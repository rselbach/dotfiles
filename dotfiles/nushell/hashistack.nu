def --env hashi_tokens [
  stack_name?: string  # Stack name (default: $env.HASHISTACK_NAME or "hcp-dev-iad")
  mode?: string        # Mode: export | print | quiet (default: export)
] {
  # Set defaults
  let hashistack_name = (
    $stack_name 
    | default ($env.HASHISTACK_NAME? | default "hcp-dev-iad")
  )
  let mode = ($mode | default "export")

  # Check for required commands
  if (which hcloud | is-empty) {
    error make {
      msg: "hcloud not found on PATH. Install it or update PATH."
    }
  }

  # Fetch JSON
  let json = (
    try {
      with-env { HASHISTACK_NAME: $hashistack_name } {
        hcloud hashistack tokens --format json --vault-role=identity-developer --consul-role=cloud-team --nomad-role=cloud-identity | from json
      }
    } catch {
      error make {
        msg: $"Failed to fetch tokens for ($hashistack_name)"
      }
    }
  )

  # Validate required fields
  try {
    if ($json.vault.address | is-empty) or (($json.vault.address | str length) == 0) {
      error make { msg: "Missing or empty field in JSON: vault.address" }
    }
    if ($json.vault.token | is-empty) or (($json.vault.token | str length) == 0) {
      error make { msg: "Missing or empty field in JSON: vault.token" }
    }
    if ($json.nomad.address | is-empty) or (($json.nomad.address | str length) == 0) {
      error make { msg: "Missing or empty field in JSON: nomad.address" }
    }
    if ($json.nomad.token | is-empty) or (($json.nomad.token | str length) == 0) {
      error make { msg: "Missing or empty field in JSON: nomad.token" }
    }
    if ($json.consul.address | is-empty) or (($json.consul.address | str length) == 0) {
      error make { msg: "Missing or empty field in JSON: consul.address" }
    }
    if ($json.consul.token | is-empty) or (($json.consul.token | str length) == 0) {
      error make { msg: "Missing or empty field in JSON: consul.token" }
    }
  }

  # Extract values
  let vault_addr = $json.vault.address
  let vault_token = $json.vault.token
  let nomad_addr = $json.nomad.address
  let nomad_token = $json.nomad.token
  let consul_http_addr = $json.consul.address
  let consul_http_token = $json.consul.token

  # Handle modes
  match $mode {
    "export" => {
      $env.VAULT_ADDR = $vault_addr
      $env.VAULT_TOKEN = $vault_token
      $env.NOMAD_ADDR = $nomad_addr
      $env.NOMAD_TOKEN = $nomad_token
      $env.CONSUL_HTTP_ADDR = $consul_http_addr
      $env.CONSUL_HTTP_TOKEN = $consul_http_token
    }
    "print" => {
      print $"export VAULT_ADDR='($vault_addr)'"
      print $"export VAULT_TOKEN='($vault_token)'"
      print $"export NOMAD_ADDR='($nomad_addr)'"
      print $"export NOMAD_TOKEN='($nomad_token)'"
      print $"export CONSUL_HTTP_ADDR='($consul_http_addr)'"
      print $"export CONSUL_HTTP_TOKEN='($consul_http_token)'"
    }
    "quiet" => {
      # Do nothing
    }
    _ => {
      error make {
        msg: $"Unknown mode: ($mode) \(use export|print|quiet\)"
      }
    }
  }

  # Human-readable summary to stderr (unless quiet)
  if $mode != "quiet" {
    print -e $"VAULT_ADDR       ($vault_addr)"
    print -e $"VAULT_TOKEN      ($vault_token)"
    print -e $"NOMAD_ADDR       ($nomad_addr)"
    print -e $"NOMAD_TOKEN      ($nomad_token)"
    print -e $"CONSUL_HTTP_ADDR ($consul_http_addr)"
    print -e $"CONSUL_TOKEN     ($consul_http_token)"
  }
}
