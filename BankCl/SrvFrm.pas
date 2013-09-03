unit SrvFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ScktComp, StdCtrls, Buttons;

const
  WM_UPDATECOUNTER = WM_USER + 126;

type
  TForm1 = class(TForm)
    ServerSocket: TServerSocket;
    Memo1: TMemo;
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    Memo2: TMemo;
    Memo3: TMemo;
    BitBtn3: TBitBtn;
    Label1: TLabel;
    ListBox1: TListBox;
    Label2: TLabel;
    procedure ServerSocketAccept(Sender: TObject;
      Socket: TCustomWinSocket);
    procedure ServerSocketListen(Sender: TObject;
      Socket: TCustomWinSocket);
    procedure BitBtn3Click(Sender: TObject);
    procedure ServerSocketClientConnect(Sender: TObject;
      Socket: TCustomWinSocket);
    procedure ServerSocketClientDisconnect(Sender: TObject;
      Socket: TCustomWinSocket);
    procedure ServerSocketClientError(Sender: TObject;
      Socket: TCustomWinSocket; ErrorEvent: TErrorEvent;
      var ErrorCode: Integer);
    procedure ServerSocketClientRead(Sender: TObject;
      Socket: TCustomWinSocket);
    procedure ServerSocketClientWrite(Sender: TObject;
      Socket: TCustomWinSocket);
    procedure BitBtn1Click(Sender: TObject);
    procedure BitBtn2Click(Sender: TObject);
    procedure ListBox1DblClick(Sender: TObject);
    procedure ListBox1Click(Sender: TObject);
  private
    procedure WMUpdateCounter(var Message: TMessage); message WM_UPDATECOUNTER;
  public
    procedure AddProto(S: string);
  end;

var
  Form1: TForm1;

implementation

{$R *.DFM}

procedure TForm1.BitBtn3Click(Sender: TObject);
begin
  ServerSocket.Active := not ServerSocket.Active;
  if ServerSocket.Active then
    BitBtn3.Caption := 'Deactivate'
  else
    BitBtn3.Caption := 'Activate';
  ListBox1Click(nil);
end;

procedure TForm1.AddProto(S: string);
begin
  Memo3.Lines.Add(S);
  Application.ProcessMessages;
end;

procedure TForm1.ServerSocketAccept(Sender: TObject;
  Socket: TCustomWinSocket);
begin
  AddProto('Connected to: ' + Socket.RemoteAddress);
end;

procedure TForm1.ServerSocketListen(Sender: TObject;
  Socket: TCustomWinSocket);
begin
  AddProto('OnListen');
end;

procedure TForm1.ListBox1DblClick(Sender: TObject);
var
  I: Integer;
begin
  Application.ProcessMessages;
  I := ServerSocket.Socket.ActiveConnections;
  Label2.Caption := IntToStr(I);
  while ListBox1.Items.Count>I do
    ListBox1.Items.Delete(I);
  while ListBox1.Items.Count<I do
    ListBox1.Items.Add('C'+IntToStr(I-1));
end;

procedure TForm1.WMUpdateCounter(var Message: TMessage);
begin
  inherited;
  ListBox1DblClick(nil);
end;

procedure TForm1.ServerSocketClientConnect(Sender: TObject;
  Socket: TCustomWinSocket);
begin
  AddProto('ClientConnect');
  PostMessage(Handle, WM_UPDATECOUNTER, 0, 0);
end;

procedure TForm1.ServerSocketClientDisconnect(Sender: TObject;
  Socket: TCustomWinSocket);
begin
  AddProto('ClientDisconnect');
  PostMessage(Handle, WM_UPDATECOUNTER, 0, 0);
end;

procedure TForm1.ServerSocketClientError(Sender: TObject;
  Socket: TCustomWinSocket; ErrorEvent: TErrorEvent;
  var ErrorCode: Integer);
begin
  AddProto('Error '+IntToStr(ErrorCode));
end;

var
  BufSz: DWord = 0;

procedure TForm1.ServerSocketClientRead(Sender: TObject;
  Socket: TCustomWinSocket);
var
  S: string;
begin
  BufSz := BufSz+Socket.ReceiveLength;
  AddProto('ClRead '+IntToStr(Socket.ReceiveLength));
  if BufSz>5 then
  begin
    S := Socket.ReceiveText;
    Memo1.Lines.Add(S);
    Socket.SendText('It''s ok: '+S);
    BufSz := 0;
  end;
end;

procedure TForm1.BitBtn2Click(Sender: TObject);
var
  I: Integer;
  Buf: array[0..4] of Char;
begin
  I := ListBox1.ItemIndex;
  if (I>=0) and (I<ServerSocket.Socket.ActiveConnections) then
  begin
    Buf := 'AB'#0'DE';
    ServerSocket.Socket.Connections[I].SendBuf(Buf, SizeOf(Buf));
    ServerSocket.Socket.Connections[I].SendText(Memo2.Text);
    Memo2.Clear;
  end;
end;

procedure TForm1.ServerSocketClientWrite(Sender: TObject;
  Socket: TCustomWinSocket);
begin
  AddProto('ClWrite');
end;

procedure TForm1.BitBtn1Click(Sender: TObject);
begin
  if ServerSocket.Active then
    BitBtn3Click(nil);
  Close;
end;

procedure TForm1.ListBox1Click(Sender: TObject);
begin
  BitBtn2.Enabled :=
    (ListBox1.ItemIndex>=0) and (ListBox1.ItemIndex<ListBox1.Items.Count);
  BitBtn2.Caption := 'Send to '+IntToStr(ListBox1.ItemIndex);
end;

end.
