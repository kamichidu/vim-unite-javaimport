" ----------------------------------------------------------------------------
" File:        plugin/javaimport.vim
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
if exists('g:loaded_javaimport') && g:loaded_javaimport
    finish
endif
let g:loaded_javaimport= 1

let s:save_cpo= &cpo
set cpo&vim

let g:javaimport_version= '0.01'

let g:javaimport_config= get(g:, 'javaimport_config', {})
let g:javaimport_config.cache_dir= get(g:javaimport_config, 'cache_dir', g:unite_data_directory . '/javaimport/')
let g:javaimport_config.preview_using= get(g:javaimport_config, 'preview_using', 'w3m')

command! JavaImportClearCache call javaimport#clear_cache()
command! JavaImportSortStatements call javaimport#sort_import_statements()

let &cpo= s:save_cpo
unlet s:save_cpo

" vim:foldenable:foldmethod=marker

