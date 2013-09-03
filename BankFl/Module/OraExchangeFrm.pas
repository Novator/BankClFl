unit OraExchangeFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Grids, Db, DBTables, DBGrids, ExtCtrls, DBCtrls, Menus,
  StdCtrls, Buttons, ComCtrls, Common, SearchFrm, Basbn, Utilits,
  BtrDS, BankCnBn, Registr, CommCons, Btrieve, Mask,
  ToolEdit, {Sign, }BUtilits, DocFunc, Orakle, Math;

type
  TOraExchangeForm = class(TForm)
    StatusBar: TStatusBar;
    ProtoGroupBox: TGroupBox;
    ProtoMemo: TMemo;
    ProgressBar: TProgressBar;
    SetupPanel: TPanel;
    BtnPanel: TPanel;
    CancelBtn: TBitBtn;
    ProccessBtn: TBitBtn;
    ImportCheckBox: TCheckBox;
    PosDateEdit: TDateEdit;
    DateEdit: TDateEdit;
    ExportCheckBox: TCheckBox;
    StatPanel: TPanel;
    ExportGroupBox: TGroupBox;
    EInbankLabel: TLabel;
    EOutbankLabel: TLabel;
    ECashLabel: TLabel;
    ECashCountLabel: TLabel;
    EInbankCountLabel: TLabel;
    EOutbankCountLabel: TLabel;
    ImportGroupBox: TGroupBox;
    IInbankLabel: TLabel;
    ICashLabel: TLabel;
    ICashCountLabel: TLabel;
    IInbankCountLabel: TLabel;
    IOutbankCountLabel: TLabel;
    IOutbankLabel: TLabel;
    DIOutbankLabel: TLabel;
    DIInbankLabel: TLabel;
    DICashLabel: TLabel;
    DICashCountLabel: TLabel;
    DIInbankCountLabel: TLabel;
    DIOutbankCountLabel: TLabel;
    LookDeletedCheckBox: TCheckBox;
    SelectedCheckBox: TCheckBox;
    LookKartotCheckBox: TCheckBox;
    RedSaldoCountLabel: TLabel;
    RedSaldoLabel: TLabel;
    StoredProc: TStoredProc;
    DoLoadLabel: TLabel;
    WorkTimerLabel: TLabel;
    WorkTimer: TTimer;
    OpenSpeedButton: TSpeedButton;
    ComisCheckBox: TCheckBox;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ProccessBtnClick(Sender: TObject);
    procedure PosDateEditChange(Sender: TObject);
    procedure ExportCheckBoxClick(Sender: TObject);
    procedure ImportCheckBoxClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure EOutbankLabelClick(Sender: TObject);
    procedure DateEditChange(Sender: TObject);
    procedure ExportGroupBoxClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure WorkTimerTimer(Sender: TObject);
    procedure OpenSpeedButtonClick(Sender: TObject);
    procedure ComisCheckBoxClick(Sender: TObject);
  private
    PaydocDBGrid: TDBGrid;
    procedure WMSysCommand(var Message:TMessage); message WM_SYSCOMMAND;
  protected
    procedure SetBtnFocus;
  public
    procedure ShowProtoMes(Level: Byte; C: PChar; S: string);
  end;

const
  OraExchangeForm: TOraExchangeForm = nil;

  ID_MODULINFO = WM_USER+153;

var
  ObjList: TList;
  CurrPosDate: TDate = 0.0;
  CurrDate: TDate = 0.0;
  ComisChecked: Boolean = True;
  ComisType: Byte = 9;
  ComisSum: Comp;
  ComisRAcc, ComisRKs, ComisKpp, ComisRCode, ComisRInn, ComisRClient,
    ComisRBank, ComisPurpose1, ComisPurpose2: string;

//Добавлено Меркуловым
function SqlInsert(Values : array of const; TableName : string;
  ColNames : array of string) : string;
function SqlUpdate(Values : array of const; TableName : string;
  ColNames : array of string; WhereClause : string) : string;
function OrDataInsert(OrInsString: string; KeyName:string;
  var OraKey:Integer): Integer;

implementation

uses CorrOpSumFrm;

{$R *.DFM}

var
  Process: Boolean = False;
  BtrTAExecuted: Boolean = False;

procedure TOraExchangeForm.ShowProtoMes(Level: Byte; C: PChar; S: string);
begin
  ProtoMemo.Lines.Add(S);
  ProtoMes(Level, C, S);
end;

var
  RkcAccNum, SberAccNum, BankBik: array[0..31] of Char;
const
  LookDeletedDays: Integer = 0;
  LookKartot: Boolean = False;
  CleanFieldsEx: Integer = 0;
  CheckCharModeEx: Integer = 0;
  CleanFieldsIm: Integer = 0;
  CheckCharModeIm: Integer = 0;
  FindOper: Boolean = False;
  QrmOperId: Integer = 0;
  CorrBank: Integer = 0;
  MinRkcSum: Double = 0;
  BankBikInt: Integer = 0;
  PayOrInBank: Boolean = True;

procedure TOraExchangeForm.WMSysCommand(var Message:TMessage);
begin
  case Message.wParam of
    ID_MODULINFO:
      MessageBox(Handle,
        'Для синхронизации баз с АБС "Кворум 7.04"'#13#10+
        'Транскапиталбанк. Пермский филиал'#13#10#13#10+
        'Обращение к полям АБС ведется по именам полей.'#13#10+
        'При смене названий используемых полей'#13#10+
        'необходимо обновить модуль'#13#10#13#10
        ,'О модуле', MB_OK + MB_ICONINFORMATION);
  end;
  inherited;
end;

var
  LastCloseDate: Word = 0;
  UpdDate1: Word = 0;
  DefPayVO: Integer = 101;
  BallanseAccMask: string = '';

procedure TOraExchangeForm.FormCreate(Sender: TObject);
const
  Border=2;
  MesTitle: PChar = 'Инициализация формы';
var
  SysMenu: THandle;
  C: TComponent;
  I: Integer;
  UserCodeLocal: Integer;
  AccNum: string[10];
  CurrCode: string[3];
  ClientInn, ClientName, ClientNewAcc: ShortString;
  OldClName: string;
begin
  ObjList.Add(Self);
  with ProgressBar do
  begin
    Parent := StatusBar;
    SetBounds(0, Border, Width, StatusBar.Height - Border);
    StatusBar.Panels[0].Width := Width;
  end;
  LastCloseDate := GetLastClosedDay;
  if not GetRegParamByName('RkcAccNum', GetUserNumber, RkcAccNum) then
    RkcAccNum := '';
  if not GetRegParamByName('SberAccNum', GetUserNumber, SberAccNum) then
    SberAccNum := '';
  if not GetRegParamByName('BankBik', GetUserNumber, BankBik) then
    BankBik := '045744803';
  try
    BankBikInt := StrToInt(BankBik);
  except
    BankBikInt := 45744803;
  end;
  if not GetRegParamByName('LookDelDays', GetUserNumber, LookDeletedDays) then
    LookDeletedDays := 1;
  if not GetRegParamByName('LookKartot', GetUserNumber, LookKartot) then
    LookKartot := True;
  if not GetRegParamByName('CleanFieldsEx', GetUserNumber, CleanFieldsEx) then
    CleanFieldsEx := 0;
  if not GetRegParamByName('CheckCMEx', GetUserNumber, CheckCharModeEx) then
    CheckCharModeEx := 0;
  if not GetRegParamByName('CleanFieldsIm', GetUserNumber, CleanFieldsIm) then
    CleanFieldsIm := 0;
  if not GetRegParamByName('CheckCMIm', GetUserNumber, CheckCharModeIm) then
    CheckCharModeIm := 0;
  if not GetRegParamByName('FindOper', GetUserNumber, FindOper) then
    FindOper := False;
  if not GetRegParamByName('QrmOperId', GetUserNumber, QrmOperId) then
    QrmOperId := 0;
  if not GetRegParamByName('CorrBank', GetUserNumber, CorrBank) then
    CorrBank := 0;
  if not GetRegParamByName('MinRkcSum', GetUserNumber, MinRkcSum) then
    MinRkcSum := 0;
  if not GetRegParamByName('UpdDate1', GetUserNumber, UpdDate1) then
    UpdDate1 := 0;
  if not GetRegParamByName('PayOrInBank', GetUserNumber, PayOrInBank) then
    PayOrInBank := True;
  if not GetRegParamByName('DefPayVO', GetUserNumber, DefPayVO) then
    DefPayVO := 101;
  BallanseAccMask := DecodeMask('$(BalAccMask)', 5, GetUserNumber);

  PosDateEdit.Date := CurrPosDate;
  DateEdit.Date := CurrDate;

  ComisCheckBox.Checked := ComisChecked;

  ComisRCode := BankBik;
  ComisRBank := 'ПЕРМСКИЙ ФИЛИАЛ "ТКБ" (ЗАО) Г ПЕРМЬ';
  ComisRKs := '30101810700000000803';
  ComisKpp := '';
  ComisRInn := '7709129705';
  ComisRClient := ComisRBank;
  ComisPurpose1 := 'Коммисия за расчетное обслуживание по п/поручениям';
  ComisPurpose2 := ', принятым после окончания операционного дня';
  ComisRAcc := '70107810610101720302';
  ComisSum := 10000;
  //WinToDosS(ComisRBank);
  //WinToDosS(ComisRClient);
  //WinToDosS(ComisPurpose);

  // уточнение получателя банковской комиссии про справочникам
  if OrGetAccAndCurrByNewAcc(ComisRAcc, AccNum, CurrCode, UserCodeLocal) then
  begin
    if OrGetClientByAcc(AccNum, CurrCode, ClientInn, ClientName,  ClientNewAcc,
      OldClName) then
    begin
      ComisRInn := ClientInn;
      ComisRClient := ClientName;
      //СomisRAccc := ClientNewAcc;
    end
    else
      ShowProtoMes(plError, MesTitle, 'Получатель комиссии не найден CurrCode/Acc=['
        +AccNum+'/'+CurrCode+']');
  end
  else
    ShowProtoMes(plError, MesTitle, 'Счет получателя комиссии не найден AccNew=['
      +ComisRAcc+']');

  SysMenu := GetSystemMenu(Handle, False);
  InsertMenu(SysMenu, Word(-1), MF_SEPARATOR, 0, '');
  InsertMenu(SysMenu, Word(-1), MF_BYPOSITION, ID_MODULINFO, '&О модуле...');

  PaydocDBGrid := nil;
  I := 0;
  with Application.MainForm do
  begin
    while (I<MDIChildCount) and (MDIChildren[I].Name<>'PaydocsForm') do
      Inc(I);
    if I<MDIChildCount then
    begin
      C := MDIChildren[I].FindComponent('PaydocDBGrid');
      if (C<>nil) and (C is TDBGrid) then
        PaydocDBGrid := C as TDBGrid;
    end;
  end;
  LookDeletedCheckBox.Checked := LookDeletedDays>0;
  LookKartotCheckBox.Checked := LookKartot;
  if PaydocDBGrid<>nil then
  begin
    SelectedCheckBox.Visible := True;
    SelectedCheckBox.Checked := PaydocDBGrid.SelectedRows.Count>1;
  end;
end;

procedure TOraExchangeForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
end;

procedure TOraExchangeForm.FormDestroy(Sender: TObject);
begin
  OraExchangeForm := nil;
  ObjList.Remove(Self);
end;

function BtrDateToQrmStr(BtrDate: Word): string;
var
  S0: string;
begin
  S0 := ShortDateFormat;
  ShortDateFormat := 'ddmmyyyy';
  Result := DateToStr(BtrDateToDate(BtrDate));
  ShortDateFormat := S0;
end;

procedure TOraExchangeForm.ProccessBtnClick(Sender: TObject);
const
  MesTitle: PChar = 'ЭкспИмп';
