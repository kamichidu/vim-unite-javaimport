filetype off
set runtimepath+=./.vim-test/vim-javalang/
set runtimepath+=./.vim-test/vim-javaclasspath/
runtime! plugin/*.vim
filetype plugin indent on

describe 'javaimport#import_manager'
    before
    end

    after
        close!
    end

    it 'gets a import statement region'
        new
        setfiletype java
        read `='t/fixtures/JsonMessageDecoder.java'`

        let obj= javaimport#import_manager#new()

        let region= obj.region()

        Expect region == [3, 17]
    end

    it 'gets imported classes'
        new
        setfiletype java
        read `='t/fixtures/JsonMessageDecoder.java'`

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

    it 'gets static imported fields or methods'
        new
        setfiletype java
        read `='t/fixtures/JsonMessageDecoder.java'`

        let obj= javaimport#import_manager#new()

        let fields_or_methods= obj.imported_statics()

        Expect fields_or_methods ==# ['com.google.common.base.Preconditions.checkArgument']
    end

    it 'adds a import statement'
        new
        setfiletype java
        read `='t/fixtures/JsonMessageDecoder.java'`

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

    it 'removes a import statement'
        new
        setfiletype java
        read `='t/fixtures/JsonMessageDecoder.java'`

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

    it 'adds a static import statement'
        new
        setfiletype java
        read `='t/fixtures/JsonMessageDecoder.java'`

        let obj= javaimport#import_manager#new()

        TODO
    end
end
