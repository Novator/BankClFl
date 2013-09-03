unit ConnectFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls, PostMachineFrm, ScktComp, Menus, Btrieve, CommCons,
  CrySign, Utilits, ActnList, Common, BtrDS, Registr, BankCnBn, StrUtils;

const
  WM_UPDATECOUNTER = WM_USER + 126;

const
  UC_REFRESH = 0;
  UC_ADD = 1;
  UC_DELETE = 2;
  UC_GETINDEX = 3;

var
  TimerSocketIndex: Integer = -1;

type
  PSocketInfo = ^TSocketInfo;
  TSocketInfo = record
    siSocket: TCustomWinSocket;
    siLogin: TAbonLogin;
    siType: Byte;
    siLastId: DWord;
    siHardId: DWord;
    siIdleTime: DWord;        {время молчания}
    siStep: TConnectionStep;  {шаг обмена}
    siSendBuf: Pointer;       {указатель на область отправленных данных/или команды}
    siReceiveBuf: PChar;      {указатель на область полученных данных}
    siReceiveBufLen: DWord;   {полученная длина}
    siReceiveDataLen: DWord;  {ожидаемая длинна данных}
    siProcessing: Boolean;    {флаг обработки данных}
  end;

  TSocketInfoList = class(TList)
  public
    function IndexOfSocket(Socket: TCustomWinSocket): Integer;
    procedure Delete(Index: Integer);
    procedure Clear; override;
    destructor Destroy; override;
  end;

