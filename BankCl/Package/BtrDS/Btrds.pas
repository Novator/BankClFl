unit BtrDS;

interface

uses Windows, Db, Classes, Btrieve, SysUtils, Forms;

type
  TBtrSearchOption  = (bsEq,bsGt,bsGe,bsLt,bsLe);
  TBtrOpenMode = (bmNormal, bmAccelerated, bmReadOnly, bmExclusive);

type
  TBtrDataSet = class(TDataSet)
  public
    FName:      string;
    FCB:        array[0..127] of byte;
    FKeyBuf:    array[0..255] of byte;
    FDesc:      PBtrInfoArray;
    FKeyList:   PBtrIndexArray;
    FAltPtr:    pchar;
    FBufSize:   integer;
    FCurPos:    integer;
    FLwb:       pointer;
    FUpb:       pointer;
    FKeyCnt:    byte;
    FKeyNum:    byte;
    FKeySegs:   byte;
    FMyState:   byte;
    FMode:      TBtrOpenMode;
    procedure SetTableName(const Value: string);
  protected
    function AllocRecordBuffer: PChar; override;
    procedure FreeRecordBuffer(var Buffer: PChar); override;
    procedure InternalInitRecord(Buffer: PChar); override;
    function GetRecord(Buffer: PChar; GetMode: TGetMode;
                       DoCheck: Boolean): TGetResult; override;
    function GetRecordSize: Word; override;
//    procedure SetFieldData(Field: TField; Buffer: pointer); override;
    procedure GetBookMarkData(Buffer: PChar; Data: pointer); override;
    function GetBookMarkFlag(Buffer: PChar): TBookMarkFlag; override;
    procedure InternalGotoBookMark(BookMark: Pointer); override;
    procedure InternalSetToRecord(Buffer: PChar); override;
    procedure SetBookMarkFlag(Buffer: PChar; Value: TBookMarkFlag); override;
    procedure SetBookMarkData(Buffer: PChar; Data: Pointer); override;
    procedure InternalFirst; override;
    procedure InternalLast; override;
//    procedure InternalAddRecord(Buffer: Pointer; Append: boolean); override;
    procedure InternalDelete; override;
//    procedure InternalPost; override;
    procedure InternalClose; override;
    procedure InternalHandleException; override;
//    procedure InternalInitFieldDefs; override;
    procedure InternalOpen; override;
    function IsCursorOpen: Boolean; override;
    function GetRecordCount: Integer; override;
    function GetRecNo: integer; override;
    procedure SetRecNo(Value: integer); override;
    function CheckBtrError(Res: integer; ValidRes: array of integer): boolean; virtual;
    function KeySize(Index: byte): integer; virtual;
//    function ValidKeyValue(Buffer: pchar; Index: byte): boolean; virtual;
    function CompareKeys(Key1, Key2: pointer; Index: byte): integer; virtual;
//    procedure GetKeyValue(Buffer: pchar; Key: pointer; Index: byte); virtual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function BookmarkValid(Bookmark: TBookmark): Boolean; override;
    function CompareBookmarks(Bookmark1, Bookmark2: TBookmark): Integer; override;
//    function GetFieldData(Field: TField; Buffer: Pointer): Boolean; override;
    procedure UpdateKeys;
    function GetBtrRecord(Buffer: pchar): word; virtual;
    function AddBtrRecord(Buffer: pchar; Len: word): boolean; virtual;
    function UpdateBtrRecord(Buffer: pchar; Len: word): boolean; virtual;
    function FindBtrRecordByIndex(Buffer: pchar; var Len: word; var Value;
                                  Index: byte; Opt: TBtrSearchOption): boolean; virtual;
    function LocateBtrRecordByIndex(var Value; Index: byte; Opt: TBtrSearchOption): boolean; virtual;
    procedure SetIndex(Value: byte); virtual;
    procedure SetBufSize(Value: integer); virtual;
    procedure SetMode(Value: TBtrOpenMode); virtual;
    procedure SetRange(LValue, UValue: pointer); virtual;
    procedure Resync(Mode: TResyncMode); override;
    function GetLastRec(AKeyNum: Integer; Buffer: PChar): Boolean;
    function GetActiveRecLen: Integer;
  published
    property Active;
    property TableName: string read FName write SetTableName;
    property BufSize: integer read FBufSize write SetBufSize;
    property IndexNum: byte read FKeyNum write SetIndex;
    property Mode: TBtrOpenMode read FMode write SetMode;
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
    property OnDeleteError;
    property OnEditError;
  end;

  TExtBtrDataSet = class(TBtrDataSet)
  private
    FBtrBase: TBtrBase;
  protected
    procedure DoAfterOpen; override;
    {procedure DoBeforeClose; override;}
  public
    property BtrBase: TBtrBase read FBtrBase;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

procedure Register;

implementation

const
  msClosed    = 0;
  msUnDefined = 1;
  msBof       = 2; //Перед первой
  msEof       = 3; //После последней
  msDeleted   = 4; //После удаления текущей записи
  msDefined   = 5; //Адрес текущей записи в Btr совпадает с FCurPos
  msDirect    = 6; //Адрес текущей записи в Btr может не совпадать с FCurPos

