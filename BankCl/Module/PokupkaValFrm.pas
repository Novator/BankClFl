unit PokupkaValFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons, Mask, CurrEdit, ToolEdit, ExtCtrls, Menus, Bases, Registr,
  Common, Utilits, CommCons, WideComboBox;

type
  TPokupkaValForm = class(TForm)
    Panel: TPanel;
    CancelBtn: TBitBtn;
    OkBtn: TBitBtn;
    AreaScrollBox: TScrollBox;
    AreaPanel: TPanel;
    CreditGroupBox: TGroupBox;
    CreditKsLabel: TLabel;
    CreditBankMemo: TMemo;
    CreditMemo: TMemo;
    CreditInnBtn: TPanel;
    CreditBikBtn: TPanel;
    CreditNameBtn: TPanel;
    CreditBankBtn: TPanel;
    CreditRsBtn: TPanel;
    CreditInnEdit: TEdit;
    CreditBikEdit: TEdit;
    CreditKsEdit: TEdit;
    DebitGroupBox: TGroupBox;
    DebitBikLabel: TLabel;
    DebitKsLabel: TLabel;
    DebitInnBtn: TPanel;
    DebitInnEdit: TEdit;
    DebitKsEdit: TEdit;
    DebitBikEdit: TEdit;
    PayGroupBox: TGroupBox;
    NumberLabel: TLabel;
    SumLabel: TLabel;
    DateLabel: TLabel;
    VidLabel: TLabel;
    TypeLabel: TLabel;
    OcherLabel: TLabel;
    SrokLabel: TLabel;
    DateEdit: TDateEdit;
    PayKindBox: TComboBox;
    SumCalcEdit: TRxCalcEdit;
    NumSpinEdit: TEdit;
    PayCodeEdit: TEdit;
    NdsPanel: TPanel;
    PriorityEdit: TEdit;
    TermEdit: TDateEdit;
    NalogGroupBox: TGroupBox;
    DebitRsBox: TWideComboBox;
    CreditRsBox: TEdit;
    DebitKppEdit: TEdit;
    DebitKppLabel: TLabel;
    CreditKppLabel: TLabel;
    CreditKppEdit: TEdit;
    NDocEdit: TEdit;
    NDocLabel: TLabel;
    DocDateEdit: TDateEdit;
    DocDateLabel: TLabel;
    Label8: TLabel;
    TpComboBox: TWideComboBox;
    KbkLabel: TLabel;
    KbkEdit: TEdit;
    OkatoLabel: TLabel;
    OkatoEdit: TEdit;
    OpComboBox: TWideComboBox;
    OpLabel: TLabel;
    NpLabel: TLabel;
    PeriodComboBox: TWideComboBox;
    MounthComboBox: TWideComboBox;
    YearComboBox: TWideComboBox;
    NDSBox: TComboBox;
    NDSRemLabel: TLabel;
    NaznGroupBox: TGroupBox;
    PurposeMemo: TMemo;
    DocIdLabel: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure BtnPanelMouseDown(Sender: TObject;
      Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure BtnPanelMouseUp(Sender: TObject;
      Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure CreditRsBoxChange(Sender: TObject);
    procedure CreditRsBoxExit(Sender: TObject);
    procedure CreditInnBtnClick(Sender: TObject);
    procedure CreditRsBtnClick(Sender: TObject);
    procedure CreditNameBtnClick(Sender: TObject);
    procedure CreditBikBtnClick(Sender: TObject);
    procedure CreditBankBtnClick(Sender: TObject);
    procedure DebitRsBoxClick(Sender: TObject);
    procedure DebitInnBtnClick(Sender: TObject);
    procedure DebitNameBtnClick(Sender: TObject);
    procedure NumSpinEditKeyPress(Sender: TObject; var Key: Char);
    procedure PurposeMemoKeyPress(Sender: TObject; var Key: Char);
    procedure NdsPanelMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure NdsPanelMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure PurposeMemoExit(Sender: TObject);
    procedure NDSBoxClick(Sender: TObject);
    procedure CreditBikEditExit(Sender: TObject);
    procedure CreditBikEditChange(Sender: TObject);
    procedure SaveItemClick(Sender: TObject);
    procedure DebitRsBtnClick(Sender: TObject);
    procedure DebitRsBoxChange(Sender: TObject);
    procedure DebitRsBoxExit(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure PurposeMemoKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure OpComboBoxKeyPress(Sender: TObject; var Key: Char);
    procedure OpComboBoxChange(Sender: TObject);
    procedure PeriodComboBoxChange(Sender: TObject);
    procedure MounthComboBoxChange(Sender: TObject);
    procedure PayerComboBoxChange(Sender: TObject);
    procedure SrokLabelDblClick(Sender: TObject);
  private
    FReadOnly, FNew: Boolean;
    function ClientSearchAndEdit(ShowDlg: Boolean; Index, Client: Integer): Boolean;
    procedure BankSearchAndEdit(ShowDlg: Boolean; Index: Integer);
  public
    {procedure FirmSearchAndEdit(ShowDlg: Boolean; Index: Integer);}
    procedure LockAllControls;
    procedure SetNew;
  end;

var
  PokupkaValForm: TPokupkaValForm;
const
  CharAfterNazn: array[0..63] of Char = '. ';
  EnterAfterNazn: Boolean = True;
  WithNDSRem: array[0..63] of Char = '� �.�. ��� - ';
  WithoutNDSRem: array[0..63] of Char = '��� ���';
  CharAfterRem: array[0..63] of Char = '';

const
  RecepBankChanged: Boolean = False;
  PayerChanged: Boolean = False;
  RecepientChanged: Boolean = False;

implementation

{$R *.DFM}

procedure TPokupkaValForm.FormCreate(Sender: TObject);
begin
  FReadOnly := False;
  FNew := False;
  if Height>Screen.Height-40 then
  begin
    SetBounds(Left, Top, Width+17, Screen.Height-40);
  end;
  if Width>Screen.Width then
    Width:=Screen.Width;
end;

procedure TPokupkaValForm.FormShow(Sender: TObject);
var
  Year, Month, Day: Word;
begin
  PurposeMemoExit(Sender);
  RecepBankChanged := False;
  {ClientBtnClick(nil);}
  PayerComboBox.DroppedWidth := 320;
  OpComboBox.DroppedWidth := 440;
  PeriodComboBox.DroppedWidth := 220;
  MounthComboBox.DroppedWidth := 110;
  YearComboBox.DroppedWidth := 110;
  TpComboBox.DroppedWidth := 270;
  if DebitRsBox.Items.Count>0 then
    DebitRsBox.DroppedWidth := 320;
  DecodeDate(Date, Year, Month, Day);
  YearComboBox.Items.Text := IntToStr(Year)+#13#10+IntToStr(Year+1);
  if not FReadOnly then
    PayerComboBoxChange(nil);
end;

{type
  EditFirmRecord = function(Sender: TComponent; FirmRecPtr, AccRecPtr: Pointer;
    SearchIndex: Integer; ShowDlg: Boolean; AList: TStrings): Boolean;

procedure TPaydocForm.FirmSearchAndEdit(ShowDlg: Boolean; Index: Integer);
var
  ModuleName: array[0..512] of Char;
  Module: HModule;
  P: Pointer;
  FirmRec: TFirmRec;
  FirmAccRec: TFirmAccRec;
  I: Integer;
  S: string;
begin
  if FReadOnly then Exit;
  StrPLCopy(ModuleName, DecodeMask('$(Firms)',5), SizeOf(ModuleName));
  Module := GetModuleHandle(ModuleName);
  if Module=0 then
    MessageDlg('�� ������ ������ ������� ������ �����',
      mtError,[mbOk],0)
  else begin
    P:=GetProcAddress(Module, EditClientRecordDLLProcName);
    if P=nil then
      MessageDlg('�� ������� ������� ������ '+EditClientRecordDLLProcName+'()',
        mtError,[mbOk],0)
    else begin
      FillChar(FirmRec, SizeOf(FirmRec), #0);
      with FirmRec do
      begin
        S := DebitMemo.Text;
        I := Pos('���', S);
        if (I=1) then
        begin
          I := I+3;
          while (I<=Length(S)) and ((S[I] in ['0'..'9']) or (S[I]=' ')
            or (S[I]=#13) or (S[I]=#10) or (S[I]='.') or (S[I]=';')
            or (S[I]=',')) do Inc(I);
          Delete(S,1,I-1);
        end;
        StrPTCopy(frName, S, SizeOf(frName));
        StrPTCopy(frInn, DebitInnEdit.Text, SizeOf(TInn));
      end;
      with FirmAccRec do
      begin
        StrPTCopy(faAcc, DebitRsBox.Text, SizeOf(TAccount));
      end;
      if EditFirmRecord(P)(Self, @FirmRec, @FirmAccRec, Index, ShowDlg,
        DebitRsBox.Items) then
      begin
        with FirmRec do
        begin
          DebitInnEdit.Text := frInn;
          if StrLen(frKpp)>0 then
            DebitMemo.Text := '��� '+frKpp+#13+#10+frName
          else
            DebitMemo.Text := frName
        end;
        if ShowDlg then
          with FirmAccRec do
          begin
            StrLCopy(ModuleName, faAcc, SizeOf(TAccount));
            DebitRsBox.Text := StrPas(ModuleName);
          end;
        PayerChanged := False;
        BankSearchAndEdit(False, 0);
      end;
    end;
  end;
end;}

(*type
  EditClientRecord = function(Sender: TComponent; RecPtr: Pointer;
    SearchIndex: Integer; ShowDlg: Boolean; AList: TStrings): Boolean;

procedure TPaydocForm.ClientSearchAndEdit(ShowDlg: Boolean; Index: Integer);
var
  ModuleName: array[0..512] of Char;
  Module: HModule;
  P: Pointer;
  ClientRec: TClientRec;
  Err: Integer;
begin
  if FReadOnly then Exit;
  StrPLCopy(ModuleName, DecodeMask('$(Clients)', 5), SizeOf(ModuleName));
  Module:=GetModuleHandle(ModuleName);
  if Module=0 then
    MessageDlg('�� ������ ������ ������� ������ �������'
      +#13+'['+ModuleName+']',
      mtError,[mbOk],0)
  else begin
    P:=GetProcAddress(Module, EditClientRecordDLLProcName);
    if P=nil then
      MessageDlg('�� ������� ������� ������ '+EditClientRecordDLLProcName+'()',
        mtError,[mbOk],0)
    else begin
      FillChar(ClientRec, SizeOf(ClientRec), #0);
      with ClientRec do begin
        StrPCopy(clAccC, CreditRsBox.Text);
        Val(CreditBikEdit.Text, clCodeB, Err);
        StrPCopy(clInn, CreditInnEdit.Text);
        StrPCopy(clNameC, CreditMemo.Text);
        WinToDos(clNameC);
      end;
      if EditClientRecord(P)(Self, @ClientRec, Index, ShowDlg,
        CreditRsBox.Items) then
      begin
        with ClientRec do begin
          CreditRsBox.Text := clAccC;
          CreditBikEdit.Text := IntToStr(clCodeB);
          CreditInnEdit.Text := clInn;
          CreditMemo.Text := clNameC;
        end;
        RecepientChanged := False;
        BankSearchAndEdit(False, 0);
      end;
    end;
  end;
end;*)

type
  EditClientRecord = function(Sender: TComponent; RecPtr: Pointer;
    SearchIndex: Integer; ShowDlg: Boolean; AList: TStrings): Boolean;

function TPokupkaValForm.ClientSearchAndEdit(ShowDlg: Boolean; Index, Client: Integer): Boolean;
var
  ModuleName: array[0..512] of Char;
  Module: HModule;
  P: Pointer;
  ClientRec: TNewClientRec;
  I, Err: Integer;
begin
  Result := False;
  if FReadOnly then Exit;
  StrPLCopy(ModuleName, DecodeMask('$(Clients)', 5), SizeOf(ModuleName));
  Module:=GetModuleHandle(ModuleName);
  if Module=0 then
    MessageDlg('�� ������ ������ ������� ������ �������'
      +#13+'['+ModuleName+']',
      mtError,[mbOk],0)
  else begin
    P := GetProcAddress(Module, EditClientRecordDLLProcName);
    if P=nil then
      MessageDlg('�� ������� ������� ������ '+EditClientRecordDLLProcName+'()',
        mtError,[mbOk],0)
    else begin
      FillChar(ClientRec, SizeOf(ClientRec), #0);
      with ClientRec do
      begin
        if Client=0 then
        begin
          StrPCopy(clAccC, DebitRsBox.Text);
          StrPCopy(clInn, DebitInnEdit.Text);
          StrPCopy(clKpp, DebitKppEdit.Text);
          StrPCopy(clNameC, DebitMemo.Text);
          Val(DebitBikEdit.Text, I, Err);
        end
        else begin
          StrPCopy(clAccC, CreditRsBox.Text);
          StrPCopy(clInn, CreditInnEdit.Text);
          StrPCopy(clKpp, CreditKppEdit.Text);
          StrPCopy(clNameC, CreditMemo.Text);
          Val(CreditBikEdit.Text, I, Err);
        end;
        clCodeB := I;
        WinToDos(clNameC);
      end;
      if EditClientRecord(P)(Self, @ClientRec, Index, ShowDlg,
        {CreditRsBox.Items}nil) then
      begin
        Result := True;
        with ClientRec do
        begin
          if Client=0 then
          begin
            if clCodeB=I then
            begin
              DebitRsBox.Text := clAccC;
              DebitInnEdit.Text := clInn;
              DebitKppEdit.Text := clKpp;
              DebitMemo.Text := clNameC;
            end
            else
              MessageBox(Handle, '����� �������� ������� � ��� �� �����',
                '����� �������', MB_OK+MB_ICONWARNING);
          end
          else begin
            CreditRsBox.Text := clAccC;
            CreditInnEdit.Text := clInn;
            CreditKppEdit.Text := clKpp;
            CreditMemo.Text := clNameC;
            CreditBikEdit.Text := IntToStr(clCodeB);
            RecepBankChanged := True;
            BankSearchAndEdit(False, 0);
          end
        end;
        RecepientChanged := False;
      end;
    end;
  end;
end;

type
  EditRecord = function(Sender: TComponent; RecPtr: Pointer;
    SearchIndex: Integer; ShowDlg: Boolean): Boolean;

procedure TPokupkaValForm.BankSearchAndEdit(ShowDlg: Boolean; Index: Integer);
var
  ModuleName: array[0..511] of Char;
  Module: HModule;
  P: Pointer;
  BankFullRec: TBankFullRec;
  Err: Integer;
begin
  if FReadOnly then Exit;
  StrPLCopy(ModuleName,DecodeMask('$(Banks)', 5),SizeOf(ModuleName));
  Module:=GetModuleHandle(ModuleName);
  if Module=0 then
    MessageDlg('�� ������ ������ ������� ������ �����'+#13+'['+ModuleName+']',
      mtError,[mbOk],0)
  else begin
    P := GetProcAddress(Module, EditRecordDLLProcName);
    if P=nil then
      MessageDlg('�� ������� ������� ������ '+EditRecordDLLProcName+'()',
        mtError,[mbOk],0)
    else begin
      with BankFullRec do
      begin
        Val(CreditBikEdit.Text,brCod,Err);
        StrPCopy(brKs, CreditKsEdit.Text);
        StrPCopy(brName, CreditBankMemo.Text);
        WinToDos(brName);
      end;
      if EditRecord(P)(Self, @BankFullRec, Index, ShowDlg) then
      begin
        with BankFullRec do
        begin
          CreditBikEdit.Text := FillZeros(brCod, 9);
          CreditKsEdit.Text := brKs;
          CreditBankMemo.Text := brName;
        end;
        RecepBankChanged := False;
        if ShowDlg then
          {ClientSearchAndEdit(True, 0, 1);
          ClientSearchAndEdit(False, 0);}
      end;
    end;
  end;
end;

procedure TPokupkaValForm.CreditRsBoxChange(Sender: TObject);
begin
  RecepientChanged := True;
end;

{procedure TPaydocForm.CreditRsBoxExit(Sender: TObject);
begin
  if RecepientChanged then ClientSearchAndEdit(False, 0);
end;

procedure TPaydocForm.CreditRsBoxClick(Sender: TObject);
var
  I: Integer;
begin
  I:=CreditRsBox.ItemIndex;
  ClientSearchAndEdit(False, 0);
  CreditRsBox.ItemIndex:=I;
end;}

procedure TPokupkaValForm.BtnPanelMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbLeft then (Sender as TPanel).BevelOuter := bvLowered;
end;

procedure TPokupkaValForm.BtnPanelMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  with (Sender as TPanel) do
    if BevelOuter = bvLowered then BevelOuter := bvRaised;
end;

{procedure TPaydocForm.CreditNameBtnClick(Sender: TObject);
begin
  ClientSearchAndEdit(True, 2);
end;

procedure TPaydocForm.CreditInnBtnClick(Sender: TObject);
begin
  ClientSearchAndEdit(True, 1);
end;

procedure TPaydocForm.CreditRsBtnClick(Sender: TObject);
begin
  ClientSearchAndEdit(True, 0);
end;}

{const
  RecepBankChanged: Boolean = False;
  PayerChanged: Boolean = False;
  RecepientChanged: Boolean = False;}

{procedure TPaydocForm.FormCreate(Sender: TObject);
begin
  FReadOnly:=False;
  if Height>Screen.Height-40 then
  begin
    SetBounds(Left, Top, Width+17, Screen.Height-40);
  end;
  if Width>Screen.Width then
    Width:=Screen.Width;
end;

procedure TPaydocForm.FormShow(Sender: TObject);
begin
  RecepBankChanged := False;
end;}

{procedure TPaydocForm.CreditRsBoxChange(Sender: TObject);
begin
  RecepientChanged := True;
end;}

procedure TPokupkaValForm.CreditRsBoxExit(Sender: TObject);
begin
  if RecepientChanged then
    ClientSearchAndEdit(False, 0, 1);
end;

{procedure TPaydocForm.BtnPanelMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbLeft then (Sender as TPanel).BevelOuter := bvLowered;
end;}

{procedure TPaydocForm.BtnPanelMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  with (Sender as TPanel) do
    if BevelOuter = bvLowered then BevelOuter := bvRaised;
end;}

procedure TPokupkaValForm.CreditNameBtnClick(Sender: TObject);
begin
  ClientSearchAndEdit(True, 2, 1);
end;

procedure TPokupkaValForm.CreditInnBtnClick(Sender: TObject);
begin
  ClientSearchAndEdit(True, 1, 1);
end;

procedure TPokupkaValForm.CreditRsBtnClick(Sender: TObject);
begin
  ClientSearchAndEdit(True, 0, 1);
end;

procedure TPokupkaValForm.DebitRsBtnClick(Sender: TObject);
begin
  ClientSearchAndEdit(True, 0, 0);
end;

procedure TPokupkaValForm.DebitRsBoxChange(Sender: TObject);
begin
  PayerChanged := True;
end;

procedure TPokupkaValForm.DebitNameBtnClick(Sender: TObject);
begin
  ClientSearchAndEdit(True, 2, 0);
end;

procedure TPokupkaValForm.DebitInnBtnClick(Sender: TObject);
begin
  ClientSearchAndEdit(True, 1, 0);
end;

procedure TPokupkaValForm.CreditBikEditChange(Sender: TObject);
begin
  RecepBankChanged := True;
end;

procedure TPokupkaValForm.DebitRsBoxExit(Sender: TObject);
begin
  if PayerChanged then
    ClientSearchAndEdit(False, 0, 0);
end;

procedure TPokupkaValForm.DebitRsBoxClick(Sender: TObject);
begin
  if not ClientSearchAndEdit(False, 0, 0) then
  begin
    DebitInnEdit.Text := '';
    DebitKppEdit.Text := '';
    DebitMemo.Text := '';
  end;
end;

procedure TPokupkaValForm.CreditBikBtnClick(Sender: TObject);
begin
  BankSearchAndEdit(True, 0);
end;

procedure TPokupkaValForm.CreditBankBtnClick(Sender: TObject);
begin
  BankSearchAndEdit(True, 2);
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

procedure UnLockControls(AWinControl: TWinControl);
var
  C: TControl;
  I: Integer;
begin
  with AWinControl do
  begin
    for I:=1 to ControlCount do
    begin
      C := Controls[I-1];
      if C is TMemo then
        with C as TMemo do
        begin
          ParentColor := False;
          ReadOnly := False;
          Color := clWindow;
        end
      else
        if C is TEdit then
          with C as TEdit do
          begin
            ParentColor := False;
            ReadOnly := False;
            Color := clWindow;
          end
        else
          if C is TMaskEdit then
            with C as TMaskEdit do
            begin
              ParentColor := False;
              ReadOnly := False;
              Color := clWindow;
            end
          else
            if C is TComboBox then
              with C as TComboBox do
              begin
                ParentColor := False;
                Enabled := True;
                Color := clWindow;
              end
            else
              if C is TRxCalcEdit then
                with C as TRxCalcEdit do
                begin
                  ParentColor := False;
                  ReadOnly := False;
                  Color := clWindow;
                end
              else
                if C is TDateEdit then
                  with C as TDateEdit do
                  begin
                    ParentColor := False;
                    ReadOnly := False;
                    Color := clWindow;
                  end;
      if C is TWinControl then
        UnLockControls(C as TWinControl);
    end;
  end;
end;

procedure TPokupkaValForm.LockAllControls;
begin
  FReadOnly := True;
  LockControls(Self);
end;

procedure TPokupkaValForm.SetNew;
begin
  FNew := True;
end;

{procedure TPaydocForm.DebitRsBoxClick(Sender: TObject);
var
  I: Integer;
begin
  if not FReadOnly then
    PayerChanged := True;
end;

procedure TPaydocForm.DebitNameBtnClick(Sender: TObject);
begin
  FirmSearchAndEdit(True, 2);
end;

procedure TPaydocForm.DebitInnBtnClick(Sender: TObject);
begin
  FirmSearchAndEdit(True, 1);
end;}

procedure TPokupkaValForm.NumSpinEditKeyPress(Sender: TObject; var Key: Char);
begin
  if not ((Key in ['0'..'9']) or (Key < #32)) or FReadOnly
  then begin
    Key := #0;
    MessageBeep(0)
  end;
end;

procedure TPokupkaValForm.OpComboBoxKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #32 then
  begin
    Key := #0;
    MessageBeep(0)
  end
  else
    Key := RusUpCase(Key);
end;

procedure TPokupkaValForm.PurposeMemoKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = '�' then
    Key := 'N';
end;

procedure TPokupkaValForm.NdsPanelMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  with Sender as TPanel do
  begin
    BevelOuter := bvLowered;
    if Button = mbRight then
      Caption := '- ���'
    else
      Caption := '+ ���';
  end;
end;

function GetNDS: Double;
begin
  if not GetRegParamByName('NDS', Result) then
    Result := 0.2;
end;

procedure TPokupkaValForm.NdsPanelMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  NDS: Double;
begin
  with (Sender as TPanel) do
    if BevelOuter = bvLowered then
    begin
      BevelOuter := bvRaised;
      Caption := '&+ ���';
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

function BackPos(FromPos: Integer; Substr,S: string): Integer;
var
  M, L: Integer;
begin
  L := Length(Substr);
  M := Length(S)-L+1;
  if (FromPos>0) and (FromPos<M) then
    Result := FromPos
  else
    Result := M;
  if Result>0 then
    while (Result>0) and (Copy(S,Result,L)<>Substr) do
      Dec(Result)
  else
    Result := 0;
end;

procedure FindSpecSubstr(S: string; var P1,P2,SubstrIndex: Integer);
var
  I, J, K: Integer;
begin
  P1 := 0;
  P2 := 0;
  S := RusUpperCase(S);
  I := BackPos(0, '���', S);
  if I>0 then   {��� �������? ��}
  begin
    J := I;
    I := BackPos(I, '���', S);
    if I>0 then    {��� �������? �� - ���� ���� ���������� ����� ��� �� ���}
    begin
      K := I+2;
      while (K<J) and (S[K]<>'.') and (S[K]<>',') and (S[K]<>';') do Inc(K);
      if K<J then
        I := 0
    end;
    if I>0 then   {���� �� ������? �� - ������ "��� ���"}
    begin
      SubstrIndex := 1;
      P1 := I;
      P2 := J+2;
    end
    else begin    {����� ���� �.�.�}
      I := J-1;
      K := 0;
      repeat    {���� �� ���}
        while (I>0) and ((S[I]=' ') or (S[I]='.')) do Dec(I);
        if I>0 then
        begin
          case K of
            0: if S[I]='�' then Inc(K) else I:=0;
            1: if S[I]='�' then Inc(K) else I:=0;
            2: if S[I]='�' then Inc(K) else I:=0;
            else I := 0;
          end;
          if (K<>3) and (I<>0) then Dec(I);
        end;
      until (I<=0) or (K=3);
      if (I>0) and (K=3) then
      begin
        SubstrIndex := 2;
        P1 := I;
        J := J+2;
        P2 := J;
      end
      else begin     {���� ����� ���}
        I := J+3;
        K := 0;
        repeat
          while (I<=Length(S)) and ((S[I]=' ') or (S[I]='.')) do
            Inc(I);
          if I<=Length(S) then
          begin
            case K of
              0: if S[I]='�' then Inc(K) else I:=0;
              1: if S[I]='�' then Inc(K) else I:=0;
              2: if S[I]='�' then Inc(K) else I:=0;
              else I := 0;
            end;
            if (K<>3) and (I<>0) then Inc(I);
          end
          else
            I:=0;
        until (I<=0) or (K=3);
        if (I>0) and (K=3) then
        begin
          SubstrIndex := 2;
          P1 := J;
          P2 := I;
          if (P2<Length(S)) and (S[P2+1]='.') then {���� ����� ����� �, ����� � �� ����}
            Inc(P2);
        end
        else
          SubstrIndex := 0;
      end;
      if SubstrIndex = 2 then {������������� P2 (� ������ ����������� �����)}
      begin
        J := P2;
        Inc(J);
        while (J<Length(S))
          and
          (
            (S[J] in [' ', '0'..'9', '%', '(', ')', '[', ']', '-']) or
            ((S[J] in ['.', ',']) and (S[J-1] in ['0'..'9'])
              and (S[J+1] in ['0'..'9']))
          )
        do
          Inc(J); {���������� �����, �������� � �����������}
        if not(S[J] in ['0'..'9', '%', '(', ')', '[', ']']) then
          Dec(J);
        P2 := J;
      end;
    end
  end
  else
    SubstrIndex := 0;
end;

procedure TPokupkaValForm.PurposeMemoExit(Sender: TObject);
var
  P1,P2, SubstrIndex: Integer;
begin
  FindSpecSubstr(PurposeMemo.Text, P1,P2, SubstrIndex);
  NDSBox.ItemIndex := SubstrIndex;
end;

procedure TPokupkaValForm.NDSBoxClick(Sender: TObject);
var
  P1,P2,SubstrIndex,L,I: Integer;
  S, S2: string;
  NDS: Double;
begin
  if not FReadOnly then
  begin
    S := PurposeMemo.Text;
    FindSpecSubstr(S, P1,P2, SubstrIndex);
    if NDSBox.ItemIndex<>SubstrIndex then
    begin
      if SubstrIndex>0 then
      begin {������� ��������, ������}
        Dec(P1);
        Inc(P2);
        S2 := Copy(S, P2, Length(S)-P2+1);
        S := Copy(S, 1, P1);
      end
      else
        S2 := '';
      if (SubstrIndex=0) and (Length(S2)=0) then
      begin
        L := Length(S);
        I := L;
        while (I>0) and ((S[I]=#10) or (S[I]=#13) or (S[I]=' ')
          or (S[I]='.') or (S[I]=',') or (S[I]=';')) do Dec(I);
        if I<L then
          Delete(S, I+1, L-I); {������ �������� �������� � �������}
        if Length(S)>0 then
        begin
          S := S + CharAfterNazn;
          if EnterAfterNazn then
            S := S + #13#10;
        end;
      end;
      L := Length(S);
      I := L;
      while (I>0) and ((S[I]=#10) or (S[I]=#13) or (S[I]=' ')) do
        Dec(I);
      if (I>0) and (S[I]='.') then
        I := 0;
      case NDSBox.ItemIndex of
        1:
          begin
            S2 := WithoutNDSRem + S2;
            if I=0 then
              S2[1] := RusUpCase(S2[1]);
            S := S+S2;
          end;
        2:
          begin
            NDS := GetNDS;
            NDS := SumCalcEdit.Value/(1+NDS)*NDS;
            S2 := WithNDSRem + SumToStr(NDS*100)+S2;
            if I=0 then
              S2[1] := RusUpCase(S2[1]);
            S := S+S2;
          end;
        else begin
          L := Length(S2);
          I := 0;
          while (I<L)
            and (S2[I+1] in [#10, #13, ' ', ',', '.', ';']) do Inc(I);
          Delete(S2, 1, I); {������ �������� �������� � �������}
          S := S+S2;
        end;
      end;
      L := Length(S);
      I := L;
      while (I>0) and ((S[I]=#10) or (S[I]=#13) or (S[I]=' ') or (S[I]=',')
        or (S[I]='.') or (S[I]=';')) do Dec(I);
      if I<L then
        Delete(S, I+1, L-I); {������ �������� �������� � �������}
      if StrLen(CharAfterRem)>0 then
        S := S + CharAfterRem;
      PurposeMemo.Text := S;
    end;
  end;
end;

procedure TPokupkaValForm.CreditBikEditExit(Sender: TObject);
begin
  if (ActiveControl.Name<>'BankBtn') and RecepBankChanged then
    BankSearchAndEdit(False, 0);
end;

{procedure TPaydocForm.CreditBikEditChange(Sender: TObject);
begin
  RecepBankChanged := True;
end;}

procedure TPokupkaValForm.SaveItemClick(Sender: TObject);
begin
  ModalResult := mrOk;
end;

procedure TPokupkaValForm.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  case Key of
    VK_F2: SaveItemClick(nil);
    VK_F4: CreditNameBtnClick(nil);
  end;
end;

procedure TPokupkaValForm.PurposeMemoKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (Key=VK_RETURN) and (Shift=[ssCtrl]) then
    SaveItemClick(nil);
end;

const
  PeriodRow1: string =
    '�1 | ������ �� ������ ������ ������'
    +#13#10'�2 | ������ �� ������ ������ ������'
    +#13#10'�3 | ������ �� ������ ������ ������'
    +#13#10'�� | �������� �������'
    +#13#10'�� | ����������� �������'
    +#13#10'�� | ����������� �������'
    +#13#10'�� | ������� �������';
  PeriodRow2: string = '01'#13#10'02'#13#10'03'#13#10'04'#13#10'05'#13#10
    +'06'#13#10'07'#13#10'08'#13#10'09'#13#10'10'#13#10'11'#13#10'12'#13#10
    +'13'#13#10'14'#13#10'15'#13#10'16'#13#10'18'#13#10'19'#13#10'20'#13#10
    +'21'#13#10'22'#13#10'23'#13#10'25'#13#10'26'#13#10'27'#13#10'28'#13#10
    +'29'#13#10'30'#13#10'31';

procedure TPokupkaValForm.OpComboBoxChange(Sender: TObject);
var
  S: string;
  I: Integer;
begin
  S := OpComboBox.Text;
  if S='��' then
    I := 1
  else
  if S='��' then
    I := 2
  else
  if S='��' then
    I := 3
  else
  if S='��' then
    I := 4
  else
  if S='��' then
    I := 5
  else
  if S='��' then
    I := 6
  else
  if S='��' then
    I := 7
  else
  if S='��' then
    I := 8
  else
  if S='��' then
    I := 9
  else
  if S='��' then
    I := 10
  else
  if S='0' then
    I := 11
  else
    I := 0;
  case I of
    1..2:
      begin
        PeriodComboBox.Items.Text := PeriodRow1;
      end;
    3..8:
      begin
        PeriodComboBox.Items.Text := PeriodRow2;
      end;
    9..10:
      begin
        PeriodComboBox.Items.Text := '0';
      end;
    else begin
      PeriodComboBox.Items.Text := PeriodRow1+#13#10+PeriodRow2
    end;
  end;
  if FNew and (Sender<>nil) and (Length(PeriodComboBox.Text)=0)
    and (PeriodComboBox.Items.Count>0)
  then
    PeriodComboBox.ItemIndex := 0;
  PeriodComboBoxChange(nil);
end;

const
  MounthRow1: string =
    '01 | ������'
    +#13#10'02 | �������'
    +#13#10'03 | ����'
    +#13#10'04 | ������'
    +#13#10'05 | ���'
    +#13#10'06 | ����'
    +#13#10'07 | ����'
    +#13#10'08 | ������'
    +#13#10'09 | ��������'
    +#13#10'10 | �������'
    +#13#10'11 | ������'
    +#13#10'12 | �������';
  MounthRow2: string =
    '01 | ������� 1'
    +#13#10'02 | ������� 2'
    +#13#10'03 | ������� 3'
    +#13#10'04 | ������� 4';
  MounthRow3: string =
    '01 | ��������� 1'
    +#13#10'02 | ��������� 2';

procedure TPokupkaValForm.PeriodComboBoxChange(Sender: TObject);
var
  S: string;
  I: Integer;
begin
  S := PeriodComboBox.Text;
  if (S='�1') or (S='�2') or (S='�3') then
    I := 1
  else
  if S='��' then
    I := 2
  else
  if S='��' then
    I := 3
  else
  if S='��' then
    I := 4
  else
  if S='��' then
    I := 5
  else
    I := 0;
  case I of
    3:
      begin
        MounthComboBox.Items.Text := MounthRow2;
      end;
    4:
      begin
        MounthComboBox.Items.Text := MounthRow3;
      end;
    5:
      begin
        MounthComboBox.Items.Text := '00';
      end;
    else begin
      MounthComboBox.Items.Text := MounthRow1;
    end;
  end;
  if FNew and (Sender<>nil) and (Length(MounthComboBox.Text)=0)
    and (MounthComboBox.Items.Count>0)
  then
    MounthComboBox.ItemIndex := 0;
  MounthComboBoxChange(nil);
end;

procedure TPokupkaValForm.MounthComboBoxChange(Sender: TObject);
begin
  if FNew and (Sender<>nil)
    and (Length(YearComboBox.Text)=0) and (YearComboBox.Items.Count>0)
  then
    YearComboBox.ItemIndex := 0;
end;

procedure TPokupkaValForm.PayerComboBoxChange(Sender: TObject);
var
  B: Boolean;
begin
  B := Length(PayerComboBox.Text)>0;
  if NalogGroupBox.Enabled <> B then
  begin
    if B then
      UnLockControls(NalogGroupBox)
    else begin
      LockControls(NalogGroupBox);
      KbkEdit.Text := '';
      OkatoEdit.Text := '';
      OpComboBox.Text := '';
      PeriodComboBox.Text := '';
      MounthComboBox.Text := '';
      YearComboBox.Text := '';
      NDocEdit.Text := '';
      DocDateEdit.Text := '';
      TpComboBox.Text := '';
    end;
    NalogGroupBox.Enabled := B;
  end;
end;

procedure TPokupkaValForm.SrokLabelDblClick(Sender: TObject);
begin
  DocIdLabel.Visible := not DocIdLabel.Visible;
end;

end.

