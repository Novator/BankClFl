library updat005;

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

  POldClientRec = ^TOldClientRec;             {Клиент}
  TOldClientRec = packed record
    clAccC:  TAccount;                          {0,20     k0.1}
    clCodeB: LongInt;                           {20,4     k0.0}
    clInn:   TInn;                              {24,16    k1}
    clNameC: TClientName;       {40, 139  k2}
  end;                                             {=179}

  PNewClientRec = ^TNewClientRec;             {Клиент}
  TNewClientRec = packed record
    clAccC:  TAccount;                          {0,20     k0.1}
    clCodeB: LongInt;                           {20,4     k0.0}
    clInn:   TInn;                              {24,16    k1}
    clKpp:   TInn;                              {40,16      }
    clNameC: TClientName;       {56, 139  k2}
  end;                                             {=195}

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

const
  DosKpp: PChar = #$8A#$8F#$8F;

function UpdateClient(ClientBase: TBtrBase; Acc: string; Bik: Integer; Name, Inn, Kpp: string;
  DosCharset, UpdateKpp: Boolean): Boolean;
const
  MesTitle: PChar = 'Добавление клиента';
var
  Len, Res, I: Integer;
  ClientKey: packed record
    kCodeB: LongInt;                            {20,4     k0.0}
    kAccC:  TAccount;                           {0,20     k0.1}
  end;
  ClientRec, ClientRec2: TNewClientRec;
  NameKpp: string;
