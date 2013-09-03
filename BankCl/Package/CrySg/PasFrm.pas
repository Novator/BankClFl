unit PasFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons, ExtCtrls;

type
  TPasEnterForm = class(TForm)
    MainPasEdit: TEdit;
    MainPasLabel: TLabel;
    OperEdit: TEdit;
    OperLabel: TLabel;
    OperPasEdit: TEdit;
    OperPasLabel: TLabel;
    BtnPanel: TPanel;
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    BitBtn3: TBitBtn;
    LangLabel: TLabel;
    IndicTimer: TTimer;
    CapsLabel: TLabel;
    procedure IndicTimerTimer(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure OperEditKeyPress(Sender: TObject; var Key: Char);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

function GetPasswords(AOwner: TComponent; DlgType: Byte; Capt: string;
  ChangeKL: Boolean; var Pass: string): Integer;

implementation

{$R *.DFM}

function GetPasswords(AOwner: TComponent; DlgType: Byte; Capt: string;
  ChangeKL: Boolean; var Pass: string): Integer;
var
  PasEnterForm: TPasEnterForm;
  Eng: HKL;
  //KeyState: TKeyboardState;
begin
  Result := IDABORT;
  PasEnterForm := TPasEnterForm.Create(AOwner);
  with PasEnterForm do
  begin
    Caption := Capt;
    if ChangeKL then
    begin
      Eng := LoadKeyboardLayout('00000409', 0);
      ActivateKeyboardLayout(Eng, 0);
      //GetKeyboardState(KeyState);
      //if KeyState[VK_CAPITAL] <> 0 then
      //  KeyState[VK_CAPITAL] := 0;
      //SetKeyboardState(KeyState);
    end;
    if DlgType=0 then
    begin
      MainPasLabel.Show;
      MainPasEdit.Show;
      ClientHeight := ClientHeight - 36;
    end
    else begin
      OperLabel.Show;
      OperEdit.Show;
      OperPasLabel.Show;
      OperPasEdit.Show;
    end;
    case ShowModal of
      mrOk:
        begin
          if DlgType=0 then
            Pass := MainPasEdit.Text
          else
            Pass := OperEdit.Text+#13#10+OperPasEdit.Text;
          Result := IDOK;
        end;
      mrIgnore:
        Result := IDIGNORE;
    end;
    Free;
  end;
end;

procedure TPasEnterForm.IndicTimerTimer(Sender: TObject);
var
  KeyState: TKeyboardState;
  LayoutName: array[0.. KL_NAMELENGTH] of Char;
  S: string;
begin
  GetKeyboardState(KeyState);
  CapsLabel.Visible := KeyState[VK_CAPITAL]<>0;
  GetKeyboardLayoutName(LayoutName);
  S := LayoutName;
  S := Copy(S, Length(S)-2, 3);
  if S='409' then
  begin
    S := 'En';
    LangLabel.Color := clNavy;
  end
  else
  if S='419' then
  begin
    S := 'Ru';
    LangLabel.Color := clRed;
  end
  else begin
    S := '';
    LangLabel.Hide;
  end;
  if Length(S)>0 then
  begin
    LangLabel.Show;
    LangLabel.Caption := S;
  end;
end;

procedure TPasEnterForm.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  IndicTimerTimer(nil);
end;

procedure TPasEnterForm.OperEditKeyPress(Sender: TObject; var Key: Char);
begin
  if not ((Key in ['0'..'9']) or (Key < #32)) then
  begin
    Key := #0;
    MessageBeep(0)
  end;
end;

end.
