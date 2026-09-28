unit Assoc;

// 파일 연결 (Windows 레지스트리). 확장자 표는 Media.pas.
// 인터페이스는 OS 무관 — 비-Windows 는 아래 {$ELSE} 의 빈 구현 (macOS 이식 때 채울 자리).
// Win32 호출은 전부 W 판 명시 — FPC windows 유닛의 접미사 없는 이름은 A(ANSI) 판이라 한글 경로가 깨진다.

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils, Types, Media;

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
  //   Sheet    - 투명화해 둔 파일 속성 창 (HWND)
  //   TempFile - 속성 창용 빈 임시 파일
  TPickerJob = record
    Sheet: THandle;
    TempFile: string;
  end;

  TAssocChangeProc = procedure of object;
  TAssocLogProc = procedure(const AMsg: string) of object;

// 등록된 연결을 현재 exe 경로로 재기록 (시작 시 1회) — 포터블, 폴더 이동 시 실행 명령 어긋남.
procedure SyncFileAssoc;

// 상태
function ExtProgID(const AExt: string): string;
function AssocStateOf(const AExt: string): TAssocState;
function AssocOwned(const AExt: string): Boolean;
function AssocOwnedList: TStringDynArray;

// 사용자 직접 조작 필요 상태 = UI [적용안됨] 뱃지 조건. 등록(체크)한 확장자만 알림.
function AssocNeedsUser(const AState: TAssocState): Boolean;

// 판정 근거 텍스트 — 레지스트리 값과 실제 동작이 어긋날 때 갈라진 지점 확인용.
function AssocResolveInfo(const AExt: string): string;

// 실행 환경 한 줄 (계정/승격/HKCU 하이브). 우리 HKCU ≠ 탐색기 하이브면 값은 맞는데 동작이 다름.
function AssocEnvInfo: string;

// 등록
procedure AssocRegister(const AIndex: Integer);
procedure AssocUnregister(const AIndex: Integer);
procedure EnsureAppRegistered;

// 주요 확장자(Main) 일괄 등록 — 인스톨러가 [Run] 의 /inst 로 호출 (Main.FormCreate). 환경설정 [주요 파일] 과 같은 집합.
procedure AssocRegisterMain;

// 등록한 연결 전부 복원 (제거 프로그램이 /uninst 로 호출).
procedure AssocUnregisterAll;

// 탐색기에 연결 변경 알림
procedure AssocNotifyShell;

// 기본 앱 선택
function ShowDefaultAppPicker(const AExt: string; var AJob: TPickerJob;
  const AAnchor: TPoint): Boolean;
procedure ClosePickerJob(var AJob: TPickerJob);
procedure ShowDefaultApps(AHandle: THandle; AOurPage: Boolean);

// 감시. FileExts 변경 시 AOnChange 를 메인 스레드로. 알림 몰림 — 수신측
// 디바운스 필요. 평시 이벤트 대기.
function AssocWatch(AOnChange: TAssocChangeProc): TThread;
procedure AssocUnwatch(var AThread: TThread);

// 로그. 환경설정 창이 자기 메모를 걺 (미설정 시 no-op).
var
  AssocLogProc: TAssocLogProc = nil;

procedure AssocLog(const AMsg: string);

implementation

{$IFDEF WINDOWS}
uses
  Windows, Messages, ShellApi, ShlObj, Registry, Forms, KTranslate;
{$ENDIF}

procedure AssocLog(const AMsg: string);
begin
  // 창 없을 때도 불림
  if Assigned(AssocLogProc) then
    AssocLogProc(AMsg);
end;

function ExtProgID(const AExt: string): string;
begin
  Result := 'KPlayer' + AExt;   // '.mp4' -> 'KPlayer.mp4'
end;

function AssocNeedsUser(const AState: TAssocState): Boolean;
begin
  // 미등록 확장자는 남이 쥐어도 안 알림 (사용자가 원한 적 없음).
  // Broken 만 등록 무관 알림 — 아무것도 안 열리는 상태라서.
  Result := AState.Broken or (AState.Registered and (AState.Other <> ''));
end;

{$IFDEF WINDOWS}

