unit PackProcess;

interface

uses Btrieve, CommCons, CrySign, Windows, SysUtils, Utilits, Registr, Forms,
  Basbn, Dialogs, BtrDS, BankCnBn, Classes, BUtilits, DocFunc, {Quorum,}
  Orakle;                                                  //Добавлено Меркуловым

const
  PackControlData: TControlData = ();
var
  poInDocs, poLets, poDoubles, poAccepts, poReturns, poKarts, poBills,
    poAccs, poFiles, poBanks,
    piInRets, piInDocs, piInLets, piInFiles, piBroadcastLet: DWord;
  //poSum: Double;
  BtrDate1: Word = 0;
  BtrDate2: Word = 0;
  LastDaysDate: Word = 0;
  FirstDocDate: Word = $FFFF;
  BankBik: Integer = 45744803;
  IsUsedNewKey: Boolean;
const
  SendFileIndent: Word = 0;
  UpdDate1: Word = 0;
var
  DefPayVO, LowDate: Integer;
  MailerPort, MailerNode: Integer;

procedure GetSentDoc(BaseS: TBtrBase; SenderAcc: string;
  var Process: Boolean; CheckSndData: Boolean);
procedure SendDoc(BaseS: TBtrBase;
  SenderAcc: string; var Process: Boolean; CommPackSize: Integer;
  CommSend, FileSend, SprSend, SFileSend: Boolean; ReSendCorr: Integer; //Изменено
  FromDate, ToDate: Word; AccList: TList);
procedure ReceiveDoc(BaseR: TBtrBase; var Process: Boolean);
procedure GenerateFiles(var Process: Boolean);
//procedure SignFilePrepare;

implementation

uses
  MailFrm;

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

procedure AddPackFrag(FragType: Byte; var SndPack: TSndPack;
  Buf: PChar; BufLen: Word; {IdKorr, IdHere, Param1: Integer;} var Size: Integer);
var
  I, L: Integer;
  TxtBuf: PChar;
begin
  PByte(@SndPack.spText[Size])^ := FragType;
  I := 1;
  case FragType of
    psInDoc1, psOutDoc1, psDouble1, psInDoc2, psOutDoc2, psOutDoc3, psDouble2, psAccept:
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
            if FragType=psOutDoc3 then
            begin
              PWord(@SndPack.spText[Size+I])^ := PBankPayRec(Buf)^.dbState;
              Inc(I, 2);
            end;
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
    psFile, psSFile:                                  //Изменено
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
  case FragType of
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
    psFile, psSFile:
      IncCounter(MailForm.FilesCountLabel, poFiles);
  end;
end;

procedure ResignDoc(const AbonNode: Word; var PayRec: TBankPayRec;
  var NewLen: Integer);
const
  MesTitle: PChar = 'Переподпись документа';
var
  L: Integer;
begin
  with PackControlData do
  begin
    cdCheckSelf := False;
    cdTagNode := AbonNode;
  end;
  NewLen := SizeOf(PayRec.dbDoc)-SizeOf(PayRec.dbDoc.drVar)+PayRec.dbDocVarLen;
  L := AddSign(ceiDomenK, @PayRec.dbDoc, NewLen, SizeOf(TDocRec), smOverwrite,
    @PackControlData, '');
  if L<=0 then
    ProtoMes(plError, MesTitle, PChar('Не удалось создать подпись IdHere='
      +IntToStr(PayRec.dbIdHere)+' AbId='+IntToStr(AbonNode)));
  NewLen := NewLen + L;
end;

(*procedure ResignLetter(const AbonNode: Word; var LetterRec: TLetterRec;
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
    @PackControlData);
  if L<=0 then
  begin
    L := 0;
    ProtoMes(plError, MesTitle, PChar('Не удалось создать подпись Ider='
      +IntToStr(LetterRec.lrIder)+' AbNode='+IntToStr(AbonNode)));
  end;
  NewLen := NewLen + L;
end; *)

var
  FileBitSize: Integer = 15000;

procedure SignFilePrepare(var Process: Boolean);    //Добавлено Меркуловым
const
  MesTitle: PChar = 'Рассылка файлов';
