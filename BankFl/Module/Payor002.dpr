library Payor002;

{ Important note about DLL memory management: ShareMem must be the
  first unit in your library's USES clause AND your project's (select
  Project-View Source) USES clause if your DLL exports any procedures or
  functions that pass strings as parameters or function results. This
  applies to all strings passed to and from your DLL--even those that
  are nested in records and classes. ShareMem is the interface unit to
  the BORLNDMM.DLL shared memory manager, which must be deployed along
  with your DLL. To avoid using BORLNDMM.DLL, pass string information
  using PChar or ShortString parameters. }

uses
  SysUtils,
  Classes,
  Dialogs,
  Menus,
  Windows,
  Db,
  WinTypes,
  BtrDS,
  StdCtrls,
  Controls,
  Btrieve,
  Basbn,
  Registr,
  Utilits,
  Common,
  CommCons,
  DocFunc,
  BankCnBn,
  PayorderFrm in 'PayorderFrm.pas' {PaydocForm};

procedure GetDocuments(AList: TStringList);
begin
  AList.Add('1=Платежное поручение (до 1 июня 03)');
  AList.Add('2=*Платежное требование (до 1 июня 03)');
  AList.Add('16=*Платежный ордер (до 1 июня 03)');
  AList.Add('91=*Платежное требование (до 1 июня 03)');
  AList.Add('92=*Платежное поручение (до 1 июня 03)');
end;

function EditRecord(Sender: TComponent; PayRecPtr: PBankPayRec;
  EditMode: Integer; New: Boolean): Boolean;
const
  MesTitle: PChar = 'Редактирование документа';
var
  I, Err, CorrRes: Integer;
  UserRec: TUserRec;
  Number, DebitRs, DebitKs, DebitBik, DebitInn, DebitName, DebitBank,
    CreditRs, CreditKs, CreditBik, CreditInn, CreditName, CreditBank,
    Purpose, DebitKpp, CreditKpp, Status, Kbk, Okato, OsnPl, Period, NDoc,
    DocDate, TipPl, Nchpl, Shifr, Nplat, OstSum: string;
