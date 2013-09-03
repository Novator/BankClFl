unit AccountFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Mask, Buttons, CurrEdit, ToolEdit, ExtCtrls, WideComboBox,
  Utilits, Spin, {Quorum,} DBTables,
  Orakle;                                        //Добавлено Меркуловым

type
  TAccountForm = class(TForm)
    AccEdit: TMaskEdit;
    AccLabel: TLabel;
    OkBtn: TBitBtn;
    CancelBtn: TBitBtn;
    NameLabel: TLabel;
    OpenDateEdit: TDateEdit;
    StartSumCalcEdit: TRxCalcEdit;
    StartSumLabel: TLabel;
    OpenDateLabel: TLabel;
    CorrLabel: TLabel;
    NameEdit: TEdit;
    CurSumLabel: TLabel;
    CurSumCalcEdit: TRxCalcEdit;
    CloseDateLabel: TLabel;
    CloseDateEdit: TDateEdit;
    KindRadioGroup: TRadioGroup;
    CorrWideComboBox: TWideComboBox;
    MailPanel: TPanel;
    ClLockCheckBox: TCheckBox;
    BevelPanel: TPanel;
    SendRadioGroup: TRadioGroup;
    NewSendEdit: TEdit;
    NewSendLabel: TLabel;
    VerSpinEdit: TSpinEdit;
    VerLabel: TLabel;
    ClientPanel: TPanel;
    NewLabel: TLabel;
    procedure BikEditKeyPress(Sender: TObject; var Key: Char);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure CorrWideComboBoxKeyPress(Sender: TObject; var Key: Char);
    procedure CurSumCalcEditChange(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure MailPanelClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure SendRadioGroupClick(Sender: TObject);
    procedure ClientPanelClick(Sender: TObject);
    procedure ClientPanelMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure ClientPanelMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
  private
  public
    FNew: Boolean;
    FNewSend: Integer;
  end;

var
  AccountForm: TAccountForm;

implementation

uses AccountsFrm;

{$R *.DFM}

procedure TAccountForm.BikEditKeyPress(Sender: TObject; var Key: Char);
begin
  if not ((Key in ['0'..'9']) or (Key < #32)) then
  begin
    Key := #0;
    MessageBeep(0)
  end;
end;

var
  QrmIsOpen: Boolean;

procedure TAccountForm.FormCreate(Sender: TObject);
begin
  FNew := False;
  {CorrWideComboBox.Items.Clear;
  CorrWideComboBox.Items.Assign(AccountsForm.CorrListComboBox.Items);}
  CorrWideComboBox.Items := AccountsForm.CorrListComboBox.Items;
  CorrWideComboBox.DroppedWidth := 270;
  MailPanelClick(nil);
  if OraBase.OrBaseConn then                      //Добавлено Меркуловым
    QrmIsOpen := OrBasesIsOpen            //Добавлено Меркуловым
  {else                                    //Добавлено Меркуловым
    QrmIsOpen := QrmBasesIsOpen};
end;

procedure TAccountForm.CorrWideComboBoxKeyPress(Sender: TObject;
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

procedure TAccountForm.CurSumCalcEditChange(Sender: TObject);
begin
  if FNew then
    StartSumCalcEdit.Value := CurSumCalcEdit.Value;
end;

procedure TAccountForm.FormShow(Sender: TObject);
begin
  if FNew then
  begin
    CloseDateEdit.Enabled := False;
    CloseDateEdit.ParentColor := True;
    NewLabel.Show;
  end;
  FNewSend := 1;
  NewSendEdit.Text := SendRadioGroup.Items.Strings[FNewSend];
end;

procedure TAccountForm.FormActivate(Sender: TObject);
var
  B: Boolean;
begin
  OkBtn.Enabled := (CorrWideComboBox.ItemIndex>=0)
    and (KindRadioGroup.ItemIndex>=0) and (Length(NameEdit.Text)>0)
    and (Length(AccEdit.Text)>0);
  B := QrmIsOpen and (Length(AccEdit.Text)=20);
  if B<>ClientPanel.Enabled then
  begin
    ClientPanel.Enabled := B;
    if B then
      ClientPanel.Font.Color := clWindowText
    else
      ClientPanel.Font.Color := clGrayText;
  end;
end;

procedure TAccountForm.MailPanelClick(Sender: TObject);
begin
  if MailPanel.BevelOuter = bvRaised then
  begin
    MailPanel.BevelOuter := bvLowered;
    BevelPanel.Visible := True;
    ClientHeight := BevelPanel.Top + BevelPanel.Height;
  end
  else begin
    MailPanel.BevelOuter := bvRaised;
    BevelPanel.Visible := False;
    ClientHeight := MailPanel.Top + MailPanel.Height;
  end;
end;

procedure TAccountForm.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  case Key of
    VK_F2:
      MailPanelClick(nil);
    VK_F5:
      ClientPanelClick(nil);
    Ord('V'):
      if ssAlt in Shift then
        MailPanelClick(nil);
    VK_F9:
      NewLabel.Visible := not NewLabel.Visible;
  end;
end;

procedure TAccountForm.SendRadioGroupClick(Sender: TObject);
begin
  FNewSend := SendRadioGroup.ItemIndex;
  NewSendEdit.Text := SendRadioGroup.Items.Strings[FNewSend];
end;

procedure TAccountForm.ClientPanelClick(Sender: TObject);
const
  MesTitle: PChar = 'Поиск клиента';
var
  NewAcc, ClientInn, ClientName: ShortString;
  AccNum: string[10];
  CurrCode: string[3];
  UserCodeLocal: Integer;
  Sum: Double;
  Mes: string;
  Check:Boolean;                                 //Добавлено Меркуловым
  S: string;
  D: Double;

  procedure AddMes(S: string);
  begin
    if Length(Mes)>0 then
      Mes := Mes + #13#10;
    Mes := Mes + S;
  end;

begin
  if not ClientPanel.Enabled then
    Exit;
  NewAcc := AccEdit.Text;
  Mes := '';
  //Добавлено Меркуловым
  if OraBase.OrBaseConn then
    Check := OrGetAccAndCurrByNewAcc(NewAcc, AccNum, CurrCode, UserCodeLocal)
  {else Check := GetAccAndCurrByNewAcc(NewAcc, AccNum, CurrCode, UserCodeLocal)};
  //Конец
  if Check then
  begin
    //Добавлено Меркуловым
    if OraBase.OrBaseConn then
      Check := OrGetClientByAcc(AccNum, CurrCode, ClientInn, ClientName, NewAcc, S)
    {else
      Check := GetClientByAcc(AccNum, CurrCode, ClientInn, ClientName, NewAcc)};
    //Конец
    if Check then
    begin
      DosToWinL(@ClientName, Length(ClientName));
      NameEdit.Text := RusUpperCase(ClientName);
    end
    else
      Mes := 'Клиент не найден в справочнике АБС';
    //Добавлено Меркуловым
    if OraBase.OrBaseConn then
    begin
      if NewLabel.Visible then
        D := 1.0
      else
        D := 0.0;
      Check := OrGetLimByAccAndDate(AccNum, CurrCode, DateToDosDate(Date-D), Sum);
    end;
    {else
      Check := GetLimByAccAndDate(AccNum, CurrCode, DateToDosDate(Date), Sum)};
    //Конец
    if Check then
      CurSumCalcEdit.Value := Sum
    else
      AddMes('Текущий остаток не найден в АБС');
    if OpenDateEdit.Date<>0 then
    begin
      //Добавлено Меркуловым
      if OraBase.OrBaseConn then
        Check := OrGetLimByAccAndDate(AccNum, CurrCode, DateToDosDate(
          OpenDateEdit.Date), Sum)
      {else
        Check := GetLimByAccAndDate(AccNum, CurrCode, DateToDosDate(
          OpenDateEdit.Date), Sum)};
      //Конец
      if Check then
        StartSumCalcEdit.Value := Sum
      else
        AddMes('Начальный остаток не найден в АБС');
    end;
  end
  else
    Mes := 'Счет ['+AccEdit.Text+'] не найден в АБС';
  if Length(Mes)>0 then
    MessageBox(Handle, PChar(Mes), MesTitle, MB_OK or MB_ICONWARNING);
end;

procedure TAccountForm.ClientPanelMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbLeft then (Sender as TPanel).BevelOuter := bvLowered;
end;

procedure TAccountForm.ClientPanelMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  with (Sender as TPanel) do
    if BevelOuter = bvLowered then BevelOuter := bvRaised;
end;

end.
