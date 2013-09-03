unit QrmExchangeFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Grids, Db, DBTables, DBGrids, ExtCtrls, DBCtrls, Menus,
  StdCtrls, Buttons, ComCtrls, Common, SearchFrm, Basbn, Utilits,
  BtrDS, BankCnBn, Registr, CommCons, Quorum, Btrieve, Mask,
  ToolEdit, {Sign, }BUtilits, DocFunc;

type
  TQrmExchangeForm = class(TForm)
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
  private
    PaydocDBGrid: TDBGrid;
    procedure WMSysCommand(var Message:TMessage); message WM_SYSCOMMAND;
  protected
    procedure SetBtnFocus;
  public
    procedure ShowProtoMes(Level: Byte; C: PChar; S: string);
  end;

const
  QrmExchangeForm: TQrmExchangeForm = nil;

  ID_MODULINFO = WM_USER+153;

var
  ObjList: TList;
  CurrPosDate, CurrDate: TDate;

implementation

{$R *.DFM}

var
  Process: Boolean = False;
  TransactionExecuted: Boolean = False;

procedure TQrmExchangeForm.ShowProtoMes(Level: Byte; C: PChar; S: string);
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

procedure TQrmExchangeForm.WMSysCommand(var Message:TMessage);
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

procedure TQrmExchangeForm.FormCreate(Sender: TObject);
const
  Border=2;
var
  SysMenu: THandle;
  C: TComponent;
  I: Integer;
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

procedure TQrmExchangeForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
end;

procedure TQrmExchangeForm.FormDestroy(Sender: TObject);
begin
  QrmExchangeForm := nil;
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

