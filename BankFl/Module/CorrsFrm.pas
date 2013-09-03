unit CorrsFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Grids, Db, DBTables, DBGrids, ExtCtrls, DBCtrls, Menus,
  StdCtrls, Buttons, ComCtrls, Common, SearchFrm, Basbn, Utilits,
  BtrDS, BankCnBn, CorrFrm, Registr, CommCons;

type
  TCorrsForm = class(TDataBaseForm)
    DataSource: TDataSource;
    DBGrid: TDBGrid;
    StatusBar: TStatusBar;
    BtnPanel: TPanel;
    OkBtn: TBitBtn;
    CancelBtn: TBitBtn;
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
    EditBreaker2: TMenuItem;
    RemoveDataItem: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure NameEditChange(Sender: TObject);
    procedure SearchIndexComboBoxChange(Sender: TObject);
    procedure BtnPanelResize(Sender: TObject);
    procedure FindItemClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure InsItemClick(Sender: TObject);
    procedure EditItemClick(Sender: TObject);
    procedure DelItemClick(Sender: TObject);
    procedure CopyItemClick(Sender: TObject);
    procedure DBGridDblClick(Sender: TObject);
    procedure AbonStatItemClick(Sender: TObject);
    procedure RemoveDataItemClick(Sender: TObject);
  private
    procedure UpdateCorr(CopyCurrent, New: Boolean);
  public
    SearchForm: TSearchForm;
    function NodeIsExist(ANode: Word; CurIder: Integer): Boolean;
  end;

var
  ObjList: TList;
const
  CorrsForm: TCorrsForm = nil;

implementation

uses AbonStatFrm, MoveDataFrm;

const
  CurL: Byte = 255;

{$R *.DFM}

procedure TCorrsForm.FormCreate(Sender: TObject);
var
  UserRec: TUserRec;
begin
  ObjList.Add(Self);
  DataSource.DataSet := {GlobalBase(biCorr) as TCorrDataSet}nil;
  DefineGridCaptions(DBGrid, PatternDir+'Corrs.tab');
  SearchForm := TSearchForm.Create(Self);
  SearchForm.SourceDBGrid := DBGrid;
  SearchIndexComboBox.ItemIndex := 1;
  SearchIndexComboBoxChange(Sender);
  TakeMenuItems(OperItem, EditPopupMenu.Items);
  EditPopupMenu.Images := ChildMenu.Images;

  CurrentUser(UserRec);
  CurL := UserRec.urLevel;
end;

procedure TCorrsForm.FormDestroy(Sender: TObject);
begin
  ObjList.Remove(Self);
  if Self=CorrsForm then
    CorrsForm := nil;
end;

procedure TCorrsForm.NameEditChange(Sender: TObject);
var
  I, Err: Integer;
  Login: array[0..9] of Char;
  S: string;
begin
  case SearchIndexComboBox.ItemIndex of
    0:
    begin
      Val(NameEdit.Text, I, Err);
      TBtrDataSet(DataSource.DataSet).LocateBtrRecordByIndex(I, 0, bsGe);
    end;
    1:
    begin
      S := UpperCase(NameEdit.Text);
      StrPLCopy(Login, S, SizeOf(Login));
      (DataSource.DataSet as TBtrDataSet).LocateBtrRecordByIndex(Login, 1, bsGe);
    end;
  end;
end;

procedure TCorrsForm.SearchIndexComboBoxChange(Sender: TObject);
var
  AllowMultiSel: Boolean;
  Opt: TDBGridOptions;
begin
  (DataSource.DataSet as TBtrDataSet).IndexNum := SearchIndexComboBox.ItemIndex;
  case SearchIndexComboBox.ItemIndex of
    0: NameEdit.MaxLength := 12;
    else
      NameEdit.MaxLength := 8;
  end;
end;

const
  BtnDist=6;

procedure TCorrsForm.BtnPanelResize(Sender: TObject);
begin
  CancelBtn.Left:=BtnPanel.ClientWidth-CancelBtn.Width-2*BtnDist;
  OkBtn.Left:=CancelBtn.Left-OkBtn.Width-BtnDist;
end;