const
  BtrSeachOpCodes: array [TBtrSearchOption] of word =
      (boGetEqual, boGetGT, boGetGE, boGetLT, boGetLE);

  BtrOpenModes: array [TBtrOpenMode] of byte =
      (0, $FF, $FE, $FC);

type
  PBtrRecInfo = ^TBtrRecInfo;
  TBtrRecInfo = record
    BtrRecordLen: integer;
//    BtrPercent:   integer;
    BookMarkData: integer;
    BookMarkFlag: TBookMarkFlag;
  end;

constructor TBtrDataSet.Create(AOwner: TComponent);
begin
  Inherited Create(AOwner);
  FBufSize := SizeOf(integer);
//  FKeyNum := 0;
//  FMode := baNormal;
//  FMyState := msClosed;
  BookMarkSize := SizeOf(integer);
end;

destructor TBtrDataSet.Destroy;
begin
  if(Active) then
    Active := false;
//  FName := '';
  Inherited Destroy;
end;

function TBtrDataSet.AllocRecordBuffer: PChar;
begin
  Result := AllocMem(FBufSize+SizeOf(TBtrRecInfo));
end;

procedure TBtrDataSet.FreeRecordBuffer(var Buffer: PChar);
begin
  FreeMem(Buffer);
end;

procedure TBtrDataSet.InternalInitRecord(Buffer: PChar);
begin
  FillChar(Buffer^,FBufSize+SizeOf(TBtrRecInfo),0);
end;

function TBtrDataSet.GetRecord(Buffer: PChar; GetMode: TGetMode;
                               DoCheck: Boolean): TGetResult;
var
  Res, Len: integer;
  OpCode: word;
begin
  Result := grOk;
//  Res := 0;
  case GetMode of
    gmPrior:
      OpCode := boGetPrev;
    gmNext:
      OpCode := boGetNext;
    gmCurrent:
      OpCode := boGetDirect;
  end;
  case FMyState of
    msBof:
      if(GetMode<>gmNext) then
        Result := grBOF
      else if(FLwb=nil) then
        OpCode := boGetFirst
      else
        begin
          OpCode := boGetGE;
          Move(FLwb^,FKeyBuf,KeySize(FKeyNum));
        end;
    msEof:
      if(GetMode<>gmPrior) then
        Result := grEOF
      else if(FUpb=nil) then
        OpCode := boGetLast
      else
        begin
          OpCode := boGetLE;
          Move(FUpb^,FKeyBuf,KeySize(FKeyNum));
        end;
    msDirect:
      begin
        PInteger(Buffer)^ := FCurPos;
        if(GetMode<>gmCurrent) then begin
          Len := FBufSize;
          Res := BtrCall(boGetDirect,FCB,Buffer^,Len,FKeyBuf,255,FKeyNum);
          if(Res=0) then
            FMyState := msDefined
          else
            Result := grError;
        end;
      end;
    msDefined:
      begin
        if(GetMode=gmCurrent) then
          PInteger(Buffer)^ := FCurPos;
      end;
    msDeleted:
      if(GetMode=gmCurrent) then
        Result := grError;
    msUndefined, msClosed:
      Result := grError;
  end;
  if(Result=grOk) then
    begin
      Len := FBufSize;
      Res := BtrCall(OpCode,FCB,Buffer^,Len,FKeyBuf,255,FKeyNum);
      if(Res=0) then
        begin
          if(((FLwb=nil) Or (CompareKeys(@FKeyBuf,FLwb,FKeyNum)>=0)) And
             ((FUpb=nil) Or (CompareKeys(@FKeyBuf,FUpb,FKeyNum)<=0))) then
            begin
              FMyState := msDefined;
              with PBtrRecInfo(Buffer+FBufSize)^ do
                begin
                  BtrRecordLen := Len;
                  BookMarkFlag := bfCurrent;
                  Len := SizeOf(integer);
                  Res := BtrCall(boGetPos,FCB,BookMarkData,Len,FKeyBuf,255,FKeyNum);
                  CheckBtrError(Res,[]);
                  FCurPos := BookMarkData;
//  ShowMessage('GetRec: Mode='+IntToStr(Ord(GetMode))+' Pos='+IntToStr(FCurPos));
//                  Len := SizeOf(integer);
//                  BtrPercent := 0;
//                  Res := BtrCall(boGetPercent,FCB,BtrPercent,Len,FKeyBuf,255,FKeyNum);
//                  CheckBtrError(Res,[]);
                end;
            end
          else
            begin
              Result := grEof;
              if(GetMode=gmCurrent) then
                Result := grError
              else if((GetMode=gmPrior) And (FMyState<>msEof)) then
                Result := grBof;
            end;
        end
      else if(Res=9) then
        begin
          Result := grEof;
          if((GetMode=gmPrior) And (FMyState<>msEof)) then
            Result := grBof;
        end
      else
        Result := grError;
    end;
  if((Result=grError) And DoCheck) then
    DataBaseError(Format('No records on "%s"',[FName]));
end;

