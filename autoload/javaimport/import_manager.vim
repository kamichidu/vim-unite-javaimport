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

let s:L= javaimport#vital('Data.List')

let s:prototype= {}

function! s:prototype.sort()
    let save_pos= getpos('.')
    try
        " gather already existed import statements
        let [slnum, elnum]= self.region()

        if [slnum, elnum] == [0, 0]
            return
        endif

        let before_nlines= elnum - slnum

        let classes= self.imported_classes()
        let statics= self.imported_statics()

        call sort(classes)
        call sort(statics)

        " separate each statements on defferent top-level domain
        let statements= []
        let last_domain= matchstr(get(classes, 0, ''), '^\w\+')
        for class in classes
            let domain= matchstr(class, '^\w\+')

            if domain !=# last_domain
                let statements+= ['']
            endif

            let statements+= [printf('import %s;', class)]

            let last_domain= domain
        endfor

        if !empty(statics)
            let statements+= ['']

            let last_domain= matchstr(get(statics, 0, ''), '^\w\+')
            for static in statics
                let domain= matchstr(static, '^\w\+')

                if domain !=# last_domain
                    let statements+= ['']
                endif

                let statements+= [printf('import static %s;', static)]

                let last_domain= domain
            endfor
        endif

        execute slnum . ',' . elnum . 'delete _'

        call append(slnum - 1, statements)

        let [slnum, elnum]= self.region()
        let after_nlines= elnum - slnum
    finally
        let delta= after_nlines - before_nlines
        let [bufnum, lnum, col, off]= save_pos
        call setpos('.', [bufnum, lnum + delta, col, off])
    endtry
endfunction

function! s:prototype.add(classes)
    let classes= (type(a:classes) == type([])) ? a:classes : [a:classes]

    let save_pos= getpos('.')
    try
        let [slnum, _]= self.region()

        let before_classes= self.imported_classes()
        let after_classes= s:L.uniq(before_classes + classes)

        " adjust margin
        if !empty(getline(slnum))
            call append(slnum, '')
            let slnum+= 1
        endif

        call append(slnum, map(after_classes, 'printf("import %s;", v:val)'))

        " adjust margin
        let [_, elnum]= self.region()

        if !empty(getline(elnum + 1))
            call append(elnum, '')
        endif

        call self.sort()
    finally
        let delta= len(after_classes) - len(before_classes)
        let [bufnum, lnum, col, off]= save_pos
        call setpos('.', [bufnum, lnum + delta, col, off])
    endtry
endfunction

" statics : [{'class': '', 'field': ''}, {'class': '', 'method': ''}]
function! s:prototype.add_static(statics)
    let statics= (type(a:statics) == type([])) ? a:statics : [a:statics]
    let fields= map(filter(copy(statics), 'has_key(v:val, "field")'), 'v:val.class . "." . v:val.field')
    let methods= map(filter(copy(statics), 'has_key(v:val, "method")'), 'v:val.class . "." . v:val.method')

    let save_pos= getpos('.')
    try
        let [slnum, _]= self.region()
        let before_classes= self.imported_classes()
        let after_classes= s:L.uniq(before_classes + classes)

        call append(slnum, map(after_classes, 'printf("import %s;", v:val)'))

        call self.sort()
    finally
        let delta= len(after_classes) - len(before_classes)
        let [bufnum, lnum, col, off]= save_pos
        call setpos('.', [bufnum, lnum + delta, col, off])
    endtry
endfunction

function! s:prototype.remove(classes)
    let classes= (type(a:classes) == type([])) ? a:classes : [a:classes]
    let imports= self.imported_classes()
    let imports= filter(imports, '!s:L.has(classes, v:val)')

    let [slnum, elnum]= self.region()

    execute slnum . ',' . elnum .  'delete _'

    call self.add(imports)
endfunction

function! s:prototype.region()
    let save_pos= getpos('.')
    try
        call setpos('.', [0, 1, 1, 0])
        let slnum= search('\C^\s*\<import\>', 'cn')

        call setpos('.', [0, line('$'), 1, 0])
        let elnum= search('\C^\s*\<import\>', 'cnb')

        if slnum != 0 && elnum != 0
            return [slnum, elnum]
        endif

        call setpos('.', [0, 1, 1, 0])
        let slnum= search('\C^\s*\<package\>', 'cn')

        return [slnum, slnum]
    finally
        call setpos('.', save_pos)
    endtry
endfunction

function! s:prototype.imported_classes()
    let save_pos= getpos('.')
    try
        let [slnum, elnum]= self.region()

        if [slnum, elnum] ==# [0, 0]
            return []
        endif

        let classes= getline(slnum, elnum)
        let classes= filter(classes, 'v:val =~# ''\C^\s*\<import\>''')
        let classes= filter(classes, 'v:val !~# ''\C^\s*\<import\>\s\+\<static\>''')
        let classes= map(classes, 'matchstr(v:val, ''\C^\s*\<import\>\s\+\zs[^;]\+\ze;'')')
        let classes= map(classes, 'substitute(v:val, ''\s\+'', "", "g")')

        return s:L.uniq(classes)
    finally
        call setpos('.', save_pos)
    endtry
endfunction

function! s:prototype.imported_statics()
    let save_pos= getpos('.')
    try
        let [slnum, elnum]= self.region()

        if [slnum, elnum] ==# [0, 0]
            return []
        endif

        let statics= getline(slnum, elnum)
        let statics= filter(statics, 'v:val =~# ''\C^\s*\<import\>\s\+\<static\>''')
        let statics= map(statics, 'matchstr(v:val, ''\C^\s*\<import\>\s\+\<static\>\s\+\zs[^;]\+\ze;'')')
        let statics= map(statics, 'substitute(v:val, ''\s\+'', "", "g")')

        return s:L.uniq(statics)
    finally
        call setpos('.', save_pos)
    endtry
endfunction

function! javaimport#import_manager#new()
    return deepcopy(s:prototype)
endfunction

let &cpo= s:save_cpo
unlet s:save_cpo
