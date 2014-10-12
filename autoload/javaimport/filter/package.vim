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

let s:filter= javaimport#filter#base#new()

" name: 'java.util' or 'util', ...
function! s:filter.contains(name)
    let regex= {'name': a:name}

    function! regex.apply(value)
        return stridx(a:value, self.name) != -1
    endfunction

    let self.__regexes+= [regex]
endfunction

" name: 'java.util' or ...
function! s:filter.exclude(name)
    let regex= {'name': escape(a:name, '.\')}

    function! regex.apply(value)
        return a:value !~# '\C^' . self.name . '\>'
    endfunction

    let self.__regexes+= [regex]
endfunction

function! javaimport#filter#package#new()
    return deepcopy(s:filter)
endfunction

let &cpo= s:save_cpo
unlet s:save_cpo
