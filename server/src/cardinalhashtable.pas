{$MODE OBJFPC} { -*- delphi -*- }
{$INCLUDE settings.inc}
unit cardinalhashtable;

interface

uses
   hashtable, genericutils, hashfunctions;

type
   generic TCardinalHashTable <TBar> = class(specialize THashTable <Cardinal, TBar, CardinalUtils>)
    public
     constructor Create(PredictedCount: THashTableSizeInt = 8);
     function GetNewID(): Cardinal;
   end;

implementation

constructor TCardinalHashTable.Create(PredictedCount: THashTableSizeInt = 8);
begin
   inherited Create(@Integer32Hash32, PredictedCount);
end;

function TCardinalHashTable.GetNewID(): Cardinal;
begin
   Assert(Count < High(Cardinal));
   Result := Random(High(Cardinal)); // $R-
   while (Has(Result)) do
   begin
      if (Result = High(Cardinal)) then
         Result := 0
      else
         Inc(Result);
   end;
end;

end.