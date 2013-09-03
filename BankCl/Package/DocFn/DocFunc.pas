unit DocFunc;

interface

uses
  Windows, Classes, SysUtils, CommCons, Utilits;

procedure DecodeDocVar(DocRec: TDocRec; MaxLen: Integer; var Number,
  DebitRs, DebitKs, DebitBik, DebitInn, DebitName, DebitBank,
  CreditRs, CreditKs, CreditBik, CreditInn, CreditName, CreditBank,
  Purpose, DebitKpp, CreditKpp, Status, Kbk, Okato, OsnPl, Period, NDoc,
  DocDate, TipPl, Nchpl, Shifr, Nplat, OstSum: string;
  CheckCharMode, CleanFields: Integer; var CorrRes: Integer;
  NotToWinCharset: Boolean);
function AnalyzePayDoc(DocRec: TDocRec; MaxLen: Integer; BankBik: Integer;
  LowDate: Word; BankKs: string; var Mes: string): Integer;
function TestAcc(CodeS, KsS, AccS: string; EndMes: string;
  Ask: Boolean): Boolean;
function TestPaydoc(DocRec: TDocRec; MaxLen: Integer; Ask: Boolean): Boolean;
procedure MoveKpp(var Inn, Name: string; IsDosCharset: Boolean);
procedure EncodeDocVar(NewForm: Boolean; Number,
  DebitRs, DebitKs, DebitBik, DebitInn, DebitName, DebitBank,
  CreditRs, CreditKs, CreditBik, CreditInn, CreditName, CreditBank,
  Purpose, DebitKpp, CreditKpp, Status, Kbk, Okato, OsnPl, Period, NDoc,
  DocDate, TipPl, Nchpl, Shifr, Nplat, OstSum: string;
  CheckCharMode, CleanFields: Integer;
  var CorrRes: Integer; NotToDosCharset, TestKpp: Boolean;
  PClient: PNewClientRec; PBank: PBankFullNewRec;
  var DocRec: TDocRec; var VarLen: Integer);
{procedure EncodeDocVar(NewForm: Boolean; Number,
  DebitRs, DebitKs, DebitBik, DebitInn, DebitName, DebitBank,
  CreditRs, CreditKs, CreditBik, CreditInn, CreditName, CreditBank,
  Purpose, DebitKpp, CreditKpp, Status, Kbk, Okato, OsnPl, Period, NDoc,
  DocDate, TipPl, ClientName, ClientAcc, ClientInn, ClientKpp: string;
  CheckCharMode, CleanFields: Integer;
  var CorrRes: Integer;
  DosCharset, TestKpp, FillEmptyPayer: Boolean; PBank: PBankFullRec;
  var DocRec: TDocRec; var VarLen: Integer);}
function CalcUserRecCRC(var UserRec: TUserRec): Byte;

implementation


procedure DecodeDocVar(DocRec: TDocRec; MaxLen: Integer; var Number,
  DebitRs, DebitKs, DebitBik, DebitInn, DebitName, DebitBank,
  CreditRs, CreditKs, CreditBik, CreditInn, CreditName, CreditBank,
  Purpose, DebitKpp, CreditKpp, Status, Kbk, Okato, OsnPl, Period, NDoc,
  DocDate, TipPl, Nchpl, Shifr, Nplat, OstSum: string;
  CheckCharMode, CleanFields: Integer; var CorrRes: Integer;
  NotToWinCharset: Boolean);
var
  I, L, Offset, CorrR: Integer;
  P: PChar;
  S: string;
  V: TVarDoc;
