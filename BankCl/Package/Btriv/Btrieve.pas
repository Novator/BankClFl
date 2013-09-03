Unit Btrieve;

interface

const
  boOpen            =    0;
  boClose           =    1;
  boInsert          =    2;
  boUpdate          =    3;
  boDelete          =    4;
  boGetEqual        =    5;
  boGetNext         =    6;
  boGetPrev         =    7;
  boGetGT           =    8;
  boGetGE           =    9;
  boGetLT           =   10;
  boGetLE           =   11;
  boGetFirst        =   12;
  boGetLast         =   13;
  boCreate          =   14;
  boStat            =   15;
  boExtend          =   16;
  boSetDir          =   17;
  boGetDir          =   18;
  boBeginTran       =   19;
  boEndTran         =   20;
  boAbortTran       =   21;
  boGetPos          =   22;
  boGetDirect       =   23;
  boStepNext        =   24;
  boStop            =   25;
  boVersion         =   26;
  boUnlock          =   27;
  boReset           =   28;
  boSetOwner        =   29;
  boClearOwner      =   30;
  boBuildIndex      =   31;
  boDropIndex       =   32;
  boStepFirst       =   33;
  boStepLast        =   34;
  boStepPrev        =   35;
  boGetNextExt      =   36;
  boGetPrevExt      =   37;
  boStepNextEXT     =   38;
  boStepPrevEXT     =   39;
  boExtInsert       =   40;
  boMiscData        =   41;
  boContinues       =   42;
  boSeekPercent     =   44;
  boGetPercent      =   45;
  boChunkUpdate     =   53;
  boGetEqualKey     =   55;
  boGetNextKey      =   56;
  boGetPrevKey      =   57;
  boGetGTKey        =   58;
  boGetGEKey        =   59;
  boGetLTKey        =   60;
  boGetLEKey        =   61;
  boGetFirstKey     =   62;
  boGetLastKey      =   63;

  baNormal          =    0;
  baAccelerated     =  $FF;
  baReadOnly        =  $FE;
  baExclusive       =  $FC;

  bkDup             = $0001; { Duplicates allowed mask }
  bkMod             = $0002; { Modifiable key mask }
  bkBin             = $0004; { Binary or extended key type mask }
  bkNul             = $0008; { Null key mask }
  bkSeg             = $0010; { Segmented key mask }
  bkAlt             = $0020; { Alternate collating sequence mask }
  bkDescKey         = $0040; { Key stored descending mask }
  bkRepeatDupsKey   = $0080; { Dupes handled w/ unique suffix }
  bkExttypeKey      = $0100; { Extended key types are specified }
  bkManualKey       = $0200; { Manual key which can be optionally null }
                             { (then key is not inc. in B-tree) }
  bkNocaseKey       = $0400; { Case insensitive key }
  bkKeyonlyFile     = $4000; { key only type file }
  bkPendingKey      = $8000; { Set during a create or drop index }

  bMaxSegs          = 119;   { Max value of index segments in BTR file }

  btString =            0;
  btInteger =           1;
  btIEEE =              2;
  btDate =              3;
  btTime =              4;
  btDecimal =           5;
  btMoney =             6;
  btLogical =           7;
  btNumeric =           8;
  btBFloat =            9;
  btLstring =          10;
  btZstring =          11;
  btUnsigned =         14;
  btAutoInc =          15;

type
  PBtrInfoRec = ^TBtrInfoRec;
  TBtrInfoRec = packed record
    biRecLen_KeyPos:    word;
    biPageSize_KeyLen:  word;
    biNumKey_KeyFlag:   word;
    biRecNum_KeyNum:    longword;
//    biRecNum_KeyNumL:   word;
//    biRecNum_KeyNumH:   word;
    biBaseFlag_KeyType: word;
    bi_KeyNilVal:       word;
    biFreePage_:        word;
  end;

function BtrCall(operation: word; var posblk; var databuf;
                 var datalen: longint; var keybuf; keylen: byte;
                 keynum: word): integer; stdcall;

