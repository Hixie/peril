{$MODE OBJFPC} { -*- delphi -*- }
{$INCLUDE settings.inc}
program startgame;
uses
   sysutils,
   world;

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

   procedure StartGame(const ServerFile, FirstTurnDir: AnsiString; PlayerCount: Integer);
   var
      World: TPerilWorld;
   begin
      if (not DirectoryExists(FirstTurnDir)) then
         raise Exception.Create('first argument is not a directory that exists');
      if (PlayerCount < 2) then
         raise Exception.Create('insufficent number of players specified');
      World := TPerilWorld.Create(ServerFile);
      try
         if (PlayerCount > World.ProvinceCount) then
            raise Exception.Create('too many players specified');

      finally
         World.Free();
      end;
   end;


begin
   try
      if (ParamCount() <> 3) then
         raise Exception.Create('arguments must be <world-file> <first-turn-directory> <number of players>');
      StartGame(ParamStr(1), ParamStr(2), StrToInt(ParamStr(3)));
   except
      on E: Exception do
      begin
         Writeln(E.Message);
         ExitCode := 1;
      end;
   end;
end.