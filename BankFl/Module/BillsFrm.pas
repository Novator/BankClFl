unit BillsFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Grids, Db, DBTables, DBGrids, ExtCtrls, DBCtrls, BtrDS, Menus,
  StdCtrls, Buttons, ComCtrls, SearchFrm, {Sign, }PaydocsFrm, Common, Basbn,
  Utilits, CommCons, BillFrm, BankCnBn;

type
  TBillsForm = class(TDataBaseForm)
    DataSource: TDataSource;
    DBGrid: TDBGrid;
    StatusBar: TStatusBar;
    BtnPanel: TPanel;
    NameEdit: TEdit;
    SearchIndexComboBox: TComboBox;
    MainMenu: TMainMenu;
    OperItem: TMenuItem;
    FindItem: TMenuItem;
    SeeItem: TMenuItem;
    EditBreaker: TMenuItem;
    NameLabel: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure NameEditChange(Sender: TObject);
    procedure FindItemClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure SeeItemClick(Sender: TObject);
    procedure SearchIndexComboBoxClick(Sender: TObject);
  private
    procedure UpdateBill(CopyCurrent, New: Boolean);
  public
    SearchForm: TSearchForm;
  end;

var
  BillsForm: TBillsForm;

implementation

{$R *.DFM}

var
  PayDataSet: TExtBtrDataSet = nil;

procedure TBillsForm.FormCreate(Sender: TObject);
begin
  DataSource.DataSet := GlobalBase(biBill);
  PayDataSet := GlobalBase(biPay);
  DefineGridCaptions(DBGrid, PatternDir+'Bills.tab');
  SearchForm:=TSearchForm.Create(Self);
  SearchIndexComboBox.ItemIndex:=0;
  SearchIndexComboBoxClick(nil);
  SearchForm.SourceDBGrid := DBGrid;
end;

procedure TBillsForm.FormDestroy(Sender: TObject);
begin
  BillsForm := nil;
end;

procedure TBillsForm.NameEditChange(Sender: TObject);
var
  T: array[0..512] of Char;
  I, Err: LongInt;
  S: string;
  D: Word;
begin
  case SearchIndexComboBox.ItemIndex of
    0, 1:
    begin
      Val(NameEdit.Text, I, Err);
      if Err=0 then
        TBtrDataSet(DataSource.DataSet).LocateBtrRecordByIndex(I,
          SearchIndexComboBox.ItemIndex, bsGe);
    end;
    2: begin
      D := StrToBtrDate(NameEdit.Text);
      TBtrDataSet(DataSource.DataSet).LocateBtrRecordByIndex(D, 2, bsGe);
    end;
  end;
end;

procedure TBillsForm.FindItemClick(Sender: TObject);
begin
  SearchForm.ShowModal;
end;

procedure TBillsForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if FormStyle=fsMDIChild then Action:=caFree;
end;

procedure TBillsForm.UpdateBill(CopyCurrent, New: Boolean);
var
  OpRec: TOpRec;
  Err: Integer;
  T: array[0..512] of Char;
