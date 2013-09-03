unit CryDrv;

interface
          
type
  PassFunction = function: string;

procedure EncryptKey(Key1, Key2: pointer);
procedure DecryptKey(Key1, Key2: pointer);
function IpKey(Key1, Key2: pointer): integer;
procedure EnDecryptData(Info: pointer; Len: longword; Key: pointer);
procedure EncryptData(Info: pointer; Len: longword; Key: pointer);
procedure DecryptData(Info: pointer; Len: longword; Key: pointer);
function IpData(Info: pointer; Len: longword; Key: pointer): integer;
procedure SetUz(NewUz: pointer);
function MakeKeyFromPass(PassKey: pointer; Pwd: string): boolean;
function ReadUz(KeyDev: string): boolean;
function ReadGk(KeyDev: string; PassFunc: PassFunction): boolean;
function ReadKey(fn: string; var Data; const Cnt: integer): boolean;
function WriteKey(fni: string; fno: string; Cnt: integer): boolean;
function InitRandom(fn: string): boolean;
procedure GetRandomKey(Buf: pointer);

var
  MainKey: array [0..31] of byte;

implementation

uses
  SysUtils, Windows;

var
  UzTab: pointer;
{  RndDir: string = '';}
  RandomCnt: integer;
  RandomArray: pchar = nil;

const
  Tab: array[0..15] of byte = (
     0,  1,  2,  3,  4,  5,  6,  7,
//    12, 13, 14,  8,  9, 10, 15, 11
    11, 12, 13, 15,  8,  9, 10, 14
  );

function WinToDos(Ch: byte): byte;
begin
  Result := (Tab[(Ord(Ch) SHR 4) AND $0F] SHL 4) OR (Ord(Ch) AND $0F);
end;

{$IFDEF DEBUG}
procedure DebugDump(fn: string; var t; Len: word);
var
  F: integer;
begin
  F := FileCreate(fn);
  if(F>0) then
    begin
      FileWrite(F,t,Len);
      FileClose(F);
    end;
end;
{$ENDIF}

procedure Loop8i; assembler;
{ EDX - N2 (старшая часть кодируемого блока)			}
{ EAX - N1 (младшая часть кодируемого блока)			}
{ ESI - указатель на ключ					}
asm
	mov	cl,	8
@@1:	push	eax
	add	eax,	[esi]
	add	esi,	4
	xlat
	add	ebx,	256
	ror	eax,	8
	xlat
	add	ebx,	256
	ror	eax,	8
	xlat
	add	ebx,	256
	ror	eax,	8
	xlat
	sub	ebx,	768
	rol	eax,	3
	xor	eax,	edx
	dec	cl
	pop	edx
	jne	@@1
end;

procedure Loop8d; assembler;
{ EDX - N2 (старшая часть кодируемого блока)			}
{ EAX - N1 (младшая часть кодируемого блока)			}
{ ESI - указатель на ключ					}
asm
	mov	cl,	8
@@1:	sub	esi,	4
	push	eax
	add	eax,	[esi]
	xlat
	add	ebx,	256
	ror	eax,	8
	xlat
	add	ebx,	256
	ror	eax,	8
	xlat
	add	ebx,	256
	ror	eax,	8
	xlat
	sub	ebx,	768
	rol	eax,	3
	xor	eax,	edx
	dec	cl
	pop	edx
	jne	@@1
end;

procedure EncryptKey(Key1, Key2: pointer); assembler;
{ Зашифровать Key1 на Key2 }
{ EDX - N2 (старшая часть кодируемого блока)			}
{ EAX - N1 (младшая часть кодируемого блока)			}
{ ESI - указатель на Key2					}
{ EDI - указатель на Key1					}
asm
        push    ebx
        push    esi
        push    edi
	mov	ebx,	UzTab
	mov	esi,	Key2
	mov	edi,	Key1
	mov	ch,	4
@@1:	mov	eax,	[edi]
	mov	edx,	4[edi]
	call	Loop8i
	sub	esi,	32
	call	Loop8i
	sub	esi,	32
	call	Loop8i
	call	Loop8d
	mov	[edi],	edx
	mov	4[edi],	eax
	add	edi,	8
	dec	ch
	jne	@@1
        pop     edi
        pop     esi
        pop     ebx
