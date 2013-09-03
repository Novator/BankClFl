unit UserFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Mask, Buttons;

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
    FirmLabel: TLabel;
    BaseNumEdit: TEdit;
    procedure OperNumberEditKeyPress(Sender: TObject; var Key: Char);
  private
    { Private declarations }
  public
    { Public declarations }
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

end.
