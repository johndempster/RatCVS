unit About;

interface

uses WinTypes, WinProcs, Classes, Graphics, Forms, Controls, Buttons,
  StdCtrls;

type
  TAboutFrm = class(TForm)
    OKBtn: TBitBtn;
    lbName: TLabel;
    Label2: TLabel;
    Label4: TLabel;
    GroupBox1: TGroupBox;
    edName: TEdit;
    Label3: TLabel;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  AboutFrm: TAboutFrm;

implementation

uses ratmain ;

{$R *.DFM}

end.
