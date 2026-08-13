unit Assoc;

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.ShlObj, Winapi.ShellAPI,
  Winapi.ShLwApi, Winapi.Dwmapi, System.SysUtils, System.Classes,
  System.Generics.Collections, System.Win.Registry, Vcl.Forms, K.Translate;

type
  // 연결 카드의 확장자 분류
  TAssocGroup = (agVideo, agAudio, agList);

  TAssocExt = record
    Ext:   string;        // '.mp4'
    Desc:  string;        // 탐색기 표시 파일 종류명 (ProgID 기본값)
    Group: TAssocGroup;
    Main:  Boolean;       // [주요 파일] 버튼 선택 대상
  end;

const
  AssocGroupNames: array[TAssocGroup] of string = ('비디오', '오디오', '재생목록');

  // 재생 가능 확장자의 단일 출처 — 연결 카드 + List.AddFile 필터(IsMediaFile) 공용.
  AssocExts: array[0..37] of TAssocExt = (
    (Ext: '.mp4';  Desc: 'MP4 비디오';         Group: agVideo; Main: True),
    (Ext: '.mkv';  Desc: 'Matroska 비디오';    Group: agVideo; Main: True),
    (Ext: '.avi';  Desc: 'AVI 비디오';         Group: agVideo; Main: True),
    (Ext: '.mov';  Desc: 'QuickTime 비디오';   Group: agVideo; Main: True),
    (Ext: '.wmv';  Desc: 'Windows Media 비디오'; Group: agVideo; Main: True),
    (Ext: '.flv';  Desc: 'Flash 비디오';       Group: agVideo; Main: False),
    (Ext: '.webm'; Desc: 'WebM 비디오';        Group: agVideo; Main: True),
    (Ext: '.m4v';  Desc: 'MPEG-4 비디오';      Group: agVideo; Main: False),
    (Ext: '.mpg';  Desc: 'MPEG 비디오';        Group: agVideo; Main: False),
    (Ext: '.mpeg'; Desc: 'MPEG 비디오';        Group: agVideo; Main: False),
    (Ext: '.m2v';  Desc: 'MPEG-2 비디오';      Group: agVideo; Main: False),
    (Ext: '.ts';   Desc: 'MPEG 전송 스트림';   Group: agVideo; Main: True),
    (Ext: '.tp';   Desc: 'MPEG 전송 스트림';   Group: agVideo; Main: False),
    (Ext: '.trp';  Desc: 'MPEG 전송 스트림';   Group: agVideo; Main: False),
    (Ext: '.m2ts'; Desc: 'Blu-ray 비디오';     Group: agVideo; Main: False),
    (Ext: '.mts';  Desc: 'AVCHD 비디오';       Group: agVideo; Main: False),
    (Ext: '.vob';  Desc: 'DVD 비디오';         Group: agVideo; Main: False),
    (Ext: '.asf';  Desc: 'ASF 비디오';         Group: agVideo; Main: False),
    (Ext: '.rm';   Desc: 'RealMedia 비디오';   Group: agVideo; Main: False),
    (Ext: '.rmvb'; Desc: 'RealMedia 비디오';   Group: agVideo; Main: False),
    (Ext: '.ogv';  Desc: 'Ogg 비디오';         Group: agVideo; Main: False),
    (Ext: '.3gp';  Desc: '3GPP 비디오';        Group: agVideo; Main: False),
    (Ext: '.divx'; Desc: 'DivX 비디오';        Group: agVideo; Main: False),
    (Ext: '.mp3';  Desc: 'MP3 오디오';         Group: agAudio; Main: True),
    (Ext: '.flac'; Desc: 'FLAC 오디오';        Group: agAudio; Main: True),
    (Ext: '.aac';  Desc: 'AAC 오디오';         Group: agAudio; Main: False),
    (Ext: '.m4a';  Desc: 'MPEG-4 오디오';      Group: agAudio; Main: True),
    (Ext: '.wav';  Desc: 'WAV 오디오';         Group: agAudio; Main: True),
    (Ext: '.ogg';  Desc: 'Ogg 오디오';         Group: agAudio; Main: False),
    (Ext: '.opus'; Desc: 'Opus 오디오';        Group: agAudio; Main: False),
    (Ext: '.wma';  Desc: 'Windows Media 오디오'; Group: agAudio; Main: False),
    (Ext: '.ape';  Desc: 'Monkey''s Audio';    Group: agAudio; Main: False),
    (Ext: '.aiff'; Desc: 'AIFF 오디오';        Group: agAudio; Main: False),
    (Ext: '.mka';  Desc: 'Matroska 오디오';    Group: agAudio; Main: False),
    (Ext: '.dsf';  Desc: 'DSD 오디오';         Group: agAudio; Main: False),
    (Ext: '.m3u';  Desc: '재생목록';           Group: agList;  Main: False),
    (Ext: '.m3u8'; Desc: '재생목록';           Group: agList;  Main: False),
    (Ext: '.pls';  Desc: '재생목록';           Group: agList;  Main: False));

const
  // 콤보 인덱스 → mpv 값. INI 가 인덱스 저장 — 순서 바꾸면 기존 값 의미 변경, 추가는 뒤에만.
  HwdecValues:     array[0..2] of string = ('auto-safe', 'auto', 'no');
  VoValues:        array[0..1] of string = ('gpu', 'gpu-next');
  GpuApiValues:    array[0..3] of string = ('auto', 'd3d11', 'opengl', 'vulkan');
  ScaleValues:     array[0..3] of string = ('lanczos', 'bilinear', 'spline36', 'ewa_lanczos');
  DeintValues:     array[0..2] of string = ('auto', 'yes', 'no');
  VideoSyncValues: array[0..1] of string = ('display-resample', 'audio');
  ShotFmtValues:   array[0..1] of string = ('jpg', 'png');

  // 음량 평준화 프리셋 (dynaudnorm) — 0:낮게 1:보통 2:강하게
  NormFilters: array[0..2] of string = (
    'lavfi=[dynaudnorm=f=100:g=15:p=0.90:r=0.10:n=1]',
    'lavfi=[dynaudnorm=f=75:g=7:p=0.95:r=0.20:n=1]',
    'lavfi=[dynaudnorm=f=50:g=5:p=0.99:r=0.30:n=1]');

// 재생 가능 파일 판정. List.AddFile 필터도 이 함수 — 두 벌로 갈리면
// "연결했는데 더블클릭이 목록에 안 들어감" (실제 발생).
function IsMediaFile(const AFileName: string): Boolean;

// 재생목록 파일 (.m3u/.m3u8/.pls) — 목록 추가 시 항목으로 펼쳐야 함.
function IsPlaylistFile(const AFileName: string): Boolean;

