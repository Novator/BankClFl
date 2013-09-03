unit Orakle;

interface

uses
  Classes, SysUtils, Windows, Forms, Dialogs, Utilits, DBTables, DB;

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
  TOraBase = record
    OrQuery: TQuery;
    OrQuery2: TQuery;
    OrQuery3: TQuery;
    OrDB: TDatabase;
    OrServerName: string;
    OrLogin: string;
    OrPass: string;
    OrScheme: string;
    OrBaseConn: Boolean;
  end;

  {TProKey = packed record
    pkProDate: Integer;
    pkProCode: Longint;
  end;}


const
  coPayOrderOperation     = 1102;
  coMemOrderOperation     = 1103;
  coCashOrderOperation    = 1116;
  coRecognizeSumOperation = 1101;
  coVypOperation          = 1106;
  coVbKartotOperation     = 1113;


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

const
  KvitStatus = 50;

function OrDocumentIsExistInQuorum(Operation: Word; OperNum: Integer;
  var Status: Word): Integer;
function OrKbkNotExistInQBase(ClientKBK: ShortString): Boolean;   //Добавлено Меркуловым
function OrCompareKpp(ClntRS, ClntKpp: string): Boolean;//Добавлено Меркуловым
function OrSeeNationalCurr: string;
function OrGetAccAndCurrByNewAcc(Acc: ShortString;
  var AccNum, CurrCode: ShortString; var UserCode: Integer): Boolean;
function OrGetNewAccByAccAndCurr(AccNum, CurrCode: ShortString;
  var Acc: ShortString): Boolean;
function OrGetClientByAcc(ClientAcc, ClientCurrCode: ShortString;
  var ClientInn, ClientName, ClientNewAcc: ShortString; var OldClientName: string): Boolean;
function OrGetLimByAccAndDate(AccNum, CurrCode: ShortString;
  ProDate: Integer; var Sum: Double): Boolean;
function OrBikExistInQBase(BIK: LongInt): Boolean;
function OrGetBankByRekvisit(BankNum: ShortString; Info: Boolean; var CorrCode,
  UchCode, MFO, CorrAcc: ShortString): Boolean;
function OrGetSenderCorrAcc(CurrCode, CorrAcc: ShortString): ShortString;
function OrGetChildOperNumByKvitan(InOperation: Word; InOperNum: Longint;
  NeedOutOperation: Word): Integer;
function OrGetParentOperNumByKvitan(OutOperation: Word; OutOperNum: Longint;
  NeedInOperation: Word): Integer;
function OrGetCashNazn(S: string): string;
//function OrSortAcc(AccNum: ShortString): ShortString;
function OrGetUserNameByCode(UserCode: Integer): string;

//Oracle
procedure OraInit;
function OBaseOpen: Boolean;
procedure OraDone;
procedure GetOrOpenedBases(var Opened, All: Integer);
function OrBasesIsOpen: Boolean;

var
  OraBase: TOraBase;

implementation

//Oracle

{constructor TOraBase.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
end;

destructor TOraBase.Destroy;
begin
  inherited Destroy;
end;}

function OBaseOpen: Boolean;
const
  MesTitle: PChar = 'Подключение к серверу Oracle';
begin
  Result := False;
  with OraBase do
  begin
    OrDB := TDataBase.Create(nil);
    OrQuery := TQuery.Create(nil);
    OrQuery2 := TQuery.Create(nil);
    OrQuery3 := TQuery.Create(nil);
    OrQuery.DatabaseName := 'x';
    OrQuery2.DatabaseName := 'x';
    OrQuery3.DatabaseName := 'x';
    with OrDB do
      begin
      Connected := False;
      DataBaseName := 'x';
      DriverName := 'ORACLE';
      LoginPrompt := False;
      end;
    with OrDB.Params do
    begin
      if IndexOFName('SERVER NAME') <> -1 then
        Delete(IndexOfName('SERVER NAME'));
      if IndexOFName('USER NAME') <> -1 then
        Delete(IndexOfName('USER NAME'));
      if IndexOFName('PASSWORD') <> -1 then
        Delete(IndexOfName('PASSWORD'));
      Add('SERVER NAME='+OrServerName);
      Add('USER NAME='+OrLogin);
      Add('PASSWORD='+OrPass);
    end;
    //OrQuery.Params.CreateParam(ftString, 'OraInsString', ptInputOutput);
    OrDB.Open;
    if OrDB.Connected then
      Result := True;
    if not Result then
    begin
      OraDone;
      ProtoMes(plError, MesTitle, 'Не удалось удалось открыть базу данных Oracle.');
    end;
  end;
end;