begin
  Offset := 0;
  I := 0;
  CorrRes := 0;
  while (I<=27) and (Offset<MaxLen) do
  begin
    P := @DocRec.drVar[Offset];
    L := StrLen(P);
    if Offset+L > MaxLen then
      L := MaxLen - Offset;
    StrLCopy(V, P, L);
    if (CheckCharMode>0) and ((I=5) or (I=6) or (I=11) or (I=12) or (I=13)) then
    begin
      CorrR := CorrText(V, CheckCharMode>1, True);
      if CorrR<>0 then
      begin
        if CorrRes>=0 then
          CorrRes := CorrR;
      end;
    end;
    if not NotToWinCharset then
      DosToWin(V);
    S := StrPas(V);
    if I<>13 then
    begin
      if (CleanFields=1) or (CleanFields=3) then
        S := DelCR(S);
      if (CleanFields=2) or (CleanFields=3) then
        S := RemoveDoubleSpaces(S);
    end;
    S := Trim(S);
    case I of
      0: Number := S;
      1: DebitRs := S;
      2: DebitKs := S;
      3: DebitBik := S;
      4: DebitInn := S;
      5: DebitName := S;
      6: DebitBank := S;
      7: CreditRs := S;
      8: CreditKs := S;
      9: CreditBik := S;
      10: CreditInn := S;
      11: CreditName := S;
      12: CreditBank := S;
      13: Purpose := S;
      14: DebitKpp := S;
      15: CreditKpp := S;
      16: Status := S;
      17: Kbk := S;
      18: Okato := S;
      19: OsnPl := S;
      20: Period := S;
      21: NDoc := S;
      22: DocDate := S;
      23: TipPl := S;
      24: Nchpl := S;
      25: Shifr := S;
      26: Nplat := S;
      27: OstSum := S;
    end;
    Offset := Offset + L + 1;
    Inc(I);
  end;
  while I<=27 do
  begin
    S := '';
    case I of
      0: Number := S;
      1: DebitRs := S;
      2: DebitKs := S;
      3: DebitBik := S;
      4: DebitInn := S;
      5: DebitName := S;
      6: DebitBank := S;
      7: CreditRs := S;
      8: CreditKs := S;
      9: CreditBik := S;
      10: CreditInn := S;
      11: CreditName := S;
      12: CreditBank := S;
      13: Purpose := S;
      14: DebitKpp := S;
      15: CreditKpp := S;
      16: Status := S;
      17: Kbk := S;
      18: Okato := S;
      19: OsnPl := S;
      20: Period := S;
      21: NDoc := S;
      22: DocDate := S;
      23: TipPl := S;
      24: Nchpl := S;
      25: Shifr := S;
      26: Nplat := S;
      27: OstSum := S;
    end;
    Inc(I);
  end;
end;

function AnalyzePayDoc(DocRec: TDocRec; MaxLen: Integer; BankBik: Integer;
  LowDate: Word; BankKs: string; var Mes: string): Integer;

  procedure AddStr(S: string);
  begin
    if Length(Mes)>0 then
      Mes := Mes + '; ';
    Mes := Mes + S;
    if Result=0 then
      Result := 1;
  end;

  procedure AnalyzeAcc(Code: Integer; KsS, AccS: string; EndMes: string);
  begin
    if (Length(KsS)>0) and not TestKey(KsS, (Code div 1000) mod 100) then
      AddStr('К/С'+EndMes+' не ключуется с БИК');
    if Length(AccS)>0 then
    begin
      if Length(KsS)>0 then
      begin
        if not TestKey(AccS, Code mod 1000) then
          AddStr('Ошибочный ключ в счете'+EndMes)
      end
      else
        if not TestKey(AccS, (Code div 1000) mod 100) then
          AddStr('Ошибочный ключ в счете'+EndMes)
    end;
  end;

var
  I, Len, Err, CorrRes, DebitBikNum, CreditBikNum: Integer;
  Number, DebitRs, DebitKs, DebitBik, DebitInn, DebitName, DebitBank,
    CreditRs, CreditKs, CreditBik, CreditInn, CreditName, CreditBank,
    Purpose, DebitKpp, CreditKpp, Status, Kbk, Okato, OsnPl, Period, NDoc,
    DocDate, TipPl, Nchpl, Shifr, Nplat, OstSum: string;
