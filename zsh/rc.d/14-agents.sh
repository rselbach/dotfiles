path+=("${HOME}/.opencode/bin")

alias c='opencode'

set-claude-deepseek() {
  export ANTHROPIC_AUTH_TOKEN=$(get-token deepseek-api)
  export ANTHROPIC_BASE_URL=https://api.deepseek.com/anthropic
  export ANTHROPIC_MODEL='deepseek-v4-pro[1m]'
  export ANTHROPIC_SUBAGENT_MODEL=deepseek-v4-flash
  export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1
}

set-claude-kimi() {
  export ANTHROPIC_BASE_URL=https://api.kimi.com/coding
  export ANTHROPIC_AUTH_TOKEN=$(get-token kimi)
  export ANTHROPIC_MODEL=kimi-k2.6
  export ANTHROPIC_DEFAULT_OPUS_MODEL=kimi-k2.6
  export ANTHROPIC_DEFAULT_SONNET_MODEL=kimi-k2.6
  export ANTHROPIC_DEFAULT_HAIKU_MODEL=kimi-k2.6
  export CLAUDE_CODE_SUBAGENT_MODEL=kimi-k2.6
  export ENABLE_TOOL_SEARCH=false
}
