" ----------------------------------------------------------------------------
" File:        autoload/unite/sources/javaimport.vim
" Last Change: 11-Oct-2014.
" Maintainer:  kamichidu <c.kamunagi@gmail.com>
" License:     The MIT License (MIT)
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
" ----------------------------------------------------------------------------
let s:save_cpo= &cpo
set cpo&vim

let s:L= javaimport#Data_List()
let s:J= javaimport#Web_JSON()
let s:M= javaimport#Vim_Message()

let s:classes= {
\   'name'           : 'javaimport/class',
\   'description'    : 'candidates from classes in current classpath.',
\   'sorters'        : ['sorter_word'],
\   'max_candidates' : 100,
\}

function! s:classes.gather_candidates(args, context)
    " handle arguments
    let query= javaimport#build_args(a:args)
    let regex_object= {
    \   'regex': '',
    \   'type': 'inclusive',
    \}

    if has_key(query, 'only')
        " query.only == simple name
        if empty(query.only)
            call s:M.warn("javaimport: The `only' argument must takes non-empty classname.")
            " canonical name can't has {'<', '(', '^'}
            let query.only= '<(^o^)>'
        endif
        " constant match
        let regex_object.regex= '\b\Q' . query.only . '\E$'
    endif

    let server= javaimport#server()
    let configs= javaimport#import_config()

    let directory_configs= filter(copy(configs), 'v:val.type ==# "directory"')
    let jar_configs= filter(copy(configs), 'v:val.type ==# "jar"')
    " XXX: ignore javadoc configs
    let javadoc_configs= filter(copy(configs), 'v:val.type ==# "javadoc"')
    if !empty(javadoc_configs)
        call s:M.warn("gathering classes from javadoc path (url) is deprecated, ignore it.")
    endif

    let ticket= server.request({
    \   'command': 'classes',
    \   'classpath': map(jar_configs, 'v:val.path'),
    \   'predicate': {
    \       'classname': regex_object,
    \       'modifiers': ['public'],
    \       'exclude_packages': get(g:javaimport_config, 'exclude_packages', []),
    \   },
    \})

    let a:context.source__configs= configs
    let a:context.source__ticket= ticket
    let a:context.is_async= 1

    return []
endfunction

function! s:classes.async_gather_candidates(args, context)
    let server= javaimport#server()
    let configs= deepcopy(a:context.source__configs)
    let ticket= deepcopy(a:context.source__ticket)

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

function! unite#sources#javaimport#define()
    return [deepcopy(s:classes)]
endfunction

let &cpo= s:save_cpo
unlet s:save_cpo
