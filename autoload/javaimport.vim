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

" autoload/javaimport.vim
let s:plugin_dir= expand('<sfile>:h:h') . '/'
let s:javaimport_classpath= s:plugin_dir . 'bin/javaimport-0.2.4.jar'
let s:config_classpath= s:plugin_dir . 'config/'

let s:jclasspath= javaclasspath#get()
let s:jlang= javalang#get()

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

    let l:sources= s:J.decode('[' . join(l:lines, "\n") . ']')
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
    call s:import_manager().sort()
endfunction

"""
" remove unnecessary import statements from current buffer.
""
function! javaimport#remove_unnecesarries()
    let removals= []

    let save_pos= getpos('.')
    try
        let classes= s:import_manager().imported_classes()
        let fields_and_methods= s:import_manager().imported_fields_and_methods()

        for class in classes
            let simple_name= split(class, '\.')[-1]

            if simple_name !=# '*' && !s:is_symbol_used(simple_name)
                let removals+= [{'class': class}]
            endif
        endfor
        for field_or_method in fields_and_methods
            let name= split(field_or_method, '\.')[-1]

            if name !=# '*' && !s:is_symbol_used(name)
                let removals+= [{'class': join(split(field_or_method, '\.')[ : -2], '.'), 'field': split(field_or_method, '\.')[-1]}]
            endif
        endfor
    finally
        call setpos('.', save_pos)
    endtry

    call s:import_manager().remove(removals)
endfunction

function! javaimport#import(data)
    call s:import_manager().add(a:data)
endfunction

"""
" get some imported classnames (canonical names) from current buffer.
"
" @return list of string
""
function! javaimport#imported_classes()
    return s:import_manager().imported_classes()
endfunction

function! javaimport#data_dir()
    return javaimport#join_path(g:javaimport_config.cache_dir, 'data/')
endfunction

"
" paths: jar filename or directory name
"
function! javaimport#trans_data_path(paths)
    let data_dir= javaimport#data_dir()

    let orig_paths= []
    let data_paths= []

    for path in a:paths
        if isdirectory(path)
            " it's a directory
            let orig_paths+= [path]
            let data_paths+= [javaimport#join_path(data_dir, javaimport#fnameescape(path))]
        elseif filereadable(path) && path =~# '\c\.\%(jar\|zip\)$'
            " it's a jar file or zip file
            let orig_paths+= [path]
            let data_paths+= [javaimport#join_path(data_dir, fnamemodify(path, ':t'))]
        endif
    endfor

    return [orig_paths, data_paths]
endfunction

function! javaimport#join_path(parent, filename)
    return substitute(a:parent, '/\+$', '', '') . '/' . a:filename
endfunction

function! javaimport#fnameescape(name)
    return substitute(a:name, '[:;*?"<>|/\\%]', '_', 'g')
endfunction

" [1/0, []]
function! javaimport#read_packages(data_path)
    let filename= javaimport#join_path(a:data_path, 'packages')

    if filereadable(filename)
        try
            let content= readfile(filename)
            let data= s:J.decode(join(content, ''))

            return [1, data]
        catch
            return [0, []]
        endtry
    else
        return [0, []]
    endif
endfunction

" [1/0, []]
function! javaimport#read_classes(data_path, package)
    let filename= javaimport#join_path(a:data_path, a:package)

    if filereadable(filename)
        try
            let content= readfile(filename)
            let data= s:J.decode(join(content, ''))
            return [1, data]
        catch
            return [0, []]
        endtry
    else
        return [0, []]
    endif
endfunction

function! javaimport#start_analysis_fast(paths)
    " filter jarfle if already exist
    let [orig_paths, data_paths]= javaimport#trans_data_path(a:paths)

    let jars= []
    for path in s:L.zip(orig_paths, data_paths)
        if !isdirectory(path[1])
            let jars+= [path[0]]
        endif
    endfor

    call javaimport#start_analysis(jars)
endfunction

function! javaimport#start_analysis(paths)
    if empty(a:paths)
        " do nothing
        return
    endif

    let jvm= g:javaimport_config.jvm
    let jvmargs= g:javaimport_config.jvmargs

    if !executable(jvm)
        throw printf("javaimport: Cannot execute g:javaimport_config.jvm `%s'", jvm)
    endif

    let save_cwd= getcwd()
    try
        execute 'lcd' s:plugin_dir

        call s:P.spawn(join([
        \   jvm,
        \   jvmargs,
        \   '-cp', join([s:config_classpath, s:javaimport_classpath], s:jlang.constants.path_separator),
        \   'jp.michikusa.chitose.javaimport.cli.App',
        \   '--outputdir', javaimport#data_dir(),
        \   join(a:paths),
        \]))
    finally
        execute 'lcd' save_cwd
    endtry
endfunction

function! javaimport#scope_symbol(modifiers)
    if s:L.has(a:modifiers, 'public')
        return '+'
    elseif s:L.has(a:modifiers, 'protected')
        return '#'
    elseif s:L.has(a:modifiers, 'private')
        return '-'
    else
        return ' '
    endif
endfunction

function! javaimport#new_package_filter(...)
    let filter= javaimport#filter#package#new()

    for exclusion in get(g:javaimport_config, 'exclude_packages', [])
        call filter.exclude(exclusion)
    endfor

    return filter
endfunction

function! javaimport#new_class_filter(...)
    return javaimport#filter#class#new()
endfunction

function! javaimport#current_package()
    let dirname= tr(expand('%:.:h'), '\', '/')
    let sourcepaths= filter(copy(s:jclasspath.parse()), 'v:val.kind ==# "src"')
    let sourcepaths= map(sourcepaths, 'fnamemodify(v:val.path, ":.")')

    for sourcepath in sourcepaths
        let path= tr(sourcepath, '\', '/')
        let path= (path =~# '/$') ? path : path . '/'
        if strpart(dirname, 0, strlen(path)) ==# path
            return tr(strpart(dirname, strlen(path)), '/', '.')
        endif
    endfor

    return tr(dirname, '/', '.')
endfunction

function! s:is_symbol_used(symbol)
    let save_pos= getpos('.')
    try
        call cursor(1, 1)
        while 1
            let lnum= search('\C\<' . a:symbol . '\>', 'Wce')

            if lnum == 0
                return 0
            endif

            let in_import_decl= getline(lnum) =~# '\C\<import\>'
            let in_comment= synIDattr(synID(line('.'), col('.'), 1), 'name') =~# '\c\%(comment\)'

            if !in_import_decl && !in_comment
                return 1
            endif

            normal w
        endwhile
        return 0
    finally
        call setpos('.', save_pos)
    endtry
endfunction

function! s:import_manager()
    if !exists('s:import_manager')
        let s:import_manager= javaimport#import_manager#new()
    endif
    return s:import_manager
endfunction

let &cpo= s:save_cpo
unlet s:save_cpo
