unit Utilits;

interface

uses Classes, SysUtils, DBGrids, Db, Val2Rus, Forms, Windows;

const
  plFatalError   = 1;
  plError        = 2;
  plWarning      = 3;
  plInfo         = 4;
  plTrace        = 5;
const
  ListDivider = '#';

function AppDir: TFileName;
function BaseDir: TFileName;
function ModuleDir: TFileName;
function PostDir: TFileName;
function HelpDir: TFileName;
function KeyDir: TFileName;
function PatternDir: TFileName;
function TempDir: TFileName;

procedure DosToWin(Src: PChar);
procedure WinToDos(Src: PChar);
procedure DosToWinL(Src: PChar; Len: Integer);
procedure WinToDosL(Src: PChar; Len: Integer);
function WinToDosS(Strng: string): string;         //Добавлено Меркуловым
function DosToWinS(Strng: string): string;         //Добавлено Меркуловым
function FillZeros(V,L: Integer): string; // Число V=1 возвращает 0001 при L=4

procedure DecodeBtrDate(ADate: Word; var Year, Month, Day: Word);
function BtrDateToStr(ADate: Word): string;
function CodeBtrDate(Year, Month, Day: Word): Word;
function StrToBtrDate(ADate: string): Word;
function BtrDateToDate(ABtrDate: Word): TDateTime;
function DateToBtrDate(ADate: TDateTime): Word;
function EncodeDosDate(Year, Month, Day: Word): Integer;
function DateToDosDate(ADate: TDateTime): Integer;
function DosDateToDate(DosDate: Integer): TDateTime;        //Добавлено Меркуловым
procedure DecodeDosDate(ADate: Integer; var Year, Month, Day: Word);
function BtrDateToDosDate(BtrDate: Word): Integer;
function DosDateToBtrDate(DosDate: Integer): Word;
function DosDateToStr(DosDate: Integer): string;
function DosDateToOrStr(DosDate: Integer): string;          //Добавлено Меркуловым
function TimeToWord(Hour, Min: word): word;
procedure WordToTime(Time: word; var Hour, Min: word);
function EncodeBtrTime(Hour, Min: Word): Word;
procedure DecodeBtrTime(Time: word; var Hour, Min: Word);
function TimeToBtrTime(Time: TDateTime): Word;
function BtrTimeToTime(Time: Word): TDateTime;
function BtrTimeToStr(Time: Word): string;

procedure TakeZeroOffset(Buffer: PChar; var ZeroPos, OffSet: Integer);
procedure SetVarior(AName, AValue: string);
function GetVarior(AName: string): string;
function SumToStr(ASum: Comp): string;
function SumToRus(Sum: comp): string;
function RusUpCase(K: Char): Char;
function RusUpperCase(const S: string): string;
function RusToLat(Key: Char): Char;
function DefineGridCaptions(ADBGrid: TDBGrid; AFileName: TFileName): Boolean;
function BooleanToStr(AValue: Boolean): string;
function StrToBoolean(S: string): Boolean;
function FillDigTo(Value: Integer; Dig: Byte): Integer;
function StrTCopy(Dest, Source: PChar; MaxLen: Cardinal): PChar;
function StrPTCopy(Dest: PChar; const Source: string; MaxLen: Cardinal): PChar;
function TruncStr(S: string): string;
function FormatMultiLine(AStrings: TStrings; LineLimit: Integer): string;
function DecodeFieldMask(DS: TDataSet; AMask: string): string;
function CorrText(T: PChar; Corr, Dos: Boolean): Integer;
procedure ExtractRGB(C: Longint; var R, G, B: Byte);
procedure ComposeRGB(R, G, B: Byte; var C: Longint);
procedure CorrectBg(var C: Byte; F, M: Longint);
procedure RPad(var S: ShortString; Len: Byte; C: Char);
procedure LPad(var S: ShortString; Len: Byte; C: Char);
function DelCR(S: string): string;
function RemoveDoubleSpaces(S: string): string;
procedure SetProtoParams(AMaxProtoLevel, AShowProtoMes: Byte;
  AProtoFileName: string);
procedure CloseProto;
function LevelToStr(ALevel: Byte): string;
procedure ProtoMes(Level: Byte; Title: PChar; S: string);
function TestKey(AccS: string; Bik: Longint): Boolean;
function Masked(Value, Mask: string): Boolean;
function DateIsActive(BillDate, DateO, DateC: Word): Boolean;
function GetHddPlaceId(P: string): DWord;
function ParentWnd: hWnd;
function DirExists(S: string): Boolean;
function ClearDirectory(Dir: string): Boolean;
function KillDir(ADir: string): Boolean;
function GetVolumeLabel(RootPath: string; var ALabel: string): Boolean;

procedure AddWordInList(AWord: string; var AList: string);
function IndexOfWordInList(AWord: string; AList: string): Integer;
function WhichLoginExistInList(Logins: string; const AList: string): Integer;
procedure NormalizeDir(var Dir: string);
function SymPos(C: Char; Buf: PChar; BufLen: Integer): Integer;
function CalcCRC(Buf: PChar; BufLen: Integer): Byte;
procedure CodeBuf(CB: Byte; Buf: PChar; BufLen: Integer);
procedure EncodeBuf(CB: Byte; Buf: PChar; BufLen: Integer);

function RunAndWait(AppPath: string; ShowFlag: Integer; var ResCode: DWord): Boolean;


