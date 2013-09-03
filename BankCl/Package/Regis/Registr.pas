unit Registr;

interface

uses
  Classes, SysUtils, Windows, Db, Utilits, Btrieve;

const
  rnPaydoc    = 0;
  rnPackage   = 1;
  rnBadFile   = 2;
  rnSprUpdate = 3;
  rnAuth      = 4;
  rnInPack    = 5;

  CommonUserNumber = 0;

type
  TParamIdent = array[0..31] of Char;
  TParamName = array[0..127] of Char;
  TStrValue = array[0..235] of Char;
  TParamMeasure = array[0..19] of Char;

  PParamNewRec = ^TParamNewRec;            {Параметр реестра}
  TParamNewRec = packed record
    pmSect:   Word;           { Секция                   0, 2      k0.1}
    pmNumber: Longint;        { Номер параметра          2, 4      k0.2}
    pmUser:   Word;           { Пользователь             6, 2      k0.3  k1.2}
    pmIdent:  TParamIdent;    { Идентефикатор            8, 32     k1.1}
    pmName:   TParamName;     { Название                 20, 128}
    pmMeasure: TParamMeasure; { ЕИ                       148, 20}
    pmLevel:  Byte;           { Уровень                  168, 1}
    case pmType: TFieldType of   { Тип параметра         169, 1 = 170}
    ftString: (
      pmStrValue: TStrValue;   { Значение                170, (236)}
    );
    ftInteger: (
      pmIntValue: Integer;     {                         170, 4}
      pmMinIntValue: Integer;  {                         174, 4}
      pmMaxIntValue: Integer;  {                         178, 4}
      pmDefIntValue: Integer;  {                         182, 4}
    );
    ftBoolean: (
      pmBoolValue: Boolean;    {                         170, 4}
      pmDefBoolValue: Boolean; {                         174, 4}
    );
    ftFloat: (
      pmFltValue: Double;      {                         170, 8}
      pmMinFltValue: Double;   {                         178, 8}
      pmMaxFltValue: Double;   {                         186, 8}
      pmDefFltValue: Double;   {                         194, 8}
    );
    ftDate: (
      pmDateValue: Word;       {                         170, 2}
      pmDefDateValue: Word;    {                         172, 2}
    );
    ftUnknown: (
      pmBuffer: Char;         {                         170, (max)}
    );
  end;                                                   {=(200)}

  PParamOldRec = ^TParamOldRec;            {Устаревший параметр реестра}
  TParamOldRec = packed record
    pmSect:   Word;           { Секция                   0, 2      k0.1}
    pmNumber: Longint;        { Номер параметра          2, 4      k0.2}
    pmIdent:  TParamIdent;    { Идентефикатор            6, 12     k1}
    pmName:   TParamName;     { Название                 18, 128}
    pmMeasure: TParamMeasure; { ЕИ                       146, 20}
    pmLevel:  Byte;           { Уровень                  166, 1}
    case pmType: TFieldType of   { Тип параметра         167, 1 = 168}
    ftString: (
      pmStrValue: TStrValue;   { Значение                168, (236)}
    );
    ftInteger: (
      pmIntValue: Integer;     {                         168, 4}
      pmMinIntValue: Integer;  {                         172, 4}
      pmMaxIntValue: Integer;  {                         176, 4}
      pmDefIntValue: Integer;  {                         180, 4}
    );
    ftBoolean: (
      pmBoolValue: Boolean;    {                         168, 4}
      pmDefBoolValue: Boolean; {                         172, 4}
    );
    ftFloat: (
      pmFltValue: Double;      {                         168, 8}
      pmMinFltValue: Double;   {                         176, 8}
      pmMaxFltValue: Double;   {                         184, 8}
      pmDefFltValue: Double;   {                         192, 8}
    );
    ftDate: (
      pmDateValue: Word;       {                         168, 2}
      pmDefDateValue: Word;    {                         170, 2}
    );
    ftUnknown: (
      pmBuffer: Char;       {                      168, (max)}
    );
  end;                                                   {=(200)}

  TParamKey0 =
    packed record
      pkSect: Word;
      pkNumber: Integer;
      pkUser: Word;
    end;

  TParamKey1 =
    packed record
      pkIdent: TParamIdent;
      pkUser: Word;
    end;