function TBtrDataSet.GetRecordSize: Word;
begin
  Result := FBufSize+SizeOf(integer);
end;

procedure TBtrDataSet.GetBookMarkData(Buffer: PChar; Data: pointer);
begin
  PInteger(Data)^ := PBtrRecInfo(Buffer+FBufSize)^.BookMarkData;
end;

function TBtrDataSet.GetBookMarkFlag(Buffer: PChar): TBookMarkFlag;
begin
  Result := PBtrRecInfo(Buffer+FBufSize)^.BookMarkFlag;
end;

procedure TBtrDataSet.InternalGotoBookMark(BookMark: Pointer);
begin
  FCurPos := PInteger(BookMark)^;
  FMyState := msDirect;
end;

procedure TBtrDataSet.InternalSetToRecord(Buffer: PChar);
begin
  FCurPos := PBtrRecInfo(Buffer+FBufSize)^.BookMarkData;
  FMyState := msDirect;
end;

procedure TBtrDataSet.SetBookMarkFlag(Buffer: PChar; Value: TBookMarkFlag);
begin
  PBtrRecInfo(Buffer+FBufSize)^.BookMarkFlag := Value;
end;

procedure TBtrDataSet.SetBookMarkData(Buffer: PChar; Data: Pointer);
begin
  PBtrRecInfo(Buffer+FBufSize)^.BookMarkData := PInteger(Data)^;
end;

procedure TBtrDataSet.InternalFirst;
begin
  FMyState := msBof;
end;

procedure TBtrDataSet.InternalLast;
begin
  FMyState := msEof;
end;
{
procedure TBtrDataSet.InternalAddRecord(Buffer: Pointer; Append: boolean);
var
  Res, Len: integer;
begin
  Len := PBtrRecInfo(Pchar(Buffer)+FBufSize)^.BtrRecordLen;
  Res := BtrCall(boInsert,FCB,PChar(Buffer)^,Len,FKeyBuf,255,FKeyNum);
  if(Res=0) then
    FMyState := msDefined;
end;
}
procedure TBtrDataSet.InternalDelete;
var
  Res, Len: integer;
  p: Pchar;
begin
  if(FMyState=msDirect) then
    begin
      p := AllocMem(FBufSize);
      try
        PInteger(p)^ := FCurPos;
        Len := FBufSize;
        Res := BtrCall(boGetDirect,FCB,p^,Len,FKeyBuf,255,FKeyNum);
        if(CheckBtrError(Res,[])) then
          FMyState := msDefined;
      finally
        FreeMem(p);
      end;
    end;
  if(FMyState=msDefined) then
    begin
      Res := BtrCall(boDelete,FCB,Len,Len,FKeyBuf,255,FKeyNum);
      if(CheckBtrError(Res,[])) then
        begin
          FMyState := msDeleted;
          UpdateKeys;
        end;
    end
  else
    DataBaseError(Format('Not defined deleted record position on "%s"',[FName]));
end;
{
procedure TBtrDataSet.InternalPost;
var
  Res, Len: integer;
begin
  if(FMyState=msDefined) then
    begin
      Len := PBtrRecInfo(Pchar(ActiveBuffer)+FBufSize)^.BtrRecordLen;
      Res := BtrCall(boUpdate,FCB,PChar(ActiveBuffer)^,Len,FKeyBuf,255,FKeyNum);
      if(Res=0) then
        begin
          Inc(FDesc^[0].biRecNum_KeyNum);
          FMyState := msDefined;
        end;
    end;
end;
}
function TBtrDataSet.GetRecordCount: Integer;
begin
  Result := -1;
  if((FLwb=nil) And (FUpb=nil)) then
    Result := FDesc^[FKeyList^[FKeyNum]].biRecNum_KeyNum;
end;

function TBtrDataSet.GetRecNo: integer;
var
  Res, Len, Pos, i: integer;
  p: pchar;
begin
  Result := 0;
  if((FLwb<>nil) Or (FUpb<>nil) Or
     (FDesc^[FKeyList^[FKeyNum]].biRecNum_KeyNum=0)) then
    Exit;
  Res := 0;
  Pos := PBtrRecInfo(Pchar(ActiveBuffer)+FBufSize)^.BookMarkData;
  if((FCurPos<>Pos) Or (FMyState<>msDefined)) then
    begin
      p := AllocMem(FBufSize);
      try
        Len := FBufSize;
        PInteger(p)^ := Pos;
        Res := BtrCall(boGetDirect,FCB,p^,Len,FKeyBuf,255,FKeyNum);
      finally
        FreeMem(p);
      end;
      if(CheckBtrError(Res,[])) then
        begin
          if((FCurPos=Pos) And (FMyState=msDirect)) then
            FMyState := msDefined
          else if((FCurPos<>Pos) And (FMyState=msDefined)) then
            FMyState := msDirect;
        end;
    end;
  if(Res=0) then
    begin
      Len := SizeOf(i);
      Res := BtrCall(boGetPercent,FCB,i,Len,FKeyBuf,255,FKeyNum);
      if(CheckBtrError(Res,[])) then
        Result := i*(FDesc^[FKeyList^[FKeyNum]].biRecNum_KeyNum-1) div 10000 +1;
    end;
