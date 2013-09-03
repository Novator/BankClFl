unit SdfDataSet;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Db;

type
  PSdfBookmarkInfo = ^TSdfBookmarkInfo;
  TSdfBookmarkInfo = record
    BookmarkData: Integer;
    BookmarkFlag: TBookmarkFlag;
  end;

  TSdfDataSet = class(TDataSet)
  private
    FTableName, FDescrName: TFileName;
    FRecordPos, FRecordSize, FBufferSize: Integer;
    FRecList: TStringList;
    FSeparator, FLimiter, FBreaker: Char;
    FDateFormat: string;
    FDateSeparator: Char;
    FSaveOnChange: Boolean;
    FIsTableOpen: Boolean;
    procedure SetTableName(const Value: TFileName);
  protected
    function AllocRecordBuffer: PChar; override;
    procedure FreeRecordBuffer(var Buffer: PChar); override;
    procedure InternalInitRecord(Buffer: PChar); override;
    function GetRecord(Buffer: PChar; GetMode: TGetMode;
      DoCheck: Boolean): TGetResult; override;
    function GetRecordSize: Word; override;
    procedure SetFieldData(Field: TField; Buffer: Pointer); override;

    procedure GetBookmarkData(Buffer: PChar; Data: Pointer); override;
    function GetBookmarkFlag(Buffer: PChar): TBookmarkFlag; override;
    procedure InternalGotoBookmark(Bookmark: Pointer); override;
    procedure InternalSetToRecord(Buffer: PChar); override;
    procedure SetBookmarkData(Buffer: PChar; Data: Pointer); override;
    procedure SetBookmarkFlag(Buffer: PChar; Value: TBookmarkFlag); override;

    procedure InternalFirst; override;
    procedure InternalInitFieldDefs; override;
    procedure InternalLast; override;
    procedure InternalClose; override;
    procedure InternalHandleException; override;
    procedure InternalDelete; override;
    procedure InternalAddRecord(Buffer: Pointer; Append: Boolean); override;
    procedure InternalOpen; override;
    procedure InternalPost; override;
    function IsCursorOpen: Boolean; override;
    function GetRecordCount: Integer; override;
    function GetRecNo: Integer; override;
    procedure SetRecNo(Value: Integer); override;
    procedure CheckSaveOnChange;
    procedure SetRecordSize(Value: Integer);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function GetFieldData(Field: TField; Buffer: Pointer): Boolean; override;
    procedure EmptyTable;
    procedure CreateTable;
  published
    property TableName: TFileName read FTableName write SetTableName;
    property RecordSize: Integer read FRecordSize write SetRecordSize;
    property Active;
    property BeforeOpen;
    property AfterOpen;
    property BeforeClose;
    property AfterClose;
    property BeforeInsert;
    property AfterInsert;
    property BeforeEdit;
    property AfterEdit;
    property BeforePost;
    property AfterPost;
    property BeforeCancel;
    property AfterCancel;
    property BeforeDelete;
    property AfterDelete;
    property BeforeScroll;
    property AfterScroll;
    property OnCalcFields;
    property OnDeleteError;
    property OnEditError;
    property OnNewRecord;
    property OnPostError;
  end;

procedure Register;

implementation

uses
  BDE, DBTables, DBConsts;

const
  feData = '.sdf';
  feFields = '.fld';

  DefRecordSize: Integer = 2048;
  DefSeparator: Char = ',';
  DefLimiter: Char = '"';
  DefBreaker: Char = '#';
  DefDateFormat: PChar = 'dd/mm/yyyy';
  DefDateSeparator: Char = '/';

constructor TSdfDataSet.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FRecList := TStringList.Create;

  SetRecordSize(DefRecordSize);

  FSeparator := DefSeparator;
  FLimiter := DefLimiter;
  FBreaker := DefBreaker;
  FSaveOnChange := False;
  FIsTableOpen := False;
  FDateFormat := StrPas(DefDateFormat);
  FDateSeparator := DefDateSeparator;
