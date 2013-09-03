unit MailFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons, ComCtrls, ExtCtrls, Basbn, Registr, CommCons, CrySign,
  Utilits, Btrieve, ScktComp, ClntCons, BtrDS, Common, PackProcess,
  CheckLst, Mask, ToolEdit, WideComboBox, BUtilits;

type
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
    DoublesLabel: TLabel;
    LetsLabel: TLabel;
    DoublesCountLabel: TLabel;
    LetsCountLabel: TLabel;
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
    InDocCountLabel: TLabel;
    InLetsLabel: TLabel;
    InLetsCountLabel: TLabel;
    ClientSocket: TClientSocket;
    BufProgressBar: TProgressBar;
    BufLabel: TLabel;
    BufSizeLabel: TLabel;
    KvitPackLabel: TLabel;
    KvitPackCountLabel: TLabel;
    ClientTimer: TTimer;
    InetBreakComboBox: TComboBox;
    InetBreakLabel: TLabel;
    AcceptsLabel: TLabel;
    AcceptsCountLabel: TLabel;
    RetsLabel: TLabel;
    RetsCountLabel: TLabel;
    KartsLabel: TLabel;
    KartsCountLabel: TLabel;
    BillsLabel: TLabel;
    BillsCountLabel: TLabel;
    InDocsLabel: TLabel;
    InDocsCountLabel: TLabel;
    AccsLabel: TLabel;
    AccsCountLabel: TLabel;
    FilesLabel: TLabel;
    FilesCountLabel: TLabel;
    SendChooseTabSheet: TTabSheet;
    BanksLabel: TLabel;
    BanksCountLabel: TLabel;
    InRetsLabel: TLabel;
    InRetsCountLabel: TLabel;
    InFilesLabel: TLabel;
    InFilesCountLabel: TLabel;
    LetAccptsLabel: TLabel;
    LetAccptsCountLabel: TLabel;
    ResendGroupBox: TGroupBox;
    ResendScrollBox: TScrollBox;
    CorrLabel: TLabel;
    CorrWideComboBox: TWideComboBox;
    RemLabel: TLabel;
    FromDate: TLabel;
    FromDateEdit: TDateEdit;
    ToDateEdit: TDateEdit;
    ToLabel: TLabel;
    JustOpenCheckBox: TCheckBox;
    AllAccCheckBox: TCheckBox;
    AccCheckListBox: TCheckListBox;
    NameLabel: TLabel;
    SearchIndexComboBox: TComboBox;
    MaskComboBox: TComboBox;
    MaskLabel: TLabel;
    Panel1: TPanel;
    BaseCheckBox: TCheckBox;
    ResendCheckBox: TCheckBox;
    FileCheckBox: TCheckBox;
    SprCheckBox: TCheckBox;
    ProgressBar0: TProgressBar;
    HorzSplitter: TSplitter;
    ProgressBar1: TProgressBar;
    SignFileCheckBox: TCheckBox;
    OldKeyUsed: TCheckBox;
    AfterOperGroupBox: TGroupBox;
    AfterOperFromLabel: TLabel;
    AfterOperToLabel: TLabel;
    AfterOperFromEdit: TMaskEdit;
    AfterOperToEdit: TMaskEdit;
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
    procedure FormShow(Sender: TObject);
    procedure ClientTimerTimer(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure ResendCheckBoxClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure CorrWideComboBoxKeyPress(Sender: TObject; var Key: Char);
    procedure FormActivate(Sender: TObject);
    procedure CorrWideComboBoxClick(Sender: TObject);
    procedure SearchIndexComboBoxClick(Sender: TObject);
    procedure FromDateEditAcceptDate(Sender: TObject; var ADate: TDateTime;
      var Action: Boolean);
    procedure AllAccCheckBoxClick(Sender: TObject);
    procedure MaskComboBoxChange(Sender: TObject);
    procedure MaskComboBoxExit(Sender: TObject);
    procedure MaskComboBoxKeyPress(Sender: TObject; var Key: Char);
    procedure FromDateEditChange(Sender: TObject);
    procedure HorzSplitterCanResize(Sender: TObject; var NewSize: Integer;
      var Accept: Boolean);
    procedure FileCheckBoxClick(Sender: TObject);
    procedure AfterOperFromEditKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure AfterOperFromEditExit(Sender: TObject);
    procedure AfterOperFromEditChange(Sender: TObject);
    procedure AfterOperToEditChange(Sender: TObject);
    procedure AfterOperToEditExit(Sender: TObject);
    procedure AfterOperToEditKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
  private
    procedure WMSysCommand(var Message:TMessage); message WM_SYSCOMMAND;
  public
    Stage: Integer;
    Step: TConnectionStep;
    ReceiveBuf, SentBuf: PChar;
    ReceiveBufLen, ReceiveDataLen, SendBufLen: Integer;
    FastPrep: Boolean;
    procedure ShowMes(S: string);
    procedure AddProto(Level: Byte; Title: PChar; S: string);
    procedure InitProgressBar(PanInd, AMin, AMax: Integer);
    procedure SetProgress(PanInd, APos: Integer);
    procedure NextProgress(PanInd: Integer);
    procedure HideProgressBar(PanInd: Integer);
    procedure AddSendBytes(I: Integer);
    procedure MakeResendList(var ReSendCorr: Integer;
      var AccList: TList);
    function MakeObmen(BaseS, BaseR: TBtrBase): Integer;
    class procedure CreateChildForm(Sender: TObject);
    procedure FillAccTable;
  end;

const
  ID_CREATEENTRY = WM_USER + 10;
  ID_EDITENTRY   = WM_USER + 11;
  ID_INETCPL     = WM_USER + 12;
  ID_BEGINPRC    = WM_USER + 13;

var
  MailForm: TMailForm;
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

class procedure TMailForm.CreateChildForm(Sender: TObject);
const
  MesTitle: PChar = 'Обмен с хостом';
begin
  if IsSanctAccess('PostSanc') then
  begin
    MailForm := TMailForm.Create(Application);
    with MailForm do
    begin
      FastPrep := (Sender as TComponent).Tag=0;
      ShowModal;
      Free;
    end;
  end
  else
    MessageBox(Application.Handle, 'Вы не можете проводить сеанс связи',
      MesTitle, MB_OK or MB_ICONINFORMATION);
end;

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

function IsWinNt: Boolean;
begin
  Result := (GetVersion and $80000000) = 0;
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
    ID_BEGINPRC:
      begin
        MailBitBtnClick(nil);
      end;
  end;
  inherited;
end;

const
  piProgress1 = 0;
  piProgress2 = 1;
  piMes = 2;

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
  Application.ProcessMessages;
end;

var
  CheckSendFirst: Boolean;
  WaitHostTimeOut: Integer;
  SenderAcc, MailerURL: string;
  lcSendPack, lcRecvPack, lcRecvKvit, lcSendByte, lcRecvByte: dWord;
  PackSize: Integer;

var
  BaseSend: TBtrBase = nil;
  BaseRecv: TBtrBase = nil;
  VersionNum: LongWord = 0;
  AccList: TAccList;
  AccDataSet: TExtBtrDataSet;

procedure TMailForm.FormCreate(Sender: TObject);
const
  MesTitle: PChar = 'Сеанс связи';
var
  SysMenu: THandle;
  T: array[0..1023] of Char;
  HangUpMode: Integer;
  Err: Integer;
begin
  FastPrep := False;
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
  BufProgressBar.Position := 0;
  BufProgressBar.Max := MaxPostBufSize;
  ReceiveBufLen := 0;
  SentBuf := nil;
  SendBufLen := 0;
  BaseSend := nil;
  BaseRecv := nil;
  Stage := -1;
  AccList := TAccList.Create;
  AccDataSet := GlobalBase(biAcc);
  if IsDomenKInited then
  begin
    if IsSanctAccess('PostSanc') then
    begin
      if GetRegParamByName('SenderAcc', CommonUserNumber, T) then
        SenderAcc := StrPas(@T)
      else
        SenderAcc := '';
      SenderAcc := GetSelfLogin(SenderAcc);
      if GetRegParamByName('MailerURL', CommonUserNumber, T) then
        MailerURL := StrPas(@T)
      else
        MailerURL := '';
      if not GetRegParamByName('MailerNode', CommonUserNumber, MailerNode) then
        MailerNode := 0;
      if not GetRegParamByName('MailerPort', CommonUserNumber, MailerPort) then
        MailerPort := 10000;

      IsUsedNewKey := IsKeyNew;
      if IsUsedNewKey then
      begin
        if not GetRegParamByName('MailerPort', CommonUserNumber, MailerPort) then
          MailerPort := 10000;
      end
      else begin
        if not GetRegParamByName('MailerPortOld', CommonUserNumber, MailerPort) then
          MailerPort := 10000;
      end;
      if not GetRegParamByName('WaitHost', CommonUserNumber, WaitHostTimeOut) then
        WaitHostTimeOut := 0;
      if not GetRegParamByName('PackSize', CommonUserNumber, PackSize) then
        PackSize := 4096;
      if not GetRegParamByName('CheckSendFirst', CommonUserNumber, CheckSendFirst) then
        CheckSendFirst := True;
      if not GetRegParamByName('HangUpMode', CommonUserNumber, HangUpMode) then
        HangUpMode := 2;
      if GetRegParamByName('BankBik', GetUserNumber, T) then
      begin
        Val(StrPas(@T), BankBik, Err);
        if Err<>0 then
          BankBik := 45744803;
      end
      else
        BankBik := 45744803;
      if not GetRegParamByName('UpdDate1', GetUserNumber, UpdDate1) then
        UpdDate1 := StrToBtrDate('21.01.03');
      if not GetRegParamByName('OldDayLimit', GetUserNumber, LowDate) then
        LowDate := 10;
      LowDate := DateToBtrDate(Date-LowDate);
      if not GetRegParamByName('DefPayVO', GetUserNumber, DefPayVO) then
        DefPayVO := 1;
      InetBreakComboBox.ItemIndex := HangUpMode;
      Stage := 0;
      if (Length(MailerURL)>0) and (MailerURL[1] in ['0'..'9']) then
      begin
        ClientSocket.Host := '';
        ClientSocket.Address := MailerURL;
      end
      else begin
        ClientSocket.Address := '';
        ClientSocket.Host := MailerURL;
      end;
      ClientSocket.Port := MailerPort;
      BaseSend := TBtrBase.Create;
      BaseRecv := TBtrBase.Create;
      FillChar(PackControlData, SizeOf(PackControlData), #0);
      with PackControlData do
      begin
        StrPLCopy(cdTagLogin, SenderAcc, SizeOf(cdTagLogin)-1);
        cdTagNode := MailerNode;
      end;
    end
    else
      AddProto(plWarning, MesTitle, 'Вы не можете проводить сеанс связи');
  end
  else
    AddProto(plWarning, MesTitle, 'СКЗИ не инициализировано');
  MailBitBtn.Enabled := Stage=0;
  ProgressBar0.Parent := StatusBar;
  ProgressBar1.Parent := StatusBar;
  HideProgressBar(0);
  HideProgressBar(1);
  lcSendPack := 0;
  lcRecvPack := 0;
  lcRecvKvit := 0;
  lcSendByte := 0;
  lcRecvByte := 0;
  poInDocs := 0;
  poLets := 0;
  poDoubles := 0;
  poAccepts := 0;
  poReturns := 0;
  poKarts := 0;
  poBills := 0;
  poAccs := 0;
  poFiles := 0;
  poBanks := 0;
  piInRets := 0;
  piInDocs := 0;
  piInLets := 0;
  piInFiles := 0;
  piBroadcastLet := 0;
end;

procedure TMailForm.InitProgressBar(PanInd, AMin, AMax: Integer);
const
  Border=2;
var
  X, I: Integer;
  ProgressBar: TProgressBar;
begin
  if PanInd=0 then
    ProgressBar := ProgressBar0
  else
    ProgressBar := ProgressBar1;
  if PanInd=0 then
    StatusBar.Panels[PanInd].Width := ProgressBar.Width
  else
    StatusBar.Panels[PanInd].Width := ProgressBar.Width+Border;
  X := 0;
  for I := 0 to PanInd-1 do
    X := X+StatusBar.Panels[I].Width+Border;
  with ProgressBar do
  begin
    SetBounds(X, Border, Width, StatusBar.Height - Border);
    try
      Min := 0;
      Position := 0;
      Max := AMax;
      Min := AMin;
      Position := Min;
    except
    end;
    Visible := True;
  end;
end;

procedure TMailForm.SetProgress(PanInd, APos: Integer);
var
  ProgressBar: TProgressBar;
begin
  if PanInd=0 then
    ProgressBar := ProgressBar0
  else
    ProgressBar := ProgressBar1;
  with ProgressBar do
  begin
    if APos<Min then
      APos := Min;
    if APos>Max then
      APos := Max;
    Position := APos;
  end;
end;

procedure TMailForm.NextProgress(PanInd: Integer);
var
  ProgressBar: TProgressBar;
begin
  if PanInd=0 then
    ProgressBar := ProgressBar0
  else
    ProgressBar := ProgressBar1;
  SetProgress(PanInd, ProgressBar.Position+1);
end;

procedure TMailForm.HideProgressBar(PanInd: Integer);
var
  ProgressBar: TProgressBar;
begin
  if PanInd=0 then
    ProgressBar := ProgressBar0
  else
    ProgressBar := ProgressBar1;
  ProgressBar.Hide;
  StatusBar.Panels[PanInd].Width := 0;
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
    FN := UserBaseDir+'doc_s.btr';
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
    FN := UserBaseDir+'doc_r.btr';
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

procedure TMailForm.MakeResendList(var ReSendCorr: Integer;
  var AccList: TList);
var
  I: Integer;
begin
  AccList := nil;
  ReSendCorr := 0;
  if ResendCheckBox.Enabled and ResendCheckBox.Checked
    and (CorrWideComboBox.ItemIndex>=0) then  
  begin
    ReSendCorr := Integer(CorrWideComboBox.Items.Objects[CorrWideComboBox.ItemIndex]);  
    if ReSendCorr>0 then  
    begin  
      if not AllAccCheckBox.Checked then  
      begin  
        AccList := TList.Create;  
        for I := 0 to AccCheckListBox.Items.Count-1 do
          if AccCheckListBox.Checked[I] then  
            AccList.Add(AccCheckListBox.Items.Objects[I]);      
      end;
    end;
  end;
end;

procedure TMailForm.MailBitBtnClick(Sender: TObject);
const
  MesTitle: PChar = 'Обмен с банком';
var
  L: Integer;
  GoNext: Boolean;
  ReSendCorr: Integer;
  AccList: TList;
  d1, d2: Word;
begin
  if Process then
  begin
    MailBitBtn.Enabled := False;
    ShowMes('Прекращение процесса...');
    Process := False;
  end
  else
    if MailBitBtn.Enabled and (Stage>=0) and (Stage<=3) then
    begin
      Process := True;
      MailBitBtn.Caption := '&Прервать';
      CloseBitBtn.Caption := '&Закрыть';
      CloseBitBtn.Enabled := False;
      GoNext := True;
      while (Stage>=0) and (Stage<=3) and Process and GoNext do
      begin
        GoNext := False;
        case Stage of
          0:  {проверка старых пакетов, подготовка новых}
            begin
              InitProgressBar(0, 0, 7);
              StepPageControl.ActivePage := PrepareTabSheet;
              L := Length(SenderAcc);
              if (L>0) and (L<=8) then
              begin
                  {if (PackSize>50) and (PackSize<MaxPackSize-(drMaxVar+7+SignSize)) then
                  begin}
                    Screen.Cursor := crHourGlass;
                    if OpenSendBase then
                    begin
                      ShowMes('Проверка ранее отправленных пакетов...');
                      NextProgress(0);
                      GetSentDoc(BaseSend,
                        SenderAcc, Process, CheckSendFirst);
                      NextProgress(0);
                      if Process then
                      begin
                        ShowMes('Формирование пакетов на отправку...');
                        if ResendCheckBox.Checked
                          and (ResendCheckBox.Font.Color=clWindowText) then
                        begin
                          d1 := DateToBtrDate(FromDateEdit.Date);
                          d2 := DateToBtrDate(ToDateEdit.Date);
                          MakeResendList(ReSendCorr, AccList);
                        end
                        else
                          ReSendCorr := 0;
                        SendDoc(BaseSend, SenderAcc, Process, PackSize,
                          BaseCheckBox.Checked, FileCheckBox.Checked,
                          SprCheckBox.Checked, SignFileCheckBox.Checked, ReSendCorr, d1, d2, AccList);
                        NextProgress(0);
                        ShowMes('');
                        if Process then
                          Stage := 1;
                      end;
                      //StepPageControl.ActivePage := ExchangeTabSheet;
                    end;
                  {end
                  else
                    ProtoMes(plError, MesTitle, PChar('Размер пакета некорректен '
                      +IntToStr(PackSize)));}
              end
              else
                ProtoMes(plError, MesTitle,
                  PChar('Длина позывного отправителя неверна L='
                  +IntToStr(L)));
            end;
          1:
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
                  NextProgress(0);
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
                  SenderAcc, Process, True);
                if Process and (Stage>2) then
                  Inc(Stage);
                NextProgress(0);
                ShowMes('');
              end
              else
                AddProto(plWarning, MesTitle, 'Не удалось проверить отправленные пакеты. База закрыта');
              if OpenRecvBase then
              begin
                ShowMes('Обработка полученных пакетов...');
                LastDaysDate := GetLastClosedDay;
                FirstDocDate := $FFFF;
                ReceiveDoc(BaseRecv, Process);
                NextProgress(0);
                if Process then
                begin
                  ShowMes('Обработка полученных фрагментов файлов...');
                  GenerateFiles(Process);
                end;
                NextProgress(0);
                if Process and (Stage>2) then
                  Inc(Stage);
                ShowMes('');
              end
              else
                AddProto(plError, MesTitle, 'Не удалось проверить принятые пакеты. База закрыта');
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
        HideProgressBar(0);
        MailBitBtn.Enabled := False;
        ShowMes('Обмен успешно завершен');
        CloseBitBtn.SetFocus;
      end
      else begin
        MailBitBtn.Enabled := True;
        if Stage>2 then
        begin
          Stage := 0;
          HideProgressBar(0);
        end;
      end;
      Process := False;
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
begin
  Result := -1;
  AddProto(plInfo, MesTitle, 'Попытка установить соединение...');
  if (InternetAutoDialPtr=nil)
    or (TInternetAutoDial(InternetAutoDialPtr)(INTERNET_AUTODIAL_FORCE_ONLINE, 0)) then
  begin
    Result := 0;
    AchiveStep := csEnter;
    Step := csEnter;
    ConnectState := 1;
    TimePeriod := 0;
    IdleTimePeriod := 0;
    ClientSocket.Active := True;
    try
      //AddProto(plWarning, MesTitle, 'cicle');
      while (ConnectState>0) and Process do
      begin
        Sleep(10);
        Application.ProcessMessages;
      end;
      if (ConnectState>1) and not Process then
      begin
        I := BreakWaitSec*1000;
        while ClientSocket.Active and (I>0) do
        begin
          ShowMes('Ждем еще '+IntToStr(I div 1000+1)+' секунд...');
          Application.ProcessMessages;
          Sleep(50);
          I := I-50;
        end;
        ShowMes('');
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
        if AchiveStep>=csData then
          AddProto(plInfo, MesTitle, 'Обмен успешно завершен')
        else
          AddProto(plWarning, MesTitle, 'Были ошибки авторизации');
      end
      else
        AddProto(plWarning, MesTitle, 'Не удалось установить соединение');
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
                AddProto(plInfo, MesTitle, 'Соединение ['
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
    AddProto(plInfo, MesTitle, 'Соединение не было установлено');
end;

procedure TMailForm.StepPageControlChanging(Sender: TObject;
  var AllowChange: Boolean);
begin
  AllowChange := not Process;
end;

procedure TMailForm.ClientSocketLookup(Sender: TObject;
  Socket: TCustomWinSocket);
begin
  ShowMes('Поиск хоста...');
  IdleTimePeriod := 0;
end;

procedure TMailForm.ClientSocketConnecting(Sender: TObject;
  Socket: TCustomWinSocket);
begin
  ShowMes('Установка соединения с хостом...');
  IdleTimePeriod := 0;
  ConnectState := 2;
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
    MailForm.AddProto(plInfo, MesTitle, 'Пакет недопустимой длины L='
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
    Application.ProcessMessages;
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
    if OldKeyUsed.Checked then
      V := 'v3'
    else
      V := 'vZ';
  end;                                                //Изменено Меркуловым
  S := SenderAcc+Format(' '+V+' l%x h%x n%u', [LastAuthIder,
    GetHddPlaceId(BaseDir),VersionNum])+#13;
  Socket.SendText(S);
  AddSendBytes(Length(S));
end;

function SendComAndBuf(Socket: TCustomWinSocket; Comnd: TExchangeCommand;
  Buf: PChar; BufLen: Integer): Boolean;
var
  I: Integer;
begin
  CodeExchangeCommand(Comnd);
  I := Socket.SendBuf(Comnd, SizeOf(TExchangeCommand));
  MailForm.AddSendBytes(I);
  Result := I=SizeOf(TExchangeCommand);
  if (Buf<>nil) and (BufLen>0) and Result then
  begin
    I := Socket.SendBuf(Buf^, BufLen);
    MailForm.AddSendBytes(I);
    Result := I=BufLen;
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
      //AddProto(plWarning, SockTitle, 'Получено байт='+IntToStr(I));
      BufProgressBar.Position := ReceiveBufLen;
      BufSizeLabel.Caption := IntToStr(BufProgressBar.Position);
      RecvBytesCountLabel.Caption := IntToStr(lcRecvByte);
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
        while (I<>0) and (Step<>csError) do
        begin
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
              //AddProto(plInfo, SockTitle, 'Команда '+IntToStr(Cmnd.cmCommand)
              //  +'|'+IntToStr(Cmnd.cmParam));
              DecodeExchangeCommand(Cmnd);
              //AddProto(plInfo, SockTitle, 'DecКом '+IntToStr(Cmnd.cmCommand)
              //  +'|'+IntToStr(Cmnd.cmParam));
              if not CheckExchangeCommand(Cmnd) then
              begin    
                Step := csError;    
                AddProto(plWarning, SockTitle,
                  'CRC команды ('+IntToStr(Cmnd.cmCommand)+') неправильно ');    
              end;    
            end
            {else begin
              AddProto(plInfo, SockTitle, 'Данные '+IntToStr(ReceiveDataLen));
            end};
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
                        ShowMes('Авторизация клиента...');
                        if Cmnd.cmCommand=eccSendData then
                        begin    
                          ReceiveDataLen := Cmnd.cmParam;    
                          if (ReceiveDataLen<=0)    
                            or (ReceiveDataLen>MaxPostBufSize) then
                          begin
                            Step := csError;    
                            AddProto(plWarning, SockTitle, 'Указана ошибочная длина фразы L= '
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
                              ShowMes('');
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
                              ShowMes('Авторизация хоста...');    
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
                                  AddProto(plWarning, SockTitle, 'Не удалось создать случайную фразу');
                              finally    
                                if J=0 then
                                begin    
                                  Step := csError;    
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
                              ShowMes('');    
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
                              ShowMes('');    
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
                                            Application.ProcessMessages;
                                            //AddProto(plInfo, SockTitle, 'Пакет '
                                            //  +IntToStr(PSendData(SentBuf)^.sdParam)
                                            //  +' принят в '+IntToStr(Cmnd.cmParam));
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
                                        AddProto(plInfo, SockTitle, 'Отрицательный ответ ('+IntToStr(Cmnd.cmCommand)
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
                                          AddProto(plInfo, SockTitle, 'Пакет принят Id='
                                            +IntToStr(J));
                                        IncCounter(RecvPackCountLabel, lcRecvPack);
                                        Application.ProcessMessages;
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
                                            //Application.ProcessMessages;    
                                            {AddProto(plInfo, SockTitle, 'Пакет Id='
                                              +IntToStr(PLongWord(ReceiveBuf)^)
                                              +' был получен');}    
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
    BufSizeLabel.Caption := IntToStr(ReceiveBufLen + J);
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
  if Sender=nil then
  begin
    //BufProgressBar.Position := 0;
    BufProgressBar.Hide;
  end
  else begin
    BaseSend.Free;
    BaseSend := nil;
    BaseRecv.Free;
    BaseRecv := nil;
    AccList.Free;
    MailForm := nil;
  end;
end;

procedure TMailForm.ClientSocketDisconnect(Sender: TObject;
  Socket: TCustomWinSocket);
begin
  ClientTimer.Enabled := False;
  ConnectState := 0;
  FormDestroy(nil);
  AddProto(plInfo, SockTitle, 'Соединение с хостом разорвано');
end;

procedure TMailForm.FormShow(Sender: TObject);
begin
  if BtrDate1<>0 then
    try
      AfterOperFromEdit.Text := BtrTimeToStr(BtrDate1);
    except
      BtrDate1 := 0;
      AfterOperFromEdit.Text := '  :  ';
    end;
  if BtrDate2<>0 then
    try
      AfterOperToEdit.Text := BtrTimeToStr(BtrDate2);
    except
      BtrDate2 := 0;
      AfterOperToEdit.Text := '  :  ';
    end;
  if BtrDate1=0 then
  begin
    case DayOfWeek(Date) of
      2..5:
        BtrDate1 := TimeToBtrTime(StrToTime('16:10'));
      6, 7:
        BtrDate1 := TimeToBtrTime(StrToTime('15:10'));
    end;
    AfterOperFromEdit.Text := BtrTimeToStr(BtrDate1);
  end;
  if BtrDate2=0 then
  begin
    case DayOfWeek(Date) of
      2..5:
        BtrDate2 := TimeToBtrTime(StrToTime('19:00'));
      6, 7:
        BtrDate2 := TimeToBtrTime(StrToTime('18:00'));
    end;
    AfterOperToEdit.Text := BtrTimeToStr(BtrDate2);
  end;
  FillCorrList(CorrWideComboBox.Items, 0);
  CorrWideComboBoxClick(nil);
  if FastPrep then
    PostMessage(Handle, WM_SYSCOMMAND, ID_BEGINPRC, 0);
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
    if (IdleTimePeriod>WaitHostTimeOut) and Process then
    begin
      MailForm.AddProto(plWarning, 'Timer', PChar('Разрыв по таймауту '
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
end;

procedure TMailForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := not Process;
end;

procedure TMailForm.ResendCheckBoxClick(Sender: TObject);
begin
  if Sender<>nil then
    ResendGroupBox.Visible := ResendCheckBox.Checked;
  if ResendGroupBox.Visible then
  begin
    CorrWideComboBox.DroppedWidth := 270;
    FormActivate(nil);
  end
  else
    ResendCheckBox.Font.Color := clWindowText;
end;

type
  PAccInfoRec = ^TAccInfoRec;
  TAccInfoRec = record
    aiNumber: TAccount;
    aiName:   TKeeperName;
    aiIder:   Integer;
    aiDateO, aiDateC: Word;
  end;

procedure TMailForm.CorrWideComboBoxKeyPress(Sender: TObject;
  var Key: Char);
begin
  Key := RusToLat(Key);
  if not ((Key in ['0'..'9', 'a'..'z', 'A'..'Z'])
    or (Key < #32)) then
  begin
    Key := #0;
    MessageBeep(0)
  end
  else
    Key := UpCase(Key);
end;

procedure TMailForm.FormActivate(Sender: TObject);
var
  E: Boolean;
  I: Integer;
begin
  JustOpenCheckBox.Enabled := (FromDateEdit.Date>0) and (ToDateEdit.Date>0);
  if not JustOpenCheckBox.Enabled then
    JustOpenCheckBox.Checked := False;
  E := (CorrWideComboBox.ItemIndex>=0) and JustOpenCheckBox.Enabled
    and (FromDateEdit.Date<=ToDateEdit.Date);
  if E then
  begin
    I := AccCheckListBox.Items.Count-1;
    while (I>=0) and not AccCheckListBox.Checked[I] do
      Dec(I);
    E := I>=0;
  end;
  if E then
    ResendCheckBox.Font.Color := clWindowText
  else
    ResendCheckBox.Font.Color := clMaroon;
  //ResendCheckBox.Enabled := E;
  //BaseCheckBoxClick(nil); ??
end;

procedure TMailForm.CorrWideComboBoxClick(Sender: TObject);
var
  Corr, Res, Len, C: Integer;
  AccRec: TAccRec;
  P: PAccInfoRec;
begin
  ResendCheckBox.Font.Color := clMaroon;

  RemLabel.Visible := True;
  FromDateEdit.Visible := not RemLabel.Visible;
  FromDate.Visible := not RemLabel.Visible;
  ToDateEdit.Visible := not RemLabel.Visible;
  ToLabel.Visible := not RemLabel.Visible;
  JustOpenCheckBox.Enabled := False;

  RemLabel.Caption := '';
  AllAccCheckBox.Enabled := False;
  AllAccCheckBox.Checked := False;
  //OkBtn.Enabled := False;  ???
  AccCheckListBox.Items.Clear;
  AccList.Clear;
  if CorrWideComboBox.ItemIndex>=0 then
  begin
    if AccDataSet<>nil then
    begin
      Corr := Integer(CorrWideComboBox.Items.Objects[CorrWideComboBox.ItemIndex]);
      if Corr>0 then
      begin
        C := Corr;
        Len := SizeOf(AccRec);
        Res := AccDataSet.BtrBase.GetGE(AccRec, Len, C, 2);
        if Res=0 then
        begin
          while (Res=0) and (Corr=C) do
          begin
            New(P);
            with P^ do
            begin
              aiNumber := AccRec.arAccount;
              aiName := AccRec.arName;
              aiIder := AccRec.arIder;
              aiDateO := AccRec.arDateO;
              aiDateC := AccRec.arDateC;
            end;
            AccList.Add(P);
            Len := SizeOf(AccRec);
            Res := AccDataSet.BtrBase.GetNext(AccRec, Len, C, 2);
          end;
        end;
        if AccList.Count>0 then
        begin
          JustOpenCheckBox.Checked := False;
          SearchIndexComboBoxClick(nil);
          AllAccCheckBox.Enabled := True;
          RemLabel.Visible := False;
          FromDateEdit.Visible := not RemLabel.Visible;
          FromDate.Visible := not RemLabel.Visible;
          ToDateEdit.Visible := not RemLabel.Visible;
          ToLabel.Visible := not RemLabel.Visible;
        end
        else
          RemLabel.Caption := 'Нет счетов';
      end
      else
        RemLabel.Caption := 'Нет идентификатора';
    end
    else
      RemLabel.Caption := 'База счетов закрыта';
  end;
end;

procedure TMailForm.AllAccCheckBoxClick(Sender: TObject);
var
  I: Integer;
begin
  AccCheckListBox.Enabled := not AllAccCheckBox.Checked;
  AccCheckListBox.ParentColor := AllAccCheckBox.Checked;
  if not AccCheckListBox.ParentColor then
    AccCheckListBox.Color := clWindow;
  if AllAccCheckBox.Checked then
    for I := 0 to AccCheckListBox.Items.Count-1 do
      AccCheckListBox.Checked[I] := True;
  FormActivate(nil);
end;

procedure TMailForm.FromDateEditAcceptDate(Sender: TObject;
  var ADate: TDateTime; var Action: Boolean);
begin
  ToDateEdit.Date := ADate;
end;

const
  SortIndex: Integer = 0;

function AccInfoCompare(Key1, Key2: Pointer): Integer;
var
  k1: PAccInfoRec absolute Key1;
  k2: PAccInfoRec absolute Key2;
begin
  Result := 0;
  case SortIndex of
    1:
      Result := CompareResortedAcc(k1^.aiNumber, k2^.aiNumber);
    else
      begin
        if k1^.aiNumber<k2^.aiNumber then
          Result := -1
        else
          if k1^.aiNumber>k2^.aiNumber then
            Result := 1;
      end;
  end;
end;

var
  MaskChanged: Boolean = True;

procedure TMailForm.FillAccTable;
var
  d1, d2: Word;
  FullMask: Boolean;
  I: Integer;
  PAccInfo: PAccInfoRec;
  Buf: array[0..127] of Char;
  S: string;
begin
  if JustOpenCheckBox.Checked then
  begin
    try
      d1 := DateToBtrDate(FromDateEdit.Date);
    except
      d1 := 0;
    end;
    try
      d2 := DateToBtrDate(ToDateEdit.Date);
      if d2=0 then
        d2 := $FFFF;
    except
      d2 := $FFFF;
    end;
  end;
  while Length(MaskComboBox.Text)<SizeOf(TAccount) do
    MaskComboBox.Text := MaskComboBox.Text + '?';
  for I := 0 to AccList.Count-1 do
  begin
    PAccInfo := AccList.Items[I];
    with PAccInfo^ do
    begin
      if (FullMask or Masked(aiNumber, MaskComboBox.Text))
        and (not JustOpenCheckBox.Checked or
        (aiDateO<d2) and ((aiDateC=0) or (d1<=aiDateC))) then
      begin
        StrLCopy(Buf, aiNumber, SizeOf(aiNumber));
        S := StrPas(Buf);
        StrLCopy(Buf, aiName, SizeOf(aiName));
        DosToWin(Buf);
        S := S+' | '+StrPas(Buf);
        AccCheckListBox.Items.AddObject(S, TObject(aiIder));
      end;
    end;
  end;
  MaskChanged := False;
end;

procedure TMailForm.SearchIndexComboBoxClick(Sender: TObject);
begin
  AccCheckListBox.Items.Clear;
  MaskComboBox.Enabled := False;
  if SearchIndexComboBox.Enabled then
  begin
    if SearchIndexComboBox.ItemIndex<0 then
      SearchIndexComboBox.ItemIndex := 0;
    Screen.Cursor := crHourGlass;
    try
      SortIndex := SearchIndexComboBox.ItemIndex;
      Application.ProcessMessages;
      AccList.Sort(AccInfoCompare);
      FillAccTable;
      AllAccCheckBoxClick(nil);
      MaskComboBox.Enabled := True;
    finally
      Screen.Cursor := crDefault;
    end;
  end;
end;

procedure TMailForm.MaskComboBoxChange(Sender: TObject);
begin
  MaskChanged := True;
end;

procedure TMailForm.MaskComboBoxExit(Sender: TObject);
begin
  if MaskChanged then
  begin
    MaskChanged := False;
    SearchIndexComboBoxClick(nil);
  end;
end;

procedure TMailForm.MaskComboBoxKeyPress(Sender: TObject;
  var Key: Char);
begin
  if not ((Key in ['0'..'9','?']) or (Key < #32)) then
  begin
    Key := #0;
    MessageBeep(0)
  end;
end;

procedure TMailForm.FromDateEditChange(Sender: TObject);
begin
  JustOpenCheckBox.Checked := False;
  FormActivate(Sender);
end;

procedure TMailForm.HorzSplitterCanResize(Sender: TObject;
  var NewSize: Integer; var Accept: Boolean);
begin
  Accept := NewSize>=35;
end;

procedure TMailForm.FileCheckBoxClick(Sender: TObject);
begin
  if FileCheckBox.Checked then
    SignFileCheckBox.Checked := False;
  SignFileCheckBox.Enabled := not FileCheckBox.Checked;
end;

var
  AfterOperFromEditChanged: Boolean = False;
  AfterOperToEditChanged: Boolean = False;

procedure TMailForm.AfterOperFromEditChange(Sender: TObject);
begin
  AfterOperFromEditChanged := True;
end;

procedure TMailForm.AfterOperFromEditExit(Sender: TObject);
begin
  if AfterOperFromEditChanged then
    BtrDate1 := TimeToBtrTime(StrToTime(AfterOperFromEdit.Text));
end;

procedure TMailForm.AfterOperFromEditKeyDown(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  if Key=VK_RETURN then
  begin
    AfterOperFromEditChange(nil);
    AfterOperFromEditExit(nil);
  end;
end;

procedure TMailForm.AfterOperToEditChange(Sender: TObject);
begin
  AfterOperToEditChanged := True;
end;

procedure TMailForm.AfterOperToEditExit(Sender: TObject);
begin
  if AfterOperToEditChanged then
    BtrDate2 := TimeToBtrTime(StrToTime(AfterOperToEdit.Text));
end;

procedure TMailForm.AfterOperToEditKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key=VK_RETURN then
  begin
    AfterOperToEditChange(nil);
    AfterOperToEditExit(nil);
  end;
end;

end.
