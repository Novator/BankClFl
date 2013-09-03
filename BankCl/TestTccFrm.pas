unit TestTccFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons, TccItcs, ExtCtrls, Mask, ToolEdit, RXCtrls, CrySign;

type
  TForm1 = class(TForm)
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    Panel1: TPanel;
    BitBtn3: TBitBtn;
    BitBtn4: TBitBtn;
    Memo1: TMemo;
    BitBtn5: TBitBtn;
    Edit1: TEdit;
    Memo2: TMemo;
    Edit2: TEdit;
    BitBtn6: TBitBtn;
    BitBtn7: TBitBtn;
    Edit4: TEdit;
    BitBtn8: TBitBtn;
    DirectoryEdit1: TDirectoryEdit;
    CheckBox1: TCheckBox;
    DirectoryEdit2: TDirectoryEdit;
    procedure BitBtn1Click(Sender: TObject);
    procedure BitBtn2Click(Sender: TObject);
    procedure BitBtn3Click(Sender: TObject);
    procedure BitBtn4Click(Sender: TObject);
    procedure Panel1DblClick(Sender: TObject);
    procedure BitBtn5Click(Sender: TObject);
    procedure BitBtn7Click(Sender: TObject);
  private
    { Private declarations }
  public
    procedure AddProto(N, S: string);
  end;

var
  Form1: TForm1;

implementation

{$R *.DFM}

