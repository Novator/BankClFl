unit BillFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons, Mask, ExtCtrls, Basbn, Registr, Common, BankCnBn,
  ToolEdit, CurrEdit, Spin, Utilits, BUtilits, DocFunc;

type
  TBillForm = class(TForm)
    BillGroupBox: TGroupBox;
    CancelBtn: TBitBtn;
    OkBtn: TBitBtn;
    InputCheckBox: TCheckBox;
    ToExportCheckBox: TCheckBox;
    SignCheckBox: TCheckBox;
    MailComboBox: TComboBox;
    MailLabel: TLabel;
    BillPanel: TPanel;
    PriznLabel: TLabel;
    DateLabel: TLabel;
    DelLabel: TLabel;
    VerLabel: TLabel;
    DebitMailLabel: TLabel;
    CreditMailLabel: TLabel;
    NameLabel: TLabel;
    PriznComboBox: TComboBox;
    DateEdit: TDateEdit;
    DelComboBox: TComboBox;
    VerSpinEdit: TSpinEdit;
    DebitComboBox: TComboBox;
    CreditComboBox: TComboBox;
    NameEdit: TEdit;
    PriznPanel: TPanel;
    NumberLabel: TLabel;
    VidLabel: TLabel;
    FromAccLabel: TLabel;
    ToAccLabel: TLabel;
    SumLabel: TLabel;
    NumberEdit: TEdit;
    VidComboBox: TComboBox;
    DebetAccEdit: TEdit;
    CreditAccEdit: TEdit;
    SumCalcEdit: TRxCalcEdit;
    AbsentLabel: TLabel;
    UpdateDocCheckBox: TCheckBox;
    UpdateBillCheckBox: TCheckBox;
    SenderComboBox: TComboBox;
    SenderLabel: TLabel;
    CreatePanel: TPanel;
    DocIdLabel: TLabel;
    OpIdLabel: TLabel;
    DateREdit: TEdit;
    TimeREdit: TEdit;
    DateRLabel: TLabel;
    TimeRLabel: TLabel;
    DateSLabel: TLabel;
    TimeSLabel: TLabel;
    DateSEdit: TEdit;
    TimeSEdit: TEdit;
    UserNameLabel: TLabel;
    UserNameEdit: TEdit;
    BillOperLabel: TLabel;
    BillOperEdit: TEdit;
    procedure NumberEditKeyPress(Sender: TObject; var Key: Char);
    procedure PriznComboBoxChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure MailComboBoxClick(Sender: TObject);
    procedure DebitComboBoxChange(Sender: TObject);
    procedure CreatePanelClick(Sender: TObject);
    procedure CreatePanelMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure CreatePanelMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormDblClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
  private
    FNewBill, FReadOnly: Boolean;
  protected
  public
    PayDocPtr: PBankPayRec;
    property ReadOnly: Boolean read FReadOnly;
    property NewBill: Boolean read FNewBill;
    procedure LockAllControls;
  end;

implementation

{$R *.DFM}

