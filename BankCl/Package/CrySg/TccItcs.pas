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
{ ��� ���������������� �� �������� "��� ����", �������             }
{ �������� �� �����������������, �� ����������� ��� �� ���� ����.  }
{ ����� �� ����� ��������������� �� ����������� ����� ���������    }
{ � ��� �������������� (���������� ��� ������������).              }
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
  e_GET_HDR_ENV                = 92;   // Error header envelope reading�
  e_DEL_HDR_ENV                = 93;   // Error header envelope removing
  e_SHIFR_FILE                 = 94;   // Encrypt file error�
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

  // ����������� ������������ ���� ��������������, ����� � ���������� ������������
  _MAX_USER_ID_SIZE = 8;
  _MAX_USER_NAME_SIZE = 70;
  _MAX_USER_ALIAS_SIZE = 80;

  // ����� ������������� ����������������
  EXT_EXTERNAL_KEY_STORAGE = $00000001;     // ���� ��� �������� ������������� ������� ������������
  EXT_SILENT_MODE = $00000002;     // ���� ��� �������� ������, ��������������� ��������� � �������������.
  EXT_FORCE_SAVE_PASSWORD = $00000004;    // ����, ������� ���������, ���
    // ��������� ������ ���������� ��������� � �������. ���� ���� ���� �� ������, ��
    // ����������� ��������� ������ ����� �������� �� ��������� ��������������� ���������.
    // ������ ���� ������������, ���� ���������� ����� �� ��������� ������:
    // EXT_EXTERNAL_KEY_STORAGE, EXT_SILENT_MODE

  // ����� ��� �������� ���� ������ ��� ������� ������� / ����������
  EXT_FILE_DATA_FLAG = $00000001;    // ���� ��� �������� ����� � �������� ���� ������

  // ����� ��� �������� ������������ ������ �������
  EXT_MULTIPLE_SIGN         = $00000001;    // ������������� �������
  EXT_PKCS7_SIGN            = $00000002;    // ������� � ������� PKCS7,
    // ���� ���� ������������� ������������, ����� ����� EXT_EXTERNAL_KEY_STORAGE
    // ��� ������������� ����������
  EXT_RETURN_CONTROL_INFO   = $00000010;    // ���������, ��� ����������
    // ������� ����������� ���������� ��� �������� �������

  EXT_SMARTCARD_CONTAINER  = 'DEV|200|ITCS_SGN|'; // ��� ����������  "ASE Card Reader"

  EXT_ETOKEN_CONTAINER    = 'DEV|300|ITCS_SGN|';  // ��� ���������� E-token

  EXT_SCANTECH_CONTAINER   = 'DEV|600|ITCS_SGN|'; // ��� ���������� ScanTech Reader

