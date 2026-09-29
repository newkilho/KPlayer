unit Media;

// 지원 확장자 표 + mpv 옵션 값 표. OS 무관 — 파일 연결(Assoc, Windows 전용)과 분리.
// AssocExts = 지원 확장자의 단일 출처. List.AddFile(IsMediaFile) 과 연결 카드가 같이 본다 —
// 두 벌로 갈리면 "연결했는데 목록에 안 들어감" (실제 발생).

{$mode delphi}{$H+}

interface

uses
  SysUtils;

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
  // d3d11 은 Windows 전용 — macOS 이식 시 OS 별 표로 (인덱스 의미가 OS 마다 달라지는 점 주의).
  HwdecValues:     array[0..2] of string = ('auto-safe', 'auto', 'no');
  VoValues:        array[0..1] of string = ('gpu', 'gpu-next');
  GpuApiValues:    array[0..3] of string = ('auto', 'd3d11', 'opengl', 'vulkan');
  ScaleValues:     array[0..3] of string = ('lanczos', 'bilinear', 'spline36', 'ewa_lanczos');
  DeintValues:     array[0..2] of string = ('auto', 'yes', 'no');
  VideoSyncValues: array[0..1] of string = ('display-resample', 'audio');
  ShotFmtValues:   array[0..1] of string = ('jpg', 'png');
  SubAlignValues:  array[0..2] of string = ('left', 'center', 'right');   // sub-align-x
  SubAssValues:    array[0..1] of string = ('force', 'yes');              // sub-ass-override: 0=우리 스타일 강제 1=자막 파일 스타일 우선

  // 음량 평준화 프리셋 (dynaudnorm) — 0:낮게 1:보통 2:강하게
  NormFilters: array[0..2] of string = (
    'lavfi=[dynaudnorm=f=100:g=15:p=0.90:r=0.10:n=1]',
    'lavfi=[dynaudnorm=f=75:g=7:p=0.95:r=0.20:n=1]',
    'lavfi=[dynaudnorm=f=50:g=5:p=0.99:r=0.30:n=1]');

// AssocExts 인덱스, 없으면 -1.
function AssocIndexOf(const AExt: string): Integer;

// 재생 가능 파일 판정. List.AddFile 필터도 이 함수.
function IsMediaFile(const AFileName: string): Boolean;

// 재생목록 파일 (.m3u/.m3u8/.pls) — 목록 추가 시 항목으로 펼쳐야 함.
function IsPlaylistFile(const AFileName: string): Boolean;

// 자연 정렬 — 숫자 구간은 값으로(2화 < 10화), ASCII 대소문자 무시. 탐색기 이름순과 같은 순서.
// StrCmpLogicalW 대신 직접 (macOS 이식 대비). 한글은 UTF-8 바이트순 = 코드포인트순.
function NaturalCompare(const A, B: string): Integer;

// 관련 파일(연속물) 판정 — 확장자 뺀 이름이 처음 갈리는 자리에 숫자가 있으면 관련.
// 드라마 1화/2화, S01E01 Pilot/S01E02 Return, 01 Intro/02 Outro 통과. 영화/영화 2 는 불통과(갈리는 자리 = 공백).
function IsRelatedName(const A, B: string): Boolean;

implementation

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

function NaturalCompare(const A, B: string): Integer;
var
  I, J, SI, SJ, EI, EJ: Integer;
  CA, CB: Char;
begin
  I := 1;
  J := 1;
  while (I <= Length(A)) and (J <= Length(B)) do
  begin
    if (A[I] in ['0'..'9']) and (B[J] in ['0'..'9']) then
    begin
      // 선행 0 제외 자릿수 비교 → 같으면 자리별 (길이 무제한 — 정수 변환 안 함)
      SI := I;
      while (SI <= Length(A)) and (A[SI] = '0') do Inc(SI);
      SJ := J;
      while (SJ <= Length(B)) and (B[SJ] = '0') do Inc(SJ);
      EI := SI;
      while (EI <= Length(A)) and (A[EI] in ['0'..'9']) do Inc(EI);
      EJ := SJ;
      while (EJ <= Length(B)) and (B[EJ] in ['0'..'9']) do Inc(EJ);

      Result := (EI - SI) - (EJ - SJ);
      if Result <> 0 then Exit;
      Result := CompareStr(Copy(A, SI, EI - SI), Copy(B, SJ, EJ - SJ));
      if Result <> 0 then Exit;

      I := EI;
      J := EJ;
    end
    else
    begin
      CA := A[I];
      CB := B[J];
      if CA in ['A'..'Z'] then Inc(CA, 32);
      if CB in ['A'..'Z'] then Inc(CB, 32);
      if CA <> CB then
        Exit(Ord(CA) - Ord(CB));
      Inc(I);
      Inc(J);
    end;
  end;

  Result := (Length(A) - I) - (Length(B) - J);
  if Result = 0 then
    Result := CompareStr(A, B);   // 01 vs 1 등 값 같음 — 순서 고정용
end;

function IsRelatedName(const A, B: string): Boolean;
var
  NA, NB: string;
  I: Integer;
begin
  NA := LowerCase(ChangeFileExt(ExtractFileName(A), ''));
  NB := LowerCase(ChangeFileExt(ExtractFileName(B), ''));
  if NA = NB then
    Exit(True);   // 같은 이름 다른 컨테이너

  I := 1;
  while (I <= Length(NA)) and (I <= Length(NB)) and (NA[I] = NB[I]) do
    Inc(I);

  Result := ((I <= Length(NA)) and (NA[I] in ['0'..'9'])) or
            ((I <= Length(NB)) and (NB[I] in ['0'..'9']));
end;

end.
