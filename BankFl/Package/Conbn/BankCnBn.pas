unit BankCnBn;

interface

uses
  CommCons, Windows;

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
  cmAllAcc   = 163;
  cmFullAcc  = 164;
  cmRestoreC = 165;
  cmRestoreB = 166;
  cmToggle   = 167;

const
  srMaxVar   =   98;
  crMaxVar   =   47;
  sfMaxData  = 32000;

  driRkc     = 0;
  driTel     = 1;
  driEl      = 2;

  BroadcastNode = -1;       { ���� �������� �������� }
  BroadcastLogin: PChar = 'ALL';
  BroadcastName: PChar = '��� ��������';

  GroupNode = -2;       { ���� ��������� �������� }
  GroupLogin: PChar = 'SOME';
  GroupName: PChar = '��������� ��������';

type
  PBankPayRec = ^TBankPayRec;
  TBankPayRec = packed record     { ������ � ���-�� � �� }
    dbIdHere: longint;    { ���� � ����� }                        {  0  k0}
    dbIdKorr: longint;    { ���� � �������������� }               {  4  k1.0}
    dbIdSender: longint;  { ���� ����������� }                    {  8  k1.1}
    dbIdDoc:  longint;    { ���� � ������� }                      { 12  k2}
    dbIdArc:  longint;    { ���� � ������ }                       { 16  k3}
    dbIdDel:  longint;    { ���� � ��������� }                    { 20  k4}
    dbUserCode: Longint;    { ����� ������ }                        { 24 }
    dbState:  word;       { ��������� ���-�� }                    { 28 }
    dbDateS:  word;       { ���� �������� }                       { 30 }
    dbTimeS:  word;       { ����� �������� }                      { 32 }
    dbDateR:  word;       { ���� ��������� ������ }               { 34 }
    dbTimeR:  word;       { ����� ��������� ������ }              { 36 }
    dbDateP:  word;       { ���� ��������� ������ }               { 38 }
    dbTimeP:  word;       { ����� ��������� ������ }              { 40 }
    dbDocVarLen: word;       { ����� ��������� }                     { 42 }
    dbDoc:    TDocRec;    { �������� � ��. �������� � ������� }   { 44 }
  end;                                                            { 59 }

  PCorrRecX = ^TCorrRecX;
  TCorrRecX = packed record
    crIder:    longint;             { ���� �������������� } {  0  k0}
    crNode:    word;                { ���� ����������� }    {  4 }
    crName:    TCorrName;           { �������� }            {  6  k1}
    crType:    byte;                { ��� �������������� }  { 15 }
    crWay:     byte;                { ������ �������� }     { 16 }
    crLock:    byte;                { ���������� }          { 17 }
    crSize:    word;                { ������ ������ }       { 18 }
    crCrypt:   byte;                { �������� ������ }     { 20 }
    crVar:     array[0..crMaxVar-1] of char;                { 21 }
  end;

  PQrmOperRec = ^TQrmOperRec;
  TQrmOperRec = packed record
    onIder:    Integer;                  { ���� �����   }   {  0,4  k0}
    onName:    array[0..63] of Char;     { �������� }       {  4,64  }
  end;                                                      { =68}

const
  alSend      = $1;
  alRecv      = $2;
  alSExtr     = $20;                     //��������� ����������
  alOther     = $C;

  atClient      = $00;
  atBranch      = $01;
  atBank        = $02;
  atStatus      = $03;
  atTrace       = $04;
  atSmallPack   = $08;
  //atExtSign     = $0F;

  aloNone     = $0;
  aloTake     = $4;
  aloNew      = $8;
  aloPrivat   = $C;

  awFocus     = 0;
  awObmen     = 1;
  awPostMach  = 2;

  acNone      = 0;
  acTcbGost   = 1;
  acDomenK    = 2;

