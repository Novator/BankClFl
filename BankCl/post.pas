unit Post;

interface

uses
  Btrieve, Strings, Define, Views, Objects, Drivers, DocDial, Bases,
  App, DopTypes, Sign, MsgBox, StdDlg, Dos;

procedure PostDoc;
{function ManualExecution(var p: TDocInBase): boolean;}
{function ManualReturn(var p: TDocInBase): boolean;}
function CloseDate: boolean;
function ReOpenDate: boolean;
{function OpIsSent(var po: TOpRec): boolean;}
{
procedure ExportDocs(KeyNum: byte);
procedure ImportDocs;
}
procedure ExportDocsDbf(KeyNum: byte);
procedure ImportDocsDbf;
procedure StdExportDbf;
procedure StdImportDbf;

implementation

(*
function OpIsSent(var po: TOpRec): boolean;
var
  Res, Len: integer;
  w: word;
  c1, c2: longint;
  KeyA: TAccount;
  pa: TAccRec;
begin
  c1 := 0; c2 := 0; w := 0;
  KeyA := po.brAccD;
  Len := SizeOf(pa);
  Res := AccBase^.GetEQ(pa,Len,KeyA,1);
  if(Res=0) then
    c1 := pa.arCorr;
  KeyA := po.brAccC;
  Len := SizeOf(pa);
  Res := AccBase^.GetEQ(pa,Len,KeyA,1);
  if(Res=0) then
    c2 := pa.arCorr;
  if(c1<>0) then
    w := w OR (po.brState AND dsAnsRcv);
  if((c2<>0) AND (c2<>c1)) then
    w := w OR (po.brState AND dsReSndRcv);
  OpIsSent := (w<>0);
end;

function DeleteOp(var p: TOpRec): boolean;
var
  w: word;
begin
  DeleteOp := false;
  if(p.brPrizn=brtBill) then
    begin
      if(NOT CorrectOpSum(p.brAccD,p.brAccC,p.brSum,0,w)) then
        Exit;
      p.brState := w;
    end
  else if(p.brPrizn=brtReturn) then
    begin
      p.brState := 0;
    end;
  p.brDel := 1;
  Inc(p.brVersion);
  DeleteOp := true;
end;

function ManualReturn(var p: TDocInBase): boolean;
var
  Res, Len: integer;
  KeyL: longint;
  b: boolean;
  po: TOpRec;
begin
  ManualReturn := false;
  if(GetDocOp(po,p.dbIdHere,Len)) then
    begin
      b := false;
      if(po.brPrizn=brtBill) then
        begin
          if(MessageBoxRus('','Этот документ был проведен. '+
                           'Удалить проводку ?',mfOkCancel)=cmOk) then
            b := true;
        end
      else if(po.brPrizn=brtReturn) then
        begin
          if(MessageBoxRus('','Этот документ был возвращен. '+
                           'Удалить возврат ?',mfOkCancel)=cmOk) then
            b := true;
        end;
      if(b) then
        begin
          if(DeleteOp(po)) then
            begin
              Res := BillBase^.Update(po,Len,KeyL,1);
              if(Res<>0) then
                ErrorMessage(FormatLong('Ошибка модификации в Bill.btr N %d',Res))
              else
                ManualReturn := true;
            end;
        end;
    end
  else if(p.dbSender<>0) then
    begin
      FillChar(po,SizeOf(po),0);
      po.brDate := CurDateToWord;
      if(DocDateP(po,3,Len)) then
        begin
          po.brIder := GetLongIdent(spIdent);
          po.brDocId := p.dbIdHere;
          Res := BillBase^.Insert(po,Len,KeyL,0);
          if(Res<>0) then
            ErrorMessage(FormatLong('Ошибка добавления в Bill.btr N %d',Res))
          else
            ManualReturn := true;
        end;
    end
  else
    ErrorMessage('Состояние документа не допускает его возврат');
end;

function ManualExecution(var p: TDocInBase): boolean;
var
  Res, Len: integer;
  KeyL: longint;
  pp: pchar;
  l: longint;
  c, w: word;
  j: integer;
  b: boolean;
  rs, ks: string[20];
  code: string[9];
  KeyA: TAccount;
  s: string;
  pa: TAccRec;
  po: TOpRec;
begin
  ManualExecution := false;
  if(GetDocOp(po,p.dbIdHere,Len)) then
    begin
      ErrorMessage('Состояние документа не допускает его проводку');
      Exit;
    end;
  w := $5F;
  FillChar(po,SizeOf(po),0);
  po.brDocId := p.dbIdHere;
  s := StrLPas(p.dbDoc.drVar,255);
  Val(s,po.brNumber,Len);
  po.brNumber := po.brNumber mod 1000;
  po.brDate := CurDateToWord;
  po.brSum := p.dbDoc.drSum;
  po.brType := p.dbDoc.drType;

  j := 0;
  Inc(j,StrLen(@p.dbDoc.drVar[j])+1);
  rs := StrLPas(@p.dbDoc.drVar[j],20);
  Inc(j,StrLen(@p.dbDoc.drVar[j])+1);
  ks := StrLPas(@p.dbDoc.drVar[j],20);
  Inc(j,StrLen(@p.dbDoc.drVar[j])+1);
  code := StrLPas(@p.dbDoc.drVar[j],9);
  Inc(j,StrLen(@p.dbDoc.drVar[j])+1);
  b := true;
  s := FormatString('%020s',ks);
  if(StrLComp(@s[1],BankAcc,SizeOf(BankAcc))<>0) then
    b := false;
  Val(code,l,c);
  if((c<>0) OR (l<>BankCode)) then
    b := false;
  FillChar(KeyA,SizeOf(KeyA),0);
  Move(rs[1],KeyA,Length(rs));
  if(b) then
    begin
      po.brAccD := KeyA;
      w := w AND NOT $8;
    end;

  Inc(j,StrLen(@p.dbDoc.drVar[j])+1);
  Inc(j,StrLen(@p.dbDoc.drVar[j])+1);
  Inc(j,StrLen(@p.dbDoc.drVar[j])+1);
  rs := StrLPas(@p.dbDoc.drVar[j],20);
  Inc(j,StrLen(@p.dbDoc.drVar[j])+1);
  ks := StrLPas(@p.dbDoc.drVar[j],20);
  Inc(j,StrLen(@p.dbDoc.drVar[j])+1);
  code := StrLPas(@p.dbDoc.drVar[j],9);
  Inc(j,StrLen(@p.dbDoc.drVar[j])+1);
  b := true;
  s := FormatString('%020s',ks);
  if(StrLComp(@s[1],BankAcc,SizeOf(BankAcc))<>0) then
    b := false;
  Val(code,l,c);
  if((c<>0) OR (l<>BankCode)) then
    b := false;
  FillChar(KeyA,SizeOf(KeyA),0);
  Move(rs[1],KeyA,Length(rs));
  if(b) then
    begin
      po.brAccC := KeyA;
      w := w AND NOT $10;
    end;

  Inc(j,StrLen(@p.dbDoc.drVar[j])+1);
  Inc(j,StrLen(@p.dbDoc.drVar[j])+1);
  Inc(j,StrLen(@p.dbDoc.drVar[j])+1);
  pp := @p.dbDoc.drVar[j];
  s := Copy(FirstLine(pp),1,30);
  FillChar(po.brText,SizeOf(po.brText),0);
  Move(s[1],po.brText,Length(s));
  if(OpDialog(po,w,Len)) then
    begin
      if(CorrectOpSum(po.brAccD,po.brAccC,0,po.brSum,w)) then
        begin
          po.brIder := GetLongIdent(spIdent);
          po.brState := w;
          Inc(po.brVersion);
          Res := BillBase^.Insert(po,Len,KeyL,0);
          if(Res<>0) then
            ErrorMessage(FormatLong('Ошибка добавления в Bill.btr N %d '+
                                    'Исправьте остатки на затронутых счетах',Res))
          else
            ManualExecution := true;
        end;
    end;
end;
*)
const
  MailCmd: string[11] = '..\focus\fm.bat';

