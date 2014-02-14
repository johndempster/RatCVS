unit Shared;
{ Library of shared procedures and functions V1.0 7/1/95 }
{ 3/5/01 ExtractFloat now works with comma decimal separator}
// 9/5/03 Decimal separator now included in EXTRACTINT and EXTRACTFLOAT
interface

uses
  SysUtils, WinTypes, WinProcs, Messages, Classes, Graphics, Controls,
  Forms, Dialogs, StdCtrls, ExtCtrls, Spin, Global;

type
TCED1902 = record
           ComPort : LongInt ;
           InUse : Boolean ;
           Input : LongInt ;
           InputName : string[16] ;
           Gain : LongInt ;
           GainValue : Single ;
           HPFilter : LongInt ;
           HPFilterValue : Single ;
           LPFilter : LongInt ;
           LPFilterValue : Single ;
           NotchFilter : LongInt ;
           ACCoupled : LongInt ;
           end ;

  TADCRange = string[20] ;

  var
  CED1902 : TCED1902 ;

  function ExtractFloat ( CBuf : string ; Default : Single ) : extended ;
  function ExtractInt ( CBuf : string ) : LongInt ;
  procedure AppendFloat(  var Dest : array of char;  Keyword : string ; Value : Extended ) ;
  procedure ReadFloat(  const Source : array of char;  Keyword : string ; var Value : Single ) ;
  procedure AppendInt( var Dest : array of char;  Keyword : string ; Value : LongInt ) ;
  procedure ReadInt(  const Source : array of char;  Keyword : string ; var Value : LongInt ) ;
  procedure AppendLogical( var Dest : array of char;  Keyword : string ; Value : Boolean ) ;
  procedure ReadLogical(  const Source : array of char;  Keyword : string ; var Value : Boolean ) ;
  procedure AppendString( var Dest : Array of char; Keyword, Value : string ) ;
  procedure ReadString( const Source : Array of char; Keyword : string ; var Value : string ) ;

  procedure CopyStringToArray( var Dest : array of char ; Source : string ) ;
  procedure FindParameter( const Source : array of char ;
                                 Keyword : string ;
                                 var Parameter : string ) ;
  function MinInt( const Buf : array of LongInt ) : LongInt ;
  function MaxInt( const Buf : array of LongInt ) : LongInt ;
  function MinFlt( const Buf : array of Single ) : Single ;
  function MaxFlt( const Buf : array of Single ) : Single ;

  Procedure GetADCVoltageRangeOptions( var RangeOptions : array of TADCRange ; var NumOptions : Integer) ;
  procedure ADCToMemory( var ADCBuf : array of integer ;
                           nChannels : LongInt ;
                           nSamples : LongInt ;
                           var dt : Single ;
                           ADCVoltageRange : Single ;
                           WaitForExtTrigger : Boolean ;
                           CircularBuffer : Boolean  ) ;
  procedure MemoryToDAC( var DACBuf : array of integer ;
                           nChannels : LongInt ;
                           nPoints : LongInt ;
                           dt : Single ;
                           NumRepeats : Integer ) ;
  procedure StopDAC( FinalDACValues : array of Single ; nChannels : LongInt ) ;
  procedure StopADC ;
  Function GetLabInterfaceInfo : String ;
  Function ReadADC( Channel : Integer ; ADCVoltageRange : Single ) : Integer ;

  procedure CheckError( Err : Integer ) ;
  Function IntraceptBoxPresent : Boolean ;
  procedure TransmitLine( ComHandle : Integer ; const Line : string ) ;
  function  ReceiveLine(  ComHandle : Integer ) : string ;
  procedure SetCED1902( const CED1902 : TCED1902 ) ;
  function TimeInMilliseconds : LongInt ;


implementation

{$I \nidaqwin\tp_ex\WDAQ_TP.inc}

const
     MaxSingle = 1E38 ;

function ExtractFloat (
         CBuf : string ;     { ASCII text to be processed }
         Default : Single    { Default value if text is not valid }
         ) : extended ;
{ -------------------------------------------------------------------
  Extract a floating point number from a string which
  may contain additional non-numeric text
  28/10/99 ... Now handles both comma and period as decimal separator
  -------------------------------------------------------------------}

