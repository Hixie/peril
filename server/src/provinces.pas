{$MODE OBJFPC} { -*- delphi -*- }
{$INCLUDE settings.inc}
unit provinces;

interface

uses
   plasticarrays, genericutils, cardinalhashtable, players;

type
   TProvince = class
    public type
     TArray = specialize PlasticArray <TProvince, TObjectUtils>;
     TReadOnlyArray = TArray.TReadOnlyView;
    protected
     FName: UTF8String;
     FNeighbours: TArray;
     FID: Cardinal;
     FOwner: TPlayer;
    public
     constructor Create(const Name: UTF8String; const ID: Cardinal);
     procedure AddNeighbour(const Neighbour: TProvince);
     procedure SetID(const NewID: Cardinal);
     procedure AssignInitialPlayer(const Player: TPlayer);
     function CanBeSeenBy(const Player: TPlayer): Boolean;
     function NeighboursCanBeSeenBy(const Player: TPlayer): Boolean;
     property Name: UTF8String read FName;
     property ID: Cardinal read FID;
     property Owner: TPlayer read FOwner;
     function GetNeighbours(): TReadOnlyArray;
   end;

type
   TProvinceHashTable = specialize TCardinalHashTable <TProvince>;

implementation

constructor TProvince.Create(const Name: UTF8String; const ID: Cardinal);
begin
   FName := Name;
   FID := ID;
end;

procedure TProvince.AddNeighbour(const Neighbour: TProvince);
begin
   FNeighbours.Push(Neighbour);
end;

procedure TProvince.SetID(const NewID: Cardinal);
begin
   FID := NewID;
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

function TProvince.GetNeighbours(): TArray.TReadOnlyView;
begin
   Result := FNeighbours.GetReadOnlyView();
end;

end.