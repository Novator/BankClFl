unit VeiwSignListFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons, ExtCtrls, TccItcs, ComCtrls;

type
  TVeiwSignListForm = class(TForm)
    SignGroupBox: TGroupBox;
    SignListBox: TListBox;
    BtnPanel: TPanel;
    ViewBitBtn: TBitBtn;
    DelBitBtn: TBitBtn;
    OkBitBtn: TBitBtn;
    StatusBar: TStatusBar;
    procedure ViewBitBtnClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure SignListBoxKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure DelBitBtnClick(Sender: TObject);
  private
    { Private declarations }
  public
    FData, FSign: PChar;
    FDataLen: Integer;
    FFullCont: PEXT_FULL_CONTEXT;
  end;

implementation

uses
  CrySign;

{$R *.DFM}

procedure TVeiwSignListForm.ViewBitBtnClick(Sender: TObject);
const
  MesTitle: PChar = 'Просмотр подписи';
var
  I, C, L, K, Err: Integer;
  SignCntxt: EXT_SIGN_CONTEXT;
begin
  if (SignListBox.ItemIndex>=0) and (SignListBox.Items.Count>0)
    and IsItscLibLoaded then
  begin
    I := Integer(SignListBox.Items.Objects[SignListBox.ItemIndex]);
    C := PInteger(FSign)^;
    L := C*4;
    K := 1;
    while (K<I) and (K<C) do
    begin
      Inc(L, PInteger(@FSign[K*4])^);
      Inc(K);
    end;
    FillChar(SignCntxt, SizeOf(SignCntxt), #0);
    with SignCntxt do
    begin
      Flags := Ext_RETURN_CONTROL_INFO;
      pData := FData;
      DataLen := FDataLen;
      pSignaturesData := @FSign[4+L];
      SignaturesDataLen := PInteger(@FSign[4*I])^;
      pControlInfo := nil;
      pSignaturesResults := nil;
    end;
    Err := TExtVerifyViewSignResult(GetExtPtr(fiVerifyViewSignResult))(FFullCont,
      @SignCntxt, MesTitle, nil);
    if (Err<>e_NO_ERROR) {or (Err=e_UNKNOWN_CRYPT_METHOD)} then
      Application.MessageBox(PChar(ErrToStr(Err)), MesTitle, MB_OK or MB_ICONERROR);

    with SignCntxt do
    begin
      if pControlInfo<>nil then
        TExtFreeMemory(GetExtPtr(fiFreeMemory))(pControlInfo, ControlInfoSize);
      if pSignaturesResults<>nil then
        TExtFreeMemory(GetExtPtr(fiFreeMemory))(pSignaturesResults, ResultsSize);
    end;
  end;
end;

procedure TVeiwSignListForm.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key=VK_ESCAPE then
    ModalResult := mrCancel
end;

procedure TVeiwSignListForm.SignListBoxKeyDown(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  case Key of
    VK_DELETE:
      DelBitBtnClick(nil);
    VK_SPACE:
      ViewBitBtnClick(nil);
  end;
end;

procedure TVeiwSignListForm.DelBitBtnClick(Sender: TObject);
const
  MesTitle: PChar = 'Удаление подписи';
begin
  if DelBitBtn.Visible and (SignListBox.ItemIndex>=0) and (SignListBox.Items.Count>0)
    and (MessageBox(Handle, PChar('Подпись будет удалена. Вы уверены?'#13#10'['
    +SignListBox.Items.Strings[SignListBox.ItemIndex]+']'), MesTitle,
    MB_YESNOCANCEL or MB_ICONQUESTION)=ID_YES) then
  begin
    SignListBox.Items.Delete(SignListBox.ItemIndex);
  end;
end;

end.
