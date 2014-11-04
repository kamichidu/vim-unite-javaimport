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

function! s:_vital_loaded(V)
    let s:L= a:V.import('Data.List')
endfunction

function! s:_vital_depends()
    return ['Data.List']
endfunction

"
" add('java.util.Map', ...)
" add({'class': 'java.util.Map'}, ...)
" add({'class': 'java.lang.Boolean', 'field': 'TRUE'}, ...)
" add({'class': 'java.util.Arrays', 'method': 'asList'}, ...)
"
function! s:add(...)
    let data= s:_trans_args(a:000)
    let classes= filter(copy(data), '!has_key(v:val, "field") && !has_key(v:val, "method")')
    let fields=  filter(copy(data), 'has_key(v:val, "field")')
    let methods= filter(copy(data), 'has_key(v:val, "method")')

    let save_pos= getpos('.')
    try
        let [_, elnum]= s:region()

        if elnum == 0
            let elnum= s:_search_package_declaration()
        endif

        call append(elnum,
        \   map(copy(classes), 'printf("import %s;", v:val.class)') +
        \   map(copy(fields),  'printf("import static %s.%s;", v:val.class, v:val.field)') +
        \   map(copy(methods), 'printf("import static %s.%s;", v:val.class, v:val.method)')
        \)

        call s:sort()
    finally
        " let delta= len(after_classes) - len(before_classes)
        let delta= 0
        let [bufnum, lnum, col, off]= save_pos
        call setpos('.', [bufnum, lnum + delta, col, off])
    endtry
endfunction

function! s:remove(...)
    let data= s:_trans_args(a:000)
    let classes= map(filter(copy(data), '!has_key(v:val, "field") && !has_key(v:val, "method")'), 'v:val.class')
    let fields_and_methods= map(filter(copy(data), 'has_key(v:val, "field")'), 'v:val.class . "." . v:val.field') +
    \   map(filter(copy(data), 'has_key(v:val, "method")'), 'v:val.class . "." . v:val.method')

    let filtered_classes= []
    for class in s:imported_classes()
        if !s:L.has(classes, class)
            let filtered_classes+= [{'class': class}]
        endif
    endfor

    let filtered_fields_and_methods= []
    for field_or_method in s:imported_fields_and_methods()
        if !s:L.has(fields_and_methods, field_or_method)
            let filtered_fields_and_methods+= [{'class': join(split(field_or_method, '\.')[ : -2], '.'), 'field': split(field_or_method, '\.')[-1]}]
        endif
    endfor

    let [slnum, elnum]= s:region()

    if [slnum, elnum] == [0, 0]
        return
    endif

    execute slnum . ',' . elnum .  'delete _'

    call s:add(filtered_classes + filtered_fields_and_methods)
endfunction

function! s:sort()
    let save_pos= getpos('.')
    try
        " gather already existed import statements
        let [slnum, elnum]= s:region()

        if [slnum, elnum] == [0, 0]
            return
        endif

        let before_nlines= elnum - slnum

        let classes= s:imported_classes()
        let fields_and_methods= s:imported_fields_and_methods()

        call sort(classes)
        call sort(fields_and_methods)

        " separate each statements on defferent top-level domain
        let statements= []
        if !empty(classes)
            let last_domain= split(get(classes, 0, ''), '\.')[0]
            for class in classes
                let domain= split(class, '\.')[0]

                if domain !=# last_domain
                    let statements+= ['']
                endif

                let statements+= [printf('import %s;', class)]

                let last_domain= domain
            endfor
        endif

        if !empty(fields_and_methods)
            if !empty(classes)
                let statements+= ['']
            endif

            let last_domain= split(fields_and_methods[0], '\.')[0]
            for field_or_method in fields_and_methods
                let domain= split(field_or_method, '\.')[0]

                if domain !=# last_domain
                    let statements+= ['']
                endif

                let statements+= [printf('import static %s;', field_or_method)]

                let last_domain= domain
            endfor
        endif

        " adjust margins
        if prevnonblank(slnum - 1) > 0
            let statements= [''] + statements
        endif
        while slnum - 1 > 0 && empty(getline(slnum - 1))
            let slnum-= 1
        endwhile
        if prevnonblank(elnum + 1) > 0
            let statements+= ['']
        endif
        while elnum + 1 <= line('$') && empty(getline(elnum + 1))
            let elnum+= 1
        endwhile

        execute slnum . ',' . elnum . 'delete _'

        if slnum - 1 > line('$')
            call setline(slnum - 1, statements)
        else
            call append(slnum - 1, statements)
        endif

        let [slnum, elnum]= s:region()

        let after_nlines= elnum - slnum
    finally
        if exists('before_nlines') && exists('after_nlines')
            let delta= after_nlines - before_nlines
        else
            let delta= 0
        endif
        let [bufnum, lnum, col, off]= save_pos
        call setpos('.', [bufnum, lnum + delta, col, off])
    endtry
