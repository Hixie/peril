#!/bin/bash
cd "$( dirname "${BASH_SOURCE[0]}" )"
rm -rf start-game/test1/output/*.json
../../bin/start-game start-game/test1/world.json start-game/test1/output 4
ls -al start-game/test1/output
cat start-game/test1/output/*.json