end;

procedure DecryptKey(Key1, Key2: pointer); assembler;
{ Расшифровать Key1 на Key2 }
{ EDX - N2 (старшая часть кодируемого блока)			}
{ EAX - N1 (младшая часть кодируемого блока)			}
{ ESI - указатель на Key2					}
{ EDI - указатель на Key1					}
asm
        push    ebx
        push    esi
        push    edi
	mov	ebx,	UzTab
	mov	esi,	Key2
	mov	edi,	Key1
	mov	ch,	4
@@1:	mov	eax,	[edi]
	mov	edx,	4[edi]
	call	Loop8i
	call	Loop8d
	add	esi,	32
	call	Loop8d
        add     esi,    32
	call	Loop8d
	mov	[edi],	edx
	mov	4[edi],	eax
	add	edi,	8
	dec	ch
	jne	@@1
        pop     edi
        pop     esi
        pop     ebx
end;

function IpKey(Key1, Key2: pointer): integer; assembler;
{ ИП Key1 на Key2 }
{ EDX - N2 (старшая часть кодируемого блока)			}
{ EAX - N1 (младшая часть кодируемого блока)			}
{ ESI - указатель на Key2					}
{ EDI - указатель на Key1					}
asm
        push    ebx
        push    esi
        push    edi
	mov	ebx,	UzTab
	mov	esi,	Key2
	mov	edi,	Key1
	mov	ch,	4
	xor	eax,	eax
	xor	edx,	edx
@@1:	xor	eax,	[edi]
	xor	edx,	4[edi]
	call	Loop8i
	sub	esi,	32
	call	Loop8i
	sub	esi,	32
	add	edi,	8
	dec	ch
	jne	@@1
        pop     edi
        pop     esi
        pop     ebx
end;

procedure EnDecryptData(Info: pointer; Len: longword; Key: pointer); assembler;
{ Зашифровать Key1 на Key2 }
{ EDX - N2 (старшая часть кодируемого блока)			}
{ EAX - N1 (младшая часть кодируемого блока)			}
{ ESI - указатель на Key2					}
{ EDI - указатель на Key1					}
asm
        push    ebx
        push    esi
        push    edi
	mov	ebx,	UzTab
	mov	esi,	Key
	mov	edi,	Info
	mov	ecx,	Len
        add     ecx,    7
        shr     ecx,    3
	mov	eax,	[edi]
	mov	edx,	4[edi]
        push    ecx
	call	Loop8i
	sub	esi,	32
	call	Loop8i
	sub	esi,	32
	call	Loop8i
	call	Loop8d
        xchg    eax,    edx
        jmp     @@2
@@1:    push    ecx
        add     eax,    $01010101
        add     edx,    $01010104
        adc     edx,    0
        push    eax
        push    edx
	call	Loop8i
	sub	esi,	32
	call	Loop8i
	sub	esi,	32
	call	Loop8i
	call	Loop8d
        xor     4[edi], eax
        xor     [edi],  edx
        pop     edx
        pop     eax
@@2:    pop     ecx
	add	edi,	8
	dec	ecx
	jne	@@1
        pop     edi
        pop     esi
        pop     ebx
end;

procedure EncryptData(Info: pointer; Len: longword; Key: pointer); assembler;
{ Зашифровать Key1 на Key2 }
{ EDX - N2 (старшая часть кодируемого блока)			}
{ EAX - N1 (младшая часть кодируемого блока)			}
{ ESI - указатель на Key2					}
{ EDI - указатель на Key1					}
asm
        push    ebx
        push    esi
        push    edi
	mov	ebx,	UzTab
	mov	esi,	Key
	mov	edi,	Info
	mov	ecx,	Len
        add     ecx,    7
        shr     ecx,    3
	mov	eax,	[edi]
	mov	edx,	4[edi]
        jmp     @@2
@@1:    push    ecx
	call	Loop8i
	sub	esi,	32
	call	Loop8i
	sub	esi,	32
	call	Loop8i
	call	Loop8d
        xor     eax,    4[edi]
        xor     edx,    [edi]
        mov     4[edi], eax
        mov     [edi],  edx
        pop     ecx
        xchg    eax,    edx
@@2:	add	edi,	8
	dec	ecx
	jne	@@1
        pop     edi
        pop     esi
        pop     ebx
