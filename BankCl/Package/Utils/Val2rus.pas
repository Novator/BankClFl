{ =========== ������ ��� �������� ����� �� ������������ ���� =============
* ��� ���������:
- procedure ValToRus(R:LongInt; var S1:string; var P:Byte; G:Byte)
- procedure ValToRusFrac(R:Real; var S:string)
 �������� ���������:
    R - ����������� �����
    G - ���: 0,1,2-�������,�������,�������
 ��������� ���������:
    S1 - ������
    P - �����: 0-5(6-11)-��,�����,���,�����,����,����� ��.����� (��. �����)
    (� ���� ������ �������� ������ P=0,6 ��� 7)
* �����������.
    ����� ������ ���� ������ ��������� (����� ����� �� ����� 9 ��������)
    ����� ������������ �� ���������� ����
* �������.
  ValToRus(-7654321,S,P,0) ������ S='����� ���� ��������� �������� ���������
������ ������ ������ �������� ����' P=0
  ValToRusFrac(12.000001,S) ������ S='���������� ����� ���� ����������'}

unit Val2Rus;

interface

procedure ValToRus(R: Int64; var S1: string; var P: Byte; G: Byte);
procedure ValToRusFrac(R: Real; var S: string);

implementation

procedure ValToRus(R: Int64; var S1: string; var P: Byte; G: Byte);
const
  MD=255;
  SF: array[0..9] of string[5]=
    ('����','����','���','���','�����','���','����','���','�����','�����');
var
  FS: string[MD];
  F: array[1..MD] of Byte;
  LF,I,W: Integer;
  L: Int64;
  S: string;
begin
  if R<0 then begin R:=-R; S1:='�����' end else S1:='';
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
               if F[1]=2 then begin if G<>1 then S[3]:='�' end else
               if F[1]=4 then S:=S+'�' else S:=S+'�';
             end;
             case F[1] of
               1: begin
                    P:=0;
                    if G>0 then begin
                      S[3]:='�';
                      case G of
                        1: S[4]:='�';
                        2: S[4]:='�';
                      end
                    end;
                  end;
               2..4: P:=6;
             end;
           end
         end;
         end;
      2: case F[2] of
           1: if F[1]=0 then S:='������' else S:=SF[F[1]]+'�������';
           2: S:='��������';
           3: S:='��������';
           4: S:='�����';
           5..8: S:=SF[F[2]]+'������';
           9: S:='���������'
         end;
      3: case F[3] of
           1: S:='���';
           2: S:='������';
           3: S:=SF[F[3]]+'���';
           4: S:=SF[F[3]]+'����';
           5..9: S:=SF[F[3]]+'����'
         end;
      4: begin
           W:=LF-3; S:='';
           repeat S:=FS[W]+S; Dec(W) until (W=0) or (LF-W>5);
           Val(S,L,W);
           if L>0 then begin
             ValToRus(L,S,P,1);
             S:=S+' �����';
             case P of
               0: S:=S+'�';
               6: S:=S+'�';
             end;
           end else S:=''
         end;
      7: begin
           W:=LF-6; S:='';
           repeat S:=FS[W]+S; Dec(W) until (W=0) or (LF-W>8);
           Val(S,L,W);
           if L>0 then begin
             ValToRus(L,S,P,0);
             S:=S+' �������';
             case P of
               6: S:=S+'�';
               7: S:=S+'��';
             end;
           end else S:=S+'?';
         end;
      10: begin
           W:=LF-9; S:='';
           repeat S:=FS[W]+S; Dec(W) until (W=0);
           Val(S,L,W);
           if L>0 then begin
             ValToRus(L,S,P,0);
             S:=S+' ��������';
             case P of
               6: S:=S+'�';
               7: S:=S+'��';
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
  ValToRus(I,S,P,1); (*1 - ���.���*)
  if R<0 then begin
    R:=-R;
    if I=0 then S:='����� '+S;
  end;
  case P of
    0: S1:='�����';
    7,6: S1:='�����';
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
    ValToRus(I,S1,P,1); (*1 - ���.���*)
    S:=S+' '+S1+' ';
    case K of
       1: S1:='�����';
       2: S1:='���';
       3: S1:='';
       4: S1:='������';
       5: S1:='���';
       6: S1:='�������'
    end;
    if (2<K) and (K<6) then S1:=S1+'������';
    S:=S+S1;
    case P of
      0: S1:='��';
      6,7: S1:='��';
    end;
    S:=S+S1;
  end
end;

Begin End.