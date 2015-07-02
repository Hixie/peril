# Peril Game Logic

## World Creation

To start a game, call:
```
bin/start-game <world.json> <firstturn/> <number-of-players>
```

The world.json file should be of the form:

```json
   { provinces: [ province, province, province, ... ] }
```

...where each province is:

```json
   {
     name: 'string...',
     neighbours: [ number, number, ... ], // the province IDs
   }
```

Province IDs are the index of the province objects in the `provinces` array.


## Turns

To process a turn, call:
```
bin/process-turn <lastturn/> <nextturn/>
```

The directories must have files in the format described in
[src/process-turn.pas](src/process-turn.pas).
