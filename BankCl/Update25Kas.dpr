program Update25Kas;

uses
  Windows,
  SysUtils,
  Btrieve,
  Db,
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

type
  TParamIdent = array[0..31] of Char;
  TParamName = array[0..127] of Char;
  TStrValue = array[0..235] of Char;
  TParamMeasure = array[0..19] of Char;

  PParamNewRec = ^TParamNewRec;            {Параметр реестра}
  TParamNewRec = packed record
    pmSect:   Word;           { Секция                   0, 2      k0.1}
    pmNumber: Longint;        { Номер параметра          2, 4      k0.2}
    pmUser:   Word;           { Пользователь             6, 2      k0.3  k1.2}
    pmIdent:  TParamIdent;    { Идентефикатор            8, 32     k1.1}
    pmName:   TParamName;     { Название                 20, 128}
    pmMeasure: TParamMeasure; { ЕИ                       148, 20}
    pmLevel:  Byte;           { Уровень                  168, 1}
    case pmType: TFieldType of   { Тип параметра         169, 1 = 170}
    ftString: (
      pmStrValue: TStrValue;   { Значение                170, (236)}
    );
    ftInteger: (
      pmIntValue: Integer;     {                         170, 4}
      pmMinIntValue: Integer;  {                         174, 4}
      pmMaxIntValue: Integer;  {                         178, 4}
      pmDefIntValue: Integer;  {                         182, 4}
    );
    ftBoolean: (
      pmBoolValue: Boolean;    {                         170, 4}
      pmDefBoolValue: Boolean; {                         174, 4}
    );
    ftFloat: (
      pmFltValue: Double;      {                         170, 8}
      pmMinFltValue: Double;   {                         178, 8}
      pmMaxFltValue: Double;   {                         186, 8}
      pmDefFltValue: Double;   {                         194, 8}
    );
    ftDate: (
      pmDateValue: Word;       {                         170, 2}
      pmDefDateValue: Word;    {                         172, 2}
    );
    ftUnknown: (
      pmBuffer: Char;         {                         170, (max)}
    );
  end;                                                   {=(200)}

function FillZeros(V,L: Integer): string;
begin
  Result := IntToStr(V);
  while Length(Result)<L do
    Result := '0'+Result;
end;

function AddSetupParams(FN1, FN2: string): Boolean;
var
  B: TBtrBase;
  F: TextFile;
  Len, Res, N, I, J: Integer;
  Buf: array[0..50] of Char;
  ParamRec, ParamRec2: TParamNewRec;
  S, S2: string;
  Key1:
    packed record
      pkIdent: TParamIdent;
      pkUser: Word;
    end;
