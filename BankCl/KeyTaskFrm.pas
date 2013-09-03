unit KeyTaskFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons, Utilits, ComCtrls, ExtCtrls;

const
  ReserveLabel = 'RESERVE';

type
  TKeyTaskForm = class(TForm)
    TaskStaticText: TStaticText;
    ExitBitBtn: TBitBtn;
    IgnoreBitBtn: TBitBtn;
    CreateWorkBitBtn: TBitBtn;
    ProgressBar: TProgressBar;
    MesPanel: TPanel;
    procedure CreateWorkBitBtnClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
  private
    SorcDir, DestDir, TranDir: string;
  public
    procedure ShowTask(S: string);
    procedure ShowMes(S: string);
  end;

var
  KeyTaskForm: TKeyTaskForm;

function MakeKeyTask(P1, P2, P3: string; Mode: Byte; var Step: Integer): Boolean;

implementation

{$R *.DFM}

var
  Process: Boolean = False;

procedure TKeyTaskForm.ShowTask(S: string);
begin
  TaskStaticText.Caption := S;
end;

var
  TaskMode: Byte = 0;
  TaskStep: Integer = 0;
  TaskResult: Boolean = False;

function MakeKeyTask(P1, P2, P3: string; Mode: Byte; var Step: Integer): Boolean;
begin
  TaskMode := Mode;
  TaskStep := 0;
  TaskResult := False;
  KeyTaskForm := TKeyTaskForm.Create(Application);
  with KeyTaskForm do
  begin
    SorcDir := P1;
    DestDir := P2;
    TranDir := P3;
    case Mode of
      0:
        ShowTask('Вставленный диск '+DestDir+' является резервной дискетой. '
          +'Используйте для входа рабочий ключ. '
          +'Если рабочий ключ вышел из строя, то необходимо сделать копию.');
      1:
        begin
          Caption := 'Обновление ключей';
          CreateWorkBitBtn.Caption := 'Обновить рабочий ключ';
          ShowTask('Была получена новая версия ключей. Настоятельно рекомендуется'
            +' прямо сейчас обновить ключевые дискеты. Вставьте рабочий'
            +' ключ и нажмите кнопку "'+CreateWorkBitBtn.Caption+'"');
          try
            CreateWorkBitBtn.SetFocus;
          except
          end;
        end;
      2:
        begin
          Caption := 'Обновление транспортных ключей';
          CreateWorkBitBtn.Caption := 'Обновить ключи';
          ShowTask('Транспортные ключи, необходимые для работы новой'
            +' версии СКЗИ, не установлены. Чтобы установить их,'
            +' вставьте рабочую ключевую дискету и нажмите кнопку "'+CreateWorkBitBtn.Caption+'"');
          try
            CreateWorkBitBtn.SetFocus;
          except
          end;
        end;
    end;
    if ShowModal<>mrIgnore then
      Step := ID_ABORT;
    Result := TaskResult;
    Free;
  end;
end;

procedure TKeyTaskForm.ShowMes(S: string);
begin
  MesPanel.Visible := Length(S)>0;
  MesPanel.Caption := S;
  Application.ProcessMessages;
end;

procedure TKeyTaskForm.FormCreate(Sender: TObject);
begin
  SorcDir := '???';
  DestDir := '???';
end;

function FileIsOldKey(S: string): Boolean;
begin
  S := UpperCase(Trim(S));
  Result := (S='OBMEN.KEY')
    or (S='RANDOM.KEY')
    or (S='UZ.DB3')
    or (S='WORK.KEY')
    or (S='GK.DB3')
    or Masked(S, '00???.KEY');
end;

