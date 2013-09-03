unit AccountsFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Grids, Db, DBTables, DBGrids, ExtCtrls, DBCtrls, BtrDS, Menus, SearchFrm,
  StdCtrls, Buttons, ComCtrls, Common, Utilits, Bases, CommCons, Registr,
  AccWorkFrm, Mask, ToolEdit, ClntCons, DocFunc;

type
  TAccountsForm = class(TDataBaseForm)
    DataSource: TDataSource;
    DBGrid: TDBGrid;
    EditMenu: TMainMenu;
    FuncItem: TMenuItem;
    FindItem: TMenuItem;
    FuncBreaker: TMenuItem;
    ArcAccItem: TMenuItem;
    EditPopupMenu: TPopupMenu;
    BtnPanel: TPanel;
    NameLabel: TLabel;
    SearchIndexComboBox: TComboBox;
    NameEdit: TEdit;
    ChildStatusBar: TStatusBar;
    AccWorkList: TMenuItem;
    FuncBreaker1: TMenuItem;
    MakesItem: TMenuItem;
    MakesAllItem: TMenuItem;
    FromDateLabel: TLabel;
    FromDateEdit: TDateEdit;
    ToDateEdit: TDateEdit;
    ToDateLabel: TLabel;
    ExportAllBills: TGroupBox;
    ExportAllBillBitBtn: TBitBtn;
    BackPanel: TPanel;
    AbortBitBtn: TBitBtn;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ArcAccItemClick(Sender: TObject);
    procedure FindItemClick(Sender: TObject);
    procedure SearchIndexComboBoxClick(Sender: TObject);
    procedure NameEditChange(Sender: TObject);
    procedure AccWorkListClick(Sender: TObject);
    procedure MakesItemClick(Sender: TObject);
    procedure MakesAllItemClick(Sender: TObject);
    procedure DBGridDrawColumnCell(Sender: TObject; const Rect: TRect;
      DataCol: Integer; Column: TColumn; State: TGridDrawState);
    procedure NameEditKeyPress(Sender: TObject; var Key: Char);
    procedure DBGridKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure ExportAllBillBitBtnClick(Sender: TObject);
    procedure BackPanelClick(Sender: TObject);
    procedure BackPanelMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure BackPanelMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure AbortBitBtnClick(Sender: TObject);
  private
    SearchForm: TSearchForm;
    AccDataSet, DocDataSet, BillDataSet: TExtBtrDataSet;
  public
    {procedure TakeFormPrintData(var GraphForm, TextForm: TFileName;
      var DBGrid: TDBGrid); override;}
    procedure StatusMessage(S: string);
    procedure TakeTabPrintData(var PrintDocRec: TPrintDocRec; var FormList: TList); override;
    procedure DoMakes(Caller: Pointer; Acc: string; ADate: TDateTime);
  end;

const
  AccountsForm: TAccountsForm = nil;
var
  ObjList: TList;

implementation

uses ArchAccsFrm, MakesFrm, MakesAllFrm;

{$R *.DFM}

procedure TAccountsForm.FormCreate(Sender: TObject);
var
  BtrDate, BtrDate2: Word;
begin
  ObjList.Add(Self);
  TakeMenuItems(FuncItem, EditPopupMenu.Items);
  EditPopupMenu.Images := EditMenu.Images;

  AccDataSet := GlobalBase(biAcc);
  BillDataSet := GlobalBase(biBill);
  DocDataSet := GlobalBase(biPay);

  DataSource.DataSet := AccDataSet;
  SearchForm := TSearchForm.Create(Self);
  DefineGridCaptions(DBGrid, PatternDir+'Accounts.tab');
  SearchForm.SourceDBGrid := DBGrid;
  SearchIndexComboBox.ItemIndex := 1;
  SearchIndexComboBoxClick(Sender);

  BtrDate := DateToBtrDate(Date);
  BtrDate2 := GetPrevWorkDay(BtrDate, nil);
  if BtrDate2<>0 then
    BtrDate := BtrDate2;
  if BtrDate<>0 then
  begin
    FromDateEdit.Date := BtrDateToDate(BtrDate);
    ToDateEdit.Date := FromDateEdit.Date;
  end;
