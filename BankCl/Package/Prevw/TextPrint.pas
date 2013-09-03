unit TextPrint;

interface
             
uses
  Classes, WinTypes, WinProcs, SysUtils, Db, Dialogs, Utilits;

type
  TTextPrintManager = class(TComponent)
  private
    FNumberOfBytesWritten: DWORD;
    FHandle: THandle;
    FPrinterOpen: Boolean;
    FErrorString: PChar;
    FCommands, FParams, FSetStrings: TStringList;
    FDataSet: TDataSet;
    FLeftMarg: Integer;
    procedure SetErrorString;
  protected
    function DecodeTag(CS: string; ManageLevel: Byte): string;
    procedure PrintFileOrList(var F: TextFile; AList: TStringList);
  public
    property NumberOfBytesWritten: DWORD read FNumberOfBytesWritten;
    property Commands: TStringList read FCommands;
    property Params: TStringList read FParams;
    property SetStrings: TStringList read FSetStrings;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function InitPort(APort: PChar; ToEnd: Boolean): Boolean;
    procedure DonePort;
    procedure Send(const Str: string);
    procedure SendLn(const Str: string);
    function LoadCommands(FN: TFileName): Boolean;
    function PrintForm(FN: TFileName; DS: TDataSet; LeftMarg: Integer;
      FormFeed: Boolean): Boolean;
    function GetCommand(Index: Integer): string;
    function InitParam(N: string): Boolean;
    function GetParam(AMask: string; Len: Integer; OneLine: Boolean; Align: Byte): string;
  end;

implementation

const
  pcInit         = 0;
  pcPica         = 1;
  pcElite        = 2;
  pcCondensed    = 3;
  pcUnderlineOn  = 4;
  pcUnderlineOff = 5;
  pcBoldOn       = 6;
  pcBoldOff      = 7;
  pcItalicOn     = 8;
  pcItalicOff    = 9;

constructor TTextPrintManager.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCommands := TStringList.Create;
  FParams := TStringList.Create;
  FSetStrings := TStringList.Create;
end;

destructor TTextPrintManager.Destroy;
begin
  DonePort;
  FSetStrings.Free;
  FParams.Free;
  FCommands.Free;
  inherited Destroy;
end;

function TTextPrintManager.InitPort(APort: PChar; ToEnd: Boolean): Boolean;
var
  DesiredAccess, ShareMode, CreationDistribution: DWORD;
