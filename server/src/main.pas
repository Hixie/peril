{$MODE OBJFPC} { -*- delphi -*- }
{$INCLUDE settings.inc}
program peril;
begin
   // Command line argument: directory of last turn, directory of next turn

   // The last turn directory should contain these files:
   //  server.json
   //  state-for-playerI.json
   //  turn-for-playerI.json
   // (for I == 0..N-1 where N is the number of players)
   // The next turn directory should be empty (and files in it will be overwritten).

   // The state-for-playerI.json JSON files have the following format:

      {
        provinces: [ province, province, province, ... ],
        players: [ player, player, player, ... ],
      }

   // Provinces and players are referenced by their position in those
   // arrays, which we call their IDs.

   // Each province is a JSON object with the following format:

      {
        name: 'string...',
        owner: number, // the player ID, 0..N-1
        troups: number,
        neighbours: [ number, number, ... ], // the province IDs
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
        from: number, // provide ID
        to: number, // provide ID
        count: number, // number of troups to move
      }



   *)
end.