unit SendFileFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Grids, Db, DBTables, DBGrids, ExtCtrls, DBCtrls, Menus,
  StdCtrls, Buttons, ComCtrls, Common, Basbn, Utilits,
  BtrDS, BankCnBn, Registr, CommCons, {Quorum, }Btrieve,
  ToolEdit, {Sign, }BUtilits, Mask, RxMemDS, Spin, DbfDataSet, CheckLst;

type
  TSendFileForm = class(TForm)
    StatusBar: TStatusBar;
    SetupPanel: TPanel;
    BtnPanel: TPanel;
    CancelBtn: TBitBtn;
    ProccessBtn: TBitBtn;
    LeftPanel: TPanel;
    StatGroupBox: TGroupBox;
    BitLabel: TLabel;
    BitCountLabel: TLabel;
    AboCountLabel: TLabel;
    AboLabel: TLabel;
    Splitter1: TSplitter;
    ProtoGroupBox: TGroupBox;
    ProgressBar: TProgressBar;
    ProtoListBox: TListBox;
    CorrGroupBox: TGroupBox;
    CorrCheckListBox: TCheckListBox;
    AllCorrCheckBox: TCheckBox;
    SelCorLabel: TLabel;
    TaskPageControl: TPageControl;
    OneTabSheet: TTabSheet;
    ManyTabSheet: TTabSheet;
    DestComboBox: TComboBox;
    DebitNameBtn: TPanel;
    ModuleCheckBox: TCheckBox;
    SrcEdit: TFilenameEdit;
    SrcLabel: TLabel;
    SrcDirectoryEdit: TDirectoryEdit;
    Label1: TLabel;
    MoveCheckBox: TCheckBox;
    DstDirectoryEdit: TDirectoryEdit;
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
    procedure DebitNameBtnClick(Sender: TObject);
    procedure Splitter1CanResize(Sender: TObject; var NewSize: Integer;
      var Accept: Boolean);
    procedure CorrCheckListBoxClick(Sender: TObject);
  private
  protected
  public
    procedure InitProgress(Min, Max: Integer);
    procedure ShowProto(Level: Byte; S: string);
    procedure ShowStatus(S: string);
  end;

const
  SendFileForm: TSendFileForm = nil;
var
  CurrDate: TDate = 0;

implementation


{$R *.DFM}

procedure TSendFileForm.ShowProto(Level: Byte; S: string);
begin
  ProtoListBox.Items.Add(LevelToStr(Level)+': '+S);
  ProtoMes(Level, 'FileSnd', S);
end;

procedure TSendFileForm.ShowStatus(S: string);
begin
  StatusBar.Panels[1].Text := S;
  Application.ProcessMessages;
end;

var
  Process: Boolean = False;
  FileBitSize: Integer = 15000;
  SendFileDataSet, AbonDataSet: TExtBtrDataSet;

procedure TSendFileForm.FormCreate(Sender: TObject);
const
  Border=2;
begin
  SendFileDataSet := GlobalBase(biSendFile) as TBtrDataSet;
  AbonDataSet := GlobalBase(biAbon) as TBtrDataSet;
  with ProgressBar do
  begin
    Parent := StatusBar;
    SetBounds(0, Border, Width, StatusBar.Height - Border);
    StatusBar.Panels[0].Width := Width;
  end;
  FillCorrList(CorrCheckListBox.Items, alSend);
  if not GetRegParamByName('FileBitSize', GetUserNumber, FileBitSize) then
    FileBitSize := 15000;
end;

procedure TSendFileForm.InitProgress(Min, Max: Integer);
begin
  ProgressBar.Min := -10000000;
  ProgressBar.Position := ProgressBar.Min;
  ProgressBar.Max := Min;
  ProgressBar.Min := Min;
  ProgressBar.Position := ProgressBar.Min;
  ProgressBar.Max := Max;
  ProgressBar.Show;
end;

procedure TSendFileForm.ProccessBtnClick(Sender: TObject);
const
  MesTitle: PChar = 'Генерация обновлений';

