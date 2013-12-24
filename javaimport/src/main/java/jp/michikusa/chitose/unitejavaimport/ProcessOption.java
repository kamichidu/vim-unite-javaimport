package jp.michikusa.chitose.unitejavaimport;

import com.google.common.collect.ImmutableCollection;
import com.google.common.collect.ImmutableSet;

import javax.tools.JavaFileManager;
import javax.tools.StandardLocation;

import org.kohsuke.args4j.Option;

/**
 * cli option class.
 *
 * @author kamichidu
 * @since 2013-12-22
 */
public class ProcessOption
{
    public boolean helpFlag()
    {
        return this.help_flag;
    }

    public boolean recursive()
    {
        return this.recursive;
    }

    public String packageName()
    {
        return this.package_name;
    }

    public ImmutableCollection<JavaFileManager.Location> locations()
    {
        final String[] locations= this.locations.split(",");
        final ImmutableSet.Builder<JavaFileManager.Location> s= ImmutableSet.builder();

        for(final String location : locations)
        {
            if("platform".equals(location))
            {
                s.add(StandardLocation.PLATFORM_CLASS_PATH);
            }
            else if("user".equals(location))
            {
                s.add(StandardLocation.CLASS_PATH);
            }
        }

        return s.build();
    }

    public String target()
    {
        return this.target;
    }

    public <T> T debug(T ref)
    {
        if(this.debug)
        {
            System.err.println(ref);
        }
        return ref;
    }

    public <T> T debug(T ref, String message)
    {
        if(this.debug)
        {
            System.err.println(message + ": " + ref);
        }
        return ref;
    }

    @Option(name= "-h", aliases= "--help", usage= "show this message")
    private boolean help_flag= false;

    @Option(name= "-r", aliases= "--recursive", usage= "dump packages recursively (default: not recursive)")
    private boolean recursive= false;

    @Option(name= "-p", aliases= "--package", usage= "dump packages via (default: '')")
    private String package_name= "";

    @Option(name= "-l", aliases= "--location", usage= "location list that will be dumped classes (default: 'platform,user')(possible values are 'platform', 'user')")
    private String locations= "platform,user";

    @Option(name= "-t", aliases= "--target", usage= "process target classpath")
    private String target= "";

    @Option(name= "--debug", usage= "debug mode")
    private boolean debug= false;
}

