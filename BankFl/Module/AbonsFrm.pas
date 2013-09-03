unit AbonsFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Grids, Db, DBTables, DBGrids, ExtCtrls, DBCtrls, Menus,
  StdCtrls, Buttons, ComCtrls, Common, SearchFrm, Basbn, Utilits,
  BtrDS, BankCnBn, Registr, CommCons, AbonFrm;

type
  TAbonsForm = class(TDataBaseForm)
    DataSource: TDataSource;
    StatusBar: TStatusBar;
    ChildMenu: TMainMenu;
    OperItem: TMenuItem;
    FindItem: TMenuItem;
    InsItem: TMenuItem;
    DelItem: TMenuItem;
    EditBreaker: TMenuItem;
    EditItem: TMenuItem;
    CopyItem: TMenuItem;
    EditPopupMenu: TPopupMenu;
    EditBreaker1: TMenuItem;
    AbonStatItem: TMenuItem;
    EditBreaker2: TMenuItem;
    RemoveDataItem: TMenuItem;
    HorzSplitter: TSplitter;
    SignIdDataSource: TDataSource;
    SignIdPopupMenu: TPopupMenu;
    NewSidItem: TMenuItem;
    EditSidItem: TMenuItem;
    DelSidItem: TMenuItem;
    SidGroupBox: TGroupBox;
    SignIdDBGrid: TDBGrid;
    TopPanel: TPanel;
    DBGrid: TDBGrid;
    BtnPanel: TPanel;
    NameLabel: TLabel;
    NameEdit: TEdit;
    SearchIndexComboBox: TComboBox;
    CorrListComboBox: TComboBox;
    BottomPanel: TPanel;
    AbonSidLabel: TLabel;
    AbonSidComboBox: TComboBox;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure NameEditChange(Sender: TObject);
    procedure SearchIndexComboBoxChange(Sender: TObject);
    procedure FindItemClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure InsItemClick(Sender: TObject);
    procedure EditItemClick(Sender: TObject);
    procedure DelItemClick(Sender: TObject);
    procedure CopyItemClick(Sender: TObject);
    procedure DBGridDblClick(Sender: TObject);
    procedure AbonStatItemClick(Sender: TObject);
    procedure RemoveDataItemClick(Sender: TObject);
    procedure HorzSplitterCanResize(Sender: TObject; var NewSize: Integer;
      var Accept: Boolean);
    procedure NewSidItemClick(Sender: TObject);
    procedure EditSidItemClick(Sender: TObject);
    procedure SignIdDBGridKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure DelSidItemClick(Sender: TObject);
    procedure AbonSidComboBoxChange(Sender: TObject);
  private
    procedure UpdateAbon(CopyCurrent, New: Boolean);
  public
    SearchForm: TSearchForm;
    function NodeIsExist(ANode: Word; CurIder: Integer): Boolean;
  end;

var
  ObjList: TList;
const
  AbonsForm: TAbonsForm = nil;

implementation

uses AbonStatFrm, AbonSidFrm;

const
  CurL: Byte = 255;

{$R *.DFM}

var
  AbonDataSet, SignIdDataSet: TExtBtrDataSet;

procedure TAbonsForm.FormCreate(Sender: TObject);
var
  UserRec: TUserRec;
begin
  FillCorrList(CorrListComboBox.Items, 0);
  ObjList.Add(Self);
  AbonDataSet := GlobalBase(biAbon) as TExtBtrDataSet;
  DataSource.DataSet := AbonDataSet;
  DefineGridCaptions(DBGrid, PatternDir+'Abons.tab');

  SignIdDataSet := GlobalBase(biAbonSid) as TExtBtrDataSet;
  SignIdDataSource.DataSet := SignIdDataSet;
  DefineGridCaptions(SignIdDBGrid, PatternDir+'AbonSid.tab');

  SearchForm := TSearchForm.Create(Self);
  SearchForm.SourceDBGrid := DBGrid;
  SearchIndexComboBox.ItemIndex := 1;
  SearchIndexComboBoxChange(Sender);
  AbonSidComboBox.ItemIndex := 0;
  AbonSidComboBoxChange(Sender);
  TakeMenuItems(OperItem, EditPopupMenu.Items);
  EditPopupMenu.Images := ChildMenu.Images;

  CurrentUser(UserRec);
  CurL := UserRec.urLevel;
