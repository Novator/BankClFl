unit PaydocsFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Grids, Db, DBTables, DBGrids, ExtCtrls, DBCtrls, BtrDS, Menus, StdCtrls,
  ToolEdit, Mask, ComCtrls, SearchFrm, {Sign, }DateFrm, BankCnBn,
  ImgList, Btrieve, Common, Basbn, Utilits, Registr, CommCons,
  BUtilits, DocFunc, ClntCons, CrySign,
  Orakle;                                       //Добавлено Меркуловым

type
  TPaydocsForm = class(TDataBaseForm)
    DataSource: TDataSource;
    PaydocDBGrid: TDBGrid;
    StatusBar: TStatusBar;
    BtnPanel: TPanel;
    SearchIndexComboBox: TComboBox;
    NameLabel: TLabel;
    EditPopupMenu: TPopupMenu;
    BenefMemo: TMemo;
    PayerMemo: TMemo;
    PayerLabel: TLabel;
    BenefLabel: TLabel;
    ChildMenu: TMainMenu;
    OperItem: TMenuItem;
    NewItem: TMenuItem;
    EditItem: TMenuItem;
    CopyItem: TMenuItem;
    DelItem: TMenuItem;
    SignItem: TMenuItem;
    ExchangeItem: TMenuItem;
    EditBreaker1: TMenuItem;
    ReturnItem: TMenuItem;
    EditBreaker2: TMenuItem;
    SearchItem: TMenuItem;
    EditBreaker3: TMenuItem;
    BillItem: TMenuItem;
    EditBreaker4: TMenuItem;
    CloseDaysItem: TMenuItem;
    OpenDaysItem: TMenuItem;
    StateItem: TMenuItem;
    SignStateItem: TMenuItem;
    NotSendedItem: TMenuItem;
    ReturnComboBox: TComboBox;
    TotalSumItem: TMenuItem;
    EditBreaker5: TMenuItem;
    SaveDocItem: TMenuItem;
    SaveDocDialog: TSaveDialog;
    Komiss: TMenuItem;
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
    procedure ExchangeItemClick(Sender: TObject);
    procedure DataSourceDataChange(Sender: TObject; Field: TField);
    procedure StateItemClick(Sender: TObject);
    procedure ReturnItemClick(Sender: TObject);
    {procedure ProccessItemClick(Sender: TObject);}
    procedure PaydocDBGridDrawColumnCell(Sender: TObject; const Rect: TRect;
      DataCol: Integer; Column: TColumn; State: TGridDrawState);
    procedure SignStateItemClick(Sender: TObject);
    procedure NotSendedItemClick(Sender: TObject);
    procedure TotalSumItemClick(Sender: TObject);
    procedure SaveDocItemClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure KomissItemClick(Sender: TObject);
  private
    SearchForm: TSearchForm;
    procedure MakeFormMenuItems;
    {function GetCurrentModule: HModule;}
    procedure InsertItemClick(Sender: TObject);
    procedure WMMakeStatement(var Message: TMessage); message WM_MAKESTATEMENT;
  protected
    function UserMayEditDoc(ADocCode: Byte): Boolean;
    function TestNonClosedDays: Boolean;
    procedure RefreshBases;
  public
    procedure UpdateDocumentByCode(CopyCurrent, New, ReadOnly: Boolean;
      ADocCode: Byte);
    function GetBank(Bik: string; var BankFullRec: TBankFullNewRec): Boolean;
    procedure TakeFormPrintData(var PrintDocRec: TPrintDocRec; var FormList: TList); override;
    function BillNeedSend(var BillRec: TOpRec; FillMes: Boolean;
      var Mes: string): Integer;
  end;

  EditRecord = function(Sender: TComponent; BankPayRecPtr: PBankPayRec;
    ReadOnly: Boolean): Boolean;
    
const
  DocTypeIndex = 19;

var
  PaydocsForm: TPaydocsForm;
  DLLList: TList;
  PayObjList: TList;

function GetModuleByCode(Code: Byte): HModule;

implementation

uses BillsFrm, ReturnFrm, BillFrm;

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
        J:=0;
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

{function TPaydocsForm.GetCurrentModule: HModule;
begin
  Result:=GetModuleByCode(PBankPayRec(DataSource.DataSet.ActiveBuffer)^.dbDoc.drType);
end;}

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
          for K:=0 to AList.Count-1 do
          begin
            J := StrToInt(AList.Names[K]);
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
                if Tag=1 then
                begin
                  ImageIndex := 2;
                  {ShortCut := TextToShortCut('Ins');}
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
  AccDataSet, AccArcDataSet, BillDataSet, ExportDataSet,
    AbonDataSet: TExtBtrDataSet;
  PayDataSet: TPayDataSet;
  BankFullRec: TBankFullNewRec;
  OurBik, OurKs: string;
var
  MailerNode: Integer = 0;
  NotSendTest: Integer = 0;
  UpdDate1: Word = 0;
  LowDate: Word = 0;
  SenderAcc: string;

procedure TPaydocsForm.FormCreate(Sender: TObject);
const
  MesTitle: PChar = 'Инициализация формы';
var
  Bik: Integer;
  Buf: array[0..SizeOf(TAccount)] of Char;
  T: array[0..511] of Char;
