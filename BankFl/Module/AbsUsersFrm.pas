unit AbsUsersFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Grids, Db, DBTables, DBGrids, ExtCtrls, DBCtrls, BtrDS, Menus,
  ComCtrls, StdCtrls, Buttons, SearchFrm, AbsUserFrm, Common, Basbn,
  Utilits, BankCnBn, DbfDataSet, Registr, Orakle;

type
  TAbsUsersForm = class(TDataBaseForm)
    StatusBar: TStatusBar;
    DBGrid: TDBGrid;
    DataSource: TDataSource;
    ChildMenu: TMainMenu;
    OperItem: TMenuItem;
    InsItem: TMenuItem;
    EditItem: TMenuItem;
    CopyItem: TMenuItem;
    DelItem: TMenuItem;
    EditBreaker: TMenuItem;
    FindItem: TMenuItem;
    EditPopupMenu: TPopupMenu;
    EditBreaker2: TMenuItem;
    LoadNewFromQrmItem: TMenuItem;
    LoadAndUpdateItem: TMenuItem;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure SearchBtnClick(Sender: TObject);
    procedure InsItemClick(Sender: TObject);
    procedure EditItemClick(Sender: TObject);
    procedure CopyItemClick(Sender: TObject);
    procedure DelItemClick(Sender: TObject);
    procedure DBGridDblClick(Sender: TObject);
    procedure LoadNewFromQrmItemClick(Sender: TObject);
    procedure LoadAndUpdateItemClick(Sender: TObject);
  private
    FOperDataSet: TOperDataSet;
    procedure UpdateRecord(CopyCurrent, New: Boolean);
  public
    SearchForm: TSearchForm;
  end;

var
  ObjList: TList;
  AbsUsersForm: TAbsUsersForm;

implementation

{$R *.DFM}

var
  KliringBikMask: string = '';

procedure TAbsUsersForm.FormCreate(Sender: TObject);
begin
  ObjList.Add(Self);
  FOperDataSet := GlobalBase(biOper) as TOperDataSet;
  DataSource.DataSet := FOperDataSet;
  DefineGridCaptions(DBGrid, PatternDir+'Oper.tab');

  SearchForm := TSearchForm.Create(Self);
  SearchForm.SourceDBGrid := DBGrid;
  TakeMenuItems(OperItem, EditPopupMenu.Items);
  EditPopupMenu.Images := ChildMenu.Images;

  KliringBikMask := DecodeMask('$(KliringBikMask)', 5, GetUserNumber);
  while Length(KliringBikMask)<9 do
    KliringBikMask := KliringBikMask + '?';
end;

procedure TAbsUsersForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if FormStyle=fsMDIChild then
    Action:=caFree;
end;

procedure TAbsUsersForm.FormDestroy(Sender: TObject);
begin
  ObjList.Remove(Self);
  if Self=AbsUsersForm then
    AbsUsersForm := nil;
end;

procedure TAbsUsersForm.SearchBtnClick(Sender: TObject);
begin
  SearchForm.ShowModal;
end;

procedure TAbsUsersForm.UpdateRecord(CopyCurrent, New: Boolean);
const
  ProcTitle: PChar = 'Редактирование опера';
var
  AbsUserForm: TAbsUserForm;
  QrmOperRec: TQrmOperRec;
  Editing: Boolean;
