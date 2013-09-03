unit AbonStatFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Grids, Db, DBTables, DBGrids, ExtCtrls, DBCtrls, BtrDS, Menus,
  StdCtrls, Buttons, ComCtrls, SearchFrm, Mask, ToolEdit,
  Btrieve, TimerLst, Common, Basbn, Registr, Utilits,
  CommCons, BankCnBn, BUtilits, ClntCons, RxMemDS;

type
  TAbonStatForm = class(TDataBaseForm)
    StatusBar: TStatusBar;
    BtnPanel: TPanel;
    ToDateEdit: TDateEdit;
    ProgressBar: TProgressBar;
    ChildMenu: TMainMenu;
    OperItem: TMenuItem;
    EditBreaker: TMenuItem;
    FindItem: TMenuItem;
    MakeItem: TMenuItem;
    AbortBtn: TBitBtn;
    RxMemoryData: TRxMemoryData;
    DataSource: TDataSource;
    DBGrid: TDBGrid;
    ToDateLabel: TLabel;
    MakePopupMenu: TPopupMenu;
    DebetEdit: TEdit;
    DebetLabel: TLabel;
    CreditEdit: TEdit;
    CreditLabel: TLabel;
    AccEdit: TEdit;
    ActiveLabel: TLabel;
    PassiveLabel: TLabel;
    DocEdit: TEdit;
    SortIndexComboBox: TComboBox;
    SortLabel: TLabel;
    FromDateEdit: TDateEdit;
    FromLabel: TLabel;
    CritRadioGroup: TRadioGroup;
    ShowBlockCheckBox: TCheckBox;
    RxMemoryDataIder: TIntegerField;
    RxMemoryDataNode: TIntegerField;
    RxMemoryDataLogin: TStringField;
    RxMemoryDataType: TStringField;
    RxMemoryDataLock: TStringField;
    RxMemoryDataName: TStringField;
    RxMemoryDataAccCount: TIntegerField;
    RxMemoryDataInDocCount: TIntegerField;
    RxMemoryDataOutDocCount: TIntegerField;
    RxMemoryDataDebSum: TStringField;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure StringGridDrawCell(Sender: TObject; ACol, ARow: Integer;
      ARect: TRect; AState: TGridDrawState);
    procedure ViewItemClick(Sender: TObject);
    procedure FindItemClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ToDateEditAcceptDate(Sender: TObject; var ADate: TDateTime;
      var Action: Boolean);
    procedure AbortBtnClick(Sender: TObject);
    procedure MakeItemClick(Sender: TObject);
    procedure ToDateEditExit(Sender: TObject);
    procedure ToDateEditChange(Sender: TObject);
    procedure MaskComboBoxKeyPress(Sender: TObject; var Key: Char);
    procedure SortIndexComboBoxClick(Sender: TObject);
  private
    AccDataSet, AbonDataSet, DocDataSet: TExtBtrDataSet;
    procedure WMMakeStatement(var Message: TMessage); message WM_MAKESTATEMENT;
  protected
    procedure StatusMessage(S: string);
    procedure InitProgress(AMin, AMax: Integer);
    procedure FinishProgress;
    procedure ShowAcc(Value: Boolean);
  public
    SearchForm: TSearchForm;
    procedure TakeTabPrintData(var PrintDocRec: TPrintDocRec; var FormList: TList); override;
  end;

var
  AbonStatForm: TAbonStatForm;

implementation

{$R *.DFM}

procedure ClearStrings(AStrings: TStrings);
begin
  with AStrings do
  begin
    while Count>0 do
    begin
      Dispose(Pointer(Objects[Count-1]));
      Delete(Count-1);
    end;
  end;
end;

procedure TAbonStatForm.TakeTabPrintData(var PrintDocRec: TPrintDocRec; var FormList: TList);
begin 
  inherited;
  PrintDocRec.DBGrid := Self.DBGrid;
  PrintDocRec.GraphForm := DecodeMask('$(AbonStatGraphForm)', 5, GetUserNumber);
  PrintDocRec.TextForm := DecodeMask('$(AbonStatTextForm)', 5, GetUserNumber);
end;

const
  {MaxAcc = 1000;}
  ModuleTitle: PChar = 'Статистика документооборота';
  DataIsChanged: Boolean = False;
