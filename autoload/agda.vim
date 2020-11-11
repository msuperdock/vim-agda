" ## Commands

" ### Load

" Load current file with no command-line options.
function agda#load()
  silent update

  augroup agda
    autocmd! * <buffer>
    autocmd BufUnload <buffer> silent! bunload Agda
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

  call s:send('Cmd_load'
    \ . ' "' . s:code_file . '"'
    \ . ' []'
    \ )
endfunction

" ### Next

" Move cursor to next hole.
function agda#next()
  if s:status() < 0
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
  if s:status() < 0
    return
  endif

  let l:pos = [line('.'), col('.')]
  for l:point in reverse(s:points)
    if s:compare(l:point.end, l:pos) < 0
      call cursor(l:point.end)
      echo ''
      return
    endif
  endfor

  echom 'No hole found.'
endfunction

" ### Give

" Give expression for hole at cursor.
" The optional argument indicates whether to skip simplification.
function agda#give(...)
  let l:skip = a:0 >= 1 && a:1

  if s:status(1) < 0
    return
  endif

  let l:id = s:lookup()
  if l:id < 0
    return
  endif

  let l:input = s:escape(input('Give: '))
  if l:input ==# ''
    redraw
    echom 'No expression given.'
    return
  endif

  let s:give = l:skip ? l:input : ''
  call s:send('Cmd_give'
    \ . ' WithoutForce'
    \ . ' ' . l:id
    \ . ' noRange'
    \ . ' "' . l:input . '"'
    \ )
endfunction

" ### Refine

" Refine expression for hole at cursor.
function agda#refine()
  if s:status(1) < 0
    return
  endif

  let l:id = s:lookup()
  if l:id < 0
    return
  endif

  let l:input = s:escape(input(
    \ { 'prompt': 'Refine: '
    \ , 'cancelreturn': '.'
    \ }))
  if l:input ==# '.'
    return
  endif

  let s:give = ''
  call s:send('Cmd_refine_or_intro'
    \ . ' False'
    \ . ' ' . l:id
    \ . ' noRange'
    \ . ' "' . l:input . '"'
    \ )
endfunction

" ### Context

" Display context for hole at cursor.
function agda#context()
  if s:status(1) < 0
    return
  endif

  let l:id = s:lookup()
  if l:id < 0
    return
  endif

  call s:send('Cmd_goal_type_context'
    \ . ' Normalised'
    \ . ' ' . l:id
    \ . ' noRange'
    \ . ' ""'
    \ )
endfunction

" ### Unused

