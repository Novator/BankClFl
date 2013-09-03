unit AbonSidFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Mask, Buttons, CurrEdit, ToolEdit, ExtCtrls, WideComboBox,
  Utilits, Spin{, Quorum};

type
  TAbonSidForm = class(TForm)
    OkBtn: TBitBtn;
    CancelBtn: TBitBtn;
    NameLabel: TLabel;
    CorrLabel: TLabel;
    NameEdit: TEdit;
    CorrWideComboBox: TWideComboBox;
    StatusGroupBox: TGroupBox;
    DirectorCheckBox: TCheckBox;
    BugalterCheckBox: TCheckBox;
    IdEdit: TEdit;
    IdLabel: TLabel;
    CourierCheckBox: TCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure CorrWideComboBoxKeyPress(Sender: TObject; var Key: Char);
  private
  public
    FNew: Boolean;
  end;

var
  AbonSidForm: TAbonSidForm;

implementation

uses AbonsFrm;

{$R *.DFM}

procedure TAbonSidForm.FormCreate(Sender: TObject);
begin
  FNew := False;
  CorrWideComboBox.Items := AbonsForm.CorrListComboBox.Items;
  CorrWideComboBox.DroppedWidth := 270;
end;

procedure TAbonSidForm.CorrWideComboBoxKeyPress(Sender: TObject;
  var Key: Char);
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
