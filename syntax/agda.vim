" ## Identifiers

" Match identifiers not starting with capital letter.
syntax match agdaIdentifier
  \ '[^[:space:].;{}()@"]\+[[:space:]\n;{}()@"]\@='
  \ contains=agdaMixfixUnderscore

" Match identifiers not containing a letter.
syntax match agdaOperator
  \ '[^[:alpha:][:space:].;{}()@"]\+[[:space:]\n;{}()@"]\@='
  \ contains=agdaMixfixUnderscore

" Match identifiers starting with capital letter.
syntax match agdaType
  \ '[_¬]\?[A-Z][^[:space:].;{}()@"]*[[:space:]\n;{}()@"]\@='
  \ nextgroup=agdaTypeDot

" Match identifiers followed by a dot.
syntax match agdaType
  \ '[^[:space:].;{}()@"]\+\.\@='
  \ nextgroup=agdaTypeDot

syntax match agdaAs '@'
syntax match agdaDot '\.' contained
syntax match agdaEllipses '\.\.\.[[:space:]\n;{}()@"]\@='
syntax match agdaUnderscore '_' contained

" ## Keywords

syntax match agdaKeyword 'abstract[[:space:]\n.;{}()@"]\@='
syntax match agdaKeyword 'constructor[[:space:]\n.;{}()@"]\@='
syntax match agdaKeyword 'data[[:space:]\n.;{}()@"]\@='
syntax match agdaKeyword 'do[[:space:]\n.;{}()@"]\@='
syntax match agdaKeyword 'eta-equality[[:space:]\n.;{}()@"]\@='
syntax match agdaKeyword 'field[[:space:]\n.;{}()@"]\@='
syntax match agdaKeyword 'forall[[:space:]\n.;{}()@"]\@='
syntax match agdaKeyword 'hiding[[:space:]\n.;{}()@"]\@='
syntax match agdaKeyword 'import[[:space:]\n.;{}()@"]\@='
syntax match agdaKeyword 'in[[:space:]\n.;{}()@"]\@='
syntax match agdaKeyword 'inductive[[:space:]\n.;{}()@"]\@='
syntax match agdaKeyword 'infix[[:space:]\n.;{}()@"]\@='
syntax match agdaKeyword 'infixl[[:space:]\n.;{}()@"]\@='
syntax match agdaKeyword 'infixr[[:space:]\n.;{}()@"]\@='
syntax match agdaKeyword 'instance[[:space:]\n.;{}()@"]\@='
syntax match agdaKeyword 'let[[:space:]\n.;{}()@"]\@='
syntax match agdaKeyword 'macro[[:space:]\n.;{}()@"]\@='
syntax match agdaKeyword 'module[[:space:]\n.;{}()@"]\@='
syntax match agdaKeyword 'mutual[[:space:]\n.;{}()@"]\@='
syntax match agdaKeyword 'no-eta-equality[[:space:]\n.;{}()@"]\@='
syntax match agdaKeyword 'open[[:space:]\n.;{}()@"]\@='
syntax match agdaKeyword 'overlap[[:space:]\n.;{}()@"]\@='
syntax match agdaKeyword 'pattern[[:space:]\n.;{}()@"]\@='
syntax match agdaKeyword 'postulate[[:space:]\n.;{}()@"]\@='
syntax match agdaKeyword 'primitive[[:space:]\n.;{}()@"]\@='
syntax match agdaKeyword 'private[[:space:]\n.;{}()@"]\@='
syntax match agdaKeyword 'public[[:space:]\n.;{}()@"]\@='
syntax match agdaKeyword 'quote[[:space:]\n.;{}()@"]\@='
syntax match agdaKeyword 'quoteContext[[:space:]\n.;{}()@"]\@='
syntax match agdaKeyword 'quoteGoal[[:space:]\n.;{}()@"]\@='
syntax match agdaKeyword 'quoteTerm[[:space:]\n.;{}()@"]\@='
syntax match agdaKeyword 'record[[:space:]\n.;{}()@"]\@='
syntax match agdaKeyword 'rewrite[[:space:]\n.;{}()@"]\@='
syntax match agdaKeyword 'syntax[[:space:]\n.;{}()@"]\@='
syntax match agdaKeyword 'tactic[[:space:]\n.;{}()@"]\@='
syntax match agdaKeyword 'unquote[[:space:]\n.;{}()@"]\@='
syntax match agdaKeyword 'unquoteDecl[[:space:]\n.;{}()@"]\@='
syntax match agdaKeyword 'unquoteDef[[:space:]\n.;{}()@"]\@='
syntax match agdaKeyword 'using[[:space:]\n.;{}()@"]\@='
syntax match agdaKeyword 'variable[[:space:]\n.;{}()@"]\@='
syntax match agdaKeyword 'where[[:space:]\n.;{}()@"]\@='
syntax match agdaKeyword 'with[[:space:]\n.;{}()@"]\@='

