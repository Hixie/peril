{$MODE OBJFPC} { -*- delphi -*- }
{$INCLUDE settings.inc}
unit world;

interface

uses
   provinces, players;

type
   TPerilDataFeatures = (pdfProvinces, pdfPlayers);
   TPerilDataFeaturesSet = set of TPerilDataFeatures;
   TPerilWorld = class
    protected
     FProvinces: array of TProvince;
     FPlayers: array of TPlayer;
     function CountProvinces(): Cardinal;
     procedure AddProvince(const Province: TProvince);
     function CountPlayers(): Cardinal;
     procedure AddPlayer(const Player: TPlayer);
     function Serialise(const Player: TPlayer = nil): UTF8String; // outputs JSON of the world
    public
     constructor Create();
     destructor Destroy(); override;
     procedure LoadData(const FileName: AnsiString; const Features: TPerilDataFeaturesSet);
     procedure DistributePlayers();
     procedure SaveData(const Directory: AnsiString);
     property PlayerCount: Cardinal read CountPlayers;
     property ProvinceCount: Cardinal read CountProvinces;
   end;

implementation

uses
   sysutils, fileutils, arrayutils, math, json;

constructor TPerilWorld.Create();
begin
end;

destructor TPerilWorld.Destroy();
var
   Province: TProvince;
   Player: TPlayer;
begin
   for Province in FProvinces do // $R-
      Province.Free();
   for Player in FPlayers do // $R-
      Player.Free();
end;

procedure TPerilWorld.LoadData(const FileName: AnsiString; const Features: TPerilDataFeaturesSet);
var
   ParsedData, ProvinceData, NeighbourData, PlayerData: TJSON;
   Province: TProvince;
   Player: TPlayer;
   Number: Double;
   ProvinceIndex, NeighbourIndex: Integer;
begin
   ParsedData := ParseJSON(ReadTextFile(FileName));
   try try
      if (pdfProvinces in Features) then
      begin
         Assert(Length(FProvinces) = 0);
         if (Assigned(ParsedData['provinces'])) then
         begin
            for ProvinceData in ParsedData['provinces'] do
               AddProvince(TProvince.Create(ProvinceData['name']));
            ProvinceIndex := 0;
            for ProvinceData in ParsedData['provinces'] do
            begin
               for NeighbourData in ProvinceData['neighbours'] do
               begin
                  Number := NeighbourData;
                  if (Frac(Number) <> 0.0) then
                     raise Exception.Create('syntax error: non-integer neighbour index');
                  NeighbourIndex := Floor(Number);
                  if ((NeighbourIndex < 0) or (NeighbourIndex >= Length(FProvinces))) then
                     raise Exception.Create('syntax error: out of range neighbour index');
                  FProvinces[ProvinceIndex].AddNeighbour(FProvinces[NeighbourIndex]);
               end;
               Inc(ProvinceIndex);
            end;
         end;
      end;
      if (pdfPlayers in Features) then
      begin
         Assert(Length(FPlayers) = 0);
         if (Assigned(ParsedData['players'])) then
            for PlayerData in ParsedData['players'] do
               AddPlayer(TPlayer.Create(PlayerData['name']));
      end;
   except
      for Province in FProvinces do // $R-
         Province.Free();
      for Player in FPlayers do // $R-
         Player.Free();
      raise;
   end;
   finally
      ParsedData.Free();
   end;
end;

procedure TPerilWorld.AddProvince(const Province: TProvince);
begin
   // XXX make this more efficient - e.g. create a wrapper around dynamic arrays that doubles in size whenever it needs to be grown
   SetLength(FProvinces, Length(FProvinces)+1);
   FProvinces[Length(FProvinces)-1] := Province;
end;

procedure TPerilWorld.AddPlayer(const Player: TPlayer);
begin
   // XXX make this more efficient - e.g. create a wrapper around dynamic arrays that doubles in size whenever it needs to be grown
   SetLength(FPlayers, Length(FPlayers)+1);
   FPlayers[Length(FPlayers)-1] := Player;
   Player.SetID(Length(FPlayers)-1); // $R-
end;

procedure TPerilWorld.DistributePlayers();
var
   Index: Cardinal;
begin
   Assert(Length(FProvinces) > 0);
   Assert(Length(FPlayers) > 0);
   Assert(Length(FPlayers) < Length(FProvinces));
   // randomly assign players to provinces
   FisherYatesShuffle(FProvinces[0], Length(FProvinces), SizeOf(TProvince)); // $R-
   for Index := 0 to Length(FPlayers)-1 do // $R-
      FProvinces[Index].AssignInitialPlayer(FPlayers[Index]);
   // reshuffle the array so people can't figure out where people are
   FisherYatesShuffle(FProvinces[0], Length(FProvinces), SizeOf(TProvince)); // $R-
end;

function TPerilWorld.Serialise(const Player: TPlayer = nil): UTF8String;
var
   Province, Neighbour: TProvince;
   CurrentPlayer: TPlayer;
   First, NestedFirst: Boolean;
   Index: Cardinal;
begin
   Index := 0;
   for Province in FProvinces do // $R-
   begin
      if (Assigned(Player) and not Province.CanBeSeenBy(Player)) then
      begin
         FProvinces[Index].UnsetID();
      end
      else
      begin
         FProvinces[Index].SetID(Index);
         Inc(Index);
      end;
   end;
   // XXX this is very inefficient
   Result := '{';
   if (Assigned(Player)) then
      Result := Result + '"player":' + IntToStr(Player.ID) + ',';
   Result := Result + '"provinces":[';
   First := True;
   for Province in FProvinces do // $R-
   begin
      if (Assigned(Player) and not Province.CanBeSeenBy(Player)) then
         continue;
      if (not First) then
         Result := Result + ',';
      Result := Result + '{"name":"' + TJSONString.Escape(Province.Name) + '"';
      if (not Assigned(Player) or Province.NeighboursCanBeSeenBy(Player)) then
      begin
         Result := Result + ',"neighbours":[';
         NestedFirst := True;
         for Neighbour in Province.Neighbours do // $R-
         begin
            if (not NestedFirst) then
               Result := Result + ',';
            Result := Result + IntToStr(Neighbour.ID);
            NestedFirst := False;
         end;
         Result := Result + ']';
      end;
      if (Assigned(Province.Owner)) then
         Result := Result + ',"owner":' + IntToStr(Province.Owner.ID);
      Result := Result + '}';
      First := False;
   end;
   Result := Result + '],"players":[';
   First := True;
   for CurrentPlayer in FPlayers do // $R-
   begin
      if (not First) then
         Result := Result + ',';
      Result := Result + '{"name":"' + TJSONString.Escape(CurrentPlayer.Name) + '"}';
      First := False;
   end;
   Result := Result + ']}';
end;

procedure TPerilWorld.SaveData(const Directory: AnsiString);
var
   Player: TPlayer;
begin
   WriteTextFile(Directory + '/server.json', Serialise());
   for Player in FPlayers do // $R-
      WriteTextFile(Directory + '/player' + IntToStr(Player.ID) + '.json', Serialise(Player));
end;

function TPerilWorld.CountProvinces(): Cardinal;
begin
   Result := Length(FProvinces); // $R-
end;

function TPerilWorld.CountPlayers(): Cardinal;
begin
   Result := Length(FPlayers); // $R-
end;

end.