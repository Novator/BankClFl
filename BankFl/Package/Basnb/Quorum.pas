unit Quorum;

interface

uses
  Classes, Btrieve, SysUtils, Windows, Forms, Dialogs, Utilits;

const
  qtByte    = 3;
  qtWord    = 4;
  qtLongint = 6;
  qtDate    = 7;
  qtTime    = 8;
  qtDouble  = 11;
  qtString  = 12;

const
  DeleteText: string = #$93+#$84+#$80+#$8B; {'УДАЛ' в дос-кодировке}
  //Добавлено Меркуловым
  BankNameText: string = 'Џ…ђЊ‘Љ€‰ ”€‹€Ђ‹ "’ЉЃ" (‡ЂЋ) ѓ Џ…ђЊњ';

type
  TDicName = string[20];
  TDicTitle = string[40];

  TFileDicRec = packed record
    frCode: Word;                        {Код таблицы}  {k0}
    frName: TDicName;                    {Имя таблицы}  {k1}
    frOwnerName: string[8];              {Имя владельца}
    frTitle: TDicTitle;                  {Заголовок таблицы} {k2}
    frLoc: string[65];                   {Имя файла}         {k3}
    frCheckSum: Longint;                 {Контрольная сумма}
    frLoc2: string[61];                  {Не применяется}
    frFlags: Word;                       {Флаги}
    frFormat: Byte;                      {Формат файла}
    frAttr: Word;                        {Атрибуты файла}
    frPageSize: Word;                    {Размер страницы}
    frRecordFixed: Word;                 {Размер фиксированной части записи}
    frRecordSize: Word;                  {Размер записи}
  end;

  PFieldDicRec = ^TFieldDicRec;
  TFieldDicRec = packed record
    fiCode: Word;              {Код поля  0,2}    {k0.2}
    fiFileCode: Word;          {Код файла 2,2}   {k0.1} {k1.1} {k2.1}
    fiName: TDicName;          {Имя поля  4,21}           {k1.2}         {k3}
    fiTitle: TDicTitle;        {Заголовок поля  25,41}            {k2.2}  {k4}
    fiDataType: Byte;          {Тип поля  66,1}
    fiOffset: Word;            {Смещение  67,2}
    fiSize: Word;              {Размер    69,2}
    fiTypeCode: Word;          {Код типа данных 71,2}
  end;                                        {73}

  TAccCurrKey = packed record
    ackOpen_Close: Word;
    ackCurrCode: string[3];
    ackAccNum: string[10];
  end;

  TAccSortCurrKey = packed record
    ascAccSort: string[12];
    ascCurrCode: string[3];
  end;

  TProKey = packed record
    pkProDate: Integer;
    pkProCode: Longint;
  end;

//Добавлено Меркуловым
  TCashKey = packed record
    pcNumOp: LongInt;
    pcStat:  Word;
  end;

//Добавлено Меркуловым
  TKbkKey = packed record
    dsCode: Word;
    dsShifrV: string[80];                //Изменено
  end;

  TKvitKey = packed record
    kkDoneFlag: Word;
    kkOperation: Word;
    kkOperNum: Longint;
    kkStatus: word;
  end;

  TQuorumBase = class(TComponent)
  private
    FBuffer: PChar;
    FFieldDef: TStringList;
    FFileRec: TFileDicRec;
    FBtrBase: TBtrBase;
    FFileName: string;
    FOpenMode: Word;
  protected
    function GetActive: Boolean;
    function GetFieldDef(Index: Integer): TFieldDicRec;
    function GetFieldDefCount: Integer;
    function GetAsInteger(Index: Integer): Integer;
    function GetAsFloat(Index: Integer): Double;
    function GetAsString(Index: Integer): string;
    procedure SetAsInteger(Index: Integer; Value: Integer);
    procedure SetAsFloat(Index: Integer; Value: Double);
    procedure SetAsString(Index: Integer; Value: string);
    function GetFieldPtr(Index: Integer): PFieldDicRec;
    function FieldInfo(Index: Integer): string;
  public
    property Buffer: PChar read FBuffer;
    property Active: Boolean read GetActive;
    property FileRec: TFileDicRec read FFileRec;
    property FieldDefs[Index: Integer]: TFieldDicRec read GetFieldDef;
    property FieldDefCount: Integer read GetFieldDefCount;
    property AsInteger[Index: Integer]: Integer read GetAsInteger
      write SetAsInteger;
    property AsFloat[Index: Integer]: Double read GetAsFloat write SetAsFloat;
    property AsString[Index: Integer]: string read GetAsString write SetAsString;
    property BtrBase: TBtrBase read FBtrBase;
    property OpenMode: Word read FOpenMode write FOpenMode;
    property FileName: string read FFileName;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function Init(BaseName: string): Boolean;
    procedure Done;
    function GetFieldIndexByName(S: string): Integer;
    procedure GetIndexes(S: TStrings);
  end;

const
  coPayOrderOperation     = 1102;
  coMemOrderOperation     = 1103;
  coCashOrderOperation    = 1116;
  coRecognizeSumOperation = 1101;
  coVypOperation          = 1106;
  coVbKartotOperation     = 1113;

var
  poPreStatus, poCurrCodeCorr, poCurrCodePay, poDocNum, poDocDate,
    poInDate, poPayAcc, poBenefAcc, poDocType, poPaySum, poKAY, poStatus,
    poStatusHlp, poBatchNum, poUserCode, poOperCode, poCorrAcc, poSenderBankNum,
    poSenderMFO, poSenderUchCode, poSenderCorrAcc, poReceiverMFO, poReceiverCorrAcc,
    poReceiverUchCode, poSenderCorrCode, poReceiverBankNum, poReceiverCorrCode,
    poBranch, poSendType, poBatchType, poOrderType, poPriority, poRaceNum,
    poZaklObor, poPosDate, poProcDate, poValueDate, poPayTelegSum, poOperNum,
    poBenefTaxNum, poBenefName, poINNOur, poClientNameOur, poClientAcc,
    poKppOur, poBenefKpp: Integer;                          //Добавлено Меркуловым

  acAccNum, acAccPlch, acAccName, acClientCode, acAccStatus, acOpen_Close,
    acCurrCode, acOpenDate, acCloseDate, acOperNum, acContNum, acRightBuffer,
    acChSum, acClientMessage, acValueCode, acAccEndDate, acDayCount,
    acAccNewPlch, acNewAccNum, acShifrMask, acUserGroupCode, acPriority,
    acDivCode, acOwerContNum, acReAccPr, acReAccount, acRedCheck, acAccSort,
    acAccCourse, acKindCont, acKindAcc, acKindSaldo, acOraF_ID_Filial,
    acWayOfExt, acPerAmount, acPerType: Integer;
  bnBankNum, bnRkcNum, bnMfo, bnUchCode, bnCorrAcc, bnBankCorrAcc, bnTypeAbbrev,
    bnBankName, bnAdress: Integer;
  crnAccTheir: Integer;
  pcOperNum, pcStatus, pcComment, pcComOwner: Integer;
  moDbAcc, moDbCurrCode, moKrAcc, moKrCurrCode, moDocNum, moDocDate, moBranch,
    moUserCode, moBatchType, moBatchNum, moOperNum, moStatus, moPreStatus,
    moBreak, moMassDocNum, moOrderType, moPro_Col, moDoc_Col, moInOperation,
    moInOperNum, moPaySum, moVpCode, moPrNum, moPosDate, moProcDate,
    moUserControl, moControlLink, moStatusHlp, moOperCode, moKay, moPayKrSum,
    moPayNatSum, moZaklObor, moWhatConv, moAddInfo, moTypeKvit, moRaceNum,
    moRaceDate, moKvitPossMask, moSumValue, moStorno, moRef, moReserv: Integer;
  coDocDate, coDocCode, coOperCode, coUserCode, coDocNum, coStatus, coOperation,
    coOperNum, coAccount, coCurrCode, coCourse, coCommission, coCommissionPerc,
    coCashAcc, coCashCurrCode, coSumma_rec, coSumma_exp, coPrintFlag, coBatNum,
    coKay, coContNum, coPreStatus, coStatusHlp, coFastChrg, coRemSum, coDocType,
    coControlLink, coFIO, coNumCheck, coSerCheck, coPasp, coOldSerPasp,
    coNumPasp, coResident, coNumSpraw, coNotPay, coMultiPay, coConvFlag,
    coAccSumma, coEqvSumma, coSerPasp, coNewUserCode, coOldNomination,
    coKvitPossMask, coRef, coCommissionCurr, coDocNumAdd, coWorkStr: Integer;
  osdDocCode, osdSymbol, osdSumma, osdOldNom, osdSymbolCorr, osdSummaCorr,
    osdWorkStr: Integer;
  csSymbol, csFlag: Integer;
  prProDate, prProCode, prDocDate, prDocCode, prDocNum, prContNum, prOperCode,
    prUserCode, prDbCurrCode, prDbAcc, prKrCurrCode, prKrAcc, prExtAcc,
    prBatNum, prKay, prZaklObor, prWorkStr, prDocKind, prOperation,
    prOperation1, prOperNum, prOperNum1, prCash, prSumPro, prSumValPro,
    prStorno, prBankCode, prSumKrValPro: Integer;
  clClientCode, clClientName, clByte255a, clShortName, clAdress, clTelephone,
    clHasModem, clPrizJur, clPropertyCode, clCodeOKPO, clRegisSer, clRegisNum,
    clRegisDate, clRegisLocation, clTaxNum, clTaxDate, clTaxNumGNI,
    clTaxLocation, clPasport, clBankNum, clPayAccOld, clClType, clRezident,
    clCoClientClass, clCoClientType, clCuratorCode, clF775, clShifrMask,
    clHasVoice, clCOPF, clCOATO, clCountryCode, clPayAcc, clClFromOffice,
    clDocType, clSerPasp, clNumPasp, clDatePasp, clReasCode, clTaxDocType,
    clUserCode, clWorkStr: Integer;
  kvInOperation, kvInOperNum, kvInStatus, kvOutOperation, kvOutOperNum,
    kvOutStatus, kvProcessDate, kvProcessSysDate, kvProcessTime, kvDoneFlag,
    kvKvitType, kvUserCode, kvArcMask, kvOutStatusNew, kvOraF_ID_Kvitan,
    kvPrimaryDoc, kvWorkStr: Integer;
  ccComment: Integer;
  cdProDate, cdProCode, cdSymbol, cdSumma: Integer;
  caComment: Integer;
  dpProDate, dpProCode, dpDocDate, dpDocCode, dpDocNum, dpContNum, dpOperCode,
    dpUserCode, dpDbCurrCode, dpDbAcc, dpKrCurrCode, dpKrAcc, dpCorrAcc,
    dpExtAcc, dpBatNum, dpKay, dpZaklObor, dpWorkStr, dpDocKind, dpOperation,
    dpOperation1, dpOperNum, dpOperNum1, dpCash, dpSumPro, dpSumValPro,
    dpStorno, dpBankCode, dpSumKrValPro, dpCurrentDate, dpCurrentTime,
    dpDelUser, dpUnloadSeq: Integer;
  {vkOldKartNum, vkAccNum, vkCurrCode, vkCorrAcc, vkCurrCodeCorr, vkDocNum,
    vkDocDate, vkBranch, vkSenderCorrCode, vkSenderBankNum, vkSenderMfo,
    vkSenderUchCode, vkOldSenderCorrAcc, vkReceiverCorrCode, vkReceiverBankNum,
    vkReceiverMfo, vkReceiverUchCode, vkOldReceiverCorrAcc, vkOldBenefAcc,
    vkDocType, vkUserCode,} vkOperNum, {vkStatus, vkPreStatus, vkBreak, vkPro_Col,
    vkDoc_Col,} vkInOperation, vkInOperNum{, vkPaySum, vkVpCode, vkPrNum,
    vkRospDate, vkAllSum, vkBankNumInUse, vkOperCode, vkStatusHlp, vkPosDate,
    vkProcDate, vkUserControl, vkControlLink, vkValueDate, vkPriority,
    vkOldBenefTaxNum, vkRaceNum, vkOrderNumber, vkLinkStatus, vkRaceDate,
    vkMassDocNum, vkOrderType, vkBatchType, vkBatchNum, vkPayTelegSum,
    vkBenefName, vkSendType, vkAcceptDate, vkKay, vkZaklObor, vkBenefTaxNum},
    vkKartNum{, vkSenderCorrAcc, vkReceiverCorrAcc, vkBenefAcc, vkClVbAcc,
    vkClKartAcc, vkNoVbUch, vkNoPartAccept, vkAkcept, vkClKartCurrCode,
    vkPayNatSum, vkindate, vkInsKrtDate, vkReserv}: Integer;
  dsOperation, dsOperNum, dsTypeCode, dsShifrValue: Integer;
  lmProDate, lmAcc, lmCurrCode, lmLim, lmLimVal, lmDbTurn, lmDbTurnVal,
    lmKrTurn, lmKrTurnVal, lmLastDate, lmRevCount, lmOperCount: Integer;
  vkmOperNum, vkmAccNum, vkmCurrCode, vkmUserCode, vkmPaySum, vkmDateMove,
    vkmStatus, vkmPreStatus, vkmCode, vkmPayNatSum: Integer;
  //Добавлено Меркуловым
  dsvTypeCode, dsvShifrValue, dsvShifrName: Integer;
  ckClientCode, ckKPP, ckDefault_: Integer;

