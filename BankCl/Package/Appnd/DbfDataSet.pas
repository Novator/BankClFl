unit DbfDataSet;

interface

uses
  SysUtils, Classes, Db, DsgnIntf;

const
  EndHeaderChar: Char = #13;
  EndFileChar: Char = #$1A;
type
  TFilenameProperty = class(TStringProperty)
  public
    procedure Edit; override;
    function GetAttributes: TPropertyAttributes; override;
  end;

  EDBFError = class (Exception);

  pDateTime = ^TDateTime;
  pBoolean = ^Boolean;
  pInteger = ^Integer;

  PRecInfo = ^TRecInfo;
  TRecInfo = record
    Bookmark: Longint;
    BookmarkFlag: TBookmarkFlag;
  end;

  TDbfHeader = packed record  { Dbase III + header definition        }
    VersionNumber    :byte;  { version number (03h or 83h )              1}
    LastUpdateYear   :byte;  { last update YY MM DD                      1}
    LastUpdateMonth  :byte;                                             {1}
    LastUpdateDay    :byte;                                             {1}
    NumberOfRecords  :longint; { number of record in database            4}
    BytesInHeader    :smallint;{ number of bytes in header               2}
    BytesInRecords   :smallint;{ number of bytes in records              2}
    ReservedInHeader :array[1..20] of char;   { reserved bytes in header 20}
  end;                                                        {= 32}

  TDbfField = packed record
    fdName      :array[0..10] of char; { Name of this record            11}
    fdType      :Char;           { type of record - C,N,D,L,etc.         1}
    fdOffset    :Longint;        { offset                                4}
    fdWidth     :Byte;           { total field width of this record      1}
    fdDecimals  :Byte;           { number of digits to right of decimal  1}
    fdReserved  :array[1..14] of byte;      { 8 bytes reserved          14}
  end;                           { record starts                    = 32}

  PRecordHeader = ^TRecordHeader;
  TRecordHeader = record
    DeletedFlag : Char;
  end;

  TDbfDataSet = class(TDataSet)
  private
    FStream: TStream; // the physical table
    FTableName: string; // table path and file name
    FDBFHeader : TdbfHeader;       // record data
    FRecordHeaderSize : Integer;   // The size of the record header
    FRecordCount,                  // current number of record
    FRecordSize,                   // the size of the actual data
    FRecordBufferSize,             // data + housekeeping (TRecInfo)
    FRecordInfoOffset,             // offset of RecInfo in record buffer
    FCurrentRecord,                // current record (0 to FRecordCount - 1)
    BofCrack,                      // before the first record (crack)
    EofCrack: Integer;             // after the last record (crack)
    FIsTableOpen: Boolean;         // status
    FFileWidth,                    // field widths in record
    FFileDecimals,                 // field decimals in record
    FFileOffset: TList;            // field offsets in record
    FReadOnly : Boolean;           // Enhancements
    FStartData : Integer;          // Position in file where data starts
    procedure _ReadRecord(Buffer:PChar;IntRecNum: Integer);
    procedure _WriteRecord(Buffer:PChar;IntRecNum: Integer);
    procedure _AppendRecord(Buffer: PChar);
    procedure _SwapRecords(Rec1,REc2: Integer);
    function _CompareRecords(SortFields: array of String; Rec1,
      Rec2: Integer): Integer;
    function _ProcessFilter(Buffer: PChar): Boolean;
  protected
    procedure DBFToFieldType(const Fld: TDBFField; var FD: TFieldDef);
    procedure FieldToDBFDef(const FD: TField; var Fld: TDbfField);
  protected
    // TDataSet virtual abstract method
    function AllocRecordBuffer: PChar; override;
    procedure FreeRecordBuffer(var Buffer: PChar); override;
    procedure GetBookmarkData(Buffer: PChar; Data: Pointer); override;
    function GetBookmarkFlag(Buffer: PChar): TBookmarkFlag; override;
    function GetRecord(Buffer: PChar; GetMode: TGetMode; DoCheck: Boolean):
      TGetResult; override;
    function GetRecordSize: Word; override;
    procedure InternalAddRecord(Buffer: Pointer; Append: Boolean); override;
    procedure InternalClose; override;
    procedure InternalDelete; override;
    procedure InternalFirst; override;
    procedure InternalGotoBookmark(Bookmark: Pointer); override;
    procedure InternalHandleException; override;
    procedure InternalInitFieldDefs; override;
    procedure InternalInitRecord(Buffer: PChar); override;
    procedure InternalLast; override;
    procedure InternalOpen; override;
    procedure InternalPost; override;
    procedure InternalSetToRecord(Buffer: PChar); override;
    function IsCursorOpen: Boolean; override;
    procedure SetBookmarkFlag(Buffer: PChar; Value: TBookmarkFlag); override;
    procedure SetBookmarkData(Buffer: PChar; Data: Pointer); override;
    procedure SetFieldData(Field: TField; Buffer: Pointer); override;
    // TDataSet virtual method (optional)
    function GetRecordCount: Integer; override;
    procedure SetRecNo(Value: Integer); override;
    function GetRecNo: Integer; override;
    Procedure WriteHeader;
  public
    constructor Create(AOwner:tComponent); override;
    function GetFieldData(Field: TField; Buffer: Pointer): Boolean; override;
    procedure CreateTable;
    procedure PackTable;
    procedure SortTable(SortFields : array of String);
    procedure UnsortTable;
  published
    property TableName: string read FTableName write FTableName;
    property ReadOnly: Boolean read FReadOnly write FReadonly default False;
    property DBFHeader: TDBFHeader read FDBFHeader;
    // redeclared data set properties
    property Active;
    property Filter;
    property Filtered;
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
  TypInfo, Dialogs, Windows, Forms, Controls, IniFiles;

