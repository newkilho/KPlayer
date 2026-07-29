unit Assoc;

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.ShlObj, Winapi.ShellAPI,
  Winapi.ShLwApi, Winapi.Dwmapi, System.SysUtils, System.Classes,
  System.Generics.Collections, System.Win.Registry, Vcl.Forms;

type
  // 파일 연결 카드에서 다루는 확장자 분류
  TAssocGroup = (agVideo, agAudio, agList);

  TAssocExt = record
    Ext:   string;        // '.mp4'
    Desc:  string;        // 탐색기에 보일 파일 종류 이름 (ProgID 기본값으로 쓸 예정)
    Group: TAssocGroup;
    Main:  Boolean;       // [주요 파일] 버튼으로 선택되는 것
  end;

const
  AssocGroupNames: array[TAssocGroup] of string = ('비디오', '오디오', '재생목록');

  // 재생 가능한 확장자의 단일 출처. 연결 카드와 List.AddFile 의 필터가
  // 같이 본다 (IsMediaFile).
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
  // 콤보박스 인덱스 → mpv 옵션 값. 설정을 인덱스로 저장하므로 순서를 바꾸면
  // 기존 INI 값의 의미가 바뀐다 (추가는 뒤에만).
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

// 재생 가능한 파일인가. List.AddFile 의 필터도 이 함수를 쓴다 — 목록 필터와
// 연결 목록이 갈리면 연결해서 더블클릭했는데 목록에 안 들어간다 (그랬었다).
function IsMediaFile(const AFileName: string): Boolean;

// 재생목록 파일인가 (.m3u / .m3u8 / .pls). 목록에 넣을 때 항목으로 펼쳐야 한다.
function IsPlaylistFile(const AFileName: string): Boolean;

// 등록해 둔 연결을 지금 exe 경로로 다시 기록한다 (시작할 때 한 번).
// 포터블이라 폴더가 바뀌면 등록된 실행 명령이 어긋난다.
procedure SyncFileAssoc;

type
  // 확장자 하나의 현재 상태 (AssocStateOf 가 채운다).
  //   Registered - 우리 ProgID 를 등록해 둔 확장자다 (= 트리 체크 상태)
  //   Ours       - 지금 KPlayer 로 열린다
  //   Other      - 우리가 아니면 그 프로그램 이름 (연결이 없으면 '')
  //   Hard       - UserChoice 나 사용 이력으로 정해져 있다. 등록만으로는 못
  //                가져오고 [기본 앱 선택] 창이 필요하다.
  //   Broken     - 기본 앱은 우리인데 우리 ProgID 가 없다. 더블클릭이 '앱을
  //                선택하세요' 로 끝나고, 다시 등록하면 살아난다.
  TAssocState = record
    Registered: Boolean;
    Ours: Boolean;
    Other: string;
    Hard: Boolean;
    Broken: Boolean;
  end;

  // [기본 앱 선택] 창을 띄우고 남는 뒷정리 대상 (ShowDefaultAppPicker 참고).
  //   Sheet    - 투명하게 만들어 둔 파일 속성 창
  //   TempFile - 속성 창을 열기 위해 만든 빈 임시 파일
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

// 사용자가 직접 손대야 넘어오는 상태인가. UI 에서 [적용안됨] 뱃지를 띄우는
// 조건이다 — 등록(체크)한 확장자만 알린다.
function AssocNeedsUser(const AState: TAssocState): Boolean;

// 판정 근거를 사람이 읽을 형태로. 레지스트리 값과 실제 동작이 어긋날 때
// 어디서 갈라지는지 보려고 툴팁에 붙인다.
function AssocResolveInfo(const AExt: string): string;

// 실행 환경 한 줄 (계정 / 권한 상승 / HKCU 하이브). 우리가 쓰는 HKCU 가
// 탐색기가 읽는 하이브와 다르면 값은 맞는데 동작이 다르다.
function AssocEnvInfo: string;

// 등록
procedure AssocRegister(const AIndex: Integer);
procedure AssocUnregister(const AIndex: Integer);
procedure EnsureAppRegistered;

// 등록해 둔 연결을 전부 되돌린다 (제거 프로그램이 /uninst 로 부른다).
procedure AssocUnregisterAll;

