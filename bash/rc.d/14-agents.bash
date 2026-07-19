_bash_path+=("${HOME}/.opencode/bin")

# Speed up pi if launched outside a project directory.
export PI_LENS_STARTUP_MODE='quick'

alias c='opencode'

set-claude-default() {
  unset \
    ANTHROPIC_MODEL \
    ANTHROPIC_BASE_URL \
    ANTHROPIC_AUTH_TOKEN \
    ANTHROPIC_SUBAGENT_MODEL \
    CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC \
    CLAUDE_CODE_SUBAGENT_MODEL \
    ANTHROPIC_DEFAULT_HAIKU_MODEL \
    ANTHROPIC_DEFAULT_SONNET_MODEL \
    ANTHROPIC_DEFAULT_OPUS_MODEL \
    ENABLE_TOOL_SEARCH
}

set-claude-deepseek() {
  local token

  if ! token="$(get-token deepseek-api)"; then
    return 1
  fi

  set-claude-default
  export ANTHROPIC_AUTH_TOKEN="${token}"
  export ANTHROPIC_BASE_URL='https://api.deepseek.com/anthropic'
  export ANTHROPIC_MODEL='deepseek-v4-pro[1m]'
  export ANTHROPIC_SUBAGENT_MODEL='deepseek-v4-flash'
  export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1
}

__claude-via-fireworks() {
  local model="${1}"
  local haiku_model="${2:-${model}}"
  local token

  if ! token="$(get-token fireworks)"; then
    return 1
  fi

  set-claude-default
  export ANTHROPIC_BASE_URL='https://api.fireworks.ai/inference'
  export ANTHROPIC_AUTH_TOKEN="${token}"
  export ANTHROPIC_MODEL="${model}"
  export ANTHROPIC_DEFAULT_OPUS_MODEL="${model}"
  export ANTHROPIC_DEFAULT_SONNET_MODEL="${model}"
  export ANTHROPIC_DEFAULT_HAIKU_MODEL="${haiku_model}"
  export CLAUDE_CODE_SUBAGENT_MODEL="${model}"
  export ENABLE_TOOL_SEARCH='false'
}

set-claude-qwen() {
  __claude-via-fireworks 'accounts/fireworks/models/qwen3p6-plus'
}

set-claude-qwen-max() {
  __claude-via-openrouter 'qwen/qwen3.6-max-preview'
}

set-claude-glm() {
  __claude-via-fireworks 'accounts/fireworks/models/glm-5p2'
}

set-claude-kimi() {
  __claude-via-fireworks 'accounts/fireworks/models/kimi-2p7'
}

__claude-via-openrouter() {
  local model="${1}"
  local haiku_model="${2:-${model}}"
  local token

  if ! token="$(get-token openrouter)"; then
    return 1
  fi

  set-claude-default
  export ANTHROPIC_BASE_URL='https://openrouter.ai/api'
  export ANTHROPIC_AUTH_TOKEN="${token}"
  export ANTHROPIC_MODEL="${model}"
  export ANTHROPIC_DEFAULT_OPUS_MODEL="${model}"
  export ANTHROPIC_DEFAULT_SONNET_MODEL="${model}"
  export ANTHROPIC_DEFAULT_HAIKU_MODEL="${haiku_model}"
  export CLAUDE_CODE_SUBAGENT_MODEL="${model}"
  export ENABLE_TOOL_SEARCH='true'
}
