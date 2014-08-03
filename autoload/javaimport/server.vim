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
let s:J= javaimport#Web_JSON()

let s:server= {
\   'sequence': 0,
\   'past_response': [],
\}

function! s:server.socket()
    if has_key(self, 'vp_socket')
        return self.vp_socket
    endif

    let self.vp_socket= vimproc#socket_open(self.host, self.port)

    return self.socket()
endfunction

function! s:server.request(data)
    let data= deepcopy(a:data)

    let self.sequence+= 1
    let data.identifier= printf('%d-%d', getpid(), self.sequence)

    let request= s:J.encode(data)
    let request_length= len(split(request, '\zs'))

    let socket= self.socket()
    call socket.write(join([printf('%08x', request_length), request], ''))

    " return ticket object
    return {
    \   'identifier': data.identifier,
    \   'command': data.command,
    \}
endfunction

function! s:server.receive(ticket)
    let socket= self.socket()
    let header= socket.read(8)

    " read a new response
    if len(split(header, '\zs')) == 8
        let length= str2nr(header, 16)
        let responsestr= socket.read(length)

        if len(split(responsestr, '\zs')) == length
            let self.past_response+= [s:J.decode(responsestr)]
        endif
    endif

    for i in range(0, len(self.past_response) - 1)
        let response= self.past_response[i]

        if response.identifier ==# a:ticket.identifier
            call remove(self.past_response, i)

            return response
        endif
    endfor

    " not received yet
    return {}
endfunction

function! s:server.terminate()
    let clients= split(globpath(fnamemodify(self.lockfile, ':h'), '*.client'), '\%(\r\n\|\r\|\n\)')

    " connected only me
    if len(clients) == 1
        let server_pidfile= globpath(fnamemodify(self.lockfile, ':h'), '*.server')
        let server_pid= fnamemodify(server_pidfile, ':t:r')

        call vimproc#kill(server_pid, g:vimproc#SIGTERM)
    endif

    let clientfile= fnamemodify(self.lockfile, ':h') . printf('/%d.client', getpid())
    call delete(clientfile)
endfunction

function! javaimport#server#launch()
    let server= deepcopy(s:server)

    let server.host= g:javaimport_config.server.host
    let server.port= g:javaimport_config.server.port
    let server.lockfile= fnamemodify(g:javaimport_config.server.lockfile, ':p')
    " vimproc#popen3() delete '\' from path when 'shellslash' turned on
    let server.vm= expand(g:javaimport_config.server.vm)

    let jarpath= globpath(&runtimepath, 'bin/javaimport.jar')

    if !isdirectory(fnamemodify(server.lockfile, ':h'))
        call mkdir(fnamemodify(server.lockfile, ':h'), 'p')
    endif

    " call s:P.spawn(printf('%s -jar %s --port %d --lockfile %s', server.vm, jarpath, server.port, server.lockfile))
    call vimproc#system_bg(printf('%s -jar %s --port %d --lockfile %s', server.vm, jarpath, server.port, server.lockfile))

    let clientfile= fnamemodify(server.lockfile, ':h') . printf('/%d.client', getpid())
    call writefile([], clientfile)

    while !filereadable(server.lockfile)
        sleep 100m
    endwhile

    return server
endfunction

let &cpo= s:save_cpo
unlet s:save_cpo
