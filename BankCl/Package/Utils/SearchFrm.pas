unit SearchFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons, ExtCtrls, ComCtrls, DBGrids, Utilits;

type
  TSearchForm = class(TForm)
    ScrollBox: TScrollBox;
    StatusBar: TStatusBar;
    BtnPanel: TPanel;
    OkBtn: TBitBtn;
    CancelBtn: TBitBtn;
    ProgressBar: TProgressBar;
    ModeComboBox: TComboBox;
    CaseSensCheckBox: TCheckBox;
    BeginRadioButton: TRadioButton;
    EndRadioButton: TRadioButton;
    procedure OkBtnClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure BtnPanelResize(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    FSourceDBGrid: TDBGrid;
    FControlIsInited: Boolean;
  protected
    procedure SetSourceDBGrid(ASourceDBGrid: TDBGrid);
    procedure InitControls;
  public
    property ControlIsInited: Boolean read FControlIsInited default False;
    property SourceDBGrid: TDBGrid read FSourceDBGrid write SetSourceDBGrid;
    procedure ClickCheckBox(Sender: TObject);
    procedure ChangeEdit(Sender: TObject);
  end;

implementation

{$R *.DFM}

procedure TSearchForm.InitControls;
var
  I,Y,W: Integer;
  CB: TCheckBox;
  E: TEdit;
  T: array[0..255] of Char;
  S: TSize;
begin
  if not FControlIsInited
    and (FSourceDBGrid <> nil)
    and (FSourceDBGrid.DataSource<>nil)
    and (FSourceDBGrid.DataSource.DataSet<>nil)
    and FSourceDBGrid.DataSource.DataSet.Active then
  begin
    I:=ControlCount;
    while I>0 do
    begin
      Dec(I);
      if (Controls[I] is TEdit) or (Controls[I] is TCheckBox)
      then Controls[I].Free;
    end;
    with FSourceDBGrid.Columns do
    begin
      Y:=8;
      for I:=1 to Count do
      begin
        CB:=TCheckBox.Create(ScrollBox);
        with CB do
        begin
          Caption:=Items[I-1].Title.Caption;
          StrPCopy(T,Caption);
          GetTextExtentPoint32(Canvas.Handle,T,StrLen(T),S);
          SetBounds(17,Y,S.CX+24,Abs(CB.Font.Height)+2);
          OnClick:=ClickCheckBox;
          Parent:=ScrollBox;
          Tag:=Items[I-1].Field.Index;
          Show;
          Y:=Y+Height+2;
        end;
        E:=TEdit.Create(CB);
        with E do
        begin
          W:=Items[I-1].Width+40;
          if W<100 then W:=100;
          SetBounds(17,Y,W,Abs(E.Font.Height)+2);
          OnChange:=ChangeEdit;
          Parent:=ScrollBox;
          Show;
          Y:=Y+Height+5;
        end;
      end;
    end;
    FControlIsInited := True;
  end;
end;

procedure TSearchForm.SetSourceDBGrid(ASourceDBGrid: TDBGrid);
begin
  FSourceDBGrid := ASourceDBGrid;
  InitControls;
end;

procedure TSearchForm.ClickCheckBox(Sender: TObject);
var
  I: Integer;
begin
  with ScrollBox do begin
    I:=ComponentCount-1;
    while (I>=0) and not((Components[I] is TCheckBox)
      and (Components[I] as TCheckBox).Checked) do Dec(I);
  end;
  OkBtn.Enabled:= I>=0;
end;

procedure TSearchForm.ChangeEdit(Sender: TObject);
begin
  if Sender is TEdit then with Sender as TEdit do
    if Owner is TCheckBox then (Owner as TCheckBox).Checked:=Length(Text)>0;
end;

procedure TSearchForm.OkBtnClick(Sender: TObject);
var
  CB: TCheckBox;
  I,J,K: Integer;
  S, S2: string;
begin
  CancelBtn.Enabled:= not CancelBtn.Enabled;
  if not CancelBtn.Enabled then
  with SourceDBGrid.DataSource.DataSet do
  begin
    OkBtn.Caption := '&Стоп';
    K := 0;
    ProgressBar.Max := RecordCount;
    StatusBar.Panels[0].Width := ProgressBar.Width;
    ProgressBar.Show;
    if BeginRadioButton.Checked and Eof then                 //Изменено Меркуловым
      First;
    if EndRadioButton.Checked and BoF then
      Last;
    //while not EoF and (K=0) and not CancelBtn.Enabled
    //  and not BoF do                                       //Изменено Меркуловым
    repeat
    //begin
      if BeginRadioButton.Checked then                       //Добавлено Меркуловым
        Next
      else if EndRadioButton.Checked then                    //Добавлено Меркуловым
        Prior;                                               //Добавлено Меркуловым
      with ScrollBox do
      begin
        I := ComponentCount-1; K:=1;
        while (I>=0) and (K<>0) do
        begin
          CB := Components[I] as TCheckBox;
          if CB.Checked then
          begin
            J := CB.Tag;
            S := (CB.Components[0] as TEdit).Text;
            S2 := Fields.Fields[J].AsString;
            if not CaseSensCheckBox.Checked then
            begin
              S := RusUpperCase(S);
              S2 := RusUpperCase(S2);
            end;
            case ModeComboBox.ItemIndex of
              0:
                K := Pos(S, S2);
              1:
                begin
                  K := Length(S);
                  if K<=Length(S2) then
                  begin
                    if StrLComp(PChar(S), PChar(S2), K)<>0 then K:=0;
                  end
                  else K := 0;
                end;
              else
                begin
                  K := Length(S);
                  if K=Length(S2) then
                  begin
                    if StrLComp(PChar(S), PChar(S2), K)=0 then
                      K:=1
                    else
                      K:=0;
                  end
                  else K := 0;
                end;
            end;
          end;
          Dec(I);
        end;
      end;
      ProgressBar.Position:=RecNo;
      Application.ProcessMessages;
    //end;
    until EoF or (K<>0) or CancelBtn.Enabled or BoF;
    ProgressBar.Hide;
    StatusBar.Panels[0].Width := 0;
    CancelBtn.Enabled:= True;
    OkBtn.Caption:='&Найти';
    {if K<>0 then
    begin
      LastRadioButton.Checked := True;   //Изменено
      //BeginCheckBox.Checked := False;
      Self.Close;
    end
    else
      BeginRadioCheckBox.Checked := EoF;}  //Изменено
  end;
end;

procedure TSearchForm.FormShow(Sender: TObject);
begin
  InitControls;
  ClickCheckBox(Sender);
end;

const
  BtrDist=5;

procedure TSearchForm.BtnPanelResize(Sender: TObject);
begin
  CancelBtn.Left := BtnPanel.ClientWidth-CancelBtn.Width-2*BtrDist;
  OkBtn.Left:= CancelBtn.Left-OkBtn.Width-BtrDist;
end;

procedure TSearchForm.FormCreate(Sender: TObject);
const
  Border=2;
begin
  with ProgressBar do
  begin
    Parent := StatusBar;
    SetBounds(0, Border, Width, StatusBar.Height - Border);
  end;
  ModeComboBox.ItemIndex := 2;
  BtnPanelResize(Sender);
end;

end.
