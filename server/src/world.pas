{$MODE OBJFPC} { -*- delphi -*- }
{$INCLUDE settings.inc}
unit world;

interface

uses
   plasticarrays, genericutils, provinces, players;

type
   TPerilDataFeatures = (pdfProvinces, pdfPlayers, pdfTurnNumber);
   TPerilDataFeaturesSet = set of TPerilDataFeatures;
   TPerilWorld = class abstract
    protected type
     TPlayerArray = specialize PlasticArray <TPlayer, TObjectUtils>;
    protected
     FProvinces: TProvinceHashTable;
     FPlayers: TPlayerIDHashTable;
     FTurnNumber: Cardinal;
     function CountProvinces(): Cardinal;
     procedure AddProvince(const Province: TProvince);
     function CountPlayers(): Cardinal;
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
        Player: TPlayer;
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
   FPlayers := TPlayerIDHashTable.Create();
end;

destructor TPerilWorld.Destroy();
var
   Province: TProvince;
   Player: TPlayer;
begin
   try
      for Province in FProvinces.Values do // $R-
      begin
         Assert(Assigned(Province));
         Province.Free();
      end;
   except
      Writeln('Failure during TPerilWorld.Destroy(), freeing provinces:');
      ReportCurrentException();
   end;
   try
      FProvinces.Free();
   except
      Writeln('Failure during TPerilWorld.Destroy(), freeing provinces hash table:');
      ReportCurrentException();
   end;
   try
      for Player in FPlayers.Values do // $R-
      begin
         Assert(Assigned(Player));
         Player.Free();
      end;
   except
      Writeln('Failure during TPerilWorld.Destroy(), freeing players:');
      ReportCurrentException();
   end;
   try
      FPlayers.Free();
   except
      Writeln('Failure during TPerilWorld.Destroy(), freeing players hash table:');
      ReportCurrentException();
   end;
end;

procedure TPerilWorld.LoadData(const FileName: AnsiString; const Features: TPerilDataFeaturesSet);

   function IsValidPlayerID(PlayerID: UTF8String): Boolean;
   var
      Index: Cardinal;
   begin
      Result := False;
      if (Length(PlayerID) > 10) then
         exit;
      if (Length(PlayerID) < 1) then
         exit;
      for Index := 1 to Length(PlayerID) do // $R-
         if (not (PlayerID[Index] in ['a'..'z'])) then
            exit;
      Result := True;
   end;

var
   ParsedData, ProvinceData, NeighbourData, PlayerData: TJSON;
   Owner: TPlayer;
   ProvinceIndex, NeighbourIndex: Cardinal;
   ID, Troops: Cardinal;
   OwnerID, PlayerID, PlayerName: UTF8String;
begin
   ParsedData := ParseJSON(ReadTextFile(FileName));
   try
      if (pdfPlayers in Features) then
      begin
         Assert(FPlayers.Count = 0);
         if (Assigned(ParsedData['Players'])) then
         begin
            for PlayerData in ParsedData['Players'] do
            begin
               if (not Assigned(PlayerData['ID'])) then
                  raise Exception.Create('syntax error: missing player ID');
               PlayerID := PlayerData['ID'];
               if (not IsValidPlayerID(PlayerID)) then
                  raise Exception.Create('syntax error: invalid player ID');
               if (FPlayers.Has(PlayerID)) then
                  raise Exception.Create('syntax error: duplicate player ID');
               if (Assigned(PlayerData['Name'])) then
                  PlayerName := PlayerData['Name']
               else
                  PlayerName := '';
               FPlayers[PlayerID] := TPlayer.Create(PlayerName, PlayerID);
            end;
         end;
      end;
      if (pdfProvinces in Features) then
      begin
         Assert(FProvinces.Count = 0);
         if (Assigned(ParsedData['Provinces'])) then
         begin
            for ProvinceData in ParsedData['Provinces'] do
            begin
               if (Assigned(ProvinceData['ID'])) then
                  ID := ProvinceData['ID']
               else
                  ID := FProvinces.Count;
               Owner := nil;
               if (Assigned(ProvinceData['Owner'])) then
               begin
                  OwnerID := ProvinceData['Owner'];
                  if ((not IsValidPlayerID(OwnerID)) or (not FPlayers.Has(OwnerID))) then
                     raise Exception.Create('syntax error: reference to undeclared player');
                  Owner := FPlayers[OwnerID];
               end;
               Troops := 0;
               if (Assigned(Owner) and Assigned(ProvinceData['Troops'])) then
                  Troops := ProvinceData['Troops'];
               AddProvince(TProvince.Create(ProvinceData['Name'], ID, Owner, Troops));
            end;
            ProvinceIndex := 0;
            for ProvinceData in ParsedData['Provinces'] do
            begin
               if (Assigned(ProvinceData['ID'])) then
                  ID := ProvinceData['ID']
               else
                  ID := ProvinceIndex;
               Assert(FProvinces.Has(ID));
               for NeighbourData in ProvinceData['Neighbours'] do
               begin
                  NeighbourIndex := NeighbourData;
                  if (not FProvinces.Has(NeighbourIndex)) then
                     raise Exception.Create('syntax error: unknown neighbour ID');
                  FProvinces[ID].AddNeighbour(FProvinces[NeighbourIndex]);
               end;
               Inc(ProvinceIndex);
            end;
         end;
      end;
      if (pdfTurnNumber in Features) then
      begin
         if (Assigned(ParsedData['Turn'])) then
            FTurnNumber := ParsedData['Turn'];
      end;
   finally
      ParsedData.Free();
   end;
