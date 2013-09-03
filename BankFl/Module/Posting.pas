unit Posting;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, WinSock, Btrieve, CryDrv, Buttons, ExtCtrls, ComCtrls,
  BankCnBn, Basbn, Registr, Utilits, Sign, ObmenFrm, Common, CommCons,
  BUtilits, DocFunc, BtrDS, CrySign,Quorum;

procedure DoExchange(ParentForm: TForm; BaseSend, SprSend, FileSend: Boolean;
  ReSendCorr: Integer; AccList: TList; FromDate, ToDate: Word);

implementation

procedure ShowComment(S: string);
var
  P: array[0..127] of Char;
begin
  StrPLCopy(P, S, SizeOf(P)-1);
  SendMessage(Application.MainForm.Handle, WM_SHOWHINT, Integer(PChar(@P)), 0);
  Application.ProcessMessages;
end;

const
  PackSize: Word = 4096;
var
  poReturns, poKarts, poDoubles, poAccepts, poBills, poAccs, poInDocs, poLetters,
    poFiles, poBanks: Word;
  piDocs, piLetters, piRets, piBills, piFiles, piBroadcastLet: Word;
  DefPayVO, LowDate: Integer;

type
  PCollectionRec = ^CollectionRec;
  CollectionRec =
    packed record
      crCorr: longint;
      crIder: longint;
      crType: byte;
    end;

function Compare(Key1, Key2: Pointer): Integer;
var
  k1: PCollectionRec absolute Key1;
  k2: PCollectionRec absolute Key2;
begin
  if k1^.crCorr<k2^.crCorr then
    Result := -1
  else
  if k1^.crCorr>k2^.crCorr then
    Result := 1
  else
  if k1^.crType<k2^.crType then
    Result := -1
  else
  if k1^.crType>k2^.crType then
    Result := 1
  else
  if k1^.crIder<k2^.crIder then
    Result := -1
  else
  if k1^.crIder>k2^.crIder then
    Result := 1
  else
    Result := 0
end;

const
  MailerNode: Integer = 1;

procedure DoExchange(ParentForm: TForm; BaseSend, SprSend, FileSend: Boolean;
  ReSendCorr: Integer; AccList: TList; FromDate, ToDate: Word);
const
  MesTitle: PChar = 'Обмен с клиентами';
var
  Res, Len: Integer;
  Base: TBtrBase;
  ps: PSndPack;
  pr: PRcvPack;
  OwnN: array[0..0] of Char;
  KeyBuf: array[0..511] of Char;
  s: string absolute KeyBuf;

  AccDataSet, BillDataSet, DocDataSet, BankDataSet, NpDataSet,
    FileDataSet, AccArcDataSet, ModuleDataSet, EMailDataSet,
    AbonDataSet, LetterDataSet, CorrAboDataSet, CorrSprDataSet,
    SendFileDataSet: TExtBtrDataSet;

function TestBankSign(P: Pointer; Len: Integer; Node: word): Boolean;
var
  NF, NT, NO: word;
  Res: integer;
begin
  NT := 0;
  NF := 0;
  NO := 0;
  Res := TestSign(P, Len, NF, NO, NT);
  {Res := TestSign(@P.dbDoc, (SizeOf(P.dbDoc)-drMaxVar+SignSize)+P.dbDocLen,NF,NO,NT);}
  Result := ((Res=$10) or (Res=$110)) and (NF=Node);
    {if not Result then
      MessageBox(0, PChar('Res='+IntToStr(Res)+'  NF='+IntToStr(NF)), '', 0);}
end;

function TestClientSign(P: Pointer; Len: Integer; Node: word): Boolean;
var
  NF, NT, NO: word;
  Res: integer;
begin
  NT := 0;
  NF := 0;
  NO := 0;
  Res := TestSign(P, Len, NF, NO, NT);
  {Res := TestSign(@P.dbDoc, (SizeOf(P.dbDoc)-drMaxVar+SignSize)+P.dbDocLen,NF,NO,NT);}
  Result := ((Res=$5) or (Res=$4)) and (NT=Node)
end;

procedure GetSentDoc(OutB: TBtrBase; p: PSndPack);
const
  ProcTitle: PChar = 'Обработка отправленных пакетов';
var
  Res, Len, Len1: integer;
  LenP, i: Integer;
  ps: PSendFileRec;
  w: word;
  KeyL: longint;
  SimpleError: Boolean;
  s: array[0..9] of char;
  f: file of Byte;
  AbonRec: TAbonentRec;
  po: TOpRec;
  pa: TAccRec;
  KeyBuf: array[0..255] of char;
  pd: TBankPayRec;
  pe: TLetterRec;
  psa, KeySa: TSprAboRec;
  KeySf: packed record
    ksBitIder:  word;
    ksFileIder: longint;
    ksAbonent:  longint;
  end;

  procedure UpdateSprCorrState(l: word);
  begin
    KeySa.saIderR := PLong(@p^.spText[i+1])^;
    KeySa.saCorr := AbonRec.abIder;
    Len1 := SizeOf(psa);
    Res := CorrAboDataSet.BtrBase.GetEqual(psa, Len1, KeySa, 0);
    if Res=0 then
    begin
      w := 1;
      if p^.spFlRcv='1' then
        w := 2;
      if psa.saState<w then
      begin
        psa.saState := w;
        Res := CorrAboDataSet.BtrBase.Update(psa, Len1, KeySa, 0);
        if Res<>0 then
        begin
          SimpleError := True;
          ProtoMes(plError, ProcTitle,
            'Не удалось обновить состояние в CorrAbo Id='+IntToStr(psa.saIderR));
        end;
      end;
    end;
    Inc(i, l);
  end;

var
  FN: string;
  FragmType: Byte;
