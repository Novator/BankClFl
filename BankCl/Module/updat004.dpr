library updat004;

{ Important note about DLL memory management: ShareMem must be the
  first unit in your library's USES clause AND your project's (select
  Project-View Source) USES clause if your DLL exports any procedures or
  functions that pass strings as parameters or function results. This
  applies to all strings passed to and from your DLL--even those that
  are nested in records and classes. ShareMem is the interface unit to
  the BORLNDMM.DLL shared memory manager, which must be deployed along
  with your DLL. To avoid using BORLNDMM.DLL, pass string information
  using PChar or ShortString parameters. }

uses
  SysUtils,
  Classes,
  Windows;

const
  MesTitle: PChar = 'Обновление "Клиент-банка"';

function ParentWnd: hWnd;
begin
  Result := GetTopWindow(0);
end;

function DoUpdate: Boolean;
var
  si: TStartupInfo;
  pi: TProcessInformation;
  CmdLine: array[0..1023] of Char;
  Code: dWord;
  S: string;
begin
  Result := False;
  S := ParamStr(0);
  S := ExtractFilePath(S);
  SetCurrentDirectory(PChar(S));
  FillChar(si, SizeOf(si), #0);
  with si do
  begin
    cb := SizeOf(si);
    dwFlags := STARTF_USESHOWWINDOW;
    wShowWindow := SW_SHOWDEFAULT;
  end;
  StrPLCopy(CmdLine, 'UpdSfx9.exe', SizeOf(CmdLine));
  if CreateProcess(nil, CmdLine, nil, nil, FALSE,
    DETACHED_PROCESS, nil, nil, si, pi) then
  begin
    {WaitforSingleObject(pi.hProcess, INFINITE);
    GetExitCodeProcess(pi.hProcess, Code);}
    Result := {Code=0}True;
  end
  else
    MessageBox(ParentWnd, PChar('Не удалось запустить программу обновления обновления'
      +#13#10+CmdLine), MesTitle, MB_OK or MB_ICONERROR);
  if not Result then
    Result := MessageBox(ParentWnd, 'Возникли ошибки при обновлении'#13#10
      +'Попытаться провести обновление в следующий раз?',
      MesTitle, MB_YESNOCANCEL or MB_ICONWARNING) <> ID_YES;
end;

exports
  DoUpdate;

begin
end.

