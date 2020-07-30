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
  V3.3.4 22/07/18     Adrenaline Beta2AdR EC50 reduced and Alpha1AdR EC50 increased to produce
                      slight reduction in ABP at low concentrations and increase in ABP at high concentrations
  V3.3.5 19.06.19     Adrenaline Beta2AdR EC50 reduced and Alpha1AdR EC50 restored to previous values
                      to produce INCREAESE in ABP at 5-10 ug/kg to make it more consistent with effect of ADR observed in original pithed rat papers.
  V3.3.6 16.07.20     Chart display updated to use scopedisplay component. Vertical range can now be adjusted.
  3.3.37 30.07.20     Channel blockers and enzyme inhibitors now moved from agonisy to antagonisy list
                      Incorrect alpha-2 adrenoceptor agonist activity of phentolamine removed

  ======================================================================== }

interface

uses
  SysUtils, WinTypes, WinProcs, Messages, Classes, Graphics, Controls,
  Forms, Dialogs, Menus, StdCtrls, ExtCtrls,
  Printers, Vcl.ComCtrls,math, HTMLHelpViewer, shellapi, system.types, system.uitypes,
  ScopeDisplay, ValidatedEdit, System.StrUtils, Vcl.Imaging.pngimage  ;

const
     MaxPoints = 10000000 ;
     MaxDisplayPoints = 4000 ;
     BPMax = 200 ;
     MaxADCValue = 2047 ;
     MinADCValue = -2048 ;
    MaxMarkers = 500 ;
    NumBytesPerMarker = 40 ;
    FileHeaderSize = (MaxMarkers+10)*NumBytesPerMarker ;
    DataFileExtension = '.rat' ;

     ChABP = 0 ;   { Arterial blood pressure channel }
     ChLVP = 1 ;   { Average bloood pressure channel }
     ChCVP = 2 ;   { Venous blood pressure }
     ChHCF = 3 ;   { Cardiac contractility }
     ChHR = 4 ;    { Heart rate channel }
     None = -1. ;

type
    TDrugProperties = record
                    Potency : single ;
                    Efficacy : single ;
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
            Antagonist : Boolean ;
            constructor Create(
                        NameIn : String ;
                        ShortNameIn : string
                        ) ;
            end ;

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

    TNerve = record
           Stimulated : boolean ;
           StimulusInterval : single ;
           StimulusActivity : single ;
           Activity : single ;
           end ;

TString6 = string[6] ;
TFileBuf = Array[0..511] of single ;

  TMainForm = class(TForm)
    MainMenu1: TMainMenu;
    mnFile: TMenuItem;
    mnNewRat: TMenuItem;
    mnLoadRat: TMenuItem;
    mnSaveRat: TMenuItem;
    mnPrint: TMenuItem;
    PrintSetup1: TMenuItem;
    mnExit: TMenuItem;
    mnHelp: TMenuItem;
    mnContents: TMenuItem;
    SaveDialog: TSaveDialog;
    OpenDialog: TOpenDialog;
    Page: TPageControl;
    ChartTab: TTabSheet;
    PictureTab: TTabSheet;
    ExpImage: TImage;
    scDisplay: TScopeDisplay;
    Timer: TTimer;
    TDisplayPanel: TPanel;
    lbTDisplay: TLabel;
    Label1: TLabel;
    edTDisplay: TValidatedEdit;
    bTDisplayDouble: TButton;
    bTDisplayHalf: TButton;
    edStartTime: TValidatedEdit;
    sbDisplay: TScrollBar;
    bStart: TButton;
    bStop: TButton;
    ControlsGrp: TGroupBox;
    TissueGrp: TGroupBox;
    bNewExperiment: TButton;
    GroupBox6: TGroupBox;
    bStimulationOn: TButton;
    StimulationTypeGrp: TGroupBox;
    rbSympNerveToHeart: TRadioButton;
    rbSympNerve: TRadioButton;
    PageControl1: TPageControl;
    AgonistsTab: TTabSheet;
    Label2: TLabel;
    cbAgonist: TComboBox;
    cbAgonistDose: TComboBox;
    bAddAgonist: TButton;
    AntagonistsTab: TTabSheet;
    Label4: TLabel;
    cbAntagonist: TComboBox;
    cbAntagonistDose: TComboBox;
    UnknownsTab: TTabSheet;
    Label7: TLabel;
    cbUnknown: TComboBox;
    cbUnknownDose: TComboBox;
    rbSympNerveToAdrenals: TRadioButton;
    rbRenalNerve: TRadioButton;
    RadioButton1: TRadioButton;
    gpExperimentType: TGroupBox;
    rbNormalRat: TRadioButton;
    rbPithedRat: TRadioButton;
    bAddUnknown: TButton;
    bAddAntagonist: TButton;
    mnEdit: TMenuItem;
    mnCopyData: TMenuItem;
    mnCopyImage: TMenuItem;
    PrinterSetupDialog: TPrinterSetupDialog;
    procedure TimerTimer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure bStopClick(Sender: TObject);
    procedure bStartClick(Sender: TObject);
    procedure mnExitClick(Sender: TObject);
    procedure mnContentsClick(Sender: TObject);
    procedure mnLoadRatClick(Sender: TObject);
    procedure mnSaveRatClick(Sender: TObject);
    procedure mnNewRatClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure PrintSetup1Click(Sender: TObject);
    procedure cbAgonistChange(Sender: TObject);
    procedure cbAntagonistChange(Sender: TObject);
    procedure cbUnknownChange(Sender: TObject);
    procedure bAddAgonistClick(Sender: TObject);
    procedure bAddAntagonistClick(Sender: TObject);
    procedure bAddUnknownClick(Sender: TObject);
    procedure bStimulationOnClick(Sender: TObject);
    procedure edStartTimeKeyPress(Sender: TObject; var Key: Char);
    procedure edTDisplayKeyPress(Sender: TObject; var Key: Char);
    procedure bTDisplayDoubleClick(Sender: TObject);
    procedure bTDisplayHalfClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure mnCopyImageClick(Sender: TObject);
    procedure mnCopyDataClick(Sender: TObject);
    procedure mnPrintClick(Sender: TObject);
    procedure bNewExperimentClick(Sender: TObject);
    procedure scDisplayCursorChange(Sender: TObject);

  private
    { Private declarations }

    ADC : Array[0..MaxPoints-1] of SmallInt ;
    NumPointsInBuf : Integer ;   // No. of data points in buffer
    StartPoint : Integer ;       // Starting point of chart display
    InitialMixing : Cardinal ;
    MarkerList : TStringList ;   // Chart annotation list

    LastAgonist : Integer ;      // Index of last agonist in drug list
    LastAntagonist : Integer ;      // Index of last antagonist in drug list

   UnsavedData : Boolean ;
   t : TTime ;
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

   // Index into Drugs[] of neurtransmitters activated by selected nerve pathways
   iSympHeart : Integer ;         // Sympathetic stimulation of heart
   iSympBloodVessels : Integer ;  // Sympathetic stimulation of blood vessels
   iSympAdrenal : Integer ;       // Sympathetic stimulation of adrenal glands
   iRenalNerve : Integer ;        // Renal nerve stimulation
   iVagusNerve : Integer ;        // Vagus nerve stimulation

   ACE : single ;    { Angiotensin converting enzyme activity }
   BradR : single ;  { Bradykinin recptor }
   DigR : single ;   { Digoxin activity on cardiac force }
   PDE : single ; { Degree of phosphidesterase inhibition }

   Dead : boolean ;
   Dying : LongInt ;
   Fibrillation : single ;
   Ven : TElement ;
   Art : TElement ;
   Heart : TElement ;
   Con : TElement ;


    procedure CalculateTrace ;
    procedure InitializeSimulation ;
    procedure SetAgonistPotency(
              var Drug : TDrugProperties ;
              Potency : single
              ) ;

    procedure SetAntagonistPotency(
              var Drug : TDrugProperties ;
              Potency : single
              ) ;

    function IsAgonist( Drug : TDrug ) : Boolean ;

    Function ReceptorActivation(
          iDrug : Integer ;
          Dose : single ;
          var Drug : TDrugProperties ;
          var Numerator : single ;
          var Denominator : single ;
          PotencyShift : single
          ) : single ;

    procedure UpdateDisplay ;

    procedure AddChartAnnotations ;
    procedure UpdateDisplayDuration ;

    function AddNoise( Proportion : single ) : single ;
    Procedure UpdateCirculatingDrug( var Drug : TDrug ) ;
    function ExtractFloat ( CBuf : string ; Default : Single ) : extended ;

    function Pressure( Element : TElement ) : single ;

    procedure SetDoseList(
              cbDrug : TComboBox ;
              cbDose : TComboBox ) ;

   procedure AddDrugMarker(
             ChartAnnotation : String
             ) ;

   procedure LoadFromFile( FileName : String ) ;
   procedure SaveToFile( FileName : String ) ;

  public
    { Public declarations }
    ProgName : string ;
    WinDir : PChar ;
  end;



