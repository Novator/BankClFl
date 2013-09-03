unit WideComboBox;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls;

type
  TWideComboBox = class(TComboBox)
  private
  protected
    procedure ComboWndProc(var Message: TMessage; ComboWnd: HWnd;
      ComboProc: Pointer); override;
    function GetDroppedWidth: Integer;
    procedure SetDroppedWidth(Value: Integer);
  public
    property DroppedWidth: Integer read GetDroppedWidth write SetDroppedWidth;
  published
  end;

procedure Register;

implementation

function TWideComboBox.GetDroppedWidth: Integer;
begin
  Result := Perform(CB_GETDROPPEDWIDTH, 0, 0);
end;

procedure TWideComboBox.SetDroppedWidth(Value: Integer);
var
  S: string;
begin
  S := Text;
  Perform(CB_SETDROPPEDWIDTH, Value, 0);
  Text := S;
end;

const
  WideComboBoxText: array[0..1023] of Char = '';

procedure TWideComboBox.ComboWndProc(var Message: TMessage; ComboWnd: HWnd;
  ComboProc: Pointer);
var
  I: Integer;
begin
  with Message do
  begin
    case Msg of
      WM_SETTEXT:
        begin
          StrLCopy(WideComboBoxText, PChar(LParam), SizeOf(WideComboBoxText)-1);
          I := Pos(' |', WideComboBoxText);
          if I>0 then
          begin
            Dec(I);
            while (I>0) and (WideComboBoxText[I-1]=' ') do
              Dec(I);
            WideComboBoxText[I] := #0;
          end;
          LParam := Integer(PChar(@WideComboBoxText));
        end;
    end;
  end;
  inherited ComboWndProc(Message, ComboWnd, ComboProc);
end;

procedure Register;
begin
  RegisterComponents('BankClient', [TWideComboBox]);
end;

end.
