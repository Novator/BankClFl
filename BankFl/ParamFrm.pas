unit ParamFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Mask, Buttons, ToolEdit, Db, Registr, BtrDS, Utilits, Btrieve, Basbn;

type
  TParamForm = class(TForm)
    OkBtn: TBitBtn;
    CancelBtn: TBitBtn;
    TypeComboBox: TComboBox;
    TypeLabel: TLabel;
    NpNameLabel: TLabel;
    ValueEdit: TEdit;
    NameLabel: TLabel;
    NameEdit: TEdit;
    MeasureEdit: TEdit;
    MeasureLabel: TLabel;
    BoolComboBox: TComboBox;
    Label1: TLabel;
    DefValueEdit: TEdit;
    DefBoolComboBox: TComboBox;
    MaxValueLabel: TLabel;
    MinValueLabel: TLabel;
    MaxValueEdit: TEdit;
    MinValueEdit: TEdit;
    DateValueEdit: TDateEdit;
    DefDateValueEdit: TDateEdit;
    IdentLabel: TLabel;
    IdentEdit: TEdit;
    PrivateCheckBox: TCheckBox;
    procedure TypeComboBoxClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    function EditParamRec(var ParamRec: TParamNewRec; New: Boolean;
      RegBase: TBtrBase): Boolean;
  end;

var
  ParamForm: TParamForm;

implementation

{$R *.DFM}


procedure TParamForm.TypeComboBoxClick(Sender: TObject);
begin
  BoolComboBox.Hide;
  DefBoolComboBox.Hide;
  MinValueEdit.Hide;
  MaxValueEdit.Hide;
  MinValueLabel.Hide;
  MaxValueLabel.Hide;
  ValueEdit.Hide;
  DefValueEdit.Hide;
  DateValueEdit.Hide;
  DefDateValueEdit.Hide;
  case TypeComboBox.ItemIndex of
    1:    {Целое число}
      begin
        ValueEdit.Width := 70;
        ValueEdit.Show;
        DefValueEdit.Width := ValueEdit.Width;
        DefValueEdit.Show;
        MinValueEdit.Show;
        MaxValueEdit.Show;
        MinValueLabel.Show;
        MaxValueLabel.Show;
      end;
    2:      {Переключатель}
      begin
        BoolComboBox.Show;
        DefBoolComboBox.Show;
      end;
    3:     {Дробное число}
      begin
        ValueEdit.Width := 70;
        ValueEdit.Show;
        DefValueEdit.Width := ValueEdit.Width;
        DefValueEdit.Show;
        MinValueEdit.Show;
        MaxValueEdit.Show;
        MinValueLabel.Show;
        MaxValueLabel.Show;
      end;
    4:       {Дата}
      begin
        DateValueEdit.Show;
        DefDateValueEdit.Show;
      end;
    else begin
      ValueEdit.Width := 379;
      ValueEdit.Show;
      DefValueEdit.Width := ValueEdit.Width;
      DefValueEdit.Show;
    end;
  end;
end;

procedure TParamForm.FormCreate(Sender: TObject);
begin
  DefBoolComboBox.Items := BoolComboBox.Items;
  BoolComboBox.Left := ValueEdit.Left;
  DefBoolComboBox.Left := BoolComboBox.Left;
  DateValueEdit.Left := BoolComboBox.Left;
  DefDateValueEdit.Left := BoolComboBox.Left;
end;

function TParamForm.EditParamRec(var ParamRec: TParamNewRec; New: Boolean;
  RegBase: TBtrBase): Boolean;
const
  MesTitle: PChar = 'Редактирование параметра';
var
  I, Err: LongInt;
  Editing: Boolean;
  ParamVec: TParamKey0;
  ParamRec2: TParamNewRec;
  Sect, User: Word;
  Number: Integer;
  Ident: TParamIdent;
  Level: Byte;