var
  MainForm: TMainForm;

implementation

uses PrintUnit, shared ;

{$R *.DFM}

procedure TMainForm.FormCreate(Sender: TObject);
{ ------------------------------------
  Initialisations when form is created
  ------------------------------------}

begin
     Caption := 'Rat Cardiovascular System (c) J. Dempster, University of Strathclyde (1996-2020) V3.3.7 (30.07.20)' ;

     ProgName := Caption ;

     Application.HelpFile := ExtractFilePath(ParamStr(0)) + 'ratcvs.chm';

     Heart := TElement.Create ;
     Art := TElement.Create ;
     Ven := TElement.Create ;
     Con := TElement.Create ;

     // Create annotation list
     MarkerList := TStringList.Create ;

     InitializeSimulation ;

     end;


procedure TMainForm.FormDestroy(Sender: TObject);
// ---------------------------
// Tidy up when form destroyed
// ---------------------------

begin
    MarkerList.Free ;
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
   iDrug,i : Integer ;
begin

     Caption := ProgName ;

     {Initialise drug doses and potencies }

     for iDrug := 0 to High(Drugs) do Drugs[iDrug] := Nil ;

{    *** STANDARD DRUGS ***************************************************}

     { Adrenaline - Alpha11,beta1,beta2 adrenoceptor agonist }
     iDrug := 0 ;
     Drugs[iDrug] := TDrug.Create( 'Adrenaline', 'Adr' ) ;
     Drugs[iDrug].OnRate := FastOn ;
     Drugs[iDrug].RemovalRate := FastOff ;
     SetAgonistPotency( Drugs[iDrug].Alpha1AdR, 5E-3 {7.5e-3} ) ;  {Increased to 7.5E-3 to cause increase in ABP at high concentrations 22.7.18 }
                                                                   // Restored to previous 5E-3 to increase alpha adrenoecrptor effect
                                                                   // to ensure increase in ABP with 5-10 ug/kg as observed in original pithed rate paper 19.06.19
     SetAgonistPotency( Drugs[iDrug].Beta1AdR, 3.5E-3 ) ;
     SetAgonistPotency( Drugs[iDrug].Beta2AdR, 5E-3 {2E-3} ) ; {Reduced to 2E-3 to cause reduction in ABP at low concentrations 22.7.18}
                                                               // Restored to previous value 19.06.19

     Drugs[iDrug].MinDose := 1E-4 ;
     Drugs[iDrug].MaxDose := 1E-1 ;

//   Agonists
//   --------

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
     Drugs[iDrug] := TDrug.Create(  'Adenosine', 'Ade' ) ;
     Drugs[iDrug].OnRate := FastOn ;
     Drugs[iDrug].RemovalRate := FastOff ;
     SetAgonistPotency( Drugs[iDrug].AdenR, 1.0 ) ;
     Drugs[iDrug].MinDose := 0.1 ;
     Drugs[iDrug].MaxDose := 100. ;

     Inc(iDrug) ;
     Drugs[iDrug] := TDrug.Create(  'Cromakalim', 'Cro' ) ;     { K channel opener }
     Drugs[iDrug].OnRate := SlowOn ;                            {causes vasodilation }
     Drugs[iDrug].RemovalRate := SlowOff ;
     SetAgonistPotency( Drugs[iDrug].KChannel, 0.3 ) ;
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

     LastAgonist := iDrug ;

//   Antagonists
//   -----------


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
     Drugs[iDrug] := TDrug.Create(  'Phentolamine', 'Phe' ) ;  { Alpha Adr. }
     Drugs[iDrug].OnRate := FastOn ;                           { antagonist }
     Drugs[iDrug].RemovalRate := SlowOff ;
     SetAntagonistPotency( Drugs[iDrug].Alpha1Adr, 1E-1 ) ;
     SetAntagonistPotency( Drugs[iDrug].Alpha2Adr, 1E-1 ) ;
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
     Drugs[iDrug] := TDrug.Create(  'Atropine', 'Atr' ) ;
     Drugs[iDrug].OnRate := FastOn ;
     Drugs[iDrug].RemovalRate := SlowOff ;
     SetAntagonistPotency( Drugs[iDrug].MusChR, 0.1 ) ; {Potency reduced to 0.1 4/7/00}
     SetAntagonistPotency( Drugs[iDrug].VagChR, 0.1 ) ;
     Drugs[iDrug].MinDose := 0.01 ;
     Drugs[iDrug].MaxDose := 10.0 ;

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

     Inc(iDrug) ;
     Drugs[iDrug] := TDrug.Create(  'Glibenclamide', 'Gli' ) ;   { K Channel blocker }
     Drugs[iDrug].OnRate := SlowOn ;
     Drugs[iDrug].RemovalRate := SlowOff ;
     SetAntagonistPotency( Drugs[iDrug].KChannel, 1.0 ) ;
     Drugs[iDrug].MinDose := 0.1 ;
     Drugs[iDrug].MaxDose := 100. ;

     LastAntagonist := iDrug ;

     // Create list of known agonists and antagonists and dose list for first in list

     cbAgonist.Clear ;
     for i := 0 to LastAgonist do cbAgonist.Items.AddObject( Drugs[i].Name, TObject(i)) ;
     SetDoseList( cbAgonist, cbAgonistDose ) ;

     cbAntagonist.Clear ;
     for i := LastAgonist+1 to LastAntagonist do cbAntagonist.Items.AddObject( Drugs[i].Name, TObject(i)) ;
     SetDoseList( cbAntagonist, cbAntagonistDose ) ;


