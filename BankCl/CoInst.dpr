program CoInst;

uses
  Forms,
  CoInstFrm in 'CoInstFrm.pas' {CoinstForm};

{$R *.RES}

begin
  Application.Initialize;
  Application.Title := 'Доустановка Клиент-банка';
  Application.CreateForm(TCoinstForm, CoinstForm);
  Application.Run;
end.
