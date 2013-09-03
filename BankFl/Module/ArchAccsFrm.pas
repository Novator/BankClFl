unit ArchAccsFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Grids, Db, DBTables, DBGrids, ExtCtrls, DBCtrls, BtrDS, Menus, AccountsFrm,
  SearchFrm, StdCtrls, ComCtrls, Common, Basbn, Utilits, CommCons;

type
  TArchAccsForm = class(TDataBaseForm)
    DataSource: TDataSource;
    DBGrid: TDBGrid;
    EditMenu: TMainMenu;
    FuncItem: TMenuItem;
    FindItem: TMenuItem;
    ArchPopupMenu: TPopupMenu;
    ChildStatusBar: TStatusBar;
    BtnPanel: TPanel;
    NameLabel: TLabel;
    SearchIndexComboBox: TComboBox;
    N1: TMenuItem;
    DelItem: TMenuItem;
    N3: TMenuItem;
    DelAllAccItem: TMenuItem;
    ValueEdit: TEdit;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FindItemClick(Sender: TObject);
    procedure SearchIndexComboBoxClick(Sender: TObject);
    procedure DelItemClick(Sender: TObject);
    procedure ValueEditChange(Sender: TObject);
    procedure ValueEditKeyPress(Sender: TObject; var Key: Char);
    procedure DelAllAccItemClick(Sender: TObject);
  private
    SearchForm: TSearchForm;
  public
  end;

const
  ArchAccsForm: TArchAccsForm = nil;

implementation

{$R *.DFM}

procedure TArchAccsForm.FormCreate(Sender: TObject);
begin
  ObjList.Add(Self);
  DataSource.DataSet := GlobalBase(biAccArc);
  TakeMenuItems(FuncItem, ArchPopupMenu.Items);
  ArchPopupMenu.Images := EditMenu.Images;
  SearchForm := TSearchForm.Create(Self);
  DefineGridCaptions(DBGrid, PatternDir+'ArchAccs.tab');
  SearchForm.SourceDBGrid := DBGrid;
  SearchIndexComboBox.ItemIndex := 0;
  SearchIndexComboBoxClick(Sender);
end;

procedure TArchAccsForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action:=caFree;
end;

procedure TArchAccsForm.FormDestroy(Sender: TObject);
begin
  ObjList.Remove(Self);
  ArchAccsForm := nil;
end;

procedure TArchAccsForm.FindItemClick(Sender: TObject);
begin
  SearchForm.ShowModal;
end;

procedure TArchAccsForm.SearchIndexComboBoxClick(Sender: TObject);
begin
  (DataSource.DataSet as TBtrDataSet).IndexNum := SearchIndexComboBox.ItemIndex
end;

procedure TArchAccsForm.DelItemClick(Sender: TObject);
const
  MesTitle: PChar = 'Удаление';
var
  N: Integer;
