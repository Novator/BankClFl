unit Basbn;

interface

uses
  Classes, SysUtils, Windows, Db, Forms, Messages, DbGrids, BtrDS,
    Menus, Controls, Utilits, Registr, Btrieve, CommCons, BankCnBn;

const
  adsNone = 0;         {0}
  adsSigned = 1;       {1(o) 2(i)}
  adsSignError = 2;
  adsReturned = 3;
  adsSend = 4;
  adsBilled = 5;
  adsSndPost = 6;
  adsSndRcv = 7;       {2 }
  adsSndSent = 8;

{  rseNone       = 0;   // Индикация красного сальдо
  rseCredAccD   = 1;
  rseCredAccC   = 2;
  rseDebAccD    = 4;
  rseDebAccC    = 8;}

type
  TBaseNumber = (biUser, {biAccess, }biSanction,
    biAcc, biAccArc, biNp, biBank, biClient, {biCorr, }biAbonId, biAbonSid, biAbon,
    biLetter, biBill, biPay, biFile, biModule, biExport, biImport,
    biTrans, biCorrAbo, biCorrSpr, biSendFile, biOper);

  TExpKey = packed record
    ekOperNum:   longint;      {k1.0}
    ekOperation: word;         {k1.1}
  end;

  TImpKey = packed record
    pkProCode: Longint;
    pkProDate: Integer;
  end;

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

  {TCorrDataSet = class(TExtBtrDataSet)
  protected
    procedure InternalInitFieldDefs; override;
  public
    function GetFieldData(Field: TField; Buffer: Pointer): Boolean; override;
    constructor Create(AOwner: TComponent); override;
  end;}

  TAbonIdDataSet = class(TExtBtrDataSet)
  protected
    procedure InternalInitFieldDefs; override;
  public
    function GetFieldData(Field: TField; Buffer: Pointer): Boolean; override;
    constructor Create(AOwner: TComponent); override;
  end;

  TAbonSidDataSet = class(TExtBtrDataSet)
  protected
    procedure InternalInitFieldDefs; override;
  public
    function GetFieldData(Field: TField; Buffer: Pointer): Boolean; override;
    constructor Create(AOwner: TComponent); override;
  end;

  TAbonDataSet = class(TExtBtrDataSet)
  private
    FAbonIdDataSet: TAbonIdDataSet;
  protected
    procedure InternalInitFieldDefs; override;
  public
    procedure SetAbonId(ADataSet: TAbonIdDataSet);
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

  TTransDataSet = class(TExtBtrDataSet)
  protected
    procedure InternalInitFieldDefs; override;
  public
    function GetFieldData(Field: TField; Buffer: Pointer): Boolean; override;
    constructor Create(AOwner: TComponent); override;
  end;

  TCorrAboDataSet = class(TExtBtrDataSet)
  protected
    procedure InternalInitFieldDefs; override;
  public
    function GetFieldData(Field: TField; Buffer: Pointer): Boolean; override;
    constructor Create(AOwner: TComponent); override;
  end;

  TCorrSprDataSet = class(TExtBtrDataSet)
  protected
    procedure InternalInitFieldDefs; override;
  public
    function GetFieldData(Field: TField; Buffer: Pointer): Boolean; override;
    constructor Create(AOwner: TComponent); override;
  end;

  TSendFileDataSet = class(TExtBtrDataSet)
  protected
    procedure InternalInitFieldDefs; override;
  public
    function GetFieldData(Field: TField; Buffer: Pointer): Boolean; override;
    constructor Create(AOwner: TComponent); override;
  end;

  TOperDataSet = class(TExtBtrDataSet)
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

  (*TAccessDataSet = class(TExtBtrDataSet)
  protected
    procedure InternalInitFieldDefs; override;
  public
    function GetFieldData(Field: TField; Buffer: Pointer): Boolean; override;
    constructor Create(AOwner: TComponent); override;
  end; *)

  TSanctionDataSet = class(TExtBtrDataSet)
  protected
    procedure InternalInitFieldDefs; override;
  public
    function GetFieldData(Field: TField; Buffer: Pointer): Boolean; override;
    constructor Create(AOwner: TComponent); override;
  end;

  (*TFirmAccDataSet = class(TExtBtrDataSet)
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
  end; *)

  TFileDataSet = class(TExtBtrDataSet)
  protected
    procedure InternalInitFieldDefs; override;
  public
    function GetFieldData(Field: TField; Buffer: Pointer): Boolean; override;
    constructor Create(AOwner: TComponent); override;
  end;

  TExportDataSet = class(TExtBtrDataSet)
  protected
    procedure InternalInitFieldDefs; override;
  public
    function GetFieldData(Field: TField; Buffer: Pointer): Boolean; override;
    constructor Create(AOwner: TComponent); override;
  end;

  TImportDataSet = class(TExtBtrDataSet)
  protected
    procedure InternalInitFieldDefs; override;
  public
    function GetFieldData(Field: TField; Buffer: Pointer): Boolean; override;
    constructor Create(AOwner: TComponent); override;
  end;

function FieldTypeToStr(AFieldType: TFieldType): string;
procedure SetUserNumber(Value: Integer);
function GetUserNumber: Integer;
procedure SetFirmNumber(Value: Integer);
function UserBaseDir: string;
function LevelIsSanctioned(ALevel: Byte): Boolean;
function IsSanctionAccess(ASancNumber: Integer): Boolean;
function IsSanctAccess(ASancName: string): Boolean;
{function IsThisSign(P: PChar): Boolean;}
function IsSigned(var P: TBankPayRec; RecLen: Integer): Boolean;
{function IsSigned(var P: TBankPayRec): Boolean;}
function LetterTextVarLen(LetterPtr: Pointer; RecLen: Integer): Integer;
procedure LetterTextPar(LetterPtr: Pointer; var TextBuf: PChar;
  var TextLen: Integer);
function LetterIsSigned(LetterPtr: Pointer; RecLen: Integer): Boolean;
function GetBaseName(BaseNumber: TBaseNumber): string;
function InitBasicBase(UserBase, SbTrans: Boolean): Integer;
procedure DoneBasicBase;
function GlobalBase(ABaseNumber: TBaseNumber): TExtBtrDataSet;
function GetUserByOperNum(OperNum: Integer; var AUserRec: TUserRec): Boolean;
function CurrentUser(var AUserRec: TUserRec): Boolean;
function MakeAbonKeyList(AbonId: Integer; var List1, List2, List3: string;
  var NeedComplete: DWord): Integer;
function ClientGetLoginNameProc(Login: string; var Status: Integer;
  var UserName: string): Boolean; stdcall;
{function CurrentFirm(var AFirmRec: TFirmRec;
  var AFirmAccRec: TFirmAccRec): Boolean;}
procedure TakeMenuItems(Source, Dest: TMenuItem);
{function ExchangeStateToStr(AState: Word): string;}
{procedure MakeRegNumber(var Number: Integer);}
function GetDocOp(var BillRec: TOpRec; DocId: Longint; var Len: Integer): Boolean;
function UpdateClient(Acc: string; Bik: Integer; Name, Inn, Kpp: string;
  DosCharset, UpdateKpp: Boolean): Boolean;
function OpIsSent(var po: TOpRec; c3: Longint): Boolean;
function CorrectOpSum(var AccD, AccC: TAccount; OldSum, NewSum: Int64;
  BillDate: Word; c3: Longint; var State: Word; RedSaldoList: TStringList): Boolean;
function DeleteOp(var p: TOpRec; Sender: Integer): Boolean;
function MakeReturn(DocId: Integer; RetText: string; OpDate: Word;
  var po: TOpRec): Boolean;
function MakeKart(DocId: Integer; KartText: string; OpDate: Word;
  var po: TOpRec): Boolean;
function DocInfo(var PayRec: TBankPayRec): string;
function OpInfo(OpRec: TOpRec): string;
function FillCorrList(List: TStrings; ExcludeLock: Word): Boolean;
function GetLastClosedDay: Word;
function GetFirstOpenDay: Word;
function GetPrevWorkDay(ADay: Word): Word;
function FillClientList(List: TStrings; ActDate: Word; Max: Integer): Boolean;
function TestAcc(CodeS, KsS, AccS: string; EndMes: string;
  Ask: Boolean): Boolean;
function GetUserNameByCode(UserCode: Integer): string;

implementation

uses Orakle;

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

{function IsSigned(var P: TBankPayRec): Boolean;
begin
  Result := IsThisSign(@P.dbDoc.drVar[P.dbDocVarLen]);
end;}

(*function IsSigned(var P: TBankPayRec; RecLen: Integer): Boolean;
begin
  {Result := IsThisSign(@P.dbDoc.drVar[P.dbDocVarLen]);}
  Result := CheckSign(@P.dbDoc, SizeOf(TDocRec)-drMaxVar+P.dbDocVarLen,
    RecLen-(SizeOf(TBankPayRec)-SizeOf(TDocRec)), 0, nil)>0;
end;

function LetterIsSigned(var LetterRec: TLetterRec): Boolean;
var
  i: Word;
begin
  i := StrLen(LetterRec.erText)+1;
  i := i+StrLen(@LetterRec.erText[i])+1;
  Result := CheckSign(@LetterRec.erText, i, SizeOf(LetterRec), 0, nil)>0;
end;*)

