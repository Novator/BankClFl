unit ClntFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ScktComp, StdCtrls, Buttons;

type
  TForm1 = class(TForm)
    Memo1: TMemo;
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    ClientSocket: TClientSocket;
    Edit1: TEdit;
    BitBtn3: TBitBtn;
    BitBtn4: TBitBtn;
    Memo2: TMemo;
    Memo3: TMemo;
    CheckBox1: TCheckBox;
    procedure BitBtn3Click(Sender: TObject);
    procedure BitBtn4Click(Sender: TObject);
    procedure ClientSocketConnect(Sender: TObject;
      Socket: TCustomWinSocket);
    procedure BitBtn1Click(Sender: TObject);
    procedure ClientSocketConnecting(Sender: TObject;
      Socket: TCustomWinSocket);
    procedure ClientSocketDisconnect(Sender: TObject;
      Socket: TCustomWinSocket);
    procedure ClientSocketError(Sender: TObject; Socket: TCustomWinSocket;
      ErrorEvent: TErrorEvent; var ErrorCode: Integer);
    procedure ClientSocketLookup(Sender: TObject;
      Socket: TCustomWinSocket);
    procedure ClientSocketRead(Sender: TObject; Socket: TCustomWinSocket);
    procedure ClientSocketWrite(Sender: TObject; Socket: TCustomWinSocket);
    procedure BitBtn2Click(Sender: TObject);
  private
    { Private declarations }
  public
    procedure AddProto(S: string);
  end;

var
  Form1: TForm1;

implementation

{$R *.DFM}

procedure TForm1.AddProto(S: string);
begin
  Memo3.Lines.Add(S);
  Application.ProcessMessages;
end;

procedure TForm1.BitBtn3Click(Sender: TObject);
begin
  BitBtn4Click(nil);
  ClientSocket.Host := Edit1.Text;
  ClientSocket.Active := True;
end;

procedure TForm1.BitBtn4Click(Sender: TObject);
begin
  ClientSocket.Active := False;
end;

procedure TForm1.BitBtn1Click(Sender: TObject);
begin
  Close;
end;

procedure TForm1.ClientSocketConnect(Sender: TObject;
  Socket: TCustomWinSocket);
begin
  AddProto('Connected to: ' + Socket.RemoteHost);
end;

procedure TForm1.ClientSocketConnecting(Sender: TObject;
  Socket: TCustomWinSocket);
begin
  AddProto('Server is found');
end;

procedure TForm1.ClientSocketDisconnect(Sender: TObject;
  Socket: TCustomWinSocket);
begin
  AddProto('Disconnected');
end;

procedure TForm1.ClientSocketError(Sender: TObject;
  Socket: TCustomWinSocket; ErrorEvent: TErrorEvent;
  var ErrorCode: Integer);
begin
  AddProto('Error '+IntToStr(ErrorCode));
end;

procedure TForm1.ClientSocketLookup(Sender: TObject;
  Socket: TCustomWinSocket);
begin
  AddProto('LookUp');
end;

var
  BS : integer = 0;
procedure TForm1.ClientSocketRead(Sender: TObject;
  Socket: TCustomWinSocket);
begin
  AddProto('Read  '+IntToStr(Socket.ReceiveLength));
  BS := BS + Socket.ReceiveLength;
  if BS>5 then
  begin
    Memo1.Lines.Add(Socket.ReceiveText);
    BS := 0;
  end;
end;

procedure TForm1.ClientSocketWrite(Sender: TObject;
  Socket: TCustomWinSocket);
begin
  AddProto('Write');
end;

procedure TForm1.BitBtn2Click(Sender: TObject);
var
  S: string;
begin
  if ClientSocket.Active then
  begin
    S := Memo2.Text;
    if CheckBox1.Checked then
      S := S+#13;
    ClientSocket.Socket.SendText(S);
    Memo2.Clear;
  end;
end;

end.