begin
  Result := 0;
  Mes := '';
  with DocRec do
  begin
    if drDate=0 then
      AddStr('Не указана дата')
    else
      if (LowDate<>0) and (drDate<=LowDate) then
        AddStr('Дата слишком старая');
    if drSum=0 then
    begin
      AddStr('Сумма равна нулю');
      Result := 2;
    end
    else
      if drSum<0 then
        AddStr('Сумма меньше нуля');
    DecodeDocVar(DocRec, MaxLen, Number,
      DebitRs, DebitKs, DebitBik, DebitInn, DebitName, DebitBank,
      CreditRs, CreditKs, CreditBik, CreditInn, CreditName, CreditBank,
      Purpose, DebitKpp, CreditKpp, Status, Kbk, Okato, OsnPl, Period, NDoc,
      DocDate, TipPl, Nchpl, Shifr, Nplat, OstSum, 0, 0, CorrRes, True);
    if Length(Number)=0 then
      AddStr('Не указан номер')
    else begin
      Val(Number, I, Err);
      if Err<>0 then
        AddStr('Номер должен быть целым числом');
    end;
    DebitBikNum := 0;
    if Length(DebitBik)=0 then
      AddStr('Не указан БИК банка плательщика')
    else begin
      Val(DebitBik, DebitBikNum, Err);
      if Err=0 then
      begin
        if (BankBik>0) and (DebitBikNum<>BankBik) then
        begin
          AddStr('Чужой БИК банка плательщика');
          Result := 2;
        end;
      end
      else
        AddStr('Ошибочный БИК банка плательщика');
    end;
    if (Length(BankKs)>0) and (DebitKs<>BankKs) then
      AddStr('Чужой корсчет банка плательщика');
    Len := Length(DebitRs);
    if Len=0 then
      AddStr('Не указан счет плательщика')
    else
      if Len<>20 then
        AddStr('Длина счета плательщика='+IntToStr(Len));
    if ((drType=1) or (drType=101)) and (Length(DebitInn)=0) then
      AddStr('Не указан ИНН плательщика');
    if Length(DebitName)=0 then
      AddStr('Не указано название плательщика');
    if Length(DebitBank)=0 then
      AddStr('Не указано название банка плательщика');
    Len := Length(DebitKs);
    if (Len>0) and (Len<>20) then
      AddStr('Длина КС банка плательщика='+IntToStr(Len))
    else
      if (Length(BankKs)>0) and (DebitKs<>BankKs) then
        AddStr('Чужой корсчет банка плательщика');
    Len := Length(DebitRs);
    if Len=0 then
      AddStr('Не указан счет плательщика')
    else
      if Len<>20 then
        AddStr('Длина счета плательщика='+IntToStr(Len));
    if ((drType=1) or (drType=101)) and (Length(DebitInn)=0) then
      AddStr('Не указан ИНН плательщика');
    if Length(DebitName)=0 then
      AddStr('Не указано название плательщика');
    if Length(DebitBank)=0 then
      AddStr('Не указано название банка плательщика');
    Len := Length(CreditRs);
    if Len=0 then
    begin
      AddStr('Не указан счет получателя');
      Result := 2;
    end
    else
      if Len<>20 then
        AddStr('Длина счета получателя='+IntToStr(Len));
    Len := Length(CreditKs);
    if (Len>0) and (Len<>20) then
      AddStr('Длина КС банка получателя='+IntToStr(Len));
    CreditBikNum := 0;
    Len := Length(CreditBik);
    if Len=0 then
    begin
      AddStr('Не указан БИК банка получателя');
      Result := 2;
    end
    else begin
      Val(CreditBik, CreditBikNum, Err);
      if Err<>0 then
      begin
        AddStr('Ошибочный БИК банка получателя');
        Result := 2;
      end;
    end;
    if ((drType=1) or (drType=101)) and (Length(CreditInn)=0) then
      AddStr('Не указан ИНН получателя');
    if Length(CreditName)=0 then
      AddStr('Не указано название получателя');
    if Length(CreditBank)=0 then
      AddStr('Не указано название банка получателя');
    Len := Length(Purpose);
    if Len=0 then
      AddStr('Не указано назначение платежа')
    else begin
      if (Trim(CreditBik)<>'')
        and (Trim(CreditBik)=Trim(DebitBik)) then
      begin
        if Len>254 then
        begin
          AddStr('Назначение платежа превышает допустимые 254 символа (Len='
            +IntToStr(Len)+')');
          Result := 2;
        end
      end
      else
        if Len>210 then
        begin
          AddStr('Назначение платежа превышает допустимые 210 символов (Len='
            +IntToStr(Len)+')');
          Result := 2;
        end;
    end;
    AnalyzeAcc(DebitBikNum, DebitKs, DebitRs, ' плательщика');
    AnalyzeAcc(CreditBikNum, CreditKs, CreditRs, ' получателя');
    if not (drType in [1,3,9,101,102,106,116]) then
      AddStr('Недопустимый ВО='+IntToStr(drType));
    if not (drIsp in [0..2]) then
      AddStr('Недопустимый вид платежа');
    if ((drType=1) or (drType=101)) and not (drOcher in [1..6]) then
      AddStr('Недопустимая очередность платежа');
    if drSrok>0 then
      AddStr('Указан срок платежа');
    if (drType=2) or (drType=102) then
    begin
      if Length(DocDate)>0 then
      begin
        Val(DocDate, CreditBikNum, Err);
        if Err=0 then
        begin
          if CreditBikNum<5 then
            AddStr('Срок акцепта слишком мал');
        end
        else
          AddStr('Срок акцепта неверен');
      end;
      {if Length(OsnPl)=0 then
        AddStr('Не указано условие акцепта');}
    end;
    if Length(Status)>0 then
    begin
      Val(Status, I, Err);
      if Err<>0 then
        AddStr('Статус не цифровой')
      else
        if not (I in [1..15]) then                   //Изменено Меркуловым
          AddStr('Статус вне диапазона 1..15');      //Изменено Меркуловым
      if Length(DebitKpp)=0 then
        AddStr('Не указан КПП плательщика');
      if Length(CreditKpp)=0 then
        AddStr('Не указан КПП получателя');
      if Length(Kbk)=0 then
        AddStr('Не указан КБК');
      if Length(Okato)=0 then
        AddStr('Не указан код ОКАТО');
      if Length(OsnPl)=0 then
        AddStr('Не указано код основания платежа');
      if Length(Period)=0 then
        AddStr('Не указан налоговый период');
      if Length(NDoc)=0 then
        AddStr('Не указан номер налогового документа');
      if Length(DocDate)=0 then
        AddStr('Не указана дата налогового документа');
      if Length(TipPl)=0 then
        AddStr('Не указан тип платежа');
    end;
  end;
