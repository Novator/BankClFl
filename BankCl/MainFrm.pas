unit MainFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ComCtrls, Menus, ToolWin, StdCtrls, GraphPrims, Db, BtrDS, {Sign, }DocFunc,
  DBGrids, Buttons, Placemnt, Utilits, Bases, Common, Registr, PasFrm,
  ImgList, CommCons, Registry, ShellApi, ExportBaseFrm, CrySign, TccItcs,
  RXShell, ExtCtrls;

const
  NamePanelIndex = 0;
  ProgressPanelIndex = 1;
  InfoPanelIndex = 2;

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
    ServiceBreaker: TMenuItem;
    SetupItem: TMenuItem;
    FileBreaker3: TMenuItem;
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
    ProgressBar: TProgressBar;
    MainFormStorage: TFormStorage;
    FormPreviewItem: TMenuItem;
    ListPreviewItem: TMenuItem;
    FormPrintItem: TMenuItem;
    ListPrintItem: TMenuItem;
    FileBreaker2: TMenuItem;
    PrintToFileItem: TMenuItem;
    PrintListToFileItem: TMenuItem;
    PrintFormToFileItem: TMenuItem;
    GuideItem: TMenuItem;
    HelpBreaker: TMenuItem;
    ExportBaseItem: TMenuItem;
    FileBreaker4: TMenuItem;
    OtherHelpItem: TMenuItem;
    VerNumLabel: TLabel;
    CoInstItem: TMenuItem;
    FileBreaker5: TMenuItem;
    UpdateItem: TMenuItem;
    SetBufferItem: TMenuItem;
    RegItcsDllItem: TMenuItem;
    CoInstBreaker1: TMenuItem;
    ExchangeKeyItem: TMenuItem;
    KeyClearItem: TMenuItem;
    ImageList: TImageList;
    FileBreaker6: TMenuItem;
    ReInitKeyItem: TMenuItem;
    VipNetKeyPathItem: TMenuItem;
    OneCBuhItem: TMenuItem;
    FlashStopItem: TMenuItem;
    RxTrayIcon: TRxTrayIcon;
    TrayPopupMenu: TPopupMenu;
    OpenAppItem: TMenuItem;
    BreakerItem1: TMenuItem;
    CloseItem: TMenuItem;
    CommonTimer: TTimer;
    DoMailItem: TMenuItem;
    DelOldAccItem: TMenuItem;
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
    procedure CheckRegParam(Sender: TObject; ParamIndex: Integer;
      AskReboot: Boolean; var NeedRebMes: string);
    procedure SetBufferItemClick(Sender: TObject);
    procedure FormPreviewItemClick(Sender: TObject);
    procedure FormPrintItemClick(Sender: TObject);
    procedure ListPrintItemClick(Sender: TObject);
    procedure PrintFormToFileItemClick(Sender: TObject);
    procedure PrintListToFileItemClick(Sender: TObject);
    procedure GuideItemClick(Sender: TObject);
    procedure ExportBaseItemClick(Sender: TObject);
    procedure RegItcsDllItemClick(Sender: TObject);
    procedure ExchangeKeyItemClick(Sender: TObject);
    procedure KeyClearItemClick(Sender: TObject);
    procedure ReInitKeyItemClick(Sender: TObject);
    procedure VipNetKeyPathItemClick(Sender: TObject);
    procedure OneCBuhItemClick(Sender: TObject);
    procedure FlashStopItemClick(Sender: TObject);
    procedure OpenAppItemClick(Sender: TObject);
    procedure RxTrayIconClick(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure CommonTimerTimer(Sender: TObject);
    procedure DoMailItemClick(Sender: TObject);
    procedure DelOldAccItemClick(Sender: TObject);
  private
    DLLs: TList;
    FShowPrintDialog: Boolean;
    FTextPrint: Boolean;
    FAppVisible: Boolean;
    {procedure ActiveChanged; override;}
    procedure WMRebuildToolbar(var Message: TMessage); message WM_REBUILDTOOLBAR;
    procedure WMUserAutorization(var Message: TMessage); message WM_USERAUTORIZATION;
    procedure WMMakeUpdate(var Message: TMessage); message WM_MAKEUPDATE;
    procedure WMShowHint(var Message: TMessage); message WM_SHOWHINT;
    procedure WMPrintDoc(var Message: TMessage); message WM_PRINTDOC;
    procedure WMPrintTable(var Message: TMessage); message WM_PRINTTABLE;
    procedure WMGetVerNum(var Message: TMessage); message WM_GETVERNUM;
    procedure WMCheckNewLetter(var Message: TMessage); message WM_CHECKNEWLETTER;
    {procedure WMChar(var Message: TWMChar); message WM_CHAR;}
    //procedure CM_Deactivate(var Message: TMessage); message CM_DEACTIVATE;
    procedure WMSysCommand(var Message: TMessage); message WM_SYSCOMMAND;
    //procedure WMCheckAndHideApp(var Message: TMessage); message WM_CHECKANDHIDEAPP;
  protected
    function ChooseUser: Integer;
    procedure ShowUser;
    procedure PrintDocument(DestCode: Byte);
    {function IsWorkedMenuItem(AItem: TMenuItem): Boolean;}
    procedure CheckDataBaseForm;
    {procedure ActivateApp(Sender: TObject);}
    procedure OnAppMes(var Msg: TMsg; var Handled: Boolean);
    //procedure OnDeactivateApp(Sender: TObject);
  public
    Manager: TGraphPrimManager;
    PrintDBGrid: TPrintDBGrid;
    property AppVisible: Boolean read FAppVisible write FAppVisible;
    property TextPrint: Boolean read FTextPrint;
    procedure LoadDLLs(UseVal, UseFileMod, UseExportMod: Boolean);
    procedure FreeDLLs;
    procedure ShowHint(S: string);
    procedure ShowInfo(S: string);
    procedure InitProgressBar(AMin, AMax: Integer);
    procedure HideProgressBar;
    function GetVerNum: LongWord;
    procedure RunMenuItem(ParentItem: TMenuItem; ChildImageIndex, RunParam: Integer);
  end;

function GetVipNetKeyParam(TransPath: string; var UserKod, KeyDir: string): Integer;

var
  MainForm: TMainForm;

implementation

uses
  PreviewFrm, Printers, AboutFrm, SetupFrm,
    Btrieve, WinSpool, TextPrint, LogoFrm, KeyTaskFrm, ChooseUserFrm,
  KeyPathDlg, OneCBuhFrm;

{$R *.DFM}

const
  EnterTitle: PChar = 'Вход в Клиент-банк';
  UserInited: Boolean = False;
var
  KeyPath, KeyPathL, TransPath, PassFn: string;
  GuestEnter, ChooseOper, IgnoreKeyDisk: Boolean;
  UseCryptoEngine, EjectUsbFlash, MailTmrCount, MailTmrDelay, MinimizeTmrCount, MinimizeTmrDelay: Integer;
  KeyUpdDate: Word;
  MasterKeyUpdate: Boolean;                         //Добавлено Меркуловым

const
  MailKey = 'mail.key';

function GetVipNetKeyParam(TransPath: string; var UserKod, KeyDir: string): Integer;
var
  F: TextFile;
  S: string;
  I: Integer;
begin
  Result := -1;
  S := TransPath;
  NormalizeDir(S);
  if FileExists(S+MailKey) then
  begin
    AssignFile(F, S+MailKey);
    FileMode := 0;
    {$I-} Reset(F); {$I+}
    if IOResult=0 then
    begin
      Result := 0;
      UserKod := '';
      KeyDir := '';
      ReadLn(F, S);
      CloseFile(F);
      I := Pos(' ', S);
      if I>0 then
      begin
        UserKod := Trim(Copy(S, 1, I-1));
        Delete(S, 1, I);
        S := Trim(S);
        if Length(S)>0 then
        begin
          //NormalizeDir(S);
          KeyDir := S;
          Result := 1;
        end;
      end;
    end;
  end;
end;

function TMainForm.ChooseUser: Integer;
var
  UserRec: TUserRec;
  UserRecPtr: PUserRec;
  F: TextFile;
  S, S2, S3, MP2, MP, NO, OP, {KeyPathKey, }TransPathL, PassFnL, Disket, Login: string;
  PC, Step, Len, Res, I, OperNum: Integer;
  Lab: string;
  CB: Byte;
  Buf: array[0..SizeOf(TUserLogin)] of Char;
  UserDataSet: TExtBtrDataSet;
  SearchRec: TSearchRec;
  D: Boolean;
  ResCode: DWord;
begin
  KeyPathL := KeyPath;
  //KeyPathKey := KeyPath;  //Переменная для обновления ключей
  TransPathL := TransPath;
  PassFnL := PassFn;
  //showmessage('111');
  if GuestEnter then
    Step := IDIGNORE
  else begin
    KillDir(TempDir);
    Step := ID_RETRY;
    Login := '';
    OperNum := 1;

    if ChooseOper then
    begin
      ChooseUserForm := TChooseUserForm.Create(Self);
      with ChooseUserForm do
      begin
        UserDataSet := GlobalBase(biUser);
        Len := SizeOf(UserRec);
        Res := UserDataSet.BtrBase.GetFirst(UserRec, Len, I, 0);
        while Res=0 do
        begin
          UserRecPtr := nil;
          New(UserRecPtr);
          UserRecPtr^ := UserRec;
          UzerComboBox.Items.AddObject(StrPas(UserRec.urInfo), TObject(UserRecPtr));
          Len := SizeOf(UserRec);
          Res := UserDataSet.BtrBase.GetNext(UserRec, Len, I, 0);
        end;
        Res := ShowModal;
        if Res=mrOk then
        begin
          UserRecPtr := GetCurrentUser;
          if UserRecPtr<>nil then
          begin
            Login := Trim(StrPas(UserRecPtr^.urLogin));
            OperNum := UserRecPtr^.urNumber;
            S := KeyPathDirectoryEdit.Text;
            if Length(S)>0 then
              KeyPathL := S;
            NormalizeDir(TransPathL);
            TransPathL := TransPathL+Login;
            if not DirExists(TransPathL) and (MessageBox(Handle, PChar(
              'Транспортный каталог ['+TransPathL+'] не существует'#13#10
              +'Создать новый?'), EnterTitle, MB_ICONWARNING
              or MB_YESNOCANCEL)=ID_YES)
            then
              CreateDir(TransPathL);
            //showmessage(KeyPathL+#13#10+ TransPathL);
          end;
        end
        else begin
          if Res=mrAbort then
            Step := ID_ABORT
          else
            Step := ID_IGNORE;
        end;
        for I := 0 to UzerComboBox.Items.Count-1 do
          Dispose(Pointer(UzerComboBox.Items.Objects[I]));
        Free;
      end;
    end
    else begin
      GetVipNetKeyParam(TransPathL, S, KeyPathL);
    end;

    if (Step<>ID_IGNORE) and (Step<>ID_ABORT) then
    begin  // инициализация паролей (также из файла)
      MP2 := ManualStr;
      MP := ManualStr;
      NO := ManualStr;
      OP := ManualStr;
      PC := 0;
      if Length(PassFnL)>0 then
      begin
        if Length(ExtractFilePath(PassFnL))=0 then
        begin
          NormalizeDir(KeyPathL);
          PassFnL := KeyPathL+PassFnL;
        end;     //showmessage(PassFn);
        AssignFile(F, PassFnL);
        FileMode := 0;
        {$I-} Reset(F); {$I+}
        if IOResult=0 then
        begin
          while not Eof(F) do
          begin
            ReadLn(F, S);
            if (PC=0) and ((UseCryptoEngine and ceiDomenK)=0) then
              Inc(PC);
            case PC of
              0:
                MP2 := S;
              1:
                MP := S;
              2:
                NO := S;
              3:
                OP := S;
            end;
            Inc(PC);
          end;
          CloseFile(F);
        end;
      end;

      if ((KeyUpdDate=0) or (Date>=BtrDateToDate(KeyUpdDate))) and (not MasterKeyUpdate) then//Изменено Меркуловым
      begin  // поиск sfx-архивов с новыми ключами, их распаковка
        Res := FindFirst(AppDir+'NewKey*.*', faAnyFile, SearchRec);
        if Res=0 then
        begin
          try
            while Res=0 do
            begin
              D := (SearchRec.Attr and faDirectory)>0;
              S := UpperCase(Trim(ChangeFileExt(SearchRec.Name, '')));
              S2 := '';
              if Length(S)>6 then
              begin
                S2 := Copy(S, 8, Length(S)-7);
              end;
              if (Length(S2)=0) or (S2=Login) then
              begin
                if not D then
                begin
                  S := AppDir+SearchRec.Name;
                  if FileExists(S) then
                  begin
                    if RunAndWait(S, SW_SHOWDEFAULT, ResCode) then
                      DeleteFile(S);
                  end;
                end;
                if Login='' then
                  S := AppDir+'NewKey\'
                else
                  S := AppDir+'NewKey_'+Login+'\';
                if DirExists(S) then
                begin
                  S2 := KeyPathL;
                  //S2 := KeyPathKey;                        //Изменено Меркуловым
                  NormalizeDir(S2);
                  S3 := TransPathL;
                  NormalizeDir(S3);
                  if MakeKeyTask(S, S2, S3, 1, Step) then
                    KillDir(S);
                end;
              end;
              Res := FindNext(SearchRec);
              Application.ProcessMessages;
            end;
          finally
            FindClose(SearchRec);
          end;
        end;
      end;

      if (Step<>ID_ABORT)
        and ((UseCryptoEngine and ceiDomenK)>0) then
      begin    {проверим транспортный каталог, если пустой - заполним с ключа}
        S2 := KeyPathL;
        NormalizeDir(S2);
        S3 := TransPathL;
        NormalizeDir(S3);
        if not FileExists(S3+'infotecs.RE') then
          MakeKeyTask(S2, S3, '??', 2, Step);
      end;

      Disket := UpperCase(Copy(KeyPathL, 1, 2));
      if Step<>ID_ABORT then
      begin
        Step := ID_OK;
        if (Disket='A:') or (Disket='B:') then
        begin
          Disket := Disket+'\';
          if GetDriveType(PChar(Disket))=DRIVE_REMOVABLE then
          begin
            repeat
              if GetVolumeLabel(Disket, Lab) then
              begin
                if UpperCase(Trim(Lab))=ReserveLabel then
                begin
                  MakeKeyTask(TempDir, Disket, '??', 0, Step);
                  KillDir(TempDir);
                  if Step=ID_IGNORE then
                    Step := ID_OK;
                end
                else
                  Step := ID_OK;
              end
              else begin
                Step := Application.MessageBox(
                  PChar('Вставьте ключевую дискету в устройство '
                  +Copy(Disket, 1, 2)), EnterTitle,
                  MB_ABORTRETRYIGNORE or MB_ICONINFORMATION or MB_DEFBUTTON2);
                if IgnoreKeyDisk and (Step=ID_IGNORE) then
                  Step := ID_OK;
              end;
            until Step<>ID_RETRY;
          end;
        end;
      end;
    end;
    
    if Step=ID_OK then
    begin
      if (UseCryptoEngine and ceiDomenK)>0 then
      begin
        S2 := KeyPathL+#13#10+TransPathL;
        S := MP2;
        Step := InitCryptoEngine(ceiDomenK, S2, S, True);
      end;
      if Step<>ID_ABORT then
      begin
        if (UseCryptoEngine and ceiTcbGost)>0 then
        begin
          NormalizeDir(KeyPathL);
          NormalizeDir(TransPathL);
          S2 := KeyPathL+#13#10+TransPathL;
          S := MP+#13#10+NO+#13#10+OP;
          Step := InitCryptoEngine(ceiTcbGost, S2, S, not IsCryptoEngineInited);
        end;
      end;
    end;
  end;
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
        Application.MessageBox('Подпись не инициализирована.'#13#10
          +'Вы не сможете подписывать документы и проводить сеанс связи.'
          +#13#10'Также могуть быть недоступны некоторые другие функции', EnterTitle,
          MB_OK or MB_ICONINFORMATION);
        Application.ProcessMessages;
      end;
    end
    else begin
      if ChooseOper then
      begin
        {if GetNode>0 then
          OperNum := GetOperNum
        else} begin
          (*
          Step := IDRETRY;
          K := -1;
          while Step=IDRETRY do
          begin
            if NO=ManualStr then
            begin
              //showmessage('!!! '+no+#13#10+op);
              Step := GetPasswords(Application, 1, 'Ввод пароля оператора',
                ChangeKeyboardLayout, S)
            end
            else begin
              //showmessage(no+#13#10+op);
              Step := IDOK;
              S := NO+#13#10+OP;
              NO := ManualStr;
            end;
            if Step=IDOK then
            begin
              //showmessage('=1');
              Application.ProcessMessages;
              PC := Pos(#13#10, S);
              if PC>0 then
              begin
                //showmessage('=2');
                try
                  K := StrToInt(Copy(S, 1, PC-1));
                  Delete(S, 1, PC+1);
                except
                  K := -1;
                end;
                if GetUserByOperNum(K, UserRec) then
                begin
                  //showmessage('=3');
                  CB := CalcUserRecCRC(UserRec);
                  {Buf[SizeOf(UserRec.urUserPass)] := #0;   !!!!!!!
                  Move(UserRec.urUserPass, Buf, SizeOf(UserRec.urUserPass));
                  EncodeBuf(CB, Buf, SizeOf(UserRec.urUserPass));
                  if StrComp(PChar(S), Buf)=0 then
                  begin
                    //showmessage('=4');
                    S := '';
                    Step := IDOK;
                  end
                  else
                    S := 'Пароль указан неверно';}
                end
                else
                  S := 'Пользователь '+IntToStr(K)+' не найден';
                if Length(S)>0 then
                begin
                  K := -1;
                  Sleep(500);
                  Step := Application.MessageBox(PChar(S+#13#10'Попытаетесь еще раз?'),
                    EnterTitle, MB_ABORTRETRYIGNORE or MB_ICONWARNING or
                    MB_DEFBUTTON2);
                  Application.ProcessMessages;
                end;
              end
              {else
                showmessage('22  '+no+#13#10+op)};
            end
            {else
                showmessage('33  '+no+#13#10+op)};
          end;*)
        end;
      end;
      SetUserNumber(OperNum);
      if CurrentUser(UserRec) then
        SetFirmNumber(UserRec.urFirmNumber);
    end;
    UserInited := True;
  end;
  Result := Step;
  if (Step<>IDOK) and (Step<>IDIGNORE) then
    ExitProcess(0);
end;

procedure TMainForm.ShowUser;
var
  User: TUserRec;
begin
  CurrentUser(User);
  StatusBar.Panels[NamePanelIndex].Text := User.urInfo;
  {UpdateItem.Visible := User.urLevel=0;
  SetBufferItem.Visible := UpdateItem.Visible;}
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
  SmartIcons: Boolean = False;
  ShowTrayIcon: Integer = 0;

procedure TMainForm.FormCreate(Sender: TObject);
var
  ProtoLevel, ShowProtoMes: Integer;
  U, UseVal, UseFileMod, UseExportMod: Boolean;
  S: string;
  K, NumOfSign: Integer;
begin
  FAppVisible := True;
  GuestEnter := False;
  if not GetRegParamByName('ChooseOper', CommonUserNumber, ChooseOper) then
    ChooseOper := False;
  IgnoreKeyDisk := False;
  PassFn := '';
  KeyPath := 'A:';
  TransPath := KeyDir;
  U := False;
  K := 0;
  UseCryptoEngine := -1;
  while K<ParamCount do
  begin
    Inc(K);
    S := Trim(ParamStr(K));
    if Length(S)>0 then
    begin
      if ((S[1]='-') or (S[1]='/')) and (Length(S)>1) then
      begin
        case UpCase(S[2]) of
          'L':
            U := True;
          'K':
            KeyPath := Trim(Copy(S, 4, Length(S)-3));
          'P':
            PassFn := Trim(Copy(S, 4, Length(S)-3));
          'G':
            GuestEnter := True;
          'T':
            TransPath := Trim(Copy(S, 4, Length(S)-3));
          'O':
            ChooseOper := True;
          'A':
            ChooseOper := False;
          'S':
            begin
              S := Trim(Copy(S, 4, 1));
              if S='1' then
                UseCryptoEngine := 1
              else
              if S='2' then
                UseCryptoEngine := 2
              else
              if S='3' then
                UseCryptoEngine := 3
              else
                UseCryptoEngine := 0;
            end;
          'I':
            IgnoreKeyDisk := True;
        end;
      end
      else
        case K of
          1:
            if UpperCase(Copy(S, 1, 4))='KEY:' then
              KeyPath := Trim(Copy(S, 5, Length(S)-4))
            else
              PassFn := S;
          2:
            if Length(PassFn)=0 then
              PassFn := S;
        end;
    end;
  end;
  if not U then
  begin
    LogoForm := TLogoForm.Create(Application);
    LogoForm.FirstShow;
  end;
  if ChooseOper then
  begin
    FileBreaker6.Visible := True;
    ReInitKeyItem.Visible := True;
  end;
  if not GetRegParamByName('NumOfSign', CommonUserNumber, NumOfSign) then
    NumOfSign := 1;
  if (NumOfSign<0) or (NumOfSign>1) then
  begin
    ShowPolySign := True;
  end;
  S := ExtractFilePath(AppDir);
  SetCurrentDirectory(PChar(S));
  ShortDateFormat := 'dd.MM.yyyy';
  DateSeparator := '.';
  Application.HelpFile := HelpDir
    +ChangeFileExt(ExtractFileName(Application.ExeName), '.hlp');

  //Application.OnDeactivate := OnDeactivateApp;
  Application.OnMessage := OnAppMes;

  DLLs := TList.Create;
  Manager := TGraphPrimManager.Create(Self);
  PrintDBGrid := TPrintDBGrid.Create(Self);
  ProgressBar.Parent := StatusBar;
  if not GetRegParamByName('UseVal', CommonUserNumber, UseVal) then
    UseVal := False;
  if not GetRegParamByName('UseFileMod', CommonUserNumber, UseFileMod) then
    UseFileMod := False;
  if not GetRegParamByName('UseExportMod', CommonUserNumber, UseExportMod) then
    UseExportMod := False;
  try
    InitBasicBase(UseVal, UseFileMod);
  except
    MessageBox(Handle, 'Ошибка открытия баз', 'Инициализация баз',
      MB_OK or MB_ICONERROR);
  end;
  if not GetRegParamByName('ProtoLevel', CommonUserNumber, ProtoLevel) then
    ProtoLevel := 3;
  if not GetRegParamByName('ShowProtoMes', CommonUserNumber, ShowProtoMes) then
    ShowProtoMes := 2;
  SetProtoParams(ProtoLevel, ShowProtoMes, DecodeMask('$(ProtoFile)', 5, CommonUserNumber));
  ProtoMes(plInfo, PChar(Caption), '===Начало протоколирования===');
  UpdateItemClick(nil);
  if not GetRegParamByName('SetEngLang', CommonUserNumber, ChangeKeyboardLayout) then
    ChangeKeyboardLayout := False;
  if not GetRegParamByName('KeyUpdDate', CommonUserNumber, KeyUpdDate) then
    KeyUpdDate := StrToBtrDate('18.05.2004');
  //Добалено Меркуловым
  if not GetRegParamByName('MasterKeyUpdate', CommonUserNumber, MasterKeyUpdate) then
    MasterKeyUpdate := False;

  if UseCryptoEngine<0 then
    if not GetRegParamByName('CryptoEngine', CommonUserNumber, UseCryptoEngine) then
      UseCryptoEngine := 2;
  U := (UseCryptoEngine and ceiDomenK)>0;
  S := '';
  CheckRegParam(nil, 0, not U, S);
  if U then
    CheckRegParam(nil, 1, True, S);
  S := '';
  LoadItscLib(S);
  if U and (Length(S)>0) then
    MessageBox(Handle, PChar(S), 'Инициализация СКЗИ "Демен-К"',
      MB_OK or MB_ICONERROR);
  //ActivateApp(Self);
  SendMessage(Handle, WM_USERAUTORIZATION, 0, 0);
  //showmessage(inttostr(getmaincryptoengineindex));
  {LogoForm.Repaint;}
  try
    LoadDLLs(UseVal, UseFileMod, UseExportMod);
  except
    MessageBox(Handle, 'Ошибка подключения модулей', 'Загрузка модулей',
      MB_OK or MB_ICONERROR);
  end;
  if not GetRegParamByName('ShowPrintDialog', CommonUserNumber, FShowPrintDialog) then
    FShowPrintDialog := True;
  if not GetRegParamByName('TextPrint', CommonUserNumber, FTextPrint) then
    FTextPrint := False;
  if not GetRegParamByName('SmartIcons', CommonUserNumber, SmartIcons) then
    SmartIcons := False;
  if not GetRegParamByName('RotatePage', CommonUserNumber, RotatePage) then
    RotatePage := False;

  MailTmrCount := 0;
  MinimizeTmrCount := 0;
  if not GetRegParamByName('ShowTrayIcon', CommonUserNumber, ShowTrayIcon) then
    ShowTrayIcon := 0;        
  if not GetRegParamByName('MinimizeDelay', CommonUserNumber, MinimizeTmrDelay) then
    MinimizeTmrDelay := 0;
  if not GetRegParamByName('MailTmrDelay', CommonUserNumber, MailTmrDelay) then
    MailTmrDelay := 0;
  RxTrayIcon.Icon := Application.Icon;
  RxTrayIcon.Hint := Application.Title;
  if ShowTrayIcon=2 then
    RxTrayIcon.Active := True;
  CommonTimer.Enabled := MinimizeTmrDelay<>0;

  if LogoForm<>nil then
    LogoForm.Free;
  {Application.OnActivate := ActivateApp;}
  {if GetNode>0 then
  begin
    if not GetRegParamByName('LastHddId', LastHddId) then
      LastHddId := 0;
    HID := GetHddPlaceId(BaseDir);
    if LastHddId<>HID then
      MessageBox(Handle, 'ID этого места ни разу не было авторизованно'
        +#13#10'Свяжитесь с банком и сообщите новый ID места',
        'Проверка места', MB_OK or MB_ICONWARNING);
  end;}
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

{function TestBankSign(P: Pointer; Len: Integer; Node: word): Boolean;
var
  NF, NT, NO: Word;
  Res: Integer;
begin
  NT := 0;
  NF := 0;
  NO := 0;
  Res := TestSign(P, Len, NF, NO, NT);
  Result := ((Res=$10) or (Res=$110)) and (NF=Node)
end;}

(*function TestDLLSign(FileName: TFileName; Sign: PChar; ReceiverNode: Integer): Boolean;
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
end; *)

procedure TMainForm.LoadDLLs(UseVal, UseFileMod, UseExportMod: Boolean);
const
  MesTitle: PChar = 'Загрузка рабочих модулей';
var
  DLLModule: HModule;
  P: Pointer;
  {SearchRec: TSearchRec;}
  Len, Res: Integer;
  DLLName: array[0..525] of Char;
  MI: TMenuItem;
  ModuleDataSet: TExtBtrDataSet;
  ModuleRec: TModuleRec;
  Key: packed record
    kKind: Byte;
    kIder: Integer;
  end;
begin
  ModuleDataSet := GlobalBase(biModule);
  if ModuleDataSet<>nil then
  begin
    Len := SizeOf(ModuleRec);
    Res := ModuleDataSet.BtrBase.GetFirst(ModuleRec, Len, Key, 0);
    while Res=0 do
    begin
      if (ModuleRec.mrKind=mkAutoExec)
        and ((ModuleRec.mrIder<>85) or ((UseCryptoEngine and 1)>0))
        and ((ModuleRec.mrIder<>80) or ((UseCryptoEngine and 2)>0))
        and LevelIsSanctioned(ModuleRec.mrLevel)
        and (UseVal or (StrLen(ModuleRec.mrName)=0)
        or (Upcase(ModuleRec.mrName[0])<>'V'))
        and (UseFileMod or (ModuleRec.mrIder<>210))
        and (UseExportMod or (ModuleRec.mrIder<>100)) then
      begin
        StrPLCopy(DLLName, ModuleRec.mrName, SizeOf(ModuleRec.mrName));
        StrPLCopy(DLLName, ModuleDir+DLLName+'.dll', SizeOf(DLLName)-1);
        DLLModule := LoadLibrary(DLLName);
        if DLLModule=0 then
          MessageBox(Handle, PChar('Ошибка открытия '+DLLName+' ('
            +IntToStr(GetLastError)+')'), MesTitle, MB_OK or MB_ICONERROR)
        else begin
          P := GetProcAddress(DLLModule, NewMenuItemDLLProcName);
          if P=nil then
          begin
            FreeLibrary(DLLModule);
            MessageBox(Handle, PChar('В DLL '+DLLName+' нет процедуры инициализации '
              +NewMenuItemDLLProcName), 'Загрузка рабочих модулей',
              MB_OK or MB_ICONERROR)
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
    {FindClose(SearchRec);}
  end
  else
    MessageBox(Handle, 'Не удалось открыть список модулей',
      MesTitle, MB_OK or MB_ICONERROR)
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
  if not GetRegParamByName('EjectUsbFlash', CommonUserNumber, EjectUsbFlash) then
    EjectUsbFlash := 0;
  ShowInfo('Остановка СКЗИ...');
  FreeItscLib;
  ShowInfo('Выгрузка модулей...');
  FreeDLLs;
  DLLs.Free;
  ProtoMes(plInfo, PChar(Caption), 'Протоколирование завершено');
  ShowInfo('Закрытие протокола сообщений...');
  CloseProto;
  ShowInfo('Закрытие базы настроек...');
  CloseRegistr;
  if EjectUsbFlash>0 then
  begin
    ShowInfo('Останов USB Flash...');
    FlashStopItemClick(nil);
  end
  else
    ShowInfo('');
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
  DPI_X, DPI_Y, Page, Num, N, LastYCoord, TotalPageCount, LI, dN: Integer;
  Limits: TRect;
  Marg: TPoint;
  TextPrintManager: TTextPrintManager;
  APort, PrinterCommands: array[0..255] of Char;
  TextLeftMarg: Integer;
  FormFeed, SetupIsLoaded : Boolean;
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

begin
  ActiveChild := ActiveMDIChild;
  if ActiveChild<>nil then
  begin
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
      if not GetRegParamByName('LeftMarg', CommonUserNumber, LeftMargin) then
        LeftMargin := 20;
      if not GetRegParamByName('TopMarg', CommonUserNumber, TopMargin) then
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
        5, 6:        {форма/табл - текстовая печать}
        if (DestCode=5) and (Length(PrintDocRec.TextForm)>0)
          or (DestCode=6) and (Length(PrintDocRec.TextForm)>0) then
        begin
          if GetRegParamByName('PrnPortPath', CommonUserNumber, APort) then
          begin
            if GetRegParamByName('PrinterCommands', CommonUserNumber, PrinterCommands) then
            begin
              if not GetRegParamByName('TextLeftMarg', CommonUserNumber, TextLeftMarg) then
                TextLeftMarg := 0;
              if not GetRegParamByName('FormFeed', CommonUserNumber, FormFeed) then
                FormFeed := False;
              TextPrintManager := TTextPrintManager.Create(Self);
              try
                try
                  with TextPrintManager do
                  begin
                    FN := PatternDir + PrinterCommands;
                    if LoadCommands(FN) then
                    begin
                      ShowInfo('Инициальзация порта...');
                      if InitPort(@APort, False) then
                      begin
                        ShowInfo('Отправка на печать...');
                        case DestCode of
                          5:
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
                                  TextLeftMarg, FormFeed {and (Page<Num)})
                                then
                                  Inc(N)
                                else
                                  MessageBox(Handle, PChar('Ошибка печати формы ['
                                    +FN+']'), MesTitle, MB_OK or MB_ICONERROR);
                              end;
                            ShowInfo('Напечатано документов: '+IntToStr(N));
                            if N<Num then
                            begin
                              MessageBox(Handle, PChar('Не удалось распечатать документов: '
                                +IntToStr(Num-N)), MesTitle, MB_OK or MB_ICONERROR);
                            end;
                          end;
                          6:
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
                          +APort+']'), MesTitle, MB_OK or MB_ICONERROR);
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
            end
            else
              MessageBox(Handle, 'Не найден параметр "команды принтера"',
                MesTitle, MB_OK or MB_ICONERROR);
            end
          else
            MessageBox(Handle, 'Не найден параметр "порт принтера"',
              MesTitle, MB_OK or MB_ICONERROR);
        end;
        7, 8:        {форма/табл - печать в файл}
        if (DestCode=7) and (Length(PrintDocRec.TextForm)>0)
          or (DestCode=8) and (Length(PrintDocRec.TextForm)>0) then
        begin
          if not GetRegParamByName('PrintFilePath', CommonUserNumber, APort) then
            APort := 'prnfile.txt';
          if not GetRegParamByName('PrintFileCommands', CommonUserNumber, PrinterCommands) then
            PrinterCommands := 'empty.cfg';
          if not GetRegParamByName('TextLeftMarg', CommonUserNumber, TextLeftMarg) then
            TextLeftMarg := 0;
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
        end;
      end;
      if (PrintDocRec.CassCopy>0) then
        Dec(PrintDocRec.CassCopy);
      until (PrintDocRec.CassCopy=0);       //Добавлено Меркуловым
    end
    else
      MessageBox(Handle, PChar('Печать из этого окна не предусмотрена'),
        MesTitle, MB_OK or MB_ICONWARNING);
  end
  else
    MessageBox(Handle, 'Нет активного окна', MesTitle,
      MB_OK or MB_ICONWARNING);
end;

procedure TMainForm.FormPreviewItemClick(Sender: TObject);
const
  MesTitle: PChar = 'Предпросмотр';
var
  {Limits: TRect;}
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
          PreviewForm := TPreviewForm.Create(Self);
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

procedure TMainForm.WMPrintDoc(var Message: TMessage);
begin
  inherited;
  FormPrintItemClick(Self);
end;

procedure TMainForm.WMPrintTable(var Message: TMessage);
begin
  inherited;
  ListPrintItemClick(Self);
end;

function TMainForm.GetVerNum: LongWord;
var
  S: string;
  I: Integer;
begin
  try
    S := VerNumLabel.Caption;
    I := Length(S);
    while I>0 do
    begin
      if not(S[I] in ['0'..'9']) then
        Delete(S, I, 1);
      Dec(I)
    end;
    Result := StrToInt(S);
  except
    Result := 0;
  end;
end;

procedure TMainForm.WMGetVerNum(var Message: TMessage);
begin
  inherited;
  Message.Result := GetVerNum;
end;

procedure TMainForm.WMCheckNewLetter(var Message: TMessage);
const
  LetterHotKey = VK_F6;
begin
  inherited;
  if (Message.WParam>0) and ((Message.LParam=2) or (MessageBox(Handle, PChar(
    'В ходе сеанса связи были получены новые письма: '+IntToStr(Message.WParam)
    +#13#10'Для их прочтения будет открыто окно "Файл-Письма"'), 'Входящие письма',
    MB_ICONINFORMATION or MB_OKCANCEL)=ID_OK)) then
  begin
    PostMessage(Handle, WM_KEYDOWN, LetterHotKey, 0);
    PostMessage(Handle, WM_KEYUP, LetterHotKey, 0);
  end;
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

function MakeItemList(AItem: TMenuItem): Boolean;
var
  I: Integer;
begin
  if (AItem.Count>0) and (AItem.ImageIndex<0) then
  begin
    Result := False;
    for I := 1 to AItem.Count do
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

var
  ToolbarIsChanged: Boolean = False;

procedure TMainForm.WMRebuildToolbar(var Message: TMessage);
var
  B: TToolButton;
  MI: TMenuItem;
  I, J: Integer;
  S: string;
begin
  inherited;
  if not ToolbarIsChanged then
  begin
    ToolbarIsChanged := True;
    try
      inherited;
      CheckDataBaseForm;
      if (ToolBar<>nil) and ToolBar.Visible  and ToolBar.Enabled then
      begin
        while ToolBar.ControlCount>0 do
          ToolBar.Controls[0].Free;
        ItemList := TList.Create;
        try
          MakeItemList(Menu.Items);  {добавим команды главного меню}
          if (ActiveMDIChild<>nil) and (ActiveMDIChild.Menu<>nil)
            and (ActiveMDIChild.Menu.Items<>nil) then
              MakeItemList(ActiveMDIChild.Menu.Items); {добавим команды дочернего меню}
              {showmessage('1');}
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

procedure TMainForm.CheckDataBaseForm;
var
  NoForm: Boolean;
  PI, FI, LI: Integer;
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
  if SmartIcons then
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
  Application.ProcessMessages;
end;

procedure TMainForm.ShowInfo(S: string);
begin
  StatusBar.SimplePanel := False;
  StatusBar.Panels[InfoPanelIndex].Text := S;
  Application.ProcessMessages;
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
    for I := 0 to ProgressPanelIndex-1 do
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

procedure TMainForm.FormShow(Sender: TObject);
const
  MesTitle: PChar = 'Проверка версии';
var
  ShowToolBar: Boolean;
  //DefPayVO: Integer;
begin
  ShowUser;
  if not GetRegParamByName('ShowToolBar', CommonUserNumber, ShowToolBar) then
    ShowToolBar := True;
  ToolBar.Visible := ShowToolBar;
  if not GetRegParamByName('FlatToolBar', CommonUserNumber, ShowToolBar) then
    ShowToolBar := True;
  ToolBar.Flat := ShowToolBar;
  if ShowToolBar then
    ToolBar.Height := 27
  else
    ToolBar.Height := 30;
  ShowInfo('');
  PostMessage(Handle, WM_REBUILDTOOLBAR, 0, 0);

  (*if not GetRegParamByName('DefPayVO', CommonUserNumber, DefPayVO) then
    DefPayVO := 101;
  if (DefPayVO<100) and (Date>=StrToDate('01.06.2003')) then
  begin
    MessageBox(Handle, PChar('Сегодня '+DateToStr(Date)+'.'
      +#13#10'Начиная с 1 июня 2003 согласно УКАЗАНИЮ ЦБ РФ от 03.03.2003 N 1256-У'
      +#13#10'и ПРИКАЗУ МНС РФ N БГ-3-10/98, ГТК РФ N 197, Минфина РФ N 22н'
      +#13#10'начинает действовать новая форма платежных поручений.'
      +#13#10'Программа будет переключена на ввод новых форм'),
      MesTitle, MB_OK or MB_ICONWARNING);
    if not SetRegParamByName('DefPayVO', CommonUserNumber, False, '101') then
      MessageBox(Handle, 'Не удалось переключиться на новую версию платежных поручений',
        MesTitle, MB_OK or MB_ICONERROR);
  end; *)
  AppVisible := IsWindowVisible(Application.Handle);
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
  ModuleDataSet: TExtBtrDataSet;
  ModuleRec: TModuleRec;
  Key:
    packed record
      kKind: Byte;
      kIder: Integer;
    end;
  Len, Res: Integer;
  S: string;
  F: file;
begin
  ModuleDataSet := GlobalBase(biModule);
  try
    S := AppDir+'BankCl.upd';
    with Key do
    begin
      kKind := mkUpdate;
      kIder := 0;
    end;
    Len := SizeOf(ModuleRec);
    Res := ModuleDataSet.BtrBase.GetGE(ModuleRec, Len, Key, 0);
    if (Res=0) and (Key.kKind=mkUpdate) then
    begin
      if not FileExists(S) then
      begin
        if MessageBox(Handle, 'Были получены модули обновления. Провести обновление сейчас?'
          +#13#10'Прежде чем нажать "Да" убедитесь, что программа закрыта на других компьютерах',
          MesTitle, MB_YESNOCANCEL or MB_ICONQUESTION) = IDYES then
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
            {CREATE_NEW_CONSOLE}DETACHED_PROCESS, nil, nil, si, pi) then
          begin
            AssignFile(F, S);
            {$I-} Rewrite(F); {$I+}
            if IOResult=0 then
              CloseFile(F);
            ExitProcess(0)
            {Application.Terminate;}
          end
          else
            MessageBox(Handle, PChar('Не удалось запустить модуль обновления'
              +#13#10+CmdLine), MesTitle, MB_OK or MB_ICONERROR);
        end;
      end;
    end;
  finally
  end;
  if FileExists(S) then
    DeleteFile(S);
end;

procedure TMainForm.WMMakeUpdate(var Message: TMessage);
begin
  inherited;
  UpdateItemClick(Self);
end;

procedure TMainForm.WMShowHint(var Message: TMessage);
var
  P: PChar;
begin
  inherited;
  P := PChar(Message.WParam);
  if P<>nil then
    ShowHint(P);
end;

procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  ShowInfo('Закрытие окон...');
  CloseAllItemClick(nil);
  ShowInfo('Закрытие основных баз...');
  DoneBasicBase;
end;

(*procedure RebootSystem;
var
  handle, ph: THandle;
  {pid, }n: DWORD;
  luid: TLargeInteger;
  priv: TOKEN_PRIVILEGES;
  dummy: PTokenPrivileges;
  ver: TOSVERSIONINFO;
begin
  ver.dwOSVersionInfoSize := Sizeof(ver);
  GetVersionEx(ver);
  if ver.dwPlatformId=VER_PLATFORM_WIN32_NT then
  begin
    {pid := GetCurrentProcessId;}
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
end;*)

procedure TMainForm.CheckRegParam(Sender: TObject; ParamIndex: Integer;
  AskReboot: Boolean; var NeedRebMes: string);
const
  MesTitle0: PChar = 'Установка размера буфера';
  MesTitle1: PChar = 'Регистрация СКЗИ';
  RegPath0: PChar = 'Software\Btrieve Technologies\Microkernel Workstation Engine\Version  6.15\Settings';
  RegPath1: PChar = 'CLSID\{E09A58CD-9421-4893-B30F-0AB917CF4E61}';
  RegName0: PChar = 'Max Communication Buffer Size';
  ParValue0: Integer = 65827;
var
  Reg: TRegistry;
  Opened, Seted: Boolean;
  MesTitle, RegPathN: PChar;
  E, I: Integer;
  S: string;
  F: TextFile;
  SD: array[0..255] of Char;
  ResCode: DWord;
begin
  if ParamIndex=0 then
  begin
    MesTitle := MesTitle0;
    S := 'Установка параметра';
  end
  else begin
    MesTitle := MesTitle1;
    S := 'Регистрация СКЗИ';
  end;
  if (Sender=nil) or (MessageBox(Handle,
    PChar(S+' производится при смене Windows.'#13#10'Продолжить?'),
    MesTitle, MB_YESNOCANCEL or MB_ICONQUESTION) = IDYES) then
  begin
    Seted := False;
    Reg := TRegistry.Create;
    with Reg do
    begin
      try
        if ParamIndex=0 then
        begin
          RootKey := HKEY_LOCAL_MACHINE;
          RegPathN := RegPath0;
          Opened := OpenKey(RegPathN, ParamIndex=0);
        end
        else begin
          RootKey := HKEY_CLASSES_ROOT;
          RegPathN := RegPath1;
          Opened := OpenKeyReadOnly(RegPathN);
        end;
        if Opened then
        begin
          if ParamIndex=0 then
          begin
            try
              if ReadInteger(RegName0) >= ParValue0 then
              begin
                Seted := True;
                if Sender<>nil then
                begin
                  if MessageBox(Handle, 'Параметр уже установлен в нормальное значение.'#13#10
                    +'Желаете заново переустановить его?', MesTitle,
                    MB_YESNOCANCEL or MB_DEFBUTTON2 or MB_ICONINFORMATION) = ID_YES
                  then
                    Seted := False;
                end;
              end;
            except
              Seted := False;
            end;
            if not Seted then
            begin
              Seted := False;
              try
                WriteInteger(RegName0, ParValue0);
                Seted := True;
              except
                Seted := False;
              end;
            end
            else
              Seted := False;
          end
          else
            Seted := (Sender<>nil) and (MessageBox(Handle,
              'СКЗИ уже зарегистрировано в системе.'#13#10
              +'Желаете заново переустановить его?', MesTitle,
              MB_YESNOCANCEL or MB_DEFBUTTON2 or MB_ICONINFORMATION)=ID_YES);
          CloseKey;
        end
        else begin
          if ParamIndex=0 then
          begin
            if Sender<>nil then
              MessageBox(Handle, PChar('Не удалось открыть параметр ['
                +RegPathN+']'), MesTitle, MB_OK or MB_ICONERROR)
          end
          else begin
            E := ID_RETRY;
            while not FileExists(AppDir+'Tcc_Itcs.dll') and (E=ID_RETRY) do
            begin
              E := MessageBox(Handle,
                'Библиотеки СКЗИ не установлены'#13#10
                +'Желаете установить их?', MesTitle,
                MB_ABORTRETRYIGNORE or MB_DEFBUTTON2 or MB_ICONWARNING);
              if E=ID_RETRY then
              begin
                RunAndWait(AppDir+'CoInst.exe -C4 -E7', SW_SHOWDEFAULT, ResCode);
              end;
            end;
            if (E=ID_RETRY) or (E=ID_IGNORE) then
              Seted := MessageBox(Handle,
                'СКЗИ не зарегистрировано в системе, при этом функциональность'#13#10
                +'программы не гарантируется. Запустить скрипт регистрации?', MesTitle,
                MB_YESNOCANCEL {or MB_DEFBUTTON2} or MB_ICONINFORMATION)=ID_YES;
          end;
        end;
      finally
        Free;
      end;
    end;
    if (ParamIndex<>0) and Seted then
    begin
      Seted := False;
      ShowHint('');
      S := ExtractFilePath(AppDir);
      SetCurrentDirectory(PChar(S));
      S := AppDir+'register.bat';
      GetSystemDirectory(SD, SizeOf(SD));
      if (StrLen(SD)>0) and (SD[StrLen(SD)-1]<>'\') then
        StrLCat(SD, '\', SizeOf(SD));
      ShowInfo('Открытие файла '+S+'...');
      AssignFile(F, S);
      {$I-} Reset(F); {$I+}
      if IOResult=0 then
      begin
        E := 0;
        I := 0;
        while not Eof(F) do
        begin
          ReadLn(F, S);
          Inc(I);
          if (Length(Trim(S))>0) and (UpperCase(Copy(S, 1, 4))<>'REM ') then
          begin
            if Length(ExtractFilePath(S))=0 then
              S := SD + S;
            ShowInfo('Вполнение команды ['+S+']...');
            if not RunAndWait(S, SW_SHOWNORMAL, ResCode) or ((ResCode<>0) and (I>2)) then
            begin
              Inc(E);
              MessageBox(Handle, PChar('Ошибка при выполнении команды регистрации:'#13#10'['+S+']'),
                MesTitle, MB_OK or MB_ICONERROR);
            end;
          end;
        end;
        CloseFile(F);
        if E=0 then
        begin
          Seted := True;
          S := 'Скрипт регистрации СКЗИ успешно выполнен';
          E := MB_ICONINFORMATION;
        end
        else begin
          S := 'Не было выполнено команд: '+IntToStr(E);
          E := MB_ICONWARNING;
        end;
      end
      else begin
        S := 'Не удалось открыть файл регистрации '+S;
        E := MB_ICONERROR;
      end;
      MessageBox(Handle, PChar(S), MesTitle, MB_OK or E);
      ShowInfo(S);
    end;
    if Seted or (Length(NeedRebMes)>0) then
    begin
      if Seted then
      begin
        if ParamIndex=0 then
          S := 'Размер буфера Btrieve "Communication Buffer" изменен'
        else
          S := 'Произведена регистрация СКЗИ в системе';
        if Length(NeedRebMes)>0 then
          NeedRebMes := NeedRebMes+'.'#13#10+S
        else
          NeedRebMes := S;
      end;
      if AskReboot then
      begin
        if MessageBox(Handle,
          PChar(NeedRebMes+'.'#13#10'Для вступления изменений в силу следует перезапустить'
          +#13#10'программу (а возможно, даже перезагрузить компьютер)'), MesTitle,
          MB_OKCANCEL {or MB_DEFBUTTON2} or MB_ICONWARNING)=ID_OK then
        begin
          //RebootSystem;
          ExitProcess(0);
          {Application.Terminate;}
        end;
      end;
    end;
  end;
end;

procedure TMainForm.SetBufferItemClick(Sender: TObject);
var
  S: string;
begin
  S := '';
  CheckRegParam(Sender, 0, True, S);
end;

procedure TMainForm.GuideItemClick(Sender: TObject);
var
  H: Integer;
  S: string;
begin
  S := HelpDir;
  if Sender<>OtherHelpItem then
    S := S+'BankCl.doc';
  H := ShellExecute(Application.Handle, 'open', PChar(S), nil, nil, SW_SHOW);
  if H<=32 then
    MessageBox(Handle, PChar('Не удалось открыть '+S+' ('+IntToStr(H)),
      'Вызов документации', MB_OK or MB_ICONERROR);
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

procedure TMainForm.RegItcsDllItemClick(Sender: TObject);
var
  S: string;
begin
  S := '';
  CheckRegParam(Sender, 1, True, S);
end;

procedure TMainForm.ExchangeKeyItemClick(Sender: TObject);
var
  S: string;
  ResCode: DWord;
begin
  S := AppDir+'CoInst.exe -E7';
  if not RunAndWait(S, SW_SHOWNORMAL, ResCode) then
    MessageBox(Handle, PChar('Не удалось запустить '+S),
      'Выполнение утилиты', MB_OK or MB_ICONERROR);
end;

procedure TMainForm.KeyClearItemClick(Sender: TObject);
var
  S: string;
begin
  S := TransPath;
  NormalizeDir(S);
  if MessageBox(Handle, PChar('Желаете полностью удалить содержимое каталога'#13#10
    +S), 'Очистка транспортного каталога', MB_YESNOCANCEL or MB_ICONWARNING)=ID_YES
  then
    ClearDirectory(S);
end;

procedure TMainForm.ReInitKeyItemClick(Sender: TObject);
var
  TE, UseVal, UseFileMod, UseExportMod: Boolean;
begin
  TE := ToolBar.Enabled;
  ToolBar.Enabled := False;
  CloseAllItemClick(nil);
  Application.ProcessMessages;
  Sleep(40);
  Application.ProcessMessages;
  FreeDLLs;
  Application.ProcessMessages;
  DoneAllCryptoEngine;
  Application.ProcessMessages;
  UserInited := False;
  SendMessage(Handle, WM_USERAUTORIZATION, 0, 0);
  Application.ProcessMessages;
  {showmessage}
  //showmessage(inttostr(getmaincryptoengineindex));
  {LogoForm.Repaint;}
  if not GetRegParamByName('UseVal', CommonUserNumber, UseVal) then
    UseVal := False;
  if not GetRegParamByName('UseFileMod', CommonUserNumber, UseFileMod) then
    UseFileMod := False;
  if not GetRegParamByName('UseExportMod', CommonUserNumber, UseExportMod) then
    UseExportMod := False;
  try
    LoadDLLs(UseVal, UseFileMod, UseExportMod);
  except
    MessageBox(Handle, 'Ошибка подключения модулей', 'Загрузка модулей',
      MB_OK or MB_ICONERROR);
  end;
  ToolBar.Enabled := TE;
  PostMessage(Handle, WM_REBUILDTOOLBAR, 0, 0);
end;

procedure TMainForm.VipNetKeyPathItemClick(Sender: TObject);
var
  F: TextFile;
  S, Kod: string;
  I: Integer;
begin
  Kod := '';
  KeyPathDialog := TKeyPathDialog.Create(Self);
  with KeyPathDialog do
  begin
    FMailKey := MailKey;
    KeyDirectoryEdit.Text := KeyPath;
    FTransDir := TransPath;
    NormalizeDir(FTransDir);
    if GetVipNetKeyParam(FTransDir, Kod, S)>0 then
      KeyDirectoryEdit.Text := S;
    if ShowModal=mrOk then
    begin
      AssignFile(F, FTransDir+FMailKey);
      FileMode := 2;
      {$I-} Rewrite(F); {$I+}
      if IOResult=0 then
      try
        try
          S := GetCryptoIdent;
        except
          S := '';
        end;
        if Length(S)=0 then
        begin
          if Length(Kod)=0 then
            S := '00000000'
          else
            S := Kod;
        end;
        while Length(S)<66 do
          S := S+' ';
        S := S+KeyDirectoryEdit.Text;
        I := Length(S);
        if (I>0) and (S[I]='\') then
          Delete(S, I, 1);
        WriteLn(F, S);
      finally
        CloseFile(F);
      end;
    end;
    Free;
  end;
end;

procedure TMainForm.OneCBuhItemClick(Sender: TObject);
begin
  OneCBuhForm := TOneCBuhForm.Create(Self);
  with OneCBuhForm do
  begin
    ShowModal;
    Free;
  end;
end;

function GetSystemDir: string;
var
  Buf: array[0..511] of Char;
begin
  if GetSystemDirectory(Buf, SizeOf(Buf))=0 then
    Result := 'C:\Windows\System32\'
  else
    Result := Buf;
  NormalizeDir(Result);
end;

function GetFileModTime(FN: string; var MFT: TFileTime): Boolean;
var
  Fil: GET_FILEEX_INFO_LEVELS;
  Fad: WIN32_FILE_ATTRIBUTE_DATA;
begin
  Result := FileExists(FN);
  if Result then
  begin
    Fil := GetFileExInfoStandard;
    GetFileAttributesEx(PChar(FN), Fil, @Fad);
    MFT := Fad.ftLastWriteTime;
  end;
end;

procedure TMainForm.FlashStopItemClick(Sender: TObject);
const
  EjectUtil = 'UsbEject.exe';
var
  si: TStartupInfo;
  pi: TProcessInformation;
  CmdLine: array[0..1023] of Char;
  SD, S1, S2: string;
  Exists: Boolean;
  MFT1, MFT2: TFileTime;
  I: Integer;
begin
  I := GetDriveType(PChar(AppDir));
  if I<>1 then
  begin
    S1 := AppDir + EjectUtil;
    Exists := GetFileModTime(S1, MFT1);
    if Exists then
    begin
      SD := GetSystemDir;
      if I in [0, DRIVE_REMOVABLE] then
      begin
        S2 := SD + EjectUtil;
        Exists := GetFileModTime(S2, MFT2);
        if not Exists or (CompareFileTime(MFT1, MFT2)>0) then
        begin
          CopyFile(PChar(S1), PChar(S2), False);
        end;
        Exists := FileExists(S2);
        if Exists then
          S1 := S2;
      end;

      FillChar(si, SizeOf(si), #0);
      with si do
      begin
        cb := SizeOf(si);
        dwFlags := STARTF_USESHOWWINDOW;
        wShowWindow := SW_SHOWDEFAULT; //SW_HIDE;
      end;
      if Sender<>nil then
        EjectUsbFlash := 1;
      StrPLCopy(CmdLine, '"'+S1+'" '+IntToStr(EjectUsbFlash), SizeOf(CmdLine));
      CreateProcess(nil, CmdLine, nil, nil, FALSE, {CREATE_NEW_CONSOLE}DETACHED_PROCESS, nil,
        PChar(SD), si, pi);
    end;
  end;
end;

procedure TMainForm.OpenAppItemClick(Sender: TObject);
begin
  AppVisible := IsWindowVisible(Application.Handle);
  if AppVisible or (Sender=nil) then
  begin
    Application.Minimize;
    ShowWindow(Application.Handle, SW_HIDE);
    //Hide; //SW_SHOW
    ShowWindow(Handle, SW_HIDE);
    if not RxTrayIcon.Active then
      RxTrayIcon.Active := True;
    {TaskBarAddIcon(True, Handle, TrayIconId, Icon.Handle,
      WM_TRAY, PChar(Caption));}
    AppVisible := False;
    CommonTimer.Enabled := MailTmrDelay<>0;
  end
  else begin
    ShowWindow(Handle, SW_SHOW);
    Show;
    //ShowWindow(Handle, SW_SHOW);
    {ShowWindow(Application.Handle, SW_SHOW);
    PostMessage(Application.Handle, WM_ACTIVATEAPP, 1, 0);
    SetForegroundWindow(Application.Handle);}
    PostMessage(Handle, WM_ACTIVATEAPP, 1, 0);
    Application.Restore;
    SetForegroundWindow(Handle);
    if ShowTrayIcon<2 then
      RxTrayIcon.Active := False;
    AppVisible := True;
    CommonTimer.Enabled := MinimizeTmrDelay<>0;
  end;
end;

var
  TrayIconAnimated: Boolean = False;

procedure TMainForm.RunMenuItem(ParentItem: TMenuItem; ChildImageIndex, RunParam: Integer);
var
  I: Integer;
begin
  I := ParentItem.Count;
  while I>0 do
  begin
    Dec(I);
    if ParentItem.Items[I].ImageIndex=ChildImageIndex then
    begin
      if Assigned(ParentItem.Items[I].OnClick) then
      begin
        if RunParam=0 then
          ParentItem.Items[I].OnClick(nil)
        else
          ParentItem.Items[I].OnClick(Application);
      end;
      I := 0;
    end;
  end;
end;

procedure TMainForm.WMSysCommand(var Message: TMessage);
begin
  inherited;
  case Message.WParam of
    SC_MINIMIZE:
      begin
        if Assigned(MainForm)
          and not(csDestroying in ComponentState)
          and not(csDestroying in Application.ComponentState)
          and (ShowTrayIcon>0)
        then
          OpenAppItemClick(nil);
      end;
    SC_BANKCLCOMMAND:
      begin
        case Message.LParam of
          bccDoMail:
            begin
              if MailTmrDelay>=0 then
                RunMenuItem(ServiceItem, 13, 0)
              else
                RunMenuItem(ServiceItem, 13, 1);
            end;
          bccDoMinimize:
            begin
              OpenAppItemClick(nil);
            end;
          bccDoAnimateIcon:
            begin
              if RxTrayIcon.Active then
              begin
                TrayIconAnimated := True;
                RxTrayIcon.Animated := True;
              end;
            end;
        end;
      end;
  end;
end;

//procedure TMainForm.CMDeactivate(var Message: TMessage);
(*procedure TMainForm.WMCheckAndHideApp(var Message: TMessage);
var
  WndPlcm: WINDOWPLACEMENT;
begin
  inherited;
  if GetWindowPlacement(Application.Handle, @WndPlcm) then
  begin
    if Message.WParam=555 then
      OpenAppItemClick(Self)
    else
    if WndPlcm.showCmd=SW_SHOWMINIMIZED then
    //if WindowState=wsMinimized then
      OpenAppItemClick(nil);
      //messagebox(0, PChar(IntToStr(WndPlcm.showCmd)), 'Минимайз', 0);
  end;
end;  *)

procedure TMainForm.OnAppMes(var Msg: TMsg; var Handled: Boolean);
{var
  f: TextFile;}
begin
  if Msg.message<>WM_TIMER then
  begin
    MinimizeTmrCount := 0;
    if TrayIconAnimated then
      if (Msg.message=512{WM_MOUSEMOVE}) or (Msg.message>=256{WM_KEYDOWN}) and (Msg.message<=258{WM_CHAR}) then
        RxTrayIcon.Animated := False;
  end;
  (*if (Msg.message=CM_DEACTIVATE) {or (Msg.message=49322)} then
    PostMessage(Handle, WM_CHECKANDHIDEAPP, Msg.wParam, 0); *)
  (*if (Msg.message=512) then
  begin
    AssignFile(f, 'c:\aaa.log');
    {$I-} Append(f); {$I+}
    if IOResult=0 then
    try
      WriteLn(f, TimeToStr(Time)+'  '+IntToStr(Msg.message)+' W='+IntToStr(Msg.wParam)+' L='+IntToStr(Msg.lParam));
      Flush(f);  { ensures that the text was actually written to file }
    finally
      CloseFile(f);
    end;
  end; *)
end;

procedure TMainForm.RxTrayIconClick(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  OpenAppItemClick(Self);
end;

procedure TMainForm.CommonTimerTimer(Sender: TObject);
begin
  if AppVisible then
  begin
    if MinimizeTmrDelay<>0 then
    begin
      Inc(MinimizeTmrCount);
      if MinimizeTmrCount>=Abs(MinimizeTmrDelay*12) then
      begin
        MinimizeTmrCount := 0;
        if (Screen.ActiveForm=nil) or not (fsModal in Screen.ActiveForm.FormState) then
        begin
          if MinimizeTmrDelay>0 then
            QuitItemClick(nil)
          else
            PostMessage(Handle, WM_SYSCOMMAND, SC_BANKCLCOMMAND, bccDoMinimize);
        end;
      end;
    end;
  end
  else begin
    if MailTmrDelay<>0 then
    begin
      Inc(MailTmrCount);
      if MailTmrCount>=Abs(MailTmrDelay*12) then
      begin
        MailTmrCount := 0;
        DoMailItemClick(nil);
      end;
    end;
  end;
end;

procedure TMainForm.DoMailItemClick(Sender: TObject);
begin
  PostMessage(Handle, WM_SYSCOMMAND, SC_BANKCLCOMMAND, bccDoMail);
end;

procedure TMainForm.DelOldAccItemClick(Sender: TObject);
var
  S: string;
  ResCode: DWord;
begin
  S := AppDir+'DelOldAc.exe';
  if not RunAndWait(S, SW_SHOWNORMAL, ResCode) then
    MessageBox(Handle, PChar('Не удалось запустить '+S),
      'Выполнение утилиты', MB_OK or MB_ICONERROR);
end;

end.