var
  AboCount: Integer;

  function SendFileToCorr(Corr, MaxData, LastIder, FS: Integer; var F: file;
    DestFN: string; SendType: Char): Boolean;
  var
    Res, Len, P, I, W, C: Integer;
    ps: TSendFileRec;
  begin
    Result := True;
    BitCountLabel.Caption := '0';
    if MaxData<SizeOf(ps) - SizeOf(ps.sfData) + 10 then
      MaxData := 1000;
    with ps do
    begin
      sfBitIder := 0;
      sfFileIder := LastIder;
      sfAbonent := Corr;
      sfState := 0;
    end;
    Seek(F, 0);
    P := 0;
    while (P<=FS) and Result do
    begin
      Inc(ps.sfBitIder);
      if P+MaxData>=FS then
      begin
        I := FS-P;
        StrPCopy(ps.sfData, DestFN);
        C := Length(DestFN)+1;
        ps.sfData[C] := SendType;
      end
      else begin
        I := MaxData;
        ps.sfData[0] := #0;
        C := 0;
      end;
      Inc(C);
      if I>0 then
        BlockRead(F, ps.sfData[C], I, W)
      else
        W := 0;
      P := P+W;
      if P>=FS then
        Inc(P);
      Len := SizeOf(ps) - SizeOf(ps.sfData) + C + W;
      Res := SendFileDataSet.BtrBase.Insert(ps, Len, I, 0);
      if Res=0 then
      begin
        BitCountLabel.Caption := IntToStr(ps.sfBitIder);
        Application.ProcessMessages;
      end
      else begin
        Result := False;
        ShowProto(plError, 'Не удалось добавить фрагмент N'+IntToStr(ps.sfBitIder)
          +' Abon='+IntToStr(Corr)+' BtrErr='+IntToStr(Res));
      end;
    end;
    if Result then
    begin
      ShowProto(plInfo, 'Abo='+IntToStr(Corr)+' '+IntToStr(ps.sfBitIder)
        +'x'+IntToStr(MaxData)+'b');
      Inc(AboCount);
      AboCountLabel.Caption := IntToStr(AboCount);
      Application.ProcessMessages;
    end
  end;