function IsSigned(var P: TBankPayRec; RecLen: Integer): Boolean;
begin
  {Result := IsThisSign(@P.dbDoc.drVar[P.dbDocVarLen]);}
  {Result := CheckSign(@P.dbDoc, SizeOf(TDocRec)-drMaxVar+P.dbDocVarLen,
    RecLen-(SizeOf(TPayRec)-SizeOf(TDocRec)), 0, nil)>0;}
  Result := SizeOf(TDocRec)-drMaxVar+P.dbDocVarLen<RecLen
    -(SizeOf(TBankPayRec)-SizeOf(TDocRec));
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
  BufSize := SizeOf(TParamNewRec)+64;
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
end; *)

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
      4: StrPLCopy(Buffer, {BooleanToStr(IsThisSign(mrSign))}'-',
        Field.DataSize-1)
    end;
  end;
end;

{ TExportDataSet }

constructor TExportDataSet.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  BufSize := SizeOf(TExportRec);
end;

procedure TExportDataSet.InternalInitFieldDefs;
begin
  FieldDefs.Clear;
  TFieldDef.Create(FieldDefs, 'erIderB', ftInteger, 0, False, 0);
  TFieldDef.Create(FieldDefs, 'erOperNum', ftInteger, 0, False, 1);
  TFieldDef.Create(FieldDefs, 'erOperation', ftInteger, 0, False, 2);
end;

function TExportDataSet.GetFieldData(Field: TField; Buffer: Pointer): Boolean;
begin
  Result := True;
  with PExportRec(ActiveBuffer)^ do
  begin
    case Field.Index of
      0: PInteger(Buffer)^ := erIderB;
      1: PInteger(Buffer)^ := erOperNum;
      2: PInteger(Buffer)^ := erOperation;
    end;
  end;
end;

{ TImportDataSet }

constructor TImportDataSet.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  BufSize := SizeOf(TImportRec)+64;
end;

procedure TImportDataSet.InternalInitFieldDefs;
begin
  FieldDefs.Clear;
  TFieldDef.Create(FieldDefs, 'irIderB', ftInteger, 0, False, 0);
  TFieldDef.Create(FieldDefs, 'irOperNum', ftInteger, 0, False, 1);
  TFieldDef.Create(FieldDefs, 'irOperation', ftInteger, 0, False, 2);
  TFieldDef.Create(FieldDefs, 'irProCode', ftInteger, 0, False, 3);
  TFieldDef.Create(FieldDefs, 'irProDate', ftString, 10, False, 4);
end;

function TImportDataSet.GetFieldData(Field: TField; Buffer: Pointer): Boolean;
begin
  Result := True;
  with PImportRec(ActiveBuffer)^ do
  begin
    case Field.Index of
      0: PInteger(Buffer)^ := irIderB;
      1: PInteger(Buffer)^ := irOperNum;
      2: PInteger(Buffer)^ := irOperation;
      3: PInteger(Buffer)^ := irProCode;
      4: StrPLCopy(Buffer, DosDateToStr(irProDate), Field.DataSize-1)
    end;
  end;
end;

{ TUserDataSet }

constructor TUserDataSet.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  BufSize := SizeOf(TUserRec)+64;
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

