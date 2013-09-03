unit OneCBuhFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons, Mask, ToolEdit, Registry, Registr, ExtCtrls, Utilits,
  WideComboBox;

type
  TOneCBuhForm = class(TForm)
    OneCBuhGroupBox: TGroupBox;
    BCGroupBox: TGroupBox;
    VersComboBox: TComboBox;
    VersLabel: TLabel;
    GetPresetBitBtn: TBitBtn;
    SavePresetBitBtn: TBitBtn;
    BasesLabel: TLabel;
    ImportFilenameEdit: TFilenameEdit;
    CodeLabel: TLabel;
    CodeComboBox: TComboBox;
    PresetsLabel: TLabel;
    CloseBitBtn: TBitBtn;
    PresetNameEdit: TEdit;
    ParamsPresetEdit: TEdit;
    ParamsPresetLabel: TLabel;
    ProtoGroupBox: TGroupBox;
    ProtoMemo: TMemo;
    FileNamePanel: TPanel;
    PresetsComboBox: TWideComboBox;
    BasesComboBox: TWideComboBox;
    BasePathLabel: TLabel;
    BasePathEdit: TEdit;
    FileNameLabel: TLabel;
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure VersComboBoxClick(Sender: TObject);
    procedure BasesComboBoxClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure GetPresetBitBtnClick(Sender: TObject);
    procedure FileNamePanelMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FileNamePanelMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FileNamePanelClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure BasesComboBoxKeyPress(Sender: TObject; var Key: Char);
    procedure PresetsComboBoxClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  OneCBuhForm: TOneCBuhForm;

implementation

{$R *.DFM}

procedure TOneCBuhForm.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key=VK_ESCAPE then
    ModalResult := mrCancel;
end;

procedure ShowProtoMes(S: string);
begin
  OneCBuhForm.ProtoMemo.Lines.Add(S);
end;

procedure TOneCBuhForm.VersComboBoxClick(Sender: TObject);
const
  MesTitle: PChar = 'Инициализация списка 1C';
  RegPath0: PChar = 'Software\1C\1Cv7\7.7\Titles';
  RegPath1: PChar = 'HKEY_CURRENT_USER\Software\1C\1Cv7\7.7\Defaults';
  RegName0: PChar = 'Max Communication Buffer Size';
  //ParValue0: Integer = 65827;
var
  Reg: TRegistry;
  Seted: Boolean;
  RegPathN: PChar;
  BuhVer: Integer;
  //S: string;
  //F: TextFile;
  //SD: array[0..255] of Char;
begin
  BuhVer := VersComboBox.ItemIndex;
  if VersComboBox.ItemIndex>=0 then
  begin  {проход по известным версиям 1C}
    Seted := False;
    Reg := TRegistry.Create;
    with Reg do
    begin
      try
        case BuhVer of
          0:
            begin
              RootKey := HKEY_CURRENT_USER;
              RegPathN := RegPath0;
            end;
          else begin
            ShowProtoMes('Быстрая настройка данной конфигурации пока не поддерживается');
            RegPathN := '';
          end;
        end;
        if RegPathN<>'' then
        begin
          if OpenKey(RegPathN, False) then        
          try
            GetValueNames(BasesComboBox.Items);
            {if ParamIndex=0 then
            begin
              try
                if ReadInteger(RegName0) >= ParValue0 then
                begin
                  Seted := True;
                  if Sender<>nil then
                  begin
                    if MessageBox(Handle, 'Параметр уже установлен в нормальное значение.'#13#10
                      +'Желаете заново переустановить его?', MesTitle,
                      MB_YESNOCANCEL or MB_DEFBUTTON2 or MB_ICONINFORMATION) = ID_YES
                    then
                      Seted := False;
                  end;
                end;
              except
                Seted := False;
              end;
              if not Seted then
              begin
                Seted := False;
                try
                  WriteInteger(RegName0, ParValue0);
                  Seted := True;
                except
                  Seted := False;
                end;
              end
              else
                Seted := False;
            end
            else
              Seted := (Sender<>nil) and (MessageBox(Handle,
                'СКЗИ уже зарегистрировано в системе.'#13#10
                +'Желаете заново переустановить его?', MesTitle,
                MB_YESNOCANCEL or MB_DEFBUTTON2 or MB_ICONINFORMATION)=ID_YES);}
          finally
            CloseKey;
          end
          else
            ShowProtoMes('Не удалось открыть ветку реестра '+RegPathN);
        end;
      finally
        Free;
      end;
    end;
  end;
  BasesComboBox.Enabled := BasesComboBox.Items.Count>0;
  BasesComboBoxClick(nil);
