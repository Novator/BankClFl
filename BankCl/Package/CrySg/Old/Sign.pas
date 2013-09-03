unit Sign;

interface

const
  SignSize    = 92;
  AuthKeySize = 64;
var
  AuthKey: array[0..AuthKeySize-1] of Byte;

  function InitSign(Oper: word; KeyDev: string; Pwd: string): integer;
  function MakeSign(Info: pointer; Len: integer; TNode: word; Opt: word): integer;
  function TestSign(Info: pointer; Len: integer; var FNode, Oper, TNode: word): integer;
  function EncryptBlock(Data: pointer; Len: longword; Node: word): boolean;
  function DecryptBlock(Data: pointer; Len: longword; Node: word): boolean;
  function GetNode: integer;
  function GetOperNum: integer;
  procedure DoneSign;

implementation

uses
  SysUtils, CryDrv;

type
  Pbyte = ^byte;
  Pword = ^word;
  Pinteger = ^integer;

var
  ProgKey: array [0..31] of byte = ($3f, $6a, $69, $2b, $d6, $6b, $3e, $9c,
                                    $ca, $3d, $9e, $4e, $35, $1b, $7a, $c9,
                                    $19, $ae, $0d, $56, $37, $d4, $c4, $9c,
                                    $df, $84, $59, $58, $ce, $ab, $36, $a4);
  Ki, Kop: array [0..31] of byte;
  Ni: word = 0;
  Nop: word = 0;
  KeyDir: string = '';

function InitSign(Oper: word; KeyDev: string; Pwd: string): integer;
var
  F, i: integer;
  AccessRec: array[0..167] of byte;
  PassKey: array[0..35] of byte;
begin
  Result := 0;
  F := FileOpen(KeyDev+'access.cry',fmOpenRead);
  if(F<0) then
    begin
      Result := 1;
      Exit;
    end;
  try
    FileSeek(F,(Oper-1)*168+64,0);
    FileRead(F,AccessRec,SizeOf(AccessRec));
  finally
    FileClose(F);
  end;
  if(Pword(@AccessRec[92])^ = 0) then
    begin
      Result := 2;
      Exit;
    end;
  if(Pword(@AccessRec[92])^ <> Oper) then
    begin
      Result := 3;
      Exit;
    end;
  MakeKeyFromPass(@PassKey[4],Pwd);
  Pword(@PassKey[0])^ := Oper;
  Pword(@PassKey[2])^ := Pword(@AccessRec[94])^;
  for i := 0 to 31 do
    PassKey[i] := PassKey[i] Xor ProgKey[i];
  DecryptKey(@PassKey,@MainKey);
  DecryptKey(@AccessRec[132],@PassKey);
  if(IpKey(@AccessRec[132],@PassKey)<>Pinteger(@AccessRec[164])^) then
    begin
      Result := 4;
      Exit;
    end;
  DecryptKey(@AccessRec[96],@PassKey);
  if(IpKey(@AccessRec[96],@PassKey)<>Pinteger(@AccessRec[128])^) then
    begin
      Result := 4;
      Exit;
    end;
  KeyDir := KeyDev;
  Nop := Oper;
  Ni := Pword(@AccessRec[94])^;
  Move(AccessRec[96],Ki,32);
  Move(AccessRec[132],Kop,32);
end;

function ReadKix(Kix: pointer; x: word): boolean;
var
  F: integer;
  NodesNum: word;
  s: string;
  Key: array[0..35] of byte;
begin
  Result := false;
  s := KeyDir+Format('%5.5d.sys',[Ni]);
  F := FileOpen(s,fmOpenRead);
  if(F<0) then
    Exit;
  try
    FileRead(F,NodesNum,SizeOf(NodesNum));
    if(x>NodesNum) then
      Exit;
    FileSeek(F,(x-1)*36+2,0);
    FileRead(F,Key,36);
  finally
    FileClose(F);
  end;
  DecryptKey(@Key,@Ki);
  if(IpKey(@Key,@Ki)<>Pinteger(@Key[32])^) then
    Exit;
  Move(Key,Kix^,32);
  Result := true;
end;

