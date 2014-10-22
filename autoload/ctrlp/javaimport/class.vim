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

function! ctrlp#javaimport#class#init()
    let configs= javaimport#import_config()
    let directory_configs= filter(copy(configs), 'v:val.type ==# "directory"')
    let jar_configs= filter(copy(configs), 'v:val.type ==# "jar"')

    call javaimport#start_analysis_fast(map(copy(jar_configs), 'v:val.path'))

    let [orig_paths, data_paths]= javaimport#trans_data_path(map(copy(jar_configs), 'v:val.path'))

    if empty(data_paths)
        return []
    endif

    let packages= []
    let package_filter= javaimport#new_package_filter()
    let paths= s:L.zip(orig_paths, data_paths)
    while !empty(paths)
        let path= s:L.shift(paths)
        let [ok, names]= javaimport#read_packages(path[1])

        if ok
            let packages+= map(copy(package_filter.apply(names)), '[path, v:val]')
        else
            call s:L.push(paths, path)
        endif
    endwhile

    let candidates= []
    let class_filter= javaimport#new_class_filter()
    while !empty(packages)
        let package= s:L.shift(packages)

        let [path, name]= package
        let [ok, classes]= javaimport#read_classes(path[1], name)

        if ok
            call filter(classes, 's:L.has(v:val.modifiers, "public") || s:L.has(v:val.modifiers, "protected")')

            let candidates+= map(copy(class_filter.apply(classes)), 'v:val.canonical_name')
        else
            call s:L.push(packages, package)
        endif
    endwhile
    return candidates
endfunction

function! ctrlp#javaimport#class#accept(mode, str)
    call ctrlp#exit()

    if a:mode ==# 'e'
        call javaimport#import(a:str)
    elseif a:mode ==# 'h' || a:mode ==# 'v'
        let query= deepcopy(self)

        let query.class= a:str

        if a:mode ==# 'h'
            call ctrlp#init(ctrlp#javaimport#field#id(), query)
        else
            call ctrlp#init(ctrlp#javaimport#method#id(), query)
        endif
    endif
endfunction

let g:ctrlp_ext_vars= get(g:, 'ctrlp_ext_vars', []) + [{
\   'init':   'ctrlp#javaimport#class#init()',
\   'accept': 'ctrlp#javaimport#class#accept',
\   'lname':  'javaimport/class',
\   'sname':  'javaimport/class',
\   'type':   'line',
\   'sort':   1,
\}]

let s:id= g:ctrlp_builtins + len(g:ctrlp_ext_vars)
function! ctrlp#javaimport#class#id()
    return s:id
endfunction
