unit Ratmain;
 {$OPTIMIZATION OFF}
{ ========================================================================
  Rat cardivascular system simulation
  (c) J. Dempster, University of Strathclyde
  V2.0 1/9/97 Windows version
  V2.0a 30/9/97 L-NOARG does not inhibit sodium nitroprusside vasodilation
  V2.1 15/10/97 Now uses Windows API temporary file allocation routine
                Effect of Ach on peripheral flow now increased
  V2.1a 30/10/97 Incorrect X axis scaling when a sub-set of channels printed
                 now fixed.
  V2.2 20/9/98 16/32 bit version
  V2.2a 28/9/98 Now creates .tmp files in Windows temporary directory
  V3.0 8/1/99 Better cvs model. Now shows LVP, VBP, cardiac contractility
  V3.0b 1/2/99
  V3.0c 2/2/99 ... Normal/Pithed controls now radio buttons instead of menus
  V3.1 12/4/99 ... Stimulation of all symp. outflow except adrenal added
                   Prazozin corrected to Prazosin, and EC50=0.1 mg/kg
                   doses now displayed as /kg
  V3.1a 26/7/99 ... Name changed to RatCVS
  V3.2 4/7/00   ... High doses of acetylcholine in the presence of atropine
                    now increase BP and HR
                    Propranol, Atropine & Losartan increased in potency.
  V3.2a 3/5/01  ... Should now work with Italian/Spanish language Windows
  V3.2.2 29/08/01 ... Optimisations turned off to fix reversed for.. loop bug
                      which caused crashes under Windows NT
  V3.2.3 17/10/01 ... Help files no longer get lost when .RAT file saved
  V3.2.4 22/9/01 .... Drugs concentrations can now be entered with
                      Italian language settings
  V3.2.5 18/11/02 ... Compiled under Delphi V7
  V3.2.6 9/5/03 ..... Decimalseparator now included in ExtractInt()
  V3.2.7 2/12/03 .... Floating point error when trace reaches end of display fixed
                      Delay before re-drawing when trace reaches fixex
  V3.2.8 18/10/04 ... Memory exception error when selecting unknowns fixed
                      (FindDrug function)
                      Display calibration bars now adjust correctly when
                      window maximised
  V3.2.9 11/07/05 ... Memory Exceptions when program stopped fixed
  V3.3.0 29/01/07 ... Effect of renal nerve stimulation increased by 50%
                      Captopril no longer activates bradykinin receptors (only blocks ACE)
                      So captopril no longer appears to inhibit alpha-adrenoceptor response
                      of phenylephrine by directly activating arterial vasodilation
  V3.3.1 9/02/12 ...  Compiled under Delphi XE2
                      Now uses HTML Help format
  V3.3.2 11/02/14 ..  Milrinone now increases heart rate (due to effect of PDE inhibition of pacemaker current)
                      Error in GetTrailingPressure fixed reducing repetitive fluctuations in traces
                      Time course of heart systolic contraction now gaussian function
  ======================================================================== }

interface

uses
  SysUtils, WinTypes, WinProcs, Messages, Classes, Graphics, Controls,
  Forms, Dialogs, Menus, StdCtrls, ExtCtrls, AddDrug, Options,
  Printers, About, Vcl.ComCtrls,math, HTMLHelpViewer, shellapi  ;

const
     BPMax = 200 ;
     ChABP = 0 ;   { Arterial blood pressure channel }
     ChLVP = 1 ;   { Average bloood pressure channel }
     ChCVP = 2 ;   { Venous blood pressure }
     ChHCF = 3 ;   { Cardiac contractility }
     ChHR = 4 ;    { Heart rate channel }
     ChMarker = 5 ;  { Event marker channel }
     ChMarkerValue = 6 ;
     ChMarkerUnits = 7 ;
     ChannelLimit = 7 ;
     NumChannels = ChannelLimit+1 ;
     None = -1. ;
     mgUnits = 0 ;
     ugUnits = 1 ;
     NoUnits = 2 ;

