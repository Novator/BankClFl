unit Define;

interface

uses
  Objects;

const
  cmSel      = 101;
  cmNewDoc   = 102;
  cmNewShDoc = 103;
  cmEditDoc  = 104;
  cmViewDoc  = 105;
  cmDelDoc   = 106;
  cmDos      = 107;
  cmDoc      = 108;
  cmArc      = 109;
  cmAcc      = 110;
  cmBill     = 111;
  cmCorr     = 112;
  cmNewCorr  = 113;
  cmEditCorr = 114;
  cmViewCorr = 115;
  cmDelCorr  = 116;
  cmNewAcc   = 117;
  cmEditAcc  = 118;
  cmViewAcc  = 119;
  cmDelAcc   = 120;
  cmTestSign = 121;
  cmRetDoc   = 122;
  cmDoneDoc  = 123;
  cmPost     = 124;
  cmBanks    = 125;
  cmDocDate  = 126;
  cmDocState = 127;
  cmCloseDate= 128;
  cmOpenDate = 129;
  cmPrintDoc = 130;
  cmPrintBill= 131;
  cmOps      = 132;
  cmSettings = 133;
  cmClients  = 134;
  cmNewOp    = 135;
  cmEditOp   = 136;
  cmDelOp    = 137;
  cmEditSprav= 138;
  cmNewSprav = 139;
  cmNewShSprav=140;
  cmDelSprav = 141;
  cmPurge    = 142;
  cmPrintDB  = 143;
  cmEditEMail= 144;
  cmNewEMail = 145;
  cmNewShEMail=146;
  cmDelEMail = 147;
  cmTestEMail= 148;
  cmPrintEMail=149;
  cmArcEMail = 150;
  cmViewEMail= 151;
  cmEMailOut = 152;
  cmEMailIn  = 153;
  cmEMailAOut= 154;
  cmEMailAIn = 155;
  cmObr      = 156;
  cmLoadFile = 157;
  cmExportText=158;
  cmImportText=159;
  cmExportDbf= 160;
  cmImportDbf= 161;
  cmEditOpP  = 162;
  cmInsCred  = 163;
  cmNewCash  = 164;
  cmInDoc    = 165;
  cmOutDoc   = 166;
  cmNReestr  = 167;
  cmSReestr  = 168;
  cmSearchRec= 169;
  cmSearchNext=170;
  cmAltPBill = 171;
  cmSaldo    = 172;

const
  drMaxVar   = 2020;
  arMaxVar   =   98;
  srMaxVar   =   98;
  crMaxVar   =   47;
  erMaxVar   = 32100;
  brMaxText  = 32;
  brMaxRet   = 70;

  driRkc     = 0;
  driTel     = 1;
  driEl      = 2;

  brtBill    = 0;
  brtReturn  = 1;
  brtKart    = 2;

type
  TAccount = array[0..19] of char;
  TInn = array[0..15] of char;

type
  PDocRec = ^TDocRec;
  TDocRec = record        { ���-� }
    drDate:   word;       { ���� ���-�� }                         {  0 }
    drSum:    comp;       { ����� ������� � �������� }            {  2 }
    drSrok:   word;       { ���� ������� }                        { 10 }
    drType:   byte;       { ��� �������� }                        { 12 }
    drIsp:    byte;       { ������ ���������� }                   { 13 }
    drOcher:  byte;       { ����������� ������� }                 { 14 }
    drVar:   array[0..drMaxVar-1] of char; { ���������� ����� }   { 15 }
  end;                                                            { 15 }

  PDocInBase = ^TDocInBase;
  TDocInBase = record     { ������ � ���-�� � �� }
    dbIdHere: longint;    { ���� � ����� }                        {  0 }
    dbIdKorr: longint;    { ���� � ����� }                        {  4 }
    dbIdIn:   longint;    { ���� �� �������� }                    {  8 }
    dbIdOut:  longint;    { ���� � ��������� }                    { 12 }
    dbIdArc:  longint;    { ���� � ������ }                       { 16 }
    dbIdDel:  longint;    { ���� � ��������� }                    { 20 }
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
  end;                                                            { 59 }

  PAccRec = ^TAccRec;
  TAccRec = record
    arIder:    longint;   { ���� ����� }                {  0 }
    arNumber:  TAccount;  { ����� �����}                {  4 }
    arCorr:    longint;   { ������������� }             { 24 }
    arVersion: longint;   { ����� ������ }              { 28 }
    arDateO:   word;      { ���� �������� }             { 32 }
    arDateC:   word;      { ���� �������� }             { 34 }
    arOpts:    word;      { �������� }                  { 36 }
    arSumA:    comp;      { ������� �� ����� }          { 38 }
    arSumS:    comp;      { ��������� ������� }         { 46 }
    arVar:     array[0..arMaxVar-1] of char;            { 54 }
  end;

  PAccArcRec = ^TAccArcRec;
  TAccArcRec = record
    aaIder:    longint;   { ���� ����� }                {  0 }
    aaDate:    word;      { ���� }                      {  4 }
    aaSum:     comp;      { ����� �� ����� }            {  6 }
  end;                                                  { 14 }

  PCorrRec = ^TCorrRec;
  TCorrRec = record
    crIder:    longint;             { ���� �������������� } {  0 }
    crNode:    word;                { ���� ����������� }    {  4 }
    crName:    array[0..8] of char; { �������� }            {  6 }
    crType:    byte;                { ��� �������������� }  { 15 }
    crVar:     array[0..crMaxVar-1] of char;                { 16 }
  end;

  POpRec = ^TOpRec;
  TOpRec = record
    brIder:   longint;              { ���� �������� }         {  0 }
    brDocId:  longint;              { ���� ��������� }        {  4 }
    brDate:   word;                 { ���� �������� }         {  8 }
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
      brText:   array[0..brMaxText-1] of char; { ���������� } { 70 }
    );
    brtReturn: (
      brRet:   array[0..brMaxRet-1] of char;                  { 17 }
    );
    brtKart: (
      brSumK:  comp;
    );
  end;                                                        { 17 }

  PEmailRec = ^TEmailRec;
  TEmailRec = record
    erIder:   longint;              { ���� ����� }            {  0 }
    erIdKorr: longint;              { ���� � �������������� } {  4 }
    erSender: longint;              { ���� ����������� }      {  8 }
    erIdCurO: longint;              { ���� ���. ���. }        { 12 }
    erIdArcO: longint;              { ���� ���. ���. }        { 16 }
    erIdCurI: longint;              { ���� ���. ����. }       { 20 }
    erIdArcI: longint;              { ���� ���. ����. }       { 24 }
    erState:  word;                 { ��������� ������ }      { 28 }
    erAdr:    longint;              { ������� }               { 30 }
    erText:   array[0..erMaxVar-1] of char;                   { 34 }
  end;

