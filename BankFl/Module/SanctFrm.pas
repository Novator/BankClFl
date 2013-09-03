unit SanctFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons, CheckLst, ExtCtrls, Registr, Btrieve;

type
  TSanctForm = class(TForm)
    SanctGroupBox: TGroupBox;
    UserPanel: TPanel;
    BtnPanel: TPanel;
    CheckListBox: TCheckListBox;
    UserLabel: TLabel;
    UserEdit: TEdit;
    OkBtn: TBitBtn;
    CancelBtn: TBitBtn;
    procedure BtnPanelResize(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  SanctForm: TSanctForm;

implementation

uses BtrDS;

{$R *.DFM}

const
  BtnDist=10;

procedure TSanctForm.BtnPanelResize(Sender: TObject);
begin
  OkBtn.Left := (BtnPanel.ClientWidth-CancelBtn.Width-OkBtn.Width-BtnDist) div 2;
  CancelBtn.Left := OkBtn.Left+CancelBtn.Width+BtnDist;
  UserEdit.Width := UserPanel.Width-UserEdit.Left-2;
end;

procedure TSanctForm.FormShow(Sender: TObject);
begin
  BtnPanelResize(Sender);
end;

const
  SanctSection=7;

procedure TSanctForm.FormCreate(Sender: TObject);
var
  RegistrBase: TBtrBase;
  ParamRec: TParamNewRec;
  ParamVec: TParamKey0;
  Res, Len: Integer;
begin
  RegistrBase := GetRegistrBase;
  with RegistrBase do
  begin
    with ParamVec do
    begin
      pkSect := SanctSection;
      pkNumber := 0;
      pkUser := CommonUserNumber;
    end;
    Len := SizeOf(ParamRec);
    Res := RegistrBase.GetGE(ParamRec, Len, ParamVec, 0);
    while (Res=0) and (ParamRec.pmSect=SanctSection) do
    begin
      CheckListBox.Items.AddObject(ParamRec.pmName, TObject(ParamRec.pmNumber));
      Len := SizeOf(ParamRec);
      Res := RegistrBase.GetNext(ParamRec, Len, ParamVec, 0);
    end;
  end;
end;

end.
