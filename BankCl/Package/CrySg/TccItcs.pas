{******************************************************************}
{                                                                  }
{ Borland Delphi Runtime Library                                   }
{ Domen-K cryptographic interface unit                             }
{                                                                  }
{ 2003(fw) CB Transcapitalbank, Perm, Russia                       }
{ Written by Michael Galyuk, support@transcapbank.perm.ru          }
{                                                                  }
{ Software distributed under the License is distributed on an      }
{ "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or   }
{ implied.                                                         }
{                                                                  }
{ КОД РАСПРОСТРАНЯЕТСЯ ПО ПРИНЦИПУ "КАК ЕСТЬ", НИКАКИХ             }
{ ГАРАНТИЙ НЕ ПРЕДУСМАТРИВАЕТСЯ, ВЫ ИСПОЛЬЗУЕТЕ ЕГО НА СВОЙ РИСК.  }
{ АВТОР НЕ НЕСЕТ ОТВЕТСТВЕННОСТИ ЗА ПРИЧИНЕННЫЙ УЩЕРБ СВЯЗАННЫЙ    }
{ С ЕГО ИСПОЛЬЗОВАНИЕМ (ПРАВИЛЬНЫМ ИЛИ НЕПРАВИЛЬНЫМ).              }
{                                                                  }
{******************************************************************}

unit TccItcs;

interface

uses
  Windows, SysUtils, CryptA, Classes, StrUtils;

const
  e_NO_ERROR               = 0;     // There was no error.
  e_NO_KEY_DISK_FOUND      = 1;     // Key diskette was not found.
  e_WRONG_PASSWORD         = 2;     // The entered password is not right.
  e_DIR_INACCESSIBLE       = 3;     // The directory is not accessible.
  e_FILE_NOT_FOUND         = 4;     // The specified file not found.
  e_FILE_READ_ERROR        = 5;     // Error  while reading file.
  e_FILE_WRITE_ERROR       = 6;     // Error while writing into file.
  e_DISTORTION             = 7;     // Decrypting or imito check detected distortion.
  e_DIR_NOT_FOUND          = 8;     // The directory was not found.
  e_LIMIT_PASSWORD         = 9;     // Invalid passwords are limited
  e_ENTER_PASS_REJECT     = 10;    // The user refused from entering password.
  e_NO_ENTER_PASS        = 11;    // The password was not entered.
  e_MESS_NOT_KVITTED     = 12;    // The specified message was not kvitted.  It is not an error.
  e_MESS_DELIVERED       = 13;    // The specified message was delivered to recipient. It is not an error.
  e_MESS_USED            = 14;    // The message was used (read, printed, etc.) by recipient. Not an error.
  e_UNMATCHED_KVIT       = 15;    // No registered sent message corresponding to received kvit.
  e_NO_MEM               = 16;    // Not enough memory.
  e_FILE_OPEN_ERROR      = 17;    // Error while opening file.
  e_INVALID_DIR          = 18;    // Directory can not have such name.
  e_FILE_INACCESSIBLE    = 19;    // Access to file denied.
  e_FILE_CLOSE_ERROR     = 20;    // Error while closing file.
  e_SEEK                 = 21;    // Error while positioning in file.
  e_WRONG_FILE_STRUCT    = 22;    // Wrong structure of structured file.
  e_WRONG_ABN_FILE_STRUCT= 23;    // Wrong structure of file *.abn.
  e_WRONG_APN_FILE_STRUCT= 24;    // Wrong structure of file *.apn.
  e_WRONG_GLUE_FILE_STRUCT =25;    // Wrong structure of glued file.
  e_SRV_ID_NOT_FOUND     = 26;    // The file nodename.doc not maintaining the server ID for given AP, but this ID must be present
  e_AP_ID_NOT_FOUND      = 27;    // The searching ID of the Abonent Point was not found
  e_INCORRECT_PARAMS     = 28;    // Function received incorrect parameters.
  e_INVALID_PASSWORD_LEN = 29;    // Password too long or too small.
  e_INVALID_ID_LEN       = 30;    // Identifier has wrong length.
  e_DIR_EMPTY            = 31;    // Directory is empty but it should not be such.
  e_KEY_NOT_FOUND        = 32;    // Desired key (of any type) was not found.
  e_ABN_ID_LEN           = 33;    // The specified length of the ID of abonent, that we need to make Key Disk, is wrong
  e_ABN_NAME_LEN         = 34;    // The specified length of the abonent name is wrong
  e_DISK_FULL            = 35;    // Not enough disk space.
  e_UNKNOWN_ERROR        = 36;    // The returned value does not correspond to any code.
  e_OUT_OF_RANGE         = 37;    // Index is beyond proper bounds.
  e_WRONG_ID_TYPE        = 38;    // function received identifier of not proper type.
  e_DIFF_ABN_IDENTS      = 39;    // The file NNNNAAAA.abn maintain the abonent ID, that differs from NNNNAAAA
  e_REPETION_OF_RAND     = 40;    // The random number has repeted.
  e_ATTR_ERROR           = 41;    // File's (dir's) attr. can't be received or set.
  e_INIT_NOT_MADE        = 42;    // Is used to turn off initialization of any kind or when creating an object without initialization.
  e_DELETE_FILE          = 43;    // Error while deleting file
  e_RENAME_FILE          = 44;    // Error while renaming file
  e_FILE_SIZE            = 45;    // Error while  get file size
  e_EMPTY_ABONENT        = 46;    // Count abonent is empty
  e_COMPRESS_ERROR       = 47;    // Error while process compressing
  e_DECOMPRESS_ERROR     = 48;    // Error while process decompressing
  e_NO_FLAG_INFOTECS     = 49;    // No flag infotecs ( ITCS )
  e_ERROR_COPY_STRING    = 50;    // Error while coping string
  e_FILE_INFO            = 51;    // Get file info ( date, time, attributes ...)
  e_FIND_FILE            = 52;    // Error while finding file
  e_FULL_PATH            = 53;    // Error can't get full path ( not file or other error )
  e_FILE_OFFSET          = 54;    // Error can't get offset in the file
  e_BAD_FILE_NAME        = 55;    // File name of envelope must be @*******.***; Receipt N|D|R******.***
  e_BAD_VERSION_ENVELOPE = 56;    // Bad version envelope
  e_NO_ENVELOPE          = 57;    // No Envelope
  e_BAD_KEY              = 58;    // Bad key
  e_BAD_HEADER_ENVELOPE  = 59;    // Bad header of envelope
  e_SET_WORK_DIR         = 60;    // Can't seting working directory
  e_CREATE_DIR           = 61;    // Error while creating directory
  e_DEL_DIR              = 62;    // Error while deleting directory
  e_ERROR_CREATE_FILE    = 63;    // Error while creating file
  e_COPY_FILE_ERROR      = 64;    // Error while coping  file.
  e_ABN_NOT_REGISTERED   = 65;    // The abonent is not registered at the given AP
  e_IS_NOT_PACKAGE             = 66; // This not package
  e_DOCUMENT_NOT_FOUND         = 67; // Document not found
  e_LIST_OF_DOCUMENT_IS_EMPTY  = 68; // Document list is empty
  e_FILE_UNPACK                = 69; // Can't unpack file
  e_FILE_PACK                  = 70; //  Can't file pack
  e_INVALID_HANDLE             = 71; // Invalid handle ( pointer to CKeyDisk )
  e_INVALID_CRYPTFILE_SIGNATURE= 72; // signature not equal 'CrYpT'
  e_UNKNOWN_CRYPT_METHOD       = 73; // only GOST crypting allowed
  e_FILE_CORRUPTED             = 74; // File is corrupted
  e_RECEIPT_TYPE_UNKNOWN       = 75; // Unknown type of receipt
  e_NO_RECEIPT                 = 76; // No receipt
  e_IS_ENVELOPE                = 77; // This envelope
  e_BAD_VERSION_RECEIPT        = 78; // Bad wersion receipt
  e_NOT_DEFINED_ADDRESS_RECEIVER = 79; // Denied adress receiver
  e_NOT_DEFINED_ADDRESS_SENDER = 80; // Denied adress sender
  e_LONG_NAME_DIR              = 81; // Is long name of directory
  e_WRONG_NUM_OF_PARAMS        = 82; // Exe-file receives wrong number of parameters.
  e_DB_CONTROL                 = 83;   // Error database
  e_DB_FULL                    = 84;   // Database is full
  e_DB_REC_NOT_FOUND           = 85;   // Record not found
  e_DOC_IS_REMOVE              = 86;   // Document was removed
  e_ADDR_SENDER                = 87;   // Invalid sender address
  e_ADDR_RECIEVER              = 88;   // Invalid receiver address
  e_ALREADY_PACKED             = 89;   // Document is already packed
  e_DOC_NOT_FOUND              = 90;   // Document not found
  e_PUT_HDR_ENV                = 91;   // Error header envelope writing
  e_GET_HDR_ENV                = 92;   // Error header envelope reading 
  e_DEL_HDR_ENV                = 93;   // Error header envelope removing
  e_SHIFR_FILE                 = 94;   // Encrypt file error 
  e_DESHIFR_FILE               = 95;   // Decrypt file error
  e_IMITO_FILE                 = 96;   // Imito file error
  e_ABONENT_NOT_FOUND          = 97;   // The specified abonent ID or Name is not found
  e_CHIEF_SIGN_NOT_VALID       = 98;   // The Sign of the Chief abonent in NNNN_spr.sgn is not valid
  e_ALREADY_SIGNED_BY_ABN      = 99;   // A file or memory already signed by specified abonent
  e_NO_TASK                   = 100;   // Envelope is assign for another task application
  e_RECEIVER_NOT_FOUND        = 101;   // The specified workgroup absent in address book
  e_DB_TABLE_OPEN             = 102;   // Error open DB Table
  e_DB_TABLE_READ             = 103;   // Error read table to list
  e_DB_TABLE_EDIT             = 104;   // Error update DB table record
  e_WRONG_OBJ_CMP_PARAMS      = 105;   // The parameters of objrcts to com-pare are not matched or wrong.
  e_UNSUITABLE_RIGHTS         = 106;   // The user rights are not suitable for some operation
  e_OVERDUE                   = 107;   // Some time period is overdue (or taken out from using )
  e_WRONG_OPERATION           = 108;   // Some operation is wrong
  e_BRANCH_NEXT_ELEM          = 109;   // Branch to next element
  e_FILE_READ_TREC            = 110;   // Error read special file
  e_PACKAGE_READ_HEADER       = 111;   // Read error package's header
  e_PACKAGE_READ_DOCUMENT     = 112;   // Read error package's document
  e_MASTERS_NOT_MATCH         = 113;   // The numbers of masters are not mathing
  e_NO_NET_MASTERS            = 114;   // No any net masters for generation
  e_NOT_IMPLEMENTED           = 115;   // Function not implemented
  e_FIND_FILE_COMPLETE        = 116;   // End of files searching
  e_INVALID_IMPLEMENTATION    = 117;   // Function not implemented in some case
  e_CUR_POS_FILE              = 118;   // CurPos () failed
  e_CHANGE_SIZE_FILE          = 119;   // Truncate () failed
  e_FLUSH_FILE                = 120;   // Flush () failed
  e_FILE_ALREADY_EXIST        = 121;   // File already exist
  e_SET_FILE_TIME             = 122;   // Set file time
  e_GET_FILE_TIME             = 123;   // Get file time
  e_FILE_MOVE_ERROR           = 124;   // File move error
  e_USE_GETLASTERROR          = 125;   // Use GetLastError
  e_GET_DISK_FREE_OR_TOTAL    = 126;   // Get disk free or total
  e_STREAM_END                = 127;   //end of stream was reached
  e_NEED_DICT                 = 128;   //preset dictionary needed
  e_ERRNO                     = 129;   //error occurred in the file system ,  you may consult errno    to get the exact error code.
  e_STREAM_ERROR              = 130;   //the stream state was inconsistent (for example  if next_in or next_out was NULL)
  e_DATA_ERROR                = 131;   //the input data was  corrupted
  e_BUF_ERROR                 = 132;   //no progress is possible or if there was not enough room in the output buffer
  e_VERSION_ERROR             = 133;   //the library version is incompatible with the   version assumed by the caller
  e_BAD_FILE_STRUCTURE        = 134;   //The file struct unexpected
  e_WRONG_NET_NUMBER          = 135;   //The network number is incorrect
  e_WRONG_VERSION             = 136;   //The version is incorrect
  e_WRONG_APP_TYPE            = 137;   //The task number is incorrect
  e_CHIEF_NOT_FOUND           = 138;   // The Chief abonent is not found in NNNN.chf
  e_WS_NOT_REGISTERED         = 139;   // The WS is not registered for this task
  e_DOCUMENT_NOT_SIGNED       = 140;   // The document not signed
  e_CHECK_SIGN                = 141;   // Error during checking sign
  e_NOT_INSTALLED             = 142;   // Something not installed
  e_ALREADY_DONE              = 143;   // Some operation already done.
  e_DRIVE_NOT_READY           = 144;   // Drive not ready
  e_COPYING_OLDER_FILES       = 145;   // Occuring in trying to copy the files with create time less then existing
  e_LOADLIBRARY               = 146;   // Error during LoadLibrary
  e_GETPROCADDRESS            = 147;   // Error during GetProcAddress
  e_ABORTED_BY_USER           = 148;   // An operation has been cancelled by user
  e_PREMATURE_OPERATION       = 149;   // The premature operation, Check Your system time, please.
  e_INCORRECT_SETTINGS        = 150;   // The settings are incorrect.
// ------ Added for the project of DirCrypt ------ 01.10.98
  e_CRYPTED_ANOTHER_SER         = 151; // Crypted another ser
  e_CRYPTED_THIS_SER_ANOTHER_PASS = 152; // Crypted this ser another pass
  e_CRYPTED_THIS_SER_THIS_PASS  = 153; // Crypted this ser this pass
  e_NO_CRYPTED                  = 154; // No crypted
  e_CRYPTED_ANOTHER_MODE        = 155; // Crypted another mode
// ----------------------------------------------------
  e_CAN_NOT_DO_OPERATION        = 156; // The operation can not be executed
  e_IDS_ARE_COINCIDE            = 157; // the IDs are coincide (the same or something else)
  e_IDS_ARE_NOT_COINCIDE        = 158; // the IDs are not coincide (different or something else)
  e_WAS_UNDO_OPERATION          = 159; // Not an error, but UNDO was encountered cause of the some error or the cancel be user
// ----------------------------------------------------
  e_ACK_BAD_STATUS              = 160;  // transport receipt has not allowed status
  e_DIFFERENT_IMITO_KEY         = 161;  // different imito key
  e_DIFFERENT_IMITO_HEADER      = 162;  // different imito header
  e_DEIMITO_FILE                = 163;  // deimito file error
  e_DISABLE                     = 164;  // Aplication disabled
  e_LOCKIPTRAFFIC               = 165;  // IP-traffic was locked
// ------ Added for the project of Aladdin ------ 26.10.2000
  e_ADR_CALLBACK_FUNCTION       = 170;  // Error address Callback Function
  e_INVALID_DEVICE_CODE         = 171;  // Invalid code of device
  e_ABORT_WAIT_CHECK_READY_DEVICE = 172;  // Aborted wait fo device
  e_CREATE_OBJECT_ALTERNATE_DEVICE = 173; // Error create object of device
  e_DRIVER_OR_DEVICE_NOT_INSTALLED = 174; // Driver or device not installed
  e_READING_INFO_DEVICE         = 175;  // Reading Mistake ID key
  e_WRONG_SLOT_OF_DEVICE        = 176;  // Wrong slot of device
  e_UNDEFINED_FUNCTION          = 177;  // Undefined function
  e_KEY_NOT_INSERTED_IN_DEVICE  = 178;  // Key not inserted in device
  e_READING_FROM_DEVICE         = 179;  // Error reading from device
  e_WRITING_TO_DEVICE           = 180;  // Error writing to device
  e_PARAM_LENTGH_READING_OR_WRITING = 181; // Error lentgh reading or writing
  e_CHIEF_SIGN_DATA             = 182;  // Error data of chief sign
  e_INVALID_FILE_NAME            = 183;  // Wrong file name
// { 19.03.2001
  e_REGOPENKEY                  = 184;   // Error during RegOpenKey
  e_REGQUERYVALUEEX             = 185;   // Error during RegQueryValueEx
  e_SWITCHDESKTOP               = 186;   // Error during SwitchDesktop
  e_SYSTEMPARAMETRSINFO         = 187;   // Error during SystemParametersInfo
  e_CREATEWINDOWEX              = 188;   // Error during CreateWindowEx
  e_LOCKERUI_BUSY               = 189;   // Unlock impossible - Locker Busy
  e_CREATEDESKTOP               = 190;   // Error during CreateDesktop
  e_CREATETHREAD                = 191;   // Error during CreateThread
// } 19.03.2001
// { 16.05.2001
  e_SIGN_NOT_ALLOWED            = 192;   // The user has no right to sign
// } 16.05.2001
  e_ABONENT_WAS_REMOVED         = 193;   // The user was removed from VPN
// { 04.09.2001
  e_NOT_FOUND                   = 194;   // Missing (arbitrary) object
  e_ALREADY_EXISTS              = 195;   // (Arbitrary) object already exists
// } 04.09.2001
// { 08.11.2001
  e_MISSING_ATTACHMENT          = 196;   // Missing attachment file
// } 08.11.2001
// { 27.12.2001
  e_MAIL_TOO_LARGE              = 197;   // Mail size is beyond message store size limit
// } 27.12.2001
  e_ALTERDEV_ERROR              = 198;   // Error in function of processing alternative devices data storage
  // 6.02.2002
  e_SAVE_TO_REG                 = 199;   //Save CSP defence  key to reg
  // 07.03.2002
  e_AP_CHIEF_SIGN_CREATION      = 200;   // The chief subscriber tryes to create the new digital signature on the AP
  e_NON_MAIN_AP_SIGN_CREATION   = 201;   // The subscriber tryes to create the new digital signature on the nonprime AP
  e_CERT_IS_NOT_VALID           = 202;   // A required certificate is not valid.
  e_CERT_E_EXPIRED              = 203;   // A required certificate is not within its validity period.
  // 25.04.2002 (for the version compatibility)
  e_SIGN_FORMAT_INCOMPATIBLE    = 204;   // The current user sign certificate is incompatible with the format of the signed file.

  // Определения максимальных длин идентификатора, имени и псевдонима пользователя
  _MAX_USER_ID_SIZE = 8;
  _MAX_USER_NAME_SIZE = 70;
  _MAX_USER_ALIAS_SIZE = 80;

  // Флаги инициализации криптопровайдера
  EXT_EXTERNAL_KEY_STORAGE = $00000001;     // Флаг для указания использование внешних сертификатов
  EXT_SILENT_MODE = $00000002;     // Флаг для указания режима, неиспользующего интерфейс с пользователем.
  EXT_FORCE_SAVE_PASSWORD = $00000004;    // Флаг, который указывает, что
    // введенный пароль необходимо сохранить в реестре. Если этот флаг не указан, то
    // возможность сохранить пароль будет зависеть от последней соответствующей настройки.
    // Данный флаг игнорируется, если установлен любой из следующих флагов:
    // EXT_EXTERNAL_KEY_STORAGE, EXT_SILENT_MODE

  // Флаги для указания типа данных для функций подписи / шифрования
  EXT_FILE_DATA_FLAG = $00000001;    // Флаг для указания файла в качестве типа данных

  // Флаги для указания особенностей работы подписи
  EXT_MULTIPLE_SIGN         = $00000001;    // Множественная подпись
  EXT_PKCS7_SIGN            = $00000002;    // Подпись в формате PKCS7,
    // этот флаг автоматически используется, когда задан EXT_EXTERNAL_KEY_STORAGE
    // при инициализации провайдера
  EXT_RETURN_CONTROL_INFO   = $00000010;    // Указывает, что необходимо
    // вернуть контрольную информацию при проверке подписи

  EXT_SMARTCARD_CONTAINER  = 'DEV|200|ITCS_SGN|'; // Имя контейнера  "ASE Card Reader"

  EXT_ETOKEN_CONTAINER    = 'DEV|300|ITCS_SGN|';  // Имя контейнера E-token

  EXT_SCANTECH_CONTAINER   = 'DEV|600|ITCS_SGN|'; // Имя контейнера ScanTech Reader

type
  // LPCALLBACK_ROUTINE - указатель на тип callback функции, определяемой
  // на прикладном уровне и используемой функциями EXT_Sign, EXT_VerifySign,
  // EXT_VerifyViewSignResult, EXT_Encrypt и EXT_Decrypt.
  // Функция такого типа вызывается, когда заканчивается обработка очередной
  // порции данных. Если функция возвращает FALSE, то процесс обработки
  // информации прекращается, а вызываемая функция (EXT_Sign, EXT_Encrypt (и.т.д)
  // вернет код возврата e_ABORTED_BY_USER.
  LPCALLBACK_ROUTINE = function(TotalUnits: Int64; UnitsProcessed: Int64;
    lpCallBackData: Pointer): Boolean;

  // -------------------------------------------------------------------------
  // Структура EXT_PATHNAMES предназнгачена для передачи месторасположения
  // ключевой информации
  //
  // Элемент                    Описание
  // m_pszKeyDisketteDirectory    Путь к каталогу с ключами абонента, например,
  //                                 "A:" или "C:\VipNet"
  // m_pszTransportDirectory      Путь к каталогу со справочниками (транспортными
  //                                 справочниками Абонентского Пункта)
  // -------------------------------------------------------------------------
  EXT_PATHNAMES = packed record
    m_pszKeyDisketteDirectory: PChar;
    m_pszTransportDirectory: PChar;
  end;

  // -------------------------------------------------------------------------
  // Структура EXT_FULL_CONTEXT предназнгачена для создания контекста
  // криптопровайдера и обращения посредством его к криптографическим функциям
  // Элемент          Описание
  // version          Внутренняя версия СКЗИ "Домен-К". Зарезервировано
  // hParent          Дескриптор родительского окна (прикладной программы)
  // dwFlags          Флаги, управляющие работой функции инициализации.
  //                  Зарезервировано. Должен быть выставлен в 0;
  // pKeyStorage      Указатель на структуру EXT_PATHNAMES, содержащую пути
  //                  к каталогам с ключами и справочниками
  // pProviderName    Зарезервировано
  // pProviderError   Код (и/или сообщение) ошибки низкоуровневого
  //                  криптографического API
  // pCryptoProvider  Внутренняя криптографическая структура библиотеки
  // -------------------------------------------------------------------------
  PEXT_FULL_CONTEXT = ^EXT_FULL_CONTEXT;
  EXT_FULL_CONTEXT = packed record
     Version: dWord;
     hParent: hWnd;
     dwFlags: dWord;
     pKeyStorage: PChar;
     pProviderName: PChar;
     pProviderError: PInteger;
     pCryptoProvider: Pointer;
  end;

  PEXT_CALLBACK_DATA = ^EXT_CALLBACK_DATA;
  EXT_CALLBACK_DATA = packed record
     lpCallBackRoutine: LPCALLBACK_ROUTINE;
     lpCallBackData: Pointer;
  end;

  // -------------------------------------------------------------------------
  // Структура EXT_SIGN_RESULT предназначена для хранения результата проверки
  // одной подписи под данными.
  //
  // Элемент               Описание
  // CertResult            Результат проверки достоверности сертификата
  // SignResult             Результат проверки подписи под данными
  //
  // -------------------------------------------------------------------------
  PEXT_SIGN_RESULT = ^EXT_SIGN_RESULT;
  EXT_SIGN_RESULT = packed record
    CertResult: dWord;
    SignResult: dWord;
  end;

  // -------------------------------------------------------------------------
  // Структура EXT_SIGN_CONTEXT предназначена для создания контекста подписи
  //
  // Элемент               Описание
  // pData                 Данные для подписи/проверки подписи
  // DataLen               Количество байт данных для подписи/проверки подписи
  // DataType              Тип данных, которые нужно подписать.
  //                       (Например, память или файл и т.д.)
  // Flags                 Флаги для работы функций подписи/проверки подписи 
  //                       (зарезервировано)
  // pFunctionContext      Указатель на контекст, определяющий специфику работы
  //                       функций подписи, проверки подписи. Зарезервировано.
  //                       Должен быть выставлен в NULL.
  // SignaturesNum         Количество подписей (на данный момент
  //                       всего одна подпись). Используется при проверке подписи,
  //                       полуении информации по подписям.
  // pSignaturesData       Указатель на область памяти, содержащую результат 
  //                       подписи. Используется при подписи. Если pSignaturesData
  //                       не выставлен в NULL, считается, что по данному адресу
  //                       находится сигнатура предыдущей подписи, и необходимо
  //                       добавить еще одну. При этом память по указанному адресу
  //                       освобождается, а новая - захватывается.
  //                       Необходимо выставлять NULL, пока не реализовано 
  //                       множественное подписывание.
  // SignaturesDataLen     Размер области памяти, содержащей
  //                       результат подписи. Используется при подписи.
  // pSignaturesResults   Указатель на массив с результатами подписей. Количество
  //                       элементов массива = *pSignaturesNum. Каждый элемент
  //                       представляет собой структуру EXT_SIGN_RESULT.
  //                       Используется при проверке подписи и  просмотре 
  //                       результатов проверки подписи.
  //                       Память выделяется внутри функции проверки подписи 
  //                       и обязана быть освобождена прикладной программой,
  //                       после того как отпадает надобность в этих данных, 
  //                       с помощью функции EXT_FreeMemory
  // ResultsSize           Длина массива с результатами проверки 
  //                       подписей. Используется при проверке подписи.
  // pControlInfo          Указатель на дополнительную информацию, которая
  //                       может понадобиться для последующей проверки подписи
  //                       (например, HASH от подписанных данных и т.п.).
  //                       подписей. Данный указатель используется при проверке
  //                       подписи и просмотре результатов проверки подписи. 
  //                       Память захватывается внутри функции. Параметр является
  //                       необязательным, поэтому, если вызывающая функция желает
  //                       получать данную информацию, необходимо при проверке 
  //                       подписи (EXT_VerifySign) установить битовый флаг Flags
  //                       EXT_RETURN_CONTROL_INFO.
  // ControlInfoSize       Размер дополнительной информации,
  //                       найденной при проверке подписи.
  //                       подписей. Используется при проверке подписи и просмотре
  //                       результатов проверки подписи.
  // -------------------------------------------------------------------------
  PEXT_SIGN_CONTEXT = ^EXT_SIGN_CONTEXT;
  EXT_SIGN_CONTEXT = packed record
    pData: Pointer;
    DataLen: dWord;
    DataType: dWord;
    Flags: dWord;
    pFunctionContext: Pointer;
    SignaturesNum: dWord;
    pSignaturesData: Pointer;
    SignaturesDataLen: dWord;
    pSignaturesResults: {array of EXT_SIGN_RESULT;}Pointer;
    ResultsSize: dWord;
    pControlInfo: Pointer;
    ControlInfoSize: dWord;
  end;

  // -------------------------------------------------------------------------
  // Структура EXT_SIGNATURE_CONTEXT предназначена для создания контекста,
  // содержащего данные ЭЦП
  //
  // Элемент          Описание
  // pCertificate     Указатель на _CRYPTOAPI_BLOB, - структуру,
  //                  содержащую кодированный сертификат;
  // CertificateLen   Длина данных, содержащих кодированный 
  //                  сертификат;
  // pSignerInfo      Указатель на _CMSG_SIGNER_INFO, - структуру, содержащую 
  //                  данные с информацией о подписавшем абоненте;
  // SignerInfoLen    Длина данных, содержащих информацию о 
  //                  подписавшем абоненте
  // -------------------------------------------------------------------------
  PEXT_SIGNATURE_CONTEXT = ^EXT_SIGNATURE_CONTEXT;
  EXT_SIGNATURE_CONTEXT = packed record
    pCertificate: Pointer;
    CertificateLen: dWord;
    pSignerInfo: Pointer;
    SignerInfoLen: dWord;
  end;

  // ---------------------------------------------------------------
  //                            EXT_CRYPT_DATA
  // ---------------------------------------------------------------
  // Элемент               Описание
  //
  // pInputData            Входные данные. При шифровании это plaintext,
  //                       при расшифровании - cryptotext.
  //                       Если тип данных (DataType) - файл, то pInputData -
  //                       имя входного файла;
  // InputDataLen          Размер входных данных. Если зашифровывается
  //                       (расшифровывается) файл, то можно указать -1L, если
  //                       необходимо зашифровать файл полностью;
  // pOutputData           Выходные данные. При шифровании это cryptotext, 
  //                       при расшифровании - plaintext.
  //                       Если тип данных (DataType) - файл, то pInputData - 
  //                       имя выходного файла. Имя выходного файла может 
  //                       совпадать с именем входного файла, тогда выходной 
  //                       файл будт перезаписан поверх входного.
  //                       Если тип данных (DataType) - область памяти, то
  //                       функция зашифрования/расшифрования выделит память под
  //                       выходные данные. После того, как отпала необходимость
  //                       в этих данных, память должна быть освобождена 
  //                       функцией EXT_FreeMemory();
  // OutputDataLen         Размер выходных данных. В OutputDataLen будет возвращеен 
  //                       размер выходной информации при зашифровании/расшифровании
  //                       области памяти.
  //                       Этот размер можно также использовать при освобождении 
  //                       памяти, которая была выделена в результате отработки
  //                       функции зашифрования/расшифрования области памяти.
  // DataType              Тип зашифровываемых/расшифровываемых данных. 
  //                       Это может быть область памяти или файл.
  // Flags                 Флаги шифрования. Зарезервировано. Параметр должен быть 
  //                       выставлен в 0UL;
  // pReceivers            При расшифровании данных это "C-шная" строка с 
  //                       идентификатором получателя, для которого осуществляется
  //                       расшифрование.
  //                       При использовании в функциях зашифрования и получения 
  //                       списка получателей, данный параметр является списком
  //                       получателей для которых были зашифрованы данные.
  //                       Список идентификаторов представляет собой 
  //                       последовательность "C-шных" строк, разделенных '\0'. 
  //                       Последний получатель заканчивается двумя '\0'.
  //                       При вызове функции получении списка получателей по
  //                       данному адресу будет выделена память, и
  //                       после того, как отпала необходимость в хранении 
  //                       данного списка память должна быть освобождена
  //                       функцией EXT_FreeMemory().
  // ReceiversBytesNum     Размер списка получателей в байтах, включая 
  //                       заключительные '\0''\0'. 
  //                       Используется при вызове функции получения списка
  //                       получателей зашифрованного файла.
  //                       Этот размер можно использовать при освобождении памяти,
  //                       которая была выделена в результате отработки функции
  //                       получения списка получателей зашифрованного файла.
  // ---------------------------------------------------------------
  PEXT_CRYPT_CONTEXT = ^EXT_CRYPT_CONTEXT;
  EXT_CRYPT_CONTEXT = packed record
    pInputData: Pointer;
    InputDataLen: dWord;
    pOutputData: Pointer;
    OutputDataLen: dWord;
    DataType: dWord;
    Flags: dWord;
    pReceivers: PChar;
    ReceiversBytesNum: dWord;
  end;

  // -------------------------------------------------------------------------
  // Функция EXT_InitCrypt осуществляет проверку введенного пароля и инициализацию
  // работы с ключами абонента. После этого осуществляется проверка наличия
  // пришедших обновлений ключей, и, если таковые оказались, проводится обновление
  // действующих ключей абонента. Все остальные функции обязаны вызываться только
  // после успешного вызова данной функции. Для окончания работы с функциями СКЗИ 
  // необходимо вызвать функцию EXT_CloseCrypt.
  //
  // Для инициализации также можно воспользоваться функцией 
  // EXT_InitCryptEx (см. ниже).
  //
  // Параметры функции:
  //
  // Параметр                   Описание
  // psPassword                 Пароль абонента
  // PasswordLen                Длина пароля абонента
  // pContext                   Указатель на структуру EXT_FULL_CONTEXT
  //
  //
  // Входные значения           Выходные значения
  // psPassword
  // PasswordLen
  // pContext->pKeyStorage
  //                            pContext->pCryptoProvider
  //                            pContext->pProvderError
  //
  // -------------------------------------------------------------------------
  TExtInitCrypt = function(psPassword: PChar; PasswordLen: Integer;
    pContext: PEXT_FULL_CONTEXT): Integer; stdcall;

  // -------------------------------------------------------------------------
  // Функция EXT_InitCryptEx осуществляет ввод пароля и обновление ключей.
  // Данная функция интерактивно запрашивает пароль абонента, и после успешной
  // проверки осуществляются проверка наличия пришедших обновлений ключей и
  // (если таковые оказались) обновление действующих ключей абонента.
  // Данная функция позволяет осуществить ввод пароля с клавиатуры или с
  // внешних электронных носителей.
  //
  // Параметры функции:
  //
  // Параметр                   Описание
  // pContext                   Указатель на структуру EXT_FULL_CONTEXT
  //
  // Входные значения           Выходные значения
  // pContext->pKeyStorage 
  //                            pContext->pCryptoProvider
  //                            pContext->pProviderError
  //
  // Примечание: pContext->pKeyStorage - необязательный параметр.
  // Задается, если нужны ключи, находящиеся не в стандартном для ИТКС каталоге
  // -------------------------------------------------------------------------
  TExtInitCryptEx = function(pContext: PEXT_FULL_CONTEXT): Integer; stdcall;

  // -------------------------------------------------------------------------
  // Функция EXT_CloseCrypt предназначена для закрытия предварительно выделенного
  // криптографического контекста. Она должна вызываться непосредственно перед 
  // завершением работы с библиотекой. После вызова данной функции для 
  // возобновления работы с СКЗИ необходимо снова вызвать функцию 
  // EXT_InitCrypt или EXT_InitCryptEx.
  //
  // Параметр              Описание
  // pContext              Указатель на предварительно выделенный контекст 
  //                       библиотеки
  //
  // Входные значения      Выходные значения
  // pContext
  // -------------------------------------------------------------------------
  TExtCloseCrypt = procedure(pContext: PEXT_FULL_CONTEXT); stdcall;

  // -------------------------------------------------------------------------
  // Функция EXT_FreeMemory предназначена для освобождения памяти, выделенной
  // функциями библиотеки "Домен-К".
  //
  // Параметр              Описание
  // pData                 Указатель на освобождаемую область памяти
  // DataLen               Длина освобождаемого буфера. Если указана, то
  //                       перед освобождением памяти указанное количество байт
  //                       будет заполнено нулями. Если параметр равен нулю,
  //                       память просто освобождается по указателю в pData.
  //
  // Входные значения      Выходные значения
  // pData
  // DataLen
  // -------------------------------------------------------------------------
  TExtFreeMemory = function(pData: Pointer; DataLen: dWord): Integer; stdcall;

  // -------------------------------------------------------------------------
  // Функция EXT_AllocMemory предназначена для захвата памяти. Данная функция
  // может понадобиться при использовании множнственного подписывания,
  // разнесенного во времени. Например, промежуточный результат подписи может 
  // быть сохранен в файле, а затем считан в выделенную данной функцией память
  // и передан в фуyкцию подписи (EXT_Sign как параметр pSignaturesData 
  // структуры EXT_SIGN_CONTEXT). 
  // Если память выделилась, возвратится указатель на выделенную область памяти,
  // в противном случае вернется NULL.
  // Память, выделенная данной функцией, должна быть освобождена функцией
  // EXT_FreeMemory.
  //
  // Параметр              Описание
  // DataLen               Длина выделяемого буфера
  //
  // Входные значения      Выходные значения
  // DataLen
  // -------------------------------------------------------------------------
  TExtAllocMemory = function(DataLen: dWord): Pointer; stdcall;

  // -------------------------------------------------------------------------
  // Функция EXT_GetErrorDefinition предназначена для получения смысловой
  // информации об ошибке. Функция не выделяет память. Она возвращает информацию
  // о коде ощибки в выделенную внешней функцией память.
  //
  // Если указатель pErrDefinition выставлен в NULL, то функция вычислит 
  // размер памяти, который ей необходим для размещения описания кода ошибки, 
  // включая '\0', и вернет этот размер в параметре pErrDefSize;
  //
  // Параметр              Описание
  // ErrCode               Код ошибки периода работы СКЗИ
  // pErrDefinition        Указатель на буфер для сообщения
  // pErrDefSize           Указатель на длину буфера
  // -------------------------------------------------------------------------
  TExtGetErrorDefinition = procedure(const ErrCode: Integer;
    pErrDefinition: PChar; var pErrDefSize: dWord); stdcall;

  TExtRetCode2WinErr = function(RetCode: Integer): dWord; stdcall;

  TExtRetCode2HResult = function(RetCode: Integer): HResult; stdcall;

  // -------------------------------------------------------------------------
  // Функция получения собственного идентификатора пользователя
  //
  // Применяется для получения идентификатора действующего
  // в данный момент пользователя. 
  //
  // Параметры функции:
  // Параметр              Описание
  // pContext              Указатель на структуру EXT_FULL_CONTEXT
  // pszUserID             Указатель на буфер, по которому будет записан 
  //                       идентификатор пользователя. Размер идентификатора
  //                       ограничен восьмью символами, поэтому прикладная программа 
  //                       должна передать указатель на буфер размером в 8 + 1 символ 
  //                       (один - для '\0'). Если параметр равен NULL,
  //                       то идентификатор не возвращается.
  //
  // Входные значения           Выходные значения
  // pContext
  // pszUserID                  pszUserID
  //                            pContext->pProviderError
  // -------------------------------------------------------------------------
  TExtGetOwnID = function(pContext: PEXT_FULL_CONTEXT; pszUserID: PChar): Integer; stdcall;

  // -------------------------------------------------------------------------
  // Функция получения списка идентификаторов всех пользователей
  //
  // После отработки функции EXT_GetUserIDList параметр ppszUserIDList
  // будет содержать указатель на список идентификаторов зарегистрированных
  // пользователей. Область памяти, на которую указывает ppszUserIDList
  // должна быть освобождена вызывающей функцией, после того, как отпадает
  // надобность в этих данных, с помощью функции EXT_FreeMemory.
  // После отработки функции EXT_GetUserIDList параметр ppszUserIDList будет
  // содержать указатель на список идентификаторов зарегистрированных пользователей.
  // Формат списка получателей см. в описании структуры EXT_CRYPT_CONTEXT.
  // Область памяти, на которую указывает ppszUserIDList должна быть освобождена
  // вызывающей функцией, после того, как отпадает надобность в этих данных,
  // с помощью функции EXT_FreeMemory.
  //
  // Параметры функции:
  //
  // Параметр              Описание
  // pContext              Указатель на структуру EXT_FULL_CONTEXT
  // ppszUserIDList        Указатель на указатель, по которому будет возвращен
  //                       список идентификаторов зарегистрированных пользователей.
  //                       Формат списка пользователей см. в описании структуры
  //                       EXT_CRYPT_CONTEXT.
  // pUserIDListSize       Указатель на переменную, в которую будет возвращен размер
  //                       памяти, выделенный под список идентификаторов
  //                       пользователей. Может быть передан NULL, если не нужно
  //                       возвращать количество выделенной памяти. Параметр может
  //                       быть использован при освобождении памяти при передаче
  //                       в функцию EXT_FreeMemory
  //
  // Входные значения           Выходные значения
  // pContext
  // ppszUserIDList             ppszUserIDList
  // pUserIDListSize            pUserIDListSize
  //                            pContext->pProviderError
  // -------------------------------------------------------------------------
  TExtGetUserIDList = function(pContext: PEXT_FULL_CONTEXT;
    var ppszUserIDList: PChar; var pUserIDListSize: Integer): Integer; stdcall;

  // -------------------------------------------------------------------------
  // Функция получения псевдонима и имени пользователя по его идентификатору
  //
  // Функция применяется для получения псевдонима (и/или имени) пользователя.
  // Обычно используется после вызова функции EXT_GetReceivers, которая возвращает
  // список идентификаторов пользователей.
  //
  // Параметры функции:
  //
  // Параметр              Описание
  // pContext              Указатель на структуру EXT_FULL_CONTEXT
  // pszUserID             Указатель на строку, содержащую идентификатор
  //                       пользователя;
  // pszUserAlias          Указатель на указатель, по которому будет записан
  //                       псевдоним пользователя. Размер псевдонима ограничен 
  //                       восьмьюдесятью символами, поэтому прикладная программа
  //                       должна передать указатель на буфер размером в
  //                       80 + 1 символ (один - для '\0').
  //                       Если параметр равен NULL, то псевдоним не возвращается.
  // pszUserName           Указатель на указатель, по которому будет записано имя 
  //                       пользователя. Размер имени ограничен семьюдесятью
  //                       символами, поэтому прикладная программа должна передать 
  //                       указатель на буфер размером в 70 + 1 символ 
  //                       (один - для '\0'). Если параметр равен NULL,
  //                       то имя пользователя не возвращается.
  //
  // Входные значения           Выходные значения
  //
  // pContext
  // pszUserID
  // pszUserAlias               pszUserAlias
  // pszUserName                pszUserName
  //                            pContext->pProviderError
  // -------------------------------------------------------------------------
  TExtGetUserAlias = function(pContext: PEXT_FULL_CONTEXT; const pszUserID: PChar;
    pszUserAlias: PChar; pszUserName: PChar): Integer; stdcall;

  // -------------------------------------------------------------------------
  // Функция получения идентификатора и имени пользователя по его псевдониму
  //
  // Функция EXT_GetUserID применяется для получения идентификатора (и/или имени) 
  // пользователя. Обычно используется после вызова функций EXT_Encrypt,
  // EXT_Decrypt, которые требуют на вход идентификаторы пользователей.
  //
  // Параметры функции:
  //
  // Параметр              Описание
  //
  // pContext              Указатель на структуру EXT_FULL_CONTEXT
  // pszUserAlias          Указатель на строку, содержащую псевдоним пользователя;
  // pszUserID             Указатель на буфер, по которому будет записан 
  //                       идентификатор пользователя. Размер идентификатора
  //                       ограничен восьмью символами, поэтому прикладная программа
  //                       должна передать указатель на буфер размером
  //                       в 8 + 1 символ (один - для '\0'). 
  //                       Если параметр равен NULL, то идентификатор не возвращается.
  // ppszUserName          Указатель на указатель, по которому будет записано имя
  //                       пользователя. Размер имени ограничен семьюдесятью 
  //                       символами, поэтому прикладная программа должна передать 
  //                       указатель на буфер размером в 70 + 1 символ
  //                       (один - для '\0'). 
  //                       Если параметр равен NULL, то имя пользователя
  //                       не возвращается.
  // 
  // Входные значения           Выходные значения
  //
  // pContext
  // pszUserAlias
  // pszUserID                  pszUserID
  // pszUserName                pszUserName
  //                            pContext->pProviderError
  // -------------------------------------------------------------------------
  TExtGetUserID = function(pContext: PEXT_FULL_CONTEXT;
    const pszUserAlias: PChar; pszUserID: PChar; pszUserName: PChar): Integer; stdcall;

  // -------------------------------------------------------------------------
  // Функция подписи памяти/файла
  //
  // Параметры функции:
  //
  // Параметр              Описание
  // pContext              Указатель на структуру EXT_FULL_CONTEXT
  // pSignContext          Указатель на структуру контекста подписи
  //                       EXT_SIGN_CONTEXT, которая должна быть заполнена
  //                       следующим образом:
  //                            pData     = указатель на подписываемые данные
  //                            DataLen   = длина подписываемых данных в байтах
  //                            DataType  = Тип данных (память / файл)
  //                            Flags     = 0
  //
  // Входные значения                Выходные значения
  // pContext->pCryptoProvider
  // pSignContext->pData
  // pSignContext->DataLen
  // pSignContext->DataType
  // pSignContext->Flags
  //                                 pSignContext->pSignaturesData
  //                                 pSignContext->OutSignaturesDataLen
  //                                 pContext->pProviderError
  //
  // После вызова функции pSignContext->pSignaturesData будет содержать подпись
  // под данными, а pSignContext->OutSignaturesDataLen - длину подписи в байтах.
  // Область памяти pSignContext->pSignaturesData освобождается вызывающей
  // функцией, после того как отпадает надобность в этих данных, с помощью
  // функции EXT_FreeMemory.

  // Примечание: Одновременной подписи файла и памяти не производится.
  // -------------------------------------------------------------------------
  TExtSign = function(pContext: PEXT_FULL_CONTEXT;
    pSignContext: PEXT_SIGN_CONTEXT; pCallBackData: PEXT_CALLBACK_DATA): Integer; stdcall;

  // -------------------------------------------------------------------------
  // Функция EXT_VerifySign предназначена для проверки подписи под 
  // памятью / файлом.
  //
  // Параметры функции:
  //
  // Параметр         Описание
  // pContext         Указатель на структуру EXT_FULL_CONTEXT
  // При использовании формата PKCS#7 этот параметр может быть NULL
  //
  // pSignContext     Указатель на структуру контекста подписи 
  //                  EXT_SIGN_CONTEXT, которая должна быть заполнена 
  //                  следующим образом:
  //                       pData               = указатель на подписанные данные
  //                       DataLen             = длина подписанных данных в байтах
  //                       DataType                 = Тип данных (память / файл)
  //                       Flags               = 0
  //                       pSignaturesData     = указатель на ЭЦП
  //                       SignaturesDataLen   = Длина ЭЦП
  //
  // Входные значения                     Выходные значения
  // pContext->pCryptoProvider    
  // pSignContext->pData  
  // pSignContext->DataLen        
  // pSignContext->DataType
  // pSignContext->Flags
  // pSignContext->pSignaturesData        pSignContext->pSignaturesData
  // pSignContext->SignaturesDataLen      pSignContext->SignaturesDataLen
  //                                      pSignContext->SignaturesNum
  //                                      pSignContext->pSignaturesResults
  //                                      pSignContext->ResultsSize
  //                                      pSignContext->pControlInfo
  //                                      pSignContext->ControlInfoSize
  //                                      pContext->pProviderError
  //
  // После вызова функции параметр pSignContext->SignaturesNum будет содержать
  // количество подписей (одну), а pSignContext->pSignaturesResults - указатель
  // на массив структур EXT_SIGN_RESULT, соответствующий результатам проверки
  // подписи.
  // Область памяти pSignContext->pSignaturesResults освобождается вызывающей
  // функцией, после того как отпадает надобность в этих данных, с помощью 
  // функции EXT_FreeMemory.
  //
  // Примечание: Одновременной проверки подписи файла и памяти не производится.
  // ------------------------------------------------------------------------- 
  TExtVerifySign = function(pContext: PEXT_FULL_CONTEXT;
    pSignContext: PEXT_SIGN_CONTEXT; pCallBackData: PEXT_CALLBACK_DATA): Integer; stdcall;

  // -------------------------------------------------------------------------
  // Функция EXT_GetSignInfo предназначена для получения информации
  // по подписи. Данная функция разбирает данные, полученные при подписи 
  // документа, и возвращает информацию, соответствующую сертификату подписи,
  // и информацию о подписавшем абоненте. Для удобства использования эти 
  // данные возвращаются в форматах, соответствующих структурам Microsoft
  //
  // Параметры функции:
  // Параметр              Описание
  // pContext              Указатель на структуру EXT_FULL_CONTEXT
  // pSignContext          Указатель на структуру контекста подписи
  //                       EXT_SIGN_CONTEXT, которая должна быть заполнена 
  //                       следующим образом:
  //                            Flags               = 0
  //                            pSignaturesData     = указатель на ЭЦП
  //                            SignaturesDataLen   = Длина ЭЦП
  //                            SignaturesNum       = Индекс подписи, для которой 
  //                            нужно получить информацию (должен указывать на единицу).
  // pSignatureContext     Указатель на структуру контекста сигнатуры подписи
  //                       EXT_SIGNATURE_CONTEXT
  //
  // Входные значения                     Выходные значения
  // pContext->pCryptoProvider
  // pSignContext->Flags
  // pSignContext->pSignaturesData    
  // pSignContext->SignaturesDataLen
  // pSignContext->SignaturesNum
  //                                      pSignatureContext->pCertificate
  //                                      pSignatureContext->CertificateLen
  //                                      pSignatureContext->pSignerInfo
  //                                      pSignatureContext->SignerInfoLen
  //                                      pContext->pProviderError
  //
  // После вызова функции pSignatureContext->pCertificate содержит указатель
  // на кодированный сертификат, pSignatureContext->CertificateLen содержит число 
  // байт, занимаемых кодированным сертификатом;
  // pSignatureContext->pSignerInfo содержит указатель на кодированную информацию
  // о подписавшем абоненте, pSignatureContext->SignerInfoLen содержит число
  // байт, занимаемых информацией о подписавшем абоненте. 
  //
  // Области памяти pSignatureContext->pCertificate и pSignatureContext->pSignerInfo 
  // должны быть освобождены вызывающей функцией
  // после того, как отпадает надобность в этих данных, с помощью 
  // функции EXT_FreeMemory.
  // -------------------------------------------------------------------------
  TExtGetSignInfo = function (pContext: PEXT_FULL_CONTEXT;
    pSignContext: PEXT_SIGN_CONTEXT; pSignatureContext: PEXT_SIGNATURE_CONTEXT): Integer; stdcall;

  // -------------------------------------------------------------------------
  // Функция EXT_VerifyViewSignResult предназначена для проверки и просмотра 
  // результата подписи под данными (а также для просмотра сертификата 
  // подписавшего  пользователя). Можно воспользоваться также интерактивной 
  // функцией EXT_ViewSignResult, которая также отображает окно с 
  // результатами проверки подписи под данными и сертификата подписавшего, 
  // но в отличие от данной, не проверяет подпись, а лишь использует данные,
  // полученные при проверке подписи (EXT_VerifySign).
  //
  // Параметры функции:
  // Параметр              Описание
  // pContext              Указатель на структуру EXT_FULL_CONTEXT
  // pSignContext          Указатель на структуру контекста подписи 
  //                       EXT_SIGN_CONTEXT, которая должна быть заполнена 
  //                       следующим образом:
  //                            Flags               = 0
  //                            pSignaturesData     = указатель на ЭЦП
  //                            SignaturesDataLen   = Длина ЭЦП
  //                            pTitleStr           = Строка, содержащая какое-либо название 
  //                                                  подписанных данных;
  //                                                  Может отсутствовать, то есть pTitleStr может 
  //                                                  быть равным нулю.
  //
  // Входные значения                     Выходные значения
  // pContext->pCryptoProvider
  // pContext->hParent
  // pSignContext->Flags
  // pSignContext->pSignaturesData
  // pSignContext->SignaturesDataLen
  // pTitleStr
  // ------------------------------------------------------------------------- 
  TExtVerifyViewSignResult = function(pContext: PEXT_FULL_CONTEXT;
    pSignContext: PEXT_SIGN_CONTEXT; const pTitleStr: PChar;
    pCallBackData: PEXT_CALLBACK_DATA): Integer; stdcall;

  // -------------------------------------------------------------------------
  // Функция EXT_ViewSignResult предназначена для просмотра
  // результата подписи под данными (а также для просмотра сертификата
  // подписавшего  пользователя). Не проверяет подпись, а лишь использует данные,
  // полученные при проверке подписи (EXT_VerifySign).
  //
  // Параметры функции:
  // Параметр              Описание
  // pContext              Указатель на структуру EXT_FULL_CONTEXT
  // pSignContext          Указатель на структуру контекста подписи
  //                       EXT_SIGN_CONTEXT, которая должна быть заполнена
  //                       следующим образом:
  //                            Flags               = 0
  //                            pSignaturesData     = указатель на ЭЦП
  //                            SignaturesDataLen   = Длина ЭЦП
  //                            pSignaturesResults        = Указатель на массив с результатами подписей.
  //                            ResultsSize         = Длина массива с результатами проверки 
  //                                                  подписей.
  //                            pControlInfo        = Указатель на дополнительную информацию, 
  //                                                  которая используется проверки подписи
  //                            ControlInfoSize     = Размер дополнительной информации, 
  //                                                  найденной при проверке подписи.
  //                            pTitleStr           = Строка, содержащая какое-либо название
  //                                                  подписанных данных;
  //                                                  Может отсутствовать, то есть pTitleStr может 
  //                                                  быть равным нулю.
  //
  // Входные значения                     Выходные значения
  // pContext->pCryptoProvider
  // pContext->hParent
  // pSignContext->Flags
  // pSignContext->pSignaturesData
  // pSignContext->SignaturesDataLen
  // pSignContext->pSignaturesResults
  // pSignContext->ResultsSize
  // pSignContext->pControlInfo
  // pSignContext->ControlInfoSize
  // pTitleStr
  // -------------------------------------------------------------------------
  TExtViewSignResult = function(pContext: PEXT_FULL_CONTEXT;
    pSignContext: PEXT_SIGN_CONTEXT; const pTitleStr: PChar): Integer; stdcall;

  TExtGetSignatureSize = function(pContext: PEXT_FULL_CONTEXT;
    pSignContext: PEXT_SIGN_CONTEXT; var pSignatureSize: Integer): Integer; stdcall;

  TExtGetCurrentCertificate = function(pContext: PEXT_FULL_CONTEXT;
    var ppEncodedCertificate: Pointer; var pEncodedCertSize: Integer): Integer; stdcall;

  TExtViewEncodedCertificate = function(pContext: PEXT_FULL_CONTEXT;
    const pEncodedCertificate: Pointer; EncodedCertSize: Integer): Integer; stdcall;

  TExtViewCertificate = function(pContext: PEXT_FULL_CONTEXT;
    const pCertContext: PCERT_CONTEXT): Integer; stdcall;

  // -------------------------------------------------------------------------
  // Функция зашифрования памяти/файла
  //
  // Параметры функции:
  //
  // Параметр              Описание
  // pContext              Указатель на структуру EXT_FULL_CONTEXT
  // pCryptContext         Указатель на структуру контекста подписи
  //                       EXT_CRYPT_CONTEXT, которая должна быть заполнена
  //                       следующим образом:
  //                            pInputData     = указатель на зашифровываемые данные
  //                            InputDataLen   = длина исходных данных в байтах.
  //                                           Для файла данный параметр не имеет
  //                                           значения, так как размер файла будет 
  //                                           вычислен внутри функции;
  //                            DataType       = Тип данных (память / файл)
  //                            Flags          = 0
  //                            pOutputData    = указатель на имя выходного файла,
  //                                           если осуществляется зашифрование
  //                                           файла, иначе должен быть выставлен
  //                                           в NULL.
  //                            pReceivers     = Указатель на список получателей,
  //                                           для которых необходимо зашифровать
  //                                           данные. Формат списка см. в описании
  //                                           структуры EXT_CRYPT_CONTEXT;
  // pCallBackContext      Указатель на структуру EXT_CALLBACK_DATA, которая позволяет
  //                       прикладной программе периодически получать управление при
  //                       долговременных операциях для отображения прогресса операции.
  //
  // Входные значения                Выходные значения
  // pContext->pCryptoProvider
  // pCryptContext->pInputData
  // pCryptContext->InputDataLen
  // pCryptContext->DataType
  // pCryptContext->Flags
  // pCryptContext->pOutputData      pCryptContext->pOutputData
  //                                 pCryptContext->OutputDataLen
  //                                 pContext->pProviderError
  //
  // Если зашифровывали область памяти, то после отработки функции 
  // pCryptContext->pOutputData будет содержать совокупность
  // зашифрованных данных и криптоинформации для расшифрования,
  // pCryptContext->OutputDataLen - длину выходных данных в байтах,  
  // Область памяти pCryptContext->pOutputData освобождается вызывающей
  // функцией, после того, как отпадает надобность в этих данных, с помощью
  // функции EXT_FreeMemory.
  // Если зашифровывали файл, то pCryptContext->pOutputData является входным
  // параметром, а pCryptContext->OutputDataLen не используется. Результатом 
  // работы функции в данном случае является зашифрованный файл, имя которого
  // было передано функции в параметре pCryptContext->pOutputData.
  // -------------------------------------------------------------------------
  TExtEncrypt = function(pContext: PEXT_FULL_CONTEXT;
    pCryptContext: PEXT_CRYPT_CONTEXT; pCallBackData: PEXT_CALLBACK_DATA): Integer; stdcall;

  // -------------------------------------------------------------------------
  // Функция расшифрования памяти/файла
  //
  // Параметры функции:
  //
  // Параметр              Описание
  // pContext              Указатель на структуру EXT_FULL_CONTEXT
  // pCryptContext         Указатель на структуру контекста подписи
  //                       EXT_CRYPT_CONTEXT, которая должна быть заполнена
  //                       следующим образом:
  //                            pInputData     = указатель на зашифрованные данные
  //                            InputDataLen   = длина зашифрованных данных в байтах.
  //                                           Для файла данный параметр не имеет
  //                                           значения, так как размер файла будет
  //                                           вычислен внутри функции;
  //                            DataType       = Тип данных (память / файл)
  //                            Flags          = 0
  //                            pOutputData    = указатель на имя выходного файла,
  //                                           если осуществляется зашифрование
  //                                           файла, иначе должен быть выставлен
  //                                           в NULL.
  //                            pReceivers     = Указатель на получателя,
  //                                           для которого зашифровывались данные.
  //
  // Входные значения                Выходные значения
  // pContext->pCryptoProvider
  // pCryptContext->pInputData
  // pCryptContext->InputDataLen
  // pCryptContext->DataType
  // pCryptContext->Flags
  // pCryptContext->pOutputData      pCryptContext->pOutputData
  //                                 pCryptContext->OutputDataLen
  //                                 pContext->pProviderError
  //
  // Если расшифровывали область памяти, то после отработки функции
  // pCryptContext->pOutputData будет содержать расшифрованные данные,
  // pCryptContext->OutputDataLen - длину выходных данных в байтах,
  // Область памяти pCryptContext->pOutputData освобождается вызывающей
  // функцией, после того, как отпадает надобность в этих данных, с помощью
  // функции EXT_FreeMemory.
  // Если зашифровывали файл, то pCryptContext->pOutputData является входным
  // параметром, а pCryptContext->OutputDataLen не используется. Результатом
  // работы функции в данном случае является расшифрованный файл, имя которого
  // было передано функции в параметре pCryptContext->pOutputData.
  // -------------------------------------------------------------------------
  TExtDecrypt = function(pContext: PEXT_FULL_CONTEXT;
    pCryptContext: PEXT_CRYPT_CONTEXT; pCallBackData: PEXT_CALLBACK_DATA): Integer; stdcall;

  // -------------------------------------------------------------------------
  // Функция получения списка получаталей зашифрованных данных (памяти/файла)
  //
  // Параметры функции:
  //
  // Параметр              Описание
  // pContext              Указатель на структуру EXT_FULL_CONTEXT
  // pCryptContext         Указатель на структуру контекста подписи
  //                       EXT_CRYPT_CONTEXT, которая должна быть заполнена 
  //                       следующим образом:
  //                            pInputData     = указатель на зашифрованные данные
  //                            InputDataLen   = длина зашифрованных данных в байтах.
  //                                           Для файла данный параметр не имеет 
  //                                           значения, так как размер файла будет
  //                                           вычислен внутри функции;
  //                            DataType       = Тип данных (память / файл)
  //                            Flags          = 0
  //
  // Входные значения                Выходные значения
  // pContext->pCryptoProvider
  // pCryptContext->pInputData
  // pCryptContext->InputDataLen
  // pCryptContext->DataType
  // pCryptContext->Flags
  //                                 pCryptContext->pReceivers
  //                                 pContext->pProviderError
  //
  // После отработки функции параметр pCryptContext->pReceivers будет содержать
  // список получателей зашифрованных данных. Формат списка получаталей см.
  // в описании структуры EXT_CRYPT_CONTEXT.
  // Область памяти pCryptContext->pReceivers освобождается вызывающей
  // функцией, после того, как отпадает надобность в этих данных, с помощью
  // функции EXT_FreeMemory.
  // -------------------------------------------------------------------------
  TExtGetReceivers = function(pContext: PEXT_FULL_CONTEXT;
    pCryptContext: PEXT_CRYPT_CONTEXT): Integer; stdcall;

  // -------------------------------------------------------------------------
  // Функция получения идентификаторов пользователей, соответствующих
  // указанному псевдониму
  //
  // Обычно используется, если одному псевдониму сопоставлено несколько
  // пользователей. В отличие от функциии EXT_GetUserID, которая
  // возвращает одного пользователя, данная функция возвращает список
  // пользователей, для которых совпал указанный псевдоним.
  //
  // Область памяти, на которую указывает ppszUserIDList
  // должна быть освобождена вызывающей функцией, после того, как отпадает
  // надобность в этих данных, с помощью функции EXT_FreeMemory.
  // После отработки функции EXT_GetUserIDList параметр ppszUserIDList будет
  // содержать указатель на список идентификаторов зарегистрированных пользователей.
  // Формат списка получателей см. в описании структуры EXT_CRYPT_CONTEXT.
  // Область памяти, на которую указывает ppszUserIDList должна быть освобождена
  // вызывающей функцией, после того, как отпадает надобность в этих данных,
  // с помощью функции EXT_FreeMemory.
  //
  // Параметры функции:
  //
  // Параметр              Описание
  //
  // pContext              Указатель на структуру EXT_FULL_CONTEXT
  // pszUserAlias          Указатель на строку, содержащую псевдоним пользователя;
  // ppszUserIDList        Указатель на указатель, по которому будет возвращен
  //                       список идентификаторов зарегистрированных пользователей.
  //                       Формат списка пользователей см. в описании структуры
  //                       EXT_CRYPT_CONTEXT.
  // pUserIDListSize       Указатель на переменную, в которую будет возвращен размер
  //                       памяти, выделенный под список идентификаторов
  //                       пользователей. Может быть передан NULL, если не нужно
  //                       возвращать количество выделенной памяти. Параметр может
  //                       быть использован при освобождении памяти при передаче
  //                       в функцию EXT_FreeMemory
  //
  // Входные значения           Выходные значения
  // pContext
  // pszUserAlias
  // ppszUserIDList             ppszUserIDList
  // pUserIDListSize            pUserIDListSize
  //                            pContext->pProviderError
  // -------------------------------------------------------------------------
  TExtGetUserIDListByAlias = function(pContext: PEXT_FULL_CONTEXT;
    const pszUserAlias: PChar; var ppszUserIDList: PChar;
    var pUserIDListSize: Integer): Integer; stdcall;

  // -------------------------------------------------------------------
  // EXT_GenRandom заполняет буфер pbBuffer случайными dwLen байтами.
  // В случае успеха функция возвращает 0.
  // -------------------------------------------------------------------
  TExtGenRandom = function(pContext: PEXT_FULL_CONTEXT;
    pbBuffer: PChar; dwLen: dWord): Integer; stdcall;

  // -------------------------------------------------------------------
  // EXT_HashData выполняет хеширование данных, расположенных
  // по адресу pbData длиной dwDataLen байт.
  // В случае успеха функция возвращает 0.
  //
  // Если pbHash равен нулю, то по адресу pdwHashLen будет находиться 
  // число, указывающее на размер выходного hash-значения.
  // Если pbHash не равен нулю, то по указанному адресу будет 
  // произведено копирование hash-значения размером, равным *pdwHashLen.
  // Если размер, на который указывает pdwHashLen превышает максимальную
  // длину hash-значения, то функция вернет код, указывающий на неверно
  // заданные параметры.
  // -------------------------------------------------------------------
  TExtHashData = function(pContext: PEXT_FULL_CONTEXT;
    const pbData: PChar; dwDataLen: dWord;
    pbHash: PChar; var pdwHashLen: dWord): Integer; stdcall;
  // Возврат строкового значения ошибки на английском и русском
  //   Err - номер ошибки
  //   результат - строка сообщения
  function ErrToStr(Err: Integer): string;

  // ---------------------------------------------------------------------------------
  //   Функция GetSignIssuerName предназначена для получения информации
  //   (в данном случае, возвращается только имя (поле Subject))
  //   о подписавшем пользователе.
  //
  //   Параметры:
  //   pEncodedCertificate   -    Закодированный сертификат (полученный, например,
  //                             при вызове функции проверки подписи)
  //   EncodedCertSize       -    Длина закодированного сертификата
  //   pName                 -    Указатель на ячейку, содержащую указатель строки,
  //                              в которую вернется имя подписавшего пользователя
  //   pNameLen              -    Указатель на ячейку с длиной строки.
  //                              Длина строки включает '\0'.
  // ---------------------------------------------------------------------------------
  function GetSignIssuerName(const pEncodedCertificate: Pointer;
    const EncodedCertSize: dWord; var pSignInfo: PChar; var pSignInfoLen: dWord): Boolean;

  // ---------------------------------------------------------------------------------
  //   Функция GetSignTime предназначена для получения информации
  //   даты/времени подписи
  //
  //   Параметры:
  //   pEncodedCertificate   -    Закодированная структура с информацией по
  //                              подписавшему пользователю
  //   EncodedSignerInfoSize -    Длина Закодированной структуры
  //   pSignTime             -    Указатель на Дату/Время подписи
  // ---------------------------------------------------------------------------------
  function GetSignTime(const pEncodedSignerInfo: Pointer;
    const EncodedSignerInfoSize: dWord; var ATime: TDateTime): Boolean;

function InitUserNameList(fc: PEXT_FULL_CONTEXT;
  GetMes: Boolean; var Mes: string): Boolean;
procedure DoneUserNameList;
function GetUserIdByName(pContext: PEXT_FULL_CONTEXT; const AName: string): string;
function LoadItscLib(var Mes: string): Boolean;
function IsItscLibLoaded: Boolean;
procedure FreeItscLib;
function GetExtPtr(FuncIndex: Integer): Pointer;

//  GetExtPtr(fi))(

const
  Tcc_Itcs_Dll = 'tcc_itcs.dll';

const
  fiInitCrypt               = 0;
  fiInitCryptEx             = 1;
  fiCloseCrypt              = 2;
  fiFreeMemory              = 3;
  fiAllocMemory             = 4;
  fiGetErrorDefinition      = 5;
  fiRetCode2WinErr          = 6;
  fiRetCode2HResult         = 7;
  fiGetOwnID                = 8;
  fiGetUserIDList           = 9;
  fiGetUserAlias            = 10;
  fiGetUserID               = 11;
  fiSign                    = 12;
  fiVerifySign              = 13;
  fiGetSignInfo             = 14;
  fiVerifyViewSignResult    = 15;
  fiViewSignResult          = 16;
  fiGetSignatureSize        = 17;
  fiGetCurrentCertificate   = 18;
  fiViewEncodedCertificate  = 19;
  fiViewCertificate         = 20;
  fiEncrypt                 = 21;
  fiDecrypt                 = 22;
  fiGetReceivers            = 23;
  fiGetUserIDListByAlias    = 24;
  fiGenRandom               = 25;
  fiHashData                = 26;

implementation

var
  FuncList: array[0..26] of
    record
      flDllName: PChar;
      flPtr: Pointer;
    end =
  (
    (flDllName: 'EXT_InitCrypt';               flPtr: nil),
    (flDllName: 'EXT_InitCryptEx';             flPtr: nil),
    (flDllName: 'EXT_CloseCrypt';              flPtr: nil),
    (flDllName: 'EXT_FreeMemory';              flPtr: nil),
    (flDllName: 'EXT_AllocMemory';             flPtr: nil),
    (flDllName: 'EXT_GetErrorDefinition';      flPtr: nil),
    (flDllName: 'EXT_RetCode2WinErr';          flPtr: nil),
    (flDllName: 'EXT_RetCode2HResult';         flPtr: nil),
    (flDllName: 'EXT_GetOwnID';                flPtr: nil),
    (flDllName: 'EXT_GetUserIDList';           flPtr: nil),
    (flDllName: 'EXT_GetUserAlias';            flPtr: nil),
    (flDllName: 'EXT_GetUserID';               flPtr: nil),
    (flDllName: 'EXT_Sign';                    flPtr: nil),
    (flDllName: 'EXT_VerifySign';              flPtr: nil),
    (flDllName: 'EXT_GetSignInfo';             flPtr: nil),
    (flDllName: 'EXT_VerifyViewSignResult';    flPtr: nil),
    (flDllName: 'EXT_ViewSignResult';          flPtr: nil),
    (flDllName: 'EXT_GetSignatureSize';        flPtr: nil),
    (flDllName: 'EXT_GetCurrentCertificate';   flPtr: nil),
    (flDllName: 'EXT_ViewEncodedCertificate';  flPtr: nil),
    (flDllName: 'EXT_ViewCertificate';         flPtr: nil),
    (flDllName: 'EXT_Encrypt';                 flPtr: nil),
    (flDllName: 'EXT_Decrypt';                 flPtr: nil),
    (flDllName: 'EXT_GetReceivers';            flPtr: nil),
    (flDllName: 'EXT_GetUserIDListByAlias';    flPtr: nil),
    (flDllName: 'EXT_GenRandom';               flPtr: nil),
    (flDllName: 'EXT_HashData';                flPtr: nil)
  );

const
  ExtErrMes: array[0..204] of PChar = (
    'There was no error',
    'Key diskette was not found',
    'The entered password is not right',
    'The directory is not accessible',
    'The specified file not found',
    'Error while reading file',
    'Error while writing into file',
    'Decrypting or imito check detected distortion',
    'The directory was not found',
    'Invalid passwords are limited',
    'The user refused from entering password',
    'The password was not entered',
    'The specified message was not kvitted. It is not an error',
    'The specified message was delivered to recipient. It is not an error',
    'The message was used (read, printed, etc.) by recipient. Not an error',
    'No registered sent message corresponding to received kvit',
    'Not enough memory',
    'Error while opening file',
    'Directory can not have such name',
    'Access to file denied',
    'Error while closing file',
    'Error while positioning in file',
    'Wrong structure of structured file',
    'Wrong structure of file *.abn',
    'Wrong structure of file *.apn',
    'Wrong structure of glued file',
    'The file nodename.doc not maintaining the server ID for given AP, but this ID must be present',
    'The searching ID of the Abonent Point was not found',
    'Function received incorrect parameters',
    'Password too long or too small',
    'Identifier has wrong length',
    'Directory is empty but it should not be such',
    'Desired key (of any type) was not found',
    'The specified length of the ID of abonent, that we need to make Key Disk, is wrong',
    'The specified length of the abonent name is wrong',
    'Not enough disk space',
    'The returned value does not correspond to any code',
    'Index is beyond proper bounds',
    'function received identifier of not proper type',
    'The file NNNNAAAA.abn maintain the abonent ID, that differs from NNNNAAAA',
    'The random number has repeted',
    'File''s (dir''s) attr. can''t be received or set',
    'Is used to turn off initialization of any kind or when creating an object without initialization',
    'Error while deleting file',
    'Error while renaming file',
    'Error while  get file size',
    'Count abonent is empty',
    'Error while process compressing',
    'Error while process decompressing',
    'No flag infotecs (ITCS)',
    'Error while coping string',
    'Get file info (date, time, attributes...)',
    'Error while finding file',
    'Error can''t get full path (not file or other error)',
    'Error can''t get offset in the file',
    'File name of envelope must be @*******.***; Receipt N|D|R******.***',
    'Bad version envelope',
    'No Envelope',
    'Bad key',
    'Bad header of envelope',
    'Can''t seting working directory',
    'Error while creating directory',
    'Error while deleting directory',
    'Error while creating file',
    'Error while coping  file',
    'The abonent is not registered at the given AP',
    'This not package',
    'Document not found',
    'Document list is empty',
    'Can''t unpack file',
    'Can''t file pack',
    'Invalid handle (pointer to CKeyDisk)',
    'signature not equal ''CrYpT''',
    'only GOST crypting allowed',
    'File is corrupted',
    'Unknown type of receipt',
    'No receipt',
    'This envelope',
    'Bad wersion receipt',
    'Denied adress receiver',
    'Denied adress sender',
    'Is long name of directory',
    'Exe-file receives wrong number of parameters',
    'Error database',
    'Database is full',
    'Record not found',
    'Document was removed',
    'Invalid sender address',
    'Invalid receiver address',
    'Document is already packed',
    'Document not found',
    'Error header envelope writing',
    'Error header envelope reading',
    'Error header envelope removing',
    'Encrypt file error',
    'Decrypt file error',
    'Imito file error',
    'The specified abonent ID or Name is not found',
    'The Sign of the Chief abonent in NNNN_spr.sgn is not valid',
    'A file or memory already signed by specified abonent',
    'Envelope is assign for another task application',
    'The specified workgroup absent in address book',
    'Error open DB Table',
    'Error read table to list',
    'Error update DB table record',
    'The parameters of objrcts to com-pare are not matched or wrong',
    'The user rights are not suitable for some operation',
    'Some time period is overdue (or taken out from using)',
    'Some operation is wrong',
    'Branch to next element',
    'Error read special file',
    'Read error package''s header',
    'Read error package''s document',
    'The numbers of masters are not mathing',
    'No any net masters for generation',
    'Function not implemented',
    'End of files searching',
    'Function not implemented in some case',
    'CurPos() failed',
    'Truncate () failed',
    'Flush() failed',
    'File already exist',
    'Set file time',
    'Get file time',
    'File move error',
    'Use GetLastError',
    'Get disk free or total',
    'End of stream was reached',
    'Preset dictionary needed',
    'Error occurred in the file system, you may consult errno to get the exact error code',
    'The stream state was inconsistent (for example  if next_in or next_out was NULL)',
    'The input data was corrupted',
    'No progress is possible or if there was not enough room in the output buffer',
    'The library version is incompatible with the version assumed by the caller',
    'The file struct unexpected',
    'The network number is incorrect',
    'The version is incorrect',
    'The task number is incorrect',
    'The Chief abonent is not found in NNNN.chf',
    'The WS is not registered for this task',
    'The document not signed',
    'Error during checking sign',
    'Something not installed',
    'Some operation already done',
    'Drive not ready',
    'Occuring in trying to copy the files with create time less then existing',
    'Error during LoadLibrary',
    'Error during GetProcAddress',
    'An operation has been cancelled by user',
    'The premature operation, Check Your system time, please',
    'The settings are incorrect',
    'Crypted another ser',
    'Crypted this ser another pass',
    'Crypted this ser this pass',
    'No crypted',
    'Crypted another mode',
    'The operation can not be executed',
    'The IDs are coincide (the same or something else)',
    'The IDs are not coincide (different or something else)',
    'Not an error, but UNDO was encountered cause of the some error or the cancel be user',
    'Transport receipt has not allowed status',
    'Different imito key',
    'Different imito header',
    'Deimito file error',
    'Aplication disabled',
    'IP-traffic was locked', '', '', '', '',
    'Error address Callback Function',
    'Invalid code of device',
    'Aborted wait fo device',
    'Error create object of device',
    'Driver or device not installed',
    'Reading Mistake ID key',
    'Wrong slot of device',
    'Undefined function',
    'Key not inserted in device',
    'Error reading from device',
    'Error writing to device',
    'Error lentgh reading or writing',
    'Error data of chief sign',
    'Wrong file name',
    'Error during RegOpenKey',
    'Error during RegQueryValueEx',
    'Error during SwitchDesktop',
    'Error during SystemParametersInfo',
    'Error during CreateWindowEx',
    'Unlock impossible - Locker Busy',
    'Error during CreateDesktop',
    'Error during CreateThread',
    'The user has no right to sign',
    'The user was removed from VPN',
    'Missing (arbitrary) object',
    '(Arbitrary) object already exists',
    'Missing attachment file',
    'Mail size is beyond message store size limit',
    'Error in function of processing alternative devices data storage',
    'Save CSP defence  key to reg',
    'The chief subscriber tryes to create the new digital signature on the AP',
    'The subscriber tryes to create the new digital signature on the nonprime AP',
    'A required certificate is not valid',
    'A required certificate is not within its validity period',
    'The current user sign certificate is incompatible with the format of the signed file'
  );

  ExtErrMesRus: array[0..204] of PChar = (
    'Не имелось никакой ошибки',
    'Ключевая дискета не была найдена',
    'Введенный пароль не верен',
    'Каталог недоступен',
    'Указанные файл не найден',
    'Ошибка при чтении файла',
    'Ошибка при записи в файл',
    'Дешифровка или имито-вставка искажены',
    'Каталог не был найден',
    'Недопустимые пароли ограничены',
    'Пользователь отказался от ввода пароля',
    'Пароль не был введен',
    'Определенное сообщение не было сквитовано. Это не ошибка',
    'Определенное сообщение было поставлено получателю (приемнику). Это не ошибка',
    'Сообщение использовалось (чтение, напечатано, и т.д.) получателем (приемником). Это не ошибка',
    'Нет зарегистрированного посланного сообщения соответствующего полученной квитовке',
    'Недостаточно памяти',
    'Ошибка при открытии файла',
    'Каталог не может иметь такого имени',
    'Доступ к файлу запрещен',
    'Ошибка при закрытии файла',
    'Ошибка при позиционировании в файле',
    'Неправильная структура структурного файла',
    'Неправильная структура файла *. abn',
    'Неправильная структура файла *. apn',
    'Неправильная структура склеивающегося файла',
    'Файл nodename.doc не содержит ИДЕНТИФИКАТОР сервера для данного АП, но этот ИДЕНТИФИКАТОР должен присутствовать',
    'Разыскиваемый ИДЕНТИФИКАТОР Точки Абонента не найден',
    'Функция получила неправильные параметры',
    'Пароль слишком длинный или слишком короткий',
    'Идентификатор имеет неправильную длину',
    'Каталог пуст, но это не должно быть так',
    'Желательный ключ (любого типа) не был найден',
    'Указанная длина ИДЕНТИФИКАТОРА абонента, которая нужна для создания Ключевого диска, является неправильной.',
    'Указанная длина имени абонента неправильна',
    'Недостаточно дискового пространства',
    'Возвращенное значение не соответствует никакому коду',
    'Индекс вне соответствующих пределов',
    'Функциональный полученный идентификатор несоответствующего типа',
    'Файл NNNNAAAA.ABN поддерживает ИДЕНТИФИКАТОР абонента, который отличается от NNNNAAAA',
    'Случайное число было повторено',
    'Атрибуты файла (каталога) не могут быть получены или установлены',
    'Используется, чтобы выключить инициализацию любого вида или при создании объекта без инициализации',
    'Ошибка при удалении файла',
    'Ошибка при переименовании файла',
    'Ошибка во время получения размера файла',
    'Абонент Счета пуст',
    'Ошибка во время процесса сжатия',
    'Ошибка во время процесса декомпрессии',
    'Нет флажков Инфотекса (ITCS).',
    'Ошибка при копировании строки',
    'Получите информацию файла (дата, время, атрибуты...)',
    'Ошибка при нахождении файла',
    'Ошибка не может получить полный путь (не файловая или другая ошибка)',
    'Ошибка не может получать смещение в файле',
    'Имя файла оболочки должно быть @*******. ***; Получение N|D|R ******. ***',
    'Плохая версия оболочки',
    'Нет оболочки',
    'Плохой ключ',
    'Плохой заголовок оболочки',
    'Не могу задать рабочий каталог',
    'Ошибка при создании каталога',
    'Ошибка при удалении каталога',
    'Ошибка при создании файла',
    'Ошибка при копировании файла',
    'Абонент не зарегистрирован в данном АГЕНТСТВЕ АП',
    'Этот не пакет',
    'Документ не найден',
    'Список документов пуст',
    'Не могу распаковать файл',
    'Не могу запаковать файл',
    'Недопустимый дескриптор (указатель на CKeyDisk)',
    'Сигнатура не равна ''CrYpT''',
    'Допустимо только ГОСТ криптование',
    'Файл разрушен',
    'Неизвестный тип получателя',
    'Нет получателя',
    'Эта оболочка',
    'Неверная версия получателя',
    'Отклоненный получатель адреса',
    'Отклоненный отправитель адреса ',
    'Является длинным именем каталога',
    'Exe-файл получает неправильное число параметров',
    'Ошибочная база данных',
    'База данных полна',
    'Запись не найдена',
    'Документ был удален',
    'Недопустимый адрес отправителя',
    'Недопустимый адрес получателя',
    'Документ уже упакован',
    'Документ не найден',
    'Ошибка при записи оболочки заголовка',
    'Ошибка при чтении оболочки заголовка',
    'Ошибка при удалении оболочки заголовка',
    'Ошибка шифрования файла',
    'Ошибка дешифрования файла',
    'Ошибка имито-файла',
    'Указанный ИДЕНТИФИКАТОР абонента или имя не найдены',
    'Подпись Главного абонента в NNNN_SPR. sgn некорректна',
    'Файл или память уже подписаны указанным абонентом',
    'Оболочка назначена для другого приложения',
    'Запрашиваемая рабочая группа отсутствуюет в адресной книге',
    'Ошибка открытия DB-таблицы',
    'Ошибка чтения таблицы чтобы перечислить',
    'Ошибка модификации записи DB-таблицы',
    'Параметры objects для сравнения не согласованы или неверны',
    'Права пользователя не подходят для некоторой операции',
    'Некоторый интервал времени просрочен (или снят из использования)',
    'Некоторая операция неправильна',
    'Переход к следующему элементу',
    'Ошибка чтения заданного файла',
    'Чтение ошибочного заголовка пакета',
    'Чтение ошибочного заголовка документа',
    'Число мастеров  не согласовано',
    'Нет никаких мастеров сети для порождения',
    'Функция не выполнена',
    'Конец поиска файлов',
    'Функция не выполнена в некотором случае',
    'CurPos() потерпел неудачу',
    'Truncate() потерпел неудачу',
    'Flush() потерпел неудачу',
    'Файл уже существует',
    'Установите время файла',
    'Получите время файла    ',
    'Ошибка перемещения Файла  ',
    'Используйте GetLastError',
    'Получите дисковую свободу или общее',
    'Конец потока был достигнут',
    'Нужен предварительно установленный словарь',
    'Ошибка произошла в файловой системе, Вы можете консультироваться с errno, чтобы получить точный код ошибки',
    'Состояние потока было несогласованно (например, если next_in или next_out был НУЛЕВОЙ (ПУСТОЙ))',
    'Входные данные были разрушены',
    'Никакой прогресс не был бы возможен или если не имелось достаточного участка памяти в буфере вывода',
    'Библиотечная версия несовместима с версией принятого к вызывающему оператору',
    'Непредвиденная файловая структура',
    'Сетевой номер неправилен',
    'Версия неправильна',
    'Номер задачи неправилен',
    'Главный абонент не найден в NNNN.CHF',
    'WS не зарегистрирован для этой задачи',
    'Документ не подписан',
    'Ошибка во время проверки подписи',
    'Что-то не установлено',
    'Некоторая операция уже выполняется',
    'Дисковод не готов',
    'Конфликт в попытке копировать файлы с созданием времени меньше существующего',
    'Ошибка в течение LoadLibrary',
    'Ошибка в течение GetProcAddress',
    'Операция была отменена пользователем',
    'Преждевременная операция, проверьте Ваше время системы, пожалуйста',
    'Установки неправильны',
    'Зашифровано другим ser',
    'Зашифровано другим паролем ser',
    'Зашифровано этим паролем ser',
    'Не зашифровано',
    'Зашифровано в другом режиме',
    'Операция не может быть выполнена',
    'ИДЕНТИФИКАТОРЫ совпадают (или что-нибудь еще)',
    'ИДЕНТИФИКАТОРЫ не совпадают (или что-нибудь еще)',
    'Не ошибка, но ОТМЕНА сталкивались с причиной некоторой ошибки или отмены быть пользователь',
    'Транспортное получение не допускает состояние',
    'Другой имито-ключ',
    'Другой имито-заголовок',
    'Deimito ошибка файла',
    'Приложение заблокировано',
    'IP-траффик было блокировано', '', '', '', '',
    'Ошибочный адрес функции обратного вызова',
    'Недопустимый код устройства',
    'Ожидание устройства прервано',
    'Ошибка создания объекта устройства',
    'Драйвер или устройство не установлены',
    'Ошибка чтения идентификатора ключа',
    'Неправильный слот устройства',
    'Неопределенная функция',
    'Ключ не вставлен в устройство',
    'Ошибка чтения с устройства',
    'Ошибка записи на устройство',
    'Ошибка lentgh чтения или записи',
    'Ошибочные данные главной подписи',
    'Неправильное имя файла',
    'Ошибка в течение RegOpenKey',
    'Ошибка в течение RegQueryValueEx',
    'Ошибка в течение SwitchDesktop',
    'Ошибка в течение SystemParametersInfo',
    'Ошибка в течение CreateWindowEx',
    'Разблокировка невозможна - защелка занята',
    'Ошибка в течение CreateDesktop',
    'Ошибка в течение CreateThread',
    'Пользователь не имеет права подписывать',
    'Пользователь был удален из VPN',
    'Отсутствие (произвольного) объекта',
    '(Произвольный) объект уже существует',
    'Отсутствует файл присоединения',
    'Размер почты вне размера с допуском памяти сообщения',
    'Ошибка в функции обработки альтернативного хранения данных устройств',
    'Сохраните CSP ключ защиты в регистр',
    'Главный абонент пробует создать новую цифровую сигнатуру на АГЕНТСТВЕ АП',
    'Абонент пробует создать новую цифровую сигнатуру на не первичном АГЕНТСТВЕ АП',
    'Запрашиваемый сертификат недействителен.'#13#10'Системная дата вне диапазона действия сертификата',
    'Запрашиваемый сертификат не действует в указанном периоде',
    'Текущее удостоверение подписи пользователя несовместимо с форматом подписанного файла'
   );

function ErrToStr(Err: Integer): string;
begin
  if (0<=Err) and (Err<=204) then
    Result := ExtErrMesRus[Err]+#13#10+ExtErrMes[Err]+' ('+IntToStr(Err)+')'
  else
    Result := 'Unknown error'#13#10'Неизвестная ошибка ('+IntToStr(Err)+')'
end;

function GetSignIssuerName(const pEncodedCertificate: Pointer;
  const EncodedCertSize: dWord; var pSignInfo: PChar; var pSignInfoLen: dWord): Boolean;
var
  dwCertSize: dWord;        // Длина раскодированного сертификата
  dwCertInfoSize: dWord;    // Длина раскодированной информации о сертификате
  dwNameSize: dWord;        // Длина строки с именем пользователя
  pSignedCertInfo: PCERT_SIGNED_CONTENT_INFO;  // Указатель на раскодированный сертификат
  pCertInfo: PCERT_INFO;      // Указатель на раскодированную информацию о сертификате
  pSubjectName: PChar;   // Указатель на имя пользователя
begin
  Result := False;
  dwCertSize := 0;
  dwCertInfoSize := 0;
  dwNameSize := 0;
  pSignedCertInfo := nil;
  pCertInfo := nil;
  pSubjectName := nil;
  pSignInfoLen := 0;
  //* Декодируем закодированный сертификат */
  if CryptDecodeObject(X509_ASN_ENCODING or PKCS_7_ASN_ENCODING,
    X509_CERT, pEncodedCertificate,
    EncodedCertSize, 0, nil, @dwCertSize) then
  begin
    pSignedCertInfo := AllocMem(dwCertSize);
    try
      if CryptDecodeObject(X509_ASN_ENCODING or PKCS_7_ASN_ENCODING,
        X509_CERT, pEncodedCertificate,
        EncodedCertSize, 0, pSignedCertInfo, @dwCertSize) then
      begin
        //* Декодируем закодированный CERT_INFO */
        if CryptDecodeObject(X509_ASN_ENCODING or PKCS_7_ASN_ENCODING,
          X509_CERT_TO_BE_SIGNED,
          pEncodedCertificate,
          EncodedCertSize, 0, nil, @dwCertInfoSize) then
        begin
          pCertInfo := AllocMem(dwCertInfoSize);
          try
            if CryptDecodeObject(X509_ASN_ENCODING or PKCS_7_ASN_ENCODING,
              X509_CERT_TO_BE_SIGNED,
              pEncodedCertificate,
              EncodedCertSize, 0, pCertInfo, @dwCertInfoSize) then
            begin
              //* Декодируем закодированное имя подписавшего */
              dwNameSize := CertNameToStr(
                X509_ASN_ENCODING or PKCS_7_ASN_ENCODING,
                @pCertInfo.Subject, CERT_X500_NAME_STR, //* В данном случае возвращаем полное имя пользователя (все, что записано) одной строке */
                nil, 0);
              if dwNameSize>0 then
              begin
                pSubjectName := AllocMem(dwNameSize);
                try
                  dwNameSize := CertNameToStr(
                    X509_ASN_ENCODING or PKCS_7_ASN_ENCODING,
                    @pCertInfo.Subject,
                    CERT_X500_NAME_STR,
                    pSubjectName, dwNameSize);
                  if dwNameSize>0 then
                  begin
                    //* алокируем память и записываем имя пользователя */
                    pSignInfo := AllocMem(dwNameSize);
                    pSignInfoLen := dwNameSize;
                    Move(pSubjectName^, pSignInfo^, pSignInfoLen);
                    Result := True;
                  end;
                finally
                  FreeMem(pSubjectName);
                end;
              end;
            end;
          finally
            FreeMem(pCertInfo);
          end;
        end;
      end;
    finally
      FreeMem(pSignedCertInfo);
    end;
  end;
end;

function GetSignTime(const pEncodedSignerInfo: Pointer;
  const EncodedSignerInfoSize: dWord; var ATime: TDateTime): Boolean;
var
  dwSignerInfoSize, dwSignTimeSize, index: dWord;
  pMessageSignerInfo: PCMSG_SIGNER_INFO;
  DecodedFTime: FILETIME;
  pSignTime: SYSTEMTIME;
begin
  Result := False;
  dwSignerInfoSize := 0;
  dwSignTimeSize := 0;
  pMessageSignerInfo := nil;
  index := 0;
  //* Декодируем закодированную структуру */
  if CryptDecodeObject(X509_ASN_ENCODING or PKCS_7_ASN_ENCODING,
    PKCS7_SIGNER_INFO,
    pEncodedSignerInfo,
    EncodedSignerInfoSize, 0,
    nil, @dwSignerInfoSize) then
  begin
    //showmessage('1='+inttostr(dwSignerInfoSize));
    pMessageSignerInfo := AllocMem(dwSignerInfoSize);
    try
      if CryptDecodeObject(X509_ASN_ENCODING or PKCS_7_ASN_ENCODING,
        PKCS7_SIGNER_INFO,
        pEncodedSignerInfo,
        EncodedSignerInfoSize, 0,
        pMessageSignerInfo, @dwSignerInfoSize) then
      begin
        //* В CMSG_SIGNER_INFO дата/время подписи находится в кодированном виде */
        //* Декодируем закодированное имя подписавшего                          */
        //showmessage('2='+inttostr(dwSignerInfoSize));
        index := 0;
        while index<pMessageSignerInfo.AuthAttrs.cAttr do
        begin
          //showmessage('3='+inttostr(index)+' из '+inttostr(pMessageSignerInfo.AuthAttrs.cAttr));
          if StrLComp(szOID_RSA_signingTime,
            (pMessageSignerInfo.AuthAttrs.rgAttr[index]).pszObjId,
            StrLen(szOID_RSA_signingTime))=0 then
          begin
            //showmessage('4='+inttostr(index));
            //* Нашли нужный атрибут. */
            //* Хотя в общем случае в атрибуте может быть несколько */
            //* значений, для Времени Подписи используется один,    */
            //* поэтому выберем первый и раскодируем Время Подписи. */
            if CryptDecodeObject(X509_ASN_ENCODING or PKCS_7_ASN_ENCODING,
              PKCS_UTC_TIME,
              (pMessageSignerInfo.AuthAttrs.rgAttr[index]).rgValue.pbData,
              (pMessageSignerInfo.AuthAttrs.rgAttr[index]).rgValue.cbData,
              0, nil, @dwSignTimeSize) then
            begin
              //showmessage('5='+inttostr(dwSignTimeSize));
              if CryptDecodeObject(X509_ASN_ENCODING or PKCS_7_ASN_ENCODING,
                PKCS_UTC_TIME,
                (pMessageSignerInfo.AuthAttrs.rgAttr[index]).rgValue.pbData,
                (pMessageSignerInfo.AuthAttrs.rgAttr[index]).rgValue.cbData,
                0, @DecodedFTime, @dwSignTimeSize) then
              begin
                //showmessage('6='+inttostr(dwSignTimeSize));
                if FileTimeToLocalFileTime(DecodedFTime, DecodedFTime) then
                  if FileTimeToSystemTime(DecodedFTime, pSignTime) then
                  begin
                    Result := True;
                    ATime := SystemTimeToDateTime(pSignTime);
                    //showmessage('7=!!!');
                  end;
              end;
            end;
            index := pMessageSignerInfo.AuthAttrs.cAttr;
          end;
          Inc(index);
        end;
      end;
    finally
      FreeMem(pMessageSignerInfo)
    end;
  end;
end;

var
  UserList: TStringList = nil;

function InitUserNameList(fc: PEXT_FULL_CONTEXT;
  GetMes: Boolean; var Mes: string): Boolean;
var
  UserIdList: PChar;
  UserIDListSize: Integer;
  UserID: array[0..9] of Char;
  UserNick: array[0..91] of Char;
  UserName: array[0..71] of Char;
  I, J, ID, Err: Integer;
begin
  DoneUserNameList;
  Result := False;
  try
    UserIDList := nil;
    UserIDListSize := 0;
    if TExtGetUserIDList(GetExtPtr(fiGetUserIDList))(fc, UserIDList, UserIDListSize)=0 then
    begin
      //messagebox(0, PChar('size list!!!'+IntToStr(UserIDListSize)+']'), 'zzz', 0);
      UserList := TStringList.Create;
      Err := 0;
      I := 0;
      J := StrLen(UserIDList);
      while (Err=0) and (I+J<UserIDListSize) do
      begin
        if J>0 then
        begin
          StrLCopy(@UserID, @UserIDList[I], SizeOf(UserID)-1);
          Err := TExtGetUserAlias(GetExtPtr(fiGetUserAlias))(fc, UserID, UserNick, UserName);
          if Err=0 then
          begin
            StrUpper(@UserID);
            Val('$'+UserID, ID, Err);
            if Err=0 then
            begin
              StrUpper(@UserName);
              //messagebox(0, PChar('['+UserName+']'+Dec2Hex(ID,8)), 'zzz', 0);
              UserList.AddObject(UserName, TObject(ID))
            end
            else
              if GetMes then
                Mes := 'Ошибка оцифрения $'+UserID;
          end
          else
            if GetMes then
              Mes := 'Ошибка поиска имени '+UserID+' Err='+ErrToStr(Err);
        end;
        I := I+J+1;
        J := StrLen(@UserIDList[I]);
      end;
      Result := True;
    end
    else
      if GetMes then
        Mes := 'Ошибка взятия списка ExtGetUserIDList '+ErrToStr(Err);
  finally
    if UserIDList<>nil then
      TExtFreeMemory(GetExtPtr(fiFreeMemory))(UserIDList, UserIDListSize);
  end;
end;

procedure DoneUserNameList;
begin
  if UserList<>nil then
  begin
    UserList.Free;
    UserList := nil;
  end;
end;

function GetUserIdByName(pContext: PEXT_FULL_CONTEXT; const AName: string): string;
var
  I: Integer;
  UserID: array[0..9] of Char;
  UserNick: array[0..91] of Char;
  UserName: array[0..71] of Char;
begin
  Result := '';
  if pContext<>nil then
  begin
    StrPLCopy(UserNick, AName, SizeOf(UserNick)-1);
    if TExtGetUserID(GetExtPtr(fiGetUserID))(pContext, UserNick, UserID, UserName)=e_NO_ERROR then
      Result := UpperCase(Trim(UserID))
  end;
  if Length(Result)=0 then
  begin
    //messagebox(0, '11', '22', 0);
    if UserList<>nil then
    begin
      I := UserList.IndexOf(UpperCase(Trim(AName)));
      //messagebox(0, PChar('a!!!'+AName+'='+IntToStr(I)+']'), 'zzz', 0);
      if I>=0 then
        Result := Dec2Hex(Integer(UserList.Objects[I]), 8);
        //Format('%x',[Integer(UserList.Objects[I])]);
    end;
  end;
  //messagebox(0, '11', PChar('!!!!!!! ['+Result+']'), 0);
end;

var
  ItcsMainLib: HModule = 0;

function LoadItscLib(var Mes: string): Boolean;
var
  I: Integer;
  P: Pointer;
begin
  Result := ItcsMainLib<>0;
  if not Result then
  begin
    ItcsMainLib := LoadLibrary(Tcc_Itcs_Dll);
    if ItcsMainLib=0 then
      Mes := 'Ошибка подключения модуля '+Tcc_Itcs_Dll+' LastErr='
        +IntToStr(GetLastError)
    else begin
      Result := True;
      Mes := '';
      for I := Low(FuncList) to High(FuncList) do
      begin
        P := GetProcAddress(ItcsMainLib, FuncList[I].flDllName);
        FuncList[I].flPtr := P;
        if P=nil then
          Mes := #13#10+FuncList[I].flDllName;
      end;
      if Length(Mes)>0 then
        Mes := 'Не удалось загрузить функции:'+Mes+#13#10'из модуля '
          +Tcc_Itcs_Dll;
    end;
  end;
end;

function IsItscLibLoaded: Boolean;
begin
  Result := ItcsMainLib<>0;
end;

function GetExtPtr(FuncIndex: Integer): Pointer;
begin
  if IsItscLibLoaded then
  begin
    Result := FuncList[FuncIndex].flPtr;
    if Result=nil then
      MessageBox(0, PChar('Функция не проинициализирована ['
        +FuncList[FuncIndex].flDllName+']'), 'Запрос указателя функции',
        MB_OK or MB_ICONERROR);
  end
  else
    MessageBox(0, PChar('Модуль СКЗИ не загружен ['
      +FuncList[FuncIndex].flDllName+']'), 'Запрос указателя функции',
      MB_OK or MB_ICONERROR);
end;

procedure FreeItscLib;
begin
  if IsItscLibLoaded then
  begin
    FreeLibrary(ItcsMainLib);
    ItcsMainLib := 0;
  end;
end;

end.

