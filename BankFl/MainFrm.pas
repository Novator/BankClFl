unit MainFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ComCtrls, Menus, ExtCtrls, ToolWin, StdCtrls, GraphPrims, Db, BtrDS,
  DBGrids, ImgList, Buttons, Placemnt, Utilits, Basbn, Common, Registr,
  CommCons, Registry, ShellApi, RunMes, ExportBaseFrm, CrySign, TccItcs,
  Orakle, BankCnBn;                                     //Добавлено Меркуловым

const
  FirmPanelIndex = 0;
  NamePanelIndex = 1;
  ProgressPanelIndex = 2;
  InfoPanelIndex = 3;

type
  TMainForm = class(TForm)
    MainMenu: TMainMenu;
    StatusBar: TStatusBar;
    WinItem: TMenuItem;
    HelpItem: TMenuItem;
    ContentsItem: TMenuItem;
    HelpBreaker2: TMenuItem;
    AboutItem: TMenuItem;
    FileItem: TMenuItem;
    QuitItem: TMenuItem;
    FileBreaker1: TMenuItem;
    CascadeItem: TMenuItem;
    TileItem: TMenuItem;
    TopicItem: TMenuItem;
    ServiceItem: TMenuItem;
    ServiceBraeker: TMenuItem;
    SetupItem: TMenuItem;
    FileBreaker2: TMenuItem;
    PrintSetupItem: TMenuItem;
    PreviewItem: TMenuItem;
    PrintItem: TMenuItem;
    PrintDialog: TPrintDialog;
    PrinterSetupDialog: TPrinterSetupDialog;
    MinimizeItem: TMenuItem;
    NormalizeItem: TMenuItem;
    ArrangeItem: TMenuItem;
    CloseAllItem: TMenuItem;
    WinBreaker: TMenuItem;
    ToolBar: TToolBar;
    ImageList: TImageList;
    ProgressBar: TProgressBar;
    MainFormStorage: TFormStorage;
    UpdateItem: TMenuItem;
    SetBufferItem: TMenuItem;
    FormPreviewItem: TMenuItem;
    ListPreviewItem: TMenuItem;
    FormPrintItem: TMenuItem;
    ListPrintItem: TMenuItem;
    N5: TMenuItem;
    PrintToFileItem: TMenuItem;
    PrintListToFileItem: TMenuItem;
    PrintFormToFileItem: TMenuItem;
    GuideItem: TMenuItem;
    HelpBreaker: TMenuItem;
    FileBreaker3: TMenuItem;
    ExportBaseItem: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure QuitItemClick(Sender: TObject);
    procedure ContentsItemClick(Sender: TObject);
    procedure TopicItemClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure PrintSetupItemClick(Sender: TObject);
    procedure TileItemClick(Sender: TObject);
    procedure CascadeItemClick(Sender: TObject);
    procedure AboutItemClick(Sender: TObject);
    procedure MinimizeItemClick(Sender: TObject);
    procedure NormalizeItemClick(Sender: TObject);
    procedure ArrangeItemClick(Sender: TObject);
    procedure SetupItemClick(Sender: TObject);
    procedure CloseAllItemClick(Sender: TObject);
    procedure StatusBarHint(Sender: TObject);
    procedure StatusBarMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure StatusBarMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure StatusBarMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormShow(Sender: TObject);
    procedure UpdateItemClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure SetBufferItemClick(Sender: TObject);
    procedure FormPreviewItemClick(Sender: TObject);
    procedure FormPrintItemClick(Sender: TObject);
    procedure ListPrintItemClick(Sender: TObject);
    procedure PrintFormToFileItemClick(Sender: TObject);
    procedure PrintListToFileItemClick(Sender: TObject);
    procedure GuideItemClick(Sender: TObject);
    procedure ExportBaseItemClick(Sender: TObject);
  private
    DLLs: TList;
    FShowPrintDialog: Boolean;
    FTextPrint: Boolean;
    {procedure ActiveChanged; override;}
    procedure WMRebuildToolbar(var Message: TMessage); message WM_REBUILDTOOLBAR;
    procedure WMUserAutorization(var Message: TMessage); message WM_USERAUTORIZATION;
    procedure WMMakeUpdate(var Message: TMessage); message WM_MAKEUPDATE;
    procedure WMShowHint(var Message: TMessage); message WM_SHOWHINT;
    {procedure WMChar(var Message: TWMChar); message WM_CHAR;}
  protected
    procedure ShowUser;
    procedure PrintDocument(DestCode: Byte);
    {function IsWorkedMenuItem(AItem: TMenuItem): Boolean;}
    function MakeItemList(AItem: TMenuItem): Boolean;
    procedure CheckDataBaseForm;
    {procedure ActivateApp(Sender: TObject);}
  public
    Manager: TGraphPrimManager;
    PrintDBGrid: TPrintDBGrid;
    property TextPrint: Boolean read FTextPrint;
    procedure LoadDLLs;
    procedure FreeDLLs;
    procedure ShowHint(S: string);
    procedure ShowInfo(S: string);
    procedure InitProgressBar(AMin, AMax: Integer);
    procedure HideProgressBar;
    {procedure RebuildToolbar;}
  end;

var
  MainForm: TMainForm;

implementation

uses
  PreviewFrm, Printers, AboutFrm, SclLogoFrm, SetupFrm, {CryDrv, Sign,}
    GetPassDialog, Btrieve, WinSpool, TextPrint;

{$R *.DFM}

const
  EnterTitle: PChar = 'Вход в Банк-клиент';

var
  GkPassword: string;
  Step: Integer;
const
  UserInited: Boolean = False;
  CheckDiskette: Boolean = True;

function LocGkPassword: string;
begin
  Result := GkPassword;
end;

