filetype off
set runtimepath+=./.vim-test/vim-javalang/
set runtimepath+=./.vim-test/vim-javaclasspath/
runtime! plugin/*.vim
filetype plugin indent on

describe 'javaimport#import_manager'
    before
        new
        setfiletype java
        read `='t/fixtures/JsonMessageDecoder.java'`
    end

    after
        close!
    end

    it 'can get import statement region'
        let obj= javaimport#import_manager#new()

        let region= obj.region()

        Expect region == [3, 17]
    end

    it 'can get imported classes'
        let obj= javaimport#import_manager#new()

        let classes= obj.imported_classes()

        Expect classes ==# [
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
        \]
    end

    it 'can get static imported fields or methods'
        let obj= javaimport#import_manager#new()

        let fields_or_methods= obj.imported_statics()

        Expect fields_or_methods ==# ['com.google.common.base.Preconditions.checkArgument']
    end

    it 'can add import statement'
        let obj= javaimport#import_manager#new()

        call obj.add('java.util.HashMap')
        let classes= obj.imported_classes()

        Expect classes ==# [
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
        \]

        call obj.add(['java.util.LinkedHashMap', 'java.util.LinkedList'])
        let classes= obj.imported_classes()

        Expect classes ==# [
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
        \]
    end

    it 'can remove import statement'
        let obj= javaimport#import_manager#new()

        call obj.remove('java.util.Map')
        let classes= obj.imported_classes()

        Expect classes ==# [
        \   'java.io.ByteArrayInputStream',
        \   'java.io.IOException',
        \   'jp.michikusa.chitose.unitejavaimport.server.request.CommonRequest',
        \   'net.arnx.jsonic.JSON',
        \   'net.arnx.jsonic.JSONException',
        \   'org.apache.mina.core.buffer.IoBuffer',
        \   'org.apache.mina.core.session.IoSession',
        \   'org.apache.mina.filter.codec.CumulativeProtocolDecoder',
        \   'org.apache.mina.filter.codec.ProtocolDecoderOutput',
        \]

        call obj.remove(['java.io.ByteArrayInputStream', 'java.io.IOException'])
        let classes= obj.imported_classes()

        Expect classes ==# [
        \   'jp.michikusa.chitose.unitejavaimport.server.request.CommonRequest',
        \   'net.arnx.jsonic.JSON',
        \   'net.arnx.jsonic.JSONException',
        \   'org.apache.mina.core.buffer.IoBuffer',
        \   'org.apache.mina.core.session.IoSession',
        \   'org.apache.mina.filter.codec.CumulativeProtocolDecoder',
        \   'org.apache.mina.filter.codec.ProtocolDecoderOutput',
        \]
    end

    it 'can add static import statement'
        let obj= javaimport#import_manager#new()

        TODO
    end
end