begin
  PayObjList.Add(Self);
  if not GetRegParamByName('MailerNode', GetUserNumber, MailerNode) then
    MailerNode := 0;
  if not GetRegParamByName('SenderAcc', GetUserNumber, T) then
    T := 'CBTCB';
  SenderAcc := T;
  if not GetRegParamByName('NotSendTest', GetUserNumber, NotSendTest) then
    NotSendTest := 0;
  if not GetRegParamByName('UpdDate1', GetUserNumber, UpdDate1) then
    UpdDate1 := 0;
  if not GetRegParamByName('OldDayLimit', GetUserNumber, LowDate) then
    LowDate := 0;
  if LowDate<>0 then
    LowDate := DateToBtrDate(Date-LowDate);
  try
    FillChar(BankFullRec, SizeOf(BankFullRec), #0);
    OurKs := '';
    OurBik := '';
    Bik := StrToInt(DecodeMask('$(BankBik)', 5, GetUserNumber));
    if Bik>0 then
    begin
      OurBik := IntToStr(Bik);
      if not GetBank(OurBik, BankFullRec) then
      begin
        MessageBox(Application.MainForm.Handle,
          PChar('БИК нашего банка не найден в справочнике '+OurBik),
          MesTitle, MB_ICONERROR + MB_OK);
        with BankFullRec do
        begin
          brCod := 45744803;
          brKs := '30101810700000000803';
          brName := 'ФАКБ "ТРАНСКАПИТАЛБАНК"'+#13#10+'Г. ПЕРМЬ';
        end;
        OurBik := '045744803';
      end;
    end
    else
      MessageBox(Application.MainForm.Handle,
        PChar('БИК в настройках не больше нуля '+IntToStr(Bik)),
        MesTitle, MB_ICONERROR + MB_OK);
    StrLCopy(Buf, BankFullRec.brKs, SizeOf(TAccount));
    OurKs := StrPas(Buf);
  except
    MessageBox(Application.MainForm.Handle, 'Некорректный БИК в настройках',
      MesTitle, MB_ICONERROR or MB_OK);
  end;
  try
    ReturnComboBox.Items.LoadFromFile(BaseDir+'Return.txt');
  except
  end;
  PayDataSet := GlobalBase(biPay) as TPayDataSet;
  AccDataSet := GlobalBase(biAcc);
  AccArcDataSet := GlobalBase(biAccArc);
  BillDataSet := GlobalBase(biBill);
  ExportDataSet := GlobalBase(biExport);
  AbonDataSet := GlobalBase(biAbon);
  {CorrDataSet := GlobalBase(biCorr);}

  DataSource.DataSet := PayDataSet;
  DefineGridCaptions(PaydocDBGrid, PatternDir+'Paydocs.tab');
  MakeFormMenuItems;
  SearchForm:=TSearchForm.Create(Self);
  SearchForm.SourceDBGrid := PaydocDBGrid;
  SearchIndexComboBox.ItemIndex := 0;
  SearchIndexComboBoxChange(nil);

  TakeMenuItems(OperItem, EditPopupMenu.Items);
  EditPopupMenu.Images := ChildMenu.Images;
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

procedure TPaydocsForm.TakeFormPrintData(var PrintDocRec: TPrintDocRec; var FormList: TList);
var
  I: Byte;
  //Добавлено Меркуловым
  RegistrBase: TBtrBase;
  ParamRec: TParamNewRec;
  ParamVec: TParamKey0;
  ControlData: TControlData;
  SignDescr: TSignDescr;
  PasSerial, PasNumber, PasPlace, NaznPlat, CType: string;
  SimSum, Simvol: array [0..5] of String;
  J, J1, L, NSim, CorrRes, Res, Mode: Integer;
  Number, PAcc, PKs, PCode, PInn, PClient, PBank,
  RAcc, RKs, RCode, RInn, RClient, RBank, Purpose, PKpp, RKpp,
  Status, Kbk, Okato, OsnPl, Period, NDoc, DocDate, TipPl,
  Nchpl, Shifr, Nplat, OstSum: string;
  BillRec: TOpRec;
begin
  Mode := 0;
  Nsim := 0;                                            //Добавлено
  J := 0;                                               //Добавлено
  inherited;
  PrintDocRec.DBGrid := Self.PaydocDBGrid;
  I := PBankPayRec(DataSource.DataSet.ActiveBuffer)^.dbDoc.drType;
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
// Изменено и добавлено Меркуловым
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
 //       MessageBox(ParentWnd,PChar(Purpose),'Проверка',MB_OK);             //Отладка
        while (J<L) and (Purpose[J+1] <> #10) do
          Inc(J);
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
        //Если нет тильды, печатаем как приходный
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
          while (J<L) do
            Inc(J);
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
        while (NSim>=0) do
          begin
          //Объявляем глоб.переменные для печати
          SetVarior('Simvol'+IntToStr(NSim),Simvol[NSim]);
          SetVarior('SimSum'+IntToStr(NSim),SimSum[NSim]);
          Dec(NSim);
          end;
//Определим тип кассового ордера
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
      //Добавлено Меркуловым
      SetVarior('DSign', ' ');
      SetVarior('BSign', ' ');
      (*
      if (PBankPayRec(DataSource.DataSet.ActiveBuffer)^.dbState and dsExtended>0)
        { !!!!  добавленно временно для ИП Итунина  !!!!  }
        and (PBankPayRec(DataSource.DataSet.ActiveBuffer)^.dbIdSender<>4583215) then
      begin
        J1 := TPayDataSet(DataSource.DataSet).GetBtrRecord(@PBankPayRec(DataSource.DataSet.ActiveBuffer)^);
        if J1>0 then
        begin
          Mode := Mode or smExtFormat or smGetLoginInfo or smCheckLogin or smThoroughly;
          SignDescr.siLoginNameProc := @ClientGetLoginNameProc;
          CheckSign(@PBankPayRec(DataSource.DataSet.ActiveBuffer)^.dbDoc,
            SizeOf(TDocRec)-drMaxVar+PBankPayRec(DataSource.DataSet.ActiveBuffer)^.dbDocVarLen,
            J1-(SizeOf(PBankPayRec(DataSource.DataSet.ActiveBuffer)^)-SizeOf(PBankPayRec(DataSource.DataSet.ActiveBuffer)^.dbDoc)),
            Mode, @ControlData, @SignDescr, '');
        end;
      end; *)
      if GetDocOp(BillRec, PBankPayRec(DataSource.DataSet.ActiveBuffer)^.dbIdHere, J)
        and (BillRec.brPrizn=brtBill) then
      begin
        PrintDocRec.GraphForm := 'payo0003.gfm';
        PrintDocRec.TextForm := 'payo0003.tfm';
      end
      else begin
        PrintDocRec.GraphForm := DecodeMask('$(GrForm'+IntToStr(I)+')', 5, GetUserNumber);
        PrintDocRec.TextForm := DecodeMask('$(TxForm'+IntToStr(I)+')', 5, GetUserNumber);
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
  StrPLCopy(ModuleName, DecodeMask('$(Banks)', 5, GetUserNumber), SizeOf(ModuleName));
  Module := GetModuleHandle(ModuleName);
  if Module=0 then
    MessageDlg('=х эрщфхэ ьюфєы№ фшрыюур тvсюЁр срэър'+#13+'['+ModuleName+']',
      mtError,[mbOk],0)
  else begin
    P:=GetProcAddress(Module, EditRecordDLLProcName);
    if P=nil then
      MessageDlg('=х эрщфхэр ЇєэъЎш  ьюфєы  '+EditRecordDLLProcName+'()',
        mtError,[mbOk],0)
    else begin
      with BankFullRec do
        Val(Bik, brCod, Err);
      if Err=0 then
        Result := EditBankRecord(P)(Self, @BankFullRec, 0, False);
    end;
  end;
end;

function SignPaydoc(var PayRec: TBankPayRec): Integer;
const
  MesTitle: PChar = 'Создание подписи';
var
  ControlData: TControlData;
begin
  ControlData.cdCheckSelf := True;
  ControlData.cdTagNode := MailerNode;
  Result :=
    AddSign(0, @PayRec.dbDoc, SizeOf(TDocRec)-drMaxVar+PayRec.dbDocVarLen,
      SizeOf(TDocRec), smOverwrite or smShowInfo, @ControlData, '');
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

type
  TProKeyNum3 = packed record
    pkOperation: Word;
    pkOperNum:   Longint;
  end;


function NoActiveDocInQrm(IdHere: Integer; CanArch: Boolean): Boolean;
const
  MesTitle: PChar = 'Проверка наличия в Кворум';
var
  Res, Len: Integer;
  KeyL: Longint;
  ExportRec: TExportRec;
  Status: Word;
  //ProKeyNum3: TProKeyNum3;
begin
  Result := False;
  KeyL := IdHere;
  Len := SizeOf(ExportRec);
  Res := ExportDataSet.BtrBase.GetEqual(ExportRec, Len, KeyL, 0);
  if Res=0 then
  begin
    //Добавлено/изменено Меркуловым
    if OraBase.OrBaseConn then
      Res := OrDocumentIsExistInQuorum(ExportRec.erOperation,
        ExportRec.erOperNum, Status){
    else
      Res := DocumentIsExistInQuorum(ExportRec.erOperation,
        ExportRec.erOperNum, Status)};
    //Конец
    if (Res=0) or (Abs(Res)=4) then
    begin
      if (Res=0) and CanArch and (Status=KvitStatus)
        and (ExportRec.erOperation=coPayOrderOperation) then
      begin
      //Добавлено/изменено Меркуловым
        if OraBase.OrBaseConn then
          with OraBase, OrQuery do
            begin
            SQL.Clear;
            SQL.Add('Select count(*) from '+OrScheme+'.Pro where ');
            SQL.Add('Operation='+IntToStr(ExportRec.erOperNum)+' ');
            SQL.Add('and OperNum='+IntToStr(ExportRec.erOperNum));
            Open;
            if Fields[0].AsInteger=0 then
              Res := 4
            else
              Res := 0;
            end
        {else
          with QrmBases[qbPro] do
          begin
            with ProKeyNum3 do
            begin
              pkOperation := ExportRec.erOperNum;
              pkOperNum := ExportRec.erOperNum;
            end;
            Len := FileRec.frRecordFixed;
            Res := BtrBase.GetEqual(Buffer^, Len, ProKeyNum3, 3);
          end};
        if (Res=4) and (MessageBox(Application.Handle,
          'Документ существует в архиве Кворума, но не имеет проводки.'#13#10
          +'Проигнорировать его наличие в Кворуме?',
          MesTitle, MB_YESNOCANCEL or MB_ICONWARNING or MB_DEFBUTTON2)<>ID_YES)
        then
          Res := 0;
      //Конец
      end;
      if Abs(Res)=4 then
      begin
        Res := ExportDataSet.BtrBase.Delete(0);
        if Res=0 then
          Result := True
        else
          MessageBox(Application.Handle, PChar(
            'Не удалось удалить пометку о документе в базе "экспорт" BtrErr='
            +IntToStr(Res)), MesTitle, MB_OK or MB_ICONWARNING);
      end;
    end
    else
      MessageBox(Application.Handle, PChar(
        'Ошибка проверки наличия документа в Кворуме Res='+IntToStr(Res)),
        MesTitle, MB_OK or MB_ICONWARNING);
  end
  else
    if Res=4 then
      Result := True
    else
      MessageBox(Application.Handle, PChar(
        'Ошибка поиска пометки о выгрузке в базе "экспорт" BtrErr='
        +IntToStr(Res)), MesTitle, MB_OK or MB_ICONWARNING);
end;

function PaydocSignMayChangeByOper(var PayRec: TBankPayRec;
  var S: string): Boolean;
(*var
  //Len, Res: Integer;
  AUserRec: TUserRec;*)
begin
  Result := True;
  (*
  Result := not IsSigned(PayRec);
  if not Result then
  begin
    NT := 0;
    NF := 0;
    NO := 0;
    Len := (SizeOf(PayRec.dbDoc)-drMaxVar+SignSize)+PayRec.dbDocVarLen;
    Res := TestSign(@PayRec.dbDoc, Len, NF, NO, NT);
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
  end;
  *)
end;

procedure TPaydocsForm.UpdateDocumentByCode(CopyCurrent, New, ReadOnly: Boolean;
  ADocCode: Byte);
const
  MesTitle: PChar = 'Редактирование записи';
var
  DLLModule: HModule;
  P: Pointer;
  BankPayRec: TBankPayRec;
  LastIdHere, Offset, I, Num, SignLen: Integer;
  Year, Month, Day: Word;
  T: array[0..1023] of Char;
  Bill: TOpRec;
  SignNew: Boolean;
  S: string;
begin
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
        with PayDataSet do
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
            GetBtrRecord(PChar(@BankPayRec))
          else
            FillChar(BankPayRec, SizeOf(BankPayRec), #0);
          if New then
          begin
            DecodeDate(Date, Year, Month, Day);
            with BankPayRec do
            begin
              dbDoc.drDate := CodeBtrDate(Year, Month, Day);
              dbDoc.drIsp := 2;
              if GetRegParamByName('PaySeq', GetUserNumber, I) then
                dbDoc.drOcher := I
              else
                dbDoc.drOcher := 6;
              if not GetRegParamByName('PayNum'+IntToStr(ADocCode), GetUserNumber, Num) then
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
                Offset := 0;
                if ADocCode<>3 then
                begin
                  for I := 21 to 34 do
                  begin
                    case I of
                      21: StrPCopy(T, IntToStr(Num+1));
                      22: {StrPCopy(T, FirmAccRec.faAcc);}T := '';
                      23: StrPCopy(T, OurKs);
                      24: StrPCopy(T, OurBik);
                      25: {StrPCopy(T, FirmRec.frInn);}T := '';
                      26: begin
                            {if StrLen(FirmRec.frKpp)>0 then
                              StrPCopy(T, 'КПП '+FirmRec.frKpp+#13#10+FirmRec.frName)
                            else
                              StrPCopy(T, FirmRec.frName);}T := '';
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
                        if not GetRegParamByName('CashAcc', GetUserNumber, T) then
                          StrPCopy(T, '');
                      23: StrPCopy(T, OurKs);
                      24: StrPCopy(T, OurBik);
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
              dbIdKorr := 0;
              dbIdSender := 0;
              dbIdDoc := dbIdHere;
              dbIdArc := 0;
              dbIdDel := 0;
              dbState := 0;
              dbDoc.drType := ADocCode;
            end;
          end;
          ReadOnly := ReadOnly or (BankPayRec.dbIdDoc=0) or (BankPayRec.dbIdSender<>0);
          if not ReadOnly then
            ReadOnly := GetDocOp(Bill, BankPayRec.dbIdHere, I);
          if not ReadOnly then
            ReadOnly := not NoActiveDocInQrm(BankPayRec.dbIdHere, False);
          if not ReadOnly then
          begin
            ReadOnly := not (New or
              ({(GetNode>0) and} PaydocSignMayChangeByOper(BankPayRec, S)));
          end;
          if EditRecord(P)(Self, @BankPayRec, ReadOnly) then
          begin
            if not GetRegParamByName('SignPaydoc', GetUserNumber, SignNew) then
              SignNew := False;
            FillChar(PChar(@BankPayRec.dbDoc.drVar)[BankPayRec.dbDocVarLen], SignSize, #0);
            SignLen := 0;
            if SignNew {and (GetNode>0)} then
            begin
              SignLen := SignPaydoc(BankPayRec);
              if SignLen<=0 then
                MessageBox(Handle, 'Не удалось подписать документ',
                  MesTitle, MB_OK or MB_ICONERROR)
            end;
            I := SizeOf(TBankPayRec)-drMaxVar+BankPayRec.dbDocVarLen+SignLen;
            if SearchIndexComboBox.ItemIndex<>0 then
            begin
              SearchIndexComboBox.ItemIndex := 0;
              SearchIndexComboBoxChange(Self);
            end;
            if New then
            begin
              if AddBtrRecord(PChar(@BankPayRec), I) then
              begin
                ProtoMes(plWarning, MesTitle, 'Добавлен документ '
                  +DocInfo(BankPayRec)+' Id='+IntToStr(BankPayRec.dbIdHere));
                Refresh
              end
              else
                MessageBox(Handle, PChar('Не удалось добавить запись Id='
                  +IntToStr(BankPayRec.dbIdHere)), MesTitle, MB_OK or MB_ICONERROR)
            end
            else begin
              Num := BankPayRec.dbIdHere;
              if LocateBtrRecordByIndex(Num, 0, bsEq) then
              begin
                if UpdateBtrRecord(PChar(@BankPayRec), I) then
                begin
                  ProtoMes(plWarning, MesTitle, 'Изменен документ '
                    +DocInfo(BankPayRec)+' Id='+IntToStr(BankPayRec.dbIdHere));
                  UpdateCursorPos;
                end
                else
                  MessageBox(Handle, PChar('Не удалось обновить запись Id='
                    +IntToStr(BankPayRec.dbIdHere)), MesTitle, MB_OK or MB_ICONERROR)
              end
              else
                MessageBox(Handle, 'Не удалось установить курсор на запись',
                  MesTitle, MB_OK or MB_ICONERROR);
            end;
            S := StrPas(@BankPayRec.dbDoc.drVar[0]);
            Val(S, Num, Offset);
            if Offset=0 then
              SetRegParamByName('PayNum'+IntToStr(BankPayRec.dbDoc.drType),
                CommonUserNumber, False, IntToStr(Num));
            DataSourceDataChange(nil, nil);
          end;
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

procedure TPaydocsForm.SignItemClick(Sender: TObject);
const
  MesTitle: PChar = 'Изменение подписи';
var
  PayRec: TBankPayRec;
  I,R,N,Num,SignLen: Integer;
  U: Boolean;
  Len: Word;
  S: string;
begin
  if IsCryptoEngineInited then
  begin
    with PayDataSet do
    begin
      N := PaydocDBGrid.SelectedRows.Count;
      if N>0 then
        Dec(N);
      for R := 0 to N do
      begin
        if R<PaydocDBGrid.SelectedRows.Count then
          Bookmark := PaydocDBGrid.SelectedRows.Items[R];
        Len := GetBtrRecord(@PayRec);
        if Len>0 then
        begin
          Num := PayRec.dbIdHere;
          if PayRec.dbIdDoc<>0 then
          begin
            if PayRec.dbIdSender=0 then
            begin
              if UserMayEditDoc(PayRec.dbDoc.drType) then
              begin
                if PaydocSignMayChangeByOper(PayRec, S) then
                begin
                  SignLen := 0;
                  U := IsSigned(PayRec, Len);
                  if not U then
                  begin
                    //AnalyzePayDoc(PayRec.dbDoc, PayRec.dbDocVarLen, 0, '', S);
                    U := TestPaydoc(PayRec.dbDoc, PayRec.dbDocVarLen, True);
                    if U then
                    begin
                      SignLen := SignPaydoc(PayRec);
                      U := SignLen>0;
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
                end
                else
                  MessageBox(Handle,
                    PChar(S+'. Нельзя изменить подпись'#13#10
                    +DocInfo(PayRec)), MesTitle, MB_OK or MB_ICONINFORMATION)
              end
              else
                MessageBox(Handle, PChar('Вы не можете изменить подпись документа типа '
                  +IntToStr(PayRec.dbDoc.drType)+#13#10+DocInfo(PayRec)),
                  MesTitle, MB_OK or MB_ICONINFORMATION)
            end
            else
              MessageBox(Handle,
                PChar('Нельзя изменить клиентский документ'#13#10+DocInfo(PayRec)),
                MesTitle, MB_OK or MB_ICONINFORMATION)
          end
          else
            MessageBox(Handle,
              PChar('Изменить состояние подписи можно только у текущих документов'#13#10
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
begin
  with DataSource.DataSet do
  begin
    Val(Fields.Fields[DocTypeIndex].AsString, Code, Err);
    if Err=0 then
      UpdateDocumentByCode(True, (Sender as TComponent).Tag=1, False, Code)
  end;
end;

function DocInfo(var PayRec: TBankPayRec): string;
begin
  Result := '[N'+PayRec.dbDoc.drVar+'  '
    +BtrDateToStr(PayRec.dbDoc.drDate)+'  '
    +SumToStr(PayRec.dbDoc.drSum)+' руб.]';
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
  PayRec: TBankPayRec;
  DS: TPayDataSet;

  function PaydocCanDel(var PayRec: TBankPayRec): Boolean;
  var
    L: Integer;
    BillRec: TOpRec;
    S: string;
  begin
    S := '';
    Result := PayRec.dbIdArc=0;
    if Result then
    begin
      Result := PayRec.dbIdSender=0;
      if Result then
      begin
        Result := not GetDocOp(BillRec, PayRec.dbIdHere, L);
        if Result then
        begin
          Result := IsSanctAccess('DelPaydocSanc');
          if Result then
          begin
            Result := PaydocSignMayChangeByOper(PayRec, S);
            if Result then
            begin
              Result := NoActiveDocInQrm(PayRec.dbIdHere, False);
              if not Result then
                S := 'Сначала удалите документ в Кворуме';
            end;
          end
          else
            S := 'Вы не можете удалять документы';
        end
        else
          S := 'Нельзя удалить документ с операцией. Отмените операцию';
      end
      else
        S := 'Нельзя удалить клиентский документ. Его следует возвратить';
    end
    else
      S := 'Нельзя удалить архивный документ. Раскройте операционный день';
    if not Result and (Length(S)>0) then
      MessageBox(Handle, PChar(S+#13#10+DocInfo(PayRec)), MesTitle,
        MB_OK or MB_ICONINFORMATION);
  end;

begin
  //PaydocDBGrid.SelectedRows.Refresh;
  N := PaydocDBGrid.SelectedRows.Count;
  DS := TPayDataSet(DataSource.DataSet);
  with DS do
  begin
    LI := N;
    if N=0 then
      Inc(LI)
    else
      if (N>1) and (MessageBox(Handle, PChar('Будет удалено документов: '
        +IntToStr(N)+#13#10'Вы уверены?'), MesTitle,
        MB_YESNOCANCEL + MB_ICONQUESTION) <> IDYES)
      then
        LI := 0;
    C := LI;
    I := 0;
    while I<LI do
    begin
      if N>0 then
        Bookmark := PaydocDBGrid.SelectedRows.Items[I];
      Len := GetBtrRecord(@PayRec);
      if (Len>0) and ((Sender=nil) or PaydocCanDel(PayRec))
        and ((N>1) or (MessageBox(Handle,
          PChar('Документ будет удален. Вы уверены?'#13#10+DocInfo(PayRec)),
          MesTitle, MB_YESNOCANCEL or MB_ICONQUESTION) = IDYES)) then
      begin
        ProtoMes(plWarning, MesTitle, 'Удаляется документ '
          +DocInfo(PayRec)+' Id='+IntToStr(PayRec.dbIdHere));
        Delete;
        Dec(C);
      end;
      Inc(I);
    end;
    PaydocDBGrid.SelectedRows.Refresh;
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
  with PayDataSet do
  begin
    case SearchIndexComboBox.ItemIndex of
      0: I := 2; {текущие}
      1: I := 3; {архив}
      2: I := 0; {все}
      3: I := 1; {корреспондент}
      4: I := 4; {удаленные}
      else
        I := 2;
    end;
    if (I<>IndexNum) or (Sender=nil) then
    begin
      IndexNum := I;
      Last;
      PaydocDBGrid.SelectedRows.Clear;
    end;
  end;
  if Visible then
    PaydocDBGrid.SetFocus;
end;

procedure TPaydocsForm.RefreshBases;
begin
  BillDataSet.Refresh;
  AccArcDataSet.UpdateKeys;
  AccArcDataSet.Refresh;
  AccDataSet.UpdateKeys;
  AccDataSet.Refresh;
  PayDataSet.UpdateKeys;
  PayDataSet.Refresh;
  PayDataSet.Last;
end;

function TPaydocsForm.BillNeedSend(var BillRec: TOpRec; FillMes: Boolean;
  var Mes: string): Integer;
var
  KeyA: TAccount;
  Len, Res, KeyL: Integer;
  AccRec: TAccRec;
  d: TBankPayRec;
begin
  Result := 0;
  if BillRec.brPrizn=brtBill then
  begin
    if (BillRec.brState and dsAnsType)=dsAnsEmpty then
    begin
      KeyA := BillRec.brAccD;
      Len := SizeOf(AccRec);
      Res := AccDataSet.BtrBase.GetEqual(AccRec, Len, KeyA, 1);
      if (Res=0) and (AccRec.arCorr<>0) then
      begin
        Result := 1;
        if FillMes then
          Mes := KeyA;
      end;
    end;
    if (Result=0) and ((BillRec.brState and dsReSndType) = dsReSndEmpty) then
    begin
      KeyA := BillRec.brAccC;
      Len := SizeOf(AccRec);
      Res := AccDataSet.BtrBase.GetEqual(AccRec, Len, KeyA, 1);
      if (Res=0) and (AccRec.arCorr<>0) then
      begin
        Result := 2;
        if FillMes then
          Mes := KeyA;
      end;
    end;
    if (Result=0)
      and ((BillRec.brState and dsSndType) = dsSndEmpty)
      and (BillRec.brDate>UpdDate1) then
    begin
      KeyL := BillRec.brDocId;
      Len := SizeOf(d);
      Res := PayDataSet.BtrBase.GetEqual(d, Len, KeyL, 0);
      if (Res=0) and (d.dbIdSender<>0) then
      begin
        Result := 3;
        if FillMes then
          Mes := BillRec.brAccD + '/' + BillRec.brAccC;
      end;
    end;
  end
  else
    if (BillRec.brPrizn=brtReturn) or ((BillRec.brPrizn=brtKart)) then
    begin
      if (BillRec.brState and dsAnsType)=dsAnsEmpty then
      begin
        KeyL := BillRec.brDocId;
        Len := SizeOf(d);
        Res := PayDataSet.BtrBase.GetEqual(d, Len, KeyL, 0);
        if (Res=0) and (d.dbIdSender<>0) then
        begin
          Result := 4;
          if FillMes then
            Mes := DocInfo(d);
        end
      end;
    end;
end;

procedure ShowMes(S: string);
begin
  PaydocsForm.StatusBar.SimpleText := S;
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
  S: string;
  AccRec: TAccRec;
  AccArcRec: TAccArcRec;
  BillRec: TOpRec;
  BankPayRec: TBankPayRec;
  AccList: TAccList;
  PAccCol: PAccColRec;
  Date1, Date2: TDateTime;
  CloseDayLim: Integer;
  Errors: boolean;
begin
  if IsSanctAccess('ArchDaysSanc') then
  try
    {PaydocDBGrid.{Enabled := False; Hide;}
    DataSource.Enabled := False;
    LastDate := GetLastClosedDay;
    KeyO := LastDate;
    { Найдем проводки по незакрытым дням }
    ShowMes('Поиск проводок по незакрытым дням...');
    Len := SizeOf(BillRec);
    Res := BillDataSet.BtrBase.GetGT(BillRec, Len, KeyO, 2);
    while (Res=0) and (BillRec.brDel<>0) do
    begin
      Len := SizeOf(BillRec);
      Res := BillDataSet.BtrBase.GetNext(BillRec, Len, KeyO, 2);
    end;
    ShowMes('');
    if Res=0 then
    begin
      MaxDate := BillRec.brDate;
      if GetBtrDate(MaxDate, MesTitle, '&Закрыть по',
        'При этой операции документы указанной даты и более ранние перейдут из списка "Текущие" в список "Архив". После закрытия дней выписки за эти дни больше не будут отправляться.') then
        {if GetBtrDate(MaxDate) then}
      begin
        if MaxDate>LastDate then
        begin
          if not GetRegParamByName('CloseDayLim', GetUserNumber, CloseDayLim) then
            CloseDayLim := 0;
          try
            Date1 := StrToDate(BtrDateToStr(MaxDate));
          except
            CloseDayLim := 0;
          end;
          Date2 := Date;
          if (CloseDayLim = 0)
            or (Trunc(Date2)-Trunc(Date1)>=CloseDayLim)
            or (MessageBox(Application.Handle,
              'Возможно, еще не все документы проведены за указанный период. Вы хотите закрыть дни?',
              MesTitle, MB_YESNOCANCEL + MB_ICONWARNING)=ID_YES) then
          begin
            ProtoMes(plWarning, MesTitle, 'Закрытие опердней по '+BtrDateToStr(MaxDate));
            { Инициализация списка счетов }
            ShowMes('Инициализация списка счетов...');
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
                  if acFDate<LastDate then
                  begin
                    MessageBox(Application.Handle, PChar('По счету '
                      +PAccCol^.acNumber+' необходимо раскрыть дни по '
                      +BtrDateToStr(PAccCol^.acFDate)), MesTitle, MB_OK
                      +MB_ICONWARNING);
                    ProtoMes(plError, MesTitle, 'Надо раскрыть по '
                      +BtrDateToStr(PAccCol^.acFDate));
                  end;
                end;
                AccList.Add(PAccCol);
              end;
              Len := SizeOf(AccRec);
              Res := AccDataSet.BtrBase.GetNext(AccRec, Len, Key0, 0);
            end;
            if FirstDate>=LastDate then
            begin
              AccList.Sort(AccColRecCompare);
              { Просчет состояний счетов по выпискам }
              ShowMes('Просчет состояний счетов по выпискам...');
              KeyO := LastDate;
              Len := SizeOf(BillRec);
              Res := BillDataSet.BtrBase.GetGT(BillRec, Len, KeyO, 2);
              Errors := False;
              while (Res=0) and not Errors do
              begin
                if (NotSendTest>0) and (BillRec.brDate<=MaxDate)
                  and (BillNeedSend(BillRec, True, S)>0) then
                begin
                  K := MB_ICONWARNING;
                  S := 'Найдена неотправленная выписка от '
                    +BtrDateToStr(BillRec.brDate)+' - '+S+#13#10;
                  if NotSendTest=1 then
                  begin
                    K := K or MB_YESNOCANCEL or MB_DEFBUTTON2;
                    S := S+'Вы хотите продолжить закрытие дней?';
                  end
                  else begin
                    K := K or MB_OK;
                    S := S+'Необходимо провести сеанс связи';
                  end;
                  Errors := MessageBox(Handle, PChar(S), MesTitle, K)<>ID_YES;
                end;
                if not Errors then
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
              end;
              if not Errors then
              begin
                Errors := False;
                { Проверка соответствия состояний счетов просчитанным по выпискам }
                ShowMes('Проверка состояний счетов на соответствие выпискам...');
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
                      Str((AccRec.arSumA-PAccCol^.acSumma)/100:0:2, S);
                      S := 'Ошибка остатка по счету '+PAccCol^.acNumber+' на сумму '+S;
                      ProtoMes(plWarning, MesTitle, S);
                      MessageBox(Application.Handle, PChar(S), MesTitle, MB_OK or MB_ICONWARNING);
                      Errors := True
                    end;
                  end;
                  Inc(I);
                end;
                ShowMes('');
                if not Errors then
                begin
                  Screen.Cursor := crHourGlass;
                  KeyO := LastDate;
                  Len := SizeOf(BillRec);
                  Res := BillDataSet.BtrBase.GetGT(BillRec, Len, KeyO, 2);
                  while (Res=0) and (BillRec.brDate<=MaxDate) do
                  begin
                    FirstDate := BillRec.brDate;
                    ShowMes('Закрытие дня '+BtrDateToStr(FirstDate)+'...');
                    { Перепись док-тов из текущих в архив }
                    while (Res=0) and (BillRec.brDate=FirstDate) do
                    begin
                      if Billrec.brDel=0 then
                      begin
                        Key0 := BillRec.brDocId;
                        Len := SizeOf(BankPayRec);
                        Res := PayDataSet.BtrBase.GetEqual(BankPayRec, Len, Key0, 0);
                        if Res=0 then
                          with BankPayRec do
                          begin
                            dbIdDoc := 0;
                            dbIdArc := dbIdHere;
                            Res := PayDataSet.BtrBase.Update(BankPayRec, Len, Key0, 0);
                            if Res<>0 then
                            begin
                              S := 'Не удается перенести документ '#13#10
                                +DocInfo(BankPayRec)+#13#10'в архив BtrErr='
                                +IntToStr(Res);
                              ProtoMes(plError, MesTitle, S);
                              MessageBox(Application.Handle, PChar(S), MesTitle,
                                MB_OK or MB_ICONERROR);
                            end;
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
                        if Res1<>0 then
                        begin
                          S := 'Не удается добавить остаток за закрытый день по счету ['
                            +PAccCol^.acNumber+'] BtrErr='+IntToStr(Res1);
                          ProtoMes(plError, MesTitle, S);
                          MessageBox(Application.Handle, PChar(S),
                            MesTitle, MB_OK or MB_ICONERROR);
                        end;
                      end;
                      Inc(I);
                    end;
                  end;
                  ProtoMes(plInfo, MesTitle, 'Операционные дни закрыты с '
                    +BtrDateToStr(FirstDate)+' по '+BtrDateToStr(MaxDate));
                  ShowMes('Операционные дни закрыты');
                  Screen.Cursor := crDefault;
                  MessageBox(Application.Handle, 'Операционные дни закрыты',
                    MesTitle, MB_OK or MB_ICONINFORMATION);
                end;
              end;
            end
            else begin
              ShowMes('');
              S := 'По счету '
                +PAccCol^.acNumber+' необходимо раскрыть дни по '
                +BtrDateToStr(PAccCol^.acFDate);
              ProtoMes(plWarning, MesTitle, S);
              MessageBox(Application.Handle, PChar(S), MesTitle, MB_OK
                +MB_ICONWARNING);
            end;
            AccList.Free;
          end;
        end
        else begin
          MessageBox(Application.Handle, PChar('Уже закрыты дни по '
            +BtrDateToStr(LastDate)), MesTitle, MB_OK or MB_ICONINFORMATION);
        end;
      end
    end
    else begin
      MessageBox(Application.Handle, 'Нет операций - нечего закрывать', MesTitle,
        MB_OK or MB_ICONINFORMATION);
    end;
  finally
    Screen.Cursor := crDefault;
    RefreshBases;
    DataSource.Enabled := True;
    ShowMes('');
    {PaydocDBGrid.{Enabled := True Show;}
    {PaydocDBGrid.SelectedRows.Clear;
    PaydocDBGrid.SelectedRows.Items}
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
  BankPayRec: TBankPayRec;
  LastDate, PrevDate, MaxDate: word;
  UpdateErr: Boolean;
  S: string;
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
      if GetBtrDate(MaxDate, 'Раскрытие дней', '&Раскрыть с', 'При этой операции документы указанной даты и более поздние перейдут из списка "Архив" обратно в список "Текущие".') then
      {if GetBtrDate(MaxDate) then}
      begin
        if MaxDate<=LastDate then
        begin
          Screen.Cursor := crHourGlass;
          ProtoMes(plWarning, MesTitle, 'Раскрытие дней с '+BtrDateToStr(MaxDate)
            +' по '+BtrDateToStr(LastDate));
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
                Len := SizeOf(BankPayRec);
                Res := PayDataSet.BtrBase.GetEqual(BankPayRec, Len, Key0, 0);
                if Res=0 then
                begin
                  BankPayRec.dbIdArc := 0;
                  BankPayRec.dbIdDoc := BankPayRec.dbIdHere;
                  Res := PayDataSet.BtrBase.Update(BankPayRec, Len, Key0, 0);
                  if Res<>0 then
                    UpdateErr := True;
                end;
              end;
              Len := SizeOf(BillRec);
              Res := BillDataSet.BtrBase.GetPrev(BillRec, Len, KeyO, 2);
            end;
            if UpdateErr then
            begin
              S := 'Не удалось переписать некоторые документы';
              ProtoMes(plWarning, MesTitle, S);
              MessageBox(Handle, PChar(S), MesTitle, MB_OK or MB_ICONWARNING);
            end;
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
          S := 'Дни закрыты только по '+BtrDateToStr(LastDate);
          ProtoMes(plWarning, MesTitle, S);
          MessageBox(Handle, PChar(S),
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
    RefreshBases;
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
var
  AutoCloseDay: Integer;
  Date1, Date2: TDateTime;
begin
  Result := False;
  if GetRegParamByName('AutoCloseDay', GetUserNumber, AutoCloseDay) and (AutoCloseDay>0) then
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
      end;
      Date2 := Date;
      Len := Trunc(Date2)-Trunc(Date1);
      Result := (AutoCloseDay > 0) and (Len>=AutoCloseDay)
        and (MessageBox(Handle, PChar('Вы не закрывали операционные дни '
          +IntToStr(Len)+' дней.'+#13#10'Хотите закрыть дни?'),
          MesTitle, MB_YESNOCANCEL + MB_ICONQUESTION) = IDYES);
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

procedure TPaydocsForm.ExchangeItemClick(Sender: TObject);
const
  MesTitle: PChar = 'Изменение пометки "выгрузить"';
var
  BankPayRec: TBankPayRec;
  N, LI, I, Len, C: Integer;
  po: TopRec;                          //Добавлено Меркуловым
  Len1: Integer;                       //Добавлено Меркуловым
begin
  PaydocDBGrid.SelectedRows.Refresh;
  N := PaydocDBGrid.SelectedRows.Count;
  with TPayDataSet(DataSource.DataSet) do
  begin
    if N=0 then
      LI := 1
    else
      LI := N;
    C := LI;
    for I := 0 to LI-1 do
    begin
      if N>0 then
        Bookmark := PaydocDBGrid.SelectedRows.Items[I];
      Len := GetBtrRecord(@BankPayRec);
      if Len>0 then
      begin
        if (BankPayRec.dbState and dsInputDoc>0)
          and (BankPayRec.dbState and dsExport>0)
        then
          MessageBox(Handle, PChar('Внешний документ нельзя выгрузить'#13#10
            +DocInfo(BankPayRec)), MesTitle, MB_OK or MB_ICONINFORMATION)
        else begin
          //Добавлено/изменено Меркуловым
          if (GetDocOp(po, BankPayRec.dbIdHere, Len1)) and (po.brPrizn = brtReturn) then
            MessageBox(Handle, PChar('Документ имеет пометку возврат. Выгрузить в Кворум невозможно'#13#10
              +DocInfo(BankPayRec)), MesTitle, MB_OK or MB_ICONINFORMATION)
          else
            begin
            BankPayRec.dbState := BankPayRec.dbState xor dsExport;
            if UpdateBtrRecord(@BankPayRec, Len) then
              Dec(C)
            else
              MessageBox(Handle, 'Не удалось обновить запись',
                MesTitle, MB_OK or MB_ICONERROR);
            end;
        end;
      end;
    end;
    Refresh;
    PaydocDBGrid.SelectedRows.Refresh;
  end;
  if (C>0) and (LI>1) then
    MessageBox(Handle, PChar('Не удалось обновить документов: '+IntToStr(C)),
      MesTitle, MB_OK or MB_ICONWARNING);
end;

procedure TPaydocsForm.DataSourceDataChange(Sender: TObject;  Field: TField);
begin
  PayerMemo.Text := DataSource.DataSet.FieldByName('PName').AsString;
  BenefMemo.Text := DataSource.DataSet.FieldByName('RName').AsString;
end;

procedure TPaydocsForm.StateItemClick(Sender: TObject);
const
  MesTitle: PChar = 'Состояние документа';
var
  BankPayRec: TBankPayRec;
  BillRec: TOpRec;
  I, Res, LenD, LenB, LenN: Integer;
  BillForm: TBillForm;
  Editing, ChangeStatus: Boolean;
  Buf: array[0..511] of Char;
  W: Word;
begin
  with TPayDataSet(DataSource.DataSet) do
  begin
    LenD := GetBtrRecord(@BankPayRec);
    if LenD>0 then
    begin
      BillForm := TBillForm.Create(Self);
      with BillForm do
      begin
        //if GetOperNum<>1 then
          LockAllControls;
        with BankPayRec do
        begin
          InputCheckBox.Checked := (dbState and dsInputDoc) > 0;
          ToExportCheckBox.Checked := (dbState and dsExport) = 0;
          SignCheckBox.Checked := (dbState and dsSignError) > 0;
          MailComboBox.ItemIndex := dbState and dsSndType;
          DateSEdit.Text := BtrDateToStr(dbDateS){+'|'+IntToStr(dbDateR)};
          TimeSEdit.Text := BtrTimeToStr(dbTimeS){+'|'+IntToStr(dbTimeR)};
          DateREdit.Text := BtrDateToStr(dbDateR){+'|'+IntToStr(dbDateR)};
          TimeREdit.Text := BtrTimeToStr(dbTimeR){+'|'+IntToStr(dbTimeR)};
          if dbUserCode=0 then
            UserNameEdit.Text := '<не указан>'
          else
            UserNameEdit.Text := OrGetUserNameByCode(Abs(dbUserCode))+' ['+IntToStr(dbUserCode)+']';
        end;
        PayDocPtr := @BankPayRec;
        if GetDocOp(BillRec, BankPayRec.dbIdHere, LenB) then
        begin
          UpdateBillCheckBox.Enabled := True;
          BillPanel.Visible := True;
          with BillRec do
          begin
            if (0<=brPrizn) and (brPrizn<=2) then
              PriznComboBox.ItemIndex := brPrizn;
            DateEdit.Text := BtrDateToStr(brDate);
            if brDel=0 then
              DelComboBox.ItemIndex := 0
            else
              DelComboBox.ItemIndex := 1;
            DebitComboBox.ItemIndex := (brState and dsAnsType) shr 4;
            CreditComboBox.ItemIndex := (brState and dsReSndType) shr 6;
            SenderComboBox.ItemIndex := brState and dsSndType;
            VerSpinEdit.Value := brVersion;
            LenB := LenB - 17;
            if LenB>SizeOf(Buf) then
              LenB := SizeOf(Buf);
            case brPrizn of
              brtBill:
                begin
                  LenB := LenB-53;
                  if LenB<0 then
                    LenB := 0;
                  StrLCopy(Buf, brText, LenB);
                  LenN := StrLen(Buf);
                  DosToWinL(Buf, LenN);
                  NameEdit.Text := StrPas(Buf);

                  Inc(LenN);
                  if LenB-LenN>0 then
                  begin
                    StrLCopy(Buf, @brText[LenN], LenB-LenN);
                    DosToWin(Buf);
                    BillOperEdit.Text := StrPas(Buf);
                  end;

                  NumberEdit.Text := IntToStr(brNumber);
                  VidComboBox.Text := IntToStr(brType);
                  DebetAccEdit.Text := Copy(StrPas(brAccD), 1, SizeOf(brAccD));
                  CreditAccEdit.Text := Copy(StrPas(brAccC), 1, SizeOf(brAccC));
                  SumCalcEdit.Value := brSum / 100.0;
                end;
              brtReturn:
                begin
                  StrLCopy(Buf, brRet, LenB);
                  DosToWinL(Buf, SizeOf(Buf));
                  NameEdit.Text := Buf;
                end;
              brtKart:
                begin
                  StrLCopy(Buf, brKart, LenB);
                  DosToWinL(Buf, SizeOf(Buf));
                  NameEdit.Text := Buf;
                end;
            end;
          end;
          PriznComboBoxChange(nil);
        end
        else
          if not ReadOnly then
            CreatePanel.Show;
        UpdateDocCheckBox.Checked := False;
        UpdateBillCheckBox.Checked := False;
        VerSpinEdit.Font.Color := clBlack;
        DocIdLabel.Caption := 'Id='+IntToStr(BankPayRec.dbIdHere);
        OpIdLabel.Caption := 'Id='+IntToStr(BillRec.brIder);
        Editing := True;
        while Editing and (ShowModal = mrOk) and not ReadOnly do
        begin
          if UpdateDocCheckBox.Checked then
          begin
            with BankPayRec do
            begin
              if InputCheckBox.Checked then
                dbState := dbState or dsInputDoc
              else
                dbState := dbState and not dsInputDoc;
              if ToExportCheckBox.Checked then
                dbState := dbState and not dsExport
              else
                dbState := dbState or dsExport;
              if SignCheckBox.Checked then
                dbState := dbState or dsSignError
              else
                dbState := dbState and not dsSignError;

              dbState := dbState and not dsSndType;
              dbState := dbState or MailComboBox.ItemIndex;
            end;
            I := BankPayRec.dbIdHere;
            if LocateBtrRecordByIndex(I, 0, bsEq) then
            begin
              if UpdateBtrRecord(PChar(@BankPayRec), LenD) then
              begin
                ProtoMes(plWarning, MesTitle, 'Изменено состояние документа '
                  +DocInfo(BankPayRec)+' Id='+IntToStr(BankPayRec.dbIdHere));
                UpdateCursorPos;
              end
              else
                MessageBox(Handle, PChar('Не удалось обновить запись Id='
                  +IntToStr(BankPayRec.dbIdHere)), MesTitle, MB_OK or MB_ICONERROR)
            end
            else
              MessageBox(Handle, 'Не удалось установить курсор на запись',
                MesTitle, MB_OK or MB_ICONERROR);
          end;
          if UpdateBillCheckBox.Checked then
          begin
            with BillRec do
            begin
              LenB := 17;
              brDate := DateToBtrDate(DateEdit.Date);
              brPrizn := PriznComboBox.ItemIndex;
              case brPrizn of
                brtBill:
                  begin
                    brNumber := StrToInt(NumberEdit.Text);
                    brType := StrToInt(VidComboBox.Text);
                    StrPLCopy(brAccD, DebetAccEdit.Text, SizeOf(brAccD));
                    StrPLCopy(brAccC, CreditAccEdit.Text, SizeOf(brAccC));
                    brSum := SumCalcEdit.Value * 100;
                    StrPLCopy(Buf, NameEdit.Text, SizeOf(Buf)-1);
                    WinToDosL(Buf, SizeOf(Buf));
                    StrPLCopy(brText, Buf, SizeOf(brText)-1);
                    LenB := LenB + 53 + StrLen(brText) + 1;
                  end;
                brtReturn:
                  begin
                    StrPLCopy(Buf, NameEdit.Text, SizeOf(brRet)-1);
                    WinToDosL(Buf, SizeOf(Buf));
                    StrPLCopy(brRet, Buf, SizeOf(brRet)-1);
                    LenB := LenB + StrLen(brRet) + 1;
                  end;
                brtKart:
                  begin
                    StrPLCopy(Buf, NameEdit.Text, SizeOf(brKart)-1);
                    WinToDosL(Buf, SizeOf(Buf));
                    StrPLCopy(brKart, Buf, SizeOf(brKart)-1);
                    LenB := LenB + StrLen(brKart) + 1;
                  end;
              end;
              brState := 0;
              if not NewBill then
              begin
                brState := brState or SenderComboBox.ItemIndex;
                brState := brState or (DebitComboBox.ItemIndex shl 4);
                brState := brState or (CreditComboBox.ItemIndex shl 6);
              end;
              brVersion := VerSpinEdit.Value;
              ChangeStatus := NewBill or (brDel<>0) and (DelComboBox.ItemIndex=0)
                or (brDel=0) and (DelComboBox.ItemIndex=1);
              if DelComboBox.ItemIndex=0 then
                brDel := 0
              else
                brDel := 1;
              if ChangeStatus then
              begin
                if NewBill or (brDel=0) then
                begin
                  if brPrizn=brtBill then
                  begin
                    if not CorrectOpSum(brAccD, brAccC, 0, Round(brSum), brDate,
                      BankPayRec.dbIdSender, W, nil)
                    then
                      MessageBox(Application.Handle,
                        PChar('Не удалось обновить состояние счетов'),
                        MesTitle, MB_OK or MB_ICONERROR);
                  end
                  else
                    W := 0;
                end
                else
                  if not DeleteOp(BillRec, BankPayRec.dbIdSender) then
                    MessageBox(Application.Handle,
                      PChar('Не удалось обновить состояние счетов'),
                      MesTitle, MB_OK or MB_ICONERROR);
              end;
            end;
            if NewBill then
            begin
              MakeRegNumber(rnPaydoc, I);
              BillRec.brIder := I;
              BillRec.brDocId := BankPayRec.dbIdHere;
              BillRec.brState := W;
              Res := BillDataSet.BtrBase.Insert(BillRec, LenB, I, 0);
              if Res=0 then
                ProtoMes(plWarning, MesTitle, 'Создана проводка '
                  +' Id='+IntToStr(BillRec.brIder))
              else
                MessageBox(Application.Handle,
                  PChar('Не удалось добавить операцию BtrErr='+IntToStr(Res)),
                  MesTitle, MB_OK or MB_ICONERROR);
            end
            else begin
              I := BillRec.brIder;
              Res := BillDataSet.BtrBase.Update(BillRec, LenB, I, 0);
              if Res=0 then
                ProtoMes(plWarning, MesTitle, 'Изменена проводка '
                  +' Id='+IntToStr(BillRec.brIder))
              else
                MessageBox(Application.Handle,
                  PChar('Не удалось обновить операцию BtrErr='+IntToStr(Res)),
                  MesTitle, MB_OK or MB_ICONERROR);
            end;
          end;
          Editing := False;
        end;
        Free;
      end;
    end
  end;
end;

procedure TPaydocsForm.ReturnItemClick(Sender: TObject);
const
  MesTitle: PChar = 'Возврат';
  MesTitle2: PChar = 'Отмена возврата';
var
  Res, Len, Len0: integer;
  KeyL: longint;
  po: TOpRec;
  ReturnForm: TReturnForm;
  p: TBankPayRec;

  function SetExport(MesTitle: PChar; Value: Boolean): Boolean;
  begin
    Result := False;
    if Value and ((p.dbState and dsExport)>0) or
      not Value and ((p.dbState and dsExport)=0) then
    begin
      KeyL := p.dbIdHere;
      with PayDataSet do
      begin
        if LocateBtrRecordByIndex(KeyL, 0, bsEq) then
        begin
          if Value then
            p.dbState := p.dbState and not dsExport
          else
            p.dbState := p.dbState or dsExport;
          if UpdateBtrRecord(@p, Len0) then
          begin
            Result := True;
            UpdateCursorPos
          end
          else
            MessageBox(Handle, PChar('Не удалось обновить запись Id='
              +IntToStr(p.dbIdHere)), MesTitle, MB_OK or MB_ICONERROR)
        end
        else
          MessageBox(Handle, 'Не удалось установить курсор на запись',
            MesTitle, MB_OK or MB_ICONERROR);
      end;
    end;
  end;

var
  S: string;
begin
  Len0 := PayDataSet.GetBtrRecord(@p);
  if p.dbIdArc = 0 then
  begin
    if GetDocOp(po, p.dbIdHere, Len) then
    begin
      case po.brPrizn of
        brtReturn, brtKart:
          if MessageBox(Application.Handle,
            'Этот документ был возвращен. Удалить возврат (картотеку)?', MesTitle2,
            MB_YESNOCANCEL or MB_ICONWARNING)=ID_YES then
          begin
            KeyL := po.brIder;
            Res := BillDataSet.BtrBase.GetEqual(po, Len, KeyL, 0);
            if Res=0 then
            begin
              if DeleteOp(po, p.dbIdSender) then
              begin
                Res := BillDataSet.BtrBase.Update(po, Len, KeyL, 0);
                if Res=0 then
                begin
                  ProtoMes(plWarning, MesTitle, 'Возврат удален Id='+IntToStr(po.brIder)
                    +' ['+po.brRet+']');
                  SetExport(MesTitle2, True)
                end
                else
                  MessageBox(Application.Handle,
                    PChar('Не удалось обновить возврат BtrErr='+IntToStr(Res)),
                    MesTitle2, MB_OK or MB_ICONERROR);
              end
              else
                MessageBox(Application.Handle, 'Возврат не обнуляется',
                  MesTitle2, MB_OK or MB_ICONERROR);
            end
            else
              MessageBox(Application.Handle,
                PChar('Возврат не найден BtrErr='+IntToStr(Res)),
                MesTitle2, MB_OK or MB_ICONERROR);
          end;
        brtBill:
          MessageBox(Application.Handle,
            'Необходимо удалить проводку в Кворуме и провести импорт', MesTitle,
            MB_OK or MB_ICONINFORMATION);
        else
          MessageBox(Application.Handle, 'Неизвестный тип операции',
            MesTitle, MB_OK or MB_ICONWARNING);
      end;
    end
    else
      if p.dbIdSender<>0 then
      begin
        if NoActiveDocInQrm(p.dbIdHere, True) then
        begin
          FillChar(po, SizeOf(po), #0);
          ReturnForm := TReturnForm.Create(Self);
          with ReturnForm do
          begin
            RetComboBox.Items := ReturnComboBox.Items;
            DateEdit.Date := Date;
            RetComboBox.MaxLength := SizeOf(po.brRet)-1;
            {if not AnalyzePayDoc(p.dbDoc, p.dbDocVarLen, BankFullRec.brCod,
              LowDate, OurKs, S) then
            begin
              RetComboBox.Text := Copy(S, 1, RetComboBox.MaxLength);
            end;}
            if AnalyzePayDoc(p.dbDoc, p.dbDocVarLen, BankFullRec.brCod,
              LowDate, OurKs, S)<>0 then
            begin
              RetComboBox.Text := Copy(S, 1, RetComboBox.MaxLength);
            end;
            RemMemo.Text := S;
            if ShowModal = mrOk then
              if MakeReturn(p.dbIdHere, RetComboBox.Text,
                DateToBtrDate(DateEdit.Date), po)
              then begin
                ProtoMes(plWarning, MesTitle, 'Создан возврат Id='+IntToStr(po.brIder)
                  +' ['+po.brRet+']');
                SetExport(MesTitle, False)
              end
              else
                MessageBox(Application.Handle, 'Не удалось создать возврат',
                  MesTitle, MB_OK or MB_ICONWARNING);
            Free;
          end;
        end
        else
          MessageBox(Handle, 'Документ присутствует в Кворуме',
            MesTitle, MB_OK or MB_ICONWARNING);
      end
      else
        MessageBox(Handle, 'Документ создан в банке. Некуда возвращать',
          MesTitle, MB_OK or MB_ICONWARNING);
  end
  else
    MessageBox(Handle, 'Нельзя изменить операцию архивного документа',
      MesTitle, MB_OK or MB_ICONWARNING);
end;

(*procedure TPaydocsForm.ProccessItemClick(Sender: TObject);
const
  MesTitle: PChar = 'Создание проводки';
var
  Res, Len: integer;
  KeyL: longint;
  pp: pchar;
  l: longint;
  j, c, Bik: integer;
  w: word;
  b: boolean;
  rs, ks: string;
  code, BikStr: string;
  KeyA: TAccount;
  s: string;
  pa: TAccRec;
  po: TOpRec;
  p: TBankPayRec;
  BillForm: TBillForm;
  {BankFullRec: TBankFullRec;}

  function CheckLocks(Cond: word): Boolean;
  begin
    Result := True;
    Len := SizeOf(pa);
    Res := AccDataSet.BtrBase.GetEqual(pa,Len,KeyA,1);
    if Res=0 then
    begin
      if ((pa.arOpts and Cond)<>0) or (p.dbIdSender=pa.arCorr) and
        (p.dbIdSender<>0) and ((pa.arOpts And asLockCl)<>0) then
      begin
        MessageBox(Handle, PChar('Невозможно выполнить операцию, так как счет '
          +KeyA+' заблокирован'),
          MesTitle, MB_OK or MB_ICONWARNING);
        Result := False;
      end;
    end;
  end;
begin
  PayDataSet.GetBtrRecord(@p);
  if GetDocOp(po, p.dbIdHere, Len) then
    MessageBox(Handle, 'Документ уже проведен', MesTitle,
      MB_OK or MB_ICONINFORMATION)
  else begin
    w := $5F;
    FillChar(po, SizeOf(po), #0);
    with po do
    begin
      brDocId := p.dbIdHere;
      s := StrPas(p.dbDoc.drVar);
      Val(s, brNumber, Len);
      brNumber := brNumber mod 1000;
      brDate := DateToBtrDate(Date);
      brSum := p.dbDoc.drSum;
      brType := p.dbDoc.drType;
    end;
    j := 0;
    Inc(j, StrLen(@p.dbDoc.drVar[j])+1);
    rs := StrPas(@p.dbDoc.drVar[j]);
    Inc(j, StrLen(@p.dbDoc.drVar[j]));
    ks := StrPas(@p.dbDoc.drVar[j]);
    Inc(j, StrLen(@p.dbDoc.drVar[j])+1);
    code := StrPas(@p.dbDoc.drVar[j]);
    Inc(j,StrLen(@p.dbDoc.drVar[j])+1);
    b := true;

    BikStr := DecodeMask('$(BankBik)', 5);
    Val(BikStr, Bik, c);

    {s := ks;
    if s<>BankAcc then
      b := false;}
    Val(code, l, c);
    if (c<>0) or (l<>Bik) then
      b := false;
    FillChar(KeyA, SizeOf(KeyA), 0);
    Move(rs[1], KeyA, Length(rs));
    if b then    
    begin
      po.brAccD := KeyA;
      w := w and not $8;
      if not CheckLocks(asLockDt) then
        Exit;
    end
    else
      if l<>Bik then
      begin
        po.brAccD := BankIntAcc;
      end;

    Inc(j,StrLen(@p.dbDoc.drVar[j])+1);
    Inc(j,StrLen(@p.dbDoc.drVar[j])+1);
    Inc(j,StrLen(@p.dbDoc.drVar[j])+1);
    rs := StrPas(@p.dbDoc.drVar[j]);
    Inc(j, StrLen(@p.dbDoc.drVar[j])+1);
    ks := StrPas(@p.dbDoc.drVar[j]);
    Inc(j,StrLen(@p.dbDoc.drVar[j])+1);
    code := StrPas(@p.dbDoc.drVar[j]);
    Inc(j, StrLen(@p.dbDoc.drVar[j])+1);
    b := true;
    s := ks;
    if s<>BankAcc then
      b := false;}
    Val(code,l,c);
    if (c<>0) or (l<>BankCode) then
      b := false;}
    FillChar(KeyA, SizeOf(KeyA), 0);
    Move(rs[1], KeyA, Length(rs));
    if b then
    begin
      po.brAccC := KeyA;
      w := w and not $10;
      if not CheckLocks(asLockCr) then
        Exit;
    end
    else
      if (po.brType=1) and (l<>BankCode) then
        po.brAccC := BankIntAcc;}
    Inc(j, StrLen(@p.dbDoc.drVar[j])+1);
    Inc(j, StrLen(@.dbDoc.drVar[j])+1);
    Inc(j, StrLen(@p.dbDoc.drVar[j])+1);
    pp := @p.dbDoc.drVar[j];
    s := Copy(FirstLine(pp),1,30);
    FillChar(po.brText, SizeOf(po.brText), 0);
    Move(s[1], po.brText, Length(s));

    BillForm := TBillForm.Create(Self);
    with BillForm do
    begin
      if ShowModal = mrOk then
      begin
        if CorrectOpSum(po.brAccD, po.brAccC, 0, po.brSum, w) then
        begin
          with po do
          begin
            MakeRegNumber(rnPaydoc, j);
            brIder := j;
            brState := w;
            Inc(brVersion);
          end;
          Res := BillDataSet.BtrBase.Insert(po, Len, KeyL, 0);
          if Res<>0 then
            MessageBox(Handle, PChar('Не удалось добавить проводку ('
              +IntToStr(Res)+').'+
              #13#10' Исправьте остатки на затронутых счетах'),
              MesTitle, MB_OK+MB_ICONERROR)
        end
        else
          MessageBox(Handle, 'Не удается изменить сумму', MesTitle,
            MB_OK+MB_ICONERROR)
      end;
      Free;
    end;
  end;
end; *)

procedure TPaydocsForm.PaydocDBGridDrawColumnCell(Sender: TObject;
  const Rect: TRect; DataCol: Integer; Column: TColumn;
  State: TGridDrawState);
var
  S: string;
  C: TColor;
  DocDate, CurDate: TDateTime;
  R, G, B: Byte;
  F, M, I: Longint;
  //CurYear, CurMonth, CurDay, PayYear, PayMonth, PayDay: Word;   //Добавлено
begin
  if Column.Field<>nil then
  begin
    if Column.Field.FieldName='drType' then
    begin
      if Length(Column.Field.AsString)>0 then
      begin
        try
          F := Column.Field.AsInteger;
        except
          F := 0;
        end;
        with (Sender as TDBGrid).Canvas do
        begin
          case F of
            {101,102,106,116,191,192:
              begin
                if Brush.Color<>clHighlight then
                  Brush.Color := clYellow
                else
                  Font.Color := clYellow;
              end;}
            9:
              begin
                if Brush.Color<>clHighlight then
                  Brush.Color := clFuchsia
                else
                  Font.Color := clFuchsia;
              end;
            3:
              begin
                if Brush.Color<>clHighlight then
                  Brush.Color := clLime
                else
                  Font.Color := clLime;
              end;
          end;
          if F>100 then
            F := F-100;
          S := FillZeros(F, 2);
          TextRect(Rect, Rect.Left+2, Rect.Top+2, S);
        end;
      end;
    end
    else
    if Column.Field.FieldName='State' then
    begin
      with (Sender as TDBGrid).Canvas do
      begin
        S := Column.Field.AsString;
        if (Pos('СКВ', S)>0) or (Pos('ПРОВ', S)>0)
          or (Pos('пров', S)>0)
        then
          C := clGreen
        else
          if (Pos('ВОЗ', S)>0) or (Pos('воз', S)>0) then
            C := clRed
          else
            if (Pos('ПОЛУ', S)>0) or (Pos('полу', S)>0)
              or (Pos('пере', S)>0)
            then
              C := clBlue
            else
              if Pos('подп', S)>0 then
                C := clPurple
              else
                if (Pos('отп', S)>0) or (Pos('прин', S)>0) then
                  C := {clPurple clYellow}$0088EE
                else
                  if (Pos('КАРТ', S)>0) or (Pos('карт', S)>0) then
                    C := clMaroon
                  //Добавлено Меркуловым
                  else
                    if (Pos('ПОЛ.', S)>0) or (Pos('пол.', S)>0) then
                      C := RGB(255,128,0)
                  //Конец
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
    end
    else  //Добавлено Меркуловым
    if Column.Field.FieldName='drDate' then
    begin
      with (Sender as TDBGrid).Canvas do
      begin
        S := Column.Field.AsString;
        //DecodeBtrDate(Column.Field.AsInteger, PayYear, PayMonth, PayDay);
        if S='' then
          DocDate := 0
        else
          try
            DocDate := StrToDate(S);
          except
            DocDate := 0;
          end;
        //D := Column.Field.AsDateTime;
        //DecodeDate(Date, CurYear, CurMonth, CurDay);
        //DecodeDate(D, YearPay, MonthPay, DayPay);
        CurDate := Date;
        {if (PayDay<=Day) then
          C := clBlack
        else if (MonthPay < Month) then
          C := clBlack
        else if (YearPay < Year) then
          C := clBlack
        else
          C := clRed;}
        if DocDate<CurDate then
          C := clNavy
        else
        if DocDate>CurDate then
          C := clRed
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
        if (ColorToRGB(C) <> ColorToRGB(Brush.Color)) then
          Font.Color := C;
        TextRect(Rect, Rect.Left+2, Rect.Top+2, S);
      end;
    end
    else
    if Column.Field.FieldName='Exported' then
    begin
      S := Column.Field.AsString;
      if S='B' then
        with (Sender as TDBGrid).Canvas do
        begin
          C := clBlue;
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
          if (ColorToRGB(C) <> ColorToRGB(Brush.Color)) then
            Font.Color := C;
          TextRect(Rect, Rect.Left+2, Rect.Top+2, S);
        end;
    end
  end;
end;
{
const
  MesTitle: PChar = 'Проверка подписи';
var
  Len: Integer;
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
      Mode := Mode or smExtFormat;
    CheckSign(@PayRec.dbDoc, SizeOf(TDocRec)-drMaxVar+PayRec.dbDocVarLen,
      Len-(SizeOf(PayRec)-SizeOf(PayRec.dbDoc)), Mode, @ControlData,
      @SignDescr, AllowList);
  end;
end;
}
procedure TPaydocsForm.SignStateItemClick(Sender: TObject);
const
  MesTitle: PChar = 'Проверка подписи';
var
  Len, I, Res, Len2, Mode: Integer;
  PayRec: TBankPayRec;
  ControlData: TControlData;
  AbonRec: TAbonentRec;
  SignDescr: TSignDescr;
  List1, List2, List3: string;
  Compl: DWord;
begin
  Len := TPayDataSet(DataSource.DataSet).GetBtrRecord(@PayRec);
  if Len>0 then
  begin
    ControlData.cdCheckSelf := PayRec.dbIdSender=0;
    Mode := smShowInfo or smCheckLogin or smThoroughly;
    List1 := '';
    List2 := '';
    if ControlData.cdCheckSelf then
    begin
      StrPLCopy(ControlData.cdTagLogin, SenderAcc, SizeOf(ControlData.cdTagLogin)-1);
      ControlData.cdTagNode := MailerNode;
    end
    else begin
      if PayRec.dbState and dsExtended>0 then
        Mode := Mode or smExtFormat;
      I := PayRec.dbIdSender;
      Len2 := SizeOf(AbonRec);
      Res := AbonDataSet.BtrBase.GetEqual(AbonRec, Len2, I, 0);
      if Res=0 then
      begin
        StrLCopy(ControlData.cdTagLogin, AbonRec.abLogin,
          SizeOf(ControlData.cdTagLogin)-1);
        ControlData.cdTagNode := AbonRec.abNode;
        MakeAbonKeyList(AbonRec.abIder, List1, List2, List3, Compl);
      end
      else
        MessageBox(Handle, PChar('Абонент Id='+IntToStr(I)+' не найден'),
          MesTitle, MB_OK or MB_ICONWARNING);
    end;
    SignDescr.siLoginNameProc := @ClientGetLoginNameProc;
    CheckSign(@PayRec.dbDoc, SizeOf(TDocRec)-drMaxVar+PayRec.dbDocVarLen,
      Len-(SizeOf(PayRec)-SizeOf(PayRec.dbDoc)), Mode, @ControlData,
      @SignDescr, List1+DividerOfList+List2+DividerOfList+List3);
  end;
(*
const
  MesTitle: PChar = 'Проверка подписи';
var
  NF, NT, NO: word;
  I, Len, Res: Integer;
  Node: word;
  PayRec: TBankPayRec;
  //CorrRec: TCorrRec;
  S: string;
begin
  ?
  (*
  Len := TPayDataSet(DataSource.DataSet).GetBtrRecord(@PayRec);
  if Len>0 then
  begin
    if IsSigned(PayRec) then
    begin
      NT := 0;
      NF := 0;
      NO := 0;
      Node := 0;
      S := '';
      if PayRec.dbIdSender>0 then
      begin
        I := PayRec.dbIdSender;
        Res := CorrDataSet.BtrBase.GetEqual(CorrRec, Len, I, 0);
        if Res=0 then
          Node := CorrRec.crNode
        else
          S := 'Внимание: Неизвестный корреспондент'#13#10;
      end
      else
        Node := MailerNode;
      Len := (SizeOf(PayRec.dbDoc)-drMaxVar+SignSize)+PayRec.dbDocVarLen;
      Res := TestSign(@PayRec.dbDoc, Len, NF, NO, NT);
      I := MB_ICONWARNING;
      if PayRec.dbIdSender>0 then
      begin
        if (Res=$10) or (Res=$110) then
          I := MB_ICONINFORMATION;
      end
      else begin
        if (Res=$5) or (Res=$4) then
          I := MB_ICONINFORMATION;
      end;
      S := S + 'Параметры: оператор '+IntToStr(NO)
        +', узел-отправитель '+IntToStr(NF)+', узел-получатель '+IntToStr(NT)
        +', код='+Format('%x', [Res])+'h'#13#10'Заключение: подпись ';
      if I=MB_ICONINFORMATION then
        S := S + 'корректна'
      else
        S := S + 'ошибочна';
      MessageBox(Handle, PChar(S), MesTitle, MB_OK or I);
    end
    else
      MessageBox(Handle, 'Документ не подписан', MesTitle, MB_OK or MB_ICONWARNING);
  end;
  *)
end;

var
  AllList: TStringList = nil;
const
  OverflowCount = 10;

procedure TPaydocsForm.NotSendedItemClick(Sender: TObject);
const
  MesTitle: PChar = 'Проверка неотправленных проводок';
var
  LastDate, KeyO: Word;
  Len, Res, nsoBill, nsoRet: Integer;
  AccArcRec: TAccArcRec;
  KeyAA:
    packed record
      aaIder: longint;
      aaDate:   word;
    end;
  BillRec: TOpRec;
  Overflow: Boolean;
  S: string;
  {
  KeyL: Longint;
  e: TLetterRec;
  InfoList: TList;
  LastDate, KeyO: word;
  paa: TAccArcRec;
  PColRec: PCollectionRec;
  Corr: longint;
  Key2:
    packed record
      k2BitIder:  word;
      k2FileIder: longint;
      k2Abonent:  longint;
      k2State:    word;
    end;
  ps: PSendFileRec;
  psa, Key1: TSprAboRec;
  psc: TSprCorRec;}

  function AddInfo(D: Word; S: string): Boolean;
  begin
    if AllList=nil then
    begin
      AllList := TStringList.Create;
      AllList.Duplicates := dupIgnore;
    end;
    if not Overflow then
    begin
      if AllList.Count>OverflowCount then
      begin
        AllList.Add('...');
        Overflow := True;
      end
      else
        AllList.Add(BtrDateToStr(D)+' - '+S);
    end;
  end;

begin
  AllList.Free;
  AllList := nil;
  Overflow := False;

  LastDate := 0;
  Len := SizeOf(AccArcRec);
  Res := AccArcDataSet.BtrBase.GetLast(AccArcRec, Len, KeyAA, 0);
  if Res=0 then
  begin
    LastDate := AccArcRec.aaDate;
    StatusBar.SimpleText := 'Просмотр проводок за закрытые дни...';
    nsoBill := 0;
    nsoRet := 0;
    Len := SizeOf(BillRec);
    Res := BillDataSet.BtrBase.GetFirst(BillRec, Len, KeyO, 2);
    while (Res=0) and (KeyO<=LastDate) and not Overflow do
    begin
      Res := BillNeedSend(BillRec, True, S);
      case Res of
        1,2,3:
          begin
            Inc(nsoBill);
            AddInfo(BillRec.brDate, S+' (п)');
          end;
        4:
          begin
            Inc(nsoRet);
            AddInfo(BillRec.brDate, S+' (в)');
          end;
      end;
      Len := SizeOf(BillRec);
      Res := BillDataSet.BtrBase.GetNext(BillRec, Len, KeyO, 2);
    end;
    StatusBar.SimpleText := '';
    if (nsoBill=0) and (nsoRet=0) then
      MessageBox(Handle, 'В закрытых днях нет неотправленных выписок',
        MesTitle, MB_OK or MB_ICONINFORMATION)
    else
      MessageBox(Handle, PChar('В закрытых днях есть неотправленные выписки:'#13#10
        +'проводок - '+IntToStr(nsoBill)+#13#10
        +'возвратов - '+IntToStr(nsoRet)+#13#10'Информация по выпискам:'#13#10
        +AllList.Text), MesTitle, MB_OK or MB_ICONWARNING);
    AllList.Free;
    AllList := nil;
  end
  else
    MessageBox(Handle, 'Нет закрытых дней', MesTitle, MB_OK or MB_ICONINFORMATION);
end;

procedure TPaydocsForm.TotalSumItemClick(Sender: TObject);
const
  MesTitle: PChar = 'Подсчет общей суммы';
var
  N, N0, C, I, Len: Integer;
  PayRec: TBankPayRec;
  DS: TPayDataSet;
  Sum: comp;
begin
  PaydocDBGrid.SelectedRows.Refresh;
  N0 := PaydocDBGrid.SelectedRows.Count;
  DS := TPayDataSet(DataSource.DataSet);
  with DS do
  begin
    N := N0;
    if N=0 then
      Inc(N);
    I := 0;
    C := 0;
    Sum := 0;
    while I<N do
    begin
      if N0>0 then
        Bookmark := PaydocDBGrid.SelectedRows.Items[I];
      Len := GetBtrRecord(@PayRec);
      if Len>0 then
      begin
        Sum := Sum + PayRec.dbDoc.drSum;
        Inc(C);
      end;
      Inc(I);
    end;
    PaydocDBGrid.SelectedRows.Refresh;
    MessageBox(Handle, PChar('Общая сумма '+SumToStr(Sum)
      +#13#10'Подсчитано документов: '+IntToStr(C)), MesTitle,
      MB_OK or MB_ICONINFORMATION);
  end;
end;

procedure TPaydocsForm.SaveDocItemClick(Sender: TObject);
const
  MesTitle: PChar = 'Сохранение документа в файл';
var
  BankPayRec: TBankPayRec;
  Len: Integer;
  FN: string;
  F: file of Byte;
begin
  with TPayDataSet(DataSource.DataSet) do
  begin
    Len := GetBtrRecord(@BankPayRec);
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
            BlockWrite(F, BankPayRec.dbDoc,
              Len-(SizeOf(BankPayRec)-SizeOf(BankPayRec.dbDoc)));
          finally
            CloseFile(F);
          end;
          MessageBox(Handle, PChar('Документ '+DocInfo(BankPayRec)
            +' сохранен в файл '+FN), MesTitle, MB_OK or MB_ICONINFORMATION)
        end
        else
          MessageBox(Handle, PChar('Не удалось создать файл '+FN),
            MesTitle, MB_OK or MB_ICONERROR)
      end;
    end;
  end;
end;

procedure TPaydocsForm.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (Key=VK_DELETE) and (ssCtrl in Shift) and (ssShift in Shift) then
    DelItemClick(nil);
end;

//Добавлено Меркуловым
procedure TPaydocsForm.KomissItemClick(Sender: TObject);
const
  MesTitle: PChar = 'Изменение свойства "снятие комиссии"';
var
  BankPayRec: TBankPayRec;
  N, LI, I, Len, C, CorrRes: Integer;
  {Number, PAcc, PKs, PCode, PInn, PClient, PBank,
  RAcc, RKs, RCode, RInn, RClient, RBank, Purpose, PKpp, RKpp,
  Status, Kbk, Okato, OsnPl, Period, NDoc, DocDate, TipPl,
  Nchpl, Shifr, Nplat, OstSum: string;}
begin
  PaydocDBGrid.SelectedRows.Refresh;
  N := PaydocDBGrid.SelectedRows.Count;
  with TPayDataSet(DataSource.DataSet) do
  begin
    if N=0 then
      LI := 1
    else
      LI := N;
    C := LI;
    for I := 0 to LI-1 do
    begin
      //Len := Sizeof(BankPayRec);
      //Fillchar(BankPayRec,Len,#0);
      if N>0 then
        Bookmark := PaydocDBGrid.SelectedRows.Items[I];
      Len := GetBtrRecord(@BankPayRec);
      if Len>0 then
      begin
        {DecodeDocVar(BankPayRec.dbDoc, BankPayRec.dbDocVarLen,
          Number, PAcc, PKs, PCode, PInn, PClient, PBank,
          RAcc, RKs, RCode, RInn, RClient, RBank, Purpose, PKpp, RKpp,
          Status, Kbk, Okato, OsnPl, Period, NDoc, DocDate, TipPl,
          Nchpl, Shifr, Nplat, OstSum, 0, 0, CorrRes, False); }
        if BankPayRec.dbIdSender>0
         {(BankPayRec.dbState and dsRsAfter>0) or
          (((BankPayRec.dbTimeR<TimeToBtrTime(StrToTime('16:10'))) or
          (BankPayRec.dbDoc.drDate<>BankPayRec.dbDateR) or
          (Length(Status)>0) or (RCode=PCode)) and
          (}{MessageBox(ParentWnd,PChar('Вы действительно хотите сменить пометку "комиссия" на документе?'
          +#10#13+DocInfo(BankPayRec)),MesTitle,MB_YESNO)=IDYES{)) or
          (BankPayRec.dbTimeR>TimeToBtrTime(StrToTime('16:10')))} then
        begin
          BankPayRec.dbState := BankPayRec.dbState xor dsRsAfter;
          if UpdateBtrRecord(@BankPayRec, Len) then
            Dec(C)
          else
            MessageBox(Handle, 'Не удалось обновить запись', MesTitle, MB_OK or MB_ICONERROR);
        end
        else
          MessageBox(ParentWnd,PChar('Нельзя сменить пометку не на входящем документе'
            +#10#13+DocInfo(BankPayRec)), MesTitle, MB_OK or MB_ICONWARNING)
      end;
    end;
    Refresh;
    PaydocDBGrid.SelectedRows.Refresh;
  end;
  if (C>0) and (LI>1) then
    MessageBox(Handle, PChar('Не удалось обновить документов: '+IntToStr(C)),
      MesTitle, MB_OK or MB_ICONWARNING);
end;

end.
