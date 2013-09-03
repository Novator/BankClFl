library updat001;

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
  Windows,
  Utilits,
  Btrieve;

const
  MesTitle: PChar = 'Обновление версии "Банк-клиента"';

function ParentWnd: hWnd;
begin
  Result := {GetForegroundWindow}GetTopWindow(0);
end;

const
  clMaxVar = 139;
  arMaxVar = 98;

type
  TFirmName = array[0..127] of Char;
  TFirmDir = array[0..31] of Char;
  TInn = array[0..15] of char;
  TAccount = array[0..19] of char;

  PFirmRec = ^TFirmRec;           {Предприятие}
  TFirmRec = packed record
    frNumber: Integer;        { Номер                 0, 4    k0}
    frInn:   TInn;            { ИНН                   4, 16   k1}
    frKpp:   TInn;            { КПП                  20, 16}
    frName: TFirmName;        { Название             36, 128  k2}
    frAccNumber: Integer;     { Счет по умолч.      164, 4}
    frDir: TFirmDir;          { Подкаталог          168, 32}
  end;                                              {=200}

  TAccName = array[0..63] of Char;

  PFirmAccRec = ^TFirmAccRec;
  TFirmAccRec = packed record
    faNumber: Integer;        { Номер фирмы           0, 4    k0.1}
    faAcc:  TAccount;         { Счет                  4, 20   k0.2}
    faAccName: TAccName;      { Название             24, 64}
  end;                                              {=88}

  TClientName = array[0..clMaxVar-1] of Char;

  PClientRec = ^TClientRec;             {Клиент}
  TClientRec = packed record
    clAccC:  TAccount;                          {0,20     k0.1}
    clCodeB: LongInt;                           {20,4     k0.0}
    clInn:   TInn;                              {24,16    k1}
    clNameC: TClientName;       {40, 139  k2}
  end;                                             {=179}

function OpenBtrBase(var BtrBase: TBtrBase; S: string): Boolean;
var
  Res: Integer;
begin
  Result := BtrBase<>nil;
  if not Result then
  begin
    BtrBase := TBtrBase.Create;
    with BtrBase do
    begin
      Res := Open(S, baNormal);
      Result := Res=0;
    end;
  end;
end;

