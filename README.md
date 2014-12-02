unite-javaimport [![Build Status](https://travis-ci.org/kamichidu/vim-unite-javaimport.svg?branch=master)](https://travis-ci.org/kamichidu/vim-unite-javaimport)
====================================================================================================
Let's try!

![](https://kamichidu.github.com/vim-unite-javaimport/javaimport-00.gif)

How to Install
------------------------------------------------------------------------------------------------------------------------
1. Install [Java Runtime Environment 1.6 or above](http://www.oracle.com/technetwork/java/javase/downloads/)

1. Install [Exuberant Ctags 5.8 or above](http://ctags.sourceforge.net/)

1. Install dependency plugins

    1. [unite.vim](https://github.com/Shougo/unite.vim)

    1. [vimproc.vim](https://github.com/Shougo/vimproc.vim)

    1. [vim-javaclasspath](https://github.com/kamichidu/vim-javaclasspath)

    1. [w3m.vim](https://github.com/yuratomo/w3m.vim)

        This is optional. If you install this plugin, javadoc previewing feature will be enabled.

### neobundle snippet

```vim:simple
NeoBundle 'kamichidu/vim-unite-javaimport', {
\   'depends': [
\       'Shougo/unite.vim',
\       'Shougo/vimproc.vim',
\       'kamichidu/vim-javaclasspath',
\   ],
\}
```

```vim:
NeoBundle 'kamichidu/vim-unite-javaimport', {
\   'depends': [
\       'Shougo/unite.vim',
\       'Shougo/vimproc.vim',
\       'kamichidu/vim-javaclasspath',
\       'yuratomo/w3m.vim',
\   ],
\}
```
