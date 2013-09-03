unit ValdocsFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Grids, Db, DBTables, DBGrids, ExtCtrls, DBCtrls, BtrDS, Menus, StdCtrls,
  ToolEdit, Mask, ComCtrls, SearchFrm, Sign, DateFrm,
  ImgList, Btrieve, Common, Bases, Utilits, Registr, CommCons,
  Buttons, ClntCons;

type
  TValdocsForm = class(TDataBaseForm)
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
  private
    SearchForm: TSearchForm;
    PayDataSet: TValPayDataSet;
    procedure MakeFormMenuItems;
    function GetCurrentModule: HModule;
    procedure InsertItemClick(Sender: TObject);
    procedure WMMakeStatement(var Message: TMessage); message WM_MAKESTATEMENT;
  protected
    function CloseDays: Boolean;
    function ReopenDays: Boolean;
    function UserMayEditDoc(ADocCode: Byte): Boolean;
    function TestNonClosedDays: Boolean;
  public
    procedure UpdateDocumentByCode(CopyCurrent, New, ReadOnly: Boolean;
      ADocCode: Byte);
    function GetBank(Bik: string; var BankFullRec: TBankFullRec): Boolean;
    procedure TakeFormPrintData(var GraphForm, TextForm: TFileName;
      var DBGrid: TDBGrid); override;
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
  ValdocsForm: TValdocsForm;
  DLLList: TList;
  PayObjList: TList;

function GetModuleByCode(Code: Byte): HModule;

implementation

uses ValBillsFrm;

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

function TValdocsForm.GetCurrentModule: HModule;
begin
  Result:=GetModuleByCode(PPayRec(DataSource.DataSet.ActiveBuffer)^.dbDoc.drType);
end;

var
  DefPayVO: Integer = 1;

procedure TValdocsForm.MakeFormMenuItems;
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

procedure TValdocsForm.FormCreate(Sender: TObject);
var
  User: TUserRec;
  ColorPayState: Boolean;
begin
  PayObjList.Add(Self);

  if not GetRegParamByName('ReceiverNode', ReceiverNode) then
    ReceiverNode := -1;

  if not GetRegParamByName('DefPayVO', DefPayVO) then
    DefPayVO := 1;

  PayDataSet := GlobalBase(biValdoc) as TValPayDataSet;
  DataSource.DataSet := PayDataSet;

  DefineGridCaptions(DBGrid, PatternDir+'Valdocs.tab');
  MakeFormMenuItems;

  SearchForm := TSearchForm.Create(Self);
  SearchForm.SourceDBGrid := DBGrid;
  SearchIndexComboBox.ItemIndex := 0;
  SearchIndexComboBoxChange(Sender);

  TakeMenuItems(OperItem, EditPopupMenu.Items);
  EditPopupMenu.Images := ChildMenu.Images;

  CurrentUser(User);
  BillItem.Visible := User.urLevel=0;

  if not GetRegParamByName('ColorPayState', ColorPayState) then
    ColorPayState := False;
  if not ColorPayState then
    DBGrid.OnDrawColumnCell := nil;
end;

procedure TValdocsForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
end;

procedure TValdocsForm.FormDestroy(Sender: TObject);
begin
  PayObjList.Remove(Self);
  ValdocsForm := nil;
end;

type
  GetPrintForm = function: TFileName;

procedure TValdocsForm.TakeFormPrintData(var GraphForm, TextForm: TFileName;
  var DBGrid: TDBGrid);
var
  I: Byte;
