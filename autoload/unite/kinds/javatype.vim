" ----------------------------------------------------------------------------
" File:        autoload/unite/kinds/javatype.vim
" Last Change: 06-Jul-2013.
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

let s:V=    vital#of('unite-javaimport')
let s:HTTP= s:V.import('Web.Http')
let s:HTML= s:V.import('Web.Html')
let s:BM=   s:V.import('Vim.BufferManager').new()
unlet s:V

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
    let l:canonical_name= a:candidates[0].action__canonical_name

    if s:already_exists(l:canonical_name)
        return
    endif

    call append(s:appendable_lnum(), printf('import %s;', l:canonical_name))

    call s:sort_import_statements()

    call setpos('.', javaimport#each('v:a + v:b', l:save_cursorpos, [0, 1, 0, 0]))
endfunction

function! s:sort_import_statements()
    call setpos('.', [0, 1, 1, 0])
    let l:start_lnum= search('^\s*\<import\>', 'cn')

    call setpos('.', [0, line('$'), 1, 0])
    let l:end_lnum= search('^\s*\<import\>', 'cnb')

    execute l:start_lnum.','.l:end_lnum.'sort'
endfunction

function! s:already_exists(class_name)
    let l:imports= filter(getbufline('%', 1, '$'), 'v:val =~# "^\\s*\\<import\\>"')
    let l:same_imports= filter(l:imports, 'match(v:val, "'.a:class_name.'") >= 0')

    return !empty(l:same_imports)
endfunction

function! s:appendable_lnum()
    call setpos('.', [0, 1, 1, 0])

    let l:import_lnum= search('\<import\>', 'cn')
    if l:import_lnum
        return l:import_lnum
    endif

    let l:package_lnum= search('\<package\>', 'cn')
    if l:package_lnum
        return l:package_lnum
    endif

    let l:declaration_lnum= search('\<\(class\|@\?interface\|enum\)\>', 'cn')
    if l:declaration_lnum
        return l:declaration_lnum - 1
    endif

    return 1
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

    let l:response= s:HTTP.get(a:candidate.action__javadoc_url)
    if !l:response.success
        return
    endif

    let l:dom= s:HTML.parse(l:response.content)
    let l:dom= l:dom.find('div', {'class': 'description'})

    call s:BM.open('javadoc preview')
    setlocal bufhidden=hide buftype=nofile noswapfile nobuflisted readonly
    silent % delete _
    silent 1 put =l:dom.value()
    call cursor(1, 1)
endfunction
" }}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:foldenable:foldmethod=marker