const
  NumOfQrmBases = 22;                   //Добавлено Меркуловым

  qbPayOrder    = 1;
  qbAccounts    = 2;
  qbBanks       = 3;
  qbCorRespNew  = 4;
  qbPayOrCom    = 5;
  qbMemOrder    = 6;
  qbCashOrder   = 7;
  qbCashOSD     = 8;
  qbCashSym     = 9;
  qbPro         = 10;
  qbClients     = 11;
  qbKvitan      = 12;
  qbCashComA    = 13;
  qbCashsDA     = 14;
  qbCommentADoc = 15;
  qbDelPro      = 16;
  qbVbKartOt    = 17;
  qbDocsBySh    = 18;
  qbLim         = 19;
  qbVKrtMove    = 20;
  qbDocShfrV    = 21;                              //Добавлено Меркуловым
  qbCliKpp      = 22;                              //Добавлено Меркуловым

  QrmBaseNames: array[1..NumOfQrmBases] of PChar = (
    'PayOrder', 'Accounts', 'Banks', 'CorRespNew', 'PayOrCom', 'MemOrder',
    'CashOrder', 'CashOSD', 'CashSym', 'Pro', 'Clients', 'Kvitan', 'CashComA',
    'CashsDA', 'CommentADoc', 'DelPro', 'VbKartOt', 'DocsByShifr', 'Lim',
    'VKrtMove',
    'DocShfrValues', 'CliKpp');                    //Добавлено Меркуловым

var
  QrmBases: array[1..NumOfQrmBases] of TQuorumBase;

const
  KvitStatus = 50;


procedure SetDictDir(Value: string);
function DictDir: string;
procedure SetDataDir(Value: string);
function DataDir: string;
procedure SetQuorumDir(Value: string);
function QuorumDir: string;
function QuorumDictDir: string;
function QuorumDataDir: string;
function DecodeQuorumPath(S: string): string;
procedure CloseDictionary;
function OpenDictionary: Boolean;
function QrmBasesIsOpen: Boolean;
procedure GetQrmOpenedBases(var Opened, All: Integer);
function InitQuorumBase(QuorumDir, DictDir, DataDir: string): Boolean;
procedure DoneQuorumBase;
function DocumentIsExistInQuorum(Operation: Word; OperNum: Integer;
  var Status: Word): Integer;
function KbkNotExistInQBase(ClientKBK: ShortString): Boolean;   //Добавлено Меркуловым
function CompareKpp(ClntRS, ClntKpp: string): Boolean;//Добавлено Меркуловым
function SeeNationalCurr: string;
function GetAccAndCurrByNewAcc(Acc: ShortString;
  var AccNum, CurrCode: ShortString; var UserCode: Integer): Boolean;
function GetNewAccByAccAndCurr(AccNum, CurrCode: ShortString;
  var Acc: ShortString): Boolean;
function GetClientByAcc(ClientAcc, ClientCurrCode: ShortString;
  var ClientInn, ClientName, ClientNewAcc: ShortString): Boolean;
function GetLimByAccAndDate(AccNum, CurrCode: ShortString;
  ProDate: Integer; var Sum: Double): Boolean;
function GetBankByRekvisit(BankNum: ShortString; Info: Boolean; var CorrCode,
  UchCode, MFO, CorrAcc: ShortString): Boolean;
function GetSenderCorrAcc(CurrCode, CorrAcc: ShortString): ShortString;
function GetChildOperNumByKvitan(InOperation: Word; InOperNum: Longint;
  NeedOutOperation: Word): Integer;
function GetParentOperNumByKvitan(OutOperation: Word; OutOperNum: Longint;
  NeedInOperation: Word): Integer;
function GetCashNazn(S: string): string;
function SortAcc(AccNum: ShortString): ShortString;

implementation

var
  FDictDir: string = 'TESTDICT\';
  FDataDir: string = 'TESTDATA\';
  FQuorumDir: string = 'F:\QUORUM.703\';

function SlashDir(S: string): string;
var
  L: Integer;
