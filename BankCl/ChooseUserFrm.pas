unit ChooseUserFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons, Mask, ToolEdit, CommCons, Utilits;

type
  TChooseUserForm = class(TForm)
    UserLabel: TLabel;
    UzerComboBox: TComboBox;
    KeyPathDirectoryEdit: TDirectoryEdit;
    KeyPathLabel: TLabel;
    OkBitBtn: TBitBtn;
    CancelBitBtn: TBitBtn;
    IgnoreBitBtn: TBitBtn;
    procedure UzerComboBoxClick(Sender: TObject);
  private
    { Private declarations }
  public
    FTransPath: string;
    function GetCurrentUser: PUserRec;
  end;

var
  ChooseUserForm: TChooseUserForm;

implementation

uses MainFrm;

{$R *.DFM}

function TChooseUserForm.GetCurrentUser: PUserRec;
var
  I: Integer;
begin
  Result := nil;
  I := UzerComboBox.ItemIndex;
  if (0<=I) and (I<UzerComboBox.Items.Count) then
    Result := Pointer(UzerComboBox.Items.Objects[I]);
end;

procedure TChooseUserForm.UzerComboBoxClick(Sender: TObject);
var
  UserRecPtr: PUserRec;
  L: Integer;
  S, S2: string;
begin
  UserRecPtr := GetCurrentUser;
  OkBitBtn.Enabled := UserRecPtr<>nil;
  if OkBitBtn.Enabled then
  begin
    L := StrLen(UserRecPtr^.urInfo)+1;
    S2 := StrPas(@UserRecPtr^.urInfo[L]);
    NormalizeDir(FTransPath);
    GetVipNetKeyParam(FTransPath+UserRecPtr^.urLogin, S, S2);
    L := StrLen(UserRecPtr^.urInfo)+1;
    KeyPathDirectoryEdit.Text := S2;
  end;
end;

end.