// 등록된 연결을 현재 exe 경로로 재기록 (시작 시 1회) — 포터블, 폴더 이동 시 실행 명령 어긋남.
procedure SyncFileAssoc;

type
  // 확장자 현재 상태 (AssocStateOf 가 채움).
  //   Registered - 우리 ProgID 등록됨 (= 트리 체크 상태)
  //   Ours       - 지금 KPlayer 로 열림
  //   Other      - 남이면 그 프로그램 이름 (연결 없으면 '')
  //   Hard       - UserChoice/사용 이력으로 고정 — 등록만으론 못 가져옴, [기본 앱 선택] 필요
  //   Broken     - 기본 앱=우리인데 ProgID 없음 → 더블클릭이 '앱 선택' 으로 끝남, 재등록으로 복구
  TAssocState = record
    Registered: Boolean;
    Ours: Boolean;
    Other: string;
    Hard: Boolean;
    Broken: Boolean;
  end;

  // [기본 앱 선택] 창의 뒷정리 대상 (ShowDefaultAppPicker 참고).
  //   Sheet    - 투명화해 둔 파일 속성 창
  //   TempFile - 속성 창용 빈 임시 파일
  TPickerJob = record
    Sheet: HWND;
    TempFile: string;
  end;


// 상태
function ExtProgID(const AExt: string): string;
function AssocIndexOf(const AExt: string): Integer;
function AssocStateOf(const AExt: string): TAssocState;
function AssocOwned(const AExt: string): Boolean;
function AssocOwnedList: TArray<string>;

// 사용자 직접 조작 필요 상태 = UI [적용안됨] 뱃지 조건. 등록(체크)한 확장자만 알림.
function AssocNeedsUser(const AState: TAssocState): Boolean;

// 판정 근거 텍스트 — 레지스트리 값과 실제 동작이 어긋날 때 갈라진 지점 확인용 (툴팁).
function AssocResolveInfo(const AExt: string): string;

// 실행 환경 한 줄 (계정/승격/HKCU 하이브). 우리 HKCU ≠ 탐색기 하이브면 값은 맞는데 동작이 다름.
function AssocEnvInfo: string;

// 등록
procedure AssocRegister(const AIndex: Integer);
procedure AssocUnregister(const AIndex: Integer);
procedure EnsureAppRegistered;

// 등록한 연결 전부 복원 (제거 프로그램이 /uninst 로 호출).
procedure AssocUnregisterAll;

// 기본 앱 선택
function ShowDefaultAppPicker(const AExt: string; var AJob: TPickerJob;
  const AAnchor: TPoint): Boolean;
procedure ClosePickerJob(var AJob: TPickerJob);
procedure ShowDefaultApps(AHandle: HWND; AOurPage: Boolean);

// 감시. FileExts 변경 시 AOnChange 를 메인 스레드로. 알림 몰림 — 수신측
// 디바운스 필요. 평시 이벤트 대기.
function AssocWatch(const AOnChange: TProc): TThread;
procedure AssocUnwatch(var AThread: TThread);

// 로그. 환경설정 창이 자기 메모를 걺 (미설정 시 no-op).
var
  AssocLogProc: TProc<string> = nil;

procedure AssocLog(const AMsg: string);

implementation

procedure AssocLog(const AMsg: string);
begin
  // 창 없을 때도 불림
  if Assigned(AssocLogProc) then
    AssocLogProc(AMsg);
end;

// 파일 속성 창 '연결 프로그램 - 변경' 명령 ID (비문서화) — 확장자별
// [기본 앱 선택] 창을 띄움 (ShowDefaultAppPicker 참고).
const
  IDM_CHANGE_ASSOC = $3363;

// 'ProgID|exe' → 표시용 프로그램 이름 (FriendlyProgramName 이 채움).
// 첫 사용 시 생성, finalization 에서 해제.
var
  FriendlyCache: TDictionary<string, string> = nil;

// 레지스트리 계층 (모두 HKCU — UAC 승격 불요)
//
//   Software\Classes\KPlayer.mp4                ProgID (설명/아이콘/실행 명령)
//   Software\Classes\.mp4                       (기본값) = 우리 ProgID
//   Software\Classes\.mp4\OpenWithProgIDs       '연결 프로그램' 후보로 노출
//   Software\Classes\Applications\KPlayer.exe   FriendlyAppName / SupportedTypes
//   Software\KPlayer\Capabilities               설정 앱의 '기본 앱' 목록용
//   Software\RegisteredApplications             위 Capabilities 등록
//   Software\KPlayer\FileAssoc                  등록 전 값 백업 + 소유 목록
//
// 여기서는 후보 등록까지만. 기본 앱(FileExts\...\UserChoice)은 안 씀 — 해시
// 보호, 계산해 써도 Win11 26200 거부 (2026-07-27). 지정은 사용자가
// [기본 앱 선택] 창에서 직접.

const
  // 백업 겸 소유 목록. 값 이름=확장자, 데이터=등록 전 ProgID.
  // 빈 데이터 = HKCU 원래 값 없음 → 해제 시 값 삭제 (빈 기본값 남기면 HKLM 연결 가려짐).
  AssocBackupKey = '\Software\KPlayer\FileAssoc';
  AssocCapKey    = '\Software\KPlayer\Capabilities';
  AssocClassKey  = '\Software\Classes\';

  // 확장자별 아이콘 폴더 (exe 옆). 파일명 = 점 뺀 확장자 + '.ico'.
  AssocIconDir   = 'Icon\';

function ExtProgID(const AExt: string): string;
begin
  Result := 'KPlayer' + AExt;   // '.mp4' -> 'KPlayer.mp4'
end;

// DefaultIcon 문자열 — Icon 폴더의 확장자별 .ico, 없으면 exe 첫 아이콘.
// exe 리소스 금지: 별도 .rc 의 RT_ICON ID 가 Delphi .res 의 MAINICON 하위
// RT_ICON 과 겹침 (둘 다 1부터) → 링크 깨짐. 회피하려면 앱 아이콘·버전까지
// 직접 쓴 .rc 로 몰아야 하고, 어차피 libmpv-2.dll·KPlayer.lua 동봉 배포라
// 단일 파일 불가.
// 경로 캐시 안 함 (의도) — 포터블이라 폴더가 바뀜, SyncFileAssoc 의
// AssocRegister 재호출이 이 값을 새로 만듦.
function ExtIconRef(const AExt: string): string;
var
  LExe, LIco: string;
begin
  LExe := ParamStr(0);
  LIco := ExtractFilePath(LExe) + AssocIconDir + Copy(AExt, 2, MaxInt) + '.ico';

  if FileExists(LIco) then
    Result := '"' + LIco + '",0'
  else
    Result := '"' + LExe + '",0';