var
  CorrCollectList: TList = nil;

procedure TAbonStatForm.FormCreate(Sender: TObject);
const
  Border=2;
var
  W: Word;
begin
  CorrCollectList := TList.Create;

  with ProgressBar do
  begin
    Parent := StatusBar;
    SetBounds(0, Border, Width, StatusBar.Height - Border);
  end;
  DefineGridCaptions(DBGrid, PatternDir+'AbonStat.tab');

  SearchForm := TSearchForm.Create(Self);
  SearchForm.SourceDBGrid := DBGrid;

  AccDataSet := GlobalBase(biAcc);
  AbonDataSet := GlobalBase(biAbon);
  {BillDataSet := GlobalBase(biBill);}
  DocDataSet := GlobalBase(biPay);

  TakeMenuItems(OperItem, MakePopupMenu.Items);
  MakePopupMenu.Images := ChildMenu.Images;

  SortIndexComboBox.ItemIndex := 1;
  
  W := GetPrevWorkDay(DateToBtrDate(Date));
  if W=0 then
    FromDateEdit.Date := Date
  else
    FromDateEdit.Date := BtrDateToDate(W);
  ToDateEdit.Date := FromDateEdit.Date;
end;

procedure ClearList(AList: TList);
var
  I: Integer;
begin
  with AList do
  begin
    for I := 0 to Count-1 do
      Dispose(Pointer(Items[I]));
    Clear;
  end;
end;

procedure TAbonStatForm.FormDestroy(Sender: TObject);
begin
  AbonStatForm := nil;
  ClearList(CorrCollectList);
  CorrCollectList.Free;
end;

procedure TAbonStatForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
end;

procedure TAbonStatForm.StatusMessage(S: string);
begin
  StatusBar.Panels[1].Text := S;
end;

procedure TAbonStatForm.InitProgress(AMin, AMax: Integer);
const
  Border=2;
begin
  with ProgressBar do
  begin
    StatusBar.Panels[0].Width := Width;
    Min := -100;
    Position := AMin;
    Max := AMax;
    Min := AMin;
    Position := AMin;
    Show;
  end;
end;

procedure TAbonStatForm.FinishProgress;
begin
  ProgressBar.Hide;
  StatusBar.Panels[0].Width := 0;
end;

type
  PAccColOnDayRec = ^TAccColOnDayRec;
  TAccColOnDayRec = record
    acNumber: TAccount;
    acIder:   longint;
    acFDate:  word;
    acTDate:  word;
    acOpCnt:  word;
    acInOst:  comp;
    acOutOst: comp;
    acDebet:  comp;
    acCredit: comp;
  end;

{var
  TotalAct, TotalPas, TotalDebet, TotalCredit: comp;
  MaskChanged: Boolean = True;}

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

(*procedure TAbonStatForm.FillAccTable;
var
  Key0: longint;
  I, Len, C: Integer;
  Buf: array[0..512] of Char;
  PAcc: PAccColOnDayRec;
  pa: TAccRec;
  FullMask: Boolean;
begin
  RxMemoryData.EmptyTable;
  C := 0;
  try
    while Length(MaskComboBox.Text)<SizeOf(TAccount) do
      MaskComboBox.Text := MaskComboBox.Text + '?';
    I := 1;
    while (I<=SizeOf(TAccount)) and (MaskComboBox.Text[I]='?') do
      Inc(I);
    FullMask := I>SizeOf(TAccount);
    StatusMessage('Показ ведомости...');
    InitProgress(0, AccList.Count);
    I := 0;
    while I<AccList.Count do
    begin
      PAcc := AccList.Items[I];
      with PAcc^ do
      begin
        if (NullCheckBox.Checked or (acOutOst<>0))
          and (NonWorkedCheckBox.Checked or (acDebet<>0) or (acCredit<>0))
          and (FullMask or Masked(acNumber, MaskComboBox.Text)) then
        begin
          with RxMemoryData do
          begin
            Append;
            Fields.Fields[fiNumber].AsString := StrPas(acNumber);
            Fields.Fields[fiIder].AsInteger := acIder;
            Fields.Fields[fiDebet].AsString := SumToStr(acDebet);
            Fields.Fields[fiCredit].AsString := SumToStr(acCredit);
            Fields.Fields[fiAmount].AsString := SumToStr(acOutOst);
            Fields.Fields[fiBillAmount].AsString := SumToStr(acInOst+acCredit-acDebet);

            Key0 := acIder;
            Len := SizeOf(pa);
            if AccDataSet.BtrBase.GetEqual(pa, Len, Key0, 0)=0 then
            begin
              StrLCopy(Buf, pa.arName, SizeOf(Buf));
              DosToWin(Buf);
              Fields.Fields[fiName].AsString := StrPas(Buf);
            end;
            Post;
            Inc(C);
          end;
        end;
      end;
      Inc(I);
      ProgressBar.Position := I;
      Application.ProcessMessages;
    end;
    MaskChanged := False;
  finally
    FinishProgress;
    StatusMessage('Ведомость построена. Счетов: '+IntToStr(C));
  end;
end; *)

