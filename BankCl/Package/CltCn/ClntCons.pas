unit ClntCons;

interface

uses Windows, Classes, SysUtils, CommCons;

type
  PPayRec = ^TPayRec;                   {Документ в базе}
  TPayRec = packed record     { Запись о док-те в БД }
    dbIdHere: longint;    { Идер в здесь }                        {  0 0k}
    dbIdKorr: longint;    { Идер в банке }                        {  4 1k}
    dbIdIn:   longint;    { Идер во входящих }                    {  8 2k}
    dbIdOut:  longint;    { Идер в исходящих }                    { 12 3k}
    dbIdArc:  longint;    { Идер в архиве }                       { 16 4k}
    dbIdDel:  longint;    { Идер в удаленных }                    { 20 5k}
    dbVersion:longint;    { Номер версии }                        { 24 }
    dbState:  word;       { Состояние док-та }                    { 28 }
    dbDateS:  word;       { Дата отправки }                       { 30 }
    dbTimeS:  word;       { Время отправки }                      { 32 }
    dbDateR:  word;       { Дата получения банком }               { 34 }
    dbTimeR:  word;       { Время получения банком }              { 36 }
    dbDateP:  word;       { Дата обработки банком }               { 38 }
    dbTimeP:  word;       { Время обработки банком }              { 40 }
    dbDocVarLen: word;    { Длина документа }                     { 42 }
    dbDoc:    TDocRec;    { Документ с эл. подписью и ответом }   { 44 }
  end;

type
  PaydocEditRecord = function(Sender: TComponent; PayRecPtr: PPayRec;
    EditMode: Integer; New: Boolean): Boolean;

implementation


end.
