{$MODE OBJFPC} { -*- delphi -*- }
{$INCLUDE settings.inc}
unit provinces;

interface

uses
   plasticarrays, genericutils, hashtable, hashfunctions, cardinalhashtable, players;

const
   kInitialTroops = 3;
   kTroopRecruitmentCount = 3;

type
   TProvince = class
    public type
     TArray = specialize PlasticArray <TProvince, TObjectUtils>;
     TTroopHashTable = specialize TPlayerHashTable <Cardinal>;
     TReadOnlyArray = TArray.TReadOnlyView;
    protected
     FName: UTF8String;
     FNeighbours: TArray;
     FID: Cardinal;
     FOwner: TPlayer;
     FTroops: TTroopHashTable;
     function GetOwnerTroops(): Cardinal;
    public
     constructor Create(const Name: UTF8String; const ID: Cardinal; const Owner: TPlayer; const Troops: Cardinal);
     destructor Destroy(); override;
     procedure AddNeighbour(const Neighbour: TProvince);
     function HasNeighbour(const Neighbour: TProvince): Boolean;
     procedure SetID(const NewID: Cardinal);
     procedure AssignInitialPlayer(const Player: TPlayer);
     function CanBeSeenBy(const Player: TPlayer): Boolean;
     function NeighboursCanBeSeenBy(const Player: TPlayer): Boolean;
     function CommitTroops(const Count: Cardinal; const Source: TPlayer): Boolean;
     procedure ReceiveTroops(const Count: Cardinal; const Source: TPlayer);
     procedure ResolveBattles();
     procedure EndTurn();
     property Name: UTF8String read FName;
     property ID: Cardinal read FID;
     property Owner: TPlayer read FOwner;
     property ResidentTroopPopulation: Cardinal read GetOwnerTroops;
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
   FTroops := TTroopHashTable.Create();
   if (Assigned(FOwner)) then
      FTroops[FOwner] := Troops;
end;

destructor TProvince.Destroy();
begin
   FTroops.Free();
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
   Assert(not Assigned(FOwner));
   Assert(Assigned(Player));
   FOwner := Player;
   FTroops[FOwner] := kInitialTroops;
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

function TProvince.GetOwnerTroops(): Cardinal;
begin
   Assert(Assigned(FOwner));
   Assert(FTroops.Count = 1);
   Result := FTroops[FOwner];
end;

function TProvince.CommitTroops(const Count: Cardinal; const Source: TPlayer): Boolean;
begin
   Assert(Source = FOwner);
   Result := FTroops[Source] >= Count;
   if (Result) then
      FTroops[Source] := FTroops[Source] - Count; // $R-
end;

procedure TProvince.ReceiveTroops(const Count: Cardinal; const Source: TPlayer);
begin
   if (FTroops[Source] < High(Cardinal) - Count) then
      FTroops[Source] := FTroops[Source] + Count
   else // $R-
      FTroops[Source] := High(Cardinal);
end;

type
   TBattleEntry = record
      Player: TPlayer;
      Count: Cardinal;
   end;
   BattleUtils = record
      class function Equals(const A, B: TBattleEntry): Boolean; static; inline;
      class function LessThan(const A, B: TBattleEntry): Boolean; static; inline;
      class function GreaterThan(const A, B: TBattleEntry): Boolean; static; inline;
   end;

class function BattleUtils.Equals(const A, B: TBattleEntry): Boolean;
begin
   Assert(False); // only used for PlasticArray.Remove() and PlasticArray.Contains()
   Result := False;
end;

class function BattleUtils.LessThan(const A, B: TBattleEntry): Boolean; static; inline;
begin
   Result := A.Count < B.Count;
end;

class function BattleUtils.GreaterThan(const A, B: TBattleEntry): Boolean; static; inline;
begin
   Result := A.Count > B.Count;
end;

procedure TProvince.ResolveBattles();
var
   Armies: specialize PlasticArray <TBattleEntry, BattleUtils>;
   Army, BestArmy, SecondBestArmy: TBattleEntry;
   Player, Winner: TPlayer;
   RemainingTroops, Count: Cardinal;
begin
   if (FTroops.Count > 1) then
   begin
      Armies.Init();
      for Player in FTroops do
      begin
         Army.Player := Player;
         Army.Count := FTroops[Player];
         Armies.Push(Army);
      end;
      Assert(Armies.Length > 1);
      Armies.Sort();
      BestArmy := Armies.Pop();
      SecondBestArmy := Armies.Pop();
      Winner := BestArmy.Player;
      Assert(BestArmy.Count >= SecondBestArmy.Count);
      RemainingTroops := BestArmy.Count - SecondBestArmy.Count; // $R-
      FTroops.Empty();
      if (RemainingTroops > 0) then
      begin
         FTroops[Winner] := RemainingTroops;
         FOwner := Winner;
      end
      else
         FOwner := nil;
   end
   else
   if (Assigned(FOwner)) then
   begin
      Assert(FTroops.Has(FOwner));
      if (FTroops[FOwner] = 0) then
      begin
         FTroops.Empty();
         FOwner := nil;
      end;
   end
   else
   begin
      Count := 0;
      for Player in FTroops do
      begin
         FOwner := Player;
         Inc(Count);
      end;
      Assert(Count = 1);
   end;
   Assert(FTroops.Count <= 1);
   Assert((FTroops.Count = 0) or (Assigned(FOwner) and (FTroops.Has(FOwner)) and (FTroops[FOwner] > 0)));
end;

procedure TProvince.EndTurn();
begin
   if (Assigned(FOwner)) then
   begin
      if (FTroops[FOwner] < High(Cardinal) - kTroopRecruitmentCount) then
         FTroops[FOwner] := FTroops[FOwner] + kTroopRecruitmentCount
      else // $R-
         FTroops[FOwner] := High(Cardinal);
   end;
end;

end.