procedure TDbfDataSet._ReadRecord(Buffer: PChar; IntRecNum: Integer);
begin
 FStream.Position := FStartData + (FRecordSize * IntRecNum);
 try
   FStream.ReadBuffer(Buffer^, FRecordSize);
 except
 end;
end;

procedure TDbfDataSet._WriteRecord(Buffer: PChar; IntRecNum: Integer);
begin
  if not FReadOnly then
  begin
    FStream.Position := FStartData + (FRecordSize * IntRecNum);
    FStream.WriteBuffer (Buffer^, FRecordSize);
  end;
end;

procedure TDbfDataSet._AppendRecord(Buffer: PChar);
begin
  if not FReadOnly then
  begin
    FStream.Position := FStartData + (FRecordSize * (FRecordCount{+FDeletedCount}));
    FStream.WriteBuffer(Buffer^, FRecordSize);
  end;
end;

procedure TDbfDataSet.InternalOpen;
var
  Field : TField;
  I,J : integer;
  D : string;
begin
  if not FileExists(FTableName) then
    raise EDBFError.Create ('Open: Таблица не найдена');

  if FReadOnly then
    FStream := TFileStream.Create(FTableName, fmOpenRead or fmShareDenyWrite)
  else
    FStream := TFileStream.Create(FTableName, fmOpenReadWrite or fmShareExclusive);
  fStream.ReadBuffer(FDBFHeader, SizeOf(TDBFHeader));

  BofCrack := -1;
  EofCrack := FRecordCount;
  FCurrentRecord := BofCrack;

  BookmarkSize := sizeOf(Integer);

  if not (assigned(FFileOffset)) then
    FFileOffset := TList.Create;
  if not (assigned(FFileWidth)) then
    FFileWidth := TList.Create;
  if not (assigned(FFileDecimals)) then
    FFileDecimals := TList.Create;

  InternalInitFieldDefs;

  FRecordInfoOffset := FRecordSize;
  FRecordBufferSize := FRecordSize + SizeOf(TRecInfo);

  if DefaultFields then
    CreateFields;
  BindFields(True);

  for i := 0 to FieldCount-1 do
  begin
    Field := Fields[i];
    if (Field.DataType = ftFloat) and (Integer(FFileDecimals[i])>0) then
    begin
      d := '0.';
      for j := 1 to Integer(FFileDecimals[i]) do
        d := d + '0';
       (Field as TFloatField).DisplayFormat := d;
    end;
  end;

  // get the number of records and check size
  FRecordCount := fDBFHeader.NumberOfRecords;

  // everything OK: table is now open
  FIsTableOpen := True;

  // ShowMessage ('InternalOpen: RecCount: ' + IntToStr (FRecordCount));
end;

procedure TDbfDataSet.DBFToFieldType(const Fld: TDBFField; var FD: TFieldDef);
begin
  with FD do
  begin
    Size := 0;
    case Fld.fdType of
      'C':
        begin
          DataType := ftString;
          Size := Fld.fdWidth;
        end;
      'N', 'F':
        begin
          if Fld.fdDecimals>0 then
          begin
            DataType := ftFloat;
            Precision := Fld.fdDecimals;
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
    Name := Fld.fdName;
    Required := False;
  end;
end;

