package jp.michikusa.chitose.unitejavaimport;

import com.google.common.base.Function;
import com.google.common.base.Functions;
import com.google.common.base.Predicate;
import com.google.common.base.Predicates;
import com.google.common.collect.ImmutableSet;
import com.google.common.collect.Iterables;

import java.util.Arrays;
import java.util.Collection;
import java.util.HashSet;
import java.util.Set;
import java.util.concurrent.Callable;

import javax.lang.model.element.Modifier;
import javax.tools.DiagnosticCollector;
import javax.tools.JavaCompiler;
import javax.tools.JavaFileManager;
import javax.tools.JavaFileObject;
import javax.tools.StandardLocation;
import javax.tools.ToolProvider;

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

            for(final CharSequence element : dumper.call())
            {
                System.out.println(element);
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
        final JavaCompiler compiler= ToolProvider.getSystemJavaCompiler();
        final JavaFileManager file_manager= compiler.getStandardFileManager(
            new DiagnosticCollector<JavaFileObject>(),
            null,
            null
            );

        final ImmutableSet<JavaFileObject.Kind> kinds= ImmutableSet.of(JavaFileObject.Kind.CLASS);

        final ImmutableSet<JavaFileManager.Location> locations= ImmutableSet.<JavaFileManager.Location>of(
            StandardLocation.PLATFORM_CLASS_PATH,
            // user class path
            StandardLocation.CLASS_PATH
        );

        final Predicate<JavaFileObject> predicate;
        {
            final Predicate<JavaFileObject> exclude_self_jar= new Predicate<JavaFileObject>(){
                @Override
                public boolean apply(JavaFileObject o)
                {
                    // exclude self jar content
                    return !o.getName().contains("unite-javaimport-0.01-jar-with-dependencies.jar");
                    // getAccessLevel() always returns null
                    // return Modifier.PUBLIC.equals(o.getAccessLevel());
                }
            };

            predicate= Predicates.and(exclude_self_jar);
        }
        final Function<JavaFileObject, String> function;
        {
            final Function<JavaFileObject, String> get_name= new Function<JavaFileObject, String>(){
                @Override
                public String apply(JavaFileObject o)
                {
                    return o.getName();
                }
            };
            final Function<String, String> extract= new Function<String, String>(){
                @Override
                public String apply(String o)
                {
                    final int lparen_idx= o.lastIndexOf('(');
                    final int rparen_idx= o.lastIndexOf(")");

                    return o.substring(lparen_idx + 1, rparen_idx);
                }
            };
            final Function<String, String> name2canonical_name= new Function<String, String>(){
                @Override
                public String apply(String o)
                {
                    return o
                        .replaceFirst("^.*\\.jar/", "")
                        .replaceFirst("\\.class$", "")
                        .replace('/', '.')
                        .replace('$', '.')
                    ;
                }
            };

            function= Functions.compose(name2canonical_name, Functions.compose(extract, get_name));
        }

        final ImmutableSet.Builder<CharSequence> clazzes= ImmutableSet.builder();
        for(final JavaFileManager.Location location : locations)
        {
            final Iterable<JavaFileObject> list= file_manager.list(location, this.option.packageName(), kinds, this.option.recursive());
            final Iterable<JavaFileObject> filtered= Iterables.filter(list, predicate);

            clazzes.addAll(Iterables.transform(filtered, function));
        }
        return clazzes.build();
    }

    private final ProcessOption option;
}
