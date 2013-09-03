unit LetterFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Mask, Buttons, ExtCtrls, ComCtrls, Utilits, ToolWin, CommCons;

type
  TLetterForm = class(TForm)
    BtnPanel: TPanel;
    OkBtn: TBitBtn;
    CancelBtn: TBitBtn;
    TopicGroupBox: TGroupBox;
    MessagGroupBox: TGroupBox;
    TopicEdit: TMaskEdit;
    MessagMemo: TMemo;
    TextOpenDialog: TOpenDialog;
    TextSaveDialog: TSaveDialog;
    DialogStatusBar: TStatusBar;
    MessagToolBar: TToolBar;
    LoadToolButton: TToolButton;
    SaveToolButton: TToolButton;
    NewToolButton: TToolButton;
    ToolButton1: TToolButton;
    CopyToolButton: TToolButton;
    CutToolButton: TToolButton;
    PasteToolButton: TToolButton;
    UndoToolButton: TToolButton;
    ToolButton2: TToolButton;
    ToolButton3: TToolButton;
    ExtToolButton: TToolButton;
    CryptToolButton: TToolButton;
    EditToolButton: TToolButton;
    ToolButton4: TToolButton;
    procedure BtnPanelResize(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure LoadToolButtonClick(Sender: TObject);
    procedure SaveToolButtonClick(Sender: TObject);
    procedure MessagMemoChange(Sender: TObject);
    procedure NewToolButtonClick(Sender: TObject);
    procedure CopyToolButtonClick(Sender: TObject);
    procedure CutToolButtonClick(Sender: TObject);
    procedure PasteToolButtonClick(Sender: TObject);
    procedure UndoToolButtonClick(Sender: TObject);
    procedure TopicEditChange(Sender: TObject);
    procedure MessagMemoKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure ExtToolButtonClick(Sender: TObject);
    procedure CryptToolButtonClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure EditToolButtonClick(Sender: TObject);
  private
    FReadOnly, FNew: Boolean;
  protected
    procedure SetReadOnly(Value: Boolean);
  public
    InputDoc: Boolean;
    property ReadOnly: Boolean read FReadOnly write SetReadOnly default False;
    procedure SetNew;
    procedure UpdState;
  end;

var
  LetterForm: TLetterForm;

implementation

uses
  LettersFrm;

{$R *.DFM}

procedure TLetterForm.SetReadOnly(Value: Boolean);
begin
  TopicEdit.ReadOnly := Value;
  TopicEdit.ParentColor := Value;
  MessagMemo.ReadOnly := Value;
  MessagMemo.ParentColor := Value;
  NewToolButton.Enabled := not Value;
  LoadToolButton.Enabled := not Value;
  CutToolButton.Enabled := not Value;
  PasteToolButton.Enabled := not Value;
  UndoToolButton.Enabled := not Value;
  FReadOnly := Value;
end;

procedure TLetterForm.BtnPanelResize(Sender: TObject);
const
  BtnDist=5;
begin
  OkBtn.Left := (BtnPanel.ClientWidth-OkBtn.Width-CancelBtn.Width-BtnDist) div 2;
  CancelBtn.Left := OkBtn.Left+OkBtn.Width+BtnDist;
  TopicEdit.Width := TopicGroupBox.ClientWidth - 2*TopicEdit.Left;
end;

procedure TLetterForm.FormCreate(Sender: TObject);
begin
  MessagToolBar.Images := LettersForm.ChildMenu.Images;
  TextSaveDialog.Filter := TextOpenDialog.Filter;
  FReadOnly := False;
  FNew := False;
  InputDoc := False;
end;

procedure TLetterForm.SetNew;
begin
  FNew := True;
end;

procedure TLetterForm.LoadToolButtonClick(Sender: TObject);
const
  MesTitle: PChar = 'Вставка текста из файла';
var
  F: file;
  L: Integer;
  Buf: PChar;
begin
  if TextOpenDialog.Execute then
  begin
    AssignFile(F, TextOpenDialog.FileName);
    FileMode := 0;
    {$I-} Reset(F, 1); {$I+}
    if IOResult=0 then
    begin
      try
        L := FileSize(F);
        GetMem(Buf, L+1);
        try
          BlockRead(F, Buf^, L);
          if MessageBox(Handle, 'Файл в DOS-кодировке?', MesTitle,
            MB_YESNOCANCEL+MB_ICONQUESTION)=ID_YES
          then
            DosToWinL(Buf, L);
          Buf[L] := #0;
          MessagMemo.SelText := StrPas(Buf);
        finally
          FreeMem(Buf);
        end;
      finally
        CloseFile(F);
      end;
    end
    else
      MessageBox(Handle, PChar('Не могу открыть ['
        +TextOpenDialog.FileName+']'), MesTitle, MB_OK+MB_ICONERROR);
  end;
end;

procedure TLetterForm.SaveToolButtonClick(Sender: TObject);
const
  MesTitle: PChar = 'Сохранение в файл';
var
  F: file;
  L: Integer;
  Buf: PChar;
begin
  if TextSaveDialog.Execute then
  begin
    AssignFile(F, TextSaveDialog.FileName);
    {$I-} Rewrite(F, 1); {$I+}
    if IOResult=0 then
    begin
      try
        L := Length(MessagMemo.Text);
        GetMem(Buf, L+1);
        try
          StrPCopy(Buf, MessagMemo.Text);
          if MessageBox(Handle, 'Преобразовать в DOS-кодировку?', MesTitle,
            MB_YESNOCANCEL+MB_ICONQUESTION)=ID_YES
          then
            WinToDosL(Buf, L);
          BlockWrite(F, Buf^, L);
        finally
          FreeMem(Buf);
        end;
      finally
        CloseFile(F);
      end;
    end
    else
      MessageBox(Handle, PChar('Не могу открыть ['
        +TextOpenDialog.FileName+']'), MesTitle, MB_OK+MB_ICONERROR);
  end;
end;

procedure TLetterForm.MessagMemoChange(Sender: TObject);
begin
  DialogStatusBar.Panels[0].Text := IntToStr(Length(MessagMemo.Text));
end;

procedure TLetterForm.NewToolButtonClick(Sender: TObject);
begin
  MessagMemo.Clear;
  MessagMemoChange(nil);
end;

procedure TLetterForm.CopyToolButtonClick(Sender: TObject);
begin
  MessagMemo.CopyToClipboard;
end;

procedure TLetterForm.CutToolButtonClick(Sender: TObject);
begin
  MessagMemo.CutToClipboard;
end;

procedure TLetterForm.PasteToolButtonClick(Sender: TObject);
begin
  MessagMemo.PasteFromClipboard;
end;

procedure TLetterForm.UndoToolButtonClick(Sender: TObject);
begin
  MessagMemo.Undo;
end;

procedure TLetterForm.TopicEditChange(Sender: TObject);
begin
  MessagMemo.MaxLength := erMaxVar-Length(TopicEdit.Text)-2-SignSize;
end;

procedure TLetterForm.FormShow(Sender: TObject);
begin
  if FNew {and (Length(TopicEdit.Text)=0)} then
  begin
    TopicEdit.Text := DateToStr(Date)+' - ';
  end;
  TopicEditChange(nil);
end;

procedure TLetterForm.MessagMemoKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (Key=VK_RETURN) and (Shift=[ssCtrl]) then
    ModalResult := mrOk;
end;

procedure TLetterForm.UpdState;
var
  S: string;
begin
  S := '';
  if InputDoc then
    S := S+'В';
  if CryptToolButton.Down then
    S := S+'Ш';
  DialogStatusBar.Panels[1].Text := S;
end;

procedure TLetterForm.ExtToolButtonClick(Sender: TObject);
begin
  if FReadOnly then
    ExtToolButton.Down := not ExtToolButton.Down
  else begin
    if not ExtToolButton.Down then
      CryptToolButton.Down := False;
    UpdState;
  end;
end;

procedure TLetterForm.CryptToolButtonClick(Sender: TObject);
begin
  if FReadOnly then
    CryptToolButton.Down := not CryptToolButton.Down
  else begin
    if CryptToolButton.Down then
      ExtToolButton.Down := True;
    UpdState;
  end;
end;

procedure TLetterForm.EditToolButtonClick(Sender: TObject);
const
  MesTitle: PChar = 'Просмотр письма';
var
  FN: string;
  F: TextFile;
  I: Integer;
  ResCode: DWord;
begin
  FN := PostDir+'letter.txt';
  AssignFile(F, FN);
  Rewrite(F);
  if IOResult=0 then
  begin
    WriteLn(F, 'Тема: '+TopicEdit.Text);
    WriteLn(F, 'Сообщение:');
    with MessagMemo.Lines do
    begin
      for I := 0 to Count-1 do
        WriteLn(F, Strings[I]);
    end;
    CloseFile(F);
    RunAndWait('notepad.exe '+FN, SW_SHOW, ResCode);
    Erase(F);
  end
  else
    MessageBox(Handle, PChar('Ошибка создания временного файла '+FN),
      MesTitle, MB_OK or MB_ICONERROR);
end;

end.
