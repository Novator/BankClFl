unit SignVeiwFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ExtCtrls, StdCtrls, Buttons, TccItcs;

type
  TSignVeiwForm = class(TForm)
    OkBitBtn: TBitBtn;
    NameLabel: TLabel;
    TimeLabel: TLabel;
    NameEdit: TEdit;
    TimeEdit: TEdit;
    ViewPanel: TPanel;
    Label1: TLabel;
    ConclusMemo: TMemo;
    LenLabel: TLabel;
    LenEdit: TEdit;
    procedure ViewPanelMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure ViewPanelMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure ViewPanelClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ConclusMemoKeyPress(Sender: TObject; var Key: Char);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  SignVeiwForm: TSignVeiwForm;

procedure ShowSignConclusion(AName, ATime, AConcl: string; Len: Integer;
  APGlobCont: PEXT_FULL_CONTEXT; APGlobSignCntxt: PEXT_SIGN_CONTEXT);

implementation

{$R *.DFM}

var
  PGlobSignCntxt: PEXT_SIGN_CONTEXT = nil;
  PGlobCont: PEXT_FULL_CONTEXT = nil;

procedure TSignVeiwForm.ViewPanelMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbLeft then (Sender as TPanel).BevelOuter := bvLowered;
end;

procedure TSignVeiwForm.ViewPanelMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  with (Sender as TPanel) do
    if BevelOuter = bvLowered then BevelOuter := bvRaised;
end;

procedure TSignVeiwForm.ViewPanelClick(Sender: TObject);
const
  MesTitle: PChar = 'Проверка подписи';
var
  Err: Integer;
  Mes: string;
begin
  Err := TExtViewSignResult(GetExtPtr(fiViewSignResult))(PGlobCont, PGlobSignCntxt, 'Просмотр подписи');
  if Err<>0 then
  begin
    Mes := ErrToStr(Err);
    Application.MessageBox(PChar(Mes), MesTitle, MB_OK or MB_ICONERROR);
  end;
end;

procedure TSignVeiwForm.FormDestroy(Sender: TObject);
begin
  PGlobCont := nil;
  PGlobSignCntxt := nil;
end;

procedure ShowSignConclusion(AName, ATime, AConcl: string; Len: Integer;
  APGlobCont: PEXT_FULL_CONTEXT; APGlobSignCntxt: PEXT_SIGN_CONTEXT);
begin
  SignVeiwForm := TSignVeiwForm.Create(Application);
  with SignVeiwForm do
  begin
    if APGlobCont=nil then
    begin
      ViewPanel.Enabled := False;
      ViewPanel.Font.Color := clGrayText;
    end
    else begin
      PGlobCont := APGlobCont;
      PGlobSignCntxt := APGlobSignCntxt;
    end;
    NameEdit.Text := AName;
    TimeEdit.Text := ATime;
    ConclusMemo.Lines.Text := AConcl;
    LenEdit.Text := IntToStr(Len);
    ShowModal;
    Free;
  end;
end;

procedure TSignVeiwForm.ConclusMemoKeyPress(Sender: TObject; var Key: Char);
begin
  if Key=#13 then
    ModalResult := mrOk;
end;

procedure TSignVeiwForm.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key=VK_ESCAPE then
    ModalResult := mrCancel
end;

end.
