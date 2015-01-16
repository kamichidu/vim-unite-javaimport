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

let s:is_windows = has('win16') || has('win32') || has('win64') || has('win95')

" XXX: Modified version of Vital.Process.spawn()
function! javaimport#util#spawn(expr, ...)
  let shellslash = 0
  if s:is_windows
    let shellslash = &l:shellslash
    setlocal noshellslash
  endif
  try
    if type(a:expr) is type([])
      let special = 1
      let cmdline = join(map(a:expr, 'shellescape(v:val, special)'), ' ')
    elseif type(a:expr) is type('')
      let cmdline = a:expr
      if a:0 && a:1
        " for :! command
        let cmdline = substitute(cmdline, '\([!%#]\|<[^<>]\+>\)', '\\\1', 'g')
      endif
    else
      throw 'Process.spawn(): invalid argument (value type:'.type(a:expr).')'
    endif
    if s:is_windows
      silent execute '!start' '/B' 'cmd' '/C' cmdline
    else
      silent execute '!' cmdline '&'
      redraw!
    endif
  finally
    if s:is_windows
      let &l:shellslash = shellslash
    endif
  endtry
  return ''
endfunction

let &cpo= s:save_cpo
unlet s:save_cpo
