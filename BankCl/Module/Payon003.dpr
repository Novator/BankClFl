library Payon003;

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
  Bases,
  Registr,
  Utilits,
  Common,
  CommCons,
  ClntCons,
  DocFunc,
  PayorderNewFrm in 'PayorderNewFrm.pas' {PaydocForm};

procedure GetDocuments(AList: TStringList);
var
  C: string[1];
begin
  AList.Add('101=Платежное поручение');
  if IsSanctAccess('PlatTrebInsSanc') then C:='' else C:='*';
  AList.Add('102='+C+'Платежное требование');
  if IsSanctAccess('InkPorInsSanc') then C:='' else C:='*';
  AList.Add('106='+C+'Инкассовое поручение');
  if IsSanctAccess('PlatOrInsSanc') then C:='' else C:='*';
  AList.Add('116='+C+'Платежный ордер');
  AList.Add('191=*Платежное требование');
  AList.Add('192=*Платежное поручение');
end;

function EditRecord(Sender: TComponent; PayRecPtr: PPayRec;
  EditMode: Integer; New: Boolean): Boolean;
const
  MesTitle: PChar = 'Редактирование документа';
var
  I, Err, CorrRes: Integer;
  UserRec: TUserRec;
  S: string;
  Number, DebitRs, DebitKs, DebitBik, DebitInn, DebitName, DebitBank,
    CreditRs, CreditKs, CreditBik, CreditInn, CreditName, CreditBank,
    Purpose, DebitKpp, CreditKpp, Status, Kbk, Okato, OsnPl, Period, NDoc,
    DocDate, TipPl, Nchpl, Shifr, Nplat, OstSum: string;
  CopyMode: Boolean;
