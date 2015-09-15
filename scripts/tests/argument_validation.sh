#!/bin/sh

# This fixture tests for correct argument parsing

testBareCall() {
    ./rbbackup.sh >/dev/null 2>&1
    assertEquals 3 $?
}

testBareVersion() {
    ./rbbackup.sh -V >/dev/null 2>&1
    assertEquals 0 $?
}

testClutterVersion() {
    ./rbbackup.sh -Vnq >/dev/null 2>&1
    assertEquals 0 $?
}

testBareHelp() {
    ./rbbackup.sh -h >/dev/null 2>&1
    assertEquals 0 $?
}

testClutterHelp() {
    ./rbbackup.sh -hnq >/dev/null 2>&1
    assertEquals 0 $?
}

testBareVersionHelp() {
    ./rbbackup.sh -hV >/dev/null 2>&1
    assertEquals 0 $?
}

testClutterVersionHelp() {
    ./rbbackup.sh -hVnqi >/dev/null 2>&1
    assertEquals 0 $?
}

testMissingArgConfig() {
    ./rbbackup.sh -nc >/dev/null 2>&1
    assertEquals 3 $?
}

testPropperDryRun() {
    # First generate dummy configuration
    # 1) /tmp/globconf
    # 2) /tmp/targetdir
    # 3) /tmp/targetdir/localhost.conf

    # 2)
    declare targetdir=`mktemp -d`
    if [ $? -ne 0 ]; then
	fail "Creating temporary directory failed!"
    fi

    # 1)
    declare globconf=`mktemp`
    if [ $? -ne 0 ]; then
	fail "Creating temporary file failed!"
    fi
    echo "conf_target_confdir='$targetdir'" >> "$globconf"
    if [ $? -ne 0 ]; then
	fail "Writing to temporary file failed!"
    fi

    # 3)
    touch "$targetdir/localhost.conf"
    if [ $? -ne 0 ]; then
	fail "Creating target configuration file failed!"
    fi

    # Actual test
    ./rbbackup.sh -nq -c "$globconf" localhost >/dev/null 2>&1
    assertEquals 0 $?

    # Cleanup
    rm -rvf "$targetdir"
    rm -vf "$globconf"
}

testPropperDryRunWithReason() {
    # First generate dummy configuration
    # 1) /tmp/globconf
    # 2) /tmp/targetdir
    # 3) /tmp/targetdir/localhost.conf

    # 2)
    declare targetdir=`mktemp -d`
    if [ $? -ne 0 ]; then
	fail "Creating temporary directory failed!"
    fi

    # 1)
    declare globconf=`mktemp`
    if [ $? -ne 0 ]; then
	fail "Creating temporary file failed!"
    fi
    echo "conf_target_confdir='$targetdir'" >> "$globconf"
    if [ $? -ne 0 ]; then
	fail "Writing to temporary file failed!"
    fi

    # 3)
    touch "$targetdir/localhost.conf"
    if [ $? -ne 0 ]; then
	fail "Creating target configuration file failed!"
    fi

    # Actual test
    ./rbbackup.sh -nq -c "$globconf" localhost testing >/dev/null 2>&1
    assertEquals 0 $?

    # Cleanup
    rm -rvf "$targetdir"
    rm -vf "$globconf"
}

testTooManyArgs() {
    ./rbbackup.sh -nq localhost testing toomuch >/dev/null 2>&1
    assertEquals 3 $?
}

testSpecificConfigMissing() {
    ./rbbackup.sh -nc nonExistent test >/dev/null 2>&1
    assertEquals 1 $?
}


. $SHUNIT
