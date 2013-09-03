unit KeyPathDlg;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons, Mask, ToolEdit, ExtCtrls, Utilits;

type
  TKeyPathDialog = class(TForm)
    OkBitBtn: TBitBtn;
    BitBtn2: TBitBtn;
    KeyDirectoryEdit: TDirectoryEdit;
    KeyDirLabel: TLabel;
    KeyDirPanel: TPanel;
    DelMailKeyPanel: TPanel;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure KeyDirPanelMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure KeyDirPanelMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure KeyDirPanelClick(Sender: TObject);
    procedure DelMailKeyPanelClick(Sender: TObject);
  private
    { Private declarations }
  public
    FTransDir, FMailKey: string;
  end;

var
  KeyPathDialog: TKeyPathDialog;

implementation

{$R *.DFM}

procedure TKeyPathDialog.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  Action := caHide;
end;

procedure TKeyPathDialog.KeyDirPanelMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  (Sender as TPanel).BevelOuter := bvLowered;
end;

procedure TKeyPathDialog.KeyDirPanelMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  (Sender as TPanel).BevelOuter := bvRaised;
end;

procedure TKeyPathDialog.KeyDirPanelClick(Sender: TObject);
const
  MesTitle: PChar = 'Правка mail.key';
var
  FN: string;
  ResCode: DWord;
begin
  FN := FTransDir+FMailKey;
  if FileExists(FN) then
    RunAndWait('notepad.exe '+FN, SW_SHOW, ResCode)
  else
    MessageBox(Handle, PChar('Файл настройки пути не найден'#13#10'['+FN+']'),
      MesTitle, MB_OK or MB_ICONWARNING);
end;

procedure TKeyPathDialog.DelMailKeyPanelClick(Sender: TObject);
const
  MesTitle: PChar = 'Удаление mail.key';
var
  FN: string;
begin
  FN := FTransDir+FMailKey;
  if FileExists(FN) then
  begin
    if MessageBox(Handle, PChar('Уверены, что хотите удалить файл настройки пути?'#13#10'['+FN+']'),
      MesTitle, MB_YESNOCANCEL or MB_ICONWARNING)=ID_YES then
    begin
      if DeleteFile(FN) then
      begin
        OkBitBtn.Enabled := False;
        MessageBox(Handle, PChar('Файл настройки пути удален'#13#10'['+FN+']'),
          MesTitle, MB_OK or MB_ICONINFORMATION);
      end
      else
        MessageBox(Handle, PChar('Ошибка удаления файла'#13#10'['+FN+']'),
          MesTitle, MB_OK or MB_ICONERROR);
    end;
  end
  else
    MessageBox(Handle, PChar('Файл настройки пути не найден'#13#10'['+FN+']'),
      MesTitle, MB_OK or MB_ICONWARNING);
end;

end.
