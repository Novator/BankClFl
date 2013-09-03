unit ClientsFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Grids, Db, DBTables, DBGrids, ExtCtrls, DBCtrls, Menus,
  StdCtrls, Buttons, ComCtrls, ClientFrm, Common, SearchFrm, Basbn, Utilits,
  BtrDS, CommCons;

type
  TClientsForm = class(TDataBaseForm)
    DataSource: TDataSource;
    DBGrid: TDBGrid;
    StatusBar: TStatusBar;
    BtnPanel: TPanel;
    OkBtn: TBitBtn;
    CancelBtn: TBitBtn;
    NameEdit: TEdit;
    SearchIndexComboBox: TComboBox;
    ChildMenu: TMainMenu;
    OperItem: TMenuItem;
    FindItem: TMenuItem;
    InsItem: TMenuItem;
    DelItem: TMenuItem;
    EditBreaker: TMenuItem;
    NameLabel: TLabel;
    EditItem: TMenuItem;
    CopyItem: TMenuItem;
    EditPopupMenu: TPopupMenu;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure NameEditChange(Sender: TObject);
    procedure SearchIndexComboBoxChange(Sender: TObject);
    procedure BtnPanelResize(Sender: TObject);
    procedure FindItemClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure InsItemClick(Sender: TObject);
    procedure EditItemClick(Sender: TObject);
    procedure DelItemClick(Sender: TObject);
    procedure CopyItemClick(Sender: TObject);
    procedure DBGridDblClick(Sender: TObject);
  private
    procedure EditClient(CopyCurrent, New: Boolean);
  public
    SearchForm: TSearchForm;
    procedure TakeTabPrintData(var PrintDocRec: TPrintDocRec; var FormList: TList); override;
  end;

var
  ObjList: TList;
const
  ClientsForm: TClientsForm = nil;

implementation

{$R *.DFM}

{procedure TClientForm.AfterScrollDS(DataSet: TDataSet);
begin
  NameEdit.Text:=DataSet.Fields.Fields[5].AsString;
end;}

procedure TClientsForm.FormCreate(Sender: TObject);
begin
  ObjList.Add(Self);
  DataSource.DataSet := GlobalBase(biClient) as TClientDataSet;
  DefineGridCaptions(DBGrid, PatternDir+'Clients.tab');
  SearchForm := TSearchForm.Create(Self);
  SearchForm.SourceDBGrid := DBGrid;
  SearchIndexComboBox.ItemIndex := 2;
  SearchIndexComboBoxChange(Sender);
  TakeMenuItems(OperItem, EditPopupMenu.Items);
  EditPopupMenu.Images := ChildMenu.Images;
end;

procedure TClientsForm.FormDestroy(Sender: TObject);
begin
  ObjList.Remove(Self);
  if Self=ClientsForm then ClientsForm := nil;
end;

procedure TClientsForm.TakeTabPrintData(var PrintDocRec: TPrintDocRec; var FormList: TList);
begin
  inherited;
  PrintDocRec.DBGrid := Self.DBGrid;
end;

procedure TClientsForm.NameEditChange(Sender: TObject);
var
  Inn: TInn;
  ClientName: TClientName;
  I,Err: Integer;
  SearchData: packed record Bik: LongInt; Acc: TAccount end;
  S: string;