end;

procedure TBtrDataSet.SetRecNo(Value: integer);
var
  Pos, Res, Len: integer;
begin
  if((FLwb<>nil) Or (FUpb<>nil)) then
    Exit;
  Pos := (Value-1)*10000 div (FDesc^[FKeyList^[FKeyNum]].biRecNum_KeyNum-1);
  Len := SizeOf(Pos);
  Res := BtrCall(boSeekPercent,FCB,Pos,Len,FKeyBuf,255,FKeyNum);
  if(CheckBtrError(Res,[22])) then
    begin
      Len := SizeOf(FCurPos);
      Res := BtrCall(boGetPos,FCB,FCurPos,Len,FKeyBuf,255,FKeyNum);
      if(CheckBtrError(Res,[])) then
        begin
          FMyState := msDefined;
          Resync([]);
        end;
    end;
end;

procedure TBtrDataSet.InternalOpen;
var
  Res, Len: integer;
  Alt: integer;
begin
  Len := 0;
  StrPCopy(PChar(@FKeyBuf),FName);
  Res := BtrCall(boOpen,FCB,Len,Len,FKeyBuf,255,BtrOpenModes[FMode]);
  if(Res<>0) then
    begin
      DataBaseError(Format('Can not open database "%s"',[FName]));
      Exit;
    end;
//  FMyState := msUndefined;
  Len := (bMaxSegs+1)*SizeOf(TBtrInfoRec)+265;
  FDesc := AllocMem(Len);
  Res := BtrCall(boStat,FCB,FDesc^,Len,FKeyBuf,255,0);
  if(Res<>0) then
    begin
      FreeMem(FDesc);
      BtrCall(boClose,FCB,Len,Len,FKeyBuf,255,0);
      DataBaseError(Format('Btrieve error N %d on "%s"',[Res,FName]));
      Exit;
    end;
  FKeyCnt := FDesc^[0].biNumKey_KeyFlag;
  if(FKeyNum>=FKeyCnt) then
    begin
      FreeMem(FDesc);
      BtrCall(boClose,FCB,Len,Len,FKeyBuf,255,0);
      DataBaseError(Format('Index %d out of range on "%s"',[FKeyNum,FName]));
      Exit;
    end;
  Len := 0;
  FKeySegs := 0;
  Alt := 0;
  while(Len<FKeyCnt) do
    begin
      Inc(Len);
      repeat
        Inc(FKeySegs);
        if((FDesc^[FKeySegs].biNumKey_KeyFlag And bkAlt)<>0) then
          Alt := 265;
      until((FDesc^[FKeySegs].biNumKey_KeyFlag And bkSeg)=0);
    end;
  ReAllocMem(FDesc,(FKeySegs+1)*SizeOf(TBtrInfoRec)+Alt);
  if(Alt<>0) then
    FAltPtr := @(FDesc^[FKeySegs+1]);
  FKeyList := AllocMem(FKeyCnt);
  Len := 0;
  Res := 0;
  while(Res<FKeyCnt) do
    begin
      Inc(Len);
      FKeyList^[Res] := Len;
      while((FDesc^[Len].biNumKey_KeyFlag And bkSeg)<>0) do
        begin
          Inc(Len);
        end;
      Inc(Res);
    end;
  FMyState := msBof;
  InternalInitFieldDefs;
  if(DefaultFields) then
    CreateFields;
end;

procedure TBtrDataSet.InternalClose;
var
  Len: integer;
begin
  if(FMyState<>msClosed) then
    BtrCall(boClose,FCB,Len,Len,FKeyBuf,255,0);
  if(FLwb<>nil) then
    begin
      FreeMem(FLwb);
      FLwb := nil;
    end;
  if(FUpb<>nil) then
    begin
      FreeMem(FUpb);
      FUpb := nil;
    end;
  FAltPtr := nil;
  FreeMem(FKeyList);
  FreeMem(FDesc);
  FMyState := msClosed;
end;

procedure TBtrDataSet.InternalHandleException;
begin
  Application.HandleException(Self);
end;

function TBtrDataSet.IsCursorOpen: Boolean;
begin
  Result := FMyState<>msClosed;
end;
{
procedure TBtrDataSet.InternalInitFieldDefs;
begin
  FieldDefs.Clear;
  TFieldDef.Create(FieldDefs,'Length',ftInteger,0,False,1);
  TFieldDef.Create(FieldDefs,'Percent',ftInteger,0,False,2);
  TFieldDef.Create(FieldDefs,'Data',ftBytes,FBufSize,False,3);
end;

function TBtrDataSet.GetFieldData(Field: TField; Buffer: Pointer): Boolean;
begin
  Result := true;
  case Field.Index of
    0: PInteger(Buffer)^ := PBtrRecInfo(ActiveBuffer+FBufSize)^.BtrRecordLen;
    1: PInteger(Buffer)^ := PBtrRecInfo(ActiveBuffer+FBufSize)^.BtrPercent;
    2: Move(ActiveBuffer^,Buffer^,Field.Size);
  end;
end;

procedure TBtrDataSet.SetFieldData(Field: TField; Buffer: pointer);
begin
  case Field.Index of
    0: PBtrRecInfo(ActiveBuffer+FBufSize)^.BtrRecordLen := PInteger(Buffer)^;
    1: PBtrRecInfo(ActiveBuffer+FBufSize)^.BtrPercent := PInteger(Buffer)^;
    2: Move(Buffer^,ActiveBuffer^,Field.Size);
  end;
  DataEvent(deFieldChange,LongInt(Field));
end;
}
function TBtrDataSet.GetBtrRecord(Buffer: pchar): word;
begin
  Result := 0;
  UpdateCursorPos;