procedure TQrmExchangeForm.ProccessBtnClick(Sender: TObject);
const
  MesTitle: PChar = 'Экспорт';
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
  var
    Len, Res: Integer;
  begin
    with QrmBases[qbCashSym] do
    begin
      Len := FileRec.frRecordFixed;
      Res := BtrBase.GetEqual(Buffer^, Len, Sym, 0);
      if Res=0 then
        Result := AsInteger[csFlag]
      else
        Result := 0;
    end;
  end;

  procedure DisperceSyms(Syms: string; DocCode: Integer;
    var RemSum, FullSum: Double; var B: Integer);
  const
    MesTitle: PChar = 'Расшифровка росписей';
  var
    Res, Len, I, K, E, C: Integer;
    S, S2: string;
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
              with QrmBases[qbCashOSD] do
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
              end;
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
  procedure DispercePas(Pasp: string; DocCode: Integer;
    var PasSer, PasNum,PasPlace, FIO: string; var B: Integer);
  const
    MesTitle: PChar = 'Расшифровка паспортных данных';
  var
    Len, I, J: Integer;
  begin
    I := 1;
    J := 0;
    Len := Length(Pasp);
    if (I<Len) and (Pasp[1]>='0') and (Pasp[1]<='9') then
      begin
      while (I<Len) and (Pasp[I]>='0') and (Pasp[I]<='9') do
        Inc(I);
      PasSer := Copy(Pasp,1,I-1);
      Inc(I);
      J := I;
      while (I<Len) and (Pasp[I]>='0') and (Pasp[I]<='9') do
        Inc(I);
      PasNum := Copy(Pasp,J,(I-J));
      Inc(I);
      PasPlace := Copy(Pasp,I,Len);
      if (Length(PasSer)<>4) then
        begin
        ShowProtoMes(plError,MesTitle,'Неверная серия ['+PasSer+'] паспорта');
        B := -1;
        end;
      if (Length(PasNum)<>6) then
        begin
        ShowProtoMes(plError,MesTitle,'Неверный номер ['+PasNum+'] паспорта');
        B := -1;
        end;
      if (Length(PasPlace)<=0) then
        begin
        ShowProtoMes(plError,MesTitle,'Не указано место и дата выдачи паспорта');
        B := -1;
        end;
      end
    else if (J<Len) then
      begin
      FIO := Copy(Pasp,1,Len);
      if (Length(FIO)<=0) then
        begin
        ShowProtoMes(plError,MesTitle,'Не указано ФИО вносителя');
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
    Len, Res: Integer;
    TypeCode: Word;
  begin
    if Length(Value)=0 then
      Result := True
    else begin
      Result := False;
      with QrmBases[qbDocsBySh] do
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
      end;
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
    Len, Res, I: Integer;
    V: string;
    Key: TDocShifrKey0;
  begin
    with QrmBases[qbDocsBySh] do
    begin
      for I := sdiPSD to sdiTypePlat do
      begin
        Len := FileRec.frRecordFixed;
        with Key do
        begin
          skOperation := Operation;
          skOperNum := OperNum;
          skTypeCode := I;
        end;
        Res := BtrBase.GetEqual(Buffer^, Len, Key, 0);
        if Res=0 then
          V := AsString[dsShifrValue]
        else
          V := '';
        V := TruncStr(V);                 //Добавлено Меркуловым
        case I of
          sdiPSD:
            Status := V;
          //Убрано Меркуловым
          {sdiKppPlat:
            DebitKpp := V;
          sdiKppPol:
            CreditKpp := V; }
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

  procedure BeginTransaction;
  var
    Res: Integer;
  begin
    if not TransactionExecuted then
    begin
      Res := BtrBeginTransaction;
      if Res=0 then
        TransactionExecuted := True
      else
        ShowProtoMes(plError, MesTitle, 'Не удалось начать транзакцию. BtrErr='
          +IntToStr(Res));
    end
    else
      ShowProtoMes(plError, MesTitle, 'Нельзя начать транзакцию - предыдущая не завершена');
  end;

  procedure EndTransaction;
  var
    Res: Integer;
  begin
    if TransactionExecuted then
    begin
      Res := BtrEndTransaction;
      if Res=0 then
        TransactionExecuted := False
      else
        ShowProtoMes(plError, MesTitle, 'Не удалось завершить транзакцию. BtrErr='
          +IntToStr(Res));
    end;
  end;

  procedure AbortTransaction;
  var
    Res: Integer;
  begin
    if TransactionExecuted then
    begin
      Res := BtrAbortTransaction;
      if Res=0 then
        TransactionExecuted := False
      else
        ShowProtoMes(plError, MesTitle, 'Не удалось откатить транзакцию. BtrErr='
          +IntToStr(Res));
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
  CurrDosPosDate: Integer;

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
  PayOrComKey: TPayOrComKey;
  BankCorrCode, BankUchCode, BankMFO, BankCorrAcc: ShortString;

  function AddDocInQuorum(var PayRec: TBankPayRec): Integer;
  var
    Key, Res, Len, E, I, J, C, UserCodeLocal, UserCodeLocal2, DosDocDate: Integer;
    CashType: Integer;                                       //Добавлено
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

    //Добавлено Меркуловым
    procedure AddPayDocInQuorum;
    begin
      if GetAccAndCurrByNewAcc(CreditRs, AccNum2, CurrCode2,
        UserCodeLocal2) or (Length(CreditRs)=0) then
      begin
        if Length(CreditRs)=0 then
        begin
          CurrCode2 := CurrCode;
          ShowProtoMes(plWarning, MesTitle, 'Документ '+DocInfo(PayRec)
            +' выгружается на внутрибанк без счета получателя');
        end;
        with QrmBases[qbMemOrder] do
        begin
          Len := FileRec.frRecordFixed;
          FillChar(Buffer^, Len, #0);
          RPad(AccNum, 10, ' ');
          RPad(AccNum2, 10, ' ');

          AsString[moDbAcc] := AccNum;
          AsString[moDbCurrCode] := CurrCode;

          AsString[moKrAcc]      := AccNum2;
          AsString[moKrCurrCode] := CurrCode2;

          AsString[moDocNum] := Number;

          AsFloat[moPaySum] := 0.01*PayRec.dbDoc.drSum;
          {AsFloat[moPayKrSum]  := double(subStr(Str,150,20))/100;}
          AsFloat[moPayNatSum] := AsFloat[moPaySum];

          if (FindOper or (QrmOperId=0))
            and (Length(BallanseAccMask)>0)
            and Masked(DebitRs, BallanseAccMask)
            and not Masked(CreditRs, BallanseAccMask) then
          begin
            UserCodeLocal := UserCodeLocal2;
            ShowProtoMes(plInfo, MesTitle, 'Выгрузка '+DocInfo(PayRec)
              +' на оператора по кредиту');
          end;
          AsInteger[moUserCode] := GetUserCode;

          {AsInteger[moBatchNum] := 0;}
          AsInteger[moPreStatus] := $FFFF;

          AsInteger[moDocDate] := DosDocDate;
          AsInteger[moPosDate] := CurrDosPosDate; {Дата позиционирования документа}
          AsInteger[moProcDate] := CurrDosPosDate; {Дата подтверждения документа}

          AsInteger[moOperCode] := DocType;
          Key := 0;

        end;
      end
      else
        ShowProtoMes(plWarning, MesTitle, 'Не найден счет кредита '+CreditRs
          +' в мем. ор. '+DocInfo(PayRec));
    end;


  begin
    Result := -1;
    OrderOperation := 0;
    DosDocDate := CurrDosPosDate; {BtrDateToDosDate(PayRec.dbDoc.drDate); }
    FillBik(CreditBik);
    FillBik(DebitBik);
    case DocType of
      01:
        begin
          if GetAccAndCurrByNewAcc(DebitRs, AccNum, CurrCode, UserCodeLocal) then
          begin
            with QrmBases[qbPayOrder] do
            begin
              Len := FileRec.frRecordFixed;
              FillChar(Buffer^, Len, #0);

              RPad(AccNum, 10, ' ');

              AsString[poPayAcc] := AccNum;
              AsString[poCurrCodePay] := CurrCode;

              AsString[poCurrCodeCorr] := CurrCode;
              AsString[poDocNum] := Number;

              Sum := 0.01*PayRec.dbDoc.drSum;
              CorrAcc := GetTransAccNum(StrToInt(CreditBik),
                Copy(CreditRs, 1, 3), Sum);
              AsString[poCorrAcc] := CorrAcc;

              AsString[poSenderBankNum] := DebitBik;
              if GetBankByRekvisit(DebitBik, False,
                BankCorrCode, BankUchCode, BankMFO, BankCorrAcc) then
              begin
                AsString[poSenderCorrCode] := BankCorrCode;
                AsString[poSenderUchCode] := BankUchCode;
                AsString[poSenderMFO] := BankMFO;
              end
              else
                ShowProtoMes(plWarning, MesTitle, 'Не нашли реквизиты банка плат-ка по БИКу '+
                  DebitBik+' в плат. пор. '+DocInfo(PayRec));

              AsString[poSenderCorrAcc] := GetSenderCorrAcc(CurrCode, CorrAcc);

              AsString[poReceiverBankNum] := CreditBik;
              if GetBankByRekvisit(CreditBik, False, BankCorrCode,
                BankUchCode, BankMFO, BankCorrAcc) then
              begin
                AsString[poReceiverCorrCode] := BankCorrCode;
                AsString[poReceiverUchCode]  := BankUchCode;
                AsString[poReceiverMFO]      := BankMFO;
                AsString[poReceiverCorrAcc]  := BankCorrAcc;   {??}
              end
              else
                ShowProtoMes(plWarning, MesTitle, 'Не нашли реквизиты банка получателя по БИКу '+
                  CreditBik+' в плат. пор. '+DocInfo(PayRec));
              AsString[poDocType] := #$8A;   {досовская 'К'}
              {AsInteger[poSendType] := PayRec.dbDoc.drIsp;}
              AsInteger[poUserCode] := GetUserCode;
              if Copy(DebitBik, 1, 4) <> Copy(CreditBik, 1, 4) then
                AsInteger[poBatchType] := 1;
              AsInteger[poBatchNum] := 0;
              AsFloat[poPaySum] := Sum;
              AsInteger[poPreStatus] := $FFFF;
              {AsInteger[poOrderType] := 0;}

              AsInteger[poDocDate] := DosDocDate;
              AsInteger[poPosDate] := CurrDosPosDate; {Дата позиционирования документа}
              AsInteger[poProcDate] := CurrDosPosDate; {Дата подтверждения документа}
              AsInteger[poValueDate] := CurrDosPosDate; {Дата валютирования документа}
              AsInteger[poInDate] := CurrDosPosDate;

              ClearInn(CreditInn);
              ClearInn(DebitInn);

              AsInteger[poPriority] := PayRec.dbDoc.drOcher;
              AsInteger[poOperCode] := DocType;
              AsString[poBenefTaxNum] := CreditInn;
              AsString[poBenefAcc] := CreditRs;
              AsString[poBenefName] := CreditName;
              AsString[poInnOur] := DebitInn;
              AsString[poClientNameOur] := DebitName;
              //Добавлено Меркуловым
              AsString[poKppOur] := DebitKpp;
              AsString[poBenefKpp] := CreditKpp;
              Key := 0;

              BeginTransaction;
              if TransactionExecuted then
              begin
                Res := BtrBase.Insert(Buffer^, Len, Key, 0);
                if Res=0 then
                  Result := Key
                else begin
                  AbortTransaction;
                  ShowProtoMes(plError, MesTitle, 'Не удалось добавить плат. пор. '+DocInfo(PayRec)
                    +' BtrErr='+IntToStr(Res));
                end;
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
        //  MessageBox(ParentWnd,PChar('['+Pasp+']'),'Test!',MB_OK);                //Отладка
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
              DispercePas(Pasp, 0, PasSer, PasNum, PasPlace, FIO, C);                                  //добавлено
              if C>0 then
              begin
                if GetAccAndCurrByNewAcc(DebitRs, AccNum, CurrCode, UserCodeLocal) then
                begin
                  if GetAccAndCurrByNewAcc(CreditRs, AccNum2, CurrCode2, UserCodeLocal2) then
                  begin
                    with QrmBases[qbCashOrder] do
                    begin
                      Len := FileRec.frRecordFixed;
                      FillChar(Buffer^, Len, #0);
                      RPad(AccNum, 10, ' ');
                      RPad(AccNum2, 10, ' ');

                      AsInteger[coNotPay] := 1;
                      Sum := 0.01*PayRec.dbDoc.drSum;
                      if C=17 then
                      begin
                        AsString[coDocType] := #$8F; {досовская 'П'}
                        AsFloat[coSumma_rec] := Sum;
                        AsString[coCurrCode] := CurrCode2;
                        AsString[coAccount] := AccNum2;
                        AsString[coCashCurrCode] := CurrCode;
                        AsString[coCashAcc] := AccNum;
                        AsString[coFIO] := FIO;                 //Добавлено
                        UserCodeLocal := UserCodeLocal2;
                      end
                      else begin
                        AsString[coDocType] := #$90; {досовская 'Р'}
                        AsFloat[coSumma_exp] := Sum;
                        AsString[coCurrCode] := CurrCode;
                        AsString[coAccount] := AccNum;
                        AsString[coCashCurrCode] := CurrCode2;
                        AsString[coCashAcc] := AccNum2;
                        AsString[coSerPasp] := PasSer;          //Добавлено
                        AsString[coNumPasp] := PasNum;          //Добавлено
                        AsString[coPasp] := 'Ї бЇ®ав';          //Добавлено
                        CashType := C;                          //Добавлено
                      end;
                      AsFloat[coRemSum] := {PayRec.dbDoc.drSum/100}0;
                      AsString[coDocNum] := Number;
                      AsInteger[coDocDate] := DosDocDate;
                      AsInteger[coUserCode] := GetUserCode;
                      AsInteger[coNewUserCode] := AsInteger[coUserCode];
                      AsInteger[coPreStatus] := $FFFF;
                      AsInteger[coOperCode] := DocType;
                      Key := 0;
                      BeginTransaction;
                      if TransactionExecuted then
                      begin
                        Res := BtrBase.Insert(Buffer^, Len, Key, 0);
                        if Res=0 then
                        begin
                          DisperceSyms(Syms, Key, RemSum, FullSum, C);
                          if C<0 then
                            AbortTransaction
                          else
                            Result := Key
                        end
                        else begin
                          AbortTransaction;
                          ShowProtoMes(plError, MesTitle, 'Не удалось добавить запись. Ошибка Btrieve N'
                            +IntToStr(Res)+', кас. ор. '+DocInfo(PayRec));
                        end;
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
          if GetAccAndCurrByNewAcc(DebitRs, AccNum, CurrCode, UserCodeLocal) then
          begin
            if GetAccAndCurrByNewAcc(CreditRs, AccNum2, CurrCode2,
              UserCodeLocal2) or (Length(CreditRs)=0)
              {and (MessageBox(Handle, PChar(
              'Не указан счет получателя в документе'#13#10
              +DocInfo(PayRec)+#13#10'Выгрузить этот документ?'), MesTitle,
              MB_YESNOCANCEL or MB_ICONQUESTION)=ID_YES)} then
            begin
              if Length(CreditRs)=0 then
              begin
                CurrCode2 := CurrCode;
                ShowProtoMes(plWarning, MesTitle, 'Документ '+DocInfo(PayRec)
                  +' выгружается на внутрибанк без счета получателя');
              end;
              with QrmBases[qbMemOrder] do
              begin
                Len := FileRec.frRecordFixed;
                FillChar(Buffer^, Len, #0);
                RPad(AccNum, 10, ' ');
                RPad(AccNum2, 10, ' ');

                AsString[moDbAcc] := AccNum;
                AsString[moDbCurrCode] := CurrCode;

                AsString[moKrAcc]      := AccNum2;
                AsString[moKrCurrCode] := CurrCode2;

                AsString[moDocNum] := Number;

                AsFloat[moPaySum] := 0.01*PayRec.dbDoc.drSum;
                {AsFloat[moPayKrSum]  := double(subStr(Str,150,20))/100;}
                AsFloat[moPayNatSum] := AsFloat[moPaySum];

                if (FindOper or (QrmOperId=0))
                  and (Length(BallanseAccMask)>0)
                  and Masked(DebitRs, BallanseAccMask)
                  and not Masked(CreditRs, BallanseAccMask) then
                begin
                  UserCodeLocal := UserCodeLocal2;
                  ShowProtoMes(plInfo, MesTitle, 'Выгрузка '+DocInfo(PayRec)
                    +' на оператора по кредиту');
                end;
                AsInteger[moUserCode] := GetUserCode;

                {AsInteger[moBatchNum] := 0;}
                AsInteger[moPreStatus] := $FFFF;

                AsInteger[moDocDate] := DosDocDate;
                AsInteger[moPosDate] := CurrDosPosDate; {Дата позиционирования документа}
                AsInteger[moProcDate] := CurrDosPosDate; {Дата подтверждения документа}

                //Добавлено-изменено Меркуловым
                if (PayRec.dbDateR=0) and (PayRec.dbTimeR=0) then
                  AsInteger[moOperCode] := DocType
                else
                  AsInteger[moOperCode] := 01;
                Key := 0;

                BeginTransaction;
                if TransactionExecuted then
                begin
                  Res := BtrBase.Insert(Buffer^, Len, Key, 0);
                  if Res=0 then
                    Result := Key
                  else begin
                    AbortTransaction;
                    ShowProtoMes(plError, MesTitle, 'Не удалось добавить мем. ор. '
                      +DocInfo(PayRec)+' BtrErr='+IntToStr(Res));
                  end;
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
      else
        Result := -1;
    end;
    if (Result>0) and TransactionExecuted then
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
          AbortTransaction;
          ShowProtoMes(plError, MesTitle, 'Не удалось добавить налоговый код '
            +IntToStr(Result)+'. документ '+DocInfo(PayRec));
          Result := -1;
        end;
      end;
      if (Result>0) and TransactionExecuted then
      begin
        with QrmBases[qbPayOrCom] do
        begin
          Len := FileRec.frRecordFixed;
          FillChar(Buffer^, Len, #0);

          AsInteger[pcOperNum] := Key;
          AsInteger[pcStatus] := Res;
          if (CleanFieldsEx=1) or (CleanFieldsEx=3) then
            Purpose := DelCR(Purpose);
          if (CleanFieldsEx=2) or (CleanFieldsEx=3) then
            Purpose := RemoveDoubleSpaces(Purpose);
          Purpose := Trim(Purpose);

          AsString[pcComment]  := Purpose;
          AsInteger[pcComOwner] := OrderOperation;
          with PayOrComKey do
            begin
            pkOperNum := Key;
            pkStatus := Res;
            end;
          Res := BtrBase.Insert(Buffer^, Len, PayOrComKey, 0);
        end;
        if Res=0 then
          Result := Key
        else
          begin
          Result := -1;
          AbortTransaction;
          ShowProtoMes(plError, MesTitle, 'Не удалось добавить "назначение платежа". BtrErr='
            +IntToStr(Res)+', документ '+DocInfo(PayRec));
          end;
      end;
      //Добавлено Меркуловым
      if (Result>0) and TransactionExecuted then
        begin
        if (Res=0) and (DocType=03) and (CashType<>17) then
          begin
          with QrmBases[qbPayOrCom] do
            begin
            Len := FileRec.frRecordFixed;
            FillChar(Buffer^, Len, #0);
            AsInteger[pcOperNum] := Key;
            AsInteger[pcStatus] := 6;
            AsString[pcComment]  := PasPlace;
            AsInteger[pcComOwner] := OrderOperation;
            with PayOrComKey do
              begin
              pkOperNum := Key;
              pkStatus := Res;
              end;
            Res := BtrBase.Insert(Buffer^, Len, PayOrComKey, 0);
            end;
          end;

        if Res=0 then
          begin
            EndTransaction;
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
            AbortTransaction;
            ShowProtoMes(plError, MesTitle, 'Не удалось добавить место и дату выдачи паспорта. BtrErr='
            +IntToStr(Res)+', документ '+DocInfo(PayRec));
            end;
          end;
        end;
      end;
      AbortTransaction;
  end;

var
  PAcc, PKs, PCode, PInn, RAcc, RKs, RCode, RInn, PClient, RClient,
    PBank, RBank: string;
  DocSum: Double;
  ReceiverNode: Integer;
  T: array[0..1023] of Char;

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

procedure AddDocInBankCl(var DocNum, CorrRes: Integer; var PayRec: TBankPayRec);
const
  MesTitle: PChar = 'Добавление записи';
var
  Len, Err, Key: Integer;
begin
  CorrRes := 0;
  FillChar(PayRec, SizeOf(PayRec), #0);
  with PayRec do
  begin
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

const
  RetSignDate = -1;  {условная ДОС-дата характеризующая возврат по картотеке}

var
  DocCode, Len, Len1, ProDate, ProDate1: Integer;
  Res1, Res, I, C, J, DocNum, BillNum, OperNum: Integer;
  S, Sum: string;
  ExportRec: TExportRec;
  ImportRec: TImportRec;
  ProKey, ProKey1: TProKey;

  //Добавлено Меркуловым
  CashKey: TCashKey;

  SS1, SS2: ShortString;
  Year, Month, Day, BtrProDate, Operation: Word;
  ExpKey: TExpKey;
  ImpKey: TImpKey;
  OpRec: TOpRec;
  ClientInn, ClientName, ClientNewAcc: ShortString;
  DC, DC1, DC2, DC3, SelCount, LoopCount, CurIndex, CorrRes: Integer;

  //Добавлено Меркуловым
  PasPlc, PasSer, PasNum, FIO, DcType: string;

  W: Word;
  DocStatus: Word;
  PayRec: TBankPayRec;
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
    begin
      Process := QrmBasesIsOpen;
      if Process then
      begin
        if ExportCheckBox.Checked then
        begin
          DecodeDate(CurrPosDate, YearP, MonthP, DayP);
          ShowProtoMes(plInfo, MesTitle, '===Экспорт===');
          if (UpdDate1=0) or (LastCloseDate=0)
            or (LastCloseDate>=UpdDate1) or SelectedCheckBox.Checked then
          begin
            Len := SizeOf(PayRec);
            Res1 := PayDataSet.BtrBase.GetLast(PayRec, Len, I, 2);
            if Res1=0 then
            begin
              ProgressBar.Min := 0;
              ProgressBar.Position := ProgressBar.Min;
              ProgressBar.Max := PayRec.dbIdHere;
              Len := SizeOf(PayRec);
              Res1 := PayDataSet.BtrBase.GetFirst(PayRec, Len, I, 2);
            end;
            if Res1=0 then
            begin
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
              while (Res1=0) and Process and not TransactionExecuted do
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
                    I := PayRec.dbIdHere;
                    Res := ExportDataSet.BtrBase.GetEqual(ExportRec, Len1, I, 0);
                    if Res=0 then
                    begin
                      if Abs(DocumentIsExistInQuorum(ExportRec.erOperation,
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
                          +' уже присутствует в Кворуме')
                    end;
                    if Res<>0 then
                    begin
                      DecodeDocVar(PayRec.dbDoc, PayRec.dbDocVarLen, Number, DebitRs, DebitKs,
                        DebitBik, DebitInn, DebitName, DebitBank, CreditRs,
                        CreditKs, CreditBik, CreditInn, CreditName, CreditBank,
                        Purpose, DebitKpp, CreditKpp, Status, Kbk, Okato, OsnPl, Period, NDoc,
                        NDocDate, TipPl, Nchpl, Shifr, Nplat, OstSum,
                        CheckCharModeEx, CleanFieldsEx, CorrRes, True);
                      if (PayRec.dbIdSender<>0)
                        and (IsBankClAcc(DebitRs, 0, asLockCl)<0)
                      then
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
                          if PayOrInBank and (DocType=1) and (Len1=BankBikInt)
                            and (PayRec.dbDoc.drOcher=6) then
                          begin
                            DocType := 9;
                            {ShowProtoMes(plInfo, MesTitle, 'Документ с ВО=1 '+DocInfo(PayRec)+' выгружается на внутрибанк')}
                          end;
                          DocCode := AddDocInQuorum(PayRec);
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
                              Res := PayDataSet.BtrBase.Update(PayRec, Len, I, 2);
                              if Res<>0 then
                                ShowProtoMes(plError, MesTitle,
                                  'Не удалось установить пометку "экспорт" документа '
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
                  Res1 := PayDataSet.BtrBase.GetNext(PayRec, Len, I, 2);
                end;
                Application.ProcessMessages;
              end;
              if TransactionExecuted then
              begin
                ShowProtoMes(plWarning, MesTitle, 'Транзакция не была завершена');
                AbortTransaction;
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
        if ImportCheckBox.Checked then
        begin
          DecodeDate(CurrDate, YearL, MonthL, DayL);
          ProDate := EncodeDosDate(YearL, MonthL, DayL);
          ShowProtoMes(plInfo, MesTitle, '===Импорт===');
          if LookDeletedCheckBox.Checked then  { проверим удаленные }
          begin
            DecodeDate(EncodeDate(YearL, MonthL, DayL) + 1.0,
              Year, Month, Day);
            ProDate1 := EncodeDosDate(Year, Month, Day);
            with ProKey1 do
            begin
              pkProDate := ProDate1;
              pkProCode := 0;
            end;
            with QrmBases[qbDelPro] do
            begin
              Len := FileRec.frRecordFixed;
              Res := BtrBase.GetLT(Buffer^, Len, ProKey1, 0);
              if Res=0 then
              begin
                DecodeDate(EncodeDate(YearL, MonthL, DayL) - LookDeletedDays + 1,
                  Year, Month, Day);
                ProDate1 := EncodeDosDate(Year, Month, Day);
                ShowProtoMes(plInfo, MesTitle, '---Просмотр удаленных проводок за '
                  +IntToStr(LookDeletedDays)+' дней (с '
                  +DosDateToStr(ProDate1)+' по '+DosDateToStr(ProDate)+')---');
                with ProKey do
                begin
                  pkProDate := ProDate1;
                  pkProCode := 0;
                end;
                Len := FileRec.frRecordFixed;
                Res := BtrBase.GetGE(Buffer^, Len, ProKey, 0);
                if Res=0 then
                begin
                  ProDate1 := 0;
                  ProgressBar.Min := 0;
                  ProgressBar.Position := ProgressBar.Min;
                  ProgressBar.Max := LookDeletedDays;
                  ProgressBar.Show;
                  {ShowProtoMes(plError, MesTitle, '1:'+IntToStr(ProgressBar.Min)+','+
                    IntToStr(ProgressBar.Max)+' - '+IntToStr(ProgressBar.Position)+' cc '
                    +IntToStr(AsInteger[dpProCode]));}
                  {BtrProDate := CodeBtrDate(YearL, MonthL, DayL);}
                  C := 0;
                  while (Res=0) and (AsInteger[dpProDate]<=ProDate)
                    and Process and not TransactionExecuted do
                  begin
                    if ProDate1 <> AsInteger[dpProDate] then
                    begin
                      ProDate1 := AsInteger[dpProDate];
                      ProgressBar.Position := ProgressBar.Position+1;
                      Application.ProcessMessages;
                    end;
                    ImpKey.pkProCode := ProKey.pkProCode;
                    ImpKey.pkProDate := ProKey.pkProDate;
                    Len := SizeOf(ImportRec);
                    Res := ImportDataSet.BtrBase.GetEqual(ImportRec, Len,
                      ImpKey, 2);
                    if Res=0 then
                    begin   {да, была выгружена из К в БК - надо удалять}
                      Len := SizeOf(OpRec);
                      I := ImportRec.irIderB;
                      Res := BillDataSet.BtrBase.GetEqual(OpRec, Len, I, 0);
                      if Res=0 then
                      begin
                        BeginTransaction;
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
                              {DeleteOp(OpRec, PayRec.dbIdSender)}
                              if CorrectOpSum(brAccD, brAccC, Round(brSum), 0,
                                brDate, PayRec.dbIdSender, W) then
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
                            EndTransaction;
                            Inc(C)
                          end
                          else
                            ShowProtoMes(plError, MesTitle, 'Не удалось убрать пометку о удаленной проводке '
                              +OpInfo(OpRec)+' BtrErr='+IntToStr(Res));
                        end;
                      end
                      else
                        ShowProtoMes(plWarning, MesTitle, 'Загруженная ранее проводка не найдена Id='
                          +IntToStr(ImportRec.irIderB));
                    end;
                    Len := FileRec.frRecordFixed;
                    Res := BtrBase.GetNext(Buffer^, Len, ProKey, 0);
                  end;
                  if TransactionExecuted then
                  begin
                    AbortTransaction;
                    ShowProtoMes(plWarning, MesTitle, 'Транзакция не была завершена');
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
                while (Res=0) and Process and not TransactionExecuted do
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
                    J := GetChildOperNumByKvitan(ExportRec.erOperation,
                      ExportRec.erOperNum, coVbKartotOperation);
                    if (C3>0) and (J>0) or (C3<0) and (J=0) then
                    begin
                      if J>0 then
                      begin
                        {ShowProtoMes(plError, MesTitle, 'Найдена картотечная операция...');}
                        with QrmBases[qbVbKartOt] do
                        begin
                          Len := FileRec.frRecordFixed;
                          Res1 := BtrBase.GetEqual(Buffer^, Len, J, 0);
                          if Res1=0 then

                          begin
                            {ShowProtoMes(plError, MesTitle, 'Найден в картотеке...');}
                            Inc(C);
                            J := ExportRec.erIderB;
                            Len := SizeOf(PayRec);
                            Res1 := PayDataSet.BtrBase.GetEqual(PayRec, Len, J, 2);
                            if Res1=0 then
                            begin
                              if MakeKart(PayRec.dbIdHere, 'Поставлен в картотеку',
                                DateToBtrDate(Date), OpRec) then
                              begin
                                Inc(C1);
                                J := OpRec.brIder;
                                with ImportRec do
                                begin
                                  irIderB := J;
                                  irOperNum := AsInteger[vkOperNum];
                                  irOperation := coVbKartotOperation;
                                  irProCode := J;
                                  irProDate := RetSignDate;
                                end;
                                Len := SizeOf(ImportRec);
                                Res1 := ImportDataSet.BtrBase.Insert(ImportRec, Len, I, 0);
                                if Res1<>0 then
                                  ShowProtoMes(plError, MesTitle, 'Не удалось поставить пометку о возврате '
                                    +OpInfo(OpRec)+' BtrErr='+IntToStr(Res1));
                              end
                              else begin
                                S := 'Документ '+DocInfo(PayRec)+' в картотеке '
                                  +Trim(AsString[vkKartNum])+' - ';
                                ShowProtoMes(plError, MesTitle, S + 'не удалось создать возврат '
                                  +OpInfo(OpRec));
                              end;
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
                              end
                            end
                            else
                              ShowProtoMes(plWarning, MesTitle, 'Возврат '+OpInfo(OpRec)+
                                ' не найден BtrErr='+IntToStr(Res1));
                            if Res1=0 then
                            begin
                              Res1 := ImportDataSet.BtrBase.Delete(2);
                              if Res1<>0 then
                                ShowProtoMes(plError, MesTitle, 'Не удалось убрать пометку о ранее созданом возврате '+OpInfo(OpRec)
                                  +' BtrErr='+IntToStr(Res1));
                            end;
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
                if TransactionExecuted then
                begin
                  AbortTransaction;
                  ShowProtoMes(plWarning, MesTitle, 'Транзакция не была завершена');
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
          if BtrProDate>UpdDate1 then
          begin
            if BtrProDate>LastCloseDate then
            begin
              with QrmBases[qbPro] do
              begin
                DecodeDate(EncodeDate(YearL, MonthL, DayL) + 1.0,
                  Year, Month, Day);
                ProDate1 := EncodeDosDate(Year, Month, Day);
                with ProKey1 do
                begin
                  pkProDate := ProDate1;
                  pkProCode := 0;
                end;
                Len := FileRec.frRecordFixed;
                Res := BtrBase.GetLT(Buffer^, Len, ProKey1, 0);
                if Res=0 then
                begin
                  ProgressBar.Min := 0;
                  ProgressBar.Position := ProgressBar.Min;
                  ProgressBar.Max := AsInteger[prProCode];
                  with ProKey do
                  begin
                    pkProDate := ProDate;
                    pkProCode := 0;
                  end;
                  Len := FileRec.frRecordFixed;
                  Res := BtrBase.GetGE(Buffer^, Len, ProKey, 0);
                  if Res=0 then
                  begin
                    C := 0;
                    C1 := 0; C2 := 0; C3 := 0;
                    DC := 0;
                    DC1 := 0; DC2 := 0; DC3 := 0;
                    IOutbankCountLabel.Caption := '0';
                    IInbankCountLabel.Caption := '0';
                    ICashCountLabel.Caption := '0';

                    ProgressBar.Min := AsInteger[prProCode];
                    ProgressBar.Position := ProgressBar.Min;
                    ProgressBar.Show;
                    while (Res=0) and (AsInteger[prProDate]=ProDate)
                      and Process and not TransactionExecuted do
                    begin
                      if GetNewAccByAccAndCurr(AsString[prDbAcc],
                        AsString[prDbCurrCode], SS1)
                        and GetNewAccByAccAndCurr(AsString[prKrAcc],
                        AsString[prKrCurrCode], SS2) then
                      begin
                        Operation := AsInteger[prOperation];
                        OperNum := AsInteger[prOperNum];

                        with ExpKey do
                        begin
                          ekOperNum := OperNum;
                          ekOperation := Operation;
                        end;
                        Len := SizeOf(ExportRec);
                        Res := ExportDataSet.BtrBase.GetEqual(ExportRec, Len,
                          ExpKey, 1);
                        if Res<>0 then
                        begin
                          ExportRec.erIderB := 0;
                          if Operation=coPayOrderOperation then
                          begin  {это межбанк - проверим родителей документа по цепочке вверх}
                            I := OperNum;
                            while (I>0) and (ExportRec.erIderB=0) do
                            begin  {есть родитель и он не из БК}
                              J := I;
                              I := GetParentOperNumByKvitan(Operation, J, Operation);
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

                        I := -1;
                        Res := IsBankClAcc(SS1, BtrProDate, 0);
                        if Res>I then
                          I := Res;
                        Res := IsBankClAcc(SS2, BtrProDate, 0);
                        if Res>I then
                          I := Res;

                        if (ExportRec.erIderB<>0) or (I>0) then
                        begin    {один из счетов присутствует в БК и активен}
                          BillNum := 0;
                          DocNum := 0;
                          PayRec.dbIdSender := 0;

                          ImpKey.pkProCode := ProKey.pkProCode;  {загружалась ли проводка}
                          ImpKey.pkProDate := ProKey.pkProDate;
                          Len := SizeOf(ImportRec);
                          Res := ImportDataSet.BtrBase.GetEqual(ImportRec, Len,
                            ImpKey, 2);
                          if Res=0 then
                          begin          {проводка ранее загружалась}
                            Len := SizeOf(OpRec);
                            I := ImportRec.irIderB;     {найдем активную}
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
                            begin        {она существует и активна}
                              BillNum := I;
                              Len := SizeOf(PayRec);
                              I := OpRec.brDocId;
                              DocNum := I;
                              Res1 := PayDataSet.BtrBase.GetEqual(PayRec, Len,
                                I, 0);
                              if Res1=4 then
                              begin   {но документа уже нет}
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
                                  +IntToStr(ProKey.pkProCode))
                              else begin
                                BillNum := $FFFF;
                                DocNum := $FFFF;
                                ShowProtoMes(plError, MesTitle, 'Не могу удалить пометку о проводке ProCode='
                                  +IntToStr(ProKey.pkProCode)+' для повторной загрузки');
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
                                +IntToStr(ProKey.pkProCode));
                            end;

                          if (DocNum=0) and ((Operation<>coCashOrderOperation)
                            or (AsInteger[prCash]<>0)) then
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

                          if (DocNum<=0) or (BillNum<=0) then
                          begin
                            DocSum := AsFloat[prSumPro]*100.0;
                            Number := AsString[prDocNum];
                            DocDate := DosDateToBtrDate(AsInteger[prDocDate]);

                            if AsInteger[prCash]=0 then
                              DocType := AsInteger[prOperCode]
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
                            begin
                              if Operation=coPayOrderOperation then
                                J := OperNum
                              else
                                J := GetChildOperNumByKvitan(Operation, OperNum,
                                  coPayOrderOperation);
                              if J>0 then
                              begin
                                with QrmBases[qbPayOrder] do
                                begin
                                  Len := FileRec.frRecordFixed;
                                  Res := BtrBase.GetEqual(Buffer^, Len, J, 0);
                                  if Res=0 then
                                  begin
                                    DocOcher := AsInteger[poPriority];
                                    if AsString[poDocType]=#$8A then  {досовская 'К'}
                                    begin
                                      //Добавлено Меркуловым
                                      if (DocType = 1) then          //Если пл.поручение и клиент по дебиту, то метка для
                                        ClientInn := 'incoming';     //замены плательщика в функции GetClientByAcc()
                                      //Конец
                                      if GetClientByAcc(QrmBases[qbPro].AsString[prDbAcc],
                                        QrmBases[qbPro].AsString[prDbCurrCode],
                                        ClientInn, ClientName, ClientNewAcc) then
                                      begin
                                        PInn := ClientInn;
                                        PClient := ClientName;
                                        PAcc := ClientNewAcc;
                                        PCode := BankBik;
                                      end
                                      else
                                        ShowProtoMes(plWarning, MesTitle, 'Межбанк. Клиент не найден по счету дебета '
                                          +QrmBases[qbPro].AsString[prDbAcc]);
                                      RInn := AsString[poBenefTaxNum];
                                      RClient := AsString[poBenefName];
                                      RAcc := AsString[poBenefAcc];
                                      RCode := AsString[poReceiverBankNum];
                                      //Добавлено Меркуловым
                                      DebitKpp := AsString[poKppOur];
                                      CreditKpp := AsString[poBenefKpp];

                                    end
                                    else begin     {  "Д" }
                                      {if GetClientByAcc(QrmBases[qbPro].AsString[prKrAcc],
                                        QrmBases[qbPro].AsString[prKrCurrCode],
                                        ClientInn, ClientName, ClientNewAcc) then
                                      begin
                                        RInn := ClientInn;
                                        RClient := ClientName;
                                        RAcc := ClientNewAcc;
                                        RCode := BankBik;
                                      end
                                      else
                                        ShowProtoMes(plWarning, MesTitle, 'Межбанк. Клиент не найден по счету кредита '
                                          +QrmBases[qbPro].AsString[prKrAcc]);}
                                      {if (Operation=coRecognizeSumOperation)
                                        or (Operation=coVypOperation)
                                      then
                                        RAcc := SS2
                                      else
                                        RAcc := AsString[poClientAcc];}
                                      RAcc := SS2;
                                      RInn := AsString[poINNOur];
                                      RClient := AsString[poClientNameOur];
                                      RCode := BankBik;
                                      if (Length(RInn)=0) or (Length(RClient)=0) then
                                      begin
                                        if GetClientByAcc(QrmBases[qbPro].AsString[prKrAcc],
                                          QrmBases[qbPro].AsString[prKrCurrCode],
                                          ClientInn, ClientName, ClientNewAcc) then
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
                                            +QrmBases[qbPro].AsString[prKrAcc]);
                                        {if GetNewAccByAccAndCurr(
                                          QrmBases[qbPro].AsString[prKrAcc],
                                          QrmBases[qbPro].AsString[prKrCurrCode],
                                          ClientNewAcc)
                                        then
                                          RAcc := ClientNewAcc;}
                                      end;
                                      PInn := AsString[poBenefTaxNum];
                                      PClient := AsString[poBenefName];
                                      PAcc := AsString[poBenefAcc];
                                      PCode := AsString[poSenderBankNum];
                                      //Добавлено Меркуловым
                                      CreditKpp := AsString[poKppOur];
                                      DebitKpp := AsString[poBenefKpp];

                                    end;
                                  end
                                  else
                                    ShowProtoMes(plWarning, MesTitle,
                                      'Исходный документ не найден '
                                      +IntToStr(Operation)+'|'+IntToStr(OperNum)
                                      +' BtrErr='+IntToStr(Res));
                                end;
                                GetDocShifrs(Operation, OperNum, {DebitKpp,
                                  CreditKpp,} Status, Kbk, Okato, OsnPl, Period, //Изменено Меркуловым
                                  NDoc, NDocDate, TipPl);
                                {GetPayOrderShifrs(Nchpl, Shifr, Nplat, OstSum);  !!!}
                              end
                              else
                                ShowProtoMes(plWarning, MesTitle,
                                  'Ошибка поиска документа по квитанции '
                                    +IntToStr(Operation)+'|'+IntToStr(OperNum));
                            end
                            else begin
                              if GetClientByAcc(AsString[prDbAcc],
                                AsString[prDbCurrCode],
                                ClientInn, ClientName, ClientNewAcc) then
                              begin
                                PInn := ClientInn;
                                PClient := ClientName;
                                PAcc := ClientNewAcc;
                              end
                              else
                                ShowProtoMes(plWarning, MesTitle, 'Внутрибанк. Клиент не найден по счету дебита '
                                  +AsString[prDbAcc]);
                              if GetClientByAcc(AsString[prKrAcc],
                                AsString[prKrCurrCode],
                                ClientInn, ClientName, ClientNewAcc) then
                              begin
                                RInn := ClientInn;
                                RClient := ClientName;
                                RAcc := ClientNewAcc;
                              end
                              else
                                ShowProtoMes(plWarning, MesTitle, 'Внутрибанк. Клиент не найден по счету кредита '
                                  +AsString[prKrAcc]);
                              PCode := BankBik;
                              RCode := BankBik;
                            end;

                            if GetBankByRekvisit(PCode, True, BankCorrCode,
                              BankUchCode, BankMFO, BankCorrAcc) then
                            begin
                              PKs := BankCorrCode;
                              PBank := BankUchCode;
                            end;
                            if GetBankByRekvisit(RCode, True, BankCorrCode,
                              BankUchCode, BankMFO, BankCorrAcc) then
                            begin
                              RKs := BankCorrCode;
                              RBank := BankUchCode;
                            end;

                            ProKey1 := ProKey;
                            if AsInteger[prCash]=0 then
                            begin
                              with QrmBases[qbCommentADoc] do
                              begin
                                Len := FileRec.frRecordFixed;
                                Res := BtrBase.GetEqual(Buffer^, Len, ProKey1, 0);
                                if Res=0 then
                                  Purpose := AsString[caComment]
                                else
                                  ShowProtoMes(plWarning, MesTitle, 'Не найдено назначение платежа в CommentADoc, ProCode='
                                    +IntToStr(ProKey.pkProCode));
                              end;
                            end
                            else begin

                              //Добавлено Меркуловым
                              PasPlc := '';
                              PasNum := '';
                              PasSer := '';
                              FIO    := '';
                              CashKey.pcNumOp := OperNum;
                              Res1 := -1;
                              J := 0;
                              with QrmBases[qbCashOrder] do
                                begin
                                Len := FileRec.frRecordFixed;
                                Res := BtrBase.GetEqual(Buffer^, Len, CashKey.pcNumOp, 0);   //Может 1, 2
                                if Res=0 then
                                  begin
                                  DcType := AsString[coDocType];
                                  if(DcType=#$90) then
                                    begin
                                    PasSer := AsString[coSerPasp];
                                    PasNum := AsString[coNumPasp];
                                    end;
                                  if(DcType=#$8F) then
                                    FIO := AsString[coFIO];
                                  end
                                else
                                  ShowProtoMes(plWarning, MesTitle, 'Не найдены сведения паспорта в CashOrder, CashCode='
                                  +IntToStr(coOperNum));
                                end;
                              CashKey.pcStat := 4;
                              with QrmBases[qbPayOrCom] do
                                begin
                                Len := FileRec.frRecordFixed;
                                Res := BtrBase.GetEqual(Buffer^, Len, CashKey, 0);   //Может 1, 2
                                if (Res=0) and (Length(FIO)<=0) then
                                  FIO := AsString[pcComment];
                                end;
                              CashKey.pcStat := 2;
                              with QrmBases[qbPayOrCom] do
                                begin
                                Len := FileRec.frRecordFixed;
                                Res := BtrBase.GetEqual(Buffer^, Len, CashKey, 0);   //Может 1, 2
                                if Res=0 then
                                  begin
                                  Purpose := {GetCashNazn}(AsString[pcComment]);
                                  Len := Length(Purpose);
                                  while (J<Len) and (Purpose[J]<>'@') do
                                    Inc(J);
                                  if (J<Len) then
                                    PasPlc := Copy(Purpose,J+2,(Len-J+2));
                                  Purpose := Copy(Purpose,1,J);
                                  end
                                else
                                  begin
                                  ShowProtoMes(plWarning, MesTitle, 'Не найдено назначение платежа в PayOrCom, PCCode='
                                  +IntToStr(pcOperNum));
                                  Purpose := 'ЃҐ§ ­ §­ зҐ­Ёп';
                                  end;
                                end;
                              if (DcType=#$90) then
                                begin
                                CashKey.pcStat := 5;
                                with QrmBases[qbPayOrCom] do
                                  begin
                                  Len := FileRec.frRecordFixed;
                                  Res1 := BtrBase.GetEqual(Buffer^, Len, CashKey, 0);   //Может 1, 2
                                  if Res1=0 then
                                    begin
                                    PasPlc := AsString[pcComment];
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
                                    end;
                                  end;
                                end;
                              if (Res1<>0) and (DcType=#$90) then
                                begin
                                CashKey.pcStat := 6;
                                with QrmBases[qbPayOrCom] do
                                  begin
                                  Len := FileRec.frRecordFixed;
                                  Res := BtrBase.GetEqual(Buffer^, Len, CashKey, 0);   //Может 1, 2
                                  if Res=0 then
                                    PasPlc := AsString[pcComment]
                                  else
                                    ShowProtoMes(plWarning, MesTitle, 'Не найдено место и дата выдачи паспорта в PayOrCom, PCCode='
                                    +IntToStr(pcOperNum));
                                  end;
                                end;

                             { with QrmBases[qbCashComA] do
                              begin
                                Len := FileRec.frRecordFixed;
                                Res := BtrBase.GetEqual(Buffer^, Len, ProKey1, 1);
                                if Res=0 then
                                  Purpose := GetCashNazn(AsString[ccComment])
                                else
                                  ShowProtoMes(plWarning, MesTitle, 'Не найдено назначение платежа в CashComA, ProCode='
                                    +IntToStr(ProKey.pkProCode));
                              end; }

                          //    if Res=0 then
                          //    begin
                                S := '';
                                with QrmBases[qbCashsDA] do
                                begin
                                  Len := FileRec.frRecordFixed;
                                  Res := BtrBase.GetEqual(Buffer^, Len, ProKey1, 2);
                                  while (Res=0)
                                    and (AsInteger[cdProDate]=ProKey.pkProDate)
                                    and (AsInteger[cdProCode]=ProKey.pkProCode) do
                                  begin
                                    if Length(S)>0 then
                                      S := S + ';';                      //Изменено (убран пробел)
                                    Str(AsFloat[cdSumma]:0:2, Sum);
                                    S := S + AsString[cdSymbol] + '-' + Sum;
                                    Len := FileRec.frRecordFixed;
                                    Res := BtrBase.GetNext(Buffer^, Len, ProKey1, 2);
                                  end;
                                end;
                                Purpose := Purpose + #13#10 + S;
                  //              MessageBox(ParentWnd,PChar('Назначение['+Purpose+']'+#13#10+'['+PasPlc+']'),'Check!',MB_OK);    //Отладка
                                if DcType=#$90 then
                                  Purpose := Purpose + '~' + PasSer + ' ' + PasNum + ' ' + PasPlc;
                                if DcType=#$8F then
                                  Purpose := Purpose + '~' + FIO;
                          //    end;
                            end;

                            if DocNum<=0 then
                            begin     {надо записать документ}
                              AddDocInBankCl(DocNum, CorrRes, PayRec);
                              if DocNum=0 then
                                ShowProtoMes(plError, MesTitle, 'Не удалось загрузить документ '+
                                  DocInfo(PayRec)+', ProCode='+IntToStr(ProKey.pkProCode))
                              else begin
                                if CorrRes<>0 then
                                begin
                                  S := 'В новом документе '+DocInfo(PayRec)
                                    +' найдены недопустимые символы';
                                  if CheckCharModeEx>1 then
                                    S := S + '. Все они были исправлены';
                                  ShowProtoMes(plInfo, MesTitle, S);
                                end;
                                if AsInteger[prCash]=0 then
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
                            end;

                            if (BillNum<=0) and (DocNum>0) then
                            begin  {документ существует, загрузим проводку}
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
                                  brDate := DosDateToBtrDate(AsInteger[prProDate]);
                                  Inc(brVersion);
                                  brPrizn := brtBill;
                                  brType := DocType;
                                  brNumber := AsInteger[prDocNum];
                                  if Length(PAcc)=0 then
                                  begin
                                    if GetClientByAcc(
                                      AsString[prDbAcc], AsString[prDbCurrCode],
                                      ClientInn, ClientName, ClientNewAcc) then
                                    begin
                                      PInn := ClientInn;
                                      PClient := ClientName;
                                      PAcc := ClientNewAcc;
                                    end
                                    else
                                      ShowProtoMes(plWarning, MesTitle, 'К. Клиент не найден по счету дебита '
                                        +AsString[prDbAcc]);
                                  end;
                                  if Length(RAcc)=0 then
                                  begin
                                    if GetClientByAcc(
                                      AsString[prKrAcc], AsString[prKrCurrCode],
                                      ClientInn, ClientName, ClientNewAcc) then
                                    begin
                                      RInn := ClientInn;
                                      RClient := ClientName;
                                      RAcc := ClientNewAcc;
                                    end
                                    else
                                      ShowProtoMes(plWarning, MesTitle, 'К. Клиент не найден по счету кредита '
                                        +AsString[prKrAcc]);
                                  end;
                                  {StrTCopy(brAccD, PChar(PAcc), SizeOf(TAccount));
                                  StrTCopy(brAccC, PChar(RAcc), SizeOf(TAccount));}
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
                                  if I>SizeOf(brText)-1 then
                                    I := SizeOf(brText)-1;
                                  StrPLCopy(brText, Purpose, I);
                                  Len := StrLen(brText);
                                end;
                                Len := 17 + 53 + Len + 1;
                                I := BillNum;
                                BeginTransaction;
                                if CorrectOpSum(OpRec.brAccD, OpRec.brAccC,
                                  0, Round(OpRec.brSum), OpRec.brDate,
                                  PayRec.dbIdSender, W) then
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
                                      irProCode := AsInteger[prProCode];
                                      irProDate := AsInteger[prProDate];
                                    end;
                                    Len := SizeOf(ImportRec);
                                    Res := ImportDataSet.BtrBase.Insert(ImportRec, Len, I, 0);
                                    if Res=0 then
                                    begin
                                      EndTransaction;
                                      if AsInteger[prCash]=0 then
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
                                AbortTransaction;
                              end;
                            end;
                          end;
                        end;
                      end;
                      ProgressBar.Position := AsInteger[prProCode];
                      Application.ProcessMessages;
                      Len := FileRec.frRecordFixed;
                      Res := BtrBase.GetNext(Buffer^, Len, ProKey, 0);
                    end;
                    ShowProtoMes(plInfo, MesTitle, 'Загружено документов: '+IntToStr(DC1+DC2+DC3));
                    ShowProtoMes(plInfo, MesTitle, 'Загружено проводок: '+IntToStr(C1+C2+C3));
                    if TransactionExecuted then
                    begin
                      AbortTransaction;
                      ShowProtoMes(plWarning, MesTitle, 'Транзакция не была завершена');
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
      end
      else
        ShowProtoMes(plWarning, MesTitle, 'Не все базы Кворум открыты');
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

procedure TQrmExchangeForm.PosDateEditChange(Sender: TObject);
begin
  CurrPosDate := PosDateEdit.Date;
end;

procedure TQrmExchangeForm.DateEditChange(Sender: TObject);
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

procedure TQrmExchangeForm.EOutbankLabelClick(Sender: TObject);
begin
  ProccessBtn.Enabled := ExportCheckBox.Checked or ImportCheckBox.Checked;
end;

procedure TQrmExchangeForm.ExportCheckBoxClick(Sender: TObject);
begin
  PosDateEdit.Enabled := ExportCheckBox.Checked;
  SelectedCheckBox.Enabled := ExportCheckBox.Checked;
  ShowComponents(ExportGroupBox, ExportCheckBox.Checked);
  EOutbankLabelClick(nil);
end;

procedure TQrmExchangeForm.ImportCheckBoxClick(Sender: TObject);
begin
  DateEdit.Enabled := ImportCheckBox.Checked;
  LookDeletedCheckBox.Enabled := ImportCheckBox.Checked and (LookDeletedDays>0);
  LookKartotCheckBox.Enabled := ImportCheckBox.Checked;
  ShowComponents(ImportGroupBox, ImportCheckBox.Checked);
  EOutbankLabelClick(nil);
end;

procedure TQrmExchangeForm.FormShow(Sender: TObject);
begin
  ExportCheckBoxClick(nil);
  ImportCheckBoxClick(nil);
end;

procedure TQrmExchangeForm.SetBtnFocus;
begin
  Application.ProcessMessages;
  if ProccessBtn.Enabled then
    ProccessBtn.SetFocus
  else
    CancelBtn.SetFocus;
end;

procedure TQrmExchangeForm.FormKeyDown(Sender: TObject; var Key: Word;
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

procedure TQrmExchangeForm.ExportGroupBoxClick(Sender: TObject);
begin
  if not (ExportCheckBox.Checked and ImportCheckBox.Checked) then
    ExportCheckBox.Checked := not ExportCheckBox.Checked;
  ImportCheckBox.Checked := not ImportCheckBox.Checked;
  SetBtnFocus;
end;


end.
