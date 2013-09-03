unit AccountsFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Grids, Db, DBTables, DBGrids, ExtCtrls, DBCtrls, BtrDS, Menus, SearchFrm,
  StdCtrls, Buttons, ComCtrls, Common, Utilits, Basbn, CommCons, Registr,
  AccWorkFrm, AccountFrm, BankCnBn, BUtilits, WideComboBox, Mask, ToolEdit;

type
  TAccountsForm = class(TDataBaseForm)
    DataSource: TDataSource;
    DBGrid: TDBGrid;
    EditMenu: TMainMenu;
    FuncItem: TMenuItem;
    FindItem: TMenuItem;
    FuncBreaker2: TMenuItem;
    ArcAccItem: TMenuItem;
    EditPopupMenu: TPopupMenu;
    BtnPanel: TPanel;
    NameLabel: TLabel;
    SearchIndexComboBox: TComboBox;
    IdentEdit: TEdit;
    ChildStatusBar: TStatusBar;
    AccWorkList: TMenuItem;
    NewItem: TMenuItem;
    FuncBreaker: TMenuItem;
    EditItem: TMenuItem;
    CopyItem: TMenuItem;
    DelItem: TMenuItem;
    CorrListComboBox: TWideComboBox;
    AccComboBox: TWideComboBox;
    FuncBreaker1: TMenuItem;
    MakesItem: TMenuItem;
    DateEdit: TDateEdit;
    DateLabel: TLabel;
    MakesAllItem: TMenuItem;
    FuncBreaker3: TMenuItem;
    BillCompareItem: TMenuItem;
    ChangeCloseItem: TMenuItem;
    AccCheckBox: TCheckBox;
    OpenCloseLabel: TLabel;
    OpenCloseDateEdit: TDateEdit;
    LastAccPanel: TPanel;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ArcAccItemClick(Sender: TObject);
    procedure FindItemClick(Sender: TObject);
    procedure SearchIndexComboBoxClick(Sender: TObject);
    procedure IdentEditChange(Sender: TObject);
    procedure AccWorkListClick(Sender: TObject);
    procedure NewItemClick(Sender: TObject);
    procedure EditItemClick(Sender: TObject);
    procedure CopyItemClick(Sender: TObject);
    procedure DelItemClick(Sender: TObject);
    procedure UpdateClient(CopyCurrent, New: Boolean);
    procedure DBGridDblClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure DBGridDrawColumnCell(Sender: TObject; const Rect: TRect;
      DataCol: Integer; Column: TColumn; State: TGridDrawState);
    procedure IdentEditKeyPress(Sender: TObject; var Key: Char);
    procedure AccComboBoxChange(Sender: TObject);
    procedure CorrListComboBoxClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure CorrListComboBoxKeyPress(Sender: TObject; var Key: Char);
    procedure MakesItemClick(Sender: TObject);
    procedure MakesAllItemClick(Sender: TObject);
    procedure BillCompareItemClick(Sender: TObject);
    procedure ChangeCloseItemClick(Sender: TObject);
    procedure DateEditAcceptDate(Sender: TObject; var ADate: TDateTime;
      var Action: Boolean);
    procedure DateEditExit(Sender: TObject);
    procedure LastAccPanelMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure LastAccPanelMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure LastAccPanelClick(Sender: TObject);
  private
    SearchForm: TSearchForm;
  protected
  public
    function GetBank(Bik: string; var BankFullRec: TBankFullNewRec):
      Boolean;
    procedure TakeTabPrintData(var PrintDocRec: TPrintDocRec; var FormList: TList); override;
    procedure DoMakes(Caller: Pointer; Acc: string; ADate: TDateTime);
  end;

const
  AccountsForm: TAccountsForm = nil;
var
  ObjList: TList;

implementation

uses ArchAccsFrm, MakesFrm, MakesAllFrm, BillCompareFrm;

{$R *.DFM}

procedure TAccountsForm.FormActivate(Sender: TObject);
begin
  FillCorrList(CorrListComboBox.Items, 0);
end;

var
  ShortJump: Boolean = False;
  BeginDate: Word = 0;

procedure TAccountsForm.FormCreate(Sender: TObject);
var
  W: Word;