syntax match agdaKeyword 'renaming[[:space:]\n.;{}()@"]\@=' skipnl skipwhite
  \ nextgroup=agdaRenaming
syntax region agdaRenaming start='(' end=')' contained
  \ contains=agdaIdentifier,agdaOperator,agdaTo,agdaType
syntax match agdaTo 'to[[:space:]\n.;{}()@"]\@=' contained

" ## Comments

syntax match agdaComment '--.*'
syntax region agdaComment start='{-' end='-}' contains=agdaBlockComment
syntax region agdaPragma start='{-#' end='#-}'

" ## Literals

syntax match agdaNumber '-\?[0-9]\+[[:space:]\n;{}()@"]\@='
syntax match agdaNumber '-\?0x[0-9A-Fa-f]\+[[:space:]\n;{}()@"]\@='
syntax match agdaNumber '-\?[0-9]\+\.[0-9]\+\([Ee]\([+-]\)\?[0-9]\+\)\?'
syntax match agdaNumber '-\?[0-9]\+[Ee]\([+-]\)\?[0-9]\+'

syntax match agdaChar "'[^'\\]'"
syntax match agdaChar "'\\[0-9]\+'"
syntax match agdaChar "'\\0x[0-9A-Fa-f]\+'"
syntax match agdaChar "'\\a'"
syntax match agdaChar "'\\b'"
syntax match agdaChar "'\\t'"
syntax match agdaChar "'\\n'"
syntax match agdaChar "'\\v'"
syntax match agdaChar "'\\f'"
syntax match agdaChar "'\\\\'"
syntax match agdaChar "'\\''"
syntax match agdaChar +'\\"'+
syntax match agdaChar "'\\NUL'"
syntax match agdaChar "'\\SOH'"
syntax match agdaChar "'\\STX'"
syntax match agdaChar "'\\ETX'"
syntax match agdaChar "'\\EOT'"
syntax match agdaChar "'\\ENQ'"
syntax match agdaChar "'\\ACK'"
syntax match agdaChar "'\\BEL'"
syntax match agdaChar "'\\BS'"
syntax match agdaChar "'\\HT'"
syntax match agdaChar "'\\LF'"
syntax match agdaChar "'\\VT'"
syntax match agdaChar "'\\FF'"
syntax match agdaChar "'\\CR'"
syntax match agdaChar "'\\SO'"
syntax match agdaChar "'\\SI'"
syntax match agdaChar "'\\DLE'"
syntax match agdaChar "'\\DC1'"
syntax match agdaChar "'\\DC2'"
syntax match agdaChar "'\\DC3'"
syntax match agdaChar "'\\DC4'"
syntax match agdaChar "'\\NAK'"
syntax match agdaChar "'\\SYN'"
syntax match agdaChar "'\\ETB'"
syntax match agdaChar "'\\CAN'"
syntax match agdaChar "'\\EM'"
syntax match agdaChar "'\\SUB'"
syntax match agdaChar "'\\ESC'"
syntax match agdaChar "'\\FS'"
syntax match agdaChar "'\\GS'"
syntax match agdaChar "'\\RS'"
syntax match agdaChar "'\\US'"
syntax match agdaChar "'\\SP'"
syntax match agdaChar "'\\DEL'"

syntax region agdaString start='"' skip='\\"' end='"\|$'

" ## Holes

syntax match agdaHole '?[[:space:]\n.;{}()@"]\@='
syntax match agdaHoleIndexed '?\d\+[[:space:]\n.;{}()@"]\@='
syntax match agdaHoleIndexed '_\d\+[[:space:]\n.;{}()@"]\@='
syntax region agdaHole start='{!' end='!}\|$'

" ## Highlights

highlight default link agdaAs agdaOperator
highlight default link agdaChar agdaString
highlight default link agdaComment Comment
highlight default link agdaEllipses agdaOperator
highlight default link agdaHole WarningMsg
highlight default link agdaKeyword Statement
highlight default link agdaLine Comment
highlight default link agdaNumber Number
highlight default link agdaOperator Operator
highlight default link agdaPragma SpecialComment
highlight default link agdaString String
highlight default link agdaTo agdaKeyword
highlight default link agdaType Type
highlight default link agdaUnderscore agdaOperator

" ## Variable

" Ensure no other syntax file is loaded.
let b:current_syntax = 'agda'

