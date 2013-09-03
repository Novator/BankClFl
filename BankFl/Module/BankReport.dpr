program BankReport;

uses
  Forms,
  Windows,
  Messages,
  SysUtils,
  Controls,
  AppUtils,
  MainFrm in '..\..\QrmReport\MainFrm.pas' {MainForm},
  AboutFrm in '..\..\QrmReport\AboutFrm.pas' {AboutForm},
  ParamFrm in '..\..\QrmReport\ParamFrm.pas' {ParamForm},
  SetupFrm in '..\..\QrmReport\SetupFrm.pas' {SetupForm};

{$R *.RES}        

function GetIniName: string;
begin
  Result := ChangeFileExt(Application.ExeName, '.ini');
end;

var
  hWnd: Integer;
begin
  hWnd := FindWindow('TApplication', 'Клиент-банк');
  if hWnd = 0 then
  begin
    Application.Initialize;
    OnGetDefaultIniName := GetIniName;
    Application.Title := 'Клиент-банк';
    Application.CreateForm(TMainForm, MainForm);
  Application.Run;
  end
  else begin
    ShowWindow(hWnd, SW_SHOW);
    PostMessage(hWnd, WM_ACTIVATEAPP, 1, 0);
    SetForegroundWindow(hWnd);
  end;
end.