//   UNKNOWN DRUGS
//   -------------

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

     // Create list of unknown drugs

     cbUnknown.Clear ;
     for i := LastAntagonist+1 to iDrug do cbUnknown.Items.AddObject( Drugs[i].Name, TObject(i)) ;
    SetDoseList( cbUnknown, cbUnknownDose ) ;


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
     iSympAdrenal := iDrug ;

     { Blood vessel symp. nerve stimulation - noradrenaline }
     Inc(iDrug) ;
     Drugs[iDrug] := TDrug.Create(  'SympNerve', 'Symp(-AD)' ) ;
     Drugs[iDrug].OnRate := FastOn*7.0 ;
     Drugs[iDrug].RemovalRate := FastOff*4.0 ;
     SetAgonistPotency( Drugs[iDrug].Alpha1AdR, 1E-2 ) ;
     SetAgonistPotency( Drugs[iDrug].Beta1AdR, 1.5E-2 ) ;
     SetAgonistPotency( Drugs[iDrug].Beta2AdR, 1.5E-1 ) ;
     iSympBloodVessels := iDrug ;

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

     // ACE produced Angiotensin II via renal nerve stimulation
     Inc(iDrug) ;
     Drugs[iDrug] := TDrug.Create(  'AngiotensinIIACE', 'An2' ) ;
     Drugs[iDrug].OnRate := FastOn ;
     Drugs[iDrug].RemovalRate := FastOff ;
     SetAgonistPotency( Drugs[iDrug].Angt2R, 1E-4 ) ;
     iAngioTensin2ACE := iDrug ;
     Drugs[iDrug].MinDose := 1E-4 ;
     Drugs[iDrug].MaxDose := 1E-2 ;


     { Chart recorder traces }

     { Setuo chart display }
     scDisplay.MaxADCValue := MaxADCValue ;
     scDisplay.MinADCValue := MinADCValue ;
     scDisplay.DisplayGrid := True ;

     scDisplay.MaxPoints := MaxDisplayPoints ;
     scDisplay.NumPoints := 0 ;
     scDisplay.NumChannels := 5 ;
     sbDisplay.Max := 0 ;

     scDisplay.TScale := 1/20.0 ;
     edTDisplay.LoLimit := 1.0/scDisplay.TScale ;
     edTDisplay.HiLimit := 1E5 ;
     edTDisplay.Scale := scDisplay.TScale ;
     edStartTime.Scale := scDisplay.TScale ;
     edTDisplay.Value := scDisplay.MaxPoints ;
     scDisplay.XMin := 0 ;
     scDisplay.XMax := scDisplay.MaxPoints -1 ;

     { Blood pressure }
     scDisplay.ChanName[ChABP] := 'ABP' ;
     scDisplay.ChanUnits[ChABP] := 'mmHg' ;
     scDisplay.ChanScale[ChABP] := 300.0 / MaxADCValue ;
     scDisplay.ChanZero[ChABP] := 0.0 ;
     scDisplay.ChanOffsets[ChABP] := chABP ;
     scDisplay.yMax[ChABP] := 200.0/scDisplay.ChanScale[ChABP] ;
     scDisplay.yMin[ChABP]:= 0.0 ;
     scDisplay.ChanVisible[ChABP] := True ;

     { Left ventricular pressure }
     scDisplay.ChanName[chLVP] := 'LVP' ;
     scDisplay.ChanUnits[chLVP] := 'mmHg' ;
     scDisplay.ChanScale[ChLVP] := 300.0 / MaxADCValue ;
     scDisplay.ChanZero[chLVP] := 0.0 ;
     scDisplay.ChanOffsets[chLVP] := chLVP ;
     scDisplay.yMax[chLVP] := 200.0/scDisplay.ChanScale[ChLVP] ;
     scDisplay.yMin[chLVP]:= 0.0 ;
     scDisplay.ChanVisible[chLVP] := True ;

     { Venous Pressure }
     scDisplay.ChanName[chCVP] := 'VBP' ;
     scDisplay.ChanUnits[chCVP] := 'mmHg' ;
     scDisplay.ChanScale[ChCVP] := 50.0 / MaxADCValue ;
     scDisplay.ChanZero[chCVP] := 0.0 ;
     scDisplay.ChanOffsets[chCVP] := chCVP ;
     scDisplay.yMax[chCVP] := 20.0/scDisplay.ChanScale[ChCVP] ;
     scDisplay.yMin[chCVP]:= 0.0 ;
     scDisplay.ChanVisible[chCVP] := True ;

     { Cardiac contractile force (dLVP/dt)/LVP }
     scDisplay.ChanName[chHCF] := 'HF' ;
     scDisplay.ChanUnits[chHCF] := '' ;
     scDisplay.ChanZero[chHCF] := 0.0 ;
     scDisplay.ChanScale[ChHCF] := 20.0 / MaxADCValue ;
     scDisplay.ChanOffsets[chHCF] := chHCF ;
     scDisplay.yMax[chHCF] := 20.0/scDisplay.ChanScale[ChHCF] ;
     scDisplay.yMin[chHCF]:= 0.0 ;
     scDisplay.ChanVisible[chHCF] := True ;

     { Heart rate }
     scDisplay.ChanName[chHR] := 'HR' ;
     scDisplay.ChanUnits[chHR] := 'BPM' ;
     scDisplay.ChanZero[chHR] := 0.0 ;
     scDisplay.ChanScale[ChHR] := 1600.0 / MaxADCValue ;
     scDisplay.ChanOffsets[chHR] := chHR ;
     scDisplay.yMax[chHR]  := 800.0/scDisplay.ChanScale[ChHR] ;
     scDisplay.yMin[chHR]:= -10.0 ;
     scDisplay.ChanVisible[chHR] := True ;

     { Create a set of zero level cursors }
     scDisplay.ClearHorizontalCursors ;
     scDisplay.AddHorizontalCursor( 0, clRed, True, '' ) ;
     scDisplay.HorizontalCursors[0] := 0 ;

     // Vertical readout cursor
     scDisplay.ClearVerticalCursors ;
     scDisplay.AddVerticalCursor(-1,clGreen, '?y') ;
     scDisplay.VerticalCursors[0] := scDisplay.MaxPoints div 2 ;

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

     { Clear buffer  }
     for i := 0 to MaxPoints-1 do ADC[i] := 0 ;
     StartPoint :=  0 ;
     scDisplay.SetDataBuf( @ADC[StartPoint] ) ;
     scDisplay.XOffset := -1 ;
     NumPointsInBuf := 0 ;
     MarkerList.Clear ;

     Dead := False ;
     Dying := 0 ;
     Fibrillation := 0.0 ;
     bStart.Enabled := True ;
     bStop.Enabled := False ;
     gpExperimentType.Enabled := True ;

     end ;


procedure TMainForm.TimerTimer(Sender: TObject);
// ---------------------
// Timed event scheduler
// ---------------------
begin

     if not bStart.Enabled then
        begin
        { Calculate next set of simulation values }
        CalculateTrace ;
        UpdateDisplay ;
        InitialMixing := InitialMixing + 1 ;
        if NumPointsInBuf >= MaxPoints then bStart.Enabled := True ;

        end
     else
        begin
        // Display
        if scDisplay.XOffset <> sbDisplay.Position then
           begin
           scDisplay.XOffset := sbDisplay.Position ;
           edStartTime.Value := scDisplay.XOffset ;
           scDisplay.SetDataBuf( @ADC[sbDisplay.Position*scDisplay.NumChannels] ) ;
           scDisplay.NumPoints := Min( scDisplay.MaxPoints,
                                       sbDisplay.Max - sbDisplay.Position) ;
           // Add annotations to chart
           AddChartAnnotations ;
           scDisplay.Invalidate ;
           end ;
        end ;

end;


procedure TMainForm.UpdateDisplay ;
// -------------------
// Update chart display
// -------------------
var
    ch,StartPoints : Integer ;
begin

     // Ensure that horizontal cursor remains at zero
     for ch := 0 to scDisplay.NumChannels-1 do
         begin
         if scDisplay.HorizontalCursors[ch] <> 0 then scDisplay.HorizontalCursors[ch] := 0 ;
         end;

    if scDisplay.NumPoints >= scDisplay.MaxPoints then
       begin
       StartPoints := scDisplay.MaxPoints div 10 ;
       sbDisplay.Position := NumPointsInBuf - StartPoints + 1 ;
       scDisplay.XOffset := sbDisplay.Position ;
       scDisplay.SetDataBuf( @ADC[sbDisplay.Position*scDisplay.NumChannels] ) ;
       sbDisplay.Max := sbDisplay.Max + scDisplay.MaxPoints ;
       edStartTime.HiLimit := sbDisplay.Max ;
       // Add annotations to chart
       AddChartAnnotations ;
       end ;

    scDisplay.DisplayNewPoints( NumPointsInBuf - scDisplay.XOffset ) ;

