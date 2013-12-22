package jp.michikusa.chitose.unitejavaimport;

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

    @Option(name= "-h", aliases= "--help", usage= "show this message")
    private boolean help_flag= false;

    @Option(name= "-r", aliases= "--recursive", usage= "dump packages recursively (default: not recursive)")
    private boolean recursive= false;

    @Option(name= "-p", aliases= "--package", usage= "dump packages via (default: '')")
    private String package_name= "";
}