type
    TDrugProperties = record
                    Potency : single ;
                    Efficacy : single ;
                    end ;

  TMainForm = class(TForm)
    MainMenu1: TMainMenu;
    StandardDrugs: TMenuItem;
    mndrugAL: TMenuItem;
    mnOptions: TMenuItem;
    Timer: TTimer;
    mnAdrenaline: TMenuItem;
    mnNoradrenaline: TMenuItem;
    mnIsoprenaline: TMenuItem;
    mnAcetylcholine: TMenuItem;
    mnPropranolol: TMenuItem;
    mnAtropine: TMenuItem;
    mnFile: TMenuItem;
    mnNewRat: TMenuItem;
    mnLoadRat: TMenuItem;
    mnSaveRat: TMenuItem;
    mnPrint: TMenuItem;
    PrintSetup1: TMenuItem;
    mnExit: TMenuItem;
    mnHelp: TMenuItem;
    mnContents: TMenuItem;
    mnAbout: TMenuItem;
    SaveDialog: TSaveDialog;
    OpenDialog: TOpenDialog;
    PrinterSetupDialog: TPrinterSetupDialog;
    mnDrugA: TMenuItem;
    mnDrugB: TMenuItem;
    mnDrugC: TMenuItem;
    mnDrugD: TMenuItem;
    mnDrugE: TMenuItem;
    mnDrugF: TMenuItem;
    mnDrugG: TMenuItem;
    mnDrugH: TMenuItem;
    mndrugI: TMenuItem;
    mndrugJ: TMenuItem;
    mnLNOARG: TMenuItem;
    mn8SPT: TMenuItem;
    Phentolamine1: TMenuItem;
    Verapamil1: TMenuItem;
    mnGlyceryltrinitrate: TMenuItem;
    N1: TMenuItem;
    Cromakalim1: TMenuItem;
    mnAdenosine1: TMenuItem;
    NerveStimulation1: TMenuItem;
    mnStimCardiac: TMenuItem;
    mnStimAdrenal: TMenuItem;
    mnAngiotensin2: TMenuItem;
    mnCaptopril: TMenuItem;
    mnLosartan: TMenuItem;
    mnRenal: TMenuItem;
    mnDigoxin: TMenuItem;
    mnMilrinone: TMenuItem;
    mnPhenylephrine: TMenuItem;
    mnPrazozin: TMenuItem;
    mnAtenolol: TMenuItem;
    N2: TMenuItem;
    mndisplay: TMenuItem;
    mnGlibenclamide: TMenuItem;
    mnStimBloodVessels: TMenuItem;
    mnStimVagus: TMenuItem;
    Page: TPageControl;
    ChartTab: TTabSheet;
    PictureTab: TTabSheet;
    pbDisplay: TPaintBox;
    ControlGrp: TGroupBox;
    sbRecord: TScrollBar;
    bStart: TButton;
    bStop: TButton;
    edCursor: TEdit;
    GroupBox1: TGroupBox;
    rbNormalRat: TRadioButton;
    rbPithedRat: TRadioButton;
    ExpImage: TImage;
    procedure TimerTimer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure mnAdrenalineClick(Sender: TObject);
    procedure pbDisplayPaint(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure bStopClick(Sender: TObject);
    procedure sbRecordChange(Sender: TObject);
    procedure bStartClick(Sender: TObject);
    procedure mnPrintClick(Sender: TObject);
    procedure pbDisplayMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure mnExitClick(Sender: TObject);
    procedure mnContentsClick(Sender: TObject);
    procedure mnAboutClick(Sender: TObject);
    procedure mnLoadRatClick(Sender: TObject);
    procedure mnSaveRatClick(Sender: TObject);
    procedure mnNewRatClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure mnStimCardiacClick(Sender: TObject);
    procedure mnStimAdrenalClick(Sender: TObject);
    procedure mnStimVagusClick(Sender: TObject);
    procedure mnRenalClick(Sender: TObject);
    procedure PrintSetup1Click(Sender: TObject);
    procedure mndisplayClick(Sender: TObject);
    procedure mnStimBloodVesselsClick(Sender: TObject);
    procedure mnHelpClick(Sender: TObject);

  private
    { Private declarations }
    procedure InitializeDisplay ;
    procedure CalculateTrace ;
    procedure PrintTraces ;
    procedure InitializeSimulation ;
    procedure SetAgonistPotency(
              var Drug : TDrugProperties ;
              Potency : single
              ) ;
    procedure SetAntagonistPotency(
              var Drug : TDrugProperties ;
              Potency : single
              ) ;

    Function ReceptorActivation(
          iDrug : Integer ;
          Dose : single ;
          var Drug : TDrugProperties ;
          var Numerator : single ;
          var Denominator : single ;
          PotencyShift : single
          ) : single ;
  public
    { Public declarations }
    ProgName : string ;
    WinDir : PChar ;
  end;

    TElement = class(TObject)
               public
               Conductance : single ;
               Elastance : single ;
               Pressure : single ;
               MaxPressure : single ;
               MinPressure : single ;
               MeanPressure : single ;
               PressureLo : single ;
               PressureHi : single ;
               TLo : single ;
               THi : single ;
               Volume : single ;
               Volume0 : single ;
               Flow : Single ;
               Rate : single ;
               TSystole : single ;
               NextBeat : single ;
               Time : single ;
               Force : single ;
               procedure CalculatePressureRange( t : single ) ;
               procedure InitialisePressureRange ;
               function GetLeadingPressure : single ;
               function GetTrailingPressure : single ;
               end ;

    TDrug = class(TObject)
            public
            Name : string[40] ;
            ShortName : string ;
            Dose : single ;
            DoseInjected : single ;
            Conc : single ;
            Alpha1AdR : TDrugProperties ;
            Alpha2AdR : TDrugProperties ;
            Beta1AdR : TDrugProperties ;
            Beta2AdR : TDrugProperties ;
            MusChR : TDrugProperties ;
            VagChR : TDrugProperties ;
            NicChR : TDrugProperties ;
            HMCaChannel : TDrugProperties ;
            SMCaChannel : TDrugProperties ;
            AdenR : TDrugProperties ;
            KChannel : TDrugProperties ;
            NOX : TDrugProperties ;
            NOS : TDrugProperties ;
            Angt1R: TDrugProperties ;
            Angt2R: TDrugProperties ;
            BradR: TDrugProperties ;
            ACE : TDrugProperties ;
            DigR : TDrugProperties ;
            PDE : TDrugProperties ;
            OnRate : single ;
            RemovalRate : single ;
            MinDose : single ;
            MaxDose : single ;
            constructor Create(
                        NameIn : String ;
                        ShortNameIn : string
                        ) ;
            end ;

function MaxFlt( const Buf : array of Single ) : Single ;
function MinFlt( const Buf : array of Single ) : Single ;
function MaxInt( const Buf : array of Integer ) : Integer ;
function AddNoise( Proportion : single ) : single ;
Procedure UpdateCirculatingDrug( var Drug : TDrug ) ;
function ExtractFloat ( CBuf : string ; Default : Single ) : extended ;
function FindDrug( DrugList : Array of TDrug ; DrugName : string ) : Integer ;

function PrinterPointsToPixels( PointSize : Integer ) : Integer ;
function Pressure( Element : TElement ) : single ;
function PrinterCmToPixels(
         const Axis : string;
         cm : single
         ) : Integer ;
var
  MainForm: TMainForm;

implementation

uses Setpage;

{$R *.DFM}
type
    TState = (Recording,Idle,Replay) ;
    TTime = record
          time : single ;
          diastole : single ;
          systole : single ;
          step : single ;
          next : single ;
          end ;


    TBP = record
        diastolic : single ;
        systolic : single ;
        mean : single ;
        value : single ;
        end ;


    TMarker = record
            Index : single ;
            Value : single ;
            Units : single ;
            end ;

    TNerve = record
           Stimulated : boolean ;
           StimulusInterval : single ;
           StimulusActivity : single ;
           Activity : single ;
           end ;


TString6 = string[6] ;
TChannel = record
         xMin : single ;
         xMax : single ;
         yMin : single ;
         yMax : single ;
         xScale : single ;
         yScale : single ;
         yCal : single ;
         Left : LongInt ;
         Right : LongInt ;
         Top : LongInt ;
         Bottom : LongInt ;
         TimeZero : single ;
         ADCUnits : Tstring6 ;
         ADCName : TString6 ;
         ZeroIndex : LongInt ;
         CursorTime : single ;
         CursorValue : single ;
         color : TColor ;
         Value : single ;
         InUse : boolean ;
         end ;
TBuf = Array[0..(8*4096-1)] of single ;
TFileBuf = Array[0..511] of single ;



var
   State : TState ;
   OldPos : Array[0..ChannelLimit] of TPoint ;
   Channel : Array[0..Channellimit] of TChannel ;
   Buf : TBuf ;
   FileBuf : TFileBuf ;
   FileBufPointer, EndOfFileBuf : LongInt ;
   FileHandle : Integer ;
   FilePointer : LongInt ;
   FileName : string ;
   TempFileName : string ;
   BufPointer,EndOfBuf,FirstQuarter,LastQuarter : LongInt ;
   Initialized : boolean ;
   t : TTime ;
   BP : TBP ;
   Marker : TMarker ;
   MarkerUnits : array[0..2] of string ;
   {Standard drugs }
   Drugs : Array[0..50] of TDrug ;
   MusChR : single ; { Proportion of muscarinic cholinoceptors activated }
   VagChR : single ; { Proportion of muscarinic cholinoceptors activated }
   NicChR : single ; { Proportion of nicotinic cholinoceptors activated }
   Alpha1AdR : single ; { Proportion of Alpha1 adrenoceptors activated }
   iAlpha1AdrNerves : Integer ;
   Alpha2AdR : single ; { Proportion of Alpha2 adrenoceptors activated }
   Beta1AdR : single ; { Proportion of beta-1 adrenoceptors activated }
   iBeta1AdrNerves : Integer ;
   Beta2AdR : single ; { Proportion of beta-2 adrenoceptors activated }
   AdenR : single ; { Proportion of adenosine receptors activated }
   HMCaChannels : single ; { Proportion of heart muscle Ca channels blocked }
   SMCaChannels : single ; { Proportion of smooth muscle Ca channels blocked }
   KChannels : single ; { K channel mediated vasodilation }
   NOX : single ; { Nitric oxide mediated vasodilation }
   NOS : single ; { Nitric oxide synthase }
   Angt1R : single ; { Angiotensin I receptor }
   iAngiotensin1 : Integer ; { Angiotensin I entry with Drugs array }
   Angt2R : single ; { Angiotensin II receptor }
   iAngiotensin2ACE : Integer ; { ACE-produced Angiotensin II entry with Drugs array }
   iRenalNerve : Integer ;
   iVagusNerve : Integer ;
   ACE : single ;    { Angiotensin converting enzyme activity }
   BradR : single ;  { Bradykinin recptor }
   DigR : single ;   { Digoxin activity on cardiac force }
   PDE : single ; { Degree of phosphidesterase inhibition }

   ChartWidth : single ;
   Baroreceptors : single ;
   Dead : boolean ;
   Dying : LongInt ;
   Fibrillation : single ;
   Ven : TElement ;
   Art : TElement ;
   Heart : TElement ;
   Con : TElement ;

procedure TMainForm.FormCreate(Sender: TObject);
{ ------------------------------------
  Initialisations when form is created
  ------------------------------------}

begin
     Caption := 'Rat Cardiovascular System V3.3.2 (Feb 2014) ' ;

     ProgName := Caption ;

     Application.HelpFile := ExtractFilePath(ParamStr(0)) + 'ratcvs.chm';

     Heart := TElement.Create ;
     Art := TElement.Create ;
     Ven := TElement.Create ;
     Con := TElement.Create ;

     InitializeSimulation ;
     end;


procedure TMainForm.InitializeSimulation ;
{ ---------------------------------------------
  Set up initial conditions for simulation
  15/10/97 Better temporary file allocation
  ----------------------------------------}

const
     pFilePrefix : PChar = 'RCV' ;
     FastOn = 0.006 ;
     FastOff = 0.0035 ;
     SlowOn = 0.002 ;
     SlowOff = 5E-4 ;

var
   ch,iCount,iNum,iDrug : Integer ;
   x : single ;
   TempPath : Array[0..255] of Char ;
   TempName : Array[0..255] of Char ;
   Done,GiveUp : Boolean ;
begin
     { Get path to temporary file directory }
     GetTempPath( High(TempPath), TempPath ) ;
     { Create a temp file name }
     iNum := GetTempFileName( TempPath, pFilePrefix, 0, TempName ) ;
     TempFileName := TempName ;

     { Open temporary file }
     FileHandle := FileCreate( TempFileName ) ;
     if FileHandle <= 0 then begin
        MessageDlg('Cannot open work file!', mtWarning,[mbOK],0) ;
        close ;
        end ;
     Caption := ProgName ;

     {Initialise drug doses and potencies }

     for iDrug := 0 to High(Drugs) do Drugs[iDrug] := Nil ;

{    *** STANDARD DRUGS ***************************************************}

     { Adrenaline - Alpha11,beta1,beta2 adrenoceptor agonist }
     iDrug := 0 ;
     Drugs[iDrug] := TDrug.Create( 'Adrenaline', 'Adr' ) ;
     Drugs[iDrug].OnRate := FastOn ;
     Drugs[iDrug].RemovalRate := FastOff ;
     SetAgonistPotency( Drugs[iDrug].Alpha1AdR, {5E-3} 3.5e-3 ) ;
     SetAgonistPotency( Drugs[iDrug].Beta1AdR, 3.5E-3 ) ;
     SetAgonistPotency( Drugs[iDrug].Beta2AdR, 5E-3 ) ;
     Drugs[iDrug].MinDose := 1E-4 ;
     Drugs[iDrug].MaxDose := 1E-1 ;


     Inc(iDrug) ;
     Drugs[iDrug] := TDrug.Create( 'Noradrenaline', 'Nor' ) ;
     Drugs[iDrug].OnRate := FastOn ;
     Drugs[iDrug].RemovalRate := FastOff ;
     SetAgonistPotency( Drugs[iDrug].Alpha1AdR, 1E-2 ) ;
     SetAgonistPotency( Drugs[iDrug].Beta1AdR, 1.5E-2 ) ;
     SetAgonistPotency( Drugs[iDrug].Beta2AdR, 1.5E-1 ) ;
     Drugs[iDrug].MinDose := 1E-3 ;
     Drugs[iDrug].MaxDose := 1.0 ;

     Inc(iDrug) ;
     Drugs[iDrug] := TDrug.Create(  'Isoprenaline', 'Iso' ) ;
     Drugs[iDrug].OnRate := FastOn ;
     Drugs[iDrug].RemovalRate := FastOff ;
     SetAgonistPotency( Drugs[iDrug].Beta1AdR, 1E-3 ) ;
     SetAgonistPotency( Drugs[iDrug].Beta2AdR, 7E-4 ) ;
     Drugs[iDrug].MinDose := 1E-4 ;
     Drugs[iDrug].MaxDose := 1E-1 ;

     Inc(iDrug) ;
     Drugs[iDrug] := TDrug.Create(  'Phenylephrine', 'Phe' ) ;
     Drugs[iDrug].OnRate := FastOn ;
     Drugs[iDrug].RemovalRate := FastOff ;
     SetAgonistPotency( Drugs[iDrug].Alpha1AdR, 1E-2 ) ;
     Drugs[iDrug].MinDose := 1E-3 ;
     Drugs[iDrug].MaxDose := 1. ;

     Inc(iDrug) ;
     Drugs[iDrug] := TDrug.Create(  'Phentolamine', 'Phe' ) ;  { Alpha Adr. }
     Drugs[iDrug].OnRate := FastOn ;                           { antagonist }
     Drugs[iDrug].RemovalRate := SlowOff ;
     SetAntagonistPotency( Drugs[iDrug].Alpha1Adr, 1E-1 ) ;
     SetAgonistPotency( Drugs[iDrug].Alpha2Adr, 1E-1 ) ;
     Drugs[iDrug].MinDose := 1E-2 ;
     Drugs[iDrug].MaxDose := 10. ;


     Inc(iDrug) ;
     Drugs[iDrug] := TDrug.Create(  'Prazosin', 'Pra' ) ;    { Alpha-1 Adr. }
     Drugs[iDrug].OnRate := FastOn ;                         { antagonist }
     Drugs[iDrug].RemovalRate := SlowOff ;
     SetAntagonistPotency( Drugs[iDrug].Alpha1Adr, 0.1 ) ;
     Drugs[iDrug].MinDose := 0.01 ;
     Drugs[iDrug].MaxDose := 10. ;


     Inc(iDrug) ;
     Drugs[iDrug] := TDrug.Create(  'Propranolol', 'Pro' ) ;  { Beta Adr. }
     Drugs[iDrug].OnRate := FastOn ;                         { Antagonist }
     Drugs[iDrug].RemovalRate := SlowOff ;                   { Potency modified 4/7/00}
     SetAntagonistPotency( Drugs[iDrug].Beta1AdR, 0.5 ) ;
     SetAntagonistPotency( Drugs[iDrug].Beta2AdR, 0.5 ) ;
     Drugs[iDrug].MinDose := 0.01 ;
     Drugs[iDrug].MaxDose := 100. ;


     Inc(iDrug) ;
     Drugs[iDrug] := TDrug.Create(  'Atenolol', 'Ate' ) ;     { Beta-1 Adr. }
     Drugs[iDrug].OnRate := FastOn ;                          { Antagonist }
     Drugs[iDrug].RemovalRate := SlowOff ;
     SetAntagonistPotency( Drugs[iDrug].Beta1AdR, 10.0 ) ;
     Drugs[iDrug].MinDose := 1.0 ;
     Drugs[iDrug].MaxDose := 1000. ;


     Inc(iDrug) ;
     Drugs[iDrug] := TDrug.Create(  'Acetylcholine', 'Ach' ) ;
     Drugs[iDrug].OnRate := FastOn ;
     Drugs[iDrug].RemovalRate := FastOff*2.0 ;
     SetAgonistPotency( Drugs[iDrug].MusChR, 5E-3 ) ;
     SetAgonistPotency( Drugs[iDrug].NicChR, 0.15 ) ;
     SetAgonistPotency( Drugs[iDrug].Alpha1AdR, 0.3 ) ;
     SetAgonistPotency( Drugs[iDrug].Beta1AdR, 0.15 ) ;
     Drugs[iDrug].MinDose := 1E-3 ;
     Drugs[iDrug].MaxDose := 1. ;


     Inc(iDrug) ;
     Drugs[iDrug] := TDrug.Create(  'Atropine', 'Atr' ) ;
     Drugs[iDrug].OnRate := FastOn ;
     Drugs[iDrug].RemovalRate := SlowOff ;
     SetAntagonistPotency( Drugs[iDrug].MusChR, 0.1 ) ; {Potency reduced to 0.1 4/7/00}
     SetAntagonistPotency( Drugs[iDrug].VagChR, 0.1 ) ;
     Drugs[iDrug].MinDose := 0.01 ;
     Drugs[iDrug].MaxDose := 10.0 ;


     Inc(iDrug) ;
     Drugs[iDrug] := TDrug.Create(  'Adenosine', 'Ade' ) ;
     Drugs[iDrug].OnRate := FastOn ;
     Drugs[iDrug].RemovalRate := FastOff ;
     SetAgonistPotency( Drugs[iDrug].AdenR, 1.0 ) ;
     Drugs[iDrug].MinDose := 0.1 ;
     Drugs[iDrug].MaxDose := 100. ;


     Inc(iDrug) ;
     Drugs[iDrug] := TDrug.Create(  '8-s-p-theophylline', '8spt' ) ;
     Drugs[iDrug].OnRate := FastOn ;
     Drugs[iDrug].RemovalRate := SlowOff ;
     SetAntagonistPotency( Drugs[iDrug].AdenR, 5.0 ) ;
     Drugs[iDrug].MinDose := 0.1 ;
     Drugs[iDrug].MaxDose := 100.0 ;


     Inc(iDrug) ;
     Drugs[iDrug] := TDrug.Create(  'Verapamil', 'Ver' ) ;
     Drugs[iDrug].OnRate := SlowOn ;
     Drugs[iDrug].RemovalRate := SlowOff ;
     SetAgonistPotency( Drugs[iDrug].HMCaChannel, 0.75 ) ;
     SetAgonistPotency( Drugs[iDrug].SMCaChannel, 0.75 ) ;
     Drugs[iDrug].MinDose := 0.1 ;
     Drugs[iDrug].MaxDose := 100. ;


     Inc(iDrug) ;
     Drugs[iDrug] := TDrug.Create(  'L-NOARG', 'LNO' ) ;
     Drugs[iDrug].OnRate := FastOn ;
     Drugs[iDrug].RemovalRate := SlowOff ;
     SetAgonistPotency( Drugs[iDrug].NOS, 10.0 ) ;
     Drugs[iDrug].MinDose := 1.0 ;
     Drugs[iDrug].MaxDose := 1000. ;


     Inc(iDrug) ;
     Drugs[iDrug] := TDrug.Create(  'Cromakalim', 'Cro' ) ;     { K channel opener }
     Drugs[iDrug].OnRate := SlowOn ;                            {causes vasodilation }
     Drugs[iDrug].RemovalRate := SlowOff ;
     SetAgonistPotency( Drugs[iDrug].KChannel, 0.3 ) ;
     Drugs[iDrug].MinDose := 0.1 ;
     Drugs[iDrug].MaxDose := 100. ;

     Inc(iDrug) ;
     Drugs[iDrug] := TDrug.Create(  'Glibenclamide', 'Gli' ) ;   { K Channel blocker }
     Drugs[iDrug].OnRate := SlowOn ;
     Drugs[iDrug].RemovalRate := SlowOff ;
     SetAntagonistPotency( Drugs[iDrug].KChannel, 1.0 ) ;
     Drugs[iDrug].MinDose := 0.1 ;
     Drugs[iDrug].MaxDose := 100. ;


     Inc(iDrug) ;
     Drugs[iDrug] := TDrug.Create(  'Angiotensin I', 'An1' ) ;
     Drugs[iDrug].OnRate := FastOn ;
     Drugs[iDrug].RemovalRate := FastOff ;
     SetAgonistPotency( Drugs[iDrug].Angt1R, 1E-4 ) ;
     iAngioTensin1 := iDrug ;
     Drugs[iDrug].MinDose := 1E-4 ;
     Drugs[iDrug].MaxDose := 1E-2 ;


     Inc(iDrug) ;
     Drugs[iDrug] := TDrug.Create(  'Angiotensin II', 'An2' ) ;
     Drugs[iDrug].OnRate := FastOn ;
     Drugs[iDrug].RemovalRate := FastOff ;
     SetAgonistPotency( Drugs[iDrug].Angt2R, 1E-4 ) ;
     Drugs[iDrug].MinDose := 1E-4 ;
     Drugs[iDrug].MaxDose := 1E-2 ;


     Inc(iDrug) ;
     Drugs[iDrug] := TDrug.Create(  'AngiotensinIIACE', 'An2' ) ;
     Drugs[iDrug].OnRate := FastOn ;
     Drugs[iDrug].RemovalRate := FastOff ;
     SetAgonistPotency( Drugs[iDrug].Angt2R, 1E-4 ) ;
     iAngioTensin2ACE := iDrug ;
     Drugs[iDrug].MinDose := 1E-4 ;
     Drugs[iDrug].MaxDose := 1E-2 ;

     Inc(iDrug) ;
     Drugs[iDrug] := TDrug.Create(  'Captopril', 'Cap' ) ; { ACE inhibitor }
     Drugs[iDrug].OnRate := SlowOn ;
     Drugs[iDrug].RemovalRate := SlowOff ;
     SetAgonistPotency( Drugs[iDrug].ACE, 5.0 ) ;
     //SetAgonistPotency( Drugs[iDrug].BradR, 5.0 ) ;
     Drugs[iDrug].MinDose := 1.0 ;
     Drugs[iDrug].MaxDose := 1000. ;

     Inc(iDrug) ;
     Drugs[iDrug] := TDrug.Create(  'Losartan', 'Los' ) ; { Blocks angiotensin II }
     Drugs[iDrug].OnRate := FastOn ; ;
     Drugs[iDrug].RemovalRate := SlowOff ;
     SetAntagonistPotency( Drugs[iDrug].Angt2R, 1.0 ) ;    { Potency reduced to 1 4/7/00) }
     Drugs[iDrug].MinDose := 1. ;
     Drugs[iDrug].MaxDose := 1000. ;

     Inc(iDrug) ;
     Drugs[iDrug] := TDrug.Create(  'Digoxin', 'Dig' ) ; { Digoxin }
     Drugs[iDrug].OnRate := SlowOn*0.25 ;
     Drugs[iDrug].RemovalRate := SlowOff ;
     SetAgonistPotency( Drugs[iDrug].DigR, 0.5 ) ;
     Drugs[iDrug].MinDose := 0.1 ;
     Drugs[iDrug].MaxDose := 100. ;

     Inc(iDrug) ;
     Drugs[iDrug] := TDrug.Create(  'Glyceryl trinitrate', 'GTN' ) ;     { Glyceryl trinitrate }
     Drugs[iDrug].OnRate := FastOn ;
     Drugs[iDrug].RemovalRate := FastOff ;
     SetAgonistPotency( Drugs[iDrug].NOX, 10.0 ) ;
     Drugs[iDrug].MinDose := 1.0 ;
     Drugs[iDrug].MaxDose := 1000. ;

     Inc(iDrug) ;
     Drugs[iDrug] := TDrug.Create(  'Milrinone', 'Mil' ) ;     { Phosphodiesterase inh. }
     Drugs[iDrug].OnRate := SlowOn ;
     Drugs[iDrug].RemovalRate := SlowOff ;
     SetAgonistPotency( Drugs[iDrug].PDE, 10.0 ) ;
     Drugs[iDrug].MinDose := 1. ;
     Drugs[iDrug].MaxDose := 1000. ;


