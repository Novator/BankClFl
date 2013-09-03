unit Bases;

interface

uses
  Classes, SysUtils, Windows, Db, Forms, Messages, DbGrids, BtrDS,
    Menus, Controls, Utilits, Registr, Btrieve, CommCons, ClntCons;

type
  TBaseNumber = (biUser, biSanction,
    biAcc, biAccArc, biNp, biBank, biClient, biLetter, biBill, biPay, biFile,
    biModule, biSFile, biLFile, biValDoc, biValAcc, biValBill, biValCode,
    biValCli);             //Изменено

  TBillDataSet = class(TExtBtrDataSet)
  protected
    procedure InternalInitFieldDefs; override;
  public
    function GetFieldData(Field: TField; Buffer: Pointer): Boolean; override;
    constructor Create(AOwner: TComponent); override;
  end;

  TPayDataSet = class(TExtBtrDataSet)
  protected
    procedure InternalInitFieldDefs; override;
  public
    function GetFieldData(Field: TField; Buffer: Pointer): Boolean; override;
    //function GetDocState(ARecBuffer: Pointer): Word;
    constructor Create(AOwner: TComponent); override;
    {procedure UpdateDocumentByCode(CopyCurrent, New, ReadOnly: Boolean;
      ADocCode: Byte);
    procedure ViewDocumentIder(ADocIder: Integer);}
  end;

  TValPayDataSet = class(TExtBtrDataSet)
  protected
    procedure InternalInitFieldDefs; override;
  public
    function GetFieldData(Field: TField; Buffer: Pointer): Boolean; override;
    {function GetDocState(ARecBuffer: Pointer): Word;}
    constructor Create(AOwner: TComponent); override;
    {procedure UpdateDocumentByCode(CopyCurrent, New, ReadOnly: Boolean;
      ADocCode: Byte);
    procedure ViewDocumentIder(ADocIder: Integer);}
  end;

  TNpDataSet = class(TExtBtrDataSet)
  protected
    procedure InternalInitFieldDefs; override;
  public
    function GetFieldData(Field: TField; Buffer: Pointer): Boolean; override;
    constructor Create(AOwner: TComponent); override;
  end;

  TClientDataSet = class(TExtBtrDataSet)
  protected
    procedure InternalInitFieldDefs; override;
  public
    function GetFieldData(Field: TField; Buffer: Pointer): Boolean; override;
    constructor Create(AOwner: TComponent); override;
  end;

  TLetterDataSet = class(TExtBtrDataSet)
  protected
    procedure InternalInitFieldDefs; override;
  public
    function GetFieldData(Field: TField; Buffer: Pointer): Boolean; override;
    constructor Create(AOwner: TComponent); override;
  end;

  TBankDataSet = class(TExtBtrDataSet)
  protected
    procedure InternalInitFieldDefs; override;
  public
    function GetFieldData(Field: TField; Buffer: Pointer): Boolean; override;
    constructor Create(AOwner: TComponent); override;
  end;

  TAccDataSet = class(TExtBtrDataSet)
  protected
    procedure InternalInitFieldDefs; override;
  public
    function GetFieldData(Field: TField; Buffer: Pointer): Boolean; override;
    constructor Create(AOwner: TComponent); override;
  end;

  TAccArcDataSet = class(TExtBtrDataSet)
  protected
    procedure InternalInitFieldDefs; override;
  public
    function GetFieldData(Field: TField; Buffer: Pointer): Boolean; override;
    constructor Create(AOwner: TComponent); override;
  end;

  {TParamDataSet = class(TBtrDataSet)
  protected
    procedure InternalInitFieldDefs; override;
  public
    function GetFieldData(Field: TField; Buffer: Pointer): Boolean; override;
    constructor Create(AOwner: TComponent); override;
  end;}

  TModuleDataSet = class(TExtBtrDataSet)
  protected
    procedure InternalInitFieldDefs; override;
  public
    function GetFieldData(Field: TField; Buffer: Pointer): Boolean; override;
    constructor Create(AOwner: TComponent); override;
  end;

  TUserDataSet = class(TExtBtrDataSet)
  protected
    procedure InternalInitFieldDefs; override;
  public
    function GetFieldData(Field: TField; Buffer: Pointer): Boolean; override;
    constructor Create(AOwner: TComponent); override;
  end;

  {TAccessDataSet = class(TExtBtrDataSet)
  protected
    procedure InternalInitFieldDefs; override;
  public
    function GetFieldData(Field: TField; Buffer: Pointer): Boolean; override;
    constructor Create(AOwner: TComponent); override;
  end;}

  TSanctionDataSet = class(TExtBtrDataSet)
  protected
    procedure InternalInitFieldDefs; override;
  public
    function GetFieldData(Field: TField; Buffer: Pointer): Boolean; override;
    constructor Create(AOwner: TComponent); override;
  end;

  {TFirmAccDataSet = class(TExtBtrDataSet)
  protected
    procedure InternalInitFieldDefs; override;
  public
    function GetFieldData(Field: TField; Buffer: Pointer): Boolean; override;
    constructor Create(AOwner: TComponent); override;
  end;

  TFirmDataSet = class(TExtBtrDataSet)
  private
  protected
    procedure InternalInitFieldDefs; override;
  public
    function GetFieldData(Field: TField; Buffer: Pointer): Boolean; override;
    constructor Create(AOwner: TComponent); override;
  end;}

  TFileDataSet = class(TExtBtrDataSet)
  protected
    procedure InternalInitFieldDefs; override;
  public
    function GetFieldData(Field: TField; Buffer: Pointer): Boolean; override;
    constructor Create(AOwner: TComponent); override;
  end;

  //Добавлено Меркуловым
  TSFileDataSet = class(TExtBtrDataSet)
  protected
    procedure InternalInitFieldDefs; override;
  public
    function GetFieldData(Field: TField; Buffer: Pointer): Boolean; override;
    constructor Create(AOwner: TComponent); override;
  end;

  //Добавлено Меркуловым
  TLFileDataSet = class(TExtBtrDataSet)
  protected
    procedure InternalInitFieldDefs; override;
  public
    function GetFieldData(Field: TField; Buffer: Pointer): Boolean; override;
    constructor Create(AOwner: TComponent); override;
  end;


var
  ShowPolySign: Boolean = False;


function FieldTypeToStr(AFieldType: TFieldType): string;
procedure SetUserNumber(Value: Integer);
procedure SetFirmNumber(Value: Integer);
function LevelIsSanctioned(ALevel: Byte): Boolean;
function IsSanctionAccess(ASancNumber: Integer): Boolean;
function IsSanctAccess(ASancName: string): Boolean;
//function IsThisSign(P: PChar): Boolean;
function IsSigned(var P: TPayRec; RecLen: Integer): Boolean;
function LetterTextVarLen(LetterPtr: Pointer; RecLen: Integer): Integer;
procedure LetterTextPar(LetterPtr: Pointer; var TextBuf: PChar;
  var TextLen: Integer);
function LetterIsSigned(LetterPtr: Pointer; RecLen: Integer): Boolean;
function InitBasicBase(OpenVal, OpenFileBases: Boolean): Boolean;
procedure DoneBasicBase;
function GlobalBase(ABaseNumber: TBaseNumber): TExtBtrDataSet;
function GetUserByOperNum(OperNum: Integer; var AUserRec: TUserRec): Boolean;
function CurrentUser(var AUserRec: TUserRec): Boolean;
function MakeUserList(var List1, List2, List3: string): Integer;
function ClientGetLoginNameProc(Login: string; var Status: Integer;
  var UserName: string): Boolean; stdcall;
{function CurrentFirm(var AFirmRec: TFirmRec;
  var AFirmAccRec: TFirmAccRec): Boolean;}
procedure TakeMenuItems(Source, Dest: TMenuItem);
{function ExchangeStateToStr(AState: Word): string;}
{procedure MakeRegNumber(var Number: Integer);}
function GetDocOp(var Bill: TOpRec; DocId: Longint): Integer;
function UpdateClient(Acc: string; Bik: Integer; Name, Inn, Kpp: string;
  DosCharset, UpdateKpp: Boolean; ModIndex: Integer;
  OldAcc: string; OldBik: Integer; OldInn: string): Boolean;
function TestAcc(CodeS, KsS, AccS: string; EndMes: string;
  Ask: Boolean): Boolean;
function TestPaydoc(var PayRec: TPayRec; Ask: Boolean): Boolean;
function DocInfo(var PayRec: TPayRec): string;
function FillClientList(List: TStrings; ActDate: Word; Max: Integer): Boolean;
function GetLastClosedDay: Word;
function GetFirstOpenDay: Word;
function GetPrevWorkDay(ADay: Word; Acc: PChar): Word;
function GetFullBankByBik(Bik: Integer; DosCharset: Boolean;
  var FullBank: TBankFullNewRec): Boolean;
function IsPayDocExist(DocDataSet: TExtBtrDataSet; SelfOutID: Integer; Number: string; DocDate: Word; VO, Sum: Comp): Boolean;

implementation

{procedure TExtBtrDataSet.DoBeforeClose;
begin
  FBtrBase.Close;
  inherited DoBeforeClose;
end;}

function FieldTypeToStr(AFieldType: TFieldType): string;
begin
  case AFieldType of
    ftString: Result := 'Строка';
    ftInteger: Result := 'Целое число';
    ftBoolean: Result := 'Переключатель';
    ftFloat: Result := 'Дробное число';
    ftDate: Result := 'Дата';
    else Result := 'Неизвестный';
  end;
end;

(*function ParamValueToStr(var ParamRec: TParamRec): string;
begin
  with ParamRec do
    case pmType of
      ftString: Result := StrPas(@pmStrValue);
      ftInteger: Result := IntToStr(pmIntValue);
      ftBoolean: Result := BooleanToStr(pmBoolValue);
      ftFloat: Result := FloatToStr(pmFltValue);
      ftDate: Result := BtrDateToStr(pmDateValue);
      else Result := '-';
    end;
end;

function StrToParamValue(S: string; AType: TFieldType; var AValue): Boolean;
begin
  Result := True;
  case AType of
    ftString: StrPLCopy(@AValue, S, SizeOf(TStrValue));
    ftInteger: Integer(AValue) := StrToInt(S);
    ftBoolean: Boolean(AValue) := StrToBoolean(S);
    ftFloat: Double(AValue) := StrToFloat(S);
    ftDate: Word(AValue) := StrToBtrDate(S);
    else Result := False;
  end;
end;*)

{function IsThisSign(P: PChar): Boolean;
begin
  Result := (P[0]=Chr($1A)) and (P[SignSize-1]=Chr($1A))
end;}

function IsSigned(var P: TPayRec; RecLen: Integer): Boolean;
begin
  {Result := IsThisSign(@P.dbDoc.drVar[P.dbDocVarLen]);}
  {Result := CheckSign(@P.dbDoc, SizeOf(TDocRec)-drMaxVar+P.dbDocVarLen,
    RecLen-(SizeOf(TPayRec)-SizeOf(TDocRec)), 0, nil)>0;}
  Result := SizeOf(TDocRec)-drMaxVar+P.dbDocVarLen<RecLen
    -(SizeOf(TPayRec)-SizeOf(TDocRec));
end;

function LetterTextVarLen(LetterPtr: Pointer; RecLen: Integer): Integer;
begin
  if (PLetterRec(LetterPtr)^.lrState and dsExtended)=0 then
  begin
    Result := RecLen-(SizeOf(TEMailRec)-erMaxVar);
  end
  else begin
    Result := RecLen-(SizeOf(TLetterRec)-erMaxVar);
  end;
end;

procedure LetterTextPar(LetterPtr: Pointer; var TextBuf: PChar;
  var TextLen: Integer);
begin
  if (PLetterRec(LetterPtr)^.lrState and dsExtended)=0 then
  begin
    TextBuf := @PEMailRec(LetterPtr)^.erText;
    TextLen := StrLen(TextBuf)+1;
    TextLen := TextLen + StrLen(@TextBuf[TextLen])+1;
  end
  else begin
    TextBuf := @PLetterRec(LetterPtr)^.lrText;
    TextLen := PLetterRec(LetterPtr)^.lrTextLen;
  end;
  if TextLen>erMaxVar then
    TextLen := erMaxVar;
end;

function LetterIsSigned(LetterPtr: Pointer; RecLen: Integer): Boolean;
var
  TextBuf: PChar;
  TextLen: Integer;
begin
  LetterTextPar(LetterPtr, TextBuf, TextLen);
  Result := TextLen<LetterTextVarLen(LetterPtr, RecLen);
  {Result := CheckSign(@LetterRec.lrText, I, SizeOf(LetterRec), 0, nil)>0;}
end;

