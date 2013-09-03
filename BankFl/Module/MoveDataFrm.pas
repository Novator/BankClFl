unit MoveDataFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Grids, Db, DBTables, DBGrids, ExtCtrls, DBCtrls, Menus,
  StdCtrls, Buttons, ComCtrls, Common, Basbn, Utilits,
  BtrDS, BankCnBn, Registr, CommCons, {Quorum, }Btrieve,
  ToolEdit, {Sign, }BUtilits, Mask, RxMemDS, Spin, CheckLst;

type
  TMoveDataForm = class(TForm)
    StatusBar: TStatusBar;
    SetupPanel: TPanel;
    BtnPanel: TPanel;
    CancelBtn: TBitBtn;
    ProccessBtn: TBitBtn;
    LeftPanel: TPanel;
    StatGroupBox: TGroupBox;
    AccLabel: TLabel;
    AccCountLabel: TLabel;
    DocCountLabel: TLabel;
    DocLabel: TLabel;
    Splitter1: TSplitter;
    ProtoGroupBox: TGroupBox;
    ProgressBar: TProgressBar;
    ProtoListBox: TListBox;
    TaskGroupBox: TGroupBox;
    DstLabel: TLabel;
    CorrGroupBox: TGroupBox;
    CorrCheckListBox: TCheckListBox;
    AllCorrCheckBox: TCheckBox;
    SelCorLabel: TLabel;
    OpLabel: TLabel;
    OpCountLabel: TLabel;
    AboCountLabel: TLabel;
    AboLabel: TLabel;
    DstDirectoryEdit: TDirectoryEdit;
    DelCheckBox: TCheckBox;
    PackLabel: TLabel;
    PackCountLabel: TLabel;
    CalcCheckBox: TCheckBox;
    ParamGroupBox: TGroupBox;
    AccDateLabel: TLabel;
    LastAccDateEdit: TDateEdit;
    Label1: TLabel;
    FirstDocDateEdit: TDateEdit;
    Label2: TLabel;
    MinDocSpinEdit: TSpinEdit;
    procedure FormCreate(Sender: TObject);
    procedure ProccessBtnClick(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure AllCorrCheckBoxClick(Sender: TObject);
    procedure DebitNameBtnMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure DebitNameBtnMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure Splitter1CanResize(Sender: TObject; var NewSize: Integer;
      var Accept: Boolean);
    procedure CorrCheckListBoxClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure CalcCheckBoxClick(Sender: TObject);
  private
  protected
  public
    procedure InitProgress(Min, Max: Integer);
    procedure ShowProto(Level: Byte; S: string);
    procedure ShowStatus(S: string);
  end;

const
  MoveDataForm: TMoveDataForm = nil;
var
  CurrDate: TDate = 0;

implementation


{$R *.DFM}

procedure TMoveDataForm.ShowProto(Level: Byte; S: string);
begin
  ProtoListBox.Items.Add(LevelToStr(Level)+': '+S);
  ProtoMes(Level, 'FileSnd', S);
end;

procedure TMoveDataForm.ShowStatus(S: string);
begin
  StatusBar.Panels[1].Text := S;
  Application.ProcessMessages;
end;

var
  Process: Boolean = False;
  FileBitSize: Integer = 15000;
  SendFileDataSet, CorrDataSet, AccDataSet, AccArcDataSet, DocDataSet,
    BillDataSet: TExtBtrDataSet;
  CorrList: TList = nil;
  AccList: TAccList = nil;

procedure TMoveDataForm.FormCreate(Sender: TObject);
const
  Border=2;
var
  LowDate: Integer;
begin
  CorrList := TList.Create;
  AccList := TAccList.Create;
  SendFileDataSet := GlobalBase(biSendFile) as TBtrDataSet;
  CorrDataSet := {GlobalBase(biCorr) as TBtrDataSet}nil;
  AccDataSet := GlobalBase(biAcc) as TBtrDataSet;
  AccArcDataSet := GlobalBase(biAccArc) as TBtrDataSet;
  DocDataSet := GlobalBase(biPay) as TBtrDataSet;
  BillDataSet := GlobalBase(biBill) as TBtrDataSet;
  with ProgressBar do
  begin
    Parent := StatusBar;
    SetBounds(0, Border, Width, StatusBar.Height - Border);
    StatusBar.Panels[0].Width := Width;
  end;
  FillCorrList(CorrCheckListBox.Items);
  if not GetRegParamByName('FileBitSize', GetUserNumber, FileBitSize) then
    FileBitSize := 15000;
  if not GetRegParamByName('OldDayLimit', GetUserNumber, LowDate) then
    LowDate := 10;
  FirstDocDateEdit.Date := Date - LowDate;
  LastAccDateEdit.Date := FirstDocDateEdit.Date;
end;

procedure TMoveDataForm.InitProgress(Min, Max: Integer);
begin
  ProgressBar.Min := -10000000;
  ProgressBar.Position := ProgressBar.Min;
  ProgressBar.Max := Min;
  ProgressBar.Min := Min;
  ProgressBar.Position := ProgressBar.Min;
  ProgressBar.Max := Max;
  ProgressBar.Show;
end;

function CorrRecCompare(Key1, Key2: Pointer): Integer;
begin
  if Integer(Key1)<Integer(Key2) then
    Result := -1
  else
  if Integer(Key1)>Integer(Key2) then
    Result := 1
  else
    Result :=0
end;

procedure TMoveDataForm.ProccessBtnClick(Sender: TObject);
const
  MesTitle: PChar = 'Генерация обновлений';
const
  MaxHistoryDateCount = 10;
var
  HistoryDates: array[0..MaxHistoryDateCount-1] of Word;
  CurDateIndex, HistoryDateCount: Integer;

  procedure ResetDateHistory;
  begin
    CurDateIndex := 0;
    HistoryDateCount := 0;
  end;

  function AddHistoryDate(ADate: Word): Boolean;
  var
    I: Integer;
    SD: Double;
  begin
    Result := False;
    if ADate>0 then
    begin
      if HistoryDateCount<MaxHistoryDateCount then
        Inc(HistoryDateCount);
      Inc(CurDateIndex);
      if CurDateIndex>=MaxHistoryDateCount then
        CurDateIndex := 0;
      HistoryDates[CurDateIndex] := ADate;
      Result := True;
    end;
  end;

  function MidleHistoryDate: Word;
  var
    I: Integer;
    SD: Double;
  begin
    Result := 0;
    if HistoryDateCount>0 then
    begin
      SD := 0;
      for I := 0 to HistoryDateCount-1 do
        SD := SD + BtrDateToDate(HistoryDates[I]);
      Result := DateToBtrDate(SD/HistoryDateCount);
    end;
  end;

var
  Res, Len, Key0, I, K, J, C1, C2: Integer;
  {CorrRec: TCorrRec;
  CorrBase2, AccBase2, AccArcBase2, DocBase2, BillBase2, PostBase1, PostBase2: TBtrBase;
  AccRec: TAccRec;
  AccColPtr: PAccColRec;
  PayRec: TBankPayRec;
  OpRec: TOpRec;
  SndPack: TSndPack;
  MoveMode: Integer;
  FirstDocDate, LastAccDate: Word;
  OldCapt: string;
  CorrName: array[0..SizeOf(TCorrName)] of Char;
  DstPath, SrcPath: string;
  FN: string;}
begin
  (*
  if Process then
    Process := False
  else begin
    Process := True;
    if CalcCheckBox.Checked then
      MoveMode := 0
    else begin
      if DelCheckBox.Checked then
        MoveMode := 2
      else
        MoveMode := 1
    end;
    OldCapt := (Sender as TBitBtn).Caption;
    (Sender as TBitBtn).Caption := '&Прервать';
    ProccessBtn.Enabled := False;
    AboCountLabel.Caption := '0';
    AccCountLabel.Caption := '0';
    OpCountLabel.Caption := '0';
    DocCountLabel.Caption := '0';
    CancelBtn.Enabled := False;
    ShowStatus('');
    DstPath := DstDirectoryEdit.Text;
    FirstDocDate := DateToBtrDate(FirstDocDateEdit.Date);
    LastAccDate := DateToBtrDate(LastAccDateEdit.Date);;
    if Length(DstPath)>0 then
    begin
      ShowStatus('Открытие баз '+DstPath+'...');
      if DstPath[Length(DstPath)]<>'\' then
        DstPath := DstPath+'\';
      SrcPath := UserBaseDir;
      CorrBase2 := TBtrBase.Create;
      AccBase2 := TBtrBase.Create;
      AccArcBase2 := TBtrBase.Create;
      DocBase2 := TBtrBase.Create;
      BillBase2 := TBtrBase.Create;
      PostBase1 := TBtrBase.Create;
      PostBase2 := TBtrBase.Create;
      FN := DstPath+GetBaseName(biCorr);
      Res := CorrBase2.Open(FN, baNormal);
      if Res=0 then
      begin
        FN := DstPath+GetBaseName(biAcc);
        Res := AccBase2.Open(FN, baNormal);
        if Res=0 then
        begin
          FN := DstPath+GetBaseName(biAccArc);
          Res := AccArcBase2.Open(FN, baNormal);
          if Res=0 then
          begin
            FN := DstPath+GetBaseName(biPay);
            Res := DocBase2.Open(FN, baNormal);
            if Res=0 then
            begin
              FN := DstPath+GetBaseName(biBill);
              Res := BillBase2.Open(FN, baNormal);
              if Res=0 then
              begin
                FN := SrcPath+'doc_s.btr';
                Res := PostBase1.Open(FN, baNormal);
                if Res=0 then
                begin
                  FN := DstPath+'doc_s.btr';
                  Res := PostBase2.Open(FN, baNormal);
                  if Res=0 then
                  begin
                    C1 := 0;
                    C2 := 0;
                    CorrList.Clear;
                    AccList.Clear;
                    if MoveMode>0 then
                      ShowStatus('Перенос абонентов...')
                    else
                      ShowStatus('Поиск абонентов...');
                    I := 0;
                    with CorrCheckListBox do
                    begin
                      while (I<Items.Count) and Process do
                      begin
                        if Checked[I] then
                        begin
                          K := Integer(Items.Objects[I]);
                          Len := SizeOf(CorrRec);
                          Res := CorrDataSet.BtrBase.GetEqual(CorrRec, Len, K, 0);
                          if Res=0 then
                          begin
                            if MoveMode=0 then
                              CorrList.Add(TObject(K))
                            else begin
                              Res := CorrBase2.Insert(CorrRec, Len, K, 0);
                              if Res<>0 then
                                ShowProto(plWarning, 'Не удалось добавить нового абонента '
                                  +Items.Strings[I]+' BtrErr='+IntToStr(Res));
                              if (Res=0) or (Res=5) then
                              begin
                                CorrList.Add(TObject(K));
                                if MoveMode=2 then
                                begin
                                  Res := CorrDataSet.BtrBase.Delete(0);
                                  if Res<>0 then
                                    ShowProto(plWarning, 'Не удалось убрать старого абонента '
                                      +Items.Strings[I]+' BtrErr='+IntToStr(Res));
                                end;
                              end;
                            end;
                            Inc(C1);
                            AboCountLabel.Caption := IntToStr(C1);
                          end;
                        end;
                        Inc(I);
                        Application.ProcessMessages;
                      end;
                    end;
                    ShowProto(plInfo, 'Всего абонентов: '+IntToStr(C1));
                    if MoveMode>0 then
                      ShowStatus('Перенос счетов...')
                    else
                      ShowStatus('Поиск счетов...');
                    I := 0;
                    while (I<CorrList.Count) and Process do
                    begin
                      J := Integer(CorrList.Items[I]);
                      K := J;
                      Len := SizeOf(AccRec);
                      Res := AccDataSet.BtrBase.GetEqual(AccRec, Len, K, 2);
                      while (Res=0) and (K=J) and Process do
                      begin
                        if (AccRec.arDateC=0) or (AccRec.arDateC>=LastAccDate) then
                        begin
                          if MoveMode>0 then
                          begin
                            Res := AccBase2.Insert(AccRec, Len, K, 2);
                            if Res<>0 then
                              ShowProto(plWarning, 'Не удалось добавить новый счет '
                                +Copy(AccRec.arAccount,1,SizeOf(TAccount))
                                +' BtrErr='+IntToStr(Res));
                            if (Res=0) or (Res=5) then
                            begin
                              New(AccColPtr);
                              with AccColPtr^ do
                              begin
                                acIder := AccRec.arIder;
                                acNumber := AccRec.arAccount;
                              end;
                              AccList.Add(AccColPtr);
                              if MoveMode>1 then
                              begin
                                Res := AccDataSet.BtrBase.Delete(2);
                                if Res<>0 then
                                  ShowProto(plWarning, 'Не удалось убрать старый счет '
                                    +Copy(AccRec.arAccount,1,SizeOf(TAccount))
                                    +' BtrErr='+IntToStr(Res));

                              end;
                            end;
                          end;
                          Inc(C2);
                          AccCountLabel.Caption := IntToStr(C2);
                          Application.ProcessMessages;
                        end;
                        Len := SizeOf(AccRec);
                        Res := AccDataSet.BtrBase.GetNext(AccRec, Len, K, 2);
                      end;
                      Inc(I);
                      Application.ProcessMessages;
                    end;
                    ShowProto(plInfo, 'Всего счетов: '+IntToStr(C2));
                    if (MoveMode>0) and Process then
                    begin
                      ShowStatus('Сортировка коллекции счетов...');
                      CorrList.Sort(@CorrRecCompare);
                      AccList.Sort(@AccColRecCompare);
                      C1 := 0;
                      C2 := 0;
                      ShowStatus('Перенос операций и документов...');
                      Len := SizeOf(OpRec);
                      Res := BillDataSet.BtrBase.GetLast(OpRec, Len, K, 0);
                      I := OpRec.brIder;
                      Len := SizeOf(OpRec);
                      Res := BillDataSet.BtrBase.GetFirst(OpRec, Len, K, 0);
                      if Res=0 then
                        InitProgress(OpRec.brIder, I);
                      while (Res=0) and Process do
                      begin
                        case OpRec.brPrizn of
                          brtBill:
                            begin
                              J := AccList.SearchAcc(OpRec.brAccD);
                              if J<0 then
                                J := AccList.SearchAcc(OpRec.brAccC);
                            end;
                          brtReturn, brtKart:
                            begin
                              J := OpRec.brDocId;
                              Len := SizeOf(PayRec);
                              Res := DocDataSet.BtrBase.GetEqual(PayRec, Len, J, 0);
                              J := -1;
                              if PayRec.dbIdSender>0 then
                              begin
                                if CorrList.IndexOf(Pointer(PayRec.dbIdSender))>=0 then
                                  J := 1;
                              end;
                              (*J := 1; {Дальше будет проверка}?
                            end;
                          else
                            J := -1;
                        end;
                        if J>=0 then
                        begin
                          J := OpRec.brIder;
                          Res := BillBase2.Insert(OpRec, Len, J, 0);
                          if Res=0 then
                          begin
                            Inc(C1);
                            OpCountLabel.Caption := IntToStr(C1);
                            if MoveMode>1 then
                            begin
                              Res := BillDataSet.BtrBase.Delete(0);
                              if Res<>0 then
                                ShowProto(plWarning, 'Не удалось убрать старую операцию '
                                  +OpInfo(OpRec)+' BtrErr='+IntToStr(Res));
                            end;
                          end
                          else
                            ShowProto(plWarning, 'Не удалось добавить новую операцию '
                              +OpInfo(OpRec)+' BtrErr='+IntToStr(Res));
                          if OpRec.brDel=0 then
                          begin
                            J := OpRec.brDocId;
                            Len := SizeOf(PayRec);
                            Res := DocDataSet.BtrBase.GetEqual(PayRec, Len, J, 0);
                            if (Res=0) {and ((OpRec.brPrizn=brtBill)
                              or (CorrList.IndexOf(Pointer(PayRec.dbIdSender))>=0))} then
                            begin
                              J := PayRec.dbIdHere;
                              Res := DocBase2.Insert(PayRec, Len, J, 0);
                              if Res=0 then
                              begin
                                Inc(C2);
                                DocCountLabel.Caption := IntToStr(C2);
                                if MoveMode>1 then
                                begin
                                  Res := DocDataSet.BtrBase.Delete(0);
                                  if Res<>0 then
                                    ShowProto(plWarning, 'Не удалось убрать старый документ '
                                      +DocInfo(PayRec)+' BtrErr='+IntToStr(Res));
                                end;
                              end
                              else
                                ShowProto(plWarning, 'Не удалось добавить новый документ '
                                  +DocInfo(PayRec)+' BtrErr='+IntToStr(Res));
                            end;
                          end;
                        end;
                        ProgressBar.Position := OpRec.brIder;
                        Application.ProcessMessages;
                        Len := SizeOf(OpRec);
                        Res := BillDataSet.BtrBase.GetNext(OpRec, Len, K, 0);
                      end;
                      ProgressBar.Hide;
                      ShowProto(plInfo, 'Всего операций: '+IntToStr(C1));
                      ShowStatus('Перенос последних входящих...');
                      J := MinDocSpinEdit.Value;
                      ResetDateHistory;
                      Len := SizeOf(PayRec);
                      Res := DocDataSet.BtrBase.GetLast(PayRec, Len, K, 0);
                      while (Res=0) and Process and ((J>0)
                        or (MidleHistoryDate>=FirstDocDate)) do
                      begin
                        if PayRec.dbIdSender>0 then
                        begin
                          if J>0 then
                            Dec(J);
                          I := CorrList.IndexOf(Pointer(PayRec.dbIdSender));
                          if I>=0 then
                          begin
                            Res := DocBase2.Insert(PayRec, Len, K, 0);
                            if Res=0 then
                            begin
                              Inc(C2);
                              DocCountLabel.Caption := IntToStr(C2);
                              if MoveMode>1 then
                              begin
                                Res := DocDataSet.BtrBase.Delete(0);
                                if Res<>0 then
                                  ShowProto(plWarning, 'Не удалось убрать old документ '
                                    +DocInfo(PayRec)+' BtrErr='+IntToStr(Res));
                              end;
                            end;
                          end;
                          if PayRec.dbDateR>0 then
                            AddHistoryDate(PayRec.dbDateR)
                          else
                            AddHistoryDate(PayRec.dbDoc.drDate);
                        end;
                        Application.ProcessMessages;
                        Len := SizeOf(PayRec);
                        Res := DocDataSet.BtrBase.GetPrev(PayRec, Len, K, 0);
                      end;
                      ShowProto(plInfo, 'Всего документов: '+IntToStr(C2));
                      C1 := 0;
                      ShowStatus('Перенос отправленных пакетов...');
                      I := 0;
                      while (I<CorrList.Count) and Process do
                      begin
                        K := Integer(CorrList.Items[I]);
                        Len := SizeOf(CorrRec);
                        Res := CorrBase2.GetEqual(CorrRec, Len, K, 0);
                        if Res=0 then
                        begin
                          FillChar(CorrName, SizeOf(CorrName), #0);
                          StrLCopy(CorrName, CorrRec.crName, SizeOf(CorrName)-1);
                          Len := SizeOf(SndPack);
                          Res := PostBase1.GetEqual(SndPack, Len, CorrName, 0);
                          while ((Res=0) or (Res=22)) and Process
                            and (StrLComp(CorrName, CorrRec.crName, SizeOf(CorrName)-1)=0) do
                          begin
                            if (Res=0) and (SndPack.spByteS=PackByteSC) and
                              (SndPack.spFlSnd='2') then
                            begin
                              Res := PostBase2.Insert(SndPack, Len, CorrName, 0);
                              if Res=0 then
                              begin
                                Inc(C1);
                                PackCountLabel.Caption := IntToStr(C1);
                                if MoveMode>1 then
                                begin
                                  Res := PostBase1.Delete(0);
                                  if Res<>0 then
                                    ShowProto(plWarning, 'Не удалось убрать старый пакет '
                                      +CorrName+' Id='+IntToStr(SndPack.spIder)
                                      +' BtrErr='+IntToStr(Res));
                                end;
                              end
                              else
                                ShowProto(plWarning, 'Не удалось добавить новый пакет '
                                  +CorrName+' Id='+IntToStr(SndPack.spIder)
                                  +' BtrErr='+IntToStr(Res));
                            end;
                            Len := SizeOf(SndPack);
                            Res := PostBase1.GetNext(SndPack, Len, CorrName, 0);
                            Application.ProcessMessages;
                          end;
                        end
                        else
                          ShowProto(plWarning, 'Новый корреспондент не найден '
                            +CorrName+' BtrErr='+IntToStr(Res));
                        Inc(I);
                        Application.ProcessMessages;
                      end;
                    end;
                    if not Process then
                       ShowProto(plInfo, 'Процесс прерван');
                    Res := PostBase2.Close;
                  end
                  else
                    ShowProto(plWarning, 'Не удалось открыть базу new doc_s '+FN);
                  Res := PostBase1.Close;
                end
                else
                  ShowProto(plWarning, 'Не удалось открыть базу old doc_s '+FN);
                Res := BillBase2.Close;
              end
              else
                ShowProto(plWarning, 'Не удалось открыть базу new Bill '+FN);
              Res := DocBase2.Close;
            end
            else
              ShowProto(plWarning, 'Не удалось открыть базу new Doc '+FN);
            Res := AccArcBase2.Close;
          end
          else
            ShowProto(plWarning, 'Не удалось открыть базу new AccArc '+FN);
          Res := AccBase2.Close;
        end
        else
          ShowProto(plWarning, 'Не удалось открыть базу new Acc '+FN);
        Res := CorrBase2.Close;
      end
      else
        ShowProto(plWarning, 'Не удалось открыть базу new Corr '+FN);
      CorrBase2.Free;
      AccBase2.Free;
      AccArcBase2.Free;
      DocBase2.Free;
      BillBase2.Free;
      PostBase1.Free;
      PostBase2.Free;
    end;
    ShowStatus('');
    Process := False;
    (Sender as TBitBtn).Caption := OldCapt;
    CancelBtn.Enabled := True;
    ProccessBtn.Enabled := True;
  end;
  *)
end;

procedure TMoveDataForm.FormResize(Sender: TObject);
begin
  DstDirectoryEdit.Width := TaskGroupBox.ClientWidth - 2 * DstDirectoryEdit.Left;
end;

procedure TMoveDataForm.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  Action := caFree;
end;

procedure TMoveDataForm.FormShow(Sender: TObject);
var
  B: Boolean;
  I, C: Integer;
begin
  if not Process then
  begin
    B := (Length(DstDirectoryEdit.Text)>0) and (CalcCheckBox.State<>cbGrayed);
    if B and not AllCorrCheckBox.Checked then
    begin
      with CorrCheckListBox do
      begin
        I := 0;
        C := Items.Count;
        while (I<C) and not CorrCheckListBox.Checked[I] do
          Inc(I);
        B := I<C;
      end;
    end;
    ProccessBtn.Enabled := B;
  end;
end;

procedure TMoveDataForm.CorrCheckListBoxClick(Sender: TObject);
var
  I, C: Integer;
begin
  if Sender<>nil then
    FormShow(Sender);
  C := 0;
  with CorrCheckListBox do
    for I := 0 to Items.Count-1 do
      if CorrCheckListBox.Checked[I] then
        Inc(C);
  SelCorLabel.Caption := 'Веделено: '+IntToStr(C);
  SelCorLabel.Visible := C>0;
end;

procedure TMoveDataForm.AllCorrCheckBoxClick(Sender: TObject);
var
  I: Integer;
begin
  CorrCheckListBox.Enabled := not AllCorrCheckBox.Checked;
  CorrCheckListBox.ParentColor := AllCorrCheckBox.Checked;
  if not CorrCheckListBox.ParentColor then
    CorrCheckListBox.Color := clWindow;
  if AllCorrCheckBox.Checked then
    for I := 0 to CorrCheckListBox.Items.Count-1 do
      CorrCheckListBox.Checked[I] := True;
  CorrCheckListBoxClick(Sender);
end;

procedure TMoveDataForm.DebitNameBtnMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbLeft then (Sender as TPanel).BevelOuter := bvLowered;
end;

procedure TMoveDataForm.DebitNameBtnMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  with (Sender as TPanel) do
    if BevelOuter = bvLowered then BevelOuter := bvRaised;
end;


procedure TMoveDataForm.Splitter1CanResize(Sender: TObject;
  var NewSize: Integer; var Accept: Boolean);
begin
  if NewSize<15 then
    NewSize := 15;
end;


procedure TMoveDataForm.FormDestroy(Sender: TObject);
begin
  CorrList.Free;
  AccList.Free;
  MoveDataForm := nil;
end;

procedure TMoveDataForm.CalcCheckBoxClick(Sender: TObject);
begin
  DelCheckBox.Enabled := not CalcCheckBox.Checked;
  FormShow(Sender);
end;

end.