begin
  Len := SizeOf(p^);
  Res := OutB.GetFirst(p^, Len, KeyBuf, 0);
  while (Res=0) or (Res=22) do
  begin
    if (Res=0) and (p^.spWordS=PackWordS) and
      (p^.spByteS=PackByteSC) then
    begin
      if p^.spFlSnd<>'2' then
      begin
        Res := OutB.Delete(0);
        if Res<>0 then
          ProtoMes(plError, ProcTitle,
            'Не удалось удалить неотправленный пакет, BtrErr='+IntToStr(Res)
            +' Id='+IntToStr(p^.spIder));
      end
      else begin
        SimpleError := False;
        LenP := Len - (SizeOf(TSndPack) - MaxPackSize);
        FillChar(s, SizeOf(s), #0);
        StrLCopy(s, p^.spNameR, 9);
        I := StrLen(s)-1;
        while (I>=0) and (s[I]=' ') do
        begin
          s[I] := #0;
          Dec(I);
        end;
        StrUpper(s);
        i := 0;
        Len1 := SizeOf(AbonRec);
        Res := AbonDataSet.BtrBase.GetEqual(AbonRec, Len1, s, 2);
        if Res=0 then
        begin
          i := -1;
          if p^.spByteS=PackByteSC then
          begin
            if TestClientSign(@p^.spText, LenP, AbonRec.abNode) then
            begin
              i := 0;
              LenP := LenP-SignSize;
            end
            else
              ProtoMes(plError, ProcTitle,
                'Ошибка при дешифрации пакета Id='+IntToStr(p^.spIder));
          end
          else
            ProtoMes(plError, ProcTitle,
              'Ошибочный байт spByteS='+IntToStr(p^.spByteS)+' Id='+IntToStr(p^.spIder));
          while (i>=0) and (i<LenP) do
          begin
            FragmType := PByte(@p^.spText[i])^;
            case FragmType of
              psAccept:
                begin
                  Inc(i,9);
                end;
              psInDoc1:
                begin
                  Len1 := PWord(@p^.spText[i+5])^;
                  Inc(i, Len1+7);
                end;
              psDouble1:
                begin
                  KeyL := PLong(@p^.spText[i+5])^;
                  Len1 := SizeOf(pd);
                  Res := DocDataSet.BtrBase.GetEqual(pd, Len1, KeyL, 0);
                  if Res=0 then
                  begin
                    w := dsSndSent;
                    if p^.spFlRcv='1' then
                      w := dsSndRcv;
                    if (pd.dbState and dsSndType)<w then
                    begin
                      pd.dbState := (pd.dbState and not dsSndType) or w;
                      Res := DocDataSet.BtrBase.Update(pd, Len1, KeyL,0);
                      if Res<>0 then
                      begin
                        SimpleError := True;
                        ProtoMes(plWarning, ProcTitle,
                          'Не удалось обновить состояние документа, BtrErr='
                          +IntToStr(Res)+' Id='+IntToStr(pd.dbIdHere));
                      end;
                    end;
                  end;
                  Len1 := PWord(@p^.spText[i+9])^;
                  Inc(i, Len1+11);
                end;
              psAnsBill, psSndBill:
                begin
                  KeyL := PLong(@p^.spText[i+3])^;
                  Len1 := SizeOf(po);
                  Res := BillDataSet.BtrBase.GetEqual(po, Len1, KeyL, 0);
                  if (Res=0)
                    and (po.brVersion<=POpRec(@p^.spText[i+3])^.brVersion) then
                  begin
                    w := po.brState;
                    w := w or dsSndSent;
                    w := w or dsAnsSent;
                    if p^.spFlRcv='1' then
                    begin
                      w := w or dsSndRcv;
                      w := w or dsAnsRcv;
                    end;
                    if po.brState <> w then
                    begin
                      po.brState := w;
                      Res := BillDataSet.BtrBase.Update(po, Len1, KeyL, 0);
                      if Res<>0 then
                      begin
                        SimpleError := True;
                        ProtoMes(plWarning, ProcTitle,
                          'Не удалось обновить состояние выписки, BtrErr='
                          +IntToStr(Res)+' Id='+IntToStr(po.brIder));
                      end;
                    end;
                  end;
                  Len1 := PWord(@p^.spText[i+1])^;
                  Inc(i, Len1+3);
                end;
              psInBill:
                begin
                  KeyL := PLong(@p^.spText[i+3])^;
                  Len1 := SizeOf(po);
                  Res := BillDataSet.BtrBase.GetEqual(po, Len1, KeyL, 0);
                  if (Res=0)
                    and (po.brVersion<=POpRec(@p^.spText[i+3])^.brVersion) then
                  begin
                    w := dsReSndSent;
                    if p^.spFlRcv='1' then
                      w := dsReSndRcv;
                    if (po.brState and dsReSndType)<w then
                    begin
                      po.brState := (po.brState and not dsReSndType) or w;
                      Res := BillDataSet.BtrBase.Update(po, Len1, KeyL, 0);
                      if Res<>0 then
                      begin
                        SimpleError := True;
                        ProtoMes(plWarning, ProcTitle,
                          'Не удалось обновить состояние выписки, BtrErr='
                          +IntToStr(Res)+' Id='+IntToStr(po.brIder));
                      end;
                    end;
                  end;
                  Len1 := PWord(@p^.spText[i+1])^;
                  Inc(i, Len1+3);
                end;
              psAccState:
                begin
                  KeyL := PLong(@p^.spText[i+3])^;
                  Len1 := SizeOf(pa);
                  Res := AccDataSet.BtrBase.GetEqual(pa, Len1, KeyL, 0);
                  if (Res=0)
                    and (pa.arVersion<=PAccRec(@p^.spText[i+3])^.arVersion) then
                  begin
                    w := asSndSent;
                    if p^.spFlRcv='1' then
                      w := asSndRcv;
                    if (pa.arOpts and asSndType)<w then
                    begin
                      pa.arOpts := (pa.arOpts and not asSndType) or w;
                      Res := AccDataSet.BtrBase.Update(pa, Len1, KeyL, 0);
                      if Res<>0 then
                      begin
                        SimpleError := True;
                        ProtoMes(plWarning, ProcTitle,
                          'Не удалось обновить состояние счета, BtrErr='
                          +IntToStr(Res)+' Id='+IntToStr(pa.arIder));
                      end;
                    end;
                  end;
                  Len1 := PWord(@p^.spText[i+1])^;
                  Inc(i, Len1+3);
                end;
              psEMail1, psEMail2:
                begin
                  KeyL := PLong(@p^.spText[i+1])^;
                  Len1 := SizeOf(pe);
                  Res := EMailDataSet.BtrBase.GetEqual(pe, Len1, KeyL, 0);
                  if Res=0 then
                  begin
                    w := dsSndSent;
                    if p^.spFlRcv='1' then
                    begin
                      w := dsSndRcv;
                      if pe.lrAdr = BroadcastNode then
                        Inc(piBroadcastLet);
                        {Inc(pe.erIdKorr);  код не работает из-за немодиф-ти ключа}
                    end;
                    if (pe.lrState and dsSndType)<w then
                    begin
                      pe.lrState := (pe.lrState and not dsSndType) or w;
                      Res := EMailDataSet.BtrBase.Update(pe, Len1, KeyL, 0);
                      if Res<>0 then
                      begin
                        SimpleError := True;
                        ProtoMes(plWarning, ProcTitle,
                          'Не удалось обновить состояние письма, BtrErr='
                          +IntToStr(Res)+' Id='+IntToStr(pe.lrIder));
                      end;
                    end;
                  end;
                  Len1 := PWord(@p^.spText[i+5])^;
                  if FragmType=psEMail1 then
                    Inc(i, Len1+7)
                  else
                    Inc(i, Len1+11);
                end;
              psFile:
                begin
                  New(ps);
                  KeySf.ksBitIder := PWord(@p^.spText[i+3])^;
                  KeySf.ksFileIder := PLong(@p^.spText[i+5])^;
                  KeySf.ksAbonent := AbonRec.abIder;
                  Len1 := SizeOf(ps^);
                  Res := SendFileDataSet.BtrBase.GetEqual(ps^, Len1, KeySf, 1);
                  if Res=0 then
                  begin
                    w := 1;
                    if p^.spFlRcv='1' then
                      w := 2;
                    if ps^.sfState<w then
                    begin
                      ps^.sfState := w;
                      Res := SendFileDataSet.BtrBase.Update(ps^, Len1, KeySf, 1);
                      if Res<>0 then
                      begin
                        SimpleError := True;
                        ProtoMes(plWarning, ProcTitle,
                          'Не удалось обновить состояние фрагмента файла, BtrErr='
                          +IntToStr(Res)+' Id='+IntToStr(ps^.sfBitIder)
                          +':'+IntToStr(ps^.sfFileIder));
                      end;
                    end;
                  end;
                  Dispose(ps);
                  Len1 := PWord(@p^.spText[i+1])^;
                  Inc(i, Len1+9);
                end;
              psDelBank:
                UpdateSprCorrState(9);
              psAddBank:
                UpdateSprCorrState(104);
              psReplaceBank:
                UpdateSprCorrState(108)
              else
                i := -1;
            end;
          end;
          if p^.spFlRcv='1' then
          begin
            if (i<0) or (i<>LenP) then
            begin   {была серьезная ошибка, сохраним пакет}
              MakeRegNumber(rnBadFile, Len1);
              FN := PostDir+'Bad\pk'+IntToStr(Len1)+'.snd';
              AssignFile(F, FN);
              {$I-} Rewrite(F); {$I+}
              if IOResult=0 then
              begin
                BlockWrite(F, p^, Len);
                CloseFile(F);
                i := 0;
              end
              else
                ProtoMes(plError, ProcTitle,
                  'Не удалось сохранить плохой пакет в файл ['+FN
                  +'] Id='+IntToStr(p^.spIder));
            end;
          end
          else begin {Пакет еще не получен адресатом - не надо удалять}
            SimpleError := True;
            i := -1;
          end;
        end
        else
          ProtoMes(plWarning, ProcTitle,
            'Был отправлен пакет на уже неизвестный позывной ['+s+']');
        if (i>=0) and not SimpleError then
        begin     {пакет больше не нужен, удалим его}
          Res := OutB.Delete(0);
          if Res<>0 then
            ProtoMes(plError, ProcTitle,
              'Ошибка удаления обработанного пакета Id='+IntToStr(p^.spIder));
        end;
      end;
    end;
    Len := SizeOf(p^);
    Res := OutB.GetNext(p^,Len,KeyBuf,0);
  end;
end;

procedure MakeDocSign(var P: TBankPayRec; Node: Word);
var
  L: longint;
begin
  L := MakeSign(@P.dbDoc, SizeOf(P.dbDoc)-drMaxVar+P.dbDocVarLen, Node, 1);
  if L<=0 then
  begin
    FillChar(P.dbDoc.drVar[P.dbDocVarLen], SignSize, #0);
    ProtoMes(plError, MesTitle, 'Не удалось подписать документ на узел '
      +IntToStr(Node));
  end;
end;

{procedure MakeLetterSign(var P: TLetterRec; Node: Word);
var
  i: Word;
  L: longint;
begin
  i := StrLen(P.erText)+1;
  i := i+StrLen(@P.erText[i])+1;
  L := MakeSign(@P.erText, i, Node, 1);
  if L<=0 then
  begin
    FillChar(P.erText[i],SignSize,0);
    ProtoMes(plError, MesTitle, 'Не удалось зашифровать письмо на узел '
      +IntToStr(Node));
  end;
end;}

var
  PackControlData: TControlData;

procedure ResignLetter(const AbonNode: Word; var LetterRec: TLetterRec;
  var NewLen: Integer);
const
  MesTitle: PChar = 'Переподпись письма';
var
  L, TxtLen: Integer;
  TxtBuf: PChar;
begin
  with PackControlData do
  begin
    cdCheckSelf := False;
    cdTagNode := AbonNode;
  end;
  LetterTextPar(@LetterRec, TxtBuf, TxtLen);
  NewLen := TxtLen;
  L := AddSign(0, TxtBuf, TxtLen, erMaxVar, smOverwrite {or smShowInfo},
    @PackControlData, '');
  if L<=0 then
  begin
    L := 0;
    ProtoMes(plError, MesTitle, PChar('Не удалось создать подпись Ider='
      +IntToStr(LetterRec.lrIder)+' AbNode='+IntToStr(AbonNode)));
  end;
  NewLen := NewLen + L;
end;

{function LetterIsSigned(var P: TLetterRec): Boolean;
var
  i: Word;
begin
  i := StrLen(P.erText)+1;
  i := i+StrLen(@P.erText[i])+1;
  Result := (P.erText[i]=#$1A) and (P.erText[i+SignSize-1]=#$1A);
end;}

procedure AddPackFrag(FragType: Byte; var SndPack: TSndPack;
  Buf: PChar; BufLen: Word; {IdKorr, IdHere, Param1: Integer;} var Size: Integer);
var
  I, L: Integer;
  TxtBuf: PChar;
begin
  PByte(@SndPack.spText[Size])^ := FragType;
  I := 1;
  case FragType of
    psInDoc1, psOutDoc1, psDouble1, psInDoc2, psOutDoc2, psDouble2, psAccept:
      begin
        if FragType in [psDouble1, psDouble2, psAccept] then
        begin
          PLong(@SndPack.spText[Size+I])^ := PBankPayRec(Buf)^.dbIdKorr;
          Inc(I, 4);
        end;
        PLong(@SndPack.spText[Size+I])^ := PBankPayRec(Buf)^.dbIdHere;
        Inc(I, 4);
        if FragType=psAccept then
          BufLen := 0
        else begin
          if FragType in [psInDoc1, psOutDoc1, psDouble1] then
          begin
            PWord(@SndPack.spText[Size+I])^ := BufLen;
            Inc(I, 2);
          end
          else begin
            PWord(@SndPack.spText[Size+I])^ := BufLen;
            Inc(I, 2);
            PWord(@SndPack.spText[Size+I])^ := PBankPayRec(Buf)^.dbDocVarLen;
            Inc(I, 2);
          end;
          Move(PBankPayRec(Buf)^.dbDoc, SndPack.spText[Size+I], BufLen);
        end;
        Inc(Size, I+BufLen);
      end;
    psAnsBill, psInBill, psSndBill:
      begin
        PWord(@SndPack.spText[Size+I])^ := BufLen;
        Inc(I, 2);
        Move(Buf^, SndPack.spText[Size+I], BufLen);
        Inc(Size, I+BufLen);
      end;
    psEMail1, psEMail2:
      begin
        BufLen := LetterTextVarLen(Buf, BufLen);
        PLong(@SndPack.spText[Size+I])^ := PLetterRec(Buf)^.lrIder;
        Inc(I, 4);
        PWord(@SndPack.spText[Size+I])^ := BufLen;
        Inc(I, 2);
        LetterTextPar(Buf, TxtBuf, L);
        if FragType=psEMail2 then
        begin
          PWord(@SndPack.spText[Size+I])^ := PLetterRec(Buf)^.lrState or dsExtended;
          Inc(I, 2);
          PWord(@SndPack.spText[Size+I])^ := PLetterRec(Buf)^.lrTextLen;
          Inc(I, 2);
        end;
        Move(TxtBuf^, SndPack.spText[Size+I], BufLen);
        Inc(Size, I+BufLen);
      end;
    psFile:
      begin
        PWord(@SndPack.spText[Size+I])^ := BufLen;
        Inc(I, 2);
        PWord(@SndPack.spText[Size+I])^ := PSendFileRec(Buf)^.sfBitIder;
        Inc(I, 2);
        PLong(@SndPack.spText[Size+I])^ := PSendFileRec(Buf)^.sfFileIder;
        Inc(I, 4);
        Move(PSendFileRec(Buf)^.sfData, SndPack.spText[I], BufLen);
        Inc(Size, I+BufLen);
      end;
  end;
  {case FragType of
    psInDoc1, psInDoc2:
      IncCounter(MailForm.InDocsCountLabel, poInDocs);
    psDouble1, psDouble2:
      IncCounter(MailForm.DoublesCountLabel, poDoubles);
    psAccept:
      IncCounter(MailForm.AcceptsCountLabel, poAccepts);
    psAnsBill, psInBill, psSndBill:
      begin
        case POpRec(Buf)^.brPrizn of
          brtReturn:
            IncCounter(MailForm.RetsCountLabel, poReturns);
          brtKart:
            IncCounter(MailForm.KartsCountLabel, poKarts);
          else
            IncCounter(MailForm.BillsCountLabel, poKarts);
        end;
      end;
    psEMail1, psEMail2:
      IncCounter(MailForm.LetsCountLabel, poLets);
    psFile:
      IncCounter(MailForm.FilesCountLabel, poFiles);
  end;}
end;

const
  SendFileIndent: Word = 0;
  UpdDate1: Word = 0;

procedure SendDoc(OutB: TBtrBase; p: PSndPack); {Сформируем пакеты на отправку}
const
  ProcTitle: PChar = 'Формирование пакетов';
var
  Size, Res, ResA, Len: Integer;
  AbonRec: TAbonentRec;
  KeyBuf: array[0..255] of byte;

  procedure AddPack(Limit: Integer); {запишем пакет}
  var
    L: Integer;
  begin
    if Size>Limit then
    begin
      FillChar(p^.spNameR, SizeOf(p^.spNameR), ' ');
      L := StrLen(AbonRec.abOldLogin);
      if SizeOf(p^.spNameR)<L then
        L := SizeOf(p^.spNameR);
      Move(AbonRec.abOldLogin, p^.spNameR, L);
      with p^ do
      begin
        spByteS := PackByteSC;
        spWordS := PackWordS;
        spLength := 0;
        MakeRegNumber(rnPackage, spNum);
        spFlSnd := '0';
        spFlRcv := '0';
      end;

      Res := MakeSign(@p^.spText, Size, AbonRec.abNode, 0);
      if Res>0 then
      begin
        Inc(Size, Res);
        Len := (SizeOf(TSndPack)-MaxPackSize)+Size;
        Res := OutB.Insert(p^, Len, KeyBuf, 0);
        if Res<>0 then
          ProtoMes(plError, ProcTitle, 'Не удалось добавить пакет Num='
            +IntToStr(p^.spNum)+' BtrErr='+IntToStr(Res));
      end
      else
        ProtoMes(plError, ProcTitle, 'Не удалось зашифровать пакет Node='
          +IntToStr(AbonRec.abNode)+' Len='+IntToStr(Size));
      Size := 0;
    end;
  end;

var
  J, Len1, Key0: Integer;
  KeyL: Longint;
  d: TBankPayRec;
  LetterRec: TLetterRec;
  {FN: TFileName;}
  {F: file;}
  {Buf: array[0..MaxPackSize-1] of Char;}
  InfoList: TList;
  LastDate, KeyO, w: word;
  paa: TAccArcRec;
  KeyAA:
    packed record
      aaIder: longint;
      aaDate:   word;
    end;
  po: TOpRec;
  KeyA: TAccount;
  pa: TAccRec;
  PColRec: PCollectionRec;
  Corr: longint;
  Key2:
    packed record
      k2BitIder:  word;
      k2FileIder: longint;
      k2Abonent:  longint;
      k2State:    word;
    end;
  ps: PSendFileRec;
  psa, Key1: TSprAboRec;
  psc: TSprCorRec;
  LettType: Byte;
begin
  Size := 0;
  if BaseSend then
  begin
    InfoList := TList.Create;
    try
      { Соберем информацию по проводкам }
      LastDate := 0;
      Len := SizeOf(paa);
      Res := AccArcDataSet.BtrBase.GetLast(paa, Len, KeyAA, 0);
      if Res=0 then
        LastDate := paa.aaDate;
      KeyO := LastDate;
      Len := SizeOf(po);
      Res := BillDataSet.BtrBase.GetGT(po, Len, KeyO, 2);
      while Res=0 do
      begin
        case po.brPrizn of
          brtBill:
            begin
              if ((po.brState and dsSndType)=dsSndEmpty)
                and (po.brDate>UpdDate1) then
              begin
                KeyL := po.brDocId;
                Len := SizeOf(d);
                Res := DocDataSet.BtrBase.GetEqual(d, Len, KeyL, 0);
                if (Res=0) and (d.dbIdSender<>0) then
                begin
                  PColRec := New(PCollectionRec);
                  PColRec^.crCorr := d.dbIdSender;
                  PColRec^.crIder := po.brIder;
                  PColRec^.crType := psAnsBill{psSndBill};
                  InfoList.Add(PColRec);
                end;
              end;
              if (po.brState and dsAnsType)=dsAnsEmpty then
              begin
                KeyA := po.brAccD;
                Len := SizeOf(pa);
                Res := AccDataSet.BtrBase.GetEqual(pa, Len, KeyA, 1);
                if (Res=0) and (pa.arCorr<>0) then
                begin
                  PColRec := New(PCollectionRec);
                  PColRec^.crCorr := pa.arCorr;
                  PColRec^.crIder := po.brIder;
                  PColRec^.crType := psAnsBill;
                  InfoList.Add(PColRec);
                end;
              end;
              if (po.brState and dsReSndType) = dsReSndEmpty then
              begin
                KeyA := po.brAccC;
                Len := SizeOf(pa);
                Res := AccDataSet.BtrBase.GetEqual(pa, Len, KeyA, 1);
                if (Res=0) and (pa.arCorr<>0) then
                begin
                  PColRec := New(PCollectionRec);
                  PColRec^.crCorr := pa.arCorr;
                  PColRec^.crIder := po.brIder;
                  PColRec^.crType := psInBill;
                  InfoList.Add(PColRec);
                end;
              end;
            end;
          brtReturn, brtKart:
            begin
              if (po.brState and dsAnsType)=dsAnsEmpty then
              begin
                KeyL := po.brDocId;
                Len := SizeOf(d);
                Res := DocDataSet.BtrBase.GetEqual(d, Len, KeyL, 0);
                if (Res=0) and (d.dbIdSender<>0) then
                begin
                  PColRec := New(PCollectionRec);
                  PColRec^.crCorr := d.dbIdSender;
                  PColRec^.crIder := po.brIder;
                  PColRec^.crType := psReturn;
                  InfoList.Add(PColRec);
                end;
              end;
            end;
        end;
        Len := SizeOf(po);
        Res := BillDataSet.BtrBase.GetNext(po, Len, KeyO, 2);
      end;

      { Соберем информацию по остаткам }
      Len := SizeOf(pa);
      Res := AccDataSet.BtrBase.GetFirst(pa, Len, KeyL, 0);
      while Res=0 do
      begin
        if ((pa.arOpts and asSndType)=asSndMark) and (pa.arCorr<>0) then
        begin
          PColRec := New(PCollectionRec);
          PColRec^.crCorr := pa.arCorr;
          PColRec^.crIder := pa.arIder;
          PColRec^.crType := psAccState;
          InfoList.Add(PColRec);
        end;
        Len := SizeOf(pa);
        Res := AccDataSet.BtrBase.GetNext(pa, Len, KeyL, 0);
      end;

      { Отсортируем коллекцию и сформируем пакеты }
      InfoList.Sort(Compare);
      Size := 0;
      Corr := 0;
      j := 0;
      while j<InfoList.Count do
      begin
        PColRec := InfoList.Items[j];
        if (Size>PackSize) or (Corr<>PColRec^.crCorr) and (Corr<>0) then
          AddPack(0);
        if Corr<>PColRec^.crCorr then
        begin
          Corr := 0;
          KeyL := PColRec^.crCorr;
          Len := SizeOf(AbonRec);
          Res := AbonDataSet.BtrBase.GetEqual(AbonRec, Len, KeyL, 0);
          if (Res=0) and ((AbonRec.abLock and alSend) = 0)
            and (AbonRec.abWay = awObmen)
          then
            Corr := PColRec^.crCorr;
        end;
        if Corr<>0 then
        begin
          KeyL := PColRec^.crIder;
          case PColRec^.crType of
            psReturn:
              begin
                Len := SizeOf(po);
                Res := BillDataSet.BtrBase.GetEqual(po, Len, KeyL, 0);
                if Res=0 then
                begin
                  KeyL := po.brDocId;
                  Len1 := SizeOf(d);
                  Res := DocDataSet.BtrBase.GetEqual(d, Len1, KeyL, 0);
                  if Res=0 then
                  begin
                    if (d.dbState and dsSndType)=dsSndEmpty then
                    begin
                      PByte(@p^.spText[Size])^ := psDouble1;
                      PLong(@p^.spText[Size+1])^ := d.dbIdKorr;
                      PLong(@p^.spText[Size+5])^ := d.dbIdHere;
                      Len1 := d.dbDocVarLen+(SizeOf(d.dbDoc)-drMaxVar+SignSize);
                      PWord(@p^.spText[Size+9])^ := Len1;
                      Move(d.dbDoc,p^.spText[Size+11], Len1);
                      Inc(Size, Len1+11);
                      Inc(poDoubles);
                    end
                    else begin
                      PByte(@p^.spText[Size])^ := psAccept;
                      PLong(@p^.spText[Size+1])^ := d.dbIdKorr;
                      PLong(@p^.spText[Size+5])^ := d.dbIdHere;
                      Inc(Size, 9);
                      Inc(poAccepts);
                    end;
                    PByte(@p^.spText[Size])^ := psAnsBill;
                    PWord(@p^.spText[Size+1])^ := Len;
                    Move(po, p^.spText[Size+3], Len);
                    Inc(Size, Len+3);
                    if po.brPrizn=brtReturn then
                      Inc(poReturns)
                    else
                      Inc(poKarts);
                  end;
                end;
              end;
            psAnsBill, psInBill, psSndBill:
              begin
                Len := SizeOf(po);
                Res := BillDataSet.BtrBase.GetEqual(po, Len, KeyL, 0);
                if Res=0 then
                begin
                  KeyL := po.brDocId;
                  Len1 := SizeOf(d);
                  Res := DocDataSet.BtrBase.GetEqual(d, Len1, KeyL, 0);
                  if Res=0 then
                  begin
                    if (d.dbIdSender=Corr) and (Corr<>0) then
                    begin
                      if (d.dbState and dsSndType)=dsSndEmpty then
                      begin
                        PByte(@p^.spText[Size])^ := psDouble1;
                        PLong(@p^.spText[Size+1])^ := d.dbIdKorr;
                        PLong(@p^.spText[Size+5])^ := d.dbIdHere;
                        Len1 := d.dbDocVarLen+(SizeOf(d.dbDoc)-drMaxVar+SignSize);
                        PWord(@p^.spText[Size+9])^ := Len1;
                        Move(d.dbDoc, p^.spText[Size+11], Len1);
                        Inc(Size, Len1+11);
                        Inc(poDoubles);
                      end
                      else begin
                        PByte(@p^.spText[Size])^ := psAccept;
                        PLong(@p^.spText[Size+1])^ := d.dbIdKorr;
                        PLong(@p^.spText[Size+5])^ := d.dbIdHere;
                        Inc(Size, 9);
                        Inc(poAccepts);
                      end;
                    end
                    else begin
                      MakeDocSign(d, AbonRec.abNode);
                      PByte(@p^.spText[Size])^ := psInDoc1;
                      PLong(@p^.spText[Size+1])^ := d.dbIdHere;
                      Len1 := d.dbDocVarLen+(SizeOf(d.dbDoc)-drMaxVar+SignSize);
                      PWord(@p^.spText[Size+5])^ := Len1;
                      Move(d.dbDoc, p^.spText[Size+7], Len1);
                      Inc(Size, Len1+7);
                      Inc(poInDocs);
                    end
                  end;
                  PByte(@p^.spText[Size])^ := PColRec^.crType;
                  PWord(@p^.spText[Size+1])^ := Len;
                  Move(po, p^.spText[Size+3], Len);
                  Inc(Size, Len+3);
                  Inc(poBills);
                end
              end;
            psAccState:
              begin
                Len := SizeOf(pa);
                Res := AccDataSet.BtrBase.GetEqual(pa, Len, KeyL, 0);
                if Res=0 then
                begin
                  PByte(@p^.spText[Size])^ := PColRec^.crType;
                  PWord(@p^.spText[Size+1])^ := Len;
                  Move(pa, p^.spText[Size+3], Len);
                  Inc(Size, Len+3);
                  Inc(poAccs);
                end;
              end;
          end;
        end;
        if PColRec<>nil then
          Dispose(PColRec);
        Inc(j);
      end;
      AddPack(0);
    finally
      InfoList.Free;
    end;

    {запакетируем письма}
    Len := SizeOf(LetterRec);
    Res := LetterDataSet.BtrBase.GetFirst(LetterRec, Len, KeyL, 2);
    while Res=0 do
    begin
      if ((LetterRec.lrState and dsSndType)=dsSndEmpty)
        and LetterIsSigned(@LetterRec, Len) then
      begin
        if LetterRec.lrAdr=BroadcastNode then
        begin
          Len1 := SizeOf(AbonRec);
          ResA := AbonDataSet.BtrBase.GetFirst(AbonRec, Len1, Key0, 0);
          while ResA=0 do
          begin
            if ((AbonRec.abLock and alSend) = 0)
              and (AbonRec.abWay = awObmen) then
            begin
              {ResignLetter(AbonRec.abNode, LetterRec, Len);}
              if (LetterRec.lrState and dsExtended)=0 then
                LettType := psEMail1
              else
                LettType := psEMail2;
              {Len := LetterTextVarLen(}
              AddPackFrag(LettType, p^, @LetterRec, Len, Size);
              {PByte(@SndPack.spText)^ := psEMail; ?
              PLong(@SndPack.spText[1])^ := LetterRec.erIder;
              Len :=  StrLen(LetterRec.erText)+1;
              Inc(Len, StrLen(@LetterRec.erText[Len])+(SignSize+1));
              PWord(@SndPack.spText[5])^ := Len;
              Move(LetterRec.erText, SndPack.spText[7], Len);
              Inc(Len, 7);}
              AddPack(0);
              Inc(poLetters);
              //IncCounter(MailForm.LetsCountLabel, poLets);
            end;
            Len1 := SizeOf(AbonRec);
            ResA := AbonDataSet.BtrBase.GetNext(AbonRec, Len1, Key0, 0);
          end;
        end
        else begin
          Key0 := LetterRec.lrAdr;
          Len1 := SizeOf(AbonRec);
          ResA := AbonDataSet.BtrBase.GetEqual(AbonRec, Len1, Key0, 0);
          if (ResA=0) and ((AbonRec.abLock and alSend) = 0)
            and (AbonRec.abWay = awObmen) then
          begin
            //MakeLetterSign(e, AbonRec.crNode);
            //ResignLetter(AbonRec.abNode, LetterRec, Len);
            if (LetterRec.lrState and dsExtended)=0 then
              LettType := psEMail1
            else
              LettType := psEMail2;
            AddPackFrag(LettType, p^, @LetterRec, Len, Size);
            {PByte(@SndPack.spText)^ := psEMail; ?
            PLong(@SndPack.spText[1])^ := LetterRec.erIder;
            Len :=  StrLen(LetterRec.erText)+1;
            Inc(Len, StrLen(@LetterRec.erText[Len])+(SignSize+1));
            PWord(@SndPack.spText[5])^ := Len;
            Move(LetterRec.erText, SndPack.spText[7], Len);
            Inc(Len, 7);
            IncCounter(MailForm.LetsCountLabel, poLets);
            Size := Len;}
            Inc(poLetters);
            AddPack(0);
          end;
        end;
      end;
      Application.ProcessMessages;
      Len := SizeOf(LetterRec);
      Res := LetterDataSet.BtrBase.GetNext(LetterRec, Len, KeyL, 2);
    end;
    (*{запакетируем письма}
    Len := SizeOf(e);
    Res := LetterDataSet.BtrBase.GetFirst(e, Len, KeyL, 2);
    while Res=0 do
    begin
      if ((e.lrState and dsSndType)=dsSndEmpty) and LetterIsSigned(@e, Len) then
      begin
        if e.lrAdr=BroadcastNode then
        begin
          Len1 := SizeOf(AbonRec);
          Res := AbonDataSet.BtrBase.GetFirst(AbonRec, Len1, Key0, 0);
          while Res=0 do
          begin
            if ((AbonRec.abLock and alSend) = 0)
              and (AbonRec.abWay = awObmen) then
            begin
              ResignLetter(AbonRec.abNode, e, Len);
              if (e.lrState and dsExtended)=0 then
                LettType := psEMail1
              else
                LettType := psEMail2;
              AddPackFrag(LettType, p^, @e, Len, Size);
              Inc(poLetters);
              AddPack(0);
            end;
            Len1 := SizeOf(AbonRec);
            Res := AbonDataSet.BtrBase.GetNext(AbonRec, Len1, Key0, 0);
          end;
        end
        else begin
          Key0 := e.lrAdr;
          Len1 := SizeOf(AbonRec);
          Res := AbonDataSet.BtrBase.GetEqual(AbonRec, Len1, Key0, 0);
          if (Res=0) and ((AbonRec.abLock and alSend) = 0)
            and (AbonRec.abWay = awObmen) then
          begin
            ResignLetter(AbonRec.abNode, e, Len);
            if (e.lrState and dsExtended)=0 then
              LettType := psEMail1
            else
              LettType := psEMail2;
            AddPackFrag(LettType, p^, @e, Len, Size);
            Inc(poLetters);
            AddPack(0);
          end;
        end;
      end;
      Len := SizeOf(e);
      Res := LetterDataSet.BtrBase.GetNext(e, Len, KeyL, 2);
    end;*)
  end;

  if FileSend then
  begin
    { запакетируем кусочки файлов }
    ps := New(PSendFileRec);
    Len := SizeOf(ps^);
    Res := SendFileDataSet.BtrBase.GetFirst(ps^,Len,Key2,2);
    while Res=0 do
    begin
      if ps^.sfState<>0 then
        Break;
      KeyL := ps^.sfAbonent;
      Len1 := SizeOf(AbonRec);
      Res := AbonDataSet.BtrBase.GetEqual(AbonRec, Len1, KeyL, 0);
      if (Res=0) and ((AbonRec.abLock and alSend) = 0)
        and (AbonRec.abWay = awObmen) then
      begin  
        Dec(Len, SizeOf(ps^)-SizeOf(ps^.sfData));
        PByte(@p^.spText)^ := psFile;
        PWord(@p^.spText[1])^ := Len;
        PWord(@p^.spText[3])^ := ps^.sfBitIder;
        PLong(@p^.spText[5])^ := ps^.sfFileIder;
        Move(ps^.sfData, p^.spText[9], Len);
        Inc(Len, 9);  
        Inc(poFiles);
        Size := Len;
        AddPack(0);
      end;
      Len := SizeOf(ps^);
      Res := SendFileDataSet.BtrBase.GetNext(ps^, Len, Key2, 2);
    end;
    Dispose(ps);
    AddPack(0);
  end;

  if SprSend then
  begin
    { запакетируем обновления справочника банков }
    Corr := 0;
    Size := 0;
    FillChar(Key1, SizeOf(Key1), #0);
    Len := SizeOf(psa);
    Res := CorrAboDataSet.BtrBase.GetGE(psa, Len, Key1, 1);
    while (Res=0) and (psa.saState=0) do
    begin
      if (Size>PackSize) or (Corr<>psa.saCorr) and (Corr<>0) then
        AddPack(0);
      if Corr<>psa.saCorr then
      begin
        Corr := 0;
        Key0 := psa.saCorr;
        Len := SizeOf(AbonRec);
        Res := AbonDataSet.BtrBase.GetEqual(AbonRec, Len, Key0, 0);
        if (Res=0) and ((AbonRec.abLock and alSend) = 0)
          and (AbonRec.abWay = awObmen)
        then
          Corr := psa.saCorr;
      end;
      if Corr<>0 then
      begin
        Key0 := psa.saIderR;
        Len := SizeOf(psc);
        Res := CorrSprDataSet.BtrBase.GetEqual(psc, Len, Key0, 0);
        if Res=0 then
        begin
          PByte(@p^.spText[Size])^ := psc.scType;
          PLong(@p^.spText[Size+1])^ := psc.scIderR;
          Dec(Len, SizeOf(psc)-SizeOf(psc.scData));
          Move(psc.scData, p^.spText[Size+5], Len);
          Inc(Size, Len+5);
          Inc(poBanks);
        end;
      end;
      Len := SizeOf(psa);
      Res := CorrAboDataSet.BtrBase.GetNext(psa, Len, Key1, 1);
    end;
    AddPack(0);
  end;

  if ReSendCorr>0 then
  begin { досылка баз по корреспонденту }
    Corr := ReSendCorr;
    Len := SizeOf(AbonRec);
    Res := AbonDataSet.BtrBase.GetEqual(AbonRec, Len, Corr, 0);
    if (Res=0) and (FromDate>0) and (ToDate>0)
      and ((AccList=nil) or (AccList.Count>0)) then
    begin
      ProtoMes(plInfo, MesTitle, 'Создание досылки по абоненту: '
        +Copy(AbonRec.abOldLogin, 1, SizeOf(AbonRec.abOldLogin))
        +' с '+BtrDateToStr(FromDate)+' по '+BtrDateToStr(ToDate));
      KeyO := FromDate;
      Len := SizeOf(po);
      Res := BillDataSet.BtrBase.GetGE(po, Len, KeyO, 2);
      while (Res=0) and (KeyO<=ToDate) do
      begin
        if po.brPrizn=brtBill then
        begin
          w := 0;
          KeyA := po.brAccD;
          Len1 := SizeOf(pa);
          Res := AccDataSet.BtrBase.GetEqual(pa, Len1, KeyA, 1);
          if (Res=0) and (pa.arCorr=Corr)
            and DateIsActive(po.brDate, pa.arDateO, pa.arDateC)
            and ((AccList=nil) or (AccList.IndexOf(Pointer(pa.arIder))>=0))
          then
            w := psAnsBill;
          if w=0 then
          begin
            KeyA := po.brAccC;
            Len1 := SizeOf(pa);
            Res := AccDataSet.BtrBase.GetEqual(pa, Len1, KeyA, 1);
            if (Res=0) and (pa.arCorr=Corr)
              and DateIsActive(po.brDate, pa.arDateO, pa.arDateC)
              and ((AccList=nil) or (AccList.IndexOf(Pointer(pa.arIder))>=0))
            then
              w := psInBill;
          end;
          if w<>0 then
          begin
            KeyL := po.brDocId;
            Len1 := SizeOf(d);
            Res := DocDataSet.BtrBase.GetEqual(d, Len1, KeyL, 0);
            if Res=0 then
            begin
              if d.dbIdSender=Corr then
              begin
                PByte(@p^.spText[Size])^ := psDouble1;
                PLong(@p^.spText[Size+1])^ := d.dbIdKorr;
                PLong(@p^.spText[Size+5])^ := d.dbIdHere;
                Len1 := d.dbDocVarLen+(SizeOf(d.dbDoc)-drMaxVar+SignSize);
                PWord(@p^.spText[Size+9])^ := Len1;
                Move(d.dbDoc,p^.spText[Size+11],Len1);
                Inc(Size, Len1+11);
                Inc(poDoubles);

                PByte(@p^.spText[Size])^ := psAccept;
                PLong(@p^.spText[Size+1])^ := d.dbIdKorr;
                PLong(@p^.spText[Size+5])^ := d.dbIdHere;
                Inc(Size, 9);
                Inc(poAccepts);
              end
              else begin
                MakeDocSign(d, AbonRec.abNode);
                PByte(@p^.spText[Size])^ := psInDoc1;
                PLong(@p^.spText[Size+1])^ := d.dbIdHere;
                Len1 := d.dbDocVarLen + (SizeOf(d.dbDoc) - drMaxVar + SignSize);
                PWord(@p^.spText[Size+5])^ := Len1;
                Move(d.dbDoc, p^.spText[Size+7], Len1);
                Inc(Size, Len1+7);
                Inc(poInDocs);
              end
            end;
            PByte(@p^.spText[Size])^ := w;
            PWord(@p^.spText[Size+1])^ := Len;
            Move(po, p^.spText[Size+3], Len);
            Inc(Size, Len+3);
            Inc(poBills);
            if Size>PackSize then
              AddPack(0);
          end
        end
        else
          if ((po.brPrizn=brtReturn) or (po.brPrizn=brtKart)) and (AccList=nil) then
          begin
            KeyL := po.brDocId;
            Len1 := SizeOf(d);
            Res := DocDataSet.BtrBase.GetEqual(d, Len1, KeyL, 0);
            if (Res=0) and (d.dbIdSender=Corr) then
            begin
              PByte(@p^.spText[Size])^ := psDouble1;
              PLong(@p^.spText[Size+1])^ := d.dbIdKorr;
              PLong(@p^.spText[Size+5])^ := d.dbIdHere;
              Len1 := d.dbDocVarLen+(SizeOf(d.dbDoc)-drMaxVar+SignSize);
              PWord(@p^.spText[Size+9])^ := Len1;
              Move(d.dbDoc, p^.spText[Size+11], Len1);
              Inc(Size, Len1+11);
              Inc(poDoubles);

              PByte(@p^.spText[Size])^ := psAccept;
              PLong(@p^.spText[Size+1])^ := d.dbIdKorr;
              PLong(@p^.spText[Size+5])^ := d.dbIdHere;
              Inc(Size, 9);
              Inc(poAccepts);

              PByte(@p^.spText[Size])^ := psAnsBill;
              PWord(@p^.spText[Size+1])^ := Len;
              Move(po, p^.spText[Size+3], Len);
              Inc(Size, Len+3);
              Inc(poBills);

              if Size>PackSize then
                AddPack(0);
            end;
          end;
        Len := SizeOf(po);
        Res := BillDataSet.BtrBase.GetNext(po, Len, KeyO, 2);
      end;
      AddPack(0);
    end;
  end;
end;

(*function DelBank(Bik: Integer): Boolean;
var
  Len, Res, I: Integer;
  b: TBankRec;
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
      ProtoMes(plWarning, MesTitle, 'Не удалось удалить банк Bik='
        +IntToStr(Bik));
  end;
  Result := Res=0;
end;

function AddBank(NewBank: TBankRec; NewNp: TNpRec): Boolean;
var
  Len, Res, I, J: Integer;
  b: TBankRec;
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
    ProtoMes(plWarning, MesTitle, 'Не удалось добавить/обновить банк Bik='
      +IntToStr(NewBank.brCod));
end;
*)
var
  LastDaysDate, FirstDocDate: Word;
  {OldDocCount, }BankBik: Integer;

{procedure TestDocDate(ADate: Word);
begin
  if ADate<= LastDaysDate then
  begin
    FirstDocDate := ADate;
    Inc(OldDocCount);
  end;
end;}

type
  TFilePieceKey =
    packed record
      Index: Word;
      Ident: Integer;
    end;

(*label
  L_10;
var
  Res, Len: integer;
  j, c: integer;
  LenP, i: word;
  NF, NO, NT: word;
  KeyW: longint;
  Key0: longint;
  pe: PEMailRec;
  w: word;
  b: boolean;
  KeyA: TAccount;
  ks: TAccount;
  KeyC: array[0..9] of char;
  code: string[9];
  pa: TAccRec;
  pcr: TCorrRec;
  KeyBuf: array[0..255] of char;
  pd: TDocInBase;
begin
  Len := SizeOf(p^);
  Res := InB^.GetFirst(p^,Len,KeyBuf,0);
  while((Res=0) OR (Res=22)) do
    begin
      if((Res=0) AND (p^.rpWordS=PackWordS) AND
         ((p^.rpByteS=PackByteS) Or (p^.rpByteS=PackByteSC))) then
        begin
          LenP := word(Len)-(SizeOf(p^)-MaxPackSize);
          StrUpper(StrLCopy(KeyC,p^.rpNameS,9));
          i := 9;
          while(i>0) do
            begin
              if(KeyC[i-1]<>' ') then
                break;
              KeyC[i] := Chr(0);
              Dec(i);
            end;
          KeyC[i] := Chr(0);
          Len := SizeOf(pcr);
          Res := CorrBase^.GetEQ(pcr,Len,KeyC,1);
          if(Res<>0) then
            ErrorMessage('Получен пакет от позывного '+StrLPas(KeyC,9)+
                         ','#13#10'который отсутствует среди'+
                         #13#10'корреспондентов')
          else
            begin
              if(p^.rpByteS=PackByteSC) then
                begin
                  Res := TestPodpis(p^.rpText,LenP,NF,NO,NT);
                  if((Res<>$10) And (Res<>$110) Or (NF<>pcr.crNode)) then
                    begin
                      goto L_10;
                    end;
                  LenP := LenP-SignSize;
                end;
              i := 0;
              while(i<LenP) do
                begin
                  case PByte(@p^.rpText[i])^ of
                    psOutDoc:
                      begin
                        FillChar(pd,SizeOf(pd)-SizeOf(pd.dbDoc),0);
                        pd.dbIdKorr := PLong(@p^.rpText[i+1])^;
                        Len := PWord(@p^.rpText[i+5])^;
                        Move(p^.rpText[i+7],pd.dbDoc,Len);
                        Inc(i,Len+7);
                        pd.dbDocVarLen := Len-(SizeOf(TDocRec)-drMaxVar+SignSize);
                        pd.dbSender := pcr.crIder;
                        pd.dbState := dsSndRcv;
                        pd.dbIdHere := GetLongIdent(spIdent);
                        pd.dbIdDoc  := pd.dbIdHere;
                        if(NOT TestSign(pd,pcr.crNode)) then
                          begin
                            MakeReturn(pd,SignErrMessage);
                          end
                        else
                          begin
                            j := StrLen(@pd.dbDoc.drVar)+1;
                            FillChar(KeyA,SizeOf(KeyA),0);
                            Move(pd.dbDoc.drVar[j],KeyA,Min(SizeOf(KeyA),
                                           StrLen(@pd.dbDoc.drVar[j])));
                            Inc(j,StrLen(@pd.dbDoc.drVar[j])+1);
                            FillChar(ks,SizeOf(ks),0);
                            Move(pd.dbDoc.drVar[j],ks,Min(SizeOf(ks),
                                           StrLen(@pd.dbDoc.drVar[j])));
                            Inc(j,StrLen(@pd.dbDoc.drVar[j])+1);
                            code := Copy(Trim(StrLPas(@pd.dbDoc.drVar[j],255)),1,9);
                            b := true;
                            if((pd.dbDoc.drType<>1) AND
                               ((pcr.crType AND 1)=0)) then
                              b := false;
                            if(ks<>BankAcc) then
                              b := false;
                            Val(code,Key0,c);
                            if((c<>0) OR (Key0<>BankCode)) then
                              b := false;
                            if(b) then
                              begin
                                Len := SizeOf(pa);
                                Res := AccBase^.GetEQ(pa,Len,KeyA,1);
                                if((Res<>0) OR (pa.arCorr<>pcr.crIder)
                                   AND (pd.dbDoc.drType=1)) then
                                  begin
                                    b := false;
                                  end;
                              end;
                            if(NOT b) then
                              begin
                                MakeReturn(pd,SenderErrMessage);
                              end;
                          end;
                        Len := pd.dbDocVarLen+(SizeOf(pd)-drMaxVar+SignSize);
                        Res := DocBase^.Insert(pd,Len,Key0,0);
                        if(Res=5) then
                          ErrorMessage(
                            FormatLong('Получен дубликат документа с ключом %d',pd.dbIdKorr)+
                            ' от абонента '+StrLPas(KeyC,9))
                        else if(Res<>0) then
                          ErrorMessage(
                            FormatLong('Ошибка вставки N %d',Res)+
                            FormatLong(' в doc.btr для %d',pd.dbIdKorr)+
                            ' от абонента '+StrLPas(KeyC,9))
                        else
                           Inc(piDocs);
                      end;
                    psEMail:
                      begin
                        pe := New(PEMailRec);
                        FillChar(pe^,SizeOf(pe^)-SizeOf(pe^.erText),0);
                        pe^.erIdKorr := PLong(@p^.rpText[i+1])^;
                        Len := PWord(@p^.rpText[i+5])^;
                        Move(p^.rpText[i+7],pe^.erText,Len);
                        Inc(i,Len+7);
                        pe^.erIder := GetLongIdent(spIdent);
                        pe^.erSender := pcr.crIder;
                        pe^.erIdCurI := pe^.erIder;
                        pe^.erState := dsSndRcv;
                        pe^.erAdr := pcr.crIder;
                        if(NOT EMailTestSign(pe^,pcr.crNode)) then
                          pe^.erState := dsSndRcv OR dsDoneReturn;
                        Inc(Len,SizeOf(pe^)-SizeOf(pe^.erText));
                        Res := EMailBase^.Insert(pe^,Len,Key0,0);
                        if(Res=0) then
                          Inc(piLetters);
                        Dispose(pe);
                      end;
                  else
                    begin
                      ErrorMessage(
                        FormatLong('В полученном пакете найдено сообщение тип %d',
                                   PByte(@p^.rpText[i])^)+' от абонента '+StrLPas(KeyC,9));
                      break;
                    end;
                  end;
                end;
L_10:
              Res := Inb^.Delete(Len,0);
            end;
        end;
      Len := SizeOf(p^);
      Res := Inb^.GetNext(p^,Len,KeyBuf,0);
    end; *)

procedure ReceiveDoc(InB: TBtrBase; p: PRcvPack);
const
  ProcTitle: PChar = 'Обработка полученных пакетов';
  ProcTitle2: PChar = 'RcvDoc';
var
  i, Res, Len, LenP, K, Len1: Integer;
  KeyL: longint;
  LetterRec: TLetterRec;
  //w: word;
  KeyC: array[0..9] of char;
  pa: TAccRec;
  po: TOpRec;
  KeyBuf: array[0..255] of Char;
  pd: TBankPayRec;
  //b: TBankNewRec;
  //np: TNpRec1;
  FN: string;
  PieceKind: Byte;
  FilePieceRec: TFilePieceRec;
  FileKey: TFilePieceKey;
  F: file of Byte;
  //pcr: TCorrRec;
  AbonRec: TAbonentRec;
  KeyA: TAccount;
  //ks: TAccount;
  //code: string[9];
  FatalError{, SimpleError}: Boolean;
  CurrBtrDate: Word;
  TextBuf: PChar;
//Добавлено Меркуловым
  Number, DebitRs, DebitKs, DebitBik, DebitInn, DebitName, DebitBank,
    CreditRs, CreditKs, CreditBik, CreditInn, CreditName, CreditBank,
    Purpose, DebitKpp, CreditKpp, Status, Kbk, Okato, OsnPl, Period, NDoc,
    DocDate, TipPl, Nchpl, Shifr, Nplat, OstSum: string;
  CorrRes: Integer;

begin
  CurrBtrDate := DateToBtrDate(Date);
  Len := SizeOf(p^);
  Res := InB.GetFirst(p^, Len, KeyBuf, 0);
  while (Res=0) or (Res=22) do
  begin  {переберем все полученные пакеты}
    FillChar(KeyC, SizeOf(KeyC), #0);
    if Res=0 then
    begin   {запись прочитана полностью}
      if p^.rpByteS=PackByteSC then {пакет старого формата}
      begin
        FatalError := False;
        //SimpleError := False;
        LenP := 0;
        i := -1;
        if (p^.rpByteS=PackByteSC) and (p^.rpWordS=PackWordS) then
        begin    {пакет проверен, теперь расшифруем его}
          FillChar(KeyC, SizeOf(KeyC), #0);
          StrLCopy(KeyC, p^.rpNameS, SizeOf(KeyC)-1);
          K := StrLen(KeyC)-1;
          while (K>=0) and (KeyC[K]=' ') do
          begin
            KeyC[K] := #0;
            Dec(K);
          end;
          StrUpper(KeyC);
          K := SizeOf(AbonRec);
          Res := AbonDataSet.BtrBase.GetEqual(AbonRec, K, KeyC, 2);
          if Res=0 then
          begin
            if (AbonRec.abLock and alRecv) = 0 then
            begin
              LenP := Len-(SizeOf(p^)-MaxPackSize);
              if TestBankSign(@p^.rpText, LenP, AbonRec.abNode) then
              begin
                i := 0;
                Dec(LenP, SignSize);
              end
              else begin
                ProtoMes(plError, ProcTitle, 'Ошибка шифрации в полученном пакете Num='
                  +IntToStr(p^.rpNum)+' Login='+KeyC);
                if MessageBox(Application.Handle,
                  'Ошибка шифрации в полученном пакете'
                  +#13#10'Удалить его из почтовой базы?',
                  ProcTitle, MB_ICONERROR or MB_YESNOCANCEL) = ID_YES
                then
                  FatalError := True;
              end;
            end
            else begin
              ProtoMes(plWarning, ProcTitle,
                'Получен пакет от блокированного корреспондента ['+KeyC+']');
              if MessageBox(Application.Handle,
                PChar('Получен пакет от блокированного корреспондента ['+KeyC+']'
                +#13#10'Удалить его из почтовой базы?'),
                ProcTitle, MB_ICONERROR or MB_YESNOCANCEL) = ID_YES
              then
                FatalError := True;
            end;
          end
          else begin
            ProtoMes(plError, ProcTitle,
              'Позывной отправителя не зарегистрирован ['+KeyC+'] BtrErr='
              +IntToStr(Res));
            if MessageBox(Application.Handle,
              PChar('Позывной отправителя не зарегистрирован ['+KeyC+'] BtrErr='
              +IntToStr(Res)+#13#10'Удалить его из почтовой базы?'),
              ProcTitle, MB_ICONERROR or MB_YESNOCANCEL or MB_DEFBUTTON2) = ID_YES
            then
              FatalError := True;
          end;
        end
        else begin
          ProtoMes(plError, ProcTitle,
            'Пакет с неверной служебной информацией '#13#10
            +'ByteS=#'+IntToStr(p^.rpByteS)+', WordS=#'+IntToStr(p^.rpWordS));
          if MessageBox(Application.Handle,
            PChar('Пакет с неверной служебной информацией '#13#10
            +'ByteS=#'+IntToStr(p^.rpByteS)+', WordS=#'+IntToStr(p^.rpWordS)
            +#13#10'Удалить его из почтовой базы?'),
            ProcTitle, MB_ICONERROR or MB_YESNOCANCEL) = ID_YES
          then
            FatalError := True;
        end;
        while (i>=0) and (i<LenP) and not FatalError do
        begin                                   {разберем пакет}
          PieceKind := PByte(@p^.rpText[i])^;
          case PieceKind of
            (*
            psAccept:
              begin
                KeyL := PLong(@p^.rpText[i+1])^;
                Len1 := SizeOf(pd);
                Res := DocDataSet.BtrBase.GetEqual(pd, Len1, KeyL, 0);
                if Res=0 then
                begin
                  pd.dbIdKorr := PLong(@p^.rpText[i+5])^;
                  pd.dbState := (pd.dbState and not dsAnsType) or dsAnsRcv;
                  Res := DocDataSet.BtrBase.Update(pd, Len1, KeyL, 0);
                end;
                if Res<>0 then
                  MessageBox(Application.Handle,
                    PChar('Квитанция не отработала. Ошибка Btrieve='+IntToStr(Res)),
                    ProcTitle, MB_OK or MB_ICONERROR);
                Inc(i, 9);
              end;
            psInDoc:
              begin
                FillChar(pd, SizeOf(pd)-SizeOf(pd.dbDoc), #0);
                pd.dbIdKorr := PLong(@p^.rpText[i+1])^;
                Len1 := PWord(@p^.rpText[i+5])^;
                Move(p^.rpText[i+7], pd.dbDoc, Len1);
                pd.dbDocVarLen := Len1 - (SizeOf(TDocRec) - drMaxVar+SignSize);
                pd.dbState := dsInputDoc;
                if not TestBankSign(@pd.dbDoc,
                  (SizeOf(pd.dbDoc)-drMaxVar+SignSize)+pd.dbDocVarLen, MailerNode)
                then
                  pd.dbState := dsSignError or dsInputDoc;
                MakeRegNumber(rnPaydoc, pd.dbIdHere);
                {pd.dbIdIn  := pd.dbIdHere;}
                Len1 := pd.dbDocVarLen+(SizeOf(TBankPayRec)-drMaxVar+SignSize);
                Res := DocDataSet.BtrBase.Insert(pd, Len1, KeyL, 0);
                if (Res<>0) and (Res<>5) then
                  MessageBox(Application.Handle, PChar('Ошибка записи входящего документа N '
                    +IntToStr(Res)+' в DocBase'), ProcTitle, MB_OK or MB_ICONERROR);
                Inc(piDocs);
                Inc(i, PWord(@p^.rpText[i+5])^+7);
              end; *)
            psOutDoc1:
              begin
                FillChar(pd, SizeOf(pd)-SizeOf(pd.dbDoc), #0);
                pd.dbIdKorr := PLong(@p^.rpText[i+1])^;
                Len1 := PWord(@p^.rpText[i+5])^;
                Move(p^.rpText[i+7], pd.dbDoc, Len1);
                Inc(i, Len1+7);
                pd.dbDocVarLen := Len1-(SizeOf(TDocRec)-drMaxVar+SignSize);
                pd.dbIdSender := AbonRec.abIder;
                pd.dbState := dsSndRcv;
                pd.dbDateR := DateToBtrDate(Date); {надо брать из пакета !!!}
                pd.dbTimeR := TimeToBtrTime(Time); {надо брать из пакета !!!}
                MakeRegNumber(rnPaydoc, pd.dbIdHere);
                pd.dbIdDoc  := pd.dbIdHere;
                FN := '';  {проверим документ}
                if not TestBankSign(@pd.dbDoc,
                  (SizeOf(pd.dbDoc)-drMaxVar)+pd.dbDocVarLen+SignSize,
                  AbonRec.abNode) then
                begin
                  pd.dbState := pd.dbState or dsSignError;
                  FN := 'Ошибка электронной подписи';
                end
                else begin
                  FillChar(KeyA, SizeOf(KeyA), #0);
                  K := StrLen(@pd.dbDoc.drVar) + 1;
                  Len1 := StrLen(@pd.dbDoc.drVar[K]);
                  if Len1>SizeOf(KeyA) then
                    Len1 := SizeOf(KeyA);
                  Move(pd.dbDoc.drVar[K], KeyA, Len1);
                  Len1 := SizeOf(pa);
                  Res := AccDataSet.BtrBase.GetEqual(pa, Len1, KeyA, 1);
                  if AbonRec.abType=0 then   {клиент}
                  begin
                    if Res<>0 then
                      FN := 'Счет плательщика не зарегистрирован'
                    else begin
                      if pa.arCorr<>AbonRec.abIder then
                        FN := 'Счет зарегистрирован за другим корреспондентом'
                      else begin
                        if pa.arOpts and asLockCl <> 0 then
                          FN := 'Счет плательщика блокирован на расход'
                        else begin
                          if not DateIsActive(CurrBtrDate, pa.arDateO, pa.arDateC) then
                            FN := 'Счет плательщика неактивен в системе "Банк-клиент" на '+BtrDateToStr(CurrBtrDate)
                          else
                            if (DefPayVO=1) and (pd.dbDoc.drType<>1) or
                              (DefPayVO=101) and (pd.dbDoc.drType<>101)
                            then
                              FN := 'Недопустимый вид операции';
                        end;
                      end;
                    end;
                  end
                  else begin   {отделение}
                    if (Res<>0)
                      or (Res=0) and not DateIsActive(CurrBtrDate, pa.arDateO, pa.arDateC) then
                    begin
                      FillChar(KeyA, SizeOf(KeyA), #0);
                      K := pd.dbDocVarLen;
                      Len1 := 7;   {позиция CreditRs}
                      TakeZeroOffset(pd.dbDoc.drVar, Len1, K);
                      Len1 := StrLen(@pd.dbDoc.drVar[K]);
                      if Len1>SizeOf(KeyA) then
                        Len1 := SizeOf(KeyA);
                      Move(pd.dbDoc.drVar[K], KeyA, Len1);
                      Len1 := SizeOf(pa);
                      Res := AccDataSet.BtrBase.GetEqual(pa, Len1, KeyA, 1);
                      if (Res<>0)
                        or (Res=0) and not DateIsActive(CurrBtrDate, pa.arDateO, pa.arDateC)
                      then
                        FN := 'Счета неактивны в системе "Банк-клиент" на '+BtrDateToStr(CurrBtrDate);
                    end;
                  end;

                  //Добавлено Меркуловым
                  DecodeDocVar(pd.dbDoc, pd.dbDocVarLen, Number,
                    DebitRs, DebitKs, DebitBik, DebitInn, DebitName, DebitBank,
                    CreditRs, CreditKs, CreditBik, CreditInn, CreditName, CreditBank,
                    Purpose, DebitKpp, CreditKpp, Status, Kbk, Okato, OsnPl, Period, NDoc,
                    DocDate, TipPl, Nchpl, Shifr, Nplat, OstSum, 0, 0, CorrRes, True);
                  if (Length(Kbk)>0) and KbkNotExistInQBase(Kbk) then
                    FN := 'КБК неправильный или отсутствует в справочнике';

                  if Length(FN)=0 then
                    if AnalyzePayDoc(pd.dbDoc, pd.dbDocVarLen, BankBik, LowDate, '',
                      FN)
                    then  {корсчет не проверяется !!!}
                      FN := '';
                end;
                if Length(FN)>0 then
                  pd.dbState := pd.dbState or dsExport;
                Len1 := pd.dbDocVarLen+(SizeOf(pd)-drMaxVar)+SignSize;
                Res := DocDataSet.BtrBase.Insert(pd, Len1, K, 0);
                if Res=0 then
                begin
                  Inc(piDocs);
                  if Length(FN)>0 then
                  begin
                    FN := Copy(FN, 1, SizeOf(po.brRet));
                    if MakeReturn(pd.dbIdHere, FN, CurrBtrDate, po) then
                    begin
                      Inc(piRets);
                      ProtoMes(plInfo, ProcTitle2,
                        'AutoRet Id='+IntToStr(pd.dbIdHere)+' "'+FN+'"');
                    end
                    else
                      ProtoMes(plWarning, ProcTitle,
                        'Не удалось создать автовозврат на документ '+DocInfo(pd));
                  end;
                  ProtoMes(plInfo, ProcTitle2, 'OutDoc Id='+IntToStr(pd.dbIdHere));
                end
                else begin
                  if Res=5 then
                    ProtoMes(plWarning, ProcTitle,
                      'Получен дубликат документа с ключом '
                      +IntToStr(pd.dbIdKorr)+' от абонента '+KeyC)
                  else begin
                    //SimpleError := True;
                    ProtoMes(plError, ProcTitle,
                      'Ошибка записи документа от абонента '+KeyC+' BtrErr='
                      +IntToStr(Res)+' Id='+IntToStr(pd.dbIdHere));
                  end;
                end;
              end;
            (*psDouble:
              begin
                FillChar(pd,SizeOf(pd)-SizeOf(pd.dbDoc), 0);
                pd.dbIdHere := PLong(@p^.rpText[i+1])^;
                pd.dbIdKorr := PLong(@p^.rpText[i+5])^;
                Len1 := PWord(@p^.rpText[i+9])^;
                Move(p^.rpText[i+11], pd.dbDoc, Len1);
                pd.dbDocVarLen := Len1-(SizeOf(TDocRec)-drMaxVar+SignSize);
                pd.dbState := dsSndRcv;
                if not TestClientSign(@pd.dbDoc,
                  (SizeOf(pd.dbDoc)-drMaxVar+SignSize)+pd.dbDocVarLen, ReceiverNode)
                then
                  pd.dbState := dsSignError or dsSndRcv;
                pd.dbIdOut  := pd.dbIdHere;
                Len1 := pd.dbDocVarLen+(SizeOf(TBankPayRec)-drMaxVar+SignSize);
                Res := DocDataSet.BtrBase.Insert(pd, Len1, KeyL, 0);
                if (Res<>0) and (Res<>5) then
                  MessageBox(Application.Handle, PChar('Ошибка записи дубликта N '
                    +IntToStr(Res)+' в DocBase'), ProcTitle, MB_OK or MB_ICONERROR);
                Inc(piDocs);
                Inc(i, PWord(@p^.rpText[i+9])^+11);
              end;
            psAnsBill, psInBill:
              begin
                KeyL := POpRec(@p^.rpText[i+3])^.brIder;
                Len1 := SizeOf(po);
                Res := BillDataSet.BtrBase.GetEqual(po, Len1, KeyL, 0);
                if Res<>0 then
                begin
                  Len1 := PWord(@p^.rpText[i+1])^;
                  Move(p^.rpText[i+3], po, Len1);
                  TestDocDate(po.brDate);
                  Res := BillDataSet.BtrBase.Insert(po, Len1, KeyL, 0);
                end
                else
                  if po.brVersion<POpRec(@p^.rpText[i+3])^.brVersion then
                  begin
                    Len1 := PWord(@p^.rpText[i+1])^;
                    Move(p^.rpText[i+3], po, Len1);
                    TestDocDate(po.brDate);
                    Res := BillDataSet.BtrBase.Update(po, Len1, KeyL, 0);
                  end;  
                if Res<>0 then
                  MessageBox(Application.Handle, PChar('Ошибка записи проводки N '
                    +IntToStr(Res)), ProcTitle, MB_OK or MB_ICONERROR);
                Inc(piBills);
                Inc(i, PWord(@p^.rpText[i+1])^+3);
              end;
            psAccState:
              begin
                KeyL := PAccRec(@p^.rpText[i+3])^.arIder;
                Len1 := SizeOf(pa);
                Res := AccDataSet.BtrBase.GetEqual(pa, Len1, KeyL, 0);
                if Res<>0 then
                begin
                  Move(p^.rpText[i+3],pa,PWord(@p^.rpText[i+1])^);
                  Len1 := SizeOf(pa);
                  Res := AccDataSet.BtrBase.Insert(pa, Len1, KeyL, 0);
                end
                else
                  if pa.arVersion<PAccRec(@p^.rpText[i+3])^.arVersion then
                  begin
                    Move(p^.rpText[i+3],pa,PWord(@p^.rpText[i+1])^);
                    Len1 := SizeOf(pa);
                    Res := AccDataSet.BtrBase.Update(pa, Len1, KeyL, 0);
                  end;
                if Res<>0 then
                  MessageBox(Application.Handle, PChar('Ошибка обновления счета N '
                    +IntToStr(Res)), ProcTitle, MB_OK or MB_ICONERROR);
                Inc(i, PWord(@p^.rpText[i+1])^+3);
              end; *)
            psEMail1, psEMail2:
              begin
                FillChar(LetterRec, SizeOf(LetterRec)-SizeOf(LetterRec.lrText), #0);
                LetterRec.lrIdKorr := PLong(@p^.rpText[i+1])^;
                MakeRegNumber(rnPaydoc, LetterRec.lrIder);
                LetterRec.lrIdCurI := LetterRec.lrIder;
                LetterRec.lrSender := AbonRec.abIder;
                Len1 := PWord(@p^.rpText[i+5])^;
                LetterRec.lrState := dsSndRcv or dsInputDoc;
                LetterRec.lrAdr := AbonRec.abIder;
                Res := 7;
                if PieceKind=psEMail2 then
                begin
                  LetterRec.lrState := LetterRec.lrState
                    or PWord(@p^.rpText[i+Res])^;
                  Inc(Res, 2);
                  LetterRec.lrTextLen := PWord(@p^.rpText[i+Res])^;
                  Inc(Res, 2);
                end;
                K := Len1;
                if (LetterRec.lrState and dsExtended)=0 then
                begin
                  Move(p^.rpText[i+Res], PEMailRec(@LetterRec)^.erText, Len1);
                  Dec(K, 2);
                end
                else begin
                  Move(p^.rpText[i+Res], LetterRec.lrText, Len1);
                end;
                LetterTextPar(@LetterRec, TextBuf, Len1);
                with PackControlData do
                begin
                  cdCheckSelf := False;
                  cdTagNode := AbonRec.abNode;
                end;
                if CheckSign(TextBuf, Len1, erMaxVar, smCheckLogin,
                  @PackControlData, nil, '')<=0
                then
                  LetterRec.lrState := LetterRec.lrState or dsSignError;
                Len1 := SizeOf(LetterRec)-SizeOf(LetterRec.lrText) + K;
                Res := LetterDataSet.BtrBase.Insert(LetterRec, Len1, K, 0);
                if Res=0 then
                begin
                  Inc(piLetters);
                  //IncCounter(MailForm.InLetsCountLabel, piInLets);
                  ProtoMes(plInfo, ProcTitle2, 'Письмо Id='+IntToStr(LetterRec.lrIder));
                end
                else begin
                  if Res=5 then
                    ProtoMes(plWarning, ProcTitle2, 'Дубликат письма игнорируется Korr='
                      +IntToStr(LetterRec.lrIdKorr))
                  else begin
                    //SimpleErr := True;
                    ProtoMes(plError, MesTitle,
                      'Не удалось записать письмо от абонента '+KeyC+' Korr='
                      +IntToStr(LetterRec.lrIdKorr)+' BtrErr='+IntToStr(Res));
                  end;
                end;
                if PieceKind=psEMail1 then
                  Inc(i, PWord(@p^.rpText[i+5])^+7)
                else
                  Inc(i, PWord(@p^.rpText[i+5])^+11);
              end;
            (*psEMail1, psEMail2:
              begin
                FillChar(pe, SizeOf(pe)-SizeOf(pe.lrText), #0);
                pe.lrIdKorr := PLong(@p^.rpText[i+1])^;
                MakeRegNumber(rnPaydoc, pe.lrIder);
                pe.lrIdCurI := pe.lrIder;
                pe.lrSender := AbonRec.abIder;
                Len1 := PWord(@p^.rpText[i+5])^;
                pe.lrState := dsSndRcv;
                pe.lrAdr := AbonRec.abIder;
                Res := 7;
                if PieceKind=psEMail2 then
                begin
                  pe.lrState := pe.lrState
                    or PWord(@p^.rpText[i+Res])^;
                  Inc(Res, 2);
                end;
                K := Len1;
                if (pe.lrState and dsExtended)=0 then
                begin
                  Move(p^.rpText[i+Res], PEMailRec(@pe)^.erText, Len1);
                  Dec(K, 2);
                end
                else begin
                  Move(p^.rpText[i+Res], pe.lrText, Len1);
                  pe.lrTextLen := Len1;
                end;
                LetterTextPar(@pe, TextBuf, Len1);
                with PackControlData do
                begin
                  cdCheckSelf := False;
                  cdTagNode := AbonRec.abNode;
                  cdTagLogin := AbonRec.abLogin;
                end;
                if CheckSign(TextBuf, Len1, erMaxVar, smCheckLogin,
                  @PackControlData)<=0
                then
                  pe.lrState := pe.lrState or dsSignError;
                Len1 := SizeOf(pe)-SizeOf(pe.lrText) + K;
                Res := LetterDataSet.BtrBase.Insert(pe, Len1, K, 0);
                if Res=0 then
                begin
                  Inc(piLetters);
                  //IncCounter(MailForm.InLetsCountLabel, piInLets);
                  ProtoMes(plInfo, ProcTitle2, 'Письмо Id='+IntToStr(pe.lrIder));
                end
                else begin
                  if Res=5 then
                    ProtoMes(plWarning, ProcTitle2, 'Дубликат письма игнорируется Korr='
                      +IntToStr(pe.lrIdKorr))
                  else begin
                    //SimpleErr := True;
                    ProtoMes(plError, MesTitle,
                      'Не удалось записать письмо от абонента '+KeyC+' Korr='
                      +IntToStr(pe.lrIdKorr)+' BtrErr='+IntToStr(Res));
                  end;
                end;
                if PieceKind=psEMail1 then
                  Inc(i, PWord(@p^.rpText[i+5])^+7)
                else
                  Inc(i, PWord(@p^.rpText[i+5])^+9);

                {FillChar(pe, SizeOf(pe)-SizeOf(pe.erText), #0);
                pe.erIdKorr := PLong(@p^.rpText[i+1])^;
                MakeRegNumber(rnPaydoc, pe.erIder);
                pe.erIdCurI := pe.erIder;
                pe.erSender := AbonRec.abIder;
                Len1 := PWord(@p^.rpText[i+5])^;
                Move(p^.rpText[i+7], pe.erText, Len1);
                pe.erState := dsSndRcv;
                pe.erAdr := AbonRec.abIder;
                if not TestBankSign(@pe.erText, Len1+SignSize, MailerNode) then
                  pe.erState := dsSignError or dsSndRcv;
                Len1 := SizeOf(pe)-SizeOf(pe.erText) + Len1;
                Res := EMailDataSet.BtrBase.Insert(pe, Len1, KeyL, 0);
                if Res=0 then
                begin
                  Inc(piLetters);
                  ProtoMes(plInfo, ProcTitle2, 'psEMail Id='+IntToStr(pe.erIder));
                end
                else begin
                  //SimpleError := True;
                  ProtoMes(plError, ProcTitle,
                    'Не удалось записать письмо от абонента '+KeyC+' Id='
                    +IntToStr(pe.erIder)+' BtrErr='+IntToStr(Res));
                end;
                Inc(i, PWord(@p^.rpText[i+5])^+7);}
              end;*)
            psDelBank:
              begin
                {Bik := PLong(@p^.rpText[i+5])^;
                DelBank(Bik);}
                Inc(i, 9);
              end;
            psAddBank, psReplaceBank:
              begin
                Inc(i, 5);
                if PieceKind=psReplaceBank then
                begin
                  {Bik := PLong(@p^.rpText[i])^; {Старый БИК}
                  Inc(i, 4);
                  {DelBank(Bik);}
                end;
                (*
                FillChar(b, SizeOf(b), #0);
                FillChar(np, SizeOf(np), #0);
                with b do
                begin
                  brCod := PLong(@p^.rpText[i])^; {Новый БИК}
                  Move(p^.rpText[i+4], brKs, 20);
                  Move(p^.rpText[i+24], brType, 4);
                  Move(p^.rpText[i+28], brName, 40);
                end;
                with np do
                begin
                  Move(p^.rpText[i+68], npName, 25);
                  Move(p^.rpText[i+93], npType, 5);
                end; *)
                Inc(i, 99);
                {AddBank(b, np);}
              end;
            psFile:
              begin
                Len1 := PWord(@p^.rpText[i+1])^;
                with FilePieceRec do
                begin
                  fpIndex := PWord(@p^.rpText[i+3])^;
                  fpIdent := PInteger(@p^.rpText[i+5])^;
                  Move(p^.rpText[i+9], fpVar, Len1);
                  with FileKey do
                  begin
                    Ident := fpIdent;
                    Index := fpIndex;
                  end;
                end;
                Inc(i, Len1+9);
                Res := FileDataSet.BtrBase.Insert(FilePieceRec, Len1+6, FileKey, 0);
                if Res<>0 then
                begin
                  //SimpleError := True;
                  ProtoMes(plError, ProcTitle,
                    'Не удалось записать фрагмент файла от абонента '+KeyC
                    +' BtrErr='+IntToStr(Res));
                end;
              end;
            else begin
              ProtoMes(plError, ProcTitle,
                'В пакете найдено включение неизвестного типа '
                +IntToStr(PByte(@p^.rpText[i])^)+' от абонента '+KeyC);
              i := -1; {выход из цикла}
            end;
          end;
        end;
        if FatalError then
        begin   {была ошибка, сохраним пакет}
          i := -1;
          MakeRegNumber(rnBadFile, K);
          FN := PostDir+'Bad\pk'+IntToStr(K)+'.rcv';
          AssignFile(F, FN);
          {$I-} Rewrite(F); {$I+}
          if IOResult=0 then
          begin
            BlockWrite(F, p^, Len);
            CloseFile(F);
            ProtoMes(plWarning, ProcTitle, 'Пакет сохранен '+FN);
            i := 0;
          end
          else
            ProtoMes(plError, ProcTitle,
              'Не удалось сохранить плохой пакет в файл '+FN+' Num='
              +IntToStr(p^.rpNum)+' от абонента '+KeyC);
        end;
        if i>=0 then
        begin     {пакет больше не нужен, удалим его}
          Res := Inb.Delete(0);
          if Res<>0 then
            ProtoMes(plError, ProcTitle,
              'Ошибка удаления обработанного пакета BtrErr='+IntToStr(Res)+' Num='
              +IntToStr(p^.rpNum)+' от абонента '+KeyC);
        end;
      end;
    end
    else
      ProtoMes(plError, ProcTitle,
        'Не хватило буфера для пакета - запись пропущена Num='
        +IntToStr(p^.rpNum));
    Len := SizeOf(p^);
    Res := Inb.GetNext(p^, Len, KeyBuf, 0);
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
  Res, K, CurIndex, LastUpdate: Integer;
  {Testing: Boolean;}
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
      CurFN := DecodeMask(FN, 5, GetUserNumber);
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
              ProtoMes(plError, MesTitle, 'База модулей закрыта')
            else begin
              if GetRegParamByName('LastUpdate', GetUserNumber, LastUpdate) then
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
                    if not SetRegParamByName('LastUpdate', CommonUserNumber,
                      False, IntToStr(LastUpdate)) then
                    begin
                      ProtoMes(plError, MesTitle,
                        'Ошибка инкремента последнего ид-ра модуля при подключении ['
                        +CurFN+']');
                    end;
                  end
                  else
                    ProtoMes(plError, MesTitle,
                      'Не удалось зарегистрировать модуль обновления ['
                      +CurFN+']');
                end
              end
              else
                ProtoMes(plError, MesTitle,
                  'Не удалось взять номер посл. обновления для ['
                  +CurFN+']');
            end;
          end;
        end
        else begin
          Erase(F);
          ProtoMes(plError, MesTitle, 'Не найден последний кусок файла');
        end;
      end
      else
        ProtoMes(plError, MesTitle, 'Не удается создать файл ['+FN+']');
    end;
    Inc(FileKey.Ident);  {следующий идер}
    FileKey.Index := 1;
    Len := SizeOf(FilePieceRec);
    Res := FileDataSet.BtrBase.GetGE(FilePieceRec, Len, FileKey, 0);
  end;
end;

procedure AddMessage(Mes: string; C: Integer; var S: string);
begin
  if C>0 then
  begin
    if Length(S)>0 then
      S := S + #13#10;
    S := S + Mes + ' - ' + IntToStr(C);
  end;
end;

var
  L, WaitHostTimeOut, MailerPort, MaxAuthTry: Integer;
  SenderAcc: string[16];
  MailerURL: string[255];
  T: array[0..255] of Char;
  AccArcRec: TAccArcRec;
  KeyAA:
    packed record
      aaIder: longint;
      aaDate: word;
    end;
  ObmenIsMaked: Boolean;
  M, DocSBase, DocRBase: string;
begin
  if GetNode<=0 then
  begin
    MessageBox(Application.Handle, 'СКЗИ не инициализировано', MesTitle,
      MB_OK or MB_ICONINFORMATION);
    Exit;
  end;
  if not IsSanctAccess('PostSanc') then
  begin
    MessageBox(Application.Handle, 'Вы не можете проводить сеанс связи', MesTitle,
      MB_OK or MB_ICONINFORMATION);
    Exit;
  end;
  if GetRegParamByName('SenderAcc', GetUserNumber, T) then
  begin
    SenderAcc := StrPas(@T);
    L := Length(SenderAcc);
    if (L>0) and (L<=8) then
    begin
      if GetRegParamByName('BankBik', GetUserNumber, T) then
      begin
        Val(StrPas(@T), BankBik, L);
        if (L=0)
          and GetRegParamByName('MailerURL', GetUserNumber, T)
          and GetRegParamByName('MailerNode', GetUserNumber, MailerNode)
          and GetRegParamByName('MailerPort', GetUserNumber, MailerPort)
          and GetRegParamByName('WaitHost', GetUserNumber, WaitHostTimeOut)
          and GetRegParamByName('PackSize', GetUserNumber, Res)
          and GetRegParamByName('MaxAuthTry', GetUserNumber, MaxAuthTry)
          and GetRegParamByName('UpdDate1', GetUserNumber, UpdDate1)
          and GetRegParamByName('OldDayLimit', GetUserNumber, LowDate) then
        begin
          if LowDate<>0 then
            LowDate := DateToBtrDate(Date-LowDate);
          MailerURL := StrPas(@T);
          if (Res>1000) and (Res<MaxPackSize-(drMaxVar+7+SignSize)) then
            PackSize := Res
          else begin
            PackSize := 4096;
            ProtoMes(plWarning, MesTitle, 'Размер пакета '+IntToStr(Res)
              +' указанный в настройках некорректен. '
              +'На этот сеанс задан новый размер '+IntToStr(PackSize));
          end;
          if not GetRegParamByName('DefPayVO', GetUserNumber, DefPayVO) then
            DefPayVO := 1;
          try
            Screen.Cursor := crHourGlass;

            AccDataSet := GlobalBase(biAcc);
            BillDataSet := GlobalBase(biBill);
            DocDataSet := GlobalBase(biPay);    
            BankDataSet := GlobalBase(biBank);    
            NpDataSet := GlobalBase(biNp);
            FileDataSet := GlobalBase(biFile);
            AccArcDataSet := GlobalBase(biAccArc);    
            ModuleDataSet := GlobalBase(biModule);
            EMailDataSet := GlobalBase(biLetter);
            AbonDataSet := GlobalBase(biAbon);
            LetterDataSet := GlobalBase(biLetter);
            CorrAboDataSet := GlobalBase(biCorrAbo);
            CorrSprDataSet := GlobalBase(biCorrSpr);
            SendFileDataSet := GlobalBase(biSendFile);

            DocSBase := UserBaseDir+'doc_s.btr';
            DocRBase := UserBaseDir+'doc_r.btr';

            Base := TBtrBase.Create;

            poReturns := 0;
            poKarts := 0;
            poDoubles := 0;
            poAccepts := 0;
            poBills := 0;
            poAccs := 0;
            poInDocs := 0;
            poLetters := 0;
            poFiles := 0;
            poBanks := 0;

            piDocs := 0;
            piLetters := 0;
            piRets := 0;
            piBills := 0;
            piFiles := 0;
            piBroadcastLet := 0;
            OwnN[0] := chr(0);
            Res := Base.Open(DocSBase, baNormal);
            if Res=0 then
            begin
              ShowComment('Формирование пакетов на отправку...');
              New(ps);

              GetSentDoc(Base, ps);
              SendDoc(Base, ps);
              Dispose(ps);
              Res := Base.Close;
              ShowComment('');
              ProtoMes(plInfo, MesTitle, 'Отправка: В'
                +IntToStr(poReturns)+',Б'
                +IntToStr(poKarts)+',K'
                +IntToStr(poDoubles)+',Т'
                +IntToStr(poAccepts)+',О'
                +IntToStr(poBills)+',С'
                +IntToStr(poAccs)+',Д'
                +IntToStr(poInDocs)+',П'
                +IntToStr(poLetters)+',Н'
                +IntToStr(poBanks)+',Ф'
                +IntToStr(poFiles));
              ObmenIsMaked := MakeObmen('=Обмен данными с банком='
                +#13#10'Подготовлено на отправку:'
                +#13#10'Возвратов - '+IntToStr(poReturns)
                +#13#10'Картотек - '+IntToStr(poKarts)
                +#13#10'Дубликатов - '+IntToStr(poDoubles)
                +#13#10'Подтверждений - '+IntToStr(poAccepts)
                +#13#10'Проводок - '+IntToStr(poBills)
                +#13#10'Состояний счетов - '+IntToStr(poAccs)
                +#13#10'Входящих документов - '+IntToStr(poInDocs)
                +#13#10'Писем - '+IntToStr(poLetters)
                +#13#10'Обновлений банков - '+IntToStr(poBanks)
                +#13#10'Кусочков файлов - '+IntToStr(poFiles)
                +#13#10+'Нажмите "Начать" для продолжения...',
                MailerURL, MailerPort{10000},
                SenderAcc, @AuthKey, WaitHostTimeOut{5*60}*1000,
                MaxAuthTry{3}, '', UserBaseDir);
              {if ObmenIsMaked then
                ProtoMes(plInfo, MesTitle, 'Обмен завершен')
              else
                ProtoMes(plInfo, MesTitle, 'Обмен не завершен');}
              OwnN[0] := chr(0);
              Res := Base.Open(DocSBase, baNormal);
              ShowComment('');
              if Res=0 then
              begin
                ShowComment('Проверка отправленных пакетов...');
                New(ps);
                GetSentDoc(Base, ps);
                Dispose(ps);
                Res := Base.Close;
                OwnN[0] := chr(0);
                Res := Base.Open(DocRBase, baNormal);
                if Res=0 then
                begin
                  ShowComment('Обработка полученных пакетов...');
                  New(pr);
                  LastDaysDate := 0;
                  Len := SizeOf(AccArcRec);
                  Res := AccArcDataSet.BtrBase.GetLast(AccArcRec, Len, KeyAA, 0);
                  if Res=0 then
                    LastDaysDate := AccArcRec.aaDate
                  else
                    LastDaysDate := 0;
                  FirstDocDate := $FFFF;
                  {OldDocCount := 0;}
                  ReceiveDoc(Base, pr);
                  Dispose(pr);
                  Res := Base.Close;
                  GenerateFiles;
                  ShowComment('');
                  M := '';
                  AddMessage('документов', piDocs, M);
                  AddMessage('автовозвратов', piRets, M);
                  AddMessage('писем', piLetters, M);
                  AddMessage('проводок', piBills, M);
                    {AddMessage('обновлений счетов', piAccStates, M);}
                    {AddMessage('подтверждений', piAccepts, S);}
                    {AddMessage('обновлений банков', piBanks, M);}
                  AddMessage('файлов', piFiles, M);
                  AddMessage('подтверждений о получении массового письма', piBroadcastLet, M);
                  if Length(M)>0 then
                  begin
                    MessageBox(ParentForm.Handle,
                      PChar('Получено:'#13#10+M),
                      MesTitle, MB_OK+MB_ICONINFORMATION);
                  end;
                  ProtoMes(plInfo, MesTitle, 'Получено: Д'
                    +IntToStr(piDocs)+',В'
                    +IntToStr(piRets)+',П'
                    +IntToStr(piLetters)+',О'
                    +IntToStr(piBills)+',Ф'
                    +IntToStr(piFiles)+',М'
                    +IntToStr(piBroadcastLet));
                  {if OldDocCount>0 then
                  begin
                    ProtoMes(plWarning, MesTitle,
                      'Получены документы за уже закрытые дни - '
                      +IntToStr(OldDocCount)+#13#10
                      +'Последний закрытый день '+BtrDateToStr(LastDaysDate)
                      +#13#10+'Необходимо раскрыть операционные дни до '
                      +BtrDateToStr(FirstDocDate));
                  end;}
                end
                else
                  ProtoMes(plError, MesTitle,
                    'Не удается открыть базу входящих пакетов '+DocRBase);
              end
              else
                ProtoMes(plError, MesTitle,
                  'Не удается второй раз открыть базу исходящих пакетов '+DocSBase);
            end
            else
              ProtoMes(plError, MesTitle,
                'Не удается открыть базу исходящих пакетов '+DocSBase);
            ShowComment('');
          finally
            ShowComment('');
            Screen.Cursor := crDefault;
            try
              AccDataSet.Refresh;
              BillDataSet.Refresh;
              DocDataSet.Refresh;
              BankDataSet.Refresh;
              NpDataSet.Refresh;
              FileDataSet.Refresh;
              AccArcDataSet.Refresh;
              EMailDataSet.Refresh;

              DocDataSet.UpdateKeys;
              AccDataSet.UpdateKeys;
              AbonDataSet.UpdateKeys;
              BankDataSet.UpdateKeys;
              NpDataSet.UpdateKeys;
              EMailDataSet.UpdateKeys;
            except
              ProtoMes(plError, MesTitle, 'Ошибка Refresh');
            end;
          end;
        end
        else
          ProtoMes(plError, MesTitle, 'Не найден один из параметров в реестре:'#13#10
            +'адрес хоста, узел, порт получателя, таймаут, число попыток, число активных дней'#13#10
            +'Или ошибочно задан БИК');
      end
      else
        ProtoMes(plError, MesTitle, 'Не указан БИК в настройках');
    end
    else
      ProtoMes(plError, MesTitle, 'Неверная длина позывного отправителя '
        +IntToStr(L)+#13#10+'['+SenderAcc+']');
  end
  else
    ProtoMes(plError, MesTitle, 'Не задан позывной отправителя в настройках');
  PostMessage(ParentForm.Handle, WM_MAKEUPDATE, 0, 0);
end;

end.


