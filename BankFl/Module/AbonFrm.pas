unit AbonFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons, Mask, ExtCtrls, Basbn, Registr, Common, CommCons,
  Utilits, BankCnBn, Orakle;

type
  TAbonForm = class(TForm)
    NameLabel: TLabel;
    OkBtn: TBitBtn;
    CancelBtn: TBitBtn;
    NameEdit: TEdit;
    LoginEdit: TEdit;
    LoginLabel: TLabel;
    LockGroupBox: TGroupBox;
    SendLockCheckBox: TCheckBox;
    RecieveLockCheckBox: TCheckBox;
    SizeLabel: TLabel;
    SizeComboBox: TComboBox;
    WayLabel: TLabel;
    WayComboBox: TComboBox;
    CryptLabel: TLabel;
    CryptComboBox: TComboBox;
    ControlLabel: TLabel;
    ControlComboBox: TComboBox;
    AbonIdGroupBox: TGroupBox;
    HardIdLabel: TLabel;
    LastIdLabel: TLabel;
    LastIdEdit: TEdit;
    HardIdEdit: TEdit;
    HexPanel: TPanel;
    ObsolveGroupBox: TGroupBox;
    LoginOldEdit: TEdit;
    LoginOldLabel: TLabel;
    NodeLabel: TLabel;
    NodeEdit: TEdit;
    ChangeIdLabel: TLabel;
    StatusLabel: TLabel;
    StatusComboBox: TComboBox;
    TraceCheckBox: TCheckBox;
    SmallPackCheckBox: TCheckBox;
    SendExtractCheckBox: TCheckBox;
    MailPanel: TPanel;
    BevelPanel: TPanel;
    AccListMemo: TMemo;
    Panel3: TPanel;
    Panel1: TPanel;
    procedure NodeEditKeyPress(Sender: TObject; var Key: Char);
    procedure LoginEditKeyPress(Sender: TObject; var Key: Char);
    procedure FormShow(Sender: TObject);
    procedure HardIdEditKeyPress(Sender: TObject; var Key: Char);
    procedure HardIdEditKeyPress2(Sender: TObject; var Key: Char);
    procedure FormCreate(Sender: TObject);
    procedure HexPanelClick(Sender: TObject);
    procedure HexPanelMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure HexPanelMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure LastIdEditChange(Sender: TObject);
    procedure ChangeIdLabelClick(Sender: TObject);
    procedure Panel1Click(Sender: TObject);
    procedure MailPanelClick(Sender: TObject);
    procedure Panel3Click(Sender: TObject);
  private
    LoginOldNew: Boolean;
  public
  end;

implementation

{$R *.DFM}

type
  EditRecord = function(Sender: TComponent; RecPtr: Pointer;
    SearchIndex: Integer; ShowDlg: Boolean): Boolean;

