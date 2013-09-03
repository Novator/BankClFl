unit CommCons;

interface

uses Windows, Classes, SysUtils;

const
  SignSize = 92;      // ������ ������ �������
  MaxSignSize = 2200; //������������ ������ ����� �������

  brtBill    = 0;
  brtReturn  = 1;
  brtKart    = 2;

  drMaxVar = 49152;

  arMaxVar = 98;
  brMaxOperName = 64;
  brMaxText = 32;
  brMaxRet = 70;
  brMaxKart = 70;
  clMaxVar = 139;             
  OperNameLen = 24;

  SumStrLen = 17;
  DateStrLen = 10;
  TimeStrLen = 5;
  erMaxVar   = 32100;

  {DocStates: array[0..9] of string = (
    '','��������','��. ����.','�������','�������','��������',
    '������������','������','���������','���������');}

  (*adsNone = 0;         {0}
  adsSigned = 1;       {1(o) 2(i)}
  adsSignError = 2;
  adsReturned = 3;
  adsSend = 4;
  adsBilled = 5;
  adsSndPost = 6;
  adsSndRcv = 7;       {2}
  adsSndSent = 8;
  adsKarted = 9;*)

type
  PInteger = ^Integer;
  PWord = ^Word;
  PBoolean = ^Boolean;
  PDouble = ^Double;
  PLong = ^Longint;

{ ��������� ��������� }
const
  dsSndType    = $03;
  dsDoneType   = $0C;
  dsAnsType    = $30;
  dsReSndType  = $C0;

  dsSndEmpty   = $00;
  dsSndPost    = $01;
  dsSndSent    = $02;
  dsSndRcv     = $03;

  dsDoneEmpty  = $00;
  dsDoneReserv = $04;
  dsDoneDone   = $08;
  dsDoneReturn = $0C;

  dsAnsEmpty   = $00;
  dsAnsPost    = $10;
  dsAnsSent    = $20;
  dsAnsRcv     = $30;

  dsReSndEmpty = $00;
  dsReSndPost  = $40;
  dsReSndSent  = $80;
  dsReSndRcv   = $C0;

  dsRsAfter    = $400;                                   //��������� ����������
  dsExtended   = $800;
  dsEncrypted  = $1000;
  dsInputDoc   = $2000;
  dsSignError  = $4000;
  dsExport     = $8000;

{ ��� ���� }
const
  btInDoc      =  0;
  btOutDoc     =  1;
  btArc        =  2;

{ ��������� ����� }
const
  asType       =   3;

  asPassive    =   0;
  asActive     =   1;
  asActPas     =   2;

  asAutoDt     =   4;
  asAutoCr     =   8;
  asControlDt  = $10;
  asControlCr  = $20;

  asSndType    = $C000;

  asSndEmpty   = $0000;
  asSndMark    = $4000;
  asSndSent    = $8000;
  asSndRcv     = $C000;

const    {���� ���������� ��������� ������}
  psOutDoc1    =  1;
  psAccept     =  2;
  psDouble1    =  3;
  psInDoc1     =  4;
  psAnsBill    =  5;
  psInBill     =  6;
  psAccState   =  7;
  psEMail1     =  8;
  psReturn     = 11;

  psDelBank     = 12;  {�������� �����}
  psAddBank     = 13;  {����������/���������� �����}
  psReplaceBank = 14;  {������ �����}
  psFile        = 15;  {����}

  psSndBill     = 16;

  psOutDoc2    =  17;
  psDouble2    =  18;
  psInDoc2     =  19;
  psEMail2     =  20;
  psOutDoc3    =  21;
  psSFile      =  22;           //��������� ����������


type
  TPostFileType = (pftSimple, pftModule);

const
  MaxPackSize = 55000-41;
  PackByteSC  = $2;
  PackByteSD  = $3;
  PackByteSE  = $4;
  PackWordS   = $0FAC;
  {erMaxVar   = 32100;}

