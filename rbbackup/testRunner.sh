#!/bin/sh

if [ $# -gt 0 ]; then
    
    shopt -s extglob
    GLOBIGNORE='*~'
    
    export SHUNIT=./shunit2/shunit2
    #(./tests/*)

    echo "Starting Fixture $1..."
    ./tests/$1
    
else
    echo "No fixture given!"
    echo "available fixtures:"
    cd ./tests/
    find . -type f ! -name '*~' ! -path './templates/*'
fi
