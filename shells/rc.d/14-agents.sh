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
  export ANTHROPIC_MODEL="k3[1m]"
  export ANTHROPIC_DEFAULT_FABLE_MODEL=$ANTHROPIC_MODEL
  export ANTHROPIC_DEFAULT_OPUS_MODEL=$ANTHROPIC_MODEL
  export ANTHROPIC_DEFAULT_SONNET_MODEL=$ANTHROPIC_MODEL
  export ANTHROPIC_DEFAULT_HAIKU_MODEL=$ANTHROPIC_MODEL
  export CLAUDE_CODE_SUBAGENT_MODEL=$ANTHROPIC_MODEL
  export CLAUDE_CODE_EFFORT_LEVEL=high
  export CLAUDE_CODE_AUTO_COMPACT_WINDOW=1048576
  export CLAUDE_CODE_MAX_CONTEXT_TOKENS=1048576
  export ANTHROPIC_API_KEY=$(get-token kimi)
  export ANTHROPIC_BASE_URL=https://api.kimi.com/coding/
}

claude-kimi() {
  ANTHROPIC_DEFAULT_FABLE_MODEL="k3[1m]" \
    ANTHROPIC_DEFAULT_OPUS_MODEL="k3[1m]" \
    ANTHROPIC_DEFAULT_SONNET_MODEL="k3[1m]" \
    ANTHROPIC_DEFAULT_HAIKU_MODEL="k3[1m]" \
    CLAUDE_CODE_SUBAGENT_MODEL="k3[1m]" \
    CLAUDE_CODE_EFFORT_LEVEL=high \
    CLAUDE_CODE_AUTO_COMPACT_WINDOW=1048576 \
    CLAUDE_CODE_MAX_CONTEXT_TOKENS=1048576 \
    ANTHROPIC_API_KEY=$(get-token kimi) \
    ANTHROPIC_BASE_URL=https://api.kimi.com/coding/ \
    claude --model "k3[1m]" --dangerously-skip-permissions
}

claude-proxy() {
  local effort="${1:-high}"

  ANTHROPIC_DEFAULT_FABLE_MODEL="local[1m]" \
    ANTHROPIC_DEFAULT_OPUS_MODEL="local[1m]" \
    ANTHROPIC_DEFAULT_SONNET_MODEL="local[1m]" \
    ANTHROPIC_DEFAULT_HAIKU_MODEL="local[1m]" \
    CLAUDE_CODE_SUBAGENT_MODEL="local[1m]" \
    CLAUDE_CODE_EFFORT_LEVEL="$effort" \
    CLAUDE_CODE_AUTO_COMPACT_WINDOW=1048576 \
    CLAUDE_CODE_MAX_CONTEXT_TOKENS=1048576 \
    ANTHROPIC_API_KEY=not-used \
    ANTHROPIC_BASE_URL=http://localhost:8787 \
    claude --model "local[1m]" --dangerously-skip-permissions
}

claude-deepseek() {
  ANTHROPIC_BASE_URL=https://api.deepseek.com/anthropic \
    ANTHROPIC_AUTH_TOKEN=$(get-token deepseek) \
    ANTHROPIC_MODEL=deepseek-v4-flash \
    ANTHROPIC_DEFAULT_OPUS_MODEL=deepseek-v4-flash \
    ANTHROPIC_DEFAULT_SONNET_MODEL=deepseek-v4-flash \
    ANTHROPIC_DEFAULT_HAIKU_MODEL=deepseek-v4-flash \
    CLAUDE_CODE_SUBAGENT_MODEL=deepseek-v4-flash \
    CLAUDE_CODE_EFFORT_LEVEL=max \
    claude --model "deepseek-v4-flash" --dangerously-skip-permissions
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

claudex() {
  local effort=${1:-high}

  CLAUDE_CODE_SUBAGENT_MODEL=gpt-5.6-sol \
    CLAUDE_CODE_ALWAYS_ENABLE_EFFORT=1 \
    CLAUDE_CODE_MAX_TOOL_USE_CONCURRENCY=6 \
    ENABLE_TOOL_SEARCH=false \
    ANTHROPIC_BASE_URL=http://localhost:8317 \
    ANTHROPIC_AUTH_TOKEN=not-used \
    claude --model gpt-5.6-sol --dangerously-skip-permissions
}