procedure TForm1.AddProto(N, S: string);
begin
  Memo1.Lines.Add('=='+N+'========'+#13#10+S);
end;

procedure TForm1.Panel1DblClick(Sender: TObject);
var
  I: Integer;
begin
  Panel1.Enabled := Sender<>nil;
  BitBtn1.Enabled := not Panel1.Enabled;
  BitBtn8.Enabled := BitBtn1.Enabled;
  for I := 0 to Panel1.ControlCount-1 do
    Panel1.Controls[I].Enabled := Panel1.Enabled;
end;

var
  pn: EXT_PATHNAMES;
  fc: EXT_FULL_CONTEXT;
  pErrDefSize: dWord;

procedure TForm1.BitBtn1Click(Sender: TObject);
var
  Err: Integer;
  Pass: array[0..31] of Char;
  UserID: array[0..9] of Char;
  UserNick: array[0..91] of Char;
  UserName: array[0..71] of Char;
  KeyPath: array[0..511] of Char;
  TransPath: array[0..511] of Char;
begin
  StrPLCopy(TransPath, DirectoryEdit1.Text, SizeOf(TransPath)-1);
  {if (StrLen(TransPath)>0) and (TransPath[StrLen(TransPath)-1]='\') then
    TransPath[StrLen(TransPath)-1] := #0;}

  StrPLCopy(KeyPath, DirectoryEdit2.Text, SizeOf(KeyPath)-1);
  {if (StrLen(KeyPath)>0) and (KeyPath[StrLen(KeyPath)-1]='\') then
    KeyPath[StrLen(KeyPath)-1] := #0;}

  StrPLCopy(Pass, Edit2.Text, SizeOf(Pass)-1);
  with pn do
  begin
    m_pszKeyDisketteDirectory := KeyPath;
    m_pszTransportDirectory := TransPath;
  end;
  FillChar(fc, SizeOf(fc), #0);
  with fc do
  begin
    hParent := Self.Handle;
    pKeyStorage := @pn;
  end;
  if Sender=BitBtn8 then
    Err := ExtInitCryptEx(@fc)
  else
    Err := ExtInitCrypt(Pass, StrLen(Pass), @fc);
  if Err=0 then
    Panel1DblClick(Sender);
  AddProto('InitCrypt', ErrToStr(Err));

  Err := ExtGetOwnID(@fc, UserID);
  AddProto('GetOwnID', 'ID='+UserID+' '+ErrToStr(Err));

  Err := ExtGetUserAlias(@fc, UserID, UserNick, UserName);
  AddProto('GetUserAlias', 'Nick='+UserNick+' '+' Name='+UserName+' '+ErrToStr(Err));
end;

procedure TForm1.BitBtn2Click(Sender: TObject);
begin
  if BitBtn3.Enabled then
    BitBtn3Click(nil);
  Close;
end;

procedure TForm1.BitBtn3Click(Sender: TObject);
begin
  ExtCloseCrypt(@fc);
  Panel1DblClick(nil);
  AddProto('CloseCrypt','Done');
end;

function SaveBlockToFile(Buf: PChar; BufLen: Integer; FN: string;
  Sign: PChar; SignLen: Integer): Boolean;
var
  F: file of Byte;
begin
  Result := False;
  AssignFile(F, FN);
  {$I-} Rewrite(F); {$I+}
  if IOResult=0 then
  begin
    if Sign<>nil then
    begin
      {C := PChar(@BufLen)[0];
      Write(F, Byte(C));
      C := PChar(@BufLen)[1];
      Write(F, Byte(C));
      C := PChar(@BufLen)[2];
      Write(F, Byte(C));
      C := PChar(@BufLen)[3];
      Write(F, Byte(C));}
      BlockWrite(F, PChar(@BufLen)^, 4);
    end;
    BlockWrite(F, Buf^, BufLen);
    if Sign<>nil then
      BlockWrite(F, Sign^, SignLen);
    CloseFile(F);
    Result := True;
  end;
end;

function LoadBlockFromFile(var Buf: PChar; var BufLen: Integer;
  FN: string; GetSign: Boolean; var Sign: PChar; var SignLen: Integer): Boolean;
var
  F: file of Byte;
  TrLen: Integer;
begin
  Result := False;
  Buf := nil;
  Sign := nil;
  SignLen := 0;
  AssignFile(F, FN);
  {$I-} Reset(F); {$I+}
  if IOResult=0 then
  begin
    if GetSign then
    begin
      BufLen := 0;
      BlockRead(F, BufLen, 4, TrLen);
      if TrLen<4 then
        BufLen := 0;
      SignLen := FileSize(F)-TrLen;
      if SignLen<BufLen then
        BufLen := SignLen;
      SignLen := SignLen-BufLen;
      if SignLen<0 then
        SignLen := 0;
    end
    else
      BufLen := FileSize(F);
    Buf := ExtAllocMemory(BufLen);
    BlockRead(F, Buf^, BufLen, TrLen);
    if (SignLen>0) and GetSign then
    begin
      Sign := ExtAllocMemory(SignLen);
      BlockRead(F, Sign^, SignLen);
    end;
    CloseFile(F);
    Result := True;
  end;
end;

var
  SignCntxt: EXT_SIGN_CONTEXT;
  SignatureCntxt: EXT_SIGNATURE_CONTEXT;

const
  pnLogin = 'OID.2.5.4.65';
  pnNode = 'OID.2.5.4.5';
  pnFirm = 'O';

function ExtractParam(ParName: string; ASignInfo: PChar): string;
var
  I, L, J, K: Integer;
  SignInfo: string;
begin
  Result := '';
  if ASignInfo<>nil then
  begin
    SignInfo := StrPas(ASignInfo);
    ParName := ParName+'=';
    I := Pos(ParName, SignInfo);
    L := Length(SignInfo);
    if I>0 then
    begin
      I := I+Length(ParName);
      J := I;
      K := -1;
      while (J<=L) and ((SignInfo[J]<>',') or (K=1)) do
      begin
        if SignInfo[J]='"' then
        begin
          if K<=0 then
          begin
            if K<0 then
              I := J+1;
            K := 1
          end
          else begin
            if (J<L) and (SignInfo[J+1]='"') then
              Inc(J)
            else begin
              K := 0;
              Dec(J);
              Dec(J);
              L := J;
            end;
          end;
        end;
        if K<0 then
          K := 0;
        Inc(J);
      end;
      Result := Copy(SignInfo, I, J-I+1);
      I := Pos('""', Result);
      if I>0 then
      begin
        L := Length(Result);
        while (I<L) do
        begin
          if (Result[I]='"') and (Result[I+1]='"') then
          begin
            Delete(Result, I, 1);
            Dec(L);
          end;
          Inc(I);
        end;
      end;
    end;
  end;
end;

procedure TForm1.BitBtn4Click(Sender: TObject);
const
  MesTitle: PChar = 'Проверка ЭЦП';
var
  I, Len, Err, SignatureSize, SignLen: Integer;
  dwControlInfoSize, dwSignatureNum, dwCertStatus, dwResultsSize,
    dwEncodedCertLen, dwSignerInfoLen, dwSignStatus, dwSignInfoLen: dWord;
  {TempName: array[0..64] of Char;}
  SignTime: SYSTEMTIME;
  ASgnData, ASign: PChar;
  Mes: string;
  SignInfo: PChar;
begin
  if LoadBlockFromFile(ASgnData, Len, Edit4.Text, CheckBox1.Checked,
    ASign, SignLen) then
  begin
    if SignLen>0 then
    begin
      with SignCntxt do
      begin
        Flags := EXT_RETURN_CONTROL_INFO;
        ResultsSize := 0;
        ControlInfoSize := 0;
        SignaturesNum := 0;
        pData := ASgnData;
        DataLen := Len;
        pSignaturesData := ASign;
        SignaturesDataLen := SignLen;
      end;
      Err := ExtVerifySign(@fc, @SignCntxt, nil);
      AddProto('VerifySign', {'SignL='+IntToStr(SignatureSize)+#13#10+}ErrToStr(Err)
        +' SN='+IntToStr(SignCntxt.SignaturesNum));
      dwResultsSize       := SignCntxt.ResultsSize;
      dwControlInfoSize   := SignCntxt.ControlInfoSize;
      dwSignatureNum      := SignCntxt.SignaturesNum;
      for I := 0 to dwSignatureNum-1 do
      begin
        dwCertStatus := SignCntxt.pSignaturesResults[I].CertResult;
        dwSignStatus := SignCntxt.pSignaturesResults[I].SignResult;
        FillChar(SignatureCntxt, SizeOf(SignatureCntxt), #0);
        with SignatureCntxt do
        begin
          pCertificate := 0;
          CertificateLen := 0;
          pSignerInfo := 0;
          SignerInfoLen := 0;
        end;
        SignCntxt.SignaturesNum := I;
        Err := ExtGetSignInfo(@fc, @SignCntxt, @SignatureCntxt);
        AddProto('GetSignInfo', ErrToStr(Err));

        dwEncodedCertLen := SignatureCntxt.CertificateLen;
        dwSignerInfoLen :=  SignatureCntxt.SignerInfoLen;

        if GetSignIssuerName(SignatureCntxt.pCertificate,
          dwEncodedCertLen, SignInfo, dwSignInfoLen) then
        begin
          AddProto('GetSignIssuerName', 'SIL='+IntToStr(dwSignInfoLen)+'['
            +SignInfo+']'+ExtractParam(pnFirm, SignInfo)+'|');
          FreeMem(SignInfo);
        end
        else
          AddProto('GetSignIssuerName', '- no');
        {if GetSignTime(SignatureCntxt.pSignerInfo, dwSignerInfoLen, SignTime) then
        begin
          AddProto('GetSignTime', 'CrTime='+DateTimeToStr(SystemTimeToDateTime(SignTime)));
        end
        else
          AddProto('GetSignTime', '- no');}
        ExtFreeMemory(SignatureCntxt.pCertificate, SignatureCntxt.CertificateLen);
        SignatureCntxt.pCertificate := nil;
        SignatureCntxt.CertificateLen := 0;
        ExtFreeMemory(SignatureCntxt.pSignerInfo, SignatureCntxt.SignerInfoLen);
        SignatureCntxt.pSignerInfo := nil;
        SignatureCntxt.SignerInfoLen := 0;
      end;
      SignCntxt.SignaturesNum := dwSignatureNum;
      Err := ExtViewSignResult(@fc, @SignCntxt, 'Test Data');
      AddProto('ViewSignResult', ErrToStr(Err));

      if SignCntxt.ResultsSize>0 then
      begin
          {showmessage('0');}
        ExtFreeMemory(SignCntxt.pSignaturesResults, SignCntxt.ResultsSize);
          {showmessage('1');}
        {SignCntxt.pSignaturesResults := nil;}
          {showmessage('2');}
        SignCntxt.ResultsSize := 0;
      end;
        {showmessage('3a');}
      ExtFreeMemory(SignCntxt.pControlInfo, SignCntxt.ControlInfoSize);
      SignCntxt.pControlInfo := nil;
      SignCntxt.ControlInfoSize := 0;

        {showmessage('3');}

      {ExtFreeMemory(SgnData, 0);}
        {showmessage('4');
      {ExtFreeMemory(ASign, 0);}

      SignCntxt.pSignaturesData := nil;
      SignCntxt.SignaturesDataLen := 0;
    end
    else
      Mes := 'Нет подписей';
    if MessageBox(Handle, PChar(Mes+#13#10'Подписать данные?'), MesTitle, MB_OK
      or MB_ICONQUESTION or MB_YESNOCANCEL)=ID_YES then
    begin
      FillChar(SignCntxt, SizeOf(SignCntxt), #0);
      with SignCntxt do
      begin
        pData := ASgnData;
        DataLen := Len;
        Flags := EXT_MULTIPLE_SIGN or EXT_PKCS7_SIGN;
        pSignaturesData := {nil}ASign;
        SignaturesDataLen := SignLen;
        pFunctionContext := nil;
      end;
      Err := ExtGetSignatureSize(@fc, @SignCntxt, SignatureSize);
      AddProto('GetSignatureSize', 'SignL='+IntToStr(SignatureSize)+#13#10+ErrToStr(Err));
      Err := ExtSign(@fc, @SignCntxt, nil);
      AddProto('Sign', 'SignedL='+IntToStr(SignCntxt.SignaturesDataLen)+#13#10+ErrToStr(Err));
      if SignCntxt.SignaturesDataLen <> SignatureSize then
        AddProto('!!!Error', 'Не совпадает вычисленный и реальный размеры подписи');
      if Err=0 then
        SaveBlockToFile(ASgnData, Len, Edit4.Text, SignCntxt.pSignaturesData,
          SignCntxt.SignaturesDataLen);
      ExtFreeMemory(SignCntxt.pSignaturesData, SignCntxt.SignaturesDataLen);
      SignCntxt.pSignaturesData := nil;
      SignCntxt.SignaturesDataLen := 0;
      ExtFreeMemory(ASgnData, 0);
    end
    else begin
      ExtFreeMemory(ASgnData, 0);
      if ASign<>nil then
        ExtFreeMemory(ASign, 0);
    end;
  end;
end;

const
  MaxKeyIDLen = $20;
  {MaxMessLen 100}

procedure TForm1.BitBtn5Click(Sender: TObject);
var
  CryptData: EXT_CRYPT_CONTEXT;
  Err, SignatureLen, CipherTextLen: Integer;
  MemoryToEncrypt: array[0..63] of Char;
  Receiver: array[0..8+2] of Char;
  Buf: PChar;
  BufLen: Integer;
  Sign: PChar;
  SignLen: Integer;
begin
  repeat
    FillChar(MemoryToEncrypt, SizeOf(MemoryToEncrypt), #0);
    StrCopy(MemoryToEncrypt, 'Привет мир! Привет мир! Привет мир!');
    FillChar(CryptData, SizeOf(CryptData), #0);
    StrPLCopy(Receiver, Edit1.Text, SizeOf(Receiver)-2) ;
    Receiver[StrLen(@Receiver)+1] := #0;
    FillChar(CryptData, SizeOf(CryptData), #0);
    with CryptData do
    begin
      pInputData := @MemoryToEncrypt;
      InputDataLen := StrLen(MemoryToEncrypt);
      pOutputData := nil;
      pReceivers := @Receiver;
    end;
    Err := ExtEncrypt(@fc, @CryptData, nil);
    AddProto('Encrypt', 'BL='+IntToStr(CryptData.OutputDataLen)+'  '+ErrToStr(Err));
    if Err<>0 then
      Break;
    SaveBlockToFile(CryptData.pOutputData, CryptData.OutputDataLen, 'C:\aaa.cry',
      nil, 0);
    ExtFreeMemory(CryptData.pOutputData, CryptData.OutputDataLen);
  until True;
end;


procedure TForm1.BitBtn7Click(Sender: TObject);
var
  CryptData: EXT_CRYPT_CONTEXT;
  Err, SignatureLen, CipherTextLen: Integer;
  MemoryToEncrypt: array[0..63] of Char;
  Receiver: array[0..8+2] of Char;
  Buf: PChar;
  BufLen: Integer;
  Sign: PChar;
  SignLen: Integer;
begin
  repeat
    Buf := nil;
    LoadBlockFromFile(Buf, BufLen, 'C:\aaa.cry', False, Sign, SignLen);
    FillChar(CryptData, SizeOf(CryptData), #0);
    with CryptData do
    begin
      pInputData := Buf;
      InputDataLen := BufLen;
      pOutputData := nil;
    end;
    Err := ExtDecrypt(@fc, @CryptData, nil);
    AddProto('Decrypt', 'BL='+IntToStr(CryptData.OutputDataLen)+'  '+ErrToStr(Err));
    ExtFreeMemory(Buf, 0);
    if Err<>0 then
      Break;
    SaveBlockToFile(CryptData.pOutputData, CryptData.OutputDataLen,
      'C:\bbb.cry', nil, 0);
    ExtFreeMemory(CryptData.pOutputData, CryptData.OutputDataLen);
  until True;
end;

end.