type
  PBtrIndexArray = ^TBtrIndexArray;
  TBtrIndexArray = array [0..255] of byte;

  PBtrInfoArray = ^TBtrInfoArray;
  TBtrInfoArray = packed array [0..255] of TBtrInfoRec;

  PBtrBufArray = ^TBtrBufArray;
  TBtrBufArray = array [0..65535] of byte;

type
//  PBtrIndexArray = ^TBtrIndexArray;
//  TBtrIndexArray = array [0..255] of byte;

//  PBtrInfoArray = ^TBtrInfoArray;
//  TBtrInfoArray = packed array [0..255] of TBtrInfoRec;

//  PBtrBufArray = ^TBtrBufArray;
//  TBtrBufArray = array [0..65535] of byte;

  TBtrBase = class(TObject)
  private
    bbFCB:      PChar;
    bbOwnFCB:   Boolean;
  protected
    //procedure SetOwnFCB(Value: Boolean);
    function GetActive: Boolean;
  public
    //property OwnFCB: Boolean read bbOwnFCB write SetOwnFCB;
    property Active: Boolean read GetActive;
    constructor Create;
    destructor  Destroy; override;
    procedure   SetFCB(FCB: pchar);
    function    Open(Fname: string; Mode: byte): integer;
    function    Close: integer;
    function    Insert(var Rec; Len: integer;
                       var Key; Index: byte): integer;
    function    Update(var Rec; Len: integer;
                       var Key; Index: byte): integer;
    function    Delete(Index: byte): integer;
    function    GetEqual(var Rec; var Len: integer;
                         var Key; Index: byte): integer;
    function    GetNext(var Rec; var Len: integer;
                        var Key; Index: byte): integer;
    function    GetPrev(var Rec; var Len: integer;
                        var Key; Index: byte): integer;
    function    GetGT(var Rec; var Len: integer;
                      var Key; Index: byte): integer;
    function    GetGE(var Rec; var Len: integer;
                      var Key; Index: byte): integer;
    function    GetLT(var Rec; var Len: integer;
                      var Key; Index: byte): integer;
    function    GetLE(var Rec; var Len: integer;
                      var Key; Index: byte): integer;
    function    GetFirst(var Rec; var Len: integer;
                         var Key; Index: byte): integer;
    function    GetLast(var Rec; var Len: integer;
                        var Key; Index: byte): integer;
    function    GetEqualKey(var Key; Index: byte): integer;
    function    GetNextKey(var Key; Index: byte): integer;
    function    GetPrevKey(var Key; Index: byte): integer;
    function    GetGTKey(var Key; Index: byte): integer;
    function    GetGEKey(var Key; Index: byte): integer;
    function    GetLTKey(var Key; Index: byte): integer;
    function    GetLEKey(var Key; Index: byte): integer;
    function    GetFirstKey(var Key; Index: byte): integer;
    function    GetLastKey(var Key; Index: byte): integer;
    function    StepNext(var Rec; var Len: integer): integer;
    function    StepPrev(var Rec; var Len: integer): integer;
    function    StepFirst(var Rec; var Len: integer): integer;
    function    StepLast(var Rec; var Len: integer): integer;
    function    GetAddr(var Addr:longint): integer;
    function    GetDirect(Addr: longint; var Rec; var Len: integer;
                          var Key; Index: byte): integer;
    function    CheckBtrError(Res: integer;
                              ValidRes: array of integer): boolean;
  end;

function BtrBeginTransaction: integer;
function BtrAbortTransaction: integer;
function BtrEndTransaction:   integer;

implementation

uses
  Windows, SysUtils;

type
  PLongint = ^Longint;

function BtrCall(operation: word; var posblk; var databuf;
                 var datalen: longint; var keybuf; keylen: byte;
                 keynum: word): integer; stdcall;
                 external 'WBTRV32.DLL' name 'BTRCALL';

constructor TBtrBase.Create;
begin
  inherited;
  bbOwnFCB := False;
  bbFCB := nil;
