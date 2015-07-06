#MAIN="test" MODE="DEBUG" lib/compile.sh; exit
#MODE="RELEASE"
MODE="DEBUG"
MAIN="start-game" MODE=$MODE TESTCMD="src/tests/test-start-game.sh" lib/compile.sh || exit 1
MAIN="process-turn" MODE=$MODE TESTCMD="src/tests/test-process-turn.sh" lib/compile.sh || exit 1
