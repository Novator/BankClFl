unit AccWorkFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Grids, Db, DBTables, DBGrids, ExtCtrls, DBCtrls, BtrDS, Menus,
  StdCtrls, Buttons, ComCtrls, SearchFrm, Mask, ToolEdit,
  RxMemDS, Btrieve, Common, Bases, Registr, Utilits, CommCons;

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
    EditMenu: TMainMenu;
    OperItem: TMenuItem;
    FuncBreaker: TMenuItem;
    FindItem: TMenuItem;
    FuncBreaker2: TMenuItem;
    MakeItem: TMenuItem;
    MakesItem: TMenuItem;
    DateEdit: TDateEdit;
    DateLabel: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure StringGridDrawCell(Sender: TObject; ACol, ARow: Integer;
      ARect: TRect; AState: TGridDrawState);
    procedure FindItemClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure AbortBtnClick(Sender: TObject);
    procedure MakeItemClick(Sender: TObject);
    procedure MaskComboBoxKeyPress(Sender: TObject; var Key: Char);
    procedure MaskComboBoxClick(Sender: TObject);
    procedure MaskComboBoxChange(Sender: TObject);
    procedure SearchIndexComboBoxClick(Sender: TObject);
    procedure MaskComboBoxExit(Sender: TObject);
    procedure MakesItemClick(Sender: TObject);
    procedure DateEditAcceptDate(Sender: TObject; var ADate: TDateTime;
      var Action: Boolean);
  private
    AccList: TList;
    AccDataSet: TExtBtrDataSet;
    procedure WMMakeStatement(var Message: TMessage); message WM_MAKESTATEMENT;
    procedure FillAccTable;
  protected
    procedure StatusMessage(S: string);
    procedure InitProgress(AMin, AMax: Integer);
    procedure FinishProgress;
  public
    SearchForm: TSearchForm;
    {procedure TakeTabPrintData(var GraphTab, TextTab: TFileName;
      var DBGrid: TDBGrid); override;}
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

{procedure TAccWorkForm.TakeTabPrintData(var GraphTab, TextTab: TFileName;
  var DBGrid: TDBGrid);
begin
  inherited TakeTabPrintData(GraphTab, TextTab, DBGrid);
  DBGrid := Self.DBGrid;
  GraphTab := DecodeMask('$(AccSheetGraphForm)', 5);
  TextTab := DecodeMask('$(AccSheetTextForm)', 5);
end;}

const
  WorkIndex: Integer = 0;

procedure TAccWorkForm.FormCreate(Sender: TObject);
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
  AccList := TList.Create;
  with ProgressBar do
  begin
    Parent := StatusBar;
    SetBounds(0, Border, Width, StatusBar.Height - Border);
  end;
  DefineGridCaptions(DBGrid, PatternDir+'AccWork.tab');

  if not GetRegParamByName('WorkIndex', CommonUserNumber, WorkIndex) then
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
  end;

const
  NumberIndex=0;
  NameIndex=1;
  IderIndex=2;
  SummaIndex=3;
  TypeIndex=4;
  CorrIndex=5;
var
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

procedure TAccWorkForm.FillAccTable;
var
  I, C: Integer;
  PAccInfo: PAccInfoRec;
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
    StatusMessage('Показ списка...');
    InitProgress(0, AccList.Count);
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
  end;
  if Result=0 then
  begin
    {case SortIndex of
      1:
        Result := CompareResortedAcc(k1^.aiNumber, k2^.aiNumber);
      else}
        begin
          if k1^.aiNumber<k2^.aiNumber then
            Result := -1
          else
            if k1^.aiNumber>k2^.aiNumber then
              Result := 1;
        end;
    {end;}
  end;
end;

procedure TAccWorkForm.WMMakeStatement(var Message: TMessage);
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
  Len, Res: Integer;
  BtrDate: Word;
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

procedure TAccWorkForm.MakesItemClick(Sender: TObject);
begin
  AccountsForm.DoMakes(@AccWorkForm, RxMemoryData.Fields.Fields[NumberIndex].AsString,
    DateEdit.Date);
end;

procedure TAccWorkForm.DateEditAcceptDate(Sender: TObject;
  var ADate: TDateTime; var Action: Boolean);
begin
  DateEdit.Date := ADate;
  MakeItemClick(nil);
end;

end.
