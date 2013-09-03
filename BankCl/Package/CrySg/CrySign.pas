unit CrySign;

interface

uses
  Windows, SysUtils, {Sign, CryDrv, }Classes, PasFrm, SignVeiwFrm, Forms, TccItcs,
    Utilits, CommCons, VeiwSignListFrm, Graphics;

const
  ceiNone    = -1;
  ceiUnknown = 0;
  ceiTcbGost = 1;
  ceiDomenK  = 2;
  {ceiPgp     = 3;
  ceiGnuPgp  = 4;}

  smOverwrite        = $01;  // �������� ���������� �������
  smShowInfo         = $02;  // ����� ��������
  smDefShowInfo      = $04;  // ����� ��-� ������� �����. �����
  smCheckLogin       = $08;  // �������� ��������� � �������
  smThoroughly       = $10;  // ���������� �������� �������
  smExtFormat        = $20;  // ����������� ������ ������� - �����������
  smOneSignInLevel   = $40;  // �������� ���������� ������ ����� ������� � ������
  smCanDelAnySign    = $80;  // ����������� �������� ������� ���������
  //��������� ����������
  smGetLoginInfo     = $100; // �������� �������� � ��������, �����, ������� ������������
  smFile             = $200; // ������� �����
  smCertVerify       = $400; // �������� �����������

  SignLenVip1 = 1100;
  SignLenVip2 = 1200;

  pnNewLogin = 'CN';
  pnOldLogin = 'OID.2.5.4.65';
  pnNode = 'OID.2.5.4.5';
  pnFirm = 'O';

  DividerOfList = '/';

type
  PControlData = ^TControlData;
  TControlData = packed record
    cdCheckSelf: Boolean;
    cdTagNode: Word;
    cdTagLogin: TAbonLogin;
  end;

  TSignValid = (svNone, svAllGood, svInvalid, svChanged);
               {����, ��� ������, ���-�� �� ���, ��������}

  PSignDescr = ^TSignDescr;   {���� � �����������}
  TSignDescr = packed record
    siCount: Integer;       {����� ��������}
    siLen: Integer;         {����� ����� ����������� �� ����. �������� (4 ����)}
    siOwnIndex: Integer;    {������ ������������ �������, ����� -1}
    siValid: TSignValid;    {����������� �����������}
    siComplete: Word;       {����� ����� ������� �����������}
    siLoginNameProc: Pointer;  {��������� �� �-� �������� ���� � ������ ������� �� �� ���������}
  end;

  //��������� ����������
  PSignUserInfo = ^TSignUserInfo;           //���� � ������������� ��� �����
  TSignUserInfo = packed record
    siSignNum: Integer;                     //����� ��������
    siLoginName: array [0..8] of string[8]; //������ ���������������� �������
    siUserName: array [0..8] of string;     //������ ������������ �������
    siUserStatus: array [0..8] of Integer; //������ ������� �������
  end;

  PFileBasePtr = ^TFileBasePtr;            //������ � ���� ���
  TFileBasePtr = packed record
    ECPLen: Integer;                       //������
    ECP: PChar;                           //���
  end;


var
  ManualStr: string = '?';
  ChangeKeyboardLayout: Boolean = False;

function InitCryptoEngine(ACryptoEngineIndex: Integer;
  Paths, Params: string; Main: Boolean): Integer;
function IsCryptoEngineInited: Boolean;
function GetMainCryptoEngineIndex: Integer;
function CheckSign(AData: PChar; ADataLen, ACommonLen: Integer;
  Mode: Integer; ControlDataPtr: PControlData; SignDescrPtr: PSignDescr;
  AllowLogins: string): Integer;
procedure EraseSign(AData: PChar; ADataLen, ACommonLen: Integer);
function AddSign(CEI: Integer; AData: PChar; ADataLen, ACommonLen: Integer;
  Mode: Integer; ControlDataPtr: PControlData; AllowLogins: string): Integer;
procedure DoneAllCryptoEngine;
function InitCryptoEngine1(Paths, Params: string): Integer;
function InitCryptoEngine2(Paths, Params: string): Integer;
function GetAllCryptoInfo: string;
function GenRandom(Buf: PChar; BufLen: DWord): Boolean;
function GetSelfLogin(RegLogin: string): string;
function EncryptBlock(CEI: Integer; AData: PChar; ADataLen, ACommonLen: Integer;
  Mode: Integer; ControlDataPtr: PControlData): Integer;
function DecryptBlock(AData: PChar; ADataLen, ACommonLen: Integer;
  Mode: Integer; ControlDataPtr: PControlData): Integer;
function IsDomenKInited: Boolean;
function IsKeyNew: Boolean;
function GetCryptoIdent: string;

implementation

var
  MainCryptoEngineIndex: Integer = ceiNone;

function InitCryptoEngine(ACryptoEngineIndex: Integer;
  Paths, Params: string; Main: Boolean): Integer;
begin
  //messagebox(0, PChar(IntToStr(ACryptoEngineIndex)), '+', 0);
  case ACryptoEngineIndex of
    ceiTcbGost:
      Result := InitCryptoEngine1(Paths, Params);
    ceiDomenK:
      Result := InitCryptoEngine2(Paths, Params);
    {ceiPgp:
      Result := InitCryptoEngine3(Paths, Params);}
    else
      Result := IDIGNORE;
  end;
  if Result=IDOK then
  begin
    if Main or (MainCryptoEngineIndex=ceiNone) then
      MainCryptoEngineIndex := ACryptoEngineIndex;
  end;
  {else
    CryptoEngineIndex := ceiNone;}
end;

function IsCryptoEngineInited: Boolean;
begin
  Result := MainCryptoEngineIndex>ceiNone;
end;

function GetMainCryptoEngineIndex: Integer;
begin
  Result := MainCryptoEngineIndex;
end;

function GetParam(const Param: string; Index: Integer): string;
var
  S: string;
  I, L, P: Integer;
