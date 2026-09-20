#!/bin/bash

if ! command -v clisp &> /dev/null; then
    echo "clisp is required. Please install it and run again"
    exit 1
fi

cd ../../
clisp sites/example/example.lisp