// FPC windows 유닛에 없거나 A 판만 있는 것
const
  EVENT_OBJECT_CREATE    = $8000;
  EVENT_OBJECT_SHOW      = $8002;
  WINEVENT_OUTOFCONTEXT  = $0000;
  DWMWA_CLOAK            = 13;
  LWA_ALPHA_             = $00000002;
  WS_EX_LAYERED_         = $00080000;
  TokenElevationClass    = 20;
  REG_NOTIFY_CHANGE_NAME_     = $00000001;
  REG_NOTIFY_CHANGE_LAST_SET_ = $00000004;

type
  TWinEventProc = procedure(hWinEventHook: THandle; event: DWORD; hwnd: HWND;
    idObject, idChild: LONG; idEventThread, dwmsEventTime: DWORD); stdcall;

  TTokenElevationRec = record
    TokenIsElevated: DWORD;
  end;

  TSidAndAttributesRec = record
    Sid: Pointer;
    Attributes: DWORD;
  end;
  PTokenUserRec = ^TTokenUserRec;
  TTokenUserRec = record
    User: TSidAndAttributesRec;
  end;

function SetWinEventHook(eventMin, eventMax: DWORD; hmodWinEventProc: HMODULE;
  pfnWinEventProc: TWinEventProc; idProcess, idThread, dwFlags: DWORD): THandle;
  stdcall; external 'user32.dll' name 'SetWinEventHook';
function UnhookWinEvent(hWinEventHook: THandle): BOOL; stdcall;
  external 'user32.dll' name 'UnhookWinEvent';
function SetLayeredWindowAttributes_(hwnd: HWND; crKey: COLORREF; bAlpha: Byte;
  dwFlags: DWORD): BOOL; stdcall; external 'user32.dll' name 'SetLayeredWindowAttributes';
function DwmSetWindowAttribute(hwnd: HWND; dwAttribute: DWORD; pvAttribute: Pointer;
  cbAttribute: DWORD): HRESULT; stdcall; external 'dwmapi.dll' name 'DwmSetWindowAttribute';
function SHDeleteKeyW(hkey: HKEY; pszSubKey: PWideChar): LONG; stdcall;
  external 'shlwapi.dll' name 'SHDeleteKeyW';
function SHDeleteValueW(hkey: HKEY; pszSubKey, pszValue: PWideChar): LONG; stdcall;
  external 'shlwapi.dll' name 'SHDeleteValueW';
function ConvertSidToStringSidW(Sid: Pointer; var StringSid: PWideChar): BOOL; stdcall;
  external 'advapi32.dll' name 'ConvertSidToStringSidW';
function GetUserNameW_(lpBuffer: PWideChar; var nSize: DWORD): BOOL; stdcall;
  external 'advapi32.dll' name 'GetUserNameW';

// 파일 속성 창 '연결 프로그램 - 변경' 명령 ID (비문서화) — 확장자별
// [기본 앱 선택] 창을 띄움 (ShowDefaultAppPicker 참고).
const
  IDM_CHANGE_ASSOC = $3363;

// 'ProgID|exe' → 표시용 프로그램 이름 (FriendlyProgramName 이 채움).
// 첫 사용 시 생성, finalization 에서 해제. 이름=값 목록 (정렬·대소문자 무시).
var
  FriendlyCache: TStringList = nil;

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
  FileExtsKey    = 'Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\';

// 확장자별 아이콘 = exe 리소스 (KPlayerIcons.res, Tools\MakeIconRes.py 생성). IconIds 표.
{$I IconIds.inc}

function W(const S: string): UnicodeString; inline;
begin
  Result := UTF8Decode(S);
end;

function U(const S: UnicodeString): string; inline;
begin
  Result := UTF8Encode(S);
end;

function ExePath: string;
begin
  Result := ParamStr(0);
end;

// DefaultIcon 문자열 — "<exe>",-<RT_GROUP_ICON ID> (음수 = 리소스 ID, ZipMania 동일), 표에 없으면
// exe 첫 아이콘(",0"). .rc 로 넣으면 RT_ICON 이 1부터 매겨져 프로젝트 .res 의 MAINICON 과 충돌
// → 링커가 한쪽 폐기. 그래서 Tools\MakeIconRes.py 가 RT_ICON 1000+/그룹 40000+ 로 .res 를 직접 쓴다.
// 경로 캐시 안 함 (의도) — 포터블이라 폴더가 바뀜, SyncFileAssoc 의 AssocRegister 재호출이 새로 만듦.
function ExtIconRef(const AExt: string): string;
var
  LExe, LStem: string;
  I: Integer;