begin
  Result := False;
  FillChar(ClientRec, SizeOf(ClientRec), #0);
  with ClientRec do
  begin
    StrPLCopy(clAccC, Acc, SizeOf(clAccC));
    clCodeB := Bik;
    StrPLCopy(clInn, Inn, SizeOf(clInn));
    StrPLCopy(clKpp, Kpp, SizeOf(clInn));
    Name := Trim(Name);
    StrPLCopy(clNameC, Name, SizeOf(clNameC));
    if not DosCharset then
      WinToDos(clNameC);
    Name := StrPas(clNameC);
    I := Pos(DosKpp, Name);
    if I=1 then
    begin
      System.Delete(Name, 1, 3);
      Name := Trim(Name);
      Len := Length(Name);
      I := 0;
      while (I<Len) and (Name[I+1] in ['0'..'9']) do
        Inc(I);
      if I>0 then
      begin
        NameKpp := Copy(Name, 1, I);
        Delete(Name, 1, I);
        Name := Trim(Name);
      end
      else
        NameKpp := '';
      StrPLCopy(clNameC, Name, SizeOf(clNameC)-1);
    end
    else
      NameKpp := '';
  end;
  if ClientBase<>nil then
  begin
    Len := SizeOf(ClientRec);
    FillChar(ClientKey, SizeOf(ClientKey), #0);
    with ClientKey do
    begin
      kAccC := ClientRec.clAccC;
      kCodeB := ClientRec.clCodeB;
    end;
    if (StrLen(ClientRec.clKpp)=0) and (Length(NameKpp)>0) then
      StrPLCopy(ClientRec.clKpp, NameKpp, SizeOf(ClientRec.clKpp)-1);
    Res := ClientBase.GetEqual(ClientRec2, Len, ClientKey, 0);
    if Res=0 then
    begin
      if not UpdateKpp and (StrLen(ClientRec.clKpp)=0) then
        ClientRec.clKpp := ClientRec2.clKpp;
      Res := ClientBase.Update(ClientRec, Len, ClientKey, 0);
      if Res=0 then
        Result := True
      else
        MessageBox(ParentWnd, PChar('Не удалось обновить клиента BtrErr='
          +IntToStr(Res)), MesTitle, MB_OK or MB_ICONERROR);
    end
    else begin
      Len := SizeOf(ClientRec);
      Res := ClientBase.Insert(ClientRec, Len, ClientKey, 0);
      if Res=0 then
        Result := True
      else
        MessageBox(ParentWnd, PChar('Не удалось добавить клиента BtrErr='
          +IntToStr(Res)), MesTitle, MB_OK or MB_ICONERROR);
    end;
  end
  else
    MessageBox(ParentWnd, 'База клиентов не открыта', MesTitle, MB_OK or MB_ICONERROR);
end;

function MoveFirmData(FFN, FAFN, OCFN, NCFN: string): Boolean;
var
  FirmBase, FirmAccBase, OldClientBase, NewClientBase: TBtrBase;
  FirmRec: TFirmRec;
  FirmAccRec: TFirmAccRec;
  Len, Res, I: Integer;
  FAKey: packed record
    fkNumber: Integer;        { Номер фирмы           0, 4    k0.1}
    fkAcc:  TAccount;         { Счет                  4, 20   k0.2}
  end;
  Acc: string;
  Bik: Integer;
  Name, Inn, Kpp: string;
  OldClientRec: TOldClientRec;
  OldCliKey: packed record
    kAccC:  TAccount;
    kCodeB: LongInt;
  end;
begin
  Result := False;
  FirmBase := nil;
  FirmAccBase := nil;
  OldClientBase := nil;
  NewClientBase := nil;
  if OpenBtrBase(NewClientBase, NCFN) then
  begin
    if OpenBtrBase(FirmBase, FFN) then
    begin
      if OpenBtrBase(FirmAccBase, FAFN) then
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
              Acc := FirmAccRec.faAcc;
              Bik := 045744803;
              Inn := FirmRec.frInn;
              Kpp := FirmRec.frKpp;
              Name := FirmRec.frName;
              UpdateClient(NewClientBase, Acc, Bik, Name, Inn, Kpp, False, True);
            end;
            Len := SizeOf(FirmAccRec);
            Res := FirmAccBase.GetNext(FirmAccRec, Len, FAKey, 0);
          end;
          Len := SizeOf(FirmRec);
          Res := FirmBase.GetNext(FirmRec, Len, I, 0);
        end;
        FirmAccBase.Close;
      end
      else
        MessageBox(ParentWnd, PChar(FAFN), 'No FirmAccBase', 0);
      FirmAccBase.Free;
      FirmBase.Close;
    end
    {else
      MessageBox(ParentWnd, PChar(FFN), 'No FirmBase', 0)};
    FirmBase.Free;
    if OpenBtrBase(OldClientBase, OCFN) then
    begin
      Result := True;
      Len := SizeOf(OldClientRec);
      Res := OldClientBase.GetFirst(OldClientRec, Len, OldCliKey, 0);
      while Res=0 do
      begin
        Acc := OldClientRec.clAccC;
        Bik := OldClientRec.clCodeB;
        Inn := OldClientRec.clInn;
        Kpp := '';
        Name := OldClientRec.clNameC;
        UpdateClient(NewClientBase, Acc, Bik, Name, Inn, Kpp, True, False);
        Len := SizeOf(OldClientRec);
        Res := OldClientBase.GetNext(OldClientRec, Len, OldCliKey, 0);
      end;
      OldClientBase.Close;
    end
    else
      MessageBox(ParentWnd, PChar(OCFN), 'No OldClientBase', 0);
    OldClientBase.Free;
    NewClientBase.Close;
  end
  else
    MessageBox(ParentWnd, PChar(NCFN), 'No NewClientBase', 0);
  NewClientBase.Free;
end;

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
    MessageBox(ParentWnd, PChar(FN1), '', 0);
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
    MessageBox(ParentWnd, PChar(FN2), '', 0);
  UserBase.Free;
end;

function DoUpdate: Boolean;
var
  {si: TStartupInfo;
  pi: TProcessInformation;}
  {CmdLine: array[0..1023] of Char;}
  {Code: dWord;}
  S: string;
begin
  Result := True;
  S := ParamStr(0);
    {messagebox(parentwnd, PChar(S), 'path', 0);}
  S := ExtractFilePath(S);
    {messagebox(parentwnd, PChar(S), 'dir', 0);}
  SetCurrentDirectory(PChar(S));{ then
    messagebox(parentwnd, 'Ura!!!', '', 0);}
  (*FillChar(si, SizeOf(si), #0);
  with si do
  begin
    cb := SizeOf(si);
    dwFlags := STARTF_USESHOWWINDOW;
    wShowWindow := SW_SHOWDEFAULT;
  end;
  StrPLCopy(CmdLine, 'VerUpd VerUpd3.log', SizeOf(CmdLine));
  if CreateProcess(nil, CmdLine, nil, nil, FALSE,
    {CREATE_NEW_CONSOLE}DETACHED_PROCESS, nil, nil, si, pi) then
  begin
    WaitforSingleObject(pi.hProcess, INFINITE);
    GetExitCodeProcess(pi.hProcess, Code);
    Result := Code=0;
    if Result then
    begin*)
      MoveFirmData('Update3\Old\Base\firm.btr', 'Update3\Old\Base\firmacc.btr',
        'Update3\Old\Base\client.btr', 'Base\clientn.btr');
      CorrectUser('Base\acc.btr', 'Base\user.btr');
  (*  end;
  end
  else
    MessageBox(ParentWnd, PChar('Не удалось запустить программу обновления обновления'
      +#13#10+CmdLine), MesTitle, MB_OK or MB_ICONERROR);*)
  {if not Result then
    Result :=} MessageBox(ParentWnd, 'Перенос справочника клиентов завершен',
      MesTitle, MB_OK or MB_ICONINFORMATION);
end;

exports
  DoUpdate;

begin
end.

