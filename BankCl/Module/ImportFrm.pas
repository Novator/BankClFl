unit ImportFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Grids, Db, DBTables, DBGrids, ExtCtrls, DBCtrls, BtrDS, Menus, CrySign,
  SearchFrm, UserFrm, StdCtrls, ComCtrls, Buttons, Btrieve, Common, DocFunc,
  Utilits, Bases, Registr, CommCons, ClntCons, DbfDataSet, SdfDataSet;

type
  TImportForm = class(TDataBaseForm)
    DataSource: TDataSource;
    DBGrid: TDBGrid;
    ChildMenu: TMainMenu;
    OperItem: TMenuItem;
    OpenItem: TMenuItem;
    ShutItem: TMenuItem;
    EditBreaker: TMenuItem;
    FindItem: TMenuItem;
    StatusBar: TStatusBar;
    CompressItem: TMenuItem;
    EditBreaker1: TMenuItem;
    ImportItem: TMenuItem;
    EditPopupMenu: TPopupMenu;
    OpenDialog: TOpenDialog;
    SdfTable: TSdfDataSet;
    DbfTable: TDbfDataSet;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure OpenItemClick(Sender: TObject);
    procedure FindItemClick(Sender: TObject);
    procedure ShutItemClick(Sender: TObject);
    procedure CompressItemClick(Sender: TObject);
    procedure ImportItemClick(Sender: TObject);
    procedure DBGridDrawDataCell(Sender: TObject; const Rect: TRect;
      Field: TField; State: TGridDrawState);
    procedure FormShow(Sender: TObject);
  private
    SearchForm: TSearchForm;
  public
    function OpenImportBase(Choose: Boolean): Boolean;
    function AllFieldIsExist: Boolean;
    procedure ChooseFile;
  end;

const
  ImportForm: TImportForm = nil;

var
  ObjList: TList;

implementation

const
  DosCharset: Boolean = False;

{$R *.DFM}

function GetClientByAcc(Bik: Integer; AccS: string; DosCharset: Boolean;
  var Client: TNewClientRec): Boolean;
var
  ClientDataSet: TExtBtrDataSet;
  Len, Res: Integer;
  ClientKey:
    packed record
      Bik: LongInt;
      Acc: TAccount
    end;
