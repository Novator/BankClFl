library Clntf002;

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
  BtrDS,
  SearchFrm,
  Controls,
  Forms,
  Basbn,
  Utilits,
  Common,
  CommCons,
  ClientsFrm in 'ClientsFrm.pas' {ClientsForm},
  ClientFrm in 'ClientFrm.pas' {ClientForm};

function EditClientRecord(Sender: TComponent; ClientRecPtr: PNewClientRec;
  SearchIndex: Integer; ShowDlg: Boolean; AList: TStrings): Boolean;
var
  T: array[0..1023] of Char;
  SearchData: packed record Bik: LongInt; Acc: TAccount end;
  AClientsForm: TClientsForm;
  Inn: TInn;
begin
  Result := False;
  if (ClientsForm<>nil) and (ClientRecPtr=nil) then
    ClientsForm.Show
  else begin
    AClientsForm := TClientsForm.Create(Sender);
    if ClientsForm=nil then
      ClientsForm := AClientsForm;
    with AClientsForm do
    begin
      if SearchIndex>=0 then
      begin
        case SearchIndex of
          0:
          begin
            with SearchData do
            begin
              Bik:=ClientRecPtr^.clCodeB;
              StrLCopy(Acc,ClientRecPtr^.clAccC,SizeOf(Acc));
            end;
            if ShowDlg then
            begin
              SearchIndexComboBox.ItemIndex:=0;
              SearchIndexComboBoxChange(nil);
              NameEdit.Text := IntToStr(SearchData.Bik)+'/'+SearchData.Acc;
              NameEditChange(nil);
            end
            else begin
              Result := (DataSource.DataSet as TBtrDataSet).LocateBtrRecordByIndex(
                SearchData, 0, bsEq);
            end;
          end;
          1:
          begin
            FillChar(Inn, SizeOf(Inn), #0);
            StrLCopy(Inn, ClientRecPtr^.clInn, SizeOf(Inn));
            if ShowDlg then
            begin
              SearchIndexComboBox.ItemIndex:=1;
              SearchIndexComboBoxChange(nil);
              NameEdit.Text := Inn;
              NameEditChange(nil);
            end
            else begin
              (DataSource.DataSet as TBtrDataSet).LocateBtrRecordByIndex(
                Inn, 1, bsEq);
            end;
          end;
          2:
          begin
            if ShowDlg then
            begin
              SearchIndexComboBox.ItemIndex:=2;
              SearchIndexComboBoxChange(nil);
              StrLCopy(T, ClientRecPtr^.clNameC, SizeOf(T));
              DosToWin(T);
              NameEdit.Text := T;
              NameEditChange(nil);
            end
            else
              Result := (DataSource.DataSet as TBtrDataSet).LocateBtrRecordByIndex(
                ClientRecPtr^.clNameC, 2, bsEq);
          end;
          else
            MessageBox(Handle, 'Запрос по недопустимому индексу', 'Поиск клиента',
              MB_OK + MB_ICONERROR);
        end;
      end;
      if ShowDlg then
      begin
        if ClientRecPtr<>nil then
        begin
          Position := poScreenCenter;
          Result := ShowModal = mrOk
        end
        else begin
          FormStyle := fsMDIChild;
          OkBtn.Hide; CancelBtn.Hide;
          Result := False;
          Show
        end;
      end;
      if Result and (ClientRecPtr<>nil) then
      begin
        System.Move(DataSource.DataSet.ActiveBuffer^, ClientRecPtr^,
          SizeOf(TNewClientRec));
        with ClientRecPtr^ do
        begin
          DosToWin(clNameC);
        end;
        if AList<>nil then
        begin
          AList.Clear;
          with DataSource.DataSet as TBtrDataSet do
          begin
            IndexNum := 1;
            First;
            LocateBtrRecordByIndex(ClientRecPtr^.clInn, 1, bsGe);
            while (PNewClientRec(ActiveBuffer)^.clInn=ClientRecPtr^.clInn)
              and (AList.Count<30) and not Eof do
            begin
              StrLCopy(T, PNewClientRec(ActiveBuffer)^.clAccC, SizeOf(TAccount));
              AList.Add(T);
              Next;
            end;
          end;
        end;
      end;
      if ClientRecPtr<>nil then
        Free;
    end;
  end;
end;

procedure CreateChildForm(Sender: TObject);
begin
  EditClientRecord(Sender as TComponent, nil, -1, True, nil);
end;

function NewMenuItem(AOwner: TComponent): TMenuItem;
begin
  Result:=TMenuItem.Create(AOwner);
  with Result do begin
    Caption:='&Клиенты';
    Hint:='Показывает справочник клиентов';
    ShortCut := TextToShortCut('F4');
    GroupIndex := 0;
    ImageIndex := -1;
    HelpContext := 45;
    @OnClick:=@CreateChildForm;
  end;
  ObjList.Add(Result);
end;

exports
  EditClientRecord name EditClientRecordDLLProcName,
  NewMenuItem name NewMenuItemDLLProcName;

procedure DLLEntryProc(Reason: Integer);
var
  I: Integer;
begin
  case Reason of
    DLL_PROCESS_DETACH:
      begin
        I := ObjList.Count;
        while I>0 do
        begin
          TObject(ObjList.Items[I-1]).Free;
          Dec(I);
        end;
        ObjList.Free;
      end;
  end;
end;

begin
  ObjList := TList.Create;
  DLLProc := @DLLEntryProc;
end.