end ;


procedure TMainForm.AddChartAnnotations ;
// -------------------------------------
// Add drug annotations to chart display
// -------------------------------------
var
    i : Integer ;
    MarkerPosition : Integer ;
begin

     scDisplay.ClearMarkers ;
     for i := 0 to MarkerList.Count-1 do
         begin
         MarkerPosition := Integer(MarkerList.Objects[i]) - scDisplay.XOffset ;
         if (MarkerPosition > 0) and (MarkerPosition < scDisplay.MaxPoints) then
            begin
            scDisplay.AddMarker( MarkerPosition, MarkerList.Strings[i] ) ;
            end ;
         end ;
     end ;



procedure TMainForm.CalculateTrace ;
{ -------------------------------------------
  Calculate next step of simulated BP and HR
  ------------------------------------------}
const
    NumStepsPerDisplayPoint = 100 ;
var
   x : single ;
   i,j : Integer ;
   Num,Denom : single ;
   PotencyShift,TMid,YMax,YMin : single ;
  ch: Integer;
begin

     if t.time >= t.next then
        begin

        { Ensure resting levels of angiotensin in circulation }
        Drugs[iRenalNerve].Dose := Max( Drugs[iRenalNerve].Dose,
                                        Drugs[iRenalNerve].Angt1R.Potency*0.25) ;

        { Nicotinic (ganglion) cholinoceptor activation }
        for i := 0 to High(Drugs) do if Drugs[i] <> Nil then
            NicChR := ReceptorActivation(i,Drugs[i].Dose,Drugs[i].NicChR,Num,Denom,1.0 ) ;

        { Effects of sympathetic nerve and vagal baroreceptor feedback
          in normal UNPITHED rat }
        if rbNormalRat.checked then
           begin

           { Basal sympathetic nerve stimulation of blood vessels }
           Drugs[iAlpha1AdrNerves].Dose := Drugs[iAlpha1AdrNerves].Alpha1Adr.Potency*0.4 ;
           Drugs[iBeta1AdrNerves].Dose := Drugs[iBeta1AdrNerves].Beta1Adr.Potency*0.2 ;

           { ** Baroreceptor feedback loops (in normal rat only) ** }
           Drugs[iVagusNerve].Dose := Max( Drugs[iVagusNerve].Dose,
                                           Drugs[iVagusNerve].VagChR.Potency
                                           * (5.0 / (1.+ exp(-(Art.MeanPressure-130.0)/8.0)))
                                           ) ;

           end ;

          { Update drugs in circulation }
          for i := 0 to High(Drugs) do if Drugs[i] <> Nil then
              begin
              Drugs[i].Dose := Drugs[i].Dose
                               + Drugs[i].OnRate*(Drugs[i].DoseInjected - Drugs[i].Dose)
                               - (Drugs[i].Dose*Drugs[i].RemovalRate) ;
              Drugs[i].Dose := Max( Drugs[i].Dose, 0. ) ;
              Drugs[i].DoseInjected := Max( Drugs[i].DoseInjected -
                                        Drugs[i].DoseInjected*Drugs[i].RemovalRate, 0. ) ;
              end ;


         { Muscarinic cholinoceptor activation }
         for i := 0 to High(Drugs) do if Drugs[i] <> Nil then
             MusChR := ReceptorActivation(i,Drugs[i].Dose,Drugs[i].MusChR,Num,Denom,1.0 ) ;

         { Vagally stimulated muscarinic cholinoceptor activation }
         for i := 0 to High(Drugs) do if Drugs[i] <> Nil then
             VagChR := ReceptorActivation(i,Drugs[i].Dose,Drugs[i].VagChR,Num,Denom,1.0 ) ;

         { Phosphodiesterase inhibition }
         for i := 0 to High(Drugs) do if Drugs[i] <> Nil then
             PDE := ReceptorActivation(i,Drugs[i].Dose,Drugs[i].PDE,Num,Denom,1.0 ) ;

         { Alpha1-adrenoceptor activation }
         for i := 0 to High(Drugs) do if Drugs[i] <> Nil then
             Alpha1AdR := ReceptorActivation(i,Drugs[i].Dose,Drugs[i].Alpha1AdR,Num,Denom,1.0 ) ;

         { Alpha2-adrenoceptor activation }
         for i := 0 to High(Drugs) do if Drugs[i] <> Nil then
             Alpha2AdR := ReceptorActivation(i,Drugs[i].Dose,Drugs[i].Alpha2AdR,Num,Denom,1.0 ) ;

         { Beta1-adrenoceptor activation }
         PotencyShift := 1.0 - PDE*0.5 ;
         for i := 0 to High(Drugs) do if Drugs[i] <> Nil then
             Beta1AdR := ReceptorActivation(i,Drugs[i].Dose,Drugs[i].Beta1AdR,Num,Denom,PotencyShift ) ;

        { Beta2-adrenoceptor activation }
        PotencyShift := 1.0 - PDE*0.5 ;
        for i := 0 to High(Drugs) do if Drugs[i] <> Nil then
            Beta2AdR := ReceptorActivation(i,Drugs[i].Dose,Drugs[i].Beta2AdR,
                        Num,Denom,PotencyShift ) ;

        { Heart muscle calcium channel activation }
        for i := 0 to High(Drugs) do if Drugs[i] <> Nil then
            HMCaChannels := ReceptorActivation(i,Drugs[i].Dose,Drugs[i].HMCaChannel,Num,Denom,1.0 ) ;

        { Digoxin effect on heart muscle }
        for i := 0 to High(Drugs) do if Drugs[i] <> Nil then
            DigR := ReceptorActivation(i,Drugs[i].Dose,Drugs[i].DigR,Num,Denom,1.0 ) ;

        { Smooth muscle calcium channel activation }
        for i := 0 to High(Drugs) do if Drugs[i] <> Nil then
            SMCaChannels := ReceptorActivation(i,Drugs[i].Dose,Drugs[i].SMCaChannel,Num,Denom,1.0 ) ;

        { Adenosine receptor activation }
        for i := 0 to High(Drugs) do if Drugs[i] <> Nil then
            AdenR := ReceptorActivation(i,Drugs[i].Dose,Drugs[i].AdenR,Num,Denom,1.0 ) ;

        { K channel activation }
        for i := 0 to High(Drugs) do if Drugs[i] <> Nil then
            KChannels := ReceptorActivation(i,Drugs[i].Dose,Drugs[i].KChannel,Num,Denom,1.0 ) ;

        { Nitric oxide synthase }
        for i := 0 to High(Drugs) do if Drugs[i] <> Nil then
            NOS := ReceptorActivation(i,Drugs[i].Dose,Drugs[i].NOS,Num,Denom,1.0 ) ;

        { Nitric oxide activation }
        { Note. Intrinsic generation of nitric oxide means that a certain
          degree of vasodilation exists in the absence of drugs }
        for i := 0 to High(Drugs) do if Drugs[i] <> Nil then
             NOX := ReceptorActivation(i,Drugs[i].Dose,Drugs[i].NOX,Num,Denom,1.0 ) ;

         { Angiotensin I activation }
        for i := 0 to High(Drugs) do if Drugs[i] <> Nil then
             Angt1R := ReceptorActivation(i,Drugs[i].Dose,Drugs[i].Angt1R,Num,Denom,1.0 ) ;

         { Angiotensin converting enzyme activity}
        for i := 0 to High(Drugs) do if Drugs[i] <> Nil then
             ACE := ReceptorActivation(i,Drugs[i].Dose,Drugs[i].ACE,Num,Denom,1.0 ) ;

         { Angiotensin II produce from Angiotensin I by angiotensin converting enzyme }
        Drugs[iAngioTensin2ACE].Dose := Drugs[iAngioTensin2ACE].Angt2R.Potency*5.0
                                         *( 1.0 - ACE )
                                         * (Angt1R / ( 1.0 + Angt1R )) ;

         { Angiotensin II activation }
        for i := 0 to High(Drugs) do if Drugs[i] <> Nil then
             Angt2R := ReceptorActivation(i,Drugs[i].Dose,Drugs[i].Angt2R,Num,Denom,1.0 ) ;

         { Bradykinin receptor activation }
        for i := 0 to High(Drugs) do if Drugs[i] <> Nil then
             BradR := ReceptorActivation(i,Drugs[i].Dose,Drugs[i].BradR,Num,Denom,1.0 ) ;

         t.next := t.time + 0.005 ;

        end ;

     Art.Conductance := 5.0*(1.0
                        + (2.5*MusChR*(1.0-NOS))  { Muscarinic receptors VD }
                        + ({2.25}1.9*Beta2AdR)   { Beta-2 adrenoceptor VD Decreased to 1.9 to allow alpha ADR vasosconstrictor to dominate at high concs.}
                        + (2.5*AdenR)             { Adenosine receptors VD }
                        + 2.0*NOX                 { Nitric oxide VD }
                        + 2.0*PDE                 { Phosphodiesterase inhibition VD }
                        + 0.95*SMCaChannels       { Ca channel block VD }
                        + 0.95*KChannels          { K channel opening VD }
                        + BradR                   { Bradykinin VD }
                        - 0.6*NOS                 { Inhib. of NO synthase VC }
                        - {0.9}1.35*Alpha1ADR     { Alpha-1 adrenoceptor VD Increased to 1.35 to emphasize vasoconstrictor effect at high concs. 22.07.18 }
                       { - 0.9*NicChR }            { Nicotinic VC }
                        - 0.9*Angt2R             { Angiotension II VC }

                        );
     Art.Conductance := Max( Art.Conductance,0.25 ) ;

     { Arterial elastance increased by vasoconstrictors
       Results in increased pulse pressure }
     Art.Elastance := (1./0.8) * (1.0
                      + 0.2*Alpha1Adr
                      );

     { Venous elastance : decreased by certain vasodilators
       Decreased elastance = increased venous capacity }
     Ven.Elastance := (1./30.0) * ( 1.0 - 0.7*Min( 1.0,
                      NOX
                      + SMCaCHannels
                      - Alpha1AdR
                      ) ) ;

     Heart.InitialisePressureRange ;
     Art.InitialisePressureRange ;
     Ven.InitialisePressureRange ;
     Con.InitialisePressureRange ;

     YMax := -1E38 ;
     YMin := 1E38 ;

     for i := 1 to NumStepsPerDisplayPoint do
         begin

         { Set heart rate and force for next beat}
         if t.Time >= Heart.NextBeat then
            begin

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
            Heart.Rate := Max( Heart.Rate, 1.0 ) ;

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

         if Heart.Time > 0.0 then
           begin

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

         if DigR > 0.95 then
            begin
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
         if (Heart.Pressure >= Art.Pressure) and (Fibrillation <= 0.0) then
            begin
            Heart.Flow := (Heart.Pressure - Art.Pressure)*Heart.Conductance ;
            Art.Volume := Art.Volume + Heart.Flow*t.step ;
            Heart.Volume := Heart.Volume - Heart.Flow*t.step ;
            end ;

         Art.Pressure := Pressure(Art) ;

         { Find Systolic/Diastolic pressures }
         Art.MaxPressure := Max(Art.MaxPressure,Art.Pressure) ;
         Art.MinPressure := Min(Art.MinPressure,Art.Pressure) ;

         Art.Flow := (Art.Pressure - Ven.Pressure)*Art.Conductance ;
         Ven.Volume := Ven.Volume + Art.Flow*t.step ;
         Art.Volume := Art.Volume - Art.Flow*t.step ;

         Ven.Pressure := Pressure(Ven) ;
         { Venous system -> heart valve }
         if (Ven.Pressure >= Heart.Pressure) and (Fibrillation <= 0.0)then
            begin
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
     if not Dead  then
        begin
        if Art.Pressure < 20. then Inc(Dying)
                               else Dying := 0 ;
        if Dying = 500 then
           begin
           AddDrugMarker('Your rat has died!!!');
           Dead := True ;
           end ;
        end ;

     j := NumPointsInBuf*scDisplay.NumChannels ;
     Inc(NumPointsInBuf) ;

     ADC[j+chLVP] := Round( Heart.GetLeadingPressure/scDisplay.ChanScale[chLVP]);
     ADC[j+chABP] := Round( Art.GetLeadingPressure/scDisplay.ChanScale[chABP]);
     ADC[j+ChCVP] := Round( Ven.GetLeadingPressure/scDisplay.ChanScale[chCVP]);
     ADC[j+ChHCF] := Round( Con.GetLeadingPressure/scDisplay.ChanScale[chHCF]);
     ADC[j+chHR] := Round( (Heart.Rate*AddNoise(0.05))/scDisplay.ChanScale[chHR]);

     j := NumPointsInBuf*scDisplay.NumChannels ;
     Inc(NumPointsInBuf) ;
     ADC[j+chLVP] := Round( Heart.GetTrailingPressure/scDisplay.ChanScale[chLVP]);
     ADC[j+chABP] := Round( Art.GetTrailingPressure/scDisplay.ChanScale[chABP]);
     ADC[j+ChCVP] := Round( Ven.GetTrailingPressure/scDisplay.ChanScale[chCVP]);
     ADC[j+ChHCF] := Round( Con.GetTrailingPressure/scDisplay.ChanScale[chHCF]);
     ADC[j+chHR] := Round( Heart.Rate/scDisplay.ChanScale[chHR]);

     // Ensure trace does not exceed display range
     for ch := 0 to scDisplay.NumChannels-1 do
         if ADC[j+ch] > scDisplay.Ymax[ch] then scDisplay.Ymax[ch] := scDisplay.Ymax[ch]*1.1 ;


     end ;


