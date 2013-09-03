unit ReturnFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons, Mask, ExtCtrls, Basbn, Registr, Common, CommCons,
  ToolEdit, Utilits, ShellApi;

type
  TReturnForm = class(TForm)
    NameLabel: TLabel;
    OkBtn: TBitBtn;
    CancelBtn: TBitBtn;
    DateLabel: TLabel;
    DateEdit: TDateEdit;
    RemMemo: TMemo;
    RemLabel: TLabel;
    RetComboBox: TComboBox;
    RetSetupPanel: TPanel;
    procedure RetSetupPanelMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure RetSetupPanelMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure RetSetupPanelClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

implementation

uses PaydocsFrm;

{$R *.DFM}

procedure TReturnForm.RetSetupPanelMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbLeft then (Sender as TPanel).BevelOuter := bvLowered;
end;

procedure TReturnForm.RetSetupPanelMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  with (Sender as TPanel) do
    if BevelOuter = bvLowered then BevelOuter := bvRaised;
end;

procedure TReturnForm.RetSetupPanelClick(Sender: TObject);
var
  Url: array[0..511] of Char;
  FN: string;
begin
  FN := BaseDir+'Return.txt';
  StrPLCopy(Url, FN, SizeOf(Url));
  Screen.Cursor := crHourGlass;
  ShellExecute(Application.Handle, nil, @Url, nil, nil,
    SW_SHOWNORMAL);
  Screen.Cursor := crDefault;
  try
    MessageBox(Handle, 'Изменения вступят в силу после следующего открытия окна "Платежные документы"',
      'Предупреждение', MB_OK or MB_ICONINFORMATION);
    PaydocsForm.ReturnComboBox.Items.LoadFromFile(FN);
    RetComboBox.Items := PaydocsForm.ReturnComboBox.Items;
  except
  end;
end;

end.
