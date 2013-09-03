unit Posting;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, WinSock, Btrieve, Buttons, ExtCtrls, ComCtrls, CommCons,
  Bases, Registr, Utilits, ObmenFrm, Common, ClntCons, Sign, BtrDS;

const
  PackSize: Word = 4096;
var
  poSum: comp;
  poDocs, poLetters, poFiles: word;
  piDocs, piLetters, piRets, piKarts, piBills, piFiles, piAccepts, piDoubles,
    piAccStates, piBanks: Word;
  KeyBuf: array[0..255] of char;
  LastDaysDate, FirstDocDate: Word;
  OldDocCount: Integer;

{const
  PackSize: Word = 4096;
var
  poSum: comp;
  poDocs, poLetters, poFiles: word;
  piDocs, piLetters, piRets, piKarts, piBills, piFiles, piAccepts, piDoubles,
    piAccStates, piBanks: Word;}
  ReceiverAcc: string[16];
  ReceiverNode: Integer = 1;
  AccDataSet, BillDataSet, DocDataSet, BankDataSet, NpDataSet,
    FileDataSet, AccArcDataSet, ModuleDataSet, EMailDataSet: TExtBtrDataSet;
  {KeyBuf: array[0..255] of char;
  LastDaysDate, FirstDocDate: Word;
  OldDocCount: Integer;}

procedure ShowComment(S: string);
procedure GetSentDoc(OutB: TBtrBase; p: PSndPack);
procedure SendDoc(OutB: TBtrBase; p: PSndPack); {Сформируем пакеты на отправку}
procedure ReceiveDoc(InB: TBtrBase; p: PRcvPack);
procedure GenerateFiles;

implementation

const
  P: array[0..255] of Char = '';

procedure ShowComment(S: string);
begin
  StrPLCopy(P, S, SizeOf(P)-1);
  SendMessage(Application.MainForm.Handle, WM_SHOWHINT, WParam(@P), 0);
  Application.ProcessMessages;
end;

function TestBankSign(P: Pointer; Len: Integer; Node: word): Boolean;
var
  NF, NT, NO: word;
  Res: integer;
begin
  NT := 0;
  NF := 0;
  NO := 0;
  Res := TestSign(P, Len, NF, NO, NT);
  Result := ((Res=$10) or (Res=$110)) and (NF=Node);
end;

function TestClientSign(P: Pointer; Len: Integer; Node: word): Boolean;
var
  NF, NT, NO: word;
  Res: integer;
begin
  Result := False;
  if Len>=0 then
  begin
    NT := 0;
    NF := 0;
    NO := 0;
    Res := TestSign(P, Len, NF, NO, NT);
    Result := (Res=$5) and (NT=Node)
  end;
end;

procedure GetSentDoc(OutB: TBtrBase; p: PSndPack);
const
  ProcTitle: PChar = 'Проверка отправки пакетов';
var
  Res, Len, LenP: integer;
  i: integer;
  KeyL: longint;
  ErrorsInPacket: boolean;
  PayRec: TPayRec;
  LetterRec: TLetterRec;
  w: word;
  F: file;
  PieceByte: Byte;
