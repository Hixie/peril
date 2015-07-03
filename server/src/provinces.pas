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
     FID: Integer;
     FOwner: TPlayer;
     function GetID(): Cardinal;
    public type
     TProvinceArray = array of TProvince;
    public
     constructor Create(const Name: UTF8String);
     procedure AddNeighbour(const Neighbour: TProvince);
     procedure UnsetID();
     procedure SetID(const NewID: Cardinal);
     procedure AssignInitialPlayer(const Player: TPlayer);
     function CanBeSeenBy(const Player: TPlayer): Boolean;
     function NeighboursCanBeSeenBy(const Player: TPlayer): Boolean;
     property Name: UTF8String read FName;
     property ID: Cardinal read GetID;
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

procedure TProvince.UnsetID();
begin
   FID := -1;
end;

procedure TProvince.SetID(const NewID: Cardinal);
begin
   Assert(NewID <= High(FID));
   FID := NewID; // $R-
end;

function TProvince.GetID(): Cardinal;
begin
   Assert(FID >= 0);
   Result := FID; // $R-
end;

procedure TProvince.AssignInitialPlayer(const Player: TPlayer);
begin
   Assert(FOwner = nil);
   FOwner := Player;
end;

function TProvince.CanBeSeenBy(const Player: TPlayer): Boolean;
var
   Neighbour: TProvince;
begin
   Result := True;
   if (FOwner = Player) then
      exit;
   for Neighbour in FNeighbours do // $R-
      if (Neighbour.FOwner = Player) then
         exit;
   Result := False;
end;

function TProvince.NeighboursCanBeSeenBy(const Player: TPlayer): Boolean;
begin
   Result := FOwner = Player;
end;

end.