unit RunMes;

interface

uses
  Windows, Messages, Forms, Classes;

const
  WM_RUNMESSAGE = WM_USER + 122;

function SendRunMessage(Mes: PChar): Boolean;

implementation

var
  LogoForm: TForm = nil;

function SendRunMessage(Mes: PChar): Boolean;
var
  C: TComponent;
begin
  Result := False;
  if LogoForm=nil then
  begin
    C := Application.FindComponent('ScaleLogoForm');
    if (C<>nil) and (C is TForm) then
      LogoForm := C as TForm;
  end;
  if LogoForm<>nil then
  begin
    SendMessage(LogoForm.Handle, WM_RUNMESSAGE, Integer(Mes), 0);
    Result := True;
    Application.ProcessMessages;
  end;
end;


end.
