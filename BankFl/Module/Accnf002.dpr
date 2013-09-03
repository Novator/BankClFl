library Accnf002;

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
  Common,
  Controls,
  Basbn,
  BankCnBn,
  CommCons,
  Registr,
  Utilits,
  BtrDS,
  ArchAccsFrm in 'ArchAccsFrm.pas' {ArchAccsForm},
  AccountsFrm in 'AccountsFrm.pas' {AccountsForm},
  AccWorkFrm in 'AccWorkFrm.pas' {AccWorkForm},
  AccountFrm in 'AccountFrm.pas' {AccountForm},
  MakesFrm in 'MakesFrm.pas' {MakesForm},
  MakesAllFrm in 'MakesAllFrm.pas' {MakesAllForm},
  BillCompareFrm in 'BillCompareFrm.pas' {BillCompareForm};

procedure CreateChildForm(Sender: TObject);
begin
  if AccountsForm = nil then
    AccountsForm := TAccountsForm.Create(Sender as TComponent)
  else
    AccountsForm.Show;
end;

function NewMenuItem(AOwner: TComponent): TMenuItem;
begin
  Result := TMenuItem.Create(AOwner);
  with Result do begin
    Caption := '&Счета';
    Hint := 'Показывает состояние счетов';
    ShortCut:=TextToShortCut('F7');
    GroupIndex := 0;
    ImageIndex := 23;
    HelpContext := 120;
    @OnClick := @CreateChildForm;
  end;
  ObjList.Add(Result);
end;

exports
  NewMenuItem name NewMenuItemDLLProcName;

procedure LoadDLLs;
const
  MesTitle: PChar = 'Загрузка модулей диалогов';
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
        MessageBox(0, PChar('Ошибка открытия '+DLLName+' ('
          +IntToStr(GetLastError)+')'), MesTitle, MB_OK or MB_ICONERROR)
      else begin
        P := GetProcAddress(DLLModule, DocumentsDLLProcName);
        if P=nil then begin
          FreeLibrary(DLLModule);
          MessageBox(0, PChar('В DLL '+DLLName
            +' нет процедуры инициализации '
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
    MessageBox(0, 'Не удалось открыть список модулей',
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
        ObjList := TList.Create;
        DLLList := TList.Create;
        ObjList.Add(DLLList);
        LoadDLLs;
      end;
    DLL_PROCESS_DETACH:
      begin
        FreeDLLs;
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
  DLLProc := @DLLEntryProc;
  DLLEntryProc(DLL_PROCESS_ATTACH);
end.


