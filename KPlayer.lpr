program KPlayer;

{$mode delphi}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  // KExcept 는 uses 만으로 설치된다 (klib\kexcept.pas, madExcept 대체). 유닛 initialization 이
  // 프로그램 본문보다 먼저 돌아 시작 도중의 크래시까지 잡는다. 앱 이름은 exe 이름, 버전은 버전 리소스.
  Forms, SysUtils, KExcept,
  MPVPlayer, Main, List, Setup, Assoc, Hotkey, Media, Config, OSUtil,
  IconButton, VTScrollbar;

{$R *.res}
// 다국어 문자열 (translate.txt → RCDATA 'translate') + UI 스크립트 (KPlayer.lua → RCDATA 'script')
// + 재생목록 창 아이콘 (Res\list-*.png → RCDATA 'list-*'). RT_RCDATA 라 RT_ICON 과 ID 충돌 없음.
{$R KPlayerResource.res}
// 파일 연결 아이콘 (Icon\*.ico → RT_ICON 1000+ / RT_GROUP_ICON 40000+). .rc 가 아니라
// Tools\MakeIconRes.py 가 직접 쓴 .res — MAINICON 의 RT_ICON 과 안 겹치게. Icon\ 바뀌면 재실행.
{$R KPlayerIcons.res}

begin
  // Debug 빌드는 heaptrc 가 켜져 있다(.lpi). 기본 출력은 stdout 인데 GUI 앱이라 종료할 때마다
  // 대화상자로 뜬다 — 샐 때만 보면 되므로 파일로 돌린다. 누수는 %TEMP%\kplayer-heap.log 에 남는다.
  {$IFDEF DEBUG}
  SetHeapTraceOutput(GetTempDir + 'kplayer-heap.log');
  {$ENDIF}

  // 제거 프로그램이 부른다 (KPlayer.iss RunAsShellUser). 창 없이 연결 원복만 하고 끝 — 화면 반응 없는 것이 정상.
  if FindCmdLineSwitch('uninst', ['/'], True) then
  begin
    AssocUnregisterAll;
    Exit;
  end;

  RequireDerivedFormResource := True;
  Application.Scaled := True;
  {$PUSH}{$WARN 5044 OFF}
  Application.MainFormOnTaskbar := True;
  {$POP}
  Application.Initialize;
  Application.CreateForm(TFrmKPlayer, FrmKPlayer);
  Application.CreateForm(TFrmList, FrmList);
  Application.CreateForm(TFrmSetup, FrmSetup);
  Application.Run;
end.
