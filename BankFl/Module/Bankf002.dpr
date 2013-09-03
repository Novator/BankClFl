library Bankf002;

{ Important note about DLL memory management: ShareMem must be the
  first unit in your library's USES clause AND your project's (select
  Project-View Source) USES clause if your DLL exports any procedures or
  functions that pass strings as parameters or function results. This
  applies to all strings passed to and from your DLL--even those that
  are nested in records and classes. ShareMem is the interface unit to
  the BORLNDMM.DLL shared memory manager, which must be deployed along
  with your DLL. To avoid using BORLNDMM.DLL, pass string information
  using PChar or ShortString parameters. }

uses
  SysUtils,
  Classes,
  Dialogs,
  Menus,
  Windows,
  Db,
  SearchFrm,
  Controls,
  BtrDS,
  Forms,
  Basbn,
  Utilits,
  Common,
  CommCons,
  BanksFrm in 'BanksFrm.pas' {BanksForm},
  BankFrm in 'BankFrm.pas' {BankForm};

function EditRecord(Sender: TComponent; BankFullRecPtr: PBankFullNewRec;
  SearchIndex: Integer; ShowDlg: Boolean): Boolean;
var
  ABanksForm: TBanksForm;
  I,ZeroPos,Offset,Err: Integer;
  T: array[0..4095] of Char;
  S: string;
begin
  Result := False;
  if (BanksForm<>nil) and (BankFullRecPtr=nil) then
    BanksForm.Show
  else begin
    ABanksForm := TBanksForm.Create(Sender);
    if BanksForm=nil then
      BanksForm := ABanksForm;
    with ABanksForm do
    begin
      if SearchIndex>=0 then
      begin
        case SearchIndex of
          0:
          begin
            I := BankFullRecPtr^.brCod;
            if ShowDlg then
            begin
              SearchIndexComboBox.ItemIndex := SearchIndex;
              SearchIndexComboBoxChange(nil);
              NameEdit.Text := IntToStr(I);
              NameEditChange(nil);
            end
            else begin
              Result := (DataSource.DataSet as TBtrDataSet).LocateBtrRecordByIndex(
                I, 0, bsEq);
            end;
          end;
          2:
          begin
            StrCopy(T, BankFullRecPtr^.brName);
            if ShowDlg then
            begin
              SearchIndexComboBox.ItemIndex := SearchIndex;
              SearchIndexComboBoxChange(nil);
              I := 0; Err := StrLen(T)-1;
              while (I<Err) and (T[I]<>#13) and (T[I]<>#10) do Inc(I);
              if (I<Err) and ((T[I]=#13) or (T[I]=#10)) then
                T[I] := #0;
              DosToWin(T);
              NameEdit.Text := StrPas(T);
              NameEditChange(nil);
            end
            else begin
              Result := (DataSource.DataSet as TBtrDataSet).LocateBtrRecordByIndex(
                T, 0, bsEq);
            end;
          end;
          else
            MessageBox(Handle, 'Запрос по недопустимому индексу', 'Поиск банка',
              MB_OK + MB_ICONERROR)
        end;
      end;
      if ShowDlg then
      begin
        SearchForm.SourceDBGrid := DBGrid;
        if BankFullRecPtr<>nil then
          Result := ShowModal = mrOk
        else begin
          FormStyle:=fsMDIChild;
          OkBtn.Hide; CancelBtn.Hide;
          Show
        end;
      end;
      if Result and (BankFullRecPtr<>nil) then
      begin
        with BankFullRecPtr^, DataSource.DataSet.Fields do
        begin
          brCod:=Fields[0].AsInteger;
          StrPCopy(brKs,Fields[1].AsString);
          {brType:   array[0..3] of char;	{Аббревиатура}
          StrPCopy(brName, Fields[2].AsString+#13#10+Fields[3].AsString);
          {npName:   array[0..24] of char;	{Наименование нас.пункта}
          {npType:   array[0..4] of char;	{Аббревиатура}
        end;
      end;
      if BankFullRecPtr<>nil then
        Free;
    end;
  end;
end;

procedure CreateChildForm(Sender: TObject);
begin
  EditRecord(Sender as TComponent, nil, -1, True);
end;

function NewMenuItem(AOwner: TComponent): TMenuItem;
begin
  Result:=TMenuItem.Create(AOwner);
  with Result do
  begin
    Caption := '&Банки';
    Hint := 'Показывает справочник банков';
    ShortCut := TextToShortCut('F5');
    GroupIndex := 0;
    HelpContext := 40;
    @OnClick := @CreateChildForm;
  end;
  ObjList.Add(Result);
end;

exports
  NewMenuItem name NewMenuItemDLLProcName,
  EditRecord name EditRecordDLLProcName;

procedure DLLEntryProc(Reason: Integer);
var
  I,K: Integer;
begin
  case Reason of
    DLL_PROCESS_DETACH: begin
      I:=ObjList.Count;
      while I>0 do begin
        K:=I;
        TObject(ObjList.Items[I-1]).Free;
        if K=I then Dec(I);
      end;
      ObjList.Free;
    end;
  end;
end;

begin
  ObjList:=TList.Create;
  DLLProc:=@DLLEntryProc;
end.


