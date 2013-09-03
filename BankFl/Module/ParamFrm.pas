unit ParamFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons, Mask, ExtCtrls, Basbn, Registr, Common, BankCons;

type
  TParamForm = class(TForm)
    NodeLabel: TLabel;
    NameLabel: TLabel;
    OkBtn: TBitBtn;
    CancelBtn: TBitBtn;
    NodeEdit: TEdit;
    NameEdit: TEdit;
    LoginEdit: TEdit;
    LoginLabel: TLabel;
    LockGroupBox: TGroupBox;
    SendLockCheckBox: TCheckBox;
    RecieveLockCheckBox: TCheckBox;
    BranchCheckBox: TCheckBox;
    WayComboBox: TComboBox;
    WayLabel: TLabel;
    CryptCheckBox: TCheckBox;
    SizeLabel: TLabel;
    SizeComboBox: TComboBox;
    procedure NodeEditKeyPress(Sender: TObject; var Key: Char);
    procedure LoginEditKeyPress(Sender: TObject; var Key: Char);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

implementation

{$R *.DFM}

type
  EditRecord = function(Sender: TComponent; RecPtr: Pointer;
    SearchIndex: Integer; ShowDlg: Boolean): Boolean;

procedure TParamForm.NodeEditKeyPress(Sender: TObject; var Key: Char);
begin
  if not ((Key in ['0'..'9']) or (Key < #32)) then
  begin
    Key := #0;
    MessageBeep(0)
  end;
end;

procedure TParamForm.LoginEditKeyPress(Sender: TObject; var Key: Char);
begin
  if not ((Key in ['0'..'9', 'a'..'z', 'A'..'Z'])
    or (Key < #32)) then
  begin
    Key := #0;
    MessageBeep(0)
  end
  else
    Key := UpCase(Key);
end;

procedure TParamForm.FormShow(Sender: TObject);
begin
  OkBtn.Enabled := (Length(NameEdit.Text)>0) and (Length(LoginEdit.Text)>0)
    and (Length(SizeComboBox.Text)>0) and (Length(NodeEdit.Text)>0);
end;

end.
