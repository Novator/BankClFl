unit ObmenFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, WinSock, Btrieve, {CryDrv, }Buttons, ExtCtrls, ComCtrls, WinInet,
  Registr, Common, ShellApi{, RasApi};

type
  TObmenForm = class(TForm)
    GroupBox2: TGroupBox;
    Memo1: TMemo;
    StatusBar1: TStatusBar;
    Panel1: TPanel;
    GroupBox1: TGroupBox;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Edit1: TEdit;
    Edit2: TEdit;
    Edit3: TEdit;
    Edit4: TEdit;
    Edit5: TEdit;
    CloseBtn: TBitBtn;
    ProcessBtn: TBitBtn;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
  private
    FBankAddr: string;
    FBankPort: integer;
    FMyAccount: string;
    FAuthKey: pointer;
    FMyTimeOut: longword;
    FMaxAuthTry: integer;
    FProto: string;
    FDir: string;
    Started: boolean;
    { Private declarations }
  public
    { Public declarations }
  end;

var
  ObmenForm: TObmenForm = nil;
  ObjList: TList = nil;

type
  TObmenThread = class(TThread)
    procedure ObmenThreadOnTerminate(Sender: TObject);
  private
    { Private declarations }
    FHostAddr:  string;
    FPortNum:   integer;
    FAccount:   string;
    FObmenKey:  pchar;
    FProtoName: string;
    FTimeOut:   longword;
//    FhWnd:      HWND;
    FMaxAuth:   integer;
    FDirectory: string;
    Snd, Rcv: TBtrBase;
    Sock: TSocket;
    NeedBreak: boolean;
    Success: boolean;
    AuthError: integer;
//    MyError: integer;
//    MyExtendedError: integer = 0;
//    MyAbort: integer = 0;
    LineCnt: integer;
    InCnt: integer;
    LinePos: pchar;
    InPos: pchar;
    PackBuf: pchar;
    LineBuf: array[0..80] of char;
    InBuf: array[0..2047] of char;
    SendErrorVal: string;
    MyMessageId: integer;
    MyMessageVal: integer;
    procedure WriteProto(const s: string);
    procedure MyMessage(Id: integer; Par: integer);
    procedure SendError(const s: string);
    function SendLine(s: pchar): integer;
    function RecvLine(s: pchar; n: integer): integer;
    function SendFiles: integer;
    function RecvFiles: integer;
    function RecvKvits: integer;
    function TestAuth: integer;
  protected
    procedure SendErrorProc;
    procedure MyMessageProc;
    procedure Execute; override;
  public
    property HostAddr: string read FHostAddr write FHostAddr;
    property PortNum: integer read FPortNum write FPortNum;
    property Account: string read FAccount write FAccount;
    property ObmenKey: pchar read FObmenKey write FObmenKey;
    property TimeOut: longword read FTimeOut write FTimeOut;
//    property HWnd: HWND read FhWnd write FhWnd;
    property MaxAuth: integer read FMaxAuth write FMaxAuth;
    property ProtoName: string read FProtoName write FProtoName;
    property Directory: string read FDirectory write FDirectory;
  end;

function MakeObmen(InitMessage: string; BankAddr: string;
  BankPort: integer; MyAccount: string;
  AuthKey: pointer; TimeOut: longword;
  MaxAuthTry: integer; Proto: string;
  Dir: string): Boolean;

implementation

{$R *.DFM}

var
  ObmenThread: TObmenThread;
  CntS, CntR, CntK, CntA: Integer;
  SuccessConnect: Boolean;

{ Important: Methods and properties of objects in VCL can only be used in a
  method called using Synchronize, for example,

      Synchronize(UpdateCaption);

  and UpdateCaption could look like,

    procedure TObmenThread.UpdateCaption;
    begin
      Form1.Caption := 'Updated in a thread';
    end; }

{ TObmenThread }
{
procedure GetRandomKey(Key: pointer);
begin
  FillChar(Key^,32,0);
end;

procedure EncryptKey(Key, Key1: pointer);
begin
  FillChar(Key^,32,0);
end;

procedure DecryptKey(Key, Key1: pointer);
begin
  FillChar(Key^,32,0);
end;
}
function ReadIder(p: pchar; var Res: integer): boolean;
var
  n: cardinal;