const
  FUserNumber: Integer = -1;
  FFirmNumber: Integer = -1;
  FGlobalBases: TList = nil;

function GlobalBase(ABaseNumber: TBaseNumber): TExtBtrDataSet;
begin
  Result := nil;
  if (FGlobalBases<>nil) and (Ord(ABaseNumber)<FGlobalBases.Count) then
    Result := TExtBtrDataSet(FGlobalBases.Items[Ord(ABaseNumber)]);
end;

{ TParamDataSet }


(*constructor TParamDataSet.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  BufSize := SizeOf(TParamRec)+64;
end;

procedure TParamDataSet.InternalInitFieldDefs;
begin
  FieldDefs.Clear;
  TFieldDef.Create(FieldDefs,'pmSect', ftInteger, 0, False, 0);
  TFieldDef.Create(FieldDefs,'pmNumber', ftInteger, 0, False, 1);
  TFieldDef.Create(FieldDefs,'pmIdent', ftString, SizeOf(TParamIdent), False, 2);
  TFieldDef.Create(FieldDefs,'pmName', ftString, SizeOf(TParamName), False, 3);
  TFieldDef.Create(FieldDefs,'pmMeasure', ftString, SizeOf(TParamMeasure), False, 4);
  TFieldDef.Create(FieldDefs,'pmLevel', ftInteger, 0, False, 5);
  TFieldDef.Create(FieldDefs,'pmType', ftString, 20, False, 6);
  TFieldDef.Create(FieldDefs,'pmValue', ftString, SizeOf(TStrValue), False, 7);
end;

function TParamDataSet.GetFieldData(Field: TField; Buffer: Pointer): Boolean;
begin
  Result := True;
  with PParamRec(ActiveBuffer)^ do
  begin
    case Field.Index of
      0: PInteger(Buffer)^ := pmSect;
      1: PInteger(Buffer)^ := pmNumber;
      2: StrLCopy(Buffer, pmIdent, Field.DataSize-1);
      3: StrLCopy(Buffer, pmName, Field.DataSize-1);
      4: StrLCopy(Buffer, pmMeasure, Field.DataSize-1);
      5: PInteger(Buffer)^ := pmLevel;
      6: StrPLCopy(Buffer, FieldTypeToStr(pmType), Field.DataSize-1);
      7: StrPLCopy(Buffer, ParamValueToStr(PParamRec(ActiveBuffer)^),
        Field.DataSize-1);
    end;
  end;
end;*)

{ TModuleDataSet }

constructor TModuleDataSet.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  BufSize := SizeOf(TModuleRec)+64;
end;

procedure TModuleDataSet.InternalInitFieldDefs;
begin
  FieldDefs.Clear;
  TFieldDef.Create(FieldDefs,'mrKind', ftInteger, 0, False, 0);
  TFieldDef.Create(FieldDefs,'mrIder', ftInteger, 0, False, 1);
  TFieldDef.Create(FieldDefs,'mrLevel', ftInteger, 0, False, 2);
  TFieldDef.Create(FieldDefs,'mrName', ftString, SizeOf(TModuleName), False, 3);
  TFieldDef.Create(FieldDefs,'mrSign', ftString, 3, False, 4);
end;

function TModuleDataSet.GetFieldData(Field: TField; Buffer: Pointer): Boolean;
begin
  Result := True;
  with PModuleRec(ActiveBuffer)^ do
  begin
    case Field.Index of
      0: PInteger(Buffer)^ := mrKind;
      1: PInteger(Buffer)^ := mrIder;
      2: PInteger(Buffer)^ := mrLevel;
      3: StrLCopy(Buffer, mrName, Field.DataSize-1);
      4: StrPLCopy(Buffer, {BooleanToStr(IsThisSign(mrSign))}'-', Field.DataSize-1)
    end;
  end;
end;

{ TUserDataSet }

constructor TUserDataSet.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  BufSize := SizeOf(TUserRec)+32;
end;

procedure TUserDataSet.InternalInitFieldDefs;
begin
  FieldDefs.Clear;
  TFieldDef.Create(FieldDefs,'urNumber', ftInteger, 0, False, 0);
  TFieldDef.Create(FieldDefs,'urLogin', ftString, SizeOf(TUserLogin), False, 1);
  TFieldDef.Create(FieldDefs,'urLevel', ftInteger, 0, False, 2);
  TFieldDef.Create(FieldDefs,'urFirmNumber', ftInteger, 0, False, 3);
  TFieldDef.Create(FieldDefs,'urName', ftString, SizeOf(TUserInfo), False, 4);
  TFieldDef.Create(FieldDefs,'urDir', ftString, SizeOf(TUserInfo), False, 5);
end;

function TUserDataSet.GetFieldData(Field: TField; Buffer: Pointer): Boolean;
type
  PInteger = ^Integer;
begin
  Result := False;
  with PUserRec(ActiveBuffer)^ do
  begin
    if not IsEmpty then
    begin
      Result := True;
      case Field.Index of
        0: PInteger(Buffer)^ := urNumber;
        1: StrLCopy(Buffer, urLogin, Field.DataSize-1);
        2: PInteger(Buffer)^ := urLevel;
        3: PInteger(Buffer)^ := urFirmNumber;
        4: StrLCopy(Buffer, urInfo, Field.DataSize-1);
        5: StrLCopy(Buffer, @urInfo[StrLen(urInfo)+1], Field.DataSize-1);
      end;
    end;
  end;
end;

{ TAccessDataSet }
(*
constructor TAccessDataSet.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  BufSize := SizeOf(TAccessRec)+64;
end;

procedure TAccessDataSet.InternalInitFieldDefs;
begin
  FieldDefs.Clear;
  TFieldDef.Create(FieldDefs,'asUserNumber', ftInteger, 0, False, 0);
  TFieldDef.Create(FieldDefs,'asFirmNumber', ftInteger, 0, False, 1);
end;

function TAccessDataSet.GetFieldData(Field: TField; Buffer: Pointer): Boolean;
type
  PInteger = ^Integer;
begin
  Result := True;
  with PAccessRec(ActiveBuffer)^ do
  begin
    case Field.Index of
      0: PInteger(Buffer)^ := asUserNumber;
      1: PInteger(Buffer)^ := asFirmNumber;
    end;
  end;
end; *)

{ TSanctionDataSet }

constructor TSanctionDataSet.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  BufSize := SizeOf(TSanctionRec)+64;
end;

procedure TSanctionDataSet.InternalInitFieldDefs;
begin
  FieldDefs.Clear;
  TFieldDef.Create(FieldDefs,'snUserNumber', ftInteger, 0, False, 0);
  TFieldDef.Create(FieldDefs,'snSancNumber', ftInteger, 0, False, 1);
end;

function TSanctionDataSet.GetFieldData(Field: TField; Buffer: Pointer): Boolean;
type
  PInteger = ^Integer;
begin
  Result := True;
  with PSanctionRec(ActiveBuffer)^ do
  begin
    case Field.Index of
      0: PInteger(Buffer)^ := snUserNumber;
      1: PInteger(Buffer)^ := snSancNumber;
    end;
  end;
end;

