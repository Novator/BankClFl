program Update2615;

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

procedure ShowWaitForm(Mes: string);
var
  S: string;
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

procedure DestroyWaitForm;
begin
  DeleteObject(Font);
  ShowWindow(MainWnd, SW_HIDE);
  DestroyWindow(MainWnd);
  MainWnd := 0;
  ProcessMessages;
end;

const
  plInfo = 0;
  plErr  = 1;

procedure ProtoMes(L: Byte; S: string);
begin
  if L=plErr then
    MessageBox(ParentWnd, PChar(S), MesTitle, MB_OK or MB_ICONERROR);
end;

function RegistrItcs: Boolean;
const
  MesTitle: PChar = 'Регистрация СКЗИ';
var
  H, E: Integer;
  S, S2: string;
  F: TextFile;
  SD: array[0..255] of Char;
begin
  Result := False;
  S := 'register.bat';
  GetSystemDirectory(SD, SizeOf(SD));
  if (StrLen(SD)>0) and (SD[StrLen(SD)-1]<>'\') then
    StrLCat(SD, '\', SizeOf(SD));
  //ShowInfo('Открытие файла '+S+'...');
  AssignFile(F, S);
  {$I-} Reset(F); {$I+}
  if IOResult=0 then
  begin
    E := 0;
    while not Eof(F) do
    begin
      ReadLn(F, S);
      if (Length(Trim(S))>0) and (UpperCase(Copy(S, 1, 4))<>'REM ') then
      begin
        if Length(ExtractFilePath(S))=0 then
          S := SD + S;
        //ShowInfo('Вполнение команды ['+S+']...');
        S2 := '';
        H := WinExec(PChar(S), SW_SHOWNORMAL);
        case H of
          ERROR_BAD_FORMAT:
            S2 := 'Ошибочный формат';
          ERROR_FILE_NOT_FOUND:
            S2 := 'Файл не найден';
          ERROR_PATH_NOT_FOUND:
            S2 := 'Путь не найден';
          else
            if H<=31 then
              S2 := 'Ошибка запуска';
        end;
        if Length(S2)>0 then
        begin
          Inc(E);
          //MessageBox(Handle, PChar(S2+' при выполнении '+S),
          //  MesTitle, MB_OK or MB_ICONERROR);
        end;
      end;
    end;
    CloseFile(F);
    if E=0 then
    begin
      Result := True;
      S := 'Скрипт регистрации СКЗИ успешно выполнен';
      E := MB_ICONINFORMATION;
    end
    else begin
      S := 'Не было выполнено команд: '+IntToStr(E);
      E := MB_ICONWARNING;
    end;
  end
  else begin
    S := 'Не удалось открыть файл регистрации '+S;
    E := MB_ICONERROR;
  end;
  //MessageBox(Handle, PChar(S), MesTitle, MB_OK or E);
  //ShowInfo(S);
end;

(*type
  TAccount = array[0..19] of char;

  TSity = array[0..24] of char;
  TSityType = array[0..4] of char;

  PNpRec = ^TNpRec;
  TNpRec = packed record                                {Населенные пункты банков}
    npIder:   longint;                  {Идер нас.пункта}           {0      0,4}
    npName:   TSity;                    {Наименование нас.пункта}   {1.0    4,25}
    npType:   TSityType;                {Аббревиатура}              {1.1    29,5}
  end;                                                              {       =34}

  TBankTypeOld = array[0..3] of Char;
  TBankNameOld = array[0..39] of Char;
  TBankNameNew = array[0..44] of Char;

  PBankOldRec = ^TBankOldRec;
  TBankOldRec = packed record                       {Банковские учреждения}
    brCod:    longint;                  {БИК}                 {k0}  {0,4}
    brKs:     TAccount;                 {К/С}                       {4,20}
    brNpIder: longint;                  {Идер нас.пункта}     {k1}  {24,4}
    brType:   TBankTypeOld;        {Аббревиатура}                   {28,4}
    brName:   TBankNameOld;        {Наименование банка}       {k2}  {32,40}
  end;                                                              {=72}

  PBankNewRec = ^TBankNewRec;
  TBankNewRec = packed record                       {Банковские учреждения}
    brCod:    longint;                  {БИК}                 {k0}  {0,4}
    brKs:     TAccount;                 {К/С}                       {4,20}
    brNpIder: longint;                  {Идер нас.пункта}     {k1}  {24,4}
    brName:   TBankNameNew;             {Наименование банка}  {k2}  {28,45}
  end;                                                              {=73}

function ConvertBankSpr(FN1, FN2: string): Boolean;
var
  B1, B2: TBtrBase;
  Len, Res, Bik, N: Integer;
  Bank1: TBankOldRec;
  Bank2: TBankNewRec;
  Buf: array[0..50] of Char;
begin
  Result := False;
  B1 := TBtrBase.Create;
  Res := B1.Open(FN1, baReadOnly);
  if Res=0 then
  begin
    B2 := TBtrBase.Create;
    Res := B2.Open(FN2, baNormal);
    if Res=0 then
    begin
      N := 0;
      Len := SizeOf(Bank1);
      Res := B1.GetFirst(Bank1, Len, Bik, 0);
      while Res=0 do
      begin
        FillChar(Bank2, SizeOf(Bank2), #0);
        Bank2.brCod := Bank1.brCod;
        Bank2.brKs := Bank1.brKs;
        Bank2.brNpIder := Bank1.brNpIder;
        StrLCopy(Buf, Bank1.brType, SizeOf(Bank1.brType));
        if StrLen(Buf)>0 then
          StrCat(Buf, ' ');
        StrLCat(Buf, Bank1.brName, SizeOf(Bank1.brName));
        if StrLen(Buf)<SizeOf(Bank2.brName) then
          StrLCopy(Bank2.brName, Buf, SizeOf(Bank2.brName)-1)
        else
          Move(Buf, Bank2.brName, SizeOf(Bank2.brName));
        Len := SizeOf(Bank2);
        Res := B2.Insert(Bank2, Len, Bik, 0);
        if Res=0 then
          Inc(N);

        Len := SizeOf(Bank1);
        Res := B1.GetNext(Bank1, Len, Bik, 0);
      end;
      Res := B2.Close;
      Result := True;
      ProtoMes(plInfo, 'Перенесено записей '+IntToStr(N));
    end
    else
      ProtoMes(plErr, 'Не удалось открыть '+FN2);
    Res := B1.Close;
    B2.Free;
  end
  else
    ProtoMes(plErr, 'Не удалось открыть '+FN1);
  B1.Free;
end;
*)
procedure Pause(Ms: dWord);
var
  I: Integer;
begin
  I := Ms div 10;
  repeat
    Sleep(10);
    Dec(I);
    ProcessMessages;
  until I>0;
end;

const
  //AppName: array[0..1023] of Char;
  AppName: PChar = 'BankCl.exe';
  NewAppName: PChar = 'BankCl.old';
  OldMod: PChar = 'Base\module.old';
  CurMod: PChar = 'Base\module.btr';
  NewMod: PChar = 'Base\module.new';
  NewReg: PChar = 'Base\setup.btr';
  //NewReg0: PChar = 'Base\setup.new';
  UpdArch: PChar = 'Sfx2615.exe';
  //UpdSdkArch: PChar = 'Sfx_Sdk.exe';
  SrciptRun1: PChar = 'VerUpd.exe VUpd2615.run';
//  SrciptRun2: PChar = 'VerUpd.exe VUpd255.run';
  ItcsMainDll: PChar = 'Tcc_Itcs.dll';
  InstallSdkCmd: PChar = 'CoInst.exe -D7 -C4';
  {OldBankFN: PChar = 'Base\bank.btr';
  NewBankFN: PChar = 'Base\bankn.btr';}
var
  si: TStartupInfo;
  pi: TProcessInformation;
  Wnd, WaitLimit, Step: Integer;
  //App: HModule;
  B: Boolean;
  S: string;
begin
  if ParamCount>0 then
  begin
    S := ParamStr(0);
    S := ExtractFilePath(S);
    SetCurrentDirectory(PChar(S));
    //StrPLCopy(AppName, ParamStr(1), SizeOf(AppName));
    WaitLimit := 35;
    if ParamCount>1 then
      Val(ParamStr(2), WaitLimit, Step);
    Step := 0;
    repeat
      Wnd := FindWindow('TApplication', 'Клиент-банк');
      {App := GetModuleHandle(AppName);}
      Pause(200);
      Inc(Step);
    until (Wnd=0{(App=0}) or (Step>=WaitLimit);
    if Wnd=0 then
    begin
      if FileExists(UpdArch) then
      begin
        if FileExists(AppName) then
        begin
          DeleteFile(NewAppName);
          Pause(500);
          B := RenameFile(AppName, NewAppName);
        end
        else
          B := FileExists(NewAppName);
        if B then
        begin
          InitWaitForm;
          ShowWaitForm('Подождите, идет распаковка новых файлов...');
          Pause(500);
          S := '';
          B := RunAndWait(UpdArch);
          DestroyWaitForm;
          if B then
          begin
//            if FileExists(NewReg) then
//              S := SrciptRun2
//            else
            S := SrciptRun1;
            B := RunAndWait(S);
            if B then
            begin
              S := '';
              if not FileExists(ItcsMainDll) then
              begin
                {if FileExists(UpdSdkArch) then
                begin
                  InitWaitForm;
                  ShowWaitForm('Регистрация новой СКЗИ...');
                  B := RunAndWait(UpdSdkArch);
                  DestroyWaitForm;
                end
                else}
                  B := RunAndWait(InstallSdkCmd);
              end;
              {if B then    {Этот кусок для новых клиентов!
              begin
                InitWaitForm;
                ShowWaitForm('Регистрация новой СКЗИ...');
                B := RegistrItcs;
                DestroyWaitForm;
                if not B then
                  S := 'СКЗИ не удалось зарегистрировать';
              end
              else
                S := 'СКЗИ не было установлено';}
              B := True;
              if FileExists(NewMod) then
              begin
                DeleteFile(OldMod);
                if RenameFile(CurMod, OldMod) then
                begin
                  if RenameFile(NewMod, CurMod) then
                  begin
                    DeleteFile(UpdArch);
                    {DeleteFile(OldBankFN);}
                    MessageBox(ParentWnd, 'Набор модулей обновлен', MesTitle,
                      MB_OK or MB_ICONINFORMATION)
                  end
                  else
                    RenameFile(OldMod, CurMod);
                end
                else
                  MessageBox(ParentWnd, PChar('Не удалось заменить список модулей ['
                    +CurMod+']'), MesTitle, MB_OK or MB_ICONERROR);
              end;
            end
            else
              S := 'Ошибка запуска скрипта обновления '+S;
          end
          else
            S := 'Ошибка запуска самораспаковывающегося архива '+UpdArch;
          if Length(S)>0 then
            MessageBox(ParentWnd, PChar('Возникли ошибки при обновлении'#13#10
              +S+#13#10'Сообщите об этом в банк по т. 180-223'), MesTitle,
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
            MessageBox(ParentWnd, PChar('Ошибка запуска обновленной программы ['
              +AppName+']'), MesTitle, MB_OK or MB_ICONERROR);
        end
        else
          MessageBox(ParentWnd, PChar('Не удалось убрать exe-файл ['+AppName
            +']'#13#10'Возможно программа открыта на других компьютерах'+
            #13#10'Закройте ее на остальных компьютерах и попробуйте снова'),
            MesTitle, MB_OK or MB_ICONERROR);
      end
      else
        MessageBox(ParentWnd, PChar('Нет самораспаковывающегося архива ['+UpdArch
          +']'), MesTitle, MB_OK or MB_ICONERROR);
    end
    else
      MessageBox(ParentWnd, PChar('Программа не завершилась ['+AppName
        +']. Обновление невозможно'), MesTitle, MB_OK or MB_ICONERROR);
  end;
  {else
    MessageBox(ParentWnd, 'Должен быть параметр - программа обновления',
      MesTitle, MB_OK or MB_ICONERROR);}
end.