procedure TAbonStatForm.StringGridDrawCell(Sender: TObject; ACol,
  ARow: Integer; ARect: TRect; AState: TGridDrawState);
begin
  if ACol=0 then
    with Sender as TStringGrid do
    begin
      Canvas.Brush.Color := clBtnFace;
      Canvas.FillRect(ARect);
    end;
end;

procedure TAbonStatForm.FindItemClick(Sender: TObject);
begin
  SearchForm.ShowModal;
end;

procedure TAbonStatForm.ToDateEditAcceptDate(Sender: TObject;
  var ADate: TDateTime; var Action: Boolean);
begin
  Action := True;
  ToDateEdit.Date := ADate;
  ShowAcc(False);
  PostMessage(Handle, WM_MAKESTATEMENT, 0, 0);
  DataIsChanged := False;
end;

procedure TAbonStatForm.ToDateEditChange(Sender: TObject);
begin
  DataIsChanged := True;
end;

procedure TAbonStatForm.ToDateEditExit(Sender: TObject);
var
  Action: Boolean;
  ADate: TDateTime;
begin
  if DataIsChanged then
  begin
    ADate := ToDateEdit.Date;
    Action := True;
    ToDateEditAcceptDate(Sender, ADate, Action);
  end;
end;

procedure TAbonStatForm.AbortBtnClick(Sender: TObject);
begin
  AbortBtn.Visible := False;
end;

procedure TAbonStatForm.ShowAcc(Value: Boolean);
begin
  DebetEdit.Visible := Value;
  DebetLabel.Visible := Value;
  CreditEdit.Visible := Value;
  CreditLabel.Visible := Value;
  AccEdit.Visible := Value;
  ActiveLabel.Visible := Value;
  DocEdit.Visible := Value;
  PassiveLabel.Visible := Value;
  {if not Value then
    RxMemoryData.EmptyTable;}
end;

type
  PCorrCollectRec = ^TCorrCollectRec;
  TCorrCollectRec = record
    ccrIder: Integer;             { Идер корреспондента } {  0  k0}
    ccrNode: word;                { Узел криптования }    {  4 }
    ccrLogin: TAbonLogin;           { Позывной }            {  6  k1}
    ccrType: byte;                { Тип корреспондента }  { 15 }
    ccrLock: byte;                { Блокировки }          { 17 }
    ccrName: array[0..crMaxVar-1] of Char;                { 21 }
    ccrAccCount, ccrInDocCount, ccrOutDocCount: Integer;
    ccrDebSum: comp;
  end;

const
  SortIndex: Integer = 0;

function CorrCollectCompare(Key1, Key2: Pointer): Integer;
var
  k1: PCorrCollectRec absolute Key1;
  k2: PCorrCollectRec absolute Key2;