type
  // LPCALLBACK_ROUTINE - ��������� �� ��� callback �������, ������������
  // �� ���������� ������ � ������������ ��������� EXT_Sign, EXT_VerifySign,
  // EXT_VerifyViewSignResult, EXT_Encrypt � EXT_Decrypt.
  // ������� ������ ���� ����������, ����� ������������� ��������� ���������
  // ������ ������. ���� ������� ���������� FALSE, �� ������� ���������
  // ���������� ������������, � ���������� ������� (EXT_Sign, EXT_Encrypt (�.�.�)
  // ������ ��� �������� e_ABORTED_BY_USER.
  LPCALLBACK_ROUTINE = function(TotalUnits: Int64; UnitsProcessed: Int64;
    lpCallBackData: Pointer): Boolean;

  // -------------------------------------------------------------------------
  // ��������� EXT_PATHNAMES �������������� ��� �������� �����������������
  // �������� ����������
  //
  // �������                    ��������
  // m_pszKeyDisketteDirectory    ���� � �������� � ������� ��������, ��������,
  //                                 "A:" ��� "C:\VipNet"
  // m_pszTransportDirectory      ���� � �������� �� ������������� (�������������
  //                                 ������������� ������������ ������)
  // -------------------------------------------------------------------------
  EXT_PATHNAMES = packed record
    m_pszKeyDisketteDirectory: PChar;
    m_pszTransportDirectory: PChar;
  end;

  // -------------------------------------------------------------------------
  // ��������� EXT_FULL_CONTEXT �������������� ��� �������� ���������
  // ���������������� � ��������� ����������� ��� � ����������������� ��������
  // �������          ��������
  // version          ���������� ������ ���� "�����-�". ���������������
  // hParent          ���������� ������������� ���� (���������� ���������)
  // dwFlags          �����, ����������� ������� ������� �������������.
  //                  ���������������. ������ ���� ��������� � 0;
  // pKeyStorage      ��������� �� ��������� EXT_PATHNAMES, ���������� ����
  //                  � ��������� � ������� � �������������
  // pProviderName    ���������������
  // pProviderError   ��� (�/��� ���������) ������ ���������������
  //                  ������������������ API
  // pCryptoProvider  ���������� ����������������� ��������� ����������
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
  // ��������� EXT_SIGN_RESULT ������������� ��� �������� ���������� ��������
  // ����� ������� ��� �������.
  //
  // �������               ��������
  // CertResult            ��������� �������� ������������� �����������
  // SignResult             ��������� �������� ������� ��� �������
  //
  // -------------------------------------------------------------------------
  PEXT_SIGN_RESULT = ^EXT_SIGN_RESULT;
  EXT_SIGN_RESULT = packed record
    CertResult: dWord;
    SignResult: dWord;
  end;

  // -------------------------------------------------------------------------
  // ��������� EXT_SIGN_CONTEXT ������������� ��� �������� ��������� �������
  //
  // �������               ��������
  // pData                 ������ ��� �������/�������� �������
  // DataLen               ���������� ���� ������ ��� �������/�������� �������
  // DataType              ��� ������, ������� ����� ���������.
  //                       (��������, ������ ��� ���� � �.�.)
  // Flags                 ����� ��� ������ ������� �������/�������� ������� 
  //                       (���������������)
  // pFunctionContext      ��������� �� ��������, ������������ ��������� ������
  //                       ������� �������, �������� �������. ���������������.
  //                       ������ ���� ��������� � NULL.
  // SignaturesNum         ���������� �������� (�� ������ ������
  //                       ����� ���� �������). ������������ ��� �������� �������,
  //                       �������� ���������� �� ��������.
  // pSignaturesData       ��������� �� ������� ������, ���������� ��������� 
  //                       �������. ������������ ��� �������. ���� pSignaturesData
  //                       �� ��������� � NULL, ���������, ��� �� ������� ������
  //                       ��������� ��������� ���������� �������, � ����������
  //                       �������� ��� ����. ��� ���� ������ �� ���������� ������
  //                       �������������, � ����� - �������������.
  //                       ���������� ���������� NULL, ���� �� ����������� 
  //                       ������������� ������������.
  // SignaturesDataLen     ������ ������� ������, ����������
  //                       ��������� �������. ������������ ��� �������.
  // pSignaturesResults   ��������� �� ������ � ������������ ��������. ����������
  //                       ��������� ������� = *pSignaturesNum. ������ �������
  //                       ������������ ����� ��������� EXT_SIGN_RESULT.
  //                       ������������ ��� �������� ������� �  ��������� 
  //                       ����������� �������� �������.
  //                       ������ ���������� ������ ������� �������� ������� 
  //                       � ������� ���� ����������� ���������� ����������,
  //                       ����� ���� ��� �������� ���������� � ���� ������, 
  //                       � ������� ������� EXT_FreeMemory
  // ResultsSize           ����� ������� � ������������ �������� 
  //                       ��������. ������������ ��� �������� �������.
  // pControlInfo          ��������� �� �������������� ����������, �������
  //                       ����� ������������ ��� ����������� �������� �������
  //                       (��������, HASH �� ����������� ������ � �.�.).
  //                       ��������. ������ ��������� ������������ ��� ��������
  //                       ������� � ��������� ����������� �������� �������. 
  //                       ������ ������������� ������ �������. �������� ��������
  //                       ��������������, �������, ���� ���������� ������� ������
  //                       �������� ������ ����������, ���������� ��� �������� 
  //                       ������� (EXT_VerifySign) ���������� ������� ���� Flags
  //                       EXT_RETURN_CONTROL_INFO.
  // ControlInfoSize       ������ �������������� ����������,
  //                       ��������� ��� �������� �������.
  //                       ��������. ������������ ��� �������� ������� � ���������
  //                       ����������� �������� �������.
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
  // ��������� EXT_SIGNATURE_CONTEXT ������������� ��� �������� ���������,
  // ����������� ������ ���
  //
  // �������          ��������
  // pCertificate     ��������� �� _CRYPTOAPI_BLOB, - ���������,
  //                  ���������� ������������ ����������;
  // CertificateLen   ����� ������, ���������� ������������ 
  //                  ����������;
  // pSignerInfo      ��������� �� _CMSG_SIGNER_INFO, - ���������, ���������� 
  //                  ������ � ����������� � ����������� ��������;
  // SignerInfoLen    ����� ������, ���������� ���������� � 
  //                  ����������� ��������
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
  // �������               ��������
  //
  // pInputData            ������� ������. ��� ���������� ��� plaintext,
  //                       ��� ������������� - cryptotext.
  //                       ���� ��� ������ (DataType) - ����, �� pInputData -
  //                       ��� �������� �����;
  // InputDataLen          ������ ������� ������. ���� ���������������
  //                       (����������������) ����, �� ����� ������� -1L, ����
  //                       ���������� ����������� ���� ���������;
  // pOutputData           �������� ������. ��� ���������� ��� cryptotext, 
  //                       ��� ������������� - plaintext.
  //                       ���� ��� ������ (DataType) - ����, �� pInputData - 
  //                       ��� ��������� �����. ��� ��������� ����� ����� 
  //                       ��������� � ������ �������� �����, ����� �������� 
  //                       ���� ���� ����������� ������ ��������.
  //                       ���� ��� ������ (DataType) - ������� ������, ��
  //                       ������� ������������/������������� ������� ������ ���
  //                       �������� ������. ����� ����, ��� ������ �������������
  //                       � ���� ������, ������ ������ ���� ����������� 
  //                       �������� EXT_FreeMemory();
  // OutputDataLen         ������ �������� ������. � OutputDataLen ����� ���������� 
  //                       ������ �������� ���������� ��� ������������/�������������
  //                       ������� ������.
  //                       ���� ������ ����� ����� ������������ ��� ������������ 
  //                       ������, ������� ���� �������� � ���������� ���������
  //                       ������� ������������/������������� ������� ������.
  // DataType              ��� ���������������/���������������� ������. 
  //                       ��� ����� ���� ������� ������ ��� ����.
  // Flags                 ����� ����������. ���������������. �������� ������ ���� 
  //                       ��������� � 0UL;
  // pReceivers            ��� ������������� ������ ��� "C-����" ������ � 
  //                       ��������������� ����������, ��� �������� ��������������
  //                       �������������.
  //                       ��� ������������� � �������� ������������ � ��������� 
  //                       ������ �����������, ������ �������� �������� �������
  //                       ����������� ��� ������� ���� ����������� ������.
  //                       ������ ��������������� ������������ ����� 
  //                       ������������������ "C-����" �����, ����������� '\0'. 
  //                       ��������� ���������� ������������� ����� '\0'.
  //                       ��� ������ ������� ��������� ������ ����������� ��
  //                       ������� ������ ����� �������� ������, �
  //                       ����� ����, ��� ������ ������������� � �������� 
  //                       ������� ������ ������ ������ ���� �����������
  //                       �������� EXT_FreeMemory().
  // ReceiversBytesNum     ������ ������ ����������� � ������, ������� 
  //                       �������������� '\0''\0'. 
  //                       ������������ ��� ������ ������� ��������� ������
  //                       ����������� �������������� �����.
  //                       ���� ������ ����� ������������ ��� ������������ ������,
  //                       ������� ���� �������� � ���������� ��������� �������
  //                       ��������� ������ ����������� �������������� �����.
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
  // ������� EXT_InitCrypt ������������ �������� ���������� ������ � �������������
  // ������ � ������� ��������. ����� ����� �������������� �������� �������
  // ��������� ���������� ������, �, ���� ������� ���������, ���������� ����������
  // ����������� ������ ��������. ��� ��������� ������� ������� ���������� ������
  // ����� ��������� ������ ������ �������. ��� ��������� ������ � ��������� ���� 
  // ���������� ������� ������� EXT_CloseCrypt.
  //
  // ��� ������������� ����� ����� ��������������� �������� 
  // EXT_InitCryptEx (��. ����).
  //
  // ��������� �������:
  //
  // ��������                   ��������
  // psPassword                 ������ ��������
  // PasswordLen                ����� ������ ��������
  // pContext                   ��������� �� ��������� EXT_FULL_CONTEXT
  //
  //
  // ������� ��������           �������� ��������
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
  // ������� EXT_InitCryptEx ������������ ���� ������ � ���������� ������.
  // ������ ������� ������������ ����������� ������ ��������, � ����� ��������
  // �������� �������������� �������� ������� ��������� ���������� ������ �
  // (���� ������� ���������) ���������� ����������� ������ ��������.
  // ������ ������� ��������� ����������� ���� ������ � ���������� ��� �
  // ������� ����������� ���������.
  //
  // ��������� �������:
  //
  // ��������                   ��������
  // pContext                   ��������� �� ��������� EXT_FULL_CONTEXT
  //
  // ������� ��������           �������� ��������
  // pContext->pKeyStorage 
  //                            pContext->pCryptoProvider
  //                            pContext->pProviderError
  //
  // ����������: pContext->pKeyStorage - �������������� ��������.
  // ��������, ���� ����� �����, ����������� �� � ����������� ��� ���� ��������
  // -------------------------------------------------------------------------
  TExtInitCryptEx = function(pContext: PEXT_FULL_CONTEXT): Integer; stdcall;

  // -------------------------------------------------------------------------
  // ������� EXT_CloseCrypt ������������� ��� �������� �������������� �����������
  // ������������������ ���������. ��� ������ ���������� ��������������� ����� 
  // ����������� ������ � �����������. ����� ������ ������ ������� ��� 
  // ������������� ������ � ���� ���������� ����� ������� ������� 
  // EXT_InitCrypt ��� EXT_InitCryptEx.
  //
  // ��������              ��������
  // pContext              ��������� �� �������������� ���������� �������� 
  //                       ����������
  //
  // ������� ��������      �������� ��������
  // pContext
  // -------------------------------------------------------------------------
  TExtCloseCrypt = procedure(pContext: PEXT_FULL_CONTEXT); stdcall;

  // -------------------------------------------------------------------------
  // ������� EXT_FreeMemory ������������� ��� ������������ ������, ����������
  // ��������� ���������� "�����-�".
  //
  // ��������              ��������
  // pData                 ��������� �� ������������� ������� ������
  // DataLen               ����� �������������� ������. ���� �������, ��
  //                       ����� ������������� ������ ��������� ���������� ����
  //                       ����� ��������� ������. ���� �������� ����� ����,
  //                       ������ ������ ������������� �� ��������� � pData.
  //
  // ������� ��������      �������� ��������
  // pData
  // DataLen
  // -------------------------------------------------------------------------
  TExtFreeMemory = function(pData: Pointer; DataLen: dWord): Integer; stdcall;

  // -------------------------------------------------------------------------
  // ������� EXT_AllocMemory ������������� ��� ������� ������. ������ �������
  // ����� ������������ ��� ������������� �������������� ������������,
  // ������������ �� �������. ��������, ������������� ��������� ������� ����� 
  // ���� �������� � �����, � ����� ������ � ���������� ������ �������� ������
  // � ������� � ��y���� ������� (EXT_Sign ��� �������� pSignaturesData 
  // ��������� EXT_SIGN_CONTEXT). 
  // ���� ������ ����������, ����������� ��������� �� ���������� ������� ������,
  // � ��������� ������ �������� NULL.
  // ������, ���������� ������ ��������, ������ ���� ����������� ��������
  // EXT_FreeMemory.
  //
  // ��������              ��������
  // DataLen               ����� ����������� ������
  //
  // ������� ��������      �������� ��������
  // DataLen
  // -------------------------------------------------------------------------
  TExtAllocMemory = function(DataLen: dWord): Pointer; stdcall;

  // -------------------------------------------------------------------------
  // ������� EXT_GetErrorDefinition ������������� ��� ��������� ���������
  // ���������� �� ������. ������� �� �������� ������. ��� ���������� ����������
  // � ���� ������ � ���������� ������� �������� ������.
  //
  // ���� ��������� pErrDefinition ��������� � NULL, �� ������� �������� 
  // ������ ������, ������� �� ��������� ��� ���������� �������� ���� ������, 
  // ������� '\0', � ������ ���� ������ � ��������� pErrDefSize;
  //
  // ��������              ��������
  // ErrCode               ��� ������ ������� ������ ����
  // pErrDefinition        ��������� �� ����� ��� ���������
  // pErrDefSize           ��������� �� ����� ������
  // -------------------------------------------------------------------------
  TExtGetErrorDefinition = procedure(const ErrCode: Integer;
    pErrDefinition: PChar; var pErrDefSize: dWord); stdcall;

  TExtRetCode2WinErr = function(RetCode: Integer): dWord; stdcall;

  TExtRetCode2HResult = function(RetCode: Integer): HResult; stdcall;

  // -------------------------------------------------------------------------
  // ������� ��������� ������������ �������������� ������������
  //
  // ����������� ��� ��������� �������������� ������������
  // � ������ ������ ������������. 
  //
  // ��������� �������:
  // ��������              ��������
  // pContext              ��������� �� ��������� EXT_FULL_CONTEXT
  // pszUserID             ��������� �� �����, �� �������� ����� ������� 
  //                       ������������� ������������. ������ ��������������
  //                       ��������� ������� ���������, ������� ���������� ��������� 
  //                       ������ �������� ��������� �� ����� �������� � 8 + 1 ������ 
  //                       (���� - ��� '\0'). ���� �������� ����� NULL,
  //                       �� ������������� �� ������������.
  //
  // ������� ��������           �������� ��������
  // pContext
  // pszUserID                  pszUserID
  //                            pContext->pProviderError
  // -------------------------------------------------------------------------
  TExtGetOwnID = function(pContext: PEXT_FULL_CONTEXT; pszUserID: PChar): Integer; stdcall;

  // -------------------------------------------------------------------------
  // ������� ��������� ������ ��������������� ���� �������������
  //
  // ����� ��������� ������� EXT_GetUserIDList �������� ppszUserIDList
  // ����� ��������� ��������� �� ������ ��������������� ������������������
  // �������������. ������� ������, �� ������� ��������� ppszUserIDList
  // ������ ���� ����������� ���������� ��������, ����� ����, ��� ��������
  // ���������� � ���� ������, � ������� ������� EXT_FreeMemory.
  // ����� ��������� ������� EXT_GetUserIDList �������� ppszUserIDList �����
  // ��������� ��������� �� ������ ��������������� ������������������ �������������.
  // ������ ������ ����������� ��. � �������� ��������� EXT_CRYPT_CONTEXT.
  // ������� ������, �� ������� ��������� ppszUserIDList ������ ���� �����������
  // ���������� ��������, ����� ����, ��� �������� ���������� � ���� ������,
  // � ������� ������� EXT_FreeMemory.
  //
  // ��������� �������:
  //
  // ��������              ��������
  // pContext              ��������� �� ��������� EXT_FULL_CONTEXT
  // ppszUserIDList        ��������� �� ���������, �� �������� ����� ���������
  //                       ������ ��������������� ������������������ �������������.
  //                       ������ ������ ������������� ��. � �������� ���������
  //                       EXT_CRYPT_CONTEXT.
  // pUserIDListSize       ��������� �� ����������, � ������� ����� ��������� ������
  //                       ������, ���������� ��� ������ ���������������
  //                       �������������. ����� ���� ������� NULL, ���� �� �����
  //                       ���������� ���������� ���������� ������. �������� �����
  //                       ���� ����������� ��� ������������ ������ ��� ��������
  //                       � ������� EXT_FreeMemory
  //
  // ������� ��������           �������� ��������
  // pContext
  // ppszUserIDList             ppszUserIDList
  // pUserIDListSize            pUserIDListSize
  //                            pContext->pProviderError
  // -------------------------------------------------------------------------
  TExtGetUserIDList = function(pContext: PEXT_FULL_CONTEXT;
    var ppszUserIDList: PChar; var pUserIDListSize: Integer): Integer; stdcall;

  // -------------------------------------------------------------------------
  // ������� ��������� ���������� � ����� ������������ �� ��� ��������������
  //
  // ������� ����������� ��� ��������� ���������� (�/��� �����) ������������.
  // ������ ������������ ����� ������ ������� EXT_GetReceivers, ������� ����������
  // ������ ��������������� �������������.
  //
  // ��������� �������:
  //
  // ��������              ��������
  // pContext              ��������� �� ��������� EXT_FULL_CONTEXT
  // pszUserID             ��������� �� ������, ���������� �������������
  //                       ������������;
  // pszUserAlias          ��������� �� ���������, �� �������� ����� �������
  //                       ��������� ������������. ������ ���������� ��������� 
  //                       �������������� ���������, ������� ���������� ���������
  //                       ������ �������� ��������� �� ����� �������� �
  //                       80 + 1 ������ (���� - ��� '\0').
  //                       ���� �������� ����� NULL, �� ��������� �� ������������.
  // pszUserName           ��������� �� ���������, �� �������� ����� �������� ��� 
  //                       ������������. ������ ����� ��������� ������������
  //                       ���������, ������� ���������� ��������� ������ �������� 
  //                       ��������� �� ����� �������� � 70 + 1 ������ 
  //                       (���� - ��� '\0'). ���� �������� ����� NULL,
  //                       �� ��� ������������ �� ������������.
  //
  // ������� ��������           �������� ��������
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
  // ������� ��������� �������������� � ����� ������������ �� ��� ����������
  //
  // ������� EXT_GetUserID ����������� ��� ��������� �������������� (�/��� �����) 
  // ������������. ������ ������������ ����� ������ ������� EXT_Encrypt,
  // EXT_Decrypt, ������� ������� �� ���� �������������� �������������.
  //
  // ��������� �������:
  //
  // ��������              ��������
  //
  // pContext              ��������� �� ��������� EXT_FULL_CONTEXT
  // pszUserAlias          ��������� �� ������, ���������� ��������� ������������;
  // pszUserID             ��������� �� �����, �� �������� ����� ������� 
  //                       ������������� ������������. ������ ��������������
  //                       ��������� ������� ���������, ������� ���������� ���������
  //                       ������ �������� ��������� �� ����� ��������
  //                       � 8 + 1 ������ (���� - ��� '\0'). 
  //                       ���� �������� ����� NULL, �� ������������� �� ������������.
  // ppszUserName          ��������� �� ���������, �� �������� ����� �������� ���
  //                       ������������. ������ ����� ��������� ������������ 
  //                       ���������, ������� ���������� ��������� ������ �������� 
  //                       ��������� �� ����� �������� � 70 + 1 ������
  //                       (���� - ��� '\0'). 
  //                       ���� �������� ����� NULL, �� ��� ������������
  //                       �� ������������.
  // 
  // ������� ��������           �������� ��������
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
  // ������� ������� ������/�����
  //
  // ��������� �������:
  //
  // ��������              ��������
  // pContext              ��������� �� ��������� EXT_FULL_CONTEXT
  // pSignContext          ��������� �� ��������� ��������� �������
  //                       EXT_SIGN_CONTEXT, ������� ������ ���� ���������
  //                       ��������� �������:
  //                            pData     = ��������� �� ������������� ������
  //                            DataLen   = ����� ������������� ������ � ������
  //                            DataType  = ��� ������ (������ / ����)
  //                            Flags     = 0
  //
  // ������� ��������                �������� ��������
  // pContext->pCryptoProvider
  // pSignContext->pData
  // pSignContext->DataLen
  // pSignContext->DataType
  // pSignContext->Flags
  //                                 pSignContext->pSignaturesData
  //                                 pSignContext->OutSignaturesDataLen
  //                                 pContext->pProviderError
  //
  // ����� ������ ������� pSignContext->pSignaturesData ����� ��������� �������
  // ��� �������, � pSignContext->OutSignaturesDataLen - ����� ������� � ������.
  // ������� ������ pSignContext->pSignaturesData ������������� ����������
  // ��������, ����� ���� ��� �������� ���������� � ���� ������, � �������
  // ������� EXT_FreeMemory.

  // ����������: ������������� ������� ����� � ������ �� ������������.
  // -------------------------------------------------------------------------
  TExtSign = function(pContext: PEXT_FULL_CONTEXT;
    pSignContext: PEXT_SIGN_CONTEXT; pCallBackData: PEXT_CALLBACK_DATA): Integer; stdcall;

  // -------------------------------------------------------------------------
  // ������� EXT_VerifySign ������������� ��� �������� ������� ��� 
  // ������� / ������.
  //
  // ��������� �������:
  //
  // ��������         ��������
  // pContext         ��������� �� ��������� EXT_FULL_CONTEXT
  // ��� ������������� ������� PKCS#7 ���� �������� ����� ���� NULL
  //
  // pSignContext     ��������� �� ��������� ��������� ������� 
  //                  EXT_SIGN_CONTEXT, ������� ������ ���� ��������� 
  //                  ��������� �������:
  //                       pData               = ��������� �� ����������� ������
  //                       DataLen             = ����� ����������� ������ � ������
  //                       DataType                 = ��� ������ (������ / ����)
  //                       Flags               = 0
  //                       pSignaturesData     = ��������� �� ���
  //                       SignaturesDataLen   = ����� ���
  //
  // ������� ��������                     �������� ��������
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
  // ����� ������ ������� �������� pSignContext->SignaturesNum ����� ���������
  // ���������� �������� (����), � pSignContext->pSignaturesResults - ���������
  // �� ������ �������� EXT_SIGN_RESULT, ��������������� ����������� ��������
  // �������.
  // ������� ������ pSignContext->pSignaturesResults ������������� ����������
  // ��������, ����� ���� ��� �������� ���������� � ���� ������, � ������� 
  // ������� EXT_FreeMemory.
  //
  // ����������: ������������� �������� ������� ����� � ������ �� ������������.
  // ------------------------------------------------------------------------- 
  TExtVerifySign = function(pContext: PEXT_FULL_CONTEXT;
    pSignContext: PEXT_SIGN_CONTEXT; pCallBackData: PEXT_CALLBACK_DATA): Integer; stdcall;

  // -------------------------------------------------------------------------
  // ������� EXT_GetSignInfo ������������� ��� ��������� ����������
  // �� �������. ������ ������� ��������� ������, ���������� ��� ������� 
  // ���������, � ���������� ����������, ��������������� ����������� �������,
  // � ���������� � ����������� ��������. ��� �������� ������������� ��� 
  // ������ ������������ � ��������, ��������������� ���������� Microsoft
  //
  // ��������� �������:
  // ��������              ��������
  // pContext              ��������� �� ��������� EXT_FULL_CONTEXT
  // pSignContext          ��������� �� ��������� ��������� �������
  //                       EXT_SIGN_CONTEXT, ������� ������ ���� ��������� 
  //                       ��������� �������:
  //                            Flags               = 0
  //                            pSignaturesData     = ��������� �� ���
  //                            SignaturesDataLen   = ����� ���
  //                            SignaturesNum       = ������ �������, ��� ������� 
  //                            ����� �������� ���������� (������ ��������� �� �������).
  // pSignatureContext     ��������� �� ��������� ��������� ��������� �������
  //                       EXT_SIGNATURE_CONTEXT
  //
  // ������� ��������                     �������� ��������
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
  // ����� ������ ������� pSignatureContext->pCertificate �������� ���������
  // �� ������������ ����������, pSignatureContext->CertificateLen �������� ����� 
  // ����, ���������� ������������ ������������;
  // pSignatureContext->pSignerInfo �������� ��������� �� ������������ ����������
  // � ����������� ��������, pSignatureContext->SignerInfoLen �������� �����
  // ����, ���������� ����������� � ����������� ��������. 
  //
  // ������� ������ pSignatureContext->pCertificate � pSignatureContext->pSignerInfo 
  // ������ ���� ����������� ���������� ��������
  // ����� ����, ��� �������� ���������� � ���� ������, � ������� 
  // ������� EXT_FreeMemory.
  // -------------------------------------------------------------------------
  TExtGetSignInfo = function (pContext: PEXT_FULL_CONTEXT;
    pSignContext: PEXT_SIGN_CONTEXT; pSignatureContext: PEXT_SIGNATURE_CONTEXT): Integer; stdcall;

  // -------------------------------------------------------------------------
  // ������� EXT_VerifyViewSignResult ������������� ��� �������� � ��������� 
  // ���������� ������� ��� ������� (� ����� ��� ��������� ����������� 
  // ������������  ������������). ����� ��������������� ����� ������������� 
  // �������� EXT_ViewSignResult, ������� ����� ���������� ���� � 
  // ������������ �������� ������� ��� ������� � ����������� ������������, 
  // �� � ������� �� ������, �� ��������� �������, � ���� ���������� ������,
  // ���������� ��� �������� ������� (EXT_VerifySign).
  //
  // ��������� �������:
  // ��������              ��������
  // pContext              ��������� �� ��������� EXT_FULL_CONTEXT
  // pSignContext          ��������� �� ��������� ��������� ������� 
  //                       EXT_SIGN_CONTEXT, ������� ������ ���� ��������� 
  //                       ��������� �������:
  //                            Flags               = 0
  //                            pSignaturesData     = ��������� �� ���
  //                            SignaturesDataLen   = ����� ���
  //                            pTitleStr           = ������, ���������� �����-���� �������� 
  //                                                  ����������� ������;
  //                                                  ����� �������������, �� ���� pTitleStr ����� 
  //                                                  ���� ������ ����.
  //
  // ������� ��������                     �������� ��������
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
  // ������� EXT_ViewSignResult ������������� ��� ���������
  // ���������� ������� ��� ������� (� ����� ��� ��������� �����������
  // ������������  ������������). �� ��������� �������, � ���� ���������� ������,
  // ���������� ��� �������� ������� (EXT_VerifySign).
  //
  // ��������� �������:
  // ��������              ��������
  // pContext              ��������� �� ��������� EXT_FULL_CONTEXT
  // pSignContext          ��������� �� ��������� ��������� �������
  //                       EXT_SIGN_CONTEXT, ������� ������ ���� ���������
  //                       ��������� �������:
  //                            Flags               = 0
  //                            pSignaturesData     = ��������� �� ���
  //                            SignaturesDataLen   = ����� ���
  //                            pSignaturesResults        = ��������� �� ������ � ������������ ��������.
  //                            ResultsSize         = ����� ������� � ������������ �������� 
  //                                                  ��������.
  //                            pControlInfo        = ��������� �� �������������� ����������, 
  //                                                  ������� ������������ �������� �������
  //                            ControlInfoSize     = ������ �������������� ����������, 
  //                                                  ��������� ��� �������� �������.
  //                            pTitleStr           = ������, ���������� �����-���� ��������
  //                                                  ����������� ������;
  //                                                  ����� �������������, �� ���� pTitleStr ����� 
  //                                                  ���� ������ ����.
  //
  // ������� ��������                     �������� ��������
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
  // ������� ������������ ������/�����
  //
  // ��������� �������:
  //
  // ��������              ��������
  // pContext              ��������� �� ��������� EXT_FULL_CONTEXT
  // pCryptContext         ��������� �� ��������� ��������� �������
  //                       EXT_CRYPT_CONTEXT, ������� ������ ���� ���������
  //                       ��������� �������:
  //                            pInputData     = ��������� �� ��������������� ������
  //                            InputDataLen   = ����� �������� ������ � ������.
  //                                           ��� ����� ������ �������� �� �����
  //                                           ��������, ��� ��� ������ ����� ����� 
  //                                           �������� ������ �������;
  //                            DataType       = ��� ������ (������ / ����)
  //                            Flags          = 0
  //                            pOutputData    = ��������� �� ��� ��������� �����,
  //                                           ���� �������������� ������������
  //                                           �����, ����� ������ ���� ���������
  //                                           � NULL.
  //                            pReceivers     = ��������� �� ������ �����������,
  //                                           ��� ������� ���������� �����������
  //                                           ������. ������ ������ ��. � ��������
  //                                           ��������� EXT_CRYPT_CONTEXT;
  // pCallBackContext      ��������� �� ��������� EXT_CALLBACK_DATA, ������� ���������
  //                       ���������� ��������� ������������ �������� ���������� ���
  //                       �������������� ��������� ��� ����������� ��������� ��������.
  //
  // ������� ��������                �������� ��������
  // pContext->pCryptoProvider
  // pCryptContext->pInputData
  // pCryptContext->InputDataLen
  // pCryptContext->DataType
  // pCryptContext->Flags
  // pCryptContext->pOutputData      pCryptContext->pOutputData
  //                                 pCryptContext->OutputDataLen
  //                                 pContext->pProviderError
  //
  // ���� ������������� ������� ������, �� ����� ��������� ������� 
  // pCryptContext->pOutputData ����� ��������� ������������
  // ������������� ������ � ���������������� ��� �������������,
  // pCryptContext->OutputDataLen - ����� �������� ������ � ������,  
  // ������� ������ pCryptContext->pOutputData ������������� ����������
  // ��������, ����� ����, ��� �������� ���������� � ���� ������, � �������
  // ������� EXT_FreeMemory.
  // ���� ������������� ����, �� pCryptContext->pOutputData �������� �������
  // ����������, � pCryptContext->OutputDataLen �� ������������. ����������� 
  // ������ ������� � ������ ������ �������� ������������� ����, ��� ��������
  // ���� �������� ������� � ��������� pCryptContext->pOutputData.
  // -------------------------------------------------------------------------
  TExtEncrypt = function(pContext: PEXT_FULL_CONTEXT;
    pCryptContext: PEXT_CRYPT_CONTEXT; pCallBackData: PEXT_CALLBACK_DATA): Integer; stdcall;

  // -------------------------------------------------------------------------
  // ������� ������������� ������/�����
  //
  // ��������� �������:
  //
  // ��������              ��������
  // pContext              ��������� �� ��������� EXT_FULL_CONTEXT
  // pCryptContext         ��������� �� ��������� ��������� �������
  //                       EXT_CRYPT_CONTEXT, ������� ������ ���� ���������
  //                       ��������� �������:
  //                            pInputData     = ��������� �� ������������� ������
  //                            InputDataLen   = ����� ������������� ������ � ������.
  //                                           ��� ����� ������ �������� �� �����
  //                                           ��������, ��� ��� ������ ����� �����
  //                                           �������� ������ �������;
  //                            DataType       = ��� ������ (������ / ����)
  //                            Flags          = 0
  //                            pOutputData    = ��������� �� ��� ��������� �����,
  //                                           ���� �������������� ������������
  //                                           �����, ����� ������ ���� ���������
  //                                           � NULL.
  //                            pReceivers     = ��������� �� ����������,
  //                                           ��� �������� ��������������� ������.
  //
  // ������� ��������                �������� ��������
  // pContext->pCryptoProvider
  // pCryptContext->pInputData
  // pCryptContext->InputDataLen
  // pCryptContext->DataType
  // pCryptContext->Flags
  // pCryptContext->pOutputData      pCryptContext->pOutputData
  //                                 pCryptContext->OutputDataLen
  //                                 pContext->pProviderError
  //
  // ���� �������������� ������� ������, �� ����� ��������� �������
  // pCryptContext->pOutputData ����� ��������� �������������� ������,
  // pCryptContext->OutputDataLen - ����� �������� ������ � ������,
  // ������� ������ pCryptContext->pOutputData ������������� ����������
  // ��������, ����� ����, ��� �������� ���������� � ���� ������, � �������
  // ������� EXT_FreeMemory.
  // ���� ������������� ����, �� pCryptContext->pOutputData �������� �������
  // ����������, � pCryptContext->OutputDataLen �� ������������. �����������
  // ������ ������� � ������ ������ �������� �������������� ����, ��� ��������
  // ���� �������� ������� � ��������� pCryptContext->pOutputData.
  // -------------------------------------------------------------------------
  TExtDecrypt = function(pContext: PEXT_FULL_CONTEXT;
    pCryptContext: PEXT_CRYPT_CONTEXT; pCallBackData: PEXT_CALLBACK_DATA): Integer; stdcall;

  // -------------------------------------------------------------------------
  // ������� ��������� ������ ����������� ������������� ������ (������/�����)
  //
  // ��������� �������:
  //
  // ��������              ��������
  // pContext              ��������� �� ��������� EXT_FULL_CONTEXT
  // pCryptContext         ��������� �� ��������� ��������� �������
  //                       EXT_CRYPT_CONTEXT, ������� ������ ���� ��������� 
  //                       ��������� �������:
  //                            pInputData     = ��������� �� ������������� ������
  //                            InputDataLen   = ����� ������������� ������ � ������.
  //                                           ��� ����� ������ �������� �� ����� 
  //                                           ��������, ��� ��� ������ ����� �����
  //                                           �������� ������ �������;
  //                            DataType       = ��� ������ (������ / ����)
  //                            Flags          = 0
  //
  // ������� ��������                �������� ��������
  // pContext->pCryptoProvider
  // pCryptContext->pInputData
  // pCryptContext->InputDataLen
  // pCryptContext->DataType
  // pCryptContext->Flags
  //                                 pCryptContext->pReceivers
  //                                 pContext->pProviderError
  //
  // ����� ��������� ������� �������� pCryptContext->pReceivers ����� ���������
  // ������ ����������� ������������� ������. ������ ������ ����������� ��.
  // � �������� ��������� EXT_CRYPT_CONTEXT.
  // ������� ������ pCryptContext->pReceivers ������������� ����������
  // ��������, ����� ����, ��� �������� ���������� � ���� ������, � �������
  // ������� EXT_FreeMemory.
  // -------------------------------------------------------------------------
  TExtGetReceivers = function(pContext: PEXT_FULL_CONTEXT;
    pCryptContext: PEXT_CRYPT_CONTEXT): Integer; stdcall;

  // -------------------------------------------------------------------------
  // ������� ��������� ��������������� �������������, ���������������
  // ���������� ����������
  //
  // ������ ������������, ���� ������ ���������� ������������ ���������
  // �������������. � ������� �� �������� EXT_GetUserID, �������
  // ���������� ������ ������������, ������ ������� ���������� ������
  // �������������, ��� ������� ������ ��������� ���������.
  //
  // ������� ������, �� ������� ��������� ppszUserIDList
  // ������ ���� ����������� ���������� ��������, ����� ����, ��� ��������
  // ���������� � ���� ������, � ������� ������� EXT_FreeMemory.
  // ����� ��������� ������� EXT_GetUserIDList �������� ppszUserIDList �����
  // ��������� ��������� �� ������ ��������������� ������������������ �������������.
  // ������ ������ ����������� ��. � �������� ��������� EXT_CRYPT_CONTEXT.
  // ������� ������, �� ������� ��������� ppszUserIDList ������ ���� �����������
  // ���������� ��������, ����� ����, ��� �������� ���������� � ���� ������,
  // � ������� ������� EXT_FreeMemory.
  //
  // ��������� �������:
  //
  // ��������              ��������
  //
  // pContext              ��������� �� ��������� EXT_FULL_CONTEXT
  // pszUserAlias          ��������� �� ������, ���������� ��������� ������������;
  // ppszUserIDList        ��������� �� ���������, �� �������� ����� ���������
  //                       ������ ��������������� ������������������ �������������.
  //                       ������ ������ ������������� ��. � �������� ���������
  //                       EXT_CRYPT_CONTEXT.
  // pUserIDListSize       ��������� �� ����������, � ������� ����� ��������� ������
  //                       ������, ���������� ��� ������ ���������������
  //                       �������������. ����� ���� ������� NULL, ���� �� �����
  //                       ���������� ���������� ���������� ������. �������� �����
  //                       ���� ����������� ��� ������������ ������ ��� ��������
  //                       � ������� EXT_FreeMemory
  //
  // ������� ��������           �������� ��������
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
  // EXT_GenRandom ��������� ����� pbBuffer ���������� dwLen �������.
  // � ������ ������ ������� ���������� 0.
  // -------------------------------------------------------------------
  TExtGenRandom = function(pContext: PEXT_FULL_CONTEXT;
    pbBuffer: PChar; dwLen: dWord): Integer; stdcall;

  // -------------------------------------------------------------------
  // EXT_HashData ��������� ����������� ������, �������������
  // �� ������ pbData ������ dwDataLen ����.
  // � ������ ������ ������� ���������� 0.
  //
  // ���� pbHash ����� ����, �� �� ������ pdwHashLen ����� ���������� 
  // �����, ����������� �� ������ ��������� hash-��������.
  // ���� pbHash �� ����� ����, �� �� ���������� ������ ����� 
  // ����������� ����������� hash-�������� ��������, ������ *pdwHashLen.
  // ���� ������, �� ������� ��������� pdwHashLen ��������� ������������
  // ����� hash-��������, �� ������� ������ ���, ����������� �� �������
  // �������� ���������.
  // -------------------------------------------------------------------
  TExtHashData = function(pContext: PEXT_FULL_CONTEXT;
    const pbData: PChar; dwDataLen: dWord;
    pbHash: PChar; var pdwHashLen: dWord): Integer; stdcall;
  // ������� ���������� �������� ������ �� ���������� � �������
  //   Err - ����� ������
  //   ��������� - ������ ���������
  function ErrToStr(Err: Integer): string;

  // ---------------------------------------------------------------------------------
  //   ������� GetSignIssuerName ������������� ��� ��������� ����������
  //   (� ������ ������, ������������ ������ ��� (���� Subject))
  //   � ����������� ������������.
  //
  //   ���������:
  //   pEncodedCertificate   -    �������������� ���������� (����������, ��������,
  //                             ��� ������ ������� �������� �������)
  //   EncodedCertSize       -    ����� ��������������� �����������
  //   pName                 -    ��������� �� ������, ���������� ��������� ������,
  //                              � ������� �������� ��� ������������ ������������
  //   pNameLen              -    ��������� �� ������ � ������ ������.
  //                              ����� ������ �������� '\0'.
  // ---------------------------------------------------------------------------------
  function GetSignIssuerName(const pEncodedCertificate: Pointer;
    const EncodedCertSize: dWord; var pSignInfo: PChar; var pSignInfoLen: dWord): Boolean;

  // ---------------------------------------------------------------------------------
  //   ������� GetSignTime ������������� ��� ��������� ����������
  //   ����/������� �������
  //
  //   ���������:
  //   pEncodedCertificate   -    �������������� ��������� � ����������� ��
  //                              ������������ ������������
  //   EncodedSignerInfoSize -    ����� �������������� ���������
  //   pSignTime             -    ��������� �� ����/����� �������
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
    '�� ������� ������� ������',
    '�������� ������� �� ���� �������',
    '��������� ������ �� �����',
    '������� ����������',
    '��������� ���� �� ������',
    '������ ��� ������ �����',
    '������ ��� ������ � ����',
    '���������� ��� �����-������� ��������',
    '������� �� ��� ������',
    '������������ ������ ����������',
    '������������ ��������� �� ����� ������',
    '������ �� ��� ������',
    '������������ ��������� �� ���� ����������. ��� �� ������',
    '������������ ��������� ���� ���������� ���������� (���������). ��� �� ������',
    '��������� �������������� (������, ����������, � �.�.) ����������� (����������). ��� �� ������',
    '��� ������������������� ���������� ��������� ���������������� ���������� ��������',
    '������������ ������',
    '������ ��� �������� �����',
    '������� �� ����� ����� ������ �����',
    '������ � ����� ��������',
    '������ ��� �������� �����',
    '������ ��� ���������������� � �����',
    '������������ ��������� ������������ �����',
    '������������ ��������� ����� *. abn',
    '������������ ��������� ����� *. apn',
    '������������ ��������� �������������� �����',
    '���� nodename.doc �� �������� ������������� ������� ��� ������� ��, �� ���� ������������� ������ ��������������',
    '������������� ������������� ����� �������� �� ������',
    '������� �������� ������������ ���������',
    '������ ������� ������� ��� ������� ��������',
    '������������� ����� ������������ �����',
    '������� ����, �� ��� �� ������ ���� ���',
    '����������� ���� (������ ����) �� ��� ������',
    '��������� ����� �������������� ��������, ������� ����� ��� �������� ��������� �����, �������� ������������.',
    '��������� ����� ����� �������� �����������',
    '������������ ��������� ������������',
    '������������ �������� �� ������������� �������� ����',
    '������ ��� ��������������� ��������',
    '�������������� ���������� ������������� ������������������ ����',
    '���� NNNNAAAA.ABN ������������ ������������� ��������, ������� ���������� �� NNNNAAAA',
    '��������� ����� ���� ���������',
    '�������� ����� (��������) �� ����� ���� �������� ��� �����������',
    '������������, ����� ��������� ������������� ������ ���� ��� ��� �������� ������� ��� �������������',
    '������ ��� �������� �����',
    '������ ��� �������������� �����',
    '������ �� ����� ��������� ������� �����',
    '������� ����� ����',
    '������ �� ����� �������� ������',
    '������ �� ����� �������� ������������',
    '��� ������� ��������� (ITCS).',
    '������ ��� ����������� ������',
    '�������� ���������� ����� (����, �����, ��������...)',
    '������ ��� ���������� �����',
    '������ �� ����� �������� ������ ���� (�� �������� ��� ������ ������)',
    '������ �� ����� �������� �������� � �����',
    '��� ����� �������� ������ ���� @*******. ***; ��������� N|D|R ******. ***',
    '������ ������ ��������',
    '��� ��������',
    '������ ����',
    '������ ��������� ��������',
    '�� ���� ������ ������� �������',
    '������ ��� �������� ��������',
    '������ ��� �������� ��������',
    '������ ��� �������� �����',
    '������ ��� ����������� �����',
    '������� �� ��������������� � ������ ��������� ��',
    '���� �� �����',
    '�������� �� ������',
    '������ ���������� ����',
    '�� ���� ����������� ����',
    '�� ���� ���������� ����',
    '������������ ���������� (��������� �� CKeyDisk)',
    '��������� �� ����� ''CrYpT''',
    '��������� ������ ���� �����������',
    '���� ��������',
    '����������� ��� ����������',
    '��� ����������',
    '��� ��������',
    '�������� ������ ����������',
    '����������� ���������� ������',
    '����������� ����������� ������ ',
    '�������� ������� ������ ��������',
    'Exe-���� �������� ������������ ����� ����������',
    '��������� ���� ������',
    '���� ������ �����',
    '������ �� �������',
    '�������� ��� ������',
    '������������ ����� �����������',
    '������������ ����� ����������',
    '�������� ��� ��������',
    '�������� �� ������',
    '������ ��� ������ �������� ���������',
    '������ ��� ������ �������� ���������',
    '������ ��� �������� �������� ���������',
    '������ ���������� �����',
    '������ ������������ �����',
    '������ �����-�����',
    '��������� ������������� �������� ��� ��� �� �������',
    '������� �������� �������� � NNNN_SPR. sgn �����������',
    '���� ��� ������ ��� ��������� ��������� ���������',
    '�������� ��������� ��� ������� ����������',
    '������������� ������� ������ ������������ � �������� �����',
    '������ �������� DB-�������',
    '������ ������ ������� ����� �����������',
    '������ ����������� ������ DB-�������',
    '��������� objects ��� ��������� �� ����������� ��� �������',
    '����� ������������ �� �������� ��� ��������� ��������',
    '��������� �������� ������� ��������� (��� ���� �� �������������)',
    '��������� �������� �����������',
    '������� � ���������� ��������',
    '������ ������ ��������� �����',
    '������ ���������� ��������� ������',
    '������ ���������� ��������� ���������',
    '����� ��������  �� �����������',
    '��� ������� �������� ���� ��� ����������',
    '������� �� ���������',
    '����� ������ ������',
    '������� �� ��������� � ��������� ������',
    'CurPos() �������� �������',
    'Truncate() �������� �������',
    'Flush() �������� �������',
    '���� ��� ����������',
    '���������� ����� �����',
    '�������� ����� �����    ',
    '������ ����������� �����  ',
    '����������� GetLastError',
    '�������� �������� ������� ��� �����',
    '����� ������ ��� ���������',
    '����� �������������� ������������� �������',
    '������ ��������� � �������� �������, �� ������ ����������������� � errno, ����� �������� ������ ��� ������',
    '��������� ������ ���� �������������� (��������, ���� next_in ��� next_out ��� ������� (������))',
    '������� ������ ���� ���������',
    '������� �������� �� ��� �� �������� ��� ���� �� ������� ������������ ������� ������ � ������ ������',
    '������������ ������ ������������ � ������� ��������� � ����������� ���������',
    '�������������� �������� ���������',
    '������� ����� ����������',
    '������ �����������',
    '����� ������ ����������',
    '������� ������� �� ������ � NNNN.CHF',
    'WS �� ��������������� ��� ���� ������',
    '�������� �� ��������',
    '������ �� ����� �������� �������',
    '���-�� �� �����������',
    '��������� �������� ��� �����������',
    '�������� �� �����',
    '�������� � ������� ���������� ����� � ��������� ������� ������ �������������',
    '������ � ������� LoadLibrary',
    '������ � ������� GetProcAddress',
    '�������� ���� �������� �������������',
    '��������������� ��������, ��������� ���� ����� �������, ����������',
    '��������� �����������',
    '����������� ������ ser',
    '����������� ������ ������� ser',
    '����������� ���� ������� ser',
    '�� �����������',
    '����������� � ������ ������',
    '�������� �� ����� ���� ���������',
    '�������������� ��������� (��� ���-������ ���)',
    '�������������� �� ��������� (��� ���-������ ���)',
    '�� ������, �� ������ ������������ � �������� ��������� ������ ��� ������ ���� ������������',
    '������������ ��������� �� ��������� ���������',
    '������ �����-����',
    '������ �����-���������',
    'Deimito ������ �����',
    '���������� �������������',
    'IP-������� ���� �����������', '', '', '', '',
    '��������� ����� ������� ��������� ������',
    '������������ ��� ����������',
    '�������� ���������� ��������',
    '������ �������� ������� ����������',
    '������� ��� ���������� �� �����������',
    '������ ������ �������������� �����',
    '������������ ���� ����������',
    '�������������� �������',
    '���� �� �������� � ����������',
    '������ ������ � ����������',
    '������ ������ �� ����������',
    '������ lentgh ������ ��� ������',
    '��������� ������ ������� �������',
    '������������ ��� �����',
    '������ � ������� RegOpenKey',
    '������ � ������� RegQueryValueEx',
    '������ � ������� SwitchDesktop',
    '������ � ������� SystemParametersInfo',
    '������ � ������� CreateWindowEx',
    '������������� ���������� - ������� ������',
    '������ � ������� CreateDesktop',
    '������ � ������� CreateThread',
    '������������ �� ����� ����� �����������',
    '������������ ��� ������ �� VPN',
    '���������� (�������������) �������',
    '(������������) ������ ��� ����������',
    '����������� ���� �������������',
    '������ ����� ��� ������� � �������� ������ ���������',
    '������ � ������� ��������� ��������������� �������� ������ ���������',
    '��������� CSP ���� ������ � �������',
    '������� ������� ������� ������� ����� �������� ��������� �� ��������� ��',
    '������� ������� ������� ����� �������� ��������� �� �� ��������� ��������� ��',
    '������������� ���������� ��������������.'#13#10'��������� ���� ��� ��������� �������� �����������',
    '������������� ���������� �� ��������� � ��������� �������',
    '������� ������������� ������� ������������ ������������ � �������� ������������ �����'
   );

