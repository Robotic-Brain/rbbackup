#!/bin/bash

# This fixture tests a complete real run

# All paths relative to this directory
DIR="${BASH_SOURCE%/*}"; if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi; DIR=`readlink -m "$DIR"`

# Scratch area
TMP=

# Template root
TEMPLATE="$DIR/templates/dryRun"

# Timestamp info
declare -a TIME=(`date +"%Y"` `date +"%m"` `date +"%d"`)

createConfiguration() {
    # Magic var: DBG_OPEN_TMP
    #            set to 1 to prevent deletion of <TMP> and open in Thunar
    # Magic folders:
    # <TMP>/output     # temporary stdout and stderr for later parsing
    # <TMP>/destdir    # backup storage destination root
    # <TMP>/parsed     # almost exact copy of <TEMPLATE> dir (see substitutions below)
    
    TMP=`mktemp -d` || return 1
    if [ ${DBG_OPEN_TMP:-0} -ne 0 ]; then
        xdg-open "$TMP"
    fi
    echo "INFO: mktmp created directory: '$TMP'"

    # Build substitution list
    local -A l_replaceMe=(
	    ['H']='#'
	    ['TARGET_ROOT_PATH']="$TMP/destdir"
	    ['BACKUP_PATH']="$TMP/destdir/${TIME[0]}/${TIME[1]}/${TIME[2]}/testing"
	    ['FNCTAGS_0']=$RANDOM
	    ['FNCTAGS_1']=$RANDOM
	    ['FNCTAGS_2']=$RANDOM
        ['TMP']="$TMP"
        ['PARSED_ROOT']="$TMP/parsed"
        ['RANDOM']=$RANDOM
        ['START_TIME']=`date +"%s" | head -c -3`
    )
    local l_sedSubs=''
    for i in "${!l_replaceMe[@]}"
    do
	    l_sedSubs+="s:###$i###:${l_replaceMe[$i]}:g"$'\n'
    done

    mkdir -v "$TMP/parsed" | sed -r 's/.*/INFO: &/' || return 1
    (
        cd "$TEMPLATE"
        # for each directory in template directory...
        find . -type d | while IFS= read -r file; do
            mkdir -vp "$TMP/parsed/$file" | sed -r 's/.*/INFO: &/' || return 1
        done
        # for each file in template directory...
        find . -type f | while IFS= read -r file; do
            # ...replace tags and write to scratch dir (or exit when tags missing)
            cp -a "$TEMPLATE/$file" "$TMP/parsed/$file"
            cat "$TEMPLATE/$file" | sed -r -e "$l_sedSubs" -e '/###[^#]+###/ q 1' > "$TMP/parsed/$file"
            if [ $? -ne 0 ]; then
	            fail "Missing substitution!"
	            tail -n1 "$TMP/parsed/$file"
	            return 1
            fi
            echo "INFO: wrote parsed file: $TMP/parsed/$file"
        done
    )

    mkdir -v "$TMP/destdir" | sed -r 's/.*/INFO: &/' || return 1
    mkdir -v "$TMP/output" | sed -r 's/.*/INFO: &/' || return 1

    # dummy last path
    echo "DUMMY PATH" > "$TMP/output/dummyPath"
    cp "$TMP/output/dummyPath" "$TMP/destdir/lastPath"
}

cleanupConfiguration() {
    # Cleanup
    if [ ${DBG_OPEN_TMP:-0} -eq 0 ]; then
        rm -rvf "$TMP" | sed -r 's/.*/INFO: &/'
    fi
}

runtests() {
    # Actual test
    ./rbbackup.sh -ni -c "$TMP/parsed/config/rbbackup.conf" testRun testing >"$TMP/output/out1.log" 2>"$TMP/output/out2.log"
    assertEquals "Exit code" 0 $?       # check exit == 0
    tail -n1 "$TMP/output/out1.log" | grep -i "done" >/dev/null
    assertEquals "last line contains 'Done'" 0 $? # check that it ran till the end
    grep "$TMP/parsed/config/rbbackup.conf" <"$TMP/output/out1.log" | grep "global" >/dev/null
    assertEquals "global config" 0 $?   # check used global configuration
    grep "$TMP/parsed/config/targets/testRun.conf" <"$TMP/output/out1.log" | grep "target" >/dev/null
    assertEquals "target config" 0 $?   # check used target configuration
    
    cat "$TMP/output/out1.log" | awk -f "$TMP/parsed/testSupport/check1.awk"
    assertEquals "hook functions" 0 $?  # check hooks were called in order
    assertTrue "Lock exists?" "[ -f $TMP/destdir/target.lck ]"
    
    # compare directory structure (should be empty)
    ls -lARn "$TMP/destdir/${TIME[0]}/${TIME[1]}/${TIME[2]}/testing" | grep -v "$TMP" > "$TMP/output/ls2.log" || fail "Ls 2 failed"
    cat "$TMP/output/ls2.log" | wc -l | grep -e '^1$' >/dev/null
    assertEquals "Backup structure" 0 $?

    # check that lastPath did not change
    diff -qN "$TMP/output/dummyPath" "$TMP/destdir/lastPath" >/dev/null
    assertEquals "LastPath modified" 0 $?
}

testInitialRun() {
    createConfiguration || fail "Config setup failed!" || exit 1
    runtests
    cleanupConfiguration
}


. $SHUNIT
