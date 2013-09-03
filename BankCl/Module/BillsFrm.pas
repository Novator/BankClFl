unit BillsFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Grids, Db, DBTables, DBGrids, ExtCtrls, DBCtrls, BtrDS, Menus,
  StdCtrls, Buttons, ComCtrls, SearchFrm, PaydocsFrm, Common, Bases,
  Utilits, CommCons, DateFrm;

type
  TBillsForm = class(TDataBaseForm)
    DataSource: TDataSource;
    DBGrid: TDBGrid;
    StatusBar: TStatusBar;
    BtnPanel: TPanel;
    NameEdit: TEdit;
    SearchIndexComboBox: TComboBox;
    ChildMenu: TMainMenu;
    OperItem: TMenuItem;
    FindItem: TMenuItem;
    SeeItem: TMenuItem;
    EditBreaker: TMenuItem;
    NameLabel: TLabel;
    EditBreaker1: TMenuItem;
    TestItem: TMenuItem;
    EditPopupMenu: TPopupMenu;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure NameEditChange(Sender: TObject);
    procedure FindItemClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure SeeItemClick(Sender: TObject);
    procedure SearchIndexComboBoxClick(Sender: TObject);
    procedure TestItemClick(Sender: TObject);
  private
  public
    SearchForm: TSearchForm;
  end;

var
  BillsForm: TBillsForm;

implementation

{$R *.DFM}

procedure TBillsForm.FormCreate(Sender: TObject);
begin
  {BillObjList.Add(Self);}
  DataSource.DataSet := GlobalBase(biBill);
  DefineGridCaptions(DBGrid, PatternDir+'Bills.tab');
  SearchForm:=TSearchForm.Create(Self);
  SearchForm.SourceDBGrid := DBGrid;
  SearchIndexComboBox.ItemIndex:=0;

  TakeMenuItems(OperItem, EditPopupMenu.Items);
  EditPopupMenu.Images := ChildMenu.Images;
end;

procedure TBillsForm.FormDestroy(Sender: TObject);
begin
  BillsForm := nil;
end;

procedure TBillsForm.NameEditChange(Sender: TObject);
var
  I, Err: LongInt;
  D: Word;
begin
  case SearchIndexComboBox.ItemIndex of
    0, 1:
    begin
      Val(NameEdit.Text, I, Err);
      if Err=0 then
        TBtrDataSet(DataSource.DataSet).LocateBtrRecordByIndex(I,
          SearchIndexComboBox.ItemIndex, bsGe);
    end;
    2: begin
      D := StrToBtrDate(NameEdit.Text);
      TBtrDataSet(DataSource.DataSet).LocateBtrRecordByIndex(D, 2, bsGe);
    end;
  end;
end;

procedure TBillsForm.FindItemClick(Sender: TObject);
begin
  SearchForm.ShowModal;
end;

procedure TBillsForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if FormStyle=fsMDIChild then Action:=caFree;
end;

procedure TBillsForm.SeeItemClick(Sender: TObject);
var
  I: Integer;
begin
  I := POpRec(DataSource.DataSet.ActiveBuffer)^.brDocId;
end;

procedure TBillsForm.SearchIndexComboBoxClick(Sender: TObject);
begin
  (DataSource.DataSet as TBtrDataSet).IndexNum:=SearchIndexComboBox.ItemIndex;
  NameEdit.Visible := SearchIndexComboBox.ItemIndex <> 2;
end;

procedure TBillsForm.TestItemClick(Sender: TObject);
var
  BtrDate, D: Word;
  Res, Len, K, K2: Integer;
  OpRec: TOpRec;
begin
  with (DataSource.DataSet as TExtBtrDataSet) do
  begin
    BtrDate := DateToBtrDate(Date);
    if GetBtrDate(BtrDate, 'Тестирование', '&Проверить с',
      'Операции будут проверены на длину записи начиная с указанной даты') then
    begin
      D := 0;
      K := 0;
      K2 := 0;
      Len := SizeOf(OpRec);
      Res := BtrBase.GetGE(OpRec, Len, BtrDate, 2);
      while Res=0 do
      begin
        Inc(K);
        if BtrDate<>D then
        begin
          D := BtrDate;
          Inc(K2);
        end;
        if Len<10 then
          ShowMessage('Id='+IntToStr(OpRec.brIder)+'  Len<10');
        Len := SizeOf(OpRec);
        Res := BtrBase.GetNext(OpRec, Len, BtrDate, 2);
      end;
      ShowMessage('Проверено: '+IntToStr(K)+' в '+IntToStr(K2)+' днях.'
        +#13#10'Последняя BtrErr='+IntToStr(Res));
    end;
  end;
end;

end.
