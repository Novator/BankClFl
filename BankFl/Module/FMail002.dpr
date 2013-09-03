library FMail002;

{ Important note about DLL memory management: ShareMem must be the
  first unit in your library's USES clause AND your project's (select
  Project-View Source) USES clause if your DLL exports any procedures or
  functions that pass strings as parameters or function results. This
  applies to all strings passed to and from your DLL--even those that
  are nested in records and classes. ShareMem is the interface unit to
  the BORLNDMM.DLL shared memory manager, which must be deployed along
  with your DLL. To avoid using BORLNDMM.DLL, pass string information
  using PChar or ShortString parameters.}

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
  Common,
  Utilits,
  ObmenFrm in 'ObmenFrm.pas' {ObmenForm},
  Posting in 'Posting.pas',
  ResendBillFrm in 'ResendBillFrm.pas' {ResendBillForm};

procedure CreateChildForm(Sender: TObject);
begin
  DoExchange(Application.MainForm, True, False, False, 0, nil, 0, 0);
end;

procedure CreateChildForm2(Sender: TObject);
var
  ResendBillForm: TResendBillForm;
  ReSendCorr, I: Integer;
  AccList: TList;
  d1, d2: Word;
begin
  ResendBillForm := TResendBillForm.Create(Application.MainForm);
  with ResendBillForm do
  begin
    if ShowModal=mrOk then
    begin
      AccList := nil;
      ReSendCorr := 0;
      try
        if ResendCheckBox.Enabled and ResendCheckBox.Checked
          and (CorrWideComboBox.ItemIndex>=0) then
        begin
          ReSendCorr := Integer(CorrWideComboBox.Items.Objects[CorrWideComboBox.ItemIndex]);
          if ReSendCorr>0 then
          begin
            if not AllAccCheckBox.Checked then
            begin
              AccList := TList.Create;
              for I := 0 to AccCheckListBox.Items.Count-1 do
                if AccCheckListBox.Checked[I] then
                  AccList.Add(AccCheckListBox.Items.Objects[I]);
            end;
            d1 := DateToBtrDate(FromDateEdit.Date);
            d2 := DateToBtrDate(ToDateEdit.Date);
          end;
        end;
        DoExchange(Application.MainForm, BaseCheckBox.Checked,
          SprCheckBox.Checked, FileCheckBox.Checked, ReSendCorr, AccList, d1, d2);
      finally
        if AccList<>nil then
          AccList.Free;
      end;
    end;
    Free;
  end;
end;

function NewMenuItem(AOwner: TComponent): TMenuItem;
var
  MI: TMenuItem;
begin
  Result := TMenuItem.Create(AOwner);
  with Result do
  begin
    Caption := '&Сеанс связи (устар.)';
    Hint := 'Обменивается данными с банком';
    GroupIndex := 4;
    HelpContext := 50;
  end;
  ObjList.Add(Result);
  MI := TMenuItem.Create(Result);
  with MI do
  begin
    Caption := '&Основной обмен';
    Hint := 'Обменивается данными с клиентами';
    //ShortCut := TextToShortCut('Ctrl+M');
    ImageIndex := 47;
    {GroupIndex := 4;}
    HelpContext := 50;
    @OnClick := @CreateChildForm;
  end;
  Result.Add(MI);
  MI := TMenuItem.Create(Result);
  with MI do
  begin
    Caption := '&Расширенный обмен';
    Hint := 'Рассылает справочники, файлы, досылает данные';
    //ShortCut := TextToShortCut('Shift+Ctrl+M');
    {ImageIndex := 13;}
    GroupIndex := 4;
    HelpContext := 170;
    @OnClick := @CreateChildForm2;
  end;
  Result.Add(MI);
end;

exports
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

