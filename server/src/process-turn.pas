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
   //  state-for-playerI.json (these are ignored by this program)
   //  turn-for-playerI.json
   // (for I == 0..N-1 where N is the number of players)
   // The next turn directory should be empty (and files in it will be overwritten).

   // The state-for-playerI.json JSON files are ignored (they are the
   // output from the last turn; see below). The server.json file has
   // the following format:

      {
        Turn: T,
        Players: [ player, player, player, ... ],
        Provinces: [ province, province, province, ... ],
      }

   // Players are referenced by their position in the Players array,
   // which we call their IDs.

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
   // server does nothing. If the files are malformed, they are
   // treated as empty orders. If some orders are invalid, those
   // orders are ignored, but the rest are applied.

   // Otherwise, it outputs new server.json and state-for-playerI.json
   // files. The server.json file is for internal use (it tracks the
   // server state). The state-for-playerI.json JSON files have the
   // following format:

      {
        Player: I, // the played ID
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
      if (not DirectoryExists(NextTurnDir)) then
         raise Exception.Create('second argument is not a directory that exists');
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