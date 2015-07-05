# Peril Game Logic

## World Creation

To start a game, call `bin/start-game`. See
[src/start-game.pas](src/start-game.pas) for the arguments to use.

The provinces in the data file passed to `start-game` form a graph
with directed edges. Relationships are not necessarily symmetrical. It
might be possible to go down-river, but not up-river.


## Turns

To process a turn, call:
```
bin/process-turn <lastturn/> <nextturn/>
```

The directories must have files in the format described in
[src/process-turn.pas](src/process-turn.pas).
