unit FirmsFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Grids, Db, DBTables, DBGrids, ExtCtrls, DBCtrls, BtrDS, Menus, Deals,
  StdCtrls, Buttons, ComCtrls, SearchFrm, FirmFrm;

type
  TFirmsForm = class(TDataBaseForm)
    DataSource: TDataSource;
    DBGrid: TDBGrid;
    StatusBar: TStatusBar;
    BtnPanel: TPanel;
    OkBtn: TBitBtn;
    CancelBtn: TBitBtn;
    NameEdit: TEdit;
    SearchIndexComboBox: TComboBox;
    MainMenu: TMainMenu;
    OperItem: TMenuItem;
    FindItem: TMenuItem;
    InsItem: TMenuItem;
    DelItem: TMenuItem;
    EditBreaker: TMenuItem;
    NameLabel: TLabel;
    EditItem: TMenuItem;
    CopyItem: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure NameEditChange(Sender: TObject);
    procedure SearchIndexComboBoxChange(Sender: TObject);
    procedure BtnPanelResize(Sender: TObject);
    procedure FindItemClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure InsItemClick(Sender: TObject);
    procedure EditItemClick(Sender: TObject);
    procedure DelItemClick(Sender: TObject);
    procedure CopyItemClick(Sender: TObject);
    procedure DBGridDblClick(Sender: TObject);
  private
    procedure UpdateFirm(CopyCurrent, New: Boolean);
  public
    SearchForm: TSearchForm;
    procedure TakePrintData(var PrintForm: TFileName;
      var ADBGrid: TDBGrid); override;
  end;

  TFirmDataSet = class(TBtrDataSet)
  protected
    procedure InternalInitFieldDefs; override;
  public
    property ActiveRecord;
    function GetFieldData(Field: TField; Buffer: Pointer): Boolean; override;
    constructor Create(AOwner: TComponent);
  end;

var
  ObjList: TList;

implementation

{$R *.DFM}

constructor TFirmDataSet.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FBufSize := SizeOf(TFirmRec);
end;

procedure TFirmDataSet.InternalInitFieldDefs;
begin
  FieldDefs.Clear;
  TFieldDef.Create(FieldDefs,'clAccC',ftString,20,False,0);
  TFieldDef.Create(FieldDefs,'clInn',ftString,16,False,1);
  TFieldDef.Create(FieldDefs,'clKpp',ftString,16,False,2);
  TFieldDef.Create(FieldDefs,'clNameC',ftString,44,False,3);
end;

function TFirmDataSet.GetFieldData(Field: TField; Buffer: Pointer): Boolean;
var
  I: integer;
