" Vim folding file
" Language: Python
" Author:   Jorrit Wiersma (foldexpr), Max Ischenko (foldtext), Robert, Anton Abrosimov
" Ames (line counts)
" Last Change:  2019 Oct 1
" Version:  2.4
" Bug fix:  Drexler Christopher, Tom Schumm, Geoff Gerrietts


setlocal foldmethod=expr
setlocal foldexpr=GetPythonFold(v:lnum)
setlocal foldtext=PythonFoldText()

let b:is_comment_block = 0
let b:is_decorated = 0

function! PythonFoldText()
    let line = getline(v:foldstart)

    " Hide decorators
    if line =~ '^\s*@.*$'
        let cnum = nextnonblank(v:foldstart + 1)
        let line = getline(cnum)
        let nnum = nextnonblank(cnum + 1)
        let nextline = getline(nnum)
    else
        let nnum = nextnonblank(v:foldstart + 1)
        let nextline = getline(nnum)
    endif

    " Hide variables definition
    let line = matchstr(line, '^\s*\(class\|\(async \)\?def\)\s*\zs.*\ze(.*$')

    " Multiline definitions
    while getline(prevnonblank(nnum - 1)) !~ '^.*:$'
        let nnum = nextnonblank(nnum + 1)
        let nextline = getline(nnum)
    endwhile

    if nextline =~ '^\s\+"""$'
        let line = line . getline(nnum + 1)
    elseif nextline =~ '^\s\+u\?"""'
        let line = line . ' ' . matchstr(nextline, '"""\zs.\{-}\ze\("""\)\?$')
    elseif nextline =~ '^\s\+"[^"]\+"$'
        let line = line . ' ' . matchstr(nextline, '"\zs.*\ze"')
    elseif nextline =~ '^\s\+pass\s*$'
        let line = line . ' pass'
    endif
    let size = 1 + v:foldend - v:foldstart
    if size < 10
        let size = " " . size
    endif
    if size < 100
        let size = " " . size
    endif
    if size < 1000
        let size = " " . size
    endif
    return size . " lines: " . line
endfunction


function! GetPythonFold(lnum)
    " Determine folding level in Python source
    "
    let line = getline(a:lnum)
    let ind  = indent(a:lnum)

    " Support comment block
    if line =~ '^\s*""".*$' && line !~ '^\s*""".*"""\s*$'
        if b:is_comment_block == 0
            let b:is_comment_block = 1
            return "a1"
        else
            let b:is_comment_block = 0
            return "s1"
        endif
    endif
    if b:is_comment_block == 1
        return '='
    endif

    " Ignore blank lines
    if line =~ '^\s*$'
        return "="
    endif

    " Ignore triple quoted strings
    if line =~ "(\"\"\"|''')"
        return "="
    endif

    " Ignore continuation lines
    if line =~ '\\$'
        return '='
    endif

    " Support markers
    if line =~ '^\s*\(# [[[\|[[[\).*'
        return "a1"
    elseif line =~ '^\s*\(# ]]]\|]]]\).*'
        return "s1"
    endif

    " Ignore empty classes and functions
    if line =~ '^\s*\(class\|\(async \)\?def\)\s[^#]*\<pass\>'
        return "="
    endif

    " Hide decorators
    if line =~ '^\s*@.*$'
        if b:is_decorated == 0
            let b:is_decorated = 1
            return ">" . (ind / &sw + 1)
        else
            return "="
        endif
    endif

    " Classes and functions get their own folds
    if line =~ '^\s*\(class\|\(async \)\?def\)\s'
        if b:is_decorated == 1
            let b:is_decorated = 0
            return "="
        else
            return ">" . (ind / &sw + 1)
        endif
    endif

    let pnum = prevnonblank(a:lnum - 1)

    if pnum == 0
    " Hit start of file
        return 0
    endif

    " If the previous line has foldlevel zero, and we haven't increased
    " it, we should have foldlevel zero also
    if foldlevel(pnum) == 0
        return 0
    endif

    " The end of a fold is determined through a difference in indentation
    " between this line and the next.
    " So first look for next line
    let nnum = nextnonblank(a:lnum + 1)
    if nnum == 0
        return "="
    endif

    " First I check for some common cases where this algorithm would
    " otherwise fail. (This is all a hack)
    let nline = getline(nnum)
    if nline =~ '^\s*\(except\|else\|elif\)'
        return "="
    endif

    " Python programmers love their readable code, so they're usually
    " going to have blank lines at the ends of functions or classes
    " If the next line isn't blank, we probably don't need to end a fold
    if nnum == a:lnum + 1
        return "="
    endif

    " If next line has less indentation we end a fold.
    " This ends folds that aren't there a lot of the time, and this sometimes
    " confuses vim.  Luckily only rarely.
    let nind = indent(nnum)
    if nind < ind
        return "<" . (nind / &sw + 1)
    endif

    " If none of the above apply, keep the indentation
    return "="

endfunction

