# Coworker MCP kit install prompt

Copy everything below into Codex or Claude on a coworker Mac/PC.

---

You are installing our company **read-only MCP kit** for agents.

## Systems in scope
{{systems_list}}

## Install these MCP servers (in order)
### Official
{{official_mcp_steps}}

### Community
{{community_mcp_steps}}

### Custom (from shared folder `mcp-servers/`)
{{custom_mcp_steps}}

## Config snippets
Paste into Claude Desktop / Codex MCP config:
```json
{{mcp_config_json}}
```

## Secrets
Ask IT/sponsor for: {{secret_names}}  
Do **not** commit secrets. Use Keychain/env.

## Smoke test
{{smoke_commands}}

## Rules
- Read-only only
- If smoke fails, stop and report — do not invent workarounds that write data