begin
  Result := 0;
  case SortIndex of
    1: {Логин}
      begin
        if k1^.ccrLogin<k2^.ccrLogin then
          Result := -1
        else
          if k1^.ccrLogin>k2^.ccrLogin then
            Result := 1;
      end;
    2: {Входящие док-ты}
      begin
        if k1^.ccrInDocCount<k2^.ccrInDocCount then
          Result := -1
        else
          if k1^.ccrInDocCount>k2^.ccrInDocCount then
            Result := 1;
      end;
    3: {Исх. док-ты}
      begin
        if k1^.ccrOutDocCount<k2^.ccrOutDocCount then
          Result := -1
        else
          if k1^.ccrOutDocCount>k2^.ccrOutDocCount then
            Result := 1;
      end;
    4: {Общий объем документов}
      begin
        if k1^.ccrInDocCount+k1^.ccrOutDocCount<k2^.ccrInDocCount+k2^.ccrOutDocCount then
          Result := -1
        else
          if k1^.ccrInDocCount+k1^.ccrOutDocCount>k2^.ccrInDocCount+k2^.ccrOutDocCount then
            Result := 1;
      end;
    5: {Сумма}
      begin
        if k1^.ccrDebSum<k2^.ccrDebSum then
          Result := -1
        else
          if k1^.ccrDebSum>k2^.ccrDebSum then
            Result := 1;
      end;
  end;
  if Result=0 then   {Идентификатор}
  begin
    if k1^.ccrIder<k2^.ccrIder then
      Result := -1
    else
      if k1^.ccrIder>k2^.ccrIder then
        Result := 1;
  end;
end;

{function AccColOnDayCompare(Key1, Key2: Pointer): Integer;
var
  k1: PAccColOnDayRec absolute Key1;
  k2: PAccColOnDayRec absolute Key2;
begin
  if(k1^.acNumber<k2^.acNumber) then
    Result := -1
  else if(k1^.acNumber>k2^.acNumber) then
    Result := 1
  else
    Result :=0
end;}

procedure TAbonStatForm.WMMakeStatement(var Message: TMessage);
begin
  MakeItemClick(Self);
end;

const
  DispDays = 2;
var
  FromDate, ToDate: Word;

procedure TAbonStatForm.MakeItemClick(Sender: TObject);
const
  MesTitle: PChar = 'Формирование ведомости';

  function RDate(var PayRec: TBankPayRec): word;
  begin
    Result := PayRec.dbDateR;
  end;

  function CritDate(var PayRec: TBankPayRec): word;
  begin
    if CritRadioGroup.ItemIndex=1 then
      Result := PayRec.dbDoc.drDate
    else
      Result := PayRec.dbDateR;
  end;

  function SearchCorr(Id: Integer): Integer;
  var
    L, H, I, C: Integer;
  begin
    Result := -1;
    with CorrCollectList do
    try
      L := 0;
      H := Count - 1;
      while L <= H do
      begin
        I := (L + H) shr 1;
        C := PCorrCollectRec(Items[I])^.ccrIder - Id;
        if C < 0 then
          L := I + 1
        else begin
          H := I - 1;
          if C = 0 then
            Result := I;
        end;
      end;
    except
      MessageBox(GetForegroundWindow, 'Ошибка поиска счета',
        'Список счетов', MB_OK+MB_ICONERROR);
    end;
  end;

  function IterPayDoc(Id: Integer;
    var PayRec: TBankPayRec; Direct: Byte): Boolean;
  var
    Res, Len: Integer;
  begin
    Len := SizeOf(PayRec);
    if Direct>0 then
      Res := DocDataSet.BtrBase.GetGE(PayRec, Len, Id, 0)
    else
      Res := DocDataSet.BtrBase.GetLE(PayRec, Len, Id, 0);
    while (Res=0) and (RDate(PayRec)=0) do
    begin
      Len := SizeOf(PayRec);
      if Direct>0 then
        Res := DocDataSet.BtrBase.GetNext(PayRec, Len, Id, 0)
      else
        Res := DocDataSet.BtrBase.GetPrev(PayRec, Len, Id, 0);
    end;
    Result := (Res=0) and (RDate(PayRec)>0);
  end;

var
  J, K, Len, Res: Integer;
  FromDateS, ToDateS, W: word;
  //AbonRec: TAbonRec;
  //AbonName: TAbonName;
  AbonRec: TAbonentRec;
  AbonName: TAbonName;
  CorrCollectPtr: PCorrCollectRec;
  AccRec: TAccRec;
  PayRec, FirstPayRec, LastPayRec, FirstPayRecL, LastPayRecL: TBankPayRec;