type
  TCorrName = packed array[0..8] of Char;
  TAbonLogin = packed array[0..8] of Char;

  PSndPack = ^TSndPack;
  TSndPack = packed record
    spNameR:   TAbonLogin;               {0, 9      k0         p1.1}
    spNameS:   TAbonLogin;               {9, 9                       p2.1}
    spByteS:   byte;                     {18, 1}
    spLength:  word;                     {19, 2}
    spWordS:   word;                     {21, 2}
    spNum:     longint;                  {23, 4     k1.2}
    spIder:    longint;                  {27, 4     k2        p0}
    spFlSnd:   char;                     {31, 1     k1.1  k3}
    spDateS:   word;                     {32, 2}
    spTimeS:   word;                     {34, 2}
    spFlRcv:   Char;                     {36, 1                p1.2  p2.2}
    spDateR:   word;                     {37, 2}
    spTimeR:   word;                     {39, 2}
    spText:    array[0..MaxPackSize-1] of char; {41, ..}
  end;

  PRcvPack = ^TRcvPack;
  TRcvPack = packed record
    rpNameR:   TAbonLogin;                       {0, 9}
    rpNameS:   TAbonLogin;                       {9, 9}   {k0.1  k1  p1}
    rpByteS:   byte;                             {18, 1}  {k2.1}
    rpLength:  word;                             {19, 2}  {k2.2}
    rpWordS:   word;                             {21, 2}  {k2.3}
    rpNum:     longint;                          {23, 4}  {k2.4}
    rpIder:    longint;                          {27, 4}  {k0.2}
    rpDateS:   word;                             {31, 2}  {k3.1}
    rpTimeS:   word;                             {33, 2}  {k3.2}
    rpDateR:   word;                             {35, 2}  {k4.1}
    rpTimeR:   word;                             {37, 2}  {k4.2}
    rpText:    array[0..MaxPackSize-1] of char;  {39, xxxx}
  end;

  TAccount = packed array[0..19] of char;
  TInn = packed array[0..15] of char;

  TVarDoc = array[0..drMaxVar-1] of Char;

  PDocRec = ^TDocRec;
  TDocRec = packed record        { ���-� }
    drDate:   word;       { ���� ���-�� }                         {  0 }
    drSum:    comp;       { ����� ������� � �������� }            {  2 }
    drSrok:   word;       { ���� ������� }                        { 10 }
    drType:   byte;       { ��� �������� }                        { 12 }
    drIsp:    byte;       { ������ ���������� }                   { 13 }
    drOcher:  byte;       { ����������� ������� }                 { 14 }
    drVar:   TVarDoc; { ���������� ����� }   { 15 }
  end;                                                            { 15 }

  (*PPayRec = ^TPayRec;                   {��������}
  TPayRec = packed record     { ������ � ���-�� � �� }
    dbIdHere: longint;    { ���� � ����� }                        {  0 0k}
    dbIdKorr: longint;    { ���� � ����� }                        {  4 1k}
    dbIdIn:   longint;    { ���� �� �������� }                    {  8 2k}
    dbIdOut:  longint;    { ���� � ��������� }                    { 12 3k}
    dbIdArc:  longint;    { ���� � ������ }                       { 16 4k}
    dbIdDel:  longint;    { ���� � ��������� }                    { 20 5k}
    dbVersion:longint;    { ����� ������ }                        { 24 }
    dbState:  word;       { ��������� ���-�� }                    { 28 }
    dbDateS:  word;       { ���� �������� }                       { 30 }
    dbTimeS:  word;       { ����� �������� }                      { 32 }
    dbDateR:  word;       { ���� ��������� ������ }               { 34 }
    dbTimeR:  word;       { ����� ��������� ������ }              { 36 }
    dbDateP:  word;       { ���� ��������� ������ }               { 38 }
    dbTimeP:  word;       { ����� ��������� ������ }              { 40 }
    dbDocLen: word;       { ����� ��������� }                     { 42 }
    dbDoc:    TDocRec;    { �������� � ��. �������� � ������� }   { 44 }
  end; *)

  TSity = packed array[0..24] of char;
  TSityType = packed array[0..4] of char;

  PNpRec = ^TNpRec;
  TNpRec = packed record                                {���������� ������ ������}
    npIder:   longint;                  {���� ���.������}           {0      0,4}
    npName:   TSity;                    {������������ ���.������}   {1.0    4,25}
    npType:   TSityType;                {������������}              {1.1    29,5}
  end;                                                              {       =34}

  TBankTypeOld = packed array[0..3] of Char;
  TBankNameOld = packed array[0..39] of Char;
  TBankNameNew = packed array[0..44] of Char;

  PBankOldRec = ^TBankOldRec;
  TBankOldRec = packed record                       {���������� ����������}
    brCod:    longint;                  {���}                 {k0}  {0,4}
    brKs:     TAccount;                 {�/�}                       {4,20}
    brNpIder: longint;                  {���� ���.������}     {k1}  {24,4}
    brType:   TBankTypeOld;        {������������}                   {28,4}
    brName:   TBankNameOld;        {������������ �����}       {k2}  {32,40}
  end;                                                              {=72}

  PBankNewRec = ^TBankNewRec;
  TBankNewRec = packed record                       {���������� ����������}
    brCod:    longint;                  {���}                 {k0}  {0,4}
    brKs:     TAccount;                 {�/�}                       {4,20}
    brNpIder: longint;                  {���� ���.������}     {k1}  {24,4}
    brName:   TBankNameNew;             {������������ �����}  {k2}  {28,45}
  end;                                                              {=73}

  PBankFullOldRec = ^TBankFullOldRec;
  TBankFullOldRec = packed record                   {���������� ����������}
    brCod:    longint;                  {���}
    brKs:     TAccount;
    brName:   array[0..SizeOf(TBankTypeOld)+SizeOf(TBankNameOld)
      +SizeOf(TSityType)+SizeOf(TSity)+5] of Char;   {������ ������������ �����}
  end;

  PBankFullNewRec = ^TBankFullNewRec;
  TBankFullNewRec = packed record                   {���������� ����������}
    brCod:    longint;                  {���}
    brKs:     TAccount;
    brName:   array[0..SizeOf(TBankNameNew)
      +SizeOf(TSityType)+SizeOf(TSity)+5] of Char;   {������ ������������ �����}
  end;

  TClientName = array[0..clMaxVar-1] of Char;

  POldClientRec = ^TOldClientRec;             {������}
  TOldClientRec = packed record
    clAccC:  TAccount;                          {0,20     k0.1}
    clCodeB: LongInt;                           {20,4     k0.0}
    clInn:   TInn;                              {24,16    k1}
    clNameC: TClientName;       {40, 139  k2}
  end;                                             {=179}

  PNewClientRec = ^TNewClientRec;             {������}
  TNewClientRec = packed record
    clAccC:  TAccount;                          {0,20     k0.1}
    clCodeB: LongInt;                           {20,4     k0.0}
    clInn:   TInn;                              {24,16    k1}
    clKpp:   TInn;                              {40,16      }
    clNameC: TClientName;       {56, 139  k2}
  end;                                             {=195}

  POpRec = ^TOpRec;                    {��������}
  TOpRec = packed record
    brIder:   longint;              { ���� �������� }         {  0  0k }
    brDocId:  longint;              { ���� ��������� }        {  4  1k }
    brDate:   word;                 { ���� �������� }         {  8  2k }
    brVersion:longint;              { ����� ������ }          { 10 }
    brState:  byte;                 { ��������� }             { 14 }
    brDel:    byte;                 { ���������/������� }     { 15 }
    case brPrizn: byte of           { ��������/������� }      { 16 }
    brtBill: (
      brType:   byte;                 { ��� �������� }        { 17 }
      brNumber: longint;              { ����� �������� }      { 18 }
      brAccD:   TAccount;             { ���������� ���� }     { 22 }
      brAccC:   TAccount;             { ����������� ���� }    { 42 }
      brSum:    comp;                 { ����� }               { 62 }
      brText:   array[0..brMaxText+brMaxOperName-1] of char; { ���������� } { 70 }
    );
    brtReturn: (
      brRet:   array[0..brMaxRet+brMaxOperName-1] of char;                  { 17 }
    );
    brtKart: (
      {brSumK:  comp;}
      brKart:   array[0..brMaxKart+brMaxOperName-1] of char;                  { 17 }
    );
  end;                                                        { 17 }

  TKeeperName = array[0..arMaxVar-1] of Char;

  PAccRec = ^TAccRec;             {��������� �����}
  TAccRec = packed record
    arIder:    integer;   { ���� ����� }                {0, 4  k0}
    arAccount:  TAccount;  { ����� �����}               {4, 20 k1}
    arCorr:    integer;   { ������������� }             {24, 4 k2}
    arVersion: integer;   { ����� ������ }              {28, 4}
    arDateO:   word;      { ���� �������� }             {32, 2}
    arDateC:   word;      { ���� �������� }             {34, 2}
    arOpts:    word;      { �������� }                  {36, 2}
    arSumA:    Int64;      { ������� �� ����� }         {38, 8}
    arSumS:    Int64;      { ��������� ������� }        {46, 8}
    arName:    TKeeperName;                 {54, 98}
  end;                                                   {=152}

  PAccArcRec = ^TAccArcRec;       {��������� ����� �� �������� ����}
  TAccArcRec = packed record
    aaIder: Longint;   { ���� ����� }                {  0, 4   k0.2  k1.1}
    aaDate: Word;      { ���� }                      {  4, 2   k0.1  k1.2}
    aaSum:  Comp;      { ����� �� ����� }            {  6, 8 }
  end;                                                  { =14 }

  PFilePieceRec = ^TFilePieceRec;       {�������� �����}
  TFilePieceRec = packed record
    fpIndex: Word;      { ������ ��������� }          {  2, 2   k0.1}
    fpIdent: Integer;   { ���� ����� }                {  0, 2   k0.2}
    fpVar: array[0..MaxPackSize-1-6] of Char;  { ������ ������ }
  end;


  TModuleName = packed array[0..7] of Char;

  PAccColRec = ^TAccColRec;
  TAccColRec = packed record
    acNumber: TAccount;
    acIder:   longint;
    acFDate:   word;
    acTDate:   word;
    acSumma:  comp;
    acSumma2: comp;
  end;

