" ----------------------------------------------------------------------------
" File:        autoload/unite/sources/javaimport.vim
" Last Change: 29-Jun-2013.
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

let s:V= vital#of('unite-javaimport')
let s:L= s:V.import('Data.List')
let s:H= s:V.import('Web.Http')
let s:S= s:V.import('Data.String')
let s:source= {
\   'name'           : 'javaimport',
\   'description'    : 'candidates from classes in current classpath.',
\   'sorters'        : ['sorter_word'],
\   'max_candidates' : 100,
\}
unlet s:V

function! s:gather_from_javadoc(path) " {{{
    let l:response= s:H.get(a:path.'/allclasses-noframe.html')

    if !l:response.success
        return []
    endif

    let l:li_of_classes= filter(split(l:response.content, "\n"), 'v:val =~# "^<li>.*</li>$"')

    return map(l:li_of_classes, 's:to_class_name_for_javadoc(v:val)')
endfunction

function! s:to_class_name_for_javadoc(li_of_class)
    let l:html= substitute(a:li_of_class, '^.*\<href\>="\([a-zA-Z0-9/\._]\+\)\.html".*$', '\1', '')

    return substitute(l:html, '/', '.', 'g')
endfunction
" }}}
function! s:gather_from_directory(path) " {{{
    " TODO
    if filereadable('./tags')
        call delete('./tags')
    endif
    " ctags --language-force=java --langmap=Java:.java --java-kinds=cgi --recurse=yes
    call system('ctags --append=yes --language-force=java --langmap=Java:.java --java-kinds=cgi --recurse=yes '.a:path)

    " collect class, interface and enum name.
    let l:result= map(
    \   s:filter_tags_line(readfile('tags')), 
    \   's:type_from_tags_line(a:path, v:val)'
    \)
    if filereadable('./tags')
        call delete('./tags')
    endif
    return l:result
endfunction

function! s:filter_tags_line(tags_lines)
    let l:predicates= [
    \   'v:val !~# "^!"', 
    \   'v:val =~# "\\/^\\<\\(public\\|protected\\)\\>"', 
    \]

    let l:result= deepcopy(a:tags_lines)
    for l:predicate in l:predicates
        call filter(l:result, l:predicate)
    endfor

    return l:result
endfunction

function! s:type_from_tags_line(path, tags_line)
    let l:name= substitute(a:tags_line, '\s\+.*$', '', '')
    let l:package= s:package_name(a:path, a:tags_line)

    return join([l:package, l:name], '.')
endfunction

function! s:package_name(path, tags_line)
    let l:path= split(a:tags_line, '\s\+')[1]

    " ファイル名削除
    let l:path= substitute(l:path, '/[^/]\+\.java$', '', '')
    " ^src/ を削除
    let l:path= s:S.replace_once(l:path, a:path, '')
    " / -> .
    let l:path= substitute(l:path, '/', '.', 'g')

    return l:path
endfunction
" }}}
function! s:gather_from_jar(path) " {{{
    " TODO
    let l:class_files= s:filter_class_files(
    \   split(
    \       system('jar -tf '.shellescape(a:path)), 
    \       '\n'
    \   )
    \)

    let l:result= map(
    \   l:class_files, 
    \   's:type_from_class_file(v:val)'
    \)
    return l:result
endfunction

function! s:filter_class_files(files)
    return filter(a:files, 'v:val =~# "\\(/\\|\\$\\)\\a\\w*\\.class$"')
endfunction

function! s:type_from_class_file(filename)
    let l:result= a:filename

    let l:result= substitute(l:result, '\.class$', '', '')
    let l:result= substitute(l:result, '/\|\$', '.', 'g')

    return l:result
endfunction
" }}}
function! s:gather_from_unknown(path) " {{{
    " TODO
    return []
endfunction
" }}}
function! unite#sources#javaimport#define() " {{{
    return s:source
endfunction
" }}}
function! s:source.gather_candidates(args, context) " {{{
    let l:configs= javaimport#config()

    let l:result= []
    for l:config in l:configs
        call add(l:result, s:gather_from_{l:config.type}(l:config.path))
    endfor

    let l:result= s:L.flatten(l:result)

    return map(l:result, '{'.
    \   '"word": v:val, '.
    \   '"kind": "javatype", '.
    \   '"source": "javaimport", '.
    \   '"action__canonical_name": v:val, '.
    \   '}'
    \)
endfunction
" }}}

let &cpo= s:save_cpo
unlet s:save_cpo

" vim:foldenable:foldmethod=marker

