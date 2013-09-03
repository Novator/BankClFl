unit ImpMarksFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Grids, Db, DBTables, DBGrids, ExtCtrls, DBCtrls, BtrDS, Menus,
  StdCtrls, Buttons, ComCtrls, SearchFrm, Common, Basbn, CommCons,
  Utilits;

type
  TImpMarksForm = class(TDataBaseForm)
    DataSource: TDataSource;
    DBGrid: TDBGrid;
    StatusBar: TStatusBar;
    MainMenu: TMainMenu;
    OperItem: TMenuItem;
    FindItem: TMenuItem;
    DelItem: TMenuItem;
    EditBreaker: TMenuItem;
    BtnPanel: TPanel;
    NameLabel: TLabel;
    NameEdit: TEdit;
    SearchIndexComboBox: TComboBox;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FindItemClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure DelItemClick(Sender: TObject);
    procedure SearchIndexComboBoxChange(Sender: TObject);
  private
  public
    SearchForm: TSearchForm;
    procedure TakeTabPrintData(var PrintDocRec: TPrintDocRec; var FormList: TList); override;
  end;

var
  ImpMarksForm: TImpMarksForm = nil;
  ObjList: TList;

implementation

{$R *.DFM}

procedure TImpMarksForm.FormCreate(Sender: TObject);
begin
  ObjList.Add(Self);
  DataSource.DataSet := GlobalBase(biImport) as TBtrDataSet;
  DefineGridCaptions(DBGrid, PatternDir+'impmarks.tab');
  SearchForm := TSearchForm.Create(Self);
  SearchForm.SourceDBGrid := DBGrid;
  SearchIndexComboBox.ItemIndex := 0;
  SearchIndexComboBoxChange(nil);
end;

procedure TImpMarksForm.TakeTabPrintData(var PrintDocRec: TPrintDocRec;
  var FormList: TList);
begin
  inherited;
  PrintDocRec.DBGrid := Self.DBGrid;
end;

procedure TImpMarksForm.FormDestroy(Sender: TObject);
begin
  ObjList.Remove(Self);
  ImpMarksForm := nil;
end;

const
  BtnDist=6;

procedure TImpMarksForm.FindItemClick(Sender: TObject);
begin
  SearchForm.ShowModal;
end;

procedure TImpMarksForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if FormStyle=fsMDIChild then Action:=caFree;
end;

procedure TImpMarksForm.DelItemClick(Sender: TObject);
begin
  if MessageBox(Handle, 'Пометка будет удалена, это повлияет на импорт документов. Вы уверены?',
    'Удаление', MB_YESNOCANCEL + MB_ICONQUESTION) = IDYES
  then
    DataSource.DataSet.Delete;
end;

procedure TImpMarksForm.SearchIndexComboBoxChange(Sender: TObject);
begin
  (DataSource.DataSet as TBtrDataSet).IndexNum := SearchIndexComboBox.ItemIndex;
  NameEdit.Visible := SearchIndexComboBox.ItemIndex=0;
end;

end.
