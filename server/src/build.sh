#MAIN="test" MODE="DEBUG" lib/compile.sh; exit
MODE="DEBUG"
MAIN="start-game" MODE=$MODE TESTCMD="src/tests/test-start-game.sh" lib/compile.sh || exit 1
MAIN="process-turn" MODE=$MODE TESTCMD="src/tests/test-process-turn.sh" lib/compile.sh || exit 1

# 32-bin binaries:
#MODE="RELEASE
#export PATH=/usr/local/bin:/usr/bin:/bin:~/bin:~/bin/fpc-32/trunk/bin/:~/bin/gdb/bin/:~/bin/valgrind/bin/bin
#cp -f ~/bin/fpc-32/fpc.cfg ~/.fpc.cfg
#MAIN="start-game" MODE=$MODE TESTCMD="echo" lib/compile.sh || exit 1
#MAIN="process-turn" MODE=$MODE TESTCMD="echo" lib/compile.sh || exit 1
#cp -f ~/bin/fpc/fpc.cfg ~/.fpc.cfg