function ReadAx(Ax: pointer; x: word): boolean;
var
  F, i, Ip: integer;
  NodesNum: word;
  Key: array[0..35] of byte;
  s: string;
begin
  Result := false;
  s := KeyDir+'adr_user.sys';
  F := FileOpen(s,fmOpenRead);
  if(F<0) then
    Exit;
  try
    FileRead(F,NodesNum,SizeOf(NodesNum));
    if(x>NodesNum) then
      Exit;
    FileSeek(F,(x-1)*36+2,0);
    FileRead(F,Key,36);
  finally
    FileClose(F);
  end;
  Ip := 0;
  i := 0;
  repeat
    Inc(Ip,Pinteger(@Key[i])^);
    Inc(i,4);
  until(i=32);
  if(Ip<>Pinteger(@Key[32])^) then
    Exit;
  DecryptKey(@Key,@Ki);
  Move(Key,Ax^,32);
  Result := true;
end;

procedure XorHash(Hash, Dst, Key: pointer);
var
  t: array[0..31] of byte;
  p: pchar absolute Dst;
begin
  Move(Hash^,t,32);
  EncryptKey(@t,Key);
  Pinteger(p)^ := Pinteger(@t[0])^ Xor Pinteger(@t[16])^;
  Pinteger(p+4)^ := Pinteger(@t[4])^ Xor Pinteger(@t[20])^;
  Pinteger(p+8)^ := Pinteger(@t[8])^ Xor Pinteger(@t[24])^;
  Pinteger(p+12)^ := Pinteger(@t[12])^ Xor Pinteger(@t[28])^;
end;

function GetIp(Adr: pointer; Len: longword; Key: pointer): integer;
var
  t: array[0..519] of byte;
begin
  Move(Adr^,t,Len);
  FillChar(t[Len],8,0);
  Result := IpData(@t,(Len+7) And $FFFFFFF8,Key);
end;

procedure HashOnBlock(Hash: pointer; pp: pointer; Len: integer);
var
  p: pchar;
  l, i: integer;
  t, t1, t2: array [0..31] of byte;
  tt: word;
begin
  p := pp;
  l := Len;
  while(l>0) do
    begin
      if(l>=32) then
        begin
          Move(p^,t,32);
        end
      else
        begin
          Move(p^,t,l);
          FillChar(t[l],32-l,0);
        end;
      Move(t,t1,32);
      EncryptKey(@t1,Hash);
      tt := Pword(@t1[2])^;
      Pword(@t1[2])^ := Pword(@t1[26])^;
      Pword(@t1[26])^ := Pword(@t1[18])^;
      Pword(@t1[18])^ := Pword(@t1[10])^;
      Pword(@t1[10])^ := tt;
      tt := Pword(@t1[4])^;
      Pword(@t1[4])^ := Pword(@t1[8])^;
      Pword(@t1[8])^ := tt;
      tt := Pword(@t1[12])^;
      Pword(@t1[12])^ := Pword(@t1[28])^;
      Pword(@t1[28])^ := tt;
      tt := Pword(@t1[6])^;
      Pword(@t1[6])^ := Pword(@t1[14])^;
      Pword(@t1[14])^ := Pword(@t1[22])^;
      Pword(@t1[22])^ := Pword(@t1[30])^;
      Pword(@t1[30])^ := tt;
      Move(t1,t2,32);
      EncryptKey(@t2,Hash);
      i := 0;
      repeat
        Pinteger(Pchar(Hash)+i)^ := Pinteger(@t2[i])^ Xor Pinteger(@t[i])^;
        Inc(i,4);
      until(i=32);
      Inc(p,32);
      Dec(l,32);
    end;
end;

procedure DeEncodeBlock(Synhro: pointer; p: pointer; Len: word;
                        Key: pointer; Decode: boolean);
var
  t: array [0..519] of byte;
begin
  Move(Synhro^,t,8);
  Move(p^,t[8],Len);
  if(Decode) then
    begin
      DecryptData(@t,Len+8,Key);
      Move(t[8],p^,Len);
    end
  else
    begin
      EncryptData(@t,Len+8,Key);
      Move(t[8],p^,Len);
    end;
