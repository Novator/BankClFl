unit PayorderFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons, Mask, CurrEdit, ToolEdit, ExtCtrls, Menus, Basbn, Registr,
  Common, Utilits, CommCons, WideComboBox;

type
  TPaydocForm = class(TForm)
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
    DebitBankLabel: TLabel;
    DebitBikLabel: TLabel;
    DebitKsLabel: TLabel;
    DebitBankMemo: TMemo;
    DebitMemo: TMemo;
    DebitNameBtn: TPanel;
    DebitInnBtn: TPanel;
    DebitInnEdit: TEdit;
    DebitKsEdit: TEdit;
    DebitBikEdit: TEdit;
    DebitRsBtn: TPanel;
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
    NaznGroupBox: TGroupBox;
    NDSRemLabel: TLabel;
    PurposeMemo: TMemo;
    NDSBox: TComboBox;
    DlgPopupMenu: TPopupMenu;
    SaveItem: TMenuItem;
    PayerItem: TMenuItem;
    ClientItem: TMenuItem;
    DebitRsBox: TWideComboBox;
    CreditRsBox: TEdit;
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
    procedure PanelMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure PurposeMemoKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure SrokLabelDblClick(Sender: TObject);
  private
    FReadOnly: Boolean;
    function ClientSearchAndEdit(ShowDlg: Boolean; Index, Client: Integer): Boolean;
    procedure BankSearchAndEdit(ShowDlg: Boolean; Index: Integer);
  public
    {procedure FirmSearchAndEdit(ShowDlg: Boolean; Index: Integer);}
    procedure LockAllControls;
  end;

var
  PaydocForm: TPaydocForm;
const
  CharAfterNazn: array[0..63] of Char = '. ';
  EnterAfterNazn: Boolean = True;
  WithNDSRem: array[0..63] of Char = 'в т.ч. НДС - ';
  WithoutNDSRem: array[0..63] of Char = 'без НДС';
  CharAfterRem: array[0..63] of Char = '';

const
  RecepBankChanged: Boolean = False;
  PayerChanged: Boolean = False;
  RecepientChanged: Boolean = False;

implementation

{$R *.DFM}

procedure TPaydocForm.FormCreate(Sender: TObject);
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
  PurposeMemoExit(Sender);
  RecepBankChanged := False;
  {ClientBtnClick(nil);}
  if DebitRsBox.Items.Count>0 then
    DebitRsBox.DroppedWidth := 320;
end;

type
  EditClientRecord = function(Sender: TComponent; RecPtr: Pointer;
    SearchIndex: Integer; ShowDlg: Boolean; AList: TStrings): Boolean;

function TPaydocForm.ClientSearchAndEdit(ShowDlg: Boolean; Index, Client: Integer): Boolean;
var
  ModuleName: array[0..511] of Char;
  Module: HModule;
  P: Pointer;
  ClientRec: TNewClientRec;
  I, Err: Integer;
  S: string;