(*constructor TAccessDataSet.Create(AOwner: TComponent);
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

{ TFirmAccDataSet }

(*constructor TFirmAccDataSet.Create(AOwner: TComponent);
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
  Result := true;
  with PFirmAccRec(ActiveBuffer)^ do
    case Field.Index of
      0: PInteger(Buffer)^ := faNumber;
      1: StrLCopy(Buffer, faAccName, Field.DataSize-1);
      2: StrLCopy(Buffer, faAcc, Field.DataSize-1);
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
  Result := true;
  with PFirmRec(ActiveBuffer)^ do
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
end;*)

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
  TFieldDef.Create(FieldDefs,'arName',ftString, SizeOf(TKeeperName), False, 9);
  TFieldDef.Create(FieldDefs, 'arLock', ftString, 1, False, 10);
  TFieldDef.Create(FieldDefs,'Login',ftString, 9, False, 11);
end;

function TAccDataSet.GetFieldData(Field: TField; Buffer: Pointer): Boolean;
var
  //CorrDataSet: TExtBtrDataSet;
  AbonDataSet: TExtBtrDataSet;
  I: Integer;
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
        10:
          if (arOpts and asLockCl)>0 then
            StrLCopy(Buffer, 'Б', Field.DataSize-1)
          else
            StrCopy(Buffer, '');
        11:
          begin
            AbonDataSet := GlobalBase(biAbon);
            if AbonDataSet<>nil then
              with AbonDataSet do
              begin
                I := arCorr;
                if LocateBtrRecordByIndex(I, 0, bsEq) then
                  StrLCopy(Buffer, PAbonentRec(ActiveBuffer)^.abLogin,
                    Field.DataSize-1)
                else
                  StrCopy(Buffer, '-');
              end;
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
      2: StrPLCopy(Buffer, BtrDateToStr(PAccArcRec(ActiveBuffer)^.aaDate),
        Field.DataSize-1);
      3: StrPLCopy(Buffer, SumToStr(PAccArcRec(ActiveBuffer)^.aaSum),
        Field.DataSize-1);
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
  TFieldDef.Create(FieldDefs,'brName', ftString, SizeOf(TBankNameNew)+1
    , False, 2);
  TFieldDef.Create(FieldDefs,'npName', ftString, SizeOf(TSity)
    +SizeOf(TSityType)+1, False, 3);
end;

function TBankDataSet.GetFieldData(Field: TField; Buffer: Pointer): Boolean;
var
  I: LongInt;
  FNpDataSet: TExtBtrDataSet;
begin
  Result := true;
  with PBankNewRec(ActiveBuffer)^ do
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

{ TTransDataSet }

constructor TTransDataSet.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  BufSize := SizeOf(TTransRec);
end;

procedure TTransDataSet.InternalInitFieldDefs;
begin
  FieldDefs.Clear;
  TFieldDef.Create(FieldDefs, 'sbBik', ftString, 9, False, 0);
  TFieldDef.Create(FieldDefs, 'sbState', ftString, 5, False, 1);
  TFieldDef.Create(FieldDefs, 'sbName', ftString, SizeOf(TBankNameNew)+1,
    False, 2);
end;

function TTransDataSet.GetFieldData(Field: TField; Buffer: Pointer): Boolean;
var
  BankDataSet: TExtBtrDataSet;
  I: Integer;
begin
  Result := False;
  with PTransRec(ActiveBuffer)^ do
    if not IsEmpty then
    begin
      Result := True;
      case Field.Index of
        0: StrPLCopy(Buffer, FillZeros(sbBik, 9), Field.DataSize-1);
        1: StrPLCopy(Buffer, IntToStr(sbState), Field.DataSize-1);
        2:
          begin
            BankDataSet := GlobalBase(biBank);
            if BankDataSet<>nil then
              with BankDataSet do
              begin
                I := sbBik;
                if LocateBtrRecordByIndex(I, 0, bsEq) then
                  with PBankNewRec(ActiveBuffer)^ do
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
                  end
                else
                  StrCopy(Buffer, '-');
              end;
          end;
      end;
    end;
end;

{ TCorrAboDataSet }

constructor TCorrAboDataSet.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  BufSize := SizeOf(TSprAboRec);
end;

procedure TCorrAboDataSet.InternalInitFieldDefs;
begin
  FieldDefs.Clear;
  TFieldDef.Create(FieldDefs, 'saIderR', ftInteger, 0, False, 0);
  TFieldDef.Create(FieldDefs, 'saCorr', ftInteger, 0, False, 1);
  TFieldDef.Create(FieldDefs, 'saState', ftWord, 0, False, 2);
end;

function TCorrAboDataSet.GetFieldData(Field: TField; Buffer: Pointer): Boolean;
begin
  Result := True;
  with PSprAboRec(ActiveBuffer)^ do
    case Field.Index of
      0: PInteger(Buffer)^ := saIderR;
      1: PInteger(Buffer)^ := saCorr;
      2: PWord(Buffer)^ := saState;
    end;
end;

{ TCorrSprDataSet }

constructor TCorrSprDataSet.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  BufSize := SizeOf(TSprCorRec);
end;

procedure TCorrSprDataSet.InternalInitFieldDefs;
begin
  FieldDefs.Clear;
  TFieldDef.Create(FieldDefs, 'scIderR', ftInteger, 0, False, 0);
  TFieldDef.Create(FieldDefs, 'scIderC', ftInteger, 0, False, 1);
  TFieldDef.Create(FieldDefs, 'scVer', ftWord, 0, False, 2);
  TFieldDef.Create(FieldDefs, 'scType', ftString, 1, False, 3);
  TFieldDef.Create(FieldDefs, 'scData', ftString, 255, False, 4);
end;

function TCorrSprDataSet.GetFieldData(Field: TField; Buffer: Pointer): Boolean;
var
  Bik: Integer;
begin
  Result := True;
  with PSprCorRec(ActiveBuffer)^ do
    case Field.Index of
      0: PInteger(Buffer)^ := scIderR;
      1: PInteger(Buffer)^ := scIderC;
      2: PWord(Buffer)^ := scVer;
      3:
        case scType of
          psAddBank:
            StrLCopy(Buffer, 'Д', Field.DataSize-1);
          psDelBank:
            StrLCopy(Buffer, 'У', Field.DataSize-1);
          else
            StrLCopy(Buffer, '-', Field.DataSize-1);
        end;
      4:
        case scType of
          psAddBank:
            begin
              Bik := PInteger(@scData)^;
              StrLCopy(Buffer, @scData[4], Field.DataSize-5);
              DosToWin(Buffer);
              StrPLCopy(Buffer, IntToStr(Bik)+'|'+PChar(Buffer), Field.DataSize-1);
            end;
          psDelBank:
            begin
              Bik := PInteger(@scData)^;
              StrPLCopy(Buffer, IntToStr(Bik), Field.DataSize-1);
            end;
          else begin
            StrLCopy(Buffer, @scData, Field.DataSize-1);
            DosToWin(Buffer);
          end;
        end;
    end;
end;

{ TSendFileDataSet }

constructor TSendFileDataSet.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  BufSize := SizeOf(TSendFileRec);
end;

procedure TSendFileDataSet.InternalInitFieldDefs;
begin
  FieldDefs.Clear;
  TFieldDef.Create(FieldDefs, 'sfBitIder', ftWord, 0, False, 0);
  TFieldDef.Create(FieldDefs, 'sfFileIder', ftInteger, 0, False, 1);
  TFieldDef.Create(FieldDefs, 'sfAbonent', ftInteger, 0, False, 2);
  TFieldDef.Create(FieldDefs, 'sfState', ftWord, 0, False, 3);
  TFieldDef.Create(FieldDefs, 'sfData', ftString, 255, False, 4);
  TFieldDef.Create(FieldDefs, 'sfLogin', ftString, 8, False, 5);
end;

function TSendFileDataSet.GetFieldData(Field: TField; Buffer: Pointer): Boolean;
var
  I: Integer;
  //CorrDataSet: TExtBtrDataSet;
  AbonDataSet: TExtBtrDataSet;
begin
  Result := True;
  with PSendFileRec(ActiveBuffer)^ do
    case Field.Index of
      0: PWord(Buffer)^ := sfBitIder;
      1: PInteger(Buffer)^ := sfFileIder;
      2: PInteger(Buffer)^ := sfAbonent;
      3: PWord(Buffer)^ := sfState;
      4:
        begin
          StrLCopy(Buffer, @sfData, Field.DataSize-1);
          DosToWin(Buffer);
        end;
      5:
        begin
          AbonDataSet := GlobalBase(biAbon);
          if AbonDataSet<>nil then
            with AbonDataSet do
            begin
              I := sfAbonent;
              if LocateBtrRecordByIndex(I, 0, bsEq) then
                StrLCopy(Buffer, PAbonentRec(ActiveBuffer)^.abLogin, Field.DataSize-1)
              else
                StrCopy(Buffer, '-');
            end;
        end;
    end;
end;

{ TOperDataSet }

constructor TOperDataSet.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  BufSize := SizeOf(TQrmOperRec);
end;

procedure TOperDataSet.InternalInitFieldDefs;
begin
  FieldDefs.Clear;
  TFieldDef.Create(FieldDefs, 'onIder', ftWord, 0, False, 0);
  TFieldDef.Create(FieldDefs, 'onName', ftString, 64, False, 1);
  TFieldDef.Create(FieldDefs, 'onQrmName', ftString, 64, False, 2);
end;

function TOperDataSet.GetFieldData(Field: TField; Buffer: Pointer): Boolean;
begin
  Result := False;
  if not IsEmpty then
    with PQrmOperRec(ActiveBuffer)^ do
    begin
      Result := True;
      case Field.Index of
        0: PWord(Buffer)^ := onIder;
        1:
          begin
            StrLCopy(Buffer, @onName, Field.DataSize-1);
            DosToWin(Buffer);
          end;
        2:
          begin
            StrPLCopy(Buffer, OrGetUserNameByCode(onIder), Field.DataSize-1);
            {StrLCopy(Buffer, @onName, Field.DataSize-1);
            DosToWin(Buffer);}
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

{ TCorrDataSet }

(*constructor TCorrDataSet.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  BufSize := SizeOf(TCorrRecX)+32;
end;

procedure TCorrDataSet.InternalInitFieldDefs;
begin
  FieldDefs.Clear;
  TFieldDef.Create(FieldDefs,'crIder', ftInteger, 0, False, 0);
  TFieldDef.Create(FieldDefs,'crNode', ftWord, 0, False, 1);
  TFieldDef.Create(FieldDefs,'crName', ftString, 9, False, 2);
  TFieldDef.Create(FieldDefs,'crSize', ftWord, 0, False, 3);
  TFieldDef.Create(FieldDefs,'crVar', ftString, crMaxVar, False, 4);

  TFieldDef.Create(FieldDefs,'crType', ftString, 1, False, 5);
  TFieldDef.Create(FieldDefs,'crWay', ftString, 1, False, 6);
  TFieldDef.Create(FieldDefs,'crLock', ftString, 1, False, 7);
  TFieldDef.Create(FieldDefs,'crCrypt', ftString, 1, False, 8);
end;

function TCorrDataSet.GetFieldData(Field: TField; Buffer: Pointer): Boolean;
begin
  Result := False;
  with PCorrRecX(ActiveBuffer)^ do
    if not IsEmpty then
    begin
      Result := True;
      case Field.Index of
        0: PInteger(Buffer)^ := crIder;
        1: PWord(Buffer)^ := crNode;
        2: StrLCopy(Buffer, crName, Field.DataSize-1);
        3: PWord(Buffer)^ := crSize;
        4:
          begin
            StrLCopy(Buffer, @crVar, Field.DataSize-1);
            DosToWin(Buffer);
          end;
        5:
          if crType=0 then
            StrLCopy(Buffer, '', Field.DataSize-1)
          else
            StrLCopy(Buffer, 'O', Field.DataSize-1);
        6:
          if crWay=0 then
            StrLCopy(Buffer, 'S', Field.DataSize-1)
          else
            StrLCopy(Buffer, 'I', Field.DataSize-1);
        7:
          case crLock of
            1: StrLCopy(Buffer, '>', Field.DataSize-1);
            2: StrLCopy(Buffer, '<', Field.DataSize-1);
            3: StrLCopy(Buffer, 'Б', Field.DataSize-1);
            else
              StrLCopy(Buffer, '', Field.DataSize-1)
          end;
        8:
          if crCrypt<>0 then
            StrLCopy(Buffer, '+', Field.DataSize-1)
          else
            StrLCopy(Buffer, '', Field.DataSize-1)
      end;
    end;
end;*)

function DecToHex(D, L: LongWord): string;
begin
  Result := Format('%x', [D]);
  while Length(Result)<L do
    Result := '0'+Result;
end;

{ TAbonIdDataSet }

constructor TAbonIdDataSet.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  BufSize := SizeOf(TAbonIdRec)+1;
end;

procedure TAbonIdDataSet.InternalInitFieldDefs;
begin
  FieldDefs.Clear;
  TFieldDef.Create(FieldDefs, 'aiIder', ftInteger, 0, False, 0);
  TFieldDef.Create(FieldDefs, 'aiLastAuth', ftInteger, 0, False, 1);
  TFieldDef.Create(FieldDefs, 'aiHardId', ftString, 8, False, 2);
end;

function TAbonIdDataSet.GetFieldData(Field: TField; Buffer: Pointer): Boolean;
begin
  Result := False;
  with PAbonIdRec(ActiveBuffer)^ do
  begin
    if not IsEmpty then
    begin
      Result := True;
      case Field.Index of
        0: PInteger(Buffer)^ := aiIder;
        1: PInteger(Buffer)^ := aiLastAuth;
        2: StrPLCopy(Buffer, DecToHex(aiHardId, 8), Field.DataSize-1);
      end;
    end;
  end;
end;

{ TAbonSidDataSet }

constructor TAbonSidDataSet.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  BufSize := SizeOf(TAbonSignIdRec)+32;
end;

procedure TAbonSidDataSet.InternalInitFieldDefs;
begin
  FieldDefs.Clear;
  TFieldDef.Create(FieldDefs, 'asIder', ftInteger, 0, False, 0);
  TFieldDef.Create(FieldDefs, 'asAbon', ftString, SizeOf(TAbonLogin), False, 1);
  TFieldDef.Create(FieldDefs, 'asLogin', ftString, SizeOf(TAbonLogin), False, 2);
  TFieldDef.Create(FieldDefs, 'asStatus', ftWord, 0, False, 3);
  TFieldDef.Create(FieldDefs, 'asName', ftString, SizeOf(TAbonUserName), False, 4);
end;

function TAbonSidDataSet.GetFieldData(Field: TField; Buffer: Pointer): Boolean;
var
  AbonDataSet: TExtBtrDataSet;
  I: Integer;
begin
  Result := False;
  with PAbonSignIdRec(ActiveBuffer)^ do
  begin
    if not IsEmpty then
    begin
      Result := True;
      case Field.Index of
        0: PInteger(Buffer)^ := asIder;
        1:
          begin
            AbonDataSet := GlobalBase(biAbon);
            if AbonDataSet<>nil then
              with AbonDataSet do
              begin
                I := asIder;
                if LocateBtrRecordByIndex(I, 0, bsEq) then
                  StrLCopy(Buffer, PAbonentRec(ActiveBuffer)^.abLogin,
                    Field.DataSize-1)
                else
                  StrCopy(Buffer, '-');
              end;
          end;
        2: StrPLCopy(Buffer, asLogin, Field.DataSize-1);
        3: PWord(Buffer)^ := asStatus;
        4: StrPLCopy(Buffer, asName, Field.DataSize-1);
      end;
    end;
  end;
end;

{ TAbonDataSet }

constructor TAbonDataSet.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  BufSize := SizeOf(TAbonentRec)+32;
  FAbonIdDataSet := nil;
end;

procedure TAbonDataSet.SetAbonId(ADataSet: TAbonIdDataSet);
begin
  FAbonIdDataSet := ADataSet;
end;

procedure TAbonDataSet.InternalInitFieldDefs;
begin
  FieldDefs.Clear;
  TFieldDef.Create(FieldDefs, 'abIder', ftInteger, 0, False, 0);
  TFieldDef.Create(FieldDefs, 'abLogin', ftString, SizeOf(TAbonLogin), False, 1);
  TFieldDef.Create(FieldDefs, 'abOldLogin', ftString, SizeOf(TCorrName), False, 2);
  TFieldDef.Create(FieldDefs, 'abNode', ftWord, 0, False, 3);
  TFieldDef.Create(FieldDefs, 'abType', ftWord, 0, False, 4);
  TFieldDef.Create(FieldDefs, 'abWay', ftWord, 0, False, 5);
  TFieldDef.Create(FieldDefs, 'abLock', ftWord, 0, False, 6);
  TFieldDef.Create(FieldDefs, 'abSize', ftWord, 0, False, 7);
  TFieldDef.Create(FieldDefs, 'abCrypt', ftWord, 0, False, 8);
  TFieldDef.Create(FieldDefs, 'abName', ftString, SizeOf(TAbonName), False, 9);
  TFieldDef.Create(FieldDefs, 'abiLastAuth', ftInteger, 0, False, 10);
  TFieldDef.Create(FieldDefs, 'abiHardId', ftString, 8, False, 11);
end;

function TAbonDataSet.GetFieldData(Field: TField; Buffer: Pointer): Boolean;
var
  I: Integer;
begin
  Result := False;
  with PAbonentRec(ActiveBuffer)^ do
  begin
    if not IsEmpty then
    begin
      Result := True;
      case Field.Index of
        0: PInteger(Buffer)^ := abIder;
        1: StrPLCopy(Buffer, abLogin, Field.DataSize-1);
        2: StrPLCopy(Buffer, abOldLogin, Field.DataSize-1);
        3: PWord(Buffer)^ := abNode;
        4: PWord(Buffer)^ := abType;
        5: PWord(Buffer)^ := abWay;
        6: PWord(Buffer)^ := abLock;
        7: PWord(Buffer)^ := abSize;
        8: PWord(Buffer)^ := abCrypt;
        9:
          begin
            StrPLCopy(Buffer, abName, Field.DataSize-1);
            DosToWin(Buffer);
          end;
        10:
          begin
            if FAbonIdDataSet<>nil then
              with FAbonIdDataSet do
              begin
                I := abIder;
                if LocateBtrRecordByIndex(I, 0, bsEq) then
                  PInteger(Buffer)^ := PAbonIdRec(ActiveBuffer)^.aiLastAuth
                else
                  PInteger(Buffer)^ := 0;
              end;
          end;
        11:
          begin
            if FAbonIdDataSet<>nil then
              with FAbonIdDataSet do
              begin
                I := abIder;
                if LocateBtrRecordByIndex(I, 0, bsEq) then
                  StrPLCopy(Buffer,
                    DecToHex(PAbonIdRec(ActiveBuffer)^.aiHardId, 8), Field.DataSize-1)
                else
                  StrCopy(Buffer, '-');
              end;
          end;
        else
          Result := False;
      end;
    end;
  end;
end;

{ TLetterDataSet }

constructor TLetterDataSet.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  BufSize := SizeOf(TLetterRec)+64;
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
  TFieldDef.Create(FieldDefs, 'erAdrName', ftString, 8, False, 10);
  TFieldDef.Create(FieldDefs, 'erMes', ftString, {erMaxVar}1023, False, 11);
end;

function TLetterDataSet.GetFieldData(Field: TField; Buffer: Pointer): Boolean;
var
  AbonDataSet: TExtBtrDataSet;
  I: Integer;
  S: string;
  TxtBuf: PChar;
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
        {10:
          begin
            I := StrLen(erText)+1;
            StrLCopy(Buffer, @erText[I], Field.DataSize-1);
            DosToWin(Buffer);
          end;}
        10:
          begin
            if lrAdr = BroadcastNode then
              StrLCopy(Buffer, BroadcastLogin, Field.DataSize-1)
            else begin
              AbonDataSet := GlobalBase(biAbon);
              if AbonDataSet<>nil then
                with AbonDataSet do
                begin
                  I := lrAdr;
                  if LocateBtrRecordByIndex(I, 0, bsEq) then
                    StrLCopy(Buffer, PAbonentRec(ActiveBuffer)^.abLogin, Field.DataSize-1)
                  else
                    StrCopy(Buffer, '-');
                end;
            end;
          end;
        11:
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
  Result := True;
  with PFilePieceRec(ActiveBuffer)^ do
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
  TFieldDef.Create(FieldDefs, 'brState', ftWord, 0, False, 4);
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
        4: PWord(Buffer)^ := brState;
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
          StrPCopy(Buffer, '-');
      end;
    end;
end;

{ TPayDataSet }

constructor TPayDataSet.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  BufSize := SizeOf(TBankPayRec)+128;
end;

procedure TPayDataSet.InternalInitFieldDefs;
begin
  FieldDefs.Clear;

  TFieldDef.Create(FieldDefs,'IdHere', ftInteger,0,False,0);
  TFieldDef.Create(FieldDefs,'IdKorr', ftInteger,0,False,1);
  TFieldDef.Create(FieldDefs,'IdSender', ftInteger,0,False,2);
  TFieldDef.Create(FieldDefs,'IdDoc', ftInteger,0,False,3);
  TFieldDef.Create(FieldDefs,'IdArc', ftInteger,0,False,4);
  TFieldDef.Create(FieldDefs,'IdDel', ftInteger,0,False,5);

  TFieldDef.Create(FieldDefs,'UserCode', ftInteger,0,False, 6);
  TFieldDef.Create(FieldDefs,'State', ftString, 11, False, 7);
  TFieldDef.Create(FieldDefs,'Export', ftString, 1, False, 8);
  TFieldDef.Create(FieldDefs,'DateS', ftString, DateStrLen, False, 9);
  TFieldDef.Create(FieldDefs,'TimeS', ftWord,0,False, 10);
  TFieldDef.Create(FieldDefs,'DateR', ftString, DateStrLen, False, 11);
  TFieldDef.Create(FieldDefs,'TimeR', ftWord,0,False,12);
  TFieldDef.Create(FieldDefs,'DateP', ftString, DateStrLen, False,13);
  TFieldDef.Create(FieldDefs,'TimeP', ftWord, 0, False, 14);
  TFieldDef.Create(FieldDefs,'DocLen', ftWord, 0, False, 15);

  TFieldDef.Create(FieldDefs,'drDate', ftString, DateStrLen, False, 16);
  TFieldDef.Create(FieldDefs,'drSum', ftString, SumStrLen, False, 17);
  TFieldDef.Create(FieldDefs,'drSrok', ftString, DateStrLen, False, 18);
  TFieldDef.Create(FieldDefs,'drType', ftString, 3, False, 19);
  TFieldDef.Create(FieldDefs,'drIsp', ftString, 10, False, 20);
  TFieldDef.Create(FieldDefs,'drOcher', ftWord, 0, False, 21);

  TFieldDef.Create(FieldDefs,'drVO', ftString, 2, False, 22);
  TFieldDef.Create(FieldDefs,'SumRus', ftString, 255, False, 23);
  TFieldDef.Create(FieldDefs,'DateOp', ftString, DateStrLen, False, 24);
  TFieldDef.Create(FieldDefs,'Exported', ftString, 1, False, 25);
  TFieldDef.Create(FieldDefs,'InputDate', ftString, DateStrLen, False, 26);

  TFieldDef.Create(FieldDefs,'DocNum',ftString, 5, False, 27);
  TFieldDef.Create(FieldDefs,'Pacc',ftString, SizeOf(TAccount), False, 28);
  TFieldDef.Create(FieldDefs,'Pks',ftString, SizeOf(TAccount), False, 29);
  TFieldDef.Create(FieldDefs,'Pcode',ftString, 9, False, 30);
  TFieldDef.Create(FieldDefs,'PInn',ftString, SizeOf(TInn), False, 31);
  TFieldDef.Create(FieldDefs,'PName',ftString, 160, False, 32);
  TFieldDef.Create(FieldDefs,'PbName',ftString, 70, False, 33);
  TFieldDef.Create(FieldDefs,'Racc',ftString, SizeOf(TAccount), False, 34);
  TFieldDef.Create(FieldDefs,'Rks',ftString, SizeOf(TAccount), False, 35);
  TFieldDef.Create(FieldDefs,'Rcode',ftString, 9, False, 36);
  TFieldDef.Create(FieldDefs,'RInn',ftString, SizeOf(TInn), False, 37);
  TFieldDef.Create(FieldDefs,'RName',ftString, 160, False, 38);
  TFieldDef.Create(FieldDefs,'RbName',ftString, 70, False, 39);
  TFieldDef.Create(FieldDefs,'NaznP',ftString, 400, False, 40);
  TFieldDef.Create(FieldDefs,'PKpp', ftString, 9, False, 41);
  TFieldDef.Create(FieldDefs,'RKpp', ftString, 9, False, 42);
  TFieldDef.Create(FieldDefs,'NalPayer', ftString, 2, False, 43);
  TFieldDef.Create(FieldDefs,'Kbk', ftString, 20, False, 44);
  TFieldDef.Create(FieldDefs,'Okato', ftString, 11, False, 45);
  TFieldDef.Create(FieldDefs,'OsnPl', ftString, 2, False, 46);
  TFieldDef.Create(FieldDefs,'Period', ftString, 10, False, 47);
  TFieldDef.Create(FieldDefs,'NDoc', ftString, 15, False, 48);
  TFieldDef.Create(FieldDefs,'DocDate', ftString, 10, False, 49);
  TFieldDef.Create(FieldDefs,'Tp', ftString, 2, False, 50);
  TFieldDef.Create(FieldDefs,'Nchpl', ftString, 3, False, 51);
  TFieldDef.Create(FieldDefs,'Shifr', ftString, 3, False, 52);
  TFieldDef.Create(FieldDefs,'Nplat', ftString, 5, False, 53);
  TFieldDef.Create(FieldDefs,'OstSum', ftString, 15, False, 54);
  TFieldDef.Create(FieldDefs,'AcceptSr', ftString, DateStrLen, False, 55);
  TFieldDef.Create(FieldDefs,'SignMes', ftString, 40, False, 56);
  TFieldDef.Create(FieldDefs,'ReceiveMes', ftString, 51, False, 57);
  TFieldDef.Create(FieldDefs,'BillDate', ftString, DateStrLen, False, 58);
  TFieldDef.Create(FieldDefs,'UserName', ftString, 32, False, 59);
end;

{function ExchangeStateToStr(AState: Word): string;
begin
  Result := '';
  if dsExport and AState <> 0 then
    Result := Result + 'выгружен';
end;}

function GetDocOp(var BillRec: TOpRec; DocId: Longint; var Len: Integer): Boolean;
var
  Res: integer;
  KeyL: longint;
  BillDataSet: TExtBtrDataSet;
begin
  Result := False;
  BillDataSet := GlobalBase(biBill);
  KeyL := DocId;
  Len := SizeOf(BillRec);
  Res := BillDataSet.BtrBase.GetEqual(BillRec, Len, KeyL, 1);
  while ((Res=0) {or (Res=22)}) and (BillRec.brDocId=DocId) and (BillRec.brDel<>0) do
  begin
    Len := SizeOf(BillRec);
    Res := BillDataSet.BtrBase.GetNext(BillRec, Len, KeyL, 1);
  end;
  if ((Res=0) {or (Res=22)}) and (BillRec.brDocId=DocId) then
    Result := True;
end;

function DocWasExported(DocId: Longint; InBank: Boolean): Char;
var
  Len, Res: Integer;
  ExportDataSet: TExtBtrDataSet;
  ExportRec: TExportRec;
begin
  Result := '-';
  ExportDataSet := GlobalBase(biExport);
  if ExportDataSet<>nil then
  begin
    Len := SizeOf(ExportRec);
    Res := ExportDataSet.BtrBase.GetEqual(ExportRec, Len, DocId, 0);
    if Res=0 then
    begin
      if InBank then
        Result := 'B'
      else
        Result := 'K'
    end
    else
      Result := ' ';
  end;
end;

function DocStateToStr(PayRecPtr: PBankPayRec; RecLen: Integer): string;
var
  BillRec: TOpRec;
  I: Integer;
begin
  Result := '';
  if GetDocOp(BillRec, PayRecPtr^.dbIdHere, I) then
    with BillRec do
    begin
      case brPrizn of
        brtReturn:
          begin
            case brState and dsAnsType of
              dsAnsSent:
                Result := '<ВОЗВРАТ';
              dsAnsRcv:
                Result := 'ВОЗВРАТ';
              else
                Result := 'возврат';
            end;
          end;
        brtKart:
          begin
            case brState and dsAnsType of
              dsAnsSent:
                Result := '<КАРТОТЕКА';
              dsAnsRcv:
                Result := 'КАРТОТЕКА';
              else
                Result := 'картотека';
            end;
          end;
        brtBill:
          begin
            Result := 'ПРОВЕДЕН';
            if ((brState and dsSndType)=dsSndRcv)
              and ((brState and dsAnsType)=dsAnsRcv)
              and ((brState and dsReSndType)=dsReSndRcv)
            then
              Result := 'СКВИТОВАН'
            else
              if (brState and dsAnsType)=dsAnsRcv then
              begin
                if (brState and dsReSndType)=dsReSndSent then
                  Result := '>ПРОВЕДЕН'
                else
                  if (brState and dsSndType)=dsSndSent then
                    Result := '<ПРОВЕДЕН'
                  else
                    Result := 'ПРОВЕДЕН';
              end
              else
                if (brState and dsReSndType)=dsReSndRcv then
                begin
                //Добавлено Меркуловым
                  if PayRecPtr^.dbState and dsRsAfter<>0 then
                    Result := 'ПОЛ.ПОС'
                  else
                //Конец
                    Result := 'ПОЛУЧЕН';
                  if (brState and dsAnsType)=dsAnsSent then
                  //Добавлено Меркуловым
                    if PayRecPtr^.dbState and dsRsAfter<>0 then
                      Result := '<ПОЛ.ПОС'
                    else
                  //Конец
                      Result := '<ПОЛУЧЕН';
                end
                else
                  if ((brState and dsAnsType)=dsAnsSent) and
                    ((brState and dsReSndType)=dsReSndSent)
                  then
                    Result := '=ПРОВЕДЕН'
                  else
                    if (brState and dsAnsType)=dsAnsSent then
                      Result := '{ПРОВЕДЕН'
                    else
                      if (brState and dsReSndType)=dsReSndSent then
                        Result := '}ПРОВЕДЕН';
          end;
        else
          Result := '?';
      end;
    end
  else begin
    if PayRecPtr^.dbIdSender<>0 then
    //Добавлено Меркуловым
    begin
      if PayRecPtr^.dbState and dsRsAfter<>0 then
        Result := 'пол.пос'
      else
    //Конец
        Result := 'получен';
    end                                         //Добавлено Меркуловым
    else begin
      I := RecLen-(SizeOf(TBankPayRec)-drMaxVar+PayRecPtr^.dbDocVarLen);
      if I<0 then
        I := 0;
      case I of
        0:
          Result := '';
        92:
          Result := 'подп.уст.';
        else
          Result := 'подписан';
      end;
      {Len := CheckSign(@PayRecPtr^.dbDoc, SizeOf(TDocRec)-drMaxVar
        +PayRecPtr^.dbDocVarLen, RecLen-(SizeOf(TBankPayRec)-SizeOf(TDocRec)), 0, nil);
      case Len of
        ceiTcbGost:
          Result := 'подп.уст.';
        ceiDomenK:
          Result := 'подписан';
        else
          Result := '';
      end;}
    end;
  end;
end;

function GetUserNameByCode(UserCode: Integer): string;
var
  OperDataSet: TExtBtrDataSet;
  QrmOperRec: TQrmOperRec;
  Res, Len: Integer;
begin
  Result := '';
  OperDataSet := GlobalBase(biOper);
  if OperDataSet<>nil then
    if OperDataSet.Active then
    begin
      Len := SizeOf(QrmOperRec);
      Res := OperDataSet.BtrBase.GetEqual(QrmOperRec, Len, UserCode, 0);
      if Res=0 then
      begin
        Result := StrPas(QrmOperRec.onName);
        if Length(Result)>SizeOf(QrmOperRec.onName) then
          Result := Copy(Result, 1, SizeOf(QrmOperRec.onName));
      end;
    end;
end;

const
  PayTypeNames: array[0..2] of string[10]= ('почтой','телеграфом','электронно');

function TPayDataSet.GetFieldData(Field: TField; Buffer: Pointer): Boolean;
var
  Offset, ZeroPos: Integer;
  Text: array[0..511] of Char;
  BillRec: TOpRec;
  S: string;
begin
  Result := False;
  with PBankPayRec(ActiveBuffer)^ do
  begin
    if not IsEmpty and (GetActiveRecLen>0) then
    begin
      Result := True;
      case Field.Index of
        0: PInteger(Buffer)^ := dbIdHere;
        1: PInteger(Buffer)^ := dbIdKorr;
        2: PInteger(Buffer)^ := dbIdSender;
        3: PInteger(Buffer)^ := dbIdDoc;
        4: PInteger(Buffer)^ := dbIdArc;
        5: PInteger(Buffer)^ := dbIdDel;
        6: PInteger(Buffer)^ := Abs(dbUserCode);
        7:
          StrPLCopy(Buffer, DocStateToStr(PBankPayRec(ActiveBuffer),
            GetActiveRecLen), Field.DataSize-1);
          //StrPLCopy(Buffer, IntToStr(GetActiveRecLen), Field.DataSize-1);
        8:
          if dsExport and PBankPayRec(ActiveBuffer)^.dbState = 0 then
            StrPLCopy(Buffer, '>', Field.DataSize-1)
          else
            StrPLCopy(Buffer, '', Field.DataSize-1);
        9: StrPLCopy(Buffer, BtrDateToStr(dbDateS), Field.DataSize-1);
        10: PWord(Buffer)^ := dbTimeS;
        11: StrPLCopy(Buffer, BtrDateToStr(dbDateR), Field.DataSize-1);
        12: PWord(Buffer)^ := dbTimeR;
        13: StrPLCopy(Buffer, BtrDateToStr(dbDateP), Field.DataSize-1);
        14: PWord(Buffer)^ := dbTimeP;
        15: PWord(Buffer)^ := dbDocVarLen;
        16: StrPLCopy(Buffer, BtrDateToStr(dbDoc.drDate), Field.DataSize-1);
        17:
        begin
          StrPLCopy(Text, SumToStr(dbDoc.drSum), Field.DataSize-1);
          StrCopy(Buffer, Text);
        end;
        18: StrPLCopy(Buffer, BtrDateToStr(dbDoc.drSrok), Field.DataSize-1);
        19: StrPLCopy(Buffer, FillZeros(dbDoc.drType,2), Field.DataSize-1);
        20: StrPLCopy(Buffer, PayTypeNames[dbDoc.drIsp], Field.DataSize-1);
        21: PWord(Buffer)^ := dbDoc.drOcher;
        22:
          begin
            Offset := dbDoc.drType;
            if Offset>100 then
              Offset := Offset-100;
            StrPLCopy(Buffer, FillZeros(Offset, 2), Field.DataSize-1);
          end;
        23: StrPLCopy(Buffer, SumToRus(dbDoc.drSum), Field.DataSize-1);
        24,26,58: {DateOp,InputDate,BillDate}
          begin
            if GetDocOp(BillRec, PBankPayRec(ActiveBuffer)^.dbIdHere, Offset) then
            begin
              if (Field.Index<>58) or (BillRec.brPrizn=brtBill) then
                StrPLCopy(Buffer, BtrDateToStr(BillRec.brDate), Field.DataSize-1)
              else
                StrCopy(Buffer, #0)
            end
            else
              if Field.Index=24 then
                StrCopy(Buffer, #0)
              else
                StrPLCopy(Buffer, BtrDateToStr(DateToBtrDate(Date)),
                  Field.DataSize-1)
          end;
        25:
          StrPLCopy(Buffer, DocWasExported(dbIdHere, dbUserCode<0), Field.DataSize-1);
        27..54:
          begin
            ZeroPos := Field.Index-27;
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
        55:
          StrCopy(Buffer, #0);
        56:
          begin
            if dbIdSender=0 then
              StrCopy(Buffer, #0)
            else
              StrPLCopy(Buffer, 'Документ подписан электронной подписью',
                Field.DataSize-1)
          end;
        57:
          begin
            if dbIdSender=0 then
              StrCopy(Buffer, #0)
            else begin
              S := 'Получено по системе "БАНК-КЛИЕНТ"';
              {if dbDateR>0 then
              begin
                S := S + ' ' + BtrDateToStr(dbDateR);
                if dbTimeR>0 then
                  S := S + ' ' + BtrTimeToStr(dbTimeR);
              end;}
              StrPLCopy(Buffer, S, Field.DataSize-1)
            end;
          end;
        59:
          begin
            if dbUserCode=0 then
              StrCopy(Buffer, #0)
            else begin
              StrPLCopy(Buffer, GetUserNameByCode(Abs(dbUserCode)),
                Field.DataSize-1);
              DosToWin(Buffer);
            end;
          end;
        else
          MessageBox(0, PChar('Для поля таблицы N'+IntToStr(Field.Index)
            +' не определено чтение поля записи'), 'Чтение записи',
            MB_OK or MB_ICONERROR)
      end;
    end;
  end;
end;

(*procedure TPayDataSet.ViewDocumentIder(ADocIder: Integer);
var
  Code, OldKeyNum: Integer;
  CurPos: TBookMark;
begin
  CurPos := GetBookMark;
  OldKeyNum := KeyNum;
  KeyNum := 0;
  First;
  if LocateBtrRecordByIndex(ADocIder, 0, bsEq) then
  begin
    UpdateCursorPos;
    Code:=Fields.Fields[18].AsInteger;
    UpdateDocumentByCode(True, False, True, Code)
  end
  else
    MessageBox(0, 'Этого документа нет в вашей базе', 'Просмотр документа',
      MB_OK or MB_ICONINFORMATION);
  GotoBookMark(CurPos);
  FreeBookMark(CurPos);
  KeyNum := OldKeyNum;
end;*)

type
  TBaseInfo = record
    biName: string;
    biAccess: TBtrOpenMode;
  end;

const
  BaseCount = Ord(High(TBaseNumber))+1;
  BaseFiles: array[0..BaseCount-1] of TBaseInfo =
   ((biName:'users.btr';    biAccess:bmNormal),
    (biName:'sanctn.btr';   biAccess:bmNormal),
    (biName:'acc.btr';      biAccess:bmNormal),
    (biName:'accarc.btr';   biAccess:bmNormal),
    (biName:'banknp.btr';   biAccess:bmNormal),
    (biName:'bankn.btr';    biAccess:bmNormal),
    (biName:'clientn.btr';  biAccess:bmNormal),
    //(biName:'corr.btr';     biAccess:bmNormal),
    (biName:'abonid.btr';   biAccess:bmNormal),
    (biName:'abonsid.btr';  biAccess:bmNormal),
    (biName:'abon.btr';     biAccess:{bmReadOnly}bmNormal),
    (biName:'email.btr';    biAccess:bmNormal),
    (biName:'bill.btr';     biAccess:bmNormal),
    (biName:'doc.btr';      biAccess:bmNormal),
    (biName:'files.btr';    biAccess:bmNormal),
    (biName:'module.btr';   biAccess:bmNormal),
    (biName:'export.btr';   biAccess:bmNormal),
    (biName:'import.btr';   biAccess:bmNormal),
    (biName:'trans.btr';    biAccess:bmNormal),
    (biName:'corrabo.btr';  biAccess:bmNormal),
    (biName:'corrspr.btr';  biAccess:bmNormal),
    (biName:'sendfile.btr'; biAccess:bmNormal),
    (biName:'oper.btr'; biAccess:bmNormal)
    );

function GetBaseName(BaseNumber: TBaseNumber): string;
begin
  if (Ord(BaseNumber)>=0) and (Ord(BaseNumber)<BaseCount) then
    Result := BaseFiles[Ord(BaseNumber)].biName
  else
    Result := '<unknown>';
end;

function InitBasicBase(UserBase, SbTrans: Boolean): Integer;
var                          
  ABaseNumber: TBaseNumber;
  ADataSet: TBtrDataSet;
  AFileName: TFileName;
  ErrMes: string;
begin
  Result := 0;
  ErrMes := '';
  if FGlobalBases=nil then
  begin
    FGlobalBases := TList.Create;
    for ABaseNumber := biUser to biOper do
      FGlobalBases.Add(nil);
  end;
  for ABaseNumber := biUser to biOper do
    if FGlobalBases.Items[Ord(ABaseNumber)]=nil then
    begin
      AFileName := '';
      case ABaseNumber of
        biAcc, biAccArc, biBill, {biCorr, }biCorrAbo, biCorrSpr, biPay,
        biLetter, biExport, biImport, biTrans, biSendFile:
          if UserBase then
          begin
            AFileName := UserBaseDir;
          end;
        else
          if not UserBase then
          begin
            case ABaseNumber of
              biAbonId, biAbon, biAbonSid:
                AFileName := DecodeMask('$(PostMashBase)', 5, CommonUserNumber);
              else
                AFileName := DecodeMask('$(Base)', 5, CommonUserNumber);
            end;
          end;
      end;
      if Length(AFileName)>0 then
      begin
        AFileName := AFileName + BaseFiles[Ord(ABaseNumber)].biName;
        case ABaseNumber of
          biUser: ADataSet := TUserDataSet.Create(Application);
          biSanction: ADataSet := TSanctionDataSet.Create(Application);
          biAcc: ADataSet := TAccDataSet.Create(Application);
          biAccArc: ADataSet := TAccArcDataSet.Create(Application);
          biNp: ADataSet := TNpDataSet.Create(Application);
          biBank: ADataSet := TBankDataSet.Create(Application);
          biClient: ADataSet := TClientDataSet.Create(Application);
          //biCorr: ADataSet := TCorrDataSet.Create(Application);
          biAbonId: ADataSet := TAbonIdDataSet.Create(Application);
          biAbonSid: ADataSet := TAbonSidDataSet.Create(Application);
          biAbon:
            begin
              ADataSet := TAbonDataSet.Create(Application);
              (ADataSet as TAbonDataSet).SetAbonId(
                GlobalBase(biAbonId) as TAbonIdDataSet);
            end;
          biLetter: ADataSet := TLetterDataSet.Create(Application);
          biBill: ADataSet := TBillDataSet.Create(Application);
          biPay: ADataSet := TPayDataSet.Create(Application);
          biFile: ADataSet := TFileDataSet.Create(Application);
          biModule: ADataSet := TModuleDataSet.Create(Application);
          biExport: ADataSet := TExportDataSet.Create(Application);
          biImport: ADataSet := TImportDataSet.Create(Application);
          biTrans:
            begin
              ADataSet := TTransDataSet.Create(Application);
              if SbTrans then
                AFileName := ChangeFileExt(AFileName, '.sb');
            end;
          biCorrAbo: ADataSet := TCorrAboDataSet.Create(Application);
          biCorrSpr: ADataSet := TCorrSprDataSet.Create(Application);
          biSendFile: ADataSet := TSendFileDataSet.Create(Application);
          biOper: ADataSet := TOperDataSet.Create(Application);
          else
            ADataSet := nil;
        end;
        FGlobalBases.Items[Ord(ABaseNumber)] := ADataSet;
        with ADataSet do
        begin
          try
            TableName := AFileName;
            Mode := BaseFiles[Ord(ABaseNumber)].biAccess;
            Active := True;
            Inc(Result);
          except
            ErrMes := ErrMes+#13#10+AFileName;
          end;
        end;
      end;
    end;
  if Length(ErrMes)>0 then
    MessageBox(0, PChar('Не удалось открыть базы:'+ErrMes),
      'Инициализация баз', MB_OK or MB_ICONERROR);
end;

procedure DoneBasicBase;
begin
  if FGlobalBases<>nil then
  begin
    while FGlobalBases.Count>0 do
    begin
      if FGlobalBases.Items[FGlobalBases.Count-1]<>nil then
        TObject(FGlobalBases.Items[FGlobalBases.Count-1]).Free;
      FGlobalBases.Delete(FGlobalBases.Count-1);
    end;
    FGlobalBases.Free;
    FGlobalBases := nil;
  end;
end;

procedure SetUserNumber(Value: Integer);
begin
  FUserNumber := Value;
end;

function GetUserNumber: Integer;
begin
  Result := FUserNumber;
end;

procedure SetFirmNumber(Value: Integer);
begin
  FFirmNumber := Value;
end;

function UserBaseDir: string;
begin
  Result := DecodeMask('$(Base)', 5, FUserNumber);
  if (Length(Result)>0) and (Result[Length(Result)]='\') then
    System.Delete(Result, Length(Result), 1);
  Result := Result+'.'+FillZeros(FFirmNumber, 3)+'\';
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

function MakeAbonKeyList(AbonId: Integer; var List1, List2, List3: string;
  var NeedComplete: DWord): Integer;
var
  AbonSidDataSet: TExtBtrDataSet;
  AbonSidRec: TAbonSignIdRec;
  Res, Len, Id: Integer;
begin
  Result := -1;
  AbonSidDataSet := GlobalBase(biAbonSid);
  if AbonSidDataSet<>nil then
  begin
    List1 := '';
    List2 := '';
    List3 := '';
    Result := 0;
    NeedComplete := 0;
    Id := AbonId;
    Len := SizeOf(AbonSidRec);
    Res := AbonSidDataSet.BtrBase.GetEqual(AbonSidRec, Len, Id, 1);
    while (Res=0) and (Id=AbonId) do
    begin
      Inc(Result);
      if usDirector and AbonSidRec.asStatus>0 then
        AddWordInList(AbonSidRec.asLogin, List1);
      if usAccountant and AbonSidRec.asStatus>0 then
        AddWordInList(AbonSidRec.asLogin, List2);
      if usCourier and AbonSidRec.asStatus>0 then
        AddWordInList(AbonSidRec.asLogin, List3);
      NeedComplete := NeedComplete or AbonSidRec.asStatus;
      Len := SizeOf(AbonSidRec);
      Res := AbonSidDataSet.BtrBase.GetNext(AbonSidRec, Len, Id, 1);
    end;
  end;
end;

function ClientGetLoginNameProc(Login: string; var Status: Integer;
  var UserName: string): Boolean; stdcall;
var
  AbonSidDataSet: TExtBtrDataSet;
  AbonSidRec: TAbonSignIdRec;
  Res, Len, Id: Integer;
  AbLog: TAbonLogin;
begin
  Result := False;
  //Status := 0;
  //UserName := '';
  AbonSidDataSet := GlobalBase(biAbonSid);
  if AbonSidDataSet<>nil then
  begin
    FillChar(AbLog, SizeOf(TAbonLogin), #0);
    StrPLCopy(AbLog, Login, SizeOf(TAbonLogin)-1);
    Len := SizeOf(AbonSidRec);
    Res := AbonSidDataSet.BtrBase.GetEqual(AbonSidRec, Len, AbLog, 2);
    if Res=0 then
    begin
      Result := True;
      Status := AbonSidRec.asStatus;
      UserName := StrPas(AbonSidRec.asName);
    end;
  end;
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
  ParamVec: TParamKey1;
  ParamRec: TParamNewRec;
  Res, Len: Integer;
begin
  RegistrBase := GetRegistrBase;
  Result := RegistrBase<>nil;
  if Result then
    with RegistrBase do
    begin
      FillChar(ParamVec, SizeOf(ParamVec), #0);
      StrPLCopy(ParamVec.pkIdent, ASancName, SizeOf(ParamVec.pkIdent)-1);
      ParamVec.pkUser := CommonUserNumber;
      Len := SizeOf(ParamRec);
      Res := RegistrBase.GetEqual(ParamRec, Len, ParamVec, 1);
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

(*function CurrentFirm(var AFirmRec: TFirmRec;
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
end;
*)
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
      if GetRegParamByName('PopupIcons', FUserNumber, ShowIcon) then
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
      MessageBox(0, 'Ошибка регистрации документа в реестре',
        'Получение уникального номера', MB_OK or MB_ICONERROR);
  end
  else
    Number := -1;
end;*)

const
  DosKpp: PChar = #$8A#$8F#$8F;
  
function UpdateClient(Acc: string; Bik: Integer; Name, Inn, Kpp: string;
  DosCharset, UpdateKpp: Boolean): Boolean;
const
  MesTitle: PChar = '-юсртыхэшх ъышхэЄр';
var
  ClientDataSet: TExtBtrDataSet;
  Len, Res, I: Integer;
  ClientKey: packed record
    kCodeB: LongInt;                            {20,4     k0.0}
    kAccC:  TAccount;                           {0,20     k0.1}
  end;
  ClientRec, ClientRec2: TNewClientRec;
  NameKpp: string;
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
    FillChar(ClientKey, SizeOf(ClientKey), #0);
    with ClientKey do
    begin
      kAccC := ClientRec.clAccC;
      kCodeB := ClientRec.clCodeB;
    end;
    if (StrLen(ClientRec.clKpp)=0) and (Length(NameKpp)>0) then
      StrPLCopy(ClientRec.clKpp, NameKpp, SizeOf(ClientRec.clKpp)-1);
    Res := ClientDataSet.BtrBase.GetEqual(ClientRec2, Len, ClientKey, 0);
    if Res=0 then
    begin
      if not UpdateKpp and (StrLen(ClientRec.clKpp)=0) then
        ClientRec.clKpp := ClientRec2.clKpp;
      Res := ClientDataSet.BtrBase.Update(ClientRec, Len, ClientKey, 0);
      if Res=0 then
        Result := True
      else
        MessageBox(ParentWnd, PChar('=х єфрыюё№ юсэютшЄ№ ъышхэЄр BtrErr='
          +IntToStr(Res)), MesTitle, MB_OK or MB_ICONERROR);
    end
    else begin
      Len := SizeOf(ClientRec);
      Res := ClientDataSet.BtrBase.Insert(ClientRec, Len, ClientKey, 0);
      if Res=0 then
        Result := True
      else
        MessageBox(ParentWnd, PChar('=х єфрыюё№ фюсртшЄ№ ъышхэЄр BtrErr='
          +IntToStr(Res)), MesTitle, MB_OK or MB_ICONERROR);
    end;
    ClientDataSet.Refresh;
  end
  else
    MessageBox(ParentWnd, '+рчр ъышхэЄют эх юЄъЁvЄр', MesTitle, MB_OK or MB_ICONERROR);
end;

function OpIsSent(var po: TOpRec; c3: Longint): Boolean;
var
  Res, Len: integer;
  w: word;
  c1, c2: longint;
  KeyA: TAccount;
  pa: TAccRec;
  AccDataSet: TExtBtrDataSet;
begin
  AccDataSet := GlobalBase(biAcc);
  c1 := 0; c2 := 0; w := 0;
  KeyA := po.brAccD;
  Len := SizeOf(pa);
  Res := AccDataSet.BtrBase.GetEqual(pa, Len, KeyA, 1);
  if Res=0 then
    c1 := pa.arCorr;
  KeyA := po.brAccC;
  Len := SizeOf(pa);
  Res := AccDataSet.BtrBase.GetEqual(pa, Len, KeyA, 1);
  if Res=0 then
    c2 := pa.arCorr;
  if c1<>0 then
    w := w or (po.brState and dsAnsSent); //dsAnsRcv
  if (c2<>0) and (c2<>c1) then
    w := w or (po.brState and dsReSndSent);  //dsReSndRcv
  if (c3<>0) and (c3<>c1) and (c3<>c2) then
    w := w or (po.brState and dsSndSent); //dsSndRcv
  Result := w<>0;
end;

function CorrectOpSum(var AccD, AccC: TAccount; OldSum, NewSum: Int64;
  BillDate: Word; c3: Longint; var State: Word; RedSaldoList: TStringList): Boolean;
const
  MesTitle: PChar = 'Корректировка суммы проводки';
var
  pa: TAccRec;
  Res, Len: integer;
  KeyA: TAccount;
  w: word;
  c1, c2: longint;

  procedure AddAccMes(Acc, CName: string; Sum: Int64; ActiveAcc: Word);
  var
    I: Integer;
    S: string;
  begin
    if RedSaldoList<>nil then
    begin
      Acc := Trim(Acc);
      I := RedSaldoList.IndexOfName(Acc);
      S := IntToStr(ActiveAcc)+':'+SumToStr(Sum)+' - '+DosToWinS(CName);
      if I>=0 then
        RedSaldoList.Strings[I] := Acc+'='+S
      else
        RedSaldoList.Add(Acc+'='+S);
    end;
  end;

  function WrongAccSum(IsAccC: Byte): Boolean;
  var
    S: string;
  begin
    Result := False;
    if (pa.arSumA<0) and ((pa.arOpts and asType)=asPassive) then
    begin
      Result := (RedSaldoList=nil) and (MessageBox(Application.Handle,
        PChar('В результате операции образуется'+
        ' кредитовое по счету '+pa.arAccount+'. Выполнять операцию?'),
        MesTitle, MB_YESNOCANCEL or MB_ICONWARNING) <> ID_YES);
      AddAccMes(pa.arAccount, pa.arName, pa.arSumA, asPassive);
    end
    else
      if (pa.arSumA>0) and ((pa.arOpts and asType)=asActive) then
      begin
        //RedSaldoErrCode := rseDebAccD shl IsAccC;
        Result := (RedSaldoList=nil) and (MessageBox(Application.Handle,
          PChar('В результате операции образуется'+
          ' дебетовое по счету '+pa.arAccount+'. Выполнять операцию?'),
          MesTitle, MB_YESNOCANCEL or MB_ICONWARNING) <> ID_YES);
        AddAccMes(pa.arAccount, pa.arName, pa.arSumA, asActive);
      end;
  end;

var
  AccDataSet: TExtBtrDataSet;
begin
  Result := False;
  AccDataSet := GlobalBase(biAcc);
  c1 := 0; c2 := 0; w := 0;
  KeyA := AccD;
  Len := SizeOf(pa);
  Res := AccDataSet.BtrBase.GetEqual(pa, Len, KeyA, 1);
  if (Res=0) and DateIsActive(BillDate, pa.arDateO, pa.arDateC) then
  begin
    pa.arSumA := pa.arSumA + OldSum - NewSum;
    WrongAccSum(0)
  end;
  KeyA := AccC;
  Len := SizeOf(pa);
  Res := AccDataSet.BtrBase.GetEqual(pa, Len, KeyA, 1);
  if Res=0 then
  begin
    c2 := pa.arCorr;
    if DateIsActive(BillDate, pa.arDateO, pa.arDateC) then
    begin
      pa.arSumA := pa.arSumA-OldSum+NewSum;
      WrongAccSum(1);
      Inc(pa.arVersion);
      pa.arOpts := (pa.arOpts and not asSndType) or asSndMark;
      Res := AccDataSet.BtrBase.Update(pa, Len, KeyA, 1);
      if Res<>0 then  
        Exit;
    end  
    else  
      c2 := -c2;  
  end;
  KeyA := AccD;  
  Len := SizeOf(pa);  
  Res := AccDataSet.BtrBase.GetEqual(pa, Len, KeyA, 1);
  if Res=0 then
  begin  
    c1 := pa.arCorr;
    if DateIsActive(BillDate, pa.arDateO, pa.arDateC) then
    begin
      pa.arSumA := pa.arSumA + OldSum - NewSum;
      Inc(pa.arVersion);
      pa.arOpts := (pa.arOpts and not asSndType) or asSndMark;  
      Res := AccDataSet.BtrBase.Update(pa, Len, KeyA, 1);  
      if Res<>0 then
        Exit;
    end
    else  
      c1 := -c1;  
  end;
  if c1<=0 then  
    w := w or dsAnsRcv;
  if (c2<=0) or (c1>0) and (c1=c2) then
    w := w or dsReSndRcv;  
  if (c3<=0) or (c1>0) and (c1=c3) or (c2>0) and (c2=c3) then  
    w := w or dsSndRcv;
  State := w;  
  Result := True;
end;

function DeleteOp(var p: TOpRec; Sender: Integer): Boolean;
var
  W: Word;
  RedSaldoErrCode: Integer;
begin
  Result := false;
  if p.brPrizn=brtBill then
  begin
    if not CorrectOpSum(p.brAccD, p.brAccC, Round(p.brSum), 0, p.brDate,
      Sender, W, nil) then
    begin
      Exit;
    end;
    p.brState := W;
  end
  else
    if (p.brPrizn=brtReturn) or (p.brPrizn=brtKart) then
      p.brState := 0;
  p.brDel := 1;
  Inc(p.brVersion);
  Result := true;
end;

function MakeReturn(DocId: Integer; RetText: string; OpDate: Word;
  var po: TOpRec): Boolean;
var
  Res, Len, KeyL: Integer;
  BillDataSet: TExtBtrDataSet;
begin
  BillDataSet := GlobalBase(biBill);
  FillChar(po, SizeOf(po), #0);
  with po do
  begin
    MakeRegNumber(rnPaydoc, brIder);
    brDocId := DocId;
    StrPLCopy(brRet, RetText, brMaxRet-1);
    WinToDos(brRet);
    brPrizn := brtReturn;
    brDate := OpDate;
    Inc(brVersion);
    Len := 17+StrLen(brRet)+1;
    KeyL := brIder;
  end;
  Res := BillDataSet.BtrBase.Insert(po, Len, KeyL, 0);
  Result := Res=0;
end;

function MakeKart(DocId: Integer; KartText: string; OpDate: Word;
  var po: TOpRec): Boolean;
var
  Res, Len, KeyL: Integer;
  BillDataSet: TExtBtrDataSet;
begin
  BillDataSet := GlobalBase(biBill);
  FillChar(po, SizeOf(po), #0);
  with po do
  begin
    MakeRegNumber(rnPaydoc, brIder);
    brDocId := DocId;
    StrPLCopy(brKart, KartText, brMaxKart-1);
    WinToDos(brKart);
    brPrizn := brtKart;
    brDate := OpDate;
    Inc(brVersion);
    Len := 17+StrLen(brKart)+1;
    KeyL := brIder;
  end;
  Res := BillDataSet.BtrBase.Insert(po, Len, KeyL, 0);
  Result := Res=0;
end;

function DocInfo(var PayRec: TBankPayRec): string;
begin
  Result := '[N'+PayRec.dbDoc.drVar+'  '
    +BtrDateToStr(PayRec.dbDoc.drDate)+'  '
    +SumToStr(PayRec.dbDoc.drSum)+' руб.]';
end;

function OpInfo(OpRec: TOpRec): string;
begin
  with OpRec do
  begin
    Result := '{'+BtrDateToStr(brDate)+' N'+IntToStr(brNumber)+' ВО'
      +IntToStr(brType)+' '+SumToStr(brSum)+' руб. Id='+IntToStr(brIder)+'}';
  end;
end;

function FillCorrList(List: TStrings; ExcludeLock: Word): Boolean;
var
  //CorrDataSet: TCorrDataSet;
  AbonDataSet: TExtBtrDataSet;
  //CorrRec: TCorrRecX;
  AbonRec: TAbonentRec;
  Len, Res: Integer;
  S: string;
  AbonName: TAbonName;
begin
  Result := False;
  AbonDataSet := GlobalBase(biAbon) as TExtBtrDataSet;
  if (AbonDataSet<>nil) and (List<>nil) then
  begin
    Result := True;
    List.Clear;
    with AbonDataSet.BtrBase do
    begin
      Len := SizeOf(AbonRec);
      Res := GetFirst(AbonRec, Len, AbonName, 1);
      while Res=0 do     
      begin
        if AbonRec.abLock and ExcludeLock = 0 then
        begin
          DosToWin(AbonRec.abName);
          S := AbonRec.abLogin;
          while Length(S)<8 do
            S := S+' ';
          List.AddObject(S+' | '+AbonRec.abName, TObject(AbonRec.abIder));
        end;
        Len := SizeOf(AbonRec);
        Res := GetNext(AbonRec, Len, AbonName, 1);
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

function GetPrevWorkDay(ADay: Word): Word;
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
  while (Res=0) and (BillRec.brDel<>0) do
  begin
    Len := SizeOf(BillRec);
    Res := BillDataSet.BtrBase.GetPrev(BillRec, Len, KeyO, 2);
  end;
  if Res=0 then
    Result := BillRec.brDate;
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


end.