end;

destructor TSdfDataSet.Destroy;
begin
  FRecList.Free;
  inherited Destroy;
end;

procedure TSdfDataSet.SetRecordSize(Value: Integer);
begin
  FRecordSize := Value;
  FBufferSize := FRecordSize + SizeOf(TSdfBookmarkInfo);
end;

function TSdfDataSet.AllocRecordBuffer: PChar;
begin
  Result := AllocMem(FBufferSize);
end;

procedure TSdfDataSet.FreeRecordBuffer(var Buffer: PChar);
begin
  FreeMem(Buffer);
end;

procedure TSdfDataSet.InternalInitRecord(Buffer: PChar);
begin
  FillChar(Buffer^, FBufferSize, #0);
end;

function ParentWnd: hWnd;
begin
  Result := GetForegroundWindow {GetTopWindow(0)};
end;

procedure TSdfDataSet.InternalOpen;
const
  MesTitle: PChar = 'Открытие базы';
var
  F: TextFile;
  S: string;
begin
  if FileExists(FTableName) then
  begin
    if FileExists(FDescrName) then
    begin
      try
        FRecordPos := -1;
        BookmarkSize := SizeOf(Integer);
        InternalInitFieldDefs;
        if DefaultFields then
          CreateFields;
        BindFields(True);
        FRecList.Clear;
        AssignFile(F, FTableName);
        FileMode := 0;
        {$I-} Reset(F); {$I+}
        if IOResult=0 then
        begin
          while not System.EoF(F) do
          begin
            ReadLn(F, S);
            FRecList.Add(S);
          end;
          CloseFile(F);
          FIsTableOpen := True;
        end
        else
          MessageBox(ParentWnd, PChar('Ошибка открытия базы ['+TableName+']'), MesTitle,
            MB_OK+MB_ICONERROR);
      except
        MessageBox(ParentWnd, PChar('Ошибка открытия ['+TableName+']'), MesTitle,
          MB_OK+MB_ICONERROR);
        raise;
      end;
    end
    else
      MessageBox(ParentWnd, PChar('Файл описания полей ['+FDescrName+'] не найден'),
        MesTitle, MB_OK+MB_ICONERROR);
  end
  else
    MessageBox(ParentWnd, PChar('База ['+FTableName+'] не найдена'),
      MesTitle, MB_OK+MB_ICONERROR);
end;

function TSdfDataSet.GetRecord(Buffer: PChar; GetMode: TGetMode;
  DoCheck: Boolean): TGetResult;
begin
  if FRecList.Count <= 0 then
    Result := grEOF
  else begin
    Result := grOk;
    case GetMode of
      gmPrior:
        if FRecordPos <=0 then
        begin
          Result := grBOF;
          FRecordPos := -1;
        end
        else
          Dec(FRecordPos);
      gmCurrent:
        if (FRecordPos < 0) or (FRecordPos >= RecordCount) then
          Result := grError;
      gmNext:
        if FRecordPos >= RecordCount-1 then
          Result := grEOF
        else
          Inc(FRecordPos);
    end;
    if Result = grOk then
    begin
      StrPLCopy(Buffer, FRecList.Strings[FRecordPos], FBufferSize-1);
      with PSdfBookmarkInfo(@Buffer[FRecordSize])^ do
      begin
        BookmarkData := FRecordPos;
        BookmarkFlag := bfCurrent;
      end;
    end
    else
      if (Result = grError) and DoCheck then
        DatabaseError('No record');
  end;
end;

function TSdfDataSet.GetRecordSize: Word;
begin
  Result := FRecordSize;
end;

function GetFieldFromString(var S: string; Index: Integer; Sep,Lim: Char;
  var I,P0,P: Integer): string;
var
  L: Integer;
  InStr: Boolean;
begin
  InStr := False;
  I := 1;
  L := Length(S);
  P0 := 0; P := 0;
  while (I<=Index) and (P<L) do
  begin
    Inc(P);
    if InStr and (P<L) then
      InStr := not ((S[P]=Lim) and ((P>=L) or (S[P+1]=Sep)))
    else begin
      InStr := (S[P]=Lim)
        and ((P>1) and (S[P-1]=Sep) or (P<L) and (S[P+1]=Sep) or (P=L));
      if (S[P]=Sep) or (P=L) then
      begin
        Inc(I);
        if I=Index then
          P0 := P;
        if P=L then
          Inc(P);
      end;
    end;
  end;
  if I<=Index then
    Result := ''
  else
    Result := Copy(S, P0+1, P-P0-1);
end;

procedure SetFieldToString(var S: string; Index: Integer; V: string;
  Sep,Lim: Char);
var
  I,P0,P: Integer;
begin
  GetFieldFromString(S, Index, Sep, Lim, I, P0, P);
  if I<=Index then
  begin
    while I<=Index do
    begin
      S := S+Sep;
      Inc(I);
    end;
    S := S+V;
  end
  else
    S := Copy(S, 1, P0)+V+Copy(S, P, Length(S)-P+1);
end;

function StrFieldToStr(var S: string; Lim,Br: Char): string;
var
  I: Integer;
begin
  Result := S;
  I := Length(Result);
  if (I>1) and (Result[1]=Lim) and (Result[I]=Lim) then
    Result := Copy(Result, 2, I-2);
  I := Pos(Lim+Lim, Result);
  while I>0 do
  begin
    Delete(Result, I, 1);
    I := Pos(Lim+Lim, Result);
  end;
  I := Pos(Br, Result);
  while I>0 do
  begin
    Result := Copy(Result, 1, I-1)+#13#10+Copy(Result, I+1, Length(Result)-I);
    I := Pos(Br, Result);
  end;
end;

function StrToStrField(var S: string; Lim,Br: Char): string;
var
  L,I: Integer;
begin
  Result := S;
  L := Length(Result);
  I := 0;
  while I<L do
  begin
    Inc(I);
    if Result[I]=Lim then
    begin
      Result := Copy(Result, 1, I)+Copy(Result, I, L-I+1);
      Inc(L);
      Inc(I);
    end
    else
      if Result[I]=#13 then
      begin
        Result := Copy(Result, 1, I-1)+Br+Copy(Result, I+2, L-I-1);
        Dec(L);
      end;
  end;
  Result := Lim+Result+Lim;
end;

type
  PDate = ^TDate;
  PBoolean = ^Boolean;

function TSdfDataSet.GetFieldData(Field: TField; Buffer: Pointer):Boolean;
const
  MesTitle: PChar = 'Чтение поля';
var
  I, P0, P, Err: Integer;
  S, OldDateFormat: string;
  OldDateSeparator: Char;
  D: Double;
  ActBuf: PChar;
begin
  Result := False;

  ActBuf := ActiveBuffer;
  if (RecordCount>0) and (FRecordPos>=0) and (Assigned(Buffer))
    and (Assigned(ActBuf)) then
  begin
    S := StrPas(ActBuf);
    S := GetFieldFromString(S, Field.FieldNo, FSeparator, FLimiter, I,P0,P);
    case Field.DataType of
      ftString:
        begin
          S := StrFieldToStr(S, FLimiter, FBreaker);
          StrPLCopy(Buffer, S, Field.DataSize-1);
          Result := True;
        end;
      ftFloat:
        begin
          Val(Trim(S), D, Err);
          PDouble(Buffer)^ := D;
          Result := True;
        end;
      ftInteger:
        begin
          Val(Trim(S), I, Err);
          PInteger(Buffer)^ := I;
          Result := True;
        end;
      ftDate:
        begin
          OldDateFormat := ShortDateFormat;
          OldDateSeparator := DateSeparator;
          try
            DateSeparator := FDateSeparator;
            ShortDateFormat := FDateFormat;
            try
              PInteger(Buffer)^ := Trunc(Double(StrToDate(S)))+693594;
              Result := True;
            except
            end;
          finally
            DateSeparator := OldDateSeparator;
            ShortDateFormat := OldDateFormat;
          end;
        end;
      ftBoolean:
        begin
          Result := True;
          S := Trim(S);
          if S[1] in ['S','T','Y','д','Д','+','1'] then
            PBoolean(Buffer)^ := True
          else
            PBoolean(Buffer)^ := False
        end
      else
        begin
          MessageBox(ParentWnd, 'Недопустимый тип поля', MesTitle,
            MB_OK+MB_ICONERROR);
          Result := False;
        end;
    end;
  end;
end;

procedure TSdfDataSet.SetFieldData(Field: TField; Buffer: Pointer);
const
  MesTitle: PChar = 'Запись поля';
var
  S, V: string;
  ActBuf: PChar;
begin
  ActBuf := ActiveBuffer;
  if (RecordCount>0) and (Assigned(Buffer))
    and (Assigned(ActBuf)) then
  begin
    S := StrPas(ActBuf);
    case Field.DataType of
      ftString:
        begin
          V := StrPas(Buffer);
          V := StrToStrField(V, FLimiter, FBreaker);
        end;
      ftFloat:
        Str(pDouble(Buffer)^:0:5, V);
      ftInteger:
        Str(PInteger(Buffer)^, V);
      ftDate:
        V := FormatDateTime(FDateFormat, PInteger(Buffer)^-693594);
      ftBoolean:
        begin
          if PBoolean(Buffer)^ then
            V := 'T'
          else
            V := 'F';
        end
      else
        V := '';
    end;
    SetFieldToString(S, Field.FieldNo, V, FSeparator, FLimiter);
    StrPLCopy(ActBuf, S, FRecordSize-1);
    DataEvent(deFieldChange, Longint(Field));
  end;
end;

procedure TSdfDataSet.GetBookmarkData(Buffer: PChar; Data: Pointer);
begin
  PInteger(Data)^ := PSdfBookmarkInfo(@Buffer[FRecordSize])^.BookmarkData;
end;

function TSdfDataSet.GetBookmarkFlag(Buffer: PChar): TBookmarkFlag;
begin
  Result := PSdfBookmarkInfo(@Buffer[FRecordSize])^.BookmarkFlag;
end;

procedure TSdfDataSet.InternalGotoBookmark(Bookmark: Pointer);
begin
  FRecordPos := Integer(Bookmark);
end;

procedure TSdfDataSet.InternalSetToRecord(Buffer: PChar);
begin
  FRecordPos := PSdfBookmarkInfo(@Buffer[FRecordSize])^.BookmarkData;
end;

procedure TSdfDataSet.SetBookmarkData(Buffer: PChar; Data: Pointer);
begin
  PSdfBookmarkInfo(@Buffer[FRecordSize])^.BookmarkData := PInteger(Data)^;
end;

procedure TSdfDataSet.SetBookmarkFlag(Buffer: PChar; Value: TBookmarkFlag);
begin
  PSdfBookmarkInfo(@Buffer[FRecordSize])^.BookmarkFlag := Value;
end;

procedure TSdfDataSet.InternalFirst;
begin
  FRecordPos := -1;
end;

procedure DecodeField(Fld: string; var FD: TFieldDef);
const
  MesTitle: PChar = 'Инициализация поля';
var
  I, Err: Integer;
begin
  with FD do
  begin
    DataType := ftUnknown;
    Size := 0;
    Fld := Trim(Fld);
    if Length(Fld)>0 then
    begin
      I := Pos(',', Fld);
      if I>0 then
      begin
        Name := Copy(Fld, 1, I-1);
        Delete(Fld, 1, I);
      end
      else begin
        Name := Copy(Fld, 1, I);
        Fld := '';
      end;

      if Length(Fld)=0 then
        Fld := 'C';
      case Fld[1] of
        'C':
          begin
            DataType := ftString;
            I := Pos(':', Fld);
            if I>0 then
            begin
              Delete(Fld, 1, I);
              Val(Fld, I, Err);
              if Err<>0 then
              begin
                MessageBox(ParentWnd, PChar('Ошибочно задана длина поля '+Name),
                  MesTitle, MB_OK+MB_ICONERROR);
                I := 10;
              end;
            end
            else
              I := 10;
            Size := I;
          end;
        'N', 'F':
          begin
            I := Pos(':', Fld);
            if I>0 then
            begin
              Delete(Fld, 1, I);
              Val(Fld, I, Err);
              if Err<>0 then
              begin
                MessageBox(ParentWnd, PChar('Ошибочно задана дробь поля '+Name),
                  MesTitle, MB_OK+MB_ICONERROR);
                I := 0;
              end;
            end;
            if I>0 then
            begin
              DataType := ftFloat;
              Precision := I;
            end
            else
              DataType := ftInteger;
          end;
        'L':
          DataType := ftBoolean;
        'D':
          DataType := ftDate;
        else
          DataType := ftUnknown;
      end;
    end
    else
      MessageBox(ParentWnd, 'Пустое описание поля', MesTitle, MB_OK+MB_ICONERROR);
    Required := False;
  end;
end;

procedure CodeField(const FD: TField; var Fld: string);
begin
  with FD do
  begin
    Fld := '';
    case DataType of
      ftFloat, ftInteger, ftLargeInt, ftWord, ftSmallInt:
        begin
          Fld := Fld+'N';
          if (FD is TFloatField) then
            Fld := Fld + ':' + IntToStr((FD as TFloatField).Precision);
        end;
      ftBoolean:
        Fld := 'L';
      ftDate:
        Fld := 'D';
      else begin
        Fld := 'C:'+IntToStr(Size);
      end;
    end;
    if Length(Fld)>0 then
      Fld := ','+Fld;
    Fld := FieldName+Fld;
  end;
end;

const
  scCommon = 0;
  scFields = 1;
  NumOfSect = 2;
  SectNames: array[0..NumOfSect-1] of PChar = ('Common', 'Fields');

  pmSeparator = 0;
  pmLimiter = 1;
  pmBreaker = 2;
  pmRecordSize = 3;
  pmDateFormat = 4;
  pmDateSeparator = 5;
  NumOfParam = 6;
  ParamNames: array[0..NumOfParam-1] of PChar = ('Separator', 'Limiter',
    'Breaker', 'RecordSize', 'DateFormat', 'DateSeparator');

procedure TSdfDataSet.InternalInitFieldDefs;
const
  MesTitle: PChar = 'Инициализация полей по файлу описания ('+feFields+')';
var
  F: TextFile;
  S, N: string;
  NumOfFields, I, J, SectIndex: Integer;
  NewFieldDef: TFieldDef;
begin
  FieldDefs.Clear;
  if FileExists(FDescrName) then
  begin
    AssignFile(F, FDescrName);
    FileMode := 0;
    {$I-} Reset(F); {$I+}
    if IOResult=0 then
    begin
      SectIndex := -1;
      NumOfFields := 0;
      while not System.EoF(F) do
      begin
        ReadLn(F, S);
        if Length(S)>0 then
        begin
          if S[1]='[' then
          begin
            I := Pos(']', S);
            if I<=0 then
              I := Length(S)+1;
            S := UpperCase(Copy(S, 2, I-2));
            SectIndex := 0;
            while (SectIndex<NumOfSect) and (S<>UpperCase(SectNames[SectIndex])) do
              Inc(SectIndex);
            if SectIndex>=NumOfSect then
              SectIndex := -1;
          end
          else begin
            case SectIndex of
              scCommon:
                begin
                  I := Pos('=', S);
                  if I>0 then
                  begin
                    N := UpperCase(Copy(S, 1, I-1));
                    System.Delete(S, 1, I);
                    I := 0;
                    while (I<NumOfParam) and (N<>UpperCase(ParamNames[I])) do
                      Inc(I);
                    if I<NumOfParam then
                    begin
                      case I of
                        pmSeparator:
                          if Length(S)=1 then
                            FSeparator := S[1]
                          else
                            MessageBox(ParentWnd, PChar('Разделитель полей должен быть одним симолом ['+S+']'),
                              MesTitle, MB_OK+MB_ICONERROR);
                        pmLimiter:
                          if Length(S)=1 then
                            FLimiter := S[1]
                          else
                            MessageBox(ParentWnd, PChar('Ограничитель строк должен быть одним симолом ['+S+']'),
                              MesTitle, MB_OK+MB_ICONERROR);
                        pmBreaker:
                          if Length(S)=1 then
                            FBreaker := S[1]
                          else
                            MessageBox(ParentWnd, PChar('Разделитель строк должен быть одним симолом ['+S+']'),
                              MesTitle, MB_OK+MB_ICONERROR);
                        pmRecordSize:
                          begin
                            Val(S, I, J);
                            if J=0 then
                              RecordSize := I
                            else
                              MessageBox(ParentWnd, PChar('Неверно задан размер буфера ['+S+']'),
                                MesTitle, MB_OK+MB_ICONERROR);
                          end;
                        pmDateFormat:
                          begin
                            FDateFormat := S;
                          end;
                        pmDateSeparator:
                          begin
                            if Length(S)=1 then
                              FDateSeparator := S[1]
                            else
                              MessageBox(ParentWnd, PChar('Разделитель даты должен быть одним симолом ['+S+']'),
                                MesTitle, MB_OK+MB_ICONERROR);
                          end;
                      end
                    end
                    else
                      MessageBox(ParentWnd, PChar('Неизвестный параметр ['+N+']'),
                        MesTitle, MB_OK+MB_ICONERROR);
                  end
                  else
                    MessageBox(ParentWnd, PChar('Недопустимая строка ['+S+']'),
                      MesTitle, MB_OK+MB_ICONERROR);
                end;
              scFields:
                begin
                  NewFieldDef := TFieldDef.Create(FieldDefs);
                  DecodeField(S, NewFieldDef);
                  Inc(NumOfFields);
                  NewFieldDef.FieldNo := NumOfFields;
                end;
            end;
          end;
        end;
      end;
      CloseFile(F);
    end
    else
      MessageBox(ParentWnd, PChar('Не могу открыть файл описания полей ['+FDescrName+']'),
        MesTitle, MB_OK+MB_ICONERROR);
  end;
end;

procedure TSdfDataSet.CreateTable;
const
  MesTitle: PChar = 'Создание таблицы';
var
  I, Sect: Integer;
  S: string;
  F: TextFile;
begin
  CheckInactive;
  if not FileExists(FDescrName) or
    (MessageBox(ParentWnd, PChar('Файл описания ' + FTableName +
      ' уже существует. Перезаписать его?'), MesTitle,
      MB_YESNOCANCEL+MB_ICONWARNING) = ID_YES) then
  begin
    if FieldDefs.Count = 0 then
    begin
      for I := 0 to FieldCount - 1 do
      begin
        with Fields[I] do
        begin
          if FieldKind = fkData then
            FieldDefs.Add(FieldName, DataType, Size, Required);
        end;
      end;
    end;
    AssignFile(F, FDescrName);
    Rewrite(F);
    if IOResult=0 then
    begin
      for Sect := 0 to NumOfSect-1 do
      begin
        WriteLn(F, '['+SectNames[Sect]+']');
        case Sect of
          scCommon:
            begin
              for I := 0 to NumOfParam-1 do
              begin
                case I of
                  pmSeparator:
                    S := FSeparator;
                  pmLimiter:
                    S := FLimiter;
                  pmBreaker:
                    S := FBreaker;
                  pmRecordSize:
                    S := IntToStr(FRecordSize);
                  pmDateFormat:
                    S := FDateFormat;
                  pmDateSeparator:
                    S := FDateSeparator;
                  else
                    S := '';
                end;
                WriteLn(F, ParamNames[I]+'='+S);
              end;
            end;
          scFields:
            begin
              S := '';
              for I := 0 to FieldCount - 1 do
              begin
                CodeField(Fields[I], S);
                WriteLn(F, S);
              end;
            end;
        end;
      end;
      CloseFile(F);
      AssignFile(F, FTableName);
      Rewrite(F);
      if IOResult=0 then
      begin
        CloseFile(F);
        {EmptyTable;}
      end
      else
        MessageBox(ParentWnd, PChar('Не удалось создать базу ['+FTableName+']'),
          MesTitle, MB_OK+MB_ICONERROR);
    end
    else
      MessageBox(ParentWnd, PChar('Не удалось создать файл описания ['+FDescrName+']'),
        MesTitle, MB_OK+MB_ICONERROR);
  end;
end;

procedure TSdfDataSet.InternalLast;
begin
  FRecordPos := FRecList.Count;
end;

procedure TSdfDataSet.InternalClose;
begin
  FRecList.SaveToFile(FTableName);
  FRecList.Clear;
  if DefaultFields then
    DestroyFields;
  FIsTableOpen := False;
  FRecordPos := -1;
end;

procedure TSdfDataSet.InternalHandleException;
begin
  Application.HandleException(Self);
end;

procedure TSdfDataSet.InternalDelete;
begin
  FRecList.Delete(FRecordPos);
  if FRecordPos >= FRecList.Count then
    Dec(FRecordPos);
end;

procedure TSdfDataSet.CheckSaveOnChange;
begin
  if FSaveOnChange then
    FRecList.SaveToFile(FTableName);
end;

procedure TSdfDataSet.InternalAddRecord(Buffer: Pointer; Append: Boolean);
var
  RecPos: Integer;
begin
  if Append then
  begin
    FRecList.Add(PChar(Buffer));
    InternalLast;
  end
  else begin
    if FRecordPos = -1 then
      RecPos := 0
    else
      RecPos := FRecordPos;
    FRecList.Insert(RecPos, PChar(Buffer));
  end;
  CheckSaveOnChange;
end;

procedure TSdfDataSet.InternalPost;
var
  RecPos: Integer;
begin
  if FRecordPos<0 then
    RecPos := 0
  else
    if FRecordPos>=FRecList.Count then
      RecPos := FRecList.Count-1
    else
      RecPos := FRecordPos;
  if FRecList.Count<=0 then
    FRecList.Add(StrPas(ActiveBuffer))
  else
    FRecList.Strings[RecPos] := StrPas(ActiveBuffer);
end;

function TSdfDataSet.IsCursorOpen: Boolean;
begin
  Result := FIsTableOpen;
end;

function TSdfDataSet.GetRecordCount: Integer;
begin
  Result := FRecList.Count;
end;

function TSdfDataSet.GetRecNo: Integer;
begin
  UpdateCursorPos;
  if FRecordPos < 0 then
    Result := 1
  else
    Result := FRecordPos + 1;
end;

procedure TSdfDataSet.SetRecNo(Value: Integer);
begin
  CheckBrowseMode;
  if (Value > 0) and (Value <= RecordCount) then
  begin
    FRecordPos := Value - 1;
    Resync([]);
  end;
end;

procedure TSdfDataSet.SetTableName(const Value: TFileName);
begin
  CheckInactive;
  FTableName := Value;
  if ExtractFileExt(FTableName) = '' then
    FTableName := FTableName + feData;
  FDescrName := ChangeFileExt(FTableName, feFields);
end;

procedure TSdfDataSet.EmptyTable;
begin
  FRecList.Clear;
  FRecordPos := -1;
  Refresh;
end;

procedure Register;
begin
  RegisterComponents('BankClient', [TSdfDataSet]);
end;

end.