const
  mkAutoExec    = 0;
  //mkSkzi1       = 1;
  //mkSkzi2       = 2;
  mkPayDialog   = 5;
  mkUpdate      = 100;
  mkDeleted     = 255;

type
  PModuleRec = ^TModuleRec;
  TModuleRec = packed record
    mrKind: Byte;              {���              k0.1}
    mrIder: Integer;           {�������������    k0.2}
    mrLevel: Byte;             {������� ����������}
    mrName: TModuleName;       {��� �����}
    mrSign: array[0..SignSize-1] of Char;
  end;

  //TUserName = packed array[0..127] of Char;

  (*POldUserRec = ^TOldUserRec;               {������������}
  TOldUserRec = packed record
    urNumber: Integer;         {�����}                 {0, 4  k0}
    urLevel: Byte;             {������� ����������}    {4, 1}
    urFirmNumber: Integer;     {����� �� ���������}    {5, 4}
    urName: TUserName;         {��� �����}             {9, 64}
  end;                                                 {=73}*)

  //TUserPass = packed array[0..11] of Char;

  (*POld2UserRec = ^TOld2UserRec;               {������������}
  TOldUserRec = packed record
    urNumber: Integer;         {�����}                 {0, 4  k0}
    urUserPass: TUserPass;     {������}                {4, 12}
    urLevel: Byte;             {������� ����������}    {16, 1}
    urFirmNumber: Integer;     {����� �� ���������}    {17, 4}
    urName: TUserName;         {��� �����}             {21, 64}
  end;                                                 {=85}*)

  TUserLogin = packed array[0..11] of Char;
  TUserInfo = packed array[0..1023] of Char;

