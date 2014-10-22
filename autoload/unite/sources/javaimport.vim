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

"
" package source
"
let s:packages= {
\   'name': 'javaimport/package',
\   'description': 'Gather packages from current classpath.',
\   'sorters': ['sorter_word'],
\   'max_candidates': 100,
\}

function! s:packages.gather_candidates(args, context)
    let configs= javaimport#import_config()
    let jar_configs= filter(copy(configs), 'v:val.type ==# "jar"')

    call javaimport#start_analysis_fast(map(copy(jar_configs), 'v:val.path'))

    let [orig_paths, data_paths]= javaimport#trans_data_path(map(copy(jar_configs), 'v:val.path'))

    if empty(data_paths)
        let a:context.is_async= 0
        return []
    endif

    let candidates= []
    let filter= s:new_package_filter(a:context)
    let a:context.source__paths= []
    let a:context.source__filter= filter
    for path in s:L.zip(orig_paths, data_paths)
        let [ok, packages]= javaimport#read_packages(path[1])

        if ok
            let candidates+= s:trans_package_candidate(filter.apply(packages))
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
        let [ok, packages]= javaimport#read_packages(path[1])

        if ok
            let candidates+= s:trans_package_candidate(filter.apply(packages))
        else
            let a:context.source__paths+= [path]
        endif
    endfor
    let a:context.is_async= !empty(a:context.source__paths)
    return candidates
endfunction

"
" class source
"
let s:classes= {
\   'name': 'javaimport/class',
\   'description': 'Gather classes from current classpath.',
\   'sorters': ['sorter_word'],
\   'max_candidates': 100,
\}

" all arguments are passed by context using -custom-javaimport-xxx argument
" valid arguments are:
"   custom_javaimport_package - package name (constant match)
"   custom_javaimport_class   - class name (constant match)
function! s:classes.gather_candidates(args, context)
    let configs= javaimport#import_config()
    let directory_configs= filter(copy(configs), 'v:val.type ==# "directory"')
    let jar_configs= filter(copy(configs), 'v:val.type ==# "jar"')
    let javadoc_configs= filter(copy(configs), 'v:val.type ==# "javadoc"')
    " TODO: remove this feature
    if !empty(javadoc_configs)
        call s:M.warn("gathering classes from javadoc path (url) is deprecated, ignore it.")
    endif

    call javaimport#start_analysis_fast(map(copy(jar_configs), 'v:val.path'))

    let [orig_paths, data_paths]= javaimport#trans_data_path(map(copy(jar_configs), 'v:val.path'))

    if empty(data_paths)
        let a:context.is_async= 0
        return []
    endif

    let package_filter= s:new_package_filter(a:context)

    let a:context.source__paths= []
    let a:context.source__package_filter= package_filter
    let packages= []
    for path in s:L.zip(orig_paths, data_paths)
        let [ok, names]= javaimport#read_packages(path[1])

        if ok
            let packages+= map(copy(package_filter.apply(names)), '[path, v:val]')
        else
            let a:context.source__paths+= [path]
        endif
    endfor

    let candidates= []
    let class_filter= s:new_class_filter(a:context)
    let a:context.source__packages= []
    let a:context.source__class_filter= class_filter
    for package in packages
        let [path, name]= package
        let [ok, classes]= javaimport#read_classes(path[1], name)

        if ok
            call filter(classes, 's:L.has(v:val.modifiers, "public") || s:L.has(v:val.modifiers, "protected")')

            let candidates+= s:trans_class_candidate(class_filter.apply(classes))
        else
            let a:context.source__packages+= [package]
        endif
    endfor
    let a:context.is_async= !empty(a:context.source__paths) || !empty(a:context.source__packages)
    return candidates
endfunction

function! s:classes.async_gather_candidates(args, context)
    let package_filter= a:context.source__package_filter
    let paths= a:context.source__paths
    let a:context.source__paths= []
    let packages= []
    for path in paths
        let [ok, names]= javaimport#read_packages(path[1])

        if ok
            let packages+= map(copy(package_filter.apply(names)), '[path, v:val]')
        else
            let a:context.source__paths+= [path]
        endif
    endfor

    let candidates= []
    let class_filter= a:context.source__class_filter
    let packages+= a:context.source__packages
    let a:context.source__packages= []
    for package in packages
        let [path, name]= package
        let [ok, classes]= javaimport#read_classes(path[1], name)

        if ok
            call filter(classes, 's:L.has(v:val.modifiers, "public") || s:L.has(v:val.modifiers, "protected")')

            let candidates+= s:trans_class_candidate(class_filter.apply(classes))
        else
            let a:context.source__packages+= [package]
        endif
    endfor
    let a:context.is_async= !empty(a:context.source__paths) || !empty(a:context.source__packages)
    return candidates
