unit PostAbonsFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Grids, Db, DBTables, DBGrids, ExtCtrls, DBCtrls, Menus,
  StdCtrls, Buttons, ComCtrls, SearchFrm, Utilits, CommCons,
  BtrDS, BankCnBn, Registr, AbonFrm, ActnList, Common;

type
  TAbonsForm = class(TDataBaseForm)
    DataSource: TDataSource;
    DBGrid: TDBGrid;
    BtnPanel: TPanel;
    NameEdit: TEdit;
    SearchIndexComboBox: TComboBox;
    ChildMenu: TMainMenu;
    OperItem: TMenuItem;
    FindItem: TMenuItem;
    InsItem: TMenuItem;
    DelItem: TMenuItem;
    EditBreaker: TMenuItem;
    NameLabel: TLabel;
    EditItem: TMenuItem;
    CopyItem: TMenuItem;
    EditPopupMenu: TPopupMenu;
    EditBreaker1: TMenuItem;
    AbonStatItem: TMenuItem;
    ActionList: TActionList;
    NewAction: TAction;
    EditAction: TAction;
    CopyAction: TAction;
    DelAction: TAction;
    FindAction: TAction;
    StatAction: TAction;
    N1: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure NameEditChange(Sender: TObject);
    procedure SearchIndexComboBoxChange(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure NewActionExecute(Sender: TObject);
    procedure EditActionExecute(Sender: TObject);
    procedure CopyActionExecute(Sender: TObject);
    procedure DelActionExecute(Sender: TObject);
    procedure FindActionExecute(Sender: TObject);
    procedure StatActionExecute(Sender: TObject);
  private
    procedure UpdateAbon(CopyCurrent, New: Boolean);
  public
    SearchForm: TSearchForm;
    function NodeIsExist(ANode: Word; CurIder: Integer): Boolean;
  end;

const
  AbonsForm: TAbonsForm = nil;

implementation

uses
  PostMachineFrm;

{$R *.DFM}

var
  AbonIdDataSet: TExtBtrDataSet = nil;
  AbonDataSet: TExtBtrDataSet = nil;

procedure TAbonsForm.FormCreate(Sender: TObject);
begin
  AbonIdDataSet := GetGlobalBase(biAbonId) as TExtBtrDataSet;
  AbonDataSet := GetGlobalBase(biAbon) as TExtBtrDataSet;
  DataSource.DataSet := AbonDataSet;
  DefineGridCaptions(DBGrid, PatternDir+'Abons.tab');
  {with PostMachineForm do
  begin
    AddToolBtn(nil, Self);
    AddToolBtn(NewAction, Self);
    AddToolBtn(EditAction, Self);
    AddToolBtn(CopyAction, Self);
    AddToolBtn(DelAction, Self);
    AddToolBtn(nil, Self);
    AddToolBtn(FindAction, Self);
    AddToolBtn(nil, Self);
    AddToolBtn(StatAction, Self);
  end;}
  SearchForm := TSearchForm.Create(Self);
  SearchForm.SourceDBGrid := DBGrid;
  SearchIndexComboBox.ItemIndex := 1;
  SearchIndexComboBoxChange(Sender);
end;

procedure TAbonsForm.FormDestroy(Sender: TObject);
begin
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
      TBtrDataSet(DataSource.DataSet).LocateBtrRecordByIndex(I, 0, bsGe);
    end;
    1,2:
    begin
      S := UpperCase(NameEdit.Text);
      StrPLCopy(Login, S, SizeOf(Login));
      (DataSource.DataSet as TBtrDataSet).LocateBtrRecordByIndex(Login, 1, bsGe);
    end;
  end;
end;

procedure TAbonsForm.SearchIndexComboBoxChange(Sender: TObject);
begin
  (DataSource.DataSet as TBtrDataSet).IndexNum := SearchIndexComboBox.ItemIndex;
  case SearchIndexComboBox.ItemIndex of
    0: NameEdit.MaxLength := 12;
    else
      NameEdit.MaxLength := 8;
  end;
end;

procedure TAbonsForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action:=caFree;
end;

function TAbonsForm.NodeIsExist(ANode: Word; CurIder: Integer): Boolean;
var
  AbonentRec: TAbonentRec;
  Len, I, Res: Integer;
begin
  Result := False;
  with TExtBtrDataSet(DataSource.DataSet).BtrBase do
  begin
    Res := GetFirst(AbonentRec, Len, I, 0);
    while (Res=0) and not Result do
    begin
      Result := (AbonentRec.abNode = ANode) and (AbonentRec.abIder<>CurIder);
      Res := GetNext(AbonentRec, Len, I, 0);
    end;
  end;
end;

procedure TAbonsForm.UpdateAbon(CopyCurrent, New: Boolean);
const
  MesTitle: PChar = 'Редактирование';
var
  AbonForm: TAbonForm;
  AbonentRec: TAbonentRec;
  AbonIdRec, AbonIdRec2: TAbonIdRec;
  L, Res, I, Id: Integer;
  T: array[0..511] of Char;
  Editing: Boolean;
begin
  AbonIdDataSet := GetGlobalBase(biAbonId) as TExtBtrDataSet;
  if not AbonDataSet.IsEmpty or (New and not CopyCurrent) then
  begin
    AbonForm := TAbonForm.Create(Self);
    with AbonForm do
    begin
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

procedure TAbonsForm.NewActionExecute(Sender: TObject);
begin
  UpdateAbon(False, True);
end;

procedure TAbonsForm.EditActionExecute(Sender: TObject);
begin
  UpdateAbon(True, False)
end;

procedure TAbonsForm.CopyActionExecute(Sender: TObject);
begin
  UpdateAbon(True, True)
end;

procedure TAbonsForm.DelActionExecute(Sender: TObject);
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

procedure TAbonsForm.FindActionExecute(Sender: TObject);
begin
  SearchForm.ShowModal;
end;

procedure TAbonsForm.StatActionExecute(Sender: TObject);
begin
  {if AbonStatForm=nil then
    AbonStatForm := TAbonStatForm.Create(Self);
  AbonStatForm.Show;}
end;

end.
