{$MODE OBJFPC} { -*- delphi -*- }
{$INCLUDE settings.inc}
unit provinces;

interface

uses
   players;

type
   TProvince = class
    protected
     FName: UTF8String;
     FNeighbours: array of TProvince;
     FIndex: Cardinal;
     FOwner: TPlayer;
    public type
     TProvinceArray = array of TProvince;
    public
     constructor Create(const Name: UTF8String);
     procedure AddNeighbour(const Neighbour: TProvince);
     procedure SetID(const NewID: Cardinal);
     procedure AssignInitialPlayer(const Player: TPlayer);
     property Name: UTF8String read FName;
     property ID: Cardinal read FIndex;
     property Owner: TPlayer read FOwner;
     property Neighbours: TProvinceArray read FNeighbours; // XXX make this a read-only view of the array
   end;

implementation

constructor TProvince.Create(const Name: UTF8String);
begin
   FName := Name;
end;

procedure TProvince.AddNeighbour(const Neighbour: TProvince);
begin
   // XXX make this more efficient - e.g. create a wrapper around dynamic arrays that doubles in size whenever it needs to be grown
   SetLength(FNeighbours, Length(FNeighbours)+1);
   FNeighbours[Length(FNeighbours)-1] := Neighbour;
end;

procedure TProvince.SetID(const NewID: Cardinal);
begin
   FIndex := NewID;
end;

procedure TProvince.AssignInitialPlayer(const Player: TPlayer);
begin
   Assert(FOwner = nil);
   FOwner := Player;
end;

end.