{    *** UNKNOWN DRUGS *****************************************************}

     Inc(iDrug) ;
     Drugs[iDrug] := TDrug.Create(  'Drug A', 'A' ) ;    { Acetylcholine }
     Drugs[iDrug].OnRate := FastOn ;
     Drugs[iDrug].RemovalRate := FastOff ;
     SetAgonistPotency( Drugs[iDrug].MusChR, 5E-3 ) ;
     SetAgonistPotency( Drugs[iDrug].NicChR, 0.1 ) ;
     SetAgonistPotency( Drugs[iDrug].Alpha1AdR, 0.3 ) ;
     SetAgonistPotency( Drugs[iDrug].Beta1AdR, 0.15 ) ;
     Drugs[iDrug].MinDose := 1E-3 ;
     Drugs[iDrug].MaxDose := 1. ;


     Inc(iDrug) ;
     Drugs[iDrug] := TDrug.Create(  'Drug B', 'B' ) ;     { Adenosine  }
     Drugs[iDrug].OnRate := FastOn ;
     Drugs[iDrug].RemovalRate := FastOff ;
     SetAgonistPotency( Drugs[iDrug].AdenR, 1.0 ) ;
     Drugs[iDrug].MinDose := 0.1 ;
     Drugs[iDrug].MaxDose := 1000. ;


     Inc(iDrug) ;
     Drugs[iDrug] := TDrug.Create(  'Drug C', 'C' ) ;    { Isoprenaline }
     Drugs[iDrug].OnRate := FastOn ;
     Drugs[iDrug].RemovalRate := SlowOff ;
     SetAgonistPotency( Drugs[iDrug].Beta1AdR, 1E-3 ) ;
     SetAgonistPotency( Drugs[iDrug].Beta2AdR, 7E-4 ) ;
     Drugs[iDrug].MinDose := 1E-4 ;
     Drugs[iDrug].MaxDose := 1E-1 ;


     Inc(iDrug) ;
     Drugs[iDrug] := TDrug.Create(  'Drug D', 'D' ) ;    { Noradrenaline }
     Drugs[iDrug].OnRate := FastOn ;
     Drugs[iDrug].RemovalRate := FastOff ;
     SetAgonistPotency( Drugs[iDrug].Alpha1AdR, 1E-2 ) ;
     SetAgonistPotency( Drugs[iDrug].Beta1AdR, 1.5E-2 ) ;
     SetAgonistPotency( Drugs[iDrug].Beta2AdR, 1.5E-1 ) ;
     Drugs[iDrug].MinDose := 1E-3 ;
     Drugs[iDrug].MaxDose := 1. ;


     Inc(iDrug) ;
     Drugs[iDrug] := TDrug.Create( 'Drug E', 'E' ) ;      { Sodium nitroprusside }
     Drugs[iDrug].OnRate := FastOn ;
     Drugs[iDrug].RemovalRate := FastOff ;
     SetAgonistPotency( Drugs[iDrug].NOX, 15.0 ) ;
     Drugs[iDrug].MinDose := 1.0 ;
     Drugs[iDrug].MaxDose := 1000. ;


     Inc(iDrug) ;
     Drugs[iDrug] := TDrug.Create( 'Drug F', 'F' ) ;    { Cromokalim }
     Drugs[iDrug].OnRate := SlowOn ;
     Drugs[iDrug].RemovalRate := SlowOff ;
     SetAgonistPotency( Drugs[iDrug].KChannel, 0.3 ) ;
     Drugs[iDrug].MinDose := 1.0 ;
     Drugs[iDrug].MaxDose := 1000. ;


     Inc(iDrug) ;
     Drugs[iDrug] := TDrug.Create(  'Drug G', 'G' ) ;     { Milrinone }
     Drugs[iDrug].OnRate := SlowOn ;
     Drugs[iDrug].RemovalRate := SlowOff ;
     SetAgonistPotency( Drugs[iDrug].PDE, 10.0 ) ;
     Drugs[iDrug].MinDose := 1. ;
     Drugs[iDrug].MaxDose := 1000. ;


     Inc(iDrug) ;
     Drugs[iDrug] := TDrug.Create(  'Drug H', 'H' ) ;     { Propanalol }
     Drugs[iDrug].OnRate := FastOn ;
     Drugs[iDrug].RemovalRate := SlowOff ;
     SetAntagonistPotency( Drugs[iDrug].Beta1AdR, 10.0 ) ;
     SetAntagonistPotency( Drugs[iDrug].Beta2AdR, 10.0 ) ;
     Drugs[iDrug].MinDose := 1.0 ;
     Drugs[iDrug].MaxDose := 1000. ;


     Inc(iDrug) ;
     Drugs[iDrug] := TDrug.Create(  'Drug I', 'I' ) ;     { Verapamil }
     Drugs[iDrug].OnRate := SlowOn ;
     Drugs[iDrug].RemovalRate := SlowOff ;
     SetAgonistPotency( Drugs[iDrug].HMCaChannel, 0.75 ) ;
     SetAgonistPotency( Drugs[iDrug].SMCaChannel, 0.75 ) ;
     Drugs[iDrug].MinDose := 0.1 ;
     Drugs[iDrug].MaxDose := 100. ;


     Inc(iDrug) ;
     Drugs[iDrug] := TDrug.Create(  'Drug J', 'J' ) ;   { L-NOARG (NOS-inhibitor) }
     Drugs[iDrug].OnRate := FastOn ;
     Drugs[iDrug].RemovalRate := SlowOff ;
     SetAgonistPotency( Drugs[iDrug].NOS, 10.0 ) ;
     Drugs[iDrug].MinDose := 1. ;
     Drugs[iDrug].MaxDose := 1000. ;


     Inc(iDrug) ;
     Drugs[iDrug] := TDrug.Create(  'Drug K', 'K' ) ;   { Atropine }
     Drugs[iDrug].OnRate := FastOn ;
     Drugs[iDrug].RemovalRate := SlowOff ;
     SetAntagonistPotency( Drugs[iDrug].MusChR, 0.1 ) ; {Potency reduced to 0.1 4/7/00}
     SetAntagonistPotency( Drugs[iDrug].VagChR, 0.1 ) ;
     Drugs[iDrug].MinDose := 0.1 ;
     Drugs[iDrug].MaxDose := 100. ;



