unit ClientsFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Grids, Db, DBTables, DBGrids, ExtCtrls, DBCtrls, Menus,
  StdCtrls, Buttons, ComCtrls, ClientFrm, Common, SearchFrm, Bases, Utilits,
  BtrDS, CommCons, Btrieve;

type
  TClientsForm = class(TDataBaseForm)
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
    N1: TMenuItem;
    ImportClnItem: TMenuItem;
    ExportClnItem: TMenuItem;
    SaveDialog: TSaveDialog;
    AbortBtn: TBitBtn;
    OpenDialog: TOpenDialog;
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
    procedure ExportClnItemClick(Sender: TObject);
    procedure AbortBtnClick(Sender: TObject);
    procedure ImportClnItemClick(Sender: TObject);
  private
    procedure EditClient(CopyCurrent, New: Boolean);
  public
    SearchForm: TSearchForm;
    procedure ShowMes(S: string);
    procedure TakeTabPrintData(var PrintDocRec: TPrintDocRec; var FormList: TList); override;
  end;

var
  ObjList: TList;
const
  ClientsForm: TClientsForm = nil;

implementation

{$R *.DFM}

{procedure TClientForm.AfterScrollDS(DataSet: TDataSet);
begin
  NameEdit.Text:=DataSet.Fields.Fields[5].AsString;
end;}

procedure TClientsForm.ShowMes(S: string);
begin
  StatusBar.SimpleText := S;
end;

procedure TClientsForm.FormCreate(Sender: TObject);
begin
  ObjList.Add(Self);
  DataSource.DataSet := GlobalBase(biClient) as TClientDataSet;
  DefineGridCaptions(DBGrid, PatternDir+'Clients.tab');
  SearchForm := TSearchForm.Create(Self);
  SearchForm.SourceDBGrid := DBGrid;
  SearchIndexComboBox.ItemIndex := 2;
  SearchIndexComboBoxChange(Sender);
  TakeMenuItems(OperItem, EditPopupMenu.Items);
  EditPopupMenu.Images := ChildMenu.Images;
end;

procedure TClientsForm.FormDestroy(Sender: TObject);
begin
  ObjList.Remove(Self);
  if Self=ClientsForm then ClientsForm := nil;
end;

procedure TClientsForm.TakeTabPrintData(var PrintDocRec: TPrintDocRec; var FormList: TList);
begin
  inherited;
  PrintDocRec.DBGrid := Self.DBGrid;
end;

procedure TClientsForm.NameEditChange(Sender: TObject);
var
  Inn: TInn;
  ClientName: TClientName;
  I,Err: Integer;
  SearchData: packed record Bik: LongInt; Acc: TAccount end;
  S: string;
