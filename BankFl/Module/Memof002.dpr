library Memof002;

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
  Classes,
  Windows,
  SysUtils,
  Controls,
  Basbn,
  CommCons,
  Registr,
  Utilits,
  Common,
  DocFunc,
  BankCnBn,
  MemorderFrm in 'MemorderFrm.pas' {MemorderForm};

procedure GetDocuments(AList: TStringList);
var
  C: string[1];
begin
  {AList.Add('6=*Мемориальный ордер');}
  if IsSanctAccess('MemInsSanc') then C:='' else C:='*';
  AList.Add('9='+C+'Мемориальный ордер');
end;

type
  AddClientRecord = function(Sender: TComponent; AClientRecPtr: PNewClientRec): Boolean;

function EditRecord(Sender: TComponent; PayRecPtr: PBankPayRec;
  EditMode: Integer; New: Boolean): Boolean;
const
  MesTitle: PChar = 'Ошибка ввода';
var
  MemorderForm: TMemorderForm;
  I, Err, CorrRes: Integer;
  UserRec: TUserRec;
  Number, DebitRs, DebitKs, DebitBik, DebitInn, DebitName, DebitBank,
    CreditRs, CreditKs, CreditBik, CreditInn, CreditName, CreditBank,
    Purpose, DebitKpp, CreditKpp, Status, Kbk, Okato, OsnPl, Period, NDoc,
    DocDate, TipPl, Nchpl, Shifr, Nplat, OstSum: string;
begin
  GetRegParamByName('CharAfterNazn', GetUserNumber, CharAfterNazn);
  GetRegParamByName('EnterAfterNazn', GetUserNumber, EnterAfterNazn);
  MemorderForm := TMemorderForm.Create(Sender);
  with MemorderForm  do
  begin
    try
      if PayRecPtr<>nil then
      begin
        DateEdit.Text := BtrDateToStr(PayRecPtr^.dbDoc.drDate);
        SumCalcEdit.Value := PayRecPtr^.dbDoc.drSum/100;
        if PayRecPtr^.dbDoc.drType=3 then
          Caption := 'Кассовый ордер';
        PayCodeEdit.Text := FillZeros(PayRecPtr^.dbDoc.drType, 2);

        DecodeDocVar(PayRecPtr^.dbDoc, PayRecPtr^.dbDocVarLen, Number,
          DebitRs, DebitKs, DebitBik, DebitInn, DebitName, DebitBank,
          CreditRs, CreditKs, CreditBik, CreditInn, CreditName, CreditBank,
          Purpose, DebitKpp, CreditKpp, Status, Kbk, Okato, OsnPl, Period, NDoc,
          DocDate, TipPl, Nchpl, Shifr, Nplat, OstSum, 0, 0, CorrRes, False);
        NumSpinEdit.Text := Number;
        DebitRsBox.Text := DebitRs;
        StrPLCopy(CommonKs, DebitKs, SizeOf(CommonKs)-1);
        StrPLCopy(CommonBik, DebitBik, SizeOf(CommonBik)-1);
        DebitInnEdit.Text := DebitInn;
        DebitMemo.Text := DebitName;
        CommonBankName := DebitBank;
        CreditRsBox.Text := CreditRs;
        CreditInnEdit.Text := CreditInn;
        CreditMemo.Text := CreditName;
        PurposeMemo.Text := Purpose;
      end;
      if EditMode>0 then
        LockAllControls
      else begin
        FillClientList(DebitRsBox.Items, DateToBtrDate(Date), 200);
        CreditRsBox.Items := DebitRsBox.Items;
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
          if PayRecPtr^.dbDoc.drDate=0 then
            Err := 1
          else begin
            if (SumCalcEdit.Value<=0) and (MessageBox(ParentWnd,
              'Сумма документа равна нулю', MesTitle,
                MB_ABORTRETRYIGNORE + MB_ICONERROR)<>IDIGNORE) then
            begin
              Err := 1;
              ActiveControl := SumCalcEdit;
            end
            else
            try  {сумма}
              PayRecPtr^.dbDoc.drSum := Round(SumCalcEdit.Value*100.0);
            except
              MessageBox(Handle, 'Сумма указана неверно', MesTitle,
                MB_OK + MB_ICONERROR);
              ActiveControl := SumCalcEdit;
              Err:=1;
            end;
            if Err=0 then
            begin
              if (Err=0) and (Length(PurposeMemo.Text)<=0)
                and (MessageBox(ParentWnd, 'Не указано назначение платежа', MesTitle,
                  MB_ABORTRETRYIGNORE + MB_ICONERROR)<>IDIGNORE) then
              begin
                Err := 1;
                ActiveControl := PurposeMemo;
              end;
              if Err=0 then
              begin
                if not TestAcc(CommonBik, CommonKs, DebitRsBox.Text,
                  ' плательщика', True) then
                begin
                  Err:=1;
                  ActiveControl := DebitRsBox;
                end
                else begin
                  if not TestAcc(CommonBik, CommonKs,
                    CreditRsBox.Text, ' получателя', True) then
                  begin
                    Err := 1;
                    ActiveControl := CreditRsBox;
                  end
                  else begin
                    Number := NumSpinEdit.Text;
                    DebitRs := DebitRsBox.Text;
                    DebitKs := CommonKs;
                    DebitBik := CommonBik;
                    DebitInn := DebitInnEdit.Text;
                    DebitName := DebitMemo.Text;
                    DebitBank := CommonBankName;
                    CreditRs := CreditRsBox.Text;
                    CreditKs := CommonKs;
                    CreditBik := CommonBik;
                    CreditInn := CreditInnEdit.Text;
                    CreditName := CreditMemo.Text;
                    CreditBank := CommonBankName;
                    Purpose := PurposeMemo.Text;
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


