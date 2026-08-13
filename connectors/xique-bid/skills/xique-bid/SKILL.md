---
name: xique-bid
description: 在 WorkBuddy 中自动安装并使用喜鹊标书 MCP，完成标书配置、大纲生成与预览、修改大纲、确认续写、状态跟踪和 Word 导出。用户提到喜鹊、标书、投标文件、技术标、生成或修改大纲、生成正文、导出标书、xq-cli、首次安装、重新安装或再次生成时使用。明确的安装请求同时授权自动安装 MCP 和打开喜鹊浏览器登录，不要再次询问安装确认；所有生成、续写、修改和导出操作仍须遵守对应确认门禁。
---

# 喜鹊标书工作流

只使用 `xique-bid` MCP 工具执行标书业务。禁止直接运行 `xq-cli wizard`、
`xq-cli init`、`xq-cli outline`、`xq-cli write` 或 `xq-cli export`，禁止创建辅助脚本、
手动启动 MCP 服务或把日志、进程状态当作任务完成依据。

## 首次自动安装

开始业务前先检查 `xique_runtime_status` 是否可用。工具可用时不得重复安装，直接进入标准流程。

工具不可用时按以下规则处理：

1. 当前消息明确要求安装或重新安装时，立即执行完整首次安装，不得再问一次。SkillHub 的
   `请根据 https://skillhub.cn/install/skillhub.md，安装 @.../xique-bid` 属于明确授权。
2. 当前消息只是要求生成标书、没有明确要求安装时，说明 Skill 已存在但 MCP 尚未注册，只询问一次是否自动安装。
3. 未取得上述授权前，不得写入 `mcp.json`、下载 npm 包或启动登录。
4. 取得授权后，只执行下面对应平台的一次性命令。不得查找 `scripts/`，不得要求用户提供 MCP 启动命令，
   不得要求用户全局安装 `xq-cli`。

Windows 使用 WorkBuddy 自带的最新版 Node/npm：

```powershell
$workbuddyHome = if ($env:WORKBUDDY_HOME) { $env:WORKBUDDY_HOME } else { Join-Path ([Environment]::GetFolderPath('UserProfile')) '.workbuddy' }
$runtime = Get-ChildItem -LiteralPath (Join-Path $workbuddyHome 'binaries\node\versions') -Directory -ErrorAction Stop | ForEach-Object { if ($_.Name -match '^\d+\.\d+\.\d+$') { $npx = Join-Path $_.FullName 'npx.cmd'; if (Test-Path -LiteralPath $npx -PathType Leaf) { [PSCustomObject]@{ Version = [Version]$_.Name; Npx = $npx } } } } | Sort-Object Version -Descending | Select-Object -First 1
if ($null -eq $runtime) { throw '没有找到 WorkBuddy 内置 npx，请先升级 WorkBuddy。' }
$env:PATH = (Split-Path -Parent $runtime.Npx) + [IO.Path]::PathSeparator + $env:PATH
& $runtime.Npx -y '--package=@xqyz/workbuddy-plugin-xique@0.9.4' -- xique-workbuddy-install
if ($LASTEXITCODE -ne 0) { throw '喜鹊标书 MCP 自动安装失败。' }
```

macOS/Linux 使用：

```bash
workbuddy_home="${WORKBUDDY_HOME:-$HOME/.workbuddy}"
npx_path="$(find "$workbuddy_home/binaries/node/versions" -type f \( -path '*/bin/npx' -o -path '*/npx' \) | sort -V | tail -n 1)"
test -n "$npx_path" || { echo '没有找到 WorkBuddy 内置 npx，请先升级 WorkBuddy。' >&2; exit 1; }
export PATH="$(dirname "$npx_path"):$PATH"
"$npx_path" -y --package='@xqyz/workbuddy-plugin-xique@0.9.4' -- xique-workbuddy-install
```

如果用户已经在 API Key 管理页创建了 Key，推荐先在本机终端完成 CLI 登录，再安装插件：

```bash
xq-cli login --api-key xq_sk_xxx
```

