{ =========== Модуль для перевода числа на человеческий язык =============
* Две процедуры:
- procedure ValToRus(R:LongInt; var S1:string; var P:Byte; G:Byte)
- procedure ValToRusFrac(R:Real; var S:string)
 ¦Входные параметры:
    R - переводимое число
    G - род: 0,1,2-мужской,женский,средний
 ¦Выходные параметры:
    S1 - строка
    P - падеж: 0-5(6-11)-им,родит,дат,винит,твор,предл ед.числа (мн. числа)
    (В этой версии выдается только P=0,6 или 7)
* Ограничения.
    Число должно быть меньше миллиарда (целая часть не более 9 символов)
    Дробь распознается до миллионной доли
* Примеры.
  ValToRus(-7654321,S,P,0) выдаст S='минус семь миллионов шестьсот пятьдесят
четыре тысячи триста двадцать один' P=0
  ValToRusFrac(12.000001,S) выдаст S='двенадцать целых одна миллионная'}

unit Val2Rus;

interface

procedure ValToRus(R: Int64; var S1: string; var P: Byte; G: Byte);
procedure ValToRusFrac(R: Real; var S: string);

implementation

procedure ValToRus(R: Int64; var S1: string; var P: Byte; G: Byte);
const
  MD=255;
  SF: array[0..9] of string[5]=
    ('ноль','один','две','три','четыр','пят','шест','сем','восем','девят');
var
  FS: string[MD];
  F: array[1..MD] of Byte;
  LF,I,W: Integer;
  L: Int64;
  S: string;
begin
  if R<0 then begin R:=-R; S1:='минус' end else S1:='';
  Str(R,FS);
  LF:=Length(FS);
  for I:=1 to LF do F[LF-I+1]:=Ord(FS[I])-48;
  for I:=LF downto 1 do begin
    S:='';
    case I of
      1: begin P:=7;
         if (LF=1) or (F[2]<>1) then begin
           if not((LF>1)and(F[1]=0)) then begin
             S:=SF[F[1]];
             if (F[1]>1) and (F[1]<>3) then begin
               if F[1]=2 then begin if G<>1 then S[3]:='а' end else
               if F[1]=4 then S:=S+'е' else S:=S+'ь';
             end;
             case F[1] of
               1: begin
                    P:=0;
                    if G>0 then begin
                      S[3]:='н';
                      case G of
                        1: S[4]:='а';
                        2: S[4]:='о';
                      end
                    end;
                  end;
               2..4: P:=6;
             end;
           end
         end;
         end;
      2: case F[2] of
           1: if F[1]=0 then S:='десять' else S:=SF[F[1]]+'надцать';
           2: S:='двадцать';
           3: S:='тридцать';
           4: S:='сорок';
           5..8: S:=SF[F[2]]+'ьдесят';
           9: S:='девяносто'
         end;
      3: case F[3] of
           1: S:='сто';
           2: S:='двести';
           3: S:=SF[F[3]]+'ста';
           4: S:=SF[F[3]]+'еста';
           5..9: S:=SF[F[3]]+'ьсот'
         end;
      4: begin
           W:=LF-3; S:='';
           repeat S:=FS[W]+S; Dec(W) until (W=0) or (LF-W>5);
           Val(S,L,W);
           if L>0 then begin
             ValToRus(L,S,P,1);
             S:=S+' тысяч';
             case P of
               0: S:=S+'а';
               6: S:=S+'и';
             end;
           end else S:=''
         end;
      7: begin
           W:=LF-6; S:='';
           repeat S:=FS[W]+S; Dec(W) until (W=0) or (LF-W>8);
           Val(S,L,W);
           if L>0 then begin
             ValToRus(L,S,P,0);
             S:=S+' миллион';
             case P of
               6: S:=S+'а';
               7: S:=S+'ов';
             end;
           end else S:=S+'?';
         end;
      10: begin
           W:=LF-9; S:='';
           repeat S:=FS[W]+S; Dec(W) until (W=0);
           Val(S,L,W);
           if L>0 then begin
             ValToRus(L,S,P,0);
             S:=S+' миллиард';
             case P of
               6: S:=S+'а';
               7: S:=S+'ов';
             end;
           end else S:=S+'?';
         end;
      else S:='';
    end;
    if S<>'' then begin if S1<>'' then S1:=S1+' '; S1:=S1+S end;
  end
end;

procedure ValToRusFrac(R:Real; var S:string);
var I: LongInt;
    W,K: Integer;
    P: Byte;
    S1: string;
begin
  I:=Trunc(R);
  ValToRus(I,S,P,1); (*1 - жен.род*)
  if R<0 then begin
    R:=-R;
    if I=0 then S:='минус '+S;
  end;
  case P of
    0: S1:='целая';
    7,6: S1:='целых';
  end;
  S:=S+' '+S1;
  R:=Frac(R);
  if R>0.4e-6 then begin
    R:=R*1e6;
    Str(R:0:0,S1);
    K:=Length(S1);
    W:=K;
    while S1[K]='0' do Dec(K);
    S1:=Copy(S1,1,K);
    K:=6-(W-K);
    Val(S1,I,W);
    ValToRus(I,S1,P,1); (*1 - жен.род*)
    S:=S+' '+S1+' ';
    case K of
       1: S1:='десят';
       2: S1:='сот';
       3: S1:='';
       4: S1:='десяти';
       5: S1:='сто';
       6: S1:='милионн'
    end;
    if (2<K) and (K<6) then S1:=S1+'тысячн';
    S:=S+S1;
    case P of
      0: S1:='ая';
      6,7: S1:='ых';
    end;
    S:=S+S1;
  end
end;

Begin End.