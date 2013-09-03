program ConvBank;

uses
  Windows,
  Messages,
  SysUtils,
  Btrieve;

{$R *.RES}

const
  plInfo = 0;
  plErr  = 1;

procedure ProtoMes(L: Byte; S: string);
begin
  MessageBox(0, PChar(S), '', 0);
end;

type
  TAccount = array[0..19] of char;

  TSity = array[0..24] of char;
  TSityType = array[0..4] of char;

  PNpRec = ^TNpRec;
  TNpRec = packed record                                {���������� ������ ������}
    npIder:   longint;                  {���� ���.������}           {0      0,4}
    npName:   TSity;                    {������������ ���.������}   {1.0    4,25}
    npType:   TSityType;                {������������}              {1.1    29,5}
  end;                                                              {       =34}

  TBankTypeOld = array[0..3] of Char;
  TBankNameOld = array[0..39] of Char;
  TBankNameNew = array[0..44] of Char;

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

function ConvertBankSpr(FN1, FN2: string): Boolean;
var
  B1, B2: TBtrBase;
  Len, Res, Bik, N: Integer;
  Bank1: TBankOldRec;
  Bank2: TBankNewRec;
  Buf: array[0..50] of Char;
begin
  Result := False;
  B1 := TBtrBase.Create;
  Res := B1.Open(FN1, baReadOnly);
  if Res=0 then
  begin
    B2 := TBtrBase.Create;
    Res := B2.Open(FN2, baNormal);
    if Res=0 then
    begin
      N := 0;
      Len := SizeOf(Bank1);
      Res := B1.GetFirst(Bank1, Len, Bik, 0);
      while Res=0 do
      begin
        FillChar(Bank2, SizeOf(Bank2), #0);
        Bank2.brCod := Bank1.brCod;
        Bank2.brKs := Bank1.brKs;
        Bank2.brNpIder := Bank1.brNpIder;
        StrLCopy(Buf, Bank1.brType, SizeOf(Bank1.brType));
        if StrLen(Buf)>0 then
          StrCat(Buf, ' ');
        StrLCat(Buf, Bank1.brName, SizeOf(Bank1.brName));
        if StrLen(Buf)<SizeOf(Bank2.brName) then
          StrLCopy(Bank2.brName, Buf, SizeOf(Bank2.brName)-1)
        else
          Move(Buf, Bank2.brName, SizeOf(Bank2.brName));
        Len := SizeOf(Bank2);
        Res := B2.Insert(Bank2, Len, Bik, 0);
        if Res=0 then
          Inc(N);

        Len := SizeOf(Bank1);
        Res := B1.GetNext(Bank1, Len, Bik, 0);
      end;
      Res := B2.Close;
      Result := True;
      ProtoMes(plInfo, '���������� ������� '+IntToStr(N));
    end
    else
      ProtoMes(plErr, '�� ������� ������� '+FN2);
    Res := B1.Close;
    B2.Free;
  end
  else
    ProtoMes(plErr, '�� ������� ������� '+FN1);
  B1.Free;
end;


begin
  if ParamCount>1 then
  begin
    ConvertBankSpr(ParamStr(1), ParamStr(2));
  end;
end.
