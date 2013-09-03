unit ValAccountsFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Grids, Db, DBTables, DBGrids, ExtCtrls, DBCtrls, BtrDS, Menus, SearchFrm,
  StdCtrls, Buttons, ComCtrls, Common, Utilits, Bases, CommCons, Registr,
  AccWorkFrm;

type
  TValAccountsForm = class(TDataBaseForm)
    DataSource: TDataSource;
    DBGrid: TDBGrid;
    EditMenu: TMainMenu;
    FuncItem: TMenuItem;
    FindItem: TMenuItem;
    FuncBreaker: TMenuItem;
    ArcAccItem: TMenuItem;
    EditPopupMenu: TPopupMenu;
    BtnPanel: TPanel;
    NameLabel: TLabel;
    SearchIndexComboBox: TComboBox;
    NameEdit: TEdit;
    ChildStatusBar: TStatusBar;
    AccWorkList: TMenuItem;
    FuncBreaker1: TMenuItem;
    MakesItem: TMenuItem;
    MakesAllItem: TMenuItem;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ArcAccItemClick(Sender: TObject);
    procedure FindItemClick(Sender: TObject);
    procedure SearchIndexComboBoxClick(Sender: TObject);
    procedure NameEditChange(Sender: TObject);
    procedure AccWorkListClick(Sender: TObject);
    procedure MakesItemClick(Sender: TObject);
    procedure MakesAllItemClick(Sender: TObject);
    procedure DBGridDrawColumnCell(Sender: TObject; const Rect: TRect;
      DataCol: Integer; Column: TColumn; State: TGridDrawState);
    procedure NameEditKeyPress(Sender: TObject; var Key: Char);
    procedure DBGridKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
  private
    SearchForm: TSearchForm;
  public
    {procedure TakeFormPrintData(var GraphForm, TextForm: TFileName;
      var DBGrid: TDBGrid); override;}
    procedure TakeTabPrintData(var GraphTab, TextTab: TFileName;
      var DBGrid: TDBGrid); override;
    procedure DoMakes(Caller: Pointer; Acc: string; ADate: TDateTime);
  end;

const
  ValAccountsForm: TValAccountsForm = nil;
var
  ObjList: TList;

implementation

{uses ArchAccsFrm, MakesFrm, MakesAllFrm;}

{$R *.DFM}

procedure TValAccountsForm.FormCreate(Sender: TObject);
begin
  ObjList.Add(Self);
  TakeMenuItems(FuncItem, EditPopupMenu.Items);
  EditPopupMenu.Images := EditMenu.Images;
  DataSource.DataSet := GlobalBase(biAcc);
  SearchForm := TSearchForm.Create(Self);
  DefineGridCaptions(DBGrid, PatternDir+'Accounts.tab');
  SearchForm.SourceDBGrid := DBGrid;
  SearchIndexComboBox.ItemIndex := 1;
  SearchIndexComboBoxClick(Sender);
end;

procedure TValAccountsForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action:=caFree;
end;

procedure TValAccountsForm.FormDestroy(Sender: TObject);
begin
  ObjList.Remove(Self);
  ValAccountsForm := nil;
end;

procedure TValAccountsForm.TakeTabPrintData(var GraphTab, TextTab: TFileName;
  var DBGrid: TDBGrid);
begin
  inherited TakeTabPrintData(GraphTab, TextTab, DBGrid);
  DBGrid := Self.DBGrid;
  GraphTab := DecodeMask('$(AccountsGraphForm)', 5);
  TextTab := DecodeMask('$(AccountsTextForm)', 5);
end;

procedure TValAccountsForm.ArcAccItemClick(Sender: TObject);
begin
  {if ArchAccsForm = nil then
    ArchAccsForm := TArchAccsForm.Create(Self)
  else
    ArchAccsForm.Show;}
end;

procedure TValAccountsForm.FindItemClick(Sender: TObject);
begin
  SearchForm.ShowModal;
end;

procedure TValAccountsForm.SearchIndexComboBoxClick(Sender: TObject);
begin
  (DataSource.DataSet as TBtrDataSet).IndexNum := SearchIndexComboBox.ItemIndex;
  case SearchIndexComboBox.ItemIndex of
    1: NameEdit.MaxLength := SizeOf(TAccount);
    else
      NameEdit.MaxLength := 15
  end;
end;

var
  Acc: array[0..SizeOf(TAccount)] of Char;

procedure TValAccountsForm.NameEditChange(Sender: TObject);
var
  I, J: Integer;
begin
  with TBtrDataSet(DataSource.DataSet) do
    case SearchIndexComboBox.ItemIndex of
      0,2:
        begin
          Val(NameEdit.Text, I, J);
          if J=0 then
            LocateBtrRecordByIndex(I, SearchIndexComboBox.ItemIndex, bsGe);
        end;
      1:
        begin                 
          FillChar(Acc, SizeOf(Acc), #0);
          StrPLCopy(Acc, NameEdit.Text, SizeOf(Acc)-1);
          LocateBtrRecordByIndex(Acc, 1, bsGe);
        end;
    end;
end;

procedure TValAccountsForm.AccWorkListClick(Sender: TObject);
begin
  if AccWorkForm = nil then
    AccWorkForm := TAccWorkForm.Create(Self)
  else
    AccWorkForm.Show;
end;

procedure TValAccountsForm.DoMakes(Caller: Pointer; Acc: string; ADate: TDateTime);
var
  A: Boolean;
begin
  (*
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
      AccEdit.Text := Acc;
      if ADate=0 then
        ADate := MakesForm.FromDateEdit.Date;
      FromDateEditAcceptDate(nil, ADate, A);
      {FromDateEdit.Date := ADate;
      ToDateEdit.Date := ADate;}
      {PostMessage(MakesForm.Handle, WM_MAKESTATEMENT, 0, 0);}
    end;
  end; *)
end;

procedure TValAccountsForm.MakesItemClick(Sender: TObject);
var
  AccRec: TAccRec;
begin
  if not DataSource.DataSet.IsEmpty then
  begin
    TExtBtrDataSet(DataSource.DataSet).GetBtrRecord(@AccRec);
    DoMakes(@ValAccountsForm, AccRec.arAccount, 0);
  end;
end;

procedure TValAccountsForm.MakesAllItemClick(Sender: TObject);
begin
  {if MakesAllForm = nil then
    MakesAllForm := TMakesAllForm.Create(Self)
  else
    MakesAllForm.Show;}
end;

procedure TValAccountsForm.DBGridDrawColumnCell(Sender: TObject;
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

procedure TValAccountsForm.NameEditKeyPress(Sender: TObject; var Key: Char);
begin
  if not ((Key in ['0'..'9']) or (Key < #32)) then
  begin
    Key := #0;
    MessageBeep(0)
  end;
end;

procedure TValAccountsForm.DBGridKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  case Key of
    VK_RETURN:
      MakesItemClick(nil);
  end;
end;

end.

