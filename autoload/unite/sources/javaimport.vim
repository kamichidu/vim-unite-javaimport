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

let s:P= javaimport#vital('Process')
let s:L= javaimport#vital('Data.List')
let s:J= javaimport#vital('Web.JSON')
let s:M= javaimport#vital('Vim.Message')

" autoload/unite/sources/javaimport.vim
let s:plugin_dir= expand('<sfile>:h:h:h:h') . '/'
let s:javaimport_classpath= s:plugin_dir . 'bin/javaimport-0.2.1.jar'
let s:config_classpath= s:plugin_dir . 'config/'

let s:jlang= javalang#get()

let s:packages= {
\   'name': 'javaimport/package',
\   'description': 'Gather packages from current classpath.',
\   'sorters': ['sorter_word'],
\   'max_candidates': 100,
\}

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

    call s:P.spawn(join([
    \   expand('$JAVA_HOME/bin/java'),
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

function! s:new_package_filter(context)
    let filter= javaimport#filter#package#new()

    if has_key(a:context, 'custom_package')
        call filter.contains(a:context.custom_package)
    endif
    for exclusion in get(g:javaimport_config, 'exclude_packages', [])
        call filter.exclude(exclusion)
    endfor

    return filter
endfunction

function! s:new_class_filter(context)
    let filter= javaimport#filter#class#new()

    if has_key(a:context, 'class')
        call filter.classname(a:context.class)
    endif

    return filter
endfunction

function! s:packages.gather_candidates(args, context)
    let data_dir= expand('$TEMP/javaimport/data/')
    let configs= javaimport#import_config()
    let jar_configs= filter(copy(configs), 'v:val.type ==# "jar"')

    call s:analyze_fast(data_dir, map(copy(jar_configs), 'v:val.path'))

    let [orig_paths, data_paths]= s:trans_data_path(data_dir, map(copy(jar_configs), 'v:val.path'))

    if empty(data_paths)
        let a:context.is_async= 0
        return []
    endif

    let candidates= []
    let filter= s:new_package_filter(a:context)
    let a:context.source__paths= []
    let a:context.source__filter= filter
    for path in s:L.zip(orig_paths, data_paths)
        if filereadable(path[1] . '/packages')
            let packages= s:J.decode(join(readfile(path[1] . '/packages'), ''))

            let candidates+= map(filter.apply(packages), "{
            \   'word': v:val,
            \   'kind': 'javaimport/package',
            \   'action__package': v:val,
            \}")
        else
            let a:context.source__paths+= [path]
        endif
    endfor
    let a:context.is_async= !empty(a:context.source__paths)
    return candidates
endfunction

function! s:packages.async_gather_candidates(args, context)
    let candidates= []
    let paths= a:context.source__paths
    let filter= a:context.source__filter
    let a:context.source__paths= []
    for path in paths
        if filereadable(path[1] . '/packages')
            let packages= s:J.decode(join(readfile(data_dir . jarname . '/packages'), ''))

            let packages= filter.apply(packages)

            let candidates+= map(packages, "{
            \   'word': v:val,
            \   'kind': 'javaimport/package',
            \   'action__package': v:val,
            \}")
        else
            let a:context.source__paths+= [path]
        endif
    endfor
    let a:context.is_async= !empty(a:context.source__paths)
    return candidates
endfunction

let s:classes= {
\   'name': 'javaimport/class',
\   'description': 'Gather classes from current classpath.',
\   'sorters': ['sorter_word'],
\   'max_candidates': 100,
\}

" all arguments are passed by context using -custom_xxx argument
" valid arguments are:
"   custom_package - package name (constant match)
"   custom_class   - class name (constant match)
function! s:classes.gather_candidates(args, context)
    let data_dir= expand('$TEMP/javaimport/data/')
    let configs= javaimport#import_config()
    let directory_configs= filter(copy(configs), 'v:val.type ==# "directory"')
    let jar_configs= filter(copy(configs), 'v:val.type ==# "jar"')
    let javadoc_configs= filter(copy(configs), 'v:val.type ==# "javadoc"')
    " TODO: remove this feature
    if !empty(javadoc_configs)
        call s:M.warn("gathering classes from javadoc path (url) is deprecated, ignore it.")
    endif

    call s:analyze_fast(data_dir, map(copy(jar_configs), 'v:val.path'))

    let [orig_paths, data_paths]= s:trans_data_path(data_dir, map(copy(jar_configs), 'v:val.path'))

    if empty(data_paths)
        let a:context.is_async= 0
        return []
    endif

    let candidates= []
    let package_filter= s:new_package_filter(a:context)
    let class_filter= s:new_class_filter(a:context)
    let a:context.source__paths= []
    let a:context.source__package_filter= package_filter
    let a:context.source__class_filter= class_filter
    for path in s:L.zip(orig_paths, data_paths)
        if isdirectory(path[1])
            let files= map(split(globpath(path[1], '*'), "\n"), 'fnamemodify(v:val, ":t")')

            call filter(files, 'v:val !=# "packages"')

            for file in package_filter.apply(files)
                try
                    let classes= s:J.decode(join(readfile(s:join_path(path[1], file)), ''))

                    call filter(classes, 's:L.has(v:val.modifiers, "public") || s:L.has(v:val.modifiers, "protected")')

                    let candidates+= map(class_filter.apply(classes), "{
                    \   'word': v:val.canonical_name,
                    \   'kind': 'javaimport/class',
                    \   'action__canonical_name': v:val.canonical_name,
                    \}")
                catch
                    echomsg file
                    echomsg v:throwpoint
                    echomsg v:exception
                endtry
            endfor
        else
            let a:context.source__paths+= [path]
        endif
    endfor
    let a:context.is_async= !empty(a:context.source__paths)
    return candidates
endfunction

function! s:classes.async_gather_candidates(args, context)
    let candidates= []
    let paths= a:context.source__paths
    let package_filter= a:context.source__package_filter
    let class_filter= a:context.source__class_filter
    let a:context.source__paths= []
    for path in paths
        if isdirectory(path[1])
            let files= map(split(globpath(path[1], '*'), "\n"), 'fnamemodify(v:val, ":t")')

            call filter(files, 'v:val !=# "packages"')

            for file in package_filter.apply(files)
                try
                    let classes= s:J.decode(join(readfile(s:join_path(path[1], file)), ''))

                    call filter(classes, 's:L.has(v:val.modifiers, "public") || s:L.has(v:val.modifiers, "protected")')

                    let candidates+= map(filter.apply(classes), "{
                    \   'word': v:val.canonical_name,
                    \   'kind': 'javaimport/class',
                    \   'action__canonical_name': v:val.canonical_name,
                    \}")
                catch
                    echomsg file
                    echomsg v:throwpoint
                    echomsg v:exception
                endtry
            endfor
        else
            let a:context.source__paths+= [path]
        endif
    endfor
    let a:context.is_async= !empty(a:context.source__paths)
    return candidates
endfunction

let s:static_import= {
\   'name': 'javaimport/static_import',
\}

function! s:static_import.async_gather_candidates(args, context)
    let args= javaimport#build_args(a:args)

    if !(has_key(args, 'classname') && has_key(args, 'jarpath'))
        let a:context.is_async= 0
        return []
    endif

    let classname= args.classname
    let jarpath= args.jarpath

    let server= javaimport#server()

    " show_fields
    if !has_key(a:context, 'source__fields_ticket')
        let a:context.source__fields_ticket= server.request({
        \   'command': 'fields',
        \   'classpath': [jarpath],
        \   'predicate': {
        \       'classname': {'regex': classname, 'type': 'inclusive'},
        \       'modifiers': ['public', 'static'],
        \       'exclude_packages': get(g:javaimport_config, 'exclude_packages', []),
        \   },
        \})
    endif
    " show_methods
    if !has_key(a:context, 'source__methods_ticket')
        let a:context.source__methods_ticket= server.request({
        \   'command': 'methods',
        \   'classpath': [jarpath],
        \   'predicate': {
        \       'classname': {'regex': classname, 'type': 'inclusive'},
        \       'modifiers': ['public', 'static'],
        \       'exclude_packages': get(g:javaimport_config, 'exclude_packages', []),
        \   },
        \})
    endif

    let fields_response= server.receive(a:context.source__fields_ticket)
    let methods_response= server.receive(a:context.source__methods_ticket)

    " TODO
    let a:context.is_async= 0
    return []
endfunction

function! s:escape(name)
    return substitute(a:name, '[:;*?"<>|/\\%]', '_', 'g')
endfunction

function! s:join_path(parent, filename)
    return substitute(a:parent, '/\+$', '', '') . '/' . a:filename
endfunction

function! unite#sources#javaimport#define()
    return [deepcopy(s:packages), deepcopy(s:classes)]
endfunction

let &cpo= s:save_cpo
unlet s:save_cpo
