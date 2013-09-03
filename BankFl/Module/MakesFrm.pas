unit MakesFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Grids, Db, DBTables, DBGrids, ExtCtrls, DBCtrls, BtrDS, Menus,
  StdCtrls, Buttons, ComCtrls, SearchFrm, Mask, ToolEdit, Common, CommCons,
  RxMemDS, Btrieve, Basbn, Registr, Utilits, BankCnBn, WideComboBox,
  DocFunc;                                    //Добавлено Меркуловым

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
    FindAccItem: TMenuItem;
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
    AccComboBox: TWideComboBox;
    EditBreaker2: TMenuItem;
    MoveItem: TMenuItem;
    PayDataSource: TDataSource;
    PayDBGrid: TDBGrid;
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
    procedure FindAccItemClick(Sender: TObject);
    procedure MakeItemClick(Sender: TObject);
    procedure AbortBtnClick(Sender: TObject);
    procedure OneDayItemClick(Sender: TObject);
    procedure AccComboBoxClick(Sender: TObject);
    procedure FromDateEditExit(Sender: TObject);
    procedure AccComboBoxKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure AccComboBoxChange(Sender: TObject);
    procedure AccComboBoxExit(Sender: TObject);
    procedure FromDateEditChange(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure MoveItemClick(Sender: TObject);
  private
    AccDataSet, AccArcDataSet, BillDataSet, DocDataSet: TExtBtrDataSet;
    BaseIsOpened: Boolean;
    AccChanged: Boolean;
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
    procedure TakeFormPrintData(var PrintDocRec: TPrintDocRec; var FormList: TList); override;
    procedure TakeTabPrintData(var PrintDocRec: TPrintDocRec; var FormList: TList); override;
    procedure SetCallerForm(Value: Pointer);
  end;

  EditRecord = function(Sender: TComponent; PayRecPtr: PBankPayRec;
    ReadOnly: Boolean): Boolean;

var
  MakesForm: TMakesForm;
  DLLList: TList;

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
  DateIndex=0;
  NumberIndex=1;
  AccIndex=2;
  TypeIndex=3;
  DebitSumIndex=4;
  CreditSumIndex=5;
  NaznIndex=6;
  DocIderIndex=7;
  NameIndex=8;
  InnIndex=9;

procedure TMakesForm.TakeFormPrintData(var PrintDocRec: TPrintDocRec; var FormList: TList);
var
  I: Integer;
  PayRec: TBankPayRec;
  Len, Res: Integer;

  //Добавлено Меркуловым
  PasSerial, PasNumber, PasPlace, NaznPlat: string;
  SimSum, Simvol: array [0..5] of String;
  J, J1, L, NSim, CorrRes: Integer;
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
  if RxMemoryData.Active and (RxMemoryData.RecordCount>0) then
  begin
    I := RxMemoryData.Fields.Fields[DocIderIndex].AsInteger;
    with DocDataSet do
    begin
      IndexNum := 0;
      Len := SizeOf(TBankPayRec);
      Res := BtrBase.GetEqual(PayRec, Len, I, 0);
      if Res=0 then
      begin
        if LocateBtrRecordByIndex(I, 0, bsEq) then
        begin
          Repaint;
          I := PBankPayRec(DocDataSet.ActiveBuffer)^.dbDoc.drType;
          case I of
            1,2,6,16,91,92:
              begin
                PrintDocRec.GraphForm := DecodeMask('$(PayGraphForm)', 5, GetUserNumber);
                PrintDocRec.TextForm := DecodeMask('$(PayTextForm)', 5, GetUserNumber);
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
                DecodeDocVar(PBankPayRec(DataSource.DataSet.ActiveBuffer)^.dbDoc,
                PBankPayRec(DataSource.DataSet.ActiveBuffer)^.dbDocVarLen,
                Number, PAcc, PKs, PCode, PInn, PClient, PBank,
                RAcc, RKs, RCode, RInn, RClient, RBank, Purpose, PKpp, RKpp,
                Status, Kbk, Okato, OsnPl, Period, NDoc, DocDate, TipPl,
                Nchpl, Shifr, Nplat, OstSum, 0, 0, CorrRes, False);
                //Выделяем часть "Назначение ордера"
                L := Length(Purpose);
                while (J<L) and (Purpose[J+1] <> #10) and (Purpose[J+1] <> #13) do
                  Inc(J);
                NaznPlat := Copy (Purpose,1,J);
                if (J<L) then
                  J := J+3;
                J1 := J;
                //Заполним массив "символов" ордера
                while (J<L) and (Purpose[J1-1]<>'~') do
                  begin
                  if (Purpose[J]='-') then
                    begin
                    Simvol[NSim] := Copy(Purpose,J1,(J-J1));
                    while (J<L) and (Purpose[J]<>';') and (Purpose[J]<>'~') do
                      begin
                      Inc(J);
                      //С заменой точки на тире
                      if (Purpose[J]='.') then
                        SimSum[NSim]:=SimSum[NSim]+'-';
                      if (Purpose[J]<>';') and (Purpose[J]<>'~') and (Purpose[J]<>'.') then
                        SimSum[NSim]:=SimSum[NSim]+Purpose[J];
                      end;
                    Inc(NSim);
                    J1:=J+1;
                  end;
                  Inc(J);
                end;
                Dec(NSim);
                //Печать нескольких копий кассового ордера
                if(PrintDocRec.CassCopy=0) then
                  begin
                  SetVarior('CassCopy',' ');
                  PrintDocRec.CassCopy := StrToInt(DecodeMask('$(CassCopy)', 5, CommonUserNumber));
                  end;
                if(PrintDocRec.CassCopy>0) then
                  SetVarior('CassCopy',IntToStr(PrintDocRec.CassCopy)+' экз.');
                //Если нет цифр, печатаем как приходный
                if (J1<L) and (Purpose[J1]>='0') and (Purpose[J1]<='9') then
                  begin
                  //Заполняем поля паспортных данных
                  //Серия
                  J1 := J;
                  while (J<L) and (Purpose[J-1]<>' ') do
                    begin
                    if (Purpose[J] = ' ') then
                      PasSerial := Copy(Purpose,J1,(J-J1));
                    Inc(J);
                    end;
                  J1:=J;
                  //Номер
                  while (J<L) and (Purpose[J]<>' ') do
                    Inc(J);
                  if (J<L) and (Purpose[J] = ' ') then
                    PasNumber := Copy(Purpose,J1,(J-J1));
                  J1:=J+1;
                  //Дата и место выдачи
                  while (J<L) do
                    Inc(J);
                  PasPlace := Copy(Purpose,J1,L);
                  PrintDocRec.GraphForm := DecodeMask('$(CashRecGraphForm)', 5, CommonUserNumber);
                  PrintDocRec.TextForm := DecodeMask('$(CashRecTextForm)', 5, CommonUserNumber);
                  //Объявляем глобальные переменные данных паспорта
                  SetVarior('PasSerial',PasSerial);
                  SetVarior('PasNumber',PasNumber);
                  SetVarior('PasPlace',PasPlace);
                end
                else if (J1<L) then
                  begin
                  // Обьявляем гл.перем.Ф.И.О.
                  SetVarior('FIO',Copy(Purpose,J1,L));
                  PrintDocRec.GraphForm := DecodeMask('$(CashExpGraphForm)', 5, CommonUserNumber);
                  PrintDocRec.TextForm := DecodeMask('$(CashExpTextForm)', 5, CommonUserNumber);
                  end;
                //Объявляем глобальные переменные назначения и символов ордера
                SetVarior('NaznPlat',NaznPlat);
                while (NSim>=0) do
                  begin
                  //Объявляем глоб.переменные для печати
                  SetVarior('Simvol'+IntToStr(NSim),Simvol[NSim]);
                  SetVarior('SimSum'+IntToStr(NSim),SimSum[NSim]);
                  Dec(NSim);
                  end;

              end;
            9:
              begin
                PrintDocRec.GraphForm := DecodeMask('$(MemGraphForm)', 5, GetUserNumber);
                PrintDocRec.TextForm := DecodeMask('$(MemTextForm)', 5, GetUserNumber);
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
              PrintDocRec.GraphForm := DecodeMask('$(GrForm'+IntToStr(I)+')', 5, GetUserNumber);
              PrintDocRec.TextForm := DecodeMask('$(TxForm'+IntToStr(I)+')', 5, GetUserNumber);
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

procedure TMakesForm.TakeTabPrintData(var PrintDocRec: TPrintDocRec; var FormList: TList);
begin
  inherited;
  PrintDocRec.DBGrid := Self.DBGrid;
  PrintDocRec.GraphForm := DecodeMask('$(StatementGraphForm)', 5, GetUserNumber);
  PrintDocRec.TextForm := DecodeMask('$(StatementTextForm)', 5, GetUserNumber);
end;

procedure TMakesForm.SetCallerForm(Value: Pointer);
begin
  FCallerForm := Value;
end;

const
  MaxAcc = 1000;
  DataIsChanged: Boolean = False;

procedure TMakesForm.FormCreate(Sender: TObject);
const
  Border = 2;
begin
  FCallerForm := nil;
  FromDateEdit.Date := Date;
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

  SearchForm:=TSearchForm.Create(Self);
  SearchForm.SourceDBGrid := DBGrid;

  PayDataSource.DataSet := DocDataSet;

  TakeMenuItems(OperItem, MakePopupMenu.Items);
  MakePopupMenu.Images := ChildMenu.Images;
  OneDayItemClick(Sender);
  DataIsChanged := False;
end;

procedure TMakesForm.FormDestroy(Sender: TObject);
begin
  ClearStrings(AccComboBox.Items);
  MakesForm := nil;
end;

procedure TMakesForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
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
  I, Len, Res, NameFI, InnFI: Integer;
  Buf: array[0..511] of Char;
  PBill: PBillRec;
  po: TOpRec;
  DocId: Longint;
  KeyAcc: TAccount;
  PayRec: TBankPayRec;
begin
  RxMemoryData.EmptyTable;
  try
    InitProgress(0, BillList.Count);
    I := 0;
    while I<BillList.Count do
    begin
      PBill := BillList.Items[I];
      with RxMemoryData do
      begin
        Append;
        DocId := PBill^.brAdr;
        Len := SizeOf(po);
        Res := BillDataSet.BtrBase.GetEqual(po, Len, DocId, 0);
        if Res=0 then
          with po do
          begin
            Fields.Fields[DateIndex].AsString :=
              BtrDateToStr(brDate);
            Fields.Fields[NumberIndex].AsInteger := brNumber;
            if StrLComp(brAccC, CurAcc, SizeOf(TAccount))=0 then
            begin
              KeyAcc := brAccD;
              Fields.Fields[CreditSumIndex].AsString :=
                SumToStr(Abs(PBill^.brSumma));
              NameFI := 5;
            end
            else begin
              KeyAcc := brAccC;
              Fields.Fields[DebitSumIndex].AsString :=
                SumToStr(Abs(PBill^.brSumma));
              NameFI := 11;
            end;
            Fields.Fields[AccIndex].AsString := KeyAcc;
            Fields.Fields[TypeIndex].AsString := FillZeros(brType, 2);
            StrLCopy(Buf, brText, SizeOf(Buf));
            DosToWin(Buf);
            Fields.Fields[NaznIndex].AsString := StrPas(Buf);
            Fields.Fields[DocIderIndex].AsInteger := brDocId;

            if DBGrid.Columns.Items[NameIndex].Visible
              or DBGrid.Columns.Items[InnIndex].Visible then
            begin
              Len := SizeOf(TBankPayRec);
              DocId := brDocId;
              Res := DocDataSet.BtrBase.GetEqual(PayRec, Len, DocId, 0);
              if Res=0 then
              begin
                Res := PayRec.dbDocVarLen;
                InnFI := NameFI-1;

                TakeZeroOffset(PayRec.dbDoc.drVar, InnFI, Res);
                StrLCopy(Buf, @PayRec.dbDoc.drVar[Res], SizeOf(Buf)-1);
                Fields.Fields[InnIndex].AsString := StrPas(Buf);

                Res := Res + StrLen(@PayRec.dbDoc.drVar[Res])+1;
                StrLCopy(Buf, @PayRec.dbDoc.drVar[Res], SizeOf(Buf)-1);
                DosToWin(Buf);
                Fields.Fields[NameIndex].AsString := StrPas(Buf);
              end
              else
                Fields.Fields[NameIndex].AsString := '-';
            end;
          end
        else begin
          Fields.Fields[DocIderIndex].AsInteger := 0;
          Fields.Fields[DebitSumIndex].AsString := SumToStr(Abs(PBill^.brSumma));
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
  PayRec: TBankPayRec;
  DLLModule: HModule;
  P: Pointer;
begin
  if RxMemoryData.Active and (RxMemoryData.RecordCount>0) then
  begin
    DocIder := RxMemoryData.Fields.Fields[DocIderIndex].AsInteger;
    Len := SizeOf(TBankPayRec);
    Res := DocDataSet.BtrBase.GetEqual(PayRec, Len, DocIder, 0);
    if Res=0 then
    begin
      ADocCode := PayRec.dbDoc.drType;
      DLLModule := GetModuleByCode(ADocCode);
      if DLLModule<>0 then
      begin
        P := GetProcAddress(DLLModule, EditRecordDLLProcName);
        if P<>nil then
          EditRecord(P)(Self, @PayRec, True)
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
  AccComboBoxClick(nil);
  {PostMessage(Handle, WM_MAKEACCLIST, 0, 0);}
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

procedure TMakesForm.FindAccItemClick(Sender: TObject);
{var
  Res: integer;
  Key0: longint;
  KeyO: word;
  po: TOpRec;
  pa: TAccRec;
  pac: PAccInfoRec;
  ANewDate: TDateTime;
  Action: Boolean;
  Year, Month, Day: Word;
  AccList: TStringList;
  T: array[0..arMaxVar-1] of Char;}
begin
  (*
  ShowAcc(False);
  ClearStrings(AccComboBox.Items);
  AccChanged := True;
  {AccComboBox.Enabled := False;}
  StatusMessage('');

  BillDate1 := StrToBtrDate(FromDateEdit.Text);
  BillDate2 := StrToBtrDate(ToDateEdit.Text);

  KeyO := BillDate1;
  Len := SizeOf(po);
  Res := BillDataSet.BtrBase.GetLE(po, Len, KeyO, 2);
  if Res=0 then
  begin
    if (po.brDate<BillDate1) and
      (MessageBox(Handle, PChar('Выписка за указанную дату не найдена.'+#13+#10
        +'Предыдущая выписка обнаружена за '+BtrDateToStr(po.brDate)+#13+#10
        +'Показать счета за эту дату?'),
        'Поиск счетов', MB_YESNOCANCEL or MB_ICONQUESTION) = ID_YES) then
    begin
      BillDate1 := po.brDate;
      ANewDate := StrToDate(BtrDateToStr(BillDate1));
      Action := True;
      FromDateEditAcceptDate(Sender, ANewDate, Action);
    end
    else begin
      try
        { Выбор счета, по которому строить выписку }
        StatusMessage('Поиск счетов...');
        DBGrid.Cursor := crHourGlass;
        AccList := TStringList.Create;
        Len := SizeOf(pa);
        Res := AccDataSet.BtrBase.GetFirst(pa, Len, Key0, 0);
        while Res=0 do
        begin
          if (BillDate1>pa.arDateO) and
            ((pa.arDateC=0) or (BillDate2<=pa.arDateC)) then
          begin
            New(pac);
            with pac^ do
            begin
              acAccount := pa.arAccount;
              StrCopy(acName, pa.arName);
            end;
            AccList.AddObject(pac^.acAccount, TObject(pac));
          end;
          Len := SizeOf(pa);
          Res := AccDataSet.BtrBase.GetNext(pa, Len, Key0, 0);
        end;
        AccList.Sort;
        Len := AccList.Count-1;
        AccComboBox.Items.Clear;
        for Res := 0 to Len do
        begin
          pac := Pointer(AccList.Objects[Res]);
          StrLCopy(T, pac^.acName, SizeOf(T));
          DosToWin(T);
          AccComboBox.Items.AddObject(pac^.acAccount+' | '+T, TObject(pac));
        end;
        StatusMessage('Найдено счетов: '+IntToStr(AccComboBox.Items.Count));
      finally
        DBGrid.Cursor := crDefault;
        AccList.Free;

        AccComboBox.Enabled := AccComboBox.Items.Count>0;
        AccComboBoxClick(Sender);
      end;
    end;
  end
  else
    MessageBox(Handle, 'Нет выписок за указанную дату и ранее', 'Поиск счетов',
      MB_OK or MB_ICONINFORMATION); *)
end;

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
begin
  ShowAcc(False);
  RxMemoryData.EmptyTable;
  if AccComboBox.Enabled and (Length(AccComboBox.Text)>0) then
  begin
    if not AbortBtn.Visible then
    begin
      try
        StrLCopy(BillAcc, PChar(AccComboBox.Text), SizeOf(BillAcc)-1);
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
          KeyO := DateFrom;
          Len := SizeOf(po);
          Res := BillDataSet.BtrBase.GetGT(po, Len, KeyO, 2);
          while (Res=0) and (po.brDate<=DateTo) and AbortBtn.Visible do
          begin
            FillChar(PChar(@po)[Len], SizeOf(po)-Len, #0);
            if (po.brDel=0) and (po.brPrizn=brtBill) and
              ((StrLComp(po.brAccD, BillAcc, SizeOf(TAccount))=0)
              or (StrLComp(po.brAccC, BillAcc, SizeOf(TAccount))=0)) then
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
                end
            end;
            Len := SizeOf(po);
            Res := BillDataSet.BtrBase.GetNext(po, Len, KeyO, 2);
            Application.ProcessMessages;
          end;
          if AbortBtn.Visible then
          begin
            AbortBtn.Hide;
            { Проверка остатка по счету }
            if BillList.bcOstIn+BillList.bcCredit-BillList.bcDebet
              <> BillList.bcOstOut then
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
              SetVarior('bcDate1', BtrDateToStr(bcDate1));
              SetVarior('bcDate2', BtrDateToStr(bcDate2));
              DosToWin(@bcName);
              SetVarior('bcName', bcName);
              SetVarior('bcDate', DateToStr(Date));
              SetVarior('bcTime', TimeToStr(Time));

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
  AccComboBox.Left := L+Dist;
  AccLabel.Left := AccComboBox.Left;
  AbortBtn.Left := AccComboBox.Left + AccComboBox.Width + 2*Dist;
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
    AccComboBoxClick(nil);
end;

procedure TMakesForm.AccComboBoxClick(Sender: TObject);
begin
  PostMessage(Handle, WM_MAKESTATEMENT, 0, 0);
end;

procedure TMakesForm.FromDateEditChange(Sender: TObject);
begin
  DataIsChanged := True;
end;

procedure TMakesForm.FormShow(Sender: TObject);
begin
  AccComboBox.Perform(CB_SETDROPPEDWIDTH, 460, 0);
end;

(*procedure TMakesForm.FormActivate(Sender: TObject);
var
  I: Integer;
  C: TComponent;
begin
  I := 0;
  with Application.MainForm do
  begin
    while (I<MDIChildCount) and (MDIChildren[I].Name<>'PaydocsForm') do
      Inc(I);
    if I<MDIChildCount then
    begin
      PaydocsForm := MDIChildren[I] as TDataBaseForm;
      C := PaydocsForm.FindComponent('PaydocDBGrid');
      if (C<>nil) and (C is TDBGrid) then
        PaydocDBGrid := C as TDBGrid;
    end;
  end;
end;*)

type
  PForm = ^TForm;

procedure TMakesForm.MoveItemClick(Sender: TObject);
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


end.
