unit MakesAllFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Grids, Db, DBTables, DBGrids, ExtCtrls, DBCtrls, BtrDS, Menus,
  StdCtrls, Buttons, ComCtrls, SearchFrm, Mask, ToolEdit, CommCons,
  RxMemDS, Btrieve, TimerLst, Common, Bases, Registr, Utilits, ClntCons;

type
  TMakesAllForm = class(TDataBaseForm)
    StatusBar: TStatusBar;
    BtnPanel: TPanel;
    DateEdit: TDateEdit;
    ProgressBar: TProgressBar;
    ChildMenu: TMainMenu;
    OperItem: TMenuItem;
    ViewItem: TMenuItem;
    EditBreaker: TMenuItem;
    FindItem: TMenuItem;
    MakeItem: TMenuItem;
    AbortBtn: TBitBtn;
    RxMemoryData: TRxMemoryData;
    DataSource: TDataSource;
    DBGrid: TDBGrid;
    FromDateLabel: TLabel;
    MakePopupMenu: TPopupMenu;
    DebetEdit: TEdit;
    DebetLabel: TLabel;
    CreditEdit: TEdit;
    CreditLabel: TLabel;
    RxMemoryDataNumber: TStringField;
    RxMemoryDataIder: TIntegerField;
    RxMemoryDataName: TStringField;
    ActiveEdit: TEdit;
    ActiveLabel: TLabel;
    PassiveLabel: TLabel;
    PassiveEdit: TEdit;
    AccShowGroupBox: TGroupBox;
    NullCheckBox: TCheckBox;
    NonWorkedCheckBox: TCheckBox;
    MaskComboBox: TComboBox;
    MaskLabel: TLabel;
    SearchIndexComboBox: TComboBox;
    NameLabel: TLabel;
    RxMemoryDataDebet: TStringField;
    RxMemoryDataCredit: TStringField;
    RxMemoryDataAmount: TStringField;
    RxMemoryDataBillAmount: TStringField;
    RxMemoryDataPassive: TStringField;
    PrintAllItem: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure StringGridDrawCell(Sender: TObject; ACol, ARow: Integer;
      ARect: TRect; AState: TGridDrawState);
    procedure ViewItemClick(Sender: TObject);
    procedure FindItemClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure DateEditAcceptDate(Sender: TObject; var ADate: TDateTime;
      var Action: Boolean);
    procedure AbortBtnClick(Sender: TObject);
    procedure MakeItemClick(Sender: TObject);
    procedure DateEditExit(Sender: TObject);
    procedure DateEditChange(Sender: TObject);
    procedure MaskComboBoxKeyPress(Sender: TObject; var Key: Char);
    procedure NullCheckBoxClick(Sender: TObject);
    procedure MaskComboBoxClick(Sender: TObject);
    procedure MaskComboBoxChange(Sender: TObject);
    procedure SearchIndexComboBoxClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure PrintAllItemClick(Sender: TObject);
  private
    AccDataSet, AccArcDataSet, BillDataSet, DocDataSet: TExtBtrDataSet;
    procedure WMMakeStatement(var Message: TMessage); message WM_MAKESTATEMENT;
    procedure FillAccTable;
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
  MakesAllForm: TMakesAllForm;

implementation

uses AccountsFrm, MakesFrm;

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

procedure TMakesAllForm.TakeTabPrintData(var PrintDocRec: TPrintDocRec; var FormList: TList);
begin
  inherited;
  PrintDocRec.DBGrid := Self.DBGrid;
  PrintDocRec.GraphForm := DecodeMask('$(AccSheetGraphForm)', 5, CommonUserNumber);
  PrintDocRec.TextForm := DecodeMask('$(AccSheetTextForm)', 5, CommonUserNumber);
end;

const
  MaxAcc = 1000;
  ModuleTitle: PChar = 'Ведомость остатков';
  DataIsChanged: Boolean = False;
var
  AccList: TAccList = nil;

