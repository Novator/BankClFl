library EMail003;

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
  Bases,
  Utilits,
  Common,
  CommCons,
  LettersFrm in 'LettersFrm.pas' {LettersForm},
  LetterFrm in 'LetterFrm.pas' {LetterForm};

procedure CreateChildForm(Sender: TObject);
begin
  if LettersForm=nil then
    LettersForm := TLettersForm.Create(Sender as TComponent)
  else
    LettersForm.Show;
end;

function NewMenuItem(AOwner: TComponent): TMenuItem;
begin
  Result := TMenuItem.Create(AOwner);
  with Result do
  begin
    Caption := '�&�����';
    Hint := '���������� ������ ����� ������ � ��������';
    ShortCut := TextToShortCut('F6');
    GroupIndex := 0;
    HelpContext := 140;
    @OnClick := @CreateChildForm;
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
    DLL_PROCESS_DETACH:
      begin
        I := ObjList.Count;
        while I>0 do
        begin
          K:=I;
          TObject(ObjList.Items[I-1]).Free;
          if K=I then
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


