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
    git clone https://github.com/kamichidu/vim-javalang .vim-test/javalang/
    git clone https://github.com/kamichidu/vim-javaclasspath .vim-test/javaclasspath/
fi
...
    sh './.vim-test/themis/bin/themis --runtimepath .vim-test/javalang/ --runtimepath .vim-test/javaclasspath/'
end
