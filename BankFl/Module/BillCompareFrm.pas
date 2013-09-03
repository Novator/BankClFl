unit BillCompareFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Grids, Db, DBTables, DBGrids, ExtCtrls, DBCtrls, Menus,
  StdCtrls, Buttons, ComCtrls, Common, Basbn, Utilits,
  BtrDS, BankCnBn, Registr, CommCons, {Quorum, }Btrieve,
  ToolEdit, {Sign, }BUtilits, Mask, RxMemDS,
  Orakle;                                 //Добавлено Меркуловым

type
  TBillCompareForm = class(TForm)
    StatusBar: TStatusBar;
    ProtoGroupBox: TGroupBox;
    ProtoMemo: TMemo;
    ProgressBar: TProgressBar;
    SetupPanel: TPanel;
    BtnPanel: TPanel;
    CancelBtn: TBitBtn;
    ProccessBtn: TBitBtn;
    StatGroupBox: TGroupBox;
    CheckLabel: TLabel;
    BillLabel: TLabel;
    ErrBillLabel: TLabel;
    ErrBillCountLabel: TLabel;
    CheckCountLabel: TLabel;
    BillCountLabel: TLabel;
    DateEdit: TDateEdit;
    CheckAccBox: TCheckBox;
    JustOpenBox: TCheckBox;
    DateLabel: TLabel;
    GridGroupBox: TGroupBox;
    MemDBGrid: TDBGrid;
    RxMemoryData: TRxMemoryData;
    MemDataSource: TDataSource;
    HorSplitter: TSplitter;
    RxMemoryDataAcc: TStringField;
    RxMemoryDataSum: TFloatField;
    RxMemoryDataIder: TIntegerField;
    RxMemoryDataSource: TStringField;
    OpenProtoSpeedButton: TSpeedButton;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure ProccessBtnClick(Sender: TObject);
    procedure DateEditAcceptDate(Sender: TObject; var ADate: TDateTime;
      var Action: Boolean);
    procedure DateEditExit(Sender: TObject);
    procedure OpenProtoSpeedButtonClick(Sender: TObject);
  private
  protected
    procedure SetBtnFocus;
  public
    procedure ShowProtoMes(Level: Byte; C: PChar; S: string);
    procedure ShowProccessMes(S: string);
  end;

const
  BillCompareForm: TBillCompareForm = nil;

implementation


{$R *.DFM}

{var
  ProtoFileName: string;}

procedure TBillCompareForm.ShowProtoMes(Level: Byte; C: PChar; S: string);
begin
  ProtoMemo.Lines.Add(S);
  ProtoMes(Level, C, S);
end;

procedure TBillCompareForm.ShowProccessMes(S: string);
begin
  StatusBar.Panels[1].Text := S;
end;

var
  Process: Boolean = False;
  
var
  BillDataSet, AccDataSet, AccArcDataSet: TExtBtrDataSet;
  FirstDate: Word = 0;

procedure TBillCompareForm.FormCreate(Sender: TObject);
const
  Border=2;
var
  W: Word;
begin
  if FirstDate=0 then
  begin
    W := DateToBtrDate(Date);
    FirstDate := GetPrevWorkDay(W);
    if FirstDate=0 then
      FirstDate := W;
  end;
  DateEdit.Date := BtrDateToDate(FirstDate);
  BillDataSet := GlobalBase(biBill);
  AccDataSet := GlobalBase(biAcc);
  AccArcDataSet := GlobalBase(biAccArc);
  with ProgressBar do
  begin
    Parent := StatusBar;
    SetBounds(0, Border, Width, StatusBar.Height - Border);
    StatusBar.Panels[0].Width := Width;
  end;
  {ProtoFileName := DecodeMask('$(AbsLogFile)',5);}
  DefineGridCaptions(MemDBGrid, PatternDir+'BillComp.tab');
end;

procedure TBillCompareForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
end;

procedure TBillCompareForm.ProccessBtnClick(Sender: TObject);
const
  MesTitle: PChar = 'Экспорт';

type
  PBillInfo = ^TBillInfo;
  TBillInfo = packed record
    biIder: Integer;
    biAcc: TAccount;
    biSum: Comp;
  end;

function CompareBill(Key1, Key2: Pointer): Integer;
var
  k1: PBillInfo absolute Key1;
  k2: PBillInfo absolute Key2;
