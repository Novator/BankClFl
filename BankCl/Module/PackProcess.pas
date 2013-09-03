unit PackProcess;

interface

uses Btrieve, CommCons, CrySign, Windows, SysUtils, Utilits, Registr, Forms,
  ClntCons, Bases, Dialogs, BtrDS, DocFunc;                        //Изменено

const
  PackControlData: TControlData = ();
var
  poDocs, poLetters, poFiles, OldDocCount, piBills, piRets, piDelBills, piKarts,
    piDocs, piDoubles, piLetters, piAccStates, piAccepts, piDelBanks,
    piAddBanks, piEditBanks, piFiles, piSFile, piLFile: DWord;      //Изменено
  poSum: Double;
var
  LastDaysDate: Word = 0;
  FirstDocDate: Word = $FFFF;
  IsUsedNewKey: Boolean;
  NumOfSign: Integer = 1;

procedure GetSentDoc(BaseS: TBtrBase; SenderAcc, ReceiverAcc: string;
  var Process: Boolean; CheckSndData: Boolean);
procedure SendDoc(BaseS: TBtrBase; SenderAcc,
  ReceiverAcc: string; var Process: Boolean; PackSize: Integer);
procedure ReceiveDoc(BaseR: TBtrBase; ReceiverAcc: string;
  var Process: Boolean);
procedure GenerateFiles(var Process: Boolean);

implementation

uses
  MailFrm;

procedure SendDoc(BaseS: TBtrBase; SenderAcc,
  ReceiverAcc: string; var Process: Boolean; PackSize: Integer);
const
  MesTitle: PChar = 'Формирование пакетов';
