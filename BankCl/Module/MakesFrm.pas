unit MakesFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Grids, Db, DBTables, DBGrids, ExtCtrls, DBCtrls, BtrDS, Menus,
  StdCtrls, Buttons, ComCtrls, SearchFrm, Mask, ToolEdit, Common, CommCons, ClntCons,
  RxMemDS, Btrieve, Bases, Registr, Utilits, WideComboBox, DocFunc;

{const
  WM_MAKEACCLIST = WM_MAKESTATEMENT + 5;}

type
  PBillRec = ^TBillRec;
  TBillRec = packed record
    brAdr:    longint;
    brSumma:  comp;
    brDate:   Word;
  end;

  TBillList = class(TList)
  private
    bcAcc: TAccount;
    bcOstIn: comp;
    bcOstOut: comp;
    bcDebet: comp;
    bcCredit: comp;
    bcNumO: word;
    bcDate1, bcDate2: word;
    bcName: string[arMaxVar];
  protected
  public
    constructor Create(Acc: PChar; Date1, Date2 : word);
    destructor Destroy; override;
    procedure Clear; override;
  end;

  TMakesForm = class(TDataBaseForm)
    StatusBar: TStatusBar;
    BtnPanel: TPanel;
    FromDateEdit: TDateEdit;
    ToDateEdit: TDateEdit;
    ToDateLabel: TLabel;
    ProgressBar: TProgressBar;
    ChildMenu: TMainMenu;
    OperItem: TMenuItem;
    ViewItem: TMenuItem;
    EditBreaker: TMenuItem;
    FindItem: TMenuItem;
    MakeItem: TMenuItem;
    AbortBtn: TBitBtn;
    AccLabel: TLabel;
    RxMemoryData: TRxMemoryData;
    DataSource: TDataSource;
    DBGrid: TDBGrid;
    RxMemoryDataOpNumber: TIntegerField;
    RxMemoryDataAcc: TStringField;
    RxMemoryDataDebitSum: TStringField;
    RxMemoryDataCreditSum: TStringField;
    RxMemoryDataNazn: TStringField;
    RxMemoryDataDocIder: TIntegerField;
    RxMemoryDataDate: TStringField;
    FromDateLabel: TLabel;
    EditBreaker1: TMenuItem;
    OneDayItem: TMenuItem;
    MakePopupMenu: TPopupMenu;
    InAccEdit: TEdit;
    InAccLabel: TLabel;
    OutAccEdit: TEdit;
    OutAccLabel: TLabel;
    RxMemoryDataType: TStringField;
    DebitEdit: TEdit;
    DebitLabel: TLabel;
    CreditEdit: TEdit;
    CreditLabel: TLabel;
    RxMemoryDataName: TStringField;
    RxMemoryDataInn: TStringField;
    EditBreaker2: TMenuItem;
    PayDataSource: TDataSource;
    PayDBGrid: TDBGrid;
    OpenMoveItem: TMenuItem;
    AccEdit: TEdit;
    BackPanel: TPanel;
    EditBreaker3: TMenuItem;
    SetExtBillItem: TMenuItem;
    SetFullBillItem: TMenuItem;
    SetSimpleBillItem: TMenuItem;
    ChangeBillFormatItem: TMenuItem;
    KartDataSource: TDataSource;
    KartRxMemoryData: TRxMemoryData;
    StringField1: TStringField;
    IntegerField1: TIntegerField;
    StringField2: TStringField;
    StringField3: TStringField;
    StringField4: TStringField;
    StringField6: TStringField;
    IntegerField2: TIntegerField;
    StringField7: TStringField;
    StringField8: TStringField;
    GridSplitter: TSplitter;
    KartGroupBox: TGroupBox;
    KartDBGrid: TDBGrid;
    KartItem: TMenuItem;
    RxMemoryDataOrderNum: TIntegerField;
    KartRxMemoryDataIntegerField: TIntegerField;
    ExtAccShowItem: TMenuItem;
    EditBreaker4: TMenuItem;
    ExportBillItem: TMenuItem;
    SaveDialog: TSaveDialog;
    RxMemoryDataOpIder: TIntegerField;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure StringGridDrawCell(Sender: TObject; ACol, ARow: Integer;
      ARect: TRect; AState: TGridDrawState);
    procedure ViewItemClick(Sender: TObject);
    procedure FindItemClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ToDateEditAcceptDate(Sender: TObject; var ADate: TDateTime;
      var Action: Boolean);
    procedure FromDateEditAcceptDate(Sender: TObject; var ADate: TDateTime;
      var Action: Boolean);
    procedure MakeItemClick(Sender: TObject);
    procedure AbortBtnClick(Sender: TObject);
    procedure OneDayItemClick(Sender: TObject);
    {procedure AccComboBoxClick(Sender: TObject);}
    procedure FromDateEditExit(Sender: TObject);
    procedure AccComboBoxKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure AccComboBoxChange(Sender: TObject);
    procedure AccComboBoxExit(Sender: TObject);
    procedure FromDateEditChange(Sender: TObject);
    procedure MoveItemClick(Sender: TObject);
    procedure OpenMoveItemClick(Sender: TObject);
    procedure AccEditKeyPress(Sender: TObject; var Key: Char);
    procedure BackPanelClick(Sender: TObject);
    procedure BackPanelMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure BackPanelMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure SetSimpleBillItemClick(Sender: TObject);
    procedure GridSplitterCanResize(Sender: TObject; var NewSize: Integer;
      var Accept: Boolean);
    procedure KartItemClick(Sender: TObject);
    procedure DBGridEnter(Sender: TObject);
    procedure KartDBGridEnter(Sender: TObject);
    procedure ExtAccShowItemClick(Sender: TObject);
    procedure ExportBillItemClick(Sender: TObject);
  private
    AccDataSet, AccArcDataSet, BillDataSet, DocDataSet: TExtBtrDataSet;
    {BaseIsOpened: Boolean;}
    AccChanged, FTotalPrinting: Boolean;
    FCallerForm: Pointer;
    {procedure WMMakeAccList(var Message: TMessage); message WM_MAKEACCLIST;}
    procedure WMMakeStatement(var Message: TMessage); message WM_MAKESTATEMENT;
    procedure FillBillTable(CurAcc: PChar; BillList: TBillList);
  protected
    procedure StatusMessage(S: string);
    procedure InitProgress(AMin, AMax: Integer);
    procedure FinishProgress;
    procedure ShowAcc(Value: Boolean);
  public
    SearchForm: TSearchForm;
    ActiveGrid: Integer;
    OstIn0: Double;
    property TotalPrinting: Boolean read FTotalPrinting write FTotalPrinting;
    procedure TakeFormPrintData(var PrintDocRec: TPrintDocRec; var FormList: TList); override;
    procedure TakeTabPrintData(var PrintDocRec: TPrintDocRec; var FormList: TList); override;
    procedure SetCallerForm(Value: Pointer);
  end;

  EditRecord = function(Sender: TComponent; PayRecPtr: PPayRec; EditMode: Integer;
    ReadOnly: Boolean): Boolean;

var
  MakesForm: TMakesForm;
  DLLList: TList = nil;
  BillFormList: TList = nil;

procedure Save1sCaption(var F: TextFile; FromDate, ToDate, Acc: string);
procedure DisperseStr(S, Name: string; var Single, Multi: string);

implementation

uses
  AccountsFrm, AccWorkFrm;

{$R *.DFM}

procedure ClearStrings(AStrings: TStrings);
begin
  with AStrings do
  begin
    while Count>0 do
    begin
      Dispose(Pointer(Objects[Count-1]));
      Delete(Count-1);
    end;
  end;
end;