begin
  if BeginDate=0 then
  begin
    W := DateToBtrDate(Date);
    BeginDate := GetPrevWorkDay(W);
    if BeginDate=0 then
      BeginDate := W;
  end;
  DateEdit.Date := BtrDateToDate(BeginDate);
  OpenCloseDateEdit.Date := Date - 1.0;
  ObjList.Add(Self);
  TakeMenuItems(FuncItem, EditPopupMenu.Items);
  EditPopupMenu.Images := EditMenu.Images;
  DataSource.DataSet := GlobalBase(biAcc);
  SearchForm:=TSearchForm.Create(Self);
  DefineGridCaptions(DBGrid, PatternDir+'Accounts.tab');
  SearchForm.SourceDBGrid := DBGrid;
  SearchIndexComboBox.ItemIndex := 1;
  SearchIndexComboBoxClick(Sender);
  (DataSource.DataSet as TBtrDataSet).First;
  if not GetRegParamByName('ShortJump', GetUserNumber, ShortJump) then
    ShortJump := False;
  AccCheckBox.Checked := ShortJump;
  LastAccPanel.Tag := 3;
  LastAccPanelClick(nil);
end;

procedure TAccountsForm.FormDestroy(Sender: TObject);
begin
  ObjList.Remove(Self);
  AccountsForm := nil;
end;

procedure TAccountsForm.TakeTabPrintData(var PrintDocRec: TPrintDocRec; var FormList: TList);
begin 
  inherited;
  PrintDocRec.DBGrid := Self.DBGrid;
  PrintDocRec.GraphForm := DecodeMask('$(AccountsGraphForm)', 5, GetUserNumber);
  PrintDocRec.TextForm := DecodeMask('$(AccountsTextForm)', 5, GetUserNumber);
end;

procedure TAccountsForm.ArcAccItemClick(Sender: TObject);
begin
  if ArchAccsForm = nil then
    ArchAccsForm := TArchAccsForm.Create(Self)
  else
    ArchAccsForm.Show;
end;

procedure TAccountsForm.FindItemClick(Sender: TObject);
begin
  SearchForm.ShowModal;
end;

procedure TAccountsForm.SearchIndexComboBoxClick(Sender: TObject);
var
  AllowMultiSel: Boolean;
  Opt: TDBGridOptions;
begin
  (DataSource.DataSet as TBtrDataSet).IndexNum := SearchIndexComboBox.ItemIndex;
  AccComboBox.Hide;
  IdentEdit.Hide;
  CorrListComboBox.Hide;
  AccCheckBox.Hide;
  LastAccPanel.Hide;
  case SearchIndexComboBox.ItemIndex of
    0: IdentEdit.Show;
    1:
      begin
        AccComboBox.Show;
        AccCheckBox.Show;
        LastAccPanel.Show;
      end;
    2: CorrListComboBox.Show;
  end;
  AllowMultiSel := SearchIndexComboBox.ItemIndex<>2;
  Opt := DBGrid.Options;
  if (dgMultiSelect in Opt)<>AllowMultiSel then
  begin
    if AllowMultiSel then
      Include(Opt, dgMultiSelect)
    else
      Exclude(Opt, dgMultiSelect);
    DBGrid.Options := Opt;
  end;
end;

procedure TAccountsForm.IdentEditChange(Sender: TObject);
var
  I, J: Integer;
begin
  Val(IdentEdit.Text, I, J);
  if J=0 then
    TBtrDataSet(DataSource.DataSet).LocateBtrRecordByIndex(I,
      SearchIndexComboBox.ItemIndex, bsGe);
end;

procedure TAccountsForm.AccComboBoxChange(Sender: TObject);
var
  A: array[0..SizeOf(TAccount)] of Char;
