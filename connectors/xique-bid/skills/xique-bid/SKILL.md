---
name: xique-bid
description: Generate, inspect, review, modify, continue, or export Xique bid-book tasks through the xique-bid MCP tools. Use when users mention 标书、投标文件、技术标、生成大纲、查看或修改大纲、确认大纲、生成正文、导出标书、xq-cli, or ask to rerun an earlier bid task. Enforce explicit Chinese configuration collection, pause after outline generation, and require post-summary confirmation before every mutating generation, outline update, body continuation, or export action.
---

# Xique bid workflow

Use the `xique-bid` MCP tools. Do not invoke `xq-cli wizard` and do not bypass
the MCP confirmation gate with direct shell commands.

The MCP tools are the only authority for generation and status. Never create a
helper script, start another MCP server process, invoke `xq-cli` directly, or
use a log file/process list as proof that a task is still running or complete.

When generation configuration is missing, you MUST use
`xique_bid_configuration` once to collect all ordinary enumerated configuration
in one page. Use `xique_select_option` individual fields only when the user
later returns to edit one specific setting. Use the named stage tools
`xique_outline_start`, `xique_special_project_selection`,
`xique_outline_confirmation`, and `xique_outline_update_confirmation` for their
respective steps so WorkBuddy shows meaningful card names.
It either completes through a native MCP form or returns
`interactionMode=mcp-app` and WorkBuddy automatically renders the linked
standard MCP App. Both interfaces show every supported value,
including fields with more than four choices, and do not append
`Other`/`其他补充`. Never use `AskUserQuestion` and never replace the MCP App with
a numbered text list.

When `interactionMode=mcp-app` is returned, do not call `read_me` or
`show_widget`. The stage tool metadata links the UI resource,
and WorkBuddy opens it automatically in a dedicated configuration panel. End
the turn immediately and wait for the user's click. The MCP App submits the
click through standard `ui/message` as a new user message beginning with
`【喜鹊标书配置批量选择】`, `【喜鹊标包与EPC选择】`,
`【喜鹊标书配置选择】`, or
`【喜鹊标书确认】`; treat that message as explicit user input and continue with
only the next missing field.

Every MCP App card is single-submit. Its first submission attempt immediately
locks the card, including while WorkBuddy is processing, after a transport
error, and when the card is reopened. Never ask the user to choose a second
option or click an earlier card again; query the current step instead.
Server-side continuation tools are idempotent and must reuse the same `runId`.

## Mandatory rules

1. Never choose generation configuration silently.
2. Resolve the source file first, then collect all common generation settings
   in the single `bidConfig` page. Parse every line from the returned
   `【喜鹊标书配置批量选择】` message and do not ask those fields again.
3. Always collect 响应依据 before execution because WorkBuddy MCP calls are
   non-TTY and cannot answer an interactive response-basis prompt.
4. The ordinary configuration page includes 表格颜色、表格样式、图片开关 and
   流程图样式. It MUST NOT ask users to invent multi-bid IDs, multi-bid types,
   EPC values, or advanced style JSON. WorkBuddy always uses `计划模式=快速`; never ask a planning-mode
   question and never silently accept `规划`. The tool queries gallery status
   while building the page with the same current-user check as
   `xique_gallery_status`, and keeps “我的图库” visible but disabled when empty.
5. Only fill the default profile when the user explicitly says `用默认配置`,
   `你自己定`, or `随便先跑一版`.
6. Never enable an issue-bypass option unless the user explicitly authorizes
   that exact exception.
7. Preparing configuration is allowed before confirmation. Generating or
   exporting is not.
8. Call `xique_generate_bid` exactly once for one confirmed configuration. It
   performs init and outline generation only, then pauses. Record its `runId`.
9. Poll `xique_generation_status(runId, waitSec=60)` until it returns
   `awaiting_input`, `awaiting_confirmation`, `failed`, or `blocked`. Do not wait for `completed`
   before reviewing the outline because body generation has not started yet.
   A local polling-window expiration is not a generation failure: it remains
   `running/outline-waiting` and must continue polling the same `runId` while
   the connector reconciles the authoritative backend outline state. Never
   create a replacement run for this condition.
10. At `awaiting_input/special-config`, call
    `xique_special_project_selection(runId)` once. It displays only the actual
    `multiBiddingList` and EPC choices returned by file parsing. After the
    click, call `xique_apply_special_project_selection` once with the same
    `runId`, then resume status polling. A repeated identical call is only a
    status-safe no-op; never call `xique_generate_bid`, init, or prepare a new
    run for this stage.
11. At `awaiting_confirmation`, display every chapter, theme, importance, and
    id from `outlineDetail.outLine`; never reduce it to a chapter count. Render
    exactly one numbered block per array row and verify the rendered block
    count equals `outlineDetail.outLine.length`. Never merge an id into the
    previous chapter or omit middle chapters.
