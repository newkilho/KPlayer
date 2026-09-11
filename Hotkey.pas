unit Hotkey;

// 키보드 단축키 표 — 동작 목록·기본 키·INI 저장의 단일 출처 (AssocExts 와 같은 역할).
// Main.FormKeyDown 은 여기서 (Key, Shift) → 동작을 찾아 ExecAction 만 부른다. 환경설정 '단축키' 카드가
// KeyMap 을 고치고 INI 에 쓴다. 고정 키(표 밖): ESC(전체화면 해제) · TAB(정보 패널,
// AppMessage — FormKeyDown 에 안 옴, CLAUDE.md).
// INI 는 TShortCut 정수 그대로 (ShortCutToText 문자열은 키보드 배치·VCL 리소스에 묶여 왕복이 깨질 수 있다).
// 키 없음(0) = 값이 있어도 미할당, INI 에 키 자체가 없으면 기본값 → 새 동작을 추가해도 옛 INI 가 그대로 산다.

interface

uses
  Winapi.Windows, System.Classes, System.SysUtils, Vcl.Menus, K.Config.INI;

type
  TKeyAction = (
    kaPause, kaSeekBack, kaSeekFwd, kaSeekBackExact, kaSeekFwdExact,
    kaChapterPrev, kaChapterNext, kaFrameBack, kaFrameFwd,
    kaVolUp, kaVolDown, kaVolUpFine, kaVolDownFine, kaMute,
    kaSpeedDown10, kaSpeedUp10, kaSpeedDown, kaSpeedUp, kaSpeedReset,
    kaSubToggle, kaSubNext, kaSubPrev, kaScreenshot, kaFullScreen,
    kaListPrev, kaListNext, kaPlayList, kaSettings, kaTopMost);

  TKeyDef = record
    Id: string;      // INI 키 = 'key_' + Id
    Name: string;    // 표시명 (한국어 = 번역 키, _() 는 Setup 이 부름)
    Def: TShortCut;
  end;

const
  KeyDefs: array[TKeyAction] of TKeyDef = (
    (Id: 'pause';         Name: '재생/일시정지';   Def: VK_SPACE),
    (Id: 'seek_back';     Name: '뒤로 5초';        Def: VK_LEFT),
    (Id: 'seek_fwd';      Name: '앞으로 5초';      Def: VK_RIGHT),
    (Id: 'seek_back_1';   Name: '뒤로 1초 (정확)'; Def: VK_LEFT or scShift),
    (Id: 'seek_fwd_1';    Name: '앞으로 1초 (정확)'; Def: VK_RIGHT or scShift),
    (Id: 'chapter_prev';  Name: '이전 챕터';       Def: VK_LEFT or scCtrl),
    (Id: 'chapter_next';  Name: '다음 챕터';       Def: VK_RIGHT or scCtrl),
    (Id: 'frame_back';    Name: '이전 프레임';     Def: VK_OEM_COMMA),
    (Id: 'frame_fwd';     Name: '다음 프레임';     Def: VK_OEM_PERIOD),
    (Id: 'vol_up';        Name: '음량 +5';         Def: VK_UP),
    (Id: 'vol_down';      Name: '음량 -5';         Def: VK_DOWN),
    (Id: 'vol_up_fine';   Name: '음량 +2';         Def: Ord('0')),
    (Id: 'vol_down_fine'; Name: '음량 -2';         Def: Ord('9')),
    (Id: 'mute';          Name: '음소거';          Def: Ord('M')),
    (Id: 'speed_down10';  Name: '배속 -10%';       Def: VK_OEM_4),   // [
    (Id: 'speed_up10';    Name: '배속 +10%';       Def: VK_OEM_6),   // ]
    (Id: 'speed_down';    Name: '배속 -0.1';       Def: Ord('X')),
    (Id: 'speed_up';      Name: '배속 +0.1';       Def: Ord('C')),
    (Id: 'speed_reset';   Name: '배속 1.0x';       Def: Ord('Z')),
    (Id: 'sub_toggle';    Name: '자막 표시/숨김';  Def: Ord('V')),
    (Id: 'sub_next';      Name: '다음 자막';       Def: Ord('J')),
    (Id: 'sub_prev';      Name: '이전 자막';       Def: Ord('J') or scShift),
    (Id: 'screenshot';    Name: '스크린샷';        Def: Ord('S')),
    (Id: 'fullscreen';    Name: '전체 화면';       Def: VK_RETURN),   // 2026-09-11 사용자 결정 (F 아님)
    (Id: 'list_prev';     Name: '이전 파일';         Def: VK_PRIOR),
    (Id: 'list_next';     Name: '다음 파일';         Def: VK_NEXT),
    (Id: 'playlist';      Name: '재생목록';        Def: 0),
    (Id: 'settings';      Name: '환경설정';        Def: 0),
    (Id: 'topmost';       Name: '항상 위';         Def: 0)
  );