procedure TMakesAllForm.FormCreate(Sender: TObject);
const
  Border=2;
var
  W: Word;
begin
  W := GetPrevWorkDay(DateToBtrDate(Date), nil);
  if W=0 then
    DateEdit.Date := Date
  else
    DateEdit.Date := BtrDateToDate(W);
  
  AccList := TAccList.Create;
  with ProgressBar do
  begin
    Parent := StatusBar;
    SetBounds(0, Border, Width, StatusBar.Height - Border);
  end;
  DefineGridCaptions(DBGrid, PatternDir+'MakesAll.tab');

  SearchForm := TSearchForm.Create(Self);
  SearchForm.SourceDBGrid := DBGrid;

  AccDataSet := GlobalBase(biAcc);
  AccArcDataSet := GlobalBase(biAccArc);
  BillDataSet := GlobalBase(biBill);
  DocDataSet := GlobalBase(biPay);

  TakeMenuItems(OperItem, MakePopupMenu.Items);
  MakePopupMenu.Images := ChildMenu.Images;
end;

procedure TMakesAllForm.FormDestroy(Sender: TObject);
begin
  MakesAllForm := nil;
  AccList.Free;
end;

procedure TMakesAllForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
end;

procedure TMakesAllForm.StatusMessage(S: string);
begin
  StatusBar.Panels[1].Text := S;
end;

procedure TMakesAllForm.InitProgress(AMin, AMax: Integer);
const
  Border=2;
begin
  with ProgressBar do
  begin
    StatusBar.Panels[0].Width := Width;
    Min := AMin;
    Max := AMax;
    Position := AMin;
    Show;
  end;
end;

procedure TMakesAllForm.FinishProgress;
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

const
  fiNumber  = 0;
  fiName    = 1;
  fiIder    = 2;
  fiDebet   = 3;
  fiCredit  = 4;
  fiActive     = 5;
  fiPassive     = 6;
  fiBillAmount = 7;
var
  TotalAct, TotalPas, TotalDebet, TotalCredit: comp;
  MaskChanged: Boolean = True;

procedure TMakesAllForm.FillAccTable;
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
            if acOutOst<0 then
              Fields.Fields[fiActive].AsString := SumToStr(-acOutOst)
            else
              Fields.Fields[fiPassive].AsString := SumToStr(acOutOst);
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
end;

procedure TMakesAllForm.StringGridDrawCell(Sender: TObject; ACol,
  ARow: Integer; ARect: TRect; AState: TGridDrawState);
begin
  if ACol=0 then
    with Sender as TStringGrid do
    begin
      Canvas.Brush.Color := clBtnFace;
      Canvas.FillRect(ARect);
    end;
end;

procedure TMakesAllForm.ViewItemClick(Sender: TObject);
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
      AccountsForm.DoMakes(@MakesAllForm, S, DateEdit.Date);
    end;
  end;
end;

procedure TMakesAllForm.PrintAllItemClick(Sender: TObject);
var
  Ider, Len: Integer;
  pa: TAccRec;
  S: string;
begin
  if RxMemoryData.Active and (RxMemoryData.RecordCount>0) then
  begin
    RxMemoryData.First;
    if MakesForm = nil then
      MakesForm := TMakesForm.Create(Self);
    MakesForm.TotalPrinting := True;
    while not RxMemoryData.Eof do
    begin
      Ider := RxMemoryData.Fields.Fields[fiIder].AsInteger;
      Len := SizeOf(pa);
      if AccDataSet.BtrBase.GetEqual(pa, Len, Ider, 0)=0 then
      begin
        S := Copy(pa.arAccount, 1, SizeOf(TAccount));
        AccountsForm.DoMakes(@MakesAllForm, S, DateEdit.Date);
        Application.ProcessMessages;
        PostMessage(Application.MainForm.Handle, WM_PRINTTABLE, 0, 0);
        Application.ProcessMessages;
      end;
      RxMemoryData.Next;
    end;
    MakesForm.TotalPrinting := False;
  end;
end;

