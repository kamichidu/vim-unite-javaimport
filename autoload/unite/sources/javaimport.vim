" ----------------------------------------------------------------------------
" File:        autoload/unite/sources/javaimport.vim
" Last Change: 01-Jun-2014.
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

function! s:allclasses.gather_candidates(args, context)
    let configs= javaimport#import_config()

    let classes= []
    for config in configs
        let source= s:class_sources[config.type]
        let items= source.gather_classes(config, a:context)

        call add(classes, items)
    endfor
    let classes= s:L.flatten(classes)

    return map(classes, "
    \   {
    \       'word':   v:val.word,
    \       'kind':   'javatype',
    \       'source': 'javaimport',
    \       'action__canonical_name': v:val.canonical_name,
    \       'action__javadoc_url':    v:val.javadoc_url,
    \   }
    \")
endfunction

function! unite#sources#javaimport#define()
    return [deepcopy(s:source), deepcopy(s:allclasses)]
endfunction

let &cpo= s:save_cpo
unlet s:save_cpo

" vim:foldenable:foldmethod=marker
