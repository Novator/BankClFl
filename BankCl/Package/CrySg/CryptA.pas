unit CryptA;

interface

uses
  Windows;

const
  CRYPT32     = 'crypt32.dll';

  CRYPT_ASN_ENCODING  = $00000001;
  CRYPT_NDR_ENCODING = $00000002;
  X509_ASN_ENCODING = $00000001;
  X509_NDR_ENCODING = $00000002;
  PKCS_7_ASN_ENCODING = $00010000;
  PKCS_7_NDR_ENCODING = $00020000;

  CRYPT_DECODE_NOCOPY_FLAG = $1;

//+-------------------------------------------------------------------------
//  Predefined X509 certificate data structures that can be encoded / decoded.
//--------------------------------------------------------------------------
  CRYPT_ENCODE_DECODE_NONE         = 0;
  X509_CERT                        = (LPCSTR(1));
  X509_CERT_TO_BE_SIGNED           = (LPCSTR(2));
  X509_CERT_CRL_TO_BE_SIGNED       = (LPCSTR(3));
  X509_CERT_REQUEST_TO_BE_SIGNED   = (LPCSTR(4));
  X509_EXTENSIONS                  = (LPCSTR(5));
  X509_NAME_VALUE                  = (LPCSTR(6));
  X509_NAME                        = (LPCSTR(7));
  X509_PUBLIC_KEY_INFO             = (LPCSTR(8));

//+-------------------------------------------------------------------------
//  Predefined X509 certificate extension data structures that can be
//  encoded / decoded.
//--------------------------------------------------------------------------
  X509_AUTHORITY_KEY_ID            = (LPCSTR(9));
  X509_KEY_ATTRIBUTES              = (LPCSTR(10));
  X509_KEY_USAGE_RESTRICTION       = (LPCSTR(11));
  X509_ALTERNATE_NAME              = (LPCSTR(12));
  X509_BASIC_CONSTRAINTS          = (LPCSTR(13));
  X509_KEY_USAGE                   = (LPCSTR(14));
  X509_BASIC_CONSTRAINTS2          = (LPCSTR(15));
  X509_CERT_POLICIES               = (LPCSTR(16));

//+-------------------------------------------------------------------------
//  Additional predefined data structures that can be encoded / decoded.
//--------------------------------------------------------------------------
  PKCS_UTC_TIME                    = (LPCSTR(17));
  PKCS_TIME_REQUEST                = (LPCSTR(18));
  RSA_CSP_PUBLICKEYBLOB            = (LPCSTR(19));
  X509_UNICODE_NAME                = (LPCSTR(20));

  X509_KEYGEN_REQUEST_TO_BE_SIGNED  = (LPCSTR(21));
  PKCS_ATTRIBUTE                    = (LPCSTR(22));
  PKCS_CONTENT_INFO_SEQUENCE_OF_ANY = (LPCSTR(23));

//+-------------------------------------------------------------------------
//  Predefined primitive data structures that can be encoded / decoded.
//--------------------------------------------------------------------------
  X509_UNICODE_NAME_VALUE    = (LPCSTR(24));
  X509_ANY_STRING            = X509_NAME_VALUE;
  X509_UNICODE_ANY_STRING    = X509_UNICODE_NAME_VALUE;
  X509_OCTET_STRING          = (LPCSTR(25));
  X509_BITS                  = (LPCSTR(26));
  X509_INTEGER               = (LPCSTR(27));
  X509_MULTI_BYTE_INTEGER    = (LPCSTR(28));
  X509_ENUMERATED            = (LPCSTR(29));
  X509_CHOICE_OF_TIME        = (LPCSTR(30));

//+-------------------------------------------------------------------------
//  More predefined X509 certificate extension data structures that can be
//  encoded / decoded.
//--------------------------------------------------------------------------

  X509_AUTHORITY_KEY_ID2        = (LPCSTR(31));
//  X509_AUTHORITY_INFO_ACCESS          (LPCSTR(32));
  X509_CRL_REASON_CODE          = X509_ENUMERATED;
  PKCS_CONTENT_INFO             = (LPCSTR(33));
  X509_SEQUENCE_OF_ANY          = (LPCSTR(34));
  X509_CRL_DIST_POINTS          = (LPCSTR(35));
  X509_ENHANCED_KEY_USAGE       = (LPCSTR(36));
  PKCS_CTL                      = (LPCSTR(37));

  X509_MULTI_BYTE_UINT          = (LPCSTR(38));
  X509_DSS_PUBLICKEY            =  X509_MULTI_BYTE_UINT;
  X509_DSS_PARAMETERS           = (LPCSTR(39));
  X509_DSS_SIGNATURE            = (LPCSTR(40));
  PKCS_RC2_CBC_PARAMETERS       = (LPCSTR(41));
  PKCS_SMIME_CAPABILITIES       = (LPCSTR(42));