var
  poSum: comp;
  poDocs, poLetters: word;
  piDocs, piLetters, piRets, piBills: word;

procedure GetSentDoc(OutB: PBtrBase; p: PSndPack);
var
  Res, Len, LenP: integer;
  i: integer;
  KeyBuf: array[0..255] of char;
  KeyL: longint;
  ErrorsInPacket: boolean;
  pe: PEMailRec;
  pd: PDocInBase absolute pe;
  w: word;
begin
  New(pe);
  Len := SizeOf(p^);
  Res := OutB^.GetFirst(p^,Len,KeyBuf,0);
  while((Res=0) OR (Res=22)) do
    begin
      if((Res=0) AND (p^.spByteS=PackByteS)
                 AND (p^.spWordS=PackWordS)) then
        begin
          if(p^.spFlSnd<>'2') then      {не отправлен?}
            Res := OutB^.Delete(Len,0)
          else
            begin
              i := 0;
              LenP := Len-(SizeOf(TSndPack)-MaxPackSize);
              ErrorsInPacket := false;
              while(i<LenP) do
                begin
                  case PByte(@p^.spText[i])^ of
                    psOutDoc:
                      begin
                        KeyL := PLong(@p^.spText[i+1])^;
                        Len := SizeOf(pd^);
                        Res := DocBase^.GetEQ(pd^,Len,KeyL,0);
                        if((Res<>0) AND (Res<>4)) then
                          begin
                            ErrorMessage(FormatLong('Ошибка поиска N %d',Res)+
                              FormatLong(' по ключу 0 в doc.btr для %d',KeyL));
                            ErrorsInPacket := true;
                          end
                        else if(Res=0) then
                          begin
                            w := dsSndSent;
                            if(p^.spFlRcv='1') then
                              w := dsSndRcv;
                            if((pd^.dbState AND dsSndType)<w) then
                              begin
                                pd^.dbState := (pd^.dbState AND NOT dsSndType) OR w;
                                Res := DocBase^.Update(pd^,Len,KeyL,0);
                                if(Res<>0) then
                                  ErrorsInPacket := true;
                              end
                          end;
                        Inc(i,PWord(@p^.spText[i+5])^+7);
                      end;
                    psEMail:
                      begin
                        KeyL := PLong(@p^.spText[i+1])^;
                        Len := SizeOf(pe^);
                        Res := EMailBase^.GetEQ(pe^,Len,KeyL,0);
                        if((Res<>0) And (Res<>4)) then
                          begin
                            ErrorMessage(FormatLong('Ошибка поиска N %d',Res)+
                              FormatLong(' по ключу 0 в email.btr для %d',KeyL));
                            ErrorsInPacket := true;
                          end
                        else
                          begin
                            w := dsSndSent;
                            if(p^.spFlRcv='1') then {принят?}
                              w := dsSndRcv;
                            if((pe^.erState AND dsSndType)<w) then
                              begin
                                pe^.erState := (pe^.erState AND NOT dsSndType) OR w;
                                Res := EMailBase^.Update(pe^,Len,KeyL,0);
                                if(Res<>0) then
                                  ErrorsInPacket := true;
                              end;
                          end;
                        Inc(i,PWord(@p^.spText[i+5])^+7);
                      end;
                    else
                      begin
                        ErrorMessage(FormatLong('В пакете на отправку найдено сообщение тип %d',
                                                PByte(@p^.spText[i])^));
                        ErrorsInPacket := true;
                        break;
                      end;
                  end;
                end;
              if(i<>LenP) then
                ErrorsInPacket := true;
              if(NOT ErrorsInPacket AND (p^.spFlRcv='1')) then
                Res := OutB^.Delete(Len,0);
            end;
        end;
      Len := SizeOf(p^);
      Res := OutB^.GetNext(p^,Len,KeyBuf,0);
    end;
  Dispose(pe);
end;

procedure SendDoc(OutB: PBtrBase; p: PSndPack);
var
  Res, Len: integer;
  i: integer;
  KeyBuf: array[0..255] of char;
  KeyL: longint;
  pd: PDocInBase;
  w: word;
begin
  New(pd);
  i := 0;
  Len := SizeOf(pd^);
  Res := DocBase^.GetFirst(pd^,Len,KeyL,3);
  while((Res=0) OR (Res=22)) do
    begin
      if((Res=0) AND ((pd^.dbState AND dsSndType)=dsSndEmpty) AND IsSigned(pd^)) then
        begin
          PByte(@p^.spText[i])^ := psOutDoc;
          PLong(@p^.spText[i+1])^ := pd^.dbIdHere;
          Len := pd^.dbDocLen+(SizeOf(TDocRec)-drMaxVar+SignSize);
          PWord(@p^.spText[i+5])^ := Len;
          Move(pd^.dbDoc,p^.spText[i+7],Len);
          Inc(i,Len+7);
          if(i>=PackSize) then
            begin
              FillChar(p^.spNameR,SizeOf(p^.spNameR),' ');
              Move(CenterAcc[1],p^.spNameR,Length(CenterAcc));
              p^.spByteS := PackByteS;
              p^.spWordS := PackWordS;
              p^.spLength := 0;
              p^.spNum   := GetLongIdent(spIdent);
              p^.spFlSnd := '0';
              p^.spFlRcv := '0';
              Len := (SizeOf(TSndPack)-MaxPackSize)+i;
              Res := OutB^.Insert(p^,Len,KeyBuf,0);
              i := 0;
            end;
          Inc(poDocs);
          poSum := poSum+pd^.dbDoc.drSum;
        end;
      Len := SizeOf(pd^);
      Res := DocBase^.GetNext(pd^,Len,KeyL,3);
    end;
  if(i>0) then
    begin
      FillChar(p^.spNameR,SizeOf(p^.spNameR),' ');
      Move(CenterAcc[1],p^.spNameR,Length(CenterAcc));
      p^.spByteS := PackByteS;
      p^.spWordS := PackWordS;
      p^.spLength := 0;
      p^.spNum   := GetLongIdent(spIdent);
      p^.spFlSnd := '0';
      p^.spFlRcv := '0';
      Len := (SizeOf(TSndPack)-MaxPackSize)+i;
      Res := OutB^.Insert(p^,Len,KeyBuf,0);
    end;
  Dispose(pd);
end;

procedure SendEMail(OutB: PBtrBase; p: PSndPack);
var
  Res, Len, Len1: integer;
  i, j: integer;
  KeyL: longint;
  pe: PEmailRec;
  w: word;
  Corr: longint;
  pcr: TCorrRec;
  KeyBuf: array[0..255] of char;
begin
  pe := New(PEmailRec);
  Len := SizeOf(pe^);
  Res := EMailBase^.GetFirst(pe^,Len,KeyL,2);
  while(Res=0) do
    begin
      if(((pe^.erState AND dsSndType)=dsSndEmpty) AND EMailIsSigned(pe^)) then
        begin
          EMailMakeSign(pe^,CenterNode);
          PByte(@p^.spText)^ := psEMail;
          PLong(@p^.spText[1])^ := pe^.erIder;
          Len :=  StrLen(pe^.erText)+1;
          Inc(Len,StrLen(@pe^.erText[Len])+(SignSize+1));
          PWord(@p^.spText[5])^ := Len;
          Move(pe^.erText,p^.spText[7],Len);
          FillChar(p^.spNameR,SizeOf(p^.spNameR),' ');
          Move(CenterAcc[1],p^.spNameR,Min(SizeOf(p^.spNameR),Length(CenterAcc)));
          p^.spByteS := PackByteS;
          p^.spWordS := PackWordS;
          p^.spLength := 0;
          p^.spNum   := GetLongIdent(spIdent);
          p^.spFlSnd := '0';
          p^.spFlRcv := '0';
          Len := Len+(SizeOf(TSndPack)-MaxPackSize+7);
          Res := OutB^.Insert(p^,Len,KeyBuf,0);
          Inc(poLetters);
        end;
      Len := SizeOf(pe^);
      Res := EMailBase^.GetNext(pe^,Len,KeyL,2);
    end;
  Dispose(pe);
