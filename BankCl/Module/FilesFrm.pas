unit FilesFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Grids, Db, DBTables, DBGrids, ExtCtrls, DBCtrls, BtrDS, Menus,
  StdCtrls, Buttons, ComCtrls, SearchFrm, Common, Bases, CommCons,
  Utilits;

type
  TFilesForm = class(TDataBaseForm)
    DataSource: TDataSource;
    DBGrid: TDBGrid;
    StatusBar: TStatusBar;
    ChildMenu: TMainMenu;
    OperItem: TMenuItem;
    FindItem: TMenuItem;
    DelItem: TMenuItem;
    EditBreaker: TMenuItem;
    EditPopupMenu: TPopupMenu;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FindItemClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure DelItemClick(Sender: TObject);
  private
  public
    SearchForm: TSearchForm;
  end;

var
  FilesForm: TFilesForm = nil;
  ObjList: TList;

implementation

{$R *.DFM}

procedure TFilesForm.FormCreate(Sender: TObject);
begin
  ObjList.Add(Self);
  DataSource.DataSet := GlobalBase(biFile) as TBtrDataSet;
  DefineGridCaptions(DBGrid, PatternDir+'filebits.tab');
  SearchForm := TSearchForm.Create(Self);
  SearchForm.SourceDBGrid := DBGrid;
  TakeMenuItems(OperItem, EditPopupMenu.Items);
  EditPopupMenu.Images := ChildMenu.Images;
end;

procedure TFilesForm.FormDestroy(Sender: TObject);
begin
  ObjList.Remove(Self);
  FilesForm := nil;
end;

const
  BtnDist=6;

procedure TFilesForm.FindItemClick(Sender: TObject);
begin
  SearchForm.ShowModal;
end;

procedure TFilesForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if FormStyle=fsMDIChild then Action:=caFree;
end;

procedure TFilesForm.DelItemClick(Sender: TObject);
begin
  if not DataSource.DataSet.IsEmpty then
  begin
    if MessageBox(Handle, 'Фрагмент будет удален. Файл не сможет быть воссоздан. Вы уверены?',  
      'Удаление', MB_YESNOCANCEL + MB_ICONQUESTION) = IDYES
    then
      DataSource.DataSet.Delete;
  end;
end;

end.