//+-------------------------------------------------------------------------
//  Predefined PKCS #7 data structures that can be encoded / decoded.
//--------------------------------------------------------------------------
  PKCS7_SIGNER_INFO             = (LPCSTR(500));

  CERT_SIMPLE_NAME_STR = 1;
  CERT_OID_NAME_STR = 2;
  CERT_X500_NAME_STR = 3;

const 
  szOID_RSA         = '1.2.840.113549';
  szOID_PKCS        = '1.2.840.113549.1';
  szOID_RSA_HASH    = '1.2.840.113549.2';
  szOID_RSA_ENCRYPT = '1.2.840.113549.3';

  szOID_PKCS_1      = '1.2.840.113549.1.1';
  szOID_PKCS_2      = '1.2.840.113549.1.2';
  szOID_PKCS_3      = '1.2.840.113549.1.3';
  szOID_PKCS_4      = '1.2.840.113549.1.4';
  szOID_PKCS_5      = '1.2.840.113549.1.5';
  szOID_PKCS_6      = '1.2.840.113549.1.6';
  szOID_PKCS_7      = '1.2.840.113549.1.7';
  szOID_PKCS_8      = '1.2.840.113549.1.8';
  szOID_PKCS_9      = '1.2.840.113549.1.9';
  szOID_PKCS_10     = '1.2.840.113549.1.10';

  szOID_RSA_RSA     = '1.2.840.113549.1.1.1';
  szOID_RSA_MD2RSA  = '1.2.840.113549.1.1.2';
  szOID_RSA_MD4RSA  = '1.2.840.113549.1.1.3';
  szOID_RSA_MD5RSA  = '1.2.840.113549.1.1.4';
  szOID_RSA_SHA1RSA = '1.2.840.113549.1.1.5';
  szOID_RSA_SETOAEP_RSA  = '1.2.840.113549.1.1.6';
  
  szOID_RSA_data             = '1.2.840.113549.1.7.1';
  szOID_RSA_signedData       = '1.2.840.113549.1.7.2';
  szOID_RSA_envelopedData    = '1.2.840.113549.1.7.3';
  szOID_RSA_signEnvData      = '1.2.840.113549.1.7.4';
  szOID_RSA_digestedData     = '1.2.840.113549.1.7.5';
  szOID_RSA_hashedData       = '1.2.840.113549.1.7.5';
  szOID_RSA_encryptedData    = '1.2.840.113549.1.7.6';

  szOID_RSA_emailAddr           = '1.2.840.113549.1.9.1';
  szOID_RSA_unstructName        = '1.2.840.113549.1.9.2';
  szOID_RSA_contentType         = '1.2.840.113549.1.9.3';
  szOID_RSA_messageDigest       = '1.2.840.113549.1.9.4';
  szOID_RSA_signingTime         = '1.2.840.113549.1.9.5';
  szOID_RSA_counterSign         = '1.2.840.113549.1.9.6';
  szOID_RSA_challengePwd        = '1.2.840.113549.1.9.7';
  szOID_RSA_unstructAddr        = '1.2.840.113549.1.9.8';
  szOID_RSA_extCertAttrs        = '1.2.840.113549.1.9.9';
  szOID_RSA_SMIMECapabilities   = '1.2.840.113549.1.9.15';
  szOID_RSA_preferSignedData    = '1.2.840.113549.1.9.15.1';

  szOID_RSA_MD2 = '1.2.840.113549.2.2';
  szOID_RSA_MD4 = '1.2.840.113549.2.4';
  szOID_RSA_MD5 = '1.2.840.113549.2.5';

  szOID_RSA_RC2CBC        = '1.2.840.113549.3.2';
  szOID_RSA_RC4           = '1.2.840.113549.3.4';
  szOID_RSA_DES_EDE3_CBC  = '1.2.840.113549.3.7';
  szOID_RSA_RC5_CBCPad    = '1.2.840.113549.3.9';

// ITU-T UsefulDefinitions
  szOID_DS          = '2.5';
  szOID_DSALG       = '2.5.8';
  szOID_DSALG_CRPT  = '2.5.8.1';
  szOID_DSALG_HASH  = '2.5.8.2';
  szOID_DSALG_SIGN  = '2.5.8.3';
  szOID_DSALG_RSA   = '2.5.8.1.1';

