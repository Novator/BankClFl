unit ResendBillFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Mask, Buttons, CurrEdit, ToolEdit, ExtCtrls, WideComboBox, CommCons,
  Utilits, Spin, CheckLst, Basbn, BankCnBn, BUtilits, ComCtrls, ClntCons, BtrDS;

type
  TResendBillForm = class(TForm)
    OkBtn: TBitBtn;
    CancelBtn: TBitBtn;
    PageControl: TPageControl;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    CorrLabel: TLabel;
    RemLabel: TLabel;
    FromDate: TLabel;
    ToLabel: TLabel;
    NameLabel: TLabel;
    MaskLabel: TLabel;
    CorrWideComboBox: TWideComboBox;
    AccCheckListBox: TCheckListBox;
    AllAccCheckBox: TCheckBox;
    FromDateEdit: TDateEdit;
    ToDateEdit: TDateEdit;
    SearchIndexComboBox: TComboBox;
    MaskComboBox: TComboBox;
    JustOpenCheckBox: TCheckBox;
    SprCheckBox: TCheckBox;
    ResendCheckBox: TCheckBox;
    FileCheckBox: TCheckBox;
    BaseCheckBox: TCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure CorrWideComboBoxKeyPress(Sender: TObject; var Key: Char);
    procedure FormActivate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure CorrWideComboBoxClick(Sender: TObject);
    procedure AllAccCheckBoxClick(Sender: TObject);
    procedure FromDateEditAcceptDate(Sender: TObject; var ADate: TDateTime;
      var Action: Boolean);
    procedure SearchIndexComboBoxClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure MaskComboBoxChange(Sender: TObject);
    procedure MaskComboBoxExit(Sender: TObject);
    procedure MaskComboBoxKeyPress(Sender: TObject; var Key: Char);
    procedure FromDateEditChange(Sender: TObject);
    procedure BaseCheckBoxClick(Sender: TObject);
    procedure TabSheet2Show(Sender: TObject);
  private
    AccList: TAccList;
  public
    FNew: Boolean;
    FNewSend: Integer;
    procedure FillAccTable;
  end;

implementation

{$R *.DFM}

var
  AccDataSet: TExtBtrDataSet = nil;

type
  PAccInfoRec = ^TAccInfoRec;
  TAccInfoRec = record
    aiNumber: TAccount;
    aiName:   TKeeperName;
    aiIder:   Integer;
    aiDateO, aiDateC: Word;
  end;


procedure TResendBillForm.FormCreate(Sender: TObject);
begin
  AccList := TAccList.Create;
  AccDataSet := GlobalBase(biAcc);
end;

procedure TResendBillForm.CorrWideComboBoxKeyPress(Sender: TObject;
  var Key: Char);
