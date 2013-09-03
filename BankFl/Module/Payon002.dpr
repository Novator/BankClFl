library Payon002;

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
  PayorderNewFrm in 'PayorderNewFrm.pas' {PaydocForm};

procedure GetDocuments(AList: TStringList);
begin
  AList.Add('101=��������� ���������');
  AList.Add('102=*��������� ����������');
  AList.Add('106=*���������� ���������');
  AList.Add('116=*��������� �����');
  AList.Add('191=*��������� ����������');
  AList.Add('192=*��������� ���������');
end;

function EditRecord(Sender: TComponent; PayRecPtr: PBankPayRec;
  EditMode: Integer; New: Boolean): Boolean;
const
  MesTitle: PChar = '�������������� ���������';
var
  I, Err, CorrRes: Integer;
  UserRec: TUserRec;
  S: string;
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
      KorrIdLabel.Caption := IntToStr(PayRecPtr^.dbIdKorr); //��������� ����������
      DateEdit.Text := BtrDateToStr(PayRecPtr^.dbDoc.drDate);
      SumCalcEdit.Value := PayRecPtr^.dbDoc.drSum/100;
      TermEdit.Text := BtrDateToStr(PayRecPtr^.dbDoc.drSrok);
      PayCodeEdit.Text := FillZeros(PayRecPtr^.dbDoc.drType div 100, 2);
      case PayRecPtr^.dbDoc.drType of
        102: Caption := '��������� ����������';
        105: Caption := '���������� ���������';
        116: Caption := '��������� �����';
        else
          Caption := '��������� ���������';
      end;
      PayKindBox.ItemIndex:=PayRecPtr^.dbDoc.drIsp;
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
      DebitKppEdit.Text := DebitKpp;
      CreditKppEdit.Text := CreditKpp;
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
    if EditMode>0 then
      LockAllControls
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
            (MessageBox(Handle, '����� ��������� ����� ����', MesTitle,
              MB_ABORTRETRYIGNORE or MB_ICONERROR)<>IDIGNORE) then
          begin
            Err := 1;
            ActiveControl := SumCalcEdit;
          end;
          if Err=0 then
          try  {�����}
            PayRecPtr^.dbDoc.drSum := Round(SumCalcEdit.Value*100.0);
          except
            MessageBox(Handle, '����� ������� �������', MesTitle,
              MB_OK or MB_ICONERROR);
            ActiveControl := SumCalcEdit;
            Err:=1;
          end;
          if Err=0 then
          begin
            PayRecPtr^.dbDoc.drSrok := StrToBtrDate(TermEdit.Text);
            if (PayRecPtr^.dbDoc.drSrok<>0) and
              (MessageBox(Handle, '���� ������� �� �����������', MesTitle,
                MB_ABORTRETRYIGNORE or MB_ICONERROR)<>IDIGNORE) then
            begin
              Err := 1;
              ActiveControl := TermEdit;
            end;
            if Err=0 then
            begin
              try  {����������� �������}
                PayRecPtr^.dbDoc.drOcher := StrToInt(PriorityEdit.Text);
              except
                MessageBox(Handle, '����������� ������� ������� �������',
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
                if MessageBox(ParentWnd, '�� ������� ���������� �������', MesTitle,
                  MB_ABORTRETRYIGNORE or MB_ICONERROR)<>IDIGNORE
                then begin
                  ActiveControl := PurposeMemo;
                  Err := 1;
                end;
              if Err=0 then
              begin
                if not TestAcc(DebitBikEdit.Text, DebitKsEdit.Text, DebitRsBox.Text,
                  ' �����������', True) then
                begin
                  Err := 1;
                  ActiveControl := DebitRsBox;
                end
                else begin
                  if not TestAcc(CreditBikEdit.Text, CreditKsEdit.Text,
                    CreditRsBox.Text, ' ����������', True) then
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
                    Status := PayerComboBox.Text;
                    Kbk := KbkEdit.Text;
                    Period := Trim(PeriodComboBox.Text);
                    Okato := Trim(MounthComboBox.Text);
                    OsnPl := Trim(YearComboBox.Text);
                    if (Length(Period)>0) or (Length(Okato)>0) or (Length(OsnPl)>0) then
                    begin
                      if (Length(Okato)>0) or (Length(OsnPl)>0) then
                        Period := Period + '.' + Okato;
                      if Length(OsnPl)>0 then
                        Period := Period + '.' + OsnPl;  
                    end;  
                    Okato := OkatoEdit.Text;  
                    OsnPl := OpComboBox.Text;  
                    NDoc := NDocEdit.Text;  
                    try  
                      if DocDateEdit.Date=0 then
                        DocDate := ''
                      else
                        DocDate := DocDateEdit.Text;
                    except
                      DocDate := '';
                    end;
                    TipPl := TpComboBox.Text;
                    if (Length(PayerComboBox.Text)>0) and (
                      (Length(DebitKpp)=0) or (Length(CreditKpp)=0) or
                      (Length(Status)=0) or (Length(Kbk)=0) or
                      (Length(PeriodComboBox.Text)=0) or (Length(MounthComboBox.Text)=0) or
                      (Length(YearComboBox.Text)=0) or (Length(Okato)=0) or
                      (Length(Period)=0) or (Length(OsnPl)=0) or
                      (Length(NDoc)=0) or (DocDateEdit.Date=0) or
                      (Length(TipPl)=0))
                      and (MessageBox(Handle, '������� �� ��� ��������� ����', MesTitle,
                        MB_ABORTRETRYIGNORE or MB_ICONERROR)<>IDIGNORE) then
                    begin
                      Err := 1;
                      ActiveControl := KbkEdit;
                    end
                    else begin
                      EncodeDocVar(True, Number,
                        DebitRs, DebitKs, DebitBik, DebitInn, DebitName, DebitBank,
                        CreditRs, CreditKs, CreditBik, CreditInn, CreditName, CreditBank,
                        Purpose, DebitKpp, CreditKpp, Status, Kbk, Okato, OsnPl, Period, NDoc,
                        DocDate, TipPl, Nchpl, Shifr, Nplat, OstSum, 0, 0, CorrRes,
                        False, False, nil, nil,
                        PayRecPtr^.dbDoc, I);
                      PayRecPtr^.dbDocVarLen := I;
                      UpdateClient(DebitRs, StrToInt(DebitBik), DebitName,
                        DebitInn, DebitKpp, False, True);
                      UpdateClient(CreditRs, StrToInt(CreditBik), CreditName,
                        CreditInn, CreditKpp, False, True);
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


