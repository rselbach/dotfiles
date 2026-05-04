path+=("${HOME}/.opencode/bin")

alias c='opencode'

set-claude-default() {
  unset ANTHROPIC_MODEL
  unset ANTHROPIC_BASE_URL
  unset ANTHROPIC_AUTH_TOKEN
  unset ANTHROPIC_SUBAGENT_MODEL
  unset CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC
  unset CLAUDE_CODE_SUBAGENT_MODEL
  unset ANTHROPIC_DEFAULT_HAIKU_MODEL
  unset ANTHROPIC_DEFAULT_SONNET_MODEL
  unset ANTHROPIC_DEFAULT_OPUS_MODEL
  unset ENABLE_TOOL_SEARCH
}

set-claude-deepseek() {
  export ANTHROPIC_AUTH_TOKEN=$(get-token deepseek-api)
  export ANTHROPIC_BASE_URL=https://api.deepseek.com/anthropic
  export ANTHROPIC_MODEL='deepseek-v4-pro[1m]'
  export ANTHROPIC_SUBAGENT_MODEL=deepseek-v4-flash
  export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1
}

__claude-via-fireworks() {
  local model="$1"
  local haiku_model="${2:-$model}"

  export ANTHROPIC_BASE_URL=https://api.fireworks.ai/inference
  export ANTHROPIC_AUTH_TOKEN=$(get-token fireworks)
  export ANTHROPIC_MODEL="$model"
  export ANTHROPIC_DEFAULT_OPUS_MODEL="$model"
  export ANTHROPIC_DEFAULT_SONNET_MODEL="$model"
  export ANTHROPIC_DEFAULT_HAIKU_MODEL="$haiku_model"
  export CLAUDE_CODE_SUBAGENT_MODEL="$model"
  export ENABLE_TOOL_SEARCH=false
}

set-claude-qwen() {
  __claude-via-fireworks accounts/fireworks/models/qwen3p6-plus
}

set-claude-qwen-max() {
  __claude-via-openrouter qwen/qwen3.6-max-preview
}

set-claude-glm() {
  __claude-via-fireworks accounts/fireworks/models/glm-5p1
}

set-claude-kimi() {
  __claude-via-fireworks accounts/fireworks/models/glm-5p1
}

__claude-via-openrouter() {
  local model="$1"
  local haiku_model="${2:-$model}"

  export ANTHROPIC_BASE_URL=https://openrouter.ai/api
  export ANTHROPIC_AUTH_TOKEN=$(get-token openrouter)
  export ANTHROPIC_MODEL="$model"
  export ANTHROPIC_DEFAULT_OPUS_MODEL="$model"
  export ANTHROPIC_DEFAULT_SONNET_MODEL="$model"
  export ANTHROPIC_DEFAULT_HAIKU_MODEL="$haiku_model"
  export CLAUDE_CODE_SUBAGENT_MODEL="$model"
  export ENABLE_TOOL_SEARCH=true
}

