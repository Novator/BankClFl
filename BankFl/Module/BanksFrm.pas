unit BanksFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Grids, Db, DBTables, DBGrids, ExtCtrls, DBCtrls, BtrDS, Menus, CommCons,
  ComCtrls, StdCtrls, Buttons, SearchFrm, BankFrm, Common, Basbn, Utilits;

type
  TBanksForm = class(TDataBaseForm)
    BtnPanel: TPanel;
    OkBtn: TBitBtn;
    CancelBtn: TBitBtn;
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
    NameLabel: TLabel;
    SearchIndexComboBox: TComboBox;
    NameEdit: TEdit;
    EditPopupMenu: TPopupMenu;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure BtnPanelResize(Sender: TObject);
    procedure SearchBtnClick(Sender: TObject);
    procedure InsItemClick(Sender: TObject);
    procedure EditItemClick(Sender: TObject);
    procedure CopyItemClick(Sender: TObject);
    procedure DelItemClick(Sender: TObject);
    procedure SearchIndexComboBoxChange(Sender: TObject);
    procedure NameEditChange(Sender: TObject);
    procedure DBGridDblClick(Sender: TObject);
  private
    NpDataSet: TBtrDataSet;
    procedure UpdateRecord(CopyCurrent, New: Boolean);
  public
    SearchForm: TSearchForm;
  end;

var
  ObjList: TList;
  BanksForm: TBanksForm;

implementation

{$R *.DFM}

procedure TBanksForm.FormCreate(Sender: TObject);
begin
  ObjList.Add(Self);
  DataSource.DataSet := GlobalBase(biBank);
  NpDataSet := GlobalBase(biNp);

  DefineGridCaptions(DBGrid, PatternDir+'Banks.tab');

  SearchForm := TSearchForm.Create(Self);
  TakeMenuItems(OperItem, EditPopupMenu.Items);
  EditPopupMenu.Images := ChildMenu.Images;
  SearchIndexComboBox.ItemIndex := 0;
  SearchIndexComboBoxChange(nil);
end;

procedure TBanksForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if FormStyle=fsMDIChild then Action:=caFree;
end;

procedure TBanksForm.FormDestroy(Sender: TObject);
begin
  ObjList.Remove(Self);
  if Self=BanksForm then BanksForm := nil;
end;

procedure TBanksForm.BtnPanelResize(Sender: TObject);
const
  BtnDist=8;
begin
  CancelBtn.Left := BtnPanel.ClientWidth-CancelBtn.Width-2*BtnDist;
  OkBtn.Left := CancelBtn.Left-OkBtn.Width-BtnDist;
end;

procedure TBanksForm.SearchBtnClick(Sender: TObject);
begin
  SearchForm.ShowModal;
end;

(*
    brCod:    longint;			{БИК}
    brKs:     array[0..19] of char;	{К/С}
    brNpIder: longint;			{Идер нас.пункта}
    brType:   array[0..3] of char;	{Аббревиатура}
    brName:   array[0..39] of char;	{Наименование банка}

    npIder:   longint;			{Идер нас.пункта}
    npName:   array[0..24] of char;	{Наименование нас.пункта}
    npType:   array[0..4] of char;	{Аббревиатура}*)


procedure TBanksForm.UpdateRecord(CopyCurrent, New: Boolean);
const
  ProcTitle: PChar = 'Редактирование банка';
var
  BankForm: TBankForm;
  BankRec: TBankNewRec;
  NpRec, NpRec2: TNpRec;
  I,Err: LongInt;
  T: array[0..512] of Char;
  Sity: packed record stName: TSity; stType: TSityType end;
  Editing: Boolean;
