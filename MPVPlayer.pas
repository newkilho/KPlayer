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
  SysUtils, Classes, SyncObjs,
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

implementation

{ TMPVPlayer }

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