var
   CNum : string ;
   i : integer ;
   Done,NumberFound : Boolean ;
begin
     { Extract number from othr text which may be around it }
     CNum := '' ;
     Done := False ;
     NumberFound := False ;
     i := 1 ;
     repeat
         if CBuf[i] in ['0'..'9', 'E', 'e', '+', '-', '.', ',',
                        DecimalSeparator ] then begin
            CNum := CNum + CBuf[i] ;
            NumberFound := True ;
            end
         else if NumberFound then Done := True ;
         Inc(i) ;
         if i > Length(CBuf) then Done := True ;
         until Done ;

     { Correct for use of comma/period as decimal separator }
     if (DECIMALSEPARATOR = '.') and (Pos(',',CNum) <> 0) then
        CNum[Pos(',',CNum)] := DECIMALSEPARATOR ;
     if (DECIMALSEPARATOR = ',') and (Pos('.',CNum) <> 0) then
        CNum[Pos('.',CNum)] := DECIMALSEPARATOR ;

     { Convert number from ASCII to real }
     try
        if Length(CNum)>0 then ExtractFloat := StrToFloat( CNum )
                          else ExtractFloat := Default ;
     except
        on E : EConvertError do ExtractFloat := Default ;
        end ;
     end ;


{ Extract a 32 bit integer number from a string which
  may contain additional non-numeric text }
function ExtractInt ( CBuf : string ) : longint ;
Type
TState = (RemoveLeadingWhiteSpace, ReadNumber) ;
var CNum : string ;
i : integer ;
Quit : Boolean ;
State : TState ;

begin
CNum := '' ;
i := 1;
Quit := False ;
State := RemoveLeadingWhiteSpace ;
while not Quit do begin

     case State of

     { Ignore all non-numeric characters before number }
     RemoveLeadingWhiteSpace : begin
         if CBuf[i] in ['0'..'9','E','e','+','-','.',
                        DecimalSeparator] then State := ReadNumber
                                          else i := i + 1 ;
         end ;

     { Copy number into string CNum }
     ReadNumber : begin
         { End copying when a non-numeric character
           or the end of the string is encountered }
         if CBuf[i] in ['0'..'9','E','e','+','-','.',DecimalSeparator] then begin
                 CNum := CNum + CBuf[i] ;
                 i := i + 1 ;
                 end
             else Quit := True ;
         end ;
     else end ;

     if i > Length(CBuf) then Quit := True ;
     end ;
     try
        ExtractInt := StrToInt( CNum ) ;
     except
        ExtractInt := 1 ;
        end ;
end ;

{ Append a floating point parameter line
  'Keyword' = 'Value' on to end of the header text array}

procedure AppendFloat( var Dest : Array of char; Keyword : string ; Value : Extended ) ;
begin
CopyStringToArray( Dest, Keyword ) ;
CopyStringToArray( Dest, FloattoStr( Value ) ) ;
CopyStringToArray( Dest, chr(13) + chr(10) ) ;
end ;

procedure ReadFloat( const Source : Array of char; Keyword : string ; var Value : Single ) ;
var
Parameter : string ;
begin
FindParameter( Source, Keyword, Parameter ) ;
if Parameter <> '' then Value := ExtractFloat( Parameter, 1. ) ;
end ;


{ Append a long integer point parameter line
  'Keyword' = 'Value' on to end of the header text array}

procedure AppendInt( var Dest : Array of char; Keyword : string ; Value : LongInt ) ;
begin
CopyStringToArray( Dest, Keyword ) ;
CopyStringToArray( Dest, InttoStr( Value ) ) ;
CopyStringToArray( Dest, chr(13) + chr(10) ) ;
end ;

procedure ReadInt( const Source : Array of char; Keyword : string ; var Value : LongInt ) ;
var
Parameter : string ;
begin
FindParameter( Source, Keyword, Parameter ) ;
if Parameter <> '' then Value := ExtractInt( Parameter ) ;
end ;

{ Append a text string parameter line
  'Keyword' = 'Value' on to end of the header text array}

