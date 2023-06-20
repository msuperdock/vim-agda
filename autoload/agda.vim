" ## Commands

" ### Load

" Load current file with no command-line options.
function agda#load()
  silent update

  augroup agda
    autocmd! * <buffer>
    autocmd BufUnload <buffer> silent! bdelete Agda
  augroup end

  if exists('s:agda_loading') && s:agda_loading > 0
    echom 'Loading Agda (command ignored).'
    return
  endif

  if !exists('g:agda_job') || g:agda_job < 0
    let g:agda_job = jobstart(['agda', '--interaction-json'] + g:agda_args
      \ , {'on_stdout': function('s:handle_event')})
  endif

  if g:agda_job < 0
    echom 'Failed to load Agda.'
    return
  endif

  redraw
  echom 'Loading Agda.'

  let s:code_file = expand('%:p')
  let s:code_window = winnr()
  let s:data = ''

  let l:command =
    \ [ 'Cmd_load'
    \ , s:quote(s:code_file)
    \ , '[]'
    \ ]

  call s:send(l:command)
endfunction

" ### Abort

" Abort the current Agda process operation.
function agda#abort()
  if s:status(2) < 0
    return
  endif

  if s:agda_loading == 0
    echom 'Nothing to abort.'
    return
  endif

  call s:send(['Cmd_abort'], 1)
endfunction

" ### Next

" Move cursor to next hole.
function agda#next()
  if s:status(1) < 0
    return
  endif

  let l:pos = [line('.'), col('.')]
  for l:point in s:points
    if s:compare(l:point.start, l:pos) > 0
      call cursor(l:point.start)
      echo ''
      return
    endif
  endfor

  echom 'No hole found.'
endfunction

" ### Previous

" Move cursor to previous hole.
function agda#previous()
  if s:status(1) < 0
    return
  endif

  let l:pos = [line('.'), col('.')]
  for l:point in reverse(s:points)
    if s:compare(l:point.end, l:pos) < 0
      call cursor(l:point.start)
      echo ''
      return
    endif
  endfor

  echom 'No hole found.'
endfunction

" ### Infer

function agda#infer()
  if s:status() < 0
    return
  endif

  let l:id = s:lookup()

  let l:input = s:input('Infer', 1)
  if l:input ==# '.'
    return
  endif

  if l:id >= 0
    let l:command =
      \ [ 'Cmd_infer'
      \ , 'Simplified'
      \ , l:id
      \ , 'noRange'
      \ , s:quote(l:input)
      \ ]

  else
    let l:command =
      \ [ 'Cmd_infer_toplevel'
      \ , 'Simplified'
      \ , s:quote(l:input)
      \ ]

  endif

  call s:send(l:command)
endfunction

" ### Give

" Give expression for hole at cursor.
function agda#give()
  if s:status() < 0
    return
  endif

  let l:id = s:lookup(1)
  if l:id < 0
    return
  endif

  let l:input = s:input('Give', 1)
  if l:input ==# '.'
    return
  endif

  let l:command =
    \ [ 'Cmd_give'
    \ , 'WithoutForce'
    \ , l:id
    \ , 'noRange'
    \ , s:quote(l:input)
    \ ]

  call s:send(l:command)
endfunction

" ### Refine

" Refine expression for hole at cursor.
function agda#refine()
  if s:status() < 0
    return
  endif

  let l:id = s:lookup(1)
  if l:id < 0
    return
  endif

  let l:input = s:input('Refine')
  if l:input ==# '.'
    return
  endif

  let l:command =
    \ [ 'Cmd_refine_or_intro'
    \ , 'False'
    \ , l:id
    \ , 'noRange'
    \ , s:quote(l:input)
    \ ]

  call s:send(l:command)
endfunction

" ### Context

" Display context for hole at cursor.
function agda#context()
  if s:status() < 0
    return
  endif

  let l:id = s:lookup(1)
  if l:id < 0
    return
  endif

  let l:command =
    \ [ 'Cmd_goal_type_context'
    \ , 'Simplified'
    \ , l:id
    \ , 'noRange'
    \ , s:quote('')
    \ ]

  call s:send(l:command)
endfunction

" ### Unused