begin
  if not DataSource.DataSet.IsEmpty then
  begin
    DBGrid.SelectedRows.Refresh;
    N := DBGrid.SelectedRows.Count;
    if (N<2) and (MessageBox(Handle, PChar('Остаток будет удален. Вы уверены?'),
      MesTitle, MB_YESNOCANCEL or MB_ICONQUESTION) = IDYES)
      or (N>=2) and (MessageBox(Handle, PChar('Будет удалено остатков: '
      +IntToStr(DBGrid.SelectedRows.Count)+#13#10'Вы уверены?'),
      MesTitle, MB_YESNOCANCEL or MB_ICONQUESTION) = IDYES) then
    begin
      if N>0 then
      begin
        {ProtoMes(plInfo, MesTitle, 'Удаляется счет Id='
          +IntToStr(PAccRec(DataSource.DataSet.ActiveBuffer)^.arIder));}
        DBGrid.SelectedRows.Delete;
        DBGrid.SelectedRows.Refresh;
      end
      else
        DataSource.DataSet.Delete;
    end;
  end;
end;

procedure TArchAccsForm.ValueEditChange(Sender: TObject);
var
  K1: packed record
    kaDate: Word;      { Дата }                      {  4, 2   k0.1  k1.2}
    kaIder: Longint;   { Идер счета }                {  0, 4   k0.2  k1.1}
  end;
  K2: packed record
    kaIder: Longint;   { Идер счета }                {  0, 4   k0.2  k1.1}
    kaDate: Word;      { Дата }                      {  4, 2   k0.1  k1.2}
  end;
  P: Integer;
  S1, S2: string;
begin
  S1 := ValueEdit.Text;
  P := Pos('/', S1);
  if P>0 then
  begin
    S2 := Copy(S1, P+1, Length(S1)-P);
    S1 := Copy(S1, 1, P-1);
  end
  else
    S2 := '';
  case SearchIndexComboBox.ItemIndex of
    0:
      begin
        try
          K1.kaDate := StrToBtrDate(S1);
        except
          K1.kaDate := 0;
        end;
        try
          K1.kaIder := StrToInt(S2);
        except
          K1.kaIder := 0;
        end;
        TBtrDataSet(DataSource.DataSet).LocateBtrRecordByIndex(K1,
          SearchIndexComboBox.ItemIndex, bsGe);
      end;
    1:
      begin
        try
          K2.kaIder := StrToInt(S1);
        except
          K2.kaIder := 0;
        end;
        try
          K2.kaDate := StrToBtrDate(S2);
        except
          K2.kaDate := 0;
        end;
        TBtrDataSet(DataSource.DataSet).LocateBtrRecordByIndex(K2,
          SearchIndexComboBox.ItemIndex, bsGe);
      end;
  end;
end;

procedure TArchAccsForm.ValueEditKeyPress(Sender: TObject; var Key: Char);
begin
  if not ((Key in ['0'..'9', '/', '.']) or (Key < #32)) then
  begin
    Key := #0;
    MessageBeep(0)
  end;
end;

procedure TArchAccsForm.DelAllAccItemClick(Sender: TObject);
const
  MesTitle: PChar = 'Удаление истории счета';
var
  AccArcDataSet: TExtBtrDataSet;
  K2: packed record
    kaIder: Longint;   { Идер счета }                {  0, 4   k0.2  k1.1}
    kaDate: Word;      { Дата }                      {  4, 2   k0.1  k1.2}
  end;
  P, I, Res, Len: Integer;
  AccArcRec: TAccArcRec;
begin
  AccArcDataSet := DataSource.DataSet as TExtBtrDataSet;
  try
    I := StrToInt(ValueEdit.Text);
  except
    I := 0;
  end;
  K2.kaIder := I;
  K2.kaDate := 0;
  Len := SizeOf(AccArcRec);
  Res := AccArcDataSet.BtrBase.GetGE(AccArcRec, Len, K2, 1);
  if (Res=0) and (I=K2.kaIder) then
  begin
    if Application.MessageBox(PChar(
      'Вы уверны что хотите удалить историю счета Id='+IntToStr(I)
      +#13#10'При этом будет пересчет проводок с даты '+BtrDateToStr(AccArcRec.aaDate)
      +#13#10'и возможно затяжное закрытие операционных дней'), MesTitle,
      MB_YESNOCANCEL or MB_ICONWARNING)=ID_YES then
    begin
      P := 0;
      while (Res=0) and (I=K2.kaIder) do
      begin
        Res := AccArcDataSet.BtrBase.Delete(1);
        if Res=0 then
          Inc(P)
        else
          Application.MessageBox(PChar('Ошибка удаления Date='
            +BtrDateToStr(AccArcRec.aaDate)+' BtrErr='+IntToStr(Res)), MesTitle,
            MB_OK or MB_ICONERROR);
        Len := SizeOf(AccArcRec);
        Res := AccArcDataSet.BtrBase.GetNext(AccArcRec, Len, K2, 1);
      end;
      AccArcDataSet.First;
      Application.MessageBox(PChar('Всего удалено остатков '+IntToStr(P)), MesTitle,
        MB_OK or MB_ICONINFORMATION);
    end;
  end
  else
    Application.MessageBox(PChar('История по счету Id='+IntToStr(I)
      +'не найдена'), MesTitle, MB_OK or MB_ICONINFORMATION)
end;

end.
