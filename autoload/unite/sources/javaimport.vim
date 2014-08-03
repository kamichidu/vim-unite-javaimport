" ----------------------------------------------------------------------------
" File:        autoload/unite/sources/javaimport.vim
" Last Change: 03-Aug-2014.
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

let s:L= javaimport#Data_List()
let s:J= javaimport#Web_JSON()

let s:class_sources= {
\   'jar':       javaimport#source#jar#define(),
\   'directory': javaimport#source#directory#define(),
\   'javadoc':   javaimport#source#javadoc#define(),
\}

let s:source= {
\   'name'           : 'javaimport',
\   'description'    : 'candidates from classes in current classpath.',
\   'sorters'        : ['sorter_word'],
\   'max_candidates' : 100,
\}

function! s:source.gather_candidates(args, context)
    let l:configs= javaimport#import_config()

    let l:classes= []
    for l:config in l:configs
        let source= s:class_sources[l:config.type]
        let items= source.gather_classes(l:config, a:context)

        call add(l:classes, items)
    endfor

    let l:classes= s:L.flatten(l:classes)

    let l:args= javaimport#build_args(a:args, {'queue': 'List'})

    " show classes only called by expandable
    " otherwise only packages (for speed, memory, anti stop the world)
    if has_key(l:args, 'show_class') && l:args.show_class || has_key(l:args, '!')
        let l:package_regex= get(l:args, 'package', '')

        if !empty(l:package_regex)
            let l:package_regex= substitute(l:package_regex, '\.', '\\.', 'g')

            " filter by package name depends on naming convention
            call filter(l:classes, 'v:val.canonical_name =~# ''^\C' . l:package_regex . '\.[A-Z]''')
        endif

        return map(l:classes,
        \   '{' .
        \   '   "word":   v:val.word,' .
        \   '   "kind":   "javatype",' .
        \   '   "source": "javaimport",' .
        \   '   "action__canonical_name": v:val.canonical_name,' .
        \   '   "action__javadoc_url":    v:val.javadoc_url,' .
        \   '}'
        \)
    elseif has_key(l:args, 'only')
        let l:simple_name= l:args.only
        let l:rest= get(l:args, 'queue', [])

        call filter(l:classes, 'v:val.canonical_name =~# ''\C\.'' . l:simple_name . ''$''')

        return map(l:classes,
        \   '{' .
        \   '   "word":   v:val.word,' .
        \   '   "kind":   "javatype",' .
        \   '   "source": "javaimport",' .
        \   '   "action__canonical_name": v:val.canonical_name,' .
        \   '   "action__javadoc_url":    v:val.javadoc_url,' .
        \   '   "action__rest": l:rest,' .
        \   '}'
        \)
    else
        let l:packages= map(l:classes, 'matchstr(v:val.canonical_name, ''\C[a-z][a-z0-9_]*\%(\.[a-z][a-z0-9_]*\)*'')')

        let l:packages= s:L.uniq(l:packages)

        return map(l:packages,
        \   '{' .
        \   '   "word":   v:val,' .
        \   '   "kind":   "expandable",' .
        \   '   "source": self.name,' .
        \   '   "action__package": v:val,' .
        \   '}'
        \)
    endif
endfunction

let s:allclasses= {
\   'name'           : 'javaimport/class',
\   'description'    : 'candidates from classes in current classpath.',
\   'sorters'        : ['sorter_word'],
\   'max_candidates' : 100,
\}

function! s:allclasses.async_gather_candidates(args, context)
    if has_key(a:context, 'source__configs')
        let configs= deepcopy(a:context.source__configs)
    else
        let configs= javaimport#import_config()
        let a:context.source__configs= deepcopy(configs)
    endif

    let server= javaimport#server()

    if has_key(a:context, 'source__ticket')
        let ticket= a:context.source__ticket
    else
        let ticket= server.request({
        \   'command': 'classes',
        \   'classpath': map(configs, 'v:val.path'),
        \   'predicate': {
        \       'modifiers': ['public'],
        \       'exclude_packages': get(g:javaimport_config, 'exclude_packages', []),
        \   },
        \})
        let a:context.source__ticket= ticket
    endif

    let response= server.receive(ticket)

    if empty(response)
        return []
    endif

    if response.status ==# 'finish' || response.status ==# 'error'
        let a:context.is_async= 0
    endif

    return map(response.result, "
    \   {
    \       'word':   v:val.classname,
    \       'kind':   'javatype',
    \       'source': 'javaimport',
    \       'action__canonical_name': v:val.classname,
    \       'action__javadoc_url':    get(v:val, 'javadoc_url', ''),
    \       'action__jar_path':       v:val.jar,
    \   }
    \")
    " return map(classes, "
    " \   {
    " \       'word':   v:val.word,
    " \       'kind':   'javatype',
    " \       'source': 'javaimport',
    " \       'action__canonical_name': v:val.canonical_name,
    " \       'action__javadoc_url':    v:val.javadoc_url,
    " \       'action__jar_path':        v:val.jar_path
    " \   }
    " \")
endfunction

let s:static_import= {
\   'name': 'javaimport/static_import',
\}

function! s:static_import.async_gather_candidates(args, context)
    if !(has_key(a:args, 'classname') && has_key(a:args, 'jarpath'))
        let a:context.is_async= 0
        return []
    endif

    let classname= a:args.classname
    let jarpath= a:args.jarpath

    " show_fields
    if has_key(a:context, 'source__fields_ticket')
    endif
    " show_methods
    if has_key(a:context, 'source__methods_ticket')
    endif
endfunction

function! unite#sources#javaimport#define()
    return [deepcopy(s:source), deepcopy(s:allclasses)]
endfunction

let &cpo= s:save_cpo
unlet s:save_cpo

" vim:foldenable:foldmethod=marker