implementation

function AppDir: TFileName;
begin
  Result:= ExtractFilePath(Application.ExeName);
end;

function BaseDir: TFileName;
begin
  Result := AppDir+'Base\';
end;

function PostDir: TFileName;
begin
  Result := AppDir+'Post\';
end;

function KeyDir: TFileName;
begin
  Result := AppDir+'Key\';
end;

function PatternDir: TFileName;
begin
  Result := AppDir+'Pattern\';
end;

function TempDir: TFileName;
begin
  Result := AppDir+'Temp\';
end;

function HelpDir: TFileName;
begin
  Result := AppDir+'Help\';
end;

function ModuleDir: TFileName;
begin
  Result := AppDir+'Module\';
end;

function ParentWnd: hWnd;
begin
  Result := GetForegroundWindow {GetTopWindow(0)};
end;

const
  DosToWinTab: array[0..15] of byte = (
     0,  1,  2,  3,  4,  5,  6,  7,
    12, 13, 14,  8,  9, 10, 15, 11
  );
  WinToDosTab: array[0..15] of byte = (
     0,  1,  2,  3,  4,  5,  6,  7,
    11, 12, 13,  15,  8, 9, 10, 14
  );

procedure DosToWinL(Src: PChar; Len: Integer);
var
  I: Integer;
begin
  for I:=0 to Len-1 do
    Src[I]:= Chr((DosToWinTab[(Ord(Src[I]) shr 4) and $0F] shl 4) or
      (Ord(Src[I]) and $0F));
end;

procedure DosToWin(Src: PChar);
begin
  DosToWinL(Src,StrLen(Src));
end;

procedure WinToDosL(Src: PChar; Len: Integer);
var
  I: Integer;
begin
  for I:=0 to Len-1 do
    Src[I]:= Chr((WinToDosTab[(Ord(Src[I]) shr 4) and $0F] shl 4) or
      (Ord(Src[I]) and $0F));
end;

procedure WinToDos(Src: PChar);
begin
  WinToDosL(Src,StrLen(Src));
end;

function WinToDosS(Strng: string): string;         //Добавлено Меркуловым
var
  I, Len: Integer;
begin
  Len := Length(Strng);
  for I:=1 to Len do
    Strng[I]:= Chr((WinToDosTab[(Ord(Strng[I]) shr 4) and $0F] shl 4) or
      (Ord(Strng[I]) and $0F));
  Result := Strng;
end;

function DosToWinS(Strng: string): string;         //Добавлено Меркуловым
var
  I, Len: Integer;
begin
  Len := Length(Strng);
  for I:=1 to Len do
    Strng[I]:= Chr((DosToWinTab[(Ord(Strng[I]) shr 4) and $0F] shl 4) or
      (Ord(Strng[I]) and $0F));
  Result := Strng;
end;

function FillZeros(V,L: Integer): string;
begin
  Result := IntToStr(V);
  while Length(Result)<L do
    Result := '0'+Result;
end;

function TimeToWord(Hour, Min: word): word;
begin
  TimeToWord := 0;
  if((Hour<24) AND (Min<60)) then
    TimeToWord := (Hour SHL 6) + Min
end;

procedure WordToTime(Time: word; var Hour, Min: word);
begin
  Hour := (Time SHR 6) AND $0F;
  Min := Time AND $3F;
end;

procedure DecodeBtrDate(ADate: Word; var Year, Month, Day: Word);
begin
  Year := ((ADate shr 9) and $7F)+1980;
  Month := (ADate shr 5) and $0F;
  Day := ADate and $1F;
end;

function DateToExtStr(Year, Month, Day: Word): string;
begin
  Result := FillZeros(Day,2)+'.'+FillZeros(Month,2)+'.'+FillZeros(Year,4);
end;

function BtrDateToStr(ADate: Word): string;
var
  Year, Month, Day: Word;
begin
  if ADate=0 then
    Result:=''
  else begin
    DecodeBtrDate(ADate, Year, Month, Day);
    Result := DateToExtStr(Year, Month, Day);
  end;
end;

function DosDateToStr(DosDate: Integer): string;
var
  Year, Month, Day: Word;
begin
  if DosDate=0 then Result:=''
  else begin
    DecodeDosDate(DosDate, Year, Month, Day);
    Result := DateToExtStr(Year, Month, Day);
  end;
end;

function DosDateToOrStr(DosDate: Integer): string;          //Добавлено Меркуловым
var
  Year, Month, Day: Word;