end;

procedure DecryptData(Info: pointer; Len: longword; Key: pointer); assembler;
{ Зашифровать Key1 на Key2 }
{ EDX - N2 (старшая часть кодируемого блока)			}
{ EAX - N1 (младшая часть кодируемого блока)			}
{ ESI - указатель на Key2					}
{ EDI - указатель на Key1					}
asm
        push    ebx
        push    esi
        push    edi
	mov	ebx,	UzTab
	mov	esi,	Key
	mov	edi,	Info
	mov	ecx,	Len
        add     ecx,    7
        shr     ecx,    3
	mov	eax,	[edi]
	mov	edx,	4[edi]
        jmp     @@2
@@1:    push    ecx
	call	Loop8i
	sub	esi,	32
	call	Loop8i
	sub	esi,	32
	call	Loop8i
	call	Loop8d
        mov     ecx,    [edi]
        xor     [edi],  edx
        mov     edx,    4[edi]
        xor     4[edi], eax
        mov     eax,    ecx
        pop     ecx
@@2:	add	edi,	8
	dec	ecx
	jne	@@1
        pop     edi
        pop     esi
        pop     ebx
end;

function IpData(Info: pointer; Len: longword; Key: pointer): integer; assembler;
asm
        push    ebx
        push    esi
        push    edi
	mov	ebx,	UzTab
	mov	esi,	Key
	mov	edi,	Info
	mov	eax,	Len
        add     eax,    7
        shr     eax,    3
        mov     ecx,    eax
	xor	eax,	eax
	xor	edx,	edx
@@1:    push    ecx
	xor	eax,	[edi]
	xor	edx,	4[edi]
	call	Loop8i
	sub	esi,	32
	call	Loop8i
	sub	esi,	32
        pop     ecx
	add	edi,	8
        dec     ecx
	jne	@@1
        pop     edi
        pop     esi
        pop     ebx
end;

procedure SetUz(NewUz: pointer);
{ Установить новый УЗ }
asm
        push    ebx
        push    esi
        push    edi
        push    NewUz
	mov	edi,	UzTab
	xor	eax,	eax
	mov	ecx,	256
	cld
rep	stosd
        pop     esi              //NewUz
	mov	ebx,	eax
	mov	dl,	al
@@1:	sub	edi,	1024
	mov	dh,	4
@@2:    xor     ebx,    ebx
	mov	al,	[esi]
	mov	bl,	dl
	and	al,	0Fh
	mov	ecx,	16
@@3:	or	[edi+ebx], al
	add	ebx,	16
	loop	@@3
        xor     ebx,    ebx
	lodsb
	mov	bl,	dl
	and	al,	0F0h
	shl	ebx,	4
	mov	ecx,	16
@@4:	or	[edi+ebx], al
	inc	ebx
	loop	@@4
	add	edi,	256
	dec	dh
	jne	@@2
	inc	dl
	cmp	dl,	16
	jb	@@1
        pop     edi
        pop     esi
        pop     ebx
end;

function MakeKeyFromPass(PassKey: pointer; Pwd: string): boolean;
var
  i, j: integer;
  MyPassKey: array[0..37] of byte;
begin
  Result := false;
  StrPCopy(@MyPassKey,Copy(Pwd,1,37));
  j := StrLen(@MyPassKey);
  if(j>0) then
    begin
      i := 0;
      while(i<j) do
        begin
          MyPassKey[i] := WinToDos(MyPassKey[i]);
          inc(i);
        end;
      i := 0;
      while(j<37) do
        begin
          MyPassKey[j] := MyPassKey[i];
          Inc(i);
          Inc(j);
        end;
      asm
        push    esi
        push    edi
   	lea	edi,	MyPassKey
	mov	esi,	32
	add	esi,	edi
	mov	ch,	5
	cld
      @@1:
	lodsb
	mov	cl,	7
      @@2:
	ror	al,	1
	rcl	byte ptr [edi],	1
	inc	edi
	dec	cl
	jne	@@2
	dec	ch
	jne	@@1
        pop     edi
        pop     esi
      end;
      Move(MyPassKey,PassKey^,32);
      Result := true;
    end;
end;

