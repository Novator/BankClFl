unit ArchAccsFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Grids, Db, DBTables, DBGrids, ExtCtrls, DBCtrls, BtrDS, Menus, AccountsFrm,
  SearchFrm, StdCtrls, ComCtrls, Common, Bases, Utilits, CommCons;

type
  TArchAccsForm = class(TDataBaseForm)
    DataSource: TDataSource;
    DBGrid: TDBGrid;
    EditMenu: TMainMenu;
    FuncItem: TMenuItem;
    FindItem: TMenuItem;
    ArchPopupMenu: TPopupMenu;
    ChildStatusBar: TStatusBar;
    BtnPanel: TPanel;
    NameLabel: TLabel;
    SearchIndexComboBox: TComboBox;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FindItemClick(Sender: TObject);
    procedure SearchIndexComboBoxClick(Sender: TObject);
  private
    SearchForm: TSearchForm;
  public
  end;

const
  ArchAccsForm: TArchAccsForm = nil;

implementation

{$R *.DFM}

procedure TArchAccsForm.FormCreate(Sender: TObject);
begin
  ObjList.Add(Self);
  DataSource.DataSet := GlobalBase(biAccArc);
  TakeMenuItems(FuncItem, ArchPopupMenu.Items);
  ArchPopupMenu.Images := EditMenu.Images;
  SearchForm := TSearchForm.Create(Self);
  DefineGridCaptions(DBGrid, PatternDir+'ArchAccs.tab');
  SearchForm.SourceDBGrid := DBGrid;
  SearchIndexComboBox.ItemIndex := 0;
  SearchIndexComboBoxClick(Sender);
end;

procedure TArchAccsForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action:=caFree;
end;

procedure TArchAccsForm.FormDestroy(Sender: TObject);
begin
  ObjList.Remove(Self);
  ArchAccsForm := nil;
end;

procedure TArchAccsForm.FindItemClick(Sender: TObject);
begin
  SearchForm.ShowModal;
end;

procedure TArchAccsForm.SearchIndexComboBoxClick(Sender: TObject);
begin
  (DataSource.DataSet as TBtrDataSet).IndexNum := SearchIndexComboBox.ItemIndex
end;

end.
