unit PaydocsFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Grids, Db, DBTables, DBGrids, ExtCtrls, DBCtrls, BtrDS, Menus, StdCtrls,
  ToolEdit, Mask, ComCtrls, SearchFrm, DateFrm,
  ImgList, Btrieve, Common, Bases, Utilits, Registr, CommCons,
  Buttons, ClntCons, DocFunc, CrySign;

type
  TPaydocsForm = class(TDataBaseForm)
    DataSource: TDataSource;
    ChildMenu: TMainMenu;
    OperItem: TMenuItem;
    EditItem: TMenuItem;
    DelItem: TMenuItem;
    NewItem: TMenuItem;
    DBGrid: TDBGrid;
    CopyItem: TMenuItem;
    SearchItem: TMenuItem;
    EditBreaker: TMenuItem;
    EditBreaker1: TMenuItem;
    BillItem: TMenuItem;
    StatusBar: TStatusBar;
    BtnPanel: TPanel;
    SearchIndexComboBox: TComboBox;
    NameLabel: TLabel;
    EditBreaker2: TMenuItem;
    CloseDaysItem: TMenuItem;
    OpenDaysItem: TMenuItem;
    SignItem: TMenuItem;
    EditPopupMenu: TPopupMenu;
    BenefMemo: TMemo;
    PayerMemo: TMemo;
    PayerLabel: TLabel;
    BenefLabel: TLabel;
    ExchangeItem: TMenuItem;
    ReturnItem: TMenuItem;
    CheckItem: TMenuItem;
    SignedItem: TMenuItem;
    AbortBtn: TBitBtn;
    N1: TMenuItem;
    SaveDocItem: TMenuItem;
    SaveDocDialog: TSaveDialog;
    DelAllSignItem: TMenuItem;
    DelSignItem: TMenuItem;
    StatusItem: TMenuItem;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure EditItemClick(Sender: TObject);
    procedure DelItemClick(Sender: TObject);
    procedure SearchItemClick(Sender: TObject);
    procedure BillItemClick(Sender: TObject);
    procedure SearchIndexComboBoxChange(Sender: TObject);
    procedure CloseDaysItemClick(Sender: TObject);
    procedure OpenDaysItemClick(Sender: TObject);
    procedure SignItemClick(Sender: TObject);
    procedure BtnPanelResize(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure ReturnItemClick(Sender: TObject);
    procedure ExchangeItemClick(Sender: TObject);
    procedure DataSourceDataChange(Sender: TObject; Field: TField);
    procedure DBGridDrawColumnCell(Sender: TObject; const Rect: TRect;
      DataCol: Integer; Column: TColumn; State: TGridDrawState);
    procedure FormResize(Sender: TObject);
    procedure CheckItemClick(Sender: TObject);
    procedure SignedItemClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure AbortBtnClick(Sender: TObject);
    procedure SaveDocItemClick(Sender: TObject);
    procedure DelAllSignItemClick(Sender: TObject);
    procedure DelSignItemClick(Sender: TObject);
    procedure StatusItemClick(Sender: TObject);
  private
    SearchForm: TSearchForm;
    procedure MakeFormMenuItems;
    {function GetCurrentModule: HModule;}
    procedure InsertItemClick(Sender: TObject);
    procedure WMMakeStatement(var Message: TMessage); message WM_MAKESTATEMENT;
  protected
    function UserMayEditDoc(ADocCode: Byte): Boolean;
    function TestNonClosedDays: Boolean;
    function SignPaydoc(var PayRec: TPayRec; Overwrite: Boolean): Integer;
  public
    procedure UpdateDocumentByCode(CopyCurrent, New, ReadOnly: Boolean;
      ADocCode: Byte);
    function GetBank(Bik: string; var BankFullRec: TBankFullNewRec): Boolean;
    procedure TakeFormPrintData(var PrintDocRec: TPrintDocRec; var FormList: TList); override;
    function FindPrepareSum(AccStr: string; Ider: Integer): Comp;
  end;

  PAccColRec = ^TAccColRec;
  TAccColRec = packed record
    acNumber: TAccount;
    acIder:   longint;
    acFDate:   word;
    acTDate:   word;
    acSumma:  comp;
    acSumma2: comp;
  end;

  TAccList = class(TList)
  protected
  public
    destructor Destroy; override;
    procedure Clear; override;
    function SearchAcc(Acc: PChar): Integer;
  end;

const
  DocTypeIndex = 18;

var
  PaydocsForm: TPaydocsForm;
  DLLList: TList;
  PayObjList: TList;

function GetModuleByCode(Code: Byte): HModule;

implementation

uses BillsFrm, SignedDocsFrm, StatusFrm{, StatusFrm};

{$R *.DFM}

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
          try
            if StrToInt(AList.Names[J])=Code then
              Result := DLLModule;
          except
            Result := 0;
          end;
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

{function TPaydocsForm.GetCurrentModule: HModule;
begin
  Result := GetModuleByCode(PPayRec(DataSource.DataSet.ActiveBuffer)^.dbDoc.drType);
end;}

var
  DefPayVO: Integer = 101;

procedure TPaydocsForm.MakeFormMenuItems;
var
  I,J,K,L: Integer;
  DLLModule: HModule;
  P: Pointer;
  MI: TMenuItem;
  AList: TStringList;
  S: string;
begin
  AList := TStringList.Create;
  try
    for I:=1 to DLLList.Count do
    begin
      DLLModule:=HINST(DLLList.Items[I-1]);
      if DLLModule<>0 then
      begin
        P := GetProcAddress(DLLModule, DocumentsDLLProcName);
        if P<>nil then
        begin
          AList.Clear;
          GetDocuments(P)(AList);
          for K := 0 to AList.Count-1 do
          begin
            try
              J := StrToInt(AList.Names[K]);
            except
              J := 0;
            end;
            L := Pos('=', AList.Strings[K]);
            S := Copy(AList.Strings[K], L+1, Length(AList.Strings[K])-L);
            if (Length(S)>0) and (S[1]<>'*') then
            begin
              MI := TMenuItem.Create(NewItem.Owner);
              with MI do
              begin
                Tag := J;
                Caption := S;
                Hint := 'Создает новый документ';
                OnClick := InsertItemClick;
                if Tag=DefPayVO then
                begin
                  ImageIndex := 2;
                  ShortCut := TextToShortCut('Ins');
                end;
              end;
              NewItem.Add(MI);
            end;
          end;
        end else
          MessageBox(Handle, PChar('Нет процедуры инициализации диалога'
            +IntToStr(I)), DlgTitle, MB_OK or MB_ICONERROR)
      end;
    end;
  finally
    AList.Free
  end;
end;

var
  ReceiverNode: Integer = -1;
  CheckAccSum: Boolean = False;
  OurBankBik: Integer = -1;
  AccDataSet: TExtBtrDataSet = nil;
  AccArcDataSet: TExtBtrDataSet = nil;
  BillDataSet: TExtBtrDataSet = nil;
  DocDataSet: TPayDataSet = nil;
  ControlData: TControlData;
  AllowList: string = '';
  NumOfSign: Integer = 0;
  DoubleAddMode: Integer = 0;
  PrintStamp: Boolean = False;                             //Добавлено Меркуловым
  MasterKeyUpdate: Boolean;                                //Добавлено Меркуловым
  KeyUpdDate: Word;                                        //Добавлено Меркуловым

procedure TPaydocsForm.FormCreate(Sender: TObject);
var
  User: TUserRec;
  ColorPayState: Boolean;
  T: array[0..511] of Char;
  List1, List2, List3: string;
begin
  FillChar(ControlData, SizeOf(ControlData), #0);
  PayObjList.Add(Self);
  if not GetRegParamByName('ReceiverNode', CommonUserNumber, ReceiverNode) then
    ReceiverNode := -1;
  if not GetRegParamByName('CheckAccSum', CommonUserNumber, CheckAccSum) then
    CheckAccSum := False;
  if not GetRegParamByName('DefPayVO', CommonUserNumber, DefPayVO) then
    DefPayVO := 101;
  if not GetRegParamByName('NumOfSign', CommonUserNumber, NumOfSign) then
    NumOfSign := 1;
  //Добавлено Меркуловым
  if not GetRegParamByName('PrintStamp', CommonUserNumber, PrintStamp) then
    PrintStamp := False;
  if not GetRegParamByName('MasterKeyUpdate', CommonUserNumber, MasterKeyUpdate) then
    MasterKeyUpdate := False;
  if not GetRegParamByName('KeyUpdDate', CommonUserNumber, KeyUpdDate) then
    KeyUpdDate := StrToBtrDate('18.05.2004');
  if not GetRegParamByName('DoubleAddMode', CommonUserNumber, DoubleAddMode) then
    DoubleAddMode := 0;
  try
    OurBankBik := StrToInt(DecodeMask('$(BankBik)', 5, CommonUserNumber));
  except
    OurBankBik := -1;
  end;
  AccDataSet := GlobalBase(biAcc);
  AccArcDataSet := GlobalBase(biAccArc);
  BillDataSet := GlobalBase(biBill);
  DocDataSet := GlobalBase(biPay) as TPayDataSet;
  DataSource.DataSet := DocDataSet;
  MakeUserList(List1, List2, List3);
  AllowList := List1+DividerOfList+List2+DividerOfList+List3;
  DefineGridCaptions(DBGrid, PatternDir+'Paydocs.tab');
  MakeFormMenuItems;
  SearchForm := TSearchForm.Create(Self);
  SearchForm.SourceDBGrid := DBGrid;
  SearchIndexComboBox.ItemIndex := 0;
  SearchIndexComboBoxChange(Sender);
  TakeMenuItems(OperItem, EditPopupMenu.Items);
  EditPopupMenu.Images := ChildMenu.Images;
  CurrentUser(User);
  BillItem.Visible := User.urLevel=0;
  if not GetRegParamByName('ColorPayState', CommonUserNumber, ColorPayState) then
    ColorPayState := False;
  if not ColorPayState then
    DBGrid.OnDrawColumnCell := nil;
  with ControlData do
  begin
    cdTagNode := ReceiverNode;
    cdCheckSelf := False;
    if GetRegParamByName('ReceiverAcc', CommonUserNumber, T) then
    begin
      StrLCopy(cdTagLogin, T, SizeOf(cdTagLogin)-1);
    end
    else
      cdTagLogin := 'CBTCB';
    {if GetRegParamByName('SenderAcc', CommonUserNumber, T) then
      AddWordInList(T, cdLoginList);}
  end;
end;

procedure TPaydocsForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
end;

procedure TPaydocsForm.FormDestroy(Sender: TObject);
begin
  PayObjList.Remove(Self);
  PaydocsForm := nil;
end;

type
  GetPrintForm = function: TFileName;

//Загрузка форм печати
procedure TPaydocsForm.TakeFormPrintData(var PrintDocRec: TPrintDocRec; var FormList: TList);
var
  I: Byte;
  //Добавлено Меркуловым
  RegistrBase: TBtrBase;
  ParamRec: TParamNewRec;
  ParamVec: TParamKey0;
  PasSerial, PasNumber, PasPlace, NaznPlat, CType: string;
  SimSum, Simvol: array [0..5] of String;
  J, J1, L, NSim, CorrRes, Res: Integer;
  Number, PAcc, PKs, PCode, PInn, PClient, PBank,
  RAcc, RKs, RCode, RInn, RClient, RBank, Purpose, PKpp, RKpp,
  Status, Kbk, Okato, OsnPl, Period, NDoc, DocDate, TipPl,
  Nchpl, Shifr, Nplat, OstSum: string;
  AState: Word;
  OpRec: TOpRec;
  Trnsns: Boolean;                                      //Проведен ?
begin
  Nsim := 0;                                            //Добавлено
  J := 0;                                               //Добавлено
  CType := '';                                          //Добавлено
  Trnsns := False;                                      //Добавлено
  inherited;
  PrintDocRec.DBGrid := Self.DBGrid;
  I := PPayRec(DataSource.DataSet.ActiveBuffer)^.dbDoc.drType;
  case I of
    1,2,6,16,91,92:
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
// Изменено и добавлено Меркуловым
    3:
      begin

        //Добавлено Меркуловым
        DecodeDocVar(PPayRec(DataSource.DataSet.ActiveBuffer)^.dbDoc,
        PPayRec(DataSource.DataSet.ActiveBuffer)^.dbDocVarLen,
        Number, PAcc, PKs, PCode, PInn, PClient, PBank,
        RAcc, RKs, RCode, RInn, RClient, RBank, Purpose, PKpp, RKpp,
        Status, Kbk, Okato, OsnPl, Period, NDoc, DocDate, TipPl,
        Nchpl, Shifr, Nplat, OstSum, 0, 0, CorrRes, False);
        //Выделяем часть "Назначение ордера"
        L := Length(Purpose);
 //       MessageBox(ParentWnd,PChar(Purpose),'Проверка',MB_OK);             //Отладка
        while (J<L) and (Purpose[J] <> #10) and (Purpose[J] <> #13) do
          Inc(J);
        if (J<L) then
          NaznPlat := Copy (Purpose,1,J);
 //       MessageBox(ParentWnd,PChar(NaznPlat),'Проверка',MB_OK);             //Отладка
        if (J<L) then
          J := J+2;
        J1 := J;
        //Заполним массив "символов" ордера
 //       MessageBox(ParentWnd,'3','Проверка',MB_OK);             //Отладка
        while (J<L) and (Purpose[J1-1]<>'~') do
          begin
          if (Purpose[J]='-') then
            begin
            Simvol[NSim] := Copy(Purpose,J1,(J-J1));
  //          MessageBox(ParentWnd,PChar(Simvol[Nsim]),'Проверка',MB_OK);  //Отладка
            while (J<L) and (Purpose[J]<>';') and (Purpose[J]<>'~') do
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
 //       MessageBox(ParentWnd,PChar(IntToStr(PrintDocRec.CassCopy)),'Проверка',MB_OK);             //Отладка
        if(PrintDocRec.CassCopy=0) then
          begin
          SetVarior('CassCopy',' ');
          PrintDocRec.CassCopy := StrToInt(DecodeMask('$(CassCopy)', 5, CommonUserNumber));
          end;
        if(PrintDocRec.CassCopy>0) then
          SetVarior('CassCopy',IntToStr(PrintDocRec.CassCopy)+' экз.');
//        MessageBox(ParentWnd,PChar(Purpose),'Проверка',MB_OK);             //Отладка

        if (J1<L) and (Purpose[J1]>='0') and (Purpose[J1]<='9') then
          begin
   //     MessageBox(ParentWnd,'6','Проверка',MB_OK);             //Отладка
          //Заполняем поля паспортных данных
          //Серия
          J1 := J;
          while (J<L) and (Purpose[J-1]<>' ') do
            begin
              if (Purpose[J] = ' ') then
                PasSerial := Copy(Purpose,J1,(J-J1));
              Inc(J);
            end;
//          MessageBox(ParentWnd,PChar(PasSerial),'Проверка серии',MB_OK);             //Отладка
          J1:=J;
          //Номер
          while (J<L) and (Purpose[J]<>' ') do
            Inc(J);
          if (J<L) and (Purpose[J] = ' ') then
            PasNumber := Copy(Purpose,J1,(J-J1));
  //        MessageBox(ParentWnd,PChar(PasNumber),'Проверка номера',MB_OK);             //Отладка
          J1:=J+1;
          //Дата и место выдачи
          PasPlace := Copy(Purpose,J1,L);
    //      MessageBox(ParentWnd,PChar(PasPlace),'Проверка ДМВ',MB_OK);             //Отладка
    //      PrintDocRec.GraphForm := DecodeMask('$(CashRecGraphForm)', 5, CommonUserNumber);
    //      PrintDocRec.TextForm := DecodeMask('$(CashRecTextForm)', 5, CommonUserNumber);
          //Объявляем глобальные переменные данных паспорта
          SetVarior('PasSerial',PasSerial);
          SetVarior('PasNumber',PasNumber);
          SetVarior('PasPlace',PasPlace);
      //    MessageBox(ParentWnd,'Расх','Проверка',MB_OK);             //Отладка
          end
        else if (J1<L) then
          begin
          // Обьявляем гл.перем.Ф.И.О.
          SetVarior('FIO',Copy(Purpose,J1,L));
   //       MessageBox(ParentWnd,'Прих','Проверка',MB_OK);             //Отладка
   //       PrintDocRec.GraphForm := DecodeMask('$(CashExpGraphForm)', 5, CommonUserNumber);
   //       PrintDocRec.TextForm := DecodeMask('$(CashExpTextForm)', 5, CommonUserNumber);
          end;
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
          // Определяем тип ордера в зав-ти от символа
          RegistrBase := GetRegistrBase;
          with RegistrBase do
            begin
            with ParamVec do
              begin
              pkSect := 10;
              pkNumber := 0;
              pkUser := CommonUserNumber;
              end;
            L := SizeOf(ParamRec);
            Res := RegistrBase.GetGE(ParamRec, L, ParamVec, 0);
            while (Res=0) and (ParamRec.pmSect = 10) and (CType='') do
              begin
              with ParamRec do
                if (pmNumber=StrToInt(Simvol[NSim+1])) then
                  CType := pmMeasure;
              L := SizeOf(ParamRec);
              Res := RegistrBase.GetNext(ParamRec, L, ParamVec, 0);
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
      //Добавлено/изменено Меркуловым
      if PrintStamp=True then
        begin
        PrintDocRec.GraphForm := DecodeMask('$(PayWSGraphForm)', 5, CommonUserNumber);
        PrintDocRec.TextForm := DecodeMask('$(PayWSTextForm)', 5, CommonUserNumber);
        end
      else
        begin
        PrintDocRec.GraphForm := DecodeMask('$(GrForm101)', 5, CommonUserNumber);
        PrintDocRec.TextForm := DecodeMask('$(TxForm101)', 5, CommonUserNumber);
        end;
      end;
    191:
      begin
        PrintDocRec.GraphForm := DecodeMask('$(GrForm102)', 5, CommonUserNumber);
        PrintDocRec.TextForm := DecodeMask('$(TxForm102)', 5, CommonUserNumber);
      end;
    else begin
      //Добавлено/изменено Меркуловым
      AState := PPayRec(DataSource.DataSet.ActiveBuffer)^.dbState;
      if GetDocOp(OpRec, PPayRec(DataSource.DataSet.ActiveBuffer)^.dbIdKorr)>0 then
        with OpRec do
          if (brPrizn=brtBill) {and (AState and dsInputDoc)=0)} then
            Trnsns := True;
      if PrintStamp and (I=101) and Trnsns then
        begin
        PrintDocRec.GraphForm := DecodeMask('$(PayWSGraphForm)', 5, CommonUserNumber);
        PrintDocRec.TextForm := DecodeMask('$(PayWSTextForm)', 5, CommonUserNumber);
        end
      else begin
        PrintDocRec.GraphForm := DecodeMask('$(GrForm'+IntToStr(I)+')', 5, CommonUserNumber);
        PrintDocRec.TextForm := DecodeMask('$(TxForm'+IntToStr(I)+')', 5, CommonUserNumber);
      end;
    end;
  end;
end;

type
  EditBankRecord = function(Sender: TComponent; RecPtr: Pointer;
    SearchIndex: Integer; ShowDlg: Boolean): Boolean;

function TPaydocsForm.GetBank(Bik: string; var BankFullRec: TBankFullNewRec):
  Boolean;
var
  ModuleName: array[0..511] of Char;
  Module: HModule;
  P: Pointer;
  Err: Integer;
begin
  Result := False;
  StrPLCopy(ModuleName, DecodeMask('$(Banks)', 5, CommonUserNumber), SizeOf(ModuleName));
  Module := GetModuleHandle(ModuleName);
  if Module=0 then
    MessageDlg('Не найден модуль диалога выбора банка'+#13+'['+ModuleName+']',
      mtError,[mbOk],0)
  else begin
    P:=GetProcAddress(Module, EditRecordDLLProcName);
    if P=nil then
      MessageDlg('Не найдена функция модуля '+EditRecordDLLProcName+'()',
        mtError,[mbOk],0)
    else begin
      with BankFullRec do
        Val(Bik, brCod, Err);
      if Err=0 then
        Result := EditBankRecord(P)(Self, @BankFullRec, 0, False);
    end;
  end;
end;

function PaydocSignMayChangeByOper(var PayRec: TPayRec; CommLen: Integer;
  var S: string): Boolean;
{var
  Len, Res: Integer;
  AUserRec: TUserRec;}
begin
  Result := {not IsSigned(PayRec, CommLen)}True;
  if not Result then
  begin
    (*S := 'Подпись уже существует';
    {CheckSign(@PayRec.dbDoc, SizeOf(TDocRec)-drMaxVar+PayRec.dbDocVarLen,
      Len-(SizeOf(PayRec)-SizeOf(PayRec.dbDoc)),
      smShowInfo, @ControlData);}
    (*
    if GetCryptoEngineIndex=ceiTcbGost then
    begin
      NT := 0;
      NF := 0;
      NO := 0;
      Len := (SizeOf(PayRec.dbDoc)-drMaxVar+SignSize)+PayRec.dbDocVarLen;
      Res := TestSign(@PayRec.dbDoc, Len, NF, NO, NT);???
      if {NF<>ReceiverNode}NF=GetNode then
      begin
        Result := {(NF<>GetNode) or} not GetUserByOperNum(NO, AUserRec);
        if not Result then
        begin
          if LevelIsSanctioned(AUserRec.urLevel) then
            Result := True
          else
            S := 'Подписан пользователем большего уровня';
        end;
      end
      else
        S := 'Подписано на другом узле';
    end
    else begin
      S := 'Подпись старого образца';
      if IsCryptoEngineInited then
        Result := True;
    end; *)
  end;
end;

function GetAccSum(AccStr: string; var Sum: comp; var AccKind: Integer): Boolean;
var
  AccRec: TAccRec;
  Len, Res: Integer;
  Acc: array[0..SizeOf(TAccount)] of Char;
begin
  Result := False;
  Len := SizeOf(AccRec);
  StrPLCopy(Acc, AccStr, SizeOf(Acc)-1);
  Res := AccDataSet.BtrBase.GetEqual(AccRec, Len, Acc, 1);
  if Res=0 then
  begin
    Sum := AccRec.arSumA;
    AccKind := AccRec.arOpts and asType;
    Result := True;
  end
  else
    Sum := 0;
end;

function TPaydocsForm.FindPrepareSum(AccStr: string; Ider: Integer): Comp;
var
  Len, Res, I: Integer;
  PayRec: TPayRec;
  Number, PAcc, PKs, PCode, PInn, PClient, PBank,
    RAcc, RKs, RCode, RInn, RClient, RBank, Nazn, PKpp, RKpp,
    Status, Kbk, Okato, OsnPl, Period, NDoc, DocDate, TipPl,
    Nchpl, Shifr, Nplat, OstSum: string;
begin
  Result := 0;
  AbortBtn.Visible := True;
  DataSource.Enabled := False;
  try
    Len := SizeOf(PayRec);
    Res := DocDataSet.BtrBase.GetFirst(PayRec, Len, I, 3);
    while ((Res=0) or (Res=22)) and AbortBtn.Visible do
    begin
      if (Res=0) and ((PayRec.dbState and dsSndType)=dsSndEmpty)
        and (Ider<>PayRec.dbIdHere) and IsSigned(PayRec, Len) then
      begin
        DecodeDocVar(PayRec.dbDoc, PayRec.dbDocVarLen,
          Number, PAcc, PKs, PCode, PInn, PClient, PBank,
          RAcc, RKs, RCode, RInn, RClient, RBank, Nazn, PKpp, RKpp,
          Status, Kbk, Okato, OsnPl, Period, NDoc, DocDate, TipPl,
          Nchpl, Shifr, Nplat, OstSum, 0, 3, Len, False);
        if AccStr=PAcc then
          Result := Result + PayRec.dbDoc.drSum;
        if AccStr=RAcc then
          Result := Result - PayRec.dbDoc.drSum;
      end;
      Len := SizeOf(PayRec);
      Res := DocDataSet.BtrBase.GetNext(PayRec, Len, I, 3);
      Application.ProcessMessages;
    end;
  finally
    AbortBtn.Visible := False;
    DataSource.Enabled := True;
    DocDataSet.UpdateKeys;
    DocDataSet.Refresh;
  end;
end;

function TPaydocsForm.SignPaydoc(var PayRec: TPayRec; Overwrite: Boolean): Integer;
const
  MesTitle: PChar = 'Создание подписи';
var
  Sum, Sum0: comp;
  Number, PAcc, PKs, PCode, PInn, PClient, PBank,
    RAcc, RKs, RCode, RInn, RClient, RBank, Nazn, PKpp, RKpp,
    Status, Kbk, Okato, OsnPl, Period, NDoc, DocDate, TipPl,
    Nchpl, Shifr, Nplat, OstSum, ErrMes: string;
  I, ActKind, Mode: Integer;
  AppInfo: Pointer;
begin
  Result := 0;
  if ReceiverNode>=0 then
  begin
    if IsSanctAccess('SignDocSanc') then               //Добавлено Меркуловым
    begin                                              //Добавлено Меркуловым
      //Добавлено Меркуловым
      if MasterKeyUpdate and (Date>=BtrDateToDate(KeyUpdDate)) then
        MessageBox(Application.Handle,'В связи со сменой мастер-ключа Вы не можете подписать документ.'
          +#10#13+'Пожайлуста, произведите сеанс связи, после чего перезапустите Клиент-Банк.', MesTitle, MB_OK)
      //Конец
      else begin
        if DoubleAddMode<>0 then
          Number := Trim(StrPas(@PayRec.dbDoc.drVar[0]));
        if (DoubleAddMode=0) or (not IsPayDocExist(DocDataSet, PayRec.dbIdOut, Number,
          0{PayRec.dbDoc.drDate}, PayRec.dbDoc.drType,
          0{PayRec.dbDoc.drSum}) or (DoubleAddMode=2) and (MessageBox(Application.Handle,
          PChar('Документ с номером ['+Number+'] уже существует'#13#10'Подписать этот повторный документ?'),
          MesTitle, MB_YESNOCANCEL or MB_DEFBUTTON2 or MB_ICONWARNING)=ID_YES)) then
        begin
          if CheckAccSum then
          begin
            DecodeDocVar(PayRec.dbDoc, PayRec.dbDocVarLen,
              Number, PAcc, PKs, PCode, PInn, PClient, PBank,
              RAcc, RKs, RCode, RInn, RClient, RBank, Nazn, PKpp, RKpp,
              Status, Kbk, Okato, OsnPl, Period, NDoc, DocDate, TipPl,
              Nchpl, Shifr, Nplat, OstSum, 0, 3, I, False);
            if GetAccSum(PAcc, Sum0, ActKind) then
            begin
              if ActKind=0 then
              begin
                Sum := FindPrepareSum(PAcc, PayRec.dbIdHere);
                if Sum0-(Sum+PayRec.dbDoc.drSum)<0 then
                  MessageBox(Handle, PChar('Сумма этого платежа '+SumToStr(PayRec.dbDoc.drSum)
                    +#13#10'вместе с другими платежами '+SumToStr(Sum)
                    +#13#10'превышает остаток '+SumToStr(Sum0)+#13#10'на счете '+PAcc
                    +#13#10'Возможно, информация по остатку устарела'),
                    MesTitle, MB_OK or MB_ICONWARNING);
              end;
            end;
          end;
          //Добавлено Меркуловым
          //  GetRegParamByName('NumOfSign',CommonUserNumber,I);
          //  while (I>0) do
          //    begin
          Mode := smShowInfo;
          if ((PayRec.dbState and dsExtended)<>0) or Overwrite then
          begin
            Mode := Mode or smExtFormat or smCertVerify;        //Изменено Меркуловым
            PayRec.dbState := PayRec.dbState or dsExtended;
          end;
          if Overwrite then
            Mode := Mode or smOverwrite;
          AppInfo := @ControlData;
          if (NumOfSign<0) and ((Mode and smExtFormat)<>0)
            and ((Mode and smOverwrite)=0) then
          begin
            Mode := Mode or smOneSignInLevel;
            AppInfo := @ClientGetLoginNameProc;
          end;
          I := AnalyzePayDoc(PayRec.dbDoc, PayRec.dbDocVarLen, OurBankBik, 10, '', ErrMes);
          if I=2 then
            MessageBox(Application.Handle, PChar('Исправьте недопустимые ошибки:'#13#10
              +ErrMes+'.'#13#10'Подпись не может быть создана'), MesTitle, MB_ICONERROR or MB_OK)
          else
            Result :=
              AddSign(0, @PayRec.dbDoc, SizeOf(TDocRec)-drMaxVar+PayRec.dbDocVarLen,
                SizeOf(TDocRec), Mode, AppInfo, AllowList);
          //showmessage(inttostr(Result));
          {MakeSign(PChar(@PayRec.dbDoc),
          PayRec.dbDocVarLen+SizeOf(TDocRec)-drMaxVar, ReceiverNode, 1)>0;}
          {if Result=0 then
          MessageBox(Application.Handle, 'Не удалось сгенерировать подпись',
          MesTitle, MB_ICONERROR or MB_OK);}
          //Добавлено Меркуловым
        end;
      end;
    end;
  end
  else
    MessageBox(Application.Handle, 'Не известен узел получателя',
      MesTitle, MB_ICONERROR or MB_OK);
end;

function TPaydocsForm.UserMayEditDoc(ADocCode: Byte): Boolean;
var
  I: Integer;
begin
  with NewItem do
  begin
    I := 0;
    while (I<Count) and (Items[I].Tag<>ADocCode) do Inc(I);
    Result := (I<Count) and (Count>0);
  end;
end;

procedure TPaydocsForm.UpdateDocumentByCode(CopyCurrent, New, ReadOnly: Boolean;
  ADocCode: Byte);
const
  MesTitle: PChar = 'Редактирование записи';
var
  DLLModule: HModule;
  P: Pointer;
  PayRec: TPayRec;
  LastIdHere, Offset, I, Num, SignLen, Len: Integer;
  Year, Month, Day: Word;
  Bik, ErrMes: string;
  T: array[0..1023] of Char;
  BankFullRec: TBankFullNewRec;
  SignNew: Boolean;
  OpRec: TOpRec;
  SignDescr: TSignDescr;
  JustSign: Boolean;
begin
  Len :=0;
  JustSign := False;
  if not ReadOnly and New and CopyCurrent and (ADocCode=1) then
    ADocCode := DefPayVO;
  DLLModule := GetModuleByCode(ADocCode);
  if DLLModule<>0 then
  begin
    P := GetProcAddress(DLLModule, EditRecordDLLProcName);
    if P<>nil then
    begin
      ReadOnly := ReadOnly or not UserMayEditDoc(ADocCode);
      if New and ReadOnly then
        MessageBox(Handle, 'Вы не можете создать документ такого типа',
          MesTitle, MB_OK or MB_ICONINFORMATION)
      else begin
        with DocDataSet do
        begin
          if New then
          begin
            MakeRegNumber(rnPaydoc, LastIdHere);
            if LastIdHere<0 then
            begin
              MessageBox(Handle, 'Не могу определить последний идентификатор'#13#10
                +'Сообщите о данной ошибке в банк',
                MesTitle, MB_OK or MB_ICONERROR);
              Exit;
            end;
          end;
          if CopyCurrent then
            Len := GetBtrRecord(PChar(@PayRec))
          else
            FillChar(PayRec, SizeOf(PayRec), #0);
          if New then
          begin
            DecodeDate(Date, Year, Month, Day);
            with PayRec do
            begin
              dbDoc.drDate := CodeBtrDate(Year, Month, Day);
              dbDoc.drIsp := 2;
              if GetRegParamByName('PaySeq', CommonUserNumber, I) then
                dbDoc.drOcher := I
              else
                dbDoc.drOcher := 6;
              I := ADocCode;
              if I>100 then
                I := I - 100;
              if not GetRegParamByName('PayNum'+IntToStr(I), CommonUserNumber, Num) then
                Num := 0;
              if CopyCurrent then
              begin
                I := StrLen(@dbDoc.drVar[0])+1;
                Offset := dbDocVarLen-I;
                Move(dbDoc.drVar[I], T, Offset);
                StrPCopy(@dbDoc.drVar[0], IntToStr(Num+1));
                I := StrLen(@dbDoc.drVar[0])+1;
                Move(T, dbDoc.drVar[I], Offset);
                dbDocVarLen := Offset + I;
              end
              else begin
                {CurrentFirm(FirmRec, FirmAccRec);}
                Bik := FillZeros(OurBankBik, 9);
                if not GetBank(Bik, BankFullRec) then
                  with BankFullRec do
                  begin
                    Bik := '045744803';
                    brKs := '30101810700000000803';
                    brName := 'ФАКБ "ТРАНСКАПИТАЛБАНК"'+#13#10+'Г. ПЕРМЬ';
                  end;
                Offset := 0;
                if ADocCode<>3 then
                begin
                  for I := 21 to 34 do
                  begin
                    case I of
                      21: StrPCopy(T, IntToStr(Num+1));
                      22: StrPCopy(T, {FirmAccRec.faAcc}'');
                      23: StrPCopy(T, BankFullRec.brKs);
                      24: StrPCopy(T, Bik);
                      25: StrPCopy(T, {FirmRec.frInn}'');
                      26: begin
                            {if StrLen(FirmRec.frKpp)>0 then
                              StrPCopy(T, 'КПП '+FirmRec.frKpp+#13#10+FirmRec.frName)
                            else}
                              StrPCopy(T, ''{FirmRec.frName});
                          end;
                      27: StrPCopy(T, BankFullRec.brName);
                      else
                        StrPCopy(T, '');
                    end;
                    WinToDos(T);
                    StrPCopy(@dbDoc.drVar[Offset], T);
                    Offset := Offset+StrLen(T)+1;
                  end;
                end
                else begin
                  for I := 21 to 34 do
                  begin
                    case I of
                      21: StrPCopy(T, IntToStr(Num+1));
                      22:
                        if not GetRegParamByName('CashAcc', CommonUserNumber, T) then
                          StrPCopy(T, '');
                      23: StrPCopy(T, BankFullRec.brKs);
                      24: StrPCopy(T, Bik);
                      26,27: StrPCopy(T, BankFullRec.brName);
                      {31: StrPCopy(T, FirmRec.frInn);}
                      {32,33: StrPCopy(T, BankFullRec.brName);}
                      else
                        StrPCopy(T, '');
                    end;
                    WinToDos(T);
                    StrPCopy(@dbDoc.drVar[Offset], T);
                    Offset := Offset+StrLen(T)+1;
                  end;
                end;
                dbDocVarLen := Offset;
              end;
              dbIdHere := LastIdHere;
              dbIdKorr :=0;
              dbIdIn := 0;
              dbIdOut := dbIdHere;
              dbIdArc := 0;
              dbIdDel := 0;
              dbState := 0;
              dbDoc.drType := ADocCode;
              dbDateS := 0;
              dbDateR := 0;
              dbTimeS := 0;
              dbTimeR := 0;
            end;
          end;
          ReadOnly := ReadOnly or (PayRec.dbIdHere=0);
          if not ReadOnly then
          begin
            //AState := PPayRec(ARecBuffer)^.dbState;
            if GetDocOp(OpRec, PayRec.dbIdKorr)>0 then
              ReadOnly := True
            else begin
              ReadOnly := not((PayRec.dbState and dsSndType)=dsSndEmpty);
              if not New and not ReadOnly then
              begin
                if IsSigned(PayRec, Len) and not IsCryptoEngineInited then
                  ReadOnly := True
                else begin
                  if (PayRec.dbState and dsExtended>0) then
                  begin
                    SignDescr.siLoginNameProc := nil;
                    CheckSign(@PayRec.dbDoc, SizeOf(TDocRec)-drMaxVar+PayRec.dbDocVarLen,
                      Len-(SizeOf(PayRec)-SizeOf(PayRec.dbDoc)), smExtFormat, @ControlData,
                      @SignDescr, AllowList);
                    if (SignDescr.siCount>1) and (SignDescr.siOwnIndex>0) then
                      ReadOnly := True
                    else
                      if (SignDescr.siCount>1) or (SignDescr.siOwnIndex<0) and (SignDescr.siCount>0) then
                      begin
                        if IsSanctAccess('SignDocSanc') then
                          JustSign := True
                        else
                          ReadOnly := True
                      end;
                    {or (DocState = adsSigned) and (New
                    or IsCryptoEngineInited and PaydocSignMayChangeByOper(PayRec,
                      DocState, Bik))}
                  end;
                end;
              end;
            end;
          end;
          {if not ReadOnly then
          begin
            if (PayRec.dbDoc.drType=1) and (Date>=StrToDate('01.06.2003')) then
              MessageBox(Handle, 'Данная форма устарела. Используйте форму "с 01 июня 2003"',
                MesTitle, MB_OK or MB_ICONWARNING);
            if (PayRec.dbDoc.drType=101) and (Date<StrToDate('01.06.2003')) then
              MessageBox(Handle, 'Данная форма еще не действует. Используйте форму "до 01 июня 2003"',
                MesTitle, MB_OK or MB_ICONWARNING);
          end;}
          repeat
            ErrMes := '';
            I := 0;
            if ReadOnly then
              I := 1;
            if JustSign then
              I := 2;
            if (New and CopyCurrent) and not ReadOnly then
              I := I+10;
            if PaydocEditRecord(P)(Self, @PayRec, I, New
              and not CopyCurrent) then
            begin
              SignLen := 0;
              if JustSign then
              begin
                SignNew := IsSigned(PayRec, Len);
                SignLen := SignPaydoc(PayRec, not SignNew);
              end
              else begin
                if not GetRegParamByName('SignPaydoc', CommonUserNumber, SignNew) then
                  SignNew := False;
                FillChar(PChar(@PayRec.dbDoc.drVar)[PayRec.dbDocVarLen],
                  drMaxVar-PayRec.dbDocVarLen, #0);
                PayRec.dbState := PayRec.dbState or dsExtended;
                if SignNew and IsCryptoEngineInited then
                  SignLen := SignPaydoc(PayRec, True);
              end;
              I := SizeOf(TPayRec)-drMaxVar+PayRec.dbDocVarLen+SignLen;
              if SearchIndexComboBox.ItemIndex<>0 then
              begin
                SearchIndexComboBox.ItemIndex := 0;
                SearchIndexComboBoxChange(Self);
              end;
              if New then
              begin
                if AddBtrRecord(PChar(@PayRec), I) then
                  Refresh
                else
                  MessageBox(Handle, PChar('Не удалось добавить запись Id='
                    +IntToStr(PayRec.dbIdHere)), MesTitle, MB_OK or MB_ICONERROR)
              end
              else begin
                Num := PayRec.dbIdHere;
                if LocateBtrRecordByIndex(Num, 0, bsEq) then
                begin
                  if UpdateBtrRecord(PChar(@PayRec), I) then
                    UpdateCursorPos
                  else
                    MessageBox(Handle, PChar('Не удалось обновить запись Id='
                      +IntToStr(PayRec.dbIdHere)), MesTitle, MB_OK or MB_ICONERROR)
                end
                else
                  MessageBox(Handle, 'Не удалось установить курсор на запись',
                    MesTitle, MB_OK or MB_ICONERROR);
              end;
              Bik := StrPas(@PayRec.dbDoc.drVar[0]);
              Val(Bik, Num, Offset);
              if Offset=0 then
              begin
                I := PayRec.dbDoc.drType;
                if I>100 then
                  I := I - 100;
                SetRegParamByName('PayNum'+IntToStr(I), CommonUserNumber, False, IntToStr(Num));
              end;
              DataSourceDataChange(nil, nil);
            end;
          until ErrMes='';
        end;
      end;
    end
    else
      MessageBox(Handle, 'В модуле нет функции редактирования записи',
        MesTitle, MB_OK or MB_ICONERROR)
  end
  else
    MessageBox(Handle, 'Текущей записи не сопоставлен модуль редактирования',
      MesTitle, MB_OK or MB_ICONERROR)
end;

var
  DelMode: Integer = 0;

procedure TPaydocsForm.SignItemClick(Sender: TObject);
const
  MesTitle: PChar = 'Изменение подписи';
var
  PayRec: TPayRec;
  I,R,N,K,J,Err,Num: Integer;
  U: Boolean;
  Len, SignLen: Word;
  S: string;
  OpRec: TOpRec;
  SignDescr: TSignDescr;
  ASign: PChar;
begin
  S := '';
  if IsCryptoEngineInited then
  begin
    with DocDataSet do
    begin
      N := DBGrid.SelectedRows.Count;
      if N>0 then
        Dec(N);
      for R := 0 to N do
      begin
        if R<DBGrid.SelectedRows.Count then
          Bookmark := DBGrid.SelectedRows.Items[R];
        Len := GetBtrRecord(@PayRec);
        if Len>0 then
        begin
          Num := PayRec.dbIdHere;
          if PayRec.dbIdOut<>0 then
          begin
            if UserMayEditDoc(PayRec.dbDoc.drType) then
            begin
              //DocState := GetDocState(@PayRec);
              if GetDocOp(OpRec, PayRec.dbIdKorr)<=0 then
              begin
                if {(DocState = adsSigned) or (DocState = adsNone)}
                  (PayRec.dbState and dsSndType)=dsSndEmpty then
                begin
                  U := PaydocSignMayChangeByOper(PayRec, Len, S);
                  if U or IsSanctAccess('DelSignSanc') then
                  begin
                    if U or (MessageBox(Handle,
                      PChar(S+'. Вы желаете снять подпись?'+DocInfo(PayRec)),
                      MesTitle, MB_YESNOCANCEL or MB_ICONWARNING
                      or MB_DEFBUTTON2)=ID_YES) then
                    begin
                      SignLen := 0;
                      if Sender=nil then
                      begin
                        U := IsSigned(PayRec, Len);
                        if U then
                        begin
                          if (DelMode=0) or (PayRec.dbState and dsExtended=0) then
                          begin  {снятие всех подписей}
                            FillChar(PChar(@PayRec.dbDoc.drVar)[PayRec.dbDocVarLen],
                              {SignSize}(drMaxVar-PayRec.dbDocVarLen), #0);     //Изменено Меркуловым
                          end
                          else begin  {снятие одной подписи}
                            U := False;
                            CheckSign(@PayRec.dbDoc, SizeOf(TDocRec)-drMaxVar+PayRec.dbDocVarLen,
                              Len-(SizeOf(PayRec)-SizeOf(PayRec.dbDoc)), smExtFormat, @ControlData,
                              @SignDescr, AllowList);
                            if SignDescr.siCount>0 then
                            begin
                              if SignDescr.siOwnIndex>0 then
                              begin
                                ASign := @PayRec.dbDoc.drVar[PayRec.dbDocVarLen];
                                with SignDescr do
                                begin
                                  K := 0;
                                  siLen := siCount*4;
                                  Err := siLen;
                                  for I := 1 to siCount do
                                  begin
                                    J := PInteger(@ASign[I*4])^;
                                    if I<>siOwnIndex then
                                    begin
                                      Inc(K);
                                      Move(ASign[4+siLen], ASign[4+Err], J);
                                      PInteger(@ASign[K*4])^ := J;
                                      Inc(Err, J);
                                    end;
                                    Inc(siLen, J);
                                  end;
                                  if (K>0) and (siCount>0) then
                                    Move(ASign[4+siCount*4], ASign[4+K*4], Err-siCount*4);
                                  siLen := Err-siCount*4+K*4;
                                  PInteger(ASign)^ := K;
                                  siCount := K;
                                  siValid := svChanged;
                                  if siLen>0 then
                                    SignLen := siLen+4;
                                  U := True;
                                end;
                              end
                              else
                                MessageBox(Handle, PChar('Документ не имеет Вашей подписи'
                                  +DocInfo(PayRec)), MesTitle, MB_OK or MB_ICONINFORMATION);
                            end;
                          end;
                        end
                        else
                          MessageBox(Handle, PChar('Документ не имеет ни одной подписи'
                            +DocInfo(PayRec)), MesTitle, MB_OK or MB_ICONINFORMATION);
                      end
                      else begin
                        U := False;
                        I := AnalyzePayDoc(PayRec.dbDoc, PayRec.dbDocVarLen, OurBankBik, 10, '', S);
                        if I=2 then
                          MessageBox(Handle, PChar('Недопустимые ошибки в документе:'#13#10
                            +S+DocInfo(PayRec)), MesTitle, MB_OK or MB_ICONWARNING)
                        else begin
                          if (I=0) or (MessageBox(Handle, PChar('Ошибки в документе:'#13#10
                            +S+DocInfo(PayRec)), MesTitle,
                            MB_ABORTRETRYIGNORE or MB_ICONWARNING)=ID_IGNORE) then
                          begin
                            U := IsSigned(PayRec, Len);
                            SignLen := SignPaydoc(PayRec, not U);
                            U := SignLen>0;
                          end;
                        end;
                      end;
                      if U then
                      begin
                        I := SizeOf(TPayRec)-drMaxVar+PayRec.dbDocVarLen+SignLen;
                        if LocateBtrRecordByIndex(Num, 0, bsEq) then
                        begin
                          if UpdateBtrRecord(PChar(@PayRec), I) then
                            Refresh
                          else
                            MessageBox(Handle, 'Не удалось обновить запись',
                              MesTitle, MB_OK or MB_ICONERROR)
                        end
                        else
                          MessageBox(Handle, 'Не удалось спозиционироваться на запись',
                            MesTitle, MB_OK or MB_ICONERROR)
                      end;
                    end;
                  end
                  else
                    MessageBox(Handle, PChar(S+'. Нельзя изменить подпись'
                      +DocInfo(PayRec)), MesTitle, MB_OK or MB_ICONINFORMATION)
                end
                else
                  MessageBox(Handle,
                    PChar('Документ уже отправлен в банк. Нельзя изменить подпись'
                    +DocInfo(PayRec)), MesTitle, MB_OK or MB_ICONINFORMATION)
              end
              else
                MessageBox(Handle,
                  PChar('По документу есть операция. Нельзя изменить подпись'
                  +DocInfo(PayRec)), MesTitle, MB_OK or MB_ICONINFORMATION)
            end
            else
              MessageBox(Handle, PChar('Вы не можете изменить подпись документа типа '
                +IntToStr(PayRec.dbDoc.drType)
                +DocInfo(PayRec)),
                MesTitle, MB_OK or MB_ICONINFORMATION)
          end
          else
            MessageBox(Handle,
              PChar('Изменить состояние подписи можно только у исходящих документов'
              +DocInfo(PayRec)), MesTitle, MB_OK or MB_ICONINFORMATION)
        end;
      end;
    end;
  end
  else
    MessageBox(Handle, 'Подпись не инициализирована', MesTitle, MB_OK or MB_ICONWARNING);
end;

procedure TPaydocsForm.EditItemClick(Sender: TObject);
var
  Code, Err: Integer;
  ReadOnly, New: Boolean;
begin
  with DataSource.DataSet do
  begin
    Val(Fields.Fields[DocTypeIndex].AsString, Code, Err);
    if Err=0 then
    begin
      ReadOnly := Sender=nil;
      New := not ReadOnly and ((Sender as TComponent).Tag=1);
      UpdateDocumentByCode(True, New, ReadOnly, Code)
    end;
  end;
end;

procedure TPaydocsForm.InsertItemClick(Sender: TObject);
var
  Code: Integer;
begin
  Code := (Sender as TMenuItem).Tag;
  UpdateDocumentByCode(False, True, False, Code)
end;

procedure TPaydocsForm.DelItemClick(Sender: TObject);
const
  MesTitle: PChar = 'Удаление';
var
  N, LI, C, I, Len: Integer;
  PayRec: TPayRec;
  DS: TPayDataSet;

  function PaydocCanDel(var PayRec: TPayRec; Len: Integer): Boolean;
  var
    //DocState: Integer;
    S: string;
    OpRec: TOpRec;
  begin
    S := '';
    Result := False;
    if PayRec.dbIdArc = 0 then
    begin
      if GetDocOp(OpRec, PayRec.dbIdKorr)<=0 then
      begin
        if (PayRec.dbState and dsSndType)=dsSndEmpty then
        begin
          if IsSanctAccess('DelPaydocSanc') or not (IsSigned(PayRec, Len)) then
          begin
            Result := PaydocSignMayChangeByOper(PayRec, {DocState}0, S);
            if Result then
            begin
              if PayRec.dbIdOut<>0 then
                Result := True
              else begin
                Result := IsSanctAccess('DelNoBillDocSanc');
                if Result then
                begin
                  Result := MessageBox(Handle,
                    PChar('Документ не имеет проводки, но существует в банке.'
                    +#13#10'Вы согласовали это удаление с банком?'
                    +DocInfo(PayRec)), MesTitle,
                    MB_YESNOCANCEL or MB_ICONWARNING) = ID_YES
                end
                else
                  S := 'Вы не можете удалять принятые документы';
              end;
            end;
          end
          else
            S := 'Вы не можете удалять документы';
        end
        else
          S := 'Документ уже отправлен в банк';
      end
      else
        S := 'Нельзя удалять документы с операцией';
    end
    else
      S := 'Нельзя удалить архивный документ';
    if not Result and (Length(S)>0) then
      MessageBox(Handle, PChar(S+DocInfo(PayRec)), MesTitle,
        MB_OK or MB_ICONINFORMATION);
  end;

begin
  DBGrid.SelectedRows.Refresh;
  N := DBGrid.SelectedRows.Count;
  DS := TPayDataSet(DataSource.DataSet);
  with DS do
  begin
    LI := N;
    if N=0 then
      Inc(LI)
    else
      if (N>1) and (MessageBox(Handle, PChar('Будет удалено документов: '
        +IntToStr(N)+#13#10'Вы уверены?'), MesTitle,
        MB_YESNOCANCEL or MB_ICONQUESTION) <> IDYES)
      then
        LI := 0;
    C := LI;
    I := 0;
    while I<LI do
    begin
      if N>0 then
        Bookmark := DBGrid.SelectedRows.Items[I];
      Len := GetBtrRecord(@PayRec);
      if (Len>0) and PaydocCanDel(PayRec, Len)
        and ((N>1) or (MessageBox(Handle,
          PChar('Документ будет удален. Вы уверены?'+DocInfo(PayRec)),
          MesTitle, MB_YESNOCANCEL or MB_ICONQUESTION) = IDYES)) then
      begin
        Delete;
        Dec(C);
      end;
      Inc(I);
    end;
    DBGrid.SelectedRows.Refresh;
  end;
  if (N>1) and (C>0) then
    MessageBox(Handle, PChar('Не удалось удалить документов: '+IntToStr(C)),
      MesTitle, MB_OK or MB_ICONWARNING);
end;

procedure TPaydocsForm.SearchItemClick(Sender: TObject);
begin
  SearchForm.ShowModal;
end;

procedure TPaydocsForm.BillItemClick(Sender: TObject);
begin
  if BillsForm = nil then
    BillsForm := TBillsForm.Create(Self)
  else
    BillsForm.Show;
end;

procedure TPaydocsForm.SearchIndexComboBoxChange(Sender: TObject);
var
  I: Integer;
begin
  with DocDataSet do
  begin
    case SearchIndexComboBox.ItemIndex of
      0: I := 3;  {Исходящие}
      1: I := 2;  {Входящие}
      2: I := 4;  {Архив}
      else
        I := 0;  {Все}
    end;
    if IndexNum<>I then
    begin
      IndexNum := I;
      Sender := Self;
    end;
    if Sender<>nil then
      Last;
  end;
  if Visible then
    DBGrid.SetFocus;
end;

procedure TAccList.Clear;
var
  I: Integer;
begin
  try
    try
      for I := 0 to Count-1 do
        Dispose(Items[I]);
    except
      MessageBox(ParentWnd, 'Ошибка освобождения памяти', 'Список счетов',
        MB_OK or MB_ICONERROR);
    end;
  finally
    inherited Clear;
  end;
end;

destructor TAccList.Destroy;
begin
  Clear;
  inherited Destroy;
end;

{function TAccList.SearchAcc(Acc: PChar): Integer;
begin
  try
    Result := 0;
    while (Result<Count) and (Items[Result]<>nil)
      and (StrLComp(Acc, @PAccColRec(Items[Result])^.acNumber,
        SizeOf(TAccount))<>0) do
          Inc(Result);
    if Result>=Count then
      Result := -1;
  except
    Result := -1;
    MessageBox(Handle, 'Ошибка поиска счета', 'Список счетов', MB_OK or MB_ICONERROR);
  end;
end;}

function TAccList.SearchAcc(Acc: PChar): Integer;
var
  L, H, I, C: Integer;
begin
  Result := -1;
  try
    L := 0;
    H := Count - 1;
    while L <= H do
    begin
      I := (L + H) shr 1;
      C := StrLComp(@PAccColRec(Items[I])^.acNumber, Acc, SizeOf(TAccount));
      if C < 0 then
        L := I + 1
      else begin
        H := I - 1;
        if C = 0 then
          Result := I;
      end;
    end;
  except
    MessageBox(Application.MainForm.Handle, 'Ошибка поиска счета',
      'Список счетов', MB_OK or MB_ICONERROR);
  end;
end;

function Compare(Key1, Key2: Pointer): Integer;
var
  k1: PAccColRec absolute Key1;
  k2: PAccColRec absolute Key2;
begin
  if k1^.acNumber<k2^.acNumber then
    Result := -1
  else
  if k1^.acNumber>k2^.acNumber then
    Result := 1
  else
    Result :=0
end;

procedure TPaydocsForm.CloseDaysItemClick(Sender: TObject);
const
  MesTitle: PChar = 'Закрытие опердней';
var
  KeyAA:
    packed record
      aaIder: longint;
      aaDate: word;
    end;
  KeyO: Word;
  Sum: Comp;
  I, K, Len, Res, Res1: Integer;
  Key0: Longint;
  LastDate, FirstDate, MaxDate: word;
  Errors: boolean;
  AccRec: TAccRec;
  AccArcRec: TAccArcRec;
  BillRec: TOpRec;
  PayRec: TPayRec;
  AccList: TAccList;
  PAccCol: PAccColRec;
  Date1, Date2: TDateTime;
  CloseDayLim: Integer;
begin
  if IsSanctAccess('ArchDaysSanc') then
  try
    DataSource.Enabled := False;
    LastDate := 0;
    Len := SizeOf(AccArcRec);
    Res := AccArcDataSet.BtrBase.GetLast(AccArcRec, Len, KeyAA, 0);
    if Res=0 then
      LastDate := AccArcRec.aaDate;
    { Найдем проводки по незакрытым дням }
    StatusBar.SimpleText := 'Поиск проводок по незакрытым дням...';
    KeyO := LastDate;
    Len := SizeOf(BillRec);
    Res := BillDataSet.BtrBase.GetGT(BillRec, Len, KeyO, 2);
    while (Res=0) and (BillRec.brDel<>0) do
    begin
      Len := SizeOf(BillRec);
      Res := BillDataSet.BtrBase.GetNext(BillRec, Len, KeyO, 2);
    end;
    StatusBar.SimpleText := '';
    if Res=0 then
    begin
      MaxDate := DateToBtrDate(Date-5.0);{BillRec.brDate}
      if GetBtrDate(MaxDate, 'Закрытие дней', '&Закрыть по',
        'При этой операции документы указанной даты и ранее (более старые) перейдут из списков "Исходящие" и "Входящие" в список "Архив". Закрывайте только полностью отработанные дни.') then
      begin
        if MaxDate>LastDate then
        begin
          if not GetRegParamByName('CloseDayLim', CommonUserNumber, CloseDayLim) then
            CloseDayLim := 0;
          try
            Date1 := StrToDate(BtrDateToStr(MaxDate));
          except
            CloseDayLim := 0;
          end;
          Date2 := Date;
          if (CloseDayLim = 0)
            or (Trunc(Date2)-Trunc(Date1)>=CloseDayLim)
            or (MessageBox(Handle, 'Возможно, еще не все документы проведены за указанный период. Вы хотите закрыть дни?',
              MesTitle, MB_YESNOCANCEL or MB_ICONWARNING)=ID_YES) then
          begin
            { Инициализация списка счетов }
            StatusBar.SimpleText := 'Инициализация списка счетов...';
            FirstDate := $FFFF;
            AccList := TAccList.Create;
            Len := SizeOf(AccRec);
            Res := AccDataSet.BtrBase.GetFirst(AccRec, Len, Key0, 0);
            while Res=0 do
            begin
              if (AccRec.arDateC=0) or (AccRec.arDateC>LastDate) then
              begin
                PAccCol := New(PAccColRec);
                with PAccCol^ do
                begin
                  acNumber := AccRec.arAccount;
                  acIder := AccRec.arIder;
                  acFDate := AccRec.arDateO;
                  acTDate := AccRec.arDateC;
                  if acTDate=0 then
                    acTDate := $FFFF;
                  acSumma := AccRec.arSumS;
                  acSumma2 := AccRec.arSumS;

                  KeyAA.aaIder := AccRec.arIder;
                  KeyAA.aaDate := $FFFF;
                  Len := SizeOf(AccArcRec);
                  Res := AccArcDataSet.BtrBase.GetLE(AccArcRec, Len, KeyAA, 1);
                  with AccArcRec do
                  begin
                    if (Res=0) and (aaIder=AccRec.arIder) and (acFDate<aaDate) then
                    begin
                      acFDate := aaDate;
                      acSumma := aaSum;
                      acSumma2 := aaSum;
                    end;
                  end;
                  if acFDate<FirstDate then
                    FirstDate := acFDate;
                  {@++}
                  if acFDate<LastDate then
                  begin
                    MessageBox(Handle, PChar('По счету '
                      +PAccCol^.acNumber+' необходимо раскрыть дни по '
                      +BtrDateToStr(PAccCol^.acFDate)), MesTitle, MB_OK
                      or MB_ICONWARNING);
                  end;
                  {@--}
                end;
                AccList.Add(PAccCol);
              end;
              Len := SizeOf(AccRec);
              Res := AccDataSet.BtrBase.GetNext(AccRec, Len, Key0, 0);
            end;
            if FirstDate>=LastDate then
            begin
              AccList.Sort(Compare);
              { Просчет состояний счетов по выпискам }
              StatusBar.SimpleText := 'Просчет состояний счетов по выпискам...';
              KeyO := LastDate;
              Len := SizeOf(BillRec);
              Res := BillDataSet.BtrBase.GetGT(BillRec, Len, KeyO, 2);
              while Res=0 do
              begin
                if (BillRec.brDel=0) and (BillRec.brPrizn=brtBill) then
                begin
                  Sum := BillRec.brSum;
                  K := AccList.SearchAcc(@BillRec.brAccD);
                  if K>=0 then
                  begin
                    PAccCol := AccList.Items[K];
                    if (BillRec.brDate>PAccCol^.acFDate)
                      and (BillRec.brDate<=PAccCol^.acTDate) then
                        PAccCol^.acSumma := PAccCol^.acSumma - Sum;
                  end;
                  K := AccList.SearchAcc(@BillRec.brAccC);
                  if K>=0 then
                  begin
                    PAccCol := AccList.Items[K];
                    if (BillRec.brDate>PAccCol^.acFDate)
                      and (BillRec.brDate<=PAccCol^.acTDate) then
                        PAccCol^.acSumma := PAccCol^.acSumma + Sum;
                  end;
                end;
                Len := SizeOf(BillRec);
                Res := BillDataSet.BtrBase.GetNext(BillRec, Len, KeyO, 2);
              end;
              { Проверка соответствия состояний счетов просчитанным по выпискам }
              StatusBar.SimpleText := 'Проверка состояний счетов на соответствие выпискам...';
              Errors := False;
              I := 0;
              while I<AccList.Count do
              begin
                PAccCol := AccList.Items[I];
                Key0 := PAccCol^.acIder;
                Len := SizeOf(AccRec);
                Res := AccDataSet.BtrBase.GetEqual(AccRec, Len, Key0, 0);
                if Res=0 then
                begin
                  if PAccCol^.acSumma<>AccRec.arSumA then
                  begin
                    MessageBox(Handle, PChar('Ошибка остатка по счету '
                      +PAccCol^.acNumber+' на сумму '
                      +SumToStr(AccRec.arSumA-PAccCol^.acSumma)+'.'
                      +#13#10'Присланные выписки не соответствуют текущему остатку'),
                      MesTitle, MB_OK or MB_ICONWARNING);
                    Errors := True
                  end;
                end;
                Inc(I);
              end;
              StatusBar.SimpleText := '';
              if not Errors then
              begin
                Screen.Cursor := crHourGlass;
                KeyO := LastDate;
                Len := SizeOf(BillRec);
                Res := BillDataSet.BtrBase.GetGT(BillRec, Len, KeyO, 2);
                while (Res=0) and (BillRec.brDate<=MaxDate) do
                begin
                  FirstDate := BillRec.brDate;
                  StatusBar.SimpleText := 'Закрытие дня '+BtrDateToStr(FirstDate)+'...';
                  { Перепись док-тов из текущих в архив }
                  while (Res=0) and (BillRec.brDate=FirstDate) do
                  begin
                    if Billrec.brDel=0 then
                    begin
                      Key0 := BillRec.brDocId;
                      Len := SizeOf(PayRec);
                      Res := DocDataSet.BtrBase.GetEqual(PayRec, Len, Key0, 1);
                      if Res=0 then
                        with PayRec do
                        begin
                          dbIdIn := 0;
                          dbIdOut := 0;
                          dbIdArc := dbIdHere;
                          Res := DocDataSet.BtrBase.Update(PayRec, Len, Key0, 1);
                        end;
                      if BillRec.brPrizn=brtBill then
                      begin
                        Sum := BillRec.brSum;
                        K := AccList.SearchAcc(@BillRec.brAccD);
                        if K>=0 then
                        begin
                          PAccCol := AccList.Items[K];
                          if (BillRec.brDate>PAccCol^.acFDate)
                            and (BillRec.brDate<=PAccCol^.acTDate) then
                              PAccCol^.acSumma2 := PAccCol^.acSumma2 - Sum;
                        end;
                        K := AccList.SearchAcc(@BillRec.brAccC);
                        if K>=0 then
                        begin
                          PAccCol := AccList.Items[K];
                          if (BillRec.brDate>PAccCol^.acFDate)
                            and (BillRec.brDate<=PAccCol^.acTDate) then
                              PAccCol^.acSumma2 := PAccCol^.acSumma2 + Sum;
                        end;
                      end;
                    end;
                    Len := SizeOf(BillRec);
                    Res := BillDataSet.BtrBase.GetNext(BillRec, Len, KeyO, 2);
                  end;
                  { Сохранение остатков на счетах в архиве }
                  I := 0;
                  while I<AccList.Count do
                  begin
                    PAccCol := AccList.Items[I];
                    if (FirstDate>PAccCol^.acFDate) and (FirstDate<=PAccCol^.acTDate) then
                    begin
                      with AccArcRec do
                      begin
                        aaIder := PAccCol^.acIder;
                        aaDate := FirstDate;
                        aaSum := PAccCol^.acSumma2;
                      end;
                      Len := SizeOf(AccArcRec);
                      Res1 := AccArcDataSet.BtrBase.Insert(AccArcRec, Len, KeyAA, 0);
                    end;
                    Inc(I);
                  end;
                end;
                StatusBar.SimpleText := 'Операционные дни закрыты';
                Screen.Cursor := crDefault;
                MessageBox(Handle, 'Операционные дни закрыты', MesTitle,
                  MB_OK or MB_ICONINFORMATION);
              end
            end
            else begin
              StatusBar.SimpleText := '';
              MessageBox(Handle, PChar('По счету '
                +PAccCol^.acNumber+' необходимо раскрыть дни по '
                +BtrDateToStr(PAccCol^.acFDate)), MesTitle, MB_OK or MB_ICONWARNING);
            end;
            AccList.Free;
          end;
        end
        else begin
          MessageBox(Handle, PChar('Уже закрыты дни по '+BtrDateToStr(LastDate)),
            MesTitle, MB_OK or MB_ICONINFORMATION);
        end;
      end
    end
    else begin
      MessageBox(Handle, 'Нет операций - нечего закрывать', MesTitle,
        MB_OK or MB_ICONINFORMATION);
    end;
  finally
    Screen.Cursor := crDefault;
    AccDataSet.Refresh;
    DocDataSet.UpdateKeys;
    DocDataSet.Refresh;
    DataSource.Enabled := True;
  end
  else
    MessageBox(Handle, 'Вы не можете закрывать/открывать опердни', 'Закрытие дней',
      MB_OK or MB_ICONINFORMATION);
end;

procedure TPaydocsForm.OpenDaysItemClick(Sender: TObject);
const
  MesTitle: PChar = 'Раскрытие опердней';
var
  Len, Res: Integer;
  Key0: Longint;
  KeyAA:
    packed record
      aaIder: Longint;
      aaDate: Word;
    end;
  KeyO: word;
  BillRec: TOpRec;
  AccArcRec: TAccArcRec;
  PayRec: TPayRec;
  LastDate, PrevDate, MaxDate: word;
  UpdateErr: Boolean;
begin
  if IsSanctionAccess(3) then
  try
    DataSource.Enabled := False;
    LastDate := 0;
    Len := SizeOf(AccArcRec);
    Res := AccArcDataSet.BtrBase.GetLast(AccArcRec, Len, KeyAA, 0);
    if Res=0 then
    begin
      LastDate := AccArcRec.aaDate;
      MaxDate := LastDate;
      if GetBtrDate(MaxDate, 'Раскрытие дней', '&Раскрыть с',
        'При этой операции документы указанной даты и позднее (более свежие) перейдут из списка "Архив" обратно в списки "Исходящие" и "Входящие".') then
      begin
        if MaxDate<=LastDate then
        begin
          Screen.Cursor := crHourGlass;
          while LastDate>=MaxDate do
          begin
            StatusBar.SimpleText := 'Раскрытие дня '+BtrDateToStr(LastDate)+'...';
            PrevDate := 0;
            KeyAA.aaDate := LastDate;
            KeyAA.aaIder := 0;
            Res := AccArcDataSet.BtrBase.GetLT(AccArcRec, Len, KeyAA, 0);
            if Res=0 then
              PrevDate := AccArcRec.aaDate;
            { Переписать документы из архива в текущие }
            KeyO := LastDate+1;
            Len := SizeOf(BillRec);
            Res := BillDataSet.BtrBase.GetLT(BillRec, Len, KeyO, 2);
            UpdateErr := False;
            while (Res=0) and (BillRec.brDate>PrevDate) do
            begin
              if BillRec.brDel=0 then
              begin
                Key0 := BillRec.brDocId;
                Len := SizeOf(PayRec);
                Res := DocDataSet.BtrBase.GetEqual(PayRec, Len, Key0, 1);
                if Res=0 then
                begin
                  PayRec.dbIdArc := 0;
                  if (PayRec.dbState and dsInputDoc)<>0 then
                    PayRec.dbIdIn := PayRec.dbIdHere
                  else
                    PayRec.dbIdOut := PayRec.dbIdHere;
                  Res := DocDataSet.BtrBase.Update(PayRec, Len, Key0, 1);
                  if Res<>0 then
                    UpdateErr := True;
                end;
              end;
              Len := SizeOf(BillRec);
              Res := BillDataSet.BtrBase.GetPrev(BillRec, Len, KeyO, 2);
            end;
            if UpdateErr then
              MessageBox(Handle, 'Не удалось переписать некоторые документы',
                MesTitle, MB_OK or MB_ICONWARNING);
            { Удалить из архива состояний счетов состояния за последнюю дату }
            Len := SizeOf(AccArcRec);
            Res := AccArcDataSet.BtrBase.GetLast(AccArcRec, Len, KeyAA, 0);
            while (Res=0) and (AccArcRec.aaDate>=LastDate) do
            begin
              Res := AccArcDataSet.BtrBase.Delete(0);
              Len := SizeOf(AccArcRec);
              Res := AccArcDataSet.BtrBase.GetPrev(AccArcRec, Len, KeyAA, 0);
            end;
            LastDate := 0;
            if Res=0 then
              LastDate := AccArcRec.aaDate;
          end;
          Screen.Cursor := crDefault;
          StatusBar.SimpleText := '';
          MessageBox(Handle, 'Операционные дни раскрыты', MesTitle,
            MB_OK or MB_ICONINFORMATION);
        end
        else begin
          MessageBox(Handle, PChar('Дни закрыты только по '+BtrDateToStr(LastDate)),
            MesTitle, MB_OK or MB_ICONWARNING);
        end
      end;
    end
    else begin
      MessageBox(Handle, 'Нет закрытых дней', MesTitle,
        MB_OK or MB_ICONINFORMATION);
    end;
  finally
    Screen.Cursor := crDefault;
    {DocBase.Free;
    BillBase.Free;
    AccArcBase.Free;}
    BillDataSet.Refresh;
    AccArcDataSet.Refresh;
    DocDataSet.UpdateKeys;
    DocDataSet.Refresh;
    DataSource.Enabled := True;
  end
  else
    MessageBox(Handle, 'Вы не можете закрывать/открывать опердни', 'Раскрытие дней',
      MB_OK or MB_ICONINFORMATION);
end;

const
  MemoDist = 5;

procedure TPaydocsForm.BtnPanelResize(Sender: TObject);
var
  I: Integer;
begin
  I := (BtnPanel.ClientWidth - PayerMemo.Left - 2*MemoDist) div 2;
  with PayerMemo do
    SetBounds(Left, Top, I, Height);
  with BenefMemo do
    SetBounds(PayerMemo.Left + I + MemoDist, Top, I, Height);
  PayerLabel.Left := PayerMemo.Left;
  BenefLabel.Left := BenefMemo.Left;
end;

function TPaydocsForm.TestNonClosedDays: Boolean;
const
  MesTitle: PChar = 'Проверка незакрытых опердней';
var
  KeyAA:
    packed record
      aaIder: longint;
      aaDate: word;
    end;
  KeyO: Word;
  Res, Len: Integer;
  LastDate, MaxDate: word;
  AccArcRec: TAccArcRec;
  BillRec: TOpRec;
  AccArcDataSet, BillDataSet: TExtBtrDataSet;
var
  AutoCloseDay: Integer;
  Date1, Date2: TDateTime;
begin
  Result := False;
  if GetRegParamByName('AutoCloseDay', CommonUserNumber, AutoCloseDay) and (AutoCloseDay>0) then
  try
    StatusBar.SimpleText := 'Проверка незакрытых опердней...';

    AccArcDataSet := GlobalBase(biAccArc);
    BillDataSet := GlobalBase(biBill);

    LastDate := 0;
    Len := SizeOf(AccArcRec);
    Res := AccArcDataSet.BtrBase.GetLast(AccArcRec, Len, KeyAA, 0);
    if Res=0 then
      LastDate := AccArcRec.aaDate;
    KeyO := LastDate;

    Len := SizeOf(BillRec);
    Res := BillDataSet.BtrBase.GetGT(BillRec, Len, KeyO, 2);
    while (Res=0) and (BillRec.brDel<>0) do
    begin
      Len := SizeOf(BillRec);
      Res := BillDataSet.BtrBase.GetNext(BillRec, Len, KeyO, 2);
    end;

    StatusBar.SimpleText := '';
    if Res=0 then
    begin
      MaxDate := BillRec.brDate;
      try
        Date1 := StrToDate(BtrDateToStr(MaxDate));
      except
        AutoCloseDay := 0;
        Date1 := 0;
      end;
      Date2 := Date;
      Len := Trunc(Date2)-Trunc(Date1);
      Result := (AutoCloseDay > 0) and (Len>=AutoCloseDay)
        and (MessageBox(Handle, PChar('Вы не закрывали операционные дни '
          +IntToStr(Len)+' дней.'+#13#10'Хотите закрыть дни?'),
          MesTitle, MB_YESNOCANCEL or MB_ICONQUESTION) = IDYES);
    end;
  finally
    StatusBar.SimpleText := '';
  end;
end;

procedure TPaydocsForm.WMMakeStatement(var Message: TMessage);
begin
  if TestNonClosedDays then
    CloseDaysItemClick(Self);
end;

const
  WasAsked: Boolean = False;

procedure TPaydocsForm.FormShow(Sender: TObject);
begin
  BtnPanelResize(Sender);
  if not WasAsked then
  begin
    PostMessage(Handle, WM_MAKESTATEMENT, 0, 0);
    WasAsked := True;
  end;
end;

procedure TPaydocsForm.ReturnItemClick(Sender: TObject);
const
  MesTitle1: PChar = 'Причина возврата';
  MesTitle2: PChar = 'Причина картотеки';
var
  PayRec: TPayRec;
  Bill: TOpRec;
  Len: Integer;
  S: string;
begin
  with TPayDataSet(DataSource.DataSet) do
  begin
    Len := GetBtrRecord(@PayRec);
    if Len>0 then
    begin
      if PayRec.dbIdHere<>0 then
        if GetDocOp(Bill, PayRec.dbIdKorr)>0 then
        begin
          case Bill.brPrizn of
            brtReturn:
              begin
                DosToWin(Bill.brRet);
                S := StrPas(Bill.brRet);
                MessageBox(Handle, PChar('['+S+']'), MesTitle1, MB_OK or MB_ICONINFORMATION);
              end;
            brtKart:
              begin
                DosToWin(Bill.brKart);
                S := StrPas(Bill.brKart);
                MessageBox(Handle, PChar('['+S+']'), MesTitle2, MB_OK or MB_ICONINFORMATION);
              end;
          end;
        end;
    end
  end;
end;

procedure TPaydocsForm.ExchangeItemClick(Sender: TObject);
const
  MesTitle: PChar = 'Снятие пометки "выгружен"';
var
  PayRec: TPayRec;
  N, LI, I, Len: Integer;
begin
  DBGrid.SelectedRows.Refresh;
  N := DBGrid.SelectedRows.Count;
  with TPayDataSet(DataSource.DataSet) do
  begin
    if N=0 then
      LI := 0
    else
      LI := N-1;
    for I := 0 to LI do
    begin
      if N>0 then
        Bookmark := DBGrid.SelectedRows.Items[I];
      Len := GetBtrRecord(@PayRec);
      if Len>0 then
      begin
        PayRec.dbState := PayRec.dbState xor dsExport;
        if UpdateBtrRecord(@PayRec, Len) then
          Dec(N)
        else
          MessageBox(Handle, 'Не удалось обновить запись',
            MesTitle, MB_OK or MB_ICONERROR)
      end;
    end;
    Refresh;
    DBGrid.SelectedRows.Refresh;
  end;
  if N>0 then
    MessageBox(Handle, PChar('Не удалось обновить документов: '+IntToStr(N)),
      MesTitle, MB_OK or MB_ICONWARNING);
end;

procedure TPaydocsForm.DataSourceDataChange(Sender: TObject;
  Field: TField);
begin
  PayerMemo.Text := DataSource.DataSet.FieldByName('PName').AsString;
  BenefMemo.Text := DataSource.DataSet.FieldByName('RName').AsString;
end;

procedure TPaydocsForm.DBGridDrawColumnCell(Sender: TObject;
  const Rect: TRect; DataCol: Integer; Column: TColumn;
  State: TGridDrawState);
var
  S: string;
  C: TColor;
  F, M: Longint;
  R, G, B: Byte;
begin
  if Column.Field<>nil then
  begin
    if (Column.Field.FieldName='drType')
      and (Length(Column.Field.AsString)>0) then
    begin
      try
        F := Column.Field.AsInteger;
      except
        F := 0;
      end;
      if (F<>0) or (Length(Column.Field.AsString)>0) then
        with (Sender as TDBGrid).Canvas do
        begin
          if F in [101,102,106,116,191,192] then
          begin
            if Brush.Color<>clHighlight then
              Brush.Color := clYellow
            else
              Font.Color := clYellow;
          end;
          if F>100 then
            F := F-100;
          S := FillZeros(F, 2);
          TextRect(Rect, Rect.Left+2, Rect.Top+2, S);
        end;
    end
    else
    if (Column.Field.FieldName='State')
      and (Length(Column.Field.AsString)>0) then
    begin
      with (Sender as TDBGrid).Canvas do
      begin
        S := Column.Field.AsString;
        if Pos('пров', S)>0 then
          C := clGreen
        else
          if Pos('полу', S)>0 then
            C := clBlue
          else
            if Pos('подп', S)>0 then
            begin
              if Pos('подп', S)>0 then
              begin
                if (Abs(NumOfSign)=1) or (Length(S)<=8) then
                  C := clPurple
                else begin
                  try
                    M := StrToInt(Copy(S, 9, Length(S)-8));
                  except
                    M := 1;
                  end;
                  if M<Abs(NumOfSign) then
                    C := clTeal
                  else
                    C := clPurple;
                end;
              end
            end
            else
              if (Pos('отпр', S)>0) or (Pos('прин', S)>0) then
                C := {clPurple clYellow}$0088EE
              else
                if (Pos('возв', S)>0) or (Pos('ош', S)>0) then
                  C := clRed
                else
                  if Pos('карт', S)>0 then
                    C := clMaroon
                  else
                    C := clBlack;
        if Brush.Color=clHighlight then
        begin
          ExtractRGB(ColorToRGB(C), R, G, B);
          M := (R + G + B) div 3;
          F := ColorToRGB(Brush.Color);
          CorrectBg(R, F, M);
          CorrectBg(G, F, M);
          CorrectBg(B, F, M);
          ComposeRGB(R, G, B, F);
          C := F;
        end;
        if {(Brush.Color<>clHighlight)
          and} (ColorToRGB(C) <> ColorToRGB(Brush.Color))
        then
          Font.Color := C;
        TextRect(Rect, Rect.Left+2, Rect.Top+2, S);
      end;
    end;
  end;
end;

procedure TPaydocsForm.FormResize(Sender: TObject);
var
  I, W: Integer;
begin
  W := 11;
  with DBGrid.Columns do
    for I := 0 to Count-1 do
      if Items[I].Visible then
        W := W+Items[I].Width+1;
  I := DBGrid.ClientWidth;
  if (I=W) or (I+1=W) then
    Width := Width+W-I+1;
end;

procedure TPaydocsForm.CheckItemClick(Sender: TObject);
const
  MesTitle: PChar = 'Проверка подписи';
var
  Len, I: Integer;
  PayRec: TPayRec;
  Mode: Integer;
  SignDescr: TSignDescr;
begin
  Len := TPayDataSet(DataSource.DataSet).GetBtrRecord(@PayRec);
  if Len>0 then
  begin
    ControlData.cdCheckSelf := (PayRec.dbState and dsInputDoc)=0;
    Mode := smShowInfo or smCheckLogin or smThoroughly;
    if PayRec.dbState and dsExtended>0 then
    begin
      Mode := Mode or smExtFormat;
      if ((PayRec.dbState and dsSndType)=dsSndEmpty) and (PayRec.dbIdHere<>0) then
        Mode := Mode or smCanDelAnySign;
    end;
    SignDescr.siLoginNameProc := @ClientGetLoginNameProc;
    CheckSign(@PayRec.dbDoc, SizeOf(TDocRec)-drMaxVar+PayRec.dbDocVarLen,
      Len-(SizeOf(PayRec)-SizeOf(PayRec.dbDoc)), Mode, @ControlData,
      @SignDescr, AllowList);
    if ((Mode and smCanDelAnySign)<>0) and (SignDescr.siValid=svChanged) then
    begin
      I := PayRec.dbIdHere;
      with DocDataSet do
      begin
        if LocateBtrRecordByIndex(I, 0, bsEq) then
        begin
          I := SignDescr.siLen;
          if I>0 then
            Inc(I, 4);
          I := SizeOf(TPayRec)-drMaxVar+PayRec.dbDocVarLen+I;
          if UpdateBtrRecord(PChar(@PayRec), I) then
            UpdateCursorPos
          else
            MessageBox(Handle, PChar('Не удалось обновить запись Id='
              +IntToStr(PayRec.dbIdHere)), MesTitle, MB_OK or MB_ICONERROR)
        end
        else
          MessageBox(Handle, 'Не удалось установить курсор на запись',
            MesTitle, MB_OK or MB_ICONERROR);
      end;
    end;
  end;
end;

procedure TPaydocsForm.SignedItemClick(Sender: TObject);
begin
  if SignedDocsForm = nil then
    SignedDocsForm := TSignedDocsForm.Create(Self)
  else
    SignedDocsForm.Show;
  SignedDocsForm.MakeItemClick(nil);
end;

procedure TPaydocsForm.FormActivate(Sender: TObject);
begin
  SearchIndexComboBoxChange(nil);
end;

procedure TPaydocsForm.AbortBtnClick(Sender: TObject);
begin
  AbortBtn.Visible := False;
end;

procedure TPaydocsForm.SaveDocItemClick(Sender: TObject);
const
  MesTitle: PChar = 'Сохранение оригинала';
var
  PayRec: TPayRec;
  Len: Integer;
  FN: string;
  F: file of Byte;
begin
  with TPayDataSet(DataSource.DataSet) do
  begin
    Len := GetBtrRecord(@PayRec);
    if Len>0 then
    begin
      if SaveDocDialog.Execute then
      begin
        FN := SaveDocDialog.FileName;
        AssignFile(F, FN);
        {$I-} Rewrite(F); {$I+}
        if IOResult=0 then
        begin
          try
            BlockWrite(F, PayRec.dbDoc,
              Len-(SizeOf(PayRec)-SizeOf(PayRec.dbDoc)));
          finally
            CloseFile(F);
          end;
          MessageBox(Handle, PChar('Документ '+DocInfo(PayRec)
            +' сохранен в файл '+FN), MesTitle, MB_OK or MB_ICONINFORMATION)
        end
        else
          MessageBox(Handle, PChar('Не удалось создать файл '+FN),
            MesTitle, MB_OK or MB_ICONERROR)
      end;
    end;
  end;
end;

procedure TPaydocsForm.DelAllSignItemClick(Sender: TObject);
begin
  DelMode := 0;
  SignItemClick(nil);
end;

procedure TPaydocsForm.DelSignItemClick(Sender: TObject);
begin
  DelMode := 1;
  SignItemClick(nil);
end;

procedure TPaydocsForm.StatusItemClick(Sender: TObject);
var
  PayRec: TPayRec;
  Len, I: Integer;
  Bill: TOpRec;
  S: string;
begin
  Len := DocDataSet.GetBtrRecord(PChar(@PayRec));
  if Len>0 then
  begin
    StatusForm := TStatusForm.Create(Self);
    with StatusForm do
    begin
      SendDateEdit.Text := BtrDateToStr(PayRec.dbDateS)+'  '+BtrTimeToStr(PayRec.dbTimeS);
      RecvDateEdit.Text := BtrDateToStr(PayRec.dbDateR)+'  '+BtrTimeToStr(PayRec.dbTimeR);
      DocTypeEdit.Text := IntToStr(PayRec.dbDoc.drType);
      if PayRec.dbIdHere<>0 then
      begin
        Len := GetDocOp(Bill, PayRec.dbIdKorr);
        if Len>0 then
        begin
          BillDateEdit.Text := BtrDateToStr(Bill.brDate);
          OpTypeEdit.Text := IntToStr(Ord(Bill.brPrizn));
          OpNumberEdit.Text := IntToStr(Bill.brNumber);
          case Bill.brPrizn of
            brtBill:
              begin
                DosToWin(Bill.brText);
                S := StrPas(Bill.brText);
                PurposeMemo.Text := S;
                I := StrLen(Bill.brText)+1;
                Len := Len-70;
                if Len>I then
                begin
                  Len := Len - I - 1;
                  DosToWinL(@Bill.brText[I], Len);
                  S := Copy(StrPas(@Bill.brText[I]), 1, Len);
                  OperNameEdit.Text := S;
                end;
              end;
            brtReturn:
              begin
                DosToWin(Bill.brRet);
                S := StrPas(Bill.brRet);
                PurposeMemo.Text := S;
              end;
            brtKart:
              begin
                DosToWin(Bill.brKart);
                S := StrPas(Bill.brKart);
                PurposeMemo.Text := S;
              end;
          end;
        end
        else
          with OpGroupBox do
            for I := 0 to ControlCount-1 do
              Controls[I].Hide;
      end;
      ShowModal;
      Free;
    end;
  end;
end;

end.