begin
  DonePort;
  DesiredAccess := {GENERIC_READ or} GENERIC_WRITE;
  ShareMode := {FILE_SHARE_READ or} FILE_SHARE_WRITE;
  CreationDistribution := {OPEN_EXISTING CREATE_NEW} OPEN_ALWAYS;
  FHandle := CreateFile(APort, DesiredAccess, ShareMode, nil,
    CreationDistribution, 0, 0);
  Result := FHandle <> INVALID_HANDLE_VALUE;
  if not Result then
  begin
    SetErrorString;
    raise Exception.Create('Ошибка открытия порта принтера'+#13#10
      +FErrorString+#13#10+APort);
  end
  else begin
    FPrinterOpen := True;
    if ToEnd then
      SetFilePointer(FHandle, 0, nil, FILE_END);
  end;
end;

procedure TTextPrintManager.SetErrorString;
begin
  if FErrorString <> nil then
    LocalFree(Integer(FErrorString));
  FormatMessage(FORMAT_MESSAGE_ALLOCATE_BUFFER or FORMAT_MESSAGE_FROM_SYSTEM,
    nil, GetLastError(), LANG_USER_DEFAULT, @FErrorString, 0, nil);
end;

function TTextPrintManager.GetCommand(Index: Integer): string;
begin
  if (Index>=0) and (Index<Commands.Count) then
    Result := Commands[Index]
  else
    Result := '';
end;

procedure TTextPrintManager.Send(const Str: string);
var
  OEMStr: PChar;
  NumberOfBytesToWrite: DWord;
begin
  if not FPrinterOpen then
    Exit;
  NumberOfBytesToWrite := Length(Str);
  OEMStr := PChar(LocalAlloc(LMEM_FIXED, NumberOfBytesToWrite + 1));
  try
    {CharToOem(PChar(Str), OEMStr);}
    StrPCopy(OEMStr, Str);
    if not WriteFile(FHandle, OEMStr^, NumberOfBytesToWrite,
      FNumberOfBytesWritten, nil) then
    begin
      SetErrorString;
      raise Exception.Create(FErrorString);
    end;
  finally
    LocalFree(Integer(OEMStr));
  end;
end;

procedure TTextPrintManager.SendLn(const Str: string);
begin
  Send(Str);
  Send(#13#10);
end;

procedure TTextPrintManager.DonePort;
begin
  CloseHandle(FHandle);
  if FErrorString <> nil then
    LocalFree(Integer(FErrorString));
end;

function TTextPrintManager.LoadCommands(FN: TFileName): Boolean;
var
  F: TextFile;
  S: string;
begin
  AssignFile(F, FN);
  FileMode := 0;
  {$I-} Reset(F); {$I+}
  Result := IOResult=0;
  if Result then
  begin
    Commands.Clear;
    while not Eof(F) do
    begin
      ReadLn(F, S);
      if (Length(S)>0) and (S[1]<>';') then
        Commands.Add(S);
    end;
    CloseFile(F);
  end;
end;

const
  ComCount = 7;
  ComNames: array[1..ComCount] of PChar =
    ('K', 'V', 'F', 'B', 'S', 'L', 'LM');

function GetCommandIndex(C: string): Integer;
begin
  C := UpperCase(C);
  Result := 1;
  while (Result<=ComCount) and (StrComp(PChar(C), ComNames[Result])<>0) do
    Inc(Result);
  if Result>ComCount then
    Result := -1;
end;

function TTextPrintManager.InitParam(N: string): Boolean;
const
  MesTitle: PChar = 'Инициализация параметра';
var
  T: array[0..1023] of Char;
begin
  Result := FDataSet=nil;
  if Result then
    MessageBox(ParentWnd, 'База не указана', MesTitle, MB_OK or MB_ICONERROR)
  else begin
    StrPLCopy(T, DecodeFieldMask(FDataSet, N), SizeOf(T));
    WinToDos(T);
    Params.Add(N + '=' + T);
  end;
end;

function TTextPrintManager.GetParam(AMask: string; Len: Integer; OneLine: Boolean;
  Align: Byte): string;

  function GetParamLoc(N: string): string;
  var
    I, J, K, L: Integer;
    S: string;
  begin
    I := Params.IndexOfName(N);
    if I>=0 then
    begin
      Result := Params.Strings[I];
      K := Pos('=', Result);
      if K>0 then
        Delete(Result, 1, K);
      if OneLine then
      begin
        S := '';
        J := Length(Result);
        K := 1;          {разбиение по CR или перенос}
        while (K<=J) and ((Len<=0) or (K<=Len)) and (Result[K]<>#13)
          and (Result[K]<>#10) do Inc(K);
        if K<=J then
        begin   {нужно отрзать начальный кусок строки}
          if (Len>0) and (K>Len) then  {найдем пробел, если нету - режем по слову}
          begin
            while (K>0) and (Result[K]<>' ') and (Result[K]<>#13)
              and (Result[K]<>#10) and (Result[K]<>'.')
              and (Result[K]<>',') and (Result[K]<>';')
                do Dec(K);
            if K<=0 then
              K := Len;
          end;
          L := K+1;
          while (L<=J) and ((Result[L]=' ') or (Result[L]=#13) or (Result[L]=#10))
            do Inc(L);
          S := S + Copy(Result, L, Length(Result)-L+1);
          while (K>0) and ((Result[K]=' ') or (Result[K]=#13) or (Result[K]=#10))
            do Dec(K);
          Result := Copy(Result, 1, K);
        end;
        if Length(S)>0 then
          Params.Strings[I] := N + '=' + S
        else
          Params.Delete(I);
      end
      else
        Params.Delete(I);
    end
    else begin
      {MessageBox(ParentWnd, PChar('Параметр не инициализирован ['+N+']'),
        'Взятие параметра', MB_OK or MB_ICONERROR);}
      Result := '';
    end;
  end;

var
  V: string;
  I, J, ErrCode: Integer;
  AField: TField;
begin
  Result:='';
  repeat
    I := Pos('+',AMask);
    if I>0 then
    begin
      V := Copy(AMask,1,I-1);
      Delete(AMask,1,I)
    end
    else begin
      V := AMask;
      AMask := ''
    end;
    I := 0;
    while (I<Length(V)) and (V[I+1]=' ') do Inc(I);
    if I>0 then
      Delete(V,1,I);
    I := Length(V);
    while (I>1) and (V[I]=' ') do Dec(I);
    V := Copy(V,1,I);
    if (V[1]='"') or (V[1]='''') or (V[1]='[') then
    begin
      if V[1]='[' then I:=1
      else I:=0;
      V := Copy(V,2,Length(V)-2);
    end
    else begin
      I := 2;
      V := GetParamLoc(V);
    end;
    Result := Result + V;
  until Length(AMask)<=0;

  if Len>0 then    {выравнивание}
  begin
    I := Length(Result);
    if I<Len then
    begin
      I := Len-I;
      case Align of
        1:
          for J := 1 to I do
            Result := ' '+Result;
        2:
          begin
            Len := I div 2;
            for J := 1 to Len do
              Result := ' '+Result;
            Dec(I, Len);
            for J := 1 to I do
              Result := Result+' ';
          end;
        else
          for J := 1 to I do
            Result := Result+' ';
      end;
    end
    else
      if I>Len then
        Result := Copy(Result, 1, Len);
  end;
end;

function TTextPrintManager.DecodeTag(CS: string; ManageLevel: Byte): string;
const
  MesTitle: PChar = 'Расшифровка команд';
var
  F: TextFile;
  I,J,Err: Integer;
  C,P: string;
  Align: Byte;
begin
  Result := '';
  while Length(CS)>0 do
  begin
    if ManageLevel<=0 then
      I := Pos(';', CS)
    else
      I := 0;
    if I>0 then
    begin
      C := Copy(CS, 1, I-1);
      System.Delete(CS, 1, I);
    end
    else begin
      C := CS;
      CS := ''
    end;
    I := Pos(':', C);
    if I>0 then
    begin
      P := Copy(C, I+1, Length(C)-I);
      C := Copy(C, 1, I-1);
    end
    else
      P := '';
    C := TruncStr(C);
    I := GetCommandIndex(C);
    case I of
      1: {K - команда}
        begin
          Val(P, J, Err);
          if Err=0 then
            Result := Result + GetCommand(J)
          else begin
            MessageBox(ParentWnd, PChar('Параметр команды K должен быть числом ['+P+']'),
              MesTitle, MB_OK or MB_ICONERROR);
            Result := Result + C;
          end;
        end;
      2: {V - взятие параметра из базы}
        InitParam(P);
      3: {F - заполнение поля формы}
        begin
          if Length(P)>0 then
          begin
            Align := 0;
            J := Pos('#', P);
            if J>0 then
            begin
              C := Copy(P, J+1, Length(P)-J);
              P := Copy(P, 1, J-1);
              if Length(C)>0 then
              begin
                if (C[1]<'0') or (C[1]>'9') then
                begin
                  case C[1] of
                    'R': Align := 1;
                    'C': Align := 2;
                  end;
                  Delete(C, 1, 1);
                end;
                Val(C, J, Err);
                if Err<>0 then
                  J := 0
              end
              else
                J := 0;
            end;
            if P[1]='@' then
              Result := Result + GetParam(Copy(P, 2, Length(P)-1), J, True, Align)
            else
              Result := Result + GetParam(P, J, False, Align);
          end;
        end;
      4: {B - отображение символов}
        begin
          Val(P, J, Err);
          if Err=0 then
            Result := Result + Chr(J)
          else begin
            MessageBox(ParentWnd, PChar('Параметр команды B должен быть числом ['
              +P+']'), MesTitle, MB_OK or MB_ICONERROR);
            Result := Result + C;
          end;
        end;
      5: {S - установка шаблона}
        begin
          SetStrings.Clear;
          SetStrings.Add(P);
        end;
      6: {L - цикл по шаблону}
        begin
          Val(P, J, Err);
          if Err=0 then
          begin
            if FDataSet<>nil then
            begin
              with FDataSet do
              begin
                case J of
                  1: First;
                end;
                while not EoF do
                begin
                  PrintFileOrList(F, SetStrings);
                  Next;
                end;
              end;
            end;
          end
          else begin
            MessageBox(ParentWnd, PChar('Параметр команды L должен быть числом ['
              +P+']'), MesTitle, MB_OK or MB_ICONERROR);
            Result := Result + C;
          end;
        end;
      7: {LM - левая граница}
        begin
          Val(P, J, Err);
          if Err=0 then
            FLeftMarg := J
          else begin
            MessageBox(ParentWnd, PChar('Параметр команды LM должен быть числом ['
              +P+']'), MesTitle, MB_OK or MB_ICONERROR);
            Result := Result + C;
          end;
        end;
      else begin
        MessageBox(ParentWnd, PChar('В форме неизвестная команда ['+C+']'),
          MesTitle, MB_OK or MB_ICONERROR);
        Result := Result + C;
      end;
    end;
  end;
end;

procedure TTextPrintManager.PrintFileOrList(var F: TextFile; AList: TStringList);
var
  EndOfList: Boolean;
  I, P: Integer;
  S, PS, CS, SS: string;
  ManageLevel: Byte;
  Manage: Boolean;
begin
  CS := '';
  PS := '';
  ManageLevel := 0;
  Manage := False;
  if AList=nil then
    EndOfList := Eof(F)
  else begin
    I := 0;
    EndOfList := I>=AList.Count;
  end;
  while not EndOfList do
  begin
    if AList=nil then
      ReadLn(F, S)
    else
      S := AList.Strings[I];
    while Length(S)>0 do
    begin
      if Manage then
      begin
        SS := '}';
        for P := 1 to ManageLevel do
          SS := '$'+SS;
        P := Pos(SS, S);
        if P>0 then
          Inc(P, ManageLevel);
      end
      else begin
        P := Pos('{', S);
        ManageLevel := 0;
        if P>0 then
          while (P+ManageLevel<Length(S)) and (S[P+ManageLevel+1]='$') do
            Inc(ManageLevel);
      end;
      if P>0 then
      begin
        if Manage then
        begin
          CS := CS + Copy(S, 1, P-1);
          if ManageLevel>0 then
            CS := Copy(CS, ManageLevel+1, Length(CS)-2*ManageLevel);
          PS := PS + DecodeTag(CS, ManageLevel);
          CS := '';  
        end
        else
          PS := PS + Copy(S, 1, P-1);
        System.Delete(S, 1, P);
        Manage := not Manage;
      end
      else begin
        if Manage then
          CS := CS+S
        else
          PS := PS+S;
        S := '';
      end;
    end;
    if not Manage then
    begin
      for P := 1 to FLeftMarg do
        PS := ' '+PS;
      SendLn(PS);
      PS := '';
    end;
    if AList=nil then
      EndOfList := Eof(F)
    else begin
      Inc(I);
      EndOfList := I>=AList.Count;
    end;
  end;
end;

function TTextPrintManager.PrintForm(FN: TFileName; DS: TDataSet;
  LeftMarg: Integer; FormFeed: Boolean): Boolean;
var
  F: TextFile;
begin
  AssignFile(F, FN);
  FileMode := 0;
  {$I-} Reset(F); {$I+}
  Result := IOResult=0;
  if Result then
  begin
    try
      Params.Clear;
      FLeftMarg := LeftMarg;
      FDataSet := DS;
      PrintFileOrList(F, nil);
      if FormFeed then
        Send(#12);
    finally
      CloseFile(F);
    end;
  end;
end;

end.
