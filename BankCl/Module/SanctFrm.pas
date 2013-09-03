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
    procedure FormDestroy(Sender: TObject);
    procedure CheckListBoxClick(Sender: TObject);
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
  HintList: TStringList = nil;

procedure TSanctForm.FormCreate(Sender: TObject);
var
  RegistrBase: TBtrBase;
  ParamRec: TParamNewRec;
  ParamVec: TParamKey0;
  Res, Len: Integer;
begin
  HintList := TStringList.Create;
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
      HintList.Add(ParamValueToStr(ParamRec));
      Len := SizeOf(ParamRec);
      Res := RegistrBase.GetNext(ParamRec, Len, ParamVec, 0);
    end;
  end;
end;

procedure TSanctForm.FormDestroy(Sender: TObject);
begin
  HintList.Free;
end;

var
  LastItem: Integer = -1;

procedure TSanctForm.CheckListBoxClick(Sender: TObject);
begin
  if CheckListBox.ItemIndex<>LastItem then
  begin
    LastItem := CheckListBox.ItemIndex;
    if (LastItem>=0) and (LastItem<HintList.Count) then
      CheckListBox.Hint := HintList.Strings[LastItem]
    else
      CheckListBox.Hint := '';
  end;
end;

end.
