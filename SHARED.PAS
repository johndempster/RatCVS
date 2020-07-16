unit Shared;
{ ===============================================================
  CHART - Library of shared procedures and functions V1.1
  ===============================================================
  18/8/98 Windows 95 version
  1/11/99 ExtractFloat corrected to account for use of comma as decimal separator
  9/3/12  Char changed to ANSIChar when moved to Delphi XE2}

interface

uses
  SysUtils, WinTypes, WinProcs, Messages, Classes, Graphics, Controls,
  Forms, Dialogs, StdCtrls, ExtCtrls, Spin, printers {nidaq};

const
     MaxSingle = 1E38 ;



  function ExtractFloat ( CBuf : string ; Default : Single ) : extended ;
  function ExtractInt ( CBuf : string ) : LongInt ;
  procedure AppendFloat(  var Dest : array of ansichar;  Keyword : string ; Value : Extended ) ;
  procedure ReadFloat(  const Source : array of ansichar;  Keyword : string ; var Value : Single ) ;
  procedure AppendInt( var Dest : array of ansichar;  Keyword : string ; Value : LongInt ) ;
  procedure ReadInt(  const Source : array of ansichar;  Keyword : string ; var Value : LongInt ) ;
  procedure AppendLogical( var Dest : array of ansichar;  Keyword : string ; Value : Boolean ) ;
  procedure ReadLogical(  const Source : array of ansichar;  Keyword : string ; var Value : Boolean ) ;
  procedure AppendString( var Dest : Array of ansichar; Keyword, Value : string ) ;
  procedure ReadString( const Source : Array of ansichar; Keyword : string ; var Value : string ) ;

  procedure CopyStringToArray( var Dest : array of ansichar ; Source : string ) ;
  procedure FindParameter( const Source : array of ansichar ;
                                 Keyword : string ;
                                 var Parameter : string ) ;
  function TimeInMilliseconds : LongInt ;
  function PrinterCmToPixels(const Axis : string;cm : single) : Integer ;

implementation

var
    ArrayFull : Boolean ;

{ Extract a floating point number from a string which
  may contain additional non-numeric text }
function ExtractFloat ( CBuf : string ; Default : Single ) : extended ;
var CNum : string ;
i : SmallInt ;

begin
     CNum := ' ' ;
     for i := 1 to length(CBuf) do begin
         if CBuf[i] in ['0'..'9', 'E', 'e', '+', '-', '.', ',' ] then
            CNum := CNum + CBuf[i]
         else CNum := CNum + ' ' ;
         end ;

     { Correct for use of comma/period as decimal separator }
     if (formatsettings.DECIMALSEPARATOR = '.') and (Pos(',',CNum) <> 0) then
        CNum[Pos(',',CNum)] := formatsettings.DECIMALSEPARATOR ;
     if (formatsettings.DECIMALSEPARATOR = ',') and (Pos('.',CNum) <> 0) then
        CNum[Pos('.',CNum)] := formatsettings.DECIMALSEPARATOR ;

     try
        ExtractFloat := StrToFloat( CNum ) ;
     except
        on E : EConvertError do ExtractFloat := Default ;
        end ;
     end ;

{ Extract a 32 bit integer number from a string which
  may contain additional non-numeric text }
function ExtractInt ( CBuf : string ) : longint ;
Type
    TState = (RemoveLeadingWhiteSpace, ReadNumber) ;
var
   CNum : string ;
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

           { Ignore all non-numeric ansicharacters before number }
           RemoveLeadingWhiteSpace : begin
               if CBuf[i] in ['0'..'9','E','e','+','-','.'] then State := ReadNumber
                                                            else i := i + 1 ;
               end ;

           { Copy number into string CNum }
           ReadNumber : begin
                { End copying when a non-numeric ansicharacter
                or the end of the string is encountered }
                if CBuf[i] in ['0'..'9','E','e','+','-','.'] then begin
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

