_path_add "${HOME}/.opencode/bin"

# speed up pi if launched outside a project dir
export PI_LENS_STARTUP_MODE=quick

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
  local auth_token

  auth_token="$(get-token deepseek-api)" || return 1
  set-claude-default
  export ANTHROPIC_AUTH_TOKEN="${auth_token}"
  export ANTHROPIC_BASE_URL=https://api.deepseek.com/anthropic
  export ANTHROPIC_MODEL='deepseek-v4-pro[1m]'
  export ANTHROPIC_SUBAGENT_MODEL=deepseek-v4-flash
  export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1
}

__claude-via-fireworks() {
  local model="$1"
  local haiku_model="${2:-$model}"

  local auth_token

  auth_token="$(get-token fireworks)" || return 1
  set-claude-default
  export ANTHROPIC_BASE_URL=https://api.fireworks.ai/inference
  export ANTHROPIC_AUTH_TOKEN="${auth_token}"
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
  __claude-via-fireworks accounts/fireworks/models/glm-5p2
}

set-claude-kimi() {
  __claude-via-fireworks accounts/fireworks/models/kimi-2p7
}

__claude-via-openrouter() {
  local model="$1"
  local haiku_model="${2:-$model}"

  local auth_token

  auth_token="$(get-token openrouter)" || return 1
  set-claude-default
  export ANTHROPIC_BASE_URL=https://openrouter.ai/api
  export ANTHROPIC_AUTH_TOKEN="${auth_token}"
  export ANTHROPIC_MODEL="$model"
  export ANTHROPIC_DEFAULT_OPUS_MODEL="$model"
  export ANTHROPIC_DEFAULT_SONNET_MODEL="$model"
  export ANTHROPIC_DEFAULT_HAIKU_MODEL="$haiku_model"
  export CLAUDE_CODE_SUBAGENT_MODEL="$model"
  export ENABLE_TOOL_SEARCH=true
}

alias claudex='CLAUDE_CODE_SUBAGENT_MODEL=gpt-5.6-sol \
CLAUDE_CODE_ALWAYS_ENABLE_EFFORT=1 \
CLAUDE_CODE_MAX_TOOL_USE_CONCURRENCY=6 \
ENABLE_TOOL_SEARCH=false \
ANTHROPIC_BASE_URL=http://localhost:8317 \
ANTHROPIC_AUTH_TOKEN=not-used \
claude --model gpt-5.6-sol'
