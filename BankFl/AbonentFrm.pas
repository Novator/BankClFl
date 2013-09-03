unit AbonentFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Menus, ActnList, PostMachineFrm, Db, Grids, DBGrids, BtrDS, Utilits,
  StdCtrls, ExtCtrls;

type
  TAbonentForm = class(TForm)
    DBGrid: TDBGrid;
    DataSource: TDataSource;
    ActionList: TActionList;
    RunAction: TAction;
    StopAction: TAction;
    BreakAction: TAction;
    MainMenu: TMainMenu;
    EditItem: TMenuItem;
    RunItem: TMenuItem;
    StopItem: TMenuItem;
    EditBreaker1: TMenuItem;
    BreakItem: TMenuItem;
    BtnPanel: TPanel;
    NameLabel: TLabel;
    NameEdit: TEdit;
    SearchIndexComboBox: TComboBox;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormDestroy(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  AbonentForm: TAbonentForm;

implementation

{$R *.DFM}

procedure TAbonentForm.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  Action := caFree;
end;

procedure TAbonentForm.FormDestroy(Sender: TObject);
begin
  AbonentForm := nil;
end;

procedure TAbonentForm.FormCreate(Sender: TObject);
begin
  DataSource.DataSet := GetGlobalBase(biAbon) as TExtBtrDataSet;
  DefineGridCaptions(DBGrid, PatternDir+'Abons.tab');
end;

end.