end;

function GetPresetParam(S: string; NeedLevel, NeedIndex: Integer;
  var ResPar: string; var Level, Index: Integer): Boolean;
var
  I, StartPos: Integer;

  procedure TakeParamAndExit(EndPos: Integer);
  begin
    {  showmessage('555: ['+S+'] I='+IntToStr(I)+' Lev='+IntToStr(Level)+' Ind='+IntToStr(Index)
        +' StrP='+IntToStr(StartPos)+' EndP='+IntToStr(EndPos));}
    ResPar := ResPar + Copy(S, StartPos, EndPos-StartPos+1);
    Result := True;
  end;

begin
  Result := False;
  StartPos := 1;
  I := 0;
  while not Result and (I<Length(S)) do
  begin
    Inc(I);
    //  showmessage('222: ['+S+'] I='+IntToStr(I)+' Lev='+IntToStr(Level)+' Ind='+IntToStr(Index));
    while (I<=Length(S)) and not(S[I] in ['{','}',',']) do
      Inc(I);

    //showmessage('333: ['+S+'] I='+IntToStr(I)+' Lev='+IntToStr(Level)+' Ind='+IntToStr(Index));

    if I<=Length(S) then
    begin
      //showmessage('444: ['+S+'] I='+IntToStr(I)+' Lev='+IntToStr(Level)+' Ind='+IntToStr(Index));
      if S[I]=',' then
      begin
        if Level=NeedLevel then
        begin
          Inc(Index);
      {showmessage('66: ['+S+'] I='+IntToStr(I)+' Lev='+IntToStr(Level)+' Ind='+IntToStr(Index)
        +' StrP='+IntToStr(StartPos));}

          if Index=NeedIndex then
            StartPos := I+1
          else
            if Index=NeedIndex+1 then
              TakeParamAndExit(I-1);
      //showmessage('77: ['+S+'] I='+IntToStr(I)+' Lev='+IntToStr(Level)+' Ind='+IntToStr(Index)
      //  +' StrP='+IntToStr(StartPos));
        end;
      end
      else begin
      {showmessage('88: ['+S+'] I='+IntToStr(I)+' Lev='+IntToStr(Level)+' Ind='+IntToStr(Index)
        +' StrP='+IntToStr(StartPos)); }
        if S[I]='{' then
        begin
          Inc(Level);
          if Level=NeedLevel then
          begin
            StartPos := I+1;
            if Index=0 then
              Inc(Index);
          end;
        end
        else begin
          if (Level=NeedLevel) and (Index=NeedIndex) then
            TakeParamAndExit(I-1);
          Dec(Level);
        end;
      {showmessage('99: ['+S+'] I='+IntToStr(I)+' Lev='+IntToStr(Level)+' Ind='+IntToStr(Index)
        +' StrP='+IntToStr(StartPos)); }
      end;
    end;
  end;
end;

var
  ParamSettings: Integer = 0;

procedure ClearPresetParam(var S: string; NeedSet: Integer; var ParSet: Integer);
begin
  ParSet := 0;
  S := Trim(S);
  if ((NeedSet and 1)>0) and (Length(S)>1) and (S[1]='{') and (S[Length(S)]='}') then
  begin
    S := Trim(Copy(S, 2, Length(S)-2));
    ParSet := 1;
  end;
  if ((NeedSet and 2)>0) and (Length(S)>1) and (S[1]='"') and (S[Length(S)]='"') then
  begin
    S := Trim(Copy(S, 2, Length(S)-2));
    ParSet := ParSet or 2;
  end;
end;

function FindPresetParam(S: string; StartInd: Integer;
  var FindValue: string; ParName: string; var FindIndex: Integer): Boolean;
var
  I, Level1, Level2, Index2, J: Integer;
  S1,S2: string;