// 기본 앱 선택
function ShowDefaultAppPicker(const AExt: string; var AJob: TPickerJob;
  const AAnchor: TPoint): Boolean;
procedure ClosePickerJob(var AJob: TPickerJob);
procedure ShowDefaultApps(AHandle: HWND; AOurPage: Boolean);

// 감시. FileExts 가 바뀌면 AOnChange 를 메인 스레드로 넘긴다. 알림이 몰려
// 오므로 받는 쪽에서 디바운스해야 한다. 평상시에는 이벤트에서 잠든다.
function AssocWatch(const AOnChange: TProc): TThread;
procedure AssocUnwatch(var AThread: TThread);

// 로그. 환경설정 창이 자기 메모를 걸어 둔다 (안 걸면 아무 일도 하지 않는다).
var
  AssocLogProc: TProc<string> = nil;

procedure AssocLog(const AMsg: string);

implementation

procedure AssocLog(const AMsg: string);
begin
  // 걸린 곳이 없으면 아무 일도 하지 않는다 (창이 없을 때도 불린다)
  if Assigned(AssocLogProc) then
    AssocLogProc(AMsg);
end;

// 파일 속성 창의 '연결 프로그램 - 변경' 명령 ID (비문서화). 이 명령이
// 확장자별 [기본 앱 선택] 창을 띄운다 — ShowDefaultAppPicker 주석 참고.
const
  IDM_CHANGE_ASSOC = $3363;

// 'ProgID|exe' -> 화면에 보일 프로그램 이름. FriendlyProgramName 이 채운다.
// 처음 쓸 때 만들고 유닛이 끝날 때 버린다.
var
  FriendlyCache: TDictionary<string, string> = nil;

// 레지스트리 계층 (모두 HKCU — UAC 승격이 필요 없다)
//
//   Software\Classes\KPlayer.mp4                ProgID (설명/아이콘/실행 명령)
//   Software\Classes\.mp4                       (기본값) = 우리 ProgID
//   Software\Classes\.mp4\OpenWithProgIDs       '연결 프로그램' 후보로 노출
//   Software\Classes\Applications\KPlayer.exe   FriendlyAppName / SupportedTypes
//   Software\KPlayer\Capabilities               설정 앱의 '기본 앱' 목록용
//   Software\RegisteredApplications             위 Capabilities 등록
//   Software\KPlayer\FileAssoc                  등록 전 값 백업 + 소유 목록
//
// 여기서 하는 일은 후보 등록까지다. 기본 앱(FileExts\...\UserChoice)은 쓰지
// 않는다 — 해시로 보호되고, 계산해 써 봐도 Win11 26200 에서 거부됐다
// (2026-07-27). 지정은 사용자가 [기본 앱 선택] 창에서 직접 한다.

const
  // 백업 겸 소유 목록. 값 이름은 확장자, 데이터는 등록 전의 ProgID.
  // 데이터가 비었으면 HKCU 에 원래 값이 없었다는 뜻이므로 해제할 때 값을
  // 지운다 — 빈 문자열을 기본값으로 남기면 HKLM 연결이 가려진다.
  AssocBackupKey = '\Software\KPlayer\FileAssoc';
  AssocCapKey    = '\Software\KPlayer\Capabilities';
  AssocClassKey  = '\Software\Classes\';

  // 확장자별 아이콘 폴더 (exe 옆). 파일 이름은 점 뺀 확장자 + '.ico'.
  AssocIconDir   = 'Icon\';

function ExtProgID(const AExt: string): string;
begin
  Result := 'KPlayer' + AExt;   // '.mp4' -> 'KPlayer.mp4'
end;

// DefaultIcon 에 쓸 문자열. exe 옆 Icon 폴더에 확장자와 같은 이름의 .ico 가
// 있으면 그것을, 없으면 exe 에 박힌 첫 번째 아이콘을 가리킨다.
//
// exe 리소스에 넣지 않는 이유: 별도 .rc 를 붙이면 Delphi 가 만드는 .res 의
// MAINICON 하위 RT_ICON 과 ID(둘 다 1부터)가 겹쳐 링크가 깨진다. 피하려면 앱
// 아이콘·버전 정보까지 직접 쓴 .rc 하나로 몰아야 하는데, 어차피 libmpv-2.dll
// 과 KPlayer.lua 를 exe 옆에 두는 배포라 단일 파일이 되지도 않는다.
//
// 경로를 상수로 캐시하지 않는 것도 일부러다 — 포터블이라 폴더가 바뀌고,
// SyncFileAssoc 이 AssocRegister 를 다시 부르면서 이 값이 새로 만들어진다.
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

