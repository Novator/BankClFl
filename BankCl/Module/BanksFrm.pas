unit BanksFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Grids, Db, DBTables, DBGrids, ExtCtrls, DBCtrls, BtrDS, Menus, CommCons,
  ComCtrls, StdCtrls, Buttons, SearchFrm, BankFrm, Common, Bases, Utilits;

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
    EditBreaker2: TMenuItem;
    ExportItem: TMenuItem;
    SaveDialog: TSaveDialog;
    AbortBtn: TBitBtn;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure SearchBtnClick(Sender: TObject);
    procedure InsItemClick(Sender: TObject);
    procedure EditItemClick(Sender: TObject);
    procedure CopyItemClick(Sender: TObject);
    procedure DelItemClick(Sender: TObject);
    procedure SearchIndexComboBoxChange(Sender: TObject);
    procedure NameEditChange(Sender: TObject);
    procedure DBGridDblClick(Sender: TObject);
    procedure ExportItemClick(Sender: TObject);
    procedure AbortBtnClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormResize(Sender: TObject);
  private
    NpDataSet, BankDataSet: TExtBtrDataSet;
    procedure UpdateRecord(CopyCurrent, New: Boolean);
  public
    SearchForm: TSearchForm;
    procedure ShowMes(S: string);
    procedure TakeTabPrintData(var PrintDocRec: TPrintDocRec; var FormList: TList); override;
  end;

var
  ObjList: TList;
  BanksForm: TBanksForm;

implementation

{$R *.DFM}

procedure TBanksForm.FormCreate(Sender: TObject);
begin
  ObjList.Add(Self);
  BankDataSet := GlobalBase(biBank);
  DataSource.DataSet := BankDataSet;
  NpDataSet := GlobalBase(biNp);

  DefineGridCaptions(DBGrid, PatternDir+'Banks.tab');

  SearchForm := TSearchForm.Create(Self);
  EditPopupMenu.Images := ChildMenu.Images;
  SearchIndexComboBox.ItemIndex := 0;
  SearchIndexComboBoxChange(nil);
end;

procedure TBanksForm.ShowMes(S: string);
begin
  StatusBar.SimpleText := S;
end;

procedure TBanksForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if FormStyle=fsMDIChild then
    Action := caFree;
end;

procedure TBanksForm.FormDestroy(Sender: TObject);
begin
  ObjList.Remove(Self);
  if Self=BanksForm then
    BanksForm := nil;
end;

procedure TBanksForm.TakeTabPrintData(var PrintDocRec: TPrintDocRec; var FormList: TList);
begin
  inherited;
  PrintDocRec.DBGrid := Self.DBGrid;
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
  if FormStyle = fsMDIChild then
    UpdateRecord(True, False)
  else
    ModalResult := mrOk;
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
  EditItemClick(Sender)
end;

procedure TBanksForm.ExportItemClick(Sender: TObject);
const
  MesTitle: PChar = 'Экспорт базы банков';
var
  FN, S: string;
  F: TextFile;
  Res, Len, I, J, C: Integer;
  BankRec: TBankNewRec;
  NpRec: TNpRec;
begin
  if SaveDialog.Execute and (BankDataSet<>nil) and (NpDataSet<>nil) then
  begin
    FN := SaveDialog.FileName;
    AssignFile(F, FN);
    {$I-} Rewrite(F); {$I+}
    if IOResult=0 then
    begin
      C := 0;
      try
        ShowMes('Выгрузка банков...');
        WriteLn(F, ';BIK KS|TT TOWN|BANKTYPE|BANKNAME');
        AbortBtn.Visible := True;
        Len := SizeOf(BankRec);
        Res := BankDataSet.BtrBase.GetFirst(BankRec, Len, I, 0);
        while (Res=0) and AbortBtn.Visible do
        begin
          Inc(C);
          S := FillZeros(BankRec.brCod, 9)+' '+BankRec.brKs+'|';
          J := BankRec.brNpIder;
          Len := SizeOf(NpRec);
          Res := NpDataSet.BtrBase.GetEqual(NpRec, Len, J, 0);
          if Res=0 then
            S := S + NpRec.npType + ' ' + NpRec.npName;
          S := S + '|'+{BankRec.brType+'|'+}BankRec.brName;
          WriteLn(F, S);
          Len := SizeOf(BankRec);
          Res := BankDataSet.BtrBase.GetNext(BankRec, Len, I, 0);
          Application.ProcessMessages;
        end;
      finally
        CloseFile(F);
        if AbortBtn.Visible then
        begin
          AbortBtn.Visible := False;
          ShowMes('Выгрузка успешно завершена');
          MessageBox(Handle, PChar('Выгружено в файл ['+FN+']'
            +#13#10'Всего банков: '+IntToStr(C)), MesTitle, MB_OK or MB_ICONINFORMATION);
          ShowMes('');
        end
        else
          ShowMes('Выгрузка прервана');
      end;
    end
    else
      MessageBox(Handle, PChar('Не могу создать файл ['+FN+']'), MesTitle, MB_OK or MB_ICONERROR);
  end;
end;

procedure TBanksForm.AbortBtnClick(Sender: TObject);
begin
  AbortBtn.Visible := False;
end;

procedure TBanksForm.FormShow(Sender: TObject);
begin
  if FormStyle<>fsMDIChild then
  begin
    EditBreaker2.Visible := False;
    ExportItem.Visible := False;
  end;
  TakeMenuItems(OperItem, EditPopupMenu.Items);
end;

procedure TBanksForm.FormResize(Sender: TObject);
const
  BtnDist=8;
begin
  CancelBtn.Left := BtnPanel.ClientWidth-CancelBtn.Width-2*BtnDist;
  OkBtn.Left := CancelBtn.Left-OkBtn.Width-BtnDist;
end;

end.