begin
  Result := false;
  if((p^<'0') Or (p^>'9')) then
    Exit;
  n := 0;
  while((p^>='0') And (p^<='9')) do
    begin
      if(n>400000000) then
        Exit;
      n := n*10+(Ord(p^)-Ord('0'));
      Inc(p);
    end;
  if(p^<>Chr(0)) then
    Exit;
  Res := n;
  Result := true;
end;

const
  uue: array [0..63] of char = (
    'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P',
    'Q','R','S','T','U','V','W','X','Y','Z','a','b','c','d','e','f',
    'g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v',
    'w','x','y','z','.','/','0','1','2','3','4','5','6','7','8','9'
  );

  uud: array [char] of byte = (
    64, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99,
    99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99,
    99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 52, 53,
    54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 99, 99, 99, 99, 99, 99,
    99,  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14,
    15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 99, 99, 99, 99, 99,
    99, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40,
    41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 99, 99, 99, 99, 99,
    99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99,
    99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99,
    99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99,
    99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99,
    99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99,
    99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99,
    99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99,
    99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99
  );

procedure EncodeLine(Src: pchar; Dst: pchar; Cnt: integer);
var
  n, c: integer;
begin
  while(Cnt>0) do
    begin
      n := 3;
      if(n>Cnt) then
        n := Cnt;
      c := Ord(Src^);
      Inc(Src);
      if(n>1) then
        begin
          c := c Or (Ord(Src^) SHL 8);
          Inc(Src);
          if(n>2) then
            begin
              c := c Or (Ord(Src^) SHL 16);
              Inc(Src);
            end;
        end;
      Dst^ := uue[c And $3F];
      Inc(Dst);
      c := c SHR 6;
      Dst^ := uue[c And $3F];
      Inc(Dst);
      if(n>1) then
        begin
          c := c SHR 6;
          Dst^ := uue[c And $3F];
          Inc(Dst);
          if(n>2) then
            begin
              c := c SHR 6;
              Dst^ := uue[c And $3F];
              Inc(Dst);
            end;
        end;
      Dec(Cnt,n);
    end;
  Dst^ := #13;
  Inc(Dst);
  Dst^ := Chr(0);
end;

function DecodeLine(Src: pchar; Dst: pchar; Cnt: integer): integer;
var
  n, c, cc, nn, n1: integer;
begin
  Result := -1;
  cc := 0;
  while(true) do
    begin
      n := 0;
      c := uud[Src^];
      Inc(Src);
      if(c<64) then
        begin
          nn := c;
          Inc(n);
          c := uud[Src^];
          Inc(Src);
          if(c<64) then
            begin
              nn := nn Or (c SHL 6);
              Inc(n);
              c := uud[Src^];
              Inc(Src);
              if(c<64) then
                begin
                  nn := nn Or (c SHL 12);
                  Inc(n);
                  c := uud[Src^];
                  Inc(Src);
                  if(c<64) then
                    begin
                      nn := nn Or (c SHL 18);
                      Inc(n);
                    end;
                end;
            end;
        end;
//      WriteProto('DecodeLine: n='+IntToStr(n)+' nn='+IntToStr(nn));
      if(n>0) then
        begin
          n1 := n-1;
          while(n1>0) do
            begin
              if(cc<cnt) then
                begin
                  Dst^ := Chr(nn And $FF);
                  Inc(Dst);
                end;
              nn := nn SHR 8;
              Inc(cc);
              Dec(n1);
            end;
        end;
      if(n<4) then
        begin
          if(c<>64) then
            break;
          if(n=1) then
            break;
          Result := cc;
          break
        end;
    end;
end;

function CheckTimeOut(const t1, t2: longword): boolean;
var
  t: longword;
begin
  Result := false;
  t := GetTickCount;
  if(t1<=t2) then
    begin
      if(Not((t<t2) And (t>=t1))) then
        Result := true;
    end
  else
    begin
      if((t>=t2) And (t<t1)) then
        Result := true;
    end;
end;

const
  mmCharCnt    = 0;
  mmSndStop    = 1;
  mmRcvStop    = 2;
  mmKvtStop    = 3;
  mmNewAttempt = 4;

procedure TObmenThread.MyMessage(Id: integer; Par: integer);
begin
  MyMessageId := Id;
  MyMessageVal := Par;
  Synchronize(MyMessageProc);
end;

procedure TObmenThread.SendError(const s: string);
begin
  WriteProto(s);
  SendErrorVal := s;
  Synchronize(SendErrorProc);
end;