{    *** NERVE STIMULATION **************************************************}

     { Cardiac nerve stimulation - beta1 adrenoceptor agonist }
     Inc(iDrug) ;
     Drugs[iDrug] := TDrug.Create(  'Cardiac', 'Symp(H)' ) ;
     Drugs[iDrug].OnRate := FastOn*4.0 ;
     Drugs[iDrug].RemovalRate := FastOff*4.0 ;
     SetAgonistPotency( Drugs[iDrug].Beta1AdR, 1.5E-2 ) ;

     { Adrenal nerve stimulation - Alpha1,beta1,beta2 adrenoceptor agonist }
     Inc(iDrug) ;
     Drugs[iDrug] := TDrug.Create(  'AdrenNerve', 'Symp(AD)' ) ;
     Drugs[iDrug].OnRate := FastOn*2.0 ;
     Drugs[iDrug].RemovalRate := FastOff ;
     SetAgonistPotency( Drugs[iDrug].Alpha1AdR, 5E-3 ) ;
     SetAgonistPotency( Drugs[iDrug].Beta1AdR, 3.55E-3 ) ;
     SetAgonistPotency( Drugs[iDrug].Beta2AdR, 5E-3 ) ;

     { Blood vessel symp. nerve stimulation - noradrenaline }
     Inc(iDrug) ;
     Drugs[iDrug] := TDrug.Create(  'SympNerve', 'Symp(-AD)' ) ;
     Drugs[iDrug].OnRate := FastOn*7.0 ;
     Drugs[iDrug].RemovalRate := FastOff*4.0 ;
     SetAgonistPotency( Drugs[iDrug].Alpha1AdR, 1E-2 ) ;
     SetAgonistPotency( Drugs[iDrug].Beta1AdR, 1.5E-2 ) ;
     SetAgonistPotency( Drugs[iDrug].Beta2AdR, 1.5E-1 ) ;

     { Vagus nerve stimulation - cholinergic agonist }
     Inc(iDrug) ;
     Drugs[iDrug] := TDrug.Create(  'Vagus', 'Vag. Nv.' ) ;
     Drugs[iDrug].OnRate := FastOn*4.0 ;
     Drugs[iDrug].RemovalRate := FastOn*4.0 ;
     SetAgonistPotency( Drugs[iDrug].VagChR, 5E-3 ) ;
     iVagusNerve := iDrug ;

      { Renal nerve stimulation - Release angiotensin I - vasoconstrictor }
     Inc(iDrug) ;
     Drugs[iDrug] := TDrug.Create(  'Renal', 'Ren. Nv.' ) ;
     Drugs[iDrug].OnRate := FastOn ;
     Drugs[iDrug].RemovalRate := FastOff ;
     SetAgonistPotency( Drugs[iDrug].Angt1R, 2E-4 ) ;
     iRenalNerve := iDrug ;

     { Vascular nerve stimulation acting on alpha-1 adrenoceptors }
     Inc(iDrug) ;
     Drugs[iDrug] := TDrug.Create(  'Alpha1', '???' ) ;
     Drugs[iDrug].OnRate := FastOn ;
     Drugs[iDrug].RemovalRate := FastOff*2.0 ;
     SetAgonistPotency( Drugs[iDrug].Alpha1AdR, 1E-2 ) ;
     iAlpha1AdrNerves := iDrug ;

     { Nerve stimulation acting on beta-1 adrenoceptors in heart}
     Inc(iDrug) ;
     Drugs[iDrug] := TDrug.Create(  'Beta1', '???' ) ;
     Drugs[iDrug].OnRate := FastOn ;
     Drugs[iDrug].RemovalRate := FastOff*2.0 ;
     SetAgonistPotency( Drugs[iDrug].Beta1AdR, 1E-2 ) ;
     iBeta1AdrNerves := iDrug ;

     { Chart recorder traces }

     { Blood pressure }
     Channel[ChABP].ADCName := 'ABP' ;
     Channel[ChABP].ADCUnits := 'mmHg' ;
     Channel[ChABP].yMin := 0. ;
     Channel[ChABP].yMax := 200.0 ;
     Channel[ChABP].yCal := 20.0 ;
     Channel[ChABP].color := clBlue ;
     Channel[ChABP].InUse := True ;

     { Left ventricular pressure }
     Channel[ChLVP].ADCName := 'LVP' ;
     Channel[ChLVP].ADCUnits := 'mmHg' ;
     Channel[ChLVP].yMin := 0. ;
     Channel[ChLVP].yMax := 200.0 ;
     Channel[ChLVP].yCal := 20.0 ;
     Channel[ChLVP].color := clBlue ;
     Channel[ChLVP].InUse := True ;

     { Venous Pressure }
     Channel[ChCVP].ADCName := 'VBP' ;
     Channel[ChCVP].ADCUnits := 'mmHg' ;
     Channel[ChCVP].yMin := 0. ;
     Channel[ChCVP].yMax := 20.0 ;
     Channel[ChCVP].yCal := 2.0 ;
     Channel[ChCVP].color := clBlue ;
     Channel[ChCVP].InUse := True ;

     { Cardiac contractile force (dLVP/dt)/LVP }
     Channel[ChHCF].ADCName := 'HF' ;
     Channel[ChHCF].ADCUnits := ' ' ;
     Channel[ChHCF].yMin := 0.0 ;
     Channel[ChHCF].yMax := 20.0 ;
     Channel[ChHCF].yCal := 2.0 ;
     Channel[ChHCF].color := clBlue ;
     Channel[ChHCF].InUse := True ;

     { Heart rate }
     Channel[ChHR].ADCName := 'HR' ;
     Channel[ChHR].ADCUnits := 'BPM' ;
     Channel[ChHR].yMin := -10. ;
     Channel[ChHR].yMax := 800.0 ;
     Channel[ChHR].yCal := 100.0 ;
     Channel[ChHR].color := clBlue ;
     Channel[ChHR].InUse := True ;

     Heart.Elastance := 1./{75.} 30.0 ;
     Heart.Volume0 := 5. ;
     Heart.Volume := 10. ;
     Heart.Conductance := 2500. ;
     Heart.NextBeat := 0.0 ;
     Heart.Rate := 400.0 ;

     Art.Conductance := 0.05 ;
     Art.Elastance := 1./0.8;
     Art.Volume0 := 100.0 ;
     Art.Volume := 150.0 ;

     Ven.Conductance := 5000.0 ;
     Ven.Elastance := 1./ 30.0 ;
     Ven.Volume0 := 300. ;
     Ven.Volume := 600. ;


     t.Step := 0.125E-3;//0.125E-3 ;
     t.time := 0. ;
     t.next := -1.0 ;

     BufPointer := -1 ;
     EndOfBuf := ((High(Buf) + 1 ) div NumChannels) - 1;
     FirstQuarter := ((EndOfBuf+1) div 4) -1;
     LastQuarter := EndofBuf - FirstQuarter  ;
     ChartWidth := t.Step*High(Buf) / NumChannels ;
     for ch := 0 to ChMarker-1 do begin
         Channel[ch].xMin := 0 ;
         Channel[ch].xMax := EndOfBuf ;
         Channel[ch].Value := 0. ;
         end ;

     Marker.Index := None ;
     Marker.Value := 0. ;
     Marker.Units := 0. ;
     MarkerUnits[mgUnits] := 'mg/kg' ;
     MarkerUnits[ugUnits] := 'ug/kg' ;
     MarkerUnits[NoUnits] := '' ;

     EndOfFileBuf := High(FileBuf) ;
     FileBufPointer := 0 ;
     Dead := False ;
     Dying := 0 ;
     Fibrillation := 0.0 ;
     InitializeDisplay ;
     State := Idle ;
     bStart.Enabled := True ;
     bStop.Enabled := False ;
     sbRecord.Enabled := False ;
     end ;


procedure TMainForm.CalculateTrace ;
{ -------------------------------------------
  Calculate next step of simulated BP and HR
  ------------------------------------------}
var
   x,sum : single ;
   i,ch,j : Integer ;
   Num,Denom,HeartRate,BasalRate,s : single ;
   PotencyShift,TMid,YMax,YMin : single ;