function GetRegistrBase: TBtrBase;
procedure SetRegFile(Value: string);
function OpenRegistr: Boolean;
procedure CloseRegistr;
function FieldTypeToStr(AFieldType: TFieldType): string;
function ParamValueToStr(var ParamRec: TParamNewRec): string;
function StrToParamValue(S: string; AType: TFieldType; var AValue): Boolean;
function GetParamDataLen(AType: TFieldType; ABuf: PChar): Integer;
function GetParamLen(const ParamRec: TParamNewRec): Integer;
function GetRegParam(ASect: Word; ANumber: Integer; AUser: Word; var Value): Boolean;
function GetRegParamByName(AName: string; AUser: Word; var Value): Boolean;
function SetRegParamByName(AName: string; AUser: Word; LetCommon: Boolean;
  Value: string): Boolean;
function DecodeMask(AMask: string; ADepth: Byte; AUser: Word): string;
procedure MakeRegNumber(GroupIndex: Integer; var Number: Integer);
function GetRegNumber(GroupIndex: Integer): Integer;
function SetRegNumber(GroupIndex, Value: Integer): Boolean;

implementation

var
  RegistrBase: TBtrBase = nil;

function GetRegistrBase: TBtrBase;
begin
  Result := RegistrBase;
end;

var
  RegFile: string = 'Base\setup.btr';

procedure SetRegFile(Value: string);
begin
  RegFile := Value;
end;

function OpenRegistr: Boolean;
var
  Res: Integer;
begin
  Result := RegistrBase<>nil;
  if not Result then
  begin
    RegistrBase := TBtrBase.Create;
    with RegistrBase do
    begin
      Res := Open(AppDir+RegFile, baNormal);
      Result := Res=0;
    end;
  end;
end;

procedure CloseRegistr;
begin
  RegistrBase.Free;
  RegistrBase := nil;
end;

function FieldTypeToStr(AFieldType: TFieldType): string;
begin
  case AFieldType of
    ftString:
      Result := 'Строка';
    ftInteger:
      Result := 'Целое число';
    ftBoolean:
      Result := 'Переключатель';
    ftFloat:
      Result := 'Дробное число';
    ftDate:
      Result := 'Дата';
    else
      Result := 'Неизвестный';
  end;
end;

function ParamValueToStr(var ParamRec: TParamNewRec): string;
begin
  with ParamRec do
    case pmType of
      ftString:
        Result := StrPas(@pmStrValue);
      ftInteger:
        Result := IntToStr(pmIntValue);
      ftBoolean:
        Result := BooleanToStr(pmBoolValue);
      ftFloat:
        Result := FloatToStr(pmFltValue);
      ftDate:
        Result := BtrDateToStr(pmDateValue);
      else
        Result := '-';
    end;
end;

function StrToParamValue(S: string; AType: TFieldType; var AValue): Boolean;
begin
  Result := True;
  case AType of
    ftString:
      StrPLCopy(@AValue, S, SizeOf(TStrValue));
    ftInteger:
      Integer(AValue) := StrToInt(S);
    ftBoolean:
      Boolean(AValue) := StrToBoolean(S);
    ftFloat:
      Double(AValue) := StrToFloat(S);
    ftDate:
      Word(AValue) := StrToBtrDate(S);
    else
      Result := False;
  end;
end;

procedure GetParam(AParamRec: TParamNewRec; var Value);
begin
  with AParamRec do
  begin
    case pmType of
      ftString:
        StrLCopy(PChar(@Value), @pmStrValue, SizeOf(TStrValue));
      ftInteger:
        Integer(Value) := pmIntValue;
      ftBoolean:
        Boolean(Value) := pmBoolValue;
      ftFloat:
        Double(Value) := pmFltValue;
      ftDate:
        Word(Value) := pmDateValue;
    end;
  end;
end;

function GetParamDataLen(AType: TFieldType; ABuf: PChar): Integer;
begin
  Result := 0;
  case AType of
    ftString: Result := StrLen(ABuf)+1 + StrLen(@ABuf[StrLen(ABuf)+1])+1;
    ftInteger: Result := 16;
    ftBoolean: Result := 8;
    ftFloat: Result := 32;
    ftDate: Result := 4;
  end;
end;

function GetParamLen(const ParamRec: TParamNewRec): Integer;
begin
  Result := SizeOf(ParamRec)-SizeOf(TStrValue);
  Result := Result + GetParamDataLen(ParamRec.pmType, @ParamRec.pmBuffer);