end;

function TestAcc(CodeS, KsS, AccS: string; EndMes: string;
  Ask: Boolean): Boolean;
var
  Code, Res: Integer;
  Mes: string;
begin
  Val(CodeS, Code, Res);
  Result := Res=0;
  if Result then
  begin
    Result := (Length(KsS)=0) or TestKey(KsS, (Code div 1000) mod 100);
    if Result then
    begin
      if Length(AccS)>0 then
      begin
        if Length(KsS)>0 then
          Result := TestKey(AccS, Code mod 1000)
        else
          Result := TestKey(AccS, (Code div 1000) mod 100);
      end;
      if Result then
      begin
        Result := Length(AccS)>0;
        if not Result then
          Mes := 'Не указан счет';
      end
      else
        Mes := 'Ошибочный ключ в счете'
    end
    else
      Mes := 'Корсчет банка не ключуется с БИК'
  end
  else
    Mes := 'БИК банка указан неверно';
  if not Result and Ask then
    Result := MessageBox(0, PChar(Mes), PChar('Проверка реквизитов'+EndMes),
      MB_ABORTRETRYIGNORE or MB_ICONERROR)=IDIGNORE;
end;

function TestPaydoc(DocRec: TDocRec; MaxLen: Integer; Ask: Boolean): Boolean;
const
  MesTitle: PChar = 'Проверка документа';
var
  I, Offset, Len, FN, Err, J: Integer;
  V: TVarDoc;
  DebitRs, DebitKs, DebitBik, CreditRs, CreditKs, CreditBik: string;
  P: PChar;