begin

     if t.time >= t.next then begin

        { Ensure resting levels of angiotensin in circulation }
        Drugs[iRenalNerve].Dose := MaxFlt([Drugs[iRenalNerve].Dose,
                                           Drugs[iRenalNerve].Angt1R.Potency*0.25]) ;

        { Nicotinic (ganglion) cholinoceptor activation }
        for i := 0 to High(Drugs) do if Drugs[i] <> Nil then
            NicChR := ReceptorActivation(i,Drugs[i].Dose,Drugs[i].NicChR,
                      Num,Denom,1.0 ) ;

        { Effects of sympathetic nerve and vagal baroreceptor feedback
          in normal UNPITHED rat }
        if rbNormalRat.checked then begin

           { Basal sympathetic nerve stimulation of blood vessels }
           Drugs[iAlpha1AdrNerves].Dose := Drugs[iAlpha1AdrNerves].Alpha1Adr.Potency*0.4 ;
           Drugs[iBeta1AdrNerves].Dose := Drugs[iBeta1AdrNerves].Beta1Adr.Potency*0.2 ;

           { ** Baroreceptor feedback loops (in normal rat only) ** }
           Drugs[iVagusNerve].Dose := MaxFlt( [Drugs[iVagusNerve].Dose,
                                               Drugs[iVagusNerve].VagChR.Potency
                                     * (5.0 / (1.
                                       + exp(-(Art.MeanPressure-130.0)/8.0)))
                                     ]) ;

           end ;

     { Update drugs in circulation }
     for i := 0 to High(Drugs) do if Drugs[i] <> Nil then begin
          Drugs[i].Dose := Drugs[i].Dose
                        + Drugs[i].OnRate*(Drugs[i].DoseInjected - Drugs[i].Dose)
                        - (Drugs[i].Dose*Drugs[i].RemovalRate) ;
          Drugs[i].Dose := MaxFlt( [Drugs[i].Dose, 0. ] ) ;
          Drugs[i].DoseInjected := MaxFlt( [Drugs[i].DoseInjected -
                                   Drugs[i].DoseInjected*Drugs[i].RemovalRate, 0. ] ) ;
          end ;


     { Muscarinic cholinoceptor activation }
     for i := 0 to High(Drugs) do if Drugs[i] <> Nil then
         MusChR := ReceptorActivation(i,Drugs[i].Dose,Drugs[i].MusChR,
                   Num,Denom,1.0 ) ;

     { Vagally stimulated muscarinic cholinoceptor activation }
     for i := 0 to High(Drugs) do if Drugs[i] <> Nil then
         VagChR := ReceptorActivation(i,Drugs[i].Dose,Drugs[i].VagChR,
                   Num,Denom,1.0 ) ;

     { Phosphodiesterase inhibition }
     for i := 0 to High(Drugs) do if Drugs[i] <> Nil then
         PDE := ReceptorActivation(i,Drugs[i].Dose,Drugs[i].PDE,
                                   Num,Denom,1.0 ) ;

     { Alpha1-adrenoceptor activation }
     for i := 0 to High(Drugs) do if Drugs[i] <> Nil then
         Alpha1AdR := ReceptorActivation(i,Drugs[i].Dose,Drugs[i].Alpha1AdR,
                     Num,Denom,1.0 ) ;

     { Alpha2-adrenoceptor activation }
     for i := 0 to High(Drugs) do if Drugs[i] <> Nil then
         Alpha2AdR := ReceptorActivation(i,Drugs[i].Dose,Drugs[i].Alpha2AdR,
                     Num,Denom,1.0 ) ;


     { Beta1-adrenoceptor activation }
     PotencyShift := 1.0 - PDE*0.5 ;
     for i := 0 to High(Drugs) do if Drugs[i] <> Nil then
         Beta1AdR := ReceptorActivation(i,Drugs[i].Dose,Drugs[i].Beta1AdR,
                     Num,Denom,PotencyShift ) ;

     { Beta2-adrenoceptor activation }
     PotencyShift := 1.0 - PDE*0.5 ;
     for i := 0 to High(Drugs) do if Drugs[i] <> Nil then
         Beta2AdR := ReceptorActivation(i,Drugs[i].Dose,Drugs[i].Beta2AdR,
                     Num,Denom,PotencyShift ) ;

     { Heart muscle calcium channel activation }
     for i := 0 to High(Drugs) do if Drugs[i] <> Nil then
         HMCaChannels := ReceptorActivation(i,Drugs[i].Dose,Drugs[i].HMCaChannel,
                                            Num,Denom,1.0 ) ;

     { Digoxin effect on heart muscle }
     for i := 0 to High(Drugs) do if Drugs[i] <> Nil then
         DigR := ReceptorActivation(i,Drugs[i].Dose,Drugs[i].DigR,
                 Num,Denom,1.0 ) ;

     { Smooth muscle calcium channel activation }
     for i := 0 to High(Drugs) do if Drugs[i] <> Nil then
         SMCaChannels := ReceptorActivation(i,Drugs[i].Dose,Drugs[i].SMCaChannel,
                                            Num,Denom,1.0 ) ;

     { Adenosine receptor activation }
     for i := 0 to High(Drugs) do if Drugs[i] <> Nil then
         AdenR := ReceptorActivation(i,Drugs[i].Dose,Drugs[i].AdenR,
                  Num,Denom,1.0 ) ;

     { K channel activation }
     for i := 0 to High(Drugs) do if Drugs[i] <> Nil then
         KChannels := ReceptorActivation(i,Drugs[i].Dose,Drugs[i].KChannel,
                      Num,Denom,1.0 ) ;

     { Nitric oxide synthase }
     for i := 0 to High(Drugs) do if Drugs[i] <> Nil then
         NOS := ReceptorActivation(i,Drugs[i].Dose,Drugs[i].NOS,
                Num,Denom,1.0 ) ;

     { Nitric oxide activation }
     { Note. Intrinsic generation of nitric oxide means that a certain
       degree of vasodilation exists in the absence of drugs }
     for i := 0 to High(Drugs) do if Drugs[i] <> Nil then
         NOX := ReceptorActivation(i,Drugs[i].Dose,Drugs[i].NOX,
                Num,Denom,1.0 ) ;

     { Angiotensin I activation }
     for i := 0 to High(Drugs) do if Drugs[i] <> Nil then
         Angt1R := ReceptorActivation(i,Drugs[i].Dose,Drugs[i].Angt1R,
                   Num,Denom,1.0 ) ;


     { Angiotensin converting enzyme activity}
     for i := 0 to High(Drugs) do if Drugs[i] <> Nil then
         ACE := ReceptorActivation(i,Drugs[i].Dose,Drugs[i].ACE,
                Num,Denom,1.0 ) ;


     { Angiotensin II produce from Angiotensin I by angiotensin converting enzyme }
     Drugs[iAngioTensin2ACE].Dose := Drugs[iAngioTensin2ACE].Angt2R.Potency*5.0
                                  *( 1.0 - ACE )
                                  * (Angt1R / ( 1.0 + Angt1R )) ;


     { Angiotensin II activation }
     for i := 0 to High(Drugs) do if Drugs[i] <> Nil then
         Angt2R := ReceptorActivation(i,Drugs[i].Dose,Drugs[i].Angt2R,
                                       Num,Denom,1.0 ) ;

     { Bradykinin receptor activation }
     for i := 0 to High(Drugs) do if Drugs[i] <> Nil then
         BradR := ReceptorActivation(i,Drugs[i].Dose,Drugs[i].BradR,
                                       Num,Denom,1.0 ) ;

     t.next := t.time + 0.005 ;

     end ;

     Art.Conductance := 5.0*(1.0
                        + (2.5*MusChR*(1.0-NOS))  { Muscarinic receptors VD }
                        + (2.25*Beta2AdR)          { Beta-2 adrenoceptor VD }
                        + (2.5*AdenR)             { Adenosine receptors VD }
                        + 2.0*NOX                 { Nitric oxide VD }
                        + 2.0*PDE                 { Phosphodiesterase inhibition VD }
                        + 0.95*SMCaChannels       { Ca channel block VD }
                        + 0.95*KChannels          { K channel opening VD }
                        + BradR                   { Bradykinin VD }
                        - 0.6*NOS                 { Inhib. of NO synthase VC }
                        - 0.9*Alpha1ADR          { Alpha-1 adrenoceptor VD }
                       { - 0.9*NicChR }            { Nicotinic VC }
                        - 0.9*Angt2R             { Angiotension II VC }

                        );
     Art.Conductance := MaxFlt([Art.Conductance,0.25]) ;

     { Arterial elastance increased by vasoconstrictors
       Results in increased pulse pressure }
     Art.Elastance := (1./0.8) * (1.0
                      + 0.2*Alpha1Adr
                      );

     { Venous elastance : decreased by certain vasodilators
       Decreased elastance = increased venous capacity }
     Ven.Elastance := (1./30.0) * ( 1.0 - 0.7*MinFlt([1.0,
                      NOX
                      + SMCaCHannels
                      - Alpha1AdR
                      ]) ) ;


     Heart.InitialisePressureRange ;
     Art.InitialisePressureRange ;
     Ven.InitialisePressureRange ;
     Con.InitialisePressureRange ;

     YMax := -1E38 ;
     YMin := 1E38 ;

     for i := 1 to 80 do begin

         { Set heart rate and force for next beat}
         if t.Time >= Heart.NextBeat then begin

            Art.MeanPressure := (Art.MaxPressure - Art.MinPressure)*0.33
                                + Art.MinPressure ;
            Art.MinPressure := 300.0 ;
            Art.MaxPressure := 0.0 ;

            { Heart rate }
            Heart.Rate := 1. + 350.0*(1.0
                                        - 0.7*VagChR
                                        - MusChR
                                        - AdenR
                                        + Beta1AdR
                                        - HMCaChannels
                                        + 1.0*PDE ) ;
            Heart.Rate := MaxFlt( [Heart.Rate, 1.] ) ;

            { Contractile force }
            Heart.Force :=  8.0 * (1.0
                           - 0.95*MusChR
                           - 0.95*AdenR
                           - 0.6*KChannels
                           + 1.5*Beta1AdR
                           + DigR
                           + PDE )
                           * ( 1.0 - HMCaChannels )
                           * (1./(1. + Heart.Volume0/Heart.Volume)) ;

            { Duration of contraction (systole) }
            Heart.Time := (12.0 / 400.0) ;
            if Heart.Time >= (12.0/Heart.Rate) then Heart.Time := 12.0/Heart.Rate ;
            Heart.TSystole := Heart.Time ;

            { Time for next beat }
            Heart.NextBeat := t.Time + (60.0/Heart.Rate) ;

            end ;

         if Heart.Time > 0.0 then begin

           { Compute cardiac contractile force }
           TMid := t.step*Round((Heart.TSystole*0.5)/t.step) ;

           x := (Heart.Time-TMid)/(TMid*0.33) ;
       {    Heart.Elastance := (sin(3.141*(Heart.Time/Heart.TSystole))
                              * Heart.Force )
                              + Ven.Elastance*4.0 ;}

           Heart.Elastance := (exp(-x*x)
                              * Heart.Force )
                              + Ven.Elastance*4.0 ;

           Heart.Time := Heart.Time - t.Step ;
           end ;

         if DigR > 0.95 then begin
            Heart.Elastance := Heart.Force*AddNoise(0.5)*0.25 ;
            Fibrillation := Fibrillation + t.step ;
            Heart.Rate := 300.0*AddNoise(0.5) ;
            Heart.Pressure := 50.0*AddNoise(1.0 ) ;
            end
         else Heart.Pressure := Pressure(Heart) ;

         Con.Pressure := Heart.Elastance ;
         YMax := Max(Ymax,Heart.Elastance) ;
         YMin := Min(Ymin,Heart.Elastance) ;

         { Arterial valve }
         if (Heart.Pressure >= Art.Pressure)
            and (Fibrillation <= 0.0) then begin

            Heart.Flow := (Heart.Pressure - Art.Pressure)*Heart.Conductance ;

            Art.Volume := Art.Volume + Heart.Flow*t.step ;
            Heart.Volume := Heart.Volume - Heart.Flow*t.step ;
            end ;

         Art.Pressure := Pressure(Art) ;

         { Find Systolic/Diastolic pressures }
         Art.MaxPressure := MaxFlt([Art.MaxPressure,Art.Pressure]) ;
         Art.MinPressure := MinFlt([Art.MinPressure,Art.Pressure]) ;

         Art.Flow := (Art.Pressure - Ven.Pressure)*Art.Conductance ;
         Ven.Volume := Ven.Volume + Art.Flow*t.step ;
         Art.Volume := Art.Volume - Art.Flow*t.step ;

         Ven.Pressure := Pressure(Ven) ;
         { Venous system -> heart valve }
         if (Ven.Pressure >= Heart.Pressure)
            and (Fibrillation <= 0.0)then begin
            Ven.Flow := (Ven.Pressure - Heart.Pressure)*Ven.Conductance ;
            Heart.Volume := Heart.Volume + Ven.Flow*t.step ;
            Ven.Volume := Ven.Volume - Ven.Flow*t.step ;
            end ;

         t.time := t.time + t.step ;

         Heart.CalculatePressureRange( t.time ) ;
         Art.CalculatePressureRange( t.time ) ;
         Ven.CalculatePressureRange( t.time ) ;
         Con.CalculatePressureRange( t.time ) ;

         end ;


     { The rat dies if the B.P. falls too low for too long }
     if not Dead  then begin
        if Art.Pressure < 20. then Inc(Dying)
                               else Dying := 0 ;
        if Dying = 500 then begin
           j := pbDisplay.font.size ;
           pbDisplay.canvas.font.size := 32 ;
           pbDisplay.canvas.font.Color := clRed ;
           pbDisplay.canvas.TextOut( pbDisplay.Width div 4,
                                     pbDisplay.Height div 2,
                                     'Your rat has just died!!!' ) ;
           pbDisplay.canvas.font.size := j ;
           Dead := True ;
           end ;
        end
     else begin
        end ;

     Inc(BufPointer) ;
     j := BufPointer*NumChannels ;
     Buf[j+chLVP] := Heart.GetLeadingPressure ;
     Buf[j+chABP] := Art.GetLeadingPressure ;
     Buf[j+ChCVP] := Ven.GetLeadingPressure ;
     Buf[j+ChHCF] := Con.GetLeadingPressure ;

     Buf[j+chHR] := Heart.Rate*AddNoise(0.05) ;
     Buf[j+chMarker] := Marker.Index ;
     Marker.Index := -1. ; ;
     Buf[j+chMarkerValue] := Marker.Value ;
     Buf[j+ChMarkerUnits] := Marker.Units ;

     Inc(BufPointer) ;
     j := BufPointer*NumChannels ;
     Buf[j+chLVP] := Heart.GetTrailingPressure ;
     Buf[j+chABP] := Art.GetTrailingPressure ;
     Buf[j+ChCVP] := Ven.GetTrailingPressure ;
     Buf[j+ChHCF] := Con.GetTrailingPressure ;
     Buf[j+chHR] := Heart.Rate  ;
     Buf[j+chMarker] := Marker.Index ;
     Marker.Index := -1. ;
     Buf[j+chMarkerValue] := Marker.Value ;
     Buf[j+ChMarkerUnits] := Marker.Units ;
     end ;


procedure TElement.CalculatePressureRange( t : single ) ;
begin
     if Pressure <= PressureLo then begin
        PressureLo := Pressure ;
        TLo := t ;
        end ;

     if Pressure >= PressureHi then begin
        PressureHi := Pressure ;
        THi := t ;
        end ;
     end ;

function TElement.GetLeadingPressure : single ;
begin
     if TLo <= THi then Result := PressureLo
                   else Result := PressureHi ;
     end ;

function TElement.GetTrailingPressure : single ;
begin
     if THi >= TLo then Result := PressureHi
                   else Result := PressureLo ;
     end ;

procedure TElement.InitialisePressureRange ;
begin
     PressureHi := -1E38 ;
     PressureLo := 1E38 ;
     end ;


function FindDrug(
         DrugList : Array of TDrug ;
         DrugName : string ) : Integer ;
{ ---------------------------------------------------------------------
  Return the array index of the drug in DrugList with the name DrugName
  ---------------------------------------------------------------------}
var
   Found : Boolean ;
   i : Integer ;
   Temp : string ;
begin

     // Remove & from name
     Temp := DrugName ;
     DrugName := '' ;
     for i:= 1 to Length(Temp) do
         if Temp[i] <> '&' then DrugName := DrugName + Temp[i] ;

     i := 0 ;
     Found := False ;
     while (not Found) and (i <= High(DrugList)) do begin
         if Pos(DrugName,DrugList[i].Name) > 0 then Found := True
                                               else Inc(i) ;
         end ;
     if Found then Result := i
              else begin
                   Result := -1 ;
                   MessageDlg( DrugName + ' not available.',mtWarning,[mbOK], 0 ) ;
                   end ;
     end ;


procedure TMainForm.TimerTimer(Sender: TObject);
{ ----------------------------------------------------
  Timed event scheduler ... does simulation time steps
  ----------------------------------------------------}
var
   xPix,yPix,ch,j,jTo,jFrom0,jFrom1,nw : LongInt ;
begin
     case State of

          { Create simulated cat experiment traces }
          Recording : Begin

             { Calculate next set of simulation values }
             CalculateTrace ;

             { Plot results on chart traces }
             xPix := Trunc( (BufPointer - Channel[0].xMin)*Channel[0].xScale )
                     + Channel[0].Left ;

             for ch := 0 to chMarker do if Channel[ch].InUse then begin
                 j := (BufPointer-1)*NumChannels + ch ;
                 yPix := Channel[ch].Bottom -
                         Trunc( (Buf[j]-Channel[ch].yMin)*Channel[ch].yScale ) ;
                 pbDisplay.canvas.pen.color := Channel[ch].color ;
                 { If no information about previous position ... used current }
                 if OldPos[ch].x = 0 then OldPos[ch] := Point( xPix, yPix ) ;
                 pbDisplay.canvas.MoveTo( OldPos[ch].x, OldPos[ch].y ) ;

                 pbDisplay.canvas.LineTo( xPix, yPix ) ;

                 j := (BufPointer)*NumChannels + ch ;
                 yPix := Channel[ch].Bottom -
                         Trunc( (Buf[j]-Channel[ch].yMin)*Channel[ch].yScale ) ;
                 pbDisplay.canvas.LineTo( xPix, yPix ) ;

                 OldPos[ch] := Point( xPix, yPix ) ;
                 end ;

             { Display marker at bottom of screen }
             j := (BufPointer-1)*NumChannels  ;
             if Buf[j+chMarker] <> None then begin
                yPix := pbDisplay.Height - pbDisplay.canvas.TextHeight('X') ;
                { Draw tic indicating point of drug application }
                pbDisplay.canvas.MoveTo( xPix, yPix ) ;
                pbDisplay.canvas.LineTo( xPix, yPix + pbDisplay.canvas.TextHeight('X')) ;
                if Buf[j+ChMarkerValue] <> 0.0 then
                     pbDisplay.canvas.TextOut( xPix + 2,yPix,
                                  Drugs[Trunc(Buf[j+ChMarker])].ShortName +
                                  format(' %.3g %s',[Buf[j+ChMarkerValue],
                                  MarkerUnits[Trunc(Buf[j+ChMarkerUnits])]])
                                   )
                else
                     pbDisplay.canvas.TextOut( xPix + 2,yPix,
                                  Drugs[Trunc(Buf[j+ChMarker])].ShortName ) ;

                end ;

             { Write results to file }
             j := (BufPointer-1)*NumChannels ;
             for ch := 0 to ((2*NumChannels)-1) do begin
                 FileBuf[FileBufPointer] := Buf[j+ch] ;
                 Inc(FileBufPointer) ;
                 end ;
             if FileBufPointer > EndofFileBuf then begin
                nw := FileWrite( FileHandle, FileBuf, Sizeof(FileBuf) ) ;
                FileBufPointer := 0 ;
                end ;

             t.time := t.time + t.Step ;

             { If at end of display ... refresh display retaining last 25% of traces }
             if BufPointer >= EndofBuf then begin
                jTo := 0 ;
                jFrom0 := LastQuarter*NumChannels ;
                jFrom1 := (EndOfBuf+1)*NumChannels -1  ;
                for j := jFrom0 to jFrom1 do begin
                    Buf[jTo] := Buf[j] ;
                    Inc(jTo) ;
                    end ;
                BufPointer := FirstQuarter ;
                InitializeDisplay ;
                end ;
             end ;

          Replay : begin
                 { Replay recorded traces }
                 FilePointer := SizeOf(FileBuf)  ;
                 FilePointer := FilePointer*sbRecord.position ;
                 nw := FileSeek( FileHandle, FilePointer, 0 ) ;
                 nw := FileRead( FileHandle,Buf,Sizeof(Buf)) ;
                 BufPointer := ((nw) div (4*NumChannels)) - 1 ;
                 InitializeDisplay ;
                 State := Idle ;
                 end ;
          end ;
     end;