也可以先设置环境变量，WorkBuddy 插件会优先读取它：

```powershell
$env:XQ_API_KEY="xq_sk_xxx"
```

```bash
export XQ_API_KEY="xq_sk_xxx"
```

API Key 不要粘贴到聊天消息中，只在本机终端或环境变量中配置。

安装器会自动完成以下工作：

- 使用 WorkBuddy 自带的 Node 20.19.0 或更高版本；
- 下载固定版本 `@xqyz/workbuddy-plugin-xique@0.9.4`，其中已包含 `@xqyz/xq-cli@0.2.1`；
- 备份并合并 `~/.workbuddy/mcp.json`，保留所有其他 MCP；
- 注册名为 `xique-bid` 的 MCP；
- 未登录时自动打开喜鹊浏览器授权页并等待最多 10 分钟；
- 已登录时复用本地登录状态，绝不在聊天中索取账号、密码、API key 或 token。

安装器成功退出只表示“自动配置已写入”，不能表示 WorkBuddy 已经信任并启动 MCP。
随后明确告知用户：打开 `专家·技能·连接器 > 连接器 > MCP 服务管理`，找到 `xique-bid`，
如出现首次连接提示则点击 `信任`，然后完全退出并重新打开 WorkBuddy。不得绕过或修改 WorkBuddy 的信任记录。

重启后再次调用 `xique_runtime_status`。只有该工具可用，并确认 Node、内置 xq-cli 和登录状态正常时，
才能报告“安装完成”。如果仍不可用，要求用户展开 MCP 服务管理中的 `xique-bid` 并提供准确错误，
不得在 `mcp.json` 已正确时反复运行安装器。

## 交互原则

1. 缺少普通配置时，必须只调用一次 `xique_bid_configuration`，在一页中展示全部配置。
2. 只在用户之后单独修改某一项时使用 `xique_select_option`。
3. 使用 `xique_outline_start`、`xique_special_project_selection`、`xique_period_confirmation`、
   `xique_outline_confirmation`、`xique_outline_update_confirmation` 和
   `xique_directory_confirmation` 展示对应阶段卡片。规划模式必须按“智能解读→大纲→目录→正文”推进，快速模式按“大纲→正文”推进。
4. 返回 `interactionMode=mcp-app` 时，WorkBuddy 会自动打开关联 MCP App。立即结束当前回复并等待用户点击；
   禁止调用 `read_me`、`show_widget`，禁止输出编号文本选项，禁止改用 `AskUserQuestion`。
5. 每张 MCP App 卡片只能提交一次。第一次提交时立即锁定，即使超时或传输结果不确定也不得恢复点击，
   应查询当前工作流状态，避免重复请求。
6. MCP App 点击生成的 `【喜鹊标书配置批量选择】`、`【喜鹊标包与EPC选择】`、
   `【喜鹊标书配置选择】` 或 `【喜鹊标书确认】` 消息属于明确的用户输入。
7. 不得给枚举选项追加 `Other` 或 `其他补充`。

## 一页配置要求

先解析源文件绝对路径，再展示普通配置页。该页一次展示：篇幅、写作、正文风格、表格数量、响应依据、
表格颜色、表格样式、图片设置、流程图样式、导出模板、导出布局、自动编号、修改标记和输出路径。

必须展示完整合法值：

- 篇幅：`极短篇（50–100页）`、`超短篇（100–200页）`、`短篇（200–350页）`、
  `中篇（350–500页）`、`中长篇（500–800页）`、`长篇（800–1200页）`、
  `超长篇（1200–1500页）`。传给 MCP 时只传括号前的名称。