// 레지스트리 문자열 하나 (없으면 ''). 값 이름이 '' 이면 기본값.
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

// 확장자에 연결된 ProgID. 사용자별 설정(HKCU)이 먼저고, 없으면 시스템 전체
// (HKEY_CLASSES_ROOT — HKLM 과 HKCU 가 합쳐진 뷰) 를 본다.
function ClassProgID(const AExt: string): string;
begin
  Result := RegStr(HKEY_CURRENT_USER, 'Software\Classes\' + AExt, '');
  if Result = '' then
    Result := RegStr(HKEY_CLASSES_ROOT, AExt, '');
end;

// 확장자의 기본 앱 ProgID (지정이 없으면 '').
//
// 윈도우 11(26xxx)은 UserChoice 가 아니라 UserChoiceLatest 를 본다. 구조도
// 달라서 ProgId 가 값이 아니라 하위 키이고 그 안에 같은 이름의 값이 있다:
//
//   FileExts\.mp4\UserChoiceLatest\ProgId   ProgId = KingPlayer.mp4
//
// 옛 키만 읽으면 "지정 없음" 으로 잘못 판정한다 (레지스트리는 우리 것인데
// 탐색기는 남을 띄우는 모순의 원인이었다). 새 키 → 옛 키 순서로 본다.
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

// 마지막으로 이 확장자를 연 프로그램의 exe 이름 (없으면 '').
// UserChoice 가 없어도 이 사용 이력이 클래스 연결을 이기므로 반드시 봐야 한다.
// MRUList 의 첫 글자가 가리키는 값이 현재 승자다.
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

  // 셸 자신의 '다른 앱 선택' 은 프로그램이 아니다 ({CLSID}\OpenWith.exe).
  if SameText(ExtractFileName(Result), 'OpenWith.exe') then
    Result := '';
end;

// 실행 명령에서 exe 경로만 뽑는다 ('"C:\...\x.exe" "%1"' -> 'C:\...\x.exe').
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

// exe 의 버전 리소스에서 프로그램 이름 (ProductName → FileDescription).
// 셸 호출이 아니므로 AssocQueryString 의 캐시 문제와 무관하다.
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

  // 언어/코드페이지는 파일이 알려주는 것을 먼저, 없으면 흔한 값을 시도한다.
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

// 화면에 보일 프로그램 이름 (캐시 없는 버전 — 부를 때는 FriendlyProgramName).
// ProgID 의 기본값은 프로그램 이름이 아니라 파일 형식 이름이라 쓸 수 없다
// ('7-Zip.zip' → 'zip Archive'). 실행 명령의 exe 를 따라가 버전 리소스에서
// 읽고, 실패하면 exe 이름이나 ProgID 를 그대로 쓴다.
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

    // App Paths 에만 있는 프로그램이 있다 (7-Zip 이 그렇다).
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

// 위와 같은데 결과를 캐시한다. AssocStateOf 는 창을 열 때 38번, 체크할 때마다,
// 감시가 깨울 때마다 다시 도는데 프로그램 이름은 실행 중에 바뀌지 않는다
// (못 찾은 결과도 캐시한다).
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

// 우리가 등록해 둔 확장자인지 (= 백업 목록에 있는지). 백업 없이 등록했던
// 예전 버전을 위해 ProgID 키 존재도 함께 본다.
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

// 확장자 하나의 현재 상태. 레지스트리 값만 본다 — AssocQueryString 은 프로세스
// 안에 캐시되어 방금 바뀐 값을 돌려주지 않는다.
//
// 우선순위:
//   UserChoice(Latest) > OpenWithList MRU(사용 이력) > HKCU\Classes > HKLM\Classes
//
// HKLM 에 남이 있다는 것만으로 '남의 것' 으로 보지 않는다 — HKLM 클래스 등록은
// 우리 HKCU 등록을 이기지 못한다. 우리가 지는 것은 UserChoice 나 사용 이력이
// 있을 때뿐이다 (HKLM 을 근거로 고치면 우리로 열리는 확장자에 경고가 뜬다).
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
    // 기본 앱이 명시적으로 지정된 상태 — 등록만으로는 못 가져온다
    Result.Ours := SameText(LChoice, LPID);
    Result.Hard := not Result.Ours;

    if Result.Ours then
      // 우리를 가리키는데 ProgID 가 없으면 아무것도 열리지 않는다 (해제할 때
      // 이 키까지 정리하지만, 삭제가 거부된 PC 와 옛 버전이 남는다).
      Result.Broken := not RegHasKey(HKEY_CURRENT_USER,
        'Software\Classes\' + LPID + '\shell\open\command')
    else
      Result.Other := FriendlyProgramName(LChoice, '');

    Exit;
  end;

  // 사용 이력. 비교는 ProgID 가 아니라 exe 파일 이름으로 한다.
  LExe := OpenWithMruExe(AExt);
  if LExe <> '' then
  begin
    Result.Ours := SameText(ExtractFileName(LExe),
      ExtractFileName(ParamStr(0)));

    if not Result.Ours then
    begin
      Result.Hard := True;   // 이력은 등록으로 못 이긴다 — 선택 창이 필요하다
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
  // 등록하지 않은 확장자는 남이 쥐고 있어도 알리지 않는다 (사용자가 원한 적이
  // 없다). Broken 만은 등록 여부와 무관하게 알린다 — 아무것도 열리지 않는다.
  Result := AState.Broken or (AState.Registered and (AState.Other <> ''));
end;

// 판정 근거를 그대로 보여준다. 판정과 실제 동작이 어긋날 때 어느 값에서
// 갈라지는지 눈으로 봐야 한다.
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
    // 사용 이력. 어느 단계에서 갈렸는지 이 줄이 없으면 다시 못 잡는다.
    'OpenWithList MRU: ' + OpenWithMruExe(AExt) + sLineBreak +
    'HKCU\Classes: ' + RegStr(HKEY_CURRENT_USER, 'Software\Classes\' + AExt, '') +
    sLineBreak +
    'HKCR: ' + RegStr(HKEY_CLASSES_ROOT, AExt, '');

  // 실제로 실행될 명령까지 따라가 본다 (셸 캐시를 거치지 않는 경로다).
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
    // 권한 상승 여부 — 상승된 프로세스는 다른 하이브를 볼 수 있다
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

// 우리가 등록해 둔 확장자 전체. 노출 목록(AssocExts)이 아니라 레지스트리에서
// 읽는다 — 노출 목록을 줄여도 예전에 등록한 확장자가 방치되지 않는다.
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

// AssocExts 에서 확장자의 인덱스. 없으면 -1.
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

// 설정 앱의 기본 앱 화면 (선택 창을 띄우지 못했을 때의 마지막 수단).
//
// SHOpenWithDialog 는 길이 아니다 — Win10 부터 등록 기능이 빠져 플래그를 어떻게
// 조합해도 [한 번만] 만 있는 창이 뜬다 (탐색기의 'openas' 동사도 같다).
//
// AOurPage=True 면 우리 앱 페이지로 바로 들어간다. registeredAppUser 값은
// RegisteredApplications 의 값 이름이고, 그 페이지에는 Capabilities 에 등록한
// 확장자가 항목마다 [기본값 설정] 과 함께 나열된다. 확장자 하나로 바로 가는
// 파라미터는 없고, 쿼리를 모르는 빌드에서는 그냥 목록이 열린다.
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
    Name: string;   // 찾을 임시 파일명 (창 제목이 '<파일명> 속성' 형태다)
    Found: HWND;
  end;

// 제목에 그 이름이 든 대화상자(#32770)를 찾는다. 프로세스는 가리지 않는다 —
// 셸이 다른 프로세스에서 띄우는 경우가 있어 PID 로 거르면 못 찾는다. 비교는
// 확장자를 뗀 이름으로 한다 ('확장명 숨기기' 가 켜져 있으면 제목에 없다).
function EnumSheetProc(AWnd: HWND; AParam: LPARAM): BOOL; stdcall;
var
  LInfo: PFindSheet;
  LClass, LText: array[0..259] of Char;
begin
  Result := True;   // 계속 훑는다
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
  // 속성 창을 '보이는 순간' 잡기 위한 훅 상태. 콜백에 인자를 넘길 수 없어
  // 유닛 변수로 둔다 (선택 창은 한 번에 하나만 띄운다).
  GSheetName: string;
  GSheetAnchor: TPoint;
  GSheetFound: HWND = 0;

// 속성 창을 화면에서 지운다. SW_HIDE 로 숨기지 않는다 — 셸이 곧 다시 표시하면서
// 깜빡인다. 대신 알파 0 으로 투명하게 만들어 표시 상태를 유지한다 (그래야 뒤에
// 뜨는 선택 창의 배치 기준도 남는다). DWM 클로킹도 함께 시도한다.
//
// 위치는 우리 창 가운데다 — 화면 밖으로 보내면 선택 창이 엉뚱한 모니터로 밀린다.
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

// 속성 창이 만들어지는 순간 통지받아 표시되기 전에 지운다.
// EVENT_OBJECT_SHOW 로는 늦다 (이미 화면에 나온 뒤에 온다) — CREATE 부터 받고,
// 셸이 다시 표시하므로 SHOW 에서도 한 번 더 지운다.
procedure SheetShownProc(hHook: THandle; event: DWORD; wnd: HWND;
  idObject, idChild: Longint; idEventThread, dwmsEventTime: DWORD); stdcall;
var
  LClass, LText: array[0..259] of Char;
  LPid: DWORD;
begin
  // 창 자체의 이벤트만 본다 (OBJID_WINDOW = 0)
  if (wnd = 0) or (idObject <> 0) or (idChild <> 0) then
    Exit;

  // 이미 잡은 창이면 다시 지우기만 한다 (셸이 나중에 다시 표시한다).
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

  // 만들어지는 순간에는 제목이 비어 있을 수 있다. 이름이 맞으면 확실하고,
  // 비어 있으면 후보로 본다 (우리 프로세스의 대화상자는 제외).
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

// 확장자 하나의 [기본 앱 선택] 창을 띄운다 (아래 버튼이 [기본값 설정] 인 창).
//
// 이 창을 직접 부르는 공개 API 는 없다. 파일 속성 창을 경유한다:
//   1. 대상 확장자로 빈 임시 파일을 만든다
//   2. 그 파일의 '속성' 창을 띄운다 (셸이 별도 스레드에서 만든다)
//   3. 창을 찾아 투명하게 지운다 (VanishSheet)
//   4. '연결 프로그램 - 변경' 명령(0x3363)을 보낸다 → 선택 창이 뜬다
//
// 3번은 셸이 창을 만들 때까지 기다려야 하므로 그 사이 우리 메시지 루프도 돌린다
// (Application.ProcessMessages).
//
// 선택 창이 닫히는 시점은 알 수 없다. 그래서 속성 창과 임시 파일을 AJob 에 담아
// 돌려주고, 환경설정 창이 다시 활성화될 때 ClosePicker 가 정리한다.
//
// 0x3363 은 비문서화 ID 라 빌드에 따라 달라질 수 있다. 실패하면 False 를
// 돌려주고 호출부가 설정 앱으로 폴백한다.
function ShowDefaultAppPicker(const AExt: string; var AJob: TPickerJob;
  const AAnchor: TPoint): Boolean;
const
  SearchTimeout = 5000;   // 속성 창을 기다리는 한계 (ms)
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

  // 훅을 먼저 건다 (깜빡임을 없애는 핵심). 폴링은 훅이 놓쳤을 때의 보조다.
  LFind.Name := ChangeFileExt(ExtractFileName(AJob.TempFile), '');
  LFind.Found := 0;

  GSheetName := LFind.Name;
  GSheetAnchor := AAnchor;
  GSheetFound := 0;

  // CREATE ~ SHOW 구간을 모두 받는다 (생성 시점에 지워야 깜빡이지 않는다).
  LHook := SetWinEventHook(EVENT_OBJECT_CREATE, EVENT_OBJECT_SHOW, 0,
    @SheetShownProc, 0, 0, WINEVENT_OUTOFCONTEXT);
  try
    FillChar(LExec, SizeOf(LExec), 0);
    LExec.cbSize := SizeOf(LExec);
    LExec.fMask := SEE_MASK_INVOKEIDLIST;
    LExec.lpVerb := 'properties';
    LExec.lpFile := PChar(AJob.TempFile);

    // 숨겨서 띄워 달라고 요청한다 (셸이 무시하면 훅/폴링이 다시 지운다).
    LExec.nShow := SW_HIDE;

    if not ShellExecuteEx(@LExec) then
    begin
      AssocLog(Format('%s: 속성 창 호출 실패 (err=%d)', [AExt, GetLastError]));
      Exit;
    end;

    LDeadline := GetTickCount64 + SearchTimeout;

    while (LFind.Found = 0) and (GSheetFound = 0) and (GetTickCount64 < LDeadline) do
    begin
      // 훅 콜백은 우리 메시지 큐로 온다 — 반드시 큐를 돌려야 불린다.
      Application.ProcessMessages;

      if GSheetFound <> 0 then
        Break;

      EnumWindows(@EnumSheetProc, LPARAM(@LFind));
      Sleep(5);
    end;

    if GSheetFound <> 0 then
    begin
      // 훅이 잡았고 그 자리에서 이미 숨겼다.
      AJob.Sheet := GSheetFound;
      AssocLog(Format('%s: 속성 창 HWND=%x (훅)', [AExt, GSheetFound]));
    end
    else if LFind.Found <> 0 then
    begin
      AJob.Sheet := LFind.Found;
      GSheetFound := LFind.Found;   // 훅도 이 창을 알아야 다시 숨긴다
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

    // 명령을 받은 셸이 속성 창을 다시 표시하므로, 잠깐 메시지를 돌리며 지운다.
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

// 숨겨 둔 속성 창을 닫고 임시 파일을 지운다. 어느 경로로 실패해도 불린다.
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
    // 속성 창이 아직 파일을 붙들고 있을 수 있다. 실패해도 %TEMP% 의 0바이트
    // 파일 하나이므로 로그만 남긴다.
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
      LReg.WriteString('ApplicationDescription', 'libmpv 기반 미디어 플레이어');
    finally
      LReg.CloseKey;
    end;

    // 이게 있어야 윈도우 설정의 '기본 앱' 목록에 KPlayer 가 나타난다.
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

// 확장자 하나를 등록한다. 이미 등록돼 있어도 다시 부를 수 있다
// (SyncFileAssoc 이 exe 경로 갱신 목적으로 그렇게 쓴다).
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
      LReg.WriteString('', AssocExts[AIndex].Desc);
    finally
      LReg.CloseKey;
    end;

    // 확장자별 아이콘이 있으면 그것, 없으면 exe 의 첫 아이콘 (ExtIconRef 참고).
    if LReg.OpenKey(AssocClassKey + LPID + '\DefaultIcon', True) then
    try
      LReg.WriteString('', ExtIconRef(LExt));
    finally
      LReg.CloseKey;
    end;

    // %1 은 반드시 따옴표로 감싼다 — 공백/한글이 든 경로가 조각난다.
    if LReg.OpenKey(AssocClassKey + LPID + '\shell\open\command', True) then
    try
      LReg.WriteString('', '"' + LExe + '" "%1"');
    finally
      LReg.CloseKey;
    end;

    // 탐색기의 '연결 프로그램' 목록에 KPlayer 를 올린다. UserChoice 에 막혀
    // 기본이 되지 못해도 이것이 있어야 사용자가 직접 고를 수 있다.
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

    // 확장자의 기본 클래스. 이것이 없으면 '연결 프로그램' 목록에만 오르고
    // 실제로 더블클릭으로 열리지는 않는다.
    LPrev := '';
    if LReg.OpenKey(AssocClassKey + LExt, True) then
    try
      if LReg.ValueExists('') then
        LPrev := LReg.ReadString('');

      LReg.WriteString('', LPID);
    finally
      LReg.CloseKey;
    end;

    // 등록 전 값을 백업한다. 이미 백업이 있으면 덮어쓰지 않는다 — 재등록 때
    // 덮어쓰면 '원래 값' 이 우리 자신이 되어 되돌릴 곳을 잃는다.
    // 빈 문자열도 유효한 백업이다 ("HKCU 에 원래 값이 없었음").
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

// 해제는 확장자만 있으면 된다 (AssocExts 의 다른 필드를 안 본다). 그래서 노출
// 목록에서 빠진 확장자도 소유 목록에 있으면 지울 수 있다 — 제거 프로그램이
// 이걸로 예전에 등록한 것까지 훑는다.
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

    // 백업을 먼저 읽는다. OpenKeyReadOnly 는 쓰지 않는다 — 성공하면 인스턴스의
    // Access 를 KEY_READ 로 바꿔버려서 이어지는 쓰기가 예외로 죽는다.
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

    // 확장자의 기본 클래스가 아직 우리 것일 때만 손댄다. 그 사이 사용자가 다른
    // 프로그램을 골랐다면 그 선택이 우선이다.
    if LReg.OpenKey(AssocClassKey + LExt, False) then
    try
      if LReg.ValueExists('') and SameText(LReg.ReadString(''), LPID) then
      begin
        if LPrev <> '' then
          LReg.WriteString('', LPrev)
        else
          LReg.DeleteValue('');   // 없던 상태로 — HKLM 연결이 다시 드러난다
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

  // TRegistry.DeleteKey 는 하위 키가 있으면 실패한다 → SHDeleteKey (재귀 삭제)
  SHDeleteKey(HKEY_CURRENT_USER, PChar('Software\Classes\' + LPID));

  SHDeleteValue(HKEY_CURRENT_USER,
    PChar('Software\Classes\' + LExt + '\OpenWithProgIDs'), PChar(LPID));
  SHDeleteValue(HKEY_CURRENT_USER,
    PChar('Software\Classes\Applications\' + ExtractFileName(ParamStr(0)) +
      '\SupportedTypes'), PChar(LExt));
  SHDeleteValue(HKEY_CURRENT_USER,
    PChar('Software\KPlayer\Capabilities\FileAssociations'), PChar(LExt));

  // 기본 앱이 우리였다면 그 지정도 지운다 (삭제는 허용된다 — 해시 보호는
  // 쓰기에만 걸린다). 남기면 연결 없는 기본 앱, 즉 Broken 상태가 된다.
  // 빌드에 따라 살아 있는 키가 달라 새 키와 옛 키를 둘 다 지운다.
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

// 등록해 둔 연결을 전부 되돌리고 우리 흔적을 지운다. 제거 프로그램이
// KPlayer.exe /uninst 로 부른다 — 설치 폴더를 지우기 전에 불러야 한다.
//
// 대상은 AssocExts 가 아니라 소유 목록(AssocOwnedList)이다. 노출 목록에서
// 빠진 확장자를 예전에 등록해 뒀다면 그것도 지워야 한다 — 안 지우면 exe 가
// 사라진 뒤에도 그 확장자의 기본 클래스가 우리 ProgID 를 가리킨 채 남는다.
procedure AssocUnregisterAll;
var
  LExt: string;
begin
  for LExt in AssocOwnedList do
    AssocUnregisterExt(LExt);

  // 남은 우리 키 (백업 목록 자체와 Capabilities). 하위 키가 있으므로 재귀 삭제.
  SHDeleteKey(HKEY_CURRENT_USER, 'Software\KPlayer');

  // '기본 앱' 목록의 등록. 이 값이 남으면 설정 앱에 죽은 항목이 보인다.
  SHDeleteValue(HKEY_CURRENT_USER, 'Software\RegisteredApplications', 'KPlayer');

  SHDeleteKey(HKEY_CURRENT_USER,
    PChar('Software\Classes\Applications\' + ExtractFileName(ParamStr(0))));

  SHChangeNotify(SHCNE_ASSOCCHANGED, SHCNF_IDLIST, nil, nil);
end;

type
  // 기본 앱이 적히는 키를 감시하는 스레드. 정지는 이벤트로 한다 — 짧은
  // 타임아웃으로 도는 방식은 깨어날 때마다 알림을 다시 거는 낭비다.
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
  SetEvent(FStop);   // INFINITE 대기에서 즉시 빠져나오게 한다
end;

procedure TAssocWatcher.Execute;
const
  // 이름/값 변경만 본다. 속성·보안 변경까지 받으면 트리거만 늘어난다.
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

        // Synchronize 가 아니라 Queue 다 — 여기서 기다릴 이유가 없고, 받는
        // 쪽이 타이머로 모아 처리한다.
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