type
  // 마우스 (환경설정 '마우스' 카드, 팟플레이어 방식: 이벤트마다 기능 콤보). 기능 목록은 키 동작 표와 별개로
  // 작게 — 사용자 지정 (2026-09-11). INI = mouse_<id> 정수(TMouseFunc 순번, 다른 콤보와 동일).
  TMouseFunc = (mfNone, mfFullScreen, mfStretch, mfPause, mfNextFile, mfPrevFile,
    mfSeekFwd, mfSeekBack, mfVolUp, mfVolDown);

  TMouseEvent = (meLClick, meDblClick, meMClick, meWheelUp, meWheelDown);   // 가로 휠은 넣었다 뺌 (2026-09-11, 사용자 환경에서 동작 안 함)

  TMouseDef = record
    Id: string;
    Name: string;
    Def: TMouseFunc;
  end;

const
  MouseFuncNames: array[TMouseFunc] of string = (
    '아무 작동 안함', '전체 화면/원래 화면', '꽉찬 화면/원래 화면', '재생/일시정지',
    '다음 파일 재생', '이전 파일 재생', '앞으로 이동', '뒤로 이동', '볼륨 크게', '볼륨 작게');

  // 왼쪽 클릭 기본 없음 — 창 드래그와 겹치고, 있으면 더블클릭 판별 지연만큼 반응이 늦다 (Main.FormMouseDown).
  MouseDefs: array[TMouseEvent] of TMouseDef = (
    (Id: 'lclick';      Name: '왼쪽 버튼 한 번 클릭'; Def: mfNone),
    (Id: 'dblclick';    Name: '왼쪽 버튼 두 번 클릭'; Def: mfFullScreen),
    (Id: 'mclick';      Name: '가운데 버튼 클릭';     Def: mfNone),
    (Id: 'wheel_up';    Name: '휠 위로';              Def: mfVolUp),
    (Id: 'wheel_down';  Name: '휠 아래로';            Def: mfVolDown)
  );

var
  KeyMap: array[TKeyAction] of TShortCut;   // 현재 할당 (LoadKeys 가 채움, 0 = 없음)
  MouseMap: array[TMouseEvent] of TMouseFunc;

procedure LoadKeys(AConfig: TConfig);
procedure SaveKey(AConfig: TConfig; AAction: TKeyAction; AKey: TShortCut);
procedure ResetKeys(AConfig: TConfig);
function FindKeyAction(AKey: TShortCut; out AAction: TKeyAction): Boolean;
function KeyText(AKey: TShortCut): string;   // 0 → '' (없음 표기는 호출측)

procedure LoadMouse(AConfig: TConfig);
procedure SaveMouse(AConfig: TConfig; AEvent: TMouseEvent; AFunc: TMouseFunc);
procedure ResetMouse(AConfig: TConfig);

implementation

function KeyName(AAction: TKeyAction): string;
begin
  Result := 'key_' + KeyDefs[AAction].Id;
end;

procedure LoadKeys(AConfig: TConfig);
var
  A: TKeyAction;
begin
  for A := Low(TKeyAction) to High(TKeyAction) do
    KeyMap[A] := Word(AConfig.ReadInteger(KeyName(A), KeyDefs[A].Def));
end;

procedure SaveKey(AConfig: TConfig; AAction: TKeyAction; AKey: TShortCut);
begin
  KeyMap[AAction] := AKey;
  AConfig.WriteInteger(KeyName(AAction), AKey);
end;

procedure ResetKeys(AConfig: TConfig);
var
  A: TKeyAction;
begin
  for A := Low(TKeyAction) to High(TKeyAction) do
    SaveKey(AConfig, A, KeyDefs[A].Def);
end;

// 정확 일치 (Shift 상태 포함). 옛 case 문은 'M' 을 Ctrl+M 에도 반응시켰다 — 이제 안 함.
function FindKeyAction(AKey: TShortCut; out AAction: TKeyAction): Boolean;
var
  A: TKeyAction;
begin
  Result := False;
  if AKey = 0 then Exit;
  for A := Low(TKeyAction) to High(TKeyAction) do
    if KeyMap[A] = AKey then
    begin
      AAction := A;
      Exit(True);
    end;
end;

function KeyText(AKey: TShortCut): string;
begin
  if AKey = 0 then
    Result := ''
  else
    Result := ShortCutToText(AKey);
end;

function MouseName(AEvent: TMouseEvent): string;
begin
  Result := 'mouse_' + MouseDefs[AEvent].Id;
end;

procedure LoadMouse(AConfig: TConfig);
var
  E: TMouseEvent;
  V: Integer;
begin
  for E := Low(TMouseEvent) to High(TMouseEvent) do
  begin
    V := AConfig.ReadInteger(MouseName(E), Ord(MouseDefs[E].Def));
    if (V < 0) or (V > Ord(High(TMouseFunc))) then V := Ord(MouseDefs[E].Def);
    MouseMap[E] := TMouseFunc(V);
  end;
end;

procedure SaveMouse(AConfig: TConfig; AEvent: TMouseEvent; AFunc: TMouseFunc);
begin
  MouseMap[AEvent] := AFunc;
  AConfig.WriteInteger(MouseName(AEvent), Ord(AFunc));
end;

procedure ResetMouse(AConfig: TConfig);
var
  E: TMouseEvent;
begin
  for E := Low(TMouseEvent) to High(TMouseEvent) do
    SaveMouse(AConfig, E, MouseDefs[E].Def);
end;

end.
