unit ClntCons;

interface

uses Windows, Classes, SysUtils, CommCons;

type
  PPayRec = ^TPayRec;                   {�������� � ����}
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
    dbDocVarLen: word;    { ����� ��������� }                     { 42 }
    dbDoc:    TDocRec;    { �������� � ��. �������� � ������� }   { 44 }
  end;

type
  PaydocEditRecord = function(Sender: TComponent; PayRecPtr: PPayRec;
    EditMode: Integer; New: Boolean): Boolean;

implementation


end.