begin
  if not DataSource.DataSet.IsEmpty or (New and not CopyCurrent) then
  begin
    AbsUserForm := TAbsUserForm.Create(Self);
    with AbsUserForm do
    begin
      if CopyCurrent then
      begin
        FOperDataSet.GetBtrRecord(PChar(@QrmOperRec));
        DosToWinL(QrmOperRec.onName, SizeOf(QrmOperRec.onName));
        QrmNameEdit.Text := OrGetUserNameByCode(QrmOperRec.onIder);
      end
      else
        FillChar(QrmOperRec, SizeOf(QrmOperRec), #0);
      with QrmOperRec do
      begin
        IdEdit.Text := IntToStr(onIder);
        NameEdit.Text := onName;
        if Length(NameEdit.Text)>SizeOf(onName) then
          NameEdit.Text := Copy(NameEdit.Text, 1, SizeOf(onName));
      end;
      Editing := True;
      while Editing and (ShowModal = mrOk) do
      begin
        Editing := False;
        FillChar(QrmOperRec, SizeOf(QrmOperRec), #0);
        with QrmOperRec do
        begin
          onIder := StrToInt(IdEdit.Text);
          StrPLCopy(onName, NameEdit.Text, SizeOf(onName)-1);
          WinToDos(onName);
        end;
        if New then begin
          if FOperDataSet.AddBtrRecord(PChar(@QrmOperRec),
            SizeOf(QrmOperRec))
          then
            FOperDataSet.Refresh
          else begin
            Editing := True;
            MessageDlg('',mtError,[mbOk,mbHelp],0);
            MessageBox(Handle, 'Невозможно добавить запись', ProcTitle,
              MB_OK or MB_ICONERROR)
          end;
        end else begin
          if FOperDataSet.UpdateBtrRecord(PChar(@QrmOperRec),
            SizeOf(QrmOperRec))
          then
            FOperDataSet.UpdateCursorPos
          else begin
            Editing := True;
            MessageBox(Handle, 'Невозможно изменить запись', ProcTitle,
              MB_OK or MB_ICONERROR)
          end;
        end;
      end;
      Free;
    end;
  end;
end;

procedure TAbsUsersForm.InsItemClick(Sender: TObject);
begin
  UpdateRecord(False, True);
end;

procedure TAbsUsersForm.EditItemClick(Sender: TObject);
begin
  UpdateRecord(True, False);
end;

procedure TAbsUsersForm.CopyItemClick(Sender: TObject);
begin
  UpdateRecord(True, True)
end;

procedure TAbsUsersForm.DelItemClick(Sender: TObject);
const
  MesTitle: PChar = 'Удаление';
var
  N: Integer;
begin
  if not DataSource.DataSet.IsEmpty then
  begin
    DBGrid.SelectedRows.Refresh;
    N := DBGrid.SelectedRows.Count;
    if (N<2) and (MessageBox(Handle, PChar('Опер будет удален. Вы уверены?'),
      MesTitle, MB_YESNOCANCEL or MB_ICONQUESTION) = IDYES)
      or (N>=2) and (MessageBox(Handle, PChar('Будет удалено оперов: '
      +IntToStr(DBGrid.SelectedRows.Count)+#13#10'Вы уверены?'),
      MesTitle, MB_YESNOCANCEL or MB_ICONQUESTION) = IDYES) then
    begin
      if N>0 then
      begin
        DBGrid.SelectedRows.Delete;
        DBGrid.SelectedRows.Refresh;
      end
      else
        FOperDataSet.Delete;
    end;
  end;
end;

procedure TAbsUsersForm.DBGridDblClick(Sender: TObject);
begin
  if FormStyle=fsMDIChild then
    EditItemClick(Sender)
  else
    ModalResult := mrOk;
end;

procedure TAbsUsersForm.LoadNewFromQrmItemClick(Sender: TObject);
const
  MesTitle: PChar = 'Загрузка новых операторов';
var
  I, K, J, N, Len, Res: Integer;
  S: string;
  QrmOperRec: TQrmOperRec;
begin
  if OraBase.OrDb.Connected then
  begin
    K := 0;
    J := 0;
    N := 0;
    if (Sender=nil) and (MessageBox(Handle, 'Вы уверны, что хотите заменить все имена?',
      MesTitle, MB_YESNOCANCEL or MB_DEFBUTTON2	or MB_ICONINFORMATION)<>ID_YES)
    then
      Sender := Self;
    with OraBase, OrQuery3 do
    begin
      SQL.Clear;
      SQL.Add('Select xu$id,xu$name from '+OrScheme+'.x$users');
      Open;
      First;
      while not Eof do
      begin
        Inc(K);
        I := FieldByName('xu$id').AsInteger;
        Len := SizeOf(QrmOperRec);
        Res := FOperDataSet.BtrBase.GetEqual(QrmOperRec, Len, I, 0);
        if (Res<>0) or (Sender=nil) then
        begin
          S := Trim(FieldbyName('xu$name').AsString);
          with QrmOperRec do
          begin
            onIder := I;
            StrPLCopy(onName, S, SizeOf(onName)-1);
            WinToDos(onName);
            Len := 4+StrLen(onName)+1;
          end;
          if Res=0 then
          begin
            Res := FOperDataSet.BtrBase.Update(QrmOperRec, Len, I, 0);
            if Res=0 then
              Inc(N);
          end
          else begin
            Res := FOperDataSet.BtrBase.Insert(QrmOperRec, Len, I, 0);
            if Res=0 then
              Inc(J);
          end;
        end;
        Next;
      end;
      FOperDataSet.Refresh;
    end;
    MessageBox(Handle, PChar('Всего просмотрено: '+IntToStr(K)
      +#13#10'добавлено новых: '+IntToStr(J)
      +#13#10'изменено: '+IntToStr(N)), MesTitle, MB_OK or MB_ICONINFORMATION);
  end;
end;

procedure TAbsUsersForm.LoadAndUpdateItemClick(Sender: TObject);
begin
  LoadNewFromQrmItemClick(nil);
end;

end.