procedure TMakesAllForm.FindItemClick(Sender: TObject);
begin
  SearchForm.ShowModal;
end;

procedure TMakesAllForm.DateEditAcceptDate(Sender: TObject;
  var ADate: TDateTime; var Action: Boolean);
begin
  Action := True;
  DateEdit.Date := ADate;
  ShowAcc(False);
  PostMessage(Handle, WM_MAKESTATEMENT, 0, 0);
  DataIsChanged := False;
end;

procedure TMakesAllForm.DateEditChange(Sender: TObject);
begin
  DataIsChanged := True;
end;

procedure TMakesAllForm.DateEditExit(Sender: TObject);
var
  Action: Boolean;
  ADate: TDateTime;
begin
  if DataIsChanged then
  begin
    ADate := DateEdit.Date;
    Action := True;
    DateEditAcceptDate(Sender, ADate, Action);
  end;
end;

procedure TMakesAllForm.AbortBtnClick(Sender: TObject);
begin
  AbortBtn.Visible := False;
end;

procedure TMakesAllForm.ShowAcc(Value: Boolean);
begin
  DebetEdit.Visible := Value;
  DebetLabel.Visible := Value;
  CreditEdit.Visible := Value;
  CreditLabel.Visible := Value;
  ActiveEdit.Visible := Value;
  ActiveLabel.Visible := Value;
  PassiveEdit.Visible := Value;
  PassiveLabel.Visible := Value;
  if not Value then
    RxMemoryData.EmptyTable;
end;

const
  SortIndex: Integer = 0;

{function CompareResortedAcc(a1, a2: TAccount): Integer;
begin
  Result := 0;
  ReSortAcc(a1);
  ReSortAcc(a2);
  if a1<a2 then
    Result := -1
  else
    if a1>a2 then
      Result := 1;
end;}

function AccColOnDayCompare(Key1, Key2: Pointer): Integer;
var
  k1: PAccColOnDayRec absolute Key1;
  k2: PAccColOnDayRec absolute Key2;
  s1, s2: Comp;
begin
  Result := 0;
  case SortIndex of
    {1:
      Result := CompareResortedAcc(k1^.acNumber, k2^.acNumber);}
    2:
      begin
        s1 := k1^.acDebet + k1^.acCredit;
        s2 := k2^.acDebet + k2^.acCredit;
        if s1>s2 then
          Result := -1
        else
          if s1<s2 then
            Result := 1;
      end;
    else
      begin
        if k1^.acNumber<k2^.acNumber then
          Result := -1
        else
          if k1^.acNumber>k2^.acNumber then
            Result := 1;
      end;
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

procedure TMakesAllForm.WMMakeStatement(var Message: TMessage);
begin
  MakeItemClick(Self);
end;

procedure TMakesAllForm.MakeItemClick(Sender: TObject);
const
  MesTitle: PChar = 'Формирование ведомости';
var
  Key0: longint;
  KeyAA:
    record
      aaIder: longint;
      aaDate: word;
    end;
  KeyO: word;
  pa: TAccRec;
  paa: TAccArcRec;
  po: TOpRec;
  t: comp;
  pac: PAccColOnDayRec;
  I, Len, Res: Integer;
  OtchDate, MinDate, MaxDate: word;
  Acc: array[0..SizeOf(TAccount)] of Char;