begin
  Result := False;
  AssignFile(F, FN1);
  {$I-} Reset(F); {$I+}
  if IOResult=0 then
  begin
    B := TBtrBase.Create;
    try
      Res := B.Open(FN2, baNormal);
      if Res=0 then
      begin
        N := 0;
        while not Eof(F) do
        begin
          ReadLn(F, S);
          S := Trim(S);
          if Length(S)>0 then
          begin
            I := Pos('|', S);
            if I>0 then
            begin
              S2 := Trim(Copy(S, 1, I-1));
              Delete(S, 1, I);
              Val(S2, J, I);
              //MessageBox(ParentWnd, PChar('!'+S+'['+S2+']'), MesTitle, MB_OK);
              if I=0 then
              begin
                I := Pos('|', S);
                if I>0 then
                begin
                  S2 := Trim(Copy(S, 1, I-1));
                  Delete(S, 1, I);
                  S := Trim(S);
                  FillChar(Key1, SizeOf(Key1), #0);
                  FillChar(ParamRec, SizeOf(ParamRec), #0);
                  //MessageBox(ParentWnd, PChar(IntToStr(J)+'['+S2+']'), MesTitle, MB_OK);
                  with ParamRec do
                  begin
                    pmSect := 10;
                    pmNumber := J;
                    StrPLCopy(Key1.pkIdent, 'CashCode'+FillZeros(J, 3),
                      SizeOf(Key1.pkIdent)-1);
                    pmIdent := Key1.pkIdent;
                    StrPLCopy(pmName, S2, SizeOf(pmName)-1);
                    pmType := ftString;
                    if S='18' then
                      pmMeasure := 'Р'
                    else
                      pmMeasure := 'П';
                  end;
                  Len := SizeOf(ParamRec2);
                  Res := B.GetEqual(ParamRec2, Len, Key1, 1);
                  Len := SizeOf(ParamRec);
                  if Res=0 then
                  begin
                    Res := B.Update(ParamRec, Len, Key1, 1);
                    if Res<>0 then
                      ProtoMes(plErr, 'Update  BtrErr='+IntToStr(Res)+' J='+IntToStr(J));
                  end
                  else begin
                    if Res=4 then
                    begin
                      Res := B.Insert(ParamRec, Len, Key1, 1);
                      if Res<>0 then
                        ProtoMes(plErr, 'Insert  BtrErr='+IntToStr(Res)+' J='+IntToStr(J));
                    end
                    else
                      ProtoMes(plErr, 'GetEq  BtrErr='+IntToStr(Res)+' J='+IntToStr(J));
                  end;
                  if Res=0 then
                    Inc(N);
                end;
              end;
            end;
          end;
        end;
        Res := B.Close;
        Result := True;
        ProtoMes(plInfo, 'Перенесено записей '+IntToStr(N));
      end
      else
        ProtoMes(plErr, 'Не удалось открыть базу '+FN2);
    finally
      B.Free;
    end;
    CloseFile(F);
  end
  else
    ProtoMes(plErr, 'Не удалось открыть список '+FN1);
end;

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
  {NewAppName: PChar = 'BankCl.old';}
  OldMod: PChar = 'Base\module.old';
  CurMod: PChar = 'Base\module.btr';
  NewMod: PChar = 'Base\module.new';
  NewParam: PChar = 'NewKas25.txt';
  RegFile: PChar = 'Base\setup.btr';
  {NewReg: PChar = 'Base\setup.btr';}
  //NewReg0: PChar = 'Base\setup.new';
  //UpdArch: PChar = 'SfxEx25.exe';
  //UpdSdkArch: PChar = 'Sfx_Sdk.exe';
  //SrciptRun: PChar = 'VerUpd.exe VUpdEx25.run';
  {SrciptRun2: PChar = 'VerUpd.exe VUpd2521.run';}
  {ItcsMainDll: PChar = 'Tcc_Itcs.dll';
  InstallSdkCmd: PChar = 'CoInst.exe -D7 -C4';}
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
    (*
    WaitLimit := 35;
    if ParamCount>1 then
      Val(ParamStr(2), WaitLimit, Step);
    Step := 0;
    repeat
      Wnd := FindWindow('TApplication', 'Клиент-банк');
      {App := GetModuleHandle(AppName);}
      Pause(200);
      Inc(Step);
    until (Wnd=0{(App=0}) or (Step>=WaitLimit); *)
    {if Wnd=0 then
    begin}
      if AddSetupParams(NewParam, RegFile) then
      begin
        if FileExists(NewMod) then
        begin
          DeleteFile(OldMod);
          if RenameFile(CurMod, OldMod) then
          begin
            if RenameFile(NewMod, CurMod) then
            begin
              {DeleteFile(UpdArch);}
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
        MessageBox(ParentWnd, PChar('Не удалось добавить новые параметры из ['
          +NewParam+'] в ['+RegFile+']'), MesTitle, MB_OK or MB_ICONERROR);
    {end
    else
      MessageBox(ParentWnd, PChar('Программа не завершеилась ['+AppName
        +']. Обновление невозможно'), MesTitle, MB_OK or MB_ICONERROR)};
  end;
  {else
    MessageBox(ParentWnd, 'Должен быть параметр - программа обновления',
      MesTitle, MB_OK or MB_ICONERROR);}
end.