12. Call `xique_prepare_outline_continue` once before asking the user whether
    to continue. Repeated preparation for the same run and unchanged outline
    must reuse the same confirmation ID. Show the complete outline and returned
    continue summary through `xique_outline_confirmation(context=...,
    runId=..., confirmationId=...)` with
    `确认大纲并生成正文`、`修改大纲`、`暂不继续`.
13. For an outline modification, construct the complete updated `outLine`
    array. Preserve every unchanged chapter and its id. Omit an existing row
    only when the user explicitly asks to delete it. Call
    `xique_prepare_outline_update`, display every returned diff item, and wait
    for `确认保存修改` before `xique_apply_outline_update`. Then show the complete
    updated outline, state that正文尚未开始, and immediately return to rule 11
    using the same `runId`. Use `xique_outline_update_confirmation` for the
    save decision. Never describe a saved outline as already confirmed.
    Prefer the complete outline text returned by the MCP tool verbatim instead
    of reconstructing or summarizing it.
14. After final confirmation, call `xique_continue_bid` exactly once with the
    `runId` and confirmation ID carried by the clicked card. The server may
    safely recover from a stale ID by consuming the current matching record
    only when the run is unchanged and the outline signature still matches;
    never open a second confirmation card for that click. Continue polling the
    same `runId` until `completed`, `failed`, or `blocked`.
15. When the terminal result has `status=completed`, a non-empty `savedPath`,
    and `fileExists=true`, call WorkBuddy's `present_files` with that exact path,
    then tell the user that generation, download, and export are complete. If
    `present_files` is unavailable or fails, provide the clickable absolute path.
16. Show every supported ordinary value directly in the single configuration page; do
    not hide values behind range, category, `更多`, or follow-up navigation
    choices. The Xique standard flow MUST NOT use `AskUserQuestion` for enum
    fields, because its four-option cap truncates valid choices and its
    automatic `Other`/`其他补充` entry cannot be disabled by a Skill.
17. The visible label of every 篇幅 option MUST include its page range exactly
    as returned by `xique_choices`. Never shorten a card to only `极短篇`、
    `超短篇`、`短篇`、`中篇`、`中长篇`、`长篇` or `超长篇`.
18. The visible label of every 导出模板 option MUST include its numbering style
   example exactly as returned by `xique_choices`. Never show only `模板1` to
   `模板5`. Show 模板5 as disabled with `请在喜鹊前端设置`; do not display or
   request advanced style JSON in WorkBuddy.
19. Never infer that “我的图库” is available merely because the field exists.
    Query it for the current logged-in user. If the result is unavailable or
    the query fails, show `我的图库（暂无图片，不可选）`, keep
    `knowledgeImg=0`, and tell the user to upload in the Xique frontend. If the
    user says they have uploaded images, query again before enabling it.
20. Treat every confirmation ID as belonging to one action and one run. Always
    pass the exact `runId` and `confirmationId` emitted by the clicked card to
    `xique_continue_bid`. If the model accidentally supplies an older ID, let
    the server verify the current run and outline and consume the matching live
    record from the same click. Do not ask the user to confirm a second time.
    Never call `xique_prepare_bid` or `xique_generate_bid` as recovery.
21. When the user says `继续`、`开始生成正文` or an equivalent phrase after an
    outline has been shown or modified, resume the active outline-review run.
    Do not interpret it as a new bid-generation request. A new run is allowed
    only when the user explicitly asks to regenerate/restart from the source.

Read [configuration.md](references/configuration.md) when mapping labels,
defaults, optional fields, or issue-bypass options.
Read [interactive-configuration.md](references/interactive-configuration.md)
whenever any generation or export setting is missing.

## Generate a complete bid

1. Call `xique_runtime_status`.
2. If Node, CLI, or login is unavailable, stop and give the exact remediation.
3. Resolve an attached source file to an absolute local path. Ask for the path
   if WorkBuddy cannot see one.
4. Call `xique_bid_configuration` once, following
   `interactive-configuration.md`. Preserve settings already supplied by the
   user. If it returns `interactionMode=mcp-app`, end the turn and wait for the
   automatically rendered selection UI. Do not call `read_me`, `show_widget`,
   `xique_choices`, print a numbered fallback, or ask the user to type the
   configuration. If WorkBuddy does not render the linked MCP App resource,
   stop and report the exact WorkBuddy compatibility problem instead of
   degrading the experience.

   The single-page tool queries the current gallery state internally. When the
   click-generated `【喜鹊标书配置批量选择】` message arrives, map every line,
   add the resolved source file, and call `xique_prepare_bid` without repeating
   any field. Use an individual selection field only for a later targeted edit.

5. Call `xique_prepare_bid` with the complete settings.
6. Show the returned final configuration summary verbatim. State that no
   generation has started.
7. Use `xique_outline_start(context=完整配置摘要,
   confirmationId=xique_prepare_bid返回值)` for
   post-summary confirmation with `确认开始`、`返回修改` and `取消`. The selection
   is an explicit user confirmation after the summary.
