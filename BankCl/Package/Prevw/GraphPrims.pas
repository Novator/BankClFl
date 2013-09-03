unit GraphPrims;

interface

uses Classes, WinTypes, WinProcs, Dialogs, SysUtils, Db, DbGrids, Utilits;

const
  DraftFileExt: string[3]='dxf';

type
  TCoord = record X,Y,Z:Real end;        {координата}
  TGrCoord = record X,Y,Z:Integer end;   {графическая координата}

type
  TDraftElement = class(TComponent)                {прототип раздела в секции}
  public
    class function DxfName: string; virtual; abstract;
  end;

  TGraphPrim = class(TDraftElement)
  protected
  public
    //Name: string;
    Layer: string;
    Height: Integer;
    //procedure Paint; virtual; abstract;
    procedure SaveProperties(var S: string); virtual;
    procedure LoadProperties(S: string); virtual; abstract;
    procedure Save(var F:Text); virtual;
    constructor Create(AnOwner: TComponent); override;
    procedure Draw(DC: HDC); virtual; abstract;
    procedure DrawLoc(DC: HDC); virtual; abstract;
    function GetLimits: TRect; virtual; abstract;
    class function Ident: string; virtual; abstract;
  end;

  TGPRect = class(TGraphPrim)
  protected
  public
    Bounds: TRect;
    procedure SaveProperties(var S: string); override;
    procedure LoadProperties(S: string); override;
    procedure Draw(DC: HDC); override;
    procedure DrawLoc(DC: HDC); override;
    function GetLimits: TRect; override;
    procedure Save(var F:Text); override;
    class function Ident: string; override;
    class function DxfName: string; override;
  end;

  TGPLine = class(TGPRect)
  protected
  public
    procedure Draw(DC: HDC); override;
    procedure DrawLoc(DC: HDC); override;
    function GetLimits: TRect; override;
    class function Ident: string; override;
    class function DxfName: string; override;
  end;

  TGPEllipse = class(TGPRect)
  protected
  public
    procedure Draw(DC: HDC); override;
    procedure DrawLoc(DC: HDC); override;
    function GetLimits: TRect; override;
    procedure Save(var F:Text); override;
    class function Ident: string; override;
    class function DxfName: string; override;
  end;

  TGPArc = class(TGraphPrim)
  protected
  public
    Bounds, Bounds2: TRect;
    procedure SaveProperties(var S: string); override;
    procedure LoadProperties(S: string); override;
    procedure Draw(DC: HDC); override;
    //procedure DrawLoc(DC: HDC); override;
    function GetLimits: TRect; override;
    procedure Save(var F:Text); override;
    class function Ident: string; override;
    class function DxfName: string; override;
  end;

  TVertex = class(TComponent)       {включение плинии}
  public
    Pset: TCoord;
    ArcK: Real;
  end;

  TGPPolyLine = class(TGraphPrim)
  private
    FPointList: TList;
  protected
    function GetPoint(Index: Integer): TPoint;
  public
    Closed: Boolean;
    procedure SaveProperties(var S: string); override;
    procedure LoadProperties(S: string); override;
    property Points[Index: Integer]: TPoint read GetPoint;
    function PointCount: Integer;
    procedure AddPoint(Value: TPoint);
    procedure Draw(DC: HDC); override;
    //procedure DrawLoc(DC: HDC); override;
    function GetLimits: TRect; override;
    procedure Save(var F:Text); override;
    destructor Destroy; override;

    procedure AddPset(AX,AY,AZ:Real);
    procedure AddArc(AX1,AY1,AZ1,AX2,AY2,AZ2,R:Real; InSide: Boolean);

    class function Ident: string; override;
    class function DxfName: string; override;
  end;

  TGPSetting = class(TGraphPrim)
  protected
  public
    Params: array[0..255] of Char;
    procedure SaveProperties(var S: string); override;
    procedure LoadProperties(S: string); override;
    procedure Draw(DC: HDC); override;
    procedure DrawLoc(DC: HDC); override;
    class function Ident: string; override;
    class function DxfName: string; override;
  end;

  TGPParagraph = class(TGPRect)
  private
    FMask: string;
    FFormat: UINT;
    FLogFont: TLogFont;
  protected
  public
    property LogFont: TLogFont read FLogFont write FLogFont;
    property Mask: string read FMask write FMask;
    property Format: UINT read FFormat write FFormat;
    procedure SaveProperties(var S: string); override;
    procedure LoadProperties(S: string); override;
    procedure Draw(DC: HDC); override;
    procedure DrawLoc(DC: HDC); override;
    procedure Save(var F:Text); override;
    constructor Create(AOwner: TComponent); override;
    class function Ident: string; override;
    class function DxfName: string; override;
  end;

  (*TGPTable = class(TGPRect)
  private
    FLogFont: TLogFont;
  protected
    procedure SaveProperties(var S: string); override;
    procedure LoadProperties(S: string); override;
  public
    property LogFont: TLogFont read FLogFont write FLogFont;
    procedure Draw(DC?: HDC); override;
    constructor Create(AOwner: TComponent); override;
    class function Ident: string; override;?
  end;*)

  TParagraph = class(TDraftElement)                {прототип раздела в секции}
  public
    procedure Save(var F:Text); virtual;
    //constructor Create(AnOwner: TComponent); override;
  end;

  TGraphPrimManager = class(TParagraph)
  private
    FDataSet: TDataSet;
  protected
    function GetGraphPrim(Index: Integer): TGraphPrim;
  public
    LogPen: TLogPen;
    LogBrush: TLogBrush;
    property Prims[Index: Integer]: TGraphPrim read GetGraphPrim;
    procedure SaveToListOrFile(AList: TStrings; var F: TextFile);
    procedure SaveToList(AList: TStrings);
    function SaveToFile(FileName: TFileName): Boolean;
    function LoadFromListOrFile(AList: TStrings; var F: TextFile): Integer;
    procedure LoadFromList(AList: TStrings);
    function LoadFromFile(FileName: TFileName): Boolean;
    procedure Draw(DC: HDC; AScaleX, AScaleY: Real; AWinOrigin: TPoint); virtual;
    function GetLimits: TRect; virtual;
    constructor Create(AOwner: TComponent); override;
    function InitForm(FormFile: TFileName; ADataSet: TDataSet): Boolean;
    class function DxfName: string; override;
    procedure Save(var F:Text); override;
  end;

  TSection = class(TDraftElement)                 {секция}
    //procedure Paint; virtual;
    procedure Save(var F:Text); virtual;
    constructor Create(AnOwner: TComponent);
    //class function DxfName: string; override;
  end;

  TDraft = class(TDraftElement)                   {чертеж - файл DXF}
  public
    procedure SetDraftScalePixOnCm(ScaleX,ScaleY: Real);
    procedure SetDraftLimitsOnMM(LimX,LimY: Real);
    procedure SetBaseCoord(X,Y,Z: Real);
    //procedure Paint(ABitMap: TBitMap);
    function SaveToFile(FileName:string):Integer;
    //class function DxfName: string; override;
  end;

  TPageOrientation = ({pgoDefault, }pgoPortrait, pgoLandscape);

  TPrintDBGrid = class(TComponent)
  private
    FDBGrid: TDBGrid;
    FSetupFileName: TFileName;
    FHeader, FFooter, FPager: TGraphPrimManager;
    FWidths: TList;
    FLogFont: TLogFont;
    FLogPen: TLogPen;
    FLogBrush: TLogBrush;
    FRowFactor: Real;
    FTextAttr: Integer;
    FRowOnPage1, FRowOnPage2, FRowOnPage3: Integer;
    FHeaderLimits, FFooterLimits, FPagerLimits: TRect;
    FRowHeight: Integer;
    FPageCount: Integer;
    FLastGridBottom: Integer;
    FGridWidth: Integer;
    FSkipPage: Integer;
    FYCoord, FSheetWidth, FSheetHeight: Integer;
    FPageOrientation: TPageOrientation;
    FShowPagerOnFirstPage: Boolean;
  protected
    function GetWidth(Index: Integer): Integer;
    procedure SetDBGrid(Value: TDBGrid);
  public
    property ShowPagerOnFirstPage: Boolean read FShowPagerOnFirstPage
      write FShowPagerOnFirstPage;
    property YCoord: Integer read FYCoord write FYCoord;
    property SheetWidth: Integer read FSheetWidth write FSheetWidth;
    property SheetHeight: Integer read FSheetHeight write FSheetHeight;
    property PageCount: Integer read FPageCount;
    property GridWidth: Integer read FGridWidth;
    property SkipPage: Integer read FSkipPage;
    property PageOrientation: TPageOrientation read FPageOrientation write FPageOrientation;
    property LastGridBottom: Integer read FLastGridBottom;
    property DBGrid: TDBGrid read FDBGrid write SetDBGrid;
    property SetupFileName: TFileName read FSetupFileName write FSetupFileName;
    property Widths[Index: Integer]: Integer read GetWidth;
    property Header: TGraphPrimManager read FHeader;
    property Footer: TGraphPrimManager read FFooter;
    property Pager: TGraphPrimManager read FPager;
    property LogFont: TLogFont read FLogFont write FLogFont;
    property RowFactor: Real read FRowFactor write FRowFactor;
    property TextAttr: Integer read FTextAttr write FTextAttr;
    property RowOnPage1: Integer read FRowOnPage1;
    property RowOnPage2: Integer read FRowOnPage2;
    property RowOnPage3: Integer read FRowOnPage3;
    function GetGridWidth: Integer;
    function GetLimits: TRect; virtual;
    function LoadSetup: Boolean;
    procedure Draw(DC: HDC; AScaleX, AScaleY: Real; AWinOrigin: TPoint;
      APage: Integer);
    procedure ResetSettings;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure DevideArea;
  end;

  TFloatPoint = record X,Y: Real end;