begin
  Result := '';
  S := Param;
  I := 0;
  L := Length(S);
  repeat
    P := AnsiPos(#13, S);
    if P>0 then
      Dec(P)
    else
      P := L;
    if I=Index then
      Result := Copy(S, 1, P);
    if L>0 then
    begin
      if (P<L) and (S[P+1]=#13) then
        Inc(P);
      if (P<L) and (S[P+1]=#10) then
        Inc(P);
    end;
    Delete(S, 1, P);
    L := Length(S);
    Inc(I);
  until (I>Index) or (L=0);
end;

var
  MainPassword: string;

{function GetMainPassword: string;
begin
  Result := MainPassword;
end;}

function InitCryptoEngine1(Paths, Params: string): Integer;
const
  MesTitle: PChar = '������������� ������� DOS';
var
  KeyDir, TransDir, OperNum, OperPassword: string;
  EnterMP, EnterOP: Boolean;
  Oper: Word;
begin
  Result := IDRETRY;
  KeyDir := GetParam(Paths, 0);
  {if Length(KeyDir)=0 then
    KeyDir := 'A:\';}
  TransDir := GetParam(Paths, 1);
  {if Length(TransDir)=0 then
    TransDir := 'Key';}
  //NormalizeDir(KeyDir);
  //NormalizeDir(TransDir);

  MainPassword := GetParam(Params, 0);
  OperNum := GetParam(Params, 1);
  OperPassword := GetParam(Params, 2);
  EnterMP := MainPassword=ManualStr;
  EnterOP := (OperPassword=ManualStr) or (OperNum=ManualStr);

  //messagebox(0, PChar(KeyDir+#13#10+TransDir+#13#10+MainPassword
  //  +#13#10+OperNum+#13#10+OperPassword), '1', 0);

  while Result=IDRETRY do
  begin
    {if ReadUz(KeyDir+'uz.db3') then
      Result := IDOK
    else}
      Result := MessageBox(GetTopWindow(0), '������ ���� ������.'+#13
        +'�������� �������� �������', MesTitle,
        MB_ABORTRETRYIGNORE or MB_ICONERROR or MB_DEFBUTTON2);
  end;

  if Result=IDOK then
    Result := IDRETRY;
  while Result=IDRETRY do
  begin
    if EnterMP then
    begin
      Result := GetPasswords(Application, 0, '���� ������ �������� �����',
        ChangeKeyboardLayout, MainPassword);
      Application.ProcessMessages;
    end
    else
      Result := IDOK;
    if Result=IDOK then
    begin
      {if ReadGk(KeyDir+'gk.db3', GetMainPassword) then
        Result := IDOK
      else}
        Result := Application.MessageBox('������ �������� �����', MesTitle,
          MB_ABORTRETRYIGNORE or MB_ICONERROR or MB_DEFBUTTON2);
    end;
  end;
  if (Result=IDOK) and {not InitRandom(KeyDir+'random.key')} True then
  begin
    if Application.MessageBox('������ ������������� ���'+#13
      +'������ ����������?', MesTitle, MB_YESNOCANCEL or MB_ICONERROR) = IDYES
    then
      Result := IDIGNORE
    else
      Result := IDABORT
  end;

  if (Result=IDOK) and {not ReadKey(KeyDir+'obmen.key', AuthKey, 2)}True then
  begin
    if Application.MessageBox('������ ������������� ��'+#13
      +'������ ����������?', MesTitle, MB_YESNOCANCEL or MB_ICONERROR) = IDYES
    then
      Result := IDIGNORE
    else
      Result := IDABORT
  end;

  if Result=IDOK then
    Result := IDRETRY;
  while Result=IDRETRY do
  begin
    if EnterOP then
    begin
      Result := GetPasswords(Application, 1, '���� ������ ���������',
        ChangeKeyboardLayout, Params);
      Application.ProcessMessages;
      if Result=IDOK then
      begin
        OperNum := GetParam(Params, 0);
        OperPassword := GetParam(Params, 1);
      end;
    end
    else
      Result := IDOK;
    if Result=IDOK then
    begin
      try
        Oper := StrToInt(OperNum);
      except
        Oper := 1;
      end;
      {if InitSign(Oper, TransDir, OperPassword)=0 then
        Result := IDOK
      else}
        Result := Application.MessageBox('������ ������������� �������',
          MesTitle, MB_ABORTRETRYIGNORE or MB_ICONERROR or MB_DEFBUTTON2);
    end;
  end;
  MainPassword := '';
  OperNum := '';
  OperPassword := '';
end;

var
  KeyPath: array[0..511] of Char;
  TransPath: array[0..511] of Char;
  pn: EXT_PATHNAMES;
  FullContext: EXT_FULL_CONTEXT;
  CryptoEngine2Inited: Boolean = False;

function IsDomenKInited: Boolean;
begin
  Result := IsCryptoEngineInited and CryptoEngine2Inited;
end;

function InitCryptoEngine2(Paths, Params: string): Integer;
const
  MesTitle: PChar = '������������� �������';
var
  KeyDir, TransDir, Psw: string;
  PswEnterMode, Err: Integer;
  Pass: array[0..31] of Char;
begin
  Result := IDABORT;
  if not CryptoEngine2Inited then
  begin
    if IsItscLibLoaded then
    begin
      Result := IDRETRY;
      KeyDir := GetParam(Paths, 0);
      TransDir := GetParam(Paths, 1);
      //NormalizeDir(KeyDir);
      //NormalizeDir(TransDir);
      Psw := GetParam(Params, 0);

      if Psw=ManualStr+ManualStr then
        PswEnterMode := 2
      else
        if Psw=ManualStr then
          PswEnterMode := 1
        else
          PswEnterMode := 0;

      //messagebox(0, PChar(Psw+'/'+IntToStr(PswEnterMode)), '3', 0);
      //messagebox(0, PChar(KeyDir+#13#10+TransDir+#13#10+Psw), '2', 0);

      StrPLCopy(TransPath, TransDir, SizeOf(TransPath)-1);
      StrPLCopy(KeyPath, KeyDir, SizeOf(KeyPath)-1);
      while Result=IDRETRY do
      begin
        with pn do
        begin
          m_pszKeyDisketteDirectory := KeyPath;
          m_pszTransportDirectory := TransPath;
        end;
        FillChar(FullContext, SizeOf(FullContext), #0);
        with FullContext do
        begin
          hParent := Application.Handle;
          pKeyStorage := @pn;
          //if PswEnterMode<2 then
          //  dwFlags := dwFlags or EXT_SILENT_MODE;
        end;
        //ExtCloseCrypt(@FullContext);
        Err := -1;
        if PswEnterMode=2 then
        begin
          //messagebox(0, 'ccc', '1', 0);
          Err := TExtInitCryptEx(GetExtPtr(fiInitCryptEx))(@FullContext);
          Application.ProcessMessages;
          if Err=e_ENTER_PASS_REJECT then
            Result := IDIGNORE
          else
            Result := IDOK;
        end
        else begin
          //messagebox(0, 'aaaa', '1', 0);
          if PswEnterMode=1 then
          begin
            //messagebox(0, 'bbb', '1', 0);
            Result := GetPasswords(Application, 0, '���� ������',
              ChangeKeyboardLayout, Psw);
            Application.ProcessMessages;
          end
          else
            Result := IDOK;
          StrPLCopy(Pass, Psw, SizeOf(Pass)-1);
          if Result=IDOK then
          begin
            Err := TExtInitCrypt(GetExtPtr(fiInitCrypt))(@Pass, StrLen(Pass), @FullContext);
            Application.ProcessMessages;
            if (Err<>0) and (PswEnterMode=0) then
              PswEnterMode := 1;
          end;
        end;
        if Err=0 then
        begin
          Result := IDOK;
          Psw := '';
          if not InitUserNameList(@FullContext, True, Psw) then
            Application.MessageBox(PChar('������ ������������� ������ �������'#13#10
            +Psw), MesTitle, MB_OK or MB_ICONERROR);
        end
        else
          if Result=IDOK then
          begin
            Result := Application.MessageBox(PChar('������ ������������� �����'#13#10
              +ErrToStr(Err)), MesTitle, MB_ABORTRETRYIGNORE or MB_ICONERROR or MB_DEFBUTTON2);
            if (PswEnterMode=0) and (Result=IDRETRY) then
              PswEnterMode := 1;
          end;
      end;
      CryptoEngine2Inited := Result=IDOK;
    end
    else
      Result := Application.MessageBox('���������� ���� "�����-�" �� ���� ���������',
        MesTitle, MB_ABORTRETRYIGNORE or MB_ICONERROR);
  end;
end;

procedure DoneAllCryptoEngine;
begin
  try
    {if GetNode>0 then
      DoneSign;}
    if CryptoEngine2Inited then
    begin
      if IsItscLibLoaded then
        TExtCloseCrypt(GetExtPtr(fiCloseCrypt))(@FullContext);
      CryptoEngine2Inited := False;
      DoneUserNameList;
    end;
    {Done PGP}
  finally
    MainCryptoEngineIndex := ceiNone;
  end;
end;

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

(*procedure addlocprot(S: string);
var
  F: TextFile;
begin
  //messagebox(0, PChar(S), '111111', 0);
  AssignFile(F, 'c:\protloc.txt');
  {$I-} Append(F);
  if IOREsult<>0 then
    Rewrite(F); {$I+}
  WriteLn(F, S);
  CloseFile(F);
end;*)

function GetSelfLogin(RegLogin: string): string;
var
  Err: Integer;
  UserID: array[0..9] of Char;
  UserNick: array[0..91] of Char;
  UserName: array[0..71] of Char;
begin
  Result := RegLogin;
  if (MainCryptoEngineIndex=ceiDomenK) and IsItscLibLoaded then
  begin
    Err := TExtGetOwnID(GetExtPtr(fiGetOwnID))(@FullContext, UserID);
    if Err=0 then
    begin
      Err := TExtGetUserAlias(GetExtPtr(fiGetUserAlias))(@FullContext, UserID, UserNick, UserName);
      if Err=0 then
        Result := UpperCase(Trim(UserName));
    end;
  end;
end;

function CheckSign(AData: PChar; ADataLen, ACommonLen: Integer;
  Mode: Integer; ControlDataPtr: PControlData; SignDescrPtr: PSignDescr;
  AllowLogins: string): Integer;
const
  MesTitle: PChar = '�������� �������';
var
  ComSignLen, Err, MesType, I, J, K: Integer;
  ASign: PChar;
  FromNode, Oper, ToNode: word;
  Mes, SignLoginList, SignTimeList, S, SelfLogin, List1, List2, List3: string;
  dwSignatureNum, dwEncodedCertLen, dwSignerInfoLen, dwSignInfoLen: DWord;
  //PSignCntxt: PEXT_SIGN_CONTEXT;
  SignCntxt: EXT_SIGN_CONTEXT;
  SignatureCntxt: EXT_SIGNATURE_CONTEXT;
  SignInfo: PChar;
  ATime: TDateTime;
  VeiwSignListForm: TVeiwSignListForm;
  SignUserInfo: TSignUserInfo;                   //��������� ����������

begin
  //addlocprot('0===  DL='+inttostr(ADataLen)+' CL='+inttostr(ACommonLen));
  Result := ceiNone;
  //         addlocprot('1===  DL='+inttostr(ADataLen)+' CL='+inttostr(ACommonLen));
  if SignDescrPtr<>nil then
    with SignDescrPtr^ do
    begin
      siCount := 0;
      siLen := 0;
      siOwnIndex := -1;
      siValid := svNone;
      siComplete := 0;
    end;
  ComSignLen := ACommonLen-ADataLen;
           //addlocprot('2===  ComSL='+inttostr(ComSignLen));
  if smShowInfo and Mode<>0 then
  begin
    Mes := '';
    MesType := 0;
  end;
  if ComSignLen>=SignSize then
  begin
    Result := ceiUnknown;
    ASign := @AData[ADataLen];

    if ((Mode and smExtFormat)=0) and (ASign[0]=#$1A) and ((ASign[SignSize-1]=#$19)
      or (ASign[SignSize-1]=#$1A)) and (PInteger(@ASign[1])^=ADataLen)
    then
      I := 1
    else
      I := 0;

    if (ComSignLen=SignSize) or (I>0) then
    begin   {DOS}
      if I=0 then
      begin
        if smShowInfo and Mode<>0 then
        begin
          Mes := '������� �����������';
          MesType := MB_ICONINFORMATION;
        end;
      end
      else begin
        if ControlDataPtr=nil then
        begin
          Result := ceiTcbGost;
          if smShowInfo and Mode<>0 then
          begin
            Mes := '������ ������� ����������';
            MesType := MB_ICONINFORMATION;
          end;
        end
        else begin
          FromNode := 0;
          Oper := 0;
          ToNode := 0;
          Err := {TestSign(AData, ADataLen+SignSize, FromNode, Oper, ToNode)}-153;
          with ControlDataPtr^ do
          begin
            I := 1;
            if (Err=$10) or (Err=$110) then
            begin
              if not cdCheckSelf and ((cdTagNode=0) or (cdTagNode=FromNode)) then
                I := 0
              else
                I := 2;
            end
            else
              if (Err=$5) or (Err=$4) then
              begin
                if cdCheckSelf and ((cdTagNode=0) or (cdTagNode=ToNode)) then
                  I := 0
                else
                  I := 3;
              end;
            if I=0 then
              Result := ceiTcbGost;
            if smShowInfo and Mode<>0 then
            begin
              MesType := MB_ICONWARNING;
              case I of
                0:
                  begin
                    Mes := '������� ���������';
                    MesType := MB_ICONINFORMATION;
                  end;
                2:
                  Mes := '���� ����������� ���������� N='
                    +IntToStr(FromNode)+' (Err='+IntToStr(Err)+')';
                3:
                  Mes := '���� ���������� ���������� N='
                    +IntToStr(ToNode)+' (Err='+IntToStr(Err)+')';
                else begin
                  if {GetNode=0}True then
                    Mes := '������� ������ ������ ��������� ('+IntToStr({GetNode}0)+')'
                  else begin
                    Mes := '������� �����������';
                    MesType := MB_ICONERROR;
                  end;
                end;
              end;
              Mes := Mes+#13#10'���������: �������� '+IntToStr(Oper)
                +', ����-����������� '+IntToStr(FromNode)+', ����-���������� '
                +IntToStr(ToNode)+', ���='+Format('%x', [Err])+'h';
            end;
          end;
        end;
      end;
    end
    else begin   {DomenK}
      if (PInteger(ASign)^=0) and (PInteger(@ASign[4])^=0) then
      begin
        Result := ceiNone;
              //addlocprot('56=== '+inttostr(ADataLen)+' SL='+inttostr(SignLen)+'|');
        if smShowInfo and Mode<>0 then
        begin
          Mes := '������� �����������';
          MesType := MB_ICONINFORMATION;
        end;
      end
      else begin
        if (Mode and smExtFormat)=0 then
        begin   {������� �������}
          if (ControlDataPtr=nil) and ((ComSignLen=SignLenVip1)
            or (ComSignLen=SignLenVip2)) then
          begin
            Result := ceiDomenK;
            if smShowInfo and Mode<>0 then
            begin
              Mes := '������� ����������';
              MesType := MB_ICONINFORMATION;
            end;
          end
          else begin
            if IsItscLibLoaded then
            begin
              FillChar(SignCntxt, SizeOf(SignCntxt), #0);
              with SignCntxt do
              begin
                Flags := Ext_RETURN_CONTROL_INFO;
                if smFile and Mode<>0 then              //��������
                  begin                                 //��������
                  pData := PChar(AllowLogins);          //��������
                  DataType := EXT_FILE_DATA_FLAG;       //��������
                  DataLen := $FFFFFFFF;                 //��������
                  end                                   //��������
                else                                    //��������
                  begin                                 //��������
                  pData := AData;                       //��������
                  DataLen := ADataLen;                  //��������
                  end;                                  //��������
                pSignaturesData := ASign;
                SignaturesDataLen := ComSignLen;
                pControlInfo := nil;
                pSignaturesResults := nil;
              end;
              Err := TExtVerifySign(GetExtPtr(fiVerifySign))(@FullContext, @SignCntxt, nil);
              if (Err=e_NO_ERROR) {or (Err=e_UNKNOWN_CRYPT_METHOD)} then
              begin
                if (ControlDataPtr=nil) {or (Err=e_UNKNOWN_CRYPT_METHOD)
                  and (CryptoEngineIndex<>ceiDomenK)} then
                begin
                  Result := ceiDomenK;
                  if smShowInfo and Mode<>0 then
                  begin
                    Mes := '������� ����������';
                    MesType := MB_ICONINFORMATION;
                  end;
                end
                else begin
                  dwSignatureNum := SignCntxt.SignaturesNum;
                  SignLoginList := '';
                  SignTimeList := '';
                  Mes := '';
                  if (smShowInfo and Mode<>0) or (smCheckLogin and Mode<>0) then
                  begin
                    for I := 0 to dwSignatureNum-1 do
                    begin
                      FillChar(SignatureCntxt, SizeOf(SignatureCntxt), #0);
                      with SignatureCntxt do
                      begin
                        pCertificate := nil;
                        CertificateLen := 0;
                        pSignerInfo := nil;
                        SignerInfoLen := 0;
                      end;
                      SignCntxt.SignaturesNum := I;
                      Err := TExtGetSignInfo(GetExtPtr(fiGetSignInfo))(@FullContext,
                        @SignCntxt, @SignatureCntxt);
                      if Err=0 then
                      begin
                        dwEncodedCertLen := SignatureCntxt.CertificateLen;
                        dwSignerInfoLen :=  SignatureCntxt.SignerInfoLen;
                        if GetSignIssuerName(SignatureCntxt.pCertificate,
                          dwEncodedCertLen, SignInfo, dwSignInfoLen) then
                        begin
                          S := Trim(ExtractParam(pnNewLogin, SignInfo));
                          if Length(S)=0 then
                            S := Trim(ExtractParam(pnOldLogin, SignInfo));
                          AddWordInList(UpperCase(S), SignLoginList);
                          FreeMem(SignInfo);
                        end
                        else
                          Mes := Mes+#13#10'�����N'+IntToStr(I);
                        if GetSignTime(SignatureCntxt.pSignerInfo, dwSignerInfoLen, ATime) then
                        begin
                          AddWordInList(DateTimeToStr(ATime), SignTimeList);
                        end
                        else
                          Mes := Mes+#13#10'����N'+IntToStr(I);
                        TExtFreeMemory(GetExtPtr(fiFreeMemory))(SignatureCntxt.pCertificate, SignatureCntxt.CertificateLen);
                        TExtFreeMemory(GetExtPtr(fiFreeMemory))(SignatureCntxt.pSignerInfo, SignatureCntxt.SignerInfoLen);
                      end
                      else
                        Mes := Mes+#13#10'��.�����N'+IntToStr(I);
                    end;
                    if Length(Mes)>0 then
                      Application.MessageBox(PChar('������ ����������� ������������ ������� '+Mes),
                        MesTitle, MB_OK or MB_ICONERROR);
                    SignCntxt.SignaturesNum := dwSignatureNum;

                    Mes := GetSelfLogin('');

                    //messagebox(0, PChar(Mes+'|'+ControlDataPtr^.cdTagLogin), 'l', 0);
                    //addlocprot('2=== '+inttostr(ADataLen)+' SL='+inttostr(SignLen)+'|');

                    Err := 0;
                    if (Length(Mes)>0) and (IndexOfWordInList(Mes,
                      SignLoginList)>=0)
                    then
                      Err := -1;
                    if Err=0 then
                    begin
                      //Err := WhichLoginExistInList(ControlDataPtr^.cdLoginList, SignLoginList);
                      if smCheckLogin and Mode<>0 then
                      begin
                        Err := IndexOfWordInList(ControlDataPtr^.cdTagLogin, SignLoginList);
                        if Err>=0 then
                          Inc(Err)
                        else
                          Err := 0;
                      end
                      else
                        Err := 1;
                    end;
                  end
                  else
                    Err := 1;
                  //addlocprot('3=== '+inttostr(ADataLen)+' SL='+inttostr(SignLen)+'|');

                  if (Err<>0) and ((smThoroughly and Mode=0) or CryptoEngine2Inited) then
                    Result := ceiDomenK;
                  if smShowInfo and Mode<>0 then
                  begin
                    if (smDefShowInfo and Mode<>0) and CryptoEngine2Inited then
                    begin
                      Err := TExtViewSignResult(GetExtPtr(fiViewSignResult))(@FullContext, @SignCntxt, '�������� �������');
                      if Err<>0 then
                      begin
                        Mes := ErrToStr(Err);
                        Application.MessageBox(PChar(Mes), MesTitle, MB_OK or MB_ICONERROR);
                      end;
                    end
                    else begin
                      if Result=ceiDomenK then
                      begin
                        if Err<0 then
                          Mes := '����������� �������'
                        else
                          Mes := '������� ���������'
                      end
                      else begin
                        if CryptoEngine2Inited then
                          Mes := '������� �����, �� �����������'
                        else
                          Mes := '������� �����, ������������ �� ����������';
                      end;
                      if CryptoEngine2Inited then
                        ShowSignConclusion(SignLoginList, SignTimeList, Mes,
                          ComSignLen, @FullContext, @SignCntxt)
                      else
                        ShowSignConclusion(SignLoginList, SignTimeList, Mes,
                          ComSignLen, nil, nil);
                    end;
                    Mode := Mode and not smShowInfo;
                  end;
                  //addlocprot('4=== '+inttostr(ADataLen)+' SL='+inttostr(SignLen)+'|');
                end;
              end
              else begin
                if smShowInfo and Mode<>0 then
                begin
                  Mes := '������ �������'#13#10+ErrToStr(Err);
                  MesType := MB_ICONWARNING;
                end;
              end;
              //addlocprot('56=== '+inttostr(ADataLen)+' SL='+inttostr(SignLen)+'|');
              with SignCntxt do
              begin
                if pControlInfo<>nil then
                  TExtFreeMemory(GetExtPtr(fiFreeMemory))(pControlInfo, ControlInfoSize);
                if pSignaturesResults<>nil then
                  TExtFreeMemory(GetExtPtr(fiFreeMemory))(pSignaturesResults, ResultsSize);
              end;
            end
            else begin
              if smShowInfo and Mode<>0 then
              begin
                Mes := '���������� ���� "�����-�" �� ���������';
                MesType := MB_ICONWARNING;
              end;
            end;
          end;
        end
        else   {������. ������}
        if IsItscLibLoaded and (SignDescrPtr<>nil) then
        begin
          with SignDescrPtr^ do
          begin
            siCount := PInteger(ASign)^;
            siLen := siCount*4;

            I := Pos(DividerOfList, AllowLogins);
            if I=0 then
              I := Length(AllowLogins)+1;
            List1 := Copy(AllowLogins, 1, I-1);
            Delete(AllowLogins, 1, I);
            I := Pos(DividerOfList, AllowLogins);
            if I=0 then
              I := Length(AllowLogins)+1;
            List2 := Copy(AllowLogins, 1, I-1);
            Delete(AllowLogins, 1, I);
            List3 := AllowLogins;

            //addlocprot('2.22===  siCount='+inttostr(siCount));

            if smShowInfo and Mode<>0 then
              VeiwSignListForm := TVeiwSignListForm.Create(Application)
            else
              VeiwSignListForm := nil;

            //   addlocprot('5===  DL='+inttostr(ADataLen)+' CL='+inttostr(ACommonLen));
            SelfLogin := GetSelfLogin('');
            Mes := '';
            I := 0;
            while (I<siCount) and (4+siLen<ComSignLen) and (siValid<>svInvalid) do
            begin
              Inc(I);
              J := PInteger(@ASign[I*4])^;

              FillChar(SignCntxt, SizeOf(SignCntxt), #0);
              with SignCntxt do
              begin
                Flags := Ext_RETURN_CONTROL_INFO;
                if smFile and Mode<>0 then              //��������
                  begin                                 //��������
                  pData := PChar(AllowLogins);          //��������
                  DataType := EXT_FILE_DATA_FLAG;       //��������
                  DataLen := $FFFFFFFF;                 //��������
                  end                                   //��������
                else                                    //��������
                  begin                                 //��������
                  pData := AData;                       //��������
                  DataLen := ADataLen;                  //��������
                  end;                                  //��������
                pSignaturesData := @ASign[4+siLen];
                SignaturesDataLen := J;
                pControlInfo := nil;
                pSignaturesResults := nil;
              end;
              Err := TExtVerifySign(GetExtPtr(fiVerifySign))(@FullContext, @SignCntxt, nil);
              if (Err=e_NO_ERROR) {or (Err=e_UNKNOWN_CRYPT_METHOD)} then
              begin
                //addlocprot('3===  DL='+inttostr(ADataLen)+' CL='+inttostr(ACommonLen)+' I='+IntToStr(I));
          //      MessageBox(ParentWnd,PChar(IntToStr(SignatureResult.CertResult)), 'Check!',mb_ok);
                dwSignatureNum := SignCntxt.SignaturesNum;
                SignLoginList := '';
                SignTimeList := '';

                FillChar(SignatureCntxt, SizeOf(SignatureCntxt), #0);
                with SignatureCntxt do
                begin
                  pCertificate := nil;
                  CertificateLen := 0;
                  pSignerInfo := nil;
                  SignerInfoLen := 0;
                end;
                SignCntxt.SignaturesNum := 0;
                Err := TExtGetSignInfo(GetExtPtr(fiGetSignInfo))(@FullContext,
                  @SignCntxt, @SignatureCntxt);
                if Err=0 then
                begin
                  dwEncodedCertLen := SignatureCntxt.CertificateLen;
                  dwSignerInfoLen :=  SignatureCntxt.SignerInfoLen;
                  if GetSignIssuerName(SignatureCntxt.pCertificate,
                    dwEncodedCertLen, SignInfo, dwSignInfoLen) then
                  begin
                    S := Trim(ExtractParam(pnNewLogin, SignInfo));
                    if Length(S)=0 then
                      S := Trim(ExtractParam(pnOldLogin, SignInfo));
                    SignLoginList := UpperCase(S);
                    FreeMem(SignInfo);
                  end
                  else
                    Mes := Mes+#13#10'�����N'+IntToStr(I);
                  if GetSignTime(SignatureCntxt.pSignerInfo, dwSignerInfoLen, ATime) then
                    SignTimeList := DateTimeToStr(ATime)
                  else
                    Mes := Mes+#13#10'����N'+IntToStr(I);
                              //addlocprot('4===  LOGIN='+SignLoginList);
                  TExtFreeMemory(GetExtPtr(fiFreeMemory))(SignatureCntxt.pCertificate, SignatureCntxt.CertificateLen);
                  TExtFreeMemory(GetExtPtr(fiFreeMemory))(SignatureCntxt.pSignerInfo, SignatureCntxt.SignerInfoLen);

                  if IndexOfWordInList(SignLoginList, List1)>=0 then
                    siComplete := siComplete or usDirector;
                  if IndexOfWordInList(SignLoginList, List2)>=0 then
                    siComplete := siComplete or usAccountant;
                  if IndexOfWordInList(SignLoginList, List3)>=0 then
                    siComplete := siComplete or usCourier;
                  if (VeiwSignListForm<>nil) or (smGetLoginInfo and Mode<>0) then  //�������� ����������
                  begin
                    if (siLoginNameProc<>nil) and (Integer(siLoginNameProc)<>0)
                      and GetLoginNameProc(siLoginNameProc)(SignLoginList,
                      K, S) then
                    begin
                      S := Trim(S);
                      //��������� ����������
                      if (Length(S)>0) and (smGetLoginInfo and Mode<>0) then
                        begin
                        with SignUserInfo do
                          begin
                          siSignNum := I;
                          Dec(I);
                          siLoginName[I] := SignLoginList;
                          siUserName[I] := S;
                          if usDirector and K>0 then
                            siUserStatus[I] := siUserStatus[I] or usDirector;
                          if usAccountant and K>0 then
                            siUserStatus[I] := siUserStatus[I] or usAccountant;
                          if usCourier and K>0 then
                            siUserStatus[I] := siUserStatus[I] or usCourier;
                          Inc(I);
                          end;
                        end;

                      if Length(S)>0 then
                        S := S+' ';
                    end
                    else begin
                      K := 0;
                      S := '';
                    end;
                    S := S+'{';
                    if usDirector and K>0 then
                      S := S+'�';
                    if usAccountant and K>0 then
                      S := S+'�';
                    if usCourier and K>0 then
                      S := S+'�';
                    S := S+'} '+SignLoginList+'  '+SignTimeList;
                    if VeiwSignListForm<>nil then
                      VeiwSignListForm.SignListBox.Items.AddObject(S, TObject(I));
                  end;
                end
                else
                  Mes := Mes+#13#10'��.�����N'+IntToStr(I);
                if Length(Mes)>0 then
                  Application.MessageBox(PChar('������ ����������� ������������ ������� '+Mes),
                    MesTitle, MB_OK or MB_ICONERROR);

                SignCntxt.SignaturesNum := dwSignatureNum;

                //messagebox(0, PChar(Mes+'|'+ControlDataPtr^.cdTagLogin), 'l', 0);
                //addlocprot('2=== '+inttostr(ADataLen)+' SL='+inttostr(SignLen)+'|');

                if (Length(SelfLogin)>0) and (SelfLogin=SignLoginList) then
                  siOwnIndex := I
                else begin
                  if smCheckLogin and Mode<>0 then
                  begin
                    if ControlDataPtr^.cdTagLogin=SignLoginList then
                      Err := 1
                    else
                      Err := 0;
                  end
                  else
                    Err := 1;
                end;
              end
              else
                siValid := svInvalid;
              Inc(siLen, J);
            end;
            if (siCount>0) and (siValid<>svInvalid) then
            begin
              siValid := svAllGood;
              Result := ceiDomenK;
            end;

            //     addlocprot('7===  DL='+inttostr(ADataLen)+' CL='+inttostr(ACommonLen));
            if VeiwSignListForm<>nil then
              with VeiwSignListForm do
              begin
                FSign := ASign;
                FData := AData;
                FDataLen := ADataLen;
                FFullCont := @FullContext;
                if usDirector and siComplete>0 then
                  StatusBar.Panels[0].Text := '�';
                if usAccountant and siComplete>0 then
                  StatusBar.Panels[1].Text := '�';
                if usCourier and siComplete>0 then
                  StatusBar.Panels[2].Text := '�';
                if smCanDelAnySign and Mode<>0 then
                  DelBitBtn.Visible := True;
                if (ShowModal=idOk) and DelBitBtn.Visible and
                  (SignListBox.Items.Count<siCount) then
                begin
                  K := 0;
                  siLen := siCount*4;
                  Err := siLen;
                  for I := 1 to siCount do
                  begin
                    J := PInteger(@ASign[I*4])^;
                    if SignListBox.Items.IndexOfObject(TObject(I))>=0 then
                    begin
                      Inc(K);
                      Move(ASign[4+siLen], ASign[4+Err], J);
                      PInteger(@ASign[K*4])^ := J;
                      Inc(Err, J);
                    end;
                    Inc(siLen, J);
                  end;
                  if (K>0) and (siCount>0) then
                    Move(ASign[4+siCount*4], ASign[4+K*4], Err-siCount*4);
                  siLen := Err-siCount*4+K*4;
                  PInteger(ASign)^ := K;
                  siCount := K;
                  siValid := svChanged;
                end;
                Free;
                Mode := Mode and not smShowInfo;
              end;
            //     addlocprot('8===  DL='+inttostr(ADataLen)+' CL='+inttostr(ACommonLen));
          end;
        end
        else begin
          if smShowInfo and Mode<>0 then
          begin
            Mes := '���������� ���� "�����-�" �� ���������';
            MesType := MB_ICONWARNING;
          end;
        end;
      end;
    end;
  end
  else begin
    if smShowInfo and Mode<>0 then
    begin
      Mes := '������� �����������';
      MesType := MB_ICONINFORMATION;
    end;
  end;
                //addlocprot('10===  Res='+inttostr(Result));
  if smShowInfo and Mode<>0 then
    Application.MessageBox(PChar(Mes), MesTitle, MB_OK or MesType);
  //addlocprot('  7=== '+inttostr(ADataLen)+' SL='+inttostr(SignLen)+'| ESP='
  //  +inttostr(GetESP));
  //messagebox(0, PChar(inttostr(GetESP)), 'end', 0);

  //��������� ����������
  if smGetLoginInfo and Mode<>0 then
    begin
    I := 0;
    with SignUserInfo do
      while I<siSignNum do
        begin
        if usDirector and siUserStatus[I]<>0 then
          SetVarior('DSign',siUserName[I]);
        if usAccountant and siUserStatus[I]<>0 then
          SetVarior('BSign',siUserName[I]);
        Inc(I);
        end;
    end;

end;

procedure EraseSign(AData: PChar; ADataLen, ACommonLen: Integer);
begin
  if ACommonLen>ADataLen then
    FillChar(AData[ADataLen], ACommonLen-ADataLen, #0);
end;

function AddSign(CEI: Integer; AData: PChar; ADataLen, ACommonLen: Integer;
  Mode: Integer; ControlDataPtr: PControlData; AllowLogins: string): Integer;
const
  MesTitle: PChar = '�������� �������';
var
  Err: Integer;
  SignCntxt: EXT_SIGN_CONTEXT;
  SignDescr: TSignDescr;
  LoginName: string;
  ppEncddCert: Pointer;                          //��������� ����������
  pEncddCertSize: Integer;                       //��������� ����������
  wc: TWndClass;
begin
  Result := 0;
  if IsCryptoEngineInited then
  begin
    with SignDescr do
    begin
      siCount := 0;
      siLen := 0;
      siOwnIndex := -1;
      siValid := svNone;
      siLoginNameProc := nil;
    end;
    if smOverwrite and Mode=0 then
    begin
      Err := CheckSign(AData, ADataLen, ACommonLen, Mode and smExtFormat, nil,
        @SignDescr, AllowLogins);

      //addlocprot('11===  Res='+inttostr(Err));

      if (Err>ceiNone) and (((Mode and smExtFormat)=0) or (SignDescr.siOwnIndex>=0)) then
      begin
        if (smShowInfo and Mode<>0) then
        begin
          if Mode and smExtFormat=0 then
            Application.MessageBox('������� ��� ����������', MesTitle, MB_OK or
              MB_ICONWARNING)
          else
            Application.MessageBox('���� ������� ��� ����������', MesTitle,
              MB_OK or MB_ICONWARNING)
        end
      end;
    end
    else begin
      Err := ceiNone;
      EraseSign(AData, ADataLen, ACommonLen);
    end;
    if (Err=ceiNone) or (Mode and smExtFormat<>0) and (Err<>ceiUnknown)
      and (SignDescr.siOwnIndex<0) then
    begin
      if CEI<=0 then
        CEI := MainCryptoEngineIndex;
      case CEI of
        ceiTcbGost:
          begin
            if ControlDataPtr<>nil then
            begin
              {if GetNode>0 then
              begin
                if SignSize>ACommonLen-ADataLen then
                begin
                  if smShowInfo and Mode<>0 then
                    Application.MessageBox('�� ������� ����� ��� �������',
                      MesTitle, MB_OK or MB_ICONWARNING)
                end
                else begin
                  Err := MakeSign(AData, ADataLen, ControlDataPtr^.cdTagNode, 1);
                  if Err>0 then
                    Result := Err
                  else
                    if smShowInfo and Mode<>0 then
                      Application.MessageBox(PChar('�������� ������� �� ������� '
                        +IntToStr(Err)), MesTitle, MB_OK or MB_ICONERROR);
                end;
              end
              else} begin
                if smShowInfo and Mode<>0 then
                  Application.MessageBox('���� "��� ����" �� ����������������',
                    MesTitle, MB_OK or MB_ICONWARNING);
              end;
            end
            else begin
              if smShowInfo and Mode<>0 then
                Application.MessageBox('�� ������� ������ ����������',
                  MesTitle, MB_OK or MB_ICONWARNING);
            end;
          end;
        ceiDomenK:
          begin
            Err := 0;                                                //��������� ����������
            if CryptoEngine2Inited then
            begin
              FillChar(SignCntxt, SizeOf(SignCntxt), #0);
              with SignCntxt do
              begin
                if smFile and Mode<>0 then              //��������
                begin                                 //��������
                  pData := PChar(AllowLogins);          //��������
                  DataType := EXT_FILE_DATA_FLAG;       //��������
                  DataLen := $FFFFFFFF;                 //��������
                end                                   //��������
                else begin                                 //��������
                  pData := AData;                       //��������
                  DataLen := ADataLen;                  //��������
                  Flags := {EXT_MULTIPLE_SIGN or }EXT_PKCS7_SIGN; //��������
                end;                                  //��������
                pSignaturesData := nil{ASign};
                SignaturesDataLen := {SignLen}0;
                pFunctionContext := nil;
              end;
              if smCertVerify and Mode<>0 then                                         //��������� ����������
              begin                                                                  //��������� ����������
                Err := TExtGetCurrentCertificate(GetExtPtr(fiGetCurrentCertificate))   //��������� ����������
                  (@FullContext, ppEncddCert, pEncddCertSize);                         //��������� ����������
                   //���� ��� ������ ����� ����������� ����� (������ � CD)
                if Err=e_FILE_CORRUPTED then                                           //��������� ����������
                  Err := e_NO_ERROR;                                                   //��������� ����������
                (*if Err<>e_NO_ERROR then                                                //��������� ����������
                begin                                                                //��������� ����������
                  Application.MessageBox(PChar('                         ! ! ! ! ! ! ! ! !  � � � � � � � �  ! ! ! ! ! ! ! ! !' //��������� ����������
                    +#13#10+#13+'         � � � � � � � � � �   � � � � � � � � �   � � �   � � � � � � �.'+#13#13#10+
                    '� � � � � � �   �   � � � � � � � �   � � � � � � � �   � � � � � � � � � � !'+#13#10+#13+    //��������� ����������
                    '� � � � � �   � � � � � � � � �   �   � � � � �   � � � � � � � � � � � � � �'+#13#13#10+
                    '         � � � � � � � � � �  � � � � � � � � � � � � � � � � � ! ! ! ! ! !'+#13#13#10+
                    '                            �.  2 1 2 - 5 2 - 2 5 ,  � � � � � �')     //��������� ����������
                    , MesTitle, MB_OK or MB_ICONWARNING);                              //��������� ����������
                  end;
                end;                                                               //��������� ����������*)
                if Err<>e_NO_ERROR then
                begin
                  if Err=e_CERT_IS_NOT_VALID then
                    MessageBox(ParentWnd, PChar(ErrToStr(Err)+#13#10'��������, ���� �������� ������ ����������� �����.'#13#10
                      +'�������� � ����� ����� �������� ������'),
                      MesTitle, MB_OK or MB_ICONWARNING)
                  else
                    MessageBox(ParentWnd, PChar('������ �������� �����������'#13#10+ErrToStr(Err)),
                      MesTitle, MB_OK or MB_ICONWARNING);
                end;
              end;
              if Err=e_NO_ERROR then
              begin
                Err := TExtSign(GetExtPtr(fiSign))(@FullContext, @SignCntxt, nil);
                if (smShowInfo and Mode<>0) and (Err<>e_NO_ERROR) then
                  Application.MessageBox(PChar('������ �������� �������'#13#10
                    +ErrToStr(Err)), MesTitle, MB_OK or MB_ICONWARNING);
              end;
              if (Err=e_NO_ERROR) and (SignCntxt.pSignaturesData<>nil)
                and (SignCntxt.SignaturesDataLen>0) then
              begin
                Result := SignCntxt.SignaturesDataLen;
                if Mode and smExtFormat=0 then {�������}
                begin
                  if Result>ACommonLen-ADataLen then
                  begin
                    Result := 0;
                    if smShowInfo and Mode<>0 then
                      Application.MessageBox('�� ������� ����� ��� �������',
                        MesTitle, MB_OK or MB_ICONWARNING)
                  end
                  else begin
                    Move(SignCntxt.pSignaturesData^, AData[ADataLen], Result);
                    if Result<SignLenVip1 then
                      Result := SignLenVip1
                    else
                      if Result<SignLenVip2 then
                        Result := SignLenVip2;
                  end;
                end
                else begin   {����. ������}
                  if Result>ACommonLen-(ADataLen+8+SignDescr.siLen) then
                  begin
                    if smShowInfo and Mode<>0 then
                      Application.MessageBox('�� ������� ����� ��� ��� ���� �������',
                        MesTitle, MB_OK or MB_ICONWARNING)
                  end
                  else begin
                    if (smOneSignInLevel and Mode<>0)
                      and (ControlDataPtr<>nil)
                      and GetLoginNameProc(ControlDataPtr)
                      (GetSelfLogin(''), Err, LoginName) then
                    begin
                      if ((Err and SignDescr.siComplete)<>0)
                        and ((Err or SignDescr.siComplete)=SignDescr.siComplete) then
                      begin
                        Result := 0;
                        if smShowInfo and Mode<>0 then
                          Application.MessageBox('������� ������� ����� ��� ����������',
                            MesTitle, MB_OK or MB_ICONWARNING)
                      end;
                    end;
                    if Result>0 then
                    begin
                      if SignDescr.siLen>0 then
                      begin
                        Move(AData[ADataLen+4+4*SignDescr.siCount], AData[ADataLen
                          +4+4*(SignDescr.siCount+1)], SignDescr.siLen-4*SignDescr.siCount);
                      end;
                      Inc(SignDescr.siCount);
                      Inc(SignDescr.siLen, 4);
                      Move(SignCntxt.pSignaturesData^, AData[ADataLen+4
                        +SignDescr.siLen], Result);
                      PInteger(@AData[ADataLen+4*SignDescr.siCount])^ := Result;
                      Inc(SignDescr.siLen, Result);
                    end;
                  end;
                  PInteger(@AData[ADataLen])^ := SignDescr.siCount;
                  Result := 4+SignDescr.siLen;
                end;
              end;
              if SignCntxt.pSignaturesData<>nil then
                TExtFreeMemory(GetExtPtr(fiFreeMemory))(SignCntxt.pSignaturesData,
                  SignCntxt.SignaturesDataLen);
            end
            else
              if smShowInfo and Mode<>0 then
                Application.MessageBox('���� "�����-�" �� ����������������', MesTitle,
                  MB_OK or MB_ICONWARNING);
          end;
        else
          if smShowInfo and Mode<>0 then
            Application.MessageBox('����������� ����', MesTitle, MB_OK or
              MB_ICONWARNING);
      end;
    end;
  end
  else begin
    if smShowInfo and Mode<>0 then
      Application.MessageBox('���� �� ����������������', MesTitle, MB_OK or
        MB_ICONWARNING);
  end;
end;

function GetAllCryptoInfo: string;
var
  Err: Integer;
  UserID: array[0..9] of Char;
  UserNick: array[0..91] of Char;
  UserName: array[0..71] of Char;
  S: string;
begin
  Result := '';
  {if IsCryptoEngineInited then
  begin}
    if CryptoEngine2Inited then
      {ceiDomenK:}
        begin
          Result := '��������. SDK "�����-�"'#13#10;
          Err := TExtGetOwnID(GetExtPtr(fiGetOwnID))(@FullContext, UserID);
          if Err=0 then
            Result := Result+'�������������: '+UserID
          else
            Result := Result+ErrToStr(Err);
          Result := Result+#13#10;
          Err := TExtGetUserAlias(GetExtPtr(fiGetUserAlias))(@FullContext,
            UserID, UserNick, UserName);
          if Err=0 then
          begin
            Result := Result+'���: '+UserNick+#13#10'���������: '+UserName;
            if not IsKeyNew then
              Result := Result+#13#10'(���������� �����)';
          end
          else
            Result := ErrToStr(Err);
        end;
      {else
        Result := '����������� ����';
    end;}
    {if GetNode>0 then}
    {case CryptoEngineIndex of
      ceiTcbGost:}
        (*begin
          S := '���. ���� 28147-89'#13#10'����: '+IntToStr({GetNode}0)
            +#13#10'����� ���������: '+IntToStr({GetOperNum}0);
          if GetMainCryptoEngineIndex=ceiTcbGost then
            Result := S + #13#10+ Result
          else
            Result := Result + #13#10 + S;
        end;*)
  {end
  else}
  if Length(Result)=0 then
    Result := '���� �� ����������������';
end;

function GenRandom(Buf: PChar; BufLen: DWord): Boolean;
begin
  Result := False;
  case GetMainCryptoEngineIndex of
    ceiTcbGost:
      begin
        if BufLen=32 then
        begin
          //GetRandomKey(Buf);
          //Result := True;
          Result := False;
        end;
      end;
    ceiDomenK:
      Result := TExtGenRandom(GetExtPtr(fiGenRandom))(@FullContext, Buf, BufLen)=0;
  end;
end;

function EncryptBlock(CEI: Integer; AData: PChar; ADataLen, ACommonLen: Integer;
  Mode: Integer; ControlDataPtr: PControlData): Integer;
const
  MesTitle: PChar = '����������';
var
  CryptData: EXT_CRYPT_CONTEXT;
  I, J: Integer;
  Receivers: PChar;
  S: string;
  //UserID: array[0..9] of Char;
begin
  Result := 0;
  if IsCryptoEngineInited then
  begin
    if ControlDataPtr<>nil then
    begin
      if CEI<=0 then
        CEI := MainCryptoEngineIndex;
      case CEI of
        ceiTcbGost:
          begin
            if ControlDataPtr<>nil then
            begin
              if SignSize>ACommonLen-ADataLen then
              begin
                if smShowInfo and Mode<>0 then
                  Application.MessageBox('�� ������� ����� ��� ����',
                    MesTitle, MB_OK or MB_ICONWARNING)
              end
              else begin
                I := 0;//MakeSign(AData, ADataLen, ControlDataPtr^.cdTagNode, 0);
                if I>0 then
                  Result := ADataLen+I
                else
                  if smShowInfo and Mode<>0 then
                    Application.MessageBox(PChar('���������� �� ������� '
                      +IntToStr(I)), MesTitle, MB_OK or MB_ICONERROR);
              end;
            end
            else begin
              if smShowInfo and Mode<>0 then
                Application.MessageBox('�� ������� ������ ����������',
                  MesTitle, MB_OK or MB_ICONWARNING);
            end;
          end;
        ceiDomenK:
          if CryptoEngine2Inited then
          begin
            Receivers := AllocMem(10);
            try
              if ControlDataPtr^.cdCheckSelf then
              begin
                I := TExtGetOwnID(GetExtPtr(fiGetOwnID))(@FullContext, Receivers);
                if I<>0 then
                  Receivers := #0;
              end
              else
                Receivers := #0;
              S := GetUserIdByName(@FullContext, ControlDataPtr^.cdTagLogin);
              I := StrLen(Receivers)+1;
              J := I+Length(S)+1;
              ReallocMem(Receivers, J+1);
              StrPCopy(@Receivers[I], S);
              Receivers[J] := #0;
              I := StrLen(Receivers);
              if I>0 then
              begin
                FillChar(CryptData, SizeOf(CryptData), #0);
                with CryptData do
                begin
                  pInputData := AData;
                  InputDataLen := ADataLen;
                  pOutputData := nil;
                  pReceivers := Receivers;
                end;
                I := TExtEncrypt(GetExtPtr(fiEncrypt))(@FullContext, @CryptData, nil);
                //messagebox(0, PChar('e!!!'+inttostr(ADataLen)+' R='
                //  +Receivers+' err='+inttostr(err)), '1', 0);
                try
                  if I=0 then
                  begin
                    if CryptData.OutputDataLen<=ACommonLen then
                    begin
                      Move(CryptData.pOutputData^, AData^, CryptData.OutputDataLen);
                      Result := CryptData.OutputDataLen;
                    end
                    else
                      if smShowInfo and Mode<>0 then
                        Application.MessageBox(PChar(
                          '��������������� ���� ��� ��� ���������� ����� '
                          +IntToStr(CryptData.OutputDataLen)+'>'+IntToStr(ACommonLen)),
                          MesTitle, MB_OK or MB_ICONWARNING);
                  end
                  else
                    if smShowInfo and Mode<>0 then
                      Application.MessageBox(PChar('�� ������� ����������� ����'#13#10
                        +ErrToStr(I)), MesTitle, MB_OK or MB_ICONWARNING);
                finally
                  if CryptData.pOutputData<>nil then
                    TExtFreeMemory(GetExtPtr(fiFreeMemory))(CryptData.pOutputData, CryptData.OutputDataLen);
                end;
              end
              else
                if smShowInfo and Mode<>0 then
                  Application.MessageBox(PChar('���������� �� ���������� '
                    +ControlDataPtr^.cdTagLogin), MesTitle, MB_OK or MB_ICONWARNING);
            finally
              FreeMem(Receivers);
            end;
          end
          else
            if smShowInfo and Mode<>0 then
              Application.MessageBox('���� "�����-�" �� ����������������',
                MesTitle, MB_OK or MB_ICONWARNING);
        else
          if smShowInfo and Mode<>0 then
            Application.MessageBox('����������� ����', MesTitle, MB_OK or
              MB_ICONWARNING);
      end;
    end
    else
      if smShowInfo and Mode<>0 then
        Application.MessageBox('������ ���������� �� �������', MesTitle, MB_OK or
          MB_ICONWARNING);
  end;
end;

function DecryptBlock(AData: PChar; ADataLen, ACommonLen: Integer;
  Mode: Integer; ControlDataPtr: PControlData): Integer;
const
  MesTitle: PChar = '������������';
var
  CryptData: EXT_CRYPT_CONTEXT;
  Err, I: Integer;
  FromNode, Oper, ToNode: word;
begin
  Result := -1;
  if IsCryptoEngineInited then
  begin
    I := ADataLen-SignSize;
    if I>=0 then
    begin
      if (AData[I]=#$1A) and ((AData[ADataLen-1]=#$19)
        or (AData[ADataLen-1]=#$1A)) and (PInteger(@AData[I+1])^=I)
      then
        I := 1
      else
        I := 0;
    end;
    {case MainCryptoEngineIndex of
      ceiTcbGost:}
    if I>0 then
    begin
      if ControlDataPtr<>nil then
      begin
        {if GetNode>0 then
        begin
          FromNode := 0;
          Oper := 0;
          ToNode := 0;
          Err := TestSign(AData, ADataLen, FromNode, Oper, ToNode);
          with ControlDataPtr^ do
          begin
            I := 1;
            if (Err=$10) or (Err=$110) then
            begin
              if not cdCheckSelf and ((cdTagNode=0) or (cdTagNode=FromNode)) then
                I := 0
              else
                I := 2;
            end
            else
              if (Err=$5) or (Err=$4) then
              begin
                if cdCheckSelf and ((cdTagNode=0) or (cdTagNode=ToNode)) then
                  I := 0
                else
                  I := 3
              end;
            if I=0 then
              Result := ADataLen-SignSize
            else
              if smShowInfo and Mode<>0 then
              begin
                case I of
                  2:
                    Application.MessageBox(PChar('���� ����������� ���������� N='
                      +IntToStr(FromNode)+' (Err='+IntToStr(Err)+')'), MesTitle,
                      MB_OK or MB_ICONWARNING);
                  3:
                    Application.MessageBox(PChar('���� ���������� ���������� N='
                      +IntToStr(ToNode)+' (Err='+IntToStr(Err)+')'), MesTitle,
                      MB_OK or MB_ICONWARNING);
                  else
                    Application.MessageBox(PChar('������ ������������� '
                      +IntToStr(Err)), MesTitle, MB_OK or MB_ICONWARNING);
                end;
              end;
          end;
        end
        else} begin
          if smShowInfo and Mode<>0 then
            Application.MessageBox('���� "��� ����" �� ����������������',
              MesTitle, MB_OK or MB_ICONWARNING);
        end;
      end
      else begin
        if smShowInfo and Mode<>0 then
          Application.MessageBox('�� ������� ������ ����������',
            MesTitle, MB_OK or MB_ICONWARNING);
      end;
    end
    else begin
      if CryptoEngine2Inited then
      begin
        FillChar(CryptData, SizeOf(CryptData), #0);
        with CryptData do
        begin
          pInputData := AData;
          InputDataLen := ADataLen;
          pOutputData := nil;
        end;
        Err := TExtDecrypt(GetExtPtr(fiDecrypt))(@FullContext, @CryptData, nil);
        //messagebox(0, PChar('d!!!'+inttostr(ADataLen)+' R='
        //+' err='+inttostr(err)), '1', 0);
        try
          if Err=0 then
          begin
            if CryptData.OutputDataLen<=ACommonLen then
            begin
              Move(CryptData.pOutputData^, AData^, CryptData.OutputDataLen);
              Result := CryptData.OutputDataLen;
            end
            else
              if smShowInfo and Mode<>0 then
                Application.MessageBox('���� ��� ��� ���������� ���������',
                  MesTitle, MB_OK or MB_ICONWARNING);
          end
          else
            if smShowInfo and Mode<>0 then
              Application.MessageBox(PChar('�� ������� ������������ ����'#13#10
                +ErrToStr(Err)), MesTitle, MB_OK or MB_ICONWARNING);
        finally
          if CryptData.pOutputData<>nil then
            TExtFreeMemory(GetExtPtr(fiFreeMemory))(CryptData.pOutputData, CryptData.OutputDataLen);
        end;
      end
      else
        if smShowInfo and Mode<>0 then
          Application.MessageBox('���� "�����-�" �� ����������������', MesTitle,
            MB_OK or MB_ICONWARNING);
    end;
  end;
end;

function IsKeyNew: Boolean;
var
  Err: Integer;
  UserID: array[0..9] of Char;
  UserNick: array[0..91] of Char;
  UserName: array[0..71] of Char;
begin
  Result := True;
  if CryptoEngine2Inited then
  begin
    Err := TExtGetOwnID(GetExtPtr(fiGetOwnID))(@FullContext, UserID);
    if Err=0 then
    begin
      Err := TExtGetUserAlias(GetExtPtr(fiGetUserAlias))(@FullContext, UserID, UserNick, UserName);
      if Err=0 then
      begin
        if StrLComp(UserID, UserNick, SizeOf(UserID))=0 then
          Result := False;
      end;
    end;
  end;
end;

function GetCryptoIdent: string;
var
  Err: Integer;
  UserID: array[0..9] of Char;
begin
  Result := '';
  if CryptoEngine2Inited then
  begin
    Err := TExtGetOwnID(GetExtPtr(fiGetOwnID))(@FullContext, UserID);
    if Err=0 then
      Result := UserID;
  end;
end;

//��������� ����������
{function AddFileSign(FileAndPath:PChar; FileBasePtr: PFileBasePtr): Integer;
const
  MesTitle: PChar = '�������� ������� �����';
var
  SignCntxt: EXT_SIGN_CONTEXT;
  Err: Integer;
begin
  with SignCntxt do
    begin
    pData := FileAndPath;
    DataLen := $FFFFFFFF;
    DataType := EXT_FILE_DATA_FLAG;
    Flags := 0;
    pFunctionContext := nil;
    pSignaturesData := nil;
    SignaturesDataLen := 0;
    end;
  Err := TExtSign(GetExtPtr(fiSign))(@FullContext, @SignCntxt, nil);
  if (Err=e_NO_ERROR) and (SignCntxt.pSignaturesData<>nil)
    and (SignCntxt.SignaturesDataLen>0) then
    begin
    FileBasePtr.ECPLen := SignCntxt.SignaturesDataLen;
    FileBasePtr.ECP := SignCntxt.pSignaturesData;
    Result := 0;
    end
  else
    Result := Err;
end;

function CheckFileSign(FileAndPath:PChar;FileBasePtr: PFileBasePtr;
  Mode: Integer;ControlDataPtr: PControlData): Integer;
const
  MesTitle:PChar = '�������� ������� �����';
var
  SignCntxt: EXT_SIGN_CONTEXT;
  SignatureCntxt: EXT_SIGNATURE_CONTEXT;

  ComSignLen, Err, MesType, I, J, K: Integer;
  ASign: PChar;
  FromNode, Oper, ToNode: word;
  Mes, SignLoginList, SignTimeList, S, SelfLogin, List1, List2, List3: string;
  dwSignatureNum, dwEncodedCertLen, dwSignerInfoLen, dwSignInfoLen: DWord;
  SignInfo: PChar;
  ATime: TDateTime;
  VeiwSignListForm: TVeiwSignListForm;

begin
  if (ControlDataPtr=nil) and ((ComSignLen=SignLenVip1)
    or (ComSignLen=SignLenVip2)) then
    begin
      Result := ceiDomenK;
      if smShowInfo and Mode<>0 then
        begin
        Mes := '������� ����������';
        MesType := MB_ICONINFORMATION;
        end;
      end
      else begin
        if IsItscLibLoaded then
            begin
                with SignCntxt do
                begin
                  pData := FileAndPath;
                  DataLen := $FFFFFFFF;
                  DataType := EXT_FILE_DATA_FLAG;
                  pSignaturesData := FileBasePtr.ECP;
                  SignaturesDataLen := FileBasePtr.ECPLen;
                  SignaturesNum := nil;
                  pSignaturesResults := nil;
                  ResultsSize := nil;
                  pControlInfo := nil;
                  ControlInfoSize := nil;
                  pFunctionContext := nil;
                end;
                Err := TExtVerifySign(GetExtPtr(fiVerifySign))(@FullContext, @SignCntxt, nil);
                if (Err=e_NO_ERROR) then
                begin
                  if (ControlDataPtr=nil) then
                    begin
                    Result := ceiDomenK;
                    if smShowInfo and Mode<>0 then
                      begin
                      Mes := '������� ����������';
                      MesType := MB_ICONINFORMATION;
                      end;
                    end
                  else begin
                    dwSignatureNum := SignCntxt.SignaturesNum;
                    SignLoginList := '';
                    SignTimeList := '';
                    Mes := '';
                    if (smShowInfo and Mode<>0) or (smCheckLogin and Mode<>0) then
                    begin
                      for I := 0 to dwSignatureNum-1 do
                      begin
                        FillChar(SignatureCntxt, SizeOf(SignatureCntxt), #0);
                        with SignatureCntxt do
                        begin
                          pCertificate := nil;
                          CertificateLen := 0;
                          pSignerInfo := nil;
                          SignerInfoLen := 0;
                        end;
                        SignCntxt.SignaturesNum := I;
                        Err := TExtGetSignInfo(GetExtPtr(fiGetSignInfo))(@FullContext,
                          @SignCntxt, @SignatureCntxt);
                        if Err=0 then
                        begin
                          dwEncodedCertLen := SignatureCntxt.CertificateLen;
                          dwSignerInfoLen :=  SignatureCntxt.SignerInfoLen;
                          if GetSignIssuerName(SignatureCntxt.pCertificate,
                            dwEncodedCertLen, SignInfo, dwSignInfoLen) then
                          begin
                            S := Trim(ExtractParam(pnNewLogin, SignInfo));
                            if Length(S)=0 then
                              S := Trim(ExtractParam(pnOldLogin, SignInfo));
                            AddWordInList(UpperCase(S), SignLoginList);
                            FreeMem(SignInfo);
                          end
                          else
                            Mes := Mes+#13#10'�����N'+IntToStr(I);
                          if GetSignTime(SignatureCntxt.pSignerInfo, dwSignerInfoLen, ATime) then
                          begin
                            AddWordInList(DateTimeToStr(ATime), SignTimeList);
                          end
                          else
                            Mes := Mes+#13#10'����N'+IntToStr(I);
                          TExtFreeMemory(GetExtPtr(fiFreeMemory))(SignatureCntxt.pCertificate, SignatureCntxt.CertificateLen);
                          TExtFreeMemory(GetExtPtr(fiFreeMemory))(SignatureCntxt.pSignerInfo, SignatureCntxt.SignerInfoLen);
                        end
                        else
                          Mes := Mes+#13#10'��.�����N'+IntToStr(I);
                      end;
                      if Length(Mes)>0 then
                        Application.MessageBox(PChar('������ ����������� ������������ ������� '+Mes),
                        MesTitle, MB_OK or MB_ICONERROR);
                      SignCntxt.SignaturesNum := dwSignatureNum;
                      Mes := GetSelfLogin('');
                      Err := 0;
                      if (Length(Mes)>0) and (IndexOfWordInList(Mes,
                        SignLoginList)>=0) then
                        Err := -1;
                      if Err=0 then
                      begin
                        //Err := WhichLoginExistInList(ControlDataPtr^.cdLoginList, SignLoginList);
                        if smCheckLogin and Mode<>0 then
                        begin
                          Err := IndexOfWordInList(ControlDataPtr^.cdTagLogin, SignLoginList);
                          if Err>=0 then
                            Inc(Err)
                          else
                            Err := 0;
                        end
                        else
                          Err := 1;
                      end;
                    end
                    else
                      Err := 1;
                    //addlocprot('3=== '+inttostr(ADataLen)+' SL='+inttostr(SignLen)+'|');
                    if (Err<>0) and ((smThoroughly and Mode=0) or CryptoEngine2Inited) then
                      Result := ceiDomenK;
                    if smShowInfo and Mode<>0 then
                    begin
                      if (smDefShowInfo and Mode<>0) and CryptoEngine2Inited then
                      begin
                        Err := TExtViewSignResult(GetExtPtr(fiViewSignResult))(@FullContext, @SignCntxt, '�������� �������');
                        if Err<>0 then
                        begin
                          Mes := ErrToStr(Err);
                          Application.MessageBox(PChar(Mes), MesTitle, MB_OK or MB_ICONERROR);
                        end;
                      end
                      else begin
                        if Result=ceiDomenK then
                        begin
                          if Err<0 then
                            Mes := '����������� �������'
                          else
                            Mes := '������� ���������'
                        end
                        else begin
                          if CryptoEngine2Inited then
                            Mes := '������� �����, �� �����������'
                          else
                            Mes := '������� �����, ������������ �� ����������';
                        end;
                        if CryptoEngine2Inited then
                          ShowSignConclusion(SignLoginList, SignTimeList, Mes,
                          ComSignLen, @FullContext, @SignCntxt)
                        else
                          ShowSignConclusion(SignLoginList, SignTimeList, Mes,
                          ComSignLen, nil, nil);
                      end;
                      Mode := Mode and not smShowInfo;
                    end;
                    //addlocprot('4=== '+inttostr(ADataLen)+' SL='+inttostr(SignLen)+'|');
                  end;
                end
                else begin
                  if smShowInfo and Mode<>0 then
                  begin
                    Mes := '������ �������'#13#10+ErrToStr(Err);
                    MesType := MB_ICONWARNING;
                  end;
                end;
                //addlocprot('56=== '+inttostr(ADataLen)+' SL='+inttostr(SignLen)+'|');
                with SignCntxt do
                begin
                  if pControlInfo<>nil then
                    TExtFreeMemory(GetExtPtr(fiFreeMemory))(pControlInfo, ControlInfoSize);
                  if pSignaturesResults<>nil then
                    TExtFreeMemory(GetExtPtr(fiFreeMemory))(pSignaturesResults, ResultsSize);
                end;
            end
            else begin
              if smShowInfo and Mode<>0 then
              begin
                Mes := '���������� ���� "�����-�" �� ���������';
                MesType := MB_ICONWARNING;
              end;
            end;
          end;
      end;
    end;
end;
}
end.
