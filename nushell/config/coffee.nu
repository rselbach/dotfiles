let theme = {
  bg: "#f5deb3"
  fg: "#000000"
  black: "#3A2C28"
  red: "#c91b00"
  green: "#00c200"
  yellow: "#adaa00"
  blue: "#0225c7"
  magenta: "#ca30c7"
  cyan: "#00b8ba"
  white: "#a1a1a1"
  bright_black: "#686868"
  bright_red: "#ff6e67"
  bright_green: "#1fba28"
  bright_yellow: "#b2af1b"
  bright_blue: "#6871ff"
  bright_magenta: "#f26af2"
  bright_cyan: "#20bdbf"
  bright_white: "#ffffff"
  selection: "#c1deff"
}

let scheme = {
  recognized_command: $theme.blue
  unrecognized_command: $theme.bright_black
  constant: $theme.yellow
  punctuation: $theme.bright_black
  operator: $theme.cyan
  string: $theme.green
  virtual_text: $theme.white
  variable: { fg: $theme.bright_red attr: i }
  filepath: $theme.blue
}

$env.config.color_config = {
  separator: { fg: $theme.bright_black attr: b }
  leading_trailing_space_bg: { fg: $theme.magenta attr: u }
  header: { fg: $theme.fg attr: b }
  row_index: $scheme.virtual_text
  record: $theme.fg
  list: $theme.fg
  hints: $scheme.virtual_text
  search_result: { fg: $theme.bright_white bg: $theme.yellow }
  shape_closure: $theme.cyan
  closure: $theme.cyan
  shape_flag: { fg: $theme.bright_red attr: i }
  shape_matching_brackets: { attr: u }
  shape_garbage: $theme.red
  shape_keyword: $theme.magenta
  shape_match_pattern: $theme.green
  shape_signature: $theme.cyan
  shape_table: $scheme.punctuation
  cell-path: $scheme.punctuation
  shape_list: $scheme.punctuation
  shape_record: $scheme.punctuation
  shape_vardecl: $scheme.variable
  shape_variable: $scheme.variable
  empty: { attr: n }
  filesize: {||
    if $in < 1kb {
      $theme.cyan
    } else if $in < 10kb {
      $theme.green
    } else if $in < 100kb {
      $theme.yellow
    } else if $in < 10mb {
      $theme.bright_red
    } else if $in < 100mb {
      $theme.magenta
    } else if $in < 1gb {
      $theme.red
    } else {
      $theme.bright_magenta
    }
  }
  duration: {||
    if $in < 1day {
      $theme.cyan
    } else if $in < 1wk {
      $theme.green
    } else if $in < 4wk {
      $theme.yellow
    } else if $in < 12wk {
      $theme.bright_red
    } else if $in < 24wk {
      $theme.magenta
    } else if $in < 52wk {
      $theme.red
    } else {
      $theme.bright_magenta
    }
  }
  date: {|| (date now) - $in |
    if $in < 1day {
      $theme.cyan
    } else if $in < 1wk {
      $theme.green
    } else if $in < 4wk {
      $theme.yellow
    } else if $in < 12wk {
      $theme.bright_red
    } else if $in < 24wk {
      $theme.magenta
    } else if $in < 52wk {
      $theme.red
    } else {
      $theme.bright_magenta
    }
  }
  shape_external: $scheme.unrecognized_command
  shape_internalcall: $scheme.recognized_command
  shape_external_resolved: $scheme.recognized_command
  shape_block: $scheme.recognized_command
  block: $scheme.recognized_command
  shape_custom: $theme.magenta
  custom: $theme.magenta
  background: $theme.bg
  foreground: $theme.fg
  cursor: { bg: $theme.fg fg: $theme.bg }
  shape_range: $scheme.operator
  range: $scheme.operator
  shape_pipe: $scheme.operator
  shape_operator: $scheme.operator
  shape_redirection: $scheme.operator
  glob: $scheme.filepath
  shape_directory: $scheme.filepath
  shape_filepath: $scheme.filepath
  shape_glob_interpolation: $scheme.filepath
  shape_globpattern: $scheme.filepath
  shape_int: $scheme.constant
  int: $scheme.constant
  bool: $scheme.constant
  float: $scheme.constant
  nothing: $scheme.constant
  binary: $scheme.constant
  shape_nothing: $scheme.constant
  shape_bool: $scheme.constant
  shape_float: $scheme.constant
  shape_binary: $scheme.constant
  shape_datetime: $scheme.constant
  shape_literal: $scheme.constant
  string: $scheme.string
  shape_string: $scheme.string
  shape_string_interpolation: $theme.magenta
  shape_raw_string: $scheme.string
  shape_externalarg: $scheme.string
}
$env.config.highlight_resolved_externals = true
$env.config.explore = {
    status_bar_background: { fg: $theme.fg, bg: $theme.bg },
    command_bar_text: { fg: $theme.fg },
    highlight: { fg: $theme.bright_white, bg: $theme.yellow },
    status: {
        error: $theme.red,
        warn: $theme.yellow,
        info: $theme.blue,
    },
    selected_cell: { bg: $theme.selection fg: $theme.fg },
}