var
  Size, Res, Len, L: Integer;           //Изменено
  //KeyBuf: array[0..511] of Char;
  SndPack: TSndPack;
  NameKey: array[0..9] of Char;

  procedure AddPack; {запишем пакет}
  begin
    PackControlData.cdCheckSelf := True;
   // MessageBox(ParentWnd,PChar('Size='+IntToStr(Size)),'Check!',MB_OK);        //Временно
    Res := EncryptBlock(ceiDomenK, @SndPack.spText, Size,   {шифруем переменную часть}
      SizeOf(SndPack.spText), smShowInfo, @PackControlData);
   // MessageBox(ParentWnd,PChar(IntToStr(Res)),'Check!',MB_OK);        //Временно
    if Res>0 then
    begin
      with SndPack do
      begin
        FillChar(spNameS, SizeOf(spNameS), #0);
        StrPLCopy(spNameS, SenderAcc, SizeOf(spNameS));
        FillChar(spNameR, SizeOf(spNameR), #0);
        StrPLCopy(spNameR, ReceiverAcc, SizeOf(spNameR));
        if IsUsedNewKey then
          spByteS := PackByteSE
        else
          spByteS := PackByteSD;
        spWordS := PackWordS;
        spLength := Size;
        spDateS := DateToBtrDate(Date);
        spTimeS := TimeToBtrTime(Time);
        MakeRegNumber(rnPackage, spNum);
        if (spNum<0) and (MessageBox(Application.Handle,
          'Не удалось зарегистрировать пакет. Прервать процесс?', MesTitle,
          MB_YESNOCANCEL or MB_ICONWARNING)=ID_YES) then
        begin
          Process := False;
        end;
        spFlSnd := '0';
        spFlRcv := '0';
        spDateR := 0;
        spTimeR := 0;
    //    MessageBox(ParentWnd,PChar(spNameS+#10#13+spNameR+#10#13+IntToStr(spByteS)+
    //      #10#13+IntToStr(spWordS)+#10#13+IntToStr(spLength)+#10#13+IntToStr(spDateS)+#10#13+
    //      IntToStr(spTimeS)+#10#13+IntToStr(spNum)),'Check!',MB_OK);
      end;
      if Process then
      begin
        Len := (SizeOf(SndPack)-SizeOf(SndPack.spText))+Res;
    //    MessageBox(ParentWnd,PChar(IntToStr(Len)+#10#13+NameKey),'Check!',MB_OK); //Временно
        Res := BaseS.Insert(SndPack, Len, NameKey, 0);
        if Res<>0 then
          ProtoMes(plError, MesTitle, PChar('Не удалось добавить пакет Id='
            +IntToStr(SndPack.spNum)+' BtrErr='+IntToStr(Res)));
 //       MessageBox(ParentWnd,'Stage 5','Check!',MB_OK);          //Временно
      end;
    end
    else
      ProtoMes(plError, MesTitle, PChar('Не удалось зашифровать пакет L='
        +IntToStr(Size)));
  end;

var
  KeyL, Len2, NoS: Longint;
  KeySf: packed record                                         //Добавлено
    ksIndex:  word;                                            //Добавлено
    ksIder: longint;                                           //Добавлено
    end;                                                       //Добавлено
  PayRec: TPayRec;
  LetterRec: TLetterRec;
  FilePieceRec: TFilePieceRec;                                  //Добавлено
  DocDataSet, EMailDataSet, LFileDataSet: TExtBtrDataSet;      //Изменено
  TxtBuf: PChar;
begin
  DocDataSet := GlobalBase(biPay);
  EMailDataSet := GlobalBase(biLetter);
  LFileDataSet := GlobalBase(biLFile);                         //Добавлено

  Size := 0;

  {запакетируем документы}
  Len := SizeOf(PayRec);
  Res := DocDataSet.BtrBase.GetFirst(PayRec, Len, KeyL, 3);
  while ((Res=0) or (Res=22)) and Process do
  begin
    NoS := 0;
    if IsSigned(PayRec, Len) then
    begin
      if PayRec.dbState=dsExtended then
      begin
        if Len-(SizeOf(TPayRec)-drMaxVar+PayRec.dbDocVarLen)>=4 then
          NoS := PInteger(@PayRec.dbDoc.drVar[PayRec.dbDocVarLen])^;
      end
      else
        NoS := 1;
    end;
    if (Res=0) and ((PayRec.dbState and dsSndType)=dsSndEmpty)
      and (NoS>=Abs(NumOfSign)) then
    begin
      Len := Len-(SizeOf(PayRec)-SizeOf(PayRec.dbDoc));
      if (Len>0) and (Len<SizeOf(SndPack.spText)-9-Size) then
      begin
        PByte(@SndPack.spText[Size])^ := psOutDoc3;
        PLong(@SndPack.spText[Size+1])^ := PayRec.dbIdHere;
        PWord(@SndPack.spText[Size+5])^ := Len;
        PWord(@SndPack.spText[Size+7])^ := PayRec.dbDocVarLen;
        PWord(@SndPack.spText[Size+9])^ := PayRec.dbState;
        Move(PayRec.dbDoc, SndPack.spText[Size+11], Len);
        Inc(Size, Len+11);
        if Size>=PackSize then
        begin
          AddPack;
          Size := 0;
        end;
        poSum := poSum + PayRec.dbDoc.drSum;
        IncCounter(MailForm.DocCountLabel, poDocs);
        MailForm.TotSumLabel.Caption := SumToStr(poSum);
      end
      else
        ProtoMes(plError, MesTitle,
          PChar('Документ Id='+IntToStr(PayRec.dbIdHere)
          +' Len='+IntToStr(Len)+' не входит в пакет'));
    end;
    Len := SizeOf(PayRec);
    Res := DocDataSet.BtrBase.GetNext(PayRec, Len, KeyL, 3);
    Application.ProcessMessages;
  end;
  if Size>0 then
    AddPack;
  Size := 0;
  {запакетируем письма}
  Len := SizeOf(LetterRec);
  Res := EMailDataSet.BtrBase.GetFirst(LetterRec, Len, KeyL, 2);
  while (Res=0) and Process do
  begin
    if ((LetterRec.lrState and dsSndType)=dsSndEmpty) and
      LetterIsSigned(@LetterRec, Len) then
    begin
      Len2 := LetterTextVarLen(@LetterRec, Len);
      if (Len2>0) and (Len2<SizeOf(SndPack.spText)-7-Size) then
      begin
        PLong(@SndPack.spText[1])^ := LetterRec.lrIder;
        PWord(@SndPack.spText[5])^ := Len2;
        LetterTextPar(@LetterRec, TxtBuf, Res);
        Res := 7;
        if (LetterRec.lrState and dsExtended)=0 then
        begin
          PByte(@SndPack.spText)^ := psEMail1;
        end
        else begin
          PByte(@SndPack.spText)^ := psEMail2;
          PWord(@SndPack.spText[Size+Res])^ := LetterRec.lrState or dsExtended;
          Inc(Res, 2);
          PWord(@SndPack.spText[Size+Res])^ := LetterRec.lrTextLen;
          Inc(Res, 2);
        end;
        Move(TxtBuf^, SndPack.spText[Size+Res], Len2);
        Inc(Size, Len2+Res);
        AddPack;
        Size := 0;
        IncCounter(MailForm.LetCountLabel, poLetters);
      end
      else
        ProtoMes(plError, MesTitle,
          PChar('Письмо Id='+IntToStr(LetterRec.lrIder)
          +' Len='+IntToStr(Len)+' не входит в пакет'));
    end;
    Len := SizeOf(LetterRec);
    Res := EMailDataSet.BtrBase.GetNext(LetterRec, Len, KeyL, 2);
    Application.ProcessMessages;
  end;

  //Добавлено Меркуловым
  // Запакетируем файлы для отправки
  if LFileDataSet<>nil then
  begin
    Size := 0;
    //FilePieceRec := New(PFilePieceRec);
    Len := SizeOf(FilePieceRec);
    Res := LFileDataSet.BtrBase.GetFirst(FilePieceRec, Len, KeySf, 0);
    while (Res=0) and Process do
    begin
      L := StrLen(@FilePieceRec.fpVar[0]);
      if (L>0) then
        Inc(L);
      if Byte(FilePieceRec.fpVar[L])=0 then
        begin
        Len := Len -(SizeOf(FilePieceRec)-SizeOf(FilePieceRec.fpVar));
        if (Len>0) and (Len<SizeOf(SndPack.spText)-9-Size) then
          begin
          PByte(@SndPack.spText[Size])^ := psSFile;
          PWord(@SndPack.spText[Size+1])^ := Len;
          PWord(@SndPack.spText[Size+3])^ := FilePieceRec.fpIndex;
          PInteger(@SndPack.spText[Size+5])^ := FilePieceRec.fpIdent;
          Move(FilePieceRec.fpVar,SndPack.spText[Size+9],Len);
          Inc(Size, Len+9);
          AddPack;
          Size :=0;
          if (Length(StrPas(@FilePieceRec.fpVar[0]))>0) then
            IncCounter(MailForm.FilCountLabel, poFiles);
          end
        else
          ProtoMes(plError, MesTitle,
              PChar('Файл Id='+IntToStr(FilePieceRec.fpIdent)
              +' Len='+IntToStr(Len)+' не входит в пакет'));
        end;
      Len := SizeOf(FilePieceRec);
      Res := LFileDataSet.BtrBase.GetNext(FilePieceRec, Len, KeySf, 0);
      Application.ProcessMessages;
    end;
  end;
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

procedure GetSentDoc(BaseS: TBtrBase;
  SenderAcc, ReceiverAcc: string; var Process: Boolean;
  CheckSndData: Boolean);
const
  MesTitle: PChar = 'Проверка отправленных пакетов';
var
  Res, Len, LenP, CorrRes: Integer;                  //Изменено
  i: integer;
  KeyL: longint;
  //Добавлено Меркуловым
  KeySf: packed record
    ksIndex:  word;
    ksIder: longint;
    end;
  PayAfterTimeCount: Integer;             //Счетчик платежей, принятых после 16:05

  FatalErr, SimpleErr: Boolean;
  w: word;
  L: Byte;
  L1: Integer;
  F: file;
  SndPack: TSndPack;
  NameKey: array[0..9] of Char;
  PayRec: TPayRec;
  FileRec: TFilePieceRec;                                  //Добавлено
  LetterRec: TLetterRec;
  FN: string;
  FragmType: Byte;
  DocDataSet, EMailDataSet, LFileDataSet: TExtBtrDataSet;  //Изменено
  //Добавлено
  Number, DebitRs, DebitKs, DebitBik, DebitInn, DebitName, DebitBank,
  CreditRs, CreditKs, CreditBik, CreditInn, CreditName, CreditBank,
  Purpose, DebitKpp, CreditKpp, Status, Kbk, Okato, OsnPl, Period, NDoc,
  DocDate, TipPl, Nchpl, Shifr, Nplat, OstSum: string;
  KomisMessageEnabled: Boolean;                     //Добавлено Меркуловым

begin
  DocDataSet := GlobalBase(biPay);
  EMailDataSet := GlobalBase(biLetter);
  LFileDataSet := GlobalBase(bilfile);                     //Добавлено
  PayAfterTimeCount := 0;                                  //Добавлено
  if not GetRegParamByName('KomisMessageEnabled', CommonUserNumber, KomisMessageEnabled) then
    KomisMessageEnabled := True;

  Len := SizeOf(SndPack);
  Res := BaseS.GetFirst(SndPack, Len, NameKey, 0);
  while ((Res=0) or (Res=22)) and Process do
  begin
    FatalErr := False;
    SimpleErr := False;
    if (Res=0) and (SndPack.spByteS in [PackByteSC, PackByteSD, PackByteSE])
      and (SndPack.spWordS=PackWordS) then
    begin
      if SndPack.spFlSnd='2' then      {отправлен?}
      begin
        if CheckSndData or (SndPack.spFlRcv='1') then   {принят?}
        begin
          LenP := Len-(SizeOf(SndPack)-SizeOf(SndPack.spText));
          PackControlData.cdCheckSelf := True;
          Res := DecryptBlock(@SndPack.spText, LenP, SizeOf(SndPack.spText),
            0{smShowInfo}, @PackControlData);
          if Res>0 then   {расшифрован?}
          begin
            LenP := Res;
            i := 0;
            if SndPack.spLength<>LenP then
            begin
              ProtoMes(plError, MesTitle,
                PChar('Искомая длина Li='+IntToStr(SndPack.spLength)
                +' пакета Id='+IntToStr(SndPack.spNum)
                +' отлична от расшифрованной Lf='+IntToStr(LenP)));
              if SndPack.spLength<LenP then
                SndPack.spLength := LenP;
            end;
          end
          else begin
            i := LenP;
            ProtoMes(plError, MesTitle, PChar('Не удалось расшифровать пакет Num='
              +IntToStr(SndPack.spNum)));
            FatalErr := True;
          end;
          while (i<LenP) and not FatalErr do
          begin
            FragmType := PByte(@SndPack.spText[i])^;
            case FragmType of
              psOutDoc1, psOutDoc2, psOutDoc3:
                begin
                  KeyL := PLong(@SndPack.spText[i+1])^;
                  Len := SizeOf(PayRec);
                  Res := DocDataSet.BtrBase.GetEqual(PayRec, Len, KeyL, 0);
                  if (Res<>0) and (Res<>4) then
                  begin
                    ProtoMes(plError, MesTitle, PChar(
                      'Не удалось найти отправленный документ BtrErr='
                      +IntToStr(Res)+' Id='+IntToStr(KeyL)));
                      SimpleErr := True;
                  end
                  else
                    if Res=0 then
                    begin
                      w := dsSndSent;
                      if SndPack.spFlRcv='1' then
                      begin
                        w := dsSndRcv;
                      end;
                      if (PayRec.dbState and dsSndType)<w then
                      begin
                        PayRec.dbState := (PayRec.dbState and not dsSndType) or w;
                        if SndPack.spDateS<>0 then
                        begin
                          PayRec.dbDateS := SndPack.spDateS;
                          PayRec.dbTimeS := SndPack.spTimeS;
                        end;
                        if SndPack.spDateR<>0 then
                        begin
                          PayRec.dbDateR := SndPack.spDateR;
                          PayRec.dbTimeR := SndPack.spTimeR;
                          //Добавлено Меркуловым
                          if KomisMessageEnabled then
                            case DayOfWeek(BtrDateToDate(SndPack.spDateR)) of
                              2..5:
                                if (SndPack.spTimeR>TimeToBtrTime(StrToTime('16:10'))) and
                                  (SndPack.spTimeR<TimeToBtrTime(StrToTime('19:00'))) then
                                begin
                                  DecodeDocVar(PayRec.dbDoc, PayRec.dbDocVarLen, Number,
                                  DebitRs, DebitKs, DebitBik, DebitInn, DebitName, DebitBank,
                                  CreditRs, CreditKs, CreditBik, CreditInn, CreditName, CreditBank,
                                  Purpose, DebitKpp, CreditKpp, Status, Kbk, Okato, OsnPl, Period, NDoc,
                                  DocDate, TipPl, Nchpl, Shifr, Nplat, OstSum, 0, 0, CorrRes, False);
                                  if (PayRec.dbDoc.drDate=PayRec.dbDateR) and (Length(Status)=0)
                                    and (DebitBik<>CreditBik) then
                                    Inc(PayAfterTimeCount);
                                end;
                              6:
                                if (SndPack.spTimeR>TimeToBtrTime(StrToTime('15:10'))) and
                                  (SndPack.spTimeR<TimeToBtrTime(StrToTime('19:00'))) then
                                begin
                                  DecodeDocVar(PayRec.dbDoc, PayRec.dbDocVarLen, Number,
                                  DebitRs, DebitKs, DebitBik, DebitInn, DebitName, DebitBank,
                                  CreditRs, CreditKs, CreditBik, CreditInn, CreditName, CreditBank,
                                  Purpose, DebitKpp, CreditKpp, Status, Kbk, Okato, OsnPl, Period, NDoc,
                                  DocDate, TipPl, Nchpl, Shifr, Nplat, OstSum, 0, 0, CorrRes, False);
                                  if (PayRec.dbDoc.drDate=PayRec.dbDateR) and (Length(Status)=0) and
                                  (DebitBik<>CreditBik) then
                                    Inc(PayAfterTimeCount);
                                end;
                            end;
                          //Конец
                        end;
                        Res := DocDataSet.BtrBase.Update(PayRec, Len, KeyL, 0);
                        if Res<>0 then
                        begin
                          ProtoMes(plError, MesTitle, PChar(
                            'Не удалось обновить состояние документа '+DocInfo(PayRec)
                            +#13#10'BtrErr='+IntToStr(Res)));
                          SimpleErr := True;
                        end;
                      end
                    end;
                  case FragmType of
                    psOutDoc1:
                      Inc(i, PWord(@SndPack.spText[i+5])^+7);
                    psOutDoc2:
                      Inc(i, PWord(@SndPack.spText[i+5])^+9);
                    psOutDoc3:
                      Inc(i, PWord(@SndPack.spText[i+5])^+11);
                  end;
                end;
              psEMail1, psEMail2:
                begin
                  KeyL := PLong(@SndPack.spText[i+1])^;
                  Len := SizeOf(LetterRec);
                  Res := EMailDataSet.BtrBase.GetEqual(LetterRec, Len, KeyL, 0);
                  if (Res<>0) and (Res<>4) then
                  begin
                    ProtoMes(plError, MesTitle, PChar(
                      'Отправленное письмо не найдено BtrErr='+IntToStr(Res)
                      +' Id='+IntToStr(KeyL)));
                    SimpleErr := True;
                  end
                  else begin
                    w := dsSndSent;
                    if SndPack.spFlRcv='1' then {принят?}
                      w := dsSndRcv;
                    if (LetterRec.lrState and dsSndType)<w then
                    begin
                      LetterRec.lrState := (LetterRec.lrState and not dsSndType) or w;
                      Res := EMailDataSet.BtrBase.Update(LetterRec, Len, KeyL, 0);
                      if Res<>0 then
                      begin
                        ProtoMes(plError, MesTitle,
                          PChar('Не удалось обновить письмо BtrErr='+IntToStr(Res)));
                        SimpleErr := True;
                      end;
                    end;
                  end;
                  if FragmType=psEMail1 then
                    Inc(i, PWord(@SndPack.spText[i+5])^+7)
                  else
                    Inc(i, PWord(@SndPack.spText[i+5])^+11);
                end;
              psFile, psSFile:
                begin
                  //Добавлено Меркуловым
                  //FileRec := New(PFilePieceRec);
                  KeySf.ksIder := PInteger(@SndPack.spText[i+5])^;
                  KeySf.ksIndex := PWord(@SndPack.spText[i+3])^;
                  Len := SizeOf(FileRec);
                  if LFileDataSet=nil then
                    Res := -555
                  else
                    Res := LFileDataSet.BtrBase.GetEqual(FileRec, Len, KeySf, 0);
                  if (Res<>0) and (Res<>4) then
                  begin
                    ProtoMes(plError, MesTitle, PChar(
                      'Отправленный файл не найден BtrErr='+IntToStr(Res)
                      +' Id='+IntToStr(KeySf.ksIder)));
                    SimpleErr := True;
                  end
                  else begin
                    L := 1;
                    if SndPack.spFlRcv='1' then {принят?}
                      L := 2;
                    L1 := StrLen(@FileRec.fpVar[0]);
                    //MessageBox(ParentWnd,PChar(IntTostr(L1)),'Check!',MB_OK);          //Временно
                    if (L1>0) then
                    begin
                      Inc(L1);
                      if Byte(FileRec.fpVar[L1])<L then
                      begin
                        Byte(FileRec.fpVar[L1]) := L;
                        Res := LFileDataSet.BtrBase.Update(FileRec, Len, KeySf, 0);
                        if Res<>0 then
                        begin
                          ProtoMes(plError, MesTitle,
                            PChar('Не удалось обновить состояние файла BtrErr='+IntToStr(Res)));
                          SimpleErr := True;
                        end;
                      end;
                    end;
                  end;
                  //Dispose(FileRec);
                  Inc(i, PWord(@SndPack.spText[i+1])^+9);
                end;
              else begin
                ProtoMes(plError, MesTitle,
                  PChar('В отправленном пакете найдено сообщение неизвестного типа '
                  +IntToStr(FragmType)));
                FatalErr := True;
              end;
            end;
          end;
          if i<>LenP then
          begin
            FatalErr := True;
            ProtoMes(plError, MesTitle,
              PChar('Длина включений пакета не вяжется с общей длиной'));
          end;
          if FatalErr then
          begin
            if MessageBox(Application.Handle,
              'Убрать ошибочный пакет из почтовой базы?', MesTitle,
              MB_YESNOCANCEL or MB_ICONWARNING)=ID_YES then
            begin
              MakeRegNumber(rnBadFile, i);
              FN := PostDir+'Bad\pk'+IntToStr(i)+'.out';
              AssignFile(F, FN);
              {$I-} Rewrite(F, 1); {$I+}
              if IOResult=0 then
              begin
                BlockWrite(F, SndPack, Len);
                CloseFile(F);
                ProtoMes(plWarning, MesTitle, 'Ошибочный пакет Id='
                  +IntToStr(SndPack.spIder)+' убран в файл '+FN);
                Res := BaseS.Delete(0);
                if Res<>0 then
                  ProtoMes(plError, MesTitle, 'Не удалось убрать пакет Id='
                    +IntToStr(SndPack.spIder)+' BtrErr='+IntToStr(Res));
              end
              else
                ProtoMes(plError, MesTitle,
                  PChar('Не удалось убрать ошибочный пакет в файл '+FN));
            end;
          end
          else
            if SndPack.spFlRcv='1' then
            begin
              Res := BaseS.Delete(0);
              if Res<>0 then
                ProtoMes(plError, MesTitle, 'Не удалось убрать полученный пакет Id='
                  +IntToStr(SndPack.spIder)+' BtrErr='+IntToStr(Res));
            end;
        end;
      end
      else begin
        Res := BaseS.Delete(0);
        if Res<>0 then
          ProtoMes(plError, MesTitle, 'Не удалось убрать неотправленный пакет Id='
            +IntToStr(SndPack.spIder)+' BtrErr='+IntToStr(Res));
      end;
    end
    else begin
      Res := BaseS.Delete(0);
      ProtoMes(plError, MesTitle, 'Убран пакет с неверными контрольными байтами Id='
        +IntToStr(SndPack.spIder)+' BtrErr='+IntToStr(Res));
    end;
    Len := SizeOf(SndPack);
    Res := BaseS.GetNext(SndPack, Len, NameKey, 0);
  end;
  if PayAfterTimeCount>0 then
    MessageBox(Application.Handle, PChar('После операционного времени поступило: '
      +IntToStr(PayAfterTimeCount)+' платежа(ей)'+#10#13+'Комиссия - '+
      IntToStr(PayAfterTimeCount*75)+'-00 рублей.'), MesTitle, MB_OK);
end;

procedure ReceiveDoc(BaseR: TBtrBase; ReceiverAcc: string;
  var Process: Boolean);
const
  MesTitle: PChar = 'Обработка полученных пакетов';
var
  AccDataSet, BillDataSet, DocDataSet, BankDataSet, NpDataSet,
    EMailDataSet, FileDataSet, SFileDataSet: TExtBtrDataSet;     //Добавлено

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
        ProtoMes(plWarning, MesTitle, PChar('Не удалось удалить банк БИК='
          +IntToStr(Bik)));
    end;
    Result := Res=0;
  end;

  function AddBank(NewBank: TBankNewRec; NewNp: TNpRec): Integer;
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
    Result := 0;

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
      if Res=0 then
      begin
        Result := 1;
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
      if Res=0 then
        Result := 2;
    end;
    if Result=0 then
      ProtoMes(plWarning, MesTitle, PChar('Не удалось добавить/обновить банк '
        +IntToStr(NewBank.brCod)));
  end;

var
  Res, Len, P, LenP, Bik, K: integer;
  KeyL: longint;
  LetterRec: TLetterRec;
  AccRec: TAccRec;
  OpRec: TOpRec;
  NameS: TAbonLogin;
  NameKey:
    packed record
      rpNameS: TAbonLogin;
      kIder: Integer;
    end;
  PayRec: TPayRec;
  b: TBankNewRec;
  np: TNpRec;
  PieceKind: Byte;
  FilePieceRec: TFilePieceRec;
  FileKey: TFilePieceKey;
  F: file;
  Acc: TAccount;
  RcvPack: TRcvPack;
  FatalErr, SimpleErr: Boolean;
  FN: string;
  TextBuf: PChar;
  SignDescr: TSignDescr;
  Mode: Integer;
begin
  AccDataSet := GlobalBase(biAcc);
  BillDataSet := GlobalBase(biBill);
  DocDataSet := GlobalBase(biPay);
  BankDataSet := GlobalBase(biBank);
  NpDataSet := GlobalBase(biNp);
  FileDataSet := GlobalBase(biFile);
  {AccArcDataSet := GlobalBase(biAccArc);}
  {FileDataSet := GlobalBase(biFile);}
  EMailDataSet := GlobalBase(biLetter);
  SFileDataSet := GlobalBase(biSFile);                //Добавлено

  Len := SizeOf(RcvPack);
  Res := BaseR.GetFirst(RcvPack, Len, NameKey, 0);
  while ((Res=0) or (Res=22)) and Process do
  begin
    FatalErr := False;
    SimpleErr := False;
    P := 0;
    LenP := 0;
    if Res=0 then
    begin
      StrLCopy(NameS, RcvPack.rpNameS, 9);
      StrUpper(@NameS);
      if (RcvPack.rpByteS in [PackByteSC, PackByteSD, PackByteSE])
        and (RcvPack.rpWordS=PackWordS) then
      begin
        if (Trim(StrPas(NameS))<>ReceiverAcc) and (MessageBox(
          Application.Handle, PChar('Пришел пакет от нежданного абонента ['
          +NameS+ '] вместо ['+ReceiverAcc+']'#13#10'Будем его обрабатывать?'),
          MesTitle, MB_YESNOCANCEL or MB_ICONWARNING)<>ID_YES) then
        begin
          ProtoMes(plError, MesTitle, 'Пришел пакет от нежданного абонента ['
            +NameS+ '] вместо ['+ReceiverAcc+']');
          FatalErr := True;
        end;
        if not FatalErr then
        begin
          LenP := Len-(SizeOf(RcvPack)-SizeOf(RcvPack.rpText));
          (*if RcvPack.rpLength>0 then
          begin
            i := LenP;{RcvPack.rpLength;
            if i>=LenP then
            begin
              MessageBox(Application.Handle, PChar('Длина пакета указана слишком большой '
                +IntToStr(i)+' (всего '+IntToStr(LenP)+')'),
                MesTitle, MB_OK or ??MB_ICONERROR);
              i := LenP;
            end;}
          end
          else
            i := LenP-SignSize;*)
          PackControlData.cdCheckSelf := False;
          Res := DecryptBlock(@RcvPack.rpText, LenP, SizeOf(RcvPack.rpText),
            {smShowInfo}0, @PackControlData);
          if Res>0 then
          begin
            LenP := Res;
            P := 0;
          end
          else begin
            ProtoMes(plError, MesTitle, PChar('Ошибка дешифрации полученного пакета Id='
              +IntToStr(RcvPack.rpIder)+' Позывной='+NameS));
            FatalErr := True;
          end;
          while (P<LenP) and not FatalErr do
          begin
            PieceKind := PByte(@RcvPack.rpText[P])^;
            case PieceKind of
              psAccept:
                begin
                  KeyL := PLong(@RcvPack.rpText[P+1])^;
                  Len := SizeOf(PayRec);
                  Res := DocDataSet.BtrBase.GetEqual(PayRec, Len, KeyL, 0);
                  if Res=0 then
                  begin
                    PayRec.dbIdKorr := PLong(@RcvPack.rpText[P+5])^;
                    PayRec.dbState := (PayRec.dbState and not dsAnsType) or dsAnsRcv;
                    if (PayRec.dbDateS=0) and (RcvPack.rpDateS<>0) then
                    begin
                      PayRec.dbDateS := RcvPack.rpDateS;
                      PayRec.dbTimeS := RcvPack.rpTimeS;
                    end;
                    if RcvPack.rpDateR<>0 then
                    begin
                      PayRec.dbDateR := RcvPack.rpDateR;
                      PayRec.dbTimeR := RcvPack.rpTimeR;
                    end;
                    Res := DocDataSet.BtrBase.Update(PayRec, Len, KeyL, 0);
                    if Res<>0 then
                    begin
                      ProtoMes(plWarning, MesTitle, PChar('Документ '+DocInfo(PayRec)
                        +', на который пришла квитанция, не обновляется BtrErr='
                        +IntToStr(Res)));
                      //SimpleErr := True;
                    end;
                  end;
                  if Res<>0 then
                  begin
                    ProtoMes(plWarning, MesTitle, PChar('Документ Id='+IntToStr(KeyL)
                      +', на который пришла квитанция, не найден BtrErr='
                      +IntToStr(Res)));
                    //SimpleErr := True;
                  end;
                  Inc(P, 9);
                  IncCounter(MailForm.AcceptCountLabel, piAccepts);
                end;
              psOutDoc1, psOutDoc2, psOutDoc3:
                begin
                  case PieceKind of
                    psOutDoc1:
                      Inc(P, PWord(@RcvPack.rpText[P+5])^+7);
                    psOutDoc2:
                      Inc(P, PWord(@RcvPack.rpText[P+5])^+9);
                    psOutDoc3:
                      Inc(P, PWord(@RcvPack.rpText[P+5])^+11);
                  end;
                  ProtoMes(plWarning, MesTitle, PChar('Документ Id='
                    +IntToStr(PLong(@RcvPack.rpText[P+1])^)+' от '
                    +NameS+' игнорируется'));
                end;
              psInDoc1, psDouble1, psInDoc2, psDouble2:
                begin
                  FillChar(PayRec, SizeOf(PayRec)-SizeOf(PayRec.dbDoc), #0);
                  K := 1;
                  if PieceKind in [psDouble1, psDouble2] then
                  begin
                    PayRec.dbIdHere := PLong(@RcvPack.rpText[P+K])^;
                    Inc(K, 4);
                  end;
                  PayRec.dbIdKorr := PLong(@RcvPack.rpText[P+K])^;
                  Inc(K, 4);
                  Len := PWord(@RcvPack.rpText[P+K])^;
                  Inc(K, 2);
                  if PieceKind in [psInDoc1, psDouble1] then
                    PayRec.dbDocVarLen := Len-(SizeOf(PayRec.dbDoc)
                      -SizeOf(PayRec.dbDoc.drVar))
                  else begin
                    PayRec.dbDocVarLen := PWord(@RcvPack.rpText[P+K])^;
                    Inc(K, 2);
                  end;
                  Move(RcvPack.rpText[P+K], PayRec.dbDoc, Len);
                  Inc(P, K+Len);
                  PackControlData.cdCheckSelf := False;

                  Mode := smCheckLogin;
                  if PayRec.dbState and dsExtended<>0 then
                    Mode := Mode or smExtFormat;
                  if CheckSign(@PayRec.dbDoc, PayRec.dbDocVarLen
                    +SizeOf(PayRec.dbDoc)-SizeOf(PayRec.dbDoc.drVar),
                    SizeOf(PayRec.dbDoc), Mode, @PackControlData, @SignDescr,
                    '')<=0 {???}
                  then
                    PayRec.dbState := dsSignError;
                  if PieceKind in [psInDoc1, psInDoc2] then
                  begin
                    PayRec.dbState := PayRec.dbState or dsInputDoc;
                    MakeRegNumber(rnPaydoc, PayRec.dbIdHere);
                    if PayRec.dbIdHere>0 then
                      PayRec.dbIdIn  := PayRec.dbIdHere
                    else begin
                      ProtoMes(plError, MesTitle, PChar(
                        'Не удалось получить новый идер для вход. документа IdKorr='
                        +IntToStr(PayRec.dbIdKorr)));
                      SimpleErr := True;
                    end;
                  end
                  else begin
                    PayRec.dbState := PayRec.dbState or dsSndRcv;
                    PayRec.dbIdOut  := PayRec.dbIdHere;
                  end;
                  if not SimpleErr then
                  begin
                    PayRec.dbDateS := RcvPack.rpDateS;
                    PayRec.dbTimeS := RcvPack.rpTimeS;
                    PayRec.dbDateR := RcvPack.rpDateR;
                    PayRec.dbTimeR := RcvPack.rpTimeR;
                    Len := Len+(SizeOf(PayRec)-SizeOf(PayRec.dbDoc));
                    Res := DocDataSet.BtrBase.Insert(PayRec, Len, KeyL, 0);
                    if Res=0 then
                    begin
                      case PieceKind of
                        psInDoc1, psInDoc2:
                          IncCounter(MailForm.InDocCountLabel, piDocs);
                        psDouble1, psDouble2:
                          IncCounter(MailForm.DoubDocCountLabel, piDoubles);
                      end;
                    end
                    else begin
                      if Res=5 then
                      begin
                        ProtoMes(plWarning, MesTitle, PChar('Повтор документа '
                          +DocInfo(PayRec))+' IdKorr='+IntToStr(PayRec.dbIdKorr));
                      end
                      else begin
                        ProtoMes(plError, MesTitle, PChar('Ошибка записи документа '
                          +DocInfo(PayRec)+' BtrErr='+IntToStr(Res)
                          +' IdKorr='+IntToStr(PayRec.dbIdKorr)));
                        SimpleErr := True;
                      end;
                    end;
                  end;
                end;
              psAnsBill, psInBill, psSndBill:
                begin
                  KeyL := POpRec(@RcvPack.rpText[P+3])^.brIder;
                  Len := SizeOf(OpRec);
                  Res := BillDataSet.BtrBase.GetEqual(OpRec, Len, KeyL, 0);
                  if (Res<>0)
                    or (OpRec.brVersion<POpRec(@RcvPack.rpText[P+3])^.brVersion) then
                  begin
                    Len := PWord(@RcvPack.rpText[P+1])^;
                    Move(RcvPack.rpText[P+3], OpRec, Len);
                    if OpRec.brDel=0 then
                    begin
                      case OpRec.brPrizn of                              
                        brtReturn:
                          IncCounter(MailForm.InRetCountLabel, piRets);
                        brtKart:
                          IncCounter(MailForm.InKartCountLabel, piKarts)
                        else
                          IncCounter(MailForm.InBillCountLabel, piBills);
                      end;
                    end
                    else
                      IncCounter(MailForm.EscOpCountLabel, piDelBills);
                    TestDocDate(OpRec.brDate);
                    if Res=0 then
                      Res := BillDataSet.BtrBase.Update(OpRec, Len, KeyL, 0)
                    else
                      Res := BillDataSet.BtrBase.Insert(OpRec, Len, KeyL, 0);
                  end;
                  if Res<>0 then
                  begin
                    ProtoMes(plError, MesTitle, PChar('Ошибка записи проводки BtrErr='
                      +IntToStr(Res)));
                    SimpleErr := True;
                  end;
                  Inc(P, PWord(@RcvPack.rpText[P+1])^+3);
                end;
              psAccState:
                begin
                  KeyL := PAccRec(@RcvPack.rpText[P+3])^.arIder;
                  Len := SizeOf(AccRec);
                  Res := AccDataSet.BtrBase.GetEqual(AccRec, Len, KeyL, 0);
                  if Res<>0 then
                  begin
                    Move(RcvPack.rpText[P+3], AccRec, PWord(@RcvPack.rpText[P+1])^);
                    Len := SizeOf(AccRec);
                    Res := AccDataSet.BtrBase.Insert(AccRec, Len, KeyL, 0);
                    if Res=5 then  { если идер изменен, то надо сначала удалить }
                    begin
                      Acc := AccRec.arAccount;
                      Len := SizeOf(AccRec);
                      Res := AccDataSet.BtrBase.GetEqual(AccRec, Len, Acc, 1);
                      if Res=0 then
                      begin
                        Res := AccDataSet.BtrBase.Delete(1);
                        if Res=0 then
                        begin
                          Move(RcvPack.rpText[P+3], AccRec, PWord(@RcvPack.rpText[P+1])^);
                          Len := SizeOf(AccRec);
                          Res := AccDataSet.BtrBase.Insert(AccRec, Len, KeyL, 0);
                        end;
                      end;
                    end;
                  end
                  else
                    if AccRec.arVersion<PAccRec(@RcvPack.rpText[P+3])^.arVersion then
                    begin
                      Move(RcvPack.rpText[P+3], AccRec, PWord(@RcvPack.rpText[P+1])^);
                      Len := SizeOf(AccRec);
                      Res := AccDataSet.BtrBase.Update(AccRec, Len, KeyL, 0);
                    end;
                  if Res<>0 then
                    ProtoMes(plWarning, MesTitle, PChar('Ошибка обновления счета BtrErr='
                      +IntToStr(Res)));
                  IncCounter(MailForm.AccCountLabel, piAccStates);
                  Inc(P, PWord(@RcvPack.rpText[P+1])^+3);
                end;
              psEMail1, psEMail2:
                begin
                  FillChar(LetterRec, SizeOf(LetterRec)-SizeOf(LetterRec.lrText), #0);
                  LetterRec.lrIdKorr := PLong(@RcvPack.rpText[P+1])^;
                  MakeRegNumber(rnPaydoc, LetterRec.lrIder);
                  LetterRec.lrIdCurI := LetterRec.lrIder;
                  LetterRec.lrState := dsSndRcv or dsInputDoc;
                  Len := PWord(@RcvPack.rpText[P+5])^;
                  Res := 7;
                  if PieceKind=psEMail2 then
                  begin
                    LetterRec.lrState := LetterRec.lrState
                      or PWord(@RcvPack.rpText[P+Res])^;
                    Inc(Res, 2);
                    LetterRec.lrTextLen := PWord(@RcvPack.rpText[P+Res])^;
                    Inc(Res, 2);
                  end;
                  K := Len;
                  if (LetterRec.lrState and dsExtended)=0 then
                  begin
                    Move(RcvPack.rpText[P+Res], PEMailRec(@LetterRec)^.erText, Len);
                    Dec(K, 2);
                  end
                  else begin
                    Move(RcvPack.rpText[P+Res], LetterRec.lrText, Len);
                  end;
                  LetterTextPar(@LetterRec, TextBuf, Len);
                  if CheckSign(TextBuf, Len, erMaxVar, smCheckLogin,
                    @PackControlData, nil, '')<=0
                  then
                    LetterRec.lrState := LetterRec.lrState or dsSignError;
                  Len := SizeOf(LetterRec)-SizeOf(LetterRec.lrText) + K;
                  Res := EMailDataSet.BtrBase.Insert(LetterRec, Len, KeyL, 0);
                  if Res<>0 then
                  begin
                    if Res=5 then
                      ProtoMes(plError, MesTitle, PChar('Дубликат письма IdKorr='
                        +IntToStr(LetterRec.lrIdKorr)))
                    else
                      ProtoMes(plError, MesTitle, PChar('Не удалось записать письмо BtrErr='
                        +IntToStr(Res))+' IdKorr='+IntToStr(LetterRec.lrIdKorr));
                    SimpleErr := True;
                  end;
                  IncCounter(MailForm.InLetCountLabel, piLetters);
                  if PieceKind=psEMail1 then
                    Inc(P, PWord(@RcvPack.rpText[P+5])^+7)
                  else
                    Inc(P, PWord(@RcvPack.rpText[P+5])^+11);
                end;
              psDelBank:
                begin
                  Bik := PLong(@RcvPack.rpText[P+5])^;
                  Inc(P, 9);
                  DelBank(Bik);
                  IncCounter(MailForm.DelBankCountLabel, piDelBanks);
                end;
              psAddBank, psReplaceBank:
                begin
                  Inc(P, 5);
                  if PieceKind=psReplaceBank then
                  begin
                    Bik := PLong(@RcvPack.rpText[P])^; {Старый БИК}
                    Inc(P, 4);
                    DelBank(Bik);
                  end;
                  FillChar(b, SizeOf(b), #0);
                  FillChar(np, SizeOf(np), #0);
                  with b do
                  begin
                    brCod := PLong(@RcvPack.rpText[P])^; {Новый БИК}
                    Move(RcvPack.rpText[P+4], brKs, 20);
                    {Move(p^.rpText[i+24], brType, 4);}
                    Move(RcvPack.rpText[P+24], brName, 45);
                  end;
                  with np do
                  begin
                    Move(RcvPack.rpText[P+69], npName, 25);
                    Move(RcvPack.rpText[P+94], npType, 5);
                  end;
                  Inc(P, 99);
                  Bik := AddBank(b, np);
                  if Bik=2 then
                    IncCounter(MailForm.AddBankCountLabel, piAddBanks)
                  else
                    if Bik=1 then
                      IncCounter(MailForm.EditBankCountLabel, piEditBanks);
                end;
              psFile, psSFile:                              //Изменено
                begin
                  Len := PWord(@RcvPack.rpText[P+1])^;
                  with FilePieceRec do
                  begin
                    fpIndex := PWord(@RcvPack.rpText[P+3])^;
                    fpIdent := PInteger(@RcvPack.rpText[P+5])^;
                    Move(RcvPack.rpText[P+9], fpVar, Len);
                    with FileKey do
                    begin
                      Ident := fpIdent;
                      Index := fpIndex;
                    end;
                  end;
                  Inc(P, Len+9);

                  //Изменено
                  if (PieceKind = psFile) then
                    Res := FileDataSet.BtrBase.Insert(FilePieceRec, Len+6, FileKey, 0)
                  else
                    if (PieceKind = psSFile) then
                    begin
                      if (Length(StrPas(@FilePieceRec.fpVar[0]))>0) then
                        IncCounter(MailForm.InFileCountLabel, piFiles);
                      if SFileDataSet=nil then
                        Res := -555
                      else
                        Res := SFileDataSet.BtrBase.Insert(FilePieceRec, Len+6, FileKey, 0);
                    end;
                  if Res<>0 then
                  begin
                    ProtoMes(plError, MesTitle, PChar('Ошибка запоминания фрагмента файла BtrErr='
                      +IntToStr(Res)));
                    SimpleErr := True;
                  end;
                end;
              else begin
                ProtoMes(plError, MesTitle, PChar('Найдено сообщение неизвестного типа '
                  +IntToStr(PByte(@RcvPack.rpText[P])^)));
                FatalErr := True;
              end;
            end;
          end;
          if not SimpleErr and not FatalErr then
          begin
            Res := BaseR.Delete(0);
            if Res<>0 then
              ProtoMes(plError, MesTitle, 'Не удалось убрать обработанный пакет Id='
                +IntToStr(RcvPack.rpIder)+' BtrErr='+IntToStr(Res));
          end;
        end;
      end
      else begin
        ProtoMes(plError, MesTitle, 'Служебные байты не верны. Id='
          +IntToStr(RcvPack.rpIder)+ ' Позывной='+NameS);
        FatalErr := True;
      end;
    end
    else
      ProtoMes(plError, MesTitle, 'Не хватило буфера для чтения пакета Id='
        +IntToStr(RcvPack.rpIder));
    if FatalErr and (MessageBox(Application.Handle,
      'Серьезная ошибка в пакете. Удалить его из почтовой базы?', MesTitle,
      MB_YESNOCANCEL or MB_ICONERROR)=ID_YES) then
    begin
      MakeRegNumber(rnBadFile, K);
      FN := PostDir+'Bad\pk'+IntToStr(K)+'.inp';
      AssignFile(F, FN);
      {$I-} Rewrite(F, 1); {$I+}
      if IOResult=0 then
      begin
        BlockWrite(F, RcvPack, Len);
        CloseFile(F);
        ProtoMes(plWarning, MesTitle, 'Ошибочный пакет Id='
          +IntToStr(RcvPack.rpIder)+ ' позывной='+NameS+' убран в файл '+FN);
        Res := BaseR.Delete(0);
        if Res<>0 then
          ProtoMes(plError, MesTitle, 'Не удалось убрать ошибочный пакет Id='
            +IntToStr(RcvPack.rpIder)+' BtrErr='+IntToStr(Res));
      end
      else
        ProtoMes(plError, MesTitle, 'Не удалось создать файл '+FN+'. Id='
          +IntToStr(RcvPack.rpIder)+ ' Позывной='+NameS);
    end;
    Len := SizeOf(RcvPack);
    Res := BaseR.GetNext(RcvPack, Len, NameKey, 0);
  end;
end;

procedure GenerateFiles(var Process: Boolean);
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
  FileDataSet, ModuleDataSet: TExtBtrDataSet;
begin
  FileDataSet := GlobalBase(biFile);
  ModuleDataSet := GlobalBase(biModule);

  Len := SizeOf(FilePieceRec);
  Res := FileDataSet.BtrBase.GetFirst(FilePieceRec, Len, FileKey, 0);
  while (Res=0) and Process do
  begin
    FN := '';
    CurIndex := 1;             {проверка на последовательность}
    FileKey2 := FileKey;
    while (Res=0) and (FilePieceRec.fpIndex = CurIndex) and Process do
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
    if Process and (FilePieceRec.fpIndex = CurIndex) and (Length(FN)>0) then {последовательно и с последним куском?}
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
          IncCounter(MailForm.InFileCountLabel, piFiles);
          FileKey2 := FileKey;
          Len := SizeOf(FilePieceRec);
          Res := FileDataSet.BtrBase.GetGE(FilePieceRec, Len, FileKey2, 0); {удалим все кусочки}
          while (Res=0) and (FileKey2.Ident=FileKey.Ident) do
          begin
            Res := FileDataSet.BtrBase.Delete(0);
            if Res<>0 then
              ProtoMes(plError, MesTitle, 'Не удается удалить фрагмент файла Id='
                +IntToStr(+FileKey2.Ident)+' BtrErr='+IntToStr(Res));
            Len := SizeOf(FilePieceRec);
            FileKey2 := FileKey;
            Res := FileDataSet.BtrBase.GetGE(FilePieceRec, Len, FileKey2, 0);
          end;
          if FileType=1 then {это модуль?}
          begin
            ModuleDataSet := GlobalBase(biModule);
            if ModuleDataSet=nil then
              ProtoMes(plError, MesTitle, 'База модулей закрыта для модуля ['
                +CurFN+']')
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
                      ProtoMes(plError, MesTitle, 'Ошибка коррекции параметра при подключении ['
                        +CurFN+']');
                  end
                  else
                    ProtoMes(plError, MesTitle, 'Не удалось зарегистрировать модуль обновления ['
                      +CurFN+']');
                end
              end
              else
                ProtoMes(plError, MesTitle, 'Не удалось взять номер посл. обновления ['
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
        ProtoMes(plError, MesTitle, PChar('Не удается создать файл ['+FN+']'));
    end;
    Inc(FileKey.Ident);  {следующий идер}
    FileKey.Index := 1;
    Len := SizeOf(FilePieceRec);
    Res := FileDataSet.BtrBase.GetGE(FilePieceRec, Len, FileKey, 0);
  end;
end;

end.