begin
  if k1^.biAcc<k2^.biAcc then
    Result := -1
  else
    if k1^.biAcc>k2^.biAcc then
      Result := 1
    else
      if k1^.biSum<k2^.biSum then
        Result := -1
      else
        if k1^.biSum>k2^.biSum then
          Result := 1
        else
          Result := 0;
end;

function FindFirstBillByAcc(BillList: TList; Acc: TAccount): Integer;
var
  L, H, I, C: Integer;
begin
  Result := -1;
  try
    L := 0;
    H := BillList.Count - 1;
    while L <= H do
    begin
      I := (L + H) shr 1;
      C := StrLComp(@PBillInfo(BillList.Items[I])^.biAcc, Acc, SizeOf(TAccount));
      if C < 0 then
        L := I + 1
      else begin
        H := I - 1;
        if C = 0 then
          Result := I;
      end;
    end;
    while (Result>0) and (PBillInfo(BillList.Items[Result-1])^.biAcc=Acc) do
      Dec(Result);
  except
    MessageBox(GetForegroundWindow, 'Ошибка поиска счета',
      'Список выписок', MB_OK+MB_ICONERROR);
  end;
end;

type
  TDelPro = packed record
    dpAccNum: string[10];
    dpCurrCode: string[3];
    dpProDate: Integer;
    dpProCode: Integer;
  end;

function FillBillListByQrm(Acc: TAccount; ProDate: Integer; QrmIndex: Integer;
  QrmBillList: TList): Integer;
var
  AccStr: string;
  AccNum: string[10];
  CurrCode: string[3];
  UserCode, Len, Res: Integer;
  DelPro: TDelPro;
  PB: PBillInfo;
  Sum: Comp;
  AccExist: Boolean;                                 //Добавлено Меркуловым
