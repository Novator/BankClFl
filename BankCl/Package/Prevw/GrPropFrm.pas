unit GrPropFrm;

interface
 
uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons, Mask, ToolEdit, GraphPrims;

type
  TGrPropertyForm = class(TForm)
    OkBitBtn: TBitBtn;
    CancelBitBtn: TBitBtn;
    IderLabel: TLabel;
    IderEdit: TEdit;
    NumberLabel: TLabel;
    NumberEdit: TEdit;
    CoordGroupBox: TGroupBox;
    LeftEdit: TEdit;
    LeftLabel: TLabel;
    TopEdit: TEdit;
    TopLabel: TLabel;
    WidthEdit: TEdit;
    WidthLabel: TLabel;
    HeightEdit: TEdit;
    HeightLabel: TLabel;
    TextGroupBox: TGroupBox;
    MaskLabel: TLabel;
    MaskEdit: TEdit;
    FontLabel: TLabel;
    FontComboEdit: TComboEdit;
    ExampleStaticText: TStaticText;
    FontDialog: TFontDialog;
    AlignComboBox: TComboBox;
    AlignLabel: TLabel;
    AbzasLabel: TLabel;
    AbzasComboBox: TComboBox;
    WordBreakCheckBox: TCheckBox;
    SingleLineCheckBox: TCheckBox;
    AtrLabel: TLabel;
    AtrNumLabel: TLabel;
    procedure FontComboEditButtonClick(Sender: TObject);
    procedure ExampleStaticTextClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure WordBreakCheckBoxClick(Sender: TObject);
    procedure AtrNumLabelDblClick(Sender: TObject);
  private
  public
    AtrNum: Integer;
  end;

var
  GrPropertyForm: TGrPropertyForm;

implementation

{$R *.DFM}

procedure FontToLogFont(AFont: TFont; var ALogFont: TLogFont);
begin
  with ALogFont, AFont do
  begin
    StrPLCopy(lfFaceName, Name, SizeOf(lfFaceName)-1);
    lfHeight := Abs(Round(Size*10/2.54));
    {lfWidth := ;
    lfEscapement := ;
    lfOrientation := ;}
    if fsBold in Style then
      lfWeight := FW_BOLD
    else
      lfWeight := FW_NORMAL;
    if fsItalic	in Style then
      lfItalic := 1
    else
      lfItalic := 0;
    if fsUnderline in Style then
      lfUnderline := 1
    else
      lfUnderline := 0;
    if fsStrikeOut in Style then
      lfStrikeOut := 1
    else
      lfStrikeOut := 0;
    lfCharSet := CharSet;
    {lfOutPrecision;
    lfClipPrecision;
    lfQuality;}
    lfPitchAndFamily := Ord(Pitch);
  end;
end;

procedure LogFontToFont(ALogFont: TLogFont; var AFont: TFont);
var
  S: TFontStyles;
begin
  with ALogFont, AFont do
  begin
    Name := StrPas(lfFaceName);
    Size := Abs(Round(lfHeight*2.54/10));
    S := [];
    if lfWeight=FW_BOLD then
      Include(S, fsBold); 
    if lfItalic>0 then
      Include(S, fsItalic);
    if lfUnderline>0 then
      Include(S, fsUnderline);
    if lfStrikeOut>0 then
      Include(S, fsStrikeOut);
    Style := S;
    CharSet := lfCharSet;
    {lfOutPrecision;
    lfClipPrecision;
    lfQuality;}
    Pitch := TFontPitch(lfPitchAndFamily and $03);
  end;
end;

var
  ALogFont: TLogFont;

procedure TGrPropertyForm.FontComboEditButtonClick(Sender: TObject);
begin
  FontDialog.Font := ExampleStaticText.Font;
  if FontDialog.Execute then
  begin
    ExampleStaticText.Font := FontDialog.Font;
    FontToLogFont(ExampleStaticText.Font, ALogFont);
    FontComboEdit.Text := LogFontToStr(ALogFont);
  end;
end;

procedure TGrPropertyForm.ExampleStaticTextClick(Sender: TObject);
var
  AFont: TFont;
begin
  StrToLogFont(FontComboEdit.Text, ALogFont);
  AFont := TFont.Create;
  LogFontToFont(ALogFont, AFont);
  ExampleStaticText.Font.Assign(AFont);
  AFont.Free;
end;

procedure TGrPropertyForm.FormShow(Sender: TObject);
begin
  FillChar(ALogFont, SizeOf(ALogFont), #0);
  if TextGroupBox.Visible then
  begin
    if Length(FontComboEdit.Text)>0 then
      ExampleStaticTextClick(nil);
    AtrNumLabel.Enabled := False;
    if (AtrNum and DT_CENTER<>0) then
      AlignComboBox.ItemIndex := 1
    else
    if (AtrNum and DT_RIGHT<>0) then
      AlignComboBox.ItemIndex := 2
    else
      AlignComboBox.ItemIndex := 0;
    WordBreakCheckBox.Checked := (AtrNum and DT_WORDBREAK)<>0;
    SingleLineCheckBox.Checked := (AtrNum and DT_SINGLELINE)<>0;
    if not SingleLineCheckBox.Checked then
      AbzasComboBox.Enabled := False;
    if (AtrNum and DT_VCENTER)<>0 then
      AbzasComboBox.ItemIndex := 1
    else
    if (AtrNum and DT_BOTTOM)<>0 then
      AbzasComboBox.ItemIndex := 2
    else
      AbzasComboBox.ItemIndex := 0;
    AtrNumLabel.Enabled := True;
    AtrNumLabelDblClick(nil);
  end
  else
    AtrNum := 0;
end;

procedure TGrPropertyForm.WordBreakCheckBoxClick(Sender: TObject);
begin
  SingleLineCheckBox.Enabled := not WordBreakCheckBox.Checked;
  if not SingleLineCheckBox.Enabled then
    SingleLineCheckBox.Checked := False;
  AbzasComboBox.Enabled := SingleLineCheckBox.Checked;
  if not AbzasComboBox.Enabled then
    AbzasComboBox.ItemIndex := 0;
  AtrNumLabelDblClick(Sender);
end;

procedure TGrPropertyForm.AtrNumLabelDblClick(Sender: TObject);
begin
  if (Sender<>nil) and AtrNumLabel.Enabled then
  begin
    case AlignComboBox.ItemIndex of
      1:
        AtrNum := DT_CENTER;
      2:
        AtrNum := DT_RIGHT;
      else
        AtrNum := DT_LEFT;
    end;
    if WordBreakCheckBox.Checked then
      AtrNum := AtrNum or DT_WORDBREAK;
    if SingleLineCheckBox.Checked then
    begin
      AtrNum := AtrNum or DT_SINGLELINE;
      case AbzasComboBox.ItemIndex of
        1:
          AtrNum := AtrNum or DT_VCENTER;
        2:
          AtrNum := AtrNum or DT_BOTTOM;
      end;
    end;
    AtrNumLabel.Font.Color := clNavy;
  end;
  AtrNumLabel.Caption := IntToStr(AtrNum);
  case AlignComboBox.ItemIndex of
    1:
      ExampleStaticText.Alignment := taCenter;
    2:
      ExampleStaticText.Alignment := taRightJustify;
    else
      ExampleStaticText.Alignment := taLeftJustify;
  end;
end;

end.
