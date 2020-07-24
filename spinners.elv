use str

spinners = (from-json < (path-dir (src)[path])/spinners.json)

default-spinner = 'dots'

fn output [@s]{
  print $@s >/dev/tty
}

fn spinner-sleep [s]{
  sleep (to-string (/ $s[interval] 1000))
}

fn hide-cursor {
  put "\e[?25l"
}
fn show-cursor {
  put "\e[?25h"
}
fn clear-line {
  put "\e[0K"
}

fn list {
  keys $spinners | order
}

fn new [&spinner=$nil &frames=$nil &interval=$nil &title="" &style=[] &prefix="" &indent=0 &cursor=$false &persist=$false &id=$nil]{
  # Use default spinner if none is specified
  if (not $spinner) { spinner = $default-spinner }
  # Automatically convert non-list styles, so you can do e.g. &style=red
  if (not-eq (kind-of $style) list) { style = [$style] }
  put [
    &id=       (or $id (e=?(uuidgen)) (randint 0 9999999))
    &frames=   (or $frames $spinners[$spinner][frames])
    &interval= (or $interval $spinners[$spinner][interval])
    &title=    $title
    &prefix=   $prefix
    &indent=   $indent
    &style=    $style
    &cursor=   $cursor
    &persist=  $persist
    &current=  0
  ]
}

fn step [spinner]{
  steps = $spinner[frames]
  indentation = (str:join '' [(repeat $spinner[indent] ' ')])
  pre-string = (if (not-eq $spinner[prefix] '') { put $spinner[prefix]' ' } else { put '' })
  post-string = (if (not-eq $spinner[title] '') { put ' '$spinner[title] } else { put '' })
  output $indentation$pre-string(styled $steps[$spinner[current]] (all $spinner[style]))$post-string(clear-line)"\r"
  inc = 1
  if (eq (kind-of $steps string)) {
    inc = (count $steps[$spinner[current]])
  }
  spinner[current] = (% (+ $spinner[current] $inc) (count $steps))
  put $spinner
}

fn run [&spinner=$nil &frames=$nil &interval=$nil &title="" &prefix="" &style=[] &cursor=$false &persist=$false f]{
  s = (new &spinner=$spinner &frames=$frames &interval=$interval &title=$title &prefix=$prefix &style=$style &cursor=$cursor &persist=$persist)
  stop = $false
  run-parallel {
    if (not $s[cursor]) { output (hide-cursor) }
    while (not $stop) {
      s = (step $s)
      spinner-sleep $s
    }
    if (not $s[cursor]) { output (show-cursor) }
    if $persist {
      output "\n"
    } else {
      output (clear-line)
    }
  } {
    try {
      $f
    } finally {
      stop = $true
    }
  }
}

fn demo [&time=2 &style=blue]{
  list | each [s]{
    run &spinner=$s &title=$s &style=$style { sleep $time }
  }
}