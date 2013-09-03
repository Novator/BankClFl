unit AbsUserFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons, Mask, ExtCtrls, Basbn, Registr, Common, CommCons;

type
  TAbsUserForm = class(TForm)
    OkBtn: TBitBtn;
    CancelBtn: TBitBtn;
    IdEdit: TEdit;
    WayLabel: TLabel;
    NameEdit: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    QrmNameEdit: TEdit;
    procedure InnEditKeyPress(Sender: TObject; var Key: Char);
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

procedure TAbsUserForm.InnEditKeyPress(Sender: TObject; var Key: Char);
begin
  if not ((Key in ['0'..'9']) or (Key < #32)) then
  begin
    Key := #0;
    MessageBeep(0)
  end;
end;

end.
