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

let s:filter= javaimport#filter#package#new()

let s:filter.__package_expr= 'v:val.package'
let s:filter.__simple_name_expr= 'v:val.simple_name'
let s:filter.__classname= []

function! s:filter.classname(name)
    let self.__classname+= [a:name]
endfunction

let s:_make_expr= s:filter._make_expr
function! s:filter._make_expr()
    let expr= call(s:_make_expr, [], self)

    if !empty(self.__classname)
        let expr+= [printf("%s =~# '%s'", self.__simple_name_expr, '\C^\%(' . join(map(copy(self.__classname), 'escape(v:val, ".")'), '\|') . '\)$')]
    endif

    return expr
endfunction

function! javaimport#filter#class#new()
    return deepcopy(s:filter)
endfunction

let &cpo= s:save_cpo
unlet s:save_cpo
