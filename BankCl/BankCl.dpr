program BankCl;

uses
  Forms,
  Windows,
  Messages,
  SysUtils,
  Controls,
  AppUtils,
  Common, 
  MainFrm in 'MainFrm.pas' {MainForm},
  AboutFrm in 'AboutFrm.pas' {AboutForm},
  ParamFrm in 'ParamFrm.pas' {ParamForm},
  SetupFrm in 'SetupFrm.pas' {SetupForm},
  ExportBaseFrm in 'ExportBaseFrm.pas' {ExportBaseForm},
  KeyTaskFrm in 'KeyTaskFrm.pas' {KeyTaskForm},
  ChooseUserFrm in 'ChooseUserFrm.pas' {ChooseUserForm},
  KeyPathDlg in 'KeyPathDlg.pas' {KeyPathDialog},
  OneCBuhFrm in 'OneCBuhFrm.pas' {OneCBuhForm};

{$R *.RES}        
{$R BankClExt.RES}      
{$R BankClExt2.RES}  
{$R BankClExt3.RES}

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
    {ShowWindow(hWnd, SW_SHOW);
    PostMessage(hWnd, WM_ACTIVATEAPP, 1, 0);
    SetForegroundWindow(hWnd);}
    PostMessage(hWnd, CM_DEACTIVATE, 555, 0);
  end;
end.
