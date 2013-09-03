unit SendFilesFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Grids, Db, DBTables, DBGrids, ExtCtrls, DBCtrls, BtrDS, Menus,
  StdCtrls, Buttons, ComCtrls, SearchFrm, Common, Basbn, CommCons, BankCnBn,
  Utilits, Btrieve, DbfDataSet, Registr, SendFileFrm;

type
  TSendFilesForm = class(TDataBaseForm)
    DataSource: TDataSource;
    DBGrid: TDBGrid;
    StatusBar: TStatusBar;
    ChildMenu: TMainMenu;
    OperItem: TMenuItem;
    FindItem: TMenuItem;
    DelItem: TMenuItem;
    EditBreaker: TMenuItem;
    EditBreaker1: TMenuItem;
    MakeChangeItem: TMenuItem;
    EditPopupMenu: TPopupMenu;
    BtnPanel: TPanel;
    NameLabel: TLabel;
    SearchIndexComboBox: TComboBox;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FindItemClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure DelItemClick(Sender: TObject);
    procedure SplitterCanResize(Sender: TObject; var NewSize: Integer;
      var Accept: Boolean);
    procedure MakeChangeItemClick(Sender: TObject);
    procedure SearchIndexComboBoxClick(Sender: TObject);
  private
  public
    SearchForm: TSearchForm;
  end;

var
  SendFilesForm: TSendFilesForm = nil;
  ObjList: TList;

implementation

{$R *.DFM}

procedure TSendFilesForm.FormCreate(Sender: TObject);
begin
  ObjList.Add(Self);
  DataSource.DataSet := GlobalBase(biSendFile) as TBtrDataSet;
  DefineGridCaptions(DBGrid, PatternDir+'SendFile.tab');
  SearchForm := TSearchForm.Create(Self);
  SearchForm.SourceDBGrid := DBGrid;
  TakeMenuItems(OperItem, EditPopupMenu.Items);
  EditPopupMenu.Images := ChildMenu.Images;
  SearchIndexComboBox.ItemIndex := 0;
  SearchIndexComboBoxClick(nil);
end;

procedure TSendFilesForm.FormDestroy(Sender: TObject);
begin
  ObjList.Remove(Self);
  SendFilesForm := nil;
end;

const
  BtnDist=6;

procedure TSendFilesForm.FindItemClick(Sender: TObject);
begin
  SearchForm.ShowModal;
end;

procedure TSendFilesForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if FormStyle=fsMDIChild then Action:=caFree;
end;

procedure TSendFilesForm.DelItemClick(Sender: TObject);
const
  MesTitle: PChar = 'Удаление';
begin
  if not DataSource.DataSet.IsEmpty then
    if MessageBox(Handle, 'Рассылка будет удалена. Вы уверерны?',
      MesTitle, MB_YESNOCANCEL + MB_ICONQUESTION) = IDYES
    then
      DataSource.DataSet.Delete;
end;

procedure TSendFilesForm.SplitterCanResize(Sender: TObject;
  var NewSize: Integer; var Accept: Boolean);
begin
  Accept := NewSize>10;
end;

procedure TSendFilesForm.MakeChangeItemClick(Sender: TObject);
var
  SendFileForm: TSendFileForm;
begin
  SendFileForm := TSendFileForm.Create(Self);
  SendFileForm.ShowModal;
  SendFileForm.Free;
end;

procedure TSendFilesForm.SearchIndexComboBoxClick(Sender: TObject);
begin
  (DataSource.DataSet as TBtrDataSet).IndexNum := SearchIndexComboBox.ItemIndex;
end;

end.


    sfBitIder:  word;                   {Идер фрагмента        k1.0  k2.0}
    sfFileIder: longint;                {Идер файла        k0  k1.1  k2.1}
    sfAbonent:  longint;                {Идер абонента         k1.2  k2.2}
    sfState:    word;                   {Состояние                   k2.3}