end;

destructor TBtrBase.Destroy;
begin
  if Active then
    Close;
  inherited Destroy;
end;

function TBtrBase.GetActive: Boolean;
begin
  Result := bbOwnFCB and (bbFCB<>nil);
end;

procedure TBtrBase.SetFCB(FCB: pchar);
begin
  if Active then
    Close;
  bbOwnFCB := false;
  bbFCB := FCB;
end;

function TBtrBase.Open(Fname: string; Mode: byte): integer;
var
  Len: integer;
  c: char;
begin
  if Active then
    Close;
  if (Not bbOwnFCB) then
  begin
    bbFCB := AllocMem(128);
    bbOwnFCB := True;
  end;
  c := Chr(0);
  Len := 0;
  Result := BtrCall(boOpen,bbFCB^,c,Len,pchar(FName)^,
    Length(FName),Mode);
end;

function TBtrBase.Close: integer;
begin
  Result := BtrCall(boClose,bbFCB^,nil^,PLongint(nil)^,nil^,0,0);
  if bbOwnFCB and (bbFCB<>nil) then
  begin
    FreeMem(bbFCB);
    bbFCB := nil;
    bbOwnFCB := False;
  end;
end;

function TBtrBase.Insert(var Rec; Len: integer;
  var Key; Index: byte): integer;
begin
  Result := BtrCall(boInsert,bbFCB^,Rec,Len,Key,255,Index);
end;

function TBtrBase.Update(var Rec; Len: integer;
                         var Key; Index: byte): integer;
  begin
    Result := BtrCall(boUpdate,bbFCB^,Rec,Len,Key,255,Index);
  end;

function TBtrBase.Delete(Index: byte): integer;
  var
    Len: integer;
  begin
    Result := BtrCall(boDelete,bbFCB^,nil^,Len,nil^,0,Index);
  end;

function TBtrBase.GetEqual(var Rec; var Len: integer;
                           var Key; Index: byte): integer;
  begin
    Result := BtrCall(boGetEqual,bbFCB^,Rec,Len,Key,255,Index);
  end;

function TBtrBase.GetNext(var Rec; var Len: integer;
                          var Key; Index: byte): integer;
  begin
    Result := BtrCall(boGetNext,bbFCB^,Rec,Len,Key,255,Index);
  end;

function TBtrBase.GetPrev(var Rec; var Len: integer;
                          var Key; Index: byte): integer;
  begin
    Result := BtrCall(boGetPrev,bbFCB^,Rec,Len,Key,255,Index);
  end;

function TBtrBase.GetGT(var Rec; var Len: integer;
                        var Key; Index: byte): integer;
  begin
    Result := BtrCall(boGetGT,bbFCB^,Rec,Len,Key,255,Index);
  end;

function TBtrBase.GetGE(var Rec; var Len: integer;
                        var Key; Index: byte): integer;
  begin
    Result := BtrCall(boGetGE,bbFCB^,Rec,Len,Key,255,Index);
  end;

function TBtrBase.GetLT(var Rec; var Len: integer;
                        var Key; Index: byte): integer;
  begin
    Result := BtrCall(boGetLT,bbFCB^,Rec,Len,Key,255,Index);
  end;

function TBtrBase.GetLE(var Rec; var Len: integer;
                        var Key; Index: byte): integer;
  begin
    Result := BtrCall(boGetLE,bbFCB^,Rec,Len,Key,255,Index);
  end;

function TBtrBase.GetFirst(var Rec; var Len: integer;
                           var Key; Index: byte): integer;
  begin
    Result := BtrCall(boGetFirst,bbFCB^,Rec,Len,Key,255,Index);
  end;

function TBtrBase.GetLast(var Rec; var Len: integer;
                          var Key; Index: byte): integer;
  begin
    Result := BtrCall(boGetLast,bbFCB^,Rec,Len,Key,255,Index);
  end;

