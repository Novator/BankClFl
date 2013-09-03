program PostMach;

uses
  Windows,
  Messages,
  Forms,
  PostMachineFrm in 'PostMachineFrm.pas' {PostMachineForm},
  ConnectFrm in 'ConnectFrm.pas' {ConnectForm},
  PostPacksFrm in 'PostPacksFrm.pas' {PostPacksForm},
  PostAbonsFrm in 'PostAbonsFrm.pas' {AbonsForm},
  AbonFrm in 'Module\AbonFrm.pas' {AbonForm},
  PostPackFrm in 'PostPackFrm.pas' {PostPackForm},
  SetupFrm in 'SetupFrm.pas' {SetupForm},
  ParamFrm in 'ParamFrm.pas' {ParamForm},
  AboutPFrm in 'AboutPFrm.pas' {AboutPForm};

{$R *.RES}

{var
  hWnd: Integer;}
begin
  {hWnd := FindWindow('TApplication', 'PostMachine');
  if hWnd = 0 then
  begin}
    Application.Initialize;
    Application.Title := 'PostMachine';
    Application.CreateForm(TPostMachineForm, PostMachineForm);
  Application.Run;
  {end
  else begin
    ShowWindow(hWnd, SW_SHOW);
    PostMessage(hWnd, WM_ACTIVATEAPP, 1, 0);
    SetForegroundWindow(hWnd);
  end;}
end.
