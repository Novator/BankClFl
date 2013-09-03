unit DelOldAccFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Controls, StdCtrls, Buttons,
    ExtCtrls, ComCtrls, Forms, Graphics, Db, Btrieve, Utilits, CommCons, ClntCons,
  Mask, ToolEdit;

type
  TDelOldAccForm = class(TForm)
    TopBevel: TBevel;
    TopPanel: TPanel;
    TitleLabel: TLabel;
    UrlLabel: TLabel;
    MesLabel: TLabel;
    TaskGroupBox: TGroupBox;
    TaskListBox: TListBox;
    ProgressBar: TProgressBar;
    DateEdit: TDateEdit;
    DateLabel: TLabel;
    CloseBitBtn: TBitBtn;
    OkBitBtn: TBitBtn;
    procedure TaskListBoxDrawItem(Control: TWinControl; Index: Integer;
      Rect: TRect; State: TOwnerDrawState);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure OkBitBtnClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure CloseBitBtnClick(Sender: TObject);
  private
    AccList: TStringList;
  public
    procedure ShowMes(S: string);
    procedure AddStep(S: string);
    procedure SetCurStep(I: Integer);
    function ActiveDoc(var d: TPayRec): Boolean;
  end;

var
  DelOldAccForm: TDelOldAccForm;
  Step: Byte = 0;

implementation

{$R *.DFM}

var
  Process: Boolean = False;

procedure TDelOldAccForm.TaskListBoxDrawItem(Control: TWinControl;
  Index: Integer; Rect: TRect; State: TOwnerDrawState);
var
  S: TFontStyles;
begin
  with (Control as TListBox).Canvas do
  begin
    Brush.Color := (Control as TListBox).Color;
    FillRect(Rect);
    S := Font.Style;
    if Process and (Index=(Control as TListBox).ItemIndex) then
      Include(S, fsBold)
    else
      Exclude(S, fsBold);
    Font.Color := clBlack;
    Font.Style := S;
    TextOut(Rect.Left + 17, Rect.Top, (Control as TListBox).Items[Index]);
    Exclude(S, fsBold);
    Font.Style := S;
  end;
end;

procedure TDelOldAccForm.FormCloseQuery(Sender: TObject;
  var CanClose: Boolean);
begin
  CanClose := not Process;
  if Process then
  begin
    if MessageBox(Handle,
      'Завершение обновления приведет к неправильной работе программы. Прервать?',
      PChar(Caption), MB_YESNOCANCEL or MB_ICONWARNING or MB_DEFBUTTON2) = ID_YES
    then
      Process := False;
  end;
end;

function ProtoFileName: string;
begin
  Result := ChangeFileExt(Application.ExeName, '.prt');
end;

const
  ProtoIsOpen: Boolean = False;
var
  ProtoFile: TextFile;

procedure ShowProto(S: string);
begin
  if not ProtoIsOpen then
  begin
    AssignFile(ProtoFile, ProtoFileName);
    {$I-} System.Append(ProtoFile); {$I+}
    ProtoIsOpen := IOResult = 0;
    if not ProtoIsOpen then
    begin
      {$I-} Rewrite(ProtoFile); {$I+}
      ProtoIsOpen := IOResult = 0;
    end;
  end;
  if ProtoIsOpen then
    WriteLn(ProtoFile, DateTimeToStr(Now)+' '+S);
end;

procedure TDelOldAccForm.ShowMes(S: string);
begin
  MesLabel.Caption := S;
  ShowProto(S);
end;

procedure TDelOldAccForm.AddStep(S: string);
begin
  TaskListBox.Items.Add(S);
end;

procedure TDelOldAccForm.SetCurStep(I: Integer);
begin
  if (I<TaskListBox.Items.Count) and (I<>TaskListBox.ItemIndex) then
    TaskListBox.ItemIndex := I;
  TaskListBox.Repaint;
  Application.ProcessMessages;
end;

function OpenBase(var Reg: TBtrBase; S: string): Boolean;
var
  Res: Integer;