begin
  Result := False;
  ClientDataSet := GlobalBase(biClient);
  if ClientDataSet<>nil then
  begin
    ClientKey.Bik := Bik;
    StrTCopy(ClientKey.Acc, PChar(AccS), SizeOf(ClientKey.Acc));
    Len := SizeOf(Client);
    Res := ClientDataSet.BtrBase.GetEqual(Client, Len, ClientKey, 0);
    if Res=0 then
    begin
      Result := True;
      if not DosCharset then
        DosToWinL(Client.clNameC, SizeOf(Client.clNameC));
    end
    else
      FillChar(Client, SizeOf(Client), #0)
  end;
end;

var
  ExportFormat: Integer = 1;
  ExportFile: string = '';
  ExportFile2: string = '';
  TotalExport: Boolean = False;
  FullExport: Boolean = False;
  FirstExport: Boolean = False;
  CloseExport: Boolean = False;
  ReservExport: Integer = 50;

  DefOcher: Integer = 6;
  ChooseImport: Boolean = True;
  FirstImport: Boolean = False;
  CloseImport: Boolean = False;
  CheckCharMode: Integer = 0;
  ReceiverNode: Integer = 0;
  TestKpp: Boolean = True;
  SignNew: Boolean = True;
  ImportFormat0, CurImportFormat, DelMode: Integer;

  FillBank: Boolean = True;

  ClientAcc: string = '';
  ClientName: string = '';
  ClientInn: string = '';

  PtrBank: PBankFullNewRec = nil;
  Bank: TBankFullNewRec;
  PtrClient: PNewClientRec = nil;
  Client: TNewClientRec;
  ImportFile: string = '';
  DefImpAcc: string = '';
  ImportDefFile: string = '';
  CleanFields: Integer = 0;
  DefPayVO: Integer = 101;
  BankBik: Integer = 0;
  DoubleImpMode: Integer = 0;

  SetExportMark: Boolean = False;

  ControlData: TControlData;

procedure TImportForm.FormCreate(Sender: TObject);
var
  Res, Len, I: Integer;
  UserRec: TUserRec;
  AccDataSet: TExtBtrDataSet;
  AccRec: TAccRec;
  T: array[0..511] of Char;
begin
  ObjList.Add(Self);
  PtrBank := nil;
  PtrClient := nil;
  SearchForm := TSearchForm.Create(Self);
  SearchForm.SourceDBGrid := DBGrid;
  TakeMenuItems(OperItem, EditPopupMenu.Items);
  EditPopupMenu.Images := ChildMenu.Images;
  if not GetRegParamByName('DefPayVO', CommonUserNumber, DefPayVO) then
    DefPayVO := 101;
  if not GetRegParamByName('ImportDosCharset', CommonUserNumber, DosCharset) then
    DosCharset := False;
  if not GetRegParamByName('PaySeq', CommonUserNumber, DefOcher) then
    DefOcher := 6;
  if not GetRegParamByName('PaySeq', CommonUserNumber, DefOcher) then
    DefOcher := 6;
  OpenDialog.FileName := DecodeMask('$(ImportFile)', 5, CommonUserNumber);
  if not GetRegParamByName('ChooseImport', CommonUserNumber, ChooseImport) then
    ChooseImport := True;
  if not GetRegParamByName('DelImportMode', CommonUserNumber, DelMode) then
    DelMode := 0;
  if not GetRegParamByName('ImportFmt', CommonUserNumber, ImportFormat0) then
    ImportFormat0 := 0;
  if not GetRegParamByName('TestKpp', CommonUserNumber, TestKpp) then
    TestKpp := True;
  if not GetRegParamByName('FirstImport', CommonUserNumber, FirstImport) then
    FirstImport := False;
  if not GetRegParamByName('CloseImport', CommonUserNumber, CloseImport) then
    CloseImport := False;
  if not GetRegParamByName('FillBank', CommonUserNumber, FillBank) then
    FillBank := True;
  if not GetRegParamByName('CheckCharMode', CommonUserNumber, CheckCharMode) then
    CheckCharMode := 0;
  if not GetRegParamByName('SetExportMark', CommonUserNumber, SetExportMark) then
    SetExportMark := False;
  if not GetRegParamByName('DoubleImpMode', CommonUserNumber, DoubleImpMode) then
    DoubleImpMode := 0;
  if not GetRegParamByName('SignImported', CommonUserNumber, SignNew) or not
    GetRegParamByName('ReceiverNode', CommonUserNumber, ReceiverNode)
  then
    SignNew := False;
  try
    BankBik := StrToInt(DecodeMask('$(BankBik)', 5, CommonUserNumber));
  except
    BankBik := -1;
  end;
  if BankBik<0 then
    BankBik := 45744803;
  FillChar(Bank, SizeOf(Bank), #0);
  if FillBank then
  begin
    if not GetFullBankByBik(BankBik, DosCharset, Bank) then
      with Bank do
      begin
        brCod := 45744803;
        brKs := '30101810700000000803';
        brName := 'ФАКБ "ТРАНСКАПИТАЛБАНК"'#13#10'Г. ПЕРМЬ';
        if DosCharset then
          WinToDos(brName);
      end;
    PtrBank := @Bank;
  end;
  FillChar(Client, SizeOf(Client), #0);
  DefImpAcc := DecodeMask('$(DefImpAcc)', 5, CommonUserNumber);
  if Length(DefImpAcc)>0 then
  begin
    if DefImpAcc='0' then
    begin
      DefImpAcc := '';
      CurrentUser(UserRec);
      I := UserRec.urFirmNumber;
      if I>0 then
      begin
        AccDataSet := GlobalBase(biAcc);
        if AccDataSet<>nil then
        begin
          Len := SizeOf(AccRec);
          Res := AccDataSet.BtrBase.GetEqual(AccRec, Len, I, 0);
          if Res=0 then
            DefImpAcc := Copy(StrPas(AccRec.arAccount), 1,
              SizeOf(AccRec.arAccount));
        end;
      end;
    end;
    if Length(DefImpAcc)>0 then
      if GetClientByAcc(BankBik, DefImpAcc, DosCharset, Client) then
        PtrClient := @Client;
  end;
  if not GetRegParamByName('CloseImport', CommonUserNumber, CloseImport) then
    CloseImport := False;
  if not GetRegParamByName('CleanFields', CommonUserNumber, CleanFields) then
    CleanFields := 0;
  ImportDefFile := DecodeMask('$(ImportDefFile)', 5, CommonUserNumber);
  FillChar(ControlData, SizeOf(ControlData), #0);
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

procedure TImportForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  ShutItemClick(nil);
  Action := caFree;
end;

procedure TImportForm.FormDestroy(Sender: TObject);
begin
  ImportForm := nil;
  ObjList.Remove(Self);
end;

procedure TImportForm.FindItemClick(Sender: TObject);
begin
  SearchForm.ShowModal;
end;

const
  NumOfFields1 = 50;
  FldNames1: array[1..NumOfFields1] of string =
    ('NUMBER', 'PACC', 'PKS', 'PCODE', 'PINN', 'PCLIENT1', 'PCLIENT2', 'PCLIENT3',
    'PBANK1', 'PBANK2', 'RACC', 'RKS', 'RCODE', 'RINN',
    'RCLIENT1', 'RCLIENT2', 'RCLIENT3', 'RBANK1', 'RBANK2',
    'NAZN1', 'NAZN2', 'NAZN3', 'NAZN4', 'NAZN5',
    'DATE', 'VID', 'SUM', 'OPTYPE', 'OCHER',
    'SROK', 'STATE', 'NUMOP', 'DATEOP', 'DTACC', 'CRACC', 'INFO',
    'PKPP', 'RKPP',
    'STATUS', 'KBK', 'OKATO', 'OSNPL', 'PERIOD', 'NDOC', 'DOCDATE', 'TIPPL',
    'NCHPL', 'SHIFR', 'NPLAT', 'OSTSUM');

  NumOfFields2 = 34;
  FldNames2: array[1..NumOfFields2] of string =
    ('NUMBER', 'DATE', 'VID', 'SUMMA',
    'PACC', 'PCODE', 'PKS', 'PINN', 'PCLIENT', 'PBANK',
    'RCODE', 'RACC', 'RKS', 'RBANK', 'RINN', 'RCLIENT',
    'OPTYPE', 'OCHER', 'SROK', 'NAZN',
    'PKPP', 'RKPP',
    'STATUS', 'KBK', 'OKATO', 'OSNPL', 'PERIOD', 'NDOC', 'DOCDATE', 'TIPPL',
    'NCHPL', 'SHIFR', 'NPLAT', 'OSTSUM');

  NumOfFields3 = 36;
  FldNames3: array[1..NumOfFields3] of string =
    ('BEGIN', 'END', 'NUMBER', 'DATE', 'VID', 'SUMMA',
    'PACC', 'PCODE', 'PKS', 'PINN', 'PCLIENT', 'PBANK',
    'RCODE', 'RACC', 'RKS', 'RBANK', 'RINN', 'RCLIENT',
    'OPTYPE', 'OCHER', 'SROK', 'NAZN',
    'PKPP', 'RKPP', 'STATUS', 'KBK', 'OKATO',
    'OSNPL', 'PERIOD', 'NDOC', 'DOCDATE', 'TIPPL', 'NCHPL', 'SHIFR', 'NPLAT', 'OSTSUM');

  NumOfFields5 = 34;
  FldNames5: array[1..NumOfFields5] of string =
    ('DATE', 'NUMBER', 'SUMMA', 'VIDOP', 'VIDPL', 'OCHER',
    'PBANK', 'PBIK', 'PKS', 'PNAME', 'PACC', 'PINN', 'PKPP',
    'RBANK', 'RBIK', 'RKS', 'RNAME', 'RACC', 'RINN', 'RKPP',
    'NAZN', 'SROKPL',
    'STATUS', 'KBK', 'OKATO', 'OSNPL', 'PERIOD', 'NDOC', 'DOCDATE', 'TIPPL',
    'NCHPL', 'SHIFR', 'NPLAT', 'OSTSUM');


function TImportForm.AllFieldIsExist: Boolean;
const
  MesTitle: PChar = 'Проверка файла обмена';
var
  I: Integer;
  F: TField;
begin
  Result := DataSource.DataSet<>nil;
  if Result then
    with DataSource.DataSet do
    begin
      Result := Active;
      if Result then
      begin
        if Active then
          case CurImportFormat of
            1:
              begin
                for I := 1 to 28 do
                begin
                  F := FindField(FldNames1[I]);
                  if F=nil then
                  begin
                    Result := False;
                    MessageBox(Handle, PChar('Поле ['+FldNames1[I]+'] не найдено'),
                      MesTitle, MB_OK or MB_ICONERROR);
                  end;
                end;
              end;
            2,3:
              begin
                for I := 1 to NumOfFields2 do
                begin
                  F := FindField(FldNames2[I]);
                  if (F=nil) and (I<>18) and (I<>19) then
                  begin
                    Result := False;
                    MessageBox(Handle, PChar('Поле ['+FldNames2[I]+'] не найдено'),
                      MesTitle, MB_OK or MB_ICONERROR);
                  end;
                end;
              end;
            5:
              begin
                for I := 1 to NumOfFields5 do
                begin
                  F := FindField(FldNames5[I]);
                  if (F=nil) and not (I in [5,13,20]) and (I<22) then
                  begin
                    Result := False;
                    MessageBox(Handle, PChar('Поле ['+FldNames5[I]+'] не найдено'),
                      MesTitle, MB_OK or MB_ICONERROR);
                  end;
                end;
              end;
          end;
      end;
    end;
end;

procedure TImportForm.ChooseFile;
var
  S: string;
begin
  if ChooseImport or (Length(OpenDialog.FileName)=0) then
  begin
    case ImportFormat0 of
      1,2: OpenDialog.FilterIndex := 1;
      3: OpenDialog.FilterIndex := 2;
      else
        OpenDialog.FilterIndex := 3;
    end;
    if OpenDialog.Execute then
      ImportFile := OpenDialog.FileName
    else
      ImportFile := '';
  end
  else
    ImportFile := OpenDialog.FileName;
  if ImportFormat0>0 then
    CurImportFormat := ImportFormat0
  else begin
    DosCharset := True;
    S := UpperCase(ExtractFileExt(ImportFile));
    if S='.DBF' then
      CurImportFormat := 1
    else
    if S='.SDF' then
      CurImportFormat := 3
    else begin
      CurImportFormat := 4;
      DosCharset := False;
    end;
  end;
end;

function TImportForm.OpenImportBase(Choose: Boolean): Boolean;
const
  MesTitle: PChar = 'Открытие базы';
begin
  Result := False;
  if Choose then
    ChooseFile;
  if Length(ImportFile)>0 then
  begin
    case CurImportFormat of
      1,2,5: DataSource.DataSet := DbfTable;
      3: DataSource.DataSet := SdfTable;
      else
        DataSource.DataSet := nil;
    end;
    Result := DataSource.DataSet<>nil;
    if Result then
      with DataSource.DataSet do
      begin
        try
          if Self.DataSource.DataSet is TDbfDataSet then
            (Self.DataSource.DataSet as TDbfDataSet).TableName := ImportFile
          else
            if Self.DataSource.DataSet is TSdfDataSet then
              (Self.DataSource.DataSet as TSdfDataSet).TableName := ImportFile
            else
              MessageBox(Handle, 'Неизвестная база', MesTitle, MB_OK
                or MB_ICONERROR);
          Active := True;
          if Active and not AllFieldIsExist and (MessageBox(Handle,
            PChar('В файле импорта ['+ImportFile+'] не найдены необходмые поля'
            +#13#10'Хотите ли вы открыть этот файл?'),
            MesTitle, MB_YESNOCANCEL + MB_DEFBUTTON2 or MB_ICONWARNING)<>ID_YES)
          then
            Active := False;
          Result := Active;
        except
          Result := False;
          MessageBox(Handle, PChar('Не удается открыть файл импорта'
            +#13#10'['+ImportFile+']'), MesTitle, MB_OK or MB_ICONERROR);
        end;
      end
    else
      MessageBox(Handle, PChar('Неизвестный формат импорта '
        +IntToStr(CurImportFormat)+#13#10'['+OpenDialog.FileName+']'),
        MesTitle, MB_OK or MB_ICONERROR);
  end;
end;

procedure TImportForm.OpenItemClick(Sender: TObject);
begin
  OpenImportBase(True);
end;

procedure TImportForm.ShutItemClick(Sender: TObject);
begin
  DbfTable.Close;
  SdfTable.Close;
end;

procedure TImportForm.CompressItemClick(Sender: TObject);
begin
  DbfTable.PackTable;
end;

var
  DocDataSet: TExtBtrDataSet;
  PayRec: TPayRec;
  Number, PAcc, PKs, PCode, PInn, PClient, PBank,
    RAcc, RKs, RCode, RInn, RClient, RBank, Nazn, S,
    Status, PKpp, RKpp, Kbk, Okato, OsnPl, Period, NDoc, DocDate, TipPl,
    Nchpl, Shifr, Nplat, OstSum: string;
  NoError{, Signed}: Boolean;
  PayCount, SkipCount, SignCount, Offset, CorrResult: Integer;
  CommonSum: Comp;
  T: array[0..1023] of Char;

procedure AddRecord;
const
  MesTitle: PChar = 'Добавление записи';
var
  Err, Key, CorrRes, SignLen: Integer;
  S: string;
begin
  with PayRec do
  begin
    if (PayRec.dbDoc.drType in [1,2,6,16,91,92]) and (DefPayVO>100) then
      PayRec.dbDoc.drType := PayRec.dbDoc.drType+DefPayVO-1;
    EncodeDocVar(dbDoc.drType>100, Number, PAcc, PKs, PCode, PInn, PClient, PBank,
      RAcc, RKs, RCode, RInn, RClient, RBank, Nazn, PKpp, RKpp, Status, Kbk, Okato,
      OsnPl, Period, NDoc, DocDate, TipPl, Nchpl, Shifr, Nplat, OstSum,
      CheckCharMode, CleanFields, CorrRes,
      DosCharset, TestKpp, PtrClient, PtrBank, dbDoc, Err);
    dbDocVarLen := Err;
  end;
  if (DoubleImpMode=0) or (not IsPayDocExist(DocDataSet, PayRec.dbIdOut,
    Number, PayRec.dbDoc.drDate, PayRec.dbDoc.drType,
    PayRec.dbDoc.drSum) or (DoubleImpMode=2) and (MessageBox(Application.Handle,
    PChar('Документ уже существует'+DocInfo(PayRec)+#13#10'Еще раз загрузить этот документ?'),
    MesTitle, MB_YESNOCANCEL or MB_DEFBUTTON2 or MB_ICONWARNING)=ID_YES)) then
  begin
    with PayRec do
    begin
      MakeRegNumber(rnPaydoc, dbIdHere);
      dbIdOut := dbIdHere;
      if SetExportMark then
        dbState := dbState or dsExport;
    end;
    {Signed := False;}
    SignLen := 0;
    if SignNew and ((CheckCharMode>1) or (CorrRes=0)) and
      (AnalyzePayDoc(PayRec.dbDoc, PayRec.dbDocVarLen, BankBik, 10, '', S)=0) then
    begin
      {MessageBox(Handle,}
      {Signed := SignPaydoc;}
      SignLen :=
        AddSign(0, @PayRec.dbDoc, SizeOf(TDocRec)-drMaxVar+PayRec.dbDocVarLen,
        SizeOf(TDocRec), smOverwrite or smShowInfo, @ControlData, '');
    end;
    Offset := SizeOf(PayRec)-drMaxVar+PayRec.dbDocVarLen+SignLen;
    Err := DocDataSet.BtrBase.Insert(PayRec, Offset, Key, 0);
    if Err=0 then
    begin
      CommonSum := CommonSum + PayRec.dbDoc.drSum;
      Inc(PayCount);
      if SignLen>0 then
        Inc(SignCount);
    end
    else begin
      MessageBox(Application.MainForm.Handle, 'Не удается добавить запись',
        MesTitle, MB_OK or MB_ICONERROR);
      NoError := False;
    end;
  end
  else
    Inc(SkipCount);
end;

function FinishImport(MesTitle: PChar): Boolean;
begin
  if not NoError or (CorrResult<>0) then
  begin
    if NoError then
      S := ''
    else
      S := 'Не все документы были импортированы.'#13#10
        +'Сообщите настройщику экспорта внешней (бухгалтерской) программы';
    if CorrResult<>0 then
    begin
      if Length(S)>0 then
        S := S+#13#10#13#10;
      S := S+'В документах найдены недопустимые символы.'#13#10;
      if CheckCharMode>1 then
        S := S+'Все они были исправлены'
      else
        S := S+'Их необходимо исправить';
    end;
    MessageBox(Application.Handle, PChar(S),
      MesTitle, MB_OK or MB_ICONWARNING);
  end;
  Result := (DelMode=2) and (NoError or
    (MessageBox(Application.Handle, 'Удалить файл обмена?', MesTitle,
      MB_YESNOCANCEL or MB_ICONWARNING)=IDYES));
  S := 'Всего импортировано: '+IntToStr(PayCount)
    +#13#10'на общую сумму: '+SumToStr(CommonSum);
  if SignNew then
    S := S+#13#10'Из них подписано: '+IntToStr(SignCount);
  if SkipCount>0 then
    S := S+#13#10'Пропущенно дублей: '+IntToStr(SkipCount);
  MessageBox(Application.MainForm.Handle, PChar(S), MesTitle,
    MB_OK or MB_ICONINFORMATION);
end;

procedure TImportForm.ImportItemClick(Sender: TObject);
const
  MesTitle: PChar = 'Импорт';
  NilFld: PChar = 'None';
var
  I, Err, J, K: Integer;
  F: TField;
  S1, V, N: string;
  TF1, TF2: TextFile;
  Names: TStringList;
  Filling: Boolean;
  SumVal: Double;
begin
  ShutItemClick(nil);
  ChooseFile;
  if Length(ImportFile)>0 then
  begin
    try
      try
        DocDataSet := GlobalBase(biPay);
      except
        MessageBox(Application.MainForm.Handle, 'Не удается открыть базу Doc',
          MesTitle, MB_OK or MB_ICONERROR);
        raise;
      end;
      Screen.Cursor := crHourGlass;
      NoError := True;
      PayCount := 0;
      SkipCount := 0;
      CommonSum := 0;
      SignCount := 0;
      CorrResult := 0;

      if CurImportFormat=4 then
      begin
        if Length(ImportDefFile)>0 then
          S1 := ImportDefFile
        else
          S1 := ChangeFileExt(ImportFile, '.fld');
        AssignFile(TF1, S1);
        FileMode := 0;
        {$I-} Reset(TF1); {$I+}
        if IOResult=0 then
        begin
          Names := TStringList.Create;
          try
            for I := 1 to NumOfFields3 do
              Names.Add(NilFld);
            while not Eof(TF1) do
            begin
              ReadLn(TF1, V);
              V := Trim(V);
              if Length(V)>0 then
              begin
                I := Pos('=', V);
                if I>0 then
                begin
                  N := UpperCase(Trim(Copy(V, 1, I-1)));
                  Delete(V, 1, I);
                  I := 1;
                  while (I<=NumOfFields3) and (UpperCase((FldNames3[I]))<>N) do
                    Inc(I);
                  if I<=NumOfFields3 then
                  begin
                    J := Pos(';', V);
                    if J>0 then
                      Delete(V, J, Length(V)-J+1);
                    V := Trim(V);
                    J := Length(V);
                    if (J>0) then
                    begin
                      if V[J]='*' then
                      begin
                        Names.Objects[I-1] := Self;
                        Delete(V, J, 1);
                        Dec(J);
                      end;
                      if J>0 then
                        Names.Strings[I-1] := RusUpperCase(V);
                    end;
                  end
                  else
                    MessageBox(Handle, PChar('Неизвестный параметр ['+N+']'),
                      MesTitle, MB_OK or MB_ICONERROR);
                end;
              end;
            end;
            CloseFile(TF1);
            AssignFile(TF2, ImportFile);
            FileMode := 0;
            {$I-} Reset(TF2); {$I+}
            if IOResult=0 then
            begin
              Filling := False;
              while not Eof(TF2) do
              begin
                ReadLn(TF2, V);
                V := Trim(V);
                if Length(V)>0 then
                begin
                  if Filling then
                  begin
                    if RusUpperCase(V)=Names[1] then
                    begin
                      Filling := False;
                      AddRecord;
                    end
                    else begin
                      I := Pos('=', V);
                      if I>0 then
                      begin
                        N := RusUpperCase(Trim(Copy(V, 1, I-1)));
                        Delete(V, 1, I);
                        I := Length(N);
                        J := I;
                        while (J>0) and ('0'<=N[J]) and (N[J]<='9') do
                          Dec(J);
                        if J<I then
                        begin
                          Val(Copy(N, J+1, I-J), K, Err);
                          if Err=0 then
                            Delete(N, J+1, I-J)
                          else
                            K := 0;
                        end
                        else
                          K := 0;
                        I := Names.IndexOf(N);
                        if (I>1) and
                          ((K=0) and (Names.Objects[I]=nil)
                          or (K>0) and (Names.Objects[I]<>nil)) then
                        begin
                          Dec(I);
                          S := Trim(V);
                          with PayRec do
                          begin
                            with dbDoc do
                            begin
                              case I of
                                1: Number := S;
                                2: drDate := StrToBtrDate(S); {DATE}
                                3:              {VID}
                                  begin
                                    Val(S, drIsp, Err);
                                    if Err<>0 then
                                      drIsp := 2;
                                  end;
                                4:
                                  begin
                                    Val(S, SumVal, Err);
                                    drSum := Round(SumVal*100.0);
                                  end;
                                5: PAcc := S;
                                6: PCode := S;
                                7: PKs := S;
                                8: PInn := S;
                                9:
                                  begin
                                    if K>1 then
                                      PClient := PClient + #13#10 + S
                                    else
                                      PClient := S;
                                  end;
                                10:
                                  begin
                                    if K>1 then
                                      PBank := PBank + #13#10 + S
                                    else
                                      PBank := S;
                                  end;
                                11: RCode := S;
                                12: RAcc := S;
                                13: RKs := S;
                                14:
                                  begin
                                    if K>1 then
                                      RBank := RBank + #13#10 + S
                                    else
                                      RBank := S;
                                  end;
                                15: RInn := S;
                                16:
                                  begin
                                    if K>1 then
                                      RClient := RClient + #13#10 + S
                                    else
                                      RClient := S;
                                  end;
                                17:
                                  begin
                                    Val(S, drType, Err);
                                    if Err<>0 then
                                      drType := 1;
                                  end;
                                18:
                                  begin
                                    Val(S, drOcher, Err);
                                    if Err<>0 then
                                      drOcher := DefOcher;
                                  end;
                                19: drSrok := StrToBtrDate(S);
                                20:
                                  begin
                                    if K>1 then
                                      Nazn := Nazn + #13#10 + S
                                    else
                                      Nazn := S;
                                  end;
                                21: PKpp := S;
                                22: RKpp := S;
                                23: Status := S;
                                24: Kbk := S;
                                25: Okato := S;
                                26: OsnPl := S;
                                27: Period := S;
                                28: NDoc := S;
                                29: DocDate := S;
                                30: TipPl := S;
                                31: Nchpl := S;
                                32: Shifr := S;
                                33: Nplat := S;
                                34: OstSum := S;
                              end;
                            end;
                          end;
                        end;
                      end;
                    end;
                  end
                  else begin
                    if RusUpperCase(V)=Names[0] then
                    begin
                      Filling := True;
                      FillChar(PayRec, SizeOf(PayRec), #0);
                      PayRec.dbDoc.drType := DefPayVO;
                      PayRec.dbDoc.drIsp := 2;
                      Number := '';
                      PAcc := '';
                      PKs := '';
                      PCode := '';
                      PInn := '';
                      PKpp := '';
                      PClient := '';
                      PBank := '';
                      RAcc := '';
                      RKs := '';
                      RCode := '';
                      RInn := '';
                      RKpp := '';
                      RClient := '';
                      RBank := '';
                      Nazn := '';
                      Status := '';
                      Kbk := '';
                      Okato := '';
                      OsnPl := '';
                      Period := '';
                      NDoc := '';
                      DocDate := '';
                      TipPl := '';
                      Nchpl := '';
                      Shifr := '';
                      Nplat := '';
                      OstSum := '';
                    end;
                  end;
                end;
              end;
              CloseFile(TF2);
              if FinishImport(MesTitle) then
                Erase(TF2);
            end
            else
              MessageBox(Handle, PChar('Файл обмена не найден'#13#10'['+ImportFile+']'),
                MesTitle, MB_OK or MB_ICONWARNING);
          finally
            Names.Free;
          end;
        end
        else
          MessageBox(Handle, PChar('Файл описания полей не найден ['+S1+']'),
            MesTitle, MB_OK or MB_ICONWARNING);
      end
      else begin
        if OpenImportBase(False) and (DataSource.DataSet<>nil) then
        begin
          with DataSource.DataSet do
          begin
            begin
              First;
              if (CurImportFormat>=1) and (CurImportFormat<=5) then
              begin
                while not EoF do
                begin
                  FillChar(PayRec, SizeOf(PayRec), #0);     {Заполнение записи}
                  PayRec.dbDoc.drType := DefPayVO;
                  PayRec.dbDoc.drIsp := 2;
                  Number := '';
                  PAcc := '';
                  PKs := '';
                  PCode := '';
                  PInn := '';
                  PKpp := '';
                  PClient := '';
                  PBank := '';
                  RAcc := '';
                  RKs := '';
                  RCode := '';
                  RInn := '';
                  RKpp := '';
                  RClient := '';
                  RBank := '';
                  Nazn := '';
                  Status := '';
                  Kbk := '';
                  Okato := '';
                  OsnPl := '';
                  Period := '';
                  NDoc := '';
                  DocDate := '';
                  TipPl := '';
                  Nchpl := '';
                  Shifr := '';
                  Nplat := '';
                  OstSum := '';
                  try
                    with PayRec do
                    begin
                      with dbDoc do
                      begin
                        case CurImportFormat of
                          1:
                            begin
                              for I := 1 to NumOfFields1 do
                              begin
                                F := FindField(FldNames1[I]);
                                if F<>nil then
                                begin
                                  S := Trim(F.AsString);
                                  case I of
                                    1: Number := S;
                                    2: PAcc := S;
                                    3: PKs := S;
                                    4: PCode := S;
                                    5: PInn := S;
                                    6: PClient := S;
                                    7: if Length(S)>0 then
                                      PClient := PClient + #13#10 + S;
                                    8: if Length(S)>0 then
                                      PClient := PClient + #13#10 + S;
                                    9: PBank := S;
                                    10: if Length(S)>0 then
                                      PBank := PBank + #13#10 + S;
                                    11: RAcc := S;
                                    12: RKs := S;
                                    13: RCode := S;
                                    14: RInn := S;
                                    15: RClient := S;
                                    16: if Length(S)>0 then
                                      RClient := RClient + #13#10 + S;
                                    17: if Length(S)>0 then
                                      RClient := RClient + #13#10 + S;
                                    18: RBank := S;
                                    19: if Length(S)>0 then
                                      RBank := RBank + #13#10 + S;
                                    20: Nazn := S;
                                    21: if Length(S)>0 then
                                      Nazn := Nazn + #13#10 + S;
                                    22: if Length(S)>0 then
                                      Nazn := Nazn + #13#10 + S;
                                    23: if Length(S)>0 then
                                      Nazn := Nazn + #13#10 + S;
                                    24: if Length(S)>0 then
                                      Nazn := Nazn + #13#10 + S;
                                    25: drDate := StrToBtrDate(S);
                                    26:
                                      begin
                                        Val(S, drIsp, Err);
                                        if Err<>0 then
                                          drIsp := 2;
                                      end;
                                    27:
                                      begin
                                        try
                                          drSum := StrToFloat(S)*100.0;
                                        except
                                          drSum := 0;
                                          Err := 1;
                                        end;
                                      end;
                                    28:
                                      begin
                                        Val(S, drType, Err);
                                        if Err<>0 then
                                          drType := 1;
                                      end;
                                    29:
                                      begin
                                        Val(S, drOcher, Err);
                                        if Err<>0 then
                                          drOcher := DefOcher;
                                      end;
                                    30: drSrok := StrToBtrDate(S);
                                    31..36: ;
                                    37: PKpp := S;
                                    38: RKpp := S;
                                    39: Status := S;
                                    40: Kbk := S;
                                    41: Okato := S;
                                    42: OsnPl := S;
                                    43: Period := S;
                                    44: NDoc := S;
                                    45: DocDate := S;
                                    46: TipPl := S;
                                    47: Nchpl := S;
                                    48: Shifr := S;
                                    49: Nplat := S;
                                    50: OstSum := S;
                                  end;
                                end;
                              end;
                            end;
                          2,3:
                            begin
                              for I := 1 to NumOfFields2 do
                              begin
                                F := FindField(FldNames2[I]);
                                if F<>nil then
                                begin
                                  S := Trim(F.AsString);
                                  case I of
                                    1: Number := S;
                                    2: drDate := StrToBtrDate(S); {DATE}
                                    3:              {VID}
                                      begin
                                        Val(S, drIsp, Err);
                                        if Err<>0 then
                                          drIsp := 2;
                                      end;
                                    4:
                                      begin
                                        try
                                          drSum := StrToFloat(S)*100.0;
                                        except
                                          drSum := 0;
                                          Err := 1;
                                        end;
                                      end;
                                    5: PAcc := S;
                                    6: PCode := S;
                                    7: PKs := S;
                                    8: PInn := S;
                                    9: PClient := S;
                                    10: PBank := S;

                                    11: RCode := S;
                                    12: RAcc := S;
                                    13: RKs := S;
                                    14: RBank := S;
                                    15: RInn := S;
                                    16: RClient := S;
                                    17:
                                      begin
                                        Val(S, drType, Err);
                                        if Err<>0 then
                                          drType := 1;
                                      end;
                                    18:
                                      begin
                                        Val(S, drOcher, Err);
                                        if Err<>0 then
                                          drOcher := DefOcher;
                                      end;
                                    19: drSrok := StrToBtrDate(S);
                                    20: Nazn := S;
                                    21: PKpp := S;
                                    22: RKpp := S;
                                    23: Status := S;
                                    24: Kbk := S;
                                    25: Okato := S;
                                    26: OsnPl := S;
                                    27: Period := S;
                                    28: NDoc := S;
                                    29: DocDate := S;
                                    30: TipPl := S;
                                    31: Nchpl := S;
                                    32: Shifr := S;
                                    33: Nplat := S;
                                    34: OstSum := S;
                                  end;
                                end;
                              end;
                            end;
                          5:
                            begin
                              for I := 1 to NumOfFields5 do
                              begin
                                F := FindField(FldNames5[I]);
                                if F<>nil then
                                begin
                                  S := Trim(F.AsString);
                                  case I of
                                    1: drDate := StrToBtrDate(S); {DATE}
                                    2: Number := S;
                                    3:
                                      begin
                                        try
                                          drSum := StrToFloat(S)*100.0;
                                        except
                                          drSum := 0;
                                          Err := 1;
                                        end;
                                      end;
                                    4:             {VIDOP}
                                      begin
                                        Val(S, drType, Err);
                                        if Err<>0 then
                                          drType := 1;
                                      end;
                                    5:              {VIDPL}
                                      begin
                                        Val(S, drIsp, Err);
                                        if Err<>0 then
                                          drIsp := 2;
                                      end;
                                    6:
                                      begin
                                        Val(S, drOcher, Err);
                                        if Err<>0 then
                                          drOcher := DefOcher;
                                      end;
                                    7: PBank := S;
                                    8: PCode := S;
                                    9: PKs := S;
                                    10: PClient := S;
                                    11: PAcc := S;
                                    12: PInn := S;
                                    13: PKpp := S;
                                    14: RBank := S;
                                    15: RCode := S;
                                    16: RKs := S;
                                    17: RClient := S;
                                    18: RAcc := S;
                                    19: RInn := S;
                                    20: RKpp := S;
                                    21: Nazn := S;
                                    22: drSrok := StrToBtrDate(S);
                                    23: Status := S;
                                    24: Kbk := S;
                                    25: Okato := S;
                                    26: OsnPl := S;
                                    27: Period := S;
                                    28: NDoc := S;
                                    29: DocDate := S;
                                    30: TipPl := S;
                                    31: Nchpl := S;
                                    32: Shifr := S;
                                    33: Nplat := S;
                                    34: OstSum := S;
                                  end;
                                end;
                              end;
                            end;
                        end;
                      end;
                    end;
                    AddRecord;
                  except
                    NoError := False;
                    raise;
                  end;
                  if (DelMode=1) and (Err=0) then
                    Delete
                  else
                    Next;
                end;
                ShutItemClick(nil);
                if FinishImport(MesTitle) then
                begin
                  if Self.DataSource.DataSet is TDbfDataSet then
                    S := (Self.DataSource.DataSet as TDbfDataSet).TableName
                  else
                    if Self.DataSource.DataSet is TSdfDataSet then
                      S := (Self.DataSource.DataSet as TSdfDataSet).TableName;
                  if not DeleteFile(S) then
                    MessageBox(Handle, PChar('Не удалось удалить файл ['+S+']'),
                      MesTitle, MB_OK or MB_ICONERROR);
                end;
              end
              else
                MessageBox(Application.MainForm.Handle, PChar('Для формата импорта '
                  +IntToStr(CurImportFormat)+' функции не определены'),
                  MesTitle, MB_OK or MB_ICONERROR);
            end;
          end
        end;
      end;
    finally
      Screen.Cursor := crDefault;
      DocDataSet.Refresh;
    end;
  end;
  if CloseImport then
    Close;
end;

var
  Buf: array[0..1023] of Char;

procedure TImportForm.DBGridDrawDataCell(Sender: TObject;
  const Rect: TRect; Field: TField; State: TGridDrawState);
var
  Size: TSize;
begin
  with (Sender as TDBGrid).Canvas do
  begin
    StrPLCopy(Buf, Field.Text, SizeOf(Buf));
    if DosCharset then
      DosToWin(Buf);
    Size := TextExtent(Buf);
    TextRect(Rect, Rect.Left+2, (Rect.Bottom + Rect.Top - Size.cy) div 2, Buf);
  end;
end;

procedure TImportForm.FormShow(Sender: TObject);
begin
  if FirstImport then
    ImportItemClick(nil);
end;

end.