procedure AppendString( var Dest : Array of char; Keyword, Value : string ) ;
begin
CopyStringToArray( Dest, Keyword ) ;
CopyStringToArray( Dest, Value ) ;
CopyStringToArray( Dest, chr(13) + chr(10) ) ;
end ;

procedure ReadString( const Source : Array of char; Keyword : string ; var Value : string ) ;
var
Parameter : string ;
begin
FindParameter( Source, Keyword, Parameter ) ;
if Parameter <> '' then Value := Parameter  ;
end ;

{ Append a boolean True/False parameter line
  'Keyword' = 'Value' on to end of the header text array}

procedure AppendLogical( var Dest : Array of char; Keyword : string ; Value : Boolean ) ;
begin
CopyStringToArray( Dest, Keyword ) ;
if Value = True then CopyStringToArray( Dest, 'T' )
                else CopyStringToArray( Dest, 'F' )  ;
CopyStringToArray( Dest, chr(13) + chr(10) ) ;
end ;

procedure ReadLogical( const Source : Array of char; Keyword : string ; var Value : Boolean ) ;
var
Parameter : string ;
begin
FindParameter( Source, Keyword, Parameter ) ;
if pos('T',Parameter) > 0 then Value := True
                          else Value := False ;
end ;

{ Copy a string variable to character array
  NOTE. array MUST have been filled with 0 characters before
        using the function }

procedure CopyStringToArray( var Dest : array of char ; Source : string ) ;
var
   i,j : Integer ;
begin

     { Find end of character array }
     j := 0 ;
     while (Dest[j] <> chr(0)) and (j < High(Dest) ) do j := j + 1 ;

     if (j + length(Source)) < High(Dest) then
     begin
          for i := 1 to length(Source) do
          begin
               Dest[j] := Source[i] ;
               j := j + 1 ;
               end ;
          end
     else
         MessageDlg( ' Array Full ', mtWarning, [mbOK], 0 ) ;

     end ;

procedure FindParameter( const Source : array of char ;
                               Keyword : string ;
                               var Parameter : string ) ;
var
s,k : integer ;
Found : boolean ;
begin

     { Search for the string 'keyword' within the
       array 'Source' }

     s := 0 ;
     k := 1 ;
     Found := False ;
     while (not Found) and (s < High(Source)) do
     begin
          if Source[s] = Keyword[k] then
          begin
               k := k + 1 ;
               if k > length(Keyword) then Found := True
               end
               else k := 1;
         s := s + 1;
         end ;

    { Copy parameter value into string 'Parameter'
      to be returned to calling routine }

    Parameter := '' ;
    if Found then
    begin
        while (Source[s] <> chr(13)) and (s < High(Source)) do
        begin
             Parameter := Parameter + Source[s] ;
             s := s + 1
             end ;
        end ;
    end ;


function MinInt( const Buf : array of LongInt ) : LongInt ;
{ Return the smallest value in the array 'Buf' }
var
i,Min : LongInt ;
begin
     Min := High(Min) ;
     for i := 0 to High(Buf) do
         if Buf[i] < Min then Min := Buf[i] ;
     Result := Min ;
     end ;

function MaxInt( const Buf : array of LongInt ) : LongInt ;
{ Return the largest value in the array 'Buf' }
var
i,Max : LongInt ;
begin
     Max:= Low(Max) ;
     for i := 0 to High(Buf) do
         if Buf[i] > Max then Max := Buf[i] ;
     Result := Max ;
     end ;

function MinFlt( const Buf : array of Single ) : Single ;
{ Return the smallest value in the array 'Buf' }
var
i : LongInt ;
Min : Single ;
begin
     Min := MaxSingle ;
     for i := 0 to High(Buf) do
         if Buf[i] < Min then Min := Buf[i] ;
     Result := Min ;
     end ;


function MaxFlt( const Buf : array of Single ) : Single ;
{ Return the largest value in the array 'Buf' }
var
   i : LongInt ;
   Max : Single ;
