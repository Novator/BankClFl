unit BankFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Mask, Buttons;

type
  TBankForm = class(TForm)
    BikEdit: TMaskEdit;
    KsEdit: TMaskEdit;
    KsLabel: TLabel;
    BikLabel: TLabel;
    NameMemo: TMemo;
    NameLabel: TLabel;
    OkBtn: TBitBtn;
    CancelBtn: TBitBtn;
    NpGroupBox: TGroupBox;
    NpTypeComboBox: TComboBox;
    NpTypeLabel: TLabel;
    NPNameEdit: TEdit;
    NpNameLabel: TLabel;
    procedure BikEditKeyPress(Sender: TObject; var Key: Char);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  BankForm: TBankForm;

implementation

{$R *.DFM}

procedure TBankForm.BikEditKeyPress(Sender: TObject; var Key: Char);
begin
  if not ((Key in ['0'..'9']) or (Key < #32)) then
  begin
    Key := #0;
    MessageBeep(0)
  end;
end;

end.
