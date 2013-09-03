library Quorm002;

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
  Controls,
  Common,
  Orakle,                                                //Добавлено Меркуловым
  QrmExchangeFrm in 'QrmExchangeFrm.pas' {QrmExchangeForm};

procedure CreateChildForm(Sender: TObject);
begin
  if QrmExchangeForm = nil then
  begin
    QrmExchangeForm := TQrmExchangeForm.Create(Sender as TComponent);
    QrmExchangeForm.ShowModal;
  end;
end;

function NewMenuItem(AOwner: TComponent): TMenuItem;
begin
  Result := TMenuItem.Create(AOwner);
  with Result do
  begin
    Caption:='&Обмен с АБС';
    Hint:='Обменивается данными с банковской системой';
    ImageIndex := 24;
    ShortCut := TextToShortCut('F12');
    GroupIndex := 4;
    HelpContext := 135;
    @OnClick := @CreateChildForm;
    if OraBase.OrBaseConn then                             //Добавлено Меркуловым
      Enabled := False;                            //Добавлено Меркуловым
  end;
  ObjList.Add(Result);
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
  CurrPosDate := Date;
  CurrDate := CurrPosDate;
end.