begin
  Result := Reg<>nil;
  if not Result then
  begin
    Reg := TBtrBase.Create;
    with Reg do
    begin
      Res := Open(S, baNormal);
      Result := Res=0;
      if Res<>0 then
        ShowProto('OpenReg: ['+S+'] BtrErr='+IntToStr(Res));
    end;
  end;
end;

procedure CloseBase(var Reg: TBtrBase);
begin
  if Reg<>nil then
  begin
    Reg.Close;
    Reg.Free;
    Reg := nil;
  end;
end;

const
  NumOfBase = 4;
  BaseNames: array[1..NumOfBase] of string = ('acc.btr', 'accarc.btr',
    'bill.btr', 'doc.btr');
  AccBi    = 1;
  AccArcBi = 2;
  BillBi   = 3;
  DocBi    = 4;

var
  T: array[0..1023] of Char;

function TDelOldAccForm.ActiveDoc(var d: TPayRec): Boolean;
var
  I, Offset, Len: Integer;
  DebAcc, CredAcc: string;
begin
  Result := False;
  with d.dbDoc do
  begin
    Offset := 0;
    for I := 1 to 8 do
    begin
      Len := StrLen(@drVar[Offset]);
      StrLCopy(T, @drVar[Offset], SizeOf(T));
      case I of
        2: DebAcc := Trim(StrPas(@T));
        8: CredAcc := Trim(StrPas(@T));
      end;
      Offset := Offset + Len + 1;
    end;
  end;
  if (AccList.IndexOf(DebAcc)>=0)
    or (AccList.IndexOf(CredAcc)>=0)
  then
    Result := True;
end;

procedure TDelOldAccForm.OkBitBtnClick(Sender: TObject);
var
  Err: Boolean;
  I, J, Res, Len, Len1: Integer;
  S1, S2, S: string;
  BtrBase1, BtrBase2, BtrBase3, BtrBase4: TBtrBase;
  AccRec: TAccRec;
  AccArcRec: TAccArcRec;
  OpRec: TOpRec;
  d: TPayRec;
  BeginDate: Word;
