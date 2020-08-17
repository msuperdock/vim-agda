" ## Commands

" Load current file with no command-line options.
function agda#load()
  echom 'Loading Agda.'
  update

  " Start Agda job if not already started.
  if !exists('g:agda_job')
    let g:agda_job = jobstart(['agda', '--interaction-json'] + g:agda_args
      \ , {'on_stdout': function('s:handle_event')})
  endif

  let s:code_file = expand('%:p')
  let s:code_window = winnr()

  call s:send('Cmd_load'
    \ . ' "' . s:code_file . '"'
    \ . ' []'
    \ )
endfunction

" Display context for hole at cursor.
function agda#environment()
  let l:id = s:point_lookup()

  if l:id < 0
    return
  endif

  call s:send('Cmd_goal_type_context'
    \ . ' AsIs'
    \ . ' ' . l:id
    \ . ' noRange'
    \ . ' ""'
    \ )
endfunction

" Give or refine expression for hole at cursor.
function agda#give()
  let l:id = s:point_lookup()

  if l:id < 0
    return
  endif

  let l:input = s:escape(input('Give: '))

  call s:send('Cmd_refine_or_intro'
    \ . ' False '
    \ . ' ' . l:id
    \ . ' noRange'
    \ . ' "' . l:input . '"'
    \ )
endfunction

" Check for unused code in the current module.
function agda#unused()
  update
  call jobstart(['agda-unused', '--local', expand('%'), '--json']
    \ , {'on_stdout': function('s:handle_unused')})
endfunction

" Send command to the Agda job.
function s:send(command)
  call chansend(g:agda_job
    \ , 'IOTCM'
    \ . ' "' . s:code_file . '"'
    \ . ' None'
    \ . ' Direct'
    \ . ' (' . a:command . ')'
    \ . "\n"
    \ )
endfunction

" ## Handlers

" ### Event

" Callback function for the Agda job.
function s:handle_event(id, data, event)
  for l:line in a:data
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
    silent! bdelete Agda
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
    call s:handle_goals_all
      \ ( l:json.info.visibleGoals
      \ , l:json.info.invisibleGoals
      \ , l:json.info.warnings
      \ , l:json.info.errors
      \ )

  " Handle errors.
  elseif l:json.kind ==# 'DisplayInfo' && l:json.info.kind ==# 'Error'
    call s:handle_output('Error', l:json.info.message)

  " Handle context.
  elseif l:json.kind ==# 'DisplayInfo' && l:json.info.kind ==# 'GoalSpecific'
    call s:handle_environment(l:json.info.goalInfo)

  " Handle give.
  elseif l:json.kind ==# 'GiveAction'
    call s:handle_give(l:json.giveResult.str, l:json.interactionPoint)

  " Handle interaction points.
  elseif l:json.kind ==# 'InteractionPoints'
    call s:handle_points(l:json.interactionPoints)

  " Handle status messages.
  elseif l:json.kind ==# 'RunningInfo'
    call s:handle_message(l:json.message)

  endif
endfunction

" ### Goals

function s:handle_goals_all(visible, invisible, warnings, errors)
  let l:types
    \ = (a:visible == [] && a:invisible == [] ? [] : ['Goals'])
    \ + (a:warnings == '' ? [] : ['Warnings'])
    \ + (a:errors == '' ? [] : ['Errors'])

  let l:outputs
    \ = (a:visible == []
    \   ? [] : [s:section('Goals', s:handle_goals(a:visible, 1))])
    \ + (a:invisible == []
    \   ? [] : [s:section('Goals (implicit)', s:handle_goals(a:invisible, 0))])
    \ + (a:warnings == ''
    \   ? [] : [s:section('Warnings', a:warnings)])
    \ + (a:errors == ''
    \   ? [] : [s:section('Errors', a:errors)])

  if l:types == []
    silent! bdelete Agda
    echom "All done."
  else
    call s:handle_output(join(l:types, ', '), join(l:outputs, ''))
  endif
endfunction

function s:handle_goals(goals, visible)
  return join(map(a:goals, 's:handle_goal(v:val, a:visible)'), '')
endfunction

function s:handle_goal(goal, visible)
  if a:goal.kind ==# 'OfType'
    return (a:visible ? '?' : '')
      \ . a:goal.constraintObj
      \ . "\n"
      \ . '  : '
      \ . join(split(a:goal.type, '\n'), "\n    ")
      \ . "\n"

  elseif a:goal.kind ==# 'JustSort'
    return 'Sort '
      \ . a:goal.constraintObj
      \ . "\n"

  else
    return '(unrecognized goal)'

  endif
endfunction

