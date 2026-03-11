program KPlayer;

uses
  madExcept,
  madLinkDisAsm,
  madListProcesses,
  madListModules,
  Vcl.Forms,
  MPVPlayer in 'MPVPlayer.pas',
  Main in 'Main.pas' {FrmKPlayer},
  List in 'List.pas' {FrmList},
  Setup in 'Setup.pas' {FrmSetup};

{$R *.res}

begin
  //ReportMemoryLeaksOnShutDown := True;

  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFrmKPlayer, FrmKPlayer);
  Application.CreateForm(TFrmList, FrmList);
  Application.CreateForm(TFrmSetup, FrmSetup);
  Application.Run;
end.