begin
  LExe := ExePath;
  LStem := Copy(AExt, 2, MaxInt);   // '.mp4' -> 'mp4'
  for I := Low(IconIds) to High(IconIds) do
    if SameText(IconIds[I].Ext, LStem) then
      Exit('"' + LExe + '",-' + IntToStr(IconIds[I].Id));
  Result := '"' + LExe + '",0';
end;

// 레지스트리 문자열 (없으면 ''). 값 이름 '' = 기본값.
function RegStr(ARoot: HKEY; const AKey, AValue: string): string;
var
  LKey: HKEY;
  LBuf: array[0..511] of WideChar;
  LSize, LType: DWORD;
begin
  Result := '';

  if RegOpenKeyExW(ARoot, PWideChar(W(AKey)), 0, KEY_READ, LKey) <> ERROR_SUCCESS then
    Exit;
  try
    FillChar(LBuf, SizeOf(LBuf), 0);
    LSize := SizeOf(LBuf) - SizeOf(WideChar);   // 끝 #0 자리 보장
    if (RegQueryValueExW(LKey, PWideChar(W(AValue)), nil, @LType, PByte(@LBuf[0]),
          @LSize) = ERROR_SUCCESS) and (LType = REG_SZ) then
      Result := U(PWideChar(@LBuf[0]));
  finally
    RegCloseKey(LKey);
  end;
end;

function RegHasKey(ARoot: HKEY; const AKey: string): Boolean;
var
  LKey: HKEY;
begin
  Result := RegOpenKeyExW(ARoot, PWideChar(W(AKey)), 0, KEY_READ, LKey) = ERROR_SUCCESS;
  if Result then
    RegCloseKey(LKey);
end;

procedure RegDeleteKeyTree(const ASubKey: string);
begin
  SHDeleteKeyW(HKEY_CURRENT_USER, PWideChar(W(ASubKey)));
end;

procedure RegDeleteValueAt(const ASubKey, AValue: string);
begin
  SHDeleteValueW(HKEY_CURRENT_USER, PWideChar(W(ASubKey)), PWideChar(W(AValue)));
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
begin
  Result := RegStr(HKEY_CURRENT_USER, FileExtsKey + AExt + '\UserChoiceLatest\ProgId',
    'ProgId');

  if Result = '' then
    Result := RegStr(HKEY_CURRENT_USER, FileExtsKey + AExt + '\UserChoiceLatest', 'ProgId');

  if Result = '' then
    Result := RegStr(HKEY_CURRENT_USER, FileExtsKey + AExt + '\UserChoice', 'ProgId');
end;

// 마지막으로 이 확장자를 연 exe 이름 (없으면 ''). UserChoice 없어도 이 이력이
// 클래스 연결을 이김 — 필수 확인. MRUList 첫 글자가 가리키는 값 = 현재 승자.
function OpenWithMruExe(const AExt: string): string;
var
  LKey, LMru: string;
begin
  Result := '';

  LKey := FileExtsKey + AExt + '\OpenWithList';
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
  LBuf: array of Byte;
  LPtr: Pointer;
  LLangs: array[0..2] of string;
  LFile: UnicodeString;
  I, J: Integer;