// NIST OSE Implementors' Workshop (OIW)
// http://nemo.ncsl.nist.gov/oiw/agreements/stable/OSI/12s_9506.w51
// http://nemo.ncsl.nist.gov/oiw/agreements/working/OSI/12w_9503.w51
  szOID_OIW            = '1.3.14';
// NIST OSE Implementors' Workshop (OIW) Security SIG algorithm identifiers
  szOID_OIWSEC         = '1.3.14.3.2';
  szOID_OIWSEC_md4RSA  = '1.3.14.3.2.2';
  szOID_OIWSEC_md5RSA  = '1.3.14.3.2.3';
  szOID_OIWSEC_md4RSA2 = '1.3.14.3.2.4';
  szOID_OIWSEC_desECB  = '1.3.14.3.2.6';
  szOID_OIWSEC_desCBC  = '1.3.14.3.2.7';
  szOID_OIWSEC_desOFB  = '1.3.14.3.2.8';
  szOID_OIWSEC_desCFB  = '1.3.14.3.2.9';
  szOID_OIWSEC_desMAC  = '1.3.14.3.2.10';
  szOID_OIWSEC_rsaSign = '1.3.14.3.2.11';
  szOID_OIWSEC_dsa     = '1.3.14.3.2.12';
  szOID_OIWSEC_shaDSA  = '1.3.14.3.2.13';
  szOID_OIWSEC_mdc2RSA = '1.3.14.3.2.14';
  szOID_OIWSEC_shaRSA  = '1.3.14.3.2.15';
  szOID_OIWSEC_dhCommMod = '1.3.14.3.2.16';
  szOID_OIWSEC_desEDE    = '1.3.14.3.2.17';
  szOID_OIWSEC_sha       = '1.3.14.3.2.18';
  szOID_OIWSEC_mdc2      = '1.3.14.3.2.19';
  szOID_OIWSEC_dsaComm   = '1.3.14.3.2.20';
  szOID_OIWSEC_dsaCommSHA  = '1.3.14.3.2.21';
  szOID_OIWSEC_rsaXchg     = '1.3.14.3.2.22';
  szOID_OIWSEC_keyHashSeal = '1.3.14.3.2.23';
  szOID_OIWSEC_md2RSASign  = '1.3.14.3.2.24';
  szOID_OIWSEC_md5RSASign  = '1.3.14.3.2.25';
  szOID_OIWSEC_sha1        = '1.3.14.3.2.26';
  szOID_OIWSEC_dsaSHA1     = '1.3.14.3.2.27';
  szOID_OIWSEC_dsaCommSHA1 =  '1.3.14.3.2.28';
  szOID_OIWSEC_sha1RSASign =  '1.3.14.3.2.29';
// NIST OSE Implementors' Workshop (OIW) Directory SIG algorithm identifiers
  szOID_OIWDIR             = '1.3.14.7.2';
  szOID_OIWDIR_CRPT        = '1.3.14.7.2.1';
  szOID_OIWDIR_HASH        = '1.3.14.7.2.2';
  szOID_OIWDIR_SIGN        = '1.3.14.7.2.3';
  szOID_OIWDIR_md2         = '1.3.14.7.2.2.1';
  szOID_OIWDIR_md2RSA      = '1.3.14.7.2.3.1';


// INFOSEC Algorithms
// joint-iso-ccitt(2) country(16) us(840) organization(1) us-government(101) dod(2) id-infosec(1)
  szOID_INFOSEC                       = '2.16.840.1.101.2.1';
  szOID_INFOSEC_sdnsSignature         = '2.16.840.1.101.2.1.1.1';
  szOID_INFOSEC_mosaicSignature       = '2.16.840.1.101.2.1.1.2';
  szOID_INFOSEC_sdnsConfidentiality   = '2.16.840.1.101.2.1.1.3';
  szOID_INFOSEC_mosaicConfidentiality = '2.16.840.1.101.2.1.1.4';
  szOID_INFOSEC_sdnsIntegrity         = '2.16.840.1.101.2.1.1.5';
  szOID_INFOSEC_mosaicIntegrity       = '2.16.840.1.101.2.1.1.6';
  szOID_INFOSEC_sdnsTokenProtection   = '2.16.840.1.101.2.1.1.7';
  szOID_INFOSEC_mosaicTokenProtection = '2.16.840.1.101.2.1.1.8';
  szOID_INFOSEC_sdnsKeyManagement     = '2.16.840.1.101.2.1.1.9';
  szOID_INFOSEC_mosaicKeyManagement   = '2.16.840.1.101.2.1.1.10';
  szOID_INFOSEC_sdnsKMandSig          = '2.16.840.1.101.2.1.1.11';
  szOID_INFOSEC_mosaicKMandSig        = '2.16.840.1.101.2.1.1.12';
  szOID_INFOSEC_SuiteASignature       = '2.16.840.1.101.2.1.1.13';
  szOID_INFOSEC_SuiteAConfidentiality = '2.16.840.1.101.2.1.1.14';
  szOID_INFOSEC_SuiteAIntegrity       = '2.16.840.1.101.2.1.1.15';
  szOID_INFOSEC_SuiteATokenProtection = '2.16.840.1.101.2.1.1.16';
  szOID_INFOSEC_SuiteAKeyManagement   = '2.16.840.1.101.2.1.1.17';
  szOID_INFOSEC_SuiteAKMandSig        = '2.16.840.1.101.2.1.1.18';
  szOID_INFOSEC_mosaicUpdatedSig      = '2.16.840.1.101.2.1.1.19';
  szOID_INFOSEC_mosaicKMandUpdSig     = '2.16.840.1.101.2.1.1.20';
  szOID_INFOSEC_mosaicUpdatedInteg    = '2.16.840.1.101.2.1.1.21';

