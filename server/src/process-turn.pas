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
        Player: I,
        Players: [ player, player, player, ... ],
        Provinces: [ province, province, province, ... ],
      }

   // Players are referenced by their position in those arrays, which
   // we call their IDs.

   // Provinces are referenced by their ID which is given in the JSON
   // object, see below.

   // Each province is a JSON object with the following format:

      {
        ID: number, // the province ID
        Name: 'string...',
        Owner: number, // the player ID, 0..N-1
        Troups: number,
        Neighbours: [ number, number, ... ], // province IDs
      }

   // Each player is a JSON object with the following format:

      {
        Name: 'string...',
      }

   // The turn-for-playerI.json JSON files have the following format:

      { 
        Actions: [ action, action, ... ],
      }

   // Each action is a JSON object with the following format:

      {
        Action: 'move',
        From: number, // province ID
        To: number, // province ID
        Count: number, // number of troops to move
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