{$MODE OBJFPC} { -*- delphi -*- }
{$INCLUDE settings.inc}
program startgame;
uses
   sysutils,
   world,
   exceptions;

   // Command line argument: world file, players file, directory of first turn

   // The first turn directory should be empty (and files in it will be overwritten).

   // The world JSON files have the following format:

      {
        provinces: [ province, province, province, ... ],
      }

   // The players JSON files have the following format:

      {
        players: [ player, player, player, ... ],
      }

   // Provinces and players are referenced by their position in those
   // arrays, which we call their IDs.

   // Each player is a JSON object with the following format:

      {
        name: 'string...',
      }

   procedure StartGame(const ServerFile, PlayerFile, FirstTurnDir: AnsiString);
   var
      World: TPerilWorld;
   begin
      if (not DirectoryExists(FirstTurnDir)) then
         raise Exception.Create('third argument is not a directory that exists');
      World := TPerilWorld.Create();
      try
         World.LoadData(ServerFile, [pdfProvinces]);
         World.LoadData(PlayerFile, [pdfPlayers]);
         if (World.PlayerCount < 2) then
            raise Exception.Create('insufficent number of players specified');
         if (World.PlayerCount > World.ProvinceCount) then
            raise Exception.Create('too many players specified');
         World.DistributePlayers();
         World.RandomiseIDs();
         World.SaveData(FirstTurnDir);
      finally
         World.Free();
      end;
   end;

begin
   Randomize();
   try
      if (ParamCount() <> 3) then
         raise Exception.Create('arguments must be <world-file> <player-file> <first-turn-directory>');
      StartGame(ParamStr(1), ParamStr(2), ParamStr(3));
   except
      on E: Exception do
      begin
         {$IFDEF DEBUG}
            ReportCurrentException();
         {$ELSE}
            Writeln('start-game: ', E.Message);
         {$ENDIF}
         ExitCode := 1;
      end;
   end;
end.