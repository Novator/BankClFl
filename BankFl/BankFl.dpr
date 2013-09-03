program BankFl;

uses
  Forms,
  Windows,
  Messages,
  SysUtils,
  Controls,
  AppUtils,
  MainFrm in 'MainFrm.pas' {MainForm},
  AboutFrm in 'AboutFrm.pas' {AboutForm},
  GetPassDialog in 'GetPassDialog.PAS',
  SclLogoFrm in 'SclLogoFrm.pas' {ScaleLogoForm},
  ParamFrm in 'ParamFrm.pas' {ParamForm},
  SetupFrm in 'SetupFrm.pas' {SetupForm},
  ExportBaseFrm in 'ExportBaseFrm.pas' {ExportBaseForm};

{$R *.RES}

function GetIniName: string;
begin
  Result := ChangeFileExt(Application.ExeName, '.ini');
end;

var
  hWnd: Integer;
begin
  hWnd := FindWindow('TApplication', 'Банк-клиент');
  if hWnd = 0 then
  begin
    Application.Initialize;
    OnGetDefaultIniName := GetIniName;
    Application.Title := 'Банк-клиент';
    Application.CreateForm(TMainForm, MainForm);
    Application.Run;
  end
  else begin
    ShowWindow(hWnd, SW_SHOW);
    PostMessage(hWnd, WM_ACTIVATEAPP, 1, 0);
    SetForegroundWindow(hWnd);
  end;
end.
