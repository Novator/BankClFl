unit VekselFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons, Mask, ToolEdit, Utilits, ExtCtrls;

type
  TVekselForm = class(TForm)
    AccLabel: TLabel;
    OkBtn: TBitBtn;
    CancelBtn: TBitBtn;
    RemMemo: TMemo;
    RemPanel: TPanel;
    AccComboBox: TComboBox;
    procedure RemPanelClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure AccComboBoxKeyPress(Sender: TObject; var Key: Char);
    procedure FormDestroy(Sender: TObject);
  private
    { Private declarations }
  public
  end;

function GetAcc(Mes: string; var Acc: string): Boolean;

implementation

{$R *.DFM}

const
  MustAdd: Boolean = False;

function GetAcc(Mes: string; var Acc: string): Boolean;
var
  VekselForm: TVekselForm;
begin
  Application.CreateForm(TVekselForm, VekselForm);
  with VekselForm do
  begin
    RemMemo.Text := Mes + #13#10 + RemMemo.Text;
    Result := ShowModal = mrOk;
    if Result then
    begin
      Acc := AccComboBox.Text;
      MustAdd := True;
    end;
    Free;
  end;
end;

procedure TVekselForm.RemPanelClick(Sender: TObject);
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

function VekselAccFN: string;
begin
  Result := BaseDir + 'veksacc.txt';
end;

procedure TVekselForm.FormCreate(Sender: TObject);
var
  F: TextFile;
  S: string;
begin
  MustAdd := False;
  RemPanelClick(nil);
  AssignFile(F, VekselAccFN);
  FileMode := 0;
  {$I-} Reset(F); {$I+}
  if IOResult=0 then
  begin
    ReadLn(F, S);
    S := Trim(S);
    if Length(S)>0 then
      AccComboBox.Items.Add(S);
    CloseFile(F);
  end;
end;

procedure TVekselForm.AccComboBoxKeyPress(Sender: TObject; var Key: Char);
begin
  if not ((Key in ['0'..'9']) or (Key < #32)) then
  begin
    Key := #0;
    MessageBeep(0)
  end;
end;

procedure TVekselForm.FormDestroy(Sender: TObject);
var
  I: Integer;
  S: string;
begin
  S := AccComboBox.Text;
  if MustAdd and (Length(S)>0) then
  begin
    I := AccComboBox.Items.IndexOf(S);
    if I<>0 then
    begin
      if I>0 then
        AccComboBox.Items.Delete(I);
      AccComboBox.Items.Insert(0, S);
      try
        AccComboBox.Items.SaveToFile(VekselAccFN);
      except
      end;
    end;
  end;
end;

end.
