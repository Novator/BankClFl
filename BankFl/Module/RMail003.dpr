library RMail003;

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
  Common,
  CommCons,
  Basbn,
  Registr,
  Btrieve,
  Utilits,
  //Sign,
  MailFrm in 'MailFrm.pas' {MailForm},
  PackProcess in 'PackProcess.pas';

//var
  //Res, Len: Integer;
  //Base: TBtrBase;
  //ps: PSndPack;
  //pr: PRcvPack;

{procedure AddMessage(Mes: string; C: Integer; var S: string);
begin
  if C>0 then
  begin
    if Length(S)>0 then
      S := S + #13#10;
    S := S + Mes + ' - ' + IntToStr(C);
  end;
end;

procedure AddMes(Mes: string; C: Integer; var S: string);
begin
  if C>0 then
  begin
    if Length(S)>0 then
      S := S + '; ';
    S := S + Mes + ':' + IntToStr(C);
  end;
end;

procedure AddStrMes(Mes: string; var S: string);
begin
  if Length(Mes)>0 then
  begin
    if Length(S)>0 then
      S := S + '; ';
    S := S + Mes;
  end;
end;}

function NewMenuItem(AOwner: TComponent): TMenuItem;
var
  MI: TMenuItem;
begin
  Result := TMenuItem.Create(AOwner);
  with Result do
  begin
    Caption := '&Сеанс связи';
    Hint := 'Обменивается данными с почтовой машиной';
    GroupIndex := 5;
    HelpContext := 50;
  end;
  ObjList.Add(Result);
  MI := TMenuItem.Create(Result);
  with MI do
  begin
    Caption := '&Основной обмен';
    Hint := 'Создает основную рассылку по абонентам';
    ShortCut := TextToShortCut('Ctrl+M');
    ImageIndex := 13;
    GroupIndex := 5;
    HelpContext := 50;
    @OnClick := @TMailForm.CreateChildForm;
  end;
  Result.Add(MI);
  MI := TMenuItem.Create(Result);
  with MI do
  begin
    Caption := '&Расширенный обмен';
    Hint := 'Кроме основной рассылки, позволяет выбрать дополнительные: справочники, файлы, данные';
    ShortCut := TextToShortCut('Shift+Ctrl+M');
    Tag := 1;
    GroupIndex := 5;
    HelpContext := 170;
    @OnClick := @TMailForm.CreateChildForm;
  end;
  Result.Add(MI);
end;

exports
  NewMenuItem name NewMenuItemDLLProcName;

procedure LoadDLLs;
const
  MesTitle: PChar = 'Загрузка модулей диалогов';
  DllNameList: array[0..1] of PChar = ('wininet.dll', 'rasapi32.dll');
  DllFuncNames1: array[0..1] of PChar = ('InternetAutodial',
    'InternetAutodialHangup');
  DllFuncNames2: array[0..3] of PChar = ('RasEnumConnectionsA', 'RasHangUpA',
    'RasCreatePhonebookEntryA', 'RasEditPhonebookEntryA');
var
  I, J: Integer;
  DLLModule: HModule;
  P: Pointer;
begin
  InternetAutoDialPtr := nil;
  InternetAutodialHangupPtr := nil;
  RasEnumConnectionsPtr := nil;
  RasHangUpPtr := nil;
  for I := 0 to 1 do
  begin
    DLLModule := LoadLibrary(DllNameList[I]);
    if DLLModule=0 then
      ProtoMes(plTrace, MesTitle, 'Ошибка подключения модуля '+DllNameList[I]
        +' LastErr='+IntToStr(GetLastError))
    else begin
      DLLList.Add(Pointer(DLLModule));
      case I of
        0:
          for J := 0 to 1 do
          begin
            P := GetProcAddress(DLLModule, DllFuncNames1[J]);
            if P<>nil then
              case J of
                0:
                  InternetAutoDialPtr := P;
                1:
                  InternetAutodialHangupPtr := P;
              end
            else
              ProtoMes(plTrace, MesTitle, 'Нет функции '+DllFuncNames1[J]
                + ' в '+DllNameList[I]);
          end;
        1:
          for J := 0 to 3 do
          begin
            P := GetProcAddress(DLLModule, DllFuncNames2[J]);
            if P<>nil then
              case J of
                0:
                  RasEnumConnectionsPtr := P;
                1:
                  RasHangUpPtr := P;
                2:
                  RasCreatePhonebookEntryPtr := P;
                3:
                  RasEditPhonebookEntryPtr := P;
              end
            else
              ProtoMes(plTrace, MesTitle, 'Нет функции '+DllFuncNames2[J]
                + ' в '+DllNameList[I]);
          end;
      end;
    end;
  end;
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