type
  PCRYPTOAPI_BLOB = ^CRYPTOAPI_BLOB;
  CRYPTOAPI_BLOB = record
    cbData :DWORD;
    pbData :PBYTE;
  end;
  CRYPT_INTEGER_BLOB    = CRYPTOAPI_BLOB;
  PCRYPT_INTEGER_BLOB   = PCRYPTOAPI_BLOB;
  CRYPT_UINT_BLOB       = CRYPT_INTEGER_BLOB;
  CRYPT_OBJID_BLOB      = CRYPT_INTEGER_BLOB;
  CERT_NAME_BLOB        = CRYPT_INTEGER_BLOB;
  CERT_RDN_VALUE_BLOB   = CRYPT_INTEGER_BLOB;
  CERT_BLOB             = CRYPT_INTEGER_BLOB;
  CRL_BLOB              = CRYPT_INTEGER_BLOB;
  DATA_BLOB             = CRYPT_INTEGER_BLOB;
  CRYPT_DATA_BLOB       = CRYPT_INTEGER_BLOB;
  CRYPT_HASH_BLOB       = CRYPT_INTEGER_BLOB;
  CRYPT_DIGEST_BLOB     = CRYPT_INTEGER_BLOB;
  CRYPT_DER_BLOB        = CRYPT_INTEGER_BLOB;
  CRYPT_ATTR_BLOB       = CRYPT_INTEGER_BLOB;
  PCRYPT_UINT_BLOB      = PCRYPT_INTEGER_BLOB;
  PCRYPT_OBJID_BLOB     = PCRYPT_INTEGER_BLOB;
  PCERT_NAME_BLOB       = PCRYPT_INTEGER_BLOB;
  PCERT_RDN_VALUE_BLOB  = PCRYPT_INTEGER_BLOB;
  PCERT_BLOB            = PCRYPT_INTEGER_BLOB;
  PCRL_BLOB             = PCRYPT_INTEGER_BLOB;
  PDATA_BLOB            = PCRYPT_INTEGER_BLOB;
  PCRYPT_DATA_BLOB      = PCRYPT_INTEGER_BLOB;
  PCRYPT_HASH_BLOB      = PCRYPT_INTEGER_BLOB;
  PCRYPT_DIGEST_BLOB    = PCRYPT_INTEGER_BLOB;
  PCRYPT_DER_BLOB       = PCRYPT_INTEGER_BLOB;
  PCRYPT_ATTR_BLOB      = PCRYPT_INTEGER_BLOB;

  CRYPT_ALGORITHM_IDENTIFIER = record
    pszObjId: PChar;
    Parameters: CRYPT_OBJID_BLOB;
  end;

  PCRYPT_BIT_BLOB = ^CRYPT_BIT_BLOB;
  CRYPT_BIT_BLOB = record
    cbData: dWord;
    pbData: PChar;
    cUnusedBits: dWord;
  end;

  PCERT_PUBLIC_KEY_INFO = ^CERT_PUBLIC_KEY_INFO;
  CERT_PUBLIC_KEY_INFO = record
    Algorithm: CRYPT_ALGORITHM_IDENTIFIER;
    PublicKey: CRYPT_BIT_BLOB;
  end;

  PCERT_EXTENSION = ^CERT_EXTENSION;
  CERT_EXTENSION = record
    pszObjId: PChar;
    fCritical: Boolean;
    Value: CRYPT_OBJID_BLOB;
  end;


  PCERT_INFO = ^CERT_INFO;
  CERT_INFO = record
    dwVersion: dWord;
    SerialNumber: CRYPT_INTEGER_BLOB;
    SignatureAlgorithm: CRYPT_ALGORITHM_IDENTIFIER;
    Issuer: CERT_NAME_BLOB;
    NotBefore: FILETIME;
    NotAfter: FILETIME;
    Subject: CERT_NAME_BLOB;
    SubjectPublicKeyInfo: CERT_PUBLIC_KEY_INFO;
    IssuerUniqueId: CRYPT_BIT_BLOB;
    SubjectUniqueId: CRYPT_BIT_BLOB;
    cExtension: dWord;
    rgExtension: PCERT_EXTENSION;
  end;

  PCERT_CONTEXT = ^CERT_CONTEXT;
  HCERTSTORE = PCERT_CONTEXT;
  CERT_CONTEXT = record
    dwCertEncodingType: dWord;
    pbCertEncoded: PChar;
    cbCertEncoded: dWord;
    pCertInfo: PCERT_INFO;
    hCertStore: HCERTSTORE;
  end;

  PCERT_SIGNED_CONTENT_INFO = ^CERT_SIGNED_CONTENT_INFO;
  CERT_SIGNED_CONTENT_INFO = record
    ToBeSigned: CRYPT_DER_BLOB;
    SignatureAlgorithm: CRYPT_ALGORITHM_IDENTIFIER;
    Signature: CRYPT_BIT_BLOB;
  end;