end;

function GetRegParam(ASect: Word; ANumber: Integer; AUser: Word; var Value): Boolean;
var
  ParamVec: TParamKey0;
  ParamRec: TParamNewRec;
  Res, Len: Integer;
begin
  Result := OpenRegistr;
  if Result then
  begin
    with ParamVec do
    begin
      pkSect := ASect;
      pkNumber := ANumber;
      pkUser := AUser;
    end;
    Len := SizeOf(ParamRec);
    Res := RegistrBase.GetEqual(ParamRec, Len, ParamVec, 0);
    if (Res<>0) and (AUser<>CommonUserNumber) then
    begin
      ParamVec.pkUser := CommonUserNumber;
      Len := SizeOf(ParamRec);
      Res := RegistrBase.GetEqual(ParamRec, Len, ParamVec, 0);
    end;
    Result := Res=0;
    if Result then
      GetParam(ParamRec, Value);
  end;
end;

function GetRegParamByName(AName: string; AUser: Word; var Value): Boolean;
var
  ParamVec: TParamKey1;
  ParamRec: TParamNewRec;
  Res, Len: Integer;
begin
  Result := OpenRegistr;
  if Result then
  begin
    FillChar(ParamVec, SizeOf(ParamVec), #0);
    StrPLCopy(ParamVec.pkIdent, AName, SizeOf(ParamVec.pkIdent)-1);
    ParamVec.pkUser := AUser;
    Len := SizeOf(ParamRec);
    Res := RegistrBase.GetEqual(ParamRec, Len, ParamVec, 1);
    if (Res<>0) and (AUser<>CommonUserNumber) then
    begin
      ParamVec.pkUser := CommonUserNumber;
      Len := SizeOf(ParamRec);
      Res := RegistrBase.GetEqual(ParamRec, Len, ParamVec, 1);
    end;
    Result := Res=0;
    if Result then
      GetParam(ParamRec, Value);
  end;
end;

function SetRegParamByName(AName: string; AUser: Word; LetCommon: Boolean;
  Value: string): Boolean;
var
  ParamVec: TParamKey1;
  ParamRec: TParamNewRec;
  Res, Len: Integer;
begin
  Result := OpenRegistr;
  if Result then
  begin
    FillChar(ParamVec, SizeOf(ParamVec), #0);
    StrPLCopy(ParamVec.pkIdent, AName, SizeOf(ParamVec.pkIdent)-1);
    ParamVec.pkUser := AUser;
    Len := SizeOf(ParamRec);
    Res := RegistrBase.GetEqual(ParamRec, Len, ParamVec, 1);
    if (Res<>0) and (AUser<>CommonUserNumber) and LetCommon then
    begin
      ParamVec.pkUser := CommonUserNumber;
      Len := SizeOf(ParamRec);
      Res := RegistrBase.GetEqual(ParamRec, Len, ParamVec, 1);
    end;
    Result := Res=0;
    if Result then
    begin
      with ParamRec do
        StrToParamValue(Value, pmType, pmBuffer);
      Len := GetParamLen(ParamRec);
      Res := RegistrBase.Update(ParamRec, Len, ParamVec, 1);
      Result := Res=0;
    end;
  end;
end;

procedure GetRegName(GroupIndex: Integer; RegName: PChar; MaxLen: Integer);
begin
  case GroupIndex of
    rnPaydoc:
      StrLCopy(RegName, 'PaydocRegNum', MaxLen);
    rnPackage:
      StrLCopy(RegName, 'PackageRegNum', MaxLen);
    rnBadFile:
      StrLCopy(RegName, 'BadFileRegNum', MaxLen);
    rnSprUpdate:
      StrLCopy(RegName, 'SprUpdRegNum', MaxLen);
    rnAuth:
      StrLCopy(RegName, 'AuthRegNum', MaxLen);
    rnInPack:
      StrLCopy(RegName, 'InPackRegNum', MaxLen);
    else
      StrLCopy(RegName, 'CommonRegNum', MaxLen);
  end;
end;

const
  MaxTakeRegNumLoop: Integer = 1000;

procedure MakeRegNumber(GroupIndex: Integer; var Number: Integer);
const
  MesTitle: PChar = 'Регистрация идентификатора';
var
  ParamVec: TParamKey1;
  ParamRec: TParamNewRec;
  Res, Len, C: Integer;
begin
  Number := -1;
  if OpenRegistr then
  begin
    FillChar(ParamVec, SizeOf(ParamVec), #0);
    GetRegName(GroupIndex, ParamVec.pkIdent, SizeOf(ParamVec.pkIdent)-1);
    ParamVec.pkUser := CommonUserNumber;
    C := 0;
    repeat
      Len := SizeOf(ParamRec);
      Res := RegistrBase.GetEqual(ParamRec, Len, ParamVec, 1);
      if Res=0 then
      begin
        if ParamRec.pmType=ftInteger then
        begin
          Inc(ParamRec.pmIntValue);
          Res := RegistrBase.Update(ParamRec, Len, ParamVec, 1);
          if Res=0 then
            Number := ParamRec.pmIntValue
          else begin
            if Res=80 then
            begin
              Inc(C);
              if C>MaxTakeRegNumLoop then
              begin
                if MessageBox(ParentWnd, PChar('Не удалось взять новый '
                  +ParamVec.pkIdent+' за '+IntToStr(C)
                  +' циклов'#13#10'Повторить еще раз?'), MesTitle,
                  MB_YESNOCANCEL or MB_ICONERROR) = ID_YES
                then
                  C := 0
                else
                  Res := 0;
              end
              else
                Sleep(10);
            end
            else
              MessageBox(ParentWnd, PChar('Ошибка модификации '
                +ParamVec.pkIdent+' BtrErr='+IntToStr(Res)), MesTitle,
                MB_OK or MB_ICONERROR);
          end;
        end
        else
          MessageBox(ParentWnd, PChar('Запрос идентификатора '
            +ParamVec.pkIdent+' не целого типа ('+IntToStr(Ord(ParamRec.pmType))),
            MesTitle, MB_OK or MB_ICONERROR);
      end
      else
        MessageBox(ParentWnd, PChar('Ошибка чтения '+ParamVec.pkIdent+' BtrErr='
          +IntToStr(Res)), MesTitle, MB_OK or MB_ICONERROR);
    until Res<>80;
  end;
end;

function GetRegNumber(GroupIndex: Integer): Integer;
const
  MesTitle: PChar = 'Чтение идентификатора';
var
  ParamVec: TParamKey1;
  ParamRec: TParamNewRec;
  Res, Len: Integer;
begin
  Result := -1;
  if OpenRegistr then
  begin
    FillChar(ParamVec, SizeOf(ParamVec), #0);
    GetRegName(GroupIndex, ParamVec.pkIdent, SizeOf(ParamVec.pkIdent)-1);
    ParamVec.pkUser := CommonUserNumber;
    Len := SizeOf(ParamRec);
    Res := RegistrBase.GetEqual(ParamRec, Len, ParamVec, 1);
    if Res=0 then
    begin
      if ParamRec.pmType=ftInteger then
        Result := ParamRec.pmIntValue
      else
        MessageBox(ParentWnd, PChar('Запрос идентификатора '
          +ParamVec.pkIdent+' не целого типа ('+IntToStr(Ord(ParamRec.pmType))),
          MesTitle, MB_OK or MB_ICONERROR);
    end
    else
      MessageBox(ParentWnd, PChar('Ошибка чтения '+ParamVec.pkIdent+' BtrErr='
        +IntToStr(Res)), MesTitle, MB_OK or MB_ICONERROR);
  end;
end;

function SetRegNumber(GroupIndex: Integer; Value: Integer): Boolean;
const
  MesTitle: PChar = 'Запись идентификатора';
var
  ParamVec: TParamKey1;
  ParamRec: TParamNewRec;
  Res, Len, C: Integer;
begin
  Result := False;
  if OpenRegistr then
  begin
    FillChar(ParamVec, SizeOf(ParamVec), #0);
    GetRegName(GroupIndex, ParamVec.pkIdent, SizeOf(ParamVec.pkIdent)-1);
    ParamVec.pkUser := CommonUserNumber;
    C := 0;
    repeat
      Len := SizeOf(ParamRec);
      Res := RegistrBase.GetEqual(ParamRec, Len, ParamVec, 1);
      if Res=0 then
      begin
        if ParamRec.pmType=ftInteger then
        begin
          ParamRec.pmIntValue := Value;
          Res := RegistrBase.Update(ParamRec, Len, ParamVec, 1);
          if Res=0 then
            Result := True
          else begin
            if Res=80 then
            begin
              Inc(C);
              if C>MaxTakeRegNumLoop then
              begin
                if MessageBox(ParentWnd, PChar('Не записать идентификатор '
                  +ParamVec.pkIdent+' за '+IntToStr(C)
                  +' циклов'#13#10'Повторить еще раз?'), MesTitle,
                  MB_YESNOCANCEL or MB_ICONERROR) = ID_YES
                then
                  C := 0
                else
                  Res := 0;
              end
              else
                Sleep(10);
            end
            else
              MessageBox(ParentWnd, PChar('Ошибка модификации '
                +ParamVec.pkIdent+' BtrErr='
                +IntToStr(Res)), MesTitle, MB_OK or MB_ICONERROR);
          end;
        end
        else
          MessageBox(ParentWnd, PChar('Запрос идентификатора '
            +ParamVec.pkIdent+' не целого типа ('+IntToStr(Ord(ParamRec.pmType))),
            MesTitle, MB_OK or MB_ICONERROR);
      end
      else
        MessageBox(ParentWnd, PChar('Ошибка чтения '+ParamVec.pkIdent+' BtrErr='
          +IntToStr(Res)), MesTitle, MB_OK or MB_ICONERROR);
    until Res<>80;
  end;
end;


const
  NumOfFuncs = 6;
  FuncNames: array[1..NumOfFuncs] of string =
    ('App', 'Base', 'Key', 'Module', 'Help', 'Pattern');

var
  DecodeUser: Word = CommonUserNumber;

function DecodeMaskIntern(AMask: string; Depth: Byte): string;
var
  I, B, J, K, L: Integer;
  S: string;
  Mode: Byte;
  ParamVec: TParamKey1;
  ParamRec: TParamNewRec;
begin
  if Depth>0 then
  begin
    Dec(Depth);
    Result := '';
    Mode := 0;
    J := 0;
    I := 0;
    B := 1;
    while (I<Length(AMask)) do
    begin
      Inc(I);
      case AMask[I] of
        '[':
          if Mode = 0 then
          begin
            J := I;
            Mode := 1;
          end;
        ']':
          if Mode = 1 then
          begin
            S := Copy(AMask, J+1, I-J-1);
            K := 1;
            while (K<=NumOfFuncs) and (UpperCase(S)<>UpperCase(FuncNames[K]))
              do Inc(K);
            if K<=NumOfFuncs then
            begin
              case K of
                1: S := AppDir;
                2: S := BaseDir;
                3: S := KeyDir;
                4: S := ModuleDir;
                5: S := HelpDir;
                6: S := PatternDir;
              end;
              Result := Result + Copy(AMask, B, J-B) + S;
              B := I+1;
            end;
            Mode := 0;
          end;
        '$':
          if (Mode = 0) and (I<Length(AMask)) then
          begin
            if (AMask[I+1]='(') then
            begin
              J := I;
              Inc(I);
              Mode := 2;
            end;
          end;
        ')':
          if Mode = 2 then
          begin
            S := Copy(AMask, J+2, I-J-2);
            if OpenRegistr then
            begin
              FillChar(ParamVec, SizeOf(ParamVec), #0);
              StrPLCopy(ParamVec.pkIdent, S, SizeOf(ParamVec.pkIdent)-1);
              ParamVec.pkUser := DecodeUser;
              L := SizeOf(ParamRec);
              K := RegistrBase.GetEqual(ParamRec, L, ParamVec, 1);
              if (K<>0) and (DecodeUser<>CommonUserNumber) then
              begin
                ParamVec.pkUser := CommonUserNumber;
                L := SizeOf(ParamRec);
                K := RegistrBase.GetEqual(ParamRec, L, ParamVec, 1);
              end;
              if K=0 then
              begin
                S := ParamValueToStr(ParamRec);
                S := DecodeMaskIntern(S, Depth-1);
                Result := Result + Copy(AMask, B, J-B) + S;
                B := I+1;
              end;
            end;
            Mode := 0;
          end;
      end;
    end;
    Result := Result + Copy(AMask, B, Length(AMask)-B+1);
  end
  else
    Result := '<!рекурсия>';
end;

function DecodeMask(AMask: string; ADepth: Byte; AUser: Word): string;
begin
  DecodeUser := AUser;
  Result := DecodeMaskIntern(AMask, ADepth);
end;

end.
