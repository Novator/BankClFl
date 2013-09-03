unit ExTxFile;

interface

uses
  Windows, SysUtils;

type
  TExtTextFile = record
    FH: THandle;
    OpS: OFSTRUCT;
    Buf: PChar;
    I, L, W: DWord;
    Eof: Boolean;
    ReadedBytes: DWord;
  end;

var
  WorkTextFileBuf: DWord  = 1024;
  LimitTextFileBuf: DWord = 65535;

function OpenTextFile(var F: TExtTextFile; FN: string): Word;
function ExtReadLn(var F: TExtTextFile; var S: string): Integer;
function CloseTextFile(var F: TExtTextFile): Boolean;

implementation

function OpenTextFile(var F: TExtTextFile; FN: string): Word;
begin
  F.OpS.cBytes := SizeOf(F.OpS);
  F.FH := OpenFile(PChar(FN), F.OpS, OF_READ);
  if F.FH=INVALID_HANDLE_VALUE then
  begin
    Result := F.OpS.nErrCode;
    if Result=0 then
      Result := 65535;
  end
  else begin
    Result := 0;
    F.Buf := nil;
    F.Eof := GetFileSize(F.FH, nil)=0;
  end;
  F.ReadedBytes := 0;
end;

function ExtReadLn(var F: TExtTextFile; var S: string): Integer;
var
  K: DWord;
begin
  Result := -1;
  if not F.Eof then
  begin
    if F.Buf=nil then
    begin
      F.W := WorkTextFileBuf;
      F.Buf := AllocMem(F.W);
      F.I := 0;
      F.L := 0;
    end;
    while not F.Eof and (Result<0) do  
    begin
      K := F.I;
      while (K<F.L) and (F.Buf[K]<>#13) do
        Inc(K);
      if (K<F.L) or ((K>=LimitTextFileBuf) and (F.I=0)) then
      begin
        if K<F.L then
        begin
          F.Buf[K] := #0;
          Inc(K);
          if (K<F.L) and (F.Buf[K]=#10) then
            Inc(K);
        end
        else
          F.Buf[K-1] := #0;
        S := StrPas(@F.Buf[F.I]);
        F.I := K;
        Result := 0;
      end
      else begin
        K := 0;
        if F.I<F.L then
        begin   {есть данные в буфере}
          if F.I=0 then
          begin  {буфер нечитан, но строка не была найдена - увеличим}
            Inc(F.W, WorkTextFileBuf);
            if F.W>LimitTextFileBuf then
              F.W := LimitTextFileBuf;
            ReAllocMem(F.Buf, F.W);
            K := 1;
          end
          else begin  {буфер был читан, переместим данные в начало и дочитаем буфер}
            F.L := F.L-F.I;
            Move(F.Buf[F.I], F.Buf[0], F.L);
          end;
        end
        else
          F.L := 0;
        if (K=0) and (F.W>WorkTextFileBuf) and (F.L<=WorkTextFileBuf) then
        begin
          F.W := WorkTextFileBuf;
          ReAllocMem(F.Buf, F.W);
        end;
        //Messagebox(0, PChar('1/'+inttostr(F.W)+':'+inttostr(F.L)+'['
        //  +Copy(StrPas(F.Buf), 1, F.L)+']'), '1111', 0);
        F.I := 0;
        if ReadFile(F.FH, F.Buf[F.L], F.W-F.L, K, nil) then
        begin
          Inc(F.ReadedBytes, K);
          Inc(F.L, K);
          //messagebox(0, PChar('2/'+inttostr(F.W)+':'+inttostr(F.L)+'['
          //  +Copy(StrPas(F.Buf), 1, F.L)+']'), '22', 0);
          if (F.I<F.L) and (F.Buf[F.I]=#10) then
            Inc(F.I);
          if K=0 then
          begin   {не было чтения}
            if F.L<F.W then
            begin
              F.Buf[F.L-F.I] := #0;
              S := StrPas(@F.Buf[F.I]);
            end
            else
              S := Copy(StrPas(@F.Buf[F.I]), 1, F.L);
            F.L := 0;
            Result := 0;
          end
          else begin
            Result := -2;
            {messagebox(0, PChar('3/'+inttostr(F.W)+':'+inttostr(F.I)+'['
              +Copy(StrPas(F.Buf), 1, F.L)+']'), '33333333', 0);}
          end;
          F.Eof := F.L=0;
        end
        else begin
          Result := GetLastError;
          if Result<0 then
            Result := -Result;
        end;
      end;
    end;
  end;
  if F.Eof and (F.Buf<>nil) then
  begin
    FreeMem(F.Buf);
    F.Buf := nil;
  end;
end;

function CloseTextFile(var F: TExtTextFile): Boolean;
begin
  Result := CloseHandle(F.FH);
  if F.Buf<>nil then
  begin
    FreeMem(F.Buf);
    F.Buf := nil;
  end;
end;

end.