procedure TMainForm.cbAgonistChange(Sender: TObject);
// ==============================
// Agonist drug selection changed
// ==============================
begin
    SetDoseList( cbAgonist, cbAgonistDose ) ;
end;


procedure TMainForm.cbAntagonistChange(Sender: TObject);
// ==============================
// Antaonist drug selection changed
// ==============================
begin
    SetDoseList( cbAntagonist, cbAntagonistDose ) ;
end;


procedure TMainForm.cbUnknownChange(Sender: TObject);
// ==============================
// Unknown drug selection changed
// ==============================
begin
    SetDoseList( cbUnknown, cbUnknownDose ) ;
end;


procedure TMainForm.edStartTimeKeyPress(Sender: TObject; var Key: Char);
// ------------------
// Start time changed
// ------------------
begin
    if Key = #13 then
       begin
       sbDisplay.Position := Round(edStartTime.Value) ;
       end;
    end;


procedure TMainForm.edTDisplayKeyPress(Sender: TObject; var Key: Char);
// -------------------------------
// Display window duration changed
// -------------------------------
begin
    if Key = #13 then UpdateDisplayDuration ;
    end;


procedure TElement.CalculatePressureRange( t : single ) ;
begin
     if Pressure <= PressureLo then
        begin
        PressureLo := Pressure ;
        TLo := t ;
        end ;

     if Pressure >= PressureHi then
        begin
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


function TMainForm.Pressure( Element : TElement ) : single ;
var
   P : Single ;
begin
     P := (Element.Volume - Element.Volume0)*Element.Elastance ;
     if P < 0.0 then P := 0.0 ;
     Result := P ;
     end ;


function TMainForm.AddNoise(
         Proportion : single
         ) : single ;
{ -----------------------------------------------
  Create a random scaling factor 1 +/- Proportion
  -----------------------------------------------}
