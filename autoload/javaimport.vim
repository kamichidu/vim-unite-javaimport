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

let s:V= vital#of('javaimport')
let s:P= s:V.import('Process')
let s:L= s:V.import('Data.List')
let s:J= s:V.import('Web.JSON')
let s:M= s:V.import('Vim.Message')
let s:F= s:V.import('System.File')
unlet s:V

let s:jclasspath= javaclasspath#get()

let s:vital= {
\   'Process': s:P,
\   'Data.List': s:L,
\   'Web.JSON': s:J,
\   'Vim.Message': s:M,
\   'System.File': s:F,
\}
function! javaimport#vital(module)
    return s:vital[a:module]
endfunction

" Deprecated: removed later
function! javaimport#import_config()
    let result= s:parse_javaimport()
    let jclasspath_parsed= s:jclasspath.parse()

    " convert own format
    for entry in jclasspath_parsed
        let converted= {}

        if entry.kind ==# 'lib'
            let converted.type= 'jar'
            let converted.path= entry.path
            let converted.javadoc= get(entry, 'javadoc', '')
        elseif entry.kind ==# 'src'
            let converted.type= 'directory'
            let converted.path= entry.path
            let converted.javadoc= get(entry, 'javadoc', '')
        endif

        if has_key(converted, 'path')
            call add(result, converted)
        endif
    endfor

    return result
endfunction

" Deprecated: removed later
function! s:parse_javaimport()
    if !filereadable('.javaimport')
        return []
    endif

    let l:lines= readfile('.javaimport')
    " ignore comment lines
    call filter(l:lines, 'v:val !~# ''^\s*#''')

    let l:sources= s:JSON.decode('[' . join(l:lines, "\n") . ']')
    let l:result= []

    for l:source in l:sources
        let l:path= l:source.path
        let l:type= ''
        if l:path =~# '^http://'
            let l:type= 'javadoc'
        elseif l:path =~# '\.jar$'
            let l:type= 'jar'
        elseif isdirectory(l:path)
            let l:type= 'directory'
        else
            let l:type= 'unknown'
        endif

        let l:javadoc= (has_key(l:source, 'javadoc')) ? l:source.javadoc : ''

        call add(l:result, {
        \   'path': l:path,
        \   'type': l:type,
        \   'javadoc': l:javadoc,
        \})
    endfor

    return l:result
endfunction


"""
" javadocのurlを得る
"
" @param  base_url       javadocのルートurl
" @param  canonical_name クラス名
" @return
"   canonical_nameのjavadoc url
""
function! javaimport#to_javadoc_url(base_url, canonical_name)
    " TODO: more effective implementation.
    let l:elms= split(a:canonical_name, '\.')

    let l:result= a:base_url.'/'
    for l:elm in l:elms
        if l:elm =~# '^\U'
            let l:result.= l:elm.'/'
        else
            let l:result.= l:elm.'.'
        endif
    endfor

    return l:result.'html'
endfunction

"""
" clear cache.
"
""
function! javaimport#clear_cache()
    let cachedir= g:javaimport_config.cache_dir

    " check exist
    if isdirectory(cachedir)
        call s:F.rmdir(cachedir, 'r')
    endif
endfunction

"""
" show javadoc by url on the new buffer.
"
" @param url javadoc url
""
function! javaimport#preview(url)
    " call s:BM.open('javadoc preview', {'range': 'current'})

    " setlocal bufhidden=hide buftype=nofile noswapfile nobuflisted readonly

    let l:using= g:javaimport_config.preview_using
    if l:using ==# 'w3m' && exists(':W3mSplit')
        execute ':W3mSplit ' . a:url
    elseif l:using ==# 'lynx'
        throw 'sorry, unimplemented yet'
    else
        throw 'unite-javaimport: illegal configuration (g:javaimport_config.preview_using): ' . l:using
    endif
endfunction

function! javaimport#build_args(args)
    let result= {}

    for arg in a:args
        let pair= split(arg, '=')

        let result[pair[0]]= get(pair, 1, '')
    endfor

    return result
endfunction

"""
" start unite-javaimport by simple_name to import quickly.
"
" @param simple_name simple classname (aka. class name without package name)
""
function! javaimport#quickimport(simple_name)
    call unite#start([['javaimport/class']], {'custom_javaimport_class': a:simple_name})
endfunction

"""
" sort import statements on current buffer.
"
" before:
"   import java.util.Map;
"   import java.util.Collection;
"   import org.apache.commons.lang.StringUtils;
"
" after:
"   import java.util.Collection;
"   import java.util.Map;
"
"   import org.apache.commons.lang.StringUtils;
"
""
function! javaimport#sort_import_statements()
    let manager= javaimport#import_manager#new()

    call manager.sort()
endfunction

"""
" remove unnecessary import statements from current buffer.
""
function! javaimport#remove_unnecesarries()
    let save_pos= getpos('.')
    try
        let manager= javaimport#import_manager#new()

        " gather already existed import statements
        let [slnum, elnum]= manager.region()

        if [slnum, elnum] == [0, 0]
            return
        endif

        let classes= manager.imported_classes()

        " delete old import statements
        execute slnum . ',' . elnum . 'delete _'

        let remainings= []
        " find unnecessary statements
        for class in classes
            let simple_name= matchstr(class, '\.\zs\w\+$')

            " move cursor to 1st line
            call setpos('.', ['%', 1, 1, 0])
            if search('\C\<' . simple_name . '\>', 'nW') != 0
                let remainings+= [class]
            endif
        endfor

        " append new import statements
        call manager.add(remainings)
    finally
        call setpos('.', save_pos)
    endtry
endfunction

"""
" add import statements for classnames on current buffer.
"
" @param classnames will be imported
""
function! javaimport#add_import_statements(classnames)
    let manager= javaimport#import_manager#new()

    call manager.add(a:classnames)
endfunction

function! javaimport#add_static_import_statements(class_and_fields)
    let manager= javaimport#import_manager#new()

    call manager.add_static(a:class_and_fields)
endfunction

"""
" get some imported classnames (canonical names) from current buffer.
"
" @return list of string
""
function! javaimport#imported_classes()
    let manager= javaimport#import_manager#new()

    return manager.imported_classes()
endfunction

let &cpo= s:save_cpo
unlet s:save_cpo