begin
  case SearchIndexComboBox.ItemIndex of
    0:
    begin
      NameEdit.MaxLength := 10+SizeOf(SearchData.Acc);
      S := NameEdit.Text;
      I := Pos('/',S);
      FillChar(SearchData.Acc, SizeOf(SearchData.Acc), #0);
      if I>0 then
      begin
        StrPLCopy(SearchData.Acc, Copy(S,I+1,Length(S)-I), SizeOf(SearchData.Acc));
        S:=Copy(S, 1, I-1);
      end;
      Val(S, I, Err);
      SearchData.Bik := FillDigTo(I, 8);
      TBtrDataSet(DataSource.DataSet).LocateBtrRecordByIndex(SearchData, 0, bsGe);
    end;
    1:
    begin
      NameEdit.MaxLength := SizeOf(Inn);
      FillChar(Inn, SizeOf(Inn), #0);
      StrPCopy(Inn, NameEdit.Text);
      (DataSource.DataSet as TBtrDataSet).LocateBtrRecordByIndex(Inn, 1, bsGe);
    end;
    2:
    begin
      NameEdit.MaxLength := SizeOf(TClientName);
      FillChar(ClientName, SizeOf(TClientName), #0);
      StrPLCopy(ClientName, NameEdit.Text, SizeOf(TClientName)-1);
      WinToDos(ClientName);
      (DataSource.DataSet as TBtrDataSet).LocateBtrRecordByIndex(ClientName,
        2, bsGe);
    end;
  end;
end;

procedure TClientsForm.SearchIndexComboBoxChange(Sender: TObject);
var
  AllowMultiSel: Boolean;
  Opt: TDBGridOptions;
begin
  (DataSource.DataSet as TBtrDataSet).IndexNum := SearchIndexComboBox.ItemIndex;
  case SearchIndexComboBox.ItemIndex of
    0: NameEdit.MaxLength := 10+SizeOf(TAccount);
    1: NameEdit.MaxLength := SizeOf(TInn);
    2: NameEdit.MaxLength := clMaxVar;
    else
      NameEdit.MaxLength := 15;
  end;
  AllowMultiSel := SearchIndexComboBox.ItemIndex=0;
  Opt := DBGrid.Options;
  if (dgMultiSelect in Opt)<>AllowMultiSel then
  begin
    if AllowMultiSel then
      Include(Opt, dgMultiSelect)
    else
      Exclude(Opt, dgMultiSelect);
    DBGrid.Options := Opt;
  end;
end;

const
  BtnDist=6;

procedure TClientsForm.BtnPanelResize(Sender: TObject);
begin
  CancelBtn.Left:=BtnPanel.ClientWidth-CancelBtn.Width-2*BtnDist;
  OkBtn.Left:=CancelBtn.Left-OkBtn.Width-BtnDist;
end;

procedure TClientsForm.FindItemClick(Sender: TObject);
begin
  SearchForm.ShowModal;
end;

procedure TClientsForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if FormStyle=fsMDIChild then Action:=caFree;
end;

procedure TClientsForm.EditClient(CopyCurrent, New: Boolean);
var
  ClientForm: TClientForm;
  ClientRec: TNewClientRec;
  T: array[0..512] of Char;
  Editing: Boolean;
  OldAcc: string;
  OldBik: Integer;
begin
  if not DataSource.DataSet.IsEmpty or (New and not CopyCurrent) then
  begin
    ClientForm := TClientForm.Create(Self);
    with ClientForm do
    begin
      if CopyCurrent then
      begin
        if TClientDataSet(DataSource.DataSet).GetBtrRecord(PChar(@ClientRec))>0 then
        begin
          StrLCopy(T, ClientRec.clAccC, SizeOf(ClientRec.clAccC));
          OldAcc := StrPas(T);
          OldBik := ClientRec.clCodeB;
        end
        else
          CopyCurrent := False;
      end
      else
        FillChar(ClientRec, SizeOf(ClientRec), #0);
      with ClientRec do
      begin
        DosToWin(clNameC);
        StrLCopy(T, clAccC, SizeOf(clAccC));
        RsEdit.Text := StrPas(T);
        BikEdit.Text := IntToStr(clCodeB);
        StrLCopy(T, clInn, SizeOf(clInn));
        InnEdit.Text := StrPas(T);
        StrLCopy(T, clKpp, SizeOf(clKpp));
        KppEdit.Text := StrPas(T);
        NameMemo.Text := StrPas(clNameC);
      end;
      Editing := True;
      while Editing and (ShowModal = mrOk) do
      begin
        Editing := False;
        if not CopyCurrent or New then
        begin
          OldAcc := RsEdit.Text;
          OldBik := StrToInt(BikEdit.Text);
        end;
        if not UpdateClient(RsEdit.Text, StrToInt(BikEdit.Text), NameMemo.Text,
          InnEdit.Text, KppEdit.Text, False, True, 0, OldAcc, OldBik, '') then
        begin
          Editing := True;
          MessageBox(Handle, 'Невозможно обновить запись', 'Редактирование',
            MB_OK or MB_ICONERROR);
        end;
      end;
      Free;
    end;
  end;
end;

procedure TClientsForm.InsItemClick(Sender: TObject);
begin
  EditClient(False, True);
end;

procedure TClientsForm.EditItemClick(Sender: TObject);
begin
  if FormStyle = fsMDIChild then
    EditClient(True, False)
  else
    ModalResult := mrOk;
end;

procedure TClientsForm.CopyItemClick(Sender: TObject);
begin
  EditClient(True, True)
end;

procedure TClientsForm.DelItemClick(Sender: TObject);
const
  MesTitle: PChar = 'Удаление';
var
  N: Integer;
begin
  if not DataSource.DataSet.IsEmpty then
  begin
    DBGrid.SelectedRows.Refresh;  
    N := DBGrid.SelectedRows.Count;
    if (N<2) and (MessageBox(Handle, PChar('Клиент будет удален. Вы уверены?'),
      MesTitle, MB_YESNOCANCEL + MB_ICONQUESTION) = IDYES)
      or (N>=2) and (MessageBox(Handle, PChar('Будет удалено клиентов: '
      +IntToStr(DBGrid.SelectedRows.Count)+#13#10'Вы уверены?'),
      MesTitle, MB_YESNOCANCEL + MB_ICONQUESTION) = IDYES) then
    begin
      if N>0 then
      begin
        DBGrid.SelectedRows.Delete;
        DBGrid.SelectedRows.Refresh;
      end
      else
        DataSource.DataSet.Delete;
    end;
  end;
end;

procedure TClientsForm.DBGridDblClick(Sender: TObject);
begin
  EditItemClick(Sender)
end;

procedure TClientsForm.ExportClnItemClick(Sender: TObject);
const
  MesTitle: PChar = 'Экспорт базы клиентов';
var
  FN, S: string;
  F: TextFile;
  Res, Len, C: Integer;
  ClientRec: TNewClientRec;
  ClntKey: TAccount;
begin
  if SaveDialog.Execute and (DataSource.DataSet<>nil) then
  begin
    FN := SaveDialog.FileName;
    AssignFile(F, FN);
    {$I-} Rewrite(F); {$I+}
    if IOResult=0 then
    begin
      C := 0;
      try
        DataSource.Enabled := False;
        ShowMes('Выгрузка клиентов...');
        WriteLn(F, ';ACCOUNT|BIK|INN|KPP|NAME');
        AbortBtn.Visible := True;
        Len := SizeOf(ClientRec);
        with DataSource.DataSet as TExtBtrDataSet do
        begin
          Res := BtrBase.GetFirst(ClientRec, Len, ClntKey, 0);
          while (Res=0) and AbortBtn.Visible do
          begin
            Inc(C);
            S := ClientRec.clAccC+'|'+FillZeros(ClientRec.clCodeB, 9)
              +'|'+ClientRec.clInn+'|'+ClientRec.clKpp+'|'
                +RemoveDoubleSpaces(DelCR(ClientRec.clNameC));
            WriteLn(F, S);
            Len := SizeOf(ClientRec);
            Res := BtrBase.GetNext(ClientRec, Len, ClntKey, 0);
            Application.ProcessMessages;
          end;
        end;
      finally
        CloseFile(F);
        DataSource.Enabled := True;
        if AbortBtn.Visible then
        begin
          AbortBtn.Visible := False;
          ShowMes('Выгрузка успешно завершена');
          MessageBox(Handle, PChar('Выгружено в файл ['+FN+']'
            +#13#10'Всего клиентов: '+IntToStr(C)), MesTitle, MB_OK or MB_ICONINFORMATION);
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

procedure TClientsForm.AbortBtnClick(Sender: TObject);
begin
  AbortBtn.Visible := False;
end;

procedure TClientsForm.ImportClnItemClick(Sender: TObject);
const
  MesTitle: PChar = 'Импорт базы клиентов';
var
  FN, S, S0: string;
  F: TextFile;
  Res, Len, C, C1, C2, K, I: Integer;
  ClientRec: TNewClientRec;

  KKClientBase: TBtrBase;
  KKClientRec: packed record
    KFld1: Smallint;           {0, 2}      {k0.1}  {k1.1}
    Fld2: Smallint;            {0, 2}
    kkInn: array[0..15] of Char;         {4, 16}     {k0.2}
    kkAcc: array[0..25] of Char;        {20, 26}    {k0.3}
    kkName: array[0..160+450] of Char;      {46, 161}           {k1.2}
  end;                                  {=(207)209}
  KK_Key1: packed record
    Fld1: Integer{Smallint};            {0, 4}      {k0.1}
    Fld2: array[0..15] of Char;         {4, 16}     {k0.2}
    kkAcc: array[0..25] of Char;        {20, 26}    {k0.3}
  end;

  function GetNumber(S: string): string;
  var
    I, L: Integer;
  begin
    Result := Trim(S);
    I := 1;
    L := Length(Result);
    while (I<=L) and (Result[I] in ['0'..'9']) do
      Inc(I);
    if I<=L then
      Result := Copy(Result, 1, I-1);
  end;

  procedure AddClientRec;
  var
    ClientRec0: TNewClientRec;
    ClntKey0:
      packed record
        clAccC:  TAccount;                          {0,20     k0.1}
        clCodeB: LongInt;                           {20,4     k0.0}
      end;                                             {=195}
    ClntKey1: TInn;                              {24,16    k1}
    ClntKey2: TClientName;       {56, 139  k2}
  begin
    Inc(C);
    with DataSource.DataSet as TExtBtrDataSet do
    begin          ?
      Len := SizeOf(ClientRec);
      ClntKey1 := ClientRec.clInn;
      Res := BtrBase.GetEqual(ClientRec0, Len, ClntKey1, 1);

      if Res=0 then
      begin
        Res := BtrBase.Update(ClientRec, Len, ClntKey1, 1);
        if Res=0 then
          Inc(C2);
      end
      else begin
        Res := BtrBase.Insert(ClientRec, Len, ClntKey1, 1);
        if Res=0 then
          Inc(C1);
      end;
    end;
  end;

begin
  if OpenDialog.Execute and (DataSource.DataSet<>nil) then
  begin
    FN := OpenDialog.FileName;
    C := 0; C1 := 0; C2 := 0;
    try
      DataSource.Enabled := False;
      ShowMes('Загрузка клиентов...');
      AbortBtn.Visible := True;
      S := UpperCase(ExtractFileExt(FN));
      if (S='.DBT') or (S='.BTR') then
      begin  
        KKClientBase := TBtrBase.Create;  
        try  
        with KKClientBase do  
        begin  
          Res := Open(FN, baReadOnly);  
          if Res=0 then  
          begin  
            try  
            Len := SizeOf(KKClientRec);  
            Res := GetFirst(KKClientRec, Len, KK_Key1, 0);  
            while (Res=0) and AbortBtn.Visible do  
            begin  
              {S := IntToStr(C)+#13#10  
                +IntToStr(KKClientRec.KFld1)+#13#10  
                +IntToStr(KKClientRec.Fld2)+#13#10  
                +'['+KKClientRec.kkInn+']'#13#10
                +'['+KKClientRec.kkAcc+']'#13#10  
                +'['+KKClientRec.kkName;  
              showmessage(S);}  

              FillChar(ClientRec, SizeOf(ClientRec), #0);  
              StrPLCopy(ClientRec.clAccC, GetNumber(KKClientRec.kkAcc), SizeOf(ClientRec.clAccC));  
              StrPLCopy(ClientRec.clInn, GetNumber(KKClientRec.kkInn), SizeOf(ClientRec.clInn));
              StrPLCopy(ClientRec.clNameC, RemoveDoubleSpaces(KKClientRec.kkName),  
                SizeOf(ClientRec.clNameC)-1);  
              Len := StrLen(ClientRec.clNameC);  
              if (Len>1) and (ClientRec.clNameC[0]='"') and (ClientRec.clNameC[Len-1]='"') then  
                StrPLCopy(ClientRec.clNameC, Trim(Copy(ClientRec.clNameC, 2, Len-2)),
                  SizeOf(ClientRec.clNameC)-1);  
              WinToDosL(ClientRec.clNameC, SizeOf(ClientRec.clNameC)-1);  
              StrPLCopy(ClientRec.clKpp, '', SizeOf(ClientRec.clKpp));  

              ClientRec.clCodeB := StrToInt('0');

              AddClientRec;  

              Len := SizeOf(KKClientRec);  
              Res := GetNext(KKClientRec, Len, KK_Key1, 0);
            end;  
            finally  
            Close;  
            end;  
          end  
          else  
            ShowMessage('Ошибка открытия базы ['+FN+'] BtrErr='+IntToStr(Res));  
        end;  
        finally  
        KKClientBase.Free;  
        end;  
      end  
      else begin  
        AssignFile(F, FN);  
        FileMode := 0;  
        {$I-} Reset(F); {$I+}  
        if IOResult=0 then  
        begin  
          while not System.Eof(F) and AbortBtn.Visible do  
          begin  
            ReadLn(F, S);  
            if (Length(S)>0) and (S[1]<>';') then  
            begin  
              FillChar(ClientRec, SizeOf(ClientRec), #0);  
              K := 0;  
              while (Length(S)>0) and (K<5) do  
              begin  
                Inc(K);  
                I := Pos('|', S);  
                if I>0 then
                begin  
                  S0 := Copy(S, 1, I-1);  
                  System.Delete(S, 1, I);  
                end  
                else begin  
                  S0 := S;  
                  S := '';  
                end;  
                S0 := Trim(S0);  
                S := Trim(S);  
                case K of  
                  1:  
                    StrPLCopy(ClientRec.clAccC, S0, SizeOf(ClientRec.clAccC));  
                  2:  
                    try  
                      ClientRec.clCodeB := StrToInt(S0);  
                    except  
                      ClientRec.clCodeB := 0;  
                    end;  
                  3:  
                    StrPLCopy(ClientRec.clInn, S0, SizeOf(ClientRec.clInn));  
                  4:  
                    StrPLCopy(ClientRec.clKpp, S0, SizeOf(ClientRec.clKpp));  
                  5:  
                    StrPLCopy(ClientRec.clNameC, RemoveDoubleSpaces(S0),  
                      SizeOf(ClientRec.clNameC)-1);  
                end;  
              end;  
              if K>0 then  
                AddClientRec;  
            end;  
            Application.ProcessMessages;  
          end;  
          CloseFile(F);  
        end  
        else  
          MessageBox(Handle, PChar('Не могу открыть файл ['+FN+']'), MesTitle,  
            MB_OK or MB_ICONERROR);  
      end;
    finally
      DataSource.Enabled := True;
      if AbortBtn.Visible then
      begin
        AbortBtn.Visible := False;
        ShowMes('Загрузка успешно завершена');
        MessageBox(Handle, PChar('В файле-источнике ['+FN+'] просмотрено всего клиентов: '+IntToStr(C)
          +#13#10'изменено в справочнике: '+IntToStr(C2)+#13#10'добавлено в справочник: '
          +IntToStr(C1)), MesTitle, MB_OK or MB_ICONINFORMATION);
        ShowMes('');
      end
      else
        ShowMes('Загрузка прервана');
    end;
  end;
end;

end.