begin
     AddNoise := 1. + ((2.*random)-1. )*Proportion ;
     end ;


Procedure TMainForm.UpdateCirculatingDrug
          ( var Drug : TDrug
          ) ;
{ -------------------------------------------
  Update concentration of drug in circulation
  -------------------------------------------}
begin
     Drug.Dose := Drug.Dose + Drug.OnRate*(Drug.DoseInjected - Drug.Dose)
                            - (Drug.Dose*Drug.RemovalRate);
     Drug.Dose := Max( Drug.Dose, 0.  ) ;
     Drug.DoseInjected := Max( Drug.DoseInjected -
                               Drug.DoseInjected*Drug.RemovalRate, 0. ) ;
     end ;


function TMainForm.ExtractFloat ( CBuf : string ; Default : Single ) : extended ;
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


procedure TMainForm.FormResize(Sender: TObject);
// ----------------------------------------
// Resize form components when size changed
// ----------------------------------------
var
   MinHeight,MinWidth : Integer ;
begin
     MinWidth := TDisplayPanel.Width + 20 ;
     MinHeight := TDisplayPanel.Height + 100 ;
     if ClientHeight < MinHeight then ClientHeight := Minheight ;
     if ClientWidth < MinWidth then ClientWidth := MinWidth ;

     Page.Width := ClientWidth - Page.Left - 5 ;
     Page.Height := ClientHeight - Page.Top - 5 ;

     TDisplayPanel.Top := ChartTab.ClientHeight - TDisplayPanel.Height - 10 ;
     TDisplayPanel.Width := ChartTab.ClientWidth - TDisplayPanel.Left - 10 ;
     bTDisplayDouble.Left := TDisplayPanel.ClientWidth - bTDisplayDouble.Width ;
     edTDisplay.Left := bTDisplayDouble.Left - edTDisplay.Width - 5 ;
     bTDisplayHalf.Left := EdTDisplay.Left - bTDisplayHalf.Width - 5;
     lbTDisplay.Left := bTDisplayHalf.Left - lbTDisplay.Width - 5 ;
     sbDisplay.Width := lbTDisplay.Left - sbDisplay.Left - 5 ;

     scDisplay.Height := TDisplayPanel.Top - scDisplay.Top - 10 ;
     scDisplay.Width := ChartTab.CLientWidth - scDisplay.Left - 10 ;

     ExpImage.Width := Max(Round(PictureTab.ClientWidth*0.9),465) ;
     ExpImage.Height :=  Max(Round(ExpImage.Width*(329.0/465.0)),329) ;
     ExpImage.Left := (PictureTab.ClientWidth - ExpImage.Width) div 2 ;
     ExpImage.Top := (PictureTab.ClientHeight - ExpImage.Height) div 2 ;

     end;


procedure TMainForm.bStopClick(Sender: TObject);
// --------------------
// Stop chart recording
// --------------------
begin

     sbDisplay.Max := NumPointsInBuf - 1 ;
     bStart.Enabled := True ;
     bStop.Enabled := False ;
     mnFile.Enabled := True ;

     end;


procedure TMainForm.bTDisplayDoubleClick(Sender: TObject);
// --------------------------------
// Increase display duration by 25%
// --------------------------------
begin
    edTDisplay.Value := edTDisplay.Value*1.25 ;
    UpdateDisplayDuration ;
    end;


procedure TMainForm.bTDisplayHalfClick(Sender: TObject);
// --------------------------
// Decrease display duration
// --------------------------
begin
    edTDisplay.Value := edTDisplay.Value*(1.0/1.25) ;
    UpdateDisplayDuration ;
    end;


procedure TMainForm.UpdateDisplayDuration ;
// ------------------------------
// Update display window duration
// ------------------------------
begin
    scDisplay.MaxPoints :=  Round(edTDisplay.Value) ;
    scDisplay.XMax := scDisplay.MaxPoints -1 ;
    scDisplay.VerticalCursors[0] := scDisplay.MaxPoints div 2 ;
    scDisplay.NumPoints := NumPointsInBuf - scDisplay.XOffset ;
    scDisplay.invalidate ;
    end;


procedure TMainForm.scDisplayCursorChange(Sender: TObject);
// --------------------------------------------
// Display cursor moved or display zoom changed
// --------------------------------------------
var
    ch : Integer ;
begin
     // Ensure that horizontal cursor remains at zero
     for ch := 0 to scDisplay.NumChannels-1 do
         if scDisplay.YMin[ch] < 0.0 then scDisplay.YMin[ch] := 0.0 ;

end;


procedure TMainForm.bAddAgonistClick(Sender: TObject);
// ----------------------------
// Add selected dose of agonist
// ----------------------------
var
    iDrug : Integer ;
    Dose,Scale : Single ;
    ChartAnnotation,Units : string ;
begin

    iDrug := Integer(cbAgonist.Items.Objects[cbAgonist.ItemIndex]);
    Dose := 1E-6*Integer(cbAgonistDose.Items.Objects[cbAgonistDose.ItemIndex]);

    Drugs[iDrug].DoseInjected := Dose*AddNoise(0.1) ;

    if Dose < 1.0 then
       begin
       Units := 'ug/kg';
       Scale := 1000.0 ;
       end
    else
       begin
       Units := 'mg/kg';
       Scale := 1.0 ;
       end ;

    // Add chart annotation
    ChartAnnotation := format('%s %.3g %s',
                       [Drugs[iDrug].ShortName,Dose*Scale,Units] ) ;
     AddDrugMarker( ChartAnnotation ) ;

end;


procedure TMainForm.bAddAntagonistClick(Sender: TObject);
// -------------------------------
// Add selected dose of antagonist
// -------------------------------
var
    iDrug : Integer ;
    Dose,Scale : Single ;
    ChartAnnotation,Units : string ;
begin

    iDrug := Integer(cbAntagonist.Items.Objects[cbAntagonist.ItemIndex]);
    Dose := 1E-6*Integer(cbAntagonistDose.Items.Objects[cbAntagonistDose.ItemIndex]);
    Drugs[iDrug].DoseInjected := Dose*AddNoise(0.1) ;

    if Dose < 1.0 then
       begin
       Units := 'ug/kg';
       Scale := 1000.0 ;
       end
    else
       begin
       Units := 'mg/kg';
       Scale := 1.0 ;
       end ;

    // Add chart annotation
    ChartAnnotation := format('%s %.3g %s',
                       [Drugs[iDrug].ShortName,Dose*Scale,Units] ) ;
     AddDrugMarker( ChartAnnotation ) ;

end;


procedure TMainForm.bAddUnknownClick(Sender: TObject);
// --------------------------------
// Add selected dose of unknown drug
// ---------------------------------
var
    iDrug : Integer ;
    Dose,Scale : Single ;
    ChartAnnotation,Units : string ;
begin

    iDrug := Integer(cbUnknown.Items.Objects[cbUnknown.ItemIndex]);
    Dose := 1E-6*Integer(cbUnknownDose.Items.Objects[cbUnknownDose.ItemIndex]);
    Drugs[iDrug].DoseInjected := Dose*AddNoise(0.1) ;

    if Dose < 1.0 then
       begin
       Units := 'ug/kg';
       Scale := 1000.0 ;
       end
    else
       begin
       Units := 'mg/kg';
       Scale := 1.0 ;
       end ;

    // Add chart annotation
    ChartAnnotation := format('%s %.3g %s',
                       [Drugs[iDrug].ShortName,Dose*Scale,Units] ) ;
     AddDrugMarker( ChartAnnotation ) ;

end;


procedure TMainForm.bNewExperimentClick(Sender: TObject);
// ---------------------------------
// Start new experiment with new rat
// ---------------------------------
begin
     if MessageDlg('New Experiment! Are you sure?', mtConfirmation,
        [mbYes,mbNo],0) = mrYes then
        begin
        InitializeSimulation ;
        end;

