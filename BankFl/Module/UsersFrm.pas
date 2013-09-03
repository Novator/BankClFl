unit UsersFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Grids, Db, DBTables, DBGrids, ExtCtrls, DBCtrls, BtrDS, Menus,
  ComCtrls, StdCtrls, Buttons, SearchFrm, TransFrm, Common, Basbn,
  Utilits, BankCnBn, DbfDataSet, Registr;

type
  TTransportsForm = class(TDataBaseForm)
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
    LoadItem: TMenuItem;
    OpenDialog: TOpenDialog;
    SaveDialog: TSaveDialog;
    SaveItem: TMenuItem;
    BankDataSet: TDbfDataSet;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure SearchBtnClick(Sender: TObject);
    procedure InsItemClick(Sender: TObject);
    procedure EditItemClick(Sender: TObject);
    procedure CopyItemClick(Sender: TObject);
    procedure DelItemClick(Sender: TObject);
    procedure DBGridDblClick(Sender: TObject);
    procedure LoadItemClick(Sender: TObject);
    procedure SaveItemClick(Sender: TObject);
  private
    FTransDataSet: TTransDataSet;
    procedure UpdateRecord(CopyCurrent, New: Boolean);
  public
    SearchForm: TSearchForm;
  end;

var
  ObjList: TList;
  TransportsForm: TTransportsForm;

implementation

{$R *.DFM}

var
  KliringBikMask: string = '';

procedure TTransportsForm.FormCreate(Sender: TObject);
begin
  ObjList.Add(Self);
  FTransDataSet := GlobalBase(biTrans) as TTransDataSet;
  DataSource.DataSet := FTransDataSet;
  DefineGridCaptions(DBGrid, PatternDir+'Trans.tab');

  SearchForm := TSearchForm.Create(Self);
  SearchForm.SourceDBGrid := DBGrid;
  TakeMenuItems(OperItem, EditPopupMenu.Items);
  EditPopupMenu.Images := ChildMenu.Images;

  KliringBikMask := DecodeMask('$(KliringBikMask)', 5, GetUserNumber);
  while Length(KliringBikMask)<9 do
    KliringBikMask := KliringBikMask + '?';
end;

procedure TTransportsForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if FormStyle=fsMDIChild then
    Action:=caFree;
end;

procedure TTransportsForm.FormDestroy(Sender: TObject);
begin
  ObjList.Remove(Self);
  if Self=TransportsForm then
    TransportsForm := nil;
end;

procedure TTransportsForm.SearchBtnClick(Sender: TObject);
begin
  SearchForm.ShowModal;
end;

procedure TTransportsForm.UpdateRecord(CopyCurrent, New: Boolean);
const
  ProcTitle: PChar = 'Редактирование банка';
var
  TransForm: TTransForm;
  TransRec: TTransRec;
  Editing: Boolean;