end;
(*
procedure MakeReturn(var pd: TDocInBase; s: string);
var
  Res, Len: integer;
  KeyL: longint;
  po: TOpRec;
begin
  FillChar(po,SizeOf(po),0);
  po.brIder := GetLongIdent(spIdent);
  po.brDocId := pd.dbIdHere;
  po.brDate := CurDateToWord;
  po.brPrizn := brtReturn;
  Move(s[1],po.brRet,Length(s));
  Len := 17+brMaxRet;
  Res := BillBase^.Insert(po,Len,KeyL,0);
  if(Res<>0) then
    ErrorMessage(FormatLong('Ошибка добавления в Bill.btr N %d',Res));
end;
*)
procedure ReceiveDoc(InB: PBtrBase; p: PRcvPack);
var
  Res, Len, LenP: integer;
  i: integer;
  KeyL: longint;
  pe: PEMailRec;
  w: word;
  s: array[0..8] of char;
  pa: TAccRec;
  po: TOpRec;
  KeyBuf: array[0..255] of char;
  pd: TDocInBase;
begin
  Len := SizeOf(p^);
  Res := InB^.GetFirst(p^,Len,KeyBuf,0);
  while((Res=0) OR (Res=22)) do
    begin
      StrUpper(StrLCopy(s,p^.rpNameS,9));
      if((Res=0) AND (p^.rpByteS=PackByteS) AND
         (p^.rpWordS=PackWordS) AND
         (Trim(StrLPas(s,9))=CenterAcc)) then
        begin
          LenP := Len-(SizeOf(p^)-MaxPackSize);
          i := 0;
          while(i<LenP) do
            begin
              case PByte(@p^.rpText[i])^ of
                psAccept:
                  begin
                    KeyL := PLong(@p^.rpText[i+1])^;
                    Len := SizeOf(pd);
                    Res := DocBase^.GetEQ(pd,Len,KeyL,0);
                    if(Res=0) then
                      begin
                        pd.dbIdKorr := PLong(@p^.rpText[i+5])^;
                        pd.dbState := (pd.dbState AND NOT dsAnsType) OR dsAnsRcv;
                        Res := DocBase^.Update(pd,Len,KeyL,0);
                      end;
                    if(Res<>0) then
                      ErrorMessage(FormatLong('Ошибка N %d в DOC.BTR',Res));
                    Inc(i,9);
                  end;
                psInDoc:
                  begin
                    FillChar(pd,SizeOf(pd)-SizeOf(pd.dbDoc),0);
                    pd.dbIdKorr := PLong(@p^.rpText[i+1])^;
                    Len := PWord(@p^.rpText[i+5])^;
                    Move(p^.rpText[i+7],pd.dbDoc,Len);
                    pd.dbDocLen := Len-(SizeOf(TDocRec)-drMaxVar+SignSize);
                    pd.dbState := dsInputDoc;
                    if(NOT TestSign(pd,CenterNode)) then
                      pd.dbState := dsSignError OR dsInputDoc;
                    pd.dbIdHere := GetLongIdent(spIdent);
                    pd.dbIdIn  := pd.dbIdHere;
                    Len := pd.dbDocLen+(SizeOf(TDocInBase)-drMaxVar+SignSize);
                    Res := DocBase^.Insert(pd,Len,KeyL,0);
                    if((Res<>0) AND (Res<>5)) then
                      ErrorMessage(FormatLong('Ошибка N %d в DOC.BTR',Res));
                    Inc(piDocs);
                    Inc(i,PWord(@p^.rpText[i+5])^+7);
                  end;
                psDouble:
                  begin
                    FillChar(pd,SizeOf(pd)-SizeOf(pd.dbDoc),0);
                    pd.dbIdHere := PLong(@p^.rpText[i+1])^;
                    pd.dbIdKorr := PLong(@p^.rpText[i+5])^;
                    Len := PWord(@p^.rpText[i+9])^;
                    Move(p^.rpText[i+11],pd.dbDoc,Len);
                    pd.dbDocLen := Len-(SizeOf(TDocRec)-drMaxVar+SignSize);
                    pd.dbState := dsSndRcv;
                    if(NOT TestMySign(pd,CenterNode)) then
                      pd.dbState := dsSignError OR dsSndRcv;
                    pd.dbIdOut  := pd.dbIdHere;
                    Len := pd.dbDocLen+(SizeOf(TDocInBase)-drMaxVar+SignSize);
                    Res := DocBase^.Insert(pd,Len,KeyL,0);
                    if((Res<>0) AND (Res<>5)) then
                      ErrorMessage(FormatLong('Ошибка N %d в DOC.BTR',Res));
                    Inc(piDocs);
                    Inc(i,PWord(@p^.rpText[i+9])^+11);
                  end;
                psAnsBill, psInBill:
                  begin
                    KeyL := POpRec(@p^.rpText[i+3])^.brIder;
                    Len := SizeOf(po);
                    Res := BillBase^.GetEQ(po,Len,KeyL,0);
                    if(Res<>0) then
                      begin
                        Len := PWord(@p^.rpText[i+1])^;
                        Move(p^.rpText[i+3],po,Len);
                        Res := BillBase^.Insert(po,Len,KeyL,0);
                      end
                    else if(po.brVersion<POpRec(@p^.rpText[i+3])^.brVersion) then
                      begin
                        Len := PWord(@p^.rpText[i+1])^;
                        Move(p^.rpText[i+3],po,Len);
                        Res := BillBase^.Update(po,Len,KeyL,0);
                      end;
                    if(Res<>0) then
                      ErrorMessage(FormatLong('Ошибка N %d в Bill.btr',Res));
                    Inc(piBills);
                    Inc(i,PWord(@p^.rpText[i+1])^+3);
                  end;
                psAccState:
                  begin
                    KeyL := PAccRec(@p^.rpText[i+3])^.arIder;
                    Len := SizeOf(pa);
                    Res := AccBase^.GetEQ(pa,Len,KeyL,0);
                    if(Res<>0) then
                      begin
                        Move(p^.rpText[i+3],pa,PWord(@p^.rpText[i+1])^);
                        Len := SizeOf(pa);
                        Res := AccBase^.Insert(pa,Len,KeyL,0);
                      end
                    else if(pa.arVersion<PAccRec(@p^.rpText[i+3])^.arVersion) then
                      begin
                        Move(p^.rpText[i+3],pa,PWord(@p^.rpText[i+1])^);
                        Len := SizeOf(pa);
                        Res := AccBase^.Update(pa,Len,KeyL,0);
                      end;
                    if(Res<>0) then
                      ErrorMessage(FormatLong('Ошибка N %d в ACC.BTR',Res));
                    Inc(i,PWord(@p^.rpText[i+1])^+3);
                  end;
                psEMail:
                  begin
                    New(pe);
                    FillChar(pe^,SizeOf(pe^)-SizeOf(pe^.erText),0);
                    pe^.erIdKorr := PLong(@p^.rpText[i+1])^;
                    pe^.erIder := GetLongIdent(spIdent);
                    pe^.erIdCurI := pe^.erIder;
                    Len := PWord(@p^.rpText[i+5])^;
                    Move(p^.rpText[i+7],pe^.erText,Len);
                    pe^.erState := dsSndRcv;
                    if(NOT EMailTestSign(pe^,CenterNode)) then
                      pe^.erState := dsSignError OR dsSndRcv;
                    Len := (SizeOf(pe^)-SizeOf(pe^.erText))+Len;
                    Res := EMailBase^.Insert(pe^,Len,KeyL,0);
                    if(Res<>0) then
                      ErrorMessage(FormatLong('Ошибка N %d в EMAIL.BTR',Res));
                    Dispose(pe);
                    Inc(piLetters);
                    Inc(i,PWord(@p^.rpText[i+5])^+7);
                  end;
              else
                begin
                  ErrorMessage(FormatLong('В полученном пакете найдено сообщение тип %d',PByte(@p^.rpText[i])^));
                  break;
                end;
              end;
            end;
          Res := Inb^.Delete(Len,0);
        end;
      Len := SizeOf(p^);
      Res := Inb^.GetNext(p^,Len,KeyBuf,0);
    end;