end;

procedure TMainForm.bStartClick(Sender: TObject);
// ---------------------
// Start chart recording
// ---------------------
begin

     bStart.Enabled := False ;
     bStop.Enabled := True ;
     bStart.Enabled := False ;
     mnFile.Enabled := False ;
     // Disable changes to normal/pithed state once experiment started
     gpExperimentType.Enabled := False ;
     UnSavedData := True ;

     end;


procedure TMainForm.bStimulationOnClick(Sender: TObject);
// ---------------------------------
// Stimulate autonomic nerve pathway
// ---------------------------------
var
    ChartAnnotation : string ;
begin

   if rbSympNerve.Checked then
      begin
      // Sympathetic nerves (excluding adrenal) acting on beta1
      Drugs[iSympBloodVessels].DoseInjected := 4.0*Drugs[iSympBloodVessels].Beta1AdR.Potency
                                        *( 0.5 + Alpha2Adr ) ;
      ChartAnnotation := 'Symp.Nv.(blood ves.)';
      end
   else if rbSympNerveToHeart.Checked then
      begin
      // Sympathetic nerves to heart Beta1 and Alpha1 a
      Drugs[iSympHeart].DoseInjected := 5.0*Drugs[iSympHeart].Beta1AdR.Potency
                                        *( 0.5 + Alpha2Adr ) ;
      ChartAnnotation := 'Symp.Nv.(heart)';
      end
   else if rbSympNerveToAdrenals.Checked then
      begin
      // Sympathetic nerves to adrenals
      Drugs[iSympAdrenal].DoseInjected := 2.*Drugs[iSympAdrenal].Beta1AdR.Potency ;
      ChartAnnotation := 'Symp.Nv.(adrenals)';
      end
   else if rbRenalNerve.Checked then
      begin
      // Vagus nerve
      Drugs[iRenalNerve].DoseInjected := 5.*Drugs[iRenalNerve].Angt1R.Potency ;
      ChartAnnotation := 'Renal Nv.';
      end
   else
      begin
      // Sympathetic nerves (excluding adrenal)
      Drugs[iVagusNerve].DoseInjected := 10.0*Drugs[iVagusNerve].VagChR.Potency ;
      ChartAnnotation := 'Vagus Nv.';
      end;


   AddDrugMarker( ChartAnnotation ) ;


end;


procedure TMainForm.mnExitClick(Sender: TObject);
{ -----------------
  Stop the program
  ----------------}
begin
     Close ;
     end ;


procedure TMainForm.mnContentsClick(Sender: TObject);
// -----------------------
//  Help/Contents menu item
//  -----------------------
var
   pWinDir : PChar ;
   FileName : string ;
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


procedure TMainForm.mnCopyDataClick(Sender: TObject);
// ----------------------------------------------------
// Copy sample values of displayed signals to clipboard
// ----------------------------------------------------
begin
     scDisplay.CopyDataToClipboard ;
     end;


procedure TMainForm.mnCopyImageClick(Sender: TObject);
// -----------------------------------------
// Copy image of displayed trace to clipboad
// -----------------------------------------
begin

     scDisplay.ChanCalBar[0] :=  scDisplay.ChanGridSpacing[0] ;
     scDisplay.TCalBar := scDisplay.TimeGridSpacing/scDisplay.TScale ;
     scDisplay.PrinterFontName := 'Arial' ;
     scDisplay.PrinterFontSize := 10 ;
     scDisplay.MetafileWidth := 1000 ;
     scDisplay.MetafileHeight := 600 ;
     scDisplay.PrinterPenWidth := 2 ;
     scDisplay.CopyImageToClipBoard ;

     end;


procedure TMainForm.SaveToFile(
          FileName : String
          ) ;
// ----------------------------
// Save chart recording to file
// ----------------------------
var
   Header : array[1..FileHeaderSize] of ansichar ;
   i : Integer ;
   FileHandle : THandle ;
begin

     FileHandle := FileCreate( FileName ) ;
     if Integer(FileHandle) < 0 then Exit ;

     { Initialise empty header buffer with zero bytes }
     for i := 1 to sizeof(Header) do Header[i] := #0 ;

     AppendInt( Header, 'NPOINTS=', NumPointsInBuf ) ;
     AppendLogical( Header, 'PITHED=', rbPithedRat.Checked ) ;

     AppendInt( Header, 'NMARKERS=', MarkerList.Count ) ;
     for i := 0 to MarkerList.Count-1 do
         begin
         AppendInt( Header, format('MKP%d=',[i]), Integer(MarkerList.Objects[i])) ;
         AppendString( Header, format('MKT%d=',[i]), MarkerList.Strings[i] ) ;
         end ;

     // Write header
     FileWrite( FileHandle, Header, SizeOf(Header)) ;

     // Write chart data
     FileWrite( FileHandle, ADC, NumPointsInBuf*scDisplay.NumChannels*2 ) ;

     // Close file
     FileClose( FileHandle ) ;

     UnSavedData := False ;
     end ;


procedure TMainForm.LoadFromFile(
          FileName : String
          ) ;
// ----------------------------
// Load chart recording from file
// ----------------------------
var
   Header : array[1..FileHeaderSize] of ansichar ;
   i : Integer ;
   FileHandle : Integer ;
   NumMarkers : Integer ;
   MarkerPoint : Integer ;
   MarkerText : String ;
   Pithed : Boolean ;
begin

     NumPointsInBuf := 0 ;

     FileHandle := FileOpen( FileName, fmOpenRead ) ;
     if FileHandle < 0 then Exit ;

     FileSeek( FileHandle, 0, 0 ) ;

     // Clear header
     for i := 1 to High(Header) do Header[i] := #0 ;

     // Read header
     FileRead(FileHandle, Header, Sizeof(Header)) ;

     // Get tissue type
     ReadLogical( Header, 'PITHED=', Pithed ) ;
     rbPithedRat.Checked := Pithed ;

     InitializeSimulation ;

     NumPointsInBuf := 0 ;
     ReadInt( Header, 'NPOINTS=', NumPointsInBuf ) ;

     ReadInt( Header, 'NMARKERS=', NumMarkers ) ;
     MarkerList.Clear ;
     for i := 0 to NumMarkers-1 do
         begin
         ReadInt( Header, format('MKPOINT%d=',[i]), MarkerPoint) ;
         ReadInt( Header, format('MKP%d=',[i]), MarkerPoint) ;
         ReadString( Header, format('MKTEXT%d=',[i]), MarkerText ) ;
         ReadString( Header, format('MKT%d=',[i]), MarkerText ) ;
         MarkerList.AddObject( MarkerText, TObject(MarkerPoint)) ;
         end ;

     if NumPointsInBuf > 0 then
        begin
        FileRead( FileHandle, ADC, NumPointsInBuf*scDisplay.NumChannels*2 ) ;
        end ;

     // Close data file
     FileClose( FileHandle ) ;

     UnsavedData := False ;
     scDisplay.XOffset := -1 ;
     sbDisplay.Position := 0 ;
     sbDisplay.Max := NumPointsInBuf ;
     scDisplay.Invalidate ;

     end ;



procedure TMainForm.mnLoadRatClick(Sender: TObject);
// -------------------------
// Load experiment from file
// -------------------------
begin

    if UnSavedData then
        begin
        if MessageDlg('Existing experiment will be overwritten! Are you sure?', mtConfirmation,
           [mbYes,mbNo],0) = mrNo then Exit ;
        end ;

   OpenDialog.options := [ofPathMustExist] ;
   OpenDialog.FileName := '' ;

   OpenDialog.DefaultExt := DataFileExtension ;
   //OpenDialog.InitialDir := OpenDirectory ;
   OpenDialog.Filter := format( ' Experiment (*%s)|*%s',
                                [DataFileExtension,DataFileExtension]) ;
   OpenDialog.Title := 'Load Experiment ' ;

   // Open selected data file
   if OpenDialog.execute then LoadFromFile( OpenDialog.FileName ) ;

   end;