type
  TAbonName = packed array[0..63] of Char;

  PAbonentRec = ^TAbonentRec;
  TAbonentRec = packed record
    abIder:     longint;             { ���� �������������� }  {  0,4  k0}
    abLogin:    TAbonLogin;          { �������� }             {  4,9  k1}
    abOldLogin: TCorrName;           { ������ �������� }      { 13,9  k2}
    abNode:     word;                { ���� ����������� }     { 22,2  }
    abType:     byte;                { ��� �������������� }   { 24,1  }
    abWay:      byte;                { ������ �������� }      { 25,1  }
    abLock:     byte;                { ���������� }           { 26,1  }
    abSize:     word;                { ������ ������ }        { 27,2  }
    abCrypt:    byte;                { �������� ������ }      { 29,1  }
    abName:     TAbonName;           { ���  }                 { 30,64 }
  end;                                                        { = 94 }

  PAbonIdRec = ^TAbonIdRec;
  TAbonIdRec = packed record
    aiIder:     longint;             { ���� �������������� }  {  0,4  k0}
    aiLastAuth: dWord;               { ��������� ���. }       {  4,4  }
    aiHardId:   dWord;               { ������������� ������ } {  8,4  }
  end;                                                        { = 12 }

  TAbonUserName = array[0..63] of Char;

  PAbonSignIdRec = ^TAbonSignIdRec;
  TAbonSignIdRec = packed record
    asIder:     longint;             { ���� �������������� }  {  0,4  k1  k0.1}
    asLogin:    TAbonLogin;          { �������� }             {  4,9  k2  k0.2}
    asStatus:   Word;                { ������ }               {  13,2  }
    asName:     TAbonUserName;       { ���� � ����� }         {  15,64}
  end;                                                        { = 79 }

  PSprCorRec = ^TSprCorRec;
  TSprCorRec = packed record                   {������������� �����������}
    scIderR:  longint;                  {���� ������          k0, k1.0}
    scIderC:  longint;                  {���� ����������          k1.1}
    scVer:    word;                     {����� �������������}
    scType:   byte;                     {��� ������}
    scData:   array [0..199] of byte;   {������}
  end;

  PSprAboRec = ^TSprAboRec;
  TSprAboRec = packed record
    saIderR:  longint;                  {���� ������ �������������  k0.0, k1.0}
    saCorr:   longint;                  {���� ��������              k0.1, k1.1}
    saState:  word;                     {���������                        k1.2}
  end;

  PSendFileRec = ^TSendFileRec;
  TSendFileRec = packed record                 {���� �� ��������}
    sfBitIder:  word;                   {���� ���������        k1.0  k2.0}
    sfFileIder: longint;                {���� �����        k0  k1.1  k2.1}
    sfAbonent:  longint;                {���� ��������         k1.2  k2.2}
    sfState:    word;                   {���������                   k2.3}
    sfData:     array [0..sfMaxData] of char; {������}
  end;

  PExportRec = ^TExportRec;
  TExportRec = packed record
    erIderB:     longint;      {k0}
    erOperNum:   longint;      {k1.0}
    erOperation: word;         {k1.1}
  end;

  PImportRec = ^TImportRec;
  TImportRec = packed record
    irIderB:     longint;      {k0}
    irOperNum:   longint;      {k1.0}
    irOperation: word;         {k1.1}
    irProCode:   longint;      {k2.0}
    irProDate:   longint;      {k2.1}
  end;

  PTransRec = ^TTransRec;
  TTransRec = packed record     { ������ ����� ������, ���������� �/� �������� }
    sbBik: Longint;             { ���     k0}
    sbState: Byte;              { ������ }
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
  spIntAcc      = 17;