begin
  try
    Screen.Cursor := crHourGlass;
    FromDate := DateToBtrDate(FromDateEdit.Date);
    ToDate := DateToBtrDate(ToDateEdit.Date);
    FromDateS := FromDate;
    ToDateS := ToDate;
    if CritRadioGroup.ItemIndex=1 then
    begin
      FromDateS := FromDateS - DispDays;
      ToDateS := ToDateS + DispDays;
    end;
    AbortBtn.Show;
    RxMemoryData.EmptyTable;
    ClearList(CorrCollectList);
    StatusMessage('Инициализация списка абонентов...');
    { Инициализация списка счетов }
    Len := SizeOf(AbonRec);
    Res := AbonDataSet.BtrBase.GetFirst(AbonRec, Len, AbonName, 1);
    while (Res=0) and AbortBtn.Visible do
    begin
      {if ShowBlockCheckBox.Checked or ((AbonRec.crLock and 3)=0) then
      begin}
        CorrCollectPtr := New(PCorrCollectRec);
        with CorrCollectPtr^, AbonRec do
        begin
          ccrIder   :=  abIder;
          ccrNode   :=  abNode;
          ccrLogin  :=  abLogin;
          ccrType   :=  abType;
          ccrLock   :=  abLock;
          StrLCopy(ccrName, abName, SizeOf(ccrName)-1);
          DosToWinL(ccrName, SizeOf(ccrName));
          ccrAccCount := 0;
          ccrInDocCount := 0;
          ccrOutDocCount := 0;
          ccrDebSum := 0;
        end;
        CorrCollectList.Add(CorrCollectPtr);
        K := AbonRec.abIder;
        Len := SizeOf(AccRec);
        Res := AccDataSet.BtrBase.GetEqual(AccRec, Len, K, 2);
        while (Res=0) and (AccRec.arCorr=AbonRec.abIder) do
        begin
          Inc(CorrCollectPtr^.ccrAccCount);
          Len := SizeOf(AccRec);
          Res := AccDataSet.BtrBase.GetNext(AccRec, Len, K, 2);
        end;
      {end;}
      Len := SizeOf(AbonRec);
      Res := AbonDataSet.BtrBase.GetNext(AbonRec, Len, AbonName, 1);
      Application.ProcessMessages;
    end;
    StatusMessage('Предварительная сортировка коллекции...');
    SortIndex := 0;
    CorrCollectList.Sort(CorrCollectCompare);
    StatusMessage('Поиск диапазона...');
    K := 1506000;
    Len := SizeOf(FirstPayRec);
    Res := DocDataSet.BtrBase.GetGE(FirstPayRec, Len, K, 0); {нижний предел}
    if (Res=0) and AbortBtn.Visible then
    begin
      Len := SizeOf(LastPayRec);
      Res := DocDataSet.BtrBase.GetLast(LastPayRec, Len, K, 0); {верхний предел}
      if Res=0 then
      begin
        {придвинемся к диапазону}
        K := 0;
        if IterPayDoc(FirstPayRec.dbIdHere, FirstPayRec, 1) then
          K := K + 1;
        if IterPayDoc(LastPayRec.dbIdHere, LastPayRec, 0) then
          K := K + 10;
        if FirstPayRec.dbIdHere<=LastPayRec.dbIdHere then
          K := K + 100;
        if FromDateS<=RDate(LastPayRec) then
          K := K + 1000;
        if ToDateS>=RDate(FirstPayRec) then
          K := K + 10000;
        if K=11111 then
        begin
          {showmessage('1='+btrdatetostr(rdate(FirstPayRec))+'-'+btrdatetostr(rdate(LastPayRec)));}
          StatusMessage('Поиск нижней границы...');
          FirstPayRecL := FirstPayRec;
          LastPayRecL := LastPayRec;
          K := -1;
          repeat
            J := K;
            K := (FirstPayRecL.dbIdHere + LastPayRecL.dbIdHere) div 2;
            if IterPayDoc(K, PayRec, 0) then
            begin
              K := PayRec.dbIdHere;
              if RDate(PayRec)>=FromDateS then
                LastPayRecL := PayRec
              else
                FirstPayRecL := PayRec;
            end;
            Application.ProcessMessages;
          until (J=K) or not AbortBtn.Visible;
          StatusMessage('Уточнение нижней границы...');
          K := 0;
          W := RDate(FirstPayRecL);
          while (K=0) and (W>=FromDateS) and AbortBtn.Visible do
          begin
            if IterPayDoc(FirstPayRecL.dbIdHere-1, PayRec, 0) then
            begin
              W := RDate(PayRec);
              if W>=FromDateS then
                FirstPayRecL := PayRec;
            end
            else
              K := 1;
            Application.ProcessMessages;
          end;
          FirstPayRec := FirstPayRecL;
          {showmessage('2='+btrdatetostr(rdate(FirstPayRec))+'-'+btrdatetostr(rdate(LastPayRec)));}
          if AbortBtn.Visible then
          begin
            StatusMessage('Поиск верхней границы...');
            FirstPayRecL := FirstPayRec;
            LastPayRecL := LastPayRec;
            K := -1;
            repeat
              J := K;
              K := (FirstPayRecL.dbIdHere + LastPayRecL.dbIdHere) div 2;
              if IterPayDoc(K, PayRec, 1) then
              begin
                K := PayRec.dbIdHere;
                if RDate(PayRec)<=ToDateS then
                  FirstPayRecL := PayRec
                else
                  LastPayRecL := PayRec;
              end;
              Application.ProcessMessages;
            until (J=K) or not AbortBtn.Visible;
            StatusMessage('Уточнение верхней границы...');
            K := 0;
            W := RDate(LastPayRecL);
            while (K=0) and (W<=ToDateS) and AbortBtn.Visible do
            begin
              if IterPayDoc(FirstPayRecL.dbIdHere+1, PayRec, 1) then
              begin
                W := RDate(PayRec);
                if W<=ToDateS then
                  LastPayRecL := PayRec;
              end
              else
                K := 1;
              Application.ProcessMessages;
            end;
            LastPayRec := LastPayRecL;
            {showmessage('3='+btrdatetostr(rdate(FirstPayRec))+'-'+btrdatetostr(rdate(LastPayRec)));}
            if AbortBtn.Visible then
            begin
              StatusMessage('Сбор статистики по документам...');
              InitProgress(FirstPayRec.dbIdHere, LastPayRec.dbIdHere);
              K := FirstPayRec.dbIdHere;
              Len := SizeOf(PayRec);
              Res := DocDataSet.BtrBase.GetGE(PayRec, Len, K, 0);
              while (Res=0) and (PayRec.dbIdHere<=LastPayRec.dbIdHere)
                and AbortBtn.Visible do
              begin
                if (PayRec.dbIdSender>0)
                  and (FromDate<=CritDate(PayRec)) and (CritDate(PayRec)<=ToDate) then
                begin
                  J := SearchCorr(PayRec.dbIdSender);
                  if J>=0 then
                  begin
                    CorrCollectPtr := CorrCollectList.Items[J];
                    with CorrCollectPtr^ do
                    begin
                      Inc(ccrInDocCount);
                      ccrDebSum := ccrDebSum + PayRec.dbDoc.drSum;
                    end;
                  end
                  else
                    {showmessage('не найден кор. id='+inttostr(J))};
                end;
                if (FirstPayRec.dbIdHere<=PayRec.dbIdHere)
                  and (PayRec.dbIdHere<=LastPayRec.dbIdHere)
                then
                  ProgressBar.Position := PayRec.dbIdHere;
                Application.ProcessMessages;
                Len := SizeOf(PayRec);
                Res := DocDataSet.BtrBase.GetNext(PayRec, Len, K, 0);
              end;
              FinishProgress;
              StatusMessage('');
            end;
          end;
        end
        else
          MessageBox(Handle, PChar('Дата должна быть в диапазоне '
            +BtrDateToStr(RDate(FirstPayRec))+'-'
            +BtrDateToStr(RDate(LastPayRec))+'  K='+IntToStr(K)), MesTitle,
            MB_OK or MB_ICONWARNING);
      end;
    end;
  finally
    Screen.Cursor := crDefault;
    AbortBtn.Hide;
  end;
  SortIndexComboBoxClick(nil);
