" ----------------------------------------------------------------------------
" File:        autoload/unite/sources/javaimport.vim
" Last Change: 30-Dec-2013.
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

let s:V= vital#of('unite-javaimport')
let s:L= s:V.import('Data.List')
let s:H= s:V.import('Web.HTTP')
let s:X= s:V.import('Web.HTML')
let s:S= s:V.import('Data.String')
let s:P= s:V.import('Process')
unlet s:V

function! s:gather_from_javadoc(config) " {{{
    let l:response= s:H.get(a:config.path.'/allclasses-noframe.html')

    if !l:response.success
        return []
    endif

    let l:li_of_classes= filter(split(l:response.content, "\n"), 'v:val =~# "^<li>.*</li>$"')

    return map(l:li_of_classes, 's:new_candidate(a:config, s:to_class_name_for_javadoc(v:val))')
endfunction

function! s:to_class_name_for_javadoc(li_of_class)
    let l:html= substitute(a:li_of_class, '^.*\<href\>="\([a-zA-Z0-9/\._]\+\)\.html".*$', '\1', '')

    return substitute(l:html, '/', '.', 'g')
endfunction
" }}}
function! s:gather_from_directory(config) " {{{
    let l:fullpath= fnamemodify(a:config.path, ':p')
    let l:cmd= join(
    \   [
    \       'ctags',
    \       '-f -',
    \       '--language-force=java',
    \       '--langmap=Java:.java',
    \       '--java-kinds=cgi',
    \       '--recurse=yes',
    \       '--extra=q',
    \       l:fullpath,
    \   ],
    \   ' '
    \)
    let l:outputs= split(s:P.system(l:cmd), "\n")

    " filter if non-public
    let l:tags= map(l:outputs, 'split(v:val, "\t")')
    let l:tags= map(l:tags, '{"tag": v:val[0], "filename": v:val[1], "declaration": v:val[2]}')
    let l:tags= filter(l:tags, 'v:val.declaration =~# ''\<public\>''')

    " make filename to package
    for l:tag in l:tags
        let l:package= l:tag.filename
        " remove path to dir
        let l:package= substitute(l:package, l:fullpath, '', '')
        " remove base filename
        let l:package= substitute(l:package, '[/\\]\w\+\.java$', '', '')
        " replace / to .
        let l:package= substitute(l:package, '[/\\]\+', '.', 'g')

        let l:tag.package= l:package
    endfor

    return map(map(l:tags, 'v:val.package . "." . v:val.tag'), 's:new_candidate(a:config, v:val)')
endfunction
" }}}
function! s:gather_from_jar(config) " {{{
    let l:debug_mode= ''
    if g:javaimport_config.debug_mode
        let l:debug_mode= '--debug'
    endif
    let l:cmd= join(
    \   [
    \       expand('$JAVA_HOME') . '/bin/java',
    \       '-jar', javaimport#jar_path(),
    \       '--recurse',
    \       '--path', fnamemodify(a:config.path, ':p'),
    \       l:debug_mode,
    \   ],
    \   ' '
    \)

    if g:javaimport_config.debug_mode
        echomsg l:cmd
    endif

    return map(split(vimproc#system(l:cmd), "\n"), 's:new_candidate(a:config, v:val)')
endfunction
" }}}
function! s:gather_from_unknown(path) " {{{
    " TODO
    return []
endfunction
" }}}
function! s:new_candidate(config, canonical_name) " {{{
    let l:javadoc_url= ''

    if !empty(a:config.javadoc)
        let l:javadoc_url= javaimport#to_javadoc_url(a:config.javadoc, a:canonical_name)
    endif

    return {
    \   'word'          : a:canonical_name,
    \   'canonical_name': a:canonical_name,
    \   'javadoc_url'   : l:javadoc_url,
    \}
endfunction
" }}}
let s:source= {
\   'name'           : 'javaimport',
\   'description'    : 'candidates from classes in current classpath.',
\   'sorters'        : ['sorter_word'],
\   'max_candidates' : 100,
\}
function! unite#sources#javaimport#define() " {{{
    return s:source
endfunction
" }}}
function! s:source.gather_candidates(args, context) " {{{
    let l:configs= javaimport#import_config()

    let l:classes= []
    for l:config in l:configs
        if javaimport#has_cache(l:config) && !g:javaimport_config.debug_mode
            call add(l:classes, javaimport#read_cache(l:config))
        else
            let l:items= s:gather_from_{l:config.type}(l:config)

            call javaimport#write_cache(l:config, l:items)

            call add(l:classes, l:items)
        endif
    endfor

    let l:classes= s:L.flatten(l:classes)

    let l:args= javaimport#build_args(a:args)

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
" }}}

let &cpo= s:save_cpo
unlet s:save_cpo

" vim:foldenable:foldmethod=marker
