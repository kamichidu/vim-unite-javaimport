let s:suite= themis#suite('javaimport')
let s:assert= themis#helper('assert')

function! s:paste(...)
    call setline(1, a:000)
endfunction

function! s:suite.before_each()
    new
    setlocal filetype=java
endfunction

function! s:suite.after_each()
    close!
endfunction

function! s:suite.__SortStatements__()
    let SortStatements= themis#suite('SortStatements')

    function! SortStatements.with_no_imports()
        call s:paste(
        \   'package hoge;',
        \   'class Hoge{}',
        \)

        JavaImportSortStatements

        call s:assert.equals(getline(1, '$'), [
        \   'package hoge;',
        \   'class Hoge{}',
        \])
    endfunction

    function! SortStatements.with_a_import()
        call s:paste(
        \   'package hoge;',
        \   'import a.b.C;',
        \   'class Hoge{}',
        \)

        JavaImportSortStatements

        call s:assert.equals(getline(1, '$'), [
        \   'package hoge;',
        \   '',
        \   'import a.b.C;',
        \   '',
        \   'class Hoge{}',
        \])
    endfunction

    function! SortStatements.with_imports()
        call s:paste(
        \   'package hoge;',
        \   'import a.c.C;',
        \   'import a.b.C;',
        \   'import b.a.C;',
        \   'import a.a.C;',
        \   'class Hoge{}',
        \)

        JavaImportSortStatements

        call s:assert.equals(getline(1, '$'), [
        \   'package hoge;',
        \   '',
        \   'import a.a.C;',
        \   'import a.b.C;',
        \   'import a.c.C;',
        \   '',
        \   'import b.a.C;',
        \   '',
        \   'class Hoge{}',
        \])
    endfunction
endfunction

function! s:suite.__RemoveUnnecessaries__()
    let RemoveUnnecessaries= themis#suite('RemoveUnnecessaries')

    function! RemoveUnnecessaries.with_no_imports()
        call s:paste(
        \   'package hoge;',
        \   'class Hoge{}',
        \)

        JavaImportRemoveUnnecessaries

        call s:assert.equals(getline(1, '$'), [
        \   'package hoge;',
        \   'class Hoge{}',
        \])
    endfunction

    function! RemoveUnnecessaries.with_a_import()
        call s:paste(
        \   'package hoge;',
        \   'import a.b.C;',
        \   'class Hoge{}',
        \)

        JavaImportRemoveUnnecessaries

        call s:assert.equals(getline(1, '$'), [
        \   'package hoge;',
        \   'class Hoge{}',
        \])
    endfunction

    function! RemoveUnnecessaries.with_imports()
        call s:paste(
        \   'package hoge;',
        \   '',
        \   'import a.b.Fuga;',
        \   'import a.c.Hoge;',
        \   '',
        \   'import b.a.Piyo;',
        \   '',
        \   'class Hoge{',
        \   '  private Hoge hoge;',
        \   '  private Piyo fuga;',
        \   '}',
        \)

        JavaImportRemoveUnnecessaries

        call s:assert.equals(getline(1, '$'), [
        \   'package hoge;',
        \   '',
        \   'import a.c.Hoge;',
        \   '',
        \   'import b.a.Piyo;',
        \   '',
        \   'class Hoge{',
        \   '  private Hoge hoge;',
        \   '  private Piyo fuga;',
        \   '}',
        \])
    endfunction

    function! RemoveUnnecessaries.with_static_imports()
        call s:paste(
        \   'package hoge;',
        \   '',
        \   'import a.b.Fuga;',
        \   'import a.c.Hoge;',
        \   '',
        \   'import b.a.Piyo;',
        \   '',
        \   'import static java.lang.Boolean.TRUE;',
        \   '',
        \   'class Hoge{',
        \   '  private Hoge hoge;',
        \   '  private Piyo fuga= TRUE;',
        \   '}',
        \)

        JavaImportRemoveUnnecessaries

        call s:assert.equals(getline(1, '$'), [
        \   'package hoge;',
        \   '',
        \   'import a.c.Hoge;',
        \   '',
        \   'import b.a.Piyo;',
        \   '',
        \   'import static java.lang.Boolean.TRUE;',
        \   '',
        \   'class Hoge{',
        \   '  private Hoge hoge;',
        \   '  private Piyo fuga= TRUE;',
        \   '}',
        \])
    endfunction

    function! RemoveUnnecessaries.shouldnot_remove_star_import()
        call s:paste(
        \   'package hoge;',
        \   '',
        \   'import a.c.*;',
        \   '',
        \   'import static java.lang.Boolean.*;',
        \   '',
        \   'class Hoge{',
        \   '}',
        \)

        JavaImportRemoveUnnecessaries

        call s:assert.equals(getline(1, '$'), [
        \   'package hoge;',
        \   '',
        \   'import a.c.*;',
        \   '',
        \   'import static java.lang.Boolean.*;',
        \   '',
        \   'class Hoge{',
        \   '}',
        \])
    endfunction
endfunction