procedure TObmenThread.WriteProto(const s: string);
var
  f: Text;
begin
  if(FProtoName<>'') then
    begin
      Assign(f,FProtoName);
      {$I-}
      Append(f);
      {$I+}
      if(IOResult<>0) then
        Rewrite(f);
      WriteLn(f,s);
      CloseFile(f);
    end;
end;

function TObmenThread.SendLine(s: pchar): integer;
var
  l, Res: integer;
  t1, t2: longword;
begin
  WriteProto('>'+StrPas(s));
  LinePos := s;
  LineCnt := StrLen(s);
  //  MyError := 0;
  Result := -1;
  t1 := GetTickCount;
  t2 := t1+FTimeOut;
  while(LineCnt>0) do
    begin
      if(Terminated) then
        begin
          SendError('Обмен прерван оператором');
          NeedBreak := true;
          // MyExtendedError := 1;
          Exit;
        end;
      l := send(Sock,LinePos^,LineCnt,0);
      if(l=SOCKET_ERROR) then
        begin
          Res := WsaGetLastError;
          if(Res<>WsaEWouldBlock) then
            begin
              SendError('Ошибка передачи N '+IntToStr(Res));
              Exit;
            end;
            // MyError := 0;
          if(CheckTimeOut(t1,t2)) then
            begin
              SendError('Таймаут при передаче');
              Exit;
            end;
          continue;
        end;
      Inc(LinePos,l);
      Dec(LineCnt,l);
      t1 := GetTickCount;
      t2 := t1+FTimeOut;
    end;
  Result := 0;
end;

function TObmenThread.RecvLine(s: pchar; n: integer): integer;
var
  l, nn, Res: integer;
  s1: pchar;
  t1, t2: longword;
begin
  Result := -1;
  s^ := Chr(0);
  s1 := s;
  nn := 0;
  //  MyError := 0;
  while(true) do
    begin
      t1 := GetTickCount;
      t2 := t1+FTimeOut;
      // WriteProto(Format('Recv-time: %d %d %d',[GetTickCount,FTimeOut,t]));
      while (InCnt=0) do
        begin
          if (Terminated) then
            begin
             // MyExtendedError := 1;
             SendError('Обмен прерван оператором');
             NeedBreak := true;
             Exit;
            end;
          l := recv(Sock,InBuf,SizeOf(InBuf),0);
          if (l=SOCKET_ERROR) then
            begin
              Res := WsaGetLastError;
              if(Res<>WsaEWouldBlock) then
                begin
                  SendError('Ошибка приема N '+IntToStr(Res));
                  Exit;
                end;
                // MyError := 0;
              if(CheckTimeOut(t1,t2)) then
                begin
                  //      WriteProto('Recv-timeout: '+IntToStr(GetTickCount));
                  SendError('Таймаут при приеме');
                  Exit;
                end;
              continue;
            end;
          if (l=0) then
            begin
              //              MyExtendedError := 2;
              SendError('Соединение завершено хостом');
              Exit;
            end;
          InCnt := l;
          InPos := InBuf;
          t1 := GetTickCount;
          t2 := t1+FTimeOut;
        end;
      while (InCnt>0) do
        begin
          Dec(InCnt);
          if(InPos^ = Chr(13)) then
            begin
              s^ := Chr(0);
              Result := nn;
              Inc(InPos);
              WriteProto('<'+StrPas(s1));
              Exit;
            end;
          if (Ord(InPos^)>=Ord(' ')) then
            begin
              if (nn<n) then
                begin
                  s^ := InPos^;
                  Inc(s);
                end;
              Inc(nn);
            end;
          Inc(InPos);
        end;
    end;
end;

const
  MaxPackSize = 64042;

type
  PSndPack = ^TSndPack;
  TSndPack = packed record
    spNameR:   array [0..8] of char;
    spNameS:   array [0..8] of char;
    spByteS:   byte;
    spLength:  word;
    spWordS:   word;
    spNum:     integer;
    spIder:    integer;
    spFlSnd:   char;
    spDateS:   word;
    spTimeS:   word;
    spFlRcv:   char;
    spDateR:   word;
    spTimeR:   word;
    spText:    array [0..MaxPackSize-42] of char;
  end;

  PRcvPack = ^TRcvPack;
  TRcvPack = packed record
    rpNameR:   array [0..8] of char;
    rpNameS:   array [0..8] of char;
    rpByteS:   byte;
    rpLength:  word;
    rpWordS:   word;
    rpNum:     integer;
    rpIder:    integer;
    rpDateS:   word;
    rpTimeS:   word;
    rpDateR:   word;
    rpTimeR:   word;
    rpText:    array [0..MaxPackSize-42] of char;
  end;

