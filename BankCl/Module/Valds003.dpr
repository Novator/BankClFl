library Valds003;

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
  Forms,
  Common,
  Utilits,
  Bases,
  CommCons,
  ValdocsFrm in 'ValdocsFrm.pas' {ValdocsForm},
  ValBillsFrm in 'ValBillsFrm.pas' {ValBillsForm},
  DateFrm in 'DateFrm.pas' {DateForm};

procedure CreateChildForm(Sender: TObject);
begin
  if ValdocsForm=nil then
    ValdocsForm := TValdocsForm.Create(Sender as TComponent)
  else
    ValdocsForm.Show;
end;

function NewMenuItem(AOwner: TComponent): TMenuItem;
begin
  Result := TMenuItem.Create(AOwner);
  with Result do
  begin
    Caption := '&�������� �������';
    Hint := '��������� ������ �������� ����������';
    ShortCut := TextToShortCut('F3');
    @OnClick := @CreateChildForm;
    GroupIndex := 0;
    ImageIndex := 35;
    HelpContext := 30;
  end;
  PayObjList.Add(Result);
end;

exports
  NewMenuItem name NewMenuItemDLLProcName;

procedure LoadDLLs;
const
  MesTitle: PChar = '�������� ������� ��������';
var
  DLLModule: HModule;
  P: Pointer;
  Len, Res: Integer;
  DLLName: array[0..525] of Char;
  ModuleDataSet: TExtBtrDataSet;
  ModuleRec: TModuleRec;
  Key: packed record
    kKind: Byte;
    kIder: Integer;
  end;
begin
  ModuleDataSet := GlobalBase(biModule);
  if ModuleDataSet<>nil then
  begin
    with Key do
    begin
      kKind := mkPayDialog;
      kIder := 0;
    end;
    Len := SizeOf(ModuleRec);
    Res := ModuleDataSet.BtrBase.GetGE(ModuleRec, Len, Key, 0);
    while (Res=0) and (Key.kKind=mkPayDialog) do
    begin
      StrPLCopy(DLLName, ModuleDir+ModuleRec.mrName+'.dll', SizeOf(DLLName)-1);
      DLLModule := LoadLibrary(DLLName);
      if DLLModule=0 then
        MessageBox(ParentWnd, PChar('������ �������� '+DLLName+' ('
          +IntToStr(GetLastError)+')'), MesTitle, MB_OK or MB_ICONERROR)
      else begin
        P := GetProcAddress(DLLModule, DocumentsDLLProcName);
        if P=nil then begin
          FreeLibrary(DLLModule);
          MessageBox(ParentWnd, PChar('� DLL '+DLLName
            +' ��� ��������� ������������� '
            +DocumentsDLLProcName), MesTitle,
            MB_OK or MB_ICONERROR)
        end
        else
          DLLList.Add(Pointer(DLLModule));
      end;
      Len := SizeOf(ModuleRec);
      Res := ModuleDataSet.BtrBase.GetNext(ModuleRec, Len, Key, 0);
    end;
  end
  else
    MessageBox(ParentWnd, '�� ������� ������� ������ �������',
      MesTitle, MB_OK or MB_ICONERROR)
end;

procedure FreeDLLs;
var
  I: Integer;
  P: Pointer;
begin
  for I := 1 to DLLList.Count do
  begin
    P := DLLList.Items[I-1];
    FreeLibrary(HINST(P));
  end;
  DLLList.Clear;
end;

procedure DLLEntryProc(Reason: Integer);
var
  I: Integer;
begin
  case Reason of
    DLL_PROCESS_ATTACH:
      begin
        PayObjList := TList.Create;
        DLLList := TList.Create;
        PayObjList.Add(DLLList);
        LoadDLLs;
      end;
    DLL_PROCESS_DETACH:
      begin
        FreeDLLs;
        I := PayObjList.Count;
        while I>0 do
        begin
          TObject(PayObjList.Items[I-1]).Free;
          Dec(I);
        end;
        PayObjList.Free;
      end;
  end;
end;

begin
  DLLProc := @DLLEntryProc;
  DLLEntryProc(DLL_PROCESS_ATTACH);
end.

