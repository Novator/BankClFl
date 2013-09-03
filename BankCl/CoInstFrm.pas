unit CoInstFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons, ExtCtrls, ComCtrls, ShlObj;

type
  TCoinstForm = class(TForm)
    TopBevel: TBevel;
    BottomBevel: TBevel;
    BtnPanel: TPanel;
    TopPanel: TPanel;
    TitleLabel: TLabel;
    UrlLabel: TLabel;
    MesLabel: TLabel;
    DirGroupBox: TGroupBox;
    DirEdit: TEdit;
    BrowseButton: TButton;
    NextButton: TButton;
    SkipButton: TButton;
    ProgressGroupBox: TGroupBox;
    ProgressBar: TProgressBar;
    StatusLabel: TLabel;
    BankCheckBox: TCheckBox;
    ItcsCheckBox: TCheckBox;
    KeyCheckBox: TCheckBox;
    KeyLabel: TLabel;
    BankLabel: TLabel;
    ItcsLabel: TLabel;
    procedure SkipButtonClick(Sender: TObject);
    procedure NextButtonClick(Sender: TObject);
    procedure BrowseButtonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure BankCheckBoxClick(Sender: TObject);
  private
    { Private declarations }
  public
    procedure ShowMes(const S: string);
  end;

var
  CoinstForm: TCoinstForm;

implementation

{$R *.DFM}

const
  stKey   = 1;
  stBank  = 2;
  stItcs  = 4;
var
  Step: Integer = -1;
  NoFinalDlg: Boolean = False;

procedure TCoinstForm.FormCreate(Sender: TObject);
var
  S: string;
  K: Integer;
  Make, Enab: Word;
  B: Byte;
begin
  NoFinalDlg := False;
  Make := stKey{ or stBank or stItcs};
  Enab := stKey or stBank{ or stItcs};
  K := 0;
  while K<ParamCount do
  begin
    Inc(K);
    S := UpperCase(Trim(ParamStr(K)));
    if Length(S)>0 then
    begin
      if ((S[1]='-') or (S[1]='/')) and (Length(S)>2) and (S[3] in ['0'..'9']) then
      begin
        B := Ord(S[3])-48;
        case S[2] of
          'C':
            Make := B;
          'U':
            Make := Make and not B;
          'E':
            Enab := B;
          'D':
            Enab := Enab and not B;
          'N':
            NoFinalDlg := True;
        end;
      end
    end;
  end;
  KeyCheckBox.Checked := (Make and stKey) > 0;
  KeyCheckBox.Enabled := (Enab and stKey) > 0;
  BankCheckBox.Checked := (Make and stBank) > 0;
  BankCheckBox.Enabled := (Enab and stBank) > 0;
  ItcsCheckBox.Checked := (Make and stItcs) > 0;
  ItcsCheckBox.Enabled := (Enab and stItcs) > 0;
  SkipButtonClick(nil);
end;

function GetCdDrive(Num: Integer): string;
var
  I, Mask: DWord;
  S: string;
begin
  Result := '';
  Mask := GetLogicalDrives;
  I := 0;
  while (Mask<>0) and ((Num>0) or (Length(Result)=0)) do
  begin
    S := Chr(Ord('A')+I) + ':\';
    if (Mask and 1) <> 0 then
      if GetDriveType(PChar(S))=DRIVE_CDROM then
      begin
        Result := S;
        if Num>0 then
          Dec(Num);
      end;
    Inc(I);
    Mask := Mask shr 1;
  end;
end;

procedure NormalizeDir(var Dir: string);
var
  L: Integer;
