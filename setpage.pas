unit Setpage;
{ =======================================================
  Updates printer page settings in Settings.Plot
  =======================================================}

interface

uses
  SysUtils, WinTypes, WinProcs, Messages, Classes, Graphics, Controls,
  Forms, Dialogs, StdCtrls, Spin, Buttons, Printers ;

type
  TSetPageFrm = class(TForm)
    GroupBox1: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    edLeftMargin: TEdit;
    edTopMargin: TEdit;
    edRightMargin: TEdit;
    edBottomMargin: TEdit;
    bOK: TButton;
    bCancel: TButton;
    procedure FormShow(Sender: TObject);
    procedure bOKClick(Sender: TObject);
    procedure edRightMarginKeyPress(Sender: TObject; var Key: Char);
    procedure edTopMarginKeyPress(Sender: TObject; var Key: Char);
    procedure edBottomMarginKeyPress(Sender: TObject; var Key: Char);
    procedure edLeftMarginKeyPress(Sender: TObject; var Key: Char);
    procedure edPointSizeKeyPress(Sender: TObject; var Key: Char);
  private
    { Private declarations }
    procedure UpdateSettings ;

  public
    { Public declarations }

  end;

var
  SetPageFrm: TSetPageFrm;

implementation

uses ratmain ;
{$R *.DFM}
var
   LeftMargin : single ;
   RightMargin : single ;
   TopMargin : single ;
   BottomMargin : single ;

procedure TSetPageFrm.FormShow(Sender: TObject);
begin
     UpdateSettings ;
     end;


procedure TSetPageFrm.UpdateSettings ;
{ ---------------------------
  Update page margin settings
  ---------------------------}
begin
     { Top of page margin }
     TopMargin := ExtractFloat(edTopMargin.text,TopMargin) ;
     edTopMargin.text := format( '%.1f cm',[TopMargin]);

     { Bottom of page margin }
     BottomMargin := ExtractFloat(edBottomMargin.text,BottomMargin) ;
     edBottomMargin.text := format( '%.1f cm',[BottomMargin]);

     { Left page margin }
     LeftMargin := ExtractFloat(edLeftMargin.text,LeftMargin) ;
     edLeftMargin.text := format( '%.1f cm',[LeftMargin]);

     { Right page margin }
     RightMargin := ExtractFloat(edRightMargin.text,RightMargin) ;
     edRightMargin.text := format( '%.1f cm',[RightMargin]);

     end ;


procedure TSetPageFrm.bOKClick(Sender: TObject);
begin
     UpdateSettings ;
     end;


procedure TSetPageFrm.edRightMarginKeyPress(Sender: TObject;
  var Key: Char);
begin
     if key = chr(13) then UpdateSettings ;
     end;


procedure TSetPageFrm.edTopMarginKeyPress(Sender: TObject;
  var Key: Char);
begin
     if key = chr(13) then UpdateSettings ;
     end;


procedure TSetPageFrm.edBottomMarginKeyPress(Sender: TObject;
  var Key: Char);
begin
     if key = chr(13) then UpdateSettings ;
     end;


procedure TSetPageFrm.edLeftMarginKeyPress(Sender: TObject;
  var Key: Char);
begin
     if key = chr(13) then UpdateSettings ;
     end;

procedure TSetPageFrm.edPointSizeKeyPress(Sender: TObject; var Key: Char);
begin
     if key = chr(13) then UpdateSettings ;
     end;

end.