begin
  with DocRec do
  begin
    Result := (drDate<>0) or (Ask and
      (MessageBox(ParentWnd, 'Не указана дата', MesTitle,
        MB_ABORTRETRYIGNORE or MB_ICONERROR)=IDIGNORE));
    if Result then
    begin
      Result := (drSum>0) or (Ask and
        (MessageBox(ParentWnd, 'Сумма равна нулю', MesTitle,
          MB_ABORTRETRYIGNORE or MB_ICONERROR)=IDIGNORE));
      if Result then
      begin
        Offset := 0;
        I := 0;
        if drType<100 then
          FN := 13
        else
          FN := 23;
        while (I<=FN) and (Offset<MaxLen) and Result do
        begin
          P := @drVar[Offset];
          Len := StrLen(P);
          if Offset+Len > MaxLen then
            Len := MaxLen - Offset;
          case I of
            1..3,7..9,16:
              StrLCopy(V, P, Len);
          end;
          case I of
            0: {Number}
              Result := (Len>0) or (Ask and (MessageBox(ParentWnd,
                'Не указан номер', MesTitle, MB_ABORTRETRYIGNORE
                or MB_ICONERROR)=IDIGNORE));
            1: {DebitRs}
              begin
                DebitRs := V;
                Result := (Len>0) or (Ask and (MessageBox(ParentWnd,
                  'Не указан счет плательщика',
                  MesTitle, MB_ABORTRETRYIGNORE + MB_ICONERROR)=IDIGNORE));
              end;
            2: {DebitKs}
              DebitKs := V;
            3: {DebitBik}
              begin
                DebitBik := V;
                Result := (Len>0) or (Ask and (MessageBox(ParentWnd, 'Не указан БИК банка плательщика',
                  MesTitle, MB_ABORTRETRYIGNORE + MB_ICONERROR)=IDIGNORE));
              end;
            4:  {DebetInn}
              Result := (Len>0) or ((drType<>1) and (drType<>101))
                or (Ask and (MessageBox(ParentWnd, 'Не указан ИНН плательщика',
                MesTitle, MB_ABORTRETRYIGNORE + MB_ICONERROR)=IDIGNORE));
            5:  {DebetName}
              Result := (Len>0) or (Ask and (MessageBox(ParentWnd, 'Не указано название плательщика',
                MesTitle, MB_ABORTRETRYIGNORE + MB_ICONERROR)=IDIGNORE));
            6:  {DebetBankName}
              Result := (Len>0) or (Ask and (MessageBox(ParentWnd, 'Не указано название банка плательщика',
                MesTitle, MB_ABORTRETRYIGNORE + MB_ICONERROR)=IDIGNORE));
            7: {CreditRs}
              begin
                CreditRs := V;
                Result := (Len>0) or (Ask and (MessageBox(ParentWnd, 'Не указан счет получателя',
                  MesTitle, MB_ABORTRETRYIGNORE + MB_ICONERROR)=IDIGNORE));
              end;
            8: {CreditKs}
              CreditKs := V;
            9: {CreditBik}
              begin
                CreditBik := V;
                Result := (Len>0) or (Ask and (MessageBox(ParentWnd, 'Не указан БИК банка получателя',
                  MesTitle, MB_ABORTRETRYIGNORE + MB_ICONERROR)=IDIGNORE));
              end;
            10:  {CreditInn}
              Result := (Len>0) or ((drType<>1) and (drType<>101))
                or (Ask and (MessageBox(ParentWnd, 'Не указан ИНН получателя',
                MesTitle, MB_ABORTRETRYIGNORE or MB_ICONERROR)=IDIGNORE));
            11:  {CreditName}
              Result := (Len>0) or (Ask and (MessageBox(ParentWnd, 'Не указано название получателя',
                MesTitle, MB_ABORTRETRYIGNORE or MB_ICONERROR)=IDIGNORE));
            12:  {CreditBankName}
              Result := (Len>0) or (Ask and (MessageBox(ParentWnd, 'Не указано название банка получателя',
                MesTitle, MB_ABORTRETRYIGNORE or MB_ICONERROR)=IDIGNORE));
            13:  {Nazn}
              Result := (Len>0) or (Ask and (MessageBox(ParentWnd, 'Не указано назначение платежа',
                MesTitle, MB_ABORTRETRYIGNORE or MB_ICONERROR)=IDIGNORE));
            14:
              Result := (Len>0) or ((drType<>1) and (drType<>101))
                or (Ask and (MessageBox(ParentWnd, 'Не указан КПП плательщика',
                MesTitle, MB_ABORTRETRYIGNORE or MB_ICONERROR)=IDIGNORE));
            15:
              Result := (Len>0) or ((drType<>1) and (drType<>101))
                or (Ask and (MessageBox(ParentWnd, 'Не указан КПП получателя',
                MesTitle, MB_ABORTRETRYIGNORE or MB_ICONERROR)=IDIGNORE));
            16: {Status}
              if Len=0 then
                I := FN
              else begin
                Val(V, J, Err);
                Result := ((Err=0) and (J in [1..15]))            //Изменено Меркуловым
                  or (Ask and (MessageBox(ParentWnd, 'Статус вне пределов 1..15',//Изменено Меркуловым
                  MesTitle, MB_ABORTRETRYIGNORE or MB_ICONERROR)=IDIGNORE));
              end;
            17: {Kbk}
              Result := (Len>0) or (Ask and (MessageBox(ParentWnd, 'Не указан КБК',
                MesTitle, MB_ABORTRETRYIGNORE or MB_ICONERROR)=IDIGNORE));
            18: {Okato}
              Result := (Len>0) or (Ask and (MessageBox(ParentWnd, 'Не указан код ОКАТО',
                MesTitle, MB_ABORTRETRYIGNORE or MB_ICONERROR)=IDIGNORE));
            19: {OsnPl}
              if not((drType=2) or (drType=102)) then
                Result := (Len>0) or (Ask and (MessageBox(ParentWnd, 'Не указано основание платежа',
                  MesTitle, MB_ABORTRETRYIGNORE or MB_ICONERROR)=IDIGNORE));
            20: {Period}
              Result := (Len>0) or (Ask and (MessageBox(ParentWnd, 'Не указан налоговый период',
                MesTitle, MB_ABORTRETRYIGNORE or MB_ICONERROR)=IDIGNORE));
            21: {NDoc}
              Result := (Len>0) or (Ask and (MessageBox(ParentWnd, 'Не указан номер налогового документа',
                MesTitle, MB_ABORTRETRYIGNORE or MB_ICONERROR)=IDIGNORE));
            22: {DocDate}
              if not((drType=2) or (drType=102)) then
                Result := (Len>0) or (Ask and (MessageBox(ParentWnd, 'Не указана дата налогового документа',
                  MesTitle, MB_ABORTRETRYIGNORE or MB_ICONERROR)=IDIGNORE));
            23: {TipPl}
              Result := (Len>0) or (Ask and (MessageBox(ParentWnd, 'Не указан тип налогового платежа',
                MesTitle, MB_ABORTRETRYIGNORE or MB_ICONERROR)=IDIGNORE));
          end;
          Offset := Offset + Len + 1;
          Inc(I);
        end;
        Result := Result and TestAcc(DebitBik, DebitKs, DebitRs, ' плательщика',
          Ask) and TestAcc(CreditBik, CreditKs, CreditRs, ' получателя', Ask);
        if Result and (I<=FN) then
          Result := (Ask and (MessageBox(ParentWnd, 'Запись не полная',
            MesTitle, MB_ABORTRETRYIGNORE or MB_ICONERROR)=IDIGNORE));
      end;
    end;
  end;