end;

const
  fiIder    = 0;
  fiNode    = 1;
  fiLogin   = 2;
  fiType    = 3;
  fiLock    = 4;
  fiName    = 5;
  fiAccCount    = 6;
  fiInDocCount  = 7;
  fiOutDocCount = 8;
  fiDebSum      = 9;

procedure TAbonStatForm.SortIndexComboBoxClick(Sender: TObject);
var
  CorrCollectPtr: PCorrCollectRec;
  I, C, AccCount, InDocCount: Integer;
  SumDeb: comp;
  S: string;
begin
  RxMemoryData.EmptyTable;
  AbortBtn.Show;
  StatusMessage('Сортировка коллекции...');
  I := SortIndexComboBox.ItemIndex;
  if (I>=0) and (I<>SortIndex) then
  begin
    SortIndex := SortIndexComboBox.ItemIndex;
    CorrCollectList.Sort(CorrCollectCompare);
  end;
  StatusMessage('Заполнение таблицы...');
  I := 0;
  Screen.Cursor := crHourGlass;
  DataSource.Enabled := False;
  C := 0;
  AccCount := 0;
  InDocCount := 0;
  SumDeb := 0;
  while (I<CorrCollectList.Count) and AbortBtn.Visible do
  begin
    CorrCollectPtr := CorrCollectList.Items[I];
    if ShowBlockCheckBox.Checked or ((CorrCollectPtr^.ccrLock and 3)=0) then
      with RxMemoryData, CorrCollectPtr^ do
      begin
        Append;
        Fields.Fields[fiIder].AsInteger := ccrIder;
        Fields.Fields[fiNode].AsInteger := ccrNode;
        Fields.Fields[fiLogin].AsString := ccrLogin;
        if ccrType<>0 then
          Fields.Fields[fiType].AsString := 'О';
        case ccrLock of
          1:
            Fields.Fields[fiLock].AsString := '>';
          2:
            Fields.Fields[fiLock].AsString := '<';
          3:
            Fields.Fields[fiLock].AsString := 'Б';
        end;
        Fields.Fields[fiName].AsString := ccrName;
        Fields.Fields[fiAccCount].AsInteger := ccrAccCount;
        Fields.Fields[fiInDocCount].AsInteger := ccrInDocCount;
        Fields.Fields[fiOutDocCount].AsInteger := ccrOutDocCount;
        Fields.Fields[fiDebSum].AsString := SumToStr(ccrDebSum);
        Post;
        Inc(C);
        AccCount := AccCount + ccrAccCount;
        InDocCount := InDocCount + ccrInDocCount;
        SumDeb := SumDeb + ccrDebSum;
      end;
    Inc(I);
    Application.ProcessMessages;
  end;
  DataSource.Enabled := True;
  Screen.Cursor := crDefault;
  if AbortBtn.Visible then
  begin
    AbortBtn.Hide;
    StatusMessage('');
    S := BtrDateToStr(FromDate);
    if ToDate<>FromDate then
      S := S + '-' + BtrDateToStr(ToDate);
    SetVarior('asOtchDate', S);
    SetVarior('asAccCount', IntToStr(AccCount));
    SetVarior('asInDocCount', IntToStr(InDocCount));
    SetVarior('asSumDeb', SumToStr(SumDeb));
    SetVarior('asDate', DateToStr(Date));
    SetVarior('asTime', TimeToStr(Time));

    DebetEdit.Text := SumToStr(SumDeb);
    CreditEdit.Text := {SumToStr(TotalCredit)}'0';
    AccEdit.Text := SumToStr(AccCount);
    DocEdit.Text := SumToStr(InDocCount);
    ShowAcc(True);
  end
  else
    StatusMessage('Построение прервано');
end;

procedure TAbonStatForm.ViewItemClick(Sender: TObject);
var
  Ider, Len: Integer;
  pa: TAccRec;
  S: string;
begin
  if RxMemoryData.Active and (RxMemoryData.RecordCount>0) then
  begin
    Ider := RxMemoryData.Fields.Fields[fiIder].AsInteger;
    Len := SizeOf(pa);
    if AccDataSet.BtrBase.GetEqual(pa, Len, Ider, 0)=0 then
    begin
      S := Copy(pa.arAccount, 1, SizeOf(TAccount));
      {AccountsForm.DoMakes(@MakesAllForm, S, DateEdit.Date);}
    end;
  end;
end;

procedure TAbonStatForm.MaskComboBoxKeyPress(Sender: TObject;
  var Key: Char);
begin
  if not ((Key in ['0'..'9','?']) or (Key < #32)) then
  begin
    Key := #0;
    MessageBeep(0)
  end;
end;

end.
