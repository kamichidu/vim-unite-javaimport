#!/usr/bin/bash

if ! [ -d .deps ]; then
    git clone https://github.com/thinca/vim-themis .deps/themis/
    git clone https://github.com/Shougo/unite.vim  .deps/unite/
    git clone https://github.com/kamichidu/vim-javaclasspath .deps/javaclasspath/
fi

./.deps/themis/bin/themis --runtimepath ./.deps/unite/ --runtimepath ./.deps/javaclasspath/ --recursive $*
