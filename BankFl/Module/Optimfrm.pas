unit Optimfrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ComCtrls, ExtCtrls, Btrieve, Basbn, Utilits, BankCnBn, CommCons,
  BtrDS;

type
  TOptimForm = class(TForm)
    ActionPanel: TPanel;
    StatusBar: TStatusBar;
    AbonMemo: TMemo;
    AnalyseButton: TButton;
    OptimiseButton: TButton;
    AgrCheckBox: TCheckBox;
    FileCheckBox: TCheckBox;
    OptProgressBar: TProgressBar;
    MailCheckBox: TCheckBox;
    procedure AnalyseButtonClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormDestroy(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure ShowMes(S: string);
    procedure AddProto(Level: Byte; Title: PChar; S: string);
    procedure InitProgressBar(AMin, AMax: Integer);
    procedure SetProgress(APos: Integer);
    procedure NextProgress;
    procedure HideProgressBar;
  end;

var
  OptimForm: TOptimForm;
  ObjList: TList = nil;
  DLLList: TList = nil;

implementation

{$R *.DFM}
var
  BaseS: TBtrBase = nil;
  BaseR: TBtrBase = nil;
  AbonDataSet, AccDataSet, SendFileDataSet, FileDataSet, LetterDataSet: TExtBtrDataSet;
  Process: Boolean = False;

const
  piProgress = 0;
  piMes = 1;

procedure TOptimForm.FormCreate(Sender: TObject);
begin
  ObjList.Add(Self);
  BaseS := nil;
  BaseR := nil;
  BaseS := TBtrBase.Create;
  BaseR := TBtrBase.Create;
  OptProgressBar.Parent := StatusBar;
end;

procedure TOptimForm.InitProgressBar(AMin, AMax: Integer);
const
  Border=2;
var
  X: Integer;
begin
  StatusBar.Panels[piProgress].Width := OptProgressBar.Width;
  X := 0;
  X := X+StatusBar.Panels[piProgress].Width+Border;
  with OptProgressBar do
  begin
    SetBounds(X, Border, Width, StatusBar.Height - Border);
    try
      Min := 0;
      Position := 0;
      Max := AMax;
      Min := AMin;
      Position := Min;
    except
    end;
    Visible := True;
  end;
end;

procedure TOptimForm.SetProgress(APos: Integer);
begin
  with OptProgressBar do
  begin
    if APos<Min then
      APos := Min;
    if APos>Max then
      APos := Max;
    Position := APos;
  end;
end;

procedure TOptimForm.NextProgress;
begin
  SetProgress(OptProgressBar.Position+1);
end;

procedure TOptimForm.HideProgressBar;
begin
  OptProgressBar.Hide;
  StatusBar.Panels[piProgress].Width := 0;
end;

procedure TOptimForm.ShowMes(S: string);
begin
  StatusBar.Panels[piMes].Text := S;
  Application.ProcessMessages;
end;

procedure TOptimForm.AddProto(Level: Byte; Title: PChar; S: string);
begin
  ProtoMes(Level, Title, S);
  if Level<plInfo then
    S := LevelToStr(Level)+': '+S;
  //ProtoMemo.Lines.Add(S);
  Application.ProcessMessages;
end;

function OpenSendBase: Boolean;
const
  MesTitle: PChar = 'Открытие базы исходящих пакетов';
var
  Res: Integer;
  FN: string;
begin
  if BaseS.Active then
    Res := 0
  else begin
    FN := UserBaseDir+'doc_s.btr';
    OptimForm.ShowMes(StrPas(MesTitle)+'...');
    Res := BaseS.Open(FN, baNormal);
    OptimForm.ShowMes('');
    if Res<>0 then
      OptimForm.AddProto(plError, MesTitle, PChar('Не могу открыть базу '
        +FN+' BtrErr='+IntToStr(Res)));
  end;
  Result := Res=0;
end;

function OpenRecvBase: Boolean;
const
  MesTitle: PChar = 'Открытие базы входящих пакетов';
var
  Res: Integer;
  FN: string;
begin
  if BaseR.Active then
    Res := 0
  else begin
    FN := UserBaseDir+'doc_r.btr';
    OptimForm.ShowMes(StrPas(MesTitle)+'...');
    Res := BaseR.Open(FN, baNormal);
    OptimForm.ShowMes('');
    if Res<>0 then
      OptimForm.AddProto(plError, MesTitle, PChar('Не могу открыть базу '
        +FN+' BtrErr='+IntToStr(Res)));
    end;
  Result := Res=0;
end;

procedure TOptimForm.FormDestroy(Sender: TObject);
begin
  BaseS.Free;
  BaseS := nil;
  BaseR.Free;
  BaseR := nil;
  ObjList.Remove(Self);
  OptimForm := nil;
end;

procedure TOptimForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
end;

procedure TOptimForm.AnalyseButtonClick(Sender: TObject);
const
  MesTitle: PChar = 'Анализ почтовых баз';
var
  Res, ResA, Key1, Key2, Len, AbonCounter,I: Integer;
  AbonRec: TAbonentRec;
  RcvPack: TRcvPack;
  SndPack: TSndPack;
  AccRec: TAccRec;
  LetterRec: TLetterRec;
  NameR: TAbonName;
  AbonList: array of string[8];
  AbonIsDel: Boolean;
begin
  AbonDataSet := GlobalBase(biAbon);
  AccDataSet := GlobalBase(biAcc);
  SendFileDataSet := GlobalBase(biSendFile);
  FileDataSet := GlobalBase(biFile);
  LetterDataSet := GlobalBase(biLetter);
  AbonCounter := 0;
  AbonIsDel := False;
  if Process then
    begin
    AnalyseButton.Enabled := False;
    ShowMes('Прекращение процесса...');
    Process := False;
    end
  else
    begin
    AnalyseButton.Caption := 'Прервать';
    OptimiseButton.Enabled := False;
    Process := True;
    //while Process do
    //  begin
      //InitProgressBar(0,7);
      ShowMes('Анализ базы отправленных пакетов...');
      //NextProgress(0);
      if OpenSendBase then
        begin
        Len := SizeOf(SndPack);
        Res := BaseS.GetLast(SndPack, Len, Key1, 2);
        if (Res=0) or (Res=22) then
          begin
          Len := SizeOf(SndPack);
          Res := BaseS.GetFirst(SndPack, Len, Key2, 2);
          InitProgressBar(Key1,Key2);
          while ((Res=0) or (Res=22)) and Process do
            begin
            //LenP := Len - (SizeOf(TSndPack) - MaxPackSize);
            FillChar(NameR, SizeOf(NameR), #0);
            StrLCopy(NameR, SndPack.spNameR, 9);
            I := StrLen(NameR)-1;
            while (I>=0) and (NameR[I]=' ') do
              begin
              NameR[I] := #0;
              Dec(I);
              end;
            StrUpper(NameR);
            I := AbonCounter;
            while (I>0) and not AbonIsDel do
              begin
              Dec(I);
              if (AbonList[I] = NameR) then
                AbonIsDel := True;
              end;
            if not AbonIsDel then
              begin
              Len := SizeOf(AbonRec);
              if SndPack.spByteS=PackByteSC then
                ResA := AbonDataSet.BtrBase.GetEqual(AbonRec, Len, NameR, 2)
              else
                ResA := AbonDataSet.BtrBase.GetEqual(AbonRec, Len, NameR, 1);
              if ResA<>0 then
                begin
                if ResA=4 then
                  begin
                  AbonList[AbonCounter] := NameR;
                  Inc(AbonCounter);
                  MessageBox(ParentWnd,Pchar(IntToStr(AbonCounter)),'StepMessage',mb_ok);  //Отладка
                  end
                else
                  ProtoMes(plWarning, MesTitle,
                    'Ошибка поиска абонента ['+NameR+'] BtrErr='+IntToStr(ResA));
                end;
              if ((AbonRec.abLock and (alSend or alRecv))=alSend or alRecv) then
                begin
                MessageBox(ParentWnd,NameR,'StepMessage',mb_ok);  //Отладка
                Len := SizeOf(AccRec);
                ResA := AccDataSet.BtrBase.GetEqual(AccRec,Len,NameR,0);
                if (ResA<>0) then
                  begin
                  Abonlist[AbonCounter] := NameR;
                  Inc(AbonCounter);
                  end;
                end;
              end;
            Len := SizeOf(SndPack);
            Res := BaseS.GetNext(SndPack, Len, Key2, 2);
            end;
          end;
        for I:=0 to AbonCounter do
          AbonMemo.Lines[I] := AbonList[I];
        AnalyseButton.Caption := 'Анализ';
        OptimiseButton.Enabled := True;
        Process := False;
        end;

      //end;
    end;
end;

end.





