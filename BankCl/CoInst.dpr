program CoInst;

uses
  Forms,
  CoInstFrm in 'CoInstFrm.pas' {CoinstForm};

{$R *.RES}

begin
  Application.Initialize;
  Application.Title := '����������� ������-�����';
  Application.CreateForm(TCoinstForm, CoinstForm);
  Application.Run;
end.