begin
     Max:= -MaxSingle ;
     for i := 0 to High(Buf) do
         if Buf[i] > Max then Max := Buf[i] ;
     Result := Max ;
     end ;


    Procedure GetADCVoltageRangeOptions( var RangeOptions : array of TADCRange ; var NumOptions : Integer) ;
    { Return a string array of A/D converter input voltage ranges }
    begin
         RangeOptions[0] := ' ±5.0 V ' ;
         RangeOptions[1] := ' ±2.5 V ' ;
         RangeOptions[2] := ' ±1.0 V ' ;
         RangeOptions[3] := ' ±0.5 V ' ;
         RangeOptions[4] := ' ±0.25 V ' ;
         RangeOptions[5] := ' ±0.1 V ' ;
         RangeOptions[6] := ' ±0.05 V ' ;
         NumOptions := 7
         end ;

    { Start A/D converter sampling }
    procedure ADCToMemory( var ADCBuf : array of integer ;
                           nChannels : LongInt ;
                           nSamples : LongInt ;
                           var dt : Single ;
                           ADCVoltageRange : Single ;
                           WaitForExtTrigger : Boolean ;
                           CircularBuffer : Boolean  ) ;
    const
    EmptyFlag = 32767 ;
    var
    TimeBase,err,Channel,Gain,i,NumDACChannels : Integer ;
    ClockInterval : array[-1..5] of Single ;
    ClockTicks : word ;
    SamplingInterval : Double ;
    begin
         Err := DAQ_Clear(1) ; { Reset Lab. Interface }
         CheckError(Set_DAQ_Mode(1,1)) ;

         { Determine sampling clock time-base and number of ticks }
         SamplingInterval := dt / nChannels ;
         CheckError(DAQ_Rate (SamplingInterval,1,Timebase,ClockTicks )) ;
         ClockInterval[-1] := 2E-6 ;
         ClockInterval[0] := 1E-6 ;
         ClockInterval[1] := 1E-6 ;
         ClockInterval[2] := 1E-5 ;
         ClockInterval[3] := 1E-4 ;
         ClockInterval[4] := 1E-5 ;
         ClockInterval[5] := 1E-2 ;
         dt := ClockTicks * ClockInterval[TimeBase] * nChannels ;

         { Set recording trigger mode }
         if WaitForExtTrigger then
             CheckError(DAQ_Config( 1,1,0))        { Wait for Ext. Trigger pulse }
             else CheckError(DAQ_Config( 1,0,0)) ; { Start A/D conversion immediately }

         {If in 'CircularBuffer' mode set A/D converter to continue
          indefinitely filling ADC buffer }
         if CircularBuffer then CheckError(DAQ_DB_Config(1, 1))
                           else CheckError(DAQ_DB_Config(1, 0)) ;

         { Fill A/D data buffer with empty flag }
         for i := 0 to (nSamples*nChannels)-1 do ADCBuf[i] := EmptyFlag ;

         { Set internal gain for A/D converter's programmable amplifier }
         Gain := Trunc( 5.001 / ADCVoltageRange ) ;

         if nChannels < 2 then begin
              { Single A/D channel sampling }
              Channel := 0 ;
              CheckError(DAQ_Start(1, Channel, Gain, @ADCBuf, nSamples, Timebase,
                                      ClockTicks )) ;
              end
        else begin
             { Multiple A/D channel sampling }
             CheckError(LAB_ISCAN_Start( 1, nChannels, Gain, @ADCBuf,
                        nSamples*nChannels,TimeBase,ClockTicks,0));
             end ;


        end ;

        { Warn User if the NIDAQ Lab. interface library
          returns an error }
        procedure CheckError( Err : Integer ) ;
        begin
        if Err <> 0 then MessageDlg(
           ' Lab. Interface Error = ' + IntToStr(Err),
           mtWarning, [mbOK], 0 ) ;
        end ;


{ Start D/A converter output }
procedure MemoryToDAC( var DACBuf : array of integer ;
                           nChannels : LongInt ;
                           nPoints : LongInt ;
                           dt : Single ;
                           NumRepeats : Integer ) ;
var
UpdateInterval : double ;
TimeBase,Stopped,Err : Integer ;
ClockTicks,ItersDone,PointsDone : LongInt ;
Channels : array[0..1] of Integer ;
pDAC : ^Integer ;
pC : PInteger ;

begin

     {Err := WFM_Group_Control(1,1,NumRepeats)}
     { Set D/A update clock }
     UpdateInterval := dt ;
     CheckError(WFM_Rate( UpdateInterval, 1,Timebase,ClockTicks));
     CheckError(WFM_ClockRate(1,1,0,TimeBase,ClockTicks,0));

     { Set up D/A channel selection array }
     Channels[0] := 0 ;
     Channels[1] := 1;

     { Load D/A data into output buffer }
     pDAC := @DACBuf[0] ;
     pC := @Channels[0] ;
     CheckError(WFM_Load( 1,nChannels,pC,pDAC,nPoints,NumRepeats,0)) ;

     { Begin D/A output sequence }
     CheckError(WFM_Group_Control(1,1,1)) ;
     end ;

procedure StopDAC( FinalDACValues : array of Single ; nChannels : LongInt ) ;
var
   Err,ch : Integer ;
begin
     { Stop D/A output }
     Err := WFM_Group_Control(1,1,0) ;
     { Output the final D/A values }
     for ch := 0 to nChannels-1 do
         CheckError( AO_VWrite(1,ch,
                     Trunc(FinalDACValues[ch]*MaxDACValue/MaxDACVolts) )  ) ;
     end ;

Procedure StopADC ;
{ Reset A/D conversion sub-system }
var
   Err : Integer ;
begin
     Err := DAQ_Clear(1) ;
     end ;

Function GetLabInterfaceInfo : String ;
var
   Err, BoardCode, BaseAddr, IRQLev1, IRQLev2, IRQTriggerMode, DMALev1,
   DMALev2, daqMode : Integer ;
   BoardName : array[0..30] of String[14] ;
begin

   Err := Get_DA_Brds_Info( 1, BoardCode, BaseAddr, IRQLev1, IRQLev2,
                            IRQTriggerMode, DMALev1, DMALev2, daqMode ) ;

   BoardName[0] := 'MIO-16L-9' ;
   BoardName[1] := 'MIO-16L-15' ;
   BoardName[2] := 'MIO-16L-25 ' ;
   BoardName[3] := '??' ;
   BoardName[4] := 'MIO-16H-9' ;
   BoardName[5] := 'MIO-16H-15' ;
   BoardName[6] := 'MIO-16H-25' ;
   BoardName[7] := 'DIO-24' ;
   BoardName[8] := 'DIO-32F' ;
   BoardName[9] := 'LAB-PC' ;
   BoardName[10] := 'EISA-A2000' ;
   BoardName[11] := 'AT-MIO-16F-5' ;
   BoardName[12] := 'PC-DIO-96' ;
   BoardName[13] := 'PC-LPM-16';
   BoardName[14] := 'PC-TIO-10' ;
   BoardName[15] := 'AT-AO-6' ;
   BoardName[16] := 'AT-A2150S' ;
   BoardName[17] := 'AT-DSP2200 64K' ;
   BoardName[18] := 'AT-DSP2200' ;
   BoardName[19] := 'AT-MIO-16X' ;
   BoardName[20] := 'AT-MIO-64F-5' ;
   BoardName[21] := 'AT-MIO-16DL-9' ;
   BoardName[22] := 'AT-MIO-16DL-25' ;
   BoardName[23] := 'AT-MIO-16DH-9' ;
   BoardName[24] := 'AT-MIO-16DH-25' ;
   BoardName[26] := 'AT-AO-10' ;
   BoardName[25] := '??' ;
   BoardName[27] := 'AT-A2150C' ;
   BoardName[28] := 'Lab-PC+' ;
   if BoardCode >= 0 then Result := 'Interface Card: ' + BoardName[BoardCode]
                     else Result := 'No Interface Board ' ;
   end ;

Function ReadADC( Channel : Integer ; ADCVoltageRange : Single ) : Integer ;
var
   ADCREading, Gain : Integer ;
begin
     { Set internal gain for A/D converter's programmable amplifier }
     Gain := Trunc( 5.001 / ADCVoltageRange ) ;
     CheckError( AI_Read( 1, Channel, Gain, ADCReading ) ) ;
     ReadADC := ADCReading ;
     end ;

Function IntraceptBoxPresent : Boolean ;
const
     InPort=0 ;
     OutPort=1 ;
var
     Pattern : Integer ;
begin
     { Configure port 0 (A) as input }
     CheckError( DIG_Prt_Config( 1,InPort,0,0) ) ;
     { Configure port 1 (B) as output }
     CheckError( DIG_Prt_Config( 1,OutPort,0,1) ) ;

     { Bit 7 On, Bit 6 Off }
     CheckError( Dig_Out_Port( 1,OutPort,$80 ) );
     CheckError( Dig_In_Port( 1,InPort,Pattern ) );
     if (Pattern and $C0) = $40 then begin
        { Bit & Off, Bit 6 On }
        CheckError( Dig_Out_Port( 1,OutPort,$40 ) );
        CheckError( Dig_In_Port( 1,InPort,Pattern ) );
        if (Pattern and $C0) = $80 then IntraceptBoxPresent := True 
                                   else IntraceptBoxPresent := False ;
        end
     else IntraceptBoxPresent := False ;
     end ;


procedure TransmitLine( ComHandle : Integer ; const Line : string ) ;
var
i,nC,nWritten : Integer ;
xBuf : array[0..258] of char ;
begin
     nC := Length(Line) ;
     for i := 1 to nC do xBuf[i-1] := Line[i] ;
     xBuf[nC] := chr(13) ;
     nWritten := WriteComm( ComHandle, xBuf, nC+1 ) ;
     end ;

function ReceiveLine( ComHandle : Integer ) : string ;
var
nRead : Integer ;
Line : string ;
rBuf : array[0..1] of char ;
begin
     Line := '' ;
     repeat
        rBuf[0] := ' ' ;
        nRead := ReadComm( ComHandle, rBuf, 1 ) ;
        if nRead > 0 then begin
           if (rBuf[0] <> chr(13)) and (rBuf[0]<>chr(10)) then
                                   Line := Line + rBuf[0] ;
           end ;
        until rBuf[0] = chr(13) ;
     Result := Line ;
     end ;

procedure SetCED1902( const CED1902 : TCED1902 ) ;
{ Transmit new gain/filter settings to CED 1902 amplifier }
var
ComHandle,Err,cStart : Integer ;
Buf : array[0..40] of char ;
DCB : TDCB ;
begin

     if (CED1902.ComPort > 0) and
        (CED1902.ComPort < 3) and
        CED1902.InUse then begin

          { Set Com port to match requirements of CED 1902 }

          StrPCopy( Buf, 'COM'+IntToStr(CED1902.ComPort) ) ;

          ComHandle := OpenComm( Buf ,256,256) ;
          Err := BuildCommDCB( 'COM1:9600,e,7,1', DCB );
          DCB.Id := ComHandle ;
          Err := SetCommState( DCB ) ;

         { Problem Here ?? First command to 1902 getting ignored }
         TransmitLine(ComHandle, 'IP' + IntToStr(CED1902.Input) + ';') ;

         TransmitLine(ComHandle, 'IP' + IntToStr(CED1902.Input) + ';') ;
         TransmitLine(ComHandle, 'GN' + IntToStr(CED1902.Gain) + ';') ;
         TransmitLine(ComHandle, 'LP' + IntToStr(CED1902.LPFilter) + ';') ;
         TransmitLine(ComHandle, 'HP' + IntToStr(CED1902.HPFilter) + ';') ;
         TransmitLine(ComHandle, 'AC' + IntToStr(CED1902.ACCoupled) + ';') ;
         TransmitLine(ComHandle, 'NF' + IntToStr(CED1902.NotchFilter) + ';') ;

         Err := CloseComm( ComHandle ) ;
         end ;
     end ;

function TimeInMilliseconds : LongInt ;
{ Returns current time of day in milliseconds }
var
Hour,Min,Sec,Msec : Word ;
lHour, lMin, lSec, lMsec : LongInt ;
begin
     DecodeTime( Time, Hour, Min, Sec, Msec ) ;
     lHour := Hour ;
     lMin := Min ;
     lSec := Sec ;
     lmsec := Msec ;
     TimeInMilliseconds := lMSec + (lSec + 60*lMin + 3600*lHour)*1000 ;
     end ;

end.