begin
  Result := '';

  if (AExeFile = '') or not FileExists(AExeFile) then
    Exit;

  LFile := W(AExeFile);
  LHandle := 0;
  LSize := GetFileVersionInfoSizeW(PWideChar(LFile), LHandle);
  if LSize = 0 then
    Exit;

  SetLength(LBuf, LSize);
  if not GetFileVersionInfoW(PWideChar(LFile), 0, LSize, @LBuf[0]) then
    Exit;

  // 언어/코드페이지: 파일 제공값 먼저, 없으면 흔한 값 시도.
  LLangs[0] := '';
  LPtr := nil;
  LLen := 0;
  if VerQueryValueW(@LBuf[0], PWideChar(UnicodeString('\VarFileInfo\Translation')), LPtr, LLen) and
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
    begin
      LPtr := nil;
      LLen := 0;
      if VerQueryValueW(@LBuf[0],
           PWideChar(W('\StringFileInfo\' + LLangs[I] + '\' + Names[J])),
           LPtr, LLen) and (LLen > 0) then
      begin
        Result := Trim(U(PWideChar(LPtr)));
        if Result <> '' then
          Exit;
      end;
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
  LIdx: Integer;
begin
  LKey := AProgID + '|' + AExe;

  if FriendlyCache = nil then
  begin
    FriendlyCache := TStringList.Create;
    FriendlyCache.Sorted := True;
    FriendlyCache.CaseSensitive := False;
  end;

  LIdx := FriendlyCache.IndexOfName(LKey);
  if LIdx >= 0 then
    Exit(FriendlyCache.ValueFromIndex[LIdx]);

  Result := FriendlyProgramNameRaw(AProgID, AExe);
  FriendlyCache.Add(LKey + '=' + Result);
end;

// 우리가 등록한 확장자인가 (= 백업 목록 존재). 백업 없이 등록한 구버전 대비
// ProgID 키 존재도 확인.
function AssocOwned(const AExt: string): Boolean;
var
  LKey: HKEY;
begin
  Result := False;

  if RegOpenKeyExW(HKEY_CURRENT_USER, PWideChar(UnicodeString('Software\KPlayer\FileAssoc')), 0,
       KEY_READ, LKey) = ERROR_SUCCESS then
  try
    Result := RegQueryValueExW(LKey, PWideChar(W(AExt)), nil, nil, nil, nil) = ERROR_SUCCESS;
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
    Result.Ours := SameText(ExtractFileName(LExe), ExtractFileName(ExePath));

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

// 판정 근거 원본 표시 — 어느 값에서 갈라지는지 확인용.
function AssocResolveInfo(const AExt: string): string;
var
  LPID, LEffective, LCmd: string;
begin
  LPID := ExtProgID(AExt);

  Result := 'UserChoiceLatest: ' + RegStr(HKEY_CURRENT_USER,
      FileExtsKey + AExt + '\UserChoiceLatest\ProgId', 'ProgId') + LineEnding +
    'UserChoice: ' + RegStr(HKEY_CURRENT_USER,
      FileExtsKey + AExt + '\UserChoice', 'ProgId') + LineEnding +
    // 사용 이력 — 이 줄 없으면 갈린 단계 추적 불가.
    'OpenWithList MRU: ' + OpenWithMruExe(AExt) + LineEnding +
    'HKCU\Classes: ' + RegStr(HKEY_CURRENT_USER, 'Software\Classes\' + AExt, '') +
    LineEnding +
    'HKCR: ' + RegStr(HKEY_CLASSES_ROOT, AExt, '');

  // 실제 실행 명령까지 추적 (셸 캐시 미경유).
  LEffective := UserChoiceProgID(AExt);
  if LEffective = '' then
    LEffective := ClassProgID(AExt);

  if LEffective <> '' then
  begin
    LCmd := RegStr(HKEY_CLASSES_ROOT, LEffective + '\shell\open\command', '');
    Result := Result + LineEnding + '실행: ' + LCmd;
  end;

  Result := Result + LineEnding + '우리 ProgID: ' + LPID;
end;

function AssocEnvInfo: string;
var
  LName: array[0..255] of WideChar;
  LSize: DWORD;
  LToken: THandle;
  LElev: TTokenElevationRec;
  LRet: DWORD;
  LUser, LSid: string;
  LStr: PWideChar;
  LBuf: array[0..255] of Byte;
begin
  LUser := '?';
  LSize := Length(LName);
  if GetUserNameW_(@LName[0], LSize) then
    LUser := U(PWideChar(@LName[0]));

  LSid := '?';
  Result := '';

  LToken := 0;
  if OpenProcessToken(GetCurrentProcess, TOKEN_QUERY, LToken) then
  try
    // 승격 여부 — 승격 프로세스는 다른 하이브를 봄
    LRet := 0;
    if GetTokenInformation(LToken, TTokenInformationClass(TokenElevationClass), @LElev,
         SizeOf(LElev), LRet) then
      Result := '상승=' + BoolToStr(LElev.TokenIsElevated <> 0, True);

    LStr := nil;
    if GetTokenInformation(LToken, TokenUser, @LBuf[0], SizeOf(LBuf), LRet) and
       ConvertSidToStringSidW(PTokenUserRec(@LBuf[0])^.User.Sid, LStr) then
    try
      LSid := U(LStr);
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
function AssocOwnedList: TStringDynArray;
var
  LReg: TRegistry;
  LNames: TStringList;
  I, N: Integer;
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
        SetLength(Result, LNames.Count);
        N := 0;
        for I := 0 to LNames.Count - 1 do
          if LNames[I] <> '' then
          begin
            Result[N] := LNames[I];
            Inc(N);
          end;
        SetLength(Result, N);
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

procedure AssocNotifyShell;
begin
  SHChangeNotify(SHCNE_ASSOCCHANGED, SHCNF_IDLIST, nil, nil);
end;

// 설정 앱 기본 앱 화면 (선택 창 실패 시 최후 수단).
// SHOpenWithDialog 불가 — Win10 부터 등록 기능 제거, 플래그 무관 [한 번만]
// 창만 뜸 (탐색기 'openas' 동사도 동일).
// AOurPage=True = 우리 앱 페이지 직행. registeredAppUser = RegisteredApplications
// 값 이름. 페이지엔 Capabilities 등록 확장자가 각각 [기본값 설정] 과 나열.
// 확장자 단위 직행 파라미터 없음 — 쿼리 모르는 빌드는 그냥 목록.
procedure ShowDefaultApps(AHandle: THandle; AOurPage: Boolean);
const
  Uri: array[Boolean] of UnicodeString = (
    'ms-settings:defaultapps',
    'ms-settings:defaultapps?registeredAppUser=KPlayer');
begin
  ShellExecuteW(AHandle, 'open', PWideChar(Uri[AOurPage]), nil, nil, SW_SHOWNORMAL);
end;

type
  PFindSheet = ^TFindSheet;
  TFindSheet = record
    Name: UnicodeString;   // 찾을 임시 파일명 (창 제목 = '<파일명> 속성'), 소문자
    Found: HWND;
  end;

function WinClassIs(AWnd: HWND; const AClass: UnicodeString): Boolean;
var
  LClass: array[0..259] of WideChar;
begin
  Result := (GetClassNameW(AWnd, @LClass[0], Length(LClass)) > 0) and
    (WideCompareText(UnicodeString(PWideChar(@LClass[0])), AClass) = 0);
end;

// 제목 소문자 ('' = 제목 없음)
function WinTitleLower(AWnd: HWND): UnicodeString;
var
  LText: array[0..259] of WideChar;
begin
  if GetWindowTextW(AWnd, @LText[0], Length(LText)) > 0 then
    Result := WideLowerCase(UnicodeString(PWideChar(@LText[0])))
  else
    Result := '';
end;

// 제목에 이름이 든 대화상자(#32770) 검색. 프로세스 불문 — 셸이 타 프로세스에서
// 띄우기도 해 PID 필터로는 못 찾음. 비교는 확장자 뗀 이름
// ('확장명 숨기기' 켜지면 제목에 없음).
function EnumSheetProc(AWnd: HWND; AParam: LPARAM): BOOL; stdcall;
var
  LInfo: PFindSheet;
  LTitle: UnicodeString;
begin
  Result := True;   // 계속
  LInfo := PFindSheet(AParam);

  if not WinClassIs(AWnd, '#32770') then
    Exit;

  LTitle := WinTitleLower(AWnd);
  if (LTitle = '') or (Pos(LInfo^.Name, LTitle) = 0) then
    Exit;

  LInfo^.Found := AWnd;
  Result := False;  // 찾았다
end;

var
  // 속성 창을 뜨는 순간 잡는 훅 상태. 콜백에 인자 못 넘겨 유닛 변수
  // (선택 창은 동시 1개).
  GSheetName: UnicodeString;
  GSheetAnchor: TPoint;
  GSheetFound: HWND = 0;

// 속성 창 소거. SW_HIDE 금지 — 셸이 곧 재표시하며 깜빡임. 알파 0 투명화로
// 표시 상태 유지 (뒤에 뜨는 선택 창의 배치 기준 보존). DWM 클로킹 병행.
// 위치는 우리 창 가운데 — 화면 밖으로 보내면 선택 창이 엉뚱한 모니터로 밀림.
procedure VanishSheet(AWnd: HWND; const AAnchor: TPoint);
var
  LCloak: BOOL;
begin
  SetWindowLongPtrW(AWnd, GWL_EXSTYLE,
    GetWindowLongPtrW(AWnd, GWL_EXSTYLE) or WS_EX_LAYERED_);
  SetLayeredWindowAttributes_(AWnd, 0, 0, LWA_ALPHA_);

  LCloak := True;
  DwmSetWindowAttribute(AWnd, DWMWA_CLOAK, @LCloak, SizeOf(LCloak));

  MoveWindow(AWnd, AAnchor.X, AAnchor.Y, 0, 0, False);
end;

// 속성 창 생성 순간 통지받아 표시 전 소거. EVENT_OBJECT_SHOW 는 늦음
// (이미 표시 후) — CREATE 부터 받고, 셸 재표시 대비 SHOW 에서도 재소거.
procedure SheetShownProc(hWinEventHook: THandle; event: DWORD; wnd: HWND;
  idObject, idChild: LONG; idEventThread, dwmsEventTime: DWORD); stdcall;
var
  LTitle: UnicodeString;
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

  if not WinClassIs(wnd, '#32770') then
    Exit;

  // 생성 직후엔 제목이 빌 수 있음 — 이름 일치 = 확정, 빈 제목 = 후보
  // (우리 프로세스 대화상자 제외).
  LTitle := WinTitleLower(wnd);
  if LTitle <> '' then
  begin
    if Pos(GSheetName, LTitle) = 0 then
      Exit;
  end
  else
  begin
    LPid := 0;
    GetWindowThreadProcessId(wnd, @LPid);
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
  LExec: TShellExecuteInfoW;
  LFind: TFindSheet;
  LHandle: THandle;
  LHook: THandle;
  LDeadline: QWord;
  LFile: UnicodeString;
begin
  Result := False;

  AJob.Sheet := 0;
  AJob.TempFile := IncludeTrailingPathDelimiter(GetTempDir(False)) +
    Format('KPlayer-assoc-%u%s', [GetTickCount64, AExt]);

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
  LFind.Name := WideLowerCase(W(ChangeFileExt(ExtractFileName(AJob.TempFile), '')));
  LFind.Found := 0;

  GSheetName := LFind.Name;
  GSheetAnchor := AAnchor;
  GSheetFound := 0;

  LFile := W(AJob.TempFile);

  // CREATE~SHOW 전부 수신 — 생성 시점에 지워야 안 깜빡임.
  LHook := SetWinEventHook(EVENT_OBJECT_CREATE, EVENT_OBJECT_SHOW, 0,
    @SheetShownProc, 0, 0, WINEVENT_OUTOFCONTEXT);
  try
    FillChar(LExec, SizeOf(LExec), 0);
    LExec.cbSize := SizeOf(LExec);
    LExec.fMask := SEE_MASK_INVOKEIDLIST;
    LExec.lpVerb := 'properties';
    LExec.lpFile := PWideChar(LFile);

    // 숨김 표시 요청 (셸이 무시하면 훅/폴링이 소거).
    LExec.nShow := SW_HIDE;

    if not ShellExecuteExW(@LExec) then
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
      AssocLog(Format('%s: 속성 창 HWND=%x (훅)', [AExt, PtrUInt(GSheetFound)]));
    end
    else if LFind.Found <> 0 then
    begin
      AJob.Sheet := LFind.Found;
      GSheetFound := LFind.Found;   // 훅도 알아야 재소거함
      AssocLog(Format('%s: 속성 창 HWND=%x (폴링)', [AExt, PtrUInt(LFind.Found)]));
      VanishSheet(AJob.Sheet, AAnchor);
    end
    else
    begin
      AssocLog(Format('%s: 속성 창을 찾지 못했다 (%dms 초과, 찾던 이름 "%s")',
        [AExt, SearchTimeout, U(LFind.Name)]));
      Exit;
    end;

    Result := PostMessageW(AJob.Sheet, WM_COMMAND, IDM_CHANGE_ASSOC, 0);
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
      PostMessageW(AJob.Sheet, WM_CLOSE, 0, 0);
    AJob.Sheet := 0;
  end;

  if AJob.TempFile <> '' then
  begin
    // 속성 창이 아직 파일을 붙들 수 있음 — 실패해도 %TEMP% 0바이트라 로그만.
    if not SysUtils.DeleteFile(AJob.TempFile) then
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
  LExe := ExePath;

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
  LExe := ExePath;

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

    // 확장자별 리소스 아이콘, 없으면 exe 첫 아이콘 (ExtIconRef).
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
      RegDeleteValueAt(Copy(AssocBackupKey, 2, MaxInt), LExt);
  finally
    LReg.Free;
  end;

  // TRegistry.DeleteKey 는 하위 키 있으면 실패 → SHDeleteKey (재귀 삭제)
  RegDeleteKeyTree('Software\Classes\' + LPID);

  RegDeleteValueAt('Software\Classes\' + LExt + '\OpenWithProgIDs', LPID);
  RegDeleteValueAt('Software\Classes\Applications\' + ExtractFileName(ExePath) +
    '\SupportedTypes', LExt);
  RegDeleteValueAt('Software\KPlayer\Capabilities\FileAssociations', LExt);

  // 기본 앱=우리면 지정도 삭제 (삭제는 허용 — 해시 보호는 쓰기만). 남기면
  // 연결 없는 기본 앱 = Broken. 빌드별 활성 키가 달라 새/옛 키 둘 다 삭제.
  if SameText(UserChoiceProgID(LExt), LPID) then
  begin
    RegDeleteKeyTree(FileExtsKey + LExt + '\UserChoiceLatest');
    RegDeleteKeyTree(FileExtsKey + LExt + '\UserChoice');
  end;
end;

procedure AssocUnregister(const AIndex: Integer);
begin
  AssocUnregisterExt(AssocExts[AIndex].Ext);
end;

procedure AssocRegisterMain;
var
  I: Integer;
begin
  for I := Low(AssocExts) to High(AssocExts) do
    if AssocExts[I].Main then
      AssocRegister(I);
  EnsureAppRegistered;
  AssocNotifyShell;
end;

// 등록 연결 전부 복원 + 우리 흔적 삭제. 제거 프로그램이 KPlayer.exe /uninst
// 로 호출 — 설치 폴더 삭제 전이어야 함.
// 대상은 AssocExts 아닌 소유 목록(AssocOwnedList) — 노출 목록에서 뺀 확장자가
// 남으면 exe 삭제 후에도 기본 클래스가 우리 ProgID 를 가리킴.
procedure AssocUnregisterAll;
var
  LExts: TStringDynArray;
  I: Integer;
begin
  LExts := AssocOwnedList;
  for I := 0 to High(LExts) do
    AssocUnregisterExt(LExts[I]);

  // 잔여 키 (백업 목록 자체 + Capabilities). 하위 키 있어 재귀 삭제.
  RegDeleteKeyTree('Software\KPlayer');

  // '기본 앱' 등록 값 — 남으면 설정 앱에 죽은 항목 보임.
  RegDeleteValueAt('Software\RegisteredApplications', 'KPlayer');

  RegDeleteKeyTree('Software\Classes\Applications\' + ExtractFileName(ExePath));

  AssocNotifyShell;
end;

type
  // 기본 앱 키 감시 스레드. 정지는 이벤트 — 짧은 타임아웃 폴링은 깰 때마다
  // 알림 재등록하는 낭비.
  TAssocWatcher = class(TThread)
  private
    FStop: THandle;
    FOnChange: TAssocChangeProc;
    procedure DoChange;
  protected
    procedure Execute; override;
  public
    constructor Create(AOnChange: TAssocChangeProc);
    destructor Destroy; override;
    procedure Stop;
  end;

constructor TAssocWatcher.Create(AOnChange: TAssocChangeProc);
begin
  FOnChange := AOnChange;
  FStop := CreateEventW(nil, True, False, nil);   // 수동 리셋

  FreeOnTerminate := False;
  inherited Create(False);
end;

destructor TAssocWatcher.Destroy;
begin
  inherited;
  CloseHandle(FStop);
end;

// Terminate + 정지 이벤트 (INFINITE 대기 즉시 탈출)
procedure TAssocWatcher.Stop;
begin
  Terminate;
  SetEvent(FStop);
end;

procedure TAssocWatcher.DoChange;
begin
  if Assigned(FOnChange) then
    FOnChange();
end;

procedure TAssocWatcher.Execute;
const
  // 이름/값 변경만 — 속성·보안까지 받으면 트리거만 증가.
  Filter = REG_NOTIFY_CHANGE_NAME_ or REG_NOTIFY_CHANGE_LAST_SET_;
var
  LKey: HKEY;
  LEvent: THandle;
  LWait: array[0..1] of THandle;
begin
  if RegOpenKeyExW(HKEY_CURRENT_USER,
       PWideChar(UnicodeString('Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts')), 0,
       KEY_NOTIFY, LKey) <> ERROR_SUCCESS then
    Exit;
  try
    LEvent := CreateEventW(nil, True, False, nil);
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
        // 스레드 해제 시 TThread 가 남은 큐 항목을 걷어낸다 (RemoveQueuedEvents).
        Queue(DoChange);
      end;
    finally
      CloseHandle(LEvent);
    end;
  finally
    RegCloseKey(LKey);
  end;
end;

function AssocWatch(AOnChange: TAssocChangeProc): TThread;
begin
  Result := TAssocWatcher.Create(AOnChange);
end;

procedure AssocUnwatch(var AThread: TThread);
begin
  if AThread = nil then
    Exit;

  TAssocWatcher(AThread).Stop;
  AThread.WaitFor;
  FreeAndNil(AThread);
end;

procedure SyncFileAssoc;
var
  LExts: TStringDynArray;
  I, LIndex, LCount: Integer;
begin
  LExts := AssocOwnedList;
  if Length(LExts) = 0 then
    Exit;

  LCount := 0;

  for I := 0 to High(LExts) do
  begin
    // 노출 목록에서 빠진 확장자는 설명 정보가 없어 다시 쓸 수 없다.
    // 해제는 환경설정 화면에서만 한다 (여기서 조용히 지우면 사용자가 모른다).
    LIndex := AssocIndexOf(LExts[I]);
    if LIndex < 0 then
      Continue;

    AssocRegister(LIndex);   // exe 경로가 바뀌었어도 이 호출로 갱신된다
    Inc(LCount);
  end;

  if LCount > 0 then
  begin
    EnsureAppRegistered;
    AssocNotifyShell;
  end;
end;

initialization

finalization
  FriendlyCache.Free;   // nil 이어도 안전하다

{$ELSE}

// 비-Windows: 파일 연결 미구현 (macOS 는 Info.plist + NSWorkspace 로 이식 예정)

procedure SyncFileAssoc; begin end;
function AssocStateOf(const AExt: string): TAssocState; begin Result := Default(TAssocState); end;
function AssocOwned(const AExt: string): Boolean; begin Result := False; end;
function AssocOwnedList: TStringDynArray; begin Result := nil; end;
function AssocResolveInfo(const AExt: string): string; begin Result := ''; end;
function AssocEnvInfo: string; begin Result := ''; end;
procedure AssocRegister(const AIndex: Integer); begin end;
procedure AssocUnregister(const AIndex: Integer); begin end;
procedure EnsureAppRegistered; begin end;
procedure AssocRegisterMain; begin end;
procedure AssocUnregisterAll; begin end;
procedure AssocNotifyShell; begin end;
function ShowDefaultAppPicker(const AExt: string; var AJob: TPickerJob;
  const AAnchor: TPoint): Boolean; begin Result := False; end;
procedure ClosePickerJob(var AJob: TPickerJob); begin AJob.Sheet := 0; AJob.TempFile := ''; end;
procedure ShowDefaultApps(AHandle: THandle; AOurPage: Boolean); begin end;
function AssocWatch(AOnChange: TAssocChangeProc): TThread; begin Result := nil; end;
procedure AssocUnwatch(var AThread: TThread); begin AThread := nil; end;

{$ENDIF}

end.