procedure TMainForm.InitializeDisplay ;
{ ----------------------------
  Initialise a display window
  ---------------------------}
var
   Height,ch,cTop,xPix,yPix,yPixTop,yPixBottom,i,j,n : LongInt ;
   x,y,xStep : single ;
   Lab : string ;
begin

     { Erase display }
     pbDisplay.canvas.brush.color := clWhite ;
     pbDisplay.canvas.fillrect(pbDisplay.canvas.ClipRect);

     { Determine number of channels in use }
     n := 0 ;
     for ch := 0 to ChMarker-1 do begin
         if (Channel[Ch].InUse) then Inc(n) ;
         end ;
     if n <= 0 then n := 1 ;
     Height := (pbDisplay.Height - 2*pbDisplay.canvas.TextHeight('X') ) div n ;

     { Display Min./Max. range and channel name }

     for ch := 0 to chMarker-1 do begin
         if Channel[ch].InUse then begin
            { Maximum value }
            Channel[ch].Left := pbDisplay.Canvas.TextWidth('X')*6 ;
            Lab := format('%d',[Trunc(Channel[ch].yMax)]) ;
            pbDisplay.canvas.TextOut( Channel[ch].Left - pbDisplay.Canvas.TextWidth(Lab)
                                      - pbDisplay.Canvas.TextWidth('X') div 2,
                                      Channel[ch].Top,
                                      Lab) ;
            { Minimum value }
            Lab := '0' ;
            pbDisplay.canvas.TextOut( Channel[ch].Left - pbDisplay.Canvas.TextWidth(Lab)
                                      - pbDisplay.Canvas.TextWidth('X') div 2,
                                      Channel[ch].Bottom - pbDisplay.Canvas.TextHeight('X'),
                                      Lab ) ;

            { Channel name }
            Lab := Channel[ch].ADCName ;
            pbDisplay.canvas.font.color := Channel[ch].color ;
            pbDisplay.Canvas.TextOut( Channel[ch].Left - pbDisplay.Canvas.TextWidth(Lab)
                                      - pbDisplay.Canvas.TextWidth('X') div 2,
                                      Channel[ch].Top + pbDisplay.Canvas.TextHeight('X'),
                                      Lab ) ;
            pbDisplay.canvas.font.color := clBlack ;
            end ;
         end ;

     { Define display area for each channel }
     cTop := pbDisplay.canvas.TextHeight('X') ;
     for i := 0 to ChMarker-1 do begin
         if Channel[i].InUse then begin
            //Channel[i].Left := 0 ;
            Channel[i].Right := pbDisplay.width - 5 ;
            Channel[i].Top := cTop ;
            Channel[i].Bottom := Channel[i].Top + Height
                                  - (pbDisplay.canvas.TextHeight('X') div 2);
            Channel[i].xMin := Channel[0].xMin ;
            Channel[i].xMax := Channel[0].xMax ;
            Channel[i].xScale := (Channel[i].Right - Channel[i].Left) /
                            (Channel[i].xMax - Channel[i].xMin ) ;
            Channel[i].yScale := (Channel[i].Bottom - Channel[i].Top) /
                            (Channel[i].yMax - Channel[i].yMin ) ;
            cTop := cTop + Height ;
            end ;
         end ;

     { Draw grid }
     for ch := 0 to chMarker-1 do begin
         if Channel[ch].InUse  then begin
            { Grid colour }
            pbDisplay.canvas.pen.color := clGray ;
            { Horizontal grid }
            y := 0. ;
            pbDisplay.Canvas.Pen.Width := 2 ;
            while y <= (Channel[ch].yMax ) do begin
                  yPix := Channel[ch].bottom -
                          Trunc( (y-Channel[ch].yMin)*Channel[ch].yScale ) ;
                  pbDisplay.canvas.Polyline( [Point(Channel[ch].Left, yPix),
                                              Point(Channel[ch].Right, yPix) ]) ;
                  y := y + Channel[ch].yCal ;
                  pbDisplay.Canvas.Pen.Width := 1 ;
                  end ;

            { Vertical grid lines }
            x := (Channel[0].xMax - Channel[0].xMin) / 10. ;
            yPixTop := Channel[ch].bottom -
                          Trunc((Channel[ch].yMax -Channel[ch].yMin)
                          *Channel[ch].yScale ) ;
            yPixBottom := Channel[ch].bottom -
                          Trunc((-Channel[ch].yMin)*Channel[ch].yScale ) ;
            xStep := x ;
            while x < Channel[0].xMax do begin
                  xPix := Trunc( (x - Channel[0].xMin)*Channel[0].xScale )
                          + Channel[0].Left ;
                  pbDisplay.canvas.Polyline( [Point(xPix, yPixTop),
                                              Point(xPix, yPixBottom)]) ;
                  x := x + xStep ;
                  end ;

            end ;
         end ;

     pbDisplay.canvas.pen.style := psSolid ;

     { Draw channels }
     for ch := 0 to chMarker-1 do begin
         if Channel[ch].InUse then begin
            pbDisplay.canvas.pen.color := Channel[ch].color ;
            for i := 0 to BufPointer do begin
                if (i mod 2) = 0 then begin
                   xPix := Trunc( (i - Channel[0].xMin)*Channel[0].xScale )
                           + Channel[0].Left ;
                   end ;
                j := i*NumChannels + ch ;
                yPix := Channel[ch].Bottom -
                        Trunc( (Buf[j]-Channel[ch].yMin)*Channel[ch].yScale ) ;
                if i = 0 then pbDisplay.canvas.MoveTo( xPix, yPix )
                         else pbDisplay.canvas.LineTo( xPix, yPix ) ;
                end ;
            if BufPointer >= 0 then OldPos[ch] := Point(xPix,yPix)
                               else OldPos[ch] := Point( 0,0 ) ;
            end ;
         end ;

     { Display markers }
     for i := 0 to Bufpointer do begin
         j := i*NumChannels  ;
         if Buf[j + chMarker] <> None then begin
            xPix := Trunc( (i - Channel[0].xMin)*Channel[0].xScale )
                    + Channel[0].Left ;
            yPix := pbDisplay.Height - pbDisplay.canvas.TextHeight('X') ;
            { Draw tic indicating point of drug application }
            pbDisplay.canvas.MoveTo( xPix, yPix ) ;
            pbDisplay.canvas.LineTo( xPix, yPix + pbDisplay.canvas.TextHeight('X')) ;

            if Buf[j+ChMarkerValue] <> 0.0 then
               pbDisplay.canvas.TextOut( xPix+2,yPix,
                                      Drugs[Trunc(Buf[j+ChMarker])].ShortName +
                                      format(' %.3g %s',[Buf[j+ChMarkerValue],
                                      MarkerUnits[Trunc(Buf[j+ChMarkerUnits])]]) )
            else
               pbDisplay.canvas.TextOut( xPix+2,yPix,
                                      Drugs[Trunc(Buf[j+ChMarker])].ShortName ) ;
            end ;
         end ;

     Initialized := True ;
     end ;


function Pressure( Element : TElement ) : single ;
var
   P : Single ;
begin
     P := (Element.Volume - Element.Volume0)*Element.Elastance ;
     if P < 0.0 then P := 0.0 ;
     Result := P ;
     end ;


procedure TMainForm.PrintTraces ;
{ ------------------------------------
  Print hard copy of traces on screen
  -----------------------------------}
var
   LineSpace,ChanHeight,n,CTop,ch,i,j :LongInt ;
   TopMargin,BottomMargin,LeftMargin,RightMargin : LongInt ;
   x,xStep,y : single ;
   xPix,yPix,yPixTop,yPixBottom : LongInt ;
   PrChan : Array[0..ChannelLimit] of TChannel ;
   Lab : string ;
begin
     SetPageFrm.ShowModal ;
     if SetPageFrm.ModalResult = mrOK then begin

        screen.cursor := crHourGlass ;
        Printer.BeginDoc ;

        TopMargin := PrinterCMToPixels('V',
                     ExtractFloat(SetPageFrm.edTopMargin.text,5.0)) ;
        BottomMargin := PrinterCMToPixels('V',
                        ExtractFloat(SetPageFrm.edBottomMargin.text,5.0)) ;
        LeftMargin := PrinterCMToPixels('H',
                      ExtractFloat(SetPageFrm.edLeftMargin.text,5.0)) ;
        RightMargin := PrinterCMToPixels('H',
                       ExtractFloat(SetPageFrm.edRightMargin.text,5.0)) ;

        { Set printer typeface and size }
        Printer.canvas.font.name := 'Arial'  ;
        Printer.canvas.font.Size := 10 ;
        LineSpace := printer.canvas.textheight( 'X' ) ;
        { Print user name at top of page }
        Printer.canvas.font.Size := 10 ;
        LineSpace := printer.canvas.TextHeight('X') ;
        xPix := PrinterCMToPixels('H',2.5) ;
        yPix := PrinterCMToPixels('V',1.0) ;
        Printer.Canvas.TextOut( xPix,
                                yPix,
                                'User: ' + AboutFrm.edName.text
                                ) ;
        yPix := yPix + LineSpace ;
        Printer.Canvas.TextOut( xPix,
                                yPix,
                                'File: ' + FileName) ;
        yPix := yPix + LineSpace ;
        if rbPithedrat.Checked then
           Printer.Canvas.TextOut( xPix,yPix,'Experiment : Pithed')
        else
           Printer.Canvas.TextOut( xPix,yPix,'Experiment : Normal') ;



        { Set up printer page scaling }
        n := 0 ;
        for ch := 0 to ChMarker-1 do if (Channel[ch].InUse)  then Inc(n) ;
        if n < 1 then n := 1 ;

        { Set position on page and scaling factor for each channel }
        ChanHeight := ((Printer.PageHeight - TopMargin - BottomMargin) div n) ;

        CTop := TopMargin ;
        for ch := 0 to ChMarker-1 do begin
            PrChan[ch] := Channel[ch] ;
            if PrChan[ch].InUse then begin
               PrChan[ch].Left := LeftMargin ;
               PrChan[ch].Right := Printer.PageWidth - RightMargin ;
               PrChan[ch].Top := CTop ;
               PrChan[ch].Bottom := PrChan[ch].Top + ChanHeight
                                    - PrinterCMToPixels('V',0.5) ;
               PrChan[ch].xScale := (PrChan[ch].Right - PrChan[ch].Left) /
                                    (PrChan[ch].xMax  - PrChan[ch].xMin ) ;
               PrChan[ch].yScale := (PrChan[ch].Bottom - PrChan[ch].Top) /
                                    (PrChan[ch].yMax   - PrChan[ch].yMin ) ;
               CTop := CTop + ChanHeight ;
               { Copy channel settings to Marker channel to ensure that
                 there is a correct set of X axis scaling factors in it
                 (any channel will do) 30/10/97 }
               PrChan[chMarker] := PrChan[ch] ;
               end ;
            end ;

        { Display Min./Max. range and channel name }
        Printer.canvas.font.Size := 10 ;
        for ch := 0 to chMarker-1 do if PrChan[ch].InUse  then begin
            { Maximum value }
            PrChan[ch].Left := PrChan[ch].Left + printer.Canvas.TextWidth('X')*4 ;
            PrChan[ch].xScale := (PrChan[ch].Right - PrChan[ch].Left) /
                                 (PrChan[ch].xMax  - PrChan[ch].xMin ) ;

            Lab := format('%d',[Trunc(PrChan[ch].yMax)]) ;
            printer.canvas.TextOut( PrChan[ch].Left - printer.Canvas.TextWidth(Lab)
                                   - printer.Canvas.TextWidth('X') div 2,
                                   PrChan[ch].Top,
                                   Lab) ;
            { Minimum value }
            Lab := '0' ;
            printer.canvas.TextOut( PrChan[ch].Left - printer.Canvas.TextWidth(Lab)
                                   - printer.Canvas.TextWidth('X') div 2,
                                   PrChan[ch].Bottom - printer.Canvas.TextHeight('X'),
                                   Lab ) ;

            { PrChan name }
            Lab := PrChan[ch].ADCName ;
            printer.Canvas.TextOut( PrChan[ch].Left - printer.Canvas.TextWidth(Lab)
                                   - printer.Canvas.TextWidth('X') div 2,
                                   PrChan[ch].Top + printer.Canvas.TextHeight('X'),
                                   Lab ) ;

            end ;


        { Draw grid }
        for ch := 0 to chMarker-1 do if PrChan[ch].InUse  then begin
            { Grid line style }
            Printer.canvas.pen.style := psDot ;

            { Horizontal grid }
            y := 0. ;
            while y <= (PrChan[ch].yMax ) do begin
                  yPix := PrChan[ch].bottom -
                          Trunc( (y-PrChan[ch].yMin)*PrChan[ch].yScale ) ;
                  Printer.canvas.Polyline( [Point(PrChan[ch].Left, yPix),
                                            Point(PrChan[ch].Right, yPix) ]) ;
                  y := y + Channel[ch].yCal ;
                  end ;

            { Vertical grid lines }
            x := (PrChan[ch].xMax - PrChan[ch].xMin) / 10. ;
            yPixTop := PrChan[ch].bottom -
                       Trunc((PrChan[ch].yMax  -PrChan[ch].yMin)
                       *PrChan[ch].yScale ) ;
            yPixBottom := PrChan[ch].bottom -
                          Trunc((-PrChan[ch].yMin)*PrChan[ch].yScale ) ;
            xStep := x ;
            while x < PrChan[ch].xMax do begin
                  xPix := Trunc( (x - PrChan[ch].xMin)*PrChan[ch].xScale )
                          + PrChan[ch].Left ;
                  Printer.canvas.Polyline( [Point(xPix, yPixTop),
                                              Point(xPix, yPixBottom)]) ;
                  x := x + xStep ;
                  end ;
            end ;

        Printer.canvas.pen.style := psSolid ;

        { Draw channels traces}
        for ch := 0 to chMarker-1 do if PrChan[ch].InUse then begin
            for i := 0 to BufPointer do begin
                xPix := Trunc( (i - PrChan[ch].xMin)*PrChan[ch].xScale )
                        + PrChan[ch].Left ;
                j := i*NumChannels + ch ;
                yPix := PrChan[ch].Bottom - Trunc( Buf[j]*PrChan[ch].yScale ) ;
                if i = 0 then Printer.canvas.MoveTo( xPix, yPix )
                         else Printer.canvas.LineTo( xPix, yPix ) ;
                end ;
            end ;

        { Display markers }
        Printer.canvas.font.height := PrinterPointsToPixels(8) ;
        for ch := 0 to chMarker-1 do
            if PrChan[ch].InUse then PrChan[chMarker] := PrChan[ch] ;

        for i := 0 to Bufpointer do begin
            j := i*NumChannels ;
            if Buf[j + chMarker] <> None then begin
               { Calculate point of drug application on trace }
               xPix := Trunc( (i - PrChan[chMarker].xMin)*PrChan[chMarker].xScale )
                       + PrChan[chMarker].Left ;
               yPix := (Printer.PageHeight - BottomMargin) ;
               { Draw tic indicating point of drug application }
               Printer.Canvas.MoveTo( xPix, yPix ) ;
               Printer.Canvas.LineTo( xPix, yPix + Printer.Canvas.TextHeight('X')) ;
               xPix := xPix + (Printer.Canvas.TextWidth('X') div 4) ;
               { Display drug/dose information }
               if Buf[j+ChMarkerValue] <> 0.0 then
                  Printer.canvas.TextOut( xPix ,yPix,
                                          Drugs[Trunc(Buf[j+ChMarker])].ShortName +
                                          format(' %.4g %s',[Buf[j+ChMarkerValue],
                                          MarkerUnits[Trunc(Buf[j+ChMarkerUnits])]]) )
               else
                  Printer.canvas.TextOut( xPix,yPix,
                                    Drugs[Trunc(Buf[j+ChMarker])].ShortName ) ;               end ;
            end ;

        Printer.canvas.font.Size := 8 ;
        LineSpace := printer.canvas.TextHeight('X') ;
        Printer.Canvas.TextOut( PrinterCMToPixels('H',2.5),
                                Printer.PageHeight - PrinterCMToPixels('V',1.0),
                                ProgName + ' ' + DateTimeToStr(Now) ) ;

        Printer.EndDoc ;
        screen.cursor := crDefault ;
        end ;

    end ;