" Check for unused code in the current module.
function agda#unused()
  if exists('s:agda_loading') && s:agda_loading > 0
    echom 'Loading Agda (command ignored).'
    return
  endif

  silent update
  let l:agda_unused_job = jobstart
    \ ( ['agda-unused', expand('%'), '--json'] + g:agda_unused_args
    \ , {'on_stdout': function('s:handle_unused')}
    \ )

  if l:agda_unused_job < 0
    echom 'Failed to run agda-unused.'
  else
    call s:handle_loading(1)
  endif
endfunction

" ### Debug

" Toggle value of `agda_debug`.
function agda#toggle_debug()
  if g:agda_debug
    echom "Agda debugging off."
    let g:agda_debug = 0
  else
    echom "Agda debugging on."
    let g:agda_debug = 1
  endif
endfunction

" ## Handlers

" ### Event

" Callback function for the Agda job.
function s:handle_event(id, data, event)
  for l:line in a:data
    if g:agda_debug
      echom l:line
      echo ''
      redraw
    endif

    call s:handle_line(l:line)
  endfor
endfunction

" Callback function for the agda-unused job.
function s:handle_unused(id, data, event)
  " Check if output is non-empty; return if not.
  if len(a:data) == 0
    return
  endif

  " Decode JSON; return if unsuccessful.
  try
    let l:json = json_decode(a:data[0])
  catch
    return
  endtry

  " Handle output.
  if l:json.type ==# 'none'
    call s:handle_clear(trim(l:json.message))
  elseif l:json.type ==# 'unused'
    call s:handle_output('Unused', l:json.message)
  elseif l:json.type ==# 'error'
    call s:handle_output('Unused', l:json.message)
  endif
endfunction

" ### Line

" Handle a line of data from Agda.
function s:handle_line(line)
  " Ignore interaction prompt.
  if a:line ==# 'JSON> '
    let s:data = ''
    return
  endif

  " Try decoding JSON; store line if decoding JSON fails.
  try
    let l:json = json_decode(s:data . a:line)
  catch
    let s:data .= a:line
    return
  endtry

  " Reset data if decoding JSON succeeds.
  let s:data = ''

  " Handle goals.
  if l:json.kind ==# 'DisplayInfo'
    \ && l:json.info.kind ==# 'AllGoalsWarnings'
    call s:handle_goals_all(l:json.info)

  " Handle errors.
  elseif l:json.kind ==# 'DisplayInfo'
    \ && l:json.info.kind ==# 'Error'
    call s:handle_error(l:json.info)

  " Handle inferred type at hole.
  elseif l:json.kind ==# 'DisplayInfo'
    \ && l:json.info.kind ==# 'GoalSpecific'
    \ && l:json.info.goalInfo.kind ==# 'InferredType'
    call s:handle_infer(l:json.info.goalInfo.expr)

  " Handle context.
  elseif l:json.kind ==# 'DisplayInfo'
    \ && l:json.info.kind ==# 'GoalSpecific'
    call s:handle_context(l:json.info.goalInfo)

  " Handle inferred type.
  elseif l:json.kind ==# 'DisplayInfo'
    \ && l:json.info.kind ==# 'InferredType'
    call s:handle_infer(l:json.info.expr)

  " Handle introduction not found error.
  elseif l:json.kind ==# 'DisplayInfo'
    \ && l:json.info.kind ==# 'IntroNotFound'
    call s:handle_loading(0)
    echom 'No introduction forms found.'

  " Handle abort.
  elseif l:json.kind ==# 'DoneAborting'
    call s:handle_loading(0)
    echom 'Aborted Agda command.'

  " Handle give.
  elseif l:json.kind ==# 'GiveAction'
    call s:handle_give(l:json.giveResult.str, l:json.interactionPoint.id)

  " Handle interaction points.
  elseif l:json.kind ==# 'InteractionPoints'
    call s:handle_points(l:json.interactionPoints)

  " Handle jump to error.
  elseif l:json.kind ==# 'JumpToError'
    call s:goto(l:json.position)

  " Handle status messages.
  elseif l:json.kind ==# 'RunningInfo'
    call s:handle_message(l:json.message)

  endif
endfunction

" ### Goals

function s:handle_goals_all(info)
  let l:outputs = []

  if a:info.visibleGoals != [] || a:info.invisibleGoals != []
    let l:output
      \ = s:handle_goals(a:info.visibleGoals, 1)
      \ . s:handle_goals(a:info.invisibleGoals, 0)
    call s:append_output(l:outputs, 'Goals', l:output, 1)
  endif

  call s:append_messages(l:outputs, 'Warnings', a:info.warnings)
  call s:append_messages(l:outputs, 'Errors', a:info.errors)

  call s:handle_outputs(l:outputs)
