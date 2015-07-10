{$MODE OBJFPC} { -*- delphi -*- }
{$INCLUDE settings.inc}
program startgame;
uses
   sysutils,
   world,
   exceptions;

   // Command line argument: world file, players file, directory of first turn

   // The first turn directory should not yet exist and will be created.

   // The world JSON files have the following format:

      {
        Provinces: [ province, province, province, ... ],
      }

   // Each province is a JSON object with the following format:

      {
        Name: 'string...',
        Neighbours: [ number, number, ... ], // province IDs
      }

   // Provinces are referenced by their position in the Provinces
   // array, which we call their ID.

   // The players JSON files have the following format:

      {
        Players: [ player, player, player, ... ],
      }

   // Each player is a JSON object with the following format:

      {
        Name: 'string...',
        id: 'string', // 1-10 character string with only 'a' to 'z' characters
      }

   // This program outputs the same format of data as process-turn
   // (qv), with the Turn field set to 1.

   procedure StartGame(const ServerFile, PlayerFile, FirstTurnDir: AnsiString);
   var
      World: TPerilWorldCreator;
   begin
      if (DirectoryExists(FirstTurnDir)) then
         raise Exception.Create('third argument is a directory that exists');
      if (not CreateDir(FirstTurnDir)) then
         raise Exception.Create('could not create directory for first turn');
      World := TPerilWorldCreator.Create();
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