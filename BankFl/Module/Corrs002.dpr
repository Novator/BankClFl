library Corrs002;

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
  BankCnBn,
  CommCons,
  CorrsFrm in 'CorrsFrm.pas' {CorrsForm},
  CorrFrm in 'CorrFrm.pas' {CorrForm},
  AbonStatFrm in 'AbonStatFrm.pas' {AbonStatForm},
  MoveDataFrm in 'MoveDataFrm.pas' {MoveDataForm};

(*function EditCorrRecord(Sender: TComponent; CorrRecPtr: PCorrRec;
  SearchIndex: Integer; ShowDlg: Boolean): Boolean;
var
  I,ZeroPos,Offset,Err: Integer;
  T: array[0..1023] of Char;
  S: string;
  {SearchData: packed record Bik: LongInt; Acc: TAccount end;}
  ACorrsForm: TCorrsForm;
  Login: array[0..9] of Char;
begin
  Result := False;
  if (CorrsForm<>nil) and (CorrRecPtr=nil) then
    CorrsForm.Show
  else begin
    ACorrsForm := TCorrsForm.Create(Sender);
    if CorrsForm=nil then
      CorrsForm := ACorrsForm;
    with ACorrsForm do
    begin
      if SearchIndex>=0 then
      begin
        case SearchIndex of
          0:
          begin
            I := CorrRecPtr^.crIder;
            if ShowDlg then
            begin
              SearchIndexComboBox.ItemIndex := 0;
              SearchIndexComboBoxChange(nil);
              NameEdit.Text := IntToStr(I);
              NameEditChange(nil);
            end
            else begin
              Result := (DataSource.DataSet as TBtrDataSet).LocateBtrRecordByIndex(
                I, 0, bsEq);
            end;
          end;
          1:
          begin
            FillChar(Login, SizeOf(Login), #0);
            StrLCopy(Login, CorrRecPtr^.crName, SizeOf(Login));
            if ShowDlg then
            begin
              SearchIndexComboBox.ItemIndex := 1;
              SearchIndexComboBoxChange(nil);
              NameEdit.Text := Login;
              NameEditChange(nil);
            end
            else begin
              (DataSource.DataSet as TBtrDataSet).LocateBtrRecordByIndex(
                Login, 1, bsEq);
            end;
          end;
          else
            MessageBox(Handle, 'Запрос по недопустимому индексу', 'Поиск клиента',
              MB_OK + MB_ICONERROR);
        end;
      end;
      if ShowDlg then
      begin
        if CorrRecPtr<>nil then
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
      if Result and (CorrRecPtr<>nil) then
      begin
        System.Move(DataSource.DataSet.ActiveBuffer^, CorrRecPtr^,
          SizeOf(TCorrRec));
      end;
      if CorrRecPtr<>nil then
        Free;
    end;
  end;
end; *)

procedure CreateChildForm(Sender: TObject);
begin
  //EditCorrRecord(Sender as TComponent, nil, -1, True);
end;

function NewMenuItem(AOwner: TComponent): TMenuItem;
begin
  Result:=TMenuItem.Create(AOwner);
  with Result do begin
    Caption:='К&орреспонденты';
    Hint:='Показывает список корреспондентов';
    //ShortCut := TextToShortCut('F8');
    GroupIndex := 0;
    ImageIndex := 33;
    HelpContext := 0;
    @OnClick := @CreateChildForm;
  end;
  ObjList.Add(Result);
end;

exports
  //EditCorrRecord name EditClientRecordDLLProcName,
  NewMenuItem name NewMenuItemDLLProcName;

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