//  SetCurrentRecord(ActiveRecord);
  GetRecord(ActiveBuffer,gmCurrent,false);
  Move(ActiveBuffer^,Buffer^,PBtrRecInfo(ActiveBuffer+FBufSize)^.BtrRecordLen);
  Result := PBtrRecInfo(ActiveBuffer+FBufSize)^.BtrRecordLen;
end;

function TBtrDataSet.AddBtrRecord(Buffer: pchar; Len: word): boolean;
var
  Res, MyLen: integer;
//  bm: TBookMark;
begin
  Result := false;
  MyLen := Len;
  Res := BtrCall(boInsert,FCB,Buffer^,MyLen,FKeyBuf,255,FKeyNum);
  CheckBtrError(Res,[5]);
  if(Res=0) then
    begin
//      if(ValidKeyValue(Buffer,FKeyNum)) then
//        Inc(FDesc^[FKeyList^[FKeyNum]].biRecNum_KeyNum);
      UpdateKeys;
      MyLen := SizeOf(FCurPos);
      Res := BtrCall(boGetPos,FCB,FCurPos,MyLen,FKeyBuf,255,FKeyNum);
      if(CheckBtrError(Res,[])) then
        begin
          FMyState := msDefined;
          Resync([]);
        end;
//      GotoBookMark(@Pos);
//      FMyState := msDefined;
      Result := true;
    end;
end;

function TBtrDataSet.UpdateBtrRecord(Buffer: pchar; Len: word): boolean;
var
  Res, MyLen: integer;
begin
  Result := false;
{  if (CurrentRecord<>ActiveRecord) then Exit;}
  MyLen := Len;
  Res := BtrCall(boUpdate,FCB,Buffer^,MyLen,FKeyBuf,255,FKeyNum);
  if(CheckBtrError(Res,[])) then
    begin
      UpdateKeys;
      MyLen := SizeOf(integer);
      Move(Buffer^,ActiveBuffer^,Len);
      PBtrRecInfo(ActiveBuffer+FBufSize)^.BtrRecordLen := Len;
      Res := BtrCall(boGetPos,FCB,PBtrRecInfo(ActiveBuffer+FBufSize)^.BookMarkData,MyLen,FKeyBuf,255,FKeyNum);
      CheckBtrError(Res,[]);
      Result := true;
    end;
end;

function TBtrDataSet.FindBtrRecordByIndex(Buffer: pchar; var Len: word;
                                          var Value; Index: byte; Opt: TBtrSearchOption): boolean;
var
  Res, MyLen: integer;
begin
  Result := false;
  if(Index>=FKeyCnt) then
    Exit;
//  Res := FKeyList^[Index];
//  MyLen := FDesc^[Res].biPageSize_KeyLen;
//  while((FDesc^[Res].biNumKey_KeyFlag And bkSeg)<>0) do
//    begin
//      Inc(Res);
//      Inc(MyLen,FDesc^[Res].biPageSize_KeyLen);
//    end;
//  Move(Value,FKeyBuf,MyLen);
  Move(Value,FKeyBuf,KeySize(Index));
  MyLen := FBufSize;
  Res := BtrCall(BtrSeachOpCodes[Opt],FCB,Buffer^,MyLen,FKeyBuf,255,Index);
  if(Opt=bsEq) then
    CheckBtrError(Res,[4])
  else
    CheckBtrError(Res,[9]);
  if(Res=0) then
    begin
      FMyState := msUnDefined;
      Len := MyLen;
      Result := true;
    end;
end;

function TBtrDataSet.LocateBtrRecordByIndex(var Value; Index: byte; Opt: TBtrSearchOption): boolean;
var
  Len: word;
  MyLen, Res: integer;
  p: pchar;
begin
  Result := false;
  p := AllocMem(FBufSize);
  try
    if(FindBtrRecordByIndex(p,Len,Value,Index,Opt)) then
      begin
        MyLen := SizeOf(FCurPos);
        Res := BtrCall(boGetPos,FCB,FCurPos,MyLen,FKeyBuf,255,Index);
        if(CheckBtrError(Res,[])) then
          begin
            FMyState := msDirect;
            if(Index=FKeyNum) then
              FMyState := msDefined;
            Resync([]);
          end;
//        GotoBookMark(@Pos);
        Result := true;
      end;
  finally
    FreeMem(p);
  end;
end;

procedure TBtrDataSet.SetTableName(const Value: string);
begin
  CheckInactive;
  FName := Value;
end;

