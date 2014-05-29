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
    let l:fullpath= fnamemodify(a:config.path, ':p')
    let l:cmd= join(
    \   [
    \       get(a:config, 'ctags', 'ctags'),
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

function! javaimport#source#directory#define()
    return deepcopy(s:source)
endfunction

let &cpo= s:save_cpo
unlet s:save_cpo
