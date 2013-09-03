unit TestEngFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons, CrySign;

type
  TForm1 = class(TForm)
    Memo1: TMemo;
    Memo2: TMemo;
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    BitBtn3: TBitBtn;
    Memo3: TMemo;
    procedure BitBtn3Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure BitBtn2Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.DFM}

procedure TForm1.BitBtn3Click(Sender: TObject);
begin
  Close;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  FN, S: string;
begin
  FN := 'Key'+#13#10+'Key';
  S := 'veppfcpt,'+#13#10+''+#13#10+'';
  if InitCryptoEngine(ceiDomenK, FN, S, True)<>ID_OK then
    ShowMessage('No init');
  {FN := 'FloppyKey\'+#13#10+'Key\';
  S := 'mister'+#13#10+'1'+#13#10+'oper1';
  if InitCryptoEngine(ceiTcbGost, FN, S, True)<>ID_OK then
    ShowMessage('No init');}
end;

function SaveToFile(Buf: PChar; BufLen: Integer; FN: string): Boolean;
var
  F: file of Byte;
begin
  Result := False;
  AssignFile(F, FN);
  {$I-} Rewrite(F); {$I+}
  if IOResult=0 then
  begin
    BlockWrite(F, Buf^, BufLen);
    CloseFile(F);
    Result := True;
  end;
end;

function LoadFromFile(Buf: PChar; MaxLen: Integer; FN: string): Integer;
var
  F: file of Byte;
begin
  Result := 0;
  AssignFile(F, FN);
  {$I-} Reset(F); {$I+}
  if IOResult=0 then
  begin
    BlockRead(F, Buf^, MaxLen, Result);
    CloseFile(F);
  end;
end;

var
  Buf: array[0..1023] of Char;

var
  ControlData: TControlData;

procedure TForm1.BitBtn1Click(Sender: TObject);
var
  Err: Integer;
begin
  StrPLCopy(Buf, Memo1.Text, SizeOf(Buf)-1);
  ControlData.cdCheckSelf := False;
  ControlData.cdTargetNode := 5;
  ControlData.cdLoginList := 'cbtcb';//'005206BA';//'cbtcb#cbt235';
  Err := EncryptBlock(@Buf, StrLen(Buf)+1, SizeOf(Buf), smShowInfo,
    @ControlData);
  if Err>0 then
  begin
    Memo3.Lines.Add('Ура! '+IntToStr(Err)+#13#10+Buf);
    SaveToFile(@Buf, Err, 'c:\aaa.enc');
  end
  else
    Memo3.Lines.Add('Нифига!');
end;

procedure TForm1.BitBtn2Click(Sender: TObject);
var
  Len, Err: Integer;
begin
  Len := LoadFromFile(Buf, SizeOf(Buf), 'c:\aaa.enc');
  if Len>0 then
  begin
    ControlData.cdCheckSelf := True;
    ControlData.cdTargetNode := 5;
    ControlData.cdLoginList := '';
    Err := DecryptBlock(@Buf, Len, StrLen(Buf), smShowInfo, @ControlData);
    if Err>0 then
    begin
      Memo2.Lines.Clear;
      Memo2.Lines.Add(Buf);
      Memo3.Lines.Add('Ура! '+IntToStr(Err));
    end
    else
      Memo3.Lines.Add('Нифига!');
  end
  else
    Memo3.Lines.Add('Нет файло');
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  DoneAllCryptoEngine;
end;

end.
