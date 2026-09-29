unit Instance;

// 단일 실행 — 이미 떠 있는 KPlayer 에 파일을 넘기고 이 프로세스는 창 없이 끝낸다 (팟플레이어·곰 관례).
// INI instance_mode: 0=여러 개 실행 허용 1=실행 중인 창에서 재생(기본) 2=실행 중인 창 목록에 추가.
// 넘기기 = WM_COPYDATA (UTF-8 경로를 #10 으로 이음, 빈 데이터 = 인자 없이 실행 → 창만 앞으로).
// 받는 창 표시 = 창 속성(SetProp). 시작 인자 처리가 끝난 뒤 붙인다(MarkReady) — 그 전엔 뒤이은 실행이 기다린다.
// 탐색기 다중 선택 = 파일 수만큼 거의 동시 실행. 뮤텍스 = 누가 먼저인가 판정 — 먼저 만든 쪽이 창을 띄우고
// 나머지는 그 창이 준비될 때까지 기다렸다 넘긴다 (첫 실행은 libmpv 117MB 로드라 수 초 걸릴 수 있다).
// 받는 쪽 처리는 Main.WndHook(WM_COPYDATA) → ForwardTimerTick.
// Windows 전용 — 그 밖은 항상 새로 실행.

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils;

const
  imMulti   = 0;   // 여러 개 실행 허용 (넘기지 않음)
  imPlay    = 1;   // 실행 중인 창에서 재생
  imEnqueue = 2;   // 실행 중인 창 목록에 추가

// 명령줄의 파일 인자 (절대경로로). 스위치('-'/'/' 시작 — '/' 는 Windows 만)는 빼고 AHasSwitch 로 알린다.
// 절대경로인 이유 — 넘겨받는 프로세스는 현재 폴더가 다르다.
function StartupFiles(out AHasSwitch: Boolean): TStringArray;

// 실행 중인 KPlayer 에 인자를 넘겼으면 True → 호출부(lpr)는 창을 만들지 않고 끝낸다.
// 스위치(/inst 등)가 있으면 넘기지 않는다 — 그 처리는 이 프로세스가 해야 한다.
function ForwardToRunning: Boolean;

// 넘겨받을 준비 완료/해제 (본체 창 핸들). 모드와 무관하게 붙인다 — 모드를 나중에 바꿔도 찾을 수 있게.
procedure MarkReady(AHandle: THandle; AReady: Boolean);

// WM_COPYDATA 의 lParam → 경로 배열. KPlayer 가 보낸 것이 아니면 False.
function DecodeForwarded(ALParam: PtrInt; out AFiles: TStringArray): Boolean;

// 본체 창을 앞으로 (최소화면 복원). 보낸 쪽이 AllowSetForegroundWindow 로 허락해 둔다.
procedure ActivateWindow(AHandle: THandle);

implementation

uses
  {$IFDEF WINDOWS}Windows,{$ENDIF}
  Config;

{$I Const.inc}

function StartupFiles(out AHasSwitch: Boolean): TStringArray;
var
  I, N: Integer;
  S: string;
begin
  AHasSwitch := False;
  Result := nil;
  SetLength(Result, ParamCount);
  N := 0;
  for I := 1 to ParamCount do
  begin
    S := ParamStr(I);
    if S = '' then
      Continue;
    if (S[1] = '-') {$IFDEF WINDOWS}or (S[1] = '/'){$ENDIF} then
    begin
      AHasSwitch := True;
      Continue;
    end;
    Result[N] := ExpandFileName(S);
    Inc(N);
  end;
  SetLength(Result, N);
end;

{$IFDEF WINDOWS}
const
  PropName: PWideChar = 'KPlayer.Instance';
  MutexName: PWideChar = 'Local\KPlayer.Instance';   // Local = 세션별 (원격 데스크톱 다른 사용자와 안 섞임)
  CopyDataMagic = $4B504C31;                        // 'KPL1'
  ReadyWaitMs = 15000;

var
  GMutex: THandle = 0;   // 닫지 않는다 — 프로세스 끝에서 OS 가 정리. 살아 있는 동안 '누군가 있다' 표시

// FPC windows 유닛에 없다
function AllowSetForegroundWindow(dwProcessId: DWORD): BOOL; stdcall; external 'user32' name 'AllowSetForegroundWindow';

function EnumReadyProc(AWnd: HWND; AParam: LPARAM): BOOL; stdcall;
var
  LPid: DWORD;