var
  OrOpenedBases: Integer = 0;

procedure GetOrOpenedBases(var Opened, All: Integer);
begin
  Opened := OrOpenedBases;
  All := NumOfQrmBases;
end;

function OrBasesIsOpen: Boolean;
begin
  Result := OrOpenedBases>=NumOfQrmBases;
end;

procedure OraInit;
const
  MesTitle: PChar = 'Инициализация o-записи';
begin
  if OraBase.OrDB.Connected then
    OrOpenedBases := NumOfQrmBases;
end;

procedure OraDone;
begin
  with OraBase do
  begin
    OrQuery.Close;
    OrQuery2.Close;
    OrQuery3.Close;
    OrDB.Connected := False;
    OrDB.Destroy;
    OrQuery.Destroy;
    OrQuery2.Destroy;
    OrQuery3.Destroy;
  end;
end;

//Добавлено Меркуловым
function OrKbkNotExistInQBase(ClientKBK: ShortString): Boolean;
const
  MesTitle: Pchar='Проверка КБК';
{var
  Len, Res: Integer;
  KbkKey: TKbkKey;}
begin
  {Res := 0;}
  Result := True;
  {with KbkKey do
    begin
    dsCode := 4;
    dsShifrV := ClientKBK;
    end;}
  if OraBase.OrDb.Connected then
    {with QrmBases[qbDocShfrV] do
      begin
      Len := FileRec.frRecordFixed;
      FillChar(Buffer^, Len, #0);
      Res := BtrBase.GetEqual(Buffer^, Len, KbkKey, 0);
      end;}
    with OraBase, OrQuery3 do
    begin
      SQL.Clear;
      SQL.Add('Select /*+ index_asc(DocShfrValues i_ShifrValue) */ count(*) from '+OrScheme+'.DocShfrValues where');
      SQL.Add('TypeCode=4 and ShifrValue='''+ClientKBK+'''');
      //try
      Open;
      //DisplayStatus('');
      {except
        on E:Exception do
          ProtoMes(plError, MesTitle, E.Message);
      end;}
      if Fields[0].AsInteger>0 then
        Result := False;
    end;
end;

//Добавлено Меркуловым
function OrCompareKpp (ClntRS, ClntKpp: string): Boolean;
var
  {Res, Len: Integer;
  AccSortCurrKey: TAccSortCurrKey;}
  AccNum: string[10];
  //AccSort: string[12];
  CurrCode: string[3];
  UserCodeLocal, ClCode: Integer;
  CurKpp: string;
begin
  Result := True;
  OrGetAccAndCurrByNewAcc(ClntRS, AccNum, CurrCode, UserCodeLocal);
  if OraBase.OrDb.Connected then
    with OraBase, OrQuery3 do
    begin
      SQL.Clear;
      SQL.Add('Select /*+ index_asc(ACCOUNTS IACC_AccCurr) */ * from '+OrScheme+'.Accounts where AccNum='''+AccNum+''' and CurrCode='''+CurrCode+'''');
      Open;
      if Length(Fields[0].AsString)>0 then
      begin
        ClCode := FieldByName('ClientCode').AsInteger;
        if OrDb.Connected then
        begin
          SQL.Clear;
          SQL.Add('Select /*+ index_asc(Clients Icl1) */ * from '+OrScheme+'.Clients where ClientCode='+IntToStr(ClCode));
          Open;
          if Length(Fields[0].AsString)>0 then
          begin
            CurKpp := FieldByName('ReasCode').AsString;
            if  (CurKpp<>ClntKpp) and (ClntKpp<>'0') then
            begin
              if OrDb.Connected then
              begin
                SQL.Clear;
                SQL.Add('Select /*+ index_asc(CliKpp iCliKPP1) */ count(*) from '+OrScheme+'.CliKpp where ');
                SQL.Add('ClientCode='+IntToStr(ClCode)+' and KPP='''+ClntKpp+'''');
                Open;
                if Fields[0].AsInteger>0 then
                  Result := False;
              end;
            end
            else
              Result := False;
          end;
        end;
      end;
      Close;
    end;
end;


function OrDocumentIsExistInQuorum(Operation: Word; OperNum: Integer;
  var Status: Word): Integer;
var
  {Len1,} Res: Integer;
begin
  Status := 0;
  Res := -1;
  case Operation of
    coPayOrderOperation:
      if OraBase.OrDb.Connected then
        with OraBase, OrQuery3 do
        begin
          SQL.Clear;
          SQL.Add('Select /*+ index_asc(PayOrder PaO1) */ Status, DocNum from '+OrScheme+'.PayOrder where');
          SQL.Add(' OperNum='+IntToStr(OperNum));
          Open;
          if Length(Fields[0].AsString)>0 then
          begin  
            Status := Fields[0].AsInteger;
            Res := 0;  
            if WinToDosS(Fields[1].AsString)=DeleteText then
              Res := -4;
          end
          else
            Res := 4;
        end;
    coMemOrderOperation:
      if OraBase.OrDb.Connected then
        with OraBase, OrQuery3 do
        begin
          SQL.Clear;
          SQL.Add('Select /*+ index_asc(MemOrder MeO1) */ DocNum from '+OrScheme+'.MemOrder where');
          SQL.Add(' OperNum='+IntToStr(OperNum));
          Open;
          if (Length(Fields[0].AsString)>0) then
          begin
            Res := 0;
            if (WinToDosS(Fields[0].AsString)=DeleteText) then
              Res := -4;
          end
          else
            Res := 4;
        end;
    coCashOrderOperation:
      if OraBase.OrDb.Connected then
        with OraBase, OrQuery3 do
        begin
          SQL.Clear;
          SQL.Add('Select /*+ index_asc(CashOrder iCODocOperation) */ DocNum from '+OrScheme+'.CashOrder where');
          SQL.Add(' DocCode='+IntToStr(OperNum));
          Open;
          if (Length(Fields[0].AsString)>0) then
          begin
            Res := 0;
            if (WinToDosS(Fields[0].AsString)=DeleteText) then
              Res := -4;
          end
          else
            Res := 4;
        end;
    else
      Res := -2;
  end;
  Result := Res;
end;

function OrSeeNationalCurr: string;
begin
  Result := '000';
end;

function OrGetAccAndCurrByNewAcc(Acc: ShortString;
  var AccNum, CurrCode: ShortString; var UserCode: Integer): Boolean;
var
  {Len, }Res: Integer;
  NewAcc: string[22];
begin
  Result := False;
  UserCode := -1;
  AccNum := '';
  CurrCode := '';
  if (Length(Acc)=20) and OraBase.OrDB.Connected then
  begin
    with OraBase, OrQuery3 do
    begin
      FillChar(NewAcc, SizeOf(NewAcc), #0);
      NewAcc := Acc;
      SQL.Clear;
      SQL.Add('Select /*+ index_asc(Accounts AccbyNewAccNum) */ AccNum, CurrCode, Opernum, Open_Close from '+OrScheme);
      SQL.Add('.Accounts where NewAccNum='''+NewAcc+'''');
      Open;
      if Length(Fields[0].AsString)>0 then
      begin
        Res := 0;
        Result := True;
        while not eof and (Res=0) do
        begin
          AccNum := Fields[0].AsString;
          CurrCode := Fields[1].AsString;
          UserCode := Fields[2].AsInteger;
          if Fields[3].AsInteger=0 then
            Res := -1
          else begin
            Next;
            if not Eof and (NewAcc<>Acc) then
              Res := -1;
          end;
        end;
      end;
    end;
  end;
end;

function OrBikExistInQBase(BIK: LongInt): Boolean;
const
  MesTitle: Pchar='Проверка банка';
begin
  Result := False;
  if OraBase.OrDb.Connected then
    with OraBase, OrQuery3 do
    begin
      SQL.Clear;
      SQL.Add('Select /*+ index_asc(Banks BankNum) */ count(*) from '+OrScheme+'.Banks where');
      SQL.Add(' BankNum='''+FillZeros(BIK, 9)+''' or BankNum='''+IntToStr(BIK)+'''');
      try
        Open;
        if Fields[0].AsInteger>0 then
          Result := True;
      except
        on E:Exception do
          ProtoMes(plError, MesTitle, E.Message);
      end;
    end;
end;

{function OrSortAcc(AccNum: ShortString): ShortString;
begin
  Result := Copy(AccNum,4,3) + Copy(AccNum,1,3) + Copy(AccNum,7,4);
end;}

function OrGetNewAccByAccAndCurr(AccNum, CurrCode: ShortString;
  var Acc: ShortString): Boolean;
begin
  Result := False;
  if OraBase.OrDb.Connected then
    with OraBase, OrQuery3 do
    begin
      SQL.Clear;
      SQL.Add('Select /*+ index_asc(ACCOUNTS IACC_AccCurr) */ NewAccNum, Open_Close from '+OrScheme+'.Accounts where AccNum='''+AccNum+''' and CurrCode='''+CurrCode+'''');
      Open;
      Result := Length(Fields[0].AsString)>0;
      if Result then
      begin
        Acc := Fields[0].AsString;
        while not Eof and (Fields[1].AsInteger<>0) do
        begin
          Acc := Fields[0].AsString;
          Next;
        end;
      end;
      Close;
    end;
end;

function OrGetClientByAcc(ClientAcc, ClientCurrCode: ShortString;
  var ClientInn, ClientName, ClientNewAcc: ShortString; var OldClientName: string): Boolean;
const
  MesTitle: PChar = 'OrGetClientByAcc';
var
  ClCode: Integer;
  //Buf: string;
begin
  Result := False;
  OldClientName := '';
  if OraBase.OrDb.Connected then
    with OraBase, OrQuery3 do
    begin
      SQL.Clear;
      SQL.Add('Select /*+ index_asc(ACCOUNTS IACC_AccCurr) */ ClientCode, AccName, NewAccNum from '+OrScheme+'.Accounts where AccNum='''+ClientAcc+''' and CurrCode='''+ClientCurrCode+'''');
      Open;
      Result := Length(Fields[0].AsString)>0;
      if Result then
      begin
        ClCode := Fields[0].AsInteger;
        ClientName := WinToDosS(Fields[1].AsString);
        ClientNewAcc := Fields[2].AsString;
        //Добавлено Меркуловым
        if (ClientInn = 'incoming') and (ClCode = 1) then
        begin
          (*if (Length(ClientNewAcc)>0) and (ClientNewAcc[1]='6') then
          begin*)
            OldClientName := ClientName;
            DosToWinS(OldClientName);
            {if MessageBox(ParentWnd, PChar('Заменить '+ OldClientName + #10#13 + ClientNewAcc + ' на'+
              #10#13 + 'типа наш банк ?'), 'Внимание!!', mb_yesno)=IDYES then}
            ClientName := BankNameText;
            //ProtoMes(plInfo, MesTitle, 'Не удалось удалось открыть базу данных Oracle.');
          (*end
          else begin
            ProtoMes(plInfo, MesTitle, 'Замена имени клиента пропущена ['+ClientName+']');
          end;*)
        end;
        ClientInn := '';
        //Конец
        if OrDb.Connected then
        begin
          SQL.Clear;
          SQL.Add('Select /*+ index_asc(Clients Icl1) */ TaxNum from '+OrScheme+'.Clients where ');
          SQL.Add('ClientCode='+IntToStr(ClCode));
          Open;
          if Length(Fields[0].AsString)>0 then
            ClientInn := Copy(Fields[0].AsString, 1, 12)
          else
            ClientInn := '';
          end;
      end;
      Close;
    end;
end;

function OrGetLimByAccAndDate(AccNum, CurrCode: ShortString;
  ProDate: Integer; var Sum: Double): Boolean;
begin
  Result := False;
  if OraBase.OrDb.Connected then
    with OraBase, OrQuery3 do
    begin
      SQL.Clear;
      SQL.Add('Select /*+ index_desc(LIM Lim) */ ProDate,Lim from '+OrScheme+'.Lim where ');
      SQL.Add('Acc='''+AccNum+''' and CurrCode='''+CurrCode+''' and ');
      SQL.Add('ProDate<=to_date('''+DosDateToStr(ProDate)+''',''dd.mm.yyyy'') order by ProDate desc');
      Open;
      if Length(Fields[0].AsString)>0 then
      begin
        Sum := FieldbyName('Lim').AsFloat;
        Result := True;
      end;
    end;
end;

function OrGetBankByRekvisit(BankNum: ShortString; Info: Boolean; var CorrCode,
  UchCode, MFO, CorrAcc: ShortString): Boolean;
begin
  Result := False;
  if OraBase.OrDb.Connected then
    with OraBase, OrQuery3 do
    begin
      LPad(BankNum, 9, '0');
      SQL.Clear;
      SQL.Add('Select /*+ index_asc(BANKS BankNum) */ * from '+OrScheme+'.Banks where BankNum='''+BankNum+'''');
      Open;
      Result := Length(Fields[0].AsString)>0;
      if Result then
        if Info then
        begin
          CorrCode := FieldByName('CorrAcc').AsString;
          //Добавлено/изменено Меркуловым
          UchCode := Trim(WinToDosS(FieldbyName('TypeAbbrev').AsString));
          if (UchCode = 'ђЉ–') then       //Если РКЦ то подставляем в название
            UchCode := UchCode+' '+Trim(WinToDosS(FieldbyName('BankName').AsString))+
            ' '+Trim(WinToDosS(FieldbyName('Adress').AsString))
          else
            UchCode := Trim(WinToDosS(FieldbyName('BankName').AsString))+' '+
              Trim(WinToDosS(FieldbyName('Adress').AsString));
          //Конец
        end
        else begin
          CorrCode := FieldbyName('RkcNum').AsString;
          UchCode := WinToDosS(FieldbyName('UchCode').AsString);
          MFO :=     WinToDosS(FieldbyName('MFO').AsString);
          CorrAcc := FieldbyName('CorrAcc').AsString;
        end
      else begin
        CorrCode := '';
        UchCode := '';
        MFO := '';
        CorrAcc := '';
      end;
    end;
end;

function OrGetSenderCorrAcc(CurrCode, CorrAcc: ShortString): ShortString;
{type
  TCorRespNewKey = packed record
    ckAccNum: string[10];
    ckCurrCode: string[3];
  end;
var
  Len, Res: Integer;
  CorRespNewKey: TCorRespNewKey;}
begin
  if not OraBase.OrDb.Connected then
    Result := ''
  else
    with OraBase, OrQuery3 do
    begin
      RPad(CorrAcc, 10, ' ');
      SQL.Clear;
      SQL.Add('Select /*+ index_asc(CORRESPNEW CorrbyAcc) */ AccTheir from '+OrScheme+'.CorRespNew where ');
      SQL.Add('AccNum='''+CorrAcc+''' and CurrCode='''+CurrCode+'''');
      Open;
      if Length(Fields[0].AsString)>0 then
        Result := Fields[0].AsString
      else
        Result := '';
    end;
end;

function OrGetChildOperNumByKvitan(InOperation: Word; InOperNum: Longint;
  NeedOutOperation: Word): Integer;
const
  MesTitle: PChar = 'OrGetChildOperNumByKvitan';
begin
  Result := 0;
  if OraBase.OrDb.Connected then
  begin
    with OraBase, OrQuery3 do
    begin
      SQL.Clear;
      SQL.Add('Select /*+ index_asc(KVITAN Kv1) */ InStatus, OutOperation, OutOperNum from '+OrScheme+'.Kvitan where ');
      SQL.Add('DoneFlag=0 and InOperation='+IntToStr(InOperation)+' and ');
      SQL.Add('InOperNum='+IntToStr(InOperNum)+' and InStatus>=0 order by InStatus');
      Open;
      while (Result=0) and not Eof do
      begin
        if (Fields[1].AsInteger=NeedOutOperation) then
        try
          Result := Fields[2].AsInteger;
        except
          Result := -1;
          ProtoMes(plError, MesTitle, 'Искл. InOperation/InOperNum='
            +IntToStr(InOperation)+'/'+IntToStr(InOperNum));
        end;
        if Result=0 then
          Next;
      end;
    end;
  end;
end;

function OrGetParentOperNumByKvitan(OutOperation: Word; OutOperNum: Longint;
  NeedInOperation: Word): Integer;
const
  MesTitle: PChar = 'OrGetParentOperNumByKvitan';
begin
  Result := 0;
  if OraBase.OrDb.Connected then
  begin
    with OraBase, OrQuery3 do
    begin
      SQL.Clear;
      SQL.Add('Select /*+ index_asc(KVITAN Kv2) */ * from '+OrScheme+'.Kvitan where DoneFlag=0 and ');
      SQL.Add('OutOperation='+IntToStr(OutOperation)+' and ');
      SQL.Add('OutOperNum='+IntToStr(OutOperNum)+' and OutStatus>=0');
      Open;
      while (Result=0) and not Eof do
      begin
        if (FieldbyName('DoneFlag').AsInteger=0) and ((NeedInOperation=0)
          or (FieldbyName('InOperation').AsInteger=NeedInOperation)) then
        try
          Result := FieldbyName('InOperNum').AsInteger;
        except
          Result := -1;
          ProtoMes(plError, MesTitle, 'OrGetParentOperNumByKvitan. Искл. OutOperation/OutOperNum='
            +IntToStr(OutOperation)+'/'+IntToStr(OutOperNum));
        end;
        if Result=0 then
          Next;
      end;
    end;
  end;
end;

function OrGetCashNazn(S: string): string;
var
  I: Integer;
begin
  I := Pos('+', S);
  if I>0 then
    Result := Copy(S, 1, I-1)
  else
    Result := S;
end;

function OrGetUserNameByCode(UserCode: Integer): string;
begin
  Result := '';
  if OraBase.OrDb.Connected then
    with OraBase, OrQuery3 do
    begin
      SQL.Clear;
      SQL.Add('Select xu$id,xu$name from '+OrScheme+'.x$users where ');
      SQL.Add('xu$id='+IntToStr(UserCode));
      Open;
      if Length(Fields[0].AsString)>0 then
        Result := Trim(FieldbyName('xu$name').AsString);
    end;
end;

end.