begin
  Result := true;
  case Field.Index of
    0: StrLCopy(Buffer, @(PFirmRec(ActiveBuffer)^.clAccC), SizeOf(TAccount));
    1: StrLCopy(Buffer, PFirmRec(ActiveBuffer)^.clInn, SizeOf(TInn));
    2: StrLCopy(Buffer, PFirmRec(ActiveBuffer)^.clKpp, SizeOf(TInn));
    3: begin
      I:=0;
      while (I<clMaxVar) and (PFirmRec(ActiveBuffer)^.clNameC[I]<>#13)
        and (PFirmRec(ActiveBuffer)^.clNameC[I]<>#0) do begin
        Inc(I);
      end;
      StrLCopy(Buffer, @(PFirmRec(ActiveBuffer)^.clNameC),I);
      DosToWin(Buffer);
    end;
  end;
end;

{procedure TFirmForm.AfterScrollDS(DataSet: TDataSet);
begin
  NameEdit.Text:=DataSet.Fields.Fields[5].AsString;
end;}

procedure TFirmsForm.FormCreate(Sender: TObject);
begin
  ObjList.Add(Self);
  DataSource.DataSet := TFirmDataSet.Create(Self);
  with DataSource.DataSet as TFirmDataSet do begin
    FKeyNum := 2;
    FBufSize := SizeOf(TFirmRec)+64;
    SetTableName(BaseDir+'Firm.btr');
    Active := true;
{    AfterScroll:=AfterScrollDS;}
  end;
  DefineGridCaptions(DBGrid, PatternDir+'Firms.tab');
  SearchForm:=TSearchForm.Create(Self);
  SearchIndexComboBox.ItemIndex:=2;
end;

procedure TFirmsForm.FormDestroy(Sender: TObject);
begin
  ObjList.Remove(Self);
end;

procedure TFirmsForm.TakePrintData(var PrintForm: TFileName;
  var ADBGrid: TDBGrid);
begin
  ADBGrid:=DBGrid;
  PrintForm:='Firm.pfm';
end;


procedure TFirmsForm.NameEditChange(Sender: TObject);
var
  T: array[0..512] of Char;
  I,Err: LongInt;
  SearchData: packed record Bik: LongInt; Acc: TAccount end;
  S: string;
begin
  case SearchIndexComboBox.ItemIndex of
    0:
    begin
      S:=NameEdit.Text;
      I:=Pos('/',S);
      if I>0 then begin
        StrPCopy(SearchData.Acc,Copy(S,I+1,Length(S)-I));
        S:=Copy(S,1,I-1);
      end else StrCopy(SearchData.Acc,'');
      while Length(S)<8 do S:=S+'0';
      Val(S,SearchData.Bik,Err);
      TBtrDataSet(DataSource.DataSet).LocateBtrRecordByIndex(SearchData,0,bsGe);
    end;
    else begin
      StrPCopy(T,NameEdit.Text);
      WinToDos(T);
      (DataSource.DataSet as TBtrDataSet).LocateBtrRecordByIndex(
        T, SearchIndexComboBox.ItemIndex, bsGe);
    end;
  end;
end;

procedure TFirmsForm.SearchIndexComboBoxChange(Sender: TObject);
begin
  (DataSource.DataSet as TBtrDataSet).KeyNum:=SearchIndexComboBox.ItemIndex
end;

const
  BtnDist=6;

procedure TFirmsForm.BtnPanelResize(Sender: TObject);
begin
  CancelBtn.Left:=BtnPanel.ClientWidth-CancelBtn.Width-2*BtnDist;
  OkBtn.Left:=CancelBtn.Left-OkBtn.Width-BtnDist;
end;

procedure TFirmsForm.FindItemClick(Sender: TObject);
begin
  SearchForm.ShowModal;
end;

procedure TFirmsForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if FormStyle=fsMDIChild then Action:=caFree;
end;

procedure TFirmsForm.UpdateFirm(CopyCurrent, New: Boolean);
var
  FirmForm: TFirmForm;
  FirmRec: TFirmRec;
  Err: Integer;
  T: array[0..512] of Char;
begin
  FirmForm := TFirmForm.Create(Self);
  with FirmForm do begin
    FillChar(FirmRec,SizeOf(FirmRec),#0);
    if CopyCurrent then
      TFirmDataSet(DataSource.DataSet).GetBtrRecord(PChar(@FirmRec));
    with FirmRec do begin
      DosToWin(clNameC);
      StrLCopy(T,clAccC,SizeOf(clAccC));
      RsEdit.Text := StrPas(T);
      StrLCopy(T,clInn,SizeOf(clInn));
      InnEdit.Text := StrPas(T);
      StrLCopy(T,clKpp,SizeOf(clKpp));
      KppEdit.Text := StrPas(T);
      NameMemo.Text := StrPas(clNameC);
    end;
    if ShowModal = mrOk then begin
      with FirmRec do begin
        StrPCopy(clAccC,RsEdit.Text);
        StrPCopy(clInn,InnEdit.Text);
        StrPCopy(clKpp,KppEdit.Text);
        StrPCopy(clNameC,NameMemo.Text);
        WinToDos(clNameC);
      end;
      if New then begin
        if TFirmDataSet(DataSource.DataSet).AddBtrRecord(PChar(@FirmRec),
          SizeOf(FirmRec))
        then
          DataSource.DataSet.Refresh
        else
          MessageBox(Handle, 'Невозможно добавить запись', 'Редактирование',
            MB_OK + MB_ICONERROR);
      end else begin
        if TFirmDataSet(DataSource.DataSet).UpdateBtrRecord(PChar(@FirmRec),
          SizeOf(FirmRec))
        then
          DataSource.DataSet.UpdateCursorPos
        else
          MessageBox(Handle, 'Невозможно изменить запись', 'Редактирование',
            MB_OK + MB_ICONERROR);
      end;
    end;
    Free;
  end;
end;

procedure TFirmsForm.InsItemClick(Sender: TObject);
begin
  UpdateFirm(False,True);
end;

procedure TFirmsForm.EditItemClick(Sender: TObject);
begin
  UpdateFirm(True,False);
end;

procedure TFirmsForm.CopyItemClick(Sender: TObject);
begin
  UpdateFirm(True,True)
end;

procedure TFirmsForm.DelItemClick(Sender: TObject);
begin
  if MessageBox(Handle, 'Фирма будет удалена из списка. Вы уверены?',
    'Удаление', MB_YESNOCANCEL + MB_ICONQUESTION) = IDYES
  then
    DataSource.DataSet.Delete;
end;

procedure TFirmsForm.DBGridDblClick(Sender: TObject);
begin
  if FormStyle=fsMDIChild then EditItemClick(Sender)
  else ModalResult := mrOk;
end;

end.
