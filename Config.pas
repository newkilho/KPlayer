unit Config;

// 설정 INI (Delphi K.Config.INI 이식) + 앱 데이터 위치.
// 파일 = AppDataDir + 'KPlayer.ini', 섹션 [Config]. 키·형식은 Delphi 판 그대로 — 옛 INI 가 그대로 산다.
// 저장 위치는 AppDataDir 한 곳 — Windows = exe 폴더(포터블·설치본 모두 %LOCALAPPDATA%\KPlayer 라 쓰기 가능),
// macOS 이식 시 .app 번들은 서명 후 읽기 전용이라 여기만 ~/Library/Application Support 로 바꾼다.

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils, IniFiles;

const
  // 디버그 빌드 전용 기능 (연결 로그·정보 카드, n:\Release lua) 판정. Delphi 판의 ReportMemoryLeaksOnShutDown 자리.
  IsDebugBuild = {$IFDEF DEBUG}True{$ELSE}False{$ENDIF};

type
  TConfig = class
  private
    FIni: TIniFile;
  public
    function ReadInteger(const Name: string; Default: Integer = -1): Integer;
    function ReadString(const Name: string; const Default: string = ''): string;
    function ReadBoolean(const Name: string; Default: Boolean = False): Boolean;
    function ReadDouble(const Name: string; Default: Double = 0): Double;

    procedure WriteInteger(const Name: string; Value: Integer);
    procedure WriteString(const Name: string; const Value: string);
    procedure WriteBoolean(const Name: string; Value: Boolean);
    procedure WriteDouble(const Name: string; Value: Double);

    constructor Create(const Name: string);
    destructor Destroy; override;
  end;

// 설정·재생목록 폴더 (끝 구분자 포함)
function AppDataDir: string;

// 바이트 → 문자열(UTF-8). BOM 우선 (UTF-8 / UTF-16LE), 없으면 UTF-8 로 유효한지 보고 아니면 OS ANSI 코드페이지.
// .m3u 는 ANSI(CP949) 흔함, Delphi 판 INI 도 ANSI 로 저장됐다.
function DecodeText(const ABytes: TBytes): string;
function ReadTextFile(const AFileName: string): string;

implementation

uses
  LazUTF8, LConvEncoding;

function AppDataDir: string;
begin
  {$IFDEF WINDOWS}
  Result := ExtractFilePath(ParamStr(0));
  {$ELSE}
  Result := IncludeTrailingPathDelimiter(GetAppConfigDir(False));
  ForceDirectories(Result);
  {$ENDIF}
end;

function DecodeText(const ABytes: TBytes): string;
var
  N: Integer;
  S: RawByteString;
  W: UnicodeString;
begin
  Result := '';
  N := Length(ABytes);
  if N = 0 then Exit;

  if (N >= 3) and (ABytes[0] = $EF) and (ABytes[1] = $BB) and (ABytes[2] = $BF) then
  begin
    SetString(S, PAnsiChar(@ABytes[3]), N - 3);
    SetCodePage(S, CP_UTF8, False);
    Exit(string(S));
  end;

  if (N >= 2) and (ABytes[0] = $FF) and (ABytes[1] = $FE) then
  begin
    SetLength(W, (N - 2) div 2);
    if Length(W) > 0 then
      Move(ABytes[2], W[1], Length(W) * 2);
    Exit(UTF8Encode(W));
  end;

  SetString(S, PAnsiChar(@ABytes[0]), N);
  if FindInvalidUTF8Codepoint(PChar(S), Length(S)) < 0 then
  begin
    SetCodePage(S, CP_UTF8, False);
    Result := string(S);
  end
  else
    {$IFDEF WINDOWS}
    Result := WinCPToUTF8(S);   // 시스템 ANSI 코드페이지 (한국어 Windows = CP949)
    {$ELSE}
    Result := ConvertEncoding(S, GetDefaultTextEncoding, EncodingUTF8);
    {$ENDIF}