const
  usDirector    = $01;
  usAccountant  = $02;
  usCourier     = $04;

type  
  PUserRec = ^TUserRec;               {������������}
  TUserRec = packed record
    urNumber: Integer;         {�����}                 {0, 4  k0}
    urLogin: TUserLogin;       {�����}                 {4, 12}
    urLevel: Byte;             {������� ����������}    {16, 1}
    urFirmNumber: Integer;     {����� �� ���������}    {17, 4}
    urStatus: Word;            {����� �� ���������}    {21, 2}
    urInfo: TUserInfo;         {��� � ���� �����}      {23, 1024}
  end;                                                 {=1047}

  PSanctionRec = ^TSanctionRec;      {�������}
  TSanctionRec = packed record
    snUserNumber: Integer;        {0, 4   k0.1}
    snSancNumber: Integer;        {8, 4   k0.2}
  end;                            {=12}

  PEMailRec = ^TEMailRec;
  TEMailRec = packed record       {������ ������}
    erIder:   longint;              { ���� ����� }               {  0,4  k0}
    erIdKorr: longint;              { ���� � �������������� }    {  4,4  k1.2}
    erSender: longint;              { ���� ����������� }         {  8,4  k1.1}
    erIdCurO: longint;              { ���� ���. ���. }           { 12,4  k2}
    erIdArcO: longint;              { ���� ���. ���. }           { 16,4  k3}
    erIdCurI: longint;              { ���� ���. ����. }          { 20,4  k4}
    erIdArcI: longint;              { ���� ���. ����. }          { 24,4  k5}
    erState:  word;                 { ��������� ������ }         { 28,2 }
    erAdr:    longint;              { ������� }                  { 30,4 }
    erText:   array[0..erMaxVar-1] of Char;                      { 34,32100 }
  end;

  PLetterRec = ^TLetterRec;       {����� ������}
  TLetterRec = packed record
    lrIder:   longint;              { ���� ����� }            {  0,4  k0}
    lrIdKorr: longint;              { ���� � �������������� } {  4,4  k1.2}
    lrSender: longint;              { ���� ����������� }      {  8,4  k1.1}
    lrIdCurO: longint;              { ���� ���. ���. }        { 12,4  k2}
    lrIdArcO: longint;              { ���� ���. ���. }        { 16,4  k3}
    lrIdCurI: longint;              { ���� ���. ����. }       { 20,4  k4}
    lrIdArcI: longint;              { ���� ���. ����. }       { 24,4  k5}
    lrState:  word;                 { ��������� ������ }      { 28,2 }
    lrAdr:    longint;              { ������� }               { 30,4 }
    lrTextLen: Word;                { ����� ���� ������ }     { 34,2 }
    lrText:    array[0..erMaxVar-1] of Char;                  { 36,32100 }
  end;