const
  OutDig: Byte=6;                    {вывод разрядов}
  DraftScalePixOnCm: TCoord=(X:10; Y:10; Z:10);
  DraftLimitsOnMM: TCoord=(X:10; Y:10; Z:10);
  BaseCoord: TCoord =(X:0; Y:0; Z:0);
  CurLayer: string='0';
  CurHeight: Integer=0;
var
  GlobScale: TFloatPoint = (X:1; Y:1);
  WinOrigin: TPoint = (X:0; Y:0);
  TabCellMargin: TPoint = (X:1; Y:0);
  FormPageOrientation: TPageOrientation = {pgoDefault}pgoPortrait;
  ListPageOrientation: TPageOrientation = {pgoDefault}pgoPortrait;
  RotatePage: Boolean = False;

function VirtToViewX(Value: Integer): Integer;
function ViewToVirtX(Value: Integer): Integer;
function VirtToViewY(Value: Integer): Integer;
function ViewToVirtY(Value: Integer): Integer;
function VirtToView(Value: TPoint): TPoint;
function ViewToVirt(Value: TPoint): TPoint;
function VirtToWin(Value: TPoint): TPoint;
function ExtRect(R: TRect): TRect;
procedure StrToLogFont(S: string; var Result: TLogFont);
function LogFontToStr(ALogFont: TLogFont): string;

implementation

uses Graphics;

{=== Общие функции ===}

function VirtToViewX(Value: Integer): Integer;
begin
  Result:=Round(Value*GlobScale.X);
end;

function ViewToVirtX(Value: Integer): Integer;
begin
  Result:=Round(Value/GlobScale.X);
end;

function VirtToViewY(Value: Integer): Integer;
begin
  Result:=Round(Value*GlobScale.Y);
end;

function ViewToVirtY(Value: Integer): Integer;
begin
  Result:=Round(Value/GlobScale.Y);
end;

function VirtToView(Value: TPoint): TPoint;
begin
  Result.X := VirtToViewX(Value.X);
  Result.Y := VirtToViewY(Value.Y);
end;

function ViewToVirt(Value: TPoint): TPoint;
begin
  Result.X := ViewToVirtX(Value.X);
  Result.Y := ViewToVirtY(Value.Y);
end;

function VirtToWin(Value: TPoint): TPoint;
begin
  Result.X := WinOrigin.X + VirtToViewX(Value.X);
  Result.Y := WinOrigin.Y + VirtToViewY(Value.Y);
end;

function ExtRect(R: TRect): TRect;
begin
  Result := R;
  if Result.Left>Result.Right then
    Inc(Result.Left)
  else
    Inc(Result.Right);
  if Result.Top>Result.Bottom then
    Inc(Result.Top)
  else
    Inc(Result.Bottom);
end;

function MMToPix(MM:Real; Coord:Byte):Integer;
begin
  case Coord of
    1: Result:=Round(DraftScalePixOnCm.X/10*MM);
    2: Result:=Round(DraftScalePixOnCm.Y/10*MM);
    3: Result:=Round(DraftScalePixOnCm.Z/10*MM);
    else Result:=0;
  end;
end;

function CoordOnPix(MM: Real; Coord:Byte):Integer;
begin
  Result:=MMToPix(MM,Coord);
  with BaseCoord do begin
    case Coord of
      1: Result:=MMToPix(X,Coord)+Result;
      2: Result:=MMToPix(DraftLimitsOnMM.Y-Y,Coord)-Result;
    end
  end;
end;

function RealToStr(R:Real):string;
var S: string;
    L,J,I: Byte;
begin
  Str(R:0:OutDig,S);
  J:=Pos('.',S);
  if J>0 then begin
    L:=Length(S); I:=L; Inc(J);
    while (I>J) and (S[I]='0') do Dec(I);
    if I<L then Delete(S,I+1,L-I)
  end;
  RealToStr:=S;
end;

function Coord(X,Y,Z: Real):TCoord;
begin
  Result.X:=X; Result.Y:=Y; Result.Z:=Z;
end;

procedure SavePoint(var F:Text; XN,YN,ZN: string; P:TCoord);
begin
  WriteLn(F,' '+XN);
  WriteLn(F, RealToStr(P.X));
  WriteLn(F,' '+YN);
  WriteLn(F, RealToStr(P.Y));
  WriteLn(F,' '+ZN);
  WriteLn(F, RealToStr(P.Z));
end;

function Dist(P1,P2: TCoord):Real;
begin
  Dist:=Sqrt(Sqr(P2.X-P1.X)+Sqr(P2.Y-P1.Y)+Sqr(P2.Z-P1.Z));
end;

function MakeArcK(D,R:Real; InSide: Boolean):Real;
var
  MD,H: Real;
begin
  MD:=Abs(D);
  if (MD<R) or (R=0) then MakeArcK:=0
  else begin
    H:=Sqrt(Sqr(MD)-Sqr(R));
    if InSide then H:=-H;
    MakeArcK:=(MD+H)/R*D/MD;
  end;
end;

{=== Описание классов ===}

constructor TGraphPrim.Create(AnOwner: TComponent);
begin
  inherited Create(AnOwner);
  //Name := 'NONAME';
  Layer := CurLayer;
  Height := CurHeight;
end;

procedure TGraphPrim.Save(var F:Text);
begin
  WriteLn(F,'  0');
  WriteLn(F,DxfName);
  WriteLn(F,'  8');
  WriteLn(F,Layer);
  if Height<>0 then
  begin
    WriteLn(F,' 39');
    WriteLn(F,Height);
  end;
end;

procedure TGraphPrim.SaveProperties(var S: string);
begin
  S := Ident;
end;

class function TGPRect.Ident: string;
begin
  Result := 'RECT';
end;

class function TGPRect.DxfName: string;
begin
  Result := 'RECT';
end;

procedure TGPRect.Save(var F:Text);
begin
  inherited Save(F);
  SavePoint(F,'10','20','30', Coord(Bounds.Top, Bounds.Left, 0));
  SavePoint(F,'11','21','31', Coord(Bounds.Bottom, Bounds.Right, 0));
end;

procedure TGPRect.SaveProperties(var S: string);
begin
  inherited SaveProperties(S);
  S := S+'('+IntToStr(Bounds.Left)+','+IntToStr(Bounds.Top)+','
    +IntToStr(Bounds.Right)+','+IntToStr(Bounds.Bottom)+')';
end;

procedure TGPRect.LoadProperties(S: string);
var
  J,K,Z,Err: Integer;
  V: string;
begin
  J:=0;
  repeat
    Inc(J);
    K:=Pos(',',S);
    if K>0 then
    begin
      V:=Copy(S,1,K-1); System.Delete(S,1,K)
    end
    else begin
      V:=S; S:=''
    end;
    Val(V,Z,Err);
    if Err=0 then
    begin
      case J of
        1: Bounds.Left:=Z;
        2: Bounds.Top:=Z;
        3: Bounds.Right:=Z;
        4: Bounds.Bottom:=Z;
        else MessageBox(ParentWnd, PChar('Лишний параметр ['+V+']'), 'RECT', MB_OK or MB_ICONWARNING);
      end
    end
    else
      MessageBox(ParentWnd, PChar('Ошибка оцифрения ['+V+']'), 'RECT',
        MB_OK or MB_ICONWARNING);
  until K=0;
end;

procedure TGPRect.Draw(DC: HDC);
var
  P: TPoint;
  R: TRect;
begin
  with Bounds do
  begin
    P:=VirtToWin(Point(Left,Top));
    R.Left:=P.X; R.Top:=P.Y;
    P:=VirtToWin(Point(Right,Bottom));
    R.Right:=P.X; R.Bottom:=P.Y;
    R:=ExtRect(R);
    Rectangle(DC,R.Left,R.Top,R.Right,R.Bottom);
  end;
end;

function GetRectBase(R: TRect): TPoint;
begin
  with R do
  begin
    if Left<=Right then
      Result.x := Left
    else
      Result.x := Right;
    if Top<=Bottom then
      Result.y := Top
    else
      Result.y := Bottom;
  end;
end;

function MoveOnBase(R: TRect): TRect;
var
  P1, P2: TPoint;
