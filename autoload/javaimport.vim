" ----------------------------------------------------------------------------
" File:        autoload/javaimport.vim
" Last Change: 02-Jul-2013.
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
let s:save_cpo= &cpo
set cpo&vim

"""
" importの設定を返す
"
" @return
"   次の形式に則ったDictionaryのList
"   [
"       {
"           'path': 'path/to/item', 
"           'type': {'jar'|'file'|'javadoc'}, 
"           'javadoc': 'path/to/javadoc', 
"       }, 
"   ]
""
function! javaimport#import_config() " {{{
    if !filereadable('.javaimport')
        return []
    endif

    perl << END
use YAML::Syck;
use JSON::Syck;

my $data= YAML::Syck::LoadFile './.javaimport';

my @result;
foreach my $key (keys %$data)
{
    my $type;
    if($key ~~ qr|^http://|m)
    {
        $type= 'javadoc';
    }
    elsif($key ~~ qr|\.jar$|m)
    {
        $type= 'jar';
    }
    elsif(-d $key)
    {
        $type= 'directory';
    }
    else
    {
        $type= 'unknown';
    }

    my $javadoc;
    if(exists $data->{$key}{javadoc})
    {
        $javadoc= $data->{$key}{javadoc};
    }
    else
    {
        $javadoc= '';
    }

    push @result, {
        path => $key, 
        type => $type, 
        javadoc => $javadoc, 
    };
}

my $json= JSON::Syck::Dump \@result;
VIM::DoCommand("let l:result= $json");

1;
END

    return l:result
endfunction
" }}}

"""
" javadocのurlを得る
"
" @param  base_url       javadocのルートurl
" @param  canonical_name クラス名
" @return
"   canonical_nameのjavadoc url
""
function! javaimport#to_javadoc_url(base_url, canonical_name) " {{{
    " TODO: more effective implementation.
    let l:elms= split(a:canonical_name, '\.')

    let l:result= a:base_url.'/'
    for l:elm in l:elms
        if l:elm =~# '^\U'
            let l:result.= l:elm.'/'
        else
            let l:result.= l:elm.'.'
        endif
    endfor

    return l:result.'html'
endfunction
" }}}

let &cpo= s:save_cpo
unlet s:save_cpo

" vim:foldenable:foldmethod=marker

