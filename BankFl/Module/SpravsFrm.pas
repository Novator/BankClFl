unit SpravsFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Grids, Db, DBTables, DBGrids, ExtCtrls, DBCtrls, BtrDS, Menus,
  StdCtrls, Buttons, ComCtrls, SearchFrm, Common, Basbn, CommCons, BankCnBn,
  Utilits, Btrieve, DbfDataSet, Registr, BankSpravFrm;

type
  TSpravsForm = class(TDataBaseForm)
    SprDataSource: TDataSource;
    StatusBar: TStatusBar;
    ChildMenu: TMainMenu;
    OperItem: TMenuItem;
    FindItem: TMenuItem;
    DelItem: TMenuItem;
    EditBreaker: TMenuItem;
    EditBreaker1: TMenuItem;
    MakeChangeItem: TMenuItem;
    AboDBGrid: TDBGrid;
    AboDataSource: TDataSource;
    Splitter: TSplitter;
    EditPopupMenu: TPopupMenu;
    AboPanel: TPanel;
    AboLabel: TLabel;
    AboComboBox: TComboBox;
    SprAreaPanel: TPanel;
    SprDBGrid: TDBGrid;
    SprPanel: TPanel;
    SprLabel: TLabel;
    SprComboBox: TComboBox;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FindItemClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure DelItemClick(Sender: TObject);
    procedure SplitterCanResize(Sender: TObject; var NewSize: Integer;
      var Accept: Boolean);
    procedure MakeChangeItemClick(Sender: TObject);
    procedure SprComboBoxClick(Sender: TObject);
    procedure AboComboBoxClick(Sender: TObject);
  private
  public
    SearchForm: TSearchForm;
  end;

var
  SpravsForm: TSpravsForm = nil;
  ObjList: TList;

implementation

{$R *.DFM}

procedure TSpravsForm.FormCreate(Sender: TObject);
begin
  ObjList.Add(Self);
  SprDataSource.DataSet := GlobalBase(biCorrSpr) as TBtrDataSet;
  AboDataSource.DataSet := GlobalBase(biCorrAbo) as TBtrDataSet;
  DefineGridCaptions(SprDBGrid, PatternDir+'CorrSpr.tab');
  DefineGridCaptions(AboDBGrid, PatternDir+'CorrAbo.tab');
  SearchForm := TSearchForm.Create(Self);
  SearchForm.SourceDBGrid := SprDBGrid;
  TakeMenuItems(OperItem, EditPopupMenu.Items);
  EditPopupMenu.Images := ChildMenu.Images;
  SprComboBox.ItemIndex := 0;
  SprComboBoxClick(nil);
  AboComboBox.ItemIndex := 0;
  AboComboBoxClick(nil);
end;

procedure TSpravsForm.FormDestroy(Sender: TObject);
begin
  ObjList.Remove(Self);
  SpravsForm := nil;
end;

const
  BtnDist=6;

procedure TSpravsForm.FindItemClick(Sender: TObject);
begin
  SearchForm.ShowModal;
end;

procedure TSpravsForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if FormStyle=fsMDIChild then Action:=caFree;
end;

procedure TSpravsForm.DelItemClick(Sender: TObject);
const
  MesTitle: PChar = 'Удаление';
begin
  if AboDBGrid.Focused then
  begin
    if not AboDataSource.DataSet.IsEmpty then
      if MessageBox(Handle, 'Рассылка будет удалена. Вы уверерны?',
        MesTitle, MB_YESNOCANCEL + MB_ICONQUESTION) = IDYES
      then
         AboDataSource.DataSet.Delete;
  end
  else begin
    if not SprDataSource.DataSet.IsEmpty then
      if MessageBox(Handle, 'Обновление банка будет удалено, это может привести к ошибкам. Вы уверерны?',
        MesTitle, MB_YESNOCANCEL + MB_ICONQUESTION) = IDYES
      then
         SprDataSource.DataSet.Delete;
  end
end;

procedure TSpravsForm.SplitterCanResize(Sender: TObject;
  var NewSize: Integer; var Accept: Boolean);
begin
  Accept := NewSize>10;
end;

procedure TSpravsForm.MakeChangeItemClick(Sender: TObject);
var
  BankSpravForm: TBankSpravForm;
begin
  BankSpravForm := TBankSpravForm.Create(Self);
  BankSpravForm.ShowModal;
  BankSpravForm.Free;
end;

procedure TSpravsForm.SprComboBoxClick(Sender: TObject);
begin
  (AboDataSource.DataSet as TBtrDataSet).IndexNum := SprComboBox.ItemIndex;
end;

procedure TSpravsForm.AboComboBoxClick(Sender: TObject);
begin
  (SprDataSource.DataSet as TBtrDataSet).IndexNum := AboComboBox.ItemIndex;
end;

end.

    scIderR:  longint;                  {Идер записи          k0, k1.0}
    scIderC:  longint;                  {Идер обновления          k1.1}

  PSprAboRec = ^TSprAboRec;
  TSprAboRec = packed record

    saIderR:  longint;                  {Идер записи корректировки  k0.0, k1.0}
    saCorr:   longint;                  {Идер абонента              k0.1, k1.1}
    saState:  word;                     {Состояние                        k1.2}

