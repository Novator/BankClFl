unit AccWorkFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Grids, Db, DBTables, DBGrids, ExtCtrls, DBCtrls, BtrDS, Menus,
  StdCtrls, Buttons, ComCtrls, SearchFrm, Mask, ToolEdit, Orakle, ShellApi,
  RxMemDS, Btrieve, Common, Basbn, Registr, Utilits, CommCons, BUtilits,
  WideComboBox;

type
  TAccWorkForm = class(TDataBaseForm)
    StatusBar: TStatusBar;
    BtnPanel: TPanel;
    ProgressBar: TProgressBar;
    AbortBtn: TBitBtn;
    RxMemoryData: TRxMemoryData;
    DataSource: TDataSource;
    DBGrid: TDBGrid;
    MakePopupMenu: TPopupMenu;
    RxMemoryDataNumber: TStringField;
    RxMemoryDataIder: TIntegerField;
    RxMemoryDataName: TStringField;
    MaskComboBox: TComboBox;
    MaskLabel: TLabel;
    SearchIndexComboBox: TComboBox;
    NameLabel: TLabel;
    RxMemoryDataSumma: TFloatField;
    RxMemoryDataType: TStringField;
    RxMemoryDataCorr: TStringField;
    RxMemoryDataBankOper: TStringField;
    EditMenu: TMainMenu;
    OperItem: TMenuItem;
    TrasitItem: TMenuItem;
    FuncBreaker: TMenuItem;
    FindItem: TMenuItem;
    FuncBreaker2: TMenuItem;
    MakeItem: TMenuItem;
    MakesItem: TMenuItem;
    DateEdit: TDateEdit;
    DateLabel: TLabel;
    UserCodeCheckBox: TCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure StringGridDrawCell(Sender: TObject; ACol, ARow: Integer;
      ARect: TRect; AState: TGridDrawState);
    procedure ViewItemClick(Sender: TObject);
    procedure FindItemClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure AbortBtnClick(Sender: TObject);
    procedure MakeItemClick(Sender: TObject);
    procedure MaskComboBoxKeyPress(Sender: TObject; var Key: Char);
    procedure MaskComboBoxClick(Sender: TObject);
    procedure MaskComboBoxChange(Sender: TObject);
    procedure SearchIndexComboBoxClick(Sender: TObject);
    procedure MaskComboBoxExit(Sender: TObject);
    procedure TrasitItemClick(Sender: TObject);
    procedure MakesItemClick(Sender: TObject);
    procedure DateEditAcceptDate(Sender: TObject; var ADate: TDateTime;
      var Action: Boolean);
    procedure UserNameCodePanelMouseDown(Sender: TObject;
      Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure UserNameCodePanelMouseUp(Sender: TObject;
      Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure FormShow(Sender: TObject);
  private
    AccList: TList;
    AccDataSet: TExtBtrDataSet;
    BaseIsOpened: Boolean;
    procedure WMMakeStatement(var Message: TMessage); message WM_MAKESTATEMENT;
    procedure FillAccTable;
  protected
    procedure StatusMessage(S: string);
    procedure InitProgress(AMin, AMax: Integer);
    procedure FinishProgress;
    function UserCodeToUserName(UserCode: Integer): string;
  public
    SearchForm: TSearchForm;
    procedure TakeTabPrintData(var PrintDocRec: TPrintDocRec; var FormList: TList); override;
  end;

var
  AccWorkForm: TAccWorkForm;

implementation

uses AccountsFrm;


{$R *.DFM}

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

procedure TAccWorkForm.TakeTabPrintData(var PrintDocRec: TPrintDocRec; var FormList: TList);
begin
  inherited;
  PrintDocRec.DBGrid := Self.DBGrid;
  PrintDocRec.GraphForm := DecodeMask('$(AccWorkGraphForm)', 5, GetUserNumber);
  PrintDocRec.TextForm := DecodeMask('$(AccWorkTextForm)', 5, GetUserNumber);
  //PrintDocRec.GraphForm := DecodeMask('$(AccWorkGraphForm)', 5, GetUserNumber);
  //PrintDocRec.TextForm := DecodeMask('$(AccWorkTextForm)', 5, GetUserNumber);
end;

const
  WorkIndex: Integer = 0;

procedure TAccWorkForm.FormCreate(Sender: TObject);
const
  Border=2;
var
  W: Word;
begin
  W := GetPrevWorkDay(DateToBtrDate(Date));
  if W=0 then
    DateEdit.Date := Date
  else
    DateEdit.Date := BtrDateToDate(W);
  AccList := TList.Create;
  with ProgressBar do
  begin
    Parent := StatusBar;
    SetBounds(0, Border, Width, StatusBar.Height - Border);
  end;
  DefineGridCaptions(DBGrid, PatternDir+'AccWork.tab');

  if not GetRegParamByName('WorkIndex', GetUserNumber, WorkIndex) then
    WorkIndex := 1;

  SearchForm:=TSearchForm.Create(Self);
  SearchForm.SourceDBGrid := DBGrid;

  AccDataSet := GlobalBase(biAcc);

  TakeMenuItems(OperItem, MakePopupMenu.Items);
  MakePopupMenu.Images := EditMenu.Images;
end;

procedure TAccWorkForm.FormDestroy(Sender: TObject);
begin
  AccWorkForm := nil;
  ClearList(AccList);
  AccList.Free;
end;

procedure TAccWorkForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
end;

procedure TAccWorkForm.StatusMessage(S: string);
begin
  StatusBar.Panels[1].Text := S;
end;

procedure TAccWorkForm.InitProgress(AMin, AMax: Integer);
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

procedure TAccWorkForm.FinishProgress;
begin
  ProgressBar.Hide;
  StatusBar.Panels[0].Width := 0;
end;

type
  PAccInfoRec = ^TAccInfoRec;
  TAccInfoRec = record
    aiNumber: TAccount;
    aiIder:   Integer;
    aiName:   TKeeperName;
    aiSumma:  Comp;
    aiState:  Word;
    aiCorr:   Integer;
    aiBankOper:   Integer;
  end;

const
  NumberIndex=0;
  NameIndex=1;
  IderIndex=2;
  SummaIndex=3;
  TypeIndex=4;
  CorrIndex=5;
  BankOperIndex=6;
var
  TotalAct, TotalPas, TotalDebet, TotalCredit: comp;
  MaskChanged: Boolean = True;

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

const
  AccTypeNames: array[0..2] of PChar = ('П', 'А', 'С');

function TAccWorkForm.UserCodeToUserName(UserCode: Integer): string;
begin
  if UserCodeCheckBox.Checked then
  begin
    Result := GetUserNameByCode(UserCode);
    if Result='' then
      Result := '['+IntToStr(UserCode)+']';
  end
  else
    Result := IntToStr(UserCode);
end;

procedure TAccWorkForm.FillAccTable;
var
  Key0: longint;
  I, Len, Res, C: Integer;
  Buf: array[0..512] of Char;
  PAccInfo: PAccInfoRec;
  pa: TAccRec;
  FullMask: Boolean;
begin
  RxMemoryData.EmptyTable;
  try
    while Length(MaskComboBox.Text)<SizeOf(TAccount) do
      MaskComboBox.Text := MaskComboBox.Text + '?';
    I := 1;
    while (I<=SizeOf(TAccount)) and (MaskComboBox.Text[I]='?') do
      Inc(I);
    FullMask := I>SizeOf(TAccount);
    StatusMessage('Показ списка...');
    InitProgress(0, AccList.Count);
    C := 0;
    I := 0;
    AbortBtn.Show;
    DBGrid.Hide;
    while (I<AccList.Count) and AbortBtn.Visible do
    begin
      PAccInfo := AccList.Items[I];
      with PAccInfo^ do
      begin
        if FullMask or Masked(aiNumber, MaskComboBox.Text) then
        begin
          with RxMemoryData do
          begin
            Append;
            Fields.Fields[NumberIndex].AsString := StrPas(aiNumber);
            Fields.Fields[NameIndex].AsString := aiName;
            Fields.Fields[IderIndex].AsInteger := aiIder;
            Fields.Fields[SummaIndex].AsFloat := aiSumma;
            Fields.Fields[TypeIndex].AsString := AccTypeNames[aiState and 3];
            Fields.Fields[CorrIndex].AsString := IntToStr(aiCorr);
            if RxMemoryDataBankOper.Visible then
              Fields.Fields[BankOperIndex].AsString := UserCodeToUserName(aiBankOper)
            else
              Fields.Fields[BankOperIndex].AsString := '';
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
    AbortBtn.Hide;
    DBGrid.Show;
    FinishProgress;
    I := AccList.Count;
    if C<I then
      StatusMessage('Показано счетов '+IntToStr(C)+' из '+IntToStr(I))
    else
      StatusMessage('');
  end;
end;

procedure TAccWorkForm.StringGridDrawCell(Sender: TObject; ACol,
  ARow: Integer; ARect: TRect; AState: TGridDrawState);
begin
  if ACol=0 then
    with Sender as TStringGrid do
    begin
      Canvas.Brush.Color := clBtnFace;
      Canvas.FillRect(ARect);
    end;
end;

procedure TAccWorkForm.ViewItemClick(Sender: TObject);
var
  Ider, Len, Res: Integer;
  pa: TAccRec;
  A: Boolean;
  ADate: TDateTime;
begin
  (*if RxMemoryData.Active and (RxMemoryData.RecordCount>0) then
  begin
    Ider := RxMemoryData.Fields.Fields[IderIndex].AsInteger;
    Len := SizeOf(pa);
    if AccDataSet.BtrBase.GetEqual(pa, Len, Ider, 0)=0 then
    begin
      if MakesForm = nil then
        MakesForm := TMakesForm.Create(PaydocsForm);
      with MakesForm do
      begin
        Show;
        if not OneDayItem.Checked then
          OneDayItemClick(nil);
        A := True;
        ADate := DateEdit.Date;
        FromDateEditAcceptDate(Sender, ADate, A);

        Ider := AccComboBox.Items.IndexOf(pa.arAccount);
        if Ider<0 then
          MessageBox(Handle, PChar('Счет ['+pa.arAccount+'] не найден'),
            'Запрос выписки', MB_OK or MB_ICONWARNING);
        begin
          AccComboBox.ItemIndex := Ider;
          PostMessage(MakesForm.Handle, WM_MAKESTATEMENT, 0, 0);
        end;
      end;
    end;
  end;*)
end;

procedure TAccWorkForm.FindItemClick(Sender: TObject);
begin
  SearchForm.ShowModal;
end;

procedure TAccWorkForm.AbortBtnClick(Sender: TObject);
begin
  AbortBtn.Visible := False;
end;

const
  SortIndex: Integer = 0;

function AccInfoCompare(Key1, Key2: Pointer): Integer;
var
  k1: PAccInfoRec absolute Key1;
  k2: PAccInfoRec absolute Key2;
begin
  Result := 0;
  if SortIndex=2 then
  begin
    if k1^.aiCorr<k2^.aiCorr then
      Result := -1
    else
    if k1^.aiCorr>k2^.aiCorr then
      Result := 1;
  end
  else
  if SortIndex=3 then
  begin
    if k1^.aiBankOper<k2^.aiBankOper then
      Result := -1
    else
    if k1^.aiBankOper>k2^.aiBankOper then
      Result := 1;
  end;
  if Result=0 then
  begin
    case SortIndex of
      1:
        Result := CompareResortedAcc(k1^.aiNumber, k2^.aiNumber);
      else
        begin
          if k1^.aiNumber<k2^.aiNumber then
            Result := -1
          else
            if k1^.aiNumber>k2^.aiNumber then
              Result := 1;
        end;
    end;
  end;
end;

procedure TAccWorkForm.WMMakeStatement(var Message: TMessage);
begin
  MakeItemClick(Self);
end;

procedure TAccWorkForm.FormShow(Sender: TObject);
begin
  MakeItemClick(Self);
end;

procedure TAccWorkForm.MakeItemClick(Sender: TObject);
const
  MesTitle: PChar = 'Формирование списка';
var
  Key0: longint;
  pa: TAccRec;
  pai: PAccInfoRec;
  I, Len, Res: Integer;
  BtrDate: Word;
  AccNum, CurrCode: ShortString;
  UserCode: Integer;
begin
  try
    BtrDate := DateToBtrDate(DateEdit.Date);
    DateEdit.Enabled := False;
    Screen.Cursor := crHourGlass;
    SearchIndexComboBox.Enabled := False;
    AbortBtn.Show;
    ClearList(AccList);
    StatusMessage('Формирование списка открытых счетов...');
    { Инициализация списка счетов }
    Len := SizeOf(pa);
    Res := AccDataSet.BtrBase.GetFirst(pa, Len, Key0, 0);
    while (Res=0) and AbortBtn.Visible do
    begin
      if DateIsActive(BtrDate, pa.arDateO, pa.arDateC) then
      begin
        pai := New(PAccInfoRec);
        with pai^ do
        begin
          aiNumber := pa.arAccount;
          aiIder := pa.arIder;
          aiName := pa.arName;
          DosToWin(aiName);
          aiSumma := pa.arSumA*0.01;
          aiState := pa.arOpts;
          aiCorr := pa.arCorr;
          if RxMemoryDataBankOper.Visible then
          begin
            OrGetAccAndCurrByNewAcc(aiNumber, AccNum, CurrCode, UserCode);
            aiBankOper := UserCode;
          end
          else
            aiBankOper := 0;
        end;
        AccList.Add(pai);
      end;
      Len := SizeOf(pa);
      Res := AccDataSet.BtrBase.GetNext(pa,Len,Key0,0);
      Application.ProcessMessages;
    end;
    StatusMessage('');
    if AbortBtn.Visible then
      SearchIndexComboBox.Enabled := True
    else
      StatusMessage('Построение списка прервано');
    AbortBtn.Hide;
    SearchIndexComboBoxClick(nil);
  finally
    Screen.Cursor := crDefault;
    AbortBtn.Hide;
    DateEdit.Enabled := True;
  end;
end;

procedure TAccWorkForm.MaskComboBoxKeyPress(Sender: TObject;
  var Key: Char);
begin
  if not ((Key in ['0'..'9','?']) or (Key < #32)) then
  begin
    Key := #0;
    MessageBeep(0)
  end;
end;

var
  NeedRebuild: Boolean = False;

procedure TAccWorkForm.MaskComboBoxChange(Sender: TObject);
begin
  MaskChanged := True;
  if NeedRebuild then
  begin
    NeedRebuild := False;
    MaskComboBoxExit(nil);
  end;
end;

procedure TAccWorkForm.MaskComboBoxClick(Sender: TObject);
begin
  NeedRebuild := True;
end;

procedure TAccWorkForm.MaskComboBoxExit(Sender: TObject);
begin
  if MaskChanged then
    FillAccTable;
end;

procedure TAccWorkForm.SearchIndexComboBoxClick(Sender: TObject);
begin
  RxMemoryData.EmptyTable;
  MaskComboBox.Enabled := False;
  if SearchIndexComboBox.Enabled then
  begin
    if SearchIndexComboBox.ItemIndex<0 then
      SearchIndexComboBox.ItemIndex := WorkIndex;
    Screen.Cursor := crHourGlass;
    try
      SortIndex := SearchIndexComboBox.ItemIndex;
      StatusMessage('Упорядочевание списка...');
      Application.ProcessMessages;
      AccList.Sort(AccInfoCompare);
      StatusMessage('');
      FillAccTable;
      MaskComboBox.Enabled := True;
    finally
      Screen.Cursor := crDefault;
    end;
  end;
end;

procedure TAccWorkForm.TrasitItemClick(Sender: TObject);
begin
  with AccountsForm do
  begin
    if SearchIndexComboBox.ItemIndex<>1 then
    begin
      SearchIndexComboBox.ItemIndex := 1;
      SearchIndexComboBoxClick(nil);
    end;
    AccComboBox.Text := RxMemoryData.Fields.Fields[NumberIndex].AsString;
    AccComboBoxChange(nil);
    Show;
  end;
end;

procedure TAccWorkForm.MakesItemClick(Sender: TObject);
begin
  AccountsForm.DoMakes(@AccWorkForm, RxMemoryData.Fields.Fields[NumberIndex].AsString,
    AccountsForm.DateEdit.Date);
end;

procedure TAccWorkForm.DateEditAcceptDate(Sender: TObject;
  var ADate: TDateTime; var Action: Boolean);
begin
  DateEdit.Date := ADate;
  MakeItemClick(nil);
end;

procedure TAccWorkForm.UserNameCodePanelMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  (Sender as TPanel).BevelOuter := bvLowered;
end;

procedure TAccWorkForm.UserNameCodePanelMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  (Sender as TPanel).BevelOuter := bvRaised;
end;

end.
