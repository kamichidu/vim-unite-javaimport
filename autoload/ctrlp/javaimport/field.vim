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
let s:P= javaimport#vital('Process')
let s:L= javaimport#vital('Data.List')
let s:J= javaimport#vital('Web.JSON')
let s:M= javaimport#vital('Vim.Message')

" autoload/unite/sources/javaimport.vim
let s:plugin_dir= expand('<sfile>:h:h:h:h') . '/'
let s:javaimport_classpath= s:plugin_dir . 'bin/javaimport-0.2.4.jar'
let s:config_classpath= s:plugin_dir . 'config/'

let s:jlang= javalang#get()

function! ctrlp#javaimport#field#init()
    let data_dir= s:join_path(g:javaimport_config.cache_dir, 'data/')
    let configs= javaimport#import_config()
    let jar_configs= filter(copy(configs), 'v:val.type ==# "jar"')

    call s:analyze_fast(data_dir, map(copy(jar_configs), 'v:val.path'))

    let [orig_paths, data_paths]= s:trans_data_path(data_dir, map(copy(jar_configs), 'v:val.path'))

    if empty(data_paths)
        return []
    endif

    let package_filter= s:new_package_filter()
    let packages= []
    let paths= s:L.zip(orig_paths, data_paths)
    while !empty(paths)
        let path= s:L.shift(paths)
        let [ok, names]= s:read_packages(path[1])

        if ok
            let packages+= map(copy(package_filter.apply(names)), '[path, v:val]')
        else
            call s:L.push(paths, path)
        endif
    endwhile

    let candidates= []
    let class_filter= s:new_class_filter()
    while !empty(packages)
        let package= s:L.shift(packages)
        let [path, name]= package
        let [ok, classes]= s:read_classes(path[1], name)

        if ok
            " public, protected, package private class are permitted
            call filter(classes, '
            \   s:L.has(v:val.modifiers, "public") ||
            \   s:L.has(v:val.modifiers, "protected") ||
            \   !s:L.has(v:val.modifiers, "private")
            \')

            for class in class_filter.apply(classes)
                let fields= filter(class.fields, '
                \   s:L.has(v:val.modifiers, "static") && (
                \       s:L.has(v:val.modifiers, "public") ||
                \       s:L.has(v:val.modifiers, "protected") ||
                \       !s:L.has(v:val.modifiers, "private")
                \   )
                \')
                let candidates+= map(copy(fields), "class.canonical_name . '.' . v:val.name . \"\t\" . s:info(v:val)")
            endfor
        else
            call s:L.push(packages, package)
        endif
    endwhile
    return candidates
endfunction

function! s:info(field)
    let info= []
    if s:L.has(a:field.modifiers, 'public')
        let info+= ['public']
    elseif s:L.has(a:field.modifiers, 'protected')
        let info+= ['protected']
    elseif s:L.has(a:field.modifiers, 'private')
        let info+= ['private']
    endif
    let info+= [a:field.type]
    return join(info)
endfunction

function! s:analyze_fast(data_dir, paths)
    " filter jarfle if already exist
    let [orig_paths, data_paths]= s:trans_data_path(a:data_dir, a:paths)

    let jars= []
    for path in s:L.zip(orig_paths, data_paths)
        if !isdirectory(path[1])
            let jars+= [path[0]]
        endif
    endfor

    call s:analyze(a:data_dir, jars)
endfunction

function! s:analyze(data_dir, paths)
    if empty(a:paths)
        " do nothing
        return
    endif

    let jvm= g:javaimport_config.jvm
    let jvmargs= g:javaimport_config.jvmargs

    if !executable(jvm)
        throw printf("javaimport: Cannot execute g:javaimport_config.jvm `%s'", jvm)
    endif

    call s:P.system(join([
    \   jvm,
    \   jvmargs,
    \   '-cp', join([s:config_classpath, s:javaimport_classpath], s:jlang.constants.path_separator),
    \   'jp.michikusa.chitose.javaimport.cli.App',
    \   '--outputdir', a:data_dir,
    \   join(a:paths),
    \]))
endfunction

" => [[], []]
function! s:trans_data_path(data_dir, paths)
    let orig_paths= []
    let data_paths= []

    for path in a:paths
        if isdirectory(path)
            " it's a directory
            let orig_paths+= [path]
            let data_paths+= [s:join_path(a:data_dir, s:escape(path))]
        elseif filereadable(path) && path =~# '\c\.\%(jar\|zip\)$'
            " it's a jar file or zip file
            let orig_paths+= [path]
            let data_paths+= [s:join_path(a:data_dir, fnamemodify(path, ':t'))]
        endif
    endfor

    return [orig_paths, data_paths]
endfunction

function! s:new_package_filter()
    let filter= javaimport#filter#package#new()

    if exists('s:package')
        call filter.contains(s:package)
    endif
    for exclusion in get(g:javaimport_config, 'exclude_packages', [])
        call filter.exclude(exclusion)
    endfor

    return filter
endfunction

function! s:new_class_filter()
    let filter= javaimport#filter#class#new()

    return filter
endfunction

function! s:escape(name)
    return substitute(a:name, '[:;*?"<>|/\\%]', '_', 'g')
endfunction

function! s:join_path(parent, filename)
    return substitute(a:parent, '/\+$', '', '') . '/' . a:filename
endfunction

" [1/0, []]
function! s:read_packages(data_path)
    if filereadable(s:join_path(a:data_path, 'packages'))
        let content= readfile(s:join_path(a:data_path, 'packages'))
        return [1, s:J.decode(join(content, ''))]
    else
        return [0, []]
    endif
endfunction

" [1/0, []]
function! s:read_classes(data_path, package)
    if filereadable(s:join_path(a:data_path, a:package))
        let content= readfile(s:join_path(a:data_path, a:package))
        return [1, s:J.decode(join(content, ''))]
    else
        return [0, []]
    endif
endfunction

function! s:scope_symbol(modifiers)
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

function! ctrlp#javaimport#field#accept(mode, str)
  call ctrlp#exit()

  let str= strpart(a:str, 0, stridx(a:str, "\t"))
  let class= join(split(str, '\.')[ : -2], '.')
  let field= split(str, '\.')[-1]
  call javaimport#import({'class': class, 'field': field})
endfunction

let g:ctrlp_ext_vars= get(g:, 'ctrlp_ext_vars', []) + [{
\   'init':   'ctrlp#javaimport#field#init()',
\   'accept': 'ctrlp#javaimport#field#accept',
\   'lname':  'javaimport/field',
\   'sname':  'javaimport/field',
\   'type':   'tabs',
\   'sort':   1,
\}]

let s:id= g:ctrlp_builtins + len(g:ctrlp_ext_vars)
function! ctrlp#javaimport#field#id()
    return s:id
endfunction