begin
  case SearchIndexComboBox.ItemIndex of
    0:
    begin
      NameEdit.MaxLength := 10+SizeOf(SearchData.Acc);
      S := NameEdit.Text;
      I := Pos('/',S);
      FillChar(SearchData.Acc, SizeOf(SearchData.Acc), #0);
      if I>0 then
      begin
        StrPLCopy(SearchData.Acc, Copy(S,I+1,Length(S)-I), SizeOf(SearchData.Acc));
        S:=Copy(S, 1, I-1);
      end;
      Val(S, I, Err);
      SearchData.Bik := FillDigTo(I, 8);
      TBtrDataSet(DataSource.DataSet).LocateBtrRecordByIndex(SearchData, 0, bsGe);
    end;
    1:
    begin
      NameEdit.MaxLength := SizeOf(Inn);
      FillChar(Inn, SizeOf(Inn), #0);
      StrPCopy(Inn, NameEdit.Text);
      (DataSource.DataSet as TBtrDataSet).LocateBtrRecordByIndex(Inn, 1, bsGe);
    end;
    2:
    begin
      NameEdit.MaxLength := SizeOf(TClientName);
      FillChar(ClientName, SizeOf(TClientName), #0);
      StrPLCopy(ClientName, NameEdit.Text, SizeOf(TClientName)-1);
      WinToDos(ClientName);
      (DataSource.DataSet as TBtrDataSet).LocateBtrRecordByIndex(ClientName,
        2, bsGe);
    end;
  end;
end;

procedure TClientsForm.SearchIndexComboBoxChange(Sender: TObject);
var
  AllowMultiSel: Boolean;
  Opt: TDBGridOptions;
begin
  (DataSource.DataSet as TBtrDataSet).IndexNum := SearchIndexComboBox.ItemIndex;
  case SearchIndexComboBox.ItemIndex of
    0: NameEdit.MaxLength := 10+SizeOf(TAccount);
    1: NameEdit.MaxLength := SizeOf(TInn);
    2: NameEdit.MaxLength := clMaxVar;
    else
      NameEdit.MaxLength := 15;
  end;
  AllowMultiSel := SearchIndexComboBox.ItemIndex=0;
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

const
  BtnDist=6;

procedure TClientsForm.BtnPanelResize(Sender: TObject);
begin
  CancelBtn.Left:=BtnPanel.ClientWidth-CancelBtn.Width-2*BtnDist;
  OkBtn.Left:=CancelBtn.Left-OkBtn.Width-BtnDist;
end;

procedure TClientsForm.FindItemClick(Sender: TObject);
begin
  SearchForm.ShowModal;
end;

procedure TClientsForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if FormStyle=fsMDIChild then Action:=caFree;
end;

procedure TClientsForm.EditClient(CopyCurrent, New: Boolean);
var
  ClientForm: TClientForm;
  ClientRec: TNewClientRec;
  T: array[0..512] of Char;
  Editing: Boolean;
  {I: Integer;}
begin
  if not DataSource.DataSet.IsEmpty or (New and not CopyCurrent) then
  begin
    ClientForm := TClientForm.Create(Self);
    with ClientForm do
    begin
      if CopyCurrent then
        TClientDataSet(DataSource.DataSet).GetBtrRecord(PChar(@ClientRec))
      else
        FillChar(ClientRec,SizeOf(ClientRec),#0);
      with ClientRec do
      begin
        DosToWin(clNameC);
        StrLCopy(T, clAccC, SizeOf(clAccC));
        RsEdit.Text := StrPas(T);
        BikEdit.Text := IntToStr(clCodeB);
        StrLCopy(T, clInn, SizeOf(clInn));
        InnEdit.Text := StrPas(T);
        StrLCopy(T, clKpp, SizeOf(clKpp));
        KppEdit.Text := StrPas(T);
        NameMemo.Text := StrPas(clNameC);
      end;
      Editing := True;
      while Editing and (ShowModal = mrOk) do
      begin
        Editing := False;
        if not UpdateClient(RsEdit.Text, StrToInt(BikEdit.Text), NameMemo.Text,
          InnEdit.Text, KppEdit.Text, False, True) then
        begin
          Editing := True;
          MessageBox(Handle, 'Невозможно обновить запись', 'Редактирование',
            MB_OK + MB_ICONERROR);
        end;
      end;
      Free;
    end;
  end;
end;

procedure TClientsForm.InsItemClick(Sender: TObject);
begin
  EditClient(False, True);
end;

procedure TClientsForm.EditItemClick(Sender: TObject);
begin
  if FormStyle = fsMDIChild then
    EditClient(True, False)
  else
    ModalResult := mrOk;
end;

procedure TClientsForm.CopyItemClick(Sender: TObject);
begin
  EditClient(True, True)
end;

procedure TClientsForm.DelItemClick(Sender: TObject);
const
  MesTitle: PChar = 'Удаление';
var
  N: Integer;
begin
  if not DataSource.DataSet.IsEmpty then
  begin
    DBGrid.SelectedRows.Refresh;  
    N := DBGrid.SelectedRows.Count;
    if (N<2) and (MessageBox(Handle, PChar('Клиент будет удален. Вы уверены?'),
      MesTitle, MB_YESNOCANCEL + MB_ICONQUESTION) = IDYES)
      or (N>=2) and (MessageBox(Handle, PChar('Будет удалено клиентов: '
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

procedure TClientsForm.DBGridDblClick(Sender: TObject);
begin
  EditItemClick(Sender)
end;

end.
