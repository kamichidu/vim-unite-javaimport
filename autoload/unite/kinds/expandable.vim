" ----------------------------------------------------------------------------
" File:        autoload/unite/kinds/expandable.vim
" Last Change: 05-Aug-2014.
" Maintainer:  kamichidu <c.kamunagi@gmail.com>
" License:     The MIT License (MIT)
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
" ----------------------------------------------------------------------------
let s:save_cpo = &cpo
set cpo&vim

let s:kind = {
\   'name':           'expandable',
\   'parents':        ['common'],
\   'default_action': 'expand',
\   'action_table':   {},
\}

function! unite#kinds#expandable#define()
    return s:kind
endfunction

let s:kind.action_table.expand= {
\   'description'  : 'open new unite buffer with selected word.',
\   'is_selectable': 0,
\   'is_start': 1,
\}
function! s:kind.action_table.expand.func(candidate)
    call unite#start_script(
    \   [
    \       [
    \           a:candidate.source,
    \           'show_class=1',
    \           'package=' . a:candidate.action__package,
    \       ],
    \   ],
    \)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
