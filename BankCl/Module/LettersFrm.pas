unit LettersFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Grids, Db, DBTables, DBGrids, ExtCtrls, DBCtrls, BtrDS, Menus, CommCons,
  ComCtrls, StdCtrls, Buttons, SearchFrm, Common, Bases, Utilits, LetterFrm,
  Registr, CrySign;

type
  TLettersForm = class(TDataBaseForm)
    BtnPanel: TPanel;
    StatusBar: TStatusBar;
    DBGrid: TDBGrid;
    DataSource: TDataSource;
    ChildMenu: TMainMenu;
    OperItem: TMenuItem;
    InsItem: TMenuItem;
    EditItem: TMenuItem;
    CopyItem: TMenuItem;
    DelItem: TMenuItem;
    EditBreaker2: TMenuItem;
    FindItem: TMenuItem;
    NameLabel: TLabel;
    SearchIndexComboBox: TComboBox;
    EditPopupMenu: TPopupMenu;
    EditBreaker: TMenuItem;
    ArchItem: TMenuItem;
    SignItem: TMenuItem;
    CheckSignItem: TMenuItem;
    EditBreaker3: TMenuItem;
    SaveOrigItem: TMenuItem;
    SaveDocDialog: TSaveDialog;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure SearchBtnClick(Sender: TObject);
    procedure InsItemClick(Sender: TObject);
    procedure EditItemClick(Sender: TObject);
    procedure CopyItemClick(Sender: TObject);
    procedure DelItemClick(Sender: TObject);
    procedure SearchIndexComboBoxChange(Sender: TObject);
    procedure DBGridDblClick(Sender: TObject);
    procedure ArchItemClick(Sender: TObject);
    procedure SignItemClick(Sender: TObject);
    procedure DBGridDrawColumnCell(Sender: TObject; const Rect: TRect;
      DataCol: Integer; Column: TColumn; State: TGridDrawState);
    procedure CheckSignItemClick(Sender: TObject);
    procedure SaveOrigItemClick(Sender: TObject);
  private
    procedure UpdateRecord(CopyCurrent, New: Boolean);
  public
    SearchForm: TSearchForm;
    procedure TakeFormPrintData(var PrintDocRec: TPrintDocRec; var FormList: TList); override;
  end;

var
  ObjList: TList;
  LettersForm: TLettersForm = nil;

implementation

{$R *.DFM}

var
  ControlData: TControlData;

procedure TLettersForm.FormCreate(Sender: TObject);
var
  T: array[0..511] of Char;
  ColorPayState: Boolean;
  ReceiverNode: Integer;
begin
  ObjList.Add(Self);
  DataSource.DataSet := GlobalBase(biLetter);

  with ControlData do
  begin
    if not GetRegParamByName('ReceiverNode', CommonUserNumber, ReceiverNode) then
      ReceiverNode := -1;
    cdTagNode := ReceiverNode;
    cdCheckSelf := False;
    if GetRegParamByName('ReceiverAcc', CommonUserNumber, T) then
    begin
      StrLCopy(cdTagLogin, T, SizeOf(cdTagLogin)-1);
    end
    else
      cdTagLogin := 'CBTCB';
  end;

  DefineGridCaptions(DBGrid, PatternDir+'Letters.tab');

  SearchForm:=TSearchForm.Create(Self);
  TakeMenuItems(OperItem, EditPopupMenu.Items);
  EditPopupMenu.Images := ChildMenu.Images;
  SearchForm.SourceDBGrid := DBGrid;
  SearchIndexComboBox.ItemIndex := 1;
  SearchIndexComboBoxChange(nil);
  DataSource.DataSet.Last;

  if not GetRegParamByName('ColorPayState', CommonUserNumber, ColorPayState) then
    ColorPayState := False;
  if not ColorPayState then
    DBGrid.OnDrawColumnCell := nil;
end;

procedure TLettersForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action:=caFree;
end;