function TBtrBase.GetEqualKey(var Key; Index: byte): integer;
  begin
    Result := BtrCall(boGetEqualKey,bbFCB^,nil^,PLongint(nil)^,Key,255,Index);
  end;

function TBtrBase.GetNextKey(var Key; Index: byte): integer;
  begin
    Result := BtrCall(boGetNextKey,bbFCB^,nil^,PLongint(nil)^,Key,255,Index);
  end;

function TBtrBase.GetPrevKey(var Key; Index: byte): integer;
  begin
    Result := BtrCall(boGetPrevKey,bbFCB^,nil^,PLongint(nil)^,Key,255,Index);
  end;

function TBtrBase.GetGTKey(var Key; Index: byte): integer;
  begin
    Result := BtrCall(boGetGTKey,bbFCB^,nil^,PLongint(nil)^,Key,255,Index);
  end;

function TBtrBase.GetGEKey(var Key; Index: byte): integer;
  begin
    Result := BtrCall(boGetGEKey,bbFCB^,nil^,PLongint(nil)^,Key,255,Index);
  end;

function TBtrBase.GetLTKey(var Key; Index: byte): integer;
  begin
    Result := BtrCall(boGetLTKey,bbFCB^,nil^,PLongint(nil)^,Key,255,Index);
  end;

function TBtrBase.GetLEKey(var Key; Index: byte): integer;
  begin
    Result := BtrCall(boGetLEKey,bbFCB^,nil^,PLongint(nil)^,Key,255,Index);
  end;

function TBtrBase.GetFirstKey(var Key; Index: byte): integer;
  begin
    Result := BtrCall(boGetFirstKey,bbFCB^,nil^,PLongint(nil)^,Key,255,Index);
  end;

function TBtrBase.GetLastKey(var Key; Index: byte): integer;
  begin
    Result := BtrCall(boGetLastKey,bbFCB^,nil^,PLongint(nil)^,Key,255,Index);
  end;

function TBtrBase.StepNext(var Rec; var Len: integer): integer;
  begin
    Result := BtrCall(boStepNext,bbFCB^,Rec,Len,nil^,0,0);
  end;

function TBtrBase.StepPrev(var Rec; var Len: integer): integer;
  begin
    Result := BtrCall(boStepPrev,bbFCB^,Rec,Len,nil^,0,0);
  end;

function TBtrBase.StepFirst(var Rec; var Len: integer): integer;
  begin
    Result := BtrCall(boStepFirst,bbFCB^,Rec,Len,nil^,0,0);
  end;

function TBtrBase.StepLast(var Rec; var Len: integer): integer;
  begin
    Result := BtrCall(boStepLast,bbFCB^,Rec,Len,nil^,0,0);
  end;

function TBtrBase.GetAddr(var Addr: longint): integer;
  var
    Len: integer;
  begin
    Result := BtrCall(boGetPos,bbFCB^,Addr,Len,nil^,0,0);
  end;

function TBtrBase.GetDirect(Addr: longint; var Rec; var Len: integer;
                            var Key; Index: byte): integer;
  begin
    PLongint(@Rec)^ := Addr;
    Result := BtrCall(boGetDirect,bbFCB^,Rec,Len,Key,255,Index);
  end;

function TBtrBase.CheckBtrError(Res: integer;
                                ValidRes: array of integer): boolean;
var
  i: integer;
begin
  Result := true;
  if(Res=0) then
    Exit;
  for i := Low(ValidRes) to High(ValidRes) do
    if(Res=ValidRes[i]) then
      Exit;
  Result := false;
end;

function BtrBeginTransaction: integer;
  begin
    Result := BtrCall(boBeginTran,nil^,nil^,PLongint(nil)^,nil^,0,0);
  end;

function BtrAbortTransaction: integer;
  begin
    Result := BtrCall(boAbortTran,nil^,nil^,PLongint(nil)^,nil^,0,0);
  end;

function BtrEndTransaction:   integer;
  begin
    Result := BtrCall(boEndTran,nil^,nil^,PLongint(nil)^,nil^,0,0);
  end;

end.
