#!/bin/sh

# This fixture tests a complete real run

# All paths relative to this directory
DIR="${BASH_SOURCE%/*}"; if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
TMP=

createConfiguration() {
    # First generate dummy configuration
    # 1) <TMP>/gconf.conf          # global config (passed via -c)
    # 2) <TMP>/tconf               # target config dir (set in global config)
    # 3) <TMP>/tconf/testRun.conf  # test target config
    # 4) <TMP>/destdir             # backup storage destination
    # 5) <TMP>/srcdir              # populated by createExpectedStructure
    # 6) <TMP>/output              # temporary output storage for later parsing
    #    <TMP>/output/out*.log     # output files of command runs
    # 7) <TMP>/output/check*.awk   # checks to run on files
    
    # 0)
    TMP=`mktemp -d` || return 1
    echo "INFO: mktmp created directory: '$TMP'"
    
    # 1)
    echo "conf_target_confdir='$TMP/tconf'" >> "$TMP/gconf.conf"
    
    # 2)
    mkdir -v "$TMP/tconf" | sed -r 's/.*/INFO: &/' || return 1
    
    # 3)
    # Build substitution list
    local -A l_replaceMe=(
	    ['H']='#'
	    ['DEST_DIR']="$TMP/destdir"
	    ['BACKUP_PATH']="$TMP/destdir/"`date +"%Y"`/`date +"%m"`/`date +"%d"`"/testing"
	    ['FNCTAGS_0']=$RANDOM
	    ['FNCTAGS_1']=$RANDOM
	    ['FNCTAGS_2']=$RANDOM
    )
    local l_sedSubs=''
    for i in "${!l_replaceMe[@]}"
    do
	    l_sedSubs+="s:###$i###:${l_replaceMe[$i]}:g"$'\n'
    done
    # replace tags and write to file (or exit when tags missing)
    if [ ! -r "$DIR/templates/realRun/testRun.conf" ]; then
        fail "Missing template file: $DIR/templates/realRun/testRun.conf"
        return 1
    fi
    cat "$DIR/templates/realRun/testRun.conf" | sed -r -e "$l_sedSubs" -e '/###[^#]+###/ q 1' > "$TMP/tconf/testRun.conf"
    if [ $? -ne 0 ]; then
	    fail "Missing substitution!"
	    tail -n1 "$TMP/tconf/testRun.conf"
	    return 1
    fi
    echo "INFO: wrote parsed config file: $TMP/tconf/testRun.conf"
    
    # 4)
    mkdir -v "$TMP/destdir" | sed -r 's/.*/INFO: &/' || return 1

    # 5)
    cp -av "$DIR/templates/realRun/initialFS" "$TMP/srcdir" | sed -r 's/.*/INFO: &/' || return 1

    # 6)
    mkdir -v "$TMP/output" | sed -r 's/.*/INFO: &/' || return 1

    # 7)
    # replace tags and write to file (or exit when tags missing)
    if [ ! -r "$DIR/templates/realRun/check1.awk" ]; then
        fail "Missing template file: $DIR/templates/realRun/check1.awk"
        return 1
    fi
    cat "$DIR/templates/realRun/check1.awk" | sed -r -e "$l_sedSubs" -e '/###[^#]+###/ q 1' > "$TMP/output/check1.awk"
    if [ $? -ne 0 ]; then
	    fail "Missing substitution!"
	    tail -n1 "$TMP/output/check1.awk"
	    return 1
    fi
    echo "INFO: wrote parsed awk script: $TMP/output/check1.awk"
}

cleanupConfiguration() {
    # Cleanup
    rm -rvf "$TMP"
}

runtests() {
    # Actual test
    ./rbbackup.sh -i -c "$TMP/gconf.conf" testRun testing >"$TMP/output/out1.log" 2>"$TMP/output/out2.log"
    assertEquals "Exit code" 0 $?       # check exit == 0
    grep "$TMP/gconf.conf" <"$TMP/output/out1.log" | grep "global" >/dev/null
    assertEquals "global config" 0 $?   # check used global configuration
    grep "$TMP/tconf/testRun.conf" <"$TMP/output/out1.log" | grep "target" >/dev/null
    assertEquals "target config" 0 $?   # check used target configuration
    
    cat "$TMP/output/out1.log" | awk -f "$TMP/output/check1.awk"
    assertEquals "hook functions" 0 $?  # check hooks were called in order
    assertTrue "Lock exists?" "[ -f $TMP/destdir/target.lck ]"

    #ls -l "$destdir" | wc -l | grep "3" >/dev/null
    #assertEquals "Empty destination" 0 $?
}

testInitialRun() {
    createConfiguration || fail "Config setup failed!" || exit 1
    runtests
    #cleanupConfiguration
}


. $SHUNIT