begin
  try
    Screen.Cursor := crHourGlass;
    OtchDate := DateToBtrDate(DateEdit.Date);
    AbortBtn.Show;
    AccList.Clear;
    StatusMessage('Инициализация списка открытых счетов...');
    { Инициализация списка счетов }
    MaxDate := 0;
    MinDate := $FFFF;
    Len := SizeOf(pa);
    Res := AccDataSet.BtrBase.GetFirst(pa, Len, Key0, 0);
    while (Res=0) and AbortBtn.Visible do
    begin
      if DateIsActive(OtchDate, pa.arDateO, pa.arDateC) then
      begin
        pac := New(PAccColOnDayRec);
        pac^.acNumber := pa.arAccount;
        pac^.acIder := pa.arIder;
        pac^.acFDate := pa.arDateO;
        pac^.acTDate := pa.arDateC;
        if pac^.acTDate=0 then
          pac^.acTDate := $FFFF;
        pac^.acOpCnt := 0;
        pac^.acInOst := pa.arSumS;
        pac^.acOutOst := pa.arSumA;
        pac^.acDebet := 0.0;
        pac^.acCredit := 0.0;
        KeyAA.aaIder := pa.arIder;
        KeyAA.aaDate := OtchDate;
        Len := SizeOf(paa);
        Res := AccArcDataSet.BtrBase.GetLT(paa, Len, KeyAA, 1);
        if (Res=0) and (paa.aaIder=pa.arIder) and (pac^.acFDate<paa.aaDate) then
        begin
          pac^.acFDate := paa.aaDate;
          pac^.acInOst := paa.aaSum;
        end;
        KeyAA.aaIder := pa.arIder;
        KeyAA.aaDate := OtchDate;
        Len := SizeOf(paa);
        Res := AccArcDataSet.BtrBase.GetGE(paa, Len, KeyAA, 1);
        if (Res=0) and (paa.aaIder=pa.arIder) and
           (pac^.acTDate>paa.aaDate) then
        begin
          pac^.acTDate := paa.aaDate;
          pac^.acOutOst := paa.aaSum;
        end;
        if pac^.acFDate<MinDate then
          MinDate := pac^.acFDate;
        if pac^.acTDate>MaxDate then
          MaxDate := pac^.acTDate;
        AccList.Add(pac);
      end;
      Len := SizeOf(pa);
      Res := AccDataSet.BtrBase.GetNext(pa, Len, Key0, 0);
      Application.ProcessMessages;
    end;
    StatusMessage('');
    if AccList.Count>0 then
    begin
      StatusMessage('Просчет остатков по выпискам...');
      I := SortIndex;
      try
        SortIndex := 0;
        AccList.Sort(AccColOnDayCompare);
      finally
        SortIndex := I;
      end;
      KeyO := MinDate;
      Len := SizeOf(po);
      Res := BillDataSet.BtrBase.GetGT(po, Len, KeyO, 2);
      while (Res=0) and (po.brDate<=MaxDate) and AbortBtn.Visible do
      begin
        if (po.brDel=0) and (po.brPrizn=brtBill) then
        begin
          i := AccList.SearchAcc(po.brAccD);
          if i>=0 then
          begin
            pac := AccList.Items[i];
            if (po.brDate>pac^.acFDate) and (po.brDate<=pac^.acTDate) then
            begin
              if po.brDate<OtchDate then
                pac^.acInOst := pac^.acInOst-po.brSum
              else
                if po.brDate>OtchDate then
                  pac^.acOutOst := pac^.acOutOst+po.brSum
                else begin
                  pac^.acDebet := pac^.acDebet+po.brSum;
                  if po.brType=1 then
                    pac^.acOpCnt := pac^.acOpCnt+1;
                end;
            end;
          end;
          i := AccList.SearchAcc(po.brAccC);
          if i >= 0 then
          begin
            pac := AccList.Items[i];
            if (po.brDate>pac^.acFDate) and (po.brDate<=pac^.acTDate) then
            begin
              if po.brDate<OtchDate then
                pac^.acInOst := pac^.acInOst+po.brSum
              else
                if po.brDate>OtchDate then
                  pac^.acOutOst := pac^.acOutOst-po.brSum
                else begin
                  pac^.acCredit := pac^.acCredit+po.brSum;
                end;
            end;
          end;
        end;
        Len := SizeOf(po);
        Res := BillDataSet.BtrBase.GetNext(po,Len,KeyO,2);
        Application.ProcessMessages;
      end;
      if AbortBtn.Visible then
      begin
        StatusMessage('Проверка соответствия состояний счетов...');
        {Проверка соответствия состояний счетов просчитанным по выпискам }
        TotalAct := 0.0;
        TotalPas := 0.0;
        TotalDebet := 0.0;
        TotalCredit := 0.0;
        i := 0;
        while (i<AccList.Count) and AbortBtn.Visible do
        begin
          pac := AccList.Items[i];
          if pac^.acOutOst<0 then
            TotalAct := TotalAct - pac^.acOutOst
          else
            TotalPas := TotalPas + pac^.acOutOst;
          TotalDebet := TotalDebet + pac^.acDebet;
          TotalCredit := TotalCredit + pac^.acCredit;
          t := pac^.acInOst+pac^.acCredit-pac^.acDebet;
          if t<>pac^.acOutOst then
          begin
            StrLCopy(Acc, pac^.acNumber, SizeOf(TAccount));
            MessageBox(Handle, PChar('Ошибка остатка по счету '+StrPas(Acc)+
              ' на сумму '+SumToStr(t-pac^.acOutOst)), MesTitle,
              MB_OK or MB_ICONWARNING);
          end;
          Inc(i);
          Application.ProcessMessages;
        end;
        AbortBtn.Hide;
        with AccList do
        begin
          SetVarior('acOtchDate', BtrDateToStr(OtchDate));
          SetVarior('acAccCount', IntToStr(AccList.Count));
          SetVarior('acTotalDebet', SumToStr(TotalDebet));
          SetVarior('acTotalCredit', SumToStr(TotalCredit));
          SetVarior('acTotalAct', SumToStr(TotalAct));
          SetVarior('acTotalPas', SumToStr(TotalPas));
          SetVarior('acDate', DateToStr(Date));
          SetVarior('acTime', TimeToStr(Time));

          DebetEdit.Text := SumToStr(TotalDebet);
          CreditEdit.Text := SumToStr(TotalCredit);
          ActiveEdit.Text := SumToStr(TotalAct);
          PassiveEdit.Text := SumToStr(TotalPas)
        end;
        ShowAcc(True);
        SearchIndexComboBoxClick(nil);
      end
      else begin
        StatusMessage('Построение выписки прервано');
        AbortBtn.Hide;
      end;
    end
    else begin
      MessageBox(Handle, 'На указанную дату нет открытых счетов', MesTitle,
        MB_OK or MB_ICONINFORMATION);
      AbortBtn.Hide;
    end;
  finally
    Screen.Cursor := crDefault;
    AbortBtn.Hide;
  end;