function TObmenThread.SendFiles: integer;
var
  p: pchar;
  l, ll: integer;
  s: string;
  Res, Len: integer;
  CntC: integer;
  c: char;
  t: array [0..56] of char;
  Key1: packed record
    kkFlSnd: char;
    kkNum:   longword;
  end;
begin
  Result := -1;
  SendError('Отправка пакетов');
  Key1.kkFlSnd := '0';
  Key1.kkNum := 0;
  Len := MaxPackSize;
  Res := Snd.GetGE(PackBuf^,Len,Key1,1);
  while(Res=0) do
    begin
      if(PSndPack(PackBuf)^.spFlSnd<>'0') then
        break;
      ll := Len;
//      WriteProto('Start send file');
      SendError('Отправка пакета N '+IntToStr(CntS+1));
      CntC := 0;
      s := '=S'#13;
      if(SendLine(pchar(s))<>0) then
        Exit;
      FillChar(PSndPack(PackBuf)^.spNameS,9,' ');
      s := UpperCase(Copy(FAccount,1,9));
      Move(pchar(s)^,PSndPack(PackBuf)^.spNameS,Length(s));
      PSndPack(PackBuf)^.spIder := 0;
      PSndPack(PackBuf)^.spDateS := 0;
      PSndPack(PackBuf)^.spTimeS := 0;
      PSndPack(PackBuf)^.spDateR := 0;
      PSndPack(PackBuf)^.spTimeR := 0;
      p := pchar(PackBuf);
      l := 59;
      if(l>ll) then
        l := ll;
      Move(p^,t,31);
      Move(p[32],t[31],4);
      Move(p[37],t[35],l-37);
      EncodeLine(t,LineBuf,l-2);
      if(SendLine(LineBuf)<>0) then
        Exit;
      Inc(p,l);
      Dec(ll,l);
      Inc(CntC,l);
      MyMessage(mmCharCnt, CntC);
      while(ll>0) do
        begin
          l := 57;
          if(l>ll) then
            l := ll;
          EncodeLine(p,LineBuf,l);
          if(SendLine(LineBuf)<>0) then
            Exit;
          Inc(p,l);
          Dec(ll,l);
          Inc(CntC,l);
          MyMessage(mmCharCnt, CntC);
        end;
      if(SendLine(#13)<>0) then
        Exit;
      l := RecvLine(LineBuf,80);
      if(l<0) then
        Exit;
      c := '3';
      if((StrLComp(LineBuf,'Ok ',3)=0) And
         (DecodeLine(@LineBuf[3],t,8)=8)) then
        begin
          c := '2';
          Move(t,PSndPack(PackBuf)^.spIder,4);
          Move(t[4],PSndPack(PackBuf)^.spDateS,4);
        end;
      PSndPack(PackBuf)^.spFlSnd := c;
      PSndPack(PackBuf)^.spFlRcv := '0';
      Res := Snd.Update(PackBuf^,Len,Key1,1);
      if(Res<>0) then
        begin
          SendError('Не могу изменить запись в "doc_s.btr". Ошибка Btrieve N '+
                    IntToStr(Res));
//          Result := -4; //Btrieve error
          NeedBreak := true;
          Exit;
        end
      else if(c='2') then
        begin
          Inc(CntS);
          MyMessage(mmSndStop, CntS);
        end;
//      WriteProto('Send file: '+c);
      Key1.kkFlSnd := '0';
      Key1.kkNum := 0;
      Len := MaxPackSize;
      Res := Snd.GetGE(PackBuf^,Len,Key1,1);
    end;
  if((Res<>9) And (Res<>0)) then
    begin
      SendError('Не могу получить запись из "doc_s.btr". Ошибка Btrieve N '+
                IntToStr(Res));
//      Result := -5; //Btrieve error
      NeedBreak := true;
      Exit;
    end;
  SendError('Отправка пакетов завершена');
  Result := 0;
end;

function TObmenThread.RecvFiles: integer;
var
  p, p1: pchar;
  l, n: integer;
  Res: integer;
  CntC: integer;
  tmp: array[0..57] of char;
  Error: boolean;
begin
  Result := -1;
  SendError('Прием пакетов');
  while(true) do
    begin
//      WriteProto('Ask recv file');
      if(SendLine('=R'#13)<>0) then
        Exit;
      l := RecvLine(LineBuf,80);
      if(l<0) then
        Exit;
      if(l=0) then
        break;
//      WriteProto('Start recv file');
      SendError('Прием пакета N '+IntToStr(CntR+1));
      CntC := 0;
      Error := false;
      p := PackBuf;
      n := 0;
      repeat
        if(l>76) then
          begin
            Error := true;
          end;
        if(Not Error) then
          begin
            l := DecodeLine(LineBuf,tmp,57);
            if(l<0) then
              begin
                Error := true;
              end;
          end;
        if(l>0) then
          begin
            Inc(CntC,l);
            MyMessage(mmCharCnt, CntC);
          end;
        if(Not Error) then
          begin
            p1 := tmp;
            while(l>0) do
              begin
                if(n<MaxPackSize) then
                  begin
                    p^ := p1^;
                    Inc(p1);
                    Inc(p);
                  end;
                Inc(n);
                Dec(l);
              end;
          end;
        l := RecvLine(LineBuf,80);
        if(l<0) then
          Exit;
      until(l=0);
      if(n>MaxPackSize) then
        begin
          Error := true;
        end;
      Res := 0;
      if(Not Error) then
        begin
          Res := Rcv.Insert(PackBuf^,n,tmp,0);
          if(Res=5) then
            begin // Дубликат
              SendError('Получен дубликат пакета. Пакет игнорируется');
              Res := 0;
            end;
        end;
      StrCopy(tmp,'Ok'#13);
      if(Error Or (Res<>0)) then
        StrCopy(tmp,'Error'#13)
      else
        begin
          Inc(CntR);
          MyMessage(mmRcvStop, CntR);
        end;
//      WriteProto('Recv file '+StrPas(tmp));
      if(SendLine(tmp)<>0) then
        Exit;
      if(Error) then
        begin
          SendError('Ошибка формата принятого пакета');
//          Result := -6; //Bad format
          NeedBreak := true;
          Exit;
        end
      else if(Res<>0) then
        begin
          SendError('Ошибка добавления в "doc_r.btr". Ошибка Btrieve N '+
                    IntToStr(Res));
//          Result := -7; //Btrieve error
          NeedBreak := true;
          Exit;
        end;
    end;
  SendError('Прием пакетов завершен');
  Result := 0;
end;

function TObmenThread.RecvKvits: integer;
var
  l: integer;
  Res, Len: integer;
  Error: boolean;
  tmp: array[0..80] of char;
  Key2: integer;
begin
  Result := -1;
  SendError('Прием квитанций');
  while(true) do
    begin
//      WriteProto('Ask recv kvit');
      if(SendLine('=K'#13)<>0) then
        Exit;
      l := RecvLine(LineBuf,80);
      if(l<0) then
        Exit;
      if(l=0) then
        break;
//      WriteProto('Start recv kvit');
      SendError('Прием квитанции N '+IntToStr(CntK+1));
      Error := false;
      Res := 0;
      if(DecodeLine(LineBuf,tmp,8)=8) then
        begin
          Len := MaxPackSize;
          Move(tmp,Key2,4);
          Res := Snd.GetEqual(PackBuf^,Len,Key2,2);
          if(Res=0) then
            begin
              PSndPack(PackBuf)^.spFlRcv := '1';
              Move(tmp[4],PSndPack(PackBuf)^.spDateR,4);
              Res := Snd.Update(PackBuf^,Len,Key2,2);
            end
          else if(Res=4) then
            begin
              SendError('Не найден пакет, соответствующий квитанции.'+
                        ' Квитанция игнорируется');
              Res := 0;
            end;
        end
      else
        Error := true;
      StrCopy(tmp,'Ok'#13);
      if(Error Or (Res<>0)) then
        StrCopy(tmp,'Error'#13)
      else
        begin
          Inc(CntK);
          MyMessage(mmKvtStop, CntK);
        end;
//      WriteProto('Recv kvit '+StrPas(tmp));
      if(SendLine(tmp)<>0) then
        Exit;
      if(Error) then
        begin
          SendError('Ошибка формата квитанции');
//          Result := -8; //Bad format
          NeedBreak := true;
          Exit;
        end
      else if(Res<>0) then
        begin
          SendError('Ошибка изменения в "doc_s.btr". Ошибка Btrieve N '+
                    IntToStr(Res));
//          Result := -9; //Btrieve error
          NeedBreak := true;
          Exit;
        end;
    end;
  SendError('Прием квитанций завершен');
  Result := 0;
end;

function TObmenThread.TestAuth: integer;
var
  l: integer;
  s: string;
  TestKey, MyKey: array[0..31] of char;
begin
  Result := -1;
//  WriteProto('Start auth');
  SendError('Аутентификация на хосте');
//  l := RecvLine(LineBuf,80);
//  if(l<0) then
//    Exit;
  s := FAccount+#13;
  if(SendLine(pchar(s))<>0) then
    Exit;
  l := RecvLine(LineBuf,80);
  if(l<0) then
    Exit;
  l := DecodeLine(LineBuf,TestKey,32);
  if(l=32) then
    begin
      DecryptKey(@TestKey,FObmenKey);
      EncryptKey(@TestKey,FObmenKey+32);
    end
  else
    FillChar(TestKey,32,0);
  EncodeLine(TestKey,LineBuf,32);
  if(SendLine(LineBuf)<>0) then
    Exit;
  l := RecvLine(LineBuf,80);
  if(l<0) then
    Exit;
  if(StrComp(LineBuf,'Ok')<>0) then
    begin
//      WriteProto('Bad auth on server');
//      Result := -2; // Wrong auth on host
//      SendError('Ошибка аутентификации на хосте');
      Exit;
    end;
  SendError('Аутентификация хоста');
  GetRandomKey(@MyKey);
  Move(MyKey,TestKey,32);
  EncryptKey(@TestKey,FObmenKey);
  EncodeLine(TestKey,LineBuf,32);
  if(SendLine(LineBuf)<>0) then
    Exit;
  l := RecvLine(LineBuf,80);
  if(l<0) then
    Exit;
  l := DecodeLine(LineBuf,TestKey,32);
  if(l<>32) then
    begin
//      WriteProto('Bad auth of server');
//      Result := -3; // Wrong host auth
//      SendError('Ошибка аутентификации хоста');
      Inc(AuthError);
      if(AuthError>=MaxAuth) then
        begin
          NeedBreak := true;
        end;
      Exit;
    end;
  DecryptKey(@TestKey,FObmenKey+32);
  if(Not CompareMem(@MyKey,@TestKey,32)) then
    begin
//      WriteProto('Bad auth of server');
//      Result := -3; // Wrong host auth
//      SendError('Ошибка аутентификации хоста');
      Inc(AuthError);
      if(AuthError>=MaxAuth) then
        begin
          NeedBreak := true;
        end;
      Exit;
    end;
  Result := 0;
end;

procedure TObmenThread.Execute;
var
  Res: integer;
  WSData: TWSAData;

  procedure ConnectAndObmen;
  var
    HostEnt: PHostEnt;
    pp: ^pointer;
    l: u_long;
    SockAddr: TSockAddr;
    lng: TLinger;
  begin
    if Terminated then
    begin
      SendError('Обмен прерван оператором');
      NeedBreak := true;
      Exit;
    end;
    Inc(CntA);
    MyMessage(mmNewAttempt, CntA);
    SendError('Попытка соединения N '+IntToStr(CntA));
    if InternetAutoDial(INTERNET_AUTODIAL_FORCE_ONLINE, 0) then
    begin
      FillChar(SockAddr,SizeOf(SockAddr), 0);
      if ((PChar(FHostAddr)^<'0') or (PChar(FHostAddr)^>'9')) then
      begin
        SendError('Получение адреса хоста');
        HostEnt := GetHostByName(pchar(FHostAddr));
        if(HostEnt=nil) then
          begin
            Res := WSAGetLastError;
            SendError('Не могу получить адрес хоста. Ошибка N '+
                      IntToStr(Res));
            Exit;
          end;
        pp := pointer(HostEnt^.h_addr);
        pp := pp^;
        Move(pp^,SockAddr.sin_addr,HostEnt^.h_length);
        SockAddr.sin_family := HostEnt^.h_addrtype;
      end
      else begin
        SockAddr.sin_addr.S_addr := inet_addr(pchar(FHostAddr));
        SockAddr.sin_family := PF_INET;
      end;
      SockAddr.sin_port := htons(FPortNum);
      if Terminated then
      begin
        SendError('Обмен прерван оператором');
        NeedBreak := true;
        Exit;
      end;
      Sock := Socket(AF_INET, SOCK_STREAM, 0);
      if Sock=INVALID_SOCKET then
      begin
        Res := WSAGetLastError;
        SendError('Не могу создать сокет. Ошибка N '+
          IntToStr(Res));
        Exit;
      end;
      try
        if Terminated then
        begin
          SendError('Обмен прерван оператором');
          NeedBreak := true;
          Exit;
        end;
        SendError('Установление соединения с хостом');
        if Connect(Sock, SockAddr, SizeOf(SockAddr))=INVALID_SOCKET then
        begin
          Res := WSAGetLastError;
          SendError('Не могу соединиться с хостом. Ошибка N '+
                    IntToStr(Res));
          Exit;
        end;
        l := 1;
        if IoctlSocket(Sock,FIONBIO,l)=SOCKET_ERROR then
        begin
          Res := WSAGetLastError;
          SendError('Не могу установить режим без ожидания. Ошибка N '+
            IntToStr(Res));
          Exit;
        end;
        FillChar(lng, SizeOf(lng), 0);
        if SetSockOpt(Sock, SOL_SOCKET, SO_LINGER, pchar(@lng),
          SizeOf(lng))=SOCKET_ERROR then
        begin
          Res := WSAGetLastError;
          SendError('Не могу установить режим завершения. Ошибка N'+
            IntToStr(Res));
          Exit;
        end;
        if (Terminated) then
        begin
          SendError('Обмен прерван оператором');
          NeedBreak := true;
          Exit;
        end;
        Res := TestAuth;
        if Res<0 then
        begin
          SendError('Ошибка аутентификации');
          Exit;
        end
        else
          SendError('Аутентификация успешно завершена');
        SuccessConnect := True;
        Res := SendFiles;
        if Res<0 then
          Exit;
        Res := RecvFiles;
        if Res<0 then
          Exit;
        Res := RecvKvits;
        if Res<0 then
          Exit;
        Success := true;
        NeedBreak := true;
      finally
        if CloseSocket(Sock)=SOCKET_ERROR then
        begin
          Res := WsaGetLastError;
          SendError('Ошибка закрытия сокета N '+IntToStr(Res));
        end;
      end;
    end;
  end;

const
  MesTitle: PChar = 'Сеанс связи';

var
  HangUpMode: Integer;
  ras: packed array[0..20] of RASCONN;
  dSize, dNumber, dwRet: DWord;
  PRasConn: HRASCONN;
  I: Integer;
begin
  { Place thread code here }
  try
    Snd := TBtrBase.Create;
    Res := Snd.Open(Directory+'doc_s.btr',baNormal);
    if Res<>0 then
    begin
      SendError('Не могу открыть "doc_s.btr". Ошибка Btrieve N '+
        IntToStr(Res));
      Exit;
    end;
    Rcv := TBtrBase.Create;
    Res := Rcv.Open(Directory+'doc_r.btr',baNormal);
    if Res<>0 then
    begin
      SendError('Не могу открыть "doc_r.btr". Ошибка Btrieve N '+
        IntToStr(Res));
      Exit;
    end;
    PackBuf := AllocMem(MaxPackSize);
    Res := WSAStartUp($0101,WSData);
    if Res<>0 then
    begin
      SendError('Ошибка инициализации сокета N '+IntToStr(Res));
      Exit;
    end;
    try
      {repeat}
      ConnectAndObmen;
      {until(NeedBreak);}
    finally
      WSACleanUp;
    end;
  finally
    if PackBuf<>nil then
    begin
      FreeMem(PackBuf);
      PackBuf := nil;
    end;
    if Snd<>nil then
      begin
        Snd.Close;
        Snd.Free;
        Snd := nil;
      end;
    if(Rcv<>nil) then
      begin
        Rcv.Close;
        Rcv.Free;
        Rcv := nil;
      end;
  end;

  if not GetRegParamByName('HangUpMode', CommonUserNumber, HangUpMode) then
    HangUpMode := 1;

  if Success then
    SendError('Обмен успешно завершен.')
  else begin
    SendError('Обмен не был завершен.');
    SendError('После устранения причины ошибки повторите обмен');
    {if HangUpMode=1 then
      HangUpMode := 2;}
  end;

  if HangUpMode>=2 then
  begin
    ras[0].dwSize := sizeof(RASCONN);
    dSize := sizeof(ras);
    dwRet := RasEnumConnections(@ras, dSize, dNumber);
    if (dwRet<>0) or (dNumber<=0)
      or (HangUpMode<>2) and (MessageBox(Application.Handle,
      'Разорвать соединение?',  MesTitle, MB_YESNOCANCEL+MB_ICONQUESTION)<>ID_YES)
    then
      HangUpMode := 0;
  end;
  case HangUpMode of
    1,3:
      InternetAutoDialHangUp(0);
    2,4:
      for I := 0 to dNumber-1 do
      begin
        PRasConn := ras[I].hrasconn;
        dwRet := RasHangUp(PRasConn);
        if dwRet<>0 then
          MessageBox(Application.Handle,
            PChar('Не удалось разорвать соединение ['
            +ras[I].szEntryName+']'), MesTitle, MB_OK+MB_ICONWARNING)
      end;
  end;
end;

procedure TObmenThread.SendErrorProc;
begin
  with ObmenForm.Memo1.Lines do
    begin
      if(Count>30) then
        Delete(0);
      Append(SendErrorVal);
    end;
end;

procedure TObmenThread.MyMessageProc;
begin
  if MyMessageId=mmCharCnt then
  begin
    ObmenForm.Edit1.Text := IntToStr(MyMessageVal);
  end
  else begin
    ObmenForm.Edit1.Text := '0';
    case MyMessageId of
      mmSndStop:
        ObmenForm.Edit2.Text := IntToStr(MyMessageVal);
      mmRcvStop:
        ObmenForm.Edit3.Text := IntToStr(MyMessageVal);
      mmKvtStop:
        ObmenForm.Edit4.Text := IntToStr(MyMessageVal);
      mmNewAttempt:
        ObmenForm.Edit5.Text := IntToStr(MyMessageVal);
    end;
  end;
end;

procedure TObmenThread.ObmenThreadOnTerminate(Sender: TObject);
begin
  with ObmenForm do
  begin
    Started := False;
    CloseBtn.Caption := '&Закрыть';
    ProcessBtn.Enabled := True;
  end;
  //  ObmenForm.ModalResult := mrOk;
end;

function MakeObmen(InitMessage: string; BankAddr: string;
  BankPort: integer; MyAccount: string;
  AuthKey: pointer; TimeOut: longword;
  MaxAuthTry: integer; Proto: string;
  Dir: string): Boolean;
begin
  Result := False;
  SuccessConnect := False;
  CntS := 0;
  CntR := 0;
  CntK := 0;
  CntA := 0;
  ObmenForm := TObmenForm.Create(Application);
  with ObmenForm do
  begin
    FBankAddr := BankAddr;
    FBankPort := BankPort;
    FMyAccount := MyAccount;
    FAuthKey := AuthKey;
    FMyTimeOut := TimeOut;
    FMaxAuthTry := MaxAuthTry;
    FProto := Proto;
    FDir := Dir;
    Memo1.Lines.Append(InitMessage);
    ShowModal;
    Free;
  end;
  Result := SuccessConnect;
end;

procedure TObmenForm.Button1Click(Sender: TObject);
begin
  ProcessBtn.Enabled := False;
  CloseBtn.Caption := '&Прервать';
  Started := true;
  ObmenThread := TObmenThread.Create(true);
  with ObmenThread do
    begin
      HostAddr := FBankAddr;
      PortNum := FBankPort;
      Account := FMyAccount;
      ObmenKey := FAuthKey;
      TimeOut := FMyTimeOut;
      MaxAuth := FMaxAuthTry;
      ProtoName := FProto;
      Directory := FDir;
      OnTerminate := ObmenThreadOnTerminate;
      FreeOnTerminate := true;
      Resume;
    end;
end;

procedure TObmenForm.Button2Click(Sender: TObject);
begin
  if Started then
    ObmenThread.Terminate
  else
    ModalResult := mrOk;
end;

procedure TObmenForm.FormCloseQuery(Sender: TObject;
  var CanClose: Boolean);
begin
  CanClose := true;
  if Started then
  begin
    CanClose := false;
    if MessageBox(Handle, 'Прервать обмен?', PChar(Caption),
      MB_YESNOCANCEL or MB_ICONWARNING)=ID_YES
    then
      ObmenThread.Terminate;
  end;
end;

end.

