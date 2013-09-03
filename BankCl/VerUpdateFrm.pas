unit VerUpdateFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Controls, StdCtrls, Buttons,
    ExtCtrls, ComCtrls, Forms, Graphics, Db, {ShlObj;}Btrieve, Utilits;

const
  CommonUserNumber = 0;

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
      pmBuffer: PChar;         {                         170, (max)}
    );
  end;                                                   {=(200)}

  PParamOldRec = ^TParamOldRec;            {Устаревший параметр реестра}
  TParamOldRec = packed record
    pmSect:   Word;           { Секция                   0, 2      k0.1}
    pmNumber: Longint;        { Номер параметра          2, 4      k0.2}
    pmIdent:  TParamIdent;    { Идентефикатор            6, 12     k1}
    pmName:   TParamName;     { Название                 18, 128}
    pmMeasure: TParamMeasure; { ЕИ                       146, 20}
    pmLevel:  Byte;           { Уровень                  166, 1}
    case pmType: TFieldType of   { Тип параметра         167, 1 = 168}
    ftString: (
      pmStrValue: TStrValue;   { Значение                168, (236)}
    );
    ftInteger: (
      pmIntValue: Integer;     {                         168, 4}
      pmMinIntValue: Integer;  {                         172, 4}
      pmMaxIntValue: Integer;  {                         176, 4}
      pmDefIntValue: Integer;  {                         180, 4}
    );
    ftBoolean: (
      pmBoolValue: Boolean;    {                         168, 4}
      pmDefBoolValue: Boolean; {                         172, 4}
    );
    ftFloat: (
      pmFltValue: Double;      {                         168, 8}
      pmMinFltValue: Double;   {                         176, 8}
      pmMaxFltValue: Double;   {                         184, 8}
      pmDefFltValue: Double;   {                         192, 8}
    );
    ftDate: (
      pmDateValue: Word;       {                         168, 2}
      pmDefDateValue: Word;    {                         170, 2}
    );
    ftUnknown: (
      pmBuffer: PChar;         {                         168, (max)}
    );
  end;                                                   {=(200)}

  TParamKey0 =
    packed record
      pkSect: Word;
      pkNumber: Integer;
      pkUser: Word;
    end;

  TParamKey1 =
    packed record
      pkIdent: TParamIdent;
      pkUser: Word;
    end;

  PSanctionRec = ^TSanctionRec;      {Санкция}
  TSanctionRec = packed record
    snUserNumber: Integer;        {0, 4   k0.1}
    snSancNumber: Integer;        {8, 4   k0.2}
  end;                            {=12}

  TUserName = array[0..63] of Char;

  PUserRec = ^TUserRec;               {Пользователь}
  TUserRec = packed record
    urNumber: Integer;         {Номер}                 {0, 4  k0}
    urLevel: Byte;             {Уровень привелегий}    {4, 1}
    urFirmNumber: Integer;     {Фирма по умолчанию}    {5, 4}
    urName: TUserName;         {ФИО юзера}             {9, 64}
  end;                                                 {=73}

type
  TVerUpdateForm = class(TForm)
    TopBevel: TBevel;
    TopPanel: TPanel;
    TitleLabel: TLabel;
    UrlLabel: TLabel;
    MesLabel: TLabel;
    TaskGroupBox: TGroupBox;
    TaskListBox: TListBox;
    OkBitBtn: TBitBtn;
    ProgressBar: TProgressBar;
    procedure TaskListBoxDrawItem(Control: TWinControl; Index: Integer;
      Rect: TRect; State: TOwnerDrawState);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure OkBitBtnClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormActivate(Sender: TObject);
  private
  public
    ScriptList: TStringList;
    procedure ShowMes(S: string);
    function ExecuteUpdate: Boolean;
    procedure AddStep(S: string);
    procedure SetCurStep(I: Integer);
  end;

var
  VerUpdateForm: TVerUpdateForm;
  Step: Byte = 0;

implementation

{$R *.DFM}

var
  Process: Boolean = False;
  LogFileName: string = '';

procedure TVerUpdateForm.TaskListBoxDrawItem(Control: TWinControl;
  Index: Integer; Rect: TRect; State: TOwnerDrawState);