end;

procedure TAccountsForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action:=caFree;
end;

procedure TAccountsForm.FormDestroy(Sender: TObject);
begin
  ObjList.Remove(Self);
  AccountsForm := nil;
end;

procedure TAccountsForm.TakeTabPrintData(var PrintDocRec: TPrintDocRec; var FormList: TList);
begin
  inherited;
  PrintDocRec.DBGrid := Self.DBGrid;
  PrintDocRec.GraphForm := DecodeMask('$(AccountsGraphForm)', 5, CommonUserNumber);
  PrintDocRec.TextForm := DecodeMask('$(AccountsTextForm)', 5, CommonUserNumber);
end;

procedure TAccountsForm.ArcAccItemClick(Sender: TObject);
begin
  if ArchAccsForm = nil then
    ArchAccsForm := TArchAccsForm.Create(Self)
  else
    ArchAccsForm.Show;
end;

procedure TAccountsForm.FindItemClick(Sender: TObject);
begin
  SearchForm.ShowModal;
end;

procedure TAccountsForm.SearchIndexComboBoxClick(Sender: TObject);
begin
  (DataSource.DataSet as TBtrDataSet).IndexNum := SearchIndexComboBox.ItemIndex;
  case SearchIndexComboBox.ItemIndex of
    1: NameEdit.MaxLength := SizeOf(TAccount);
    else
      NameEdit.MaxLength := 15
  end;
end;

var
  Acc: array[0..SizeOf(TAccount)] of Char;

procedure TAccountsForm.NameEditChange(Sender: TObject);
var
  I, J: Integer;