begin
  if not DataSource.DataSet.IsEmpty or (New and not CopyCurrent) then
  begin
    TransForm := TTransForm.Create(Self);
    with TransForm do
    begin
      if CopyCurrent then
        FTransDataSet.GetBtrRecord(PChar(@TransRec))
      else
        FillChar(TransRec,SizeOf(TransRec), #0);
      with TransRec do
      begin
        BikEdit.Text := IntToStr(sbBik);
        WayComboBox.ItemIndex := sbState;
      end;
      Editing := True;
      while Editing and (ShowModal = mrOk) do
      begin
        Editing := False;
        FillChar(TransRec, SizeOf(TransRec), #0);
        with TransRec do
        begin
          sbBik := StrToInt(BikEdit.Text);
          sbState := WayComboBox.ItemIndex;
        end;
        if New then begin
          if FTransDataSet.AddBtrRecord(PChar(@TransRec),
            SizeOf(TransRec))
          then
            FTransDataSet.Refresh
          else begin
            Editing := True;
            MessageDlg('',mtError,[mbOk,mbHelp],0);
            MessageBox(Handle, 'Невозможно добавить запись', ProcTitle,
              MB_OK + MB_ICONERROR)
          end;
        end else begin
          if FTransDataSet.UpdateBtrRecord(PChar(@TransRec),
            SizeOf(TransRec))
          then
            FTransDataSet.UpdateCursorPos
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

procedure TTransportsForm.InsItemClick(Sender: TObject);
begin
  UpdateRecord(False, True);
end;

procedure TTransportsForm.EditItemClick(Sender: TObject);
begin
  UpdateRecord(True, False);
end;

procedure TTransportsForm.CopyItemClick(Sender: TObject);
begin
  UpdateRecord(True, True)
end;

procedure TTransportsForm.DelItemClick(Sender: TObject);
const
  MesTitle: PChar = 'Удаление';
var
  N: Integer;
begin
  if not DataSource.DataSet.IsEmpty then
  begin
    DBGrid.SelectedRows.Refresh;
    N := DBGrid.SelectedRows.Count;
    if (N<2) and (MessageBox(Handle, PChar('Банк будет удален. Вы уверены?'),
      MesTitle, MB_YESNOCANCEL + MB_ICONQUESTION) = IDYES)
      or (N>=2) and (MessageBox(Handle, PChar('Будет удалено банков: '
      +IntToStr(DBGrid.SelectedRows.Count)+#13#10'Вы уверены?'),
      MesTitle, MB_YESNOCANCEL + MB_ICONQUESTION) = IDYES) then
    begin
      if N>0 then
      begin
        DBGrid.SelectedRows.Delete;
        DBGrid.SelectedRows.Refresh;
      end
      else
        FTransDataSet.Delete;
    end;
  end;
end;

procedure TTransportsForm.DBGridDblClick(Sender: TObject);
begin
  if FormStyle=fsMDIChild then
    EditItemClick(Sender)
  else
    ModalResult := mrOk;
end;

const
  BikFldName = 'BANKCODE';

procedure TTransportsForm.LoadItemClick(Sender: TObject);
const
  MesTitle: PChar = 'Загрузка банков';
var
  F: TextFile;
  TransRec: TTransRec;
  I, Len, Res, Bik: Integer;
  S: string;
  Fld: TField;

  function AddBank(S: string): Boolean;
  var
    Bik, Res: Integer;
  begin
    Result := False;
    Val(S, Bik, Res);
    if (Res=0) and (Bik>0) then
    begin
      if Masked(FillZeros(Bik, 9), KliringBikMask) then
      begin
        Len := SizeOf(TransRec);
        FillChar(TransRec, Len, #0);
        with TransRec do
        begin
          sbBik := Bik;
        end;
        Res := FTransDataSet.BtrBase.Insert(TransRec, Len, Bik, 0);
        if Res=0 then
        begin
          Inc(I);
          StatusBar.SimpleText := 'Загружено: '+IntToStr(I)+'...';
        end
      end;
    end;
  end;

begin
  StatusBar.SimpleText := '';
  if OpenDialog.Execute then
  begin
    I := -1;
    if UpperCase(ExtractFileExt(OpenDialog.FileName))='.DBF' then
    begin
      with BankDataSet do
      begin
        TableName := OpenDialog.FileName;
        try
          Active := True;
        except
          MessageBox(Handle, PChar('Не удалось открыть ['+OpenDialog.FileName+']'),
            MesTitle, MB_OK+MB_ICONERROR);
        end;
        if Active then
        begin
          StatusBar.SimpleText := 'Загрузка из dbf-файла...';
          I := 0;
          First;
          while not EoF do
          begin
            Fld := FindField(BikFldName);
            if Fld<>nil then
              AddBank(Trim(Fld.AsString));
            Next;
          end;
          Active := False;
        end;
      end;
    end
    else begin
      AssignFile(F, OpenDialog.FileName);
      FileMode := 0;
      {$I-} Reset(F); {$I+}
      if IOResult=0 then
      begin
        StatusBar.SimpleText := 'Загрузка из текстового файла...';
        I := 0;
        while not EoF(F) do
        begin
          ReadLn(F, S);
          S := Trim(S);
          Res := Length(S);
          Bik := 0;
          while (Bik<Res) and (S[Bik+1] in ['0'..'9']) do
            Inc(Bik);
          if Bik>7 then
            AddBank(Copy(S, 1, Bik));
        end;
        CloseFile(F);
      end
      else
        MessageBox(Handle, PChar('Не удалось открыть ['+OpenDialog.FileName+']'),
          MesTitle, MB_OK+MB_ICONERROR);
    end;
    if I>=0 then
    begin
      FTransDataSet.Refresh;
      FTransDataSet.Last;
      MessageBox(Handle, PChar('Загружено новых записей: '+IntToStr(I)
        +#13#10'из файла ['+OpenDialog.FileName+']'),
        MesTitle, MB_OK+MB_ICONINFORMATION);
    end;
  end;
  StatusBar.SimpleText := '';
end;

procedure TTransportsForm.SaveItemClick(Sender: TObject);
const
  MesTitle: PChar = 'Выгрузка БИКов';
var
  F: TextFile;
  TransRec: TTransRec;
  I, Len, Res, Bik: Integer;
begin
  StatusBar.SimpleText := '';
  if SaveDialog.Execute then
  begin
    AssignFile(F, SaveDialog.FileName);
    {$I-} Rewrite(F); {$I+}
    if IOResult=0 then
    begin
      StatusBar.SimpleText := 'Выгрузка в текстовый файл...';
      I := 0;
      Len := SizeOf(TransRec);
      Res := FTransDataSet.BtrBase.GetFirst(TransRec, Len, Bik, 0);
      while Res=0 do
      begin
        WriteLn(F, FillZeros(TransRec.sbBik, 9));
        Inc(I);
        Len := SizeOf(TransRec);
        Res := FTransDataSet.BtrBase.GetNext(TransRec, Len, Bik, 0);
      end;
      CloseFile(F);
      StatusBar.SimpleText := 'Выгрузка завершена';
      MessageBox(Handle, PChar('Выгружено записей: '+IntToStr(I)
        +#13#10'в файл ['+OpenDialog.FileName+']'), MesTitle,
        MB_OK+MB_ICONINFORMATION);
      FTransDataSet.Refresh;
    end
    else
      MessageBox(Handle, PChar('Не удалось создать ['+SaveDialog.FileName+']'),
        MesTitle, MB_OK+MB_ICONERROR);
  end;
  StatusBar.SimpleText := '';
end;

end.