begin
  P1 := GetRectBase(R);
  with R do
  begin
    P2 := VirtToView(Point(Right-P1.x, Bottom-P1.y));
    P1 := VirtToView(Point(Left-P1.x, Top-P1.y));
    Result.Left := P1.x+1; Result.Top := P1.y+1;
    Result.Right := P2.X+1; Result.Bottom := P2.Y+1;
  end;
end;

procedure TGPRect.DrawLoc(DC: HDC);
var
  R: TRect;
begin
  R := MoveOnBase(Bounds);
  R := ExtRect(R);
  Rectangle(DC, R.Left, R.Top, R.Right, R.Bottom);
end;

function TGPRect.GetLimits: TRect;
begin
  with Bounds do
  begin
    if Left<Right then
    begin
      Result.Left:=Left;
      Result.Right:=Right;
    end
    else begin
      Result.Left:=Right;
      Result.Right:=Left;
    end;
    if Top<Bottom then
    begin
      Result.Top:=Top;
      Result.Bottom:=Bottom;
    end
    else begin
      Result.Top:=Bottom;
      Result.Bottom:=Top;
    end;
  end;
end;

class function TGPSetting.Ident: string;
begin
  Result := 'SET';
end;

class function TGPSetting.DxfName: string;
begin
  Result := 'SETTING';
end;

procedure TGPSetting.SaveProperties(var S: string);
begin
  inherited SaveProperties(S);
  S := S+'('+Params+')';
end;

procedure TGPSetting.LoadProperties(S: string);
begin
  StrPLCopy(Params, S, SizeOf(Params));
end;

procedure TGPSetting.Draw(DC: HDC);
var
  J, K, Z, Err, P1, P2, P3, P4, P5, P6: Integer;
  S, V: string;
begin
  P1 := 0;
  P2 := 0;
  P3 := 0;
  P4 := 0;
  P5 := 0;
  P6 := 0;

  S := StrPas(Params);
  J := 0;
  repeat
    Inc(J);
    K := Pos(',', S);
    if K>0 then
    begin
      V := Copy(S, 1, K-1);
      System.Delete(S, 1, K)
    end
    else begin
      V := S;
      S := ''
    end;
    Val(V, Z, Err);
    if Err=0 then
    begin
      case J of
        1: P1 := Z;
        2: P2 := Z;
        3: P3 := Z;
        4: P4 := Z;
        5: P5 := Z;
        6: P6 := Z;
      end
    end
    else
      MessageBox(ParentWnd, PChar('Ошибка оцифрения ['+V+']'), 'SET',
        MB_OK or MB_ICONWARNING);
  until K=0;
  if J>1 then
  begin
    case P1 of
      1:
        begin
          WinOrigin.X := VirtToViewX(P2);
          WinOrigin.Y := VirtToViewY(P3);
        end;
      2:
        WinOrigin.X := VirtToViewX(P2);
      3:
        WinOrigin.Y := VirtToViewY(P2);
      4:
        begin
          TabCellMargin.X := P2;
          TabCellMargin.Y := P3;
        end;
      5:
        TabCellMargin.X := P2;
      6:
        TabCellMargin.Y := P2;
      7:
        if (0<=P2) and (P2<=2) then
          FormPageOrientation := TPageOrientation(P2);
      else
        MessageBox(ParentWnd, PChar('Неизвестная установка ['+Params+']'), 'SET',
          MB_OK or MB_ICONWARNING);
    end;
  end
  else
    MessageBox(ParentWnd, PChar('Мало параметров ['+Params+']'), 'SET',
      MB_OK or MB_ICONWARNING);
end;

procedure TGPSetting.DrawLoc(DC: HDC);
begin
  Draw(DC);
end;

class function TGPLine.Ident: string;
begin
  Result := 'LINE';
end;

class function TGPLine.DxfName: string;
begin
  Result := 'LINE';
end;

procedure TGPLine.Draw(DC: HDC);
var
  P1,P2: TPoint;
begin
  with Bounds do
  begin
    P1 := Point(Left,Top); P1 := VirtToWin(P1);
    P2 := Point(Right,Bottom); P2 := VirtToWin(P2);
    MoveToEx(DC,P1.X,P1.Y,nil);
    LineTo(DC,P2.X,P2.Y);
  end;
end;

procedure TGPLine.DrawLoc(DC: HDC);
var
  R: TRect;
begin
  R := MoveOnBase(Bounds);
  MoveToEx(DC, R.Left, R.Top, nil);
  LineTo(DC, R.Right, R.Bottom);
end;

function TGPLine.GetLimits: TRect;
begin
  with Bounds do
  begin
    if Left<Right then
    begin
      Result.Left:=Left;
      Result.Right:=Right;
    end
    else begin
      Result.Left:=Right;
      Result.Right:=Left;
    end;
    if Top<Bottom then
    begin
      Result.Top:=Top;
      Result.Bottom:=Bottom;
    end
    else begin
      Result.Top:=Bottom;
      Result.Bottom:=Top;
    end;
  end;
end;

class function TGPEllipse.Ident: string;
begin
  Result := 'ELL';
end;

class function TGPEllipse.DxfName: string;
begin
  Result := 'CIRCLE';
end;

procedure TGPEllipse.Draw(DC: HDC);
var
  P: TPoint;
  R: TRect;
begin
  with Bounds do
  begin
    P := VirtToWin(Point(Left,Top)); R.Left:=P.X; R.Top:=P.Y;
    P := VirtToWin(Point(Right,Bottom)); R.Right:=P.X; R.Bottom:=P.Y;
    R := ExtRect(R);
    Ellipse(DC, R.Left, R.Top, R.Right, R.Bottom);
  end;
end;

procedure TGPEllipse.DrawLoc(DC: HDC);
var
  R: TRect;
begin
  R := MoveOnBase(Bounds);
  R := ExtRect(R);
  Ellipse(DC, R.Left, R.Top, R.Right, R.Bottom);
end;

procedure TGPEllipse.Save(var F:Text);
begin
  inherited Save(F);
  {WriteLn(F,' 40');
  WriteLn(F, RealToStr(R));!!!}
end;

function TGPEllipse.GetLimits: TRect;
begin
  with Bounds do
  begin
    if Left<Right then
    begin
      Result.Left:=Left;
      Result.Right:=Right;
    end
    else begin
      Result.Left:=Right;
      Result.Right:=Left;
    end;
    if Top<Bottom then
    begin
      Result.Top:=Top;
      Result.Bottom:=Bottom;
    end
    else begin
      Result.Top:=Bottom;
      Result.Bottom:=Top;
    end;
  end;
end;

class function TGPArc.Ident: string;
begin
  Result := 'ARC';
end;

class function TGPArc.DxfName: string;
begin
  Result := 'ARC';
end;

procedure TGPArc.Save(var F:Text);
begin
  inherited Save(F);
  {WriteLn(F,' 50');
  WriteLn(F,RealToStr(A1));
  WriteLn(F,' 51');
  WriteLn(F,RealToStr(A2));}
end;

procedure TGPArc.SaveProperties(var S: string);
begin
  S := Ident+'('+IntToStr(Bounds.Left)+','+IntToStr(Bounds.Top)+','
    +IntToStr(Bounds.Right)+','+IntToStr(Bounds.Bottom)+','
    +IntToStr(Bounds2.Left)+','+IntToStr(Bounds2.Top)+','
    +IntToStr(Bounds2.Right)+','+IntToStr(Bounds2.Bottom)+')';
end;

procedure TGPArc.LoadProperties(S: string);
var
  J,K,Z,Err: Integer;
  V: string;
begin
  J:=0;
  repeat
    Inc(J);
    K:=Pos(',',S);
    if K>0 then
    begin
      V:=Copy(S,1,K-1);
      System.Delete(S,1,K)
    end
    else begin
      V:=S;
      S:=''
    end;
    Val(V,Z,Err);
    if Err=0 then
    begin
      case J of
        1: Bounds.Left:=Z;
        2: Bounds.Top:=Z;
        3: Bounds.Right:=Z;
        4: Bounds.Bottom:=Z;
        5: Bounds2.Left:=Z;
        6: Bounds2.Top:=Z;
        7: Bounds2.Right:=Z;
        8: Bounds2.Bottom:=Z;
        else
          MessageBox(ParentWnd, PChar('Лишний параметр ['+V+']'), 'ARC', MB_OK or MB_ICONWARNING);
      end
    end
    else
      MessageBox(ParentWnd, PChar('Ошибка оцифрения ['+V+']'), 'ARC', MB_OK or MB_ICONWARNING);
  until K=0;
end;

procedure TGPArc.Draw(DC: HDC);
var
  P,P2: TPoint;
  R: TRect;