type
  TConnectForm = class(TDataBaseForm)
    TopPanel: TPanel;
    Vert1Splitter: TSplitter;
    ConnectGroupBox: TGroupBox;
    ConnectCountLabel: TLabel;
    ConnectListBox: TListBox;
    ConnectPanel: TPanel;
    PropGroupBox: TGroupBox;
    PropMemo: TMemo;
    PropPanel: TPanel;
    SendMesPanel: TPanel;
    SendMesMemo: TMemo;
    MainMenu: TMainMenu;
    EditItem: TMenuItem;
    RunItem: TMenuItem;
    ServerSocket: TServerSocket;
    Timer: TTimer;
    ActionList: TActionList;
    RunAction: TAction;
    StopAction: TAction;
    BreakAction: TAction;
    StopItem: TMenuItem;
    BreakItem: TMenuItem;
    EditBreaker1: TMenuItem;
    procedure ConnectPanelClick(Sender: TObject);
    procedure PropPanelClick(Sender: TObject);
    procedure SendMesMemoKeyPress(Sender: TObject; var Key: Char);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure RunActionExecute(Sender: TObject);
    procedure StopActionExecute(Sender: TObject);
    procedure ServerSocketListen(Sender: TObject;
      Socket: TCustomWinSocket);
    procedure ServerSocketClientConnect(Sender: TObject;
      Socket: TCustomWinSocket);
    procedure ServerSocketClientDisconnect(Sender: TObject;
      Socket: TCustomWinSocket);
    procedure ServerSocketAccept(Sender: TObject;
      Socket: TCustomWinSocket);
    procedure ServerSocketClientError(Sender: TObject;
      Socket: TCustomWinSocket; ErrorEvent: TErrorEvent;
      var ErrorCode: Integer);
    procedure ServerSocketClientRead(Sender: TObject;
      Socket: TCustomWinSocket);
    procedure BreakActionExecute(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure AccesPanelMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure AccesPanelMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure TimerTimer(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Vert1SplitterCanResize(Sender: TObject; var NewSize: Integer;
      var Accept: Boolean);
  private
    procedure WMUpdateCounter(var Message: TMessage); message WM_UPDATECOUNTER;
  public
    SocketInfoList: TSocketInfoList;
  end;

var
  ConnectForm: TConnectForm = nil;
  OldMach: Boolean;
  AbonId: array [0..20] of string;
  AbonIdCounter: Integer = 0;

implementation

{$R *.DFM}

function TSocketInfoList.IndexOfSocket(Socket: TCustomWinSocket): Integer;
begin
  Result := 0;
  while (Result<Count) and (PSocketInfo(Items[Result])^.siSocket<>Socket) do
    Inc(Result);
  if Result = Count then
    Result := -1;
end;

procedure TSocketInfoList.Delete(Index: Integer);
var
  P: PSocketInfo;
begin
  P := Items[Index];
  if P<>nil then
  begin
    try
      with P^ do
      begin
        if siSendBuf<>nil then
        begin
          FreeMem(siSendBuf);
          siSendBuf := nil;
        end;
        if siReceiveBuf<>nil then
        begin
          FreeMem(siReceiveBuf);
          siReceiveBuf := nil;
        end;
      end;
    finally
      Dispose(P);
    end;
  end;
  inherited Delete(Index);
end;

procedure TSocketInfoList.Clear;
begin
  while Count>0 do
    Delete(Count-1);
  inherited;
end;

destructor TSocketInfoList.Destroy;
begin
  Clear;
  inherited;
end;

var
  AbonIdDataSet: TExtBtrDataSet = nil;
  AbonDataSet: TExtBtrDataSet = nil;
  PackDataSet: TExtBtrDataSet = nil;
  OldPackDataSet: TExtBtrDataSet = nil;               //Добавлено Меркуловым
  SmallBufSize: Integer = 800;
  SleepAfterSmall: Integer = 100;

procedure TConnectForm.FormCreate(Sender: TObject);
begin
  SocketInfoList := TSocketInfoList.Create;
  if not GetRegParamByName('SmallBufSize', CommonUserNumber, SmallBufSize) then
    SmallBufSize := 800;
  if not GetRegParamByName('SleepAfterSmall', CommonUserNumber, SleepAfterSmall) then
    SleepAfterSmall := 100;
  {with PostMachineForm do
  begin
    AddToolBtn(nil, Self);
    AddToolBtn(RunAction, Self);
    AddToolBtn(StopAction, Self);
    AddToolBtn(BreakAction, Self);
  end;}
  AbonIdDataSet := GetGlobalBase(biAbonId) as TExtBtrDataSet;
  AbonDataSet := GetGlobalBase(biAbon) as TExtBtrDataSet;
  PackDataSet := GetGlobalBase(biPost) as TExtBtrDataSet;
  OldPackDataSet := GetGlobalBase(biPostOld) as TExtBtrDataSet;//Добавлено Меркуловым
end;

var
  EnterTimeout, ErrorTimeout, AuthedTimeout, TimerInterval, ServerPort,
   OldMachLock: DWord;

procedure TConnectForm.RunActionExecute(Sender: TObject);
const
  MesTitle: PChar = 'Запуск сервера';
begin
  if IsCryptoEngineInited then
  begin
    if not ServerSocket.Active then
    begin
      if not GetRegParamByName('EnterTimeout', CommonUserNumber, EnterTimeout) then
        EnterTimeout := 40;
      if not GetRegParamByName('ErrorTimeout', CommonUserNumber, ErrorTimeout) then
        ErrorTimeout := 15;
      if not GetRegParamByName('AuthedTimeout', CommonUserNumber, AuthedTimeout) then
        AuthedTimeout := 180;
      if not GetRegParamByName('TimerInterval', CommonUserNumber, TimerInterval) then
        TimerInterval := 5;
      OldMachLock := 0;
      if OldMach then
      begin
        if not GetRegParamByName('MailerPortOld', CommonUserNumber, ServerPort) then
          ServerPort := 10000;
        if not GetRegParamByName('OldMachLock', CommonUserNumber, OldMachLock) then
          OldMachLock := 0;
      end
      else begin
        if not GetRegParamByName('MailerPort', CommonUserNumber, ServerPort) then
          ServerPort := 10000;
      end;
      try
        ServerSocket.Port := ServerPort;
        ServerSocket.Active := True;
      finally
        StopAction.Enabled := ServerSocket.Active;
        RunAction.Enabled := not StopAction.Enabled;
      end;
    end
    else begin
      MessageBox(Handle, 'Сервер уже активен',
        MesTitle, MB_OK or MB_ICONWARNING);
      StopAction.Enabled := True;
    end;
  end
  else
    MessageBox(Handle, 'СКЗИ не инициализировано. Запуск машины невозможен',
      MesTitle, MB_OK or MB_ICONWARNING);
end;

const
  ServerSocketMes: PChar = 'Socket';

procedure TConnectForm.StopActionExecute(Sender: TObject);
const
  MesTitle: PChar = 'Останов сервера';
var
  I: Integer;
begin
  if ServerSocket.Active then
  begin
    I := ServerSocket.Socket.ActiveConnections;
    if (I<=0) or (MessageBox(Handle, PChar('В данный момент подключено клиентов: '
      +IntToStr(I)+#13#10'Разорвать эти соединения?'), MesTitle,
      MB_YESNOCANCEL or MB_ICONWARNING)=ID_YES) then
    begin
      try
        ServerSocket.Active := False;
      finally
        StopAction.Enabled := ServerSocket.Active;
        RunAction.Enabled := not RunAction.Enabled;
        if not ServerSocket.Active then
        begin
          Timer.Enabled := False;
          AddProtoMes(plInfo, ServerSocketMes, 'Stop listen.');
          PostMachineForm.StatusBar.Panels.Items[piListen].Text := '';
          ConnectListBox.Items.Clear;
          PostMessage(Handle, WM_UPDATECOUNTER, UC_REFRESH, 0);
        end;
      end;
    end;
  end;
end;

procedure TConnectForm.ServerSocketListen(Sender: TObject;
  Socket: TCustomWinSocket);
begin
  Timer.Interval := TimerInterval * 1000;
  Timer.Enabled := True;
  AddProtoMes(plInfo, ServerSocketMes, 'Begin listen '
    +IntToStr(ServerSocket.Port)+' ('+IntToStr(TimerInterval)+'/'
    +IntToStr(EnterTimeout)+':'+IntToStr(ErrorTimeout)+':'
    +IntToStr(AuthedTimeout)+')...');
  PostMachineForm.StatusBar.Panels.Items[piListen].Text := 'Listen';
end;

procedure TConnectForm.FormCloseQuery(Sender: TObject;
  var CanClose: Boolean);
begin
  if ServerSocket.Active then
    StopActionExecute(nil);
  Application.ProcessMessages;
  CanClose := not ServerSocket.Active;
  Application.ProcessMessages;
end;

procedure TConnectForm.WMUpdateCounter(var Message: TMessage);
var
  Socket: TCustomWinSocket;
  SocketInfoPtr: PSocketInfo;
  I: Integer;
begin
  inherited;
  Socket := TCustomWinSocket(Message.LParam);
  with ConnectListBox do
    case Message.WParam of
      UC_ADD:
        begin
          New(SocketInfoPtr);
          FillChar(SocketInfoPtr^, SizeOf(TSocketInfo), #0);
          with SocketInfoPtr^ do
          begin
            siSocket := Socket;
            siStep := csEnter;
            siSendBuf := nil;
            siReceiveBuf := nil;
            siProcessing := False;
          end;
          Message.Result := Items.AddObject('N'+Socket.RemoteAddress,
            TObject(Socket));
          SocketInfoList.Add(SocketInfoPtr);
        end;
      UC_DELETE, UC_GETINDEX:
        begin
          Message.Result := Items.IndexOfObject(TObject(Socket));
          if (Message.WParam=UC_DELETE) and (Message.Result>=0) then
          begin
            Items.Delete(Message.Result);
            I := SocketInfoList.IndexOfSocket(Socket);
            if I>=0 then
              SocketInfoList.Delete(I)
            else
              AddProtoMes(plError, 'DeleteSocket', 'Info not found Ab='
                +IntToStr(LongWord(Socket)));
          end;
        end;
    end;
  Application.ProcessMessages;
  ConnectCountLabel.Caption := IntToStr(ServerSocket.Socket.ActiveConnections)
    +'='+IntToStr(ConnectListBox.Items.Count)
    +'='+IntToStr(SocketInfoList.Count);
end;

procedure TConnectForm.ServerSocketClientConnect(Sender: TObject;
  Socket: TCustomWinSocket);
begin
  AddProtoMes(plInfo, ServerSocketMes, 'Connect Ab='+IntToStr(LongWord(Socket))
    +' ['+Socket.RemoteAddress+'] '+Socket.RemoteHost);
  SendMessage(Handle, WM_UPDATECOUNTER, UC_ADD, Integer(Socket));
end;

procedure TConnectForm.ServerSocketAccept(Sender: TObject;
  Socket: TCustomWinSocket);
var
  I: Integer;
  S: string;
begin
  //AddProtoMes(plInfo, ServerSocketMes, 'Connected from: ' + Socket.RemoteAddress);
  I := SendMessage(Handle, WM_UPDATECOUNTER, UC_GETINDEX, Integer(Socket));
  if I>=0 then
  begin
    S := ConnectListBox.Items.Strings[I];
    if Length(S)>0 then
      S[1] := 'A';
    ConnectListBox.Items.Strings[I] := S;
  end;
  {else
    ShowMessage('No '+IntToStr(I));}
end;

procedure TConnectForm.ServerSocketClientDisconnect(Sender: TObject;
  Socket: TCustomWinSocket);
var
  SocketInfoPtr: PSocketInfo;
  I, J: Integer;
  S: string;
begin
  J:=0;
  S := 'Disconn Ab='+IntToStr(LongWord(Socket));
  I := SocketInfoList.IndexOfSocket(Socket);
  if I>=0 then
  begin
    SocketInfoPtr := SocketInfoList.Items[I];
    while J<AbonIdCounter do
    begin
      if AbonId[J] = SocketInfoPtr^.siLogin then
      begin
        while (J<(AbonIdCounter-1)) do
          begin
          AbonId[J]:=AbonId[J+1];
          Inc(J);
          end;
        Dec(AbonIdCounter);
      end;
      Inc(J);
    end;
    if SocketInfoPtr^.siStep=csData then
      I := plInfo
    else begin
      I := plWarning;
      S := S+' abnormal '+IntToStr(Ord(SocketInfoPtr^.siStep));
    end;
  end
  else begin
    I := plError;
    S := S+' no info';
  end;
  PostMessage(Handle, WM_UPDATECOUNTER, UC_DELETE, Integer(Socket));
  AddProtoMes(I, ServerSocketMes, S);
end;

procedure TConnectForm.ServerSocketClientError(Sender: TObject;
  Socket: TCustomWinSocket; ErrorEvent: TErrorEvent;
  var ErrorCode: Integer);
begin
  AddProtoMes(plWarning, ServerSocketMes, 'Error '+IntToStr(ErrorCode)+' Ab='
    +IntToStr(LongWord(Socket)));
end;

(*function HideZeroInBlock(Src: PChar; SrcLen: Integer; Dst: PChar;
  MaxDstLen: Integer; var DstLen: Integer): Boolean;
var
  I: Integer;
begin
  Result := False;
  DstLen := 0;
  I := 0;
  while (I<SrcLen) and ((Dst=nil) or (DstLen<MaxDstLen)) do
  begin
    if Src[I] in [#0, #255] then
    begin
      if Dst=nil then
        Inc(DstLen)
      else begin
        if Src[I]=#0 then
        begin
          Dst[DstLen] := #255;
          Inc(DstLen);
          Dst[DstLen] := #254;
        end
        else begin
          Dst[DstLen] := #255;
          Inc(DstLen);
          Dst[DstLen] := #255;
        end;
      end;
    end
    else
      if Dst<>nil then
        Dst[DstLen] := Src[I];
    Inc(I);
    Inc(DstLen);
  end;
  Result := I>=SrcLen;
end;

function UnhideZeroInBlock(Src: PChar; SrcLen: Integer; Dst: PChar;
  MaxDstLen: Integer; var DstLen: Integer): Boolean;
var
  I: Integer;
begin
  Result := False;
  DstLen := 0;
  I := 0;
  while (I<SrcLen) and ((Dst=nil) or (DstLen<MaxDstLen)) do
  begin
    if (Src[I]=#255) and (I+1<SrcLen) and (Src[I+1] in [#254, #255]) then
    begin
      Inc(I);
      if Dst<>nil then
      begin
        if Src[I]=#254 then
          Dst[DstLen] := #0
        else
          Dst[DstLen] := #255;
      end;
    end
    else
      if Dst<>nil then
        Dst[DstLen] := Src[I];
    Inc(I);
    Inc(DstLen);
  end;
  Result := I>=SrcLen;
end;*)

const
  piNone = 0;
  piData = 1;
  piMes  = 2;

(*function SendCorrTextToSocket(Socket: TCustomWinSocket; Buf: PChar;
  BufLen, MaxSendSize: Integer; PackIdIndex: Integer): Boolean;
var
  L, I, K: Integer;
  Text: PChar;
  S: string;
begin
  try
    if (Buf<>nil) and (BufLen>0) then
    begin
      if HideZeroInBlock(Buf, BufLen, nil, 0, L) then
      begin
        Text := AllocMem(L+1);
        try
          if HideZeroInBlock(Buf, BufLen, Text, L+1, L) then
          begin
            Text[L] := #0;
            if StrLen(Text)=L then
            begin
              if (L<=MaxSendSize) or (PackIdIndex<>piNone) then
              begin
                if PackIdIndex<>piNone then
                begin
                  K := 0;
                  repeat
                    case PackIdIndex of
                      piData:
                        S := 'DATA';
                      piMes:
                        S := 'MES';
                      else
                        S := 'PACK';
                    end;
                    I := (K*MaxSendSize)+MaxSendSize;
                    if I>L then
                      I := L;
                    S := S+'.'+IntToStr(K)+'='+Copy(Text,
                      K*MaxSendSize+1, I-K*MaxSendSize);
                    Socket.SendText(S);
                    Inc(K);
                  until I>=L;
                end
                else
                  Socket.SendText(Text);
                Result := True;
              end
              else
                AddProtoMes(plWarning1, ?, 'Получается слишком длинная отправка');
            end
            else
              AddProtoMes(plWarning1, ?, 'Кодированый текст ошибочной длины');
          end
          else
            AddProtoMes(plWarning1, ?, 'Не удалось закодировать данные');
        finally
          FreeMem(Text);
        end;
      end
      else
        AddProtoMes(plWarning1, ?, 'Не удалось узнать длину');
    end
    else
      AddProtoMes(plWarning1, ?, 'Не указаны данные для отправки');
  except
    Result := False;
  end;
end;*)

function StrLPas(Buf: PChar; BufLen: Integer): string;
var
  I: Integer;
begin
  Result := '';
  if Buf<>nil then
    for I := 0 to BufLen-1 do
      Result := Result+Buf[I];
end;

function AnalizeHelloStr(S: string; SocketInfoPtr: PSocketInfo): Integer;
var
  I: Integer;
  V: string;
begin
  Result := 0;
  if (AbonIdCounter<0) or (AbonIdCounter>20) then      //Добавлено Меркуловым
    AbonIdCounter := 0;                                //Добавлено Меркуловым
  S := Trim(S);
  if Length(S)>0 then
  begin
    I := Pos(' ', S);
    while (Length(S)>0) and (Result>=0) do
    begin
      if I>0 then
      begin
        V := Copy(S, 1, I-1);
        Delete(S, 1, I);
      end
      else begin
        V := S;
        S := '';
      end;
      V := Trim(V);
      //AddProtoMes(plWarning1, ?, 'V='+V+']');
      S := Trim(S);
      Inc(Result);
      with SocketInfoPtr^ do
        case Result of
          1:
            begin
              StrPLCopy(siLogin, UpperCase(V),
                SizeOf(siLogin)-1);
              if StrLen(siLogin)<=0 then
                Result := -Result;
            end;
          2:
            if OldMach then
            begin
              if UpperCase(V)<>'V2' then
                Result := -Result;
            end
            else begin
              if UpperCase(V)<>'VZ' then            //Добавлено Меркуловым
              begin                                 //Добавлено Меркуловым
                if UpperCase(V)<>'V3' then
                  Result := -Result
                else                                 //Добавлено Меркуловым
                begin                                //Добавлено Меркуловым
                  AbonId[AbonIdCounter] := siLogin;  //Добавлено Меркуловым
                  Inc(AbonIdCounter);                //Добавлено Меркуловым
                  //MessageBox(ParentWnd,Pchar(IntToStr(AbonIdCounter)),'1',mb_ok);
                end;                                 //Добавлено Меркуловым
              end;                                   //Добавлено Меркуловым
            end;
          3:
            begin
              Delete(V, 1, 1);
              Val('$'+V, siLastId, I);
              if I<>0 then
                Result := -Result;
            end;
          4:
            begin
              Delete(V, 1, 1);
              Val('$'+V, siHardId, I);
              if I<>0 then
                Result := -Result;
            end;
        end;
      I := Pos(' ', S);
    end;
    if (Result>0) and (Result<4) then
      Result := -5;
  end;
end;

function RegistrateAbon(SocketInfoPtr: PSocketInfo; Update: Boolean): Integer;
const
  MesTitle: PChar = 'Регистрация абонента';
var
  Res, Len, I, Len2: Integer;
  AbonRec: TAbonentRec;
  AbonIdRec: TAbonIdRec;
  AbonLogin: TAbonLogin;
  NeedUpd: Boolean;
begin
  Result := -1;
  FillChar(AbonLogin, SizeOf(AbonLogin), #0);
  StrLCopy(@AbonLogin, @SocketInfoPtr.siLogin, SizeOf(AbonLogin)-1);
  {I := StrLen(AbonLogin)+1;
  while I<SizeOf(AbonLogin) do
  begin
    AbonLogin[I] := #0;
    Inc(I);
  end;}
  Len := SizeOf(AbonRec);
  Res := AbonDataSet.BtrBase.GetEqual(AbonRec, Len, AbonLogin, 1);
  //showmessage(SocketInfoPtr.siLogin+'  '+inttostr(res));
  if Res=0 then
  begin
    if (AbonRec.abLock and alSend>0) and
      (AbonRec.abLock and alRecv>0) then
    begin   {полная блокировка}
      Result := 3;
      AddProtoMes(plWarning, MesTitle,
        'Абонент ['+AbonLogin+'] полностью блокирован Ab='
        +IntToStr(LongWord(SocketInfoPtr^.siSocket)));
    end
    else begin   {проверим остальное}
      NeedUpd := False;
      I := AbonRec.abIder;
      Len2 := SizeOf(AbonIdRec);
      Res := AbonIdDataSet.BtrBase.GetEqual(AbonIdRec, Len2, I, 0);
      if Res<>0 then
      begin
        if Res=4 then
        begin
          FillChar(AbonIdRec, SizeOf(AbonIdRec), #0);
          AbonIdRec.aiIder := AbonRec.abIder;
        end
        else begin
          AddProtoMes(plError, MesTitle,
            'Ошибка поиска информации об абоненте Id='+IntToStr(I)
            +' BtrErr='+IntToStr(Res)+' Ab='+IntToStr(
            LongWord(SocketInfoPtr^.siSocket)));
          Result := 6
        end;
      end;
      if Result<0 then
      begin
        case AbonRec.abLock and alOther of
          aloTake:
            if Update then
            begin
              if AbonIdRec.aiHardId<>SocketInfoPtr.siHardId then
                AddProtoMes(plInfo, MesTitle,
                  'HardId измененился с '+Dec2Hex(AbonIdRec.aiHardId, 8)
                  +' на '+Dec2Hex(SocketInfoPtr.siHardId, 8)
                  +' Ab='+IntToStr(LongWord(SocketInfoPtr^.siSocket)));
              AbonIdRec.aiHardId := SocketInfoPtr.siHardId;
            end;
          aloNew:
            if Update then
            begin
              AddProtoMes(plWarning, MesTitle,
                'Установка приватного режима HardId '+Dec2Hex(SocketInfoPtr.siHardId, 8)
                +' (было '+Dec2Hex(AbonIdRec.aiHardId, 8)+') Ab='
                +IntToStr(LongWord(SocketInfoPtr^.siSocket)));
              AbonIdRec.aiHardId := SocketInfoPtr.siHardId;
              AbonRec.abLock := (AbonRec.abLock and not alOther) or aloPrivat;
              NeedUpd := True;
            end;
          aloPrivat:
            begin
              if AbonIdRec.aiHardId<>SocketInfoPtr.siHardId then
              begin
                AddProtoMes(plWarning, MesTitle,
                  'Нарушение приватности: предложен другой HardId '+Dec2Hex(SocketInfoPtr.siHardId, 8)
                  +' (было '+Dec2Hex(AbonIdRec.aiHardId, 8)+') Ab='
                  +IntToStr(LongWord(SocketInfoPtr^.siSocket)));
                Result := 4;
              end;
            end;
        end;
        if Result<0 then
        begin
          if AbonIdRec.aiLastAuth<SocketInfoPtr.siLastId then
          begin
            if Update
              and (AbonIdRec.aiLastAuth+1<>SocketInfoPtr.siLastId) then
            begin
              AddProtoMes(plWarning, MesTitle,
                'Нарушение последовательности LastId '
                +IntToStr(SocketInfoPtr.siLastId)
                +' > '+IntToStr(AbonIdRec.aiLastAuth)
                +'. Проигнорировано Ab='+IntToStr(LongWord(SocketInfoPtr^.siSocket)));
            end;
            AbonIdRec.aiLastAuth := SocketInfoPtr.siLastId;
          end
          else begin
            AddProtoMes(plWarning, MesTitle,
              'Предложен неновый LastId '+IntToStr(SocketInfoPtr.siLastId)
              +' (последний '+IntToStr(AbonIdRec.aiLastAuth)+') Ab='+
              IntToStr(LongWord(SocketInfoPtr^.siSocket)));
            Result := 5;
          end;
        end;
      end;
    end;
    if Result<0 then
    begin
      SocketInfoPtr^.siType := AbonRec.abType;
      if Update then
      begin
        if Res=0 then
          Res := AbonIdDataSet.BtrBase.Update(AbonIdRec, Len2, I, 0)
        else begin
          AddProtoMes(plWarning, MesTitle, 'Ввод данных по абоненту ['
            +AbonLogin+'] Ab='+IntToStr(LongWord(SocketInfoPtr^.siSocket)));
          Len2 := SizeOf(AbonIdRec);
          Res := AbonIdDataSet.BtrBase.Insert(AbonIdRec, Len2, I, 0);
        end;
        if Res=0 then
        begin
          if (AbonRec.abWay<>awPostMach) or (AbonRec.abCrypt<>acDomenK) then
          begin
            NeedUpd := True;
            AbonRec.abWay := awPostMach;
            AbonRec.abCrypt := acDomenK;
            AddProtoMes(plWarning, MesTitle,
              'Переключен на новую почтовую машину ['+AbonLogin+'] Ab='
              +IntToStr(LongWord(SocketInfoPtr^.siSocket)));
          end;
          if NeedUpd then
          begin
            Res := AbonDataSet.BtrBase.Update(AbonRec, Len, AbonLogin, 1);
            if Res=0 then
              Result := 0
            else begin
              Result := 1000+Res;
              AddProtoMes(plError, MesTitle, 'Ошибка модификации абонента ['
                +AbonLogin+'] BtrErr='+IntToStr(Res)+' Ab='
                +IntToStr(LongWord(SocketInfoPtr^.siSocket)));
            end;
          end
          else
            Result := 0;
        end
        else begin
          AddProtoMes(plError, MesTitle,
            'Не удалось обновить данные по абоненту ['
              +AbonLogin+'] BtrErr='+IntToStr(Res)+' Ab='
              +IntToStr(LongWord(SocketInfoPtr^.siSocket)));
          Result := 7;
        end;
      end
      else
        Result := 0;
    end;
  end
  else begin
    if Res=4 then
    begin
      Result := 1;
      AddProtoMes(plError, MesTitle, 'Неизвестный абонент ['+AbonLogin+'] Ab='
        +IntToStr(LongWord(SocketInfoPtr^.siSocket)));
    end
    else begin
      Result := 2;
      AddProtoMes(plError, MesTitle, 'Ошибка поиска абонента ['+AbonLogin
        +'] BtrErr='+IntToStr(Res)+' Ab='+IntToStr(LongWord(SocketInfoPtr^.siSocket)));
    end;
  end;
end;

function InsertPack(Socket: TCustomWinSocket; Buf: PChar; BufLen: Integer;
  AbonType: Byte): Integer;
const
  MesTitle: PChar = 'Запись входящего пакета';
var
  Res, Len, Ider: Integer;
  AbonRec: TAbonentRec;
  AbonLogin: TAbonLogin;
  OldBase: Boolean;                                      //Добавлено Меркуловым
  i: Integer;                                            //Добавлено Меркуловым
begin
  OldBase := False;                                      //Добавлено Меркуловым
  if (PackDataSet<>nil) and (OldPackDataSet<>nil) then       //Изменено Меркуловым
  begin
    if (BufLen>SizeOf(TSndPack)-MaxPackSize)
      and (BufLen<=SizeOf(TSndPack)) then
    begin
      FillChar(AbonLogin, SizeOf(AbonLogin), #0);
      StrLCopy(@AbonLogin, @PSndPack(Buf)^.spNameR, SizeOf(AbonLogin)-1);
      Len := SizeOf(AbonRec);
      Res := AbonDataSet.BtrBase.GetEqual(AbonRec, Len, AbonLogin, 1);
      if Res=0 then
      begin
        if (AbonRec.abLock and alRecv=0) then
        begin
          AbonType := AbonType and atStatus;
          for i := 1 to AbonIdCounter do                //Добавлено Меркуловым
            if AbonId[i-1] = AbonLogin then               //Добавлено Меркуловым
              OldBase := True;                          //Добавлено Меркуловым
          if ((OldMachLock and 1=0) and (not OldBase)) or (AbonType=atBank) then  //Изменено Меркуловым
          begin
            if (AbonType=atBank) and (AbonRec.abType<>atBank) or
              (AbonType<>atBank) and (AbonRec.abType=atBank) then
            begin
              MakeRegNumber(rnInPack, Ider);
              if Ider>0 then
              begin
                with PSndPack(Buf)^ do
                begin
                  spIder := Ider;
                  spDateS := DateToBtrDate(Date);
                  spTimeS := TimeToBtrTime(Time);
                end;
                //Len := BufLen;
                if OldBase then                           //Добавлено Меркуловым
                  Res := OldPackDataSet.BtrBase.Insert(Buf^, BufLen, Ider, 0)//Добавлено Меркуловым
                else                                      //Добавлено Меркуловым
                  Res := PackDataSet.BtrBase.Insert(Buf^, BufLen, Ider, 0);
                if Res=0 then
                begin
                  Result := Ider;
                  AddProtoMes(plInfo, ServerSocketMes, 'Snd Ab='+IntToStr(LongWord(Socket))
                    +' Id='+IntToStr(Ider)+' Len='+IntToStr(BufLen));
                end
                else begin
                  Result := -4;
                  AddProtoMes(plError, MesTitle, 'Не удалось вставить пакет Id='
                    +IntToStr(Ider)+' BtrErr='+IntToStr(Res)+' Len='
                    +IntToStr(BufLen)+' Ab='+IntToStr(LongWord(Socket)));
                end;
              end
              else begin
                Result := -3;
                AddProtoMes(plError, MesTitle, 'Не удалось получить номер пакета Len='
                  +IntToStr(BufLen)+' Ab='+IntToStr(LongWord(Socket)));
              end;
            end
            else begin
              Result := -7;
              AddProtoMes(plWarning, MesTitle, 'Недопустимый получатель пакета ['
                +AbonLogin+'] Type='+IntToStr(AbonRec.abType));
            end;
          end
          else begin
            Result := -8;
            AddProtoMes(plWarning, MesTitle, 'Машина блокирована на прием');
          end;
        end
        else begin
          Result := -5;
          AddProtoMes(plWarning, MesTitle, 'Получатель пакета ['
            +AbonLogin+'] блокирован на прием');
        end;
      end
      else begin
        Result := -6;
        AddProtoMes(plWarning, MesTitle, 'Получатель пакета ['
          +AbonLogin+'] не найден BtrErr='+IntToStr(Res));
      end;
    end
    else begin
      Result := -2;
      AddProtoMes(plError, MesTitle, 'Недопустимая длина пакета Len='
        +IntToStr(BufLen));
    end;
  end
  else
    Result := -1;
end;

function GetFirstRcvPacket(Socket: TCustomWinSocket; ANameR: PChar;
  var Ider: Integer; var Buf: PChar): Integer;
const
  MesTitle: PChar = 'Чтение первого пакета';
var
  Res, Len: Integer;
  Key1: packed record
    kNameR: TAbonLogin;
    kFlRcv: Char;
  end;
  SndPack: TSndPack;
  OldBase: Boolean;                                      //Добавлено Меркуловым
  i: Integer;                                            //Добавлено Меркуловым
begin
  OldBase := False;                                      //Добавлено Меркуловым
  Result := -1;
  if (PackDataSet<>nil) and (OldPackDataSet<>nil) then    //Изменено Меркуловым
  begin
    //AddProtoMes(plWarning, ServerSocketMes,
    //  'Зап. пак. ['+ANameR+']');
    FillChar(Key1.kNameR, SizeOf(Key1.kNameR), #0);
    StrLCopy(@Key1.kNameR, ANameR, SizeOf(Key1.kNameR));
    Key1.kFlRcv := '0';
    Len := SizeOf(SndPack);
    for i:=1 to AbonIdCounter do                      //Добавлено Меркуловым
      if AbonId[i-1] = ANameR then                    //Добавлено Меркуловым
        OldBase := True;                              //Добавлено Меркуловым
    if OldBase then                                                   //Добавлно Меркуловым
      begin
      //MessageBox(ParentWnd,Pchar('Читаю из старой, Id='+IntToStr(AbonIdCounter)),'1',mb_ok);
      Res := OldPackDataSet.BtrBase.GetEqual(SndPack, Len, Key1, 1); //Добавлено Меркуловым
      end
    else                                                          //Добавлено Меркуловым
      Res := PackDataSet.BtrBase.GetEqual(SndPack, Len, Key1, 1);
    if Res=0 then
    begin
      AddProtoMes(plTrace, ServerSocketMes, 'Get Ab='
        +IntToStr(LongWord(Socket))+' Id='+IntToStr(SndPack.spIder));
      if Len>SizeOf(SndPack)-SizeOf(SndPack.spText) then
      begin
        SndPack.spDateR := DateToBtrDate(Date);
        SndPack.spTimeR := TimeToBtrTime(Time);
        Result := Len-2;  {убираем длину двух флагов}
        Ider := SndPack.spIder;
        Buf := AllocMem(Result);
        Move(SndPack, Buf^, 31);    {переносим запись, исключая флаги}
        Move(SndPack.spDateS, PRcvPack(Buf)^.rpDateS, 4);
        Move(SndPack.spDateR, PRcvPack(Buf)^.rpDateR, Result-35);
      end
      else begin
        Result := -3;
        AddProtoMes(plError, MesTitle, 'Пакет Id='+IntToStr(SndPack.spIder)
          +' слишком короток Len='+IntToStr(Len)+' Ab='+IntToStr(LongWord(Socket)));
      end;
    end
    else begin
      if Res=4 then
        Result := 0
      else begin
        Result := -2;
        AddProtoMes(plError, MesTitle, 'Ошибка поиска пакета BtrErr='
          +IntToStr(Res)+' для '+ANameR);
      end;
    end;
    //AddProtoMes(plWarning, ServerSocketMes, '222 '+IntToStr(Res));
  end;
end;

function SetRcvPack(Socket: TCustomWinSocket; Ider: Integer): Integer;
const
  MesTitle: PChar = 'Пометка пакета полученным';
var
  Res, Len: Integer;
  SndPack: TSndPack;
  //AbonRec: TAbonentRec;                                  //Добавлено Меркуловым
  OldBase: Boolean;                                      //Добавлено Меркуловым
  i: Integer;                                            //Добавлено Меркуловым
begin
  OldBase := False;                                      //Добавлено Меркуловым
  Result := -1;
  //if AbonIdCounter>0 then                                //Добавлено Меркуловым
  //  begin                                                //Добавлено Меркуловым
  //  Len := SizeOf(AbonRec);                              //Добавлено Меркуловым
  //  Res := AbonDataSet.BtrBase.GetEqual(AbonRec, Len, Ider, 0);//Добавлено Меркуловым
  //  end;                                                 //Добавлено Меркуловым
  if (PackDataSet<>nil) and (OldPackDataSet<>nil) then    //Изменено Меркуловым
  begin
    Len := SizeOf(SndPack);
    //for i:=1 to AbonIdCounter do                      //Добавлено Меркуловым
    //  if (Res=0) and (AbonId[i-1] = AbonRec.abLogin) then //Добавлено Меркуловым
    //if AbonIdCounter>0 then                             //Добавлено Меркуловым
      OldBase := True;                                  //Добавлено Меркуловым
    if OldBase then                                                //Добавлено Меркуловым
      begin
      Res := OldPackDataSet.BtrBase.GetEqual(SndPack, Len, Ider, 0);//Добавлено Меркуловым
      if Res<>0 then                                             //Добавлено Меркуловым
        OldBase := False;                                        //Добавлено Меркуловым
      end;
    if not OldBase then                                              //Добавлено Меркуловым
      Res := PackDataSet.BtrBase.GetEqual(SndPack, Len, Ider, 0);
    if Res=0 then
    begin
      Len := SizeOf(SndPack)-SizeOf(SndPack.spText); //усечение пакета
      with SndPack do
      begin
        spFlRcv := '1';
        spDateR := DateToBtrDate(Date);
        spTimeR := TimeToBtrTime(Time);
      end;
      if OldBase then                                 //Добавлено Меркуловым
        Res := OldPackDataSet.BtrBase.Update(SndPack, Len, Ider, 0)//Добавлено Меркуловым
      else                                            //Добавлено Меркуловым
        Res := PackDataSet.BtrBase.Update(SndPack, Len, Ider, 0);
      if Res=0 then
      begin
        Result := 0;
        AddProtoMes(plInfo, ServerSocketMes, 'Rcv Ab='+IntToStr(LongWord(Socket))
          +' Id='+IntToStr(SndPack.spIder));
      end
      else
        Result := -2;
    end
    else
      Result := -3;
  end;
end;

function GetFirstKvit(ANameS: PChar; var Buf: PChar): Integer;
const
  MesTitle: PChar = 'Поиск взятых пакетов';
var
  Res, Len: Integer;
  Key2: packed record
    kNameS: TAbonLogin;
    kFlRcv: Char;
  end;
  SndPack: TSndPack;
  OldBase: Boolean;                                      //Добавлено Меркуловым
  i: Integer;                                            //Добавлено Меркуловым
begin
  OldBase := False;                                      //Добавлено Меркуловым
  Result := 0;
  if (PackDataSet<>nil) and (OldPackDataSet<>nil) then   //Изменено Меркуловым
  begin
    //AddProtoMes(plWarning, ServerSocketMes,
    //  'Зап. квит. ['+ANameS+']');
    FillChar(Key2.kNameS, SizeOf(Key2.kNameS), #0);
    StrLCopy(@Key2.kNameS, ANameS, SizeOf(Key2.kNameS));
    Key2.kFlRcv := '1';
    Len := SizeOf(SndPack);
    for i:=1 to AbonIdCounter do                      //Добавлено Меркуловым
      if AbonId[i-1] = ANameS then                    //Добавлено Меркуловым
        OldBase := True;
    if ANameS = 'CBTCB' then                           //Добавлено Меркуловым
      OldBase := True;
    if OldBase then                                   //Добавлено Меркуловым
      begin                                           //Добавлено Меркуловым
      Res := OldPackDataSet.BtrBase.GetEqual(SndPack, Len, Key2, 2);//Добавлено Меркуловым
      if (ANameS = 'CBTCB') and (Res<>0) then         //Добавлено Меркуловым
        OldBase := False;                             //Добавлено Меркуловым
      end;                                            //Добавлено Меркуловым
    if not OldBase then                               //Добавлено Меркуловым
      Res := PackDataSet.BtrBase.GetEqual(SndPack, Len, Key2, 2);
    if Res=0 then
    begin
      Result := 8;
      Buf := AllocMem(Result);
      PLongWord(Buf)^ := SndPack.spIder;
      PWord(@Buf[4])^ := SndPack.spDateR;
      PWord(@Buf[6])^ := SndPack.spTimeR;
    end;
    //AddProtoMes(plWarning, ServerSocketMes, '333 '+IntToStr(Res));
  end;
end;

function RemovePacket(Socket: TCustomWinSocket; Ider: Integer): Integer;
const
  MesTitle: PChar = 'Удаление взятых пакетов';
var
  Res, Len: Integer;
  SndPack: TSndPack;
  //AbonRec: TAbonentRec;                                  //Добавлено Меркуловым
  OldBase: Boolean;                                      //Добавлено Меркуловым
  i: Integer;                                            //Добавлено Меркуловым
begin
  OldBase := False;                                      //Добавлено Меркуловым
  Result := -1;
  //if AbonIdCounter>0 then                                //Добавлено Меркуловым
  //  begin                                                //Добавлено Меркуловым
  //  Len := SizeOf(AbonRec);                              //Добавлено Меркуловым
  //  Res := AbonDataSet.BtrBase.GetEqual(AbonRec, Len, Ider, 0);//Добавлено Меркуловым
  //  end;                                                 //Добавлено Меркуловым
  if (PackDataSet<>nil) and (OldPackDataSet<>nil) then   //Изменено Меркуловым
  begin
    Len := SizeOf(SndPack);
    //for i:=1 to AbonIdCounter do                      //Добавлено Меркуловым
    //  if (Res=0) and (AbonId[i-1] = AbonRec.abLogin) then //Добавлено Меркуловым
    //if AbonIdCounter>0 then                         //Добавлено Меркуловым
      OldBase := True;                              //Добавлено Меркуловым
    if OldBase then                                                //Добавлено Меркуловым
      begin
      Res := OldPackDataSet.BtrBase.GetEqual(SndPack, Len, Ider,0);//Добавлено Меркуловым
      if Res<>0 then                                             //Добавлено Меркуловым
        OldBase := False;                                        //Добавлено Меркуловым
      end;
    if not OldBase then                                          //Добавлено Меркуловым
      Res := PackDataSet.BtrBase.GetEqual(SndPack, Len, Ider, 0);
    if Res=0 then
    begin
      if OldBase then                                 //Добавлено Меркуловым
        Res := OldPackDataSet.BtrBase.Delete(0)       //Добавлено Меркуловым
      else                                            //Добавлено Меркуловым
        Res := PackDataSet.BtrBase.Delete(0);
      if Res=0 then
      begin
        Result := 0;
        AddProtoMes(plInfo, ServerSocketMes, 'Del Ab='+IntToStr(LongWord(Socket))
          +' Id='+IntToStr(SndPack.spIder));
      end
      else
        Result := Res+100;
    end
    else
      Result := Res;
  end;
end;

function SendComAndBuf(Socket: TCustomWinSocket; Comnd: TExchangeCommand;
  Buf: PChar; BufLen: Integer; AbonType: Byte): Boolean;
var
  I, J, K: Integer;
begin
  if (AbonType and atTrace)>0 then
    AddProtoMes(plInfo, ServerSocketMes, 'Отп ком '
      +IntToStr(Comnd.cmCommand)+'\'+IntToStr(Comnd.cmParam)+' BL='+IntToStr(BufLen)
      +' для Ab='+IntToStr(LongWord(Socket)));
  CodeExchangeCommand(Comnd);
  Result := Socket.SendBuf(Comnd, SizeOf(TExchangeCommand))
    =SizeOf(TExchangeCommand);
  if (Buf<>nil) and (BufLen>0) and Result then
  begin
    if ((AbonType and atSmallPack)=0) or (SmallBufSize<=0) then
      Result := Socket.SendBuf(Buf^, BufLen)=BufLen
    else begin
      I := 0;
      J := 1;
      while (I<BufLen) or (J=0) do
      begin
        J := SmallBufSize;
        if J>BufLen-I then
          J := BufLen-I;
        if (AbonType and atTrace)>0 then
          AddProtoMes(plInfo, ServerSocketMes, 'Отп фрагм '
            +IntToStr(Comnd.cmCommand)+'\'+IntToStr(Comnd.cmParam)+' FL='
            +IntToStr(J)+' для Ab='+IntToStr(LongWord(Socket)));
        J := Socket.SendBuf(Buf[I], J);
        I := I+J;
        if J>0 then
        begin
          Sleep(5);
          K := 0;
          while K<(SleepAfterSmall div 5) do
          begin
            Application.ProcessMessages;
            Sleep(5);
            Inc(K);
          end;
        end;
      end;
      Result := I=BufLen
    end;
  end;
end;

const
  MaxComLen: Integer = 255;
  MaxClientFrase: Integer = 128; //максимальная предлагаемая клиентом фраза

function SendMesToClient(Socket: TCustomWinSocket; const Mes: string;
  AbonType: Byte): Boolean;
var
  Cmnd: TExchangeCommand;
  L: Integer;
  Buf: PChar;
begin
  Result := False;
  L := Length(Mes);
  if L>0 then
  begin
    SetExchangeCommand(eccMes, L, Cmnd);
    Buf := AllocMem(L+1);
    try
      StrPLCopy(Buf, Mes, L);
      CodeBuf(134, Buf, L);
      Result := SendComAndBuf(Socket, Cmnd, Buf, L, AbonType);
    finally
      FreeMem(Buf);
    end;
  end;
end;

(*procedure TMailForm.ClientSocketRead(Sender: TObject;
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
        while (I<>0) and (Step<>csError) and Process do
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
                        //ShowMes('Авторизация клиента...');
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
                              {or smShowInfo}, nil);    
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
                                    SendBufLen+ReceiveDataLen, {smShowInfo}0,    
                                    @PackControlData)=ceiDomenK then    
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
          Application.ProcessMessages;
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
end;*)

procedure TConnectForm.ServerSocketClientRead(Sender: TObject;
  Socket: TCustomWinSocket);
var
  I, J, K: Integer;
  SocketInfoPtr: PSocketInfo;
  Buf: PChar;
  RcvCmd, SndCmd: TExchangeCommand;
  ControlData: TControlData;
  S: string;
begin
  I := SocketInfoList.IndexOfSocket(Socket);
  if I>=0 then
  begin
    SocketInfoPtr := SocketInfoList.Items[I];
    SocketInfoPtr^.siIdleTime := 0;
    with SocketInfoPtr^ do
    begin
      I := Socket.ReceiveLength;
      if (siReceiveBufLen+I<=MaxPostBufSize) and (siStep<>csError) then
      begin
        try
          ReallocMem(siReceiveBuf, siReceiveBufLen+I);
        except
          siStep := csError;
          AddProtoMes(plError, ServerSocketMes, 'Ошибка увеличения буфера чтения Ab='
            +IntToStr(LongWord(Socket)));
        end;
        if siStep<>csError then
        begin
          try
            I := Socket.ReceiveBuf(siReceiveBuf[siReceiveBufLen], I);
            Inc(siReceiveBufLen, I);
            //Inc(lcRecvByte, I);
            //BufProgressBar.Position := ReceiveBufLen;
            //BufSizeLabel.Caption := IntToStr(BufProgressBar.Position);
            //RecvBytesCountLabel.Caption := IntToStr(lcRecvByte);
            //Application.ProcessMessages;
          except
            siStep := csError;
            AddProtoMes(plError, ServerSocketMes, 'Исключение при чтении данных Ab='
              +IntToStr(LongWord(Socket)));
          end;
        end;
        if (siReceiveBufLen>0) and (siStep<>csError) and not siProcessing then
        begin
          siProcessing := True;
          try
            if (siType and atTrace)>0 then
              AddProtoMes(plInfo, ServerSocketMes, 'GetBuf Len='
                +IntToStr(siReceiveBufLen)+' Ab='+IntToStr(LongWord(Socket)));
    (*if (I>0) and (SocketInfoPtr^.siStep<>csError) then
    begin
      with SocketInfoPtr^ do
      begin
        J := 0;
        try
          if siReceiveBuf=nil then
            siReceiveBufLen := 0;
          ReallocMem(siReceiveBuf, siReceiveBufLen + I);
        except
          J := 1;
          AddProtoMes(plError, ServerSocketMes,
            'Исключение при расширении буфера приема Ab='+IntToStr(LongWord(Socket)));
        end;
        if J=0 then
        begin
          try
            J := Socket.ReceiveBuf(siReceiveBuf[siReceiveBufLen], I);
            //AddProtoMes(plInfo, ServerSocketMes, 'J='+IntToStr(J));
            I := J;
          except
            J := 0;
            AddProtoMes(plError, ServerSocketMes,
              'Исключение при чтении данных из сокета Ab='+IntToStr(LongWord(Socket)));
          end;
          if J>0 then
          begin
            try
              siReceiveBufLen := siReceiveBufLen + I;*)

            I := -1;
            while (I<>0) and (siStep<>csError) do
            begin
              if (siType and atTrace)>0 then
                AddProtoMes(plInfo, ServerSocketMes, 'Обр пор I='
                  +IntToStr(I)+' от Ab='+IntToStr(LongWord(Socket))+' шаг='
                  +IntToStr(Ord(siStep)));
              if siStep=csEnter then
              begin
                I := SymPos(#13, siReceiveBuf, siReceiveBufLen);
                if I>=0 then
                begin
                  S := StrLPas(siReceiveBuf, I);
                  J := AnalizeHelloStr(S, SocketInfoPtr);
                  if J>0 then
                  begin
                    AddProtoMes(plInfo, ServerSocketMes,
                      'Hello Ab='+IntToStr(LongWord(Socket))+' ['+S+']');
                    //SendMesToClient(Socket, 'Тестовое сообщение');
                    siSendBuf := AllocMem(AuthKeyLength);
                    J := 0;
                    try
                      if GenRandom(siSendBuf, AuthKeyLength) then
                      begin
                        SetExchangeCommand(eccSendData, AuthKeyLength, SndCmd);
                        if SendComAndBuf(Socket, SndCmd, siSendBuf,
                          AuthKeyLength, siType) then
                        begin
                          J := 1;
                          siStep := csAuth1;
                          siReceiveDataLen := 0;
                        end
                        else
                          AddProtoMes(plWarning,
                            ServerSocketMes, 'Не удалось послать пароль для Ab='
                              +IntToStr(LongWord(Socket)));
                      end
                      else
                        AddProtoMes(plError, ServerSocketMes, 'Не удалось создать случайную фразу для Ab='
                          +IntToStr(LongWord(Socket)));
                    finally
                      if J=0 then
                      begin
                        siStep := csError;
                        FreeMem(siSendBuf);
                        siSendBuf := nil;
                      end;
                    end;
                  end
                  else begin
                    siStep := csError;
                    AddProtoMes(plWarning, ServerSocketMes,
                      'Формат приветствия с адреса Ab='
                        +IntToStr(LongWord(Socket))+' ошибочен Err='+IntToStr(J)+' ['
                      +S+']');
                  end;
                  Inc(I);
                end
                else
                  I := 0;
              end
              else begin
                if siReceiveDataLen=0 then
                begin
                  if siReceiveBufLen<SizeOf(RcvCmd) then
                    I := 0
                  else
                    I := SizeOf(RcvCmd);
                end
                else begin
                  if siReceiveBufLen<siReceiveDataLen then
                    I := 0
                  else
                    I := siReceiveDataLen;
                end;
                if (I>0) and (siStep<>csError) then
                begin
                  if siReceiveDataLen=0 then
                  begin
                    Move(siReceiveBuf^, RcvCmd, SizeOf(RcvCmd));
                    DecodeExchangeCommand(RcvCmd);
                    if (siType and atTrace)>0 then
                      AddProtoMes(plInfo, ServerSocketMes,
                        'Команда '+IntToStr(RcvCmd.cmCommand)
                        +'\'+IntToStr(RcvCmd.cmParam)+' от Ab='
                        +IntToStr(LongWord(Socket)));
                    if not CheckExchangeCommand(RcvCmd) then
                    begin
                      siStep := csError;
                      AddProtoMes(plWarning, ServerSocketMes,
                        'CRC команды ('+IntToStr(RcvCmd.cmCommand)
                        +'/'+IntToStr(RcvCmd.cmParam)+'|'+IntToStr(RcvCmd.cmControl)
                        +') неправильно Ab='+IntToStr(LongWord(Socket)));
                    end;
                  end
                  else begin
                    if (siType and atTrace)>0 then
                      AddProtoMes(plInfo, ServerSocketMes,
                        'Данные '+IntToStr(I)+' от Ab='
                        +IntToStr(LongWord(Socket)));
                    FillChar(RcvCmd, SizeOf(RcvCmd), #0);
                  end;
                  if siStep<>csError then
                  begin
                    case siStep of
                      csAuth1, csAuth2:  {авторизация}
                        begin
                          if siReceiveDataLen=0 then
                          begin
                            if RcvCmd.cmCommand=eccSendData then
                            begin
                              siReceiveDataLen := RcvCmd.cmParam;
                              if (siReceiveDataLen<=0)
                                or (siReceiveDataLen>MaxPostBufSize) then
                              begin
                                siStep := csError;
                                AddProtoMes(plWarning, ServerSocketMes,
                                  'Указана ошибочная длина предложения с Ab='
                                    +IntToStr(LongWord(Socket))+' L= '
                                    +IntToStr(siReceiveDataLen));
                                siReceiveDataLen := 0;
                              end
                              {else
                                AddProtoMes(plInfo, ServerSocketMes,
                                  '!!Принята подпись '+IntToStr(siReceiveDataLen))};
                            end
                            else begin
                              siStep := csError;
                              AddProtoMes(plWarning, ServerSocketMes,
                                'Команда предложения с Ab='+IntToStr(LongWord(Socket))
                                +' неправильна ('+IntToStr(RcvCmd.cmCommand)+')');
                            end;
                          end
                          else begin
                            if siStep=csAuth1 then
                            begin
                              {AddProtoMes(plInfo, ServerSocketMes,
                                'Прием подписи с '+Socket.RemoteAddress
                                +' SB='+IntToStr(Integer(siSendBuf))
                                +' RDL='+IntToStr(siReceiveDataLen));}
                              if siSendBuf<>nil then
                              begin
                                try
                                  try
                                    Buf := AllocMem(AuthKeyLength+siReceiveDataLen);
                                    try
                                      Move(siSendBuf^, Buf^, AuthKeyLength);
                                      Move(siReceiveBuf^, Buf[AuthKeyLength],
                                        siReceiveDataLen);
                                      with ControlData do
                                      begin
                                        cdCheckSelf := False;
                                        StrLCopy(cdTagLogin, siLogin,
                                          SizeOf(cdTagLogin)-1);
                                      end;
                                       // showmessage(inttostr(AuthKeyLength)
                                       //  +'/'+inttostr(AuthKeyLength+siReceiveDataLen));
                                      if CheckSign(Buf, AuthKeyLength,
                                        AuthKeyLength+siReceiveDataLen,
                                        smCheckLogin or smThoroughly{or smShowInfo},
                                        @ControlData, nil, '')=ceiDomenK then
                                      begin
                                        J := RegistrateAbon(SocketInfoPtr, False);
                                        if J=0 then
                                        begin
                                          {AddProtoMes(plInfo, ServerSocketMes,
                                            'Абонент проверен '+Socket.RemoteAddress);}
                                          setExchangeCommand(eccOk, 0, SndCmd);
                                          if SendComAndBuf(Socket, SndCmd, nil,
                                            0, siType) then
                                          begin
                                            siStep := csAuth2;
                                            {AddProtoMes(plInfo, ServerSocketMes,
                                              'Подтверждение подписи отправлено '
                                              +Socket.RemoteAddress);}
                                          end
                                          else begin
                                            siStep := csError;
                                            AddProtoMes(plWarning, ServerSocketMes,
                                              'Не удалось подтвердить подпись Ab='
                                              +IntToStr(LongWord(Socket)));
                                          end;
                                        end
                                        else begin
                                          if J>0 then
                                          begin
                                            SetExchangeCommand(eccError, J, SndCmd);
                                            if SendComAndBuf(Socket, SndCmd, nil,
                                              0, siType) then
                                            begin
                                              siStep := csError;
                                              AddProtoMes(plError, ServerSocketMes,
                                                'Ошибка приветствия Ab='
                                                +IntToStr(LongWord(Socket))+' Err='
                                                +IntToStr(J));
                                            end
                                            else begin
                                              siStep := csError;
                                              AddProtoMes(plWarning, ServerSocketMes,
                                                'Не удалось отправить ошибку приветствия на Ab='
                                                  +IntToStr(LongWord(Socket)));
                                            end;
                                          end;
                                        end;
                                      end
                                      else begin
                                        siStep := csError;
                                        AddProtoMes(plError, ServerSocketMes,
                                          'Подпись вернулась не верная Ab='
                                          +IntToStr(LongWord(Socket)));
                                      end;
                                    finally
                                      FreeMem(Buf);
                                    end;
                                  finally
                                    FreeMem(siSendBuf);
                                    siSendBuf := nil;
                                  end;
                                except
                                  siStep := csError;
                                  AddProtoMes(plError, ServerSocketMes,
                                    'Исключение при анализе подписи с Ab='
                                    +IntToStr(LongWord(Socket)));
                                end;
                              end
                              else begin
                                siStep := csError;
                                AddProtoMes(plError, ServerSocketMes,
                                  'Не найдена фраза для Ab='
                                  +IntToStr(LongWord(Socket)));
                              end;
                            end
                            else begin {Auth2}
                              Buf := AllocMem(siReceiveDataLen+MaxSignSize);
                              try
                                Move(siReceiveBuf^, Buf^, siReceiveDataLen);
                                J := AddSign(ceiDomenK, Buf, siReceiveDataLen,
                                  siReceiveDataLen+MaxSignSize, smOverwrite
                                  {or smShowInfo}, nil, '');
                                if J>0 then
                                begin
                                  SetExchangeCommand(eccSendData, J, SndCmd);
                                  if SendComAndBuf(Socket, SndCmd,
                                    @Buf[siReceiveDataLen], J, siType) then
                                  begin
                                    siStep := csAuth3;
                                    {AddProtoMes(plInfo, ServerSocketMes,
                                      'Подпись отправлена на адрес '+Socket.RemoteAddress);}
                                    if siSendBuf<>nil then
                                    begin
                                      FreeMem(siSendBuf);
                                      siSendBuf := nil;
                                    end;
                                  end
                                  else begin
                                    siStep := csError;
                                    AddProtoMes(plWarning, ServerSocketMes,
                                      'Не удалось отправить подпись для Ab='
                                      +IntToStr(LongWord(Socket)));
                                  end;
                                end
                                else begin
                                  siStep := csError;
                                  AddProtoMes(plError, ServerSocketMes,
                                    'Не удалось создать подпись для Ab='
                                    +IntToStr(LongWord(Socket)));
                                end;
                              finally
                                FreeMem(Buf);
                              end;
                            end;
                            siReceiveDataLen := 0;
                          end;
                        end;
                      csAuth3:
                        begin
                          if siReceiveDataLen=0 then
                          begin
                            case RcvCmd.cmCommand of
                              eccOk:
                                begin
                                  {AddProtoMes(plInfo, ServerSocketMes,
                                    'Подпись сервера подтверждена от '+Socket.RemoteAddress);
                                  {Запись идентификатора lastID !!!}
                                  if siSendBuf<>nil then
                                  begin
                                    FreeMem(siSendBuf);
                                    siSendBuf := nil;
                                  end;
                                  J := RegistrateAbon(SocketInfoPtr, True);
                                  if J=0 then
                                  begin
                                    siStep := csData;
                                    {AddProtoMes(plInfo, ServerSocketMes,
                                      'Абонент ['+siLogin+'] зарегистрирован '
                                      +Socket.RemoteAddress);}
                                  end
                                  else begin
                                    siStep := csError;
                                    AddProtoMes(plWarning, ServerSocketMes,
                                      'Не удалось зарегистрировать абонента Ab='
                                      +IntToStr(LongWord(Socket)));
                                  end;
                                end;
                              eccError:
                                begin
                                  siStep := csError;
                                  AddProtoMes(plWarning, ServerSocketMes,
                                    'Подпись сервера отвергнута Err='
                                    +IntToStr(RcvCmd.cmParam)
                                    +' Ab='+IntToStr(LongWord(Socket)));
                                end;
                              else begin
                                siStep := csError;
                                AddProtoMes(plWarning, ServerSocketMes,
                                  'Команда ответа на подпись хоста ошибочна '
                                  +IntToStr(RcvCmd.cmCommand)+'/'+IntToStr(RcvCmd.cmParam)
                                  +' Ab='+IntToStr(LongWord(Socket)));
                              end;
                            end;
                          end
                          else begin
                            siStep := csError;
                            AddProtoMes(plWarning, ServerSocketMes,
                              'Непонятные данные по завершении авторизации Ab='
                              +IntToStr(LongWord(Socket)));
                          end;
                        end;
                      csData: {обмен данными}
                        begin
                          if siReceiveDataLen=0 then
                          begin
                            if siSendBuf=nil then  {начало команды}
                            begin
                              case RcvCmd.cmCommand of
                                eccSendData: {Хочет послать пакет}
                                  begin
                                    siReceiveDataLen := RcvCmd.cmParam;
                                    if (siReceiveDataLen<=0)
                                      or (siReceiveDataLen>MaxPostBufSize) then
                                    begin
                                      siStep := csError;
                                      AddProtoMes(plWarning, ServerSocketMes,
                                        'Указана ошибочная длина пакета Ab='
                                        +IntToStr(LongWord(Socket))+' L= '
                                        +IntToStr(siReceiveDataLen));
                                      siReceiveDataLen := 0;
                                    end
                                    else begin
                                      {AddProtoMes(plInfo, ServerSocketMes,
                                        'Прием пакета '+IntToStr(siReceiveDataLen)+' от '+Socket.RemoteAddress);}
                                      siSendBuf := AllocMem(SizeOf(TSendData));
                                      with PSendData(siSendBuf)^ do
                                      begin
                                        sdCommand := RcvCmd.cmCommand;
                                        sdParam := RcvCmd.cmParam; //не имеет значения
                                      end;
                                    end;
                                  end;
                                eccRcvData:   {Запрос пакета}
                                  begin
                                    Buf := nil;
                                    try
                                      J := GetFirstRcvPacket(Socket, siLogin, K, Buf);
                                      if J>0 then
                                      begin {нашел пакет}
                                        SetExchangeCommand(eccSendData,
                                          J, SndCmd);
                                        {AddProtoMes(plWarning, ServerSocketMes,
                                          '=='+IntToStr(SndCmd.cmCommand)
                                          +'/'+IntToStr(SndCmd.cmParam)
                                          +'  j '+IntToStr(J));}
                                        if SendComAndBuf(Socket, SndCmd,
                                          Buf, J{SndCmd.cmParam}, siType) then
                                        begin
                                          siSendBuf := AllocMem(SizeOf(TSendData));
                                          with PSendData(siSendBuf)^ do
                                          begin
                                            sdCommand := RcvCmd.cmCommand;
                                            sdParam := K;
                                          end;
                                        end
                                        else begin
                                          siStep := csError;
                                          AddProtoMes(plWarning, ServerSocketMes,
                                            'Не удалось отправить пакет на Ab='
                                            +IntToStr(LongWord(Socket)));
                                        end;
                                      end
                                      else begin  {нету пакетов}
                                        SetExchangeCommand(eccError, -J, SndCmd);
                                        if not SendComAndBuf(Socket, SndCmd, nil,
                                          0, siType) then
                                        begin
                                          siStep := csError;
                                          AddProtoMes(plWarning, ServerSocketMes,
                                            'Не удалось отправить отрицание пакетов на Ab='
                                            +IntToStr(LongWord(Socket)));
                                        end;
                                      end;
                                    finally
                                      if Buf<>nil then
                                        FreeMem(Buf);
                                    end;
                                  end;
                                eccRcvKvit:  {Запрос квитанции}
                                  begin
                                    Buf := nil;
                                    try
                                      J := GetFirstKvit(siLogin, Buf);
                                      if J>0 then
                                      begin
                                        SetExchangeCommand(eccSendData, J, SndCmd);
                                        if SendComAndBuf(Socket, SndCmd, Buf,
                                          J, siType) then
                                        begin
                                          siSendBuf := AllocMem(SizeOf(TSendData));
                                          with PSendData(siSendBuf)^ do
                                          begin
                                            sdCommand := RcvCmd.cmCommand;
                                            sdParam := PLongWord(Buf)^;
                                          end;
                                        end
                                        else begin
                                          siStep := csError;
                                          AddProtoMes(plWarning, ServerSocketMes,
                                            'Не удалось отправить пакет на Ab='
                                            +IntToStr(LongWord(Socket)));
                                        end;
                                      end
                                      else begin  {нету квитанций}
                                        SetExchangeCommand(eccError, -J, SndCmd);
                                        if not SendComAndBuf(Socket, SndCmd, nil,
                                          0, siType) then
                                        begin
                                          siStep := csError;
                                          AddProtoMes(plWarning, ServerSocketMes,
                                            'Не удалось отправить отрицание квитанций на Ab='
                                            +IntToStr(LongWord(Socket)));
                                        end;
                                      end;
                                    finally
                                      if Buf<>nil then
                                        FreeMem(Buf);
                                    end;
                                  end;
                                eccMes:
                                  begin
                                    AddProtoMes(plWarning, ServerSocketMes,
                                      'Сообщение от Ab='+IntToStr(LongWord(Socket)));
                                  end;
                                else begin
                                  siStep := csError;
                                  AddProtoMes(plError, ServerSocketMes,
                                    'Неизвестное предложение с адреса Ab='
                                    +IntToStr(LongWord(Socket))+' на ('
                                    +IntToStr(RcvCmd.cmCommand)+'/'
                                    +IntToStr(RcvCmd.cmParam)+')');
                                end;
                              end;
                            end
                            else begin  {завершение команды}
                              {AddProtoMes(plWarning, ServerSocketMes,
                                'ddd '+IntToStr(RcvCmd.cmCommand)+'/'
                                +IntToStr(RcvCmd.cmParam)+' f='
                                +IntToStr(PSendData(siSendBuf)^.sdCommand)
                                +'/'+IntToStr(PSendData(siSendBuf)^.sdParam));}
                              case RcvCmd.cmCommand of
                                eccOk:
                                  begin
                                    case PSendData(siSendBuf)^.sdCommand of
                                      eccRcvData:
                                        begin
                                          J := SetRcvPack(Socket,
                                            PSendData(siSendBuf)^.sdParam);
                                          if J<>0 then
                                          begin
                                            AddProtoMes(plError, ServerSocketMes,
                                              'Ошибка усечения пакета Id='
                                              +IntToStr(PSendData(siSendBuf)^.sdParam)
                                              +' Err='+IntToStr(J));
                                          end;
                                        end;
                                      eccRcvKvit:
                                        begin
                                          J := RemovePacket(Socket, PSendData(
                                            siSendBuf)^.sdParam);
                                          if J<>0 then
                                          begin
                                            AddProtoMes(plError, ServerSocketMes,
                                              'Ошибка удаления пакета Id='
                                              +IntToStr(PSendData(siSendBuf)^.sdParam)
                                              +' Err='+IntToStr(J));
                                          end;
                                        end;
                                      else begin
                                        siStep := csError;
                                        AddProtoMes(plWarning, ServerSocketMes,
                                          'Ненужный ответ (0) от Ab='
                                          +IntToStr(LongWord(Socket))+' на ('
                                          +IntToStr(PSendData(siSendBuf)^.sdCommand)+')');
                                      end;
                                    end;
                                  end;
                                eccError:
                                  begin
                                    siStep := csError;
                                    AddProtoMes(plWarning, ServerSocketMes,
                                      'Ответ о неудаче ErrCode='+IntToStr(RcvCmd.cmParam)
                                      +' от Ab='+IntToStr(LongWord(Socket))+' на ('
                                      +IntToStr(PSendData(siSendBuf)^.sdCommand)+')');
                                  end;
                                else begin
                                  siStep := csError;
                                  AddProtoMes(plWarning, ServerSocketMes,
                                    'Неадекватный ответ ('+IntToStr(RcvCmd.cmCommand)
                                    +') от Ab='+IntToStr(LongWord(Socket))+' на ('
                                    +IntToStr(PSendData(siSendBuf)^.sdCommand)+')');
                                end;
                              end;
                              FreeMem(siSendBuf);
                              siSendBuf := nil;
                            end;
                          end
                          else begin  {данные команды}
                            if siSendBuf<>nil then  {инфо о начальной команде}
                            begin
                              case PSendData(siSendBuf)^.sdCommand of
                                eccSendData:
                                  begin
                                    J := InsertPack(Socket, siReceiveBuf,
                                      siReceiveDataLen, siType);
                                    if J>0 then
                                    begin
                                      SetExchangeCommand(eccOk, J, SndCmd);
                                      if SendComAndBuf(Socket, SndCmd, nil,
                                        0, siType) then
                                      begin
                                        {AddProtoMes(plInfo,
                                          ServerSocketMes, 'Подтверждение пакета отправлено');}
                                      end
                                      else begin
                                        siStep := csError;
                                        AddProtoMes(plWarning, ServerSocketMes,
                                          'Не удалось отправить подтверждение пакета для Ab='
                                          +IntToStr(LongWord(Socket)));
                                      end;
                                    end
                                    else begin
                                      siStep := csError;
                                      AddProtoMes(plError, ServerSocketMes,
                                        'Не удалось вставить пакет для Ab='
                                        +IntToStr(LongWord(Socket)));
                                      SetExchangeCommand(eccError, -J, SndCmd);
                                      if SendComAndBuf(Socket, SndCmd, nil, 0,
                                        siType) then
                                      begin
                                        {AddProtoMes(plInfo,
                                          ServerSocketMes, 'Ошибка отослана');}
                                      end
                                      else begin
                                        siStep := csError;
                                        AddProtoMes(plWarning, ServerSocketMes,
                                          'Не удалось отправить ошибку на Ab='
                                          +IntToStr(LongWord(Socket)));
                                      end;
                                    end;
                                  end;
                                else begin
                                  siStep := csError;
                                  AddProtoMes(plWarning, ServerSocketMes,
                                    'Данные от неясной команды '
                                    +IntToStr(PSendData(siSendBuf)^.sdCommand)
                                    +' с Ab='+IntToStr(LongWord(Socket)));
                                end;
                              end;
                              FreeMem(siSendBuf);
                              siSendBuf := nil;
                            end
                            else begin
                              siStep := csError;
                              AddProtoMes(plError, ServerSocketMes,
                                'Нет информации о начальной команде Ab='
                                +IntToStr(LongWord(Socket)));
                            end;
                            siReceiveDataLen := 0;
                          end;
                        end;
                      else
                        begin
                          siStep := csError;
                          AddProtoMes(plError, ServerSocketMes,
                            'Неясный шаг Ab='+IntToStr(LongWord(Socket)));
                        end;
                    end;
                  end;
                end
                else
                  I := 0;
              end;
              if I>0 then
              begin
                try
                  siReceiveBufLen := siReceiveBufLen-I;
                  if siReceiveBufLen>0 then
                  begin
                    Buf := AllocMem(siReceiveBufLen);
                    Move(siReceiveBuf[I], Buf^, siReceiveBufLen);
                    FreeMem(siReceiveBuf);
                    siReceiveBuf := Buf;
                    I := -1;
                  end
                  else begin
                    siReceiveBufLen := 0;
                    FreeMem(siReceiveBuf);
                    siReceiveBuf := nil;
                    I := 0;
                  end;
                except
                  siStep := csError;
                  AddProtoMes(plError, ServerSocketMes,
                    'Ошибка перераспределения памяти для Ab='
                    +IntToStr(LongWord(Socket)));
                end;
              end;
            end;
          except
            siStep := csError;
            AddProtoMes(plError, ServerSocketMes,
              'Исключение при обработке полученных данных от Ab='
              +IntToStr(LongWord(Socket)));
          end;
          siProcessing := False;
        end;
      end
      else begin
        if siStep<>csError then
        begin
          siStep := csError;
          AddProtoMes(plError, ServerSocketMes, 'Размер буфера чтения превышен '
            +IntToStr(MaxPostBufSize)+' Ab='+IntToStr(LongWord(Socket)));
        end;
      end;
    end;
  end
  else begin
    AddProtoMes(plError, ServerSocketMes,
      'Не найдено состояние сокета Ab='+IntToStr(LongWord(Socket))
      +' ['+Socket.RemoteAddress+']');
    Socket.Close;
  end;
end;

procedure TConnectForm.BreakActionExecute(Sender: TObject);
const
  MesTitle: PChar = 'Отсоединение клиента';
var
  I: Integer;
  Socket: TCustomWinSocket;
begin
  I := ConnectListBox.ItemIndex;
  if (I>=0) and (I<ConnectListBox.Items.Count) then
  begin
    Socket := TCustomWinSocket(ConnectListBox.Items.Objects[I]);
    if (Socket<>nil) and (MessageBox(Handle,
      PChar('Отсоединить клиента '+Socket.RemoteAddress+'?'), MesTitle,
      MB_YESNOCANCEL or MB_ICONWARNING)=ID_YES) then
    begin
      Socket.Close;
      PostMessage(Handle, WM_UPDATECOUNTER, UC_REFRESH, 0);
      Application.ProcessMessages;
      PropPanelClick(nil);
    end;
  end
  else
    BreakAction.Enabled := False;
end;

function ConStateToStr(CS: TConnectionStep): string;
begin
  case CS of
    csEnter:
      Result := 'Вход';
    csAuth1:
      Result := 'Авторизация клиента';
    csAuth2:
      Result := 'Авторизация сервера';
    csAuth3:
      Result := 'Завершение авторизации';
    csData:
      Result := 'Обмен';
    csError:
      Result := 'Ошибка';
    else
      Result := 'Неизвестно';
  end;
end;

procedure TConnectForm.AccesPanelMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbLeft then (Sender as TPanel).BevelOuter := bvLowered;
end;

procedure TConnectForm.AccesPanelMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  with (Sender as TPanel) do
    if BevelOuter = bvLowered then BevelOuter := bvRaised;
end;

procedure TConnectForm.TimerTimer(Sender: TObject);
var
  SocketInfoPtr: PSocketInfo;
  I: Integer;
  TimeOut: DWord;
begin
  with SocketInfoList do
    for I := 0 to Count-1 do
    begin
      SocketInfoPtr := Items[I];
      SocketInfoPtr^.siIdleTime := SocketInfoPtr^.siIdleTime
        + TimerInterval;
      if I=TimerSocketIndex then
        PropPanelClick(nil);
      case SocketInfoPtr^.siStep of
        csEnter:
          Timeout := EnterTimeout;
        csError:
          Timeout := ErrorTimeout;
        else
          Timeout := AuthedTimeout;
      end;
      if (Timeout>0) and (SocketInfoPtr^.siIdleTime>=Timeout) then
      begin
        AddProtoMes(plWarning, ServerSocketMes,
          'Отключение по таймауту '+IntToStr(SocketInfoPtr^.siIdleTime)
          +' Ab='+IntToStr(Integer(SocketInfoPtr^.siSocket))
          +' ['+SocketInfoPtr^.siSocket.RemoteAddress+'] '
          +' '+SocketInfoPtr^.siSocket.RemoteHost);
        SocketInfoPtr^.siSocket.Close;
        if (TimerSocketIndex>=0) and (I=TimerSocketIndex) then
        begin
          TimerSocketIndex := -1;
          PropMemo.Text := '';
        end;
      end;
    end;
end;

procedure TConnectForm.ConnectPanelClick(Sender: TObject);
begin
  PostMessage(Handle, WM_UPDATECOUNTER, UC_REFRESH, 0);
end;

procedure TConnectForm.PropPanelClick(Sender: TObject);
var
  Socket: TCustomWinSocket;
  SocketInfoPtr: PSocketInfo;
  I: Integer;
begin
  if (Sender=PropPanel) and (TimerSocketIndex>=0) then
  begin
    TimerSocketIndex := -1;
    PropMemo.Lines.Text := '';
  end
  else begin
    if Sender<>nil then
      TimerSocketIndex := ConnectListBox.ItemIndex;
    if (TimerSocketIndex>=0) and (TimerSocketIndex<ConnectListBox.Items.Count) then
    begin
      Socket := TCustomWinSocket(ConnectListBox.Items.Objects[TimerSocketIndex]);
      if Socket<>nil then
      begin
        BreakAction.Enabled := True;
        I := SocketInfoList.IndexOfSocket(Socket);
        if I>=0 then
        begin
          if I=TimerSocketIndex then
          begin
            SocketInfoPtr := PSocketInfo(SocketInfoList.Items[I]);
            if SocketInfoPtr<>nil then
            begin
              with SocketInfoPtr^ do
                PropMemo.Lines.Text :=
                  'Адрес: '+siSocket.RemoteAddress
                  +#13#10'Хост: '+siSocket.RemoteHost
                  +#13#10'Порт: '+IntToStr(siSocket.RemotePort)
                  +#13#10'Спит: '+IntToStr(siIdleTime)
                  +#13#10'Шаг: '+ConStateToStr(siStep)
                  +#13#10'Логин: '+siLogin
                  +#13#10'LastId: '+IntToStr(siLastId)
                  +#13#10'HardId: '+IntToStr(siHardId)
                  +#13#10'SendBuf: '+IntToStr(Integer(siSendBuf))
                  +#13#10'RecvBuf: '+IntToStr(Integer(siReceiveBuf))
                  +#13#10'RecvBufLen: '+IntToStr(siReceiveBufLen)
                  +#13#10'RecvDataLen: '+IntToStr(siReceiveDataLen);
            end
            else
              PropMemo.Lines.Text := 'Нет данных по соединению';
          end
          else begin
            TimerSocketIndex := -1;
            PropMemo.Lines.Text := 'Рассогласование списков';
          end;
        end
        else
          PropMemo.Lines.Text := 'Не могу найти Socket в списке';
      end
      else begin
        TimerSocketIndex := -1;
        BreakAction.Enabled := False;
        PropMemo.Lines.Text := 'Socket=nil';
      end;
    end
    else begin
      TimerSocketIndex := -1;
      BreakAction.Enabled := False;
      PropMemo.Lines.Text := '';
    end;
  end;
end;

procedure TConnectForm.SendMesMemoKeyPress(Sender: TObject; var Key: Char);
var
  I: Integer;
  Socket: TCustomWinSocket;
begin
  if Key=#13 then
  begin
    Key := #0;
    if ConnectListBox.Items.Count>0 then
    begin
      I := ConnectListBox.ItemIndex;
      if (I>=0) and (I<ConnectListBox.Items.Count) then
      begin
        Socket := TCustomWinSocket(ConnectListBox.Items.Objects[I]);
        SendMesToClient(Socket, SendMesMemo.Text, 0);
        AddProtoMes(plInfo, ServerSocketMes,
          'Послано сообщение ['+SendMesMemo.Text+'] на Ab='
          +IntToStr(LongWord(Socket)));
        SendMesMemo.Clear;
      end;
    end;
  end;
end;

procedure TConnectForm.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  {if ServerSocket.Active then
    StopActionExecute(nil);}
  Action := caFree;
end;

procedure TConnectForm.FormDestroy(Sender: TObject);
begin
  SocketInfoList.Free;
  ConnectForm := nil;
end;

procedure TConnectForm.Vert1SplitterCanResize(Sender: TObject;
  var NewSize: Integer; var Accept: Boolean);
begin
  Accept := NewSize>=15;
end;

end.
