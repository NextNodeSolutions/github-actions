# Dokploy API Quirks

## Server Update Requires ALL Fields (CRITICAL)

The Dokploy `server.update` TRPC endpoint uses **PUT semantics**, not PATCH.

**Every request MUST include all 8 fields:**
| Field | Type | Notes |
|-------|------|-------|
| `serverId` | string | Server UUID |
| `name` | string | Server display name |
| `description` | string | Can be empty `""`, but MUST be present |
| `ipAddress` | string | Server IP address |
| `port` | int | SSH port (default: 22) |
| `username` | string | SSH user (default: "root") |
| `sshKeyId` | string \| null | SSH key UUID |
| `serverType` | "deploy" \| "build" | Server role |

**Missing ANY field -> HTTP 400 Bad Request**

This is enforced by the `apiUpdateServer` schema in Dokploy source:
`packages/server/src/db/schema/server.ts` (lines 162-176)

## Pattern: Always Pass existing_server

When calling `update_server()`, always pass the full existing server object:

```python
existing = client.get_server_by_name("my-server")
client.update_server(
    server_id=existing["serverId"],
    existing_server=existing,  # REQUIRED - contains all current values
    ip_address=new_ip,  # Override only what changed
)
```

Never construct partial payloads manually.