endfunction

function s:handle_goals(goals, visible)
  let l:goals = map(copy(a:goals), {_, val -> s:handle_goal(val, a:visible)})
  return join(l:goals, '')
endfunction

function s:handle_goal(goal, visible)
  if a:goal.kind ==# 'OfType'
    let l:name
      \ = a:visible
      \ ? '?' . a:goal.constraintObj.id
      \ : a:goal.constraintObj.name
    return s:signature(l:name, a:goal.type)
  elseif a:goal.kind ==# 'JustSort'
    return s:signature(a:goal.constraintObj.name, 'Sort')
  else
    echoerr 'Unrecognized goal.'
  endif
endfunction

" ### Points

" Initialize script-local points list.
function s:handle_points(points)
  " If any points are missing range, determine ranges by scanning file.
  if s:handle_points_valid(a:points)
    let s:points = map(copy(a:points), {_, val -> s:handle_point(val)})
  else
    call s:handle_points_manual(a:points)
  endif
endfunction

function s:handle_point(point)
  return
    \ { 'id': a:point.id
    \ , 'start': s:handle_position(a:point.range[0].start, 0)
    \ , 'end': s:handle_position(a:point.range[0].end, -1)
    \ }
endfunction

function s:handle_position(pos, offset)
  return [a:pos.line, byteidxcomp(getline(a:pos.line), a:pos.col + a:offset)]
endfunction

" Determine whether the given points list has nonempty ranges.
function s:handle_points_valid(points)
  for l:point in a:points
    if l:point.range == []
      return 0
    endif
  endfor

  return 1
endfunction

function s:handle_points_manual(points)
  " Save initial position.
  let l:window = winnr()
  let l:line = line('.')
  let l:col = col('.')

  " Patterns for start & end of token.
  let l:start = '\(^\|[[:space:].;{}()@"]\)'
  let l:end = '\($\|[[:space:].;{}()@"]\)'

  " Go to beginning of code window.
  execute s:code_window . 'wincmd w'
  call cursor(1, 1)

  " Initialize points list.
  let s:points = []

  let l:index = 0
  while l:index < len(a:points)

    " Match single-line comments.
    let l:pos1 = searchpos('\m' . l:start . '--', 'nWz')

    " Match block comments.
    let l:pos2 = searchpos('\m{-', 'nWz')

    " Match strings.
    let l:pos3 = searchpos('\m"', 'nWz')

    " Match holes.
    let l:pos4 = searchpos('\m' . l:start . '\zs?' . l:end, 'nWz')

    " Match block holes.
    let l:pos5 = searchpos('\m{!', 'nWz')

    " If single-line comment is found first:
    if l:pos1[0] > 0
      \ && (l:pos2[0] == 0 || s:compare(l:pos1, l:pos2) < 0)
      \ && (l:pos3[0] == 0 || s:compare(l:pos1, l:pos3) < 0)
      \ && (l:pos4[0] == 0 || s:compare(l:pos1, l:pos4) < 0)
      \ && (l:pos5[0] == 0 || s:compare(l:pos1, l:pos5) < 0)

      call cursor(l:pos1)
      call cursor(l:pos1[0], col('$'))

    " If block comment is found first:
    elseif l:pos2[0] > 0
      \ && (l:pos3[0] == 0 || s:compare(l:pos2, l:pos3) < 0)
      \ && (l:pos4[0] == 0 || s:compare(l:pos2, l:pos4) < 0)
      \ && (l:pos5[0] == 0 || s:compare(l:pos2, l:pos5) < 0)

      call cursor(l:pos2)
      if searchpair('\m{-', '', '\m-}', 'Wz') <= 0
        break
      endif

    " If string is found first:
    elseif l:pos3[0] > 0
      \ && (l:pos4[0] == 0 || s:compare(l:pos3, l:pos4) < 0)
      \ && (l:pos5[0] == 0 || s:compare(l:pos3, l:pos5) < 0)

      call cursor(l:pos3)
      if search('\m"', 'Wz') <= 0 || s:next() == 0
        break
      endif

    " If hole is found first:
    elseif l:pos4[0] > 0
      \ && (l:pos5[0] == 0 || s:compare(l:pos4, l:pos5) < 0)

      let s:points += [
        \ { 'id': a:points[l:index].id
        \ , 'start': l:pos4
        \ , 'end': l:pos4
        \ }]
      let l:index += 1

      call cursor(l:pos4)
      if s:next() == 0
        break
      endif

    " If block hole is found first:
    elseif l:pos5[0] > 0

      call cursor(l:pos5)
      let l:pos6 = searchpairpos('\m{!', '', '\m!\zs}', 'Wz')
      if l:pos6[0] == 0
        break
      endif

      let s:points += [
        \ { 'id': a:points[l:index].id
        \ , 'start': l:pos5
        \ , 'end': l:pos6
        \ }]
      let l:index += 1

    " If no match is found:
    else

      break

    endif
  endwhile

  " Restore original position.
  execute l:window . 'wincmd w'
  call cursor(l:line, l:col)