function FileIsOldTrans(S: string): Boolean;
begin
  S := UpperCase(Trim(S));
  {Result := FileIsOldKey(S);
  if not Result then
  begin}
    Result := (S='ACCESS.CRY')
      or (S='ADR_USER.SYS')
      or (S='ADR_USER.WRK')
      or (S='CRSMNG.EXE')
      or (S='CRY_ADM.EXE')
      or (S='CRY_DRV.COM')
      or (S='CRYSG001.BPL')
      or (S='MAIL.KEY')             //Добавлено Меркуловым
      or Masked(S,'00???.SYS');
  {end;}
end;

function GetFileAttr(FN: string; var Size: DWord; D: Integer): Boolean;
var
  Ofs: OFSTRUCT;
  H: THandle;
begin
  Result := False;
  FillChar(Ofs, SizeOf(Ofs), #0);
  Ofs.cBytes := SizeOf(Ofs);
  H := OpenFile(PChar(FN), Ofs, OF_READ);
  if H<>INVALID_HANDLE_VALUE then
  begin
    try
      D := FileGetDate(H);
      Size := GetFileSize(H, nil);
    finally
      CloseHandle(H);
    end;
  end;
end;

function FilesIsEqual(FN1, FN2: string): Boolean;
var
  S1, S2: DWord;
  D1, D2: Integer;
begin
  Result := FileExists(FN1) and FileExists(FN2) and
    (RusUpperCase(ExtractFileName(FN1))=RusUpperCase(ExtractFileName(FN2)))
    and GetFileAttr(FN1, S1, D1) and GetFileAttr(FN2, S2, D2)
    and (S1=S2) and (D1=D2);
end;

function KillNewKeys(Dir: string): Integer;
var
  SearchRec: TSearchRec;
  Res: Integer;
begin
  Result := 0;
  Dir := UpperCase(Dir);
  if (Length(Dir)>0) and (Dir<>'C:') and (Dir<>'C:\') then
  begin
    Res := FindFirst(Dir+'*.*', faAnyFile, SearchRec);
    if Res=0 then
    begin
      try
        while (Res=0) and Process do
        begin
          if (SearchRec.Attr and faDirectory)>0 then
          begin
            if (UpperCase(SearchRec.Name)='KEY_DISK')
              or (UpperCase(SearchRec.Name)='STATION') then
            begin
              if KillDir(Dir+SearchRec.Name+'\') then
                Inc(Result);
            end;
          end
          else begin   {файл}
            if not FileIsOldTrans(SearchRec.Name) then
            begin
              if DeleteFile(Dir+SearchRec.Name) then
                Inc(Result);
            end;
          end;
          Res := FindNext(SearchRec);
          Application.ProcessMessages;
        end;
      finally
        FindClose(SearchRec);
      end;
    end;
  end;
end;

procedure TKeyTaskForm.CreateWorkBitBtnClick(Sender: TObject);
const
  MesTitle: PChar = 'Создание рабочей копии';
  DoubleDirName = 'Копия';
  FlopKeyDirName = 'KEY_DISK';
var
  C: Integer;
  WriteMode: Integer;
  SkipDirName1, SkipDirName2: string;

  procedure NextProgressStep;
  begin
    if ProgressBar.Position < ProgressBar.Max then
      ProgressBar.Position := ProgressBar.Position+1;
  end;

  function ProcessDir(Src, Dst: string): Boolean;
  var
    SearchRec: TSearchRec;
    Res: Integer;
  begin
    Result := False;
    Res := FindFirst(Src+'*.*', faAnyFile, SearchRec);
    if Res=0 then
    begin
      Result := True;
      try
        while (Res=0) and Result and Process do
        begin
          if (SearchRec.Attr and faDirectory)>0 then
          begin
            if (SearchRec.Name<>'.') and (SearchRec.Name<>'..')
              and ((WriteMode>0) or (SearchRec.Name<>SkipDirName1)
              and (SearchRec.Name<>SkipDirName2)) then
            begin
              if not DirExists(Dst+SearchRec.Name) then
              begin
                ShowMes('Создаю каталог '+Dst+SearchRec.Name+'...');
                if not CreateDirectory(PChar(Dst+SearchRec.Name), nil) then
                begin
                  //AddProto('Can''t create dir '+Dst+SearchRec.Name);
                  Result := False;
                end;
                ShowMes('');
              end;
              if Result then
                ProcessDir(Src+SearchRec.Name+'\', Dst+SearchRec.Name+'\')
            end;
          end
          else begin
            if ((WriteMode<>1) or not FileExists(Dst+SearchRec.Name))
              and ((WriteMode>=0) or not FileIsOldKey(SearchRec.Name)) then
            begin
              NextProgressStep;
              if WriteMode<2 then
                ShowMes('Читаю файл '+Src+SearchRec.Name+'...')
              else
                ShowMes('Записываю файл '+Dst+SearchRec.Name+'...');
              if (WriteMode=3) and FilesIsEqual(Src+SearchRec.Name,
                Dst+SearchRec.Name)
              then
                Result := False
              else
                Result := CopyFile(PChar(Src+SearchRec.Name),
                  PChar(Dst+SearchRec.Name), WriteMode=1);
              {if not Result and (Mode=0) then
                Result := CopyFile(PChar(Src+DoubleDirName+'\'+SearchRec.Name),
                  PChar(Dst+SearchRec.Name), False);}
              ShowMes('');
              if Result then
                Inc(C);
              Result := Result or (WriteMode=1) or (WriteMode=3);
                //AddProto('Can''t copy file '+Dir+SearchRec.Name+' to '
                  //+Dst+SearchRec.Name);
            end;
          end;
          Res := FindNext(SearchRec);
          Application.ProcessMessages;
        end;
        Result := Result and Process;
      finally
        FindClose(SearchRec);
      end;
    end;
  end;

var
  OldCapt: string;
  S, S2: string;
begin
  if Process then
  begin
    if MessageBox(Handle, 'Вы уверены, что хотите прервать процесс?',
      MesTitle, MB_YESNOCANCEL or MB_ICONWARNING or MB_DEFBUTTON2)=ID_YES
    then
      Process := False
  end
  else begin
    OldCapt := CreateWorkBitBtn.Caption;
    CreateWorkBitBtn.Caption := 'Остановить процесс';
    IgnoreBitBtn.Hide;
    ExitBitBtn.Hide;
    Process := True;
    SkipDirName2 := '';
    try
      case TaskMode of
        0:
          begin   { создание копии рабочего ключа }
            case TaskStep of
              0:
                begin
                  ShowTask('Создание временной папки...');
                  KillDir(SorcDir);
                  if CreateDir(SorcDir) then
                  begin
                    ShowTask('Подождите, идет копирование файлов с резервной дискеты '
                      +DestDir+' во временную папку...');
                    ProgressBar.Show;
                    ProgressBar.Min := 0;
                    ProgressBar.Position := 0;
                    ProgressBar.Max := 45;
                    C := 0;
                    WriteMode := 0;
                    SkipDirName1 := DoubleDirName;
                    ProcessDir(DestDir, SorcDir);
                    WriteMode := 1;
                    ProcessDir(DestDir+DoubleDirName+'\', SorcDir);
                    ProgressBar.Position := ProgressBar.Max;
                    if Process then
                    begin
                      if C>0 then
                      begin
                        Caption := 'Создание рабочего ключа';
                        TaskStep := 1;
                        ProgressBar.Position := 0;
                        ProgressBar.Max := C;
                        OldCapt := 'Воссоздать дискету';
                        ShowTask('Вставьте дискету '+DestDir
                          +' для создания рабочего ключа и нажмите кнопку "'
                          +OldCapt+'"');
                      end
                      else
                        ShowTask('Нет файлов для копирования в '+DestDir);
                    end;
                    if not Process then
                      ShowTask('Копирование прервано');
                  end
                  else
                    ShowTask('Не удалось создать временную папку '+SorcDir);
                end;
              1:
                begin
                  while Process do
                  begin
                    ShowTask('Подождите, идет проверка метки дискеты '
                      +DestDir+'...');
                    if GetVolumeLabel(DestDir, S) then
                    begin
                      if UpperCase(Trim(S))<>ReserveLabel then
                      begin
                        ShowTask('Подождите, идет установка метки '
                          +DestDir+'...');
                        if SetVolumeLabel(PChar(DestDir), '') then
                        begin
                          S := '';
                          if MessageBox(Handle, PChar('Предварительно очистить дискету?'
                            +#13#10'(при этом все файлы на ней будут удалены)'),
                            MesTitle, MB_YESNO or MB_ICONQUESTION or MB_DEFBUTTON2)=ID_YES then
                          begin
                            ShowTask('Подождите, идет очистка дискеты '
                              +DestDir+'...');
                            if not ClearDirectory(DestDir) then
                              S := 'Не удалось очистить дискету. Возможно, она защищена от записи.'
                          end;
                          if Length(S)=0 then
                          begin
                            ShowTask('Подождите, идет запись файлов на рабочую дискету '
                              +DestDir+'...');
                            ProgressBar.Show;
                            ProgressBar.Position := 0;
                            C := 0;
                            WriteMode := 2;
                            ProcessDir(SorcDir, DestDir);
                            if C<ProgressBar.Max then
                            begin
                              ShowTask('Не все файлы скопированы в '+DestDir);
                              if C=0 then
                                S := 'Не удалось скопировать файлы. Возможно, дискета защищена от записи'
                              else
                                S := 'Не все файлы скопированы';
                            end
                            else begin
                              S := '';
                              ShowTask('Очистка временного каталога '+SorcDir+'...');
                              KillDir(SorcDir);
                              ShowTask('Копирование в '+DestDir+' успешно выполнено.'
                                +#13#10'Теперь Вы можете войти в программу с новой рабочей дискетой.');
                              CreateWorkBitBtn.Enabled := False;
                              TaskResult := True;
                              IgnoreBitBtn.Show;
                              IgnoreBitBtn.Caption := 'Войти';
                              Application.ProcessMessages;
                              try
                                IgnoreBitBtn.SetFocus;
                              except
                              end;
                            end;
                          end;
                        end
                        else
                          S := 'Не удается выполнить запись на дискету';
                      end
                      else
                        S := 'Дискета помечена как резервная. Вставьте другую дискету';
                    end
                    else
                      S := 'Не удается прочитать дискету. Вставьте исправную дискету';
                    if Length(S)>0 then
                    begin
                      Process := MessageBox(Handle, PChar(S+'.'#13#10'Попробовать еще раз?'),
                        MesTitle, MB_RETRYCANCEL or MB_ICONWARNING)=ID_RETRY;
                      if not Process then
                        ShowTask('Процесс копирования прерван');
                    end
                    else
                      Process := False;
                  end;
                end;
            end;
          end;
        1:
          begin    { "растусовка" новых ключей по дискетам }
            if TaskStep<2 then
            begin
              S := UpperCase(Copy(DestDir, 1, 2));
              if (S='A:') or (S='B:') then
              begin
                S := S+'\';
                if GetDriveType(PChar(S))=DRIVE_REMOVABLE then
                begin
                  WriteMode := ID_RETRY;
                  while WriteMode=ID_RETRY do
                  begin  
                    if GetVolumeLabel(S, S2) then
                    begin
                      while not DirExists(DestDir+FlopKeyDirName) and (WriteMode=ID_RETRY) do
                        WriteMode := MessageBox(Handle,
                          PChar('Это не новая ключевая дискета. Пожалуйста, вставьте новую'),
                          MesTitle, MB_ABORTRETRYIGNORE or MB_ICONWARNING or MB_DEFBUTTON2);
                      if WriteMode<>ID_ABORT then
                      begin  
                        WriteMode := ID_IGNORE;
                        if UpperCase(Trim(S2))=ReserveLabel then
                        begin
                          if TaskStep=0 then
                          begin
                            WriteMode := MessageBox(Handle,  
                              PChar('Дискета помечена как резервная.'
                              +' Вставьте рабочую дискету'), MesTitle,
                              MB_ABORTRETRYIGNORE or MB_ICONWARNING or MB_DEFBUTTON2);
                            S2 := '';
                          end  
                          else  
                            S2 := ReserveLabel;
                        end  
                        else begin
                          if TaskStep=1 then
                          begin
                            WriteMode := MessageBox(Handle,
                              PChar('Дискета не помечена как резервная.'
                              +' Вставьте резервную дискету?'), MesTitle,
                              MB_ABORTRETRYIGNORE or MB_ICONWARNING or MB_DEFBUTTON2);
                            S2 := ReserveLabel;
                          end
                          else
                            S2 := '';
                        end;
                        if WriteMode=ID_IGNORE then
                        begin
                          ShowTask('Подождите, идет установка метки '+S+'...');
                          if not SetVolumeLabel(PChar(S), PChar(S2)) then
                            WriteMode := MessageBox(Handle,
                              PChar('Не удается установить метку для дискеты.'
                              +#13#10'Возможно, дискета защищена от записи.'
                              +#13#10'Закройте флажок на дискете и попробуйте еще раз'),
                              MesTitle, MB_ABORTRETRYIGNORE or MB_ICONWARNING or MB_DEFBUTTON2);
                        end;
                      end;
                    end
                    else
                      WriteMode := MessageBox(Handle,
                        PChar('Вставьте, пожалуйста, дискету'), MesTitle,
                        MB_ABORTRETRYIGNORE or MB_ICONWARNING or MB_DEFBUTTON2);  
                  end;  
                  if WriteMode=ID_ABORT then
                    Process := False;
                end;
              end;
            end;
            if Process then
            begin
              ProgressBar.Position := 0;
              if TaskStep=1 then
                ProgressBar.Max := 90
              else
                ProgressBar.Max := 45;
              ProgressBar.Show;
              C := 0;
              if TaskStep<2 then
              begin
                S := AppDir+'OldKey';
                CreateDir(S);
                if DirExists(S) then
                begin
                  ShowTask('Резервное чтение предыдущей версии ключей...');
                  NormalizeDir(S);

                  WriteMode := 1;
                  ProcessDir(DestDir, S);
                  if TaskStep=0 then
                  begin
                    ProcessDir(TranDir, S);
                    KillNewKeys(TranDir);
                  end;

                  ProgressBar.Position := 0;
                  case TaskStep of
                    0:
                      ShowTask('Обновление рабочей ключевой дискеты...');
                    1:
                      ShowTask('Обновление резервной ключевой дискеты...');
                    else
                  end;
                  WriteMode := 2;
                  ProcessDir(SorcDir, DestDir);
                  if TaskStep=1 then
                  begin
                    CreateDir(DestDir+DoubleDirName+'\');
                    ProcessDir(SorcDir, DestDir+DoubleDirName+'\');
                  end;
                end
                else begin
                  ShowTask('Не удалось создать каталог для сохранения старых ключей '+S);
                  Process := False;
                end
              end
              else begin
                ShowTask('Обновление транспортного каталога...');
                WriteMode := 0;
                SkipDirName1 := FlopKeyDirName;
                ProcessDir(SorcDir, TranDir);
              end;
              if not Process then
              begin
                ShowTask('Процесс прерван');
                Process := False;
              end
              else begin
                if C>0 then
                begin
                  case TaskStep of
                    0:
                      begin
                        OldCapt := 'Обновить резервный ключ';
                        ShowTask('Копирование рабочего ключа выполнено.'
                          +#13#10'Теперь вставьте резервную дискету '
                          +'(не забудьте снять с нее защиту от записи) и нажмите кнопку "'
                          +OldCapt+'"');
                        {???}
                      end;
                    1:
                      begin
                        TaskResult := True;
                        OldCapt := 'Обновить транспорт';
                        ShowTask('Копирование резервного ключа выполнено.'
                          +#13#10'Нажмите кнопку "'
                          +OldCapt+'" для обновления транспортного каталога');
                        {???}
                      end;
                    else begin
                      ShowTask('Копирование новых ключей в '+DestDir+' успешно выполнено.'
                        +#13#10'Теперь Вы можете войти в программу с новой рабочей дискетой.');
                      TaskResult := True;
                      CreateWorkBitBtn.Enabled := False;
                      IgnoreBitBtn.Show;
                      IgnoreBitBtn.Caption := 'Войти';
                      Application.ProcessMessages;
                      try
                        IgnoreBitBtn.SetFocus;
                      except
                      end;
                    end;
                  end;
                  Inc(TaskStep);
                end
                else begin
                  ShowTask('Ни один файл не был скопирован в '+DestDir);
                end;
              end;
            end;
            if not Process then
              ShowTask('Копирование прервано');
          end;
        2:
          begin    { копирование транс. кат. }
            ShowTask('Обновление транспортного каталога...');
            S := SorcDir+'Station';
            if DirExists(S) then
            begin
              ProgressBar.Show;
              ProgressBar.Position := 0;
              ProgressBar.Max := 30;
              C := 0;
              WriteMode := -1;
              SkipDirName1 := FlopKeyDirName;
              SkipDirName2 := DoubleDirName;
              ProcessDir(SorcDir, DestDir);
              if not Process then
              begin
                ShowTask('Процесс прерван');
                Process := False;
              end
              else begin
                if C>0 then
                begin
                  ShowTask('Копирование новых ключей успешно выполнено.'
                    +#13#10'Теперь Вы можете войти в программу с новой рабочей дискетой.');
                  TaskResult := True;
                  CreateWorkBitBtn.Enabled := False;
                  IgnoreBitBtn.Show;
                  IgnoreBitBtn.Caption := 'Войти';
                  Application.ProcessMessages;
                  try
                    IgnoreBitBtn.SetFocus;
                  except
                  end;
                end
                else
                  ShowTask('Ни один файл не был скопирован');
              end;
            end
            else
              ShowTask('Не найден каталог '+S+'. Возможно, дискета, которую Вы вставили,'
                +' старого образца. Попробуйте еще раз с новой дискетой');
          end;
      end;
    finally
      ShowMes('');
      ProgressBar.Hide;
      CreateWorkBitBtn.Caption := OldCapt;
      Process := False;
      IgnoreBitBtn.Show;
      ExitBitBtn.Show;
    end;
  end;
end;

procedure TKeyTaskForm.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
const
  MesTitle: PChar = 'Удаление метки "резервная"';
begin
  if (Key=VK_F8) and not Process
    and (MessageBox(Handle, PChar('Вы уверены, что хотите снять с дискеты '
    +DestDir+' метку "резервная"?'), MesTitle, MB_YESNOCANCEL or MB_ICONWARNING)=ID_YES) then
  begin
    ShowTask('Снимаю метку тома с диска '+DestDir+'...');
    if SetVolumeLabel(PChar(DestDir), '') then
    begin
      ShowTask('Метка снята'{, MB_ICONINFORMATION});
      ModalResult := mrIgnore;
    end
    else begin
      ShowTask('Не удалось снять метку'{, MB_ICONERROR});
      RaiseLastWin32Error;
    end;
  end;
end;

procedure TKeyTaskForm.FormCloseQuery(Sender: TObject;
  var CanClose: Boolean);
begin
  if Process then
  begin
    CreateWorkBitBtnClick(nil);
    CanClose := not Process;
  end;
end;

end.