begin
  FillChar(A, SizeOf(A), #0);
  StrPCopy(A, AccComboBox.Text);
  if not AccCheckBox.Checked or (StrLen(A)>20-LastAccPanel.Tag) then
    TBtrDataSet(DataSource.DataSet).LocateBtrRecordByIndex(A,
      SearchIndexComboBox.ItemIndex, bsGe);
end;

procedure TAccountsForm.CorrListComboBoxClick(Sender: TObject);
var
  I: Integer;
begin
  with CorrListComboBox do
    if (ItemIndex>=0) and (Items.Objects[ItemIndex]<>nil) then
    I := Integer(Items.Objects[ItemIndex]);
  TBtrDataSet(DataSource.DataSet).LocateBtrRecordByIndex(I,
    SearchIndexComboBox.ItemIndex, bsGe);
end;


procedure TAccountsForm.AccWorkListClick(Sender: TObject);
begin
  if AccWorkForm = nil then
    AccWorkForm := TAccWorkForm.Create(Self)
  else
    AccWorkForm.Show;
end;

procedure TAccountsForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if FormStyle=fsMDIChild then
    Action := caFree;
end;

type
  EditBankRecord = function(Sender: TComponent; RecPtr: Pointer;
    SearchIndex: Integer; ShowDlg: Boolean): Boolean;

function TAccountsForm.GetBank(Bik: string; var BankFullRec: TBankFullNewRec):
  Boolean;
var
  ModuleName: array[0..511] of Char;
  Module: HModule;
  P: Pointer;
  Err: Integer;
begin
  Result := False;
  StrPLCopy(ModuleName, DecodeMask('$(Banks)', 5, GetUserNumber), SizeOf(ModuleName));
  Module := GetModuleHandle(ModuleName);
  if Module=0 then
    MessageDlg('Не найден модуль диалога выбора банка'+#13+'['+ModuleName+']',
      mtError,[mbOk],0)
  else begin
    P:=GetProcAddress(Module, EditRecordDLLProcName);
    if P=nil then
      MessageDlg('Не найдена функция модуля '+EditRecordDLLProcName+'()',
        mtError,[mbOk],0)
    else begin
      with BankFullRec do
        Val(Bik, brCod, Err);
      if Err=0 then
        Result := EditBankRecord(P)(Self, @BankFullRec, 0, False);
    end;
  end;
end;

procedure TAccountsForm.UpdateClient(CopyCurrent, New: Boolean);
const
  MesTitle: PChar = 'Редактирование';
var
  AccountForm: TAccountForm;
  AccRec: TAccRec;
  I, L: Integer;
  T: array[0..511] of Char;
  Editing: Boolean;
  Bik: string;
  BankFullRec: TBankFullNewRec;
  ChangeCloseDate: Boolean;
begin
  ChangeCloseDate := not CopyCurrent and not New;
  if ChangeCloseDate then
    CopyCurrent := True;
  if not DataSource.DataSet.IsEmpty or (New and not CopyCurrent) then
  begin
    AccountForm := TAccountForm.Create(Self);
    with AccountForm do
    begin
      FNew := New;
      if CopyCurrent then
        TExtBtrDataSet(DataSource.DataSet).GetBtrRecord(PChar(@AccRec))
      else
        FillChar(AccRec, SizeOf(AccRec), #0);
      with AccRec do
      begin
        DosToWin(arName);
        AccEdit.Text := arAccount;
        CorrWideComboBox.ItemIndex := CorrWideComboBox.Items.
          IndexOfObject(TObject(arCorr));
        if New then
          OpenDateEdit.Date := OpenCloseDateEdit.Date
        else begin
          if arDateO>0 then
            OpenDateEdit.Date := BtrDateToDate(arDateO);
          if arDateC>0 then
          begin
            if not ChangeCloseDate then
              CloseDateEdit.Date := BtrDateToDate(arDateC);
          end
          else
            if ChangeCloseDate then
              CloseDateEdit.Date := OpenCloseDateEdit.Date;
        end;
        KindRadioGroup.ItemIndex := arOpts and asType;

        ClLockCheckBox.Checked := (arOpts and asLockCl)>0;

        SendRadioGroup.ItemIndex := (arOpts and asSndType) shr 14;
        CurSumCalcEdit.Value := arSumA*0.01;
        StartSumCalcEdit.Value := arSumS*0.01;
        NameEdit.Text := arName;
        VerSpinEdit.Value := arVersion;
      end;
      Editing := True;
      while Editing and (ShowModal = mrOk) do
      begin
        Editing := False;
        FillChar(AccRec.arAccount, SizeOf(AccRec.arAccount), #0);
        FillChar(AccRec.arName, SizeOf(AccRec.arName), #0);
        with AccRec do
        begin
          StrPLCopy(T, AccEdit.Text, SizeOf(T));
          StrTCopy(@arAccount, @T, SizeOf(arAccount));
          arCorr := Integer(CorrWideComboBox.Items.Objects[CorrWideComboBox.ItemIndex]);
          arVersion := VerSpinEdit.Value + 1;
          arDateO := DateToBtrDate(OpenDateEdit.Date);
          arDateC := DateToBtrDate(CloseDateEdit.Date);
          arOpts := KindRadioGroup.ItemIndex or (FNewSend shl 14);
          if ClLockCheckBox.Checked then
            arOpts := arOpts or asLockCl;
          arSumA := Round(CurSumCalcEdit.Value*100.0);
          arSumS := Round(StartSumCalcEdit.Value*100.0);
          StrPLCopy(arName, NameEdit.Text, SizeOf(arName)-1);
          WinToDos(arName);
          L := SizeOf(AccRec)-SizeOf(AccRec.arName)+StrLen(arName)+1;
        end;
        Bik := DecodeMask('$(BankBik)', 5, GetUserNumber);
        if GetBank(Bik, BankFullRec) then
          Editing := not TestAcc(IntToStr(BankFullRec.brCod), BankFullRec.brKs,
            AccRec.arAccount, ' клиента', True)
        else
          MessageBox(Handle, 'В справочнике отсутствует банк с указанным БИКом в настройках.'
            +#13#10'Проверка расчетного счета не выполнена',
            MesTitle, MB_OK or MB_ICONWARNING);
        if not Editing then
          with TExtBtrDataSet(DataSource.DataSet) do
          begin
            if New then
            begin
              MakeRegNumber(rnPaydoc, I);
              AccRec.arIder := I;
              if AddBtrRecord(PChar(@AccRec), L) then
              begin
                ProtoMes(plInfo, MesTitle, 'Добавлен счет Id='+IntToStr(AccRec.arIder));
                Refresh
              end
              else begin
                Editing := True;
                MessageBox(Handle, 'Невозможно добавить запись', MesTitle,
                  MB_OK or MB_ICONERROR);
              end;
            end
            else begin
              I := AccRec.arIder;
              if LocateBtrRecordByIndex(I, 0, bsEq) then
              begin
                if UpdateBtrRecord(@AccRec, L) then
                begin
                  ProtoMes(plInfo, MesTitle, 'Изменен счет Id='+IntToStr(AccRec.arIder));
                  UpdateCursorPos
                end
                else
                  Editing := MessageBox(Handle, 'Не удается изменить запись. Повторить?',
                    MesTitle, MB_YESNOCANCEL or MB_ICONWARNING) = ID_YES;
              end
              else begin
                Editing := MessageBox(Handle, 'Запись уже не существует. Создать заново?',
                  MesTitle, MB_YESNOCANCEL or MB_ICONWARNING) = ID_YES;
                New := Editing;
              end;
            end;
        end;
      end;
      Free;
    end;
  end;
end;

procedure TAccountsForm.NewItemClick(Sender: TObject);
begin
  UpdateClient(False, True);
end;

procedure TAccountsForm.EditItemClick(Sender: TObject);
begin
  if FormStyle = fsMDIChild then
    UpdateClient(True, False)
  else
    ModalResult := mrOk;
end;

procedure TAccountsForm.CopyItemClick(Sender: TObject);
begin
  UpdateClient(True, True)
end;

procedure TAccountsForm.DelItemClick(Sender: TObject);
const
  MesTitle: PChar = 'Удаление';
var
  N: Integer;
begin
  if not DataSource.DataSet.IsEmpty then
  begin
    DBGrid.SelectedRows.Refresh;
    N := DBGrid.SelectedRows.Count;
    if (N<2) and (MessageBox(Handle, PChar('Счет будет удален. Вы уверены?'),
      MesTitle, MB_YESNOCANCEL or MB_ICONQUESTION) = IDYES)
      or (N>=2) and (MessageBox(Handle, PChar('Будет удалено счетов: '
      +IntToStr(DBGrid.SelectedRows.Count)+#13#10'Вы уверены?'),
      MesTitle, MB_YESNOCANCEL or MB_ICONQUESTION) = IDYES) then
    begin
      if N>0 then
      begin
        ProtoMes(plInfo, MesTitle, 'Удаляется счет Id='
          +IntToStr(PAccRec(DataSource.DataSet.ActiveBuffer)^.arIder));
        DBGrid.SelectedRows.Delete;
        DBGrid.SelectedRows.Refresh;
      end
      else
        DataSource.DataSet.Delete;
    end;
  end;
end;

procedure TAccountsForm.DBGridDblClick(Sender: TObject);
begin
  EditItemClick(Sender)
end;

procedure TAccountsForm.DBGridDrawColumnCell(Sender: TObject;
  const Rect: TRect; DataCol: Integer; Column: TColumn;
  State: TGridDrawState);
var
  C: TColor;
begin
  if (Column.Field<>nil) and (Column.Field.FieldName='arDateC')
    and (Length(Column.Field.AsString)>0) then
  begin
    with (Sender as TDBGrid).Canvas do
    begin
      C := clRed;
      if (Brush.Color<>clHighlight)
        and (ColorToRGB(C) <> ColorToRGB(Brush.Color))
      then
        Font.Color := C;
      TextRect(Rect, Rect.Left+2, Rect.Top+2, Column.Field.AsString);
      {if ColorToRGB(C) <> ColorToRGB(Brush.Color) then
        Font.Color := C;
      TextRect(Rect, Rect.Left+2, Rect.Top+2, S);}
    end;
  end;
end;

procedure TAccountsForm.IdentEditKeyPress(Sender: TObject;
  var Key: Char);
begin
  if not ((Key in ['0'..'9']) or (Key < #32)) then
  begin
    Key := #0;
    MessageBeep(0)
  end;
end;

procedure TAccountsForm.FormShow(Sender: TObject);
begin
  AccComboBox.DroppedWidth := 460;
  AccComboBox.Show;
  with CorrListComboBox do
  begin
    Show;
    DroppedWidth := 460;
    Hide;
  end;
end;

procedure TAccountsForm.CorrListComboBoxKeyPress(Sender: TObject;
  var Key: Char);
begin
  Key := RusToLat(Key);
  if not ((Key in ['0'..'9', 'a'..'z', 'A'..'Z'])
    or (Key < #32)) then
  begin
    Key := #0;
    MessageBeep(0)
  end
  else
    Key := UpCase(Key);
end;

procedure TAccountsForm.DoMakes(Caller: Pointer; Acc: string; ADate: TDateTime);
var
  A: Boolean;
begin
  if Length(Acc)>0 then
  begin
    if MakesForm = nil then
      MakesForm := TMakesForm.Create(Self);
    with MakesForm do
    begin
      Show;
      MakesForm.SetCallerForm(Caller);
      if not OneDayItem.Checked then
        OneDayItemClick(nil);
      A := True;
      AccComboBox.Text := Acc;
      FromDateEditAcceptDate(nil, ADate, A);
      {FromDateEdit.Date := ADate;
      ToDateEdit.Date := ADate;}
      {PostMessage(MakesForm.Handle, WM_MAKESTATEMENT, 0, 0);}
    end;
  end;
end;

procedure TAccountsForm.MakesItemClick(Sender: TObject);
var
  AccRec: TAccRec;
begin
  if not DataSource.DataSet.IsEmpty then
  begin
    TExtBtrDataSet(DataSource.DataSet).GetBtrRecord(@AccRec);
    DoMakes(@AccountsForm, AccRec.arAccount, DateEdit.Date);
  end;
end;

procedure TAccountsForm.MakesAllItemClick(Sender: TObject);
begin
  if MakesAllForm = nil then
    MakesAllForm := TMakesAllForm.Create(Self)
  else
    MakesAllForm.Show;
end;

procedure TAccountsForm.BillCompareItemClick(Sender: TObject);
begin
  BillCompareForm := TBillCompareForm.Create(Self);
  with BillCompareForm do
  begin
    ShowModal;
    Free;
  end;
end;

procedure TAccountsForm.ChangeCloseItemClick(Sender: TObject);
begin
  UpdateClient(False, False)
end;

procedure TAccountsForm.DateEditAcceptDate(Sender: TObject;
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
    BeginDate := W;
end;

procedure TAccountsForm.DateEditExit(Sender: TObject);
var
  W: Word;
begin
  try
    W := DateToBtrDate(DateEdit.Date);
  except
    W := 0;
  end;
  if W>0 then
    BeginDate := W;
end;

procedure TAccountsForm.LastAccPanelMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbLeft then (Sender as TPanel).BevelOuter := bvLowered;
end;

procedure TAccountsForm.LastAccPanelMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  with (Sender as TPanel) do
    if BevelOuter = bvLowered then BevelOuter := bvRaised;
end;

procedure TAccountsForm.LastAccPanelClick(Sender: TObject);
begin
  if Sender<>nil then
  begin
    if LastAccPanel.Tag>=19 then
    begin
      LastAccPanel.Tag := 0;
      AccCheckBox.Checked := False;
    end
    else begin
      LastAccPanel.Tag := LastAccPanel.Tag + 1;
      AccCheckBox.Checked := True;
    end;
  end;
  LastAccPanel.Caption := IntToStr(LastAccPanel.Tag);
end;

end.