endfunction

"
" field source
"
let s:fields= {
\   'name': 'javaimport/field',
\   'description': 'Gather fields from current classpath.',
\   'sorters': ['sorter_word'],
\   'max_candidates': 100,
\}

function! s:fields.gather_candidates(args, context)
    let configs= javaimport#import_config()
    let jar_configs= filter(copy(configs), 'v:val.type ==# "jar"')

    call javaimport#start_analysis_fast(map(copy(jar_configs), 'v:val.path'))

    let [orig_paths, data_paths]= javaimport#trans_data_path(map(copy(jar_configs), 'v:val.path'))

    if empty(data_paths)
        let a:context.is_async= 0
        return []
    endif

    let package_filter= s:new_package_filter(a:context)
    let a:context.source__paths= []
    let a:context.source__package_filter= package_filter
    let packages= []
    for path in s:L.zip(orig_paths, data_paths)
        let [ok, names]= javaimport#read_packages(path[1])

        if ok
            let packages+= map(copy(package_filter.apply(names)), '[path, v:val]')
        else
            let a:context.source__paths+= [path]
        endif
    endfor

    let candidates= []
    let class_filter= s:new_class_filter(a:context)
    let a:context.source__packages= []
    let a:context.source__class_filter= class_filter
    for package in packages
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
                let candidates+= s:trans_field_candidate(class, filter(class.fields, '
                \   s:L.has(v:val.modifiers, "static") && (
                \       s:L.has(v:val.modifiers, "public") ||
                \       s:L.has(v:val.modifiers, "protected") ||
                \       !s:L.has(v:val.modifiers, "private")
                \   )
                \'))
            endfor
        else
            let a:context.source__packages+= [package]
        endif
    endfor
    let a:context.is_async= !empty(a:context.source__paths) || !empty(a:context.source__packages)
    return candidates
endfunction

function! s:fields.async_gather_candidates(args, context)
    let package_filter= a:context.source__package_filter
    let paths= a:context.source__paths
    let a:context.source__paths= []
    let packages= []
    for path in paths
        let [ok, names]= javaimport#read_packages(path[1])

        if ok
            let packages+= map(copy(package_filter.apply(names)), '[path, v:val]')
        else
            let a:context.source__paths+= [path]
        endif
    endfor

    let candidates= []
    let class_filter= s:new_class_filter(a:context)
    let packages+= a:context.source__packages
    let a:context.source__packages= []
    for package in packages
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
                let candidates+= s:trans_field_candidate(class, filter(class.fields, '
                \   s:L.has(v:val.modifiers, "static") && (
                \       s:L.has(v:val.modifiers, "public") ||
                \       s:L.has(v:val.modifiers, "protected") ||
                \       !s:L.has(v:val.modifiers, "private")
                \   )
                \'))
            endfor
        else
            let a:context.source__packages+= [package]
        endif
    endfor
    let a:context.is_async= !empty(a:context.source__paths) || !empty(a:context.source__packages)
    return candidates
endfunction

"
" method source
"
let s:methods= {
\   'name': 'javaimport/method',
\   'description': 'Gather methods from current classpath.',
\   'sorters': ['sorter_word'],
\   'max_candidates': 100,
\}

function! s:methods.gather_candidates(args, context)
    let configs= javaimport#import_config()
    let jar_configs= filter(copy(configs), 'v:val.type ==# "jar"')

    call javaimport#start_analysis_fast(map(copy(jar_configs), 'v:val.path'))

    let [orig_paths, data_paths]= javaimport#trans_data_path(map(copy(jar_configs), 'v:val.path'))

    if empty(data_paths)
        let a:context.is_async= 0
        return []
    endif

    let package_filter= s:new_package_filter(a:context)
    let a:context.source__paths= []
    let a:context.source__package_filter= package_filter
    let packages= []
    for path in s:L.zip(orig_paths, data_paths)
        let [ok, names]= javaimport#read_packages(path[1])

        if ok
            let packages+= map(copy(package_filter.apply(names)), '[path, v:val]')
        else
            let a:context.source__paths+= [path]
        endif
    endfor

    let candidates= []
    let class_filter= s:new_class_filter(a:context)
    let a:context.source__packages= []
    let a:context.source__class_filter= class_filter
    for package in packages
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
                let candidates+= s:trans_method_candidate(class, filter(class.methods, '
                \   s:L.has(v:val.modifiers, "static") && (
                \       s:L.has(v:val.modifiers, "public") ||
                \       s:L.has(v:val.modifiers, "protected") ||
                \       !s:L.has(v:val.modifiers, "private")
                \   )
                \'))
            endfor
        else
            let a:context.source__packages+= [package]
        endif
    endfor
    let a:context.is_async= !empty(a:context.source__paths) || !empty(a:context.source__packages)
    return candidates
endfunction

function! s:methods.async_gather_candidates(args, context)
    let package_filter= a:context.source__package_filter
    let paths= a:context.source__paths
    let a:context.source__paths= []
    let packages= []
    for path in paths
        let [ok, names]= javaimport#read_packages(path[1])

        if ok
            let packages+= map(copy(package_filter.apply(names)), '[path, v:val]')
        else
            let a:context.source__paths+= [path]
        endif
    endfor

    let candidates= []
    let class_filter= s:new_class_filter(a:context)
    let packages+= a:context.source__packages
    let a:context.source__packages= []
    for package in packages
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
                let candidates+= s:trans_method_candidate(class, filter(class.methods, '
                \   s:L.has(v:val.modifiers, "static") && (
                \       s:L.has(v:val.modifiers, "public") ||
                \       s:L.has(v:val.modifiers, "protected") ||
                \       !s:L.has(v:val.modifiers, "private")
                \   )
                \'))
            endfor
        else
            let a:context.source__packages+= [package]
        endif
    endfor
    let a:context.is_async= !empty(a:context.source__paths) || !empty(a:context.source__packages)
    return candidates
endfunction

function! s:new_package_filter(context)
    let filter= javaimport#new_package_filter()

    if has_key(a:context, 'custom_javaimport_package')
        call filter.contains(a:context.custom_javaimport_package)
    endif

    return filter
endfunction

function! s:new_class_filter(context)
    let filter= javaimport#new_class_filter()

    if has_key(a:context, 'custom_javaimport_class')
        call filter.classname(a:context.custom_javaimport_class)
    endif

    return filter
endfunction

function! s:trans_package_candidate(packages)
    return map(copy(a:packages), "{
    \   'word': v:val,
    \   'kind': 'javaimport/package',
    \   'action__package': v:val,
    \}")
endfunction

function! s:trans_class_candidate(classes)
    return map(copy(a:classes), "{
    \   'word': v:val.canonical_name,
    \   'kind': 'javaimport/class',
    \   'action__package': v:val.package,
    \   'action__class': v:val.canonical_name,
    \}")
endfunction

function! s:trans_field_candidate(class, fields)
    return map(copy(a:fields), "{
    \   'word': v:val.name,
    \   'kind': 'javaimport/field',
    \   'abbr': printf('%s %s - %s ... %s', javaimport#scope_symbol(v:val.modifiers), v:val.name, v:val.type, a:class.canonical_name),
    \   'action__package': a:class.package,
    \   'action__class': a:class.canonical_name,
    \   'action__field': v:val.name,
    \}")
endfunction

function! s:trans_method_candidate(class, methods)
    return map(copy(a:methods), "{
    \   'word': a:class.canonical_name . '.' . v:val.name,
    \   'kind': 'javaimport/method',
    \   'abbr': printf('%s %s(%s) : %s ... %s', javaimport#scope_symbol(v:val.modifiers), v:val.name, join(map(copy(v:val.parameters), 'v:val.type'), ', '), v:val.return_type, a:class.canonical_name),
    \   'action__package': a:class.package,
    \   'action__class': a:class.canonical_name,
    \   'action__method': v:val.name,
    \}")
endfunction

function! unite#sources#javaimport#define()
    return [deepcopy(s:packages), deepcopy(s:classes), deepcopy(s:fields), deepcopy(s:methods)]
endfunction

let &cpo= s:save_cpo
unlet s:save_cpo
