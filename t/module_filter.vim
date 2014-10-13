let s:suite= themis#suite('javaimport#filter')
let s:assert= themis#helper('assert')

function! s:suite.__base_filter__()
    let base_filter= themis#suite('base_filter')

    function! base_filter.has_attributes()
        let filter= javaimport#filter#base#new()

        call s:assert.type_of(filter, 'Dictionary')
        call s:assert.has_key(filter, 'apply')
        call s:assert.type_of(filter.apply, 'Funcref')
    endfunction

    function! base_filter.doesnot_break_original_list()
        let filter= javaimport#filter#base#new()

        let unfiltered= [1, 2, 3]
        let filtered= filter.apply(unfiltered)
        call s:assert.equals(unfiltered, [1, 2, 3])
        call s:assert.equals(filtered, [1, 2, 3])
    endfunction
endfunction

function! s:suite.__package_filter__()
    let package_filter= themis#suite('package_filter')

    function! package_filter.doesnot_filter_without_predicate()
        let filter= javaimport#filter#package#new()

        let unfiltered= ['java.util.HashMap', 'java.lang.Boolean', 'java.util.concurrent.ConcurrentSkipListMap']
        let filtered= filter.apply(unfiltered)
        call s:assert.equals(filtered, ['java.util.HashMap', 'java.lang.Boolean', 'java.util.concurrent.ConcurrentSkipListMap'])
    endfunction

    function! package_filter.filters_specific_word()
        let filter= javaimport#filter#package#new()

        call filter.contains('util.')

        let unfiltered= ['java.util.HashMap', 'java.utility.Boolean', 'java.util.concurrent.ConcurrentSkipListMap']
        let filtered= filter.apply(unfiltered)
        call s:assert.equals(unfiltered, ['java.util.HashMap', 'java.utility.Boolean', 'java.util.concurrent.ConcurrentSkipListMap'])
        call s:assert.equals(filtered, ['java.util.HashMap', 'java.util.concurrent.ConcurrentSkipListMap'])
    endfunction

    function! package_filter.filters_lower_packages()
        let filter= javaimport#filter#package#new()

        call filter.exclude('java.util')

        let unfiltered= ['java.util.HashMap', 'java.utility.Boolean', 'java.util.concurrent.ConcurrentSkipListMap']
        let filtered= filter.apply(unfiltered)
        call s:assert.equals(unfiltered, ['java.util.HashMap', 'java.utility.Boolean', 'java.util.concurrent.ConcurrentSkipListMap'])
        call s:assert.equals(filtered, ['java.utility.Boolean'])
    endfunction
endfunction

function! s:suite.__class_filter__()
    let class_filter= themis#suite('class_filter')

    function! class_filter.filters_by_simplename()
        let filter= javaimport#filter#class#new()

        call filter.classname('Boolean')

        let unfiltered= [{'simple_name': 'HashMap'}, {'simple_name': 'Boolean'}, {'simple_name': 'ConcurrentSkipListMap'}]
        let filtered= filter.apply(unfiltered)
        call s:assert.equals(unfiltered, [{'simple_name': 'HashMap'}, {'simple_name': 'Boolean'}, {'simple_name': 'ConcurrentSkipListMap'}])
        call s:assert.equals(filtered, [{'simple_name': 'Boolean'}])
    endfunction
endfunction