begin
  Result := False;
  if FReadOnly then Exit;
  StrPLCopy(ModuleName, DecodeMask('$(Clients)', 5, GetUserNumber), SizeOf(ModuleName));
  Module:=GetModuleHandle(ModuleName);
  if Module=0 then
    MessageDlg('Не найден модуль диалога выбора клиента'
      +#13+'['+ModuleName+']', mtError,[mbOk],0)
  else begin
    P := GetProcAddress(Module, EditClientRecordDLLProcName);
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
          StrPCopy(clNameC, DebitMemo.Text);
          Val(DebitBikEdit.Text, I, Err);
        end
        else begin
          StrPCopy(clAccC, CreditRsBox.Text);
          StrPCopy(clInn, CreditInnEdit.Text);
          StrPCopy(clNameC, CreditMemo.Text);
          Val(CreditBikEdit.Text, I, Err);
        end;
        clCodeB := I;
        WinToDos(clNameC);
      end;
      if EditClientRecord(P)(Self, @ClientRec, Index, ShowDlg, nil) then
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
              if StrLen(clKpp)>0 then
                S := 'КПП '+clKpp+#13#10
              else
                S := '';
              DebitMemo.Text := S+clNameC;
            end
            else
              MessageBox(Handle, 'Нужно выбирать клиента с тем же БИКом',
                'Выбор клиента', MB_OK+MB_ICONWARNING);
          end
          else begin
            CreditRsBox.Text := clAccC;
            CreditInnEdit.Text := clInn;
            if StrLen(clKpp)>0 then
              S := 'КПП '+clKpp+#13#10
            else
              S := '';
            CreditMemo.Text := S+clNameC;
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

procedure TPaydocForm.BankSearchAndEdit(ShowDlg: Boolean; Index: Integer);
var
  ModuleName: array[0..511] of Char;
  Module: HModule;
  P: Pointer;
  BankFullRec: TBankFullNewRec;
  Err: Integer;
begin
  if FReadOnly then Exit;
  StrPLCopy(ModuleName,DecodeMask('$(Banks)', 5, GetUserNumber),SizeOf(ModuleName));
  Module:=GetModuleHandle(ModuleName);
  if Module=0 then
    MessageDlg('Не найден модуль диалога выбора банка'+#13+'['+ModuleName+']',
      mtError,[mbOk],0)
  else begin
    P := GetProcAddress(Module, EditRecordDLLProcName);
    if P=nil then
      MessageDlg('Не найдена функция модуля '+EditRecordDLLProcName+'()',
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

procedure TPaydocForm.CreditRsBoxChange(Sender: TObject);
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

procedure TPaydocForm.BtnPanelMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbLeft then (Sender as TPanel).BevelOuter := bvLowered;
end;

procedure TPaydocForm.BtnPanelMouseUp(Sender: TObject;
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

procedure TPaydocForm.CreditRsBoxExit(Sender: TObject);
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

procedure TPaydocForm.CreditNameBtnClick(Sender: TObject);
begin
  ClientSearchAndEdit(True, 2, 1);
end;

procedure TPaydocForm.CreditInnBtnClick(Sender: TObject);
begin
  ClientSearchAndEdit(True, 1, 1);
end;

procedure TPaydocForm.CreditRsBtnClick(Sender: TObject);
begin
  ClientSearchAndEdit(True, 0, 1);
end;

procedure TPaydocForm.DebitRsBtnClick(Sender: TObject);
begin
  ClientSearchAndEdit(True, 0, 0);
end;

procedure TPaydocForm.DebitRsBoxChange(Sender: TObject);
begin
  PayerChanged := True;
end;

procedure TPaydocForm.DebitNameBtnClick(Sender: TObject);
begin
  ClientSearchAndEdit(True, 2, 0);
end;

procedure TPaydocForm.DebitInnBtnClick(Sender: TObject);
begin
  ClientSearchAndEdit(True, 1, 0);
end;

procedure TPaydocForm.CreditBikEditChange(Sender: TObject);
begin
  RecepBankChanged := True;
end;

procedure TPaydocForm.DebitRsBoxExit(Sender: TObject);
begin
  if PayerChanged then
    ClientSearchAndEdit(False, 0, 0);
end;

procedure TPaydocForm.DebitRsBoxClick(Sender: TObject);
begin
  if not ClientSearchAndEdit(False, 0, 0) then
  begin
    DebitInnEdit.Text := '';
    DebitMemo.Text := '';
  end;
end;

procedure TPaydocForm.CreditBikBtnClick(Sender: TObject);
begin
  BankSearchAndEdit(True, 0);
end;

procedure TPaydocForm.CreditBankBtnClick(Sender: TObject);
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
                Enabled:=False;
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

procedure TPaydocForm.LockAllControls;
begin
  LockControls(Self);
  FReadOnly:=True;
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

procedure TPaydocForm.NumSpinEditKeyPress(Sender: TObject; var Key: Char);
begin
  if not ((Key in ['0'..'9']) or (Key < #32)) or FReadOnly
  then begin
    Key := #0;
    MessageBeep(0)
  end;
end;

procedure TPaydocForm.PurposeMemoKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = '№' then
    Key := 'N';
end;

procedure TPaydocForm.NdsPanelMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  with Sender as TPanel do
  begin
    BevelOuter := bvLowered;
    if Button = mbRight then
      Caption := '- НДС'
    else
      Caption := '+ НДС';
  end;
end;

function GetNDS: Double;
begin
  if not GetRegParamByName('NDS', GetUserNumber, Result) then
    Result := 0.2;
end;

procedure TPaydocForm.NdsPanelMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  NDS: Double;
begin
  with (Sender as TPanel) do
    if BevelOuter = bvLowered then
    begin
      BevelOuter := bvRaised;
      Caption := '&+ НДС';
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
  I := BackPos(0, 'НДС', S);
  if I>0 then   {НДС найдено? да}
  begin
    J := I;
    I := BackPos(I, 'БЕЗ', S);
    if I>0 then    {БЕЗ найдено? да - ищем знак препинания после БЕЗ до НДС}
    begin
      K := I+2;
      while (K<J) and (S[K]<>'.') and (S[K]<>',') and (S[K]<>';') do Inc(K);
      if K<J then
        I := 0
    end;
    if I>0 then   {Знак не найден? да - значит "Без НДС"}
    begin
      SubstrIndex := 1;
      P1 := I;
      P2 := J+2;
    end
    else begin    {иначе ищем в.т.ч}
      I := J-1;
      K := 0;
      repeat    {ищем до НДС}
        while (I>0) and ((S[I]=' ') or (S[I]='.')) do Dec(I);
        if I>0 then
        begin
          case K of
            0: if S[I]='Ч' then Inc(K) else I:=0;
            1: if S[I]='Т' then Inc(K) else I:=0;
            2: if S[I]='В' then Inc(K) else I:=0;
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
      else begin     {ищем после НДС}
        I := J+3;
        K := 0;
        repeat
          while (I<=Length(S)) and ((S[I]=' ') or (S[I]='.')) do
            Inc(I);
          if I<=Length(S) then
          begin
            case K of
              0: if S[I]='В' then Inc(K) else I:=0;
              1: if S[I]='Т' then Inc(K) else I:=0;
              2: if S[I]='Ч' then Inc(K) else I:=0;
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
          if (P2<Length(S)) and (S[P2+1]='.') then {если точка после Ч, тогда и ее тоже}
            Inc(P2);
        end
        else
          SubstrIndex := 0;
      end;
      if SubstrIndex = 2 then {корректировка P2 (в случае присутствия суммы)}
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
          Inc(J); {пропускаем цифры, проценты и разделители}
        if not(S[J] in ['0'..'9', '%', '(', ')', '[', ']']) then
          Dec(J);
        P2 := J;
      end;
    end
  end
  else
    SubstrIndex := 0;
end;

procedure TPaydocForm.PurposeMemoExit(Sender: TObject);
var
  P1,P2, SubstrIndex: Integer;
begin
  FindSpecSubstr(PurposeMemo.Text, P1,P2, SubstrIndex);
  NDSBox.ItemIndex := SubstrIndex;
end;

procedure TPaydocForm.NDSBoxClick(Sender: TObject);
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
      begin {уточним диапазон, урежем}
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
          Delete(S, I+1, L-I); {удалим концевые переносы и пробелы}
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
          Delete(S2, 1, I); {удалим ненужные переносы и пробелы}
          S := S+S2;
        end;
      end;
      L := Length(S);
      I := L;
      while (I>0) and ((S[I]=#10) or (S[I]=#13) or (S[I]=' ') or (S[I]=',')
        or (S[I]='.') or (S[I]=';')) do Dec(I);
      if I<L then
        Delete(S, I+1, L-I); {удалим концевые переносы и пробелы}
      if StrLen(CharAfterRem)>0 then
        S := S + CharAfterRem;
      PurposeMemo.Text := S;
    end;
  end;
end;

procedure TPaydocForm.CreditBikEditExit(Sender: TObject);
begin
  if (ActiveControl.Name<>'BankBtn') and RecepBankChanged then
    BankSearchAndEdit(False, 0);
end;

{procedure TPaydocForm.CreditBikEditChange(Sender: TObject);
begin
  RecepBankChanged := True;
end;}

procedure TPaydocForm.SaveItemClick(Sender: TObject);
begin
  ModalResult := mrOk;
end;

procedure TPaydocForm.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  case Key of
    VK_F2: SaveItemClick(nil);
    VK_F4: CreditNameBtnClick(nil);
  end;
end;

procedure TPaydocForm.PanelMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  P: TPoint;
begin
  if Button=mbRight then
  begin
    P := Panel.ClientToScreen(Point(X, Y));
    with DlgPopupMenu do
      Popup(P.X, P.Y);
  end;
end;

procedure TPaydocForm.PurposeMemoKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (Key=VK_RETURN) and (Shift=[ssCtrl]) then
    SaveItemClick(nil);
end;

procedure TPaydocForm.SrokLabelDblClick(Sender: TObject);
begin
  DocIdLabel.Visible := not DocIdLabel.Visible;
end;

end.