var
  S: TFontStyles;
begin
  with (Control as TListBox).Canvas do
  begin
    Brush.Color := (Control as TListBox).Color;
    FillRect(Rect);
    S := Font.Style;
    if Process and (Index=(Control as TListBox).ItemIndex) then
      Include(S, fsBold)
    else
      Exclude(S, fsBold);
    Font.Color := clBlack;
    Font.Style := S;
    TextOut(Rect.Left + 17, Rect.Top, (Control as TListBox).Items[Index]);
  end;
end;

procedure TVerUpdateForm.FormCloseQuery(Sender: TObject;
  var CanClose: Boolean);
begin
  CanClose := not Process;
  if Process then
  begin
    if MessageBox(Handle,
      'Завершение обновления приведет к неправильной работе программы. Прервать?',
      PChar(Caption), MB_YESNOCANCEL or MB_ICONWARNING or MB_DEFBUTTON2) = ID_YES
    then
      Process := False;
  end;
end;

const
  ProtoIsOpen: Boolean = False;
var
  ProtoFile: TextFile;

procedure ShowProto(S: string);
begin
  if not ProtoIsOpen and (Length(LogFileName)>0) then
  begin
    AssignFile(ProtoFile, ChangeFileExt(LogFileName, '.prt'));
    {$I-} System.Append(ProtoFile); {$I+}
    ProtoIsOpen := IOResult = 0;
    if not ProtoIsOpen then
    begin
      {$I-} Rewrite(ProtoFile); {$I+}
      ProtoIsOpen := IOResult = 0;
    end;
  end;
  if ProtoIsOpen then
    WriteLn(ProtoFile, DateTimeToStr(Now)+' '+S);
end;

procedure TVerUpdateForm.ShowMes(S: string);
begin
  MesLabel.Caption := S;
  ShowProto(S);
end;

procedure TVerUpdateForm.AddStep(S: string);
begin
  TaskListBox.Items.Add(S);
end;

procedure TVerUpdateForm.SetCurStep(I: Integer);
begin
  if I<TaskListBox.Items.Count then
    TaskListBox.ItemIndex := I;
  TaskListBox.Repaint;
end;


procedure TVerUpdateForm.OkBitBtnClick(Sender: TObject);
begin
  Close;
end;

function RunAndWait(CmdLine: PChar): Boolean;
var
  si: TStartupInfo;
  pi: TProcessInformation;
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
  if CreateProcess(nil, CmdLine, nil, nil, FALSE,
    {CREATE_NEW_CONSOLE}DETACHED_PROCESS, nil, nil, si, pi) then
  begin
    {WaitforSingleObject(pi.hProcess, INFINITE);}
    while WaitforSingleObject(pi.hProcess, 200)=WAIT_TIMEOUT do
      Application.ProcessMessages;
    GetExitCodeProcess(pi.hProcess, Code);
    Result := Code=0;
  end;
end;

function GetFirstBroker(S: string): Integer;
var
  I, L: Integer;
  Skoba: Boolean;
begin
  Skoba := False;
  I := 0;
  L := Length(S);
  while (I<L) and (Skoba or (S[I+1]<>' ')) do
  begin
    Inc(I);
    if S[I]='"' then
      Skoba := not Skoba;
  end;
  Result := I;
  if I<L then
    Inc(Result);
end;

function TrimSkoba(S: string): string;
var
  L: Integer;
begin
  S := Trim(S);
  L := Length(S);
  if (L>0) and (S[1]='"') and (S[L]='"') then
    Result := Copy(S, 2, L-2)
  else
    Result := S;
end;

function OpenBtrBase(var Reg: TBtrBase; S: string; OpenMode: Byte): Boolean;
var
  Res: Integer;
begin
  Result := Reg<>nil;
  if not Result then
  begin
    Reg := TBtrBase.Create;
    with Reg do
    begin
      Res := Open(S, OpenMode);
      Result := Res=0;
      if Res<>0 then
        ShowProto('OpenBtrBase: ['+S+'] BtrErr='+IntToStr(Res));
    end;
  end;
end;

