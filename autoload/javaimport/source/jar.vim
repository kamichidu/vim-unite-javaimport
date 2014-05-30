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

let s:P= javaimport#Process()

let s:source= {
\   'name': 'jar',
\}

function! s:source.gather_classes(config, context)
    let start_time= reltime()
    call self.launch()
    PP! {'launch() ': reltimestr(reltime(start_time))}

    let start_time= reltime()
    call self.writeln('path clear')
    call self.wait_and_read()
    PP! {'wait_and_read() ': reltimestr(reltime(start_time))}

    let start_time= reltime()
    call self.writeln('path add ' . a:config.path)
    call self.wait_and_read()
    PP! {'wait_and_read() ': reltimestr(reltime(start_time))}

    let start_time= reltime()
    call self.writeln('list --public --exclude_package ' . join(g:javaimport_config.exclude_packages, ','))

    let [output, error]= self.wait_and_read()
    PP! {'wait_and_read() ': reltimestr(reltime(start_time))}

    return map(split(output, '\r\=\n'), "
    \   {
    \       'word':           v:val,
    \       'canonical_name': v:val,
    \       'simple_name':    v:val,
    \       'javadoc_url':    '',
    \   }
    \")
endfunction

function! s:source.launch()
    if has_key(self, 'proc')
        return
    endif

    let self.ofile= tempname()

    let self.proc= vimproc#popen3(printf("%s/bin/java -jar %s --ofile %s", $JAVA_HOME, globpath(&runtimepath, 'bin/javaimport.jar'), self.ofile))

    call self.wait_and_read()
endfunction

function! s:source.writeln(s)
    call self.proc.stdin.write(a:s . "\n")
endfunction

function! s:source.wait_and_read()
    let [out, err]= ['', '']

    while !self.proc.stdout.eof
        let out.= self.proc.stdout.read()
        let err.= self.proc.stderr.read()

        if out =~# '\%(^\|\r\=\n\)\s>\s$'
            if filereadable(self.ofile)
                let content= join(readfile(self.ofile), "\n")

                call delete(self.ofile)

                return [content, err]
            else
                return [out, err]
            endif
        endif
    endwhile

    throw 'javaimport: illegal state, outer process was dead.'
endfunction

function! javaimport#source#jar#define()
    return deepcopy(s:source)
endfunction

let &cpo= s:save_cpo
unlet s:save_cpo