begin
  Key := RusToLat(Key);
  if not ((Key in ['0'..'9', 'a'..'z', 'A'..'Z'])
    or (Key < #32)) then
  begin
    Key := #0;
    MessageBeep(0)
  end
  else
    Key := UpCase(Key);
end;

procedure TResendBillForm.FormActivate(Sender: TObject);
var
  E: Boolean;
  I: Integer;
begin
  JustOpenCheckBox.Enabled := (FromDateEdit.Date>0) and (ToDateEdit.Date>0);
  if not JustOpenCheckBox.Enabled then
    JustOpenCheckBox.Checked := False;
  E := (CorrWideComboBox.ItemIndex>=0) and JustOpenCheckBox.Enabled
    and (FromDateEdit.Date<=ToDateEdit.Date);
  if E then
  begin
    I := AccCheckListBox.Items.Count-1;
    while (I>=0) and not AccCheckListBox.Checked[I] do
      Dec(I);
    E := I>=0;
  end;
  ResendCheckBox.Enabled := E;
  BaseCheckBoxClick(nil);
end;

procedure TResendBillForm.FormShow(Sender: TObject);
begin
  FillCorrList(CorrWideComboBox.Items);
  CorrWideComboBoxClick(nil);
end;

procedure TResendBillForm.CorrWideComboBoxClick(Sender: TObject);
var
  Corr, Res, Len, C: Integer;
  AccRec: TAccRec;
  P: PAccInfoRec;
begin
  RemLabel.Visible := True;
  FromDateEdit.Visible := not RemLabel.Visible;
  FromDate.Visible := not RemLabel.Visible;
  ToDateEdit.Visible := not RemLabel.Visible;
  ToLabel.Visible := not RemLabel.Visible;
  JustOpenCheckBox.Enabled := False;

  RemLabel.Caption := '';
  AllAccCheckBox.Enabled := False;
  AllAccCheckBox.Checked := False;
  OkBtn.Enabled := False;
  AccCheckListBox.Items.Clear;
  AccList.Clear;
  if CorrWideComboBox.ItemIndex>=0 then
  begin
    if AccDataSet<>nil then
    begin
      Corr := Integer(CorrWideComboBox.Items.Objects[CorrWideComboBox.ItemIndex]);
      if Corr>0 then
      begin
        C := Corr;
        Len := SizeOf(AccRec);
        Res := AccDataSet.BtrBase.GetGE(AccRec, Len, C, 2);
        if Res=0 then
        begin
          while (Res=0) and (Corr=C) do
          begin
            New(P);
            with P^ do
            begin
              aiNumber := AccRec.arAccount;
              aiName := AccRec.arName;
              aiIder := AccRec.arIder;
              aiDateO := AccRec.arDateO;
              aiDateC := AccRec.arDateC;
            end;
            AccList.Add(P);
            Len := SizeOf(AccRec);
            Res := AccDataSet.BtrBase.GetNext(AccRec, Len, C, 2);
          end;
        end;
        if AccList.Count>0 then
        begin
          JustOpenCheckBox.Checked := False;
          SearchIndexComboBoxClick(nil);
          AllAccCheckBox.Enabled := True;
          RemLabel.Visible := False;
          FromDateEdit.Visible := not RemLabel.Visible;
          FromDate.Visible := not RemLabel.Visible;
          ToDateEdit.Visible := not RemLabel.Visible;
          ToLabel.Visible := not RemLabel.Visible;
        end
        else
          RemLabel.Caption := 'Нет счетов';
      end
      else
        RemLabel.Caption := 'Нет идентификатора';
    end
    else
      RemLabel.Caption := 'База счетов закрыта';
  end;
end;

procedure TResendBillForm.AllAccCheckBoxClick(Sender: TObject);
var
  I: Integer;
begin
  AccCheckListBox.Enabled := not AllAccCheckBox.Checked;
  AccCheckListBox.ParentColor := AllAccCheckBox.Checked;
  if not AccCheckListBox.ParentColor then
    AccCheckListBox.Color := clWindow;
  if AllAccCheckBox.Checked then
    for I := 0 to AccCheckListBox.Items.Count-1 do
      AccCheckListBox.Checked[I] := True;
  FormActivate(nil);
end;

procedure TResendBillForm.FromDateEditAcceptDate(Sender: TObject;
  var ADate: TDateTime; var Action: Boolean);
begin
  ToDateEdit.Date := ADate;
end;

const
  SortIndex: Integer = 0;

function AccInfoCompare(Key1, Key2: Pointer): Integer;
var
  k1: PAccInfoRec absolute Key1;
  k2: PAccInfoRec absolute Key2;
begin
  Result := 0;
  case SortIndex of
    1:
      Result := CompareResortedAcc(k1^.aiNumber, k2^.aiNumber);
    else
      begin
        if k1^.aiNumber<k2^.aiNumber then
          Result := -1
        else
          if k1^.aiNumber>k2^.aiNumber then
            Result := 1;
      end;
  end;
end;

var
  MaskChanged: Boolean = True;

procedure TResendBillForm.FillAccTable;
var
  d1, d2: Word;
  FullMask: Boolean;
  I: Integer;
  PAccInfo: PAccInfoRec;
  Buf: array[0..127] of Char;
  S: string;
begin
  if JustOpenCheckBox.Checked then
  begin
    try
      d1 := DateToBtrDate(FromDateEdit.Date);
    except
      d1 := 0;
    end;
    try
      d2 := DateToBtrDate(ToDateEdit.Date);
      if d2=0 then
        d2 := $FFFF;
    except
      d2 := $FFFF;
    end;
  end;
  while Length(MaskComboBox.Text)<SizeOf(TAccount) do
    MaskComboBox.Text := MaskComboBox.Text + '?';
  for I := 0 to AccList.Count-1 do
  begin
    PAccInfo := AccList.Items[I];
    with PAccInfo^ do
    begin
      if (FullMask or Masked(aiNumber, MaskComboBox.Text))
        and (not JustOpenCheckBox.Checked or
        (aiDateO<d2) and ((aiDateC=0) or (d1<=aiDateC))) then
      begin
        StrLCopy(Buf, aiNumber, SizeOf(aiNumber));
        S := StrPas(Buf);
        StrLCopy(Buf, aiName, SizeOf(aiName));
        DosToWin(Buf);
        S := S+' | '+StrPas(Buf);
        AccCheckListBox.Items.AddObject(S, TObject(aiIder));
      end;
    end;
  end;
  MaskChanged := False;
end;

procedure TResendBillForm.SearchIndexComboBoxClick(Sender: TObject);
begin
  AccCheckListBox.Items.Clear;
  MaskComboBox.Enabled := False;
  if SearchIndexComboBox.Enabled then
  begin
    if SearchIndexComboBox.ItemIndex<0 then
      SearchIndexComboBox.ItemIndex := 0;
    Screen.Cursor := crHourGlass;
    try
      SortIndex := SearchIndexComboBox.ItemIndex;
      Application.ProcessMessages;
      AccList.Sort(AccInfoCompare);
      FillAccTable;
      AllAccCheckBoxClick(nil);
      MaskComboBox.Enabled := True;
    finally
      Screen.Cursor := crDefault;
    end;
  end;
end;

procedure TResendBillForm.FormDestroy(Sender: TObject);
begin
  AccList.Free;
end;

procedure TResendBillForm.MaskComboBoxChange(Sender: TObject);
begin
  MaskChanged := True;
end;

procedure TResendBillForm.MaskComboBoxExit(Sender: TObject);
begin
  if MaskChanged then
  begin
    MaskChanged := False;
    SearchIndexComboBoxClick(nil);
  end;
end;

procedure TResendBillForm.MaskComboBoxKeyPress(Sender: TObject;
  var Key: Char);
begin
  if not ((Key in ['0'..'9','?']) or (Key < #32)) then
  begin
    Key := #0;
    MessageBeep(0)
  end;
end;

procedure TResendBillForm.FromDateEditChange(Sender: TObject);
begin
  JustOpenCheckBox.Checked := False;
  FormActivate(Sender);
end;

procedure TResendBillForm.BaseCheckBoxClick(Sender: TObject);
begin
  OkBtn.Enabled := BaseCheckBox.Checked or SprCheckBox.Checked
    or FileCheckBox.Checked or ResendCheckBox.Checked;
end;

procedure TResendBillForm.TabSheet2Show(Sender: TObject);
begin
  CorrWideComboBox.DroppedWidth := 270;
end;

end.
