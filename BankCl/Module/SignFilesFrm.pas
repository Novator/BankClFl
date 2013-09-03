unit SignFilesFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Grids, Db, DBTables, DBGrids, ExtCtrls, DBCtrls, BtrDS, Menus,
  StdCtrls, Buttons, ComCtrls, SearchFrm, Common, Bases, CommCons,
  Utilits, Mask, ToolEdit, Registr, CrySign, DBFilter, DBLists, RxMemDS;


type
  TSignFilesForm = class(TDataBaseForm)
    ChildMenu: TMainMenu;
    DataSource: TDataSource;
    EditPopupMenu: TPopupMenu;
    OperItem: TMenuItem;
    AddItem: TMenuItem;
    DelItem: TMenuItem;
    SaveItem: TMenuItem;
    SearchItem: TMenuItem;
    CheckItem: TMenuItem;
    SFileStatusBar: TStatusBar;
    SFileMemoryData: TRxMemoryData;
    BtnPanel: TPanel;
    LoadSFileDirectoryEdit: TDirectoryEdit;
    SaveSFileButton: TButton;
    LoadSFileButton: TButton;
    Breaker1Item: TMenuItem;
    SaveSFileDirectoryEdit: TDirectoryEdit;
    DelLoadedCheckBox: TCheckBox;
    DBGrid: TDBGrid;
    SFileComboBox: TComboBox;
    Label1: TLabel;
    StopBitBtn: TBitBtn;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure DelItemClick(Sender: TObject);
    procedure SearchItemClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure SFileComboBoxChange(Sender: TObject);
    procedure SaveSFileButtonClick(Sender: TObject);
    procedure LoadSFileButtonClick(Sender: TObject);
    procedure CheckItemClick(Sender: TObject);
    procedure SFileFillTable;
    procedure FormResize(Sender: TObject);
    procedure StopBitBtnClick(Sender: TObject);
  private
    { Private declarations }
    function FileCreate(var FileName:string):Integer;
    function FileSignCheck(FileShowInfo:Boolean; CurFN: string): Integer;
  public
    { Public declarations }
    SearchForm: TSearchForm;
  end;

var
  SignFilesForm: TSignFilesForm;
  ObjList: TList;

implementation

{$R *.DFM}
const
  IdentIndex = 0;
  IndexIndex = 1;
  NameIndex = 2;
  FTypeIndex = 3;

var
  SFileDataSet, LFileDataSet, FileDataSet: TExtBtrDataSet;
  NumOfSign: Integer;
  ControlData: TControlData;
  ReceiverNode: Integer = -1;

procedure TSignFilesForm.FormCreate(Sender: TObject);
var
  T: array[0..511] of Char;
  B: Boolean;
begin
  ObjList.Add(Self);
  SFileDataSet := Globalbase(biSFile);
  LFileDataSet := Globalbase(biLFile);
  SaveSFileDirectoryEdit.Text := DecodeMask('$(SFileSaveDir)', 5, CommonUserNumber);
  LoadSFileDirectoryEdit.Text := DecodeMask('$(SFileLoadDir)', 5, CommonUserNumber);
  if not GetRegParamByName('DelFileAfterLoad', CommonUserNumber, B) then
    B := True;
  DelLoadedCheckBox.Checked := B;
  if not GetRegParamByName('NumOfSign', CommonUserNumber, NumOfSign) then
    NumOfSign := 1;
  DefineGridCaptions(DBGrid, PatternDir+'SignFile.tab');
  SearchForm := TSearchForm.Create(Self);
  SearchForm.SourceDBGrid := DBGrid;
  TakeMenuItems(OperItem, EditPopupMenu.Items);
  EditPopupMenu.Images := ChildMenu.Images;
  with ControlData do
  begin
    cdTagNode := ReceiverNode;
    cdCheckSelf := False;
    if GetRegParamByName('ReceiverAcc', CommonUserNumber, T) then
    begin
      StrLCopy(cdTagLogin, T, SizeOf(cdTagLogin)-1);
    end
    else
      cdTagLogin := 'CBTCB';
    {if GetRegParamByName('SenderAcc', CommonUserNumber, T) then
      AddWordInList(T, cdLoginList);}
  end;
  SFileCombobox.ItemIndex := 1;
  SFileComboBoxChange(Self);
  SFileFillTable;