procedure TCorrsForm.FindItemClick(Sender: TObject);
begin
  SearchForm.ShowModal;
end;

procedure TCorrsForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if FormStyle=fsMDIChild then
    Action:=caFree;
end;

function TCorrsForm.NodeIsExist(ANode: Word; CurIder: Integer): Boolean;
var
  {CorrRec: TCorrRec;}
  Len, I, Res: Integer;
begin
  Result := False;
  (*
  with TCorrDataSet(DataSource.DataSet).BtrBase do
  begin
    Res := GetFirst(CorrRec, Len, I, 0);
    while (Res=0) and not Result do
    begin
      Result := (CorrRec.crNode = ANode) and (CorrRec.crIder<>CurIder);
      Res := GetNext(CorrRec, Len, I, 0);
    end;
  end;
  *)
end;

procedure TCorrsForm.UpdateCorr(CopyCurrent, New: Boolean);
const
  MesTitle: PChar = 'Редактирование';
var
  CorrForm: TCorrForm;
  {CorrRec: TCorrRec;}
  I, L: Integer;
  T: array[0..511] of Char;
  Editing: Boolean;
begin
  (*
  if not DataSource.DataSet.IsEmpty or (New and not CopyCurrent) then
  begin
    CorrForm := TCorrForm.Create(Self);
    with CorrForm do
    begin
      {WayComboBox.Enabled := CurL<1;
      CryptCheckBox.Enabled := WayComboBox.Enabled;}
      if CopyCurrent then
        TCorrDataSet(DataSource.DataSet).GetBtrRecord(PChar(@CorrRec))
      else
        FillChar(CorrRec, SizeOf(CorrRec), #0);
      with CorrRec do
      begin
        NodeEdit.Text := IntToStr(crNode);
        LoginEdit.Text := crName;
        BranchCheckBox.Checked := crType<>0;
        {if (crWay=0) and not New then
          WayComboBox.ItemIndex := 0
        else
          WayComboBox.ItemIndex := 1;}
        SendLockCheckBox.Checked := crLock and 1 > 0;
        RecieveLockCheckBox.Checked := crLock and 2 > 0;
        if New then
          crSize := 4096;
        SizeComboBox.Text := IntToStr(crSize);
        {CryptCheckBox.Checked := (crCrypt<>0) or New;}

        DosToWin(crVar);
        StrLCopy(T, crVar, SizeOf(crVar));
        NameEdit.Text := T;
      end;
      Editing := True;
      while Editing and (ShowModal = mrOk) do
      begin
        with CorrRec do
        begin
          Val(NodeEdit.Text, crNode, I);
          Editing := (I<>0) or (crNode=BroadcastNode) or (crNode<1);
          if Editing then
          begin
            ActiveControl := NodeEdit;
            MessageBox(Handle, 'Ошибочный номер узла',
              MesTitle, MB_OK + MB_ICONWARNING)
          end
          else begin
            Val(SizeComboBox.Text, crSize, I);
            Editing := (I<>0) or (crSize<200);
            if Editing then
            begin
              ActiveControl := SizeComboBox;
              MessageBox(Handle, 'Неверно указан размер пакета',
                MesTitle, MB_OK + MB_ICONWARNING)
            end
            else begin
              FillChar(crName, SizeOf(crName), #0);
              StrPLCopy(crName, LoginEdit.Text, SizeOf(crName)-1);
              if BranchCheckBox.Checked then
                crType := 1
              else
                crType := 0;
              {if WayComboBox.ItemIndex=0 then
                crWay := 0
              else}
                crWay := 1;
              crLock := 0;
              if SendLockCheckBox.Checked then
                crLock := crLock or 1;
              if RecieveLockCheckBox.Checked then
                crLock := crLock or 2;
              {if CryptCheckBox.Checked then}
                crCrypt := 1
              {else
                crCrypt := 0};
              StrPTCopy(T, NameEdit.Text, SizeOf(T));
              WinToDos(T);
              StrLCopy(crVar, T, SizeOf(crVar));
              L := SizeOf(TCorrRec)-SizeOf(crVar)+StrLen(crVar)+1;
              Editing := False;
            end;
          end;
        end;
        if New then
          I := 0
        else
          I := CorrRec.crIder;
        Editing := Editing
          or (NodeIsExist(CorrRec.crNode, I) and (MessageBox(Handle,
            'Корреспондент с таким номером узла уже существует. Игнорировать?',
            MesTitle, MB_YESNOCANCEL or MB_ICONWARNING
            or MB_DEFBUTTON2) <> ID_YES));
        if not Editing then
        begin
          if New then
          begin
            begin
              MakeRegNumber(rnPaydoc, I);
              CorrRec.crIder := I;
              if TExtBtrDataSet(DataSource.DataSet).AddBtrRecord(PChar(@CorrRec),
                L) then
              begin
                ProtoMes(plInfo, MesTitle, 'Добавлен корреспондент Id='+IntToStr(CorrRec.crIder));
                DBGrid.SelectedRows.Clear;
                DataSource.DataSet.Refresh;
              end
              else
                Editing := MessageBox(Handle, 'Не удается добавить запись. Повторить?',
                  MesTitle, MB_YESNOCANCEL or MB_ICONWARNING) = ID_YES;
            end;
          end
          else begin
            I := CorrRec.crIder;
            if TBtrDataSet(DataSource.DataSet).LocateBtrRecordByIndex(I, 0, bsEq) then
            begin
              if TExtBtrDataSet(DataSource.DataSet).UpdateBtrRecord(PChar(@CorrRec),
                L) then
              begin
                ProtoMes(plInfo, MesTitle, 'Изменен корреспондент Id='+IntToStr(CorrRec.crIder));
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
        end;
      end;
      Free;
    end;
  end;
  *)
end;

procedure TCorrsForm.InsItemClick(Sender: TObject);
begin
  UpdateCorr(False, True);
end;

procedure TCorrsForm.EditItemClick(Sender: TObject);
begin
  if FormStyle = fsMDIChild then
    UpdateCorr(True, False)
  else
    ModalResult := mrOk;
end;

procedure TCorrsForm.CopyItemClick(Sender: TObject);
begin
  UpdateCorr(True, True)
end;

procedure TCorrsForm.DelItemClick(Sender: TObject);
const
  MesTitle: PChar = 'Удаление';
var
  N: Integer;
  //CorrRec: TCorrRec;
begin
  if not DataSource.DataSet.IsEmpty then
  begin
    DBGrid.SelectedRows.Refresh;
    N := DBGrid.SelectedRows.Count;
    if (N<2) and (MessageBox(Handle, PChar('Корреспондент будет удален. Вы уверены?'),
      MesTitle, MB_YESNOCANCEL or MB_ICONQUESTION) = IDYES)
      or (N>=2) and (MessageBox(Handle, PChar('Будет удалено корреспондентов: '
      +IntToStr(DBGrid.SelectedRows.Count)+#13#10'Вы уверены?'),
      MesTitle, MB_YESNOCANCEL or MB_ICONQUESTION) = IDYES) then
    begin
      if N>0 then
      begin
        DBGrid.SelectedRows.Delete;
        DBGrid.SelectedRows.Refresh;
        ProtoMes(plInfo, MesTitle, 'Удалено корреспондентов N='+IntToStr(N));
      end
      else begin
        {TCorrDataSet(DataSource.DataSet).GetBtrRecord(PChar(@CorrRec));
        DataSource.DataSet.Delete;
        ProtoMes(plInfo, MesTitle, 'Удален корреспондент Id='+IntToStr(CorrRec.crIder));}
      end;
    end;
  end;
end;

procedure TCorrsForm.DBGridDblClick(Sender: TObject);
begin
  EditItemClick(Sender)
end;

procedure TCorrsForm.AbonStatItemClick(Sender: TObject);
begin
  if AbonStatForm=nil then
    AbonStatForm := TAbonStatForm.Create(Self);
  AbonStatForm.Show;
end;

procedure TCorrsForm.RemoveDataItemClick(Sender: TObject);
begin
  if MoveDataForm=nil then
    MoveDataForm := TMoveDataForm.Create(Sender as TComponent);
  MoveDataForm.ShowModal;
  MoveDataForm.Free;
end;

end.