begin
  //New(pd);
  Len := SizeOf(p^);
  Res := OutB.GetFirst(p^, Len, KeyBuf, 0);
  while (Res=0) or (Res=22) do
  begin
    if (Res=0) and (p^.spByteS=PackByteSC)
      and (p^.spWordS=PackWordS) then
    begin
      if p^.spFlSnd='2' then      {отправлен?}
      begin
        i := 0;
        LenP := Len-(SizeOf(TSndPack)-MaxPackSize);
        ErrorsInPacket := not TestClientSign(@p^.spText, LenP, ReceiverNode);
        if ErrorsInPacket then
          MessageBox(Application.Handle, 'Ошибка шифрации в отправленном пакете',
            ProcTitle, MB_OK or MB_ICONERROR)
        else
          Dec(LenP, SignSize);
        while (i<LenP) and not ErrorsInPacket do
        begin
          PieceByte := PByte(@p^.spText[i])^;
          case PieceByte of
            psOutDoc1:
              begin
                KeyL := PLong(@p^.spText[i+1])^;
                Len := SizeOf(PayRec);
                Res := DocDataSet.BtrBase.GetEqual(PayRec, Len, KeyL, 0);
                if (Res<>0) and (Res<>4) then
                  begin
                    MessageBox(Application.Handle, PChar('Ошибка поиска N '+IntToStr(Res)
                      +' по ключу 0 в doc.btr для '+IntToStr(KeyL)),
                      ProcTitle, MB_OK or MB_ICONERROR);
                    ErrorsInPacket := true;
                  end
                else
                  if Res=0 then
                  begin
                    w := dsSndSent;
                    if p^.spFlRcv='1' then
                      w := dsSndRcv;
                    if (PayRec.dbState and dsSndType)<w then
                    begin
                      PayRec.dbState := (PayRec.dbState and not dsSndType) or w;
                      Res := DocDataSet.BtrBase.Update(PayRec, Len, KeyL, 0);
                      if Res<>0 then
                      begin
                        MessageBox(Application.Handle, PChar(
                          'Не удалось обновить состояние документа '+DocInfo(PayRec)
                          +#13#10'BtrErr='+IntToStr(Res)),
                          ProcTitle, MB_OK or MB_ICONERROR);
                        ErrorsInPacket := true;
                      end;
                    end
                  end;
                Inc(i, PWord(@p^.spText[i+5])^+7);
              end;
            psEMail1, psEMail2:
              begin
                KeyL := PLong(@p^.spText[i+1])^;
                Len := SizeOf(LetterRec);
                Res := EMailDataSet.BtrBase.GetEqual(LetterRec, Len, KeyL, 0);
                if (Res<>0) and (Res<>4) then
                begin
                  MessageBox(Application.Handle,
                    PChar('Отправленное письмо не найдено.'#13#10
                    +'Ошибка поиска N '+IntToStr(Res)
                    +' по ключу 0 в email.btr для '+IntToStr(KeyL)),
                    ProcTitle, MB_OK or MB_ICONERROR);
                  ErrorsInPacket := true;
                end
                else begin
                  w := dsSndSent;
                  if p^.spFlRcv='1' then {принят?}
                    w := dsSndRcv;
                  if (LetterRec.lrState and dsSndType)<w then
                  begin
                    LetterRec.lrState := (LetterRec.lrState and not dsSndType) or w;
                    Res := EMailDataSet.BtrBase.Update(LetterRec, Len, KeyL, 0);
                    if Res<>0 then
                    begin
                      MessageBox(Application.Handle, PChar('Не удалось обновить письмо.'#13#10
                        +'Ошибка N '+IntToStr(Res)), ProcTitle, MB_OK or MB_ICONERROR);
                      ErrorsInPacket := true;
                    end;
                  end;
                end;
                if PieceByte=psEMail1 then
                  Inc(i, PWord(@p^.spText[i+5])^+7)
                else
                  Inc(i, PWord(@p^.spText[i+5])^+11);
              end;
            psFile:
              begin
                Inc(i, PWord(@p^.spText[i+1])^);
              end;
            else begin
              MessageBox(Application.Handle, PChar('В пакете на отправку найдено неизвестное сообщение тип '
                +IntToStr(PByte(@p^.spText[i])^)), ProcTitle, MB_OK or MB_ICONERROR);
              i := LenP+1;
            end;
          end;
        end;
        if i<>LenP then
        begin
          ErrorsInPacket := True;
          MessageBox(Application.Handle, 'Ошибка в пакете', ProcTitle,
            MB_OK or MB_ICONERROR);
        end;
        if p^.spFlRcv='1' then
        begin
          if ErrorsInPacket and (MessageBox(Application.Handle,
            'Удалить ошибочный пакет после сохранения?', ProcTitle,
            MB_YESNOCANCEL or MB_ICONWARNING)=ID_YES) then
          begin
            MakeRegNumber(rnBadFile, i);
            AssignFile(F, PostDir+'Bad\pk'+IntToStr(i)+'.out');
            {$I-} Rewrite(F, 1); {$I+}
            if IOResult=0 then
            begin
              BlockWrite(F, p^, Len);
              CloseFile(F);
              ErrorsInPacket := False;
            end;
          end;
          if not ErrorsInPacket then
            Res := OutB.Delete(0);
        end;
      end
      else
        Res := OutB.Delete(0)
    end;
    Len := SizeOf(p^);
    Res := OutB.GetNext(p^, Len, KeyBuf, 0);
  end;
  //Dispose(pd);
end;

{function EMailIsSigned(var P: TLetterRec): Boolean;
var
  i: Word;
begin
  i := StrLen(P.lrText)+1;
  i := i+StrLen(@P.lrText[i])+1;
  Result := (P.lrText[i]=Chr($1A)) and
    (P.lrText[i+SignSize-1]=Chr($1A));
end;}

const
  SendFileIndent: Word = 0;

procedure SendDoc(OutB: TBtrBase; p: PSndPack); {Сформируем пакеты на отправку}
const
  ProcTitle: PChar = 'Формирование пакетов';
var
  Size, Res, Len: Integer;
  KeyBuf: array[0..511] of Char;

  procedure AddPack; {запишем пакет}
  begin
    FillChar(p^.spNameR, SizeOf(p^.spNameR), ' ');
    Move(ReceiverAcc[1], p^.spNameR, Length(ReceiverAcc));
    with p^ do
    begin
      spByteS := PackByteSC;
      spWordS := PackWordS;
      spLength := 0;
      MakeRegNumber(rnPackage, spNum);
      spFlSnd := '0';
      spFlRcv := '0';
    end;
    Res := MakeSign(@p^.spText, Size, ReceiverNode, 0);
    if Res>0 then
    begin
      Inc(Size, Res);
      Len := (SizeOf(TSndPack)-MaxPackSize)+Size;
      Res := OutB.Insert(p^, Len, KeyBuf, 0);
      if Res<>0 then
        MessageBox(Application.Handle, PChar('Не удалось добавить пакет Id='
          +IntToStr(p^.spNum)+' BtrErr='+IntToStr(Res)),
          ProcTitle, MB_OK or MB_ICONERROR);
    end
    else
      MessageBox(Application.Handle, 'Не удалось зашифровать пакет',
        ProcTitle, MB_OK or MB_ICONERROR);
  end;

var
  KeyL, Len2: Longint;
  PayRec: TPayRec;
  LetterRec: TLetterRec;
  TxtBuf: PChar;
begin
  Size := 0;

  {запакетируем документы}
  //New(pd);
  Len := SizeOf(PayRec);
  Res := DocDataSet.BtrBase.GetFirst(PayRec, Len, KeyL, 3);
  while (Res=0) or (Res=22) do
  begin
    if (Res=0) and ((PayRec.dbState and dsSndType)=dsSndEmpty)
      and IsSigned(PayRec, Len) then
    begin
      PByte(@p^.spText[Size])^ := psOutDoc1;
      PLong(@p^.spText[Size+1])^ := PayRec.dbIdHere;
      Len := PayRec.dbDocVarLen+(SizeOf(TDocRec)-drMaxVar+SignSize);
      PWord(@p^.spText[Size+5])^ := Len;
      Move(PayRec.dbDoc, p^.spText[Size+7], Len);
      Inc(Size, Len+7);
      if Size>=PackSize then
      begin
        AddPack;
        Size := 0;
      end;
      Inc(poDocs);
      poSum := poSum + PayRec.dbDoc.drSum;
    end;
    Len := SizeOf(PayRec);
    Res := DocDataSet.BtrBase.GetNext(PayRec, Len, KeyL, 3);
  end;
  //Dispose(pd);

  if Size>0 then
    AddPack;

  Size := 0;
  {запакетируем письма}
  Len := SizeOf(LetterRec);
  Res := EMailDataSet.BtrBase.GetFirst(LetterRec, Len, KeyL, 2);
  while Res=0 do
  begin
    if ((LetterRec.lrState and dsSndType)=dsSndEmpty) and
      LetterIsSigned(@LetterRec, Len) then
    begin
      Len2 := LetterTextVarLen(@LetterRec, Len);
      if (Len2>0) and (Len2<SizeOf(p^.spText)-7-Size) then
      begin
        PLong(@p^.spText[1])^ := LetterRec.lrIder;
        PWord(@p^.spText[5])^ := Len2;
        LetterTextPar(@LetterRec, TxtBuf, Res);
        Res := 7;
        if (LetterRec.lrState and dsExtended)=0 then
        begin
          PByte(@p^.spText)^ := psEMail1;
        end
        else begin
          PByte(@p^.spText)^ := psEMail2;
          PWord(@p^.spText[Size+Res])^ := LetterRec.lrState or dsExtended;
          Inc(Res, 2);
          PWord(@p^.spText[Size+Res])^ := LetterRec.lrTextLen;
          Inc(Res, 2);
        end;
        Move(TxtBuf^, p^.spText[Size+Res], Len2);
        Inc(Size, Len2+Res);
        AddPack;
        Size := 0;
        Inc(poLetters);
      end
      else
        ProtoMes(plError, ProcTitle,
          PChar('Письмо Id='+IntToStr(LetterRec.lrIder)
          +' Len='+IntToStr(Len)+' не входит в пакет'));
    end;
    Len := SizeOf(LetterRec);
    Res := EMailDataSet.BtrBase.GetNext(LetterRec, Len, KeyL, 2);
    Application.ProcessMessages;
  end;
end;

function DelBank(Bik: Integer): Boolean;
const
  MesTitle: PChar = 'Удаление банка';
var
  Len, Res, I: Integer;
  b: TBankNewRec;
  np: TNpRec;
begin
  Result := False;
  Len := SizeOf(b);
  Res := BankDataSet.BtrBase.GetEqual(b, Len, Bik, 0);
  if Res=0 then
  begin
    I := b.brNpIder;
    Res := BankDataSet.BtrBase.Delete(0);
    Result := Res=0;
    if Result then
    begin
      Len := SizeOf(b);
      Res := BankDataSet.BtrBase.GetEqual(b, Len, I, 1);
      if Res=4 then
      begin
        Len := SizeOf(np);
        Res := NpDataSet.BtrBase.GetEqual(np, Len, I, 0);
        if Res=0 then
          Res := NpDataSet.BtrBase.Delete(0);
      end;
    end
    else
      MessageBox(Application.Handle, 'Не удалось удалить банк ', MesTitle,
        MB_OK or MB_ICONERROR);
  end;
  Result := Res=0;
end;

function AddBank(NewBank: TBankNewRec; NewNp: TNpRec): Boolean;
const
  MesTitle: PChar = 'Добавление банка';
var
  Len, Res, I, J: Integer;
  b: TBankNewRec;
  np: TNpRec;
  Sity:
    packed record
      kName: TSity;
      kType: TSityType;
    end;
begin
  Result := False;

  Sity.kName := NewNp.npName;
  Sity.kType := NewNp.npType;
  Len := SizeOf(np);
  Res := NpDataSet.BtrBase.GetEqual(np, Len, Sity, 1);
  if Res=0 then
    I := np.npIder
  else
  if Res=4 then
  begin
    Len := SizeOf(np);
    Res := NpDataSet.BtrBase.GetLast(np, Len, I, 0);
    if Res=0 then
      Inc(I)
    else
    if Res=9 then
      I := 1
    else
      I := -1;
    if I>=0 then
    begin
      NewNp.npIder := I;
      Len := SizeOf(np);
      Res := NpDataSet.BtrBase.Insert(NewNp, Len, I, 0);
      if Res<>0 then
        I := -1;
    end;
  end
  else
    I := -1;
  NewBank.brNpIder := I;

  I := NewBank.brCod;
  Len := SizeOf(b);
  Res := BankDataSet.BtrBase.GetEqual(b, Len, I, 0);
  Len := SizeOf(NewBank);
  if Res=0 then
  begin
    J := b.brNpIder;
    Res := BankDataSet.BtrBase.Update(NewBank, Len, I, 0);
    Result := Res=0;
    if Result then
    begin
      Len := SizeOf(b);
      Res := BankDataSet.BtrBase.GetEqual(b, Len, J, 1);
      if Res=4 then
      begin
        Len := SizeOf(np);
        Res := NpDataSet.BtrBase.GetEqual(np, Len, J, 0);
        if Res=0 then
          Res := NpDataSet.BtrBase.Delete(0);
      end;
    end;
  end
  else begin
    Res := BankDataSet.BtrBase.Insert(NewBank, Len, I, 0);
    Result := Res=0;
  end;
  if not Result then
    MessageBox(Application.Handle, 'Не удалось добавить/обновить банк', MesTitle,
      MB_OK or MB_ICONERROR);
end;

procedure TestDocDate(ADate: Word);
begin
  if ADate<= LastDaysDate then
  begin
    FirstDocDate := ADate;
    Inc(OldDocCount);
  end;
end;

type
  TFilePieceKey =
    packed record
      Index: Word;
      Ident: Integer;
    end;

procedure ReceiveDoc(InB: TBtrBase; p: PRcvPack);
const
  ProcTitle: PChar = 'Обработка полученных пакетов';
var
  i, Res, Len, LenP, Bik, K: integer;
  KeyL: longint;
  LetterRec: TLetterRec;
  s: TAbonLogin;
  pa: TAccRec;
  po: TOpRec;
  KeyBuf: array[0..255] of Char;
  pd: TPayRec;
  b: TBankNewRec;
  np: TNpRec;
  PieceKind: Byte;
  FilePieceRec: TFilePieceRec;
  FileKey: TFilePieceKey;
  F: file;
  Acc: TAccount;
  TextBuf: PChar;
begin
  Len := SizeOf(p^);
  Res := InB.GetFirst(p^, Len, KeyBuf,0);
  while (Res=0) or (Res=22) do
  begin
    StrUpper(StrLCopy(s, p^.rpNameS, 9));
    StrPLCopy(s, Trim(StrPas(s)), 9);
    if (Res=0) and (p^.rpByteS=PackByteSC) and (p^.rpWordS=PackWordS)
      and ((s=ReceiverAcc) or (MessageBox(ParentWnd, PChar(
      'Получен пакет от нежданного абонента ['+s+']'#13#10'Обрабатывать?'),
      ProcTitle, MB_ICONWARNING or MB_YESNOCANCEL)=ID_YES)) then
    begin
      LenP := Len-(SizeOf(p^)-MaxPackSize);
      if TestBankSign(@p^.rpText, LenP, ReceiverNode) then
      begin
        i := 0;
        Dec(LenP, SignSize);
      end
      else begin
        MessageBox(Application.Handle, 'Ошибка шифрации в полученном пакете',
          ProcTitle, MB_OK or MB_ICONERROR);
        MakeRegNumber(rnBadFile, i);
        AssignFile(F, PostDir+'Bad\pk'+IntToStr(i)+'.inp');
        {$I-} Rewrite(F, 1); {$I+}
        if IOResult=0 then
        begin
          BlockWrite(F, p^, Len);
          CloseFile(F);
        end;
        i := LenP;
      end;
      while i<LenP do
      begin
        PieceKind := PByte(@p^.rpText[i])^;
        case PieceKind of
          psAccept:
            begin
              KeyL := PLong(@p^.rpText[i+1])^;
              Len := SizeOf(pd);
              Res := DocDataSet.BtrBase.GetEqual(pd, Len, KeyL, 0);
              if Res=0 then
              begin
                pd.dbIdKorr := PLong(@p^.rpText[i+5])^;
                pd.dbState := (pd.dbState and not dsAnsType) or dsAnsRcv;
                Res := DocDataSet.BtrBase.Update(pd, Len, KeyL, 0);
              end;
              if Res<>0 then
                MessageBox(Application.Handle,
                  PChar('Квитанция не отработала. Ошибка N '+IntToStr(Res)),
                  ProcTitle, MB_OK or MB_ICONERROR);
              Inc(i, 9);
              Inc(piAccepts);
            end;
          psInDoc1:
            begin
              FillChar(pd, SizeOf(pd)-SizeOf(pd.dbDoc), #0);
              pd.dbIdKorr := PLong(@p^.rpText[i+1])^;
              Len := PWord(@p^.rpText[i+5])^;
              Move(p^.rpText[i+7], pd.dbDoc,Len);
              pd.dbDocVarLen := Len-(SizeOf(TDocRec)-drMaxVar+SignSize);
              pd.dbState := dsInputDoc;
              if not TestBankSign(@pd.dbDoc,
                (SizeOf(pd.dbDoc)-drMaxVar+SignSize)+pd.dbDocVarLen, ReceiverNode)
              then
                pd.dbState := dsSignError or dsInputDoc;
              MakeRegNumber(rnPaydoc, pd.dbIdHere);
              pd.dbIdIn  := pd.dbIdHere;
              Len := pd.dbDocVarLen+(SizeOf(TPayRec)-drMaxVar+SignSize);
              Res := DocDataSet.BtrBase.Insert(pd, Len, KeyL, 0);
              if (Res<>0) and (Res<>5) then
                MessageBox(Application.Handle,
                  PChar('Ошибка записи входящего документа N '
                  +IntToStr(Res)+' в DocBase'), ProcTitle, MB_OK or MB_ICONERROR);
              Inc(piDocs);
              Inc(i, PWord(@p^.rpText[i+5])^+7);
            end;
          psDouble1:
            begin
              FillChar(pd, SizeOf(pd)-SizeOf(pd.dbDoc), 0);
              pd.dbIdHere := PLong(@p^.rpText[i+1])^;
              pd.dbIdKorr := PLong(@p^.rpText[i+5])^;
              Len := PWord(@p^.rpText[i+9])^;
              Move(p^.rpText[i+11], pd.dbDoc, Len);
              pd.dbDocVarLen := Len-(SizeOf(TDocRec)-drMaxVar+SignSize);
              pd.dbState := dsSndRcv;
              if not TestClientSign(@pd.dbDoc,
                (SizeOf(pd.dbDoc)-drMaxVar+SignSize)+pd.dbDocVarLen, ReceiverNode)
              then
                pd.dbState := dsSignError or dsSndRcv;
              pd.dbIdOut  := pd.dbIdHere;
              Len := pd.dbDocVarLen+(SizeOf(TPayRec)-drMaxVar+SignSize);
              Res := DocDataSet.BtrBase.Insert(pd,Len,KeyL,0);
              if (Res<>0) and (Res<>5) then
                MessageBox(Application.Handle, PChar('Ошибка записи дубликта N '
                  +IntToStr(Res)+' в DocBase'), ProcTitle, MB_OK or MB_ICONERROR);
              Inc(piDoubles);
              Inc(i, PWord(@p^.rpText[i+9])^+11);
            end;
          psAnsBill, psInBill, psSndBill:
            begin
              KeyL := POpRec(@p^.rpText[i+3])^.brIder;
              Len := SizeOf(po);
              Res := BillDataSet.BtrBase.GetEqual(po, Len, KeyL, 0);
              if (Res<>0) or (po.brVersion<POpRec(@p^.rpText[i+3])^.brVersion) then
              begin
                Len := PWord(@p^.rpText[i+1])^;
                Move(p^.rpText[i+3], po, Len);
                case po.brPrizn of
                  brtReturn:
                    Inc(piRets);
                  brtKart:
                    Inc(piKarts)
                  else
                    Inc(piBills);
                end;
                TestDocDate(po.brDate);
                if Res=0 then
                  Res := BillDataSet.BtrBase.Update(po, Len, KeyL, 0)
                else
                  Res := BillDataSet.BtrBase.Insert(po, Len, KeyL, 0);
              end;
              if Res<>0 then
                MessageBox(Application.Handle, PChar('Ошибка записи проводки N '
                  +IntToStr(Res)), ProcTitle, MB_OK or MB_ICONERROR);
              Inc(i, PWord(@p^.rpText[i+1])^+3);
            end;
          psAccState:
            begin
              KeyL := PAccRec(@p^.rpText[i+3])^.arIder;
              Len := SizeOf(pa);
              Res := AccDataSet.BtrBase.GetEqual(pa, Len, KeyL, 0);
              if Res<>0 then
              begin
                Move(p^.rpText[i+3], pa, PWord(@p^.rpText[i+1])^);
                Len := SizeOf(pa);
                Res := AccDataSet.BtrBase.Insert(pa, Len, KeyL, 0);
                if Res=5 then  { если идер изменен, то надо сначала удалить }
                begin
                  Acc := pa.arAccount;
                  Len := SizeOf(pa);
                  Res := AccDataSet.BtrBase.GetEqual(pa, Len, Acc, 1);
                  if Res=0 then
                  begin
                    Res := AccDataSet.BtrBase.Delete(1);
                    if Res=0 then
                    begin
                      Move(p^.rpText[i+3], pa, PWord(@p^.rpText[i+1])^);
                      Len := SizeOf(pa);
                      Res := AccDataSet.BtrBase.Insert(pa, Len, KeyL, 0);
                    end;
                  end;
                end;
              end
              else
                if pa.arVersion<PAccRec(@p^.rpText[i+3])^.arVersion then
                begin
                  Move(p^.rpText[i+3], pa, PWord(@p^.rpText[i+1])^);
                  Len := SizeOf(pa);
                  Res := AccDataSet.BtrBase.Update(pa, Len, KeyL, 0);
                end;
              if Res<>0 then
                MessageBox(Application.Handle, PChar('Ошибка обновления счета N '
                  +IntToStr(Res)), ProcTitle, MB_OK or MB_ICONERROR);
              Inc(piAccStates);
              Inc(i, PWord(@p^.rpText[i+1])^+3);
            end;
          psEMail1, psEMail2:
            begin
              FillChar(LetterRec, SizeOf(LetterRec)-SizeOf(LetterRec.lrText), #0);
              LetterRec.lrIdKorr := PLong(@p^.rpText[i+1])^;
              MakeRegNumber(rnPaydoc, LetterRec.lrIder);
              LetterRec.lrIdCurI := LetterRec.lrIder;
              LetterRec.lrState := dsSndRcv or dsInputDoc;
              Len := PWord(@p^.rpText[i+5])^;
              Res := 7;    
              if PieceKind=psEMail2 then    
              begin
                LetterRec.lrState := LetterRec.lrState
                  or PWord(@p^.rpText[i+Res])^;
                Inc(Res, 2);    
                LetterRec.lrTextLen := PWord(@p^.rpText[i+Res])^;
                Inc(Res, 2);    
              end;    
              K := Len;    
              if (LetterRec.lrState and dsExtended)=0 then    
              begin    
                Move(p^.rpText[i+Res], PEMailRec(@LetterRec)^.erText, Len);
                Dec(K, 2);
              end
              else begin
                Move(p^.rpText[i+Res], LetterRec.lrText, Len);
              end;
              LetterTextPar(@LetterRec, TextBuf, Len);
              if not TestBankSign(TextBuf, Len+SignSize, ReceiverNode)
              then
                LetterRec.lrState := LetterRec.lrState or dsSignError;
              Len := SizeOf(LetterRec)-SizeOf(LetterRec.lrText) + K;
              Res := EMailDataSet.BtrBase.Insert(LetterRec, Len, KeyL, 0);
              if Res<>0 then
              begin
                if Res=5 then
                  ProtoMes(plError, ProcTitle, PChar('Дубликат письма IdKorr='
                    +IntToStr(LetterRec.lrIdKorr)))
                else
                  ProtoMes(plError, ProcTitle, PChar('Не удалось записать письмо BtrErr='
                    +IntToStr(Res))+' IdKorr='+IntToStr(LetterRec.lrIdKorr));
                //SimpleErr := True;
              end;
              Inc(piLetters);
              if PieceKind=psEMail1 then
                Inc(i, PWord(@p^.rpText[i+5])^+7)
              else
                Inc(i, PWord(@p^.rpText[i+5])^+11);
            end;
          psDelBank:
            begin
              Bik := PLong(@p^.rpText[i+5])^;
              Inc(i, 9);
              DelBank(Bik);
              Inc(piBanks);
            end;
          psAddBank, psReplaceBank:
            begin
              Inc(i, 5);
              if PieceKind=psReplaceBank then
              begin
                Bik := PLong(@p^.rpText[i])^; {Старый БИК}
                Inc(i, 4);
                DelBank(Bik);
              end;
              FillChar(b, SizeOf(b), #0);
              FillChar(np, SizeOf(np), #0);
              with b do
              begin
                brCod := PLong(@p^.rpText[i])^; {Новый БИК}
                Move(p^.rpText[i+4], brKs, 20);
                {Move(p^.rpText[i+24], brType, 4);}
                Move(p^.rpText[i+24], brName, 45);
              end;
              with np do
              begin
                Move(p^.rpText[i+69], npName, 25);
                Move(p^.rpText[i+94], npType, 5);
              end;
              Inc(i, 99);
              Inc(piBanks);
              AddBank(b, np);
            end;
          psFile:
            begin
              Len := PWord(@p^.rpText[i+1])^;
              with FilePieceRec do
              begin
                fpIndex := PWord(@p^.rpText[i+3])^;
                fpIdent := PInteger(@p^.rpText[i+5])^;
                Move(p^.rpText[i+9], fpVar, Len);
                with FileKey do
                begin
                  Ident := fpIdent;
                  Index := fpIndex;
                end;
              end;
              Inc(i, Len+9);
              Res := FileDataSet.BtrBase.Insert(FilePieceRec, Len+6, FileKey, 0);
              if Res<>0 then
                MessageBox(Application.Handle, PChar('Ошибка запоминания фрагмента файла N '
                  +IntToStr(Res)), ProcTitle, MB_OK or MB_ICONERROR);
            end;
          else begin
            MessageBox(Application.Handle, PChar('Найдено сообщение неизвестного типа '
              +IntToStr(PByte(@p^.rpText[i])^)), ProcTitle, MB_OK or MB_ICONERROR);
            i := LenP; {выход из цикла}
          end;
        end;
      end;
      Res := Inb.Delete(0);
    end;
    Len := SizeOf(p^);
    Res := Inb.GetNext(p^,Len,KeyBuf,0);
  end;
end;

procedure GenerateFiles;
const
  MesTitle: PChar = 'Воссоздание файла';
var
  FilePieceRec: TFilePieceRec;
  FileKey, FileKey2: TFilePieceKey;
  CurFN, FN: string;
  F: file;
  Len, Res, K, CurIndex, LastUpdate: Integer;
  FileType: Byte;
  ModuleRec: TModuleRec;
begin
  Len := SizeOf(FilePieceRec);
  Res := FileDataSet.BtrBase.GetFirst(FilePieceRec, Len, FileKey, 0);
  while Res=0 do
  begin
    FN := '';
    CurIndex := 1;             {проверка на последовательность}
    FileKey2 := FileKey;
    while (Res=0) and (FilePieceRec.fpIndex = CurIndex) do
    begin
      FN := StrPas(@FilePieceRec.fpVar[0]);
      if Length(FN)>0 then
        Res := -1
      else begin
        Len := SizeOf(FilePieceRec);
        Res := FileDataSet.BtrBase.GetNext(FilePieceRec, Len, FileKey2, 0);
        Inc(CurIndex);
      end;
    end;
    FileType := 0;
    if (FilePieceRec.fpIndex = CurIndex) and (Length(FN)>0) then {последовательно и с последним куском?}
    begin
      CurFN := DecodeMask(FN, 5, CommonUserNumber);
      AssignFile(F, CurFN);
      {$I-} Rewrite(F, 1); {$I+}
      if IOResult=0 then
      begin
        FileKey.Index := 1;
        FileKey2 := FileKey;
        Len := SizeOf(FilePieceRec);
        Res := FileDataSet.BtrBase.GetEqual(FilePieceRec, Len, FileKey2, 0);
        while (Res=0) and (FilePieceRec.fpIdent=FileKey.Ident) do
        begin
          FN := StrPas(@FilePieceRec.fpVar[0]);
          if Length(FN)=0 then
            K := 1
          else begin
            K := Length(FN)+2;
            FileType := Byte(FilePieceRec.fpVar[K-1]);
          end;
          BlockWrite(F, FilePieceRec.fpVar[K], Len-K-6);
          Len := SizeOf(FilePieceRec);
          Res := FileDataSet.BtrBase.GetNext(FilePieceRec, Len, FileKey2, 0);
        end;
        CloseFile(F);
        if Length(FN)>0 then   {найден последний кусочек?}
        begin
          Inc(piFiles);
          FileKey2 := FileKey;
          Len := SizeOf(FilePieceRec);
          Res := FileDataSet.BtrBase.GetGE(FilePieceRec, Len, FileKey2, 0); {удалим все кусочки}
          while (Res=0) and (FileKey2.Ident=FileKey.Ident) do
          begin
            Res := FileDataSet.BtrBase.Delete(0);
            Len := SizeOf(FilePieceRec);
            FileKey2 := FileKey;
            Res := FileDataSet.BtrBase.GetGE(FilePieceRec, Len, FileKey2, 0);
          end;
          if FileType=1 then {это модуль?}
          begin
            ModuleDataSet := GlobalBase(biModule);
            if ModuleDataSet=nil then
              MessageBox(Application.Handle, PChar('База модулей закрыта для модуля ['
                +CurFN+']'), MesTitle, MB_OK or MB_ICONERROR)
            else begin
              if GetRegParamByName('LastUpdate', CommonUserNumber, LastUpdate) then
              begin
                Inc(LastUpdate);
                with ModuleDataSet do
                begin
                  FN := ExtractFileName(CurFN);
                  Len := Pos('.', FN);
                  if Len>0 then
                    FN := Copy(FN, 1, Len-1);
                  Len := SizeOf(ModuleRec);
                  with ModuleRec do
                  begin
                    mrKind := mkUpdate;
                    mrIder := LastUpdate;
                    StrPLCopy(mrName, FN, SizeOf(mrName));
                  end;
                  if AddBtrRecord(@ModuleRec, Len) then
                  begin
                    if not SetRegParamByName('LastUpdate', CommonUserNumber, False, IntToStr(LastUpdate)) then
                      MessageBox(Application.Handle, PChar('Ошибка коррекции параметра при подключении ['
                        +CurFN+']'), MesTitle, MB_OK or MB_ICONERROR);
                  end
                  else
                    MessageBox(Application.Handle, PChar('Не удалось зарегистрировать модуль обновления ['
                      +CurFN+']'), MesTitle, MB_OK or MB_ICONERROR);
                end
              end
              else
                MessageBox(Application.Handle, PChar('Не удалось взять номер посл. обновления ['
                  +CurFN+']'), MesTitle, MB_OK or MB_ICONERROR);
            end;
          end;
        end
        else begin
          Erase(F);
          MessageBox(Application.Handle, 'Не найден последний кусок файла',
            MesTitle, MB_OK or MB_ICONERROR);
        end;
      end
      else
        MessageBox(Application.Handle, PChar('Не удается создать файл ['+FN+']'),
          MesTitle, MB_OK or MB_ICONERROR);
    end;
    Inc(FileKey.Ident);  {следующий идер}
    FileKey.Index := 1;
    Len := SizeOf(FilePieceRec);
    Res := FileDataSet.BtrBase.GetGE(FilePieceRec, Len, FileKey, 0);
  end;
end;


end.