procedure TBtrDataSet.SetIndex(Value: byte);
var
  Res, Len: integer;
  p: pchar;
begin
  if(Active) then
    begin
      if(Value>=FKeyCnt) then
        begin
          DataBaseError(Format('Index %d out of range on "%s"',[FKeyNum,FName]));
          Exit;
        end;
      UpdateCursorPos;
      if((FMyState=msDefined) Or (FMyState=msDirect)) then
        begin
          p := AllocMem(FBufSize);
          try
            Pinteger(p)^ := FCurPos;
            Len := FBufSize;
            Res := BtrCall(boGetDirect,FCB,p^,Len,FKeyBuf,255,Value);
            CheckBtrError(Res,[44]);
            if(Res=0) then
              FMyState := msDefined
            else
              FMyState := msBof;
          finally
            FreeMem(p);
          end;
        end
      else if(FMyState<>msClosed) then
        FMyState := msBof;
    end;
  if(FLwb<>nil) then
    begin
      FreeMem(FLwb);
      FLwb := nil;
    end;
  if(FUpb<>nil) then
    begin
      FreeMem(FUpb);
      FUpb := nil;
    end;
  FKeyNum := Value;
  if(Active) then
    begin
//      Refresh();
      Resync([]);
    end;
end;

procedure TBtrDataSet.SetBufSize(Value: integer);
begin
  FBufSize := Value;
end;

procedure TBtrDataSet.SetMode(Value: TBtrOpenMode);
begin
  FMode := Value;
end;

procedure TBtrDataSet.SetRange(LValue, UValue: pointer);
var
  p: pchar;
  Res, Len: integer;
begin
  if(Not Active) then
    begin
      DataBaseError(Format('SetRange on closed table "%s"',[FName]));
      Exit;
    end;
  UpdateCursorPos;
  if(FLwb<>nil) then
    begin
      FreeMem(FLwb);
      FLwb := nil;
    end;
  if(FUpb<>nil) then
    begin
      FreeMem(FUpb);
      FUpb := nil;
    end;
  if(LValue<>nil) then
    begin
      FLwb := AllocMem(KeySize(FKeyNum));
      Move(LValue^,FLwb^,KeySize(FKeyNum));
    end;
  if(UValue<>nil) then
    begin
      FUpb := AllocMem(KeySize(FKeyNum));
      Move(UValue^,FUpb^,KeySize(FKeyNum));
    end;
  if((FMyState=msDefined) Or (FMyState=msDirect)) then
    begin
      p := AllocMem(FBufSize);
      try
        Pinteger(p)^ := FCurPos;
        Len := FBufSize;
        Res := BtrCall(boGetDirect,FCB,p^,Len,FKeyBuf,255,FKeyNum);
        CheckBtrError(Res,[]);
        FMyState := msDefined;
        if((FLwb<>nil) And (CompareKeys(@FKeyBuf,FLwb,FKeyNum)<0)) then
          FMyState := msBof
        else if((FUpb<>nil) And (CompareKeys(@FKeyBuf,FUpb,FKeyNum)>0)) then
          FMyState := msEof;
      finally
        FreeMem(p);
      end;
    end
  else if(FMyState<>msClosed) then
    FMyState := msBof;
//  Refresh();
  Resync([]);
end;

function TBtrDataSet.CheckBtrError(Res: integer; ValidRes: array of integer): boolean;
var
  i: integer;
begin
  Result := true;
  if(Res=0) then
    Exit;
  for i := Low(ValidRes) to High(ValidRes) do
    if(Res=ValidRes[i]) then
      Exit;
  DataBaseError(Format('Btrieve error N %d on "%s"',[Res,FName]));
  Result := false;
end;

function TBtrDataSet.KeySize(Index: byte): integer;
var
  i: byte;
begin
  Result := 0;
  if(Index>=FKeyCnt) then
    Exit;
  i := FKeyList^[Index];
  Result := FDesc^[i].biPageSize_KeyLen;
  while((FDesc^[i].biNumKey_KeyFlag And bkSeg)<>0) do
    begin
      Inc(i);
      Inc(Result,FDesc^[i].biPageSize_KeyLen);
    end;
end;
{
function TBtrDataSet.ValidKeyValue(Buffer: pchar; Index: byte): boolean;
var
  i, j: integer;
  p: pchar;
begin
  Result := false;
  if(Index>=FKeyCnt) then
    Exit;
  Result := true;
  i := FKeyList^[Index];
  while(true) do
    begin
      if((FDesc^[i].biNumKey_KeyFlag And bkNul)=0) then
        Exit;
      p := Buffer+FDesc^[i].biRecLen_KeyPos-1;
      for j := 1 to FDesc^[i].biPageSize_KeyLen do
        begin
          if(Ord(p^)<>FDesc^[i].bi_KeyNilVal) then
            Exit;
          Inc(p);
        end;
      if((FDesc^[i].biNumKey_KeyFlag And bkSeg)=0) then
        break;
      Inc(i);
    end;
  Result := false;
end;
}
//btString
function Compare00(p1, p2: pchar; Len: Cardinal): integer;
asm
        PUSH    EDI
        PUSH    ESI
        MOV     EDI,EDX
        MOV     ESI,EAX
        REPE    CMPSB
        MOVZX   EAX,BYTE PTR [ESI-1]
        MOVZX   EDX,BYTE PTR [EDI-1]
        SUB     EAX,EDX
        POP     ESI
        POP     EDI