begin
  with TBtrDataSet(DataSource.DataSet) do
    case SearchIndexComboBox.ItemIndex of
      0,2:
        begin
          Val(NameEdit.Text, I, J);
          if J=0 then
            LocateBtrRecordByIndex(I, SearchIndexComboBox.ItemIndex, bsGe);
        end;
      1:
        begin                 
          FillChar(Acc, SizeOf(Acc), #0);
          StrPLCopy(Acc, NameEdit.Text, SizeOf(Acc)-1);
          LocateBtrRecordByIndex(Acc, 1, bsGe);
        end;
    end;
end;

procedure TAccountsForm.AccWorkListClick(Sender: TObject);
begin
  if AccWorkForm = nil then
    AccWorkForm := TAccWorkForm.Create(Self)
  else
    AccWorkForm.Show;
end;

procedure TAccountsForm.DoMakes(Caller: Pointer; Acc: string; ADate: TDateTime);
var
  A: Boolean;
begin
  if Length(Acc)>0 then
  begin
    if MakesForm = nil then
      MakesForm := TMakesForm.Create(Self);
    with MakesForm do
    begin
      Show;
      MakesForm.SetCallerForm(Caller);
      if not OneDayItem.Checked then
        OneDayItemClick(nil);
      A := True;
      AccEdit.Text := Acc;
      if ADate=0 then
        ADate := MakesForm.FromDateEdit.Date;
      FromDateEditAcceptDate(nil, ADate, A);
      {FromDateEdit.Date := ADate;
      ToDateEdit.Date := ADate;}
      {PostMessage(MakesForm.Handle, WM_MAKESTATEMENT, 0, 0);}
    end;
  end;
end;

procedure TAccountsForm.MakesItemClick(Sender: TObject);
var
  AccRec: TAccRec;
begin
  if not DataSource.DataSet.IsEmpty then
  begin
    TExtBtrDataSet(DataSource.DataSet).GetBtrRecord(@AccRec);
    DoMakes(@AccountsForm, AccRec.arAccount, 0);
  end;
end;

procedure TAccountsForm.MakesAllItemClick(Sender: TObject);
begin
  if MakesAllForm = nil then
    MakesAllForm := TMakesAllForm.Create(Self)
  else
    MakesAllForm.Show;
end;

procedure TAccountsForm.DBGridDrawColumnCell(Sender: TObject;
  const Rect: TRect; DataCol: Integer; Column: TColumn;
  State: TGridDrawState);
var
  C: TColor;
begin
  if (Column.Field<>nil) and (Column.Field.FieldName='arDateC')
    and (Length(Column.Field.AsString)>0) then
  begin
    with (Sender as TDBGrid).Canvas do
    begin
      C := clRed;
      if (Brush.Color<>clHighlight)
        and (ColorToRGB(C) <> ColorToRGB(Brush.Color))
      then
        Font.Color := C;
      TextRect(Rect, Rect.Left+2, Rect.Top+2, Column.Field.AsString);
      {if ColorToRGB(C) <> ColorToRGB(Brush.Color) then
        Font.Color := C;
      TextRect(Rect, Rect.Left+2, Rect.Top+2, S);}
    end;
  end;
end;

procedure TAccountsForm.NameEditKeyPress(Sender: TObject; var Key: Char);
begin
  if not ((Key in ['0'..'9']) or (Key < #32)) then
  begin
    Key := #0;
    MessageBeep(0)
  end;
end;

procedure TAccountsForm.DBGridKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  case Key of
    VK_RETURN:
      MakesItemClick(nil);
    VK_DELETE:
      if (ssCtrl in Shift) and (MessageBox(Handle,
        '���������� � ����� ����� �������. �� �������?',
        '��������', MB_ICONWARNING or MB_YESNOCANCEL or MB_DEFBUTTON2)=ID_YES)
      then
        DBGrid.DataSource.DataSet.Delete;
  end;
end;

procedure TAccountsForm.StatusMessage(S: string);
begin
  ChildStatusBar.Panels[1].Text := S;
end;

procedure TAccountsForm.ExportAllBillBitBtnClick(Sender: TObject);
const
  MesTitle: PChar = '�������� �������';
var
  OpRec: TOpRec;
  Len, Res, CF, CB, I: Integer;
  BtrDate1, BtrDate2, BtrDate3: Word;
  ExpPath, FN, Acc: string;
  AccList: TStringList;
  KeyA: TAccount;
  PayRec: TPayRec;
  AccRec: TAccRec;
  F: TextFile;
  S, M, Srok, Ocher,
    Number, DebitRs, DebitKs, DebitBik, DebitInn, DebitName, DebitBank,
    CreditRs, CreditKs, CreditBik, CreditInn, CreditName, CreditBank,
    Purpose, DebitKpp, CreditKpp, Status, Kbk, Okato, OsnPl, Period, NDoc,
    DocDate, TipPl, Nchpl, Shifr, Nplat, OstSum: string;
  CorrRes: Integer;
begin
  try
    BtrDate1 := DateToBtrDate(FromDateEdit.Date);
  except
    BtrDate1 := 0;
  end;
  try
    BtrDate2 := DateToBtrDate(ToDateEdit.Date);
  except
    BtrDate2 := 0;
  end;
  if (BtrDate1<>0) or (BtrDate2<>0) then
  begin
    if BtrDate1=0 then
      BtrDate1 := BtrDate2;
    if BtrDate2=0 then
      BtrDate2 := BtrDate1;
    if BtrDate1>BtrDate2 then
    begin
      BtrDate3 := BtrDate2;
      BtrDate2 := BtrDate1;
      BtrDate1 := BtrDate3;
    end;

    FN := DecodeMask('$(BillExpFile)', 5, CommonUserNumber);
    ExpPath := ExtractFilePath(FN);
    NormalizeDir(ExpPath);
    if DirExists(ExpPath) then
    try
      StatusMessage('���������� �������...');
      AccList := TStringList.Create;
      AbortBitBtn.Visible := True;
      AbortBitBtn.Enabled := True;
      CF := 0;
      CB := 0;
      Len := SizeOf(AccRec);
      Res := AccDataSet.BtrBase.GetFirst(AccRec, Len, KeyA, 1);
      while (Res=0) and AbortBitBtn.Enabled do
      begin
        Acc := StrPas(AccRec.arAccount);
        Acc := Copy(Acc, 1, SizeOf(TAccount));
        BtrDate3 := BtrDate1;
        Len := SizeOf(OpRec);
        Res := BillDataSet.BtrBase.GetGE(OpRec, Len, BtrDate3, 2);
        while (Res=0) and (OpRec.brDate<=BtrDate2) do
        begin
          if (OpRec.brDel=0) and (OpRec.brPrizn=brtBill)
            and ((StrLComp(OpRec.brAccD, AccRec.arAccount, SizeOf(TAccount))=0)
              or (StrLComp(OpRec.brAccC, AccRec.arAccount, SizeOf(TAccount))=0))
            and AbortBitBtn.Enabled then
          begin   // ��� �������� � ��� �� �������
            FN := ExpPath+Acc+'.txt';
            AssignFile(F, FN);
            {$I-}
            if AccList.IndexOf(Acc)<0 then
            begin
              AccList.Add(Acc);
              Rewrite(F);
              Save1sCaption(F, BtrDateToStr(BtrDate1), BtrDateToStr(BtrDate2), Acc);
              Inc(CF);
            end
            else
              Append(F);
            {$I+}
            if IOResult=0 then
            try
              I := OpRec.brDocId;
              Len := SizeOf(PayRec);
              Res := DocDataSet.BtrBase.GetEqual(PayRec, Len, I, 1);
              if Res=0 then
              begin
                DecodeDocVar(PayRec.dbDoc, PayRec.dbDocVarLen, Number,
                  DebitRs, DebitKs, DebitBik, DebitInn, DebitName, DebitBank,
                  CreditRs, CreditKs, CreditBik, CreditInn, CreditName, CreditBank,
                  Purpose, DebitKpp, CreditKpp, Status, Kbk, Okato, OsnPl, Period, NDoc,
                  DocDate, TipPl, Nchpl, Shifr, Nplat, OstSum, 0, 2, CorrRes, False);
                Srok := BtrDateToStr(PayRec.dbDoc.drSrok);
                Ocher := FillZeros(PayRec.dbDoc.drOcher, 2);
              end
              else begin
                with OpRec do
                begin
                  Number := IntToStr(OpRec.brNumber);
                  DebitRs := OpRec.brAccD;
                  CreditRs := OpRec.brAccC;
                  Purpose := OpRec.brText;

                  Srok := '';
                  Ocher := '';
                  DebitKs     := '';
                  DebitBik    := '';
                  DebitInn    := '';
                  DebitName   := '';
                  DebitBank   := '';
                  CreditKs    := '';
                  CreditBik   := '';
                  CreditInn   := '';
                  CreditName  := '';
                  CreditBank  := '';
                  DebitKpp    := '';
                  CreditKpp   := '';
                  Status      := '';
                  Kbk         := '';
                  Okato       := '';
                  OsnPl       := '';
                  Period      := '';
                  NDoc        := '';
                  DocDate     := '';
                  TipPl       := '';
                  Nchpl       := '';
                  Shifr       := '';
                  Nplat       := '';
                  OstSum      := '';
                end;
              end;
              case OpRec.brType of
                3:
                  WriteLn(F, '��������������=�������� �����');
                9:
                  WriteLn(F, '��������������=������������ �����');
                2:
                  WriteLn(F, '��������������=��������� �����');
                else
                  WriteLn(F, '��������������=��������� ���������');
              end;
              WriteLn(F, '�����='+Number);
              WriteLn(F, '����='+BtrDateToStr(OpRec.brDate));
              Str(OpRec.brSum*0.01:0:2, S);
              WriteLn(F, '�����='+S);
              WriteLn(F, '��������������='+DebitRs);
              WriteLn(F, '�������������='+DebitInn);
              WriteLn(F, '�������������='+DebitKpp);
              DisperseStr(DebitName, '����������', S, M);
              Write(F, M);
              WriteLn(F, '������������������='+DebitRs);
              DisperseStr(DebitBank, '��������������', S, M);
              Write(F, M);
              WriteLn(F, '�������������='+DebitBik);
              WriteLn(F, '�����������������='+DebitKs);
              WriteLn(F, '��������������='+CreditRs);
              WriteLn(F, '�������������='+BtrDateToStr(OpRec.brDate));
              WriteLn(F, '�������������='+CreditInn);  
              WriteLn(F, '�������������='+CreditKpp);  
              DisperseStr(CreditName, '����������', S, M);  
              Write(F, M);  
              WriteLn(F, '������������������='+CreditRs);  
              DisperseStr(CreditBank, '��������������', S, M);  
              Write(F, M);  
              WriteLn(F, '�������������='+CreditBik);  
              WriteLn(F, '�����������������='+CreditKs);  
              WriteLn(F, '����������=����������');  
              WriteLn(F, '���������='+FillZeros(OpRec.brType, 2));  
              WriteLn(F, '�����������������='+Status);  
              WriteLn(F, '�������������='+Kbk);  
              WriteLn(F, '�����='+Okato);  
              WriteLn(F, '�������������������='+OsnPl);  
              WriteLn(F, '�����������������='+Period);  
              WriteLn(F, '����������������='+NDoc);  
              WriteLn(F, '��������������='+DocDate);  
              WriteLn(F, '��������������='+TipPl);  
              WriteLn(F, '�����������='+BtrDateToStr(PayRec.dbDoc.drSrok));  
              WriteLn(F, '�����������='+FillZeros(PayRec.dbDoc.drOcher, 2));
              DisperseStr(Purpose, '�����������������', S, M);
              WriteLn(F, '�����������������='+S);
              if Length(M)>0 then
                Write(F, M);
              WriteLn(F, '��������������');
              
              Inc(CB);
            finally
              CloseFile(F);
            end
            else
              MessageBox(Handle, PChar('�� ���� �������/�������� ['+FN+']'),
                MesTitle, MB_OK or MB_ICONERROR)
          end;
          Len := SizeOf(OpRec);
          Res := BillDataSet.BtrBase.GetNext(OpRec, Len, BtrDate3, 2);
          Application.ProcessMessages;
        end;
        Len := SizeOf(AccRec);
        Res := AccDataSet.BtrBase.GetNext(AccRec, Len, KeyA, 1);
      end;
      StatusMessage('');
      AbortBitBtn.Visible := False;
      if AbortBitBtn.Enabled then
        MessageBox(Handle, PChar('������� ������ �������: '+IntToStr(CF)+#13#10
          +'����� ��������� ��������: '+IntToStr(CB)),
          MesTitle, MB_OK or MB_ICONINFORMATION)
      else
        MessageBox(Handle, PChar('������� �������. ������� ������ �������: '+IntToStr(CF)+#13#10
          +'����� ��������� �������� '+IntToStr(CB)),
          MesTitle, MB_OK or MB_ICONWARNING);
    finally
      AccList.Free;
      AbortBitBtn.Visible := False;
    end
    else
      MessageBox(Handle, PChar('���� ��� �������� �� ����������'#13#10'['
        +ExpPath+']'#13#10'������� ���� "������-���������-�������-���� ��� �������� ������� (��� �������)"'),
        MesTitle, MB_OK or MB_ICONWARNING);
  end
  else
    MessageBox(Handle, '�������� ��� �� ���������', MesTitle, MB_OK or MB_ICONWARNING);
end;

procedure TAccountsForm.BackPanelClick(Sender: TObject);
var
  BtrDate: Word;
begin
  try
    BtrDate := DateToBtrDate(FromDateEdit.Date);
  except
    BtrDate := 0;
  end;
  if BtrDate=0 then
    BtrDate := DateToBtrDate(Date);
  if BtrDate<>0 then
  begin
    BtrDate := GetPrevWorkDay(BtrDate, nil);
    if BtrDate<>0 then
      FromDateEdit.Date := BtrDateToDate(BtrDate)
    else
      MessageBox(Handle, '���������� ������� �� �������',
        '����� ��������', MB_OK or MB_ICONWARNING);
  end;
end;

procedure TAccountsForm.BackPanelMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button=mbLeft then
    (Sender as TPanel).BevelOuter := bvLowered;
end;

procedure TAccountsForm.BackPanelMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  (Sender as TPanel).BevelOuter := bvRaised;
end;

procedure TAccountsForm.AbortBitBtnClick(Sender: TObject);
begin
  AbortBitBtn.Enabled := False;
end;

end.

