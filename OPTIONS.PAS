unit Options;

interface

uses WinTypes, WinProcs, Classes, Graphics, Forms, Controls, Buttons,
  StdCtrls, ExtCtrls, Dialogs;

type
  TOptionsFrm = class(TForm)
    OKBtn: TBitBtn;
    CancelBtn: TBitBtn;
    BPGrp: TGroupBox;
    ckABPShow: TCheckBox;
    Label1: TLabel;
    ABPColor: TShape;
    ColorDialog1: TColorDialog;
    GroupBox1: TGroupBox;
    Label2: TLabel;
    LVPColor: TShape;
    ckLVPShow: TCheckBox;
    GroupBox2: TGroupBox;
    Label3: TLabel;
    CVPColor: TShape;
    ckCVPShow: TCheckBox;
    GroupBox3: TGroupBox;
    Label4: TLabel;
    HCFColor: TShape;
    ckHCFShow: TCheckBox;
    GroupBox4: TGroupBox;
    Label5: TLabel;
    HRColor: TShape;
    ckHRShow: TCheckBox;
    procedure ABPColorMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure HRColorMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  OptionsFrm: TOptionsFrm;

implementation

{$R *.DFM}

procedure TOptionsFrm.ABPColorMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
     if ColorDialog1.execute then
        TShape(Sender).brush.color := ColorDialog1.color ;
     end;


procedure TOptionsFrm.HRColorMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
     if ColorDialog1.execute then
        HRcolor.brush.color := ColorDialog1.color ;
     end;

end.