begin
(*  BillForm := TBillForm.Create(Self);
  with BillForm do begin
    if CopyCurrent then
      TBillDataSet(DataSource.DataSet).GetBtrRecord(PChar(@OpRec))
    else
      FillChar(OpRec,SizeOf(OpRec),#0);
    with OpRec do begin
      DosToWin(clNameC);
      StrLCopy(T,clAccC,SizeOf(clAccC));
      RsEdit.Text := StrPas(T);
      BikEdit.Text := IntToStr(clCodeB);
      StrLCopy(T,clInn,SizeOf(clInn));
      InnEdit.Text := StrPas(T);
      NameMemo.Text := StrPas(clNameC);
    end;
    if ShowModal = mrOk then begin
      with OpRec do begin
        StrPCopy(clAccC,RsEdit.Text);
        Val(BikEdit.Text,clCodeB,Err);
        StrPCopy(clInn,InnEdit.Text);
        StrPCopy(clNameC,NameMemo.Text);
        WinToDos(clNameC);
      end;
      if New then begin
        if TBillDataSet(DataSource.DataSet).AddBtrRecord(PChar(@OpRec),
          SizeOf(OpRec))
        then
          DataSource.DataSet.Refresh
        else
          MessageBox(Handle, 'Невозможно добавить запись', 'Редактирование',
            MB_OK + MB_ICONERROR);
      end else begin
        if TBillDataSet(DataSource.DataSet).UpdateBtrRecord(PChar(@OpRec),
          SizeOf(OpRec))
        then
          {          DataSource.DataSet.Refresh}
          DataSource.DataSet.UpdateCursorPos
        else
          MessageBox(Handle, 'Невозможно изменить запись', 'Редактирование',
            MB_OK + MB_ICONERROR);
      end;
    end;
    Free;
  end;*)
end;

procedure TBillsForm.SeeItemClick(Sender: TObject);
const
  MesTitle: PChar = 'Состояние документа';
var
  BillRec: TOpRec;
  Res, LenB, LenD, DocSender: Integer;
  BillForm: TBillForm;
  Editing, ChangeStatus: Boolean;
  Buf: array[0..511] of Char;
  I: Integer;
  W: Word;
  BankPayRec: TBankPayRec;
begin
  with TBillDataSet(DataSource.DataSet) do
  begin
    LenB := GetBtrRecord(@BillRec);
    if LenB>0 then
    begin
      I := BillRec.brDocId;
      LenD := SizeOf(BankPayRec);
      Res := PayDataSet.BtrBase.GetEqual(BankPayRec, LenD, I, 0);
      if Res=0 then
        DocSender := BankPayRec.dbIdSender
      else
        DocSender := 0;
      BillForm := TBillForm.Create(Self);
      with BillForm do
      begin
        Caption := 'Состояние операции';
        //if GetOperNum<>1 then
          LockAllControls;
        UpdateDocCheckBox.Enabled := False;
        InputCheckBox.Enabled := False;
        ToExportCheckBox.Enabled := False;
        SignCheckBox.Enabled := False;
        MailComboBox.Enabled := False;
        MailComboBox.ParentColor := True;

        UpdateBillCheckBox.Enabled := True;
        BillPanel.Visible := True;
        with BillRec do
        begin
          if (0<=brPrizn) and (brPrizn<=2) then
            PriznComboBox.ItemIndex := brPrizn;
          DateEdit.Text := BtrDateToStr(brDate);
          if brDel=0 then
            DelComboBox.ItemIndex := 0
          else
            DelComboBox.ItemIndex := 1;
          DebitComboBox.ItemIndex := (brState and dsAnsType) shr 4;
          CreditComboBox.ItemIndex := (brState and dsReSndType) shr 6;
          SenderComboBox.ItemIndex := brState and dsSndType;
          VerSpinEdit.Value := brVersion;
          LenB := LenB - 17;
          if LenB>SizeOf(Buf) then
            LenB := SizeOf(Buf);
          case brPrizn of
            brtBill:
              begin
                LenB := LenB-53;
                if LenB<0 then
                  LenB := 0;
                StrLCopy(Buf, brText, LenB);
                DosToWinL(Buf, SizeOf(Buf));
                NameEdit.Text := StrPas(Buf);
                NumberEdit.Text := IntToStr(brNumber);
                VidComboBox.Text := IntToStr(brType);
                DebetAccEdit.Text := Copy(StrPas(brAccD), 1, SizeOf(brAccD));
                CreditAccEdit.Text := Copy(StrPas(brAccC), 1, SizeOf(brAccC));
                SumCalcEdit.Value := brSum / 100.0;
              end;
            brtReturn:
              begin
                StrLCopy(Buf, brRet, LenB);
                DosToWinL(Buf, SizeOf(Buf));
                NameEdit.Text := Buf;
              end;
          end;
        end;
        PriznComboBoxChange(nil);
        UpdateBillCheckBox.Checked := False;
        VerSpinEdit.Font.Color := clBlack;
        OpIdLabel.Caption := 'Id='+IntToStr(BillRec.brIder);
        Editing := True;
        while Editing and (ShowModal = mrOk) and not ReadOnly do
        begin
          if UpdateBillCheckBox.Checked then
          begin
            (*
            with BillRec do
            begin
              LenB := 17;
              brDate := DateToBtrDate(DateEdit.Date);
              brPrizn := PriznComboBox.ItemIndex;
              case brPrizn of
                brtBill:
                  begin
                    brNumber := StrToInt(NumberEdit.Text);
                    brType := StrToInt(VidComboBox.Text);
                    StrPLCopy(brAccD, DebetAccEdit.Text, SizeOf(brAccD));
                    StrPLCopy(brAccC, CreditAccEdit.Text, SizeOf(brAccC));
                    brSum := SumCalcEdit.Value * 100;
                    StrPLCopy(Buf, NameEdit.Text, SizeOf(Buf)-1);
                    WinToDosL(Buf, SizeOf(Buf));
                    StrPLCopy(brText, Buf, SizeOf(brText)-1);
                    LenB := LenB + 53 + StrLen(brText) + 1;
                  end;
                brtReturn:
                  begin
                    StrPLCopy(Buf, NameEdit.Text, SizeOf(brRet)-1);
                    WinToDosL(Buf, SizeOf(Buf));
                    StrPLCopy(brRet, Buf, SizeOf(brRet)-1);
                    LenB := LenB + StrLen(brRet) + 1;
                  end;
              end;
              brState := 0;
              if not NewBill then
              begin
                brState := brState or SenderComboBox.ItemIndex;
                brState := brState or (DebitComboBox.ItemIndex shl 4);
                brState := brState or (CreditComboBox.ItemIndex shl 6);
              end;
              brVersion := VerSpinEdit.Value;
              ChangeStatus := NewBill or (brDel<>0) and (DelComboBox.ItemIndex=0)
                or (brDel=0) and (DelComboBox.ItemIndex=1);
              if DelComboBox.ItemIndex=0 then
                brDel := 0
              else
                brDel := 1;
              if ChangeStatus then
              begin
                if NewBill or (brDel=0) then
                begin
                  if not CorrectOpSum(brAccD, brAccC, 0, Round(brSum), brDate,
                    DocSender, W, nil)
                  then
                    MessageBox(Application.Handle,
                      PChar('Не удалось обновить состояние счетов'),
                      MesTitle, MB_OK or MB_ICONERROR);
                end
                else
                  if not DeleteOp(BillRec, BankPayRec.dbIdSender) then
                    MessageBox(Application.Handle,
                      PChar('Не удалось обновить состояние счетов'),
                      MesTitle, MB_OK or MB_ICONERROR);
              end;
            end;
            I := BillRec.brIder;
            Res := BtrBase.Update(BillRec, LenB, I, 0);
            if Res=0 then
              UpdateCursorPos
            else *)  Res := -111;
              MessageBox(Application.Handle,
                PChar('Не удалось обновить операцию BtrErr='+IntToStr(Res)),
                MesTitle, MB_OK or MB_ICONERROR);
          end;
          Editing := False;
        end;
        Free;
      end;
    end
  end;
end;

procedure TBillsForm.SearchIndexComboBoxClick(Sender: TObject);
begin
  (DataSource.DataSet as TBtrDataSet).IndexNum:=SearchIndexComboBox.ItemIndex;
  NameEdit.Visible := SearchIndexComboBox.ItemIndex <> 2;
end;

end.