endfunction

" ### Give

function s:handle_give(result, id)
  for l:point in s:points
    if l:point.id == a:id
      call s:replace(s:code_window, l:point.start, l:point.end, a:result)
      silent update
      return
    endif
  endfor
endfunction

" ### Infer

function s:handle_infer(result)
  call s:handle_clear('Inferred type: ' . a:result)
endfunction

" ### Context

function s:handle_context(info)
  let l:outputs = []

  call s:append_output(l:outputs, 'Goal',
    \ s:signature('Goal', a:info.type), 1)
  call s:append_output(l:outputs, 'Context',
    \ s:handle_entries(a:info.entries), 1)
  call s:handle_outputs(l:outputs)
endfunction

function s:handle_entries(entries)
  return join(map(copy(a:entries), {_, val -> s:handle_entry(val)}), '')
endfunction

function s:handle_entry(entry)
  let l:name = a:entry.reifiedName . (a:entry.inScope ? '' : ' (out of scope)')
  return s:signature(l:name, a:entry.binding)
endfunction

" ### Message

function s:handle_message(message)
  echom trim(substitute(a:message, '\m (.*)', '', 'g'))
endfunction

function s:append_message(outputs, name, content)
  return s:append_output(a:outputs, a:name, a:content.message . "\n")
endfunction

function s:append_messages(outputs, name, contents)
  if a:contents == []
    return a:outputs
  endif

  let l:messages = map(copy(a:contents), {_, val -> val['message'] . "\n"})
  return s:append_output(a:outputs, a:name, join(l:messages, ''))
endfunction

" ### Error

function s:handle_error(info)
  let l:outputs = []

  call s:append_messages(l:outputs, 'Warnings', a:info.warnings)
  call s:append_message(l:outputs, 'Error', a:info.error)
  call s:handle_outputs(l:outputs)
endfunction

" ### Output

" Print the given output in the Agda buffer.
" The optional argument indicates whether to treat the output as code.
function s:handle_output(name, content, ...)
  let l:code = get(a:, 1)

  " Clear echo area.
  echo ''

  " Indicate that Agda is no longer loading.
  let s:agda_loading = 0

  " Save initial window.
  let l:current = winnr()

  " Switch to Agda buffer.
  let l:agda_buffer = bufnr('Agda')
  let l:agda_window = bufwinnr('Agda')
  if l:agda_window >= 0
    execute l:agda_window . 'wincmd w'
  elseif l:agda_buffer >= 0
    belowright 10new
    execute l:agda_buffer . 'buffer'
  else
    belowright 10split Agda
    let &l:buftype = 'nofile'
    let &l:swapfile = 0
  endif

  " Change buffer name.
  execute 'file Agda (' . a:name . ')'

  " Write output.
  let &l:readonly = 0
  silent %delete _
  silent put =a:content
  execute 'normal! ggdd'
  let &l:readonly = 1
  silent! %foldopen!

  " Enable foldout if loaded.
  if exists('g:foldout_loaded')
    let &l:filetype = l:code ? 'agda' : ''
    let b:foldout_heading_comment = 1
    let b:foldout_heading_ignore = '\(Errors\|Warnings\)'
    let b:foldout_heading_string = '-- %s'
    call foldout#enable()
  endif

  " Restore original window.
  execute l:current . 'wincmd w'
endfunction

