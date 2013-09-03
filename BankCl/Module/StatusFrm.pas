unit StatusFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons;

type
  TStatusForm = class(TForm)
    DocGroupBox: TGroupBox;
    SendDateEdit: TEdit;
    RecvDateEdit: TEdit;
    DocTypeEdit: TEdit;
    SendDateLabel: TLabel;
    RecvDateLabel: TLabel;
    DocTypeLabel: TLabel;
    OpGroupBox: TGroupBox;
    BillDateLabel: TLabel;
    OpNumberLabel: TLabel;
    OpTypeLabel: TLabel;
    BillDateEdit: TEdit;
    OpNumberEdit: TEdit;
    OpTypeEdit: TEdit;
    PurposeLabel: TLabel;
    PurposeMemo: TMemo;
    OkBtn: TBitBtn;
    OperNameLabel: TLabel;
    OperNameEdit: TEdit;
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  StatusForm: TStatusForm;

implementation

{$R *.DFM}

procedure TStatusForm.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key=VK_ESCAPE then
    Close;
end;

procedure TStatusForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
end;

end.
