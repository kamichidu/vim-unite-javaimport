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
if exists('g:loaded_ctrlp_javaimport_package') && g:loaded_ctrlp_javaimport_package
    finish
endif
let g:loaded_ctrlp_javaimport_package= 1

let s:P= javaimport#vital('Process')
let s:L= javaimport#vital('Data.List')
let s:J= javaimport#vital('Web.JSON')
let s:M= javaimport#vital('Vim.Message')

let s:plugin_dir= expand('<sfile>:h:h:h:h') . '/'
let s:javaimport_classpath= s:plugin_dir . 'bin/javaimport-0.2.4.jar'
let s:config_classpath= s:plugin_dir . 'config/'

let s:jlang= javalang#get()

function! ctrlp#javaimport#package#init()
    let data_dir= s:join_path(g:javaimport_config.cache_dir, 'data/')
    let configs= javaimport#import_config()
    let jar_configs= filter(copy(configs), 'v:val.type ==# "jar"')

    call s:analyze_fast(data_dir, map(copy(jar_configs), 'v:val.path'))

    let [orig_paths, data_paths]= s:trans_data_path(data_dir, map(copy(jar_configs), 'v:val.path'))

    if empty(data_paths)
        return []
    endif

    let candidates= []
    let filter= s:new_package_filter()
    let paths= s:L.zip(orig_paths, data_paths)
    while !empty(paths)
        let path= s:L.shift(paths)
        let [ok, packages]= s:read_packages(path[1])

        if ok
            let candidates+= filter.apply(packages)
        else
            call s:L.push(paths, path)
        endif
    endwhile
    return candidates
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

function! s:join_path(parent, filename)
    return substitute(a:parent, '/\+$', '', '') . '/' . a:filename
endfunction

function! s:new_package_filter()
    let filter= javaimport#filter#package#new()

    for exclusion in get(g:javaimport_config, 'exclude_packages', [])
        call filter.exclude(exclusion)
    endfor

    return filter
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

function! ctrlp#javaimport#package#accept(mode, str)
  call ctrlp#exit()
  call ctrlp#javaimport#class#package(a:str)
  call ctrlp#init(ctrlp#javaimport#class#id())
endfunction

let g:ctrlp_ext_vars= get(g:, 'ctrlp_ext_vars', []) + [{
\   'init':   'ctrlp#javaimport#package#init()',
\   'accept': 'ctrlp#javaimport#package#accept',
\   'lname':  'javaimport/package',
\   'sname':  'javaimport/package',
\   'type':   'line',
\   'sort':   1,
\}]

let s:id= g:ctrlp_builtins + len(g:ctrlp_ext_vars)
function! ctrlp#javaimport#package#id()
    return s:id
endfunction
