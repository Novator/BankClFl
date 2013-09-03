unit GetPassDialog;

interface

uses
  Forms, StdCtrls, Windows, Graphics, Controls;

function GetGkPassword: string;
function GetOperPassword(var Oper: word; var Pwd: string): boolean;

implementation

function GetAveCharSize(Canvas: TCanvas): TPoint;
var
  I: Integer;
  Buffer: array[0..51] of Char;
begin
  for I := 0 to 25 do Buffer[I] := Chr(I + Ord('A'));
  for I := 0 to 25 do Buffer[I + 26] := Chr(I + Ord('a'));
  GetTextExtentPoint(Canvas.Handle, Buffer, 52, TSize(Result));
  Result.X := Result.X div 52;
end;

function GetGkPassword: string;
var
  Form: TForm;
  Prompt: TLabel;
  Edit: TEdit;
  DialogUnits: TPoint;
  ButtonTop, ButtonWidth, ButtonHeight: Integer;
begin
  Result := '';
  Form := TForm.Create(Application);
  with Form do
    try
      Canvas.Font := Font;
      DialogUnits := GetAveCharSize(Canvas);
      BorderStyle := bsDialog;
      Caption := 'Ввод пароля главного ключа';
      ClientWidth := MulDiv(180, DialogUnits.X, 4);
      ClientHeight := MulDiv(63, DialogUnits.Y, 8);
      Position := poScreenCenter;
      Prompt := TLabel.Create(Form);
      with Prompt do
      begin
        AutoSize := True;
        Left := MulDiv(8, DialogUnits.X, 4);
        Top := MulDiv(8, DialogUnits.Y, 8);
        Caption := 'Пароль';
        Parent := Form;
      end;
      Edit := TEdit.Create(Form);
      with Edit do
      begin
        Parent := Form;
        Left := Prompt.Left;
        Top := Prompt.Top + Prompt.Height + 2;
        Width := MulDiv(164, DialogUnits.X, 4);
        MaxLength := 255;
        Text := '';
        PasswordChar := '*';
        SelectAll;
      end;
      ButtonTop := MulDiv(41, DialogUnits.Y, 8);
      ButtonWidth := MulDiv(50, DialogUnits.X, 4);
      ButtonHeight := MulDiv(14, DialogUnits.Y, 8);
      with TButton.Create(Form) do
      begin
        Parent := Form;
        Caption := 'O&K';
        ModalResult := mrOk;
        Default := True;
        SetBounds(MulDiv(38, DialogUnits.X, 4), ButtonTop, ButtonWidth,
          ButtonHeight);
      end;
      with TButton.Create(Form) do
      begin
        Parent := Form;
        Caption := '&Отмена';
        ModalResult := mrCancel;
        Cancel := True;
        SetBounds(MulDiv(92, DialogUnits.X, 4), ButtonTop, ButtonWidth,
          ButtonHeight);
      end;
      if ShowModal = mrOk then
      begin
        Result := Edit.Text;
      end;
    finally
      Form.Free;
    end;
end;

function GetOperPassword(var Oper: word; var Pwd: string): boolean;
var
  Form: TForm;
  Prompt1, Prompt2: TLabel;
  Edit1, Edit2: TEdit;
  DialogUnits: TPoint;
  ButtonTop, ButtonWidth, ButtonHeight: Integer;
begin
  Result := False;
  Form := TForm.Create(Application);
  with Form do
    try
      Canvas.Font := Font;
      DialogUnits := GetAveCharSize(Canvas);
      BorderStyle := bsDialog;
      Caption := 'Ввод пароля оператора';
      ClientWidth := MulDiv(180, DialogUnits.X, 4);
      ClientHeight := MulDiv(87, DialogUnits.Y, 8);
      Position := poScreenCenter;
      Prompt1 := TLabel.Create(Form);
      with Prompt1 do
      begin
        Parent := Form;
        AutoSize := True;
        Left := MulDiv(8, DialogUnits.X, 4);
        Top := MulDiv(8, DialogUnits.Y, 10);
        Caption := 'Оператор';
      end;
      Edit1 := TEdit.Create(Form);
      with Edit1 do
      begin
        Parent := Form;
        Left := Prompt1.Left;
        Top := Prompt1.Top + Prompt1.Height + 2;
        Width := MulDiv(164, DialogUnits.X, 4);
        MaxLength := 255;
        Text := '';
        SelectAll;
      end;
      Prompt2 := TLabel.Create(Form);
      with Prompt2 do
      begin
        Parent := Form;
        AutoSize := True;
        Left := Prompt1.Left;
        Top := Edit1.Top + Edit1.Height + 7;
        Caption := 'Пароль';
      end;
      Edit2 := TEdit.Create(Form);
      with Edit2 do
      begin
        Parent := Form;
        Left := Prompt2.Left;
        Top := Prompt2.Top + Prompt2.Height + 2;
        Width := Edit1.Width;
        MaxLength := 255;
        Text := '';
        PasswordChar := '*';
        SelectAll;
      end;
      ButtonTop := MulDiv(65, DialogUnits.Y, 8);
      ButtonWidth := MulDiv(50, DialogUnits.X, 4);
      ButtonHeight := MulDiv(14, DialogUnits.Y, 8);
      with TButton.Create(Form) do
      begin
        Parent := Form;
        Caption := 'O&K';
        ModalResult := mrOk;
        Default := True;
        SetBounds(MulDiv(38, DialogUnits.X, 4), ButtonTop, ButtonWidth,
          ButtonHeight);
      end;
      with TButton.Create(Form) do
      begin
        Parent := Form;
        Caption := '&Отмена';
        ModalResult := mrCancel;
        Cancel := True;
        SetBounds(MulDiv(92, DialogUnits.X, 4), ButtonTop, ButtonWidth,
          ButtonHeight);
      end;
      if ShowModal = mrOk then
      begin
        Val(Edit1.Text, Oper, ButtonTop);
        if ButtonTop = 0 then
        begin
          Pwd := Edit2.Text;
          Result := True;
        end;
      end;
    finally
      Form.Free;
    end;
end;

end.