(*{ TFirmAccDataSet }

constructor TFirmAccDataSet.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  BufSize := SizeOf(TFirmAccRec)+128;
end;

procedure TFirmAccDataSet.InternalInitFieldDefs;
begin
  FieldDefs.Clear;
  TFieldDef.Create(FieldDefs, 'faNumber', ftInteger, 0, False, 0);
  TFieldDef.Create(FieldDefs, 'faName', ftString, SizeOf(TAccName), False, 1);
  TFieldDef.Create(FieldDefs, 'faAcc', ftString, SizeOf(TAccount), False, 2);
end;

function TFirmAccDataSet.GetFieldData(Field: TField; Buffer: Pointer): Boolean;
begin
  Result := False;
  with PFirmAccRec(ActiveBuffer)^ do
    if not IsEmpty then
    begin
      Result := True;
      case Field.Index of
        0: PInteger(Buffer)^ := faNumber;
        1: StrLCopy(Buffer, faAccName, Field.DataSize-1);
        2: StrLCopy(Buffer, faAcc, Field.DataSize-1);
      end;
    end;
end;

{ TFirmDataSet }

constructor TFirmDataSet.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  BufSize := SizeOf(TFirmRec)+64;
end;

procedure TFirmDataSet.InternalInitFieldDefs;
begin
  FieldDefs.Clear;
  TFieldDef.Create(FieldDefs, 'frNumber', ftInteger, 0, False, 0);
  TFieldDef.Create(FieldDefs, 'frInn', ftString, SizeOf(TInn), False, 1);
  TFieldDef.Create(FieldDefs, 'frKpp', ftString, SizeOf(TInn), False, 2);
  TFieldDef.Create(FieldDefs, 'frName', ftString, SizeOf(TFirmName), False, 3);
  TFieldDef.Create(FieldDefs, 'frAccNumber', ftInteger, 0, False, 4);
  TFieldDef.Create(FieldDefs, 'frDir', ftString, SizeOf(TFirmDir), False, 5);
end;

function TFirmDataSet.GetFieldData(Field: TField; Buffer: Pointer): Boolean;
var
  I: Integer;
begin
  Result := False;
  with PFirmRec(ActiveBuffer)^ do
    if not IsEmpty then
    begin
      Result := True;
      case Field.Index of
        0: PInteger(Buffer)^ := frNumber;
        1: StrLCopy(Buffer, frInn, Field.DataSize-1);
        2: StrLCopy(Buffer, frKpp, Field.DataSize-1);
        3:
          begin
            I:=0;
            while (I<SizeOf(TFirmName)) and (frName[I]<>#13)
              and (frName[I]<>#0) do Inc(I);
            StrLCopy(Buffer, frName, I);
          end;
        4: PInteger(Buffer)^ := frAccNumber;
        5: StrLCopy(Buffer, frDir, Field.DataSize-1);
      end;
    end;
end; *)

{ TAccDataSet }

constructor TAccDataSet.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  BufSize := SizeOf(TAccRec)+64;
end;

const
  AccTypeNames: array[0..2] of PChar = ('П', 'А', 'А-П');

procedure TAccDataSet.InternalInitFieldDefs;
begin
  FieldDefs.Clear;
  TFieldDef.Create(FieldDefs,'arIder',ftInteger,0,False,0);
  TFieldDef.Create(FieldDefs,'arAccount',ftString, SizeOf(TAccount), False, 1);
  TFieldDef.Create(FieldDefs,'arCorr',ftInteger,0,False,2);
  TFieldDef.Create(FieldDefs,'arVersion',ftInteger,0,False,3);
  TFieldDef.Create(FieldDefs,'arDateO',ftString, DateStrLen, False,4);
  TFieldDef.Create(FieldDefs,'arDateC',ftString, DateStrLen, False,5);
  TFieldDef.Create(FieldDefs,'arOpts', ftString, 3, False,6);
  TFieldDef.Create(FieldDefs,'arSumA',ftString, SumStrLen, False, 7);
  TFieldDef.Create(FieldDefs,'arSumS',ftString, SumStrLen, False, 8);
  TFieldDef.Create(FieldDefs,'arName',ftString, SizeOf(TKeeperName), False,9);
end;

function TAccDataSet.GetFieldData(Field: TField; Buffer: Pointer): Boolean;
begin
  Result := False;
  with PAccRec(ActiveBuffer)^ do
    if not IsEmpty then
    begin
      Result := True;
      case Field.Index of
        0: PInteger(Buffer)^ := arIder;
        1: StrLCopy(Buffer, arAccount, Field.DataSize-1);
        2: PInteger(Buffer)^ := arCorr;
        3: PInteger(Buffer)^ := arVersion;
        4: StrPLCopy(Buffer, BtrDateToStr(arDateO), Field.DataSize-1);
        5: StrPLCopy(Buffer, BtrDateToStr(arDateC), Field.DataSize-1);
        6: StrLCopy(Buffer, AccTypeNames[arOpts and 3], Field.DataSize-1);
        7: StrPLCopy(Buffer, SumToStr(arSumA), Field.DataSize-1);
        8: StrPLCopy(Buffer, SumToStr(arSumS), Field.DataSize-1);
        9:
        begin
          StrLCopy(Buffer, @(arName), Field.DataSize-1);
          DosToWin(Buffer);
        end;
      end;
    end;
end;

{ TAccArcDataSet }

constructor TAccArcDataSet.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  BufSize := SizeOf(TAccArcRec)+64;
end;

procedure TAccArcDataSet.InternalInitFieldDefs;
begin
  FieldDefs.Clear;
  TFieldDef.Create(FieldDefs,'aaIder', ftInteger, 0, False, 0);
  TFieldDef.Create(FieldDefs,'aaAccount', ftString, SizeOf(TAccount), False, 1);
  TFieldDef.Create(FieldDefs,'aaDate', ftString, DateStrLen, False, 2);
  TFieldDef.Create(FieldDefs,'aaSum', ftString, SumStrLen, False, 3);
end;

function TAccArcDataSet.GetFieldData(Field: TField; Buffer: Pointer): Boolean;
var
  AccDataSet: TExtBtrDataSet;
begin
  Result := true;
  with PAccArcRec(ActiveBuffer)^ do begin
    case Field.Index of
      0: PInteger(Buffer)^ := aaIder;
      1:
        begin
          AccDataSet := GlobalBase(biAcc);
          if AccDataSet<>nil then
            with AccDataSet do
            begin
              if LocateBtrRecordByIndex(aaIder, 0, bsEq) then
                StrLCopy(Buffer, PAccRec(ActiveBuffer)^.arAccount, Field.DataSize-1)
              else
                StrCopy(Buffer, '-');
            end;
        end;
      2: StrPLCopy(Buffer, BtrDateToStr(PAccArcRec(ActiveBuffer)^.aaDate), Field.DataSize-1);
      3: StrPLCopy(Buffer, SumToStr(PAccArcRec(ActiveBuffer)^.aaSum), Field.DataSize-1);
    end;
  end;
end;

{ TNpDataSet }

constructor TNpDataSet.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  BufSize := SizeOf(TNpRec)+12;
end;

procedure TNpDataSet.InternalInitFieldDefs;
begin
  FieldDefs.Clear;
  TFieldDef.Create(FieldDefs,'npIder', ftLargeInt, 0, False, 0);
  TFieldDef.Create(FieldDefs,'npName', ftString, SizeOf(TSity)
    +SizeOf(TSityType)+1, False, 1);
end;

function TNpDataSet.GetFieldData(Field: TField; Buffer: Pointer): Boolean;
begin
  Result := true;
  with PNpRec(ActiveBuffer)^ do
    case Field.Index of
      0: PInt64(Buffer)^ := npIder;
      1:
      begin
        if StrLen(npType)>0 then
        begin
          StrLCopy(Buffer, npType, SizeOf(TSityType));
          StrCat(Buffer, ' ');
        end
        else
          StrCopy(Buffer, '');
        StrLCat(Buffer, npName, SizeOf(TSity));
        DosToWin(Buffer);
      end;
    end;
end;

{ TBankDataSet }

constructor TBankDataSet.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  BufSize := SizeOf(TBankNewRec)+32;
end;

procedure TBankDataSet.InternalInitFieldDefs;
begin
  FieldDefs.Clear;
  TFieldDef.Create(FieldDefs,'brCod', ftString, 9, False, 0);
  TFieldDef.Create(FieldDefs,'brKs', ftString, SizeOf(TAccount), False, 1);
  TFieldDef.Create(FieldDefs,'brName', ftString, SizeOf(TBankNameNew)+1,
    False, 2);
  TFieldDef.Create(FieldDefs,'npName', ftString, SizeOf(TSity)
    +SizeOf(TSityType)+1, False, 3);
end;

function TBankDataSet.GetFieldData(Field: TField; Buffer: Pointer): Boolean;
var
  I: LongInt;
  FNpDataSet: TExtBtrDataSet;
begin
  Result := False;
  with PBankNewRec(ActiveBuffer)^ do
    if not IsEmpty then
    begin
      Result := True;
      case Field.Index of
        0: StrPLCopy(Buffer, FillZeros(brCod, 9), Field.DataSize-1);
        1: StrLCopy(Buffer, brKs, Field.DataSize-1);
        2:
        begin
          {if StrLen(brType)>0 then
          begin
            StrLCopy(Buffer, @brType, SizeOf(TBankType));
            StrCat(Buffer, ' ');
          end
          else
            StrCopy(Buffer, '');}
          StrLCopy(Buffer, @brName, SizeOf(TBankNameNew));
          DosToWin(Buffer);
        end;
        3: begin
          I := brNpIder;
          FNpDataSet := GlobalBase(biNp);
          if FNpDataSet.LocateBtrRecordByIndex(I,0,bsEq) then
            StrPLCopy(Buffer, FNpDataSet.Fields.Fields[1].AsString,
              Field.DataSize-1)
          else
            StrPLCopy(Buffer, '<не найден>', Field.DataSize-1);
        end;
      end;
    end;
end;

{ TClientDataSet }

constructor TClientDataSet.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  BufSize := SizeOf(TNewClientRec)+64;
end;

procedure TClientDataSet.InternalInitFieldDefs;
begin
  FieldDefs.Clear;
  TFieldDef.Create(FieldDefs,'clAccC', ftString, SizeOf(TAccount), False,0);
  TFieldDef.Create(FieldDefs,'clCodeB', ftString, 9, False, 1);
  TFieldDef.Create(FieldDefs,'clInn', ftString, SizeOf(TInn), False, 2);
  TFieldDef.Create(FieldDefs,'clKpp', ftString, SizeOf(TInn), False, 3);
  TFieldDef.Create(FieldDefs,'clNameC', ftString, SizeOf(TClientName), False, 4);
end;

function TClientDataSet.GetFieldData(Field: TField; Buffer: Pointer): Boolean;
var
  I: integer;
begin
  Result := False;
  with PNewClientRec(ActiveBuffer)^ do
    if not IsEmpty then
    begin
      Result := True;
      case Field.Index of
        0: StrLCopy(Buffer, clAccC, Field.DataSize-1);
        1: StrPLCopy(Buffer, FillZeros(clCodeB, 9), Field.DataSize-1);
        2: StrLCopy(Buffer, clInn, Field.DataSize-1);
        3: StrLCopy(Buffer, clKpp, Field.DataSize-1);
        4:
          begin
            I := 0;
            while (I<clMaxVar) and (clNameC[I]<>#13)
              and (clNameC[I]<>#0) do Inc(I);
            StrLCopy(Buffer, @clNameC, I);
            DosToWin(Buffer);
          end;
      end;
    end;
end;

{ TLetterDataSet }

constructor TLetterDataSet.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  BufSize := SizeOf(TLetterRec)+16;
end;

procedure TLetterDataSet.InternalInitFieldDefs;
begin
  FieldDefs.Clear;
  TFieldDef.Create(FieldDefs, 'erIder', ftInteger, 0, False, 0);
  TFieldDef.Create(FieldDefs, 'erIdKorr', ftInteger, 0, False, 1);
  TFieldDef.Create(FieldDefs, 'erSender', ftInteger, 0, False, 2);
  TFieldDef.Create(FieldDefs, 'erIdCurO', ftInteger, 0, False, 3);
  TFieldDef.Create(FieldDefs, 'erIdArcO', ftInteger, 0, False, 4);
  TFieldDef.Create(FieldDefs, 'erIdCurI', ftInteger, 0, False, 5);
  TFieldDef.Create(FieldDefs, 'erIdArcI', ftInteger, 0, False, 6);
  TFieldDef.Create(FieldDefs, 'erState', ftString, 15, False, 7);
  TFieldDef.Create(FieldDefs, 'erAdr', ftInteger, 0, False, 8);
  TFieldDef.Create(FieldDefs, 'erCapt', ftString, 256, False, 9);
  TFieldDef.Create(FieldDefs, 'erMes', ftString, {erMaxVar}1023, False, 10);
  {TFieldDef.Create(FieldDefs, 'erAdrName', ftString, 8, False, 11);}
end;

function TLetterDataSet.GetFieldData(Field: TField; Buffer: Pointer): Boolean;
var
  S: string;
  TxtBuf: PChar;
  I: Integer;
begin
  Result := False;
  with PLetterRec(ActiveBuffer)^ do
    if not IsEmpty then
    begin
      Result := True;
      case Field.Index of
        0: PInteger(Buffer)^ := lrIder;
        1: PInteger(Buffer)^ := lrIdKorr;
        2: PInteger(Buffer)^ := lrSender;
        3: PInteger(Buffer)^ := lrIdCurO;
        4: PInteger(Buffer)^ := lrIdArcO;
        5: PInteger(Buffer)^ := lrIdCurI;
        6: PInteger(Buffer)^ := lrIdArcI;
        7:
          begin
            S := '';
            if lrState and dsDoneType = dsDoneReturn then
              S := 'ош.подп.'
            else
              case lrState and dsSndType of
                dsSndEmpty:
                  begin
                    {I := StrLen(erText)+1;
                    I := I + StrLen(@erText[I])+1;}
                    if LetterIsSigned(ActiveBuffer,
                      GetActiveRecLen)
                    then
                      S := 'подписано'
                  end;
                dsSndSent:
                  S := 'отправлено';
                dsSndRcv:
                  if lrIdKorr=0 then
                    S := 'принято'
                  else
                    S := 'получено';
              end;
            StrPLCopy(Buffer, S, Field.DataSize-1);
          end;
        8: PInteger(Buffer)^ := lrAdr;
        9:
          begin
            if (lrState and dsExtended)=0 then
              StrLCopy(Buffer, lrText-2, Field.DataSize-1)
            else
              StrLCopy(Buffer, lrText, Field.DataSize-1);
            DosToWin(Buffer);
          end;
        10:
          begin
            if (lrState and dsEncrypted)=0 then
            begin
              if (lrState and dsExtended)=0 then
                TxtBuf := lrText-2
              else
                TxtBuf := lrText;
              I := StrLen(TxtBuf)+1;
              StrLCopy(Buffer, @TxtBuf[I], Field.DataSize-1);
              DosToWin(Buffer);
            end
            else
              StrLCopy(Buffer, '<зашифровано>', Field.DataSize-1);
          end;
      end;
    end;
end;

{ TFileDataSet }

constructor TFileDataSet.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  BufSize := SizeOf(TFilePieceRec)+64;
end;

procedure TFileDataSet.InternalInitFieldDefs;
begin
  FieldDefs.Clear;
  TFieldDef.Create(FieldDefs, 'fpIdent', ftInteger, 0, False, 0);
  TFieldDef.Create(FieldDefs, 'fpIndex', ftInteger, 0, False, 1);
  TFieldDef.Create(FieldDefs, 'fpType', ftString, 8, False, 2);
  TFieldDef.Create(FieldDefs, 'fpName', ftString, 255, False, 3);
end;

function TFileDataSet.GetFieldData(Field: TField; Buffer: Pointer): Boolean;
var
  L: Integer;
begin
  Result := False;
  with PFilePieceRec(ActiveBuffer)^ do
    if not IsEmpty then
    begin
      Result := True;
      case Field.Index of
        0: PInteger(Buffer)^ := fpIdent;
        1: PInteger(Buffer)^ := fpIndex;
        2:
          begin
            L := StrLen(@fpVar[0]);
            if L>0 then
              L := Byte(fpVar[L+1]);
            case L of
              0: StrLCopy(Buffer, 'файл', Field.DataSize-1);
              1: StrLCopy(Buffer, 'модуль', Field.DataSize-1);
              else StrLCopy(Buffer, 'неизв.', Field.DataSize-1);
            end;
          end;
        3: StrLCopy(Buffer, @fpVar[0], Field.DataSize-1);
      end;
    end;
end;

//Добавлено Меркуловым
{ TSFileDataSet }

constructor TSFileDataSet.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  BufSize := SizeOf(TFilePieceRec)+64;
end;

procedure TSFileDataSet.InternalInitFieldDefs;
begin
  FieldDefs.Clear;
  TFieldDef.Create(FieldDefs, 'fpIdent', ftInteger, 0, False, 0);
  TFieldDef.Create(FieldDefs, 'fpIndex', ftInteger, 0, False, 1);
  TFieldDef.Create(FieldDefs, 'fpType', ftString, 8, False, 2);
  TFieldDef.Create(FieldDefs, 'fpName', ftString, 255, False, 3);
end;

function TSFileDataSet.GetFieldData(Field: TField; Buffer: Pointer): Boolean;
//var
 // L: Integer;
  //ASFileDataSet: TExtBtrDataSet;
begin
  Result := False;
//  ASFileDataSet := Globalbase(biSFile);
  with PFilePieceRec(ActiveBuffer)^ do
    if not IsEmpty then
    begin

      {if LocateBtrRecordByIndex(fpIdent, 1, bsEq) then
      begin
        L := fpIdent;
       // GetBtrRecord(@Bill);
        while not EoF and (fpIdent=L) do
        begin
          Inc(fpIndex);
          Next;
          GetBtrRecord(@ASFileDataSet);
        end;
      end;}

      Result := True;
      case Field.Index of
        0: PInteger(Buffer)^ := fpIdent;
        1: PInteger(Buffer)^ := fpIndex;
        2: StrLCopy(Buffer, 'принят', Field.DataSize-1);
          {begin
            L := StrLen(@fpVar[0]);
            if L>0 then
              L := Byte(fpVar[L+1]);
            case L of
              0: StrLCopy(Buffer, 'файл', Field.DataSize-1);
              1: StrLCopy(Buffer, 'модуль', Field.DataSize-1);
              else StrLCopy(Buffer, 'неизв.', Field.DataSize-1);
            end;
          end;}
        3: StrLCopy(Buffer, @fpVar[0], Field.DataSize-1);
      end;
    end;
end;

{ TLFileDataSet }

constructor TLFileDataSet.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  BufSize := SizeOf(TFilePieceRec)+64;
end;

procedure TLFileDataSet.InternalInitFieldDefs;
begin
  FieldDefs.Clear;
  TFieldDef.Create(FieldDefs, 'fpIdent', ftInteger, 0, False, 0);
  TFieldDef.Create(FieldDefs, 'fpIndex', ftInteger, 0, False, 1);
  TFieldDef.Create(FieldDefs, 'fpType', ftString, 8, False, 2);
  TFieldDef.Create(FieldDefs, 'fpName', ftString, 255, False, 3);
end;

function TLFileDataSet.GetFieldData(Field: TField; Buffer: Pointer): Boolean;
var
  L: Integer;
begin
  Result := False;
  with PFilePieceRec(ActiveBuffer)^ do
    if not IsEmpty then
    begin
      Result := True;
      case Field.Index of
        0: PInteger(Buffer)^ := fpIdent;
        1: PInteger(Buffer)^ := fpIndex;
        2:
          begin
            L := StrLen(@fpVar[0]);
            if L>0 then
              L := Byte(fpVar[L+1]);
            case L of
              0: StrLCopy(Buffer, 'готов', Field.DataSize-1);
              1: StrLCopy(Buffer, 'отпр.', Field.DataSize-1);
              2: StrLCopy(Buffer, 'принят', Field.DataSize-1);
              else StrLCopy(Buffer, 'неизв.', Field.DataSize-1);
            end;
          end;
        3: StrLCopy(Buffer, @fpVar[0], Field.DataSize-1);
      end;
    end;
end;


{ TBillDataSet }

constructor TBillDataSet.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  BufSize := SizeOf(TOpRec)+64;
end;

procedure TBillDataSet.InternalInitFieldDefs;
begin
  FieldDefs.Clear;
  TFieldDef.Create(FieldDefs, 'brIder', ftInteger, 0, False, 0);
  TFieldDef.Create(FieldDefs, 'brDocId', ftInteger, 0, False, 1);
  TFieldDef.Create(FieldDefs, 'brDate', ftString, DateStrLen, False, 2);
  TFieldDef.Create(FieldDefs, 'brVersion', ftInteger, 0, False, 3);
  TFieldDef.Create(FieldDefs, 'brState', ftString, 15, False, 4);
  TFieldDef.Create(FieldDefs, 'brDel', ftString, 12, False, 5);
  TFieldDef.Create(FieldDefs, 'brPrizn', ftInteger, 0, False, 6);

  TFieldDef.Create(FieldDefs, 'brType', ftInteger, 0, False, 7);
  TFieldDef.Create(FieldDefs, 'brNumber', ftInteger, 0, False, 8);
  TFieldDef.Create(FieldDefs, 'brAccD', ftString, SizeOf(TAccount), False, 9);
  TFieldDef.Create(FieldDefs, 'brAccC', ftString, SizeOf(TAccount), False, 10);
  TFieldDef.Create(FieldDefs, 'brSum', ftString, SumStrLen, False, 11);
  TFieldDef.Create(FieldDefs, 'brText', ftString, brMaxText, False, 12);
  TFieldDef.Create(FieldDefs, 'brRet', ftString, brMaxRet, False, 13);
end;

function TBillDataSet.GetFieldData(Field: TField; Buffer: Pointer): Boolean;
begin
  Result := False;
  with POpRec(ActiveBuffer)^ do
    if not IsEmpty then
    begin
      Result := True;
      case Field.Index of
        0: PInteger(Buffer)^ := brIder;
        1: PInteger(Buffer)^ := brDocId;
        2: StrPLCopy(Buffer, BtrDateToStr(brDate), Field.DataSize-1);
        3: PInteger(Buffer)^ := brVersion;
        4:
          begin
            if brPrizn=brtReturn then
            begin
              StrPLCopy(Buffer, 'возвр', Field.DataSize-1);
            end
            else
              if brPrizn=brtKart then
                StrPLCopy(Buffer, 'карт', Field.DataSize-1)
              else
                if brPrizn=brtBill then
                begin
                  StrPLCopy(Buffer, 'пров', Field.DataSize-1)
                end;
          end;
        5:
          if brDel = 0 then
            StrLCopy(Buffer, 'активен', Field.DataSize-1)
          else
            StrLCopy(Buffer, 'удален', Field.DataSize-1);
        6: PInteger(Buffer)^ := brPrizn;
        7: if brPrizn=brtBill then
             PInteger(Buffer)^ := brType
           else
             PInteger(Buffer)^ := 0;
        8: if brPrizn=brtBill then
             PInteger(Buffer)^ := brNumber
           else
             PInteger(Buffer)^ := 0;
        9: if brPrizn=brtBill then
             StrPLCopy(Buffer, brAccD, SizeOf(TAccount))
           else
             StrPCopy(Buffer, '-');
        10: if brPrizn=brtBill then
              StrPLCopy(Buffer, brAccC, SizeOf(TAccount))
            else
              StrPCopy(Buffer, '-');
        11: if brPrizn=brtBill then
              StrPLCopy(Buffer, SumToStr(brSum), Field.DataSize-1)
            else
              StrPCopy(Buffer, '-');
        12:
        if brPrizn=brtBill then
        begin
          StrPLCopy(Buffer, brText, Field.DataSize-1);
          DosToWin(Buffer);
        end
        else
          StrPCopy(Buffer, '-');
        13:
          if brPrizn=brtReturn then
          begin
            StrPLCopy(Buffer, brRet, Field.DataSize-1);
            DosToWin(Buffer);
          end
          else
            if brPrizn=brtKart then
            begin
              StrPLCopy(Buffer, brKart, Field.DataSize-1);
              DosToWin(Buffer);
            end
            else
              StrPCopy(Buffer, '-');
      end;
    end;
end;

{ TPayDataSet }

constructor TPayDataSet.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  BufSize := SizeOf(TPayRec)+128;
end;

procedure TPayDataSet.InternalInitFieldDefs;
begin
  FieldDefs.Clear;

  TFieldDef.Create(FieldDefs,'IdHere',ftInteger,0,False,0);
  TFieldDef.Create(FieldDefs,'IdKorr',ftInteger,0,False,1);
  TFieldDef.Create(FieldDefs,'IdIn',ftInteger,0,False,2);
  TFieldDef.Create(FieldDefs,'IdOut',ftInteger,0,False,3);
  TFieldDef.Create(FieldDefs,'IdArc',ftInteger,0,False,4);
  TFieldDef.Create(FieldDefs,'IdDel',ftInteger,0,False,5);
  TFieldDef.Create(FieldDefs,'Version',ftInteger,0,False,6);
  TFieldDef.Create(FieldDefs,'State',ftString, 11, False,7);
  TFieldDef.Create(FieldDefs,'DateS',ftString, DateStrLen, False,8);
  TFieldDef.Create(FieldDefs,'TimeS',ftWord,0,False,9);
  TFieldDef.Create(FieldDefs,'DateR',ftString, DateStrLen, False,10);
  TFieldDef.Create(FieldDefs,'TimeR',ftWord,0,False,11);
  TFieldDef.Create(FieldDefs,'DateP',ftString, DateStrLen, False,12);
  TFieldDef.Create(FieldDefs,'TimeP', ftWord, 0, False, 13);
  TFieldDef.Create(FieldDefs,'DocLen', ftWord, 0, False, 14);

  TFieldDef.Create(FieldDefs,'drDate',ftString, DateStrLen, False, 15);
  TFieldDef.Create(FieldDefs,'drSum', ftString, SumStrLen, False, 16);
  TFieldDef.Create(FieldDefs,'drSrok', ftString, DateStrLen, False, 17);
  TFieldDef.Create(FieldDefs,'drType', ftWord, 0, False, 18);
  TFieldDef.Create(FieldDefs,'drIsp',ftString, 10, False, 19);
  TFieldDef.Create(FieldDefs,'drOcher', ftWord, 0, False, 20);

  TFieldDef.Create(FieldDefs,'SumRus',ftString, 255, False, 21);
  TFieldDef.Create(FieldDefs,'DateOp', ftString, DateStrLen, False, 22);
  TFieldDef.Create(FieldDefs,'drVO', ftString, 2, False, 23);
  TFieldDef.Create(FieldDefs,'InputDate', ftString, DateStrLen, False, 24);

  TFieldDef.Create(FieldDefs,'DocNum',ftString, 5, False, 25);
  TFieldDef.Create(FieldDefs,'Pacc',ftString, SizeOf(TAccount), False, 26);
  TFieldDef.Create(FieldDefs,'Pks',ftString, SizeOf(TAccount), False, 27);
  TFieldDef.Create(FieldDefs,'Pcode',ftString, 9, False, 28);
  TFieldDef.Create(FieldDefs,'PInn',ftString, SizeOf(TInn), False, 29);
  TFieldDef.Create(FieldDefs,'PName',ftString, 160, False, 30);
  TFieldDef.Create(FieldDefs,'PbName',ftString, 70, False, 31);
  TFieldDef.Create(FieldDefs,'Racc',ftString, SizeOf(TAccount), False, 32);
  TFieldDef.Create(FieldDefs,'Rks',ftString, SizeOf(TAccount), False, 33);
  TFieldDef.Create(FieldDefs,'Rcode',ftString, 9, False, 34);
  TFieldDef.Create(FieldDefs,'RInn',ftString, SizeOf(TInn), False, 35);
  TFieldDef.Create(FieldDefs,'RName',ftString, 160, False, 36);
  TFieldDef.Create(FieldDefs,'RbName',ftString, 70, False, 37);
  TFieldDef.Create(FieldDefs,'NaznP',ftString, 400, False, 38);
  TFieldDef.Create(FieldDefs,'PKpp', ftString, 9, False, 39);
  TFieldDef.Create(FieldDefs,'RKpp', ftString, 9, False, 40);
  TFieldDef.Create(FieldDefs,'NalPayer', ftString, 2, False, 41);
  TFieldDef.Create(FieldDefs,'Kbk', ftString, 20, False, 42);
  TFieldDef.Create(FieldDefs,'Okato', ftString, 11, False, 43);
  TFieldDef.Create(FieldDefs,'OsnPl', ftString, 160, False, 44);
  TFieldDef.Create(FieldDefs,'Period', ftString, 10, False, 45);
  TFieldDef.Create(FieldDefs,'NDoc', ftString, 15, False, 46);
  TFieldDef.Create(FieldDefs,'DocDate', ftString, 10, False, 47);
  TFieldDef.Create(FieldDefs,'Tp', ftString, 2, False, 48);
  TFieldDef.Create(FieldDefs,'Nchpl', ftString, 3, False, 49);
  TFieldDef.Create(FieldDefs,'Shifr', ftString, 3, False, 50);
  TFieldDef.Create(FieldDefs,'Nplat', ftString, 5, False, 51);
  TFieldDef.Create(FieldDefs,'OstSum', ftString, 15, False, 52);
  TFieldDef.Create(FieldDefs,'AcceptSr', ftString, DateStrLen, False, 53);
  TFieldDef.Create(FieldDefs,'SignMes', ftString, 40, False, 54);
  TFieldDef.Create(FieldDefs,'ReceiveMes', ftString, 51, False, 55);
  TFieldDef.Create(FieldDefs,'BillDate', ftString, DateStrLen, False, 56);
  TFieldDef.Create(FieldDefs,'OperName', ftString, OperNameLen, False, 57);
end;

{function ExchangeStateToStr(AState: Word): string;
begin
  Result := '';
  if dsExport and AState <> 0 then
    Result := Result + 'выгружен';
end;}

function GetDocOp(var Bill: TOpRec; DocId: Longint): Integer;
var
  ABillDataSet: TExtBtrDataSet;
  Res, Len, I: Integer;
begin
  Result := 0;
  ABillDataSet := GlobalBase(biBill);
  if ABillDataSet<>nil then
    with ABillDataSet do
    begin
      I := DocId;
      Len := SizeOf(Bill);
      Res := BtrBase.GetEqual(Bill, Len, I, 1);
      while (Res=0) and (Bill.brDocId=DocId) and (Bill.brDel<>0) do
      begin
        Len := SizeOf(Bill);
        Res := BtrBase.GetNext(Bill, Len, I, 1);
      end;
      if (Res=0) and (Bill.brDocId=DocId) and (Bill.brDel=0) then
        Result := Len;
      (*IndexNum := 1;
      First;
      if LocateBtrRecordByIndex(DocId, 1, bsEq) then
      begin
        GetBtrRecord(@Bill);
        while not EoF and (Bill.brDocId=DocId) and (Bill.brDel<>0) do
        begin
          Next;
          GetBtrRecord(@Bill);
        end;
        if not EoF then
          Result := Bill.brDocId=DocId;
      end; *)
    end;
end;

function GetDocOperName(DocId: Longint): string;
var
  ABillDataSet: TExtBtrDataSet;
  Bill: TOpRec;
  Res, Len, I: Integer;
  PBuf: PChar;
begin
  Result := '';
  if DocId<>0 then
  begin
    ABillDataSet := GlobalBase(biBill);  
    if ABillDataSet<>nil then
      with ABillDataSet do
      begin
        I := DocId;
        Len := SizeOf(Bill);
        Res := BtrBase.GetEqual(Bill, Len, I, 1);
        while (Res=0) and (I=DocId) and (Bill.brDel<>0) do
        begin
          Len := SizeOf(Bill);
          Res := BtrBase.GetNext(Bill, Len, I, 1);
        end;
        if (Res=0) and (I=DocId) and (Bill.brDel=0) then
        begin
          Res := 0;
          case Bill.brPrizn of
            brtBill:
              begin
                Res := Len - 70;
                PBuf := @Bill.brText;
              end;
            brtReturn:
              begin
                Res := Len - 17;
                PBuf := @Bill.brRet;
              end;
            brtKart:
              begin
                Res := Len - 17;
                PBuf := @Bill.brKart;
              end;
          end;
          if Res>0 then
          begin
            I := StrLen(PBuf)+1;
            //Result := StrPas(@PBuf[0]);
            if I<Res then
            begin
              Len := StrLen(@PBuf[I]);
              if Len>=Res-I then
                PBuf[Res-1] := #0;
              Result := StrPas(@PBuf[I]);
            end;
            //Result := IntToStr(Res)+'='+Result;
          end;
          if Length(Result)=0 then
            Result := '!';
        end;
      end;
  end;
end;

(*function TPayDataSet.GetDocState(ARecBuffer: Pointer): Word;
var
  AState: Word;
  BillRec: TOpRec;
begin
  AState := PPayRec(ARecBuffer)^.dbState;
  if GetDocOp(BillRec, PPayRec(ARecBuffer)^.dbIdKorr) then
    with BillRec do
    begin
      if brPrizn=brtReturn then
      begin
        if (AState and dsSignError) <> 0 then
          Result := adsSignError
        else
          Result := adsReturned;
      end
      else
        if brPrizn=brtKart then
          Result := adsKarted
        else
          if brPrizn=brtBill then
          begin
            Result := adsBilled;
            if (AState and dsInputDoc) <>0 then
              Result := adsSend;
            if (AState and dsSignError<>0) then
              Result := adsSignError;
          end
          else
            Result := adsSignError;
    end
  else
    begin
      AState := AState and 3;
      case AState of
        dsSndPost: Result := adsSndPost;
        dsSndSent: Result := adsSndSent;
        dsSndRcv: Result := adsSndRcv;
        else
          if IsSigned(PPayRec(ActiveBuffer)^, GetActiveRecLen) then
            Result := adsSigned
          else
            Result := adsNone;
    end;
  end;
end;*)

{function DocStateToStr(AState: Word): string;
begin
  Result := DocStates[AState];
end;}

function DocStateToStr(PayRecPtr: PPayRec; RecLen: Integer): string;
var
  AState: Word;
  OpRec: TOpRec;
  I: Integer;
begin
  AState := PayRecPtr^.dbState;
  if GetDocOp(OpRec, PPayRec(PayRecPtr)^.dbIdKorr)>0 then
  begin
    with OpRec do
    begin
      if brPrizn=brtReturn then
      begin
        {if (AState and dsSignError) <> 0 then
          Result := 'ош.подп.'
        else}
          Result := 'возврат';
      end
      else
        if brPrizn=brtKart then
          Result := 'картотека'
        else
          if brPrizn=brtBill then
          begin
            {if (AState and dsSignError)<>0 then
              Result := 'ош.подп.п'
            else}
            if (AState and dsInputDoc)<>0 then
              Result := 'получен'
            else
              Result := 'проведен';
          end
          else
            Result := 'неизв.оп.';
    end
  end
  else begin
    case AState and 3 of
      dsSndPost:
        Result := 'отправляется';
      dsSndSent:
        Result := 'отправлен';
      dsSndRcv:
        Result := 'принят';
      else begin
        {I := CheckSign(@PayRecPtr^.dbDoc, SizeOf(TDocRec)-drMaxVar
          +PayRecPtr^.dbDocVarLen, RecLen-(SizeOf(TPayRec)-SizeOf(TDocRec)),
          0, nil);}
        I := RecLen-(SizeOf(TPayRec)-drMaxVar+PayRecPtr^.dbDocVarLen);
        if I<0 then
          I := 0;
        case I of
          0:
            Result := '';
          92:
            Result := 'подп.уст.';
          else begin
            Result := 'подписан';
            if ShowPolySign and (AState=dsExtended) then
            begin
              if I>=4 then
                Result := Result + IntToStr(PInteger(@PayRecPtr^.dbDoc.drVar[
                  PayRecPtr^.dbDocVarLen])^);
            end;
          end;
        end;
      end;
    end;
  end;
  if (AState and dsSignError) <> 0 then
    Result := Result+' ош.п'
end;

const
  PayTypeNames: array[0..2] of string = ('почтой','телеграфом','электронно');

function TPayDataSet.GetFieldData(Field: TField; Buffer: Pointer): Boolean;
var
  Offset, ZeroPos: integer;
  Text: array[0..512] of Char;
  BillRec: TOpRec;
begin
  Result := False;
  with PPayRec(ActiveBuffer)^ do
  begin
    if not IsEmpty then
    begin
      Result := True;
      case Field.Index of
        0: PInteger(Buffer)^ := dbIdHere;
        1: PInteger(Buffer)^ := dbIdKorr;
        2: PInteger(Buffer)^ := dbIdIn;
        3: PInteger(Buffer)^ := dbIdOut;
        4: PInteger(Buffer)^ := dbIdArc;
        5: PInteger(Buffer)^ := dbIdDel;
        6: PInteger(Buffer)^ := dbVersion;
        7:
          begin
            if dsExport and PPayRec(ActiveBuffer)^.dbState <> 0 then
            begin
              StrPLCopy(Buffer, '+', Field.DataSize-1);
              Offset := 1;
            end
            else
              Offset := 0;
            StrPLCopy(@(PChar(Buffer)[Offset]),
              DocStateToStr(PPayRec(ActiveBuffer), GetActiveRecLen),
              Field.DataSize-1);
          end;
        8: StrPLCopy(Buffer, BtrDateToStr(dbDateS), Field.DataSize-1);
        9: PWord(Buffer)^ := dbTimeS;
        10: StrPLCopy(Buffer, BtrDateToStr(dbDateR), Field.DataSize-1);
        11: PWord(Buffer)^ := dbTimeR;
        12: StrPLCopy(Buffer, BtrDateToStr(dbDateP), Field.DataSize-1);
        13: PWord(Buffer)^ := dbTimeP;
        14: PWord(Buffer)^ := dbDocVarLen;
        15: StrPLCopy(Buffer, BtrDateToStr(dbDoc.drDate), Field.DataSize-1);
        16:
        begin
          StrPLCopy(Text, SumToStr(dbDoc.drSum), Field.DataSize-1);
          StrCopy(Buffer, Text);
        end;
        17: StrPLCopy(Buffer, BtrDateToStr(dbDoc.drSrok), Field.DataSize-1);
        18: PWord(Buffer)^ := dbDoc.drType;
        19: StrPLCopy(Buffer, PayTypeNames[dbDoc.drIsp], Field.DataSize-1);
        20: PWord(Buffer)^ := dbDoc.drOcher;
        21: StrPLCopy(Buffer, SumToRus(dbDoc.drSum), Field.DataSize-1);
        22,24,56:
          begin
            if GetDocOp(BillRec, PPayRec(ActiveBuffer)^.dbIdKorr)>0 then
              StrPLCopy(Buffer, BtrDateToStr(BillRec.brDate), Field.DataSize-1)
            else
              if Field.Index<>24 then
                StrCopy(Buffer, #0)
              else
                StrPLCopy(Buffer, BtrDateToStr(DateToBtrDate(Date)),
                  Field.DataSize-1);
          end;
        23:
          begin
            Offset := dbDoc.drType;
            if Offset>100 then
              Offset := Offset-100;
            StrPLCopy(Buffer, FillZeros(Offset, 2), Field.DataSize-1);
          end;
        25..52:
          begin
            ZeroPos := Field.Index-25;
            Offset := SizeOf(TDocRec);
            TakeZeroOffset(dbDoc.drVar, ZeroPos, Offset);
            StrCopy(Text, @dbDoc.drVar[Offset]);
            DosToWin(Text);
            if Field.DataType = ftString then
              StrLCopy(Buffer, Text, Field.DataSize-1)
            else
              Application.MessageBox('Поле таблицы не соответствует полю записи',
                'Чтение записи', MB_OK or MB_ICONERROR)
          end;
        53:
          StrPLCopy(Buffer, {BtrDateToStr(OpRec.AcceptSr)}'', Field.DataSize-1);
        54:
          begin
            {if dbIdKorr=0 then}
            if (dbState and dsSndSent)=0 then
              StrCopy(Buffer, '')
            else
              StrPLCopy(Buffer, 'Документ подписан электронной подписью',
                Field.DataSize-1)
          end;
        55:
          begin
            if dbState and dsInputDoc<>0 then
              StrLCopy(Buffer, 'Получено по системе электронного документооборота', Field.DataSize-1)
              {StrCopy(Buffer, '')}
            else begin
              {S := 'Получено по системе "БАНК-КЛИЕНТ"';}
              {if dbDateR>0 then
              begin
                S := S + ' ' + BtrDateToStr(dbDateR);
                if dbTimeR>0 then
                  S := S + ' ' + BtrTimeToStr(dbTimeR);
              end;}
              StrLCopy(Buffer, 'Принят по системе электронного документооборота', Field.DataSize-1)
            end;
          end;
        57:
          begin
            StrPLCopy(Buffer, GetDocOperName(dbIdKorr), Field.DataSize-1);
            if PChar(Buffer)[0]='!' then
              StrPLCopy(Buffer, 'Ветлугина Ю.В.', Field.DataSize-1)
            else
              DosToWin(Buffer);
          end;
        else
          Result := False;
      end;
    end;
  end;
end;

{ TValPayDataSet }

constructor TValPayDataSet.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  BufSize := SizeOf(TPayRec)+16;
end;

procedure TValPayDataSet.InternalInitFieldDefs;
begin
  FieldDefs.Clear;

  TFieldDef.Create(FieldDefs,'IdHere',ftInteger,0,False,0);
  TFieldDef.Create(FieldDefs,'IdKorr',ftInteger,0,False,1);
  TFieldDef.Create(FieldDefs,'IdIn',ftInteger,0,False,2);
  TFieldDef.Create(FieldDefs,'IdOut',ftInteger,0,False,3);
  TFieldDef.Create(FieldDefs,'IdArc',ftInteger,0,False,4);
  TFieldDef.Create(FieldDefs,'IdDel',ftInteger,0,False,5);
  TFieldDef.Create(FieldDefs,'Version',ftInteger,0,False,6);
  TFieldDef.Create(FieldDefs,'State',ftString, 11, False,7);
  TFieldDef.Create(FieldDefs,'DateS',ftString, DateStrLen, False,8);
  TFieldDef.Create(FieldDefs,'TimeS',ftWord,0,False,9);
  TFieldDef.Create(FieldDefs,'DateR',ftString, DateStrLen, False,10);
  TFieldDef.Create(FieldDefs,'TimeR',ftWord,0,False,11);
  TFieldDef.Create(FieldDefs,'DateP',ftString, DateStrLen, False,12);
  TFieldDef.Create(FieldDefs,'TimeP', ftWord, 0, False, 13);
  TFieldDef.Create(FieldDefs,'DocLen', ftWord, 0, False, 14);

  TFieldDef.Create(FieldDefs,'drDate',ftString, DateStrLen, False, 15);
  TFieldDef.Create(FieldDefs,'drSum', ftString, SumStrLen, False, 16);
  TFieldDef.Create(FieldDefs,'drSrok', ftString, DateStrLen, False, 17);
  TFieldDef.Create(FieldDefs,'drType', ftWord, 0, False, 18);
  TFieldDef.Create(FieldDefs,'drIsp',ftString, 10, False, 19);
  TFieldDef.Create(FieldDefs,'drOcher', ftWord, 0, False, 20);

  TFieldDef.Create(FieldDefs,'SumRus',ftString, 255, False, 21);
  TFieldDef.Create(FieldDefs,'DateOp', ftString, DateStrLen, False, 22);
  TFieldDef.Create(FieldDefs,'drVO', ftString, 2, False, 23);
  TFieldDef.Create(FieldDefs,'InputDate', ftString, DateStrLen, False, 24);

  TFieldDef.Create(FieldDefs,'DocNum',ftString, 5, False, 25);
  TFieldDef.Create(FieldDefs,'Pacc',ftString, SizeOf(TAccount), False, 26);
  TFieldDef.Create(FieldDefs,'Pks',ftString, SizeOf(TAccount), False, 27);
  TFieldDef.Create(FieldDefs,'Pcode',ftString, 9, False, 28);
  TFieldDef.Create(FieldDefs,'PInn',ftString, SizeOf(TInn), False, 29);
  TFieldDef.Create(FieldDefs,'PName',ftString, 160, False, 30);
  TFieldDef.Create(FieldDefs,'PbName',ftString, 70, False, 31);
  TFieldDef.Create(FieldDefs,'Racc',ftString, SizeOf(TAccount), False, 32);
  TFieldDef.Create(FieldDefs,'Rks',ftString, SizeOf(TAccount), False, 33);
  TFieldDef.Create(FieldDefs,'Rcode',ftString, 9, False, 34);
  TFieldDef.Create(FieldDefs,'RInn',ftString, SizeOf(TInn), False, 35);
  TFieldDef.Create(FieldDefs,'RName',ftString, 160, False, 36);
  TFieldDef.Create(FieldDefs,'RbName',ftString, 70, False, 37);
  TFieldDef.Create(FieldDefs,'NaznP',ftString, 400, False, 38);
  TFieldDef.Create(FieldDefs,'PKpp', ftString, 9, False, 39);
  TFieldDef.Create(FieldDefs,'RKpp', ftString, 9, False, 40);
  TFieldDef.Create(FieldDefs,'NalPayer', ftString, 2, False, 41);
  TFieldDef.Create(FieldDefs,'Kbk', ftString, 20, False, 42);
  TFieldDef.Create(FieldDefs,'Okato', ftString, 11, False, 43);
  TFieldDef.Create(FieldDefs,'OsnPl', ftString, 120, False, 44);
  TFieldDef.Create(FieldDefs,'Period', ftString, 10, False, 45);
  TFieldDef.Create(FieldDefs,'NDoc', ftString, 15, False, 46);
  TFieldDef.Create(FieldDefs,'DocDate', ftString, 10, False, 47);
  TFieldDef.Create(FieldDefs,'Tp', ftString, 2, False, 48);
end;

{function ExchangeStateToStr(AState: Word): string;
begin
  Result := '';
  if dsExport and AState <> 0 then
    Result := Result + 'выгружен';
end;}

{function GetDocOp(var Bill: TOpRec; DocId: Longint): Boolean;
var
  ABillDataSet: TExtBtrDataSet;
begin
  Result := False;
  ABillDataSet := GlobalBase(biBill);
  with ABillDataSet do
  begin
    IndexNum := 1;
    First;
    if LocateBtrRecordByIndex(DocId, 1, bsEq) then
    begin
      GetBtrRecord(@Bill);
      while not EoF and (Bill.brDocId=DocId) and (Bill.brDel<>0) do
      begin
        Next;
        GetBtrRecord(@Bill);
      end;
      if not EoF then
        Result := Bill.brDocId=DocId;
    end;
  end;
end;}

(*function TValPayDataSet.GetDocState(ARecBuffer: Pointer): Word;
var
  AState: Word;
  BillRec: TOpRec;
begin
  AState := PPayRec(ARecBuffer)^.dbState;
  if GetDocOp(BillRec, PPayRec(ARecBuffer)^.dbIdKorr) then
    with BillRec do
    begin
      if brPrizn=brtReturn then
      begin
        if (AState and dsSignError) <> 0 then
          Result := adsSignError
        else
          Result := adsReturned;
      end
      else
        if brPrizn=brtBill then
        begin
          Result := adsBilled;
          if (AState and dsInputDoc) <>0 then
            Result := adsSend;
          if (AState and dsSignError<>0) then
            Result := adsSignError;
        end
        else
          Result := adsSignError;
    end
  else
  begin
    AState := AState and 3;
    case AState of
      dsSndPost: Result := adsSndPost;
      dsSndSent: Result := adsSndSent;
      dsSndRcv: Result := adsSndRcv;
      else
        if IsSigned(PPayRec(ActiveBuffer)^) then
          Result := adsSigned
        else
          Result := adsNone;
    end;
  end;
end;

function DocStateToStr(AState: Word): string;
begin
  Result := DocStates[AState];
end;

const
  PayTypeNames: array[0..2] of string = ('почтой','телеграфом','электронно');*)

function TValPayDataSet.GetFieldData(Field: TField; Buffer: Pointer): Boolean;
begin
  Result := False;
  with PPayRec(ActiveBuffer)^ do
  begin
    if not IsEmpty then
    begin
      Result := True;
      case Field.Index of
        0: PInteger(Buffer)^ := dbIdHere;
        1: PInteger(Buffer)^ := dbIdKorr;
        2: PInteger(Buffer)^ := dbIdIn;
        3: PInteger(Buffer)^ := dbIdOut;
        4: PInteger(Buffer)^ := dbIdArc;
        5: PInteger(Buffer)^ := dbIdDel;
        6: PInteger(Buffer)^ := dbVersion;
        {7:
          begin
            if dsExport and PPayRec(ActiveBuffer)^.dbState <> 0 then
            begin
              StrPLCopy(Buffer, '+', Field.DataSize-1);
              Offset := 1;
            end
            else
              Offset := 0;
            StrPLCopy(@(PChar(Buffer)[Offset]),
              DocStateToStr(GetDocState(ActiveBuffer)), Field.DataSize-1);
          end;
        8: StrPLCopy(Buffer, BtrDateToStr(dbDateS), Field.DataSize-1);
        9: PWord(Buffer)^ := dbTimeS;
        10: StrPLCopy(Buffer, BtrDateToStr(dbDateR), Field.DataSize-1);
        11: PWord(Buffer)^ := dbTimeR;
        12: StrPLCopy(Buffer, BtrDateToStr(dbDateP), Field.DataSize-1);
        13: PWord(Buffer)^ := dbTimeP;
        14: PWord(Buffer)^ := dbDocVarLen;
        15: StrPLCopy(Buffer, BtrDateToStr(dbDoc.drDate), Field.DataSize-1);
        16:
        begin
          StrPLCopy(Text, SumToStr(dbDoc.drSum), Field.DataSize-1);
          StrCopy(Buffer, Text);
        end;
        17: StrPLCopy(Buffer, BtrDateToStr(dbDoc.drSrok), Field.DataSize-1);
        18: PWord(Buffer)^ := dbDoc.drType;
        19: StrPLCopy(Buffer, PayTypeNames[dbDoc.drIsp], Field.DataSize-1);
        20: PWord(Buffer)^ := dbDoc.drOcher;
        21: StrPLCopy(Buffer, SumToRus(dbDoc.drSum), Field.DataSize-1);
        22,24:
          begin
            if GetDocOp(BillRec, PPayRec(ActiveBuffer)^.dbIdKorr) then
              StrPLCopy(Buffer, BtrDateToStr(BillRec.brDate), Field.DataSize-1)
            else
              if Field.Index=22 then
                StrCopy(Buffer, #0)
              else
                StrPLCopy(Buffer, BtrDateToStr(DateToBtrDate(Date)),
                  Field.DataSize-1)
          end;
        23:
          begin
            Offset := dbDoc.drType;
            if Offset>100 then
              Offset := Offset-100;
            StrPLCopy(Buffer, FillZeros(Offset, 2), Field.DataSize-1);
          end;
        25..48:
          begin
            ZeroPos := Field.Index-25;
            Offset := SizeOf(TDocRec);
            TakeZeroOffset(dbDoc.drVar, ZeroPos, Offset);
            StrCopy(Text, @dbDoc.drVar[Offset]);
            DosToWin(Text);
            if Field.DataType = ftString then
              StrLCopy(Buffer, Text, Field.DataSize-1)
            else
              Application.MessageBox('Поле таблицы не соответствует полю записи',
                'Чтение записи', MB_OK or MB_ICONERROR)
          end;}
        else
          Result := False;
      end;
    end;
  end;
end;

const
  BaseCount = 19;
  BaseFiles: array[0..BaseCount-1] of TFileName =
   ('users.btr', 'sanctn.btr', 'acc.btr', 'accarc.btr', 'banknp.btr', 'bankn.btr',
    'clientn.btr', 'email.btr', 'bill.btr', 'doc.btr', 'files.btr', 'module.btr',
    'sfiles.btr', 'lfiles.btr', 'valdoc.btr', 'valacc.btr', 'valbill.btr',
    'valcode.btr', 'valcli.btr');               //Добавлено

function InitBasicBase(OpenVal, OpenFileBases: Boolean): Boolean;  { Инициализация основных баз }
const
  MesTitle: PChar = 'Инициализация основных баз';
var
  ABaseNumber: TBaseNumber;
  ADataSet: TBtrDataSet;
  AFileName: TFileName;
begin
  FGlobalBases := TList.Create;
  Result := True;
  for ABaseNumber := biUser to biValCli do
  begin
    ADataSet := nil;
    case ABaseNumber of
      biUser: ADataSet := TUserDataSet.Create(Application);
      biSanction: ADataSet := TSanctionDataSet.Create(Application);
      biAcc: ADataSet := TAccDataSet.Create(Application);
      biAccArc: ADataSet := TAccArcDataSet.Create(Application);
      biNp: ADataSet := TNpDataSet.Create(Application);
      biBank: ADataSet := TBankDataSet.Create(Application);
      biClient: ADataSet := TClientDataSet.Create(Application);
      biLetter: ADataSet := TLetterDataSet.Create(Application);
      biBill: ADataSet := TBillDataSet.Create(Application);
      biPay: ADataSet := TPayDataSet.Create(Application);
      biFile: ADataSet := TFileDataSet.Create(Application);
      biModule: ADataSet := TModuleDataSet.Create(Application);
      biSFile:
        if OpenFileBases then
          AdataSet := TSFileDataSet.Create(Application);    //Добавлено
      biLFile:
        if OpenFileBases then
          AdataSet := TLFileDataSet.Create(Application);    //Добавлено
      biValDoc..biValCli:
        begin
          if OpenVal then
          begin
            {MessageBox(ParentWnd, 'На данный момент валютная часть не реализована',
              MesTitle, MB_OK or MB_ICONINFORMATION);}
            OpenVal := False;
            (*case ABaseNumber of
              biValDoc: ADataSet := TValPayDataSet.Create(Application);
              biValAcc: ADataSet := nil;
              biValBill: ADataSet := nil;
              biValCode: ADataSet := nil;
              biValCli: ADataSet := nil;
              else
                ADataSet := nil;
            end*)
          end;
        end;
    end;
    FGlobalBases.Add(ADataSet);
    if ADataSet<>nil then
      with ADataSet do
      begin
        try
          try
            AFileName := DecodeMask('$(Base)', 5, CommonUserNumber);
          except
            AFileName := '';
          end;
          if Length(AFileName)<=0 then
            AFileName := BaseDir;
          AFileName := AFileName + BaseFiles[Ord(ABaseNumber)];
          TableName := AFileName;
          Active := True;
        except
          try
            AFileName := BaseDir + BaseFiles[Ord(ABaseNumber)];
            TableName := AFileName;
            Active := True;
          except
            Result := False;
            MessageBox(ParentWnd, PChar('Не удалось открыть базу '+AFileName),
              MesTitle, MB_OK or MB_ICONERROR);
          end;
        end;
      end;
  end;
end;

procedure DoneBasicBase;
begin
  if FGlobalBases<>nil then
  begin
    while FGlobalBases.Count>0 do
    begin
      TObject(FGlobalBases.Items[FGlobalBases.Count-1]).Free;
      FGlobalBases.Delete(FGlobalBases.Count-1);
    end;
    FGlobalBases.Free;
  end;
end;

procedure SetUserNumber(Value: Integer);
begin
  FUserNumber := Value;
end;

procedure SetFirmNumber(Value: Integer);
begin
  FFirmNumber := Value;
end;

{function FirmAccess: Boolean;
var
  AccessVec: TAccessRec;
begin
  Result := AccessDataSet<>nil;
  if Result then
    with AccessDataSet do
    begin
      First;
      with AccessVec do
      begin
        asUserNumber := UserNumber;
        asFirmNumber := FirmNumber;
      end;
      Result := LocateBtrRecordByIndex(AccessVec, 0, bsEq);
    end;
end;}

function LevelIsSanctioned(ALevel: Byte): Boolean;
var
  UserRec: TUserRec;
begin
  CurrentUser(UserRec);
  Result := UserRec.urLevel<=ALevel;
end;

function IsSanctionAccess(ASancNumber: Integer): Boolean;
var
  SanctionVec: TSanctionRec;
  SanctionDataSet: TExtBtrDataSet;
begin
  SanctionDataSet := GlobalBase(biSanction);
  Result := SanctionDataSet<>nil;
  if Result then
    with SanctionDataSet do
    begin
      with SanctionVec do
      begin
        snUserNumber := FUserNumber;
        snSancNumber := ASancNumber;
      end;
      Result := LocateBtrRecordByIndex(SanctionVec, 0, bsEq);
    end;
end;

function IsSanctAccess(ASancName: string): Boolean;
var
  RegistrBase: TBtrBase;
  ParamKey: TParamKey1;
  ParamRec: TParamNewRec;
  Res, Len: Integer;
begin
  RegistrBase := GetRegistrBase;
  Result := RegistrBase<>nil;
  if Result then
    with RegistrBase do
    begin
      FillChar(ParamKey, SizeOf(ParamKey), #0);
      StrPLCopy(ParamKey.pkIdent, ASancName, SizeOf(ParamKey.pkIdent));
      ParamKey.pkUser := CommonUserNumber;
      Len := SizeOf(ParamRec);
      Res := RegistrBase.GetEqual(ParamRec, Len, ParamKey, 1);
      Result := Res=0;
      if Result then
        Result := IsSanctionAccess(ParamRec.pmNumber);
    end;
end;

{function LegalUser: Boolean;
begin
  Result := UserDataSet<>nil;
  if Result then
    with UserDataSet do
    begin
      Result := LocateBtrRecordByIndex(UserNumber, 0, bsEq);
      if Result then
      begin
        Result := PUserRec(ActiveBuffer)^.urOperNum = GetOperNum;
      end;
    end;
end;}

function GetUserByOperNum(OperNum: Integer; var AUserRec: TUserRec): Boolean;
var
  UserDataSet: TExtBtrDataSet;
  U: Integer;
begin
  FillChar(AUserRec, SizeOf(AUserRec), #0);
  AUserRec.urLevel := 255;
  UserDataSet := GlobalBase(biUser);
  Result := UserDataSet<>nil;
  if Result then
    with UserDataSet do
    begin
      U := OperNum;
      Result := LocateBtrRecordByIndex(U, 0, bsEq);
      if Result then
        GetBtrRecord(@AUserRec);
    end;
end;

function CurrentUser(var AUserRec: TUserRec): Boolean;
begin
  Result := GetUserByOperNum(FUserNumber, AUserRec);
end;

function MakeUserList(var List1, List2, List3: string): Integer;
var
  UserDataSet: TExtBtrDataSet;
  UserRec: TUserRec;
  Res, Len, Id: Integer;
begin
  Result := -1;
  UserDataSet := GlobalBase(biUser);
  if UserDataSet<>nil then
  begin
    List1 := '';
    List2 := '';
    List3 := '';
    Result := 0;
    Len := SizeOf(UserRec);
    Res := UserDataSet.BtrBase.GetFirst(UserRec, Len, Id, 0);
    while Res=0 do
    begin
      Inc(Result);
      if usDirector and UserRec.urStatus>0 then
        AddWordInList(UserRec.urLogin, List1);
      if usAccountant and UserRec.urStatus>0 then
        AddWordInList(UserRec.urLogin, List2);
      if usCourier and UserRec.urStatus>0 then
        AddWordInList(UserRec.urLogin, List3);
      Len := SizeOf(UserRec);
      Res := UserDataSet.BtrBase.GetNext(UserRec, Len, Id, 0);
    end;
  end;
end;

function ClientGetLoginNameProc(Login: string; var Status: Integer;
  var UserName: string): Boolean; stdcall;
var
  UserDataSet: TExtBtrDataSet;
  UserRec: TUserRec;
  Res, Len, Id: Integer;
begin
  Result := False;
  UserDataSet := GlobalBase(biUser);
  if UserDataSet<>nil then
  begin
    Len := SizeOf(UserRec);
    Res := UserDataSet.BtrBase.GetFirst(UserRec, Len, Id, 0);
    while (Res=0) and not Result do
    begin
      if UpperCase(UserRec.urLogin)=UpperCase(Login) then
      begin
        Result := True;
        Status := UserRec.urStatus;
        UserName := StrPas(UserRec.urInfo);
      end;
      Len := SizeOf(UserRec);
      Res := UserDataSet.BtrBase.GetNext(UserRec, Len, Id, 0);
    end;
  end;
end;


{function CurrentFirm(var AFirmRec: TFirmRec;
  var AFirmAccRec: TFirmAccRec): Boolean;
var
  FirmDataSet, FirmAccDataSet: TExtBtrDataSet;
  I: Integer;
  FirmAccKey: packed record Number: Integer; Acc: TAccount end;
begin
  FillChar(AFirmRec, SizeOf(AFirmRec), #0);
  FillChar(AFirmAccRec, SizeOf(AFirmAccRec), #0);
  FirmDataSet := GlobalBase(biFirm);
  Result := FirmDataSet<>nil;
  if Result then
    with FirmDataSet do
    begin
      First;
      I := FFirmNumber;
      Result := LocateBtrRecordByIndex(I, 0, bsEq);
      if Result then
      begin
        GetBtrRecord(@AFirmRec);
        FirmAccDataSet := GlobalBase(biFirmAcc);
        Result := FirmAccDataSet<>nil;
        if Result then
          with FirmAccDataSet do
          begin
            First;
            with FirmAccKey do
            begin
              Number := FFirmNumber;
              FillChar(Acc, SizeOf(Acc), #0)
            end;
            Result := LocateBtrRecordByIndex(FirmAccKey, 0, bsGe);
            if Result then
            begin
              UpdateCursorPos;
              GetBtrRecord(@AFirmAccRec);
              I := AFirmRec.frAccNumber;
              while not EoF and (FFirmNumber=AFirmAccRec.faNumber) and (I>0) do
              begin
                Dec(I);
                Next;
                GetBtrRecord(@AFirmAccRec);
              end;
            end;
          end;
      end;
    end;
end;}

var
  TakeMI: TMenuItem;

procedure TakeMenuItems(Source, Dest: TMenuItem);
var
  I: Integer;
  ShowIcon: Boolean;
begin
  if Source.Count>0 then
    for I := 1 to Source.Count do
      TakeMenuItems(Source.Items[I-1], Dest)
  else begin
    TakeMI := TMenuItem.Create(Dest.Owner);
    with TakeMI do
    begin
      Break := Source.Break;
      Caption := Source.Caption;
      Checked := Source.Checked;
      GroupIndex := Source.GroupIndex;
      HelpContext := Source.HelpContext;
      Hint := Source.Hint;
      if GetRegParamByName('PopupIcons', CommonUserNumber, ShowIcon) then
        if ShowIcon then
          ImageIndex := Source.ImageIndex;
      RadioItem := Source.RadioItem;
      ShortCut := Source.ShortCut;
      Tag := Source.Tag;
      Visible := Source.Visible;
      OnClick := Source.OnClick;
    end;
    Dest.Add(TakeMI);
  end;
end;

(*procedure MakeRegNumber(var Number: Integer);
const
  RegName: string = 'LastDocIder';
begin
  if GetRegParamByName(RegName, Number) then
  begin
    if not SetRegParamByName(RegName, IntToStr(Number+1)) then
      MessageBox(ParentWnd, 'Ошибка регистрации документа в реестре',
        'Получение уникального номера', MB_OK or MB_ICONERROR);
  end
  else
    Number := -1;
end;*)

const
  DosKpp: PChar = #$8A#$8F#$8F;

function UpdateClient(Acc: string; Bik: Integer; Name, Inn, Kpp: string;
  DosCharset, UpdateKpp: Boolean; ModIndex: Integer;
  OldAcc: string; OldBik: Integer; OldInn: string): Boolean;
const
  MesTitle: PChar = 'Добавление/обновление клиента';
var
  ClientDataSet: TExtBtrDataSet;
  Len, Res, I: Integer;
  BikAccKey: packed record
    kCodeB: LongInt;                            {20,4     k0.0}
    kAccC:  array[0..SizeOf(TAccount)] of Char;
  end;
  ClientRec, ClientRec2: TNewClientRec;
  NameKpp: string;
  InnKey: array[0..SizeOf(TInn)] of Char;
  P: Pointer;
begin
  Result := False;
  FillChar(ClientRec, SizeOf(ClientRec), #0);
  with ClientRec do
  begin
    StrPLCopy(clAccC, Acc, SizeOf(clAccC));
    clCodeB := Bik;
    StrPLCopy(clInn, Inn, SizeOf(clInn));
    StrPLCopy(clKpp, Kpp, SizeOf(clInn));
    Name := Trim(Name);
    StrPLCopy(clNameC, Name, SizeOf(clNameC));
    if not DosCharset then
      WinToDos(clNameC);
    Name := StrPas(clNameC);
    I := Pos(DosKpp, Name);
    if I=1 then
    begin
      System.Delete(Name, 1, 3);
      Name := Trim(Name);
      Len := Length(Name);
      I := 0;
      while (I<Len) and (Name[I+1] in ['0'..'9']) do
        Inc(I);
      if I>0 then
      begin
        NameKpp := Copy(Name, 1, I);
        Delete(Name, 1, I);
        Name := Trim(Name);
      end
      else
        NameKpp := '';
      StrPLCopy(clNameC, Name, SizeOf(clNameC)-1);
    end
    else
      NameKpp := '';
  end;
  ClientDataSet := GlobalBase(biClient);
  if ClientDataSet<>nil then
  begin
    Len := SizeOf(ClientRec);
    P := nil;
    case ModIndex of
      1:
        begin
          FillChar(InnKey, SizeOf(InnKey), #0);
          StrPLCopy(InnKey, OldInn, SizeOf(InnKey)-1);
          P := @InnKey;
        end;
      else
        begin
          FillChar(BikAccKey, SizeOf(BikAccKey), #0);
          with BikAccKey do
          begin
            kCodeB := OldBik;
            StrPLCopy(kAccC, OldAcc, SizeOf(kAccC)-1);
          end;
          P := @BikAccKey;
        end;
    end;
    if (StrLen(ClientRec.clKpp)=0) and (Length(NameKpp)>0) then
      StrPLCopy(ClientRec.clKpp, NameKpp, SizeOf(ClientRec.clKpp)-1);
    Res := ClientDataSet.BtrBase.GetEqual(ClientRec2, Len, P^, ModIndex);
    if Res=0 then
    begin
      if not UpdateKpp and (StrLen(ClientRec.clKpp)=0) then
        ClientRec.clKpp := ClientRec2.clKpp;
      Res := ClientDataSet.BtrBase.Update(ClientRec, Len, P^, ModIndex);
      if Res=0 then
        Result := True
      else
        MessageBox(ParentWnd, PChar('Не удалось обновить клиента BtrErr='
          +IntToStr(Res)), MesTitle, MB_OK or MB_ICONERROR);
    end
    else begin
      Len := SizeOf(ClientRec);
      Res := ClientDataSet.BtrBase.Insert(ClientRec, Len, P^, ModIndex);
      if Res=0 then
        Result := True
      else
        MessageBox(ParentWnd, PChar('Не удалось добавить клиента BtrErr='
          +IntToStr(Res)), MesTitle, MB_OK or MB_ICONERROR);
    end;
    ClientDataSet.Refresh;
  end
  else
    MessageBox(ParentWnd, 'База клиентов не открыта', MesTitle, MB_OK or MB_ICONERROR);
end;

function TestAcc(CodeS, KsS, AccS: string; EndMes: string;
  Ask: Boolean): Boolean;
var
  Code, Res: Integer;
  Mes: string;
begin
  Val(CodeS, Code, Res);
  Result := Res=0;
  if Result then
  begin
    Result := (Length(KsS)=0) or TestKey(KsS, (Code div 1000) mod 100);
    if Result then
    begin
      if Length(AccS)>0 then
      begin
        if Length(KsS)>0 then
          Result := TestKey(AccS, Code mod 1000)
        else
          Result := TestKey(AccS, (Code div 1000) mod 100);
      end;
      if Result then
      begin
        Result := Length(AccS)>0;
        if not Result then
          Mes := 'Не указан счет';
      end
      else
        Mes := 'Ошибочный ключ в счете'
    end
    else
      Mes := 'Корр/счет не соответствует БИКу'
  end
  else
    Mes := 'Код банка указан неверно';
  if not Result and Ask then
    Result := MessageBox(ParentWnd, PChar(Mes), PChar('Проверка реквизитов'+EndMes),
      MB_ABORTRETRYIGNORE or MB_ICONERROR)=IDIGNORE;
end;

function TestPaydoc(var PayRec: TPayRec; Ask: Boolean): Boolean;
const
  MesTitle: PChar = 'Проверка документа';
var
  I, Offset, Len: Integer;
  V: TVarDoc;
  DebitRs, DebitKs, DebitBik, CreditRs, CreditKs, CreditBik: string;
begin
  Result := False;
  with PayRec do
  begin
    Result := (dbDoc.drDate<>0) or (Ask and
      (MessageBox(Application.Handle, 'Не указана дата', MesTitle,
        MB_ABORTRETRYIGNORE or MB_ICONERROR)=IDIGNORE));
    if Result then
    begin
      Result := (dbDoc.drSum>0) or (Ask and
        (MessageBox(Application.Handle, 'Сумма равна нулю', MesTitle,
          MB_ABORTRETRYIGNORE or MB_ICONERROR)=IDIGNORE));
      if Result then
      begin
        Offset := 0;
        I := 21;
        while (I<=34) and Result do
        begin
          Len := StrLen(@dbDoc.drVar[Offset]);
          case I of
            22,23,24,28,29,30:
              StrLCopy(V, @dbDoc.drVar[Offset], SizeOf(dbDoc.drVar)-Offset);
          end;
          case I of
            21: {Number}
              Result := (Len>0) or (Ask and (MessageBox(Application.Handle, 'Не указан номер',
                MesTitle, MB_ABORTRETRYIGNORE or MB_ICONERROR)=IDIGNORE));
            22: {DebitRs}
              begin
                DebitRs := V;
                Result := (Len>0) or (Ask and (MessageBox(Application.Handle, 'Не указан счет плательщика',
                  MesTitle, MB_ABORTRETRYIGNORE or MB_ICONERROR)=IDIGNORE));
              end;
            23: {DebitKs}
              DebitKs := V;
            24: {DebitBik}
              begin
                DebitBik := V;
                Result := (Len>0) or (Ask and (MessageBox(Application.Handle, 'Не указан БИК банка плательщика',
                  MesTitle, MB_ABORTRETRYIGNORE or MB_ICONERROR)=IDIGNORE));
              end;
            25:  {DebetInn}
              Result := (Len>0) or (dbDoc.drType<>1)
                or (Ask and (MessageBox(Application.Handle, 'Не указан ИНН плательщика',
                MesTitle, MB_ABORTRETRYIGNORE or MB_ICONERROR)=IDIGNORE));
            26:  {DebetName}
              Result := (Len>0) or (Ask and (MessageBox(Application.Handle, 'Не указано название плательщика',
                MesTitle, MB_ABORTRETRYIGNORE or MB_ICONERROR)=IDIGNORE));
            27:  {DebetBankName}
              Result := (Len>0) or (Ask and (MessageBox(Application.Handle, 'Не указано название банка плательщика',
                MesTitle, MB_ABORTRETRYIGNORE or MB_ICONERROR)=IDIGNORE));
            28: {CreditRs}
              begin
                CreditRs := V;
                Result := (Len>0) or (Ask and (MessageBox(Application.Handle, 'Не указан счет получателя',
                  MesTitle, MB_ABORTRETRYIGNORE or MB_ICONERROR)=IDIGNORE));
              end;
            29: {CreditKs}
              CreditKs := V;
            30: {CreditBik}
              begin
                CreditBik := V;
                Result := (Len>0) or (Ask and (MessageBox(Application.Handle, 'Не указан БИК банка получателя',
                  MesTitle, MB_ABORTRETRYIGNORE or MB_ICONERROR)=IDIGNORE));
              end;
            31:  {CreditInn}
              Result := (Len>0) or (dbDoc.drType<>1)
                or (Ask and (MessageBox(Application.Handle, 'Не указан ИНН получателя',
                MesTitle, MB_ABORTRETRYIGNORE or MB_ICONERROR)=IDIGNORE));
            32:  {CreditName}
              Result := (Len>0) or (Ask and (MessageBox(Application.Handle, 'Не указано название получателя',
                MesTitle, MB_ABORTRETRYIGNORE or MB_ICONERROR)=IDIGNORE));
            33:  {CreditBankName}
              Result := (Len>0) or (Ask and (MessageBox(Application.Handle, 'Не указано название банка получателя',
                MesTitle, MB_ABORTRETRYIGNORE or MB_ICONERROR)=IDIGNORE));
            34:  {Nazn}
              Result := (Len>0) or (Ask and (MessageBox(Application.Handle, 'Не указано назначение платежа',
                MesTitle, MB_ABORTRETRYIGNORE or MB_ICONERROR)=IDIGNORE));
          end;
          Offset := Offset + Len + 1;
          Inc(I);
        end;
        Result := Result and TestAcc(DebitBik, DebitKs, DebitRs, ' плательщика',
          Ask) and TestAcc(CreditBik, CreditKs, CreditRs, ' получателя', Ask)
      end;
    end;
  end;
end;

function DocInfo(var PayRec: TPayRec): string;
begin
  Result := #13#10'[N'+PayRec.dbDoc.drVar+'  '
    +BtrDateToStr(PayRec.dbDoc.drDate)+'  '
    +SumToStr(PayRec.dbDoc.drSum)+' руб.]';
end;

function FillClientList(List: TStrings; ActDate: Word; Max: Integer): Boolean;
var
  AccDataSet: TAccDataSet;
  AccRec: TAccRec;
  Len, Res, I: Integer;
  Buf: array[0..SizeOf(TKeeperName)] of Char;
  Acc, Key: array[0..SizeOf(TAccount)] of Char;
begin
  Result := False;
  AccDataSet := GlobalBase(biAcc) as TAccDataSet;
  if (AccDataSet<>nil) and (List<>nil) then
  begin
    Result := True;
    List.Clear;
    with AccDataSet.BtrBase do
    begin
      Len := SizeOf(AccRec);
      Res := GetFirst(AccRec, Len, Key, 1);
      I := 0;
      while (Res=0) and (I<Max) do
      begin
        if (ActDate=0) or DateIsActive(ActDate, AccRec.arDateO, AccRec.arDateC) then
        begin
          StrLCopy(Buf, AccRec.arName, SizeOf(Buf)-1);
          DosToWin(Buf);
          StrLCopy(Acc, AccRec.arAccount, SizeOf(Acc)-1);
          List.AddObject(Acc+' | '+Buf, TObject(AccRec.arIder));
          Inc(I);
        end;
        Len := SizeOf(AccRec);
        Res := GetNext(AccRec, Len, Key, 1);
      end;
    end;
  end;
end;

function GetLastClosedDay: Word;
var
  AccArcDataSet: TExtBtrDataSet;
  Len, Res: Integer;
  paa: TAccArcRec;
  KeyAA:
    packed record
      aaIder: longint;
      aaDate:   word;
    end;
begin
  Result := 0;
  AccArcDataSet := GlobalBase(biAccArc);
  Len := SizeOf(paa);
  Res := AccArcDataSet.BtrBase.GetLast(paa, Len, KeyAA, 0);
  if Res=0 then
    Result := paa.aaDate;
end;

function GetFirstOpenDay: Word;
var
  KeyO: Word;
  Res, Len: Integer;
  BillRec: TOpRec;
  BillDataSet: TExtBtrDataSet;
begin
  BillDataSet := GlobalBase(biBill);
  Result := 0;
  KeyO := GetLastClosedDay;
  { Найдем проводки по незакрытым дням }
  Len := SizeOf(BillRec);
  Res := BillDataSet.BtrBase.GetGT(BillRec, Len, KeyO, 2);
  while (Res=0) and (BillRec.brDel<>0) do
  begin
    Len := SizeOf(BillRec);
    Res := BillDataSet.BtrBase.GetNext(BillRec, Len, KeyO, 2);
  end;
  if Res=0 then
    Result := BillRec.brDate;
end;

function GetPrevWorkDay(ADay: Word; Acc: PChar): Word;
var
  KeyO: Word;
  Res, Len: Integer;
  BillRec: TOpRec;
  BillDataSet: TExtBtrDataSet;
begin
  Result := 0;
  KeyO := ADay;
  BillDataSet := GlobalBase(biBill);
  Len := SizeOf(BillRec);
  Res := BillDataSet.BtrBase.GetLT(BillRec, Len, KeyO, 2);
  while (Res=0) and ((BillRec.brPrizn<>brtBill) or (BillRec.brDel<>0)
    or (Acc<>nil) and (StrLComp(BillRec.brAccD, Acc, SizeOf(TAccount))<>0)
    and (StrLComp(BillRec.brAccC, Acc, SizeOf(TAccount))<>0)) do
  begin
    Len := SizeOf(BillRec);
    Res := BillDataSet.BtrBase.GetPrev(BillRec, Len, KeyO, 2);
  end;
  if Res=0 then
    Result := BillRec.brDate;
end;

function GetFullBankByBik(Bik: Integer; DosCharset: Boolean;
  var FullBank: TBankFullNewRec): Boolean;
var
  BankDataSet, NpDataSet: TExtBtrDataSet;
  Res, Len: Integer;
  Bank: TBankNewRec;
  Np: TNpRec;
begin
  Result := False;
  BankDataSet := GlobalBase(biBank);
  if BankDataSet<>nil then
  begin
    Len := SizeOf(Bank);
    Res := BankDataSet.BtrBase.GetEqual(Bank, Len, Bik, 0);
    if Res=0 then
    begin
      Result := True;
      with FullBank do
      begin
        brCod := Bank.brCod;
        brKs := Bank.brKs;
        {if StrLen(Bank.brType)>0 then
        begin
          StrLCopy(brName, @Bank.brType, SizeOf(Bank.brType));
          StrCat(brName, ' ');
        end
        else
          StrCopy(brName, '');}
        StrLCopy(brName, @Bank.brName, SizeOf(brName));
        NpDataSet := GlobalBase(biNp);
        if NpDataSet<>nil then
        begin
          Len := SizeOf(Np);
          Res := NpDataSet.BtrBase.GetEqual(Np, Len, Bank.brNpIder, 0);
          if Res=0 then
          begin
            StrLCat(brName, #13#10, SizeOf(brName));
            if StrLen(Np.npType)>0 then
            begin
              StrLCat(brName, Np.npType, SizeOf(brName));
              StrLCat(brName, ' ', SizeOf(brName));
            end;
            StrLCat(brName, Np.npName, SizeOf(brName));
          end;
        end;
        if not DosCharset then
          DosToWin(brName);
      end;
    end;
  end;
end;

function IsPayDocExist(DocDataSet: TExtBtrDataSet; SelfOutID: Integer; Number: string; DocDate: Word; VO, Sum: Comp): Boolean;
const
  MaxAll = 100;  // Проверка всего не более
  MaxOld = 20;   // Проверка старых не более
var
  Res, Len, OutID, I1, I2: Integer;
  PayRec: TPayRec;
  Number2: string;
  Bill: TOpRec;
begin
  Result := False;
  Len := SizeOf(PayRec);
  Res := DocDataSet.BtrBase.GetLast(PayRec, Len, OutID, 3);
  I1 := 0; I2 := 0;
  while (Res=0) and not Result and (I1<MaxAll) and (I2<MaxOld) do
  begin
    if PayRec.dbIdOut<>SelfOutID then
    begin
      Inc(I1);
      if (PayRec.dbDoc.drDate<>0) and (DocDate<>0)
        and (BtrDateToDate(PayRec.dbDoc.drDate)<BtrDateToDate(DocDate))
      then
        Inc(I2);
      if (PayRec.dbDoc.drType=VO) and ((DocDate=0) or (PayRec.dbDoc.drDate=DocDate))
        and ((Sum=0) or (PayRec.dbDoc.drSum=Sum)) then
      begin
        Number2 := Trim(StrPas(@PayRec.dbDoc.drVar[0]));
        Result := (Number=Number2) and ((GetDocOp(Bill, PayRec.dbIdKorr)<=0)
          or (Bill.brPrizn<>brtReturn));
      end;
    end;
    if not Result then
    begin
      Len := SizeOf(PayRec);
      Res := DocDataSet.BtrBase.GetPrev(PayRec, Len, OutID, 3);
    end;
  end;
end;


end.