end;

procedure TAbonsForm.FormDestroy(Sender: TObject);
begin
  ObjList.Remove(Self);
  if Self=AbonsForm then
    AbonsForm := nil;
end;

procedure TAbonsForm.NameEditChange(Sender: TObject);
var
  I, Err: Integer;
  Login: array[0..23] of Char;
  S: string;
begin
  case SearchIndexComboBox.ItemIndex of
    0:
    begin
      Val(NameEdit.Text, I, Err);
      AbonDataSet.LocateBtrRecordByIndex(I, 0, bsGe);
    end;
    1,2:
    begin
      S := UpperCase(NameEdit.Text);
      StrPLCopy(Login, S, SizeOf(Login));
      AbonDataSet.LocateBtrRecordByIndex(Login, 1, bsGe);
    end;
  end;
end;

procedure TAbonsForm.SearchIndexComboBoxChange(Sender: TObject);
begin
  AbonDataSet.IndexNum := SearchIndexComboBox.ItemIndex;
  case SearchIndexComboBox.ItemIndex of
    0: NameEdit.MaxLength := 12;
    else
      NameEdit.MaxLength := 8;
  end;
end;

procedure TAbonsForm.FindItemClick(Sender: TObject);
begin
  SearchForm.ShowModal;
end;

procedure TAbonsForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if FormStyle=fsMDIChild then
    Action:=caFree;
end;

function TAbonsForm.NodeIsExist(ANode: Word; CurIder: Integer): Boolean;
var
  AbonentRec: TAbonentRec;
  Len, I, Res: Integer;
begin
  Result := False;
  with AbonDataSet.BtrBase do
  begin
    Res := GetFirst(AbonentRec, Len, I, 0);
    while (Res=0) and not Result do
    begin
      Result := (AbonentRec.abNode = ANode) and (AbonentRec.abIder<>CurIder);
      Res := GetNext(AbonentRec, Len, I, 0);
    end;
  end;
end;