const
  spIdent       =  1;
  spBankAccount =  2;
  spPrnDev      =  3;
  spBankAcc     =  4;
  spBankCode    =  5;
  spBankName    =  6;
  spPrnStyle    =  7;
  spPrnFormFeed =  8;
  spClientAcc   =  9;
  spClientName  = 10;
  spCashAcc     = 11;
  spClientInn   = 12;
  spImport      = 13;
  spExport      = 14;
  spPrnWait     = 15;
  spPrnPlatLeft = 16;

const
  ParRecLen = 256;
  CenterNode: word = 1;
  KeyDir: string[4] = 'key\';
  CenterAcc: string[8] = 'CBTKB';
  PrnDev: string[78] = 'ppp';
  StdImportName: string[78] = '';
  StdExportName: string[78] = '';
  BankAcc: TAccount = ('3','0','1','0','1','8','1','0','7','0',
                       '0','0','0','0','0','0','0','8','0','3');
  ClientAcc: TAccount = '';
  ClientInn: TInn = '';
  CashAcc: TAccount = '';
  BankCode: longint = 45744803;
  BankName: array[0..92] of char = '���� "����������������"'#13#10'�. �����';
  ClientName: array[0..138] of char = '';

  prlInit:         Pstring = nil;
  prl10cpi:        Pstring = nil;
  prl12cpi:        Pstring = nil;
  prl17cpi:        Pstring = nil;
  prlUnderLineOn:  Pstring = nil;
  prlUnderLineOff: Pstring = nil;
  prlBoldOn:       Pstring = nil;
  prlBoldOff:      Pstring = nil;
  prlItalicOn:     Pstring = nil;
  prlItalicOff:    Pstring = nil;
  prlInitPlat:     PString = nil;
  prlInitBill:     PString = nil;
  prlInitLetter:   PString = nil;

  PrnStyle:    boolean = true;
  PrnFormFeed: boolean = false;
  PrnWait:     boolean = false;

  PrnPlatLeft: byte = 0;

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

const
  psOutDoc     =  1;
  psAccept     =  2;
  psDouble     =  3;
  psInDoc      =  4;
  psAnsBill    =  5;
  psInBill     =  6;
  psAccState   =  7;
  psEMail      =  8;
  psReturn     = 11;

const
  MaxPackSize = 32767-41;
  PackByteS   = $1;
  PackWordS   = $0FAC;
  PackSize: word = 4096;

type
  PSndPack = ^TSndPack;
  TSndPack = record
    spNameR:   array[0..8] of char; {�������� �������� ������� + �������}
    spNameS:   array[0..8] of char; {����������� �������� �������� ("�������") *}
    spByteS:   byte;      {���� = PackByteS}
    spLength:  word;      {= 0}
    spWordS:   word;      {���� = PackByteW}
    spNum:     longint;   {���������� �������������}
    spIder:    longint;   {*}
    spFlSnd:   char;      {= '0'}
    spDateS:   word;      {*}
    spTimeS:   word;      {*}
    spFlRcv:   char;      {*}
    spDataR:   word;      {*}
    spTimeR:   word;      {*}
    spText:    array[0..MaxPackSize-1] of char; {���������� ������}
  end;

  PRcvPack = ^TRcvPack;
  TRcvPack = record
    rpNameR:   array[0..8] of char;
    rpNameS:   array[0..8] of char;
    rpByteS:   byte;
    rpLength:  word;
    rpWordS:   word;
    rpNum:     longint;
    rpIder:    longint;
    rpDateS:   word;
    rpTimeS:   word;
    rpDataR:   word;
    rpTimeR:   word;
    rpText:    array[0..MaxPackSize-1] of char;
  end;

const
  DocMemoSize = 510;

type
  PByte = ^byte;
  PWord = ^word;
  PLong = ^longint;

implementation

end.
