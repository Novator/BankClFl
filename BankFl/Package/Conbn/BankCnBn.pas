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

  BroadcastNode = -1;       { Узел массовых рассылок }
  BroadcastLogin: PChar = 'ALL';
  BroadcastName: PChar = 'Все абоненты';

  GroupNode = -2;       { Узел групповых рассылок }
  GroupLogin: PChar = 'SOME';
  GroupName: PChar = 'Выбранные абоненты';

type
  PBankPayRec = ^TBankPayRec;
  TBankPayRec = packed record     { Запись о док-те в БД }
    dbIdHere: longint;    { Идер в банке }                        {  0  k0}
    dbIdKorr: longint;    { Идер у корреспондента }               {  4  k1.0}
    dbIdSender: longint;  { Идер отправителя }                    {  8  k1.1}
    dbIdDoc:  longint;    { Идер в текущих }                      { 12  k2}
    dbIdArc:  longint;    { Идер в архиве }                       { 16  k3}
    dbIdDel:  longint;    { Идер в удаленных }                    { 20  k4}
    dbUserCode: Longint;    { Номер версии }                        { 24 }
    dbState:  word;       { Состояние док-та }                    { 28 }
    dbDateS:  word;       { Дата отправки }                       { 30 }
    dbTimeS:  word;       { Время отправки }                      { 32 }
    dbDateR:  word;       { Дата получения банком }               { 34 }
    dbTimeR:  word;       { Время получения банком }              { 36 }
    dbDateP:  word;       { Дата обработки банком }               { 38 }
    dbTimeP:  word;       { Время обработки банком }              { 40 }
    dbDocVarLen: word;       { Длина документа }                     { 42 }
    dbDoc:    TDocRec;    { Документ с эл. подписью и ответом }   { 44 }
  end;                                                            { 59 }

  PCorrRecX = ^TCorrRecX;
  TCorrRecX = packed record
    crIder:    longint;             { Идер корреспондента } {  0  k0}
    crNode:    word;                { Узел криптования }    {  4 }
    crName:    TCorrName;           { Позывной }            {  6  k1}
    crType:    byte;                { Тип корреспондента }  { 15 }
    crWay:     byte;                { Способ отправки }     { 16 }
    crLock:    byte;                { Блокировки }          { 17 }
    crSize:    word;                { Размер пакета }       { 18 }
    crCrypt:   byte;                { Шифрация пакета }     { 20 }
    crVar:     array[0..crMaxVar-1] of char;                { 21 }
  end;

  PQrmOperRec = ^TQrmOperRec;
  TQrmOperRec = packed record
    onIder:    Integer;                  { Идер опера   }   {  0,4  k0}
    onName:    array[0..63] of Char;     { Позывной }       {  4,64  }
  end;                                                      { =68}