begin
  if not DataSource.DataSet.IsEmpty or (New and not CopyCurrent) then
  begin
    BankForm := TBankForm.Create(Self);
    with BankForm do
    begin
      if CopyCurrent then
      begin
        TBankDataSet(DataSource.DataSet).GetBtrRecord(PChar(@BankRec));
        I:=BankRec.brNpIder;
        NpDataSet.LocateBtrRecordByIndex(I,0,bsEq);
        NpDataSet.GetBtrRecord(PChar(@NpRec))
      end
      else begin
        FillChar(BankRec,SizeOf(BankRec), #0);
        FillChar(NpRec,SizeOf(NpRec), #0);
      end;
      with BankRec,NpRec do
      begin
        {DosToWinL(brType,SizeOf(brType));}
        DosToWinL(brName,SizeOf(brName));
        DosToWinL(npType,SizeOf(npType));
        DosToWinL(npName,SizeOf(npName));

        BikEdit.Text := IntToStr(brCod);

        StrLCopy(T, brKs, SizeOf(brKs));
        KsEdit.Text := StrPas(T);
        {StrLCopy(T, brType, SizeOf(brType));
        TypeComboBox.Text := StrPas(T);}
        StrLCopy(T, brName, SizeOf(brName));
        NameMemo.Text := StrPas(T);
        StrLCopy(T, npName, SizeOf(npName));
        NpNameEdit.Text := StrPas(T);
        StrLCopy(T, npType, SizeOf(npType));
        NpTypeComboBox.Text := StrPas(T);
      end;
      Editing := True;
      while Editing and (ShowModal = mrOk) do
      begin
        Editing := False;
        FillChar(BankRec,SizeOf(BankRec), #0);
        FillChar(NpRec,SizeOf(NpRec), #0);
        with BankRec, NpRec do
        begin
          Val(BikEdit.Text,brCod,Err);
          StrPCopy(brKs,KsEdit.Text);
          {StrPCopy(brType,TypeComboBox.Text);}
          StrPCopy(brName,NameMemo.Text);
          StrPCopy(npName,NpNameEdit.Text);
          StrPCopy(npType,NpTypeComboBox.Text);

          {WinToDosL(brType,SizeOf(brType));}
          WinToDosL(brName,SizeOf(brName));
          WinToDosL(npName,SizeOf(npName));
          WinToDosL(npType,SizeOf(npType));
          with Sity do
          begin
            stName := npName;
            stType := npType;
          end;
        end;

        with NpDataSet do
        begin
          if LocateBtrRecordByIndex(Sity,1,bsEq) then
            GetBtrRecord(@NpRec)
          else begin
            GetLastRec(0, @NpRec2);
            NpRec.npIder := NpRec2.npIder+1;
            if AddBtrRecord(@NpRec,SizeOf(NpRec)) then
              MessageBox(Handle, 'Добавлен новый город', ProcTitle,
                MB_OK + MB_ICONINFORMATION)
            else
              MessageBox(Handle, 'Не удалось добавить новый город', ProcTitle,
                MB_OK + MB_ICONERROR)
          end;
        end;
        BankRec.brNpIder := NpRec.npIder;

        if New then begin
          if TBankDataSet(DataSource.DataSet).AddBtrRecord(PChar(@BankRec),
            SizeOf(BankRec))
          then
            DataSource.DataSet.Refresh
          else begin
            Editing := True;
            MessageDlg('',mtError,[mbOk,mbHelp],0);
            MessageBox(Handle, 'Невозможно добавить запись', ProcTitle,
              MB_OK + MB_ICONERROR)
          end;
        end else begin
          if TBankDataSet(DataSource.DataSet).UpdateBtrRecord(PChar(@BankRec),
            SizeOf(BankRec))
          then
            DataSource.DataSet.UpdateCursorPos
          else begin
            Editing := True;
            MessageBox(Handle, 'Невозможно изменить запись', ProcTitle,
              MB_OK + MB_ICONERROR)
          end;
        end;
      end;
      Free;
    end;
  end;
end;

procedure TBanksForm.InsItemClick(Sender: TObject);
begin
  UpdateRecord(False, True);
end;

procedure TBanksForm.EditItemClick(Sender: TObject);
begin
  UpdateRecord(True, False);
end;

procedure TBanksForm.CopyItemClick(Sender: TObject);
begin
  UpdateRecord(True, True)
end;

procedure TBanksForm.DelItemClick(Sender: TObject);
const
  ProcTitle: PChar = 'Удаление банка';
var
  BankRec: TBankNewRec;
begin
  if not DataSource.DataSet.IsEmpty then
  begin
    if MessageBox(Handle, 'Банк будет удален. Вы уверены?',
      ProcTitle, MB_YESNOCANCEL + MB_ICONQUESTION) = IDYES then
    begin
      with TBankDataSet(DataSource.DataSet) do begin
        GetBtrRecord(PChar(@BankRec));
        Delete;
        if not LocateBtrRecordByIndex(BankRec.brNpIder,1,bsEq) then
          if NpDataSet.LocateBtrRecordByIndex(BankRec.brNpIder,0,bsEq) then
          begin
            NpDataSet.Delete;
            MessageBox(Handle, 'Город удален из базы городов', ProcTitle,
              MB_OK + MB_ICONINFORMATION)
          end;
      end;
    end;
  end;
end;

procedure TBanksForm.SearchIndexComboBoxChange(Sender: TObject);
begin
  (DataSource.DataSet as TBtrDataSet).IndexNum:=SearchIndexComboBox.ItemIndex;
  case SearchIndexComboBox.ItemIndex of
    1: NameEdit.MaxLength := SizeOf(TSity);
    2: NameEdit.MaxLength := SizeOf(TBankNameNew);
    else NameEdit.MaxLength := 9;
  end;
end;

procedure TBanksForm.NameEditChange(Sender: TObject);
var
  Sity: TSity;
  BankName: TBankNameNew;
  I,J: Integer;
  S: string;
  NpRec: TNpRec;
begin
  case SearchIndexComboBox.ItemIndex of
    0:
    begin
      S := NameEdit.Text;
      Val(S, I, J);
      if J=0 then
      begin
        J := FillDigTo(I, 8);
        TBtrDataSet(DataSource.DataSet).LocateBtrRecordByIndex(J, 0, bsGe);
      end;
    end;
    1:
    begin
      FillChar(Sity, SizeOf(Sity), #0);
      StrPCopy(Sity, NameEdit.Text);
      WinToDos(Sity);
      with (DataSource.DataSet as TBankDataSet) do
        if NpDataSet.LocateBtrRecordByIndex(Sity, 1, bsGe) then
        begin
          NpDataSet.GetBtrRecord(PChar(@NpRec));
          I := NpRec.npIder;
          LocateBtrRecordByIndex(I, 1, bsEq);
        end;
    end;
    2:
    begin
      FillChar(BankName, SizeOf(BankName), #0);
      StrPCopy(BankName, NameEdit.Text);
      WinToDos(BankName);
      (DataSource.DataSet as TBtrDataSet).LocateBtrRecordByIndex(BankName, 2,
        bsGe);
    end;
  end;
end;

procedure TBanksForm.DBGridDblClick(Sender: TObject);
begin
  if FormStyle=fsMDIChild then EditItemClick(Sender)
  else ModalResult := mrOk;
end;

end.