procedure TLettersForm.FormDestroy(Sender: TObject);
begin
  ObjList.Remove(Self);
  LettersForm := nil;
end;

procedure TLettersForm.SearchBtnClick(Sender: TObject);
begin
  SearchForm.ShowModal;
end;

procedure TLettersForm.TakeFormPrintData(var PrintDocRec: TPrintDocRec; var FormList: TList);
begin
  inherited;
  PrintDocRec.DBGrid := Self.DBGrid;
  PrintDocRec.GraphForm := DecodeMask('$(LetGraphForm)', 5, CommonUserNumber);
  PrintDocRec.TextForm := DecodeMask('$(LetTextForm)', 5, CommonUserNumber);
end;

(*function LetterIsSigned(LetterPtr: Pointer; RecLen: Integer): Boolean;
var
  I: Word;
begin
  if (POldLetterRec(LetterPtr)^.erState and dsExtended)=0 then
  begin
    I := StrLen(POldLetterRec(LetterPtr)^.erText)+1;
    I := I+StrLen(@POldLetterRec(LetterPtr)^.erText[I])+1;
    Result := I<(RecLen-(SizeOf(TOldLetterRec)-erMaxVar));
  end
  else begin
    I := PLetterRec(LetterPtr)^.lrTextLen;
    Result := I<(RecLen-(SizeOf(TLetterRec)-erMaxVar));
  end;
  {Result := CheckSign(@LetterRec.lrText, I, SizeOf(LetterRec), 0, nil)>0;}
end; *)

function SignLetter(LetterPtr: Pointer): Integer;
const
  MesTitle: PChar = 'Создание подписи письма';
var
  TxtLen: Integer;
  TxtBuf: PChar;
begin
  LetterTextPar(LetterPtr, TxtBuf, TxtLen);
  Result := AddSign(0, TxtBuf, TxtLen, erMaxVar, smOverwrite or smShowInfo,
    @ControlData, '');
  if Result<=0 then
    MessageBox(Application.MainForm.Handle, 'Не удалось сгенерировать подпись',
      MesTitle, MB_ICONERROR or MB_OK);
end;

procedure TLettersForm.UpdateRecord(CopyCurrent, New: Boolean);
const
  ProcTitle: PChar = 'Редактирование письма';
var
  LetterForm: TLetterForm;
  LetterRec: TLetterRec;
  I, J, K: LongInt;
  T: array[0..erMaxVar] of Char;
  Editing: Boolean;
  TxtBuf: PChar;