begin
  with Bounds do begin
    P:=VirtToWin(Point(Left,Top)); R.Left:=P.X; R.Top:=P.Y;
    P:=VirtToWin(Point(Right,Bottom)); R.Right:=P.X; R.Bottom:=P.Y;
    R:=ExtRect(R);
  end;
  with Bounds2 do begin
    P:=VirtToWin(Point(Left,Top));
    P2:=VirtToWin(Point(Right,Bottom));
  end;
  Arc(DC,R.Left,R.Top,R.Right,R.Bottom,P.X,P.Y,P2.X,P2.Y);
end;

function TGPArc.GetLimits: TRect;
begin
  with Bounds do begin
    if Left<Right then begin
      Result.Left:=Left;
      Result.Right:=Right;
    end else begin
      Result.Left:=Right;
      Result.Right:=Left;
    end;
    if Top<Bottom then begin
      Result.Top:=Top;
      Result.Bottom:=Bottom;
    end else begin
      Result.Top:=Bottom;
      Result.Bottom:=Top;
    end;
  end;
end;

class function TGPPolyLine.Ident: string;
begin
  Result:='PLINE';
end;

class function TGPPolyLine.DxfName: string;
begin
  Result:='POLYLINE';
end;

procedure TGPPolyLine.Save(var F:Text);
var I: Byte;
    P0: TCoord;
begin
  inherited Save(F);
  WriteLn(F,' 66');
  WriteLn(F,'   1');
  P0.X:=0; P0.Y:=0; P0.Z:=0;
  SavePoint(F,'10','20','30',P0);
  if Closed then begin
    WriteLn(F,' 70');
    WriteLn(F,'     1');
  end;
  WriteLn(F,'  0');
  for I:=1 to ComponentCount do begin
    WriteLn(F,'VERTEX');
    WriteLn(F,'  8');
    WriteLn(F,Layer);
    SavePoint(F,'10','20','30',(Components[I-1] as TVertex).Pset);
    if (Components[I-1] as TVertex).ArcK<>0 then begin
      WriteLn(F,' 42');
      WriteLn(F,RealToStr((Components[I-1] as TVertex).ArcK));
    end;
    WriteLn(F,'  0');
  end;
  WriteLn(F,'SEQEND');
  WriteLn(F,'  8');
  WriteLn(F,Layer);
end;

procedure TGPPolyLine.SaveProperties(var S: string);
var I,J: Integer;
    P: TPoint;
begin
  inherited SaveProperties(S);
  S:=S+'(';
  J:=PointCount;
  for I:=1 to J do
  begin
    P:=Points[I];
    S:=S+'['+IntToStr(P.X)+','+IntToStr(P.Y)+']';
  end;
  S:=S+')';
end;

procedure TGPPolyLine.LoadProperties(S: string);
var
  K,I,Err: Integer;
  V: string;
  P: TPoint;
begin
  repeat
    K:=Pos(']',S);
    if K>0 then
    begin
      V:=Copy(S,1,K-1); System.Delete(S,1,K);
      I:=Pos('[',V);
      if I>0 then
      begin
        V:=Copy(V,I+1,Length(V)-I);
        I:=Pos(',',V);
        if I>0 then
        begin
          Val(Copy(V,1,I-1),P.X,Err);
          if Err=0 then
          begin
            Val(Copy(V,I+1,Length(V)-I),P.Y,Err);
            if Err=0 then
              AddPoint(P)
            else
              MessageBox(ParentWnd, PChar('Неверное число Y: '+V), 'PLINE', MB_OK or MB_ICONWARNING);
          end
          else
            MessageBox(ParentWnd, PChar('Неверное число X: '+V), 'PLINE', MB_OK or MB_ICONWARNING);
        end
        else
          MessageBox(ParentWnd, PChar('Нет запятой , в '+V), 'PLINE', MB_OK or MB_ICONWARNING);
      end
      else
        MessageBox(ParentWnd, PChar('Нет скобки [ в '+V), 'PLINE', MB_OK or MB_ICONWARNING);
    end
    else
      S:=''
  until K=0;
end;

function TGPPolyLine.PointCount: Integer;
begin
  if FPointList=nil then
    Result:=0
  else
    Result:=FPointList.Count;
end;

procedure TGPPolyLine.AddPoint(Value: TPoint);
var PointPtr: ^TPoint;
begin
  if FPointList=nil then
    FPointList:=TList.Create;
  New(PointPtr); PointPtr^:=Value;
  FPointList.Add(PointPtr);
end;

function TGPPolyLine.GetPoint(Index: Integer): TPoint;
begin
  Result := TPoint(FPointList.Items[Index-1]^)
end;

procedure TGPPolyLine.Draw(DC: HDC);
var
  I,J: Integer;
  P: TPoint;
begin
  J:=PointCount;
  if J>1 then
  begin
    P:=Points[1]; P:=VirtToWin(P);
    MoveToEx(DC,P.X,P.Y,nil);
    for I:=2 to J do
    begin
      P:=Points[I]; P:=VirtToWin(P);
      LineTo(DC,P.X,P.Y);
    end;
  end;
end;

function TGPPolyLine.GetLimits: TRect;
var I: Integer;
    P: TPoint;
begin
  if PointCount>0 then begin
    P:=Points[1]; Result:=Rect(P.X,P.Y,P.X,P.Y);
    for I:=2 to PointCount do begin
      P:=Points[I];
      if P.X<Result.Left then Result.Left:=P.X;
      if P.X>Result.Right then Result.Right:=P.X;
      if P.Y<Result.Top then Result.Top:=P.Y;
      if P.Y>Result.Bottom then Result.Bottom:=P.Y;
    end;
    Inc(Result.Right);
    Inc(Result.Bottom);
  end else Result:=Rect(0,0,0,0);
end;

procedure TGPPolyLine.AddPset(AX,AY,AZ:Real);
var Vertex: TVertex;
begin
  Vertex := TVertex.Create(Self);
  with Vertex do
  begin
    ArcK := 0;
    Pset := Coord(AX, AY, AZ);
  end;
end;

procedure TGPPolyLine.AddArc(AX1,AY1,AZ1,AX2,AY2,AZ2,R:Real; InSide: Boolean);
var Vertex: TVertex;
    P2: TCoord;
begin
  P2.X:=AX2; P2.Y:=AY2; P2.Z:=AZ2;
  Vertex := TVertex.Create(Self);
  AddPset(AX2,AY2,AZ2);
  with Vertex do
  begin
    ArcK := 0;
    Pset := Coord(AX1,AY1,AZ1);
    if R<>0 then
      ArcK := MakeArcK(2*R,Dist(Pset,P2),InSide);
  end;
end;

destructor TGPPolyLine.Destroy;
var I: Integer;
begin
  if FPointList<>nil then
  begin
    for I:=1 to FPointList.Count do
      Dispose(FPointList.Items[I-1]);
    FPointList.Free;
  end;
  inherited Destroy;
end;

class function TGPParagraph.Ident: string;
begin
  Result:='PARAGRAPH';
end;

class function TGPParagraph.DxfName: string;
begin
  Result:='TEXT';
end;

constructor TGPParagraph.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FFormat := DT_WORDBREAK;
  with FLogFont do
  begin
    lfHeight := 35;
    lfWidth := 0;
    lfEscapement := 0;
    lfOrientation := 0;
    lfWeight := FW_NORMAL;
    lfItalic := 0;
    lfUnderline := 0;
    lfStrikeOut := 0;
    lfCharSet := ANSI_CHARSET;
    lfOutPrecision := OUT_DEFAULT_PRECIS;
    lfClipPrecision := CLIP_DEFAULT_PRECIS;
    lfQuality := DEFAULT_QUALITY;
    lfPitchAndFamily := DEFAULT_PITCH;
    lfFaceName := 'Courier';
  end;
end;

procedure StrToLogFont(S: string; var Result: TLogFont);
const
 MesTitle: PChar = 'Определение FONT';
var
  J,K,Z,Err: Integer;
  V: string;
begin
  J:=0;
  repeat
    Inc(J);
    K := Pos('|',S);
    if K>0 then
    begin
      V := Copy(S,1,K-1);
      System.Delete(S,1,K)
    end
    else begin
      V := S;
      S := ''
    end;
    if J=1 then
      Err := 0
    else
      Val(V,Z,Err);
    if Err=0 then
    with Result do
    begin
      case J of
        1: StrPCopy(lfFaceName,V);
        2: lfHeight:=Z;
        3: lfWidth:=Z;
        4: lfEscapement:=Z;
        5: lfOrientation:=Z;
        6: lfWeight:=Z;
        7: lfItalic:=Z;
        8: lfUnderline:=Z;
        9: lfStrikeOut:=Z;
        10: lfCharSet:=Z;
        11: lfOutPrecision:=Z;
        12: lfClipPrecision := Z;
        13: lfQuality := Z;
        14: lfPitchAndFamily := Z;
        else
          MessageBox(ParentWnd, PChar('Лишний параметр ['+V+']'),
            MesTitle, MB_OK or MB_ICONWARNING);
      end;
    end
    else
      MessageBox(ParentWnd, PChar('Ошибка оцифрения ['+V+']'),
        MesTitle, MB_OK or MB_ICONWARNING);
  until K=0;
end;