endfunction

function! s:region()
    let save_pos= getpos('.')
    try
        call cursor(1, 1)
        while 1
            let slnum= search('\C\<import\>', 'Wce')

            if slnum == 0 || s:_syntax_of() !~# '\c\%(comment\)'
                break
            endif

            normal w
        endwhile

        call cursor(line('$'), 1)
        call cursor(line('$'), col('$'))
        while 1
            let elnum= search('\C\<import\>', 'Wb')

            if elnum == 0 || s:_syntax_of() !~# '\c\%(comment\)'
                break
            endif

            normal b
        endwhile

        if slnum != 0 && elnum != 0
            return [slnum, elnum]
        endif

        return [0, 0]
    finally
        call setpos('.', save_pos)
    endtry
endfunction

function! s:imported_classes()
    let [slnum, elnum]= s:region()

    if [slnum, elnum] ==# [0, 0]
        return []
    endif

    let classes= getline(slnum, elnum)
    let classes= filter(classes, 'v:val =~# ''\C^\s*\<import\>''')
    let classes= filter(classes, 'v:val !~# ''\C^\s*\<import\>\s\+\<static\>''')
    let classes= map(classes, 'matchstr(v:val, ''\C^\s*\<import\>\s\+\zs[^;]\+\ze;'')')
    let classes= map(classes, 'substitute(v:val, ''\s\+'', "", "g")')

    return s:L.uniq(classes)
endfunction

function! s:imported_fields_and_methods()
    let [slnum, elnum]= s:region()

    if [slnum, elnum] ==# [0, 0]
        return []
    endif

    let statics= getline(slnum, elnum)
    let statics= filter(statics, 'v:val =~# ''\C^\s*\<import\>\s\+\<static\>''')
    let statics= map(statics, 'matchstr(v:val, ''\C^\s*\<import\>\s\+\<static\>\s\+\zs[^;]\+\ze;'')')
    let statics= map(statics, 'substitute(v:val, ''\s\+'', "", "g")')

    return s:L.uniq(statics)
endfunction

function! s:_trans_args(...)
    let args= []
    for arg in a:000
        if type(arg) == type('')
            let args+= [{'class': arg}]
        elseif type(arg) == type({})
            let args+= [arg]
        elseif type(arg) == type([])
            let args+= call('s:_trans_args', arg)
        endif
    endfor
    return args
endfunction

function! s:_syntax_of()
    return synIDattr(synID(line('.'), col('.'), 1), 'name')
endfunction

function! s:_search_package_declaration()
    let save_pos= getpos('.')
    try
        call cursor(1, 1)
        while 1
            let lnum= search('\C\<package\>', 'Wce')

            if lnum == 0 || s:_syntax_of() !~# '\c\%(comment\)'
                break
            endif

            normal w
        endwhile

        return lnum
    finally
        call setpos('.', save_pos)
    endtry
endfunction

let &cpo= s:save_cpo
unlet s:save_cpo
