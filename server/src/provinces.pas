{$MODE OBJFPC} { -*- delphi -*- }
{$INCLUDE settings.inc}
unit provinces;

interface

uses
   plasticarrays, genericutils, cardinalhashtable, players;

const
   kInitialTroops = 3;

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
     FTroopCount: Cardinal;
    public
     constructor Create(const Name: UTF8String; const ID: Cardinal; const Owner: TPlayer; const Troops: Cardinal);
     procedure AddNeighbour(const Neighbour: TProvince);
     function HasNeighbour(const Neighbour: TProvince): Boolean;
     procedure SetID(const NewID: Cardinal);
     procedure AssignInitialPlayer(const Player: TPlayer);
     function CanBeSeenBy(const Player: TPlayer): Boolean;
     function NeighboursCanBeSeenBy(const Player: TPlayer): Boolean;
     property Name: UTF8String read FName;
     property ID: Cardinal read FID;
     property Owner: TPlayer read FOwner;
     property TroopCount: Cardinal read FTroopCount;
     function GetNeighbours(): TReadOnlyArray;
   end;

type
   TProvinceHashTable = specialize TCardinalHashTable <TProvince>;

implementation

constructor TProvince.Create(const Name: UTF8String; const ID: Cardinal; const Owner: TPlayer; const Troops: Cardinal);
begin
   FName := Name;
   FID := ID;
   FOwner := Owner;
   FTroopCount := Troops;
end;

procedure TProvince.AddNeighbour(const Neighbour: TProvince);
begin
   FNeighbours.Push(Neighbour);
end;

function TProvince.HasNeighbour(const Neighbour: TProvince): Boolean;
begin
   Result := FNeighbours.Contains(Neighbour);
end;

procedure TProvince.SetID(const NewID: Cardinal);
begin
   FID := NewID;
end;

procedure TProvince.AssignInitialPlayer(const Player: TPlayer);
begin
   Assert(FOwner = nil);
   FOwner := Player;
   FTroopCount := kInitialTroops;
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