end;

function MakeSign(Info: pointer; Len: integer; TNode: word; Opt: word): integer;
var
  l, ll: integer;
  p: pchar;
  Sign: array [0..91] of byte;
  Kii, Kij, Kf, Hash: array [0..31] of byte;
  Synhro: array [0..7] of byte;
begin
  if(Opt>1) then
    Move((pchar(Info)+Len)^,Sign,SizeOf(Sign))
  else
    GetRandomKey(@Sign[11]);
  Sign[0] := $1A;
  Sign[91] := $1A;
  if((Opt And 1)=0) then
    Sign[91] := $19;
  Pinteger(@Sign[1])^ := Len;
  Pword(@Sign[5])^ := Ni;
  Pword(@Sign[7])^ := TNode;
  Pword(@Sign[9])^ := Nop;
  if(Not ReadKix(@Kii,Ni) Or
     Not ReadKix(@Kij,TNode)) then
    begin
      Result := -1;
      Exit;
    end;
  Move(Sign[11],Kf,32);
  DecryptKey(@Kf,@Kij);
  Pinteger(@Sign[43])^ := IpKey(@Kf,@Kij);
  Move(Sign[11],Hash,32);
  Move(Sign[11],Synhro,8);
  p := Info;
  l := Len;
  while(l>0) do
    begin
      ll := l;
      if(ll>512) then
        ll := 512;
      HashOnBlock(@Hash,p,ll);
      if(Sign[91]=$19) then
        DeEncodeBlock(@Synhro,p,ll,@Kf,false);
      Move((p+504)^,Synhro,8);
      Inc(p,512);
      Dec(l,512);
    end;
//  Pinteger(@Sign[1])^ := Len;
  XorHash(@Hash,@Sign[47],@Kij);
  XorHash(@Hash,@Sign[63],@Kii);
  Pinteger(@Sign[79])^ := GetIp(@Sign,79,@Kop);
  Pinteger(@Sign[83])^ := GetIp(@Sign,83,@Kii);
  Pinteger(@Sign[87])^ := GetIp(@Sign,87,@ProgKey);
  Move(Sign,(pchar(Info)+Len)^,SizeOf(Sign));
  Result := 92;
end;

function TestSign(Info: pointer; Len: integer; var FNode, Oper, TNode: word): integer;
label l100;
var
  Sign: array [0..91] of byte;
  Kii, Kij, Kf: array [0..31] of byte;
function TestHash: boolean;
  var
    l, ll: integer;
    p: pchar;
    Hash: array [0..31] of byte;
    Synhro: array [0..7] of byte;
    t: array[0..15] of byte;
  begin
    Move(Sign[11],Hash,32);
    Move(Sign[11],Synhro,8);
    p := Info;
    l := Pinteger(@Sign[1])^;
    while(l>0) do
      begin
        Move((p+504)^,t,8);
        ll := l;
        if(ll>512) then
          ll := 512;
        if(Sign[91]=$19) then
          DeEncodeBlock(@Synhro,p,ll,@Kf,true);
        HashOnBlock(@Hash,p,ll);
        Move(t,Synhro,8);
        Inc(p,512);
        Dec(l,512);
      end;
    XorHash(@Hash,@t,@Kij);
    Result := CompareMem(@t,@Sign[47],16);
  end;
