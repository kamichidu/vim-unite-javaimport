" ----------------------------------------------------------------------------
" File:        javaimport.vim
" Last Change: 18-Jun-2013.
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

"
" @param path クラス名を取得するルートディレクトリ(or jar)のパス
" @return path以下に含まれるパッケージ名を含めたクラス名のList
"
function! javaimport#gather_class_names(path)
    if isdirectory(a:path)
        call delete('./tags')
        " ctags --language-force=java --langmap=Java:.java --java-kinds=cgi --recurse=yes
        call system('ctags --append=yes --language-force=java --langmap=Java:.java --java-kinds=cgi --recurse=yes '.a:path)

        " collect class, interface and enum name.
        return map(
        \   s:filter_tags_line(readfile('tags')), 
        \   's:type_from_tags_line(v:val)'
        \)
    elseif a:path =~# '\.jar$'
        let l:class_files= s:filter_class_files(
        \   split(
        \       system('jar -tf '.shellescape(a:path)), 
        \       '\n'
        \   )
        \)

        return map(
        \   l:class_files, 
        \   's:type_from_class_file(v:val)'
        \)
    endif

    return []
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

function! s:type_from_tags_line(tags_line)
    let l:name= substitute(a:tags_line, '\s\+.*$', '', '')
    let l:package= s:package_name(a:tags_line)

    return join([l:package, l:name], '.')
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

function! s:package_name(tags_line)
    let l:path= split(a:tags_line, '\s\+')[1]

    " ファイル名削除
    let l:path= substitute(l:path, '/[^/]\+\.java$', '', '')
    " ^./ を削除
    let l:path= substitute(l:path, '^\./', '', '')
    " ^src/ を削除
    let l:path= substitute(l:path, '^[^/]\+/', '', '')
    " / -> .
    let l:path= substitute(l:path, '/', '.', 'g')

    return l:path
endfunction

let &cpo= s:save_cpo
unlet s:save_cpo