begin
  Result := False;
  with ParamRec do
  begin
    Sect := pmSect;
    Number := pmNumber;
    Ident := pmIdent;
    Level := pmLevel;
    User := pmUser;
    NameEdit.Text := StrPas(pmName);
    MeasureEdit.Text := StrPas(pmMeasure);
    PrivateCheckBox.Checked := False;
    if pmUser<>CommonUserNumber then
    begin
      if pmUser=GetUserNumber then
        PrivateCheckBox.Checked := True
      else
        PrivateCheckBox.State := cbGrayed;
    end;
    IdentEdit.Text := Copy(StrPas(Ident), 1, SizeOf(Ident));
    case pmType of
      ftString:
        begin
          ValueEdit.Text := StrPas(pmStrValue);
          DefValueEdit.Text := StrPas(@pmStrValue[Length(ValueEdit.Text)+1]);
          TypeComboBox.ItemIndex := 0;
        end;
      ftInteger:
        begin
          ValueEdit.Text := IntToStr(pmIntValue);
          MinValueEdit.Text := IntToStr(pmMinIntValue);
          MaxValueEdit.Text := IntToStr(pmMaxIntValue);
          DefValueEdit.Text := IntToStr(pmDefIntValue);
          TypeComboBox.ItemIndex := 1;
        end;
      ftBoolean:
        begin
          if pmBoolValue then
            BoolComboBox.ItemIndex := 1
          else
            BoolComboBox.ItemIndex := 0;
          if pmDefBoolValue then
            DefBoolComboBox.ItemIndex := 1
          else
            DefBoolComboBox.ItemIndex := 0;
          TypeComboBox.ItemIndex := 2;
        end;
      ftFloat:
        begin  
          ValueEdit.Text := FloatToStr(pmFltValue);  
          MinValueEdit.Text := FloatToStr(pmMinFltValue);
          MaxValueEdit.Text := FloatToStr(pmMaxFltValue);
          DefValueEdit.Text := FloatToStr(pmDefFltValue);
          TypeComboBox.ItemIndex := 3;  
        end;
      ftDate:
        begin
          DateValueEdit.Date := StrToDate(BtrDateToStr(pmDateValue));
          DefDateValueEdit.Date := StrToDate(BtrDateToStr(pmDefDateValue));
          TypeComboBox.ItemIndex := 4;
        end;
      else
        begin
          ValueEdit.Text := StrPas(@pmBuffer);
          TypeComboBox.ItemIndex := 5;
        end;
    end;
    TypeComboBoxClick(Self);
  end;
  Editing := True;
  while Editing and (ShowModal = mrOk) do
  begin
    Editing := False;
    FillChar(ParamRec, SizeOf(ParamRec), #0);
    with ParamRec do
    begin
      pmUser := User;
      pmSect := Sect;
      pmNumber := Number;
      pmIdent := Ident;
      pmLevel := Level;
      case PrivateCheckBox.State of
        cbUnchecked:
          begin
            if pmUser<>CommonUserNumber then
            begin
              with ParamVec do
              begin
                pkSect := pmSect;
                pkNumber := pmNumber;
                pkUser := pmUser;
              end;
              Err := SizeOf(ParamRec2);
              if RegBase.GetEqual(ParamRec2, Err, ParamVec, 0)=0 then
              begin
                if RegBase.Delete(0)<>0 then
                  MessageBox(Handle, 'Не удалось убрать личную запись', MesTitle,
                    MB_OK or MB_ICONERROR);
              end;
              pmUser := CommonUserNumber;
            end;
          end;
        cbChecked:
          begin
            if pmUser<>GetUserNumber then
            begin
              pmUser := GetUserNumber;
              with ParamVec do
              begin
                pkSect := pmSect;
                pkNumber := pmNumber;
                pkUser := pmUser;
              end;
              Err := SizeOf(ParamRec2);
              if RegBase.GetEqual(ParamRec2, Err, ParamVec, 0)<>0 then
                New := True;
            end;
          end;
        cbGrayed:;
      end;
      StrPCopy(pmName, NameEdit.Text);
      StrPCopy(pmMeasure, MeasureEdit.Text);
      case TypeComboBox.ItemIndex of
        0:
          begin
            pmType := ftString;
            StrPCopy(pmStrValue, ValueEdit.Text);
            StrPCopy(@pmStrValue[Length(ValueEdit.Text)+1], DefValueEdit.Text);
          end;
        1:
          begin
            pmType := ftInteger;
            pmIntValue := StrToInt(ValueEdit.Text);
            pmMinIntValue := StrToInt(MinValueEdit.Text);
            pmMaxIntValue := StrToInt(MaxValueEdit.Text);
            pmDefIntValue := StrToInt(DefValueEdit.Text);
            Editing := not ((pmMinIntValue=0) and (pmMaxIntValue=0)
              or (pmMinIntValue<=pmIntValue) and (pmIntValue<=pmMaxIntValue));
            if Editing then
              MessageBox(Handle, 'Число вне допустимого диапазона', MesTitle,
                MB_OK or MB_ICONERROR);
          end;
        2:
          begin
            pmType := ftBoolean;
            pmBoolValue := BoolComboBox.ItemIndex = 1;
            pmDefBoolValue := DefBoolComboBox.ItemIndex = 1;
          end;
        3:
          begin
            pmType := ftFloat;
            pmFltValue := StrToFloat(ValueEdit.Text);
            pmMinFltValue := StrToFloat(MinValueEdit.Text);
            pmMaxFltValue := StrToFloat(MaxValueEdit.Text);
            pmDefFltValue := StrToFloat(DefValueEdit.Text);
            Editing := not ((pmMinFltValue=0) and (pmMaxFltValue=0)
              or (pmMinFltValue<=pmFltValue) and (pmFltValue<=pmMaxFltValue));
            if Editing then
              MessageBox(Handle, 'Число вне допустимого диапазона', MesTitle,
                MB_OK or MB_ICONERROR);
          end;
        4:
          begin
            pmType := ftDate;
            pmDateValue := StrToBtrDate(DateValueEdit.Text);
            pmDefDateValue := StrToBtrDate(DefDateValueEdit.Text);
          end;
        else begin
          pmType := ftUnknown;
          StrToParamValue(ValueEdit.Text, pmType, pmBuffer);
        end;
      end;
    end;

    if not Editing then
    begin
      I := GetParamLen(ParamRec);
      with ParamVec do
      begin
        pkSect := ParamRec.pmSect;
        pkNumber := ParamRec.pmNumber;
        pkUser := ParamRec.pmUser;
      end;
      if New then
      begin
        if RegBase.Insert(ParamRec, I, ParamVec, 0) <> 0 then
        begin
          Editing := True;
          MessageDlg('',mtError,[mbOk,mbHelp],0);
          MessageBox(Handle, 'Невозможно добавить запись', MesTitle,
            MB_OK or MB_ICONERROR)
        end;
      end
      else begin
        Err := SizeOf(ParamRec2);
        if (RegBase.GetEqual(ParamRec2, Err, ParamVec, 0)<>0)
          or (RegBase.Update(ParamRec, I, ParamVec, 0) <> 0) then
        begin
          Editing := True;
          MessageBox(Handle, 'Невозможно изменить запись', MesTitle,
            MB_OK or MB_ICONERROR)
        end;
      end;
    end;
  end;
  Result := not Editing;
end;

end.