(*function UpdateClient(ClientBase: TBtrBase; var ClientRec: TClientRec): Boolean;
const
  MesTitle: PChar = 'Добавление клиента';
var
  I, ErrCode: Integer;
  ClientKey: packed record
    kCodeB: LongInt;                            {20,4     k0.0}
    kAccC:  TAccount;                           {0,20     k0.1}
  end;
  ClientRec2: TClientRec;
begin
  Result := False;
  if ClientBase<>nil then
  begin
    I := SizeOf(ClientRec);
    FillChar(ClientKey, SizeOf(ClientKey), #0);
    with ClientKey do
    begin
      kAccC := ClientRec.clAccC;
      kCodeB := ClientRec.clCodeB;
    end;
    ErrCode := ClientBase.GetEqual(ClientRec2, I, ClientKey, 0);
    if ErrCode=0 then
    begin
      ErrCode := ClientBase.Update(ClientRec, I, ClientKey, 0);
      if ErrCode=0 then
        Result := True
      else
        MessageBox(ParentWnd, 'Не удалось обновить клиента', MesTitle,
          MB_OK + MB_ICONERROR);
    end
    else begin
      ErrCode := ClientBase.Insert(ClientRec, I, ClientKey, 0);
      if ErrCode=0 then
        Result := True
      else
        MessageBox(ParentWnd, 'Не удалось добавить клиента', MesTitle,
          MB_OK + MB_ICONERROR);
    end;
  end
  else
    MessageBox(ParentWnd, 'База клиентов не открыта', MesTitle, MB_OK + MB_ICONERROR);
end;

function MoveFirmData(FN1, FN2, FN3: string): Boolean;
var
  FirmBase, FirmAccBase, ClientBase: TBtrBase;
  FirmRec: TFirmRec;
  FirmAccRec: TFirmAccRec;
  ClientRec: TClientRec;
  Len, Res, I: Integer;
  FAKey: packed record
    fkNumber: Integer;        { Номер фирмы           0, 4    k0.1}
    fkAcc:  TAccount;         { Счет                  4, 20   k0.2}
  end;
begin
  Result := False;
  FirmBase := nil;
  FirmAccBase := nil;
  ClientBase := nil;
  if OpenBtrBase(FirmBase, FN1) then
  begin
    if OpenBtrBase(FirmAccBase, FN2) then
    begin
      if OpenBtrBase(ClientBase, FN3) then
      begin
        Result := True;
        Len := SizeOf(FirmRec);
        Res := FirmBase.GetFirst(FirmRec, Len, I, 0);
        while Res=0 do
        begin
          Len := SizeOf(FirmAccRec);
          FAKey.fkNumber := FirmRec.frNumber;
          FillChar(FAKey.fkAcc, SizeOf(FAKey.fkAcc), #0);
          Res := FirmAccBase.GetGE(FirmAccRec, Len, FAKey, 0);
          while (Res=0) and (FirmAccRec.faNumber=FirmRec.frNumber) do
          begin
            if StrLen(FirmAccRec.faAcc)>0 then
            begin
              with ClientRec do
              begin
                clAccC := FirmAccRec.faAcc;
                clCodeB := 045744803;
                clInn := FirmRec.frInn;
                if StrLen(FirmRec.frKpp)>0 then
                begin
                  clNameC := 'КПП ';
                  StrLCopy(@clNameC[4], FirmRec.frKpp, SizeOf(FirmRec.frKpp));
                  Len := StrLen(clNameC);
                  StrLCopy(@clNameC[Len], #13#10, 2);
                  Len := StrLen(clNameC);
                end
                else
                  Len := 0;
                StrPLCopy(@clNameC[Len], FirmRec.frName, SizeOf(clNameC)-Len-1);
                WinToDosL(clNameC, SizeOf(clNameC));
              end;
              UpdateClient(ClientBase, ClientRec);
            end;
            Len := SizeOf(FirmAccRec);
            Res := FirmAccBase.GetNext(FirmAccRec, Len, FAKey, 0);
          end;
          Len := SizeOf(FirmRec);
          Res := FirmBase.GetNext(FirmRec, Len, I, 0);
        end;
        ClientBase.Close;
      end
      else
        messagebox(parentwnd, PChar(FN3), '', 0);
      ClientBase.Free;
      FirmAccBase.Close;
    end
    else
      messagebox(parentwnd, PChar(FN2), '', 0);
    FirmAccBase.Free;
    FirmBase.Close;
  end
  else
    messagebox(parentwnd, PChar(FN3), '', 0);
  FirmBase.Free;
end; *)

type
  TUserName = array[0..63] of Char;
  TUserLogin = array[0..11] of Char;

  PUserRec = ^TUserRec;               {Пользователь}
  TUserRec = packed record
    urNumber: Integer;         {Номер}                 {0, 4  k0}
    urLevel: Byte;             {Уровень привелегий}    {4, 1}
    urFirmNumber: Integer;     {Фирма по умолчанию}    {5, 4}
    urName: TUserName;         {ФИО юзера}             {9, 64}
  end;                                                 {=73}

  TKeeperName = array[0..arMaxVar-1] of Char;

  PAccRec = ^TAccRec;             {Состояние счета}
  TAccRec = packed record
    arIder:    integer;   { Идер счета }                {0, 4  k0}
    arAccount:  TAccount;  { Номер счета}               {4, 20 k1}
    arCorr:    integer;   { Корреспондент }             {24, 4 k2}
    arVersion: integer;   { Номер версии }              {28, 4}
    arDateO:   word;      { Дата открытия }             {32, 2}
    arDateC:   word;      { Дата закрытия }             {34, 2}
    arOpts:    word;      { Признаки }                  {36, 2}
    arSumA:    Int64;      { Остаток по счету }         {38, 8}
    arSumS:    Int64;      { Начальный остаток }        {46, 8}
    arName:    TKeeperName;                 {54, 98}
  end;                                                   {=152}


function CorrectUser(FN1, FN2: string): Boolean;
var
  UserBase, AccBase: TBtrBase;
  UserRec: TUserRec;
  AccRec: TAccRec;
  Len, Res, I: Integer;
begin
  Result := False;
  UserBase := nil;
  AccBase := nil;
  if OpenBtrBase(AccBase, FN1) then
  begin
    Len := SizeOf(AccRec);
    Res := AccBase.GetFirst(AccRec, Len, I, 0);
    while (Res=0) and (AccRec.arDateC<>0) do
    begin
      Len := SizeOf(AccRec);
      Res := AccBase.GetNext(AccRec, Len, I, 0);
    end;
    AccBase.Close;
    if (Res<>0) or (AccRec.arDateC<>0) then
      AccRec.arIder := 0;
  end
  else
    messagebox(parentwnd, PChar(FN1), '', 0);
  AccBase.Free;
  if OpenBtrBase(UserBase, FN2) then
  begin
    Len := SizeOf(UserRec);
    Res := UserBase.GetFirst(UserRec, Len, I, 0);
    while (Res=0) do
    begin
      UserRec.urLevel := 1;
      UserRec.urFirmNumber := AccRec.arIder;
      Res := UserBase.Update(UserRec, Len, I, 0);
      Len := SizeOf(UserRec);
      Res := UserBase.GetNext(UserRec, Len, I, 0);
    end;
    UserBase.Close;
  end
  else
    messagebox(parentwnd, PChar(FN2), '', 0);
  UserBase.Free;
end;

function DoUpdate: Boolean;
var
  si: TStartupInfo;
  pi: TProcessInformation;
  CmdLine: array[0..1023] of Char;
  Code: dWord;
begin
  Result := False;
  FillChar(si, SizeOf(si), #0);
  with si do
  begin
    cb := SizeOf(si);
    dwFlags := STARTF_USESHOWWINDOW;
    wShowWindow := SW_SHOWDEFAULT;
  end;
  StrPLCopy(CmdLine, 'VerUpd VerUpd1.log', SizeOf(CmdLine));
  if CreateProcess(nil, CmdLine, nil, nil, FALSE,
    {CREATE_NEW_CONSOLE}DETACHED_PROCESS, nil, nil, si, pi) then
  begin
    WaitforSingleObject(pi.hProcess, INFINITE);
    GetExitCodeProcess(pi.hProcess, Code);
    Result := Code=0;
    if Result then
    begin
      {MoveFirmData('Update2\Old\Base\firm.btr', 'Update2\Old\Base\firmacc.btr',
        'Base\client.btr');}
      CorrectUser('Base\acc.btr', 'Base\user.btr');
    end;
  end
  else
    MessageBox(ParentWnd, PChar('Не удалось запустить программу обновления обновления'
      +#13#10+CmdLine), MesTitle, MB_OK or MB_ICONERROR);
  if not Result then
    Result := MessageBox(ParentWnd, 'Возникли ошибки при обновлении'#13#10
      +'Попытаться провести обновление в следующий раз?',
      MesTitle, MB_YESNOCANCEL + MB_ICONWARNING) <> ID_YES;
end;

exports
  DoUpdate;

begin
end.