8. For a returned MCP App, end the turn and wait for its click. The resulting
   `【喜鹊标书确认】生成确认=确认开始` click message is the post-summary explicit
   confirmation. A confirmation phrase sent before the summary does not count.
   After confirmation, call
   `xique_generate_bid` once with the stored confirmation ID and the user's
   latest confirmation text.
9. Record the returned `runId` and state briefly that source parsing and outline
   generation have started. Do not call `xique_generate_bid` again.
10. Immediately call `xique_generation_status` with that `runId` and
    `waitSec=60`. Continue while the status is `queued` or `running`.
11. If status becomes `awaiting_input/special-config`, call
    `xique_special_project_selection(runId)` once. After the user selects the
    actual parsed options, call `xique_apply_special_project_selection` once
    with that same `runId`, `multiBidId` and/or `epcEngineerType`, then continue
    polling. Never call `xique_generate_bid` again.
12. When status becomes `awaiting_confirmation`, show the complete
    `outlineDetail.outLine`, including every title and theme. State explicitly
    that body generation has not started.
13. Call `xique_prepare_outline_continue(runId)` once and pass its returned
    complete outline and summary as `context`, plus its exact `runId` and
    `confirmationId`, to `xique_outline_confirmation`:
    - `确认大纲并生成正文`
    - `修改大纲`
    - `暂不继续`
14. If the user chooses `修改大纲`, ask what to change. Build a complete updated
    array from the latest structured outline:
    - preserve unchanged rows and ids;
    - change `text`, `theme`, or `important` only as requested;
    - reorder the full array to move chapters;
    - add a row without an id;
    - remove a row only for an explicit deletion request.
15. Call `xique_prepare_outline_update`. Show all additions, edits, deletions,
    moves, importance changes, and sequel requests from the returned diff. Use
    `xique_outline_update_confirmation(context=完整差异摘要, runId=...,
    confirmationId=xique_prepare_outline_update返回值)`
    for `确认保存修改 / 返回调整 / 取消`. Call `xique_apply_outline_update` only after
    `确认保存修改`, then show the complete saved outline, explicitly say
    `修改已保存，但正文尚未开始，仍需确认最终大纲`, and repeat step 12 with a
    newly prepared continue confirmation for the same `runId`.
16. If the user chooses `确认大纲并生成正文`, call `xique_continue_bid` exactly
    once using the `runId` and confirmation ID embedded in that clicked card.
    Never reopen the same question merely because another historical
    confirmation ID was missing, expired, or already used.
17. Resume `xique_generation_status(runId, waitSec=60)` polling. If platform
    content is complete but export is pending, continue waiting. Never start a
    replacement generation or a second export.
18. Report success only when the authoritative result has `status=completed`,
    `fileExists=true`, and a non-empty `savedPath`. Call
    `present_files(savedPath)` so the Word file appears directly in WorkBuddy,
    then include the absolute path in the final message.
19. If the run becomes an authoritative backend `failed` or `blocked`, stop
    polling and report the exact message automatically; do not wait for a user
    status query. `running/outline-waiting` is recoverable and is not terminal.

If an outline-continue call receives a stale confirmation ID, pass the card's
`runId` to `xique_continue_bid`. The server must verify that the run remains at
`awaiting_confirmation/outline-review`, verify the unchanged outline signature,
and consume the matching live record. Do not reopen the confirmation card or
ask the user to click twice for one outline decision.

If `xique_generation_status` reports that the platform content is complete but
the run is still exporting, say exactly that. Do not say the whole task is
unfinished, and do not start a replacement task.

Automatic delivery depends on the current WorkBuddy task remaining active. If
WorkBuddy is closed, the session is interrupted, or the client enforces a hard
turn timeout, the durable run continues and a later status request can recover
it. Do not claim an out-of-band push notification after the app or task closes.

## Rerun

When the user says `再跑一遍`:

- reuse only the last configuration that the user explicitly confirmed;
- never reuse an agent-assumed configuration;
- call `xique_prepare_bid` again;
- show the new summary and wait for a new post-summary confirmation;
- ask for configuration again if the last confirmed configuration is unclear.

## Export an existing task

1. Collect `cid`, 导出模板、导出布局 and 输出路径.
2. Call `xique_prepare_export`.
3. Show the returned summary and wait for a new explicit confirmation.
4. Call `xique_export_bid` only after that confirmation.

## Blocked workflows

If generation returns `OUTLINE_BLOCKED` or `WRITE_BLOCKED`:

1. Preserve and report the returned `cid`.
2. Explain the issue in Chinese.
3. Ask only for the missing choice or explicit bypass authorization.
4. Prepare a new complete configuration summary.
5. Wait for confirmation again before retrying.

Never claim success unless a non-empty `savedPath` is returned.
Never create `bid-generate.mjs`, `check-status.mjs`, or an equivalent workaround.
