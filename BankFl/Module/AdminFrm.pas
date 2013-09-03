unit AdminFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Grids, Db, DBTables, DBGrids, ExtCtrls, DBCtrls, BtrDS, Menus,
  SearchFrm, UserFrm, StdCtrls, ComCtrls, Buttons, Common, Basbn, Utilits,
  CommCons;

type
  TAdminForm = class(TDataBaseForm)
    DataSource: TDataSource;
    DBGrid: TDBGrid;
    ChildMenu: TMainMenu;
    OperItem: TMenuItem;
    InsItem: TMenuItem;
    EditItem: TMenuItem;
    CopyItem: TMenuItem;
    DelItem: TMenuItem;
    EditBreaker2: TMenuItem;
    FindItem: TMenuItem;
    StatusBar1: TStatusBar;
    EditBreaker: TMenuItem;
    FirmItem: TMenuItem;
    SancItem: TMenuItem;
    EditPopupMenu: TPopupMenu;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure InsItemClick(Sender: TObject);
    procedure EditItemClick(Sender: TObject);
    procedure CopyItemClick(Sender: TObject);
    procedure DelItemClick(Sender: TObject);
    procedure FindItemClick(Sender: TObject);
    procedure DBGridDblClick(Sender: TObject);
    procedure FirmItemClick(Sender: TObject);
    procedure SancItemClick(Sender: TObject);
  private
    SearchForm: TSearchForm;
  public
    function AdminIsExist(ExcludeUserNumber: Integer): Boolean;
    procedure UpdateUser(CopyCurrent, New: Boolean);
  end;

const
  AdminForm: TAdminForm = nil;

var
  ObjList: TList;

implementation

uses
  SanctFrm{, Sign};

{$R *.DFM}

const
  CurL: Byte = 255;

function AccessToUser(Level: Byte): Boolean;
begin
  Result := (CurL=0) or (CurL=1) or (Level>CurL);
end;

procedure TAdminForm.FormCreate(Sender: TObject);
var
  UserRec: TUserRec;
begin
  CurrentUser(UserRec);
  CurL := UserRec.urLevel;
  ObjList.Add(Self);
  try
    DataSource.DataSet := GlobalBase(biUser);
  finally
    DefineGridCaptions(DBGrid, PatternDir+'User.tab');
    SearchForm:=TSearchForm.Create(Self);
    SearchForm.SourceDBGrid := DBGrid;
  end;
  TakeMenuItems(OperItem, EditPopupMenu.Items);
  EditPopupMenu.Images := ChildMenu.Images;
end;

procedure TAdminForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action:=caFree;
end;

procedure TAdminForm.FormDestroy(Sender: TObject);
begin
  AdminForm := nil;
  ObjList.Remove(Self);
end;

procedure TAdminForm.FindItemClick(Sender: TObject);
begin
  SearchForm.ShowModal;
end;

(*
    brCod:    longint;                  {БИК}
    brKs:     array[0..19] of char;     {К/С}
    brNpIder: longint;                  {Идер нас.пункта}
    brType:   array[0..3] of char;      {Аббревиатура}
    brName:   array[0..39] of char;     {Наименование банка}

    npIder:   longint;                  {Идер нас.пункта}
    npName:   array[0..24] of char;     {Наименование нас.пункта}
    npType:   array[0..4] of char;      {Аббревиатура}*)


function TAdminForm.AdminIsExist(ExcludeUserNumber: Integer): Boolean;
const
  MesTitle: PChar = 'Проверка операции';
var
  Len, Res, K: Integer;
  UserRec: TUserRec;
begin
  Result := False;
  with TUserDataSet(DataSource.DataSet) do
  begin
    Len := SizeOf(UserRec);
    Res := BtrBase.GetFirst(UserRec, Len, K, 0);
    while (Res=0) and not Result do
    begin
      if UserRec.urNumber<>ExcludeUserNumber then
        Result := UserRec.urLevel<=1;
      Len := SizeOf(UserRec);
      Res := BtrBase.GetNext(UserRec, Len, K, 0);
    end;
  end;
  if not Result then
    MessageBox(Handle, 'Администратор всегда должен существовать',
      MesTitle, MB_OK or MB_ICONWARNING);
