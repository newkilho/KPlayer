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
  Assoc in 'Assoc.pas';

{$R *.res}
// 다국어 문자열 (Translate.txt → RCDATA 'translate', K.Translate 가 읽음).
// 아이콘과 달리 RT_RCDATA 라 KPlayer.res 의 RT_ICON 과 ID 충돌 없음.
{$R KPlayerResource.res}

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