end;

function ReadTextFile(const AFileName: string): string;
var
  F: TFileStream;
  B: TBytes;
begin
  Result := '';
  F := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone);
  try
    SetLength(B, F.Size);
    if Length(B) > 0 then
      F.ReadBuffer(B[0], Length(B));
  finally
    F.Free;
  end;
  Result := DecodeText(B);
end;

// Delphi 판 TIniFile 은 WritePrivateProfileString → ANSI(CP949) 로 저장. 한글 경로(shot_dir)·글꼴명(sub_font)이
// 들어 있으면 UTF-8 로 읽을 때 깨진다 → 처음 한 번 UTF-8 로 바꿔 다시 쓴다. 이미 UTF-8 이면 손대지 않음.
procedure MigrateToUTF8(const AFileName: string);
var
  F: TFileStream;
  B: TBytes;
  S: RawByteString;
  T: string;
begin
  if not FileExists(AFileName) then Exit;
  try
    F := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone);
    try
      SetLength(B, F.Size);
      if Length(B) > 0 then
        F.ReadBuffer(B[0], Length(B));
    finally
      F.Free;
    end;
    if Length(B) = 0 then Exit;

    SetString(S, PAnsiChar(@B[0]), Length(B));
    if (FindInvalidUTF8Codepoint(PChar(S), Length(S)) < 0) and
       not ((Length(B) >= 2) and (B[0] = $FF) and (B[1] = $FE)) then
      Exit;   // 이미 UTF-8 (ASCII 만인 경우 포함)

    T := DecodeText(B);
    F := TFileStream.Create(AFileName, fmCreate);
    try
      if T <> '' then
        F.WriteBuffer(T[1], Length(T));
    finally
      F.Free;
    end;
  except
    // 읽기 전용 폴더 등 — 변환 실패해도 실행은 계속 (ASCII 키·값은 그대로 읽힌다)
  end;
end;

{ TConfig }

constructor TConfig.Create(const Name: string);
var
  LFile: string;
begin
  LFile := AppDataDir + Name + '.ini';
  MigrateToUTF8(LFile);
  FIni := TIniFile.Create(LFile);
end;

destructor TConfig.Destroy;
begin
  try
    FIni.Free;
  except
    // 종료 중 쓰기 실패로 오류 창 띄우지 않음 (읽기 전용 폴더 실행 사례)
  end;
  inherited;
end;

function TConfig.ReadBoolean(const Name: string; Default: Boolean): Boolean;
begin
  try
    Result := FIni.ReadBool('Config', Name, Default);
  except
    Result := Default;
  end;
end;

function TConfig.ReadDouble(const Name: string; Default: Double): Double;
begin
  try
    Result := FIni.ReadFloat('Config', Name, Default);
  except
    Result := Default;
  end;
end;

function TConfig.ReadInteger(const Name: string; Default: Integer): Integer;
begin
  try
    Result := FIni.ReadInteger('Config', Name, Default);
  except
    Result := Default;
  end;
end;

function TConfig.ReadString(const Name: string; const Default: string): string;
begin
  try
    Result := FIni.ReadString('Config', Name, Default);
  except
    Result := Default;
  end;
end;

procedure TConfig.WriteBoolean(const Name: string; Value: Boolean);
begin
  try
    FIni.WriteBool('Config', Name, Value);
  except
  end;
end;

procedure TConfig.WriteDouble(const Name: string; Value: Double);
begin
  try
    FIni.WriteFloat('Config', Name, Value);
  except
  end;
end;

procedure TConfig.WriteInteger(const Name: string; Value: Integer);
begin
  try
    FIni.WriteInteger('Config', Name, Value);
  except
  end;
end;

procedure TConfig.WriteString(const Name: string; const Value: string);
begin
  try
    FIni.WriteString('Config', Name, Value);
  except
  end;
end;

end.
