unit PostPacksFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls, Grids, DBGrids, Menus, Db, ActnList, BtrDS,
  SearchFrm, Utilits, Common, CommCons;

type
  TPostPacksForm = class(TDataBaseForm)
    ActionList: TActionList;
    EditAction: TAction;
    DelAction: TAction;
    FindAction: TAction;
    ChildMenu: TMainMenu;
    OperItem: TMenuItem;
    CopyItem: TMenuItem;
    DelItem: TMenuItem;
    EditBreaker: TMenuItem;
    FindItem: TMenuItem;
    DataSource: TDataSource;
    EditPopupMenu: TPopupMenu;
    DBGrid: TDBGrid;
    BtnPanel: TPanel;
    NameLabel: TLabel;
    NameEdit: TEdit;
    SearchIndexComboBox: TComboBox;
    RcvCheckBox: TCheckBox;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormDestroy(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure SearchIndexComboBoxChange(Sender: TObject);
    procedure NameEditChange(Sender: TObject);
    procedure DelActionExecute(Sender: TObject);
    procedure EditActionExecute(Sender: TObject);
  private
    { Private declarations }
  public
    SearchForm: TSearchForm;
  end;

var
  PostPacksForm: TPostPacksForm;

implementation

uses
  PostMachineFrm, PostPackFrm;

{$R *.DFM}

procedure TPostPacksForm.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  Action := caFree;
end;

procedure TPostPacksForm.FormDestroy(Sender: TObject);
begin
  PostPacksForm := nil;
end;

procedure TPostPacksForm.FormCreate(Sender: TObject);
begin
  DataSource.DataSet := GetGlobalBase(biPost) as TExtBtrDataSet;
  DefineGridCaptions(DBGrid, PatternDir+'PostPack.tab');
  {with PostMachineForm do
  begin
    AddToolBtn(nil, Self);
    AddToolBtn(EditAction, Self);
    AddToolBtn(DelAction, Self);
    AddToolBtn(nil, Self);
    AddToolBtn(FindAction, Self);
  end;}
  SearchForm := TSearchForm.Create(Self);
  SearchForm.SourceDBGrid := DBGrid;
  DataSource.DataSet.Refresh;
  SearchIndexComboBox.ItemIndex := 0;
  SearchIndexComboBoxChange(Sender);
end;

procedure TPostPacksForm.SearchIndexComboBoxChange(Sender: TObject);
var
  AllowMultiSel: Boolean;
  Opt: TDBGridOptions;
begin
  (DataSource.DataSet as TBtrDataSet).IndexNum := SearchIndexComboBox.ItemIndex;
  case SearchIndexComboBox.ItemIndex of
    0: NameEdit.MaxLength := 12;
    else
      NameEdit.MaxLength := 8;
  end;
  RcvCheckBox.Visible := SearchIndexComboBox.ItemIndex in [1,2];
  AllowMultiSel := SearchIndexComboBox.ItemIndex in [0];
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

procedure TPostPacksForm.NameEditChange(Sender: TObject);
var
  I, Err: Integer;
  Key1: packed record
    kNameR: TAbonLogin;
    kFlRcv: Char;
  end;
begin
  case SearchIndexComboBox.ItemIndex of
    0:
    begin
      Val(NameEdit.Text, I, Err);
      TExtBtrDataSet(DataSource.DataSet).LocateBtrRecordByIndex(I, 0, bsGe);
    end;
    1,2:
    begin
      StrPLCopy(Key1.kNameR, UpperCase(NameEdit.Text), SizeOf(Key1.kNameR));
      if RcvCheckBox.Checked then
        Key1.kFlRcv := '1'
      else
        Key1.kFlRcv := '0';
      TExtBtrDataSet(DataSource.DataSet).LocateBtrRecordByIndex(Key1,
        SearchIndexComboBox.ItemIndex, bsGe);
    end;
  end;
end;

procedure TPostPacksForm.DelActionExecute(Sender: TObject);
const
  MesTitle: PChar = 'Удаление';
var
  N: Integer;
begin
  if not DataSource.DataSet.IsEmpty then
  begin
    DBGrid.SelectedRows.Refresh;
    N := DBGrid.SelectedRows.Count;
    if (N<2) and (MessageBox(Handle, PChar('Пакет будет удален. Вы уверены?'),
      MesTitle, MB_YESNOCANCEL + MB_ICONQUESTION) = IDYES)
      or (N>=2) and (MessageBox(Handle, PChar('Будет удалено пакетов: '
      +IntToStr(DBGrid.SelectedRows.Count)+#13#10'Вы уверены?'),
      MesTitle, MB_YESNOCANCEL + MB_ICONQUESTION) = IDYES) then
    begin
      if N>0 then
      begin
        DBGrid.SelectedRows.Delete;
        DBGrid.SelectedRows.Refresh;
      end
      else
        DataSource.DataSet.Delete;
    end;
  end;
end;

procedure TPostPacksForm.EditActionExecute(Sender: TObject);
var
  PostPackForm: TPostPackForm;
  SndPack: TSndPack;
  Len: Integer;
begin
  if not DataSource.DataSet.IsEmpty then
  begin
    Len := TExtBtrDataSet(DataSource.DataSet).GetBtrRecord(PChar(@SndPack));
    Application.CreateForm(TPostPackForm, PostPackForm);
    with PostPackForm do
    begin
      with SndPack do
      begin
        RecvEdit.Text := spNameR;
        SendEdit.Text := spNameS;
        ByteSEdit.Text := IntToStr(spByteS);
        LenEdit.Text := IntToStr(spLength);
        WordSEdit.Text := IntToStr(spWordS);
        NumEdit.Text := IntToStr(spNum);
        IderEdit.Text := IntToStr(spIder);
        FlSndEdit.Text := spFlSnd;
        DateSEdit.Text := BtrDateToStr(spDateS);
        TimeSEdit.Text := BtrTimeToStr(spTimeS);
        FlRcvEdit.Text := spFlRcv;
        DateREdit.Text := BtrDateToStr(spDateR);
        TimeREdit.Text := BtrTimeToStr(spTimeR);
        VarMemo.Text := Copy(spText, 1, Len-(SizeOf(SndPack)-SizeOf(SndPack.spText)));
      end;
      if ShowModal=mrOk then
      begin
      end;
      Free;
    end;
  end;
end;

end.
