unit MPVPlayer;

// MPV Player - KPlayer.lua 통신
//
// [Lua] mp.commandv("script-message", "<cmd>", [인자...])
//   → MPV_EVENT_CLIENT_MESSAGE → DoEventClientMsg → OnScriptMessage (UI 스레드)
//
// 이벤트 스레드 → UI 스레드는 Synchronize(메서드). FPC 3.2 는 익명 메서드가 없어 넘길 값을
// 필드(FPend*)에 두고 부른다 — Synchronize 는 블로킹이고 이벤트 스레드는 하나라 필드 경합 없음.

{$mode delphi}{$H+}

interface

uses
  {$IFDEF WINDOWS}
  Windows,
  {$ENDIF}
  SysUtils, Classes, SyncObjs, StrUtils,
  MPVBasePlayer, MPVClient;

type
  // script-message 이벤트. sCmd=명령 식별자, sArgs=추가 인자(없으면 빈 TStringList).
  TMPVScriptMessageEvent = procedure(cSender: TObject;
    const sCmd: string; sArgs: TStrings) of object;

  // 파일별 첫 영상 크기 확정 (dwidth×dheight — 회전·화면비 반영값). 오디오 전용은 안 옴.
  TMPVVideoSizeEvent = procedure(cSender: TObject; nWidth, nHeight: Integer) of object;

  { TMPVPlayer }
  TMPVPlayer = class(TMPVBasePlayer)
  private
    m_eOnScriptMessage: TMPVScriptMessageEvent;
    m_eOnVideoSize: TMPVVideoSizeEvent;
    m_bSized: Boolean;   // 이번 파일에서 OnVideoSize 발행 여부 (reconfig 는 파일당 여러 번)

    // Synchronize 로 넘길 값 (이벤트 스레드가 채우고 UI 스레드가 읽음)
    FPendCmd: string;
    FPendArgs: TStrings;
    FPendMsg: TMPVScriptMessageEvent;
    FPendSize: TMPVVideoSizeEvent;
    FPendW, FPendH: Integer;

    procedure SyncScriptMessage;
    procedure SyncVideoSize;

  protected
    // MPV_EVENT_CLIENT_MESSAGE 오버라이드. args[0]=명령, args[1..N]=추가 인자.
    function DoEventClientMsg(pCM: P_mpv_event_client_message): TMPVErrorCode; override;

    // mpv 로그 → 디버거. 기반 Log() 는 빈 메서드. 임베드라 터미널 없음. KPlayer.lua 의 msg.info 포함.
    procedure Log(const sMsg: string; bError: Boolean); override;

    // dwidth 는 file-loaded 시점엔 아직 없다 (첫 프레임 디코드 뒤 VIDEO_RECONFIG 에서 확정)
    // → reconfig 에서 파일당 1회만 OnVideoSize. START_FILE 에서 플래그 리셋.
    function DoEventStartFile(pSF: P_mpv_event_start_file): TMPVErrorCode; override;
    function DoEventVideoReconfig: TMPVErrorCode; override;

    // 머리말 깨진·<P> 없는 SMI 자동 로드 — mpv sub-auto 는 probe 실패로 건너뛰거나 빈 트랙 (SamiLoadPath).
    // 규칙은 sub-auto 값 따라: exact=같은 이름(·이름.언어) fuzzy=이름 포함 all=전부. 이벤트 스레드.
    function DoEventFileLoaded: TMPVErrorCode; override;
    // 외부 자막 트랙 중 external-filename = AFile 인 것 (구분자·대소문자 무시)
    function FindExtSub(const AFile: string; out Id: string; out Sel: Boolean): Boolean;

  public
    // script-message 수신 이벤트 (UI 스레드에서 호출됨)
    property OnScriptMessage: TMPVScriptMessageEvent
      read  m_eOnScriptMessage
      write m_eOnScriptMessage;

    // 파일별 첫 영상 크기 (UI 스레드에서 호출됨). Main.HandleVideoSize — 재생 창 크기 옵션.
    property OnVideoSize: TMPVVideoSizeEvent
      read  m_eOnVideoSize
      write m_eOnVideoSize;
  end;

// FFmpeg sami probe = 파일 첫 6바이트가 정확히 '<SAMI>' (대소문자 구분, BOM 만 건너뜀). '<sami>'·앞 빈 줄·
// 공백·주석으로 시작하는 흔한 SMI 가 sub-auto·sub-add 모두 실패 → 'smi 만 안 뜬다' 문의 (1.1.1.0, 2026-09-29).
// 머리말만 고치면 본문(소문자 태그 포함)은 읽힌다 (libmpv 실측). 깨졌으면 %TEMP%\KPlayer\sub\ 에 같은 이름으로
// 고친 사본을 쓰고 그 경로, 멀쩡하거나 실패면 AFile 그대로. 8비트 인코딩만 (UTF-16 은 그대로 둠).
// <P> 없는 SMI('<SYNC Start=..>텍스트'): probe 는 통과하나 디코더가 '<P' 뒤만 꺼내 트랙은 있고 글자 없음
// (1.1.3.0 z:\test.smi, libmpv 실측) → SYNC 마다 '<P>' 넣음.
function SamiLoadPath(const AFile: string): string;