begin
  if not DataSource.DataSet.IsEmpty or (New and not CopyCurrent) then
  begin
    LetterForm := TLetterForm.Create(Self);
    with LetterForm do
    begin
      with TExtBtrDataSet(Self.DataSource.DataSet) do
      begin
        if CopyCurrent then
          GetBtrRecord(@LetterRec)
        else begin
          FillChar(LetterRec, SizeOf(LetterRec), #0);
          if New then
            SetNew;
        end;
        with LetterRec do
        begin
          ExtToolButton.Down := (lrState and dsExtended)<>0;
          CryptToolButton.Down := (lrState and dsEncrypted)<>0;
          InputDoc := ((lrState and dsInputDoc)<>0) or (lrIdCurI<>0)
            or (lrIdArcI<>0);
          UpdState;
          TxtBuf := @lrText;
          if (lrState and dsExtended)=0 then
            TxtBuf := TxtBuf-2;
          I := StrLen(TxtBuf)+1;
          StrLCopy(T, TxtBuf, SizeOf(T));
          DosToWin(T);
          TopicEdit.Text := StrPas(T);

          if ((lrState and dsEncrypted)<>0) and ((lrState and dsExtended)<>0) then
          begin
            J := lrTextLen-I;
            ControlData.cdCheckSelf := not InputDoc;
            K := DecryptBlock(@TxtBuf[I], J, SizeOf(lrText),
              smShowInfo, @ControlData);
            {if K<0 then
              MessageBox(Handle, PChar('Ошибка дешифрации тела письма Err='
                +IntToStr(K)), ProcTitle, MB_OK or MB_ICONERROR)}
          end;

          StrLCopy(T, @TxtBuf[I], SizeOf(T));
          DosToWin(T);
          MessagMemo.Text := StrPas(T);
        end;
        Editing := True;
        if not New and ((LetterRec.lrIdCurO=0)
          or (LetterRec.lrState and dsSndType <> dsSndEmpty))
        then
          ReadOnly := True;
        while Editing and (ShowModal = mrOk) and not ReadOnly do
        begin
          Editing := False;
          with LetterRec do
          begin
            if ExtToolButton.Down then
              lrState := lrState or dsExtended
            else
              lrState := lrState and not dsExtended;
            lrState := lrState and not dsEncrypted;
            TxtBuf := @lrText;
            if (lrState and dsExtended)=0 then
              TxtBuf := TxtBuf-2;
            StrPLCopy(TxtBuf, TopicEdit.Text, erMaxVar-1);
            WinToDos(TxtBuf);
            I := StrLen(TxtBuf)+1;
            StrPLCopy(@TxtBuf[I], MessagMemo.Text, erMaxVar-I-1);
            WinToDos(@TxtBuf[I]);
            J := StrLen(@TxtBuf[I])+1;
            if CryptToolButton.Down then
            begin
              ControlData.cdCheckSelf := True;
              K := EncryptBlock(0, @TxtBuf[I], J, SizeOf(lrText),
                smShowInfo, @ControlData);
              if K>0 then
              begin
                lrState := lrState or dsEncrypted or dsExtended;
                J := K;
              end
              else
                MessageBox(Handle, PChar('Шифрование не удалось Err='
                  +IntToStr(K)), ProcTitle, MB_OK or MB_ICONERROR)
            end;
            I := I + J;
            if (lrState and dsExtended)<>0 then
              lrTextLen := I;
            J := SignLetter(@LetterRec);
            if J>0 then
              I := I+J;
          end;
          I := SizeOf(LetterRec) - erMaxVar + I;
          if (LetterRec.lrState and dsExtended)=0 then
            Dec(I, 2);
          if SearchIndexComboBox.ItemIndex<>0 then
          begin
            SearchIndexComboBox.ItemIndex := 0;
            SearchIndexComboBoxChange(nil);
          end;
          LetterRec.lrState := LetterRec.lrState and not (dsSndType or dsInputDoc);
          if New then
          begin
            with LetterRec do
            begin
              lrIdKorr := 0;
              lrSender := 0;
              lrIdArcO := 0;
              lrIdCurI := 0;
              lrIdArcI := 0;
              lrAdr := 0;
              MakeRegNumber(rnPaydoc, lrIder);
              lrIdCurO := lrIder;
            end;
            if AddBtrRecord(@LetterRec, I) then
              Refresh
            else begin
              Editing := True;
              MessageBox(Handle, 'Невозможно добавить запись', ProcTitle,
                MB_OK or MB_ICONERROR)
            end;
          end
          else begin
            if UpdateBtrRecord(@LetterRec, I) then
              UpdateCursorPos
            else begin
              Editing := True;
              MessageBox(Handle, 'Невозможно изменить запись', ProcTitle,
                MB_OK or MB_ICONERROR)
            end;
          end;
        end;
      end;
      Free;
    end;
  end;
end;

procedure TLettersForm.SignItemClick(Sender: TObject);
const
  MesTitle: PChar = 'Изменение подписи';
var
  LetterRec: TLetterRec;
  I, L: Integer;
  TxtBuf: PChar;
begin
  if not DataSource.DataSet.IsEmpty then
  begin
    with TExtBtrDataSet(Self.DataSource.DataSet) do
    begin
      L := GetBtrRecord(@LetterRec);
      if L>0 then
      with LetterRec do
      begin
        if lrIdCurO<>0 then
        begin
          if lrState and dsSndType = dsSndEmpty then
          begin
            LetterTextPar(@LetterRec, TxtBuf, I);
            if LetterIsSigned(@LetterRec, L) then
            begin
              L := 0;
            end
            else
              L := SignLetter(@LetterRec);
            I := SizeOf(LetterRec) - erMaxVar + I + L;
            if UpdateBtrRecord(@LetterRec, I) then
              Refresh
            else
              MessageBox(Handle, 'Не удалось изменить запись', MesTitle,
                MB_OK or MB_ICONERROR)
          end
          else
            MessageBox(Handle, 'Письмо уже отправлено в банк'
              +#13#10'Нельзя изменить подпись',
              MesTitle, MB_OK or MB_ICONINFORMATION);
        end
        else
          MessageBox(Handle, 'Изменить состояние подписи можно только у исходящих писем',
            MesTitle, MB_OK or MB_ICONINFORMATION)
      end;
    end;
  end;
end;

procedure TLettersForm.ArchItemClick(Sender: TObject);
const
  ProcTitle: PChar = 'Изменение индекса';
var
  LetterRec: TLetterRec;
  I, L: LongInt;
begin
  with TExtBtrDataSet(Self.DataSource.DataSet) do
  begin
    L := GetBtrRecord(@LetterRec);
    if L>0 then
    begin
      with LetterRec do
      begin
        I := lrIder;
        if lrIdCurO<>0 then
        begin
          lrIdArcO := lrIdCurO;
          lrIdCurO := 0;
        end
        else
          if lrIdCurI<>0 then
          begin
            lrIdArcI := lrIdCurI;
            lrIdCurI := 0;
          end
          else
            if lrIdArcO<>0 then
            begin
              lrIdCurO := lrIdArcO;
              lrIdArcO := 0;
            end
            else
              if lrIdArcI<>0 then
              begin
                lrIdCurI := lrIdArcI;
                lrIdArcI := 0;
              end
              else
                MessageBox(Handle, 'Без изменений', ProcTitle,
                  MB_OK or MB_ICONERROR)
      end;
      if UpdateBtrRecord(@LetterRec, L) then
      with LetterRec do
      begin
        LocateBtrRecordByIndex(I, IndexNum, bsGe);
        Refresh;
      end
      else
        MessageBox(Handle, 'Не удалось изменить запись', ProcTitle,
          MB_OK or MB_ICONERROR)
    end;
  end;
end;

procedure TLettersForm.InsItemClick(Sender: TObject);
begin
  UpdateRecord(False, True);
end;

procedure TLettersForm.EditItemClick(Sender: TObject);
begin
  UpdateRecord(True, False);
end;

procedure TLettersForm.CopyItemClick(Sender: TObject);
begin
  UpdateRecord(True, True)
end;

procedure TLettersForm.DelItemClick(Sender: TObject);
const
  ProcTitle: PChar = 'Удаление письма';
var
  LetterRec: TLetterRec;
  L: Integer;
begin
  if not DataSource.DataSet.IsEmpty then
  begin
    with TExtBtrDataSet(Self.DataSource.DataSet) do
    begin
      L := GetBtrRecord(@LetterRec);
      if L>0 then
      begin
        if LetterRec.lrState and dsSndType=dsSndEmpty then
        begin
          if MessageBox(Handle, 'Письмо будет удалено из списка. Вы уверены?',
            ProcTitle, MB_YESNOCANCEL or MB_ICONQUESTION) = IDYES
          then
            Self.DataSource.DataSet.Delete;
        end
        else
          MessageBox(Handle, 'Письмо уже отправлено и не может быть удалено'#13#10'Вы можете переместить письмо в архив',
            ProcTitle, MB_OK or MB_ICONINFORMATION);
      end;
    end;
  end;
end;

procedure TLettersForm.SearchIndexComboBoxChange(Sender: TObject);
begin
  with DataSource.DataSet as TExtBtrDataSet do
  begin
    case SearchIndexComboBox.ItemIndex of
      0: IndexNum := 2;
      1: IndexNum := 4;
      2: IndexNum := 3;
      3: IndexNum := 5;
      else
        IndexNum := 0;
    end;
  end;
end;

procedure TLettersForm.DBGridDblClick(Sender: TObject);
begin
  EditItemClick(Sender)
end;

procedure TLettersForm.DBGridDrawColumnCell(Sender: TObject;
  const Rect: TRect; DataCol: Integer; Column: TColumn;
  State: TGridDrawState);
var
  S: string;
  C: TColor;
  F, M: Longint;
  R, G, B: Byte;
begin
  if Column.Field<>nil then
  begin
    if Column.Field.FieldName='erState' then
    begin
      with (Sender as TDBGrid).Canvas do
      begin
        S := Column.Field.AsString;
        if Pos('получ', S)>0 then
          C := clBlue
        else
          if Pos('прин', S)>0 then
            C := clGreen
          else
            if Pos('подп', S)>0 then
              C := clPurple
            else
              if Pos('отпр', S)>0 then
                C := $0088EE
              else
                C := clBlack;
        if Brush.Color=clHighlight then
        begin
          ExtractRGB(ColorToRGB(C), R, G, B);
          M := (R + G + B) div 3;
          F := ColorToRGB(Brush.Color);
          CorrectBg(R, F, M);
          CorrectBg(G, F, M);
          CorrectBg(B, F, M);
          ComposeRGB(R, G, B, F);
          C := F;
        end;
        if {(Brush.Color<>clHighlight)
          and} (ColorToRGB(C) <> ColorToRGB(Brush.Color))
        then
          Font.Color := C;
        TextRect(Rect, Rect.Left+2, Rect.Top+2, S);
      end;
    end;
  end;
end;

procedure TLettersForm.CheckSignItemClick(Sender: TObject);
const
  MesTitle: PChar = 'Проверка подписи';
var
  Len, TxtLen: Integer;
  LetterRec: TLetterRec;
  TxtBuf: PChar;
begin
  Len := TExtBtrDataSet(DataSource.DataSet).GetBtrRecord(@LetterRec);
  if Len>0 then
  begin
    LetterTextPar(@LetterRec, TxtBuf, TxtLen);
    Len := LetterTextVarLen(@LetterRec, Len);
    ControlData.cdCheckSelf := (LetterRec.lrState and dsInputDoc)=0;
    CheckSign(TxtBuf, TxtLen, Len, smShowInfo or smCheckLogin or smThoroughly,
      @ControlData, nil, '');
  end;
end;

procedure TLettersForm.SaveOrigItemClick(Sender: TObject);
const
  MesTitle: PChar = 'Сохранение оригинала';
var
  Len, L: Integer;
  FN: string;
  F: file of Byte;
  LetterRec: TLetterRec;
  TxtBuf: PChar;
begin
  if not DataSource.DataSet.IsEmpty then
  begin
    with TExtBtrDataSet(Self.DataSource.DataSet) do
    begin
      Len := GetBtrRecord(@LetterRec);
      if Len>0 then
      begin
        if SaveDocDialog.Execute then
        begin
          FN := SaveDocDialog.FileName;
          AssignFile(F, FN);
          {$I-} Rewrite(F); {$I+}
          if IOResult=0 then
          begin
            try
              L := LetterTextVarLen(@LetterRec, Len);
              TxtBuf := LetterRec.lrText;
              if (LetterRec.lrState and dsExtended)=0 then
                TxtBuf := TxtBuf-2;
              BlockWrite(F, TxtBuf^, L);
            finally
              CloseFile(F);
            end;
            MessageBox(Handle, PChar('Писмо сохранено в файл '+FN), MesTitle,
              MB_OK or MB_ICONINFORMATION)
          end
          else
            MessageBox(Handle, PChar('Не удалось создать файл '+FN),
              MesTitle, MB_OK or MB_ICONERROR)
        end;
      end;
    end;
  end;
end;

end.