end;

procedure PostDoc;
var
  Res, Len: integer;
  Base: PBtrBase;
  ps: PSndPack;
  pr: PRcvPack;
  OwnN: array[0..0] of char;
  KeyBuf: array[0..255] of char;
  s: string absolute KeyBuf;
label
  l_exit;
begin
  poSum := 0;
  poDocs := 0;
  poLetters := 0;
  piDocs := 0;
  piLetters := 0;
  piRets := 0;
  piBills := 0;
  Base := new(PBtrBase,Init);
  StrPCopy(KeyBuf,'..\focus\doc_s.btr');
  OwnN[0] := chr(0);
  Res := Base^.Open(KeyBuf,OwnN,mdNormal);
  if(Res<>0) then
    goto l_exit;
  ps := New(PSndPack);
  GetSentDoc(Base,ps);
  SendDoc(Base,ps);
  SendEMail(Base,ps);
  Dispose(ps);
  Res := Base^.Close;
  Str((poSum/100):16:2,s);
  if(MessageBoxRus('Будет отправлено:',
       FormatLong('документов - %d на сумму ',poDocs)+Trim(s)+
       FormatLong(';'#13#10'писем      - %d',poLetters),mfOkCancel)=cmOk) then
    PTApplication(Application)^.DosCmd(MailCmd);
  StrPCopy(KeyBuf,'..\focus\doc_s.btr');
  OwnN[0] := chr(0);
  Res := Base^.Open(KeyBuf,OwnN,mdNormal);
  if(Res<>0) then
    goto l_exit;
  ps := New(PSndPack);
  GetSentDoc(Base,ps);
  Dispose(ps);
  Res := Base^.Close;
  StrPCopy(KeyBuf,'..\focus\doc_r.btr');
  OwnN[0] := chr(0);
  Res := Base^.Open(KeyBuf,OwnN,mdNormal);
  if(Res<>0) then
    goto l_exit;
  pr := New(PRcvPack);
  ReceiveDoc(Base,pr);
  Dispose(pr);
  Res := Base^.Close;
l_exit:
  Dispose(Base,Done);
  MessageBoxRus('Получено:',
    FormatLong('документов - %d;'#13#10,piDocs)+
    FormatLong('выписок    - %d;'#13#10,piBills)+
    FormatLong('возвратов  - %d;'#13#10,piRets),mfOkButton);
  if(piLetters<>0) then
  MessageBoxRus('Получено:',
    FormatLong('писем      - %d',piLetters),mfOkButton);
end;

type
  PAccColRec = ^TAccColRec;
  TAccColRec = record
    acNumber: TAccount;
    acIder:   longint;
    acFDate:   word;
    acTDate:   word;
    acSumma:  comp;
    acSumma2: comp;
  end;

  PAccCollection = ^TAccCollection;
  TAccCollection = object(TSortedCollection)
    function Compare(Key1, Key2: Pointer): Integer; virtual;
    procedure FreeItem(Item: Pointer); virtual;
  end;

function TAccCollection.Compare(Key1, Key2: Pointer): Integer;
var
  k1: PAccColRec absolute Key1;
  k2: PAccColRec absolute Key2;
begin
  if(k1^.acNumber<k2^.acNumber) then
    Compare := -1
  else if(k1^.acNumber>k2^.acNumber) then
    Compare := 1
  else
    Compare :=0
end;

procedure TAccCollection.FreeItem(Item: Pointer);
var
  P: PAccColRec absolute Item;
begin
  Dispose(P)
end;

function CloseDate: boolean;
label
  l_10;
var
  Len, Res, Res1: integer;
  Key0: longint;
  KeyA: TAccount;
  KeyAA: record
    aaIder: longint;
    aaDate: word;
  end;
  KeyO: word;
  pa: TAccRec;
  paa: TAccArcRec;
  po: TOpRec;
  p: TDocInBase;
  t: comp;
  pc: PAccCollection;
  pac: PAccColRec;
  i: integer;
  LastDate, FirstDate, MaxDate: word;
  d,m,y: word;
  s: string[39];
  Errors: boolean;
begin
  CloseDate := false;
  LastDate := 0;
  Len := SizeOf(paa);
  Res := AccArcBase^.GetLast(paa,Len,KeyAA,0);
  if(Res=0) then
    LastDate := paa.aaDate;
  KeyO := LastDate;
  Len := SizeOf(po);
  Res := BillBase^.GetGT(po,Len,KeyO,2);
  while((Res=0) AND (po.brDel<>0)) do
    begin
      Len := SizeOf(po);
      Res := BillBase^.GetNext(po,Len,KeyO,2);
    end;
  if(Res<>0) then
    begin
      ErrorMessage('Нет операций - нечего закрывать');
      Exit;
    end;
  MaxDate := po.brDate;
  if(NOT GetBillDate(MaxDate,'Закрыть дни по')) then
    Exit;
  if(MaxDate<=LastDate) then
    begin
      WordToDate(LastDate,d,m,y);
      ErrorMessage('Уже закрыты дни по '+DateToStr(d,m,y));
      Exit;
    end;
{ Инициализация списка счетов }
  FirstDate := $FFFF;
  pc := New(PAccCollection,Init(200,100));
  Len := SizeOf(pa);
  Res := AccBase^.GetFirst(pa,Len,Key0,0);
  while(Res=0) do
    begin
      if((pa.arDateC=0) OR (pa.arDateC>LastDate)) then
        begin
          pac := New(PAccColRec);
          pac^.acNumber := pa.arNumber;
          pac^.acIder := pa.arIder;
          pac^.acFDate := pa.arDateO;
          pac^.acTDate := pa.arDateC;
          if(pac^.acTDate=0) then
            pac^.acTDate := $FFFF;
          pac^.acSumma := pa.arSumS;
          pac^.acSumma2 := pa.arSumS;
          KeyAA.aaIder := pa.arIder;
          KeyAA.aaDate := $FFFF;
          Len := SizeOf(paa);
          Res := AccArcBase^.GetLE(paa,Len,KeyAA,1);
          if((Res=0) AND (paa.aaIder=pa.arIder) AND
             (pac^.acFDate<paa.aaDate)) then
            begin
              pac^.acFDate := paa.aaDate;
              pac^.acSumma := paa.aaSum;
              pac^.acSumma2 := paa.aaSum;
            end;
          if(pac^.acFDate<FirstDate) then
            FirstDate := pac^.acFDate;
{@++}
          if(pac^.acFDate<LastDate) then
            begin
              WordToDate(pac^.acFDate,d,m,y);
              ErrorMessage('По счету '+
                           StrLPas(pac^.acNumber,SizeOf(pac^.acNumber))+
                           ' необходимо раскрыть дни по '+
                           DateToStr(d,m,y));
            end;
{@--}
          pc^.Insert(pac);
        end;
      Len := SizeOf(pa);
      Res := AccBase^.GetNext(pa,Len,Key0,0);
    end;
  if(FirstDate<LastDate) then
    begin
      WordToDate(FirstDate,d,m,y);
      ErrorMessage('Необходимо раскрыть операционные дни по '+
                   DateToStr(d,m,y));
      goto l_10;
    end;
{ Просчет состояний счетов по выпискам }
  KeyO := LastDate;
  Len := SizeOf(po);
  Res := BillBase^.GetGT(po,Len,KeyO,2);
  while(Res=0) do
    begin
      if((po.brDel=0) AND (po.brPrizn=brtBill)) then
        begin
          t := po.brSum;
          if(pc^.Search(@po.brAccD,i)) then
            begin
              pac := pc^.At(i);
              if((po.brDate>pac^.acFDate) AND (po.brDate<=pac^.acTDate)) then
                pac^.acSumma := pac^.acSumma-t;
            end;
          if(pc^.Search(@po.brAccC,i)) then
            begin
              pac := pc^.At(i);
              if((po.brDate>pac^.acFDate) AND (po.brDate<=pac^.acTDate)) then
                pac^.acSumma := pac^.acSumma+t;
            end;
        end;
      Len := SizeOf(po);
      Res := BillBase^.GetNext(po,Len,KeyO,2);
    end;
{ Проверка соответствия состояний счетов просчитанным по выпискам }
  Errors := false;
  i := 0;
  while(i<pc^.Count) do
    begin
      pac := pc^.At(i);
      Key0 := pac^.acIder;
      Len := SizeOf(pa);
      Res := AccBase^.GetEQ(pa,Len,Key0,0);
      if(Res=0) then
        begin
          if(pac^.acSumma<>pa.arSumA) then
            begin
              Str((pa.arSumA-pac^.acSumma)/100:16:2,s);
              ErrorMessage('Ошибка остатка по счету '+
                           StrLPas(pac^.acNumber,20)+
                           ' на сумму '+Trim(s));
              Errors := true
            end;
        end;
      Inc(i);
    end;
  if(Errors) then
    goto l_10;
  KeyO := LastDate;
  Len := SizeOf(po);
  Res := BillBase^.GetGT(po,Len,KeyO,2);
  while((Res=0) AND (po.brDate<=MaxDate)) do
    begin
      FirstDate := po.brDate;
{ Перепись док-тов из текущих в архив }
      while((Res=0) AND (po.brDate=FirstDate)) do
        begin
          if(po.brDel=0) then
            begin
              Key0 := po.brDocId;
              Len := SizeOf(p);
              Res := DocBase^.GetEQ(p,Len,Key0,1);
              if(Res=0) then
                begin
                  p.dbIdIn := 0;
                  p.dbIdOut := 0;
                  p.dbIdArc := p.dbIdHere;
                  Res := DocBase^.Update(p,Len,Key0,1);
                end;
              if(po.brPrizn=brtBill) then
                begin
                  t := po.brSum;
                  if(pc^.Search(@po.brAccD,i)) then
                    begin
                      pac := pc^.At(i);
                      if((po.brDate>pac^.acFDate) AND
                         (po.brDate<=pac^.acTDate)) then
                        pac^.acSumma2 := pac^.acSumma2-t;
                    end;
                  if(pc^.Search(@po.brAccC,i)) then
                    begin
                      pac := pc^.At(i);
                      if((po.brDate>pac^.acFDate) AND
                         (po.brDate<=pac^.acTDate)) then
                        pac^.acSumma2 := pac^.acSumma2+t;
                    end;
                end;
            end;
          Len := SizeOf(po);
          Res := BillBase^.GetNext(po,Len,KeyO,2);
        end;
{ Сохранение остатков на счетах в архиве }
      i := 0;
      while(i<pc^.Count) do
        begin
          pac := pc^.At(i);
          if((FirstDate>pac^.acFDate) AND (FirstDate<=pac^.acTDate)) then
            begin
              paa.aaIder := pac^.acIder;
              paa.aaDate := FirstDate;
              paa.aaSum := pac^.acSumma2;
              Len := SizeOf(paa);
              Res1 := AccArcBase^.Insert(paa,Len,KeyAA,0);
            end;
          Inc(i);
        end;
    end;
  EmptyMessage('Операционные дни закрыты');
  CloseDate := true;
l_10:
  Dispose(pc,Done);
end;

function ReOpenDate: boolean;
var
  Len, Res, Res1: integer;
  Key0: longint;
  KeyA: TAccount;
  KeyAA: record
    aaIder: longint;
    aaDate: word;
  end;
  KeyO: word;
  po: TOpRec;
  paa: TAccArcRec;
  pa: TAccRec;
  p: TDocInBase;
  LastDate, PrevDate, MaxDate: word;
  d,m,y: word;
begin
  ReOpenDate := false;
  LastDate := 0;
  Len := SizeOf(paa);
  Res := AccArcBase^.GetLast(paa,Len,KeyAA,0);
  if(Res<>0) then
    begin
      ErrorMessage('Нет закрытых дней');
      Exit;
    end;
  LastDate := paa.aaDate;
  MaxDate := LastDate;
  if(NOT GetBillDate(MaxDate,'Раскрыть дни по')) then
    Exit;
  if(MaxDate>LastDate) then
    begin
      WordToDate(LastDate,d,m,y);
      ErrorMessage('Дни закрыты только по '+DateToStr(d,m,y));
      Exit;
    end;
  while(LastDate>=MaxDate) do
    begin
      PrevDate := 0;
      KeyAA.aaDate := LastDate;
      KeyAA.aaIder := 0;
      Res := AccArcBase^.GetLT(paa,Len,KeyAA,0);
      if(Res=0) then
        PrevDate := paa.aaDate;
{ Переписать документы из архива в текущие }
      KeyO := LastDate+1;
      Len := SizeOf(po);
      Res := BillBase^.GetLT(po,Len,KeyO,2);
      while((Res=0) AND (po.brDate>PrevDate)) do
        begin
          if(po.brDel=0) then
            begin
              Key0 := po.brDocId;
              Len := SizeOf(p);
              Res := DocBase^.GetEQ(p,Len,Key0,1);
              if(Res=0) then
                begin
                  p.dbIdArc := 0;
                  if((p.dbState AND dsInputDoc)<>0) then
                    p.dbIdIn := p.dbIdHere
                  else
                    p.dbIdOut := p.dbIdHere;
                  Res := DocBase^.Update(p,Len,Key0,1);
                end;
            end;
          Len := SizeOf(po);
          Res := BillBase^.GetPrev(po,Len,KeyO,2);
        end;
{ Удалить из архива состояний счетов состояния за последнюю дату }
      Len := SizeOf(paa);
      Res := AccArcBase^.GetLast(paa,Len,KeyAA,0);
      while((Res=0) AND (paa.aaDate>=LastDate)) do
        begin
          Res := AccArcBase^.Delete(Len,0);
          Len := SizeOf(paa);
          Res := AccArcBase^.GetPrev(paa,Len,KeyAA,0);
        end;
      LastDate := 0;
      if(Res=0) then
        LastDate := paa.aaDate;
    end;
  EmptyMessage('Операционные дни раскрыты');
  ReOpenDate := true;
end;

type
  PDbfHeader = ^TDbfHeader;
  TDbfHeader = record
    dhHdr:    byte;
    dhYear:   byte;
    dhMonth:  byte;
    dhDay:    byte;
    dhLen:    longint;
    dhHdrSiz: word;
    dhRecLen: word;
    dhRest:   array[1..20] of char;
  end;
  PDbFileHeader = ^TDbFileHeader;
  TDbFileHeader = record
    dhFields: array[0..36] of TDbfHeader;
    dhEnd:    byte;
  end;
  PDbfData = ^TDbfData;
  TDbfData = record
    ddPrizn:    char;
    ddNumber:   array[1..5] of char;
    ddDate:     array[1..8] of char;
    ddVid:      char;
    ddSum:      array[1..15] of char;
    ddPAcc:     array[1..20] of char;
    ddPCode:    array[1..9] of char;
    ddPKs:      array[1..20] of char;
    ddPInn:     array[1..16] of char;
    ddPClient1: array[1..45] of char;
    ddPClient2: array[1..45] of char;
    ddPClient3: array[1..45] of char;
    ddPBank1:   array[1..45] of char;
    ddPBank2:   array[1..45] of char;
    ddRCode:    array[1..9] of char;
    ddRKs:      array[1..20] of char;
    ddRAcc:     array[1..20] of char;
    ddRBank1:   array[1..45] of char;
    ddRBank2:   array[1..45] of char;
    ddRInn:     array[1..16] of char;
    ddRClient1: array[1..45] of char;
    ddRClient2: array[1..45] of char;
    ddRClient3: array[1..45] of char;
    ddTypeOp:   array[1..2] of char;
    ddOcher:    array[1..2] of char;
    ddSrok:     array[1..8] of char;
    ddNazn1:    array[1..78] of char;
    ddNazn2:    array[1..78] of char;
    ddNazn3:    array[1..78] of char;
    ddNazn4:    array[1..78] of char;
    ddNazn5:    array[1..78] of char;
    ddState:    char;
    ddNumOp:    array[1..3] of char;
    ddDateOp:   array[1..8] of char;
    ddDtAcc:    array[1..20] of char;
    ddCrAcc:    array[1..20] of char;
    ddInfo:     array[1..30] of char;
  end;

function TestMakeDbfHeader(FileName: string; var f: file;
           NewFile: boolean; var FileHeader: TDbfHeader): boolean;
label
  WrongFormat,
  FileError,
  ExitProc;
var
  c, y, m, d, w: word;
  PDbHdr: PDbFileHeader;
  DbfFileDesc1: array[1..16] of word;
  DbfFileDesc2: array[1..16] of word;
  i, j: integer;
  b: byte;
begin
  TestMakeDbfHeader := false;
  New(PDbHdr);
  Assign(f,'dbf.hdr');
{$I-}
  Reset(f,1);
{$I+}
  if(IOResult<>0) then
    begin
      ErrorMessage('Ошибка открытия файла dbf.hdr');
      Goto ExitProc;
    end;
  BlockRead(f,PDbHdr^,SizeOf(PDbHdr^),c);
  Close(f);
  if(c<>SizeOf(PDbHdr^)) then
    begin
      ErrorMessage('Неправильный формат dbf.hdr');
      Goto ExitProc;
    end;
  GetDate(y,m,d,w);
  PDbHdr^.dhFields[0].dhYear := y-1900;
  PDbHdr^.dhFields[0].dhMonth := m;
  PDbHdr^.dhFields[0].dhDay := d;

  Assign(f,FileName);
{$I-}
  Reset(f,1);
{$I+}
  if(IOResult=0) then
    begin
      BlockRead(f,DbfFileDesc2,SizeOf(DbfFileDesc2),c);
      if(c<>SizeOf(DbfFileDesc2)) then
        goto WrongFormat;
      Move(PDbHdr^,DbfFileDesc1,SizeOf(DbfFileDesc1));
      if(DbfFileDesc1[5]<>DbfFileDesc2[5]) then
        goto WrongFormat;
      if(DbfFileDesc1[6]<>DbfFileDesc2[6]) then
        goto WrongFormat;
      Move(DbfFileDesc2,PDbHdr^,SizeOf(DbfFileDesc2));
      for j := 1 to 36 do
        begin
          Move(PDbHdr^.dhFields[j],DbfFileDesc1,SizeOf(DbfFileDesc1));
          BlockRead(f,DbfFileDesc2,SizeOf(DbfFileDesc2),c);
          if(c<>SizeOf(DbfFileDesc2)) then
            goto WrongFormat;
          for i := 1 to 6 do
            if(DbfFileDesc1[i]<>DbfFileDesc2[i]) then
              goto WrongFormat;
          if(DbfFileDesc1[9]<>DbfFileDesc2[9]) then
            goto WrongFormat;
        end;
      BlockRead(f,b,1,c);
      if((c<>1) OR (b<>13)) then
        begin
WrongFormat:
          ErrorMessage('Неправильный формат файла '+FileName);
          Close(f);
          Goto ExitProc;
        end;
    end
  else if(NewFile) then
    begin
{$I-}
      ReWrite(f,1);
{$I+}
      if(IOResult<>0) then
        Goto FileError;
      BlockWrite(f,PDbHdr^,SizeOf(PDbHdr^));
    end
  else
    begin
FileError:
      ErrorMessage('Ошибка открытия файла '+FileName);
      Goto ExitProc;
    end;
  Move(PDbHdr^,FileHeader,SizeOf(DbfFileDesc1));
  TestMakeDbfHeader := True;
ExitProc:
  Dispose(PDbHdr);
end;

procedure ExportDocDbf(var DbfData: TDbfData;
                       var p: TDocRec; Len: word);
var
  d,m,y,i: word;
  pp: pchar;
  s: string;
begin
  FillChar(DbfData,SizeOf(DbfData),' ');
  i := 0;
  s := StrLPas(@p.drVar[i],5);  { Номер }
  Inc(i,StrLen(@p.drVar[i])+1);
  Move(s[1],DbfData.ddNumber,Length(s));
  WordToDate(p.drDate,d,m,y);         { Дата }
  s := FormatLong('%04d',y)+FormatLong('%02d',m)+FormatLong('%02d',d);
  Move(s[1],DbfData.ddDate,Length(s));
  Str(p.drIsp:1,s);               { Способ исполнения }
  s := Copy(s,1,1);
  Move(s[1],DbfData.ddVid,Length(s));
  Str((p.drSum/100):15:2,s);      { Сумма платежа }
  s := Copy(s,1,15);
  Move(s[1],DbfData.ddSum,Length(s));
  s := StrLPas(@p.drVar[i],20); { Счет плательщика }
  Inc(i,StrLen(@p.drVar[i])+1);
  Move(s[1],DbfData.ddPAcc,Length(s));
  s := StrLPas(@p.drVar[i],20); { Счет банка плательщика }
  Inc(i,StrLen(@p.drVar[i])+1);
  Move(s[1],DbfData.ddPKs,Length(s));
  s := StrLPas(@p.drVar[i],9);  { Код банка плательщика }
  Inc(i,StrLen(@p.drVar[i])+1);
  Move(s[1],DbfData.ddPCode,Length(s));
  s := StrLPas(@p.drVar[i],16);  { ИНН плательщика }
  Inc(i,StrLen(@p.drVar[i])+1);
  Move(s[1],DbfData.ddPInn,Length(s));
  pp := @p.drVar[i];                  { Плательщик }
  s := Copy(FirstLine(pp),1,45);
  Move(s[1],DbfData.ddPClient1,Length(s));
  s := Copy(FirstLine(pp),1,45);
  Move(s[1],DbfData.ddPClient2,Length(s));
  s := Copy(FirstLine(pp),1,45);
  Move(s[1],DbfData.ddPClient3,Length(s));
  Inc(i,StrLen(@p.drVar[i])+1);
  pp := @p.drVar[i];                  { Банк плательщика }
  s := Copy(FirstLine(pp),1,45);
  Move(s[1],DbfData.ddPBank1,Length(s));
  s := Copy(FirstLine(pp),1,45);
  Move(s[1],DbfData.ddPBank2,Length(s));
  Inc(i,StrLen(@p.drVar[i])+1);
  s := StrLPas(@p.drVar[i],20); { Счет получателя }
  Inc(i,StrLen(@p.drVar[i])+1);
  Move(s[1],DbfData.ddRAcc,Length(s));
  s := StrLPas(@p.drVar[i],20); { Счет банка получателя }
  Inc(i,StrLen(@p.drVar[i])+1);
  Move(s[1],DbfData.ddRKs,Length(s));
  s := StrLPas(@p.drVar[i],9);  { Код банка получателя }
  Inc(i,StrLen(@p.drVar[i])+1);
  Move(s[1],DbfData.ddRCode,Length(s));
  s := StrLPas(@p.drVar[i],16); { ИНН получателя }
  Inc(i,StrLen(@p.drVar[i])+1);
  Move(s[1],DbfData.ddRInn,Length(s));
  pp := @p.drVar[i];                  { Получатель }
  s := Copy(FirstLine(pp),1,45);
  Move(s[1],DbfData.ddRClient1,Length(s));
  s := Copy(FirstLine(pp),1,45);
  Move(s[1],DbfData.ddRClient2,Length(s));
  s := Copy(FirstLine(pp),1,45);
  Move(s[1],DbfData.ddRClient3,Length(s));
  Inc(i,StrLen(@p.drVar[i])+1);
  pp := @p.drVar[i];                  { Банк получателя }
  s := Copy(FirstLine(pp),1,45);
  Move(s[1],DbfData.ddRBank1,Length(s));
  s := Copy(FirstLine(pp),1,45);
  Move(s[1],DbfData.ddRBank2,Length(s));
  Inc(i,StrLen(@p.drVar[i])+1);
  s := FormatLong('%02d',p.drType);  { Вид операции }
  Move(s[1],DbfData.ddTypeOp,Length(s));
  Str(p.drOcher:2,s);                { Очередность }
  s := Copy(s,1,2);
  Move(s[1],DbfData.ddOcher,Length(s));
  if(p.drSrok<>0) then               { Срок }
    begin
      WordToDate(p.drSrok,d,m,y);
      s := FormatLong('%04d',y)+FormatLong('%02d',m)+FormatLong('%02d',d);
      Move(s[1],DbfData.ddSrok,Length(s));
    end;
  pp := @p.drVar[i];                  { Назначение платежа }
  s := Copy(FirstLine(pp),1,78);
  Move(s[1],DbfData.ddNazn1,Length(s));
  s := Copy(FirstLine(pp),1,78);
  Move(s[1],DbfData.ddNazn2,Length(s));
  s := Copy(FirstLine(pp),1,78);
  Move(s[1],DbfData.ddNazn3,Length(s));
  s := Copy(FirstLine(pp),1,78);
  Move(s[1],DbfData.ddNazn4,Length(s));
  s := Copy(FirstLine(pp),1,78);
  Move(s[1],DbfData.ddNazn5,Length(s));
  Inc(i,StrLen(@p.drVar[i])+1);
end;

const
  ExportMessage: string[29] = 'Экспортировано документов: %d';
  ImportMessage: string[28] = 'Импортировано документов: %d';

procedure ExportDocsDbf(KeyNum: byte);
var
  f: file;
  p: PDocInBase;
  Res, Len: integer;
  i: word;
  Key: longint;
  FileName: FNameStr;
  DbfData: PDbfData;
  Hdr: TDbfHeader;
  b: byte;
begin
  FileName := '*.dbf';
  if(Application^.ExecuteDialog(New(PFileDialog,Init('',
      'Файл для экспорта','~N~ame',fdOkButton,0)),@FileName)<>cmCancel) then
    begin
      New(p);
      New(DbfData);
      if(TestMakeDbfHeader(FileName,f,true,Hdr)) then
        begin
          i := 0;
          Len := SizeOf(p^);
          Res := DocBase^.GetFirst(p^,Len,Key,KeyNum);
          while(Res=0) do
            begin
              ExportDocDbf(DbfData^,p^.dbDoc,p^.dbDocLen);
              Seek(f,Hdr.dhLen*Hdr.dhRecLen+Hdr.dhHdrSiz);
              BlockWrite(f,DbfData^,SizeOf(DbfData^));
              Inc(Hdr.dhLen);
              Seek(f,0);
              BlockWrite(f,Hdr,SizeOf(Hdr));
              Inc(i);
              Len := SizeOf(p^);
              Res := DocBase^.GetNext(p^,Len,Key,KeyNum);
            end;
          if(i<>0) then
            begin
              Seek(f,Hdr.dhLen*Hdr.dhRecLen+Hdr.dhHdrSiz);
              b := $1A;
              BlockWrite(f,b,1);
            end;
          Close(f);
          EmptyMessage(FormatLong(ExportMessage,i));
        end;
      Dispose(DbfData);
      Dispose(p);
    end;
end;

procedure StdExportDbf;
var
  f: file;
  p: PDocInBase;
  Res, Len: integer;
  i: word;
  Key: longint;
  DbfData: PDbfData;
  Hdr: TDbfHeader;
  b: byte;
begin
  if(StdExportName<>'') then
    begin
      New(p);
      New(DbfData);
      if(TestMakeDbfHeader(StdExportName,f,true,Hdr)) then
        begin
          i := 0;
          Len := SizeOf(p^);
          Res := DocBase^.GetFirst(p^,Len,Key,2);
          while(Res=0) do
            begin
              if((p^.dbState AND dsExport)=0) then
                begin
                  ExportDocDbf(DbfData^,p^.dbDoc,p^.dbDocLen);
                  Seek(f,Hdr.dhLen*Hdr.dhRecLen+Hdr.dhHdrSiz);
                  BlockWrite(f,DbfData^,SizeOf(DbfData^));
                  Inc(Hdr.dhLen);
                  Seek(f,0);
                  BlockWrite(f,Hdr,SizeOf(Hdr));
                  Inc(i);
                  p^.dbState := p^.dbState OR dsExport;
                  Res := DocBase^.Update(p^,Len,Key,2);
                end;
              Len := SizeOf(p^);
              Res := DocBase^.GetNext(p^,Len,Key,2);
            end;
          if(i<>0) then
            begin
              b := $1A;
              Seek(f,Hdr.dhLen*Hdr.dhRecLen+Hdr.dhHdrSiz);
              BlockWrite(f,b,1);
            end;
          Close(f);
          if(i<>0) then
            EmptyMessage(FormatLong(ExportMessage,i));
        end;
      Dispose(DbfData);
      Dispose(p);
    end;
end;

procedure ImportDocDbf(var DbfData: TDbfData;
                       var p: TDocRec; var Len: word);
var
  d,m,y,i,c: word;
  s: string;
  sum: extended;
begin
  i := 0;
  StrPCopy(@p.drVar[i],Trim(StrLPas(@DbfData.ddNumber,5)));  { Номер }
  Inc(i,StrLen(@p.drVar[i])+1);
  s := StrLPas(@DbfData.ddDate[1],4);
  Val(s,y,c);
  s := StrLPas(@DbfData.ddDate[5],2);
  Val(s,m,c);
  s := StrLPas(@DbfData.ddDate[7],2);
  Val(s,d,c);
  p.drDate := DateToWord(d,m,y);      { Дата }
  s := Trim(StrLPas(@DbfData.ddVid,1));
  Val(s,p.drIsp,c);                   { Вид платежа }
  s := Trim(StrLPas(@DbfData.ddSum,15));
  Val(s,sum,c);
  p.drSum := sum*100;                 { Сумма платежа }
  StrPCopy(@p.drVar[i],Trim(StrLPas(@DbfData.ddPAcc,20))); { Счет плательщика }
  Inc(i,StrLen(@p.drVar[i])+1);
  StrPCopy(@p.drVar[i],Trim(StrLPas(@DbfData.ddPKs,20))); { Счет банка плательщика }
  Inc(i,StrLen(@p.drVar[i])+1);
  StrPCopy(@p.drVar[i],Trim(StrLPas(@DbfData.ddPCode,9)));  { Код банка плательщика }
  Inc(i,StrLen(@p.drVar[i])+1);
  StrPCopy(@p.drVar[i],Trim(StrLPas(@DbfData.ddPInn,16)));  { ИНН плательщика }
  Inc(i,StrLen(@p.drVar[i])+1);
  StrPCopy(@p.drVar[i],TrimRight(StrLPas(@DbfData.ddPClient1,45))); { Плательщик }
  Inc(i,StrLen(@p.drVar[i]));
  p.drVar[i] := Chr(13);
  Inc(i);
  p.drVar[i] := Chr(10);
  Inc(i);
  StrPCopy(@p.drVar[i],TrimRight(StrLPas(@DbfData.ddPClient2,45))); { Плательщик }
  Inc(i,StrLen(@p.drVar[i]));
  p.drVar[i] := Chr(13);
  Inc(i);
  p.drVar[i] := Chr(10);
  Inc(i);
  StrPCopy(@p.drVar[i],TrimRight(StrLPas(@DbfData.ddPClient3,45))); { Плательщик }
  Inc(i,StrLen(@p.drVar[i])+1);
  StrPCopy(@p.drVar[i],TrimRight(StrLPas(@DbfData.ddPBank1,45))); { Банк плательщика }
  Inc(i,StrLen(@p.drVar[i]));
  p.drVar[i] := Chr(13);
  Inc(i);
  p.drVar[i] := Chr(10);
  Inc(i);
  StrPCopy(@p.drVar[i],TrimRight(StrLPas(@DbfData.ddPBank2,45))); { Банк плательщика }
  Inc(i,StrLen(@p.drVar[i])+1);
  StrPCopy(@p.drVar[i],Trim(StrLPas(@DbfData.ddRAcc,20))); { Счет получателя }
  Inc(i,StrLen(@p.drVar[i])+1);
  StrPCopy(@p.drVar[i],Trim(StrLPas(@DbfData.ddRKs,20))); { Счет банка получателя }
  Inc(i,StrLen(@p.drVar[i])+1);
  StrPCopy(@p.drVar[i],Trim(StrLPas(@DbfData.ddRCode,9)));  { Код банка получателя }
  Inc(i,StrLen(@p.drVar[i])+1);
  StrPCopy(@p.drVar[i],Trim(StrLPas(@DbfData.ddRInn,16)));  { ИНН получателя }
  Inc(i,StrLen(@p.drVar[i])+1);
  StrPCopy(@p.drVar[i],TrimRight(StrLPas(@DbfData.ddRClient1,45))); { Получатель }
  Inc(i,StrLen(@p.drVar[i]));
  p.drVar[i] := Chr(13);
  Inc(i);
  p.drVar[i] := Chr(10);
  Inc(i);
  StrPCopy(@p.drVar[i],TrimRight(StrLPas(@DbfData.ddRClient2,45))); { Получатель }
  Inc(i,StrLen(@p.drVar[i]));
  p.drVar[i] := Chr(13);
  Inc(i);
  p.drVar[i] := Chr(10);
  Inc(i);
  StrPCopy(@p.drVar[i],TrimRight(StrLPas(@DbfData.ddRClient3,45))); { Получатель }
  Inc(i,StrLen(@p.drVar[i])+1);
  s := Trim(StrLPas(@DbfData.ddTypeOp,2));
  StrPCopy(@p.drVar[i],TrimRight(StrLPas(@DbfData.ddRBank1,45))); { Банк получателя }
  Inc(i,StrLen(@p.drVar[i]));
  p.drVar[i] := Chr(13);
  Inc(i);
  p.drVar[i] := Chr(10);
  Inc(i);
  StrPCopy(@p.drVar[i],TrimRight(StrLPas(@DbfData.ddRBank2,45))); { Банк получателя }
  Inc(i,StrLen(@p.drVar[i])+1);
  Val(s,p.drType,c);                  { Вид операции }
  s := Trim(StrLPas(@DbfData.ddOcher,2));
  Val(s,p.drOcher,c);                 { Очередность }
  y := 0;
  m := 0;
  d := 0;
  s := StrLPas(@DbfData.ddSrok[1],4);
  Val(s,y,c);
  s := StrLPas(@DbfData.ddSrok[5],2);
  Val(s,m,c);
  s := StrLPas(@DbfData.ddSrok[7],2);
  Val(s,d,c);
  p.drSrok := DateToWord(d,m,y);      { Срок }
  StrPCopy(@p.drVar[i],TrimRight(StrLPas(@dbfData.ddNazn1,78))); { Назначение платежа }
  Inc(i,StrLen(@p.drVar[i]));
  p.drVar[i] := Chr(13);
  Inc(i);
  p.drVar[i] := Chr(10);
  Inc(i);
  StrPCopy(@p.drVar[i],TrimRight(StrLPas(@dbfData.ddNazn2,78))); { Назначение платежа }
  Inc(i,StrLen(@p.drVar[i]));
  p.drVar[i] := Chr(13);
  Inc(i);
  p.drVar[i] := Chr(10);
  Inc(i);
  StrPCopy(@p.drVar[i],TrimRight(StrLPas(@dbfData.ddNazn3,78))); { Назначение платежа }
  Inc(i,StrLen(@p.drVar[i]));
  p.drVar[i] := Chr(13);
  Inc(i);
  p.drVar[i] := Chr(10);
  Inc(i);
  StrPCopy(@p.drVar[i],TrimRight(StrLPas(@dbfData.ddNazn4,78))); { Назначение платежа }
  Inc(i,StrLen(@p.drVar[i]));
  p.drVar[i] := Chr(13);
  Inc(i);
  p.drVar[i] := Chr(10);
  Inc(i);
  StrPCopy(@p.drVar[i],TrimRight(StrLPas(@dbfData.ddNazn5,78))); { Назначение платежа }
  Inc(i,StrLen(@p.drVar[i])+1);

  Len := i;
end;

procedure ImportDocsDbf;
var
  f: file;
  p: PDocInBase;
  Res, Len: integer;
  Key: array[0..255] of char;
  FileName: FNameStr;
  i, j, c: word;
  DbfData: PDbfData;
  Hdr: TDbfHeader;
  b: byte;
begin
  FileName := '*.dbf';
  if(Application^.ExecuteDialog(New(PFileDialog,Init('',
      'Файл для импорта','~N~ame',fdOkButton,0)),@FileName)<>cmCancel) then
    begin
      New(p);
      New(DbfData);
      if(TestMakeDbfHeader(FileName,f,false,Hdr)) then
        begin
          j := 0;
          repeat
            BlockRead(f,DbfData^,SizeOf(DbfData^),c);
            if(c<>SizeOf(DbfData^)) then
              break;
            if(DbfData^.ddPrizn=' ') then
              begin
                FillChar(p^,SizeOf(p^),0);
                ImportDocDbf(DbfData^,p^.dbDoc,p^.dbDocLen);
                p^.dbIdHere := GetLongIdent(spIdent);
{              p.dbTxt.dbIdKorr := p.dbTxt.dbIdHere;}
                p^.dbIdOut := p^.dbIdHere;
{              MakeSign(p,CenterNode);}
                Len := SizeOf(p^)-drMaxVar+p^.dbDocLen+SignSize;
                Res := DocBase^.Insert(p^,Len,Key,0);
                Inc(j);
              end;
          until(false);
          Close(f);
          EmptyMessage(FormatLong(ImportMessage,j));
        end;
      Dispose(DbfData);
      Dispose(p);
    end;
end;

procedure StdImportDbf;
var
  f: file;
  p: PDocInBase;
  Res, Len: integer;
  c, j: word;
  i: longint;
  Key: longint;
  DbfData: PDbfData;
  Hdr: TDbfHeader;
begin
  if(StdImportName<>'') then
    begin
      New(p);
      New(DbfData);
      if(TestMakeDbfHeader(StdImportName,f,false,Hdr)) then
        begin
          i := 0;
          j := 0;
          while(i<Hdr.dhLen) do
            begin
              Seek(f,i*Hdr.dhRecLen+Hdr.dhHdrSiz);
              BlockRead(f,DbfData^,SizeOf(DbfData^),c);
              if(c<>SizeOf(DbfData^)) then
                break;
              if(DbfData^.ddPrizn=' ') then
                begin
                  FillChar(p^,SizeOf(p^),0);
                  ImportDocDbf(DbfData^,p^.dbDoc,p^.dbDocLen);
                  p^.dbIdHere := GetLongIdent(spIdent);
                  p^.dbIdOut := p^.dbIdHere;
                  Len := SizeOf(p^)-drMaxVar+p^.dbDocLen+SignSize;
                  Res := DocBase^.Insert(p^,Len,Key,0);
                  DbfData^.ddPrizn := '*';
                  Seek(f,i*Hdr.dhRecLen+Hdr.dhHdrSiz);
                  BlockWrite(f,DbfData^,SizeOf(DbfData^));
                  Inc(j);
                end;
              Inc(i);
            end;
          Close(f);
          if(j<>0) then
            EmptyMessage(FormatLong(ImportMessage,j));
        end;
      Dispose(DbfData);
      Dispose(p);
    end;
end;

end.
