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
   //  state-for-player-ID.json (these are ignored by this program)
   //  turn-for-player-ID.json
   // (where ID is the player ID)

   // The next turn directory should not yet exist (and will be created).

   // The state-for-player-ID.json JSON files are ignored (they are the
   // output from the last turn; see below). The server.json file has
   // the following format:

      {
        Turn: T,
        Players: [ player, player, player, ... ],
        Provinces: [ province, province, province, ... ],
      }

   // Players and provinces are referenced by their ID which is given
   // in the JSON object, see below.

   // Each province is a JSON object with the following format:

      {
        ID: number, // the province ID
        Name: 'string...',
        Owner: 'string', // the player ID
        Troups: number,
        Neighbours: [ number, number, ... ], // province IDs
      }

   // Each player is a JSON object with the following format:

      {
        Name: 'string...',
        ID: 'string...',
      }

   // Player IDs must be 1 to 10 characters long, only characters in
   // the range 'a' to 'z' (lowercase).

   // The turn-for-player-ID.json JSON files have the following format:

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
   // server does nothing. If the files are malformed, they are
   // treated as empty orders. If some orders are invalid, those
   // orders are ignored, but the rest are applied.

   // Otherwise, it outputs new server.json and state-for-player-ID.json
   // files. The server.json file is for internal use (it tracks the
   // server state). The state-for-player-ID.json JSON files have the
   // following format:

      {
        Player: 'id...', // the player ID
        Turn: T, // the turn number, first turn (as output by start-game) is 1
        Players: [ player, player, player, ... ], // see above for format 
        Provinces: [ province, province, province, ... ], // see above for format
      }

   procedure ProcessTurn(const LastTurnDir, NextTurnDir: AnsiString);
   var
      World: TPerilWorldTurn;
   begin
      if (not DirectoryExists(LastTurnDir)) then
         raise Exception.Create('first argument is not a directory that exists');
      if (DirectoryExists(NextTurnDir)) then
         raise Exception.Create('third argument is a directory that exists');
      if (not CreateDir(NextTurnDir)) then
         raise Exception.Create('could not create directory for next turn');
      World := TPerilWorldTurn.Create();
      try
         World.LoadData(LastTurnDir + '/server.json', [pdfProvinces, pdfPlayers, pdfTurnNumber]);
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