const
  brMaxVar = 92;

type
  TAccList = class(TList)
  protected
  public
    destructor Destroy; override;
    procedure Clear; override;
    function SearchAcc(Acc: PChar): Integer;
  end;

const
  AuthKeyLength = 32;
  MaxPostBufSize = 65000;

  eccOk       = 0;
  eccSendData = 1;
  eccRcvData  = 2;
  eccRcvKvit  = 3;
  eccMes      = 254;
  eccError    = 255;

type
  PExchangeCommand = ^TExchangeCommand;
  TExchangeCommand = packed record
    cmCommand: Byte;
    cmParam: DWord;
    cmControl: Byte;
  end;

  PSendData =^TSendData;
  TSendData = packed record
    sdCommand: Byte;
    sdParam: DWord;
  end;

  TConnectionStep = (csEnter, csAuth1, csAuth2, csAuth3, csData, csError);

  GetLoginNameProc = function (Login: string; var Status: Integer;
    var UserName: string): Boolean; stdcall;


function AccColRecCompare(Key1, Key2: Pointer): Integer;
procedure SetExchangeCommand(Cmnd: Byte; Param: DWord;
  var Value: TExchangeCommand);
function CheckExchangeCommand(Value: TExchangeCommand): Boolean;
procedure CodeExchangeCommand(var Value: TExchangeCommand);
procedure DecodeExchangeCommand(var Value: TExchangeCommand);

implementation

procedure TAccList.Clear;
var
  I: Integer;
begin
  try
    try
      for I := 0 to Count-1 do
        Dispose(Items[I]);
    except
      MessageBox(GetForegroundWindow, '������ ������������ ������', '������ ������',
        MB_OK or MB_ICONERROR);
    end;
  finally
    inherited Clear;
  end;
end;

destructor TAccList.Destroy;
begin
  Clear;
  inherited Destroy;
end;

function TAccList.SearchAcc(Acc: PChar): Integer;
var
  L, H, I, C: Integer;
begin
  Result := -1;
  try
    L := 0;
    H := Count - 1;
    while L <= H do
    begin
      I := (L + H) shr 1;
      C := StrLComp(@PAccColRec(Items[I])^.acNumber, Acc, SizeOf(TAccount));
      if C < 0 then
        L := I + 1
      else begin
        H := I - 1;
        if C = 0 then
          Result := I;
      end;
    end;
  except
    MessageBox(GetForegroundWindow, '������ ������ �����',
      '������ ������', MB_OK+MB_ICONERROR);
  end;
end;

function AccColRecCompare(Key1, Key2: Pointer): Integer;
var
  k1: PAccColRec absolute Key1;
  k2: PAccColRec absolute Key2;
begin
  if k1^.acNumber<k2^.acNumber then
    Result := -1
  else
  if k1^.acNumber>k2^.acNumber then
    Result := 1
  else
    Result :=0
end;

procedure SetExchangeCommand(Cmnd: Byte; Param: DWord;
  var Value: TExchangeCommand);
begin
  with Value do
  begin
    cmCommand := Cmnd;
    cmParam := Param;
    cmControl := Cmnd;
    for Cmnd := 0 to 3 do
      cmControl := cmControl xor Byte(PChar(@Param)[Cmnd]);
  end;
end;

function CheckExchangeCommand(Value: TExchangeCommand): Boolean;
var
  EC: TExchangeCommand;
begin
  SetExchangeCommand(Value.cmCommand, Value.cmParam, EC);
  Result := EC.cmControl = Value.cmControl;
end;

const
  ExCommCons1 = 153;
  ExCommCons2 = 2801021469;

procedure CodeExchangeCommand(var Value: TExchangeCommand);
begin
  with Value do
  begin
    cmCommand := cmCommand xor ExCommCons1;
    cmParam := cmParam xor ExCommCons2;
  end;
end;

procedure DecodeExchangeCommand(var Value: TExchangeCommand);
begin
  with Value do
  begin
    cmCommand := cmCommand xor ExCommCons1;
    cmParam := cmParam xor ExCommCons2;
  end;
end;

end.
