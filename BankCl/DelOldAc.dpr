program DelOldAc;

uses
  Forms,
  DelOldAccFrm in 'DelOldAccFrm.pas' {DelOldAccForm};

{$R *.RES}

begin
  Application.Initialize;
  Application.Title := 'Очистка Клиент-банк';
  Application.CreateForm(TDelOldAccForm, DelOldAccForm);
  Application.Run;
end.
