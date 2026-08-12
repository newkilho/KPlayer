unit MPVPlayer;

// MPV Player - KPlayer.lua 통신
//
// [Lua] mp.commandv("script-message", "<cmd>", [인자...])
//   → MPV_EVENT_CLIENT_MESSAGE → [Delphi] DoEventClientMsg → OnScriptMessage

interface

uses
  {$IFDEF MSWINDOWS}
  Winapi.Windows,
  {$ENDIF}
  System.SysUtils, System.Classes, System.SyncObjs, Vcl.Dialogs,
  MPVBasePlayer, MPVClient;

type
  // script-message 이벤트. sCmd=명령 식별자, sArgs=추가 인자(없으면 빈 TStringList).
  TMPVScriptMessageEvent = procedure(cSender: TObject;
    const sCmd: string; sArgs: TStrings) of object;

  { TMPVPlayer }
  TMPVPlayer = class(TMPVBasePlayer)
  private
    m_eOnScriptMessage: TMPVScriptMessageEvent;

  protected
    // MPV_EVENT_CLIENT_MESSAGE 오버라이드. args[0]=명령, args[1..N]=추가 인자.
    function DoEventClientMsg(pCM: P_mpv_event_client_message): TMPVErrorCode; override;

    // mpv 로그 → IDE. 기반 Log() 는 빈 메서드라 버려졌었음. 임베드라 터미널
    // 없음. KPlayer.lua 의 msg.info 포함.
    procedure Log(const sMsg: string; bError: Boolean); override;

  public
    // script-message 수신 이벤트 (UI 스레드에서 호출됨)
    property OnScriptMessage: TMPVScriptMessageEvent
      read  m_eOnScriptMessage
      write m_eOnScriptMessage;
  end;

implementation

{ TMPVPlayer }

// Debug 빌드 전용 — IDE Event Log·DebugView 로 확인. Release 는 호출 자체가 없다.
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

  sCmd := UTF8ToString(ppc^);
  Inc(ppc);

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
      // Synchronize 는 블로킹이라 리턴 후 finally 의 cArgs.Free 가 안전하다.
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
