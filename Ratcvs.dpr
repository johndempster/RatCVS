program RatCVS;

uses
  Forms,
  Ratmain in 'RATMAIN.PAS' {MainForm},
  Options in 'OPTIONS.PAS' {OptionsFrm},
  About in 'ABOUT.PAS' {AboutFrm},
  Adddrug in 'ADDDRUG.PAS' {AddDose},
  Setpage in 'setpage.pas' {SetPageFrm};

{$R *.RES}

begin
  Application.Title := 'The Virtual Rat';
  Application.HelpFile := '';
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TOptionsFrm, OptionsFrm);
  Application.CreateForm(TAboutFrm, AboutFrm);
  Application.CreateForm(TAddDose, AddDose);
  Application.CreateForm(TSetPageFrm, SetPageFrm);
  Application.Run;
end.
