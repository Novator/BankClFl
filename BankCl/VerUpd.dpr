program VerUpd;

uses
  Forms,
  VerUpdateFrm in 'VerUpdateFrm.pas' {VerUpdateForm};

{$R *.RES}

begin
  if ParamCount>0 then
  begin
    Application.Initialize;
    Application.Title := '���������� ����-������';
    Application.CreateForm(TVerUpdateForm, VerUpdateForm);
    Application.Run;
  end;
end.
