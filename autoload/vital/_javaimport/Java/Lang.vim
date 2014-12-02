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

function! s:_vital_loaded(V) dict
    call extend(self, s:constants)
endfunction

function! s:_vital_depends()
    return []
endfunction

let s:constants= {}

" platform dependant keywords
if has("win32") || has("win64") || has("win16") || has("dos32") || has("dos16")
    let s:constants.separator= '\'
    let s:constants.path_separator= ';'
else
    let s:constants.separator= '/'
    let s:constants.path_separator= ':'
endif

" jls-3.9
let s:constants.keyword= [
\   'abstract',
\   'continue',
\   'for',
\   'new',
\   'switch',
\   'assert',
\   'default',
\   'if',
\   'package',
\   'synchronized',
\   'boolean',
\   'do',
\   'goto',
\   'private',
\   'this',
\   'break',
\   'double',
\   'implements',
\   'protected',
\   'throw',
\   'byte',
\   'else',
\   'import',
\   'public',
\   'throws',
\   'case',
\   'enum',
\   'instanceof',
\   'return',
\   'transient',
\   'catch',
\   'extends',
\   'int',
\   'short',
\   'try',
\   'char',
\   'final',
\   'interface',
\   'static',
\   'void',
\   'class',
\   'finally',
\   'long',
\   'strictfp',
\   'volatile',
\   'const',
\   'float',
\   'native',
\   'super',
\   'while',
\]
" jls-4.2
let s:constants.integral_type= ['byte', 'short', 'int', 'long', 'char']
let s:constants.floating_point_type= ['float', 'double']
let s:constants.numeric_type= s:constants.integral_type + s:constants.floating_point_type
let s:constants.primitive_type= s:constants.numeric_type + ['boolean']

let &cpo= s:save_cpo
unlet s:save_cpo
