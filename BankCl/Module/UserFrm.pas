unit UserFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Mask, Buttons, WideComboBox, ToolEdit, Utilits;

type
  TUserForm = class(TForm)
    OkBtn: TBitBtn;
    CancelBtn: TBitBtn;
    LevelComboBox: TComboBox;
    LevelLabel: TLabel;
    IdentLabel: TLabel;
    OperNumberEdit: TEdit;
    NameLabel: TLabel;
    NameEdit: TEdit;
    AccComboBox: TWideComboBox;
    AccLabel: TLabel;
    IderLabel: TLabel;
    IderEdit: TEdit;
    KeyPathDirectoryEdit: TDirectoryEdit;
    KeyPathLabel: TLabel;
    StatusGroupBox: TGroupBox;
    DirCheckBox: TCheckBox;
    BuhCheckBox: TCheckBox;
    MailCheckBox: TCheckBox;
    procedure OperNumberEditKeyPress(Sender: TObject; var Key: Char);
    procedure IderEditKeyPress(Sender: TObject; var Key: Char);
  private
  public
  end;

var
  UserForm: TUserForm;

implementation

{$R *.DFM}

procedure TUserForm.OperNumberEditKeyPress(Sender: TObject; var Key: Char);
begin
  if not ((Key in ['0'..'9']) or (Key < #32)) then
  begin
    Key := #0;
    MessageBeep(0)
  end;
end;

procedure TUserForm.IderEditKeyPress(Sender: TObject; var Key: Char);
begin
  Key := RusToLat(Key);
  if not ((Key in ['0'..'9', 'a'..'z', 'A'..'Z'])
    or (Key < #32)) then
  begin
    Key := #0;
    MessageBeep(0)
  end
  else
    Key := UpCase(Key);
end;

end.
