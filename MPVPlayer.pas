unit MPVPlayer;

// MPV Player - controls.lua 통신
//
// 통신 방법: script-message (MPV_EVENT_CLIENT_MESSAGE)
//
// [Lua] mp.commandv("script-message", "<cmd>", [arg1], [arg2], ...)
//   → MPV_EVENT_CLIENT_MESSAGE
//   → [Delphi] DoEventClientMsg → OnScriptMessage 이벤트
//
// TThread.Synchronize 는 동기(블로킹) 호출이므로
// Synchronize 완료 후 try/finally 블록에서 cArgs 를 안전하게 Free 할 수 있습니다.

interface

uses
  {$IFDEF MSWINDOWS}
  Winapi.Windows,
  {$ENDIF}
  System.SysUtils, System.Classes, System.SyncObjs, Vcl.Dialogs,
  MPVBasePlayer, MPVClient;

type
  // script-message 이벤트 타입
  // sCmd  : 명령 식별자 (예: 'close-requested', 'zoom-in', ...)
  // sArgs : 추가 인자 목록 (없으면 빈 TStringList)
  TMPVScriptMessageEvent = procedure(cSender: TObject;
    const sCmd: string; sArgs: TStrings) of object;

  { TMPVPlayer }
  TMPVPlayer = class(TMPVBasePlayer)
  private
    m_eOnScriptMessage: TMPVScriptMessageEvent;

  protected
    // MPV_EVENT_CLIENT_MESSAGE 오버라이드
    // args[0] = 명령 식별자, args[1..N] = 추가 인자
    function DoEventClientMsg(pCM: P_mpv_event_client_message): TMPVErrorCode; override;

    // mpv 로그를 IDE 로 흘린다. 기반 클래스는 MPV_EVENT_LOG_MESSAGE 를 받아
    // Log() 를 부르는데 그 기본 구현이 빈 메서드라 지금까지 다 버려졌다.
    // 창에 임베드해 쓰는 구조라 터미널이 없으므로 이렇게라도 봐야 한다.
    // KPlayer.lua 의 msg.info 출력도 여기로 들어온다.
    procedure Log(const sMsg: string; bError: Boolean); override;

  public
    // script-message 수신 이벤트 (UI 스레드에서 호출됨)
    property OnScriptMessage: TMPVScriptMessageEvent
      read  m_eOnScriptMessage
      write m_eOnScriptMessage;
  end;

implementation

{ TMPVPlayer }

// Debug 빌드에서만 내보낸다. IDE 의 View > Debug Windows > Event Log 창에 찍히고,
// DebugView 같은 도구로도 볼 수 있다. Release 에서는 호출 자체가 사라진다.
procedure TMPVPlayer.Log(const sMsg: string; bError: Boolean);
begin
{$IFDEF DEBUG}
  {$IFDEF MSWINDOWS}
  OutputDebugString(PChar('[mpv] ' + sMsg));
  {$ENDIF}
{$ENDIF}
end;

function TMPVPlayer.DoEventClientMsg(pCM: P_mpv_event_client_message): TMPVErrorCode;
var
  ppc: PPMPVChar;
  i: Integer;
  sCmd: string;
  cArgs: TStringList;
  eMsg: TMPVScriptMessageEvent;
begin
  Result := MPV_ERROR_SUCCESS;

  // 인자가 없으면 무시
  if pCM^.num_args < 1 then
    Exit;

  ppc := pCM^.args;

  // args[0] = 명령 식별자
  sCmd := UTF8ToString(ppc^);
  Inc(ppc);

  // args[1..N] = 추가 인자 수집
  cArgs := TStringList.Create;
  try
    for i := 1 to pCM^.num_args - 1 do
    begin
      cArgs.Add(UTF8ToString(ppc^));
      Inc(ppc);
    end;

    // OnScriptMessage 핸들러를 스레드 안전하게 읽기
    Lock;
    eMsg := m_eOnScriptMessage;
    Unlock;

    if Assigned(eMsg) then
    begin
      // TThread.Synchronize = 동기 블로킹 호출
      // 이 줄이 리턴될 때 핸들러 실행이 완전히 끝남
      // → 이후 finally의 cArgs.Free 안전
      TThread.Synchronize(nil, procedure
      begin
        eMsg(Self, sCmd, cArgs);
      end);
    end;

  finally
    cArgs.Free;
  end;
end;

end.
