unit MailFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons, ComCtrls, ExtCtrls, Bases, Registr, CommCons, CrySign,
  Utilits, Btrieve, ScktComp, ClntCons, BtrDS, Common, PackProcess, WinSock,
  Mask, ToolEdit;

type

  TTcbClientSocket = class(TClientSocket)
  protected
    procedure Error(Socket: TCustomWinSocket; ErrorEvent: TErrorEvent;
      var ErrorCode: Integer); override;
  end;

  TMailForm = class(TForm)
    TopPanel: TPanel;
    ProtoGroupBox: TGroupBox;
    StatusBar: TStatusBar;
    BtnPanel: TPanel;
    MailBitBtn: TBitBtn;
    CloseBitBtn: TBitBtn;
    ProtoMemo: TMemo;
    StepPageControl: TPageControl;
    PrepareTabSheet: TTabSheet;
    ExchangeTabSheet: TTabSheet;
    ReceiveTabSheet: TTabSheet;
    SendGroupBox: TGroupBox;
    DocLabel: TLabel;
    SumLabel: TLabel;
    LetLabel: TLabel;
    DocCountLabel: TLabel;
    TotSumLabel: TLabel;
    LetCountLabel: TLabel;
    MailGroupBox: TGroupBox;
    SendPackLabel: TLabel;
    RecvPackLabel: TLabel;
    SendPackCountLabel: TLabel;
    RecvPackCountLabel: TLabel;
    RecvBytesCountLabel: TLabel;
    SendBytesCountLabel: TLabel;
    RecvBytesLabel: TLabel;
    SendBytesLabel: TLabel;
    TimeLabel: TLabel;
    TimeCountLabel: TLabel;
    RecvDataGroupBox: TGroupBox;
    InDocLabel: TLabel;
    InBillLabel: TLabel;
    InRetLabel: TLabel;
    InDocCountLabel: TLabel;
    InBillCountLabel: TLabel;
    InRetCountLabel: TLabel;
    DoubDocCountLabel: TLabel;
    DoubDocLabel: TLabel;
    InKartLabel: TLabel;
    InKartCountLabel: TLabel;
    InLetLabel: TLabel;
    InLetCountLabel: TLabel;
    InFileLabel: TLabel;
    InFileCountLabel: TLabel;
    RecvBankGroupBox: TGroupBox;
    AddBankCountLabel: TLabel;
    EditBankCountLabel: TLabel;
    DelBankCountLabel: TLabel;
    AddBankLabel: TLabel;
    EditBankLabel: TLabel;
    DelBankLabel: TLabel;
    BufProgressBar: TProgressBar;
    BufLabel: TLabel;
    BufSizeLabel: TLabel;
    KvitPackLabel: TLabel;
    KvitPackCountLabel: TLabel;
    ClientTimer: TTimer;
    EscOpLabel: TLabel;
    EscOpCountLabel: TLabel;
    InetBreakComboBox: TComboBox;
    InetBreakLabel: TLabel;
    ProgressBar: TProgressBar;
    AcceptLabel: TLabel;
    AcceptCountLabel: TLabel;
    AccLabel: TLabel;
    AccCountLabel: TLabel;
    HorzSplitter: TSplitter;
    FilLabel: TLabel;
    FilCountLabel: TLabel;
    AskGroupBox: TGroupBox;
    FromAskBillDateEdit: TDateEdit;
    ToAskBillDateEdit: TDateEdit;
    ToAskBillLabel: TLabel;
    AskBillCheckBox: TCheckBox;
    AskBanksCheckBox: TCheckBox;
    AskNewVerCheckBox: TCheckBox;
    FromAskBillLabel: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure MailBitBtnClick(Sender: TObject);
    procedure StepPageControlChanging(Sender: TObject;
      var AllowChange: Boolean);
    procedure ClientSocketConnect(Sender: TObject;
      Socket: TCustomWinSocket);
    procedure ClientSocketConnecting(Sender: TObject;
      Socket: TCustomWinSocket);
    procedure ClientSocketLookup(Sender: TObject;
      Socket: TCustomWinSocket);
    procedure ClientSocketRead(Sender: TObject; Socket: TCustomWinSocket);
    procedure ClientSocketError(Sender: TObject; Socket: TCustomWinSocket;
      ErrorEvent: TErrorEvent; var ErrorCode: Integer);
    procedure ClientSocketDisconnect(Sender: TObject;
      Socket: TCustomWinSocket);
    procedure FormDestroy(Sender: TObject);
    procedure ClientTimerTimer(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure HorzSplitterCanResize(Sender: TObject; var NewSize: Integer;
      var Accept: Boolean);
    procedure CloseBitBtnClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure AskBillCheckBoxClick(Sender: TObject);
  private
    procedure WMSysCommand(var Message:TMessage); message WM_SYSCOMMAND;
  public
    FirstShowMode: Integer;
    Stage: Integer;
    Step: TConnectionStep;
    ReceiveBuf, SentBuf: PChar;
    ReceiveBufLen, ReceiveDataLen, SendBufLen: Integer;
    ClientSocket: TTcbClientSocket;
    class procedure CreateChildForm(Sender: TObject);
    procedure ShowMes(S: string);
    procedure AddProto(Level: Byte; Title: PChar; S: string);
    procedure InitProgressBar(AMin, AMax: Integer);
    procedure SetProgress(APos: Integer);
    procedure NextProgress;
    procedure HideProgressBar;
    procedure AddSendBytes(I: Integer);
    function MakeObmen(BaseS, BaseR: TBtrBase): Integer;
  end;

const
  ID_CREATEENTRY = WM_USER + 10;
  ID_EDITENTRY   = WM_USER + 11;
  ID_INETCPL     = WM_USER + 12;
  ID_BEGINMAIL   = WM_USER + 13;

var
  MailForm: TMailForm = nil;
  ObjList: TList = nil;
  DLLList: TList = nil;
var
  InternetAutoDialPtr: Pointer = nil;
  InternetAutodialHangupPtr: Pointer = nil;
  RasEnumConnectionsPtr: Pointer = nil;
  RasHangUpPtr: Pointer = nil;
  RasCreatePhonebookEntryPtr: Pointer = nil;
  RasEditPhonebookEntryPtr: Pointer = nil;

procedure IncCounter(Lab: TLabel; var Counter: DWord);

implementation

{$R *.DFM}

const
{$IFDEF WINVER_0x400_OR_GREATER}
  RAS_MaxEntryName = 256;
  RAS_MaxDeviceName = 128;
  RAS_MaxCallbackNumber = RAS_MaxPhoneNumber;
{$ELSE}
  RAS_MaxEntryName = 20;
  RAS_MaxDeviceName = 32;
  RAS_MaxCallbackNumber = 48;
{$ENDIF}

type
  PHRasConn = ^THRasConn;
  HRASCONN = THandle;
  THRasConn = HRASCONN;

// Identifies an active RAS connection.  (See RasEnumConnections)

  PRasConnA = ^TRasConnA;
  PRasConnW = ^TRasConnW;
  PRasConn = PRasConnA;
  tagRASCONNA = record
    dwSize: DWORD;
    hrasconn: THRasConn;
    szEntryName: packed array[0..RAS_MaxEntryName] of AnsiChar;
{$IFDEF WINVER_0x400_OR_GREATER}
    szDeviceType: packed array[0..RAS_MaxDeviceType] of AnsiChar;
    szDeviceName: packed array[0..RAS_MaxDeviceName] of AnsiChar;
{$ENDIF}
{$IFDEF WINVER_0x401_OR_GREATER}
    szPhonebook: array[0..MAX_PATH-1] of AnsiChar;
    dwSubEntry: DWORD;
{$ENDIF}
{$IFDEF WINVER_0x500_OR_GREATER}
    guidEntry: TGUID;
{$ENDIF}
  end;
  tagRASCONNW = record
    dwSize: DWORD;
    hrasconn: THRasConn;
    szEntryName: packed array[0..RAS_MaxEntryName] of WideChar;
  {$IFDEF WINVER_0x400_OR_GREATER}
    szDeviceType: packed array[0..RAS_MaxDeviceType] of WideChar;
    szDeviceName: packed array[0..RAS_MaxDeviceName] of WideChar;
  {$ENDIF}
  {$IFDEF WINVER_0x401_OR_GREATER}
    szPhonebook: array[0..MAX_PATH-1] of WideChar;
    dwSubEntry: DWORD;
  {$ENDIF}
  {$IFDEF WINVER_0x500_OR_GREATER}
    guidEntry: TGUID;
  {$ENDIF}
  end;
  tagRASCONN = tagRASCONNA;
  TRasConnA = tagRASCONNA;
  TRasConnW = tagRASCONNW;
  TRasConn = TRasConnA;
  RASCONNA = tagRASCONNA;
  RASCONNW = tagRASCONNW;
  RASCONN = RASCONNA;
const
  INTERNET_AUTODIAL_FORCE_ONLINE          = 1;

// Enumerates intermediate states to a connection.  (See RasDial)

type
  TRasEnumConnections =
    function (lprasconn: PRasConn; var lpcb: DWORD;
      var pcConnections: DWORD): DWORD; stdcall;
  TRasHangUp =
    function(hrasconn: THRasConn): DWORD; stdcall;
  TInternetAutodial =
    function(dwFlags: DWORD; dwReserved: DWORD): BOOL; stdcall;
  TInternetAutodialHangup =
    function(dwReserved: DWORD): BOOL; stdcall;
  TRasCreatePhonebookEntry =
    function(hwnd: HWND; lpszPhonebook: PChar): DWORD; stdcall;
  TRasEditPhonebookEntry =
    function(hwnd: HWND; lpszPhonebook: PChar; lpszEntryName: PChar): DWORD; stdcall;

procedure TTcbClientSocket.Error(Socket: TCustomWinSocket; ErrorEvent: TErrorEvent;
  var ErrorCode: Integer);
begin
  //showmessage('aaa: '+inttostr(ErrorCode));
  if Assigned(OnError) then OnError(Self, Socket, ErrorEvent, ErrorCode);
  ErrorCode := 0;
  //inherited;
end;

function IsWinNt: Boolean;
begin
  Result := (GetVersion and $80000000) = 0;
end;

class procedure TMailForm.CreateChildForm(Sender: TObject);
const
  MesTitle: PChar = 'Обмен с банком';
begin
  if IsSanctAccess('PostSanc') then
  begin
    if MailForm<>nil then
    begin
      MailForm.Show;
      if Sender=nil then
        PostMessage(MailForm.Handle, WM_SYSCOMMAND, ID_BEGINMAIL, 555);
    end
    else begin
      MailForm := TMailForm.Create(Application);
      ObjList.Add(MailForm);
      with MailForm do
      begin
        FirstShowMode := 0;
        if (Sender=nil) or (Sender=Application) then
        begin
          if Sender=nil then
            FirstShowMode := 1;
          Position := poDefault;
          FormStyle := fsMDIChild;
          Show;
          PostMessage(Handle, WM_SYSCOMMAND, ID_BEGINMAIL, 555);
        end
        else begin
          //Position := poScreenCenter;
          ShowModal;
          Free;
        end;
      end;
    end;
  end
  else
    MessageBox(Application.Handle, 'Вы не можете проводить сеанс связи',
      MesTitle, MB_OK or MB_ICONINFORMATION);
end;

procedure TMailForm.WMSysCommand(var Message: TMessage);
var
  Buf: array [0..511] of Char;
  HelpWinInfo: THelpWinInfo;
  Wnd: hWnd;

  procedure Pause;
  begin
    Application.ProcessMessages;
    Sleep(300);
    Application.ProcessMessages;
  end;

begin
  case Message.wParam of
    ID_CREATEENTRY:
      if RasCreatePhonebookEntryPtr<>nil then
      begin
        Application.HelpCommand(HELP_CONTEXT, 180);
        Pause;
        FillChar(HelpWinInfo, SizeOf(HelpWinInfo), #0);
        with HelpWinInfo do
        begin
          x := 1;
          y := 1;
          dx := 2;
          dy := 2;
          wStructSize := SizeOf(HelpWinInfo);
          wMax := SW_MINIMIZE;
        end;
        Application.HelpCommand(HELP_SETWINPOS, Integer(@HelpWinInfo));
        Pause;
        TRasCreatePhonebookEntry(RasCreatePhonebookEntryPtr)(Handle, nil);
        Pause;
        Wnd := Application.Handle;
        ShowWindow(Wnd, SW_SHOW);
        PostMessage(Wnd, WM_ACTIVATEAPP, 1, 0);
        SetForegroundWindow(Wnd);
      end;
    ID_EDITENTRY:
      if RasEditPhonebookEntryPtr<>nil then
        TRasEditPhonebookEntry(RasEditPhonebookEntryPtr)(Handle, nil, 'tcb');
    ID_INETCPL:
      begin
        GetWindowsDirectory(Buf, SizeOf(Buf));
        if (StrLen(Buf)>0) and (Buf[StrLen(Buf)-1]='\') then
          Buf[StrLen(Buf)-1] := #0;
        StrLCat(Buf, '\control.exe', SizeOf(Buf));
        if not FileExists(Buf) then
          Buf := 'control';
        StrLCat(Buf, ' inetcpl.cpl,,4', SizeOf(Buf));
        if IsWinNt then
          Buf[StrLen(Buf)-1] := '3';
        WinExec(Buf, sw_ShowNormal);
      end;
    ID_BEGINMAIL:
      begin
        if Message.LParam=555 then
          MailBitBtnClick(nil);
      end;
  end;
  inherited;
end;

const
  piProgress = 0;
  piMes = 1;

procedure TMailForm.ShowMes(S: string);
begin
  StatusBar.Panels[piMes].Text := S;
  Application.ProcessMessages;
end;

procedure TMailForm.AddProto(Level: Byte; Title: PChar; S: string);
begin
  ProtoMes(Level, Title, S);
  if Level<plInfo then
    S := LevelToStr(Level)+': '+S;
  ProtoMemo.Lines.Add(S);
  //Application.ProcessMessages;
end;

var
  CheckSendFirst: Boolean;
  WaitHostTimeOut, ReceiverPort, ReceiverNode, PackSize: Integer;
  SenderAcc, ReceiverAcc, ReceiverURL: string;
  lcSendPack, lcRecvPack, lcRecvKvit, lcSendByte, lcRecvByte: dWord;

var
  BaseSend: TBtrBase = nil;
  BaseRecv: TBtrBase = nil;
  VersionNum: LongWord = 0;
  UpdateAfterMail: Boolean = False;
  MesDelay: Integer = 10;
  CheckNewLet: Integer = 0;
  TraceMode: Integer = 0;
  SmallBufSize: Integer = 0;
  MasterKeyUpdate: Boolean;                                //Добавлено Меркуловым
  KeyUpdDate: Word;                                        //Добавлено Меркуловым

procedure TMailForm.FormCreate(Sender: TObject);
const
  MesTitle: PChar = 'Сеанс связи';
var
  SysMenu: THandle;
  T: array[0..1023] of Char;
  HangUpMode: Integer;
begin
  FirstShowMode := 0;
  ClientSocket := TTcbClientSocket.Create(Self);
  with ClientSocket do
  begin
    OnLookup := ClientSocketLookup;
    OnConnecting := ClientSocketConnecting;
    OnConnect := ClientSocketConnect;
    OnDisconnect := ClientSocketDisconnect;
    OnRead := ClientSocketRead;
    OnError := ClientSocketError;
  end;

  VersionNum := GetVersionNum;
  SysMenu := GetSystemMenu(Handle, False);
  InsertMenu(SysMenu, Word(-1), MF_SEPARATOR, 0, '');
  InsertMenu(SysMenu, Word(-1), MF_BYPOSITION, ID_CREATEENTRY, '&Создать учетную запись...');
  InsertMenu(SysMenu, Word(-1), MF_BYPOSITION, ID_EDITENTRY, '&Настроить учетную запись...');
  InsertMenu(SysMenu, Word(-1), MF_SEPARATOR, 0, '');
  InsertMenu(SysMenu, Word(-1), MF_BYPOSITION, ID_INETCPL, '&Настройка подключения...');
  Stage := -1;
  Step := csEnter;
  ReceiveBuf := nil;
  ReceiverURL := 'www.transcapbank.perm.ru';
  BufProgressBar.Position := 0;
  BufProgressBar.Max := MaxPostBufSize;
  ReceiveBufLen := 0;
  SentBuf := nil;
  SendBufLen := 0;
  BaseSend := nil;
  BaseRecv := nil;
  IsUsedNewKey := True;
  if not GetRegParamByName('ProtoLevel', CommonUserNumber, TraceMode) then
    TraceMode := 0;
  if TraceMode<plTrace then
    TraceMode := 0;
  if not GetRegParamByName('SmallBufSize', CommonUserNumber, SmallBufSize) then
    SmallBufSize := 0;
  if not GetRegParamByName('NumOfSign', CommonUserNumber, NumOfSign) then
    NumOfSign := 0;
  if GetMainCryptoEngineIndex=ceiDomenK then
  begin
    if IsSanctAccess('PostSanc') then
    begin
      if GetRegParamByName('SenderAcc', CommonUserNumber, T) then
        SenderAcc := StrPas(@T)
      else
        SenderAcc := '';
      SenderAcc := GetSelfLogin(SenderAcc);
      if GetRegParamByName('ReceiverAcc', CommonUserNumber, T) then
        ReceiverAcc := StrPas(@T)
      else
        ReceiverAcc := '';
      if GetRegParamByName('ReceiverURL', CommonUserNumber, T) then
        ReceiverURL := StrPas(@T);
      if not GetRegParamByName('ReceiverNode', CommonUserNumber, ReceiverNode) then
        ReceiverNode := 0;
      if not GetRegParamByName('ReceiverPort', CommonUserNumber, ReceiverPort) then
        ReceiverPort := 10000;
      if not GetRegParamByName('WaitHost', CommonUserNumber, WaitHostTimeOut) then
        WaitHostTimeOut := 0;
      if not GetRegParamByName('PackSize', CommonUserNumber, PackSize) then
        PackSize := 4096;
      if not GetRegParamByName('CheckSendFirst', CommonUserNumber, CheckSendFirst) then
        CheckSendFirst := True;
      if not GetRegParamByName('HangUpMode', CommonUserNumber, HangUpMode) then
        HangUpMode := 2;
      if not GetRegParamByName('UpdateAfterMail', CommonUserNumber, UpdateAfterMail) then
        UpdateAfterMail := False;
      if not GetRegParamByName('MesDelay', CommonUserNumber, MesDelay) then
        MesDelay := 10;
      //Добавлено Меркуловым
      if not GetRegParamByName('MasterKeyUpdate', CommonUserNumber, MasterKeyUpdate) then
        MasterKeyUpdate := False;
      if not GetRegParamByName('KeyUpdDate', CommonUserNumber, KeyUpdDate) then
        KeyUpdDate := StrToBtrDate('18.05.2004');
      //Конец
      Stage := 0;
      {if (Length(ReceiverURL)>0) and (ReceiverURL[1] in ['0'..'9']) then
      begin
        ClientSocket.Host := '';
        ClientSocket.Address := ReceiverURL;
      end
      else begin
        ClientSocket.Address := '';
        ClientSocket.Host := ReceiverURL;
      end;}
      InetBreakComboBox.ItemIndex := HangUpMode;           //Добавлено Меркловым
      ClientSocket.Port := ReceiverPort;
      BaseSend := TBtrBase.Create;
      BaseRecv := TBtrBase.Create;
      FillChar(PackControlData, SizeOf(PackControlData), #0);
      with PackControlData do
      begin
        StrPLCopy(cdTagLogin, ReceiverAcc, SizeOf(cdTagLogin)-1);
        cdTagNode := ReceiverNode;
      end;
      IsUsedNewKey := IsKeyNew;
    end
    else
      AddProto(plWarning, MesTitle, 'Вы не можете проводить сеанс связи');
  end
  else
    AddProto(plWarning, MesTitle, 'СКЗИ не инициализировано ('
      +IntToStr(GetMainCryptoEngineIndex));
  MailBitBtn.Enabled := Stage=0;
  ProgressBar.Parent := StatusBar;
  lcSendPack := 0;
  lcRecvPack := 0;
  lcRecvKvit := 0;
  lcSendByte := 0;
  lcRecvByte := 0;
  if not GetRegParamByName('CheckNewLet', CommonUserNumber, CheckNewLet) then
    CheckNewLet := 2;
  piBills := 0;
  piRets := 0;
  piKarts := 0;
  piDelBills := 0;
  piDocs := 0;
  piDoubles := 0;
  piLetters := 0;
  piAccStates := 0;
  piAccepts := 0;
  piDelBanks := 0;
  piAddBanks := 0;
  piEditBanks := 0;
  piFiles := 0;
  piSFile := 0;                                             //Добавлено
  piLFile := 0;                                             //Добавлено
  AskBillCheckBoxClick(nil);
end;

procedure TMailForm.InitProgressBar(AMin, AMax: Integer);
const
  Border=2;
var
  X: Integer;
begin
  StatusBar.Panels[piProgress].Width := ProgressBar.Width+Border;
  with ProgressBar do
  begin
    X := Border;
    {for I := 0 to piProgress-1 do
      X := X+StatusBar.Panels[I].Width;}
    SetBounds(X, Border, Width, StatusBar.Height - Border);
    try
      Min := 0;
      Position := 0;
      Max := AMax;
      Min := AMin;
      Position := Min;
    except
    end;
    Show;
  end;
end;

procedure TMailForm.SetProgress(APos: Integer);
begin
  with ProgressBar do
  begin
    if Min<APos then
      APos := Min;
    if APos>Max then
      APos := Max;
    Position := APos;
  end;
end;

procedure TMailForm.NextProgress;
begin
  SetProgress(ProgressBar.Position+1);
end;

procedure TMailForm.HideProgressBar;
begin
  ProgressBar.Hide;
  StatusBar.Panels[piProgress].Width := 0;
end;

procedure IncCounter(Lab: TLabel; var Counter: DWord);
var
  S: TFontStyles;
begin
  Inc(Counter);
  Lab.Caption := IntToStr(Counter);
  if not(fsBold in Lab.Font.Style) then
  begin
    S := Lab.Font.Style;
    Include(S, fsBold);
    Lab.Font.Style := S;
  end;
end;

var
  Process: Boolean = False;

function OpenSendBase: Boolean;
const
  MesTitle: PChar = 'Открытие базы исходящих пакетов';
var
  Res: Integer;
  FN: string;
begin
  if BaseSend.Active then
    Res := 0
  else begin
    FN := PostDir+'doc_s.btr';
    MailForm.ShowMes(StrPas(MesTitle)+'...');
    Res := BaseSend.Open(FN, baNormal);
    MailForm.ShowMes('');
    if Res<>0 then
      MailForm.AddProto(plError, MesTitle, PChar('Не могу открыть базу '
        +FN+' BtrErr='+IntToStr(Res)));
  end;
  Result := Res=0;
end;

function OpenRecvBase: Boolean;
const
  MesTitle: PChar = 'Открытие базы входящих пакетов';
var
  Res: Integer;
  FN: string;
begin
  if BaseRecv.Active then
    Res := 0
  else begin
    FN := PostDir+'doc_r.btr';
    MailForm.ShowMes(StrPas(MesTitle)+'...');
    Res := BaseRecv.Open(FN, baNormal);
    MailForm.ShowMes('');
    if Res<>0 then
      MailForm.AddProto(plError, MesTitle, PChar('Не могу открыть базу '
        +FN+' BtrErr='+IntToStr(Res)));
  end;
  Result := Res=0;
end;

procedure RefreshAllBases;
var
  AccDataSet, DocDataSet, BankDataSet, EMailDataSet: TExtBtrDataSet;
begin
  try
    DocDataSet := GlobalBase(biPay);
    AccDataSet := GlobalBase(biAcc);
    EMailDataSet := GlobalBase(biLetter);
    BankDataSet := GlobalBase(biBank);

    DocDataSet.Refresh;
    AccDataSet.Refresh;
    EMailDataSet.Refresh;
    BankDataSet.Refresh;
  except
    ProtoMes(plError, 'Обновление состояния баз', PChar('Ошибка Refresh'));
  end;
end;

procedure TMailForm.MailBitBtnClick(Sender: TObject);
const
  MesTitle: PChar = 'Обмен с банком';
var
  L: Integer;
  GoNext: Boolean;
  S: string;

  procedure AddMes(var S: string; N, V: string);
  begin
    if V<>'0' then
    begin
      if Length(S)>0 then
        S := S+'; ';
      S := S+N+'-'+V;
    end;
  end;

begin
  if Process then
  begin
    Process := False;
    MailBitBtn.Enabled := False;
    //AddProto(plTrace, nil, 'Прекращение процесса');
    ShowMes('Прекращение процесса...');
  end
  else
    if MailBitBtn.Enabled and (Stage>=0) and (Stage<=3) then
    begin
      MailBitBtn.Caption := '&Прервать';
      CloseBitBtn.Caption := '&Закрыть';
      CloseBitBtn.Enabled := False;
      Process := True;
      GoNext := True;
      while (Stage>=0) and (Stage<=3) and Process and GoNext do
      begin
        GoNext := False;
        case Stage of
          0:  {проверка старых пакетов, подготовка новых}
            begin
              InitProgressBar(0, 10);
              StepPageControl.ActivePage := PrepareTabSheet;
              L := Length(SenderAcc);
              if (L>0) and (L<=8) then
              begin
                L := Length(ReceiverAcc);
                if (L>0) and (L<=8) then
                begin
                  if (PackSize>30) and (PackSize<MaxPackSize) then
                  begin
                    Screen.Cursor := crHourGlass;
                    poSum := 0;
                    poDocs := 0;
                    poLetters := 0;
                    poFiles := 0;
                    if OpenSendBase then
                    begin
                      ShowMes('Проверка ранее отправленных пакетов...');
                      GetSentDoc(BaseSend,
                        SenderAcc, ReceiverAcc, Process, CheckSendFirst);
                      NextProgress;
                      if Process then
                      begin
                        S := '';
                        if Sender<>nil then
                        begin
                          ShowMes('Формирование пакетов на отправку...');
                          SendDoc(BaseSend, SenderAcc, ReceiverAcc, Process, PackSize);
                          if poDocs>0 then
                          begin
                            AddMes(S, 'док', IntToStr(poDocs));
                            AddMes(S, 'сум', SumToStr(poSum));
                          end;
                          AddMes(S, 'пис', IntToStr(poLetters));
                          AddMes(S, 'ф-л', IntToStr(poFiles));     //Добавлено Меркуловым
                        end;
                        if Length(S)>0 then
                          AddProto(plInfo, MesTitle, 'Подготовлено на отправку: '+S)
                        else
                          AddProto(plTrace, MesTitle, 'Нет данных для отправки, будет только прием');
                        //Добавлено Меркуловым
                        (*if MasterKeyUpdate and (Date>=BtrDateToDate(KeyUpdDate)) and ((poDocs>0) or
                          (poLetters>0) or (poFiles>0)) then
                          MessageBox(ParentWnd,'В связи со сменой мастер-ключа отправлять документы нельзя!!!'
                            +#10#13+'Пожалуйста, отмените связь, снимите подпись с документов или файлов, '
                            +#10#13+'произведите сеанс связи и перезапустите Клиент-Банк',MesTitle,MB_OK);*)
                        //Конец
                        NextProgress;
                        ShowMes('');
                        if Process then
                          Stage := 1;
                      end;
                      //StepPageControl.ActivePage := ExchangeTabSheet;
                    end;
                  end
                  else
                    ProtoMes(plError, MesTitle, PChar('Размер пакета некорректен '
                      +IntToStr(PackSize)));
                end
                else
                  ProtoMes(plError, MesTitle, PChar('Длина позывного получателя неверна L='
                    +IntToStr(L)));
              end
              else
                ProtoMes(plError, MesTitle, PChar('Длина позывного отправителя неверна L='
                  +IntToStr(L)));
            end;
          1:  {проведение сеанса связи}
            begin
              StepPageControl.ActivePage := ExchangeTabSheet;
              if OpenRecvBase then
              begin
                ShowMes('Проведение сеанса связи...');
                L := MakeObmen(BaseSend, BaseRecv);
                if L>2 then
                begin
                  if L>3 then
                    Stage := 3
                  else
                    Stage := 2;
                  GoNext := True;
                end;
                ShowMes('');
              end;
            end;
          2,3:
            begin
              StepPageControl.ActivePage := ReceiveTabSheet;
              if OpenSendBase then
              begin
                ShowMes('Проверка отправленных пакетов...');
                GetSentDoc(BaseSend,
                  SenderAcc, ReceiverAcc, Process, True);
                if Process and (Stage>2) then
                  Inc(Stage);
                NextProgress;
                ShowMes('');
              end
              else
                AddProto(plWarning, MesTitle, 'Не удалось проверить отправленные пакеты. База закрыта');
              if Stage>2 then
              begin
                if OpenRecvBase then
                begin
                  ShowMes('Обработка полученных пакетов...');
                  LastDaysDate := GetLastClosedDay;
                  FirstDocDate := $FFFF;
                  OldDocCount := 0;
                  ReceiveDoc(BaseRecv, ReceiverAcc, Process);
                  NextProgress;
                  if Process then
                  begin
                    ShowMes('Обработка полученных фрагментов файлов...');
                    GenerateFiles(Process);
                  end;
                  NextProgress;
                  if Process then
                    Inc(Stage);
                  ShowMes('');
                  if OldDocCount>0 then
                    MessageBox(Application.Handle,
                      PChar('Получены документы за уже закрытые дни - '
                      +IntToStr(OldDocCount)+#13#10
                      +'Последний закрытый день '+BtrDateToStr(LastDaysDate)
                      +#13#10'Необходимо раскрыть операционные дни до '
                      +BtrDateToStr(FirstDocDate)), MesTitle,
                      MB_OK or MB_ICONWARNING);
                  if UpdateAfterMail then
                    PostMessage(Application.MainForm.Handle, WM_MAKEUPDATE, 0, 0);
                end
                else
                  AddProto(plError, MesTitle, 'Не удалось проверить принятые пакеты. База закрыта');
              end;
              ShowMes('Обновление состояния баз...');
              RefreshAllBases;
              ShowMes('');
            end;
        end;
      end;
      if Process then
      begin
        if Stage=1 then
          ShowMes('Нажмите "Начать" для начала обмена');
      end
      else
        ShowMes('Процесс прерван');
      Screen.Cursor := crDefault;
      if (Stage<0) or (Stage>=3) then
      begin
        if BaseSend<>nil then
        begin
          if BaseSend.Active then
            BaseSend.Close;
        end;
        if BaseRecv<>nil then
        begin
          if BaseRecv.Active then
            BaseRecv.Close;
        end;
      end;
      MailBitBtn.Caption := '&Начать';
      CloseBitBtn.Enabled := True;
      if Stage=5 then
      begin
        //Добавлено Меркуловым
        if MasterKeyUpdate and (Date>=BtrDateToDate(KeyUpdDate)) then
        begin
          if not SetRegParamByName('MasterKeyUpdate', CommonUserNumber, False, 'False') then
            MessageBox(ParentWnd,'Не удалось переключится на новые ключи.'+#10#13+
              'Позвоните в отдел ИТ ТрансКапиталБанка',MesTitle,MB_OK or MB_ICONERROR)
          else
            MessageBox(ParentWnd,'Пожалуйста, перезапустите Клиент-Банк!'+#10#13+
              'Будет произведена замена ключей на ключевых дисках!',MesTitle,MB_OK or MB_ICONWARNING)
        end;
        //Конец
        HideProgressBar;
        MailBitBtn.Enabled := False;
        ShowMes('Обмен успешно завершен');
        CloseBitBtn.SetFocus;
      end
      else begin
        MailBitBtn.Enabled := True;
        if Stage>2 then
        begin
          Stage := 0;
          HideProgressBar;
        end;
      end;
      Process := False;
      if (Sender=nil) and (Stage=5) then
      begin
        if (piBills>0) or (piRets>0) or (piDelBills>0) or (piKarts>0)
          or (piDocs>0) or (piDoubles>0) or (piLetters>0) or (piAccStates>0)
          {or (piAccepts>0) or (piDelBanks>0) or (piAddBanks>0) or (piEditBanks>0)}
          or (piFiles>0) or (piSFile>0) or (piLFile>0)
        then
          PostMessage(Application.MainForm.Handle, WM_SYSCOMMAND, SC_BANKCLCOMMAND, bccDoAnimateIcon)
        else
          Close;
      end;
    end;
end;

var
  TimePeriod: DWord = 0;
  IdleTimePeriod: DWord = 0;

const
  SockTitle: PChar = 'Socket';

var
  ConnectState: Integer = 0;
  AchiveStep: TConnectionStep = csEnter;
const
  BreakWaitSec = 5;

function TMailForm.MakeObmen(BaseS, BaseR: TBtrBase): Integer;
const
  MesTitle: PChar = 'Сеанс связи';
var
  I: Integer;
  Ras: packed array[0..20] of RASCONN;
  dSize, dNumber, dwRet: DWord;
  PtrRasConn: HRASCONN;
  HostEnt: PHostEnt;
  HostIP: packed array[0..3] of Byte;
begin
  Result := -1;
  AddProto(plTrace, MesTitle, 'Попытка установить соединение...');
  if (InternetAutoDialPtr=nil)
    or (TInternetAutoDial(InternetAutoDialPtr)(INTERNET_AUTODIAL_FORCE_ONLINE, 0)) then
  begin
    Result := 0;
    AchiveStep := csEnter;
    Step := csEnter;
    ConnectState := 1;
    TimePeriod := 0;
    IdleTimePeriod := 0;
    {S := ClientSocket.Host;
    if Length(S)=0 then
      S := '['+ClientSocket.Address+']';
    AddProto(plTrace, MesTitle, 'Соединяюсь с '+S+'...');}
    try
      ClientSocket.ClientType := ctNonBlocking;
      if (Length(ReceiverURL)>0) and (ReceiverURL[1] in ['0'..'9']) then
      begin
        ClientSocket.Host := '';
        ClientSocket.Address := ReceiverURL;
      end
      else begin
        ClientSocket.Host := '';
        ClientSocket.Address := '';
        ShowMes('Поиск адреса хоста '+ReceiverURL+'...');
        HostEnt := GetHostByName(PChar(ReceiverURL));
        if HostEnt=nil then
        begin
          Result := -2;
          I := WSAGetLastError;
          AddProto(plInfo, MesTitle, 'Не удалось получить адрес хоста '
            +ReceiverURL+' ('+IntToStr(I)+')');
        end
        else begin
          I := SizeOf(HostIP);
          FillChar(HostIP, I, #0);
          with HostEnt^ do
          begin
            if h_length<I then
              I := h_length;
            Move(h_addr^[0], HostIP, I);
          end;
          ClientSocket.Address := IntToStr(HostIP[0])+'.'+IntToStr(HostIP[1])
            +'.'+IntToStr(HostIP[2])+'.'+IntToStr(HostIP[3]);
        end;
      end;
      if (Result=0) and Process then
      begin
        ShowMes('Подключение к хосту '+ClientSocket.Address+'...');
        try
          //showmessage('1');
          try
            ClientSocket.Active := True;
            //ClientSocket.ClientType := ctNonBlocking;
            ShowMes('Проведение обмена данными...');
            //showmessage('2');
            while (ConnectState>0) and Process do
            begin
              Sleep(MesDelay);
              Application.ProcessMessages;
            end;
            if (ConnectState>1) and not Process then
            begin
              I := BreakWaitSec*1000;
              while ClientSocket.Active and (I>0) do
              begin
                ShowMes('Ждем еще '+IntToStr(I div 1000+1)+' секунд...');
                //Application.ProcessMessages;
                Sleep(MesDelay);
                I := I-MesDelay;
              end;
              ShowMes('');
            end;
          except
            on E: Exception do
              AddProto(plWarning, MesTitle, 'Ошибка связи ['+E.Message+']');
          end;
        finally
          ClientTimer.Enabled := False;
          if ClientSocket.Active then
            ClientSocket.Active := False;
          ClientTimerTimer(nil);
          if AchiveStep>=csAuth1 then
          begin
            AddProto(plInfo, MesTitle, 'Длительность сеанса '
              +TimeCountLabel.Caption+', трафик '+IntToStr(lcSendByte+lcRecvByte));
            if (AchiveStep<csAuth3) and Process then
              AddProto(plWarning, MesTitle, 'Были ошибки авторизации')
            else
              if AchiveStep<csData then
                AddProto(plTrace, MesTitle, 'Обмен не был полностью завершен')
              else
                AddProto(plTrace, MesTitle, 'Обмен успешно завершен');
          end
          else
            AddProto(plWarning, MesTitle, 'Не удалось установить соединение');
        end;
      end
      else
        if not Process then
          AddProto(plTrace, MesTitle, 'Попытка соединения прервана');
    except
      AddProto(plTrace, MesTitle, 'Были ошибки соединения');
    end;
    I := InetBreakComboBox.ItemIndex;
    case I of
      1..3:   {Спросить 1   По ситуации 2   Всегда 3}
        begin
          dNumber := 0;
          if RasEnumConnectionsPtr<>nil then
          begin
            Ras[0].dwSize := SizeOf(RASCONN);
            dSize := SizeOf(Ras);
            dwRet := TRasEnumConnections(RasEnumConnectionsPtr)(@Ras, dSize, dNumber);
            if (dwRet=0) and (dNumber>0) then
            begin
              case I of
                1:
                  if MessageBox(Application.Handle,
                    'Разорвать удаленное соединение?',  MesTitle,
                    MB_YESNOCANCEL or MB_ICONQUESTION)<>ID_YES
                  then
                    dNumber := 0;
                2:
                  if (AchiveStep<csData) and (MessageBox(Application.Handle,
                    'Обмен не был полностью завершен'#13#10
                    +'Разорвать удаленное соединение?',  MesTitle,
                    MB_YESNOCANCEL or MB_ICONQUESTION)<>ID_YES)
                  then
                    dNumber := 0;
              end;
            end
            else
              dNumber := 0
          end;
          if RasHangUpPtr<>nil then
            for I := 0 to dNumber-1 do
            begin
              PtrRasConn := Ras[I].hrasconn;
              dwRet := TRasHangUp(RasHangUpPtr)(PtrRasConn);
              if dwRet=0 then
                AddProto(plTrace, MesTitle, 'Соединение ['
                  +Ras[I].szEntryName+'] разорвано')
              else
                MessageBox(Application.Handle,
                  PChar('Не удалось разорвать соединение ['
                  +Ras[I].szEntryName+']'), MesTitle, MB_OK or MB_ICONWARNING)
          end;
        end;
      4:
        if InternetAutodialHangupPtr<>nil then
          TInternetAutoDialHangUp(InternetAutodialHangupPtr)(0);
    end;
    Result := Ord(AchiveStep);
  end
  else
    AddProto(plTrace, MesTitle, 'Соединение не было установлено');
end;

procedure TMailForm.StepPageControlChanging(Sender: TObject;
  var AllowChange: Boolean);
begin
  AllowChange := not Process;
end;

procedure TMailForm.ClientSocketLookup(Sender: TObject;
  Socket: TCustomWinSocket);
begin
  //ShowMes('Поиск хоста...');
  IdleTimePeriod := 0;
end;

procedure TMailForm.ClientSocketConnecting(Sender: TObject;
  Socket: TCustomWinSocket);
begin
  IdleTimePeriod := 0;
  ConnectState := 2;
  //ShowMes('Установка соединения с хостом...');
end;

function GetNextSendPack(var Buf: PChar; var LastNum: Integer): Integer;
var
  Res, Len: Integer;
  SndPack: TSndPack;
  Key0: packed record
    kFlSnd: Char;
    kNum: Longint;
  end;
begin
  Result := 0;
  Len := SizeOf(SndPack);
  Key0.kFlSnd := '0';
  Key0.kNum := LastNum;
  Res := BaseSend.GetGT(SndPack, Len, Key0, 1);
  if (Res=0) and (Key0.kFlSnd='0') and (Len>0) then
  begin
    LastNum := Key0.kNum;
    if SndPack.spFlSnd='0' then
    begin
      Buf := AllocMem(Len);
      Move(SndPack, Buf^, Len);
      Result := Len;
    end;
  end;
end;

function SetSendPack(Num, Ider: Integer): Integer;
var
  Len: Integer;
  SndPack: TSndPack;
  Key0: packed record
    kFlSnd: Char;
    kNum: Longint;
  end;
begin
  Len := SizeOf(SndPack);
  Key0.kFlSnd := '0';
  Key0.kNum := Num;
  Result := BaseSend.GetEqual(SndPack, Len, Key0, 1);
  if Result=0 then
  begin
    SndPack.spIder := Ider;
    SndPack.spFlSnd := '2';
    Result := BaseSend.Update(SndPack, Len, Key0, 1);
  end;
end;

function InsertPack(Buf: PChar; BufLen: Integer): Integer;
const
  MesTitle: PChar = 'Вставка входящего пакета';
var
  Res: Integer;
  NameS: TAbonLogin;
begin
  Res := SizeOf(TRcvPack);
  if (BufLen>Res-MaxPackSize) and (BufLen<=Res) then
  begin
    Result := PSndPack(Buf)^.spIder;
    if Result>0 then
    begin
      Res := BaseRecv.Insert(Buf^, BufLen, NameS, 1);
      if Res<>0 then
      begin
        if Res=5 then
        begin
          MailForm.AddProto(plInfo, MesTitle,
            'Получен дубликат пакета Id='+IntToStr(Result));
          Result := 0;
        end
        else begin
          MailForm.AddProto(plError, MesTitle,
            'Ошибка записи пакета Id='+IntToStr(Result)+' BtrErr='+IntToStr(Res));
          Result := -3;
        end;
      end;
    end
    else begin
      MailForm.AddProto(plError, MesTitle, 'Идер пакета не положительный Id='
        +IntToStr(Result));
      Result := -2;
    end;
  end
  else begin
    Result := -1;
    MailForm.AddProto(plWarning, MesTitle, 'Пакет недопустимой длины пропущен L='
      +IntToStr(BufLen)+' ['+IntToStr(Res-MaxPackSize)+'..'+IntToStr(Res)+']');
  end;
end;

function SetRcvPack(Ider: LongWord; DateR: Word; TimeR: Word): Integer;
var
  Len: Integer;
  SndPack: TSndPack;
begin
  Len := SizeOf(SndPack);
  Result := BaseSend.GetEqual(SndPack, Len, Ider, 2);
  if Result=0 then
  begin
    with SndPack do
    begin
      spFlRcv := '1';
      spDateR := DateR;
      spTimeR := TimeR;
    end;
    Result := BaseSend.Update(SndPack, Len, Ider, 2);
    if Result<>0 then
      Result := Result+100;
  end;
end;

var
  SendDataMode: Integer = eccSendData;
  LastSendPackID: Integer = 0;
  LastAuthIder: Integer = 0;

procedure TMailForm.AddSendBytes(I: Integer);
begin
  if I>0 then
  begin
    Inc(lcSendByte, I);
    SendBytesCountLabel.Caption := IntToStr(lcSendByte);
    //Application.ProcessMessages;
  end;
end;

var
  TakeMes: Boolean = False;
  Processing: Boolean = False;

procedure TMailForm.ClientSocketConnect(Sender: TObject;
  Socket: TCustomWinSocket);
var
  S, V: string;
begin
  AchiveStep := csAuth1;
  Processing := False;
  ConnectState := 3;
  AddProto(plInfo, SockTitle, 'Соединение с хостом '+Socket.RemoteAddress
    +' установлено');
  TimePeriod := 0;
  IdleTimePeriod := 0;
  ClientTimer.Enabled := True;
  if ReceiveBuf<>nil then
  begin
    FreeMem(ReceiveBuf);
    ReceiveBuf := nil;
  end;
  ReceiveBufLen := 0;
  ReceiveDataLen := 0;
  if SentBuf<>nil then
  begin
    FreeMem(SentBuf);
    SentBuf := nil;
  end;
  SendBufLen := 0;

  BufProgressBar.Position := 0;
  BufProgressBar.Show;
  BufSizeLabel.Caption := '0';

  LastSendPackID := 0;
  SendDataMode := eccSendData;

  LastAuthIder := GetRegNumber(rnAuth)+1;
  if IsUsedNewKey then
  begin
    if MasterKeyUpdate then              //Добавлено Меркуловым
      V := 'v3'
    else                                 //Добавлено Меркуловым
      V := 'vZ';                         //Добавлено Меркуловым
  end
  else
    V := 'v2';
  S := SenderAcc+Format(' '+V+' l%x h%x n%u', [LastAuthIder,
    GetHddPlaceId(BaseDir),VersionNum])+#13;
  Socket.SendText(S);
  AddSendBytes(Length(S));
end;

function SendComAndBuf(Socket: TCustomWinSocket; Comnd: TExchangeCommand;
  Buf: PChar; BufLen: Integer): Boolean;
var
  I, J: Integer;
begin
  if TraceMode>0 then
    MailForm.AddProto(TraceMode, SockTitle, 'ОтпКом '+IntToStr(Comnd.cmCommand)
      +'/'+IntToStr(Comnd.cmParam)+' BL='+IntToStr(BufLen));
  CodeExchangeCommand(Comnd);
  I := Socket.SendBuf(Comnd, SizeOf(TExchangeCommand));
  Result := I=SizeOf(TExchangeCommand);
  MailForm.AddSendBytes(I);
  if (Buf<>nil) and (BufLen>0) and Result then
  begin
    if SmallBufSize<=0 then
      I := Socket.SendBuf(Buf^, BufLen)
    else begin
      I := 0;
      J := 1;
      while (I<BufLen) or (J=0) do
      begin
        J := SmallBufSize;
        if J>BufLen-I then
          J := BufLen-I;
        J := Socket.SendBuf(Buf[I], J);
        I := I+J;
        Sleep(5);
        Application.ProcessMessages;
        Sleep(10);
      end;
    end;
    Result := I=BufLen;
    MailForm.AddSendBytes(I);
  end;
  IdleTimePeriod := 0;
end;

procedure TMailForm.ClientSocketRead(Sender: TObject;
  Socket: TCustomWinSocket);
var
  I, J: Integer;
  Cmnd: TExchangeCommand;
  Buf: PChar;
begin
  IdleTimePeriod := 0;
  I := Socket.ReceiveLength;
  if (ReceiveBufLen+I<=MaxPostBufSize) and (Step<>csError) then
  begin
    try
      ReallocMem(ReceiveBuf, ReceiveBufLen+I);
    except
      Step := csError;
      AddProto(plError, SockTitle, 'Ошибка увеличения буфера чтения');
    end;
    if Step<>csError then
    try
      I := Socket.ReceiveBuf(ReceiveBuf[ReceiveBufLen], I);
      Inc(ReceiveBufLen, I);
      Inc(lcRecvByte, I);
      BufProgressBar.Position := ReceiveBufLen;
      BufSizeLabel.Caption := IntToStr(BufProgressBar.Position);
      RecvBytesCountLabel.Caption := IntToStr(lcRecvByte);
      if TraceMode>0 then
        AddProto(TraceMode, SockTitle, 'Получено байт='+IntToStr(I))
      else
        Application.ProcessMessages;
    except
      Step := csError;
      AddProto(plError, SockTitle, 'Исключение при чтении данных');
    end;
    if (ReceiveBufLen>0) and (Step<>csError) and not Processing then
    begin
      Processing := True;
      try
        I := -1;
        while (I<>0) and (Step<>csError) and Process do
        begin
          Application.ProcessMessages;
          if ReceiveDataLen=0 then
          begin
            if ReceiveBufLen<SizeOf(Cmnd) then
              I := 0
            else
              I := SizeOf(Cmnd);
          end
          else begin
            if ReceiveBufLen<ReceiveDataLen then
              I := 0
            else
              I := ReceiveDataLen;
          end;
          if (I>0) and (Step<>csError) then
          begin
            if ReceiveDataLen=0 then
            begin
              Move(ReceiveBuf^, Cmnd, SizeOf(Cmnd));
              DecodeExchangeCommand(Cmnd);
              if TraceMode>0 then
                AddProto(TraceMode, SockTitle, 'Команда '+IntToStr(Cmnd.cmCommand)
                  +'/'+IntToStr(Cmnd.cmParam));
              if not CheckExchangeCommand(Cmnd) then
              begin
                Step := csError;
                AddProto(plWarning, SockTitle,
                  'CRC команды ('+IntToStr(Cmnd.cmCommand)+'/'
                  +IntToStr(Cmnd.cmParam)+') неправильно ');
              end;
            end
            else begin
              if TraceMode>0 then
                AddProto(TraceMode, SockTitle, 'Данные '+IntToStr(ReceiveDataLen));
            end;
            if Step<>csError then
            begin
              if (ReceiveDataLen=0) and (Cmnd.cmCommand=eccMes) then
              begin
                TakeMes := True;    
                ReceiveDataLen := Cmnd.cmParam;    
                if (ReceiveDataLen<=0)    
                  or (ReceiveDataLen>MaxPostBufSize) then
                begin    
                  Step := csError;
                  AddProto(plWarning, SockTitle,
                    'Указана ошибочная длина сообщения L= '
                    +IntToStr(ReceiveDataLen));
                  ReceiveDataLen := 0;
                end;
              end    
              else
              if TakeMes then
              begin
                TakeMes := False;    
                Buf := AllocMem(ReceiveDataLen+1);
                try
                  Move(ReceiveBuf^, Buf^, ReceiveDataLen);    
                  Buf[ReceiveDataLen] := #0;    
                  EncodeBuf(134, Buf, ReceiveDataLen);    
                  AddProto(plWarning, SockTitle, 'Сообщение сервера: '+Buf);
                finally    
                  FreeMem(Buf);    
                  ReceiveDataLen := 0;
                end;    
              end
              else begin
                TakeMes := False;
                case Step of
                  csEnter:  {прием фразы и отсылка подписи}
                    begin
                      if ReceiveDataLen=0 then
                      begin
                        //ShowMes('Авторизация клиента...');
                        if Cmnd.cmCommand=eccSendData then
                        begin    
                          ReceiveDataLen := Cmnd.cmParam;    
                          if (ReceiveDataLen<=0)    
                            or (ReceiveDataLen>MaxPostBufSize) then
                          begin
                            Step := csError;
                            AddProto(plWarning, SockTitle,
                              'Указана ошибочная длина фразы L= '
                              +IntToStr(ReceiveDataLen));    
                            ReceiveDataLen := 0;    
                          end;
                        end
                        else begin
                          Step := csError;
                          AddProto(plWarning, SockTitle,
                            'Команда предложения фразы неправильна ('
                            +IntToStr(Cmnd.cmCommand)+')');    
                        end;
                      end
                      else begin    
                        Buf := AllocMem(ReceiveDataLen+MaxSignSize);    
                        try
                          Move(ReceiveBuf^, Buf^, ReceiveDataLen);
                          J := AddSign(ceiDomenK, Buf, ReceiveDataLen,
                            ReceiveDataLen+MaxSignSize, smOverwrite
                              {or smShowInfo}, nil, '');
                          if J>0 then    
                          begin    
                            SetExchangeCommand(eccSendData, J, Cmnd);
                            if SendComAndBuf(Socket, Cmnd,
                              @Buf[ReceiveDataLen], J) then    
                            begin
                              Step := csAuth1;
                              //ShowMes('');
                              //AddProto(plWarning1, MesTitle, 'Отправил подпись');
                            end
                            else begin
                              Step := csError;
                              AddProto(plInfo, SockTitle, 'Не удалось отправить подпись');
                            end;
                          end
                          else begin
                            Step := csError;
                            AddProto(plWarning, SockTitle, 'Не удалось создать подпись');
                          end;
                        finally
                          FreeMem(Buf);
                          ReceiveDataLen := 0;
                        end;
                      end;
                    end;
                  csAuth1:  {прием подтвреждения и отсылка фразы}
                    begin
                      if ReceiveDataLen=0 then
                      begin
                        case Cmnd.cmCommand of
                          eccOk:
                            begin
                              AddProto(plTrace, SockTitle, 'Клиент авторизован');
                              AchiveStep := csAuth2;
                              //ShowMes('Авторизация хоста...');
                              J := 0;
                              SendBufLen := AuthKeyLength;
                              SentBuf := AllocMem(SendBufLen);
                              try
                                if GenRandom(SentBuf, SendBufLen) then
                                begin
                                  SetExchangeCommand(eccSendData, SendBufLen, Cmnd);
                                  if SendComAndBuf(Socket, Cmnd, SentBuf, SendBufLen) then
                                  begin
                                    J := 1;
                                    Step := csAuth2;
                                  end
                                  else
                                    AddProto(plInfo, SockTitle, 'Не удалось послать фразу');
                                end
                                else
                                  AddProto(plError, SockTitle, 'Не удалось создать случайную фразу');
                              finally
                                if J=0 then
                                begin
                                  Step := csError;
                                  AddProto(plWarning, SockTitle, 'Фраза не была послана');
                                  FreeMem(SentBuf);
                                  SentBuf := nil;
                                end;
                              end;
                            end;
                          eccError:    
                            begin    
                              Step := csError;
                              AddProto(plWarning, SockTitle, 'Ошибка авторизации Err='
                                +IntToStr(Cmnd.cmParam));
                            end;
                          else begin    
                            Step := csError;
                            AddProto(plWarning, SockTitle, 'Команда подтверждения неправильна ('
                              +IntToStr(Cmnd.cmCommand)+'/'+IntToStr(Cmnd.cmParam));
                          end;
                        end;    
                      end
                      else begin    
                        Step := csError;
                        AddProto(plWarning, SockTitle, 'Не должно быть данных Auth1');
                      end;
                    end;
                  csAuth2, csData: {обмен данными}    
                    begin    
                      if Step=csAuth2 then
                      begin
                        if SentBuf<>nil then    
                        begin    
                          if ReceiveDataLen=0 then    
                          begin    
                            if Cmnd.cmCommand=eccSendData then
                            begin    
                              ReceiveDataLen := Cmnd.cmParam;
                              if (ReceiveDataLen<=0)
                                or (ReceiveDataLen>MaxPostBufSize) then
                              begin
                                Step := csError;
                                AddProto(plWarning, SockTitle, 'Указана ошибочная длина подписи L= '
                                  +IntToStr(ReceiveDataLen));
                                ReceiveDataLen := 0;
                              end    
                              {else    
                                AddProto(plWarning1, MesTitle, 'Получение подписи='+IntToStr(ReceiveDataLen))};
                            end
                            else begin    
                              Step := csError;
                              AddProto(plWarning, SockTitle, 'Команда возврата подписи неправильна ('
                                +IntToStr(Cmnd.cmCommand)+')');
                              //ShowMes('');
                            end;    
                          end    
                          else begin   {подпись сервера}    
                            try    
                              Buf := AllocMem(SendBufLen+ReceiveDataLen);
                              try
                                try
                                  Move(SentBuf^, Buf^, SendBufLen);
                                  Move(ReceiveBuf^, Buf[SendBufLen], ReceiveDataLen);
                                  PackControlData.cdCheckSelf := False;
                                    //showmessage('xx '+inttostr(SendBufLen)
                                    //  +'|'+inttostr(SendBufLen+ReceiveDataLen));
                                  if CheckSign(Buf, SendBufLen,
                                    SendBufLen+ReceiveDataLen, smThoroughly,
                                    @PackControlData, nil, '')=ceiDomenK then
                                  begin
                                    SetExchangeCommand(eccOk, 0, Cmnd);
                                    if SendComAndBuf(Socket, Cmnd, nil, 0) then
                                    begin    
                                      //Inc(LastAuthIder);    
                                      if SetRegNumber(rnAuth, LastAuthIder) then
                                      begin    
                                        Step := csData;    
                                        AchiveStep := csAuth3;
                                        AddProto(plTrace, SockTitle, 'Хост авторизован');
                                      end
                                      else begin
                                        Step := csError;
                                        AddProto(plWarning, SockTitle, 'Не удалось зарегистрировать сеанс');
                                      end;
                                    end
                                    else begin    
                                      Step := csError;
                                      AddProto(plInfo, SockTitle, 'Не удалось отправить подтверждение подписи');
                                    end;
                                  end
                                  else begin    
                                    Step := csError;
                                    AddProto(plWarning, SockTitle, 'Подпись вернулась не верная');
                                  end;    
                                except    
                                  Step := csError;
                                  AddProto(plWarning, SockTitle, 'Исключение при проверке подписи хоста');
                                end;
                              finally
                                FreeMem(Buf);    
                              end;
                            finally
                              FreeMem(SentBuf);
                              SentBuf := nil;
                              SendBufLen := 0;
                              ReceiveDataLen := 0;
                              //ShowMes('');
                            end;
                          end;
                        end
                        else begin
                          Step := csError;
                          AddProto(plWarning, SockTitle, 'Не найдена отосланная фраза');
                        end;
                      end;    
                      if Step=csData then
                      begin
                        repeat    
                          if ReceiveDataLen=0 then    
                          begin
                            if SentBuf=nil then   {команды не было, даем!}
                            begin
                              case SendDataMode of    
                                eccSendData:
                                  begin
                                    Buf := nil;
                                    try
                                      J := GetNextSendPack(Buf, LastSendPackID);    
                                      if J>0 then    
                                      begin    
                                        SetExchangeCommand(eccSendData, J, Cmnd);    
                                        if SendComAndBuf(Socket, Cmnd, Buf, J) then
                                        begin    
                                          SentBuf := AllocMem(SizeOf(TSendData));
                                          PSendData(SentBuf)^.sdCommand := Cmnd.cmCommand;
                                          PSendData(SentBuf)^.sdParam := LastSendPackID;    
                                        end    
                                        else begin
                                          Step := csError;
                                          AddProto(plInfo, SockTitle,
                                            'Не удалось отправить пакет ID='    
                                            +IntToStr(LastSendPackID));    
                                        end;
                                      end
                                      else
                                        SendDataMode := eccRcvData;
                                    finally    
                                      if Buf<>nil then
                                        FreeMem(Buf);    
                                    end;
                                  end;    
                                eccRcvData, eccRcvKvit:
                                  begin
                                    SetExchangeCommand(SendDataMode, 0, Cmnd);    
                                    if SendComAndBuf(Socket, Cmnd, nil, 0) then    
                                    begin
                                      SentBuf := AllocMem(SizeOf(TSendData));
                                      PSendData(SentBuf)^.sdCommand := Cmnd.cmCommand;    
                                      PSendData(SentBuf)^.sdParam := Cmnd.cmParam;
                                      //AddProto(plInfo, SockTitle,
                                      //  'Отправлен запрос '+IntToStr(SendDataMode));
                                    end    
                                    else begin    
                                      Step := csError;
                                      AddProto(plInfo, SockTitle,
                                        'Не удалось отправить запрос пакета/квитанци '
                                        +IntToStr(eccSendData));
                                    end;
                                  end;
                                else begin
                                  Step := csError;
                                  AddProto(plWarning, SockTitle,
                                    'Шаг передачи недопустим '+IntToStr(SendDataMode));
                                end;
                              end;
                            end    
                            else begin    {это ответ на команду}    
                              case Cmnd.cmCommand of    
                                eccOk:    
                                  begin    
                                    case PSendData(SentBuf)^.sdCommand of    
                                      eccSendData:    
                                        begin
                                          J := SetSendPack(PSendData(    
                                            SentBuf)^.sdParam, Cmnd.cmParam);
                                          if J=0 then
                                          begin
                                            IncCounter(SendPackCountLabel, lcSendPack);
                                            AddProto(plInfo, SockTitle, 'Пакет '
                                              +IntToStr(PSendData(SentBuf)^.sdParam)
                                              +' отослан '+IntToStr(Cmnd.cmParam));
                                          end
                                          else    
                                            AddProto(plWarning, SockTitle,
                                              'Не удалось пометить пакет как отправленный BtrErr='
                                              +IntToStr(J)+')');    
                                        end;
                                      else begin
                                        Step := csError;
                                        AddProto(plWarning, SockTitle,
                                          'Ненужный ответ (0) на запрос ('
                                          +IntToStr(PSendData(SentBuf)^.sdCommand)+')');
                                      end;
                                    end;    
                                  end;
                                eccSendData:
                                  begin
                                    case PSendData(SentBuf)^.sdCommand of
                                      eccRcvData, eccRcvKvit:
                                        begin
                                          ReceiveDataLen := Cmnd.cmParam;    
                                          if (ReceiveDataLen<=0)    
                                            or (ReceiveDataLen>MaxPostBufSize) then    
                                          begin    
                                            Step := csError;
                                            AddProto(plWarning, SockTitle,
                                              'Указана ошибочная длина входящих данных L= '    
                                              +IntToStr(ReceiveDataLen)+' в ответ на ('    
                                              +IntToStr(PSendData(SentBuf)^.sdCommand)+')');    
                                            ReceiveDataLen := 0;
                                          end
                                        end;    
                                      else begin
                                        Step := csError;
                                        AddProto(plWarning, SockTitle,
                                          'Предложение ненужных данных (1) на запрос ('
                                          +IntToStr(PSendData(SentBuf)^.sdCommand)+')');
                                      end;
                                    end;
                                  end;
                                eccError:
                                  begin    
                                    case PSendData(SentBuf)^.sdCommand of
                                      eccSendData:    
                                        begin    
                                          AddProto(plWarning, SockTitle,
                                            'Сервер не принял пакет Num='
                                            +IntToStr(PSendData(SentBuf)^.sdParam)
                                            +' Err='+IntToStr(Cmnd.cmParam));
                                          SendDataMode := eccRcvData;    
                                        end;
                                      eccRcvData:
                                        SendDataMode := eccRcvKvit;
                                      eccRcvKvit:
                                        begin
                                          SendDataMode := eccOk;
                                          AchiveStep := csData;
                                        end;    
                                      else
                                        AddProto(plWarning, SockTitle, 'Отрицательный ответ ('+IntToStr(Cmnd.cmCommand)
                                          +' на непонятный запрос ('+IntToStr(PSendData(SentBuf)^.sdCommand)+')');
                                    end;
                                  end;    
                                else begin    
                                  Step := csError;
                                  AddProto(plWarning, SockTitle, 'Неадекватный ответ ('+IntToStr(Cmnd.cmCommand)
                                    +' на запрос ('+IntToStr(PSendData(SentBuf)^.sdCommand)+')');
                                end;    
                              end;
                              if ReceiveDataLen=0 then
                              begin
                                FreeMem(SentBuf);
                                SentBuf := nil;
                              end;
                            end;    
                          end    
                          else begin  {данные сервера}    
                            if SentBuf<>nil then   {был ли запрос?}
                            begin
                              try
                                case PSendData(SentBuf)^.sdCommand of
                                  eccRcvData:
                                    begin
                                      J := InsertPack(ReceiveBuf, ReceiveDataLen);
                                      if J>=0 then
                                      begin
                                        if J>0 then
                                          AddProto(plInfo, SockTitle, 'Пакет принят '
                                            +IntToStr(J));
                                        IncCounter(RecvPackCountLabel, lcRecvPack);
                                        //Application.ProcessMessages;
                                        SetExchangeCommand(eccOk, 0, Cmnd);
                                        if not SendComAndBuf(Socket, Cmnd, nil, 0) then
                                        begin
                                          Step := csError;
                                          AddProto(plInfo, SockTitle,
                                            'Не удалось отправить подтверждение пакета Num='
                                            +IntToStr(J));    
                                        end;
                                      end    
                                      else begin
                                        Step := csError;
                                        AddProto(plWarning, SockTitle,
                                          'Не удалось записать пакет Err='+IntToStr(J));
                                        SetExchangeCommand(eccError, -J, Cmnd);
                                        if not SendComAndBuf(Socket, Cmnd, nil, 0) then
                                        begin
                                          Step := csError;
                                          AddProto(plWarning, SockTitle,
                                            'Не удалось отправить отрицание пакета');
                                        end;    
                                      end;
                                    end;
                                  eccRcvKvit:    
                                    begin    
                                      if ReceiveDataLen<8 then    
                                        J := 1111    
                                      else begin    
                                        J := SetRcvPack(PLongWord(ReceiveBuf)^,    
                                          PWord(@ReceiveBuf[4])^, PWord(@ReceiveBuf[6])^);
                                        if (J=0) or (J=4) then
                                        begin
                                          if J=0 then
                                          begin
                                            IncCounter(KvitPackCountLabel, lcRecvKvit);
                                            //AddProto(plInfo, SockTitle, 'Пакет Id='
                                            //  +IntToStr(PLongWord(ReceiveBuf)^)
                                            // +' был получен');}
                                          end
                                          else begin
                                            J := 0;
                                            AddProto(plWarning, SockTitle, 'Пакет Id='
                                              +IntToStr(PLongWord(ReceiveBuf)^)
                                              +' не найден, квитанция игнорируется');
                                          end;
                                          SetExchangeCommand(eccOk, 0, Cmnd);
                                          if not SendComAndBuf(Socket, Cmnd, nil, 0) then
                                          begin
                                            Step := csError;
                                            AddProto(plInfo, SockTitle,
                                              'Не удалось отправить подтверждение квитанции Id='
                                              +IntToStr(PLongWord(ReceiveBuf)^));
                                          end;
                                        end
                                        else
                                          AddProto(plWarning, SockTitle,
                                            'Не удалось пометить пакет Id='
                                            +IntToStr(PLongWord(ReceiveBuf)^)
                                            +' как полученный Err='    
                                            +IntToStr(J));    
                                      end;    
                                      if J<>0 then    
                                      begin
                                        SetExchangeCommand(eccError, J, Cmnd);    
                                        if not SendComAndBuf(Socket, Cmnd, nil, 0) then    
                                        begin
                                          Step := csError;    
                                          AddProto(plWarning, SockTitle,
                                            'Не удалось отправить отрицание квитанции');
                                        end;    
                                      end;
                                    end;
                                  else begin
                                    Step := csError;
                                    AddProto(plWarning, SockTitle,
                                      'Ненужные данные (1) на запрос ('
                                      +IntToStr(PSendData(SentBuf)^.sdCommand)+')');
                                  end;    
                                end;
                              finally    
                                FreeMem(SentBuf);    
                                SentBuf := nil;    
                                SendBufLen := 0;    
                              end;
                            end    
                            else begin
                              //Step := csError;
                              AddProto(plWarning, SockTitle, 'Команда запроса не найдена, данные DataLen='
                                +IntToStr(ReceiveDataLen)+' игнорируются');    
                            end;
                            ReceiveDataLen := 0;
                          end;
                        until not Process or (Step=csError)
                          or (SentBuf<>nil) or (SendDataMode=eccOk);
                      end;
                    end;    
                  else
                    begin    
                      Step := csError;
                      AddProto(plWarning, SockTitle, 'Неясный шаг');
                    end;
                end;
              end;
            end;
          end
          else
            I := 0;
          if (I>0) and (Step<>csError) then {обработано что-то и не ошибка}
          begin
            ReceiveBufLen := ReceiveBufLen-I;
            if ReceiveBufLen>0 then
            begin
              try
                Buf := AllocMem(ReceiveBufLen);
                Move(ReceiveBuf[I], Buf^, ReceiveBufLen);
                FreeMem(ReceiveBuf);
                ReceiveBuf := Buf;
                I := -1;
              except
                Step := csError;
                AddProto(plWarning, SockTitle, 'Ошибка перемещения буфера чтения');
              end;
            end
            else begin
              try
                ReceiveBufLen := 0;
                FreeMem(ReceiveBuf);
                ReceiveBuf := nil;
                I := 0;
              except
                Step := csError;
                AddProto(plWarning, SockTitle, 'Ошибка освобождения буфера чтения');
              end;
            end;
            BufProgressBar.Position := ReceiveBufLen;
            BufSizeLabel.Caption := IntToStr(BufProgressBar.Position);
          end;
        end;
      except
        Step := csError;
        AddProto(plWarning, SockTitle, 'Исключение при обработке полученных данных');
      end;
      Processing := False;
    end;
  end
  else begin
    Step := csError;
    BufProgressBar.Position := BufProgressBar.Max;
    BufSizeLabel.Caption := IntToStr(ReceiveBufLen + I);
    AddProto(plWarning, SockTitle, 'Размер буфера чтения превышен '
      +IntToStr(MaxPostBufSize));
  end;
  if (Step=csError) or not Process or (SendDataMode=eccOk) then
  begin
    Socket.Close;
    if Step=csError then
      AddProto(plWarning, SockTitle, 'Разрыв по ошибке')
    else begin
      if SendDataMode<>eccOk then
        AddProto(plWarning, SockTitle, 'Разрыв вручную')
      {else
        AddProto(plTrace, SockTitle, 'Сеанс связи успешно завершен')};
    end;
  end;
end;

procedure TMailForm.ClientSocketError(Sender: TObject;
  Socket: TCustomWinSocket; ErrorEvent: TErrorEvent;
  var ErrorCode: Integer);
begin
  AddProto(plWarning, SockTitle, 'Ошибка сокета '+IntToStr(ErrorCode));
  ConnectState := 0;
  IdleTimePeriod := 0;
end;

procedure TMailForm.FormDestroy(Sender: TObject);
begin
  if ReceiveBuf<>nil then
  begin
    FreeMem(ReceiveBuf);
    ReceiveBuf := nil;
  end;
  if SentBuf<>nil then
  begin
    FreeMem(SentBuf);
    SentBuf := nil;
  end;
  ReceiveBufLen := 0;
  ReceiveDataLen := 0;
  SendBufLen := 0;
  if Sender=MailBitBtn then
  begin
    //BufProgressBar.Position := 0;
    BufProgressBar.Hide;
  end
  else begin
    BaseSend.Free;
    BaseSend := nil;
    BaseRecv.Free;
    BaseRecv := nil;
    ClientSocket.Free;
    ObjList.Remove(MailForm);
    MailForm := nil;
  end;
end;

procedure TMailForm.ClientSocketDisconnect(Sender: TObject;
  Socket: TCustomWinSocket);
begin
  ClientTimer.Enabled := False;
  ConnectState := 0;
  FormDestroy(MailBitBtn);
  AddProto(plTrace, SockTitle, 'Соединение с хостом разорвано');
end;

procedure TMailForm.ClientTimerTimer(Sender: TObject);
var
  I: DWord;
begin
  if Sender<>nil then
  begin
    I := ClientTimer.Interval div 1000;
    TimePeriod := TimePeriod + I;
    IdleTimePeriod := IdleTimePeriod + I;
    if (WaitHostTimeOut>0)
      and (IdleTimePeriod>WaitHostTimeOut) and Process then
    begin
      MailForm.AddProto(plWarning, 'Timer', PChar('Разрав по таймауту '
        +IntToStr(IdleTimePeriod)+' сек.'));
      Process := False;
    end;
  end;
  I := TimePeriod div 60;
  TimeCountLabel.Caption := FillZeros(I, 2)+':'+FillZeros(TimePeriod - I*60, 2);
end;

procedure TMailForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
  if (piLetters>0) and (CheckNewLet>0) then
    PostMessage(Application.MainForm.Handle, WM_CHECKNEWLETTER, piLetters,
      CheckNewLet);
end;

procedure TMailForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := not Process;
end;

procedure TMailForm.HorzSplitterCanResize(Sender: TObject;
  var NewSize: Integer; var Accept: Boolean);
begin
  Accept := NewSize>=35;
end;

procedure TMailForm.CloseBitBtnClick(Sender: TObject);
begin
  if FormStyle=fsMDIChild then
    Close;
end;

procedure TMailForm.FormShow(Sender: TObject);
begin
  if FirstShowMode=0 then
    MailBitBtnClick(ProtoGroupBox)
  else
    MailBitBtnClick(nil);
end;

procedure TMailForm.AskBillCheckBoxClick(Sender: TObject);
begin
  ToAskBillLabel.Visible := AskBillCheckBox.Checked;
  FromAskBillLabel.Visible := ToAskBillLabel.Visible;
  FromAskBillDateEdit.Visible := ToAskBillLabel.Visible;
  ToAskBillDateEdit.Visible := ToAskBillLabel.Visible;
end;

end.