procedure TAbonForm.NodeEditKeyPress(Sender: TObject; var Key: Char);
begin
  if Sender=NodeEdit then
    LoginOldNew := False;
  if not ((Key in ['0'..'9']) or (Key < #32)) then
  begin
    Key := #0;
    MessageBeep(0)
  end;
end;

procedure TAbonForm.LoginEditKeyPress(Sender: TObject; var Key: Char);
begin
  if Sender=LoginOldEdit then
    LoginOldNew := False;
  Key := RusToLat(Key);
  if not ((Key in ['0'..'9', 'a'..'z', 'A'..'Z'])
    or (Key < #32)) then
  begin
    Key := #0;
    MessageBeep(0)
  end
  else begin
    Key := UpCase(Key);
  end;
end;

procedure TAbonForm.FormShow(Sender: TObject);
var
  S: string;
  I: Integer;
begin
  OkBtn.Enabled := (Length(NameEdit.Text)>0) and (Length(LoginEdit.Text)>0)
    and (Length(LoginOldEdit.Text)>0)
    and (Length(SizeComboBox.Text)>0) and (Length(NodeEdit.Text)>0)
    and (LoginEdit.Text<>BroadcastLogin)
    and (LoginOldEdit.Text<>BroadcastLogin);
  if Sender=Self then
  begin
    LoginOldNew := Length(LoginOldEdit.Text)=0;
    ChangeIdLabel.Tag := 0;
    ChangeIdLabelClick(nil);
  end
  else
  if LoginOldNew and (Sender=LoginEdit) then
  begin
    S := LoginEdit.Text;
    LoginOldEdit.Text := S;
    I := Length(S);
    while I>0 do
    begin
      if not(S[I] in ['0'..'9']) then
        Delete(S, I, 1);
      Dec(I);
    end;
    NodeEdit.Text := S;
  end;
end;

procedure TAbonForm.HardIdEditKeyPress(Sender: TObject; var Key: Char);
begin
  if not ((Key in ['0'..'9', '-']) or (Key < #32)) then
  begin
    Key := #0;
    MessageBeep(0)
  end
  else
    Key := UpCase(Key);
end;

procedure TAbonForm.HardIdEditKeyPress2(Sender: TObject; var Key: Char);
begin
  if not ((Key in ['0'..'9', 'A'..'F', 'a'..'f']) or (Key < #32)) then
  begin
    Key := #0;
    MessageBeep(0)
  end
  else
    Key := UpCase(Key);
end;

procedure TAbonForm.FormCreate(Sender: TObject);
begin
  NameEdit.MaxLength := SizeOf(TAbonName);
  LoginEdit.MaxLength := SizeOf(TAbonLogin);
  LoginOldEdit.MaxLength := SizeOf(TCorrName);
  LoginOldNew := False;
  MailPanelClick(nil);
end;

procedure TAbonForm.HexPanelClick(Sender: TObject);
var
  J: Integer;
  DW: dWord; 
begin
  if (Sender=nil) or (HexPanel.Tag=1) then   {to dec}
  begin
    J := 0;
    if HexPanel.Tag=1 then
    begin
      Val('$'+HardIdEdit.Text, DW, J);
      if J=0 then
        HardIdEdit.Text := IntToStr(DW);
    end;
    if J=0 then
    begin
      HexPanel.Tag := 0;
      HexPanel.Caption := 'dec';
      HardIdEdit.OnKeyPress := HardIdEditKeyPress;
      HardIdEdit.MaxLength := 10;
    end;
  end
  else begin             {to hex}
    J := 0;
    try
      if HexPanel.Tag=0 then
        HardIdEdit.Text := Format('%x', [StrToInt64(HardIdEdit.Text)]);
    except
      J := 0;
    end;
    if J=0 then
    begin
      HexPanel.Tag := 1;
      HexPanel.Caption := 'hex';
      HardIdEdit.OnKeyPress := HardIdEditKeyPress2;
      HardIdEdit.MaxLength := 8;
    end;
  end;
end;

procedure TAbonForm.HexPanelMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbLeft then (Sender as TPanel).BevelOuter := bvLowered;
end;

procedure TAbonForm.HexPanelMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  with (Sender as TPanel) do
    if BevelOuter = bvLowered then BevelOuter := bvRaised;
end;


procedure TAbonForm.LastIdEditChange(Sender: TObject);
begin
  if Visible then
  begin
    ChangeIdLabel.Tag := 1;
    ChangeIdLabelClick(nil);
  end;
end;

procedure TAbonForm.ChangeIdLabelClick(Sender: TObject);
begin
  if Sender<>nil then
  begin
    if ChangeIdLabel.Tag<2 then
      ChangeIdLabel.Tag := ChangeIdLabel.Tag+1
    else
      ChangeIdLabel.Tag := 0;
  end;
  case ChangeIdLabel.Tag of
    1:
      ChangeIdLabel.Caption := '(обновить)';
    2:
      ChangeIdLabel.Caption := '(удалить)';
    else
      ChangeIdLabel.Caption := '(оставить)';
  end;
end;

procedure TAbonForm.Panel1Click(Sender: TObject);
{procedure TAccountsForm.UpdateClient(CopyCurrent, New: Boolean);}
(*const
  MesTitle: PChar = 'Редактирование';
var
  AccountForm: TAccountForm;
  AccRec: TAccRec;
  I, L: Integer;
  T: array[0..511] of Char;
  Editing: Boolean;
  Bik: string;
  BankFullRec: TBankFullNewRec;
  ChangeCloseDate: Boolean;*)
begin
(*  ChangeCloseDate := not CopyCurrent and not New;
  if ChangeCloseDate then
    CopyCurrent := True;
  if not DataSource.DataSet.IsEmpty or (New and not CopyCurrent) then
  begin
    AccountForm := TAccountForm.Create(Self);
    with AccountForm do
    begin
      FNew := New;
      if CopyCurrent then
        TExtBtrDataSet(DataSource.DataSet).GetBtrRecord(PChar(@AccRec))
      else
        FillChar(AccRec, SizeOf(AccRec), #0);
      with AccRec do
      begin
        DosToWin(arName);
        AccEdit.Text := arAccount;
        CorrWideComboBox.ItemIndex := CorrWideComboBox.Items.
          IndexOfObject(TObject(arCorr));
        if New then
          OpenDateEdit.Date := OpenCloseDateEdit.Date
        else begin
          if arDateO>0 then
            OpenDateEdit.Date := BtrDateToDate(arDateO);
          if arDateC>0 then
          begin
            if not ChangeCloseDate then
              CloseDateEdit.Date := BtrDateToDate(arDateC);
          end
          else
            if ChangeCloseDate then
              CloseDateEdit.Date := OpenCloseDateEdit.Date;
        end;
        KindRadioGroup.ItemIndex := arOpts and asType;

        ClLockCheckBox.Checked := (arOpts and asLockCl)>0;

        SendRadioGroup.ItemIndex := (arOpts and asSndType) shr 14;
        CurSumCalcEdit.Value := arSumA*0.01;
        StartSumCalcEdit.Value := arSumS*0.01;
        NameEdit.Text := arName;
        VerSpinEdit.Value := arVersion;
      end;
      Editing := True;
      while Editing and (ShowModal = mrOk) do
      begin
        Editing := False;
        FillChar(AccRec.arAccount, SizeOf(AccRec.arAccount), #0);
        FillChar(AccRec.arName, SizeOf(AccRec.arName), #0);
        with AccRec do
        begin
          StrPLCopy(T, AccEdit.Text, SizeOf(T));
          StrTCopy(@arAccount, @T, SizeOf(arAccount));
          arCorr := Integer(CorrWideComboBox.Items.Objects[CorrWideComboBox.ItemIndex]);
          arVersion := VerSpinEdit.Value + 1;
          arDateO := DateToBtrDate(OpenDateEdit.Date);
          arDateC := DateToBtrDate(CloseDateEdit.Date);
          arOpts := KindRadioGroup.ItemIndex or (FNewSend shl 14);
          if ClLockCheckBox.Checked then
            arOpts := arOpts or asLockCl;
          arSumA := Round(CurSumCalcEdit.Value*100.0);
          arSumS := Round(StartSumCalcEdit.Value*100.0);
          StrPLCopy(arName, NameEdit.Text, SizeOf(arName)-1);
          WinToDos(arName);
          L := SizeOf(AccRec)-SizeOf(AccRec.arName)+StrLen(arName)+1;
        end;
        Bik := DecodeMask('$(BankBik)', 5, GetUserNumber);
        if GetBank(Bik, BankFullRec) then
          Editing := not TestAcc(IntToStr(BankFullRec.brCod), BankFullRec.brKs,
            AccRec.arAccount, ' клиента', True)
        else
          MessageBox(Handle, 'В справочнике отсутствует банк с указанным БИКом в настройках.'
            +#13#10'Проверка расчетного счета не выполнена',
            MesTitle, MB_OK or MB_ICONWARNING);
        if not Editing then
          with TExtBtrDataSet(DataSource.DataSet) do
          begin
            if New then
            begin
              MakeRegNumber(rnPaydoc, I);
              AccRec.arIder := I;
              if AddBtrRecord(PChar(@AccRec), L) then
              begin
                ProtoMes(plInfo, MesTitle, 'Добавлен счет Id='+IntToStr(AccRec.arIder));
                Refresh
              end
              else begin
                Editing := True;
                MessageBox(Handle, 'Невозможно добавить запись', MesTitle,
                  MB_OK or MB_ICONERROR);
              end;
            end
            else begin
              I := AccRec.arIder;
              if LocateBtrRecordByIndex(I, 0, bsEq) then
              begin
                if UpdateBtrRecord(@AccRec, L) then
                begin
                  ProtoMes(plInfo, MesTitle, 'Изменен счет Id='+IntToStr(AccRec.arIder));
                  UpdateCursorPos
                end
                else
                  Editing := MessageBox(Handle, 'Не удается изменить запись. Повторить?',
                    MesTitle, MB_YESNOCANCEL or MB_ICONWARNING) = ID_YES;
              end
              else begin
                Editing := MessageBox(Handle, 'Запись уже не существует. Создать заново?',
                  MesTitle, MB_YESNOCANCEL or MB_ICONWARNING) = ID_YES;
                New := Editing;
              end;
            end;
        end;
      end;
      Free;
    end;
  end; *)
end;

procedure TAbonForm.MailPanelClick(Sender: TObject);
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

var
  Processing: Boolean = False;

procedure TAbonForm.Panel3Click(Sender: TObject);
{procedure TAccountForm.ClientPanelClick(Sender: TObject);}
const
  MesTitle: PChar = 'Поиск клиента';
var
  NewAcc, ClientInn, ClientName: ShortString;
  AccNum: string[10];
  CurrCode: string[3];
  UserCodeLocal: Integer;
  Sum: Double;
  Mes: string;
  S: string;
  D: Double;

  procedure AddMes(S: string);
  begin
    if Length(Mes)>0 then
      Mes := Mes + #13#10;
    Mes := Mes + S;
  end;

var
  I: Integer;
begin
  (*if Processing then
    Processing := False
  else begin
    if OraBase.OrBaseConn then
    begin
      Mes := '';
      Processing := True;
      I := 0;
      while Processing and (I<AccListMemo.Lines.Count) do
      begin
        S := Trim(AccListMemo.Lines.Strings[I]);
        NewAcc := S;
        if OrGetAccAndCurrByNewAcc(NewAcc, AccNum, CurrCode, UserCodeLocal) then
        begin
          if OrGetClientByAcc(AccNum, CurrCode, ClientInn, ClientName, NewAcc, S) then
          begin
            DosToWinL(@ClientName, Length(ClientName));
            NameEdit.Text := RusUpperCase(ClientName);
          end
          else
            Mes := 'Клиент не найден в справочнике АБС';
          if OrGetLimByAccAndDate(AccNum, CurrCode, DateToDosDate(Date-1.0), Sum) then
            CurSumCalcEdit.Value := Sum
          else
            AddMes('Текущий остаток не найден в АБС');
          if OpenDateEdit.Date<>0 then
          begin
            if OraBase.OrBaseConn then
              Check := OrGetLimByAccAndDate(AccNum, CurrCode, DateToDosDate(
                OpenDateEdit.Date), Sum)
            if Check then
              StartSumCalcEdit.Value := Sum
            else
              AddMes('Начальный остаток не найден в АБС');
          end;
        end
        else
          Mes := 'Счет ['+AccEdit.Text+'] не найден в АБС';
        Inc(I);
      end;
    end;
    {if Length(Mes)>0 then
      MessageBox(Handle, PChar(Mes), MesTitle, MB_OK or MB_ICONWARNING);}
  end; *)
end;

end.
