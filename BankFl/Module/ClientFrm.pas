unit ClientFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons, Mask, ExtCtrls, Basbn, Registr, Common, CommCons;

type
  TClientForm = class(TForm)
    InnLabel: TLabel;
    NameMemo: TMemo;
    NameLabel: TLabel;
    OkBtn: TBitBtn;
    CancelBtn: TBitBtn;
    InnEdit: TEdit;
    BankGroupBox: TGroupBox;
    BikPanel: TPanel;
    BikEdit: TEdit;
    RsLabel: TLabel;
    RsEdit: TEdit;
    KppEdit: TEdit;
    KppLabel: TLabel;
    procedure BankBtnClick(Sender: TObject);
    procedure BikPanelMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure BikPanelMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure InnEditKeyPress(Sender: TObject; var Key: Char);
    procedure NameMemoKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

implementation

{$R *.DFM}

type
  EditRecord = function(Sender: TComponent; RecPtr: Pointer;
    SearchIndex: Integer; ShowDlg: Boolean): Boolean;

procedure TClientForm.BankBtnClick(Sender: TObject);
var
  ModuleName: array[0..512] of Char;
  Module: HModule;
  P: Pointer;
  BankFullRec: TBankFullNewRec;
  Err: Integer;
begin
  StrPLCopy(ModuleName, DecodeMask('$(Banks)', 5, GetUserNumber),SizeOf(ModuleName));
  Module:=GetModuleHandle(ModuleName);
  if Module=0 then
    MessageDlg('Не найден модуль диалога выбора банка',
      mtError,[mbOk],0)
  else begin
    P:=GetProcAddress(Module, EditRecordDLLProcName);
    if P=nil then
      MessageDlg('Не найдена функция модуля '+EditRecordDLLProcName+'()',
        mtError,[mbOk],0)
    else begin
      with BankFullRec do begin
        Val(BikEdit.Text,brCod,Err);
        StrPCopy(brKs,'');
        StrPCopy(brName,'');
      end;
      if EditRecord(P)(Self,@BankFullRec,0,True) then begin
        with BankFullRec do begin
          BIKEdit.Text:=IntToStr(brCod);
        end;
      end;
    end;
  end;
end;

procedure TClientForm.BikPanelMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbLeft then BikPanel.BevelOuter := bvLowered;
end;

procedure TClientForm.BikPanelMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  with BikPanel do
    if BevelOuter = bvLowered then BevelOuter := bvRaised;
end;

procedure TClientForm.InnEditKeyPress(Sender: TObject; var Key: Char);
begin
  if not ((Key in ['0'..'9']) or (Key < #32)) then
  begin
    Key := #0;
    MessageBeep(0)
  end;
end;

procedure TClientForm.NameMemoKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_ESCAPE then
    ModalResult := mrCancel;
end;

end.
