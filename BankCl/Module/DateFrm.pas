unit DateFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons, Mask, ToolEdit, Utilits, ExtCtrls;

type
  TDateForm = class(TForm)
    DateEdit: TDateEdit;
    DateLabel: TLabel;
    OkBtn: TBitBtn;
    CancelBtn: TBitBtn;
    RemMemo: TMemo;
    RemPanel: TPanel;
    procedure RemPanelClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
  end;

function GetBtrDate(var Value: Word; Capt, Tit, Rem: string): Boolean;

implementation

{$R *.DFM}

function GetBtrDate(var Value: Word; Capt, Tit, Rem: string): Boolean;
var
  DateForm: TDateForm;
  Year, Month, Day: Word;
begin
  if Value = 0 then
  begin
    DecodeDate(Date, Year, Month, Day);
    Value := CodeBtrDate(Year, Month, Day);
  end;
  Application.CreateForm(TDateForm, DateForm);
  with DateForm do
  begin
    if Length(Capt)>0 then
      Caption := Capt;
    if Length(Tit)>0 then
      DateLabel.Caption := Tit;
    if Length(Rem)>0 then
      RemMemo.Text := Rem;
    DateEdit.Text := BtrDateToStr(Value);
    Result := ShowModal = mrOk;
    if Result then
      Value := StrToBtrDate(DateEdit.Text);
    Free;
  end;
end;

procedure TDateForm.RemPanelClick(Sender: TObject);
begin
  if RemPanel.BevelOuter = bvRaised then
  begin
    RemPanel.BevelOuter := bvLowered;
    ClientHeight := RemMemo.Top + RemMemo.Height;
  end
  else begin
    RemPanel.BevelOuter := bvRaised;
    ClientHeight := RemPanel.Top + RemPanel.Height;
  end;
end;

procedure TDateForm.FormCreate(Sender: TObject);
begin
  RemPanelClick(nil);
end;

end.