begin
  inherited TakeFormPrintData(GraphForm, TextForm, DBGrid);
  DBGrid := Self.DBGrid;
  I := PPayRec(DataSource.DataSet.ActiveBuffer)^.dbDoc.drType;
  case I of
    1,2,16,91,92:
      begin
        GraphForm := DecodeMask('$(PayGraphForm)', 5);
        TextForm := DecodeMask('$(PayTextForm)', 5);
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
        GraphForm := DecodeMask('$(CashGraphForm)', 5);
        TextForm := DecodeMask('$(CashTextForm)', 5);
      end;
    6,9:
      begin
        GraphForm := DecodeMask('$(MemGraphForm)', 5);
        TextForm := DecodeMask('$(MemTextForm)', 5);
      end;
    101,102,116,191,192:
      begin
        GraphForm := DecodeMask('$(GrForm101)', 5);
        TextForm := DecodeMask('$(TxForm101)', 5);
      end;
    else begin
      GraphForm := DecodeMask('$(GrForm'+IntToStr(I)+')', 5);
      TextForm := DecodeMask('$(TxForm'+IntToStr(I)+')', 5);
    end;
  end;
end;

type
  EditBankRecord = function(Sender: TComponent; RecPtr: Pointer;
    SearchIndex: Integer; ShowDlg: Boolean): Boolean;

function TValdocsForm.GetBank(Bik: string; var BankFullRec: TBankFullRec):
  Boolean;
var
  ModuleName: array[0..511] of Char;
  Module: HModule;
  P: Pointer;
  Err: Integer;
begin
  Result := False;
  StrPLCopy(ModuleName, DecodeMask('$(Banks)', 5), SizeOf(ModuleName));
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

function PaydocSignMayChangeByOper(var PayRec: TPayRec;
  var S: string): Boolean;
var
  NF, NT, NO: word;
  Len, Res: Integer;
  AUserRec: TUserRec;
begin
  Result := not IsSigned(PayRec);
  if not Result then
  begin
    NT := 0;
    NF := 0;
    NO := 0;
    Len := (SizeOf(PayRec.dbDoc)-drMaxVar+SignSize)+PayRec.dbDocLen;
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
end;

function SignPaydoc(var PayRec: TPayRec): Boolean;
const
  MesTitle: PChar = 'Создание подписи';
begin
  if ReceiverNode>=0 then
  begin
    Result := MakeSign(PChar(@PayRec.dbDoc),
      PayRec.dbDocLen+SizeOf(TDocRec)-drMaxVar, ReceiverNode, 1)>0;
    if not Result then
      MessageBox(Application.Handle, 'Не удалось сгенерировать подпись',
        MesTitle, MB_ICONERROR or MB_OK);
  end
  else
    MessageBox(Application.Handle, 'Не известен узел получателя',
      MesTitle, MB_ICONERROR or MB_OK);
end;

function TValdocsForm.UserMayEditDoc(ADocCode: Byte): Boolean;
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

procedure TValdocsForm.UpdateDocumentByCode(CopyCurrent, New, ReadOnly: Boolean;
  ADocCode: Byte);
const
  MesTitle: PChar = 'Редактирование записи';
var
  DLLModule: HModule;
  P: Pointer;
  PayRec: TPayRec;
  LastIdHere, Offset, I, Num: Integer;
  Year, Month, Day, DocState: Word;
  {FirmRec: TFirmRec;}
  T: array[0..1023] of Char;
  Bik: string;
  BankFullRec: TBankFullRec;
  {FirmAccRec: TFirmAccRec;}
  SignNew: Boolean;
