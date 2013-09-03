unit ValCons;

interface

uses Windows, Classes, SysUtils, CommCons;

type
  PValPayRec = ^TValPayRec;                   {Валютный документ в базе}
  TValPayRec = packed record     { Запись о док-те в БД }
    vpIdHere: longint;    { Идер в здесь }                        {  0 0k}
    vpIdKorr: longint;    { Идер в банке }                        {  4 1k}
    vpIdIn:   longint;    { Идер во входящих }                    {  8 2k}
    vpIdOut:  longint;    { Идер в исходящих }                    { 12 3k}
    vpIdArc:  longint;    { Идер в архиве }                       { 16 4k}
    vpIdDel:  longint;    { Идер в удаленных }                    { 20 5k}
    vpVersion:longint;    { Номер версии }                        { 24 }
    vpState:  word;       { Состояние док-та }                    { 28 }
    vpDateS:  word;       { Дата отправки }                       { 30 }
    vpTimeS:  word;       { Время отправки }                      { 32 }
    vpDateR:  word;       { Дата получения банком }               { 34 }
    vpTimeR:  word;       { Время получения банком }              { 36 }
    vpDateP:  word;       { Дата обработки банком }               { 38 }
    vpTimeP:  word;       { Время обработки банком }              { 40 }
    vpDocLen: word;       { Длина документа }                     { 42 }
    vpDoc:    TDocRec;    { Документ с эл. подписью и ответом }   { 44 }
  end;

type
  TAccList = class(TList)
  protected
  public
    destructor Destroy; override;
    procedure Clear; override;
    function SearchAcc(Acc: PChar): Integer;
  end;

function AccColRecCompare(Key1, Key2: Pointer): Integer;

type
  PaydocEditRecord = function(Sender: TComponent; PayRecPtr: PPayRec;
    ReadOnly, New: Boolean): Boolean;

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
      MessageBox(GetForegroundWindow, 'Ошибка освобождения памяти', 'Список счетов',
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
{function TAccList.SearchAcc(Acc: PChar): Integer;
begin
  try
    Result := 0;
    while (Result<Count) and (Items[Result]<>nil)
      and (StrLComp(Acc, @PAccColRec(Items[Result])^.acNumber,
        SizeOf(TAccount))<>0) do
          Inc(Result);
    if Result>=Count then
      Result := -1;
  except
    Result := -1;
    MessageBox(Handle, 'Ошибка поиска счета', 'Список счетов', MB_OK+MB_ICONERROR);
  end;
end;}

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
    MessageBox(GetForegroundWindow, 'Ошибка поиска счета',
      'Список счетов', MB_OK+MB_ICONERROR);
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


end.
