" The MIT License (MIT)
"
" Copyright (c) 2014 kamichidu
"
" Permission is hereby granted, free of charge, to any person obtaining a copy
" of this software and associated documentation files (the "Software"), to deal
" in the Software without restriction, including without limitation the rights
" to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
" copies of the Software, and to permit persons to whom the Software is
" furnished to do so, subject to the following conditions:
"
" The above copyright notice and this permission notice shall be included in
" all copies or substantial portions of the Software.
"
" THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
" IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
" FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
" AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
" LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
" OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
" THE SOFTWARE.
let s:save_cpo= &cpo
set cpo&vim

"
" package kind
"
let s:package= {
\   'name': 'javaimport/package',
\   'parents': ['common'],
\   'default_action': 'expand',
\   'action_table': {},
\}

let s:package.action_table.expand= {
\   'description': 'Open new unite buffer with selected package.',
\   'is_selectable': 0,
\   'is_start': 1,
\}
function! s:package.action_table.expand.func(candidate)
    call unite#start_script([['javaimport/class']], {'custom_javaimport_package': a:candidate.action__package})
endfunction

"
" class kind
"
let s:class = {
\   'name': 'javaimport/class',
\   'parents': ['common'],
\   'default_action': 'import',
\   'action_table': {},
\}

let s:class.action_table.import= {
\   'description': 'Import selected classes.',
\   'is_selectable': 1,
\}
function! s:class.action_table.import.func(candidates)
    call javaimport#import(map(copy(a:candidates), "{
    \   'class': v:val.action__class,
    \}"))
endfunction

let s:class.action_table.expand= {
\   'description': 'Open new unite buffer with selected class.',
\   'is_selectable': 0,
\   'is_start': 1,
\}
function! s:class.action_table.expand.func(candidate)
    call unite#start_script(
    \   [['javaimport/field'], ['javaimport/method']],
    \   {
    \       'custom_javaimport_package': a:candidate.action__package,
    \       'custom_javaimport_class': split(a:candidate.action__class, '\.')[-1],
    \   }
    \)
endfunction

let s:class.action_table.preview= {
\   'description': 'Show javadoc if presented.',
\   'is_quit': 0,
\}
function! s:class.action_table.preview.func(candidate)
    if empty(a:candidate.action__javadoc_url)
        return
    endif

    call javaimport#preview(a:candidate.action__javadoc_url)
endfunction

"
" field kind
"
let s:field = {
\   'name': 'javaimport/field',
\   'parents': ['common'],
\   'default_action': 'import',
\   'action_table': {},
\}

let s:field.action_table.import= {
\   'description': 'Import selected fields.',
\   'is_selectable': 1,
\}
function! s:field.action_table.import.func(candidates)
    call javaimport#import(map(copy(a:candidates), "{
    \   'class': v:val.action__class,
    \   'field': v:val.action__field,
    \}"))
endfunction

"
" method kind
"
let s:method = {
\   'name': 'javaimport/method',
\   'parents': ['common'],
\   'default_action': 'import',
\   'action_table': {},
\}

let s:method.action_table.import= {
\   'description': 'Import selected methods.',
\   'is_selectable': 1,
\}
function! s:method.action_table.import.func(candidates)
    call javaimport#import(map(copy(a:candidates), "{
    \   'class': v:val.action__class,
    \   'method': v:val.action__method,
    \}"))
endfunction

function! unite#kinds#javaimport#define()
    return [deepcopy(s:package), deepcopy(s:class), deepcopy(s:field), deepcopy(s:method)]
endfunction

let &cpo= s:save_cpo
unlet s:save_cpo
