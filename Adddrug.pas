unit Adddrug;

interface

uses WinTypes, WinProcs, Classes, Graphics, Forms, Controls, Buttons,
  StdCtrls, ExtCtrls;

type
  TAddDose = class(TForm)
    CancelBtn: TBitBtn;
    Bevel1: TBevel;
    lbDrugName: TLabel;
    bOK: TBitBtn;
    cbDose: TComboBox;
    Label1: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure bOKClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    MinDose : single ;
    MaxDose : single ;
    SelectedDose : single ;
    Units : string ;
    Scale : single ;
  end;

var
  AddDose: TAddDose;

implementation

uses sysutils,ratmain ;

{$R *.DFM}

procedure TAddDose.FormCreate(Sender: TObject);
begin
     cbDose.ItemIndex := 0 ;
     end;

procedure TAddDose.FormShow(Sender: TObject);
var
   Dose : single ;
begin


     Left := MainForm.Left + 50 ;
     Top := MainForm.Top + 50 ;

     if MaxDose <= 1.0 then begin
        Scale := 1000.0 ;
        Units := 'ug/kg' ;
        end
     else begin
        Scale := 1.0 ;
        Units := 'mg/kg' ;
        end ;

     Dose := MinDose ;
     cbDose.Clear ;
     while Dose <= MaxDose do begin
       if Dose <= MaxDose then
          cbDose.Items.Add( format(' %.2f %s ',[Dose*Scale,Units]) ) ;
       if (2.0*Dose) <= MaxDose then
          cbDose.Items.Add( format(' %.1f %s ',[2.0*Dose*Scale,Units]) ) ;
       if (5.0*Dose) <= MaxDose then
          cbDose.Items.Add( format(' %.1f %s ',[5.0*Dose*Scale,Units]) ) ;
       Dose := Dose*10.0 ;
       end ;
     cbDose.ItemIndex := 0 ;
     end;

procedure TAddDose.bOKClick(Sender: TObject);
begin
     SelectedDose := ExtractFloat( cbDose.text, 1.0 ) / Scale ;
     end;

end.