var
  OldParRec: TParamOldRec;
  NewParRec: TParamNewRec;

{function GetOldRegParamByName(Reg: TBtrBase; AName: string): Boolean;
var
  Ident: TParamIdent;
  Res, Len: Integer;
begin
  Result := False;
  if Reg<>nil then
  begin
    FillChar(Ident, SizeOf(Ident), #0);
    StrPLCopy(Ident, AName, SizeOf(Ident)-1);
    Len := SizeOf(OldParRec);
    Res := Reg.GetEqual(OldParRec, Len, Ident, 1);
    Result := Res=0;
    if Res<>0 then
      ShowProto('GetOldReg: ['+AName+'] BtrErr='+IntToStr(Res));
  end;
end;}

{function GetNewRegParamByName(Reg: TBtrBase; AName: string): Boolean;
var
  Res, Len: Integer;
  ParamKey: TParamKey1;
begin
  Result := False;
  if Reg<>nil then
  begin
    FillChar(ParamKey, SizeOf(ParamKey), #0);
    StrPLCopy(ParamKey.pkIdent, AName, SizeOf(ParamKey.pkIdent)-1);
    ParamKey.pkUser := CommonUserNumber;
    Len := SizeOf(NewParRec);
    Res := Reg.GetEqual(NewParRec, Len, ParamKey, 1);
    Result := Res=0;
    if Res<>0 then
      ShowProto('GetNewReg: ['+AName+'] BtrErr='+IntToStr(Res));
  end;
end;}

function GetParamDataLen(AType: TFieldType; ABuf: PChar): Integer;
begin
  Result := 0;
  case AType of
    ftString: Result := StrLen(ABuf)+1 + StrLen(@ABuf[StrLen(ABuf)+1])+1;
    ftInteger: Result := 16;
    ftBoolean: Result := 8;
    ftFloat: Result := 32;
    ftDate: Result := 4;
  end;
end;

function GetParamLen(const ParamRec: TParamNewRec): Integer;
begin
  Result := SizeOf(ParamRec)-SizeOf(TStrValue);
  Result := Result + GetParamDataLen(ParamRec.pmType, @ParamRec.pmBuffer);
end;

function MoveParamValue(AType: TFieldType; var OldValue, AValue): Boolean;
var
  L: Integer;
  P1, P2: PChar;
  DV: TStrValue;
begin
  Result := True;
  case AType of
    ftString:
      begin
        P1 := @OldValue;
        P2 := @AValue;
        L := StrLen(P2)+1;
        StrLCopy(DV, @P2[L], SizeOf(TStrValue)-1);
        StrLCopy(P2, P1, SizeOf(TStrValue));
        L := StrLen(P2)+1;
        StrLCopy(@P2[L], DV, SizeOf(TStrValue)-L);
      end;
    ftInteger:
      Integer(AValue) := Integer(OldValue);
    ftBoolean:
      Boolean(AValue) := Boolean(OldValue);
    ftFloat:
      Double(AValue) := Double(OldValue);
    ftDate:
      Word(AValue) := Word(OldValue);
    else
      Result := False;
  end;
end;

function MoveRegParamsByName(Reg1, Reg2: TBtrBase;
  AName: string; Old: Boolean): Boolean;
var
  ParamKey11, ParamKey12: TParamKey1;
  Res, Len: Integer;
  NewParamRec: TParamNewRec;
  Ident: TParamIdent;
begin
  Result := False;
  if Reg1<>nil then
  begin
    if Old then
    begin
      FillChar(Ident, SizeOf(Ident), #0);
      StrPLCopy(Ident, AName, SizeOf(Ident)-1);
      Len := SizeOf(OldParRec);
      Res := Reg1.GetEqual(OldParRec, Len, Ident, 1);
      if Res<>0 then
        ShowProto('GetOldReg: ['+AName+'] BtrErr='+IntToStr(Res));
    end
    else
      Res := 0;
    if Res=0 then
    begin
      if Reg2<>nil then
      begin
        FillChar(ParamKey11, SizeOf(ParamKey11), #0);
        StrPLCopy(ParamKey11.pkIdent, AName, SizeOf(ParamKey11.pkIdent)-1);
        ParamKey11.pkUser := 0;
        Len := SizeOf(NewParamRec);
        Res := Reg2.GetGE(NewParamRec, Len, ParamKey11, 1);
        while (Res=0) and (UpperCase(NewParamRec.pmIdent)=UpperCase(AName)) do
        begin
          if Old then
          begin
            if OldParRec.pmType=NewParamRec.pmType then
            begin
              if MoveParamValue(NewParamRec.pmType, OldParRec.pmBuffer,
                NewParamRec.pmBuffer) then
              begin
                Len := GetParamLen(NewParamRec);
                Res := Reg2.Update(NewParamRec, Len, ParamKey11, 1);
                Result := Res=0;
                if Res=0 then
                  Result := True
                else
                  ShowProto('UpdOldReg: ['+AName+'] BtrErr='+IntToStr(Res));
              end;
            end
            else
              ShowProto('SetOldReg: ['+AName+'] Differ types '
                +IntToStr(Ord(OldParRec.pmType))+'<>'+IntToStr(Ord(NewParamRec.pmType)));
          end
          else begin
            ParamKey12 := ParamKey11;
            Len := SizeOf(NewParRec);
            Res := Reg1.GetEqual(NewParRec, Len, ParamKey12, 1);
            if Res<>0 then
            begin
              ShowProto('GetNewReg NoEqual: ['+AName+'] BtrErr='+IntToStr(Res));
              ParamKey12.pkUser := CommonUserNumber;
              Len := SizeOf(NewParRec);
              Res := Reg1.GetEqual(NewParRec, Len, ParamKey12, 1);
              if Res<>0 then
                ShowProto('GetNewReg NoCommon: ['+AName+'] BtrErr='+IntToStr(Res));
            end;
            if Res=0 then
            begin
              if NewParRec.pmType=NewParamRec.pmType then
              begin
                if MoveParamValue(NewParamRec.pmType, NewParRec.pmBuffer,
                  NewParamRec.pmBuffer) then
                begin
                  Len := GetParamLen(NewParamRec);
                  Res := Reg2.Update(NewParamRec, Len, ParamKey11, 1);
                  Result := Res=0;
                  if Res=0 then
                    Result := True
                  else
                    ShowProto('UpdNewReg: ['+AName+'] BtrErr='+IntToStr(Res));
                end;
              end
              else
                ShowProto('SetNewReg: ['+AName+'] Differ types'
                  +IntToStr(Ord(NewParRec.pmType))+'<>'+IntToStr(Ord(NewParamRec.pmType)));
            end;
          end;
          Inc(ParamKey11.pkUser);
          Len := SizeOf(NewParamRec);
          Res := Reg2.GetGE(NewParamRec, Len, ParamKey11, 1);
        end;
      end;
    end;
  end;
end;

{procedure SaveRegToFile(Reg: TBtrBase);
var
  Res, Len: Integer;
  Ident: array[0..SizeOf(TParamIdent)] of Char;
  S: string;
begin
  Len := SizeOf(TParamRec);
  Res := Reg.GetFirst(ParamRec, Len, Ident, 1);
  while Res=0 do
  begin
    StrLCopy(Ident, ParamRec.pmIdent, SizeOf(Ident)-1);
    S := StrPas(Ident) + '   ;'+StrPas(ParamRec.pmName);
    ShowProto(S);
    Len := SizeOf(TParamRec);
    Res := Reg.GetNext(ParamRec, Len, Ident, 1);
  end;
end;}

var
  Reg1: TBtrBase = nil;
  Reg2: TBtrBase = nil;

{function MoveOldReg(S: string): Boolean;
begin
  Result := False;
  if GetOldRegParamByName(Reg1, S) then
    Result := SetRegParamByName(Reg2, S, True);
end;

function MoveNewReg(S: string): Boolean;
begin
  Result := False;
  if GetNewRegParamByName(Reg1, S) then
    Result := SetRegParamByName(Reg2, S, False);
end;}

var
  SancBase: TBtrBase = nil;
  UserBase: TBtrBase = nil;

function CorrSanc(SancN, DelSanc: Integer): Boolean;
var
  Res, Len, I: Integer;
  SanctRec, SanctKey: TSanctionRec;
  UserRec: TUserRec;
begin
  Result := False;
  if (SancBase<>nil) and (UserBase<>nil) then
  begin
    Len := SizeOf(UserRec);
    Res := UserBase.GetFirst(UserRec, Len, I, 0);
    if DelSanc=0 then
    begin
      while Res=0 do
      begin
        if UserRec.urLevel<=1 then
        begin
          SanctRec.snUserNumber := UserRec.urNumber;
          SanctRec.snSancNumber := SancN;
          SanctKey := SanctRec;
          Len := SizeOf(SanctRec);
          Res := SancBase.Insert(SanctRec, Len, SanctKey, 0);
          if Res=0 then
            Result := True
          else
            ShowProto('AddSanc: ['+IntToStr(SancN)+'] ('
              +IntToStr(SanctRec.snUserNumber)+') BtrErr='+IntToStr(Res));
        end;
        Len := SizeOf(UserRec);
        Res := UserBase.GetNext(UserRec, Len, I, 0);
      end;
    end
    else begin
      while Res=0 do
      begin
        SanctKey.snUserNumber := UserRec.urNumber;
        SanctKey.snSancNumber := SancN;
        Len := SizeOf(SanctRec);
        Res := SancBase.GetEqual(SanctRec, Len, SanctKey, 0);
        if Res=0 then
        begin
          Res := SancBase.Delete(0);
          if Res=0 then
            Result := True
          else
            ShowProto('DelSanc: ['+IntToStr(SancN)+'] ('
              +IntToStr(SanctKey.snUserNumber)+') BtrErr='+IntToStr(Res));
        end
        else
          ShowProto('GetSanc: ['+IntToStr(SancN)+'] ('
            +IntToStr(SanctKey.snUserNumber)+') BtrErr='+IntToStr(Res));
        Len := SizeOf(UserRec);
        Res := UserBase.GetNext(UserRec, Len, I, 0);
      end;
    end;
  end;
end;

(*
procedure TAdminForm.SancItemClick(Sender: TObject);
const
  MesTitle: PChar = 'Санкции';
var
  SanctDataSet: TBtrDataSet;
  UserRec: TUserRec;
  SanctRec: TSanctionRec;
  N, I: Integer;
begin
  if not DataSource.DataSet.IsEmpty then
  begin
    SanctForm := TSanctForm.Create(Self);
    with SanctForm do
    begin
      SanctDataSet := GlobalBase(biSanction);
      if SanctDataSet<>nil then
      begin
        with SanctDataSet do
        begin
          TUserDataSet(Self.DataSource.DataSet).GetBtrRecord(PChar(@UserRec));
          if AccessToUser(UserRec.urLevel) then
          begin
            N := UserRec.urNumber;
            with SanctRec do
            begin
              snUserNumber := N;
              snSancNumber := 0;
            end;
            if LocateBtrRecordByIndex(SanctRec, 0, bsGe) then
            begin
              GetBtrRecord(@SanctRec);
              while not Eof and (SanctRec.snUserNumber=N) do
              begin
                I := SanctRec.snSancNumber;
                I := CheckListBox.Items.IndexOfObject(TObject(I));
                if (I>=0) and (I<CheckListBox.Items.Count) then
                  CheckListBox.Checked[I] := True;
                Next;
                GetBtrRecord(@SanctRec);
              end;
            end;
            UserEdit.Text := StrPas(UserRec.urName);
            if ShowModal=mrOk then
            begin
              if DeleteUserSanct(N) then
                for I:=1 to CheckListBox.Items.Count do
                begin
                  if CheckListBox.Checked[I-1] then
                  begin
                    with SanctRec do
                    begin
                      snUserNumber := N;
                      snSancNumber := Integer(CheckListBox.Items.Objects[I-1]);
                    end;
                    AddBtrRecord(@SanctRec, SizeOf(SanctRec));
                  end;
                end
              else
                MessageBox(Handle, 'Не удалось удалить привеллегии полльзователя',
                  MesTitle, MB_OK or MB_ICONERROR);
            end;
          end
          else
            MessageBox(Handle, 'Вы не можете администрировать этого пользователя',
              MesTitle, MB_OK or MB_ICONWARNING);
        end;
      end
      else
        MessageBox(Handle, 'База санкций не открыта', MesTitle,
          MB_OK or MB_ICONERROR);
      Free;
    end;
  end;
end;

function DeleteUserSanct(UserNumber: Integer): Boolean;
var
  SanctDataSet: TBtrDataSet;
  SanctRec: TSanctionRec;
begin
  SanctDataSet := GlobalBase(biSanction);
  Result := SanctDataSet<>nil;
  if Result then
  begin
    with SanctDataSet do
    begin
      with SanctRec do
      begin
        snUserNumber := UserNumber;
        snSancNumber := 0;
      end;
      First;
      if not Eof and LocateBtrRecordByIndex(SanctRec, 0, bsGe) then
      begin
        GetBtrRecord(@SanctRec);
        while not Eof and (SanctRec.snUserNumber=UserNumber) do
        begin
          Delete;
          GetBtrRecord(@SanctRec);
        end;
      end;
      Result := True;
    end;
  end;
end;


*)

procedure CloseReg(var Reg: TBtrBase);
begin
  if Reg<>nil then
  begin
    Reg.Close;
    Reg.Free;
    Reg := nil;
  end;
end;

procedure DelDirContent(Path: string);
var
  FileInfo: TSearchRec;
  Res: Integer;
begin
  Res := Length(Path);
  if (Res=0) or (Path[Res]<>'\') then
    Path := Path + '\';
  Res := FindFirst(Path+'*.*', faAnyFile, FileInfo);
  while Res=0 do
  begin
    if (FileInfo.Name<>'.') and (FileInfo.Name<>'..')
      and (FileInfo.Attr<>faVolumeID) then
    begin
      if FileInfo.Attr=faDirectory then
      begin
        DelDirContent(Path+FileInfo.Name);
        RemoveDirectory(PChar(Path+FileInfo.Name));
      end
      else
        DeleteFile(Path+FileInfo.Name);
    end;
    Res := FindNext(FileInfo);
  end;
end;

const
  SectCount = 8;
  SectNames: array[0..SectCount-1] of PChar = ('MAKEDIR',
    'DELETE', 'RUN', 'COPY', 'REGMOVE', 'SETPRIORITY', 'DELALL', 'SANC');
  BasePriority: Byte = 0;

function TVerUpdateForm.ExecuteUpdate: Boolean;
var
  F: TextFile;
  SectIndex, LastIndex, I, L, Step, J, K: Integer;
  S, S2, ErrMes: string;
  Err: Boolean;
  DW: dWord;
  Priority, RegMoveMode: Byte;
begin
  AssignFile(F, LogFileName);
  FileMode := 0;
  {$I-} Reset(F); {$I+}
  Result := IOResult=0;
  if Result then
  begin
    TaskListBox.Items.Clear;
    ShowMes('Чтение сценария...');
    SectIndex := -1;
    LastIndex := -1;
    RegMoveMode := 1;
    while not Eof(F) do
    begin
      ReadLn(F, S);
      S := Trim(S);
      L := Length(S);
      I := L;
      while (I>0) and not (S[I] in ['"', ';']) do
        Dec(I);
      if (I>0) and (S[I]=';') then
      begin
        S := Trim(Copy(S, 1, I-1));
        L := Length(S);
      end;
      if L>0 then
      begin
        if S[1]='[' then
        begin
          I := Pos(']', S);
          if I>0 then
          begin
            S := UpperCase(Trim(Copy(S, 2, I-2)));
            I := 0;
            while (I<SectCount) and (S<>SectNames[I]) do
              Inc(I);
            if I<SectCount then
              SectIndex := I
            else
              SectIndex := -1;
          end;
        end
        else
          if SectIndex>=0 then
          begin
            ScriptList.AddObject(S, TObject(SectIndex));
            if (LastIndex<>SectIndex) and not (SectIndex in [5,7]) then
            begin
              case SectIndex of
                0: {MakeDir}
                  AddStep('Создание подкаталогов');
                1: {Delete}
                  AddStep('Удаление неиспользуемых файлов');
                2: {Run}
                  AddStep('Распаковка новых файлов');
                3: {Copy}
                  AddStep('Копирование файлов');
                4: {RegMove}
                  AddStep('Перенос старых настроек');
                6: {DelAll}
                  AddStep('Удаление ненужных каталогов');
              end;
              LastIndex := SectIndex;
            end;
          end;
      end;
    end;
    CloseFile(F);
    ShowMes('Выполнение сценария...');
    if ScriptList.Count>0 then
    begin
      Process := True;
      I := 0;
      L := ScriptList.Count;
      try
        ProgressBar.Min := 0;
        ProgressBar.Position := ProgressBar.Min;
        ProgressBar.Max := L;
      except
      end;
      LastIndex := -1;
      Step := 0;
      Err := False;
      ProgressBar.Show;
      while (I<L) and Process and not Err do
      begin
        Priority := BasePriority;
        S := ScriptList.Strings[I];
        if S[1]='{' then
        begin
          J := Pos('}', S);
          if J>0 then
          begin
            try
              Priority := StrToInt(Trim(Copy(S, 2, J-2)));
            except
              Priority := BasePriority;
            end;
            Delete(S, 1, J);
            S := Trim(S);
          end;
        end;
        SectIndex := Integer(ScriptList.Objects[I]);
        if LastIndex<>SectIndex then
        begin
          SetCurStep(Step);
          LastIndex := SectIndex;
          Inc(Step);
        end;
        ErrMes := '';
        case SectIndex of
          0: {MakeDir}
            begin
              ShowProto('MakeDir ['+S+']');
              Err := not CreateDir(S);
              if Err then
                ErrMes := 'Не удалось создать каталог '+S;
            end;
          1,6: {Delete, DelAll}
            begin
              if SectIndex=1 then
                ShowProto('Delete ['+S+']')
              else
                ShowProto('DelAll ['+S+']');
              DW := GetFileAttributes(PChar(S));
              Err := DW=$FFFFFFFF;
              if Err then
                ErrMes := 'Удаляемый файл не найден '+S
              else begin
                if (DW and FILE_ATTRIBUTE_DIRECTORY)<>0 then
                begin
                  if SectIndex=6 then
                    DelDirContent(S);
                  Err := not RemoveDirectory(PChar(S));
                  if Err then
                    ErrMes := 'Не удалось удалить каталог '+S;
                end
                else begin
                  Err := not DeleteFile(S);
                  if Err then
                    ErrMes := 'Не удалось удалить файл '+S;
                end
              end;
            end;
          2: {Run}
            begin
              ShowProto('Run ['+S+']');
              Err := not RunAndWait(PChar(S));
              if Err then
                ErrMes := 'Ошибка при запуске '+S;
            end;
          3: {Copy}
            begin
              Err := S[1]='#';
              if Err then
                Delete(S, 1, 1);
              J := GetFirstBroker(S);
              S2 := TrimSkoba(Copy(S, 1, J-1));
              Delete(S, 1, J);
              S := TrimSkoba(S);
              ShowProto('Copy ['+S2+'|'+S+']');
              Err := not CopyFile(PChar(S2), PChar(S), Err);
              if Err then
                ErrMes := 'Не удалось скопировать '+S2+' в '+S;
            end;
          4: {RegMove}
            begin
              ShowProto('RegMove ['+S+']');
              if S[1]='#' then
              begin
                Delete(S, 1, 1);
                if Length(S)>0 then
                begin
                  if S[1]='!' then
                  begin
                    RegMoveMode := 0;
                    Delete(S, 1, 1);
                  end
                  else
                    RegMoveMode := 1;
                  J := GetFirstBroker(S);
                  S2 := TrimSkoba(Copy(S, 1, J-1));
                  Delete(S, 1, J);
                  S := TrimSkoba(S);
                  CloseReg(Reg1);
                  CloseReg(Reg2);
                  Err := not OpenBtrBase(Reg1, S2, baNormal);
                  if Err then
                    ErrMes := S2;
                  Err := Err or not OpenBtrBase(Reg2, S, baNormal);
                  if Err then
                    ErrMes := ErrMes+'|'+S;
                  if Err then
                    ErrMes := 'Ошибка открытия одной из баз настроек: '+ErrMes;
                  {SaveRegToFile(Reg2);}
                end;
              end
              else begin
                Err := not MoveRegParamsByName(Reg1, Reg2, S, RegMoveMode=0);
                if Err then
                  ErrMes := 'Не удалось перенести параметр настройки ['+S+']';
              end;
            end;
          5:  {SetPriority}
            begin
              ShowProto('SetPriority ['+S+']');
              try
                J := StrToInt(S);
              except
                Err := True;
                J := 0;
              end;
              if not Err then
                BasePriority := J;
              if Err then
                ErrMes := 'Недопустимый общий приоритет ['+S+']';
            end;
          7:  {Sanc}
            begin
              ShowProto('Sanc ['+S+']');
              if S[1]='#' then
              begin
                Delete(S, 1, 1);
                J := GetFirstBroker(S);
                S2 := TrimSkoba(Copy(S, 1, J-1));
                Delete(S, 1, J);
                S := TrimSkoba(S);
                CloseReg(SancBase);
                CloseReg(UserBase);
                Err := not OpenBtrBase(SancBase, S2, baNormal);
                Err := Err or not OpenBtrBase(UserBase, S, baReadOnly);
                if Err then
                  ErrMes := 'Ошибка открытия одной из баз: '+S2
                    +' или '+S;
                {SaveRegToFile(Reg2);}
              end
              else begin
                if S[1]='-' then
                begin
                  Delete(S, 1, 1);
                  J := 1;
                end
                else
                  J := 0;
                try
                  K := StrToInt(S);
                except
                  K := -1;
                end;
                if K>0 then
                  Err := not CorrSanc(K, J);
                if Err then
                  ErrMes := 'Не удалось изменить санкцию ['+S+']';
              end;
            end;
        end;
        if Err then
        begin
          case Priority of
            0:
              begin
                J := MB_OK or MB_ICONERROR;
                S := 'Обновление будет прервано';
              end;
            else
              begin
                J := MB_YESNOCANCEL or MB_ICONWARNING or MB_DEFBUTTON2;
                S := 'Прервать обновление?';
              end;
            {2:
              begin
                J := MB_OK or MB_ICONINFORMATION;
                S := 'Обновление будет продолжено';
              end;}
          end;
          if ((Priority=2) or (MessageBox(Handle, PChar(ErrMes+#13#10+S),
            PChar(Caption), J) <> ID_YES) and (Priority<>0)) then
          begin
            Err := False;
            ShowProto('Skip Error!');
          end
          else
            ShowProto('Fatal Error!');
        end;
        Inc(I);
        ProgressBar.Position := I;
        Application.ProcessMessages;
      end;
      if I<L then
      begin
        ExitCode := 1;
        if Process then
        begin
          ShowMes('Сценарий не удалось завершить');
        end
        else
          ShowMes('Сценарий прерван');
      end
      else begin
        ExitCode := 0;
        ShowMes('Обновление успешно завершено');
        SetCurStep(-1);
      end;
      ProgressBar.Hide;
      Process := False;
      CloseReg(Reg1);
      CloseReg(Reg2);
      CloseReg(SancBase);
      CloseReg(UserBase);
    end
    else
      ShowMes('Сценарий пуст');
  end
  else
    ShowMes('Не удалось открыть сценарий обновления ['+LogFileName+']');
end;

procedure TVerUpdateForm.FormCreate(Sender: TObject);
begin
  ScriptList := TStringList.Create;
  LogFileName := ParamStr(1);
end;

procedure TVerUpdateForm.FormDestroy(Sender: TObject);
begin
  if ProtoIsOpen then
    CloseFile(ProtoFile);
  ScriptList.Free;
end;

procedure TVerUpdateForm.FormActivate(Sender: TObject);
begin
  if FileExists(LogFileName) then
    ExecuteUpdate
  else
    ShowMes('Сценарий обновления не существует ['+LogFileName+']');
  OkBitBtn.Show;
  OkBitBtn.SetFocus;
end;

end.



