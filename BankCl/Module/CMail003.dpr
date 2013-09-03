library CMail003;

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
  BtrDS,
  SearchFrm,
  Controls,
  Forms,
  Common,
  CommCons,
  Bases,
  Registr,
  Btrieve,
  Utilits,
  Sign,
  CrySign,
  ObmenFrm in 'ObmenFrm.pas' {ObmenForm},
  Posting in 'Posting.pas';

var
  Res, Len: Integer;
  Base: TBtrBase;
  ps: PSndPack;
  pr: PRcvPack;

procedure AddMessage(Mes: string; C: Integer; var S: string);
begin
  if C>0 then
  begin
    if Length(S)>0 then
      S := S + #13#10;
    S := S + Mes + ' - ' + IntToStr(C);
  end;
end;

procedure AddMes(Mes: string; C: Integer; var S: string);
begin
  if C>0 then
  begin
    if Length(S)>0 then
      S := S + '; ';
    S := S + Mes + ':' + IntToStr(C);
  end;
end;

procedure AddStrMes(Mes: string; var S: string);
begin
  if Length(Mes)>0 then
  begin
    if Length(S)>0 then
      S := S + '; ';
    S := S + Mes;
  end;
end;

procedure DoExchange;
const
  MesTitle: PChar = '����� � ������';
var
  T: array[0..1023] of Char;
  L, WaitHostTimeOut, ReceiverPort, MaxAuthTry: Integer;
  SenderAcc, ReceiverURL, M: string;
  AccArcRec: TAccArcRec;
  KeyAA:
    packed record
      aaIder: longint;
      aaDate: word;
    end;
  ObmenIsMaked: Boolean;