begin
  BtrBase1 := nil;
  BtrBase2 := nil;
  BtrBase3 := nil;
  BtrBase4 := nil;
  if Step=0 then
  begin
    Process := True;
    OkBitBtn.Hide;
    DateEdit.Enabled := False;
    CloseBitBtn.Hide;
    OkBitBtn.Caption := 'OK';
    Err := False;
    ShowProto('===Очистка баз===');
    ShowMes('Подождите, идет процесс...');
    while (Step<TaskListBox.Items.Count) and not Err and Process do
    begin
      SetCurStep(Step);
      Inc(Step);
      case Step of
        1:
          begin
            try
              ProgressBar.Min := 0;
              ProgressBar.Position := ProgressBar.Min;
              ProgressBar.Max := NumOfBase;
            except
            end;
            ProgressBar.Show;
            I := 1;
            while (I<=NumOfBase) and Process and not Err do
            begin
              S1 := 'Base\'+BaseNames[I];
              S2 := ChangeFileExt(S1, '.old');
              ShowProto('Ren: '+S1+'>'+S2);
              Err := not RenameFile(PChar(S1), PChar(S2));
              ProgressBar.Position := I;
              Application.ProcessMessages;
              Inc(I);
            end;
          end;
        2:
          begin
            try
              ProgressBar.Min := 0;
              ProgressBar.Position := ProgressBar.Min;
              ProgressBar.Max := NumOfBase;
            except
            end;
            ProgressBar.Show;
            I := 1;
            while (I<=NumOfBase) and Process and not Err do
            begin
              S1 := 'Base\'+BaseNames[I];
              S2 := ChangeFileExt(S1, '.emp');
              ShowProto('Copy: '+S2+'>'+S1);
              Err := not CopyFile(PChar(S2), PChar(S1), True);
              ProgressBar.Position := I;
              Application.ProcessMessages;
              Inc(I);
            end;
          end;
        3:
          begin
            AccList.Clear;
            S1 := 'Base\'+BaseNames[AccBi];
            ShowProto('Open: '+S1);
            if OpenBase(BtrBase1, S1) then
            begin
              S2 := ChangeFileExt(S1, '.old');
              ShowProto('Open: '+S2);
              if OpenBase(BtrBase2, S2) then
              begin
                try
                  ProgressBar.Min := 0;
                  ProgressBar.Position := ProgressBar.Min;
                except
                end;
                Len := SizeOf(AccRec);
                Res := BtrBase2.GetLast(AccRec, Len, J, 0);
                Len := SizeOf(AccRec);
                Res := BtrBase2.GetFirst(AccRec, Len, I, 0);
                try
                  ProgressBar.Max := I+1;
                  ProgressBar.Position := I+1;
                  ProgressBar.Min := I;
                  ProgressBar.Position := I;
                  ProgressBar.Max := J;
                except
                end;
                BeginDate := DateToBtrDate(DateEdit.Date);
                ProgressBar.Show;
                while (Res=0) and Process and not Err do
                begin
                  if (AccRec.arDateC=0) or (AccRec.arDateC>=BeginDate) then
                  begin
                    S := AccRec.arAccount;
                    S := Copy(S, 1, 20);
                    ShowProto('AddAcc: ['+S+']');
                    AccList.AddObject(S, TObject(AccRec.arIder));
                    Res := BtrBase1.Insert(AccRec, Len, I, 0);
                    Err := Res<>0;
                  end;
                  Len := SizeOf(AccRec);
                  Res := BtrBase2.GetNext(AccRec, Len, I, 0);
                  ProgressBar.Position := I;
                  Application.ProcessMessages;
                end;
                CloseBase(BtrBase2);
              end
              else
                Err := True;
              CloseBase(BtrBase1);
            end
            else
              Err := True;
          end;
        4:
          begin
            S1 := 'Base\'+BaseNames[BillBi];
            ShowProto('Open: '+S1);
            if OpenBase(BtrBase1, S1) then
            begin
              S2 := ChangeFileExt(S1, '.old');
              ShowProto('Open: '+S2);
              if OpenBase(BtrBase2, S2) then
              begin
                S1 := 'Base\'+BaseNames[DocBi];
                ShowProto('Open: '+S1);
                if OpenBase(BtrBase3, S1) then
                begin
                  S2 := ChangeFileExt(S1, '.old');
                  ShowProto('Open: '+S2);
                  if OpenBase(BtrBase4, S2) then
                  begin
                    ShowMes('Перенос проведенных документов...');
                    try
                      ProgressBar.Min := 0;
                      ProgressBar.Position := ProgressBar.Min;
                    except
                    end;
                    Len := SizeOf(OpRec);
                    Res := BtrBase2.GetLast(OpRec, Len, J, 0);
                    Len := SizeOf(OpRec);
                    Res := BtrBase2.GetFirst(OpRec, Len, I, 0);
                    try
                      ProgressBar.Max := I+1;
                      ProgressBar.Min := I;
                      ProgressBar.Position := I;
                      ProgressBar.Max := J;
                    except
                    end;
                    ProgressBar.Show;
                    while (Res=0) and Process and not Err do
                    begin
                      if (OpRec.brPrizn=brtReturn) or (OpRec.brPrizn=brtBill)
                        and ((AccList.IndexOf(OpRec.brAccD)>=0)
                          or (AccList.IndexOf(OpRec.brAccC)>=0)) then
                      begin
                        Res := BtrBase1.Insert(OpRec, Len, I, 0);
                        if (Res<>0) and (Res<>5) then
                        begin
                          ShowProto('InsertBill: Id='+IntToStr(OpRec.brIder)
                            +' BtrErr='+IntToStr(Res));
                          Err := True;
                        end
                        else begin
                          J := OpRec.brDocId;
                          Len1 := SizeOf(d);
                          Res := BtrBase4.GetEqual(d, Len1, J, 1);
                          if Res=0 then
                          begin
                            if (OpRec.brPrizn<>brtReturn)
                              or ActiveDoc(d) then
                            begin
                              Res := BtrBase3.Insert(d, Len1, J, 1);
                              if (Res<>0) and (Res<>5) then
                              begin
                                ShowProto('InsertDoc: Id='+IntToStr(d.dbIdHere)
                                  +' BtrErr='+IntToStr(Res));
                                Err := True;
                              end;
                            end;
                          end;
                        end;
                      end;
                      Len := SizeOf(OpRec);
                      Res := BtrBase2.GetNext(OpRec, Len, I, 0);
                      ProgressBar.Position := I;
                      Application.ProcessMessages;
                    end;
                    ShowMes('Перенос исходящих документов без проводок...');
                    Len := SizeOf(d);
                    Res := BtrBase4.GetFirst(d, Len, J, 3);
                    while (Res=0) and Process and not Err do
                    begin
                      J := d.dbIdKorr;
                      Len1 := SizeOf(OpRec);
                      Res := BtrBase2.GetEqual(OpRec, Len1, J, 1);
                      if (Res<>0) and (((d.dbState and 3)>0) or ActiveDoc(d)) then
                      begin
                        Res := BtrBase3.Insert(d, Len, J, 3);
                        if (Res<>0) and (Res<>5) then
                        begin
                          ShowProto('InsertOutDoc: Id='+IntToStr(d.dbIdHere)
                            +' BtrErr='+IntToStr(Res));
                          Err := True;
                        end;
                      end;
                      Len := SizeOf(d);
                      Res := BtrBase4.GetNext(d, Len, J, 3);
                      Application.ProcessMessages;
                    end;
                    CloseBase(BtrBase4);
                  end
                  else
                    Err := True;
                  CloseBase(BtrBase3);
                end
                else
                  Err := True;
                CloseBase(BtrBase2);
              end
              else
                Err := True;
              CloseBase(BtrBase1);
            end
            else
              Err := True;
          end;
        5:
          begin
            S1 := 'Base\'+BaseNames[AccArcBi];
            ShowProto('Open: '+S1);
            if OpenBase(BtrBase1, S1) then
            begin
              S2 := ChangeFileExt(S1, '.old');
              ShowProto('Open: '+S2);
              if OpenBase(BtrBase2, S2) then
              begin
                Len := SizeOf(AccArcRec);
                Res := BtrBase2.GetFirst(AccArcRec, Len, I, 0);
                while (Res=0) and Process and not Err do
                begin
                  if AccList.IndexOfObject(TOBject(AccArcRec.aaIder))>=0 then
                  begin
                    Res := BtrBase1.Insert(AccArcRec, Len, I, 0);
                    if (Res<>0) and (Res<>5) then
                    begin
                      ShowProto('ArcAccInsert: Id='+IntToStr(I)+' BtrErr='
                        +IntToStr(Res));
                      Err := True;
                    end;
                  end;
                  Len := SizeOf(AccRec);
                  Res := BtrBase2.GetNext(AccRec, Len, I, 0);
                end;
                CloseBase(BtrBase2);
              end
              else
                Err := True;
              CloseBase(BtrBase1);
            end
            else
              Err := True;
          end;
      end;
      ProgressBar.Hide;
    end;
    if (Step<TaskListBox.Items.Count) or Err or not Process then
    begin
      ShowMes('Процесс не завершен до конца');
      S1 := 'Процесс не завершен до конца';
      if Err then
        S1 := S1+#13#10'По причинам ошибок';
      if not Process then
        S1 := S1+#13#10'Был прерван';
      MessageBox(Handle, PChar(S1), PChar(Caption), MB_OK or MB_ICONERROR);
    end
    else
      ShowMes('Процесс успешно завершен.');
    Process := False;
    SetCurStep(-1);
    OkBitBtn.Show;
  end
  else
    Close;
end;

procedure TDelOldAccForm.FormDestroy(Sender: TObject);
begin
  if ProtoIsOpen then
    CloseFile(ProtoFile);
  AccList.Free;
end;

procedure TDelOldAccForm.FormCreate(Sender: TObject);
var
  Year, Month, Day: Word;
begin
  AccList := TStringList.Create;
  DecodeDate(Date - 90.0, Year, Month, Day);
  DateEdit.Date := EncodeDate(Year, Month, 01);
end;

procedure TDelOldAccForm.CloseBitBtnClick(Sender: TObject);
begin
  Close;
end;

end.