var
  AbonIder, SrcDirLen: Integer;
  AbonDataSet, SendFileDataSet: TExtBtrDataSet;          //Добавлено

  function SendFileToCorr(Corr, MaxData, LastIder, FS: Integer;
    {var F: file;} var hFile: THandle; SrthFN,DestFN: string; SendType: Char): Boolean;
  var
    Res, Len, P, I, C, SignLen: Integer;   //Change
    W: LongWord;
    ps: TSendFileRec;
  begin
    Result := True;
    if MaxData<SizeOf(ps) - SizeOf(ps.sfData) + 10 then
      MaxData := 1000;
    with ps do
    begin
      sfBitIder := 0;
      sfFileIder := LastIder;
      sfAbonent := Corr;
      sfState := 0;
    end;
    //Seek(F, 0);
    C := 0;                                         //Change
    W := 0;                                         //Change
    P := 0;
    SignLen := 0;
    while (P<=FS) and Result do
    begin
      {showmessage('кручу! ['+SrthFN+'!!!'+DestFN
       +#13#10+IntToStr(ps.sfBitIder)
       +')');}
      Inc(ps.sfBitIder);
      if ps.sfBitIder=1 then                    //Изменено
      begin                                       //Изменено
        I := MaxData;                               //Merge
        FillChar(ps.sfData, SizeOf(ps.sfData), #0);
        //ps.sfData[0] := #0;                         //Изменено
        //MessageBox(ParentWnd, PChar(SrthFN),'check',mb_ok);   //Временно
        SignLen := AddSign(ceiDomenK, ps.sfData, {C+1}1, MaxData, smFile, nil, SrthFN);
        W := SignLen;
        C := 1;                                     //Изменено
      end                                         //Изменено
      else begin
        if P+MaxData>=FS then
        begin
          I := FS-P;
          StrPCopy(ps.sfData, DestFN);
          C := Length(DestFN)+1;
          ps.sfData[C] := #0;
        end
        else begin
          I := MaxData;
          ps.sfData[0] := #0;
          C := 0;
        end;
        Inc(C);
        if I>0 then
          Result := ReadFile(hFile, ps.sfData[C], I, W, nil)
          //BlockRead(F, ps.sfData[C], I, W)
        else
          W := 0;
        P := P+W;
        if P>=FS then
          Inc(P);
      end;
      if SignLen>0 then
      begin
        Len := SizeOf(ps) - SizeOf(ps.sfData) + C + W;
        Res := SendFileDataSet.BtrBase.Insert(ps, Len, I, 0);
        if Res<>0 then
        begin
          Result := False;
          ProtoMes(plError, MesTitle, 'Не удалось добавить фрагмент N'+
          IntToStr(ps.sfBitIder)+' Abon='+IntToStr(Corr)+' BtrErr='+IntToStr(Res));
        end;
      end
      else begin
        Result := False;
        ProtoMes(plError, MesTitle, 'Не удалось подписать файл '+DestFN);
      end;
    end;
    if Result then
      ProtoMes(plInfo, MesTitle, 'Abo='+IntToStr(Corr)+' '+IntToStr(ps.sfBitIder)+
        'x'+IntToStr(MaxData)+'b');
  end;

  function SendDir(SrcDir, DstDir: string): Boolean;
  var
    Res1, Res2, LastIder, FS: Integer;
    SearchRec: TSearchRec;
    //F: file;
    DstMask, DstMask1: string;
    //OneFileFlag: Boolean;
    hFile: THandle;
    OpS: OFSTRUCT;
  begin
    Result := False;
    //OneFileFlag := False;
    Res2 := FindFirst(SrcDir+'*.*', faAnyFile, SearchRec);
    if (Res2=0) and Process then
    begin
      Result := True;
      try
        while (Res2=0) and Result and Process do
        begin
          //showmessage('2aaa ['+SrcDir+'] | ['+DstDir+']='+SearchRec.Name+')');
          if (SearchRec.Attr and faDirectory)>0 then
          begin
            if (SearchRec.Name<>'.') and (SearchRec.Name<>'..') then
            begin
              if (Length(DstDir)>0) and not DirExists(DstDir+SearchRec.Name) then
              begin
                ProtoMes(plInfo, MesTitle, 'Создаю каталог '+DstDir+SearchRec.Name+'...');
                if not CreateDirectory(PChar(DstDir+SearchRec.Name), nil) then
                begin
                  ProtoMes(plWarning, MesTitle, 'Can''t create dir '+DstDir+SearchRec.Name);
                  Result := False;
                end;
              end;
              if Result then
              begin
                Result := SendDir(SrcDir+SearchRec.Name+'\', DstDir+SearchRec.Name+'\');
                if Result then
                  if not RemoveDirectory(PChar(SrcDir+SearchRec.Name)) then
                    ProtoMes(plWarning, MesTitle, 'Не удалось убрать '+DstDir+SearchRec.Name);
              end;
            end;
          end
          else begin
            //showmessage('гляжу! ['+SrcDir+SearchRec.Name+')');
            //AssignFile(F, SrcDir+SearchRec.Name);
            OpS.cBytes := SizeOf(OpS);
            hFile := OpenFile(PChar(SrcDir+SearchRec.Name), OpS, {OF_READ} OF_READWRITE or {OF_SHARE_EXCLUSIVE}OF_SHARE_DENY_WRITE);
            //FileMode := 2;             {!!!!! Использовать WIN API!!!}
            //{$I-} Reset(F, 1); {$I+}
            if hFile<>INVALID_HANDLE_VALUE{IOResult=0} then
            begin
              //showmessage('гляжу! ['+SrcDir+SearchRec.Name+')');
              FS := GetFileSize(hFile, nil); //FileSize(F);
              Res1 := SendFileDataSet.BtrBase.GetLastKey(LastIder, 0);
              if (Res1=0) or (Res1=9) then
              begin
                if Res1=9 then
                  LastIder := 0;
                Inc(LastIder);
                DstMask1 := SrcDir+SearchRec.Name;
                DstMask := Copy(DstMask1, SrcDirLen+1, Length(DstMask1)-SrcDirLen);
                Result := SendFileToCorr(AbonIder, FileBitSize, LastIder, FS, hFile,
                  DstMask1, DstMask, #0);
                CloseHandle(hFile);
                //CloseFile(F);
                //OneFileFlag := True;
                if Result then
                begin
                  if FileExists(PChar(DstDir+SearchRec.Name)) then
                    DeleteFile(PChar(DstDir+SearchRec.Name));
                  //DeleteFile(PChar(DstDir+SearchRec.Name+'\*.*'));  //Изменено Меркуловым
                  Result := RenameFile(PChar(SrcDir+SearchRec.Name),
                    PChar(DstDir+SearchRec.Name));
                  if not Result then
                    ProtoMes(plWarning, MesTitle, 'Не удалось перенести '+SrcDir+SearchRec.Name+'\'+DstMask+' в '
                      +DstDir+SearchRec.Name+'\'+DstMask);
                end;
              end
              else begin
                CloseHandle(hFile);
                //CloseFile(F);
                ProtoMes(plWarning, MesTitle, 'Ошибка поиска последнего номера обновления BtrErr='+IntToStr(Res1));
              end;
            end
            else
              ProtoMes(plWarning, MesTitle, 'Не удалось монопольно открыть ['+SrcDir+SearchRec.Name+'] пропущен');
          end;
          Res2 := FindNext(SearchRec);
          {if OneFileFlag then
            Res2 := 1;}
        end;
      finally
        FindClose(SearchRec);
      end;
    end;
  end;

var
  SrcFN, DestFN: string;
  T: array [0..511] of Char;
  Res, Res2, Len: Integer;     //Изменено
  AbonRec: TAbonentRec;
  SearchRec: TSearchRec;
  Key1: TAbonLogin;
  SrcDir: string;
begin
  SendFileDataSet := GlobalBase(biSendFile) as TBtrDataSet;  //Добавлено
  AbonDataSet := GlobalBase(biAbon) as TBtrDataSet;          //Добавлено
  GetRegParamByName('SignFilePrepDir', CommonUserNumber, T);
  SrcFN := T;
  GetRegParamByName('SignFileDestDir', CommonUserNumber, T);
  DestFN := T;
  if (Length(SrcFN)>0) and (Length(DestFN)>0) then
  begin
    NormalizeDir(SrcFN);
    Res2 := FindFirst(SrcFN+'*.*', faAnyFile, SearchRec);
    if Res2=0 then
      try
        while (Res2=0) and Process do
        begin
          if (SearchRec.Attr and faDirectory)>0 then
          begin
            if (SearchRec.Name<>'.') and (SearchRec.Name<>'..') then
            begin
              FillChar(Key1, SizeOf(Key1), #0);
              StrPLCopy(Key1, SearchRec.Name, SizeOf(Key1)-1);
              StrUpper(Key1);
              Len := SizeOf(AbonRec);
              Res := AbonDataSet.BtrBase.GetEqual(AbonRec, Len, Key1, 1);
              if Res=0 then
              begin
                if ((AbonRec.abLock and 1) = 0)
                  or (((AbonRec.abLock and 2) = 0)) then
                begin
                  SrcDir := SrcFN+SearchRec.Name+'\';
                  SrcDirLen := Length(SrcDir);
                  AbonIder := AbonRec.abIder;
                  NormalizeDir(DestFN);
                  CreateDir(DestFN+SearchRec.Name);
                  {if} SendDir(SrcDir, DestFN+SearchRec.Name+'\'){ then
                    RemoveDirectory(PChar(SrcFN+SearchRec.Name))};
                end
                else
                  ProtoMes(plWarning, MesTitle, 'Абонент ['+Key1+'] блокирован');
              end
              else
                ProtoMes(plWarning, MesTitle, 'Абонент ['+Key1+'] не найден BtrErr='+IntToStr(Res));
            end;
          end;
          Res2 := FindNext(SearchRec);
        end;
      finally
        FindClose(SearchRec);
      end;
  end;
end;

procedure SendDoc(BaseS: TBtrBase;
  SenderAcc: string; var Process: Boolean; CommPackSize: Integer;
  CommSend, FileSend, SprSend, SFileSend: Boolean; ReSendCorr: Integer; //Изменено Меркуловым
  FromDate, ToDate: Word; AccList: TList);
const
  MesTitle: PChar = 'Формирование пакетов';
var
  Size: Integer;
  SndPack: TSndPack;
  NameKey: array[0..9] of Char;
  AbonRec: TAbonentRec;

  procedure AddPack(CEI, Limit: Integer); {запишем пакет}
  var
    Res, Len: Integer;
  begin
    if Size>Limit then
    begin
      PackControlData.cdCheckSelf := True;
      with SndPack do
      begin
        FillChar(spNameR, SizeOf(spNameR), #0);
        Len := StrLen(AbonRec.abLogin);
        if SizeOf(spNameR)<Len then
          Len := SizeOf(spNameR);
        Move(AbonRec.abLogin, spNameR, Len);
        PackControlData.cdTagLogin := spNameR;
      end;
      Res := EncryptBlock(CEI, @SndPack.spText, Size,   {шифруем переменную часть}
        SizeOf(SndPack.spText), smShowInfo, @PackControlData);
      if Res>0 then
      begin
        with SndPack do
        begin
          FillChar(spNameS, SizeOf(spNameS), #0);
          StrPLCopy(spNameS, SenderAcc, SizeOf(spNameS));

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
        end;
        if Process then
        begin
          Len := (SizeOf(SndPack)-SizeOf(SndPack.spText))+Res;
          Res := BaseS.Insert(SndPack, Len, NameKey, 0);
          if Res<>0 then
            ProtoMes(plError, MesTitle, PChar('Не удалось добавить пакет Id='
              +IntToStr(SndPack.spNum)+' BtrErr='+IntToStr(Res)));
        end;
      end
      else
        ProtoMes(plError, MesTitle, PChar('Не удалось зашифровать пакет L='
          +IntToStr(Size)));
      Size := 0;
    end;
  end;

var
  J, Len1, Key0, Res, ResA, Len, KeyL: Integer;
  PayRec: TBankPayRec;
  LetterRec: TLetterRec;
  InfoList: TList;
  LastDate, KeyO, w: word;
  AccArcRec: TAccArcRec;
  KeyAA:
    packed record
      aaIder: longint;
      aaDate:   word;
    end;
  OpRec: TOpRec;
  KeyA: TAccount;
  AccRec: TAccRec;
  PColRec: PCollectionRec;
  Corr: longint;
  BitKey2:
    packed record
      k2BitIder:  word;
      k2FileIder: longint;
      k2Abonent:  longint;
      k2State:    word;
    end;
  SendFileRecPtr: PSendFileRec;
  psa, Key1: TSprAboRec;
  psc: TSprCorRec;
  AbonDataSet, AccDataSet, DocDataSet, LetterDataSet, SendFileDataSet,
    AccArcDataSet, BillDataSet, CorrAboDataSet, CorrSprDataSet: TExtBtrDataSet;
  LettType: Byte;
  PackSize, CEI: Integer;
begin
  SendFileDataSet := GlobalBase(biSendFile) as TBtrDataSet;  //Добавлено
  AbonDataSet := GlobalBase(biAbon) as TBtrDataSet;          //Добавлено
  {AbonDataSet := GlobalBase(biAbon);}                  //Изменено
  BillDataSet := GlobalBase(biBill);
  DocDataSet := GlobalBase(biPay);
  LetterDataSet := GlobalBase(biLetter);
  AccDataSet := GlobalBase(biAcc);
  AccArcDataSet := GlobalBase(biAccArc);
  {SendFileDataSet := GlobalBase(biSendFile);}          //Изменено
  CorrAboDataSet := GlobalBase(biCorrAbo);
  CorrSprDataSet := GlobalBase(biCorrSpr);

  PackSize := CommPackSize;
  CEI := ceiDomenK;

  Size := 0;
  if CommSend then
  begin
    InfoList := TList.Create;
    try
      { Соберем информацию по проводкам }
      LastDate := 0;
      Len := SizeOf(AccArcRec);
      Res := AccArcDataSet.BtrBase.GetLast(AccArcRec, Len, KeyAA, 0);
      if Res=0 then
        LastDate := AccArcRec.aaDate;
      KeyO := LastDate;
      Len := SizeOf(OpRec);
      Res := BillDataSet.BtrBase.GetGT(OpRec, Len, KeyO, 2);
      while ((Res=0) or (Res=22)) and Process do
      begin
        if Res=0 then
          case OpRec.brPrizn of
            brtBill:
              begin
                if ((OpRec.brState and dsSndType)=dsSndEmpty)
                  and (OpRec.brDate>UpdDate1) then
                begin
                  KeyL := OpRec.brDocId;
                  Len := SizeOf(PayRec);
                  Res := DocDataSet.BtrBase.GetEqual(PayRec, Len, KeyL, 0);
                  if (Res=0) and (PayRec.dbIdSender<>0) then
                  begin
                    PColRec := New(PCollectionRec);
                    PColRec^.crCorr := PayRec.dbIdSender;
                    PColRec^.crIder := OpRec.brIder;
                    PColRec^.crType := psSndBill;
                    InfoList.Add(PColRec);
                  end;
                end;
                if (OpRec.brState and dsAnsType)=dsAnsEmpty then
                begin
                  KeyA := OpRec.brAccD;
                  Len := SizeOf(AccRec);
                  Res := AccDataSet.BtrBase.GetEqual(AccRec, Len, KeyA, 1);
                  if (Res=0) and (AccRec.arCorr<>0) then
                  begin
                    PColRec := New(PCollectionRec);
                    PColRec^.crCorr := AccRec.arCorr;
                    PColRec^.crIder := OpRec.brIder;
                    PColRec^.crType := psAnsBill;
                    InfoList.Add(PColRec);
                  end;
                end;
                if (OpRec.brState and dsReSndType) = dsReSndEmpty then
                begin
                  KeyA := OpRec.brAccC;
                  Len := SizeOf(AccRec);
                  Res := AccDataSet.BtrBase.GetEqual(AccRec, Len, KeyA, 1);
                  if (Res=0) and (AccRec.arCorr<>0) then
                  begin
                    PColRec := New(PCollectionRec);
                    PColRec^.crCorr := AccRec.arCorr;
                    PColRec^.crIder := OpRec.brIder;
                    PColRec^.crType := psInBill;
                    InfoList.Add(PColRec);
                  end;
                end;
              end;
            brtReturn, brtKart:
              begin
                if (OpRec.brState and dsAnsType)=dsAnsEmpty then
                begin
                  KeyL := OpRec.brDocId;
                  Len := SizeOf(PayRec);
                  Res := DocDataSet.BtrBase.GetEqual(PayRec, Len, KeyL, 0);
                  if (Res=0) and (PayRec.dbIdSender<>0) then
                  begin
                    PColRec := New(PCollectionRec);
                    PColRec^.crCorr := PayRec.dbIdSender;
                    PColRec^.crIder := OpRec.brIder;
                    PColRec^.crType := psReturn;
                    InfoList.Add(PColRec);
                  end;
                end;
              end;
          end;
        Application.ProcessMessages;
        Len := SizeOf(OpRec);
        Res := BillDataSet.BtrBase.GetNext(OpRec, Len, KeyO, 2);
      end;

      { Соберем информацию по остаткам }
      Len := SizeOf(AccRec);
      Res := AccDataSet.BtrBase.GetFirst(AccRec, Len, KeyL, 0);
      while (Res=0) and Process do
      begin
        if ((AccRec.arOpts and asSndType)=asSndMark) and (AccRec.arCorr<>0) then
        begin
          PColRec := New(PCollectionRec);
          PColRec^.crCorr := AccRec.arCorr;
          PColRec^.crIder := AccRec.arIder;
          PColRec^.crType := psAccState;
          InfoList.Add(PColRec);
        end;
        Application.ProcessMessages;
        Len := SizeOf(AccRec);
        Res := AccDataSet.BtrBase.GetNext(AccRec, Len, KeyL, 0);
      end;

      { Отсортируем коллекцию  }
      InfoList.Sort(Compare);

      { Сформируем пакеты }
      Size := 0;
      Corr := 0;
      j := 0;
      ResA := -1;
      MailForm.InitProgressBar(1, 0, InfoList.Count);
      while (j<InfoList.Count) and Process do
      begin
        PColRec := InfoList.Items[j];
        if (Size>PackSize) or (Corr<>PColRec^.crCorr) and (Corr<>0) then
          AddPack(CEI, 0);
        if Corr<>PColRec^.crCorr then
        begin
          Corr := 0;
          KeyL := PColRec^.crCorr;
          Len := SizeOf(AbonRec);
          ResA := AbonDataSet.BtrBase.GetEqual(AbonRec, Len, KeyL, 0);
          if (ResA=0) and ((AbonRec.abLock and alSend) = 0)  //Изменено
            and ((AbonRec.abLock and alSExtr) = 0) and (AbonRec.abWay = awPostMach) then
          begin
            Corr := PColRec^.crCorr;
            PackSize := AbonRec.abSize;
            CEI := AbonRec.abCrypt;
          end
        end;
        if Corr<>0 then
        begin
          KeyL := PColRec^.crIder;
          case PColRec^.crType of
            psReturn:
              begin
                Len := SizeOf(OpRec);
                Res := BillDataSet.BtrBase.GetEqual(OpRec, Len, KeyL, 0);
                if Res=0 then
                begin
                  KeyL := OpRec.brDocId;
                  Len1 := SizeOf(PayRec);
                  Res := DocDataSet.BtrBase.GetEqual(PayRec, Len1, KeyL, 0);
                  if Res=0 then
                  begin
                    if (PayRec.dbState and dsSndType)=dsSndEmpty then
                    begin
                      Len1 := Len1-(SizeOf(PayRec)-SizeOf(PayRec.dbDoc));
                      AddPackFrag(psDouble2, SndPack, @PayRec, Len1, Size);
                      {PByte(@SndPack.spText[Size])^ := psDouble1;?
                      PLong(@SndPack.spText[Size+1])^ := PayRec.dbIdKorr;
                      PLong(@SndPack.spText[Size+5])^ := PayRec.dbIdHere;
                      Len1 := PayRec.dbDocVarLen+(
                        SizeOf(PayRec.dbDoc)-drMaxVar+SignSize);
                      PWord(@SndPack.spText[Size+9])^ := Len1;
                      Move(PayRec.dbDoc, SndPack.spText[Size+11], Len1);
                      Inc(Size, Len1+11);}
                    end
                    else begin
                      AddPackFrag(psAccept, SndPack, @PayRec, 0, Size);
                      {PByte(@SndPack.spText[Size])^ := psAccept; ?
                      PLong(@SndPack.spText[Size+1])^ := PayRec.dbIdKorr;
                      PLong(@SndPack.spText[Size+5])^ := PayRec.dbIdHere;
                      Inc(Size, 9);
                      IncCounter(MailForm.AcceptsCountLabel, poAccepts);}
                    end;
                    AddPackFrag(psAnsBill, SndPack, @OpRec, Len, Size);
                    {PByte(@SndPack.spText[Size])^ := psAnsBill; ?
                    PWord(@SndPack.spText[Size+1])^ := Len;
                    Move(OpRec, SndPack.spText[Size+3], Len);
                    Inc(Size, Len+3);
                    if OpRec.brPrizn=brtReturn then
                      IncCounter(MailForm.RetsCountLabel, poReturns)
                    else
                      IncCounter(MailForm.KartsCountLabel, poKarts);}
                  end;
                end;
              end;
            psAnsBill, psInBill, psSndBill:
              begin
                Len := SizeOf(OpRec);
                Res := BillDataSet.BtrBase.GetEqual(OpRec, Len, KeyL, 0);
                if Res=0 then
                begin
                  KeyL := OpRec.brDocId;
                  Len1 := SizeOf(PayRec);
                  Res := DocDataSet.BtrBase.GetEqual(PayRec, Len1, KeyL, 0);
                  if Res=0 then
                  begin
                    if (PayRec.dbIdSender=Corr) and (Corr<>0) then
                    begin
                      if (PayRec.dbState and dsSndType)=dsSndEmpty then
                      begin
                        {PByte(@SndPack.spText[Size])^ := psDouble1;?}
                        Len1 := Len1-(SizeOf(PayRec)-SizeOf(PayRec.dbDoc));
                        AddPackFrag(psDouble2, SndPack, @PayRec, Len1, Size);
                        {PLong(@SndPack.spText[Size+1])^ := PayRec.dbIdKorr;
                        PLong(@SndPack.spText[Size+5])^ := PayRec.dbIdHere;
                        Len1 := PayRec.dbDocVarLen+(SizeOf(PayRec.dbDoc)-drMaxVar+SignSize);
                        PWord(@SndPack.spText[Size+9])^ := Len1;
                        Move(PayRec.dbDoc, SndPack.spText[Size+11], Len1);
                        Inc(Size, Len1+11);
                        IncCounter(MailForm.DoublesCountLabel, poDoubles);}
                      end
                      else begin
                        AddPackFrag(psAccept, SndPack, @PayRec, 0, Size);
                        {PByte(@SndPack.spText[Size])^ := psAccept; ?
                        PLong(@SndPack.spText[Size+1])^ := PayRec.dbIdKorr;
                        PLong(@SndPack.spText[Size+5])^ := PayRec.dbIdHere;
                        Inc(Size, 9);
                        IncCounter(MailForm.DoublesCountLabel, poAccepts);}
                      end;
                    end
                    else begin
                      //MakeDocSign(d, AbonRec.abNode);
                      //Len1 := Len1-(SizeOf(PayRec)-SizeOf(PayRec.dbDoc));
                      ResignDoc(AbonRec.abNode, PayRec, Len1);
                      AddPackFrag(psInDoc2, SndPack, @PayRec, Len1, Size);
                      {PByte(@SndPack.spText[Size])^ := psInDoc1; ?
                      PLong(@SndPack.spText[Size+1])^ := PayRec.dbIdHere;
                      Len1 := PayRec.dbDocVarLen+(SizeOf(PayRec.dbDoc)-drMaxVar+SignSize);
                      PWord(@SndPack.spText[Size+5])^ := Len1;
                      Move(PayRec.dbDoc, SndPack.spText[Size+7], Len1);
                      Inc(Size, Len1+7);
                      IncCounter(MailForm.InDocsCountLabel, poInDocs);}
                    end
                  end;
                  AddPackFrag(PColRec^.crType, SndPack, @OpRec, Len, Size);
                  {PByte(@SndPack.spText[Size])^ := PColRec^.crType; ?
                  PWord(@SndPack.spText[Size+1])^ := Len;
                  Move(OpRec, SndPack.spText[Size+3], Len);
                  Inc(Size, Len+3);
                  IncCounter(MailForm.BillsCountLabel, poBills);}
                end
              end;
            psAccState:
              begin
                Len := SizeOf(AccRec);
                Res := AccDataSet.BtrBase.GetEqual(AccRec, Len, KeyL, 0);
                if Res=0 then
                begin
                  PByte(@SndPack.spText[Size])^ := PColRec^.crType;
                  PWord(@SndPack.spText[Size+1])^ := Len;
                  Move(AccRec, SndPack.spText[Size+3], Len);
                  Inc(Size, Len+3);
                  IncCounter(MailForm.AccsCountLabel, poAccs);
                end;
              end;
          end;
        end;
        if PColRec<>nil then
          Dispose(PColRec);
        Inc(j);
        MailForm.SetProgress(1, j);
        Application.ProcessMessages;
      end;
      AddPack(CEI, 0);
      MailForm.HideProgressBar(1);
    finally
      InfoList.Free;
    end;

    {запакетируем письма}
    Len := SizeOf(LetterRec);
    Res := LetterDataSet.BtrBase.GetFirst(LetterRec, Len, KeyL, 2);
    while (Res=0) and Process do
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
              and (AbonRec.abWay = awPostMach) then
            begin
              {ResignLetter(AbonRec.abNode, LetterRec, Len);}
              if (LetterRec.lrState and dsExtended)=0 then
                LettType := psEMail1
              else
                LettType := psEMail2;
              {Len := LetterTextVarLen(}
              AddPackFrag(LettType, SndPack, @LetterRec, Len, Size);
              {PByte(@SndPack.spText)^ := psEMail; ?
              PLong(@SndPack.spText[1])^ := LetterRec.erIder;
              Len :=  StrLen(LetterRec.erText)+1;
              Inc(Len, StrLen(@LetterRec.erText[Len])+(SignSize+1));
              PWord(@SndPack.spText[5])^ := Len;
              Move(LetterRec.erText, SndPack.spText[7], Len);
              Inc(Len, 7);}
              CEI := AbonRec.abCrypt;
              AddPack(CEI, 0);
              IncCounter(MailForm.LetsCountLabel, poLets);
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
            and (AbonRec.abWay = awPostMach) then
          begin
            //MakeLetterSign(e, AbonRec.crNode);
            //ResignLetter(AbonRec.abNode, LetterRec, Len);
            if (LetterRec.lrState and dsExtended)=0 then
              LettType := psEMail1
            else
              LettType := psEMail2;
            AddPackFrag(LettType, SndPack, @LetterRec, Len, Size);
            {PByte(@SndPack.spText)^ := psEMail; ?
            PLong(@SndPack.spText[1])^ := LetterRec.erIder;
            Len :=  StrLen(LetterRec.erText)+1;
            Inc(Len, StrLen(@LetterRec.erText[Len])+(SignSize+1));
            PWord(@SndPack.spText[5])^ := Len;
            Move(LetterRec.erText, SndPack.spText[7], Len);
            Inc(Len, 7);
            IncCounter(MailForm.LetsCountLabel, poLets);
            Size := Len;}
            CEI := AbonRec.abCrypt;
            AddPack(CEI, 0);
          end;
        end;
      end;
      Application.ProcessMessages;
      Len := SizeOf(LetterRec);
      Res := LetterDataSet.BtrBase.GetNext(LetterRec, Len, KeyL, 2);
    end;
  end;

  //Добавлено Меркуловым
  if SFileSend and Process then { Подпишем и запакетируем файлы в каталоге рассылки по абонентам }
    SignFilePrepare(Process);

  if (FileSend or SFileSend) and Process then
  begin
    { запакетируем кусочки файлов }
    SendFileRecPtr := New(PSendFileRec);
    Len := SizeOf(SendFileRecPtr^);
    Res := SendFileDataSet.BtrBase.GetFirst(SendFileRecPtr^, Len, BitKey2, 2);
    while (Res=0) and Process do
    begin
      if SendFileRecPtr^.sfState<>0 then
        Break;
      KeyL := SendFileRecPtr^.sfAbonent;
      Len1 := SizeOf(AbonRec);
      ResA := AbonDataSet.BtrBase.GetEqual(AbonRec, Len1, KeyL, 0);
      if (ResA=0) and ((AbonRec.abLock and alSend) = 0)
        and (AbonRec.abWay = awPostMach) then
      begin
        Dec(Len, SizeOf(SendFileRecPtr^)-SizeOf(SendFileRecPtr^.sfData));
        if FileSend then
          AddPackFrag(psFile, SndPack, PChar(SendFileRecPtr), Len, Size)
        else
          AddPackFrag(psSFile, SndPack, PChar(SendFileRecPtr), Len, Size);
        {PByte(@SndPack.spText)^ := psFile; ?
        PWord(@SndPack.spText[1])^ := Len;
        PWord(@SndPack.spText[3])^ := ps^.sfBitIder;
        PLong(@SndPack.spText[5])^ := ps^.sfFileIder;
        Move(ps^.sfData, SndPack.spText[9], Len);
        Inc(Len, 9);
        IncCounter(MailForm.FilesCountLabel, poFiles);
        Size := Len;}
        CEI := AbonRec.abCrypt;
        AddPack(CEI, 0);
      end;
      Application.ProcessMessages;
      Len := SizeOf(SendFileRecPtr^);
      Res := SendFileDataSet.BtrBase.GetNext(SendFileRecPtr^, Len, BitKey2, 2);
    end;
    Dispose(SendFileRecPtr);
    AddPack(CEI, 0);
  end;

  PackSize := CommPackSize;
  CEI := ceiDomenK;

  if SprSend and Process then
  begin
    { запакетируем обновления справочника банков }
    Corr := 0;
    Size := 0;
    FillChar(Key1, SizeOf(Key1), #0);
    Len := SizeOf(psa);
    Res := CorrAboDataSet.BtrBase.GetGE(psa, Len, Key1, 1);
    while (Res=0) and (psa.saState=0) and Process do
    begin
      if (Size>PackSize) or (Corr<>psa.saCorr) and (Corr<>0) then
        AddPack(CEI, 0);
      if Corr<>psa.saCorr then
      begin
        Corr := 0;
        Key0 := psa.saCorr;
        Len := SizeOf(AbonRec);
        ResA := AbonDataSet.BtrBase.GetEqual(AbonRec, Len, Key0, 0);
        if (ResA=0) and ((AbonRec.abLock and alSend) = 0)
          and (AbonRec.abWay = awPostMach) then
        begin
          Corr := psa.saCorr;
          PackSize := AbonRec.abSize;
          CEI := AbonRec.abCrypt;
        end
      end;
      if Corr<>0 then
      begin
        Key0 := psa.saIderR;
        Len := SizeOf(psc);
        Res := CorrSprDataSet.BtrBase.GetEqual(psc, Len, Key0, 0);
        if Res=0 then
        begin
          PByte(@SndPack.spText[Size])^ := psc.scType;
          PLong(@SndPack.spText[Size+1])^ := psc.scIderR;
          Dec(Len, SizeOf(psc)-SizeOf(psc.scData));
          Move(psc.scData, SndPack.spText[Size+5], Len);
          Inc(Size, Len+5);
          IncCounter(MailForm.BanksCountLabel, poBanks);
        end;
      end;
      Application.ProcessMessages;
      Len := SizeOf(psa);
      Res := CorrAboDataSet.BtrBase.GetNext(psa, Len, Key1, 1);
    end;
    AddPack(CEI, 0);
  end;

  if (ReSendCorr>0) and Process then
  begin { досылка баз по корреспонденту }
    Corr := ReSendCorr;
    Len := SizeOf(AbonRec);
    ResA := AbonDataSet.BtrBase.GetEqual(AbonRec, Len, Corr, 0);
    if (ResA=0) and (FromDate>0) and (ToDate>0)
      and ((AccList=nil) or (AccList.Count>0)) and Process then
    begin
      ProtoMes(plInfo, MesTitle, 'Создание досылки по абоненту: '
        +AbonRec.abLogin+' с '+BtrDateToStr(FromDate)+' по '+BtrDateToStr(ToDate));
      PackSize := AbonRec.abSize;
      CEI := AbonRec.abCrypt;
      KeyO := FromDate;
      Len := SizeOf(OpRec);
      Res := BillDataSet.BtrBase.GetGE(OpRec, Len, KeyO, 2);
      while (Res=0) and (KeyO<=ToDate) do
      begin
        if OpRec.brPrizn=brtBill then
        begin
          w := 0;
          KeyA := OpRec.brAccD;
          Len1 := SizeOf(AccRec);
          Res := AccDataSet.BtrBase.GetEqual(AccRec, Len1, KeyA, 1);
          if (Res=0) and (AccRec.arCorr=Corr)
            and DateIsActive(OpRec.brDate, AccRec.arDateO, AccRec.arDateC)
            and ((AccList=nil) or (AccList.IndexOf(Pointer(AccRec.arIder))>=0))
          then
            w := psAnsBill;
          if w=0 then
          begin
            KeyA := OpRec.brAccC;
            Len1 := SizeOf(AccRec);
            Res := AccDataSet.BtrBase.GetEqual(AccRec, Len1, KeyA, 1);
            if (Res=0) and (AccRec.arCorr=Corr)
              and DateIsActive(OpRec.brDate, AccRec.arDateO, AccRec.arDateC)
              and ((AccList=nil) or (AccList.IndexOf(Pointer(AccRec.arIder))>=0))
            then
              w := psInBill;
          end;
          if w<>0 then
          begin
            KeyL := OpRec.brDocId;
            Len1 := SizeOf(PayRec);
            Res := DocDataSet.BtrBase.GetEqual(PayRec, Len1, KeyL, 0);
            if Res=0 then
            begin
              if PayRec.dbIdSender=Corr then
              begin
                Len1 := Len1-(SizeOf(PayRec)-SizeOf(PayRec.dbDoc));
                AddPackFrag(psDouble2, SndPack, @PayRec, Len1, Size);
                {PByte(@SndPack.spText[Size])^ := psDouble1;?
                PLong(@SndPack.spText[Size+1])^ := PayRec.dbIdKorr;
                PLong(@SndPack.spText[Size+5])^ := PayRec.dbIdHere;
                Len1 := PayRec.dbDocVarLen+(SizeOf(PayRec.dbDoc)-drMaxVar+SignSize);
                PWord(@SndPack.spText[Size+9])^ := Len1;
                Move(PayRec.dbDoc, SndPack.spText[Size+11], Len1);
                Inc(Size, Len1+11);
                IncCounter(MailForm.DoublesCountLabel, poDoubles);}

                AddPackFrag(psAccept, SndPack, @PayRec, 0, Size);
                {PByte(@SndPack.spText[Size])^ := psAccept; ?
                PLong(@SndPack.spText[Size+1])^ := PayRec.dbIdKorr;
                PLong(@SndPack.spText[Size+5])^ := PayRec.dbIdHere;
                Inc(Size, 9);
                IncCounter(MailForm.AcceptsCountLabel, poAccepts);}
              end
              else begin
                {MakeDocSign(d, AbonRec.abNode);}
                //Len1 := Len1-(SizeOf(PayRec)-SizeOf(PayRec.dbDoc));
                //CloneDocWithSign(PayRec, AbonRec.abNode, PayRec2, Len1);
                ResignDoc(AbonRec.abNode, PayRec, Len1);
                AddPackFrag(psInDoc2, SndPack, @PayRec, Len1, Size);
                //AddPackFrag(psInDoc1, SndPack, @PayRec, Len1, Size);
                {PByte(@SndPack.spText[Size])^ := psInDoc1; ?
                PLong(@SndPack.spText[Size+1])^ := PayRec.dbIdHere;
                Len1 := PayRec.dbDocVarLen + (SizeOf(PayRec.dbDoc) - drMaxVar + SignSize);
                PWord(@SndPack.spText[Size+5])^ := Len1;
                Move(PayRec.dbDoc, SndPack.spText[Size+7], Len1);
                Inc(Size, Len1+7);
                IncCounter(MailForm.InDocsCountLabel, poInDocs);}
              end
            end;
            AddPackFrag(w, SndPack, @OpRec, Len, Size);
            {PByte(@SndPack.spText[Size])^ := w; ?
            PWord(@SndPack.spText[Size+1])^ := Len;
            Move(OpRec, SndPack.spText[Size+3], Len);
            Inc(Size, Len+3);
            IncCounter(MailForm.BillsCountLabel, poBills);}
            if Size>PackSize then
              AddPack(CEI, 0);
          end
        end
        else
          if ((OpRec.brPrizn=brtReturn) or (OpRec.brPrizn=brtKart)) and (AccList=nil) then
          begin
            KeyL := OpRec.brDocId;
            Len1 := SizeOf(PayRec);
            Res := DocDataSet.BtrBase.GetEqual(PayRec, Len1, KeyL, 0);
            if (Res=0) and (PayRec.dbIdSender=Corr) then
            begin
              Len1 := Len1-(SizeOf(PayRec)-SizeOf(PayRec.dbDoc));
              AddPackFrag(psDouble2, SndPack, @PayRec, Len1, Size);
              {PByte(@SndPack.spText[Size])^ := psDouble1;?
              PLong(@SndPack.spText[Size+1])^ := PayRec.dbIdKorr;
              PLong(@SndPack.spText[Size+5])^ := PayRec.dbIdHere;
              Len1 := PayRec.dbDocVarLen+(SizeOf(PayRec.dbDoc)-drMaxVar+SignSize);
              PWord(@SndPack.spText[Size+9])^ := Len1;
              Move(PayRec.dbDoc, SndPack.spText[Size+11], Len1);
              Inc(Size, Len1+11);
              IncCounter(MailForm.DoublesCountLabel, poDoubles);}

              AddPackFrag(psAccept, SndPack, @PayRec, 0, Size);
              {PByte(@SndPack.spText[Size])^ := psAccept; ?
              PLong(@SndPack.spText[Size+1])^ := PayRec.dbIdKorr;
              PLong(@SndPack.spText[Size+5])^ := PayRec.dbIdHere;
              Inc(Size, 9);
              IncCounter(MailForm.AcceptsCountLabel, poAccepts);}

              AddPackFrag(psAnsBill, SndPack, @OpRec, Len, Size);
              {PByte(@SndPack.spText[Size])^ := psAnsBill; ?
              PWord(@SndPack.spText[Size+1])^ := Len;
              Move(OpRec, SndPack.spText[Size+3], Len);
              Inc(Size, Len+3);
              IncCounter(MailForm.BillsCountLabel, poBills);}

              if Size>PackSize then
                AddPack(CEI, 0);
            end;
          end;
        Len := SizeOf(OpRec);
        Res := BillDataSet.BtrBase.GetNext(OpRec, Len, KeyO, 2);
      end;
      Application.ProcessMessages;
      AddPack(CEI, 0);
    end;
  end;
end;

(*
?begin
  Size := 0;

  {запакетируем документы}
  Len := SizeOf(PayRec);
  Res := DocDataSet.BtrBase.GetFirst(PayRec, Len, KeyL, 3);
  while ((Res=0) or (Res=22)) and Process do
  begin
    if (Res=0) and ((PayRec.dbState and dsSndType)=dsSndEmpty)
      and IsSigned(PayRec, Len) then
    begin
      Len := Len-(SizeOf(PayRec)-SizeOf(PayRec.dbDoc));
      if (Len>0) and (Len<PackSize-9) then
      begin
        PByte(@SndPack.spText[Size])^ := psOutDoc2;
        PLong(@SndPack.spText[Size+1])^ := PayRec.dbIdHere;
        PWord(@SndPack.spText[Size+5])^ := Len;
        PWord(@SndPack.spText[Size+7])^ := PayRec.dbDocVarLen;
        Move(PayRec.dbDoc, SndPack.spText[Size+9], Len);
        Inc(Size, Len+9);
        if Size>=PackSize then
        begin
          AddPack;
          Size := 0;
        end;
        poSum := poSum + PayRec.dbDoc.drSum;
        ?
        IncCounter(MailForm.DocCountLabel, poDocs);
        MailForm.TotSumLabel.Caption := SumToStr(poSum);
      end;
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
  Res := LetterDataSet.BtrBase.GetFirst(LetterRec, Len, KeyL, 2);
  while (Res=0) and Process do
  begin
    if ((LetterRec.erState and dsSndType)=dsSndEmpty) and
      LetterIsSigned(LetterRec) then
    begin
      Len := Len-(SizeOf(LetterRec)-SizeOf(LetterRec.erText));
      if (Len>0) and (Len<PackSize-7) then
      begin
        PByte(@SndPack.spText)^ := psEMail;
        PLong(@SndPack.spText[1])^ := LetterRec.erIder;
        PWord(@SndPack.spText[5])^ := Len;
        Move(LetterRec.erText, SndPack.spText[Size+7], Len);
        Inc(Size, Len+7);
        AddPack;
        Size := 0;
        IncCounter(MailForm.LetCountLabel, poLetters);
      end;
    end;
    Len := SizeOf(LetterRec);
    Res := LetterDataSet.BtrBase.GetNext(LetterRec, Len, KeyL, 2);
    Application.ProcessMessages;
  end;
end; *)

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

procedure GetSentDoc(BaseS: TBtrBase;
  SenderAcc: string; var Process: Boolean;
  CheckSndData: Boolean);
const
  MesTitle: PChar = 'Проверка отправки пакетов';
var
  SndPack: TSndPack;
  I: integer;
  AbonRec: TAbonentRec;
  SprAboRec, KeySa: TSprAboRec;
  KeySf: packed record
    ksBitIder:  word;
    ksFileIder: longint;
    ksAbonent:  longint;
  end;
  CorrAboDataSet: TExtBtrDataSet;

  procedure UpdateSprCorrState(l: word);
  var
    w: Word;
    Res, Len: Integer;
  begin
    KeySa.saIderR := PLong(@SndPack.spText[I+1])^;
    KeySa.saCorr := AbonRec.abIder;
    Len := SizeOf(SprAboRec);
    Res := CorrAboDataSet.BtrBase.GetEqual(SprAboRec, Len, KeySa, 0);
    if Res=0 then
    begin
      w := 1;
      if SndPack.spFlRcv='1' then
        w := 2;
      if SprAboRec.saState<w then
      begin
        SprAboRec.saState := w;
        Res := CorrAboDataSet.BtrBase.Update(SprAboRec, Len, KeySa, 0);
        if Res<>0 then
        begin
          //SimpleError := True;
          ProtoMes(plError, MesTitle,
            'Не удалось обновить состояние в CorrAbo Id='
              +IntToStr(SprAboRec.saIderR));
        end;
      end;
    end;
    Inc(i, l);
  end;

var
  Res, ResA, Len, LenP, KeyL, Len1, KeyId: integer;
  FatalErr: Boolean;
  w: word;
  OpRec: TOpRec;
  AccRec: TAccRec;
  ps: PSendFileRec;
  F: file;
  PayRec: TBankPayRec;
  LetterRec: TLetterRec;
  NameR: TAbonName;
  //NameKey: array[0..9] of Char;
  FN: string;
  FragmType: Byte;
  AbonDataSet, AccDataSet, DocDataSet, LetterDataSet, SendFileDataSet,
    BillDataSet: TExtBtrDataSet;
begin
  AbonDataSet := GlobalBase(biAbon);
  BillDataSet := GlobalBase(biBill);
  DocDataSet := GlobalBase(biPay);
  LetterDataSet := GlobalBase(biLetter);
  AccDataSet := GlobalBase(biAcc);
  SendFileDataSet := GlobalBase(biSendFile);
  CorrAboDataSet := GlobalBase(biCorrAbo);

  Len := SizeOf(SndPack);
  Res := BaseS.GetLast(SndPack, Len, KeyL, 2);
  if (Res=0) or (Res=22) then
  begin
    Len := SizeOf(SndPack);
    Res := BaseS.GetFirst(SndPack, Len, KeyId, 2);
    MailForm.InitProgressBar(1, KeyId, KeyL);
    while ((Res=0) or (Res=22)) and Process do
    begin
      FatalErr := False;
      if (Res=0) and (IsUsedNewKey and (SndPack.spByteS=PackByteSE) or
        not IsUsedNewKey and (SndPack.spByteS=PackByteSD))
        and (SndPack.spWordS=PackWordS) then
      begin
        LenP := Len - (SizeOf(TSndPack) - MaxPackSize);
        FillChar(NameR, SizeOf(NameR), #0);
        StrLCopy(NameR, SndPack.spNameR, 9);
        I := StrLen(NameR)-1;
        while (I>=0) and (NameR[I]=' ') do
        begin
          NameR[I] := #0;
          Dec(I);
        end;
        StrUpper(NameR);
        I := 0;
        LenP := -1;
        if SndPack.spFlSnd='2' then      {отправлен?}
        begin
          if CheckSndData or (SndPack.spFlRcv='1') then
          begin
            LenP := Len-(SizeOf(SndPack)-SizeOf(SndPack.spText));
            with PackControlData do
            begin
              cdCheckSelf := True;
              //StrPLCopy(cdTagLogin, SenderAcc, SizeOf(cdTagLogin)-1);
              cdTagNode := 0;
            end;
            Res := DecryptBlock(@SndPack.spText, LenP, SizeOf(SndPack.spText),
              smShowInfo, @PackControlData);
            if Res>0 then
            begin
              LenP := Res;
              i := 0;
              if (SndPack.spLength>0) and (SndPack.spLength<>LenP) then
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
              ProtoMes(plError, MesTitle, PChar('Ошибка шифрации в отправленном пакете Num='
                +IntToStr(SndPack.spNum)));
              FatalErr := True;
            end;
            Len1 := SizeOf(AbonRec);
            if SndPack.spByteS=PackByteSC then
              ResA := AbonDataSet.BtrBase.GetEqual(AbonRec, Len1, NameR, 2)
            else
              ResA := AbonDataSet.BtrBase.GetEqual(AbonRec, Len1, NameR, 1);
            if ResA<>0 then
            begin
              if ResA=4 then
                ProtoMes(plWarning, MesTitle,
                  'Абонент ['+NameR+'] не найден')
              else
                ProtoMes(plWarning, MesTitle,
                  'Ошибка поиска абонента ['+NameR+'] BtrErr='+IntToStr(ResA));
            end;
            if not FatalErr and Process then
            begin
              while (i>=0) and (i<LenP) and not FatalErr and Process do
              begin
                FragmType := PByte(@SndPack.spText[i])^;
                case FragmType of
                  psAccept:
                    begin
                      Inc(i,9);
                    end;
                  psInDoc1, psInDoc2:
                    begin
                      Len1 := PWord(@SndPack.spText[i+5])^;
                      if FragmType=psInDoc1 then
                        Inc(i, Len1+7)
                      else
                        Inc(i, Len1+9);
                    end;
                  psDouble1, psDouble2:
                    begin
                      KeyL := PLong(@SndPack.spText[i+5])^;
                      Len1 := SizeOf(PayRec);
                      Res := DocDataSet.BtrBase.GetEqual(PayRec, Len1, KeyL, 0);
                      if Res=0 then
                      begin
                        w := dsSndSent;
                        if SndPack.spFlRcv='1' then
                          w := dsSndRcv;
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
                          end;
                          Res := DocDataSet.BtrBase.Update(PayRec, Len1, KeyL,0);
                          if Res<>0 then
                          begin
                            //SimpleError := True;
                            ProtoMes(plWarning, MesTitle,
                              'Не удалось обновить состояние документа, BtrErr='
                              +IntToStr(Res)+' Id='+IntToStr(PayRec.dbIdHere));
                          end;
                        end;
                      end;
                      Len1 := PWord(@SndPack.spText[i+9])^;
                      if FragmType=psDouble1 then
                        Inc(i, Len1+11)
                      else
                        Inc(i, Len1+13);
                    end;
                  psAnsBill, psSndBill:
                    begin
                      KeyL := PLong(@SndPack.spText[i+3])^;
                      Len1 := SizeOf(OpRec);
                      Res := BillDataSet.BtrBase.GetEqual(OpRec, Len1, KeyL, 0);
                      if (Res=0)
                        and (OpRec.brVersion<=POpRec(@SndPack.spText[i+3])^.brVersion) then
                      begin
                        w := OpRec.brState;
                        w := w or dsSndSent;
                        w := w or dsAnsSent;
                        if SndPack.spFlRcv='1' then
                        begin
                          w := w or dsSndRcv;
                          w := w or dsAnsRcv;
                        end;
                        if OpRec.brState <> w then
                        begin
                          OpRec.brState := w;
                          Res := BillDataSet.BtrBase.Update(OpRec, Len1, KeyL, 0);
                          if Res<>0 then
                          begin
                            //SimpleError := True;
                            ProtoMes(plWarning, MesTitle,
                              'Не удалось обновить состояние выписки, BtrErr='
                              +IntToStr(Res)+' Id='+IntToStr(OpRec.brIder));
                          end;
                        end;
                      end;
                      Len1 := PWord(@SndPack.spText[i+1])^;
                      Inc(i, Len1+3);
                    end;
                  psInBill:
                    begin
                      KeyL := PLong(@SndPack.spText[i+3])^;
                      Len1 := SizeOf(OpRec);
                      Res := BillDataSet.BtrBase.GetEqual(OpRec, Len1, KeyL, 0);
                      if (Res=0)
                        and (OpRec.brVersion<=POpRec(@SndPack.spText[i+3])^.brVersion) then
                      begin
                        w := dsReSndSent;
                        if SndPack.spFlRcv='1' then
                          w := dsReSndRcv;
                        if (OpRec.brState and dsReSndType)<w then
                        begin
                          OpRec.brState := (OpRec.brState and not dsReSndType) or w;
                          Res := BillDataSet.BtrBase.Update(OpRec, Len1, KeyL, 0);
                          if Res<>0 then
                          begin
                            //SimpleError := True;
                            ProtoMes(plWarning, MesTitle,
                              'Не удалось обновить состояние выписки, BtrErr='
                              +IntToStr(Res)+' Id='+IntToStr(OpRec.brIder));
                          end;
                        end;
                      end;
                      Len1 := PWord(@SndPack.spText[i+1])^;
                      Inc(i, Len1+3);
                    end;
                  psAccState:
                    begin
                      KeyL := PLong(@SndPack.spText[i+3])^;
                      Len1 := SizeOf(AccRec);
                      Res := AccDataSet.BtrBase.GetEqual(AccRec, Len1, KeyL, 0);
                      if (Res=0)
                        and (AccRec.arVersion<=PAccRec(@SndPack.spText[i+3])^.arVersion) then
                      begin
                        w := asSndSent;
                        if SndPack.spFlRcv='1' then
                          w := asSndRcv;
                        if (AccRec.arOpts and asSndType)<w then
                        begin
                          AccRec.arOpts := (AccRec.arOpts and not asSndType) or w;
                          Res := AccDataSet.BtrBase.Update(AccRec, Len1, KeyL, 0);
                          if Res<>0 then
                          begin
                            //SimpleError := True;
                            ProtoMes(plWarning, MesTitle,
                              'Не удалось обновить состояние счета, BtrErr='
                              +IntToStr(Res)+' Id='+IntToStr(AccRec.arIder));
                          end;
                        end;
                      end;
                      Len1 := PWord(@SndPack.spText[i+1])^;
                      Inc(i, Len1+3);
                    end;
                  psEMail1, psEMail2:
                    begin
                      KeyL := PLong(@SndPack.spText[i+1])^;
                      Len1 := SizeOf(LetterRec);
                      Res := LetterDataSet.BtrBase.GetEqual(LetterRec, Len1, KeyL, 0);
                      if Res=0 then
                      begin
                        w := dsSndSent;
                        if SndPack.spFlRcv='1' then
                        begin
                          w := dsSndRcv;
                          if LetterRec.lrAdr = BroadcastNode then
                            IncCounter(MailForm.LetAccptsCountLabel, piBroadcastLet);
                        end;
                        if (LetterRec.lrState and dsSndType)<w then
                        begin
                          LetterRec.lrState := (LetterRec.lrState and not dsSndType) or w;
                          Res := LetterDataSet.BtrBase.Update(LetterRec, Len1, KeyL, 0);
                          if Res<>0 then
                          begin
                            //SimpleError := True;
                            ProtoMes(plWarning, MesTitle,
                              'Не удалось обновить состояние письма, BtrErr='
                              +IntToStr(Res)+' Id='+IntToStr(LetterRec.lrIder));
                          end;
                        end;
                      end;
                      Len1 := PWord(@SndPack.spText[i+5])^;
                      if FragmType=psEMail1 then
                        Inc(i, Len1+7)
                      else
                        Inc(i, Len1+11);
                    end;
                  psFile,psSFile:                            //Добавлено
                    begin
                      KeySf.ksBitIder := PWord(@SndPack.spText[i+3])^;
                      KeySf.ksFileIder := PLong(@SndPack.spText[i+5])^;
                      if ResA=0 then
                      begin
                        New(ps);
                        try
                          KeySf.ksAbonent := AbonRec.abIder;
                          Len1 := SizeOf(ps^);
                          Res := SendFileDataSet.BtrBase.GetEqual(ps^, Len1, KeySf, 1);
                          if Res=0 then
                          begin
                            w := 1;
                            if SndPack.spFlRcv='1' then
                              w := 2;
                            if ps^.sfState<w then
                            begin
                              ps^.sfState := w;
                              Res := SendFileDataSet.BtrBase.Update(ps^, Len1, KeySf, 1);
                              if Res<>0 then
                              begin
                                //SimpleError := True;
                                ProtoMes(plWarning, MesTitle,
                                  'Не удалось обновить состояние фрагмента файла, BtrErr='
                                  +IntToStr(Res)+' Id='+IntToStr(ps^.sfBitIder)
                                  +':'+IntToStr(ps^.sfFileIder));
                              end;
                            end;
                          end;
                        finally
                          Dispose(ps);
                        end;
                      end
                      else
                        ProtoMes(plWarning, MesTitle,
                          'Фрагмента файла '+IntToStr(KeySf.ksBitIder)+'\'
                          +IntToStr(KeySf.ksFileIder)+' т.к. абон не найден ResA='
                          +IntToStr(ResA));
                      Len1 := PWord(@SndPack.spText[i+1])^;
                      Inc(i, Len1+9);
                    end;
                  psDelBank:
                    UpdateSprCorrState(9);
                  psAddBank:
                    UpdateSprCorrState(104);
                  psReplaceBank:
                    UpdateSprCorrState(108)
                  else begin
                    ProtoMes(plError, MesTitle,
                      'Код фрагмента неизвестен '+IntToStr(FragmType)+' NameR='+NameR);
                    FatalErr := True;
                  end;
                end;
              end;
            end;
            if FatalErr then
            begin
              if MessageBox(Application.Handle,
                'Убрать ошибочный пакет из почтовой базы?', MesTitle,
                MB_YESNOCANCEL or MB_ICONWARNING)=ID_YES then
              begin
                MakeRegNumber(rnBadFile, i);
                FN := PostDir+'Bad\pk'+IntToStr(i)+'.snd';
                AssignFile(F, FN);
                {$I-} Rewrite(F, 1); {$I+}
                if IOResult=0 then
                begin
                  BlockWrite(F, SndPack, Len);
                  CloseFile(F);
                  Res := BaseS.Delete(0);
                  ProtoMes(plInfo, MesTitle, 'Ошибочный пакет Id='
                    +IntToStr(SndPack.spIder)+' убран в файл '+FN);
                end
                else
                  ProtoMes(plError, MesTitle,
                    PChar('Не удалось убрать ошибочный пакет в файл '+FN));
              end;
            end
            else
              if (SndPack.spFlRcv='1') or (ResA=4) or ((ResA=0)
                and ((AbonRec.abLock and (alSend or alRecv))=alSend or alRecv)) then
              begin
                Res := BaseS.Delete(0);
                if Res<>0 then
                  ProtoMes(plWarning, MesTitle,
                    PChar('Не удалось убрать пакет аб. ['+NameR+']'));
                if SndPack.spFlRcv<>'1' then
                begin
                  if ResA=0 then
                  begin
                    ProtoMes(plWarning, MesTitle,
                      PChar('Пакет удален т.к. абонент ['+NameR+'] блокирован'));
                  end
                  else
                    ProtoMes(plWarning, MesTitle,
                      PChar('Пакет удален т.к. абонент ['+NameR+'] не найден'));
                end;
              end;
          end;
        end
        else begin
          Res := BaseS.Delete(0);
          if Res<>0 then
            ProtoMes(plError, MesTitle,
              'Не удалось удалить неотправленный пакет, BtrErr='+IntToStr(Res)
              +' Id='+IntToStr(SndPack.spIder)+' аб. ['+NameR+']');
        end;
      end;
      MailForm.SetProgress(1, KeyId);
      Application.ProcessMessages;
      Len := SizeOf(SndPack);
      Res := BaseS.GetNext(SndPack, Len, KeyId, 2);
    end;
    MailForm.HideProgressBar(1);
  end;
end;

//Добавлено Меркуловым
var
  SendFileAbon: array [0..500] of string;

procedure ReceiveDoc(BaseR: TBtrBase;
  var Process: Boolean);
const
  MesTitle: PChar = 'Обработка полученных пакетов';
  MesTitle2: PChar = 'RcvDoc';
var
  I, Res, Res1, Len, LenP, K, Len1, Len2, Mode, SFACounter, ExcAccCounter: Integer;     //Изменено
  LetterRec: TLetterRec;
  AccRec: TAccRec;
  OpRec: TOpRec;
  //KeyBuf: array[0..255] of Char;
  PayRec: TBankPayRec;
  BankRec: TBankNewRec;
  FN: string;
  ExcAcc: string;                                            //Добавлено
  T: array[0..1023] of Char;                                 //Добавлено
  PieceKind: Byte;
  FilePieceRec: TFilePieceRec;
  FileKey: TFilePieceKey;
  F: file of Byte;
  AbonRec: TAbonentRec;
  KeyA: TAccount;
  FatalErr, SimpleErr: Boolean;
  CurrBtrDate: Word;
  RcvPack: TRcvPack;
  NameKey:
    packed record
      rpNameS: TAbonLogin;
      kIder: Integer;
    end;
  NameS: TAbonLogin;
  AbonDataSet, AccDataSet, DocDataSet, LetterDataSet, FileDataSet,
    AbonSidDataSet, BankDataSet: TExtBtrDataSet;
  AbonSignIdRec: TAbonSignIdRec;
  TextBuf: PChar;
  List1, List2, List3: string;
  SignDescr: TSignDescr;
  NeedCompl: DWord;

  //Добавлено Меркуловым
  Number, DebitRs, DebitKs, DebitBik, DebitInn, DebitName, DebitBank,
    CreditRs, CreditKs, CreditBik, CreditInn, CreditName, CreditBank,
    Purpose, DebitKpp, CreditKpp, Status, Kbk, Okato, OsnPl, Period, NDoc,
    DocDate, TipPl, Nchpl, Shifr, Nplat, OstSum: string;
  CorrRes: Integer;
  CrBik: LongInt;
begin
  AbonDataSet := GlobalBase(biAbon);
  AbonSidDataSet := GlobalBase(biAbonSid);
  AccDataSet := GlobalBase(biAcc);
  DocDataSet := GlobalBase(biPay);
  FileDataSet := GlobalBase(biFile);
  LetterDataSet := GlobalBase(biLetter);
  BankDataSet := GlobalBase(biBank);

  CurrBtrDate := DateToBtrDate(Date);

  SFACounter := 0;                                          //Добавлено
  ExcAccCounter := 1;                                       //Добавлено
  ExcAcc := ' ';                                            //Добавлено
  Len := SizeOf(RcvPack);
  Res := BaseR.GetFirst(RcvPack, Len, NameKey, 0);
  while ((Res=0) or (Res=22)) and Process do
  begin
    FatalErr := False;
    SimpleErr := False;
    if Res=0 then
    begin
      i := 0;
      LenP := 0;
      //FillChar(NameS, SizeOf(NameS), #0);
      StrLCopy(NameS, RcvPack.rpNameS, SizeOf(NameS)-1);
      StrUpper(@NameS);
      K := StrLen(NameS);
      while K<SizeOf(NameS) do
      begin
        NameS[K] := #0;
        Inc(K);
      end;
      if ((RcvPack.rpByteS=PackByteSC)
        or not IsUsedNewKey and (RcvPack.rpByteS=PackByteSD)
        or IsUsedNewKey and (RcvPack.rpByteS=PackByteSE))
        and (RcvPack.rpWordS=PackWordS) then
      begin
        K := SizeOf(AbonRec);
        if RcvPack.rpByteS=PackByteSC then
          Res := AbonDataSet.BtrBase.GetEqual(AbonRec, K, NameS, 2)
        else
          Res := AbonDataSet.BtrBase.GetEqual(AbonRec, K, NameS, 1);
        if Res=0 then
        begin
          if (AbonRec.abLock and alRecv) > 0 then
          begin
            ProtoMes(plWarning, MesTitle,
              'Получен пакет от блокированного корреспондента ['+NameS+']');
            if MessageBox(Application.Handle,
              PChar('Получен пакет от блокированного корреспондента ['+NameS+']'
              +#13#10'Пропустить обработку пакета?'),
              MesTitle, MB_ICONERROR or MB_YESNOCANCEL) = ID_YES
            then
              FatalErr := True;
          end;
          if not FatalErr then
          begin
            LenP := Len-(SizeOf(RcvPack)-SizeOf(RcvPack.rpText));
            PackControlData.cdTagNode := AbonRec.abNode;
            PackControlData.cdCheckSelf := False;
            Res := DecryptBlock(@RcvPack.rpText, LenP, SizeOf(RcvPack.rpText),
              {smShowInfo}0, @PackControlData);
            NeedCompl := 0;
            if Res>0 then
            begin
              LenP := Res;
              i := 0;
              Len2 := SizeOf(AbonSignIdRec);
              K := AbonRec.abIder;
              Res1 := AbonSidDataSet.BtrBase.GetEqual(AbonSignIdRec, Len2, K, 1);
              if Res1=0 then
              begin
                MakeAbonKeyList(K, List1, List2, List3, NeedCompl);
                List1 := List1+DividerOfList+List2+DividerOfList+List3;
              end
              else begin
                if Res1=4 then
                  List1 := NameS+DividerOfList+NameS
                else begin
                  ProtoMes(plError, MesTitle,
                    PChar('Ошибка поиска ключевых идентификаторов Id='
                    +IntToStr(RcvPack.rpIder)+' Позывной='+NameS+' AbonId='+IntToStr(K)));
                    FatalErr := True;
                end;
              end;
            end
            else begin
              ProtoMes(plError, MesTitle,
                PChar('Ошибка дешифрации полученного пакета Id='
                +IntToStr(RcvPack.rpIder)+' Позывной='+NameS));
              FatalErr := True;
            end;
          end;
        end
        else begin
          if Res=4 then
            ProtoMes(plError, MesTitle,
              'Позывной отправителя не зарегистрирован ['+NameS+'] CB='
              +IntToStr(RcvPack.rpByteS))
          else
            ProtoMes(plError, MesTitle,
              'Ошибка поиска позывной отправителя ['+NameS+'] BtrErr='
              +IntToStr(Res));
          FatalErr := True;
        end;
      end
      else begin
        ProtoMes(plError, MesTitle,
          'Получен пакет с неверной служебной информацией '#13#10
          +'ByteS=#'+IntToStr(RcvPack.rpByteS)+', WordS=#'+IntToStr(RcvPack.rpWordS));
        FatalErr := True;
      end;
      while (i>=0) and (i<LenP) and Process and not FatalErr do
      begin                                   {разберем пакет}
        PieceKind := PByte(@RcvPack.rpText[i])^;
        case PieceKind of
          psOutDoc1, psOutDoc2, psOutDoc3:
            begin
              K := 1;
              FillChar(PayRec, SizeOf(PayRec)-SizeOf(PayRec.dbDoc), #0);
              PayRec.dbIdKorr := PLong(@RcvPack.rpText[i+K])^;
              PayRec.dbState := dsSndRcv;
              Inc(K, 4);
              Len1 := PWord(@RcvPack.rpText[i+K])^;
              Inc(K, 2);
              case PieceKind of
                psOutDoc1:
                  PayRec.dbDocVarLen := Len1-SignSize;
                psOutDoc2:
                  begin
                    PayRec.dbDocVarLen := PWord(@RcvPack.rpText[i+K])^;
                    Inc(K, 2);
                  end;
                psOutDoc3:
                  begin
                    PayRec.dbDocVarLen := PWord(@RcvPack.rpText[i+K])^;
                    Inc(K, 2);
                    PayRec.dbState := PayRec.dbState
                      or (PWord(@RcvPack.rpText[i+K])^ and dsExtended);
                    Inc(K, 2);
                  end;
              end;
              Move(RcvPack.rpText[i+K], PayRec.dbDoc, Len1);
              Inc(i, K+Len1);
              PayRec.dbIdSender := AbonRec.abIder;
              PayRec.dbDateS := RcvPack.rpDateS;
              PayRec.dbTimeS := RcvPack.rpTimeS;
              PayRec.dbDateR := RcvPack.rpDateR; //DateToBtrDate(Date); {надо брать из пакета !!!}
              PayRec.dbTimeR := RcvPack.rpTimeR; //TimeToBtrTime(Time); {надо брать из пакета !!!}
              {showmessage('2: '
                +'CD='+BtrDateToStr(CurrBtrDate)+#13#10
                +BtrDateToStr(RcvPack.rpDateS)+#13#10
                +BtrTimeToStr(RcvPack.rpTimeS)+#13#10
                +BtrDateToStr(RcvPack.rpDateR)+#13#10
                +BtrTimeToStr(RcvPack.rpTimeR)+#13#10
                +'Len1='+IntToStr(Len1)+#13#10
                +'DvL='+IntToStr(PayRec.dbDocVarLen)+#13#10
                );}
              MakeRegNumber(rnPaydoc, PayRec.dbIdHere);
              PayRec.dbIdDoc  := PayRec.dbIdHere;
              with PackControlData do
              begin
                cdCheckSelf := False;
                StrLCopy(cdTagLogin, NameS, SizeOf(cdTagLogin)-1);
                cdTagNode := AbonRec.abNode;
              end;
              FN := '';  {проверим документ}
              Mode := smCheckLogin or smThoroughly;
              if Res1=0 then
              begin    {есть доб. ключи}
                if PayRec.dbState and dsExtended>0 then
                  Mode := Mode or smExtFormat
                else
                  FN := 'Одиночная подпись недопустима';
              end
              else begin
                if PayRec.dbState and dsExtended>0 then
                  Mode := Mode or smExtFormat;
              end;
              if Length(FN)=0 then
              begin
                SignDescr.siLoginNameProc := nil;
                if CheckSign(@PayRec.dbDoc,
                  SizeOf(PayRec.dbDoc)-SizeOf(PayRec.dbDoc.drVar)+PayRec.dbDocVarLen,
                  Len1, Mode, @PackControlData, @SignDescr, List1)<=0 then
                begin
                  PayRec.dbState := PayRec.dbState or dsSignError;
                  FN := 'Ошибка электронной подписи';
                end
                else begin  // подпись есть и нормальна
                  if (Mode and smExtFormat<>0)
                    and ((NeedCompl and not SignDescr.siComplete)<>0) then
                  begin   // расширенный формат подписи (мультиподпись)
                    if SignDescr.siComplete and usDirector=0 then
                      FN := 'Нет подп. рук.';
                    if SignDescr.siComplete and usAccountant=0 then
                    begin
                      if Length(FN)>0 then
                        FN := FN+';';
                      FN := FN+'Нет подп. гл.бух.';
                    end;
                    if (Res1=0) and (SignDescr.siComplete and usCourier=0) then
                    begin
                      if Length(FN)>0 then
                        FN := FN+';';
                      FN := FN+'Нет подп. исп.';
                    end;
                  end;
                  if Length(FN)=0 then
                  begin
                    FillChar(KeyA, SizeOf(KeyA), #0);
                    K := StrLen(@PayRec.dbDoc.drVar) + 1;
                    Len2 := StrLen(@PayRec.dbDoc.drVar[K]);
                    if Len2>SizeOf(KeyA) then
                      Len2 := SizeOf(KeyA);
                    Move(PayRec.dbDoc.drVar[K], KeyA, Len2);
                    Len2 := SizeOf(AccRec);
                    Res := AccDataSet.BtrBase.GetEqual(AccRec, Len2, KeyA, 1);
                    if AbonRec.abType=0 then   {клиент}
                    begin
                      if Res<>0 then
                        FN := 'Счет плательщика не зарегистрирован'
                      else begin
                        if AccRec.arCorr<>AbonRec.abIder then
                          FN := 'Счет зарегистрирован за другим корреспондентом'
                        else begin
                          if AccRec.arOpts and asLockCl <> 0 then
                            FN := 'Счет плательщика блокирован на расход'
                          else begin
                            if not DateIsActive(CurrBtrDate, AccRec.arDateO, AccRec.arDateC) then
                              FN := 'Счет плательщика неактивен в системе "Банк-клиент" на '+BtrDateToStr(CurrBtrDate)
                            else
                              if (DefPayVO=1) and (PayRec.dbDoc.drType<>1) or
                                (DefPayVO=101) and (PayRec.dbDoc.drType<>101)
                              then
                                FN := 'Недопустимый вид операции';
                          end;
                        end;
                      end;
                    end
                    else begin   {отделение}
                      if (Res<>0)
                        or (Res=0) and not DateIsActive(CurrBtrDate, AccRec.arDateO, AccRec.arDateC) then
                      begin
                        FillChar(KeyA, SizeOf(KeyA), #0);
                        K := PayRec.dbDocVarLen;
                        Len2 := 7;   {позиция CreditRs}
                        TakeZeroOffset(PayRec.dbDoc.drVar, Len2, K);
                        Len2 := StrLen(@PayRec.dbDoc.drVar[K]);
                        if Len2>SizeOf(KeyA) then
                          Len2 := SizeOf(KeyA);
                        Move(PayRec.dbDoc.drVar[K], KeyA, Len2);
                        Len2 := SizeOf(AccRec);
                        Res := AccDataSet.BtrBase.GetEqual(AccRec, Len2, KeyA, 1);
                        if (Res<>0)
                          or (Res=0) and not DateIsActive(CurrBtrDate, AccRec.arDateO, AccRec.arDateC)
                        then
                          FN := 'Счета неактивны в системе "Банк-клиент" на '+BtrDateToStr(CurrBtrDate);
                      end;
                    end;
                    //Добавлено Меркуловым
                    DecodeDocVar(PayRec.dbDoc, PayRec.dbDocVarLen, Number,
                      DebitRs, DebitKs, DebitBik, DebitInn, DebitName, DebitBank,
                      CreditRs, CreditKs, CreditBik, CreditInn, CreditName, CreditBank,
                      Purpose, DebitKpp, CreditKpp, Status, Kbk, Okato, OsnPl, Period, NDoc,
                      DocDate, TipPl, Nchpl, Shifr, Nplat, OstSum, 0, 0, CorrRes, True);
                    if OraBase.OrBaseConn then                                         //Добавлено Меркуловым
                    begin
                      if (Length(Kbk)>0) and OrKbkNotExistInQBase(Kbk) then    //Добавлено Меркуловым
                        FN := 'КБК неправильный или отсутствует в справочнике'; //Добавлено Меркуловым
                    end
                    {else                                                       //Добавлено Меркуловым
                      if (Length(Kbk)>0) and KbkNotExistInQBase(Kbk) then
                        FN := 'КБК неправильный или отсутствует в справочнике'};
                    //Добавлено
                    if OraBase.OrBaseConn then
                    begin
                      if (Length(FN)=0) and (Length(DebitKpp)>0)
                        and OrCompareKpp(DebitRS, DebitKpp) then
                      begin
                        while (ExcAcc<>DebitRS) and (ExcAcc<>'') and (ExcAccCounter<21) do
                          begin
                          if GetRegParamByName('ExcAcc'+IntToStr(ExcAccCounter), CommonUserNumber, T) then
                            ExcAcc := StrPas(@T)
                          else
                            ExcAcc := '';
                          Inc(ExcAccCounter);
                          end;
                        if (ExcAcc<>DebitRS) then
                          FN := 'КПП неверен';
                        end;
                      end
                    {else
                      if (Length(FN)=0) and (Length(DebitKpp)>0)
                        and CompareKpp(DebitRS, DebitKpp) then
                        begin
                        while (ExcAcc<>DebitRS) and (ExcAcc<>'') and (ExcAccCounter<21) do
                          begin
                          if GetRegParamByName('ExcAcc'+IntToStr(ExcAccCounter), CommonUserNumber, T) then
                            ExcAcc := StrPas(@T)
                          else
                            ExcAcc := '';
                          Inc(ExcAccCounter);
                          end;
                        if (ExcAcc<>DebitRS) then
                          FN := 'КПП неверен';
                        end};
                    //Добавлено ещё
                    if (PayRec.dbDoc.drDate<=PayRec.dbDateR)
                      and (Length(Status)=0) and (DebitBik<>CreditBik)
                      and (PayRec.dbTimeR>=BtrDate1)
                      and (PayRec.dbTimeR<=BtrDate2)
                    then
                      PayRec.dbState := PayRec.dbState or dsRsAfter;

                    //Конец

                    if Length(FN)=0 then
                      if AnalyzePayDoc(PayRec.dbDoc, PayRec.dbDocVarLen, BankBik, LowDate, '',
                        FN)=0
                      then  {корсчет не проверяется !!!}
                        FN := '';
                    if (Length(FN)=0) and (DebitBik<>CreditBik) then
                    begin
                      try
                        CrBik := StrToInt(CreditBik);
                      except
                        CrBik := 0;
                      end;
                      if CrBik>0 then
                      begin
                        if not OrBikExistInQBase(CrBik) then
                          FN := 'БИК получателя отсутствует в справочнике банков'
                      end
                      else
                        FN := 'БИК получателя ошибочен';
                      {?
                      Len2 := SizeOf(BankRec);
                      Res := BankDataSet.BtrBase.GetEqual(BankRec, Len2, CrBik, 0);
                      if Res<>0 then
                      begin
                        if Res=4 then
                          FN := 'БИК получателя отсутствует в справочнике банков'
                        else
                          ProtoMes(plError, MesTitle,
                            'Ошибка поиска БИКа получателя '+DocInfo(PayRec)
                            +' BtrErr='+IntToStr(Res));
                      end;}
                    end;
                  end;
                end;
              end;
              if (Length(FN)>0) or (PayRec.dbDoc.drDate>CurrBtrDate) then
                PayRec.dbState := PayRec.dbState or dsExport;
              Len1 := Len1+(SizeOf(PayRec)-SizeOf(PayRec.dbDoc));
              Res := DocDataSet.BtrBase.Insert(PayRec, Len1, K, 0);
              if Res=0 then
              begin
                IncCounter(MailForm.InDocCountLabel, piInDocs);
                if Length(FN)>0 then
                begin
                  FN := Copy(FN, 1, SizeOf(OpRec.brRet));
                  if MakeReturn(PayRec.dbIdHere, FN, CurrBtrDate, OpRec) then
                  begin
                    IncCounter(MailForm.InRetsCountLabel, piInRets);
                    ProtoMes(plInfo, MesTitle2,
                      'AutoRet Id='+IntToStr(PayRec.dbIdHere)+' "'+FN+'"');
                  end
                  else
                    ProtoMes(plWarning, MesTitle,
                      'Не удалось создать автовозврат на документ '+DocInfo(PayRec));
                end;
                ProtoMes(plInfo, MesTitle2, 'OutDoc Id='+IntToStr(PayRec.dbIdHere));
              end
              else begin
                if Res=5 then
                  ProtoMes(plError, MesTitle,
                    'Получен дубликат документа с ключом IdKorr='
                    +IntToStr(PayRec.dbIdKorr)+' от абонента '+NameS)
                else begin
                  SimpleErr := True;
                  ProtoMes(plError, MesTitle,
                    'Ошибка записи документа от абонента '+NameS+' BtrErr='
                    +IntToStr(Res)+' Id='+IntToStr(PayRec.dbIdHere));
                end;
              end;
            end;
          psEMail1, psEMail2:
            begin
              FillChar(LetterRec, SizeOf(LetterRec)-SizeOf(LetterRec.lrText), #0);
              LetterRec.lrIdKorr := PLong(@RcvPack.rpText[i+1])^;
              MakeRegNumber(rnPaydoc, LetterRec.lrIder);
              LetterRec.lrIdCurI := LetterRec.lrIder;
              LetterRec.lrSender := AbonRec.abIder;
              Len1 := PWord(@RcvPack.rpText[i+5])^;
              LetterRec.lrState := dsSndRcv or dsInputDoc;
              LetterRec.lrAdr := AbonRec.abIder;
              Res := 7;
              if PieceKind=psEMail2 then
              begin
                LetterRec.lrState := LetterRec.lrState
                  or PWord(@RcvPack.rpText[i+Res])^;
                Inc(Res, 2);
                LetterRec.lrTextLen := PWord(@RcvPack.rpText[i+Res])^;
                Inc(Res, 2);
              end;
              K := Len1;
              if (LetterRec.lrState and dsExtended)=0 then
              begin
                Move(RcvPack.rpText[i+Res], PEMailRec(@LetterRec)^.erText, Len1);
                Dec(K, 2);
              end
              else begin
                Move(RcvPack.rpText[i+Res], LetterRec.lrText, Len1);
              end;
              LetterTextPar(@LetterRec, TextBuf, Len1);
              with PackControlData do
              begin
                cdCheckSelf := False;
                StrLCopy(cdTagLogin, NameS, SizeOf(cdTagLogin)-1);
                cdTagNode := AbonRec.abNode;
              end;
              if CheckSign(TextBuf, Len1, erMaxVar, smCheckLogin or smThoroughly,
                @PackControlData, nil, '')<=0
              then
                LetterRec.lrState := LetterRec.lrState or dsSignError;
              Len1 := SizeOf(LetterRec)-SizeOf(LetterRec.lrText) + K;
              Res := LetterDataSet.BtrBase.Insert(LetterRec, Len1, K, 0);
              if Res=0 then
              begin
                IncCounter(MailForm.InLetsCountLabel, piInLets);
                ProtoMes(plInfo, MesTitle2, 'Письмо Id='+IntToStr(LetterRec.lrIder));
              end
              else begin
                if Res=5 then
                  ProtoMes(plWarning, MesTitle2, 'Дубликат письма игнорируется Korr='
                    +IntToStr(LetterRec.lrIdKorr))
                else begin
                  SimpleErr := True;
                  ProtoMes(plError, MesTitle,
                    'Не удалось записать письмо от абонента '+NameS+' Korr='
                    +IntToStr(LetterRec.lrIdKorr)+' BtrErr='+IntToStr(Res));
                end;
              end;
              if PieceKind=psEMail1 then
                Inc(i, PWord(@RcvPack.rpText[i+5])^+7)
              else
                Inc(i, PWord(@RcvPack.rpText[i+5])^+11);
            end;
          psFile, psSFile:                              //Изменено
            begin
              FillChar(FilePieceRec, SizeOf(FilePieceRec), #0);
              Len1 := PWord(@RcvPack.rpText[i+1])^;
              with FilePieceRec do
              begin
                fpIndex := PWord(@RcvPack.rpText[i+3])^;
                fpIdent := PInteger(@RcvPack.rpText[i+5])^;
                Move(RcvPack.rpText[i+9], fpVar, Len1);
                SendFileAbon[SFACounter] := NameS;            //Добавлено
                Inc(SFACounter);                              //Добавлено
                with FileKey do
                begin
                  Ident := fpIdent;
                  Index := fpIndex;
                end;
              end;
              Inc(i, Len1+9);
              //MessageBox(ParentWnd,PChar(inttostr(filekey.ident)+' & '+inttostr(filekey.index)),'Check',mb_ok);
              Res := FileDataSet.BtrBase.Insert(FilePieceRec, Len1+6, FileKey, 0);
              //MessageBox(ParentWnd,'Stage 1','Check',mb_ok);   //Временно
              //ProtoMes(plInfo, MesTitle2, 'OutDoc Id='+IntToStr(PayRec.dbIdHere));
              if Res=0 then
                ProtoMes(plInfo, MesTitle,
                  'Получен фрагмент файла от абонента '+NameS+' Ind='
                    +IntToStr(FilePieceRec.fpIdent)+'/'+IntToStr(FilePieceRec.fpIndex))
              else begin
                if Res=5 then
                  ProtoMes(plWarning, MesTitle,
                    'Получен дубликат фрагмента файла от абонента '+NameS+' Ind='
                    +IntToStr(FilePieceRec.fpIdent)+'/'+IntToStr(FilePieceRec.fpIndex))
                else begin
                  SimpleErr := True;                  //Изменено Меркуловым
                  ProtoMes(plError, MesTitle,
                    'Не удалось записать фрагмент файла от абонента '+NameS
                    +' BtrErr='+IntToStr(Res)+' Ind='
                    +IntToStr(FilePieceRec.fpIdent)+'/'+IntToStr(FilePieceRec.fpIndex));
                end;
              end;
            end;
          else begin
            ProtoMes(plError, MesTitle,
              'В пакете найдено включение неизвестного типа '
              +IntToStr(PByte(@RcvPack.rpText[i])^)+' от абонента '+NameS);
            FatalErr := True;
          end;
        end;
      end;
      if (i<LenP) or SimpleErr or FatalErr then
      begin   {была ошибка, сохраним пакет}
        if FatalErr or (i<LenP) then
          K := MB_ICONERROR
        else
          K := MB_ICONWARNING;
        i := 1;
        if MessageBox(Application.Handle,
          PChar('Пакет от абонента ['+NameS+'] не был полностью обработан'
          +#13#10'Убрать его из почтовой базы?'), MesTitle,
          MB_YESNOCANCEL or K)=ID_YES then
        begin
          MakeRegNumber(rnBadFile, K);
          FN := PostDir+'Bad\pk'+IntToStr(K)+'.rcv';
          AssignFile(F, FN);
          {$I-} Rewrite(F); {$I+}
          if IOResult=0 then
          begin
            BlockWrite(F, RcvPack, Len);
            CloseFile(F);
            ProtoMes(plWarning, MesTitle, 'Ошибочный пакет Id='
              +IntToStr(RcvPack.rpIder)+' от '+NameS+' сохранен в '+FN);
            i := 0;
          end
          else
            ProtoMes(plError, MesTitle,
              'Не удалось сохранить плохой пакет в файл '+FN+' Id='
              +IntToStr(RcvPack.rpIder)+' от абонента '+NameS);
        end;
      end
      else
        i := 0;
      if i=0 then
      begin     {пакет больше не нужен, удалим его}
        Res := BaseR.Delete(0);
        if Res<>0 then
          ProtoMes(plError, MesTitle,
            'Ошибка удаления обработанного пакета BtrErr='+IntToStr(Res)+' Id='
            +IntToStr(RcvPack.rpIder)+' от абонента '+NameS);
      end;
    end
    else
      ProtoMes(plError, MesTitle,
        'Не хватило буфера для пакета - запись пропущена Id='
        +IntToStr(RcvPack.rpIder));
    Application.ProcessMessages;
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
  T: array[0..1023] of Char;
  F: file;
  Len, Res, K, CurIndex, LastUpdate, SFACounter: Integer;    //Изменено
  FileType: Byte;
  ModuleRec: TModuleRec;
  FileDataSet, ModuleDataSet: TExtBtrDataSet;
begin
  SFACounter := 0;                                          //Добавлено
  FileDataSet := GlobalBase(biFile);
  Len := SizeOf(FilePieceRec);
  Res := FileDataSet.BtrBase.GetFirst(FilePieceRec, Len, FileKey, 0);
  //MessageBox(ParentWnd,'Stage 3','Check',mb_ok);   //Временно
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
      {CurFN := DecodeMask(FN, 5, CommonUserNumber)};
      GetRegParamByName('RcvFileDestDir', CommonUserNumber, T);      //Добавлено
      CurFN := T;                                                    //Добавлено
      NormalizeDir(CurFn);                                           //Добавлено
      CurFn := CurFn + SendFileAbon[SFACounter];                     //Добавлено    
      if not DirExists(CurFN) then                                   //Добавлено
        if not CreateDirectory(PChar(CurFN), nil) then               //Добавлено
          ProtoMes(plWarning, MesTitle, 'Can''t create dir '+CurFn); //Добавлено
      NormalizeDir(CurFn);                                           //Добавлено
      CurFn := CurFn+FN;                                             //Добавлено
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
          IncCounter(MailForm.InFilesCountLabel, piInFiles);
          FileKey2 := FileKey;
          Len := SizeOf(FilePieceRec);
          Res := FileDataSet.BtrBase.GetGE(FilePieceRec, Len, FileKey2, 0); {удалим все кусочки}
          while (Res=0) and (FileKey2.Ident=FileKey.Ident) do
          begin
            Res := FileDataSet.BtrBase.Delete(0);
            if Res<>0 then
              ProtoMes(plError, MesTitle, 'Не удается удалить фрагмент файла Id='
                +IntToStr(+FileKey2.Ident));
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