function ReadUz(KeyDev: string): boolean;
var
  NewUz, Extra: array[0..63] of byte;
  Header: array[0..5] of byte;
  i, j: integer;
  F: integer;
begin
  Result := false;
  F := FileOpen(KeyDev,fmOpenRead);
  if(F<0) then
    Exit;
  try
    if(FileRead(F,Header,SizeOf(Header))<>SizeOf(Header)) then
      Exit;
    if((Header[0] And $F0)<>64) then
      Exit;
    if(FileRead(F,NewUz,SizeOf(NewUz))<>SizeOf(NewUz)) then
      Exit;
    i := Header[1]-1;
    while(i>0) do begin
      if(FileRead(F,Extra,SizeOf(Extra))<>SizeOf(Extra)) then
        Exit;
      for j := 0 to 63 do
        begin
          NewUz[j] := NewUz[j] xor Extra[j];
        end;
      Dec(i);
    end;
  finally
    FileClose(F);
  end;
{$IFDEF DEBUG}
  DebugDump('Uz1.tst',NewUz,64);
{$ENDIF}
  SetUz(@NewUz);
{$IFDEF DEBUG}
  DebugDump('Uz.tst',UzTab^,1024);
{$ENDIF}
  Result := true;
end;

function ReadGk(KeyDev: string; PassFunc: PassFunction): boolean;
type
  Pinteger = ^integer;
var
  NewGk, Extra: array[0..31] of byte;
  Header: array[0..5] of byte;
  PassKey: array[0..31] of byte;
  i, j: integer;
  F: integer;
begin
  Result := false;
  F := FileOpen(KeyDev,fmOpenRead);
  if(F<0) then
    Exit;
  try
    if(FileRead(F,Header,SizeOf(Header))<>SizeOf(Header)) then
      Exit;
    if((Header[0] And $F0)<>32) then
      Exit;
    if(FileRead(F,NewGk,SizeOf(NewGk))<>SizeOf(NewGk)) then
      Exit;
    i := Header[1]-1;
    while(i>0) do begin
      if(FileRead(F,Extra,SizeOf(Extra))<>SizeOf(Extra)) then
        Exit;
      for j := 0 to 31 do begin
        NewGk[j] := NewGk[j] xor Extra[j];
      end;
      Dec(i);
    end;
  finally
    FileClose(F);
  end;
{$IFDEF DEBUG}
  DebugDump('Gk1.tst',NewGk,32);
{$ENDIF}
  if((Header[0] And $0F)=0) then begin
    if(MakeKeyFromPass(@PassKey,PassFunc)) then begin
{$IFDEF DEBUG}
      DebugDump('pas.tst',Passkey,32);
{$ENDIF}
      DecryptKey(@NewGk,@PassKey);
{$IFDEF DEBUG}
      DebugDump('Gk.tst',NewGk,32);
{$ENDIF}
    end;
  end;
{$IFDEF DEBUG}
  FillChar(Extra,32,0);
  i := IpKey(@Extra,@NewGk);
  DebugDump('Ip.tst',i,4);
{$ENDIF}
  FillChar(Extra,32,0);
  if(IpKey(@Extra,@NewGk)<>Pinteger(@Header[2])^) then
    Exit;
  Move(NewGk,MainKey,32);
  Result := true;
end;

function ReadKey(fn: string; var Data; const Cnt: integer): boolean;
var
  F, i, Ip: integer;
  p: pchar;
begin
  Result := false;
  F := FileOpen(fn,fmOpenRead);
  if(F<0) then
    Exit;
  try
    if(FileRead(F,Data,Cnt*32)<>Cnt*32) then
      Exit;
    if(FileRead(F,Ip,4)<>4) then
      Exit;
  finally
    FileClose(F);
  end;
  p := @Data;
  for i := 1 to Cnt do
    begin
      DecryptKey(p,@MainKey);
      Inc(p,32);
    end;
  if(IpData(@Data,Cnt*32,@MainKey)<>Ip) then
    Exit;
  Result := true;
end;

function WriteKey(fni: string; fno: string; Cnt: integer): boolean;
var
  F, i, Ip: integer;
  buf, p: pchar;
