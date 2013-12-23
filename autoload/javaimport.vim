" ----------------------------------------------------------------------------
" File:        autoload/javaimport.vim
" Last Change: 23-Dec-2013.
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
let s:FILE= s:V.import('System.File')
let s:CACHE= s:V.import('System.Cache')
let s:JSON= s:V.import('Web.JSON')
unlet s:V

"""
" importの設定を返す
"
" @return
"   次の形式に則ったDictionaryのList
"   [
"       {
"           'path': 'path/to/item', 
"           'type': {'jar'|'file'|'javadoc'}, 
"           'javadoc': 'path/to/javadoc', 
"       }, 
"   ]
""
function! javaimport#import_config() " {{{
    if !filereadable('.javaimport')
        return []
    endif

    let l:sources= s:JSON.decode('[' . join(readfile('.javaimport'), "\n") . ']')
    let l:result= []

    for l:source in l:sources
        let l:path= l:source.path
        let l:type= ''
        if l:path =~# '^http://'
            let l:type= 'javadoc'
        elseif l:path =~# '\.jar$'
            let l:type= 'jar'
        elseif isdirectory(l:path)
            let l:type= 'directory'
        else
            let l:type= 'unknown'
        endif

        let l:javadoc= (has_key(l:source, 'javadoc')) ? l:source.javadoc : ''

        call add(l:result, {
        \   'path': l:path,
        \   'type': l:type,
        \   'javadoc': l:javadoc,
        \})
    endfor

    return l:result
endfunction
" }}}

"""
" javadocのurlを得る
"
" @param  base_url       javadocのルートurl
" @param  canonical_name クラス名
" @return
"   canonical_nameのjavadoc url
""
function! javaimport#to_javadoc_url(base_url, canonical_name) " {{{
    " TODO: more effective implementation.
    let l:elms= split(a:canonical_name, '\.')

    let l:result= a:base_url.'/'
    for l:elm in l:elms
        if l:elm =~# '^\U'
            let l:result.= l:elm.'/'
        else
            let l:result.= l:elm.'.'
        endif
    endfor

    return l:result.'html'
endfunction
" }}}

"""
" 2つのListの各要素について、exprを評価した結果を新しいListに格納して返す
"
" @param expr 式中に含まれるv:aはlhsの各要素に、v:bはrhsに各要素にそれぞれ置き換えらて評価される。
" @param lhs List
" @param rhs List
" @return
"   lhsとrhsの各要素について、exprの評価結果を格納したList
" @throw lhsもしくはrhsがListでなかった場合、lhsとrhsの要素数が一致しない場合
""
function! javaimport#each(expr, lhs, rhs) " {{{
    if !(type(a:lhs) == type(a:rhs) && type(a:lhs) == type([]) && len(a:lhs) == len(a:rhs))
        throw 'illegal argument'
    endif

    let l:indices= range(0, len(a:lhs) - 1)
    let l:result= []
    for l:index in l:indices
        let l:expr= a:expr
        let l:expr= substitute(l:expr, '\<v:a\>', string(a:lhs[l:index]), 'g')
        let l:expr= substitute(l:expr, '\<v:b\>', string(a:rhs[l:index]), 'g')

        call add(l:result, eval(l:expr))
    endfor
    return l:result
endfunction
" }}}

"""
" an executable jar path.
"
" @return full path
""
function! javaimport#jar_path() " {{{
    return globpath(&runtimepath, 'autoload/unite-javaimport-0.01-jar-with-dependencies.jar')
endfunction
" }}}

"""
" clear cache.
"
""
function! javaimport#clear_cache() " {{{
    let l:cachedir= g:javaimport_config.cache_dir

    " check exist
    if !isdirectory(l:cachedir)
        return
    endif

    call s:FILE.rmdir(l:cachedir, 'r')
endfunction
" }}}

"""
" check existing cache for config.
"
" @param config
""
function! javaimport#has_cache(config) " {{{
    return s:CACHE.filereadable(g:javaimport_config.cache_dir, a:config.path)
endfunction
" }}}

"""
" read candidates from cache.
"
" @param config
" @return [{success}, {data}]
""
function! javaimport#read_cache(config) " {{{
    let l:cachedir= g:javaimport_config.cache_dir

    call s:CACHE.check_old_cache(l:cachedir, a:config.path)

    if !s:CACHE.filereadable(l:cachedir, a:config.path)
        return []
    endif

    let l:cache= eval(get(s:CACHE.readfile(l:cachedir, a:config.path), 0, '{}'))

    if empty(l:cache)
        return []
    endif

    if l:cache.meta.version !=# g:javaimport_version
        call s:CACHE.deletefile(l:cachedir, a:config.path)
        return []
    endif

    return l:cache.data
endfunction
" }}}

"""
" write items to cache.
"
" @param config
" @param items
""
function! javaimport#write_cache(config, items) " {{{
    let l:cachedir= g:javaimport_config.cache_dir

    call s:CACHE.deletefile(l:cachedir, a:config.path)
    call s:CACHE.writefile(l:cachedir, a:config.path, [string({
    \   'meta': {
    \       'version': g:javaimport_version,
    \   },
    \   'data': a:items,
    \})])
endfunction
" }}}

"""
" sort import statements on current buffer.
"
" before:
"   import java.util.Map;
"   import java.util.Collection;
"   import org.apache.commons.lang.StringUtils;
"
" after:
"   import java.util.Collection;
"   import java.util.Map;
"
"   import org.apache.commons.lang.StringUtils;
"
""
function! javaimport#sort_import_statements() " {{{
    let l:save_pos= getpos('.')
    try
        " gather already existed import statements
        call setpos('.', [0, 1, 1, 0])
        let l:start_lnum= search('^\s*\<import\>', 'cn')

        call setpos('.', [0, line('$'), 1, 0])
        let l:end_lnum= search('^\s*\<import\>', 'cnb')

        if [l:start_lnum, l:end_lnum] ==# [0, 0]
            return
        endif

        let l:classes= getbufline('%', l:start_lnum, l:end_lnum)
        let l:classes= filter(l:classes, 'v:val =~# ''^\s*\<import\>''')
        let l:classes= map(l:classes, 'matchstr(v:val, ''^\s*import\s\+\<\zs[^;]\+\ze'')')

        call sort(l:classes)

        " separate each statements on defferent top-level domain
        let l:statements= []
        let l:last_domain= matchstr(l:classes[0], '^\w\+')
        for l:class in l:classes
            let l:domain= matchstr(l:class, '^\w\+')

            if l:domain !=# l:last_domain
                call add(l:statements, '')
            endif

            call add(l:statements, printf('import %s;', l:class))

            let l:last_domain= l:domain
        endfor

        execute l:start_lnum . ',' . l:end_lnum . 'delete _'

        call append(l:start_lnum - 1, l:statements)
    finally
        call setpos('.', l:save_pos)
    endtry
endfunction
" }}}

let &cpo= s:save_cpo
unlet s:save_cpo

" vim:foldenable:foldmethod=marker

