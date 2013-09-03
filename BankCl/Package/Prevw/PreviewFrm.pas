unit PreviewFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons, ExtCtrls, GraphPrims, Db, Spin, RXSpin,
  Placemnt, Menus, Registr, DBGrids, Utilits, ComCtrls, ToolWin, Common;

type
  TPreviewForm = class(TForm)
    ScrollBox: TScrollBox;
    Panel: TPanel;
    Image: TImage;
    PageEdit: TSpinEdit;
    PageLabel: TLabel;
    MaxPageLabel: TLabel;
    MaxPageEdit: TEdit;
    ScaleLabel: TLabel;
    PrevFormStorage: TFormStorage;
    ScaleRxSpinEdit: TRxSpinEdit;
    PersentLabel: TLabel;
    PopupMenu: TPopupMenu;
    CloseItem: TMenuItem;
    PopupBreaker: TMenuItem;
    Scale100Item: TMenuItem;
    EditItem: TMenuItem;
    EditToolBar: TToolBar;
    RefreshToolButton: TToolButton;
    SaveToolButton: TToolButton;
    ToolButton1: TToolButton;
    LineToolButton: TToolButton;
    RectToolButton: TToolButton;
    CircToolButton: TToolButton;
    TextToolButton: TToolButton;
    AllPrimsComboBox: TComboBox;
    NewPrimComboBox: TComboBox;
    OkBtn: TSpeedButton;
    ToolButton2: TToolButton;
    CopyToolButton: TToolButton;
    DelToolButton: TToolButton;
    ToolButton4: TToolButton;
    ShowAllToolButton: TToolButton;
    ShowTextToolButton: TToolButton;
    ShowNoTextToolButton: TToolButton;
    procedure PanelResize(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure PageEditChange(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure Scale100ItemClick(Sender: TObject);
    procedure CloseItemClick(Sender: TObject);
    procedure ScrollBoxMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure EditItemClick(Sender: TObject);
    procedure RefreshToolButtonClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure SaveToolButtonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure LineToolButtonClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure ImageMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure DelToolButtonClick(Sender: TObject);
    procedure ShowAllToolButtonClick(Sender: TObject);
  private
    WasChanged: Boolean;
  public
    ShowMode: Byte;
    DataBaseForm: TDataBaseForm;
    procedure SetToolBtnIndexes(ixRefr, ixSave, ixLine, ixRect, ixCirc,
      ixText, ixCopy, ixDel, ixShowA, ixShowT, ixShowNT: Integer);
    class procedure MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    class procedure MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    class procedure MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
  end;

  TPrimImage = class(TGraphicControl)
  private
    FGraphPrim: TGraphPrim;
  protected
    procedure Paint; override;
    procedure Rebuild;
    procedure SetGraphPrim(AGraphPrim: TGraphPrim);
  public
    property GraphPrim: TGraphPrim read FGraphPrim write SetGraphPrim;
    property Canvas;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    constructor Create(AOwner: TComponent);
  end;

var
  PrevImageList: TImageList = nil;
  PrevManager: TGraphPrimManager = nil;
  PrevPrintDBGrid: TPrintDBGrid = nil;
  PreviewForm: TPreviewForm = nil;
  LeftMargin: Integer = 10;
  TopMargin: Integer = 10;

implementation

uses Printers, GrPropFrm;

{$R *.DFM}

constructor TPrimImage.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  {ControlStyle := ControlStyle + [csOpaque];}
  with Canvas do
  begin
    Brush.Style := bsClear;
    Pen.Color:=clBlack;
    Pen.Style:=psDot;
    Pen.Mode:=pmNot;
  end;
  Cursor := crArrow;
  OnMouseDown := TPreviewForm.MouseDown;
  OnMouseMove := TPreviewForm.MouseMove;
  OnMouseUp :=   TPreviewForm.MouseUp;
end;

var
  SelectedPrimImage: TPrimImage = nil;

procedure TPrimImage.Paint;
begin
  with Canvas do
  begin
    if FGraphPrim<>nil then
    begin
      Pen.Color := clBlack;
      Pen.Width := 1;
      Brush.Color := clWhite;
      Brush.Style := bsClear;
      Pen.Style := psSolid;
      Pen.Mode := pmCopy;
      {SetBkMode(Handle, TRANSPARENT);}
      FGraphPrim.DrawLoc(Handle);
    end;
    if Enabled{Visible} then
    begin
      Pen.Color := clBlack;
      if FGraphPrim<>nil then
      begin
        if Self=SelectedPrimImage then
          Pen.Color := clRed
        else
        if FGraphPrim is TGPLine then
          Pen.Color := clBlue;
      end;
      Pen.Width := 1;
      Brush.Style := bsClear;
      Pen.Style := psDot;
      Pen.Mode := pmMergePenNot;
      Rectangle(0,0,Width,Height);
    end;
  end;
end;

var
  SrcOrigin: TPoint = (X:0; Y:0);
  EditMode: Integer = 0;

procedure TPrimImage.Rebuild;
var
  R: TRect;
begin
  if FGraphPrim<>nil then
  begin
    R := FGraphPrim.GetLimits;
    R.TopLeft := VirtToWin(R.TopLeft);
    R.BottomRight := VirtToWin(R.BottomRight);
    R := ExtRect(R);
    Dec(R.Left);
    Dec(R.Top);
    Inc(R.Right);
    Inc(R.Bottom);
    SrcOrigin := Point(PreviewForm.ScrollBox.HorzScrollBar.ScrollPos,
      PreviewForm.ScrollBox.VertScrollBar.ScrollPos);
    SetBounds(R.Left-SrcOrigin.X, R.Top-SrcOrigin.Y,
      R.Right-R.Left, R.Bottom-R.Top);
  end;
  Enabled{Visible} := (EditMode=0) or (FGraphPrim=nil)
    or (EditMode=1) and (FGraphPrim is TGPParagraph)
    or (EditMode=2) and not (FGraphPrim is TGPParagraph);
end;

procedure TPrimImage.SetGraphPrim(AGraphPrim: TGraphPrim);
begin
  FGraphPrim := AGraphPrim;
  Rebuild;
end;

procedure TPreviewForm.PanelResize(Sender: TObject);
const
  BtrOffset = 20;
begin
  if ClientWidth<OkBtn.Width+10 then
    ClientWidth := OkBtn.Width+10;
  OkBtn.Left := Panel.ClientWidth - OkBtn.Width - BtrOffset;
end;

procedure TPreviewForm.FormShow(Sender: TObject);
begin
  if PageEdit.MaxValue<1 then
    PageEdit.MaxValue := 1;
  MaxPageEdit.Text := IntToStr(PageEdit.MaxValue);
  PageLabel.Visible := PageEdit.MaxValue>1;
  PageEdit.Visible := PageLabel.Visible;
  MaxPageLabel.Visible := PageLabel.Visible;
  MaxPageEdit.Visible := PageLabel.Visible;
  WasChanged := False;
  SelectedPrimImage := nil;
  if Sender<>nil then
    PageEdit.Value := 1;
end;

const
  Margin = 10;
  MMPerInch = 25.4;
  BaseScreenDPI = 72.0;

procedure TPreviewForm.FormResize(Sender: TObject);
var
  WorkArea: TRect;
  PWdotR, PHdotR, PWdot, PHdot, DPI_X, DPI_Y, W, H, PixelFormatIndex, LI,
    LastYCoord, TotalPageCount: Integer;
  ScreenDPI: Real;
  Marg: TPoint;
  FN: TFileName;
  PrintDocRec: TPrintDocRec;
  PtrPrintDocRec: PPrintDocRec;
  FormList: TList;
  APageOrientation: TPageOrientation;

  procedure InitPageSizes;
  begin
    PWdotR := GetDeviceCaps(Printer.Handle, PHYSICALWIDTH);     {параметры принтера}
    PHdotR := GetDeviceCaps(Printer.Handle, PHYSICALHEIGHT);
    DPI_X := GetDeviceCaps(Printer.Handle, LOGPIXELSX);
    DPI_Y := GetDeviceCaps(Printer.Handle, LOGPIXELSY);
    PWdot := VirtToViewX(Round(PWdotR/DPI_X*MMPerInch));
    PHdot := VirtToViewY(Round(PHdotR/DPI_Y*MMPerInch));
    with WorkArea do       {область вывода на канве - область печати}
    begin
      Left := VirtToViewX(Round(GetDeviceCaps(Printer.Handle, PHYSICALOFFSETX)/
        DPI_X*MMPerInch));
      Top := VirtToViewY(Round(GetDeviceCaps(Printer.Handle, PHYSICALOFFSETY)/
        DPI_Y*MMPerInch));
      Right := Left+VirtToViewX(Round(GetDeviceCaps(Printer.Handle, HORZRES)/
        DPI_X*MMPerInch));
      Bottom := Top+VirtToViewY(Round(GetDeviceCaps(Printer.Handle, VERTRES)/
        DPI_Y*MMPerInch));
    end;
    with Image.Picture.Bitmap do
    begin
      if not GetRegParamByName('PixelFormatIndex', CommonUserNumber, PixelFormatIndex) then
        PixelFormatIndex := 1;
      Width := 0;             {инициализация Bitmap}
      Height := 0;
      PixelFormat := TPixelFormat(Byte(PixelFormatIndex));
      Width := PWdot;
      Height := PHdot;
      with Canvas.Pen do
      begin
        Color := clBlack;
        Style := psSolid;
        Mode := pmCopy;
      end;
      with Canvas.Brush do
      begin
        Style := bsSolid;
        Color := clWhite;
      end;
      Canvas.Rectangle(0, 0, Width, Height);
      Canvas.TextFlags := Canvas.TextFlags and not ETO_OPAQUE; {текст без фона}
      with WorkArea do      {область вывода}
        IntersectClipRect(Canvas.Handle, Left, Top, Right, Bottom);
    end;
  end;

begin
  if ScaleRxSpinEdit.Value=0 then
    Exit;
  ScreenDPI := ScaleRxSpinEdit.Value*72/100;
  if ScrollBox.Height>3*Margin then
  begin
    GlobScale.X := ScreenDPI/MMPerInch;     {масштаб показа гр. примитивов}
    GlobScale.Y := ScreenDPI/MMPerInch;
    InitPageSizes;
    EditItem.Enabled := (ShowMode=0) or (ShowMode=1);
    Scale100Item.Enabled := True;
    case ShowMode of
      0:
        with PrevManager do
        begin
          DataBaseForm.TakeFormPrintData(PrintDocRec, FormList);
          if (PrintDocRec.DBGrid.SelectedRows.Count>0) and (PageEdit.Value>0)
            and (PageEdit.Value<=PrintDocRec.DBGrid.SelectedRows.Count) then
          begin
            PrintDocRec.DBGrid.DataSource.DataSet.Bookmark :=
              PrintDocRec.DBGrid.SelectedRows.Items[PageEdit.Value-1];
            DataBaseForm.TakeFormPrintData(PrintDocRec, FormList);
          end;
          PageEdit.MaxValue := PrintDocRec.DBGrid.SelectedRows.Count;
          FormShow(nil);
          FN := PatternDir + PrintDocRec.GraphForm;
          if InitForm(FN, PrintDocRec.DBGrid.DataSource.DataSet) then
          begin
            APageOrientation := FormPageOrientation;
            if RotatePage and
              ((Printer.Orientation=poPortrait) and (APageOrientation=pgoLandscape) or
              (Printer.Orientation=poLandscape) and (APageOrientation=pgoPortrait)) then
            begin
              case APageOrientation of
                pgoPortrait:
                  Printer.Orientation := poPortrait;
                pgoLandscape:
                  Printer.Orientation := poLandscape;
              end;
              InitPageSizes;
            end;
            Marg := VirtToView(Point(LeftMargin, TopMargin));
            LogPen.lopnWidth.X := 1;
            Draw(Image.Picture.Bitmap.Canvas.Handle, GlobScale.X, GlobScale.Y,
              Point(Marg.X, Marg.Y));
          end;
        end;
      1:
        with PrevPrintDBGrid do
        begin
          if PageEdit.Value<1 then
            PageEdit.Value := 1;
          APageOrientation := {pgoDefault}pgoPortrait;
          DataBaseForm.TakeTabPrintData(PrintDocRec, FormList);
          if FormList=nil then
          begin
            DBGrid := PrintDocRec.DBGrid;
            {Limits := GetLimits;
            SheetWidth := Limits.Right;
            SheetHeight := Limits.Bottom;}
            SetupFileName := PatternDir + PrintDocRec.GraphForm;
            if LoadSetup then
            begin
              {if PageOrientation <> pgoDefault then}
              APageOrientation := PageOrientation;
              if RotatePage and
                ((Printer.Orientation=poPortrait) and (APageOrientation=pgoLandscape) or
                (Printer.Orientation=poLandscape) and (APageOrientation=pgoPortrait)) then
              begin
                case APageOrientation of
                  pgoPortrait:
                    Printer.Orientation := poPortrait;
                  pgoLandscape:
                    Printer.Orientation := poLandscape;
                end;
                InitPageSizes;
              end;
              SheetWidth := GetDeviceCaps(Printer.Handle, HORZSIZE);
              SheetHeight := GetDeviceCaps(Printer.Handle, VERTSIZE);
              YCoord := 0;
              DevideArea;
              SetVarior('PageCount', IntToStr(PageCount));
              SetVarior('PageNumber', IntToStr(PageEdit.Value));
              PageEdit.MaxValue := PageCount;
              FormShow(nil);
              DBGrid.Hide;
              Marg := VirtToView(Point(LeftMargin, TopMargin));
              Draw(Image.Picture.Bitmap.Canvas.Handle, GlobScale.X, GlobScale.Y,
                Point(Marg.X, Marg.Y), PageEdit.Value);
              DBGrid.Show;
            end;
          end
          else begin
            LastYCoord := 0;
            TotalPageCount := 1;
            for LI := 0 to FormList.Count-1 do
            begin
              PtrPrintDocRec := FormList.Items[LI];
              if PtrPrintDocRec<>nil then
              begin
                DBGrid := PtrPrintDocRec^.DBGrid;
                SetupFileName := PatternDir + PtrPrintDocRec^.GraphForm;
                if LoadSetup then
                begin
                  if LI=0 then
                  begin
                    APageOrientation := PageOrientation;
                    if RotatePage and
                      ((Printer.Orientation=poPortrait) and (APageOrientation=pgoLandscape) or
                      (Printer.Orientation=poLandscape) and (APageOrientation=pgoPortrait)) then
                    begin
                      case APageOrientation of
                        pgoPortrait:
                          Printer.Orientation := poPortrait;
                        pgoLandscape:
                          Printer.Orientation := poLandscape;
                      end;
                    end;
                    InitPageSizes;
                  end;
                  SheetWidth := GetDeviceCaps(Printer.Handle, HORZSIZE);
                  SheetHeight := GetDeviceCaps(Printer.Handle, VERTSIZE);
                  YCoord := LastYCoord;
                  DevideArea;
                  if (LI=0) or (DBGrid.DataSource.DataSet.RecordCount>0) then
                  begin
                    LastYCoord := LastGridBottom;
                    TotalPageCount := TotalPageCount + PageCount - 1;
                    if SkipPage>0 then
                      Inc(TotalPageCount);
                    if (TotalPageCount-PageCount<PageEdit.Value)
                      and (PageEdit.Value<=TotalPageCount) then
                    begin
                      SetVarior('PageCount', IntToStr(TotalPageCount));
                      SetVarior('PageNumber', IntToStr(PageEdit.Value));
                      DBGrid.Hide;
                      Marg := VirtToView(Point(LeftMargin, TopMargin));
                      Draw(Image.Picture.Bitmap.Canvas.Handle, GlobScale.X, GlobScale.Y,
                        Point(Marg.X, Marg.Y), PageEdit.Value-(TotalPageCount-PageCount));
                      DBGrid.Show;
                    end;
                  end;
                end;  
              end;  
            end;
            PageEdit.MaxValue := TotalPageCount;
            FormShow(nil);
          end;  
        end;
    end;
    with Image do
    begin
      if Width<ScrollBox.ClientWidth then
        W := (ScrollBox.ClientWidth - Width) div 2
      else
        W := ScrollBox.HorzScrollBar.Margin;
      if Height<ScrollBox.ClientHeight then
        H := (ScrollBox.ClientHeight - Height) div 2
      else
        H := ScrollBox.VertScrollBar.Margin;
      SetBounds(W - ScrollBox.HorzScrollBar.ScrollPos,
        H - ScrollBox.VertScrollBar.ScrollPos, Width, Height);
    end;
  end;
end;

procedure TPreviewForm.PageEditChange(Sender: TObject);
begin
  try
    if PageEdit.Value>PageEdit.MaxValue then
      PageEdit.Value := PageEdit.MaxValue;
    if PageEdit.Value<PageEdit.MinValue then
      PageEdit.Value := PageEdit.MinValue;
    if PageEdit.Value<1 then
      PageEdit.Value := 1;
  except
    PageEdit.Value := 1;
  end;
  PostMessage(Handle, WM_SIZE, 0, 0);
end;

procedure TPreviewForm.FormDestroy(Sender: TObject);
begin
  if PreviewForm=Self then
    PreviewForm := nil;
end;

procedure TPreviewForm.Scale100ItemClick(Sender: TObject);
begin
  ScaleRxSpinEdit.Value := 100.0;
  FormResize(Sender);
end;

procedure TPreviewForm.CloseItemClick(Sender: TObject);
begin
  Close;
end;

procedure TPreviewForm.ScrollBoxMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  P: TPoint;
begin
  ScrollBox.SetFocus;
  if Button=mbRight then
  begin
    P := ScrollBox.ClientToScreen(Point(X,Y));
    Popupmenu.Popup(P.X, P.Y);
  end;
end;

procedure TPreviewForm.FormKeyPress(Sender: TObject; var Key: Char);
begin
  case Key of
    '+':
      ImageMouseDown(Sender, mbLeft, [], 0, 0);
    '-':
      ImageMouseDown(Sender, mbRight, [], 0, 0);
    '/':
      Scale100ItemClick(nil);
  end;
end;

procedure TPreviewForm.ImageMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  ScaleJump: Double;
  Scale: Real;
begin
  if not GetRegParamByName('PreviewJump', CommonUserNumber, ScaleJump) then
    ScaleJump := 1.4;
  if Button=mbLeft then
    Scale:=ScaleJump
  else
    Scale:=1/ScaleJump;
  ScaleRxSpinEdit.Value := ScaleRxSpinEdit.Value*Scale;
  FormResize(Sender);
end;

procedure TPreviewForm.EditItemClick(Sender: TObject);
var
  I: Integer;
  PrimImage: TPrimImage;
  PrintDocRec: TPrintDocRec;
  FormList: TList;
  FN: string;
begin
  if Image.Visible then
  begin
    if ShowMode = 0 then
    begin
      {EditMode := 0;}
      ShowAllToolButton.Down := True;
      WasChanged := False;
      with PrevManager do
      begin
        for I := 1 to ComponentCount do
        begin
          PrimImage := TPrimImage.Create(ScrollBox);
          PrimImage.GraphPrim := Prims[I-1];
          PrimImage.Parent := ScrollBox;
        end;
        Image.Hide;
        EditToolBar.Show;
        ScaleRxSpinEdit.Enabled := False;
        PageEdit.Enabled := False;
        MaxPageEdit.Enabled := False;
        OkBtn.Caption := 'Вернуться';
        Scale100Item.Enabled := False;
      end;
    end
    else
      with PrevPrintDBGrid do
      begin
        DataBaseForm.TakeTabPrintData(PrintDocRec, FormList); 
        FN := PatternDir + PrintDocRec.GraphForm;
        WinExec(PChar('notepad.exe '+FN), SW_SHOW);
      end;
  end
  else
    CloseItemClick(nil);
end;

var
  Mode: Integer = 0;
  P0: TPoint = (X:0; Y:0);

class procedure TPreviewForm.MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  ALogFont: TLogFont;
begin
  with Sender as TPrimImage do
  begin
    if Button=mbLeft then
    begin
      case Cursor of
        crHandPoint:
          Mode := 1;
        crSizeNWSE:
          Mode := 2;
        crSizeWE:
          Mode := 3;
        crSizeNS:
          Mode := 4;
        else
          Mode := 0;
      end;
      P0 := ClientToScreen(Point(X, Y));
      if SelectedPrimImage <> Sender then
      begin
        if SelectedPrimImage<>nil then
        try
          SelectedPrimImage.Invalidate;
        except
        end;
        SelectedPrimImage := Sender as TPrimImage;
        Invalidate;
      end;
    end
    else
    if GraphPrim is TGPRect then
    with GraphPrim as TGPRect do
    begin
      GrPropertyForm := TGrPropertyForm.Create(PreviewForm);
      with GrPropertyForm do
      begin
        IderEdit.Text := Ident;
        NumberEdit.Text := IntToStr(GraphPrim.ComponentIndex);
        LeftEdit.Text := IntToStr(Bounds.Left);
        TopEdit.Text := IntToStr(Bounds.Top);
        WidthEdit.Text := IntToStr(Bounds.Right-Bounds.Left);
        HeightEdit.Text := IntToStr(Bounds.Bottom-Bounds.Top);
        if GraphPrim is TGPParagraph then
          with GraphPrim as TGPParagraph do
          begin
            TextGroupBox.Show;
            MaskEdit.Text := Mask;
            FontComboEdit.Text := LogFontToStr(LogFont);
            AtrNum := Format;
          end;
        if ShowModal=mrOk then
        begin
          Bounds.Left := StrToInt(LeftEdit.Text);
          Bounds.Top := StrToInt(TopEdit.Text);
          Bounds.Right := StrToInt(WidthEdit.Text)+Bounds.Left;
          Bounds.Bottom := StrToInt(HeightEdit.Text)+Bounds.Top;
          if GraphPrim is TGPParagraph then
            with GraphPrim as TGPParagraph do
            begin
              Mask := MaskEdit.Text;
              StrToLogFont(FontComboEdit.Text, ALogFont);
              LogFont := ALogFont;
              if AtrNumLabel.Font.Color=clNavy then
                Format := AtrNum;
            end;
          Rebuild;
          (Sender as TPrimImage).Repaint;
          PreviewForm.WasChanged := True;
        end;
        Free;
      end;
    end;
  end;
end;

class procedure TPreviewForm.MouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
const
  Bord = 3;
var
  P1: TPoint;
  dX, dY: Integer;
begin
  with Sender as TPrimImage do
  begin
    if Mode=0 then
    begin
      if (X>Width-Bord) and (Y>Height-Bord) and not(GraphPrim is TGPLine) then
        Cursor := crSizeNWSE
      else
      if (X>Width-Bord) and not((GraphPrim is TGPRect)
        and ((GraphPrim as TGPRect).Bounds.Left=(GraphPrim as TGPRect).Bounds.Right))
      then
        Cursor := crSizeWE
      else
      if (Y>Height-Bord) and not((GraphPrim is TGPRect)
        and ((GraphPrim as TGPRect).Bounds.Top=(GraphPrim as TGPRect).Bounds.Bottom))
      then
        Cursor := crSizeNS
      else
        Cursor := crHandPoint;
    end
    else
    if GraphPrim is TGPRect then
    with GraphPrim as TGPRect do
    begin
      P1 := ClientToScreen(Point(X, Y));
      dX := P1.X-P0.X;
      dY := P1.Y-P0.Y;
      dX := ViewToVirtX(dX);
      dY := ViewToVirtY(dY);
      case Mode of
        1:
          begin
            Bounds := Rect(Bounds.Left + dX, Bounds.Top + dY,
              Bounds.Right + dX, Bounds.Bottom + dY);
          end;
        2, 3, 4:
          begin
            if Mode=3 then
              dY := 0;
            if Mode=4 then
              dX := 0;
            dX := Bounds.Right + ViewToVirtX(dX);
            dY := Bounds.Bottom + ViewToVirtY(dY);
            if dX<0 then
              dX := 0;
            if dY<0 then
              dY := 0;
            Bounds := Rect(Bounds.Left, Bounds.Top, dX, dY);
          end;
      end;
      Rebuild;
      PreviewForm.WasChanged := True;
      P0 := P1;
    end;
  end;
end;

class procedure TPreviewForm.MouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  with Sender as TPrimImage do
  begin
    if Mode<>0 then
      Mode := 0;
  end;
end;

procedure TPreviewForm.RefreshToolButtonClick(Sender: TObject);
var
  I: Integer;
begin
  if not Image.Visible then
  begin
    with ScrollBox do
    begin
      I := ComponentCount;
      while I>0 do
      begin
        Dec(I);
        if Components[I] is TPrimImage then
          (Components[I] as TPrimImage).Rebuild;
      end;
      Repaint;
    end;
  end;
end;

procedure TPreviewForm.DelToolButtonClick(Sender: TObject);
begin
  if SelectedPrimImage<>nil then
  begin
    SelectedPrimImage.GraphPrim.Free;
    SelectedPrimImage.Free;
    SelectedPrimImage := nil;
  end;
end;

procedure TPreviewForm.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
const
  Step = 1;
var
  dX, dY: Integer;
begin
  if SelectedPrimImage<>nil then
    case Key of
      VK_DELETE:
        DelToolButtonClick(nil);
      Ord('W'), Ord('X'), Ord('A'), Ord('D'),
      VK_HOME, VK_END, VK_PRIOR, VK_NEXT:
        begin
          if SelectedPrimImage.GraphPrim is TGPRect then
          begin
            dX := 0;
            dY := 0;
            case Key of
              Ord('X'), VK_NEXT:
                dY := Step;
              Ord('W'), VK_PRIOR:
                dY := -Step;
              Ord('A'), VK_HOME:
                dX := -Step;
              Ord('D'), VK_END:
                dX := Step;
            end;
            if ssCtrl in Shift then
            begin
              dX := dX*5;
              dY := dY*5;
            end;
            with SelectedPrimImage.GraphPrim as TGPRect do
              if ssShift in Shift then
                Bounds := Rect(Bounds.Left, Bounds.Top,
                  Bounds.Right + dX, Bounds.Bottom + dY)
              else
                Bounds := Rect(Bounds.Left + dX, Bounds.Top + dY,
                  Bounds.Right + dX, Bounds.Bottom + dY);
            SelectedPrimImage.Rebuild;
          end;
        end;
    end;
  case Key of
    VK_ESCAPE:
      if Image.Visible then
        CloseItemClick(nil);
  end;
end;

procedure TPreviewForm.SaveToolButtonClick(Sender: TObject);
const
  MesTitle: PChar = 'Сохранение шаблона';
var
  PrintDocRec: TPrintDocRec;
  FormList: TList;
  FN: string;
begin
  with PrevManager do
  begin
    DataBaseForm.TakeFormPrintData(PrintDocRec, FormList);
    FN := PatternDir + PrintDocRec.GraphForm;
    if not FileExists(FN) or (MessageBox(Handle, PChar('Перезаписать '+FN+'?'),
      MesTitle, MB_YESNOCANCEL or MB_ICONWARNING)=ID_YES) then
    begin
      SaveToFile(FN);
      WasChanged := False;
    end;
  end;
end;

procedure TPreviewForm.FormCreate(Sender: TObject);
begin
  PopupMenu.Images := PrevImageList;
  EditToolBar.Images := PrevImageList;
end;

procedure TPreviewForm.LineToolButtonClick(Sender: TObject);
var
  T, C, dX, dY: Integer;
  F: TextFile;
  PrimImage, PrimImage2: TPrimImage;
  S: string;
  AGraphPrim: TGraphPrim;
begin
  T := (Sender as TComponent).Tag;
  if (-1<=T) and (T<AllPrimsComboBox.Items.Count) then
  begin
    if T<0 then
    begin
      NewPrimComboBox.Items.Clear;
      if SelectedPrimImage<>nil then
      begin
        SelectedPrimImage.GraphPrim.SaveProperties(S);
        if Length(S)>0 then
          NewPrimComboBox.Items.Text := S;
      end;
    end
    else
      NewPrimComboBox.Items.Text := AllPrimsComboBox.Items.Strings[T];
    if NewPrimComboBox.Items.Count>0 then
    begin
      C := PrevManager.LoadFromListOrFile(NewPrimComboBox.Items, F);
      if C=1 then
      begin
        PrimImage := TPrimImage.Create(ScrollBox);
        with PrevManager do
        begin
          AGraphPrim := Prims[ComponentCount-1];
          if T<0 then
          begin
            dX := 5;
            dY := 5;
          end
          else begin
            dX := ScrollBox.HorzScrollBar.Position;
            dY := ScrollBox.VertScrollBar.Position;
          end;
          dX := ViewToVirtX(dX);
          dY := ViewToVirtX(dY);
          if AGraphPrim is TGPRect then
            with AGraphPrim as TGPRect do
              Bounds := Rect(Bounds.Left+dX, Bounds.Top+dY, Bounds.Right+dX,
                Bounds.Bottom+dY);
          PrimImage.GraphPrim := AGraphPrim;
        end;
        PrimImage.Parent := ScrollBox;
        if PrimImage.Enabled{Visible} then
        begin
          PrimImage2 := SelectedPrimImage;
          SelectedPrimImage := PrimImage;
          if PrimImage2<>nil then
            PrimImage2.Repaint;
          PrimImage.Repaint;
        end;
      end
      else
        MessageBox(Handle, PChar('Не удалось добавить примитив ('+IntToStr(C)+') '
          +NewPrimComboBox.Items.Text), 'Добавление нового', MB_OK or MB_ICONERROR);
    end;
  end;
end;

procedure TPreviewForm.FormCloseQuery(Sender: TObject;
  var CanClose: Boolean);
var
  I: Integer;
begin
  if not Image.Visible then
  begin
    if WasChanged then
    begin
      I := MessageBox(Handle, 'Сохранить сделанные изменения в печатной форме?',
        'Сохранение формы', MB_YESNOCANCEL or MB_ICONWARNING or MB_DEFBUTTON2);
      case I of
        ID_YES:
          SaveToolButtonClick(nil);
        ID_NO:
          WasChanged := False;
      end;
    end;
    if not WasChanged then
    begin
      with ScrollBox do
      begin
        I := ComponentCount;  
        while I>0 do  
        begin  
          Dec(I);  
          if Components[I] is TPrimImage then  
            Components[I].Free;  
        end;  
      end;  
      EditToolBar.Hide;  
      Image.Show;  
      ScaleRxSpinEdit.Enabled := True;  
      PageEdit.Enabled := True;
      MaxPageEdit.Enabled := True;
      OkBtn.Caption := 'Закрыть';
      SelectedPrimImage := nil;
      FormResize(nil);
    end;
    CanClose := False;
  end;
end;

procedure TPreviewForm.ShowAllToolButtonClick(Sender: TObject);
var
  I: Integer;
begin
  I := EditMode;
  EditMode := (Sender as TComponent).Tag;
  if I<>EditMode then
  begin
    RefreshToolButtonClick(nil);
    if (SelectedPrimImage<>nil) and SelectedPrimImage.Enabled{Visible} then
      SelectedPrimImage := nil;
  end;
end;

procedure TPreviewForm.SetToolBtnIndexes(ixRefr, ixSave, ixLine, ixRect, ixCirc,
  ixText, ixCopy, ixDel, ixShowA, ixShowT, ixShowNT: Integer);
begin
  RefreshToolButton.ImageIndex :=      ixRefr;
  SaveToolButton.ImageIndex :=         ixSave;

  LineToolButton.ImageIndex :=         ixLine;
  RectToolButton.ImageIndex :=         ixRect;
  CircToolButton.ImageIndex :=         ixCirc;
  TextToolButton.ImageIndex :=         ixText;

  CopyToolButton.ImageIndex :=         ixCopy;
  DelToolButton.ImageIndex :=          ixDel;

  ShowAllToolButton.ImageIndex :=      ixShowA;
  ShowTextToolButton.ImageIndex :=     ixShowT;
  ShowNoTextToolButton.ImageIndex :=   ixShowNT;
end;


end.