begin
  CopyMode := False;
  if EditMode>=10 then
  begin
    EditMode := EditMode-10;
    CopyMode := True;
  end;
  GetRegParamByName('CharAfterNazn', CommonUserNumber, CharAfterNazn);
  GetRegParamByName('EnterAfterNazn', CommonUserNumber, EnterAfterNazn);
  GetRegParamByName('WithNDSRem', CommonUserNumber, WithNDSRem);
  GetRegParamByName('WithoutNDSRem', CommonUserNumber, WithoutNDSRem);
  GetRegParamByName('CharAfterRem', CommonUserNumber, CharAfterRem);
  GetRegParamByName('PayTimeAsterik', CommonUserNumber, PayTimeAsterik);

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
        102,191:
          begin
            Caption := 'Платежное требование';
            StatusLabel.Hide;
            PayerComboBox.Hide;
            NalogGroupBox.Hide;
            Accept1Label.Show;
            Accept2Label.Show;
            AcceptSrokComboBox.Show;
            AcceptGroupBox.Height := NalogGroupBox.Height;
            AcceptGroupBox.Show;
            AcceptComboBox.Show;
            AcceptComLabel.Show;
            AcceptMemo.Text := '';
          end;
        106: Caption := 'Инкассовое поручение';
        116: Caption := 'Платежный ордер';
        else
          begin
            Caption := 'Платежное поручение';
            TermEdit.Show;
            SrokLabel.Show;
          end;
      end;
      PayKindBox.ItemIndex:=PayRecPtr^.dbDoc.drIsp;
      PriorityEdit.Text := IntToStr(PayRecPtr^.dbDoc.drOcher);
      DecodeDocVar(PayRecPtr^.dbDoc, PayRecPtr^.dbDocVarLen, Number,
        DebitRs, DebitKs, DebitBik, DebitInn, DebitName, DebitBank,
        CreditRs, CreditKs, CreditBik, CreditInn, CreditName, CreditBank,
        Purpose, DebitKpp, CreditKpp, Status, Kbk, Okato, OsnPl, Period, NDoc,
        DocDate, TipPl, Nchpl, Shifr, Nplat, OstSum, 0, 0, CorrRes, False);
      NumSpinEdit.Text := Number;
      PayCodeEdit.Text := FillZeros((PayRecPtr^.dbDoc.drType mod 100), 2);
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
      DebitKppEdit.Text := DebitKpp;
      CreditKppEdit.Text := CreditKpp;
      if PayRecPtr^.dbDoc.drType in [102,191] then
      begin
        AcceptSrokComboBox.Text := DocDate;
        AcceptMemo.Text := OsnPl;
      end
      else begin
        PayerComboBox.Text := Status;
        KbkEdit.Text := Kbk;
        OkatoEdit.Text := Okato;
        OpComboBox.Text := OsnPl;
        S := Period;
        Err := Pos('.', S);
        if Err>0 then
        begin
          PeriodComboBox.Text := Copy(S, 1, Err-1);
          Delete(S, 1, Err);
          Err := Pos('.', S);
          if Err>0 then
          begin
            MounthComboBox.Text := Copy(S, 1, Err-1);
            Delete(S, 1, Err);
            YearComboBox.Text := S;
          end
          else
            MounthComboBox.Text := S;
        end
        else
          PeriodComboBox.Text := S;
        NDocEdit.Text := NDoc;
        DocDateEdit.Text := DocDate;
        TpComboBox.Text := TipPl;
      end;
    end;
    if EditMode>0 then
    begin
      LockAllControls;
      if EditMode=2 then
        OkBtn.Caption := 'Подписать';
    end
    else begin
      FillClientList(DebitRsBox.Items, DateToBtrDate(Date), 200);
      if New then
      begin
        SetNew;
        CurrentUser(UserRec);
        DebitRsBox.ItemIndex :=
          DebitRsBox.Items.IndexOfObject(TObject(UserRec.urFirmNumber));
        DebitRsBoxClick(nil);
      end;
    end;
    if New or CopyMode then
      Caption := Caption + ' (новый)'
    else
      if not ReadOnly then
      begin
        if EditMode=2 then
          Caption := Caption + ' (подписание)'
        else
          Caption := Caption + ' (редактирование)';
      end;
    repeat
      Err := 0;
      Result := (ShowModal = mrOk) and (EditMode<>1);

      if Result and (PayRecPtr<>nil) and (EditMode=0) then
      begin
        PayRecPtr^.dbDoc.drDate := StrToBtrDate(DateEdit.Text);
        if PayRecPtr^.dbDoc.drDate=0 then
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
            if TermEdit.Visible then
            begin
              PayRecPtr^.dbDoc.drSrok := StrToBtrDate(TermEdit.Text);
              if (PayRecPtr^.dbDoc.drSrok<>0) and
                (MessageBox(Handle, 'Срок платежа не указывается', MesTitle,
                  MB_ABORTRETRYIGNORE or MB_ICONERROR)<>IDIGNORE) then
              begin
                Err := 1;
                ActiveControl := TermEdit;
              end;
            end
            else
              PayRecPtr^.dbDoc.drSrok := 0;
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
                  MB_ABORTRETRYIGNORE or MB_ICONERROR)<>IDIGNORE
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
                    DebitKpp := DebitKppEdit.Text;
                    CreditKpp := CreditKppEdit.Text;
                    if PayRecPtr^.dbDoc.drType in [102,191] then
                    begin
                      Status := '';
                      DocDate := AcceptSrokComboBox.Text;
                      if Length(DocDate)>0 then
                      begin
                        Val(DocDate, I, Err);
                        if (Err=0) and (I<5) and (MessageBox(ParentWnd,
                          'Срок для акцепта слишком мал', MesTitle,
                          MB_ABORTRETRYIGNORE or MB_ICONERROR)<>IDIGNORE)
                        then
                          Err := 1;
                        if Err<>0 then
                          ActiveControl := AcceptSrokComboBox;
                      end;
                      OsnPl := AcceptMemo.Text;
                    end
                    else begin
                      Status := PayerComboBox.Text;
                      Kbk := KbkEdit.Text;
                      Period := Trim(PeriodComboBox.Text);
                      Okato := Trim(MounthComboBox.Text);
                      OsnPl := Trim(YearComboBox.Text);
                      if ((Length(Period)>0) or (Length(Okato)>0) or (Length(OsnPl)>0))
                        and not ((Period='0') and (Okato='0') and (OsnPl='0')) then
                      begin
                        if (Length(Okato)>0) or (Length(OsnPl)>0) then
                          Period := Period + '.' + Okato;
                        if Length(OsnPl)>0 then
                          Period := Period + '.' + OsnPl;
                      end;
                      Okato := OkatoEdit.Text;
                      OsnPl := OpComboBox.Text;
                      NDoc := NDocEdit.Text;
                      if Length(Status)>0 then
                      begin
                        try
                          if DocDateEdit.Date=0 then
                          begin
                            DocDate := '0';
                          end
                          else
                            DocDate := DocDateEdit.Text;
                        except
                          DocDate := '0';
                        end;
                      end
                      else
                        DocDate := '';
                      TipPl := TpComboBox.Text;
                      if (Length(Status)>0) and (
                        (Length(DebitKpp)=0) or (Length(CreditKpp)=0) or
                        (Length(Status)=0) or (Length(Kbk)=0) or (Length(Okato)=0) or
                        (Length(Period)=0) or (Length(OsnPl)=0) or
                        (Length(NDoc)=0) or (Length(DocDate)=0) or (Length(TipPl)=0))
                        and (MessageBox(Handle, 'Указаны не все налоговые коды', MesTitle,
                          MB_ABORTRETRYIGNORE or MB_ICONERROR)<>IDIGNORE) then
                      begin
                        Err := 1;
                        ActiveControl := KbkEdit;
                      end;
                    end;
                    if Err=0 then
                    begin
                      EncodeDocVar(True, Number,
                        DebitRs, DebitKs, DebitBik, DebitInn, DebitName, DebitBank,
                        CreditRs, CreditKs, CreditBik, CreditInn, CreditName, CreditBank,
                        Purpose, DebitKpp, CreditKpp, Status, Kbk, Okato, OsnPl, Period, NDoc,
                        DocDate, TipPl, Nchpl, Shifr, Nplat, OstSum, 0, 0, CorrRes, False, False, nil, nil,
                        PayRecPtr^.dbDoc, I);
                      PayRecPtr^.dbDocVarLen := I;
                      try
                        I := StrToInt(DebitBik);
                      except
                        I := 0;
                      end;
                      UpdateClient(DebitRs, I, DebitName, DebitInn, DebitKpp,
                        False, True, 0, DebitRs, I, '');
                      try
                        I := StrToInt(CreditBik);
                      except
                        I := 0;
                      end;
                      UpdateClient(CreditRs, I, CreditName, CreditInn, CreditKpp,
                        False, True, 0, CreditRs, I, '');
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