begin
  Result := S;
  L := Length(Result);
  if (L>0) and (Result[L]<>'\') then
    Result := Result + '\';
end;

procedure SetDictDir(Value: string);
begin
  FDictDir := SlashDir(Value);
end;

function DictDir: string;
begin
  Result := FDictDir;
end;

procedure SetDataDir(Value: string);
begin
  FDataDir := SlashDir(Value);
end;

function DataDir: string;
begin
  Result := FDataDir;
end;

procedure SetQuorumDir(Value: string);
begin
  FQuorumDir := SlashDir(Value);
end;

function QuorumDir: string;
begin
  Result := FQuorumDir;
end;

function QuorumDictDir: string;
begin
  Result := FQuorumDir + FDictDir;
end;

function QuorumDataDir: string;
begin
  Result := FQuorumDir + FDataDir;
end;

function DecodeQuorumPath(S: string): string;
const
  Key1: string = '%DATA_PATH%DATA\';
var
  I: Integer;
begin
  S := Trim(UpperCase(S));
  I := Pos(Key1, S);
  if I>0 then
  begin
    I := I+Length(Key1);
    S := QuorumDataDir+Copy(S, I, Length(S)-I+1);
  end;
  I := Pos('%', S);
  while I>0 do
  begin
    Delete(S, I, 1);
    I := Pos('%', S);
  end;
  Result := S;
end;

var
  FileBase: TBtrBase = nil;
  FieldBase: TBtrBase = nil;

procedure CloseDictionary;
begin
  if FileBase<>nil then
  begin
    FileBase.Close;
    FileBase.Free;
    FileBase := nil;
  end;
  if FieldBase<>nil then
  begin
    FieldBase.Close;
    FieldBase.Free;
    FieldBase := nil;
  end;
end;

function OpenDictionary: Boolean;
const
  MesTitle: PChar = 'Открытие словаря';
var
  Res: Integer;
  Buf: array[0..511] of Char;
begin
  Result := FileBase<>nil;
  if not Result then
  begin
    FileBase := TBtrBase.Create;
    FieldBase := TBtrBase.Create;
    StrPLCopy(Buf, QuorumDictDir+'file.adf', SizeOf(Buf)-1);
    Res := FileBase.Open(Buf, baReadOnly);
    Result := Res=0;
    if Result then
    begin
      StrPLCopy(Buf, QuorumDictDir+'field.adf', SizeOf(Buf)-1);
      Res := FieldBase.Open(Buf, baReadOnly);
      Result := Res=0;
      if not Result then
        ProtoMes(plError, MesTitle, 'Не удалось открыть ['+Buf+'] BtrErr='+IntToStr(Res));
    end
    else
      ProtoMes(plError, MesTitle, 'Не удалось открыть ['+Buf+']');
    if not Result then
      CloseDictionary;
  end;
end;

function QrmTypeToStr(AType: Word): string;
begin
  case AType of
    qtByte:
      Result := 'Byte';
    qtWord:
      Result := 'Word';
    qtLongint:
      Result := 'Longint';
    qtDate:
      Result := 'Date';
    qtTime:
      Result := 'Time';
    qtDouble:
      Result := 'Double';
    qtString:
      Result := 'String';
    else
      Result := 'unknown';
  end;
end;

constructor TQuorumBase.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FFieldDef := TStringList.Create;
  FBuffer := nil;
  FBtrBase := nil;
  FFileName := '';
  FOpenMode := baNormal;
  Done;
end;

destructor TQuorumBase.Destroy;
begin
  Done;
  FFieldDef.Free;
  inherited Destroy;
end;

function TQuorumBase.GetActive: Boolean;
begin
  Result := FBuffer<>nil;
end;

function TQuorumBase.GetFieldDef(Index: Integer): TFieldDicRec;
var
  P: Pointer;
begin
  with FFieldDef do
    if Index<Count then
      P := Objects[Index]
    else
      P := nil;
  if P=nil then
    FillChar(Result, SizeOf(Result), #0)
  else
    Move(P^, Result, SizeOf(Result));
end;

function TQuorumBase.GetFieldDefCount: Integer;
begin
  Result := FFieldDef.Count;
end;

function TQuorumBase.GetFieldIndexByName(S: string): Integer;
begin
  Result := FFieldDef.IndexOf(S);
end;

procedure TQuorumBase.GetIndexes(S: TStrings);
var
  I: Integer;
begin
  for I := 0 to S.Count do
    S.Objects[I] := TObject(GetFieldIndexByName(S.Strings[I]));
end;

procedure TQuorumBase.Done;
var
  P: Pointer;
begin
  if FBtrBase<>nil then
  begin
    if Length(FFileName)>0 then
      FBtrBase.Close;
    FBtrBase.Free;
    FBtrBase := nil;
  end;
  if FBuffer<>nil then
  begin
    FreeMem(FBuffer);
    FBuffer := nil;
  end;
  with FFieldDef do
    while Count>0 do
    begin
      P := Objects[Count-1];
      if P<>nil then
        FreeMem(P);
      Delete(Count-1);
    end;
  FillChar(FFileRec, SizeOf(FFileRec), #0);
end;

function TQuorumBase.Init(BaseName: string): Boolean;
const
  MesTitle: PChar = 'Инициализация q-записи';
var
  Res, Len: Integer;
  N: TDicName;
  FieldKey:
    packed record
      fiFileCode: Word;
      fiName: TDicName;
    end;
  FieldRec: TFieldDicRec;
  P: Pointer;
begin
  Result := FileBase<>nil;
  if Result then
  begin
    Result := False;
    Done;
    N := BaseName;
    Len := SizeOf(FFileRec);
    Res := FileBase.GetEqual(FFileRec, Len, N, 1);
    if Res=0 then
    begin
      GetMem(FBuffer, FFileRec.frRecordFixed);
      FillChar(FBuffer^, FFileRec.frRecordFixed, #0);

      FieldKey.fiFileCode := FileRec.frCode;
      FillChar(FieldKey.fiName, SizeOf(FieldKey.fiName), #0);
      Len := SizeOf(FieldRec);
      Res := FieldBase.GetGE(FieldRec, Len, FieldKey, 1);
      while (Res=0) and (FieldRec.fiFileCode = FileRec.frCode) do
      begin
        GetMem(P, SizeOf(FieldRec));
        Move(FieldRec, P^, SizeOf(FieldRec));
        FFieldDef.AddObject(FieldRec.fiName, P);
        Len := SizeOf(FieldRec);
        Res := FieldBase.GetNext(FieldRec, Len, FieldKey, 1);
      end;

      FBtrBase := TBtrBase.Create;
      FFileName := DecodeQuorumPath(FileRec.frLoc);
      Res := FBtrBase.Open(FFileName, FOpenMode);
      Result := Res=0;
      if not Result then
      begin
        ProtoMes({plError}plWarning, MesTitle, 'Не удалось открыть таблицу ['+FFileName
          +']. BtrErr='+IntToStr(Res)+' база ['+BaseName+']');
        FFileName := '';
      end;
    end
    else begin
      FillChar(FFileRec, SizeOf(FFileRec), #0);
      ProtoMes(plError, MesTitle, 'Таблица ['+BaseName
        +'] не найдена в словаре. BtrErr='+IntToStr(Res)+' база ['+BaseName+']');
    end;
  end
  else
    ProtoMes(plWarning, MesTitle, 'Словарь закрыт');
end;

function TQuorumBase.GetFieldPtr(Index: Integer): PFieldDicRec;
const
  MesTitle: PChar = 'GetFieldPtr';
begin
  if (Index>=0) and (Index<FFieldDef.Count) then
    Result := Pointer(FFieldDef.Objects[Index])
  else begin
    Result := nil;
    ProtoMes(plWarning, MesTitle, 'Запрос поля недопустимого индекса '+IntToStr(Index));
  end;
end;

function TQuorumBase.FieldInfo(Index: Integer): string;
var
  P: PFieldDicRec;
begin
  P := GetFieldPtr(Index);
  Result := P^.fiName+':'+QrmTypeToStr(P^.fiTypeCode);
end;

function TQuorumBase.GetAsInteger(Index: Integer): Integer;
const
  MesTitle: PChar = 'GetAsInteger';
var
  P: PFieldDicRec;
begin
  P := GetFieldPtr(Index);
  {showmessage(MesTitle+' : '+P^.fiName+' - '+ IntToStr(P^.fiOffset));}
  case P^.fiDataType of
    qtByte:
      Result := PByte(@FBuffer[P^.fiOffset])^;
    qtWord:
      Result := PWord(@FBuffer[P^.fiOffset])^;
    qtLongint, qtDate, qtTime:
      Result := PLongInt(@FBuffer[P^.fiOffset])^;
    qtDouble:
      Result := Round(PDouble(@FBuffer[P^.fiOffset])^);
    qtString:
      try
        Result := StrToInt(PShortString(@FBuffer[P^.fiOffset])^);
      except
        Result := 0;
      end;
    else begin
      Result := 0;
      ProtoMes(plError, MesTitle, 'Недопустимое чтение по индексу поля '
        +IntToStr(Index));
    end;
  end;
end;

function TQuorumBase.GetAsFloat(Index: Integer): Double;
const
  MesTitle: PChar = 'GetAsFloat';
var
  P: PFieldDicRec;
begin
  P := GetFieldPtr(Index);
  {showmessage(MesTitle+' : '+P^.fiName+' - '+ IntToStr(P^.fiOffset));}
  case P^.fiDataType of
    qtByte:
      Result := PByte(@FBuffer[P^.fiOffset])^;
    qtWord:
      Result := PWord(@FBuffer[P^.fiOffset])^;
    qtLongint, qtDate, qtTime:
      Result := PLongInt(@FBuffer[P^.fiOffset])^;
    qtDouble:
      Result := PDouble(@FBuffer[P^.fiOffset])^;
    qtString:
      try
        Result := StrToFloat(PShortString(@FBuffer[P^.fiOffset])^);
      except
        Result := 0.0;
      end;
    else begin
      Result := 0;
      ProtoMes(plError, MesTitle, 'Недопустимое чтение по индексу поля '
        +IntToStr(Index));
    end;
  end;
end;

function TQuorumBase.GetAsString(Index: Integer): string;
const
  MesTitle: PChar = 'GetAsString';
var
  P: PFieldDicRec;
begin
  P := GetFieldPtr(Index);
     {showmessage(MesTitle+' : '+P^.fiName+' - '+ IntToStr(P^.fiOffset));}
  case P^.fiDataType of
    qtString:
      Result := PShortString(@FBuffer[P^.fiOffset])^;
    qtByte:
      Result := IntToStr(PByte(@FBuffer[P^.fiOffset])^);
    qtWord:
      Result := IntToStr(PWord(@FBuffer[P^.fiOffset])^);
    qtLongint, qtDate, qtTime:
      Result := IntToStr(PLongInt(@FBuffer[P^.fiOffset])^);
    qtDouble:
      Result := FloatToStr(PDouble(@FBuffer[P^.fiOffset])^);
    else begin
      Result := '';
      ProtoMes(plError, MesTitle, 'Недопустимое чтение по индексу поля '
        +IntToStr(Index));
    end;
  end;
end;

procedure FieldErrorMes(Index, Code: Integer; MesTitle: PChar);
begin
  ProtoMes(plError, MesTitle, 'Недопустимое присвоение '+IntToStr(Code)
    +' по индексу поля ' +IntToStr(Index));
end;

procedure TQuorumBase.SetAsInteger(Index: Integer; Value: Integer);
const
  MesTitle: PChar = 'SetAsInteger';
var
  P: PFieldDicRec;
begin
  P := GetFieldPtr(Index);
     {showmessage(MesTitle+' : '+P^.fiName+' - '+ IntToStr(P^.fiOffset));}
  case P^.fiDataType of
    qtString:
      PShortString(@FBuffer[P^.fiOffset])^ := Copy(IntToStr(Value), 1, P^.fiSize-1);
    qtByte:
      PByte(@FBuffer[P^.fiOffset])^ := Value;
    qtWord:
      PWord(@FBuffer[P^.fiOffset])^ := Value;
    qtLongint, qtDate, qtTime:
      PLongInt(@FBuffer[P^.fiOffset])^ := Value;
    qtDouble:
      PDouble(@FBuffer[P^.fiOffset])^ := Value;
    else
      FieldErrorMes(Index, P^.fiDataType, MesTitle);
  end;
end;

procedure TQuorumBase.SetAsFloat(Index: Integer; Value: Double);
const
  MesTitle: PChar = 'SetAsFloat';
var
  P: PFieldDicRec;
begin
  P := GetFieldPtr(Index);
     {showmessage(MesTitle+' : '+P^.fiName+' - '+ IntToStr(P^.fiOffset));}
  case P^.fiDataType of
    qtByte:
      PByte(@FBuffer[P^.fiOffset])^ := Round(Value);
    qtWord:
      PWord(@FBuffer[P^.fiOffset])^ := Round(Value);
    qtLongint, qtDate, qtTime:
      PLongInt(@FBuffer[P^.fiOffset])^ := Round(Value);
    qtDouble:
      PDouble(@FBuffer[P^.fiOffset])^ := Value;
    qtString:
      PShortString(@FBuffer[P^.fiOffset])^ := Copy(FloatToStr(Value), 1, P^.fiSize-1);
    else
      FieldErrorMes(Index, P^.fiDataType, MesTitle);
  end;
end;

procedure TQuorumBase.SetAsString(Index: Integer; Value: string);
const
  MesTitle: PChar = 'SetAsString';
var
  P: PFieldDicRec;
begin
  P := GetFieldPtr(Index);
     {showmessage(MesTitle+' : '+P^.fiName+' - '+ IntToStr(P^.fiOffset));}
  case P^.fiDataType of
    qtString:
      PShortString(@FBuffer[P^.fiOffset])^ := Copy(Value, 1, P^.fiSize-1);
    qtByte:
      try
        PByte(@FBuffer[P^.fiOffset])^ := StrToInt(Value);
      except
        PByte(@FBuffer[P^.fiOffset])^ := 0;
      end;
    qtWord:
      try
        PWord(@FBuffer[P^.fiOffset])^ := StrToInt(Value);
      except
        PWord(@FBuffer[P^.fiOffset])^ := 0;
      end;
    qtLongint, qtDate, qtTime:
      try
        PLongInt(@FBuffer[P^.fiOffset])^ := StrToInt(Value);
      except
        PLongInt(@FBuffer[P^.fiOffset])^ := 0;
      end;
    qtDouble:
      try
        PDouble(@FBuffer[P^.fiOffset])^ := StrToFloat(Value);
      except
        PDouble(@FBuffer[P^.fiOffset])^ := 0.0;
      end;
    else
      FieldErrorMes(Index, P^.fiDataType, MesTitle);
  end;
end;

procedure ProGetNeedIndexes;
begin
  with QrmBases[qbPro] do                                  //Проводки
  begin  
    prProDate       := GetFieldIndexByName('ProDate');     //"Дата проводки"
    prProCode       := GetFieldIndexByName('ProCode');     //
    prDocDate       := GetFieldIndexByName('DocDate');     //
    prDocCode       := GetFieldIndexByName('DocCode');     //
    prDocNum        := GetFieldIndexByName('DocNum');      //
    prContNum       := GetFieldIndexByName('ContNum');     //
    prOperCode      := GetFieldIndexByName('OperCode');    //
    prUserCode      := GetFieldIndexByName('UserCode');    //
    prDbCurrCode    := GetFieldIndexByName('DbCurrCode');  //
    prDbAcc         := GetFieldIndexByName('DbAcc');       //
    prKrCurrCode    := GetFieldIndexByName('KrCurrCode');  //
    prKrAcc         := GetFieldIndexByName('KrAcc');       //
    prExtAcc        := GetFieldIndexByName('ExtAcc');      //
    prBatNum        := GetFieldIndexByName('BatNum');      //
    prKay           := GetFieldIndexByName('Kay');         //
    prZaklObor      := GetFieldIndexByName('ZaklObor');    //
    prWorkStr       := GetFieldIndexByName('WorkStr');     //
    prDocKind       := GetFieldIndexByName('DocKind');     //
    prOperation     := GetFieldIndexByName('Operation');   //
    prOperation1    := GetFieldIndexByName('Operation1');  //
    prOperNum       := GetFieldIndexByName('OperNum');     //
    prOperNum1      := GetFieldIndexByName('OperNum1');    //
    prCash          := GetFieldIndexByName('Cash');        //
    prSumPro        := GetFieldIndexByName('SumPro');      //
    prSumValPro     := GetFieldIndexByName('SumValPro');   //
    prStorno        := GetFieldIndexByName('Storno');      //
    prBankCode      := GetFieldIndexByName('BankCode');    //
    prSumKrValPro   := GetFieldIndexByName('SumKrValPro'); //
  end;
end;

procedure DelProGetNeedIndexes;
begin
  with QrmBases[qbDelPro] do
  begin
    dpProDate        := GetFieldIndexByName('ProDate');    //
    dpProCode        := GetFieldIndexByName('ProCode');    //
    dpDocDate        := GetFieldIndexByName('DocDate');    //
    dpDocCode        := GetFieldIndexByName('DocCode');    //
    dpDocNum         := GetFieldIndexByName('DocNum');     //
    dpContNum        := GetFieldIndexByName('ContNum');    //
    dpOperCode       := GetFieldIndexByName('OperCode');   //
    dpUserCode       := GetFieldIndexByName('UserCode');   //
    dpDbCurrCode     := GetFieldIndexByName('DbCurrCode'); //
    dpDbAcc          := GetFieldIndexByName('DbAcc');      //
    dpKrCurrCode     := GetFieldIndexByName('KrCurrCode'); //
    dpKrAcc          := GetFieldIndexByName('KrAcc');      //
    dpCorrAcc        := GetFieldIndexByName('CorrAcc');    //
    dpExtAcc         := GetFieldIndexByName('ExtAcc');     //
    dpBatNum         := GetFieldIndexByName('BatNum');     //
    dpKay            := GetFieldIndexByName('Kay');        //
    dpZaklObor       := GetFieldIndexByName('ZaklObor');   //
    dpWorkStr        := GetFieldIndexByName('WorkStr');    //
    dpDocKind        := GetFieldIndexByName('DocKind');    //
    dpOperation      := GetFieldIndexByName('Operation');  //
    dpOperation1     := GetFieldIndexByName('Operation1'); //
    dpOperNum        := GetFieldIndexByName('OperNum');    //
    dpOperNum1       := GetFieldIndexByName('OperNum1');   //
    dpCash           := GetFieldIndexByName('Cash');       //
    dpSumPro         := GetFieldIndexByName('SumPro');     //
    dpSumValPro      := GetFieldIndexByName('SumValPro');  //
    dpStorno         := GetFieldIndexByName('Storno');     //
    dpBankCode       := GetFieldIndexByName('BankCode');   //
    dpSumKrValPro    := GetFieldIndexByName('SumKrValPro');//
    dpCurrentDate    := GetFieldIndexByName('CurrentDate');//
    dpCurrentTime    := GetFieldIndexByName('CurrentTime');//
    dpDelUser        := GetFieldIndexByName('DelUser');    //
    dpUnloadSeq      := GetFieldIndexByName('UnloadSeq');  //
  end;
end;

procedure VbKartOtGetNeedIndexes;
begin
  with QrmBases[qbVbKartOt] do
  begin
    {vkOldKartNum             := GetFieldIndexByName('OldKartNum');        //
    vkAccNum                 := GetFieldIndexByName('AccNum');             //
    vkCurrCode               := GetFieldIndexByName('CurrCode');           //
    vkCorrAcc                := GetFieldIndexByName('CorrAcc');            //
    vkCurrCodeCorr           := GetFieldIndexByName('CurrCodeCorr');       //
    vkDocNum                 := GetFieldIndexByName('DocNum');             //
    vkDocDate                := GetFieldIndexByName('DocDate');            //
    vkBranch                 := GetFieldIndexByName('Branch');             //
    vkSenderCorrCode         := GetFieldIndexByName('SenderCorrCode');     //
    vkSenderBankNum          := GetFieldIndexByName('SenderBankNum');      //
    vkSenderMfo              := GetFieldIndexByName('SenderMfo');          //
    vkSenderUchCode          := GetFieldIndexByName('SenderUchCode');      //
    vkOldSenderCorrAcc       := GetFieldIndexByName('OldSenderCorrAcc');   //
    vkReceiverCorrCode       := GetFieldIndexByName('ReceiverCorrCode');   //
    vkReceiverBankNum        := GetFieldIndexByName('ReceiverBankNum');    //
    vkReceiverMfo            := GetFieldIndexByName('ReceiverMfo');        //
    vkReceiverUchCode        := GetFieldIndexByName('ReceiverUchCode');    //
    vkOldReceiverCorrAcc     := GetFieldIndexByName('OldReceiverCorrAcc'); //
    vkOldBenefAcc            := GetFieldIndexByName('OldBenefAcc');        //
    vkDocType                := GetFieldIndexByName('DocType');            //
    vkUserCode               := GetFieldIndexByName('UserCode');}          //
    vkOperNum                := GetFieldIndexByName('OperNum');            //
    {vkStatus                 := GetFieldIndexByName('Status');            //
    vkPreStatus              := GetFieldIndexByName('PreStatus');          //
    vkBreak                  := GetFieldIndexByName('Break');              //
    vkPro_Col                := GetFieldIndexByName('Pro_Col');            //
    vkDoc_Col                := GetFieldIndexByName('Doc_Col');}           //
    vkInOperation            := GetFieldIndexByName('InOperation');        //
    vkInOperNum              := GetFieldIndexByName('InOperNum');          //
    {vkPaySum                 := GetFieldIndexByName('PaySum');            //
    vkVpCode                 := GetFieldIndexByName('VpCode');             //
    vkPrNum                  := GetFieldIndexByName('PrNum');              //
    vkRospDate               := GetFieldIndexByName('RospDate');           //
    vkAllSum                 := GetFieldIndexByName('AllSum');             //
    vkBankNumInUse           := GetFieldIndexByName('BankNumInUse');       //
    vkOperCode               := GetFieldIndexByName('OperCode');           //
    vkStatusHlp              := GetFieldIndexByName('StatusHlp');          //
    vkPosDate                := GetFieldIndexByName('PosDate');            //
    vkProcDate               := GetFieldIndexByName('ProcDate');           //
    vkUserControl            := GetFieldIndexByName('UserControl');        //
    vkControlLink            := GetFieldIndexByName('ControlLink');        //
    vkValueDate              := GetFieldIndexByName('ValueDate');          //
    vkPriority               := GetFieldIndexByName('Priority');           //
    vkOldBenefTaxNum         := GetFieldIndexByName('OldBenefTaxNum');     //
    vkRaceNum                := GetFieldIndexByName('RaceNum');            //
    vkOrderNumber            := GetFieldIndexByName('OrderNumber');        //
    vkLinkStatus             := GetFieldIndexByName('LinkStatus');         //
    vkRaceDate               := GetFieldIndexByName('RaceDate');           //
    vkMassDocNum             := GetFieldIndexByName('MassDocNum');         //
    vkOrderType              := GetFieldIndexByName('OrderType');          //
    vkBatchType              := GetFieldIndexByName('BatchType');          //
    vkBatchNum               := GetFieldIndexByName('BatchNum');           //
    vkPayTelegSum            := GetFieldIndexByName('PayTelegSum');        //
    vkBenefName              := GetFieldIndexByName('BenefName');          //
    vkSendType               := GetFieldIndexByName('SendType');           //
    vkAcceptDate             := GetFieldIndexByName('AcceptDate');         //
    vkKay                    := GetFieldIndexByName('Kay');                //
    vkZaklObor               := GetFieldIndexByName('ZaklObor');           //
    vkBenefTaxNum            := GetFieldIndexByName('BenefTaxNum');}       //
    vkKartNum                := GetFieldIndexByName('KartNum');            //
    {vkSenderCorrAcc          := GetFieldIndexByName('SenderCorrAcc');     //
    vkReceiverCorrAcc        := GetFieldIndexByName('ReceiverCorrAcc');    //
    vkBenefAcc               := GetFieldIndexByName('BenefAcc');           //
    vkClVbAcc                := GetFieldIndexByName('ClVbAcc');            //
    vkClKartAcc              := GetFieldIndexByName('ClKartAcc');          //
    vkNoVbUch                := GetFieldIndexByName('NoVbUch');            //
    vkNoPartAccept           := GetFieldIndexByName('NoPartAccept');       //
    vkAkcept                 := GetFieldIndexByName('Akcept');             //
    vkClKartCurrCode         := GetFieldIndexByName('ClKartCurrCode');     //
    vkPayNatSum              := GetFieldIndexByName('PayNatSum');          //
    vkindate                 := GetFieldIndexByName('indate');             //
    vkInsKrtDate             := GetFieldIndexByName('InsKrtDate');         //
    vkReserv                 := GetFieldIndexByName('Reserv');}            //
  end;                                                                     
end;                                                                       

procedure DocsByShGetNeedIndexes;
begin
  with QrmBases[qbDocsBySh] do
  begin
    dsOperation   := GetFieldIndexByName('Operation');                     //
    dsOperNum     := GetFieldIndexByName('OperNum');                       //
    dsTypeCode    := GetFieldIndexByName('TypeCode');                      //
    dsShifrValue  := GetFieldIndexByName('ShifrValue');
  end;
end;

procedure LimGetNeedIndexes;
begin
  with QrmBases[qbLim] do
  begin
    lmProDate       := GetFieldIndexByName('ProDate');       //
    lmAcc           := GetFieldIndexByName('Acc');           //
    lmCurrCode      := GetFieldIndexByName('CurrCode');      //
    lmLim           := GetFieldIndexByName('Lim');           //
    lmLimVal        := GetFieldIndexByName('LimVal');        //
    lmDbTurn        := GetFieldIndexByName('DbTurn');        //
    lmDbTurnVal     := GetFieldIndexByName('DbTurnVal');     //
    lmKrTurn        := GetFieldIndexByName('KrTurn');        //
    lmKrTurnVal     := GetFieldIndexByName('KrTurnVal');     //
    lmLastDate      := GetFieldIndexByName('LastDate');      //
    lmRevCount      := GetFieldIndexByName('RevCount');      //
    lmOperCount     := GetFieldIndexByName('OperCount');     //
  end;                                                       
end;                                                         
                                                             
procedure CashComAGetNeedIndexes;
begin
  with QrmBases[qbCashComA] do
  begin
    ccComment     := GetFieldIndexByName('Comment');         //
  end;
end;

procedure CashsDAGetNeedIndexes;
begin
  with QrmBases[qbCashsDA] do
  begin
    cdProDate   := GetFieldIndexByName('ProDate');           //
    cdProCode   := GetFieldIndexByName('ProCode');           //
//    cdSymbol    := GetFieldIndexByName('Symbol');          //
    cdSymbol    := GetFieldIndexByName('Symbol');            //
    cdSumma     := GetFieldIndexByName('Summa');             //
  end;                                                       
end;                                                         
                                                             
procedure CommentADocGetNeedIndexes;                         
begin                                                        
  with QrmBases[qbCommentADoc] do                            //
  begin                                                      
    {ProDate        : Date      "Дата проводки",             //
    ProCode        : longint   "Код проводки",}              //
    caComment     := GetFieldIndexByName('Comment');         //
    {TypeOper       : str3      "Вид операции",              //
    UserAbbr       : str3      "Код операциониста",          //
    Ref            : Str16     "Референс",                   //
    WorkStr        : Str20     "Резерв"}                     //
  end;
end;

procedure KvitanGetNeedIndexes;
begin
  with QrmBases[qbKvitan] do
  begin
    kvInOperation      := GetFieldIndexByName('InOperation');   //
    kvInOperNum        := GetFieldIndexByName('InOperNum');     //
    kvInStatus         := GetFieldIndexByName('InStatus');      //
    kvOutOperation     := GetFieldIndexByName('OutOperation');  //
    kvOutOperNum       := GetFieldIndexByName('OutOperNum');    //
    kvOutStatus        := GetFieldIndexByName('OutStatus');     //
    kvProcessDate      := GetFieldIndexByName('ProcessDate');   //
    kvProcessSysDate   := GetFieldIndexByName('ProcessSysDate');//
    kvProcessTime      := GetFieldIndexByName('ProcessTime');   //
    kvDoneFlag         := GetFieldIndexByName('DoneFlag');      //
    kvKvitType         := GetFieldIndexByName('KvitType');      //
    kvUserCode         := GetFieldIndexByName('UserCode');      //
    kvArcMask          := GetFieldIndexByName('ArcMask');       //
    kvOutStatusNew     := GetFieldIndexByName('OutStatusNew');  //
    kvOraF_ID_Kvitan   := GetFieldIndexByName('OraF_ID_Kvitan');//  
    kvPrimaryDoc       := GetFieldIndexByName('PrimaryDoc');    //
    kvWorkStr          := GetFieldIndexByName('WorkStr');       //
  end;
end;


procedure ClientsGetNeedIndexes;
begin
  with QrmBases[qbClients] do
  begin
    clClientCode      := GetFieldIndexByName('ClientCode');     //
    clClientName      := GetFieldIndexByName('ClientName');     //
    clByte255a        := GetFieldIndexByName('Byte255a');       //
    clShortName       := GetFieldIndexByName('ShortName');      //
    clAdress          := GetFieldIndexByName('Adress');         //
    clTelephone       := GetFieldIndexByName('Telephone');      //
    clHasModem        := GetFieldIndexByName('HasModem');       //
    clPrizJur         := GetFieldIndexByName('PrizJur');        //
    clPropertyCode    := GetFieldIndexByName('PropertyCode');   //
    clCodeOKPO        := GetFieldIndexByName('CodeOKPO');       //
    clRegisSer        := GetFieldIndexByName('RegisSer');       //
    clRegisNum        := GetFieldIndexByName('RegisNum');       //
    clRegisDate       := GetFieldIndexByName('RegisDate');      //
    clRegisLocation   := GetFieldIndexByName('RegisLocation');  //
    clTaxNum          := GetFieldIndexByName('TaxNum');         //
    clTaxDate         := GetFieldIndexByName('TaxDate');        //
    clTaxNumGNI       := GetFieldIndexByName('TaxNumGNI');      //
    clTaxLocation     := GetFieldIndexByName('TaxLocation');    //
    clPasport         := GetFieldIndexByName('Pasport');        //
    clBankNum         := GetFieldIndexByName('BankNum');        //
    clPayAccOld       := GetFieldIndexByName('PayAccOld');      //
    clClType          := GetFieldIndexByName('ClType');         //
    clRezident        := GetFieldIndexByName('Rezident');       //
    clCoClientClass   := GetFieldIndexByName('CoClientClass');  //
    clCoClientType    := GetFieldIndexByName('CoClientType');   //
    clCuratorCode     := GetFieldIndexByName('CuratorCode');    //
    clF775            := GetFieldIndexByName('F775');           //
    clShifrMask       := GetFieldIndexByName('ShifrMask');      //
    clHasVoice        := GetFieldIndexByName('HasVoice');       //
    clCOPF            := GetFieldIndexByName('COPF');           //
    clCOATO           := GetFieldIndexByName('COATO');          //
    clCountryCode     := GetFieldIndexByName('CountryCode');    //
    clPayAcc          := GetFieldIndexByName('PayAcc');         //
    clClFromOffice    := GetFieldIndexByName('ClFromOffice');   //
    clDocType         := GetFieldIndexByName('DocType');        //
    clSerPasp         := GetFieldIndexByName('SerPasp');        //
    clNumPasp         := GetFieldIndexByName('NumPasp');        //
    clDatePasp        := GetFieldIndexByName('DatePasp');       //
    clReasCode        := GetFieldIndexByName('ReasCode');       //КПП
    clTaxDocType      := GetFieldIndexByName('TaxDocType');     //
    clUserCode        := GetFieldIndexByName('UserCode');       //
    clWorkStr         := GetFieldIndexByName('WorkStr');        //
  end;                                                          //
end;                                                            //
                                                                //
procedure CorRespNewGetNeedIndexes;
begin
  with QrmBases[qbCorRespNew] do
  begin
    {crnAccNum := GetFieldIndexByName('');                                //
    CurrCode       : String[3] "Код валюты",                              //
    BankNum        : String[9] "Код банка корреспондента",                //
    Mfo            : String[9] "Код МФО",                                 //
    UchCode        : String[3] "Код участника прямых расчетов",           //
    BankCorrAccOld : String[10]"Коррсчет банка корреспондента Old",       //
    TypeCorr       : word      "Тип коррсчета",                           //
    AccTheirOld    : String[15]"Номер счета в банке корреспонденте Old",  //
    OpenDate       : Date      "Дата открытия",                           //
    CloseDate      : Date      "Дата закрытия",                           //
    CutOfTime      : Time      "Время приема платежа",                    //
    RCutOff        : Byte      "Поправка на дату для Cutoff",             //
    CorrespName    : string[100]"Наименование банка-корреспондента",      //
    CorrTelegPay   : double    "Сумма телеграфных расходов РКЦ",          //
    CorrStatus     : word      "Признак блокировки",                      //
    ShifrCorr      : string[6] "Шифр",                                    //
    CorrElectronPay: double    "Сумма электронных расходов",              //
    BankCorrAcc    : TExtAcc   "Коррсчет банка корреспондента",}          //
    crnAccTheir := GetFieldIndexByName('AccTheir');                       //
    {CutOffIn       : Word      "Поправка на дату для Cutoff входящих",   //
    RCutOffTel     : Word      "Поправка на дату для Cutoff (тел.)",      //
    CutOffInTel    : Word      "Поправка на дату для Cutoff вх.(тел.)",   //
    RCutOffEl      : Word      "Поправка на дату для Cutoff (эл.)",       //
    CutOffInEl     : Word      "Поправка на дату для Cutoff вх.(эл.)",    //
    WorkStr        : String[10]"Резерв"}                                  //
  end;                                                                    
end;                                                                      
                                                                          
procedure PayOrComGetNeedIndexes;                                         
begin                                                                     
  with QrmBases[qbPayOrCom] do
  begin
    pcOperNum  := GetFieldIndexByName('OperNum');                         //
    pcStatus   := GetFieldIndexByName('Status');                          //
    pcComment  := GetFieldIndexByName('Comment');                         //
    pcComOwner := GetFieldIndexByName('ComOwner');                        //
    {pcComment1 := GetFieldIndexByName('Comment1');}                      //
  end;
end;

procedure CashSymGetNeedIndexes;  
begin
  with QrmBases[qbCashSym] do  
  begin
    csSymbol     := GetFieldIndexByName('Symbol');                        //
    {csName       := GetFieldIndexByName('Name');}                        //
    csFlag       := GetFieldIndexByName('Flag');                          //
    {csCloseDate  := GetFieldIndexByName('CloseDate');                    //
    csWorkStr    := GetFieldIndexByName('WorkStr');}                      //
  end;                                                                    
end;                                                                      
                                                                          
procedure AccountsGetNeedIndexes;                                         
begin                                                                     
  with QrmBases[qbAccounts] do                                            //
  begin                                                                   
    acAccNum          := GetFieldIndexByName('AccNum');                   //
    acAccPlch         := GetFieldIndexByName('AccPlch');                  //
    acAccName         := GetFieldIndexByName('AccName');                  //
    acClientCode      := GetFieldIndexByName('ClientCode');               //
    acAccStatus       := GetFieldIndexByName('AccStatus');                //
    acOpen_Close      := GetFieldIndexByName('Open_Close');               //
    acCurrCode        := GetFieldIndexByName('CurrCode');                 //
    acOpenDate        := GetFieldIndexByName('OpenDate');                 //
    acCloseDate       := GetFieldIndexByName('CloseDate');                //
    acOperNum         := GetFieldIndexByName('OperNum');                  //
    acContNum         := GetFieldIndexByName('ContNum');                  //
    acRightBuffer     := GetFieldIndexByName('RightBuffer');              //
    acChSum           := GetFieldIndexByName('ChSum');                    //
    acClientMessage   := GetFieldIndexByName('ClientMessage');            //
    acValueCode       := GetFieldIndexByName('ValueCode');                //
    acAccEndDate      := GetFieldIndexByName('AccEndDate');               //
    acDayCount        := GetFieldIndexByName('DayCount');                 //
    acAccNewPlch      := GetFieldIndexByName('AccNewPlch');               //
    acNewAccNum       := GetFieldIndexByName('NewAccNum');                //
    acShifrMask       := GetFieldIndexByName('ShifrMask');                //
    acUserGroupCode   := GetFieldIndexByName('UserGroupCode');            //
    acPriority        := GetFieldIndexByName('Priority');                 //
    acDivCode         := GetFieldIndexByName('DivCode');                  //
    acOwerContNum     := GetFieldIndexByName('OwerContNum');              //
    acReAccPr         := GetFieldIndexByName('ReAccPr');                  //
    acReAccount       := GetFieldIndexByName('ReAccount');                //
    acRedCheck        := GetFieldIndexByName('RedCheck');                 //
    acAccSort         := GetFieldIndexByName('AccSort');                  //
    acAccCourse       := GetFieldIndexByName('AccCourse');                //
    acKindCont        := GetFieldIndexByName('KindCont');                 //
    acKindAcc         := GetFieldIndexByName('KindAcc');                  //
    acKindSaldo       := GetFieldIndexByName('KindSaldo');                //
    acOraF_ID_Filial  := GetFieldIndexByName('OraF_ID_Filial');           //
    acWayOfExt        := GetFieldIndexByName('WayOfExt');                 //
    acPerAmount       := GetFieldIndexByName('PerAmount');                //
    acPerType         := GetFieldIndexByName('PerType');                  //
  end;
end;

procedure PayOrderGetNeedIndexes;
begin
  with QrmBases[qbPayOrder] do
  begin
    poPayAcc               := GetFieldIndexByName('PayAcc');              //
    poCurrCodePay          := GetFieldIndexByName('CurrCodePay');         //
    poCorrAcc              := GetFieldIndexByName('CorrAcc');             //
    poCurrCodeCorr         := GetFieldIndexByName('CurrCodeCorr');        //
    poDocNum               := GetFieldIndexByName('DocNum');              //
    poDocDate              := GetFieldIndexByName('DocDate');             //
    poBranch               := GetFieldIndexByName('Branch');              //
    poSenderCorrCode       := GetFieldIndexByName('SenderCorrCode');      //
    poSenderBankNum        := GetFieldIndexByName('SenderBankNum');       //
    poSenderMfo            := GetFieldIndexByName('SenderMfo');           //
    poSenderUchCode        := GetFieldIndexByName('SenderUchCode');       //
    {poOldSenderCorrAcc     := GetFieldIndexByName('OldSenderCorrAcc');}  //
    poReceiverCorrCode     := GetFieldIndexByName('ReceiverCorrCode');    //
    poReceiverBankNum      := GetFieldIndexByName('ReceiverBankNum');     //
    poReceiverMfo          := GetFieldIndexByName('ReceiverMfo');         //
    poReceiverUchCode      := GetFieldIndexByName('ReceiverUchCode');     //
    {poCorrSum              := GetFieldIndexByName('CorrSum');            //
    poEqualSum             := GetFieldIndexByName('EqualSum');            //
    poOldBenefName         := GetFieldIndexByName('OldBenefName');}       //
    poDocType              := GetFieldIndexByName('DocType');             //
    poSendType             := GetFieldIndexByName('SendType');            //
    poUserCode             := GetFieldIndexByName('UserCode');            //
    poBatchType            := GetFieldIndexByName('BatchType');           //
    poBatchNum             := GetFieldIndexByName('BatchNum');            //
    poOperNum              := GetFieldIndexByName('OperNum');             //
    poStatus               := GetFieldIndexByName('Status');              //
    poPreStatus            := GetFieldIndexByName('PreStatus');           //
    {poBreak                := GetFieldIndexByName('Break');}             //
    {poCommPay              := GetFieldIndexByName('CommPay');}           //
    poOrderType            := GetFieldIndexByName('OrderType');           //
    {poPro_Col              := GetFieldIndexByName('Pro_Col');}           //
    {poDoc_Col              := GetFieldIndexByName('Doc_Col');}           //
    {poInOperation          := GetFieldIndexByName('InOperation');}       //
    {poInOperNum            := GetFieldIndexByName('InOperNum');}         //
    poPaySum               := GetFieldIndexByName('PaySum');              //
    poPayTelegSum          := GetFieldIndexByName('PayTelegSum');         //
    {poVpCode               := GetFieldIndexByName('VpCode');}            //
    {poPrNum                := GetFieldIndexByName('PrNum');}             //
    poPosDate              := GetFieldIndexByName('PosDate');             //
    poProcDate             := GetFieldIndexByName('ProcDate');            //
    {poUserControl          := GetFieldIndexByName('UserControl');}       //
    {poControlLink          := GetFieldIndexByName('ControlLink');}       //
    poValueDate            := GetFieldIndexByName('ValueDate');           //
    poPriority             := GetFieldIndexByName('Priority');            //
    {poOldBenefTaxNum       := GetFieldIndexByName('OldBenefTaxNum');}    //
    poRaceNum              := GetFieldIndexByName('RaceNum');             //
    {poOrderNumber          := GetFieldIndexByName('OrderNumber');}       //
    {poLinkStatus           := GetFieldIndexByName('LinkStatus');}        //
    {poRaceDate             := GetFieldIndexByName('RaceDate');}          //
    poStatusHlp            := GetFieldIndexByName('StatusHlp');           //
    poOperCode             := GetFieldIndexByName('OperCode');            //
    poKay                  := GetFieldIndexByName('Kay');                 //
    poZaklObor             := GetFieldIndexByName('ZaklObor');            //
    {poAddInfo              := GetFieldIndexByName('AddInfo');}           //
    poBenefTaxNum          := GetFieldIndexByName('BenefTaxNum');         //
    {poTypeKvit             := GetFieldIndexByName('TypeKvit');}          //
    poBenefAcc             := GetFieldIndexByName('BenefAcc');            //
    {poKanvaNum             := GetFieldIndexByName('KanvaNum');}          //
    poSenderCorrAcc        := GetFieldIndexByName('SenderCorrAcc');       //
    poReceiverCorrAcc      := GetFieldIndexByName('ReceiverCorrAcc');     //
    poBenefName            := GetFieldIndexByName('BenefName');           //
    poINNOur               := GetFieldIndexByName('INNOur');              //
    poClientNameOur        := GetFieldIndexByName('ClientNameOur');       //
    poClientAcc            := GetFieldIndexByName('ClientAcc');           //
    {poIsAviso              := GetFieldIndexByName('IsAviso');}           //
    {poBitMask              := GetFieldIndexByName('BitMask');}           //
    {poPaymentAlg           := GetFieldIndexByName('PaymentAlg');}        //
    {poKvitPossMask         := GetFieldIndexByName('KvitPossMask');}      //
    {poDppDate              := GetFieldIndexByName('DppDate');}           //
    {poRef                  := GetFieldIndexByName('Ref');}               //
    {poVisUserCode          := GetFieldIndexByName('VisUserCode');}       //
    {poMarshrut             := GetFieldIndexByName('Marshrut');}          //
    {poMarshrutDate         := GetFieldIndexByName('MarshrutDate');}      //
    {poReservPay            := GetFieldIndexByName('ReservPay');}         //
    {poAkcept               := GetFieldIndexByName('Akcept');}            //
    {poMenuItem             := GetFieldIndexByName('MenuItem');}          //
    poindate               := GetFieldIndexByName('indate');              //
    poKppOur               := GetFieldIndexByName('KppOur');              //Наш КПП
    poBenefKpp             := GetFieldIndexByName('BenefKpp');            //КПП бенефециара
    {poWorkStr              := GetFieldIndexByName('WorkStr');}           //
  end;
end;

procedure CashOrderGetNeedIndexes;
begin
  with QrmBases[qbCashOrder] do
  begin
    coDocDate        := GetFieldIndexByName('DocDate');                   //
    coDocCode        := GetFieldIndexByName('DocCode');                   //
    coOperCode       := GetFieldIndexByName('OperCode');                  //
    coUserCode       := GetFieldIndexByName('UserCode');                  //
    coDocNum         := GetFieldIndexByName('DocNum');                    //
    coStatus         := GetFieldIndexByName('Status');                    //
    coOperation      := GetFieldIndexByName('Operation');                 //
    coOperNum        := GetFieldIndexByName('OperNum');                   //
    coAccount        := GetFieldIndexByName('Account');                   //
    coCurrCode       := GetFieldIndexByName('CurrCode');                  //
    coCourse         := GetFieldIndexByName('Course');                    //
    coCommission     := GetFieldIndexByName('Commission');                //
    coCommissionPerc := GetFieldIndexByName('CommissionPerc');            //
    coCashAcc        := GetFieldIndexByName('CashAcc');                   //
    coCashCurrCode   := GetFieldIndexByName('CashCurrCode');              //
    coSumma_rec      := GetFieldIndexByName('Summa_rec');                 //
    coSumma_exp      := GetFieldIndexByName('Summa_exp');                 //
    coPrintFlag      := GetFieldIndexByName('PrintFlag');                 //
    coBatNum         := GetFieldIndexByName('BatNum');                    //
    coKay            := GetFieldIndexByName('Kay');                       //
    coContNum        := GetFieldIndexByName('ContNum');                   //
    coPreStatus      := GetFieldIndexByName('PreStatus');                 //
    coStatusHlp      := GetFieldIndexByName('StatusHlp');                 //
    coFastChrg       := GetFieldIndexByName('FastChrg');                  //
    coRemSum         := GetFieldIndexByName('RemSum');                    //
    coDocType        := GetFieldIndexByName('DocType');                   //
    coControlLink    := GetFieldIndexByName('ControlLink');               //
    coFIO            := GetFieldIndexByName('FIO');                       //
    coNumCheck       := GetFieldIndexByName('NumCheck');                  //
    coSerCheck       := GetFieldIndexByName('SerCheck');                  //
    coPasp           := GetFieldIndexByName('Pasp');                      //
    coOldSerPasp     := GetFieldIndexByName('OldSerPasp');                //
    coNumPasp        := GetFieldIndexByName('NumPasp');                   //
    coResident       := GetFieldIndexByName('Resident');                  //
    coNumSpraw       := GetFieldIndexByName('NumSpraw');                  //
    coNotPay         := GetFieldIndexByName('NotPay');                    //
    coMultiPay       := GetFieldIndexByName('MultiPay');                  //
    coConvFlag       := GetFieldIndexByName('ConvFlag');                  //
    coAccSumma       := GetFieldIndexByName('AccSumma');                  //
    coEqvSumma       := GetFieldIndexByName('EqvSumma');                  //
    coSerPasp        := GetFieldIndexByName('SerPasp');                   //
    coNewUserCode    := GetFieldIndexByName('NewUserCode');               //
    coOldNomination  := GetFieldIndexByName('OldNomination');             //
    coKvitPossMask   := GetFieldIndexByName('KvitPossMask');              //
    coRef            := GetFieldIndexByName('Ref');                       //
    coCommissionCurr := GetFieldIndexByName('CommissionCurr');            //
    coDocNumAdd      := GetFieldIndexByName('DocNumAdd');                 //
    coWorkStr        := GetFieldIndexByName('WorkStr');                   //
  end;
end;

procedure CashOSDGetNeedIndexes;
begin
  with QrmBases[qbCashOSD] do
  begin
    osdDocCode          := GetFieldIndexByName('DocCode');                //
    osdSymbol           := GetFieldIndexByName('Symbol');                 //
    osdSumma            := GetFieldIndexByName('Summa');                  //
    osdOldNom           := GetFieldIndexByName('OldNom');                 //
    osdSymbolCorr       := GetFieldIndexByName('SymbolCorr');             //
    osdSummaCorr        := GetFieldIndexByName('SummaCorr');              //
    osdWorkStr          := GetFieldIndexByName('WorkStr');                //
  end;
end;

procedure MemOrderGetNeedIndexes;
begin
  with QrmBases[qbMemOrder] do
  begin
    moDbAcc          := GetFieldIndexByName('DbAcc');                     //
    moDbCurrCode     := GetFieldIndexByName('DbCurrCode');                //
    moKrAcc          := GetFieldIndexByName('KrAcc');                     //
    moKrCurrCode     := GetFieldIndexByName('KrCurrCode');                //
    moDocNum         := GetFieldIndexByName('DocNum');                    //
    moDocDate        := GetFieldIndexByName('DocDate');                   //
    moBranch         := GetFieldIndexByName('Branch');                    //
    moUserCode       := GetFieldIndexByName('UserCode');                  //
    moBatchType      := GetFieldIndexByName('BatchType');                 //
    moBatchNum       := GetFieldIndexByName('BatchNum');                  //
    moOperNum        := GetFieldIndexByName('OperNum');                   //
    moStatus         := GetFieldIndexByName('Status');                    //
    moPreStatus      := GetFieldIndexByName('PreStatus');                 //
    moBreak          := GetFieldIndexByName('Break');                     //
    moMassDocNum     := GetFieldIndexByName('MassDocNum');                //
    moOrderType      := GetFieldIndexByName('OrderType');                 //
    moPro_Col        := GetFieldIndexByName('Pro_Col');                   //
    moDoc_Col        := GetFieldIndexByName('Doc_Col');                   //
    moInOperation    := GetFieldIndexByName('InOperation');               //
    moInOperNum      := GetFieldIndexByName('InOperNum');                 //
    moPaySum         := GetFieldIndexByName('PaySum');                    //
    moVpCode         := GetFieldIndexByName('VpCode');                    //
    moPrNum          := GetFieldIndexByName('PrNum');                     //
    moPosDate        := GetFieldIndexByName('PosDate');                   //
    moProcDate       := GetFieldIndexByName('ProcDate');                  //
    moUserControl    := GetFieldIndexByName('UserControl');               //
    moControlLink    := GetFieldIndexByName('ControlLink');               //
    moStatusHlp      := GetFieldIndexByName('StatusHlp');                 //
    moOperCode       := GetFieldIndexByName('OperCode');                  //
    moKay            := GetFieldIndexByName('Kay');                       //
    moPayKrSum       := GetFieldIndexByName('PayKrSum');                  //
    moPayNatSum      := GetFieldIndexByName('PayNatSum');                 //
    moZaklObor       := GetFieldIndexByName('ZaklObor');                  //
    moWhatConv       := GetFieldIndexByName('WhatConv');                  //
    moAddInfo        := GetFieldIndexByName('AddInfo');                   //
    moTypeKvit       := GetFieldIndexByName('TypeKvit');                  //
    moRaceNum        := GetFieldIndexByName('RaceNum');                   //
    moRaceDate       := GetFieldIndexByName('RaceDate');                  //
    moKvitPossMask   := GetFieldIndexByName('KvitPossMask');              //
    moSumValue       := GetFieldIndexByName('SumValue');                  //
    moStorno         := GetFieldIndexByName('Storno');                    //
    moRef            := GetFieldIndexByName('Ref');                       //
    moReserv         := GetFieldIndexByName('Reserv');                    //
    moDbAcc          := GetFieldIndexByName('DbAcc');                     //
    moDbCurrCode     := GetFieldIndexByName('DbCurrCode');                //
    moKrAcc          := GetFieldIndexByName('KrAcc');                     //
    moKrCurrCode     := GetFieldIndexByName('KrCurrCode');                //
    moDocNum         := GetFieldIndexByName('DocNum');                    //
    moDocDate        := GetFieldIndexByName('DocDate');                   //
    moBranch         := GetFieldIndexByName('Branch');                    //
    moUserCode       := GetFieldIndexByName('UserCode');                  //
    moBatchType      := GetFieldIndexByName('BatchType');                 //
    moBatchNum       := GetFieldIndexByName('BatchNum');                  //
    moOperNum        := GetFieldIndexByName('OperNum');                   //
    moStatus         := GetFieldIndexByName('Status');                    //
    moPreStatus      := GetFieldIndexByName('PreStatus');                 //
    moBreak          := GetFieldIndexByName('Break');                     //
    moMassDocNum     := GetFieldIndexByName('MassDocNum');                //
    moOrderType      := GetFieldIndexByName('OrderType');                 //
    moPro_Col        := GetFieldIndexByName('Pro_Col');                   //
    moDoc_Col        := GetFieldIndexByName('Doc_Col');                   //
    moInOperation    := GetFieldIndexByName('InOperation');               //
    moInOperNum      := GetFieldIndexByName('InOperNum');                 //
    moPaySum         := GetFieldIndexByName('PaySum');                    //
    moVpCode         := GetFieldIndexByName('VpCode');                    //
    moPrNum          := GetFieldIndexByName('PrNum');                     //
    moPosDate        := GetFieldIndexByName('PosDate');                   //
    moProcDate       := GetFieldIndexByName('ProcDate');                  //
    moUserControl    := GetFieldIndexByName('UserControl');               //
    moControlLink    := GetFieldIndexByName('ControlLink');               //
    moStatusHlp      := GetFieldIndexByName('StatusHlp');                 //
    moOperCode       := GetFieldIndexByName('OperCode');                  //
    moKay            := GetFieldIndexByName('Kay');                       //
    moPayKrSum       := GetFieldIndexByName('PayKrSum');                  //
    moPayNatSum      := GetFieldIndexByName('PayNatSum');                 //
    moZaklObor       := GetFieldIndexByName('ZaklObor');                  //
    moWhatConv       := GetFieldIndexByName('WhatConv');                  //
    moAddInfo        := GetFieldIndexByName('AddInfo');                   //
    moTypeKvit       := GetFieldIndexByName('TypeKvit');                  //
    moRaceNum        := GetFieldIndexByName('RaceNum');                   //
    moRaceDate       := GetFieldIndexByName('RaceDate');                  //
    moKvitPossMask   := GetFieldIndexByName('KvitPossMask');              //
    moSumValue       := GetFieldIndexByName('SumValue');                  //
    moStorno         := GetFieldIndexByName('Storno');                    //
    moRef            := GetFieldIndexByName('Ref');                       //
    moReserv         := GetFieldIndexByName('Reserv');                    //
  end;                                                                    
end;                                                                      
                                                                          
procedure BanksGetNeedIndexes;                                            
begin
  with QrmBases[qbBanks] do
  begin                                                                   //
    bnBankNum := GetFieldIndexByName('BankNum');                          //
    bnRkcNum := GetFieldIndexByName('RkcNum');                            //
    bnMfo     := GetFieldIndexByName('Mfo');                              //
    bnUchCode := GetFieldIndexByName('UchCode');                          //
    bnCorrAcc := GetFieldIndexByName('CorrAcc');                          //
    bnBankCorrAcc := GetFieldIndexByName('BankCorrAcc');                  //
    {bnBankTaxNum     : str10     "Инн банка",                              
    bnCorrAccOld     : str10     "Коррсчет банковского учр в РКЦ Old",      
    bnBankType       : word      "Код типа банковского учреждения (table)",}
    bnTypeAbbrev    := GetFieldIndexByName('TypeAbbrev');                   
    bnBankName      := GetFieldIndexByName('BankName');                     
    {bnPostInd                                                              
    bnRegionNum}                                                            
    bnAdress        := GetFieldIndexByName('Adress');                       
    {bnStreet         : str64     "Улица+дом",                              
    bnTelephone      : string[25]"Телефон(ы)",                              
    bnTelegraph      : str14     "Абонентский телеграф(ы)",                 
    bnSrok           : byte      "Срок прохождения документов (дней)",      
    bnElUch          : byte      "Участие в электронных расчетах", // 0 - нет, 1 - да
    bnOkpo           : str8      "Код ОКПО",                                
    bnRegistrNum     : str9      "Регистрационный номер",
    bnLicence        : word      "Лицензия",
    bnMfoCont        : string[20]"Мфо+конт",
    bnNumInUse       : string[20]"Используемый код банка",
    bnWhichBankNum   : word      "Используемый номер банка",
    bn                          //0-Мфо 1-Участник 2-Номер
    bn                          //3-Мфо + конт.
    bnUchFlag        : word      "0-не участник, 1-участник прямых расч",
    bnVkey           : Str8      "Служебная",
    bnBankCorrAcc    : TExtAcc   "Корреспондентский сч.банка",
    bnSks            : string[6] ""}
  end;
end;

procedure VKrtMoveGetNeedIndexes;
begin
  with QrmBases[qbVKrtMove] do
  begin
    vkmOperNum       := GetFieldIndexByName('OperNum');   //Код операции" ,
    vkmAccNum        := GetFieldIndexByName('AccNum');   // Номер счета",
    vkmCurrCode      := GetFieldIndexByName('CurrCode');   // Код валюты",
    vkmUserCode      := GetFieldIndexByName('UserCode');   // Код исполнителя",
    vkmPaySum        := GetFieldIndexByName('PaySum');   // Сумма",
    vkmDateMove      := GetFieldIndexByName('DateMove');   // Дата",
    vkmStatus        := GetFieldIndexByName('Status');   // Статус",
    vkmPreStatus     := GetFieldIndexByName('PreStatus');   // Статусы: 1) Новый  2) Документы отосланы  3) Документы обработаны
    vkmCode          := GetFieldIndexByName('Code');   // Уникальный код операции",
    vkmPayNatSum     := GetFieldIndexByName('PayNatSum');   // Сумма в нац. эквиваленте",
    //vkmReserv        := GetFieldIndexByName('Reserv');
  end;
end;

//Добавлено Меркуловым
//База кодов КБК
procedure DocShfrValuesGetNeedIndexes;
begin
  with QrmBases [qbDocShfrV] do
  begin
    dsvTypeCode      := GetFieldIndexByName('TypeCode');   //Код типа шифра
    dsvShifrValue    := GetFieldIndexByName('ShifrValue'); //Значение шифра
    dsvShifrName     := GetFieldIndexByName('ShifrName');  //Комментарий
  end;
end;

procedure CliKppGetNeedIndexes;
begin
  with QrmBases [qbCliKpp] do
  begin
    ckClientCode     := GetFieldIndexByName('ClientCode');
    ckKPP            := GetFieldIndexByName('KPP');
    ckDefault_       := GetFieldIndexByName('Default_');
  end;
end;

var
  FOpenedBases: Integer = 0;

function QrmBasesIsOpen: Boolean;
begin
  Result := FOpenedBases>=NumOfQrmBases;
end;

procedure GetQrmOpenedBases(var Opened, All: Integer);
begin
  Opened := FOpenedBases;
  All := NumOfQrmBases;
end;

function InitQuorumBase(QuorumDir, DictDir, DataDir: string): Boolean;  { Инициализация основных баз Кворум}
const
  MesTitle: PChar = 'InitQuorumBase';
var
  I: Integer;
  S: string;
begin
  Result := False;
  FOpenedBases := 0;
  SetQuorumDir(QuorumDir);
  SetDictDir(DictDir);
  SetDataDir(DataDir);
  if OpenDictionary then
  begin
    Result := True;
    {ShowProtoMes('Открытие таблиц Кворума...');}
    for I := 1 to NumOfQrmBases do
    begin
      QrmBases[I] := TQuorumBase.Create(Application);
      S := StrPas(QrmBaseNames[I]);
      if QrmBases[I].Init(S) then
      begin
        Inc(FOpenedBases);
        case I of
          qbPayOrder:
            PayOrderGetNeedIndexes;
          qbAccounts:
            AccountsGetNeedIndexes;
          qbBanks:
            BanksGetNeedIndexes;
          qbCorRespNew:
            CorRespNewGetNeedIndexes;
          qbPayOrCom:
            PayOrComGetNeedIndexes;
          qbMemOrder:
            MemOrderGetNeedIndexes;
          qbCashOrder:
            CashOrderGetNeedIndexes;
          qbCashOSD:
            CashOSDGetNeedIndexes;
          qbCashSym:
            CashSymGetNeedIndexes;
          qbPro:
            ProGetNeedIndexes;
          qbClients:
            ClientsGetNeedIndexes;
          qbKvitan:
            KvitanGetNeedIndexes;
          qbCashComA:
            CashComAGetNeedIndexes;
          qbCashsDA:
            CashsDAGetNeedIndexes;
          qbCommentADoc:
            CommentADocGetNeedIndexes;
          qbDelPro:
            DelProGetNeedIndexes;
          qbVbKartOt:
            VbKartOtGetNeedIndexes;
          qbDocsBySh:
            DocsByShGetNeedIndexes;
          qbLim:
            LimGetNeedIndexes;
          qbVKrtMove:
            VKrtMoveGetNeedIndexes;
          qbDocShfrV:                               //Добавлено Меркуловым
            DocShfrValuesGetNeedIndexes;            //Добавлено Меркуловым
          qbCliKpp:                                 //Добавлено Меркуловым
            CliKppGetNeedIndexes;                   //Добавлено Меркуловым
        end;
      end
      else begin
        {ProtoMes(plError, MesTitle, 'Таблица ['+S+'] не открылась');}
        QrmBases[I].Free;
        QrmBases[I] := nil;
      end;
    end;
  end;
end;

procedure DoneQuorumBase;
var
  I: Integer;
begin
  for I := 1 to NumOfQrmBases do
    if QrmBases[I]<>nil then
    begin
     QrmBases[I].Free;
     QrmBases[I] := nil;
    end;
  FOpenedBases := 0;
  CloseDictionary;
end;

//Добавлено Меркуловым
function KbkNotExistInQBase(ClientKBK: ShortString): Boolean;
var
  Len, Res: Integer;
  KbkKey: TKbkKey;
begin
  Res := 0;
  Result := False;
  with KbkKey do
    begin
    dsCode := 4;
    dsShifrV := ClientKBK;
    end;
  if QrmBases[qbDocShfrV]<>nil then
    with QrmBases[qbDocShfrV] do
      begin
      Len := FileRec.frRecordFixed;
      FillChar(Buffer^, Len, #0);
      Res := BtrBase.GetEqual(Buffer^, Len, KbkKey, 0);
      end;
  if Res<>0 then
    Result := True;
end;

//Добавлено Меркуловым
function CompareKpp (ClntRS, ClntKpp: string): Boolean;
var
  Res, Len: Integer;
  AccSortCurrKey: TAccSortCurrKey;
  AccNum: string[10];
  CurrCode: string[3];
  UserCodeLocal, ClCode: Integer;
  CurKpp: string;
  CliKppKey:
    packed record
    ClientCodeKey: Integer;
    KPPKey: string[12];
    end;
begin
  Result := False;
  GetAccAndCurrByNewAcc(ClntRS, AccNum, CurrCode, UserCodeLocal);
  if QrmBases[qbAccounts]<>nil then
    with QrmBases[qbAccounts] do
      begin
      Len := FileRec.frRecordFixed;
      FillChar(AccSortCurrKey, SizeOf(AccSortCurrKey), ' ');
      with AccSortCurrKey do
        begin
        ascAccSort := SortAcc(AccNum);
        ascCurrCode := CurrCode;
        end;
      Res := BtrBase.GetEqual(Buffer^, Len, AccSortCurrKey, 10);
      if Res=0 then
        begin
        ClCode := AsInteger[acClientCode];
        if QrmBases[qbClients]<>nil then
          with QrmBases[qbClients] do
            begin
            Len := FileRec.frRecordFixed;
            FillChar(Buffer^, Len, #0);
            Res := BtrBase.GetEqual(Buffer^, Len, ClCode, 1);
            if Res=0 then
              begin
              CurKpp := AsString[clReasCode];
              if  (CurKpp<>ClntKpp) and (ClntKpp<>'0') then
                if QrmBases[qbCliKpp]<> nil then
                  with QrmBases[qbCliKpp] do
                    begin
                    with CliKppKey do
                      begin
                      ClientCodeKey := ClCode;
                      KPPKey := ClntKpp;
                      end;
                    Res := BtrBase.GetEqualKey(CliKppKey, 1);
                    if Res<>0 then
                      Result := True;
                    end;
              end
            else
              Result := True;
            end;
        end;
      end;
end;


function DocumentIsExistInQuorum(Operation: Word; OperNum: Integer;
  var Status: Word): Integer;
var
  Len1, Res: Integer;
begin
  Status := 0;
  Res := -1;
  case Operation of
    coPayOrderOperation:
      if QrmBases[qbPayOrder]<>nil then
        with QrmBases[qbPayOrder] do
        begin
          Len1 := FileRec.frRecordFixed;
          Res := BtrBase.GetEqual(Buffer^, Len1, OperNum, 0);
          if Res=0 then
          begin
            Status := AsInteger[poStatus];
            if AsString[poDocNum]=DeleteText then
              Res := -4;
          end;
        end;
    coMemOrderOperation:
      if QrmBases[qbMemOrder]<>nil then
        with QrmBases[qbMemOrder] do
        begin
          Len1 := FileRec.frRecordFixed;
          Res := BtrBase.GetEqual(Buffer^, Len1, OperNum, 0);
          if (Res=0) and (AsString[moDocNum]=DeleteText) then
            Res := -4;
        end;
    coCashOrderOperation:
      if QrmBases[qbCashOrder]<>nil then
        with QrmBases[qbCashOrder] do
        begin
          Len1 := FileRec.frRecordFixed;
          Res := BtrBase.GetEqual(Buffer^, Len1, OperNum, 0);
          if (Res=0) and (AsString[coDocNum]=DeleteText) then
            Res := -4;
        end;
    else
      Res := -2;
  end;
  Result := Res;
end;

function SeeNationalCurr: string;
begin
  Result := '000';
end;

function GetAccAndCurrByNewAcc(Acc: ShortString;
  var AccNum, CurrCode: ShortString; var UserCode: Integer): Boolean;
var
  Len, Res: Integer;
  NewAcc: string[22];
begin
  Result := False;
  UserCode := -1;
  AccNum := '';
  CurrCode := '';
  if (Length(Acc)=20) and (QrmBases[qbAccounts]<>nil) then
  begin
    with QrmBases[qbAccounts] do
    begin
      FillChar(NewAcc, SizeOf(NewAcc), #0);
      NewAcc := Acc;
      Len := FileRec.frRecordFixed;
      FillChar(Buffer^, Len, #0);
      Res := BtrBase.GetEqual(Buffer^, Len, NewAcc, 11);
      Result := Res=0;
      while Res=0 do
      begin
        AccNum := AsString[acAccNum];
        CurrCode := AsString[acCurrCode];
        UserCode := AsInteger[acOperNum];
        if AsInteger[acOpen_Close]=0 then
          Res := -1
        else begin
          Len := FileRec.frRecordFixed;
          FillChar(Buffer^, Len, #0);
          Res := BtrBase.GetNext(Buffer^, Len, NewAcc, 11);
          if (Res=0) and (NewAcc<>Acc) then
            Res := -1;
        end;
      end;
    end;
  end;
end;

function SortAcc(AccNum: ShortString): ShortString;
begin
  Result := Copy(AccNum,4,3) + Copy(AccNum,1,3) + Copy(AccNum,7,4);
end;

function GetNewAccByAccAndCurr(AccNum, CurrCode: ShortString;
  var Acc: ShortString): Boolean;
var
  Len, Res: Integer;
  AccSortCurrKey: TAccSortCurrKey;
begin
  Result := False;
  if QrmBases[qbAccounts]<>nil then
    with QrmBases[qbAccounts] do
    begin
      Len := FileRec.frRecordFixed;
      FillChar(AccSortCurrKey, SizeOf(AccSortCurrKey), ' ');
      AccNum := SortAcc(AccNum);
      with AccSortCurrKey do
      begin
        ascAccSort := AccNum;
        ascCurrCode := CurrCode;
      end;
      Res := BtrBase.GetEqual(Buffer^, Len, AccSortCurrKey, 10);
      Result := Res=0;
      if Result then
      begin
        Acc := AsString[acNewAccNum];
        while (Res=0) and (AccSortCurrKey.ascAccSort=AccNum)
          and (AccSortCurrKey.ascCurrCode=CurrCode)
          and (AsInteger[acOpen_Close]<>0) do
        begin
          Acc := AsString[acNewAccNum];
          Len := FileRec.frRecordFixed;
          Res := BtrBase.GetNext(Buffer^, Len, AccSortCurrKey, 10);
        end;
      end;
    end;
end;

function GetClientByAcc(ClientAcc, ClientCurrCode: ShortString;
  var ClientInn, ClientName, ClientNewAcc: ShortString): Boolean;
var
  Len, Res, ClCode: Integer;
  AccSortCurrKey: TAccSortCurrKey;
  Buf: string;
begin
  Result := False;
  if QrmBases[qbAccounts]<>nil then
    with QrmBases[qbAccounts] do
    begin
      Len := FileRec.frRecordFixed;
      FillChar(AccSortCurrKey, SizeOf(AccSortCurrKey), ' ');
      with AccSortCurrKey do
      begin
        ascAccSort := SortAcc(ClientAcc);
        ascCurrCode := ClientCurrCode;
      end;
      Res := BtrBase.GetEqual(Buffer^, Len, AccSortCurrKey, 10);
      Result := Res=0;
      if Result then
      begin
        ClCode := AsInteger[acClientCode];
        ClientName := AsString[acAccName];
        ClientNewAcc := AsString[acNewAccNum];
        //Добавлено Меркуловым
        Buf := ClientName;
        DosToWin(PChar(Buf));
        if (ClientInn = 'incoming') and (ClCode = 1) then
          if MessageBox(ParentWnd, PChar('Заменить '+ Buf + #10#13 + ClientNewAcc + ' на'+
            #10#13 + 'типа наш банк ?'), 'Внимание!!', mb_yesno)=IDYES then
            ClientName := BankNameText;
        ClientInn := '';
        //Конец
        if QrmBases[qbClients]<>nil then
          with QrmBases[qbClients] do
          begin
            Len := FileRec.frRecordFixed;
            Res := BtrBase.GetEqual(Buffer^, Len, ClCode, 1);
            if Res=0 then
              ClientInn := Copy(AsString[clTaxNum], 1, 12)
            else
              ClientInn := '';
          end;
      end;
    end;
end;

function GetLimByAccAndDate(AccNum, CurrCode: ShortString;
  ProDate: Integer; var Sum: Double): Boolean;
var
  LimKey:
    packed record
      lkAcc: string[10];
      lkCurrCode: string[3];
      lkProDate: Integer;
    end;
  Len, Res: Integer;
begin
  Result := False;
  if QrmBases[qbLim]<>nil then
    with QrmBases[qbLim] do
    begin  
      FillChar(LimKey, SizeOf(LimKey), #0);
      with LimKey do  
      begin
        lkAcc := AccNum;
        lkCurrCode := CurrCode;  
        lkProDate := ProDate;  
      end;  
      Len := FileRec.frRecordFixed;
      FillChar(Buffer^, Len, #0);  
      Res := BtrBase.GetLE(Buffer^, Len, LimKey, 0);  
      if (Res=0) and (AsString[lmAcc]=AccNum)
        and (AsString[lmCurrCode]=CurrCode) then  
      begin  
        Sum := AsFloat[lmLim];  
        Result := True;  
      end;  
    end;  
end;  

function GetBankByRekvisit(BankNum: ShortString; Info: Boolean; var CorrCode,
  UchCode, MFO, CorrAcc: ShortString): Boolean;  
var
  Len, Res: Integer;
begin
  Result := False;
  if QrmBases[qbBanks]<>nil then
    with QrmBases[qbBanks] do
    begin
      Len := FileRec.frRecordFixed;
      LPad(BankNum, 9, '0');
      Res := BtrBase.GetEqual(Buffer^, Len, BankNum, 0);
      Result := Res=0;
      if Result then
      begin
        if Info then
        begin
          CorrCode := AsString[bnCorrAcc];
          //Добавлено/изменено Меркуловым
          UchCode := Trim(AsString[bnTypeAbbrev]);
          if (UchCode = 'ђЉ–') then       //Если РКЦ то подставляем в название
            UchCode := UchCode+' '+Trim(AsString[bnBankName])+
            ' '+Trim(AsString[bnAdress])
          else
            UchCode := Trim(AsString[bnBankName])+' '+Trim(AsString[bnAdress]);
          //Конец
        end
        else begin
          CorrCode := AsString[bnRkcNum];
          UchCode := AsString[bnUchCode];
          MFO :=     AsString[bnMFO];
          CorrAcc := AsString[bnCorrAcc];
        end;
      end
      else begin
        CorrCode := '';
        UchCode := '';  
        MFO := '';
        CorrAcc := '';
      end;
    end;
end;

function GetSenderCorrAcc(CurrCode, CorrAcc: ShortString): ShortString;
type  
  TCorRespNewKey = packed record
    ckAccNum: string[10];  
    ckCurrCode: string[3];  
  end;  
var  
  Len, Res: Integer;  
  CorRespNewKey: TCorRespNewKey;  
begin
  if QrmBases[qbCorRespNew]=nil then
    Result := ''
  else
    with QrmBases[qbCorRespNew] do
    begin
      Len := FileRec.frRecordFixed;
      FillChar(Buffer^, Len, #0);
      RPad(CorrAcc, 10, ' ');
      with CorRespNewKey do
      begin
        ckAccNum := CorrAcc;
        ckCurrCode := CurrCode;
      end;
      Res := BtrBase.GetEqual(Buffer^, Len, CorRespNewKey, 0);
      if Res=0 then
        Result := AsString[crnAccTheir]
      else
        Result := '';
    end;
end;

function GetChildOperNumByKvitan(InOperation: Word; InOperNum: Longint;
  NeedOutOperation: Word): Integer;
var
  KvitKey: TKvitKey;
  Len, Res: Integer;
begin
  Result := 0;
  if QrmBases[qbKvitan]<>nil then
  begin
    with KvitKey do
    begin
      kkDoneFlag := 0;
      kkOperation := InOperation;
      kkOperNum := InOperNum;
      kkStatus := 0;
    end;
    with QrmBases[qbKvitan] do
    begin
      Len := FileRec.frRecordFixed;
      Res := BtrBase.GetGE(Buffer^, Len, KvitKey, 0);
      while (Result=0)
        and (Res=0)
        and (AsInteger[kvDoneFlag]=0)    {+}
        and (AsInteger[kvInOperNum]=InOperNum)
        and (AsInteger[kvInOperation]=InOperation) do
      begin
        if {(AsInteger[kvDoneFlag]=0) and ((NeedOutOperation=0)
          or} (AsInteger[kvOutOperation]=NeedOutOperation) {)}
        then
          Result := AsInteger[kvOutOperNum];
        if Result=0 then
        begin
          Len := FileRec.frRecordFixed;
          Res := BtrBase.GetNext(Buffer^, Len, KvitKey, 0);
        end;
      end;
    end;
  end;
end;

function GetParentOperNumByKvitan(OutOperation: Word; OutOperNum: Longint;
  NeedInOperation: Word): Integer;
var
  KvitKey: TKvitKey;
  Len, Res: Integer;
begin
  Result := 0;
  if QrmBases[qbKvitan]<>nil then
  begin
    with KvitKey do  
    begin
      kkDoneFlag := 0;
      kkOperation := OutOperation;
      kkOperNum := OutOperNum;
      kkStatus := 0;
    end;
    with QrmBases[qbKvitan] do
    begin
      Len := FileRec.frRecordFixed;
      Res := BtrBase.GetGE(Buffer^, Len, KvitKey, 1);
      while (Result=0)
        and (Res=0)
        and (AsInteger[kvOutOperNum]=OutOperNum)
        and (AsInteger[kvOutOperation]=OutOperation) do
      begin
        if (AsInteger[kvDoneFlag]=0) and ((NeedInOperation=0)
          or (AsInteger[kvInOperation]=NeedInOperation))
        then
          Result := AsInteger[kvInOperNum];
        if Result=0 then
        begin
          Len := FileRec.frRecordFixed;
          Res := BtrBase.GetNext(Buffer^, Len, KvitKey, 1);
        end;
      end;
    end;
  end;
end;

function GetCashNazn(S: string): string;
var
  I: Integer;
begin
  I := Pos('+', S);
  if I>0 then
    Result := Copy(S, 1, I-1)
  else
    Result := S;
end;


end.