const
  alSend      = $1;
  alRecv      = $2;
  alSExtr     = $20;                     //Добавлено Меркуловым
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
    abIder:     longint;             { Идер корреспондента }  {  0,4  k0}
    abLogin:    TAbonLogin;          { Позывной }             {  4,9  k1}
    abOldLogin: TCorrName;           { Старый позывной }      { 13,9  k2}
    abNode:     word;                { Узел криптования }     { 22,2  }
    abType:     byte;                { Тип корреспондента }   { 24,1  }
    abWay:      byte;                { Способ отправки }      { 25,1  }
    abLock:     byte;                { Блокировки }           { 26,1  }
    abSize:     word;                { Размер пакета }        { 27,2  }
    abCrypt:    byte;                { Шифрация пакета }      { 29,1  }
    abName:     TAbonName;           { Имя  }                 { 30,64 }
  end;                                                        { = 94 }

  PAbonIdRec = ^TAbonIdRec;
  TAbonIdRec = packed record
    aiIder:     longint;             { Идер корреспондента }  {  0,4  k0}
    aiLastAuth: dWord;               { Последняя авт. }       {  4,4  }
    aiHardId:   dWord;               { Идентификатор железа } {  8,4  }
  end;                                                        { = 12 }

  TAbonUserName = array[0..63] of Char;

  PAbonSignIdRec = ^TAbonSignIdRec;
  TAbonSignIdRec = packed record
    asIder:     longint;             { Идер корреспондента }  {  0,4  k1  k0.1}
    asLogin:    TAbonLogin;          { Позывной }             {  4,9  k2  k0.2}
    asStatus:   Word;                { Статус }               {  13,2  }
    asName:     TAbonUserName;       { Инфо о юзере }         {  15,64}
  end;                                                        { = 79 }

  PSprCorRec = ^TSprCorRec;
  TSprCorRec = packed record                   {Корректировка справочника}
    scIderR:  longint;                  {Идер записи          k0, k1.0}
    scIderC:  longint;                  {Идер обновления          k1.1}
    scVer:    word;                     {Номер корректировки}
    scType:   byte;                     {Тип записи}
    scData:   array [0..199] of byte;   {Данные}
  end;

  PSprAboRec = ^TSprAboRec;
  TSprAboRec = packed record
    saIderR:  longint;                  {Идер записи корректировки  k0.0, k1.0}
    saCorr:   longint;                  {Идер абонента              k0.1, k1.1}
    saState:  word;                     {Состояние                        k1.2}
  end;

  PSendFileRec = ^TSendFileRec;
  TSendFileRec = packed record                 {Файл на отправку}
    sfBitIder:  word;                   {Идер фрагмента        k1.0  k2.0}
    sfFileIder: longint;                {Идер файла        k0  k1.1  k2.1}
    sfAbonent:  longint;                {Идер абонента         k1.2  k2.2}
    sfState:    word;                   {Состояние                   k2.3}
    sfData:     array [0..sfMaxData] of char; {Данные}
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
  TTransRec = packed record     { Список БИКов банков, работающих ч/з сбербанк }
    sbBik: Longint;             { БИК     k0}
    sbState: Byte;              { Статус }
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
    ProDate        : longint;    {"Дата проводки"  }
    ProCode        : longint;    {"Код проводки"   
    DocDate        : longint;    {"Дата документа" }
    DocCode        : longint;    {"Код документа"}
    DocNum         : string[8];  {"Номер документа"}
    ContNum        : string[9];  {"Номер договора"}
    OperCode       : word;       {"Код рода операции"}
    UserCode       : longint;    {"Код пользователя"}
    DbCurrCode     : string[3];  {"Код валюты по дебету"}
    DbAcc          : string[10]; {"Номер счета по дебету"}
    KrCurrCode     : string[3];  {"Код валюты по кредиту"}
    KrAcc          : string[10]; {"Номер счета по кредиту"}
    ExtAcc         : string[21]; {"Расчетный счет в банке Б"}
    BatNum         : word;       {"Номер пачки"}
    Kay            : word;       {"Код альт. учета"}
    ZaklObor       : word;       {"Признак заключительных оборотов",//1 -заключительные}
    WorkStr        : String[3];  {"Резерв"}
    DocKind        : string[1];  {"Тип межбанковского док.", 'Д'-дебетовый,'К'-кредитовый}
    Operation      : word;       {"Тип операции"}
    Operation1     : word;       {"Тип операции 1"}
    OperNum        : longint;    {"Номер операции"}
    OperNum1       : longint;    {"Номер операции 1"}
    Cash           : word;       {"Тип документа",//0,1-Наличный}
    SumPro         : double;     {"Сумма по проводке нац."}
    SumValPro      : double;     {"Сумма по проводке вал."}
    Storno         : word;       {"0 -просто,1-сторно"}
    BankCode       : string[12]; {"Код банка "}
    SumKrValPro    : double;     {"Сумма вал. по кредиту"}
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
    PayAcc            : String[10];  {"Лицевой счет"}
    CurrCodePay       : String[3];   {"Код валюты"}
    CorrAcc           : String[10];  {"Корреспонд.счет"}
    CurrCodeCorr      : String[3];   {"Код валюты 1"}
    DocNum            : String[8];   {"Номер документа"}
    DocDate           : longint;     {"Дата документа"}
    Branch            : longint;     {"Отделение банка"}
    SenderCorrCode    : String[9];   {"Код корр. банка отправителя"}
    SenderBankNum     : String[9];   {"Код банка отправителя"}
    SenderMfo         : String[9];   {"МФО банка отправителя"}
    SenderUchCode     : String[3];   {"Код участника банка отправителя"}
    OldSenderCorrAcc  : String[10];  {"Старый корсчет банка отправителя"}
    ReceiverCorrCode  : String[9];   {"Код корр. банка получателя"}
    ReceiverBankNum   : String[9];   {"Код банка получателя"}
    ReceiverMfo       : String[9];   {"МФО банка получателя"}
    ReceiverUchCode   : String[3];   {"Код участника банка получателя"}
    CorrSum           : double;      {"Сумма в валюте корр.счета"}
    EqualSum          : double;      {"Сумма в нац.эквиваленте"}
    OldBenefName      : string[66];  {"Имя бенефициара(стар)"}
    DocType           : string[1];   {"Тип документа('Д','К','')"}
    SendType          : word;        {"Почта/телеграф"}
    UserCode          : longint;     {"Код исполнителя"}
    BatchType         : longint;     {"Тип пачки"}
    BatchNum          : longint;     {"Номер пачки"}
    OperNum           : longint;     {"Код операции(уникальный)"}
    Status            : word;        {"Статус операции"}
    PreStatus         : word;        {"Престатус операции"}
    Break             : word;        {"Актуален/отложен"}
    CommPay           : single;      {"Комиссия"}
    OrderType         : word;        {"Срочно/не срочно"}
    Pro_Col           : word;        {"Кол-во сделанных проводок"}
    Doc_Col           : word;        {"Кол-во плановых проводок"}
    InOperation       : word;        {"Тип породившей операции"}
    InOperNum         : longint;     {"Код породившей операции"}
    PaySum            : double;      {"Сумма"}
    PayTelegSum       : double;      {"Сумма за перевод"}
    VpCode            : longint;     {"Код выписки"}
    PrNum             : longint;     {"Номер проводки в выписке"}
    PosDate           : longint;     {"Дата позиционирования документа"}
    ProcDate          : longint;     {"Дата подтверждения документа"}
    UserControl       : longint;     {"Подпись документа" ,Связь с UserCtrl через UserCtrl.Code}
    ControlLink       : longint;     {"Связь с ленточкой"}
    ValueDate         : longint;     {"Дата валютирования документа"}
    Priority          : word;        {"Приоритет"}
    OldBenefTaxNum    : string[10];  {"Номер налогоплательщика(старый)",ИНН бенеф-ра}
    RaceNum           : word;        {"Номер рейса"}
    OrderNumber       : word;        {"Порядковый N документа в рейсе"}
    LinkStatus        : word;        {"Статус обмена рейса с РКЦ"}
    RaceDate          : longint;     {"Дата рейса"}
    StatusHlp         : word;        {"Статус для ограничений", Status=0,5 -> StatusHlp = 0; Status>10 -> StatusHlp = Status}
    OperCode          : word;        {"Код рода операции"}
    Kay               : word;        {"Код альт. учета"}
    ZaklObor          : word;        {"Закл. оборот"}
    AddInfo           : string[12];  {"Доп.информация"}
    BenefTaxNum       : string[15];  {"Номер налогоплательщика", ИНН бенеф-ра}
    TypeKvit          : word;        {"Тип квитанции", Связь с DivKvit}
    BenefAcc          : tExtAcc;     {"Новый Счет бенефициара"}
    KanvaNum          : string[9];   {"Внутренний номер документа в РКЦ"}
    SenderCorrAcc     : tExtAcc;     {"Корсчет банка отправителя"}
    ReceiverCorrAcc   : tExtAcc;     {"Корсчет банка получателя"}
    BenefName         : string[254]; {"Имя внешнего клиента"}
    INNOur            : string[15];  {"ИНН клиента у нас"}
    ClientNameOur     : string[254]; {"Имя клиента у нас"}
    ClientAcc         : tExtAcc;     {"Счет клиента-отправителя"}
    IsAviso           : word;        {"Признак АВИЗО"}
    BitMask           : word;        {"Виды отправок"}
    PaymentAlg        : word;        {"Алгоритм оплаты документа"}
    KvitPossMask      : word;        {"Маска для квитовки"}
    DppDate           : longint;     {"ДПП"}
    Ref               : string[16];  {"Референс"}
    VisUserCode       : longint;     {"Визионер"}
    Marshrut          : longint;     {"ИД Маршрута"}
    MarshrutDate      : longint;     {"Дата маршрутизирования"}
    ReservPay         : word;        {"Признак использования резерва"}
    Akcept            : word;
    MenuItem          : word;
    indate            : longint;
    WorkStr           : String[2];   {"Резерв"}
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
    OperNum  : longint;     {"Номер операции"}
    Status   : word;        {"Статус", 0 - PayOrder}
                            {          1 - MemOrder}
                            {          2 - CashOrder}
                            {          3 - UnkDocN}
                            {          4..6 - CashOrder(Another Info)}
                            {          >=32000 - на усмотрение пользователей}
    Comment  : String[254]; {"Комментарий"}
    ComOwner : word;        {"Владелец комментариев"}
    Comment1 : String[254]; {"Комментарий1"}
  end;

const
  tiPayCom1 = 0; {OperNum(Seg),Status}
  tiPayCom2 = 1; {OperNum(Seg),Status(Seg),ComOwner}
  tiPayCom3 = 2; {OperNum(Seg),ComOwner}

type
  PAccounts = ^TAccounts;
  TAccounts = packed record
    AccNum             : string[10];   {"Номер лицевого счета"}
    AccPlch            : string[3];    {"Счет 2 порядка"}
    AccName            : string[48];   {"Наименование лицевого счета"}
    ClientCode         : longint;      {"Код клиента"}
    AccStatus          : word;         {"Статус счета", 7-Временный, 8-Действующий,}
                                       { 9-Арестованный(Блок. дебет), 10-Блокированный}
    Open_Close         : word;         {"Статус счета открыт/закрыт"}
    CurrCode           : string[3];    {"Код валюты"}
    OpenDate           : longint;      {"Дата открытия счета"}
    CloseDate          : longint;      {"Дата закрытия,ареста,блокировки счета"}
    OperNum            : longint;      {"Номер операциониста"}
    ContNum            : string[9];    {"Номер договора"}
    RightBuffer        : array[0..252] of char; {"Права на счет"}
    ChSum              : word;         {"Проверочная сумма"}
    ClientMessage      : string[188];  {"Сообщение клиенту"}
    ValueCode          : longint;      {"Код ценности"}
    AccEndDate         : longint;      {"Дата погашения суммы"}
    DayCount           : word;         {"Срок в днях"}
    AccNewPlch         : longint;      {"Новый счет 2 порядка"}
    NewAccNum          : String[22];   {"Новый номер счета"}
    ShifrMask          : String[20];   {"Шифр счета"}
    UserGroupCode      : longint;      {"Код группы"}
    Priority           : word;         {"Приоритет счета", 0 - общедоступный,}
                                       { 1 - доступен только гол.конторе,}
                                       { 2 - доступен гол.конторе и отделению DivCode}
    DivCode            : word;         {"Код отделения", имеет смысл лишь при Priority=2}
    OwerContNum        : String[9];    {"Номер договора на овердрафт"}
    ReAccPr            : word;         {"Признак переоценки"}
    ReAccount          : string[10];   {"Счет переоценки"}
    RedCheck           : word;         {"Контроль на красное сальдо"}
    AccSort            : string[12];   {"Номер счета для сортировки"}
    AccCourse          : double;       {"Курс счета"}
    KindCont           : word;         {"Тип договора"}
    KindAcc            : byte;         {"Тип счета", 0-А/П 1-А 2-П}
    KindSaldo          : byte;         {"Тип сальдо", 0-несальдируемый 1-сальдируемый}
    OraF_ID_Filial     : word;         {"Код филиала"}
    WayOfExt           : word;         {"Порядок выдачи выписок"}
    PerAmount          : word;         {"Периодичность выдачи выписок (кол.)"}
    PerType            : word;         {"Периодичность выдачи выписок (тип)"}
    AccCode            : longint;      {"Уникальный ключ"}
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
    ClientCode    : longint;      {"Код владельца счета"}
    ClientName    : string[254];  {"Владелец счета",  //str48}
    Byte255a      : byte;         {"255-й байт"}
    ShortName     : string[80];   {"Краткое имя клиента",   //str32}
    Adress        : string[48];   {"Краткий адрес владельца счета"}
    Telephone     : string[32];   {"Телефон"}
    HasModem      : word;         {"Наличие модема"}
    PrizJur       : word;         {"Признак ЮРИДИЧЕСКОЕ или ФИЗИЧЕСКОЕ лицо"}
    PropertyCode  : string[3];    {"Код формы собственности"}
    CodeOKPO      : string[9];    {"Код ОКПО"}
    RegisSer      : string[6];    {"Государственная регистрация: серия"}
    RegisNum      : string[15];   {"Государственная регистрация: номер", //str12}
    RegisDate     : longint;      {"Государственная регистрация: дата"}
    RegisLocation : string[60];   {"Государственная регистрация: место", //str48}
    TaxNum        : string[15];   {"Номер налогоплательщика",//ИНН}
    TaxDate       : longint;      {"Налоговая инспекция: дата"}
    TaxNumGNI     : string[15];   {"Налоговая инспекция: номер ГНИ", //str10}
    TaxLocation   : string[60];   {"Налоговая инспекция: место", //str48}
    Pasport       : string[48];   {"Кем выдан паспорт"}
    BankNum       : string[9];    {"Код банка"}
    PayAccOld     : string[15];   {"Счет в банке Old"}
    ClType        : word;         {"Код из классификатора клиентов"}
    Rezident      : word;         {"Признак резидент , 0-рез-т, 1-не рез-т"}
    CoClientClass : byte;         {"Код класса клиента"}
    CoClientType  : byte;         {"Код типа клиента"}
    CuratorCode   : longint;      {"Куратор"}
    F775          : String[3];    {"Символ ф.775"}
    ShifrMask     : String[20];   {"Шифр Клиента"}
    HasVoice      : word;         {"Наличие Информационно-Речевой системы"}
    COPF          : String[2];    {"Код Правовая форма (КОПФ)"}
    COATO         : String[12];   {"Код СОАТО"}
    CountryCode   : String[2];    {"Код страны"}
    PayAcc        : TExtAcc;      {"Счет в банке"}
    ClFromOffice  : word;         {"Клиент филиала (1-да)"}
    DocType       : string[2];    {"Тип удостоверения"}
    SerPasp       : string[10];   {"Серия предъявленного документа"}
    NumPasp       : string[20];   {"Номер предъявленного документа"}
    DatePasp      : longint;      {"Дата выдачи паспорта"}
    ReasCode      : String[9];    {"Код причины постановки на учет"}
    TaxDocType    : string[48];   {"Подтверждение учета в налоговом органе"}
                                  {// Вид и реквизиты документа, удостоверяющего факт}
                                  {// постановки лица на учет в налоговом органе}
    UserCode      : longint;      {"Ответственный исполнитель"}
    WorkStr       : String[1];    {"Резерв"}
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
    BankNum      : string[9];   {Номер банка в новой системе (МФО-9)}
    Mfo          : string[6];   {Старый номер МФО (МФО-6)}
    RkcNum       : string[9];   {BankNum РКЦ}
    BankTaxNum   : string[10];  {Инн банка}
    CorrAccOld   : string[10];  {Коррсчет банковского учр в РКЦ Old}
    BankType     : word;        {Код типа банковского учреждения (table)}
    TypeAbbrev   : string[4];   {Тип банковского учреждения (Сокр.)}
    BankName     : string[128]; {Название банковского учреждения}
    PostInd      : string[6];   {Почтовый индекс}
    RegionNum    : word;        {Регион (table)}
    Adress       : string[64];  {Адрес (тип нас.пункта+имя нас.пункта)}
    Street       : string[64];  {Улица+дом}
    Telephone    : string[25];  {Телефон(ы)}
    Telegraph    : string[14];  {Абонентский телеграф(ы)}
    Srok         : byte;        {Срок прохождения документов (дней)}
    ElUch        : byte;        {Участие в электронных расчетах 0-нет, 1-да}
    Okpo         : string[8];   {Код ОКПО}
    UchCode      : string[3];   {Код участника прямых расчетов}
    RegistrNum   : string[9];   {Регистрационный номер}
    Licence      : word;        {Лицензия}
    MfoCont      : string[20];  {Мфо+конт}
    NumInUse     : string[20];  {Используемый код банка}
    WhichBankNum : word;        {Используемый номер банка}
                                {0-Мфо, 1-Участник, 2-Номер, 3-Мфо + конт}
    UchFlag      : word;        {0-не участник, 1-участник прямых расч}
    Vkey         : String[8];   {Служебная}
    BankCorrAcc  : TExtAcc;     {Корреспондентский сч.банка}
    CorrAcc      : TExtAcc;     {Коррсчет банковского учр в РКЦ}
    Sks          : string[6];
  end;

{ Тип базы }
const
  btDoc        =  0;
  btArc        =  1;

{ Состояние счета }
const
  asLocks      = $1C0;
  asLockDt     = $40;
  asLockCr     = $80;
  asLockCl     = $100;

implementation

end.