- 写作：`标准`、`专家智笔`。极短篇和超短篇固定使用标准，并说明喜鹊前端也会禁用专家智笔。
- 正文风格：`增强图文`、`全表格式`、`丰富图文`、`基础配图`、`纯文字`。
- 表格：`无（不插入表格）`、`少量（约每4页1表）`、`丰富（约每2页1表）`；传给 MCP 时只传名称。
- 响应依据：`合并式响应`、`仅格式要求`、`仅评分要求`。
- 表格颜色：`黑色`、`蓝色`、`红色`、`绿色`、`紫色`、`青色`、`橙色`。
- 表格样式：`纯净版`、`表头强化`、`斑马条纹`、`全底色白框`。
- 导出模板：
  - `模板1｜章节目次（第一章→第一节→一、）`
  - `模板2｜中文层级（一、→（一）→1）`
  - `模板3｜全数字分级（1→1.1→1.1.1）`
  - `模板4｜章节+数字（第一章→1→1.1）`
  - `模板5｜自定义编号（请在喜鹊前端设置）`，保持可见但禁用。
- 导出布局：`常规`、`全表`、`精排`。
- 自动编号：`开启`、`关闭`；修改标记：`关闭`、`开启`。
- 输出路径：`默认`、`指定路径`。只有选择指定路径后才允许询问绝对路径。

WorkBuddy 标准流程必须展示 `计划模式=快速/规划`，并将用户选择原样提交；不得默认隐藏规划模式，也不得擅自替用户固定为快速。
不得展示高级样式 JSON 输入框；模板5只能在喜鹊前端可视化设置。
不得在普通配置页要求用户输入多标包 ID、标包类型或 EPC 类型。

图片设置必须展示全部选项：`我的图库`、`实拍风格图`、`PPT式插图`、`流程图`、`无配图`。
`xique_bid_configuration` 在构建一页配置时必须内部调用 `xique_gallery_status` 查询当前用户图库状态；
用户之后单独修改图片设置时，也必须先调用一次 `xique_gallery_status`，不得根据字段是否存在推断图库可用。

- 有图片时显示 `我的图库（可用，共N张）`；
- 无图片或查询失败时显示 `我的图库（暂无图片，不可选）` 并保持关闭；
- 实拍风格图同时控制 `sceneImg=1` 和 `onlineImg=1`，不得单独展示联网搜图；
- PPT式插图对应 `infoImg=1`，流程图对应 `mermaidImg=1`；
- 无配图与其他图片类型互斥；
- 选择流程图时展示 `灰色`、`紫色`、`蓝色`、`绿色`、`橙色`、`红色`。

只有用户明确说 `用默认配置`、`你自己定` 或 `随便先跑一版` 时才能采用默认配置：
短篇、标准、基础配图、丰富表格、合并式响应、蓝色、纯净版、快速、仅流程图、模板1、常规、
自动编号开启、修改标记关闭、默认输出路径。

任何问题绕过参数默认均为关闭。只有用户明确授权某一个具体例外时，才能开启对应例外，
不得把一次授权扩展到其他问题。

## 生成完整标书

1. 调用 `xique_runtime_status`，运行环境、内置 xq-cli 或登录缺失时停止并给出准确处理方法。
2. 取得源文件绝对路径。
3. 调用一次 `xique_bid_configuration`。收到批量选择消息后解析每一行，加上源文件，直接调用
   `xique_prepare_bid`，不得再次询问已选择字段。
4. 原样展示 `xique_prepare_bid` 返回的完整配置摘要，明确说明尚未开始生成。
5. 调用 `xique_outline_start(context=完整配置摘要, confirmationId=准备结果)`，展示
   `确认开始`、`返回修改`、`取消`。配置摘要之后的点击才是有效生成确认。
6. 用户点击确认后，只调用一次 `xique_generate_bid`，记录返回的 `runId`。该调用只启动解析和大纲生成，
   不得重复调用。
7. 立即调用 `xique_generation_status(runId, waitSec=60)`，状态为 `queued` 或 `running` 时持续查询同一任务。
   本地轮询窗口到期不是失败，不得创建替代任务。
8. 状态变为 `awaiting_input/special-config` 时，只调用一次
   `xique_special_project_selection(runId)`，展示后台解析出的真实标包和 EPC 选项；用户选择后调用一次
   `xique_apply_special_project_selection`，继续查询同一 `runId`，不得重新生成。