function LogFontToStr(ALogFont: TLogFont): string;
var
  I,Z: Integer;
  V: string;
begin
  Result := '';
  for I := 1 to 14 do
  with ALogFont do
  begin
    case I of
      1: V := StrPas(lfFaceName);
      2: Z := lfHeight;
      3: Z := lfWidth;
      4: Z := lfEscapement;
      5: Z := lfOrientation;
      6: Z := lfWeight;
      7: Z := lfItalic;
      8: Z := lfUnderline;
      9: Z := lfStrikeOut;
      10: Z := lfCharSet;
      11: Z := lfOutPrecision;
      12: Z := lfClipPrecision;
      13: Z := lfQuality;
      14: Z := lfPitchAndFamily;
      else
        Z := 0;
    end;
    if I>1 then
    begin
      V := IntToStr(Z);
      Result := Result + '|' + V;
    end
    else
      Result := V;
  end;
end;

function PosAfterChar(C: Char; S: string; D: Char): Integer;
var
  I,L: Integer;
begin
  Result := 0;
  L := 0;
  I := 0;
  while (I<Length(S)) and not ((S[I]=C) and (L=0)) do
  begin
    if S[I]=D then
    begin
      if L=0 then Inc(L) else Dec(L)
    end;
    Inc(I);
  end;
  if (I<=Length(S)) and (S[I]=C) then
    Result := I;
end;

procedure TGPParagraph.SaveProperties(var S: string);
begin
  S:=Ident+'('+IntToStr(Bounds.Left)+','+IntToStr(Bounds.Top)+','
    +IntToStr(Bounds.Right)+','+IntToStr(Bounds.Bottom)+','
    +IntToStr(FFormat)+','
    +''''+LogFontToStr(FLogFont)+''''+','+FMask+')';
end;

procedure TGPParagraph.LoadProperties(S: string);
var
  J,K,Z,Err: Integer;
  V: string;