begin
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
            GetBtrRecord(PChar(@PayRec))
          else
            FillChar(PayRec, SizeOf(PayRec), #0);
          if New then
          begin
            DecodeDate(Date, Year, Month, Day);
            with PayRec do
            begin
              dbDoc.drDate := CodeBtrDate(Year, Month, Day);
              dbDoc.drIsp := 2;
              if GetRegParamByName('PaySeq', I) then
                dbDoc.drOcher := I
              else
                dbDoc.drOcher := 6;
              I := ADocCode;
              if I>100 then
                I := I - 100;
              if not GetRegParamByName('PayNum'+IntToStr(I), Num) then
                Num := 0;
              if CopyCurrent then
              begin
                I := StrLen(@dbDoc.drVar[0])+1;
                Offset := dbDocLen-I;
                Move(dbDoc.drVar[I], T, Offset);
                StrPCopy(@dbDoc.drVar[0], IntToStr(Num+1));
                I := StrLen(@dbDoc.drVar[0])+1;
                Move(T, dbDoc.drVar[I], Offset);
                dbDocLen := Offset + I;
              end
              else begin
                {CurrentFirm(FirmRec, FirmAccRec);}
                Bik := DecodeMask('$(BankBik)', 5);
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
                        if not GetRegParamByName('CashAcc', T) then
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
                dbDocLen := Offset;
              end;
              dbIdHere := LastIdHere;
              dbIdKorr :=0;
              dbIdIn := 0;
              dbIdOut := dbIdHere;
              dbIdArc := 0;
              dbIdDel := 0;
              dbState := 0;
              dbDoc.drType := ADocCode;
            end;
          end;
          ReadOnly := ReadOnly or (PayRec.dbIdHere=0);
          if not ReadOnly then
          begin
            {DocState := GetDocState(@PayRec);
            ReadOnly := not((DocState = adsNone)
              or (DocState = adsSigned) and (New
              or (GetNode>0) and PaydocSignMayChangeByOper(PayRec, Bik)));}
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
          begin
            if PaydocEditRecord(P)(Self, @PayRec, ReadOnly, New
              and not CopyCurrent) then
            begin
              if not GetRegParamByName('SignPaydoc', SignNew) then
                SignNew := False;
              FillChar(PChar(@PayRec.dbDoc.drVar)[PayRec.dbDocLen], SignSize, #0);
              if SignNew and (GetNode>0) then
              begin
                if not SignPaydoc(PayRec) then
                  MessageBox(Handle, 'Не удалось подписать документ',
                    MesTitle, MB_OK or MB_ICONERROR)
              end;
              I := SizeOf(TPayRec)-drMaxVar+PayRec.dbDocLen+SignSize;
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
                SetRegParamByName('PayNum'+IntToStr(I), IntToStr(Num));
              end;
              DataSourceDataChange(nil, nil);
            end;
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

procedure TValdocsForm.SignItemClick(Sender: TObject);
const
  MesTitle: PChar = 'Изменение подписи';
var
  PayRec: TPayRec;
  I,R,N, Num: Integer;
  U: Boolean;
  DocState, Len: Word;
  S: string;
begin
  if GetNode>0 then
  begin
    with PayDataSet do
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
              {DocState := GetDocState(@PayRec);}
              if (DocState = adsSigned) or (DocState = adsNone) then
              begin
                if PaydocSignMayChangeByOper(PayRec, S) then
                begin
                  U := IsSigned(PayRec);
                  if U then
                    FillChar(PChar(@PayRec.dbDoc.drVar)[PayRec.dbDocLen],
                      SignSize, #0)
                  else begin
                    U := TestPaydoc(PayRec, True);
                    if U then
                      U := SignPaydoc(PayRec);
                  end;
                  if U then
                  begin
                    I := SizeOf(TPayRec)-drMaxVar+PayRec.dbDocLen+SignSize;
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
                    PChar(S+'. Нельзя изменить подпись'
                    +DocInfo(PayRec)), MesTitle, MB_OK or MB_ICONINFORMATION)
              end
              else
                MessageBox(Handle,
                  PChar('Документ уже отправлен в банк. Нельзя изменить подпись'
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

procedure TValdocsForm.EditItemClick(Sender: TObject);
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

procedure TValdocsForm.InsertItemClick(Sender: TObject);
var
  Code: Integer;
begin
  Code := (Sender as TMenuItem).Tag;
  UpdateDocumentByCode(False, True, False, Code)
end;

procedure TValdocsForm.DelItemClick(Sender: TObject);
const
  MesTitle: PChar = 'Удаление';
var
  N, LI, C, I, Len: Integer;
  PayRec: TPayRec;
  DS: TPayDataSet;

  function PaydocCanDel(var PayRec: TPayRec): Boolean;
  var
    DocState: Integer;
    S: string;
  begin
    S := '';
    Result := PayRec.dbIdArc = 0;
    if Result then
    begin
      DocState := DS.GetDocState(@PayRec);
      Result := (DocState = adsNone);
      if not Result then
      begin
        Result := IsSanctAccess('DelPaydocSanc');
        if Result then
        begin
          Result := PaydocSignMayChangeByOper(PayRec, S);
          if Result then
          begin
            Result := (DocState = adsSigned) and (PayRec.dbIdOut>0);
            if not Result then
            begin
              Result := (DocState = adsSndRcv) or (DocState = adsSigned);
              if Result then
              begin
                Result := IsSanctAccess('DelNoBillDocSanc');
                if Result then
                  Result := MessageBox(Handle,
                    PChar('Документ не имеет проводки, но существует в банке.'
                    +#13#10'Вы согласовали это удаление с банком?'
                    +DocInfo(PayRec)), MesTitle,
                    MB_YESNOCANCEL or MB_ICONWARNING) = ID_YES
                else
                  S := 'Вы не можете удалять принятые документы';
              end
              else
                S := 'Состояние документа не допускает его удаление';
            end;
          end;
        end
        else
          S := 'Вы не можете удалять подписанные документы';
      end;
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
      if (Len>0) and PaydocCanDel(PayRec)
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

procedure TValdocsForm.SearchItemClick(Sender: TObject);
begin
  SearchForm.ShowModal;
end;

procedure TValdocsForm.BillItemClick(Sender: TObject);
begin
  if ValBillsForm = nil then
    ValBillsForm := TValBillsForm.Create(Self)
  else
    ValBillsForm.Show;
end;

procedure TValdocsForm.SearchIndexComboBoxChange(Sender: TObject);
var
  I: Integer;
begin
  with PayDataSet do
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

function TValdocsForm.CloseDays: Boolean;
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
  AccDataSet, AccArcDataSet, BillDataSet, DocDataSet: TExtBtrDataSet;
  Date1, Date2: TDateTime;
  CloseDayLim: Integer;
begin
  Result := False;
  try
    DataSource.Enabled := False;

    AccDataSet := GlobalBase(biAcc);
    AccArcDataSet := GlobalBase(biAccArc);
    BillDataSet := GlobalBase(biBill);
    DocDataSet := GlobalBase(biPay);

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
          if not GetRegParamByName('CloseDayLim', CloseDayLim) then
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
                Result := True;
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
  end;
end;

function TValdocsForm.ReopenDays: Boolean;
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
  BillDataSet, AccArcDataSet, DocDataSet: TExtBtrDataSet;
  UpdateErr: Boolean;
begin
  Result := false;
  try
    DataSource.Enabled := False;

    AccArcDataSet := GlobalBase(biAccArc);
    BillDataSet := GlobalBase(biBill);
    DocDataSet := GlobalBase(biPay);

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
          Result := True;
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
  end;
end;

procedure TValdocsForm.CloseDaysItemClick(Sender: TObject);
begin
  if IsSanctAccess('ArchDaysSanc') then
    CloseDays
  else
    MessageBox(Handle, 'Вы не можете закрывать/открывать опердни', 'Закрытие дней',
      MB_OK or MB_ICONINFORMATION);
end;

procedure TValdocsForm.OpenDaysItemClick(Sender: TObject);
begin
  if IsSanctionAccess(3) then
    ReopenDays
  else
    MessageBox(Handle, 'Вы не можете закрывать/открывать опердни', 'Раскрытие дней',
      MB_OK or MB_ICONINFORMATION);
end;

const
  MemoDist = 5;

procedure TValdocsForm.BtnPanelResize(Sender: TObject);
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

function TValdocsForm.TestNonClosedDays: Boolean;
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
  if GetRegParamByName('AutoCloseDay', AutoCloseDay) and (AutoCloseDay>0) then
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
          MesTitle, MB_YESNOCANCEL or MB_ICONQUESTION) = IDYES);
    end;
  finally
    StatusBar.SimpleText := '';
  end;
end;

procedure TValdocsForm.WMMakeStatement(var Message: TMessage);
begin
  if TestNonClosedDays then
    CloseDaysItemClick(Self);
end;

const
  WasAsked: Boolean = False;

procedure TValdocsForm.FormShow(Sender: TObject);
begin
  BtnPanelResize(Sender);
  if not WasAsked then
  begin
    PostMessage(Handle, WM_MAKESTATEMENT, 0, 0);
    WasAsked := True;
  end;
end;

procedure TValdocsForm.ReturnItemClick(Sender: TObject);
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
        if GetDocOp(Bill, PayRec.dbIdKorr) and (Bill.brPrizn=brtReturn) then
        begin
          DosToWin(Bill.brRet);
          S := StrPas(Bill.brRet);
          MessageBox(Handle, PChar('['+S+']'),
            'Причина возврата', MB_OK or MB_ICONINFORMATION);
        end;
    end
  end;
end;

procedure TValdocsForm.ExchangeItemClick(Sender: TObject);
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

procedure TValdocsForm.DataSourceDataChange(Sender: TObject;
  Field: TField);
begin
  PayerMemo.Text := DataSource.DataSet.FieldByName('PName').AsString;
  BenefMemo.Text := DataSource.DataSet.FieldByName('RName').AsString;
end;

procedure TValdocsForm.DBGridDrawColumnCell(Sender: TObject;
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
    if Column.Field.FieldName='drType' then
    begin
      F := Column.Field.AsInteger;
      with (Sender as TDBGrid).Canvas do
      begin
        if F=101 then
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
    if Column.Field.FieldName='State' then
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
            if Pos('подпис', S)>0 then
              C := clPurple
            else
              if (Pos('отпр', S)>0) or (Pos('прин', S)>0) then
                C := {clPurple clYellow}$0088EE
              else
                if (Pos('возв', S)>0) or (Pos('ош', S)>0) then
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
        if {(Brush.Color<>clHighlight)
          and} (ColorToRGB(C) <> ColorToRGB(Brush.Color))
        then
          Font.Color := C;
        TextRect(Rect, Rect.Left+2, Rect.Top+2, S);
      end;
    end;
  end;
end;

procedure TValdocsForm.FormResize(Sender: TObject);
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

procedure TValdocsForm.CheckItemClick(Sender: TObject);
const
  MesTitle: PChar = 'Проверка подписи';
var
  NF, NT, NO: word;
  I, Len, Res: Integer;
  PayRec: TPayRec;
  S: string;
begin
  Len := TPayDataSet(DataSource.DataSet).GetBtrRecord(@PayRec);
  if Len>0 then
  begin
    if IsSigned(PayRec) then
    begin
      NT := 0;
      NF := 0;
      NO := 0;
      S := '';
      Len := (SizeOf(PayRec.dbDoc)-drMaxVar+SignSize)+PayRec.dbDocLen;
      Res := TestSign(@PayRec.dbDoc, Len, NF, NO, NT);
      I := MB_ICONWARNING;
      if NF=ReceiverNode then
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
end;

procedure TValdocsForm.SignedItemClick(Sender: TObject);
begin
  {if SignedDocsForm = nil then
    SignedDocsForm := TSignedDocsForm.Create(Self)
  else
    SignedDocsForm.Show;
  SignedDocsForm.MakeItemClick(nil);}
end;

procedure TValdocsForm.FormActivate(Sender: TObject);
begin
  SearchIndexComboBoxChange(nil);
end;

end.
