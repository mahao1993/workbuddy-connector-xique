# xique-bid WorkBuddy Connector marketplace

This directory is the team-distribution package for WorkBuddy 5.3.11 or newer.
It contains the Connector manifest, MCP launch configuration, and the same
`xique-bid` Skill shipped by the local development plugin.

The MCP runtime is distributed as `@xqyz/workbuddy-plugin-xique`. Publish the
matching version before releasing this Connector marketplace. WorkBuddy starts
it through `npx`, so customers do not need a repository-specific absolute path.
Version `0.9.0` includes `@xqyz/xq-cli@0.2.1`; customers do not install xq-cli
globally.

The bundled Skill also contains idempotent first-use installers for SkillHub
distribution. SkillHub's explicit `复制 prompt` installation request authorizes
the complete setup, so the installer runs without a redundant second
confirmation, backs up and merges `~/.workbuddy/mcp.json`, pins the same MCP npm
version, opens browser authorization when login is missing, and asks for a full
WorkBuddy restart. An ordinary non-installation request still requires one
confirmation before first-use MCP setup.

For local development before publishing, register
`workbuddy-plugin-xique/mcp/server.mjs` as a trusted custom MCP in WorkBuddy.
The custom MCP must be named `xique-bid`, and the plugin `.mcp.json` must remain
empty so the model cannot bypass the Connector proxy and lose MCP App cards.

Do not validate this integration by merely calling `tools/list`. A release is
valid only when WorkBuddy's MCP Apps catalog accepts the named stage tools
`xique_bid_configuration`, `xique_outline_start`,
`xique_special_project_selection`, `xique_outline_confirmation`, and
`xique_outline_update_confirmation`; the dedicated panel must render every
option, a click must succeed through `ui/message`, the submitted card must stay
locked when reopened, and the next named stage card must open automatically.
Template 5 must remain visible but disabled, with no advanced style JSON input.
Outline confirmation cards must carry the exact `runId` and `confirmationId`;
repeated preparation for the same unchanged outline must reuse one record, and
one user click must never create a second outline-confirmation question.