procedure AppendFloat( var Dest : Array of ansichar; Keyword : string ; Value : Extended ) ;
begin
     CopyStringToArray( Dest, Keyword ) ;
     CopyStringToArray( Dest, format( '%11.4e',[Value]) ) ;
     CopyStringToArray( Dest, chr(13) + chr(10) ) ;
     end ;

procedure ReadFloat( const Source : Array of ansichar; Keyword : string ; var Value : Single ) ;
var
Parameter : string ;
begin
FindParameter( Source, Keyword, Parameter ) ;
if Parameter <> '' then Value := ExtractFloat( Parameter, 1. ) ;
end ;


{ Append a long integer point parameter line
  'Keyword' = 'Value' on to end of the header text array}

procedure AppendInt(
          var Dest : Array of ansichar;
          Keyword : string ;
          Value : LongInt ) ;
begin
     CopyStringToArray( Dest, Keyword ) ;
     CopyStringToArray( Dest, InttoStr( Value ) ) ;
     CopyStringToArray( Dest, chr(13) + chr(10) ) ;
     end ;


procedure ReadInt(
          const Source : Array of ansichar;
          Keyword : string ;
          var Value : LongInt ) ;
var
   Parameter : string ;
begin
   FindParameter( Source, Keyword, Parameter ) ;
   if Parameter <> '' then Value := ExtractInt( Parameter ) ;
   end ;

{ Append a text string parameter line
  'Keyword' = 'Value' on to end of the header text array}

procedure AppendString(
          var Dest : Array of ansichar;
          Keyword, Value : string ) ;
begin
     CopyStringToArray( Dest, Keyword ) ;
     CopyStringToArray( Dest, Value ) ;
     CopyStringToArray( Dest, chr(13) + chr(10) ) ;
     end ;


procedure ReadString(
          const Source : Array of ansichar;
          Keyword : string ;
          var Value : string ) ;
var
   Parameter : string ;
begin
     FindParameter( Source, Keyword, Parameter ) ;
     if Parameter <> '' then Value := Parameter  ;
     end ;

{ Append a boolean True/False parameter line
  'Keyword' = 'Value' on to end of the header text array}

procedure AppendLogical(
          var Dest : Array of ansichar;
          Keyword : string ;
          Value : Boolean ) ;
begin
     CopyStringToArray( Dest, Keyword ) ;
     if Value = True then CopyStringToArray( Dest, 'T' )
                     else CopyStringToArray( Dest, 'F' )  ;
     CopyStringToArray( Dest, chr(13) + chr(10) ) ;
     end ;

procedure ReadLogical(
          const Source : Array of ansichar;
          Keyword : string ;
          var Value : Boolean ) ;
var
   Parameter : string ;
begin
     FindParameter( Source, Keyword, Parameter ) ;
     if pos('T',Parameter) > 0 then Value := True
                              else Value := False ;
     end ;

{ Copy a string variable to ansicharacter array
  NOTE. array MUST have been filled with 0 ansicharacters before
        using the function }

procedure CopyStringToArray( var Dest : array of ansichar ; Source : string ) ;
var
   i,j : Integer ;
begin

     { Find end of ansicharacter array }
     j := 0 ;
     while (Dest[j] <> #0) and (j < High(Dest) ) do Inc(j) ;
     if j = 0 then ArrayFull := False ;


     if (j + length(Source)) < High(Dest) then
     begin
          for i := 1 to length(Source) do
          begin
               Dest[j] := ANSIChar(Source[i]) ;
               Inc(j) ;
               end ;
          end
     else if (not ArrayFull) then begin
         ShowMessage( 'File data header full ' ) ;
         ArrayFull := True ;
         end;

     end ;

procedure FindParameter( const Source : array of ansichar ;
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
          if Source[s] = ANSIChar(Keyword[k]) then
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


function PrinterCmToPixels(
         const Axis : string;    { Axis : "X" = horizontal, "Y" = vertical }
         cm : single             { Length (cm) to be converted }
         ) : Integer ;           { Returns length in printer device pixels }
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


end.
