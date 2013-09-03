unit Common;
          
interface

uses
  Classes, SysUtils, Forms, Db, DbGrids, Dialogs,
  Messages, Controls, Menus;

const
  WM_MAKESTATEMENT = WM_USER + 20;
  WM_REBUILDTOOLBAR = WM_USER + 21;
  WM_MAKEUPDATE = WM_USER + 22;
  WM_USERAUTORIZATION = WM_USER + 23;
  WM_SHOWHINT = WM_USER + 24;
  WM_PRINTDOC = WM_USER + 25;
  WM_PRINTTABLE = WM_USER + 26;
  WM_GETVERNUM = WM_USER + 27;
  WM_CHECKNEWLETTER = WM_USER + 28;
  WM_CHECKANDHIDEAPP = WM_USER + 29;

const
  NewMenuItemDLLProcName = 'NewMenuItem';
  DocumentsDLLProcName = 'GetDocuments';
  EditRecordDLLProcName = 'EditRecord';
  EditClientRecordDLLProcName = 'EditClientRecord';
  AddClientRecordDLLProcName = 'AddClientRecord';
  PrintFormDLLProcName = 'GetPrintForm';

  SC_BANKCLCOMMAND = 64555;
  bccDoMail  = 101;
  bccDoMinimize  = 102;
  bccDoAnimateIcon  = 103;

type
  PPrintDocRec = ^TPrintDocRec;
  TPrintDocRec = record
    GraphForm, TextForm: TFileName;

    //Добавлено Меркуловым
    CassCopy: Word;                         //Кол-во копий для печати касс.ордера

    DBGrid: TDBGrid;
  end;

  TDataBaseForm = class(TForm)
  private
    procedure WMMDIActivate(var Message: TWMMDIActivate); message WM_MDIACTIVATE;
    {procedure DoMenuChange(Sender: TObject; Source: TMenuItem; Rebuild: Boolean);}
  public
    procedure AfterConstruction; override;
    procedure TakeFormPrintData(var PrintDocRec: TPrintDocRec; var FormList: TList); virtual;
    procedure TakeTabPrintData(var PrintDocRec: TPrintDocRec; var FormList: TList); virtual;
    {procedure Activate; override;}
  end;

function GetVersionNum: LongWord;

implementation

uses Windows;

function GetVersionNum: LongWord;
begin
  if (Application<>nil) and (Application.MainForm<>nil) then
    Result := SendMessage(Application.MainForm.Handle, WM_GETVERNUM, 0, 0)
  else
    Result := 0;
end;

procedure TDataBaseForm.AfterConstruction;
begin
  if (Application<>nil) and (Application.MainForm<>nil)
    and (Application.MainForm.Menu<>nil)
  then
    Menu.Images := Application.MainForm.Menu.Images;
  {Menu.OnChange := DoMenuChange;}
  inherited AfterConstruction;
end;

{procedure TDataBaseForm.DoMenuChange(Sender: TObject; Source: TMenuItem; Rebuild: Boolean);
var
  AOnChange: TMenuChangeEvent;
begin
  if (FormStyle = fsMDIChild)
    and not (csDestroying in Application.MainForm.ComponentState) then
  begin
    AOnChange := Application.MainForm.Menu.OnChange;
    if Assigned(AOnChange) then AOnChange(Self, Source, Rebuild);
  end;
end;}

procedure TDataBaseForm.WMMDIActivate(var Message: TWMMDIActivate);
begin
  if (Application<>nil) and not Application.Terminated
    and (Application.MainForm<>nil) and (FormStyle = fsMDIChild)
    and not(csDestroying in Application.MainForm.ComponentState)
  then
    PostMessage(Application.MainForm.Handle, WM_REBUILDTOOLBAR, 0, 0);
    {PostMessage(Application.MainForm.Handle, CM_ACTIVATE, 0, 0);}
  inherited;
end;

procedure TDataBaseForm.TakeFormPrintData(var PrintDocRec: TPrintDocRec;
  var FormList: TList);
begin
  with PrintDocRec do
  begin
    GraphForm := '';
    TextForm := '';
    DBGrid := nil;
  end;
  FormList := nil;
end;

procedure TDataBaseForm.TakeTabPrintData(var PrintDocRec: TPrintDocRec;
  var FormList: TList);
begin
  with PrintDocRec do
  begin
    GraphForm := '';
    TextForm := '';
    DBGrid := nil;
  end;
  FormList := nil;
end;


end.
