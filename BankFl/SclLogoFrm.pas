unit SclLogoFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ExtCtrls, RunMes, StdCtrls;

type
  TScaleLogoForm = class(TForm)
    Image: TImage;
    ShowTimer: TTimer;
    MesStaticText: TStaticText;
    BackStaticText: TStaticText;
    ProStaticText: TStaticText;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure ImageClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    FMin, FMax, FPos: Integer;
    procedure WMRunMessage(var Message: TMessage); message WM_RUNMESSAGE;
  public
    procedure SetLimits(Min, Max: Integer);
    procedure SetPos(Pos: Integer);
    procedure FirstShow;
  end;

var
  ScaleLogoForm: TScaleLogoForm;

implementation

{$R *.DFM}

procedure TScaleLogoForm.FirstShow;
begin                      
  Show;
  ClientHeight := Image.Height + BackStaticText.Height + MesStaticText.Height - 2;
  Repaint;
end;

procedure TScaleLogoForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
end;

procedure TScaleLogoForm.ImageClick(Sender: TObject);
begin
  if fsModal in FormState then
    ModalResult := mrOk;
end;

procedure TScaleLogoForm.FormCreate(Sender: TObject);
begin
  FMin := 0;
  FMax := 0;
  FPos := 0;
  with Image do
    SetBounds(0, 0, Width, Height);
  ClientWidth := Image.Width;
  ClientHeight := Image.Height;
end;

procedure TScaleLogoForm.SetLimits(Min, Max: Integer);
begin
  FMin := Min;
  FMax := Max;
end;

procedure TScaleLogoForm.SetPos(Pos: Integer);
begin
  if (FMin<=Pos) and (Pos<=FMax) then
  begin
    FPos := Pos;
    if FMax = FMin then
      ProStaticText.Width := 0
    else
      ProStaticText.Width := (BackStaticText.Width - 2) * (FPos-FMin) div (FMax - FMin);
  end;
end;

procedure TScaleLogoForm.WMRunMessage(var Message: TMessage);
var
  P: PChar;
begin
  P := PChar(Message.WParam);
  if P<>nil then
  begin
    {MesStaticText.Caption := '';
    showmessage(IntToStr(FPos));
  end
  else}
    MesStaticText.Caption := StrPas(P)+'...';
    SetPos(FPos + 1);
  end;
  Application.ProcessMessages;
end;


end.
