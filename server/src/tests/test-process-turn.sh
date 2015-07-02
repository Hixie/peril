#!/bin/bash
cd "$( dirname "${BASH_SOURCE[0]}" )"
rm -rf process-turn/test1/turn2/*.json
../../bin/process-turn process-turn/test1/turn1 process-turn/test1/turn2
ls -al process-turn/test1/turn2/*
cat process-turn/test1/turn2/*.json