procedure TBillForm.NumberEditKeyPress(Sender: TObject; var Key: Char);
begin
  if not ((Key in ['0'..'9']) or (Key < #32)) then
  begin
    Key := #0;
    MessageBeep(0)
  end;
end;

procedure TBillForm.PriznComboBoxChange(Sender: TObject);
begin
  PriznPanel.Visible := PriznComboBox.ItemIndex = 0;
  case PriznComboBox.ItemIndex of
    0:
      NameEdit.MaxLength := 31;
    1,2:
      NameEdit.MaxLength := 69;
  end;
  DebitComboBoxChange(Sender);
end;

procedure LockControls(AWinControl: TWinControl);
var
  C: TControl;
  I: Integer;
begin
  with AWinControl do
  begin
    for I := 1 to ControlCount do
    begin
      C := Controls[I-1];
      if C is TMemo then
        with C as TMemo do
        begin
          ParentColor := True;
          ReadOnly := True;
        end
      else
        if C is TEdit then
          with C as TEdit do
          begin
            ParentColor:=True;
            ReadOnly:=True;
          end
        else
          if C is TCheckBox then
            with C as TCheckBox do
            begin
              ParentColor := True;
              Enabled := False;
            end
          else
            if C is TMaskEdit then
              with C as TMaskEdit do
              begin  
                ParentColor:=True;
                ReadOnly:=True;  
              end  
            else  
              if C is TComboBox then  
                with C as TComboBox do  
                begin  
                  ParentColor:=True;  
                  {Style := csSimple;}  
                  Enabled := False;
                end
              else
                if C is TSpinEdit then
                  with C as TSpinEdit do  
                  begin  
                    ParentColor := True;  
                    ReadOnly := True;  
                  end  
                else
                  if C is TRxCalcEdit then  
                    with C as TRxCalcEdit do  
                    begin  
                      ParentColor := True;  
                      ReadOnly := True;  
                    end  
                  else  
                    if C is TDateEdit then  
                      with C as TDateEdit do  
                      begin
                        ParentColor := True;  
                        ReadOnly := True;  
                      end;
      if C is TWinControl then LockControls(C as TWinControl);
    end;
  end;
end;

procedure TBillForm.LockAllControls;
begin
  LockControls(Self);
  FReadOnly := True;
  FNewBill := False;
end;


procedure TBillForm.FormCreate(Sender: TObject);
begin
  FReadOnly := False;
  PayDocPtr := nil;
end;

procedure TBillForm.MailComboBoxClick(Sender: TObject);
begin
  {UpdateDocCheckBox.Checked := True;}
  if UpdateDocCheckBox.State=cbUnchecked then
    UpdateDocCheckBox.State := cbGrayed;
end;

procedure TBillForm.DebitComboBoxChange(Sender: TObject);
begin
  {UpdateBillCheckBox.Checked := True;}
  if UpdateBillCheckBox.State=cbUnchecked then
  begin
    UpdateBillCheckBox.State := cbGrayed;
  end;
  if not NewBill and (Sender<>nil)
    and (Sender<>VerSpinEdit)
    and (VerSpinEdit.Font.Color<>clRed) then
  begin
    VerSpinEdit.Value := VerSpinEdit.Value+1;
    VerSpinEdit.Font.Color := clRed;
  end;
end;

procedure TBillForm.CreatePanelClick(Sender: TObject);
var
  Number, DebitRs, DebitKs,
    DebitBik, DebitInn, DebitName, DebitBank, CreditRs,
    CreditKs, CreditBik, CreditInn, CreditName, CreditBank, Purpose,
    DebitKpp, CreditKpp, Status, Kbk, Okato, OsnPl, Period, NDoc, DocDate, TipPl,
    Nchpl, Shifr, Nplat, OstSum: string;
  CorrRes: Integer;
  Buf: array[0..511] of Char;
begin
  if CreatePanel.Visible then
  begin
    FNewBill := True;  
    UpdateBillCheckBox.Enabled := True;
    BillPanel.Visible := True;
    DateEdit.Date := Date;
    PriznComboBox.ItemIndex := 0;
    DelComboBox.ItemIndex := 0;
    VerSpinEdit.Value := 1;
    DebitComboBox.Enabled := False;
    CreditComboBox.Enabled := False;
    SenderComboBox.Enabled := False;
    DebitComboBox.ParentColor := True;
    CreditComboBox.ParentColor := True;
    SenderComboBox.ParentColor := True;
    DelComboBox.Enabled := False;
    DelComboBox.ParentColor := True;
    if PayDocPtr<>nil then
    begin
      SumCalcEdit.Value := PayDocPtr^.dbDoc.drSum * 0.01;
      DecodeDocVar(PayDocPtr^.dbDoc, PayDocPtr^.dbDocVarLen, Number, DebitRs, DebitKs,
        DebitBik, DebitInn, DebitName, DebitBank, CreditRs,
        CreditKs, CreditBik, CreditInn, CreditName, CreditBank,
        Purpose, DebitKpp, CreditKpp, Status, Kbk, Okato, OsnPl, Period, NDoc,
        DocDate, TipPl, Nchpl, Shifr, Nplat, OstSum, 3, 2, CorrRes, True);
      StrPLCopy(Buf, Purpose, SizeOf(Buf)-1);
      DosToWin(Buf);
      NameEdit.Text := Buf;
      NumberEdit.Text := Number;
      VidComboBox.Text := FillZeros(PayDocPtr^.dbDoc.drType, 2);
      DebetAccEdit.Text := DebitRs;
      CreditAccEdit.Text := CreditRs;
    end;
    PriznComboBoxChange(nil);
    CreatePanel.Hide;
    PriznComboBox.Enabled := True;
  end;
end;

procedure TBillForm.CreatePanelMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbLeft then (Sender as TPanel).BevelOuter := bvLowered;
end;

procedure TBillForm.CreatePanelMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  with (Sender as TPanel) do
    if BevelOuter = bvLowered then BevelOuter := bvRaised;
end;

procedure TBillForm.FormDblClick(Sender: TObject);
begin
  DocIdLabel.Visible := not DocIdLabel.Visible;
  OpIdLabel.Visible := DocIdLabel.Visible;
end;

procedure TBillForm.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  case Key of
    VK_F2:
      CreatePanelClick(nil);
  end;
end;

end.
