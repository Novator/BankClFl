library Casor003;

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
  CashorderFrm in 'CashorderFrm.pas' {CashorderForm};

procedure GetDocuments(AList: TStringList);
var
  C: string[1];
begin
  if IsSanctAccess('CashInsSanc') then
    C := ''
  else
    C := '*';
  AList.Add('3='+C+'Кассовый ордер');
end;

type
  AddClientRecord = function(Sender: TComponent; AClientRecPtr: PNewClientRec): Boolean;

function EditRecord(Sender: TComponent; PayRecPtr: PPayRec;
  EditMode: Integer; New: Boolean): Boolean;
var
  CashorderForm: TCashorderForm;
  I, Err, K, L, J, J1, CorrRes: Integer;
  S, Number, DebitRs, DebitKs, DebitBik, DebitInn, DebitName, DebitBank,
    CreditRs, CreditKs, CreditBik, CreditInn, CreditName, CreditBank,
    Purpose, DebitKpp, CreditKpp, Status, Kbk, Okato, OsnPl, Period, NDoc,
    DocDate, TipPl, Nchpl, Shifr, Nplat, OstSum: string;
    UserRec: TUserRec;
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
  CashorderForm := TCashorderForm.Create(Sender);
  with CashorderForm  do
  begin
    try
      if PayRecPtr<>nil then
      begin
        DateEdit.Text := BtrDateToStr(PayRecPtr^.dbDoc.drDate);
        SumEdit.Value := PayRecPtr^.dbDoc.drSum/100;
        PayCodeEdit.Text := FillZeros(PayRecPtr^.dbDoc.drType, 2);
        DebInd := 1;
        CredInd := 0;

        DecodeDocVar(PayRecPtr^.dbDoc, PayRecPtr^.dbDocVarLen, Number,
          DebitRs, DebitKs, DebitBik, DebitInn, DebitName, DebitBank,
          CreditRs, CreditKs, CreditBik, CreditInn, CreditName, CreditBank,
          Purpose, DebitKpp, CreditKpp, Status, Kbk, Okato, OsnPl, Period, NDoc,
          DocDate, TipPl, Nchpl, Shifr, Nplat, OstSum, 0, 0, CorrRes, False);
        NumSpinEdit.Text := Number;
        Participants[1].Rs := DebitRs;
        Participants[1].Ks := DebitKs;
        Participants[1].Bik := DebitBik;
        Participants[1].Inn := DebitInn;
        Participants[1].Kpp := DebitKpp;
        Participants[1].Name := DebitName;
        Participants[1].BankName := DebitBank;
        Participants[0].Rs := CreditRs;
        Participants[0].Ks := CreditKs;
        Participants[0].Bik := CreditBik;
        Participants[0].Inn := CreditInn;
        Participants[0].Kpp := CreditKpp;
        Participants[0].Name := CreditName;
        Participants[0].BankName := CreditBank;
        L := Length(Purpose);
        K := 0;
        J := 0;
        while (J<L) and (K<=1) and (Purpose[J]<>'~') do    //Добавлено
        begin
          if (Purpose[J]=#10) or (Purpose[J]=#13) then
            K := 1
          else
            if K=1 then
              Inc(K);
          Inc(J);
        end;
        Dec(J);
        //Добавлено
        J1 := J;
       // MessageBox(ParentWnd,PChar(Purpose),'Chekit!',MB_OK);    //Отладка
        while (J1>=0) and (J1<L) and (Purpose[J1]<>'~') do
        begin
          Inc (J1);
          end;
        if (J1>=0) and (Purpose[J1]='~') then
        begin
          Inc(J1);
          if (J1<=L) and (Purpose[J1]>='0') and (Purpose[J1]<='9') then
            begin
            PasSerialEdit.Text := Copy(Purpose, J1, 4);
            PasNumberEdit.Text := Copy(Purpose, (J1+5), 6);
            PasPlaceMemo.Text := Copy(Purpose, (J1+12), L);
            end
          else
            FIOEdit.Text := Copy(Purpose, J1,L);
          Dec(J1);
        end;

        if K>1 then
        begin
          S := Copy(Purpose, J, (J1-J));     //Изм
          PutNazn(S, Err);
          if Err=1 then
            ChangeDebitCredit;
          OrderRadioGroupClick(nil);
          Dec(J);
        end;
        while (J>=0) and ((Purpose[J]=#10) or (Purpose[J]=#13)) do
          Dec(J);
        PurposeEdit.Text := Copy(Purpose, 1, J);
      end;
      if EditMode>0 then
        LockAllControls
      else begin
        FillClientList(ClientRsBox.Items, DateToBtrDate(Date), 200);
        if New then
        begin
          CurrentUser(UserRec);
          ClientRsBox.ItemIndex :=
            ClientRsBox.Items.IndexOfObject(TObject(UserRec.urFirmNumber));
          ClientRsBoxClick(nil);
        end;
      end;
      if New or CopyMode then
        Caption := Caption + ' (новый)';
      repeat
        Err := 0;
        Result := (ShowModal = mrOk) and (EditMode<>1);

        if Result and (PayRecPtr<>nil) and (EditMode=0) then
        begin
          Participants[1].Rs := CashAccComboBox.Text;

          Participants[0].Rs := ClientRsBox.Text;
          Participants[0].Inn := ClientInnEdit.Text;
          Participants[0].Name := ClientMemo.Text;
          Participants[0].Ks := Participants[1].Ks;
          Participants[0].Bik := Participants[1].Bik;
          Participants[0].BankName := Participants[1].Name;

          PayRecPtr^.dbDoc.drDate := StrToBtrDate(DateEdit.Text);
          if PayRecPtr^.dbDoc.drDate=0 then
          begin
            Err := 1;
            MessageBox(ParentWnd, 'Дата документа не указана', 'Ошибка ввода',
              MB_OK or MB_ICONERROR)
          end
          else begin
            if SumEdit.Value>0 then
              Err := 0
            else
              if MessageBox(ParentWnd, 'Сумма документа равна нулю', 'Ошибка ввода',
                MB_ABORTRETRYIGNORE or MB_ICONERROR)<>IDIGNORE
              then begin
                {CodeComboBox.SetFocus;}
                Err := 1;
              end;
            if Err=0 then
            begin
              PayRecPtr^.dbDoc.drSum := Round(SumEdit.Value*100.0);
              if Length(PurposeEdit.Text)<=0 then
                if MessageBox(ParentWnd, 'Не указано назначение платежа', 'Ошибка ввода',
                  MB_ABORTRETRYIGNORE or MB_ICONERROR)<>IDIGNORE
                then
                  Err := 1;
  //Добавлено Меркуловым
              if (PasSerialEdit.Text<>'') or (PasNumberEdit.Text<>'') or (PasPlaceMemo.Text<>'') then
                begin
                if (Length(PasSerialEdit.Text)<4) and (OrderRadioGroup.ItemIndex=1) then
                  if MessageBox(ParentWnd, 'Не указана серия паспорта', 'Ошибка ввода',
                    MB_ABORTRETRYIGNORE or MB_ICONERROR)<>IDIGNORE
                  then
                    Err := 1;
                if (Length(PasNumberEdit.Text)<6) and (OrderRadioGroup.ItemIndex=1) then
                  if MessageBox(ParentWnd, 'Не указан номер паспорта', 'Ошибка ввода',
                    MB_ABORTRETRYIGNORE or MB_ICONERROR)<>IDIGNORE
                  then
                    Err := 1;
                if (Length(PasPlaceMemo.Text)<=0) and (OrderRadioGroup.ItemIndex=1) then
                  if MessageBox(ParentWnd, 'Не указано место и дата выдачи паспорта', 'Ошибка ввода',
                    MB_ABORTRETRYIGNORE or MB_ICONERROR)<>IDIGNORE
                  then
                    Err := 1;
//              if (Length(FIOEdit.Text)<=0) and (OrderRadioGroup.ItemIndex=0) then
//                if MessageBox(ParentWnd, 'Не указано Ф.И.О.', 'Ошибка ввода',
//                  MB_ABORTRETRYIGNORE or MB_ICONERROR)<>IDIGNORE
//                then
//                  Err := 1;
                end;
//Окончание добавления

              if Err=0 then
              begin
                begin
                  if not TestAcc(Participants[1].Bik, Participants[1].Ks,
                    Participants[1].Rs, ' кассы', True) then
                      Err := 1
                  else
                  if not TestAcc(Participants[0].Bik, Participants[0].Ks,
                    Participants[0].Rs, ' клиента', True) then
                      Err := 1
                  else begin
                    Number := NumSpinEdit.Text;
                    DebitRs := Participants[DebInd].Rs;
                    DebitKs := Participants[DebInd].Ks;
                    DebitBik := Participants[DebInd].Bik;
                    DebitInn := Participants[DebInd].Inn;
                    DebitName := Participants[DebInd].Name;
                    DebitBank := Participants[DebInd].BankName;
                    CreditRs := Participants[CredInd].Rs;
                    CreditKs := Participants[CredInd].Ks;
                    CreditBik := Participants[CredInd].Bik;
                    CreditInn := Participants[CredInd].Inn;
                    CreditName := Participants[CredInd].Name;
                    CreditBank := Participants[CredInd].BankName;
                    TakeNazn(S);
                    //Изменено
                    Purpose := PurposeEdit.Text+#13#10+S;
                    if (OrderRadioGroup.ItemIndex=1) then
                       Purpose := Purpose+'~'+PasSerialEdit.Text+' '+
                       PasNumberEdit.Text+' '+PasPlaceMemo.Text
                    else
                       Purpose := Purpose+'~'+FIOEdit.Text;
                    Status := '';
                    Kbk := '';
                    Okato := '';
                    OsnPl := '';
                    Period := '';
                    NDoc := '';
                    DocDate := '';
                    TipPl := '';
                    EncodeDocVar(False, Number,
                      DebitRs, DebitKs, DebitBik, DebitInn, DebitName, DebitBank,
                      CreditRs, CreditKs, CreditBik, CreditInn, CreditName, CreditBank,
                      Purpose, DebitKpp, CreditKpp, Status, Kbk, Okato, OsnPl, Period, NDoc,
                      DocDate, TipPl, Nchpl, Shifr, Nplat, OstSum, 0, 0, CorrRes,
                      False, False, nil, nil,
                      PayRecPtr^.dbDoc, I);
                    PayRecPtr^.dbDocVarLen := I;
                    UpdateClient(Participants[1].Rs,
                      StrToInt(Participants[1].Bik), Participants[1].Name,
                      Participants[1].Inn, Participants[1].Kpp, False, False, 0,
                      Participants[1].Rs, StrToInt(Participants[1].Bik), '');
                  end;
                end;
              end;
            end;
          end;
        end;
      until Err=0;
    finally
      Free;
    end;
  end;
end;

exports
  GetDocuments name DocumentsDLLProcName,
  EditRecord name EditRecordDLLProcName;

begin
end.


