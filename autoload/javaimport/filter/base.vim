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

"
" filter object has:
"   apply as funcref, it can takes 1 list arg, it returns copied list was filtered
"   __regexes as list, it has some regex object
"
" regex object has:
"   apply as funcref, it can take 1 string arg, it returns 1 or 0 means matched or not
"
let s:filter= {
\   '__regexes': [],
\}

function! s:test(value) dict
    let res= 1
    for regex in self.__regexes
        let res= res && regex.apply(a:value)
    endfor
    return res
endfunction

function! s:filter.apply(list)
    let list= copy(a:list)

    return filter(list, 'call("s:test", [v:val], self)')
endfunction

function! javaimport#filter#base#new()
    return deepcopy(s:filter)
endfunction

let &cpo= s:save_cpo
unlet s:save_cpo
