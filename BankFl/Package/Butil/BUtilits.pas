unit BUtilits;

interface

uses
  SysUtils, CommCons, BankCnBn, Utilits, Windows, Forms, Classes;

procedure ResortAcc(var Acc: TAccount);
function CompareResortedAcc(a1, a2: TAccount): Integer;

implementation

procedure ResortAcc(var Acc: TAccount);
var
  I: Integer;
  C: Char;
begin
  C := Acc[8];
  for I := 8 to 18 do
    Acc[I] := Acc[I+1];
  Acc[19] := C;
end;

function CompareResortedAcc(a1, a2: TAccount): Integer;
begin
  Result := 0;
  ReSortAcc(a1);
  ReSortAcc(a2);
  if a1<a2 then
    Result := -1
  else
    if a1>a2 then
      Result := 1;
end;


end.
