{$MODE OBJFPC} { -*- delphi -*- }
{$INCLUDE settings.inc}
program processturn;
uses
   sysutils,
   exceptions,
   world;

   // Command line argument: directory of last turn, directory of next turn

   // The last turn directory should contain these files:
   //  server.json
   //  state-for-playerI.json
   //  turn-for-playerI.json
   // (for I == 0..N-1 where N is the number of players)
   // The next turn directory should be empty (and files in it will be overwritten).

   // The state-for-playerI.json JSON files have the following format:

      {
        player: I,
        provinces: [ province, province, province, ... ],
        players: [ player, player, player, ... ],
      }

   // Players are referenced by their position in those arrays, which
   // we call their IDs.

   // Provinces are referenced by their ID which is given in the JSON
   // object, see below.

   // Each province is a JSON object with the following format:

      {
        id: number, // the province ID
        name: 'string...',
        owner: number, // the player ID, 0..N-1
        troups: number,
        neighbours: [ number, number, ... ], // province IDs
      }

   // Each player is a JSON object with the following format:

      {
        name: 'string...',
      }

   // The turn-for-playerI.json JSON files have the following format:

      { 
        actions: [ action, action, ... ],
      }

   // Each action is a JSON object with the following format:

      {
        action: 'move',
        from: number, // province ID
        to: number, // province ID
        count: number, // number of troops to move
      }

   // If there are insufficient turn files for the last turn, then the
   // server does nothing.

   procedure ProcessTurn(const LastTurnDir, NextTurnDir: AnsiString);
   var
      World: TPerilWorldTurn;
   begin
      if (not DirectoryExists(LastTurnDir)) then
         raise Exception.Create('first argument is not a directory that exists');
      if (not DirectoryExists(NextTurnDir)) then
         raise Exception.Create('second argument is not a directory that exists');
      World := TPerilWorldTurn.Create();
      try
         World.LoadData(LastTurnDir + '/server.json', [pdfProvinces, pdfPlayers]);
         World.LoadInstructions(LastTurnDir);
         World.ExecuteInstructions();
         World.SaveData(NextTurnDir);
      finally
         World.Free();
      end;
   end;

begin
   try
      if (ParamCount() <> 2) then
         raise Exception.Create('arguments must be <last-turn-directory> <next-turn-directory>');
      ProcessTurn(ParamStr(1), ParamStr(2));
   except
      on E: Exception do
      begin
         {$IFDEF DEBUG}
            Writeln('Unexpected failure in process-turn:');
            ReportCurrentException();
         {$ELSE}
            Writeln('process-turn: ', E.Message);
         {$ENDIF}
         ExitCode := 1;
      end;
   end;
end.