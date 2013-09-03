unit FirmFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons, Mask, Deals, ExtCtrls;

type
  TFirmForm = class(TForm)
    InnEdit: TMaskEdit;
    RecepientBIKEdit: TMaskEdit;
    InnLabel: TLabel;
    RsLabel: TLabel;
    NameMemo: TMemo;
    NameLabel: TLabel;
    RsEdit: TMaskEdit;
    KppEdit: TMaskEdit;
    OkBtn: TBitBtn;
    CancelBtn: TBitBtn;
    KppLabel: TLabel;
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

end.