begin
  if GetNode>0 then
  begin
    if IsSanctAccess('PostSanc') then
    begin
      if GetRegParamByName('SenderAcc', CommonUserNumber, T) then
      begin
        SenderAcc := StrPas(@T);
        L := Length(SenderAcc);
        if (L>0) and (L<=8) then
        begin
          if GetRegParamByName('ReceiverAcc', CommonUserNumber, T) then
          begin
            ReceiverAcc := StrPas(@T);
            L := Length(ReceiverAcc);
            if (L>0) and (L<=8) then
            begin
              if GetRegParamByName('ReceiverURL', CommonUserNumber, T)
                and GetRegParamByName('ReceiverNode', CommonUserNumber, ReceiverNode)
                and GetRegParamByName('ReceiverPort', CommonUserNumber, ReceiverPort)
                and GetRegParamByName('WaitHost', CommonUserNumber, WaitHostTimeOut)
                and GetRegParamByName('PackSize', CommonUserNumber, Res)
                and GetRegParamByName('MaxAuthTry', CommonUserNumber, MaxAuthTry) then
              begin
                ReceiverURL := StrPas(@T);
                if (Res>1000) and (Res<MaxPackSize-(drMaxVar+7+SignSize)) then
                  PackSize := Res
                else
                  PackSize := 4096;
                try
                  Screen.Cursor := crHourGlass;

                  ShowComment('����������� � �����...');
                  AccDataSet := GlobalBase(biAcc);
                  BillDataSet := GlobalBase(biBill);
                  DocDataSet := GlobalBase(biPay);
                  BankDataSet := GlobalBase(biBank);
                  NpDataSet := GlobalBase(biNp);
                  FileDataSet := GlobalBase(biFile);
                  AccArcDataSet := GlobalBase(biAccArc);
                  ModuleDataSet := GlobalBase(biModule);
                  EMailDataSet := GlobalBase(biLetter);

                  Base := TBtrBase.Create;

                  poSum := 0;
                  poDocs := 0;
                  poLetters := 0;
                  poFiles := 0;

                  piBills := 0;
                  piRets := 0;
                  piKarts := 0;
                  piDocs := 0;
                  piDoubles := 0;
                  piLetters := 0;
                  piAccStates := 0;
                  piAccepts := 0;
                  piBanks := 0;
                  piFiles := 0;

                  StrPLCopy(KeyBuf, PostDir+'doc_s.btr', SizeOf(KeyBuf)-1);

                  Res := Base.Open(KeyBuf, baNormal);
                  if Res=0 then
                  begin
                    ShowComment('������������ ������� �� ��������...');
                    New(ps);
                    GetSentDoc(Base, ps);
                    if GetMainCryptoEngineIndex=ceiTcbGost then
                      SendDoc(Base, ps);
                    Dispose(ps);
                    Res := Base.Close;
                    ShowComment('');

                    M := '';
                    if (poDocs>0) or (poSum>0) then
                      M := #13#10'���������� - '+IntToStr(poDocs)+' �� ����� '
                        +SumToStr(poSum);
                    if poLetters>0 then
                      M := M + #13#10'����� - '+IntToStr(poLetters);
                     { +#13#10+'������ - '+IntToStr(poFiles)}
                    if Length(M)>0 then
                      M := #13#10'������������ �� ��������:' + M
                    else
                      M := #13#10'��� ������ ��� ��������, ����� ������ �����';
                    ObmenIsMaked := MakeObmen('=����� ������� � ������='
                      +M
                      +#13#10+'������� "������" ��� �����������...',
                      ReceiverURL, ReceiverPort,  SenderAcc, @AuthKey,
                      WaitHostTimeOut*1000, MaxAuthTry, '', PostDir,
                      GetHddPlaceId(BaseDir));
                    StrPLCopy(KeyBuf, PostDir+'doc_s.btr', SizeOf(KeyBuf)-1);
                    Res := Base.Open(KeyBuf, baNormal);
                    ShowComment('');
                    if Res=0 then
                    begin
                      ShowComment('�������� ������������ �������...');
                      New(ps);
                      GetSentDoc(Base, ps);
                      Dispose(ps);
                      Res := Base.Close;
                      StrPLCopy(KeyBuf, PostDir+'doc_r.btr', SizeOf(KeyBuf)-1);
                      Res := Base.Open(KeyBuf, baNormal);
                      if Res=0 then
                      begin
                        ShowComment('��������� ���������� �������...');
                        New(pr);

                        LastDaysDate := 0;
                        Len := SizeOf(AccArcRec);
                        Res := AccArcDataSet.BtrBase.GetLast(AccArcRec, Len, KeyAA, 0);
                        if Res=0 then
                          LastDaysDate := AccArcRec.aaDate
                        else
                          LastDaysDate := 0;
                        FirstDocDate := $FFFF;
                        OldDocCount := 0;

                        ReceiveDoc(Base, pr);
                        Dispose(pr);
                        Res := Base.Close;

                        GenerateFiles;
                        ShowComment('');

                        if ObmenIsMaked then
                        begin
                          M := '';
                          if poDocs>0 then
                            AddStrMes('D='+IntToStr(poDocs)+'x'+SumToStr(poSum), M);
                          if poLetters>0 then
                            AddStrMes('D='+IntToStr(poLetters), M);
                          if Length(M)=0 then
                            M := '0';
                          ProtoMes(plWarning, MesTitle, 'Sended: '+M);
                          M := '';
                          AddMes('B', piBills, M);
                          AddMes('R', piRets, M);
                          AddMes('K', piKarts, M);
                          AddMes('D', piDocs, M);
                          AddMes('U', piDoubles, M);
                          AddMes('L', piLetters, M);
                          AddMes('A', piAccStates, M);
                          AddMes('T', piAccepts, M);
                          AddMes('N', piBanks, M);
                          AddMes('F', piFiles, M);
                          if Length(M)=0 then
                            M := '0';
                          ProtoMes(plInfo, MesTitle, 'Received: '+M);
                          M := '';
                          AddMessage('��������', piBills, M);
                          AddMessage('���������', piRets, M);
                          AddMessage('��������', piKarts, M);
                          AddMessage('�������� ����������', piDocs, M);
                          AddMessage('��������� ����������', piDoubles, M);
                          AddMessage('�����', piLetters, M);
                          AddMessage('���������� ������', piAccStates, M);
                          {AddMessage('�������������', piAccepts, S);}
                          AddMessage('���������� ������', piBanks, M);
                          AddMessage('������', piFiles, M);
                          if Length(M)>0 then
                            MessageBox(Application.Handle, PChar('��������:'+#13#10+M),
                              MesTitle, MB_OK or MB_ICONINFORMATION);
                        end;
                        if OldDocCount>0 then
                          MessageBox(Application.Handle,
                            PChar('�������� ��������� �� ��� �������� ��� - '
                            +IntToStr(OldDocCount)+#13#10
                            +'��������� �������� ���� '+BtrDateToStr(LastDaysDate)
                            +#13#10+'���������� �������� ������������ ��� �� '
                            +BtrDateToStr(FirstDocDate)), MesTitle,
                            MB_OK or MB_ICONWARNING);
                      end
                      else
                        MessageBox(Application.Handle, '�� ������� ������� ���� �������� ������� doc_r.btr',
                          MesTitle, MB_OK or MB_ICONERROR);
                    end
                    else
                      MessageBox(Application.Handle, '�� ������� ������ ��� ������� ���� ��������� ������� doc_s.btr',
                        MesTitle, MB_OK or MB_ICONERROR);

                  end
                  else
                    MessageBox(Application.Handle, '�� ������� ������� ���� ��������� ������� doc_s.btr',
                      MesTitle, MB_OK or MB_ICONERROR);
                  ShowComment('');
                finally
                  Base.Free;
                  ShowComment('���������� ��������� ���...');
                  try
                    AccDataSet.Refresh;
                    DocDataSet.Refresh;
                    BankDataSet.Refresh;
                    FileDataSet.Refresh;
                    AccArcDataSet.Refresh;
                    EMailDataSet.Refresh;

                    AccDataSet.UpdateKeys;
                    DocDataSet.UpdateKeys;
                    BankDataSet.UpdateKeys;
                    EMailDataSet.UpdateKeys;
                    FileDataSet.UpdateKeys;
                    AccArcDataSet.UpdateKeys;
                  except
                    MessageBox(Application.Handle, '������ Refresh', MesTitle,
                      MB_OK or MB_ICONERROR);
                  end;
                  ShowComment('');

                  Screen.Cursor := crDefault;
                end;
              end
              else
                MessageBox(Application.Handle, '�� ������ ���� �� ���������� � �������:'+#13#10
                  +'����� �����, ����, ���� ����������, ������� � ����� �������',
                  MesTitle, MB_OK or MB_ICONERROR);
            end
            else
              MessageBox(Application.Handle, PChar('�������� ����� ��������� ���������� '
                +IntToStr(L)), MesTitle, MB_OK or MB_ICONERROR);
          end
          else
            MessageBox(Application.Handle, '�� ����� �������� ���������� � ����������',
              MesTitle, MB_OK or MB_ICONERROR);
        end
        else
          MessageBox(Application.Handle, PChar('�������� ����� ��������� ����������� '
            +IntToStr(L)+#13#10+'['+SenderAcc+']'),
            MesTitle, MB_OK or MB_ICONERROR);
      end
      else
        MessageBox(Application.Handle, '�� ����� �������� ����������� � ����������',
          MesTitle, MB_OK or MB_ICONERROR);
      if not GetRegParamByName('UpdateAfterMail', CommonUserNumber, ObmenIsMaked) then
        ObmenIsMaked := False;
      if ObmenIsMaked then
        PostMessage(Application.MainForm.Handle, WM_MAKEUPDATE, 0, 0);
    end
    else
      MessageBox(Application.Handle, '�� �� ������ ��������� ����� �����',
        MesTitle, MB_OK or MB_ICONINFORMATION);
  end
  else
    MessageBox(Application.Handle, PChar('����� ����� �� �������� ��� ������������� ������� '
      +IntToStr(GetNode)), MesTitle, MB_OK or MB_ICONINFORMATION);
end;

procedure CreateChildForm(Sender: TObject);
begin
  DoExchange;
end;

function NewMenuItem(AOwner: TComponent): TMenuItem;
begin
  Result := TMenuItem.Create(AOwner);
  with Result do
  begin
    Caption := '&����� ����� (�����.)';
    Hint := '������������ ������� � ������ ������ ��������';
    //ShortCut := TextToShortCut('Ctrl+M');
    ImageIndex := 43;
    GroupIndex := 4;
    HelpContext := 50;
    @OnClick := @CreateChildForm;
  end;
  ObjList.Add(Result);
end;

exports
  NewMenuItem name NewMenuItemDLLProcName;

procedure LoadDLLs;
const
  MesTitle: PChar = '�������� ������� ��������';
  DllNameList: array[0..1] of PChar = ('wininet.dll', 'rasapi32.dll');
  DllFuncNames1: array[0..1] of PChar = ('InternetAutodial',
    'InternetAutodialHangup');
  DllFuncNames2: array[0..3] of PChar = ('RasEnumConnectionsA', 'RasHangUpA',
    'RasCreatePhonebookEntryA', 'RasEditPhonebookEntryA');
var
  I, J: Integer;
  DLLModule: HModule;
  P: Pointer;
begin
  InternetAutoDialPtr := nil;
  InternetAutodialHangupPtr := nil;
  RasEnumConnectionsPtr := nil;
  RasHangUpPtr := nil;
  for I := 0 to 1 do
  begin
    DLLModule := LoadLibrary(DllNameList[I]);
    if DLLModule=0 then
      {MessageBox(ParentWnd, PChar('������ �������� '+DllNameList[I]+' ('
        +IntToStr(GetLastError)+')'), MesTitle, MB_OK or MB_ICONERROR)}
      {ProtoMes(plInfo, MesTitle, '������ �������� '+DllNameList[I]+' ('
        +IntToStr(GetLastError)+')')}
    else begin
      DLLList.Add(Pointer(DLLModule));
      case I of
        0:
          for J := 0 to 1 do
          begin
            P := GetProcAddress(DLLModule, DllFuncNames1[J]);
            if P<>nil then
              case J of
                0:
                  InternetAutoDialPtr := P;
                1:
                  InternetAutodialHangupPtr := P;
              end
            {else
              ProtoMes(plInfo, MesTitle, '��� ������� '+DllFuncNames1[J]
                + ' � '+DllNameList[I])};
          end;
        1:
          for J := 0 to 3 do
          begin
            P := GetProcAddress(DLLModule, DllFuncNames2[J]);
            if P<>nil then
              case J of
                0:
                  RasEnumConnectionsPtr := P;
                1:
                  RasHangUpPtr := P;
                2:
                  RasCreatePhonebookEntryPtr := P;
                3:
                  RasEditPhonebookEntryPtr := P;
              end
            {else
              ProtoMes(plInfo, MesTitle, '��� ������� '+DllFuncNames2[J]
                + ' � '+DllNameList[I])};
          end;
      end;
    end;
  end;
end;

procedure FreeDLLs;
var
  I: Integer;
  P: Pointer;
begin
  for I := 1 to DLLList.Count do
  begin
    P := DLLList.Items[I-1];
    FreeLibrary(HINST(P));
  end;
  DLLList.Clear;
end;

procedure DLLEntryProc(Reason: Integer);
var
  I: Integer;
begin
  case Reason of
    DLL_PROCESS_ATTACH:
      begin
        ObjList := TList.Create;
        DLLList := TList.Create;
        ObjList.Add(DLLList);
        LoadDLLs;
      end;
    DLL_PROCESS_DETACH:
      begin
        FreeDLLs;
        I := ObjList.Count;
        while I>0 do
        begin
          TObject(ObjList.Items[I-1]).Free;
          Dec(I);
        end;
        ObjList.Free;
      end;
  end;
end;

begin
  DLLProc := @DLLEntryProc;
  DLLEntryProc(DLL_PROCESS_ATTACH);
end.

