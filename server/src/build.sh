MAIN="start-game" MODE="DEBUG" TESTCMD="src/tests/test-start-game.sh" lib/compile.sh || exit 1
MAIN="process-turn" MODE="DEBUG" TESTCMD="src/tests/test-process-turn.sh" lib/compile.sh || exit 1
