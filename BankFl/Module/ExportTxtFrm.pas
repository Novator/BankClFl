unit ExportTxtFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ToolEdit, Mask, Buttons, BtrDS, Basbn, Utilits, BankCnBn, CommCons,
  Spin;

type
  TExportTxtForm = class(TForm)
    ProcessBitBtn: TBitBtn;
    CloseBitBtn: TBitBtn;
    DestDirectoryEdit: TDirectoryEdit;
    DestLabel: TLabel;
    DateGroupBox: TGroupBox;
    FromDateEdit: TDateEdit;
    ToDateEdit: TDateEdit;
    FromDateLabel: TLabel;
    ToLabel: TLabel;
    ModeComboBox: TComboBox;
    ModeLabel: TLabel;
    FieldsGroupBox: TGroupBox;
    OperationCheckBox: TCheckBox;
    OperNumCheckBox: TCheckBox;
    DocIderCheckBox: TCheckBox;
    DocDateCheckBox: TCheckBox;
    OverwriteCheckBox: TCheckBox;
    DocNumCheckBox: TCheckBox;
    DiffLabel: TLabel;
    DiffSpinEdit: TSpinEdit;
    procedure FormCreate(Sender: TObject);
    procedure ProcessBitBtnClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  ExportTxtForm: TExportTxtForm;

implementation

{$R *.DFM}

procedure TExportTxtForm.FormCreate(Sender: TObject);
begin
  ModeComboBox.ItemIndex := 1;
end;

var
  Process: Boolean = False;

procedure TExportTxtForm.ProcessBitBtnClick(Sender: TObject);
const
  MesTitle: PChar = 'Выгрузка для Кворума';