implementation

function IsSamiExt(const AFile: string): Boolean;
var
  Ext: string;
begin
  Ext := LowerCase(ExtractFileExt(AFile));
  Result := (Ext = '.smi') or (Ext = '.sami');
end;

// '<SYNC ...>' 뒤(공백 건너뜀)가 '<P>'·'<P ' 가 아니면 '<P>' 삽입. Changed = 하나라도 넣었나.
function SamiAddParagraphs(const Body: RawByteString; out Changed: Boolean): RawByteString;
var
  Low: RawByteString;
  I, N, Last, Q: Integer;
begin
  Changed := False;
  Low := LowerCase(Body);
  N := Length(Body);
  Result := '';
  Last := 1;
  I := Pos('<sync', Low);
  while I > 0 do
  begin
    Q := I;
    while (Q <= N) and (Low[Q] <> '>') do Inc(Q);
    if Q > N then Break;
    I := Q + 1;
    while (I <= N) and (Low[I] in [' ', #9, #13, #10]) do Inc(I);
    if not ((I + 2 <= N) and (Low[I] = '<') and (Low[I + 1] = 'p') and
            (Low[I + 2] in ['>', ' ', #9, #13, #10])) then
    begin
      Result := Result + Copy(Body, Last, Q + 1 - Last) + '<P>';
      Last := Q + 1;
      Changed := True;
    end;
    I := PosEx('<sync', Low, Q + 1);
  end;
  Result := Result + Copy(Body, Last, MaxInt);
end;

function SamiLoadPath(const AFile: string): string;
var
  F: TFileStream;
  Data, Head, Body, Low: RawByteString;
  P, Q: Integer;
  HeadOk, ParaAdded: Boolean;
  Dir: string;
begin
  Result := AFile;
  if not IsSamiExt(AFile) then Exit;
  try
    F := TFileStream.Create(AFile, fmOpenRead or fmShareDenyNone);
    try
      SetLength(Data, F.Size);
      if F.Size > 0 then
        F.ReadBuffer(Data[1], F.Size);
    finally
      F.Free;
    end;

    Head := '';
    if Copy(Data, 1, 3) = #$EF#$BB#$BF then
      Head := #$EF#$BB#$BF
    else if (Copy(Data, 1, 2) = #$FF#$FE) or (Copy(Data, 1, 2) = #$FE#$FF) then
      Exit;
    Body := Copy(Data, Length(Head) + 1, MaxInt);
    HeadOk := Copy(Body, 1, 6) = '<SAMI>';
    if HeadOk then
      Delete(Body, 1, 6)
    else
    begin
      Low := LowerCase(Body);
      P := Pos('<sami', Low);
      if P > 0 then
      begin
        Q := Pos('>', Copy(Low, P, MaxInt));
        if Q > 0 then
          Body := Copy(Body, P + Q, MaxInt);
      end;
    end;
    Body := SamiAddParagraphs(Body, ParaAdded);
    if HeadOk and not ParaAdded then Exit;

    Dir := IncludeTrailingPathDelimiter(GetTempDir(False)) + 'KPlayer' + PathDelim + 'sub';
    ForceDirectories(Dir);
    Result := IncludeTrailingPathDelimiter(Dir) + ExtractFileName(AFile);
    Data := Head + '<SAMI>' + Body;
    F := TFileStream.Create(Result, fmCreate);
    try
      F.WriteBuffer(Data[1], Length(Data));
    finally
      F.Free;
    end;
  except
    Result := AFile;
  end;
end;

{ TMPVPlayer }

function TMPVPlayer.FindExtSub(const AFile: string; out Id: string; out Sel: Boolean): Boolean;
var
  Cnt: Int64;
  I: Integer;
  S, Key: string;
begin
  Result := False;
  Id := '';
  Sel := False;
  Cnt := 0;
  if GetPropertyInt64('track-list/count', Cnt, False) <> MPV_ERROR_SUCCESS then Exit;
  Key := LowerCase(StringReplace(AFile, '/', '\', [rfReplaceAll]));
  for I := 0 to Cnt - 1 do
  begin
    S := '';
    GetPropertyString(Format('track-list/%d/type', [I]), S, False);
    if S <> 'sub' then Continue;
    S := '';
    GetPropertyString(Format('track-list/%d/external-filename', [I]), S, False);
    if LowerCase(StringReplace(S, '/', '\', [rfReplaceAll])) <> Key then Continue;
    GetPropertyString(Format('track-list/%d/id', [I]), Id, False);
    GetPropertyBool(Format('track-list/%d/selected', [I]), Sel, False);
    Exit(Id <> '');
  end;
end;

// Debug 빌드 전용 — DebugView 로 확인. Release 는 호출 자체가 없다.
procedure TMPVPlayer.Log(const sMsg: string; bError: Boolean);
begin
{$IFDEF DEBUG}
  {$IFDEF WINDOWS}
  OutputDebugStringW(PWideChar(UTF8Decode('[mpv] ' + sMsg)));
  {$ENDIF}
{$ENDIF}
end;

function TMPVPlayer.DoEventStartFile(pSF: P_mpv_event_start_file): TMPVErrorCode;
begin
  m_bSized := False;
  Result := inherited DoEventStartFile(pSF);
end;

function TMPVPlayer.DoEventFileLoaded: TMPVErrorCode;
var
  Path, Mode, Sid, Dir, Base, Name, Fixed, Id: string;
  SR: TSearchRec;
  Match, Selected, WasSel: Boolean;
begin
  Result := inherited DoEventFileLoaded;
  Path := '';
  Mode := '';
  GetPropertyString('path', Path);
  GetPropertyString('sub-auto', Mode);
  if (Path = '') or (Pos('://', Path) > 0) or (Mode = '') or (Mode = 'no') then Exit;

  Sid := '';
  GetPropertyString('sid', Sid);
  Selected := (Sid <> '') and (Sid <> 'no');
  Dir := IncludeTrailingPathDelimiter(ExtractFilePath(Path));
  Base := LowerCase(ChangeFileExt(ExtractFileName(Path), ''));
  if FindFirst(Dir + '*', faAnyFile, SR) = 0 then
  try
    repeat
      if ((SR.Attr and faDirectory) <> 0) or not IsSamiExt(SR.Name) then Continue;
      Name := LowerCase(ChangeFileExt(SR.Name, ''));
      if Mode = 'all' then
        Match := True
      else if Mode = 'fuzzy' then
        Match := Pos(Base, Name) > 0
      else
        Match := (Name = Base) or (Copy(Name, 1, Length(Base) + 1) = Base + '.');
      if not Match then Continue;

      Fixed := SamiLoadPath(Dir + SR.Name);
      if Fixed = Dir + SR.Name then Continue;   // 멀쩡 → mpv 가 이미 넣음
      // <P> 없는 SMI 는 probe 통과 → mpv 가 빈 트랙으로 넣어 둠. 빼고 사본으로 (선택돼 있었으면 사본 선택)
      if FindExtSub(Dir + SR.Name, Id, WasSel) then
      begin
        Command(['sub-remove', Id]);
        if WasSel then Selected := False;
      end;
      if Selected then
        Command(['sub-add', Fixed, 'auto'])
      else
      begin
        Command(['sub-add', Fixed, 'select']);
        Selected := True;
      end;
    until FindNext(SR) <> 0;
  finally
    FindClose(SR);
  end;
end;

procedure TMPVPlayer.SyncVideoSize;
begin
  FPendSize(Self, FPendW, FPendH);
end;

function TMPVPlayer.DoEventVideoReconfig: TMPVErrorCode;
begin
  Result := inherited DoEventVideoReconfig;   // m_nX/m_nY ← dwidth/dheight
  if m_bSized or (m_nX <= 0) or (m_nY <= 0) then
    Exit;
  m_bSized := True;

  Lock;
  FPendSize := m_eOnVideoSize;
  Unlock;

  if Assigned(FPendSize) then
  begin
    FPendW := m_nX;
    FPendH := m_nY;
    // Synchronize — Queue 는 종료 중 폼 해제 뒤 실행될 수 있다 (OnScriptMessage 와 동일 이유).
    TThread.Synchronize(nil, SyncVideoSize);
  end;
end;

procedure TMPVPlayer.SyncScriptMessage;
begin
  FPendMsg(Self, FPendCmd, FPendArgs);
end;

function TMPVPlayer.DoEventClientMsg(pCM: P_mpv_event_client_message): TMPVErrorCode;
var
  ppc: PPMPVChar;
  i: Integer;
  cArgs: TStringList;
begin
  Result := MPV_ERROR_SUCCESS;

  // 인자가 없으면 무시
  if pCM^.num_args < 1 then
    Exit;

  ppc := pCM^.args;

  FPendCmd := string(ppc^);   // mpv 문자열 = UTF-8 = Lazarus string, 변환 불필요
  Inc(ppc);

  cArgs := TStringList.Create;
  try
    for i := 1 to pCM^.num_args - 1 do
    begin
      cArgs.Add(string(ppc^));
      Inc(ppc);
    end;

    // OnScriptMessage 핸들러를 스레드 안전하게 읽기
    Lock;
    FPendMsg := m_eOnScriptMessage;
    Unlock;

    if Assigned(FPendMsg) then
    begin
      // Synchronize 는 블로킹이라 리턴 후 finally 의 cArgs.Free 가 안전하다.
      FPendArgs := cArgs;
      try
        TThread.Synchronize(nil, SyncScriptMessage);
      finally
        FPendArgs := nil;
      end;
    end;

  finally
    cArgs.Free;
  end;
end;

end.
