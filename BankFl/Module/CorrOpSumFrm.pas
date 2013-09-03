unit CorrOpSumFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Grids, StdCtrls, Buttons, ExtCtrls, Utilits;

type
  TCorrOpSumForm = class(TForm)
    BtnPanel: TPanel;
    OkBitBtn: TBitBtn;
    ResSaldoListMemo: TMemo;
    AgreeCheckBox: TCheckBox;
    SaveSpeedButton: TSpeedButton;
    TextSaveDialog: TSaveDialog;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure AgreeCheckBoxClick(Sender: TObject);
    procedure SaveSpeedButtonClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

function RedSaldoFN: string;

var
  CorrOpSumForm: TCorrOpSumForm = nil;

implementation

{$R *.DFM}

const
  ciNum      = 0;
  ciAcc      = 1;
  ciClient   = 2;
  ciSum      = 3;

procedure TCorrOpSumForm.FormCreate(Sender: TObject);
begin
  {with AccStringGrid do
  begin
    ColWidths[ciNum   ] := 32;
    ColWidths[ciAcc   ] := 140;
    ColWidths[ciClient] := 250;
    ColWidths[ciSum   ] := 60;
    Cells[ciNum   , 0] := 'N';
    Cells[ciAcc   , 0] := 'Счет';
    Cells[ciClient, 0] := 'Клиент';
    Cells[ciSum   , 0] := 'Сальдо';
  end;}
end;

(*procedure AddAcc(Acc, Client: string; Sum: Int64);
var
  R, C: Integer;
begin
  if CorrOpSumForm=nil then
  begin
    CorrOpSumForm := TCorrOpSumForm.Create(Application);
    with CorrOpSumForm.AccStringGrid do
    begin
      RowCount := 2;
      for C := 1 to ColCount-1 do
        Cells[C, 1] := '';
    end;
  end;
  with CorrOpSumForm.AccStringGrid do
  begin
    R := RowCount-1;
    if Cells[C, R]<>'' then
    begin
      R := 1;
      while (R<RowCount) and (Cells[ciAcc, R]<>Acc) do
        Inc(R);
      if R>=RowCount then
      begin
        RowCount := RowCount+1;
        for C := 1 to ColCount-1 do
          Cells[C, R] := '';
      end;
    end;
    Cells[ciNum   , R] := IntToStr(R);
    Cells[ciAcc   , R] := 'Счет';
    Cells[ciClient, R] := 'Клиент';
    Cells[ciSum   , R] := 'Сальдо';
  end;
  CorrOpSumForm.ShowModal;
end;*)

procedure TCorrOpSumForm.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  if AgreeCheckBox.Checked then
  begin
    if SaveSpeedButton.Enabled then
      SaveSpeedButtonClick(nil);
    Action := caFree
  end
  else
    Action := caNone;
end;

procedure TCorrOpSumForm.AgreeCheckBoxClick(Sender: TObject);
begin
  OkBitBtn.Enabled := AgreeCheckBox.Checked;
end;

function RedSaldoFN: string;
begin
  Result := AppDir+'Log\redsaldo.txt';
end;

procedure TCorrOpSumForm.SaveSpeedButtonClick(Sender: TObject);
const
  MesTitle: PChar = 'Сохранение в файл';
var
  F: TextFile;
  I: Integer;
  FN: string;
  {L: Integer;
  Buf: PChar;}
begin
  {if TextSaveDialog.Execute then
  begin }
    FN := RedSaldoFN;
    AssignFile(F, FN);
    {$I-} Append(F); {$I+}
    I := IOResult;
    if I<>0 then
    begin
      {$I-} ReWrite(F); {$I+}
      I := IOResult;
    end;
    if I=0 then
    begin
      try
        WriteLn(F, '======= ['+DateTimeToStr(Now)+'] =========');
        WriteLn(F, ResSaldoListMemo.Text);
        {L := Length(ResSaldoListMemo.Text);
        GetMem(Buf, L+1);
        try
          StrPCopy(Buf, ResSaldoListMemo.Text);
          if MessageBox(Handle, 'Оставить в Windows-кодировке?', MesTitle,
            MB_YESNOCANCEL or MB_DEFBUTTON1 or MB_ICONQUESTION)=ID_YES
          then
            WinToDosL(Buf, L);
          BlockWrite(F, Buf^, L);
        finally
          //FreeMem(Buf);
        end;}
        SaveSpeedButton.Enabled := False;
      finally
        CloseFile(F);
      end;
    end
    else
      MessageBox(Handle, PChar('Не могу дописать/создать ['
        +FN+']'), MesTitle, MB_OK or MB_ICONERROR);
    {try
      ResSaldoListMemo.Lines.SaveToFile(TextSaveDialog.FileName);
    except
      MessageBox(Handle, PChar('Не могу создать ['
        +TextSaveDialog.FileName+']'), MesTitle, MB_OK or MB_ICONERROR);
    end;}
  {end;}
end;

end.
