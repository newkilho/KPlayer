program KPlayer;

uses
  madExcept,
  madLinkDisAsm,
  madListProcesses,
  madListModules,
  Vcl.Forms,
  Main in 'Main.pas' {FrmKPlayer},
  MPVPlayer in 'MPVPlayer.pas',
  List in 'List.pas' {FrmList},
  Setup in 'Setup.pas' {FrmSetup};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFrmKPlayer, FrmKPlayer);
  Application.CreateForm(TFrmList, FrmList);
  Application.CreateForm(TFrmSetup, FrmSetup);
  Application.Run;
end.