function MaxFlt( const Buf : array of Single ) : Single ;
{ Return the largest value in the array 'Buf' }
var
   i : LongInt ;
   Max : Single ;
begin
     Max:= -1E38 ;
     for i := 0 to High(Buf) do
         if Buf[i] > Max then Max := Buf[i] ;
     Result := Max ;
     end ;

function MinFlt( const Buf : array of Single ) : Single ;
{ Return the largest value in the array 'Buf' }
var
   i : LongInt ;
   Min : Single ;
begin
     Min:= 1E38 ;
     for i := 0 to High(Buf) do
         if Buf[i] < Min then Min := Buf[i] ;
     Result := Min ;
     end ;



function MaxInt( const Buf : array of Integer ) : Integer ;
{ Return the largest value in the array 'Buf' }
var
   i,Max : Integer ;
begin
     Max:= Low(Max) ;
     for i := 0 to High(Buf) do
         if Buf[i] > Max then Max := Buf[i] ;
     Result := Max ;
     end ;


function AddNoise(
         Proportion : single
         ) : single ;
{ -----------------------------------------------
  Create a random scaling factor 1 +/- Proportion
  -----------------------------------------------}
begin
     AddNoise := 1. + ((2.*random)-1. )*Proportion ;
     end ;


Procedure UpdateCirculatingDrug
          ( var Drug : TDrug
          ) ;
{ -------------------------------------------
  Update concentration of drug in circulation
  -------------------------------------------}
begin
     Drug.Dose := Drug.Dose + Drug.OnRate*(Drug.DoseInjected - Drug.Dose)
                            - (Drug.Dose*Drug.RemovalRate);
     Drug.Dose := MaxFlt( [Drug.Dose, 0. ] ) ;
     Drug.DoseInjected := MaxFlt( [Drug.DoseInjected -
                                   Drug.DoseInjected*Drug.RemovalRate, 0. ] ) ;
     end ;


procedure TMainForm.pbDisplayPaint(Sender: TObject);
begin
     InitializeDisplay ;
     end;


procedure TMainForm.FormDestroy(Sender: TObject);

var
   i : Integer ;
begin


     end;

function ExtractFloat ( CBuf : string ; Default : Single ) : extended ;
{ ---------------------------------------------------
  Extract a floating point number from a string which
  may contain additional non-numeric text
  ---------------------------------------}
var
   CNum : string ;
   i : integer ;
begin
     CNum := '' ;
     for i := 1 to length(CBuf) do begin
         if CBuf[i] in ['0'..'9', 'E', 'e', '+', '-', '.', ',' ] then
            CNum := CNum + CBuf[i]
         else CNum := CNum + ' ' ;
         end ;
     try
        if Length(CNum)>0 then ExtractFloat := StrToFloat( CNum )
                          else ExtractFloat := Default ;
     except
        on E : EConvertError do ExtractFloat := Default ;
        end ;
     end ;


procedure TMainForm.mnAdrenalineClick(Sender: TObject);
var
   ix : Integer ;
begin
     { Find drug to be added }
     AddDose.lbDrugName.caption := TMenuItem(Sender).Caption ;
     ix := FindDrug( Drugs, TMenuItem(Sender).Caption ) ;
     { Determine min/max dose range allowed }
     AddDose.MinDose := Drugs[ix].MinDose ;
     AddDose.MaxDose := Drugs[ix].MaxDose ;
     { Let user set dose }


     AddDose.ShowModal ;

     if AddDose.ModalResult = mrOK then begin
        if ix >= 0 then begin
           Drugs[ix].DoseInjected := AddDose.SelectedDose*AddNoise(0.1) ;
           Marker.Index := ix ;
           Marker.Value := AddDose.SelectedDose*AddDose.Scale ;
           if AddDose.Scale <> 1.0 then Marker.Units := ugUnits
                                   else Marker.Units := mgUnits ;
           end ;
        end ;
     end;


procedure TMainForm.FormResize(Sender: TObject);
var
   MinHeight,MinWidth : Integer ;
begin
     MinWidth := ControlGrp.Width + 20 ;
     MinHeight := ControlGrp.Height + 100 ;
     if ClientHeight < MinHeight then ClientHeight := Minheight ;
     if ClientWidth < MinWidth then ClientWidth := MinWidth ;

     Page.Width := ClientWidth - Page.Left - 5 ;
     Page.Height := ClientHeight - Page.Top - 5 ;

     ControlGrp.Top := ChartTab.ClientHeight - ControlGrp.Height - 10 ;
     pbDisplay.Height := ControlGrp.Top - pbDisplay.Top - 10 ;
     pbDisplay.Width := ChartTab.CLientWidth - pbDisplay.Left - 10 ;

     ExpImage.Width := Max(Round(PictureTab.ClientWidth*0.9),465) ;
     ExpImage.Height :=  Max(Round(ExpImage.Width*(329.0/465.0)),329) ;
     ExpImage.Left := (PictureTab.ClientWidth - ExpImage.Width) div 2 ;
     ExpImage.Top := (PictureTab.ClientHeight - ExpImage.Height) div 2 ;

     // Ensures update of paintbox size
     Application.ProcessMessages ;

     pbDisplay.Invalidate ;

     end;


procedure TMainForm.bStopClick(Sender: TObject);
var
   nBufs,FileLength : LongInt ;
begin
     State := Replay ;
     FileLength := FileSeek( FileHandle, 0, 2 ) ;
     nBufs := FileLength div SizeOf(FileBuf) ;
     sbRecord.Max :=MaxInt( [nBufs-1,1] ) ;
     sbRecord.Min := 0 ;
     bStart.Enabled := True ;
     bStop.Enabled := False ;
     mnFile.Enabled := True ;
     //if FileLength > 0 then sbRecord.Enabled := True
     end;

procedure TMainForm.sbRecordChange(Sender: TObject);
begin
     State := Replay ;
end;

procedure TMainForm.bStartClick(Sender: TObject);
var
   FileLength : LongInt ;
begin
     State := Recording ;
     FileLength := FileSeek( FileHandle, 0, 2 ) ;
     bStart.Enabled := False ;
     bStop.Enabled := True ;
     sbRecord.Enabled := False ;
     mnFile.Enabled := False ;
     BufPointer := -1 ;
     InitializeDisplay ;
     end;

procedure TMainForm.mnPrintClick(Sender: TObject);
begin
     PrintTraces ;
     end;

procedure TMainForm.pbDisplayMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
var
   ch,chCursor : Integer ;
   XValue,YValue : single ;
begin

     chCursor := 0 ;
     XValue := (X-Channel[0].left) / Channel[0].xScale + Channel[0].xMin ;
     for ch := 0 to ChMarker-1 do if Channel[ch].InUse then begin
         YValue := (Channel[ch].Bottom - Y) / Channel[ch].yScale
                   + Channel[ch].yMin ;
         if ((Channel[ch].yMin <= YValue)
            and (YValue <= Channel[ch].yMax) ) then ChCursor := Ch ;
        end ;

     if (Y <= Channel[ChCursor].Bottom)
        and (Y >= Channel[ChCursor].Top) then begin
        YValue := (Channel[ChCursor].Bottom - Y) / Channel[ChCursor].yScale
                   + Channel[ChCursor].yMin ;
        edCursor.text := format('T= %.1f s %s= %.1f %s',
                              [ XValue,
                                Channel[ChCursor].ADCName,
                                YValue,
                                Channel[ChCursor].ADCUnits] )
        end
     else edCursor.text := ' ' ;
     end ;


procedure TMainForm.mnExitClick(Sender: TObject);
{ -----------------
  Stop the program
  ----------------}
begin
     Close ;
     end ;

procedure TMainForm.mnHelpClick(Sender: TObject);
// -----------------------
//  Help/Contents menu item
//  -----------------------
begin
//     ShellExecute(Handle,'open', 'c:\windows\hh.exe',PChar(Application.HelpFile),
//     nil, SW_SHOWNORMAL) ;
     //Application.HelpContext(10) ;
     end;

procedure TMainForm.mnContentsClick(Sender: TObject);
// -----------------------
//  Help/Contents menu item
//  -----------------------
var
   pWinDir : PChar ;
   WindowsDir : String ;
begin


     GetMem( pWinDir, 512 ) ;
     GetWindowsDirectoryW( pWinDir, 256 ) ;
     FileName := pWinDir + '\hh.exe' ;

     ShellExecute( Handle,PChar('open'),
                   PChar(FileName),
                   PChar(Application.HelpFile),
                   nil,
                   SW_SHOWNORMAL) ;
     FreeMem( pWinDir ) ;
     end;


procedure TMainForm.mnAboutClick(Sender: TObject);
begin
     AboutFrm.ShowModal ;
     end;