var
  DocDataSet, BillDataSet, ExportDataSet, ImportDataSet: TExtBtrDataSet;
  FromDate, ToDate, LocFromDate, LocToDate, CurDate, TmpDate: TDate;
  DateB, FromDateB, ToDateB: Word;
  OpRec: TOpRec;
  PayRec: TBankPayRec;
  ExportRec: TExportRec;
  Id, Id0, IdD, Len, Res, IdEx0, DiffInc: Integer;
  F: TextFile;
  FN, S: string;

  procedure AddFld(C: Boolean; V: string; var S: string);
  begin
    if C then
    begin
      if Length(S)>0 then
        S := S+' ';
      S := S+V;
    end;
  end;

  function CreateFileAndSetLocToDate(LocFromDate: TDate; ModeIndex: Integer;
    var F: TextFile; var FN: string; var LocToDate: TDate): Boolean;
  var
    //D1, D2: TDate;
    DD, MM, YY: Word;
  begin
    Result := False;
    //D1 := BtrDateToDate(LocFromDateB);
    DecodeDate(LocFromDate, YY, MM, DD);
    FN := DestDirectoryEdit.Text;
    if (Length(FN)>0) and (FN[Length(FN)]<>'\') then
      FN := FN + '\';
    FN := FN + FillZeros(YY, 4);
    case ModeIndex of
      0: {год}
        LocToDate := EncodeDate(YY+1, 01, 01)-1.0;
      1: {месяц}
        begin
          FN := FN + FillZeros(MM, 2);
          if MM=12 then
          begin
            Inc(YY);
            MM := 01;
          end
          else
            Inc(MM);
          LocToDate := EncodeDate(YY, MM, 01)-1.0;
        end;
      else begin
        FN := FN + FillZeros(MM, 2) + FillZeros(DD, 2);
        LocToDate := LocFromDate;
      end;
    end;
    FN := FN + '.txt';
    if not FileExists(FN) or OverwriteCheckBox.Checked then
    begin
      AssignFile(F, FN);
      {$I-} Rewrite(F); {$I+}
      if IOResult=0 then
      begin
        S := '';
        AddFld(OperationCheckBox.Checked, 'Operation', S);
        AddFld(OperNumCheckBox.Checked, 'OperNum', S);
        AddFld(DocIderCheckBox.Checked, 'DocIder', S);
        AddFld(DocDateCheckBox.Checked, 'DocDate', S);
        AddFld(DocNumCheckBox.Checked, 'DocNum', S);
        WriteLn(F, S);
        Result := True;
      end
      else
        MessageBox(Handle, PChar('Ошибка перезаписи ['+FN+']'),
          MesTitle, MB_ICONERROR or MB_OK);
    end
    else
      MessageBox(Handle, PChar('Файл уже существует ['+FN+']'),
        MesTitle, MB_ICONWARNING or MB_OK);
  end;

begin
  if Process then
    Process := False
  else begin
    Process := True;
    ProcessBitBtn.Caption := 'Прервать';
    try
      BillDataSet := GlobalBase(biBill);
      DocDataSet := GlobalBase(biPay);
      ExportDataSet := GlobalBase(biExport);
      ImportDataSet := GlobalBase(biImport);
      try
        FromDate := FromDateEdit.Date;
      except
        FromDate := 0;
      end;
      try
        ToDate := ToDateEdit.Date;
        //DateToBtrDate(
      except
        ToDate := 0;
      end;
      if ToDate=0 then
        ToDate := Date;
      if (FromDate>0) and Process then
      begin
        DateB := DateToBtrDate(FromDate);
        Len := SizeOf(OpRec);
        Res := BillDataSet.BtrBase.GetLT(OpRec, Len, DateB, 2);
        if Res<>0 then
        begin
          Len := SizeOf(OpRec);
          Res := BillDataSet.BtrBase.GetGE(OpRec, Len, DateB, 2);
        end;
        if Res=0 then
        begin
               {MessageBox(Handle, PChar('поиск op Id='
                  +IntToStr(OpRec.brIder)), '111', MB_ICONINFORMATION or MB_OK); }
          Id := OpRec.brDocId;
          Len := SizeOf(PayRec);
          Res := DocDataSet.BtrBase.GetLE(PayRec, Len, Id, 0);
          if Res<>0 then
          begin
            Len := SizeOf(PayRec);
            Res := DocDataSet.BtrBase.GetGE(PayRec, Len, Id, 0);
          end;
          if (Res=0) and Process then
          begin
               {MessageBox(Handle, PChar('поиск документов по Id='
                  +IntToStr(Id)), '222', MB_ICONINFORMATION or MB_OK); }
            FromDateB := DateToBtrDate(FromDate);
            ToDateB := DateToBtrDate(ToDate);
            {while (Res=0) and Process and (PayRec.dbDoc.drDate<FromDateB) do
            begin
              Len := SizeOf(PayRec);
              Res := DocDataSet.BtrBase.GetNext(PayRec, Len, Id, 0);
              Application.ProcessMessages;
            end; }
               {MessageBox(Handle, PChar('документы (сдвиг) по Id2='
                  +IntToStr(Id)), '333', MB_ICONINFORMATION or MB_OK);}
            Id := PayRec.dbIdHere;
            Len := SizeOf(ExportRec);
            Res := ExportDataSet.BtrBase.GetGE(ExportRec, Len, Id, 0);
            if Res=0 then
            begin
              IdEx0 := Id;
              {MessageBox(Handle, PChar('первая метка Id='
                  +IntToStr(Id)), '444', MB_ICONINFORMATION or MB_OK); }
              LocFromDate := FromDate;
              while (LocFromDate<=ToDate) and Process do
              begin
                Id := IdEx0-DiffSpinEdit.Value;
                Len := SizeOf(ExportRec);
                Res := ExportDataSet.BtrBase.GetGE(ExportRec, Len, Id, 0);
                if CreateFileAndSetLocToDate(LocFromDate, ModeComboBox.ItemIndex,
                  F, FN, LocToDate) then
                begin
                  {MessageBox(Handle, PChar('Loc From  To.дата='
                       +DateToStr(LocFromDate)+'///'
                       +DateToStr(LocToDate)),
                       '555', MB_ICONINFORMATION or MB_OK);}
                  CurDate := LocFromDate;
                  DiffInc := 0;
                  while (Res=0) and ((CurDate<=LocToDate)
                    or (DiffInc<DiffSpinEdit.Value)) and Process do
                  begin
                    {S := '';
                    AddFld(True, IntToStr(ExportRec.erIderB)+
                      IntToStr(ExportRec.erOperNum)
                      IntToStr(ExportRec.erOperation), S);
                    WriteLn(F, S);}
                    IdD := ExportRec.erIderB;
                    Len := SizeOf(PayRec);
                    Res := DocDataSet.BtrBase.GetEqual(PayRec, Len, IdD, 0);
                    if Res=0 then
                    begin
                      TmpDate :=BtrDateToDate(PayRec.dbDoc.drDate);
                      if TmpDate>=LocFromDate then
                      begin
                        CurDate := TmpDate;
                        if CurDate<=LocToDate then
                        begin
                          S := '';
                          AddFld(OperationCheckBox.Checked, IntToStr(ExportRec.erOperation), S);
                          AddFld(OperNumCheckBox.Checked, IntToStr(ExportRec.erOperNum), S);
                          AddFld(DocIderCheckBox.Checked, IntToStr(ExportRec.erIderB), S);
                          AddFld(DocDateCheckBox.Checked, BtrDateToStr(PayRec.dbDoc.drDate), S);
                          AddFld(DocNumCheckBox.Checked, PayRec.dbDoc.drVar, S);
                          WriteLn(F, S);
                          IdEx0 := Id;
                        end
                        else
                          DiffInc := Id-IdEx0;
                      end;
                    end;
                    Len := SizeOf(ExportRec);
                    Res := ExportDataSet.BtrBase.GetNext(ExportRec, Len, Id, 0);
                    Application.ProcessMessages;
                  end;
                  CloseFile(F);
                  LocFromDate := LocToDate + 1.0;
                end
                else begin
                  MessageBox(Handle, PChar('Не удалось создать файл на дату '
                    +DateToStr(LocFromDate)), MesTitle, MB_ICONINFORMATION or MB_OK);
                  Process := False;
                end;
              end;
              MessageBox(Handle, 'Процесс завершен', MesTitle,
                MB_ICONINFORMATION or MB_OK);
            end
            else begin
              MessageBox(Handle, PChar('Неудачный поиск меток по Id='
                +IntToStr(Id)), MesTitle, MB_ICONINFORMATION or MB_OK);
              Process := False;
            end;
          end
          else
            MessageBox(Handle, PChar('Неудачный поиск документов по Id='
              +IntToStr(Id)), MesTitle, MB_ICONINFORMATION or MB_OK);
        end
        else
          MessageBox(Handle, PChar('Неудачный поиск по проводкам на дату '
            +BtrDateToStr(DateB)), MesTitle, MB_ICONINFORMATION or MB_OK);
      end
      else
        MessageBox(Handle, 'Начальная дата должна быть задана', MesTitle,
          MB_ICONINFORMATION or MB_OK);
      if not Process then
        MessageBox(Handle, 'Процесс прерван', MesTitle,
          MB_ICONINFORMATION or MB_OK);
    finally
      ProcessBitBtn.Caption := 'Начать';
      Process := False;
    end;
  end;
end;

end.
