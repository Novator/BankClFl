unit CashorderFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons, Mask, CurrEdit, ToolEdit, ExtCtrls, ShellApi,
  Grids, Registr, Btrieve, Utilits, Basbn, Common, CommCons, WideComboBox;

type
  TCashorderForm = class(TForm)
    Panel: TPanel;
    CancelBtn: TBitBtn;
    OkBtn: TBitBtn;
    AreaScrollBox: TScrollBox;
    AreaPanel: TPanel;
    PayGroupBox: TGroupBox;
    NumLabel: TLabel;
    DateLabel: TLabel;
    TypeLabel: TLabel;
    SumLabel: TLabel;
    DateEdit: TDateEdit;
    NumSpinEdit: TEdit;
    PayCodeEdit: TEdit;
    SumEdit: TCurrencyEdit;
    ClientGroupBox: TGroupBox;
    ClientMemo: TMemo;
    CreditInnBtn: TPanel;
    CreditNameBtn: TPanel;
    CreditRsBtn: TPanel;
    ClientInnEdit: TEdit;
    PurposeGroupBox: TGroupBox;
    CodesLabel: TLabel;
    CodeLabel: TLabel;
    IndexLabel: TLabel;
    CodeSumLabel: TLabel;
    SumStringGrid: TStringGrid;
    PurposeEdit: TEdit;
    AddBtn: TBitBtn;
    DelBtn: TBitBtn;
    SumCalcEdit: TRxCalcEdit;
    IndexComboBox: TComboBox;
    CodeComboBox: TWideComboBox;
    CashBox: TGroupBox;
    CashAccLabel: TLabel;
    OrderRadioGroup: TRadioGroup;
    CashAccComboBox: TWideComboBox;
    ClientRsBox: TWideComboBox;
    CashAccPanel: TPanel;
    PaspGroupBox: TGroupBox;
    PasSerialEdit: TEdit;
    PasNumberEdit: TEdit;
    PasPlaceMemo: TMemo;
    PasSerLabel: TLabel;
    PasNumLabel: TLabel;
    PasPlacLabel: TLabel;
    FIOLabel: TLabel;
    FIOEdit: TEdit;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure BtnPanelMouseDown(Sender: TObject;
      Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure BtnPanelMouseUp(Sender: TObject;
      Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure ClientRsBoxChange(Sender: TObject);
    procedure ClientRsBoxExit(Sender: TObject);
    procedure ClientRsBoxClick(Sender: TObject);
    procedure CreditInnBtnClick(Sender: TObject);
    procedure CreditRsBtnClick(Sender: TObject);
    procedure CreditNameBtnClick(Sender: TObject);
    procedure DebitRsBoxChange(Sender: TObject);
    procedure NumSpinEditKeyPress(Sender: TObject; var Key: Char);
    procedure PurposeMemoKeyPress(Sender: TObject; var Key: Char);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure CreditBikEditChange(Sender: TObject);
    procedure SumStringGridKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure AddBtnClick(Sender: TObject);
    procedure DelBtnClick(Sender: TObject);
    procedure SumCalcEditKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure SumStringGridClick(Sender: TObject);
    procedure SumStringGridSelectCell(Sender: TObject; ACol, ARow: Integer;
      var CanSelect: Boolean);
    procedure SumStringGridDrawCell(Sender: TObject; ACol, ARow: Integer;
      Rect: TRect; State: TGridDrawState);
    procedure CodeComboBoxDrawItem(Control: TWinControl; Index: Integer;
      Rect: TRect; State: TOwnerDrawState);
    procedure IndexComboBoxClick(Sender: TObject);
    procedure SumCalcEditChange(Sender: TObject);
    procedure SumStringGridDblClick(Sender: TObject);
    procedure SumLabelDblClick(Sender: TObject);
    procedure OrderRadioGroupClick(Sender: TObject);
    procedure ClientMemoKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure CashAccPanelClick(Sender: TObject);
  private
    FReadOnly: Boolean;
    function ClientSearchAndEdit(ShowDlg: Boolean; Index: Integer): Boolean;
  public
    procedure LockAllControls;
    procedure GetCodeIndex(ACode: Integer; var AnIndex, AType: Integer;
      var AName: string);
    function GetCodeType(ACode: Integer): Integer;
    procedure PutNazn(ANazn: string; var PayType: Integer);
    procedure TakeNazn(var ANazn: string);
    procedure ChangeDebitCredit;
  end;

  TParticipant =
    record
      Rs, Ks, Bik, Inn, Kpp, Name, BankName: string;
    end;


var
  Participants: array[0..1] of TParticipant;
  DebInd, CredInd: Integer;
const
  CharAfterNazn: array[0..63] of Char='.';
  EnterAfterNazn: Boolean = True;

implementation

uses BtrDS;

{$R *.DFM}

const
  RecepBankChanged: Boolean = False;
  PayerChanged: Boolean = False;
  RecepientChanged: Boolean = False;

const
  CashCodeSection = 10;
  T: array[0..511] of Char = '';

procedure TCashorderForm.FormCreate(Sender: TObject);
var
  RegistrBase: TBtrBase;
  ParamRec: TParamNewRec;
  ParamVec: TParamKey0;
  Res, Len: Integer;
begin
  RegistrBase := GetRegistrBase;   {Заполним список кодов}
  with RegistrBase do
  begin
    with ParamVec do
    begin
      pkSect := CashCodeSection;
      pkNumber := 0;
      pkUser := CommonUserNumber;
    end;
    Len := SizeOf(ParamRec);
    Res := RegistrBase.GetGE(ParamRec, Len, ParamVec, 0);
    while (Res=0) and (ParamRec.pmSect = CashCodeSection) do
    begin
      with ParamRec do
      begin
        StrPCopy(T, pmMeasure+' | '+pmName);
        CodeComboBox.Items.Add{Object}(FillZeros(pmNumber, 3)+' | '+T{, TObject(@T)});
      end;
      Len := SizeOf(ParamRec);
      Res := RegistrBase.GetNext(ParamRec, Len, ParamVec, 0);
    end;
  end;

  with SumStringGrid do          {Определим вид таблицы}
  begin
    ColWidths[0] := 25;
    ColWidths[1] := 90;
    ColWidths[2] := SumStringGrid.Width - ColWidths[1] - ColWidths[0] - 6;
    Cells[0,0] := 'Код';
    Cells[1,0] := 'Сумма';
    Cells[2,0] := 'Наименование';
  end;
  FReadOnly := False;
  if Height>Screen.Height-40 then
  begin
    SetBounds(Left, Top, Width+17, Screen.Height-40);
  end;
  if Width>Screen.Width then
    Width := Screen.Width;
end;

function CashAccFile: string;
begin
  Result := BaseDir+'CashAcc.txt';
end;

procedure TCashorderForm.FormShow(Sender: TObject);
begin
  RecepBankChanged := False;
  with Participants[0] do
  begin
    ClientMemo.Text := Name;
    ClientRsBox.Text := RS;
    ClientInnEdit.Text := Inn;
  end;
  SumStringGridClick(Sender);
  CashAccComboBox.Text := Participants[1].Rs;
  if not FReadOnly then
  try
    CashAccComboBox.Items.LoadFromFile(CashAccFile);
  except
  end;
  if CashAccComboBox.Items.Count>0 then
    CashAccComboBox.Perform(CB_SETDROPPEDWIDTH, 320, 0);
  if CodeComboBox.Items.Count>0 then
    CodeComboBox.DroppedWidth := 320;
  if ClientRsBox.Items.Count>0 then
    ClientRsBox.DroppedWidth := 320;
end;

type
  EditClientRecord = function(Sender: TComponent; RecPtr: Pointer;
    SearchIndex: Integer; ShowDlg: Boolean; AList: TStrings): Boolean;

function TCashorderForm.ClientSearchAndEdit(ShowDlg: Boolean; Index: Integer): Boolean;
var
  ModuleName: array[0..511] of Char;
  Module: HModule;
  P: Pointer;
  ClientRec: TNewClientRec;
  I, Err: Integer;
begin
  Result := False;
  if FReadOnly then Exit;
  StrPLCopy(ModuleName, DecodeMask('$(Clients)', 5, GetUserNumber), SizeOf(ModuleName));
  Module := GetModuleHandle(ModuleName);
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
        StrPCopy(clAccC, ClientRsBox.Text);
        Val(Participants[1].Bik, I, Err);
        clCodeB := I;
        StrPCopy(clInn, ClientInnEdit.Text);
        StrPCopy(clNameC, ClientMemo.Text);
        WinToDos(clNameC);
      end;
      if EditClientRecord(P)(Self, @ClientRec, Index, ShowDlg,
        nil{ClientRsBox.Items}) then
      begin
        Result := True;
        if ClientRec.clCodeB=I then
        begin
          with ClientRec do
          begin
            ClientRsBox.Text := clAccC;
            ClientInnEdit.Text := clInn;
            ClientMemo.Text := clNameC;
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

procedure TCashorderForm.ClientRsBoxChange(Sender: TObject);
begin
  RecepientChanged := True;
end;

procedure TCashorderForm.ClientRsBoxExit(Sender: TObject);
begin
  if RecepientChanged then ClientSearchAndEdit(False, 0);
end;

procedure TCashorderForm.ClientRsBoxClick(Sender: TObject);
begin
  if not ClientSearchAndEdit(False, 0) then
  begin
    ClientInnEdit.Text := '';
    ClientMemo.Text := '';
  end;
end;

procedure TCashorderForm.BtnPanelMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbLeft then (Sender as TPanel).BevelOuter := bvLowered;
end;

procedure TCashorderForm.BtnPanelMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  with (Sender as TPanel) do
    if BevelOuter = bvLowered then BevelOuter := bvRaised;
end;

procedure TCashorderForm.CreditNameBtnClick(Sender: TObject);
begin
  ClientSearchAndEdit(True, 2);
end;

procedure TCashorderForm.CreditInnBtnClick(Sender: TObject);
begin
  ClientSearchAndEdit(True, 1);
end;

procedure TCashorderForm.CreditRsBtnClick(Sender: TObject);
begin
  ClientSearchAndEdit(True, 0);
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

procedure TCashorderForm.LockAllControls;
begin
  LockControls(Self);
  FReadOnly := True;
  CashAccPanel.Hide;
end;

procedure TCashorderForm.DebitRsBoxChange(Sender: TObject);
begin
  if not FReadOnly then
    PayerChanged := True;
end;

procedure TCashorderForm.NumSpinEditKeyPress(Sender: TObject; var Key: Char);
begin
  if not ((Key in ['0'..'9']) or (Key < #32)) or FReadOnly
  then begin
    Key := #0;
    MessageBeep(0)
  end;
end;

procedure TCashorderForm.PurposeMemoKeyPress(Sender: TObject; var Key: Char);
begin
  if not (Key <> '№') then
  begin
    Key := #0;
    MessageBeep(0)
  end;
end;

procedure TCashorderForm.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  case Key of
    VK_F2:
      ModalResult := mrOk;
    VK_F4:
      CreditNameBtnClick(Self);
  end;
end;

procedure TCashorderForm.CreditBikEditChange(Sender: TObject);
begin
  RecepBankChanged := True;
end;

procedure TCashorderForm.SumStringGridKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  case Key of
    VK_INSERT, VK_RETURN:
      if not FReadOnly then
        CodeComboBox.SetFocus;
    VK_DELETE:
      DelBtnClick(Sender);
  end;
end;

procedure TCashorderForm.SumCalcEditKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  case Key of
    VK_INSERT, VK_RETURN:
      AddBtnClick(Sender);
  end;
end;

procedure TCashorderForm.AddBtnClick(Sender: TObject);
const
  MesTitle: PChar = 'Добавление росписи';
var
  S: string;
  Code, Err, I, J: Integer;
begin
  if AddBtn.Enabled then
  begin
    if Length(CodeComboBox.Text)>0 then
    begin
      if SumCalcEdit.Value>0 then
      begin
        Val(CodeComboBox.Text, Code, Err);
        if Err=0 then
        begin
          with SumStringGrid do
          begin
            Err := 1;
            I := 1;
            while (I<RowCount) and (Err<>0) do
            begin
              Val(Cells[0, I], J, Err);
              if (Err=0) and (J<>Code) then
                Err := 1;
              Inc(I);
            end;
            if Err=0 then
              Row := I-1
            else begin
              if Cells[0, 1]<>'' then
                RowCount := RowCount+1;
              Row := RowCount-1;
            end;
            Cells[0, Row] := FillZeros(Code, 3);
            Cells[1, Row] := FloatToStr(SumCalcEdit.Value);
            GetCodeIndex(Code, Err, J, S);
            Cells[2, Row] := S;
          end;
          if IndexComboBox.ItemIndex<0 then
            IndexComboBox.ItemIndex := 0;
          IndexComboBoxClick(Sender);
          SumLabelDblClick(Sender);
          OrderRadioGroupClick(Sender);
          CodeComboBox.Text := '';
          SumCalcEdit.Value := 0;
          SumStringGridClick(Sender);
        end
        else
          MessageBox(Handle, 'Нецифровой код', MesTitle, MB_OK + MB_ICONERROR);
        CodeComboBox.SetFocus;
      end
      else begin
        MessageBox(Handle, 'Укажите сумму', MesTitle, MB_OK + MB_ICONERROR);
        SumCalcEdit.SetFocus;
      end;
    end
    else begin
      MessageBox(Handle, 'Укажите код', MesTitle, MB_OK + MB_ICONERROR);
      CodeComboBox.SetFocus;
    end;
  end;
end;

procedure TCashorderForm.DelBtnClick(Sender: TObject);
var
  R, C: Integer;
begin
  with SumStringGrid do
  begin
    SumStringGridClick(Sender);
    if DelBtn.Enabled then
    begin
      for R := Row+1 to RowCount-1 do
      begin
        for C := 0 to ColCount-1 do
          Cells[C, R-1] := Cells[C, R];
      end;
      if RowCount>2 then
        RowCount := RowCount - 1
      else
        for C := 0 to ColCount-1 do
          Cells[C, Row] := '';
      SumLabelDblClick(Sender);
      SumStringGridClick(Sender);
      OrderRadioGroupClick(Sender);
    end;
  end;
end;

procedure TCashorderForm.SumStringGridClick(Sender: TObject);
begin
  with SumStringGrid do
    DelBtn.Enabled := (Row>0) and (Cells[0, Row]<>'') and not FReadOnly;
  SumCalcEditChange(Sender);
end;

procedure TCashorderForm.SumStringGridSelectCell(Sender: TObject; ACol,
  ARow: Integer; var CanSelect: Boolean);
begin
  SumStringGridClick(Sender);
end;

procedure TCashorderForm.SumStringGridDrawCell(Sender: TObject; ACol,
  ARow: Integer; Rect: TRect; State: TGridDrawState);
var
  S: string;
  Size: TSize;
begin
  if (ACol=1) and (ARow>0) then
    with Sender as TDrawGrid do
    begin
      S := SumStringGrid.Cells[ACol, ARow];
      if Length(S)>0 then
      begin
        S := SumToStr(StrToFloat(S)*100.0);
        Size := Canvas.TextExtent(S);
        Canvas.TextRect(Rect, Rect.Right-Size.cx-3,
          (Rect.Bottom + Rect.Top - Size.cy) div 2, S);
      end;
    end;
end;

procedure TCashorderForm.CodeComboBoxDrawItem(Control: TWinControl;
  Index: Integer; Rect: TRect; State: TOwnerDrawState);
var
  S: string;
  Size: TSize;
begin
  with CodeComboBox do
  begin
    S := Items[Index]+' | '+StrPas(PChar(Items.Objects[Index]));
    if Length(S)>0 then
    begin
      Size := Canvas.TextExtent(S);
      Canvas.TextRect(Rect, Rect.Left+2,
        (Rect.Bottom + Rect.Top - Size.cy) div 2, S);
    end;
  end;
end;

procedure TCashorderForm.GetCodeIndex(ACode: Integer; var AnIndex, AType: Integer;
  var AName: string);
const
  MesTitle: PChar = 'Определение индекса кода';
var
  I, K, Err: Integer;
  S: string;
begin
  with CodeComboBox.Items do
  begin
    K := 0;
    Err := 0;
    I := 0;
    while (I<Count) and (Err=0) do
    begin
      AName := Strings[I];
      K := Pos('|', AName);
      if K>0 then
        S := Copy(AName, 1, K-1)
      else
        S := '';
      Val(TruncStr(S), AnIndex, Err);
      if Err=0 then
      begin
        if AnIndex=ACode then
          Err := -1;
      end
      else
        MessageBox(ParentWnd, PChar('Ошибочный код в списке кодов ['+S+']'),
          MesTitle, MB_OK + MB_ICONERROR);
      Inc(I);
    end;
    if Err<0 then
    begin
      AnIndex := I-1;
      System.Delete(AName, 1, K);
      if TruncStr(AName)[1]='Р' then
        AType := 1
      else
        AType := 0;
      K := Pos('|', AName);
      System.Delete(AName, 1, K);
    end
    else begin
      AnIndex := -1;
      AName := '<не определено>';
      AType := -1;
    end;
  end;
end;

function TCashorderForm.GetCodeType(ACode: Integer): Integer;
const
  MesTitle: PChar = 'Определение типа кода';
var
  AnIndex, I, K, Err: Integer;
  AName, S: string;
begin
  with CodeComboBox.Items do
  begin
    K := 0;
    Err := 0;
    I := 0;
    while (I<Count) and (Err=0) do
    begin
      AName := Strings[I];
      K := Pos('|', AName);
      if K>0 then
        S := Copy(AName, 1, K-1)
      else
        S := '';
      Val(TruncStr(S), AnIndex, Err);
      if Err=0 then
      begin
        if AnIndex=ACode then
          Err := -1;
      end
      else
        MessageBox(ParentWnd, PChar('Ошибочный код в списке кодов ['+S+']'),
          MesTitle, MB_OK + MB_ICONERROR);
      Inc(I);
    end;
    if Err<0 then
    begin
      System.Delete(AName, 1, K);
      if TruncStr(AName)[1]='Р' then
        Result := 1
      else
        Result := 0;
    end
    else
      Result := -1;
  end;
end;

procedure TCashorderForm.PutNazn(ANazn: string; var PayType: Integer);
const
  MesTitle: PChar = 'Расшифровка росписей';
var
  I, Code, Err: Integer;
  S, S2: string;
  Sum: Double;
begin                            
  I := Length(ANazn);
  while I>0 do
  begin
    if (ANazn[I]=#13) or (ANazn[I]=#10) then
      Delete(ANazn, I, 1);
    Dec(I);
  end;
  I := Length(ANazn);
  Code := 0;
  while (Code<I) and not (ANazn[Code+1] in ['0'..'9']) do
    Inc(Code);
  if Code>0 then
  begin
    Delete(ANazn, 1, Code);
    I := Length(ANazn);
  end;
  while I>0 do
  begin
    I := Pos(';', ANazn);
    if I>0 then
    begin
      S := Copy(ANazn, 1, I-1);
      Delete(ANazn, 1, I);
    end
    else begin
      S := ANazn;
      ANazn := ''
    end;
    I := Pos('-', S);
    if I>0 then
    begin
      S2 := TruncStr(Copy(S, 1, I-1));
      Val(S2, Code, Err);
      if Err<>0 then
        MessageBox(ParentWnd, PChar('Неверный код ['+S2+'] росписи ['+S+']'),
          MesTitle, MB_OK + MB_ICONERROR);
      S2 := TruncStr(Copy(S, I+1, Length(S)-I));
      Val(S2, Sum, Err);
      if Err<>0 then
        MessageBox(ParentWnd, PChar('Неверная сумма ['+S2+'] росписи ['+S+']'),
          MesTitle, MB_OK + MB_ICONERROR);
      with SumStringGrid do
      begin
        I := RowCount-1;
        if Length(Cells[0, I])>0 then
        begin
          RowCount := RowCount+1;
          Inc(I);
        end;
        Cells[0, I] := FillZeros(Code, 3);
        Cells[1, I] := FloatToStr(Sum);
        GetCodeIndex(Code, Err, PayType, S);
        Cells[2, I] := S;
      end;
    end
    else
      MessageBox(ParentWnd, PChar('В назначении платежа найдена недопустимая роспись ['
        +S+']'), MesTitle, MB_OK + MB_ICONERROR);
    I := Length(ANazn);
  end;
end;

procedure TCashorderForm.TakeNazn(var ANazn: string);
const
  MesTitle: PChar = 'Зашифровка росписей';
var
  R, Err, Code: Integer;
  Sum: Double;
  S: string;
begin
  ANazn := '';
  with SumStringGrid do
  begin
    R := 1;
    while R<RowCount do
    begin
      S := Cells[0, R];
      if Length(S)>0 then
      begin
        Val(S, Code, Err);
        if Err=0 then
        begin
          S := Cells[1, R];
          try
            Sum := StrToFloat(S);
            Err := 0;
          except
            Sum := 0;
            Err := 1
          end;
          if Err=0 then
          begin
            if Length(ANazn)>0 then
              ANazn := ANazn + ';';
            Str(Sum:0:2, S);
            ANazn := ANazn + FillZeros(Code, 2) + '-' + S;
          end
          else
            MessageBox(ParentWnd, PChar('Ошибочная сумма в таблице ['+S+']'),
              MesTitle, MB_OK + MB_ICONERROR)
        end
        else
          MessageBox(ParentWnd, PChar('Ошибочный код в таблице ['+S+']'),
            MesTitle, MB_OK + MB_ICONERROR)
      end;
      Inc(R);
    end;
  end;
end;

procedure TCashorderForm.IndexComboBoxClick(Sender: TObject);
var
  FS, S: string;
  I, J, K, C: Integer;
  Change: Boolean;
  Sum1, Sum2: Double;
begin
  Sum1 := 0;
  Sum2 := 0;
  with SumStringGrid do
  begin
    FS := Cells[0, Row];
    C := RowCount-1;
    for I := 1 to C-1 do
    begin
      if Length(Cells[0, I])>0 then
        for J := I+1 to C do
        begin
          case IndexComboBox.ItemIndex of
            0: Change := Cells[0, J]<Cells[0, I];
            1:
              begin
                try
                  Sum1 := StrToFloat(Cells[1, J]);
                  Sum2 := StrToFloat(Cells[1, I]);
                except
                  MessageBox(ParentWnd, PChar('Ошибочная сумма в таблице'),
                    'Упорядочение по индексу', MB_OK + MB_ICONERROR)
                end;
                Change := Sum1<Sum2;
              end;
            else
              Change := False;
          end;
          if Change then
          begin
            for K := 0 to 2 do
            begin
              S := Cells[K, I];
              Cells[K, I] := Cells[K, J];
              Cells[K, J] := S;
            end;
          end;
        end;
    end;
    I := 1;
    while (I<C) and (Cells[0, I]<>FS) do
      Inc(I);
    Row := I;
  end;
end;

procedure TCashorderForm.SumCalcEditChange(Sender: TObject);
var
  Code, I, J, Err: Integer;
  S: string;
begin
  S := CodeComboBox.Text;
  AddBtn.Enabled := (Length(S)>0) and not FReadOnly;
  if AddBtn.Enabled then
  begin
    Val(S, Code, Err);
    AddBtn.Enabled := Err=0;
    if AddBtn.Enabled then
    begin
      Err := 1;
      GetCodeIndex(Code, I, J, S);
      AddBtn.Enabled := (I>=0) and ((OrderRadioGroup.ItemIndex<0)
        or (OrderRadioGroup.ItemIndex=J));
      if AddBtn.Enabled then
        with SumStringGrid do
        begin
          Err := 1;
          I := 1;
          while (I<RowCount) and (Err<>0) do
          begin
            Val(Cells[0, I], J, Err);
            if (Err=0) and (J<>Code) then
              Err := 1;
            Inc(I);
          end;
        end;
      if Err=0 then
        AddBtn.Caption := 'Заменить'
      else
        AddBtn.Caption := 'Добавить';
      AddBtn.Enabled := AddBtn.Enabled and (SumCalcEdit.Value>0);
    end;
  end;
end;

procedure TCashorderForm.SumStringGridDblClick(Sender: TObject);
begin
  with SumStringGrid do
  begin
    if Length(Cells[0, Row])>0 then
    begin
      CodeComboBox.Text := Cells[0, Row];
      SumCalcEdit.Value := StrToFloat(Cells[1, Row]);
      SumStringGridClick(Sender);
    end;
  end;
end;

procedure TCashorderForm.SumLabelDblClick(Sender: TObject);
var
  R: Integer;
  S: string;
begin
  with SumStringGrid do
  begin
    SumEdit.Value := 0;
    for R := 1 to RowCount-1 do
    begin
      S := Cells[1, R];
      if Length(S)>0 then
        try
          SumEdit.Value := SumEdit.Value + StrToFloat(S);
        except
          MessageBox(Handle, 'Ошибка оцифрения', 'Вычисление суммы',
            MB_OK + MB_ICONERROR);
        end;
    end;
  end;
end;

procedure TCashorderForm.OrderRadioGroupClick(Sender: TObject);
var
  Code, Err: Integer;
begin
  with SumStringGrid do
  begin
    if (Row>0) and (Length(Cells[0, Row])>0) then
    begin
      Val(Cells[0, Row], Code, Err);
      OrderRadioGroup.ItemIndex := GetCodeType(Code);
    end
    else
      OrderRadioGroup.ItemIndex := -1;
  end;
  case OrderRadioGroup.ItemIndex of
    0: ClientGroupBox.Caption := 'Получатель';
    1: ClientGroupBox.Caption := 'Плательщик';
    else
      ClientGroupBox.Caption := 'Клиент';
  end;
  if OrderRadioGroup.ItemIndex=1 then
  begin
    DebInd := 0;
    CredInd := 1;
    //Добавлено Меркуловым
    FIOEdit.ParentColor := True;
    FIOEdit.ReadOnly := True;
    PasSerialEdit.ParentColor := False;
    PasSerialEdit.Color := clWindow;
    PasSerialEdit.ReadOnly := False;
    PasNumberEdit.ParentColor := False;
    PasNumberEdit.Color := clWindow;
    PasNumberEdit.ReadOnly := False;
    PasPlaceMemo.ParentColor := False;
    PasPlaceMemo.Color := clWindow;
    PasPlaceMemo.ReadOnly := False;
  end
  else begin
    DebInd := 1;
    CredInd := 0;
    //Добавлено Меркуловым
    FIOEdit.ParentColor := False;
    FIOEdit.Color := clWindow;
    FIOEdit.ReadOnly := False;
    PasSerialEdit.ParentColor := True;
    PasSerialEdit.ReadOnly := True;
    PasNumberEdit.ParentColor := True;
    PasNumberEdit.ReadOnly := True;
    PasPlaceMemo.ParentColor := True;
    PasPlaceMemo.ReadOnly := True;
  end
end;

procedure TCashorderForm.ChangeDebitCredit;
var
  AParticipant: TParticipant;
begin
  AParticipant := Participants[0];
  Participants[0] := Participants[1];
  Participants[1] := AParticipant;
end;

procedure TCashorderForm.ClientMemoKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (Key=VK_RETURN) and (Shift=[ssCtrl]) then
    ModalResult := mrOk;
end;

procedure TCashorderForm.CashAccPanelClick(Sender: TObject);
var
  Url: array[0..511] of Char;
begin
  if not FReadOnly then
  begin
    StrPLCopy(Url, CashAccFile, SizeOf(Url));
    Screen.Cursor := crHourGlass;
    ShellExecute(Application.Handle, nil, @Url, nil, nil,
      SW_SHOWNORMAL);
    Screen.Cursor := crDefault;
    MessageBox(Handle, 'Изменения начнут действовать при следующем открытии кассового ордера',
      PChar(Caption), MB_OK or MB_ICONWARNING);
    try
      CashAccComboBox.Items.LoadFromFile(CashAccFile);
    except
    end;
  end;
end;

end.