(*procedure TAbonsForm.UpdateAbon(CopyCurrent, New: Boolean);
const
  MesTitle: PChar = 'Редактирование';
var
  AbonForm: TAbonForm;
  AbonentRec: TAbonentRec;
  AbonIdRec, AbonIdRec2: TAbonIdRec;
  I, L, Res, Id: Integer;
  T: array[0..511] of Char;
  Editing: Boolean;
  AbonIdDataSet: TExtBtrDataSet;
begin
  AbonIdDataSet := GlobalBase(biAbonId) as TExtBtrDataSet;
  if not AbonDataSet.IsEmpty or (New and not CopyCurrent) then
  begin
    AbonForm := TAbonForm.Create(Self);
    with AbonForm do
    begin
      {WayComboBox.Enabled := CurL<1;
      CryptCheckBox.Enabled := WayComboBox.Enabled;}
      //FillChar(AbonIdRec, SizeOf(AbonIdRec), #0);
      Id := 0;
      if CopyCurrent then
      begin
        L := AbonDataSet.GetBtrRecord(PChar(@AbonentRec));
        if L>0 then
        begin
          Id := AbonentRec.abIder;
          L := SizeOf(AbonIdRec);
          AbonIdDataSet.BtrBase.GetEqual(AbonIdRec, L, I, 0);
        end;
      end
      else begin
        FillChar(AbonentRec, SizeOf(AbonentRec), #0);
        with AbonentRec do
        begin
          abSize := 4096;
          abWay := awPostMach;
          abCrypt := acDomenK;
          abLock := aloTake;
        end;
      end;
      with AbonentRec do
      begin
        NodeEdit.Text := IntToStr(abNode);
        LoginEdit.Text := abLogin;
        LoginOldEdit.Text := abOldLogin;
        BranchCheckBox.Checked := abType<>0;
        if (abWay>=0) and (abWay<WayComboBox.Items.Count) then
          WayComboBox.ItemIndex := abWay;
        if (abCrypt>=0) and (abCrypt<CryptComboBox.Items.Count) then
          CryptComboBox.ItemIndex := abCrypt;
        SendLockCheckBox.Checked := abLock and alSend > 0;
        RecieveLockCheckBox.Checked := abLock and alRecv > 0;
        ControlComboBox.ItemIndex := (abLock and alOther) shr 2;
        SizeComboBox.Text := IntToStr(abSize);
        LastIdEdit.Text := IntToStr(AbonIdRec.aiLastAuth);
        HardIdEdit.Text := IntToStr(AbonIdRec.aiHardId);
        HexPanelClick(Self);
        DosToWin(abName);
        StrLCopy(T, abName, SizeOf(abName));
        NameEdit.Text := T;
      end;
      Editing := True;
      while Editing and (ShowModal = mrOk) do
      begin
        FillChar(AbonentRec, SizeOf(AbonentRec), #0);
        with AbonentRec do
        begin
          abIder := Id;
          Val(NodeEdit.Text, abNode, I);
          Editing := (I<>0) or (abNode=BroadcastNode) or (abNode<1);
          if Editing then
          begin
            ActiveControl := NodeEdit;
            MessageBox(Handle, 'Ошибочный номер узла',
              MesTitle, MB_OK or MB_ICONWARNING)
          end
          else begin
            Val(SizeComboBox.Text, abSize, I);
            Editing := (I<>0) or (abSize<200);
            if Editing then
            begin
              ActiveControl := SizeComboBox;
              MessageBox(Handle, 'Неверно указан размер пакета',
                MesTitle, MB_OK or MB_ICONWARNING)
            end
            else begin
              FillChar(abLogin, SizeOf(abLogin), #0);
              StrPLCopy(abLogin, LoginEdit.Text, SizeOf(abLogin)-1);
              FillChar(abOldLogin, SizeOf(abOldLogin), #0);
              StrPLCopy(abOldLogin, LoginOldEdit.Text, SizeOf(abOldLogin)-1);
              if BranchCheckBox.Checked then
                abType := 1
              else
                abType := 0;
              abLock := 0;
              if SendLockCheckBox.Checked then
                abLock := abLock or alSend;
              if RecieveLockCheckBox.Checked then
                abLock := abLock or alRecv;
              abLock := abLock or ControlComboBox.ItemIndex shl 2;
              abWay := WayComboBox.ItemIndex;
              abCrypt := CryptComboBox.ItemIndex;

              Val(LastIdEdit.Text, AbonIdRec.aiLastAuth, I);
              if I<>0 then
                MessageBox(Handle, 'Неверно указан номер захода',
                  MesTitle, MB_OK or MB_ICONWARNING);
              HexPanelClick(nil);
              Val(HardIdEdit.Text, AbonIdRec.aiHardId, I);
              if I<>0 then
                MessageBox(Handle, 'Неверно указан аппаратный код',
                  MesTitle, MB_OK or MB_ICONWARNING);
              StrPTCopy(T, NameEdit.Text, SizeOf(T));
              WinToDos(T);
              StrLCopy(abName, T, SizeOf(abName));
              L := SizeOf(TAbonentRec)-SizeOf(abName)+StrLen(abName)+1;
              Editing := False;
            end;
          end;
        end;
        if New then
          I := 0
        else
          I := AbonentRec.abIder;
        Editing := Editing
          or (NodeIsExist(AbonentRec.abNode, I) and (MessageBox(Handle,
            'Абонент с таким номером узла уже существует. Игнорировать?',
            MesTitle, MB_YESNOCANCEL or MB_ICONWARNING
            or MB_DEFBUTTON2) <> ID_YES));
        if not Editing then
        begin
          if New then
          begin
            begin
              MakeRegNumber(rnPaydoc, I);
              AbonentRec.abIder := I;
              if AbonDataSet.AddBtrRecord(PChar(@AbonentRec), L) then
              begin
                ProtoMes(plInfo, MesTitle, 'Добавлен абонент Id='
                  +IntToStr(AbonentRec.abIder));
                DBGrid.SelectedRows.Clear;
                AbonDataSet.Refresh;
              end
              else
                Editing := MessageBox(Handle, 'Не удается добавить запись. Повторить?',
                  MesTitle, MB_YESNOCANCEL or MB_ICONWARNING) = ID_YES;
            end;
          end
          else begin
            I := AbonentRec.abIder;
            if AbonDataSet.LocateBtrRecordByIndex(I, 0, bsEq) then
            begin
              if AbonDataSet.UpdateBtrRecord(PChar(@AbonentRec), L) then
              begin
                ProtoMes(plInfo, MesTitle, 'Изменен абонент Id='
                  +IntToStr(AbonentRec.abIder));
                AbonDataSet.UpdateCursorPos
              end
              else
                Editing := MessageBox(Handle, 'Не удается изменить запись. Повторить?',
                  MesTitle, MB_YESNOCANCEL or MB_ICONWARNING) = ID_YES;
            end
            else begin
              Editing := MessageBox(Handle, 'Запись уже не существует. Создать новую?',
                MesTitle, MB_YESNOCANCEL or MB_ICONWARNING) = ID_YES;
              New := Editing;
            end;
          end;
          if not Editing and (ChangeIdLabel.Tag>0) then
          begin
            I := AbonentRec.abIder;
            AbonIdRec.aiIder := I;
            L := SizeOf(AbonIdRec2);
            Res := AbonIdDataSet.BtrBase.GetEqual(AbonIdRec2, L, I, 0);
            if ChangeIdLabel.Tag=1 then
            begin
              if Res=0 then
                Res := AbonIdDataSet.BtrBase.Update(AbonIdRec, L, I, 0)
              else
                Res := AbonIdDataSet.BtrBase.Insert(AbonIdRec, L, I, 0);
              if Res<>0 then
                MessageBox(Handle, PChar(
                  'Не удалось изменить данные об абоненте BtrErr='
                  +IntToStr(Res)), MesTitle, MB_OK or MB_ICONWARNING);
            end
            else begin
              if Res=0 then
                Res := AbonIdDataSet.BtrBase.Delete(0);
              if Res<>0 then
                MessageBox(Handle, PChar(
                  'Не удалось удалить данные об абоненте BtrErr='
                  +IntToStr(Res)), MesTitle, MB_OK or MB_ICONWARNING);
            end
          end;
        end;
      end;
      Free;
    end;
  end;
end;*)
procedure TAbonsForm.UpdateAbon(CopyCurrent, New: Boolean);
const
  MesTitle: PChar = 'Редактирование';
var
  AbonForm: TAbonForm;
  AbonentRec: TAbonentRec;
  AbonIdRec, AbonIdRec2: TAbonIdRec;
  I, L, Res, Id: Integer;
  T: array[0..511] of Char;
  Editing: Boolean;
  AbonIdDataSet: TExtBtrDataSet;
begin
  AbonIdDataSet := GlobalBase(biAbonId) as TExtBtrDataSet;
  if not AbonDataSet.IsEmpty or (New and not CopyCurrent) then
  begin
    AbonForm := TAbonForm.Create(Self);
    with AbonForm do
    begin
      MailPanel.Enabled := not New and CopyCurrent;
      if not MailPanel.Enabled then
        MailPanel.Font.Color := TColor(COLOR_BTNSHADOW or $80000000);;
      {WayComboBox.Enabled := CurL<1;
      CryptCheckBox.Enabled := WayComboBox.Enabled;}
      //FillChar(AbonIdRec, SizeOf(AbonIdRec), #0);
      FillChar(AbonIdRec, SizeOf(AbonIdRec), #0);
      Id := 0;
      if CopyCurrent then
      begin
        L := AbonDataSet.GetBtrRecord(PChar(@AbonentRec));
        if L>0 then
        begin
          Id := AbonentRec.abIder;
          L := SizeOf(AbonIdRec);
          Res := AbonIdDataSet.BtrBase.GetEqual(AbonIdRec, L, Id, 0);
          if Res<>0 then
            FillChar(AbonIdRec, SizeOf(AbonIdRec), #0);
        end;
      end
      else begin
        FillChar(AbonentRec, SizeOf(AbonentRec), #0);
        with AbonentRec do
        begin
          abSize := 4096;
          abWay := awPostMach;
          abCrypt := acDomenK;
          abLock := aloTake;
        end;
      end;
      with AbonentRec do
      begin
        NodeEdit.Text := IntToStr(abNode);
        LoginEdit.Text := abLogin;
        LoginOldEdit.Text := abOldLogin;
        StatusComboBox.ItemIndex := abType and atStatus;
        TraceCheckBox.Checked := (abType and atTrace)>0;
        SmallPackCheckBox.Checked := (abType and atSmallPack)>0;
        if (abWay>=0) and (abWay<WayComboBox.Items.Count) then
          WayComboBox.ItemIndex := abWay;
        if (abCrypt>=0) and (abCrypt<CryptComboBox.Items.Count) then
          CryptComboBox.ItemIndex := abCrypt;
        SendLockCheckBox.Checked := abLock and alSend > 0;
        RecieveLockCheckBox.Checked := abLock and alRecv > 0;
        //Добавлено Меркуловым
        SendExtractCheckBox.Checked := abLock and alSExtr > 0;

        ControlComboBox.ItemIndex := (abLock and alOther) shr 2;
        SizeComboBox.Text := IntToStr(abSize);
        LastIdEdit.Text := IntToStr(AbonIdRec.aiLastAuth);
        HardIdEdit.Text := IntToStr(AbonIdRec.aiHardId);
        HexPanelClick(Self);
        DosToWin(abName);
        StrLCopy(T, abName, SizeOf(abName));
        NameEdit.Text := T;
      end;
      Editing := True;
      while Editing and (ShowModal = mrOk) do
      begin
        FillChar(AbonentRec, SizeOf(AbonentRec), #0);
        with AbonentRec do
        begin
          abIder := Id;
          Val(NodeEdit.Text, abNode, I);
          Editing := (I<>0) or (abNode=BroadcastNode) or (abNode<1);
          if Editing then
          begin
            ActiveControl := NodeEdit;
            MessageBox(Handle, 'Ошибочный номер узла',
              MesTitle, MB_OK or MB_ICONWARNING)
          end
          else begin
            Val(SizeComboBox.Text, abSize, I);
            Editing := (I<>0) or (abSize<200);
            if Editing then
            begin
              ActiveControl := SizeComboBox;
              MessageBox(Handle, 'Неверно указан размер пакета',
                MesTitle, MB_OK or MB_ICONWARNING)
            end
            else begin
              FillChar(abLogin, SizeOf(abLogin), #0);
              StrPLCopy(abLogin, LoginEdit.Text, SizeOf(abLogin)-1);
              FillChar(abOldLogin, SizeOf(abOldLogin), #0);
              StrPLCopy(abOldLogin, LoginOldEdit.Text, SizeOf(abOldLogin)-1);
              abType := StatusComboBox.ItemIndex;
              if TraceCheckBox.Checked then
                abType := abType or atTrace;
              if SmallPackCheckBox.Checked then
                abType := abType or atSmallPack;
              abLock := 0;
              if SendLockCheckBox.Checked then
                abLock := abLock or alSend;
              if RecieveLockCheckBox.Checked then
                abLock := abLock or alRecv;

              //Добавлено Меркуловым
              if SendExtractCheckBox.Checked then
                abLock := abLock or alSExtr;

              abLock := abLock or ControlComboBox.ItemIndex shl 2;
              abWay := WayComboBox.ItemIndex;
              abCrypt := CryptComboBox.ItemIndex;

              Val(LastIdEdit.Text, AbonIdRec.aiLastAuth, I);
              if I<>0 then
                MessageBox(Handle, 'Неверно указан номер захода',
                  MesTitle, MB_OK or MB_ICONWARNING);
              HexPanelClick(nil);
              Val(HardIdEdit.Text, AbonIdRec.aiHardId, I);
              if I<>0 then
                MessageBox(Handle, 'Неверно указан аппаратный код',
                  MesTitle, MB_OK or MB_ICONWARNING);
              StrPTCopy(T, NameEdit.Text, SizeOf(T));
              WinToDos(T);
              StrLCopy(abName, T, SizeOf(abName));
              L := SizeOf(TAbonentRec)-SizeOf(abName)+StrLen(abName)+1;
              Editing := False;
            end;
          end;
        end;
        if New then
          I := 0
        else
          I := AbonentRec.abIder;
        Editing := Editing
          or (NodeIsExist(AbonentRec.abNode, I) and (MessageBox(Handle,
            'Абонент с таким номером узла уже существует. Игнорировать?',
            MesTitle, MB_YESNOCANCEL or MB_ICONWARNING
            or MB_DEFBUTTON2) <> ID_YES));
        if not Editing then
        begin
          if New then
          begin
            begin
              MakeRegNumber(rnPaydoc, I);
              AbonentRec.abIder := I;
              if TExtBtrDataSet(DataSource.DataSet).AddBtrRecord(PChar(@AbonentRec),
                L) then
              begin
                ProtoMes(plInfo, MesTitle, 'Добавлен абонент Id='
                  +IntToStr(AbonentRec.abIder));
                DBGrid.SelectedRows.Clear;
                DataSource.DataSet.Refresh;
              end
              else
                Editing := MessageBox(Handle, 'Не удается добавить запись. Повторить?',
                  MesTitle, MB_YESNOCANCEL or MB_ICONWARNING) = ID_YES;
            end;
          end
          else begin
            I := AbonentRec.abIder;
            if TBtrDataSet(DataSource.DataSet).LocateBtrRecordByIndex(I, 0, bsEq) then
            begin
              if TExtBtrDataSet(DataSource.DataSet).UpdateBtrRecord(PChar(@AbonentRec),
                L) then
              begin
                ProtoMes(plInfo, MesTitle, 'Изменен абонент Id='
                  +IntToStr(AbonentRec.abIder));
                DataSource.DataSet.UpdateCursorPos
              end
              else
                Editing := MessageBox(Handle, 'Не удается изменить запись. Повторить?',
                  MesTitle, MB_YESNOCANCEL or MB_ICONWARNING) = ID_YES;
            end
            else begin
              Editing := MessageBox(Handle, 'Запись уже не существует. Создать новую?',
                MesTitle, MB_YESNOCANCEL or MB_ICONWARNING) = ID_YES;
              New := Editing;
            end;
          end;
          if not Editing and (ChangeIdLabel.Tag>0) then
          begin
            I := AbonentRec.abIder;
            AbonIdRec.aiIder := I;
            L := SizeOf(AbonIdRec2);
            Res := AbonIdDataSet.BtrBase.GetEqual(AbonIdRec2, L, I, 0);
            if ChangeIdLabel.Tag=1 then
            begin
              if Res=0 then
                Res := AbonIdDataSet.BtrBase.Update(AbonIdRec, L, I, 0)
              else
                Res := AbonIdDataSet.BtrBase.Insert(AbonIdRec, L, I, 0);
              if Res<>0 then
                MessageBox(Handle, PChar(
                  'Не удалось изменить данные об абоненте BtrErr='
                  +IntToStr(Res)), MesTitle, MB_OK or MB_ICONWARNING);
            end
            else begin
              if Res=0 then
                Res := AbonIdDataSet.BtrBase.Delete(0);
              if Res<>0 then
                MessageBox(Handle, PChar(
                  'Не удалось удалить данные об абоненте BtrErr='
                  +IntToStr(Res)), MesTitle, MB_OK or MB_ICONWARNING);
            end
          end;
        end;
      end;
      Free;
    end;
  end;
end;

procedure TAbonsForm.InsItemClick(Sender: TObject);
begin
  UpdateAbon(False, True);
end;

procedure TAbonsForm.EditItemClick(Sender: TObject);
begin
  if FormStyle = fsMDIChild then
    UpdateAbon(True, False)
  else
    ModalResult := mrOk;
end;

procedure TAbonsForm.CopyItemClick(Sender: TObject);
begin
  UpdateAbon(True, True)
end;

procedure TAbonsForm.DelItemClick(Sender: TObject);
const
  MesTitle: PChar = 'Удаление';
var
  N: Integer;
  AbonentRec: TAbonentRec;
begin
  if not DataSource.DataSet.IsEmpty then
  begin
    DBGrid.SelectedRows.Refresh;
    N := DBGrid.SelectedRows.Count;
    if (N<2) and (MessageBox(Handle, PChar('Абонент будет удален. Вы уверены?'),
      MesTitle, MB_YESNOCANCEL or MB_ICONQUESTION) = IDYES)
      or (N>=2) and (MessageBox(Handle, PChar('Будет удалено абонентов: '
      +IntToStr(DBGrid.SelectedRows.Count)+#13#10'Вы уверены?'),
      MesTitle, MB_YESNOCANCEL or MB_ICONQUESTION) = IDYES) then
    begin
      if N>0 then
      begin
        DBGrid.SelectedRows.Delete;
        DBGrid.SelectedRows.Refresh;
        ProtoMes(plInfo, MesTitle, 'Удалено абонентов N='+IntToStr(N));
      end
      else begin
        TExtBtrDataSet(DataSource.DataSet).GetBtrRecord(PChar(@AbonentRec));
        DataSource.DataSet.Delete;
        ProtoMes(plInfo, MesTitle, 'Удален абонент Id='
          +IntToStr(AbonentRec.abIder));
      end;
    end;
  end;
end;

procedure TAbonsForm.DBGridDblClick(Sender: TObject);
begin
  EditItemClick(Sender)
end;

procedure TAbonsForm.AbonStatItemClick(Sender: TObject);
begin
  if AbonStatForm=nil then
    AbonStatForm := TAbonStatForm.Create(Self);
  AbonStatForm.Show;
end;

procedure TAbonsForm.RemoveDataItemClick(Sender: TObject);
begin
  {if MoveDataForm=nil then
    MoveDataForm := TMoveDataForm.Create(Sender as TComponent);
  MoveDataForm.ShowModal;
  MoveDataForm.Free;}
end;

procedure TAbonsForm.HorzSplitterCanResize(Sender: TObject;
  var NewSize: Integer; var Accept: Boolean);
begin
  Accept := NewSize>40;
end;

procedure TAbonsForm.NewSidItemClick(Sender: TObject);
const
  MesTitle: PChar = 'Редактирование ключа';
var
  AbonSignIdRec: TAbonSignIdRec;
  L, AbId: Integer;
  Editing: Boolean;
begin
  AbonSidForm := TAbonSidForm.Create(Self);
  with AbonSidForm do
  begin
    FillChar(AbonSignIdRec, SizeOf(AbonSignIdRec), #0);
    AbId := 0;
    if Sender=nil then
    begin
      L := SignIdDataSet.GetBtrRecord(PChar(@AbonSignIdRec));
      if L>0 then
        AbId := AbonSignIdRec.asIder;
    end;
    Editing := True;
    while Editing do
    begin
      Editing := False;
      with AbonSignIdRec do
      begin
        IdEdit.Text := asLogin;
        CorrWideComboBox.ItemIndex := CorrWideComboBox.Items.
          IndexOfObject(TObject(asIder));
        DirectorCheckBox.Checked := usDirector and asStatus>0;
        BugalterCheckBox.Checked := usAccountant and asStatus>0;
        CourierCheckBox.Checked := usCourier and asStatus>0;
        NameEdit.Text := asName;
        if ShowModal=mrOk then
        begin
          FillChar(AbonSignIdRec, SizeOf(AbonSignIdRec), #0);
          StrPLCopy(asLogin, IdEdit.Text, SizeOf(asLogin)-1);
          asIder := Integer(CorrWideComboBox.Items.Objects[CorrWideComboBox.ItemIndex]);
          asStatus := 0;
          if DirectorCheckBox.Checked then
            asStatus := asStatus or usDirector;
          if BugalterCheckBox.Checked then
            asStatus := asStatus or usAccountant;
          if CourierCheckBox.Checked then
            asStatus := asStatus or usCourier;
          StrPLCopy(asName, NameEdit.Text, SizeOf(asName)-1);
          L := SizeOf(AbonSignIdRec)-SizeOf(asName)+StrLen(asName)+1;
          if Sender=nil then
          begin
            AbonSignIdRec.asIder := AbId;
            if SignIdDataSet.UpdateBtrRecord(PChar(@AbonSignIdRec), L) then
            begin
              ProtoMes(plInfo, MesTitle, 'Изменен ключ Id='+IntToStr(asIder)+'|'+asLogin);
              SignIdDataSource.DataSet.UpdateCursorPos
            end
            else
              Editing := MessageBox(Handle, 'Не удается изменить запись. Повторить?',
                MesTitle, MB_YESNOCANCEL or MB_ICONWARNING) = ID_YES;
          end
          else begin
            if SignIdDataSet.AddBtrRecord(PChar(@AbonSignIdRec), L) then
            begin
              ProtoMes(plInfo, MesTitle, 'Добавлен ключ Id='+IntToStr(asIder)+'|'+asLogin);
              SignIdDBGrid.SelectedRows.Clear;
              SignIdDataSource.DataSet.Refresh;
            end
            else
              Editing := MessageBox(Handle, 'Не удается добавить запись. Повторить?',
                MesTitle, MB_YESNOCANCEL or MB_ICONWARNING) = ID_YES;
          end;
        end;
      end;
    end;
    Free;
  end;
end;

procedure TAbonsForm.EditSidItemClick(Sender: TObject);
begin
  if not SignIdDataSet.IsEmpty then
    NewSidItemClick(nil);
end;

procedure TAbonsForm.DelSidItemClick(Sender: TObject);
const
  MesTitle: PChar = 'Удаление ключа';
var
  N: Integer;
  AbonSignIdRec: TAbonSignIdRec;
  List1, List2: string;
begin
  if not SignIdDataSet.IsEmpty then
  begin
    SignIdDBGrid.SelectedRows.Refresh;
    N := SignIdDBGrid.SelectedRows.Count;
    if (N<2) and (MessageBox(Handle, PChar('Ключ будет удален. Вы уверены?'),
      MesTitle, MB_YESNOCANCEL or MB_ICONQUESTION) = IDYES)
      or (N>=2) and (MessageBox(Handle, PChar('Будет удалено ключей: '
      +IntToStr(SignIdDBGrid.SelectedRows.Count)+#13#10'Вы уверены?'),
      MesTitle, MB_YESNOCANCEL or MB_ICONQUESTION) = IDYES) then
    begin
      if N>0 then
      begin
        SignIdDBGrid.SelectedRows.Delete;
        SignIdDBGrid.SelectedRows.Refresh;
        ProtoMes(plInfo, MesTitle, 'Удалено ключей N='+IntToStr(N));
      end
      else begin
        TExtBtrDataSet(SignIdDataSource.DataSet).GetBtrRecord(PChar(@AbonSignIdRec));
        SignIdDataSource.DataSet.Delete;
        ProtoMes(plInfo, MesTitle, 'Удален ключ Id='
          +IntToStr(AbonSignIdRec.asIder));
      end;
    end;
  end;
end;

procedure TAbonsForm.SignIdDBGridKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  case Key of
    VK_RETURN:
      EditSidItemClick(nil);
    VK_DELETE:
      DelSidItemClick(nil);
  end;
end;

procedure TAbonsForm.AbonSidComboBoxChange(Sender: TObject);
var
  AllowMultiSel: Boolean;
  Opt: TDBGridOptions;
begin
  SignIdDataSet.IndexNum := AbonSidComboBox.ItemIndex;
  AllowMultiSel := AbonSidComboBox.ItemIndex=0;
  Opt := SignIdDBGrid.Options;
  if (dgMultiSelect in Opt)<>AllowMultiSel then
  begin
    if AllowMultiSel then
      Include(Opt, dgMultiSelect)
    else
      Exclude(Opt, dgMultiSelect);
    SignIdDBGrid.Options := Opt;
  end;
end;

{begin
  (DataSource.DataSet as TBtrDataSet).IndexNum := SearchIndexComboBox.ItemIndex;
  AccComboBox.Hide;
  IdentEdit.Hide;
  CorrListComboBox.Hide;
  AccCheckBox.Hide;
  LastAccPanel.Hide;
  case SearchIndexComboBox.ItemIndex of
    0: IdentEdit.Show;
    1:
      begin
        AccComboBox.Show;
        AccCheckBox.Show;
        LastAccPanel.Show;
      end;
    2: CorrListComboBox.Show;
  end;
  AllowMultiSel := SearchIndexComboBox.ItemIndex<>2;
  Opt := DBGrid.Options;
  if (dgMultiSelect in Opt)<>AllowMultiSel then
  begin
    if AllowMultiSel then
      Include(Opt, dgMultiSelect)
    else
      Exclude(Opt, dgMultiSelect);
    DBGrid.Options := Opt;
  end;
end;}

end.
