unit PrintUnit;
// ---------------------------
// Print displayed chart trace
// ---------------------------
// 8/11/11 ... DeviceName etc. now assigned using GetMem
// 3/03/15 ... Printer exception when no default printer set or no printers available now trapped
//             and causes form to exited with mrCancel mode flag.

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Printers, Vcl.ExtCtrls ;

type
  TPrintFrm = class(TForm)
    GroupBox6: TGroupBox;
    bPrinterSetup: TButton;
    edPrinterName: TEdit;
    bOK: TButton;
    bCancel: TButton;
    KillFormTimer: TTimer;
    procedure FormShow(Sender: TObject);
    procedure bPrinterSetupClick(Sender: TObject);
    procedure KillFormTimerTimer(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  PrintFrm: TPrintFrm;

implementation

uses RatMain;

{$R *.dfm}

procedure TPrintFrm.FormShow(Sender: TObject);
// ---------------------------------------
// Initialise controls when form displayed
// ---------------------------------------
const
    MaxSize = 100 ;
var
    DeviceName,DeviceDriver,Port : PChar ;
    DeviceMode : THandle ;
begin

     GetMem( DeviceName, MaxSize*SizeOf(WideChar) ) ;
     GetMem( DeviceDriver, MaxSize*SizeOf(WideChar) ) ;
     GetMem( Port, MaxSize*SizeOf(WideChar) ) ;

     try
        KillFormTimer.Enabled := False ;
        Printer.GetPrinter( DeviceName,DeviceDriver,Port,DeviceMode);
        edPrinterName.Text := String(DeviceName) ;
     except on E:EPrinter do begin
        ShowMessage('Unable to print!. No default printer selected or no printers available (see Windows->Devices & Printers).');
        KillFormTimer.Enabled := True ;
        end;
     end;

     FreeMem(DeviceName) ;
     FreeMem(DeviceDriver) ;
     FreeMem(Port) ;

     end;

procedure TPrintFrm.KillFormTimerTimer(Sender: TObject);
// -------------------------------------
// Hide form if timer has been activated
// -------------------------------------
begin
    bCancel.Click ;
    KillFormTimer.Enabled := False ;
    end;

procedure TPrintFrm.bPrinterSetupClick(Sender: TObject);
// --------------------------------
// Display printer setup dialog box
// --------------------------------
const
    MaxSize = 100 ;
var
    DeviceName,DeviceDriver,Port : PChar ;
    DeviceMode : THandle ;
begin
     MainForm.PrinterSetupDialog.Execute ;

     GetMem( DeviceName, MaxSize*SizeOf(WideChar) ) ;
     GetMem( DeviceDriver, MaxSize*SizeOf(WideChar) ) ;
     GetMem( Port, MaxSize*SizeOf(WideChar) ) ;

     Printer.GetPrinter( DeviceName,DeviceDriver,Port,DeviceMode);

     edPrinterName.Text := String(DeviceName) ;

     FreeMem(DeviceName) ;
     FreeMem(DeviceDriver) ;
     FreeMem(Port) ;

     end;

end.
