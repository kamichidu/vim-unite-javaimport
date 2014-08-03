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

let s:H= javaimport#Web_HTTP()

let s:javadoc= {
\   'name':        'javadoc',
\   'description': 'gather importable candidates from javadoc',
\}

function! s:javadoc.gather_classes(config, context)
    let l:response= s:H.get(a:args.path.'/allclasses-noframe.html')

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

function! s:new_candidate(config, canonical_name) " {{{
    let l:javadoc_url= ''

    if !empty(a:config.javadoc)
        let l:javadoc_url= javaimport#to_javadoc_url(a:config.javadoc, a:canonical_name)
    endif

    return {
    \   'word'          : a:canonical_name,
    \   'canonical_name': a:canonical_name,
    \   'javadoc_url'   : l:javadoc_url,
    \   'jar_path':     : '',
    \}
endfunction

function! javaimport#source#javadoc#define()
    return deepcopy(s:javadoc)
endfunction

let &cpo= s:save_cpo
unlet s:save_cpo
