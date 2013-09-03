program KeyPath;

uses
  Windows,
  SysUtils;

{$APPTYPE CONSOLE}

const
  BcName: PChar = 'BankCl.exe';
  Offset: Integer = $0F478;
  MaxLen = 128;
var
  P: PChar;
  Buf: array[0..MaxLen] of Char;
  F: file of Byte;
  I: Integer;
begin
  P := GetCommandLine;
  I := 0;
  if (P<>nil) and (StrLen(P)>0) then
  begin
    while (P[I]<>#0) and (P[I]<>' ') and (I<512) do
      Inc(I);
    if P[I]=#0 then
      I := 0
    else begin
      Inc(I);
      StrLCopy(Buf, @P[I], SizeOf(Buf));
      I := StrLen(Buf);
    end;
  end;
  if I=0 then
    Writeln('KeyPath Changer for Bank-Client 1.02 of TransCapitalBank');
  AssignFile(F, BcName);
  {$I-} Reset(F); {$I+}
  if IOResult=0 then
  begin
    {$I-} Seek(F, Offset); {$I+}
    if IOResult=0 then
    begin
      if I=0 then
      begin
        BlockRead(F, Buf, SizeOf(Buf));
        WriteLn('Current Path: '+Buf);
      end
      else begin
        Inc(I);
        BlockWrite(F, Buf, I);
        WriteLn('Set to: ['+Buf+']');
      end;
    end
    else
      Writeln('Cannot seek file pos');
    CloseFile(F);
  end
  else
    Writeln('Cannot open file');
end.
