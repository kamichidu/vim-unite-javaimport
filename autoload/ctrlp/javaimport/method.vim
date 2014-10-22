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

function! ctrlp#javaimport#method#init()
    let configs= javaimport#import_config()
    let jar_configs= filter(copy(configs), 'v:val.type ==# "jar"')

    call javaimport#start_analysis_fast(map(copy(jar_configs), 'v:val.path'))

    let [orig_paths, data_paths]= javaimport#trans_data_path(map(copy(jar_configs), 'v:val.path'))

    if empty(data_paths)
        return []
    endif

    let package_filter= javaimport#new_package_filter()
    let paths= s:L.zip(orig_paths, data_paths)
    let packages= []
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
            " public, protected, package private class are permitted
            call filter(classes, '
            \   s:L.has(v:val.modifiers, "public") ||
            \   s:L.has(v:val.modifiers, "protected") ||
            \   !s:L.has(v:val.modifiers, "private")
            \')

            for class in class_filter.apply(classes)
                let methods= filter(class.methods, '
                \   s:L.has(v:val.modifiers, "static") && (
                \       s:L.has(v:val.modifiers, "public") ||
                \       s:L.has(v:val.modifiers, "protected") ||
                \       !s:L.has(v:val.modifiers, "private")
                \   )
                \')
                let candidates+= map(methods, "class.canonical_name . '.' . v:val.name . \"\t\" . s:info(v:val)")
            endfor
        else
            call s:L.push(packages, package)
        endif
    endwhile
    return candidates
endfunction

function! s:info(method)
    let info= []
    if s:L.has(a:method.modifiers, 'public')
        let info+= ['public']
    elseif s:L.has(a:method.modifiers, 'protected')
        let info+= ['protected']
    elseif s:L.has(a:method.modifiers, 'private')
        let info+= ['private']
    endif
    let info+= [printf('%s(%s)', a:method.return_type, join(map(copy(a:method.parameters), 'string(v:val)')))]
    return join(info)
endfunction

function! ctrlp#javaimport#method#accept(mode, str)
    call ctrlp#exit()

    let str= strpart(a:str, 0, stridx(a:str, "\t"))
    let class= join(split(str, '\.')[ : -2], '.')
    let method= split(str, '\.')[-1]
    call javaimport#import({'class': class, 'method': method})
endfunction

let g:ctrlp_ext_vars= get(g:, 'ctrlp_ext_vars', []) + [{
\   'init':   'ctrlp#javaimport#method#init()',
\   'accept': 'ctrlp#javaimport#method#accept',
\   'lname':  'javaimport/method',
\   'sname':  'javaimport/method',
\   'type':   'tabs',
\   'sort':   1,
\}]

let s:id= g:ctrlp_builtins + len(g:ctrlp_ext_vars)
function! ctrlp#javaimport#method#id()
    return s:id
endfunction