end;

//btInteger
function Compare01(p1, p2: pchar; Len: Cardinal): integer;
asm
        PUSH    EDI
        PUSH    ESI
        STD
        LEA     EDI,[EDX+ECX-4]
        LEA     ESI,[EAX+ECX-4]
        MOVSX   EAX,WORD PTR [ESI+2]
        MOVSX   EDX,WORD PTR [EDI+2]
        CMP     EAX,EDX
        JNE     @@1
        SHR     ECX,1
        DEC     ECX
        JNE     @@2
@@1:    SUB     EAX,EDX
        JMP     @@3
@@2:    REPE    CMPSW
        MOVZX   EAX,WORD PTR [ESI+2]
        MOVZX   ECX,WORD PTR [EDI+2]
        SUB     EAX,ECX
        OR      EDX,EDX
        JNS     @@3
        NEG     EAX
@@3:    CLD
        POP     ESI
        POP     EDI
end;

//btLString
function Compare10(p1, p2: pchar; Len: Cardinal): integer;
asm
        PUSH    EDI
        PUSH    ESI
        MOV     EDI,EDX
        MOV     ESI,EAX
        MOVZX   EDX,BYTE PTR [EDX]
        MOVZX   EAX,BYTE PTR [EAX]
        MOV     ECX,EDX
        CMP     EAX,EDX
        JAE     @@1
        MOV     ECX,EAX
@@1:    OR      ECX,ECX
        JE      @@2
        INC     EDI
        INC     ESI
        REPE    CMPSB
        JE      @@2
        MOVZX   EAX,BYTE PTR [ESI-1]
        MOVZX   EDX,BYTE PTR [EDI-1]
@@2:    SUB     EAX,EDX
        POP     ESI
        POP     EDI
end;

//btZString
function Compare11(p1, p2: pchar; Len: Cardinal): integer;
asm
        PUSH    EDI
        PUSH    ESI
        PUSH    EBX
        MOV     EDI,EDX
        MOV     ESI,EAX
        MOV     EBX,ECX
        XOR     AL,AL
        REPNE   SCASB
        SUB     EBX,ECX
        MOV     ECX,EBX
        MOV     EDI,EDX
        REPE    CMPSB
        MOVZX   EAX,WORD PTR [ESI-1]
        MOVZX   EDX,WORD PTR [EDI-1]
        SUB     EAX,EDX
        POP     EBX
        POP     ESI
        POP     EDI
end;

//btUnsigned
function Compare14(p1, p2: pchar; Len: Cardinal): integer;
asm
        PUSH    EDI
        PUSH    ESI
        LEA     EDI,[EDX+ECX-2]
        LEA     ESI,[EAX+ECX-2]
        SHR     ECX,1
        STD
        REPE    CMPSW
        MOVZX   EAX,WORD PTR [ESI+2]
        MOVZX   EDX,WORD PTR [EDI+2]
        SUB     EAX,EDX
        CLD
        POP     ESI
        POP     EDI
end;

function TBtrDataSet.CompareKeys(Key1, Key2: pointer; Index: byte): integer;
var
  i, t: integer;
  p1: pchar absolute Key1;
  p2: pchar absolute Key2;
begin
  Result := 0;
  if(Index>=FKeyCnt) then
    Exit;
  i := FKeyList^[Index];
  while(true) do
    begin
      if((FDesc^[i].biNumKey_KeyFlag And bkExtTypeKey)<>0) then
        t := FDesc^[i].biBaseFlag_KeyType
      else if((FDesc^[i].biNumKey_KeyFlag And bkBin)<>0) then
        t := btInteger
      else
        t := btString;
      case t of
        btString:
          Result := Compare00(p1,p2,FDesc^[i].biPageSize_KeyLen);
        btLString:
          Result := Compare10(p1,p2,FDesc^[i].biPageSize_KeyLen);
        btZString:
          Result := Compare11(p1,p2,FDesc^[i].biPageSize_KeyLen);
        btInteger:
          Result := Compare01(p1,p2,FDesc^[i].biPageSize_KeyLen);
        btUnsigned:
          Result := Compare14(p1,p2,FDesc^[i].biPageSize_KeyLen);
      end;
      if(Result<>0) then
        break;
      if((FDesc^[i].biNumKey_KeyFlag And bkSeg)=0) then
        break;
      Inc(p1,FDesc^[i].biPageSize_KeyLen);
      Inc(p2,FDesc^[i].biPageSize_KeyLen);
      Inc(i);
    end;