end;

// 레지스트리 문자열 (없으면 ''). 값 이름 '' = 기본값.
function RegStr(ARoot: HKEY; const AKey, AValue: string): string;
var
  LKey: HKEY;
  LBuf: array[0..511] of Char;
  LSize, LType: DWORD;
begin
  Result := '';

  if RegOpenKeyEx(ARoot, PChar(AKey), 0, KEY_READ, LKey) <> ERROR_SUCCESS then
    Exit;
  try
    LSize := SizeOf(LBuf);
    if (RegQueryValueEx(LKey, PChar(AValue), nil, @LType, PByte(@LBuf),
          @LSize) = ERROR_SUCCESS) and (LType = REG_SZ) then
      Result := LBuf;
  finally
    RegCloseKey(LKey);
  end;
end;

function RegHasKey(ARoot: HKEY; const AKey: string): Boolean;
var
  LKey: HKEY;
begin
  Result := RegOpenKeyEx(ARoot, PChar(AKey), 0, KEY_READ, LKey) = ERROR_SUCCESS;
  if Result then
    RegCloseKey(LKey);
end;

// 확장자의 클래스 ProgID: HKCU 먼저, 없으면 HKCR (HKLM+HKCU 병합 뷰).
function ClassProgID(const AExt: string): string;
begin
  Result := RegStr(HKEY_CURRENT_USER, 'Software\Classes\' + AExt, '');
  if Result = '' then
    Result := RegStr(HKEY_CLASSES_ROOT, AExt, '');
end;

// 확장자의 기본 앱 ProgID (미지정 시 '').
// Win11 26xxx 는 UserChoice 아닌 UserChoiceLatest. 구조도 다름 — ProgId 가
// 값이 아니라 하위 키, 그 안에 동명 값:
//   FileExts\.mp4\UserChoiceLatest\ProgId   ProgId = KingPlayer.mp4
// 옛 키만 읽으면 "지정 없음" 오판 ("레지스트리는 우리 것인데 탐색기는 남을
// 띄움" 모순의 원인). 새 키 → 옛 키 순.
function UserChoiceProgID(const AExt: string): string;
const
  Base = 'Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\';
begin
  Result := RegStr(HKEY_CURRENT_USER, Base + AExt + '\UserChoiceLatest\ProgId',
    'ProgId');

  if Result = '' then
    Result := RegStr(HKEY_CURRENT_USER, Base + AExt + '\UserChoiceLatest', 'ProgId');

  if Result = '' then
    Result := RegStr(HKEY_CURRENT_USER, Base + AExt + '\UserChoice', 'ProgId');
end;

// 마지막으로 이 확장자를 연 exe 이름 (없으면 ''). UserChoice 없어도 이 이력이
// 클래스 연결을 이김 — 필수 확인. MRUList 첫 글자가 가리키는 값 = 현재 승자.
function OpenWithMruExe(const AExt: string): string;
const
  Base = 'Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\';
var
  LKey, LMru: string;
begin
  Result := '';

  LKey := Base + AExt + '\OpenWithList';
  LMru := RegStr(HKEY_CURRENT_USER, LKey, 'MRUList');
  if LMru = '' then
    Exit;

  Result := RegStr(HKEY_CURRENT_USER, LKey, LMru[1]);

  // 셸의 '다른 앱 선택'({CLSID}\OpenWith.exe)은 프로그램 아님.
  if SameText(ExtractFileName(Result), 'OpenWith.exe') then
    Result := '';
end;

// 실행 명령 → exe 경로 ('"C:\...\x.exe" "%1"' → 'C:\...\x.exe').
function CommandExe(const ACmd: string): string;
var
  LPos: Integer;
begin
  Result := Trim(ACmd);
  if Result = '' then
    Exit;

  if Result[1] = '"' then
  begin
    Delete(Result, 1, 1);
    LPos := Pos('"', Result);
  end
  else
    LPos := Pos(' ', Result);

  if LPos > 0 then
    Result := Copy(Result, 1, LPos - 1);
end;

// exe 버전 리소스에서 프로그램 이름 (ProductName → FileDescription).
// 셸 미경유 — AssocQueryString 캐시 문제 무관.
function ExeProductName(const AExeFile: string): string;
const
  Names: array[0..1] of string = ('ProductName', 'FileDescription');
var
  LSize, LHandle: DWORD;
  LLen: UINT;
  LBuf: TBytes;
  LPtr: Pointer;
  LLangs: array[0..2] of string;
  I, J: Integer;
begin
  Result := '';

  if (AExeFile = '') or not FileExists(AExeFile) then
    Exit;

  LSize := GetFileVersionInfoSize(PChar(AExeFile), LHandle);
  if LSize = 0 then
    Exit;

  SetLength(LBuf, LSize);
  if not GetFileVersionInfo(PChar(AExeFile), LHandle, LSize, Pointer(LBuf)) then
    Exit;

  // 언어/코드페이지: 파일 제공값 먼저, 없으면 흔한 값 시도.
  LLangs[0] := '';
  if VerQueryValue(Pointer(LBuf), '\VarFileInfo\Translation', LPtr, LLen) and
     (LLen >= 4) then
    LLangs[0] := Format('%.4x%.4x',
      [PWord(LPtr)^, PWord(PByte(LPtr) + 2)^]);

  LLangs[1] := '040904b0';   // 영어(미국) / Unicode
  LLangs[2] := '041204b0';   // 한국어 / Unicode

  for I := Low(LLangs) to High(LLangs) do
  begin
    if LLangs[I] = '' then
      Continue;

    for J := Low(Names) to High(Names) do
      if VerQueryValue(Pointer(LBuf),
           PChar('\StringFileInfo\' + LLangs[I] + '\' + Names[J]),
           LPtr, LLen) and (LLen > 0) then
      begin
        Result := Trim(PChar(LPtr));
        if Result <> '' then
          Exit;
      end;
  end;
end;

// 표시용 프로그램 이름 (캐시 없는 판 — 호출은 FriendlyProgramName 으로).
// ProgID 기본값은 파일 형식 이름이라 부적합 ('7-Zip.zip' → 'zip Archive').
// 실행 명령의 exe 버전 리소스에서 읽고, 실패 시 exe 이름/ProgID 그대로.
function FriendlyProgramNameRaw(const AProgID, AExe: string): string;
var
  LExe: string;
begin
  if AProgID <> '' then
    LExe := CommandExe(RegStr(HKEY_CLASSES_ROOT,
      AProgID + '\shell\open\command', ''))
  else
  begin
    LExe := CommandExe(RegStr(HKEY_CLASSES_ROOT,
      'Applications\' + AExe + '\shell\open\command', ''));

    // App Paths 에만 있는 프로그램 존재 (7-Zip).
    if LExe = '' then
      LExe := CommandExe(RegStr(HKEY_LOCAL_MACHINE,
        'Software\Microsoft\Windows\CurrentVersion\App Paths\' + AExe, ''));
  end;

  Result := ExeProductName(LExe);
  if Result <> '' then
    Exit;

  if AExe <> '' then
    Result := ChangeFileExt(AExe, '')
  else
    Result := AProgID;
end;

// 위의 캐시판. AssocStateOf 가 창 열 때 38회 + 체크·감시 때마다 재실행되는데
// 프로그램 이름은 실행 중 불변 (실패 결과도 캐시).
function FriendlyProgramName(const AProgID, AExe: string): string;
var
  LKey: string;
begin
  LKey := AProgID + '|' + AExe;

  if FriendlyCache = nil then
    FriendlyCache := TDictionary<string, string>.Create;

  if FriendlyCache.TryGetValue(LKey, Result) then
    Exit;

  Result := FriendlyProgramNameRaw(AProgID, AExe);
  FriendlyCache.Add(LKey, Result);
end;

// 우리가 등록한 확장자인가 (= 백업 목록 존재). 백업 없이 등록한 구버전 대비
// ProgID 키 존재도 확인.
function AssocOwned(const AExt: string): Boolean;
var
  LKey: HKEY;
begin
  Result := False;

  if RegOpenKeyEx(HKEY_CURRENT_USER, PChar('Software\KPlayer\FileAssoc'), 0,
       KEY_READ, LKey) = ERROR_SUCCESS then
  try
    Result := RegQueryValueEx(LKey, PChar(AExt), nil, nil, nil, nil) = ERROR_SUCCESS;
  finally
    RegCloseKey(LKey);
  end;

  if not Result then
    Result := RegHasKey(HKEY_CURRENT_USER,
      'Software\Classes\' + ExtProgID(AExt) + '\shell\open\command');
end;

// 확장자 현재 상태. 레지스트리만 봄 — AssocQueryString 은 프로세스 내 캐시로
// 방금 바뀐 값을 못 돌려줌.
// 우선순위: UserChoice(Latest) > OpenWithList MRU(사용 이력) > HKCU\Classes > HKLM\Classes
// HKLM 에 남이 있어도 '남의 것' 아님 — HKLM 클래스는 우리 HKCU 등록을 못 이김.
// 지는 건 UserChoice/사용 이력뿐 (HKLM 근거로 판정하면 우리로 열리는 확장자에 경고 뜸).
function AssocStateOf(const AExt: string): TAssocState;
var
  LPID, LChoice, LExe: string;
begin
  LPID := ExtProgID(AExt);

  Result := Default(TAssocState);
  Result.Registered := AssocOwned(AExt);

  LChoice := UserChoiceProgID(AExt);
  if LChoice <> '' then
  begin
    // 기본 앱 명시 지정 상태 — 등록만으론 못 가져옴
    Result.Ours := SameText(LChoice, LPID);
    Result.Hard := not Result.Ours;

    if Result.Ours then
      // 우리 지정인데 ProgID 없음 = 아무것도 안 열림 (해제 시 이 키도
      // 정리하지만 삭제 거부 PC·구버전 잔재가 있음).
      Result.Broken := not RegHasKey(HKEY_CURRENT_USER,
        'Software\Classes\' + LPID + '\shell\open\command')
    else
      Result.Other := FriendlyProgramName(LChoice, '');

    Exit;
  end;

  // 사용 이력 — 비교는 exe 파일명 (ProgID 아님).
  LExe := OpenWithMruExe(AExt);
  if LExe <> '' then
  begin
    Result.Ours := SameText(ExtractFileName(LExe),
      ExtractFileName(ParamStr(0)));

    if not Result.Ours then
    begin
      Result.Hard := True;   // 이력은 등록으로 못 이김 — 선택 창 필요
      Result.Other := FriendlyProgramName('', ExtractFileName(LExe));
      Exit;
    end;
  end;

  LChoice := ClassProgID(AExt);
  Result.Ours := SameText(LChoice, LPID);
  if not Result.Ours and (LChoice <> '') then
    Result.Other := FriendlyProgramName(LChoice, '');
end;

function AssocNeedsUser(const AState: TAssocState): Boolean;
begin
  // 미등록 확장자는 남이 쥐어도 안 알림 (사용자가 원한 적 없음).
  // Broken 만 등록 무관 알림 — 아무것도 안 열리는 상태라서.
  Result := AState.Broken or (AState.Registered and (AState.Other <> ''));
end;

// 판정 근거 원본 표시 — 어느 값에서 갈라지는지 확인용.
function AssocResolveInfo(const AExt: string): string;
var
  LPID, LEffective, LCmd: string;
begin
  LPID := ExtProgID(AExt);

  Result := 'UserChoiceLatest: ' + RegStr(HKEY_CURRENT_USER,
      'Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\' + AExt +
      '\UserChoiceLatest\ProgId', 'ProgId') + sLineBreak +
    'UserChoice: ' + RegStr(HKEY_CURRENT_USER,
      'Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\' + AExt +
      '\UserChoice', 'ProgId') + sLineBreak +
    // 사용 이력 — 이 줄 없으면 갈린 단계 추적 불가.
    'OpenWithList MRU: ' + OpenWithMruExe(AExt) + sLineBreak +
    'HKCU\Classes: ' + RegStr(HKEY_CURRENT_USER, 'Software\Classes\' + AExt, '') +
    sLineBreak +
    'HKCR: ' + RegStr(HKEY_CLASSES_ROOT, AExt, '');

  // 실제 실행 명령까지 추적 (셸 캐시 미경유).
  LEffective := UserChoiceProgID(AExt);
  if LEffective = '' then
    LEffective := ClassProgID(AExt);

  if LEffective <> '' then
  begin
    LCmd := RegStr(HKEY_CLASSES_ROOT, LEffective + '\shell\open\command', '');
    Result := Result + sLineBreak + '실행: ' + LCmd;
  end;

  Result := Result + sLineBreak + '우리 ProgID: ' + LPID;
end;

function AssocEnvInfo: string;
var
  LName: array[0..255] of Char;
  LSize: DWORD;
  LToken: THandle;
  LElev: TOKEN_ELEVATION;
  LRet: DWORD;
  LUser, LSid: string;
  LStr: LPWSTR;
  LBuf: array[0..255] of Byte;
begin
  LUser := '?';
  LSize := Length(LName);
  if GetUserName(LName, LSize) then
    LUser := LName;

  LSid := '?';
  Result := '';

  if OpenProcessToken(GetCurrentProcess, TOKEN_QUERY, LToken) then
  try
    // 승격 여부 — 승격 프로세스는 다른 하이브를 봄
    if GetTokenInformation(LToken, TokenElevation, @LElev, SizeOf(LElev), LRet) then
      Result := '상승=' + BoolToStr(LElev.TokenIsElevated <> 0, True);

    if GetTokenInformation(LToken, TokenUser, @LBuf, SizeOf(LBuf), LRet) and
       ConvertSidToStringSid(PTokenUser(@LBuf)^.User.Sid, LStr) then
    try
      LSid := LStr;
    finally
      LocalFree(HLOCAL(LStr));
    end;
  finally
    CloseHandle(LToken);
  end;

  Result := Format('계정=%s  %s  SID=%s', [LUser, Result, LSid]);
end;

// 등록한 확장자 전체 — AssocExts 아닌 레지스트리에서 읽음. 노출 목록을 줄여도
// 옛 등록이 방치되지 않게.
function AssocOwnedList: TArray<string>;
var
  LReg: TRegistry;
  LNames: TStringList;
  I: Integer;
begin
  Result := nil;

  LReg := TRegistry.Create(KEY_READ);
  try
    LReg.RootKey := HKEY_CURRENT_USER;
    if not LReg.OpenKey(AssocBackupKey, False) then
      Exit;
    try
      LNames := TStringList.Create;
      try
        LReg.GetValueNames(LNames);
        for I := 0 to LNames.Count - 1 do
          if LNames[I] <> '' then
            Result := Result + [LNames[I]];
      finally
        LNames.Free;
      end;
    finally
      LReg.CloseKey;
    end;
  finally
    LReg.Free;
  end;
end;

// AssocExts 인덱스, 없으면 -1.
function AssocIndexOf(const AExt: string): Integer;
var
  I: Integer;
begin
  for I := Low(AssocExts) to High(AssocExts) do
    if SameText(AssocExts[I].Ext, AExt) then
      Exit(I);

  Result := -1;
end;

function IsMediaFile(const AFileName: string): Boolean;
begin
  Result := AssocIndexOf(ExtractFileExt(AFileName)) >= 0;
end;

function IsPlaylistFile(const AFileName: string): Boolean;
var
  LIndex: Integer;
begin
  LIndex := AssocIndexOf(ExtractFileExt(AFileName));
  Result := (LIndex >= 0) and (AssocExts[LIndex].Group = agList);
end;

// 설정 앱 기본 앱 화면 (선택 창 실패 시 최후 수단).
// SHOpenWithDialog 불가 — Win10 부터 등록 기능 제거, 플래그 무관 [한 번만]
// 창만 뜸 (탐색기 'openas' 동사도 동일).
// AOurPage=True = 우리 앱 페이지 직행. registeredAppUser = RegisteredApplications
// 값 이름. 페이지엔 Capabilities 등록 확장자가 각각 [기본값 설정] 과 나열.
// 확장자 단위 직행 파라미터 없음 — 쿼리 모르는 빌드는 그냥 목록.
procedure ShowDefaultApps(AHandle: HWND; AOurPage: Boolean);
const
  Uri: array[Boolean] of string = (
    'ms-settings:defaultapps',
    'ms-settings:defaultapps?registeredAppUser=KPlayer');
begin
  ShellExecute(AHandle, 'open', PChar(Uri[AOurPage]), nil, nil, SW_SHOWNORMAL);
end;

type
  PFindSheet = ^TFindSheet;
  TFindSheet = record
    Name: string;   // 찾을 임시 파일명 (창 제목 = '<파일명> 속성')
    Found: HWND;
  end;

// 제목에 이름이 든 대화상자(#32770) 검색. 프로세스 불문 — 셸이 타 프로세스에서
// 띄우기도 해 PID 필터로는 못 찾음. 비교는 확장자 뗀 이름
// ('확장명 숨기기' 켜지면 제목에 없음).
function EnumSheetProc(AWnd: HWND; AParam: LPARAM): BOOL; stdcall;
var
  LInfo: PFindSheet;
  LClass, LText: array[0..259] of Char;
begin
  Result := True;   // 계속
  LInfo := PFindSheet(AParam);

  if GetClassName(AWnd, LClass, Length(LClass)) = 0 then
    Exit;
  if not SameText(LClass, '#32770') then
    Exit;

  if GetWindowText(AWnd, LText, Length(LText)) = 0 then
    Exit;
  if Pos(LowerCase(LInfo^.Name), LowerCase(string(LText))) = 0 then
    Exit;

  LInfo^.Found := AWnd;
  Result := False;  // 찾았다
end;

var
  // 속성 창을 뜨는 순간 잡는 훅 상태. 콜백에 인자 못 넘겨 유닛 변수
  // (선택 창은 동시 1개).
  GSheetName: string;
  GSheetAnchor: TPoint;
  GSheetFound: HWND = 0;

// 속성 창 소거. SW_HIDE 금지 — 셸이 곧 재표시하며 깜빡임. 알파 0 투명화로
// 표시 상태 유지 (뒤에 뜨는 선택 창의 배치 기준 보존). DWM 클로킹 병행.
// 위치는 우리 창 가운데 — 화면 밖으로 보내면 선택 창이 엉뚱한 모니터로 밀림.
procedure VanishSheet(AWnd: HWND; const AAnchor: TPoint);
var
  LCloak: BOOL;
begin
  SetWindowLong(AWnd, GWL_EXSTYLE,
    GetWindowLong(AWnd, GWL_EXSTYLE) or WS_EX_LAYERED);
  SetLayeredWindowAttributes(AWnd, 0, 0, LWA_ALPHA);

  LCloak := True;
  DwmSetWindowAttribute(AWnd, DWMWA_CLOAK, @LCloak, SizeOf(LCloak));

  MoveWindow(AWnd, AAnchor.X, AAnchor.Y, 0, 0, False);
end;

// 속성 창 생성 순간 통지받아 표시 전 소거. EVENT_OBJECT_SHOW 는 늦음
// (이미 표시 후) — CREATE 부터 받고, 셸 재표시 대비 SHOW 에서도 재소거.
procedure SheetShownProc(hHook: THandle; event: DWORD; wnd: HWND;
  idObject, idChild: Longint; idEventThread, dwmsEventTime: DWORD); stdcall;
var
  LClass, LText: array[0..259] of Char;
  LPid: DWORD;
begin
  // 창 자체 이벤트만 (OBJID_WINDOW = 0)
  if (wnd = 0) or (idObject <> 0) or (idChild <> 0) then
    Exit;

  // 이미 잡은 창이면 재소거만 (셸이 나중에 재표시함).
  if GSheetFound <> 0 then
  begin
    if wnd = GSheetFound then
      VanishSheet(wnd, GSheetAnchor);
    Exit;
  end;

  if GetClassName(wnd, LClass, Length(LClass)) = 0 then
    Exit;
  if not SameText(LClass, '#32770') then
    Exit;

  // 생성 직후엔 제목이 빌 수 있음 — 이름 일치 = 확정, 빈 제목 = 후보
  // (우리 프로세스 대화상자 제외).
  if GetWindowText(wnd, LText, Length(LText)) > 0 then
  begin
    if Pos(LowerCase(GSheetName), LowerCase(string(LText))) = 0 then
      Exit;
  end
  else
  begin
    GetWindowThreadProcessId(wnd, LPid);
    if LPid = GetCurrentProcessId then
      Exit;
  end;

  GSheetFound := wnd;
  VanishSheet(wnd, GSheetAnchor);
end;

// 확장자 하나의 [기본 앱 선택] 창 ([기본값 설정] 버튼 있는 창). 직접 부르는
// 공개 API 없음 — 파일 속성 창 경유:
//   1. 대상 확장자로 빈 임시 파일 생성
//   2. '속성' 창 실행 (셸이 별도 스레드에서 만듦)
//   3. 창을 찾아 투명화 (VanishSheet) — 셸이 만들 때까지 기다리는 동안
//      Application.ProcessMessages 로 우리 메시지 루프도 돌림
//   4. '연결 프로그램 - 변경'(0x3363) 전송 → 선택 창
// 선택 창 닫힘 시점 불명 → 속성 창·임시 파일을 AJob 으로 반환, 환경설정 창
// 재활성화 때 ClosePicker 가 정리.
// 0x3363 은 비문서화 ID — 빌드 따라 변할 수 있음. 실패 시 False → 호출부가
// 설정 앱 폴백.
function ShowDefaultAppPicker(const AExt: string; var AJob: TPickerJob;
  const AAnchor: TPoint): Boolean;
const
  SearchTimeout = 5000;   // 속성 창 대기 한계 (ms)
var
  LDir: array[0..MAX_PATH] of Char;
  LExec: TShellExecuteInfo;
  LFind: TFindSheet;
  LHandle, LHook: THandle;
  LDeadline: UInt64;
begin
  Result := False;

  AJob.Sheet := 0;
  AJob.TempFile := '';

  GetTempPath(Length(LDir), LDir);
  AJob.TempFile := IncludeTrailingPathDelimiter(LDir) +
    Format('KPlayer-assoc-%u%s', [GetTickCount, AExt]);

  LHandle := FileCreate(AJob.TempFile);
  if LHandle = THandle(-1) then
  begin
    AssocLog(AExt + ': 임시 파일 생성 실패 — ' + AJob.TempFile);
    AJob.TempFile := '';
    Exit;
  end;
  FileClose(LHandle);
  AssocLog(AExt + ': 임시 파일 ' + AJob.TempFile);

  // 훅 먼저 (깜빡임 제거 핵심). 폴링은 훅 놓쳤을 때 보조.
  LFind.Name := ChangeFileExt(ExtractFileName(AJob.TempFile), '');
  LFind.Found := 0;

  GSheetName := LFind.Name;
  GSheetAnchor := AAnchor;
  GSheetFound := 0;

  // CREATE~SHOW 전부 수신 — 생성 시점에 지워야 안 깜빡임.
  LHook := SetWinEventHook(EVENT_OBJECT_CREATE, EVENT_OBJECT_SHOW, 0,
    @SheetShownProc, 0, 0, WINEVENT_OUTOFCONTEXT);
  try
    FillChar(LExec, SizeOf(LExec), 0);
    LExec.cbSize := SizeOf(LExec);
    LExec.fMask := SEE_MASK_INVOKEIDLIST;
    LExec.lpVerb := 'properties';
    LExec.lpFile := PChar(AJob.TempFile);

    // 숨김 표시 요청 (셸이 무시하면 훅/폴링이 소거).
    LExec.nShow := SW_HIDE;

    if not ShellExecuteEx(@LExec) then
    begin
      AssocLog(Format('%s: 속성 창 호출 실패 (err=%d)', [AExt, GetLastError]));
      Exit;
    end;

    LDeadline := GetTickCount64 + SearchTimeout;

    while (LFind.Found = 0) and (GSheetFound = 0) and (GetTickCount64 < LDeadline) do
    begin
      // 훅 콜백은 우리 메시지 큐 경유 — 큐를 돌려야 불림.
      Application.ProcessMessages;

      if GSheetFound <> 0 then
        Break;

      EnumWindows(@EnumSheetProc, LPARAM(@LFind));
      Sleep(5);
    end;

    if GSheetFound <> 0 then
    begin
      // 훅이 잡음 — 그 자리에서 이미 소거됨.
      AJob.Sheet := GSheetFound;
      AssocLog(Format('%s: 속성 창 HWND=%x (훅)', [AExt, GSheetFound]));
    end
    else if LFind.Found <> 0 then
    begin
      AJob.Sheet := LFind.Found;
      GSheetFound := LFind.Found;   // 훅도 알아야 재소거함
      AssocLog(Format('%s: 속성 창 HWND=%x (폴링)', [AExt, LFind.Found]));
      VanishSheet(AJob.Sheet, AAnchor);
    end
    else
    begin
      AssocLog(Format('%s: 속성 창을 찾지 못했다 (%dms 초과, 찾던 이름 "%s")',
        [AExt, SearchTimeout, LFind.Name]));
      Exit;
    end;

    Result := PostMessage(AJob.Sheet, WM_COMMAND, IDM_CHANGE_ASSOC, 0);
    AssocLog(Format('%s: 변경 명령(0x%x) 전달 %s',
      [AExt, IDM_CHANGE_ASSOC, BoolToStr(Result, True)]));

    // 셸이 명령 받고 속성 창 재표시 — 잠깐 메시지 돌리며 재소거.
    LDeadline := GetTickCount64 + 700;
    while GetTickCount64 < LDeadline do
    begin
      Application.ProcessMessages;
      VanishSheet(AJob.Sheet, AAnchor);
      Sleep(10);
    end;
  finally
    if LHook <> 0 then
      UnhookWinEvent(LHook);
  end;
end;

// 숨긴 속성 창 닫고 임시 파일 삭제. 실패 경로 포함 항상 호출됨.
procedure ClosePickerJob(var AJob: TPickerJob);
begin
  if AJob.Sheet <> 0 then
  begin
    if IsWindow(AJob.Sheet) then
      PostMessage(AJob.Sheet, WM_CLOSE, 0, 0);
    AJob.Sheet := 0;
  end;

  if AJob.TempFile <> '' then
  begin
    // 속성 창이 아직 파일을 붙들 수 있음 — 실패해도 %TEMP% 0바이트라 로그만.
    if not System.SysUtils.DeleteFile(AJob.TempFile) then
      AssocLog('임시 파일 삭제 실패 — ' + AJob.TempFile);

    AJob.TempFile := '';
  end;
end;

// 확장자와 무관한 1회성 등록 (앱 이름, 설정 앱 노출).
procedure EnsureAppRegistered;
var
  LReg: TRegistry;
  LExe: string;
begin
  LExe := ParamStr(0);

  LReg := TRegistry.Create(KEY_READ or KEY_WRITE);
  try
    LReg.RootKey := HKEY_CURRENT_USER;

    if LReg.OpenKey(AssocClassKey + 'Applications\' + ExtractFileName(LExe), True) then
    try
      LReg.WriteString('FriendlyAppName', 'KPlayer');
    finally
      LReg.CloseKey;
    end;

    if LReg.OpenKey(AssocCapKey, True) then
    try
      LReg.WriteString('ApplicationName', 'KPlayer');
      LReg.WriteString('ApplicationDescription', _('libmpv 기반 미디어 플레이어'));
    finally
      LReg.CloseKey;
    end;

    // 없으면 윈도우 설정 '기본 앱' 목록에 KPlayer 미표시.
    if LReg.OpenKey('\Software\RegisteredApplications', True) then
    try
      LReg.WriteString('KPlayer', 'Software\KPlayer\Capabilities');
    finally
      LReg.CloseKey;
    end;
  finally
    LReg.Free;
  end;
end;

// 확장자 하나 등록. 재호출 가능 — SyncFileAssoc 이 exe 경로 갱신용으로 재호출.
procedure AssocRegister(const AIndex: Integer);
var
  LReg: TRegistry;
  LExt, LPID, LExe, LPrev: string;
begin
  LExt := AssocExts[AIndex].Ext;
  LPID := ExtProgID(LExt);
  LExe := ParamStr(0);

  LReg := TRegistry.Create(KEY_READ or KEY_WRITE);
  try
    LReg.RootKey := HKEY_CURRENT_USER;

    if LReg.OpenKey(AssocClassKey + LPID, True) then
    try
      // 탐색기 표시 이름 = 등록 시점 언어. 언어를 바꾸면 SyncFileAssoc 이 다시 쓴다.
      LReg.WriteString('', _(AssocExts[AIndex].Desc));
    finally
      LReg.CloseKey;
    end;

    // 확장자별 .ico 우선, 없으면 exe 첫 아이콘 (ExtIconRef).
    if LReg.OpenKey(AssocClassKey + LPID + '\DefaultIcon', True) then
    try
      LReg.WriteString('', ExtIconRef(LExt));
    finally
      LReg.CloseKey;
    end;

    // %1 따옴표 필수 — 공백/한글 경로 조각남.
    if LReg.OpenKey(AssocClassKey + LPID + '\shell\open\command', True) then
    try
      LReg.WriteString('', '"' + LExe + '" "%1"');
    finally
      LReg.CloseKey;
    end;

    // 탐색기 '연결 프로그램' 목록 등재 — UserChoice 에 막혀 기본이 못 돼도
    // 사용자가 직접 고를 수 있게.
    if LReg.OpenKey(AssocClassKey + LExt + '\OpenWithProgIDs', True) then
    try
      LReg.WriteString(LPID, '');
    finally
      LReg.CloseKey;
    end;

    if LReg.OpenKey(AssocClassKey + 'Applications\' + ExtractFileName(LExe) +
         '\SupportedTypes', True) then
    try
      LReg.WriteString(LExt, '');
    finally
      LReg.CloseKey;
    end;

    if LReg.OpenKey(AssocCapKey + '\FileAssociations', True) then
    try
      LReg.WriteString(LExt, LPID);
    finally
      LReg.CloseKey;
    end;

    // 확장자 기본 클래스 — 없으면 '연결 프로그램' 목록에만 오르고 더블클릭으론 안 열림.
    LPrev := '';
    if LReg.OpenKey(AssocClassKey + LExt, True) then
    try
      if LReg.ValueExists('') then
        LPrev := LReg.ReadString('');

      LReg.WriteString('', LPID);
    finally
      LReg.CloseKey;
    end;

    // 등록 전 값 백업. 기존 백업은 안 덮음 — 재등록 때 덮으면 '원래 값'=우리
    // 자신이 되어 복원처 상실. 빈 문자열도 유효 백업 (= HKCU 원래 값 없음).
    if SameText(LPrev, LPID) then
      LPrev := '';

    if LReg.OpenKey(AssocBackupKey, True) then
    try
      if not LReg.ValueExists(LExt) then
        LReg.WriteString(LExt, LPrev);
    finally
      LReg.CloseKey;
    end;
  finally
    LReg.Free;
  end;
end;

// 해제는 확장자만 필요 (AssocExts 다른 필드 안 봄) → 노출 목록에서 뺀
// 확장자도 소유 목록에 있으면 해제 가능 — 제거 프로그램이 옛 등록까지 훑음.
procedure AssocUnregisterExt(const AExt: string);
var
  LReg: TRegistry;
  LExt, LPID, LPrev: string;
  LHasBackup: Boolean;
begin
  LExt := AExt;
  LPID := ExtProgID(LExt);

  LReg := TRegistry.Create(KEY_READ or KEY_WRITE);
  try
    LReg.RootKey := HKEY_CURRENT_USER;

    // 백업 먼저 읽음. OpenKeyReadOnly 금지 — 성공 시 인스턴스 Access 가
    // KEY_READ 로 바뀌어 이후 쓰기가 예외로 죽음.
    LPrev := '';
    LHasBackup := False;
    if LReg.OpenKey(AssocBackupKey, False) then
    try
      LHasBackup := LReg.ValueExists(LExt);
      if LHasBackup then
        LPrev := LReg.ReadString(LExt);
    finally
      LReg.CloseKey;
    end;

    // 기본 클래스가 아직 우리 것일 때만 복원 — 사용자가 딴 걸 골랐으면 그 선택 우선.
    if LReg.OpenKey(AssocClassKey + LExt, False) then
    try
      if LReg.ValueExists('') and SameText(LReg.ReadString(''), LPID) then
      begin
        if LPrev <> '' then
          LReg.WriteString('', LPrev)
        else
          LReg.DeleteValue('');   // 없던 상태로 — HKLM 연결이 다시 드러남
      end;
    finally
      LReg.CloseKey;
    end;

    if LHasBackup then
      SHDeleteValue(HKEY_CURRENT_USER, PChar(Copy(AssocBackupKey, 2, MaxInt)),
        PChar(LExt));
  finally
    LReg.Free;
  end;

  // TRegistry.DeleteKey 는 하위 키 있으면 실패 → SHDeleteKey (재귀 삭제)
  SHDeleteKey(HKEY_CURRENT_USER, PChar('Software\Classes\' + LPID));

  SHDeleteValue(HKEY_CURRENT_USER,
    PChar('Software\Classes\' + LExt + '\OpenWithProgIDs'), PChar(LPID));
  SHDeleteValue(HKEY_CURRENT_USER,
    PChar('Software\Classes\Applications\' + ExtractFileName(ParamStr(0)) +
      '\SupportedTypes'), PChar(LExt));
  SHDeleteValue(HKEY_CURRENT_USER,
    PChar('Software\KPlayer\Capabilities\FileAssociations'), PChar(LExt));

  // 기본 앱=우리면 지정도 삭제 (삭제는 허용 — 해시 보호는 쓰기만). 남기면
  // 연결 없는 기본 앱 = Broken. 빌드별 활성 키가 달라 새/옛 키 둘 다 삭제.
  if SameText(UserChoiceProgID(LExt), LPID) then
  begin
    SHDeleteKey(HKEY_CURRENT_USER,
      PChar('Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\' +
        LExt + '\UserChoiceLatest'));
    SHDeleteKey(HKEY_CURRENT_USER,
      PChar('Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\' +
        LExt + '\UserChoice'));
  end;
end;

procedure AssocUnregister(const AIndex: Integer);
begin
  AssocUnregisterExt(AssocExts[AIndex].Ext);
end;

// 등록 연결 전부 복원 + 우리 흔적 삭제. 제거 프로그램이 KPlayer.exe /uninst
// 로 호출 — 설치 폴더 삭제 전이어야 함.
// 대상은 AssocExts 아닌 소유 목록(AssocOwnedList) — 노출 목록에서 뺀 확장자가
// 남으면 exe 삭제 후에도 기본 클래스가 우리 ProgID 를 가리킴.
procedure AssocUnregisterAll;
var
  LExt: string;
begin
  for LExt in AssocOwnedList do
    AssocUnregisterExt(LExt);

  // 잔여 키 (백업 목록 자체 + Capabilities). 하위 키 있어 재귀 삭제.
  SHDeleteKey(HKEY_CURRENT_USER, 'Software\KPlayer');

  // '기본 앱' 등록 값 — 남으면 설정 앱에 죽은 항목 보임.
  SHDeleteValue(HKEY_CURRENT_USER, 'Software\RegisteredApplications', 'KPlayer');

  SHDeleteKey(HKEY_CURRENT_USER,
    PChar('Software\Classes\Applications\' + ExtractFileName(ParamStr(0))));

  SHChangeNotify(SHCNE_ASSOCCHANGED, SHCNF_IDLIST, nil, nil);
end;

type
  // 기본 앱 키 감시 스레드. 정지는 이벤트 — 짧은 타임아웃 폴링은 깰 때마다
  // 알림 재등록하는 낭비.
  TAssocWatcher = class(TThread)
  private
    FStop: THandle;
    FOnChange: TProc;
  protected
    procedure Execute; override;
    procedure TerminatedSet; override;
  public
    constructor Create(const AOnChange: TProc);
    destructor Destroy; override;
  end;

constructor TAssocWatcher.Create(const AOnChange: TProc);
begin
  FOnChange := AOnChange;
  FStop := CreateEvent(nil, True, False, nil);   // 수동 리셋

  FreeOnTerminate := False;
  inherited Create(False);
end;

destructor TAssocWatcher.Destroy;
begin
  inherited;
  CloseHandle(FStop);
end;

procedure TAssocWatcher.TerminatedSet;
begin
  SetEvent(FStop);   // INFINITE 대기 즉시 탈출
end;

procedure TAssocWatcher.Execute;
const
  // 이름/값 변경만 — 속성·보안까지 받으면 트리거만 증가.
  Filter = REG_NOTIFY_CHANGE_NAME or REG_NOTIFY_CHANGE_LAST_SET;
var
  LKey: HKEY;
  LEvent: THandle;
  LWait: array[0..1] of THandle;
begin
  if RegOpenKeyEx(HKEY_CURRENT_USER,
       'Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts', 0,
       KEY_NOTIFY, LKey) <> ERROR_SUCCESS then
    Exit;
  try
    LEvent := CreateEvent(nil, True, False, nil);
    if LEvent = 0 then
      Exit;
    try
      LWait[0] := LEvent;
      LWait[1] := FStop;

      while not Terminated do
      begin
        if RegNotifyChangeKeyValue(LKey, True, Filter, LEvent, True) <> ERROR_SUCCESS then
          Break;

        if WaitForMultipleObjects(2, @LWait[0], False, INFINITE) <> WAIT_OBJECT_0 then
          Break;   // 정지 이벤트이거나 오류

        ResetEvent(LEvent);
        if Terminated then
          Break;

        // Queue (Synchronize 아님) — 기다릴 이유 없고 수신측이 타이머로 모아 처리.
        Queue(procedure
          begin
            if Assigned(FOnChange) then
              FOnChange();
          end);
      end;
    finally
      CloseHandle(LEvent);
    end;
  finally
    RegCloseKey(LKey);
  end;
end;

function AssocWatch(const AOnChange: TProc): TThread;
begin
  Result := TAssocWatcher.Create(AOnChange);
end;

procedure AssocUnwatch(var AThread: TThread);
begin
  if AThread = nil then
    Exit;

  AThread.Terminate;    // TerminatedSet 이 정지 이벤트를 신호한다
  AThread.WaitFor;
  FreeAndNil(AThread);
end;

procedure SyncFileAssoc;
var
  LExts: TArray<string>;
  LExt: string;
  LIndex, LCount: Integer;
begin
  LExts := AssocOwnedList;
  if Length(LExts) = 0 then
    Exit;

  LCount := 0;

  for LExt in LExts do
  begin
    // 노출 목록에서 빠진 확장자는 설명 정보가 없어 다시 쓸 수 없다.
    // 해제는 환경설정 화면에서만 한다 (여기서 조용히 지우면 사용자가 모른다).
    LIndex := AssocIndexOf(LExt);
    if LIndex < 0 then
      Continue;

    AssocRegister(LIndex);   // exe 경로가 바뀌었어도 이 호출로 갱신된다
    Inc(LCount);
  end;

  if LCount > 0 then
  begin
    EnsureAppRegistered;
    SHChangeNotify(SHCNE_ASSOCCHANGED, SHCNF_IDLIST, nil, nil);
  end;
end;

initialization

finalization
  FriendlyCache.Free;   // nil 이어도 안전하다

end.