begin
  Result := false;
  buf := AllocMem(Cnt*32);
  try
    F := FileOpen(fni,fmOpenRead);
    if(F<0) then
      Exit;
    try
      if(FileRead(F,buf^,Cnt*32)<>Cnt*32) then
        Exit;
    finally
      FileClose(F);
    end;
    Ip := IpData(buf,Cnt*32,@MainKey);
    p := buf;
    for i := 1 to Cnt do
      begin
        EncryptKey(p,@MainKey);
        Inc(p,32);
      end;
    F := FileCreate(fno);
    if(F<0) then
      Exit;
    try
      if(FileWrite(F,buf^,Cnt*32)<>Cnt*32) then
        Exit;
      if(FileWrite(F,Ip,4)<>4) then
        Exit;
    finally
      FileClose(F);
    end;
  finally
    FreeMem(buf);
  end;
  Result := true;
end;
{
function InitRandom(fn, dir: string): boolean;
const
  RandomArraySize = 256*4*32;
var
  F, L, Ip: integer;
begin
  Result := false;
  F := FileOpen(fn,fmOpenRead);
  if(F<0) then
    Exit;
  RandomArray := AllocMem(RandomArraySize);
  L := FileRead(F,RandomArray^,RandomArraySize);
  FileClose(F);
  if(L<>RandomArraySize) then
    begin
      FreeMem(RandomArray);
      RandomArray := nil;
      Exit;
    end;
  RndDir := dir;
  Result := true;
end;
}
{
function InitRandom(fn, dir: string): boolean;
begin
  Result := false;
  RandomArray := AllocMem(1024*32);
  if(Not ReadKey(fn,RandomArray^,1024)) then
    begin
      FreeMem(RandomArray);
      RandomArray := nil;
      Exit;
    end;
  RndDir := dir;
  Result := true;
end;

procedure GetRandomKey(Buf: pointer);
var
  F: integer;
  Cnt: longword;
  CntBytes: array [0..3] of byte;
  Key: array [0..31] of byte;
begin
  F := FileOpen(RndDir,fmOpenReadWrite);
  if(F<0) then
    Exit;
  FileRead(F,Cnt,SizeOf(Cnt));
  Move(Cnt,CntBytes,SizeOf(CntBytes));
  Inc(Cnt);
  FileSeek(F,0,0);
  FileWrite(F,Cnt,SizeOf(Cnt));
  FileClose(F);
  Move((RandomArray+(CntBytes[3]+256*3)*32)^,Buf^,32);
  Move((RandomArray+(CntBytes[2]+256*2)*32)^,Key,32);
  EncryptKey(Buf,@Key);
  Move((RandomArray+(CntBytes[1]+256*1)*32)^,Key,32);
  EncryptKey(Buf,@Key);
  Move((RandomArray+CntBytes[0]*32)^,Key,32);
  EncryptKey(Buf,@Key);
end;
}
function InitRandom(fn: string): boolean;
var
  t: TDateTime;
  tt: array [0..1] of longword absolute t;
  t1: array [0..7] of longword;
begin
  Result := false;
  RandomArray := AllocMem(1024*32);
  if(Not ReadKey(fn,RandomArray^,1024)) then
    begin
      FreeMem(RandomArray);
      RandomArray := nil;
      Exit;
    end;
  t := Date+Time;
  RandomCnt := GetTickCount Xor tt[0] Xor tt[1];
  GetRandomKey(@t1);
  RandomCnt := t1[0] Xor t1[1] Xor t1[2] Xor t1[3] Xor
               t1[4] Xor t1[5] Xor t1[6] Xor t1[7];
  Result := true;
end;

procedure GetRandomKey(Buf: pointer);
var
  CntBytes: array [0..3] of byte;
  Key: array [0..31] of byte;
begin
  Move(RandomCnt,CntBytes,SizeOf(CntBytes));
  Inc(RandomCnt);
  Move((RandomArray+(CntBytes[3]+256*3)*32)^,Buf^,32);
  Move((RandomArray+(CntBytes[2]+256*2)*32)^,Key,32);
  EncryptKey(Buf,@Key);
  Move((RandomArray+(CntBytes[1]+256*1)*32)^,Key,32);
  EncryptKey(Buf,@Key);
  Move((RandomArray+CntBytes[0]*32)^,Key,32);
  EncryptKey(Buf,@Key);
end;

begin
  UzTab := AllocMem(1024);
end.
