unit ExpMarksFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Grids, Db, DBTables, DBGrids, ExtCtrls, DBCtrls, BtrDS, Menus,
  StdCtrls, Buttons, ComCtrls, SearchFrm, Common, Basbn, CommCons,
  Utilits, ExportTxtFrm;

type
  TExpMarksForm = class(TDataBaseForm)
    DataSource: TDataSource;
    DBGrid: TDBGrid;
    StatusBar: TStatusBar;
    MainMenu: TMainMenu;
    OperItem: TMenuItem;
    FindItem: TMenuItem;
    DelItem: TMenuItem;
    EditBreaker2: TMenuItem;
    BtnPanel: TPanel;
    NameLabel: TLabel;
    NameEdit: TEdit;
    SearchIndexComboBox: TComboBox;
    ExportTxtItem: TMenuItem;
    EditBreaker1: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FindItemClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure DelItemClick(Sender: TObject);
    procedure SearchIndexComboBoxChange(Sender: TObject);
    procedure ExportTxtItemClick(Sender: TObject);
  private
  public
    SearchForm: TSearchForm;
    procedure TakeTabPrintData(var PrintDocRec: TPrintDocRec; var FormList: TList); override;
  end;

var
  ExpMarksForm: TExpMarksForm = nil;
  ObjList: TList;

implementation

{$R *.DFM}

procedure TExpMarksForm.FormCreate(Sender: TObject);
begin
  ObjList.Add(Self);
  DataSource.DataSet := GlobalBase(biExport) as TBtrDataSet;
  DefineGridCaptions(DBGrid, PatternDir+'expmarks.tab');
  SearchForm := TSearchForm.Create(Self);
  SearchForm.SourceDBGrid := DBGrid;
  SearchIndexComboBox.ItemIndex := 0;
  SearchIndexComboBoxChange(nil);
end;

procedure TExpMarksForm.TakeTabPrintData(var PrintDocRec: TPrintDocRec; var FormList: TList);
begin
  inherited;
  PrintDocRec.DBGrid := Self.DBGrid;
end;

procedure TExpMarksForm.FormDestroy(Sender: TObject);
begin
  ObjList.Remove(Self);
  ExpMarksForm := nil;
end;

const
  BtnDist=6;

procedure TExpMarksForm.FindItemClick(Sender: TObject);
begin
  SearchForm.ShowModal;
end;

procedure TExpMarksForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if FormStyle=fsMDIChild then Action:=caFree;
end;

procedure TExpMarksForm.DelItemClick(Sender: TObject);
begin
  if MessageBox(Handle, 'Пометка будет удалена, это повлияет на экспорт документов. Вы уверены?',
    'Удаление', MB_YESNOCANCEL + MB_ICONQUESTION) = IDYES
  then
    DataSource.DataSet.Delete;
end;

procedure TExpMarksForm.SearchIndexComboBoxChange(Sender: TObject);
begin
  (DataSource.DataSet as TBtrDataSet).IndexNum := SearchIndexComboBox.ItemIndex;
  NameEdit.Visible := SearchIndexComboBox.ItemIndex=0;
end;

procedure TExpMarksForm.ExportTxtItemClick(Sender: TObject);
var
  ExportTxtForm: TExportTxtForm;
begin
  ExportTxtForm := TExportTxtForm.Create(Self);
  with ExportTxtForm do
    try
      ShowModal;
    finally
      Free;
    end;
end;

end.
