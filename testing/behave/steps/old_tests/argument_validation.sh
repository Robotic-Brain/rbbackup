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

testTooManyArgs() {
    ./rbbackup.sh -nq localhost testing toomuch >/dev/null 2>&1
    assertEquals 3 $?
}

testSpecificConfigMissing() {
    ./rbbackup.sh -nc nonExistent test >/dev/null 2>&1
    assertEquals 1 $?
}


. $SHUNIT
