unit MemorderFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons, Mask, CurrEdit, ToolEdit, ExtCtrls, Basbn, Registr,
  Common, Utilits, CommCons, WideComboBox;

type
  TMemorderForm = class(TForm)
    Panel: TPanel;
    CancelBtn: TBitBtn;
    OkBtn: TBitBtn;
    AreaScrollBox: TScrollBox;
    AreaPanel: TPanel;
    PayGroupBox: TGroupBox;
    NumLabel: TLabel;
    SumLabel: TLabel;
    DateLabel: TLabel;
    TypeLabel: TLabel;
    DateEdit: TDateEdit;
    SumCalcEdit: TRxCalcEdit;
    NumSpinEdit: TEdit;
    PayCodeEdit: TEdit;
    DebitGroupBox: TGroupBox;
    DebitMemo: TMemo;
    DebitNameBtn: TPanel;
    DebitInnBtn: TPanel;
    DebitInnEdit: TEdit;
    DebitRsBtn: TPanel;
    CreditGroupBox: TGroupBox;
    CreditMemo: TMemo;
    CreditInnBtn: TPanel;
    CreditNameBtn: TPanel;
    CreditRsBtn: TPanel;
    CreditInnEdit: TEdit;
    AreaGroupBox: TGroupBox;
    PurposeMemo: TMemo;
    DebitRsBox: TWideComboBox;
    CreditRsBox: TWideComboBox;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure BtnPanelMouseDown(Sender: TObject;
      Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure BtnPanelMouseUp(Sender: TObject;
      Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure CreditRsBoxChange(Sender: TObject);
    procedure CreditRsBoxExit(Sender: TObject);
    procedure CreditRsBoxClick(Sender: TObject);
    procedure CreditInnBtnClick(Sender: TObject);
    procedure CreditRsBtnClick(Sender: TObject);
    procedure CreditNameBtnClick(Sender: TObject);
    procedure DebitRsBoxChange(Sender: TObject);
    procedure DebitInnBtnClick(Sender: TObject);
    procedure DebitNameBtnClick(Sender: TObject);
    procedure NumSpinEditKeyPress(Sender: TObject; var Key: Char);
    procedure PurposeMemoKeyPress(Sender: TObject; var Key: Char);
    procedure NdsPanelMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure NdsPanelMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure CreditBikEditChange(Sender: TObject);
    procedure DebitRsBoxExit(Sender: TObject);
    procedure DebitRsBoxClick(Sender: TObject);
    procedure DebitRsBtnClick(Sender: TObject);
    procedure DebitMemoKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
  private
    FReadOnly: Boolean;
    function ClientSearchAndEdit(ShowDlg: Boolean; Index, Client: Integer): Boolean;
  public
    procedure LockAllControls;
  end;

var
  CommonBik: array[0..SizeOf(TInn)] of Char;
  CommonKs: array[0..SizeOf(TAccount)] of Char;
  CommonBankName: string;
const
  CharAfterNazn: array[0..63] of Char='.';
  EnterAfterNazn: Boolean = True;

implementation

{$R *.DFM}

const
  RecepBankChanged: Boolean = False;
  PayerChanged: Boolean = False;
  RecepientChanged: Boolean = False;

procedure TMemorderForm.FormCreate(Sender: TObject);
begin
  FReadOnly := False;
  if Height>Screen.Height-40 then
  begin
    SetBounds(Left, Top, Width+17, Screen.Height-40);
  end;
  if Width>Screen.Width then
    Width := Screen.Width;
end;

procedure TMemorderForm.FormShow(Sender: TObject);
begin
  RecepBankChanged := False;
  if DebitRsBox.Items.Count>0 then
    DebitRsBox.DroppedWidth := 320;
  if CreditRsBox.Items.Count>0 then
    CreditRsBox.DroppedWidth := 320;
end;

type
  EditClientRecord = function(Sender: TComponent; RecPtr: Pointer;
    SearchIndex: Integer; ShowDlg: Boolean; AList: TStrings): Boolean;

function TMemorderForm.ClientSearchAndEdit(ShowDlg: Boolean; Index, Client: Integer): Boolean;
var
  ModuleName: array[0..512] of Char;
  Module: HModule;
  P: Pointer;
  ClientRec: TNewClientRec;
  I, Err: Integer;
begin
  Result := False;
  if FReadOnly then Exit;
  StrPLCopy(ModuleName, DecodeMask('$(Clients)', 5, GetUserNumber), SizeOf(ModuleName));
  Module:=GetModuleHandle(ModuleName);
  if Module=0 then
    MessageDlg('Не найден модуль диалога выбора клиента'
      +#13+'['+ModuleName+']',
      mtError,[mbOk],0)
  else begin
    P:=GetProcAddress(Module, EditClientRecordDLLProcName);
    if P=nil then
      MessageDlg('Не найдена функция модуля '+EditClientRecordDLLProcName+'()',
        mtError,[mbOk],0)
    else begin
      FillChar(ClientRec, SizeOf(ClientRec), #0);
      with ClientRec do
      begin
        if Client=0 then
        begin
          StrPCopy(clAccC, DebitRsBox.Text);
          StrPCopy(clInn, DebitInnEdit.Text);
          {StrPCopy(clKpp, DebitKppEdit.Text);}
          StrPCopy(clNameC, DebitMemo.Text);
        end
        else begin
          StrPCopy(clAccC, CreditRsBox.Text);
          StrPCopy(clInn, CreditInnEdit.Text);
          {StrPCopy(clKpp, CreditKppEdit.Text);}
          StrPCopy(clNameC, CreditMemo.Text);
        end;
        Val(CommonBik, I, Err);
        clCodeB := I;
        WinToDos(clNameC);
      end;
      if EditClientRecord(P)(Self, @ClientRec, Index, ShowDlg,
        {CreditRsBox.Items}nil) then
      begin
        Result := True;
        if ClientRec.clCodeB=I then
        begin
          with ClientRec do
          begin
            if Client=0 then
            begin
              DebitRsBox.Text := clAccC;
              DebitInnEdit.Text := clInn;
              {DebitKppEdit.Text := clKpp;}
              DebitMemo.Text := clNameC;
            end
            else begin
              CreditRsBox.Text := clAccC;
              CreditInnEdit.Text := clInn;
              {CreditKppEdit.Text := clKpp;}
              CreditMemo.Text := clNameC;
            end
          end;
          RecepientChanged := False;
        end
        else
          MessageBox(ParentWnd, 'Нужно выбирать счет с тем же БИКом', 'Выбор клиента',
            MB_OK+MB_ICONWARNING);
      end;
    end;
  end;
end;

procedure TMemorderForm.CreditRsBoxChange(Sender: TObject);
begin
  RecepientChanged := True;
end;

procedure TMemorderForm.CreditRsBoxExit(Sender: TObject);
begin
  if RecepientChanged then
    ClientSearchAndEdit(False, 0, 1);
end;

procedure TMemorderForm.CreditRsBoxClick(Sender: TObject);
begin
  if not ClientSearchAndEdit(False, 0, 1) then
  begin
    CreditInnEdit.Text := '';
    CreditMemo.Text := '';
  end;
end;

procedure TMemorderForm.BtnPanelMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbLeft then (Sender as TPanel).BevelOuter := bvLowered;
end;

procedure TMemorderForm.BtnPanelMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  with (Sender as TPanel) do
    if BevelOuter = bvLowered then BevelOuter := bvRaised;
end;

procedure TMemorderForm.CreditNameBtnClick(Sender: TObject);
begin
  ClientSearchAndEdit(True, 2, 1);
end;

procedure TMemorderForm.CreditInnBtnClick(Sender: TObject);
begin
  ClientSearchAndEdit(True, 1, 1);
end;

procedure TMemorderForm.CreditRsBtnClick(Sender: TObject);
begin
  ClientSearchAndEdit(True, 0, 1);
end;

procedure TMemorderForm.DebitRsBtnClick(Sender: TObject);
begin
  ClientSearchAndEdit(True, 0, 0);
end;

procedure TMemorderForm.DebitRsBoxChange(Sender: TObject);
begin
  PayerChanged := True;
end;

procedure TMemorderForm.DebitNameBtnClick(Sender: TObject);
begin
  ClientSearchAndEdit(True, 2, 0);
end;

procedure TMemorderForm.DebitInnBtnClick(Sender: TObject);
begin
  ClientSearchAndEdit(True, 1, 0);
end;

procedure TMemorderForm.CreditBikEditChange(Sender: TObject);
begin
  RecepBankChanged := True;
end;

procedure TMemorderForm.DebitRsBoxExit(Sender: TObject);
begin
  if PayerChanged then
    ClientSearchAndEdit(False, 0, 0);
end;

procedure TMemorderForm.DebitRsBoxClick(Sender: TObject);
begin
  if not ClientSearchAndEdit(False, 0, 0) then
  begin
    DebitInnEdit.Text := '';
    DebitMemo.Text := '';
  end;
end;

procedure LockControls(AWinControl: TWinControl);
var
  C: TControl;
  I: Integer;
begin
  with AWinControl do
  begin
    for I:=1 to ControlCount do
    begin
      C:=Controls[I-1];
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
          if C is TMaskEdit then
            with C as TMaskEdit do
            begin
              ParentColor := True;
              ReadOnly := True;
            end
          else
            if C is TComboBox then
              with C as TComboBox do
              begin
                ParentColor := True;
                {Style := csSimple;}
                Enabled := False;
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

procedure TMemorderForm.LockAllControls;
begin
  LockControls(Self);
  FReadOnly:=True;
end;

procedure TMemorderForm.NumSpinEditKeyPress(Sender: TObject; var Key: Char);
begin
  if not ((Key in ['0'..'9']) or (Key < #32)) or FReadOnly
  then begin
    Key := #0;
    MessageBeep(0)
  end;
end;

procedure TMemorderForm.PurposeMemoKeyPress(Sender: TObject; var Key: Char);
begin
  if not (Key <> '№') then
  begin
    Key := #0;
    MessageBeep(0)
  end;
end;

procedure TMemorderForm.NdsPanelMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  with Sender as TPanel do
  begin
    BevelOuter := bvLowered;
    if Button = mbRight then
      Caption := '_ НДС'
    else
      Caption := '+ НДС';
  end;
end;

function GetNDS: Double;
begin
  if not GetRegParamByName('NDS', GetUserNumber, Result) then
    Result := 0.2;
end;

procedure TMemorderForm.NdsPanelMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  NDS: Double;
begin
  with (Sender as TPanel) do
    if BevelOuter = bvLowered then
    begin
      BevelOuter := bvRaised;
      Caption := '+ НДС';
      if not FReadOnly then
      begin
        NDS := GetNDS;
        if Button = mbRight then
          SumCalcEdit.Value := SumCalcEdit.Value / (1+NDS)
        else
          SumCalcEdit.Value := SumCalcEdit.Value * (1+NDS)
      end;
    end;
end;

procedure TMemorderForm.FormKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  case Key of
    VK_F4:
      CreditNameBtnClick(Self);
    VK_F2:
      ModalResult := mrOk;
  end;
end;

procedure TMemorderForm.DebitMemoKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (Key=VK_RETURN) and (Shift=[ssCtrl]) then
    ModalResult := mrOk;
end;

end.
