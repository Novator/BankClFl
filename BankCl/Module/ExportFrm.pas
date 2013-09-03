unit ExportFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Grids, Db, DBTables, DBGrids, ExtCtrls, DBCtrls, BtrDS, Menus,
  SearchFrm, UserFrm, StdCtrls, ComCtrls, Buttons, Btrieve,
  Common, Bases, Registr, CommCons, ClntCons, Utilits, DbfDataSet,
  SdfDataSet, DocFunc;

type
  TExportForm = class(TDataBaseForm)
    DataSource: TDataSource;
    DBGrid: TDBGrid;
    ChildMenu: TMainMenu;
    OperItem: TMenuItem;
    OpenItem: TMenuItem;
    CloseItem: TMenuItem;
    EditBreaker: TMenuItem;
    FindItem: TMenuItem;
    StatusBar: TStatusBar;
    CompressItem: TMenuItem;
    EditBreaker1: TMenuItem;
    EditPopupMenu: TPopupMenu;
    ExportItem: TMenuItem;
    DelBaseItem: TMenuItem;
    SaveDialog: TSaveDialog;
    Export2Item: TMenuItem;
    Open2Item: TMenuItem;
    SdfDataSet1: TSdfDataSet;
    SdfDataSet1NUMBER: TStringField;
    SdfDataSet1DATE: TDateField;
    SdfDataSet1VID: TWordField;
    SdfDataSet1SUMMA: TFloatField;
    SdfDataSet1PACC: TStringField;
    SdfDataSet1PCODE: TStringField;
    SdfDataSet1PKS: TStringField;
    SdfDataSet1PINN: TStringField;
    SdfDataSet1PCLIENT: TStringField;
    SdfDataSet1PBANK: TStringField;
    SdfDataSet1RCODE: TStringField;
    SdfDataSet1RACC: TStringField;
    SdfDataSet1RKS: TStringField;
    SdfDataSet1RBANK: TStringField;
    SdfDataSet1RINN: TStringField;
    SdfDataSet1RCLIENT: TStringField;
    SdfDataSet1OPTYPE: TWordField;
    SdfDataSet1OCHER: TStringField;
    SdfDataSet1SROK: TDateField;
    SdfDataSet1NAZN: TStringField;
    DbfDataSet1: TDbfDataSet;
    DbfDataSet2: TDbfDataSet;
    DbfDataSet1NUMBER: TStringField;
    DbfDataSet1DATE: TDateField;
    DbfDataSet1VID: TWordField;
    DbfDataSet1SUM: TFloatField;
    DbfDataSet1PACC: TStringField;
    DbfDataSet1PCODE: TStringField;
    DbfDataSet1PKS: TStringField;
    DbfDataSet1PINN: TStringField;
    DbfDataSet1PCLIENT1: TStringField;
    DbfDataSet1PCLIENT2: TStringField;
    DbfDataSet1PCLIENT3: TStringField;
    DbfDataSet1PBANK1: TStringField;
    DbfDataSet1PBANK2: TStringField;
    DbfDataSet1RCODE: TStringField;
    DbfDataSet1RKS: TStringField;
    DbfDataSet1RACC: TStringField;
    DbfDataSet1RBANK1: TStringField;
    DbfDataSet1RBANK2: TStringField;
    DbfDataSet1RINN: TStringField;
    DbfDataSet1RCLIENT1: TStringField;
    DbfDataSet1RCLIENT2: TStringField;
    DbfDataSet1RCLIENT3: TStringField;
    DbfDataSet1OPTYPE: TWordField;
    DbfDataSet1OCHER: TWordField;
    DbfDataSet1SROK: TDateField;
    DbfDataSet1NAZN1: TStringField;
    DbfDataSet1NAZN2: TStringField;
    DbfDataSet1NAZN3: TStringField;
    DbfDataSet1NAZN4: TStringField;
    DbfDataSet1NAZN5: TStringField;
    DbfDataSet1STATE: TWordField;
    DbfDataSet1NUMOP: TWordField;
    DbfDataSet1DATEOP: TDateField;
    DbfDataSet1DTACC: TIntegerField;
    DbfDataSet1CRACC: TIntegerField;
    DbfDataSet1INFO: TStringField;
    DbfDataSet2NUMBER: TStringField;
    DbfDataSet2DATE: TDateField;
    DbfDataSet2VID: TWordField;
    DbfDataSet2SUMMA: TFloatField;
    DbfDataSet2PACC: TStringField;
    DbfDataSet2PCODE: TStringField;
    DbfDataSet2PKS: TStringField;
    DbfDataSet2PINN: TStringField;
    DbfDataSet2PCLIENT: TStringField;
    DbfDataSet2PBANK: TStringField;
    DbfDataSet2RCODE: TStringField;
    DbfDataSet2RACC: TStringField;
    DbfDataSet2RKS: TStringField;
    DbfDataSet2RBANK: TStringField;
    DbfDataSet2RINN: TStringField;
    DbfDataSet2RCLIENT: TStringField;
    DbfDataSet2OPTYPE: TWordField;
    DbfDataSet2OCHER: TStringField;
    DbfDataSet2SROK: TDateField;
    DbfDataSet2NAZN: TStringField;
    DbfDataSet3: TDbfDataSet;
    StringField1: TStringField;
    WordField1: TWordField;
    FloatField1: TFloatField;
    StringField2: TStringField;
    StringField3: TStringField;
    StringField4: TStringField;
    StringField5: TStringField;
    StringField6: TStringField;
    StringField7: TStringField;
    StringField8: TStringField;
    StringField9: TStringField;
    StringField10: TStringField;
    StringField11: TStringField;
    StringField12: TStringField;
    StringField13: TStringField;
    StringField14: TStringField;
    StringField15: TStringField;
    StringField16: TStringField;
    StringField17: TStringField;
    StringField18: TStringField;
    StringField19: TStringField;
    WordField2: TWordField;
    WordField3: TWordField;
    DateField2: TDateField;
    StringField20: TStringField;
    StringField21: TStringField;
    StringField22: TStringField;
    DbfDataSet3DATE: TDateField;
    DbfDataSet3TIPPL: TStringField;
    DbfDataSet3PERIOD: TStringField;
    DbfDataSet1PKPP: TStringField;
    DbfDataSet1RKPP: TStringField;
    DbfDataSet1STATUS: TStringField;
    DbfDataSet1KBK: TStringField;
    DbfDataSet1OKATO: TStringField;
    DbfDataSet1OSNPL: TStringField;
    DbfDataSet1PERIOD: TStringField;
    DbfDataSet1NDOC: TStringField;
    DbfDataSet1DOCDATE: TStringField;
    DbfDataSet1TIPPL: TStringField;
    DbfDataSet2PKPP: TStringField;
    DbfDataSet2RKPP: TStringField;
    DbfDataSet2STATUS: TStringField;
    DbfDataSet2KBK: TStringField;
    DbfDataSet2OKATO: TStringField;
    DbfDataSet2OSNPL: TStringField;
    DbfDataSet2PERIOD: TStringField;
    DbfDataSet2NDOC: TStringField;
    DbfDataSet2DOCDATE: TStringField;
    DbfDataSet2TIPPL: TStringField;
    DbfDataSet1NCHPL: TStringField;
    DbfDataSet1SHIFR: TStringField;
    DbfDataSet1NPLAT: TStringField;
    DbfDataSet1OSTSUM: TStringField;
    DbfDataSet2NCHPL: TStringField;
    DbfDataSet2SHIFR: TStringField;
    DbfDataSet2NPLAT: TStringField;
    DbfDataSet2OSTSUM: TStringField;
    DbfDataSet3NCHPL: TStringField;
    DbfDataSet3SHIFR: TStringField;
    DbfDataSet3NPLAT: TStringField;
    DbfDataSet3OSTSUM: TStringField;
    SdfDataSet1NCHPL: TStringField;
    SdfDataSet1SHIFR: TStringField;
    SdfDataSet1NPLAT: TStringField;
    SdfDataSet1OSTSUM: TStringField;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure OpenItemClick(Sender: TObject);
    procedure FindItemClick(Sender: TObject);
    procedure CloseItemClick(Sender: TObject);
    procedure CompressItemClick(Sender: TObject);
    procedure DBGridDrawDataCell(Sender: TObject; const Rect: TRect;
      Field: TField; State: TGridDrawState);
    procedure ExportItemClick(Sender: TObject);
    procedure DelBaseItemClick(Sender: TObject);
    procedure Export2ItemClick(Sender: TObject);
    procedure Open2ItemClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    SearchForm: TSearchForm;
  protected
    procedure Exporting(Range: Byte);
  public
    function OpenExportBase(Range: Byte): Boolean;
  end;

