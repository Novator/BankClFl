unit BankSpravFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Grids, Db, DBTables, DBGrids, ExtCtrls, DBCtrls, Menus,
  StdCtrls, Buttons, ComCtrls, Common, Basbn, Utilits,
  BtrDS, BankCnBn, Registr, CommCons, {Quorum, }Btrieve,
  ToolEdit, {Sign, }BUtilits, Mask, RxMemDS, Spin, DbfDataSet;

type
  TBankSpravForm = class(TForm)
    StatusBar: TStatusBar;
    ProtoGroupBox: TGroupBox;
    ProgressBar: TProgressBar;
    SetupPanel: TPanel;
    BtnPanel: TPanel;
    CancelBtn: TBitBtn;
    ProccessBtn: TBitBtn;
    ProtoListBox: TListBox;
    LeftPanel: TPanel;
    FilenameEdit: TFilenameEdit;
    FileNameLabel: TLabel;
    VerSpinEdit: TSpinEdit;
    VerLabel: TLabel;
    BankDataSet: TDbfDataSet;
    StatGroupBox: TGroupBox;
    ModBankLabel: TLabel;
    AddBankLabel: TLabel;
    DelBankLabel: TLabel;
    DelBankCountLabel: TLabel;
    ModBankCountLabel: TLabel;
    AddBankCountLabel: TLabel;
    DelSityLabel: TLabel;
    AddSityLabel: TLabel;
    DelSityCountLabel: TLabel;
    AddSityCountLabel: TLabel;
    AboCountLabel: TLabel;
    AboLabel: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure ProccessBtnClick(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    {PznNameList, }TipNpList: TStringList;
  protected
  public
    procedure InitProgress(Min, Max: Integer);
    {function Pzn(Arg: string): string;}
    function TipNp(Arg: char): string;
    procedure ShowProto(Level: Byte; S: string);
    procedure ShowStatus(S: string);
  end;

const
  BankSpravForm: TBankSpravForm = nil;
var
  CurrDate: TDate = 0;

implementation


{$R *.DFM}

procedure TBankSpravForm.ShowProto(Level: Byte; S: string);
begin
  ProtoListBox.Items.Add(LevelToStr(Level)+': '+S);
  ProtoMes(Level, 'SprUpdate', S);
end;

procedure TBankSpravForm.ShowStatus(S: string);
begin
  StatusBar.Panels[1].Text := S;
  Application.ProcessMessages;
end;

var
  Process: Boolean = False;
  
var
  CorrSprDataSet, CorrAboDataSet, AbonDataSet: TExtBtrDataSet;

procedure TBankSpravForm.FormCreate(Sender: TObject);
const
  Border=2;
var
  S: string;
  SprCorRec: TSprCorRec;
  Len, Res: Integer;
  SprKey: packed record
    skIderR:  longint;                  {Идер записи          k0, k1.0}
    skIderC:  longint;                  {Идер обновления          k1.1}
  end;
begin
  {PznNameList := TStringList.Create;}
  TipNpList := TStringList.Create;
  CorrSprDataSet := GlobalBase(biCorrSpr) as TBtrDataSet;
  CorrAboDataSet := GlobalBase(biCorrAbo) as TBtrDataSet;
  AbonDataSet := GlobalBase(biAbon) as TBtrDataSet;
  with ProgressBar do
  begin
    Parent := StatusBar;
    SetBounds(0, Border, Width, StatusBar.Height - Border);
    StatusBar.Panels[0].Width := Width;
  end;
  {try
    S := BaseDir + 'PznName.txt';
    PznNameList.LoadFromFile(S);
  except
    ShowProto(plError, 'Не удалось загрузить таблицу типов банков '+S);
  end;}
  try
    S := BaseDir + 'TipNp.txt';
    TipNpList.LoadFromFile(S);
  except
    ShowProto(plError, 'Не удалось загрузить таблицу типов банков '+S);
  end;
  Len := SizeOf(SprCorRec);
  Res := CorrSprDataSet.BtrBase.GetLast(SprCorRec, Len, SprKey, 1);
  if Res=0 then
  begin
    VerSpinEdit.Value := SprCorRec.scVer+1;
    VerSpinEdit.MinValue := SprCorRec.scVer;
  end;
end;

{function TBankSpravForm.Pzn(Arg: string): string;
var
  s: string;
begin
  s := '';
  if Length(Arg)>1 then
    try
      case Arg[1] of
        '0': if Arg[2]='0' then
          s := PznNameList.Strings[0];
        '1': if Arg[2]='0' then
          s := PznNameList.Strings[1];
        '2':
          if Arg[2]='0' then
            s := PznNameList.Strings[2]
          else
            if Arg[2]='1' then
              s := PznNameList.Strings[3]
            else
              if Arg[2]='3' then
                s := PznNameList.Strings[4]
               else
                 if Arg[2]='4' then
                   s := PznNameList.Strings[5]
                 else
                   if Arg[2]='5' then
                     s := PznNameList.Strings[6];
        '3': if Arg[2]='0' then s := PznNameList.Strings[7]
             else if Arg[2]='1' then s := PznNameList.Strings[8]
             else if Arg[2]='2' then s := PznNameList.Strings[9]
             else if Arg[2]='3' then s := PznNameList.Strings[10]
             else if Arg[2]='4' then s := PznNameList.Strings[11]
             else if Arg[2]='5' then s := PznNameList.Strings[12]
             else if Arg[2]='6' then s := PznNameList.Strings[13];
        '4': if Arg[2]='0' then s := PznNameList.Strings[14];
        '5': if Arg[2]='0' then s := PznNameList.Strings[15];
        '7': if Arg[2]='0' then s := PznNameList.Strings[16]
             else if Arg[2]='1' then s := PznNameList.Strings[17]
             else if Arg[2]='2' then s := PznNameList.Strings[18];
        '9': if Arg[2]='0' then s := PznNameList.Strings[19]
             else if Arg[2]='8' then s := PznNameList.Strings[20]
             else if Arg[2]='9' then s := PznNameList.Strings[21];
      end;
    except
      ShowProto(plError, 'Ошибка Pzn ['+Arg+']');
    end;
  Result := s;
end;}

function TBankSpravForm.TipNp(Arg: char): string;
begin
  Result := '';
  try
    case Arg of
      '1': Result := TipNpList.Strings[0];
      '2': Result := TipNpList.Strings[1];
      '3': Result := TipNpList.Strings[2];
      '4': Result := TipNpList.Strings[3];
      '5': Result := TipNpList.Strings[4];
      '6': Result := TipNpList.Strings[5];
      '7': Result := TipNpList.Strings[6];
    end;
  except
    ShowProto(plError, 'Ошибка TipNp ['+Arg+']');
  end;
end;

var
  RusBuf: array[0..127] of Char;

function Min(A, B: Integer): Integer;
begin
  if B<A then
    Result := B
  else
    Result := A;
end;

function NpInfo(NpRec: TNpRec): string;
begin
  StrLCopy(RusBuf, NpRec.npType, Min(SizeOf(NpRec.npType), SizeOf(RusBuf)));
  DosToWin(RusBuf);
  Result := '['+RusBuf;
  StrLCopy(RusBuf, NpRec.npName, Min(SizeOf(NpRec.npName), SizeOf(RusBuf)));
  DosToWin(RusBuf);
  Result := Result +'_'+RusBuf+']';
end;

function BankInfo(BankRec: TBankNewRec): string;
begin
  {StrLCopy(RusBuf, BankRec.brType, Min(SizeOf(BankRec.brType), SizeOf(RusBuf)));
  DosToWin(RusBuf);}
  Result := '['+IntToStr(BankRec.brCod){+' '+RusBuf};

  StrLCopy(RusBuf, BankRec.brName, Min(SizeOf(BankRec.brName), SizeOf(RusBuf)));
  DosToWin(RusBuf);
  Result := Result + '_' + RusBuf;

  StrLCopy(RusBuf, BankRec.brKs, Min(SizeOf(BankRec.brKs), SizeOf(RusBuf)));
  Result := Result + '{' + RusBuf + '}' + IntToStr(BankRec.brNpIder) + ']';
end;

procedure TBankSpravForm.InitProgress(Min, Max: Integer);
begin
  ProgressBar.Min := -10000000;
  ProgressBar.Position := ProgressBar.Min;
  ProgressBar.Max := Min;
  ProgressBar.Min := Min;
  ProgressBar.Position := ProgressBar.Min;
  ProgressBar.Max := Max;
  ProgressBar.Show;
end;

procedure TBankSpravForm.ProccessBtnClick(Sender: TObject);
const
  MesTitle: PChar = 'Генерация обновлений';
var
  LastCorr, LastRec: Integer;
  SprCorRec: TSprCorRec;
  SprAboRec: TSprAboRec;
  //CorrRec: TCorrRec;
  AbonRec: TAbonentRec;
  VerNum: Integer;

function AddBank(var br: TBankNewRec; var np: TNpRec): Integer;
var
  Len, KeyN: Integer;
begin
  Inc(LastRec);
  SprCorRec.scIderR := LastRec;
  SprCorRec.scIderC := LastCorr;
  SprCorRec.scVer := VerNum;
  SprCorRec.scType := psAddBank;
  Move(br, SprCorRec.scData, 24);
  Move(br.brName, SprCorRec.scData[24], 45);
  Move(np.npName, SprCorRec.scData[69], 30);
  Len := SizeOf(SprCorRec) - SizeOf(SprCorRec.scData) + 99;
  Result := CorrSprDataSet.BtrBase.Insert(SprCorRec, Len, KeyN, 0);
end;

function DelBank(var br: TBankNewRec): Integer;
var
  Len, KeyN: Integer;
begin
  Inc(LastRec);
  SprCorRec.scIderR := LastRec;
  SprCorRec.scIderC := LastCorr;
  SprCorRec.scVer := VerNum;
  SprCorRec.scType := psDelBank;
  Move(br, SprCorRec.scData, 4);
  Len := SizeOf(SprCorRec) - SizeOf(SprCorRec.scData) + 4;
  Result := CorrSprDataSet.BtrBase.Insert(SprCorRec, Len, KeyN, 0);
end;

function GetFldIndex(S: string): Integer;
var
  Fld: TField;
begin
  Result := -1;
  Fld := BankDataSet.Fields.FindField(S);
  if Fld=nil then
    MessageBox(Handle, PChar('Не найдено поле '+S), MesTitle,
      MB_OK or MB_ICONERROR)
  else
    Result := Fld.Index;
end;

var
  CntA, CntD, CntN, CntR, CntC: Integer;

procedure WriteNpChanges(var Np: TNpRec; C: char);
begin
  ShowProto(plInfo, C+'>'+NpInfo(Np));
  case C of
    'N':
      begin
        Inc(CntN);
        AddSityCountLabel.Caption := IntToStr(CntN);
      end;
    'R':
      begin
        Inc(CntR);
        DelSityCountLabel.Caption := IntToStr(CntR);
      end;
  end;
  Application.ProcessMessages;
end;

procedure WriteBankChanges(var Bn: TBankNewRec; var Np: TNpRec; C: char);
begin
  ShowProto(plInfo, C+'>'+BankInfo(Bn)+' '+NpInfo(Np));
  case C of
    'A':
      begin
        Inc(CntA);
        AddBankCountLabel.Caption := IntToStr(CntA);
      end;
    'C':
      begin
        Inc(CntC);
        ModBankCountLabel.Caption := IntToStr(CntC);
      end;
    'D':
      begin
        Inc(CntD);
        DelBankCountLabel.Caption := IntToStr(CntD);
      end;
  end;
  Application.ProcessMessages;
end;

var
  EmptyBankName, OldBankName, NewBankName, NpBaseName, OldNpBaseName, DbfName,
    S: string;
  OldBank, NewBank, NpBase: TBtrBase;
  fiTnp, fiNnp, fiNamep, fiNewnum, {fiP, fiPzn,} fiKsNp: Integer;
  Res, Len, LastNp, FirstRec, CntO, CntNp, Key0, KeyN, I: Integer;
  Key1:
    packed record
      k1Name: array[0..24] of Char;
      k1Type: array[0..4] of Char;
    end;
  KeyN1:
    packed record
      knIderR: longint;
      knIderC: longint;
    end;
  BankRec, OldBankRec: TBankNewRec;
  NpRec, OldNpRec: TNpRec;
begin
  if Process then
    Process := False
  else begin
    Process := True;
    ProccessBtn.Caption := '&Прервать';
    CancelBtn.Enabled := False;
    ShowStatus('');
    if Length(FilenameEdit.Text)>0 then
    begin
      DbfName := FilenameEdit.Text;  
      with BankDataSet do
      begin
        TableName := DbfName;
        ShowStatus('Открытие файла '+DbfName+'...');
        try
          Active := True;
        except
          MessageBox(Handle, PChar('Ошибка при открытии ['+DbfName+']'),
            MesTitle, MB_OK or MB_ICONERROR);
        end;
        if Active then
        begin
          ShowStatus('Поиск полей в '+DbfName+'...');

          fiTnp := GetFldIndex('Tnp');
          fiNnp := GetFldIndex('Nnp');
          fiNamep := GetFldIndex('Namep');
          fiNewnum := GetFldIndex('Newnum');
          {fiP := GetFldIndex('P');}
          {fiPzn := GetFldIndex('Pzn');}
          fiKsNp := GetFldIndex('KsNp');

          if (fiTnp>=0) and (fiNnp>=0) and (fiNamep>=0) and (fiNewnum>=0)
            {and (fiP>=0) and (fiPzn>=0)} and (fiKsNp>=0) then
          begin
            EmptyBankName := DecodeMask('$(Base)', 5, CommonUserNumber) + 'emptbank.btr';
            OldBankName := UserBaseDir + 'oldbank.btr';
            NewBankName := UserBaseDir + 'newbank.btr';
            NpBaseName := UserBaseDir + 'newnp.btr';
            OldNpBaseName := UserBaseDir + 'oldnp.btr';
            if FileExists(NewBankName) and FileExists(NpBaseName) then
            begin
              if DeleteFile(OldBankName) then
                ShowStatus('Старый бэкап '+OldBankName+' удален.');
              ShowStatus('Переименование '+NewBankName+' в '+OldBankName+'...');
              if RenameFile(NewBankName, OldBankName) then
              begin
                if DeleteFile(OldNpBaseName) then
                  ShowStatus('Старый бэкап Np '+OldNpBaseName+' удален.');
                ShowStatus('Копия старого '+NpBaseName+' в '+OldNpBaseName+'...');
                if CopyFile(PChar(NpBaseName), PChar(OldNpBaseName), True) then
                begin
                  ShowStatus('Копия пустого '+EmptyBankName+' в '+NewBankName+'...');
                  if CopyFile(PChar(EmptyBankName), PChar(NewBankName), True) then
                  begin
                    ShowStatus('Открытие '+NewBankName+'...');
                    NewBank := TBtrBase.Create;
                    Res := NewBank.Open(NewBankName, baNormal);
                    if Res=0 then
                    begin
                      ShowStatus('Открытие '+OldBankName+'...');
                      OldBank := TBtrBase.Create;
                      Res := OldBank.Open(OldBankName, baReadOnly);
                      if Res=0 then
                      begin
                        ShowStatus('Открытие '+NpBaseName+'...');
                        NpBase := TBtrBase.Create;
                        Res := NpBase.Open(NpBaseName, baNormal);
                        if Res=0 then
                        begin
                          ShowStatus('Поиск последнего города...');
                          Res := NpBase.GetLastKey(LastNp, 0);
                          if Res=0 then
                          begin
                            ShowStatus('Поиск последнего индекса корректировки справочника...');
                            Res := CorrSprDataSet.BtrBase.GetLastKey(LastRec, 0);
                            if Res=9 then
                              LastRec := 0
                            else
                              if Res<>0 then
                                LastRec := -1;
                            if LastRec >= 0 then
                            begin
                              FirstRec := LastRec;
                              ShowStatus('Поиск последней записи корректировки справочника...');
                              Res := CorrSprDataSet.BtrBase.GetLastKey(KeyN1, 1);
                              if Res=9 then
                                LastCorr := 1
                              else
                                if Res=0 then
                                  LastCorr := KeyN1.knIderC+1
                                else
                                  LastCorr := -1;
                              if LastCorr>0 then
                              begin
                                try
                                  VerNum := VerSpinEdit.Value;
                                except
                                  ShowProto(plError, 'Неверно указана версия!');
                                  VerNum := 0;
                                end;
                                ShowProto(plInfo, 'Создание рассылки банков версии '
                                  +IntToStr(VerNum));
                                CntA := 0;
                                CntD := 0;
                                CntN := 0;
                                CntR := 0;
                                CntC := 0;
                                CntO := 0;
                                CntNp := LastNp;
                                ShowStatus('Формирование новой базы и добавление новых...');
                                First;
                                InitProgress(0, RecordCount);
                                while not EoF and Process do
                                begin
                                  FillChar(NpRec, SizeOf(NpRec), #0);
                                  with NpRec do
                                  begin
                                    S := Trim(Fields.Fields[fiNnp].AsString);
                  
                                    StrTCopy(npName, PChar(S), SizeOf(npName));
                                    S := Fields.Fields[fiTnp].AsString;
                                    if Length(S)>0 then
                                      S := Tipnp(S[1]);
                                    StrTCopy(npType, PChar(S), SizeOf(npType));
                                  end;  
                                  Move(NpRec.npName, Key1, SizeOf(Key1));  


                                  Len := SizeOf(NpRec);
                                  Res := NpBase.GetEqual(NpRec, Len, Key1, 1);

                                  FillChar(BankRec, SizeOf(BankRec), #0);
                                  BankRec.brNpIder := -1;
                                  if Res=0 then
                                    BankRec.brNpIder := NpRec.npIder
                                  else
                                    if Res=4 then
                                    begin
                                      Inc(CntNp);
                                      NpRec.npIder := CntNp;
                                      Len := SizeOf(NpRec);  
                                      Res := NpBase.Insert(NpRec, Len, Key0, 0);
                                      if Res=0 then  
                                        BankRec.brNpIder := NpRec.npIder
                                      else  
                                        ShowProto(plError,  
                                          'Не удалось добавить город '+NpInfo(NpRec)
                                          +' BtrErr='+IntToStr(Res));
                                      WriteNpChanges(NpRec, 'N');
                                    end
                                    else
                                      ShowProto(plError, 'Ошибка поиска города '+NpInfo(NpRec)
                                        +' BtrErr='+IntToStr(Res));
                                  if BankRec.brNpIder>=0 then
                                  begin
                                    with BankRec do
                                    begin
                                      S := Trim(Fields.Fields[fiNamep].AsString);
                                      StrTCopy(brName, PChar(S), SizeOf(brName));

                                      {S := Trim(Fields.Fields[fiP].AsString);
                                      if S='+' then
                                        S := ''
                                      else begin
                                        S := Trim(Fields.Fields[fiPzn].AsString);
                                        S := Pzn(S);
                                      end;
                                      StrTCopy(brType, PChar(S), SizeOf(brType));}

                                      brCod := Fields.Fields[fiNewNum].AsInteger;
                                      S := Trim(Fields.Fields[fiKsNp].AsString);
                                      StrTCopy(brKs, PChar(S), SizeOf(brKs));
                                      Len := SizeOf(BankRec);
                                      Res := NewBank.Insert(BankRec, Len, Key0, 0);
                                      if Res<>0 then
                                        ShowProto(plError, 'Не удалось добавить новый банк '
                                          +BankInfo(BankRec)+' BtrErr='+IntToStr(Res));
                                      Key0 := BankRec.brCod;
                                      FillChar(OldBankRec, SizeOf(OldBankRec), #0);
                                      Len := SizeOf(OldBankRec);
                                      Res := OldBank.GetEqual(OldBankRec, Len, Key0, 0);
                                      if Res=4 then {Не найден - добавление}
                                      begin
                                        WriteBankChanges(BankRec, NpRec, 'A');
                                        AddBank(BankRec, NpRec);
                                      end
                                      else
                                        if Res=0 then {Найден - сравнение}
                                        begin
                                          if not CompareMem(@BankRec, @OldBankRec,
                                            SizeOf(BankRec)) then
                                          begin
                                            FillChar(OldNpRec, SizeOf(OldNpRec), #0);
                                            KeyN := OldBankRec.brNpIder;
                                            Len := SizeOf(OldNpRec);
                                            Res := NpBase.GetEqual(OldNpRec, Len, KeyN, 0);
                                            if Res<>0 then
                                              ShowProto(plWarning, 'Не найден город старого банка '
                                                +BankInfo(BankRec)+' BtrErr='+IntToStr(Res));
                                            WriteBankChanges(BankRec, NpRec, 'C');
                                            WriteBankChanges(OldBankRec, OldNpRec, 'O');
                                            AddBank(BankRec, NpRec);
                                          end;
                                        end
                                        else
                                          ShowProto(plError, 'Ошибка поиска старого банка '
                                            +BankInfo(BankRec)+' BtrErr='+IntToStr(Res));
                                    end;
                                  end;
                                  ProgressBar.Position := RecNo;
                                  Application.ProcessMessages;
                                  Next;
                                end;
                                ProgressBar.Hide;
                                Active := False;
                                if Process then
                                begin
                                  ShowStatus('Поиск и удаление неиспользуемых банков...');
                                  Len := SizeOf(OldBankRec);
                                  Res := OldBank.GetLast(OldBankRec, Len, Key0, 0);
                                  I := OldBankRec.brCod;
                                  Len := SizeOf(OldBankRec);
                                  Res := OldBank.GetFirst(OldBankRec, Len, Key0, 0);
                                  if Res=0 then
                                    InitProgress(OldBankRec.brCod, I);
                                  while (Res=0) and Process do
                                  begin
                                    Res := NewBank.GetEqualKey(Key0, 0);
                                    if Res=4 then {Не найден - удаление}
                                    begin
                                      FillChar(NpRec, SizeOf(NpRec), #0);
                                      KeyN := OldBankRec.brNpIder;
                                      Len := SizeOf(NpRec);
                                      Res := NpBase.GetEqual(NpRec, Len, KeyN, 0);
                                      if Res<>0 then
                                        ShowProto(plError, 'Ошибка поиска города 2 '
                                          +NpInfo(NpRec)+' BtrErr='+IntToStr(Res));
                                      WriteBankChanges(OldBankRec, NpRec, 'D');
                                      DelBank(OldBankRec);
                                    end
                                    else
                                      if Res<>0 then
                                        ShowProto(plError, 'Ошибка старого банка 2 '
                                              +BankInfo(OldBankRec)+' BtrErr='+IntToStr(Res));
                                    ProgressBar.Position := OldBankRec.brCod;
                                    Application.ProcessMessages;
                                    Len := SizeOf(OldBankRec);
                                    Res := OldBank.GetNext(OldBankRec, Len, Key0, 0);
                                  end;
                                  ProgressBar.Hide;
                                  if Process then
                                  begin
                                    ShowStatus('Поиск и удаление неиспользуемых городов...');
                                    Len := SizeOf(NpRec);
                                    Res := NpBase.GetFirst(NpRec, Len, Key0, 0);
                                    if Res=0 then
                                      InitProgress(NpRec.npIder, LastNp);
                                    while (Res=0) and Process do
                                    begin
                                      Res := NewBank.GetEqualKey(Key0, 1);
                                      if Res=4 then {Нет ссылок на этот нас.пункт}
                                      begin
                                        WriteNpChanges(NpRec, 'R');
                                        Res := NpBase.Delete(0);
                                        if Res<>0 then
                                          ShowProto(plError, 'Ошибка поиска города '+NpInfo(NpRec)
                                            +' BtrErr='+IntToStr(Res));
                                      end
                                      else
                                        if Res<>0 then
                                          ShowProto(plError, 'Ошибка поиска города 3 '+NpInfo(NpRec)
                                            +' BtrErr='+IntToStr(Res));
                                      ProgressBar.Position := NpRec.npIder;
                                      Application.ProcessMessages;
                                      Len := SizeOf(NpRec);
                                      Res := NpBase.GetNext(NpRec,Len,Key0,0);
                                    end;
                                    ProgressBar.Hide;
                                    if Process then
                                    begin
                                      ShowStatus('Формирование сообщений абонентам...');
                                      Len := SizeOf(AbonRec);
                                      Res := AbonDataSet.BtrBase.GetLast(AbonRec, Len, Key0, 0);
                                      I := AbonRec.abIder;
                                      Len := SizeOf(AbonRec);
                                      Res := AbonDataSet.BtrBase.GetFirst(AbonRec, Len, Key0, 0);
                                      if Res=0 then
                                        InitProgress(AbonRec.abIder, I);
                                      while (Res=0) and Process do
                                      begin
                                        if ((AbonRec.abLock and 1) = 0)
                                          or (((AbonRec.abLock and 2) = 0)) then
                                        begin
                                          Inc(CntO);
                                          AboCountLabel.Caption := IntToStr(CntO);
                                          with SprAboRec do
                                          begin
                                            saState := 0;
                                            saCorr := AbonRec.abIder;
                                            saIderR := FirstRec+1;
                                            while saIderR<=LastRec do
                                            begin
                                              Len := SizeOf(SprAboRec);
                                              Res := CorrAboDataSet.BtrBase.Insert(SprAboRec,
                                                Len, Key1, 0);
                                              if Res<>0 then
                                                ShowProto(plError, 'Ошибка добавления сообщения в CorrAbo '
                                                  +' Corr='+IntToStr(saCorr)+'  Id='+IntToStr(saIderR)
                                                  +' BtrErr='+IntToStr(Res));
                                              Inc(saIderR);
                                            end;
                                          end;
                                        end;
                                        ProgressBar.Position := AbonRec.abIder;
                                        Application.ProcessMessages;
                                        Len := SizeOf(AbonRec);
                                        Res := AbonDataSet.BtrBase.GetNext(AbonRec, Len, Key0, 0);
                                      end;
                                      ProgressBar.Hide;
                                    end;
                                  end;
                                end;
                                if not Process then
                                  ShowProto(plWarning, 'Обновление прервано');
                                ShowProto(plInfo,
                                  '+Б'+IntToStr(CntA)+' ~Б'+IntToStr(CntC)+' -Б'+IntToStr(CntD)
                                  +' +Г'+IntToStr(CntN)+' -Г'+IntToStr(CntR)
                                  +' ~А'+IntToStr(CntO));
                              end
                              else
                                ShowProto(plError, 'Не найдена последняя запись корректировки');
                            end
                            else
                              ShowProto(plError, 'Не найден последний индекс корректировки');
                          end
                          else
                            ShowProto(plError, 'Не найден последний город');
                          Res := NpBase.Close;
                          if Res<>0 then
                            ShowProto(plError, 'Не удалось закрыть базу '+NpBaseName);
                        end
                        else
                          ShowProto(plError, 'Не могу открыть базу '+NpBaseName);
                        NpBase.Free;
                        Res := OldBank.Close;
                        if Res<>0 then
                          ShowProto(plError, 'Не удалось закрыть старую базу '+OldBankName);
                      end
                      else  
                        ShowProto(plError, 'Не могу открыть старую базу '+OldBankName);  
                      OldBank.Free;
                      Res := NewBank.Close;
                      if Res<>0 then
                        ShowProto(plError, 'Не удалось закрыть новую базу '+NewBankName);  
                    end  
                    else  
                      ShowProto(plError, 'Не могу открыть пустую базу '+NewBankName);
                    NewBank.Free;
                  end
                  else
                    ShowProto(plWarning, 'Не могу скопировать пустую базу '+EmptyBankName
                      +' в '+NewBankName);
                end
                else
                  ShowProto(plWarning, 'Не могу скопировать старые города '+NpBaseName
                    +' в '+OldNpBaseName);
              end
              else
                ShowProto(plWarning, 'Не могу переименовать '+NewBankName+' в '+OldBankName);
            end
            else
              ShowProto(plWarning, 'Нет текущих: '+NewBankName+'|'+NpBaseName);
          end
          else
            ShowProto(plWarning, 'Один из индексов не найден в '+DbfName);
          Active := False;
        end
        else
          ShowProto(plWarning, 'Не удалось открыть '+DbfName);
      end;
    end;  
    ShowStatus('');
    Process := False;
    ProccessBtn.Caption := '&Начать...';
    CancelBtn.Enabled := True;
  end;
end;

procedure TBankSpravForm.FormResize(Sender: TObject);
begin
  FilenameEdit.Width := LeftPanel.Width - 2 * FilenameEdit.Left;
end;

procedure TBankSpravForm.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  Action := caFree;
end;

procedure TBankSpravForm.FormDestroy(Sender: TObject);
begin
  {PznNameList.Free;}
  TipNpList.Free;
end;

procedure TBankSpravForm.FormShow(Sender: TObject);
begin
  if not Process then
    ProccessBtn.Enabled := (Length(FilenameEdit.Text)>0) and (Length(VerSpinEdit.Text)>0);
end;

end.
