unit LettersFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Grids, Db, DBTables, DBGrids, ExtCtrls, DBCtrls, BtrDS, Menus, BankCnBn,
  ComCtrls, StdCtrls, Buttons, SearchFrm, Common, Basbn, Utilits, LetterFrm,
  Registr, CrySign, CommCons;

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
    CorrListComboBox: TComboBox;
    CheckSignItem: TMenuItem;
    SaveOrigItem: TMenuItem;
    EditBreaker3: TMenuItem;
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
  AbonDataSet, NpDataSet: TExtBtrDataSet;

procedure TLettersForm.FormCreate(Sender: TObject);
var
  S: string;
  //ReceiverNode: Integer;
  MailerNode: Integer;
  T: array[0..511] of Char;
begin
  ObjList.Add(Self);
  DataSource.DataSet := GlobalBase(biLetter);
  NpDataSet := GlobalBase(biNp);
  AbonDataSet := GlobalBase(biAbon);
  FillChar(ControlData, SizeOf(ControlData), #0);
  with ControlData do
  begin
    if not GetRegParamByName('MailerNode', GetUserNumber, MailerNode) then
      MailerNode := 0;
    cdTagNode := MailerNode;
    cdCheckSelf := True;
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
  SearchIndexComboBox.ItemIndex := 0;
  SearchIndexComboBoxChange(nil);

  FillCorrList(CorrListComboBox.Items, 0);
  S := BroadCastLogin;
  while Length(S)<8 do
    S := S+' ';
  CorrListComboBox.Items.InsertObject(0, S+' | '+BroadcastName, TObject(BroadcastNode));
  S := GroupLogin;
  while Length(S)<8 do
    S := S+' ';
  CorrListComboBox.Items.InsertObject(1, S+' | '+GroupName, TObject(GroupNode));
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

{function SignLetter(var LetterRec: TLetterRec): Boolean;
const
  MesTitle: PChar = 'Создание подписи';
var
  L, MailerNode: Integer;
begin
  Result := GetRegParamByName('MailerNode', GetUserNumber, MailerNode);
  if Result then
  begin
    L := StrLen(LetterRec.erText) + 1;
    L := L + StrLen(@LetterRec.erText[L]) + 1;
    Result := MakeSign(PChar(@LetterRec.erText), L, MailerNode, 1)>0;
    if not Result then
      MessageBox(Application.MainForm.Handle, 'Не удалось сгенерировать подпись',
        MesTitle, MB_ICONERROR or MB_OK);
  end
  else
    MessageBox(Application.MainForm.Handle, 'Не известен узел получателя',
      MesTitle, MB_ICONERROR or MB_OK);
end;}

{function SignLetter(var LetterRec: TLetterRec): Integer;
const
  MesTitle: PChar = 'Создание подписи письма';
var
  L, ReceiverNode: Integer;
begin
  L := StrLen(LetterRec.erText) + 1;
  L := L + StrLen(@LetterRec.erText[L]) + 1;
  ControlData.cdCheckSelf := True;
  Result := AddSign(0, @LetterRec.erText, L, SizeOf(LetterRec.erText),
    smOverwrite or smShowInfo, @ControlData);
  if Result<=0 then
    MessageBox(Application.MainForm.Handle, 'Не удалось сгенерировать подпись',
      MesTitle, MB_ICONERROR or MB_OK);
end;}

function SignLetter(LetterPtr: Pointer): Integer;
const
  MesTitle: PChar = 'Создание подписи письма';
var
  K, CEI, TxtLen, Len, Res: Integer;
  TxtBuf: PChar;
  AbonRec: TAbonentRec;
begin
  CEI := ceiDomenK;
  K := PLetterRec(LetterPtr)^.lrAdr;
  Len := SizeOf(AbonRec);
  Res := AbonDataSet.BtrBase.GetEqual(AbonRec, Len, K, 0);
  if Res=0 then
  begin
    CEI := AbonRec.abWay;
    ControlData.cdTagNode := AbonRec.abNode;
  end;
  LetterTextPar(LetterPtr, TxtBuf, TxtLen);
  Result := AddSign(CEI, TxtBuf, TxtLen, erMaxVar, smOverwrite or smShowInfo,
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
  I, J, K, Len, Res, AbonId, NSL: LongInt;
  T: array[0..erMaxVar] of Char;
  Editing: Boolean;
  TxtBuf: PChar;
  AbonRec: TAbonentRec;
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
        end;
        if New then
        begin
          SetNew;
          LetterRec.lrState := LetterRec.lrState and not dsInputDoc;
        end;
        with LetterRec do
        begin
          InputDoc := ((lrState and dsInputDoc)<>0) or (lrIdCurI<>0)
            or (lrIdArcI<>0);
          CorrWideComboBox.ItemIndex :=
            CorrWideComboBox.Items.IndexOfObject(TObject(lrAdr));
          ExtToolButton.Down := (lrState and dsExtended)<>0;
          CryptToolButton.Down := (lrState and dsEncrypted)<>0;
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
            with ControlData do
            begin
              cdCheckSelf := (lrState and dsInputDoc)=0;
              if cdCheckSelf then
                cdTagNode := 0
              else begin
                K := lrAdr;
                Len := SizeOf(AbonRec);
                Res := AbonDataSet.BtrBase.GetEqual(AbonRec, Len, K, 0);
                if Res=0 then
                  cdTagNode := AbonRec.abNode
                else
                  cdTagNode := 0;
              end;
              StrLCopy(cdTagLogin, AbonRec.abLogin, SizeOf(cdTagLogin)-1);
            end;
            J := lrTextLen-I;
            K := DecryptBlock(@TxtBuf[I], J, SizeOf(lrText),
              smShowInfo, @ControlData);
            if K<=0 then
              MessageBox(Handle, PChar('Ошибка дешифрации тела письма Err='
                +IntToStr(J)), ProcTitle, MB_OK or MB_ICONERROR)
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
          AbonId := Integer(CorrWideComboBox.Items.Objects[CorrWideComboBox.ItemIndex]);
          Editing := False;
          with LetterRec do
          begin
            if CorrWideComboBox.ItemIndex>=0 then
              lrAdr := AbonId
            else
              lrAdr := 0;
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
              K := lrAdr;
              Len := SizeOf(AbonRec);
              Res := AbonDataSet.BtrBase.GetEqual(AbonRec, Len, K, 0);
              if Res=0 then
              begin
                with ControlData do
                begin
                  cdCheckSelf := True;
                  cdTagNode := AbonRec.abNode;
                  Move(AbonRec.abLogin, cdTagLogin, SizeOf(cdTagLogin)-1);
                end;
                K := EncryptBlock(AbonRec.abCrypt, @TxtBuf[I], J, SizeOf(lrText),
                  smShowInfo, @ControlData);
                if K>0 then
                begin
                  lrState := lrState or dsEncrypted or dsExtended;
                  J := K;
                end
                else
                  MessageBox(Handle, PChar('Шифрование не удалось Err='
                    +IntToStr(K)), ProcTitle, MB_OK or MB_ICONERROR)
              end
              else
                MessageBox(Handle, PChar('Абонент не найден BtrErr='
                  +IntToStr(Res)), ProcTitle, MB_OK or MB_ICONERROR)
            end;
            I := I + J;
            if (lrState and dsExtended)<>0 then
              lrTextLen := I;
          end;
          I := SizeOf(LetterRec) - erMaxVar + I;
          if (LetterRec.lrState and dsExtended)=0 then
            Dec(I, 2);
          NSL := I;
          if SearchIndexComboBox.ItemIndex<>0 then
          begin
            SearchIndexComboBox.ItemIndex := 0;
            SearchIndexComboBoxChange(nil);
          end;
          LetterRec.lrState := LetterRec.lrState and not (dsSndType or dsInputDoc);
          K := 0;
          if (AbonId=GroupNode) and New and AbonCheckListBox.Visible
            and ((LetterRec.lrState and dsEncrypted)=0) then
          begin
            J := 1;
            Len := AbonCheckListBox.Items.Count;
          end
          else begin
            J := 0;
            Len := 1;
          end;
          Res := 0;
          while K<Len do
          begin
            if (J=0) or AbonCheckListBox.Checked[K] then
            begin
              if J<>0 then
                LetterRec.lrAdr := Integer(AbonCheckListBox.Items.Objects[K]);
              I := SignLetter(@LetterRec);
              if I>0 then
                I := NSL+I
              else
                I := NSL;
              if New then
              begin
                with LetterRec do
                begin
                  lrIdKorr := 0;
                  lrSender := 0;
                  lrIdArcO := 0;
                  lrIdCurI := 0;
                  lrIdArcI := 0;
                  MakeRegNumber(rnPaydoc, lrIder);
                  lrIdCurO := lrIder;
                end;
                if AddBtrRecord(@LetterRec, I) then
                begin
                  if J<>0 then
                    Inc(Res);
                end
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
            Inc(K);
          end;
          if New then
            Refresh;
          if J<>0 then
            MessageBox(Handle, PChar('Всего создано писем: '+IntToStr(Res)),
              ProcTitle, MB_OK or MB_ICONINFORMATION)
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
  I, L: LongInt;
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
            {??
            I := StrLen(erText)+1;
            I := I + StrLen(@erText[I])+1;
            L := 0;
            if LetterIsSigned(LetterRec) then
              FillChar(erText[I], SizeOf(erText)-I, #0)
            else
              L := SignLetter(LetterRec);
            I := SizeOf(LetterRec) - SizeOf(LetterRec.erText) + I + L;
            if UpdateBtrRecord(@LetterRec, I) then
              Refresh
            else
              MessageBox(Handle, 'Не удалось изменить запись', MesTitle,
                MB_OK or MB_ICONERROR)}
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
        if
          ((LetterRec.lrState and dsInputDoc)<>0) and (MessageBox(Handle,
          'Это входящее письмо, не рекомендуется его удалять. Удалить?',
          ProcTitle, MB_YESNOCANCEL or MB_ICONWARNING or MB_DEFBUTTON2)<>IDYES)
          or
          ((LetterRec.lrState and dsSndType) <> dsSndEmpty)
          and (MessageBox(Handle,
          'Письмо уже отправлено, не рекомендуется его удалять. Удалить?',
          ProcTitle, MB_YESNOCANCEL or MB_ICONWARNING or MB_DEFBUTTON2)<>IDYES)
          or
          (MessageBox(Handle, 'Письмо будет удалено из списка. Вы уверены?',
          ProcTitle, MB_YESNOCANCEL or MB_ICONQUESTION)<>IDYES)
        then
          L := 0;
        if L>0 then
          Self.DataSource.DataSet.Delete;
      end;
    end;
  end;
end;

procedure TLettersForm.SearchIndexComboBoxChange(Sender: TObject);
begin
  with DataSource.DataSet as TBtrDataSet do
    case SearchIndexComboBox.ItemIndex of
      0: IndexNum := 2;
      1: IndexNum := 4;
      2: IndexNum := 3;
      3: IndexNum := 5;
      else
        IndexNum := 0;
    end;
end;

procedure TLettersForm.DBGridDblClick(Sender: TObject);
begin
  EditItemClick(Sender)
end;

procedure TLettersForm.TakeFormPrintData(var PrintDocRec: TPrintDocRec; var FormList: TList);
begin
  inherited; 
  PrintDocRec.DBGrid := Self.DBGrid;
  PrintDocRec.GraphForm := DecodeMask('$(LetGraphForm)', 5, GetUserNumber);
  PrintDocRec.TextForm := DecodeMask('$(LetTextForm)', 5, GetUserNumber);
end;

procedure TLettersForm.CheckSignItemClick(Sender: TObject);
const
  MesTitle: PChar = 'Проверка подписи';
var
  K, Len, Len2, Res: Integer;
  LetterRec: TLetterRec;
  TxtBuf: PChar;
  AbonRec: TAbonentRec;
begin
  Len := TExtBtrDataSet(DataSource.DataSet).GetBtrRecord(@LetterRec);
  if Len>0 then
  begin
    K := LetterRec.lrAdr;
    Len2 := SizeOf(AbonRec);
    Res := AbonDataSet.BtrBase.GetEqual(AbonRec, Len2, K, 0);
    if Res=0 then
    begin
      ControlData.cdTagNode := AbonRec.abNode;
      ControlData.cdCheckSelf := (LetterRec.lrState and dsInputDoc)=0;
    end;
    LetterTextPar(@LetterRec, TxtBuf, Len2);
    Len := LetterTextVarLen(@LetterRec, Len);
    CheckSign(TxtBuf, Len2, Len, smShowInfo or smThoroughly, @ControlData, nil, '');
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
