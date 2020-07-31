" File: ~/.vim/syntax/agda.vim

" This is reproduced from 
" http://wiki.portal.chalmers.se/agda/pmwiki.php?n=Main.VIMEditing
" for convenience

if version < 600
    syntax clear
elseif exists("b:current_syntax")
    finish
endif

" To tokenize, the best pattern I've found so far is this:
"   (^|\s|[.(){};])@<=token($|\s|[.(){};])@=
" The patterns @<= and @= look behind and ahead, respectively, without matching.

" `agda --vim` extends these groups:
"   agdaConstructor
"   agdaFunction
"   agdaInfixConstructor
"   agdaInfixFunction

" Any identifier not starting with a capital letter is an ordinary identifier.
syntax match agdaIdentifier "[^.[:space:](){};_]\+"

" Allow custom color for underscore in mixfix operator.
syntax match agdaMixfixUnderscore "_"

" Any identifier consisting of only non-letters is an operator.
syntax match agdaOperator
  \ "[^[:alpha:][:space:](){};]\+\($\|\ze[[:space:](){};_]\)"

" Any identifier starting with capital letter is a type.
syntax match agdaType "[_¬]\?[A-Z][^.[:space:](){};]*" nextgroup=agdaTypeDot

" Any identifier followed by a dot is a type.
syntax match agdaType "[^.[:space:](){};]\+\ze\." nextgroup=agdaTypeDot

" Allow custom color for dot after type.
syntax match agdaTypeDot "\." contained

syntax match   agdaKeywords     "\v(^|\s|[.(){};])@<=(abstract|data|hiding|import|as|infix|infixl|infixr|module|mutual|open|primitive|private|public|record|renaming|rewrite|using|where|with|field|constructor|instance|syntax|pattern|inductive|coinductive|to|let|in|postulate|variable)($|\s|[.(){};])@="
syntax match   agdaNumber       "\v(^|\s|[.(){};])@<=-?[0-9]+($|\s|[.(){};])@="
syntax match   agdaCharCode     contained "\\\([0-9]\+\|o[0-7]\+\|x[0-9a-fA-F]\+\|[\"\\'&\\abfnrtv]\|^[A-Z^_\[\\\]]\)"
syntax match   agdaCharCode     contained "\v\\(NUL|SOH|STX|ETX|EOT|ENQ|ACK|BEL|BS|HT|LF|VT|FF|CR|SO|SI|DLE|DC1|DC2|DC3|DC4|NAK|syntax|ETB|CAN|EM|SUB|ESC|FS|GS|RS|US|SP|DEL)"
syntax match   agdaCharCodeErr  contained "\\&\|'''\+"
syntax region  agdaString       start=+"+ skip=+\\\\\|\\"+ end=+"+ contains=agdaCharCode
syntax match   agdaString       "'.'"
syntax match   agdaHole         "\v(^|\s|[.(){};])@<=(\?)($|\s|[.(){};])@="
syntax region  agdaX            oneline matchgroup=agdaHole start="{!" end="!}"
syntax match   agdaLineComment  "\v(^|\s|[.(){};])@<=--.*$" contains=@agdaInComment
syntax region  agdaBlockComment start="{-"  end="-}" contains=agdaBlockComment,@agdaInComment
syntax region  agdaPragma       start="{-#" end="#-}"
syntax cluster agdaInComment    contains=agdaTODO,agdaFIXME,agdaXXX
syntax keyword agdaTODO         contained TODO
syntax keyword agdaFIXME        contained FIXME
syntax keyword agdaXXX          contained XXX

highlight default link agdaNumber           Number
highlight default link agdaString           String
highlight default link agdaConstructor      Constant
highlight default link agdaCharCode         SpecialChar
highlight default link agdaCharCodeErr      Error
highlight default link agdaHole             WarningMsg
highlight default link agdaKeywords         Statement
highlight default link agdaOperator         Operator
highlight default link agdaInfixConstructor Operator
highlight default link agdaInfixFunction    Operator
highlight default link agdaLineComment      Comment
highlight default link agdaBlockComment     Comment
highlight default link agdaPragma           Comment
highlight default      agdaTODO             cterm=bold,underline ctermfg=2 " green
highlight default      agdaFIXME            cterm=bold,underline ctermfg=3 " yellow
highlight default      agdaXXX              cterm=bold,underline ctermfg=1 " red

highlight default link agdaMixfixUnderscore Operator
highlight default link agdaType Type

" Prevent agda-vim plugin from overriding syntax.
let b:current_syntax = 1