//  CurrentUser(User);
{  if not GetRegParamByName('ColorPayState', CommonUserNumber, ColorPayState) then
    ColorPayState := False;
  if not ColorPayState then
    DBGrid.OnDrawColumnCell := nil;
  with ControlData do
  begin
    cdTagNode := ReceiverNode;
    cdCheckSelf := False;
    if GetRegParamByName('ReceiverAcc', CommonUserNumber, T) then
    begin
      StrLCopy(cdTagLogin, T, SizeOf(cdTagLogin)-1);
    end
    else
      cdTagLogin := 'CBTCB';
  end; }
end;

procedure TSignFilesForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if FormStyle=fsMDIChild then Action:=caFree;
end;

type
  TFilePieceKey =
    packed record
      Index: Word;
      Ident: Integer;
    end;

procedure TSignFilesForm.DelItemClick(Sender: TObject);
const
  MesTitle: PChar = 'Удаление';
var
  FilePieceRec: TFilePieceRec;
  FileKey: TFilePieceKey;
  Len, Res, CurIden, I: Integer;
begin
  I := DBGrid.SelectedRows.Count;
  if (I>0)
    and (MessageBox(Handle, PChar('Удаление файлов из списка: '+IntToStr(I)
    +#13#10'Вы уверерны?'), MesTitle, MB_ICONWARNING or MB_YESNOCANCEL)=ID_YES) then
  begin
    while I>0 do
    begin
      Dec(I);
      DBGrid.DataSource.DataSet.Bookmark := DBGrid.SelectedRows.Items[I];
      FileKey.Ident := DBGrid.DataSource.DataSet.FieldValues['fpIdent'];
      FileKey.Index := DBGrid.DataSource.DataSet.FieldValues['fpIndex'];
      CurIden := FileKey.Ident;
      Len := SizeOf(FilePieceRec);
      Res := FileDataSet.BtrBase.GetEqual(FilePieceRec, Len, FileKey, 0);
      while (Res=0) and (FilePieceRec.fpIdent = CurIden) do
      begin
        FileDataSet.BtrBase.Delete(0);
        Res := FileDataSet.BtrBase.GetPrev(FilePieceRec, Len, FileKey, 0);
      end;
    end;
    SFileFillTable;
  end;
end;


procedure TSignFilesForm.FormDestroy(Sender: TObject);
begin
  ObjList.Remove(Self);
  SignFilesForm := nil;
end;


procedure TSignFilesForm.SearchItemClick(Sender: TObject);
begin
  SearchForm.ShowModal;
end;

procedure TSignFilesForm.SFileComboBoxChange(Sender: TObject);
begin
  if SFileComboBox.ItemIndex>=0 then
  begin
    if SFileComboBox.ItemIndex=0 then
      FileDataSet := LFileDataSet
    else
      FileDataSet := SFileDataSet;
  end
  else
    FileDataSet := nil;
  SaveSFileButton.Visible := SFileComboBox.ItemIndex=1;
  SaveSFileDirectoryEdit.Visible := SaveSFileButton.Visible;
  LoadSFileButton.Visible := not SaveSFileButton.Visible;
  LoadSFileDirectoryEdit.Visible := not SaveSFileButton.Visible;
  DelLoadedCheckBox.Visible := not SaveSFileButton.Visible;
  SFileFillTable;
end;

{
procedure TSignFilesForm.SFileComboBoxChange(Sender: TObject);
var
  FFileDataSet: TExtBtrDataSet;
  FilePieceRec: TFilePieceRec;
  FileKey: TFilePieceKey;
  Len, I: Integer;
begin
  I := 1;
  Len := SizeOf(FilePieceRec);
  with SFileComboBox do
    case ItemIndex of
      0: begin
         if SFileDataSet.BtrBase.GetFirst(FilePieceRec,Len,FileKey,0)=0 then
           begin
           Len := SizeOf(FilePieceRec);
           with SFileDataSet do
             while BtrBase.GetNext(FilePieceRec,Len,FileKey,0)=0 do
               begin
               MessageBox(ParentWnd,PChar(IntToStr(Length(StrPas(@FilePieceRec.fpVar[0])))),'Check',MB_OK);    //Merge
               if Length(StrPas(@FilePieceRec.fpVar[0]))>0 then
                 begin
                 DataSource.DataSet.InsertRecord([I,FilePieceRec.fpIdent,
                   FilePieceRec.fpIndex, StrPas(@FilePieceRec.fpVar[0]), 'принят']);
                 Inc(I);
                 end;
               Len := SizeOf(FilePieceRec);
               end;
           end
         else
           FFileDataSet := SFileDataSet;
         end;
      1: FFileDataSet := LFileDataSet;
      2: FFileDataSet := SFileDataSet;
      end;
DataSource.DataSet := FFileDataSet;
end;
}

procedure TSignFilesForm.SaveSFileButtonClick(Sender: TObject);
const
  MesTitle: PChar = 'Воссоздание файла';
var
  DstDir, FN: string;
  //F: file;
  FileShowInfo: Boolean;
  LI, N, I, I1, I2: Integer;
begin
  if SFileCombobox.ItemIndex=1 then
  begin
    SFileComboBoxChange(Self);  
    DstDir := SaveSFileDirectoryEdit.Text;
    NormalizeDir(DstDir);
    if DirExists(DstDir) then
    begin
      DBGrid.SelectedRows.Refresh;
      N := DBGrid.SelectedRows.Count;
      with DBGrid.DataSource.DataSet do
      begin
        LI := N;
        if N=0 then
          Inc(LI);
        I := 0;
        I1 := 0;
        I2 := 0;
        while I<LI do
        begin
          if N>0 then
            Bookmark := DBGrid.SelectedRows.Items[I];
          FN := DstDir;
          FileShowInfo := False;
          if FileCreate(FN)>0 then
          begin
            Inc(I1);
            if FileSignCheck(FileShowInfo, FN)>=0 then
              Inc(I2);
          end;
          Inc(I);
      end;
        DBGrid.SelectedRows.Refresh;
      end;
      MessageBox(Handle, PChar('Просмотрено файлов: '+IntToStr(I)
        +#13#10'выгружено файлов: '+IntToStr(I1)
        +#13#10'правильно подписанных: '+IntToStr(I2)),
        MesTitle, MB_OK or MB_ICONINFORMATION);
      SetRegParamByName('SFileSaveDir', CommonUserNumber, False, SaveSFileDirectoryEdit.Text);
    end
    else
      MessageBox(Handle, PChar('Директория выгрузки не существует'#13#10'['+FN+']'), MesTitle,
        MB_ICONWARNING or MB_OK);
  end
  else
    MessageBox(Handle, 'Выберите индекс "Входящие"', MesTitle, MB_ICONINFORMATION or MB_OK);
end;

function TSignFilesForm.FileSignCheck(FileShowInfo:Boolean; CurFN: string): Integer;
const
  MesTitle: PChar = 'Проверка подписи файла';
var
  FilePieceRec: TFilePieceRec;
  SignDescr: TSignDescr;
  FileKey: TFilePieceKey;
  FN: string;
  Len, Res, K, Mode, Sign: Integer;
begin
  Mode := smFile;
  Result := 0;
  FileKey.Index := 1;
  FileKey.Ident := DataSource.DataSet.FieldValues['fpIdent'];
  Len := SizeOf(FilePieceRec);
  Res := SFileDataSet.BtrBase.GetEqual(FilePieceRec, Len, FileKey, 0);
  if (Res=0) then
  begin
    FN := StrPas(@FilePieceRec.fpVar[0]);
    if Length(FN)=0 then
      K := 1
    else
      K := Length(FN)+2;
    if FileShowInfo then
    begin
      Mode := Mode or smShowInfo or smCheckLogin or smThoroughly;
      SignDescr.siLoginNameProc := @ClientGetLoginNameProc;
      Sign := CheckSign(FilePieceRec.fpVar, K, Len-K-6, Mode, @ControlData, @SignDescr, CurFN);
    end
    else begin
      Sign := CheckSign(FilePieceRec.fpVar, K, Len-K-6, Mode, nil, nil, CurFN);
    end;
    if (Sign<>ceiDomenK) then
    begin
      ProtoMes(plError, MesTitle, PChar('Подпись файла '+CurFN+' неправильная или отсутствует !!!!'));
      Result := -1;
    end;
  end
  else begin
    ProtoMes(plError, MesTitle, PChar('Подпись файла отсутствует !!!!'));
    Result := -1;
  end;
end;

function TSignFilesForm.FileCreate(var FileName:string): Integer;
const
  MesTitle: PChar = 'Создание файла';
var
  FilePieceRec: TFilePieceRec;
  FileKey, FileKey2: TFilePieceKey;
  CurFN, FN: string;
  F: file;
  Len, Res, K, CurIndex: Integer;
begin
  Result := 0;
  SFileDataSet := GlobalBase(biSFile);
  FN := '';
  CurIndex := 1;             //проверка на последовательность
  FileKey.Ident := DataSource.DataSet.FieldValues['fpIdent'];
  FileKey.Index := 1;
  FileKey2 := FileKey;
  Len := SizeOf(FilePieceRec);
  Res := SFileDataSet.BtrBase.GetEqual(FilePieceRec, Len, FileKey, 0);
  while (Res=0) and (FilePieceRec.fpIndex = CurIndex) do
  begin
    FN := StrPas(@FilePieceRec.fpVar[0]);
    if Length(FN)>0 then
      Res := -1
    else begin
      Len := SizeOf(FilePieceRec);
      Res := SFileDataSet.BtrBase.GetNext(FilePieceRec, Len, FileKey2, 0);
      Inc(CurIndex);
    end;
  end;
  if (FilePieceRec.fpIndex = CurIndex) and (Length(FN)>0) then //последовательно и с последним куском?
  begin
    CurFN := FileName;
    if (CurFN<>'') then
      NormalizeDir(CurFN);
    CurFN := CurFN+FN;
    if not FileExists(CurFN) or (MessageBox(Handle, PChar('Файл уже существует'
      +#13#10'['+CurFN+']'+#13#10'Перезаписать его?'),
      MesTitle, MB_ICONWARNING or MB_YESNOCANCEL)=ID_YES) then
    begin
      AssignFile(F, CurFN);
      Rewrite(F, 1);
      if IOResult=0 then
      begin
        FileKey.Index := 2;                  //Изменено
        FileKey2 := FileKey;
        Len := SizeOf(FilePieceRec);
        Res := SFileDataSet.BtrBase.GetEqual(FilePieceRec, Len, FileKey2, 0);
        while (Res=0) and (FilePieceRec.fpIdent=FileKey.Ident) do
        begin
          FN := StrPas(@FilePieceRec.fpVar[0]);
          if Length(FN)=0 then
            K := 1
          else
            K := Length(FN)+2;
          BlockWrite(F, FilePieceRec.fpVar[K], Len-K-6);
          Len := SizeOf(FilePieceRec);
          Res := SFileDataSet.BtrBase.GetNext(FilePieceRec, Len, FileKey2, 0);
        end;
        CloseFile(F);
        if Length(FN)=0 then   //найден последний кусочек?
        begin
          Erase(F);
          ProtoMes(plError, MesTitle, 'Не найден последний кусок файла');
        end;
        FileName := CurFN;
        Result := 1;
      end
      else
        ProtoMes(plError, MesTitle, PChar('Не удается создать файл ['+FN+']'));
    end;
  end;
//MessageBox(ParentWND,'Выгружен файл','Выгрузка файлов', MB_OK);
end;

procedure TSignFilesForm.CheckItemClick(Sender: TObject);
const
  MesTitle:PChar = 'Проверка подписи файла';
var
  FN: string;
  F: file;
  FileShowInfo: Boolean;
begin
  FN := PostDir;
  FileShowInfo := True;
  FileCreate(FN);
  FileSignCheck(FileShowInfo, FN);
  AssignFile(F, FN);
  Erase(F);
end;

var
  FileBitSize: Integer = 15000;
  Process: Boolean = False;
  MaxLoadCountFile: Integer = 30;

procedure TSignFilesForm.LoadSFileButtonClick(Sender: TObject);
const
  MesTitle: PChar = 'Подготовка к отправке файлов для банка';

var
  AbonIder: Integer;

  function SendFileToCorr(Corr, MaxData, LastIder, FS: Integer; var F: file; DestFN: string; SendType: Char): Boolean;
  var
    Res, Len, P, I, W, C: Integer;       //Change
    ps: TFilePieceRec;
  begin
    Result := True;
    if MaxData<SizeOf(ps) - SizeOf(ps.fpVar) + 10 then
      MaxData := 1000;
    with ps do
      begin
      fpIndex := 0;
      fpIdent := LastIder;
      end;
    Seek(F, 0);
    P := 0;
    while (P<=FS) and Result do
    begin
      Inc(ps.fpIndex);
      if P+MaxData>=FS then
      begin
        I := FS-P;
        StrPCopy(ps.fpVar, DestFN);
        C := Length(DestFN)+1;
        ps.fpVar[C] := #0;
      end
      else begin
        I := MaxData;
        ps.fpVar[0] := #0;
        C := 0;
      end;
      Inc(C);
      if I>0 then
        BlockRead(F, ps.fpVar[C], I, W)
      else
        W := 0;
      P := P+W;
      if P>=FS then
        Inc(P);
      Len := SizeOf(ps) - SizeOf(ps.fpVar) + C + W;
      Res := LFileDataSet.BtrBase.Insert(ps, Len, I, 0);
      if Res<>0 then
      begin
        Result := False;
        ProtoMes(plError, MesTitle, 'Не удалось добавить фрагмент N'+
        IntToStr(ps.fpIndex)+' Abon='+IntToStr(Corr)+' BtrErr='+IntToStr(Res));
      end;
    end;
    if Result then
      ProtoMes(plInfo, MesTitle, 'Abo='+IntToStr(Corr)+' '+IntToStr(ps.fpIndex)+
        'x'+IntToStr(MaxData)+'b');
  end;

  function SendDir(SrcDir: string): Integer;
  var
    Res1, Res2, FS: Integer;
    LastKey: TFilePieceKey;
    SearchRec: TSearchRec;
    F: file;
    Err: Boolean;
  begin
    Err := False;
    Result := 0;
    Res2 := FindFirst(SrcDir+'*.*', faAnyFile, SearchRec);
    if Res2=0 then
    begin
      try
        while (Res2=0) and not Err and Process and (Result<MaxLoadCountFile) do
        begin
          if (SearchRec.Attr and faDirectory)>0 then
          begin
            {if (SearchRec.Name<>'.') and (SearchRec.Name<>'..') then
              Result := Result+SendDir(SrcDir+SearchRec.Name+'\');}
          end
          else begin
            AssignFile(F, SrcDir+SearchRec.Name);
            FileMode := 0;
            {$I-} Reset(F, 1); {$I+}
            if IOResult=0 then
            begin
              FS := FileSize(F);
              Res1 := FileDataSet.BtrBase.GetLastKey(LastKey, 0);
              if (Res1=0) or (Res1=9) then
              begin
                if Res1=9 then
                  LastKey.Ident := 0;
                Inc(LastKey.Ident);
                if SendFileToCorr(AbonIder, FileBitSize, LastKey.Ident, FS, F,
                  SearchRec.Name, #0) then
                begin
                  ProtoMes(plInfo, MesTitle, 'Загружен ['+SrcDir+SearchRec.Name+']');
                  Inc(Result)
                end
                else
                  Err := True;
                CloseFile(F);
                Application.ProcessMessages;
                if not Err and DelLoadedCheckBox.Checked then
                begin
                  if DeleteFile(PChar(SrcDir+SearchRec.Name)) then
                    ProtoMes(plInfo, MesTitle, 'Удален ['+SrcDir+SearchRec.Name+']');
                end;
              end
              else begin
                CloseFile(F);
                ProtoMes(plWarning, MesTitle, 'Ошибка поиска последнего номера обновления BtrErr='+IntToStr(Res1));
              end;
            end
            else
              ProtoMes(plWarning, MesTitle, 'Не удалось открыть '+SrcDir+SearchRec.Name);
          end;
          Res2 := FindNext(SearchRec);
          if (Res2=0) and (Result>=MaxLoadCountFile) then
            MessageBox(Handle, PChar('Достигнут предел количества загружаемых файлов: '
              +IntToStr(Result)), MesTitle, MB_ICONWARNING or MB_OK);
        end;
      finally
        FindClose(SearchRec);
      end;
    end;
  end;

var
  SrcFN: string;
  I: Integer;
begin
  if SFileCombobox.ItemIndex=0 then
  begin
    SFileComboBoxChange(Self);
    //SFileFillTable;
    SrcFN := LoadSFileDirectoryEdit.Text;
    if (Length(SrcFN)>0) then
    begin
      if DirExists(SrcFN) then
      begin
        NormalizeDir(SrcFN);
        Process := True;
        StopBitBtn.Visible := True;
        I := SendDir(SrcFN);
        StopBitBtn.Visible := False;
        Process := False;
        SFileFillTable;
        SetRegParamByName('SFileLoadDir', CommonUserNumber, False, LoadSFileDirectoryEdit.Text);
        SetRegParamByName('DelFileAfterLoad', CommonUserNumber, False, BooleanToStr(DelLoadedCheckBox.Checked));
        MessageBox(Handle, PChar('Всего загружено файлов: '+IntToStr(I)), MesTitle,
          MB_ICONINFORMATION or MB_OK);
      end
      else
        MessageBox(Handle, PChar('Директория загрузки не существует'#13#10'['+SrcFN+']'), MesTitle,
          MB_ICONWARNING or MB_OK);
    end;
  end
  else
    MessageBox(Handle, 'Выберите индекс "Исходящие"', MesTitle, MB_ICONINFORMATION or MB_OK);
end;

//Заполним таблицу файлов
procedure TSignFilesForm.SFileFillTable;
var
  Res, Len, L: Integer;
  FilePieceRec: TFilePieceRec;
  FileKey: TFilePieceKey;
begin
  SFileMemoryData.EmptyTable;
  if FileDataSet<>nil then
  begin
    Len := SizeOf(FilePieceRec);
    Res := FileDataSet.BtrBase.GetFirst(FilePieceRec, Len, FileKey, 0);
    while (Res=0) do
      begin
      with FilePieceRec do
        begin
        if (Length(StrPas(@fpVar[0]))>0) then
          begin
          with SFileMemoryData do
            begin
            Append;
            Fields.Fields[IdentIndex].AsInteger := fpIdent;
            Fields.Fields[IndexIndex].AsInteger := fpIndex;
            Fields.Fields[NameIndex].AsString := StrPas(@fpVar[0]);
            if (FileDataSet=SFileDataSet) then
              Fields.Fields[FTypeIndex].AsString := 'принят'
            else
              begin
              L := StrLen(@fpVar[0]);
              if L>0 then
                L := Byte(fpVar[L+1]);
              case L of
                0: Fields.Fields[FTypeIndex].AsString := 'готов';
                1: Fields.Fields[FTypeIndex].AsString := 'отпр.';
                2: Fields.Fields[FTypeIndex].AsString := 'принят';
                else Fields.Fields[FTypeIndex].AsString := 'неизв.';
                end;
              end;
            Post;
            end;
          end;
        end;
      Len := SizeOf(FilePieceRec);
      Res := FileDataSet.BtrBase.GetNext(FilePieceRec, Len, FileKey, 0);
    end;
  end;
end;

procedure TSignFilesForm.FormResize(Sender: TObject);
begin
  //SaveSFileButton.Left := BtnPanel.ClientWidth-SaveSFileButton.Width-6;
  //LoadSFileButton.Left := SaveSFileButton.Left;
  SaveSFileDirectoryEdit.Width := BtnPanel.ClientWidth-SaveSFileDirectoryEdit.Left-5;//-SaveSFileButton.Width;
  LoadSFileDirectoryEdit.Width := SaveSFileDirectoryEdit.Width;
  DelLoadedCheckBox.Left := SaveSFileDirectoryEdit.Left + LoadSFileDirectoryEdit.Width - DelLoadedCheckBox.Width;
  //SaveSFileButton.Left := ?;
end;

procedure TSignFilesForm.StopBitBtnClick(Sender: TObject);
begin
  Process := False;
end;

end.