begin
  Result := 0;
  AccExist := False;                                //Добавлено Меркуловым
  AccStr := Acc;
  //Добавлено Меркуловым
  if OraBase.OrBaseConn then
    AccExist := OrGetAccAndCurrByNewAcc(AccStr, AccNum, CurrCode, UserCode)
  {else
    AccExist := GetAccAndCurrByNewAcc(AccStr, AccNum, CurrCode, UserCode)};
  //Конец
  if AccExist then
  begin
    //Добавлено Меркуловым
    if OraBase.OrBaseConn then
      with OraBase, OrQuery do
        begin
        SQL.Clear;
        if QrmIndex=1 then
          begin
          SQL.Add('Select * from '+OrScheme+'.Pro where ProCode>=0 and DbAcc');
          SQL.Add('='''+AccNum+''' and DbCurrCode='''+CurrCode+''' and ProDate=');
          SQL.Add('to_date('''+DosDateToStr(ProDate)+''',''dd.mm.yyyy'') order by ProCode');
          end
        else
          begin
          SQL.Add('Select * from '+OrScheme+'.Pro where ProCode>=0 and KrAcc');
          SQL.Add('='''+AccNum+''' and KrCurrCode='''+CurrCode+''' and ProDate=');
          SQL.Add('to_date('''+DosDateToStr(ProDate)+''',''dd.mm.yyyy'') order by ProCode');
          end;
        Open;
        {if Length(Fields[0].AsString)>0 then
          Res := -1;}
        while not eof and Process do
          begin
          if QrmIndex=1 then
            Sum := FieldbyName('SumPro').AsFloat * (-100.0)
          else
            Sum := FieldbyName('SumPro').AsFloat * 100.0;
          New(PB);
          with PB^ do
          begin
            biIder := FieldbyName('ProCode').AsInteger;
            biAcc := Acc;
            biSum := Sum;
          end;
          QrmBillList.Add(PB);
          Inc(Result);
          Next;
          end;
        end
    {else
    begin
      with DelPro do
      begin
        dpAccNum := AccNum;
        dpCurrCode := CurrCode;
        dpProDate := ProDate;
        dpProCode := 0;
      end;
      with QrmBases[qbPro] do
      begin
        Len := FileRec.frRecordFixed;
        Res := BtrBase.GetGE(Buffer^, Len, DelPro, QrmIndex);
        if QrmIndex=1 then
          begin
          if (AsString[prDbAcc]<>AccNum) or (AsString[prDbCurrCode]<>CurrCode) then
            Res := -1;
          end
        else
          if (AsString[prKrAcc]<>AccNum) or (AsString[prKrCurrCode]<>CurrCode)  then
            Res := -1;
        while (Res=0) and (AsInteger[prProDate]=ProDate) and Process do
        begin
          if QrmIndex=1 then
            Sum := AsFloat[prSumPro] * (-100.0)
          else
            Sum := AsFloat[prSumPro] * 100.0;
          New(PB);
          with PB^ do
          begin
            biIder := AsInteger[prProCode];
            biAcc := Acc;
            biSum := Sum;
          end;
          QrmBillList.Add(PB);
          Inc(Result);
          Len := FileRec.frRecordFixed;
          Res := BtrBase.GetNext(Buffer^, Len, DelPro, QrmIndex);
          if QrmIndex=1 then
            begin
            if (AsString[prDbAcc]<>AccNum) or (AsString[prDbCurrCode]<>CurrCode) then
              Res := -1;
            end
          else
            if (AsString[prKrAcc]<>AccNum) or (AsString[prKrCurrCode]<>CurrCode)  then
              Res := -1;
        end;
      end;
    end};
  end
  else
    ShowProtoMes(plWarning, MesTitle, 'Счет не найден ['+AccStr+'] в Кворум');
end;

var
  BillList: TList;
  BtrProDate: Word;
  C: Integer;

  function AddAccBill(Acc: TAccount; Sum: Comp; Ider: Integer): Boolean;
  var
    AccRec: TAccRec;
    Len, Res: Integer;
    PB: PBillInfo;
  begin
    Result := False;    {счет не зарегистрирован}
    Len := SizeOf(TAccRec);
    Res := AccDataSet.BtrBase.GetEqual(AccRec, Len, Acc, 1);
    if (Res=0) and (not JustOpenBox.Checked
      or DateIsActive(BtrProDate, AccRec.arDateO, AccRec.arDateC)) then
    begin
      New(PB);
      with PB^ do
      begin
        biIder := Ider;
        biAcc := Acc;
        biSum := Sum;
      end;
      BillList.Add(PB);
      Result := True;
      Inc(C);
      BillCountLabel.Caption := IntToStr(C);
    end;
  end;

const
  fiAcc = 0;
  fiSum = 1;
  fiIder = 2;
  fiSource = 3;

var
  BadBill, BadAcc, BadMakes: Integer;

procedure AddBadBill(PB: PBillInfo; Src: Char);
begin
  Inc(BadBill);
  ErrBillCountLabel.Caption := IntToStr(BadBill);
  with PB^ do
  begin
    if Src='К' then
      ShowProtoMes(plWarning, MesTitle,
        'Нет проводки '+SumToStr(biSum)+' в Банк-клиенте QrmId='+IntToStr(biIder))
    else
      ShowProtoMes(plWarning, MesTitle, 'Нет проводки '+SumToStr(biSum)
        +' в Кворуме BfId='+IntToStr(biIder));
    with RxMemoryData do
    begin
      Append;
      Fields.Fields[fiAcc].AsString := biAcc;
      Fields.Fields[fiSum].AsFloat := biSum * 0.01;
      Fields.Fields[fiIder].AsInteger := biIder;
      Fields.Fields[fiSource].AsString := Src;
      Post;
    end;
  end;
end;

procedure FreeList(L: TList);
var
  I: Integer;
begin
  for I := 0 to L.Count-1 do
    Dispose(L.Items[I]);
  L.Clear;
end;

(*???

function TPaydocsForm.CloseDays: Boolean;
const
  MesTitle: PChar = 'Закрытие опердней';
var
  KeyAA:
    packed record
      aaIder: longint;
      aaDate: word;
    end;
  KeyO: Word;
  Sum: Comp;
  I, K, Len, Res, Res1: Integer;
  Key0: Longint;
  LastDate, FirstDate, MaxDate: word;
  S: string;
  AccRec: TAccRec;
  AccArcRec: TAccArcRec;
  BillRec: TOpRec;
  BankPayRec: TBankPayRec;
  AccList: TAccList;
  PAccCol: PAccColRec;
  Date1, Date2: TDateTime;
  CloseDayLim: Integer;
  Errors: boolean;
begin
            { Инициализация списка счетов }
            ShowMes('Инициализация списка счетов...');
            FirstDate := $FFFF;
            AccList := TAccList.Create;
            Len := SizeOf(AccRec);
            Res := AccDataSet.BtrBase.GetFirst(AccRec, Len, Key0, 0);
            while Res=0 do
            begin
              if (AccRec.arDateC=0) or (AccRec.arDateC>LastDate) then
              begin
                PAccCol := New(PAccColRec);
                with PAccCol^ do
                begin
                  acNumber := AccRec.arAccount;
                  acIder := AccRec.arIder;
                  acFDate := AccRec.arDateO;
                  acTDate := AccRec.arDateC;
                  if acTDate=0 then
                    acTDate := $FFFF;
                  acSumma := AccRec.arSumS;
                  acSumma2 := AccRec.arSumS;

                  KeyAA.aaIder := AccRec.arIder;
                  KeyAA.aaDate := $FFFF;
                  Len := SizeOf(AccArcRec);
                  Res := AccArcDataSet.BtrBase.GetLE(AccArcRec, Len, KeyAA, 1);
                  with AccArcRec do
                  begin
                    if (Res=0) and (aaIder=AccRec.arIder) and (acFDate<aaDate) then
                    begin
                      acFDate := aaDate;
                      acSumma := aaSum;
                      acSumma2 := aaSum;
                    end;
                  end;
                  if acFDate<FirstDate then
                    FirstDate := acFDate;
                end;
                AccList.Add(PAccCol);
              end;
              Len := SizeOf(AccRec);
              Res := AccDataSet.BtrBase.GetNext(AccRec, Len, Key0, 0);
            end;

            begin
              AccList.Sort(AccColRecCompare);
              { Просчет состояний счетов по выпискам }
              ShowMes('Просчет состояний счетов по выпискам...');
              KeyO := LastDate;
              Len := SizeOf(BillRec);
              Res := BillDataSet.BtrBase.GetGT(BillRec, Len, KeyO, 2);
              Errors := False;
              while (Res=0) and not Errors do
              begin
                if (NotSendTest>0) and (BillRec.brDate<=MaxDate)
                  and (BillNeedSend(BillRec, True, S)>0) then
                begin
                  K := MB_ICONWARNING;
                  S := 'Найдена неотправленная выписка от '
                    +BtrDateToStr(BillRec.brDate)+' - '+S+#13#10;
                  if NotSendTest=1 then
                  begin
                    K := K or MB_YESNOCANCEL or MB_DEFBUTTON2;
                    S := S+'Вы хотите продолжить закрытие дней?';
                  end
                  else begin
                    K := K or MB_OK;
                    S := S+'Необходимо провести сеанс связи';
                  end;
                  Errors := MessageBox(Handle, PChar(S), MesTitle, K)<>ID_YES;
                end;
                if not Errors then
                begin
                  if (BillRec.brDel=0) and (BillRec.brPrizn=brtBill) then
                  begin
                    Sum := BillRec.brSum;
                    K := AccList.SearchAcc(@BillRec.brAccD);
                    if K>=0 then
                    begin
                      PAccCol := AccList.Items[K];
                      if (BillRec.brDate>PAccCol^.acFDate)
                        and (BillRec.brDate<=PAccCol^.acTDate) then
                          PAccCol^.acSumma := PAccCol^.acSumma - Sum;
                    end;
                    K := AccList.SearchAcc(@BillRec.brAccC);
                    if K>=0 then
                    begin
                      PAccCol := AccList.Items[K];
                      if (BillRec.brDate>PAccCol^.acFDate)
                        and (BillRec.brDate<=PAccCol^.acTDate) then
                          PAccCol^.acSumma := PAccCol^.acSumma + Sum;
                    end;
                  end;
                  Len := SizeOf(BillRec);
                  Res := BillDataSet.BtrBase.GetNext(BillRec, Len, KeyO, 2);
                end;
              end;
              if not Errors then
              begin
                Errors := False;
                { Проверка соответствия состояний счетов просчитанным по выпискам }
                ShowMes('Проверка состояний счетов на соответствие выпискам...');
                I := 0;
                while I<AccList.Count do
                begin
                  PAccCol := AccList.Items[I];
                  Key0 := PAccCol^.acIder;
                  Len := SizeOf(AccRec);
                  Res := AccDataSet.BtrBase.GetEqual(AccRec, Len, Key0, 0);
                  if Res=0 then
                  begin
                    if PAccCol^.acSumma<>AccRec.arSumA then
                    begin
                      Str((AccRec.arSumA-PAccCol^.acSumma)/100:0:2, S);
                      S := 'Ошибка остатка по счету '+PAccCol^.acNumber+' на сумму '+S;
                      ProtoMes(plWarning, MesTitle, S);
                      MessageBox(Application.Handle, PChar(S), MesTitle, MB_OK or MB_ICONWARNING);
                      Errors := True
                    end;
                  end;
                  Inc(I);
                end;
                ShowMes('');
                if not Errors then
                begin
                  Screen.Cursor := crHourGlass;
                  KeyO := LastDate;
                  Len := SizeOf(BillRec);
                  Res := BillDataSet.BtrBase.GetGT(BillRec, Len, KeyO, 2);
                  while (Res=0) and (BillRec.brDate<=MaxDate) do
                  begin
                    FirstDate := BillRec.brDate;
                    ShowMes('Закрытие дня '+BtrDateToStr(FirstDate)+'...');
                    { Перепись док-тов из текущих в архив }
                    while (Res=0) and (BillRec.brDate=FirstDate) do
                    begin
                      if Billrec.brDel=0 then
                      begin
                        Key0 := BillRec.brDocId;
                        Len := SizeOf(BankPayRec);
                        Res := PayDataSet.BtrBase.GetEqual(BankPayRec, Len, Key0, 0);
                        if Res=0 then
                          with BankPayRec do
                          begin
                            dbIdDoc := 0;
                            dbIdArc := dbIdHere;
                            Res := PayDataSet.BtrBase.Update(BankPayRec, Len, Key0, 0);
                            if Res<>0 then
                            begin
                              S := 'Не удается перенести документ ['#13#10
                                +DocInfo(BankPayRec)+'] в архив BtrErr='
                                +IntToStr(Res);
                              ProtoMes(plError, MesTitle, S);
                              MessageBox(Application.Handle, PChar(S), MesTitle,
                                MB_OK or MB_ICONERROR);
                            end;
                          end;
                        if BillRec.brPrizn=brtBill then
                        begin
                          Sum := BillRec.brSum;
                          K := AccList.SearchAcc(@BillRec.brAccD);
                          if K>=0 then
                          begin
                            PAccCol := AccList.Items[K];
                            if (BillRec.brDate>PAccCol^.acFDate)
                              and (BillRec.brDate<=PAccCol^.acTDate) then
                                PAccCol^.acSumma2 := PAccCol^.acSumma2 - Sum;
                          end;
                          K := AccList.SearchAcc(@BillRec.brAccC);
                          if K>=0 then
                          begin
                            PAccCol := AccList.Items[K];
                            if (BillRec.brDate>PAccCol^.acFDate)
                              and (BillRec.brDate<=PAccCol^.acTDate) then
                                PAccCol^.acSumma2 := PAccCol^.acSumma2 + Sum;
                          end;
                        end;
                      end;
                      Len := SizeOf(BillRec);
                      Res := BillDataSet.BtrBase.GetNext(BillRec, Len, KeyO, 2);
                    end;
                    { Сохранение остатков на счетах в архиве }
                    I := 0;
                    while I<AccList.Count do
                    begin
                      PAccCol := AccList.Items[I];
                      if (FirstDate>PAccCol^.acFDate) and (FirstDate<=PAccCol^.acTDate) then
                      begin
                        with AccArcRec do
                        begin
                          aaIder := PAccCol^.acIder;
                          aaDate := FirstDate;
                          aaSum := PAccCol^.acSumma2;
                        end;
                        Len := SizeOf(AccArcRec);
                        Res1 := AccArcDataSet.BtrBase.Insert(AccArcRec, Len, KeyAA, 0);
                        if Res1<>0 then
                        begin
                          S := 'Не удается добавить остаток за закрытый день по счету ['
                            +PAccCol^.acNumber+'] BtrErr='+IntToStr(Res1);
                          ProtoMes(plError, MesTitle, S);
                          MessageBox(Application.Handle, PChar(S),
                            MesTitle, MB_OK or MB_ICONERROR);
                        end;
                      end;
                      Inc(I);
                    end;
                  end;
                  ProtoMes(plInfo, MesTitle, 'Операционные дни закрыты с '
                    +BtrDateToStr(FirstDate)+' по '+BtrDateToStr(MaxDate));
                  ShowMes('Операционные дни закрыты');
                  Screen.Cursor := crDefault;
                  Result := True;
                  MessageBox(Application.Handle, 'Операционные дни закрыты',
                    MesTitle, MB_OK + MB_ICONINFORMATION);
                end;
              end;
            end;
            AccList.Free;

??? *)

var
  ProDate: Integer;
  Res, Len, I, I1, I2, N1, N2, OperN: Integer;
  KeyD: Word;
  OpRec: TOpRec;
  Acc: TAccount;
  PB1, PB2: PBillInfo;
  QrmBillList: TList;
  AccList: TAccList;
  PAccCol: PAccColRec;
  dSum1, dSum2: Comp;
  AccRec: TAccRec;
  AccNum, CurrCode: ShortString;
  LimKey:
    packed record
      lkAcc: string[10];
      lkCurrCode: string[3];
      lkProDate: Integer;
    end;
  {KeyAA:
    packed record
      aaIder: longint;
      aaDate: word;
    end;}
  {AccArcRec: TAccArcRec;}
  AccExist: Boolean;                       //Добавлено Меркуловым
begin
  if Process then
    Process := False
  else begin
    BillCountLabel.Caption := '0';
    CheckCountLabel.Caption := '0';
    ErrBillCountLabel.Caption := '0';
    RxMemoryData.EmptyTable;
    Process := True;
    ProccessBtn.Caption := '&Прервать';
    CancelBtn.Enabled := False;
    AccExist := False;                     //Добавлено Меркуловым
    //Добавлено Меркуловым
    if OraBase.OrBaseConn then
      Process := OraBase.OrDB.Connected
    {else
      Process := QrmBasesIsOpen};
    //Конец
    if Process then
    begin
      BtrProDate := DateToBtrDate(DateEdit.Date);
      ProDate := BtrDateToDosDate(BtrProDate);
      ShowProtoMes(plInfo, MesTitle, '===Сверка выписок за '
        +BtrDateToStr(BtrProDate)+'===');
      { построим коллекцию открытых счетов }
      AccList := TAccList.Create;
      Len := SizeOf(AccRec);
      Res := AccDataSet.BtrBase.GetFirst(AccRec, Len, Acc, 1);
      while (Res=0) and Process do
      begin
        if not JustOpenBox.Checked or
          DateIsActive(BtrProDate, AccRec.arDateO, AccRec.arDateC) then
        begin
          //Добавлено Меркуловым
          if OraBase.OrBaseConn then
          begin
            if OrGetAccAndCurrByNewAcc(Acc, AccNum, CurrCode, OperN) then
              AccExist := True;
          end
          {else
            if GetAccAndCurrByNewAcc(Acc, AccNum, CurrCode, OperN) then
              AccExist := True};
          if AccExist then
          //Конец
          begin
            PAccCol := New(PAccColRec);
            FillChar(PAccCol^, SizeOf(TAccColRec), #0);
            //Добавлено Меркуловым
            if OraBase.OrBaseConn then
              with OraBase, OrQuery do
              begin
                SQL.Clear;
                SQL.Add('Select ProDate, Lim from '+OrScheme+'.Lim where Acc=');
                SQL.Add(''''+AccNum+''' and CurrCode='''+CurrCode+''' and ProDate');
                SQL.Add('<=to_date('''+DosDateToStr(ProDate)+''',''dd.mm.yyyy'') order by ProDate desc');
                Open;
                if Length(Fields[0].AsString)>0 then
                  PAccCol^.acSumma2 := Fields[1].AsFloat*100;
              end
            {else
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
                  and (AsString[lmCurrCode]=CurrCode)
                then
                  PAccCol^.acSumma2 := AsFloat[lmLim]*100;
              end};
              //Конец
            with PAccCol^ do
            begin
              StrLCopy(acNumber, Acc, SizeOf(acNumber));
              acIder := AccRec.arIder;
              acFDate := AccRec.arDateO;
              acTDate := AccRec.arDateC;
              if acTDate=0 then
                acTDate := $FFFF;
              acSumma := AccRec.arSumA;
              if (AccRec.arOpts and asType = 0) and (acSumma2<0) then
                ShowProtoMes(plInfo, MesTitle, 'Пассивный счет ['
                  +Acc+'] при активном остатке в АБС');
              if (AccRec.arOpts and asType = 1) and (acSumma2>0) then
                ShowProtoMes(plInfo, MesTitle, 'Активный счет ['
                  +Acc+'] при пассивном остатке в АБС');
            end;
            AccList.Add(PAccCol);
          end
          else
            ShowProtoMes(plInfo, MesTitle, 'Счет ['+Acc
              +'] не найден в Кворуме, пропущен')
        end;
        Len := SizeOf(AccRec);
        Res := AccDataSet.BtrBase.GetNext(AccRec, Len, Acc, 1);
        Application.ProcessMessages;
      end;
      { отсортируем коллекцию }
      {AccList.Sort(@AccColRecCompare);
      Application.ProcessMessages;}
      { сформируем коллекцию проводок БК, пересчитаем остаток }
      BillList := TList.Create;
      try
        C := 0;
        {B := 0;}
        BadBill := 0;
        BadAcc := 0;
        BadMakes := 0;
        ShowProccessMes('Формируется коллекция проводок Банк-клиента...');
        Len := SizeOf(OpRec);
        KeyD := BtrProDate;
        Res := BillDataSet.BtrBase.GetGE(OpRec, Len, KeyD, 2);
        while (Res=0) and Process do
        begin
          FillChar(PChar(@OpRec)[Len], SizeOf(OpRec)-Len, #0);
          with OpRec do
          begin
            if (brDel=0) and (brPrizn=brtBill) then
            begin
              if KeyD=BtrProDate then
              begin
                AddAccBill(brAccD, -brSum, brIder);
                AddAccBill(brAccC, brSum, brIder);
              end
              else begin
                I := AccList.SearchAcc(@brAccD);
                if I>=0 then
                begin
                  PAccCol := AccList.Items[I];
                  if (brDate>PAccCol^.acFDate) and (brDate<=PAccCol^.acTDate) then
                    PAccCol^.acSumma := PAccCol^.acSumma - brSum;
                end;
                I := AccList.SearchAcc(@brAccC);
                if I>=0 then
                begin
                  PAccCol := AccList.Items[I];
                  if (brDate>PAccCol^.acFDate) and (brDate<=PAccCol^.acTDate) then
                    PAccCol^.acSumma := PAccCol^.acSumma + brSum;
                end;
              end;
            end;
          end;
          Len := SizeOf(OpRec);
          Res := BillDataSet.BtrBase.GetNext(OpRec, Len, KeyD, 2);
          Application.ProcessMessages;
        end;
        { сверим выписки }
        if Process then
        begin
          ShowProccessMes('Сортировка коллекции проводок Банк-клиента...');
          BillList.Sort(@CompareBill);
          ShowProccessMes('Сверка выписок и остатков с Кворум...');
          QrmBillList := TList.Create;
          try
            ProgressBar.Min := 0;
            ProgressBar.Position := ProgressBar.Min;
            ProgressBar.Max := AccList.Count;
            ProgressBar.Show;
            I := 0;
            while (I<AccList.Count) and Process do
            begin
              PAccCol := AccList.Items[I];
              {for I1 := 0 to SizeOf(Acc)-1 do}
                Acc{[I1]} := PAccCol^.acNumber{[I1]};
              if PAccCol^.acSumma <> PAccCol^.acSumma2 then
              begin
                ShowProtoMes(plInfo, MesTitle,
                  'Расхождение остатков '+Acc+' : Б'+SumToStr(PAccCol^.acSumma)
                  +' K'+SumToStr(PAccCol^.acSumma2));
                Inc(BadAcc);
              end;
              { возьмем выписку из Кворум }
              FreeList(QrmBillList);
              FillBillListByQrm(Acc, ProDate, 1, QrmBillList);
              FillBillListByQrm(Acc, ProDate, 2, QrmBillList);
              QrmBillList.Sort(@CompareBill);
              { сравним выписки }
              I1 := FindFirstBillByAcc(BillList, Acc);
              if I1>=0 then
                N1 := BillList.Count
              else begin
                I1 := 0;
                N1 := 0;
              end;
              I2 := 0;
              N2 := QrmBillList.Count;
              dSum1 := 0;
              dSum2 := 0;
              PB1 := nil;
              PB2 := nil;
              while (I1<N1) and (PBillInfo(BillList.Items[I1])^.biAcc=Acc)
                or (I2<N2) do
              begin
                if I1<N1 then
                begin
                  PB1 := BillList.Items[I1];
                  dSum1 := dSum1 + PB1.biSum;
                end;
                if I2<N2 then
                begin
                  PB2 := QrmBillList.Items[I2];
                  dSum2 := dSum2 + PB2.biSum;
                end;
                if (I1>=N1) or (I2<N2) and (PB1.biSum>PB2.biSum) then
                begin
                  AddBadBill(PB2, 'К');
                  Inc(I2);
                end
                else
                  if (I2>=N2) or (PB1.biSum<PB2.biSum) then
                  begin
                    AddBadBill(PB1, 'Б');
                    Inc(I1);
                  end
                  else begin
                    Inc(I1);
                    Inc(I2);
                  end;
              end;
              if dSum1<>dSum2 then
              begin
                ShowProtoMes(plInfo, MesTitle, 'Расхождение выписок по счету '
                  +Acc+' на сумму '+SumToStr(dSum2-dSum1));
                Inc(BadMakes);
              end;
              ProgressBar.Position := I;
              Application.ProcessMessages;
              Inc(I);
              CheckCountLabel.Caption := IntToStr(I);
            end;
            ShowProtoMes(plInfo, MesTitle, 'Проверено выписок: '+IntToStr(I));
            if (BadMakes>0) or (BadBill>0) or (BadAcc>0) then
              ShowProtoMes(plWarning, MesTitle,
                'Обнаружены расхождения в выписах: по остаткам '
                +IntToStr(BadAcc)+'; по проводкам '+IntToStr(BadMakes)+' (проводок: '
                +IntToStr(BadBill)+')')
            else
              ShowProtoMes(plInfo, MesTitle, 'Расхождений в выписках не обнаружено');
            Application.ProcessMessages;
          finally
            ShowProccessMes('');
            ProgressBar.Hide;
            FreeList(QrmBillList);
            QrmBillList.Free;
          end;
        end;
      finally
        ShowProccessMes('');
        FreeList(BillList);
        BillList.Free;
      end;
      AccList.Free;
    end
    else
      ShowProtoMes(plWarning, MesTitle, 'Не все базы Кворум открыты');
    if Process then
      ShowProtoMes(plInfo, MesTitle, 'Процесс завершен')
    else
      ShowProtoMes(plWarning, MesTitle, 'Процесс не завершен');
    Process := False;
    ProccessBtn.Caption := '&Начать...';
    CancelBtn.Enabled := True;
    AccDataSet.Refresh;
    BillDataSet.Refresh;
  end;
end;

procedure ShowComponents(Comp: TWinControl; V: Boolean);
var
  I: Integer;
begin
  with Comp do
    for I := 0 to ControlCount-1 do
      Controls[I].Visible := V;
end;

procedure TBillCompareForm.SetBtnFocus;
begin
  Application.ProcessMessages;
  if ProccessBtn.Enabled then
    ProccessBtn.SetFocus
  else
    CancelBtn.SetFocus;
end;

procedure TBillCompareForm.DateEditExit(Sender: TObject);
var
  W: Word;
begin
  try
    W := DateToBtrDate(DateEdit.Date);
  except
    W := 0;
  end;
  if W>0 then
    FirstDate := W;
end;

procedure TBillCompareForm.DateEditAcceptDate(Sender: TObject;
  var ADate: TDateTime; var Action: Boolean);
var
  W: Word;
begin
  try
    W := DateToBtrDate(ADate);
  except
    W := 0;
  end;
  if W>0 then
    FirstDate := W;
end;

procedure TBillCompareForm.OpenProtoSpeedButtonClick(Sender: TObject);
const
  MesTitle: PChar = 'Просмотр протокола';
var
  FN: string;
  Ok: Boolean;
begin
  FN := PostDir+'acc_proto.txt';
  Ok := True;
  try
    ProtoMemo.Lines.SaveToFile(FN);
  except
    Ok := False;
  end;
  if Ok then
    WinExec(PChar('notepad.exe '+FN), SW_SHOW)
  else
    MessageBox(Handle, PChar('Ошибка создания временного файла '+FN),
      MesTitle, MB_OK or MB_ICONERROR);
end;

end.


