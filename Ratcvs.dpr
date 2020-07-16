program RatCVS;

uses
  Forms,
  RATMAIN in 'RATMAIN.PAS' {MainForm},
  PrintUnit in 'PrintUnit.pas' {PrintFrm};

{$R *.RES}

begin
  Application.Title := 'The Virtual Rat';
  Application.HelpFile := '';
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TPrintFrm, PrintFrm);
  Application.Run;
end.