begin
  J := 0;
  repeat
    Inc(J);
    K := PosAfterChar(',', S, '''');
    if K>0 then
    begin
      V := Copy(S,1,K-1);
      System.Delete(S,1,K)
    end
    else begin
      V := S;
      S := ''
    end;
    case J of
      1..5:
      begin
        Val(V,Z,Err);
        if Err=0 then
        begin
          case J of
            1: Bounds.Left := Z;
            2: Bounds.Top := Z;
            3: Bounds.Right := Z;
            4: Bounds.Bottom := Z;
            5: FFormat := Z;
          end
        end
        else
          MessageBox(ParentWnd, PChar('Ошибка оцифрения ['+V+']'),
            'Paragraph', MB_OK or MB_ICONWARNING);
      end;
      6:
      begin
        if (Length(V)>0) and (V[1]='''') then
          System.Delete(V,1,1);
        if (Length(V)>0) and (V[Length(V)]='''') then
          System.Delete(V,Length(V),1);
        StrToLogFont(V, FLogFont)
      end;
      7: FMask:=V;
    end;
  until K=0;
end;

procedure TGPParagraph.Save(var F:Text);
begin
  inherited Save(F);
  WriteLn(F,'  1');
  WriteLn(F, FMask);
end;

procedure TGPParagraph.Draw(DC: HDC);
var
  Text: array[0..1023] of Char;
  ALogFont: TLogFont;
  Font, Font2: HFONT;
  P: TPoint;
  R: TRect;
begin
  ALogFont := FLogFont;
  ALogFont.lfHeight := -VirtToViewY(ALogFont.lfHeight) div 10;
  Font2 := CreateFontIndirect(ALogFont);
  Font := SelectObject(DC,Font2);
  with Bounds do
  begin
    P := VirtToWin(Point(Left,Top)); R.Left:=P.X; R.Top:=P.Y;
    P := VirtToWin(Point(Right,Bottom)); R.Right:=P.X; R.Bottom:=P.Y;
    R := ExtRect(R);
  end;
  StrPCopy(Text, DecodeFieldMask((Owner as TGraphPrimManager).FDataSet, FMask));
  DrawText(DC, Text, StrLen(Text), R, FFormat);
  Font2 := SelectObject(DC,Font);
  DeleteObject(Font2);
end;

procedure TGPParagraph.DrawLoc(DC: HDC);
var
  Text: array[0..1023] of Char;
  ALogFont: TLogFont;
  Font, Font2: HFONT;
  R: TRect;
begin
  ALogFont := FLogFont;
  ALogFont.lfHeight := -VirtToViewY(ALogFont.lfHeight) div 10;
  Font2 := CreateFontIndirect(ALogFont);
  Font := SelectObject(DC,Font2);
  with Bounds do
  begin
    R := MoveOnBase(Bounds);
    R := ExtRect(R);
  end;
  StrPCopy(Text, DecodeFieldMask((Owner as TGraphPrimManager).FDataSet, FMask));
  DrawText(DC, Text, StrLen(Text), R, FFormat);
  Font2 := SelectObject(DC,Font);
  DeleteObject(Font2);
end;

procedure StrToLogPen(S: string; var Result: TLogPen);
var
  J,K,Z,Err: Integer;
  V: string;
begin
  J:=0;
  repeat
    Inc(J);
    K:=Pos('|',S);
    if K>0 then begin V:=Copy(S,1,K-1); System.Delete(S,1,K) end
    else begin V:=S; S:='' end;
    Val(V,Z,Err);
    if Err=0 then with Result do begin
      case J of
        1: lopnStyle:=Z;
        2: lopnWidth:=Point(Z,0);
        3: lopnColor:=Z;
        else MessageBox(ParentWnd, PChar('Лишний параметр ['+V+']'), 'Определение PEN',
          MB_OK or MB_ICONWARNING);
      end;
    end
    else MessageBox(ParentWnd, PChar('Ошибка оцифрения ['+V+']'), 'Определение PEN',
      MB_OK or MB_ICONWARNING);
  until K=0;
end;

function LogPenToStr(ALogPen: TLogPen): string;
var
  I,Z: Integer;
  V: string;
begin
  Result:='';
  for I:=1 to 3 do with ALogPen do begin
    case I of
      1: Z:=lopnStyle;
      2: Z:=TPoint(lopnWidth).X;
      3: Z:=lopnColor;
      else Z:=0;
    end;
    V:=IntToStr(Z);
    if I>1 then Result:=Result+'|'+V
    else Result:=V;
  end;
end;

procedure StrToLogBrush(S: string; var Result: TLogBrush);
var
  J,K,Z,Err: Integer;
  V: string;
begin
  J:=0;
  repeat
    Inc(J);
    K:=Pos('|',S);
    if K>0 then begin V:=Copy(S,1,K-1); System.Delete(S,1,K) end
    else begin V:=S; S:='' end;
    Val(V,Z,Err);
    if Err=0 then with Result do begin
      case J of
        1: lbStyle:=Z;
        2: lbColor:=Z;
        3: lbHatch:=Z;
        else MessageBox(ParentWnd, PChar('Лишний параметр ['+V+']'),
          'Определение BRUSH', MB_OK or MB_ICONWARNING);
      end;
    end
    else
      MessageBox(ParentWnd, PChar('Ошибка оцифрения ['+V+']'),
        'Определение BRUSH', MB_OK or MB_ICONWARNING);
  until K=0;
end;

function LogBrushToStr(ALogBrush: TLogBrush): string;
var
  I,Z: Integer;
  V: string;
begin
  Result:='';
  for I:=1 to 3 do with ALogBrush do
  begin
    case I of
      1: Z:=lbStyle;
      2: Z:=lbColor;
      3: Z:=lbHatch;
      else Z:=0;
    end;
    V:=IntToStr(Z);
    if I>1 then Result:=Result+'|'+V
    else Result:=V;
  end;
end;

constructor TGraphPrimManager.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  with LogPen do begin
    lopnStyle:=PS_SOLID;
    lopnWidth:=Point(1,0);
    lopnColor:=clBlack;
  end;
  with LogBrush do begin
    lbStyle:=BS_NULL;
    lbColor:=clGreen;
    lbHatch:=HS_DIAGCROSS;
  end;
end;

class function TGraphPrimManager.DxfName: string;
begin
  Result := 'ENTITIES';
end;

procedure TGraphPrimManager.Save(var F:Text);
var I: Word;
begin
  inherited Save(F);
  for I:=1 to ComponentCount do
    (Components[I-1] as TGraphPrim).Save(F);
end;

function TGraphPrimManager.GetGraphPrim(Index: Integer): TGraphPrim;
begin
  Result:=Components[Index] as TGraphPrim;
end;

procedure TGraphPrimManager.SaveToListOrFile(AList: TStrings; var F: TextFile);
var
  I: Integer;
  S: string;
begin
  for I:=1 to ComponentCount do
  begin
    Prims[I-1].SaveProperties(S);
    if AList=nil then
      WriteLn(F,S)
    else
      AList.Add(S);
  end;
end;

procedure TGraphPrimManager.SaveToList(AList: TStrings);
var
  F: TextFile;
begin
  SaveToListOrFile(AList,F);
end;

function TGraphPrimManager.SaveToFile(FileName: TFileName): Boolean;
var
  F: TextFile;
begin
  AssignFile(F,FileName);
  {$I-} Rewrite(F); {$I+}
  Result := IOResult=0;
  if Result then
  begin
    SaveToListOrFile(nil,F);
    Close(F);
  end
  else
    MessageBox(ParentWnd, PChar('Ошибка при сохранении ['+FileName+']'),
      'GraphPrimManager', MB_OK or MB_ICONERROR);
end;

function TGraphPrimManager.LoadFromListOrFile(AList: TStrings; var F: TextFile): Integer;
var
  I,J: Integer;
  S,ID: string;
  GPrim: TGraphPrim;
  EoR: Boolean;
begin
  Result := 0;
  I := 0;
  if AList=nil then
    EoR:=EoF(F)
  else
    EoR:=I >= AList.Count;
  while not EoR do
  begin
    if AList=nil then
      ReadLn(F,S)
    else
      S:=AList.Strings[I];
    if (Length(S)>0) and (S[1]<>';') then
    begin
      J:=Pos('(',S);
      if J>0 then
      begin
        ID := UpperCase(Copy(S,1,J-1));
        if ID=TGPLine.Ident then GPrim:=TGPLine.Create(Self) else
        if ID=TGPRect.Ident then GPrim:=TGPRect.Create(Self) else
        if ID=TGPEllipse.Ident then GPrim:=TGPEllipse.Create(Self) else
        if ID=TGPPolyLine.Ident then GPrim:=TGPPolyLine.Create(Self) else
        if ID=TGPArc.Ident then GPrim:=TGPArc.Create(Self) else
        if ID=TGPSetting.Ident then GPrim:=TGPSetting.Create(Self) else
        if ID=TGPParagraph.Ident then GPrim:=TGPParagraph.Create(Self) {else
        if ID=TGPTable.Ident then GPrim:=TGPTable.Create(Self)}
        else GPrim:=nil;
        if GPrim=nil then
          MessageBox(ParentWnd, PChar('Не могу создать графпримитив '+ID+'()'),
            'GraphPrimManager', MB_OK or MB_ICONERROR)
        else begin
          Inc(Result);
          GPrim.LoadProperties(Copy(S,J+1,Length(S)-J-1));
        end;
      end;
    end;
    Inc(I);
    if AList=nil then
      EoR:=EoF(F)
    else
      EoR:= I >= AList.Count;
  end;
end;

procedure TGraphPrimManager.LoadFromList(AList: TStrings);
var
  F: TextFile;
begin
  LoadFromListOrFile(AList,F);
end;

function TGraphPrimManager.LoadFromFile(FileName: TFileName): Boolean;
var
  F: TextFile;
begin
  AssignFile(F,FileName);
  FileMode := 0;
  {$I-} Reset(F); {$I+}
  Result:= IOResult=0;
  if Result then
  begin
    LoadFromListOrFile(nil,F);
    Close(F);
  end
  else
    MessageBox(ParentWnd, PChar('Ошибка чтения файла ['+FileName+']'), 'GraphPrimManager',
      MB_OK or MB_ICONERROR);
end;

procedure TGraphPrimManager.Draw(DC: HDC; AScaleX, AScaleY: Real; AWinOrigin: TPoint);
var
  Pen,Pen2: HPen;
  Brush,Brush2: HBrush;
  I: Integer;
  ALogPen: TLogPen;
begin
  GlobScale.X := AScaleX;
  GlobScale.Y := AScaleY;
  WinOrigin := AWinOrigin;

  ALogPen := LogPen;
  ALogPen.lopnWidth.X := VirtToViewX(ALogPen.lopnWidth.X) div 10;
  Pen2 := CreatePenIndirect(ALogPen); {CreatePen(PS_SOLID,3,clNavy)}
  Pen := SelectObject(DC,Pen2);

  Brush2 := CreateBrushIndirect(LogBrush);
  Brush := SelectObject(DC,Brush2);

  {SetBkColor(ADC,clRed);}
  SetBkMode(DC, TRANSPARENT);

  for I:=1 to ComponentCount do
    Prims[I-1].Draw(DC);

  SelectObject(DC,Brush);
  DeleteObject(Brush2);
  SelectObject(DC,Pen);
  DeleteObject(Pen2);
end;

function TGraphPrimManager.GetLimits: TRect;
var I: Integer;
    L: TRect;
begin
  Result := Rect(0,0,1,1);
  for I := 1 to ComponentCount do begin
    L := Prims[I-1].GetLimits;
    if Result.Left>L.Left then Result.Left := L.Left;
    if Result.Top>L.Top then Result.Top := L.Top;
    if Result.Right<L.Right then Result.Right := L.Right;
    if Result.Bottom<L.Bottom then Result.Bottom := L.Bottom;
  end;
end;

function TGraphPrimManager.InitForm(FormFile: TFileName;
  ADataSet: TDataSet): Boolean;
begin                             
  FDataSet := ADataSet;
  DestroyComponents;
  FormPageOrientation := pgoPortrait;
  Result := LoadFromFile(FormFile) and (ADataSet<>nil);
  if Result and (ComponentCount>0) and (Components[0] is TGPSetting) then
    try
      (Components[0] as TGPSetting).Draw(0);
    except
    end;
end;

constructor TPrintDBGrid.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FSheetWidth := 0;
  FSheetHeight := 0;
  FYCoord := 0;
  FSkipPage := 0;
  ResetSettings;
  FHeader := TGraphPrimManager.Create(Self);
  FFooter := TGraphPrimManager.Create(Self);
  FPager := TGraphPrimManager.Create(Self);
  FWidths := TList.Create;
end;

procedure TPrintDBGrid.ResetSettings;
begin
  with FLogPen do
  begin
    lopnStyle:=PS_SOLID;
    lopnWidth:=Point(1,0);
    lopnColor:=clBlack;
  end;
  with FLogBrush do
  begin
    lbStyle:=BS_NULL;
    lbColor:=clGreen;
    lbHatch:=HS_DIAGCROSS;
  end;
  with FLogFont do
  begin
    lfHeight:=35;
    lfWidth:=0;
    lfEscapement:=0;
    lfOrientation:=0;
    lfWeight:=FW_NORMAL;
    lfItalic:=0;
    lfUnderline:=0;
    lfStrikeOut:=0;
    lfCharSet:=ANSI_CHARSET;
    lfOutPrecision:=OUT_DEFAULT_PRECIS;
    lfClipPrecision := CLIP_DEFAULT_PRECIS;
    lfQuality := DEFAULT_QUALITY;
    lfPitchAndFamily := DEFAULT_PITCH;
    lfFaceName:='Courier';
  end;
  FRowFactor := 1.3;
  FTextAttr := DT_VCENTER or DT_SINGLELINE;
  FPageOrientation := pgoPortrait;
  FShowPagerOnFirstPage := False;
end;

destructor TPrintDBGrid.Destroy;
begin
  FWidths.Free;
  inherited Destroy;
end;

const
  ScreenDPI=72;
  MMPI=25.4;

procedure TPrintDBGrid.SetDBGrid(Value: TDBGrid);
var
  W: Integer;
begin
  FDBGrid := Value;
  FWidths.Clear;
  if Value<>nil then
  begin
    while FWidths.Count<DBGrid.Columns.Count do
    begin
      W := Round(FDBGrid.Columns.Items[FWidths.Count].Width/ScreenDPI*MMPI);
      FWidths.Add(Pointer(W));
    end;
  end;
end;

function TPrintDBGrid.LoadSetup: Boolean;
const
  CommonSectName='COMMON';
  ColumnsSectName='COLUMNS';
type
  TSectionType = (stCommon, stColumns, stUnknown);
var
  F: TextFile;
  SectType: TSectionType;
  S, SectName, ParamName, ParamValue: string;
  I, J, P, W: Integer;
  Fld: TField;
  D: Double;
begin
  AssignFile(F, SetupFileName);
  FileMode := 0;
  {$I-} Reset(F); {$I+}
  Result := IOResult=0;
  if Result then
  begin
    ResetSettings;
    SectType := stUnknown;
    while not EoF(F) do
    begin
      ReadLn(F, S);
      if Length(S)>1 then
      begin
        if S[1]='[' then
        begin
          SectName := UpperCase(Copy(S, 2, Pos(']',S)-2));
          if SectName=CommonSectName then
            SectType := stCommon
          else
            if SectName=ColumnsSectName then
            begin
              SectType := stColumns;
              {with DBGrid.Columns do
              begin
                State := csCustomized;
                for I:=1 to Count do Items[I-1].Visible:=False;
              end;}
            end
          else
            SectType := stUnknown;
        end
        else begin
          case SectType of
            stCommon:
              begin
                I := Pos('=',S);
                if I>0 then
                begin
                  ParamName := UpperCase(Copy(S, 1, I-1));
                  ParamValue := Copy(S, I+1, Length(S)-I);
                  if ParamName='HEADER' then
                  begin
                    Header.DestroyComponents;
                    Header.LoadFromFile(ExtractFilePath(SetupFileName)+ParamValue);
                  end
                  else
                  if ParamName='FOOTER' then
                  begin
                    Footer.DestroyComponents;
                    Footer.LoadFromFile(ExtractFilePath(SetupFileName)+ParamValue);
                  end
                  else
                  if ParamName='PAGER' then
                  begin
                    Pager.DestroyComponents;
                    if (Length(ParamValue)>0) and (ParamValue[1]='+') then
                    begin
                      FShowPagerOnFirstPage := True;
                      Delete(ParamValue, 1, 1);
                    end;
                    Pager.LoadFromFile(ExtractFilePath(SetupFileName)+ParamValue);
                  end
                  else
                  if ParamName='PEN' then
                  begin
                    StrToLogPen(ParamValue, FLogPen);
                  end
                  else
                  if ParamName='BRUSH' then
                  begin
                    StrToLogBrush(ParamValue, FLogBrush);
                  end
                  else
                  if ParamName='FONT' then
                  begin
                    StrToLogFont(ParamValue, FLogFont);
                  end
                  else
                  if ParamName='ORIENTATION' then
                  begin
                    ParamValue := UpperCase(Trim(ParamValue));
                    if ParamValue='PORTRAIT' then
                      PageOrientation := pgoPortrait
                    else
                    if ParamValue='LANDSCAPE' then
                      PageOrientation := pgoLandscape
                    {else
                      PageOrientation := pgoDefault};
                  end
                  else
                  if ParamName='ROWFACTOR' then
                  begin
                    Val(ParamValue, D, I);
                    if (I=0) and (D>0) then
                      RowFactor := D;
                  end
                  else
                  if ParamName='TEXTATTR' then
                  begin
                    Val(ParamValue, P, I);
                    if I=0 then
                      TextAttr := P;
                  end;
                end;
              end;
            stColumns:
              begin
                I := Pos('=',S);
                if I>0 then
                begin
                  ParamName := UpperCase(Copy(S, 1, I-1));
                  ParamValue := Copy(S, I+1, Length(S)-I);

                  I := 0;
                  while (I<DBGrid.FieldCount)
                    and (UpperCase(DBGrid.Fields[I].FieldName)<>ParamName) do Inc(I);

                  Fld:=DBGrid.DataSource.DataSet.Fields.FindField(ParamName);
                  if Fld<>nil then
                  with DBGrid.Columns do
                  begin
                    I := 0;
                    while (I<Count) and (Items[I].Field<>Fld) do Inc(I);
                    if I<Count then
                    begin
                      J := 0;
                      repeat
                        P := Pos(',',ParamValue);
                        if P>0 then
                        begin
                          S := Copy(ParamValue, 1, P-1);
                          System.Delete(ParamValue,1,P);
                        end
                        else begin
                          S := ParamValue;
                          ParamValue := '';
                        end;
                        case J of
                          0:
                            if Length(S)>0 then
                            begin
                              {V := S[1]<>'*';
                              if not V then Delete(S,1,1);
                              Items[I].Title.Caption:=S;
                              Items[I].Visible:=V;
                              Inc(LastColIndex);
                              Items[I].Index := LastColIndex;}
                            end;
                          1:
                            begin
                              Val(S,W,P);
                              if P=0 then
                                FWidths[I] := Pointer(W)
                              else
                                MessageBox(ParentWnd, PChar('Ширина колонки поля ['
                                  +ParamName+'] задана неверно'),
                                  'Загрузка настроек таблицы',
                                  MB_OK or MB_ICONWARNING);
                            end;
                        end;
                        Inc(J);
                      until Length(ParamValue)=0;
                    end
                    else
                      MessageBox(ParentWnd, PChar('Поле с именем '+ParamName
                        +' не найдено'), 'Загрузка настроек таблицы',
                        MB_OK or MB_ICONWARNING);
                  end;
                end;
              end;
          end;
        end;
      end;
    end;
    CloseFile(F);
  end
  else
    MessageBox(ParentWnd, PChar('Ошибка чтения файла ['+SetupFileName+']'),
      'PrintDBGrid', MB_OK or MB_ICONERROR);
end;

function TPrintDBGrid.GetWidth(Index: Integer): Integer;
begin
  Result := Integer(FWidths.Items[Index]);
end;

function TPrintDBGrid.GetGridWidth: Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 1 to DBGrid.Columns.Count do
    if DBGrid.Columns.Items[I-1].Visible then
      Result := Result + Widths[I-1];
end;

function TPrintDBGrid.GetLimits: TRect;
var L: TRect;
begin
  Result := Rect(0,0,1,1);

  L := Header.GetLimits;
  with Result do
  begin
    if Left>L.Left then
      Left := L.Left;
    if Top>L.Top then
      Top := L.Top;
    if Right<L.Right then
      Right := L.Right;
    if Bottom<L.Bottom then
      Bottom := L.Bottom;

    L := Rect(0, 0, GetGridWidth, SheetHeight);
    if Left>L.Left then
      Left := L.Left;
    if Top>L.Top then
      Top := L.Top;
    if Right<L.Right then
      Right := L.Right;
    if Bottom<L.Bottom then
      Bottom := L.Bottom;

    L := Footer.GetLimits;
    if Left>L.Left then
      Left := L.Left;
    if Top>L.Top then
      Top := L.Top;
    if Right<L.Right then
      Right := L.Right;
    if Bottom<L.Bottom then
      Bottom := L.Bottom;
  end;
end;

procedure TPrintDBGrid.DevideArea;
var
  I, H: Integer;
begin
  FHeaderLimits := Header.GetLimits;
  FFooterLimits := Footer.GetLimits;
  FPagerLimits := Pager.GetLimits;

  FRowOnPage1 := 0;
  FRowOnPage2 := 0;
  FRowOnPage3 := 0;
  FSkipPage := 0;

  I := -VirtToViewY(FLogFont.lfHeight) div 10;
  FRowHeight := Round(Abs(RowFactor*I));
  I := DBGrid.DataSource.DataSet.RecordCount;

  H := VirtToViewY(SheetHeight-FHeaderLimits.Bottom-FFooterLimits.Bottom) - YCoord;
  if H<0 then
  begin
    FSkipPage := 1;
    YCoord := 0;
    H := VirtToViewY(SheetHeight-FHeaderLimits.Bottom-FFooterLimits.Bottom) - YCoord;
  end;
  FRowOnPage1 := H div FRowHeight - 1;
  if FRowOnPage1<0 then
    FRowOnPage1 := 0;
  if FRowOnPage1>I then
    FRowOnPage1 := I;
  FPageCount := 1;
      {showmessage(inttostr(FRowOnPage1)+' '+inttostr(I));}
  if FRowOnPage1<I then
  begin
      {showmessage('11aa'+inttostr(FRowOnPage1)+' '+inttostr(I));}
    H := VirtToViewY(SheetHeight-FHeaderLimits.Bottom) - YCoord;
    FRowOnPage1 := H div FRowHeight - 1;
    if FRowOnPage1<0 then
      FRowOnPage1 := 0;
    if FRowOnPage1>I then
      FRowOnPage1 := I;
    H := VirtToViewY(SheetHeight-FPagerLimits.Bottom-FFooterLimits.Bottom);
    FRowOnPage2 := H div FRowHeight - 1;
    if FRowOnPage2<=0 then
      FRowOnPage2 := 1;
      {showmessage('1');}
    if FRowOnPage1+FRowOnPage2<I then
    begin
      H := VirtToViewY(SheetHeight-FPagerLimits.Bottom);
      FRowOnPage2 := H div FRowHeight - 1;
      if FRowOnPage2<=0 then
        FRowOnPage2 := 1;
      H := VirtToViewY(SheetHeight-FPagerLimits.Bottom-FFooterLimits.Bottom);
      FRowOnPage3 := H div FRowHeight - 1;
      FRowOnPage3 := I-FRowOnPage1-((I-FRowOnPage1-FRowOnPage3-1)
        div FRowOnPage2 + 1)*FRowOnPage2;
      if FRowOnPage3<=0 then
        FRowOnPage3 := 1;
    end
    else begin
      FRowOnPage2 := I-FRowOnPage1;
      {if FRowOnPage2<=0 then
        showmessage('!!'+IntToStr(FRowOnPage2));}
    end;
    H := I-FRowOnPage1;
    FLastGridBottom := VirtToViewY(FPagerLimits.Bottom + FFooterLimits.Bottom);
    if FRowOnPage3>0 then
    begin
      Inc(FPageCount);
      H := H-FRowOnPage3;
      FLastGridBottom := FLastGridBottom + FRowHeight*(FRowOnPage3+1);
    end
    else
      FLastGridBottom := FLastGridBottom + FRowHeight*(FRowOnPage2+1);
    if FRowOnPage2=0 then
      Inc(FPageCount)
    else begin
       {showmessage('!!'+IntToStr(I)+'!!'+IntToStr(FPageCount)+' ;'+IntToStr(FRowOnPage1)
        +'//'+IntToStr(FRowOnPage2)+'//'+IntToStr(FRowOnPage3)+'//'+IntToStr((H-1) div FRowOnPage2));}
      FPageCount := FPageCount + (H-1) div FRowOnPage2 + 1;
    end;
  end
  else begin
    FLastGridBottom := YCoord + FRowHeight*(FRowOnPage1+1)
      + VirtToViewY(FHeaderLimits.Bottom + FFooterLimits.Bottom);
  end; {showmessage('10');}
  FGridWidth := VirtToViewX(GetGridWidth);
  {if FSkipPage>0 then
    Inc(FPageCount);}
end;

procedure TPrintDBGrid.Draw(DC: HDC; AScaleX, AScaleY: Real; AWinOrigin: TPoint;
  APage: Integer);
const
  Alignments: array[TAlignment] of Word = (DT_LEFT, DT_RIGHT, DT_CENTER);
var
  CellRect, TextCellRect: TRect;
  Pen, Pen2: HPen;
  Brush, Brush2: HBrush;
  ALogPen: TLogPen;
  ALogFont: TLogFont;
  Font, Font2: HFONT;
  I, StartRow, EndRow, ARowCount, GridTop, X, dX, Y, ARow, ACol, GridBottom,
    XCellBorder, YCellBorder: Integer;
  Text: array[0..1023] of Char;
begin
  {DevideArea;}

  ALogPen := FLogPen;
  ALogPen.lopnWidth.X := VirtToViewX(ALogPen.lopnWidth.X) div 10;
  Pen2 := CreatePenIndirect(ALogPen);
  Pen := SelectObject(DC, Pen2);

  Brush2 := CreateBrushIndirect(FLogBrush);
  Brush := SelectObject(DC, Brush2);

  ALogFont := FLogFont;
  ALogFont.lfHeight := -VirtToViewY(ALogFont.lfHeight) div 10;
  Font2 := CreateFontIndirect(ALogFont);
  Font := SelectObject(DC, Font2);
  if APage=1 then
  begin
    AWinOrigin.Y := AWinOrigin.Y + YCoord;
    Header.LogPen := FLogPen;
    Header.Draw(DC, AScaleX, AScaleY, AWinOrigin);
    if FShowPagerOnFirstPage and (APage<PageCount) then
    begin
      Pager.LogPen := FLogPen;
      Pager.Draw(DC, AScaleX, AScaleY, Point(AWinOrigin.X+
        FGridWidth-VirtToViewX({FHeaderLimits.Right-}FPagerLimits.Right),
        AWinOrigin.Y+VirtToViewY(FHeaderLimits.Bottom-FPagerLimits.Bottom)));
    end;
    StartRow := 0;
    EndRow := StartRow + RowOnPage1;
    GridTop := AWinOrigin.Y + VirtToViewY(FHeaderLimits.Bottom);
  end
  else begin
    Pager.LogPen := FLogPen;
    {Pager.Draw(DC?, AScaleX, AScaleY, AWinOrigin);}
    Pager.Draw(DC, AScaleX, AScaleY, Point(AWinOrigin.X+
      FGridWidth-VirtToViewX({FHeaderLimits.Right-}FPagerLimits.Right),
      AWinOrigin.Y{+VirtToViewY(FHeaderLimits.Bottom-FPagerLimits.Bottom)}));
    StartRow := RowOnPage1 + (APage-2)*RowOnPage2;
    if (APage=PageCount) and (RowOnPage3>0) then
      EndRow := StartRow + RowOnPage3
    else
      EndRow := StartRow + RowOnPage2;
    GridTop := AWinOrigin.Y + VirtToViewY(FPagerLimits.Bottom);
  end;
  ARowCount := DBGrid.DataSource.DataSet.RecordCount;
  if EndRow>ARowCount then
  begin
    EndRow := ARowCount;
    if EndRow<StartRow then
      EndRow := StartRow;
  end;

  XCellBorder := VirtToViewX(TabCellMargin.X);
  YCellBorder := VirtToViewY(TabCellMargin.Y);

  with DBGrid.DataSource.DataSet do
  begin
    First;
    MoveBy(StartRow);
  end;
  Y := GridTop;
  ARow := StartRow-1;
  while ARow<EndRow do
  begin
    dX := 0;
    X := AWinOrigin.X;
    for ACol := 1 to DBGrid.Columns.Count do
    begin
      if DBGrid.Columns.Items[ACol-1].Visible then
      begin
        with CellRect do
        begin
          Top := Y;
          Bottom := Y+FRowHeight;
          Left := X;
          dX := dX + Widths[ACol-1];
          X := AWinOrigin.X + VirtToViewX(dX);
          Right := X;
        end;
        if ARow>=StartRow then
          StrPLCopy(@Text, DBGrid.Columns.Items[ACol-1].Field.DisplayText,
            SizeOf(Text))
        else
          StrPLCopy(@Text, DBGrid.Columns.Items[ACol-1].Title.Caption,
            SizeOf(Text));
        with TextCellRect do
        begin
          Left := CellRect.Left + XCellBorder;
          Top := CellRect.Top + YCellBorder;
          Right := CellRect.Right - XCellBorder;
          Bottom := CellRect.Bottom - YCellBorder;
        end;
        DrawText(DC, @Text, StrLen(Text), TextCellRect, FTextAttr
          or Alignments[DBGrid.Columns.Items[ACol-1].Alignment]);
      end;
    end;
    Y := CellRect.Bottom;
    if ARow>=StartRow then
    begin
      if not DBGrid.DataSource.DataSet.Eof then
      begin
        DBGrid.DataSource.DataSet.Next;
        DBGrid.DataSource.DataSet.UpdateCursorPos;
      end;
    end;
    Inc(ARow);
  end;
  GridBottom := Y;

  dX := 0;
  X := AWinOrigin.X;
  for ACol := 1 to DBGrid.Columns.Count do
    if DBGrid.Columns.Items[ACol-1].Visible then
    begin
      MoveToEx(DC, X, GridTop, nil);
      LineTo(DC, X, GridBottom);
      dX := dX + Widths[ACol-1];
      X := AWinOrigin.X + VirtToViewX(dX);
    end;
  Y := GridTop + FRowHeight;
  MoveToEx(DC, AWinOrigin.X, Y, nil);
  LineTo(DC, X, Y);
  CellRect := Rect(AWinOrigin.X, GridTop, X, GridBottom);
  CellRect := ExtRect(CellRect);
  Rectangle(DC, CellRect.Left, CellRect.Top, CellRect.Right, CellRect.Bottom);

  SelectObject(DC,Font);
  DeleteObject(Font2);
  SelectObject(DC,Brush);
  DeleteObject(Brush2);
  SelectObject(DC,Pen);
  DeleteObject(Pen2);

  if APage=PageCount then
  begin
    Footer.LogPen := FLogPen;
    Footer.Draw(DC, AScaleX, AScaleY, Point(AWinOrigin.X, GridBottom
      {AWinOrigin.Y+GridTop+GridHeight}));
  end;
end;

procedure TParagraph.Save(var F:Text);
begin
  WriteLn(F,'  2');
  WriteLn(F, DxfName);
end;

constructor TSection.Create(AnOwner: TComponent);
begin
  if AnOwner is TDraft then
    inherited Create(AnOwner)
  else
    ShowMessage('Владельцем секции должен быть чертеж TDraft!');
end;

{procedure TSection.Paint;
var I: Integer;
begin
  for I:=1 to ComponentCount do (Components[I-1] as TParagraph).Paint;
end;}

procedure TSection.Save(var F:Text);
var
  I: Word;
begin
  WriteLn(F,'  0');
  WriteLn(F,'SECTION');
  for I:=1 to ComponentCount do
    (Components[I-1] as TParagraph).Save(F);
  WriteLn(F,'  0');
  WriteLn(F,'ENDSEC');
end;

procedure TDraft.SetDraftScalePixOnCm(ScaleX,ScaleY: Real);
begin
  DraftScalePixOnCm.X:=ScaleX;
  DraftScalePixOnCm.Y:=ScaleY;
end;

procedure TDraft.SetDraftLimitsOnMM(LimX,LimY: Real);
begin
  DraftLimitsOnMM.X:=LimX;
  DraftLimitsOnMM.Y:=LimY;
end;

procedure TDraft.SetBaseCoord(X,Y,Z: Real);
begin
  BaseCoord := Coord(X,Y,Y);
end;

function TDraft.SaveToFile(FileName:string):Integer;
var I: Byte;
    F: Text;
begin
  System.Assign(F,FileName);
  {$I-} ReWrite(F); {$I+}
  Result := IOResult;
  if Result=0 then
  begin
    for I:=1 to ComponentCount do
      (Components[I-1] as TSection).Save(F);
    WriteLn(F,'  0');
    WriteLn(F,'EOF');
    System.Close(F);
  end;
end;


end.
