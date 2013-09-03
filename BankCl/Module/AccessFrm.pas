unit AccessFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons, CheckLst, ExtCtrls, Bases, CommCons;

type
  TAccessForm = class(TForm)
    FirmGroupBox: TGroupBox;
    UserPanel: TPanel;
    BtnPanel: TPanel;
    CheckListBox: TCheckListBox;
    UserLabel: TLabel;
    UserEdit: TEdit;
    OkBtn: TBitBtn;
    CancelBtn: TBitBtn;
    procedure BtnPanelResize(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  AccessForm: TAccessForm;

implementation

uses BtrDS;

{$R *.DFM}

const
  BtnDist=10;

procedure TAccessForm.BtnPanelResize(Sender: TObject);
begin
  OkBtn.Left := (BtnPanel.ClientWidth-CancelBtn.Width-OkBtn.Width-BtnDist) div 2;
  CancelBtn.Left := OkBtn.Left+CancelBtn.Width+BtnDist;
  UserEdit.Width := UserPanel.Width-UserEdit.Left-2;
end;

procedure TAccessForm.FormShow(Sender: TObject);
begin
  BtnPanelResize(Sender);
end;

end.