begin
  Result := 0;
  Move((pchar(Info)+Len-SizeOf(Sign))^,Sign,SizeOf(Sign));
  if((Sign[0]<>$1A) Or ((Sign[91]<>$19) And (Sign[91]<>$1A)) Or
     (Pinteger(@Sign[1])^<>Len-SizeOf(Sign))) then
    begin
      Result := $8000;
      Exit;
    end;
  FNode := Pword(@Sign[5])^;
  TNode := Pword(@Sign[7])^;
  Oper := Pword(@Sign[9])^;
  if((Pword(@Sign[5])^<>Ni) And
     (Pword(@Sign[7])^<>Ni)) then
    begin
      Exit;
    end;
  if(Pword(@Sign[5])^=Ni) then
    begin
      Result := Result Or 4;
      if(Not ReadKix(@Kii,Ni) Or
         Not ReadKix(@Kij,Pword(@Sign[7])^)) then
        begin
          Result := -1;
          Exit;
        end;
      Move(Sign[11],Kf,32);
      DecryptKey(@Kf,@Kij);
      if(IpKey(@Kf,@Kij)<>Pinteger(@Sign[43])^) then
        begin
          Result := Result Or $80;
          goto L100;
        end;
      if(Not TestHash) then
        Result := Result Or $40
      else if(GetIp(@Sign,83,@Kii)<>Pinteger(@Sign[83])^) then
        Result := Result Or 8;
      if(Pword(@Sign[9])^<>Nop) then
        goto L100;
      Result := Result Or 1;
      if(GetIp(@Sign,79,@Kop)<>Pinteger(@Sign[79])^) then
        Result := Result Or 2;
      goto L100;
    end;
  Result := Result Or $10;
  if(Not ReadAx(@Kij,Pword(@Sign[5])^)) then
    begin
      Result := -2;
      Exit;
    end;
  Move(Sign[11],Kf,32);
  DecryptKey(@Kf,@Kij);
  if(IpKey(@Kf,@Kij)<>Pinteger(@Sign[43])^) then
    begin
      Result := Result Or $20;
      goto L100;
    end;
  if(Not TestHash) then
    Result := Result Or $40;
l100:
  if(GetIp(@Sign,87,@ProgKey)<>Pinteger(@Sign[87])^) then
    Result := Result Or $100;
end;

function GetNode: integer;
begin
  Result := Ni;
end;

function GetOperNum: integer;
begin
  Result := Nop;
end;

function EncryptBlock(Data: pointer; Len: longword; Node: word): boolean;
var
  p: pchar;
  IpD, IpF: integer;
  l: longword;
  Kij, Kf: array [0..31] of byte;
  Synhro: array [0..7] of integer;
begin
  Result := false;
  if(Not ReadKix(@Kij,Node)) then
    Exit;
  GetRandomKey(@Synhro);
  Synhro[0] := Synhro[0] Xor Synhro[2] Xor Synhro[4] Xor Synhro[6];
  Synhro[1] := Synhro[1] Xor Synhro[3] Xor Synhro[5] Xor Synhro[7];
  GetRandomKey(@Kf);
  IpF := IpKey(@Kf,@Kij);
  p := Data;
  l := (Len+7) And $FFFFFFF8;
  if(l>Len) then
    begin
      FillChar(p[Len],l-Len,0);
    end;
  IpD := IpData(p,l,@Kf);
  Move(p^,p[8],Len);
  Move(Synhro,p^,8);
  EncryptData(p,l+8,@Kf);
  EncryptKey(@Kf,@Kij);
  Move(IpD,p[Len+8],4);
  Move(Kf,p[Len+12],32);
  Move(IpF,p[Len+44],4);
  Result := true;
end;

function DecryptBlock(Data: pointer; Len: longword; Node: word): boolean;
var
  p: pchar;
  IpD, IpF: integer;
  l: longword;
  Kij, Kf: array [0..31] of byte;
begin
  Result := false;
  if(Len<=48) then
    Exit;
  Len := Len-48;
  if(Node=Ni) then
    begin
      if(Not ReadKix(@Kij,Node)) then
        Exit;
    end
  else if(Not ReadAx(@Kij,Node)) then
    Exit;
  p := Data;
  Move(p[Len+44],IpF,4);
  Move(p[Len+12],Kf,32);
  Move(p[Len+8],IpD,4);
  DecryptKey(@Kf,@Kij);
  if(IpKey(@Kf,@Kij)<>IpF) then
    Exit;
  l := (Len+7) And $FFFFFFF8;
  DecryptData(p,l+8,@Kf);
  Move(p[8],p^,Len);
  if(l>Len) then
    begin
      FillChar(p[Len],l-Len,0);
    end;
  if(IpData(p,l,@Kf)<>IpD) then
    Exit;
  Result := true;
end;

procedure DoneSign;
begin
  Ni := 0;
  Nop := 0;
  FillChar(Ki,32,0);
  FillChar(Kop,32,0);
end;

end.
