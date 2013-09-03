program SrvTest;

uses
  Forms,
  SrvFrm in 'SrvFrm.pas' {Form1};

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