begin
  GetRegParamByName('CharAfterNazn', GetUserNumber, CharAfterNazn);
  GetRegParamByName('EnterAfterNazn', GetUserNumber, EnterAfterNazn);
  GetRegParamByName('WithNDSRem', GetUserNumber, WithNDSRem);
  GetRegParamByName('WithoutNDSRem', GetUserNumber, WithoutNDSRem);
  GetRegParamByName('CharAfterRem', GetUserNumber, CharAfterRem);
  PaydocForm := TPaydocForm.Create(Sender);
  with PaydocForm do
  begin
    if PayRecPtr<>nil then
    begin
      DocIdLabel.Caption := IntToStr(PayRecPtr^.dbIdHere);
      DateEdit.Text := BtrDateToStr(PayRecPtr^.dbDoc.drDate);
      SumCalcEdit.Value := PayRecPtr^.dbDoc.drSum/100;
      TermEdit.Text := BtrDateToStr(PayRecPtr^.dbDoc.drSrok);
      PayCodeEdit.Text := FillZeros(PayRecPtr^.dbDoc.drType div 100, 2);
      case PayRecPtr^.dbDoc.drType of
        102: Caption := 'Платежное требование (до 1 июня 03)';
        116: Caption := 'Платежный ордер (до 1 июня 03)';
        else
          Caption := 'Платежное поручение (до 1 июня 03)';
      end;
      PayKindBox.ItemIndex := PayRecPtr^.dbDoc.drIsp;
      PriorityEdit.Text := IntToStr(PayRecPtr^.dbDoc.drOcher);
      DecodeDocVar(PayRecPtr^.dbDoc, PayRecPtr^.dbDocVarLen, Number,
        DebitRs, DebitKs, DebitBik, DebitInn, DebitName, DebitBank,
        CreditRs, CreditKs, CreditBik, CreditInn, CreditName, CreditBank,
        Purpose, DebitKpp, CreditKpp, Status, Kbk, Okato, OsnPl, Period, NDoc,
        DocDate, TipPl, Nchpl, Shifr, Nplat, OstSum, 0, 0, CorrRes, False);
      NumSpinEdit.Text := Number;
      DebitRsBox.Text := DebitRs;
      DebitKsEdit.Text := DebitKs;
      DebitBikEdit.Text := DebitBik;
      DebitInnEdit.Text := DebitInn;    
      DebitMemo.Text := DebitName;
      DebitBankMemo.Text := DebitBank;
      CreditRsBox.Text := CreditRs;
      CreditKsEdit.Text := CreditKs;
      CreditBikEdit.Text := CreditBik;
      CreditInnEdit.Text := CreditInn;
      CreditMemo.Text := CreditName;
      CreditBankMemo.Text := CreditBank;
      PurposeMemo.Text := Purpose;
    end;
    if EditMode>0 then
      LockAllControls
    else begin
      FillClientList(DebitRsBox.Items, DateToBtrDate(Date), 200);
      if New then
      begin
        CurrentUser(UserRec);
        DebitRsBox.ItemIndex :=
          DebitRsBox.Items.IndexOfObject(TObject(UserRec.urFirmNumber));
        DebitRsBoxClick(nil);
      end;
    end;
    repeat
      Err := 0;
      Result := (ShowModal = mrOk) and (EditMode<>1);
      if Result and (PayRecPtr<>nil) and (EditMode=0) then
      begin
        PayRecPtr^.dbDoc.drDate := StrToBtrDate(DateEdit.Text);
        if (PayRecPtr^.dbDoc.drDate=0) and (MessageBox(Handle,
          'Не указанна дата документа', MesTitle,
          MB_ABORTRETRYIGNORE or MB_ICONERROR)<>IDIGNORE)
        then
          Err := 1
        else begin
          if (DateEdit.Date>=StrToDate('01.06.2003')) and (MessageBox(Handle,
            'Данная форма устарела. Используйте форму "с 01 июня 2003"', MesTitle,
            MB_ABORTRETRYIGNORE or MB_ICONERROR)<>IDIGNORE)
          then
            Err := 1
          else begin
            if (SumCalcEdit.Value<=0) and
              (MessageBox(Handle, 'Сумма документа равна нулю', MesTitle,
                MB_ABORTRETRYIGNORE or MB_ICONERROR)<>IDIGNORE) then
            begin
              Err := 1;
              ActiveControl := SumCalcEdit;
            end;
            if Err=0 then
            try  {сумма}
              PayRecPtr^.dbDoc.drSum := Round(SumCalcEdit.Value*100.0);
            except
              MessageBox(Handle, 'Сумма указана неверно', MesTitle,
                MB_OK or MB_ICONERROR);
              ActiveControl := SumCalcEdit;
              Err:=1;
            end;
            if Err=0 then
            begin
              PayRecPtr^.dbDoc.drSrok := StrToBtrDate(TermEdit.Text);
              if (PayRecPtr^.dbDoc.drSrok<>0) and
                (MessageBox(Handle, 'Срок платежа не указывается', MesTitle,
                  MB_ABORTRETRYIGNORE or MB_ICONERROR)<>IDIGNORE) then
              begin
                Err := 1;
                ActiveControl := TermEdit;
              end;
              if Err=0 then
              begin
                try  {очередность платежа}
                  PayRecPtr^.dbDoc.drOcher := StrToInt(PriorityEdit.Text);
                except
                  MessageBox(Handle, 'Очередность платежа указана неверно',
                    MesTitle, MB_OK or MB_ICONERROR);
                  ActiveControl := PriorityEdit;
                  Err := 1;
                end;
                DebitMemo.Text := Trim(DebitMemo.Text);
                DebitBankMemo.Text := Trim(DebitBankMemo.Text);
                CreditMemo.Text := Trim(CreditMemo.Text);
                CreditBankMemo.Text := Trim(CreditBankMemo.Text);
                PurposeMemo.Text := Trim(PurposeMemo.Text);
                if (Err=0) and (Length(PurposeMemo.Text)<=0) then
                  if MessageBox(ParentWnd, 'Не указано назначение платежа', MesTitle,
                    MB_ABORTRETRYIGNORE + MB_ICONERROR)<>IDIGNORE
                  then begin
                    ActiveControl := PurposeMemo;
                    Err := 1;
                  end;
                if Err=0 then
                begin
                  if not TestAcc(DebitBikEdit.Text, DebitKsEdit.Text, DebitRsBox.Text,
                    ' плательщика', True) then
                  begin
                    Err := 1;
                    ActiveControl := DebitRsBox;
                  end
                  else begin
                    if not TestAcc(CreditBikEdit.Text, CreditKsEdit.Text,
                      CreditRsBox.Text, ' получателя', True) then
                    begin
                      ActiveControl := CreditRsBox;
                      Err := 1;
                    end
                    else begin
                      PayRecPtr^.dbDoc.drIsp := PayKindBox.ItemIndex;
                      Number := NumSpinEdit.Text;
                      DebitRs := DebitRsBox.Text;
                      DebitKs := DebitKsEdit.Text;
                      DebitBik := DebitBikEdit.Text;
                      DebitInn := DebitInnEdit.Text;
                      DebitName := DebitMemo.Text;
                      DebitBank := DebitBankMemo.Text;
                      CreditRs := CreditRsBox.Text;
                      CreditKs := CreditKsEdit.Text;
                      CreditBik := CreditBikEdit.Text;
                      CreditInn := CreditInnEdit.Text;
                      CreditName := CreditMemo.Text;
                      CreditBank := CreditBankMemo.Text;
                      Purpose := PurposeMemo.Text;
                      {DebitKpp := DebitKppEdit.Text;
                      CreditKpp := CreditKppEdit.Text;
                      Status := PayerComboBox.Text;
                      Kbk := KbkEdit.Text;
                      Okato := OkatoEdit.Text;
                      OsnPl := OpComboBox.Text;
                      Period := Trim(PeriodComboBox.Text)+'.'+Trim(
                        MounthComboBox.Text)+'.'+Trim(YearComboBox.Text);
                      NDoc := NDocEdit.Text;
                      DocDate := DocDateEdit.Text;
                      TipPl := TpComboBox.Text;}
                      EncodeDocVar(False, Number,
                        DebitRs, DebitKs, DebitBik, DebitInn, DebitName, DebitBank,
                        CreditRs, CreditKs, CreditBik, CreditInn, CreditName, CreditBank,
                        Purpose, DebitKpp, CreditKpp, Status, Kbk, Okato, OsnPl, Period, NDoc,
                        DocDate, TipPl, Nchpl, Shifr, Nplat, OstSum, 0, 0, CorrRes,
                        False, False, nil, nil,
                        PayRecPtr^.dbDoc, I);
                      PayRecPtr^.dbDocVarLen := I;
                      UpdateClient(DebitRs, StrToInt(DebitBik), DebitName,
                        DebitInn, DebitKpp, False, False);
                      UpdateClient(CreditRs, StrToInt(CreditBik), CreditName,
                        CreditInn, CreditKpp, False, False);
                    end;
                  end;
                end;
              end;
            end;
          end;
        end;
      end;
    until Err=0;
    Free;
  end;
end;

exports
  GetDocuments name DocumentsDLLProcName,
  EditRecord name EditRecordDLLProcName;

begin
end.