end;

procedure TMakesAllForm.MaskComboBoxKeyPress(Sender: TObject;
  var Key: Char);
begin
  if not ((Key in ['0'..'9','?']) or (Key < #32)) then
  begin
    Key := #0;
    MessageBeep(0)
  end;
end;

procedure TMakesAllForm.NullCheckBoxClick(Sender: TObject);
begin
  FillAccTable;
end;

procedure TMakesAllForm.MaskComboBoxChange(Sender: TObject);
begin
  MaskChanged := True;
end;

procedure TMakesAllForm.MaskComboBoxClick(Sender: TObject);
begin
  if MaskChanged then
    NullCheckBoxClick(nil);
end;

procedure TMakesAllForm.SearchIndexComboBoxClick(Sender: TObject);
begin
  MaskComboBox.Enabled := False;
  if SearchIndexComboBox.Enabled then
  begin
    if SearchIndexComboBox.ItemIndex<0 then
      SearchIndexComboBox.ItemIndex := 1;
    Screen.Cursor := crHourGlass;
    try
      SortIndex := SearchIndexComboBox.ItemIndex;
      StatusMessage('Упорядочевание списка...');
      Application.ProcessMessages;
      AccList.Sort(AccColOnDayCompare);
      StatusMessage('');
      FillAccTable;
      MaskComboBox.Enabled := True;
    finally
      Screen.Cursor := crDefault;
    end;
  end;
end;

procedure TMakesAllForm.FormShow(Sender: TObject);
begin
  MakeItemClick(Sender);
  DataIsChanged := False;
end;

end.
