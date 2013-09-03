unit PostStatFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Menus, ComCtrls, ExtCtrls, StdCtrls, Buttons, ToolWin, Placemnt, ImgList,
  Grids, ExTxFile, Mask, ToolEdit, Utilits, Spin;

const
  WM_MAKEUPDATE = WM_USER + 156;

type
  TPostStatForm = class(TForm)
    StatusBar: TStatusBar;
    PageControl: TPageControl;
    WorkTabSheet: TTabSheet;
    EventTabSheet: TTabSheet;
    MachTabSheet: TTabSheet;
    ToolBar: TToolBar;
    RefreshToolButton: TToolButton;
    ImageList: TImageList;
    MainFormStorage: TFormStorage;
    BreakToolButton1: TToolButton;
    StopToolButton: TToolButton;
    AllAbonStringGrid: TStringGrid;
    SocketListBox: TListBox;
    ProtoMemo: TMemo;
    HorzSplitter: TSplitter;
    ToolButton1: TToolButton;
    LastDayToolButton: TToolButton;
    LastWeekToolButton: TToolButton;
    LastMonthToolButton: TToolButton;
    LastYearToolButton: TToolButton;
    CommSetupPanel: TPanel;
    PeriodLabel: TLabel;
    PeriodComboBox: TComboBox;
    FirstDateEdit: TDateEdit;
    LastDateEdit: TDateEdit;
    FirstPanel: TPanel;
    LastPanel: TPanel;
    InfoTabSheet: TTabSheet;
    MachListBox: TListBox;
    EventMemo: TMemo;
    InfoSetupPanel: TPanel;
    MaxEnterSpinEdit: TSpinEdit;
    MaxLabel: TLabel;
    InfoGroupBox: TGroupBox;
    ManyConnListBox: TListBox;
    ProgressBar: TProgressBar;
    ProtoFileGroupBox: TGroupBox;
    ProtoFilenameEdit: TFilenameEdit;
    ProtoFileComboBox: TComboBox;
    ToolButton2: TToolButton;
    SaveToolButton: TToolButton;
    SaveDialog: TSaveDialog;
    procedure RefreshToolButtonClick(Sender: TObject);
    procedure StopToolButtonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure HorzSplitterCanResize(Sender: TObject; var NewSize: Integer;
      var Accept: Boolean);
    procedure AllAbonStringGridDrawCell(Sender: TObject; ACol,
      ARow: Integer; Rect: TRect; State: TGridDrawState);
    procedure AllAbonStringGridMouseDown(Sender: TObject;
      Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure FormShow(Sender: TObject);
    procedure LastDayToolButtonClick(Sender: TObject);
    procedure FirstPanelMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FirstPanelMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FirstPanelClick(Sender: TObject);
    procedure LastPanelClick(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure ProtoFileComboBoxClick(Sender: TObject);
    procedure SaveToolButtonClick(Sender: TObject);
  private
    procedure WMMakeUpdate(var Message: TMessage); message WM_MAKEUPDATE;
  public
    procedure AddProto(S: string);
    procedure UpdateAbonInfo(T, A: string; Mode: Byte; P: string);
    function MakeCrit(C, R: Integer): string;
    procedure InitProgressBar(AMin, AMax: Integer);
    procedure HideProgressBar;
  end;

var
  PostStatForm: TPostStatForm;

implementation

{$R *.DFM}

const
  giNumber     = 0;
  giLogin      = 1;
  giPeriod     = 2;
  giTime1      = 3;
  giTime2      = 4;
  giSessions   = 5;
  giSend       = 6;
  giRecv       = 7;
  giPostVers   = 8;
  giProgVers   = 9;
  giLastId     = 10;
  giHost       = 11;
  giAddress    = 12;

procedure TPostStatForm.FormCreate(Sender: TObject);
begin
  ShortDateFormat := 'dd.MM.yyyy';
  DateSeparator := '.';
  LongTimeFormat := 'h:mm:ss';
  with AllAbonStringGrid do
  begin
    ColWidths[giNumber] := 23;
    ColWidths[giPeriod] := 62;
    ColWidths[giTime1] := 57;
    ColWidths[giTime2] := 57;
    ColWidths[giLogin] := 65;
    ColWidths[giSessions] := 42;
    ColWidths[giSend] := 40;
    ColWidths[giRecv] := 40;
    ColWidths[giPostVers] := 40;
    ColWidths[giProgVers] := 40;
    ColWidths[giLastId] := 40;
    ColWidths[giHost] := 85;
    ColWidths[giAddress] := 220;

    {Cells[giNumber, 0] := 'N'}
    Cells[giPeriod, 0] := 'Период';
    Cells[giTime1, 0] := 'Время1';
    Cells[giTime2, 0] := 'Время2';
    Cells[giLogin, 0] := 'Позывной';
    Cells[giSessions, 0] := 'Сессий';
    Cells[giSend, 0] := 'Отпр';
    Cells[giRecv, 0] := 'Прин';
    Cells[giPostVers, 0] :=  'ВерСв';
    Cells[giProgVers, 0] :=  'ВерПр';
    Cells[giLastId, 0] :=  'Заход';
    Cells[giHost, 0] :=  'Хост';
    Cells[giAddress, 0] :=  'Адрес';
  end;
  ProgressBar.Parent := StatusBar;
end;

const
  ProgressPanelIndex = 0;

procedure TPostStatForm.InitProgressBar(AMin, AMax: Integer);
const
  Border=2;
var
  I, X: Integer;
begin
  StatusBar.Panels[ProgressPanelIndex].Width := ProgressBar.Width+Border;
  with ProgressBar do
  begin
    X := Border;
    for I := 0 to ProgressPanelIndex-1 do
      X := X+StatusBar.Panels[I].Width;
    SetBounds(X, Border, Width, StatusBar.Height - Border);
    Min := AMin;
    Position := Min;
    Max := AMax;
    Show;
  end;
end;

procedure TPostStatForm.HideProgressBar;
begin
  ProgressBar.Hide;
  StatusBar.Panels[ProgressPanelIndex].Width := 0;
end;

procedure TPostStatForm.AddProto(S: string);
begin
  with ProtoMemo.Lines do
  begin
    while Count>100 do
      Delete(0);
    Add(DateTimeToStr(Now)+'> '+S);
  end;
end;

var
  Periodity: Integer = 0;

function MakePer(D: string): string;
var
  D1: TDate;
begin
  case Periodity of
    0: {день}
      Result := Copy(D, 1, 10);
    1: {неделя}
      begin
        D1 := StrToDate(Copy(D, 1, 10));
        D1 := Int((D1-2)/7)*7+2;
        Result := DateToStr(D1)+'-'+DateToStr(D1+6);
      end;
    2: {месяц}
      Result := Copy(D, 4, 7);
    else {год}
      Result := Copy(D, 7, 4);
  end;
end;

function DateToCrit(D: string): string;
begin
  Result := Copy(D, 7, 4) + Copy(D, 4, 2) + Copy(D, 1, 2);
end;

function PerToCrit(D: string): string;
begin
  case Periodity of
    0,1: {день}
      Result := DateToCrit(D);
    2: {месяц}
      Result := Copy(D, 4, 2) + Copy(D, 1, 2);
    else {год}
      Result := Copy(D, 7, 4);
  end;
end;

function DateInPrd(D, P: string): Boolean;
begin
  Result := MakePer(D)=P;
end;

procedure DeleteRow(SG: TStringGrid; CR: Integer);
var
  R, C: Integer;
begin
  with SG do
  begin
    for R := CR to RowCount-2 do
    begin
      for C := 0 to ColCount-1 do
      begin
        Cells[C, R] := Cells[C, R+1];
      end;
    end;
    RowCount := RowCount-1;
  end;
end;

const
  umConnect  = 0;
  umHello    = 1;
  umSend     = 2;
  umRecv     = 3;
  umDelt     = 4;
  umDisconn  = 5;

var
  MaxEnter: Integer;

procedure TPostStatForm.UpdateAbonInfo(T, A: string; Mode: Byte; P: string);
var
  AI, I, R, CR, J: Integer;
  L, P2, S: string;
begin
  with AllAbonStringGrid do
  begin
    try
      AI := StrToInt(A);
    except
      AI := 0;
    end;
    //showmessage(IntToStr(Mode)+': '+T+' Ab=('+A+') ['+P+']'+IntToStr(AI));
    I := SocketListBox.Items.IndexOfObject(TObject(AI));
    if (I>=0) and ((Mode=umDisconn) or (Mode=umConnect)) then
    begin
      SocketListBox.Items.Delete(I);
      I := -1;
    end;
    if Mode=umConnect then
    begin
      SocketListBox.Items.AddObject('!'+P, TObject(AI));
      I := SocketListBox.Items.Count-1;
    end
    else begin
      if I>=0 then
      begin
        L := '';
        P2 := SocketListBox.Items.Strings[I];
        if Mode=umHello then
        begin
          J := Pos(' ', P);
          if J>0 then
          begin
            L := Copy(P, 1, J-1);
            Delete(P, 1, J);
          end;
          SocketListBox.Items.Strings[I] := L;
          I := SocketListBox.Items.Count;
          if I>=MaxEnter then
          begin
            S := '';
            for J := 0 to SocketListBox.Items.Count-1 do
              S := S+'|'+SocketListBox.Items.Strings[J];
            ManyConnListBox.Items.Add(IntToStr(ManyConnListBox.Items.Count+1)
              +'. '+T+'  '+FillZeros(I, 2)+' '+S);
          end;
        end
        else begin
          if (Length(P2)>0) and (P2[1]<>'!') then
            L := P2;
        end;
        if Length(L)>0 then
        begin
          CR := 0;
          R := 1;
          while (R<RowCount) and (CR=0) do
          begin
            if Length(Cells[giLogin, R])>0 then
            begin
              if (Cells[giLogin, R]=L) and DateInPrd(T, Cells[giPeriod, R]) then
                CR := R;
              Inc(R);
            end
            else
              CR := R;
          end;
          if (CR=0) or (Length(Cells[giLogin, CR])=0)
            or (Length(Cells[giPeriod, CR])=0) then
          begin
            if CR=0 then
            begin
              RowCount := RowCount+1;
              CR := RowCount-1;
            end;
            Cells[giNumber, CR] := IntToStr(CR);
            Cells[giPeriod, CR] := MakePer(T);
            if Periodity=0 then
            begin
              Cells[giTime1, CR] := Copy(T, 12, 8);
              Cells[giTime2, CR] := Cells[giTime1, CR];
            end
            else begin
              Cells[giTime1, CR] := {Copy(}T{, 12, 8)};
              Cells[giTime2, CR] := Cells[giTime1, CR];
            end;
            Cells[giLogin, CR] := L;
            Cells[giSessions, CR] := '0';
            Cells[giSend, CR] := '0';
            Cells[giRecv, CR] := '0';
          end;
          if CR>0 then
          begin
            case Mode of
              umHello:
                begin
                  Delete(P2, 1, 1);
                  I := Pos('] ', P2);
                  if I>0 then
                  begin
                    Cells[giHost, CR] := Copy(P2, 2, I-2);
                    Delete(P2, 1, I+1);
                    Cells[giAddress, CR] := P2;
                  end;
                  if Periodity=0 then
                    Cells[giTime2, CR] := Copy(T, 12, 8)
                  else
                    Cells[giTime2, CR] := T;
                  I := Pos(' l', P);
                  if I>0 then
                  begin
                    Cells[giPostVers, CR] :=  Copy(P, 2, I-2);
                    Delete(P, 1, I+1);
                    I := Pos(' h', P);
                    if I>0 then
                    begin
                      P2 := Copy(P, 1, I-1);
                      Delete(P, 1, I+1);
                      Val('$'+P2, I, J);
                      if J<>0 then
                        I := 0;
                      Cells[giLastId, CR] :=  IntToStr(I);
                      I := Pos(' n', P);
                      if I>0 then
                      begin
                        Cells[giProgVers, CR] :=  Copy(P, I+2, Length(P)-I-1);
                      end;
                    end;
                  end;
                  P := Cells[giSessions, CR];
                  if Length(P)=0 then
                    I := 0
                  else begin
                    Val(P, I, J);
                    if J<>0 then
                      I := 0;
                  end;
                  Inc(I);
                  Cells[giSessions, CR] := IntToStr(I);
                end;
              umSend:
                begin
                  P := Cells[giSend, CR];
                  if Length(P)=0 then
                    I := 0
                  else begin
                    Val(P, I, J);
                    if J<>0 then
                      I := 0;
                  end;
                  Inc(I);
                  Cells[giSend, CR] := IntToStr(I);
                end;
              umRecv:
                begin
                  P := Cells[giRecv, CR];
                  if Length(P)=0 then
                    I := 0
                  else begin
                    Val(P, I, J);
                    if J<>0 then
                      I := 0;
                  end;
                  Inc(I);
                  Cells[giRecv, CR] := IntToStr(I);
                end;
            end;
          end;
        end
        else
          AddProto(T+' Ab='+A+' Нет позывного');
      end
      else
        if Mode<>umDisconn then
          AddProto(T+' Ab='+A+' Сокет не найден');
    end;
  end;
end;

var
  Process: Boolean = False;

procedure TPostStatForm.RefreshToolButtonClick(Sender: TObject);
const
  MesTitle: PChar = 'Анализ протокола';
var
  I, J: Integer;
  S, T, D1, D2, V, S2, Dir: string;
  F: TExtTextFile;
  SearchRec: TSearchRec;
  Res: Integer;
begin
  if not Process then
  begin
    Periodity := PeriodComboBox.ItemIndex;
    try
      MaxEnter := MaxEnterSpinEdit.Value;
    except
      MaxEnter := 2;
    end;
    Process := True;
    RefreshToolButton.Enabled := False;
    StopToolButton.Enabled := True;
    Application.ProcessMessages;
    try
      with AllAbonStringGrid do
      begin
        Hide;
        RowCount := 2;
        for J := 0 to ColCount-1 do
          Cells[J, 1] := '';
      end;
      with AllAbonStringGrid do
      begin
        case Periodity of
          0:
            begin
              ColWidths[giPeriod] := 62;
              ColWidths[giTime1] := 53;
              ColWidths[giTime2] := 53;
            end;
          else
            begin
              case Periodity of
                1:          
                  ColWidths[giPeriod] := 118;          
                2:          
                  ColWidths[giPeriod] := 47;          
                3:          
                  ColWidths[giPeriod] := 42;
              end;          
              ColWidths[giTime1] := 107;          
              ColWidths[giTime2] := 107;          
            end;          
        end;          
      end;          
      EventMemo.Lines.Clear;          
      MachListBox.Items.Clear;          
      ManyConnListBox.Items.Clear;
      if FirstDateEdit.Date=0 then          
        D1 := ''          
      else          
        D1 := DateToCrit(FirstDateEdit.Text);          
      if LastDateEdit.Date=0 then          
        D2 := ''
      else
        D2 := DateToCrit(LastDateEdit.Text);

      S := ProtoFilenameEdit.Text;
      Res := FindFirst(S, faAnyFile, SearchRec);
      if Res=0 then
      begin
        try
          Dir := ExtractFilePath(S);
          NormalizeDir(Dir);
          while (Res=0) and Process do
          begin
            if (SearchRec.Attr and faDirectory)=0 then
            begin
              S := Dir+SearchRec.Name;
              I := OpenTextFile(F, S);
              if I=0 then
              begin
                AddProto('Анализ '+S);
                I := GetFileSize(F.FH, nil);
                //showmessage(inttostr(I));
                InitProgressBar(0, I);
                while not F.Eof and Process do
                begin
                  ExtReadLn(F, S);
                  //showmessage(inttostr(F.ReadedBytes)+' m '+inttostr(ProgressBar.Max));
                  if (F.ReadedBytes<>ProgressBar.Position)
                    and (ProgressBar.Position<ProgressBar.Max) then
                  begin
                    if F.ReadedBytes>ProgressBar.Max then
                      ProgressBar.Position := ProgressBar.Max
                    else
                      ProgressBar.Position := F.ReadedBytes;
                  end;
                  T := DateToCrit(Copy(S, 1, 10));
                  if ((D1='') or (D1<=T)) and ((D2='') or (T<=D2)) then
                  begin
                    T := Copy(S, 1, 19);
                    if T[19]=' ' then
                    begin
                      T := Copy(T, 1, 10)+' 0'+Copy(T, 12, 7);
                      Delete(S, 1, 19);
                    end
                    else
                      Delete(S, 1, 20);
                    I := Pos(')', S);
                    if I>0 then
                    begin
                      S2 := Copy(S, 1, I);
                      Delete(S, 1, I+1);

                      I := Pos(' (', S2);
                      V := Copy(S2, 1, I-1);
                      //showmessage('['+V+']');
                      if (V='Warning') or (V='Error') or (V='FatalError') then
                      begin
                        I := Pos('Ab=', S);
                        if I>0 then
                        begin
                          V := Copy(S, I+3, 15);
                          I := Pos(' ', V);
                          if I=0 then
                            I := Length(V)+1;
                          V := Copy(V, 1, I-1);
                          try
                            I := StrToInt(V);
                          except
                            I := 0;
                          end;
                          I := SocketListBox.Items.IndexOfObject(TObject(I));
                          if I>=0 then
                            V := SocketListBox.Items.Strings[I]
                          else
                            V := IntToStr(I);
                        end
                        else
                          V := '';
                        EventMemo.Lines.Add(T+' <'+S2+'> '+S+' ['+V+']');
                      end;
                    end;
                    I := Pos('Connect Ab=', S);
                    if I>0 then
                    begin
                      J := Pos(' [', S);
                      UpdateAbonInfo(T, Copy(S, I+11, J-I-11),
                        umConnect, Copy(S, J+1, Length(S)-J));
                    end
                    else begin
                      I := Pos('Disconn Ab=', S);
                      if I>0 then
                      begin
                        S := Copy(S, I+11, Length(S)-I-10);
                        I := Pos(' ', S);
                        if I>0 then
                          S := Copy(S, 1, I-1);
                        UpdateAbonInfo(T, S, umDisconn, '');
                      end
                      else begin
                        I := Pos('Hello Ab=', S);
                        if I>0 then
                        begin
                          J := Pos(' [', S);
                          UpdateAbonInfo(T, Copy(S, I+9, J-I-9), umHello,
                            Copy(S, J+2, Length(S)-J-2));
                        end
                        else begin
                          I := Pos('Snd Ab=', S);
                          if I>0 then
                          begin
                            J := Pos(' Id=', S);
                            UpdateAbonInfo(T, Copy(S, I+7, J-I-7), umSend, '');
                          end
                          else begin
                            I := Pos('Rcv Ab=', S);
                            if I>0 then
                            begin
                              J := Pos(' Id=', S);
                              UpdateAbonInfo(T, Copy(S, I+7, J-I-7), umRecv, '');
                            end
                            else begin
                              I := Pos('Begin listen', S);
                              if I=0 then
                                I := Pos('Stop listen', S);
                              if I>0 then
                              begin
                                MachListBox.Items.Add(T+' '+S);
                              end;
                            end;
                          end;
                        end;
                      end;
                    end;
                  end;
                  Application.ProcessMessages;
                end;
                CloseTextFile(F);
                HideProgressBar;
              end
              else
                MessageBox(Handle, PChar('Не удалось открыть протокол '+S+' ('
                  +IntToStr(I)+')'), MesTitle, MB_OK or MB_ICONWARNING);
            end;
            Res := FindNext(SearchRec);
            Application.ProcessMessages;
          end;
        finally
          FindClose(SearchRec);
        end;
        AllAbonStringGridMouseDown(nil, mbLeft, [], 0, 0);
        AllAbonStringGrid.Row := 1;
        Show;
      end
      else
        MessageBox(Handle, PChar('Не удалось найти протоколы по маске '+S),
          MesTitle, MB_OK or MB_ICONWARNING);
    finally
      if Process then
        AddProto('Процесс завершен')
      else
        AddProto('Процесс прерван');
      Process := False;
      RefreshToolButton.Enabled := True;
      StopToolButton.Enabled := False;
    end;
  end;
end;

procedure TPostStatForm.StopToolButtonClick(Sender: TObject);
begin
  StopToolButton.Enabled := True;
  Process := False;
end;

procedure TPostStatForm.HorzSplitterCanResize(Sender: TObject;
  var NewSize: Integer; var Accept: Boolean);
begin
  Accept := NewSize>37;
end;

function TimeToCrit(D: string): string;
var
  I: Integer;
begin
  if Periodity=0 then
  begin
    I := 0;
    Result := '';
  end
  else begin
    I := 11;
    Result := DateToCrit(D);
  end;
  Result := Result + Copy(D, I+1, 2)+Copy(D, I+4, 2)+Copy(D, I+7, 2);
end;

function TPostStatForm.MakeCrit(C, R: Integer): string;
begin
  with AllAbonStringGrid do
  begin
    case C of
      1: Result := Cells[giLogin, R] + PerToCrit(Cells[giPeriod, R]);
      2: Result := PerToCrit(Cells[giPeriod, R]) + Cells[giLogin, R];
      3: Result := PerToCrit(Cells[giPeriod, R])
        + TimeToCrit(Cells[giTime1, R])+ Cells[giLogin, R];
      4: Result := PerToCrit(Cells[giPeriod, R])
        + TimeToCrit(Cells[giTime2, R])+ Cells[giLogin, R];
      5..7:
        begin
          Result := Cells[C, R];
          while Length(Result)<9 do
            Result := '0'+Result;
          Result := Result+PerToCrit(Cells[giPeriod, R])+Cells[giLogin, R];
        end;
      else
        Result := Cells[C, R];
    end;
  end;
end;

var
  SortIndex: Integer = 4;

procedure TPostStatForm.AllAbonStringGridMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  ACol, ARow: Longint;
  C, R, I, K: Integer;
  M, S, N: string;
begin
  if Sender<>nil then
  begin
    AllAbonStringGrid.MouseToCell(X, Y, ACol, ARow);
    if (ARow=0) and (ACol>0) then
    begin
      if ACol=Abs(SortIndex) then
        SortIndex := -SortIndex
      else
        SortIndex := ACol * SortIndex div Abs(SortIndex);
      AllAbonStringGrid.Repaint;
    end;
  end
  else
    ARow := 0;
  C := Abs(SortIndex);
  //StatusBar.SimpleText := IntToStr(C);
  if ARow=0 then
  with AllAbonStringGrid do
  begin
    Hide;
    if Row>0 then
      N := MakeCrit(2, Row)
    else
      N := '';
    for R := 1 to RowCount-1 do
    begin
      M := MakeCrit(C, R);
      I := R;
      for K := R+1 to RowCount-1 do
      begin
        S := MakeCrit(C, K);
        if (SortIndex>0) and (S<M) or (SortIndex<0) and (S>M) then
        begin
          M := S; I := K;
        end;
      end;
      if I<>R then
      begin
        for K := 0 to ColCount do
        begin
          M := Cells[K, R];
          S := Cells[K, I];
          Cells[K, R] := S;
          Cells[K, I] := M;
        end;
      end;
    end;
    R := 1;
    if Length(N)>0 then
      while (R<RowCount) and (MakeCrit(2, R)<>N) do
        Inc(R);
    if R<RowCount then
      Row := R;
    Show;
  end;
end;

procedure TPostStatForm.AllAbonStringGridDrawCell(Sender: TObject; ACol,
  ARow: Integer; Rect: TRect; State: TGridDrawState);
begin
  if (ARow=0) and (ACol=Abs(SortIndex)) then
  with Sender as TDrawGrid do
  begin
    if SortIndex>0 then
      Canvas.Brush.Color := clGreen
    else
      Canvas.Brush.Color := clYellow;
    Canvas.FillRect(Rect);
    Canvas.TextRect(Rect, Rect.Left+2, Rect.Top+2, AllAbonStringGrid.Cells[ACol, ARow]);
  end;
end;

procedure TPostStatForm.WMMakeUpdate(var Message: TMessage);
begin
  inherited;
  RefreshToolButtonClick(nil);
end;

procedure TPostStatForm.FormShow(Sender: TObject);
var
  K: Integer;
  S: string;
  AutoRun: Boolean;
begin
  AutoRun := False;
  PeriodComboBox.ItemIndex := 0;
  FirstDateEdit.Date := Date;
  LastDateEdit.Date := Date;
  K := 0;
  while K<ParamCount do
  begin
    Inc(K);
    S := Trim(ParamStr(K));
    if Length(S)>0 then
    begin
      if ((S[1]='-') or (S[1]='/')) and (Length(S)>1) then
      begin
        case UpCase(S[2]) of
          'R':
            AutoRun := True;
          'L':
            ProtoFilenameEdit.Text := Trim(Copy(S, 4, Length(S)-3));
          'F':
            FirstDateEdit.Text := Trim(Copy(S, 4, Length(S)-3));
          'T':
            LastDateEdit.Text := Trim(Copy(S, 4, Length(S)-3));
          'P':
            try
              PeriodComboBox.ItemIndex := StrToInt(Trim(Copy(S, 4, Length(S)-3)));
            except
            end;
          'S':
            try
              SortIndex := StrToInt(Trim(Copy(S, 4, Length(S)-3)));
            except
            end;
        end;
      end;
    end;
  end;
  if AutoRun then
    PostMessage(Handle, WM_MAKEUPDATE, 0, 0);
end;

procedure TPostStatForm.LastDayToolButtonClick(Sender: TObject);
var
  Year, Month, Day: Word;
begin
  LastDateEdit.Date := Date;
  case (Sender as TToolButton).Tag of
    0:
      begin
        FirstDateEdit.Date := LastDateEdit.Date;
        PeriodComboBox.ItemIndex := 0;
      end;
    1:
      begin
        FirstDateEdit.Date := Int((LastDateEdit.Date-2)/7)*7+2;
        PeriodComboBox.ItemIndex := 1;
      end;
    2:
      begin
        DecodeDate(LastDateEdit.Date, Year, Month, Day);
        {Day := 1;}
        if Month>1 then
          Dec(Month)
        else
          Dec(Year);
        FirstDateEdit.Date := EncodeDate(Year, Month, Day);
        PeriodComboBox.ItemIndex := 2;
      end;
    3:
      begin
        DecodeDate(LastDateEdit.Date, Year, Month, Day);
        {Day := 1;
        Month := 1;}
        Dec(Year);
        FirstDateEdit.Date := EncodeDate(Year, Month, Day);
        PeriodComboBox.ItemIndex := 3;
      end;
  end;
  RefreshToolButtonClick(nil);
end;

procedure TPostStatForm.FirstPanelMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbLeft then (Sender as TPanel).BevelOuter := bvLowered;
end;

procedure TPostStatForm.FirstPanelMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  with (Sender as TPanel) do
    if BevelOuter = bvLowered then BevelOuter := bvRaised;
end;

procedure TPostStatForm.FirstPanelClick(Sender: TObject);
var
  Year, Month, Day: Word;
begin
  case PeriodComboBox.ItemIndex of
    0:
      FirstDateEdit.Date := FirstDateEdit.Date-1;
    1:
      begin
        FirstDateEdit.Date := Int((FirstDateEdit.Date-1-2)/7)*7+2;
      end;
    2:
      begin
        DecodeDate(FirstDateEdit.Date, Year, Month, Day);
        if Month>1 then
          Dec(Month)
        else begin
          Month := 12;
          Dec(Year);
        end;
        Day := 1;
        FirstDateEdit.Date := EncodeDate(Year, Month, Day);
      end;
    3:
      begin
        DecodeDate(FirstDateEdit.Date, Year, Month, Day);
        Dec(Year);
        Day := 1;
        Month := 1;
        FirstDateEdit.Date := EncodeDate(Year, Month, Day);
      end;
  end;
  //RefreshToolButtonClick(nil);
end;

procedure TPostStatForm.LastPanelClick(Sender: TObject);
begin
  LastDateEdit.Date := Date;
end;

procedure TPostStatForm.FormResize(Sender: TObject);
begin
  ProtoFileComboBox.Width := ProtoFileGroupBox.Width - 2*ProtoFileComboBox.Left;
  ProtoFilenameEdit.Width := ProtoFileGroupBox.Width - 2*ProtoFilenameEdit.Left-18;
end;

procedure TPostStatForm.ProtoFileComboBoxClick(Sender: TObject);
begin
  ProtoFilenameEdit.Text := ProtoFileComboBox.Text;
end;

procedure TPostStatForm.SaveToolButtonClick(Sender: TObject);
const
  MesTitle: PChar = 'Сохранение статистики';
var
  F: TextFile;
  S: string;
  R, C: Integer;
begin
  if SaveDialog.Execute then
  begin
    AssignFile(F, SaveDialog.FileName);
    {$I-} Rewrite(F); {$I+}
    if IOResult=0 then
    begin
      with AllAbonStringGrid do
      begin
        for R := 0 to RowCount-1 do
        begin
          S := '';
          for C := 0 to ColCount-1 do
          begin
            if C>0 then
              S := S+#9;
            S := S+Cells[C, R];
          end;
          WriteLn(F, S);
        end;
      end;
      CloseFile(F);
    end
    else
      MessageBox(Handle, PChar('Ошибка создания файла ['+SaveDialog.FileName+']'),
        MesTitle, MB_OK or MB_ICONWARNING);
  end;
end;

end.