var
  AbonIder, SrcDirLen: Integer;

  function SendDir(SrcDir, DstDir: string): Boolean;
  var
    Res1, Res2, LastIder, FS: Integer;
    SearchRec: TSearchRec;
    F: file;
    DstMask: string;
  begin
    Result := False;
    Res2 := FindFirst(SrcDir+'*.*', faAnyFile, SearchRec);
    if Res2=0 then
    begin
      Result := True;
      try
        while (Res2=0) and Result and Process do
        begin
          if (SearchRec.Attr and faDirectory)>0 then
          begin
            if (SearchRec.Name<>'.') and (SearchRec.Name<>'..') then
            begin
              if (Length(DstDir)>0) and not DirExists(DstDir+SearchRec.Name) then
              begin
                ShowProto(plInfo, 'Создаю каталог '+DstDir+SearchRec.Name+'...');
                if not CreateDirectory(PChar(DstDir+SearchRec.Name), nil) then
                begin
                  //AddProto('Can''t create dir '+Dst+SearchRec.Name);
                  //Result := False;
                end;
                //ShowMes('');
              end;
              if Result then
              begin
                Result := SendDir(SrcDir+SearchRec.Name+'\', DstDir+SearchRec.Name+'\');
                if Result then
                  if not RemoveDirectory(PChar(SrcDir+SearchRec.Name)) then
                    ShowProto(plWarning, 'Не удалось убрать '+DstDir+SearchRec.Name);
              end;
            end;
          end
          else begin
            ShowStatus('Открытие '+SrcDir+SearchRec.Name+'...');
            AssignFile(F, SrcDir+SearchRec.Name);
            FileMode := 0;
            {$I-} Reset(F, 1); {$I+}
            if IOResult=0 then
            begin
              FS := FileSize(F);
              ShowStatus('Определение последнего номера...');
              Res1 := SendFileDataSet.BtrBase.GetLastKey(LastIder, 0);
              if (Res1=0) or (Res1=9) then
              begin
                if Res1=9 then
                  LastIder := 0;
                Inc(LastIder);
                DstMask := SrcDir+SearchRec.Name;
                DstMask := Copy(DstMask, SrcDirLen+1, Length(DstMask)-SrcDirLen);
                ShowProto(plInfo, 'Рассылка N'+IntToStr(LastIder)+' файла '
                  +SrcDir+SearchRec.Name+'('+IntToStr(FS)+'b) в '+DstMask);
                AboCount := 0;
                AboCountLabel.Caption := '0';
                BitCountLabel.Caption := '0';
                Result := SendFileToCorr(AbonIder, FileBitSize, LastIder, FS, F,
                  DstMask, #0);
                CloseFile(F);
                if Result then
                begin
                  DeleteFile(PChar(DstDir+SearchRec.Name));
                  Result := RenameFile(PChar(SrcDir+SearchRec.Name),
                    PChar(DstDir+SearchRec.Name));
                  if not Result then
                    ShowProto(plWarning, 'Не удалось перенести '+SrcDir+SearchRec.Name+' в '
                      +DstDir+SearchRec.Name);
                end;
              end
              else begin
                CloseFile(F);
                ShowProto(plWarning, 'Ошибка поиска последнего номера обновления BtrErr='+IntToStr(Res1));
              end;
            end
            else
              ShowProto(plWarning, 'Не удалось открыть '+SrcDir+SearchRec.Name);
          end;
          Res2 := FindNext(SearchRec);
          Application.ProcessMessages;
        end;
        Result := Result and Process;
      finally
        FindClose(SearchRec);
      end;
    end;
  end;

var
  SrcFN, DestFN: string;
  F: file;
  LastIder, FS: Integer;
  SendType: Char;
  Res, Res2, Len, Key0, I: Integer;
  AbonRec: TAbonentRec;
  One: Boolean;
  SearchRec: TSearchRec;
  Key1: TAbonLogin;
  SrcDir: string;
begin
  if Process then
    Process := False
  else begin
    Process := True;
    ProccessBtn.Caption := '&Прервать';
    CancelBtn.Enabled := False;
    ShowStatus('');
    One := TaskPageControl.ActivePage=OneTabSheet;
    if One then
    begin
      SrcFN := SrcEdit.Text;
      DestFN := DestComboBox.Text;
    end
    else begin
      SrcFN := SrcDirectoryEdit.Text;
      if MoveCheckBox.Checked then
        DestFN := DstDirectoryEdit.Text
      else
        DestFN := '';
    end;
    if (Length(SrcFN)>0) and (Length(DestFN)>0) then
    begin
      if One then
      begin  {досылка одного файла или модуля выбранным абонентам}
        ShowStatus('Открытие '+SrcFN+'...');
        AssignFile(F, SrcFN);
        FileMode := 0;
        {$I-} Reset(F, 1); {$I+}
        if IOResult=0 then
        begin
          FS := FileSize(F);
          if ModuleCheckBox.Checked then
            SendType := #1
          else
            SendType := #0;
          ShowStatus('Определение последнего номера...');
          Res := SendFileDataSet.BtrBase.GetLastKey(LastIder, 0);
          if (Res=0) or (Res=9) then
          begin
            if Res=9 then
              LastIder := 0;
            Inc(LastIder);
            ShowProto(plInfo, 'Рассылка N'+IntToStr(LastIder)+' файла '+SrcFN
              +'('+IntToStr(FS)+'b) в '+DestFN);
            AboCount := 0;
            AboCountLabel.Caption := '0';
            BitCountLabel.Caption := '0';
            if AllCorrCheckBox.Checked then
            begin
              ShowStatus('Формирование сообщений всем абонентам...');
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
                  or (((AbonRec.abLock and 2) = 0))
                then
                  SendFileToCorr(AbonRec.abIder, FileBitSize, LastIder, FS, F,
                    DestFN, SendType);
                ProgressBar.Position := AbonRec.abIder;
                Application.ProcessMessages;
                Len := SizeOf(AbonRec);
                Res := AbonDataSet.BtrBase.GetNext(AbonRec, Len, Key0, 0);
              end;
              ProgressBar.Hide;
            end
            else begin
              ShowStatus('Формирование сообщений выбранным абонентам...');
              with CorrCheckListBox do
              begin
                I := 0;
                while (I<Items.Count) and Process do
                begin
                  if Checked[I] then
                    SendFileToCorr(Integer(Items.Objects[I]), FileBitSize,
                      LastIder, FS, F, DestFN, SendType);
                  Inc(I);
                end;
              end;
            end;
            ShowProto(plInfo, 'Всего абонентов: '+IntToStr(AboCount));
            if not Process then
              ShowProto(plInfo, 'Процесс прерван')
          end
          else
            ShowProto(plWarning, 'Ошибка поиска последнего номера обновления BtrErr='+IntToStr(Res));
          CloseFile(F);
        end
        else
          ShowProto(plWarning, 'Не удалось открыть '+SrcFN);
      end
      else begin  {рассылка личных файлов каждому абоненту}
        NormalizeDir(SrcFN);
        Res2 := FindFirst(SrcFN+'*.*', faAnyFile, SearchRec);
        if Res2=0 then
        begin
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
                      I := CorrCheckListBox.Items.IndexOfObject(TObject(
                        AbonRec.abIder));
                      if (I>=0) and CorrCheckListBox.Checked[I] then
                      begin
                        SrcDir := SrcFN+SearchRec.Name+'\';
                        SrcDirLen := Length(SrcDir);
                        AbonIder := AbonRec.abIder;
                        NormalizeDir(DestFN);
                        CreateDir(DestFN+SearchRec.Name);
                        if SendDir(SrcDir, DestFN+SearchRec.Name+'\') then
                          {RemoveDirectory(SrcFN+SearchRec.Name) };
                      end;
                    end
                    else
                      ShowProto(plWarning, 'Абонент ['+Key1+'] блокирован');
                  end
                  else
                    ShowProto(plWarning, 'Абонент ['+Key1+'] не найден BtrErr='+IntToStr(Res));
                end;
              end;
              Res2 := FindNext(SearchRec);
              Application.ProcessMessages;
            end;
          finally
            FindClose(SearchRec);
          end;
        end;
      end;
    end;
    ShowStatus('');
    Process := False;
    ProccessBtn.Caption := '&Начать...';
    CancelBtn.Enabled := True;
  end;
end;

procedure TSendFileForm.FormResize(Sender: TObject);
begin
  SrcEdit.Width := TaskPageControl.ClientWidth - 5 * SrcEdit.Left;
  DestComboBox.Width := SrcEdit.Width;
  SrcDirectoryEdit.Width := SrcEdit.Width;
end;

procedure TSendFileForm.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  Action := caFree;
end;

procedure TSendFileForm.FormShow(Sender: TObject);
var
  B: Boolean;
  I, C: Integer;
begin
  if not Process then
  begin
    if TaskPageControl.ActivePage=OneTabSheet then
      B := (Length(SrcEdit.Text)>0) and (Length(DestComboBox.Text)>0)
    else
      B := (Length(SrcDirectoryEdit.Text)>0)
        and (not MoveCheckBox.Checked or (Length(DstDirectoryEdit.Text)>0));
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

procedure TSendFileForm.CorrCheckListBoxClick(Sender: TObject);
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

procedure TSendFileForm.AllCorrCheckBoxClick(Sender: TObject);
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

procedure TSendFileForm.DebitNameBtnMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbLeft then (Sender as TPanel).BevelOuter := bvLowered;
end;

procedure TSendFileForm.DebitNameBtnMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  with (Sender as TPanel) do
    if BevelOuter = bvLowered then BevelOuter := bvRaised;
end;


procedure TSendFileForm.DebitNameBtnClick(Sender: TObject);
begin
  DestComboBox.Text := DestComboBox.Text + ExtractFileName(SrcEdit.Text);
end;

procedure TSendFileForm.Splitter1CanResize(Sender: TObject;
  var NewSize: Integer; var Accept: Boolean);
begin
  if NewSize<15 then
    NewSize := 15;
end;


end.
