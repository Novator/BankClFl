unit CopySdkToRootFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons;

type
  TForm1 = class(TForm)
    BitBtn1: TBitBtn;
    procedure BitBtn1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.DFM}

function CopySdkToRoot: Boolean;
begin
  ?
end;

procedure TForm1.BitBtn1Click(Sender: TObject);
begin
  CopySdkToRoot;
end;

end.