procedure TMainForm.mnSaveRatClick(Sender: TObject);
// -----------------------
// Save experiment to file
// -----------------------
begin

     { Present user with standard Save File dialog box }
     SaveDialog.options := [ofHideReadOnly,ofPathMustExist] ;
     SaveDialog.FileName := '' ;
     SaveDialog.DefaultExt := DataFileExtension ;
     SaveDialog.Filter := format( '  Experiment (*%s)|*%s',
                                  [DataFileExtension,DataFileExtension]) ;
     SaveDialog.Title := 'Save Experiment' ;

     if SaveDialog.Execute then SaveToFile( SaveDialog.FileName ) ;

     end ;


procedure TMainForm.mnNewRatClick(Sender: TObject);
begin
     if MessageDlg('New Experiment! Are you sure?', mtConfirmation,
        [mbYes,mbNo],0) = mrYes then
        begin
        InitializeSimulation ;
        end;
     end;


procedure TMainForm.mnPrintClick(Sender: TObject);
// ---------------------------
// Print displayed chart trace
// ---------------------------
var
    ch : Integer ;
begin
     PrintFrm.Left := Left + 50 ;
     PrintFrm.Top := Top + 50 ;
     PrintFrm.ShowModal ;
     if PrintFrm.ModalResult = mrOK then
        begin
        scDisplay.PrinterLeftMargin := 25 ;
        scDisplay.PrinterRightMargin := 25 ;
        scDisplay.PrinterTopMargin := 25 ;
        scDisplay.PrinterBottomMargin := 25 ;
        for ch := 0 to scDisplay.NumChannels-1 do
            scDisplay.ChanCalBar[ch] :=  scDisplay.ChanGridSpacing[ch] ;
        scDisplay.TCalBar := scDisplay.TimeGridSpacing/scDisplay.TScale ;
        scDisplay.PrinterFontName := 'Arial' ;
        scDisplay.PrinterFontSize := 10 ;
        scDisplay.PrinterPenWidth := 2 ;
        scDisplay.Print ;
        end ;
     end;


procedure TMainForm.FormActivate(Sender: TObject);
begin

     REsize ;

     end;


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

     Heart.Free ;
     Art.Free ;
     Ven.Free ;
     Con.Free ;

     for i := 0 to High(Drugs) do Drugs[i].Free ;

     end;


constructor TDrug.Create(
          NameIn : String ;
          ShortNameIn : string
          ) ;
// ------------------
// Create drug object
// ------------------
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
      if Potency <> None then
        begin
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

     if iDrug = 0 then
        begin
        Numerator := 0.0 ;
        Denominator := 1.0 ;
        end ;
     if Drug.Efficacy <> None then
        begin
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
      if Potency <> None then
        begin
        Drug.Potency := Potency*AddNoise(0.5) ;
        { Efficacy - 1.0=agonist, 0.0=antagonist }
        Drug.Efficacy := 0.0 ;
        end
     else Drug.Efficacy := None ;
     end ;


function TMainForm.IsAgonist( Drug : TDrug ) : Boolean ;
// ------------------------------------
// Return TRUE if drug is an antagonist
// ------------------------------------
begin

    if Drug.Alpha1AdR.Efficacy > 0.0 then Result := True
    else if Drug.Alpha2AdR.Efficacy > 0.0 then Result := True
    else if Drug.Beta1AdR.Efficacy > 0.0 then Result := True
    else if Drug.Beta2AdR.Efficacy > 0.0 then Result := True
    else if Drug.MusChR.Efficacy > 0.0 then Result := True
    else if Drug.VagChR.Efficacy > 0.0 then Result := True
    else if Drug.NicChR.Efficacy > 0.0 then Result := True
    else if Drug.HMCaChannel.Efficacy > 0.0 then Result := True
    else if Drug.SMCaChannel.Efficacy > 0.0 then Result := True
    else if Drug.AdenR.Efficacy > 0.0 then Result := True
    else if Drug.KChannel.Efficacy > 0.0 then Result := True
    else if Drug.NOX.Efficacy > 0.0 then Result := True
    else if Drug.NOS.Efficacy > 0.0 then Result := True
    else if Drug.Angt1R.Efficacy > 0.0 then Result := True
    else if Drug.Angt2R.Efficacy > 0.0 then Result := True
    else if Drug.BradR.Efficacy > 0.0 then Result := True
    else if Drug.ACE.Efficacy > 0.0 then Result := True
    else if Drug.DigR.Efficacy > 0.0 then Result := True
    else if Drug.PDE.Efficacy > 0.0 then Result := True
    else Result := False ;

    end;


procedure TMainForm.AddDrugMarker(
          ChartAnnotation : String
          ) ;
// ------------------------------
// Add drug addition/wash marker
// ------------------------------
begin
     if MarkerList.Count < MaxMarkers then
        begin
        ChartAnnotation := AnsiReplaceStr( ChartAnnotation, '-00', '-' ) ;
        ChartAnnotation := AnsiReplaceStr( ChartAnnotation, '00E', '0E' ) ;
        MarkerList.AddObject( ChartAnnotation, TObject(NumPointsInBuf) ) ;
        scDisplay.AddMarker( NumPointsInBuf - scDisplay.XOffset, ChartAnnotation ) ;
        end ;
     end ;


procedure TMainForm.PrintSetup1Click(Sender: TObject);
{ ------------------------------------
  Menu - Open printer setup dialog box
  ------------------------------------}
begin
     PrinterSetupDialog.Execute ;
     end;


procedure TMainForm.SetDoseList(
          cbDrug : TComboBox ;
          cbDose : TComboBox ) ;
// -----------------------------
// Create list of available doses
// -----------------------------
var
    iDrug,i : Integer ;
    Scale,Dose : Single ;
    Units : String ;
begin

   cbDose.Clear ;

   if cbDrug.Items.Count > 1 then
      begin
      cbDrug.ItemIndex := Max(cbDrug.ItemIndex,0) ;
      iDrug := Integer(cbDrug.Items.Objects[cbDrug.ItemIndex]) ;
      if Drugs[iDrug].MaxDose <= 1.0 then
         begin
         Scale := 1000.0 ;
         Units := 'ug/kg' ;
         end
      else
         begin
         Scale := 1.0 ;
         Units := 'mg/kg' ;
         end ;

      Dose := Drugs[iDrug].MinDose ;
      cbDose.Clear ;
      while Dose <= Drugs[iDrug].MaxDose do
       begin
       if Dose <= Drugs[iDrug].MaxDose then cbDose.Items.Add( format(' %.2f %s ',[Dose*Scale,Units]) ) ;
       if (2.0*Dose) <= Drugs[iDrug].MaxDose then cbDose.Items.Add( format(' %.1f %s ',[2.0*Dose*Scale,Units]) ) ;
       if (5.0*Dose) <= Drugs[iDrug].MaxDose then cbDose.Items.Add( format(' %.1f %s ',[5.0*Dose*Scale,Units]) ) ;
       Dose := Dose*10.0 ;
       end ;
     cbDose.ItemIndex := 0 ;

     // Add dose in ng/kg in objects field

     for i := 0 to cbDose.Items.Count-1 do
         begin
         Dose := ExtractFLoat( cbDose.Items[i], 0.0 );
         if ContainsText(cbDose.Text,'ug/kg') then Scale := 1000.0
         else if ContainsText(cbDose.Text,'mg/kg') then Scale := 1E6
         else Scale := 1.0 ;
         cbDose.Items.Objects[i] := Tobject(Round(Dose*Scale)) ;
         end;
     end ;
end ;


end.
