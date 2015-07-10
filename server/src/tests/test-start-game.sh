#!/bin/bash
cd "$( dirname "${BASH_SOURCE[0]}" )"
rm -rf start-game/test1/output
../../bin/start-game start-game/test1/world.json start-game/test1/players.json start-game/test1/output || exit 1
ls -al start-game/test1/output
tail -n +1 -- start-game/test1/output/*.json
rm -rf start-game/test1/output