var
  BillDataSet, PayDataSet, TransDataSet, ExportDataSet,
    ImportDataSet, AccDataSet: TExtBtrDataSet;
  YearP, MonthP, DayP, YearL, MonthL, DayL: Word;
  C1, C2, C3: Integer;

  function IsBankClAcc(AccNum: ShortString; ActualDate, UsedOpts: Word): Integer;
  var
    AccRec: TAccRec;
    Account: array[0..SizeOf(TAccount)] of Char;
    Len, Res: Integer;
  begin
    Result := 0;    {счет не зарегистрирован}
    Len := SizeOf(TAccRec);
    StrPLCopy(Account, AccNum, SizeOf(TAccount));
    Res := AccDataSet.BtrBase.GetEqual(AccRec, Len, Account, 1);
    if Res=0 then
    begin
      if ActualDate=0 then
      begin    {проверка блокировок}
        if AccRec.arOpts and UsedOpts = 0 then
          Result := 1      {без блокировок}
        else
          Result := -1;    {заблокирован}
      end
      else begin  {проверка действия даты}
        if DateIsActive(ActualDate, AccRec.arDateO, AccRec.arDateC) then
          Result := 1     {актуальна}
        else
          Result := -1;   {дата вне действия счета}
      end;
    end;
  end;

  function GetTransAccNum(Bik: Integer; AccHead: string; Sum: Comp): ShortString;
  var
    TransRec: TTransRec;
    Key, Len: Longint;
    Rkc: Boolean;
  begin
    Rkc := True;
    if (CorrBank<>1) and ((AccHead<'401') or ('404'<AccHead)) then
    begin
      if CorrBank=0 then
      begin
        if (MinRkcSum=0) or (Sum>MinRkcSum) then
        begin
          Len := SizeOf(TransRec);
          Key := Bik;
          Bik := TransDataSet.BtrBase.GetEqual(TransRec, Len, Key, 0);
          if (Bik=0) and (TransRec.sbState=0) then
            Rkc := False;
        end;
      end
      else
        Rkc := False;
    end;
    if Rkc then
      Result := RkcAccNum
    else
      Result := SberAccNum;
    RPad(Result, 10, ' ');
  end;

  function TestCashSym(Sym: ShortString): Word;
  begin
    with OraBase, OrQuery3 do
    begin
      SQL.Clear;
      SQL.Add('Select /*+ index_asc(CashSym ISym1) */ Flag from '+OrScheme+'.CashSym where Symbol='''+Sym+'''');
      Open;
      if Length(Fields[0].AsString)>0 then
        Result := Fields[0].AsInteger
      else
        Result := 0;
    end;
  end;

  procedure DisperceSyms(Syms: string; DocCode: Integer;
    var RemSum, FullSum: Double; var B: Integer);
  const
    MesTitle: PChar = 'Расшифровка росписей';
  var
    Res, {Len, }I, K, E, C: Integer;
    S, S2: string;
    S3: string;                                        //Добавлено Меркуловым
    Sum: Double;
  begin
    I := Length(Syms);
    K := 0;
    while (I>0) and (K>=0) do
    begin
      I := Pos(';', Syms);
      if I>0 then
      begin
        S := Copy(Syms, 1, I-1);
        Delete(Syms, 1, I);
      end
      else begin
        S := Syms;
        Syms := ''
      end;
      I := Pos('-', S);
      if I>0 then
      begin
        S2 := Trim(Copy(S, 1, I-1));
        Val(S2, C, E);
        if B=0 then
        begin
          if E=0 then
          begin
            S2 := FillZeros(C, 3);
            E := TestCashSym(S2);
            if E=0 then
            begin
              K := -1;
              ShowProtoMes(plError, MesTitle, 'Код символа ['+S2+'] неизвестен');
            end
            else begin
              if K=0 then
                K := E
              else
                if K<>E then
                begin
                  K := -1;
                  ShowProtoMes(plError, MesTitle, 'Коды символа разного типа в одном кассовом ордере');
                end;
            end;
          end
          else begin
            K := -1;
            ShowProtoMes(plError, MesTitle, 'Неверный код ['+S2+'] росписи ['+S+']');
          end;
        end;
        if K>=0 then
        begin
          S2 := TruncStr(Copy(S, I+1, Length(S)-I));
          Val(S2, Sum, E);
          if E<>0 then
          begin
            ShowProtoMes(plError, MesTitle, 'Неверная сумма ['+S2+'] росписи ['+S+']');
            K := -1;
          end
          else begin
            if B>0 then
            begin
              //Добавлено Меркуловым
              S3 := FillZeros(C, 3);
              Res := OrDataInsert(SqlInsert([DocCode,S3,Sum],'CashOSD',
                ['DocCode','Symbol','Summa']),'',E);
              if Res<>0 then
                ShowProtoMes(plError, MesTitle, 'Не удалось добавить роспись');
              {with QrmBases[qbCashOSD] do
              begin
                Len := FileRec.frRecordFixed;
                FillChar(Buffer^, Len, #0);
                AsInteger[osdDocCode] := DocCode;
                AsString[osdSymbol] := FillZeros(C, 3);
                AsFloat[osdSumma] := Sum;
                E := DocCode;
                Res := BtrBase.Insert (Buffer^, Len, E, 0);
                if Res<>0 then
                  ShowProtoMes(plError, MesTitle, 'Не удалось добавить роспись');
              end;}
            end
            else begin
              RemSum := RemSum - Sum;
              FullSum := FullSum + Sum;
            end;
          end;
        end;
      end
      else
        ShowProtoMes(plError, MesTitle, 'В назначении платежа найдена недопустимая роспись ['
          +S+']');
      I := Length(Syms);
    end;
    if B=0 then
      B := K;
  end;

  //Добавлено Меркуловым
  procedure DispercePas(Pasp: string; {DocCode: Integer;}
    var PasSer, PasNum, PasPlace, FIO: string; var B: Integer);
  const
    MesTitle: PChar = 'Расшифровка паспортных данных';
  var
    Len, I, J: Integer;
  begin
    I := 1;
    PasSer := '';
    PasNum := '';
    PasPlace := '';
    FIO := '';
    Len := Length(Pasp);
    if (I<Len) and (Pasp[1]>='0') and (Pasp[1]<='9') then
    begin
      while (I<Len) and (Pasp[I]>='0') and (Pasp[I]<='9') do
        Inc(I);
      PasSer := Copy(Pasp, 1, I-1);
      Inc(I);
      J := I;
      while (I<Len) and (Pasp[I]>='0') and (Pasp[I]<='9') do
        Inc(I);
      PasNum := Copy(Pasp, J, (I-J) );
      Inc(I);
      PasPlace := Copy(Pasp,I,Len);
      if (Length(PasSer)<>4) then
      begin
        ShowProtoMes(plError, MesTitle, 'Неверная серия ['+PasSer+'] паспорта');
        B := -1;
      end;
      if (Length(PasNum)<>6) then
      begin
        ShowProtoMes(plError, MesTitle, 'Неверный номер ['+PasNum+'] паспорта');
        B := -1;
      end;
      if (Length(PasPlace)<=0) then
      begin
        ShowProtoMes(plError, MesTitle, 'Не указано место и дата выдачи паспорта');
        B := -1;
      end;
      if (Length(PasPlace)>254) then
      begin
        PasPlace := Copy(PasPlace, 1, 254);
        ShowProtoMes(plWarning, MesTitle, 'Место и дата выдачи паспорта ['+
          DosToWinS(PasPlace)+'] срезаны до 254 симв.');
      end;
    end
    else
      if Len>0 then
      begin
        FIO := Copy(Pasp, 1, Len);
        if (Length(FIO)<=0) then
        begin
          ShowProtoMes(plError, MesTitle, 'Не указано ФИО вносителя');
          B := -1;
        end;
      end;
  end;


const
  sdiPSD = 1;
  //Изменено меркуловым
  //sdiKppPlat = 2;
  //sdiKppPol = 3;
  sdiKBK = 4;
  sdiOkato = 5;
  sdiPop = 6;
  sdiPnp = 7;
  sdiPnd = 8;
  sdiPdd = 9;
  sdiTypePlat = 10;
  {sdiDataPos = 11;
  sdiDataKart = 12;
  sdiDataSpis = 13;}

  function AddDocShifr(Operation: Word; OperNum, Index: Integer; Value: string): Boolean;
  var
    Res: Integer;
//    TypeCode: Word;
  begin
    if Length(Value)=0 then
      Result := True
    else begin
      Result := False;
      Res := OrDataInsert(SqlInsert([Index,Operation,OperNum,DosToWinS(Value)],
        'DocsByShifr', ['TypeCode','Operation','OperNum','ShifrValue']), '', Res);
      Result := Res=0;
      {with QrmBases[qbDocsBySh] do
      begin
        Len := FileRec.frRecordFixed;
        FillChar(Buffer^, Len, #0);
        AsInteger[dsOperation] := Operation;
        AsInteger[dsOperNum] := OperNum;
        AsInteger[dsTypeCode] := Index;
        AsString[dsShifrValue] := Value;
        TypeCode := Index;
        Res := BtrBase.Insert(Buffer^, Len, TypeCode, 1);
        Result := Res=0;
      end;}
    end;
  end;

type
  TDocShifrKey0 = packed record
    skOperation: Word;
    skOperNum: Longint;
    skTypeCode: Word;
  end;

  procedure GetDocShifrs(Operation: Word; OperNum: Integer;
    var {DebitKpp, CreditKpp,} Status, Kbk, Okato, OsnPl, Period,   //Изменено Меркуловым
    NDoc, NDocDate, TipPl: string);
  var
    {Len, Res,} I: Integer;
    V: string;
    //Key: TDocShifrKey0;
  begin
    with OraBase, OrQuery3 do
      for I := sdiPSD to sdiTypePlat do
      begin
        SQL.Clear;
        SQL.Add('Select /*+ index_asc(DocsByShifr i_ShifrDoc) */ ShifrValue from '+OrScheme+'.DocsByShifr where ');
        SQL.Add('Operation='+IntToStr(Operation)+' and OperNum='+IntToStr(OperNum));
        SQL.Add(' and TypeCode='+IntToStr(I));
        Open;
        if Length(Fields[0].AsString)>0 then
          V := WinToDosS(Fields[0].AsString)
        else
          V := '';
        V := TruncStr(V);                 //Добавлено Меркуловым
        case I of
          sdiPSD:
            Status := V;
          sdiKBK:
            Kbk := V;
          sdiOkato:
            Okato := V;
          sdiPop:
            OsnPl := V;
          sdiPnp:
            Period := V;
          sdiPnd:
            NDoc := V;
          sdiPdd:
            NDocDate := V;
          sdiTypePlat:
            TipPl := V;
        end;
    end;
  end;

  (*procedure GetPayOrderShifrs(InOperNum: Integer;
    var Nchpl, Shifr, Nplat, OstSum: string);
  var
    Len, Res, Code: Integer;
    Found_vbKartot: Boolean;
  begin
    with QrmBases[qbVKrtMove] do
    begin
      Code := InOperNum;
      Len := FileRec.frRecordFixed;
      Res := BtrBase.GetEqual(Buffer^, Len, Code, 1);
      if Res=0 then
      begin
        Code := AsInteger[vkmOperNum];
        with QrmBases[qbVbKartot] do
        begin
          Len := FileRec.frRecordFixed;
          Res := BtrBase.GetEqual(Buffer^, Len, Code, 0);
          if Res=0 then
          begin
            Found_vbKartot := true;
            Prim_operation := AsInteger[vkInOperation];
            Prim_opernum:=vbKartot.InOpernum;

            if GetInt('Работа в филиале') = 1 then
            begin
              if vbKartot.OperCode=91 or vbKartot.OperCode=92
                SetStr('PO_KARTOT_OPERCODE','01')
              else
                SetStr('PO_KARTOT_OPERCODE',string(vbKartot.OperCode,'77'));
            end;

     // определение нерасписанной суммы

     vkrtMove.OperNum:=vbKartot.OperNum;
     vkrtMove.UserCode:=0;
     vKrtmove.SetTopBound(tivKrtRM1,rgreater+requal);
     vkrtMove.UserCode:=$FFFFFFF;
     vKrtmove.SetBotBound(tivKrtRM1,rless+requal);
     if vKrtmove.GetFirst(tivKrtRM1)=tsOk
     {
      Journal.DoneFlag:=0;
      Journal.OperNum:=P.InOperNum;
      Journal.Operation:=vKrtMoveOperation;
      Journal.OldStatus:=0;
      if Journal.GetEqual(tiJou2)=tsOk
      { // запись в журнале о нашем документе
        ProcessDate    :=Journal.ProcessDate;
        ProcessSysDate :=Journal.ProcessSysDate;
        ProcessTime    :=Journal.ProcessTime;
        Move_summ:=0;
        do
        {  // выбираем росписи строго позже нашей
          if vkrtMove.Code=P.InOperNum continue; // нашу роспись не учитываем
          Journal.DoneFlag:=0;
          Journal.OperNum:=vkrtMove.Code;
          Journal.Operation:=vKrtMoveOperation;
          Journal.OldStatus:=0;
          if Journal.GetEqual(tiJou2)=tsOk
          // Остальные бракуем по времени появления
          if not ((Journal.ProcessDate<ProcessDate) OR
                 ( (Journal.ProcessDate=ProcessDate) AND
                   ( (Journal.ProcessSysDate<ProcessSysDate) OR
                     ( (Journal.ProcessSysDate=ProcessSysDate) AND
                       (Journal.ProcessTime<=ProcessTime)
                     )
                   )
                 )
                 )
             {
              Move_summ:=Move_summ+vKrtmove.PaySum;
             };
        }while vKrtmove.GetNext=tsOk;

        Setfloat('PO_LIMSUM',vbKartot.PaySum + Move_summ);
      }
     };
     vKrtmove.ReSetBotBound(tivKrtRM1);
     vKrtmove.ReSetTopBound(tivKrtRM1);

     // определение номера списания

     Setint('PO_COUNTMOVE',Getcountkrtmove(vkrtMoveTbl,JournalTbl,vbKartot.OperNum,P.InOperNum));

        ?
      end;
    end;
  end;*)

  procedure BtrStartTA;
  var
    Res: Integer;
  begin
    if not BtrTAExecuted then
    begin
      Res := BtrBeginTransaction;
      if Res=0 then
        BtrTAExecuted := True
      else
        ShowProtoMes(plError, MesTitle, 'Не удалось начать транзакцию. BtrErr='
          +IntToStr(Res));
    end
    else
      ShowProtoMes(plError, MesTitle, 'Нельзя начать транзакцию - предыдущая не завершена');
  end;

  procedure BtrCommitTA;
  var
    Res: Integer;
  begin
    if BtrTAExecuted then
    begin
      Res := BtrEndTransaction;
      if Res=0 then
        BtrTAExecuted := False
      else
        ShowProtoMes(plError, MesTitle, 'Не удалось завершить транзакцию. BtrErr='
          +IntToStr(Res));
    end;
  end;

  procedure BtrAbortTA;
  var
    Res: Integer;
  begin
    if BtrTAExecuted then
    begin
      Res := BtrAbortTransaction;
      if Res=0 then
        BtrTAExecuted := False
      else
        ShowProtoMes(plError, MesTitle, 'Не удалось откатить транзакцию. BtrErr='
          +IntToStr(Res));
    end;
  end;

  procedure OraStartTA;
  begin
    if not OraBase.OrDB.InTransaction then
    begin
      OraBase.OrDB.StartTransaction;
      if not OraBase.OrDB.InTransaction then
        ShowProtoMes(plError, MesTitle, 'Не удалось начать транзакцию Oracle');
    end
    else
      ShowProtoMes(plError, MesTitle, 'Нельзя начать транзакцию Oracle - предыдущая не завершена');
  end;

  function OraTAExecuted: Boolean;
  begin
    Result := OraBase.OrDB.InTransaction;
  end;

  procedure OraCommitTA;
  begin
    if OraTAExecuted then
    begin
      OraBase.OrDB.Commit;
      if OraTAExecuted then
        ShowProtoMes(plError, MesTitle, 'Не удалось завершить транзакцию Oracle');
    end;
  end;

  procedure OraAbortTA;
  begin
    if OraTAExecuted then
    begin
      OraBase.OrDB.Rollback;
      if OraTAExecuted then
        ShowProtoMes(plError, MesTitle, 'Не удалось прервать транзакцию Oracle');
    end;
  end;

var
  DocType, DocOcher: Byte;
  OrderOperation: Word;

  Number, DebitRs, DebitKs,
    DebitBik, DebitInn, DebitName, DebitBank, CreditRs, CreditKs, CreditBik,
    CreditInn, CreditName, CreditBank, Purpose, Syms, DebitKpp, CreditKpp,
    Status, Kbk, Okato, OsnPl, Period, NDoc, NDocDate, TipPl, Nchpl, Shifr,
    Nplat, OstSum: string;
  DocDate: Word;
  CurrDosPosDate, DocType2: Integer;            //Изменено Меркуловым

procedure ClearInn(var Inn: string);
var
  I, L: Integer;
begin
  Inn := Trim(Inn);
  L := Length(Inn);
  I := 0;
  while (I<L) and (Inn[I+1] in ['0'..'9']) do
    Inc(I);
  if I<L then
    Inn := Copy(Inn, 1, I);
end;

type
  TPayOrComKey = packed record
    pkOperNum: Longint;
    pkStatus: Word;
  end;
var
  //PayOrComKey: TPayOrComKey;
  BankCorrCode, BankUchCode, BankMFO, BankCorrAcc,
    CBankCorrCode, CBankUchCode, CBankMFO, CBankCorrAcc: ShortString;

  function AddDocInQuorum(var PayRec: TBankPayRec; var BasicUserCode: Integer): Integer;
  var
    Key, Res, Len, E, I, J, C, UserCodeLocal, UserCodeLocal2, DosDocDate: Integer;
    CashType, poBatchType: Integer;                           //Добавлено
    AccNum, AccNum2: string[10];
    CurrCode, CurrCode2: string[3];
    Pasp, PasSer, PasNum, PasPlace, FIO: string;              //Добавлено
    CorrAcc: ShortString;
    FullSum, RemSum, Sum: Double;

    function GetUserCode: Integer;
    begin
      if FindOper or (QrmOperId=0) then
        Result := UserCodeLocal
      else
        Result := QrmOperId;
    end;

    procedure FillBik(var Bik: string);
    var
      L: Integer;
    begin
      L := Length(Bik);
      if L>0 then
        while L<9 do
        begin
          Bik := '0'+Bik;
          Inc(L);
        end;
    end;

  begin
    Result := -1;
    OrderOperation := 0;
    BasicUserCode := 0;
    poBatchType := 0;                                     //Добавлено Меркуловым
    DosDocDate := CurrDosPosDate; {BtrDateToDosDate(PayRec.dbDoc.drDate); }
    FillBik(CreditBik);
    FillBik(DebitBik);
    case DocType of
      01:
        begin
          //Добавлено Меркуловым
          if OrGetAccAndCurrByNewAcc(DebitRs, AccNum, CurrCode, UserCodeLocal) then
          begin
            RPad(AccNum,10,' ');
            Sum := 0.01*PayRec.dbDoc.drSum;
            CorrAcc := GetTransAccNum(StrToInt(CreditBik), Copy(CreditRs,1,3), Sum);
            if not OrGetBankByRekvisit(DebitBik, False, BankCorrCode, BankUchCode,
              BankMFO, BankCorrAcc) then
            begin
              BankCorrCode := '';
              BankUchCode := '';
              BankMFO := '';
              ShowprotoMes(plWarning, MesTitle, 'Не нашли реквизиты банка плат-ка по БИКу '
                +DebitBik+' в плат.пор. '+DocInfo(PayRec));
            end;
            if not OrGetBankByRekvisit(CreditBik, False, CBankCorrCode, CBankUchCode,
              CBankMFO, CBankCorrAcc) then
            begin
              CBankCorrCode := '';
              CBankUchCode := '';
              CBankMFO := '';
              CBankCorrAcc := '';
              ShowprotoMes(plWarning, MesTitle, 'Не нашли реквизиты банка получателя по БИКу '
                +CreditBik+' в плат.пор. '+DocInfo(PayRec));
            end;
            if Copy(DebitBik, 1, 4) <> Copy(CreditBik, 1, 4) then
              poBatchType := 1
            else
              poBatchType :=0;
            ClearInn(CreditInn);
            ClearInn(DebitInn);
            OraStartTA;
            if OraTAExecuted then
            begin
              I := Pos(':', CreditName);
              while I>0 do
              begin
                CreditName[I] := '!';
                ShowProtoMes(plError, MesTitle, 'Заменено двоеточие "+CreditName+" в плат.пор. '
                  +DocInfo(PayRec)+' на воскл. знак "!"');
                I := Pos(':', CreditName);
              end;
              Res := OrDataInsert(SqlInsert([AccNum,CurrCode,CurrCode,Number,CorrAcc,
                DebitBik,BankCorrCode,DosToWinS(BankUchCode),BankMFO,
                OrGetSenderCorrAcc(CurrCode,CorrAcc),CreditBik,CBankCorrCode,
                DosToWinS(CBankUchCode),CBankMFO,CBankCorrAcc,'К',GetUserCode,
                poBatchType,0,Sum,65535,DosDateToOrStr(DosDocDate),
                DosDateToOrStr(CurrDosPosDate),DosDateToOrStr(CurrDosPosDate),
                DosDateToOrStr(CurrDosPosDate),DosDateToOrStr(CurrDosPosDate),
                PayRec.dbDoc.drOcher,DocType,CreditInn,CreditRs,DosToWinS(CreditName),
                DebitInn,DosToWinS(DebitName),DebitKpp,CreditKpp
                ],'PayOrder', ['PayAcc','CurrCodePay','CurrCodeCorr','DocNum','CorrAcc','SenderBankNum',
                'SenderCorrCode','SenderUchCode','SenderMFO','SenderCorrAcc',
                'ReceiverBankNum','ReceiverCorrCode','ReceiverUchCode','ReceiverMFO',
                'ReceiverCorrAcc','DocType','UserCode','BatchType','BatchNum','PaySum',
                'PreStatus','DocDate','PosDate','ProcDate','ValueDate','InDate','Priority',
                'OperCode','BenefTaxNum','BenefAcc','BenefName','InnOur','ClientNameOur',
                'KppOur','BenefKpp']),'OperNum',Key);
              if Res=0 then
              begin
                Result := Key;
                BasicUserCode := GetUserCode;
              end
              else begin
                OraAbortTA;
                ShowProtoMes(plError, MesTitle, 'Не удалось добавить плат.пор. '
                  +DocInfo(PayRec)+' OraErr='+IntToStr(Res));
              end;
            end;
          end
          else
            ShowProtoMes(plWarning, MesTitle, 'Не найден счет плательщика '+DebitRs
              +' плат. пор. '+DocInfo(PayRec));
        end;
      03:
        begin
          FullSum := 0.0;
          E := Length(Purpose);  {отделим росписи по символам от назначения}
          I := 1;
          while (I<=E) and (Purpose[I]<>#13) and (Purpose[I]<>#10) and (Purpose[I]<>'~') do
            Inc(I);
          Inc(I);
          //Добавлено Меркуловым
          J :=I;
          while (J<=E) and (Purpose[J]<>'~') do
            Inc(J);
          Inc(J);
          Syms := Trim(RemoveDoubleSpaces(DelCR(Copy(Purpose, I, J-(I+1){E-I}))));  //изменено
          Pasp := Copy(Purpose, J,E);
          Purpose := Copy(Purpose, 1, I-1);
          I := Length(Syms);
          C := 0;               {уберем начальные нецифровые символы - мусор}
          while (C<I) and not (Syms[C+1] in ['0'..'9']) do
            Inc(C);
          if C>0 then
          begin
            Delete(Syms, 1, C);
            I := Length(Syms);
          end;
          if I>0 then
          begin
            C := 0;
            DisperceSyms(Syms, 0, RemSum, FullSum, C);
            if C>0 then
            begin
              DispercePas(Pasp, PasSer, PasNum, PasPlace, FIO, C);                                  //добавлено
              if C>0 then
              begin
                if OrGetAccAndCurrByNewAcc(DebitRs, AccNum, CurrCode, UserCodeLocal) then
                begin
                  if OrGetAccAndCurrByNewAcc(CreditRs, AccNum2, CurrCode2, UserCodeLocal2) then
                  begin
                    //Добавлено Меркуловым
                    RPad(AccNum, 10, ' ');
                    RPad(AccNum2, 10, ' ');
                    Sum := 0.01*PayRec.dbDoc.drSum;
                    OraStartTA;
                    if OraTAExecuted then
                    begin
                      if C=17 then
                      begin
                        Res := OrDataInsert(SqlInsert([1, 'П'{#$8F}, Sum, CurrCode2, AccNum2,
                          CurrCode, AccNum, DosToWinS(FIO), 0, Number,
                          DosDateToOrStr(DosDocDate), GetUserCode, GetUserCode, 65535,
                          DocType],'CashOrder', ['NotPay','DocType','Summa_rec','CurrCode',
                          'Account','CashCurrCode','CashAcc','FIO','RemSum','DocNum',
                          'DocDate','UserCode','NewUserCode','PreStatus','OperCode']),
                          'DocCode',Key);
                        UserCodeLocal := UserCodeLocal2;
                      end
                      else begin
                        Res := OrDataInsert(SqlInsert([1, 'Р'{#$90}, Sum, CurrCode, AccNum,
                          CurrCode2, AccNum2, DosToWinS(PasSer), DosToWinS(PasNum), 'паспорт',
                          0, Number, DosDateToOrStr(DosDocDate), GetUserCode, GetUserCode,
                          65535, DocType],'CashOrder', ['NotPay','DocType','Summa_exp',
                          'CurrCode','Account','CashCurrCode','CashAcc','SerPasp',
                          'NumPasp','Pasp','RemSum','DocNum','DocDate','UserCode',
                          'NewUserCode','PreStatus','OperCode']),'DocCode',Key);
                        CashType := C;
                      end;
                      if Res=0 then
                      begin
                        DisperceSyms(Syms, Key, RemSum, FullSum, C);
                        if C>=0 then
                        begin
                          Result := Key;
                          BasicUserCode := GetUserCode;
                        end
                        else
                          OraAbortTA;
                      end
                      else begin
                        OraAbortTA;
                        ShowProtoMes(plError, MesTitle, 'Не удалось добавить запись. Ошибка Btrieve N'
                          +IntToStr(Res)+', кас. ор. '+DocInfo(PayRec));
                      end;
                    end;
                  end
                  else
                    ShowProtoMes(plWarning, MesTitle, 'Не найден кредитовый счет '+CreditRs
                      +' в кас. ор. '+DocInfo(PayRec));
                end
                else
                  ShowProtoMes(plWarning, MesTitle, 'Не найден дебетовый счет'+DebitRs
                    +' в кас. ор. '+DocInfo(PayRec));
              end
              else
              ShowProtoMes(plWarning, MesTitle, 'Ошибка в паспортных данных ['+Pasp
                +'] в кас. ор. '+DocInfo(PayRec));
            end
            else
              ShowProtoMes(plWarning, MesTitle, 'Ошибка в росписях по символам ['+Syms
                +'] в кас. ор. '+DocInfo(PayRec));
          end
          else
            ShowProtoMes(plWarning, MesTitle, 'Кас. ор. '+DocInfo(PayRec)
              +' не содержит росписей по символам');
        end;
      09:
        begin
          if OrGetAccAndCurrByNewAcc(DebitRs, AccNum, CurrCode, UserCodeLocal) then
          begin
            if OrGetAccAndCurrByNewAcc(CreditRs, AccNum2, CurrCode2,
              UserCodeLocal2) or (Length(CreditRs)=0) then
            begin
              if Length(CreditRs)=0 then
              begin
                CurrCode2 := CurrCode;
                ShowProtoMes(plWarning, MesTitle, 'Документ '+DocInfo(PayRec)
                  +' выгружается на внутрибанк без счета получателя');
              end;
              RPad(AccNum, 10, ' ');
              RPad(AccNum2, 10, ' ');
              if (FindOper or (QrmOperId=0))
                and (Length(BallanseAccMask)>0)
                and Masked(DebitRs, BallanseAccMask)
                and not Masked(CreditRs, BallanseAccMask) then
              begin
                UserCodeLocal := UserCodeLocal2;
                ShowProtoMes(plInfo, MesTitle, 'Выгрузка '+DocInfo(PayRec)
                  +' на оператора по кредиту');
              end;
              if (PayRec.dbDateR=0) and (PayRec.dbTimeR=0) then
                DocType2 := DocType
              else
                DocType2 := 01;
              OraStartTA;
              if OraTAExecuted then
              begin
                Res := OrDataInsert(SqlInsert([AccNum, CurrCode, AccNum2, CurrCode2,
                  Number, 0.01*PayRec.dbDoc.drSum, 0.01*PayRec.dbDoc.drSum, GetUserCode,
                  65535, DosDateToOrStr(DosDocDate), DosDateToOrStr(CurrDosPosDate),
                  DosDateToOrStr(CurrDosPosDate), DocType2],'MemOrder',['DbAcc',
                  'DbCurrCode','KrAcc','KrCurrCode','DocNum','PaySum','PayNatSum',
                  'UserCode','PreStatus','DocDate','PosDate','ProcDate','OperCode']),
                  'OperNum',Key);
                if Res=0 then
                begin
                  Result := Key;
                  BasicUserCode := GetUserCode;
                end
                else begin
                  OraAbortTA;
                  ShowProtoMes(plError, MesTitle, 'Не удалось добавить мем. ор. '
                    +DocInfo(PayRec)+' OraErr='+IntToStr(Res));
                end;
              end;
            end
            else
              ShowProtoMes(plWarning, MesTitle, 'Не найден счет кредита '+CreditRs
                +' в мем. ор. '+DocInfo(PayRec));
          end
          else
            ShowProtoMes(plWarning, MesTitle, 'Не найден счет дебита '+DebitRs
              +' в мем. ор. '+DocInfo(PayRec));
        end;
      else begin
        ShowProtoMes(plError, MesTitle, 'Неизвестный тип '+IntToStr(DocType)
          +' документа '+DocInfo(PayRec));
        Result := -1;
      end;
    end;
    if (Result>0) and OraTAExecuted then
    begin
      case DocType of
        03:
          begin
            Res := 2;
            OrderOperation := coCashOrderOperation;
          end;
        09:
          begin
            Res := 1;
            OrderOperation := coMemOrderOperation;
          end;
        else
          begin
            Res := 0;
            OrderOperation := coPayOrderOperation;
          end;
      end;
      if (DocType=1) and (PayRec.dbDoc.drType in [101,102,106,116,191,192]) then
      begin
        //if AddDocShifr(OrderOperation, Key, sdiKppPlat, DebitKpp)        //Убрано Меркуловым
        //  and AddDocShifr(OrderOperation, Key, sdiKppPol, CreditKpp) then//Убрано Меркуловым
        //begin                                                            //Убрано Меркуловым
          if (Length(Status)>0) then
          begin
            if not AddDocShifr(OrderOperation, Key, sdiPSD, Status) then
              Result := -2
            else
            if not AddDocShifr(OrderOperation, Key, sdiKBK, Kbk)
             then Result := -3
            else
            if not AddDocShifr(OrderOperation, Key, sdiOkato, Okato) then
              Result := -4
            else
            if not AddDocShifr(OrderOperation, Key, sdiPop, OsnPl) then
              Result := -5
            else
            if not AddDocShifr(OrderOperation, Key, sdiPnp, Period) then
              Result := -6
            else
            if not AddDocShifr(OrderOperation, Key, sdiPnd, NDoc) then
              Result := -7
            else
            if not AddDocShifr(OrderOperation, Key, sdiPdd, NDocDate) then
              Result := -8
            else
            if not AddDocShifr(OrderOperation, Key, sdiTypePlat, TipPl) then
              Result := -9;
          end;
        //end                                                              //Убрано Меркуловым
        //else                                                             //Убрано Меркуловым
        //  Result := -1;                                                  //Убрано Меркуловым
        if Result<0 then
        begin
          OraAbortTA;
          ShowProtoMes(plError, MesTitle, 'Не удалось добавить налоговый код ErrC='
            +IntToStr(Result)+'. документ '+DocInfo(PayRec));
          Result := -1;
        end;
      end;
      if (Result>0) and OraTAExecuted then
      begin
        //Добавлено Меркуловым
        if (CleanFieldsEx=1) or (CleanFieldsEx=3) then
          Purpose := DelCR(Purpose);
        if (CleanFieldsEx=2) or (CleanFieldsEx=3) then
          Purpose := RemoveDoubleSpaces(Purpose);
        Purpose := Trim(Purpose);
        //Замена двойных кавычек одинарными для совместимости
        I := Pos('"', Purpose);
        while I>0 do
        begin
          Purpose[I] := '''';
          I := Pos('"', Purpose);
        end;
        if Length(Purpose)>254 then
        begin
          ShowProtoMes(plWarning, MesTitle, 'Длинна назначения платежа превышает 254 символа. Отсекаем лишнее.'
            +#10#13+'Док-т '+DocInfo(PayRec));
          Purpose:= Copy(Purpose,1,254);
        end;
        Res := OrDataInsert(SqlInsert([Key, Res, DosToWinS(Purpose), OrderOperation],
          'PayOrCom',['OperNum','Status','Comment_','ComOwner']),'',Res);
        if Res<>0 then
        begin
          Result := -1;
          OraAbortTA;
          ShowProtoMes(plError, MesTitle, 'Не удалось добавить "назначение платежа". BtrErr='
            +IntToStr(Res)+', документ '+DocInfo(PayRec));
        end;
      end;
      //Добавлено Меркуловым
      if (Result>0) and OraTAExecuted then
      begin
        if (Res=0) and (DocType=03) and (CashType<>17) then
          Res := OrDataInsert(SqlInsert([Key, 6, DosToWinS(PasPlace), OrderOperation],
            'PayOrCom', ['OperNum','Status','Comment_','ComOwner']),'',Res);
        if Res=0 then
        begin
          OraCommitTA;
          Result := Key;
          case DocType of
            01:
              begin
                Inc(C1);
                EOutbankCountLabel.Caption := IntToStr(C1);
              end;
            03:
              begin
                Inc(C3);
                ECashCountLabel.Caption := IntToStr(C3);
              end;
            09:
              begin
                Inc(C2);
                EInbankCountLabel.Caption := IntToStr(C2);
              end;
          end;
        end
        else begin
          if (DocType=03) and (CashType<>17) then
          begin
            Result := -1;
            OraAbortTA;
            ShowProtoMes(plError, MesTitle, 'Не удалось добавить место и дату выдачи паспорта. BtrErr='
            +IntToStr(Res)+', документ '+DocInfo(PayRec));
          end;
        end;
      end;
    end;
    OraAbortTA;
  end;

var
  PAcc, PKs, PCode, PInn, RAcc, RKs, RCode, RInn, PClient, RClient,
    PBank, RBank: string;
  DocSum: Double;
  //ReceiverNode: Integer;
  //T: array[0..1023] of Char;

(*function SignPaydoc(var PayRec: TBankPayRec): Boolean;
const
  MesTitle: PChar = 'Создание подписи';
begin
  Result := False;
  if MakeSign(PChar(@PayRec.dbDoc),
    PayRec.dbDocLen+SizeOf(TDocRec)-drMaxVar, ReceiverNode, 1)>0
  then
    Result := True
  else
    MessageBox(Application.MainForm.Handle, 'Не удалось сгенерировать подпись',
      MesTitle, MB_ICONERROR + MB_OK);
end; *)

function ImpInfo(ImportRec: TImportRec): string;
begin
  with ImportRec do
  begin
    Result := '<Id='+IntToStr(irIderB)+' OpNum='+IntToStr(irOperNum)
      +' Op='+IntToStr(irOperation)+' ProC='+IntToStr(irProCode)
      +' ProD='+DosDateToStr(irProDate)+'>';
  end;
end;

procedure AddDocInBankCl(var DocNum, CorrRes: Integer; var PayRec: TBankPayRec;
  UserCode: Integer);
const
  MesTitle: PChar = 'Добавление записи';
var
  Len, Err, Key: Integer;
begin
  CorrRes := 0;
  FillChar(PayRec, SizeOf(PayRec), #0);
  with PayRec do
  begin
    dbUserCode := UserCode;
    if DocNum=0 then
      MakeRegNumber(rnPaydoc, DocNum)
    else
      DocNum := Abs(DocNum);
    Key := DocNum;
    dbIdHere := Key;
    dbIdDoc := dbIdHere;
    with dbDoc do
    begin
      drDate := DocDate;
      drSum := DocSum;
      drType := DocType;
      drOcher := DocOcher;
      drIsp := 2;
      if (dbDoc.drType in [1,2,6,16,91,92]) and (DefPayVO>100) then
        dbDoc.drType := dbDoc.drType+DefPayVO-1;
      EncodeDocVar(dbDoc.drType>100, Number, PAcc,
        PKs, PCode, PInn, PClient, PBank, RAcc, RKs, RCode, RInn, RClient,
        RBank, Purpose, DebitKpp, CreditKpp, Status, Kbk, Okato, OsnPl,
        Period, NDoc, NDocDate, TipPl, Nchpl, Shifr, Nplat, OstSum,
        CheckCharModeIm, CleanFieldsIm,
        CorrRes, True, False, nil, nil, dbDoc, Err);
      dbDocVarLen := Err;
    end;
    dbState := dbState or dsExport or dsInputDoc;
  end;
  {Signed := False;
  {if SignNew and TestPaydoc(PayRec, False) then
    Signed := SignPaydoc;}
  Len := SizeOf(PayRec)-drMaxVar+PayRec.dbDocVarLen+SignSize;
  Err := PayDataSet.BtrBase.Insert(PayRec, Len, Key, 0);
  if Err<>0 then
    DocNum := 0;
end;

function GetDocComment(OperNum: Integer; Status: Word): string;
begin
  Result := '';
  try
    with StoredProc do
    begin
      if DatabaseName='' then
      begin
        DatabaseName := OraBase.OrDB.DatabaseName;
        StoredProcName := UpperCase(OraBase.OrScheme+'.cashordmanager.getdoccomment');
      end;
      if ParamCount<3 then
      begin
        Params.Clear;
        Params.CreateParam(ftInteger, 'DOC_ID', ptInput).AsInteger := OperNum;
        Params.CreateParam(ftInteger, 'STAT', ptInput).AsInteger := Status;
        Params.CreateParam(ftString, 'RESULT', ptResult);
      end
      else begin
        Params[0].AsInteger := OperNum;
        Params[1].AsInteger := Status;
      end;
      if not Prepared then
        Prepare;
      ExecProc;
      Result := Params[2].AsString;
    end;
  except
    on E: Exception do ShowProtoMes(plWarning, MesTitle, 'GetDocComment: '+E.Message);
  end;
end;

const
  RetSignDate = -1;  {условная ДОС-дата характеризующая возврат по картотеке}

var
  DocCode, Len, Len1, ProCode, ProDate, ProDate1: Integer;
  Res1, Res, I, C, J, IdH, DocNum, BillNum, OperNum, BasicUserCode: Integer;
  S, Sum: string;
  ExportRec: TExportRec;
  ImportRec: TImportRec;
  {ProKey, ProKey1: TProKey;}
  AsInbank: Boolean;

  //Добавлено Меркуловым
 // CashKey: TCashKey;

  SS1, SS2: ShortString;
  Year, Month, Day, BtrProDate, Operation: Word;
  ExpKey: TExpKey;
  ImpKey: TImpKey;
  OpRec: TOpRec;
  ClientInn, ClientName, ClientNewAcc: ShortString;
  DC, DC1, DC2, DC3, SelCount, LoopCount, CurIndex, CorrRes: Integer;
  //Добавлено Меркуловым
  PasPlc, PasSer, PasNum, FIO, DcType, OldClName: string;

  W: Word;
  DocStatus: Word;
  PayRec, PayRec2: TBankPayRec;
  RedSaldoList: TStringList;
begin
  if Process then
    Process := False
  else begin
    Process := True;
    ProccessBtn.Caption := '&Прервать';
    CancelBtn.Enabled := False;
    try
      BillDataSet := GlobalBase(biBill);
      PayDataSet := GlobalBase(biPay);
      TransDataSet := GlobalBase(biTrans);
      ExportDataSet := GlobalBase(biExport);
      ImportDataSet := GlobalBase(biImport);
      AccDataSet := GlobalBase(biAcc);
    except
      Process := False
    end;
    if Process then
    try
      WorkTimer.Enabled := True;
      RedSaldoList := TStringList.Create;
      Process := OrBasesIsOpen;
      DoLoadLabel.Show;
      if Process then
      begin
// ======================== ЭКСПОРТ =========================================
        if ExportCheckBox.Checked then
        begin
          DecodeDate(CurrPosDate, YearP, MonthP, DayP);
          ShowProtoMes(plInfo, MesTitle, '===Экспорт===');
          if (UpdDate1=0) or (LastCloseDate=0)
            or (LastCloseDate>=UpdDate1) or SelectedCheckBox.Checked then
          begin
            Len := SizeOf(PayRec);
            Res1 := PayDataSet.BtrBase.GetLast(PayRec, Len, IdH, 2);
            if Res1=0 then
            begin
              ProgressBar.Min := 0;
              ProgressBar.Position := ProgressBar.Min;
              ProgressBar.Max := PayRec.dbIdHere;
              Len := SizeOf(PayRec);
              Res1 := PayDataSet.BtrBase.GetFirst(PayRec, Len, IdH, 2);
            end;
            if Res1=0 then
            begin
              CurIndex := 0;
              SelCount := 0;
              if SelectedCheckBox.Checked then
              begin
                PaydocDBGrid.SelectedRows.Refresh;
                SelCount := PaydocDBGrid.SelectedRows.Count;
                LoopCount := SelCount;
                if LoopCount=0 then
                  Inc(LoopCount);
                CurIndex := 0;
                ProgressBar.Max := LoopCount;
                ShowProtoMes(plInfo, MesTitle, 'Выгрузка выделенных: '+IntToStr(LoopCount));
              end
              else begin
                ShowProtoMes(plInfo, MesTitle, 'Просмотр всех "текущих"');
                LoopCount := 0;
                ProgressBar.Min := PayRec.dbIdHere;
              end;
              ProgressBar.Position := ProgressBar.Min;
              C := 0;
              C1 := 0; C2 := 0; C3 := 0;
              EOutbankCountLabel.Caption := '0';
              EInbankCountLabel.Caption := '0';
              ECashCountLabel.Caption := '0';
              CurrDosPosDate := EncodeDosDate(YearP, MonthP, DayP);
              S := 'Позиционирование документов датой '+DosDateToStr(CurrDosPosDate)+' ';
              if FindOper or (QrmOperId=0) then
                S := S + 'по операционистам'
              else
                S := S + 'на операциониста N'+IntToStr(QrmOperId);
              case CorrBank of
                1: S := S + ' через РКЦ';
                2: S := S + ' через Сбербанк';
              end;
              S := S + '...';
              ShowProtoMes(plInfo, MesTitle, S);
              ProgressBar.Show;
              while (Res1=0) and Process and not OraTAExecuted do
              begin
                if LoopCount>0 then
                begin
                  if SelCount>0 then
                    PayDataSet.Bookmark := PaydocDBGrid.SelectedRows.Items[CurIndex];
                  Len := PayDataSet.GetBtrRecord(@PayRec);
                end;
                DocType := PayRec.dbDoc.drType;
                if DocType>100 then
                  DocType := DocType-100;
                if (LoopCount>0) or ((PayRec.dbState and dsExport)=0) then
                begin            { Выделенный или не экспортированный }
                  if (PayRec.dbState and dsSignError)=0 then
                  begin
                    Inc(C);
                    Len1 := SizeOf(ExportRec);
                    IdH := PayRec.dbIdHere;
                    Res := ExportDataSet.BtrBase.GetEqual(ExportRec, Len1, IdH, 0);
                    if Res=0 then
                    begin
                      if Abs(OrDocumentIsExistInQuorum(ExportRec.erOperation,
                        ExportRec.erOperNum, DocStatus))=4 then
                      begin
                        Res := ExportDataSet.BtrBase.Delete(0);
                        if Res=0 then
                        begin
                          ShowProtoMes(plWarning, MesTitle, 'Документ '
                            +DocInfo(PayRec)+' вновь экспортируется');
                          Res := -1;
                        end
                        else begin
                          ShowProtoMes(plError, MesTitle, 'Не удалось удалить запись в базе "экспорт" о документе '
                            +DocInfo(PayRec));
                          Res := 0;
                        end;
                      end
                      else
                        ShowProtoMes(plWarning, MesTitle, 'Документ '+DocInfo(PayRec)
                          +' уже присутствует в Кворуме Op='+IntToStr(ExportRec.erOperation)
                          +' OperNum='+IntToStr(ExportRec.erOperNum))
                    end;
                    if Res<>0 then
                    begin
                      DecodeDocVar(PayRec.dbDoc, PayRec.dbDocVarLen, Number, DebitRs, DebitKs,
                        DebitBik, DebitInn, DebitName, DebitBank, CreditRs,
                        CreditKs, CreditBik, CreditInn, CreditName, CreditBank,
                        Purpose, DebitKpp, CreditKpp, Status, Kbk, Okato, OsnPl, Period, NDoc,
                        NDocDate, TipPl, Nchpl, Shifr, Nplat, OstSum,
                        CheckCharModeEx, CleanFieldsEx, CorrRes, True);
                      if (PayRec.dbIdSender<>0) and (IsBankClAcc(DebitRs, 0, asLockCl)<0) then
                        ShowProtoMes(plInfo, MesTitle, 'Счет '+DebitRs+' в дебите документа '
                          +DocInfo(PayRec)+' заблокирован')
                      else begin
                        if GetDocOp(OpRec, PayRec.dbIdHere, Len1)
                          and (OpRec.brPrizn=brtBill)
                        then
                          ShowProtoMes(plWarning, MesTitle, 'Нельзя выгрузить документ '
                            +DocInfo(PayRec)+' - существует активная проводка')
                        else begin
                          try
                            Len1 := StrToInt(CreditBik);
                          except
                            Len1 := -1;
                          end;
                          AsInbank := False;
                          if PayOrInBank and (DocType=1) and (Len1=BankBikInt)
                            and (PayRec.dbDoc.drOcher=6) then
                          begin
                            DocType := 9;
                            {ShowProtoMes(plInfo, MesTitle, 'Документ с ВО=1 '+DocInfo(PayRec)+' выгружается на внутрибанк')}
                            AsInbank := True;
                          end;
                          DocCode := AddDocInQuorum(PayRec, BasicUserCode);
                          if DocCode>0 then
                          begin  {удалось выгрузить}
                            if CorrRes<>0 then
                            begin
                              Purpose := 'В документе '+DocInfo(PayRec)+' найдены недопустимые символы';
                              if CheckCharModeEx>1 then
                                Purpose := Purpose + '. Все они были исправлены';
                              ShowProtoMes(plInfo, MesTitle, Purpose);
                            end;
                            if OrderOperation>0 then
                            begin
                              with ExportRec do
                              begin
                                erIderB := PayRec.dbIdHere;
                                erOperation := OrderOperation;
                                erOperNum := DocCode;
                              end;
                              Len1 := SizeOf(ExportRec);
                              I := ExportRec.erIderB;
                              Res := ExportDataSet.BtrBase.Insert(ExportRec, Len1,
                                I, 0);
                              if Res<>0 then
                                ShowProtoMes(plError, MesTitle, 'Не удалось зарегистировать "экспорт" документа '
                                  +DocInfo(PayRec));
                            end
                            else
                              ShowProtoMes(plWarning, MesTitle, 'Тип документа не определен. Документ пропущен '
                                  +DocInfo(PayRec));
                            if (PayRec.dbState and dsExport)=0 then
                            begin
                              PayRec.dbState := PayRec.dbState or dsExport;
                              PayRec.dbUserCode := BasicUserCode;
                              if AsInbank then
                                PayRec.dbUserCode := -PayRec.dbUserCode;
                              Res := PayDataSet.BtrBase.Update(PayRec, Len, IdH, 2);
                              if Res<>0 then
                                ShowProtoMes(plError, MesTitle,
                                  'Не удалось установить пометку "экспорт" документа '
                                  +DocInfo(PayRec)+' BtrErr='+IntToStr(Res));
                            end;
                            if ComisChecked and ((PayRec.dbState and dsRsAfter)<>0)
                              and (OrderOperation=coPayOrderOperation) and (Trim(Status)='') then
                            begin
                              Inc(C);
                              CorrRes := 0;
                              FillChar(PayRec2, SizeOf(PayRec2), #0);
                              with PayRec2.dbDoc do
                              begin
                                drDate := CurrDosPosDate;
                                drSum := ComisSum;
                                drType := ComisType;
                                //drOcher := DocOcher;
                                drIsp := 2;

                                //Number := '';
                                Status := ''; Kbk := ''; Okato := ''; OsnPl := ''; Period := '';
                                NDoc := ''; NDocDate := ''; TipPl := ''; Nchpl := ''; Shifr := '';
                                Nplat := ''; OstSum := '';

                                Purpose := ComisPurpose1+' '+DocInfo(PayRec)
                                  +ComisPurpose2+' ['+BtrDateToStr(PayRec.dbDateR)
                                  +' '+BtrTimeToStr(PayRec.dbTimeR)+']';

                                EncodeDocVar(drType>100, Number,
                                  DebitRs, DebitKs, DebitBik, DebitInn, DebitName, DebitBank,
                                  ComisRAcc, ComisRKs, ComisRCode, ComisRInn, ComisRClient,
                                  ComisRBank, Purpose, DebitKpp, ComisKpp, Status, Kbk, Okato, OsnPl,
                                  Period, NDoc, NDocDate, TipPl, Nchpl, Shifr, Nplat, OstSum,
                                  CheckCharModeIm, CleanFieldsIm, CorrRes, False, False, nil, nil, PayRec2.dbDoc, Res);
                                PayRec2.dbDocVarLen := Res;
                              end;
                              DecodeDocVar(PayRec2.dbDoc, PayRec2.dbDocVarLen, Number, DebitRs, DebitKs,
                                DebitBik, DebitInn, DebitName, DebitBank, CreditRs,
                                CreditKs, CreditBik, CreditInn, CreditName, CreditBank,
                                Purpose, DebitKpp, CreditKpp, Status, Kbk, Okato, OsnPl, Period, NDoc,
                                NDocDate, TipPl, Nchpl, Shifr, Nplat, OstSum,
                                CheckCharModeEx, CleanFieldsEx, CorrRes, True);

                              //Number := '<АВТО>';

                              DocType := PayRec2.dbDoc.drType;
                              DocCode := AddDocInQuorum(PayRec2, BasicUserCode);
                              if DocCode>0 then
                                ShowProtoMes(plInfo, MesTitle, 'Создана комиссия документа '
                                  +DocInfo(PayRec)+' в Кворуме')
                              else
                                ShowProtoMes(plError, MesTitle, 'Не удалось выгрузить комиссию документа '
                                  +DocInfo(PayRec));
                            end;
                          end;
                        end;
                      end;
                    end;
                  end
                  else
                    ShowProtoMes(plWarning, MesTitle,
                      'Пометка "ошибка подписи" у документа '+DocInfo(PayRec));
                end;
                if LoopCount>0 then
                begin
                  Inc(CurIndex);
                  ProgressBar.Position := CurIndex;
                  if CurIndex<LoopCount then
                    Res1 := 0
                  else
                    Res1 := 1;
                end
                else begin
                  ProgressBar.Position := PayRec.dbIdHere;
                  Len := SizeOf(PayRec);
                  Res1 := PayDataSet.BtrBase.GetNext(PayRec, Len, IdH, 2);
                end;
                Application.ProcessMessages;
              end;
              if OraTAExecuted then
              begin
                OraAbortTA;
                ShowProtoMes(plWarning, MesTitle, 'Транзакция Oracle не была завершена');
              end;
              ShowProtoMes(plInfo, MesTitle, 'Выгружено документов: '+IntToStr(C1+C2+C3));
              C := C - (C1+C2+C3);
              if C=0 then
                ShowProtoMes(plInfo, MesTitle, 'Экспорт успешно завершен')
              else
                ShowProtoMes(plWarning, MesTitle, 'Экспорт завершен не полностью. Не удалось выгрузить документов: '
                  +IntToStr(C));
              ProgressBar.Hide;
            end
            else
              ShowProtoMes(plInfo, MesTitle, 'Нет документов в списке "текущие"');
          end
          else
            ShowProtoMes(plWarning, MesTitle, 'Последняя дата работы Dos-версии '
              +BtrDateToStr(UpdDate1)+'.'#13#10'Для корректной выгрузки текущих необходимо закрыть старые дни');
        end;
// ======================== ИМПОРТ =========================================
        if ImportCheckBox.Checked then
        begin
          DecodeDate(CurrDate, YearL, MonthL, DayL);
          ProDate := EncodeDosDate(YearL, MonthL, DayL);
          ShowProtoMes(plInfo, MesTitle, '===Импорт===');
// ======================== Удаленные =========================================
          if LookDeletedCheckBox.Checked then  { проверим удаленные }
          begin
            DecodeDate(EncodeDate(YearL, MonthL, DayL) + 1.0,
              Year, Month, Day);
            ProDate1 := EncodeDosDate(Year, Month, Day);
            //Добавлено Меркуловым
            with OraBase, OrQuery do
            begin
              SQL.Clear;
              SQL.Add('Select /*+ index_asc(DelPro DelPro1) */ count(*) from '+OrScheme+'.DelPro where ProDate<');
              SQL.Add('to_date('''+DosDateToStr(ProDate)+''',''dd.mm.yyyy'') ');
              SQL.Add('order by ProCode');
              Open;
              if Fields[0].AsInteger>0 then
              begin
                DecodeDate(EncodeDate(YearL, MonthL, DayL) - LookDeletedDays + 1,
                  Year, Month, Day);
                ProDate1 := EncodeDosDate(Year, Month, Day);
                ShowProtoMes(plInfo, MesTitle, '---Просмотр удаленных проводок за '
                  +IntToStr(LookDeletedDays)+' дней (с '
                  +DosDateToStr(ProDate1)+' по '+DosDateToStr(ProDate)+')---');
                SQL.Clear;
                SQL.Add('Select /*+ index_asc(DelPro DelPro1) */ * from '+OrScheme+'.DelPro where ProDate>=');
                SQL.Add('to_date('''+DosDateToStr(ProDate1)+''',''dd.mm.yyyy'') ');
                SQL.Add('and ProDate<=to_date('''+DosDateToStr(ProDate)+''',''dd.mm.yyyy'')');
                SQL.Add(' order by ProCode');
                Open;
                if Length(FieldByName('ProDate').AsString)>0 then
                begin
                  ProDate1 := 0;
                  ProgressBar.Min := 0;
                  ProgressBar.Position := ProgressBar.Min;
                  ProgressBar.Max := LookDeletedDays;
                  ProgressBar.Show;
                  C := 0;
                  while not eof and Process do
                  begin
                    if ProDate1 <> DateToDosDate(FieldByName('ProDate').AsDateTime) then
                    begin
                      ProDate1 := DateToDosDate(FieldByName('ProDate').AsDateTime);
                      ProgressBar.Position := ProgressBar.Position+1;
                      Application.ProcessMessages;
                    end;
                    ImpKey.pkProCode := FieldByName('ProCode').AsInteger{ProKey.pkProCode};
                    ImpKey.pkProDate := DateToDosDate(FieldByName('ProDate').AsDateTime){ProKey.pkProDate};
                    Len := SizeOf(ImportRec);
                    Res := ImportDataSet.BtrBase.GetEqual(ImportRec, Len,
                      ImpKey, 2);
                    if Res=0 then
                    begin   //да, была выгружена из К в БК - надо удалять
                      Len := SizeOf(OpRec);
                      I := ImportRec.irIderB;
                      Res := BillDataSet.BtrBase.GetEqual(OpRec, Len, I, 0);
                      if Res=0 then
                      begin
                        BtrStartTA;
                        if OpRec.brDel=0 then
                          with OpRec do
                          begin
                            if brDate>LastCloseDate then
                            begin
                              J := OpRec.brDocId;
                              Len1 := SizeOf(PayRec);
                              Res1 := PayDataSet.BtrBase.GetEqual(PayRec, Len1,
                                J, 0);
                              if Res1<>0 then
                                PayRec.dbIdSender := 0;
                              if CorrectOpSum(brAccD, brAccC, Round(brSum), 0,
                                brDate, PayRec.dbIdSender, W, RedSaldoList) then
                              begin
                                if OpIsSent(OpRec, PayRec.dbIdSender) then
                                begin
                                  brState := W;
                                  brDel := 1;
                                  Inc(brVersion);
                                  Res := BillDataSet.BtrBase.Update(OpRec,
                                    Len, I, 0);
                                  if Res=0 then
                                    ShowProtoMes(plInfo, MesTitle, 'Проводка отменена '+OpInfo(OpRec))
                                  else
                                    ShowProtoMes(plError, MesTitle, 'Не удалось отменить проводку '+OpInfo(OpRec));
                                end
                                else begin
                                  Res := BillDataSet.BtrBase.Delete(0);
                                  if Res=0 then
                                    ShowProtoMes(plInfo, MesTitle, 'Проводка удалена '+OpInfo(OpRec))
                                  else
                                    ShowProtoMes(plError, MesTitle, 'Не удалось удалить проводку '
                                      +OpInfo(OpRec)+' BtrErr='+IntToStr(Res));
                                end;
                              end
                              else begin
                                Res := 1;
                                ShowProtoMes(plError, MesTitle, 'Не удалось скорректировать остаток при удалении проводки '
                                  +OpInfo(OpRec));
                              end;
                              RedSaldoCountLabel.Caption := IntToStr(RedSaldoList.Count);
                            end
                            else begin
                              Res := 1;
                              ShowProtoMes(plWarning, MesTitle, 'Нельзя отменить проводку '
                                +OpInfo(OpRec)+' от '
                                +BtrDateToStr(brDate)+' в закрытых днях ('
                                +BtrDateToStr(LastCloseDate)+')');
                            end;
                          end;
                        if Res=0 then
                        begin
                          Res := ImportDataSet.BtrBase.Delete(2);
                          if Res=0 then
                          begin
                            BtrCommitTA;
                            Inc(C)
                          end
                          else
                            ShowProtoMes(plError, MesTitle, 'Не удалось убрать пометку о удаленной проводке '
                              +OpInfo(OpRec)+' BtrErr='+IntToStr(Res));
                        end;
                        BtrAbortTA;
                      end
                      else
                        ShowProtoMes(plWarning, MesTitle, 'Загруженная ранее проводка не найдена Id='
                          +IntToStr(ImportRec.irIderB));
                    end;
                    Next;
                  end;
                  ShowProtoMes(plInfo, MesTitle, 'Удалено проводок: '+IntToStr(C));
                end
                else
                  ShowProtoMes(plWarning, MesTitle, 'Нет удаленных проводок за указанный период и позднее');
              end
              else
                ShowProtoMes(plWarning, MesTitle, 'Нет удаленных проводок за указанный период и ранее');
            end;
            ProgressBar.Hide;
            ShowProtoMes(plInfo, MesTitle, 'Просмотр удаленных проводок завершен');
          end;
// ======================== Картотека =========================================
          if LookKartotCheckBox.Checked then  { проверим картотеку }
          begin
            ShowProtoMes(plInfo, MesTitle, '---Просмотр картотеки---');
            Len := SizeOf(PayRec);
            Res := PayDataSet.BtrBase.GetFirst(PayRec, Len, I, 2);
            if Res=0 then
            begin
              Len := SizeOf(ExportRec);
              Res := ExportDataSet.BtrBase.GetLast(ExportRec, Len, I, 0);
              if (Res=0) and (I>=PayRec.dbIdHere) then
              begin
                ProgressBar.Min := 0;
                ProgressBar.Position := ProgressBar.Min;
                ProgressBar.Max := I;
                Len := SizeOf(ExportRec);
                I := PayRec.dbIdHere;
                Res := ExportDataSet.BtrBase.GetGE(ExportRec, Len, I, 0);
                ProgressBar.Min := I;
                ProgressBar.Position := ProgressBar.Min;
                C := 0;
                C1 := 0;
                C2 := 0;
                while (Res=0) and Process and not BtrTAExecuted do
                begin
                  C3 := 0;
                  if GetDocOp(OpRec, ExportRec.erIderB, Len) then
                  begin
                    if (OpRec.brPrizn=brtReturn) or (OpRec.brPrizn=brtKart) then
                    begin
                      ImpKey.pkProDate := RetSignDate;
                      ImpKey.pkProCode := OpRec.brIder;
                      Res := ImportDataSet.BtrBase.GetEqual(ImportRec, Len,
                        ImpKey, 2);
                      if Res=0 then {этот возврат получен из картотеки}
                        C3 := -1;  {тогда проверим, не убрали ли его}
                    end;
                  end
                  else
                    C3 := 1;
                  if C3<>0 then
                  begin
                    J := OrGetChildOperNumByKvitan(ExportRec.erOperation,
                      ExportRec.erOperNum, coVbKartotOperation);
                    if (C3>0) and (J>0) or (C3<0) and (J=0) then
                    begin
                      if J>0 then
                      begin
                        //Добавлено Меркуловым
                        with OraBase, OrQuery do
                        begin
                          SQL.Clear;
                          SQL.Add('Select /*+ index_asc(VbKartOt vKrt1) */ * from '+OrScheme+'.VbKartOt where ');
                          SQL.Add('OperNum='+IntToStr(J));
                          Open;
                          if Length(Fields[0].AsString)>0 then
                          begin
                            Inc(C);
                            J := ExportRec.erIderB;
                            Len := SizeOf(PayRec);
                            Res1 := PayDataSet.BtrBase.GetEqual(PayRec, Len, J, 2);
                            if Res1=0 then
                            begin
                              BtrStartTA;
                              if MakeKart(PayRec.dbIdHere, 'Поставлен в картотеку',
                                DateToBtrDate(Date), OpRec) then
                              begin
                                Inc(C1);
                                J := OpRec.brIder;
                                with ImportRec do
                                begin
                                  irIderB := J;
                                  irOperNum := FieldByName('OperNum').AsInteger;
                                  irOperation := coVbKartotOperation;
                                  irProCode := J;
                                  irProDate := RetSignDate;
                                end;
                                Len := SizeOf(ImportRec);
                                Res1 := ImportDataSet.BtrBase.Insert(ImportRec, Len, I, 0);
                                if Res1=0 then
                                  BtrCommitTA
                                else
                                  ShowProtoMes(plError, MesTitle, 'Не удалось поставить пометку о возврате '
                                    +OpInfo(OpRec)+' BtrErr='+IntToStr(Res1));
                              end
                              else begin
                                S := 'Документ '+DocInfo(PayRec)+' в картотеке '
                                  +Trim(FieldByName('KartNum').AsString)+' - ';
                                ShowProtoMes(plError, MesTitle, S + 'не удалось создать возврат '
                                  +OpInfo(OpRec));
                              end;
                              BtrAbortTA;
                            end
                            else
                              ShowProtoMes(plWarning, MesTitle, 'Картотечный документ '+DocInfo(PayRec)
                                +' не найден среди текущих');
                          end
                          else
                            ShowProtoMes(plWarning, MesTitle, 'Найдена картотечная операция, но нет записи в картотеке VbKartOt OperNum='
                              +IntToStr(J));
                        end;
                      end
                      else
                        with OpRec do
                        begin
                          if brDate>LastCloseDate then
                          begin
                            J := brIder;
                            Len := SizeOf(OpRec);
                            Res1 := BillDataSet.BtrBase.GetEqual(OpRec, Len, J, 0);
                            if Res1=0 then
                            begin
                              J := OpRec.brDocId;
                              Len1 := SizeOf(PayRec);
                              Res1 := PayDataSet.BtrBase.GetEqual(PayRec, Len1,
                                J, 0);
                              if Res1<>0 then
                                PayRec.dbIdSender := 0;
                              BtrStartTA;
                              if OpIsSent(OpRec, PayRec.dbIdSender) then
                              begin
                                if DeleteOp(OpRec, PayRec.dbIdSender) then
                                begin
                                  Res1 := BillDataSet.BtrBase.Update(OpRec, Len, J, 0);
                                  if Res1=0 then
                                  begin
                                    Inc(C2);
                                    ShowProtoMes(plInfo, MesTitle, 'Возврат отменен '+OpInfo(OpRec))
                                  end
                                  else
                                    ShowProtoMes(plError, MesTitle, 'Не удалось отменить возврат '
                                      +OpInfo(OpRec)+' BtrErr='+IntToStr(Res1));
                                end
                                else begin
                                  Res1 := 1;
                                  ShowProtoMes(plWarning, MesTitle, 'Не удалось обнулить возврат '
                                    +OpInfo(OpRec));
                                end;
                              end
                              else begin
                                Res1 := BillDataSet.BtrBase.Delete(0);
                                if Res1=0 then
                                  ShowProtoMes(plInfo, MesTitle, 'Возврат удален '+OpInfo(OpRec))
                                else
                                  ShowProtoMes(plError, MesTitle, 'Не удалось удалить возврат '
                                    +OpInfo(OpRec)+' BtrErr='+IntToStr(Res1));
                              end;
                            end
                            else
                              ShowProtoMes(plWarning, MesTitle, 'Возврат '+OpInfo(OpRec)+
                                ' не найден BtrErr='+IntToStr(Res1));
                            if Res1=0 then
                            begin
                              Res1 := ImportDataSet.BtrBase.Delete(2);
                              if Res1=0 then
                                BtrCommitTA
                              else
                                ShowProtoMes(plError, MesTitle, 'Не удалось убрать пометку о ранее созданом возврате '+OpInfo(OpRec)
                                  +' BtrErr='+IntToStr(Res1));
                            end;
                            BtrAbortTA;
                          end
                          else
                            ShowProtoMes(plWarning, MesTitle, 'Нельзя отменить возврат '+OpInfo(OpRec)
                              +' от '+BtrDateToStr(brDate)+' в закрытых днях ('
                              +BtrDateToStr(LastCloseDate)+')');
                        end;
                    end;
                  end;
                  ProgressBar.Position := I;
                  Application.ProcessMessages;
                  Len := SizeOf(ExportRec);
                  Res := ExportDataSet.BtrBase.GetNext(ExportRec, Len, I, 0);
                end;
                ProgressBar.Hide;
                if BtrTAExecuted then
                begin
                  BtrAbortTA;;
                  ShowProtoMes(plWarning, MesTitle, 'Транзакция Btrieve не была завершена');
                end;
                if C2>0 then
                  ShowProtoMes(plInfo, MesTitle, 'Отменено возвратов по картотеке: '+IntToStr(C2));
                if C>0 then
                begin
                  S := 'Создано возвратов по картотеке: '+IntToStr(C1);
                  if C1<>C then
                    S := S + 'из '+IntToStr(C)+' найденых';
                  ShowProtoMes(plInfo, MesTitle, S);
                end
                else
                  ShowProtoMes(plInfo, MesTitle, 'Нет новых картотечных документов');
              end
              else
                ShowProtoMes(plInfo, MesTitle, 'Нет выгруженных документов среди текущих');
            end
            else
              ShowProtoMes(plWarning, MesTitle, 'Нет текущих документов');
          end;
          ShowProtoMes(plInfo, MesTitle, '---Просмотр проводок на дату '
            +DosDateToStr(ProDate)+'---');
          BtrProDate := CodeBtrDate(YearL, MonthL, DayL);
// ======================== Проводки =========================================
          if BtrProDate>UpdDate1 then    // проход по проводкам, импорт их и док-тов
          begin
            if BtrProDate>LastCloseDate then
            begin
              with OraBase, OrQuery{QrmBases[qbPro]} do
              begin
                DecodeDate(EncodeDate(YearL, MonthL, DayL) + 1.0,
                  Year, Month, Day);
                ProDate1 := EncodeDosDate(Year, Month, Day);
                SQL.Clear;
                SQL.Add('Select /*+ index_asc(PRO Pro1) */ * from '+OrScheme+'.Pro where ProDate=to_date('''+DosDateToStr(ProDate)+''',''dd.mm.yyyy'') order by Procode');
                Open;
                if Length(FieldByName('ProDate').AsString)>0 then
                begin
                  Last;
                  ProgressBar.Min := 0;
                  ProgressBar.Position := ProgressBar.Min;
                  ProgressBar.Max := FieldByName('ProCode').AsInteger;
                  if Length(FieldByName('ProDate').AsString)>0 then
                  begin
                    First;
                    C := 0;
                    C1 := 0; C2 := 0; C3 := 0;
                    DC := 0;
                    DC1 := 0; DC2 := 0; DC3 := 0;
                    IOutbankCountLabel.Caption := '0';
                    IInbankCountLabel.Caption := '0';
                    ICashCountLabel.Caption := '0';

                    ProgressBar.Min := FieldByName('ProCode').AsInteger;
                    ProgressBar.Position := ProgressBar.Min;
                    ProgressBar.Show;
                    while not Eof and Process {and not TAExecuted} do
                    begin  // проход по базе проводок
                      if DoLoadLabel.Caption='\' then
                        DoLoadLabel.Caption := '/'
                      else
                        DoLoadLabel.Caption := '\';
                      ProCode := 0;
                      try
                        ProCode := FieldByName('ProCode').AsInteger;
                        if OrGetNewAccByAccAndCurr(FieldByName('DbAcc').AsString,
                          FieldByName('DbCurrCode').AsString, SS1)
                          and OrGetNewAccByAccAndCurr(FieldByName('KrAcc').AsString,
                          FieldByName('KrCurrCode').AsString, SS2) then
                        begin  // длинные счета найдены
                          try
                            Operation := FieldByName('Operation').AsInteger;
                            OperNum := FieldByName('OperNum').AsInteger;
                          except
                            ShowProtoMes(plError, MesTitle, 'Ошибочные коды Operation/OperNum=['
                              +FieldByName('Operation').AsString+'/'+FieldByName('OperNum').AsString);
                          end;
                          with ExpKey do
                          begin
                            ekOperNum := OperNum;
                            ekOperation := Operation;
                          end;
                          try
                            Len := SizeOf(ExportRec);
                            Res := ExportDataSet.BtrBase.GetEqual(ExportRec, Len,
                              ExpKey, 1);
                            if Res<>0 then
                            begin  // проводка не была загружена из БК
                              ExportRec.erIderB := 0;
                              if Operation=coPayOrderOperation then
                              begin  {это межбанк - проверим родителей документа по цепочке вверх}
                                I := OperNum;
                                while (I>0) and (ExportRec.erIderB=0) do
                                begin  {есть родитель и он не из БК}
                                  J := I;
                                  I := OrGetParentOperNumByKvitan(Operation, J, Operation);
                                  if I>0 then
                                  begin
                                    with ExpKey do
                                    begin
                                      ekOperNum := I;
                                      ekOperation := Operation;
                                    end;
                                    Len := SizeOf(ExportRec);
                                    Res := ExportDataSet.BtrBase.GetEqual(ExportRec, Len,
                                      ExpKey, 1);
                                    if Res<>0 then
                                      ExportRec.erIderB := 0;
                                  end;
                                end;
                              end;
                            end;
                          except
                            ShowProtoMes(plError, MesTitle, 'Исключение проверки истории выгрузки Operation/OperNum=['
                              +FieldByName('Operation').AsString+'/'+FieldByName('OperNum').AsString);
                          end;

                          try
                            I := -1;
                            Res := IsBankClAcc(SS1, BtrProDate, 0);
                            if Res>I then
                              I := Res;
                            Res := IsBankClAcc(SS2, BtrProDate, 0);
                            if Res>I then
                              I := Res;
                          except
                            ShowProtoMes(plError, MesTitle, 'Исключение при поиске счетов в БК SS1/SS2=['
                              +SS1+'/'+SS2);
                          end;

                          if (ExportRec.erIderB<>0) or (I>0) then
                          begin    //один из счетов присутствует в БК и активен
                            BillNum := 0;
                            DocNum := 0;
                            PayRec.dbIdSender := 0;

                            try
                              ImpKey.pkProCode := ProCode;{ProKey.pkProCode};  //загружалась ли проводка
                              ImpKey.pkProDate := DateToDosDate(FieldByName('ProDate').AsDateTime){ProKey.pkProDate};
                              Len := SizeOf(ImportRec);
                              Res := ImportDataSet.BtrBase.GetEqual(ImportRec, Len,
                                ImpKey, 2);
                              if Res=0 then
                              begin          //проводка ранее загружалась
                                Len := SizeOf(OpRec);
                                I := ImportRec.irIderB;     //найдем активную
                                Res1 := BillDataSet.BtrBase.GetEqual(OpRec, Len,
                                  I, 0);
                                while (Res1=0) and (OpRec.brIder=ImportRec.irIderB)
                                  and (OpRec.brDel<>0) do
                                begin
                                  Len := SizeOf(OpRec);
                                  Res1 := BillDataSet.BtrBase.GetNext(OpRec, Len,
                                    I, 0);
                                end;
                                if (Res1=0) and (OpRec.brIder=ImportRec.irIderB) then
                                begin        //она существует и активна
                                  BillNum := I;
                                  Len := SizeOf(PayRec);
                                  I := OpRec.brDocId;
                                  DocNum := I;
                                  Res1 := PayDataSet.BtrBase.GetEqual(PayRec, Len, I, 0);
                                  if Res1=4 then
                                  begin   //но документа уже нет
                                    ShowProtoMes(plInfo, MesTitle, 'Повторная загрузка документа по проводке '+OpInfo(OpRec));
                                    DocNum := -DocNum;
                                  end
                                  else
                                    if Res<>0 then
                                    begin
                                      BillNum := $FFFF;
                                      DocNum := $FFFF;
                                      ShowProtoMes(plError, MesTitle, 'Ошибка поиска документа '+DocInfo(PayRec)
                                        +' по Id='+IntToStr(I)+' BtrErr='
                                        +IntToStr(Res)+'. Проводка пропущена');
                                    end;
                                end
                                else begin   {надо снова}
                                  Res1 := ImportDataSet.BtrBase.Delete(2);
                                  if Res1=0 then
                                    ShowProtoMes(plWarning, MesTitle, 'Повторная загрузка проводки ProCode='
                                      +IntToStr(ProCode{ProKey.pkProCode}))
                                  else begin
                                    BillNum := $FFFF;
                                    DocNum := $FFFF;
                                    ShowProtoMes(plError, MesTitle, 'Не могу удалить пометку о проводке ProCode='
                                      +IntToStr(ProCode{ProKey.pkProCode})+' для повторной загрузки');
                                  end;
                                end;
                              end
                              else
                                if Res<>4 then
                                begin
                                  BillNum := $FFFF;
                                  DocNum := $FFFF;
                                  ShowProtoMes(plError, MesTitle, 'Ошибка поиска ImpRec='+ImpInfo(ImportRec)
                                    +' BtrErr='+IntToStr(Res)+'. Проводка пропущена ProCode='
                                    +IntToStr(ProCode{ProKey.pkProCode}));
                                end;
                            except
                              ShowProtoMes(plError, MesTitle, 'Исключение при просмотре истории загрузки ProCode='+IntToStr(ProCode));
                            end;

                            try
                              if (DocNum=0) and ((Operation<>coCashOrderOperation)                            
                                or (FieldByName('Cash').AsInteger<>0)) then
                              begin  {по проводке нет документа в БК и это не комиссия от кассового ордера}
                                if ExportRec.erIderB<>0 then
                                begin        {операция была порождена документом БК - проверим его наличие}
                                  I := ExportRec.erIderB;
                                  DocNum := I;
                                  Len := SizeOf(PayRec);
                                  Res1 := PayDataSet.BtrBase.GetEqual(PayRec, Len, I, 0);
                                  if Res1=0 then
                                    ShowProtoMes(plInfo, MesTitle, 'Проводим док-т '+DocInfo(PayRec))
                                  else begin {нет документа в БК - надо восстановить}
                                    Res1 := ExportDataSet.BtrBase.Delete(1);
                                    if Res1=0 then
                                    begin
                                      DocNum := -DocNum;
                                      ShowProtoMes(plWarning, MesTitle, 'Восстановим выгруженный и удаленный документ '+DocInfo(PayRec))
                                    end
                                    else begin
                                      BillNum := $FFFF;
                                      ShowProtoMes(plError, MesTitle, 'Невозможно удалить пометку в базе "экспорт" '
                                        +DocInfo(PayRec)+' BtrErr='+IntToStr(Res1));
                                    end;
                                  end;
                                end;
                              end;
                            except
                              ShowProtoMes(plError, MesTitle, 'Исключение при проверки пометки выгрузки ProCode='+IntToStr(ProCode));
                            end;

                            if (DocNum<=0) or (BillNum<=0) then
                            try
                              DocSum := FieldByName('SumPro').AsFloat*100.0;
                              Number := Trim(FieldByName('DocNum').AsString);
                              DocDate := DateToBtrDate(FieldByName('DocDate').AsDateTime);
                              BasicUserCode := FieldByName('UserCode').AsInteger;

                              if FieldByName('Cash').AsInteger=0 then
                              begin
                                try
                                  DocType := FieldByName('OperCode').AsInteger;
                                except
                                  DocType := 1;
                                  ShowProtoMes(plError, MesTitle, 'Исключение оцифрения OperCode ['
                                    +FieldByName('OperCode').AsString+'] ProCode='+IntToStr(ProCode)
                                    +' Operation/OperNum='+IntToStr(Operation)+'/'+IntToStr(OperNum));
                                end;
                              end
                              else
                                DocType := 3;

                              PInn := '';
                              PClient := '';
                              PAcc := '';
                              PCode := BankBik;
                              RInn := '';
                              RClient := '';
                              RAcc := '';
                              RCode := BankBik;
                              Purpose := '';
                              DebitKpp := '';
                              CreditKpp := '';
                              Status := '';
                              Kbk := '';
                              Okato := '';
                              OsnPl := '';
                              Period := '';
                              NDoc := '';
                              NDocDate := '';
                              TipPl := '';
                              Nchpl := '';
                              Shifr := '';
                              Nplat := '';
                              OstSum := '';

                              I := -1;
                              {Res := 1;}
                              DocOcher := 6;

                              if (Operation=coPayOrderOperation)
                                or (Operation=coRecognizeSumOperation)
                                or (Operation=coVypOperation) then
                              begin  // межбанк
                                if Operation=coPayOrderOperation then
                                  J := OperNum
                                else
                                  try
                                    J := OrGetChildOperNumByKvitan(Operation, OperNum,
                                      coPayOrderOperation);
                                  except
                                    J := 0;
                                    ShowProtoMes(plError, MesTitle, 'Исключение поиска по квитанц. ProCode='+IntToStr(ProCode)
                                      +' Operation/OperNum='+IntToStr(Operation)+'/'+IntToStr(OperNum));
                                  end;
                                if J>0 then
                                try
                                  with OrQuery2 do
                                  begin
                                    SQL.Clear;
                                    SQL.Add('Select /*+ index_asc(PayOrder PaO1) */ * from '+OrScheme+'.PayOrder where OperNum='+IntTostr(J));
                                    Open;
                                    if Length(Fields[0].AsString)>0 then
                                    begin
                                      try
                                        DocOcher := FieldByName('Priority').AsInteger;
                                      except
                                        DocOcher := 0;
                                        ShowProtoMes(plError, MesTitle, 'Межбанк. Исключение оцифрения "очер.плат"=['
                                          +FieldByName('Priority').AsString+'] ProCode='+IntToStr(ProCode)
                                          +' Operation/OperNum='+IntToStr(Operation)+'/'+IntToStr(OperNum));
                                      end;
                                      if FieldByName('DocType').AsString='К'{#$8A} then  //досовская 'К'
                                      begin
                                        //Добавлено Меркуловым
                                        if (DocType = 1) then          //Если пл.поручение и клиент по дебиту, то метка для
                                        begin
                                          ClientInn := 'incoming';     //замены плательщика в функции GetClientByAcc()
                                        end;
                                        //Конец
                                        if OrGetClientByAcc(OrQuery.FieldByName('DbAcc').AsString,
                                          OrQuery.FieldByName('DbCurrCode').AsString,
                                          ClientInn, ClientName, ClientNewAcc, OldClName) then
                                        begin
                                          PInn := ClientInn;
                                          PClient := ClientName;
                                          PAcc := ClientNewAcc;
                                          PCode := BankBik;
                                          if Length(OldClName)>0 then
                                            ShowProtoMes(plInfo, MesTitle, 'Имя клиента ['+DosToWinS(OldClName)
                                              +'] -> имя нашего банка OperNum='+IntToStr(OperNum));
                                        end
                                        else
                                          ShowProtoMes(plWarning, MesTitle, 'Межбанк. Клиент не найден по счету дебета '
                                            +OrQuery.FieldByName('DbAcc').AsString);
                                        RInn := FieldByName('BenefTaxNum').AsString;
                                        RClient := WinToDosS(FieldByName('BenefName').AsString);
                                        RAcc := FieldByName('BenefAcc').AsString;
                                        RCode := FieldByName('ReceiverBankNum').AsString;
                                        //Добавлено Меркуловым
                                        DebitKpp := FieldByName('KppOur').AsString;
                                        CreditKpp := FieldByName('BenefKpp').AsString;
                                      end
                                      else begin     //  "Д"
                                        RAcc := SS2;
                                        RInn := FieldByName('INNOur').AsString;
                                        RClient := WinToDosS(FieldByName('ClientNameOur').AsString);
                                        RCode := BankBik;
                                        if (Length(RInn)=0) or (Length(RClient)=0) then
                                        begin
                                          if OrGetClientByAcc(OrQuery.FieldByName('KrAcc').AsString,
                                            OrQuery.FieldByName('KrCurrCode').AsString,
                                            ClientInn, ClientName, ClientNewAcc, OldClName) then
                                          begin
                                            RInn := ClientInn;
                                            RClient := ClientName;
                                            RAcc := ClientNewAcc;
                                            RCode := BankBik;
                                            MessageBox(Application.Handle,
                                              PChar('В загружаемом документе ['
                                                +'N'+Number+' '
                                                +BtrDateToStr(DocDate)+' '+SumToStr(DocSum)
                                                +'] пустые поля ИНН и название получателя'
                                                +#13#10'взяты из справочника клиентов'),
                                                MesTitle, MB_OK or MB_ICONWARNING);
                                            ShowProtoMes(plWarning, MesTitle,
                                              'В загружаемом документе ['
                                                +'N'+Number+' '
                                                +BtrDateToStr(DocDate)+' '+SumToStr(DocSum)
                                                +'] пустые поля ИНН и название получателя'
                                                +#13#10'взяты из справочника клиентов');
                                          end
                                          else
                                            ShowProtoMes(plWarning, MesTitle,
                                              'Межбанк. Клиент не найден по счету кредита '
                                              +OrQuery.FieldByName('KrAcc').AsString);
                                        end;
                                        PInn := FieldByName('BenefTaxNum').AsString;
                                        PClient := WinToDosS(FieldByName('BenefName').AsString);
                                        PAcc := FieldByName('BenefAcc').AsString;
                                        PCode := FieldByName('SenderBankNum').AsString;
                                        //Добавлено Меркуловым
                                        CreditKpp := FieldByName('KppOur').AsString;
                                        DebitKpp := FieldByName('BenefKpp').AsString;
                                      end;
                                    end
                                    else
                                      ShowProtoMes(plWarning, MesTitle,
                                        'Исходный документ не найден Operation='
                                        +IntToStr(Operation)+' OperNum='+IntToStr(OperNum)
                                        +' J='+IntToStr(J)
                                        +' BtrErr='+IntToStr(Res));
                                  end;
                                  GetDocShifrs(Operation, OperNum,
                                    Status, Kbk, Okato, OsnPl, Period, //Изменено Меркуловым
                                    NDoc, NDocDate, TipPl);
                                except
                                  ShowProtoMes(plError, MesTitle, 'Межбанк. Исключение при взятии реквизитов ProCode='+IntToStr(ProCode)
                                  +' Operation/OperNum='+IntToStr(Operation)+'/'+IntToStr(OperNum));
                                end
                                else
                                  ShowProtoMes(plWarning, MesTitle,
                                    'Ошибка поиска документа по квитанции '
                                      +IntToStr(Operation)+'|'+IntToStr(OperNum));
                              end
                              else begin  // внутрибанк
                                if OrGetClientByAcc(FieldByName('DbAcc').AsString,
                                  FieldByName('DbCurrCode').AsString,
                                  ClientInn, ClientName, ClientNewAcc, OldClName) then
                                begin
                                  PInn := ClientInn;
                                  PClient := ClientName;
                                  PAcc := ClientNewAcc;
                                end
                                else
                                  ShowProtoMes(plWarning, MesTitle, 'Внутрибанк. Клиент не найден по счету дебита '
                                    +FieldByName('DbAcc').AsString);
                                if OrGetClientByAcc(FieldByName('KrAcc').AsString,
                                  FieldByName('KrCurrCode').AsString,
                                  ClientInn, ClientName, ClientNewAcc, OldClName) then
                                begin
                                  RInn := ClientInn;
                                  RClient := ClientName;
                                  RAcc := ClientNewAcc;
                                end
                                else
                                  ShowProtoMes(plWarning, MesTitle, 'Внутрибанк. Клиент не найден по счету кредита '
                                    +FieldByName('KrAcc').AsString);
                                PCode := BankBik;
                                RCode := BankBik;
                              end;

                              if OrGetBankByRekvisit(PCode, True, BankCorrCode,
                                BankUchCode, BankMFO, BankCorrAcc) then
                              begin
                                PKs := BankCorrCode;
                                PBank := BankUchCode;
                              end;
                              if OrGetBankByRekvisit(RCode, True, BankCorrCode,
                                BankUchCode, BankMFO, BankCorrAcc) then
                              begin
                                RKs := BankCorrCode;
                                RBank := BankUchCode;
                              end;
                              //ProKey1 := ProKey;
                              if FieldByName('Cash').AsInteger=0 then
                              begin  // не кассовый ордер
                                with OrQuery2 do
                                begin
                                  SQL.Clear;
                                  SQL.Add('Select /*+ index_asc(CommentADoc DocAbyPro) */ * from '+OrScheme+'.CommentADoc where ');
                                  SQL.Add('ProDate=to_date('''+OrQuery.FieldByName('ProDate').AsString+''',''dd.mm.yyyy'')');
                                  SQL.Add(' and ProCode='+IntToStr(ProCode));
                                  Open;
                                  if Length(FieldByName('ProDate').AsString)>0 then
                                    Purpose := WinToDosS(FieldByName('Comment_').AsString)
                                  else
                                    ShowProtoMes(plWarning, MesTitle, 'Не найдено назначение платежа в CommentADoc, ProCode='
                                      +IntToStr(ProCode{ProKey.pkProCode}));
                                end;
                              end
                              else
                              try  // это кассовый
                                //Добавлено Меркуловым
                                PasPlc := '';
                                PasNum := '';
                                PasSer := '';
                                FIO    := '';
                                {CashKey.pcNumOp := OperNum;}
                                Res1 := -1;
                                J := 0;
                                with OrQuery2 do
                                begin
                                  SQL.Clear;
                                  SQL.Add('Select /*+ index_asc(CashOrder iCODoc1) */ * from '+OrScheme+'.CashOrder where DocCode='+IntToStr(OperNum));
                                  Open;
                                  if Length(FieldByName('DocCode').AsString)>0 then
                                  begin
                                    DcType := WinToDosS(FieldByName('DocType').AsString);
                                    if(DcType=#$90) then
                                    begin
                                      PasSer := WinToDosS(FieldByName('SerPasp').AsString);
                                      PasNum := WinToDosS(FieldByName('NumPasp').AsString);
                                    end;
                                    if(DcType=#$8F) then
                                      FIO := WinToDosS(FieldByName('FIO').AsString);
                                  end
                                  else
                                    ShowProtoMes(plWarning, MesTitle, 'Не найдены сведения паспорта в CashOrder OperNum='
                                      +IntToStr(FieldByName('OperNum').AsInteger));
                                end;
                                FIO := WinToDosS(GetDocComment(OperNum, 4));
                                with OrQuery2 do
                                begin //getdoccomment
                                  Purpose := GetDocComment(OperNum, 2);
                                  if Length(Purpose)>0 then
                                  begin
                                    Purpose := WinToDosS(Purpose);
                                    Len := Length(Purpose);
                                    while (J<Len) and (Purpose[J]<>'@') do
                                      Inc(J);
                                    if (J<Len) then
                                      PasPlc := Copy(Purpose,J+2,(Len-J+2));
                                    Purpose := Copy(Purpose,1,J);
                                  end
                                  else begin
                                    ShowProtoMes(plInfo, MesTitle, 'Пустое назначение платежа в PayOrCom OperNum='+IntToStr(OperNum));
                                    Purpose := 'ЃҐ§ ­ §­ зҐ­Ёп';
                                  end;
                                end;
                                if (DcType=#$90) then
                                  with OrQuery2 do
                                  begin
                                    {SQL.Clear;
                                    SQL.Add('Select * from '+OrScheme+'.PayOrCom where ');
                                    SQL.Add('OperNum='+IntToStr(OperNum)+' and Status=5');
                                    Open;}
                                    PasPlc := GetDocComment(OperNum, 5);
                                    if Length({FieldByName('OperNum').AsString}PasPlc)>0 then
                                    begin
                                      PasPlc := WinToDosS({FieldByName('Comment_').AsString}PasPlc);
                                      Len := Length(PasPlc);
                                      while (J<Len) do
                                      begin
                                        if (PasPlc[J]='п') or (PasPlc[J]='џ') then
                                          PasSer := Copy(PasPlc,J+2,4);
                                        if (PasPlc[J]='¬') or (PasPlc[J]='Њ') then
                                        begin
                                          PasNum := Copy(PasPlc,J+4,6);
                                          PasPlc := Trim(Copy(PasPlc,J+7,Len));
                                          J := Len;
                                        end;
                                        Inc(J);
                                      end;
                                    end
                                    else begin
                                      {SQL.Clear;
                                      SQL.Add('Select * from '+OrScheme+'.PayOrCom where ');
                                      SQL.Add('OperNum='+IntToStr(OperNum)+' and Status=6');
                                      Open;}
                                      PasPlc := GetDocComment(OperNum, 6);
                                      if Length(PasPlc)>0 then
                                      {if Length(FieldByName('OperNum').AsString)>0 then}
                                        PasPlc := WinToDosS({FieldByName('Comment_').AsString}PasPlc)
                                      else
                                        ShowProtoMes(plWarning, MesTitle, 'Не найдено место и дата выдачи паспорта в PayOrCom, OperNum='+IntToStr(OperNum));
                                    end;
                                  end;
                                S := '';
                                with OrQuery2 do
                                begin
                                  SQL.Clear;
                                  SQL.Add('Select /*+ index_asc(CashsDA iCDateCode) */ * from '+OrScheme+'.CashsDA where ProDate');
                                  SQL.Add('=to_date('''+OrQuery.FieldByName('ProDate').AsString+''',''dd.mm.yyyy'') and ProCode');
                                  SQL.Add('='+IntToStr(ProCode));
                                  Open;
                                  while not Eof do
                                  begin
                                    if Length(S)>0 then
                                      S := S + ';';         //Изменено (убран пробел)
                                    Str(FieldByName('Summa').AsFloat:0:2, Sum);
                                    S := S + FieldByName('Symbol').AsString + '-' + Sum;
                                    Next;
                                  end;
                                end;
                                Purpose := Purpose + #13#10 + S;
                                if DcType=#$90 then
                                  Purpose := Purpose + '~' + PasSer + ' ' + PasNum + ' ' + PasPlc;
                                if DcType=#$8F then
                                  Purpose := Purpose + '~' + FIO;
                              except
                                ShowProtoMes(plError, MesTitle, 'Кассовый. Исключение при взятии реквизитов ProCode='+IntToStr(ProCode)
                                  +' Operation/OperNum='+IntToStr(Operation)+'/'+IntToStr(OperNum));
                              end;

                              if DocNum<=0 then
                              try     {надо записать документ}
                                try
                                  AddDocInBankCl(DocNum, CorrRes, PayRec, BasicUserCode);
                                except
                                  ShowProtoMes(plError, MesTitle, 'Исключение при добавлении документа ProCode='+IntToStr(ProCode)
                                    +' Operation/OperNum='+IntToStr(Operation)+'/'+IntToStr(OperNum));
                                end;

                                if DocNum=0 then
                                  ShowProtoMes(plError, MesTitle, 'Не удалось загрузить документ '+
                                    DocInfo(PayRec)+', ProCode='+IntToStr(ProCode{ProKey.pkProCode}))
                                else begin
                                  if CorrRes<>0 then
                                  begin
                                    S := 'В новом документе '+DocInfo(PayRec)
                                      +' найдены недопустимые символы';
                                    if CheckCharModeEx>1 then
                                      S := S + '. Все они были исправлены';
                                    ShowProtoMes(plInfo, MesTitle, S);
                                  end;
                                  if FieldByName('Cash').AsInteger=0 then
                                  begin
                                    case Operation of
                                      coPayOrderOperation, coRecognizeSumOperation,
                                      coVypOperation:
                                        begin
                                          Inc(DC1);
                                          DIOutbankCountLabel.Caption := IntToStr(DC1);
                                        end;
                                      coMemOrderOperation, coCashOrderOperation:
                                        begin
                                          Inc(DC2);
                                          DIInbankCountLabel.Caption := IntToStr(DC2);
                                        end;
                                    end;
                                  end
                                  else begin
                                    Inc(DC3);
                                    DICashCountLabel.Caption := IntToStr(DC3);
                                  end;
                                  Inc(DC);
                                end;
                              except
                                ShowProtoMes(plError, MesTitle, 'Исключение при записи документа ProCode='+IntToStr(ProCode)
                                +' Operation/OperNum='+IntToStr(Operation)+'/'+IntToStr(OperNum));
                              end;

                              if (BillNum<=0) and (DocNum>0) then
                              try  {документ существует, загрузим проводку}
                                if GetDocOp(OpRec, DocNum, Len) then
                                  ShowProtoMes(plWarning, MesTitle, 'Нельзя загрузить проводку для документа Id='
                                    +IntToStr(DocNum)+' - существует активная')
                                else begin           {запишем проводку}
                                  if BillNum=0 then
                                    MakeRegNumber(rnPaydoc, BillNum)
                                  else
                                    BillNum := Abs(BillNum);
                                  FillChar(OpRec, SizeOf(OpRec), #0);
                                  with OpRec do
                                  begin
                                    brIder := BillNum;
                                    brDocId := Abs(DocNum);
                                    brDate := {Dos}DateToBtrDate(FieldByName('ProDate').AsDateTime);
                                    Inc(brVersion);
                                    brPrizn := brtBill;
                                    brType := DocType;
                                    try
                                      brNumber := StrToInt(Trim(FieldByName('DocNum').AsString));
                                    except
                                      brNumber := 0;
                                      ShowProtoMes(plError, MesTitle, 'Проводка. Исключение оцифрения "номер проводки"=['
                                        +FieldByName('DocNum').AsString+'] ProCode='+IntToStr(ProCode)
                                        +' Operation/OperNum='+IntToStr(Operation)+'/'+IntToStr(OperNum));
                                    end;
                                    if Length(PAcc)=0 then
                                    begin
                                      if OrGetClientByAcc(
                                        FieldByName('DbAcc').AsString, FieldByName('DbCurrCode').AsString,
                                        ClientInn, ClientName, ClientNewAcc, OldClName) then
                                      begin
                                        PInn := ClientInn;
                                        PClient := ClientName;
                                        PAcc := ClientNewAcc;
                                      end
                                      else
                                        ShowProtoMes(plWarning, MesTitle, 'К. Клиент не найден по счету дебита '
                                          +FieldByName('DbAcc').AsString);
                                    end;
                                    if Length(RAcc)=0 then
                                    begin
                                      if OrGetClientByAcc(
                                        FieldByName('KrAcc').AsString, FieldByName('KrCurrCode').AsString,
                                        ClientInn, ClientName, ClientNewAcc, OldClName) then
                                      begin
                                        RInn := ClientInn;
                                        RClient := ClientName;
                                        RAcc := ClientNewAcc;
                                      end
                                      else
                                        ShowProtoMes(plWarning, MesTitle, 'К. Клиент не найден по счету кредита '
                                          +FieldByName('KrAcc').AsString);
                                    end;
                                    PAcc := SS1;
                                    RAcc := SS2;
                                    StrTCopy(brAccD, PChar(PAcc), SizeOf(TAccount));
                                    StrTCopy(brAccC, PChar(RAcc), SizeOf(TAccount));
                                    brSum := DocSum;
                                    Len := Length(Purpose);
                                    if DocType=3 then
                                    begin
                                      I := 0;
                                      while (I<Len) and (Purpose[I+1]<>#13)
                                        and (Purpose[I+1]<>#10)
                                      do
                                        Inc(I);
                                    end
                                    else
                                      I := Len;
                                    if I>brMaxText-1 then
                                      I := brMaxText-1;
                                    StrPLCopy(brText, Purpose, I);
                                    Len := StrLen(brText);

                                    S := GetUserNameByCode(PayRec.dbUserCode);
                                    if Length(S)>0 then
                                    begin
                                      Inc(Len);
                                      StrPLCopy(@brText[Len], S, SizeOf(brText)-Len-1);
                                      //WinToDos(@brText[Len]);
                                      Len := Len+StrLen(@brText[Len]);
                                    end;

                                  end;
                                  Len := 17 + 53 + Len + 1;
                                  I := BillNum;
                                  BtrStartTA;
                                  if CorrectOpSum(OpRec.brAccD, OpRec.brAccC,
                                    0, Round(OpRec.brSum), OpRec.brDate,
                                    PayRec.dbIdSender, W, RedSaldoList) then
                                  begin
                                    OpRec.brState := W;
                                    Res := BillDataSet.BtrBase.Insert(OpRec, Len, I, 0);
                                    if Res=0 then
                                    begin
                                      with ImportRec do
                                      begin
                                        irIderB := I;
                                        irOperNum := OperNum;
                                        irOperation := Operation;
                                        irProCode := ProCode;
                                        irProDate := DateToDosDate(FieldByName('ProDate').AsDateTime);
                                      end;
                                      Len := SizeOf(ImportRec);
                                      Res := ImportDataSet.BtrBase.Insert(ImportRec, Len, I, 0);
                                      if Res=0 then
                                      begin
                                        BtrCommitTA;
                                        if FieldByName('Cash').AsInteger=0 then
                                        begin
                                          case Operation of
                                            coPayOrderOperation, coRecognizeSumOperation,
                                            coVypOperation:
                                              begin
                                                Inc(C1);
                                                IOutbankCountLabel.Caption := IntToStr(C1);
                                              end;
                                            coMemOrderOperation, coCashOrderOperation:
                                              begin
                                                Inc(C2);
                                                IInbankCountLabel.Caption := IntToStr(C2);
                                              end;
                                          end;
                                        end
                                        else begin
                                          Inc(C3);
                                          ICashCountLabel.Caption := IntToStr(C3);
                                        end;
                                        Inc(C);
                                      end
                                      else
                                        ShowProtoMes(plError, MesTitle, 'Не удалось сделать пометку о загрузке проводки '
                                          +OpInfo(OpRec)+' BtrErr='+IntToStr(Res)
                                          +' ImpRec='+ImpInfo(ImportRec));
                                    end
                                    else
                                      ShowProtoMes(plError, MesTitle, 'Не удалось загрузить проводку '
                                        +OpInfo(OpRec)+'. BtrErr='+IntToStr(Res));
                                  end
                                  else
                                    ShowProtoMes(plError, MesTitle, 'Не удалось скорректировать остаток для проводки '
                                      +OpInfo(OpRec));
                                  RedSaldoCountLabel.Caption := IntToStr(RedSaldoList.Count);
                                  BtrAbortTA;
                                end;
                              except
                                ShowProtoMes(plError, MesTitle, 'Исключение при записи проводки ProCode='+IntToStr(ProCode)
                                +' Operation/OperNum='+IntToStr(Operation)+'/'+IntToStr(OperNum));
                              end;
                            except
                              ShowProtoMes(plError, MesTitle, 'Исключение при записи документа/проводки ProCode='+IntToStr(ProCode)
                                +' Operation/OperNum='+IntToStr(Operation)+'/'+IntToStr(OperNum));
                            end;
                          end;
                        end
                        else
                          ShowProtoMes(plWarning, MesTitle, 'Длинные счета '
                            +'Db='+FieldByName('DbAcc').AsString+'/'+FieldByName('DbCurrCode').AsString
                            +' Kr='+FieldByName('KrAcc').AsString+'/'+FieldByName('KrCurrCode').AsString
                            +' для проводки ProCode='+IntToStr(ProCode)+' не найдены');
                      except
                        ShowProtoMes(plError, MesTitle, 'Исключение при обработке проводки ProCode='+IntToStr(ProCode));
                      end;
                      ProgressBar.Position := ProCode;
                      Application.ProcessMessages;
                      Next;
                      {Len := FileRec.frRecordFixed;
                      Res := BtrBase.GetNext(Buffer^, Len, ProKey, 0);}
                    end;
                    ShowProtoMes(plInfo, MesTitle, 'Загружено документов: '+IntToStr(DC1+DC2+DC3));
                    ShowProtoMes(plInfo, MesTitle, 'Загружено проводок: '+IntToStr(C1+C2+C3));
                    if BtrTAExecuted then
                    begin
                      BtrAbortTA;
                      ShowProtoMes(plWarning, MesTitle, 'Транзакция Btrieve не была завершена');
                    end
                    else begin
                      DC := DC - (DC1+DC2+DC3);
                      if DC<>0 then
                        ShowProtoMes(plWarning, MesTitle, 'Не удалось загрузить документов: '+IntToStr(DC));
                      C := C - (C1+C2+C3);
                      if C=0 then
                        ShowProtoMes(plInfo, MesTitle, 'Импорт успешно завершен')
                      else
                        ShowProtoMes(plWarning, MesTitle, 'Импорт завершен не полностью. Не удалось загрузить выписок: '+IntToStr(C));
                    end;
                  end
                  else
                    ShowProtoMes(plInfo, MesTitle, 'Нет проводок указанной даты и позднее');
                end
                else
                  ShowProtoMes(plInfo, MesTitle, 'Нет проводок указанной даты и ранее');
              end;
              ProgressBar.Hide;
            end
            else
              ShowProtoMes(plWarning, MesTitle, 'Нельзя загрузить проводки за закрытые дни ('
                +BtrDateToStr(LastCloseDate)+')');
          end
          else
            ShowProtoMes(plInfo, MesTitle, 'Последняя дата работы Dos-версии '+BtrDateToStr(UpdDate1)
              +'.'#13#10'Нельзя загрузить проводки за старые дни');
        end;
        if RedSaldoList.Count>0 then
        begin
          CorrOpSumForm := TCorrOpSumForm.Create(Self);
          CorrOpSumForm.ResSaldoListMemo.Lines := RedSaldoList;
          CorrOpSumForm.ShowModal;
          //CorrOpSumForm.Free;
        end;
      end
      else
        ShowProtoMes(plWarning, MesTitle, 'Не все базы Кворум открыты');
    finally
      WorkTimer.Enabled := False;
      RedSaldoList.Free;
      DoLoadLabel.Hide;
    end
    else
      ShowProtoMes(plError, MesTitle, 'Ошибка при запросе баз Банк-клиента');
    if Process then
      ShowProtoMes(plInfo, MesTitle, 'Процесс завершен')
    else
      ShowProtoMes(plInfo, MesTitle, 'Процесс завершен не полностью');
    Process := False;
    PayDataSet.Refresh;
    AccDataSet.Refresh;
    ProccessBtn.Caption := '&Начать...';
    CancelBtn.Enabled := True;
  end;
end;

procedure TOraExchangeForm.PosDateEditChange(Sender: TObject);
begin
  CurrPosDate := PosDateEdit.Date;
end;

procedure TOraExchangeForm.DateEditChange(Sender: TObject);
begin
  CurrDate := DateEdit.Date;
end;

procedure ShowComponents(Comp: TWinControl; V: Boolean);
var
  I: Integer;
begin
  with Comp do
    for I := 0 to ControlCount-1 do
      Controls[I].Visible := V;
end;

procedure TOraExchangeForm.EOutbankLabelClick(Sender: TObject);
begin
  ProccessBtn.Enabled := ExportCheckBox.Checked or ImportCheckBox.Checked;
end;

procedure TOraExchangeForm.ExportCheckBoxClick(Sender: TObject);
begin
  PosDateEdit.Enabled := ExportCheckBox.Checked;
  SelectedCheckBox.Enabled := ExportCheckBox.Checked;
  ComisCheckBox.Enabled := ExportCheckBox.Checked;
  ShowComponents(ExportGroupBox, ExportCheckBox.Checked);
  EOutbankLabelClick(nil);
end;

procedure TOraExchangeForm.ImportCheckBoxClick(Sender: TObject);
begin
  DateEdit.Enabled := ImportCheckBox.Checked;
  LookDeletedCheckBox.Enabled := ImportCheckBox.Checked and (LookDeletedDays>0);
  LookKartotCheckBox.Enabled := ImportCheckBox.Checked;
  ShowComponents(ImportGroupBox, ImportCheckBox.Checked);
  EOutbankLabelClick(nil);
end;

procedure TOraExchangeForm.FormShow(Sender: TObject);
begin
  ExportCheckBoxClick(nil);
  ImportCheckBoxClick(nil);
end;

procedure TOraExchangeForm.SetBtnFocus;
begin
  Application.ProcessMessages;
  if ProccessBtn.Enabled then
    ProccessBtn.SetFocus
  else
    CancelBtn.SetFocus;
end;

procedure TOraExchangeForm.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  case Key of
    VK_F11:
      begin
        ExportCheckBox.Checked := not ExportCheckBox.Checked;
        SetBtnFocus;
      end;
    VK_F12:
      begin
        ImportCheckBox.Checked := not ImportCheckBox.Checked;
        SetBtnFocus;
      end;
  end;
end;

procedure TOraExchangeForm.ExportGroupBoxClick(Sender: TObject);
begin
  if not (ExportCheckBox.Checked and ImportCheckBox.Checked) then
    ExportCheckBox.Checked := not ExportCheckBox.Checked;
  ImportCheckBox.Checked := not ImportCheckBox.Checked;
  SetBtnFocus;
end;

//Добавлено Меркуловым

function SqlInsert(Values : array of const;
                   TableName : string;
                   ColNames : array of string) : string;    //Значение возвращаемого ключа
var RetVar,c : string;
    i : integer;
begin
  TableName := OraBase.OrScheme+'.'+TableName;
  RetVar := 'insert into ' + TableName + {CrLf}' ' + '(' + ColNames[0];
  for i := 1 to High(ColNames) do
     RetVar := RetVar + ',' + ColNames[i];
  RetVar := RetVar + ')' + {CrLf}' ';
  RetVar := RetVar + 'values (';
  for i := 0 to High(Values) do begin
     case Values[i].VType of
          vtInteger,
          vtInt64    : RetVar := RetVar + IntToStr(Values[i].VInteger);
          vtChar     : RetVar := RetVar + QuotedStr(Values[i].VChar);
          vtString   : if Pos('o_date(',Values[i].VString^)>0 then
                         RetVar := RetVar + Values[i].VString^
                       else
                         RetVar := RetVar + QuotedStr(Values[i].VString^);
          vtPChar    : RetVar := RetVar + QuotedStr(Values[i].VPChar);
          vtExtended : begin
                         c := FloatToStr(Values[i].VExtended^);
                         if Pos(',',c)>0 then
                           c[Pos(',',c)] := '.';
                         RetVar := RetVar + c;
                       end;
          vtAnsiString : if Pos('o_date(',string(Values[i].VAnsiString))>0 then
                           RetVar := RetVar + string(Values[i].VAnsiString)
                         else
                           RetVar := RetVar + QuotedStr(string(Values[i].VAnsiString));
          // TDateTime - иначе получаем как vtExtended
          vtVariant  : RetVar := RetVar + 'to_date(' +
                       QuotedStr(FormatdateTime('dd/mm/yyyy',
                       TDateTime(Values[i].VVariant^))) + ',' +
                       QuotedStr('dd/mm/yyyy') + ')';
     else
       RetVar := RetVar + '??????';
     end;
     RetVar := RetVar + ',';
  end;
  Delete(RetVar,length(RetVar),1);
  RetVar := RetVar + ')';
  if High(Values) < High(ColNames) then
     ShowMessage('SQL Insert - Not enough values.');
  if High(Values) > High(ColNames) then
     ShowMessage('SQL Insert - Too many values.');
  Result := RetVar;
end;

function SqlUpdate(Values : array of const;
                   TableName : string;
                   ColNames : array of string;
                   WhereClause : string) : string;
var RetVar,Parm : string;
    i : integer;
begin
  TableName := OraBase.OrScheme+'.'+TableName;
  RetVar := 'update ' + TableName + ' set' + {CrLf}' ';
  for i := 0 to Min(High(Values),High(ColNames)) do begin
     case Values[i].VType of
          vtInteger,
          vtInt64    : Parm := IntToStr(Values[i].VInteger);
          vtChar       : Parm := QuotedStr(Values[i].VChar);
          vtString   : Parm := QuotedStr(Values[i].VString^);
          vtPChar    : Parm := QuotedStr(Values[i].VPChar);
          vtExtended : Parm := FloatToStr(Values[i].VExtended^);
          vtAnsiString : Parm := QuotedStr(string(Values[i].VAnsiString));
          // TDateTime - иначе получаем как vtExtended
          vtVariant  : Parm := 'to_date(' +
                       QuotedStr(FormatdateTime('dd/mm/yyyy',
                       TDateTime(Values[i].VVariant^))) + ',' +
                       QuotedStr('dd/mm/yyyy') + ')';
     else
       Parm := '??????';
     end;
     RetVar := RetVar + ColNames[i] + '=' + Parm + ',';
  end;
  Delete(RetVar,length(RetVar),1);
  RetVar := RetVar + {CrLf}' ' + 'where ' + WhereClause;
  if High(Values) < High(ColNames) then
     ShowMessage('SQL Update - Not enough values.');
  if High(Values) > High(ColNames) then
     ShowMessage('SQL Update - Too many values.');
  Result := RetVar;
end;

function OrDataInsert(OrInsString: string;
                      KeyName : string;            //Имя ключа в Оракле
                      var OraKey: Integer): Integer;   //Значение возвращаемого ключа
//var                                               //Добавлено
//  F: TextFile;                                    //Добавлено
//  Res: Boolean;                                   //Добавлено
const
  MesTitle: PChar = 'Вставка записи SQL';
begin
//  AssignFile(F, 'D:\PostNew\BankFl\1.txt');       //Добавлено
//  {$I-} Append(F); {$I+}                          //Добавлено
//  Res := IOResult=0;                              //Добавлено
//  if Res then                                     //Добавлено
//  begin                                           //Добавлено
//    {$I-}WriteLn(F,OrInsString); {$I+}            //Добавлено
//    CloseFile(F);                                 //Добавлено
//  end;                                            //Добавлено
  Result := 0;
  if Length(KeyName)>0 then
    OrInsString := OrInsString+' returning '+KeyName+' into BankflKeyPackage.OraKey';
  with OraBase, OrQuery do
  begin
    //ParamByName('OraInsString').AsString := OrInsString; //Добавлено
    SQL.Clear;
    SQL.Add('begin');
    SQL.Add(OrInsString+';');
    SQL.Add('end;');
    //MessageBox(ParentWnd,Pchar(OrInsString),'1',mb_ok);
    try
      ExecSQL;
    except
      on E : Exception do
      begin
        OraExchangeForm.ShowProtoMes(plError, MesTitle,
        {MessageBox(ParentWnd, PChar(}'Исключение при добавлении записи:'#13#10
          +PChar(E.Message)+#13#10'['+OrInsString+']'{), MesTitle, mb_ok});
        Result := 1;
      end;
    end;
    if (Result=0) and (Length(KeyName)>0) then
    begin
      SQL.Clear;
      SQL.Add('Select BankflKeyPackage.returning from dual');
      try
        Open;
      except
      on E : Exception do
        begin
          OraExchangeForm.ShowProtoMes(plError, MesTitle,
          {MessageBox(ParentWnd, PChar(}'Исключение при чтении записи:'#13#10
          +PChar(E.Message)+#13#10'['+OrInsString+']'{), MesTitle, mb_ok});
          {MessageBox(ParentWnd,Pchar(E.Message), 'Ошибка чтения баз',mb_ok);
          Result := 1{E.HelpContext};
        end;
      end;
      if Result=0 then
        OraKey := Fields[0].AsInteger;
    end;
  end;
end;

var
  WorkTimeInSec: Integer = 0;

procedure TOraExchangeForm.WorkTimerTimer(Sender: TObject);
begin
  Inc(WorkTimeInSec);
  WorkTimerLabel.Caption := TimeToStr(WorkTimeInSec*0.0000115740740740740740740);
  if not WorkTimerLabel.Visible then
    WorkTimerLabel.Visible := True;
end;

procedure TOraExchangeForm.OpenSpeedButtonClick(Sender: TObject);
var
  ResCode: DWord;
begin
  RunAndWait('notepad.exe '+RedSaldoFN, SW_SHOW, ResCode);
end;

procedure TOraExchangeForm.ComisCheckBoxClick(Sender: TObject);
begin
  ComisChecked := ComisCheckBox.Checked;
end;

end.