const
  OrderNumIndex=0;
  DocIderIndex=1;

  bDateIndex=2;
  bNumberIndex=3;
  bAccIndex=4;
  bTypeIndex=5;
  bDebitSumIndex=6;
  bCreditSumIndex=7;
  bNaznIndex=8;
  bNameIndex=9;
  bInnIndex=10;
  bOpIder=11;

  kDateIndex=2;
  kNumberIndex=3;
  kAccIndex=4;
  kTypeIndex=5;
  kSumIndex=6;
  kNaznIndex=7;
  kNameIndex=8;
  kInnIndex=9;

procedure TMakesForm.TakeFormPrintData(var PrintDocRec: TPrintDocRec; var FormList: TList);
var
  I: Integer;
  PayRec: TPayRec;
  Len, Res: Integer;

  //Добавлено Меркуловым
  RegistrBase: TBtrBase;
  ParamRec: TParamNewRec;
  ParamVec: TParamKey0;
  PasSerial, PasNumber, PasPlace, NaznPlat, CType: string;
  SimSum, Simvol: array [0..5] of String;
  J, J1, NSim, CorrRes: Integer;
  Number, PAcc, PKs, PCode, PInn, PClient, PBank,
  RAcc, RKs, RCode, RInn, RClient, RBank, Purpose, PKpp, RKpp,
  Status, Kbk, Okato, OsnPl, Period, NDoc, DocDate, TipPl,
  Nchpl, Shifr, Nplat, OstSum: string;