const
  {ParRecLen = 256;
  KeyDir: string[4] = 'key\';}
  {PrnDev: string[78] = 'ppp';}

  ToggleDocView:   boolean = false;

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

type
  PPro = ^TPro;
  TPro = packed record
    ProDate        : longint;    {"���� ��������"  }
    ProCode        : longint;    {"��� ��������"   
    DocDate        : longint;    {"���� ���������" }
    DocCode        : longint;    {"��� ���������"}
    DocNum         : string[8];  {"����� ���������"}
    ContNum        : string[9];  {"����� ��������"}
    OperCode       : word;       {"��� ���� ��������"}
    UserCode       : longint;    {"��� ������������"}
    DbCurrCode     : string[3];  {"��� ������ �� ������"}
    DbAcc          : string[10]; {"����� ����� �� ������"}
    KrCurrCode     : string[3];  {"��� ������ �� �������"}
    KrAcc          : string[10]; {"����� ����� �� �������"}
    ExtAcc         : string[21]; {"��������� ���� � ����� �"}
    BatNum         : word;       {"����� �����"}
    Kay            : word;       {"��� ����. �����"}
    ZaklObor       : word;       {"������� �������������� ��������",//1 -��������������}
    WorkStr        : String[3];  {"������"}
    DocKind        : string[1];  {"��� �������������� ���.", '�'-���������,'�'-����������}
    Operation      : word;       {"��� ��������"}
    Operation1     : word;       {"��� �������� 1"}
    OperNum        : longint;    {"����� ��������"}
    OperNum1       : longint;    {"����� �������� 1"}
    Cash           : word;       {"��� ���������",//0,1-��������}
    SumPro         : double;     {"����� �� �������� ���."}
    SumValPro      : double;     {"����� �� �������� ���."}
    Storno         : word;       {"0 -������,1-������"}
    BankCode       : string[12]; {"��� ����� "}
    SumKrValPro    : double;     {"����� ���. �� �������"}
  end;

const
  tiPro1     = 0; {ProDate( unique ,seg),ProCode}
  tiProDb    = 1; {DbAcc(seg),DbCurrCode(seg),ProDate(seg),ProCode}
  tiProKr    = 2; {KrAcc (seg),KrCurrCode(seg),ProDate(seg),ProCode}
  tiProOper  = 3; {Operation(seg),OperNum}
  tiOperCont = 4; {ContNum(seg),Operation(seg),ProDate}
  tiDocPro   = 5; {Cash(seg),DocCode}
  tiDtypePro = 6; {Cash(seg),ProDate(seg),ProCode}

type
  TExtAcc = string[25];

  PPayOrder = ^TPayOrder;
  TPayOrder = packed record
    PayAcc            : String[10];  {"������� ����"}
    CurrCodePay       : String[3];   {"��� ������"}
    CorrAcc           : String[10];  {"����������.����"}
    CurrCodeCorr      : String[3];   {"��� ������ 1"}
    DocNum            : String[8];   {"����� ���������"}
    DocDate           : longint;     {"���� ���������"}
    Branch            : longint;     {"��������� �����"}
    SenderCorrCode    : String[9];   {"��� ����. ����� �����������"}
    SenderBankNum     : String[9];   {"��� ����� �����������"}
    SenderMfo         : String[9];   {"��� ����� �����������"}
    SenderUchCode     : String[3];   {"��� ��������� ����� �����������"}
    OldSenderCorrAcc  : String[10];  {"������ ������� ����� �����������"}
    ReceiverCorrCode  : String[9];   {"��� ����. ����� ����������"}
    ReceiverBankNum   : String[9];   {"��� ����� ����������"}
    ReceiverMfo       : String[9];   {"��� ����� ����������"}
    ReceiverUchCode   : String[3];   {"��� ��������� ����� ����������"}
    CorrSum           : double;      {"����� � ������ ����.�����"}
    EqualSum          : double;      {"����� � ���.�����������"}
    OldBenefName      : string[66];  {"��� �����������(����)"}
    DocType           : string[1];   {"��� ���������('�','�','')"}
    SendType          : word;        {"�����/��������"}
    UserCode          : longint;     {"��� �����������"}
    BatchType         : longint;     {"��� �����"}
    BatchNum          : longint;     {"����� �����"}
    OperNum           : longint;     {"��� ��������(����������)"}
    Status            : word;        {"������ ��������"}
    PreStatus         : word;        {"��������� ��������"}
    Break             : word;        {"��������/�������"}
    CommPay           : single;      {"��������"}
    OrderType         : word;        {"������/�� ������"}
    Pro_Col           : word;        {"���-�� ��������� ��������"}
    Doc_Col           : word;        {"���-�� �������� ��������"}
    InOperation       : word;        {"��� ���������� ��������"}
    InOperNum         : longint;     {"��� ���������� ��������"}
    PaySum            : double;      {"�����"}
    PayTelegSum       : double;      {"����� �� �������"}
    VpCode            : longint;     {"��� �������"}
    PrNum             : longint;     {"����� �������� � �������"}
    PosDate           : longint;     {"���� ���������������� ���������"}
    ProcDate          : longint;     {"���� ������������� ���������"}
    UserControl       : longint;     {"������� ���������" ,����� � UserCtrl ����� UserCtrl.Code}
    ControlLink       : longint;     {"����� � ���������"}
    ValueDate         : longint;     {"���� ������������� ���������"}
    Priority          : word;        {"���������"}
    OldBenefTaxNum    : string[10];  {"����� �����������������(������)",��� �����-��}
    RaceNum           : word;        {"����� �����"}
    OrderNumber       : word;        {"���������� N ��������� � �����"}
    LinkStatus        : word;        {"������ ������ ����� � ���"}
    RaceDate          : longint;     {"���� �����"}
    StatusHlp         : word;        {"������ ��� �����������", Status=0,5 -> StatusHlp = 0; Status>10 -> StatusHlp = Status}
    OperCode          : word;        {"��� ���� ��������"}
    Kay               : word;        {"��� ����. �����"}
    ZaklObor          : word;        {"����. ������"}
    AddInfo           : string[12];  {"���.����������"}
    BenefTaxNum       : string[15];  {"����� �����������������", ��� �����-��}
    TypeKvit          : word;        {"��� ���������", ����� � DivKvit}
    BenefAcc          : tExtAcc;     {"����� ���� �����������"}
    KanvaNum          : string[9];   {"���������� ����� ��������� � ���"}
    SenderCorrAcc     : tExtAcc;     {"������� ����� �����������"}
    ReceiverCorrAcc   : tExtAcc;     {"������� ����� ����������"}
    BenefName         : string[254]; {"��� �������� �������"}
    INNOur            : string[15];  {"��� ������� � ���"}
    ClientNameOur     : string[254]; {"��� ������� � ���"}
    ClientAcc         : tExtAcc;     {"���� �������-�����������"}
    IsAviso           : word;        {"������� �����"}
    BitMask           : word;        {"���� ��������"}
    PaymentAlg        : word;        {"�������� ������ ���������"}
    KvitPossMask      : word;        {"����� ��� ��������"}
    DppDate           : longint;     {"���"}
    Ref               : string[16];  {"��������"}
    VisUserCode       : longint;     {"��������"}
    Marshrut          : longint;     {"�� ��������"}
    MarshrutDate      : longint;     {"���� �����������������"}
    ReservPay         : word;        {"������� ������������� �������"}
    Akcept            : word;
    MenuItem          : word;
    indate            : longint;
    WorkStr           : String[2];   {"������"}
  end;

const
  tiPaO1  =  0; {OperNum(autoinc)}
  tiPaO2  =  1; {StatusHlp(seg),UserCode(seg),BatchNum}
  tiPaO3  =  2; {UserCode(Seg),StatusHlp}
  tiPaO4  =  3; {StatusHlp(seg),PosDate(seg),UserCode}
  tiPaO5  =  4; {PaySum}
  tiPaO6  =  5; {DocNum}
  tiPaO7  =  6; {PayAcc}
  tiPaO8  =  7; {DocDate}
  tiPaO9  =  8; {PosDate}
  tiPaO10 =  9; {Ref}
  tiPaO11 = 10; {StatusHlp(seg),VisUserCode}

type
  PPayOrCom = ^TPayOrCom;
  TPayOrCom = packed record
    OperNum  : longint;     {"����� ��������"}
    Status   : word;        {"������", 0 - PayOrder}
                            {          1 - MemOrder}
                            {          2 - CashOrder}
                            {          3 - UnkDocN}
                            {          4..6 - CashOrder(Another Info)}
                            {          >=32000 - �� ���������� �������������}
    Comment  : String[254]; {"�����������"}
    ComOwner : word;        {"�������� ������������"}
    Comment1 : String[254]; {"�����������1"}
  end;

const
  tiPayCom1 = 0; {OperNum(Seg),Status}
  tiPayCom2 = 1; {OperNum(Seg),Status(Seg),ComOwner}
  tiPayCom3 = 2; {OperNum(Seg),ComOwner}

type
  PAccounts = ^TAccounts;
  TAccounts = packed record
    AccNum             : string[10];   {"����� �������� �����"}
    AccPlch            : string[3];    {"���� 2 �������"}
    AccName            : string[48];   {"������������ �������� �����"}
    ClientCode         : longint;      {"��� �������"}
    AccStatus          : word;         {"������ �����", 7-���������, 8-�����������,}
                                       { 9-������������(����. �����), 10-�������������}
    Open_Close         : word;         {"������ ����� ������/������"}
    CurrCode           : string[3];    {"��� ������"}
    OpenDate           : longint;      {"���� �������� �����"}
    CloseDate          : longint;      {"���� ��������,������,���������� �����"}
    OperNum            : longint;      {"����� �������������"}
    ContNum            : string[9];    {"����� ��������"}
    RightBuffer        : array[0..252] of char; {"����� �� ����"}
    ChSum              : word;         {"����������� �����"}
    ClientMessage      : string[188];  {"��������� �������"}
    ValueCode          : longint;      {"��� ��������"}
    AccEndDate         : longint;      {"���� ��������� �����"}
    DayCount           : word;         {"���� � ����"}
    AccNewPlch         : longint;      {"����� ���� 2 �������"}
    NewAccNum          : String[22];   {"����� ����� �����"}
    ShifrMask          : String[20];   {"���� �����"}
    UserGroupCode      : longint;      {"��� ������"}
    Priority           : word;         {"��������� �����", 0 - �������������,}
                                       { 1 - �������� ������ ���.�������,}
                                       { 2 - �������� ���.������� � ��������� DivCode}
    DivCode            : word;         {"��� ���������", ����� ����� ���� ��� Priority=2}
    OwerContNum        : String[9];    {"����� �������� �� ���������"}
    ReAccPr            : word;         {"������� ����������"}
    ReAccount          : string[10];   {"���� ����������"}
    RedCheck           : word;         {"�������� �� ������� ������"}
    AccSort            : string[12];   {"����� ����� ��� ����������"}
    AccCourse          : double;       {"���� �����"}
    KindCont           : word;         {"��� ��������"}
    KindAcc            : byte;         {"��� �����", 0-�/� 1-� 2-�}
    KindSaldo          : byte;         {"��� ������", 0-�������������� 1-������������}
    OraF_ID_Filial     : word;         {"��� �������"}
    WayOfExt           : word;         {"������� ������ �������"}
    PerAmount          : word;         {"������������� ������ ������� (���.)"}
    PerType            : word;         {"������������� ������ ������� (���)"}
    AccCode            : longint;      {"���������� ����"}
  end;

const
  tiAccbySort           =  0; {AccSort}
  tiIAccCode            =  1; {AccCode}
  tiIacc3               =  2; {ClientCode(mod)}
  tiIacc4               =  3; {CurrCode(mod)}
  tiIacc6               =  4; {OpenDate}
  tiIacc8               =  5; {CloseDate}
  tiIacc9               =  6; {ContNum}
  tiIacc10              =  7; {Open_Close(seg),CurrCode(seg),AccNum}
  tiIacc11              =  8; {Open_Close(seg),AccPlch}
  tiAccbyOpenCurrSort   =  9; {Open_Close(seg),CurrCode(seg),AccSort}
  tiAccbySortbyCurrCode = 10; {AccSort(seg),CurrCode}
  tiAccbyNewAccNum      = 11; {NewAccNum}
  tiAccbyOpenCurrNewNum = 12; {Open_Close(seg),CurrCode(seg),NewAccNum}
  tiAccbyNewPlch        = 13; {AccNewPlch}
  tiAccbyOperNum        = 14; {OperNum}

type
  PClients = ^TClients;
  TClients = packed record
    ClientCode    : longint;      {"��� ��������� �����"}
    ClientName    : string[254];  {"�������� �����",  //str48}
    Byte255a      : byte;         {"255-� ����"}
    ShortName     : string[80];   {"������� ��� �������",   //str32}
    Adress        : string[48];   {"������� ����� ��������� �����"}
    Telephone     : string[32];   {"�������"}
    HasModem      : word;         {"������� ������"}
    PrizJur       : word;         {"������� ����������� ��� ���������� ����"}
    PropertyCode  : string[3];    {"��� ����� �������������"}
    CodeOKPO      : string[9];    {"��� ����"}
    RegisSer      : string[6];    {"��������������� �����������: �����"}
    RegisNum      : string[15];   {"��������������� �����������: �����", //str12}
    RegisDate     : longint;      {"��������������� �����������: ����"}
    RegisLocation : string[60];   {"��������������� �����������: �����", //str48}
    TaxNum        : string[15];   {"����� �����������������",//���}
    TaxDate       : longint;      {"��������� ���������: ����"}
    TaxNumGNI     : string[15];   {"��������� ���������: ����� ���", //str10}
    TaxLocation   : string[60];   {"��������� ���������: �����", //str48}
    Pasport       : string[48];   {"��� ����� �������"}
    BankNum       : string[9];    {"��� �����"}
    PayAccOld     : string[15];   {"���� � ����� Old"}
    ClType        : word;         {"��� �� �������������� ��������"}
    Rezident      : word;         {"������� �������� , 0-���-�, 1-�� ���-�"}
    CoClientClass : byte;         {"��� ������ �������"}
    CoClientType  : byte;         {"��� ���� �������"}
    CuratorCode   : longint;      {"�������"}
    F775          : String[3];    {"������ �.775"}
    ShifrMask     : String[20];   {"���� �������"}
    HasVoice      : word;         {"������� �������������-������� �������"}
    COPF          : String[2];    {"��� �������� ����� (����)"}
    COATO         : String[12];   {"��� �����"}
    CountryCode   : String[2];    {"��� ������"}
    PayAcc        : TExtAcc;      {"���� � �����"}
    ClFromOffice  : word;         {"������ ������� (1-��)"}
    DocType       : string[2];    {"��� �������������"}
    SerPasp       : string[10];   {"����� �������������� ���������"}
    NumPasp       : string[20];   {"����� �������������� ���������"}
    DatePasp      : longint;      {"���� ������ ��������"}
    ReasCode      : String[9];    {"��� ������� ���������� �� ����"}
    TaxDocType    : string[48];   {"������������� ����� � ��������� ������"}
                                  {// ��� � ��������� ���������, ��������������� ����}
                                  {// ���������� ���� �� ���� � ��������� ������}
    UserCode      : longint;      {"������������� �����������"}
    WorkStr       : String[1];    {"������"}
  end;

const
  tiIcl0 = 0; {PrizJur(seg),ClientName(length=12,offset=1)}
  tiIcl1 = 1; {ClientCode (nomod,autoinc)}
  tiIcl2 = 2; {PropertyCode}
  tiIcl3 = 3; {TaxNumGNI}
  tiICl4 = 4; {HasModem(seg),PrizJur(seg),ClientName(Length = 12, Offset = 1)}
  tiClientsByType = 5; {ClType}
  tiICL5 = 6; {TaxNum}
  tiICL6 = 7; {SerPasp(seg),NumPasp}
  tiICL7 = 8; {ClientName(length=12,offset=1)}

type
  PBanks = ^TBanks;
  TBanks = packed record
    BankNum      : string[9];   {����� ����� � ����� ������� (���-9)}
    Mfo          : string[6];   {������ ����� ��� (���-6)}
    RkcNum       : string[9];   {BankNum ���}
    BankTaxNum   : string[10];  {��� �����}
    CorrAccOld   : string[10];  {�������� ����������� ��� � ��� Old}
    BankType     : word;        {��� ���� ����������� ���������� (table)}
    TypeAbbrev   : string[4];   {��� ����������� ���������� (����.)}
    BankName     : string[128]; {�������� ����������� ����������}
    PostInd      : string[6];   {�������� ������}
    RegionNum    : word;        {������ (table)}
    Adress       : string[64];  {����� (��� ���.������+��� ���.������)}
    Street       : string[64];  {�����+���}
    Telephone    : string[25];  {�������(�)}
    Telegraph    : string[14];  {����������� ��������(�)}
    Srok         : byte;        {���� ����������� ���������� (����)}
    ElUch        : byte;        {������� � ����������� �������� 0-���, 1-��}
    Okpo         : string[8];   {��� ����}
    UchCode      : string[3];   {��� ��������� ������ ��������}
    RegistrNum   : string[9];   {��������������� �����}
    Licence      : word;        {��������}
    MfoCont      : string[20];  {���+����}
    NumInUse     : string[20];  {������������ ��� �����}
    WhichBankNum : word;        {������������ ����� �����}
                                {0-���, 1-��������, 2-�����, 3-��� + ����}
    UchFlag      : word;        {0-�� ��������, 1-�������� ������ ����}
    Vkey         : String[8];   {���������}
    BankCorrAcc  : TExtAcc;     {����������������� ��.�����}
    CorrAcc      : TExtAcc;     {�������� ����������� ��� � ���}
    Sks          : string[6];
  end;

{ ��� ���� }
const
  btDoc        =  0;
  btArc        =  1;

{ ��������� ����� }
const
  asLocks      = $1C0;
  asLockDt     = $40;
  asLockCr     = $80;
  asLockCl     = $100;

implementation

end.