end;

procedure MoveKpp(var Inn, Name: string; IsDosCharset: Boolean);
var
  I, J, L: Integer;
  KppRem: array[0..3] of Char;
  InnRem: array[0..3] of Char;
begin
  InnRem := 'ИНН'#0;
  if IsDosCharset then
    WinToDos(InnRem);
  I := Pos(InnRem, Name);
  if I>0 then
  begin
    J := I+3;
    L := Length(Name);
    while (J<L) and (Name[J]=' ') do
      Inc(J);
    while (J<L) and (Name[J] in ['0'..'9',' ','/','\']) do
      Inc(J);
    Delete(Name, I, J-I);
  end;

  I := Pos('/', Inn);
  if I<=0 then
    I := Pos('\', Inn);
  if I>0 then
  begin
    KppRem := 'КПП'#0;
    if IsDosCharset then
      WinToDos(KppRem);
    if Pos(KppRem, Name)<=0 then
      Name := KppRem+' '+Copy(Inn, I+1, Length(Inn)-I) + #13#10 + Name;
    Inn := Copy(Inn, 1, I-1);
  end;
end;

procedure EncodeDocVar(NewForm: Boolean; Number,
  DebitRs, DebitKs, DebitBik, DebitInn, DebitName, DebitBank,
  CreditRs, CreditKs, CreditBik, CreditInn, CreditName, CreditBank,
  Purpose, DebitKpp, CreditKpp, Status, Kbk, Okato, OsnPl, Period, NDoc,
  DocDate, TipPl, Nchpl, Shifr, Nplat, OstSum: string;
  CheckCharMode, CleanFields: Integer;
  var CorrRes: Integer; NotToDosCharset, TestKpp: Boolean;
  PClient: PNewClientRec; PBank: PBankFullNewRec;
  var DocRec: TDocRec; var VarLen: Integer);
const
  MesTitle: PChar = 'Добавление записи';
var
  I, CorrR, Offset, N: Integer;
  S: string;
  V: TVarDoc;
begin
  VarLen := 0;
  with DocRec do
  begin
    if TestKpp then
    begin
      MoveKpp(DebitInn, DebitName, NotToDosCharset);
      MoveKpp(CreditInn, CreditName, NotToDosCharset);
    end;
    CorrRes := 0;
    Offset := 0;
    if NewForm then
      N := 28
    else
      N := 14;
    for I := 1 to N do
    begin
      CorrR := 0;
      case I of
        1: S := Number;
        2:
          begin
            if PClient<>nil then
              DebitRs := PClient^.clAccC;
            S := Copy(DebitRs, 1, 20);
          end;
        3:
          if PBank<>nil then
            S := PBank^.brKs
          else
            S := Copy(DebitKs, 1, 20);
        4:
          if PBank<>nil then
            S := FillZeros(PBank^.brCod, 9)
          else
            S := DebitBik;
        5:
          if PClient<>nil then
            S := PClient^.clInn
          else
            S := Copy(DebitInn, 1, 16);
        6:
          if PClient<>nil then
            S := PClient^.clNameC
          else
            S := DebitName;
        7:
          if PBank<>nil then
            S := PBank^.brName
          else
            S := DebitBank;
        8: S := Copy(CreditRs, 1, 20);
        9: S := Copy(CreditKs, 1, 20);
        10: S := CreditBik;
        11: S := Copy(CreditInn, 1, 16);
        12: S := CreditName;
        13: S := CreditBank;
        14: S := Purpose;
        15:
          if PClient<>nil then
            S := PClient^.clKpp
          else
            S := DebitKpp;
        16: S := CreditKpp;
        17: S := Status;
        18: S := Kbk;
        19: S := Okato;
        20: S := OsnPl;
        21: S := Period;
        22: S := NDoc;
        23: S := DocDate;
        24: S := TipPl;
        25: S := Nchpl;
        26: S := Shifr;
        27: S := Nplat;
        28: S := OstSum;
        else
          S := '';
      end;
      if (CheckCharMode>0) and ((I=6) or (I=7) or (I=12) or (I=13) or (I=14)) then
      begin
        CorrR := CorrText(PChar(S), CheckCharMode>1, NotToDosCharset);
        if CorrR<>0 then
        begin
          if CorrRes>=0 then
            CorrRes := CorrR;
        end;
      end;
      if (CleanFields=1) or (CleanFields=3) then
        S := DelCR(S);
      if (CleanFields=2) or (CleanFields=3) then
        S := RemoveDoubleSpaces(S);
      S := Trim(S);
      StrPLCopy(@V, S, SizeOf(V));
      if not NotToDosCharset then
        WinToDos(V);
      StrCopy(@drVar[Offset], V);
      Offset := Offset + StrLen(V) + 1;
    end;
    {DosToWinL(@drVar[Offset], Offset);}
    VarLen := Offset;
  end;
end;

function CalcUserRecCRC(var UserRec: TUserRec): Byte;
var
  L: Integer;
begin
  with UserRec do
  begin
    Result := CalcCRC(@urNumber, 4);
    Result := Result xor urLevel;
    Result := Result xor CalcCRC(@urFirmNumber, 4);
    L := StrLen(urInfo);
    if L>SizeOf(urInfo) then
      L := SizeOf(urInfo);
    Result := Result xor CalcCRC(@urInfo, L);
  end;
end;

end.