" Print the given outputs in the Agda buffer, under separate headings.
" The input should be a list of objects with `name`, `content`, `code` fields:
" - The `name` field is a string for the section heading.
" - The `content` field is a string for the section contents.
" - The `code` field is a flag indicating whether to treat the contents as code.
function s:handle_outputs(outputs)
  if a:outputs == []
    call s:handle_clear('All done.')
    return
  endif

  let l:names
    \ = map(copy(a:outputs), {_, val -> val['name']})
  let l:contents
    \ = len(a:outputs) == 1
    \ ? map(copy(a:outputs), {_, val -> val['content'] . "\n"})
    \ : map(copy(a:outputs), {_, val -> s:section(val['name'], val['content'])})
  let l:code
    \ = len(a:outputs) != 1 || a:outputs[0].code

  call s:handle_output
    \ ( join(l:names, ', ')
    \ , join(l:contents, '')
    \ , l:code
    \ )
endfunction

" Clear the agda buffer, and echo the given message string.
function s:handle_clear(message)
  let s:agda_loading = 0
  silent! bdelete Agda
  echom a:message
endfunction

" Display loading status in Agda buffer name.
function s:handle_loading(loading)
  " Update `s:agda_loading` variable.
  let s:agda_loading = a:loading

  " Save initial window.
  let l:current = winnr()

  " Get Agda buffer window.
  let l:agda = bufwinnr('Agda')
  if l:agda < 0
    return
  endif

  " Change Agda buffer name, if necessary.
  execute l:agda . 'wincmd w'
  let l:file = expand('%')
  let l:match = match(l:file, '\m \[loading\]$')
  if a:loading == 0 && l:match >= 0 
    execute 'file ' . l:file[: l:match - 1]
  elseif a:loading > 0 && l:match < 0
    execute 'file ' . l:file . ' [loading]'
  endif

  " Restore original window.
  execute l:current . 'wincmd w'
endfunction

function s:append_output(outputs, name, content, ...)
  let l:code = get(a:, 1)

  return add(a:outputs,
    \ { 'name': a:name
    \ , 'content': a:content
    \ , 'code': l:code
    \ })
endfunction

" ## Print

" Format a section with heading & content.
function s:section(name, content)
  return '-- ## '
    \ . a:name
    \ . "\n\n"
    \ . a:content
    \ . "\n"
endfunction

" Format a type signature.
function s:signature(name, type)
  return a:name
    \ . "\n"
    \ . '  : '
    \ . join(split(a:type, "\n"), "\n    ")
    \ . "\n"
endfunction

" ## Indent

" Compute indent level for a line.
function agda#indent(lnum)
  if a:lnum <= 1
    return -1
  endif

  let l:line = getline(a:lnum - 1)

  let l:directive
    \ = l:line =~# '\musing\($\|[[:space:].;{}()@"]\)'
    \ || l:line =~# '\mrenaming\($\|[[:space:].;{}()@"]\)'
    \ || l:line =~# '\mhiding\($\|[[:space:].;{}()@"]\)'
  if !l:directive
    return -1
  endif

  let l:directive_open
    \ = l:line =~# '\musing\s*$'
    \ || l:line =~# '\mrenaming\s*$'
    \ || l:line =~# '\mhiding\s*$'
    \ || count(l:line, '(') > count(l:line, ')')
  if !l:directive_open
    return -1
  endif

  return indent(a:lnum) + shiftwidth()
endfunction

" ## Utilities

" Return -1 if point1 is before point2.
" Return 1 if point1 is after point2.
" Return 0 if point1 equals point2.
function s:compare(point1, point2)
  let [l:line1, l:col1] = a:point1
  let [l:line2, l:col2] = a:point2

  if l:line1 < l:line2
    return -1
  elseif l:line1 > l:line2
    return 1
  elseif l:col1 < l:col2
    return -1
  elseif l:col1 > l:col2
    return 1
  else
    return 0
  endif
endfunction

" Go to the nth character in the buffer.
function s:goto(n)
  execute 'goto ' . byteidxcomp(join(getline(1, '$'), "\n"), a:n)
endfunction

" Get input from the user.
" The `prompt` string should not include a trailing colon or space.
" The optional argument indicates whether to fail on all-whitespace input.
" Return an escaped string, or '.' on failure.
function s:input(prompt, ...)
  let l:strict = get(a:, 1)

  let l:input = input(
    \ { 'prompt': a:prompt . ': '
    \ , 'cancelreturn': '.'
    \ })

  if l:strict && l:input !~# '\m\S'
    redraw
    echom 'No expression given.'
    return '.'
  endif

  return escape(l:input, '\"')