begin
  FindValue := '';
  I := StartInd;
  ParName := RusUpperCase(Trim(ParName));
            //showmessage('11: S=['+S+']  ParN=['+ParName+']');
  repeat
    S1 := '';
    Level1 := 0;
    FindIndex := 0;
    if GetPresetParam(S, 1, I, S1, Level1, FindIndex) then
    begin // перебор объектов {параметр,значение}
            //showmessage('22: объект S1=['+S1+']  I=['+IntToStr(I)+']');
      S2 := '';
      Level2 := 0;
      Index2 := 0;
      if GetPresetParam(S1, 1, 1, S2, Level2, Index2) then
      begin // взятие имени объекта
        ClearPresetParam(S2, 3, J);
        S2 := RusUpperCase(Trim(S2));
            //showmessage('33: имя S2=['+S2+']  ParN=['+ParName+']');
        if ParName=S2 then
        begin  // проверка имени
            //showmessage('!!!44: имя S2=['+S2+']  объект S1=['+S1+']');
          FindIndex := I;
          I := -1; // выход из цикла
          S2 := '';
          Level2 := 0;
          Index2 := 0;
          if GetPresetParam(S1, 1, 2, S2, Level2, Index2) then
          begin // взятие значения
              //showmessage('УРА! 55: значение S2=['+S2+']  ParN=['+ParName+']');
            ClearPresetParam(S2, 3, J);
            FindValue := S2;
          end;
        end;
      end;
      Inc(I);
    end
    else
      I := -1;
  until (I<=0) or (S='');
  if I<0 then
    FindIndex := -1;
end;

procedure TOneCBuhForm.BasesComboBoxClick(Sender: TObject);
const
  MesTitle: PChar = 'Чтение пресетов 1С';
  OneC77SetupFile = 'rh418.lst';
var
  S,FullS,S1,S2,BasicPreset: string;
  F: TextFile;
  I, Level, Index: Integer;
