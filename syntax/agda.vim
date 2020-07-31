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

syntax match agdaMixfixUnderscore '_' contained
syntax match agdaTypeDot '\.' contained

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

" ## Renaming

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

syntax match agdaChar "'.'"
syntax region agdaString start='"' skip='\\"' end='"\|$'

" ## Holes

syntax match agdaHole '?[[:space:]\n.;{}()@"]\@='
syntax region agdaHole start='{!' end='!}'

" ## Highlighting

highlight default link agdaChar agdaString
highlight default link agdaComment Comment
highlight default link agdaHole WarningMsg
highlight default link agdaKeyword Statement
highlight default link agdaMixfixUnderscore Operator
highlight default link agdaOperator Operator
highlight default link agdaPragma SpecialComment
highlight default link agdaString String
highlight default link agdaTo Statement
highlight default link agdaType Type

" ## Variable

" Ensure no other syntax file is loaded.
let b:current_syntax = 'agda'