endfunction

" Get id of interaction point at cursor, or return -1 on failure.
" The optional argument indicates whether to print an error message on failure.
function s:lookup(...)
  let l:print = get(a:, 1)

  let l:line = line('.')
  let l:col = col('.')
  for l:point in s:points
    if s:compare([l:line, l:col], l:point.start) >= 0
      \ && s:compare([l:line, l:col], l:point.end) <= 0
      return l:point.id
    endif
  endfor

  if l:print
    echom 'Cursor not on hole.'
  endif

  return -1
endfunction

" Go to next character; return 1 if successful, 0 if at end of file.
function s:next()
  let l:line = line('.')
  let l:col = col('.')

  if l:col < col('$') - 1
    call cursor(l:line, l:col + 1)
    return 1
  elseif l:line < line('$')
    call cursor(l:line + 1, 1)
    return 1
  endif

  return 0
endfunction

" Wrap a string in parentheses.
function s:parens(str)
  return '(' . a:str . ')'
endfunction

" Wrap a string in double quotes.
function s:quote(str)
  return '"' . a:str . '"'
endfunction

" Replace text at the given location, preserving cursor position.
" Assume `str` does not contain any newline characters.
function s:replace(window, start, end, str)
  " Save window.
  let l:window = winnr()
  execute a:window . 'wincmd w'

  " Save cursor position.
  let l:line = line('.')
  let l:col = col('.')

  " Perform deletion.
  call cursor(a:start)
  if a:end[0] == a:start[0]
    execute 'normal! ' . (a:end[1] - a:start[1] + 1) . 'x'
  else
    let l:command
      \ = a:end[0] > a:start[0] + 1
      \ ? (a:start[0] + 1) . ',' . (a:end[0] - 1) . 'd'
      \ : ''
    execute 'normal! d$'
    execute l:command
    call cursor(a:start[0] + 1, 1)
    execute 'normal! ' . a:end[1] . 'x'
    call cursor(a:start[0], 1)
    execute 'normal! gJ'
  endif

  " Perform insertion.
  call cursor(a:start[0], a:start[1] - 1)
  execute 'normal! a' . a:str

  " Restore cursor position.
  if s:compare([l:line, l:col], a:start) <= 0
    call cursor(l:line, l:col)
  elseif s:compare([l:line, l:col], a:end) <= 0
    call cursor(a:start)
  elseif l:line == a:start[0] && l:line == a:end[0]
    call cursor(a:start[0], l:col - (a:end[1] - a:start[1] + 1))
  elseif l:line == a:end[0]
    call cursor(a:start[0], l:col - a:end[1])
  elseif a:end[0] == a:start[0]
    call cursor(l:line, l:col)
  else
    call cursor(l:line - (a:end[0] - a:start[0] - 1), l:col)
  endif

  " Restore window.
  execute l:window . 'wincmd w'
endfunction

" Send command, as a list of tokens, to the Agda job.
" The optional argument indicates whether to send an indirect command.
function s:send(command, ...)
  let l:indirect = get(a:, 1)

  if !l:indirect
    call s:handle_loading(1)
  endif

  let l:command =
    \ [ 'IOTCM'
    \ , s:quote(s:code_file)
    \ , 'None'
    \ , (l:indirect ? 'Indirect' : 'Direct')
    \ , s:parens(join(a:command))
    \ ]

  call chansend(g:agda_job, join(l:command) . "\n")
endfunction

" Check whether Agda is loaded on the current file.
" With no optional argument, require that Agda is loaded and not busy.
" With optional argument of 1, require only that Agda is loaded.
" With optional argument of 2, require only that Agda has started loading.
function s:status(...)
  let l:mode = get(a:, 1)

  let l:loaded
    \ = exists('g:agda_job')
    \ && (l:mode == 2 || exists('s:agda_loading'))
    \ && (l:mode == 2 || exists('s:code_file'))
    \ && (l:mode == 2 || exists('s:code_window'))
    \ && (l:mode == 2 || exists('s:points'))
    \ && g:agda_job >= 0

  if !l:loaded
    echom 'Agda not loaded.'
    return -1
  elseif expand('%:p') !=# s:code_file
    echom 'Agda loaded on different file.'
    return -1
  elseif l:mode == 0 && s:agda_loading > 0
    echom 'Loading Agda (command ignored).'
    return -1
  endif
endfunction

