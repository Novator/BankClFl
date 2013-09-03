program Upd_Simple;

uses
  Windows,
  SysUtils,
  Messages;

{$R *.RES}

const
  MesTitle: PChar = 'Обновление';

function ParentWnd: hWnd;
begin
  Result := GetTopWindow(0);
end;

function RunAndWait(AppPath: string): Boolean;
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
  StrPLCopy(CmdLine, AppPath, SizeOf(CmdLine));
  if CreateProcess(nil, CmdLine, nil, nil, FALSE,
    DETACHED_PROCESS, nil, nil, si, pi) then
  begin
    WaitforSingleObject(pi.hProcess, INFINITE);
    GetExitCodeProcess(pi.hProcess, Code);
    Result := Code=0;
  end
  else
    MessageBox(ParentWnd, PChar('Не удалось запустить программу обновления '
      +#13#10+CmdLine), MesTitle, MB_OK or MB_ICONERROR);
end;

function WndProc(Wnd: HWND; Msg: UINT; wParam: WPARAM;
  lParam: LPARAM): LRESULT; stdcall; far;
begin
  Result := DefWindowProc(Wnd, Msg, wParam, lParam);
end;

const
  WndWidth = 290;
  WndHeight = 95;
  EditHeight = 63;
  WinClassName: PChar = 'WaitForm';
var
  I, L, K, Err: Integer;
  Wc: TWndClass;
  Font: hFont;
  MainWnd, EdtWnd: hWnd;
  WaitFormIsInited: Boolean = False;

procedure InitWaitForm;
begin
  FillChar(Wc, SizeOf(Wc), #0);
  with Wc do
  begin
    Style := 0;
    lpfnWndProc := @WndProc;
    cbClsExtra := 0;
    cbWndExtra := 0;
    hIcon := 0;
    hCursor := LoadCursor(0, IDC_ARROW);
    hbrBackground := COLOR_BACKGROUND;
    lpszMenuName := 'MainMenu';
    lpszClassName := WinClassName;
  end;
  Wc.hInstance := hInstance;
  if Windows.RegisterClass(Wc)<>0 then
    WaitFormIsInited := True;
end;

procedure ProcessMessages;
var
  Msg: TMsg;
begin
  while PeekMessage(Msg, 0, 0, 0, PM_REMOVE) do
  begin
    if Msg.Message <> WM_QUIT then
    begin
      TranslateMessage(Msg);
      DispatchMessage(Msg);
    end;
  end;
end;

var
  S: string;

procedure ShowWaitForm(Mes: string);
begin
  if WaitFormIsInited then
  begin
    if MainWnd=0 then
    begin
      MainWnd := CreateWindow(Wc.lpszClassName, MesTitle,
        WS_POPUP or WS_CAPTION or WS_BORDER {or WS_SYSMENU} or WS_VISIBLE,
        (GetSystemMetrics(SM_CXSCREEN) - WndWidth) div 2,
        (GetSystemMetrics(SM_CYSCREEN) - WndHeight) div 2,
        WndWidth, WndHeight, 0, 0, hInstance, nil);
      if MainWnd<>0 then
      begin
        Font := CreateFont(-MulDiv(8, 96, 72),
          0, 0, 0, FW_NORMAL, 0, 0, 0, RUSSIAN_CHARSET, 0, 0,
          DEFAULT_QUALITY, DEFAULT_PITCH, 'MS Sans Serif');
        EdtWnd := CreateWindow('EDIT', nil,
          WS_VISIBLE or WS_CHILD {or WS_VSCROLL or WS_BORDER}
          or ES_MULTILINE or ES_READONLY or ES_AUTOVSCROLL,
          6, 6, WndWidth-20, EditHeight-4, MainWnd, 1,
          hInstance, nil);
        SendMessage(EdtWnd, WM_SETFONT, Font, 0);
      end;
    end;
    if MainWnd<>0 then
    begin
      S := Mes;
      SendMessage(EdtWnd, WM_SETTEXT, 0, Integer(PChar(S)));
    end;
    ShowWindow(MainWnd, SW_SHOW);
    ProcessMessages;
  end;
end;

procedure CloseWaitForm;
begin
  DeleteObject(Font);
  ShowWindow(MainWnd, SW_HIDE);
  CloseWindow(MainWnd);
  MainWnd := 0;
  ProcessMessages;
end;

const
  OldMod: PChar = 'Base\module.old';
  CurMod: PChar = 'Base\module.btr';
  NewMod: PChar = 'Base\module.new';

var
  AppName: array[0..1023] of Char;
  si: TStartupInfo;
  pi: TProcessInformation;
  {hWnd, }WaitLimit, Step: Integer;
  App: HModule;
  B: Boolean;
begin
  if ParamCount>0 then
  begin
    StrPLCopy(AppName, ParamStr(1), SizeOf(AppName));
    WaitLimit := 50;
    if ParamCount>1 then
      Val(ParamStr(2), WaitLimit, Step);
    Step := 0;
    repeat
      hWnd := FindWindow('TApplication', 'Клиент-банк');
      {App := GetModuleHandle(AppName);}
      Sleep(200);
      Inc(Step);
    until hWnd=0{(App=0)} or (Step>=WaitLimit);
    if App=0 then
    begin
      Sleep(500);
      InitWaitForm;
      ShowWaitForm('Подождите, идет распаковка новых файлов...');
      B := RunAndWait('UpdSfx9.exe');
      CloseWaitForm;
      B := B and RunAndWait('VerUpd.exe VerUpd9.log');
      if B then
      begin
        DeleteFile('UpdSfx9.exe');
        if FileExists(NewMod) then
        begin
          DeleteFile(OldMod);
          if RenameFile(CurMod, OldMod) then
          begin
            if RenameFile(NewMod, CurMod) then
              MessageBox(ParentWnd, 'Набор модулей обновлен', MesTitle,
                MB_OK or MB_ICONINFORMATION)
            else
              RenameFile(OldMod, CurMod);
          end;
        end;
      end
      else
        MessageBox(ParentWnd, 'Возникли ошибки при обновлении'#13#10
          +'Сообщите об этом в банк по т. 180-223', MesTitle,
          MB_OK or MB_ICONWARNING);
      FillChar(si, SizeOf(si), #0);
      with si do
      begin
        cb := SizeOf(si);
        dwFlags := STARTF_USESHOWWINDOW;
        wShowWindow := SW_SHOWDEFAULT;
      end;
      if not CreateProcess(AppName, nil, nil, nil, FALSE,
        DETACHED_PROCESS, nil, nil, si, pi)
      then
        MessageBox(ParentWnd, PChar('Ошибка запуска обновленной программы ['+AppName+']'),
          MesTitle, MB_OK or MB_ICONERROR);
    end
    else
      MessageBox(ParentWnd, PChar('Программа не завершеилась ['+AppName
        +']. Обновление невозможно'), MesTitle, MB_OK or MB_ICONERROR);
  end;
  {else
    MessageBox(ParentWnd, 'Должен быть параметр - программа обновления',
      MesTitle, MB_OK or MB_ICONERROR);}
end.
