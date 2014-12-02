#!/usr/bin/env rake

task :ci => [:dump, :test]

task :dump do
    sh 'vim --version'
end

task :test do
    sh <<'...'
if ! [ -d .vim-test/ ]; then
    mkdir .vim-test/
    git clone https://github.com/thinca/vim-themis .vim-test/themis/
    git clone https://github.com/kamichidu/vim-javaclasspath .vim-test/javaclasspath/
fi
...
    sh './.vim-test/themis/bin/themis --runtimepath .vim-test/javaclasspath/'
end

task :lint do
    sh <<'...'
if ! [ -d .vim-lint/ ]; then
    mkdir .vim-lint/
    git clone https://github.com/syngan/vim-vimlint .vim-lint/vimlint/
    git clone https://github.com/ynkdir/vim-vimlparser .vim-lint/vimlparser/
fi
...
    sh './.vim-lint/vimlint/bin/vimlint.sh -l ./.vim-lint/vimlint/ -p ./.vim-lint/vimlparser -e EVL103=1 -e EVL102.l:_=1 autoload/'
end
