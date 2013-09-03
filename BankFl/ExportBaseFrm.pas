unit ExportBaseFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons, ExtCtrls, ComCtrls, DBGrids, Utilits, Db, Mask,
  ToolEdit;

type
  TExportBaseForm = class(TForm)
    ScrollBox: TScrollBox;
    StatusBar: TStatusBar;
    BtnPanel: TPanel;
    OkBtn: TBitBtn;
    CancelBtn: TBitBtn;
    ProgressBar: TProgressBar;
    BeginCheckBox: TCheckBox;
    BrokerComboBox: TComboBox;
    FixedCheckBox: TCheckBox;
    BrokerCheckBox: TCheckBox;
    FilenameEdit: TFilenameEdit;
    FileNameLabel: TLabel;
    TrimCheckBox: TCheckBox;
    procedure OkBtnClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure BtnPanelResize(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure BrokerComboBoxChange(Sender: TObject);
    procedure BrokerCheckBoxClick(Sender: TObject);
    procedure FilenameEditChange(Sender: TObject);
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
  end;

implementation

{$R *.DFM}

function FieldLength(F: TField): Integer;
begin
  case F.DataType of
    ftBoolean:
      Result := 1;
    ftSmallInt:
      Result := 4;
    ftWord:
      Result := 5;
    ftDate:
      Result := 10;
    ftInteger:
      Result := 11;
    ftFloat:
      Result := 20;
    else
      Result := F.DataSize;
  end;
end;

procedure TExportBaseForm.InitControls;
var
  I,Y: Integer;
  CB: TCheckBox;
  T: array[0..255] of Char;
  S: TSize;
begin
  if not FControlIsInited
    and (FSourceDBGrid <> nil)
    and (FSourceDBGrid.DataSource<>nil)
    and (FSourceDBGrid.DataSource.DataSet<>nil)
    and FSourceDBGrid.DataSource.DataSet.Active then
  begin
    I := ControlCount;
    while I>0 do
    begin
      Dec(I);
      if (Controls[I] is TEdit) or (Controls[I] is TCheckBox) then
        Controls[I].Free;
    end;
    with FSourceDBGrid.Columns do
    begin
      Y := 8;
      for I := 1 to Count do
      begin
        CB := TCheckBox.Create(ScrollBox);
        with CB do
        begin
          Caption := Items[I-1].Title.Caption;
          StrPCopy(T, Caption);
          GetTextExtentPoint32(Canvas.Handle, T, StrLen(T), S);
          SetBounds(17, Y, S.CX+24, Abs(CB.Font.Height)+2);
          OnClick := ClickCheckBox;
          Parent := ScrollBox;
          Tag := Items[I-1].Field.Index;
          Show;
          Y := Y+Height+2;
        end;
      end;
    end;
    FControlIsInited := True;
  end;
end;

procedure TExportBaseForm.SetSourceDBGrid(ASourceDBGrid: TDBGrid);
begin
  FSourceDBGrid := ASourceDBGrid;
  InitControls;
end;

var
  Broker: string = ';';

procedure TExportBaseForm.ClickCheckBox(Sender: TObject);
var
  I: Integer;
begin
  with ScrollBox do begin
    I := ComponentCount-1;
    while (I>=0) and not((Components[I] is TCheckBox)
      and (Components[I] as TCheckBox).Checked) do Dec(I);
  end;
  OkBtn.Enabled := (I>=0) and (Length(FilenameEdit.Text)>0) ;
end;

procedure TExportBaseForm.OkBtnClick(Sender: TObject);
var
  CB: TCheckBox;
  I,J: Integer;
  S, V: string;
  F: TField;
  TF: TextFile;
begin
  CancelBtn.Enabled := not CancelBtn.Enabled;
  if not CancelBtn.Enabled then
  with SourceDBGrid.DataSource.DataSet do
  begin
    OkBtn.Caption := '&Стоп';
    ProgressBar.Max := RecordCount;
    StatusBar.Panels[0].Width := ProgressBar.Width;
    ProgressBar.Show;
    if BeginCheckBox.Checked then
      First;
    AssignFile(TF, FilenameEdit.Text);
    {$I-} Rewrite(TF); {$I+}
    if IOResult=0 then
    begin
      with ScrollBox do
      begin
        S := '';
        for I := 0 to ComponentCount-1 do
        begin
          CB := Components[I] as TCheckBox;
          if CB.Checked then
          begin
            if Length(S)>0 then
              S := S + ';';
            S := S + CB.Caption;
          end;
        end;
      end;
      WriteLn(TF, S);
      Self.SourceDBGrid.DataSource.Enabled := False;
      while not EoF and not CancelBtn.Enabled do
      begin
        with ScrollBox do
        begin
          S := '';
          I := 0;
          while (I<ComponentCount) and not CancelBtn.Enabled do
          begin
            CB := Components[I] as TCheckBox;
            if CB.Checked then
            begin
              J := CB.Tag;
              F := Fields.Fields[J];
              V := F.AsString;
              if TrimCheckBox.Checked then
              begin
                J := Pos(#13#10, V);
                while J>0 do
                begin
                  V := Copy(V, 1, J-1)+' '+Copy(V, J+2, Length(V)-J-1);
                  J := Pos(#13#10, V);
                end;
                V := Trim(V);
              end;
              if FixedCheckBox.Checked then
              begin
                J := FieldLength(F);
                while Length(V)<J do
                  V := V + ' ';
              end;
              if (Length(Broker)>0) and (Length(S)>0) then
              begin
                S := S + Broker;
              end;
              S := S + V;
            end;
            Inc(I);
          end;
          WriteLn(TF, S);
        end;
        Next;
        ProgressBar.Position := RecNo;
        Application.ProcessMessages;
      end;
      CloseFile(TF);
      Self.SourceDBGrid.DataSource.Enabled := True;
      MessageBox(Handle, PChar('Файл заполнен ['+FilenameEdit.Text+']'),
        PChar(Caption), MB_OK or MB_ICONINFORMATION);
    end
    else
      MessageBox(Handle, PChar('Не могу создать ['+FilenameEdit.Text+']'),
        PChar(Caption), MB_OK or MB_ICONWARNING);
    ProgressBar.Hide;
    StatusBar.Panels[0].Width := 0;
    CancelBtn.Enabled := True;
    OkBtn.Caption := '&Найти';
  end;
end;

procedure TExportBaseForm.FormShow(Sender: TObject);
begin
  InitControls;
  ClickCheckBox(Sender);
end;

const
  BtrDist=5;

procedure TExportBaseForm.BtnPanelResize(Sender: TObject);
begin
  CancelBtn.Left := BtnPanel.ClientWidth-CancelBtn.Width-2*BtrDist;
  OkBtn.Left:= CancelBtn.Left-OkBtn.Width-BtrDist;
end;

procedure TExportBaseForm.FormCreate(Sender: TObject);
const
  Border=2;
begin
  with ProgressBar do
  begin
    Parent := StatusBar;
    SetBounds(0, Border, Width, StatusBar.Height - Border);
  end;
  BtnPanelResize(Sender);
  BrokerComboBox.ItemIndex := 0;
end;

procedure TExportBaseForm.BrokerComboBoxChange(Sender: TObject);
begin
  if UpperCase(BrokerComboBox.Text)='TAB' then
    Broker := #9
  else
  if UpperCase(BrokerComboBox.Text)='SPACE' then
    Broker := ' '
  else
    Broker := BrokerComboBox.Text;
end;

procedure TExportBaseForm.BrokerCheckBoxClick(Sender: TObject);
begin
  BrokerComboBox.Enabled := BrokerCheckBox.Checked;
  if BrokerComboBox.Enabled then
    BrokerComboBoxChange(nil)
  else
    Broker := '';
end;

procedure TExportBaseForm.FilenameEditChange(Sender: TObject);
begin
  ClickCheckBox(nil);
end;

end.
