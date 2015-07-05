{$MODE OBJFPC} { -*- delphi -*- }
{$INCLUDE settings.inc}
unit world;

interface

uses
   plasticarrays, genericutils, provinces, players;

type
   TPerilDataFeatures = (pdfProvinces, pdfPlayers);
   TPerilDataFeaturesSet = set of TPerilDataFeatures;
   TPerilWorld = class abstract
    protected type
     TPlayerArray = specialize PlasticArray <TPlayer, TObjectUtils>;
    protected
     FProvinces: TProvinceHashTable;
     FPlayers: TPlayerArray;
     function CountProvinces(): Cardinal;
     procedure AddProvince(const Province: TProvince);
     function CountPlayers(): Cardinal;
     procedure AddPlayer(const Player: TPlayer);
     function Serialise(const Player: TPlayer = nil): UTF8String; // outputs JSON of the world
    public
     constructor Create();
     destructor Destroy(); override;
     procedure LoadData(const FileName: AnsiString; const Features: TPerilDataFeaturesSet);
     procedure SaveData(const Directory: AnsiString);
     property PlayerCount: Cardinal read CountPlayers;
     property ProvinceCount: Cardinal read CountProvinces;
   end;

   TPerilWorldCreator = class(TPerilWorld)
    public
     procedure DistributePlayers();
     procedure RandomiseIDs();
   end;

   TPerilWorldTurn = class(TPerilWorld)
    protected type
     TMoveAction = record
        Source, Dest: TProvince;
        Count: Cardinal;
     end;
     TActionArray = specialize PlasticArray <TMoveAction, specialize IncomparableUtils <TMoveAction>>;
    protected
     FInstructions: TActionArray;
    public
     procedure LoadInstructions(const Directory: AnsiString);
     procedure ExecuteInstructions();
   end;

implementation

uses
   sysutils, fileutils, arrayutils, exceptions, json, stringrecorder;

constructor TPerilWorld.Create();
begin
   FProvinces := TProvinceHashTable.Create();
end;

destructor TPerilWorld.Destroy();
var
   Province: TProvince;
   Player: TPlayer;
begin
   try
      for Province in FProvinces.Values do // $R-
         Province.Free();
      FProvinces.Free();
      for Player in FPlayers do // $R-
         Player.Free();
   except
      Writeln('Failure during TPerilWorld.Destroy():');
      ReportCurrentException();
   end;
end;

procedure TPerilWorld.LoadData(const FileName: AnsiString; const Features: TPerilDataFeaturesSet);
var
   ParsedData, ProvinceData, NeighbourData, PlayerData: TJSON;
   Province: TProvince;
   Player, Owner: TPlayer;
   ProvinceIndex, NeighbourIndex: Cardinal;
   ID, OwnerID, Troops: Cardinal;
begin
   ParsedData := ParseJSON(ReadTextFile(FileName));
   try try
      if (pdfPlayers in Features) then
      begin
         Assert(FPlayers.Length = 0);
         if (Assigned(ParsedData['players'])) then
            for PlayerData in ParsedData['players'] do
               AddPlayer(TPlayer.Create(PlayerData['name']));
      end;
      if (pdfProvinces in Features) then
      begin
         Assert(FProvinces.Count = 0);
         if (Assigned(ParsedData['provinces'])) then
         begin
            for ProvinceData in ParsedData['provinces'] do
            begin
               if (Assigned(ProvinceData['id'])) then
                  ID := ProvinceData['id']
               else
                  ID := FProvinces.Count;
               Owner := nil;
               if (Assigned(ProvinceData['owner'])) then
               begin
                  OwnerID := ProvinceData['owner'];
                  if (OwnerID < FPlayers.Length) then
                     Owner := FPlayers[OwnerID];
               end;
               Troops := 0;
               if (Assigned(Owner) and Assigned(ProvinceData['troops'])) then
                  Troops := ProvinceData['troops'];
               AddProvince(TProvince.Create(ProvinceData['name'], ID, Owner, Troops));
            end;
            ProvinceIndex := 0;
            for ProvinceData in ParsedData['provinces'] do
            begin
               if (Assigned(ProvinceData['id'])) then
                  ID := ProvinceData['id']
               else
                  ID := ProvinceIndex;
               Assert(FProvinces.Has(ID));
               for NeighbourData in ProvinceData['neighbours'] do
               begin
                  NeighbourIndex := NeighbourData;
                  if (not FProvinces.Has(NeighbourIndex)) then
                     raise Exception.Create('syntax error: neighbour index unknown');
                  FProvinces[ID].AddNeighbour(FProvinces[NeighbourIndex]);
               end;
               Inc(ProvinceIndex);
            end;
         end;
      end;
   except
      try
         for Province in FProvinces.Values do // $R-
            Province.Free();
         for Player in FPlayers do // $R-
            Player.Free();
      except
         Writeln('Failed to free data during exception handler.');
         ReportCurrentException();
      end;
      Writeln('Failed to parse server state.');
      raise;
   end;
   finally
      ParsedData.Free();
   end;
end;

procedure TPerilWorld.AddProvince(const Province: TProvince);
begin
   FProvinces[Province.ID] := Province;
end;

procedure TPerilWorld.AddPlayer(const Player: TPlayer);
begin
   Player.SetID(FPlayers.Length);
   FPlayers.Push(Player);
end;

function TPerilWorld.Serialise(const Player: TPlayer = nil): UTF8String;
var
   Province, Neighbour: TProvince;
   CurrentPlayer: TPlayer;
   Neighbours: TProvince.TReadOnlyArray;
   Writer: TJSONWriter;
   Index, SubIndex: Cardinal;
   Recorder: TStringRecorderForStrings;
