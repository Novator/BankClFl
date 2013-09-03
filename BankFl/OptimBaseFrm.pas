unit OptimBaseFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, CheckLst, ComCtrls;

type
  TOptimBaseForm = class(TForm)
    StatusBar1: TStatusBar;
    GroupBox1: TGroupBox;
    Ok_Button: TButton;
    Cancel_Button: TButton;
    AnalizButton: TButton;
    DelButton: TButton;
    OptimiseButton: TButton;
    AbPackCheckListBox: TCheckListBox;
    AbLockCheckBox: TCheckBox;
    AbBlockCheckBox: TCheckBox;
    AbWorkCheckBox: TCheckBox;
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  OptimBaseForm: TOptimBaseForm;

implementation

{$R *.DFM}

procedure TOptimBaseForm.FormCreate(Sender: TObject);
  begin
  if ServerSocket.Active then
    OptimiseButton.Enabled := False;
  end;



end.
