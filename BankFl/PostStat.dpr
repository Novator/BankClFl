program PostStat;

uses
  Forms,
  PostStatFrm in 'PostStatFrm.pas' {PostStatForm};

{$R *.RES}

begin
  Application.Initialize;
  Application.Title := 'PostStat';
  Application.CreateForm(TPostStatForm, PostStatForm);
  Application.Run;
end.
