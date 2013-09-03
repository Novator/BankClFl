unit LogoFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ExtCtrls;

type
  TLogoForm = class(TForm)
    Image: TImage;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure ImageClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { Private declarations }
  public
    procedure FirstShow;
  end;

var
  LogoForm: TLogoForm = nil;

implementation

{$R *.DFM}

procedure TLogoForm.FirstShow;
begin
  Show;
  Repaint;
end;

procedure TLogoForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
end;

procedure TLogoForm.ImageClick(Sender: TObject);
begin
  if fsModal in FormState then
    ModalResult := mrOk;
end;

procedure TLogoForm.FormCreate(Sender: TObject);
begin
  with Image do
    SetBounds(0, 0, Width, Height);
  ClientWidth := Image.Width;
  ClientHeight := Image.Height;
end;

procedure TLogoForm.FormDestroy(Sender: TObject);
begin
  LogoForm := nil;
end;

end.
