@echo off

IF NOT EXIST ".deps/" (
    git clone https://github.com/thinca/vim-themis .deps/themis/
    git clone https://github.com/Shougo/unite.vim  .deps/unite/
    git clone https://github.com/kamichidu/vim-javaclasspath .deps/javaclasspath/
)

.deps\themis\bin\themis.bat --runtimepath .deps/unite/ --runtimepath .deps/javaclasspath/ --recursive %*