function ChooseUser: Integer;
{const
  KeyPath: array[0..127] of Char = 'A:\'#0'keypath (128 bites)';}
var
  UserRec: TUserRec;
  F: TextFile;
  FN, S, MP, MP0, NO0, OP0, KeyPath, TransPath: string;
  K, PC, Step: Integer;
  GuestEnter: Boolean;
  CryptoEngine: Integer;
begin
  GuestEnter := False;
  FN := '';
  K := 0;
  CryptoEngine := ceiTcbGost;
  KeyPath := 'A:';
  TransPath := KeyDir;
  while K<ParamCount do
  begin
    Inc(K);
    S := Trim(ParamStr(K));
    if Length(S)>0 then
    begin
      if ((S[1]='-') or (S[1]='/')) and (Length(S)>1) then
      begin
        case UpCase(S[2]) of
          'K':
            KeyPath := Trim(Copy(S, 4, Length(S)-3));
          'P':
            FN := Trim(Copy(S, 4, Length(S)-3));
          'G':
            GuestEnter := True;
          'T':
            TransPath := Trim(Copy(S, 4, Length(S)-3));
          'S':
            begin
              if Trim(Copy(S, 4, 1))='1' then
                CryptoEngine := ceiTcbGost
              else
                CryptoEngine := ceiDomenK;
            end;
        end;
      end
      else
        case K of
          1:
            if UpperCase(Copy(S, 1, 4))='KEY:' then
              KeyPath := Trim(Copy(S, 5, Length(S)-4))
            else
              FN := S;
          2:
            if Length(FN)=0 then
              FN := S;
        end;
    end;
  end;
  Step := ID_RETRY;
  if GuestEnter then
    Step := IDIGNORE
  else begin
    S := UpperCase(Copy(KeyPath, 1, 2));
    if Step<>ID_ABORT then
    begin
      Step := ID_RETRY;
      if (S='A:') or (S='B:') then
      begin
        S := S+'\';
        if GetDriveType(PChar(S))=DRIVE_REMOVABLE then
        begin
          while Step=ID_RETRY do
          begin
            if GetVolumeLabel(S, MP) then
            begin
              Step := ID_IGNORE;
              {if UpperCase(Trim(Lab))=ReserveLabel then
              begin
                MakeKeyTask(TempDir, Disket, '??', 0, Step);
                KillDir(TempDir);
              end}
            end
            else begin
              Step := Application.MessageBox(
                PChar('Вставьте ключевую дискету в устройство '
                +Copy(S, 1, 2)), EnterTitle,
                MB_ABORTRETRYIGNORE or MB_ICONINFORMATION or MB_DEFBUTTON2);
            end;
          end;
          if Step<>ID_ABORT then
            Step := ID_RETRY;
        end;
      end;
    end;

    MP := ManualStr;
    MP0 := ManualStr;
    NO0 := ManualStr;
    OP0 := ManualStr;
    PC := 0;
    if Length(FN)>0 then
    begin
      AssignFile(F, FN);
      FileMode := 0;
      {$I-} Reset(F); {$I+}
      if IOResult=0 then
      begin
        while not Eof(F) do
        begin
          ReadLn(F, S);
          case PC of
            0:
              MP := S;
            1:
              MP0 := S;
            2:
              NO0 := S;
            3:
              OP0 := S;
          end;
          Inc(PC);
        end;
        CloseFile(F);
      end;
    end;

    if Step<>ID_ABORT then
    begin
      NormalizeDir(KeyPath);
      NormalizeDir(TransPath);
      FN := KeyPath+#13#10+TransPath;
      S := MP;
      //MessageBox(0, PChar('['+S+'] 333 '+IntToStr(CryptoEngine)), '', MB_OK or MB_ICONERROR);
      Step := InitCryptoEngine(ceiDomenK, FN, S, CryptoEngine=ceiDomenK);
      {if (Step<>ID_IGNORE) and (Step<>ID_ABORT) then
      begin
        NormalizeDir(KeyPath);
        NormalizeDir(TransPath);
        FN := KeyPath+#13#10+TransPath;
        S := MP0+#13#10+NO0+#13#10+OP0;
        Step := InitCryptoEngine(ceiTcbGost, FN, S, CryptoEngine=ceiTcbGost);
      end;}
      if (Step<>ID_ABORT) and CheckDiskette then
      begin
        S := UpperCase(Copy(KeyPath, 1, 2));
        if (S='A:') or (S='B:') then
        begin
          S := S+'\';
          if GetDriveType(PChar(S))=DRIVE_REMOVABLE then
          begin
            while GetVolumeLabel(S, FN) and
              (Application.MessageBox('Уберите ключевую дискету из дисковода',
                EnterTitle, MB_OKCANCEL or MB_ICONINFORMATION)=ID_OK)
              do;
          end;
        end;
      end;
    end;
  end;
  Result := Step;
  if (Step=IDOK) or (Step=IDIGNORE) then
  begin
    if Step=IDIGNORE then
    begin
      SetUserNumber(255);
      if CurrentUser(UserRec) then
        SetFirmNumber(UserRec.urFirmNumber)
      else
        SetFirmNumber(-1);
      if not GuestEnter then
      begin
        Application.MessageBox('Подпись не инициализирована.'+#13
          +'Вы не сможете подписывать документы'#13#10'и проводить сеанс связи', EnterTitle,
          MB_OK or MB_ICONWARNING);
        Application.ProcessMessages;
      end;
    end
    else begin
      SetUserNumber({GetOperNum}1);
      if CurrentUser(UserRec) then
        SetFirmNumber(UserRec.urFirmNumber);
    end;
    UserInited := True;
  end;

  if (Step<>IDOK) and (Step<>IDIGNORE) then
    ExitProcess(0);
(*var
  UserRec: TNewUserRec;
  F: TextFile;
  FN, S, BaseKeyPath: string;
  K, PC: Integer;
  P: PassFunction;
  GuestEnter: Boolean;
begin
  GuestEnter := False;
  BaseKeyPath := AppDir + 'Key/';
  FN := '';
  K := 0;
  while K<ParamCount do
  begin
    Inc(K);
    S := Trim(ParamStr(K));
    if Length(S)>0 then
    begin
      if ((S[1]='-') or (S[1]='/')) and (Length(S)>1) then
      begin
        case UpCase(S[2]) of
          'B':
            BaseKeyPath := Trim(Copy(S, 4, Length(S)-3));
          'K':
            StrPLCopy(KeyPath, Trim(Copy(S, 4, Length(S)-3)), SizeOf(KeyPath));
          'P':
            FN := Trim(Copy(S, 4, Length(S)-3));
          'G':
            GuestEnter := True;
        end;
      end
      else
        case K of
          1:
            if UpperCase(Copy(S, 1, 4))='KEY:' then
              StrPLCopy(KeyPath, Copy(S, 5, Length(S)-4), SizeOf(KeyPath))
            else
              FN := S;
          2:
            if Length(FN)=0 then
              FN := S;
        end;
    end;
  end;
  if GuestEnter then
    Step := IDIGNORE
  else begin
    PC := 0;
    if Length(FN)>0 then
    begin
      AssignFile(F, FN);
      FileMode := 0;
      {$I-} Reset(F); {$I+}
      if IOResult=0 then
      begin
        while not Eof(F) do
        begin
          ReadLn(F, S);
          case PC of
            0:
              GkPassword := S;
            1:
              try
                Oper := StrToInt(S);
              except
                Oper := 0;
              end;
            2:
              Pwd := S;
          end;
          Inc(PC);
        end;
        CloseFile(F);
      end;
    end;

    if (StrLen(KeyPath)<SizeOf(KeyPath)) and (KeyPath[StrLen(KeyPath)-1]<>'\') then
      StrCat(KeyPath, '\');

    Step := IDRETRY;
    while Step=IDRETRY do
    begin
      if ReadUz(StrPas(@KeyPath)+'uz.db3') then
        Step := IDOK
      else
        Step := Application.MessageBox('Ошибка узла защиты.'+#13
          +'Вставьте ключевую дискету', EnterTitle,
          MB_ABORTRETRYIGNORE or MB_ICONERROR or MB_DEFBUTTON2);
    end;

    if Step=IDOK then
      Step := IDRETRY;
    while Step=IDRETRY do
    begin
      if PC>0 then
        P := LocGkPassword
      else
        P := GetGkPassword;
      if ReadGk(StrPas(@KeyPath)+'gk.db3', P) then
      begin
        Step := IDOK;
        if PC<=0 then
          Application.ProcessMessages;
      end
      else
        Step := Application.MessageBox('Ошибка главного ключа', EnterTitle,
          MB_ABORTRETRYIGNORE or MB_ICONERROR or MB_DEFBUTTON2);
    end;

    if (Step=IDOK) and not InitRandom(StrPas(@KeyPath)+'random.key') then
    begin
      if Application.MessageBox('Ошибка инициализации ГСЧ'+#13
        +'Хотите продолжить?', EnterTitle, MB_YESNOCANCEL or MB_ICONERROR) = IDYES
      then
        Step := IDIGNORE
      else
        Step := IDABORT
    end;

    if (Step=IDOK) and not ReadKey(StrPas(@KeyPath)+'obmen.key', AuthKey, 2) then
    begin
      if Application.MessageBox('Ошибка инициализации КО'+#13
        +'Хотите продолжить?', EnterTitle, MB_YESNOCANCEL or MB_ICONERROR) = IDYES
      then
        Step := IDIGNORE
      else
        Step := IDABORT
    end;

    if Step=IDOK then
      Step := IDRETRY;
    while Step=IDRETRY do
    begin
      if (PC>2) or GetOperPassword(Oper, Pwd) then
      begin
        if PC<=2 then
          Application.ProcessMessages;
        if InitSign(Oper, BaseKeyPath, Pwd)=0 then
          Step := IDOK
        else
          Step := Application.MessageBox('Ошибка инициализации подписи',
            EnterTitle, MB_ABORTRETRYIGNORE or MB_ICONERROR or MB_DEFBUTTON2);
      end
      else
        Step := Application.MessageBox('Отказ оператора', EnterTitle,
          MB_ABORTRETRYIGNORE or MB_ICONERROR);
    end;
  end;
  Result := Step;
  if (Step=IDOK) or (Step=IDIGNORE) then
  begin
    if Step=IDIGNORE then
    begin
      SetUserNumber(255);
      if CurrentUser(UserRec) then
        SetFirmNumber(UserRec.urFirmNumber)
      else
        SetFirmNumber(255);
      if not GuestEnter then
      begin
        Application.MessageBox('Несанкционированный вход!'+#13
          +'Вам будут недоступны некоторые функции', EnterTitle,
          MB_OK or MB_ICONWARNING);
        Application.ProcessMessages;
      end;
    end
    else begin
      SetUserNumber(GetOperNum);
      if CurrentUser(UserRec) then
        SetFirmNumber(UserRec.urFirmNumber);
    end;
    UserInited := True;
  end;

  if (Step<>IDOK) and (Step<>IDIGNORE) then
    ExitProcess(0);*)
end;

procedure TMainForm.ShowUser;
var
  User: TUserRec;
  T: array[0..255] of Char;
begin
  CurrentUser(User);
  if not GetRegParamByName('SenderAcc', GetUserNumber, T) then
    T := '';
  StatusBar.Panels[FirmPanelIndex].Text := T;
  StatusBar.Panels[NamePanelIndex].Text := User.urInfo;
  UpdateItem.Visible := User.urLevel=0;
  SetBufferItem.Visible := UpdateItem.Visible;
end;

const
  Initing: Boolean = False;

procedure TMainForm.WMUserAutorization(var Message: TMessage);
begin
  inherited;
  if not UserInited then
  begin
    if not Initing then
    begin
      Initing := True;
      try
        ChooseUser;
        ShowUser;
      finally
        Initing := False;
      end;
    end;
  end;
end;

{procedure TMainForm.ActivateApp(Sender: TObject);
begin
  SendMessage(Handle, WM_USERAUTORIZATION, 0, 0);
end;}

var
  TextPort0, TextPort1,
    PrinterCommands0, PrinterCommands1, T: array[0..511] of Char;
  TextLeftMarg: Integer = 0;
  FormFeed: Boolean = True;
  PrintDocByUser: Boolean = True;

procedure TMainForm.FormCreate(Sender: TObject);
const
  MesTitle: PChar = 'Инициализация';
var
  QuorumDir, DictDir, DataDir: string;
  Opened, All: Integer;
  ProtoLevel, ShowProtoMes: Integer;
  User: TUserRec;
  SbTrans: Boolean;
  Mes: string;
begin
  ScaleLogoForm := TScaleLogoForm.Create(Application);
  with ScaleLogoForm do
  begin
    SetLimits(0, 6);
    SetPos(0);
    FirstShow;
  end;
  ShortDateFormat := 'dd.mm.yyyy';
  DateSeparator := '.';
  Application.HelpFile := HelpDir
    +ChangeFileExt(ExtractFileName(Application.ExeName), '.hlp');
  DLLs := TList.Create;
  Manager := TGraphPrimManager.Create(Self);
  PrintDBGrid := TPrintDBGrid.Create(Self);
  ProgressBar.Parent := StatusBar;
  try
    SendRunMessage('Открытие основных баз');
    InitBasicBase(False, False);
  except
    MessageBox(Handle, 'Ошибка открытия основных баз', MesTitle,
      MB_OK or MB_ICONERROR);
  end;
    {DecodeMask('$(Key)'}

  SendRunMessage('Загрузка модулей СКЗИ');
  Mes := '';
  LoadItscLib(Mes);
  if Length(Mes)>0 then
    MessageBox(Handle, PChar(Mes), 'Инициализация СКЗИ "Демен-К"',
      MB_OK or MB_ICONERROR);

  //MessageBox(Handle, '111', MesTitle, MB_OK or MB_ICONERROR);

  SendRunMessage('Инициализация ключей');
  {ActivateApp(Self);}
  SendMessage(Handle, WM_USERAUTORIZATION, 0, 0);

  if not GetRegParamByName('PrintDocByUser', GetUserNumber, PrintDocByUser) then
    PrintDocByUser := True;
  if not GetRegParamByName('ProtoLevel', GetUserNumber, ProtoLevel) then
    ProtoLevel := 3;
  if not GetRegParamByName('ShowProtoMes', GetUserNumber, ShowProtoMes) then
    ShowProtoMes := 2;
  SetProtoParams(ProtoLevel, ShowProtoMes, DecodeMask('$(ProtoFile)', 5, GetUserNumber));
  ProtoMes(plInfo, PChar(Caption), '===Начало протоколирования===');
  if not GetRegParamByName('SbTrans', GetUserNumber, SbTrans) then
    SbTrans := False;
  try
    SendRunMessage('Открытие баз пользователя');
    CurrentUser(User);
    InitBasicBase(True, SbTrans);
  except
    MessageBox(Handle, 'Ошибка открытия баз пользователя', MesTitle,
      MB_OK or MB_ICONERROR);
  end;
  //Добавлено Меркуловым
  if not GetRegParamByName('OrBaseConn',GetUserNumber,OraBase.OrBaseConn) then
    OraBase.OrBaseConn := False;
  if OraBase.OrBaseConn then
  begin
    if not GetRegParamByName('OrServerName',GetUserNumber, T) then
      T := 'ORATEST';
    OraBase.OrServerName := T;
    if not GetRegParamByName('OrLogin',GetUserNumber, T) then
      T := 'QRM_ADMIN4';
    OraBase.OrLogin := T;
    if not GetRegParamByName('OrPass',GetUserNumber, T) then
      T := 'QRM_ADMIN4';
    OraBase.OrPass := T;
    if not GetRegParamByName('OrScheme',GetUserNumber, T) then
      T := 'TEST_PERM';
    OraBase.OrScheme := T;
    SendRunMessage('Открытие баз Oracle');
    //Добавлено Меркуловым
    OBaseOpen;
    OraInit;
    GetOrOpenedBases(Opened,All);
    if Opened<All then
      MessageBox(Handle, PChar('Открылось только '+IntToStr(Opened)
        +' баз Кворума из '+IntToStr(All)+'.Ошибка открытия баз Кворум.'),
         MesTitle, MB_OK or MB_ICONERROR);
  end;
  (*else begin
  //конец
    SendRunMessage('Открытие баз Кворума');
    QuorumDir := DecodeMask('$(QuorumDir)', 5, GetUserNumber);
    if Length(QuorumDir)>0 then
    begin
      DictDir := DecodeMask('$(QuorumDictDir)', 5, GetUserNumber);
      DataDir := DecodeMask('$(QuorumDataDir)', 5, GetUserNumber);
      try
        InitQuorumBase(QuorumDir, DictDir, DataDir);
        GetQrmOpenedBases(Opened, All);
        if Opened<All then
          MessageBox(Handle, PChar('Открылось только '+IntToStr(Opened)
            +' баз Кворума из '+IntToStr(All)), MesTitle, MB_OK or MB_ICONERROR);
      except
        MessageBox(Handle, 'Ошибка открытия баз Кворум', MesTitle,
          MB_OK or MB_ICONERROR);
      end;
    end;
  end;                                                      //Добавлено Меркуловым*)
  UpdateItemClick(nil);
  SetBufferItemClick(nil);
  try
    SendRunMessage('Подключение модулей');
    LoadDLLs;
  except
    MessageBox(Handle, 'Ошибка подключения модулей', MesTitle,
      MB_OK or MB_ICONERROR);
  end;
  if not GetRegParamByName('ShowPrintDialog', GetUserNumber, FShowPrintDialog) then
    FShowPrintDialog := True;
  if not GetRegParamByName('TextPrint', GetUserNumber, FTextPrint) then
    FTextPrint := False;
  if not GetRegParamByName('PrnPortPath', GetUserNumber, TextPort0) then
    TextPort0 := 'LPT1';
  if not GetRegParamByName('PrinterCommands', GetUserNumber, PrinterCommands0) then
    PrinterCommands0 := '';
  if not GetRegParamByName('TextLeftMarg', GetUserNumber, TextLeftMarg) then
    TextLeftMarg := 0;
  if not GetRegParamByName('FormFeed', GetUserNumber, FormFeed) then
    FormFeed := False;
  if not GetRegParamByName('PrintFilePath', GetUserNumber, TextPort1) then
    TextPort1 := 'prnfile.txt';
  if not GetRegParamByName('PrintFileCommands', GetUserNumber, PrinterCommands1) then
    PrinterCommands1 := 'empty.cfg';
  ScaleLogoForm.Free;
  {Application.OnActivate := ActivateApp;}
end;

function TruncFileExt(FileName: TFileName): TFileName;
var
  I: Integer;
begin
  Result := FileName;
  I := Length(Result);
  while (I>0) and (Result[I]<>'.')
    and (Result[I]<>'\') and (Result[I]<>':') do Dec(I);
  if (I>0) and (Result[I]='.') then
    Result := Copy(Result,1,I-1);
end;

type
  NewMenuItem = function(AOwner: TComponent): TMenuItem;

procedure AddItem(ParentItem, AItem: TMenuItem);
var
  I: Integer;
begin
  with ParentItem do
  begin
    I := 0;
    while (I<Count) and (AItem.GroupIndex>=Items[I].GroupIndex) do
      Inc(I);
    Insert(I, AItem);
  end;
end;

function TestBankSign(P: Pointer; Len: Integer; Node: word): Boolean;
var
  NF, NT, NO: Word;
  Res: Integer;
begin
  NT := 0;
  NF := 0;
  NO := 0;
  {Res := TestSign(P, Len, NF, NO, NT);}
  Result := {((Res=$10) or (Res=$110)) and (NF=Node)}False
end;

function TestDLLSign(FileName: TFileName; Sign: PChar; ReceiverNode: Integer): Boolean;
var
  F: file;
  Buf: PChar;
  Size, ActSize: Integer;
begin
  AssignFile(F, FileName);
  FileMode := 0;
  {$I-} Reset(F, 1); {$I-}
  Result := IOResult=0;
  if Result then
  begin
    Size := FileSize(F);
    Buf := AllocMem(Size+SignSize);
    try
      BlockRead(F, Buf^, Size, ActSize);
      CloseFile(F);
      Result := Size = ActSize;
      if Result then
      begin
        Move(Sign^, Buf[Size], SignSize);
        Result := TestBankSign(Buf, Size+SignSize, ReceiverNode);
      end;
    finally
      FreeMem(Buf);
    end;
  end;
end;

procedure TMainForm.LoadDLLs;
const
  MesTitle: PChar = 'Загрузка рабочих модулей';
var
  DLLModule: HModule;
  P: Pointer;
  //SearchRec: TSearchRec;
  Len, Res: Integer;
  DLLName: array[0..525] of Char;
  MI: TMenuItem;
  ModuleDataSet: TExtBtrDataSet;
  ModuleRec: TModuleRec;
  Key: packed record
    kKind: Byte;
    kIder: Integer;
  end;
  ReceiverNode: Integer;
begin
  ModuleDataSet := GlobalBase(biModule);
  if ModuleDataSet<>nil then
  begin
    if not GetRegParamByName('ReceiverNode', GetUserNumber, ReceiverNode) then
      ReceiverNode := 1;
    with Key do
    begin
      kKind := mkAutoExec;
      kIder := 0;
    end;
    Len := SizeOf(ModuleRec);
    Res := ModuleDataSet.BtrBase.GetGE(ModuleRec, Len, Key, 0);
    while Res=0 do
    begin
      if (ModuleRec.mrKind=mkAutoExec)
        and (LevelIsSanctioned(ModuleRec.mrLevel) {or (GetOperNum=1)}) then
      begin
        StrPLCopy(DLLName, ModuleRec.mrName, SizeOf(ModuleRec.mrName));
        StrPLCopy(DLLName, ModuleDir+StrPas(DLLName)+'.dll', SizeOf(DLLName)-1);
        {if (GetOperNum=1) or TestDLLSign(DLLName+'.dll', @ModuleRec.mrSign,
          ReceiverNode) then
        begin}
        DLLModule := LoadLibrary(DLLName);
        if DLLModule=0 then
          MessageBox(Handle, PChar('Ошибка открытия '+DLLName+' ('
            +IntToStr(GetLastError)+')'), MesTitle, MB_OK + MB_ICONERROR)
        else begin
          P := GetProcAddress(DLLModule, NewMenuItemDLLProcName);
          if P=nil then
          begin
            FreeLibrary(DLLModule);
            MessageBox(Handle, PChar('В DLL '+DLLName+' нет процедуры инициализации '
              +NewMenuItemDLLProcName), 'Загрузка рабочих модулей',
              MB_OK + MB_ICONERROR)
          end
          else begin
            DLLs.Add(Pointer(DLLModule));
            MI := NewMenuItem(P)(Self);
            if MI.GroupIndex<3 then
              AddItem(FileItem, MI)
            else
              ServiceItem.Add(MI);
          end;
        end;
      end;
      Len := SizeOf(ModuleRec);
      Res := ModuleDataSet.BtrBase.GetGT(ModuleRec, Len, Key, 0);
    end;
    //FindClose(SearchRec);
  end
  else
    MessageBox(Handle, 'Не удалось открыть список модулей',
      MesTitle, MB_OK + MB_ICONERROR)
end;

procedure TMainForm.FreeDLLs;
var
  I: Integer;
  P: Pointer;
begin
  for I:=1 to DLLs.Count do
  begin
    P := DLLs.Items[I-1];
    FreeLibrary(HINST(P));
  end;
  DLLs.Clear;
end;

procedure TMainForm.QuitItemClick(Sender: TObject);
begin
  Close
end;

procedure TMainForm.ContentsItemClick(Sender: TObject);
begin
  Application.HelpCommand(HELP_FINDER, 0);
end;

procedure TMainForm.TopicItemClick(Sender: TObject);
const
  T: Char = #0;
begin
  Application.HelpCommand(HELP_KEY, Integer(@T));
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  FreeItscLib;
  //DoneBasicBase;
  //DoneQuorumBase;
  FreeDLLs;
  //messagebox(0, '1', 'aaa', 0);
  DLLs.Free;
  //messagebox(0, '1', 'aaa', 0);
  ProtoMes(plInfo, PChar(Caption), 'Протоколирование завершено');
  //messagebox(0, '1', 'aaa', 0);
  CloseProto;
  CloseRegistr;
end;

(*function TMainForm.IsWorkedMenuItem(AItem: TMenuItem): Boolean;
var
  I: Integer;
begin
  Result:=Assigned(AItem.OnClick){ or (AItem.Caption='-')};
  for I:=1 to AItem.Count do
    Result:=IsWorkedMenuItem(AItem.Items[I-1]) or Result;
  if AItem.Enabled<>Result then AItem.Enabled:=Result;
{  if AItem.Visible<>Result then AItem.Visible:=Result;}
end;*)

(*const
  MenuIsChanged: Boolean = False;

procedure TMainForm.MainMenuChange(Sender: TObject; Source: TMenuItem;
  Rebuild: Boolean);
begin
  if not MenuIsChanged then
  begin
    MenuIsChanged := True;
    try
      ToolBar.Repaint;
{      with ToolBar do
        for I:=1 to ControlCount do
          if Controls[I-1] is TToolButton then
          begin
            B := Controls[I-1] as TToolButton;
            if B.MenuItem<>nil then B.Enabled := B.MenuItem.Enabled;
          end;}
    finally
      MenuIsChanged:=False
    end;
  end;
{  PostMessage(Handle, WM_REBUILDTOOLBAR, 0, 0);}
end;*)

procedure TMainForm.PrintSetupItemClick(Sender: TObject);
begin
  PrinterSetupDialog.Execute;
end;

const
  MMPerInch = 25.4;

procedure TMainForm.PrintDocument(DestCode: Byte);
const
  MesTitle: PChar = 'Печать';
var
  {TabOb: TObject;
  Gr1: TDBGrid;}
  FN{1, FN2, FN3, FN4}: TFileName;
  WorkArea: TRect;
  I, K, DPI_X, DPI_Y, Page, BeginPage, Num, N, LastYCoord, TotalPageCount, LI, dN: Integer;
  Limits: TRect;
  Marg: TPoint;
  TextPrintManager: TTextPrintManager;
  TextPort, PrinterCommands: PChar;
  SetupIsLoaded: Boolean;
  ActiveChild: TForm;
  PrintDocRec: TPrintDocRec;
  PtrPrintDocRec: PPrintDocRec;
  FormList: TList;
  APageOrientation: TPageOrientation;

  procedure GetPrinterConsts;
  begin
    DPI_X := GetDeviceCaps(Printer.Handle, LOGPIXELSX);
    DPI_Y := GetDeviceCaps(Printer.Handle, LOGPIXELSY);
    GlobScale.X := DPI_X/MMPerInch;
    GlobScale.Y := DPI_Y/MMPerInch;
    with WorkArea do
    begin
      Left := GetDeviceCaps(Printer.Handle, PHYSICALOFFSETX);
      Top := GetDeviceCaps(Printer.Handle, PHYSICALOFFSETY);
      Right := Left + GetDeviceCaps(Printer.Handle, HORZRES);
      Bottom := Top + GetDeviceCaps(Printer.Handle, VERTRES);
    end;
  end;

var
  DoneUserList: TList;
  S: string;
begin
  DoneUserList := nil;
  ActiveChild := ActiveMDIChild;
  if ActiveChild<>nil then
  try
    APageOrientation := {pgoDefault}pgoPortrait;
    if ActiveChild is TDataBaseForm then
    begin
      PrintDocRec.CassCopy := 0;                 //Добавлено Меркуловым
      repeat                                     //Добавлено Меркуловым
      with PrintDialog do
      begin
        FromPage := 1;
        ToPage := 1;
        MaxPage := 1;
      end;
      with ActiveChild as TDataBaseForm do
      begin
        case DestCode of
          2,5,7:
            begin
              TakeFormPrintData(PrintDocRec, FormList);
              PrintDialog.HelpContext := 60;
            end;
          3,6,8:
            begin
              TakeTabPrintData(PrintDocRec, FormList);
              PrintDialog.HelpContext := 65;
            end;
        end;
      end;
      if PrintDocByUser and (DestCode in [2,5,7])
        and (PrintDocRec.DBGrid.DataSource.DataSet<>nil)
        and (PrintDocRec.DBGrid.DataSource.DataSet is TPayDataSet)
        and (PrintDocRec.DBGrid.SelectedRows.Count>1)
      then
        DoneUserList := TList.Create;
      if not GetRegParamByName('LeftMarg', GetUserNumber, LeftMargin) then
        LeftMargin := 20;
      if not GetRegParamByName('TopMarg', GetUserNumber, TopMargin) then
        TopMargin := 20;
      case DestCode of
        2:                   {гр. печать формы}
        begin
          ShowInfo('Подготовка к печати документов...');
          GetPrinterConsts;
          with Printer.Canvas do
          begin
            Page := PrintDocRec.DBGrid.SelectedRows.Count;
            if Page>0 then
              PrintDialog.MaxPage := Page
            else
              PrintDialog.MaxPage := 1;
            PrintDialog.FromPage := 1;
            PrintDialog.ToPage := PrintDialog.MaxPage;
            if not FShowPrintDialog or PrintDialog.Execute then
            begin
              if not FShowPrintDialog or (PrintDialog.PrintRange<>prPageNums) then
              begin
                PrintDialog.FromPage := 1;
                PrintDialog.ToPage := PrintDialog.MaxPage;
              end;
              Num := PrintDialog.ToPage-PrintDialog.FromPage+1;
              N := 0;
              if not RotatePage then
              begin
                Printer.Title := Application.Title + ' - ['
                  + ActiveChild.Caption + ']';
                Printer.BeginDoc;
              end;
              for Page := PrintDialog.FromPage to PrintDialog.ToPage do
              begin
                ShowInfo('Отправка документа '+IntToStr(Page)+' из '
                  +IntToStr(Num)+'...');
                if (PrintDocRec.DBGrid.SelectedRows.Count>0) and (Page>0)
                  and (Page<=PrintDocRec.DBGrid.SelectedRows.Count)
                then
                  PrintDocRec.DBGrid.DataSource.DataSet.Bookmark :=
                    PrintDocRec.DBGrid.SelectedRows.Items[Page-1];
                (ActiveChild as TDataBaseForm).TakeFormPrintData(PrintDocRec, FormList);
                FN := PatternDir + PrintDocRec.GraphForm;
                if Manager.InitForm(FN, PrintDocRec.DBGrid.DataSource.DataSet) then
                begin
                  APageOrientation := FormPageOrientation;
                  if RotatePage then
                  begin
                    if (Printer.Orientation=poPortrait) and (APageOrientation=pgoLandscape) or
                     (Printer.Orientation=poLandscape) and (APageOrientation=pgoPortrait) then
                    begin
                      case APageOrientation of
                        pgoPortrait:
                          Printer.Orientation := poPortrait;
                        pgoLandscape:
                          Printer.Orientation := poLandscape;
                      end;
                      GetPrinterConsts;
                    end;
                    Printer.Title := Application.Title + ' - ['
                      + ActiveChild.Caption + ']';
                    Printer.BeginDoc;
                  end;
                  with Pen do
                  begin
                    Mode := pmCopy;
                    Color := clBlack;
                    Style := psSolid;
                  end;
                  with Brush do
                  begin
                    Style := bsSolid;
                    Color := clWhite;
                  end;
                  FillRect(Rect(0, 0, Width, Height));
                  with Manager do
                  begin
                    Marg := VirtToView(Point(LeftMargin, TopMargin));
                    LogPen.lopnWidth := Point(3,0); {0.3 мм}
                    Draw(Printer.Handle, GlobScale.X, GlobScale.Y,
                      Point(Marg.X-WorkArea.Left, Marg.Y-WorkArea.Top));
                  end;
                  if RotatePage then
                    Printer.EndDoc
                  else begin
                    if Page < PrintDialog.ToPage then
                      Printer.NewPage;
                  end;
                  Inc(N);
                end;
              end;
              if not RotatePage then
                Printer.EndDoc;
              ShowInfo('Отправлено на печать документов: '+IntToStr(N));
              if N<Num then
                MessageBox(Handle, PChar('Не удалось отправить на печать документов: '
                  +IntToStr(Num-N)), MesTitle, MB_OK or MB_ICONWARNING);
            end
            else
              ShowInfo('');
          end;
        end;
        3:                  {гр. печать таблицы}
        begin
          with Printer.Canvas do
          begin
            ShowInfo('Подготовка к печати списка...');
            GetPrinterConsts;
            with PrintDBGrid do
            begin
              PrintDialog.FromPage := 1;
              SetupIsLoaded := False;
              if FormList=nil then
              begin
                DBGrid := PrintDocRec.DBGrid;
                {Limits := GetLimits;
                SheetWidth := Limits.Right;
                SheetHeight := Limits.Bottom;}
                SetupFileName := PatternDir + PrintDocRec.GraphForm;
                if LoadSetup then
                begin
                  APageOrientation := PageOrientation;
                  if RotatePage and
                    ((Printer.Orientation=poPortrait) and (APageOrientation=pgoLandscape) or
                    (Printer.Orientation=poLandscape) and (APageOrientation=pgoPortrait))
                  then begin
                    case APageOrientation of
                      pgoPortrait:
                        Printer.Orientation := poPortrait;
                      pgoLandscape:
                        Printer.Orientation := poLandscape;
                    end;
                    GetPrinterConsts;
                  end;
                  SheetWidth := GetDeviceCaps(Printer.Handle, HORZSIZE);
                  SheetHeight := GetDeviceCaps(Printer.Handle, VERTSIZE);
                  YCoord := 0;
                  DevideArea;
                  PrintDialog.MaxPage := PageCount;
                  SetupIsLoaded := True;
                  SetVarior('PageCount', IntToStr(PageCount));
                end;
              end
              else begin
                LastYCoord := 0;
                TotalPageCount := 1;
                for LI := 0 to FormList.Count-1 do
                begin
                  PtrPrintDocRec := FormList.Items[LI];
                  if PtrPrintDocRec<>nil then
                  begin
                    DBGrid := PtrPrintDocRec^.DBGrid;
                    SetupFileName := PatternDir + PtrPrintDocRec^.GraphForm;
                    if LoadSetup then
                    begin
                      if LI=0 then
                      begin
                        APageOrientation := PageOrientation;
                        if RotatePage and
                          ((Printer.Orientation=poPortrait) and (APageOrientation=pgoLandscape) or
                          (Printer.Orientation=poLandscape) and (APageOrientation=pgoPortrait))
                        then begin
                          case APageOrientation of
                            pgoPortrait:
                              Printer.Orientation := poPortrait;
                            pgoLandscape:
                              Printer.Orientation := poLandscape;
                          end;
                          GetPrinterConsts;
                        end;
                        SheetWidth := GetDeviceCaps(Printer.Handle, HORZSIZE);
                        SheetHeight := GetDeviceCaps(Printer.Handle, VERTSIZE);
                      end;
                      YCoord := LastYCoord;
                      DevideArea;
                      if (LI=0) or (DBGrid.DataSource.DataSet.RecordCount>0) then
                      begin
                        LastYCoord := LastGridBottom;
                        TotalPageCount := TotalPageCount + PageCount - 1;
                        if SkipPage>0 then
                          Inc(TotalPageCount);
                      end;
                      SetupIsLoaded := True;
                    end
                    else
                      ShowInfo('Не удалось прочитать шаблон списка2 '+SetupFileName);
                  end;
                end;
                PrintDialog.MaxPage := TotalPageCount;
                SetVarior('PageCount', IntToStr(TotalPageCount));
              end;
              if SetupIsLoaded then
              begin
                PrintDialog.ToPage := PrintDialog.MaxPage;
                if not FShowPrintDialog or PrintDialog.Execute then
                begin
                  if not FShowPrintDialog or (PrintDialog.PrintRange<>prPageNums) then
                  begin
                    PrintDialog.FromPage := 1;
                    PrintDialog.ToPage := PrintDialog.MaxPage;
                  end;
                  Num := PrintDialog.ToPage-PrintDialog.FromPage+1;
                  Printer.Title := Application.Title + ' - ['
                    + ActiveChild.Caption + ']';
                  Printer.BeginDoc;
                  N := 0;
                  for Page := PrintDialog.FromPage to PrintDialog.ToPage do
                  begin
                    ShowInfo('Отправка страницы '+IntToStr(Page)+' из '
                      +IntToStr(Num)+'...');
                    with Pen do
                    begin
                      Mode := pmCopy;
                      Color := clBlack;
                      Style := psSolid;
                    end;
                    with Brush do
                    begin
                      Style := bsSolid;
                      Color := clWhite;
                    end;
                    FillRect(Rect(0, 0, Width, Height));
                    Marg := VirtToView(Point(LeftMargin, TopMargin));
                    SetVarior('PageNumber', IntToStr(Page));
                    if FormList=nil then
                      Draw(Printer.Handle, GlobScale.X, GlobScale.Y,
                        Point(Marg.X-WorkArea.Left, Marg.Y-WorkArea.Top), Page)
                    else begin
                      LastYCoord := 0;
                      TotalPageCount := 1;
                      for LI := 0 to FormList.Count-1 do
                      begin
                        PtrPrintDocRec := FormList.Items[LI];
                        if PtrPrintDocRec<>nil then
                        begin
                          DBGrid := PtrPrintDocRec^.DBGrid;
                          SetupFileName := PatternDir + PtrPrintDocRec^.GraphForm;
                          if LoadSetup then
                          begin
                            YCoord := LastYCoord;
                            DevideArea;
                            if (LI=0) or (DBGrid.DataSource.DataSet.RecordCount>0) then
                            begin
                              LastYCoord := LastGridBottom;
                              TotalPageCount := TotalPageCount + PageCount - 1;
                              if SkipPage>0 then
                                Inc(TotalPageCount);
                              if (TotalPageCount-PageCount<Page)
                                and (Page<=TotalPageCount) then
                              begin
                                DBGrid.Hide;
                                Draw(Printer.Handle, GlobScale.X, GlobScale.Y,
                                  Point(Marg.X-WorkArea.Left, Marg.Y-WorkArea.Top),
                                  Page-(TotalPageCount-PageCount));
                                DBGrid.Show;
                              end;
                            end;
                          end;
                        end;
                      end;
                    end;
                    if Page < PrintDialog.ToPage then
                      Printer.NewPage;
                    Inc(N);
                  end;
                  Printer.EndDoc;
                  ShowInfo('Отправлено страниц на печать: '+IntToStr(N));
                end
                else
                  ShowInfo('');
              end
              else begin
                Printer.Abort;
                ShowInfo('Не удалось прочитать шаблон списка');
              end;
            end;
          end;
        end;
        5, 6, 7, 8:        {форма/табл - текстовая печать}
        if (DestCode=5) and (Length(PrintDocRec.TextForm)>0)
          or (DestCode=6) and (Length(PrintDocRec.TextForm)>0) then
        begin
          try
            TextPrintManager := TTextPrintManager.Create(Self);
            try
              if (DestCode=7) or (DestCode=8) then
              begin
                TextPort := @TextPort1;
                PrinterCommands := @PrinterCommands1;
              end
              else begin
                TextPort := @TextPort0;
                PrinterCommands := @PrinterCommands0;
              end;
              with TextPrintManager do
              begin
                FN := PatternDir + PrinterCommands;
                if LoadCommands(FN) then
                begin
                  ShowInfo('Инициальзация порта...');
                  if InitPort(TextPort, False) then
                  begin
                    ShowInfo('Отправка на печать...');
                    case DestCode of
                      5, 7:
                      begin
                        Num := PrintDocRec.DBGrid.SelectedRows.Count;
                        if Num<=0 then
                          Num := 1;
                        N := 0;
                        BeginPage := 1;
                        repeat
                          I := -1;
                          S := '';
                          if DoneUserList<>nil then
                          begin
                            PrintDocRec.DBGrid.DataSource.DataSet.Bookmark :=
                              PrintDocRec.DBGrid.SelectedRows.Items[BeginPage-1];
                            I := Abs(PBankPayRec(PrintDocRec.DBGrid.DataSource.DataSet.ActiveBuffer)^.dbUserCode);
                            S := ' на пользователя ['+IntToStr(I)+']';
                            if DoneUserList.IndexOf(Pointer(I))<0 then
                              DoneUserList.Add(Pointer(I));
                          end;
                          K := -1;
                          for Page := BeginPage to Num do
                          begin
                            if (PrintDocRec.DBGrid.SelectedRows.Count>0) and (Page>0)
                              and (Page<=PrintDocRec.DBGrid.SelectedRows.Count)
                            then
                              PrintDocRec.DBGrid.DataSource.DataSet.Bookmark :=
                                PrintDocRec.DBGrid.SelectedRows.Items[Page-1];
                            if DoneUserList<>nil then
                              K := Abs(PBankPayRec(PrintDocRec.DBGrid.DataSource.DataSet.ActiveBuffer)^.dbUserCode);
                            if (K=-1) or (K=I) then
                            begin
                              ShowInfo('Печатаю документ '+IntToStr(Page)+' из '
                                +IntToStr(Num)+S);
                              (ActiveChild as TDataBaseForm).TakeFormPrintData(PrintDocRec, FormList);
                              FN := PatternDir + PrintDocRec.TextForm;
                              if PrintForm(FN, PrintDocRec.DBGrid.DataSource.DataSet,
                                TextLeftMarg, FormFeed and (Page<=Num))
                              then
                                Inc(N)
                              else
                                MessageBox(Handle, PChar('Ошибка печати формы ['
                                  +FN+']'), MesTitle, MB_OK or MB_ICONERROR);
                            end;
                          end;
                          if DoneUserList<>nil then
                          begin
                            if BeginPage=Num then
                              Inc(BeginPage)
                            else begin
                              BeginPage := 1;
                              repeat
                                Inc(BeginPage);
                                PrintDocRec.DBGrid.DataSource.DataSet.Bookmark :=
                                  PrintDocRec.DBGrid.SelectedRows.Items[BeginPage-1];
                                I := Abs(PBankPayRec(PrintDocRec.DBGrid.DataSource.DataSet.ActiveBuffer)^.dbUserCode);
                                K := DoneUserList.IndexOf(Pointer(I));
                              until (BeginPage>=Num) or (K<0);
                              if K<0 then
                                DoneUserList.Add(Pointer(I))
                              else
                                Inc(BeginPage);
                            end;
                          end;
                        until (DoneUserList=nil) or (BeginPage>Num);
                        S := '';
                        if DoneUserList<>nil then
                          S := '; по исполнителям: '+IntToStr(DoneUserList.Count);
                        ShowInfo('Напечатано документов: '+IntToStr(N)+S);
                        if N<Num then
                        begin
                          MessageBox(Handle, PChar('Не удалось распечатать документов: '
                            +IntToStr(Num-N)), MesTitle, MB_OK or MB_ICONERROR);
                        end;
                      end;
                      6, 8:
                      begin
                        FN := PatternDir + PrintDocRec.TextForm;
                        if PrintForm(FN, PrintDocRec.DBGrid.DataSource.DataSet,
                          TextLeftMarg, False)
                        then
                          ShowInfo('Список отправлен на печать')
                        else begin
                          MessageBox(Handle, PChar('Ошибка печати списка ['
                            +FN+']'), MesTitle, MB_OK or MB_ICONERROR);
                          ShowInfo('Ошибка печати списка');
                        end;
                      end;  
                    end;
                  end
                  else begin    
                    MessageBox(Handle, PChar('Ошибка инициализации порта ['  
                      +TextPort+']'), MesTitle, MB_OK or MB_ICONERROR);
                    ShowInfo('Ошибка инициализации порта');
                  end;  
                end
                else begin
                  MessageBox(Handle, PChar('Ошибка загрузки команд из ['
                    +FN+']'), MesTitle, MB_OK or MB_ICONERROR);
                  ShowInfo('Ошибка загрузки команд принтера');
                end;
              end;
            except
              ShowInfo('Ошибка текстовой печати');
              MessageBox(Handle, 'Ошибка текстовой печати', MesTitle,
                MB_OK or MB_ICONERROR);
            end;
          finally
            TextPrintManager.Free;
          end
        end;
        (*7, 8:        {форма/табл - печать в файл}
        if (DestCode=7) and (Length(PrintDocRec.TextForm)>0)
          or (DestCode=8) and (Length(PrintDocRec.TextForm)>0) then
        begin ?
          TextPrintManager := TTextPrintManager.Create(Self);
          try
            try
              with TextPrintManager do
              begin
                FN := PatternDir + PrinterCommands;
                ShowInfo('Загрузка команд...');
                LoadCommands(FN);
                ShowInfo('Инициализация приемника...');
                if InitPort(@APort, True) then
                begin
                  ShowInfo('Отправка на печать...');
                  case DestCode of
                    7:
                      begin
                        Num := PrintDocRec.DBGrid.SelectedRows.Count;
                        if Num<=0 then
                          Num := 1;
                        N := 0;
                        for Page := 1 to Num do
                        begin
                          ShowInfo('Печатаю документ '+IntToStr(Page)+' из '
                            +IntToStr(Num));
                          if (PrintDocRec.DBGrid.SelectedRows.Count>0) and (Page>0)
                            and (Page<=PrintDocRec.DBGrid.SelectedRows.Count)
                          then
                            PrintDocRec.DBGrid.DataSource.DataSet.Bookmark :=
                              PrintDocRec.DBGrid.SelectedRows.Items[Page-1];
                          (ActiveChild as TDataBaseForm).TakeFormPrintData(PrintDocRec, FormList);
                          FN := PatternDir + PrintDocRec.TextForm;
                          if PrintForm(FN, PrintDocRec.DBGrid.DataSource.DataSet,
                            TextLeftMarg, False)
                          then
                            Inc(N)
                          else
                            MessageBox(Handle, PChar('Ошибка печати формы ['
                              +FN+']'), MesTitle, MB_OK or MB_ICONERROR);
                        end;
                        ShowInfo('Напечатано '+IntToStr(N)+' документов в файл '+APort);
                        if N<Num then
                        begin
                          MessageBox(Handle, PChar('Не удалось распечатать документов: '
                            +IntToStr(Num-N)), MesTitle, MB_OK or MB_ICONERROR);
                        end;
                      end;
                    8:
                      begin
                        FN := PatternDir + PrintDocRec.TextForm;
                        if PrintForm(FN, PrintDocRec.DBGrid.DataSource.DataSet, TextLeftMarg,
                          False)
                        then
                          ShowInfo('Список напечатан в файл '+APort)
                        else begin
                          MessageBox(Handle, PChar('Ошибка печати списка ['
                            +FN+']'), MesTitle, MB_OK or MB_ICONERROR);
                          ShowInfo('Ошибка печати списка');
                        end;
                      end;
                  end
                end
                else begin
                  MessageBox(Handle, PChar('Ошибка записи в ['+APort+']'),
                    MesTitle, MB_OK or MB_ICONERROR);
                  ShowInfo('Ошибка записи');
                end;
                {Write(#12);}
              end;
            except
              ShowInfo('Ошибка печати в файл');
              MessageBox(Handle, 'Ошибка печати в файл', MesTitle,
                MB_OK or MB_ICONERROR);
            end;
          finally
            TextPrintManager.Free;
          end;
        end;*)
      end;
      if (PrintDocRec.CassCopy>0) then
        Dec(PrintDocRec.CassCopy);
      until (PrintDocRec.CassCopy=0);       //Добавлено Меркуловым
    end
    else
      MessageBox(Handle, PChar('Печать из этого окна не предусмотрена'),
        MesTitle, MB_OK or MB_ICONWARNING);
  finally
    if DoneUserList<>nil then
      DoneUserList.Free;
  end
  else
    MessageBox(Handle, 'Нет активного окна', MesTitle,
      MB_OK or MB_ICONWARNING);
end;

procedure TMainForm.FormPreviewItemClick(Sender: TObject);
const
  MesTitle: PChar = 'Предпросмотр';
var
  ActiveChild: TForm;
begin
  if TextPrint then
    MessageBox(Handle, 'Нет просмотра при текстовой печати', MesTitle,
      MB_OK or MB_ICONINFORMATION)
  else begin
    ActiveChild := ActiveMDIChild;
    if ActiveChild<>nil then
    begin
      if ActiveChild is TDataBaseForm then
      begin
        if not GetRegParamByName('LeftMarg', CommonUserNumber, LeftMargin) then
          LeftMargin := 20;
        if not GetRegParamByName('TopMarg', CommonUserNumber, TopMargin) then
          TopMargin := 20;
        PrevImageList := ImageList;
        PrevManager := Manager;
        PrevPrintDBGrid := PrintDBGrid;
        if PreviewForm=nil then
        begin
          PreviewForm := TPreviewForm.Create(Self);
          PreviewForm.SetToolBtnIndexes(36,26, 40,41,42,43, 4,3, 44,45,46);
        end;
        PostMessage(PreviewForm.Handle, WM_SIZE, 0, 0);
        with PreviewForm do
        begin
          DataBaseForm := ActiveChild as TDataBaseForm;
          if (Sender as TComponent).Tag=0 then   {просмотр формы}
            ShowMode := 0
          else                    {просмотр таблицы}
            ShowMode := 1;
          ShowModal;
        end
      end
      else
        MessageBox(Handle, 'Печать из этого окна не предусмотрена',
          MesTitle, MB_OK or MB_ICONWARNING);
    end;
  end;
end;

procedure TMainForm.FormPrintItemClick(Sender: TObject);
begin
  if TextPrint then
    PrintDocument(5)
  else
    PrintDocument(2);
end;

procedure TMainForm.ListPrintItemClick(Sender: TObject);
begin
  if TextPrint then
    PrintDocument(6)
  else
    PrintDocument(3);
end;

procedure TMainForm.PrintFormToFileItemClick(Sender: TObject);
begin
  PrintDocument(7)
end;

procedure TMainForm.PrintListToFileItemClick(Sender: TObject);
begin
  PrintDocument(8)
end;

procedure TMainForm.TileItemClick(Sender: TObject);
begin
  TileMode := tbHorizontal;
  Tile;
end;

procedure TMainForm.MinimizeItemClick(Sender: TObject);
var
  I: Integer;
begin
  for I := MDIChildCount downto 1 do
    MDIChildren[I-1].WindowState := wsMinimized;
end;

procedure TMainForm.ArrangeItemClick(Sender: TObject);
begin
  ArrangeIcons;
end;

procedure TMainForm.NormalizeItemClick(Sender: TObject);
var
  I: Integer;
begin
  for I := 1 to MDIChildCount do
    MDIChildren[I-1].WindowState := wsNormal;
end;

procedure TMainForm.CascadeItemClick(Sender: TObject);
begin
  Cascade;
end;

procedure TMainForm.AboutItemClick(Sender: TObject);
begin
  Application.CreateForm(TAboutForm, AboutForm);
  with AboutForm do
  begin
    ShowModal;
    Free;
  end;
end;

var
  ItemList: TList;

function TMainForm.MakeItemList(AItem: TMenuItem): Boolean;
var
  I: Integer;
begin
  if (AItem.Count>0) and (AItem.ImageIndex<0) then
  begin
    Result := False;
    for I:=1 to AItem.Count do
      Result := MakeItemList(AItem.Items[I-1]) or Result;
    if Result and ((ItemList.Count=0)
      or (ItemList.Items[ItemList.Count-1]<>nil)) then
        ItemList.Add(nil);
  end
  else begin
    Result := AItem.ImageIndex>=0;
    if Result then
      ItemList.Add(AItem);
  end;
end;

const
  ToolbarIsChanged: Boolean = False;

procedure TMainForm.WMRebuildToolbar(var Message: TMessage);
var
  B: TToolButton;
  MI: TMenuItem;
  I, J: Integer;
  S: string;
begin
  if not ToolbarIsChanged then
  begin
    ToolbarIsChanged := True;
    try
      inherited;
      CheckDataBaseForm;
      if (ToolBar<>nil) and ToolBar.Visible then
      begin
        while ToolBar.ControlCount>0 do
          ToolBar.Controls[0].Free;
        ItemList := TList.Create;
        try
          MakeItemList(Menu.Items);  {добавим команды главного меню}
          if (ActiveMDIChild<>nil) and (ActiveMDIChild.Menu<>nil)
            and (ActiveMDIChild.Menu.Items<>nil) then
              MakeItemList(ActiveMDIChild.Menu.Items); {добавим команды дочернего меню}
          with ItemList do
            for I := Count-1 downto 0 do
            begin
              MI := Items[I];
              if MI<>nil then
              begin
                B := TToolButton.Create(Application);
                with B do
                begin
                  MenuItem := MI;
                  S := MI.Caption;
                  J := Pos('&', S);
                  if J>0 then
                    System.Delete(S, J, 1);
                  J := Pos('...', S);
                  if J>0 then
                    System.Delete(S, J, 3);
                  Hint := S+'|'+MI.Hint;
                  ShowHint := True;
                end;
                B.Parent := ToolBar;
              end
              else
                if (I>0) and (I<Count-1) and (Items[I+1]<>nil) then
                begin
                  B := TToolButton.Create(Application);
                  with B do
                  begin
                    Width := 4;
                    Style := tbsSeparator;
                  end;
                  B.Parent := ToolBar;
                end;
            end;
        finally
          ItemList.Free;
        end;
      end;
    finally
      ToolbarIsChanged := False;
    end;
  end;
end;

procedure TMainForm.CloseAllItemClick(Sender: TObject);
var
  I: Integer;
begin
  I := MDIChildCount;
  while I>0 do
  begin
    Dec(I);
    MDIChildren[I].Close;
  end;
end;

procedure TMainForm.SetupItemClick(Sender: TObject);
begin
  if SetupForm=nil then
  begin
    Application.CreateForm(TSetupForm, SetupForm);
    with SetupForm do
    begin
      ShowModal;
      Free;
    end;
  end
  else
    SetupForm.ShowModal;
end;

procedure TMainForm.ShowHint(S: string);
begin
  with StatusBar do
  begin
    SimplePanel := Length(S)>0;
    if SimplePanel then
      SimpleText := S;
  end;
end;

procedure TMainForm.ShowInfo(S: string);
begin
  StatusBar.Panels[InfoPanelIndex].Text := S;
end;

procedure TMainForm.StatusBarHint(Sender: TObject);
begin
  ShowHint(GetLongHint(Application.Hint));
end;

const
  CurPanelIndex: Integer = 0;
  PanelResising: Boolean = False;

procedure TMainForm.StatusBarMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
const
  EdgeCatch = 2;
var
  UnderSplit: Boolean;
  I, EdgePos: Integer;
begin
  with StatusBar do
  begin
    EdgePos := BorderWidth;
    if PanelResising then
    begin
      if CurPanelIndex<Panels.Count then
      begin
        for I:=0 to CurPanelIndex-1 do
          EdgePos := EdgePos + Panels.Items[I].Width;
        I := X - EdgePos;
        if (I>5) and (X<Width-BorderWidth-20) then
          Panels.Items[CurPanelIndex].Width := I;
      end
    end
    else begin
      UnderSplit := False;
      if not ProgressBar.Visible then
      begin
        CurPanelIndex := 0;
        while (CurPanelIndex<Panels.Count-1) and not UnderSplit do
        begin
          EdgePos := EdgePos + Panels.Items[CurPanelIndex].Width;
          UnderSplit := Abs(X-EdgePos)<EdgeCatch;
          Inc(CurPanelIndex);
        end;
      end;
      if UnderSplit then
        Cursor := crHSplit
      else
        Cursor := crDefault;
    end;
  end;
end;

procedure TMainForm.StatusBarMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  PanelResising := StatusBar.Cursor = crHSplit;
  if PanelResising then Dec(CurPanelIndex);
end;

procedure TMainForm.StatusBarMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  with StatusBar do
  begin
    if PanelResising then
    begin
      Cursor := crDefault;
      PanelResising := False;
    end;
  end;
end;

procedure TMainForm.InitProgressBar(AMin, AMax: Integer);
const
  Border=2;
var
  I, X: Integer;
begin
  StatusBar.Panels[ProgressPanelIndex].Width := ProgressBar.Width+Border;
  with ProgressBar do
  begin
    X := Border;
    for I:=0 to ProgressPanelIndex-1 do
      X := X+StatusBar.Panels[I].Width;
    SetBounds(X, Border, Width, StatusBar.Height - Border);
    Min := AMin;
    Max := AMax;
    Show;
  end;
end;

procedure TMainForm.HideProgressBar;
begin
  ProgressBar.Hide;
  StatusBar.Panels[ProgressPanelIndex].Width := 0;
end;

procedure TMainForm.CheckDataBaseForm;
var
  NoForm: Boolean;
  PrintDocRec, PrintDocRecL: TPrintDocRec;
  FormList, FormListL: TList;
begin
  NoForm := (ActiveMDIChild=nil) or not (ActiveMDIChild is TDataBaseForm);
  if not NoForm then
  begin
    try
      with ActiveMDIChild as TDataBaseForm do
      begin
        TakeFormPrintData(PrintDocRec, FormList);
        TakeTabPrintData(PrintDocRecL, FormListL);
      end;
      NoForm :=
        ((FormList=nil) and ((PrintDocRec.DBGrid=nil)
        or (PrintDocRec.DBGrid.DataSource=nil) or (PrintDocRec.DBGrid.DataSource.DataSet=nil)))
        and
        ((FormListL=nil) and ((PrintDocRecL.DBGrid=nil)
        or (PrintDocRecL.DBGrid.DataSource=nil) or (PrintDocRecL.DBGrid.DataSource.DataSet=nil)));
      if not NoForm then
      begin
        PrintFormToFileItem.Enabled := (FormList<>nil) or (Length(PrintDocRec.TextForm)>0); {Т-Ф}
        PrintListToFileItem.Enabled := (FormListL<>nil) or (Length(PrintDocRecL.TextForm)>0); {Т-С}
        ExportBaseItem.Enabled := True;
        if TextPrint then
        begin
          FormPrintItem.Enabled := PrintFormToFileItem.Enabled;
          FormPreviewItem.Enabled := False;
          ListPrintItem.Enabled := PrintListToFileItem.Enabled;
          ListPreviewItem.Enabled := False;
        end
        else begin
          FormPrintItem.Enabled := (FormList<>nil) or (Length(PrintDocRec.GraphForm)>0);
          FormPreviewItem.Enabled := FormPrintItem.Enabled;
          ListPrintItem.Enabled := (FormListL<>nil) or (Length(PrintDocRecL.GraphForm)>0);
          ListPreviewItem.Enabled := ListPrintItem.Enabled;
        end;
      end;
    except
      NoForm := True;
    end;
  end;
  if NoForm then
  begin
    FormPrintItem.Enabled := False;
    FormPreviewItem.Enabled := False;
    ListPrintItem.Enabled := False;
    ListPreviewItem.Enabled := False;
    PrintFormToFileItem.Enabled := False;
    PrintListToFileItem.Enabled := False;
    ExportBaseItem.Enabled := False;
  end;
(*  if SmartIcons then
  begin
    PI := -1;
    FI := -1;
    LI := -1;
    if FormPreviewItem.Enabled and ListPreviewItem.Enabled then
      PI := 9
    else
    if FormPreviewItem.Enabled then
      FI := 9
    else
    if ListPreviewItem.Enabled then
      LI := 9;
    if (PreviewItem.ImageIndex<>PI) or (FormPreviewItem.ImageIndex<>FI) or
      (ListPreviewItem.ImageIndex<>LI) then
    begin
      PreviewItem.ImageIndex := PI;
      FormPreviewItem.ImageIndex := FI;
      ListPreviewItem.ImageIndex := LI;
    end;
    PI := -1;
    FI := -1;
    LI := -1;
    if FormPrintItem.Enabled and ListPrintItem.Enabled then
      PI := 8
    else
    if FormPrintItem.Enabled then
      FI := 8
    else
    if ListPrintItem.Enabled then
      LI := 8;
    if (PrintItem.ImageIndex<>PI) or (FormPrintItem.ImageIndex<>FI) or
      (ListPrintItem.ImageIndex<>LI) then
    begin
      PrintItem.ImageIndex := PI;
      FormPrintItem.ImageIndex := FI;
      ListPrintItem.ImageIndex := LI;
    end;
  end;
var
  NoForm: Boolean;
  Gr1, Gr2: TDBGrid;
  FN1, FN2, FN3, FN4: TFileName;
begin
  NoForm := (ActiveMDIChild=nil) or not (ActiveMDIChild is TDataBaseForm);
  if not NoForm then
  begin
    try
      with ActiveMDIChild as TDataBaseForm do
      begin
        TakeFormPrintData(PrintDocRec, FormList);
        TakeTabPrintData(PrintDocRecL, FormListL);
      end;
      NoForm := ((Gr1=nil) or (Gr1.DataSource=nil) or (Gr1.DataSource.DataSet=nil))
        and ((Gr2=nil) or (Gr2.DataSource=nil) or (Gr2.DataSource.DataSet=nil));
      if not NoForm then
      begin
        PrintFormToFileItem.Enabled := Length(FN2)>0; {Т-Ф}
        PrintListToFileItem.Enabled := Length(FN4)>0; {Т-С}
        ExportBaseItem.Enabled := True;
        if TextPrint then
        begin
          FormPrintItem.Enabled := PrintFormToFileItem.Enabled;
          FormPreviewItem.Enabled := False;
          ListPrintItem.Enabled := PrintListToFileItem.Enabled;
          ListPreviewItem.Enabled := False;
        end
        else begin
          FormPrintItem.Enabled := Length(FN1)>0;
          FormPreviewItem.Enabled := FormPrintItem.Enabled;
          ListPrintItem.Enabled := Length(FN3)>0;
          ListPreviewItem.Enabled := ListPrintItem.Enabled;
        end;
      end;
    except
      NoForm := True;
    end;
  end;
  if NoForm then
  begin
    FormPrintItem.Enabled := False;
    FormPreviewItem.Enabled := False;
    ListPrintItem.Enabled := False;
    ListPreviewItem.Enabled := False;
    PrintFormToFileItem.Enabled := False;
    PrintListToFileItem.Enabled := False;
    ExportBaseItem.Enabled := False;
  end; *)
end;

procedure TMainForm.FormShow(Sender: TObject);
var
  ShowToolBar: Boolean;
begin
  ShowUser;
  if not GetRegParamByName('ShowToolBar', GetUserNumber, ShowToolBar) then
    ShowToolBar := True;
  ToolBar.Visible := ShowToolBar;
  if not GetRegParamByName('FlatToolBar', GetUserNumber, ShowToolBar) then
    ShowToolBar := True;
  ToolBar.Flat := ShowToolBar;
  if ShowToolBar then
    ToolBar.Height := 27
  else
    ToolBar.Height := 30;
  ShowInfo('');
  PostMessage(Handle, WM_REBUILDTOOLBAR, 0, 0);
end;

{procedure TMainForm.WMChar(var Message: TWMChar);
var
  Key: Char;
const
  I: Byte = 1;
  S: string = 'logo';
begin
  with Message do
    Key := Char(CharCode);
      showmessage(Key);
  if S[I] = Key then
  begin
    Inc(I);
    if I>Length(S) then
    begin
      LogoItemClick(nil);
          showmessage('aaa');
      I := 1;
    end;
  end
  else
    I := 1;
  inherited;
end;}

procedure TMainForm.UpdateItemClick(Sender: TObject);
const
  MesTitle: PChar = 'Обновление';
var
  si: TStartupInfo;
  pi: TProcessInformation;
  CmdLine: array[0..1023] of Char;
  ModuleDataSet: TBtrDataSet;
  ModuleBase: TBtrBase;
  ModuleRec: TModuleRec;
  Key: packed record
    kKind: Byte;
    kIder: Integer;
  end;
  Len, Res: Integer;
  F: file;
begin
  AssignFile(F, ChangeFileExt(Application.ExeName, '.upd'));
  FileMode := 0;
  {$I-} Reset(F); {$I+}
  if IOResult=0 then
  begin
    CloseFile(F);
    Erase(F);
  end
  else begin
    {$I-} Rewrite(F); {$I+}
    if IOResult=0 then
    begin
      ModuleDataSet := GlobalBase(biModule);
      ModuleBase := TBtrBase.Create;
      try
        ModuleBase.SetFCB(@ModuleDataSet.FCB);
        with Key do
        begin
          kKind := mkUpdate;
          kIder := 0;
        end;
        Len := SizeOf(ModuleRec);
        Res := ModuleBase.GetGE(ModuleRec, Len, Key, 0);
        if (Res=0) and (Key.kKind=mkUpdate) and ((Sender=nil) or
          (MessageBox(Handle, 'Получены модули обновления. Провести обновление сейчас?',
            MesTitle, MB_YESNOCANCEL or MB_ICONQUESTION) = IDYES)) then
        begin
          FillChar(si, SizeOf(si), #0);
          with si do
          begin
            cb := SizeOf(si);
            dwFlags := STARTF_USESHOWWINDOW;
            wShowWindow := SW_SHOWDEFAULT;
          end;
          StrPLCopy(CmdLine, '"'+ExtractFilePath(Application.ExeName)+'update.exe" '
            +Application.ExeName, SizeOf(CmdLine));
          if CreateProcess(nil, CmdLine, nil, nil, FALSE,
            {CREATE_NEW_CONSOLE}DETACHED_PROCESS, nil, nil, si, pi)
          then
            ExitProcess(0)
          else
            MessageBox(Handle, PChar('Не удалось запустить модуль обновления'
              +#13#10+CmdLine), MesTitle, MB_OK or MB_ICONERROR);
        end;
      finally
        ModuleBase.Free;
      end;
      CloseFile(F);
      Erase(F);
    end;
  end;
end;

procedure TMainForm.WMMakeUpdate(var Message: TMessage);
begin
  UpdateItemClick(Self);
end;

procedure TMainForm.WMShowHint(var Message: TMessage);
var
  P: PChar;
begin
  P := PChar(Message.WParam);
  if P<>nil then
    ShowHint(P);
end;

procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
  CloseAllItemClick(nil);
  Application.ProcessMessages;
  //Добавлено Меркуловым
  if OraBase.OrBaseConn then
    OraDone
  {else
  //Конец
    DoneQuorumBase};
  DoneBasicBase;
end;

procedure RebootSystem;
var
  handle, ph: THandle;
  pid, n: DWORD;
  luid: TLargeInteger;
  priv: TOKEN_PRIVILEGES;
  dummy: PTokenPrivileges;
  ver: TOSVERSIONINFO;
begin
  ver.dwOSVersionInfoSize := Sizeof(ver);
  GetVersionEx(ver);
  if ver.dwPlatformId=VER_PLATFORM_WIN32_NT then
  begin
    pid := GetCurrentProcessId;
    if OpenProcessToken(ph, TOKEN_ADJUST_PRIVILEGES, handle) then
      if LookupPrivilegeValue(nil, 'SeShutdownPrivilege', luid) then
      begin
        priv.PrivilegeCount := 1;
        priv.Privileges[0].Attributes := SE_PRIVILEGE_ENABLED;
        priv.Privileges[0].Luid := luid;
        dummy := nil;
        AdjustTokenPrivileges(handle, false, priv, 0, dummy^, n);
      end;
  end;
  ExitWindowsEx(EWX_REBOOT, 0);
end;

procedure TMainForm.SetBufferItemClick(Sender: TObject);
const
  MesTitle: PChar = 'Установка размера буфера';
  RegPath: PChar = 'Software\Btrieve Technologies\Microkernel Workstation Engine\Version  6.15\Settings';
  RegName: PChar = 'Max Communication Buffer Size';
  ParValue: Integer = 65827;
var
  Reg: TRegistry;
  Seted: Boolean;
begin
  if (Sender=nil) or (MessageBox(Handle, 'Установка параметра производится при смене Windows.'#13#10'Продолжить?',
    MesTitle, MB_YESNOCANCEL or MB_ICONQUESTION) = IDYES) then
  begin
    Seted := False;
    Reg := TRegistry.Create;
    with Reg do
    begin
      try
        RootKey := HKEY_LOCAL_MACHINE;
        if OpenKey(RegPath, True) then
        begin
          try
            if ReadInteger(RegName) >= ParValue then
            begin
              Seted := True;
              if Sender<>nil then
                MessageBox(Handle, 'Параметр уже установлен', MesTitle,
                  MB_OK or MB_ICONINFORMATION)
            end;
          except
            Seted := False;
          end;
          if not Seted then
          begin
            Seted := False;
            try
              WriteInteger(RegName, ParValue);
              Seted := True;
            except
              Seted := False;
            end;
          end
          else
            Seted := False;
          CloseKey;
        end
        else
          if Sender<>nil then
            MessageBox(Handle, PChar('Не удалось открыть параметр ['
              +RegPath+']'), MesTitle, MB_OK or MB_ICONERROR)
      finally
        Free;
      end;
    end;
    if Seted and (MessageBox(Handle,
      PChar('Размер буфера "Communication Buffer" изменен.'
      +#13#10'Возможно это вызвано переустановкой системы.'
      +#13#10'Для вступления изменения в силу следует перезагрузить компьютер.'
      +#13#10'Перезагрузить компьютер сейчас?'), MesTitle,
      MB_YESNOCANCEL or MB_ICONWARNING) = ID_YES)
    then begin
      RebootSystem;
      ExitProcess(0);
    end;
  end;
end;

procedure TMainForm.GuideItemClick(Sender: TObject);
var
  Doc: array[0..1023] of Char;
begin
  StrPLCopy(Doc, ExtractFilePath(Application.ExeName)+'Help\BankFl.doc',
    SizeOf(Doc));
  ShellExecute(Application.Handle, 'open', Doc, nil, nil,
    SW_SHOWMAXIMIZED);
end;

procedure TMainForm.ExportBaseItemClick(Sender: TObject);
const
  MesTitle: PChar = 'Экспорт базы';
var
  ExportBaseForm: TExportBaseForm;
  PrintDocRec: TPrintDocRec;
  FormList: TList;
begin
  if ActiveMDIChild<>nil then
  begin
    if ActiveMDIChild is TDataBaseForm then
    begin
      with ActiveMDIChild as TDataBaseForm do
      begin
        TakeFormPrintData(PrintDocRec, FormList);
        if PrintDocRec.DBGrid=nil then
          TakeTabPrintData(PrintDocRec, FormList);
        ExportBaseForm := TExportBaseForm.Create(Self);
        try
          ExportBaseForm.SourceDBGrid := PrintDocRec.DBGrid;
          ExportBaseForm.ShowModal;
        finally
          ExportBaseForm.Free;
        end;
      end;
    end
    else
      MessageBox(Handle, 'Не табличная фома', MesTitle, MB_OK or MB_ICONWARNING);
  end
  else
    MessageBox(Handle, 'Нет активной формы', MesTitle, MB_OK or MB_ICONWARNING);
end;

end.