const
  ExportForm: TExportForm = nil;

var
  ObjList: TList;

implementation

function VidToStr(Isp: Integer): string;
begin
  case Isp of
    0: Result := '������';
    1: Result := '����������';
    else
      Result := '����������';
  end;
end;

const
  DosCharset: Boolean = False;
  ChooseExport: Boolean = False;

{$R *.DFM}

var
  ExportFormat: Integer = 1;
  ExportFile: string = '';
  ExportFile2: string = '';
  AddKppToInn: string = '';
  TotalExport: Boolean = False;
  FullExport: Boolean = False;
  FirstExport: Integer = 0;
  CloseExport: Boolean = False;
  ReservExport: Integer = 50;
  OverwriteMode: Integer = 0;
  CleanExFld: Integer = 0;
  ExportBilled: Boolean = False;

procedure TExportForm.FormCreate(Sender: TObject);
begin
  ObjList.Add(Self);
  SearchForm := TSearchForm.Create(Self);
  SearchForm.SourceDBGrid := DBGrid;
  TakeMenuItems(OperItem, EditPopupMenu.Items);
  EditPopupMenu.Images := ChildMenu.Images;
  if not GetRegParamByName('ExportDosCharset', CommonUserNumber, DosCharset) then
    DosCharset := False;
  if not GetRegParamByName('ExportFmt', CommonUserNumber, ExportFormat) then
    ExportFormat := 1;
  ExportFile := DecodeMask('$(ExportFile)', 5, CommonUserNumber);
  ExportFile2 := DecodeMask('$(ExportFile2)', 5, CommonUserNumber);
  AddKppToInn := DecodeMask('$(AddKppToInn)', 5, CommonUserNumber);
  if not GetRegParamByName('TotalExport', CommonUserNumber, TotalExport) then
    TotalExport := True;
  if not GetRegParamByName('FullExport', CommonUserNumber, FullExport) then
    FullExport := False;
  if not GetRegParamByName('ChooseExport', CommonUserNumber, ChooseExport) then
    ChooseExport := False;
  if not GetRegParamByName('ReservExport', CommonUserNumber, ReservExport) then
    ReservExport := 50;
  if not GetRegParamByName('FirstExport', CommonUserNumber, FirstExport) then
    FirstExport := 0;
  if not GetRegParamByName('CloseExport', CommonUserNumber, CloseExport) then
    CloseExport := False;
  if not GetRegParamByName('OverwriteMode', CommonUserNumber, OverwriteMode) then
    OverwriteMode := 0;
  if not GetRegParamByName('ExportBilled', CommonUserNumber, ExportBilled) then
    ExportBilled := False;
  if not GetRegParamByName('CleanExFld', CommonUserNumber, CleanExFld) then
    CleanExFld := 0;