end;

procedure TPerilWorld.AddProvince(const Province: TProvince);
begin
   FProvinces[Province.ID] := Province;
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
   Writer['Turn'].SetValue(FTurnNumber);
   if (Assigned(Player)) then
      Writer['Player'].SetValue(Player.ID);
   Index := 0;
   for Province in FProvinces.Values do // $R-
   begin
      if (Assigned(Player) and not Province.CanBeSeenBy(Player)) then
         continue;
      Writer['Provinces'][Index]['ID'].SetValue(Province.ID);
      Writer['Provinces'][Index]['Name'].SetValue(Province.Name);
      if (Assigned(Province.Owner)) then
      begin
         Writer['Provinces'][Index]['Owner'].SetValue(Province.Owner.ID);
         Writer['Provinces'][Index]['Troops'].SetValue(Province.ResidentTroopPopulation);
      end;
      if (not Assigned(Player) or Province.NeighboursCanBeSeenBy(Player)) then
      begin
         Neighbours := Province.GetNeighbours();
         try
            SubIndex := 0;
            for Neighbour in Neighbours do // $R-
            begin
               Writer['Provinces'][Index]['Neighbours'][SubIndex].SetValue(Neighbour.ID);
               Inc(SubIndex);
            end;
         finally
            Neighbours.Free();
         end;
      end;
      Inc(Index);
   end;
   Index := 0;
   for CurrentPlayer in FPlayers.Values do // $R-
   begin
      Writer['Players'][Index]['Name'].SetValue(CurrentPlayer.Name);
      Writer['Players'][Index]['ID'].SetValue(CurrentPlayer.ID);
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
   for Player in FPlayers.Values do // $R-
      WriteTextFile(Directory + '/state-for-player-' + Player.ID + '.json', Serialise(Player));
end;

function TPerilWorld.CountProvinces(): Cardinal;
begin
   Result := FProvinces.Count;
end;

function TPerilWorld.CountPlayers(): Cardinal;
begin
   Result := FPlayers.Count;
end;


procedure TPerilWorldCreator.DistributePlayers();
var
   Index: Cardinal;
   ProvinceList: array of TProvince;
   Province: TProvince;
   Player: TPlayer;
begin
   Assert(FProvinces.Count > 0);
   Assert(FPlayers.Count > 0);
   Assert(FPlayers.Count < FProvinces.Count);
   SetLength(ProvinceList, FProvinces.Count);
   Index := 0;
   for Province in FProvinces.Values do
   begin
      ProvinceList[Index] := Province;
      Inc(Index);
   end;
   // randomly assign players to provinces
   FisherYatesShuffle(ProvinceList[0], Length(ProvinceList), SizeOf(TProvince)); // $R-
   Index := 0;
   for Player in FPlayers.Values do // $R-
   begin
      ProvinceList[Index].AssignInitialPlayer(Player);
      Inc(Index);
   end;
   FTurnNumber := 1;
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
   for Player in FPlayers.Values do // $R-
   begin
      try
         ParsedData := ParseJSON(ReadTextFile(Directory + '/actions-for-player-' + Player.ID + '.json'));
         try
            if (Assigned(ParsedData['Actions'])) then
            begin
               for ParsedAction in ParsedData['Actions'] do
               begin
                  try
                     if (ParsedAction['Action'] = 'move') then
                     begin
                        Action.Player := Player;
                        Action.Source := FProvinces[ParsedAction['From']];
                        if (not (Assigned(Action.Source))) then
                           raise ESyntaxError.Create('unknown "from"');
                        if (Action.Source.Owner <> Player) then
                           raise ESyntaxError.Create('unknown "from"');
                        if (not Action.Source.CanBeSeenBy(Player)) then
                           raise ESyntaxError.Create('unknown "from"');
                        Action.Dest := FProvinces[ParsedAction['To']];
                        if (not Assigned(Action.Dest)) then
                           raise ESyntaxError.Create('unknown "to"');
                        if (not Action.Source.HasNeighbour(Action.Dest)) then
                           raise ESyntaxError.Create('unknown "to"');
                        if (not Action.Dest.CanBeSeenBy(Player)) then
                           raise ESyntaxError.Create('unknown "to"');
                        if (Action.Source = Action.Dest) then
                           raise ESyntaxError.Create('"from" and "to" are the same');
                        Action.Count := ParsedAction['Count'];
                        if (not Action.Source.CommitTroops(Action.Count, Player)) then
                           raise ESyntaxError.Create('overcommited troops');
                        FInstructions.Push(Action);
                     end
                     else
                     begin
                        // Ignore this action, it's an unsupported or bogus type
                        raise ESyntaxError.Create('unknown "action"');
                     end;
                  except
                     on E: Exception do
                     begin
                        Writeln('Failed to parse action in instructions from ', Player.Name);
                        ReportCurrentException();
                     end;
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
var
   Action: TMoveAction;
   Province: TProvince;
begin
   Inc(FTurnNumber);
   for Action in FInstructions do
      Action.Dest.ReceiveTroops(Action.Count, Action.Player);
   for Province in FProvinces.Values do
      Province.ResolveBattles();
   for Province in FProvinces.Values do
      Province.EndTurn();
end;

end.