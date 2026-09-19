program KPlayer;

uses
  madExcept,
  madLinkDisAsm,
  madListProcesses,
  madListModules,
  System.SysUtils,
  Vcl.Forms,
  MPVPlayer in 'MPVPlayer.pas',
  Main in 'Main.pas' {FrmKPlayer},
  List in 'List.pas' {FrmList},
  Setup in 'Setup.pas' {FrmSetup},
  Assoc in 'Assoc.pas',
  Hotkey in 'Hotkey.pas';

{$R *.res}
// 다국어 문자열 (Translate.txt → RCDATA 'translate') + UI 스크립트 (KPlayer.lua → RCDATA 'script').
// RT_RCDATA 라 KPlayer.res 의 RT_ICON 과 ID 충돌 없음.
{$R KPlayerResource.res}
// 파일 연결 아이콘 (Icon\*.ico → RT_ICON 1000+ / RT_GROUP_ICON 40000+). .rc 가 아니라
// Tools\MakeIconRes.py 가 직접 쓴 .res — MAINICON 의 RT_ICON 1·2·3 과 안 겹치게. Icon\ 바뀌면 재실행.
{$R KPlayerIcons.res}

begin
  //ReportMemoryLeaksOnShutDown := True;

  if FindCmdLineSwitch('uninst', ['/'], True) then
  begin
    AssocUnregisterAll;
    Exit;
  end;

  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFrmKPlayer, FrmKPlayer);
  Application.CreateForm(TFrmList, FrmList);
  Application.CreateForm(TFrmSetup, FrmSetup);
  Application.Run;
end.
