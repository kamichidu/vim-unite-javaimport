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

let s:source= {
\   'name': 'directory',
\}

function! s:source.gather_classes(config, context)
    let tags= s:execute_ctags(a:config.path)

    return map(tags, "
    \   {
    \       'word':           v:val.package . '.' . v:val.class,
    \       'canonical_name': v:val.package . '.' . v:val.class,
    \       'simple_name':    v:val.class,
    \       'javadoc_url':    '',
    \       'jar_path':       '',
    \   }
    \")
endfunction

function! s:execute_ctags(path)
    let save_cwd= getcwd()
    try
        execute 'lcd' a:path
        let cmd= join(
        \   [
        \       'ctags',
        \       '-f', '-',
        \       '--langmap=Java:.java',
        \       '--java-kinds=cgi',
        \       '--recurse=yes',
        \       '--extra=q',
        \   ],
        \   ' '
        \)
        let output= map(split(vimproc#system(cmd), '\%(\r\n\|\r\|\n\)'), 'split(v:val, "\t", 1)')

        let tags= []

        for tag in output
            let [tagname, tagfile, tagaddress, tagkind]= tag[0 : 3]

            let package= tagfile
            let package= substitute(package, '\c\.java$', '', '')
            let package= substitute(package, '\%(/\|\\\)\+', '.', 'g')
            let package= substitute(package, '^\.\+', '', '')
            let package= substitute(package, '\C\.' . tagname . '$', '', '')

            let modifiers= {
            \   'is_public':    match(tagaddress, '\C\<public\>') != -1,
            \   'is_protected': match(tagaddress, '\C\<protected\>') != -1,
            \   'is_private':   match(tagaddress, '\C\<private\>') != -1,
            \}

            let tags+= [{
            \   'class':     tagname,
            \   'package':   package,
            \   'modifiers': modifiers,
            \   'kind':      tagkind,
            \   'file':      fnamemodify(tagfile, ':p'),
            \}]
        endfor

        return tags
    finally
        execute 'lcd' save_cwd
    endtry
endfunction

function! javaimport#source#directory#define()
    return deepcopy(s:source)
endfunction

let &cpo= s:save_cpo
unlet s:save_cpo
