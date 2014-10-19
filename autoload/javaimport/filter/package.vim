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

if has('patch-7.3.1170')
    " name: 'java.util' or 'util', ...
    function! s:filter.contains(name)
        let self.__regexes+= [{
        \   'name': a:name,
        \   'apply': function('s:match_by_stridx'),
        \}]
    endfunction

    " name: 'java.util' or ...
    function! s:filter.exclude(name)
        let self.__regexes+= [{
        \   'name': escape(a:name, '.\'),
        \   'apply': function('s:match_prefix'),
        \}]
    endfunction

    function! s:filter.exclude_exactly(name)
        let self.__regexes+= [{
        \   'name': a:name,
        \   'apply': function('s:match_exactly'),
        \}]
    endfunction
else
    let s:contains_regex= {}

    function! s:contains_regex.apply(value)
        return call('s:match_by_stridx', [a:value], self)
    endfunction

    " name: 'java.util' or 'util', ...
    function! s:filter.contains(name)
        let regex= deepcopy(s:contains_regex)

        let regex.name= a:name

        let self.__regexes+= [regex]
    endfunction

    let s:exclude_regex= {}

    function! s:exclude_regex.apply(value)
        return call('s:match_prefix', [a:value], self)
    endfunction

    " name: 'java.util' or ...
    function! s:filter.exclude(name)
        let regex= deepcopy(s:exclude_regex)

        let regex.name= a:name

        let self.__regexes+= [regex]
    endfunction

    let s:exclude_exactly_regex= {}

    function! s:exclude_exactly_regex.apply(value)
        return call('s:match_exactly', [a:value], self)
    endfunction

    function! s:filter.exclude_exactly(name)
        let regex= deepcopy(s:exclude_exactly_regex)

        let regex.name= a:name

        let self.__regexes+= [regex]
    endfunction
endif

function! javaimport#filter#package#new()
    return deepcopy(s:filter)
endfunction

function! s:match_by_stridx(value) dict
    return stridx(a:value, self.name) != -1
endfunction

function! s:match_prefix(value) dict
    return a:value !~# '\C^' . self.name . '\>'
endfunction

function! s:match_exactly(value) dict
    return a:value !=# self.name
endfunction

let &cpo= s:save_cpo
unlet s:save_cpo
