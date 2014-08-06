#!/usr/bin/env rake

task :ci => [:dump, :test]

task :dump do
    sh 'vim --version'
end

task :test do
    sh <<'...'
if ! [ -d .vim-test/ ]; then
    mkdir .vim-test/
    git clone https://github.com/kamichidu/vim-javalang.git .vim-test/vim-javalang/
    git clone https://github.com/kamichidu/vim-javaclasspath.git .vim-test/vim-javaclasspath/
fi
...
    sh 'bundle exec vim-flavor test'
end
