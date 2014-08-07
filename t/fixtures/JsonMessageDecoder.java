package jp.michikusa.chitose.unitejavaimport.server;

import static com.google.common.base.Preconditions.checkArgument;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.util.Map;

import jp.michikusa.chitose.unitejavaimport.server.request.CommonRequest;

import net.arnx.jsonic.JSON;
import net.arnx.jsonic.JSONException;

import org.apache.mina.core.buffer.IoBuffer;
import org.apache.mina.core.session.IoSession;
import org.apache.mina.filter.codec.CumulativeProtocolDecoder;
import org.apache.mina.filter.codec.ProtocolDecoderOutput;

public class JsonMessageDecoder extends CumulativeProtocolDecoder
{
    @Override
    protected boolean doDecode(IoSession session, IoBuffer in, ProtocolDecoderOutput out) throws Exception
    {
        // header
        // 8 bytes - request byte length for hex decimal as chars
        // rest bytes - content
        if(in.remaining() < 8)
        {
            return false;
        }

        final int save_pos= in.position();

        final int byte_length= this.parseHeader(in);

        if(in.remaining() < byte_length)
        {
            in.position(save_pos);
            return false;
        }

        try(final ByteArrayInputStream istream= new ByteArrayInputStream(this.readContent(in, byte_length)))
        {
            final Map<String, Object> json= JSON.decode(istream);

            out.write(new CommonRequest(json));

            return true;
        }
        catch(IOException | JSONException e)
        {
            e.printStackTrace();
            in.position(save_pos);
            return false;
        }
    }

    private int parseHeader(IoBuffer in)
    {
        final byte[] buf= new byte[8];

        in.get(buf);

        return Integer.valueOf(new String(buf), 16);
    }

    private byte[] readContent(IoBuffer in, int length)
    {
        checkArgument(length >= 0);

        if(length == 0)
        {
            return new byte[0];
        }

        final byte[] buf= new byte[length];

        in.get(buf, 0, length);

        return buf;
    }
}
