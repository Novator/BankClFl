unit SignedDocsFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Grids, Db, DBTables, DBGrids, ExtCtrls, DBCtrls, BtrDS, Menus,
  StdCtrls, Buttons, ComCtrls, SearchFrm, Mask, ToolEdit, Common, ClntCons,
  RxMemDS, Btrieve, Bases, Registr, Utilits, WideComboBox, CommCons, DocFunc;

type
  TSignedDocsForm = class(TDataBaseForm)
    StatusBar: TStatusBar;
    BtnPanel: TPanel;
    ChildMenu: TMainMenu;
    OperItem: TMenuItem;
    ViewItem: TMenuItem;
    EditBreaker: TMenuItem;
    FindItem: TMenuItem;
    MakeItem: TMenuItem;
    AbortBtn: TBitBtn;
    RxMemoryData: TRxMemoryData;
    DataSource: TDataSource;
    DBGrid: TDBGrid;
    RxMemoryDataOpNumber: TIntegerField;
    RxMemoryDataAcc: TStringField;
    RxMemoryDataDebitSum: TStringField;
    RxMemoryDataNazn: TStringField;
    RxMemoryDataDocIder: TIntegerField;
    RxMemoryDataDate: TStringField;
    MakePopupMenu: TPopupMenu;
    DebitEdit: TEdit;
    DebitLabel: TLabel;
    EditBreaker2: TMenuItem;
    RxMemoryDataPAcc: TStringField;
    UnSignedCheckBox: TCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure ViewItemClick(Sender: TObject);
    procedure FindItemClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure MakeItemClick(Sender: TObject);
    procedure AbortBtnClick(Sender: TObject);
  private
    DocDataSet: TExtBtrDataSet;
  protected
    procedure StatusMessage(S: string);
    {procedure InitProgress(AMin, AMax: Integer);
    procedure FinishProgress;}
    function PosToCur: Boolean;
  public
    SearchForm: TSearchForm;
    procedure TakeFormPrintData(var PrintDocRec: TPrintDocRec; var FormList: TList); override;
    procedure TakeTabPrintData(var PrintDocRec: TPrintDocRec; var FormList: TList); override;
  end;

var
  SignedDocsForm: TSignedDocsForm = nil;

implementation

uses PaydocsFrm;

{$R *.DFM}

const
  DateIndex=0;
  NumberIndex=1;
  PAccIndex=2;
  RAccIndex=3;
  SumIndex=4;
  NaznIndex=5;
  DocIderIndex=6;

procedure TSignedDocsForm.TakeFormPrintData(var PrintDocRec: TPrintDocRec; var FormList: TList);
begin
  if PosToCur then
    PaydocsForm.TakeFormPrintData(PrintDocRec, FormList);
end;

procedure TSignedDocsForm.TakeTabPrintData(var PrintDocRec: TPrintDocRec; var FormList: TList);
begin
  inherited; 
  PrintDocRec.DBGrid := Self.DBGrid;
  PrintDocRec.GraphForm := DecodeMask('$(ReestrGraphForm)', 5, CommonUserNumber);
  PrintDocRec.TextForm := DecodeMask('$(ReestrTextForm)', 5, CommonUserNumber);
end;

procedure TSignedDocsForm.FormCreate(Sender: TObject);
{const
  Border = 2;
var
  W: Word;}
begin
  {with ProgressBar do
  begin
    Parent := StatusBar;
    SetBounds(0, Border, Width, StatusBar.Height - Border);
  end;}
  DocDataSet := GlobalBase(biPay);
  DefineGridCaptions(DBGrid, PatternDir+'Signed.tab');

  SearchForm:=TSearchForm.Create(Self);
  SearchForm.SourceDBGrid := DBGrid;

  TakeMenuItems(OperItem, MakePopupMenu.Items);
  MakePopupMenu.Images := ChildMenu.Images;
end;

procedure TSignedDocsForm.FormDestroy(Sender: TObject);
begin
  SignedDocsForm := nil;
end;

procedure TSignedDocsForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
end;

procedure TSignedDocsForm.StatusMessage(S: string);
begin
  StatusBar.Panels[1].Text := S;
end;

{procedure TSignedDocsForm.InitProgress(AMin, AMax: Integer);
const
  Border=2;
begin
  with ProgressBar do
  begin
    StatusBar.Panels[0].Width := Width;
    Min := AMin;
    Max := AMax;
    Position := AMin;
    Show;
  end;
end;

procedure TSignedDocsForm.FinishProgress;
begin
  ProgressBar.Hide;
  StatusBar.Panels[0].Width := 0;
end;}

