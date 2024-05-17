if exists('b:current_syntax')
  finish
endif

" ## Identifiers

" Match identifiers not starting with capital letter.
syntax match agdaIdentifier
  \ /[^[:space:].;{}()@"]\+\($\|[[:space:];{}()@"]\)\@=/

" Match identifiers not containing a letter.
syntax match agdaOperator
  \ /[^[:alpha:][:space:].;{}()@"]\+\($\|[[:space:];{}()@"]\)\@=/

" Match identifiers starting with capital letter.
syntax match agdaType
  \ /[_¬]\?[A-Z][^[:space:].;{}()@"]*\($\|[[:space:];{}()@"]\)\@=/

" Match identifiers followed by a dot.
syntax match agdaType
  \ /[^[:space:].;{}()@"]\+\.\@=/

syntax match agdaAs /@/
syntax match agdaDot /\./ contained
syntax match agdaEllipses /\.\.\.\($\|[[:space:].;{}()@"]\)\@=/
syntax match agdaUnderscore '_' contained

" ## Keywords

syntax match agdaKeyword /abstract\($\|[[:space:].;{}()@"]\)\@=/
syntax match agdaKeyword /constructor\($\|[[:space:].;{}()@"]\)\@=/
syntax match agdaKeyword /data\($\|[[:space:].;{}()@"]\)\@=/
syntax match agdaKeyword /do\($\|[[:space:].;{}()@"]\)\@=/
syntax match agdaKeyword /eta-equality\($\|[[:space:].;{}()@"]\)\@=/
syntax match agdaKeyword /field\($\|[[:space:].;{}()@"]\)\@=/
syntax match agdaKeyword /forall\($\|[[:space:].;{}()@"]\)\@=/
syntax match agdaKeyword /hiding\($\|[[:space:].;{}()@"]\)\@=/
syntax match agdaKeyword /in\($\|[[:space:].;{}()@"]\)\@=/
syntax match agdaKeyword /inductive\($\|[[:space:].;{}()@"]\)\@=/
syntax match agdaKeyword /infix\($\|[[:space:].;{}()@"]\)\@=/
syntax match agdaKeyword /infixl\($\|[[:space:].;{}()@"]\)\@=/
syntax match agdaKeyword /infixr\($\|[[:space:].;{}()@"]\)\@=/
syntax match agdaKeyword /instance\($\|[[:space:].;{}()@"]\)\@=/
syntax match agdaKeyword /let\($\|[[:space:].;{}()@"]\)\@=/
syntax match agdaKeyword /macro\($\|[[:space:].;{}()@"]\)\@=/
syntax match agdaKeyword /module\($\|[[:space:].;{}()@"]\)\@=/
syntax match agdaKeyword /mutual\($\|[[:space:].;{}()@"]\)\@=/
syntax match agdaKeyword /no-eta-equality\($\|[[:space:].;{}()@"]\)\@=/
syntax match agdaKeyword /open\($\|[[:space:].;{}()@"]\)\@=/
syntax match agdaKeyword /overlap\($\|[[:space:].;{}()@"]\)\@=/
syntax match agdaKeyword /pattern\($\|[[:space:].;{}()@"]\)\@=/
syntax match agdaKeyword /postulate\($\|[[:space:].;{}()@"]\)\@=/
syntax match agdaKeyword /primitive\($\|[[:space:].;{}()@"]\)\@=/
syntax match agdaKeyword /private\($\|[[:space:].;{}()@"]\)\@=/
syntax match agdaKeyword /public\($\|[[:space:].;{}()@"]\)\@=/
syntax match agdaKeyword /quote\($\|[[:space:].;{}()@"]\)\@=/
syntax match agdaKeyword /quoteContext\($\|[[:space:].;{}()@"]\)\@=/
syntax match agdaKeyword /quoteGoal\($\|[[:space:].;{}()@"]\)\@=/
syntax match agdaKeyword /quoteTerm\($\|[[:space:].;{}()@"]\)\@=/
syntax match agdaKeyword /record\($\|[[:space:].;{}()@"]\)\@=/
syntax match agdaKeyword /rewrite\($\|[[:space:].;{}()@"]\)\@=/
syntax match agdaKeyword /syntax\($\|[[:space:].;{}()@"]\)\@=/
syntax match agdaKeyword /tactic\($\|[[:space:].;{}()@"]\)\@=/
syntax match agdaKeyword /unquote\($\|[[:space:].;{}()@"]\)\@=/
syntax match agdaKeyword /unquoteDecl\($\|[[:space:].;{}()@"]\)\@=/
syntax match agdaKeyword /unquoteDef\($\|[[:space:].;{}()@"]\)\@=/
syntax match agdaKeyword /using\($\|[[:space:].;{}()@"]\)\@=/
syntax match agdaKeyword /variable\($\|[[:space:].;{}()@"]\)\@=/
syntax match agdaKeyword /where\($\|[[:space:].;{}()@"]\)\@=/
syntax match agdaKeyword /with\($\|[[:space:].;{}()@"]\)\@=/

syntax match agdaKeyword /import\($\|[[:space:].;{}()@"]\)\@=/
  \ skipwhite
  \ nextgroup=agdaImport,agdaImportQualified
syntax match agdaImport /[^[:space:].;{}()@"]\+\($\|[[:space:];{}()@"]\)\@=/
  \ contained skipnl skipwhite
  \ nextgroup=agdaImportAs,agdaImportComment
syntax match agdaImportQualified /[^[:space:].;{}()@"]\+\.\@=/
  \ contained
  \ nextgroup=agdaImportDot
syntax match agdaImportDot /\./
  \ contained
  \ nextgroup=agdaImport,agdaImportQualified
syntax match agdaImportAs /as\($\|[[:space:].;{}()@"]\)\@=/ contained

syntax match agdaKeyword /renaming\($\|[[:space:].;{}()@"]\)\@=/
  \ skipnl skipwhite
  \ nextgroup=agdaRenaming
syntax region agdaRenaming contained start=/(/ end=/)/
  \ contains=agdaComment,agdaIdentifier,agdaOperator,agdaTo,agdaType
syntax match agdaTo /to\($\|[[:space:].;{}()@"]\)\@=/ contained

" ## Comments

syntax match agdaComment /--.*/
syntax region agdaComment start=/{-/ end=/-}/
  \ contains=agdaBlockComment
syntax region agdaPragma start=/{-#/ end=/#-}/

syntax match agdaImportComment /--.*/ contained skipnl skipwhite
  \ nextgroup=agdaImportAs

" ## Literals

syntax match agdaNumber /-\?[0-9]\+\($\|[[:space:];{}()@"]\)\@=/
syntax match agdaNumber /-\?0x[0-9A-Fa-f]\+\($\|[[:space:];{}()@"]\)\@=/
syntax match agdaNumber /-\?[0-9]\+\.[0-9]\+\([Ee]\([+-]\)\?[0-9]\+\)\?/
syntax match agdaNumber /-\?[0-9]\+[Ee]\([+-]\)\?[0-9]\+/

syntax match agdaChar /'[^'\\]'/
syntax match agdaChar /'\\[0-9]\+'/
syntax match agdaChar /'\\0x[0-9A-Fa-f]\+'/
syntax match agdaChar /'\\a'/
syntax match agdaChar /'\\b'/
syntax match agdaChar /'\\t'/
syntax match agdaChar /'\\n'/
syntax match agdaChar /'\\v'/
syntax match agdaChar /'\\f'/
syntax match agdaChar /'\\\\'/
syntax match agdaChar /'\\''/
syntax match agdaChar /'\\"'/
syntax match agdaChar /'\\NUL'/
syntax match agdaChar /'\\SOH'/
syntax match agdaChar /'\\STX'/
syntax match agdaChar /'\\ETX'/
syntax match agdaChar /'\\EOT'/
syntax match agdaChar /'\\ENQ'/
syntax match agdaChar /'\\ACK'/
syntax match agdaChar /'\\BEL'/
syntax match agdaChar /'\\BS'/
syntax match agdaChar /'\\HT'/
syntax match agdaChar /'\\LF'/
syntax match agdaChar /'\\VT'/
syntax match agdaChar /'\\FF'/
syntax match agdaChar /'\\CR'/
syntax match agdaChar /'\\SO'/
syntax match agdaChar /'\\SI'/
syntax match agdaChar /'\\DLE'/
syntax match agdaChar /'\\DC1'/
syntax match agdaChar /'\\DC2'/
syntax match agdaChar /'\\DC3'/
syntax match agdaChar /'\\DC4'/
syntax match agdaChar /'\\NAK'/
syntax match agdaChar /'\\SYN'/
syntax match agdaChar /'\\ETB'/
syntax match agdaChar /'\\CAN'/
syntax match agdaChar /'\\EM'/
syntax match agdaChar /'\\SUB'/
syntax match agdaChar /'\\ESC'/
syntax match agdaChar /'\\FS'/
syntax match agdaChar /'\\GS'/
syntax match agdaChar /'\\RS'/
syntax match agdaChar /'\\US'/
syntax match agdaChar /'\\SP'/
syntax match agdaChar /'\\DEL'/

syntax region agdaString start=/"/ skip=/\\"/ end=/"\|$/

" ## Holes

syntax match agdaHole /?\($\|[[:space:].;{}()@"]\)\@=/
syntax region agdaHole start=/{!/ end=/!}/
  \ contains=agdaHole

syntax match agdaHoleIndexed /?\d\+\($\|[[:space:].;{}()@"]\)\@=/
syntax match agdaHoleIndexed /_\d\+\($\|[[:space:].;{}()@"]\)\@=/

" ## Highlights

highlight default link agdaAs agdaOperator
highlight default link agdaChar agdaString
highlight default link agdaComment Comment
highlight default link agdaEllipses agdaOperator
highlight default link agdaHole WarningMsg
highlight default link agdaImport agdaType
highlight default link agdaImportAs agdaKeyword
highlight default link agdaImportComment agdaComment
highlight default link agdaImportDot agdaDot
highlight default link agdaImportQualified agdaType
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

