unit AboutPFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons, ExtCtrls, ShellApi, Utilits, CrySign;

type
  TURLLabel = class(TLabel)
  private
    procedure CMMouseEnter(var Message: TMessage); message CM_MOUSEENTER;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
  protected
    procedure Click; override;
  public
    constructor Create(AOwner: TComponent); override;
  end;

  TAboutPForm = class(TForm)
    LogoImage: TImage;
    OkBtn: TBitBtn;
    NameLabel: TLabel;
    FirmLabel: TLabel;
    DepLabel: TLabel;
    AdrLabel: TLabel;
    IOLabel: TLabel;
    IOTelLabel: TLabel;
    TelLabel: TLabel;
    HddIdPanel: TPanel;
    ItscStaticText: TStaticText;
    procedure FormCreate(Sender: TObject);
    procedure LogoImageClick(Sender: TObject);
    procedure NameLabelClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
  public
  end;

var
  AboutPForm: TAboutPForm;

implementation

{$R *.DFM}

constructor TURLLabel.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Cursor := crHandPoint;
end;

procedure TURLLabel.CMMouseEnter(var Message: TMessage);
var
  FS: TFontStyles;
begin
  Font.Color := clBlue;
  FS := Font.Style;
  Include(FS, fsUnderline);
  Font.Style := FS;
end;

procedure TURLLabel.CMMouseLeave(var Message: TMessage);
var
  FS: TFontStyles;
begin
  Font.Color := clWindowText;
  FS := Font.Style;
  Exclude(FS, fsUnderline);
  Font.Style := FS;
end;

procedure TURLLabel.Click;
var
  Url: array[0..255] of Char;
begin
  inherited Click;
  StrPLCopy(Url, Hint, SizeOf(Url));
  Screen.Cursor := crHourGlass;
  ShellExecute(Application.Handle, nil, @Url, nil, nil,
    SW_SHOWMAXIMIZED);
  Screen.Cursor := crDefault;
end;

procedure TAboutPForm.LogoImageClick(Sender: TObject);
var
  I: Integer;
begin
  if (Sender=LogoImage) or HddIdPanel.Visible then
  begin
    for I := 1 to ControlCount do
      if Controls[I-1].Tag=0 then
        Controls[I-1].Visible := not Controls[I-1].Visible;
    if HddIdPanel.Visible then
    begin
      HddIdPanel.Caption := 'ID места: '+Format('%x', [GetHddPlaceId(BaseDir)]);
      ItscStaticText.Caption := 'Параметры СКЗИ:'#13#10+GetAllCryptoInfo;
    end;
  end;
end;

procedure TAboutPForm.FormCreate(Sender: TObject);
var
  URLLabel: TURLLabel;
begin
  //NameLabel.Caption := NameLabel.Caption{+' '+MainForm.VerNumLabel.Caption};
  LogoImage.Picture.Icon:=Application.Icon;
  URLLabel := TURLLabel.Create(Self);
  with URLLabel do
  begin
    Left := TelLabel.Left;
    Top := TelLabel.Top+15;
    Font := NameLabel.Font;
    Hint := 'http://www.transcapbank.perm.ru';
    Caption := 'http://www.transcapbank.perm.ru';
    Parent := Self;
  end;
  URLLabel := TURLLabel.Create(Self);
  with URLLabel do
  begin
    Left := TelLabel.Left;
    Top := IOTelLabel.Top+15;
    Font := NameLabel.Font;
    Hint := 'mailto:Информационный отдел ТКБ <support@transcapbank.perm.ru>?subject='
      +NameLabel.Caption;
    Caption := 'e-mail: support@transcapbank.perm.ru';
    Parent := Self;
  end;
  {URLLabel := TURLLabel.Create(Self);
  with URLLabel do
  begin
    Left := TelLabel.Left;
    Top := IOTelLabel.Top+30;
    Font := NameLabel.Font;
    Hint := 'mailto:Транскапиталбанк <tcb@permonline.ru>?subject='
      +NameLabel.Caption;
    Caption := 'e-mail: tcb@permonline.ru';
    Parent := Self;
  end;}
end;

procedure TAboutPForm.NameLabelClick(Sender: TObject);
begin
  ShellAbout(Handle, PChar(NameLabel.Caption),
    PChar(FirmLabel.Caption+#13#10+DepLabel.Caption),
    Application.Icon.Handle);
end;

procedure TAboutPForm.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  S: string;
begin
  case Key of
    VK_ESCAPE:
      Close;
    {VK_F5:
      begin
        MainForm.FormDblClick(nil);
        if MainForm.UpdateItem.Visible then
          S := ''
        else
          S := 'ы';
        MessageBox(Handle, PChar('Расширенный режим в'+S+'ключен'),
          'Дополнительно', MB_ICONINFORMATION or MB_OK);
      end;}
    VK_F9:
      LogoImageClick(LogoImage);
  end;
end;

end.