procedure TMainForm.mnLoadRatClick(Sender: TObject);
{ -------------------------------------------
  Load an experiment from a .RAT storage file
  -------------------------------------------}
var
   TempHandle : Integer ;
   i,nBufs,FileLength,nw : longInt ;
begin
     if OpenDialog.execute then begin
        if FileExists( OpenDialog.FileName ) then begin
           { Open .RAT file containing experiment }
           TempHandle := FileOpen( OpenDialog.FileName, fmOpenReadWrite ) ;
           Caption := ProgName + ' : ' + OpenDialog.FileName ;
           FileName := OpenDialog.FileName ;
           { Find out how big it is }
           FileLength := FileSeek( TempHandle, 0, 2 ) ;
           nBufs := FileLength div SizeOf(FileBuf) ;
           { Create an empty working file }
           FileClose( FileHandle ) ;
           FileHandle := FileCreate( 'Rat.tmp' ) ;
           { Copy data from .RAT storage file into work file }
           nw := FileSeek( TempHandle, 0, 0 ) ;
           for i := 1 to nBufs do begin
               nw := FileRead( TempHandle, FileBuf, Sizeof(FileBuf)) ;
               nw := FileWrite( FileHandle, FileBuf, Sizeof(FileBuf)) ;
               end ;
           { Close .RAT file }
           FileClose( TempHandle ) ;

           sbRecord.Max := nBufs-1 ;
           sbRecord.Min := 0 ;
           bStart.Enabled := True ;
           bStop.Enabled := False ;
           if nBufs > 0 then sbRecord.Enabled := True ;
           State := Replay ;
           end ;
        end ;
     end ;

procedure TMainForm.mnSaveRatClick(Sender: TObject);
{ -------------------------------------------
  Save an experiment to a .RAT storage file
  -------------------------------------------}
var
   TempHandle : Integer ;
   i,nw : longInt ;
begin
     if SaveDialog.execute then begin
        { Create .RCV storage file to hold experiment }
        TempHandle := FileCreate( SaveDialog.FileName ) ;
        FileName := SaveDialog.FileName ;
        Caption := ProgName + ' : ' + SaveDialog.FileName ;
        { Copy data from .RCV storage file into work file }
        FilePointer := FileSeek( FileHandle, 0, 0 ) ;
        for i := 1 to sbRecord.Max+1 do begin
            nw := FileRead( FileHandle, FileBuf, Sizeof(FileBuf));
            nw := FileWrite( TempHandle, FileBuf, Sizeof(FileBuf)) ;
            end ;
        { Close .RCV file }
        FileClose( TempHandle ) ;
        end ;
     end;

procedure TMainForm.mnNewRatClick(Sender: TObject);
begin
     if MessageDlg('New Experiment! Are you sure?', mtConfirmation,
        [mbYes,mbNo],0) = mrYes then begin
        FileClose( FileHandle ) ;
        InitializeSimulation ;
        end;
     end;

procedure TMainForm.FormActivate(Sender: TObject);
begin

     REsize ;

     AboutFrm.ShowModal ;

     end;


function PrinterPointsToPixels( PointSize : Integer ) : Integer ;
var
   PixelsPerInch : single ;
begin

     { Get height and width of page (in mm) and calculate
       the size of a pixel (in cm) }
     PixelsPerInch := GetDeviceCaps( printer.handle, LOGPIXELSX ) ;
     PrinterPointsToPixels := Trunc( (PointSize*PixelsPerInch) / 72. ) ;
     end ;



procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
     if MessageDlg( 'Exit Program! Are you Sure? ', mtConfirmation,
        [mbYes,mbNo], 0 ) = mrYes then CanClose := True
                                  else CanClose := False ;
     end;

procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
// -----------------------------------------
// Close form and dispose of created objects
// -----------------------------------------
var
    i : Integer ;
begin

     Timer.Enabled := False ;

     // Close file
     FileClose( FileHandle ) ;

     Heart.Free ;
     Art.Free ;
     Ven.Free ;
     Con.Free ;

     for i := 0 to High(Drugs) do begin
         Drugs[i].Free ;
         end ;

     DeleteFile( PChar(TempFileName) ) ;
     end;

procedure TMainForm.mnStimCardiacClick(Sender: TObject);
{ --------------------------------------
  Stimulation cardiac sympathetic nerves
  --------------------------------------}
var
   ix : Integer ;
begin
     ix := FindDrug( Drugs, 'Cardiac' ) ;
     Marker.Index := ix ;
     Marker.Value := 0.0 ;
     Marker.Units := NoUnits ;
     Drugs[ix].DoseInjected := 5.0*Drugs[ix].Beta1AdR.Potency
                               *( 0.5 + Alpha2Adr ) ;
     end;

procedure TMainForm.mnStimAdrenalClick(Sender: TObject);
{ --------------------------------------
  Stimulation adrenal sympathetic nerves
  --------------------------------------}
var
   ix : Integer ;
begin
     ix := FindDrug( Drugs, 'AdrenNerve' ) ;
     Marker.Index := ix ;
     Marker.Value := 0.0 ;
     Marker.Units := NoUnits ;
     Drugs[ix].DoseInjected := 2.*Drugs[ix].Beta1AdR.Potency ;
     end;

procedure TMainForm.mnStimVagusClick(Sender: TObject);
{ ------------------------
  Stimulation vagal nerves
  ------------------------}
var
   ix : Integer ;
begin
     ix := FindDrug( Drugs, 'Vagus' ) ;
     Marker.Index := ix ;
     Marker.Value := 0.0 ;
     Marker.Units := NoUnits ;
     Drugs[ix].DoseInjected := 10.0*Drugs[ix].VagChR.Potency ;
     end;


constructor TDrug.Create(
          NameIn : String ;
          ShortNameIn : string
          ) ;
begin
     Inherited Create   ;
     Name := NameIn ;
     ShortName := ShortNameIn ;
     Dose := 0.0 ;
     DoseInjected := 0.0 ;
     Conc := 0.0 ;
     Alpha1AdR.Efficacy := None ;
     Alpha1AdR.Potency := None ;
     Alpha2AdR.Efficacy := None ;
     Alpha2AdR.Potency := None ;
     Beta1AdR.Efficacy := None ;
     Beta1AdR.Potency := None ;
     Beta2AdR.Efficacy := None ;
     Beta2AdR.Potency := None ;
     MusChR.Efficacy := None ;
     MusChR.Potency := None ;
     VagChR.Efficacy := None ;
     VagChR.Potency := None ;
     NicChR.Efficacy := None ;
     NicChR.Potency := None ;
     HMCaChannel.Efficacy := None ;
     HMCaChannel.Potency := None ;
     SMCaChannel.Efficacy := None ;
     SMCaChannel.Potency := None ;
     AdenR.Efficacy := None ;
     AdenR.Potency := None ;
     KChannel.Efficacy := None ;
     KChannel.Potency := None ;
     NOX.Efficacy := None ;
     NOX.Potency := None ;
     NOS.Efficacy := None ;
     NOS.Potency := None ;
     Angt1R.Efficacy := None ;
     Angt1R.Potency := None ;
     Angt2R.Efficacy := None ;
     Angt2R.Potency := None ;
     BradR.Efficacy := None ;
     BradR.Potency := None ;
     ACE.Efficacy := None ;
     ACE.Potency := None ;
     DigR.Efficacy := None ;
     DigR.Potency := None ;
     PDE.Efficacy := None ;
     PDE.Potency := None ;
     OnRate := 1.0 ;
     RemovalRate := 0.05 ;
     end ;

procedure TMainForm.SetAgonistPotency(
          var Drug : TDrugProperties ;
          Potency : single
          ) ;
begin
      if Potency <> None then begin
        Drug.Potency := Potency*AddNoise(0.5) ;
        { Efficacy - 1.0=agonist, 0.0=antagonist }
        Drug.Efficacy := 1.0 ;
        end
     else Drug.Efficacy := None ;
     end ;


function TMainForm.ReceptorActivation(
          iDrug : Integer ;
          Dose : single ;
          var Drug : TDrugProperties ;
          var Numerator : single ;
          var Denominator : single ;
          PotencyShift : single
          ) : single ;
var
   x : single ;
begin

     if iDrug = 0 then begin
        Numerator := 0.0 ;
        Denominator := 1.0 ;
        end ;
     if Drug.Efficacy <> None then begin
        x := Dose/(Drug.Potency*PotencyShift) ;
        Denominator := Denominator + x ;
        Numerator := Numerator + Drug.Efficacy*x ;
        end ;
     if Denominator > 0. then Result := Numerator/Denominator
                         else Result := 0. ;

     end ;


procedure TMainForm.SetAntagonistPotency(
          var Drug : TDrugProperties ;
          Potency : single
          ) ;
begin
      if Potency <> None then begin
        Drug.Potency := Potency*AddNoise(0.5) ;
        { Efficacy - 1.0=agonist, 0.0=antagonist }
        Drug.Efficacy := 0.0 ;
        end
     else Drug.Efficacy := None ;
     end ;


procedure TMainForm.mnRenalClick(Sender: TObject);
{ --------------------------------------
  Stimulation renal nerves
  --------------------------------------}
var
   ix : Integer ;
begin
     ix := FindDrug( Drugs, 'Renal' ) ;
     Marker.Index := ix ;
     Marker.Value := 0.0 ;
     Marker.Units := 0.0 ;
     Drugs[ix].DoseInjected := 5.*Drugs[ix].Angt1R.Potency ;
     end;


function PrinterCmToPixels(
         const Axis : string;
         cm : single
         ) : Integer ;
{ -------------------------------------------
  Convert from cm (on printer page) to pixels
  -------------------------------------------}
var
   PixelWidth,PixelHeight : single ;
begin
     { Get height and width of page (in mm) and calculate
       the size of a pixel (in cm) }
     if UpperCase(Axis) = 'H' then begin
        { Printer pixel width (mm) }
        PixelWidth := GetDeviceCaps( printer.handle, HORZSIZE ) ;
        Result := Trunc( ( 10. * cm * printer.pagewidth) / PixelWidth );
        end
     else begin
        { Printer pixel height (mm) }
        PixelHeight := GetDeviceCaps( printer.handle, VERTSIZE ) ;
        Result := Trunc( ( printer.pageheight * 10. * cm )/ PixelHeight ) ;
        end ;
     end ;


procedure TMainForm.PrintSetup1Click(Sender: TObject);
{ ------------------------------------
  Menu - Open printer setup dialog box
  ------------------------------------}
begin
     PrinterSetupDialog.Execute ;
     end;


procedure TMainForm.mndisplayClick(Sender: TObject);
begin
     OptionsFrm.ABPColor.brush.color := Channel[ChABP].color ;
     OptionsFrm.ckABPShow.checked := Channel[ChABP].InUse ;
     OptionsFrm.LVPColor.brush.color := Channel[ChLVP].color ;
     OptionsFrm.ckLVPShow.checked := Channel[ChLVP].InUse ;
     OptionsFrm.CVPColor.brush.color := Channel[ChCVP].color ;
     OptionsFrm.ckCVPShow.checked := Channel[ChCVP].InUse ;
     OptionsFrm.HCFColor.brush.color := Channel[ChHCF].color ;
     OptionsFrm.ckHCFShow.checked := Channel[ChHCF].InUse ;
     OptionsFrm.HRColor.brush.color := Channel[ChHR].color ;
     OptionsFrm.ckHRShow.checked := Channel[ChHR].InUse ;

     OptionsFrm.ShowModal ;

     if OptionsFrm.ModalResult = mrOK then begin
        Channel[ChABP].color := OptionsFrm.ABPColor.brush.color ;
        Channel[ChABP].InUse := OptionsFrm.ckABPShow.checked ;
        Channel[ChLVP].color := OptionsFrm.LVPColor.brush.color ;
        Channel[ChLVP].InUse := OptionsFrm.ckLVPShow.checked ;
        Channel[ChCVP].color := OptionsFrm.CVPColor.brush.color ;
        Channel[ChCVP].InUse := OptionsFrm.ckCVPShow.checked ;
        Channel[ChHCF].color := OptionsFrm.HCFColor.brush.color ;
        Channel[ChHCF].InUse := OptionsFrm.ckHCFShow.checked ;
        Channel[ChHR].color := OptionsFrm.HRColor.brush.color ;
        Channel[ChHR].InUse := OptionsFrm.ckHRShow.checked ;
        State := Replay ;
        end ;
     end;

procedure TMainForm.mnStimBloodVesselsClick(Sender: TObject);
{ -----------------------------------------------
  Stimulation sympathetic nerves to blood vessels
  -----------------------------------------------}
var
   ix : Integer ;
begin
     ix := FindDrug( Drugs, 'SympNerve' ) ;
     Marker.Index := ix ;
     Marker.Value := 0.0 ;
     Marker.Units := NoUnits ;
     Drugs[ix].DoseInjected := 4.0*Drugs[ix].Beta1AdR.Potency
                               *( 0.5 + Alpha2Adr ) ;
     end;


end.