" Check for unused code in the current module.
function agda#unused()
  silent update

  if exists('s:agda_loading') && s:agda_loading > 0
    echom 'Loading Agda (command ignored).'
    return
  endif

  let l:agda_unused_job = jobstart
    \ ( ['agda-unused', '--local', expand('%'), '--json']
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
    let s:agda_loading = 0
    silent! bunload Agda
    echom trim(l:json.message)
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
  if l:json.kind ==# 'DisplayInfo' && l:json.info.kind ==# 'AllGoalsWarnings'
    call s:handle_goals_all(l:json.info)

  " Handle errors.
  elseif l:json.kind ==# 'DisplayInfo' && l:json.info.kind ==# 'Error'
    call s:handle_output('Error', l:json.info.message)

  " Handle context.
  elseif l:json.kind ==# 'DisplayInfo' && l:json.info.kind ==# 'GoalSpecific'
    call s:handle_context(l:json.info.goalInfo)

  " Handle introduction not found error.
  elseif l:json.kind ==# 'DisplayInfo' && l:json.info.kind ==# 'IntroNotFound'
    call s:handle_loading(0)
    echom 'No introduction forms found.'

  " Handle give.
  elseif l:json.kind ==# 'GiveAction'
    let l:result = s:give ==# '' ? l:json.giveResult.str : s:give
    call s:handle_give(l:result, l:json.interactionPoint.id)

  " Handle interaction points.
  elseif l:json.kind ==# 'InteractionPoints'
    call s:handle_points(l:json.interactionPoints)

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
    call add(l:outputs,
      \ { 'name': 'Goals'
      \ , 'content': l:output
      \ })
  endif

  if a:info.warnings !=# ''
    call add(l:outputs,
      \ { 'name': 'Warnings'
      \ , 'content': a:info.warnings
      \ })
  endif

  if a:info.errors !=# ''
    call add(l:outputs,
      \ { 'name': 'Errors'
      \ , 'content': a:info.errors
      \ })
  endif

  call s:handle_outputs(l:outputs, 1)

  if l:outputs == []
    echom "All done."
  endif
endfunction

function s:handle_goals(goals, visible)
  let l:goals = map(copy(a:goals),
    \ {_, val -> s:handle_goal(val, a:visible)})
  return join(l:goals, '')
endfunction

function s:handle_goal(goal, visible)
  if a:goal.kind ==# 'OfType'
    let l:name = (a:visible ? '?' : '') . a:goal.constraintObj
    return s:signature(l:name, a:goal.type)
  elseif a:goal.kind ==# 'JustSort'
    return s:signature(a:goal.constraintObj, 'Sort')
  else
    echoerr 'Unrecognized goal.'
  endif
endfunction

" ### Points

" Initialize script-local points list.
function s:handle_points(points)
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
      
      if l:pos1[0] < line('$')
        call cursor(l:pos1[0] + 1, 1)
      else
        break
      endif

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

" ### Context

function s:handle_context(info)
  let l:outputs = []

  call add(l:outputs,
    \ { 'name': 'Goal'
    \ , 'content': s:signature('Goal', a:info.type)
    \ })

  if a:info.entries != []
    call add(l:outputs,
      \ { 'name': 'Context'
      \ , 'content': s:handle_entries(a:info.entries)
      \ })
  endif

  call s:handle_outputs(l:outputs, 1)
endfunction

function s:handle_entries(entries)
  let l:entries = map(a:entries,
    \ {_, val -> s:handle_entry(val)})
  return join(l:entries, '')
endfunction

function s:handle_entry(entry)
  let l:name = a:entry.reifiedName . (a:entry.inScope ? '' : ' (out of scope)')
  return s:signature(l:name, a:entry.binding)
endfunction

" ### Message

function s:handle_message(message)
  echom trim(substitute(a:message, '\m (.*)', '', 'g'))
endfunction

" ### Output

" Print the given output in the Agda buffer.
" The optional argument indicates whether to use the Agda filetype.
function s:handle_output(name, content, ...)
  let l:syntax = a:0 >= 1 && a:1

  " Clear echo area.
  echo ''

  " Indicate that Agda is no longer loading.
  let s:agda_loading = 0

  " Save initial window.
  let l:current = winnr()

  " Switch to Agda buffer.
  let l:agda = bufwinnr('Agda')
  if l:agda >= 0
    execute l:agda . 'wincmd w'
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

  " Load foldout.
  if g:agda_foldout > 0
    let &l:filetype = l:syntax ? 'agda' : ''
    let b:foldout_heading_comment = 1
    let b:foldout_heading_ignore = '\(Errors\|Warnings\)'
    let b:foldout_heading_string = '-- %s'
    call foldout#enable()
  endif

  " Restore original window.
  execute l:current . 'wincmd w'
endfunction

" Print the given outputs in the Agda buffer, under separate headings.
" The input should be a list of objects with `name` and `content` fields.
" The optional argument indicates whether to use the Agda filetype.
function s:handle_outputs(outputs, ...)
  let l:syntax = a:0 >= 1 && a:1

  if a:outputs == []
    let s:agda_loading = 0
    silent! bunload Agda
    return
  endif

  let l:names
    \ = map(copy(a:outputs), {_, val -> val['name']})
  let l:contents
    \ = len(a:outputs) == 1
    \ ? map(copy(a:outputs), {_, val -> val['content'] . "\n"})
    \ : map(copy(a:outputs), {_, val -> s:section(val['name'], val['content'])})
  call s:handle_output
    \ ( join(l:names, ', ')
    \ , join(l:contents, '')
    \ , l:syntax
    \ )
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

" ## Print

" Escape a string for passing to the Agda executable.
function s:escape(str)
  return escape(a:str, '\"')
endfunction

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
    \ . join(split(a:type, '\n'), "\n    ")
    \ . "\n"
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

" Get id of interaction point at cursor, or return -1 on failure.
function s:lookup()
  let l:line = line('.')
  let l:col = col('.')
  for l:point in s:points
    if s:compare([l:line, l:col], l:point.start) >= 0
      \ && s:compare([l:line, l:col], l:point.end) <= 0
      return l:point.id
    endif
  endfor

  echom 'Cursor not on hole.'
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

" Send command to the Agda job.
function s:send(command)
  call s:handle_loading(1)
  call chansend(g:agda_job
    \ , 'IOTCM'
    \ . ' "' . s:code_file . '"'
    \ . ' None'
    \ . ' Direct'
    \ . ' (' . a:command . ')'
    \ . "\n"
    \ )
endfunction

" Check whether Agda is loaded on the current file.
" The optional argument indicates whether to also check if Agda is loading.
function s:status(...)
  let l:check_loading = a:0 >= 1 && a:1

  let l:loaded
    \ = exists('g:agda_job')
    \ && exists('s:agda_loading')
    \ && exists('s:code_file')
    \ && exists('s:code_window')
    \ && exists('s:points')
    \ && g:agda_job >= 0

  if !l:loaded
    echom 'Agda not loaded.'
    return -1
  elseif expand('%:p') !=# s:code_file
    echom 'Agda loaded on different file.'
    return -1
  elseif l:check_loading && s:agda_loading > 0
    echom 'Loading Agda (command ignored).'
    return -1
  endif
endfunction