end;
{
procedure TBtrDataSet.GetKeyValue(Buffer: pchar; Key: pointer; Index: byte);
var
  i: integer;
  p: pchar absolute Key;
begin
  if(Index>=FKeyCnt) then
    Exit;
  i := FKeyList^[Index];
  while(true) do
    begin
      Move(Buffer[FDesc^[i].biRecLen_KeyPos],p^,FDesc^[i].biPageSize_KeyLen);
      Inc(p,FDesc^[i].biPageSize_KeyLen);
      if((FDesc^[i].biNumKey_KeyFlag And bkSeg)=0) then
        break;
      Inc(i);
    end;
end;
}
function TBtrDataSet.BookmarkValid(Bookmark: TBookmark): Boolean;
var
  Res, Len: integer;
  p: pchar;
  Key: array [0..255] of char;
begin
  Result := false;
  if(FMyState<>msClosed) then
    begin
      p := AllocMem(FBufSize);
      try
        PInteger(p)^ := PInteger(BookMark)^;
        Len := FBufSize;
        Res := BtrCall(boGetDirect,FCB,p^,Len,Key,255,FKeyNum);
      finally
        FreeMem(p);
      end;
//        CheckBtrError(Res,[44]);
      if(Res=0) then
        begin
          if(((FLwb=nil) Or (CompareKeys(@Key,FLwb,FKeyNum)>=0)) And
             ((FUpb=nil) Or (CompareKeys(@Key,FUpb,FKeyNum)<=0))) then
            Result := true;
        end;
      if(FMyState=msDefined) then
        FMyState := msDirect;
    end;
end;
{
function TBtrDataSet.CompareBookmarks(Bookmark1, Bookmark2: TBookmark): Integer;
begin
  Result := 0;
  if((Bookmark1<>nil) And (Bookmark2=nil)) then Result := 1
  else if((Bookmark1=nil) And (Bookmark2<>nil)) then Result := -1
  else if((Bookmark1<>nil) And (Bookmark2<>nil)) then
    begin
      if(PLongWord(Bookmark1)^>PLongWord(Bookmark2)^) then Result := 1
      else if(PLongWord(Bookmark1)^<PLongWord(Bookmark2)^) then Result := -1;
    end;
end;
}
function TBtrDataSet.CompareBookmarks(Bookmark1, Bookmark2: TBookmark): Integer;
var
  Res1, Res2, Len: integer;
  p: PChar;
  Key1, Key2: array [0..255] of char;
begin
  Result := 0;
  if((Bookmark1<>nil) And (Bookmark2=nil)) then Result := 1
  else if((Bookmark1=nil) And (Bookmark2<>nil)) then Result := -1
  else if((Bookmark1<>nil) And (Bookmark2<>nil)) then
    begin
      if(PInteger(Bookmark1)^=PInteger(Bookmark2)^) then
        Exit;
      p := AllocMem(FBufSize);
      try
        PInteger(p)^ := PInteger(BookMark1)^;
        Len := FBufSize;
        Res1 := BtrCall(boGetDirect,FCB,p^,Len,Key1,255,FKeyNum);
        PInteger(p)^ := PInteger(BookMark2)^;
        Len := FBufSize;
        Res2 := BtrCall(boGetDirect,FCB,p^,Len,Key2,255,FKeyNum);
      finally
        FreeMem(p);
      end;
      if(FMyState=msDefined) then
        FMyState := msDirect;
      if((Res1<>0) And (Res2=0)) then Result := 1
      else if((Res1=0) And (Res2<>0)) then Result := -1
      else if((Res1=0) And (Res2=0)) then
        Result := CompareKeys(@Key1,@Key2,FKeyNum);
    end;
end;

procedure TBtrDataSet.UpdateKeys;
var
  Res, Len: integer;
  Tmp: array [0..255] of byte;
begin
  Len := (FKeySegs+1)*SizeOf(TBtrInfoRec);
  if(FAltPtr<>nil) then
    Inc(Len,265);
  Res := BtrCall(boStat,FCB,FDesc^,Len,Tmp,255,0);
  CheckBtrError(Res,[]);
end;

procedure TBtrDataSet.Resync(Mode: TResyncMode);
begin
  Inherited Resync(Mode);
  if(IsEmpty) then
    begin
      ClearBuffers;
      InitRecord(ActiveBuffer);
      DataEvent(deDataSetChange, 0);
    end;
end;

function TBtrDataSet.GetLastRec(AKeyNum: Integer; Buffer: PChar): Boolean;
var
  Len: integer;
{  CurPos: TBookMark;}
begin
{  CurPos := GetBookMark;
  Len := FBufSize;}
  Result := BtrCall(boGetLast,FCB,Buffer^,Len,FKeyBuf,255,AKeyNum)=0;
{  GotoBookMark(CurPos);
  FreeBookMark(CurPos);}
end;

function TBtrDataSet.GetActiveRecLen: Integer;
begin
  Result := PBtrRecInfo(ActiveBuffer+FBufSize)^.BtrRecordLen;
end;

constructor TExtBtrDataSet.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FBtrBase := TBtrBase.Create;
end;

destructor TExtBtrDataSet.Destroy;
begin
  FBtrBase.Free;
  inherited Destroy;
end;

procedure TExtBtrDataSet.DoAfterOpen;
begin
  inherited DoAfterOpen;
  FBtrBase.SetFCB(@FCB);
end;

procedure Register;
begin
  RegisterComponents('Btr',[TBtrDataSet]);
end;


end.
