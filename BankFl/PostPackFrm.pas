unit PostPackFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons, Mask, ExtCtrls, Basbn, Registr, Common, CommCons;

type
  TPostPackForm = class(TForm)
    RecvLabel: TLabel;
    VarMemo: TMemo;
    OkBtn: TBitBtn;
    CancelBtn: TBitBtn;
    RecvEdit: TEdit;
    SendEdit: TEdit;
    SendLabel: TLabel;
    VarPanel: TPanel;
    ByteSLabel: TLabel;
    WordSLabel: TLabel;
    ByteSEdit: TEdit;
    WordSEdit: TEdit;
    LenLabel: TLabel;
    NumLabel: TLabel;
    LenEdit: TEdit;
    NumEdit: TEdit;
    IderLabel: TLabel;
    FlSndLabel: TLabel;
    IderEdit: TEdit;
    FlSndEdit: TEdit;
    FlRcvLabel: TLabel;
    FlRcvEdit: TEdit;
    DateSLabel: TLabel;
    DateSEdit: TEdit;
    DateRLabel: TLabel;
    DateREdit: TEdit;
    TimeSLabel: TLabel;
    TimeSEdit: TEdit;
    TimeRLabel: TLabel;
    TimeREdit: TEdit;
    procedure RecvEditKeyPress(Sender: TObject; var Key: Char);
    procedure VarMemoKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

implementation

{$R *.DFM}

procedure TPostPackForm.RecvEditKeyPress(Sender: TObject; var Key: Char);
begin
  if not ((Key in ['0'..'9']) or (Key < #32)) then
  begin
    Key := #0;
    MessageBeep(0)
  end;
end;

procedure TPostPackForm.VarMemoKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_ESCAPE then
    ModalResult := mrCancel;
end;

end.