begin
  if DosDate=0 then Result:=''
  else begin
    DecodeDosDate(DosDate, Year, Month, Day);
    Result := 'to_date('''+DateToExtStr(Year, Month, Day)+''',''dd.mm.yyyy'')';
  end;
end;

procedure StrToDMY(Date: string; var Day, Month, Year: word);
var
  i: word;
  j: Integer;
  s: string[4];
begin
  i := Pos('.',Date);
  s := Copy(Date,1,i-1);
  Val(s,Day,j);
  Date := Copy(Date,i+1,255);
  i := Pos('.',Date);
  s := Copy(Date,1,i-1);
  Val(s,Month,j);
  s := Copy(Date,i+1,255);
  Val(s,Year,j);
  if Year<1000 then begin
    if Year>80 then
      Inc(Year,1900)
    else
      Inc(Year,2000)
  end;
end;

function CodeBtrDate(Year, Month, Day: Word): Word;
begin
  if (Day>0) and (Day<32) and (Month>0) and
    (Month<13) and (Year>1979) and (Year<2108)
  then
    Result := ((((Year-1980) shl 4) + Month) shl 5) + Day
  else
    Result := 0
end;

function StrToBtrDate(ADate: string): Word;
var
  Year, Month, Day: Word;
begin
  StrToDMY(ADate, Day, Month, Year);
  Result := CodeBtrDate(Year, Month, Day);
end;

function BtrDateToDate(ABtrDate: Word): TDateTime;
var
  Year, Month, Day: Word;
begin
  DecodeBtrDate(ABtrDate, Year, Month, Day);
  Result := EncodeDate(Year, Month, Day);
end;

function DateToBtrDate(ADate: TDateTime): Word;
var
  Year, Month, Day: Word;
begin
  DecodeDate(ADate, Year, Month, Day);
  Result := CodeBtrDate(Year, Month, Day);
end;

function EncodeDosDate(Year, Month, Day: Word): Integer;
begin
  Result := (Year shl 16) or (Month shl 8) or Day;
end;

function DateToDosDate(ADate: TDateTime): Integer;
var
  Year, Month, Day: Word;
begin
  DecodeDate(ADate, Year, Month, Day);
  Result := EncodeDosDate(Year, Month, Day);
end;

function DosDateToDate(DosDate: Integer): TDateTime;
var
  Year, Month, Day: Word;
begin
  DecodeDosDate(DosDate, Year, Month, Day);
  Result := EncodeDate(Year, Month, Day);
end;

procedure DecodeDosDate(ADate: Integer; var Year, Month, Day: Word);
begin
  Year := ADate shr 16;
  Month := (ADate shr 8) and $FF;
  Day := ADate and $FF;
end;

function DosDateToBtrDate(DosDate: Integer): Word;
var
  Year, Month, Day: Word;
begin
  DecodeDosDate(DosDate, Year, Month, Day);
  Result := CodeBtrDate(Year, Month, Day);
end;

function BtrDateToDosDate(BtrDate: Word): Integer;
var
  Year, Month, Day: Word;
begin
  DecodeBtrDate(BtrDate, Year, Month, Day);
  Result := EncodeDosDate(Year, Month, Day);
end;

function EncodeBtrTime(Hour, Min: Word): Word;
begin
  Result := 0;
  if (Hour<24) and (Min<60) then
    Result := (Hour shl 6) or Min
end;

procedure DecodeBtrTime(Time: word; var Hour, Min: Word);
begin
  Hour := (Time shr 6) and $1F;
  Min := Time and $3F;
end;

function TimeToBtrTime(Time: TDateTime): Word;
var
  Hour, Min, Sec, MSec: Word;
begin
  DecodeTime(Time, Hour, Min, Sec, MSec);
  Result := EncodeBtrTime(Hour, Min);
end;

function BtrTimeToTime(Time: Word): TDateTime;
var
  Hour, Min, Sec, MSec: Word;
begin
  DecodeBtrTime(Time, Hour, Min);
  Sec := 0;
  MSec := 0;
  Result := EncodeTime(Hour, Min, Sec, MSec);
end;

function BtrTimeToStr(Time: Word): string;
var
  Hour, Min: Word;
begin
  if Time=0 then
    Result:=''
  else begin
    DecodeBtrTime(Time, Hour, Min);
    Result := FillZeros(Hour, 2) + ':' + FillZeros(Min, 2);
  end;
end;

procedure TakeZeroOffset(Buffer: PChar; var ZeroPos, OffSet: Integer);
var
  MaxLength: Integer;
begin
  MaxLength:=OffSet;
  OffSet:=0;
  while (OffSet<MaxLength) and (ZeroPos>0) do begin
    if Buffer[OffSet]=#0 then Dec(ZeroPos);
    Inc(OffSet);
  end;
end;

function RusUpCase(K: Char): Char;
begin
  if ('а'<=K) and (K<='я') then
    Result := Char(Ord(K)-32)
  else
    Result:=UpCase(K)
end;

function RusUpperCase(const S: string): string;
var
  I: Integer;
begin
  Result := S;
  for I:=1 to Length(Result) do
    Result[I] := RusUpCase(Result[I]);
end;

const
  CharNum = 25;
  CorrTable: array[0..1, 0..CharNum] of Char =
    (('Й', 'Ц', 'У', 'К', 'Е', 'Н', 'Г', 'Ш', 'Щ', 'З',
     'Ф', 'Ы', 'В', 'А', 'П', 'Р', 'О', 'Л', 'Д',
     'Я', 'Ч', 'С', 'М', 'И', 'Т', 'Ь'),
     ('Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P',
     'A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L',
     'Z', 'X', 'C', 'V', 'B', 'N', 'M'));

function RusToLat(Key: Char): Char;
var
  I: Integer;
begin
  Result := RusUpCase(Key);
  I := 0;
  while (I<=CharNum) and (Result<>CorrTable[0, I]) do
    Inc(I);
  if I<=CharNum then
    Result := CorrTable[1, I];
end;

function SumToStr(ASum: Comp): string;
var
  R, K: Int64;
begin
  R := Trunc(ASum/100.0);
  K := Round(Abs(ASum - R * 100.0));
  Result := IntToStr(K);
  if Abs(K)<10 then
    Result := '0'+Result;
  Result := IntToStr(R) + '-' + Result;
end;

function SumToRus(Sum: comp): string;
var
  S: string;
  KS: string[2];
  P: Byte;
begin
  Result := '';
  if Sum<1e14 then begin
    ValToRus(Trunc(Sum/100.0), Result, P, 0);  {0-мужской род}
    case P of
      0: S:='рубль';
      6: S:='рубля';
      7: S:='рублей';
    end;
    Result:=Result+' '+S;

    Sum := Sum - Trunc(Sum/100.0)*100;
    ValToRus(Trunc(Sum), S, P, 1);  {1-женский род}
    case P of
      0: S:='копейка';
      6: S:='копейки';
      7: S:='копеек';
    end;
    KS := IntToStr(Trunc(Sum));
    if Abs(Sum)<10 then
      KS := '0'+KS;
    Result := Result+' '+KS+' '+S;
    Result[1] := RusUpCase(Result[1]);
  end
  else
    Result := FloatToStr(Sum/100);
end;

function DefineGridCaptions(ADBGrid: TDBGrid; AFileName: TFileName): Boolean;
const
  TitleSectName='TITLES';
type
  TSectType = (stTitle, stOther);
var
  I,K,N,W,Err: Integer;
  F: TextFile;
  S, SectName, S2: string;
  Fld: TField;
  V: Boolean;
  SectType: TSectType;
begin
  AssignFile(F,AFileName);
  FileMode := 0;
  {$I-} Reset(F); {$I+}
  Result := IOResult=0;
  if Result then
  with ADBGrid.Columns do
  begin
    State := csCustomized;
    N := 0;
    for I:=1 to Count do Items[I-1].Visible:=False;
    SectType := stOther;
    while not Eof(F) do
    begin
      ReadLn(F,S);
      if Length(S)>1 then
      begin
        if S[1]='[' then
        begin
          SectName := UpperCase(Copy(S,2, Pos(']',S)-2));
          if SectName = TitleSectName then SectType := stTitle
          else SectType := stOther;
        end
        else begin
          if SectType = stTitle then
          begin
            if S[1]=';' then begin System.Delete(S,1,1); V:=False end
            else V:=True;
            K := Pos('=',S);
            if K>0 then
            begin
              Fld:=ADBGrid.DataSource.DataSet.Fields.FindField(Copy(S,1,K-1));
              if Fld<>nil then
              begin
                I:=Count-1;
                while (I>=0) and (Items[I].Field<>Fld) do
                  Dec(I);
                if I>=0 then
                begin
                  S := Copy(S, K+1, Length(S)-K);
                  K := Pos('|', S);
                  if (K>0) and (Length(S)>K) then
                  begin
                    W := K;
                    Inc(W);
                    case UpCase(S[W]) of
                      'L': Items[I].Alignment := taLeftJustify;
                      'R': Items[I].Alignment := taRightJustify;
                      'C': Items[I].Alignment := taCenter;
                      else
                        Dec(W);
                    end;
                    S2 := Copy(S, W+1, Length(S)-W);
                    if Length(S2)>0 then
                    begin
                      Val(S2, W, Err);
                      if Err=0 then
                        Items[I].Width := W
                      else
                        MessageBox(ParentWnd, PChar('Неверно задана ширина колонки '+S2
                          +' в файле '+AFileName), 'Инициализация таблицы',
                          MB_OK+MB_ICONERROR);
                    end;
                    S := Copy(S, 1, K-1);
                  end;
                  Items[I].Title.Caption:=S;
                  Items[I].Visible:=V;
                  Items[I].Index := N;
                  Inc(N);
                end;
              end;
            end;
          end;
        end;
      end;
    end;
    CloseFile(F);
  end;
end;

{function FieldTypeToStr(AFieldType: TFieldType): string;
begin
  case AFieldType of
    ftString: Result := 'Строка';
    ftInteger: Result := 'Целое число';
    ftBoolean: Result := 'Переключатель';
    ftFloat: Result := 'Дробное число';
    ftDate: Result := 'Дата';
    else Result := 'Неизвестный';
  end;
end;}

function BooleanToStr(AValue: Boolean): string;
begin
  if AValue then
    Result := 'Да'
  else
    Result := 'Нет';
end;

function StrToBoolean(S: string): Boolean;
begin
  S := RusUpperCase(S);
  Result := (S='ДА') or (S='ВКЛ') or (S='YES') or (S='TRUE') or (S='1') or (S='+');
end;

function FillDigTo(Value: Integer; Dig: Byte): Integer;
var
  D: Byte;
begin
  Result := Value;
  D := 0;
  while Value<>0 do
  begin
    Value := Value div 10;
    Inc(D);
  end;
  while D<Dig do
  begin
    Result := Result*10;
    Inc(D);
  end;
end;

function StrTCopy(Dest, Source: PChar; MaxLen: Cardinal): PChar;
var
  L: Cardinal;
begin
  L := StrLen(Source);
  if L<MaxLen then
    Result := StrLCopy(Dest, Source, MaxLen)
  else begin
    Move(Source^, Dest^, MaxLen);
    Result := Dest;
  end;
end;

function StrPTCopy(Dest: PChar; const Source: string; MaxLen: Cardinal): PChar;
var
  L: Cardinal;
begin
  L := Length(Source);
  if L<MaxLen then
    Result := StrPLCopy(Dest, Source, MaxLen)
  else begin
    Move(Source, Dest^, MaxLen);
    Result := Dest;
  end;
end;

function TruncStr(S: string): string;
var
  I, L: Integer;
begin
  Result := S;
  L := Length(Result);
  I := 1;
  while (I<=L) and (Result[I]=' ') do
    Inc(I);
  if I>1 then
  begin
    Delete(Result, 1, I-1);
    L := Length(Result);
  end;
  I := L;
  while (L>0) and (Result[I]=' ') do
    Dec(I);
  if I<L then
    Delete(Result, I+1, L-I);
end;

function FormatMultiLine(AStrings: TStrings; LineLimit: Integer): string;
var
  I: Integer;
  S: string;
begin
  Result := '';
  with AStrings do
    for I := 0 to Count-1 do
    begin
      S := Strings[I];
      if Length(S)>LineLimit then
      begin
        MessageBox(ParentWnd, 'Длинная строка - будет урезана', 'Проверка строки',
          MB_OK+MB_ICONWARNING);
        S := Copy(S, 1, LineLimit);
      end;
      Result := Result + S;
      if I<Count-1 then
        Result := Result + #13#10
    end;
end;

const
  VariorList: TStringList = nil;

procedure SetVarior(AName, AValue: string);
var
  I: Integer;
begin
  AName := UpperCase(AName);
  if VariorList=nil then VariorList := TStringList.Create;
  with VariorList do
  begin
    I := IndexOfName(AName);
    if I>=0 then
      Strings[I] := AName+'='+AValue
    else
      Add(AName+'='+AValue);
  end;
end;

function GetVarior(AName: string): string;
var
  I: Integer;
begin
  AName := UpperCase(AName);
  if VariorList<>nil then
    with VariorList do
    begin
      I := IndexOfName(AName);
      if I>=0 then
      begin
        AName := Strings[I];
        I := Pos('=', AName);
        Result := Copy(AName, I+1, Length(AName)-I);
      end
      else
        Result := '';
    end
  else
    Result := '';
end;

function DecodeFieldMask(DS: TDataSet; AMask: string): string;
const
  ProcTitle: PChar = 'DecodeFieldMask';
var
  V: string;
  I, ErrCode: Integer;
  AField: TField;
begin
  Result:='';
  repeat
    I := Pos('+',AMask);
    if I>0 then
    begin
      V := Copy(AMask,1,I-1);
      Delete(AMask,1,I)
    end
    else begin
      V := AMask;
      AMask := ''
    end;
    I := 0;
    while (I<Length(V)) and (V[I+1]=' ') do Inc(I);
    if I>0 then
      Delete(V,1,I);
    I := Length(V);
    while (I>1) and (V[I]=' ') do Dec(I);
    V:=Copy(V,1,I);

    if (V[1]='"') or (V[1]='''') or (V[1]='[') then
    begin
      if V[1]='[' then I:=1
      else I:=0;
      V:=Copy(V,2,Length(V)-2);
    end
    else begin
      if (V[1]='#') or (V[1]='$') then
      begin
        if V[1]='$' then
          I := 4
        else
          I := 3;
        V := Copy(V, 2, Length(V)-1);
      end
      else
        I := 2;
    end;
    if ((I=1) or (I=2)) and (DS<>nil) then
    begin
      if I=1 then
      begin
        Val(V,I,ErrCode);
        if ErrCode<>0 then
        begin
          AField := nil;
          MessageBox(ParentWnd, PChar('Ошибка оцифрения индекса поля '+V), ProcTitle,
            MB_OK+MB_ICONWARNING)
        end
        else begin
          AField := DS.Fields.FieldByNumber(I);
          if AField=nil then MessageBox(ParentWnd, PChar('Поле с индексом '+V+' не найдено'),
            ProcTitle, MB_OK+MB_ICONWARNING);
        end;
      end
      else begin
        AField := DS.Fields.FindField(V);
        if AField=nil then
          MessageBox(ParentWnd, PChar('Поле с именем '+V+' не найдено'),
            ProcTitle, MB_OK+MB_ICONWARNING);
      end;
      if AField<>nil then
        V := AField.Text;
    end
    else
      if I=3 then
      begin
        Val(V, I, ErrCode);
        if ErrCode=0 then
          V := Char(I);
      end
      else
        if I=4 then
          V := GetVarior(V);
    Result := Result + V;
  until Length(AMask)<=0;
end;

function CorrText(T: PChar; Corr, Dos: Boolean): Integer;
var
  I, L, R: Integer;
  C: Char;
begin
  Result := 0;
  I := 1;
  L := StrLen(T);
  while (I<L) and (Result>=0) do
  begin
    C := T[I];
    if (C=#8) or (C=#10) or (C=#13) or (#32<=C) and (C<='~') then
      R := 0
    else begin
      if Dos then
      begin
        if (#$80<=C) and (C<=#$AF) or (#$E0<=C) and (C<=#$EF) then
          R := 0
        else
          if T[I]='ь' then  {ь это № в dos}
            R := 1
          else
            R := -1;
      end
      else begin
        if 'А'<=C then
          R := 0
        else
          if T[I]='№' then
            R := 1
          else
            R := -1;
      end;
      if R<>0 then
      begin
        if Result>=0 then
          Result := R;
        if Corr then
        begin
          if R<0 then
            T[I] := ' '
          else
            if R>0 then
              T[I] := 'N';
        end;
      end;
    end;
    Inc(I);
  end;
end;

procedure ExtractRGB(C: Longint; var R, G, B: Byte);
begin
  R := C shr 16;
  G := (C shr 8) and $FF;
  B := C and $FF;
end;

procedure ComposeRGB(R, G, B: Byte; var C: Longint);
begin
  C := (R shl 16) or (G shl 8) or B;
end;

procedure CorrectBg(var C: Byte; F, M: Longint);
var
  RF, GF, BF: Byte;
begin
  ExtractRGB(F, RF, GF, BF);
  F := (RF + GF + BF) div 3;
  if F<$8F then
  begin
    F := Round((C+$30) * (1 + ($80-M)/$30) * (1+($80-F)/$80));
    if F>$FF then
      C := $FF
    else
      C := F;
  end;
  {K := ($FF-F)/$FF;
  F := Round(Abs(C*(1+K)));
  if F>$FF then
    C := $FF
  else
    C := F;}
end;

procedure RPad(var S: ShortString; Len: Byte; C: Char);
var
  L: Byte;
begin
  L := Length(S);
  if Len>L then
  begin
    SetLength(S, Len);
    FillChar(S[L+1], Len-L, C);
  end;
end;

procedure LPad(var S: ShortString; Len: Byte; C: Char);
var
  L, I: Byte;
begin
  L := Length(S);
  if Len>L then
  begin
    SetLength(S, Len);
    for I := 1 to L do
      S[Len-I+1] := S[L-I+1];
    FillChar(S[1], Len-L, C);
  end;
end;

function DelCR(S: string): string;
var
  I, L, P: Integer;
begin
  Result := '';
  I := 1;
  L := Length(S);
  while (I<=L) and ((S[I]=#13) or (S[I]=#10)) do
    Inc(I);
  while I<=L do
  begin
    P := I;
    while (I<=L) and (S[I]<>#13) and (S[I]<>#10) do
      Inc(I);
    Result := Result + Copy(S, P, I-P);
    if I<=L then
    begin
      while (I<=L) and ((S[I]=#13) or (S[I]=#10)) do
        Inc(I);
      if I<L then
        Result := Result + ' ';
    end;
  end;
end;

function RemoveDoubleSpaces(S: string): string;
var
  I, L, P: Integer;
begin
  Result := '';
  P := 0;
  I := 1;
  L := Length(S);
  while I<=L do
  begin
    if S[I]=' ' then
    begin
      if (P>0) and ((I=L) or (S[I+1]=' ')) then
      begin
        Result := Result + Copy(S, P, I-P+1);
        P := 0;
      end;
    end
    else
      if P=0 then
        P := I;
    Inc(I);
  end;
  if P>0 then
    Result := Result + Copy(S, P, I-P);
end;

var
  MaxProtoLevel: Byte = 0;
  ShowProtoMes: Byte = 1;
  ProtoFileName: string = '';

procedure SetProtoParams(AMaxProtoLevel, AShowProtoMes: Byte;
  AProtoFileName: string);
begin
  MaxProtoLevel := AMaxProtoLevel;
  ShowProtoMes := AShowProtoMes;
  ProtoFileName := AProtoFileName;
end;

var
  ShowProtoErr: Boolean = True;
  ProtoIsOpen: Boolean = False;
  ProtoFile: TextFile;

function OpenProto: Boolean;
const
  ccFileNotFound = 2;
  MesTitle: PChar = 'Открытие/создание протокола';
var
  I: Integer;
  C: Boolean;
  S: string;
begin
  if not ProtoIsOpen then
  begin
    C := False;
    AssignFile(ProtoFile, ProtoFileName);
    {$I-} Append(ProtoFile); {$I+}
    I := IOResult;
    ProtoIsOpen := I=0;
    if I=ccFileNotFound then
    begin
      C := True;
      {$I-} Rewrite(ProtoFile); {$I+}
      I := IOResult;
      ProtoIsOpen := I=0;
    end;
    if ShowProtoErr and (I<>0) then
    begin
      if C then
        S := 'создать'
      else
        S := 'открыть';
      ShowProtoErr := MessageBox(ParentWnd, PChar('Не удалось ('+IntToStr(I)+') '
        +S+' файл протокола '+ProtoFileName+#13#10'Выдавать это собщение позднее?'),
        MesTitle, MB_YESNOCANCEL or MB_ICONERROR)<>ID_NO;
    end;
  end;
  Result := ProtoIsOpen;
end;

procedure CloseProto;
begin
  if ProtoIsOpen then
  begin
    {$I-} CloseFile(ProtoFile); {$I+}
    ProtoIsOpen := False;
  end;
end;

function LevelToStr(ALevel: Byte): string;
begin
  case ALevel of
    plFatalError:
      Result := 'FatalError';
    plError:
      Result := 'Error';
    plWarning:
      Result := 'Warning';
    plInfo:
      Result := 'I';
    plTrace:
      Result := 'T';
    else
      Result := 'Unknown';
  end;
end;

function LevelToIconId(ALevel: Byte): Integer;
begin
  case ALevel of
    plFatalError, plError:
      Result := MB_ICONERROR;
    plInfo, plTrace:
      Result := MB_ICONINFORMATION;
    else
      Result := MB_ICONWARNING;
  end;
end;

procedure ProtoMes(Level: Byte; Title: PChar; S: string);
begin
  if Level<=MaxProtoLevel then
  begin
    if OpenProto then
    begin
      {$I-} WriteLn(ProtoFile, DateTimeToStr(Now)+' '+LevelToStr(Level)+' ('
        +StrPas(Title)+') '+S); {$I+}
    end;
  end;
  if (Level<=ShowProtoMes) and IsWindowVisible(Application.Handle) then
  begin
    MessageBox({Application.Handle}ParentWnd, PChar(LevelToStr(Level)+' '+S),
      Title, MB_OK or LevelToIconId(Level));
  end;
end;

function TestKey(AccS: string; Bik: Longint): Boolean;
const
  AccKeyTab: array[1..20] of word = (
    7,1,3,7,1,3,7,1,3,7,1,3,7,1,3,7,1,3,7,1);
  BikKeyTab: array[1..3] of word = (3,1,7);
var
  i, s, L: word;
begin
  Result := False;
  if Length(AccS)<=20 then
  begin
    s := 0;
    for i:=1 to 3 do
    begin
      Inc(s, (Bik mod 10) * BikKeyTab[i]);
      Bik := Bik div 10;
    end;
    L := Length(AccS);
    i := 1;
    while (i<=L) and (AccS[i]>='0') and (AccS[i]<='9') do
    begin
      Inc(s, (Ord(AccS[i])-Ord('0')) * AccKeyTab[i]);
      Inc(i);
    end;
    Result := ((s mod 10)=0) and (i>L);
  end;
end;

function Masked(Value, Mask: string): Boolean;
var
  I, L: Integer;
begin
  L := Length(Mask);
  I := Length(Value);
  if I<L then
    L := I;
  I := 1;
  while (I<=L) and (Mask[I]='?') or (Mask[I]=Value[I]) do
    Inc(I);
  Result := I>L;
end;

function DateIsActive(BillDate, DateO, DateC: Word): Boolean;
begin
  Result := (DateO<BillDate) and ((DateC=0) or (BillDate<=DateC));
end;

function GetCotrolNumberOfPath(S: string): Cardinal;
var
  I, L: Integer;
begin
  S := RusUpperCase(Trim(S));
  L := Length(S);
  Result := L;
  for I := 1 to L do
  begin
    asm
      rol   Result,3
    end;
    Result := Result xor Ord(S[I]);
  end;
end;

function Rol(A: Cardinal; C: Byte): dWord;
begin
  Result := A;
  asm
    push  CX
    mov   CL,C
    rol   Result,CL
    pop   CX
  end;
end;

function GetHddPlaceId(P: string): dWord;
var
  A,B,L: dWord;
  SPC, BPS, NFC, TNC: Cardinal;
  BTC, TB, FB: Int64;
  Disk: array [0..4] of Char;
  Lab, FSys: array [0..12] of Char;
  DT: Integer;
begin
  try
    StrPLCopy(Disk, ExtractFileDrive(P)+'\', SizeOf(Disk));
    try
      DT := GetDriveType(Disk);
    except
      DT := 123;
    end;
    try
      if not GetDiskFreeSpace(Disk, SPC, BPS, NFC, TNC) then
      begin
        SPC := 1;
        BPS := 2;
        NFC := 3;
        TNC := 4;
      end;
    except
      SPC := 1;
      BPS := 2;
      NFC := 3;
      TNC := 4;
    end;
    try
      if not GetDiskFreeSpaceEx(Disk, BTC, TB, @FB) then
      begin
        BTC := 10;
        TB := 20;
        FB := 30;
      end;
    except
      BTC := 10;
      TB := 20;
      FB := 30;
    end;
    try
      if not GetVolumeInformation(Disk, Lab, SizeOf(Lab), @L, A, B, FSys,
        SizeOf(FSys)) then
      begin
        L := 100;
        A := 200;
        B := 300;
        FSys := '';
      end;
    except
      L := 100;
      A := 200;
      B := 300;
      FSys := '';
    end;
    try
      Result := GetCotrolNumberOfPath(P);
    except
      Result := 1230001;
    end;
    try
      Result := Result xor dWord(DT * 3);
    except
    end;
    Result := Result xor L xor SPC xor Rol(BPS, 3) xor Rol(TNC, 6) xor TB;
  except
    Result := 0;
  end;
end;

function DirExists(S: string): Boolean;
var
  Code: Integer;
begin
  Code := Length(S);
  if (Code>0) and (S[Code]='\') then
    Delete(S, Code, 1);
  Code := GetFileAttributes(PChar(S));
  Result := (Code <> -1) and (FILE_ATTRIBUTE_DIRECTORY and Code <> 0);
end;

function ClearDirectory(Dir: string): Boolean;
const
  MesTitle: PChar = 'Копирование ключей';
var
  SearchRec: TSearchRec;
  Res: Integer;
begin
  Result := True;
  Res := FindFirst(Dir+'*.*', faAnyFile, SearchRec);
  if Res=0 then
  begin
    try
      while (Res=0) {and Process} do
      begin
        if (SearchRec.Attr and faDirectory)>0 then
        begin
          if (SearchRec.Name<>'.') and (SearchRec.Name<>'..') then
          begin
            Result := Result and ClearDirectory(Dir+SearchRec.Name+'\')
              and RemoveDir(Dir+SearchRec.Name+'\');
          end;
        end
        else
          Result := Result and DeleteFile(PChar(Dir+SearchRec.Name));
        Res := FindNext(SearchRec);
        {Application.ProcessMessages;}
      end;
    finally
      SysUtils.FindClose(SearchRec);
    end;
  end;
end;

function KillDir(ADir: string): Boolean;
begin
  Result := True;
  if DirExists(ADir) then
    Result := ClearDirectory(ADir) and RemoveDir(ADir);
end;

function GetVolumeLabel(RootPath: string; var ALabel: string): Boolean;
var
  A,B,L: dWord;
  Lab, FSys: array [0..12] of Char;
begin
  Result := GetVolumeInformation(PChar(RootPath),
    Lab, SizeOf(Lab), @L, A, B, FSys, SizeOf(FSys));
  if Result then
    ALabel := Lab;
end;

procedure AddWordInList(AWord: string; var AList: string);
begin
  if Length(AWord)>0 then
  begin
    if Length(AList)>0 then
      AList := AList+ListDivider;
    AList := AList+AWord;
  end;
end;

function IndexOfWordInList(AWord: string; AList: string): Integer;
var
  I, L, P: Integer;
begin
  Result := -1;
  I := 0;
  L := Length(AList);
  while L>0 do
  begin
    P := Pos(ListDivider, AList);
    if P=0 then
      P := L+1;
    if UpperCase(AWord)=UpperCase(Copy(AList, 1, P-1)) then
    begin
      Result := I;
      L := 0;
    end
    else begin
      Inc(I);
      if P>L then
        P := L;
      Delete(AList, 1, P);
      L := Length(AList);
    end;
  end;
end;

function WhichLoginExistInList(Logins: string; const AList: string): Integer;
var
  I, L, P: Integer;
begin
  Result := -1;
  I := 0;
  L := Length(Logins);
  while L>0 do
  begin
    P := Pos(ListDivider, Logins);
    if P=0 then
      P := L+1;
    if IndexOfWordInList(Copy(Logins, 1, P-1), AList)>=0 then
    begin
      Result := I;
      L := 0;
    end
    else begin
      Inc(I);
      if P>L then
        P := L;
      Delete(Logins, 1, P);
      L := Length(Logins);
    end;
  end;
end;

procedure NormalizeDir(var Dir: string);
var
  L: Integer;
begin
  L := Length(Dir);
  if (L>0) and (Dir[L]<>'\') then
    Dir := Dir + '\';
end;

function SymPos(C: Char; Buf: PChar; BufLen: Integer): Integer;
begin
  Result := 0;
  while (Result<BufLen) and (C<>Buf[Result]) do
    Inc(Result);
  if Result>=BufLen then
    Result := -1;
end;

function CalcCRC(Buf: PChar; BufLen: Integer): Byte;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to BufLen-1 do
    Result := Result xor Ord(Buf[I]);
end;

procedure CodeBuf(CB: Byte; Buf: PChar; BufLen: Integer);
var
  I: Integer;
  C: Char;
begin
  if BufLen>0 then
  begin
    Buf[0] := Chr(Ord(Buf[0]) xor CB);
    C := Buf[0];
    for I := 1 to BufLen-1 do
    begin
      C := Chr(Ord(Buf[I]) xor Ord(C));
      Buf[I] := C;
    end;
    Buf[BufLen-1] := Chr(Ord(Buf[BufLen-1]) xor CB);
  end;
end;

procedure EncodeBuf(CB: Byte; Buf: PChar; BufLen: Integer);
var
  I: Integer;
  C: Char;
begin
  if BufLen>0 then
  begin
    Buf[BufLen-1] := Chr(Ord(Buf[BufLen-1]) xor CB);
    for I := BufLen-1 downto 1 do
    begin
      C := Chr(Ord(Buf[I-1]) xor Ord(Buf[I]));
      Buf[I] := C;
    end;
    Buf[0] := Chr(Ord(Buf[0]) xor CB);
  end;
end;

function RunAndWait(AppPath: string; ShowFlag: Integer; var ResCode: DWord): Boolean;
const
  MesTitle: PChar = 'Запуск утилиты';
var
  si: TStartupInfo;
  pi: TProcessInformation;
  CmdLine: array[0..1023] of Char;
  //Code: dWord;
  S: string;
begin
  Result := False;
  S := ParamStr(0);
  S := ExtractFilePath(S);
  SetCurrentDirectory(PChar(S));
  FillChar(si, SizeOf(si), #0);
  with si do
  begin
    cb := SizeOf(si);
    dwFlags := STARTF_USESHOWWINDOW;
    wShowWindow := ShowFlag{SW_SHOWDEFAULT};
  end;
  StrPLCopy(CmdLine, AppPath, SizeOf(CmdLine));
  if CreateProcess(nil, CmdLine, nil, nil, FALSE,
    DETACHED_PROCESS, nil, nil, si, pi) then
  begin
    WaitforSingleObject(pi.hProcess, INFINITE);
    GetExitCodeProcess(pi.hProcess, ResCode);
    Result := True;
  end
  else
    MessageBox(ParentWnd, PChar('Не удалось запустить программу обновления '
      +#13#10+CmdLine), MesTitle, MB_OK or MB_ICONERROR);
end;

end.