begin
  Result := True;
  if GetPropW(AWnd, PropName) = 0 then
    Exit;
  LPid := 0;
  GetWindowThreadProcessId(AWnd, @LPid);
  if LPid = GetCurrentProcessId then
    Exit;
  PHandle(AParam)^ := AWnd;
  Result := False;
end;

function FindReady: HWND;
begin
  Result := 0;
  EnumWindows(@EnumReadyProc, LPARAM(@Result));
end;

function ForwardToRunning: Boolean;
var
  LFirst, LSwitch: Boolean;
  LFiles: TStringArray;
  LMode, I: Integer;
  LCfg: TConfig;
  LWnd: HWND;
  LStart: QWord;
  LData: string;
  LCds: TCopyDataStruct;
  LRes: DWORD_PTR;
  LPid: DWORD;
begin
  Result := False;

  // 모드와 무관하게 만든다 — GetLastError 는 바로 읽어야 한다.
  GMutex := CreateMutexW(nil, False, MutexName);
  LFirst := GetLastError <> ERROR_ALREADY_EXISTS;

  LFiles := StartupFiles(LSwitch);
  if LSwitch then
    Exit;

  LCfg := TConfig.Create(AppName);
  try
    LMode := LCfg.ReadInteger('instance_mode', imPlay);
  finally
    LCfg.Free;
  end;
  if LMode = imMulti then
    Exit;

  LWnd := FindReady;
  // 먼저 뜬 쪽이 아직 창을 만드는 중 (다중 선택 동시 실행) — 준비될 때까지 기다린다.
  // 못 찾으면 새로 실행 (먼저 뜬 쪽이 도중에 끝났거나 멈춤).
  if (LWnd = 0) and not LFirst then
  begin
    LStart := GetTickCount64;
    repeat
      Sleep(50);
      LWnd := FindReady;
    until (LWnd <> 0) or (GetTickCount64 - LStart > ReadyWaitMs);
  end;
  if LWnd = 0 then
    Exit;

  LData := '';
  for I := 0 to High(LFiles) do
  begin
    if I > 0 then
      LData := LData + #10;
    LData := LData + LFiles[I];
  end;

  // 받는 쪽이 앞으로 나올 권한 — 탐색기가 띄운 우리(전경 권한 보유)만 줄 수 있다.
  LPid := 0;
  GetWindowThreadProcessId(LWnd, @LPid);
  AllowSetForegroundWindow(LPid);

  LCds.dwData := CopyDataMagic;
  LCds.cbData := Length(LData);
  if LData = '' then
    LCds.lpData := nil
  else
    LCds.lpData := PChar(LData);

  LRes := 0;
  // 멈춘 창에 매달리지 않게 제한시간. 실패하면 새로 실행.
  Result := (SendMessageTimeoutW(LWnd, WM_COPYDATA, 0, LPARAM(@LCds),
    SMTO_ABORTIFHUNG, 5000, @LRes) <> 0) and (LRes = 1);
end;

procedure MarkReady(AHandle: THandle; AReady: Boolean);
begin
  if AReady then
    SetPropW(AHandle, PropName, 1)
  else
    RemovePropW(AHandle, PropName);
end;

function DecodeForwarded(ALParam: PtrInt; out AFiles: TStringArray): Boolean;
var
  LCds: PCopyDataStruct;
  LData: string;
begin
  SetLength(AFiles, 0);
  LCds := PCopyDataStruct(ALParam);
  Result := (LCds <> nil) and (LCds^.dwData = CopyDataMagic);
  if not Result or (LCds^.cbData = 0) then
    Exit;

  SetString(LData, PChar(LCds^.lpData), LCds^.cbData);
  AFiles := LData.Split([#10]);
end;

procedure ActivateWindow(AHandle: THandle);
begin
  if IsIconic(AHandle) then
    ShowWindow(AHandle, SW_RESTORE);
  SetForegroundWindow(AHandle);
end;
{$ELSE}
function ForwardToRunning: Boolean;
begin
  Result := False;
end;

procedure MarkReady(AHandle: THandle; AReady: Boolean);
begin
end;

function DecodeForwarded(ALParam: PtrInt; out AFiles: TStringArray): Boolean;
begin
  SetLength(AFiles, 0);
  Result := False;
end;

procedure ActivateWindow(AHandle: THandle);
begin
end;
{$ENDIF}

end.