begin
   // XXX this is very inefficient
   Writer := TJSONWriter.Create();
   if (Assigned(Player)) then
      Writer['player'].SetValue(Player.ID);
   Index := 0;
   for Province in FProvinces.Values do // $R-
   begin
      if (Assigned(Player) and not Province.CanBeSeenBy(Player)) then
         continue;
      Writer['provinces'][Index]['id'].SetValue(Province.ID);
      Writer['provinces'][Index]['name'].SetValue(Province.Name);
      if (Assigned(Province.Owner)) then
      begin
         Writer['provinces'][Index]['owner'].SetValue(Province.Owner.ID);
         Writer['provinces'][Index]['troops'].SetValue(Province.TroopCount);
      end;
      if (not Assigned(Player) or Province.NeighboursCanBeSeenBy(Player)) then
      begin
         Neighbours := Province.GetNeighbours();
         try
            SubIndex := 0;
            for Neighbour in Neighbours do // $R-
            begin
               Writer['provinces'][Index]['neighbours'][SubIndex].SetValue(Neighbour.ID);
               Inc(SubIndex);
            end;
         finally
            Neighbours.Free();
         end;
      end;
      Inc(Index);
   end;
   Index := 0;
   for CurrentPlayer in FPlayers do // $R-
   begin
      Writer['players'][Index]['name'].SetValue(CurrentPlayer.Name);
      Inc(Index);
   end;
   Recorder := TStringRecorderForStrings.Create();
   Writer.Serialise(Recorder);
   Result := Recorder.Value;
   Recorder.Free();
   Writer.Free();
end;

procedure TPerilWorld.SaveData(const Directory: AnsiString);
var
   Player: TPlayer;
begin
   WriteTextFile(Directory + '/server.json', Serialise());
   for Player in FPlayers do // $R-
      WriteTextFile(Directory + '/state-for-player' + IntToStr(Player.ID) + '.json', Serialise(Player));
end;

function TPerilWorld.CountProvinces(): Cardinal;
begin
   Result := FProvinces.Count;
end;

function TPerilWorld.CountPlayers(): Cardinal;
begin
   Result := FPlayers.Length;
end;


procedure TPerilWorldCreator.DistributePlayers();
var
   Index: Cardinal;
   ProvinceList: array of TProvince;
   Province: TProvince;
begin
   Assert(FProvinces.Count > 0);
   Assert(FPlayers.Length > 0);
   Assert(FPlayers.Length < FProvinces.Count);
   SetLength(ProvinceList, FProvinces.Count);
   Index := 0;
   for Province in FProvinces.Values do
   begin
      ProvinceList[Index] := Province;
      Inc(Index);
   end;
   // randomly assign players to provinces
   FisherYatesShuffle(ProvinceList[0], Length(ProvinceList), SizeOf(TProvince)); // $R-
   for Index := 0 to FPlayers.Length-1 do // $R-
      ProvinceList[Index].AssignInitialPlayer(FPlayers[Index]);
end;

procedure TPerilWorldCreator.RandomiseIDs();
var
   Province: TProvince;
   NewTable: TProvinceHashTable;
begin
   NewTable := TProvinceHashTable.Create();
   for Province in FProvinces.Values do // $R-
   begin
      Province.SetID(NewTable.GetNewID());
      NewTable.Add(Province.ID, Province);
   end;
   FProvinces.Free();
   FProvinces := NewTable;
end;


procedure TPerilWorldTurn.LoadInstructions(const Directory: AnsiString);
var
   Player: TPlayer;
   ParsedData, ParsedAction: TJSON;
   Action: TMoveAction;
begin
   for Player in FPlayers do // $R-
   begin
      try
         ParsedData := ParseJSON(ReadTextFile(Directory + '/actions-for-player' + IntToStr(Player.ID) + '.json'));
         try
            if (Assigned(ParsedData['actions'])) then
            begin
               for ParsedAction in ParsedData['actions'] do
               begin
                  if (ParsedAction['action'] = 'move') then
                  begin
                     Action.Source := FProvinces[ParsedAction['from']];
                     if (not (Assigned(Action.Source))) then
                        raise ESyntaxError.Create('unknown "from"');
                     if (Action.Source.Owner <> Player) then
                        raise ESyntaxError.Create('unknown "from"');
                     if (not Action.Source.CanBeSeenBy(Player)) then
                        raise ESyntaxError.Create('unknown "from"');
                     Action.Count := ParsedAction['count'];
                     if (Action.Count > Action.Source.TroopCount) then
                        raise ESyntaxError.Create('requested troops unavailable');
                     Action.Dest := FProvinces[ParsedAction['to']];
                     if (not Assigned(Action.Dest)) then
                        raise ESyntaxError.Create('unknown "to"');
                     if (not Action.Source.HasNeighbour(Action.Dest)) then
                        raise ESyntaxError.Create('unknown "to"');
                     if (not Action.Dest.CanBeSeenBy(Player)) then
                        raise ESyntaxError.Create('unknown "to"');
                     XXX;
                  end
                  else
                  begin
                     // Ignore this action, it's an unsupported or bogus type
                     raise ESyntaxError.Create('unknown "action"');
                  end;
               end;
            end;
         finally
            ParsedData.Free();
         end;
      except
         on E: Exception do
         begin
            Writeln('Failed to parse instructions from ', Player.Name);
            ReportCurrentException();
         end;
      end;            
   end;
end;

procedure TPerilWorldTurn.ExecuteInstructions();
begin
   XXX;
end;

end.