function ErrToStr(Err: Integer): string;
begin
  if (0<=Err) and (Err<=204) then
    Result := ExtErrMesRus[Err]+#13#10+ExtErrMes[Err]+' ('+IntToStr(Err)+')'
  else
    Result := 'Unknown error'#13#10'����������� ������ ('+IntToStr(Err)+')'
end;

function GetSignIssuerName(const pEncodedCertificate: Pointer;
  const EncodedCertSize: dWord; var pSignInfo: PChar; var pSignInfoLen: dWord): Boolean;
var
  dwCertSize: dWord;        // ����� ���������������� �����������
  dwCertInfoSize: dWord;    // ����� ��������������� ���������� � �����������
  dwNameSize: dWord;        // ����� ������ � ������ ������������
  pSignedCertInfo: PCERT_SIGNED_CONTENT_INFO;  // ��������� �� ��������������� ����������
  pCertInfo: PCERT_INFO;      // ��������� �� ��������������� ���������� � �����������
  pSubjectName: PChar;   // ��������� �� ��� ������������
begin
  Result := False;
  dwCertSize := 0;
  dwCertInfoSize := 0;
  dwNameSize := 0;
  pSignedCertInfo := nil;
  pCertInfo := nil;
  pSubjectName := nil;
  pSignInfoLen := 0;
  //* ���������� �������������� ���������� */
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
        //* ���������� �������������� CERT_INFO */
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
              //* ���������� �������������� ��� ������������ */
              dwNameSize := CertNameToStr(
                X509_ASN_ENCODING or PKCS_7_ASN_ENCODING,
                @pCertInfo.Subject, CERT_X500_NAME_STR, //* � ������ ������ ���������� ������ ��� ������������ (���, ��� ��������) ����� ������ */
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
                    //* ��������� ������ � ���������� ��� ������������ */
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
  //* ���������� �������������� ��������� */
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
        //* � CMSG_SIGNER_INFO ����/����� ������� ��������� � ������������ ���� */
        //* ���������� �������������� ��� ������������                          */
        //showmessage('2='+inttostr(dwSignerInfoSize));
        index := 0;
        while index<pMessageSignerInfo.AuthAttrs.cAttr do
        begin
          //showmessage('3='+inttostr(index)+' �� '+inttostr(pMessageSignerInfo.AuthAttrs.cAttr));
          if StrLComp(szOID_RSA_signingTime,
            (pMessageSignerInfo.AuthAttrs.rgAttr[index]).pszObjId,
            StrLen(szOID_RSA_signingTime))=0 then
          begin
            //showmessage('4='+inttostr(index));
            //* ����� ������ �������. */
            //* ���� � ����� ������ � �������� ����� ���� ��������� */
            //* ��������, ��� ������� ������� ������������ ����,    */
            //* ������� ������� ������ � ����������� ����� �������. */
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
                Mes := '������ ��������� $'+UserID;
          end
          else
            if GetMes then
              Mes := '������ ������ ����� '+UserID+' Err='+ErrToStr(Err);
        end;
        I := I+J+1;
        J := StrLen(@UserIDList[I]);
      end;
      Result := True;
    end
    else
      if GetMes then
        Mes := '������ ������ ������ ExtGetUserIDList '+ErrToStr(Err);
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
      Mes := '������ ����������� ������ '+Tcc_Itcs_Dll+' LastErr='
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
        Mes := '�� ������� ��������� �������:'+Mes+#13#10'�� ������ '
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
      MessageBox(0, PChar('������� �� ������������������� ['
        +FuncList[FuncIndex].flDllName+']'), '������ ��������� �������',
        MB_OK or MB_ICONERROR);
  end
  else
    MessageBox(0, PChar('������ ���� �� �������� ['
      +FuncList[FuncIndex].flDllName+']'), '������ ��������� �������',
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