procedure TDbfDataSet.FieldToDBFDef(const FD: TField; var Fld: TDbfField);
begin
  FillChar(Fld, SizeOf(TDbfField), #0);
  with FD do
  begin
    StrPLCopy(Fld.fdName, FieldName, SizeOf(Fld.fdName));
    case DataType of
      ftFloat, ftInteger, ftLargeInt, ftWord, ftSmallInt:
        begin
          Fld.fdType := 'N';
          Fld.fdWidth := DisplayWidth;
          if (FD is TFloatField) then
            Fld.fdDecimals := (FD as TFloatField).Precision;
        end;
      ftBoolean:
        begin
          Fld.fdType := 'L';
          Fld.fdWidth := 1;
        end;
      ftDate:
        begin
          Fld.fdType := 'D';
          Fld.fdWidth := 8;
        end;
      else
        begin
          Fld.fdType := 'C';
          Fld.fdWidth := Size;
        end;
    end;
  end;
end;

procedure TDbfDataSet.InternalInitFieldDefs;
var
  Il: Integer;
  TmpFileOffset: Integer;
  NumberOfFields: Integer;
  Fld: TDBFField;
  FldName: array[0..11] of Char;
  NewFieldDef: TFieldDef;
begin
  FieldDefs.Clear;
  FStream.Seek(SizeOf(TDbfHeader), soFromBeginning);
  NumberOfFields := (FDbfHeader.BytesInHeader-SizeOf(DbfHeader)) div SizeOf(TDbfField);
  if not Assigned(FFileOffset) then
    FFileOffset := TList.Create;
  FFileOffset.Clear;
  if not Assigned(FFileWidth) then
    FFileWidth := TList.Create;
  FFileWidth.Clear;
  if not Assigned(FFileDecimals) then
    FFileDecimals := TList.Create;
  FFileDecimals.Clear;
  if NumberOfFields>0 then
    begin
      TmpFileOffset := 0;
      for Il := 0 to NumberOfFields-1 do
      begin
        FStream.Read(Fld, SizeOf(Fld));
        FFileOffset.Add(Pointer(TmpFileOffset));
        FFileWidth.Add(Pointer(Fld.fdWidth));
        FFileDecimals.Add(Pointer(Fld.fdDecimals));

        StrLCopy(FldName, Fld.fdName, SizeOf(FldName)-1);
        NewFieldDef := TFieldDef.Create(FieldDefs);
        DBFToFieldType(Fld, NewFieldDef);
        NewFieldDef.FieldNo := Il+1;

        Inc(TmpFileOffset, Fld.fdWidth);
      end;
      FRecordSize := TmpFileOffset + FrecordHeaderSize;
      FStartData := FDbfHeader.BytesInHeader;
    end;
end;

procedure TDbfDataSet.InternalClose;
begin
  // if required, save updated header
  if (fDBFHeader.NumberOfRecords <> FRecordCount) or
    (fDBFHeader.BytesInRecords = 0) then
  begin
    FDBFHeader.BytesInRecords := FRecordSize;
    FDBFHeader.NumberOfRecords := FRecordCount;
    WriteHeader;
  end;
  if not FReadOnly then
  begin
    FStream.Position := FStartData + (FRecordSize * FRecordCount);
    FStream.WriteBuffer(EndFileChar, 1);
  end;
  // disconnet field objects
  BindFields(False);
  // destroy field object (if not persistent)
  if DefaultFields then
    DestroyFields;

  // free the internal list field offsets
  if Assigned(FFileOffset) then
    FFileOffset.Free;
  FFileOffset := nil;
  if Assigned(FFileWidth) then
    FFileWidth.Free;
  FFileWidth := nil;
  if Assigned(FFileDecimals) then
    FFileDecimals.Free;
  FFileDecimals := nil;
  FCurrentRecord := -1;

  // close the file
  FIsTableOpen := False;
  FStream.Free;
  FStream := nil;
end;

function TDbfDataSet.IsCursorOpen: Boolean;
begin
  Result := FIsTableOpen;
end;

procedure TDbfDataSet.WriteHeader;
begin
  if (FStream <> nil) and not FReadOnly then
  begin
    FSTream.Seek(0, soFromBeginning);
    FStream.WriteBuffer(fDBFHeader, SizeOf(TDbfHeader));
  end;
end;

constructor TDbfDataSet.Create(AOwner:tComponent);
begin
  inherited create(aOwner);
  FRecordHeaderSize := SizeOf(TRecordHeader);
end;

function ParentWnd: hWnd;
begin
  Result := GetForegroundWindow {GetTopWindow(0)};
end;

procedure TDbfDataSet.CreateTable;
var
  Ix : Integer;
  Offs : Integer;
  Fld : TDbfField;
begin
  CheckInactive;
  // InternalInitFieldDefs;
  if not FileExists(FTableName) or
    (MessageBox(ParentWnd, PChar('Файл ' + FTableName +
      ' уже существует. Перезаписать его?'), 'Создание таблицы',
      MB_YESNOCANCEL+MB_ICONWARNING) = ID_YES) then
  begin
    if FieldDefs.Count = 0 then
    begin
      for Ix := 0 to FieldCount - 1 do
      begin
        with Fields[Ix] do
        begin
          if FieldKind = fkData then
            FieldDefs.Add(FieldName, DataType, Size, Required);
        end;
      end;
    end;
    FStream := TFileStream.Create(FTableName,
      fmCreate{ or fmShareExclusive});
    try
      FillChar(fDBFHeader, SizeOf(TDbfHeader), #0);
      WriteHeader;
      Offs := 0;
      for Ix := 0 to FieldCount - 1 do
      begin
        FieldToDBFDef(Fields[Ix], Fld);
        Fld.fdOffset := 1 + Offs;
        Inc(Offs, Fld.fdWidth);
        FStream.Write(Fld, SizeOf(TDbfField));
      end;
      FStream.Write(EndHeaderChar, 1);  {"заморочка" нортоновского просмотрщика}
      with FDbfHeader do
      begin
        VersionNumber := $03;
        BytesInHeader := FStream.Position;
        BytesInRecords := Offs;
      end;
      FRecordSize := Offs + FRecordHeaderSize;
      FStartData := FDbfHeader.BytesInHeader;
      WriteHeader;
    finally
      fStream.Free;
      fStream := nil;
    end;
  end;
end;

Procedure TDbfDataSet.PackTable;
var
  NewStream, OldStream : tStream;
  PC : PChar;
  Ix : Integer;
  //  DescribF : TBDescribField;
  NewDataFileHeader : tDBFHeader;
  DataBuffer : Pointer;
  NumberOfFields : integer;
  Fld : TDBFField;
BEGIN
  OldStream := Nil;
  NewStream := Nil;
  CheckInactive;
  //  if Active then
  //    raise eBinaryDataSetError.Create ('Dataset must be closed before packing.');
  if fTableName = '' then
    raise EDBFError.Create('Table name not specified.');
  if not FileExists (FTableName) then
    raise EDBFError.Create('Table '+fTableName+' does not exist.');
  PC := @fTablename[1];
  CopyFile(PChar(PC),PChar(PC+',old'+#0),False);
  // create the new file
  if FieldDefs.Count = 0 then
  begin
    for Ix := 0 to FieldCount - 1 do
    begin
      with Fields[Ix] do
      begin
        if FieldKind = fkData then
          FieldDefs.Add(FieldName,DataType,Size,Required);
      end;
    end;
  end;
  TRY
    NewStream := TFileStream.Create (FTableName+',new',
      fmCreate or fmShareExclusive);
    OldStream := tFileStream.Create (fTableName+',old',
      fmOpenRead or fmShareExclusive);
    OldStream.ReadBuffer(NewDataFileHeader,SizeOf(TDbfHeader));
    NewStream.WriteBuffer(NewDataFileHeader,SizeOf(TDbfHeader));
    NumberOfFields := ((NewDataFileHeader.BytesInHeader-sizeof(TDbfHeader))div 32);
    for IX := 0 to NumberOfFields do
      BEGIN
        OldStream.Read(Fld,SizeOf(TDbfField));
        NewStream.Write(Fld,SizeOf(TDbfField));
      END;
    GetMem(DataBuffer,NewDataFileHeader.BytesInRecords);
    REPEAT
      IX := OldStream.Read(DataBuffer^,NewDataFileHeader.BytesInRecords);
      if (IX = NewDataFileHeader.BytesInRecords) and (pRecordHeader(DataBuffer)^.DeletedFlag <> '*') then
        NewStream.WRite(DataBuffer^,NewDataFileHeader.BytesInRecords);
    Until IX <> NewDataFileHeader.BytesInRecords;
    FreeMem(DataBuffer,NewDataFileHeader.BytesInRecords);
  finally
    // close the file
    NewStream.Free;
    OldStream.Free;
  end;
  CopyFile(PChar(PC+',new'+#0),PChar(PC),False);
  DeleteFile(Pchar(PC+',new'+#0));
  DeleteFile(Pchar(PC+',old'+#0));
end;

procedure TDbfDataSet._SwapRecords(Rec1, Rec2: Integer);
var
  Buffer1, Buffer2 : PChar;
  Bookmark1, BOokmark2 : TBookmarkFlag;
begin
  if Rec1 < 0 then Exit;
  if Rec2 < 0 then Exit;
  Buffer1 := AllocRecordBuffer;
  Buffer2 := AllocRecordBuffer;
  _ReadRecord(Buffer1, Rec1);
  _ReadRecord(Buffer2, Rec2);
  Bookmark1 := GetBookmarkFlag(Buffer1);
  Bookmark2 := GetBookmarkFlag(Buffer2);
  SetBookmarkFlag(Buffer1,Bookmark2);
  SetBookmarkFlag(Buffer2,Bookmark1);
  _WriteRecord(Buffer1, Rec2);
  _WriteRecord(Buffer2, Rec1);
  StrDispose(Buffer1);
  StrDispose(Buffer2);
end;

function TDbfDataSet._CompareRecords(SortFields:Array of String;Rec1,Rec2:Integer):Integer; FAR;
{-Compare the records Rec1, Rec2 and return -1 if Rec1 < Rec2, 0 if Rec1 = Rec2,
  1 if Rec1 > Rec2 }
var
  IX : Integer;

  function CompareHelper(KeyId: string;Rec1,Rec2:Integer):Integer;
  var
    SKey1, SKey2 : string;
    IKey1, IKey2 : Integer;
    fKey1, fKey2 : Double;
    dKey1, dKey2 : tDateTime;
    CompareType : tFieldType;
    KeyField : tField;
  begin
    KeyField := FieldByName(KeyID);
    CompareType := KeyField.DataType;
    Case CompareType of
      ftFloat,
      ftCurrency,
      ftBCD :
        BEGIN
          _ReadRecord(ActiveBuffer,Rec1-1);
          fKey1 := KeyField.AsFloat;
          _ReadRecord(ActiveBuffer,Rec2-1);
          fKey2 := KeyField.AsFloat;
          if fKey1 < fKey2 then
            Result := -1
          else
            if fKey1 > fKey2 then
              Result := 1
            else
              Result := 0;
        END;
      ftSmallInt,
      ftInteger,
      ftWord :
        BEGIN
          _ReadRecord(ActiveBuffer, Rec1-1);
          IKey1 := KeyField.AsInteger;
          _ReadRecord(ActiveBuffer, Rec2-1);
          IKey2 := KeyField.AsInteger;
          if IKey1 < IKey2 then
            Result := -1
          else
            if IKey1 > IKey2 then
              Result := 1
            else
              Result := 0;
        END;
      ftDate,
      ftTime,
      ftDateTime :
        BEGIN
          _ReadRecord(ActiveBuffer, Rec1-1);
          dKey1 := KeyField.AsDateTime;
          _ReadRecord(ActiveBuffer, Rec2-1);
          dKey2 := KeyField.AsDateTime;
          if dKey1 < dKey2 then
            Result := -1
          else
            if dKey1 > dKey2 then
              Result := 1
            else
              Result := 0;
        END;
      else
        BEGIN
          _ReadRecord(ActiveBuffer, Rec1-1);
          SKey1 := KeyField.AsString;
          _ReadRecord(ActiveBuffer, Rec2-1);
          SKey2 := KeyField.AsString;
          if SKey1 < SKey2 then
            Result := -1
          else
            if SKey1 > SKey2 then
              Result := 1
            else
              Result := 0;
        END;
    END;
  END;

begin
  IX := 0;
  repeat // Loop through all available sortfields until not equal or no more sort fiels.
    Result := CompareHelper(SortFields[IX],Rec1,Rec2);
    Inc(IX);
  until (Result <> 0) or (IX > High(SortFields));
end;


procedure TDbfDataSet.SortTable(SortFields : Array of String);

  { This is the main sorting routine. It is passed the number of elements and the
    two callback routines. The first routine is the function that will perform
    the comparison between two elements. The second routine is the procedure that
    will swap two elements if necessary } // Source: UNDU #8

  procedure QSort(uNElem: Integer);
  { uNElem - number of elements to sort }

    procedure qSortHelp(pivotP: Integer; nElem: word);
    label
      TailRecursion,
      qBreak;
    var
      leftP, rightP, pivotEnd, pivotTemp, leftTemp: word;
      lNum: Integer;
      retval: integer;
    begin
      TailRecursion:
        if (nElem <= 2) then
          begin
            if (nElem = 2) then

              begin
                rightP := pivotP +1;
                if (_CompareRecords(SortFields,pivotP, rightP) > 0) then
                  _SwapRecords(pivotP, rightP);
              end;
            exit;
          end;
        rightP := (nElem -1) + pivotP;
        leftP :=  (nElem shr 1) + pivotP;
        { sort pivot, left, and right elements for "median of 3" }
        if (_CompareRecords(SortFields,leftP, rightP) > 0) then _SwapRecords(leftP, rightP);
        if (_CompareRecords(SortFields,leftP, pivotP) > 0) then _SwapRecords(leftP, pivotP)

        else if (_CompareRecords(SortFields,pivotP, rightP) > 0) then _SwapRecords(pivotP, rightP);
        if (nElem = 3) then
          begin
            _SwapRecords(pivotP, leftP);
            exit;
          end;
        { now for the classic Horae algorithm }
        pivotEnd := pivotP + 1;
        leftP := pivotEnd;
        repeat
          retval := _CompareRecords(SortFields,leftP, pivotP);
          while (retval <= 0) do
            begin
              if (retval = 0) then
                begin
                  _SwapRecords(LeftP, PivotEnd);
                  Inc(PivotEnd);
                end;
              if (leftP < rightP) then
                Inc(leftP)
              else
                goto qBreak;
              retval := _CompareRecords(SortFields,leftP, pivotP);
            end; {while}
          while (leftP < rightP) do
            begin

              retval := _CompareRecords(SortFields,pivotP, rightP);
              if (retval < 0) then
                Dec(rightP)
              else
                begin
                  _SwapRecords(leftP, rightP);
                  if (retval <> 0) then
                    begin
                      Inc(leftP);
                      Dec(rightP);
                    end;
                  break;
                end;
            end; {while}

        until (leftP >= rightP);
      qBreak:
        if (_CompareRecords(SortFields,leftP, pivotP) <= 0) then Inc(leftP);
        leftTemp := leftP -1;
        pivotTemp := pivotP;
        while ((pivotTemp < pivotEnd) and (leftTemp >= pivotEnd)) do
          begin
            _SwapRecords(pivotTemp, leftTemp);
            Inc(pivotTemp);
            Dec(leftTemp);
          end; {while}
        lNum := (leftP - pivotEnd);
        nElem := ((nElem + pivotP) -leftP);

        if (nElem < lNum) then
          begin
            qSortHelp(leftP, nElem);
            nElem := lNum;
          end
        else
          begin
            qSortHelp(pivotP, lNum);
            pivotP := leftP;
          end;
        goto TailRecursion;
      end; {qSortHelp }

  begin
    if (uNElem < 2) then  exit; { nothing to sort }
    qSortHelp(1, uNElem);
  end; { QSort }


BEGIN
  CheckActive;
  if FReadOnly then
    raise eDBFError.Create ('Dataset must be opened for read/write to perform sort.');
//  if fDataFileHeader.DeletedCount > 0 then
//    BEGIN
//      Close;
//      PackTable;
//      Open;
//    END;
  QSort(FRecordCount {+ fDeletedCount});
  First;
END;

procedure TDbfDataSet.UnsortTable;
var
  IX : Integer;
begin
  First;
  Randomize;
  for IX := 0 to RecordCOunt do
  begin
    _SwapRecords(IX, Random(RecordCount+1));
  end;
  First;
end;

procedure TDbfDataSet.InternalGotoBookmark(Bookmark: Pointer);
var
  ReqBookmark: Integer;
begin
  ReqBookmark := PInteger(Bookmark)^;
  //  ShowMessage ('InternalGotoBookmark: ' +
  //    IntToStr (ReqBookmark));
  if (ReqBookmark >= 0) and (ReqBookmark < FRecordCount {+ fDeletedCount}) then
    FCurrentRecord := ReqBookmark
  else
    raise eDBFError.Create ('Bookmark ' +
      IntToStr(ReqBookmark) + ' not found');
end;

procedure TDbfDataSet.InternalSetToRecord(Buffer: PChar);
var
  ReqBookmark: Integer;
begin
  ReqBookmark := PRecInfo(Buffer + FRecordInfoOffset).Bookmark;
  InternalGotoBookmark(@ReqBookmark);
end;

function TDbfDataSet.GetBookmarkFlag(Buffer: PChar): TBookmarkFlag;
begin
  Result := PRecInfo(Buffer + FRecordInfoOffset).BookmarkFlag;
end;

procedure TDbfDataSet.SetBookmarkFlag(Buffer: PChar;
  Value: TBookmarkFlag);
begin
  PRecInfo(Buffer + FRecordInfoOffset).BookmarkFlag := Value;
end;

procedure TDbfDataSet.GetBookmarkData(Buffer: PChar; Data: Pointer);
begin
  PInteger(Data)^ :=
    PRecInfo(Buffer + FRecordInfoOffset).Bookmark;
end;

procedure TDbfDataSet.SetBookmarkData(Buffer: PChar; Data: Pointer);
begin
  PRecInfo(Buffer + FRecordInfoOffset).Bookmark :=
    PInteger(Data)^;
end;

procedure TDbfDataSet.InternalFirst;
begin
  FCurrentRecord := BofCrack;
end;

procedure TDbfDataSet.InternalLast;
begin
  EofCrack := FRecordCount {+ fDeletedCount};
  FCurrentRecord := EofCrack;
end;

function TDbfDataSet.GetRecordCount: Longint;
begin
  CheckActive;
  Result := FRecordCount;
end;

function TDbfDataSet.GetRecNo: Longint;
begin
  UpdateCursorPos;
  if FCurrentRecord < 0 then
    Result := 1
  else
    Result := FCurrentRecord + 1;
end;

procedure TDbfDataSet.SetRecNo(Value: Integer);
begin
  CheckBrowseMode;
  if (Value > 1) and (Value <= (FRecordCount{+FDeletedCount})) then
  begin
    FCurrentRecord := Value - 1;
    Resync([]);
  end;
end;

function TDbfDataSet.GetRecordSize: Word;
begin
  Result := FRecordSize; // data only
end;

function TDbfDataSet.AllocRecordBuffer: PChar;
begin
  Result := StrAlloc(FRecordBufferSize+1);
end;

procedure TDbfDataSet.InternalInitRecord(Buffer: PChar);
(*var
  Field : TField;
  i : integer;
  FieldOffset : integer;
  S : string; *)
begin
  FillChar(Buffer^, FRecordBufferSize, 32);
  (*  for i := 0 to FieldCount-1 do
    begin
      Field := Fields[i];
      FieldOffset := Integer(FFileOffset[Field.FieldNo-1])+FRecordHeaderSize;
      if Field.DataType = ftString then
        begin
          pChar(Buffer+FieldOffset)^ := #0;
        end
      else if Field.DataType = ftFloat then
        begin
          pChar(Buffer+FieldOffset)^ := '0';
          pChar(Buffer+FieldOffset+1)^ := #0;
        end
      else if Field.DataType = ftDate then
        begin
          S := '19900101';
          CopyMemory(PChar(Buffer+FieldOffset),PChar(S),8);
        end
      else if Field.DataType = ftBoolean then
        begin
          pChar(Buffer+FieldOffset)^ := 'F';
        end;
    end; *)
end;

procedure TDbfDataSet.FreeRecordBuffer (var Buffer: PChar);
begin
  StrDispose(Buffer);
end;

function TDbfDataSet.GetRecord(Buffer: PChar;
  GetMode: TGetMode; DoCheck: Boolean): TGetResult;
var
  Acceptable : Boolean;
begin
  result := grOk;
  if FRecordCount < 1 then
    Result := grEOF
  else
    repeat
      case GetMode of
        gmCurrent :
          begin
            // ShowMessage ('GetRecord Current');
            if (FCurrentRecord >= FRecordCount{+fDeletedCount}) or
                (FCurrentRecord < 0) then
              Result := grError;
          end;
        gmNext :
          begin
            if (fCurrentRecord < (fRecordCount{+fDeletedCount})-1) then
              Inc (FCurrentRecord)
            else
              Result := grEOF;
          end;
        gmPrior :
          begin
           if (fCurrentRecord > 0) then
              Dec(fCurrentRecord)
           else
              Result := grBOF;
          end;
      end;
      // fill record data area of buffer
      if Result = grOK then
        begin
          _ReadRecord(Buffer, fCurrentRecord );
          {FStream.Position := FDataFileHeader.StartData +
          FRecordSize * FCurrentRecord;
          FStream.ReadBuffer (Buffer^, FRecordSize);}
          ClearCalcFields(Buffer);
          GetCalcFields(Buffer);
          with PRecInfo(Buffer + FRecordInfoOffset)^ do
            begin
              BookmarkFlag := bfCurrent;
              Bookmark := FCurrentRecord;
            end;
        end
      else
        if (Result = grError) and DoCheck then
          raise eDBFError.Create('GetRecord: Invalid record');
      Acceptable := pRecordHeader(Buffer)^.DeletedFlag <> '*';
      if Filtered then
        Acceptable := Acceptable and (_ProcessFilter(Buffer));
      if (GetMode=gmCurrent) and Not Acceptable then
        Result := grError;
    until (Result <> grOK) or Acceptable;
  if ((Result=grEOF)or(Result=grBOF)) and Filtered and not (_ProcessFilter(Buffer)) then
    Result := grError;
end;

procedure TDbfDataSet.InternalPost;
begin
  CheckActive;
  if State = dsEdit then
    begin
      // replace data with new data
      {FStream.Position := FDataFileHeader.StartData + (FRecordSize * FCurrentRecord);
      FStream.WriteBuffer (ActiveBuffer^, FRecordSize);}
      _WriteRecord(ActiveBuffer, FCurrentRecord);
    end
  else
    begin
      // always append
      InternalLast;
      {FStream.Seek (0, soFromEnd);
      FStream.WriteBuffer (ActiveBuffer^, FRecordSize);}
      pRecordHeader(ActiveBuffer)^.DeletedFlag := ' ';
      _AppendRecord(ActiveBuffer);
      Inc(FRecordCount);
    end;
end;

procedure TDbfDataSet.InternalAddRecord(Buffer:Pointer; Append:Boolean);
begin
  // always append
  InternalLast;
  // add record at the end of the file
  {FStream.Seek (0, soFromEnd);}
  pRecordHeader(ActiveBuffer)^.DeletedFlag := ' ';
  _AppendRecord(ActiveBuffer);
  {FStream.WriteBuffer (ActiveBuffer^, FRecordSize);}
  Inc(FRecordCount);
end;

procedure TDbfDataSet.InternalDelete;
begin
  CheckActive;
  // not supported in this version
{  raise eBinaryDataSetError.Create (
    'Delete: Operation not supported');}
//  pRecordHeader(ActiveBuffer)^.DeletedFlag := fDataFileHeader.LastDeleted;
  PChar(ActiveBuffer)^ := '*';
  _WriteRecord(ActiveBuffer, FCurrentRecord);
  {FStream.Position := FDataFileHeader.StartData + (FRecordSize * FCurrentRecord);
  FStream.WriteBuffer (ActiveBuffer^, FRecordSize);}
//  fDBFHeader.LastDeleted := GetRecNo;
//  Inc(fDeletedCount);
//  Dec(fRecordCount);
//  fDBFHeader.NumberOfRecords := fRecordCount;
//  WriteHeader;
  Resync([]);
end;

type
  PDate = ^TDate;

function TDbfDataSet.GetFieldData(Field: TField; Buffer: Pointer):Boolean;
const
  MesTitle: PChar = 'GetFieldData';
var
  FieldOffset, I, Err: Integer;
  S, OldDateFormat : string;
  D : Double;
  Buf: array[0..1023] of Char;
  Buf2: PChar;
begin
  Result := False;
  Buf2 := ActiveBuffer;
  if (FRecordCount>0) and (Field.FieldNo >= 0) and (Assigned(Buffer))
    and (Assigned(Buf2)) and (Field.FieldNo<=FFileOffset.Count) then
  begin
    FieldOffset := Integer(FFileOffset[Field.FieldNo-1])+FRecordHeaderSize;
    case Field.DataType of
      ftString:
        begin
          StrLCopy(Buffer, @Buf2[FieldOffset], Integer(FFileWidth[Field.FieldNo-1]));
          Result := True;
        end;
      ftFloat:
        begin
          StrLCopy(Buf, @Buf2[FieldOffset], Integer(FFileWidth[Field.FieldNo-1]));
          S := StrPas(Buf);
          Val(Trim(S), D, Err);
          PDouble(Buffer)^ := D;
          Result := True;
        end;
      ftInteger:
        begin
          StrLCopy(Buf, @Buf2[FieldOffset], Integer(FFileWidth[Field.FieldNo-1]));
          S := StrPas(Buf);
          Val(Trim(S), I, Err);
          PInteger(Buffer)^ := I;
          Result := True;
        end;
      ftDate:
        begin
          StrLCopy(Buf, @Buf2[FieldOffset], Integer(FFileWidth[Field.FieldNo-1]));
          S := StrPas(Buf);
          while Length(S)<8 do
            S := S+'0';
          S := Copy(S,7,2) + DateSeparator + Copy(S,5,2) + DateSeparator
            + Copy(S,1,4);
          OldDateFormat := ShortDateFormat;
          ShortDateFormat := 'dd/mm/yyyy';
          try
            try
              PInteger(Buffer)^ := Trunc(Double(StrToDate(S)))+693594;
              Result := True;
            except
            end;
          finally
            ShortDateFormat := OldDateFormat;
          end;
        end;
      ftBoolean:
        begin
          Result := True;
          if Buf2[FieldOffset] in ['S','T','Y'] then
            PBoolean(Buffer)^ := True
          else
            if Buf2[FieldOffset] in ['N','F'] then
              PBoolean(Buffer)^ := False
            else
              Result := False;
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

function CharCopy(Dest, Source: PChar; MaxLen: Cardinal): PChar;
var
  Len: Cardinal;
begin
  Len := StrLen(Source);
  if Len>MaxLen then
    Len := MaxLen;
  Move(Source^, Dest^, Len);
  Result := Dest;
end;

procedure TDbfDataSet.SetFieldData(Field: TField; Buffer: Pointer);
const
  MesTitle: PChar = 'SetFieldData';
var
  N, FieldOffset: Integer;
  Buf2 : PChar;
  S: string;
begin
  Buf2 := ActiveBuffer;
  if (Field.FieldNo >= 0) and Assigned(Buffer) and Assigned(Buf2) then
  begin
    FieldOffset := Integer(FFileOffset[Field.FieldNo-1])+FRecordHeaderSize;
    N := Integer(FFileWidth[Field.FieldNo-1]);
    case Field.DataType of
      ftString:
        CharCopy(@Buf2[FieldOffset], Buffer, N);
      ftFloat:
        begin
          Str(pDouble(Buffer)^:0:Integer(FFileDecimals[Field.FieldNo-1]), S);
          while Length(S)<N do
            S := ' '+S;
          CharCopy(@Buf2[FieldOffset], PChar(S), N);
        end;
      ftInteger:
        begin
          Str(PInteger(Buffer)^, S);
          while Length(S)<N do
            S := ' '+S;
          CharCopy(@Buf2[FieldOffset], PChar(S), N);
        end;
      ftDate:
        begin
          S := FormatDateTime('yyyymmdd', PInteger(Buffer)^-693594);
          CharCopy(@Buf2[FieldOffset], pChar(S), N);
        end;
      ftBoolean:
        begin
          if PBoolean(Buffer)^ then
            Buf2[FieldOffset] := 'T'
          else
            Buf2[FieldOffset] := 'F';
        end
      else
        MessageBox(ParentWnd, 'Недопустимый тип поля', MesTitle,
          MB_OK+MB_ICONERROR);
    end;
    DataEvent(deFieldChange, Longint(Field));
  end;
end;

procedure TDbfDataSet.InternalHandleException;
begin
  Application.HandleException(Self);
end;

function TDbfDataSet._ProcessFilter(Buffer:PChar):boolean;
var
  FilterExpresion : string;
  PosComp : integer;
  FName : string;
  FieldPos : integer;
  FieldOffset : integer;
  FieldValue : Variant;
  TestValue : Variant;
  FieldText : string;
  OldShortDateFormat : string;
begin
  FilterExpresion := Filter;
  PosComp := Pos('>',FilterExpresion);
  if PosComp=0 then
    PosComp := Pos('<',FilterExpresion);
  if PosComp=0 then
    PosComp := Pos('=',FilterExpresion);
  if PosComp=0 then
    begin
      _ProcessFilter := True;
      Exit;
    end;
  FName := Trim(Copy(FilterExpresion,1,PosComp-1));
  FieldPos := FieldDefs.IndexOf(FName);
  FieldOffset := integer(FFileOffset[FieldPos]);
  if FieldPos < 0 then
    _ProcessFilter := True
  else if FieldDefs.Items[FieldPos].DataType = ftString then
    begin // STRING
     try
      FieldValue := '';
      FieldOffset := FieldOffset+1;
      While (Buffer[FieldOffset]<>#0) and (Length(FieldValue)<integer(FFileWidth[FieldPos])) do
        begin
          FieldValue := FieldValue + Buffer[FieldOffset];
          FieldOffset := FieldOffset+1;
        end;
      FieldValue := Trim(FieldValue);
      TestValue := Trim(Copy(FilterExpresion,PosComp+2,Length(FilterExpresion)-PosComp-2));
      if FilterExpresion[PosComp]='=' then
        _ProcessFilter := (FieldValue=TestValue)
      else if FilterExpresion[PosComp]='>' then
        begin
          if FilterExpresion[PosComp+1]='=' then
            _ProcessFilter := (FieldValue>=Copy(TestValue,2,(Length(TestValue)-1)))
          else
            _ProcessFilter := (FieldValue>TestValue);
        end
      else if FilterExpresion[PosComp]='<' then
        begin
          if FilterExpresion[PosComp+1]='=' then
            _ProcessFilter := (FieldValue<=Copy(TestValue,2,(Length(TestValue)-1)))
          else
            _ProcessFilter := (FieldValue<TestValue);
        end
      else
        _ProcessFilter := False;
     except
       _ProcessFilter := False;
     end;
    end
  else if FieldDefs.Items[FieldPos].DataType = ftFloat then
    begin // FLOAT
     try
      FieldText := '';
      FieldOffset := FieldOffset+1;
      While (Buffer[FieldOffset]<>#0) and (Length(FieldText)<integer(FFileWidth[FieldPos])) do
        begin
          FieldText := FieldText + Buffer[FieldOffset];
          FieldOffset := FieldOffset+1;
        end;
      FieldText := Trim(FieldText);
      if Pos('.',FieldText)>0 then
        FieldText[Pos('.',FieldText)] := DecimalSeparator;
      FieldValue := StrToFloat(FieldText);
      if FilterExpresion[PosComp+1]='='then
        FieldText := Trim(Copy(FilterExpresion,PosComp+2,Length(FilterExpresion)-PosComp-1))
      else
        FieldText := Trim(Copy(FilterExpresion,PosComp+1,Length(FilterExpresion)-PosComp));
      if Pos('.',FieldText)>0 then
        FieldText[Pos('.',FieldText)] := DecimalSeparator;
      TestValue := StrToFloat(FieldText);
      if FilterExpresion[PosComp]='=' then
        _ProcessFilter := (FieldValue=TestValue)
      else if FilterExpresion[PosComp]='>'then
        begin
          if FilterExpresion[PosComp+1]='='then
            _ProcessFilter := (FieldValue>=TestValue)
          else
            _ProcessFilter := (FieldValue>TestValue);
        end
      else if FilterExpresion[PosComp]='<'then
        begin
          if FilterExpresion[PosComp+1]='='then
            _ProcessFilter := (FieldValue<=TestValue)
          else
            _ProcessFilter := (FieldValue<TestValue);
        end
      else
        _ProcessFilter := False;
     except
      _ProcessFilter := False;
     end;
    end
  else if FieldDefs.Items[FieldPos].DataType = ftDate then
    begin // DATE
      OldShortDateFormat := ShortDateFormat;
     try
      FieldText := '';
      FieldOffset := FieldOffset+1;
      While (Buffer[FieldOffset]<>#0) and (Length(FieldText)<integer(FFileWidth[FieldPos])) do
        begin
          FieldText := FieldText + Buffer[FieldOffset];
          FieldOffset := FieldOffset+1;
        end;
      FieldText := Trim(FieldText);
      FieldText := Copy(FieldText,1,4)+DateSeparator+Copy(FieldText,5,2)+DateSeparator+Copy(FieldText,7,2);
      ShortDateFormat := 'yyyy/mm/dd';
      FieldValue := StrToDate(FieldText);
      if FilterExpresion[PosComp+1]='=' then
        FieldText := Trim(Copy(FilterExpresion,PosComp+2,Length(FilterExpresion)-PosComp-1))
      else
        FieldText := Trim(Copy(FilterExpresion,PosComp+1,Length(FilterExpresion)-PosComp));
      FieldText := Copy(FieldText,1,4)+DateSeparator+Copy(FieldText,5,2)+DateSeparator+Copy(FieldText,7,2);
      TestValue := StrToDate(FieldText);
      if FilterExpresion[PosComp]='=' then
        begin
          _ProcessFilter := (FieldValue=TestValue);
        end
      else if FilterExpresion[PosComp]='>' then
        begin
          if FilterExpresion[PosComp+1]='='then
            _ProcessFilter := (FieldValue>=TestValue)
          else
            _ProcessFilter := (FieldValue>TestValue);
        end
      else if FilterExpresion[PosComp]='<' then
        begin
          if FilterExpresion[PosComp+1]='='then
            _ProcessFilter := (FieldValue<=TestValue)
          else
            _ProcessFilter := (FieldValue<TestValue);
        end
      else
        _ProcessFilter := False;
     except
      _ProcessFilter := False;
     end;
      ShortDateFormat := OldShortDateFormat;
    end
  else
    _ProcessFilter := False;
end;

procedure TFilenameProperty.Edit;
var
  FileOpen: TOpenDialog;
begin
  FileOpen := TOpenDialog.Create(Nil);
  FileOpen.Filename := GetValue;
  FileOpen.Filter := 'dBase Files (*.DBF)|*.DBF|All Files (*.*)|*.*';
  FileOpen.Options := FileOpen.Options + [ofPathMustExist, ofFileMustExist];
  try
    if FileOpen.Execute then SetValue(FileOpen.Filename);
  finally
    FileOpen.Free;
  end;
end;

function TFilenameProperty.GetAttributes: TPropertyAttributes;
begin
  Result := [paDialog, paRevertable];
end;

procedure Register;
begin
  RegisterComponents('BankClient', [TDbfDataSet]);
  RegisterPropertyEditor(TypeInfo(String), TDbfDataSet,
    'TableName', TFileNameProperty);
end;

end.