function TSignedDocsForm.PosToCur: Boolean;
const
  MesTitle: PChar = 'Просмотр документа';
var
  DocIder: Integer;
begin
  Result := False;
  if RxMemoryData.Active and (RxMemoryData.RecordCount>0) then
  begin
    if (DocDataSet.IndexNum<>3) and (DocDataSet.IndexNum<>0) then
    begin
      PaydocsForm.SearchIndexComboBox.ItemIndex := 0;
      PaydocsForm.SearchIndexComboBoxChange(nil);
    end;
    DocIder := RxMemoryData.Fields.Fields[DocIderIndex].AsInteger;
    Result := DocDataSet.LocateBtrRecordByIndex(DocIder, 3, bsEq);
    if not Result then
      MessageBox(Handle, 'Не удается спозиционироваться на документ', MesTitle,
        MB_OK or MB_ICONERROR);
  end;
end;

procedure TSignedDocsForm.ViewItemClick(Sender: TObject);
const
  MesTitle: PChar = 'Просмотр документа';
begin
  if PosToCur then
    PaydocsForm.EditItemClick(nil);
end;

procedure TSignedDocsForm.FindItemClick(Sender: TObject);
begin
  SearchForm.ShowModal;
end;

procedure TSignedDocsForm.MakeItemClick(Sender: TObject);
const
  MesTitle: PChar = 'Формирование реестра';
var
  I, Len, Res: Integer;
  PayRec: TPayRec;
  roDebet: Comp;
  Number, PAcc, PKs, PCode, PInn, PClient, PBank,
    RAcc, RKs, RCode, RInn, RClient, RBank, Nazn, PKpp, RKpp,
    Status, Kbk, Okato, OsnPl, Period, NDoc, DocDate, TipPl,
    Nchpl, Shifr, Nplat, OstSum: string;
begin
  RxMemoryData.EmptyTable;
  if not AbortBtn.Visible then
  begin
    try
      DBGrid.Cursor := crHourGlass;
      AbortBtn.Show;
      StatusMessage('Просмотр списка исходящих...');
      roDebet := 0;
      Len := SizeOf(PayRec);
      Res := DocDataSet.BtrBase.GetFirst(PayRec, Len, I, 3);
      while ((Res=0) or (Res=22)) and AbortBtn.Visible do
      begin
        if (Res=0) and ((PayRec.dbState and dsSndType)=dsSndEmpty)
          and (UnSignedCheckBox.Checked or IsSigned(PayRec, Len)) then
        begin
          roDebet := roDebet + PayRec.dbDoc.drSum;
          DecodeDocVar(PayRec.dbDoc, PayRec.dbDocVarLen,
            Number, PAcc, PKs, PCode, PInn, PClient, PBank,
            RAcc, RKs, RCode, RInn, RClient, RBank, Nazn, PKpp, RKpp,
            Status, Kbk, Okato, OsnPl, Period, NDoc, DocDate, TipPl,
            Nchpl, Shifr, Nplat, OstSum, 0, 3, Len, False);
          with RxMemoryData do
          begin
            Append;
            Fields.Fields[DateIndex].AsString :=
              BtrDateToStr(PayRec.dbDoc.drDate);
            Fields.Fields[NumberIndex].AsString := Number;
            Fields.Fields[PAccIndex].AsString := PAcc;
            Fields.Fields[RAccIndex].AsString := RAcc;
            Fields.Fields[SumIndex].AsString := SumToStr(PayRec.dbDoc.drSum);
            Fields.Fields[NaznIndex].AsString := RemoveDoubleSpaces(DelCR(Nazn));
            Fields.Fields[DocIderIndex].AsInteger := PayRec.dbIdHere;
            Post;
          end;
        end;
        Len := SizeOf(PayRec);
        Res := DocDataSet.BtrBase.GetNext(PayRec, Len, I, 3);
        Application.ProcessMessages;
      end;
      if AbortBtn.Visible then
      begin
        AbortBtn.Hide;
        SetVarior('roDebet', SumToStr(roDebet));
        SetVarior('roDate', DateToStr(Date));
        SetVarior('roTime', TimeToStr(Time));
        DebitEdit.Text := SumToStr(roDebet);
        StatusMessage('Реестр построен');
      end
      else
        StatusMessage('Построение реестра прервано');
    finally
      DBGrid.Cursor := crDefault;
    end;
  end;
end;

procedure TSignedDocsForm.AbortBtnClick(Sender: TObject);
begin
  AbortBtn.Visible := False;
end;

end.
