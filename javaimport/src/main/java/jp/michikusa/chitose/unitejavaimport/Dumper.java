package jp.michikusa.chitose.unitejavaimport;

import com.google.common.base.Function;
import com.google.common.base.Functions;
import com.google.common.base.Predicate;
import com.google.common.base.Predicates;
import com.google.common.collect.ImmutableSet;
import com.google.common.collect.Iterables;

import java.lang.reflect.Modifier;
import java.net.MalformedURLException;
import java.net.URL;
import java.util.Collections;
import java.util.concurrent.Callable;
import java.util.zip.ZipEntry;
import java.util.zip.ZipFile;

import javax.tools.DiagnosticCollector;
import javax.tools.JavaCompiler;
import javax.tools.JavaFileManager;
import javax.tools.JavaFileObject;
import javax.tools.ToolProvider;

import org.apache.bcel.classfile.ClassParser;
import org.apache.bcel.classfile.JavaClass;
import org.kohsuke.args4j.CmdLineException;
import org.kohsuke.args4j.CmdLineParser;

public class Dumper implements Callable<Iterable<CharSequence>>
{
    public static void main(String[] args)
    {
        final ProcessOption option= new ProcessOption();

        final CmdLineParser parser= new CmdLineParser(option);
        try
        {
            parser.parseArgument(args);
        }
        catch(CmdLineException e)
        {
            e.printStackTrace();
            return;
        }

        try
        {
            final Dumper dumper= new Dumper(option);

            for(final CharSequence clazzname : dumper.call())
            {
                System.out.println(clazzname);
            }
        }
        catch(Exception e)
        {
            e.printStackTrace();
        }
    }

    public Dumper(ProcessOption option)
    {
        this.option= option;
    }

    @Override
    public Iterable<CharSequence> call() throws Exception
    {
        final ZipFile zip_file= new ZipFile(this.option.path());
        final ImmutableSet.Builder<CharSequence> clazzes= ImmutableSet.builder();

        for(final ZipEntry entry : Collections.list(zip_file.entries()))
        {
            if(entry.getName().endsWith(".class"))
            {
                final JavaClass clazz= new ClassParser(zip_file.getInputStream(entry), entry.getName()).parse();

                if(clazz.isPublic())
                {
                    clazzes.add(clazz.getClassName());
                }
            }
        }

        return clazzes.build();
    }

    private final ProcessOption option;
}