function s:section(name, contents)
  return repeat('─', 4)
    \ . ' '
    \ . a:name
    \ . ' '
    \ . repeat('─', 54 - len(a:name))
    \ . "\n"
    \ . a:contents
    \ . "\n"
endfunction

" ### Points

" Initialize script-local points list.
function s:handle_points(points)
  " Save initial position.
  let l:window = winnr()
  let l:line = line('.')
  let l:col = col('.')

  " Go to beginning of code window.
  execute s:code_window . 'wincmd w'
  call cursor(1, 1)

  let s:points = []
  let l:index = 0

  while l:index < len(a:points)
    let l:pat1 = '\m[[:space:]\n.;{}()@"]\zs?\ze[[:space:]\n.;{}()@]'
    let l:pat2 = '\m{!\_.\{-}!}'
    let l:pat3 = '\m{!\_.\{-}!\zs}'

    let l:pos1 = searchpos(l:pat1, 'nWz')
    let l:pos2 = searchpos(l:pat2, 'nWz')
    let l:pos3 = searchpos(l:pat3, 'nWz')

    let l:line1 = l:pos1[0]
    let l:line2 = l:pos2[0]

    if l:line1 > 0 && (l:line2 == 0 || s:point_compare(l:pos1, l:pos2) < 0)
      let s:points
        \ += [{ 'id': a:points[l:index], 'start': l:pos1, 'end': l:pos1 }]
      call cursor(l:pos1)

    elseif l:line2 > 0
      let s:points
        \ += [{ 'id': a:points[l:index], 'start': l:pos2, 'end': l:pos3 }]
      call cursor(l:pos2)

    else
      break

    endif

    let l:index += 1
  endwhile

  " Restore original position.
  execute l:window . 'wincmd w'
  call cursor(l:line, l:col)
endfunction

" ### Environment

function s:handle_environment(info)
  let l:output
    \ = 'Goal: '
    \ . a:info.type
    \ . "\n"
    \ . repeat('─', 60)
    \ . "\n"
    \ . s:handle_entries(a:info.entries)

  call s:handle_output('Environment', l:output)
endfunction

function s:handle_entries(entries)
  return join(map(a:entries, 's:handle_entry(v:val)'), '')
    \ . "\n"
endfunction

function s:handle_entry(entry)
  return a:entry.reifiedName
    \ . ' : '
    \ . a:entry.binding
    \ . (a:entry.inScope ? '' : ' (not in scope)')
    \ . "\n"
endfunction

" ### Give

function s:handle_give(result, id)
  for l:point in s:points
    if l:point.id == a:id
      call s:replace(s:code_window, l:point.start, l:point.end, a:result)
      return
    endif
  endfor
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
  if s:point_compare([l:line, l:col], a:start) <= 0
    call cursor(l:line, l:col)
  elseif s:point_compare([l:line, l:col], a:end) <= 0
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

" ### Message

function s:handle_message(message)
  echom trim(substitute(a:message, '\m (.*)', '', 'g'))
endfunction

" ### Output

" Print the given output in the Agda buffer.
function s:handle_output(type, output)
  " Save initial window.
  let l:window = winnr()

  " Clear echo area.
  echo ''

  " Switch to Agda buffer.
  let l:agda = bufwinnr('Agda')
  if l:agda >= 0
    execute l:agda . 'wincmd w'
  else
    belowright 10split Agda
    let &l:buftype = 'nofile'
  endif

  " Change buffer name.
  execute 'file Agda (' . a:type . ')'

  " Write output.
  let &l:readonly = 0
  silent %delete _
  silent put =a:output
  execute 'normal! ggdd'
  let &l:readonly = 1

  " Restore original window.
  execute l:window . 'wincmd w'
endfunction

" ## Unused

" ## Utilities

function s:escape(str)
  let l:str = a:str
  let l:str = substitute(l:str, '\', '\\\\', 'g')
  let l:str = substitute(l:str, '"', '\\"', 'g')
  return l:str
endfunction

" Return -1 if point1 is before point2.
" Return 1 if point1 is after point2.
" Return 0 if point1 equals point2.
function s:point_compare(point1, point2)
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
function s:point_lookup()
  let l:loaded
    \ = exists('g:agda_job')
    \ && exists('s:code_file')
    \ && exists('s:code_window')
    \ && exists('s:points')

  if !l:loaded
    echom 'Agda not loaded.'
    return -1
  elseif expand('%:p') !=# s:code_file
    echom 'Agda loaded on different file.'
    return -1
  endif

  let l:line = line('.')
  let l:col = col('.')

  for l:point in s:points
    if s:point_compare([l:line, l:col], l:point.start) >= 0
      \ && s:point_compare([l:line, l:col], l:point.end) <= 0
      return l:point.id.id
    endif
  endfor

  echom 'Cursor not on hole.'
  return -1
endfunction

