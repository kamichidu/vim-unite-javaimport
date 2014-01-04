" ----------------------------------------------------------------------------
" File:        autoload/unite/kinds/javatype.vim
" Last Change: 04-Jan-2014.
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
let s:save_cpo = &cpo
set cpo&vim

let s:kind = {
\   'name':           'javatype',
\   'parents':        [],
\   'default_action': 'import',
\   'action_table':   {},
\}

function! unite#kinds#javatype#define() " {{{
    return s:kind
endfunction
" }}}
let s:kind.action_table.import= {
\   'description'  : 'add import statement to this buffer.',
\   'is_selectable': 1,
\}
function! s:kind.action_table.import.func(candidates) " {{{
    let l:save_cursorpos= getpos('.')
    try
        let l:canonical_names= map(a:candidates, 'v:val.action__canonical_name')

        call javaimport#add_import_statements(l:canonical_names)
        call javaimport#sort_import_statements()
    finally
        call setpos('.', javaimport#each('v:a + v:b', l:save_cursorpos, [0, 1, 0, 0]))
    endtry
endfunction
" }}}
let s:kind.action_table.preview= {
\   'description'  : 'show javadoc if presented.',
\   'is_quit': 0,
\}
function! s:kind.action_table.preview.func(candidate) " {{{
    if empty(a:candidate.action__javadoc_url)
        return
    endif

    call javaimport#preview(a:candidate.action__javadoc_url)
endfunction
" }}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:foldenable:foldmethod=marker