end;

procedure TExportForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  CloseItemClick(nil);
  Action := caFree;
end;

procedure TExportForm.FormDestroy(Sender: TObject);
begin
  ExportForm := nil;
  ObjList.Remove(Self);
end;

procedure TExportForm.FindItemClick(Sender: TObject);
begin
  SearchForm.ShowModal;
end;

var
  TF: TextFile;

function TExportForm.OpenExportBase(Range: Byte): Boolean;
const
  MesTitle: PChar = '��������/�������� ����� ��������';
var
  S, S2, V: string;
  TF2: TextFile;
begin
  CloseItemClick(nil);
  case Range of
    0: {���}
      SaveDialog.FileName := ExportFile;
    1: {��}
      SaveDialog.FileName := ExportFile2;
  end;
  if ChooseExport then
  begin
    case ExportFormat of
      1,2,5:
        begin
          SaveDialog.FilterIndex := 1;
          SaveDialog.DefaultExt := 'dbf';
        end;
      3:
        begin
          SaveDialog.FilterIndex := 2;
          SaveDialog.DefaultExt := 'sbf';
        end;
      4:
        begin
          SaveDialog.FilterIndex := 2;
          SaveDialog.DefaultExt := 'txt';
        end;
      else begin
        SaveDialog.FilterIndex := 3;
        SaveDialog.DefaultExt := '';
      end;
    end;
    Result := SaveDialog.Execute
  end
  else
    Result := True;
  if Result then
  begin
    S := SaveDialog.FileName;
    case ExportFormat of
      1: DataSource.DataSet := DbfDataSet1;
      2: DataSource.DataSet := DbfDataSet2;
      3: DataSource.DataSet := SdfDataSet1;
      5: DataSource.DataSet := DbfDataSet3;
      else
        DataSource.DataSet := nil;
    end;
    if not ((FirstExport=3) and (Range=1)) and FileExists(S)
      and ((OverwriteMode=1) or (OverwriteMode=2) and (MessageBox(Application.Handle,
        PChar('���� ['+S+'] ��� ����������. ������������?'), MesTitle,
        MB_YESNOCANCEL or MB_ICONQUESTION) = ID_YES))
    then
      if not DeleteFile(S) then
        MessageBox(Application.Handle, PChar('�� ������� ������� ���� ['
          +S+']'), MesTitle, MB_OK or MB_ICONERROR);
    if ExportFormat=4 then
    begin
      AssignFile(TF, S);
      FileMode := 0;
      {$I-} Reset(TF); {$I+}
      Result := IOResult=0;
      if Result then
      begin
        S2 := ChangeFileExt(S, '.~bc');
        AssignFile(TF2, S2);
        {$I-} Rewrite(TF2); {$I+}
        Result := IOResult=0;
        if Result then
        begin
          while not Eof(TF) do
          begin
            ReadLn(TF, V);
            if Pos('����������', V)>0 then
              Break;
            WriteLn(TF2, V);
          end;
          CloseFile(TF2);
          CloseFile(TF);
          Erase(TF);
          Rename(TF2, S);
          AssignFile(TF, S);
          {$I-} Append(TF); {$I+}
          Result := IOResult=0;
          if not Result then
            MessageBox(Application.Handle, PChar('�� ������� ����� ������� ���� ������ ['
              +S+']'), MesTitle, MB_OK or MB_ICONERROR);
        end
        else
          MessageBox(Application.Handle, PChar('�� ������� ������� ��������� ���� ['
            +S2+']'), MesTitle, MB_OK or MB_ICONERROR);
      end
      else begin
        {$I-} Rewrite(TF); {$I+}
        Result := IOResult=0;
        if Result then
        begin
          WriteLn(TF, '1CClientBankExchange');
          WriteLn(TF, '�������������=1');
          if DosCharset then
            V := 'Dos'
          else
            V := 'Windows';
          WriteLn(TF, '���������='+V);
          WriteLn(TF, '�����������='+Application.Title);
          WriteLn(TF, '����������=������������� ����, �������� 4.2');
          V := DateToStr(Date);
          WriteLn(TF, '������������='+V); //27.03.2002
          WriteLn(TF, '�������������='+TimeToStr(Time)); //09:57:11
          {WriteLn(TF, '����������='+V);    //27.03.2002
          WriteLn(TF, '���������='+V);    //27.03.2002
          WriteLn(TF, '��������=');     //40802810800100010307}
        end
        else
          MessageBox(Application.Handle, PChar('�� ������� ������� ���� ������ ['
            +S+']'), MesTitle, MB_OK or MB_ICONERROR);
      end;
    end
    else begin
      with DataSource.DataSet do
      begin
        if Self.DataSource.DataSet is TDbfDataSet then
          (Self.DataSource.DataSet as TDbfDataSet).TableName := S
        else
          if Self.DataSource.DataSet is TSDFDataSet then
            (Self.DataSource.DataSet as TSDFDataSet).TableName := S;
        if not FileExists(S) then
        begin
          try
            if Self.DataSource.DataSet is TDbfDataSet then
              (Self.DataSource.DataSet as TDbfDataSet).CreateTable
            else
              if Self.DataSource.DataSet is TSDFDataSet then
                (Self.DataSource.DataSet as TSDFDataSet).CreateTable;
          except
            Result := False;
            MessageBox(Application.MainForm.Handle,
            PChar('�� ������� ������� ���� ��������'
              +#13#10'['+S+']'), MesTitle, MB_OK or MB_ICONERROR);
          end;
        end;
        if Result then
        begin
          try
            FieldDefs.Clear;
            Fields.Clear;
            Active := True;
            Result := Active;
          except
            Result := False;
            MessageBox(Application.MainForm.Handle,
              PChar('�� ������� ������� ���� ��������'
              +#13#10'['+S+']'), MesTitle, MB_OK or MB_ICONERROR);
          end;
        end;
      end;
    end;
  end;
end;

procedure TExportForm.OpenItemClick(Sender: TObject);
begin
  OpenExportBase(0);
end;

procedure TExportForm.Open2ItemClick(Sender: TObject);
begin
  OpenExportBase(1);
end;

procedure TExportForm.CloseItemClick(Sender: TObject);
begin
  DbfDataSet1.Close;
  DbfDataSet2.Close;
  SdfDataSet1.Close;
  DbfDataSet3.Close;
end;

procedure TExportForm.CompressItemClick(Sender: TObject);
begin
  if DbfDataSet1.Active then
    DbfDataSet1.PackTable;
  if DbfDataSet2.Active then
    DbfDataSet2.PackTable;
  if DbfDataSet3.Active then
    DbfDataSet3.PackTable;
end;

function BreakStr(var S: string; MaxLen: Integer): string;
var
  Len, Len0: Integer;
begin
  Len0 := StrLen(PChar(S));
  Len := Pos(#13#10, S);
  if Len>0 then
    Dec(Len)
  else
    Len := Len0;
  if Len>MaxLen then
    Len := MaxLen;
  Result := Copy(S, 1, Len);
  Inc(Len);
  while (Len<=Len0) and ((S[Len]=#13) or (S[Len]=#10)) do
    Inc(Len);
  S := Copy(S, Len, Len0-Len+1);
end;

procedure DisperseStr(S, Name: string; var Single, Multi: string);
var
  I, L, J, K: Integer;
  V: string;
begin
  Single := '';
  Multi := '';
  K := 0;
  J := Length(Name);
  L := Length(S);
  I := 0;
  while I<=L do
  begin
    Inc(I);
    if (I>L) or (S[I]=#10) or (S[I]=#13) then
    begin
      V := Copy(S, 1, I-1);
      if Length(V)>0 then
      begin
        Single := Single + V;
        if J>0 then
        begin
          Inc(K);
          Multi := Multi + Name + IntToStr(K) + '=' + V + #13#10;
        end;
      end;
      while (I<=L) and ((S[I]=#10) or (S[I]=#13)) do
        Inc(I);
      Delete(S, 1, I-1);
      L := Length(S);
      if L>0 then
      begin
        I := 0;
        Single := Single + ' '
      end
      else
        I := 1;
    end;
  end;
end;

function Billed(var PayRec: TPayRec): Boolean;
var
  BillRec: TOpRec;
begin
  Result := (GetDocOp(BillRec, PayRec.dbIdKorr)>0) and (BillRec.brPrizn=brtBill);
end;

const
  NumOfFields1 = 50;
  FldNames1: array[1..NumOfFields1] of string =
    ('NUMBER',
    'PACC', 'PKS', 'PCODE', 'PINN', 'PCLIENT1', 'PCLIENT2', 'PCLIENT3',
    'PBANK1', 'PBANK2', 'RACC', 'RKS', 'RCODE', 'RINN',
    'RCLIENT1', 'RCLIENT2', 'RCLIENT3', 'RBANK1', 'RBANK2',
    'NAZN1', 'NAZN2', 'NAZN3', 'NAZN4', 'NAZN5',
    'DATE', 'VID', 'SUM', 'OPTYPE', 'OCHER',
    'SROK', 'STATE', 'NUMOP',
    'DATEOP', 'DTACC', 'CRACC', 'INFO',
    'PKPP', 'RKPP', 
    'STATUS', 'KBK', 'OKATO', 'OSNPL', 'PERIOD', 'NDOC', 'DOCDATE', 'TIPPL',
    'NCHPL', 'SHIFR', 'NPLAT', 'OSTSUM');
  NumOfFields2 = 34;
  FldNames2: array[1..NumOfFields2] of string =
    ('NUMBER', 'DATE', 'VID', 'SUMMA',
    'PACC', 'PCODE', 'PKS', 'PINN', 'PCLIENT', 'PBANK',
    'RCODE', 'RACC', 'RKS', 'RBANK', 'RINN', 'RCLIENT',
    'OPTYPE', 'OCHER', 'SROK', 'NAZN',
    'PKPP', 'RKPP',
    'STATUS', 'KBK', 'OKATO', 'OSNPL', 'PERIOD', 'NDOC', 'DOCDATE', 'TIPPL',
    'NCHPL', 'SHIFR', 'NPLAT', 'OSTSUM');
  NumOfFields3 = 34;
  FldNames3: array[1..NumOfFields3] of string =
    ('DATE', 'NUMBER', 'SUMMA', 'VIDOP', 'VIDPL', 'OCHER',
    'PBANK', 'PBIK', 'PKS', 'PNAME', 'PACC', 'PINN', 'PKPP',
    'RBANK', 'RBIK', 'RKS', 'RNAME', 'RACC', 'RINN', 'RKPP',
    'NAZN', 'SROKPL',
    'STATUS', 'KBK', 'OKATO', 'OSNPL', 'PERIOD', 'NDOC', 'DOCDATE', 'TIPPL',
    'NCHPL', 'SHIFR', 'NPLAT', 'OSTSUM');

procedure TExportForm.Exporting(Range: Byte);
const
  MesTitle: PChar = '�������';
var
  DocDataSet: TExtBtrDataSet;
  PayRec: TPayRec;
  PayCount, I, Offset, Key, RecLen, Res, RangeIndex: Integer;
  F: TField;

  Number, PAcc, PKs, PCode, PInn, PClient, PBank,
  RAcc, RKs, RCode, RInn, PKpp, RKpp, RClient, RBank, Nazn, S, M,
    Status, Kbk, Okato, OsnPl, Period, NDoc, DocDate, TipPl, Nchpl, Shifr,
    Nplat, OstSum: string;
  DocType: Word;
begin
  try
    try
      DocDataSet := GlobalBase(biPay);
    except
      MessageBox(Application.MainForm.Handle, '�� ������� ������� ���� Doc', MesTitle,
        MB_OK or MB_ICONERROR);
      raise;
    end;
    Screen.Cursor := crHourGlass;
    PayCount := 0;
    if OpenExportBase(Range) then
    begin
      if (ExportFormat>=1) and (ExportFormat<=5) then
      begin
        RecLen := SizeOf(PayRec);
        if TotalExport then
          RangeIndex := 0 {����� ������}
        else begin  {���������� ������}
          case Range of
            0: {���}
              RangeIndex := 3;
            else {��}
              RangeIndex := 2;
          end;
        end;
        case Range of {"��������" ����. ����}
          0: {���}
             if FullExport or not GetRegParamByName('LastExportId', CommonUserNumber, Key) then
               Key := 0;
          else {��}
             if FullExport or not GetRegParamByName('LastExportIn', CommonUserNumber, Key) then
               Key := 0;
        end;
        if Key>ReservExport then
          Key := Key-ReservExport
        else
          Key := 0;
        Res := DocDataSet.BtrBase.GetGE(PayRec, RecLen, Key, RangeIndex);
        while Res=0 do
        begin
          if
            (
              (RangeIndex<>0)
                or
              (Range=0) and ((PayRec.dbIdOut<>0) or (PayRec.dbState and dsInputDoc = 0))
                or
              (Range=1) and ((PayRec.dbIdIn<>0) or (PayRec.dbState and dsInputDoc <> 0))
            )
              and
            (dsExport and PayRec.dbState = 0)
              and
            (not ExportBilled or Billed(PayRec)) then
          begin
            DecodeDocVar(PayRec.dbDoc, PayRec.dbDocVarLen,
              Number, PAcc, PKs, PCode, PInn, PClient, PBank,
              RAcc, RKs, RCode, RInn, RClient, RBank, Nazn, PKpp, RKpp,
              Status, Kbk, Okato, OsnPl, Period, NDoc, DocDate, TipPl,
              Nchpl, Shifr, Nplat, OstSum, 0, CleanExFld, Offset, DosCharset);
            DocType := PayRec.dbDoc.drType;
            if DocType>100 then
              DocType := DocType-100;
            Res := 1;
            if Length(AddKppToInn)>0 then
            begin
              if Length(PKpp)>0 then
                PInn := PInn + AddKppToInn + PKpp;
              if Length(RKpp)>0 then
                RInn := RInn + AddKppToInn + RKpp;
            end;
            case ExportFormat of
              1:
                with DbfDataSet1 do
                begin
                  Append;
                  for I := 1 to NumOfFields1 do
                  begin
                    F := FindField(FldNames1[I]);
                    if F=nil then
                    begin
                      MessageBox(Application.MainForm.Handle, PChar('�� ������� ���� ['+FldNames1[I]+']'),
                        MesTitle, MB_OK or MB_ICONERROR)
                    end
                    else begin
                      case I of
                        1: F.AsString := Number;
                        2: F.AsString := PAcc;
                        3: F.AsString := PKs;
                        4: F.AsString := PCode;
                        5: F.AsString := PInn;
                        6..8:
                          F.AsString := BreakStr(PClient, 45);
                        9,10:
                          F.AsString := BreakStr(PBank, 45);
                        11: F.AsString := RAcc;
                        12: F.AsString := RKs;
                        13: F.AsString := RCode;
                        14: F.AsString := RInn;
                        15..17:
                          F.AsString := BreakStr(RClient, 45);
                        18,19:
                          F.AsString := BreakStr(RBank, 45);
                        20..24:
                          F.AsString := BreakStr(Nazn, 78);
                        25: F.AsString := BtrDateToStr(PayRec.dbDoc.drDate);
                        26: F.AsInteger := PayRec.dbDoc.drIsp;
                        27: F.AsFloat := PayRec.dbDoc.drSum/100.0;
                        28: F.AsInteger := DocType;
                        29: F.AsInteger := PayRec.dbDoc.drOcher;
                        30: F.AsString := BtrDateToStr(PayRec.dbDoc.drSrok);
                        31..36: ;
                        37: F.AsString := PKpp;
                        38: F.AsString := RKpp;
                        39: F.AsString := Status;
                        40: F.AsString := Kbk;
                        41: F.AsString := Okato;
                        42: F.AsString := OsnPl;
                        43: F.AsString := Period;
                        44: F.AsString := NDoc;
                        45: F.AsString := DocDate;
                        46: F.AsString := TipPl;
                        47: F.AsString := Nchpl;
                        48: F.AsString := Shifr;
                        49: F.AsString := Nplat;
                        50: F.AsString := OstSum;
                      end;
                    end;
                  end;
                  Post;
                  Res := 0;
                end;
              2,3:
                begin
                  case ExportFormat of
                    2: DataSource.DataSet := DbfDataSet2;
                    3: DataSource.DataSet := SdfDataSet1;
                  end;
                  with DataSource.DataSet do
                  begin
                    Append;
                    for I := 1 to NumOfFields2 do
                    begin
                      F := FindField(FldNames2[I]);
                      if F=nil then
                      begin
                        MessageBox(Application.MainForm.Handle,
                          PChar('�� ������� ���� ['+FldNames2[I]+']'),
                          MesTitle, MB_OK or MB_ICONERROR)
                      end
                      else begin
                        case I of
                          1: F.AsString := Number;  {Number}
                          2: F.AsString := BtrDateToStr(PayRec.dbDoc.drDate);    {Date}
                          3: F.AsInteger := PayRec.dbDoc.drIsp;     {Vid}
                          4: F.AsFloat := PayRec.dbDoc.drSum/100.0;   {Summa}
                          5: F.AsString := PAcc;
                          6: F.AsString := PCode;
                          7: F.AsString := PKs;
                          8: F.AsString := PInn;
                          9: F.AsString := PClient;
                          10: F.AsString := PBank;
                          11: F.AsString := RCode;
                          12: F.AsString := RAcc;
                          13: F.AsString := RKs;
                          14: F.AsString := RBank;
                          15: F.AsString := RInn;
                          16: F.AsString := RClient;
                          17: F.AsInteger := DocType;
                          18: F.AsInteger := PayRec.dbDoc.drOcher;
                          19: F.AsString := BtrDateToStr(PayRec.dbDoc.drSrok);
                          20: F.AsString := Nazn;
                          21: F.AsString := PKpp;
                          22: F.AsString := RKpp;
                          23: F.AsString := Status;
                          24: F.AsString := Kbk;
                          25: F.AsString := Okato;
                          26: F.AsString := OsnPl;
                          27: F.AsString := Period;
                          28: F.AsString := NDoc;
                          29: F.AsString := DocDate;
                          30: F.AsString := TipPl;
                          31: F.AsString := Nchpl;
                          32: F.AsString := Shifr;
                          33: F.AsString := Nplat;
                          34: F.AsString := OstSum;
                        end;
                      end;
                    end;
                    Post;
                    Res := 0;
                  end;
                end;
              4:
                begin
                  case DocType of
                    1,92:
                      S :='��������� ���������';
                    2,91:
                      S := '��������� ����������';
                    3:
                      S :='�������� �����';
                    9:
                      S :='������������ �����';
                    16:
                      S :='��������� �����'
                    else
                      S :='������';
                  end;
                  WriteLn(TF, '��������='+S);
                  WriteLn(TF, '��������������='+S);
                  WriteLn(TF, '�����='+Number);
                  WriteLn(TF, '����='+BtrDateToStr(PayRec.dbDoc.drDate));
                  Str(PayRec.dbDoc.drSum/100.0:0:2, S);
                  WriteLn(TF, '�����='+S);
                  WriteLn(TF, '��������������='+PAcc);
                  WriteLn(TF, '�������������='+PInn);
                  WriteLn(TF, '�������������='+PKpp);
                  DisperseStr(PClient, '����������', S, M);
                  WriteLn(TF, '����������=��� '+PInn+' '+S);
                  if Length(M)>0 then
                    Write(TF, M);
                  WriteLn(TF, '������������������='+PAcc);
                  DisperseStr(PBank, '��������������', S, M);
                  if Length(M)>0 then
                    Write(TF, M);
                  WriteLn(TF, '�������������='+PCode);
                  WriteLn(TF, '�����������������='+PKs);
                  WriteLn(TF, '��������������='+RAcc);
                  WriteLn(TF, '�������������='+RInn);
                  WriteLn(TF, '�������������='+RKpp);
                  DisperseStr(RClient, '����������', S, M);
                  WriteLn(TF, '����������=��� '+RInn+' '+S);
                  if Length(M)>0 then
                    Write(TF, M);
                  WriteLn(TF, '������������������='+RAcc);
                  DisperseStr(RBank, '��������������', S, M);
                  if Length(M)>0 then
                    Write(TF, M);
                  WriteLn(TF, '�������������='+RCode);
                  WriteLn(TF, '�����������������='+RKs);
                  WriteLn(TF, '����������='+VidToStr(PayRec.dbDoc.drIsp));
                  WriteLn(TF, '���������='+FillZeros(DocType, 2));
                  WriteLn(TF, '�����������='+IntToStr(PayRec.dbDoc.drOcher));
                  DisperseStr(Nazn, '�����������������', S, M);
                  WriteLn(TF, '�����������������='+S);
                  if Length(M)>0 then
                    Write(TF, M);
                  WriteLn(TF, '�����������������='+Status);
                  WriteLn(TF, '�������������='+Kbk);
                  WriteLn(TF, '�����='+Okato);
                  WriteLn(TF, '�������������������='+OsnPl);
                  WriteLn(TF, '�����������������='+Period);
                  WriteLn(TF, '����������������='+NDoc);
                  WriteLn(TF, '��������������='+DocDate);
                  WriteLn(TF, '��������������='+TipPl);
                  WriteLn(TF, '���������������='+Nchpl);
                  WriteLn(TF, '�����������='+Shifr);
                  WriteLn(TF, '����������='+Nplat);
                  WriteLn(TF, '������������='+OstSum);
                  WriteLn(TF, '��������������');
                  Res := 0;
                end;
              5:
                begin
                  with DbfDataSet3 do
                  begin
                    Append;
                    for I := 1 to NumOfFields3 do
                    begin
                      F := FindField(FldNames3[I]);
                      if F=nil then
                      begin
                        MessageBox(Application.MainForm.Handle,
                          PChar('�� ������� ���� ['+FldNames3[I]+']'),
                          MesTitle, MB_OK or MB_ICONERROR)
                      end
                      else begin
                        case I of
                          1: F.AsString := BtrDateToStr(PayRec.dbDoc.drDate);    {Date}
                          2: F.AsString := Number;  {Number}
                          3: F.AsFloat := PayRec.dbDoc.drSum/100.0;   {Summa}
                          4: F.AsInteger := DocType;
                          5: F.AsInteger := PayRec.dbDoc.drIsp;     {Vid pl}
                          6: F.AsInteger := PayRec.dbDoc.drOcher;
                          7: F.AsString := PBank;
                          8: F.AsString := PCode;
                          9: F.AsString := PKs;
                          10: F.AsString := PClient;
                          11: F.AsString := PAcc;
                          12: F.AsString := PInn;
                          13: F.AsString := PKpp;
                          14: F.AsString := RBank;
                          15: F.AsString := RCode;
                          16: F.AsString := RKs;
                          17: F.AsString := RClient;
                          18: F.AsString := RAcc;
                          19: F.AsString := RInn;
                          20: F.AsString := RKpp;
                          21: F.AsString := Nazn;
                          22: F.AsString := BtrDateToStr(PayRec.dbDoc.drSrok);
                          23: F.AsString := Status;
                          24: F.AsString := Kbk;
                          25: F.AsString := Okato;
                          26: F.AsString := OsnPl;
                          27: F.AsString := Period;
                          28: F.AsString := NDoc;
                          29: F.AsString := DocDate;
                          30: F.AsString := TipPl;
                          31: F.AsString := Nchpl;
                          32: F.AsString := Shifr;
                          33: F.AsString := Nplat;
                          34: F.AsString := OstSum;
                        end;
                      end;
                    end;
                    Post;
                    Res := 0;
                  end;
                end;
            end;
            if Res=0 then
            begin
              Inc(PayCount);
              PayRec.dbState := PayRec.dbState or dsExport;
              Res := DocDataSet.BtrBase.Update(PayRec, RecLen, Key, 0);
              if Res<>0 then
                MessageBox(Application.MainForm.Handle,
                  '�� ������� �������� ������', MesTitle, MB_OK or MB_ICONERROR);
            end;
          end;
          RecLen := SizeOf(PayRec);
          Res := DocDataSet.BtrBase.GetNext(PayRec, RecLen, Key, RangeIndex);
        end;
        if ExportFormat=4 then
        begin
          WriteLn(TF, '����������');
          CloseFile(TF);
        end;
        case Range of {"��������" ����. ����}
          0: {���}
            SetRegParamByName('LastExportId', CommonUserNumber, False, IntToStr(Key));
          1: {��}
            SetRegParamByName('LastExportIn', CommonUserNumber, False, IntToStr(Key));
        end;
      end
      else
        MessageBox(Application.MainForm.Handle, PChar('��� ������� �������� '+IntToStr(ExportFormat)
          +' ������� �� ����������'), MesTitle, MB_OK or MB_ICONERROR);
      if Range=0 then
        S := '���������'
      else
        S := '��������';
      MessageBox(Application.MainForm.Handle, PChar('����� �������������� '+S
        +': '+IntToStr(PayCount)), MesTitle, MB_OK or MB_ICONINFORMATION);
      CloseItemClick(nil);
    end;
  finally
    Screen.Cursor := crDefault;
    DocDataSet.Refresh;
  end;
  if CloseExport and not ((FirstExport=3) and (Range=0)) then
    Close;
end;

procedure TExportForm.ExportItemClick(Sender: TObject);
begin
  Exporting(0);
end;

procedure TExportForm.Export2ItemClick(Sender: TObject);
begin
  Exporting(1);
end;

var
  T: array[0..1023] of Char;

procedure TExportForm.DBGridDrawDataCell(Sender: TObject;
  const Rect: TRect; Field: TField; State: TGridDrawState);
var
  Size: TSize;
begin
  with (Sender as TDBGrid).Canvas do
  begin
    StrPLCopy(T, Field.Text, SizeOf(T));
    if DosCharset then
      DosToWin(T);
    Size := TextExtent(T);
    TextRect(Rect, Rect.Left+2, (Rect.Bottom + Rect.Top - Size.cy) div 2, T);
  end;
end;

procedure TExportForm.DelBaseItemClick(Sender: TObject);
const
  MesTitle: PChar = '��������';
var
  S: string;
begin
  CloseItemClick(nil);
  case ExportFormat of
    1:
      S := DbfDataSet1.TableName;
    2:
      S := DbfDataSet2.TableName;
    3:
      S := SdfDataSet1.TableName;
    5:
      S := DbfDataSet3.TableName;
    else
  end;
  if MessageBox(Handle, PChar('���� ������ ['+S+'] ����� �������. �� �������?'),
    MesTitle, MB_YESNOCANCEL or MB_ICONWARNING) = ID_YES then
  begin
    if DeleteFile(S) then
      MessageBox(Handle, PChar('���� ������ �������'), MesTitle,
        MB_OK or MB_ICONERROR)
    else
      MessageBox(Handle, PChar('�� ������� ������� ['+S+']'), MesTitle,
        MB_OK or MB_ICONERROR);
  end;
end;

procedure TExportForm.FormShow(Sender: TObject);
begin
  if (FirstExport=1) or (FirstExport=3) then
    ExportItemClick(nil);
  if (FirstExport=2) or (FirstExport=3) then
    Export2ItemClick(nil);
end;

end.
