unit SetupFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Grids, Db, DBTables, DBGrids, ExtCtrls, DBCtrls, BtrDS, Menus, Btrieve,
  SearchFrm, StdCtrls, Buttons, ParamFrm, ComCtrls, ToolEdit, Registr, Basbn;

type
  TSetupForm = class(TForm)
    BtnPanel: TPanel;
    TabControl: TTabControl;
    StringGrid: TStringGrid;
    CloseBtn: TBitBtn;
    StatusBar: TStatusBar;
    ChangeBtn: TBitBtn;
    procedure FormCreate(Sender: TObject);
    procedure TabControlChange(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure BtnPanelResize(Sender: TObject);
    procedure ChangeBtnClick(Sender: TObject);
    procedure StringGridKeyPress(Sender: TObject; var Key: Char);
  private
  public
  end;

const
  SetupForm: TSetupForm = nil;

implementation

{$R *.DFM}

function LocLevelIsSanctioned(ALevel: Byte): Boolean;
begin
  Result := {LevelIsSanctioned(ALevel)}True;
end;

procedure TSetupForm.FormCreate(Sender: TObject);
var
  RegistrBase: TBtrBase;
  ParamRec: TParamNewRec;
  ParamVec: TParamKey0;
  Res, Len: Integer;
begin
  BtnPanelResize(Sender);
  with StringGrid do
  begin
    ColCount := 4;
    ColWidths[0] := 35;
    ColWidths[1] := 200;
    ColWidths[2] := 290;
    ColWidths[3] := 15;
    Cells[1, 0] := '��������';
    Cells[2, 0] := '��������';
    Cells[3, 0] := '�';
  end;
  RegistrBase := GetRegistrBase;
  with RegistrBase do
  begin
    TabControl.Tabs.Clear;
    Len := SizeOf(ParamRec);
    Res := GetFirst(ParamRec, Len, ParamVec, 0);
    while (Res=0) and (ParamRec.pmSect=0) do
    begin
      if LocLevelIsSanctioned(ParamRec.pmLevel) then
        TabControl.Tabs.AddObject(ParamRec.pmName,
          TObject(ParamRec.pmNumber));
      Len := SizeOf(ParamRec);
      Res := GetNext(ParamRec, Len, ParamVec, 0);
    end;
  end;
  TabControlChange(Sender);
end;

(*procedure TSetupForm.UpdateClient(CopyCurrent, New: Boolean);
var
  ParamForm: TParamForm;
  ParamRec: TParamRec;
  I, Err, CurKeyNum: LongInt;
  Editing: Boolean;
  CurParamVec, ParamVec: packed record Sect: Word; Number: Integer end;
  W: Word;
  B: Boolean;
  D: Double;
begin
  ParamForm := TParamForm.Create(Self);
  with ParamForm do begin
    if CopyCurrent then begin
      TParamDataSet(DataSource.DataSet).GetBtrRecord(PChar(@ParamRec));
    end else begin
      FillChar(ParamRec, SizeOf(ParamRec), #0);
      ParamRec.pmType := ftString;
    end;
    {SectComboBox.Items.Clear;
    SectComboBox.Items.Add('������');}

    with TParamDataSet(DataSource.DataSet), SectComboBox.Items do
    begin
      with CurParamVec do
      begin
        Sect := ParamRec.pmSect;
        Number := ParamRec.pmNumber;
      end;
      CurKeyNum := KeyNum;
      KeyNum := 0;
      First;
      with ParamVec do
      begin
        Sect := 0;
        Number := 0;
      end;
      if LocateBtrRecordByIndex(ParamVec, 0, bsGe) then
      begin
        while (PParamRec(ActiveBuffer)^.pmSect = ParamVec.Sect)
          and not EoF and (Count<255) do
        begin
          Add(PParamRec(ActiveBuffer)^.pmName);
          Objects[Count-1] := Pointer(PParamRec(ActiveBuffer)^.pmNumber);
          Next;
        end;
      end;
      KeyNum := CurKeyNum;
      LocateBtrRecordByIndex(CurParamVec, 0, bsGe)
    end;
    with TypeComboBox.Items do
    begin
      Clear;
      Add('������');
      Add('����� �����');
      Add('�������������');
      Add('������� �����');
      Add('����');
      Add('�����������');
    end;
    with ParamRec do begin
      SectEdit.Text := IntToStr(pmSect);
      {SectComboBox.ItemIndex := SectComboBox.Items.IndexOfObject(Pointer(pmSect));}
      NumberEdit.Text := IntToStr(pmNumber);
      IdentEdit.Text := StrPas(pmIdent);
      NameEdit.Text := StrPas(pmName);
      case pmType of
        ftString: TypeComboBox.ItemIndex := 0;
        ftInteger: TypeComboBox.ItemIndex := 1;
        ftBoolean: TypeComboBox.ItemIndex := 2;
        ftFloat: TypeComboBox.ItemIndex := 3;
        ftDate: TypeComboBox.ItemIndex := 4;
        else TypeComboBox.ItemIndex := 5;
      end;
      MeasureEdit.Text := StrPas(pmMeasure);
      StringValueEdit.Text := ParamValueToStr(pmType, pmValue);
    end;
    Editing := True;
    while Editing and (ShowModal = mrOk) do begin
      Editing := False;
      with ParamRec do begin
        Val(SectEdit.Text, pmSect, Err);
        Val(NumberEdit.Text, pmNumber, Err);
        StrPCopy(pmIdent, IdentEdit.Text);
        StrPCopy(pmName, NameEdit.Text);
        StrPCopy(pmMeasure, MeasureEdit.Text);
        case TypeComboBox.ItemIndex of
          0: pmType := ftString;
          1: pmType := ftInteger;
          2: pmType := ftBoolean;
          3: pmType := ftFloat;
          4: pmType := ftDate;
          else pmType := ftUnknown;
        end;
        StrToParamValue(StringValueEdit.Text, pmType, pmValue);
      end;

      if New then begin
        if TParamDataSet(DataSource.DataSet).AddBtrRecord(@ParamRec,
          SizeOf(ParamRec))
        then
          DataSource.DataSet.Refresh
        else begin
          Editing := True;
          MessageDlg('',mtError,[mbOk,mbHelp],0);
          MessageBox(Handle, '���������� �������� ������','��������������',
            MB_OK + MB_ICONERROR)
        end;
      end else begin
        if TParamDataSet(DataSource.DataSet).UpdateBtrRecord(@ParamRec,
          SizeOf(ParamRec))
        then
          DataSource.DataSet.UpdateCursorPos
        else begin
          Editing := True;
          MessageBox(Handle, '���������� �������� ������','��������������',
            MB_OK + MB_ICONERROR)
        end;
      end;
    end;
    Free;
  end;
end;*)

procedure TSetupForm.TabControlChange(Sender: TObject);
var
  RegistrBase: TBtrBase;
  ParamRec: TParamNewRec;
  ParamVec: TParamKey0;
  Res, Len, R, ASect, C: Integer;
begin
  with StringGrid do
  begin
    Hide;
    RowCount := 2;
  end;
  if (TabControl.Tabs.Count>0)
    and (TabControl.TabIndex<TabControl.Tabs.Count)
  then
  begin
    ASect := Integer(TabControl.Tabs.Objects[TabControl.TabIndex]);
    RegistrBase := GetRegistrBase;
    with RegistrBase do
    begin
      R := 0;
      ParamVec.pkSect := ASect;
      ParamVec.pkNumber := 0;
      ParamVec.pkUser := 0;
      Len := SizeOf(ParamRec);
      Res := GetGE(ParamRec, Len, ParamVec, 0);
      C := 0;
      while (Res=0) and (ParamRec.pmSect=ASect) and (C<200) do
      begin
        ParamVec.pkUser := GetUserNumber;
        Len := SizeOf(ParamRec);
        Res := GetEqual(ParamRec, Len, ParamVec, 0);
        if Res<>0 then
        begin
          ParamVec.pkUser := CommonUserNumber;
          Len := SizeOf(ParamRec);
          Res := GetEqual(ParamRec, Len, ParamVec, 0);
        end;
        if Res=0 then
        begin
          with StringGrid, ParamRec do
          begin
            Inc(R);
            if RowCount<=R then
              RowCount := R+1;
            Cells[0, R] := IntToStr(pmNumber);
            Cells[1, R] := StrPas(pmName);
            Cells[2, R] := ParamValueToStr(ParamRec);
            if ParamRec.pmUser=CommonUserNumber then
              Cells[3, R] := ''
            else
              Cells[3, R] := '�';
          end;
        end
        else begin
          Len := SizeOf(ParamRec);
          Res := GetGE(ParamRec, Len, ParamVec, 0);
        end;
        Inc(ParamVec.pkNumber);
        Len := SizeOf(ParamRec);
        Res := GetGE(ParamRec, Len, ParamVec, 0);
        Inc(C);
      end;
      StringGrid.Show;
    end;
  end;
end;

procedure TSetupForm.FormDestroy(Sender: TObject);
begin
  SetupForm := nil;
end;

const
  BtnDist = 10;

procedure TSetupForm.BtnPanelResize(Sender: TObject);
begin
  ChangeBtn.Left := (BtnPanel.ClientWidth-ChangeBtn.Width-CloseBtn.Width-BtnDist) div 2;
  CloseBtn.Left := ChangeBtn.Left + ChangeBtn.Width + BtnDist;
end;

procedure TSetupForm.ChangeBtnClick(Sender: TObject);
var
  RegistrBase: TBtrBase;
  ParamRec: TParamNewRec;
  ParamVec: TParamKey0;
  Res, Len, I: Integer;
  ParamForm: TParamForm;
  C: TControl;
begin
  if ChangeBtn.Enabled then
  begin
    RegistrBase := GetRegistrBase;
    with RegistrBase do
    begin
      with ParamVec, StringGrid do
      begin
        pkSect := Integer(TabControl.Tabs.Objects[TabControl.TabIndex]);
        pkNumber := StrToInt(Cells[0, Row]);
        pkUser := GetUserNumber;
      end;
      Len := SizeOf(ParamRec);
      Res := GetEqual(ParamRec, Len, ParamVec, 0);
      if Res<>0 then
      begin
        ParamVec.pkUser := CommonUserNumber;
        Len := SizeOf(ParamRec);
        Res := GetEqual(ParamRec, Len, ParamVec, 0);
      end;
      if Res=0 then
      begin
        if LocLevelIsSanctioned(ParamRec.pmLevel) then
        begin
          ParamForm := TParamForm.Create(Self);
          with ParamForm do
          begin
            for I := 1 to ControlCount do
            begin
              C := Controls[I-1];
              if (C<>ValueEdit) and (C<>BoolComboBox) and (C<>DateValueEdit) then
              begin
                if C is TEdit then
                  with C as TEdit do
                  begin
                    ReadOnly := True;
                    ParentColor := True;
                  end
                else
                  if C is TComboBox then
                    with C as TComboBox do
                    begin
                      Enabled := False;
                      ParentColor := True;
                    end
                  else
                    if C is TDateEdit then
                      with C as TDateEdit do
                      begin
                        ReadOnly := True;
                        ParentColor := True;
                      end
              end;
            end;
            if EditParamRec(ParamRec, False, RegistrBase) then
            begin
              with StringGrid do
              begin
                Cells[2, Row] := ParamValueToStr(ParamRec);
                if ParamRec.pmUser=CommonUserNumber then
                  Cells[3, Row] := ''
                else
                  Cells[3, Row] := '�';
              end;
            end;
            Free
          end;
        end
        else
          MessageBox(Handle, '��� ������� �� ��������� ������������� ���� ��������',
            '��������������', MB_OK + MB_ICONINFORMATION)
      end;
    end;
  end;
end;

procedure TSetupForm.StringGridKeyPress(Sender: TObject; var Key: Char);
begin
  if Key=#13 then ChangeBtnClick(Sender)
end;

end.
