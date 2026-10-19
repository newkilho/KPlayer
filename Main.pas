{===============================================================================

Project : KPlayer
Author  : Kilho, Oh
Engine  : libmpv (GPL-2.0-or-later)
Tree    : Virtual Treeview (MPL 1.1)
IDE     : Lazarus (FPC) — 2026-09-29 Delphi 에서 변환 (마지막 Delphi 판 = git 태그 delphi-final)

This program links against libmpv (GPL-2.0-or-later).
When distributed in binary form, the complete corresponding
source code must be made available under the GPL.

Icon: https://www.flaticon.com/free-icon/play_2377793

히스토리:
========
  1.2.0.0
  [*] 일부 PC 에서 'MPV DLL 로드 실패' 로 실행 안 됨 - 1.1.8.0 에서 바꾼 libmpv 가 vulkan-1.dll 을 직접 import → Vulkan 을 지원하는
      그래픽 드라이버가 없는 PC 에서 DLL 자체가 안 열림. Khronos Vulkan 로더(LunarG 1.4.363.0)를 함께 배포
      (KPlayer.iss: [Files])
  [+] DLL 로드 실패 메시지에 원인 표시 - 파일 없음 / Windows 오류 문구·코드, 126 이면 의존 DLL 없음 안내 + 경로
      (Main.pas: MPVLoadError)

  1.1.9.0
  [*] 1.1.8.0 을 덮어 설치하면 libmpv 가 안 바뀌어 AVX2 없는 CPU 에서 Illegal Instruction 그대로 - 새·옛 DLL 이진 버전이 둘 다
      2.0.0.0 이라 설치본이 같은 버전으로 보고 건너뜀. 버전 비교 없이 항상 덮어씀
      (KPlayer.iss: [Files])

  1.1.8.0
  [*] '항상 위' 가 안 먹거나 반대로 동작 - LCL win32 가 직접 건 TOPMOST 를 앱 비활성 때 풀고(HWND_BOTTOM), 환경설정(ShowModal) 닫을 때
      열기 전 상태로 되살림. 원하는 상태와 어긋나는 Z순서 변경을 서브클래스에서 막음. 목록 창은 첫 표시 때 건다
      (OSUtil.pas: SetWindowTopMost, TopMostProc / List.pas: ShowPlaced)
  [*] 총 재생시간이 1초 길게 표시 (02:00 인데 01:59 에서 끝남) - duration 은 마지막 프레임 길이까지 포함 → 1프레임 빼서 표기, 팟플레이어와 같음
      (Main.pas: RefreshUI, RefreshInfo, DragPaint, UpdateHover)
  [*] 캡션 '항상 위' 아이콘을 Lucide pin / pin-off 로 - 16px 격자에 다시 그린 1px 선 (FileIndex 캡션 단추와 같은 굵기) (ui\icons\pin*.svg / player.css)
  [*] AVX 는 있고 AVX2 는 없는 CPU 에서 재생 중 크래시 (Illegal Instruction in libmpv-2.dll + 05A653C1) - 번들 zimg 가 AVX 만 보고 AVX2 색변환을 고름
      (zimg 0e56801f9 에서 수정). libmpv 교체 v0.41.0-173 → v0.41.0-1205 (shinchiro 20261018, 비-v3 판)
  [*] 재생 후 종료할 때 Access violation - 작업 표시줄 진행률 인터페이스를 COM 해제(OleUninitialize) 뒤에 Release 함 → 참조만 버림
      (OSUtil.pas: finalization)
  [*] 폴더를 목록에 넣다가 Stack overflow - 하위 폴더 전개 재귀에 끝이 없었음. 깊이 32 로 제한, 정션·심볼릭 링크 폴더는 건너뜀
      (List.pas: AddFile)
  [*] 종료가 바로 안 되고 버벅거림 - 정리(mpv 해제 등)하는 동안 멈춘 창이 보였음. 닫는 순간 재생을 멈추고 창부터 숨김
      (Main.pas: FormClose)

  1.1.7.0
  [*] 다음 영상으로 넘어가도 메모리가 안 줄던 문제 - 진행바 미리보기 mpv 가 옛 파일을 계속 열어 둠 (4K AV1 → 1080p 전환 뒤 741 → 425MB).
      파일이 바뀌면 닫고 다음 호버 때 새로 엶 (Main.pas: RefreshUI)
  [*] 진행바 미리보기 디코딩 스레드 2개로 - 4K AV1 호버 메모리 +390 → +276MB (Thumb.pas: Open)
  [+] 재생 중 작업 표시줄 버튼에 진행률 표시 - 일시정지는 노란색, 길이 없는 스트림·대기 화면은 끔 (Main.pas: UpdateTaskbar / OSUtil.pas: SetTaskbarProgress)
  [+] 재생목록 창 캡션을 앱이 그림 (klib TKCaption) + 닫기 왼쪽 검색 단추 - 캡션 입력칸에 입력하는 대로 파일 이름으로 거름 (공백으로 나눈 단어 AND),
      Esc·검색어 없이 포커스를 잃거나 다른 창으로 가면 닫음 (입력 중엔 제목·검색 단추를 덮음). 보기만 거르고 재생 순서는 전체 목록, 거르는 중엔 끌어 옮기기 없음·선택/선택 외 삭제는 보이는 항목만
      왼쪽 앱 아이콘 없음, 검색·닫기 단추 폭 32px (OS 46), 기본 폭 198 → 240 (List.lfm), 아이콘은 Lucide search (Res\list-search.png, Tools\MakeListIcons.py)
      (List.pas: FormCreate, TSearchCapButton, ApplyFilter, DelFile, ListDeactivate / IconButton.pas: PaintIcon / OSUtil.pas: SetDarkTitleBar 삭제 / translate.txt)
  [+] 커버 없는 음악은 화면에 LP 가 돈다 (재생 위치 기준 10 rpm, 일시정지면 멈춤), 라벨 둘레에 제목을 원으로.
      LP 디자인은 codepen joshbader/GqXbVZ 의 LP 부분.
      커버가 있으면 mpv 가 그대로 보여 줌 (Main.pas: CheckAudioOnly, DiscTimerTick, BuildDiscTitle / ui\player.html #lp / player.css)
  [+] 환경설정 '정보' 탭 (ZipMania 와 같은 구성) - 아이콘·이름, 버전·만든이·홈페이지, 라이선스 고지문. 디버그 전용 → 항상 표시.
      고지문 원본을 저장소로 (THIRD-PARTY-NOTICES.txt → RCDATA NOTICES, KPlayer.iss 도 저장소 것). '기본값 복원' → '초기화'
      (Setup.pas: FillAbout, LblHomeClick / Setup.lfm: CardAbout / KPlayerResource.rc / build.bat)
  [*] 실행 직후 흰 창이 잠깐 보이던 문제 (Win11 라이트 모드) - 첫 그리기 전엔 창을 DWM 에서 가림, 영상 뷰 배경도 검정
      (Main.pas: FormCreate, UncloakTimerTick / OSUtil.pas: SetWindowCloak)
  [*] 탐색기 등에서 연결 파일로 열면 기존 목록을 지우고 연 파일만 남김 (다중 선택의 나머지·'목록에 추가' 모드는 덧붙임)
      (Main.pas: HandleStartupParams, ForwardTimerTick / List.pas: ReplaceFiles)

  1.1.6.0
  [*] 재생 중 CPU 과다 - Main 의 mpv 옵션(vo/hwdec/scale 등)이 전부 무시돼 소프트웨어 디코딩. 바인딩 SetOptionString 이
      InitPlayer 전엔 버리고 이후엔 @p 를 넘겨 실패 → init 전 모아 뒀다 SetPropertyString 으로 적용 (MPVPlayer.pas: SetOptionString, ProcessCmdLine)
      4K HEVC CPU 140% → 20%, 작업 집합 879 → 559MB
  [*] 컨트롤 UI 를 KPlayer.lua(mpv ASS 오버레이) → KilhoUI(HTML/CSS, 정적 링크 -dKILHO_STATIC_MSVC) 로 교체 - 상단바·컨트롤바 디자인 동일,
      글자 12px. KPlayer.lua·script 리소스 삭제 (Main.pas: 컨트롤 UI / ui\player.html, player.css / KPlayerResource.rc)
  [*] 배속 토스트·음량/재생 베젤·중앙 알림·TAB 정보 패널도 HTML 로 - Lua 와 같은 치수·색·페이드, 상태 변화는 100ms 폴링으로 감지
      (Main.pas: CheckOsd, ShowBezel, ShowToast, Alert, ToggleInfo, RefreshInfo / player.css: #toast #bezel #alert #info)
  [*] 환경설정 '자막' 카드 맨 아래 여백 없음 (Setup.lfm: CboSubAss BorderSpacing.Bottom 19)
  [*] 닫기 버튼 hover 색 Win10 #E81123 → Win11 #C42B1C (player.css: #cap-close)
  [*] 우클릭 메뉴가 예전 모양 - LCL win32 는 항목을 전부 직접 그림(MFT_OWNERDRAW) → Win32 기본 메뉴로 복제해 띄움
      재생목록 창 우클릭·[추가]·[삭제] 메뉴도 (OSUtil.pas: PopupNativeMenu / Main.pas: ViewContextMenu / List.pas: ListDataContextPopup, BtnMouseUp)
  [+] 환경설정 '일반 - 언어' - 자동(OS) / 9개 언어, 고르면 열린 창 모두 바로 바뀜 (INI language, --lang > 설정 > OS).
      자막 언어 기본값도 화면 언어를 따름 (Setup.pas: CboLang, FillLang, ApplyLanguage / Main.pas: FormCreate / List.pas: ApplyTexts)
  [+] 우클릭 메뉴에 '재생목록'(목록 창 보이면 체크)·'환경설정'·'종료하기' (Main.lfm: MnuPlayList, MnuSettings, MnuExit / Main.pas: MenuPopup)
  [+] 진행바 미리보기 - 마우스 위치 시점의 프레임을 말풍선 위에, 환경설정 '일반' 에서 켜고 끔 (INI seek_preview, 기본 켬).
      두 번째 mpv(소리 없음·일시정지)를 스레드에서 돌려 키프레임 탐색 + 소프트웨어 렌더 → BMP (Thumb.pas / Main.pas: SetSeekPreview, ThumbReady)
  [*] 하단 시간 표시를 7세그먼트 숫자로 (5×9, 꺼진 획 어둡게) (Tools\MakeDigits.py / player.css: #time / Main.pas: SetTimeDigits)
  [*] 환경설정 '자막 기본 표시' 가 다음 재생에 안 먹던 문제 - sub-visibility 는 전역이라 자막 버튼으로 끈 상태가 다음 파일까지 남음.
      새 파일마다 설정값으로 되돌림, 자막 버튼은 그 파일에만 (MPVPlayer.pas: SubVisibleDefault, DoEventStartFile)
  [*] 환경설정 단축키: 다른 동작이 쓰는 키를 말없이 빼앗던 것 → 거절하고 [지우기] 아래 빨간 글 '이미 …에 쓰입니다',
      계속 키를 기다림. SecretVideo 1.3.4.0 · WorldView 와 같은 규칙 (Setup.pas: AssignKey / Setup.lfm: LblKeyNote)
  [*] 재생목록 하단 아이콘(반복·랜덤·추가·삭제)이 안 보이던 문제 (1.1.0.0 Lazarus 변환부터) - 그림 버퍼가 0×0 으로 만들어져
      그리기 예외가 삼켜짐 (IconButton.pas: RenderTinted). 또 폼 Width/Height 는 테두리·제목줄 제외라 창이 작업 영역 아래로
      39px 삐져 아이콘 줄이 작업 표시줄 뒤에 숨음 → 바깥 크기로 배치, 배율 다른 모니터로 옮겨 크기가 바뀌면 한 번 더 (List.pas: ShowPlaced)

  1.1.5.0
  [*] 자막 전환(cycle sub) 등 mpv 명령 중 EInvalidOp 크래시 - FPC 는 FPU 예외를 풀어 두고 libmpv 는 가려진 상태 전제(NaN 진행).
      시작 시 메인 스레드에서 전부 가림 (KPlayer.lpr)

  1.1.4.0
  [*] 창 가장자리 끌어도 크기 안 바뀌던 문제 - bsNone(WS_POPUP)은 WS_THICKFRAME 없으면 HTRIGHT 등을 줘도 크기 조절 안 함.
      가장자리 누르는 동안만 WS_THICKFRAME 켬 + WM_NCCALCSIZE 로 테두리 숨김, 끝나면 LCL 크기 재동기 (OSUtil.pas: RunSizingLoop / Main.pas: WndHook)
  [*] 가장자리 커서가 화살표로 남던 문제 - Delphi 는 VCL 이 WM_SETCURSOR 를 기본 처리로 넘겨 저절로 됐으나 LCL 은 폼 Cursor 로 덮음.
      WM_SETCURSOR 에서 HT 값별 크기 조절 커서 (Main.pas: WndHook)

  1.1.3.0
  [*] <P> 태그 없는 SMI ('<SYNC Start=..>텍스트') 는 트랙만 생기고 글자가 안 뜨던 문제 - FFmpeg 디코더는 '<P' 뒤만 읽음.
      SYNC 마다 '<P>' 넣은 사본으로 교체, mpv 가 넣어 둔 빈 원본 트랙은 sub-remove (MPVPlayer.pas: SamiAddParagraphs, FindExtSub)

  1.1.2.0
  [*] SMI 만 안 뜨던 문제 - FFmpeg 는 첫 6바이트가 '<SAMI>' 인 파일만 SAMI 로 인식 ('<sami>'·앞 빈 줄이면 자동 로드·드롭 모두 무시).
      머리말 고친 사본을 %TEMP%\KPlayer\sub 에 써서 sub-add (MPVPlayer.pas: SamiLoadPath, DoEventFileLoaded / Main.pas: AddSubtitles)

  1.1.1.0
  [+] 외부 자막 자동 로드 - 환경설정 자막 '외부 자막 자동 로드' = 사용안함 / 같은 이름만 / 이름이 포함된 자막(기본) / 폴더의 모든 자막 (mpv sub-auto).
      전엔 미설정 = exact 라 이름 다른 smi 가 안 떠 'smi 미지원' 문의 (Setup.pas: ApplySubStyle, CboSubAuto / Media.pas: SubAutoValues)
  [+] 자막 파일 드롭 - .smi/.srt/.ass 등을 본체·목록 창에 떨구면 재생 중 영상에 sub-add + 표시 켬. 영상과 섞이면 자막은 버리고 자동 로드에 맡김
      (Main.pas: FormDropFiles, AddSubtitles / List.pas: FormDropFiles / Media.pas: SubtitleExts, IsSubtitleFile)
  [*] 본체 창에 미지원 파일(자막 등)만 떨구면 목록이 비고 재생이 멈추던 문제 - 넣을 항목이 없으면 목록 유지 (List.pas: ReplaceFiles)
  [*] 자막 기본 표시를 켬으로 - 끔이 기본이라 자막 있는 영상도 첫 재생에 안 보임 (Main.pas: FormCreate / Setup.pas: 기본값)

  1.1.0.0
  [+] 단일 실행 - 이미 떠 있으면 새 창 대신 그 창에 파일을 넘긴다. 환경설정 일반 '실행 중일 때 파일 열기' = 여러 개 실행 허용 /
      실행 중인 창에서 재생(기본) / 실행 중인 창 목록에 추가. 탐색기 다중 선택은 첫 파일 재생 + 나머지 추가
      (Instance.pas / Main.pas: WndHook WM_COPYDATA, ForwardTimerTick / KPlayer.lpr / Setup: CboInstance)
  [+] 폴더 내 파일 자동 추가 - 파일 하나를 열면(탐색기·본체 드롭·열기 대화상자) 같은 폴더의 같은 종류 파일을 자연 정렬로 추가, 연 파일부터 재생.
      환경설정 일반 '폴더 내 파일 자동 추가' = 사용안함 / 관련 파일만(이름이 처음 갈리는 자리가 숫자 = 1화·2화) / 모든 파일, 기본 관련 파일만
      (List.pas: ExpandFolder, AddFiles / Media.pas: NaturalCompare, IsRelatedName / Setup: CboFolderAdd)
  [*] Delphi → Lazarus 변환 - 명령줄 빌드(lazbuild), klib(KTheme/KTranslate/KUpdate/KExcept) 로 교체, madExcept 제거,
      SVG 아이콘은 PNG 마스크 착색(IconButton / Tools\MakeListIcons.py), OS 의존 코드 분리(OSUtil, Assoc 비-Windows 빈 구현, Config.AppDataDir)
  [*] 재생목록 스크롤바 떨림 수정 - 바를 트리 DC 에 직접 그리던 것을 형제 창(HTTRANSPARENT)으로, 트리 WS_CLIPSIBLINGS. laz VT 가 ScrollWindowEx 로 바까지 밀어 다음 WM_PAINT 까지 튀던 것 (VTScrollbar.pas)
  [*] 음량 평준화를 끄면 실제로 꺼지게 - 'set af ""' 의 빈 인자가 Command 에서 버려져 명령이 실패하던 것 (Setup.pas: ApplyLive)
  [*] 우클릭 '화면 크기' 항목명을 50% / 100% / 150% / 200% 로 - '원본 화면 (n.nx)' 넷은 어색, PotPlayer·GOM 관례, 번역 불필요 (Main.dfm: MnuOrig50~200 / Main.pas: FormCreate / Translate.txt: '원본 화면' 그룹 제거)

  1.0.0.0
  [+] 설치 직후 주요 확장자 자동 연결 - 인스톨러 [Run] 이 /inst 로 실행하면 등록 후 평소처럼 계속 실행 (Assoc.pas: AssocRegisterMain / Main.pas: FormCreate / KPlayer.iss: [Run])
  [*] 파일 연결 아이콘을 exe 리소스로 - Icon\*.ico 를 Tools\MakeIconRes.py 가 RT_ICON 1000+/RT_GROUP_ICON 40000+ 로 KPlayerIcons.res 생성(MAINICON 과 ID 충돌 회피), DefaultIcon = "exe",-ID, exe 옆 Icon\ 폴더·설치본 항목 제거 (Assoc.pas: ExtIconRef, IconIds.inc / KPlayer.dpr / KPlayer.iss)
  [*] KPlayer.lua 를 exe 리소스(RCDATA 'script')에 내장 - 실행 시 %TEMP%\KPlayer\ 에 풀어 load-script, exe 옆 파일 불필요, 설치본에서 제외 (Main.pas: ExtractScript, FormCreate / KPlayerResource.rc / KPlayer.iss)
  [+] 시작 화면 원 로고를 버튼으로 - 클릭 시 목록 있으면 첫 항목 재생, 없으면 파일 열기 대화상자, 마우스 올리면 밝아짐, 창 드래그 억제 (KPlayer.lua: hover_logo, check_hover, alpha.logo_*_hover / Main.pas: OnScriptMessage 'logo')
  [+] 우클릭 '만든이 오길호' 클릭 시 홈페이지(go.kilho.net/kplayer) 열기 (Main.pas: BtnAboutClick / Const.inc: AppHome)
  [+] 우클릭 메뉴에 '파일 열기'/'폴더 열기' - 화면 크기 위, 구분선 (Main.pas: MnuOpenFileClick, MnuOpenFolderClick / Main.dfm: MnuOpenFile, MnuOpenFolder / List.pas: OpenFolder)
  [+] 파일 열기 단축키 Ctrl+O - 환경설정 '단축키' 재생목록 위, 목록 창 [추가] 와 같은 대화상자, 필터는 AssocExts 38종 (미디어/비디오/오디오/모든 파일) (Hotkey.pas: kaOpenFile / List.pas: OpenFiles, BtnAddPopupClick / Main.pas: ExecAction)
  [*] 두 번째 실행부터 둥근 모서리가 사라지던 문제 - RestoreWindow 의 Position := poDesigned 가 핸들을 재생성해 SetFormCorners 무효, DFM 을 poDesigned 로 고정하고 미저장 시 직접 가운데 배치 (Main.pas: RestoreWindow / Main.dfm: Position)
  [+] 환경설정 '마우스' 카드 - 왼쪽 클릭/더블클릭/가운데 버튼/휠 위아래 마다 기능 선택 (팟플레이어 방식), 왼쪽 클릭은 이동 없이 뗀 뒤 더블클릭 시간만큼 지연 (Hotkey.pas: MouseDefs, MouseMap, LoadMouse / Main.pas: ExecMouse, FormMouseDown, ClickTimerTick, WMMouseWheel / Setup.pas: CardMouse, FMouseCbo)
  [+] 환경설정 '단축키' 카드 - 동작 29종의 키를 지정/해제/기본값, 중복 키는 이전 동작에서 자동 해제, INI key_* (TShortCut 정수) (Hotkey.pas: KeyDefs, KeyMap, LoadKeys, SaveKey, FindKeyAction / Main.pas: FormKeyDown, ExecAction / Setup.pas: CardKeys, FillKeys, EdtKeyKeyDown)
  [*] 기본 자막 언어를 OS 언어에서 계산 (2자+3자 코드 + 영어 폴백), 직접 고친 값만 INI 기록 - ko 고정이라 타 언어 사용자에게 한국어 자막이 먼저 잡히던 것 (Setup.pas: DefaultSubLang, LoadValues, SaveValues, ApplyLive / Main.pas: FormCreate)
  [+] 캡션에 항상 위 압정 버튼 - 최소화 왼쪽, 꺼짐은 사선 표시, 환경설정 '항상 위' 와 상태 공유 (KPlayer.lua: icons.pin, cap_pin, draw_caption_pin, topmost-state / Main.pas: OnScriptMessage 'topmost', 'topmost-query', SetTopMost, SendTopMost)
  [*] 환경설정에서 글꼴 등 다른 항목을 바꾸면 켜 둔 자막이 꺼지던 문제 - sub-visibility 는 '자막 기본 표시' 콤보를 바꿀 때만 전송 (Setup.pas: ApplyLive, ControlChange)
  [*] 환경설정 카드가 마우스 휠로 스크롤되지 않던 문제 - 포커스 컨트롤 대신 마우스 아래 스크롤박스로 (Setup.pas: MouseWheelHandler)
  [*] 스크린샷 폴더 [찾기] 대화상자가 '항상 위' 창 뒤로 숨던 문제 - 설정 창 소유 TFileOpenDialog 로 교체 (Setup.pas: BtnShotDirClick)
  [*] 환경설정 카드의 설명 라벨 제거, '저장 폴더' → '스크린샷 폴더', 스크롤 하단 여백 (Setup.dfm: VertScrollBar.Margin)
  [+] 환경설정 '자막' 카드에 스타일 옵션 - 글꼴·굵게·글자색·외곽선 두께/색·그림자·세로 위치·정렬·자막 파일 스타일 우선(sub-ass-override) (Setup.pas: ApplySubStyle, FillFonts, BtnSubColorClick / Main.pas: FormCreate / Assoc.pas: SubAlignValues, SubAssValues)
  [*] 컨트롤바 표시 때 자막을 올렸다 내리던 것 제거 - sub-margin-y 40 고정, 마우스만 움직여도 자막이 들썩이던 문제 (KPlayer.lua: update_sub_margin 삭제)
  [+] 우클릭 메뉴 '화면 크기' - 원본 화면 0.5x/1.0x/1.5x/2.0x(영상 픽셀 × 배율) / 전체 화면 / 꽉찬 화면(keepaspect=no), 창모드 복귀 시 비율 복원 (Main.pas: MenuPopup, MnuOriginalClick, EnterFullScreen, HandleFullScreen / Main.dfm: MnuScreen)
  [+] 재생 창 크기 옵션 ('일반' 카드) - 마지막 크기 유지 / 영상 크기에 맞춤 / 전체 화면, 종료 시 창 위치·크기 저장 (Main.pas: RestoreWindow, SaveWindow, ResizeWindow, HandleVideoSize, ApplyWindowMode / MPVPlayer.pas: OnVideoSize, DoEventVideoReconfig / Setup.pas: CboWinSize)

  0.9.8.0
  [+] 목록 창 드롭·[추가] 버튼·폴더 추가도 추가한 첫 항목부터 자동 재생 - 불러왔는데 더블클릭해야 시작되던 혼동 해소 (List.pas: FormCreate FDragFile, BtnAddPopupClick, BtnAddPopupFolderClick)
  [*] 탐색기 더블클릭·명령줄 인자로 재생목록/폴더를 열면 재생이 안 걸리던 문제 - 인자 경로 대신 목록에 들어간 첫 항목부터 재생, 폴더 인자도 처리 (Main.pas: HandleStartupParams / List.pas: AddFiles, AddFile, FAddFirst)
  [*] 없는 파일을 재생 시 목록에서 자동 삭제하던 것 제거 - 항목은 두고 전체 경로로 표시만, 삭제는 [삭제]→없는 파일 (List.pas: SkipMissing, Play)
  [*] 재생 중인 파일이 전체 경로로 표시되던 문제 - 재생 성공 시 Missing 해제 (List.pas: Play)
  [+] 드라이브 연결/해제와 목록 창 표시 때 존재 재검사 - 없음 표시 항목만, 드라이브 통지는 2초 디바운스 (Main.pas: FVerifyTimer, WMDeviceChange, VerifyTimerTick, HandlePlayList / List.pas: StartVerify)
  [*] 존재 확인 스레드가 루트(드라이브/UNC 공유) 단위로 선판정 - 끊긴 공유에서 파일마다 수 초 막히던 것 제거 (List.pas: PathRoot, TFileCheckThread.Execute)
  [*] 부분 재검사 결과가 검사 범위 밖 항목을 덮어쓰지 않도록 확인 목록 전달 (List.pas: ApplyMissing)

  0.9.7.0
  [*] 대량 드롭 시 UI 멈춤 - 추가 시점의 파일 존재 확인 제거, 미디어 확장자면 디스크 접근 없이 바로 추가 (List.pas: AddFile)
  [+] 파일 존재 확인을 배경 스레드로 - 결과만 목록에 반영, 세대 카운터로 이전 검사 취소 (List.pas: TFileCheckThread, StartVerify, ApplyMissing, GVerifyGen)
  [*] 그리기 경로(OnGetText)의 FileExists 제거 - 스레드가 채우는 Missing 캐시 사용 (List.pas: TItemData.Missing, ListDataGetText)
  [*] 일괄 추가 중복 검사를 노드 탐색(O(n²)) 대신 해시표로 (List.pas: FAddSeen, AddFiles, AddFile)
  [*] 시작 로드 후에도 존재 확인을 배경으로 수행 (List.pas: LoadPlaylist)
  [*] 파일/폴더 추가 메뉴도 일괄 추가 경로 사용 (List.pas: BtnAddPopupClick, BtnAddPopupFolderClick)
  [+] 본체 창 드롭은 목록을 비우고 떨군 것만 추가 후 재생, 목록 창 드롭은 기존 목록에 덧붙임 (List.pas: ReplaceFiles / Main.FormCreate FDragFile)
  [*] 무음 상태에서 음량을 조절해 0 이 아니게 되면 무음 해제 (Main.pas: AddVolume, FormKeyDown)
  [+] TAB 으로 재생/파일 정보 패널 토글 - 자체 ASS 패널 1초 갱신, TAB 은 VCL 이 먹으므로 Application.OnMessage 에서 가로챔 (Main.pas: AppMessage, OnScriptMessage 'info' 무시 / KPlayer.lua: ov_info, info_rows, render_info, set_info, script-message 'info')

  0.9.6.0
  [+] 일괄 추가+재생 함수 추가 - 새로 들어간 첫 항목 판별, 추가 루프 BeginUpdate/EndUpdate (TFrmList.AddFiles)
  [*] 드롭 시 폴더/비지원 확장자/재생목록 경로가 그대로 재생되어 "파일을 찾을 수 없습니다 - <폴더명>" 후 재생 안 되던 문제 - 드롭 경로 대신 목록 항목부터 재생 (Main.FormCreate FDragFile, TFrmList.FormCreate FDragFile)
  [+] 다국어 지원 - ko/en/ja/zh/ru/it/fr/es/ar
  [+] 설치 시작 시 소개 화면 추가

  0.9.5.0
  [*] 시작 시 저장 목록을 디스크 확인 없이 로드 - 네트워크 드라이브 타임아웃으로 창 표시가 늦던 문제, 없는 파일은 재생 시 SkipMissing 이 정리 (List.pas: LoadPlaylist, AddFile ACheckDisk 파라미터)
  [*] 시작 로드의 중복 검사를 전체 노드 탐색(O(n²)) 대신 줄 단위 정렬 필터로 변경 (List.pas: LoadPlaylist)
  [*] 시작 로드의 목록 추가를 BeginUpdate/EndUpdate 로 묶음 (List.pas: LoadPlaylist)

  0.9.4.0
  [*] 랜덤 재생이 한 바퀴 끝나면 반복 설정과 무관하게 새 사이클을 시작 (List.pas: Rand)
  [+] 없는 파일은 재생 시 목록에서 빼고 다음 곡으로 (List.pas: SkipMissing)
  [+] 목록에서 Del 키로 선택 항목 삭제 (List.pas: ListDataKeyDown)
  [+] 환경설정 '일반' 에 항상 위 - SetWindowPos 방식 (Main.pas: SetTopMost)
  [+] 환경설정 '연결' 카드 추가 - 확장자 38종을 KPlayer 로 연결/해제, 체크 즉시 반영 (Setup.pas: CardAssoc/TreeAssoc, AssocExts, AssocRegister/AssocUnregister)
  [+] 시작 시 등록된 파일 연결의 exe 경로 갱신 - 포터블 폴더 이동 대응 (Setup.pas: SyncFileAssoc / Main.FormCreate)
  [*] 지원 확장자를 AssocExts 하나로 통일 - AddFile 의 하드코딩 7종 제거 (List.pas: IsMediaFile)
  [+] 재생목록 파일(.m3u/.m3u8/.pls) 을 항목으로 펼침 - 상대경로/ANSI·UTF-8 판별 (List.pas: AddPlaylist)
  [+] 환경설정 전면 개편 - 디자이너 배치, 카드별 즉시 적용, 기본값 복원을 좌측 메뉴로 (Setup.pas/Setup.dfm)
  [+] 키보드 볼륨/재생 조작 시 화면 중앙 인디케이터 - 페이드 인·아웃 + 아이콘 줌 (KPlayer.lua: draw_bezel, show_bezel)
  [+] OSD 글꼴을 윈도우 UI 기본 폰트로 맞춤 - script-message ui-font (Main.FormCreate / KPlayer.lua)
  [*] 캡처 기본 저장 폴더를 바탕화면으로 - 미지정 시 exe 폴더를 쓰지 않는다 (Setup.pas: DesktopPath)
  [*] 자막 트랙이 없으면 자막 버튼을 만들지 않음 (KPlayer.lua: calc_layout)
  [*] Lua 메시지를 영어로, 배속 토스트는 '1.5x' 형식으로 (KPlayer.lua)
  [*] 키보드 조작 시 상단/하단 컨트롤바가 뜨지 않게 - seek/playback-restart 이벤트 제거 (KPlayer.lua)
  [*] 대화상자를 TaskMessageDlg 로 - 버튼 캡션/아이콘을 OS 가 제공 (Setup.pas)
  [-] TDragFile 이 해제되지 않던 문제 수정 (List.pas: FDragFile)
  [-] 마우스 이동 등 불필요한 로그 제거, mpv 로그 파일은 기본 미사용 (Main.pas, MPVPlayer.pas)
  [+] 확장자별 파일 연결 아이콘 - exe 옆 Icon\<확장자>.ico 사용, 없으면 exe 아이콘으로 폴백 (Assoc.pas: ExtIconRef, AssocRegister)
  [+] 제거 시 파일 연결 원복 - KPlayer.exe /uninst 로 등록분 전체 해제 후 창 없이 종료 (KPlayer.dpr, Assoc.pas: AssocUnregisterAll)
  [*] 연결 해제를 확장자 기반으로 분리 - 노출 목록(AssocExts)에서 빠진 확장자도 소유 목록으로 해제 (Assoc.pas: AssocUnregisterExt)
  [+] Inno Setup 설치 스크립트 추가 - 사용자별 설치(%LOCALAPPDATA%\Programs\KPlayer), Icon 폴더 동봉 (KPlayer.iss)

  0.9.3.0
  [+] 키보드 배속 조절 추가 - Z(1.0 리셋)/X(-0.1)/C(+0.1), 수식키 없을 때만, 0.1 단위 정규화·0.25~4.0 clamp (SetSpeed, AddSpeed, FormKeyDown)
  [+] 배속 변경 시 화면 중앙 OSD 토스트 표시 (KPlayer.lua: draw_speed_toast, show_speed_toast, speed observer)
  [+] 자막 토글 버튼 추가 - 트랙 유무로 활성/비활성, 클릭 시 표시 토글 (KPlayer.lua: icons.sub, sub_btn, sid observer, render, click handler)
  [+] 랜덤 재생 중복 방지(셔플) - 사이클 내 미재생 곡만 선택 (Rand, PickRandomUnplayed, ResetShuffle, PruneShuffleMissing, FShuffleHistory/FShufflePos/FCyclePlayed)
  [*] 랜덤 중 이전곡을 셔플 순서상 실제 이전 곡으로 변경 (Prev)
  [+] 전체화면 마우스 커서 자동 숨김 - 컨트롤바 표시에 동기화 (KPlayer.lua: update_cursor / OnScriptMessage 'cursor', HandleFullScreen)
  [*] 전체화면 해제를 mpv fullscreen 속성으로 일원화 (FormKeyDown: VK_ESCAPE)
  [*] 재생 목록 노드 높이 고정 처리 방식 변경 - toVariableNodeHeight 제거, DefaultNodeHeight := 24 설정 (TFrmList.FormCreate)
  [*] 노드 추가 시 높이값 직접 지정 - ListData.NodeHeight[Node] := 24 추가 (TFrmList.AddFile)
  [+] 오디오 노멀라이징(음량 평준화) 추가

  0.9.2.0
  [*] 실행 인자에 전달된 기존 파일을 재생 목록에 추가하고 첫 파일을 자동 재생하도록 처리

  0.9.1.0
  [*] 렌더링 및 디코딩 기본 옵션 추가 - vo=gpu, hwdec=auto-safe, gpu-api=auto 설정 추가
  [*] 화면 동기화 옵션 추가 - video-sync=display-resample 설정 추가
  [*] 인터레이싱 처리 방식 변경 - deinterlace=yes → deinterlace=auto 로 변경
  [*] 스케일링 옵션 조정 - scale=bilinear → scale=lanczos 변경, cscale=bilinear 유지

================================================================================}

unit Main;

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils, Types, Math, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls, Menus, LCLType, LCLIntf,
  MPVBasePlayer, MPVPlayer, Config, Hotkey, KilhoView, Thumb, OSUtil;

const
  // 중앙 알림 색 (RGB hex). 기본 파라미터에 쓰여 클래스 선언보다 앞 필수.
  ALERT_INFO  = 'FFFFFF';
  ALERT_WARN  = 'FFC048';
  ALERT_ERROR = 'FF5555';

type

  { TFrmKPlayer }

  TFrmKPlayer = class(TForm)
    PopMenu: TPopupMenu;     // Delphi 판 이름 'Menu' — LCL TForm.Menu(TMainMenu) 속성과 겹쳐 개명
    BtnAbout: TMenuItem;
    MnuOpenFile: TMenuItem;
    MnuOpenFolder: TMenuItem;
    N2: TMenuItem;
    MnuScreen: TMenuItem;
    MnuOrig50: TMenuItem;    // Tag = 배율 % = 캡션 '50%'~'200%' (숫자라 번역 없음, PotPlayer·GOM 관례. 공용 MnuOriginalClick)
    MnuOrig100: TMenuItem;
    MnuOrig150: TMenuItem;
    MnuOrig200: TMenuItem;
    MnuFull: TMenuItem;
    MnuStretch: TMenuItem;
    N3: TMenuItem;
    MnuPlayList: TMenuItem;
    MnuSettings: TMenuItem;
    N1: TMenuItem;
    MnuExit: TMenuItem;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormDropFiles(Sender: TObject; const FileNames: array of string);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormMouseWheel(Sender: TObject; Shift: TShiftState;
      WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
    procedure MenuPopup(Sender: TObject);
    procedure MnuOpenFileClick(Sender: TObject);
    procedure BtnAboutClick(Sender: TObject);
    procedure MnuOpenFolderClick(Sender: TObject);
    procedure MnuOriginalClick(Sender: TObject);
    procedure MnuFullClick(Sender: TObject);
    procedure MnuStretchClick(Sender: TObject);
    procedure MnuPlayListClick(Sender: TObject);
    procedure MnuSettingsClick(Sender: TObject);
    procedure MnuExitClick(Sender: TObject);
  private
    FConfig: TConfig;
    FHook: TObject;         // Win32 서브클래스 (WM_NCHITTEST 가장자리 리사이즈, WM_DEVICECHANGE) — OSUtil
    FVolume: Double;
    FRepeatMode: Integer;
    FRandomMode: Integer;
    // 영상 위 UI (KilhoUI 투명 뷰). mpv 는 FView.Handle 안에 영상 창을 만든다 — KilhoUI 창과 형제라야 위에 겹친다.
    FView: TKilhoView;
    FViewWnd: THandle;      // KilhoUI 의 실제 자식 창 (가장자리 훅·맨 위 확인)
    FViewHook: TObject;     // FViewWnd 서브클래스 — 창 전체를 덮어 폼의 WM_NCHITTEST 가장자리가 안 오므로 여기서
    FRaiseTimer: TTimer;    // mpv 영상 창이 뷰 위로 올라오면 다시 올림 (RaiseTimerTick)
    FLastDownTick: QWord;   // 더블클릭 판정 (ViewMouseDown)
    FLastDownPos: TPoint;
    // 컨트롤 UI (ui\player.html). 상태는 FUi 의 클래스, 값은 RefreshUI 가 mpv 에서 읽어 넣는다.
    FUi, FElTitle, FElProgress, FElPlayed, FElThumb, FElTip, FElTime: TKElement;
    FElVolSlider, FElVolFill, FElVolThumb, FElChapters: TKElement;
    FHideTimer: TTimer;     // 컨트롤 자동 숨김 2초 (Lua autohide_timeout)
    FUiTimer: TTimer;       // mpv 상태 → DOM 100ms. 바뀐 값만 DOM 에 쓴다 (엔진이 바뀐 영역만 그림)
    FCtlHidden: Boolean;
    FDrag: Integer;        // 0 없음 / 1 진행바 / 2 음량 — 누른 채 끄는 중
    FDragPos: Double;       // 진행바 드래그 중 표시 위치(초) — 탐색이 따라오기 전에도 손끝을 따른다
    FSeekBusy: Boolean;     // 진행바 끌기 탐색이 진행 중 (보냄 → PLAYBACK_RESTART 전) — 그동안은 쌓지 않는다
    FSeekPending: Boolean;  // 진행 중에 손끝이 또 움직임 → 끝나면 FDragPos 로 한 번 더
    FDragResume: Boolean;   // 끌기 전에 재생 중이었다 → 놓을 때 재생 재개 (끄는 동안 일시정지)
    FSeekGuard: TTimer;     // 탐색 끝 알림이 안 오는 경우(같은 위치 등) 대비 — 1초 뒤 진행 중 해제
    FMoveX, FMoveY: Single; // 컨트롤 표시 1px 임계 기준점
    FLastPath, FLastTitle, FLastTime: string;
    FTimeShape: string;               // FLastTime 의 숫자를 '0' 으로 — 바뀌면(자리수·시간 단위) 칸을 다시 만든다
    FTimeDigit: array of TKElement;   // 글자 자리별 켜진 획 요소 (숫자 아닌 자리는 nil)
    FLastPlayed, FLastVol: Integer;
    FTbState: TTaskbarProgress;   // 작업 표시줄 진행률 마지막 값 (UpdateTaskbar)
    FTbPos: Integer;
    FElDisc: TKElement;     // 커버 없는 음악의 LP 라벨 (#lp-label) — DiscTimerTick 이 돌린다 (홈·반사광은 고정)
    FDiscTimer: TTimer;
    FAudioOnly: Boolean;    // #ui.audio — 오디오 트랙만 있고 영상(커버 포함) 없음
    FDiscAngle: Integer;    // 마지막으로 쓴 각도 (0.1도)
    FElDiscRing: TKElement; // LP 라벨 둘레 제목 (#lp-ring) — BuildDiscTitle
    FLastDur: Double;
    FShownDur: Double;      // 표기용 총 길이 (duration − 1프레임) — RefreshUI 가 채움
    // 화면 위 알림 (3단계) — 배속 토스트·베젤·중앙 알림·TAB 정보. 표시는 FUi 클래스, 끄는 건 1회 타이머 (Tag 로 구분)
    FElToast, FElBezelIco, FElPill, FElAlert: TKElement;
    FElInfo: array[0..8] of TKElement;
    FInfoText: array[0..8] of string;   // 바뀐 줄만 쓴다
    FToastTimer, FBezelTimer, FAlertTimer, FInfoTimer: TTimer;
    FInfoOn: Boolean;
    FBzPause, FBzVol: Integer;   // 직전 값 — 바뀌면 베젤. -1 = 아직 모름 (첫 값은 표시 안 함)
    FBzSpeed: Double;            // 0 = 아직 모름
    // 진행바 미리보기 (환경설정 '진행바 미리보기', INI seek_preview) — nil = 끔
    FThumb: TThumbnailer;
    FElPreview, FElPreviewImg: TKElement;
    FPvAlt: Boolean;             // 이미지 이름 번갈아 (pv-a / pv-b) — 같은 이름이면 엔진이 새 그림을 안 볼 수 있다
    FPvH: Integer;               // 상자 높이 (폭 160 기준, 영상 비율)
    FVerifyTimer: TTimer;  // 드라이브 변경 통지 뭉침 방지 (WndHook WM_DEVICECHANGE)
    FFullOnce: Boolean;     // 재생 창 크기 '전체 화면' 은 세션당 1회 (ESC 로 풀면 다음 곡에 다시 안 감)
    FStretch: Boolean;      // 꽉찬 화면 (keepaspect=no) 중 — 전체화면 해제 시 keepaspect 복원 판단
    FClickTimer: TTimer;    // 왼쪽 클릭 기능 지연 — 더블클릭이면 취소 (ViewMouseDown / ClickTimerTick)
    FForwardTimer: TTimer;  // 다른 실행이 넘긴 파일 묶기 (WndHook WM_COPYDATA → ForwardTimerTick, Instance.pas)
    FForwardFiles: TStringArray;
    FForwardAny: Boolean;   // 넘겨받은 것 있음 (빈 인자 실행 = 창만 앞으로)
    FLastOpenTick: QWord;   // 마지막 '열기' 처리 시각 (시작 인자·넘겨받은 묶음) — 다중 선택 판정

    procedure KeyDownBefore(Sender: TObject; var Key: Word; Shift: TShiftState);
    function WndHook(AMsg: Cardinal; AW: PtrUInt; AL: PtrInt; var AHandled: Boolean): PtrInt;
    function ViewHook(AMsg: Cardinal; AW: PtrUInt; AL: PtrInt; var AHandled: Boolean): PtrInt;
    function EdgeHit(AL: PtrInt): PtrInt;
    function EdgeCursor(AHit: Word): Boolean;
    procedure SizeFromEdge(AHit: PtrUInt; AL: PtrInt);
    procedure RaiseTimerTick(Sender: TObject);
    procedure UncloakTimerTick(Sender: TObject);

    procedure ViewMouseDown(Sender: TObject; AEvent: TKEvent);
    procedure ViewWheel(Sender: TObject; AEvent: TKEvent);
    procedure ViewContextMenu(Sender: TObject; AEvent: TKEvent);
    procedure ViewMouseMove(Sender: TObject; AEvent: TKEvent);
    procedure ViewMouseUp(Sender: TObject; AEvent: TKEvent);
    procedure ViewImage(Sender: TObject; const AName: string; var ABytes: TBytes);

    procedure BuildUI;
    procedure CtlMouseDown(Sender: TObject; AEvent: TKEvent);
    procedure CtlClick(Sender: TObject; AEvent: TKEvent);
    procedure CtlAction(Data: PtrInt);
    procedure ProgressMouseDown(Sender: TObject; AEvent: TKEvent);
    procedure ProgressMouseMove(Sender: TObject; AEvent: TKEvent);
    procedure UpdateHover(AX: Single);
    function PreviewUsable: Boolean;
    procedure SendDragSeek;
    procedure SeekGuardTick(Sender: TObject);
    procedure MpvRestart(Sender: TObject);
    procedure DragPaint;
    procedure VolMouseDown(Sender: TObject; AEvent: TKEvent);
    procedure DragTo(AX: Single; AExact: Boolean);
    procedure RestoreFocus(Data: PtrInt);
    procedure ShowControls;
    procedure HideTimerTick(Sender: TObject);
    procedure UiTimerTick(Sender: TObject);
    procedure RefreshUI;
    procedure UpdateTaskbar(AIdle: Boolean);
    procedure CheckAudioOnly(AIdle: Boolean);
    procedure DiscTimerTick(Sender: TObject);
    procedure BuildDiscTitle(const ATitle: string);
    procedure RebuildChapters;
    procedure SetTimeDigits(const S: string);
    function OneShot(AInterval: Integer): TTimer;
    procedure OsdTimerTick(Sender: TObject);
    procedure CheckOsd(AIdle: Boolean);
    procedure ShowBezel(const AIcon, AText: string);
    procedure ShowToast(const AText: string);
    procedure ToggleInfo;
    procedure RefreshInfo;
    procedure InfoTimerTick(Sender: TObject);
    procedure ThumbReady(const ABytes: TBytes; AW, AH: Integer);
    procedure UpdateCursor;

    procedure MpvFullScreen(Sender: TObject; AValue: Boolean);
    procedure MpvEndReached(Sender: TObject);
    procedure MpvVolume(Sender: TObject; AValue: Double);

    procedure ExecAction(AAction: TKeyAction);
    procedure ExecMouse(AEvent: TMouseEvent);
    procedure ClickTimerTick(Sender: TObject);
    procedure HandleClose;
    procedure HandleMinimize;
    procedure HandleZoomIn(AStep: Double);
    procedure HandleZoomOut(AStep: Double);
    procedure HandleFullScreen(AState: Boolean);
    procedure EnterFullScreen(AStretch: Boolean);
    procedure HandleSettings;
    procedure HandlePlayList;
    procedure HandleVideoSize(ASender: TObject; AWidth, AHeight: Integer);
    procedure RestoreWindow;
    procedure SaveWindow;
    procedure ResizeWindow(AWidth, AHeight: Integer);

    procedure DeviceChanged;
    procedure VerifyTimerTick(Sender: TObject);
    procedure ForwardTimerTick(Sender: TObject);

    procedure StartUpdateCheck;
    procedure UpdateResult(Quit: Boolean; const Data: string);

    procedure SetVolume(const Value: Double);
    procedure SetRandomMode(const Value: Integer);
    procedure SetRepeatMode(const Value: Integer);

    procedure SetSpeed(const Value: Double);
    procedure AddSpeed(const Delta: Double);
    procedure AddVolume(const Delta: Integer);

    function CfgOpt(const AKey: string; const AValues: array of string): string;
  public
    MPVPlayer: TMPVPlayer;

    function IsPlay: Boolean;
    function IsLoaded: Boolean;
    function IsEOF: Boolean;
    procedure SetPause(AState: Boolean);
    procedure AddSubtitles(const AFiles: TStringArray);
    procedure Alert(const AMsg: string; const AColor: string = ALERT_INFO);

    procedure HandlePlay(const AFile: string);
    procedure HandleStop;
    procedure HandlePause;
    procedure HandleStartupParams;
    procedure SetTopMost(AState: Boolean);
    procedure ApplyWindowMode;
    procedure SetSeekPreview(AOn: Boolean);

    property Config: TConfig read FConfig;
    property Volume: Double read FVolume write SetVolume;
    property RepeatMode: Integer read FRepeatMode write SetRepeatMode;
    property RandomMode: Integer read FRandomMode write SetRandomMode;
  end;

var
  FrmKPlayer: TFrmKPlayer;

implementation

{$R *.lfm}

uses
  {$IFDEF WINDOWS}Windows, MPVClient,{$ENDIF}
  List, Setup, Assoc, Media, KTranslate, KTheme, KUpdate, Instance, LazUTF8;

{$I Const.inc}

// 'MPV DLL 로드 실패' 뒤에 붙일 원인. 문구 하나로는 파일 없음(백신 격리 등)·의존 DLL 없음(126 — 1.1.8.0 libmpv 는
// vulkan-1.dll 을 직접 import, 드라이버에 Vulkan 없는 PC 에서 실패 추정)·손상(193)이 안 갈린다 → 다시 열어 오류 코드를 본다
function MPVLoadError: string;
{$IFDEF WINDOWS}
var
  LPath: string;
  H: HMODULE;
  Err: DWORD;
  Buf: array[0..511] of WideChar;
  N: DWORD;
  W: WideString;
  OldMode: UINT;
begin
  LPath := ExtractFilePath(ParamStr(0)) + MPVDLL;
  if not FileExists(LPath) then
    Exit(_('파일이 없습니다') + LineEnding + LPath);
  OldMode := SetErrorMode(SEM_FAILCRITICALERRORS or SEM_NOOPENFILEERRORBOX);
  try
    H := LoadLibraryW(PWideChar(UTF8Decode(LPath)));
    Err := GetLastError;
  finally
    SetErrorMode(OldMode);
  end;
  if H <> 0 then
  begin
    FreeLibrary(H);
    Exit(LPath);
  end;
  // SysErrorMessage 는 A 판(CP949) → 깨짐. W 판으로
  N := FormatMessageW(FORMAT_MESSAGE_FROM_SYSTEM or FORMAT_MESSAGE_IGNORE_INSERTS, nil, Err, 0, @Buf[0], Length(Buf), nil);
  SetString(W, PWideChar(@Buf[0]), N);
  Result := Trim(UTF8Encode(W)) + Format(' (%d)', [Err]);
  if Err = ERROR_MOD_NOT_FOUND then
    Result := Result + LineEnding + _('필요한 다른 DLL 이 없습니다 (그래픽 드라이버의 vulkan-1.dll 등)');
  Result := Result + LineEnding + LPath;
end;
{$ELSE}
begin
  Result := '';
end;
{$ENDIF}

procedure TFrmKPlayer.FormCreate(Sender: TObject);
var
  LLogFile, LSubLang: string;
begin
  //Lang := 'en';
  // 언어: --lang > 설정 '일반 - 언어'(auto = 건너뜀) > OS (INIT.md 언어 결정 규칙). 화면 번역 전에 → INI 를 먼저 연다.
  // 업데이트 대화상자(KUpdate)도 이 Lang — 앱이 번역 안 한 언어로도 뜨는 것은 의도 (INIT.md).
  FConfig := TConfig.Create(AppName);
  Lang := ResolveLang(FConfig.ReadString('language', 'auto'));
  Translate(Self);
  Application.Title := Caption;

  // BorderStyle = bsNone 은 LFM 에서 — 여기서 바꾸면 핸들 재생성 (mpv wid 무효·SetFormCorners 소실)
  SetFormCorners(Handle, True);

  // Win11 은 칠하기 전 창을 흰색으로 채워 보인다 (라이트 모드 실측) → 첫 그리기 끝날 때까지 가림.
  // WM_TIMER 는 WM_PAINT 보다 뒤에 처리되므로 1회 타이머에서 풀면 칠해진 뒤 나타난다.
  SetWindowCloak(Handle, True);
  with TTimer.Create(Self) do
  begin
    Interval := 10;
    OnTimer := UncloakTimerTick;
  end;

  LoadKeys(FConfig);   // 단축키 표 (Hotkey.pas) — FormKeyDown 이 본다
  LoadMouse(FConfig);

  FClickTimer := TTimer.Create(Self);
  FClickTimer.Enabled := False;
  FClickTimer.Interval := GetDoubleClickTime;
  FClickTimer.OnTimer := ClickTimerTick;
  RestoreWindow;

  Volume := FConfig.ReadDouble('volume', 100);
  RepeatMode := FConfig.ReadInteger('repeat', 0);
  RandomMode := FConfig.ReadInteger('random', 0);

  if not MPVLibLoaded(ExtractFilePath(ParamStr(0))) then
  begin
    ShowMessage(_('MPV DLL 로드 실패') + LineEnding + LineEnding + MPVLoadError);
    Application.Terminate;
    Exit;
  end;

  // 영상 위 UI. 투명 뷰는 Open 전에 Transparent (KilhoUI DComp 합성). 정적 링크라 실패할 일이 없다.
  FView := TKilhoView.Create(Self);
  FView.Transparent := True;
  FView.Color := clBlack;   // 기본 clWindow(흰색)로 지워져 시작 때 mpv·UI 가 그리기 전 흰 창이 스쳤다 (LCL 창 클래스는 배경 브러시 없음)
  FView.Align := alClient;
  FView.TabStop := False;   // 켜 두면 폼 활성화 때 LCL 이 뷰를 ActiveControl 로 → 엔진 창이 키를 먹어 FormKeyDown 무반응 (2026-10-08 실측)
  FView.Parent := Self;
  FView.Open;
  BuildUI;
  FViewWnd := FindChildWindow(FView.Handle, 'KilhoUIView');
  if FViewWnd <> 0 then
    FViewHook := HookWindowMessages(FViewWnd, ViewHook);

  MPVPlayer := TMPVPlayer.Create;
  MPVPlayer.OnVideoSize := HandleVideoSize;
  MPVPlayer.OnFullScreen := MpvFullScreen;
  MPVPlayer.OnEndReached := MpvEndReached;
  MPVPlayer.OnVolume := MpvVolume;
  MPVPlayer.OnRestart := MpvRestart;

  // 파일 없어도 플레이어 종료 방지
  MPVPlayer.SetOptionString('idle', 'yes');

  // 예전 KPlayer.lua 가 하던 비UI 설정
  MPVPlayer.SetOptionString('osd-level', '0');        // mpv 기본 OSD 문구(add volume 등) 끔 — UI 는 뷰가 그린다
  MPVPlayer.SetOptionString('sub-margin-y', '40');    // 자막 아래 여백 고정 — 컨트롤바 따라 들썩이지 않게 (2026-09-11 결정)
  MPVPlayer.SetOptionString('sub-hinting', 'native'); // 자막 libass 힌팅 — 작은 글자 획이 픽셀에 맞음
  MPVPlayer.SetOptionString('volume-max', '100');     // 100 초과 금지 (lua 는 넘으면 되돌렸다)

  // 자막 기본 켬 (1.1.0.0 까지 끔 — 'smi 미지원' 문의로 오인, 2026-09-29)
  MPVPlayer.SubVisibleDefault := FConfig.ReadInteger('sub_visible', 1) <> 0;   // 파일마다 시작 때 적용 (MPVPlayer)
  if MPVPlayer.SubVisibleDefault then
    MPVPlayer.SetOptionString('sub-visibility', 'yes')
  else
    MPVPlayer.SetOptionString('sub-visibility', 'no');

  MPVPlayer.SetOptionString('sub-font-size', IntToStr(FConfig.ReadInteger('sub_size', 55)));
  // 기본 자막 언어: '' = OS 언어 기준 (Setup.DefaultSubLang)
  LSubLang := FConfig.ReadString('sub_lang', '');
  if LSubLang = '' then LSubLang := DefaultSubLang;
  MPVPlayer.SetOptionString('slang', LSubLang);

  // 환경설정 '영상' 카드 값 — 재시작 시에만 반영
  MPVPlayer.SetOptionString('vo', CfgOpt('vo', VoValues)); // 기본 = gpu-next 아닌 안정 버전
  MPVPlayer.SetOptionString('hwdec', CfgOpt('hwdec', HwdecValues));
  MPVPlayer.SetOptionString('gpu-api', CfgOpt('gpu_api', GpuApiValues));
  MPVPlayer.SetOptionString('video-sync', CfgOpt('video_sync', VideoSyncValues));

  // 영상 안정화 (필요시만 적용)
  MPVPlayer.SetOptionString('deinterlace', CfgOpt('deinterlace', DeintValues));

  // 스케일링 (품질/안정 균형)
  MPVPlayer.SetOptionString('scale', CfgOpt('scale', ScaleValues));
  MPVPlayer.SetOptionString('cscale', 'bilinear');

  // mpv 로그: 기본 미사용
  LLogFile := '';
  {$IFDEF DEBUG}
  //LLogFile := ExtractFilePath(ParamStr(0)) + 'KPlayer.log';
  {$ENDIF}

  // 4번째 인자 = 로그 경로, '' = 기록 안 함
  MPVPlayer.InitPlayer(IntToStr(FView.Handle), '', '', LLogFile, True);

  MPVPlayer.Command(['set', 'screenshot-directory', FConfig.ReadString('shot_dir', DesktopPath)]);

  // 자막 스타일 ('자막' 카드) — 글꼴·색·외곽선·위치·ASS 덮어쓰기. 즉시 반영도 같은 함수 (Setup.ApplyLive).
  ApplySubStyle(FConfig, MPVPlayer);

  SetSeekPreview(FConfig.ReadInteger('seek_preview', 1) <> 0);

  // EOF 시 마지막 프레임 정지 — 래퍼의 keep-open-pause=no 는 EOF 에도 pause=false → OSD 가 재생 중처럼 보임
  MPVPlayer.Command(['set', 'keep-open-pause', 'yes']);

  MPVPlayer.Command(['set', 'screenshot-template', '%f-%n']);
  MPVPlayer.Command(['set', 'screenshot-format', CfgOpt('shot_format', ShotFmtValues)]);
  MPVPlayer.Command(['set', 'volume', FloatToStr(Volume)]);

  // 음량 평준화 (환경설정 '음성' 카드)
  if FConfig.ReadInteger('normalize', 1) <> 0 then
    MPVPlayer.Command(['set', 'af', NormFilters[EnsureRange(FConfig.ReadInteger('norm_level', 1), 0, High(NormFilters))]]);

  // TAB 은 FormKeyDown 에 안 올 수 있다 — 포커스 이동 키라 위젯셋/LCL 이 먼저 먹는다
  // (VCL 실측 2026-08-28: Shift·Space·'\' 는 오는데 TAB 은 안 옴). 그래서 LCL 키 처리 맨 앞 단계에서 가로챈다.
  Application.AddOnKeyDownBeforeHandler(KeyDownBefore);

  // 파일 드롭 = LFM 의 AllowDropFiles + OnDropFiles (FormDropFiles). 관리자 실행이어도 탐색기 드롭 허용.
  AllowDropFromLowerIntegrity(Handle);

  // 가장자리 리사이즈(WM_NCHITTEST)·드라이브 변경(WM_DEVICECHANGE) — LCL 이 폼으로 안 넘기는 메시지라 서브클래스로
  FHook := HookWindowMessages(Handle, WndHook);

  SetTopMost(FConfig.ReadInteger('topmost', 0) <> 0);

  // mpv 영상 창은 init 뒤 비동기로 생기고 VO 재생성 때 다시 생긴다 (통지 없음, OSUtil.IsTopChild) → 확인해서 뷰를 올림.
  // LP 회전 — 커버 없는 음악이 보일 때만 켠다 (CheckAudioOnly). 100ms 폴링으로는 회전이 끊겨 보인다
  FDiscTimer := TTimer.Create(Self);
  FDiscTimer.Enabled := False;
  FDiscTimer.Interval := 30;
  FDiscTimer.OnTimer := DiscTimerTick;

  FRaiseTimer := TTimer.Create(Self);
  FRaiseTimer.Interval := 500;
  FRaiseTimer.OnTimer := RaiseTimerTick;

  // 드라이브 연결/해제 통지는 여러 번 연달아 온다 + 붙은 직후엔 아직 못 읽는다 → 2초 뒤 한 번만.
  FVerifyTimer := TTimer.Create(Self);
  FVerifyTimer.Enabled := False;
  FVerifyTimer.Interval := 2000;
  FVerifyTimer.OnTimer := VerifyTimerTick;

  // 다중 선택은 파일마다 따로 넘어온다 → 마지막 도착 후 300ms 에 한 번에.
  FForwardTimer := TTimer.Create(Self);
  FForwardTimer.Enabled := False;
  FForwardTimer.Interval := 300;
  FForwardTimer.OnTimer := ForwardTimerTick;

  // 설치 직후 (인스톨러 [Run] 이 /inst 로 실행, 칼무리 동일) — 주요 확장자 등록 후 평소처럼 계속 실행.
  // 포터블은 스위치가 없으니 등록 안 됨. 이후 실행은 아래 SyncFileAssoc 이 소유 목록만 유지.
  if FindCmdLineSwitch('inst', ['/'], True) then
    AssocRegisterMain;

  // 파일 연결 exe 경로 재기록 — 포터블 폴더 이동 시 옛 경로 방지
  SyncFileAssoc;

  StartUpdateCheck;
end;

// 닫는 순간 창부터 숨김. LCL 은 본체 창 Close 때 Application.Terminate 만 하고 안 숨김 → 정리(미리보기·본체 mpv
// terminate_destroy, FreeLibrary ≈ 0.2~0.3초+, 2026-10-19 실측) 동안 멈춘 창이 보여 '버벅' 거림. 소리도 먼저 끊는다
procedure TFrmKPlayer.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  if MPVPlayer <> nil then MPVPlayer.Command(['stop']);
  FrmList.Hide;
  Hide;
end;

procedure TFrmKPlayer.FormDestroy(Sender: TObject);
begin
  Application.RemoveOnKeyDownBeforeHandler(KeyDownBefore);
  MarkReady(Handle, False);   // 창 속성은 파괴 전에 떼야 한다 (Win32 규칙)
  FreeAndNil(FHook);
  FreeAndNil(FViewHook);

  SaveWindow;
  FreeAndNil(FThumb);   // 두 번째 mpv — DLL 이 살아 있을 때
  FreeAndNil(MPVPlayer);
  FreeAndNil(FConfig);
end;

// 업데이트 확인 (klib KUpdate). 비동기 — 호출은 바로 돌아온다.
procedure TFrmKPlayer.StartUpdateCheck;
var
  O: TKUpdateOptions;
begin
  {$IF AppInit = ''}
  Exit;   // 엔드포인트를 안 적은 빌드(견본 그대로) - 확인하지 않는다
  {$ELSE}
  O := DefaultUpdateOptions(AppInit);
  O.Host := Self;
  O.Debug := IsDebugBuild;   // 앱의 DEBUG (라이브러리 빌드와 무관)
  CheckUpdate(O, UpdateResult);
  {$ENDIF}
end;

// 최대 수십 초 뒤에 메인 스레드에서 불린다. QueueAsyncCall 문맥이라 Close 도 안전하다.
procedure TFrmKPlayer.UpdateResult(Quit: Boolean; const Data: string);
begin
  if Quit then Close;   // 사용자가 받기로 했다 - 브라우저가 열렸고 우리는 끝낸다
end;

// 본체 창 드롭 = 목록 교체 + 재생. 덧붙이려면 목록 창에 떨군다 (TFrmList.FormDropFiles).
// HandlePlay 직접 호출 시 mpv 만 재생, 목록 '재생 중' 표시 누락 → FrmList 경유.
// 재생 시작점은 드롭 경로가 아니라 목록에 실제로 들어간 첫 항목 (AddFiles 주석).
// 자막 파일은 목록 대신 재생 중 영상에 (AddSubtitles). 영상과 섞여 오면 자막은 버린다 — 새 영상에
// 붙일 시점(file-loaded)을 잡는 대신 sub-auto 자동 로드에 맡김.
procedure TFrmKPlayer.FormDropFiles(Sender: TObject; const FileNames: array of string);
var
  LFiles, LSubs: TStringArray;
  I, N, NS: Integer;
begin
  SetLength(LFiles, Length(FileNames));
  SetLength(LSubs, Length(FileNames));
  N := 0;
  NS := 0;
  for I := 0 to High(FileNames) do
    if IsSubtitleFile(FileNames[I]) then
    begin
      LSubs[NS] := FileNames[I];
      Inc(NS);
    end
    else
    begin
      LFiles[N] := FileNames[I];
      Inc(N);
    end;
  SetLength(LFiles, N);
  SetLength(LSubs, NS);

  if N > 0 then
    FrmList.ReplaceFiles(LFiles)
  else
    AddSubtitles(LSubs);
end;

// 외부 자막을 재생 중 영상에 추가 — 첫 파일 선택, 표시 켬 (떨군 것 = 보려는 것).
// 1.1.0.0 까지는 자막 드롭이 ReplaceFiles 로 가 목록만 비우고 재생이 멈췄다 (2026-09-29 문의).
procedure TFrmKPlayer.AddSubtitles(const AFiles: TStringArray);
var
  I: Integer;
begin
  if Length(AFiles) = 0 then Exit;
  if not IsLoaded then
  begin
    Alert(_('자막을 넣을 영상을 먼저 재생하세요'), ALERT_WARN);
    Exit;
  end;

  for I := 0 to High(AFiles) do
    if I = 0 then
      MPVPlayer.Command(['sub-add', SamiLoadPath(AFiles[I]), 'select'])
    else
      MPVPlayer.Command(['sub-add', SamiLoadPath(AFiles[I]), 'auto']);
  MPVPlayer.Command(['set', 'sub-visibility', 'yes']);
  Alert(_('자막을 불러왔습니다') + ' — ' + ExtractFileName(AFiles[0]));
end;

// mpv fullscreen 속성 = 단일 상태원 — 키·메뉴·더블클릭 어디서 바꿔도 여기로 (MPVPlayer.OnFullScreen)
procedure TFrmKPlayer.MpvFullScreen(Sender: TObject; AValue: Boolean);
begin
  HandleFullScreen(AValue);
end;

procedure TFrmKPlayer.MpvEndReached(Sender: TObject);
begin
  FrmList.TrackFinished;
end;

procedure TFrmKPlayer.MpvVolume(Sender: TObject; AValue: Double);
begin
  Volume := AValue;
end;

// 콤보 인덱스(INI) → mpv 옵션 문자열
function TFrmKPlayer.CfgOpt(const AKey: string; const AValues: array of string): string;
begin
  Result := AValues[EnsureRange(FConfig.ReadInteger(AKey, 0), 0, High(AValues))];
end;

procedure TFrmKPlayer.SetRandomMode(const Value: Integer);
begin
  FRandomMode := Value;
  FConfig.WriteInteger('random', Value);

  if FrmList <> nil then
    FrmList.UpdateModeIcons;
end;

procedure TFrmKPlayer.SetRepeatMode(const Value: Integer);
begin
  FRepeatMode := Value;
  FConfig.WriteInteger('repeat', Value);

  // 목록 창 아이콘 즉시 갱신 — FormCreate 의 INI 읽기 시점엔 FrmList 없음
  if FrmList <> nil then
    FrmList.UpdateModeIcons;
end;

procedure TFrmKPlayer.SetVolume(const Value: Double);
begin
  FVolume := Value;
  FConfig.WriteDouble('volume', Value);
end;

// 음량 증감. 무음 중이라도 결과 음량이 0 이 아니면 무음 해제 (KPlayer.lua 슬라이더와 동일 규칙).
procedure TFrmKPlayer.AddVolume(const Delta: Integer);
var
  LVol: Double;
  LMute: Boolean;
begin
  if MPVPlayer = nil then Exit;

  MPVPlayer.Command(['add', 'volume', IntToStr(Delta)]);

  LVol := 0;
  // TMPVErrorCode 는 Integer — 음수만 실패 (MPV_ERROR_SUCCESS 는 MPVClient 유닛이라 uses 밖).
  if MPVPlayer.GetPropertyDouble('volume', LVol) < 0 then Exit;
  if LVol <= 0 then Exit;

  LMute := False;
  if (MPVPlayer.GetPropertyBool('mute', LMute) >= 0) and LMute then
    MPVPlayer.SetPropertyBool('mute', False);
end;

const
  SpeedMin = 0.25;
  SpeedMax = 4.0;

procedure TFrmKPlayer.SetSpeed(const Value: Double);
begin
  MPVPlayer.SetPropertyDouble('speed', EnsureRange(Value, SpeedMin, SpeedMax));
end;

procedure TFrmKPlayer.AddSpeed(const Delta: Double);
var
  LCur: Double;
begin
  LCur := 1.0;
  MPVPlayer.GetPropertyDouble('speed', LCur);
  SetSpeed(Round((LCur + Delta) * 10) / 10);
end;

// 창 프로시저 가로채기 (OSUtil.HookWindowMessages).
//   WM_NCHITTEST   가장자리 8px = 리사이즈 (테두리 없는 창). 전체화면(최대화) 중엔 안 함.
//   WM_NCLBUTTONDOWN 가장자리 누름 → RunSizingLoop (WS_THICKFRAME 없으면 기본 처리가 크기 조절 안 함).
//   WM_NCCALCSIZE  그 루프 동안의 WS_THICKFRAME 테두리 없앰.
//   WM_DEVICECHANGE USB·네트워크 드라이브가 붙거나 빠지면 목록의 '없는 파일' 판정이 통째로 뒤집힌다.
//   WM_COPYDATA    다른 실행이 넘긴 파일 (Instance.pas). 보낸 쪽이 SendMessage 로 기다리므로 여기선 모으기만.
function TFrmKPlayer.WndHook(AMsg: Cardinal; AW: PtrUInt; AL: PtrInt;
  var AHandled: Boolean): PtrInt;
{$IFDEF WINDOWS}
const
  DBT_DEVICEARRIVAL        = $8000;
  DBT_DEVICEREMOVECOMPLETE = $8004;
  DBT_DEVNODES_CHANGED     = $0007;
var
  LFiles: TStringArray;
  I, N: Integer;
{$ENDIF}
begin
  Result := 0;
  {$IFDEF WINDOWS}
  case AMsg of
    WM_NCHITTEST:
      begin
        Result := EdgeHit(AL);
        AHandled := Result <> 0;   // 가장자리 아님 → 기본 처리
      end;

    // 가장자리 커서 — LCL 이 폼 Cursor 로 덮어 화살표로 남는다
    WM_SETCURSOR:
      if (AW = PtrUInt(Handle)) and EdgeCursor(LoWord(DWORD(AL))) then
      begin
        Result := 1;
        AHandled := True;
      end;

    WM_NCLBUTTONDOWN:
      if (AW >= HTLEFT) and (AW <= HTBOTTOMRIGHT) and (WindowState <> wsMaximized) then
      begin
        SizeFromEdge(AW, AL);
        AHandled := True;
      end;

    // RunSizingLoop 동안 켜는 WS_THICKFRAME 테두리 제거 — 창 전체를 클라이언트로
    WM_NCCALCSIZE:
      if AW <> 0 then
        AHandled := True;   // Result = 0

    // DBT_DEVNODES_CHANGED 까지 받는 이유 — 매핑 드라이브 복구가 볼륨 통지 없이 오는 경우가 있다.
    WM_DEVICECHANGE:
      if (AW = DBT_DEVICEARRIVAL) or (AW = DBT_DEVICEREMOVECOMPLETE) or
         (AW = DBT_DEVNODES_CHANGED) then
        DeviceChanged;

    WM_COPYDATA:
      if DecodeForwarded(AL, LFiles) then
      begin
        N := Length(FForwardFiles);
        SetLength(FForwardFiles, N + Length(LFiles));
        for I := 0 to High(LFiles) do
          FForwardFiles[N + I] := LFiles[I];
        FForwardAny := True;
        FForwardTimer.Enabled := False;
        FForwardTimer.Enabled := True;
        Result := 1;   // 받음 — 보낸 쪽은 이걸 보고 끝낸다 (아니면 새로 실행)
        AHandled := True;
      end;
  end;
  {$ENDIF}
end;

// 가장자리 8px = 크기 조절 히트 코드 (HTLEFT..HTBOTTOMRIGHT), 아니면 0. 전체화면(최대화) 중엔 0.
// AL = WM_NCHITTEST 의 화면 좌표. 폼·KilhoUI 창(ViewHook) 공용 — 뷰가 창 전체를 덮어 폼에는 거의 안 온다.
function TFrmKPlayer.EdgeHit(AL: PtrInt): PtrInt;
const
  ResizeBorder = 8;
var
  P: TPoint;
  IsLeft, IsRight, IsTop, IsBottom: Boolean;
begin
  Result := 0;
  if WindowState = wsMaximized then Exit;

  P := ScreenToClient(Types.Point(SmallInt(LoWord(DWORD(AL))), SmallInt(HiWord(DWORD(AL)))));

  IsLeft   := P.X <= ResizeBorder;
  IsRight  := P.X >= Width  - ResizeBorder;
  IsTop    := P.Y <= ResizeBorder;
  IsBottom := P.Y >= Height - ResizeBorder;

  if      IsLeft  and IsTop    then Result := HTTOPLEFT
  else if IsRight and IsTop    then Result := HTTOPRIGHT
  else if IsLeft  and IsBottom then Result := HTBOTTOMLEFT
  else if IsRight and IsBottom then Result := HTBOTTOMRIGHT
  else if IsLeft               then Result := HTLEFT
  else if IsRight              then Result := HTRIGHT
  else if IsTop                then Result := HTTOP
  else if IsBottom             then Result := HTBOTTOM;
end;

// 가장자리 히트면 크기 조절 커서를 걸고 True
function TFrmKPlayer.EdgeCursor(AHit: Word): Boolean;
begin
  Result := False;
  {$IFDEF WINDOWS}
  if WindowState = wsMaximized then Exit;
  case AHit of
    HTLEFT, HTRIGHT:             Windows.SetCursor(LoadCursor(0, IDC_SIZEWE));
    HTTOP, HTBOTTOM:             Windows.SetCursor(LoadCursor(0, IDC_SIZENS));
    HTTOPLEFT, HTBOTTOMRIGHT:    Windows.SetCursor(LoadCursor(0, IDC_SIZENWSE));
    HTTOPRIGHT, HTBOTTOMLEFT:    Windows.SetCursor(LoadCursor(0, IDC_SIZENESW));
  else
    Exit;
  end;
  Result := True;
  {$ENDIF}
end;

// 가장자리 누름 → 폼 크기 조절 루프 (끝나야 돌아온다)
procedure TFrmKPlayer.SizeFromEdge(AHit: PtrUInt; AL: PtrInt);
{$IFDEF WINDOWS}
var
  R: Windows.RECT;
{$ENDIF}
begin
  {$IFDEF WINDOWS}
  RunSizingLoop(Handle, AHit, AL);
  // 루프 중 LCL 은 WS_THICKFRAME 기준으로 Width = 창 − 14 를 기억, 스타일 복원(SWP_NOSIZE)으론 안 고침
  // → 저장 크기가 14px 작아짐 (실측). 실제 창 크기로 다시 맞춘다.
  GetWindowRect(Handle, R);
  SetBounds(R.Left, R.Top, R.Right - R.Left, R.Bottom - R.Top);
  {$ENDIF}
end;

// KilhoUI 창 메시지 — 창 전체를 덮으므로 가장자리 크기 조절을 여기서 (폼 WndHook 와 같은 규칙).
// WM_NCLBUTTONDOWN 은 엔진의 마우스 처리(포커스·캡처)를 거치지 않는다.
function TFrmKPlayer.ViewHook(AMsg: Cardinal; AW: PtrUInt; AL: PtrInt;
  var AHandled: Boolean): PtrInt;
begin
  Result := 0;
  {$IFDEF WINDOWS}
  case AMsg of
    WM_NCHITTEST:
      begin
        Result := EdgeHit(AL);
        AHandled := Result <> 0;
      end;
    WM_SETCURSOR:
      if (AW = PtrUInt(FViewWnd)) and EdgeCursor(LoWord(DWORD(AL))) then
      begin
        Result := 1;
        AHandled := True;
      end;
    WM_NCLBUTTONDOWN:
      if (AW >= HTLEFT) and (AW <= HTBOTTOMRIGHT) and (WindowState <> wsMaximized) then
      begin
        SizeFromEdge(AW, AL);
        AHandled := True;
      end;
    // 엔진은 누를 때·창 재활성화 때(WM_KUI_ACTIVE) 포커스를 가져간다 → 폼으로 (키는 FormKeyDown 이 VK 로 받는다).
    // 메시지 안에서 SetFocus 하지 않고 미룬다
    WM_SETFOCUS:
      Application.QueueAsyncCall(RestoreFocus, 0);
  end;
  {$ENDIF}
end;

procedure TFrmKPlayer.UncloakTimerTick(Sender: TObject);
begin
  TTimer(Sender).Enabled := False;
  SetWindowCloak(Handle, False);
end;

procedure TFrmKPlayer.RaiseTimerTick(Sender: TObject);
begin
  if (FViewWnd <> 0) and not IsTopChild(FView.Handle, FViewWnd) then
    FView.RaiseView;
end;

// 넘겨받은 파일 처리 (instance_mode, Instance.pas).
// 직전 '열기'(시작 인자·이전 묶음)에서 ForwardBurstMs 안이면 같은 다중 선택의 나머지 — 재생을 뺏지 않고 추가만.
// 안 그러면 탐색기에서 A·B·C 를 함께 열 때 A 가 재생되다 B·C 가 차례로 가로챈다.
// 재생 모드 첫 묶음은 기존 목록을 비운다 (ReplaceFiles, 1.1.7.0 — HandleStartupParams 와 같음).
// 목록에 추가 모드는 덧붙임, 멈춰 있으면 재생 (not IsPlay). 창은 재생 모드·빈 인자일 때만 앞으로.
procedure TFrmKPlayer.ForwardTimerTick(Sender: TObject);
const
  ForwardBurstMs = 1500;
var
  LFiles: TStringArray;
  LMode: Integer;
  LBurst: Boolean;
begin
  FForwardTimer.Enabled := False;
  if not FForwardAny then Exit;
  FForwardAny := False;
  LFiles := FForwardFiles;
  SetLength(FForwardFiles, 0);

  LMode := FConfig.ReadInteger('instance_mode', imPlay);
  if (LMode <> imEnqueue) or (Length(LFiles) = 0) then
    ActivateWindow(Handle);
  if Length(LFiles) = 0 then Exit;

  LBurst := GetTickCount64 - FLastOpenTick < ForwardBurstMs;
  FLastOpenTick := GetTickCount64;
  if (LMode <> imEnqueue) and not LBurst then
    FrmList.ReplaceFiles(LFiles)
  else
    FrmList.AddFiles(LFiles, not IsPlay);
end;

// 검사 자체는 배경 스레드(TFileCheckThread) 라 여기선 타이머만 다시 건다.
procedure TFrmKPlayer.DeviceChanged;
begin
  if FVerifyTimer <> nil then
  begin
    FVerifyTimer.Enabled := False;   // 통지 뭉침 → 마지막 것 기준으로 재시작
    FVerifyTimer.Enabled := True;
  end;
end;

procedure TFrmKPlayer.VerifyTimerTick(Sender: TObject);
begin
  FVerifyTimer.Enabled := False;

  if FrmList <> nil then
    FrmList.StartVerify(True);   // 재연결로 바뀌는 건 '없음 → 있음' 뿐
end;

procedure TFrmKPlayer.HandleClose;
begin
  MPVPlayer.Stop;
  Close;
end;

procedure TFrmKPlayer.HandleMinimize;
begin
  WindowState := wsMinimized;
end;

// 항상 위 ('일반' 카드 + 캡션 압정). fsStayOnTop 금지 — 핸들 재생성 시 mpv wid 무효 → 영상 사라짐.
// 재생목록 창도 같이 올림 (본체만 올리면 목록이 뒤로 숨음).
// 두 곳에서 조작하므로 여기서 INI 까지 기록 — 설정 창은 LoadValues 가 INI 를 다시 읽어 콤보가 맞는다.
procedure TFrmKPlayer.SetTopMost(AState: Boolean);
begin
  SetWindowTopMost(Self, AState);

  if FrmList <> nil then
    SetWindowTopMost(FrmList, AState);

  if FConfig <> nil then
    FConfig.WriteInteger('topmost', Ord(AState));
  if FUi <> nil then
    FUi.ClassSet('pinned', AState);   // 캡션 압정
end;

procedure TFrmKPlayer.HandleFullScreen(AState: Boolean);
begin
  if AState then
  begin
    SetFormCorners(Handle, False);
    WindowState := wsMaximized;
  end
  else
  begin
    WindowState := wsNormal;
    SetFormCorners(Handle, True);
    Screen.Cursor := crDefault;   // 창모드는 항상 커서 표시 (안전장치)
    if FStretch then
    begin
      FStretch := False;   // 꽉찬 화면은 전체화면에서만 — 창모드 복귀 시 비율 복원
      MPVPlayer.Command(['set', 'keepaspect', 'yes']);
    end;
  end;
  if FUi <> nil then
  begin
    FUi.ClassSet('fs', AState);   // 캡션 최대화 ↔ 복원 글리프
    UpdateCursor;
  end;
end;

// 우클릭 '화면 크기'. 전체 화면 = 비율 유지 / 꽉찬 화면 = keepaspect=no 로 여백 없이 늘림.
// 전체화면 진입은 mpv fullscreen 속성 경유 (observer → HandleFullScreen, 단일 상태원).
procedure TFrmKPlayer.EnterFullScreen(AStretch: Boolean);
begin
  FStretch := AStretch;
  if AStretch then
    MPVPlayer.Command(['set', 'keepaspect', 'no'])
  else
    MPVPlayer.Command(['set', 'keepaspect', 'yes']);
  MPVPlayer.Command(['set', 'fullscreen', 'yes']);
end;

procedure TFrmKPlayer.MenuPopup(Sender: TObject);
var
  HasVideo: Boolean;
begin
  HasVideo := (MPVPlayer <> nil) and (MPVPlayer.VideoWidth > 0);   // 체크 표시는 안 함 (사용자 결정)
  MnuOrig50.Enabled  := HasVideo;
  MnuOrig100.Enabled := HasVideo;
  MnuOrig150.Enabled := HasVideo;
  MnuOrig200.Enabled := HasVideo;
  MnuPlayList.Checked := FrmList.Visible;
end;

// 우클릭 '재생목록'(체크 = 목록 창 보임)/'환경설정'/'종료하기' — 하단 버튼·닫기 버튼과 같은 경로
procedure TFrmKPlayer.MnuPlayListClick(Sender: TObject);
begin
  HandlePlayList;
end;

procedure TFrmKPlayer.MnuSettingsClick(Sender: TObject);
begin
  HandleSettings;
end;

procedure TFrmKPlayer.MnuExitClick(Sender: TObject);
begin
  HandleClose;
end;

// 우클릭 '만든이' → 홈페이지 (Const.inc AppHome)
procedure TFrmKPlayer.BtnAboutClick(Sender: TObject);
begin
  OpenURL(AppHome);
end;

// 우클릭 '파일 열기'/'폴더 열기' — 목록 창 [추가] 메뉴·Ctrl+O 와 같은 경로
procedure TFrmKPlayer.MnuOpenFileClick(Sender: TObject);
begin
  FrmList.OpenFiles;
end;

procedure TFrmKPlayer.MnuOpenFolderClick(Sender: TObject);
begin
  FrmList.OpenFolder;
end;

// 화면 크기 n% = 창을 영상 픽셀 크기 × 배율(Tag %) 로 (화면보다 크면 비율 축소 — ResizeWindow). 전체화면 중이면 먼저 해제.
procedure TFrmKPlayer.MnuOriginalClick(Sender: TObject);
var
  Pct: Integer;
begin
  Pct := (Sender as TMenuItem).Tag;
  if WindowState = wsMaximized then
  begin
    MPVPlayer.Command(['set', 'fullscreen', 'no']);
    // observer 경유 해제는 비동기 (이벤트 스레드 → Synchronize) → 지금 바로 창모드로.
    // 나중에 오는 HandleFullScreen(False) 재호출은 무해 (멱등).
    HandleFullScreen(False);
  end;
  if MPVPlayer.VideoWidth > 0 then
    ResizeWindow(MPVPlayer.VideoWidth * Pct div 100, MPVPlayer.VideoHeight * Pct div 100);
end;

procedure TFrmKPlayer.MnuFullClick(Sender: TObject);
begin
  EnterFullScreen(False);
end;

procedure TFrmKPlayer.MnuStretchClick(Sender: TObject);
begin
  EnterFullScreen(True);
end;

procedure TFrmKPlayer.HandleZoomIn(AStep: Double);
var
  LCur: Double;
begin
  LCur := 0;
  MPVPlayer.GetPropertyDouble('video-zoom', LCur);
  MPVPlayer.SetPropertyDouble('video-zoom', LCur + AStep);
end;

procedure TFrmKPlayer.HandleZoomOut(AStep: Double);
var
  LCur: Double;
begin
  LCur := 0;
  MPVPlayer.GetPropertyDouble('video-zoom', LCur);
  MPVPlayer.SetPropertyDouble('video-zoom', LCur - AStep);
end;

// 파일 열림 여부 (일시정지도 True) — IsPlay 와 달리 idle 판정용
function TFrmKPlayer.IsLoaded: Boolean;
var
  LName: string;
begin
  Result := False;
  if MPVPlayer = nil then Exit;

  LName := '';
  MPVPlayer.GetPropertyString('filename', LName);
  Result := LName <> '';
end;

// EOF 정지 상태인가 (keep-open 이 마지막 프레임 유지 중)
function TFrmKPlayer.IsEOF: Boolean;
var
  LEOF: string;
begin
  Result := False;
  if MPVPlayer = nil then Exit;

  LEOF := '';
  MPVPlayer.GetPropertyString('eof-reached', LEOF);
  Result := SameText(LEOF, 'yes');
end;

// 화면 중앙 일시 알림 4.5초 (#alert). 색 = RGB hex (ALERT_* 상수), 6자리 아니면 흰색. 다시 오면 글만 바꾸고 시간 연장.
procedure TFrmKPlayer.Alert(const AMsg: string; const AColor: string);
begin
  if FUi = nil then Exit;
  FElAlert.Text := AMsg;
  if Length(AColor) = 6 then
    FElAlert.Attr['style'] := 'color:#' + AColor
  else
    FElAlert.Attr['style'] := '';
  FUi.ClassSet('alert', True);
  FAlertTimer.Enabled := False;
  FAlertTimer.Enabled := True;
end;

procedure TFrmKPlayer.SetPause(AState: Boolean);
const
  YesNo: array[Boolean] of string = ('no', 'yes');
begin
  if MPVPlayer <> nil then
    MPVPlayer.Command(['set', 'pause', YesNo[AState]]);
end;

function TFrmKPlayer.IsPlay: Boolean;
var
  Pause: string;
  FileName: string;
begin
  if MPVPlayer = nil then Exit(False);

  Pause := '';
  FileName := '';
  MPVPlayer.GetPropertyString('pause', Pause);
  MPVPlayer.GetPropertyString('filename', FileName);

  Result := (FileName <> '') and (Pause <> 'yes');
end;

// 재생 창 크기 ('일반' 카드 win_mode): 0=마지막 크기 유지 / 1=영상 크기에 맞춤 / 2=전체 화면.
// ('지정 크기' 는 넣었다 뺐다 — 2026-09-11 사용자 결정. 우클릭 '화면 크기' 배율로 충분.)
// mpv autofit/geometry 는 wid 임베드라 무효 (창 주인이 우리) → 여기서 직접.
// 시작 시 크기·위치는 항상 마지막 값. 문의 (2026-09-11): 640×400 고정이라 매번 늘려야 했다.
procedure TFrmKPlayer.RestoreWindow;
var
  R: TRect;
  L, T, W, H: Integer;
begin
  W := FConfig.ReadInteger('win_width', 640);
  H := FConfig.ReadInteger('win_height', 400);
  W := Max(W, Constraints.MinWidth);
  H := Max(H, Constraints.MinHeight);

  L := FConfig.ReadInteger('win_left', MaxInt);
  T := FConfig.ReadInteger('win_top', MaxInt);
  if (L = MaxInt) or (T = MaxInt) then
  begin
    // 위치 미저장 → 주 모니터 가운데. LFM 은 poDesigned 고정 — Position 을 런타임에 바꾸면
    // 핸들이 바뀌어 FormCreate 의 SetFormCorners·mpv wid 가 날아간다 (둥근 모서리 사라짐, 2026-09-13 VCL).
    R := Screen.WorkAreaRect;
    SetBounds(R.Left + (R.Right - R.Left - W) div 2, R.Top + (R.Bottom - R.Top - H) div 2, W, H);
    Exit;
  end;

  // 저장된 모니터가 빠졌거나 해상도가 줄었을 수 있다 → 그 자리의 작업 영역 안으로 당김.
  R := Screen.MonitorFromPoint(Types.Point(L + W div 2, T + H div 2)).WorkareaRect;
  W := Min(W, R.Right - R.Left);
  H := Min(H, R.Bottom - R.Top);
  L := EnsureRange(L, R.Left, R.Right - W);
  T := EnsureRange(T, R.Top, R.Bottom - H);
  SetBounds(L, T, W, H);
end;

// 전체화면(wsMaximized) 중 종료면 안 쓴다 — 최대화 좌표가 '마지막 크기' 로 남으면 안 됨.
procedure TFrmKPlayer.SaveWindow;
begin
  if (FConfig = nil) or (WindowState <> wsNormal) then Exit;
  FConfig.WriteInteger('win_left', Left);
  FConfig.WriteInteger('win_top', Top);
  FConfig.WriteInteger('win_width', Width);
  FConfig.WriteInteger('win_height', Height);
end;

// 창 중심 고정 리사이즈. 작업 영역 초과분은 비율 유지해 축소, 하한 = Constraints, 화면 밖이면 안으로.
procedure TFrmKPlayer.ResizeWindow(AWidth, AHeight: Integer);
var
  R: TRect;
  S: Double;
  L, T, RW, RH: Integer;
begin
  R := Monitor.WorkareaRect;
  RW := R.Right - R.Left;
  RH := R.Bottom - R.Top;
  if (AWidth > RW) or (AHeight > RH) then
  begin
    S := Math.Min(RW / AWidth, RH / AHeight);   // Windows 유닛의 정수 Min 과 구분
    AWidth := Round(AWidth * S);
    AHeight := Round(AHeight * S);
  end;
  AWidth := Max(AWidth, Constraints.MinWidth);
  AHeight := Max(AHeight, Constraints.MinHeight);

  L := EnsureRange(Left + (Width - AWidth) div 2, R.Left, R.Right - AWidth);
  T := EnsureRange(Top + (Height - AHeight) div 2, R.Top, R.Bottom - AHeight);
  SetBounds(L, T, AWidth, AHeight);
end;

// 파일별 첫 영상 크기 (MPVPlayer.OnVideoSize, UI 스레드). 오디오 전용은 안 온다.
// 맞춤은 곡마다 적용 (팟플레이어 동일). 목록에 해상도가 섞이면 창이 곡마다 바뀐다 —
// 거슬린다는 문의 오면 '첫 파일만' 옵션 추가.
procedure TFrmKPlayer.HandleVideoSize(ASender: TObject; AWidth, AHeight: Integer);
var
  Mode: Integer;
begin
  Mode := FConfig.ReadInteger('win_mode', 0);

  if Mode = 2 then
  begin
    if not FFullOnce then
    begin
      FFullOnce := True;
      MPVPlayer.Command(['set', 'fullscreen', 'yes']);   // 단일 상태원 → observer → HandleFullScreen
    end;
    Exit;
  end;

  if WindowState <> wsNormal then Exit;   // 전체화면·최소화 중엔 창 안 건드림

  if Mode = 1 then
    ResizeWindow(AWidth, AHeight);
end;

// 환경설정에서 바꾼 즉시 반영 (Setup.ApplyLive). 전체 화면 모드는 여기서 안 켠다 — 설정 창 위로 덮인다.
procedure TFrmKPlayer.ApplyWindowMode;
begin
  if WindowState <> wsNormal then Exit;
  if (FConfig.ReadInteger('win_mode', 0) = 1) and (MPVPlayer <> nil) and (MPVPlayer.VideoWidth > 0) then
    ResizeWindow(MPVPlayer.VideoWidth, MPVPlayer.VideoHeight);
end;

procedure TFrmKPlayer.HandlePlayList;
begin
  if FrmList.Visible then
  begin
    FrmList.Hide;
  end
  else
  begin
    FrmList.StartVerify(True);   // 없음 표시된 항목만 재확인 (전수 검사는 부하)
    FrmList.ShowPlaced(Self.Monitor);
  end;
end;

// 탐색기 더블클릭 / '연결 프로그램' / 명령줄로 들어온 경로.
// 인자를 그대로 Play 하면 안 된다 (AddFiles 주석과 같은 이유) — 재생목록(.m3u/.pls)은
// 항목이 아니라 내부 경로로 펼쳐지고, 폴더는 내용물만 항목이 되며, 비지원 확장자는
// 걸러진다. 셋 다 '목록에 없는 경로' 라 Play 가 그대로 mpv 에 넘겨 무반응이었다
// (재생목록을 열면 목록엔 들어오는데 재생이 안 걸려 더블클릭해야 시작됐다 — 2026-08-29 문의).
// → 드롭과 같은 AddFiles 로 넘겨 '목록에 실제로 들어간 첫 항목' 부터 재생.
// FileExists 로 거르지 않는다 — 폴더 인자가 통째로 무시됐다. 존재 확인은 AddFiles 의 배경 검사.
// 저장 목록은 버린다 (ReplaceFiles, 1.1.7.0 사용자 결정 — 전엔 덧붙였다). 미지원 인자뿐이면 목록 유지.
procedure TFrmKPlayer.HandleStartupParams;
var
  Files: TStringArray;
  LSwitch: Boolean;
begin
  // 스위치(/inst 등)는 StartupFiles 가 거른다. 넘겨받는 경로(Instance)와 같은 함수.
  Files := StartupFiles(LSwitch);
  if Length(Files) = 0 then
    Exit;

  FLastOpenTick := GetTickCount64;
  FrmList.ReplaceFiles(Files);
end;

procedure TFrmKPlayer.HandleSettings;
begin
  FrmSetup.ShowModal;
end;

procedure TFrmKPlayer.HandlePlay(const AFile: string);
begin
  if (MPVPlayer <> nil) and (AFile <> '') then
    MPVPlayer.OpenFile(AFile);
end;

procedure TFrmKPlayer.HandleStop;
begin
  if MPVPlayer <> nil then
    MPVPlayer.Stop;
end;

procedure TFrmKPlayer.HandlePause;
begin
  if MPVPlayer <> nil then
    MPVPlayer.Command(['cycle','pause']);
end;

// 키 → 동작은 Hotkey.KeyMap (환경설정 '단축키' 카드에서 변경). 여기 남는 건 고정 키뿐.
procedure TFrmKPlayer.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  A: TKeyAction;
begin
  if MPVPlayer = nil then Exit;

  case Key of
    VK_ESCAPE:
      begin
        // mpv fullscreen 속성 = 단일 상태원 (observer → HandleFullScreen)
        if WindowState = wsMaximized then
          MPVPlayer.Command(['set', 'fullscreen', 'no']);
        Key := 0;
      end;
  else
    if FindKeyAction(ShortCut(Key, Shift), A) then
    begin
      ExecAction(A);
      Key := 0;
    end;
  end;
end;

// 단축키 동작 본체 (옛 FormKeyDown case 문). 표 순서 = Hotkey.TKeyAction.
procedure TFrmKPlayer.ExecAction(AAction: TKeyAction);
var
  LSpeed: Double;
begin
  if MPVPlayer = nil then Exit;

  case AAction of
    kaPause:         FrmList.Play('');   // 열린 파일 없으면 다음 곡
    kaSeekBack:      MPVPlayer.Command(['seek', '-5']);
    kaSeekFwd:       MPVPlayer.Command(['seek', '5']);
    kaSeekBackExact: MPVPlayer.Command(['seek', '-1', 'exact']);
    kaSeekFwdExact:  MPVPlayer.Command(['seek', '1', 'exact']);
    kaChapterPrev:   MPVPlayer.Command(['add', 'chapter', '-1']);
    kaChapterNext:   MPVPlayer.Command(['add', 'chapter', '1']);
    kaFrameBack:     MPVPlayer.Command(['frame-back-step']);
    kaFrameFwd:      MPVPlayer.Command(['frame-step']);
    kaVolUp:         AddVolume(5);
    kaVolDown:       AddVolume(-5);
    kaVolUpFine:     AddVolume(2);
    kaVolDownFine:   AddVolume(-2);
    kaMute:          MPVPlayer.Command(['cycle', 'mute']);
    kaSpeedDown10, kaSpeedUp10:
      begin
        LSpeed := 1.0;
        MPVPlayer.GetPropertyDouble('speed', LSpeed);
        if AAction = kaSpeedDown10 then
          SetSpeed(LSpeed * 0.9091)
        else
          SetSpeed(LSpeed * 1.1);
      end;
    kaSpeedDown:     AddSpeed(-0.1);
    kaSpeedUp:       AddSpeed(0.1);
    kaSpeedReset:    SetSpeed(1.0);
    kaSubToggle:     MPVPlayer.Command(['cycle', 'sub-visibility']);
    kaSubNext:       MPVPlayer.Command(['cycle', 'sub']);
    kaSubPrev:       MPVPlayer.Command(['cycle', 'sub', 'down']);
    kaScreenshot:    MPVPlayer.Command(['screenshot']);
    kaFullScreen:    MPVPlayer.Command(['cycle', 'fullscreen']);
    kaListPrev:      FrmList.Prev;
    kaListNext:      FrmList.Next;
    kaOpenFile:      FrmList.OpenFiles;
    kaPlayList:      HandlePlayList;
    kaSettings:      HandleSettings;
    kaTopMost:       SetTopMost(FConfig.ReadInteger('topmost', 0) = 0);
  end;
end;

procedure TFrmKPlayer.FormMouseWheel(Sender: TObject; Shift: TShiftState;
  WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
begin
  if MPVPlayer = nil then Exit;

  if WheelDelta > 0 then
    ExecMouse(meWheelUp)
  else
    ExecMouse(meWheelDown);

  Handled := True;
end;

// 마우스 이벤트 → 기능 (Hotkey.MouseMap, 환경설정 '마우스' 카드)
procedure TFrmKPlayer.ExecMouse(AEvent: TMouseEvent);
begin
  if MPVPlayer = nil then Exit;

  case MouseMap[AEvent] of
    mfFullScreen: MPVPlayer.Command(['cycle', 'fullscreen']);
    mfStretch:
      if WindowState = wsMaximized then
        MPVPlayer.Command(['set', 'fullscreen', 'no'])
      else
        EnterFullScreen(True);
    mfPause:      ExecAction(kaPause);
    mfNextFile:   ExecAction(kaListNext);
    mfPrevFile:   ExecAction(kaListPrev);
    mfSeekFwd:    ExecAction(kaSeekFwd);
    mfSeekBack:   ExecAction(kaSeekBack);
    mfVolUp:      ExecAction(kaVolUp);
    mfVolDown:    ExecAction(kaVolDown);
  end;
end;

procedure TFrmKPlayer.ClickTimerTick(Sender: TObject);
begin
  FClickTimer.Enabled := False;
  ExecMouse(meLClick);
end;

// TAB = 재생/파일 정보 패널 토글 (ToggleInfo).
// FormKeyDown 이 아닌 여기서 받는다 — TAB 은 포커스 이동 키라 거기까지 안 올 수 있다 (FormCreate 주석).
// 본체 창이 활성일 때만 (환경설정·목록 창의 탭 이동은 그대로 둔다). Ctrl+Tab 은 창 전환이라 제외.
procedure TFrmKPlayer.KeyDownBefore(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key <> VK_TAB then Exit;
  if MPVPlayer = nil then Exit;
  if Screen.ActiveCustomForm <> Self then Exit;
  if ssCtrl in Shift then Exit;

  Key := 0;
  ToggleInfo;
end;

// 영상 영역 누름 (KilhoUI 뷰 — 창 전체를 덮어 폼 OnMouseDown 은 안 온다).
//   KilhoUI 창은 누를 때 포커스를 가져간다 → 폼으로 되돌린다. 단축키는 FormKeyDown 이 VK 그대로 받아야 한다
//   (엔진 키 코드는 숫자패드·OEM 키를 구별 못 함).
//   창모드 왼쪽 누름 → Windows 이동 루프 (뗄 때까지 안 돌아옴, OSUtil.StartWindowDrag). 돌아왔을 때 창이 안 움직였으면 '클릭'.
//   클릭 기능은 더블클릭 시간만큼 미뤄 실행 (FClickTimer) — 두 번째 누름이 그 안이면 취소하고 더블클릭 기능.
//   더블클릭은 직접 판정: 이동 루프가 뗌을 먹어 엔진이 dblclick 을 합성하지 못한다.
procedure TFrmKPlayer.ViewMouseDown(Sender: TObject; AEvent: TKEvent);
var
  R: TRect;
  P: TPoint;
  T: QWord;
begin
  LCLIntf.SetFocus(Handle);   // 폼 창 자체 — TForm.SetFocus 는 ActiveControl(뷰)로 넘길 수 있다
  if MPVPlayer = nil then Exit;

  if AEvent.MouseButton = 1 then
  begin
    ExecMouse(meMClick);
    Exit;
  end;
  if AEvent.MouseButton <> 0 then Exit;
  ShowControls;

  P := Mouse.CursorPos;
  T := GetTickCount64;
  if (T - FLastDownTick <= GetDoubleClickTime) and
     (Abs(P.X - FLastDownPos.X) <= GetSystemMetrics(SM_CXDOUBLECLK) div 2) and
     (Abs(P.Y - FLastDownPos.Y) <= GetSystemMetrics(SM_CYDOUBLECLK) div 2) then
  begin
    FLastDownTick := 0;
    FClickTimer.Enabled := False;
    ExecMouse(meDblClick);
    Exit;
  end;
  FLastDownTick := T;
  FLastDownPos := P;

  if WindowState <> wsMaximized then
  begin
    R := BoundsRect;
    if StartWindowDrag(Self) then
    begin
      // 이동 루프가 뗌을 먹어 엔진은 버튼이 눌린 채로 안다 → 이동마다 텍스트 선택이 늘어남. 뗌을 대신 넣는다
      {$IFDEF WINDOWS}
      if FViewWnd <> 0 then
      begin
        P := Mouse.CursorPos;
        Windows.ScreenToClient(FViewWnd, P);
        PostMessage(FViewWnd, WM_LBUTTONUP, 0, MAKELPARAM(Word(P.X), Word(P.Y)));
      end;
      {$ENDIF}
      if (MouseMap[meLClick] <> mfNone) and
         (R.Left = Left) and (R.Top = Top) and (R.Right = Left + Width) and (R.Bottom = Top + Height) then
        FClickTimer.Enabled := True;
      Exit;
    end;
  end;

  // 전체화면(또는 끌기 미지원 OS): 이동 없음 → 바로 클릭 후보
  if MouseMap[meLClick] <> mfNone then
    FClickTimer.Enabled := True;
end;

// 휠은 '비활성 창 스크롤'(Win10 기본 켬)이면 커서 아래 KilhoUI 창으로, 아니면 포커스(폼)로 → FormMouseWheel. 둘 다 같은 처리.
procedure TFrmKPlayer.ViewWheel(Sender: TObject; AEvent: TKEvent);
begin
  AEvent.PreventDefault;
  if MPVPlayer = nil then Exit;
  if AEvent.WheelDelta > 0 then
    ExecMouse(meWheelUp)
  else if AEvent.WheelDelta < 0 then
    ExecMouse(meWheelDown);
end;

// 우클릭 메뉴 — 엔진 기본 메뉴(텍스트 편집) 대신 PopMenu
procedure TFrmKPlayer.ViewContextMenu(Sender: TObject; AEvent: TKEvent);
begin
  AEvent.PreventDefault;
  OSUtil.PopupNativeMenu(PopMenu, Handle);   // KTheme 에도 같은 이름 (impl uses 가 가림)
end;

// ---- 컨트롤 UI·화면 알림. 디자인 원본 KPlayer.lua (git 에만, 1.1.6.0 에서 삭제) — 마크업·치수는 ui\player.html / player.css.

const
  // 버튼 id ↔ CtlAction 번호 (클릭은 지연 실행 — 리스너 안에서 모달 창·창 닫기를 하면 엔진 이벤트 처리 중에 재진입)
  CtlIds: array[0..11] of string = ('cap-pin', 'cap-min', 'cap-max', 'cap-close', 'btn-prev', 'btn-play',
    'btn-next', 'btn-mute', 'btn-sub', 'btn-set', 'btn-list', 'logo-disc');
  SeekReplyId = 9001;   // 탐색 명령 ID — 응답은 안 본다, 0 이 아니면 비동기 (mpv_command_async, DragTo)

var
  InvFmt: TFormatSettings;   // CSS·mpv 숫자는 소수점 '.' 고정

function ResText(const AName: string): string;
var
  R: TResourceStream;
begin
  Result := '';
  R := TResourceStream.Create(HInstance, AName, RT_RCDATA);
  try
    SetLength(Result, R.Size);
    if R.Size > 0 then
      R.ReadBuffer(Result[1], R.Size);
  finally
    R.Free;
  end;
end;

// Lua format_time 과 같음 — 1시간 미만은 m:ss
function FormatTime(ASec: Double): string;
var
  T: Int64;
begin
  if ASec < 0 then ASec := 0;
  T := Trunc(ASec);
  if T >= 3600 then
    Result := Format('%d:%.2d:%.2d', [T div 3600, (T mod 3600) div 60, T mod 60])
  else
    Result := Format('%d:%.2d', [T div 60, T mod 60]);
end;

// CSS url(이름.svg) → 리소스 ICON-이름 (KPlayerResource.rc)
procedure TFrmKPlayer.ViewImage(Sender: TObject; const AName: string; var ABytes: TBytes);
var
  R: TResourceStream;
begin
  try
    R := TResourceStream.Create(HInstance, 'ICON-' + UpperCase(ChangeFileExt(AName, '')), RT_RCDATA);
  except
    Exit;
  end;
  try
    SetLength(ABytes, R.Size);
    if R.Size > 0 then
      R.ReadBuffer(ABytes[0], R.Size);
  finally
    R.Free;
  end;
end;

procedure TFrmKPlayer.BuildUI;
var
  I: Integer;
  E: TKElement;
begin
  InvFmt := DefaultFormatSettings;
  InvFmt.DecimalSeparator := '.';

  FView.OnImageRequest := ViewImage;
  FView.LoadHtml(ResText('UI-HTML'));
  FView.LoadCss(ResText('UI-CSS'));

  FUi := FView.GetElementById('ui');
  FElTitle := FView.GetElementById('title');
  FElProgress := FView.GetElementById('progress');
  FElPlayed := FView.GetElementById('played');
  FElThumb := FView.GetElementById('thumb');
  FElTip := FView.GetElementById('tip');
  FElTime := FView.GetElementById('time');
  FElVolSlider := FView.GetElementById('vol-slider');
  FElVolFill := FView.GetElementById('vol-fill');
  FElVolThumb := FView.GetElementById('vol-thumb');
  FElChapters := FView.GetElementById('chapters');
  FElToast := FView.GetElementById('toast');
  FElBezelIco := FView.GetElementById('bezel-ico');
  FElPill := FView.GetElementById('bezel-pill');
  FElAlert := FView.GetElementById('alert');
  FElPreview := FView.GetElementById('preview');
  FElPreviewImg := FView.GetElementById('preview-img');
  FElDisc := FView.GetElementById('lp-label');
  FElDiscRing := FView.GetElementById('lp-ring');
  FPvH := 90;
  for I := 0 to High(FElInfo) do
    FElInfo[I] := FView.GetElementById('iv' + IntToStr(I));

  // 영상 영역(버튼 밖) — 창 끌기·클릭·휠·우클릭은 1단계 처리 그대로
  FView.Root.Listen('mousedown', ViewMouseDown);
  FView.Root.Listen('wheel', ViewWheel);
  FView.Root.Listen('contextmenu', ViewContextMenu);
  FView.Root.Listen('mousemove', ViewMouseMove);
  FView.Root.Listen('mouseup', ViewMouseUp);

  for I := 0 to High(CtlIds) do
  begin
    E := FView.GetElementById(CtlIds[I]);
    E.Listen('mousedown', CtlMouseDown);
    E.Listen('click', CtlClick);
  end;
  FElProgress.Listen('mousedown', ProgressMouseDown);
  FElProgress.Listen('mousemove', ProgressMouseMove);
  FElVolSlider.Listen('mousedown', VolMouseDown);

  FLastPlayed := -1;
  FLastVol := -1;
  FLastDur := -1;
  FCtlHidden := True;   // html 의 #ui.hidden

  FHideTimer := TTimer.Create(Self);
  FHideTimer.Enabled := False;
  FHideTimer.Interval := 2000;
  FHideTimer.OnTimer := HideTimerTick;

  FUiTimer := TTimer.Create(Self);
  FUiTimer.Interval := 100;
  FUiTimer.OnTimer := UiTimerTick;

  // 끄는 시점 = 총 표시 시간 − 페이드아웃 (player.css 의 transition 과 짝)
  FBzPause := -1;
  FBzVol := -1;
  FBzSpeed := 0;
  FToastTimer := OneShot(1000);         // 토스트 1초, 페이드 없음
  FBezelTimer := OneShot(1000 - 250);   // 베젤 1초, 나갈 때 .25
  FAlertTimer := OneShot(4500 - 600);   // 알림 4.5초, 나갈 때 .6
  FSeekGuard := TTimer.Create(Self);
  FSeekGuard.Enabled := False;
  FSeekGuard.Interval := 1000;
  FSeekGuard.OnTimer := SeekGuardTick;
  FInfoTimer := TTimer.Create(Self);
  FInfoTimer.Enabled := False;
  FInfoTimer.Interval := 1000;          // 시간·비트레이트·드롭 수가 계속 변한다
  FInfoTimer.OnTimer := InfoTimerTick;
end;

function TFrmKPlayer.OneShot(AInterval: Integer): TTimer;
begin
  Result := TTimer.Create(Self);
  Result.Enabled := False;
  Result.Interval := AInterval;
  Result.OnTimer := OsdTimerTick;
end;

procedure TFrmKPlayer.OsdTimerTick(Sender: TObject);
begin
  TTimer(Sender).Enabled := False;
  if Sender = FToastTimer then
    FUi.ClassSet('toast', False)
  else if Sender = FBezelTimer then
    FUi.ClassSet('bezel', False)
  else if Sender = FAlertTimer then
    FUi.ClassSet('alert', False);
end;

// 일시정지·음량·배속이 바뀌면 베젤/토스트 (Lua 속성 감시와 같은 규칙). 어디서 바꿨든 — 키·휠·버튼·메뉴.
//   첫 값은 기준만 잡는다 (시작 때 INI 음량 적용 등). 음량 슬라이더를 끄는 중엔 슬라이더가 값을 보여 준다.
//   시작 화면(idle)엔 베젤 없음 (CSS 도 숨김) — 기준만 따라간다.
procedure TFrmKPlayer.CheckOsd(AIdle: Boolean);
var
  B: Boolean;
  V: Double;
  N: Integer;
begin
  B := False;
  MPVPlayer.GetPropertyBool('pause', B, False);
  if (FBzPause >= 0) and (Ord(B) <> FBzPause) and not AIdle then
    if B then ShowBezel('i-pause', '') else ShowBezel('i-play', '');
  FBzPause := Ord(B);

  V := 0;
  MPVPlayer.GetPropertyDouble('volume', V, False);
  N := EnsureRange(Round(V), 0, 100);
  if (FBzVol >= 0) and (N <> FBzVol) and (FDrag <> 2) and not AIdle then
  begin
    B := False;
    MPVPlayer.GetPropertyBool('mute', B, False);
    if B then ShowBezel('i-mute', IntToStr(N) + '%') else ShowBezel('i-vol', IntToStr(N) + '%');
  end;
  FBzVol := N;

  V := 1;
  MPVPlayer.GetPropertyDouble('speed', V, False);
  if (FBzSpeed > 0) and not SameValue(V, FBzSpeed, 1e-6) then
    ShowToast(FormatFloat('0.##', V, InvFmt) + 'x');   // 꼬리 0 제거 — '1.5x', '1x'
  FBzSpeed := V;
end;

// 베젤 표시 중 다시 오면 아이콘·숫자만 바꾸고 시간 연장 (페이드인 재시작 안 함 — 연타 깜빡임). AText = '' 면 알약 없음.
procedure TFrmKPlayer.ShowBezel(const AIcon, AText: string);
const
  Icons: array[0..3] of string = ('i-play', 'i-pause', 'i-vol', 'i-mute');
var
  I: Integer;
begin
  for I := 0 to High(Icons) do
    FElBezelIco.ClassSet(Icons[I], Icons[I] = AIcon);
  if AText <> '' then FElPill.Text := AText;
  FUi.ClassSet('bzvol', AText <> '');
  FUi.ClassSet('bezel', True);
  FBezelTimer.Enabled := False;
  FBezelTimer.Enabled := True;
end;

procedure TFrmKPlayer.ShowToast(const AText: string);
begin
  FElToast.Text := AText;
  FUi.ClassSet('toast', True);
  FToastTimer.Enabled := False;
  FToastTimer.Enabled := True;
end;

procedure TFrmKPlayer.ToggleInfo;
begin
  if FUi = nil then Exit;
  FInfoOn := not FInfoOn;
  FUi.ClassSet('info', FInfoOn);
  FInfoTimer.Enabled := FInfoOn;
  if FInfoOn then RefreshInfo;
end;

procedure TFrmKPlayer.InfoTimerTick(Sender: TObject);
begin
  RefreshInfo;
end;

// TAB 정보 패널 값 (Lua info_rows 와 같은 항목·형식, 영어 고정). 값 없으면 '-' — 재생 전에도 패널은 뜬다.
procedure TFrmKPlayer.RefreshInfo;
var
  R: array[0..8] of string;
  I: Integer;
  N: Int64;
  D, Fps: Double;
  B: Boolean;
  S: string;
  W: UnicodeString;

  function P(const AName: string; const ADef: string = '-'): string;
  begin
    Result := '';
    MPVPlayer.GetPropertyString(AName, Result, False);
    if Result = '' then Result := ADef;
  end;

  function Num(const AName: string): Double;
  begin
    Result := 0;
    MPVPlayer.GetPropertyDouble(AName, Result, False);
  end;

  function Kbps(const AName: string): string;
  var
    V: Double;
  begin
    V := Num(AName);
    if V <= 0 then Result := '-' else Result := Format('%d kbps', [Round(V / 1000)]);
  end;

  function Size: string;
  var
    V: Int64;
  begin
    V := 0;
    MPVPlayer.GetPropertyInt64('file-size', V, False);
    if V <= 0 then Result := '-'
    else if V >= 1073741824 then Result := FormatFloat('0.00', V / 1073741824, InvFmt) + ' GB'
    else if V >= 1048576 then Result := FormatFloat('0.0', V / 1048576, InvFmt) + ' MB'
    else Result := FormatFloat('0', V / 1024, InvFmt) + ' KB';
  end;

  function Dim(const AName: string): string;
  var
    V: Int64;
  begin
    V := 0;
    if (MPVPlayer.GetPropertyInt64(AName, V, False) <> 0) or (V <= 0) then Result := '-' else Result := IntToStr(V);
  end;

begin
  if (MPVPlayer = nil) or not FInfoOn then Exit;

  // 긴 파일명은 60자(바이트 아님)에서 자름 — 화면을 넘지 않게
  W := UTF8Decode(P('filename'));
  if Length(W) > 60 then S := UTF8Encode(Copy(W, 1, 60)) + '...' else S := UTF8Encode(W);
  R[0] := S;
  R[1] := P('file-format') + '   ' + Size;
  R[2] := FormatTime(Num('time-pos')) + ' / ' + FormatTime(FShownDur) + '   x' +
          FormatFloat('0.##', Math.Max(Num('speed'), 0.0), InvFmt);

  Fps := Num('container-fps');
  if Fps <= 0 then Fps := Num('estimated-vf-fps');
  if Fps > 0 then S := FormatFloat('0.000', Fps, InvFmt) + ' fps' else S := '-';
  R[3] := P('video-format') + '   ' + Dim('width') + 'x' + Dim('height') + '   ' + S + '   ' + Kbps('video-bitrate');
  R[4] := P('current-tracks/video/decoder-desc') + '   hwdec: ' + P('hwdec-current', 'no');
  R[5] := P('audio-codec-name') + '   ' + P('audio-params/channel-count') + 'ch   ' +
          P('audio-params/samplerate') + ' Hz   ' + Kbps('audio-bitrate');

  S := P('sid', '');
  if (S <> '') and (S <> 'no') then
    R[6] := '#' + S + '   ' + P('current-tracks/sub/title', P('current-tracks/sub/lang', ''))
  else
    R[6] := 'off';

  D := 0;
  if MPVPlayer.GetPropertyDouble('avsync', D, False) = 0 then
    S := FormatFloat('+0.000;-0.000;+0.000', D, InvFmt)
  else
    S := '-';
  R[7] := 'A/V ' + S + '   drop ' + P('frame-drop-count', '0') + ' / ' + P('decoder-frame-drop-count', '0');

  N := Round(Num('volume'));
  B := False;
  MPVPlayer.GetPropertyBool('mute', B, False);
  R[8] := IntToStr(N) + '%';
  if B then R[8] := R[8] + '   (muted)';

  for I := 0 to High(R) do
    if R[I] <> FInfoText[I] then
    begin
      FInfoText[I] := R[I];
      FElInfo[I].Text := R[I];
    end;
end;

// 컨트롤 표시 + 자동 숨김 재시작
procedure TFrmKPlayer.ShowControls;
begin
  if FUi = nil then Exit;
  if FCtlHidden then
  begin
    FCtlHidden := False;
    FUi.ClassSet('hidden', False);
    UpdateCursor;
    RefreshUI;
  end;
  FHideTimer.Enabled := False;
  FHideTimer.Enabled := True;
end;

// 시작 화면(idle)·드래그 중엔 숨기지 않는다 — 끝나면 ShowControls 가 다시 건다
procedure TFrmKPlayer.HideTimerTick(Sender: TObject);
begin
  FHideTimer.Enabled := False;
  if (FDrag <> 0) or FUi.ClassContains('idle') then Exit;
  FCtlHidden := True;
  FUi.ClassSet('hidden', True);
  UpdateCursor;
end;

// 전체 화면에서 컨트롤과 함께 커서 숨김
procedure TFrmKPlayer.UpdateCursor;
begin
  FUi.ClassSet('nocursor', FCtlHidden and (WindowState = wsMaximized));
end;

procedure TFrmKPlayer.UiTimerTick(Sender: TObject);
begin
  if FDrag = 1 then Exit;   // 끄는 중 — 진행바·시간은 DragPaint, 동기 조회로 탐색 중인 코어를 기다리지 않게
  RefreshUI;
end;

// mpv 상태 → DOM. 바뀐 값만 쓴다. 숨김 중엔 시작 화면·파일 바뀜만 본다 (안 보이는 시간·진행바는 안 건드림).
procedure TFrmKPlayer.RefreshUI;
var
  B, Idle: Boolean;
  S: string;
  Dur, Pos, V, Fps: Double;
  N: Integer;
begin
  if (MPVPlayer = nil) or (FUi = nil) then Exit;

  Idle := False;
  MPVPlayer.GetPropertyBool('idle-active', Idle, False);
  FUi.ClassSet('idle', Idle);
  if Idle and FCtlHidden then ShowControls;
  CheckOsd(Idle);   // 컨트롤 숨김과 무관하게 본다

  S := '';
  MPVPlayer.GetPropertyString('path', S, False);
  if S <> FLastPath then
  begin
    FLastPath := S;
    S := '';
    MPVPlayer.GetPropertyString('filename/no-ext', S, False);
    if S <> FLastTitle then
    begin
      FLastTitle := S;
      FElTitle.Text := S;
      BuildDiscTitle(S);
    end;
    FLastDur := -1;   // 챕터 다시
    FUi.ClassSet('haspv', False);   // 옛 파일 미리보기 안 보이게 — 새 프레임이 오면 다시
    // 미리보기 mpv 가 옛 파일을 쥐고 있으면 그 디코더 메모리가 남는다 (4K AV1 → 1080p 전환 뒤 +340MB 실측) → 닫음, 다음 호버 때 새로 연다
    if FThumb <> nil then FThumb.Request('', 0);
    if FLastPath <> '' then ShowControls;   // 새 파일 = 컨트롤 잠깐 표시 (Lua file-loaded)
  end;

  UpdateTaskbar(Idle);   // 컨트롤 숨김 중에도
  CheckAudioOnly(Idle);

  if FCtlHidden then Exit;

  B := False;
  MPVPlayer.GetPropertyBool('pause', B, False);
  FUi.ClassSet('playing', not Idle and not B);
  B := False;
  MPVPlayer.GetPropertyBool('mute', B, False);
  FUi.ClassSet('muted', B);

  S := '';
  MPVPlayer.GetPropertyString('sid', S, False);
  FUi.ClassSet('hassub', StrToIntDef(S, 0) > 0);   // 트랙 번호일 때만 — 'no', 파일 없을 땐 'auto'
  B := False;
  MPVPlayer.GetPropertyBool('sub-visibility', B, False);
  FUi.ClassSet('subon', B);

  // 음량 막대 (무음이면 0 — Lua 와 같음)
  V := 0;
  MPVPlayer.GetPropertyDouble('volume', V, False);
  if FUi.ClassContains('muted') then V := 0;
  N := EnsureRange(Round(V), 0, 100);
  if N <> FLastVol then
  begin
    FLastVol := N;
    FElVolFill.Attr['style'] := Format('width:%d%%', [N]);
    FElVolThumb.Attr['style'] := Format('left:%d%%', [N]);
  end;

  Dur := 0;
  Pos := 0;
  MPVPlayer.GetPropertyDouble('duration', Dur, False);
  MPVPlayer.GetPropertyDouble('time-pos', Pos, False);
  if FDrag = 1 then Pos := FDragPos;
  FUi.ClassSet('nodur', Dur <= 0);
  if Dur <> FLastDur then
  begin
    FLastDur := Dur;
    RebuildChapters;
  end;

  // 총 길이 표기 = duration − 1프레임 (마지막 프레임 시작 시각). duration 은 마지막 프레임 길이까지 포함 →
  // 02:00 인데 01:59 에서 끝남, 팟플레이어는 01:59 (제보 2026-10-19). 오디오 전용은 fps 없음 → 그대로.
  FShownDur := Dur;
  Fps := 0;
  if (Dur > 0) and (MPVPlayer.GetPropertyDouble('container-fps', Fps, False) = 0) and (Fps > 0) then
    FShownDur := Math.Max(Dur - 1 / Fps, 0);

  S := FormatTime(Pos) + ' / ' + FormatTime(FShownDur);
  if S <> FLastTime then SetTimeDigits(S);

  if Dur > 0 then N := EnsureRange(Round(Pos / Dur * 10000), 0, 10000) else N := 0;
  if N <> FLastPlayed then
  begin
    FLastPlayed := N;
    S := FormatFloat('0.00', N / 100, InvFmt) + '%';
    FElPlayed.Attr['style'] := 'width:' + S;
    FElThumb.Attr['style'] := 'left:' + S;
  end;
end;

// 커버 없는 음악 판정. 커버(내장 audio-display·폴더 cover-art-auto)는 mpv 가 영상 트랙으로 보여 준다 → 영상 트랙 없음 = 커버 없음.
// 오디오 트랙도 있어야 한다 — 파일을 여는 중엔 둘 다 없어서, 동영상을 열 때 LP 가 잠깐 비치지 않는다.
procedure TFrmKPlayer.CheckAudioOnly(AIdle: Boolean);
var
  S: string;
  B: Boolean;
begin
  B := False;
  if not AIdle then
  begin
    S := '';
    B := (MPVPlayer.GetPropertyString('current-tracks/audio/id', S, False) >= 0) and
         (MPVPlayer.GetPropertyString('current-tracks/video/id', S, False) < 0);
  end;
  if B = FAudioOnly then Exit;
  FAudioOnly := B;
  FUi.ClassSet('audio', B);
  FDiscTimer.Enabled := B;
  if B then
  begin
    FDiscAngle := -1;
    DiscTimerTick(nil);
  end;
end;

// 회전각 = 재생 위치 × 60도/초 (10 rpm, 6초에 한 바퀴 — 33⅓ rpm 은 너무 빠르다는 사용자 의견 2026-10-16). 일시정지면 위치가 멈춰 그대로, 탐색하면 그만큼 돈다. 바뀔 때만 쓴다.
procedure TFrmKPlayer.DiscTimerTick(Sender: TObject);
var
  Pos: Double;
  N: Integer;
begin
  if FElDisc = nil then Exit;
  Pos := 0;
  MPVPlayer.GetPropertyDouble('time-pos', Pos, False);
  N := Round(Frac(Pos * 60 / 360) * 3600) mod 3600;
  if N = FDiscAngle then Exit;
  FDiscAngle := N;
  FElDisc.Attr['style'] := 'transform: rotate(' + FormatFloat('0.0', N / 10, InvFmt) + 'deg)';
end;

// LP 라벨 둘레에 제목을 원으로 — 엔진에 textPath 가 없어 글자마다 요소를 두고 중심 기준으로 돌린다 (player.css .ch).
// 간격 = 글자 폭 추정 (한글·한자 1em, 그 밖 0.6em, 공백 0.4em) × 15도 — 1em 이 글자 원 반지름에서 약 15도
// (라벨 6em, 글자 0.6em, 글자 중심 반지름 ≈ 2.34em — 단위는 #lp 의 em). 고정 간격이면 한글은 겹치고 영문은 듬성했다.
// 합이 340도를 넘으면 비율대로 좁힘, 56자 넘으면 '…' 로 자름. 위 가운데가 제목 가운데.
procedure TFrmKPlayer.BuildDiscTitle(const ATitle: string);
const
  MaxChars = 56;
  DegPerEm = 15;
var
  S, C: string;
  N, I, L: Integer;
  W: array of Double;
  Total, K, A: Double;
  E: TKElement;
begin
  if FElDiscRing = nil then Exit;
  while FElDiscRing.FirstChild <> nil do
    FElDiscRing.FirstChild.Remove;
  S := ATitle;
  if UTF8Length(S) > MaxChars then
    S := UTF8Copy(S, 1, MaxChars - 1) + '…';
  N := UTF8Length(S);
  if N = 0 then Exit;
  SetLength(W, N);
  Total := 0;
  for I := 0 to N - 1 do
  begin
    C := UTF8Copy(S, I + 1, 1);
    if C = ' ' then W[I] := 0.4
    else if UTF8CodepointToUnicode(PChar(C), L) >= $1100 then W[I] := 1
    else W[I] := 0.6;
    Total := Total + W[I] * DegPerEm;
  end;
  K := 1;
  if Total > 340 then K := 340 / Total;
  A := -Total * K / 2;
  for I := 0 to N - 1 do
  begin
    E := FView.CreateElement('div');
    E.ClassAdd('ch');
    E.Attr['style'] := 'transform: rotate(' + FormatFloat('0.0', A + W[I] * DegPerEm * K / 2, InvFmt) + 'deg)';
    E.Text := UTF8Copy(S, I + 1, 1);
    FElDiscRing.AppendChild(E);
    A := A + W[I] * DegPerEm * K;
  end;
end;

// 작업 표시줄 진행률. 바뀔 때만, 0.1% 단위로 끊어 (1만 분할이면 100ms 마다 COM 호출).
procedure TFrmKPlayer.UpdateTaskbar(AIdle: Boolean);
var
  Dur, Pos: Double;
  B: Boolean;
  St: TTaskbarProgress;
  N: Integer;
begin
  Dur := 0;
  Pos := 0;
  B := False;
  if not AIdle then
  begin
    MPVPlayer.GetPropertyDouble('duration', Dur, False);
    MPVPlayer.GetPropertyDouble('time-pos', Pos, False);
    MPVPlayer.GetPropertyBool('pause', B, False);
  end;
  N := 0;
  if Dur <= 0 then
    St := tpNone
  else
  begin
    if B then St := tpPaused else St := tpNormal;
    N := EnsureRange(Round(Pos / Dur * 1000), 0, 1000) * 10;
  end;
  if (St = FTbState) and (N = FTbPos) then Exit;
  FTbState := St;
  FTbPos := N;
  SetTaskbarProgress(St, N);
end;

// 시간 칩 = 7세그먼트 칸 (player.css .dg/.dc/.ds). 숫자 칸 = 어두운 전 획 위에 켜진 획 자식(.d0~.d9).
// 모양(자리수·':' 위치)이 같으면 바뀐 숫자의 클래스만 바꾼다 — 1초마다 끝자리 하나.
procedure TFrmKPlayer.SetTimeDigits(const S: string);
var
  I: Integer;
  Shape, Last: string;
  E: TKElement;
begin
  Shape := S;
  for I := 1 to Length(Shape) do
    if Shape[I] in ['0'..'9'] then Shape[I] := '0';
  Last := FLastTime;
  if Shape <> FTimeShape then
  begin
    FTimeShape := Shape;
    while FElTime.FirstChild <> nil do
      FElTime.FirstChild.Remove;
    SetLength(FTimeDigit, Length(S));
    for I := 1 to Length(S) do
    begin
      FTimeDigit[I - 1] := nil;
      if S[I] = ' ' then Continue;   // ' / ' 간격은 .ds 의 margin
      E := FView.CreateElement('div');
      case S[I] of
        ':': E.ClassAdd('dc');
        '/': E.ClassAdd('ds');
      else
        E.ClassAdd('dg');
        FTimeDigit[I - 1] := FView.CreateElement('div');
        E.AppendChild(FTimeDigit[I - 1]);
      end;
      FElTime.AppendChild(E);
    end;
    Last := '';   // 새 칸 — 전부 씀
  end;
  for I := 1 to Length(S) do
    if (FTimeDigit[I - 1] <> nil) and ((I > Length(Last)) or (S[I] <> Last[I])) then
    begin
      if (I <= Length(Last)) and (Last[I] in ['0'..'9']) then
        FTimeDigit[I - 1].ClassSet('d' + Last[I], False);
      FTimeDigit[I - 1].ClassSet('d' + S[I], True);
    end;
  FLastTime := S;
end;

procedure TFrmKPlayer.RebuildChapters;
var
  I: Integer;
  Cnt: Int64;
  T: Double;
  E: TKElement;
begin
  while FElChapters.FirstChild <> nil do
    FElChapters.FirstChild.Remove;
  if FLastDur <= 0 then Exit;
  Cnt := 0;
  MPVPlayer.GetPropertyInt64('chapter-list/count', Cnt, False);
  for I := 0 to Cnt - 1 do
  begin
    T := -1;
    if MPVPlayer.GetPropertyDouble(Format('chapter-list/%d/time', [I]), T, False) < 0 then Continue;
    E := FView.CreateElement('div');
    E.ClassAdd('chap');
    E.Attr['style'] := 'left:' + FormatFloat('0.00', EnsureRange(T / FLastDur * 100, 0, 100), InvFmt) + '%';
    FElChapters.AppendChild(E);
  end;
end;

procedure TFrmKPlayer.ViewMouseMove(Sender: TObject; AEvent: TKEvent);
begin
  if FDrag <> 0 then
  begin
    DragTo(AEvent.MouseX, False);
    Exit;
  end;
  // 1px 임계 — 기준점은 넘었을 때만 옮긴다 (매번 옮기면 천천히 움직일 때 영원히 못 넘음)
  if (Abs(AEvent.MouseX - FMoveX) > 1) or (Abs(AEvent.MouseY - FMoveY) > 1) then
  begin
    FMoveX := AEvent.MouseX;
    FMoveY := AEvent.MouseY;
    ShowControls;
  end;
end;

// 드래그 끝 (엔진이 누를 때 캡처하므로 창 밖에서 떼도 온다) + 포커스를 폼으로
procedure TFrmKPlayer.ViewMouseUp(Sender: TObject; AEvent: TKEvent);
begin
  if FDrag = 1 then
    DragTo(AEvent.MouseX, True);   // 놓은 지점으로 정확히
  if FDrag <> 0 then
  begin
    if (FDrag = 1) and FDragResume then
    begin
      MPVPlayer.SetPropertyBool('pause', False);   // 끌기 전 상태로 (ProgressMouseDown)
      FBzPause := 0;
    end;
    FDrag := 0;
    FSeekPending := False;
    FUi.ClassSet('seeking', False);
    FUi.ClassSet('voldrag', False);
    ShowControls;
  end;
  // 버튼 누름은 창 끌기로 안 가서 엔진 창이 포커스를 쥔 채다 — click 처리 뒤에 폼으로 (ViewMouseDown 주석)
  Application.QueueAsyncCall(RestoreFocus, 0);
end;

procedure TFrmKPlayer.RestoreFocus(Data: PtrInt);
begin
  if Screen.ActiveCustomForm = Self then
    LCLIntf.SetFocus(Handle);
end;

// 버튼 누름은 영상 영역 처리(창 끌기·더블클릭 전체 화면)로 올라가지 않게
procedure TFrmKPlayer.CtlMouseDown(Sender: TObject; AEvent: TKEvent);
begin
  AEvent.StopPropagation;
end;

procedure TFrmKPlayer.CtlClick(Sender: TObject; AEvent: TKEvent);
var
  I: Integer;
  Id: string;
begin
  if AEvent.MouseButton <> 0 then Exit;
  Id := AEvent.CurrentTarget.Id;
  for I := 0 to High(CtlIds) do
    if CtlIds[I] = Id then
    begin
      Application.QueueAsyncCall(CtlAction, I);
      Exit;
    end;
end;

procedure TFrmKPlayer.CtlAction(Data: PtrInt);
var
  Eof: Boolean;
begin
  if MPVPlayer = nil then Exit;
  case Data of
    0: SetTopMost(FConfig.ReadInteger('topmost', 0) = 0);   // 압정
    1: HandleMinimize;
    2: MPVPlayer.Command(['cycle', 'fullscreen']);           // → MpvFullScreen
    3: HandleClose;
    4: FrmList.Prev;
    5:   // 재생: 시작 화면 = 다음 곡, 끝 정지(keep-open) = 처음부터 (pause 만 풀면 곧 다시 끝)
      if FUi.ClassContains('idle') then
        FrmList.Next
      else
      begin
        Eof := IsEOF;
        if Eof then
        begin
          MPVPlayer.Command(['seek', '0', 'absolute+exact']);
          SetPause(False);
        end
        else
          HandlePause;
      end;
    6: FrmList.Next;
    7: MPVPlayer.Command(['cycle', 'mute']);
    8: MPVPlayer.Command(['cycle', 'sub-visibility']);
    9: HandleSettings;
    10: HandlePlayList;
    11:  // 시작 화면 원 로고 — 목록 있으면 첫 항목, 없으면 파일 열기
      if FrmList.ListData.RootNodeCount > 0 then
        FrmList.Next
      else
        FrmList.OpenFiles;
  end;
  if Data >= 4 then ShowControls;   // 하단 조작은 자동 숨김 재시작
  RefreshUI;
end;

// 진행바: 누른 순간 그 위치로, 뗄 때까지 끌기
procedure TFrmKPlayer.SendDragSeek;
begin
  FSeekBusy := True;
  FSeekPending := False;
  FSeekGuard.Enabled := False;
  FSeekGuard.Enabled := True;
  MPVPlayer.Command(['seek', FormatFloat('0.000', FDragPos, InvFmt), 'absolute+keyframes'], SeekReplyId);
end;

// 탐색 끝 (MPVPlayer.OnRestart, 재생 시작 때도 온다) — 끄는 중 밀린 위치가 있으면 그것 하나만
procedure TFrmKPlayer.MpvRestart(Sender: TObject);
begin
  FSeekBusy := False;
  FSeekGuard.Enabled := False;
  if FSeekPending and (FDrag = 1) then SendDragSeek;
  FSeekPending := False;
end;

procedure TFrmKPlayer.SeekGuardTick(Sender: TObject);
begin
  MpvRestart(nil);
end;

// 끄는 중 진행바·시간 = 손끝 위치 (FDragPos, 길이는 RefreshUI 가 둔 FLastDur)
procedure TFrmKPlayer.DragPaint;
var
  S: string;
begin
  if FLastDur <= 0 then Exit;
  S := FormatFloat('0.00', EnsureRange(FDragPos / FLastDur * 100, 0, 100), InvFmt) + '%';
  FElPlayed.Attr['style'] := 'width:' + S;
  FElThumb.Attr['style'] := 'left:' + S;
  FLastPlayed := -1;   // 끝나면 RefreshUI 가 다시 씀
  S := FormatTime(Math.Min(FDragPos, FShownDur)) + ' / ' + FormatTime(FShownDur);
  if S <> FLastTime then SetTimeDigits(S);
end;

procedure TFrmKPlayer.ProgressMouseDown(Sender: TObject; AEvent: TKEvent);
begin
  AEvent.StopPropagation;
  if (AEvent.MouseButton <> 0) or FUi.ClassContains('nodur') then Exit;
  FDrag := 1;
  // 끄는 동안 일시정지 — 재생 중이면 탐색 사이사이 영상이 앞으로 갔다가 다음 탐색에 되돌아가며 떨렸다 (2026-10-08 문의).
  // 베젤은 안 띄움 (FBzPause 를 새 값으로 맞춰 CheckOsd 가 변화로 안 봄)
  FDragResume := IsPlay;
  if FDragResume then
  begin
    MPVPlayer.SetPropertyBool('pause', True);
    FBzPause := 1;
  end;
  FUi.ClassSet('seeking', True);
  DragTo(AEvent.MouseX, False);
end;

// 진행바 위 시간 말풍선 — 커서 시간, 진행바 안으로 당김
procedure TFrmKPlayer.ProgressMouseMove(Sender: TObject; AEvent: TKEvent);
begin
  UpdateHover(AEvent.MouseX);
end;

// 미리보기: 켜져 있고 영상 있는 로컬 파일만 (스트림은 두 번째 연결이 대역폭을 먹는다)
function TFrmKPlayer.PreviewUsable: Boolean;
begin
  Result := (FThumb <> nil) and (MPVPlayer.VideoWidth > 0) and (FLastPath <> '') and (Pos('://', FLastPath) = 0);
end;

// 말풍선·미리보기를 커서(뷰 좌표 AX) 시각으로 — 진행바 위에 올렸을 때와 끄는 중 둘 다. 상자는 진행바 안으로 당김
procedure TFrmKPlayer.UpdateHover(AX: Single);
var
  R, T: TKRect;
  Dur, X: Double;
begin
  Dur := FLastDur;   // RefreshUI 가 둔 값 — 끄는 중 동기 조회는 탐색 중인 코어를 기다린다
  if Dur <= 0 then Exit;
  R := FElProgress.BoundingRect;
  if R.W <= 0 then Exit;
  X := EnsureRange(AX - R.X, 0, R.W);
  FElTip.Text := FormatTime(Math.Min(X / R.W * Dur, FShownDur));   // 끝 = 총 길이 표기와 같게
  if PreviewUsable then   // 끄는 중에도 (사용자 요청 2026-10-08 — 본 영상은 키프레임만 띄엄띄엄 따라온다)
  begin
    FThumb.Request(FLastPath, X / R.W * Dur);
    FElPreview.Attr['style'] := 'left:' + FormatFloat('0.0', EnsureRange(X, 81, Math.Max(81, R.W - 81)), InvFmt) +
                                'px;height:' + IntToStr(FPvH) + 'px';   // 81 = 폭 160/2 + 테두리 1
  end;
  T := FElTip.BoundingRect;
  X := EnsureRange(X, T.W / 2, Math.Max(T.W / 2, R.W - T.W / 2));
  FElTip.Attr['style'] := 'left:' + FormatFloat('0.0', X, InvFmt) + 'px';
end;

// 환경설정 '진행바 미리보기' — 켜면 미리보기 스레드(두 번째 mpv)를 만들고, 끄면 없앤다
procedure TFrmKPlayer.SetSeekPreview(AOn: Boolean);
begin
  if AOn = (FThumb <> nil) then Exit;
  if AOn then
    FThumb := TThumbnailer.Create(ThumbReady)
  else
  begin
    FreeAndNil(FThumb);
    if FUi <> nil then FUi.ClassSet('haspv', False);
  end;
end;

// 미리보기 프레임 도착 (Thumb 스레드 → Queue). 이미지 이름을 번갈아 등록하고 상자 높이를 영상 비율로
procedure TFrmKPlayer.ThumbReady(const ABytes: TBytes; AW, AH: Integer);
var
  Name: string;
begin
  if (FThumb = nil) or (FUi = nil) or (AW <= 0) then Exit;
  FPvAlt := not FPvAlt;
  if FPvAlt then Name := 'pv-a.bmp' else Name := 'pv-b.bmp';
  FView.SetImage(Name, ABytes);
  FElPreviewImg.Attr['src'] := Name;
  FPvH := Round(160 * AH / AW);
  FUi.ClassSet('haspv', True);
end;

// 음량 슬라이더도 누른 채 끈다
procedure TFrmKPlayer.VolMouseDown(Sender: TObject; AEvent: TKEvent);
begin
  AEvent.StopPropagation;
  if AEvent.MouseButton <> 0 then Exit;
  FDrag := 2;
  FUi.ClassSet('voldrag', True);
  DragTo(AEvent.MouseX, False);
end;

// 진행바 끌기: 키프레임 탐색을 한 번에 하나만 (SendDragSeek). 끝나면(MpvRestart) 그동안 움직인 마지막 위치 하나만 다시.
// 움직일 때마다 보내면 탐색이 쌓여 지나간 위치를 전부 밟으며 버벅였다 (2026-10-08 문의 — 동기 mpv_command 는 UI 까지 잡았고,
// 비동기로 바꿔도 쌓임은 그대로). 놓을 때 1회 exact. 끄는 동안 진행바·시간은 손끝 위치로 직접 (DragPaint — mpv 에 묻는
// 동기 호출은 탐색 중인 코어를 기다린다).
procedure TFrmKPlayer.DragTo(AX: Single; AExact: Boolean);
var
  R: TKRect;
  Ratio, Dur: Double;
  V: Integer;
  Mute: Boolean;
begin
  if FDrag = 1 then
  begin
    R := FElProgress.BoundingRect;
    Dur := 0;
    MPVPlayer.GetPropertyDouble('duration', Dur, False);
    if (R.W <= 0) or (Dur <= 0) then Exit;
    Ratio := EnsureRange((AX - R.X) / R.W, 0, 1);
    FDragPos := Ratio * Dur;
    if AExact then
    begin
      FSeekPending := False;
      MPVPlayer.Command(['seek', FormatFloat('0.000', FDragPos, InvFmt), 'absolute+exact'], SeekReplyId);
    end
    else
    begin
      if FSeekBusy then FSeekPending := True else SendDragSeek;
      UpdateHover(AX);
      DragPaint;
      Exit;
    end;
  end
  else if FDrag = 2 then
  begin
    R := FElVolSlider.BoundingRect;
    if R.W <= 0 then Exit;
    V := Round(EnsureRange((AX - R.X) / R.W, 0, 1) * 100);
    MPVPlayer.SetPropertyDouble('volume', V);
    Mute := False;
    if (V > 0) and (MPVPlayer.GetPropertyBool('mute', Mute, False) >= 0) and Mute then
      MPVPlayer.SetPropertyBool('mute', False);   // 음량 올리면 음소거 해제
  end;
  RefreshUI;
end;

end.