type
  PVOID = Pointer;
  {$IFDEF UNICODE}
    LPAWSTR = PWideChar;
  {$ELSE}
    LPAWSTR = PAnsiChar;
  {$ENDIF}

  PCRYPT_ATTRIBUTE = ^CRYPT_ATTRIBUTE;
  CRYPT_ATTRIBUTE = record
     pszObjId :LPSTR;
     cValue :DWORD;
     rgValue :PCRYPT_ATTR_BLOB;
  end;

  PCRYPT_ATTRIBUTES =^CRYPT_ATTRIBUTES;
  CRYPT_ATTRIBUTES = record
    cAttr  :DWORD; {IN}
    rgAttr :array of CRYPT_ATTRIBUTE; {IN}
  end;

  PCMSG_SIGNER_INFO = ^CMSG_SIGNER_INFO;
  CMSG_SIGNER_INFO = record
    dwVersion :DWORD;
    Issuer :CERT_NAME_BLOB;
    SerialNumber :CRYPT_INTEGER_BLOB;
    HashAlgorithm :CRYPT_ALGORITHM_IDENTIFIER;
    HashEncryptionAlgorithm :CRYPT_ALGORITHM_IDENTIFIER;
    EncryptedHash :CRYPT_DATA_BLOB;
    AuthAttrs :CRYPT_ATTRIBUTES;
    UnauthAttrs :CRYPT_ATTRIBUTES;
  end;

function CryptDecodeObject(dwCertEncodingType :DWORD;
                           lpszStructType     :LPCSTR;
                     const pbEncoded          :PBYTE;
                           cbEncoded          :DWORD;
                           dwFlags            :DWORD;
                           pvStructInfo       :PVOID;
                           pcbStructInfo      :PDWORD):BOOL ; stdcall;

//+-------------------------------------------------------------------------
//--------------------------------------------------------------------------
function CertNameToStrA(dwCertEncodingType :DWORD;
                        pName :PCERT_NAME_BLOB;
                        dwStrType :DWORD;
                        psz :LPSTR; //OPTIONAL
                        csz :DWORD):DWORD ; stdcall;
//+-------------------------------------------------------------------------
//--------------------------------------------------------------------------
function CertNameToStrW(dwCertEncodingType :DWORD;
                        pName :PCERT_NAME_BLOB;
                        dwStrType :DWORD;
                        psz :LPWSTR; //OPTIONAL
                        csz :DWORD):DWORD ; stdcall;

function CertNameToStr(dwCertEncodingType :DWORD;
                       pName :PCERT_NAME_BLOB;
                       dwStrType :DWORD;
                       psz :LPAWSTR; //OPTIONAL
                       csz :DWORD):DWORD ; stdcall;


implementation

function CryptDecodeObject; external CRYPT32 name 'CryptDecodeObject';
function CertNameToStrA; external CRYPT32 name 'CertNameToStrA';
function CertNameToStrW; external CRYPT32 name 'CertNameToStrW';
{$IFDEF UNICODE}
function CertNameToStr; external CRYPT32 name 'CertNameToStrW';
{$ELSE}
function CertNameToStr; external CRYPT32 name 'CertNameToStrA';
{$ENDIF} // !UNICODE


end.
