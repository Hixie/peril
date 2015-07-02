{$MODE OBJFPC} { -*- delphi -*- }
{$INCLUDE settings.inc}
unit provinces;

interface

type
   TProvince = class
    protected
     FName: UTF8String;
     FNeighbours: array of TProvince;
    public
     constructor Create(const Name: UTF8String);
     procedure AddNeighbour(const Neighbour: TProvince);
   end;

implementation

constructor TProvince.Create(const Name: UTF8String);
begin
   FName := Name;
end;

procedure AddNeighbour(const Neighbour: TProvince);
begin
   // XXX make this more efficient - e.g. create a wrapper around dynamic arrays that doubles in size whenever it needs to be grown
   SetLength(FNeighbours, Length(FNeighbours)+1);
   FNeighbours[Length(FNeighbours)-1] := Neighbour;
end;

end.