begin
  L := Length(Dir);
  if (L>0) and (Dir[L]<>'\') then
    Dir := Dir + '\';
end;

procedure TCoinstForm.SkipButtonClick(Sender: TObject);
var
  Stop: Boolean;
  S: string;
begin
  try
    SkipButton.Enabled := False;
    NextButton.Enabled := False;
    Application.ProcessMessages;
    //Sleep(20);
    Stop := False;
    while not Stop and (Step<=3) do
    begin
      Inc(Step);
      KeyCheckBox.Enabled := KeyCheckBox.Enabled and (Step<=0);
      BankCheckBox.Enabled := BankCheckBox.Enabled and (Step<=1);
      ItcsCheckBox.Enabled := ItcsCheckBox.Enabled and (Step<=2);
      KeyLabel.Visible := Step>0;
      BankLabel.Visible := Step>1;
      ItcsLabel.Visible := Step>2;
      Stop := (Step=0) and KeyCheckBox.Checked
        or (Step=1) and BankCheckBox.Checked
        or (Step=2) and ItcsCheckBox.Checked or (Step>2);
    end;
    if Step>3 then
      Close
    else begin
      case Step of
        1:
          begin
            TitleLabel.Caption := 'Обновление справочника банков';
            MesLabel.Caption := 'Вставьте диск с sfx-архивом BankN$.exe, содержащий свежий справочник'
              +#13#10'банков. Вы можете выбрать другой каталог используя кнопку Обзор.';
          end;
        2:
          begin
            TitleLabel.Caption := 'Обновление библиотеки СКЗИ';
            MesLabel.Caption := 'Вставьте CD-диск, на котором находится новая библиотека СКЗИ. Если вас'
              +#13#10'не устраивает предложенный каталог, нажмите Обзор и выберите другой.';
            S := GetCdDrive(0);
            if Length(S)=0 then
              S := 'D:\';
            NormalizeDir(S);
            S := S+'SDK_DomK\';
            DirEdit.Text := S;
          end;
        3:
          begin
            DirGroupBox.Hide;
            TitleLabel.Caption := 'Процесс завершен';
            MesLabel.Caption := 'Нажмите Закрыть, чтобы завершить доустановку программы.';
            if NoFinalDlg then
              Close;
          end;
      end;
    end;
  finally
    SkipButton.Enabled := True;
    NextButton.Enabled := True;
    BankCheckBoxClick(nil);
  end;
end;

function DirExists(S: string): Boolean;
var
  Code: Integer;
begin
  Code := Length(S);
  if (Code>0) and (S[Code]='\') then
    Delete(S, Code, 1);
  Code := GetFileAttributes(PChar(S));
  Result := (Code <> -1) and (FILE_ATTRIBUTE_DIRECTORY and Code <> 0);
end;

var
  Process: Boolean = False;
(*  WriteMode: Byte = 0;
  SkipDirName: string = '';*)

procedure TCoinstForm.ShowMes(const S: string);
begin
  StatusLabel.Caption := S;
  Application.ProcessMessages;
end;

(*function ProcessDir(Src, Dst: string): Boolean;
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
            and ((WriteMode>0) or (SearchRec.Name<>SkipDirName)) then
          begin  
            if not DirExists(Dst+SearchRec.Name) then  
            begin  
              //ShowMes('Создаю каталог '+Dst+SearchRec.Name+'...');
              if not CreateDirectory(PChar(Dst+SearchRec.Name), nil) then
              begin
                //AddProto('Can''t create dir '+Dst+SearchRec.Name);  
                Result := False;  
              end;
              //ShowMes('');
            end;  
            if Result then  
              ProcessDir(Src+SearchRec.Name+'\', Dst+SearchRec.Name+'\')
          end;  
        end  
        else begin  
          if (WriteMode<>1) or not FileExists(Dst+SearchRec.Name) then  
          begin
            //NextProgressStep;
            {if WriteMode<2 then
              ShowMes('Читаю файл '+Src+SearchRec.Name+'...')
            else
              ShowMes('Записываю файл '+Dst+SearchRec.Name+'...');}
            Result := CopyFile(PChar(Src+SearchRec.Name),  
              PChar(Dst+SearchRec.Name), WriteMode=1);  
            {if not Result and (Mode=0) then
              Result := CopyFile(PChar(Src+DoubleDirName+'\'+SearchRec.Name),
                PChar(Dst+SearchRec.Name), False);}  
            //ShowMes('');
            {if Result then
              Inc(C);}
            Result := Result or (WriteMode=1);  
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
end; *)

function RunAndWait(AppPath: string): Boolean;
const
  MesTitle: PChar = 'Выполнение';
var
  si: TStartupInfo;
  pi: TProcessInformation;
  CmdLine: array[0..1023] of Char;
  Code: dWord;
  S: string;
begin
  Result := False;
  S := ParamStr(0);
  S := ExtractFilePath(S);
  SetCurrentDirectory(PChar(S));
  FillChar(si, SizeOf(si), #0);
  with si do
  begin
    cb := SizeOf(si);
    dwFlags := STARTF_USESHOWWINDOW;
    wShowWindow := SW_SHOWDEFAULT;
  end;
  StrPLCopy(CmdLine, AppPath, SizeOf(CmdLine));
  if CreateProcess(nil, CmdLine, nil, nil, FALSE,
    DETACHED_PROCESS, nil, nil, si, pi) then
  begin
    WaitforSingleObject(pi.hProcess, INFINITE);
    GetExitCodeProcess(pi.hProcess, Code);
    Result := Code=0;
  end
  else
    MessageBox(CoinstForm.Handle, PChar('Не удалось запустить '
      +#13#10+CmdLine), MesTitle, MB_OK or MB_ICONERROR);
end;

function GetVolumeLabel(RootPath: string; var ALabel: string): Boolean;
var
  A,B,L: dWord;
  Lab, FSys: array [0..12] of Char;
begin
  Result := GetVolumeInformation(PChar(RootPath),
    Lab, SizeOf(Lab), @L, A, B, FSys, SizeOf(FSys));
  if Result then
    ALabel := Lab;
end;

procedure TCoinstForm.NextButtonClick(Sender: TObject);
const
  MesTitle: PChar = 'Копирование';
var
  B: Boolean;
  I: Integer;
  FR: THandle;
  FindData: TWin32FindData;
  FL: TStringList;
  OldNextCapt, AppDir, SrcDir, DstDir, ErrMes, S, S2: string;
  OldSkipEn: Boolean;
  L: TLabel;
  DW, DT: DWord;
begin
  if Process then
  begin
    Process := False;
    NextButton.Enabled := False;
    Application.ProcessMessages;
  end
  else begin
    Process := True;
    OldNextCapt := NextButton.Caption;
    NextButton.Caption := 'Прервать';
    OldSkipEn := SkipButton.Enabled;
    SkipButton.Enabled := False;
    Application.ProcessMessages;
    FL := TStringList.Create;
    try
      AppDir := ExtractFilePath(Application.ExeName);
      SrcDir := DirEdit.Text;
      NormalizeDir(SrcDir);
      case Step of
        0:
          begin  {ключевые файлы}
            FR := FindFirstFile(PChar(SrcDir+'00???.SYS'), FindData);
            if FR<>INVALID_HANDLE_VALUE then
            begin
              FL.Add('crysg001.bpl');
              FL.Add('crysg001.bpl');
              FL.Add('adr_user.sys');
              FL.Add('cry_adm.exe');
              FL.Add('access.cry');
              FL.Add(ExtractFileName(FindData.cFileName));
              Windows.FindClose(FR);
            end
            else
              FL.Add('');
            //FL.Add('extnet.doc');
            FL.Add('infotecs.RE');
            FL.Add('ipliradr.doc');
            FR := FindFirstFile(PChar(SrcDir+'AP*.*'), FindData);
            if FR<>INVALID_HANDLE_VALUE then
            begin
              repeat
                FL.Add(ExtractFileName(FindData.cFileName));
              until not FindNextFile(FR, FindData);
              Windows.FindClose(FR);
            end;
            FR := FindFirstFile(PChar(SrcDir+'Station\*.*'), FindData);
            if FR<>INVALID_HANDLE_VALUE then
            begin
              repeat
                if (FindData.dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY)=0 then
                  FL.Add('Station\'+ExtractFileName(FindData.cFileName));
              until not FindNextFile(FR, FindData);
              Windows.FindClose(FR);
            end;
          end;
        1:
          begin   {справочник банков}
            FL.Add('bankn$.exe');
          end;
        2:
          begin  {библиотека СКЗИ}
            FL.Add('asimkeys.dll');
            FL.Add('Envelope.dll');
            FL.Add('filedisp.dll');
            FL.Add('sdk_list.crg');
            FL.Add('sdk_list.prg');
            FL.Add('mfc42.dll');
            FL.Add('msvcirt.dll');
            FL.Add('msvcp60.dll');
            FL.Add('msvcrt.dll');
            FL.Add('AddCrypt.dll');
            FL.Add('Aladdin.dll');
            FL.Add('aladdin2.dll');
            FL.Add('alterdev.dll');
            FL.Add('Cert.dll');
            FL.Add('certui.dll');
            FL.Add('comlogon.dll');
            FL.Add('Crypt.dll');
            FL.Add('cryptomx.dll');
            FL.Add('ExtraCrp.dll');
            FL.Add('guiext.dll');
            FL.Add('hooks.dll');
            FL.Add('idents.dll');
            FL.Add('ipc.dll');
            FL.Add('ITCSCApi.dll');
            FL.Add('itcscom.dll');
            FL.Add('LockerUI.dll');
            FL.Add('logdisp.dll');
            FL.Add('LogonDev.dll');
            FL.Add('MailCryp.dll');
            FL.Add('nonmfc.dll');
            FL.Add('pswdkeys.dll');
            FL.Add('service.dll');
            FL.Add('sprdbtxt.dll');
            FL.Add('StoreDev.dll');
            FL.Add('Tcc_Itcs.dll');
            FL.Add('Tcc_Itcs.lib');
            FL.Add('tools2.dll');
          end;
      end;
      //showmessage(fl.text);

      if (FL.Count>0) and Process then
      begin
        S := UpperCase(Copy(Trim(SrcDir), 1, 2));
        if (Length(S)>1) and (S[2]=':') and (S[1] in ['A'..'Z']) then
        begin
          S := S+'\';
          repeat
            DT := GetDriveType(PChar(S));
            if (DT=DRIVE_REMOVABLE) or (DT=DRIVE_CDROM) then
            begin
              if GetVolumeLabel(S, S2) then
                S2 := ''
              else begin
                S2 := 'В устройстве '+Copy(S, 1, 2)+' нет диска';
                if Application.MessageBox(
                  PChar('Вставьте диск в устройство '+Copy(S, 1, 2)
                    +' и попробуйте еще раз'),
                    MesTitle, MB_ABORTRETRYIGNORE or MB_ICONINFORMATION or MB_DEFBUTTON2)
                  <>ID_RETRY
                then
                  Process := False;
              end;
            end
            else
              S2 := '';
          until (Length(S2)=0) or not Process;
          if not Process then
            S := S2;
        end;
        if (FL.Count>0) and Process then
        begin
          S := '';
          ProgressBar.Position := 0;
          ProgressBar.Max := FL.Count;
          Application.ProcessMessages;
          ProgressGroupBox.Show;
          ErrMes := '';
          I := 0;
          while (I<FL.Count) and Process do
          begin
            S := FL.Strings[I];
            B := True;
            if Length(S)>0 then
            begin
              case Step of
                0:  {ключи}
                  begin
                    if I=0 then
                      DstDir := ''
                    else
                      DstDir := 'Key\';
                  end;
                1:  {справ}
                  begin
                    DstDir := 'Base\';
                  end;
                else
                  DstDir := '';
              end;
              if Length(DstDir)>0 then
              begin
                S2 := AppDir+DstDir;
                if not DirExists(S2) then
                begin
                  StatusLabel.Caption := 'Создание папки '+S2+'...';
                  Application.ProcessMessages;
                  if not CreateDir(S2) then
                    MessageBox(Handle, PChar('Не удалось создать каталог '+S2),
                      MesTitle, MB_OK or MB_ICONERROR);
                end;
              end;
              if B then
              begin
                S2 := ExtractFilePath(S);
                if Length(S2)>0 then
                begin
                  S2 := AppDir+DstDir+S2;
                  if not DirExists(S2) then
                  begin
                    StatusLabel.Caption := 'Создание папки '+S2+'...';
                    Application.ProcessMessages;
                    if not CreateDir(S2) then
                      MessageBox(Handle, PChar('Не удалось создать каталог '+S2),
                        MesTitle, MB_OK or MB_ICONERROR);
                  end;
                end;
              end;
              if B then
              begin
                StatusLabel.Caption := 'Копирование '+S+'...';
                Application.ProcessMessages;
                S2 := AppDir+DstDir+S;
                B := CopyFile(PChar(SrcDir+S), PChar(S2), False);
                if B then
                begin
                  DW := GetFileAttributes(PChar(S2));
                  if (DW and FILE_ATTRIBUTE_READONLY)<>0 then
                  begin
                    DW := DW and not FILE_ATTRIBUTE_READONLY;
                    SetFileAttributes(PChar(S2), DW);
                  end;
                end;
              end;
              if B and (Step=1) then
              begin
                StatusLabel.Caption := 'Запуск sfx-архива '+S+'...';
                Application.ProcessMessages;
                S2 := AppDir+DstDir+S;
                if RunAndWait(S2) then
                  DeleteFile(S2);
              end;
            end;
            if B or ((Step=2) and (I<=8)) then
            begin
              if ProgressBar.Position<ProgressBar.Max then
                ProgressBar.Position := ProgressBar.Position+1;
              Application.ProcessMessages;
            end
            else begin
              ErrMes := ErrMes + #13#10 + SrcDir+S +' в '+AppDir+DstDir+S;
            end;
            StatusLabel.Caption := '';
            Inc(I);   
          end;
          ProgressGroupBox.Hide;
          S := '';
          if Length(ErrMes)>0 then
          begin
            S := 'Не удалось скопировать файлы:'+ErrMes;
          end;
          if ProgressBar.Position<ProgressBar.Max then
          begin
            if Length(S)>0 then
              S := S+#13#10;
            S := S+'Скопировано всего '+IntToStr(ProgressBar.Position)
                +' файлов из '+IntToStr(ProgressBar.Max);
          end;
        end;
      end
      else
        S := 'Нет файлов для копирования';
      if Length(S)>0 then
      begin
        MessageBox(Handle, PChar(S
          +#13#10'Вы можете повторить или пропустить этот шаг'), MesTitle,
          MB_OK or MB_ICONWARNING);
        Process := False;
      end;
    finally
      FL.Free;
      NextButton.Caption := OldNextCapt;
      SkipButton.Enabled := OldSkipEn;
      if Process then
      begin
        case Step of
          0:
            L := KeyLabel;
          1:
            L := BankLabel;
          2:
            L := ItcsLabel;
          else
            L := nil;
        end;
        if L<>nil then
        begin
          L.Caption := 'выполнено';
          L.Font.Style := [fsBold];
          L.Font.Color := clGreen;
        end;
        SkipButtonClick(nil);
      end
      else
        BankCheckBoxClick(nil);
      Process := False;
      ProgressGroupBox.Hide;
    end;
  end;
end;

(*  ???
  D0 := ExtractFilePath(Application.ExeName);
  S := DirEdit.Text;
  I := Length(S);       ?
  if (I>0) and (S[I]<>'\') then
    S := S+'\';
  case Step of
    0:
      ProgressBar.Max := 2;
    1:
      begin
        ProgressBar.Max := 5;
      end;
    else
      ProgressBar.Max := 0;
  end;
  ErrMes := '';
  I := 0;
  while I<ProgressBar.Max do
  begin
    Inc(I);
    case Step of
      0:
        begin
          D := 'Base\';
          case I of
            1: F := 'bankn.btr';
            2: F := 'banknp.btr';
            else
              F := '';
          end;
        end;
      1:
        begin
          D := 'Key\';
          case I of
            1: begin D := ''; F := 'crysg001.bpl'; end;
            2: F := 'adr_user.sys';
            3: F := 'cry_adm.exe';
            4: F := K1;
            5: F := 'access.cry';
            {6: F := K2;
            7: F := 'gk.db3';
            8: F := 'uz.db3';
            9: F := 'work.key';
            10: F := 'obmen.key';
            11: F := 'random.key';
            12: F := 'obmen';
            13: F := 'random';}
            else
              F := '';
          end;
        end;
      end;
    if Length(F)>0 then
    begin
      StatusLabel.Caption := 'Копирование '+F+'...';
      Application.ProcessMessages;
      Copied := CopyFile(PChar(S+F), PChar(D0+D+F), False);
    end
    else
      Copied := False;
    if Copied then
    begin
      ProgressBar.Position := ProgressBar.Position+1;
      Application.ProcessMessages;
    end
    else
      ErrMes := ErrMes + #13#10 + S+F+' в '+D0+D+F;
    StatusLabel.Caption := '';
  end;
  if Length(ErrMes)>0 then
    MessageBox(Handle, PChar('Не скопированы файлы:'+ErrMes
      +#13#10'Вы можете повторить или пропустить этот шаг'), MesTitle,
      MB_OK or MB_ICONWARNING)
  else
    SkipButtonClick(nil);
  ProgressGroupBox.Hide;
  NextButton.Enabled := True;
  SkipButton.Enabled := True;
end; *)

procedure TCoinstForm.BrowseButtonClick(Sender: TObject);
const
  PMes: PChar = 'Выберите каталог - источник файлов'#0;
  Capt: array[0..MAX_PATH] of Char = #0;
  Path: array[0..511] of Char = '';
var
  BrowseInfo: TBrowseInfo;
  P: PItemIDList;
begin
  FillChar(BrowseInfo, SizeOf(BrowseInfo), 0);
  with BrowseInfo do
  begin
    hwndOwner := Handle;
    pidlRoot := nil;
    pszDisplayName := @Capt;
    lpszTitle := PMes;
    ulFlags := BIF_RETURNONLYFSDIRS;
  end;
  P := ShBrowseForFolder(BrowseInfo);
  if P <> nil then
  begin
    ShGetPathFromIDList(P, Path);
    DirEdit.Text := Path;
  end;
end;

procedure TCoinstForm.BankCheckBoxClick(Sender: TObject);
var
  I: Integer;
  B: Boolean;
begin
  NextButton.Enabled := (Step=0) and KeyCheckBox.Checked
    or (Step=1) and BankCheckBox.Checked
    or (Step=2) and ItcsCheckBox.Checked;
  B := False;
  I := Step;
  while not B and (I<3) do
  begin
    B := (I=0) and KeyCheckBox.Checked
      or (I=1) and BankCheckBox.Checked
      or (I=2) and ItcsCheckBox.Checked;
    Inc(I);
  end;
  if B or (Step<3) then
    SkipButton.Caption := 'Пропустить'
  else begin
    SkipButton.Caption := 'Закрыть';
    NextButton.Hide;
  end;
  {if NextButton.Visible and NextButton.Enabled and not SkipButton.Focused then
    try
      NextButton.SetFocus;
    except
    end
  else
  if SkipButton.Visible and SkipButton.Enabled then
    try
      SkipButton.SetFocus;
    except
    end}
end;

end.

