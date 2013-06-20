" ----------------------------------------------------------------------------
" File:        javaimport.vim
" Last Change: 21-Jun-2013.
" Maintainer:  kamichidu <c.kamunagi@gmail.com>
" License:     The MIT License (MIT) {{{
" 
"              Copyright (c) 2013 kamichidu
"
"              Permission is hereby granted, free of charge, to any person
"              obtaining a copy of this software and associated documentation
"              files (the "Software"), to deal in the Software without
"              restriction, including without limitation the rights to use,
"              copy, modify, merge, publish, distribute, sublicense, and/or
"              sell copies of the Software, and to permit persons to whom the
"              Software is furnished to do so, subject to the following
"              conditions:
"
"              The above copyright notice and this permission notice shall be
"              included in all copies or substantial portions of the Software.
"
"              THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
"              EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
"              OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
"              NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
"              HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
"              WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
"              FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
"              OTHER DEALINGS IN THE SOFTWARE.
" }}}
" ----------------------------------------------------------------------------
let s:save_cpo= &cpo
set cpo&vim

let s:source= {
\   'name'           : 'javaimport',
\   'description'    : 'candidates from classes in current classpath.',
\   'sorters'        : ['sorter_word'],
\   'max_candidates' : 100,
\}

function! unite#sources#javaimport#define()
    return s:source
endfunction

function! s:source.gather_candidates(args, context)
    let l:classpaths= s:classpaths()

    let l:types= []
    for l:classpath in l:classpaths
        call extend(l:types, javaimport#gather_class_names(l:classpath))
    endfor

    let l:result= []
    for l:type in l:types
        call add(l:result, {
        \   'word'  : l:type,
        \   'kind'  : 'javatype', 
        \   'source': 'javaimport',
        \   'action__canonical_name': l:type, 
        \})
    endfor

    return l:result
endfunction

function! s:classpaths()
    if !filereadable('.javaimport')
        return []
    endif

    return readfile('.javaimport')
endfunction

let &cpo= s:save_cpo
unlet s:save_cpo

" Exuberant Ctags 5.8, Copyright (C) 1996-2009 Darren Hiebert
"   Compiled: Oct 24 2010, 18:34:59
"   Addresses: <dhiebert@users.sourceforge.net>, http://ctags.sourceforge.net
"   Optional compiled features: +wildcards, +regex
" 
" Usage: ctags [options] [file(s)]
" 
"   -a   Append the tags to an existing tag file.
"   -B   Use backward searching patterns (?...?).
"   -e   Output tag file for use with Emacs.
"   -f <name>
"        Write tags to specified file. Value of "-" writes tags to stdout
"        ["tags"; or "TAGS" when -e supplied].
"   -F   Use forward searching patterns (/.../) (default).
"   -h <list>
"        Specify list of file extensions to be treated as include files.
"        [".h.H.hh.hpp.hxx.h++"].
"   -I <list|@file>
"        A list of tokens to be specially handled is read from either the
"        command line or the specified file.
"   -L <file>
"        A list of source file names are read from the specified file.
"        If specified as "-", then standard input is read.
"   -n   Equivalent to --excmd=number.
"   -N   Equivalent to --excmd=pattern.
"   -o   Alternative for -f.
"   -R   Equivalent to --recurse.
"   -u   Equivalent to --sort=no.
"   -V   Equivalent to --verbose.
"   -x   Print a tabular cross reference file to standard output.
"   --append=[yes|no]
"        Should tags should be appended to existing tag file [no]?
"   --etags-include=file
"       Include reference to 'file' in Emacs-style tag file (requires -e).
"   --exclude=pattern
"       Exclude files and directories matching 'pattern'.
"   --excmd=number|pattern|mix
"        Uses the specified type of EX command to locate tags [mix].
"   --extra=[+|-]flags
"       Include extra tag entries for selected information (flags: "fq").
"   --fields=[+|-]flags
"       Include selected extension fields (flags: "afmikKlnsStz") [fks].
"   --file-scope=[yes|no]
"        Should tags scoped only for a single file (e.g. "static" tags
"        be included in the output [yes]?
"   --filter=[yes|no]
"        Behave as a filter, reading file names from standard input and
"        writing tags to standard output [no].
"   --filter-terminator=string
"        Specify string to print to stdout following the tags for each file
"        parsed when --filter is enabled.
"   --format=level
"        Force output of specified tag file format [2].
"   --help
"        Print this option summary.
"   --if0=[yes|no]
"        Should C code within #if 0 conditional branches be parsed [no]?
"   --<LANG>-kinds=[+|-]kinds
"        Enable/disable tag kinds for language <LANG>.
"   --langdef=name
"        Define a new language to be parsed with regular expressions.
"   --langmap=map(s)
"        Override default mapping of language to source file extension.
"   --language-force=language
"        Force all files to be interpreted using specified language.
"   --languages=[+|-]list
"        Restrict files scanned for tags to those mapped to langauges
"        specified in the comma-separated 'list'. The list can contain any
"        built-in or user-defined language [all].
"   --license
"        Print details of software license.
"   --line-directives=[yes|no]
"        Should #line directives be processed [no]?
"   --links=[yes|no]
"        Indicate whether symbolic links should be followed [yes].
"   --list-kinds=[language|all]
"        Output a list of all tag kinds for specified language or all.
"   --list-languages
"        Output list of supported languages.
"   --list-maps=[language|all]
"        Output list of language mappings.
"   --options=file
"        Specify file from which command line options should be read.
"   --recurse=[yes|no]
"        Recurse into directories supplied on command line [no].
"   --regex-<LANG>=/line_pattern/name_pattern/[flags]
"        Define regular expression for locating tags in specific language.
"   --sort=[yes|no|foldcase]
"        Should tags be sorted (optionally ignoring case) [yes]?.
"   --tag-relative=[yes|no]
"        Should paths be relative to location of tag file [no; yes when -e]?
"   --totals=[yes|no]
"        Print statistics about source and tag files [no].
"   --verbose=[yes|no]
"        Enable verbose messages describing actions on each source file.
"   --version
"        Print version identifier to standard output.

