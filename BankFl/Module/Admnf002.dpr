library Admnf002;

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
  AdminFrm in 'AdminFrm.pas' {AdminForm},
  UserFrm in 'UserFrm.pas' {UserForm},
  SanctFrm in 'SanctFrm.pas' {SanctForm};

procedure CreateChildForm(Sender: TObject);
begin
  if AdminForm = nil then
    AdminForm := TAdminForm.Create(Sender as TComponent)
  else
    AdminForm.Show;
end;

function NewMenuItem(AOwner: TComponent): TMenuItem;
begin
  Result := TMenuItem.Create(AOwner);
  with Result do begin
    Caption := '&Администрирование';
    Hint := 'Настраивает привилегии пользователей';
    {ShortCut:=TextToShortCut('Shift+F12');}
    GroupIndex := 4;
    HelpContext := 95;
    @OnClick:=@CreateChildForm;
  end;
  ObjList.Add(Result);
end;

exports
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