9. 状态变为 `awaiting_input/period-confirm` 时，只调用一次 `xique_period_confirmation`，展示并收集
   `periodMode`、`contractPeriod`；日期已知时再收集 `contractStartDate` 和 `contractEndDate`。随后只调用一次
   `xique_apply_period_confirmation`，继续同一 `runId`，不得重新上传或创建任务。
10. 状态变为 `awaiting_confirmation` 时，完整展示 `outlineDetail.outLine` 的每一行，包含标题、主题、
   重要性和 id。每个数组元素显示为独立编号块，并核对显示数量等于数组长度；不得只显示章节数量或摘要。
11. 调用一次 `xique_prepare_outline_continue(runId)`，把完整大纲、摘要、准确的 `runId` 和
    `confirmationId` 传给 `xique_outline_confirmation`，展示：
    `确认大纲并生成正文`、`修改大纲`、`暂不继续`。
12. 快速模式用户点击 `确认大纲并生成正文` 后，只调用一次 `xique_continue_bid`。规划模式用户点击
    `确认大纲并生成目录` 后，也只调用一次 `xique_continue_bid`；该调用只启动目录生成。
13. 规划模式目录完成后，完整展示目录树，允许通过 `xique_prepare_directory_update` / `xique_apply_directory_update`
    修改并保存；保存后调用一次 `xique_prepare_directory_continue`，再用 `xique_directory_confirmation` 展示
    `确认目录并生成正文`。用户确认后只调用一次 `xique_continue_content`。
14. 继续调用 `xique_generation_status(runId, waitSec=60)` 直到 `completed`、`failed` 或 `blocked`。
15. 只有结果同时满足 `status=completed`、`fileExists=true` 和 `savedPath` 非空时才报告成功。
    随即调用 `present_files(savedPath)`，让 Word 文件直接显示在 WorkBuddy，并提供绝对路径。
16. 后台明确返回失败或阻塞时立即报告准确原因，不得等待用户主动追问。

特殊配置不与普通配置同时选择。只有招标文件解析后确认存在多标包或 EPC 场景时，才展示后台返回的真实选项。
EPC 选项只允许 `全部编写`、`只写施工`、`只写设计`、`这不是EPC项目`，不得由用户手输或由模型虚构。

## 修改大纲

用户选择 `修改大纲` 后：

1. 询问具体修改要求，基于最新结构化大纲构造完整 `outLine` 数组。
2. 保留所有未修改章节及 id；只有用户明确要求删除时才移除现有行；新增行不带 id。
3. 调用 `xique_prepare_outline_update`，完整展示新增、修改、删除、移动、重要性变化和续写要求。
4. 调用 `xique_outline_update_confirmation`，展示 `确认保存修改`、`返回调整`、`取消`。
5. 只有点击 `确认保存修改` 后才调用 `xique_apply_outline_update`。
6. 保存后完整展示最新大纲，并明确说明：`修改已保存，但正文尚未开始，仍需确认最终大纲`。
7. 对同一个 `runId` 重新执行大纲最终确认，不得返回配置页或创建新任务。

## 再次生成与单独导出

用户说 `再跑一遍` 时，只复用最近一次由用户明确确认的配置；如果无法确定最近确认配置，则重新展示配置页。
重新准备后仍必须展示摘要并取得新的生成确认。

单独导出现有任务时，收集 `cid`、导出模板、导出布局和输出路径，调用 `xique_prepare_export`，
展示摘要并等待新的明确确认，确认后才能调用 `xique_export_bid`。

任务返回 `OUTLINE_BLOCKED` 或 `WRITE_BLOCKED` 时，保留并报告 `cid`，用中文解释问题，
只询问缺失选择或具体绕过授权，然后重新展示完整配置摘要并等待确认。

当前 WorkBuddy 任务保持打开时持续轮询并自动交付文件。WorkBuddy 被关闭、任务中断或客户端强制结束回合后，
后台任务仍可继续，但不得声称可以在应用关闭后主动推送通知；用户回来后使用原 `runId` 恢复查询。

绝不在没有非空 `savedPath` 的情况下宣称标书生成成功。