end;

procedure TAdminForm.UpdateUser(CopyCurrent, New: Boolean);
const
  MesTitle: Pchar = 'Редактирование';
var
  UserForm: TUserForm;
  UserRec, UserRec2: TUserRec;
  I, J, K, OrigNum: LongInt;
  Editing: Boolean;
  W: Word;
  {D: Double;}
  {AccessDataSet: TBtrDataSet;}
  {AccessRec: TAccessRec;}
  {FirmDataSet, FirmAccDataSet: TBtrDataSet;
  FirmAccKey: packed record Number: Integer; Acc: TAccount end;
  FirmRec: TFirmRec;
  FirmName: TFirmName;}
begin
  if not DataSource.DataSet.IsEmpty or (New and not CopyCurrent) then
  begin
    UserForm := TUserForm.Create(Self);
    with UserForm do
    begin
      OrigNum := -1;
      if CopyCurrent then
      begin
        TUserDataSet(DataSource.DataSet).GetBtrRecord(PChar(@UserRec));
        OrigNum := UserRec.urNumber;
        CopyCurrent := not New and not AccessToUser(UserRec.urLevel);
      end
      else begin
        FillChar(UserRec, SizeOf(UserRec), #0);
      end;
      if CopyCurrent then
        MessageBox(Handle, 'Вы не можете редактировать этого пользователя',
          MesTitle, MB_OK + MB_ICONWARNING)
      else begin
        (*AccessDataSet := GlobalBase(biAccess);
        if AccessDataSet<>nil then
          with AccessDataSet do
          begin
            with AccessRec do
            begin
              asUserNumber := UserRec.urNumber;
              asFirmNumber := 0;
            end;
            {FirmDataSet := GlobalBase(biFirm);
            if (FirmDataSet<>nil) and LocateBtrRecordByIndex(AccessRec, 0,
              bsGe) then
            begin
              GetBtrRecord(@AccessRec);
              while not Eof and (AccessRec.asUserNumber=UserRec.urNumber) do
              begin
                I := AccessRec.asFirmNumber;
                with FirmDataSet do
                begin
                  if LocateBtrRecordByIndex(I, 0, bsEq) then
                  begin
                    GetBtrRecord(@FirmRec);
                    StrLCopy(FirmName, FirmRec.frName, SizeOf(FirmName));
                    J := StrLen(FirmName);
                    K := 0;
                    while (K<J) and (FirmName[K]<>#13) and (FirmName[K]<>#10) do
                      Inc(K);
                    if K<J then
                      FirmName[K] := #0;
                    FirmComboBox.Items.AddObject(FirmName,
                      TObject(AccessRec.asFirmNumber));
                  end;
                end;
                Next;
                GetBtrRecord(@AccessRec);
              end;
            end;}
          end; *)
        with UserRec do
        begin
          BaseNumEdit.Text := FillZeros(urFirmNumber, 3);
          OperNumberEdit.Text := IntToStr(urNumber);
          NameEdit.Text := StrPas(urInfo);
          case urLevel of
            0: LevelComboBox.ItemIndex := 0;
            1: LevelComboBox.ItemIndex := 1;
            2: LevelComboBox.ItemIndex := 2;
            3: LevelComboBox.ItemIndex := 3;
            else LevelComboBox.ItemIndex := 4;
          end;
        end;
        Editing := True;
        while Editing and (ShowModal = mrOk) do
        begin
          Editing := False;
          FillChar(UserRec, SizeOf(UserRec), #0);
          with UserRec do
          begin
            Val(OperNumberEdit.Text, urNumber, J);
            StrPCopy(urInfo, NameEdit.Text);
            if LevelComboBox.ItemIndex<LevelComboBox.Items.Count-1 then
              urLevel := LevelComboBox.ItemIndex
            else
              urLevel := 255;
            urFirmNumber := StrToInt(BaseNumEdit.Text);
            I := SizeOf(UserRec)-SizeOf(TUserInfo)+StrLen(urInfo)+1;
            Editing := not AccessToUser(urLevel);
          end;
          if Editing then
            MessageBox(Handle, 'Вы можете создать пользователя только нижнего уровня',
              MesTitle, MB_OK or MB_ICONERROR)
          else begin
            if New then
            begin
              if TUserDataSet(DataSource.DataSet).AddBtrRecord(@UserRec, I) then
                DataSource.DataSet.Refresh
              else begin
                Editing := True;
                MessageBox(Handle, 'Невозможно добавить запись', MesTitle,
                  MB_OK or MB_ICONERROR)
              end;
            end
            else begin
              with TUserDataSet(DataSource.DataSet) do
              begin
                if (UserRec.urLevel<=1)
                  or AdminIsExist(UserRec.urNumber) then
                begin
                  if LocateBtrRecordByIndex(OrigNum, 0, bsEq) then
                  begin
                    if UpdateBtrRecord(@UserRec, I) then
                      UpdateCursorPos
                    else begin
                      Editing := True;
                      MessageBox(Handle, 'Невозможно изменить запись', MesTitle,
                        MB_OK or MB_ICONERROR)
                    end;
                  end
                  else begin
                    Editing := True;
                    New := MessageBox(Handle, 'Запись уже не существует. Создать новую?',
                      MesTitle, MB_YESNOCANCEL or MB_ICONERROR) = ID_YES;
                  end;
                end
                else
                  Editing := True;
              end;
            end;
          end;
        end;
      end;
      Free;
    end;
  end;
end;

procedure TAdminForm.InsItemClick(Sender: TObject);
begin
  UpdateUser(False, True);
end;

procedure TAdminForm.EditItemClick(Sender: TObject);
begin
  UpdateUser(True, False);
end;

procedure TAdminForm.CopyItemClick(Sender: TObject);
begin
  UpdateUser(True, True)
end;

(*function DeleteUserAccess(UserNumber: Integer): Boolean;
var
  AccessDataSet: TBtrDataSet;
  AccessRec: TAccessRec;
begin
  Result := False;
  AccessDataSet := GlobalBase(biAccess);
  Result := AccessDataSet<>nil;
  if Result then
  begin
    with AccessDataSet do
    begin
      with AccessRec do
      begin
        asUserNumber := UserNumber;
        asFirmNumber := 0;
      end;
      First;
      if not Eof and LocateBtrRecordByIndex(AccessRec, 0, bsGe) then
      begin
        GetBtrRecord(@AccessRec);
        while not Eof and (AccessRec.asUserNumber=UserNumber) do
        begin
          Delete;
          GetBtrRecord(@AccessRec);
        end;
      end;
      Result := True;
    end;
  end;
end; *)

function DeleteUserSanct(UserNumber: Integer): Boolean;
var
  SanctDataSet: TBtrDataSet;
  SanctRec: TSanctionRec;
begin
  Result := False;
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

procedure TAdminForm.DelItemClick(Sender: TObject);
const
  MesTitle: PChar = 'Удаление пользователя';
var
  UserRec: TUserRec;
  N: Integer;
begin
  if not DataSource.DataSet.IsEmpty then
  begin
    TUserDataSet(Self.DataSource.DataSet).GetBtrRecord(PChar(@UserRec));
    N := UserRec.urNumber;
    if AccessToUser(UserRec.urLevel) then
    begin
      if AdminIsExist(UserRec.urNumber) then
      begin
        if MessageBox(Handle, 'Пользователь будет удален из списка. Вы уверены?',
          MesTitle, MB_YESNOCANCEL or MB_ICONQUESTION) = IDYES then
        begin
          if TUserDataSet(DataSource.DataSet).LocateBtrRecordByIndex(N, 0, bsEq) then
          begin
            {if not DeleteUserAccess(N) then
              MessageBox(Handle, 'Ошибка удаления доступа', MesTitle,
                MB_OK or MB_ICONERROR);}
            if not DeleteUserSanct(N) then
              MessageBox(Handle, 'Ошибка удаления санкций',MesTitle,
                MB_OK or MB_ICONERROR);
            TUserDataSet(DataSource.DataSet).Delete;
          end
          else
            MessageBox(Handle, 'Запись уже не существует',
              MesTitle, MB_OK or MB_ICONERROR);
        end;
      end;
    end
    else
      MessageBox(Handle, 'Вы не можете удалить этого пользователя',
        MesTitle, MB_OK or MB_ICONERROR);
  end;
end;

procedure TAdminForm.DBGridDblClick(Sender: TObject);
begin
  if FormStyle=fsMDIChild then
    EditItemClick(Sender)
  else
    ModalResult := mrOk;
end;

procedure TAdminForm.FirmItemClick(Sender: TObject);
(*var
  {AccessDataSet: TBtrDataSet;}
  UserRec: TUserRec;
  {AccessRec: TAccessRec;}
  N, I: Integer; *)
begin
  (*if not DataSource.DataSet.IsEmpty then
  begin
    AccessForm := TAccessForm.Create(Self);
    with AccessForm do
    begin
      AccessDataSet := GlobalBase(biAccess);
      if AccessDataSet<>nil then
      begin
        with AccessDataSet do
        begin
          TUserDataSet(Self.DataSource.DataSet).GetBtrRecord(PChar(@UserRec));
          if AccessToUser(UserRec.urLevel) then
          begin
            N := UserRec.urNumber;
            with AccessRec do
            begin
              asUserNumber := N;
              asFirmNumber := 0;
            end;
            if LocateBtrRecordByIndex(AccessRec, 0, bsGe) then
            begin
              GetBtrRecord(@AccessRec);
              while not Eof and (AccessRec.asUserNumber=N) do
              begin
                if (AccessRec.asFirmNumber>0)
                  and (AccessRec.asFirmNumber<=CheckListBox.Items.Count) then
                    CheckListBox.Checked[AccessRec.asFirmNumber-1] := True;
                Next;
                GetBtrRecord(@AccessRec);
              end;
            end;
            UserEdit.Text := StrPas(UserRec.urName);
            if ShowModal=mrOk then
            begin
              if DeleteUserAccess(N) then
                for I:=1 to CheckListBox.Items.Count do
                begin
                  if CheckListBox.Checked[I-1] then
                  begin
                    with AccessRec do
                    begin
                      asUserNumber := N;
                      asFirmNumber := I;
                    end;
                    AddBtrRecord(@AccessRec, SizeOf(AccessRec));
                  end;
                end
              else
                MessageBox(Handle, 'Не удалось удалить привеллегии полльзователя',
                  'Доступ', MB_OK+MB_ICONERROR);
            end;
          end
          else
            MessageBox(Handle, 'Вы не можете администрировать этого пользователя',
              'Доступ', MB_OK+MB_ICONERROR);
        end;
      end
      else
        MessageBox(Handle, 'База доступа не открыта', 'Доступ', MB_OK+MB_ICONERROR);
      Free;
    end;
  end; *)
end;

procedure TAdminForm.SancItemClick(Sender: TObject);
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
            UserEdit.Text := StrPas(UserRec.urInfo);
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
                  'Санкции', MB_OK+MB_ICONERROR);
            end;
          end
          else
            MessageBox(Handle, 'Вы не можете администрировать этого пользователя',
              'Санкции', MB_OK+MB_ICONERROR);
        end;
      end
      else
        MessageBox(Handle, 'База санкций не открыта', 'Санкции', MB_OK+MB_ICONERROR);
      Free;
    end;
  end;
end;

end.

