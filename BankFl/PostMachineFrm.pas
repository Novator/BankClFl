unit PostMachineFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ComCtrls, StdCtrls, ActnList, ImgList, ToolWin, Menus, ExtCtrls, ScktComp,
  ShellApi, CrySign, BtrDS, Db, CommCons, BankCnBn, Utilits, Basbn, Common,
  Placemnt, NMUDP, Registr, TccItcs;

const
  WM_TRAY = WM_USER + 125;

const
  piListen = 0;
  piHint   = 1;

{const
  plFatalError   = 1;
  plError        = 2;
  plWarning      = 3;
  plInfo         = 4;
  plTrace        = 5;}

type
  TBaseIder = (biAbonId, biAbon, biPost, biPostOld);      //Изиенено Меркуловым

  TPostDataSet = class(TExtBtrDataSet)
  protected
    procedure InternalInitFieldDefs; override;
  public
    function GetFieldData(Field: TField; Buffer: Pointer): Boolean; override;
    constructor Create(AOwner: TComponent); override;
  end;

type
  TPostMachineForm = class(TForm)
    StatusBar: TStatusBar;
    MainMenu: TMainMenu;
    FileItem: TMenuItem;
    HelpItem: TMenuItem;
    ExitItem: TMenuItem;
    AboutItem: TMenuItem;
    ToolBar: TToolBar;
    ImageList: TImageList;
    ActionList: TActionList;
    ConnectAction: TAction;
    ConnectAction1: TMenuItem;
    FileBreaker2: TMenuItem;
    AbonentAction: TAction;
    AbonentItem: TMenuItem;
    PackBaseAction: TAction;
    PackItem: TMenuItem;
    FileBreaker1: TMenuItem;
    WindowsItem: TMenuItem;
    CascadeItem: TMenuItem;
    TileItem: TMenuItem;
    ArrangeItem: TMenuItem;
    WindowsBreaker1: TMenuItem;
    MinimizeItem: TMenuItem;
    RestoreItem: TMenuItem;
    CloseAllItem: TMenuItem;
    ProtoGroupBox: TGroupBox;
    ProtoMemo: TMemo;
    HorzSplitter: TSplitter;
    HelpBreaker1: TMenuItem;
    ContentsItem: TMenuItem;
    TopicItem: TMenuItem;
    HelpAction: TAction;
    MainFormStorage: TFormStorage;
    WindowsBreaker2: TMenuItem;
    ProtoShowItem: TMenuItem;
    NMUDPClient: TNMUDP;
    ServiceItem: TMenuItem;
    SetupItem: TMenuItem;
    OptimBase: TMenuItem;
    procedure ExitItemClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure AboutItemClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure ConnectActionExecute(Sender: TObject);
    procedure AbonentActionExecute(Sender: TObject);
    procedure PackBaseActionExecute(Sender: TObject);
    procedure CascadeItemClick(Sender: TObject);
    procedure TileItemClick(Sender: TObject);
    procedure ArrangeItemClick(Sender: TObject);
    procedure MinimizeItemClick(Sender: TObject);
    procedure RestoreItemClick(Sender: TObject);
    procedure CloseAllItemClick(Sender: TObject);
    procedure HorzSplitterCanResize(Sender: TObject; var NewSize: Integer;
      var Accept: Boolean);
    procedure FormDestroy(Sender: TObject);
    procedure TopicItemClick(Sender: TObject);
    procedure HelpActionExecute(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure ProtoShowItemClick(Sender: TObject);
    procedure SetupItemClick(Sender: TObject);
//    procedure OptimBaseClick(Sender: TObject);
  private
    procedure WMTray(var Message: TMessage); message WM_TRAY;
    procedure WMSysCommand(var Message: TMessage); message WM_SYSCOMMAND;
    procedure WMRebuildToolbar(var Message: TMessage); message WM_REBUILDTOOLBAR;
  public
    procedure ShowHint(Sender: TObject);
    //procedure AddToolBtn(AnAction: TAction; AnOwner: TComponent);
  end;

var
  PostMachineForm: TPostMachineForm;

procedure AddProtoMes(Level: Byte; Title: PChar; const S: string);
function GetGlobalBase(BaseIder: TBaseIder): TExtBtrDataSet;

implementation

uses ConnectFrm, PostAbonsFrm, PostPacksFrm, SetupFrm, AboutPFrm;

{$R *.DFM}

var
  MaxProtoLevel: Integer = 0;
  ShowProtoLevel: Integer = 1;
  ChatProtoMode: Integer = 1;
  ChatProtoLevel: Integer = 1;
  ProtoFileName: string = '';

procedure SetProtoParams(AMaxProtoLevel, AShowProtoLevel, AChatProtoLevel,
  AChatProtoMode: Byte; AProtoFileName: string);
begin
  MaxProtoLevel := AMaxProtoLevel;
  ShowProtoLevel := AShowProtoLevel;
  ChatProtoLevel := AChatProtoLevel;
  ChatProtoMode := AChatProtoMode;
  ProtoFileName := AProtoFileName;
end;

var
  ShowProtoErr: Boolean = True;
  //ProtoIsOpen: Boolean = False;
  //ProtoFile: TextFile;
  HProtoFile: THandle = 0;

function OpenProto: Boolean;
const
  ccFileNotFound = 2;
  MesTitle: PChar = 'Открытие/создание протокола';
begin
  if HProtoFile=0 then
  begin
    HProtoFile := CreateFile(PChar(ProtoFileName), GENERIC_WRITE,
      FILE_SHARE_READ, nil, OPEN_ALWAYS, FILE_ATTRIBUTE_ARCHIVE, 0);
    if HProtoFile=INVALID_HANDLE_VALUE then
    begin
      HProtoFile := 0;
      if ShowProtoErr then
      begin
        ShowProtoErr := Application.MessageBox(PChar('Не удалось ('
          +IntToStr(GetLastError)+') открыть файл протокола '
          +ProtoFileName+#13#10'Выдавать это собщение позднее?'),
          MesTitle, MB_YESNOCANCEL or MB_ICONERROR)<>ID_NO;
      end;
    end;
  end;
  Result := HProtoFile<>0;
end;

procedure CloseProto;
begin
  if HProtoFile<>0 then
  begin
    CloseHandle(HProtoFile);
    HProtoFile := 0;
  end;
end;

function LevelToStr(ALevel: Byte): string;
begin
  case ALevel of
    plFatalError:
      Result := 'FatalError';
    plError:
      Result := 'Error';
    plWarning:
      Result := 'Warning';
    plInfo:
      Result := 'I';
    else
      Result := 'Unknown';
  end;
end;

function LevelToIconId(ALevel: Byte): Integer;
begin
  case ALevel of
    plFatalError, plError:
      Result := MB_ICONERROR;
    plWarning:
      Result := MB_ICONWARNING;
    plInfo:
      Result := MB_ICONINFORMATION;
    else
      Result := MB_ICONQUESTION;
  end;
end;

const
  MaxProtoLine: Integer = 100;
var
  PostChatName: string = 'PostMach';
  AdminChatName: string = 'Mихаил';
  PostChatChannel: string = 'PostMach';
  UdpBuf: array[0..511] of Char;

procedure AddProtoMes(Level: Byte; Title: PChar; const S: string);
var
  I, L: DWord;
  S2: string;
  Buf: PChar;
begin
  if Level<=MaxProtoLevel then
  begin
    if (Title<>nil) and (StrLen(Title)>0) then
      S2 := ' ('+Title+') '+S
    else
      S2 := S;
    S2 := DateTimeToStr(Now)+' '+LevelToStr(Level)+S2;
    if OpenProto then
    begin
      SetFilePointer(HProtoFile, 0, nil, FILE_END);
      L := Length(S2);
      Buf := AllocMem(L+2);
      try
        StrPCopy(Buf, S2);
        Buf[L] := #13;
        Buf[L+1] := #10;
        WriteFile(HProtoFile, Buf^, L+2, I, nil);
      finally
        FreeMem(Buf);
      end;
    end;
    if (PostMachineForm<>nil) and (PostMachineForm.ProtoMemo<>nil) then
      with PostMachineForm.ProtoMemo.Lines do
      begin
        while Count>MaxProtoLine do
          Delete(0);
        Add(S2);
      end;
  end;
  if Level<=ShowProtoLevel then
  begin
    MessageBox(Application.Handle, PChar(LevelToStr(Level)+':'#13#10+S),
      Title, MB_OK or LevelToIconId(Level));
  end;
  if (Level<=ChatProtoLevel) and (PostMachineForm<>nil)
    and (PostMachineForm.NMUDPClient<>nil) then
  begin
    if (Title<>nil) and (StrLen(Title)>0) then
      S2 := ' ('+Title+') '+S
    else
      S2 := S;
    S2 := LevelToStr(Level)+' '+S2;
    if ChatProtoMode=0 then
    begin  {разговор}
      L := 2+3+Length(PostChatName)+Length(AdminChatName)+Length(S2);
      S2 := 'J2'+PostChatName+#0+AdminChatName+#0+S2+#0;
    end
    else begin   {канал}
      L := 2+3+Length(PostChatChannel)+Length(PostChatName)+Length(S2);
      S2 := '2#'+PostChatChannel+#0+PostChatName+#0+S2+#0;
    end;
    if L>SizeOf(UdpBuf) then
      L := SizeOf(UdpBuf);
    for I := 0 to L-1 do
      UdpBuf[I] := S2[I+1];
    PostMachineForm.NMUDPClient.SendBuffer(UdpBuf, L);
  end;
end;

{ TPostDataSet }

constructor TPostDataSet.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  BufSize := SizeOf(TSndPack)+32;
end;

procedure TPostDataSet.InternalInitFieldDefs;
begin
  FieldDefs.Clear;
  TFieldDef.Create(FieldDefs, 'spNameR', ftString, 9, False, 0);
  TFieldDef.Create(FieldDefs, 'spNameS', ftString, 9, False, 1);
  TFieldDef.Create(FieldDefs, 'spByteS', ftWord, 0, False, 2);
  TFieldDef.Create(FieldDefs, 'spLength', ftWord, 0, False, 3);
  TFieldDef.Create(FieldDefs, 'spWordS', ftWord, 0, False, 4);
  TFieldDef.Create(FieldDefs, 'spNum', ftInteger, 0, False, 5);
  TFieldDef.Create(FieldDefs, 'spIder', ftInteger, 0, False, 6);
  TFieldDef.Create(FieldDefs, 'spFlSnd', ftString, 1, False, 7);
  TFieldDef.Create(FieldDefs, 'spDateS', ftString, DateStrLen, False, 8);
  TFieldDef.Create(FieldDefs, 'spTimeS', ftString, TimeStrLen, False, 9);
  TFieldDef.Create(FieldDefs, 'spFlRcv', ftString, 1, False, 10);
  TFieldDef.Create(FieldDefs, 'spDataR', ftString, DateStrLen, False, 11);
  TFieldDef.Create(FieldDefs, 'spTimeR', ftString, TimeStrLen, False, 12);
end;

function TPostDataSet.GetFieldData(Field: TField; Buffer: Pointer): Boolean;
begin
  Result := False;
  with PSndPack(ActiveBuffer)^ do
  begin
    if not IsEmpty then
    begin
      Result := True;
      case Field.Index of
        0: StrPLCopy(Buffer, spNameR, Field.DataSize-1);
        1: StrPLCopy(Buffer, spNameS, Field.DataSize-1);
        2: PWord(Buffer)^ := spByteS;
        3: PWord(Buffer)^ := spLength;
        4: PWord(Buffer)^ := spWordS;
        5: PInteger(Buffer)^ := spNum;
        6: PInteger(Buffer)^ := spIder;
        7: PChar(Buffer)[0] := spFlSnd;
        8: StrPLCopy(Buffer, BtrDateToStr(spDateS), Field.DataSize-1);
        9: StrPLCopy(Buffer, BtrTimeToStr(spTimeS), Field.DataSize-1);
        10: PChar(Buffer)[0] := spFlRcv;
        11: StrPLCopy(Buffer, BtrDateToStr(spDateR), Field.DataSize-1);
        12: StrPLCopy(Buffer, BtrTimeToStr(spTimeR), Field.DataSize-1);
        else
          Result := False;
      end;
    end;
  end;
end;

const
  NumOfGlobalBase = Ord(High(TBaseIder))+1;
var
  //Изменено Меркуловым
  GlobalBases: array[0..NumOfGlobalBase-1] of TExtBtrDataSet = (nil, nil, nil, nil);
  BaseFiles: array[0..NumOfGlobalBase-1] of string =
    ('abonid.btr', 'abon.btr', 'post.btr', 'post.lol');

function GetGlobalBase(BaseIder: TBaseIder): TExtBtrDataSet;
var
  I: Integer;
begin
  I := Ord(BaseIder);
  if (I>=0) and (I<NumOfGlobalBase) then
    Result := GlobalBases[I]
  else begin
    Result := nil;
    AddProtoMes(plError, nil, 'Запрос базы недопустимого индекса');
  end;
end;

function InitPostBase(BaseDir: string): Integer;
var
  ABaseIder: TBaseIder;
  ADataSet: TExtBtrDataSet;
  AFileName: TFileName;
  ErrMes: string;
begin
  Result := 0;
  ErrMes := '';
  for ABaseIder := Low(TBaseIder) to High(TBaseIder) do
  begin
    if GlobalBases[Ord(ABaseIder)]=nil then
    begin
      AFileName := BaseFiles[Ord(ABaseIder)];
      if Length(AFileName)>0 then
      begin
        AFileName := BaseDir + AFileName;
        case ABaseIder of
          biAbonId:
            begin
              ADataSet := TAbonIdDataSet.Create(Application);
            end;
          biAbon:
            begin
              ADataSet := TAbonDataSet.Create(Application);
              (ADataSet as TAbonDataSet).SetAbonId(
                GetGlobalBase(biAbonId) as TAbonIdDataSet);
            end;
          biPost:
            begin
              ADataSet := TPostDataSet.Create(Application);
              if OldMach then
                AFileName := ChangeFileExt(AFileName, '.lol');
            end;
          //Добавлено Меркуловым
          biPostOld:
            begin
              ADataSet := TPostDataSet.Create(Application);
            end;
          //Конец
          else
            ADataSet := nil;
        end;
        GlobalBases[Ord(ABaseIder)] := ADataSet;
        with ADataSet do
        begin
          try
            TableName := AFileName;
            Active := True;
            Inc(Result);
          except
            ErrMes := ErrMes+#13#10+AFileName;
          end;
        end;
      end;
    end;
  end;
  if Length(ErrMes)>0 then
    MessageBox(0, PChar('Не удалось открыть базы:'+ErrMes),
      'Инициализация баз', MB_OK or MB_ICONERROR);
end;

procedure DonePostBase;
var
  ABaseIder: TBaseIder;
begin
  for ABaseIder := Low(TBaseIder) to High(TBaseIder) do
  begin
    if GlobalBases[Ord(ABaseIder)]<>nil then
    begin
      try
        GlobalBases[Ord(ABaseIder)].Free;
      finally
        GlobalBases[Ord(ABaseIder)] := nil;
      end;
    end;
  end;
end;

procedure TPostMachineForm.ExitItemClick(Sender: TObject);
begin
  Close;
end;

function TaskBarAddIcon(New: Boolean; ParentWnd: HWnd; IconId: Cardinal;
  Icon: HIcon; Msg: Cardinal; Tip: PChar): Boolean;
var
  Nid : TNotifyIconData;
begin
  FillChar(Nid, SizeOf(TNotifyIconData), #0);
  with Nid do
  begin
    cbSize := SizeOf(TNotifyIconData);
    Wnd := ParentWnd;
    uID := IconId;
    uFlags := NIF_ICON or NIF_MESSAGE or NIF_TIP;
    uCallbackMessage := Msg;
    hIcon := Icon;
    if Tip<>nil then
      StrLCopy(szTip, Tip, SizeOf(szTip)-1);
  end;
  if New then
    Result := Shell_NotifyIcon(NIM_ADD, @Nid)
  else
    Result := Shell_NotifyIcon(NIM_DELETE, @Nid);
end;

const
  TrayIconId = 123;

const
  IconTitle: PChar = 'Почтовая машина';

procedure TPostMachineForm.WMTray(var Message: TMessage);
begin
  if Message.wParam = TrayIconId then
  begin
    case Message.lParam of
      WM_LBUTTONUP{WM_LBUTTONDBLCLK}:
        begin
          ShowWindow(Handle, SW_SHOW);
          Show;
          //ShowWindow(Handle, SW_SHOW);
          {ShowWindow(Application.Handle, SW_SHOW);
          PostMessage(Application.Handle, WM_ACTIVATEAPP, 1, 0);
          SetForegroundWindow(Application.Handle);}
          PostMessage(Handle, WM_ACTIVATEAPP, 1, 0);
          Application.Restore;
          SetForegroundWindow(Handle);
          //SetForegroundWindow(Application.Handle);
          TaskBarAddIcon(False, Handle, TrayIconId, Application.Icon.Handle,
            WM_TRAY, IconTitle);
        end;
      {WM_RBUTTONDOWN:
        begin
          GetCursorPos(P);
          PopMenu := CreatePopupMenu;
          AppendMenu(PopMenu, MF_ENABLED or MF_STRING, ID_StateItem, '&Свойства');
          AppendMenu(PopMenu, MF_ENABLED or MF_STRING, ID_AboutItem, '&О программе...');
          AppendMenu(PopMenu, MF_SEPARATOR, 0, nil);
          AppendMenu(PopMenu, MF_ENABLED or MF_STRING, ID_ExitItem, '&Выход');
          SetMenuDefaultItem(PopMenu, 0, 1);
          P.X := (P.X div IconSize +1) * IconSize;
          P.Y := (P.Y div IconSize) * IconSize;
          TrackPopupMenu(PopMenu, TPM_HORIZONTAL or TPM_LEFTALIGN, P.X, P.Y,
            0, Wnd, nil);
          DestroyMenu(PopMenu);
        end;}
    end;
  end;
  inherited;
end;

const
  SCP_RunServer = 111;

procedure TPostMachineForm.WMSysCommand(var Message: TMessage);
begin
  inherited;
  if Message.WParam=SC_MINIMIZE then
  begin
    if Message.LParam=SCP_RunServer then
    begin
      ConnectActionExecute(nil);
      Application.ProcessMessages;
      ConnectForm.RunAction.Execute;
      Message.LParam := 0;
      Application.ProcessMessages;
    end;
    if (ConnectForm<>nil) and ConnectForm.ServerSocket.Active
      and not(csDestroying in ComponentState)
      and not(csDestroying in Application.ComponentState) then
    begin
      Application.Minimize;
      ShowWindow(Application.Handle, SW_HIDE);
      //Hide; //SW_SHOW
      ShowWindow(Handle, SW_HIDE);
      TaskBarAddIcon(True, Handle, TrayIconId, Icon.Handle,
        WM_TRAY, PChar(Caption));
    end;
  end;
end;

procedure TPostMachineForm.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  CloseAllItemClick(nil);
  DonePostBase;
end;

procedure TPostMachineForm.AboutItemClick(Sender: TObject);
begin
  Application.CreateForm(TAboutPForm, AboutPForm);
  with AboutPForm do
  begin
    ShowModal;
    Free;
  end;
  {ShellAbout(Handle, 'Почтовая машина Банк-Клиент',
    '2004(c) Транскапиталбанк, Пермский филиал',
    Application.Icon.Handle);}
end;

procedure TPostMachineForm.ShowHint(Sender: TObject);
begin
  StatusBar.Panels.Items[piHint].Text := Application.Hint;
end;

var
  RunOnStart: Boolean = False;
  ChatRecvMask: string = '192.168.1.255';
  ChatRecvPort: Integer = 8167;

procedure TPostMachineForm.FormCreate(Sender: TObject);
const
  MesTitle: PChar = 'Вход';
var
  S, PassFile, KeyPath, TransPath, MP, NO, OP: string;
  K, Step: Integer;
  F: TextFile;
  GuestEnter: Boolean;
//  T: array[0..511] of Char;
begin
  GuestEnter := False;
  OldMach := False;
  KeyPath := 'A:';
  TransPath := 'Key';
  PassFile := '';
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
          'R':
            RunOnStart := True;
          {'M':
            MinOnStart := True;}
          'K':
            KeyPath := Trim(Copy(S, 4, Length(S)-3));
          'P':
            PassFile := Trim(Copy(S, 4, Length(S)-3));
          'G':
            GuestEnter := True;
          'T':
            TransPath := Trim(Copy(S, 4, Length(S)-3));
          'O':
            OldMach := True;
        end;
      end;
    end;
  end;

  if OldMach then
    Caption := Caption + ' (старые ключи)';

  SetRegFile('Post\setup.btr');
  ShortDateFormat := 'dd.MM.yyyy';
  DateSeparator := '.';
  LongTimeFormat := 'hh:mm:ss';
                          
  //TimeSeparator := ':';
  if not GetRegParamByName('ProtoLevel', CommonUserNumber, MaxProtoLevel) then
    MaxProtoLevel := plInfo;
  if not GetRegParamByName('ShowProtoMes', CommonUserNumber, ShowProtoLevel) then
    ShowProtoLevel := plFatalError;
  if not GetRegParamByName('ChatProtoLevel', CommonUserNumber, ChatProtoLevel) then
    ChatProtoLevel := plWarning;
  if not GetRegParamByName('ChatProtoMode', CommonUserNumber, ChatProtoMode) then
    ChatProtoMode := 1;
  PostChatName := DecodeMask('$(PostChatName)', 5, CommonUserNumber);
  AdminChatName := DecodeMask('$(AdminChatName)', 5, CommonUserNumber);
  PostChatChannel := DecodeMask('$(PostChatChannel)', 5, CommonUserNumber);
  ChatRecvMask := DecodeMask('$(ChatRecvMask)', 5, CommonUserNumber);
  if not GetRegParamByName('ChatRecvPort', CommonUserNumber, ChatRecvPort) then
    ChatRecvPort := 8167;
  S := DecodeMask('$(ProtoFile)', 5, CommonUserNumber);
  if OldMach then
    S := ChangeFileExt(S, '.lol');
  SetProtoParams(MaxProtoLevel, ShowProtoLevel, ChatProtoLevel, ChatProtoMode, S);
  ProtoMes(plInfo, PChar(Caption), '===Начало протоколирования===');
  //SetProtoParams(plInfo, plFatalError, plWarning, 1, PostDir+'post.log');
  if not GetRegParamByName('MaxProtoLine', CommonUserNumber, MaxProtoLine) then
    MaxProtoLine := 100;

  MainFormStorage.IniFileName := ChangeFileExt(Application.ExeName, '.ini');

  NMUDPClient.RemoteHost := ChatRecvMask;
  NMUDPClient.RemotePort := ChatRecvPort;

  Application.OnHint := ShowHint;

  Application.HelpFile := HelpDir
    +ChangeFileExt(ExtractFileName(Application.ExeName), '.hlp');

  S := '';
  LoadItscLib(S);
  if Length(S)>0 then
    MessageBox(Handle, PChar(S), 'Инициализация СКЗИ "Демен-К"',
      MB_OK or MB_ICONERROR);

  Step := IDRETRY;
  if GuestEnter then
    Step := IDIGNORE
  else begin
    MP := ManualStr;
    NO := ManualStr;
    OP := ManualStr;
    K := 0;
    if Length(PassFile)>0 then
    begin
      AssignFile(F, PassFile);
      FileMode := 0;
      {$I-} Reset(F); {$I+}
      if IOResult=0 then
      begin
        while not Eof(F) do
        begin
          ReadLn(F, S);
          case K of
            0:
              MP := S;
            1:
              NO := S;
            2:
              OP := S;
          end;
          Inc(K);
        end;
        CloseFile(F);
      end;
    end;
    S := KeyPath+#13#10+TransPath;
    PassFile := MP+#13#10+NO+#13#10+OP;
    if Step=IDRETRY then
      Step := InitCryptoEngine(ceiDomenK, S, PassFile, True);
  end;
  if (Step=IDOK) or (Step=IDIGNORE) then
  begin
    if Step=IDIGNORE then
    begin
      if not GuestEnter then
      begin
        Application.MessageBox('Подпись не инициализирована.'+#13
          +'Машина не сможет полноценно функционировать',
          MesTitle, MB_OK or MB_ICONWARNING);
        Application.ProcessMessages;
      end;
    end;
  end;

  if (Step<>IDOK) and (Step<>IDIGNORE) then
    ExitProcess(0);

  InitPostBase('Post\');

  //Timer.Interval := ?;
  if RunOnStart then
    PostMessage(Handle, WM_SYSCOMMAND, SC_MINIMIZE, SCP_RunServer);
end;


procedure TPostMachineForm.ConnectActionExecute(Sender: TObject);
begin
  if ConnectForm=nil then
    Application.CreateForm(TConnectForm, ConnectForm)
  else
    ConnectForm.Show;
end;

procedure TPostMachineForm.AbonentActionExecute(Sender: TObject);
begin
  if AbonsForm=nil then
    Application.CreateForm(TAbonsForm, AbonsForm)
  else
    AbonsForm.Show;
end;

procedure TPostMachineForm.PackBaseActionExecute(Sender: TObject);
begin
  if PostPacksForm=nil then
    Application.CreateForm(TPostPacksForm, PostPacksForm)
  else
    PostPacksForm.Show;
end;

procedure TPostMachineForm.CascadeItemClick(Sender: TObject);
begin
  Cascade;
end;

procedure TPostMachineForm.TileItemClick(Sender: TObject);
begin
  TileMode := tbHorizontal;
  Tile;
end;

procedure TPostMachineForm.ArrangeItemClick(Sender: TObject);
begin
  ArrangeIcons;
end;

procedure TPostMachineForm.MinimizeItemClick(Sender: TObject);
var
  I: Integer;
begin
  for I := MDIChildCount downto 1 do
    MDIChildren[I-1].WindowState := wsMinimized;
end;

procedure TPostMachineForm.RestoreItemClick(Sender: TObject);
var
  I: Integer;
begin
  for I := 1 to MDIChildCount do
    MDIChildren[I-1].WindowState := wsNormal;
end;

procedure TPostMachineForm.CloseAllItemClick(Sender: TObject);
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

{procedure TPostMachineForm.AddToolBtn(AnAction: TAction;
  AnOwner: TComponent);
var
  ToolButton: TToolButton;
begin
  if AnAction<>nil then
    AnOwner := AnAction.Owner;
  ToolButton := TToolButton.Create(AnOwner);
  with ToolButton do
  begin
    if AnAction<>nil then
      Action := AnAction
    else begin
      Style := tbsSeparator;
      Width := 8;
    end;
    Left := ToolBar.Width;
    Parent := ToolBar;
  end;
end;}

procedure TPostMachineForm.HorzSplitterCanResize(Sender: TObject;
  var NewSize: Integer; var Accept: Boolean);
begin
  Accept := (NewSize>=35);
end;

procedure TPostMachineForm.FormDestroy(Sender: TObject);
begin
  FreeItscLib;
  CloseProto;
  TaskBarAddIcon(False, Handle, TrayIconId, Application.Icon.Handle,
    WM_TRAY, nil);
end;

procedure TPostMachineForm.TopicItemClick(Sender: TObject);
const
  T: Char = #0;
begin
  Application.HelpCommand(HELP_KEY, Integer(@T));
end;

procedure TPostMachineForm.HelpActionExecute(Sender: TObject);
begin
  Application.HelpCommand(HELP_FINDER, 0);
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
    begin
      if AItem.Action=nil then
        ItemList.Add(AItem)
      else
        ItemList.Add(AItem.Action);
    end;
  end;
end;

var
  ToolbarIsChanged: Boolean = False;

procedure TPostMachineForm.WMRebuildToolbar(var Message: TMessage);
var
  B: TToolButton;
  MC: TComponent;
  I, J: Integer;
  S: string;
begin
  if not ToolbarIsChanged then
  begin
    ToolbarIsChanged := True;
    try
      inherited;
      //CheckDataBaseForm;
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
              {showmessage('1');}
          with ItemList do
            for I := 0 to Count-1 do
            begin
              MC := Items[I];
              if MC<>nil then
              begin
                B := TToolButton.Create({Application}MC.Owner);
                with B do
                begin
                  if MC is TAction then
                    Action := MC as TAction
                  else begin
                    MenuItem := MC as TMenuItem;
                    S := (MC as TMenuItem).Caption;
                    J := Pos('&', S);
                    if J>0 then
                      System.Delete(S, J, 1);
                    J := Pos('...', S);
                    if J>0 then
                      System.Delete(S, J, 3);
                    Hint := S+'|'+(MC as TMenuItem).Hint;
                    ShowHint := True;
                  end;
                  Left := ToolBar.Width;
                end;
                B.Parent := ToolBar;
              end
              else
                if (I>0) and (I<Count-1) and (Items[I-1]<>nil) then
                begin
                  B := TToolButton.Create(Application);
                  with B do
                  begin
                    Width := 4;
                    Style := tbsSeparator;
                    Left := ToolBar.Width;
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


procedure TPostMachineForm.FormShow(Sender: TObject);
begin
  PostMessage(Handle, WM_REBUILDTOOLBAR, 0, 0);
  {TaskBarAddIcon(False, Handle, TrayIconId, Application.Icon.Handle,
    WM_TRAY, IconTitle);}
  ProtoShowItemClick(nil);
end;

procedure TPostMachineForm.ProtoShowItemClick(Sender: TObject);
begin
  if Sender<>nil then
    ProtoShowItem.Checked := not ProtoShowItem.Checked;
  if ProtoShowItem.Checked then
  begin
    ProtoGroupBox.Visible := True;
    HorzSplitter.Visible := True;
  end
  else begin
    HorzSplitter.Visible := False;
    ProtoGroupBox.Visible := False;
    HorzSplitter.Top := 0;
    ProtoGroupBox.Top := 1;
  end
end;

procedure TPostMachineForm.SetupItemClick(Sender: TObject);
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

{
procedure TPostMachineForm.OptimBaseClick(Sender: TObject);
begin
  if OptimBaseForm=nil then
  begin
    Application.CreateForm(TOptimBaseForm, OptimBaseForm);
    OptimBaseForm.Free;
  end
  else
    OptimBaseForm.ShowModal;
end;
}

end.
