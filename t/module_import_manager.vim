let s:suite= themis#suite('javaimport#import_manager')
let s:assert= themis#helper('assert')

function! s:suite.after_each()
    close!
endfunction

function! s:suite.gets_a_import_statement_region()
    new
    setfiletype java
    call setline(1, readfile('t/fixtures/JsonMessageDecoder.java'))

    let obj= javaimport#import_manager#new()

    let region= obj.region()

    call s:assert.equals(region, [3, 17])
endfunction

function! s:suite.gets_imported_classes()
    new
    setfiletype java
    call setline(1, readfile('t/fixtures/JsonMessageDecoder.java'))

    let obj= javaimport#import_manager#new()

    let classes= obj.imported_classes()

    call s:assert.equals(classes, [
    \   'java.io.ByteArrayInputStream',
    \   'java.io.IOException',
    \   'java.util.Map',
    \   'jp.michikusa.chitose.unitejavaimport.server.request.CommonRequest',
    \   'net.arnx.jsonic.JSON',
    \   'net.arnx.jsonic.JSONException',
    \   'org.apache.mina.core.buffer.IoBuffer',
    \   'org.apache.mina.core.session.IoSession',
    \   'org.apache.mina.filter.codec.CumulativeProtocolDecoder',
    \   'org.apache.mina.filter.codec.ProtocolDecoderOutput',
    \])
endfunction

function! s:suite.gets_static_imported_fields_or_methods()
    new
    setfiletype java
    call setline(1, readfile('t/fixtures/JsonMessageDecoder.java'))

    let obj= javaimport#import_manager#new()

    let fields_or_methods= obj.imported_statics()

    call s:assert.equals(fields_or_methods, ['com.google.common.base.Preconditions.checkArgument'])
endfunction

function! s:suite.adds_a_import_statement()
    new
    setfiletype java
    call setline(1, readfile('t/fixtures/JsonMessageDecoder.java'))

    let obj= javaimport#import_manager#new()

    call obj.add('java.util.HashMap')
    let classes= obj.imported_classes()

    call s:assert.equals(classes, [
    \   'java.io.ByteArrayInputStream',
    \   'java.io.IOException',
    \   'java.util.HashMap',
    \   'java.util.Map',
    \   'jp.michikusa.chitose.unitejavaimport.server.request.CommonRequest',
    \   'net.arnx.jsonic.JSON',
    \   'net.arnx.jsonic.JSONException',
    \   'org.apache.mina.core.buffer.IoBuffer',
    \   'org.apache.mina.core.session.IoSession',
    \   'org.apache.mina.filter.codec.CumulativeProtocolDecoder',
    \   'org.apache.mina.filter.codec.ProtocolDecoderOutput',
    \])

    call obj.add(['java.util.LinkedHashMap', 'java.util.LinkedList'])
    let classes= obj.imported_classes()

    call s:assert.equals(classes, [
    \   'java.io.ByteArrayInputStream',
    \   'java.io.IOException',
    \   'java.util.HashMap',
    \   'java.util.LinkedHashMap',
    \   'java.util.LinkedList',
    \   'java.util.Map',
    \   'jp.michikusa.chitose.unitejavaimport.server.request.CommonRequest',
    \   'net.arnx.jsonic.JSON',
    \   'net.arnx.jsonic.JSONException',
    \   'org.apache.mina.core.buffer.IoBuffer',
    \   'org.apache.mina.core.session.IoSession',
    \   'org.apache.mina.filter.codec.CumulativeProtocolDecoder',
    \   'org.apache.mina.filter.codec.ProtocolDecoderOutput',
    \])
endfunction

function! s:suite.removes_a_import_statement()
    new
    setfiletype java
    call setline(1, readfile('t/fixtures/JsonMessageDecoder.java'))

    let obj= javaimport#import_manager#new()

    call obj.remove('java.util.Map')
    let classes= obj.imported_classes()

    call s:assert.equals(classes, [
    \   'java.io.ByteArrayInputStream',
    \   'java.io.IOException',
    \   'jp.michikusa.chitose.unitejavaimport.server.request.CommonRequest',
    \   'net.arnx.jsonic.JSON',
    \   'net.arnx.jsonic.JSONException',
    \   'org.apache.mina.core.buffer.IoBuffer',
    \   'org.apache.mina.core.session.IoSession',
    \   'org.apache.mina.filter.codec.CumulativeProtocolDecoder',
    \   'org.apache.mina.filter.codec.ProtocolDecoderOutput',
    \])

    call obj.remove(['java.io.ByteArrayInputStream', 'java.io.IOException'])
    let classes= obj.imported_classes()

    call s:assert.equals(classes, [
    \   'jp.michikusa.chitose.unitejavaimport.server.request.CommonRequest',
    \   'net.arnx.jsonic.JSON',
    \   'net.arnx.jsonic.JSONException',
    \   'org.apache.mina.core.buffer.IoBuffer',
    \   'org.apache.mina.core.session.IoSession',
    \   'org.apache.mina.filter.codec.CumulativeProtocolDecoder',
    \   'org.apache.mina.filter.codec.ProtocolDecoderOutput',
    \])
endfunction

function! s:suite.adds_a_first_import_statement()
    new
    setfiletype java
    call setline(1, readfile('t/fixtures/NoImports.java'))

    let obj= javaimport#import_manager#new()

    call obj.add('java.util.Map')
    let classes= obj.imported_classes()

    call s:assert.equals(classes, ['java.util.Map'])
    call s:assert.equals(getline(1, '$'), [
    \   'package hoge;',
    \   '',
    \   'import java.util.Map;',
    \   '',
    \   'class NoImports',
    \   '{',
    \   '}',
    \])
endfunction

function! s:suite.adds_first_import_statements()
    new
    setfiletype java
    call setline(1, readfile('t/fixtures/NoImports.java'))

    let obj= javaimport#import_manager#new()

    call obj.add(['java.util.Map', 'java.util.List'])
    let classes= obj.imported_classes()

    call s:assert.equals(classes, ['java.util.List', 'java.util.Map'])
    call s:assert.equals(getline(1, '$'), [
    \   'package hoge;',
    \   '',
    \   'import java.util.List;',
    \   'import java.util.Map;',
    \   '',
    \   'class NoImports',
    \   '{',
    \   '}',
    \])
endfunction

function! s:suite.adds_a_static_import_statement()
    new
    setfiletype java
    call setline(1, readfile('t/fixtures/JsonMessageDecoder.java'))

    let obj= javaimport#import_manager#new()

    call s:assert.skip('static import feature is not implemented yet.')
endfunction
