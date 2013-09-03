unit AccountFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Mask, Buttons, CurrEdit, ToolEdit;

type
  TAccountForm = class(TForm)
    AccEdi: TMaskEdit;
    AccLabel: TLabel;
    OkBtn: TBitBtn;
    CancelBtn: TBitBtn;
    NameLabel: TLabel;
    OpenDateEdit: TDateEdit;
    SumCalcEdit: TRxCalcEdit;
    SumLabel: TLabel;
    OpenDateLabel: TLabel;
    CorrComboBox: TComboBox;
    CorrLabel: TLabel;
    NameEdit: TEdit;
    procedure BikEditKeyPress(Sender: TObject; var Key: Char);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  AccountForm: TAccountForm;

implementation

{$R *.DFM}

procedure TAccountForm.BikEditKeyPress(Sender: TObject; var Key: Char);
begin
  if not ((Key in ['0'..'9']) or (Key < #32)) then
  begin
    Key := #0;
    MessageBeep(0)
  end;
end;

end.