begin
  Nsim := 0;                                            //Добавлено
  J := 0;                                               //Добавлено
  inherited;
  PrintDocRec.GraphForm := '0';
  PrintDocRec.TextForm := '0';
  PrintDocRec.DBGrid := PayDBGrid;
  if RxMemoryData.Active and (RxMemoryData.RecordCount>0) or
    KartRxMemoryData.Active and (KartRxMemoryData.RecordCount>0) then
  begin
    if ActiveGrid=1 then
      I := KartRxMemoryData.Fields.Fields[DocIderIndex].AsInteger
    else
      I := RxMemoryData.Fields.Fields[DocIderIndex].AsInteger;
    with DocDataSet do
    begin
      IndexNum := 0;
      {OldDocIder := PPayRec(DocDataSet.ActiveBuffer)^.dbIdKorr;}
      Len := SizeOf(TPayRec);
      Res := BtrBase.GetEqual(PayRec, Len, I, 1);
      if Res=0 then
      begin
        if LocateBtrRecordByIndex(I, 1, bsEq) then
        begin
          I := PPayRec(DocDataSet.ActiveBuffer)^.dbDoc.drType;
          case I of
            1,2,16,91,92:
              begin
                PrintDocRec.GraphForm := DecodeMask('$(PayGraphForm)', 5, CommonUserNumber);
                PrintDocRec.TextForm := DecodeMask('$(PayTextForm)', 5, CommonUserNumber);
              end;
            {2:
              begin
                GraphForm := DecodeMask('$(PaytrGraphForm)', 5);
                TextForm := DecodeMask('$(PaytrTextForm)', 5);
              end;
            16:
              begin
                GraphForm := DecodeMask('$(PayorGraphForm)', 5);
                TextForm := DecodeMask('$(PayorTextForm)', 5);
              end;}
            3:
              begin

                //Добавлено Меркуловым
                DecodeDocVar(PayRec.dbDoc,PayRec.dbDocVarLen,
                Number, PAcc, PKs, PCode, PInn, PClient, PBank,
                RAcc, RKs, RCode, RInn, RClient, RBank, Purpose, PKpp, RKpp,
                Status, Kbk, Okato, OsnPl, Period, NDoc, DocDate, TipPl,
                Nchpl, Shifr, Nplat, OstSum, 0, 0, CorrRes, False);
                //Выделяем часть "Назначение ордера"
                Len := Length(Purpose);
                while (J<Len) and (Purpose[J] <> #10) and (Purpose[J] <> #13) do
                  Inc(J);
                if (J<Len) then
                  NaznPlat := Copy (Purpose,1,J);
                if (J<Len) then
                  J := J+2;
                J1 := J;
                //Заполним массив "символов" ордера
                while (J<Len) and (Purpose[J1-1]<>'~') do
                  begin
                  if (Purpose[J]='-') then
                    begin
                    Simvol[NSim] := Copy(Purpose,J1,(J-J1));
                    while (J<Len) and (Purpose[J]<>';') and (Purpose[J]<>'~') do
                      begin
                      Inc(J);
                      //С заменой точки на тире
                      if (Purpose[J]='.') then
                        SimSum[NSim]:=SimSum[NSim]+'-'
                      else if (Purpose[J]<>';') and (Purpose[J]<>'~') then
                        SimSum[NSim]:=SimSum[NSim]+Purpose[J];
                      end;
                    Inc(NSim);
                    J1:=J+1;
                  end;
                  Inc(J);
                end;
                //Печать нескольких копий кассового ордера
                if(PrintDocRec.CassCopy=0) then
                  begin
                  SetVarior('CassCopy',' ');
                  PrintDocRec.CassCopy := StrToInt(DecodeMask('$(CassCopy)', 5, CommonUserNumber));
                  end;
                if(PrintDocRec.CassCopy>0) then
                  SetVarior('CassCopy',IntToStr(PrintDocRec.CassCopy)+' экз.');
                //Если нет цифр, печатаем как приходный
                if (J1<Len) and (Purpose[J1]>='0') and (Purpose[J1]<='9') then
                  begin
                  //Заполняем поля паспортных данных
                  //Серия
                  J1 := J;
                  while (J<Len) and (Purpose[J-1]<>' ') do
                    begin
                    if (Purpose[J] = ' ') then
                      PasSerial := Copy(Purpose,J1,(J-J1));
                    Inc(J);
                    end;
                  J1:=J;
                  //Номер
                  while (J<Len) and (Purpose[J]<>' ') do
                    Inc(J);
                  if (J<Len) and (Purpose[J] = ' ') then
                    PasNumber := Copy(Purpose,J1,(J-J1));
                  J1:=J+1;
                  //Дата и место выдачи
                  while (J<Len) do
                    Inc(J);
                  PasPlace := Copy(Purpose,J1,Len);
                  //Объявляем глобальные переменные данных паспорта
                  SetVarior('PasSerial',PasSerial);
                  SetVarior('PasNumber',PasNumber);
                  SetVarior('PasPlace',PasPlace);
                end
                else if (J1<Len) then
                  // Обьявляем гл.перем.Ф.И.О.
                  SetVarior('FIO',Copy(Purpose,J1,Len));
                //Объявляем глобальные переменные назначения и символов ордера
                SetVarior('NaznPlat',NaznPlat);
                if(NSim>0) then
                  begin
                  Dec(NSim);
                  //Очищаем символы и суммы
                  for J:=0 to 3 do
                    begin
                    SetVarior('Simvol'+IntToStr(J),'');
                    SetVarior('SimSum'+IntToStr(J),'');
                    end;
                  while (NSim>=0) do
                    begin
                    //Объявляем глоб.переменные для печати
                    SetVarior('Simvol'+IntToStr(NSim),Simvol[NSim]);
                    SetVarior('SimSum'+IntToStr(NSim),SimSum[NSim]);
                    Dec(NSim);
                    end;
                  RegistrBase := GetRegistrBase;
                  with RegistrBase do
                    begin
                    with ParamVec do
                      begin
                      pkSect := 10;
                      pkNumber := 0;
                      pkUser := CommonUserNumber;
                      end;
                    Len := SizeOf(ParamRec);
                    Res := RegistrBase.GetGE(ParamRec, Len, ParamVec, 0);
                    while (Res=0) and (ParamRec.pmSect = 10) and (CType='') do
                      begin
                      with ParamRec do
                        if (pmNumber=StrToInt(Simvol[NSim+1])) then
                          CType := pmMeasure;
                      Len := SizeOf(ParamRec);
                      Res := RegistrBase.GetNext(ParamRec, Len, ParamVec, 0);
                      end;
                    end;
                  if (Res=0) then
                    begin
                    if (CType='П') then
                      begin
                      PrintDocRec.GraphForm := DecodeMask('$(CashExpGraphForm)', 5, CommonUserNumber);
                      PrintDocRec.TextForm := DecodeMask('$(CashExpTextForm)', 5, CommonUserNumber);
                      end
                    else if (CType='Р') then
                      begin
                      PrintDocRec.GraphForm := DecodeMask('$(CashRecGraphForm)', 5, CommonUserNumber);
                      PrintDocRec.TextForm := DecodeMask('$(CashRecTextForm)', 5, CommonUserNumber);
                      end;
                    end
                  else
                    MessageBox(ParentWnd,PChar('Ошибочный код ['+IntToStr(ParamRec.pmNumber)+'] в документе №'+NDoc+' от '+DocDate),'Ошибка',MB_OK);
                  end
                // Если не определил тип ордера, исп.старую форму
                else
                  begin
                  PrintDocRec.GraphForm := 'caso0001.gfm';
                  PrintDocRec.TextForm := 'caso0001.tfm';
                  end;

              end;
            9:
              begin
                PrintDocRec.GraphForm := DecodeMask('$(MemGraphForm)', 5, CommonUserNumber);
                PrintDocRec.TextForm := DecodeMask('$(MemTextForm)', 5, CommonUserNumber);
              end;
            192:
              begin
                PrintDocRec.GraphForm := DecodeMask('$(GrForm101)', 5, CommonUserNumber);
                PrintDocRec.TextForm := DecodeMask('$(TxForm101)', 5, CommonUserNumber);
              end;
            191:
              begin
                PrintDocRec.GraphForm := DecodeMask('$(GrForm102)', 5, CommonUserNumber);
                PrintDocRec.TextForm := DecodeMask('$(TxForm102)', 5, CommonUserNumber);
              end;
            else begin
              PrintDocRec.GraphForm := DecodeMask('$(GrForm'+IntToStr(I)+')', 5, CommonUserNumber);
              PrintDocRec.TextForm := DecodeMask('$(TxForm'+IntToStr(I)+')', 5, CommonUserNumber);
            end;
          end;
        end;
      end
      else
        MessageBox(Handle, PChar('Нет документа по данной выписке (DocId='
          +IntToStr(I)+')'), 'Просмотр документа', MB_OK or MB_ICONWARNING);
    end;
  end;
end;

var
  ShowKart: Boolean = True;

procedure TMakesForm.TakeTabPrintData(var PrintDocRec: TPrintDocRec; var FormList: TList);
begin
  inherited;
  PrintDocRec.DBGrid := Self.DBGrid;
  PrintDocRec.GraphForm := DecodeMask('$(StatementGraphForm)', 5, CommonUserNumber);
  PrintDocRec.TextForm := DecodeMask('$(StatementTextForm)', 5, CommonUserNumber);
  if KartItem.Checked then
    FormList := BillFormList
  else
    FormList := nil;
end;

const
  MaxAcc = 1000;
  DataIsChanged: Boolean = False;

procedure TMakesForm.SetCallerForm(Value: Pointer);
begin
  FCallerForm := Value;
end;

procedure TMakesForm.FormCreate(Sender: TObject);
const
  Border = 2;
var
  W: Word;
  PtrPrintDocRec: PPrintDocRec;
begin
  FCallerForm := nil;
  ActiveGrid := 0;
  TotalPrinting := False;
  W := GetPrevWorkDay(DateToBtrDate(Date), nil);
  if W=0 then
    FromDateEdit.Date := Date
  else
    FromDateEdit.Date := BtrDateToDate(W);
  ToDateEdit.Date := FromDateEdit.Date;

  with ProgressBar do
  begin
    Parent := StatusBar;
    SetBounds(0, Border, Width, StatusBar.Height - Border);
  end;
  AccChanged := False;

  AccDataSet := GlobalBase(biAcc);
  AccArcDataSet := GlobalBase(biAccArc);
  BillDataSet := GlobalBase(biBill);
  DocDataSet := GlobalBase(biPay);

  DefineGridCaptions(DBGrid, PatternDir+'Makes.tab');
  DefineGridCaptions(KartDBGrid, PatternDir+'Kart.tab');

  SearchForm:=TSearchForm.Create(Self);
  SearchForm.SourceDBGrid := DBGrid;

  PayDataSource.DataSet := DocDataSet;

  TakeMenuItems(OperItem, MakePopupMenu.Items);
  MakePopupMenu.Images := ChildMenu.Images;
  OneDayItemClick(Sender);
  if not GetRegParamByName('ShowKart', CommonUserNumber, ShowKart) then
    ShowKart := True;
  KartItemClick(nil);
  DataIsChanged := False;

  if BillFormList.Count<=0 then
  begin
    New(PtrPrintDocRec);
    with PtrPrintDocRec^ do
    begin
      GraphForm := DecodeMask('$(StatementGraphForm)', 5, CommonUserNumber);
      TextForm := DecodeMask('$(StatementTextForm)', 5, CommonUserNumber);
    end;
    BillFormList.Add(PtrPrintDocRec);
    New(PtrPrintDocRec);
    with PtrPrintDocRec^ do
    begin
      GraphForm := DecodeMask('$(KartGraphForm)', 5, CommonUserNumber);
      TextForm := DecodeMask('$(KartTextForm)', 5, CommonUserNumber);
    end;
    BillFormList.Add(PtrPrintDocRec);
  end;
  PPrintDocRec(BillFormList.Items[0])^.DBGrid := DBGrid;
  PPrintDocRec(BillFormList.Items[1])^.DBGrid := KartDBGrid;
end;

procedure TMakesForm.FormDestroy(Sender: TObject);
begin
  MakesForm := nil;
end;

procedure TMakesForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if KartItem.Checked <> ShowKart then
    SetRegParamByName('ShowKart', CommonUserNumber, False, BooleanToStr(KartItem.Checked));
  Action := caFree;
end;

procedure TMakesForm.StatusMessage(S: string);
begin
  StatusBar.Panels[1].Text := S;
end;

procedure TMakesForm.ShowAcc(Value: Boolean);
begin
  InAccEdit.Visible := Value;
  OutAccEdit.Visible := Value;
  InAccLabel.Visible := Value;
  OutAccLabel.Visible := Value;

  DebitEdit.Visible := Value;
  CreditEdit.Visible := Value;
  DebitLabel.Visible := Value;
  CreditLabel.Visible := Value;
end;

constructor TBillList.Create(Acc: PChar; Date1, Date2 : word);
begin
  inherited Create;
  StrTCopy(bcAcc, Acc, SizeOf(bcAcc));
  bcOstIn := 0;
  bcOstOut := 0;
  bcDebet := 0;
  bcCredit := 0;
  bcNumO := 0;
  bcDate1 := Date1;
  bcDate2 := Date2;
  bcName := '';
end;

destructor TBillList.Destroy;
begin
  Clear;
  inherited Destroy;
end;

procedure TBillList.Clear;
var
  P: Pointer;
begin
  while Count>0 do
  begin
    try
      P := Items[Count-1];
      if P<>nil then
        Dispose(P);
    finally
      Delete(Count-1);
    end;
  end;
end;

function BillCompare(Key1, Key2: Pointer): integer;
var
  k1: PBillRec absolute Key1;
  k2: PBillRec absolute Key2;
begin
  if k1^.brDate>k2^.brDate then
    Result := 1
  else
    if k1^.brDate<k2^.brDate then
      Result := -1
    else
      Result := 0;
  if Result=0 then
  begin
    if (k1^.brSumma>0) and (k2^.brSumma>0) then
    begin
      if k1^.brSumma<k2^.brSumma then
        Result := -1
      else
        if k1^.brSumma>k2^.brSumma then
          Result := 1
        else
          Result := 0
    end
    else
      if k1^.brSumma>k2^.brSumma then
        Result := -1
      else
        if k1^.brSumma<k2^.brSumma then
          Result := 1
        else
          Result := 0
  end;
end;

procedure TMakesForm.InitProgress(AMin, AMax: Integer);
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

procedure TMakesForm.FinishProgress;
begin
  ProgressBar.Hide;
  StatusBar.Panels[0].Width := 0;
end;

procedure TMakesForm.FillBillTable(CurAcc: PChar; BillList: TBillList);
var
  I, Len, Res, CorrInd, K: Integer;
  Buf: array[0..511] of Char;
  PBill: PBillRec;
  po: TOpRec;
  DocId: Longint;
  PayRec: TPayRec;
  Number,
    DebitRs, DebitKs, DebitBik, DebitInn, DebitName, DebitBank,
    CreditRs, CreditKs, CreditBik, CreditInn, CreditName, CreditBank,
    Purpose, DebitKpp, CreditKpp, Status, Kbk, Okato, OsnPl, Period, NDoc,
    DocDate, TipPl, Nchpl, Shifr, Nplat, OstSum, KorrAcc: string;
  CorrRes: Integer;
  ExtAccShow: Boolean;
begin
  RxMemoryData.EmptyTable;
  ExtAccShow := ExtAccShowItem.Checked;
  try
    InitProgress(0, BillList.Count);
    I := 0;
    while I<BillList.Count do
    begin
      PBill := BillList.Items[I];
      with RxMemoryData do
      begin
        Append;
        Fields.Fields[OrderNumIndex].AsInteger := I+1;
        DocId := PBill^.brAdr;
        Len := SizeOf(po);
        Res := BillDataSet.BtrBase.GetEqual(po, Len, DocId, 0);
        if Res=0 then
          with po do
          begin
            Fields.Fields[bDateIndex].AsString := BtrDateToStr(brDate);
            Fields.Fields[bOpIder].AsInteger := brIder;
            Fields.Fields[bNumberIndex].AsInteger := brNumber;
            if StrLComp(brAccC, CurAcc, SizeOf(TAccount))=0 then
            begin
              KorrAcc := brAccD;
              Fields.Fields[bCreditSumIndex].AsString :=
                SumToStr(Abs(PBill^.brSumma));
              CorrInd := 1;
            end
            else begin
              KorrAcc := brAccC;
              Fields.Fields[bDebitSumIndex].AsString :=
                SumToStr(Abs(PBill^.brSumma));
              CorrInd := 2;
            end;
            K := brType;
            if K>100 then
              K := K-100;
            Fields.Fields[bTypeIndex].AsString := FillZeros(K, 2);
            Fields.Fields[DocIderIndex].AsInteger := brDocId;
            Len := SizeOf(TPayRec);
            DocId := brDocId;
            Res := DocDataSet.BtrBase.GetEqual(PayRec, Len, DocId, 1);
            if Res=0 then
            begin
              DecodeDocVar(PayRec.dbDoc, PayRec.dbDocVarLen, Number,
                DebitRs, DebitKs, DebitBik, DebitInn, DebitName, DebitBank,
                CreditRs, CreditKs, CreditBik, CreditInn, CreditName, CreditBank,
                Purpose, DebitKpp, CreditKpp, Status, Kbk, Okato, OsnPl, Period, NDoc,
                DocDate, TipPl, Nchpl, Shifr, Nplat, OstSum, 0, 3, CorrRes, False);
              Res := PayRec.dbDocVarLen;
              if CorrInd=1 then
              begin
                Fields.Fields[bInnIndex].AsString := DebitInn;
                Fields.Fields[bNameIndex].AsString := DebitName;
                if ExtAccShow then
                  KorrAcc := DebitRs;
              end
              else begin
                Fields.Fields[bInnIndex].AsString := CreditInn;
                Fields.Fields[bNameIndex].AsString := CreditName;
                if ExtAccShow then
                  KorrAcc := CreditRs;
              end;
              Fields.Fields[bNaznIndex].AsString := RemoveDoubleSpaces(DelCR(Purpose));
            end
            else begin
              Fields.Fields[bInnIndex].AsString := '-';
              Fields.Fields[bNameIndex].AsString := '-';
              StrLCopy(Buf, brText, SizeOf(Buf));
              DosToWin(Buf);
              Fields.Fields[bNaznIndex].AsString := RemoveDoubleSpaces(
                DelCR(StrPas(Buf)));
            end;
            Fields.Fields[bAccIndex].AsString := KorrAcc;
          end
        else begin
          Fields.Fields[DocIderIndex].AsInteger := 0;
          Fields.Fields[bDebitSumIndex].AsString := SumToStr(Abs(PBill^.brSumma));
        end;
        Post;
      end;
      Inc(I);
      ProgressBar.Position := I;
      Application.ProcessMessages;
    end;
  finally
    FinishProgress;
  end;
end;

procedure TMakesForm.StringGridDrawCell(Sender: TObject; ACol,
  ARow: Integer; ARect: TRect; AState: TGridDrawState);
begin
  if ACol=0 then
    with Sender as TStringGrid do
    begin
      Canvas.Brush.Color := clBtnFace;
      Canvas.FillRect(ARect);
    end;
end;

type
  GetDocuments = procedure(AList: TStringList);

const
  DlgTitle: PChar = 'Модуль редактирования документа';

function GetModuleByCode(Code: Byte): HModule;
var
  I,J: Integer;
  DLLModule: HModule;
  P: Pointer;
  AList: TStringList;
begin
  AList := TStringList.Create;
  try
    Result := 0;
    I := DLLList.Count;
    while (I>0) and (Result=0) do
    begin
      Dec(I);
      DLLModule := HINST(DLLList.Items[I]);
      P := GetProcAddress(DLLModule, DocumentsDLLProcName);
      if P<>nil then
      begin
        AList.Clear;
        GetDocuments(P)(AList);
        J := 0;
        while (Result=0) and (J<AList.Count) do
        begin
          if StrToInt(AList.Names[J])=Code then Result := DLLModule;
          Inc(J);
        end;
      end else
        Application.MessageBox('Нет функции кода документа',
          DlgTitle, MB_OK or MB_ICONERROR)
    end
  finally
    AList.Free
  end;
end;

procedure TMakesForm.ViewItemClick(Sender: TObject);
const
  MesTitle: PChar = 'Просмотр документа';
var
  DocIder, Len, Res: Integer;
  ADocCode: Byte;
  PayRec: TPayRec;
  DLLModule: HModule;
  P: Pointer;
begin
  if (ActiveGrid=0) and RxMemoryData.Active and (RxMemoryData.RecordCount>0) or
    (ActiveGrid=1) and KartRxMemoryData.Active and (KartRxMemoryData.RecordCount>0) then
  begin
    if ActiveGrid=1 then
      DocIder := KartRxMemoryData.Fields.Fields[DocIderIndex].AsInteger
    else
      DocIder := RxMemoryData.Fields.Fields[DocIderIndex].AsInteger;
    Len := SizeOf(TPayRec);
    Res := DocDataSet.BtrBase.GetEqual(PayRec, Len, DocIder, 1);
    if Res=0 then
    begin
      ADocCode := PayRec.dbDoc.drType;
      DLLModule := GetModuleByCode(ADocCode);
      if DLLModule<>0 then
      begin
        P := GetProcAddress(DLLModule, EditRecordDLLProcName);
        if P<>nil then
          EditRecord(P)(Self, @PayRec, 1, True)
        else
          MessageBox(Handle, 'В модуле нет функции редактирования записи',
            MesTitle, MB_OK or MB_ICONERROR);
      end
      else
        MessageBox(Handle, 'Текущей записи не сопоставлен модуль редактирования',
          MesTitle, MB_OK or MB_ICONERROR)
    end
    else
      MessageBox(Handle, PChar('Нет документа по данной выписке (Id='
        +IntToStr(DocIder)+')'), MesTitle, MB_OK or MB_ICONWARNING);
  end;
end;

procedure TMakesForm.FindItemClick(Sender: TObject);
begin
  SearchForm.ShowModal;
end;

procedure TMakesForm.FromDateEditAcceptDate(Sender: TObject;
  var ADate: TDateTime; var Action: Boolean);
begin
  FromDateEdit.Date := ADate;
  Action := (ToDateEdit.Date<ADate) or not ToDateEdit.Visible;
  ToDateEditAcceptDate(Sender, ADate, Action);
  Action := False;
  DataIsChanged := False;
end;

procedure TMakesForm.FromDateEditExit(Sender: TObject);
var
  Action: Boolean;
  ADate: TDateTime;
begin
  if DataIsChanged then
  begin
    ADate := (Sender as TDateEdit).Date;
    Action := True;
    (Sender as TDateEdit).OnAcceptDate(Sender, ADate, Action);
  end;
end;

procedure TMakesForm.ToDateEditAcceptDate(Sender: TObject;
  var ADate: TDateTime; var Action: Boolean);
begin
  if Action then
  begin
    Action := ADate >= FromDateEdit.Date;
    if Action then
      ToDateEdit.Date := ADate;
  end;
  {AccComboBoxClick(nil);}
  PostMessage(Handle, WM_MAKESTATEMENT, 0, 0);
  {FindAccItemClick(Self);}
end;

{procedure TMakesForm.WMMakeAccList(var Message: TMessage);
begin
  FindAccItemClick(Self);
end;}

procedure TMakesForm.WMMakeStatement(var Message: TMessage);
begin
  MakeItemClick(Self);
end;

type
  PAccInfoRec = ^TAccInfoRec;
  TAccInfoRec =
    packed record
      acAccount: TAccount;
      acName: array[0..arMaxVar-1] of Char;
    end;

const
  BillDate1: Word = 0;
  BillDate2: Word = 0;

procedure TMakesForm.MakeItemClick(Sender: TObject); {Формирование выписки с контролем остатка}
const
  MesTitle: PChar = 'Формирование выписки';
var
  Len, Res: integer;
  KeyA: TAccount;
  KeyAA:
    packed record
      aaIder: longint;
      aaDate: word;
    end;
  KeyO: word;
  po: TOpRec;
  pa: TAccRec;
  paa: TAccArcRec;
  t: comp;
  DateFrom, DateTo: word;
  S: string;
  BillAcc: array[0..SizeOf(TAccount)] of Char;
  pbr: PBillRec;
  BillList: TBillList;
  Number,
    DebitRs, DebitKs, DebitBik, DebitInn, DebitName, DebitBank,
    CreditRs, CreditKs, CreditBik, CreditInn, CreditName, CreditBank,
    Purpose, DebitKpp, CreditKpp, Status, Kbk, Okato, OsnPl, Period, NDoc,
    DocDate, TipPl, Nchpl, Shifr, Nplat, OstSum: string;
  CorrRes, DocId, K, KCount: Integer;
  PayRec: TPayRec;
  ktDebet: comp;
begin
  ShowAcc(False);
  RxMemoryData.EmptyTable;
  KartRxMemoryData.EmptyTable;
  KCount := 0;
  if AccEdit.Enabled and (Length(AccEdit.Text)>0) then
  begin
    if not AbortBtn.Visible then
    begin
      try
        StrLCopy(BillAcc, PChar(AccEdit.Text), SizeOf(BillAcc)-1);
        { Построение выписки }
        DateFrom := 0;
        DateTo := 0;
        BillDate1 := StrToBtrDate(FromDateEdit.Text);
        BillDate2 := StrToBtrDate(ToDateEdit.Text);
        BillList := TBillList.Create(BillAcc, BillDate1, BillDate2);
        KeyA := BillList.bcAcc;
        Len := SizeOf(pa);
        Res := AccDataSet.BtrBase.GetEqual(pa, Len, KeyA, 1);
        if Res=0 then
        begin
          StatusMessage('Определение начального остатка...');
          DBGrid.Cursor := crHourGlass;
          Application.ProcessMessages;
          with BillList do
          begin
            bcName := StrPas(pa.arName);
            bcOstIn := pa.arSumS;
            bcOstOut := pa.arSumA;
          end;
          DateFrom := pa.arDateO;
          DateTo := $FFFF;
          with KeyAA do
          begin
            aaIder := pa.arIder;
            aaDate := BillDate1;
          end;
          Len := SizeOf(paa);
          Res := AccArcDataSet.BtrBase.GetLT(paa, Len, KeyAA, 1);
          if (Res=0) and (paa.aaIder=pa.arIder) and (paa.aaDate>DateFrom) then
          begin
            DateFrom := paa.aaDate;
            BillList.bcOstIn := paa.aaSum;
          end;
          with KeyAA do
          begin
            aaIder := pa.arIder;
            aaDate := BillDate2;
          end;
          Len := SizeOf(paa);
          Res := AccArcDataSet.BtrBase.GetGE(paa, Len, KeyAA, 1);
          if (Res=0) and (paa.aaIder=pa.arIder) then
          begin
            DateTo := paa.aaDate;
            BillList.bcOstOut := paa.aaSum;
          end;
          StatusMessage('Построение выписки...');
          AbortBtn.Show;
          ktDebet := 0;
          KeyO := DateFrom;
          Len := SizeOf(po);
          Res := BillDataSet.BtrBase.GetGT(po, Len, KeyO, 2);
          while (Res=0) and (po.brDate<=DateTo) and AbortBtn.Visible do
          begin
            FillChar(PChar(@po)[Len], SizeOf(po)-Len, #0);
            if po.brDel=0 then
            begin
              case po.brPrizn of
                brtBill:
                  if (StrLComp(po.brAccD, BillAcc, SizeOf(TAccount))=0)
                    or (StrLComp(po.brAccC, BillAcc, SizeOf(TAccount))=0) then
                  begin
                    t := po.brSum;
                    if po.brAccD=BillList.bcAcc then
                      t := -t;
                    if po.brDate<BillDate1 then
                      BillList.bcOstIn := BillList.bcOstIn+t
                    else
                      if po.brDate>BillDate2 then
                        BillList.bcOstOut := BillList.bcOstOut-t
                      else begin
                        New(pbr);
                        with pbr^ do
                        begin
                          brAdr := po.brIder;
                          brSumma := t;
                          brDate := po.brDate;
                        end;
                        if t<0 then
                        begin
                          BillList.bcDebet := BillList.bcDebet-t;
                          if po.brType=1 then
                            Inc(BillList.bcNumO)
                        end
                        else
                          BillList.bcCredit := BillList.bcCredit+t;
                        BillList.Add(pbr);
                      end;
                  end;
                brtKart:
                  if KartGroupBox.Visible
                    and (BillDate1<=po.brDate) and (po.brDate<=BillDate2) then
                  begin
                    Len := SizeOf(TPayRec);
                    DocId := po.brDocId;
                    Res := DocDataSet.BtrBase.GetEqual(PayRec, Len, DocId, 1);
                    if Res=0 then
                    begin
                      DecodeDocVar(PayRec.dbDoc, PayRec.dbDocVarLen, Number,
                        DebitRs, DebitKs, DebitBik, DebitInn, DebitName, DebitBank,
                        CreditRs, CreditKs, CreditBik, CreditInn, CreditName, CreditBank,
                        Purpose, DebitKpp, CreditKpp, Status, Kbk, Okato, OsnPl,
                        Period, NDoc, DocDate, TipPl, Nchpl, Shifr, Nplat, OstSum,
                        0, 3, CorrRes, False);
                      if DebitRs=BillAcc then
                        with KartRxMemoryData do
                        begin
                          Inc(KCount);
                          Append;
                          Fields.Fields[OrderNumIndex].AsInteger := KCount;
                          Fields.Fields[kDateIndex].AsString :=
                            BtrDateToStr(po.brDate);
                          Fields.Fields[kNumberIndex].AsString := Number;
                          K := PayRec.dbDoc.drType;
                          if K>100 then
                            K := K-100;
                          Fields.Fields[kTypeIndex].AsString := FillZeros(K, 2);
                          Fields.Fields[kSumIndex].AsString :=
                            SumToStr(PayRec.dbDoc.drSum);
                          ktDebet := ktDebet + PayRec.dbDoc.drSum;
                          Fields.Fields[kNaznIndex].AsString := RemoveDoubleSpaces(DelCR(Purpose));
                          Fields.Fields[DocIderIndex].AsInteger := DocId;
                          Fields.Fields[kAccIndex].AsString := CreditRs;
                          Fields.Fields[kNameIndex].AsString  := CreditName;
                          Fields.Fields[kInnIndex].AsString  := CreditInn;
                          Post;
                        end;
                    end;
                  end;
              end;
            end;
            Len := SizeOf(po);
            Res := BillDataSet.BtrBase.GetNext(po, Len, KeyO, 2);
            Application.ProcessMessages;
          end;
          if AbortBtn.Visible then
          begin
            AbortBtn.Hide;
            { Проверка остатка по счету }
            if (BillList.bcOstIn+BillList.bcCredit-BillList.bcDebet
              <> BillList.bcOstOut) and not TotalPrinting then
            begin
              MessageBox(Handle, PChar('Ошибка остатка на '+SumToStr(BillList.bcOstOut
                -(BillList.bcOstIn+BillList.bcCredit-BillList.bcDebet))+'.'
                +#13#10'Присланные выписки не соответствуют текущему остатку'),
                MesTitle, MB_OK or MB_ICONWARNING);
            end;
            StatusMessage('Показ выписки...');
            BillList.Sort(BillCompare);
            FillBillTable(BillAcc, BillList);
            with BillList do
            begin
              SetVarior('bcAcc', bcAcc);
              S := SumToStr(Abs(bcOstIn));
              if bcOstIn<0 then S:=S+' (Дт)' else S:=S+' (Кр)';
              SetVarior('bcOstIn', S);
              S := SumToStr(Abs(bcOstOut));
              if bcOstOut<0 then S:=S+' (Дт)' else S:=S+' (Кр)';
              SetVarior('bcOstOut', S);
              SetVarior('bcDebet', SumToStr(bcDebet));
              SetVarior('bcCredit', SumToStr(bcCredit));
              SetVarior('bcNumO', IntToStr(bcNumO));
              S := BtrDateToStr(bcDate1);
              if bcDate1<>bcDate2 then
                S := S+'-'+BtrDateToStr(bcDate2);
              SetVarior('bcDate1', S);
              SetVarior('bcDate2', BtrDateToStr(bcDate2));
              DosToWin(@bcName);
              SetVarior('bcName', bcName);
              SetVarior('bcDate', DateToStr(Date));
              SetVarior('bcTime', TimeToStr(Time));
              S := BtrDateToStr(GetPrevWorkDay(bcDate1, bcAcc));
              SetVarior('bcPrevDate', S);
              if Length(S)=0 then
                S := '[не найдена]';
              SetVarior('bcPrevDate1', S);
              SetVarior('ktDebet', SumToStr(ktDebet));

              OstIn0 := bcOstIn;
              InAccEdit.Text := SumToStr(bcOstIn);
              OutAccEdit.Text := SumToStr(bcOstOut);
              DebitEdit.Text := SumToStr(bcDebet);
              CreditEdit.Text := SumToStr(bcCredit);
            end;
            StatusMessage('Выписка построена ['+BillList.bcName+']');
            ShowAcc(True);
            AccChanged := False;
          end
          else
            StatusMessage('Построение выписки прервано');
        end
        else
          StatusMessage('Счет '+StrPas(@BillAcc)+' не найден');
      finally
        BillList.Free;
        DBGrid.Cursor := crDefault;
        BillDataSet.Refresh;
        AccArcDataSet.Refresh;
        AccDataSet.Refresh;
        DocDataSet.Refresh;
      end;
    end;
  end;
end;

procedure TMakesForm.AbortBtnClick(Sender: TObject);
begin
  AbortBtn.Visible := False;
end;

procedure TMakesForm.OneDayItemClick(Sender: TObject);
const
  Dist=4;
var
  ADate: TDateTime;
  Action: Boolean;
  L: Integer;
begin
  OneDayItem.Checked := not OneDayItem.Checked;
  ToDateEdit.Visible := not OneDayItem.Checked;
  ToDateLabel.Visible := ToDateEdit.Visible;
  if ToDateEdit.Visible then
  begin
    FromDateLabel.Caption := '&с';
    L := ToDateEdit.Left + ToDateEdit.Width;
  end
  else begin
    FromDateLabel.Caption := '&число';
    if FromDateEdit.Date<>ToDateEdit.Date then
    begin
      ADate := FromDateEdit.Date;
      Action := True;
      FromDateEditAcceptDate(Sender, ADate, Action);
    end;
    L := FromDateEdit.Left + FromDateEdit.Width;
  end;
  AccEdit.Left := L+Dist;
  AccLabel.Left := AccEdit.Left;
  AbortBtn.Left := AccEdit.Left + AccEdit.Width + 2*Dist;
  DebitEdit.Left := AbortBtn.Left;
  DebitLabel.Left := DebitEdit.Left;
  CreditEdit.Left := DebitEdit.Left+DebitEdit.Width+Dist;
  CreditLabel.Left := CreditEdit.Left;
  InAccEdit.Left := CreditEdit.Left+CreditEdit.Width+2*Dist;
  InAccLabel.Left := InAccEdit.Left;
  OutAccEdit.Left := InAccEdit.Left+InAccEdit.Width+Dist;
  OutAccLabel.Left := OutAccEdit.Left;
end;

procedure TMakesForm.AccComboBoxKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_RETURN then
    AccComboBoxExit(nil);
end;

procedure TMakesForm.AccComboBoxChange(Sender: TObject);
begin
  AccChanged := True;
end;

procedure TMakesForm.AccComboBoxExit(Sender: TObject);
begin
  if AccChanged then
    PostMessage(Handle, WM_MAKESTATEMENT, 0, 0);
end;

{procedure TMakesForm.AccComboBoxClick(Sender: TObject);
begin
  PostMessage(Handle, WM_MAKESTATEMENT, 0, 0);
end;}

procedure TMakesForm.FromDateEditChange(Sender: TObject);
begin
  DataIsChanged := True;
end;

procedure TMakesForm.MoveItemClick(Sender: TObject);
begin
  AccountsForm.Show
end;

type
  PForm = ^TForm;

procedure TMakesForm.OpenMoveItemClick(Sender: TObject);
begin
  if FCallerForm<>nil then
  begin
    if PForm(FCallerForm)^<>nil then
    begin
      try
        PForm(FCallerForm)^.Show;
      except
        FCallerForm := nil;
      end;
    end
    else
      FCallerForm := nil;
  end;
  if FCallerForm = nil then
    AccountsForm.Show
end;

procedure TMakesForm.AccEditKeyPress(Sender: TObject; var Key: Char);
begin
  if Key=#13 then
    AccComboBoxExit(Sender)
  else
    if not ((Key in ['0'..'9']) or (Key < #32)) then
    begin
      Key := #0;
      MessageBeep(0)
    end;
end;

procedure TMakesForm.BackPanelClick(Sender: TObject);
var
  BaseDate: Word;
  A: array[0..SizeOf(TAccount)] of Char;
  var Action: Boolean;
  ADate: TDateTime;
begin
  BaseDate := DateToBtrDate(FromDateEdit.Date-1);
  StrPLCopy(A, AccEdit.Text, SizeOf(A));
  if (BaseDate<>0) and (StrLen(A)>0) then
  begin
    BaseDate := GetPrevWorkDay(BaseDate, A);
    if BaseDate>0 then
    begin
      ADate := BtrDateToDate(BaseDate);
      FromDateEditAcceptDate(Self, ADate, Action);
    end
    else
      MessageBox(Handle, 'Предыдущая выписка по данному счету не найдена',
        'Поиск проводок', MB_OK or MB_ICONWARNING);
  end;
end;

procedure TMakesForm.BackPanelMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button=mbLeft then
    (Sender as TPanel).BevelOuter := bvLowered;
end;

procedure TMakesForm.BackPanelMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  (Sender as TPanel).BevelOuter := bvRaised;
end;

procedure TMakesForm.SetSimpleBillItemClick(Sender: TObject);
const
  MesTitle: PChar = 'Изменение формата выписки';
  GrBillPar: string = 'StatementGraphForm';
var
  S,N: string;
  Mode: Integer;
  Buf: TStrValue;
begin
  Mode := (Sender as TMenuItem).Tag;
  case Mode of
    1: S := 'обычную (только счет корреспондента)';
    2: S := 'расширенную (счет и название корреспондента)';
    3: S := 'полную (счет, название и ИНН корреспондента)';
  end;
  if MessageBox(Handle, PChar('Переключиться на '+S+' выписку?'), MesTitle,
    MB_YESNOCANCEL or MB_ICONQUESTION or MB_DEFBUTTON2)=ID_YES then
  begin
    S := PatternDir+'Makes.';
    case Mode of
      1: N := 'nor';
      2: N := 'ext';
      3: N := 'exk';
      else
        N := '';
    end;
    if CopyFile(PChar(S+N), PChar(S+'tab'), False) then
    begin
      if GetRegParamByName(GrBillPar, CommonUserNumber, Buf) then
      begin
        S := StrPas(Buf);
        S := Copy(S, 5, Length(S)-4);
        case Mode of
          2:
            S := 'bile'+S;
          3:
            S := 'bilk'+S;
          else
            S := 'bill'+S;
        end;
        if SetRegParamByName(GrBillPar, CommonUserNumber, False, S) then
        begin
          if (Mode=2) or (Mode=3) then
            S := '.'#13#10'Перед печатью устанавливайте альбомную ориентацию страницы,'+
              #13#10'это можно сделать командой меню "Файл-Настройка печати..."'
          else
            S := '';
          MessageBox(Handle, PChar('Выписка переключена. Изменения вступят при следующем построении'
            +S), MesTitle, MB_OK or MB_ICONINFORMATION);
          Application.ProcessMessages;
          Close;
        end
        else
          MessageBox(Handle, PChar('Не удалось задать параметр настройки '
            +GrBillPar+' в '+S), MesTitle, MB_OK or MB_ICONERROR);
      end
      else
        MessageBox(Handle, PChar('Не удалось найти параметр настройки '+GrBillPar),
          MesTitle, MB_OK or MB_ICONERROR);
    end
    else
      MessageBox(Handle, PChar('Не удалось скопировать файл '+S+N+' в '+S+'tab'),
        MesTitle, MB_OK or MB_ICONERROR);
  end;
end;

procedure TMakesForm.GridSplitterCanResize(Sender: TObject;
  var NewSize: Integer; var Accept: Boolean);
begin
  Accept := NewSize>30;
end;

procedure TMakesForm.KartItemClick(Sender: TObject);
begin
  if Sender=nil then
    KartItem.Checked := ShowKart
  else
    KartItem.Checked := not KartItem.Checked;
  GridSplitter.Visible := KartItem.Checked;
  KartGroupBox.Visible := KartItem.Checked;
  if (Sender<>nil) and KartItem.Checked then
    PostMessage(Handle, WM_MAKESTATEMENT, 0, 0);
end;

procedure TMakesForm.DBGridEnter(Sender: TObject);
begin
  ActiveGrid := 0;
end;

procedure TMakesForm.KartDBGridEnter(Sender: TObject);
begin
  ActiveGrid := 1;
end;

procedure TMakesForm.ExtAccShowItemClick(Sender: TObject);
begin
  ExtAccShowItem.Checked := not ExtAccShowItem.Checked;
  PostMessage(Handle, WM_MAKESTATEMENT, 0, 0);
end;

procedure DisperseStr(S, Name: string; var Single, Multi: string);
var
  I, L, J, K: Integer;
  V: string;
begin
  Single := '';
  Multi := '';
  K := 0;
  J := Length(Name);
  L := Length(S);
  I := 0;
  while I<=L do
  begin
    Inc(I);
    if (I>L) or (S[I]=#10) or (S[I]=#13) then
    begin
      V := Copy(S, 1, I-1);
      if Length(V)>0 then
      begin
        Single := Single + V;
        if J>0 then
        begin
          Inc(K);
          Multi := Multi + Name + IntToStr(K) + '=' + V + #13#10;
        end;
      end;
      while (I<=L) and ((S[I]=#10) or (S[I]=#13)) do
        Inc(I);
      Delete(S, 1, I-1);
      L := Length(S);
      if L>0 then
      begin
        I := 0;
        Single := Single + ' '
      end
      else
        I := 1;
    end;
  end;
end;

procedure Save1sCaption(var F: TextFile; FromDate, ToDate, Acc: string);
begin
  WriteLn(F, '1CClientBankExchange');
  WriteLn(F, 'ВерсияФормата=1.01');
  WriteLn(F, 'Кодировка=Windows');
  WriteLn(F, 'Получатель=');

  WriteLn(F, 'ДатаНачала='+FromDate);
  WriteLn(F, 'ДатаКонца='+ToDate);
  WriteLn(F, 'РасчСчет='+Acc);
end;

procedure TMakesForm.ExportBillItemClick(Sender: TObject);
const
  MesTitle: PChar = 'Экспорт выписки';
var
  F: TextFile;
  Res, Len, C, I: Integer;
  OpRec: TOpRec;
  PayRec: TPayRec;
  FN, S, M, Srok, Ocher,
    Number, DebitRs, DebitKs, DebitBik, DebitInn, DebitName, DebitBank,
    CreditRs, CreditKs, CreditBik, CreditInn, CreditName, CreditBank,
    Purpose, DebitKpp, CreditKpp, Status, Kbk, Okato, OsnPl, Period, NDoc,
    DocDate, TipPl, Nchpl, Shifr, Nplat, OstSum: string;
  CorrRes: Integer;
  W: Word;
  Ost, Deb, Cred: Double;
begin
  if DebitEdit.Visible then
  begin
    S := '$(BillExpFile)';
    FN := DecodeMask(S, 5, CommonUserNumber);
    I := 0;
    if FN<>S then
    begin
      if Length(FN)>0 then
      begin
        I := Length(ExtractFileName(FN));
        if I>0 then
          SaveDialog.FileName := FN
        else
          SaveDialog.InitialDir := FN;
      end;
    end;
    if (I>0) or SaveDialog.Execute then
    begin
      FN := SaveDialog.FileName;
      AssignFile(F, FN);
      {$I-} Rewrite(F); {$I+}
      if IOResult=0 then
      begin
        C := 0;
        try
          DataSource.Enabled := False;
          StatusMessage('Выгрузка выписки...');
          Save1sCaption(F, FromDateEdit.Text, ToDateEdit.Text, AccEdit.Text);

          W := 0;
          Ost := OstIn0;
          Deb := 0;
          Cred := 0;
          AbortBtn.Visible := True;

          with RxMemoryData do
          begin
            First;
            while not Eof and AbortBtn.Visible do
            begin
              I := Fields.Fields[bOpIder].AsInteger;
              Len := SizeOf(OpRec);
              Res := BillDataSet.BtrBase.GetEqual(OpRec, Len, I, 0);
              if (Res=0) and (OpRec.brPrizn=brtBill) then
              begin
                if OpRec.brDate<>W then
                begin
                  if W<>0 then
                  begin
                    Str(Cred*0.01:0:2, S);
                    WriteLn(F, 'ВсегоПоступило='+S);
                    Str(Deb*0.01:0:2, S);
                    WriteLn(F, 'ВсегоСписано='+S);
                    Ost := Ost-Deb+Cred;
                    Str(Ost*0.01:0:2, S);
                    WriteLn(F, 'КонечныйОстаток='+S);
                    WriteLn(F, 'КонецРасчСчет');
                  end;
                  Deb := 0;
                  Cred := 0;
                  W := OpRec.brDate;
                  WriteLn(F, 'СекцияРасчСчет');
                  S := BtrDateToStr(W);
                  WriteLn(F, 'ДатаНачала='+S);
                  WriteLn(F, 'ДатаКонца='+S);
                  WriteLn(F, 'РасчСчет='+AccEdit.Text);
                  Str(Ost*0.01:0:2, S);
                  WriteLn(F, 'НачальныйОстаток='+S);
                end;
                if Length(Fields.Fields[bDebitSumIndex].AsString)=0 then
                  Cred := Cred + OpRec.brSum
                else
                  Deb := Deb + OpRec.brSum;
              end;
              Next;
              Application.ProcessMessages;
            end;
            if W<>0 then                  
            begin
              Str(Cred*0.01:0:2, S);
              WriteLn(F, 'ВсегоПоступило='+S);
              Str(Deb*0.01:0:2, S);
              WriteLn(F, 'ВсегоСписано='+S);
              Ost := Ost-Deb+Cred;
              Str(Ost*0.01:0:2, S);
              WriteLn(F, 'КонечныйОстаток='+S);
              WriteLn(F, 'КонецРасчСчет');
            end;

            First;
            while not Eof and AbortBtn.Visible do
            begin
              I := Fields.Fields[bOpIder].AsInteger;
              Len := SizeOf(OpRec);
              Res := BillDataSet.BtrBase.GetEqual(OpRec, Len, I, 0);
              if (Res=0) and (OpRec.brPrizn=brtBill) then
              begin
                I := OpRec.brDocId;
                Len := SizeOf(PayRec);
                Res := DocDataSet.BtrBase.GetEqual(PayRec, Len, I, 1);
                if Res=0 then
                begin
                  DecodeDocVar(PayRec.dbDoc, PayRec.dbDocVarLen, Number,
                    DebitRs, DebitKs, DebitBik, DebitInn, DebitName, DebitBank,
                    CreditRs, CreditKs, CreditBik, CreditInn, CreditName, CreditBank,
                    Purpose, DebitKpp, CreditKpp, Status, Kbk, Okato, OsnPl, Period, NDoc,
                    DocDate, TipPl, Nchpl, Shifr, Nplat, OstSum, 0, 2, CorrRes, False);
                  Srok := BtrDateToStr(PayRec.dbDoc.drSrok);
                  Ocher := FillZeros(PayRec.dbDoc.drOcher, 2);
                end
                else begin
                  with OpRec do
                  begin
                    Number := IntToStr(OpRec.brNumber);
                    DebitRs := OpRec.brAccD;
                    CreditRs := OpRec.brAccC;
                    Purpose := OpRec.brText;

                    Srok := '';
                    Ocher := '';
                    DebitKs     := '';
                    DebitBik    := '';
                    DebitInn    := '';
                    DebitName   := '';
                    DebitBank   := '';
                    CreditKs    := '';
                    CreditBik   := '';
                    CreditInn   := '';
                    CreditName  := '';
                    CreditBank  := '';
                    DebitKpp    := '';
                    CreditKpp   := '';
                    Status      := '';
                    Kbk         := '';
                    Okato       := '';
                    OsnPl       := '';
                    Period      := '';
                    NDoc        := '';
                    DocDate     := '';
                    TipPl       := '';
                    Nchpl       := '';
                    Shifr       := '';
                    Nplat       := '';
                    OstSum      := '';
                  end;
                end;
                case OpRec.brType of
                  3:
                    WriteLn(F, 'СекцияДокумент=Кассовый ордер');
                  9:
                    WriteLn(F, 'СекцияДокумент=Мемориальный ордер');
                  2:
                    WriteLn(F, 'СекцияДокумент=Платежный ордер');
                  else
                    WriteLn(F, 'СекцияДокумент=Платежное поручение');
                end;
                WriteLn(F, 'Номер='+Number);
                WriteLn(F, 'Дата='+BtrDateToStr(OpRec.brDate));
                Str(OpRec.brSum*0.01:0:2, S);
                WriteLn(F, 'Сумма='+S);
                WriteLn(F, 'ПлательщикСчет='+DebitRs);
                WriteLn(F, 'ПлательщикИНН='+DebitInn);
                WriteLn(F, 'ПлательщикКПП='+DebitKpp);
                DisperseStr(DebitName, 'Плательщик', S, M);
                Write(F, M);
                WriteLn(F, 'ПлательщикРасчСчет='+DebitRs);
                DisperseStr(DebitBank, 'ПлательщикБанк', S, M);
                Write(F, M);
                WriteLn(F, 'ПлательщикБИК='+DebitBik);
                WriteLn(F, 'ПлательщикКорсчет='+DebitKs);
                WriteLn(F, 'ПолучательСчет='+CreditRs);
                WriteLn(F, 'ДатаПоступило='+BtrDateToStr(OpRec.brDate));
                WriteLn(F, 'ПолучательИНН='+CreditInn);
                WriteLn(F, 'ПолучательКПП='+CreditKpp);
                DisperseStr(CreditName, 'Получатель', S, M);
                Write(F, M);
                WriteLn(F, 'ПолучательРасчСчет='+CreditRs);
                DisperseStr(CreditBank, 'ПолучательБанк', S, M);
                Write(F, M);
                WriteLn(F, 'ПолучательБИК='+CreditBik);
                WriteLn(F, 'ПолучательКорсчет='+CreditKs);
                WriteLn(F, 'ВидПлатежа=Электронно');
                WriteLn(F, 'ВидОплаты='+FillZeros(OpRec.brType, 2));
                WriteLn(F, 'СтатусСоставителя='+Status);
                WriteLn(F, 'ПоказательКБК='+Kbk);
                WriteLn(F, 'ОКАТО='+Okato);
                WriteLn(F, 'ПоказательОснования='+OsnPl);
                WriteLn(F, 'ПоказательПериода='+Period);
                WriteLn(F, 'ПоказательНомера='+NDoc);
                WriteLn(F, 'ПоказательДаты='+DocDate);
                WriteLn(F, 'ПоказательТипа='+TipPl);
                WriteLn(F, 'СрокПлатежа='+BtrDateToStr(PayRec.dbDoc.drSrok));
                WriteLn(F, 'Очередность='+FillZeros(PayRec.dbDoc.drOcher, 2));
                DisperseStr(Purpose, 'НазначениеПлатежа', S, M);
                WriteLn(F, 'НазначениеПлатежа='+S);
                if Length(M)>0 then
                  Write(F, M);
                WriteLn(F, 'КонецДокумента');
                Inc(C);
              end;
              Next;
              Application.ProcessMessages;
            end;
          end;
          WriteLn(F, 'КонецФайла');
        finally
          CloseFile(F);
          DataSource.Enabled := True;
          if AbortBtn.Visible then
          begin
            AbortBtn.Visible := False;
            StatusMessage('Выгрузка успешно завершена');
            MessageBox(Handle, PChar('Выгружено в файл ['+FN+']'
              +#13#10'Всего проводок: '+IntToStr(C)), MesTitle,
              MB_OK or MB_ICONINFORMATION);
            StatusMessage('');
          end
          else
            StatusMessage('Выгрузка прервана');
        end;
      end
      else
        MessageBox(Handle, PChar('Не могу создать файл ['+FN+']'),
          MesTitle, MB_OK or MB_ICONERROR);
    end;
  end
  else
    MessageBox(Handle, PChar('Сначала постройте выписку'),
      MesTitle, MB_OK or MB_ICONINFORMATION);
end;

end.