begin
  SavePresetBitBtn.Enabled := False;
  if BasesComboBox.ItemIndex>=0 then
  begin
    PresetsComboBox.Items.Clear;
    S := BasesComboBox.Items[BasesComboBox.ItemIndex];
    NormalizeDir(S);
    BasePathEdit.Text := S;
    case BasesComboBox.ItemIndex of
      0:
        begin
          S := S+'rh418.lst';
          AssignFile(F, S);
          FileMode := 0;
          {$I-} Reset(F); {$I+}
          if IOResult=0 then
          begin
            try
              while not Eof(F) and (S1='') do
              begin
                ReadLn(F, S1);
                FullS := FullS+S1;
              end;
            finally
              CloseFile(F);
            end;
            SavePresetBitBtn.Enabled := True;
            I := 1;
            //showmessage('!!: ['+FullS+'] I='+IntToStr(I));
            BasicPreset := '';
            repeat
              S1 := '';
              Level := 0;
              Index := 0;
              if GetPresetParam(FullS, 1, I, S1, Level, Index) then
              begin
                if I=1 then
                begin
                  ClearPresetParam(S1, 3, ParamSettings);
                  if (Length(S1)>0) and (S1[1]='@') then
                    Delete(S1, 1, 1);
                  BasicPreset := RusUpperCase(S1);
                end
                else begin
                  S := '';
                  S2 := '';
                  Level := 0;
                  Index := 0;
                  if GetPresetParam(S1, 1, 1, S2, Level, Index) then
                  begin
                    ClearPresetParam(S2, 3, ParamSettings);
                    S := S2;
                  end;
                  S2 := '';
                  if FindPresetParam(S1, 2, S2, 'ИмяФайлаВыгрузки', Index) then
                  begin
                    ClearPresetParam(S2, 3, ParamSettings);
                    S := S + ' | ' + S2;
                  end;
                  PresetsComboBox.Items.Add(S);
                end;
                //showmessage('ZZZ: ['+S1+'] I='+IntToStr(I));
                Inc(I);
              end
              else
                I := -1;
            until (FullS='') or (I<0);
            if PresetsComboBox.Items.Count>0 then
            begin
              I := 0;
              repeat
                S := PresetsComboBox.Items.Strings[I];
                Level := Pos('|', S);
                if Level>0 then
                  S := Trim(Copy(S, 1, Level-1));
                S := RusUpperCase(S);
                Inc(I);
              until (I>=PresetsComboBox.Items.Count) or (S=BasicPreset);
              if I<=PresetsComboBox.Items.Count then
                PresetsComboBox.ItemIndex := I-1;
            end;
          end
          else
            ShowProtoMes('Ошибка открытия файла настроек 1С'#13#10'['+S+']');
            {MessageBox(Handle, PChar(
              'Ошибка открытия файла настроек 1С'#13#10'['+S+']'), MesTitle, MB_ICONWARNING
              or MB_YESNOCANCEL);}
        end;
    end;
  end
  else
    BasePathEdit.Text := '';
  PresetsComboBox.Enabled := PresetsComboBox.Items.Count>0;
end;

procedure TOneCBuhForm.FormCreate(Sender: TObject);
var
  ImportDosCharset: Boolean;
begin
  ImportFilenameEdit.FileName := DecodeMask('$(ImportFile)', 5, CommonUserNumber);
  if not GetRegParamByName('ImportDosCharset', CommonUserNumber, ImportDosCharset) then
    ImportDosCharset := False;
  if ImportDosCharset then
    CodeComboBox.ItemIndex := 1
  else
    CodeComboBox.ItemIndex := 0;
end;

procedure TOneCBuhForm.GetPresetBitBtnClick(Sender: TObject);
var
  ImportFile: string;
begin
  ImportFilenameEdit.FileName := ParamsPresetEdit.Text;
  FileNamePanelClick(nil);
end;

procedure TOneCBuhForm.FileNamePanelMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbLeft then
    (Sender as TPanel).BevelOuter := bvLowered;
end;

procedure TOneCBuhForm.FileNamePanelMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  (Sender as TPanel).BevelOuter := bvRaised;
end;

procedure TOneCBuhForm.FileNamePanelClick(Sender: TObject);
const
  MesTitle: PChar = 'Установка параметров';
var
  ImportFile: string;
  ImportDosCharset: Boolean;
begin
  if (Sender=nil) or (MessageBox(Handle, 'Вы желаете сохранить настройку?',
    MesTitle, MB_YESNOCANCEL or MB_ICONINFORMATION)=ID_YES) then
  begin            
    ImportFile := ImportFilenameEdit.FileName;
    if not SetRegParamByName('ImportFile', CommonUserNumber, True, ImportFile) then
      ShowProtoMes('Ошибка сохранения параметра ImportFile');
      {MessageBox(Handle, 'Ошибка сохранения параметра ImportFile',
        MesTitle, MB_OK or MB_ICONWARNING);}
    ImportDosCharset := CodeComboBox.ItemIndex=1;
    if not SetRegParamByName('ImportDosCharset', CommonUserNumber, True, BooleanToStr(ImportDosCharset)) then
      ShowProtoMes('Ошибка сохранения параметра ImportDosCharset');
      {MessageBox(Handle, 'Ошибка сохранения параметра ImportDosCharset',
        MesTitle, MB_OK or MB_ICONWARNING);}
    ShowProtoMes('Настройки сохранены в Клиент-Банке');
  end;
end;

procedure TOneCBuhForm.FormShow(Sender: TObject);
begin
  if VersComboBox.Items.Count>0 then
  begin
    VersComboBox.ItemIndex := 0;
    VersComboBoxClick(nil);
    Application.ProcessMessages;
  end;
  PresetsComboBox.DroppedWidth := ClientWidth - PresetsComboBox.Left - 10;
end;

procedure TOneCBuhForm.BasesComboBoxKeyPress(Sender: TObject;
  var Key: Char);
begin
  Key := #0;
end;

procedure TOneCBuhForm.PresetsComboBoxClick(Sender: TObject);
var
  S: string;
  I: Integer;
begin
  GetPresetBitBtn.Enabled := False;
  if PresetsComboBox.ItemIndex>=0 then
  begin
    S := PresetsComboBox.Items.Strings[PresetsComboBox.ItemIndex];
    I := Pos('|', S);
    if I>0 then
    begin
      Delete(S, 1, I);
      S := Trim(S);
    end;
    ParamsPresetEdit.Text := S;
    GetPresetBitBtn.Enabled := S<>'';
  end;
end;

end.
