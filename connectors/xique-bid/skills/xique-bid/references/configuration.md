# Configuration reference

## Required mappings

| 中文配置 | MCP value | xq-cli |
|---|---:|---|
| 极短篇（50–100页） | 极短篇 | `--page-scope -1` |
| 超短篇（100–200页） | 超短篇 | `--page-scope 0` |
| 短篇（200–350页） | 短篇 | `--page-scope 1` |
| 中篇（350–500页） | 中篇 | `--page-scope 2` |
| 中长篇（500–800页） | 中长篇 | `--page-scope 3` |
| 长篇（800–1200页） | 长篇 | `--page-scope 4` |
| 超长篇（1200–1500页） | 超长篇 | `--page-scope 5` |
| 标准 | 标准 | `--base 0` |
| 专家智笔 | 专家智笔 | `--base 1` |
| 增强图文 | 增强图文 | `--theme-style 1` |
| 全表格式 | 全表格式 | `--theme-style 2` |
| 丰富图文 | 丰富图文 | `--theme-style 3` |
| 基础配图 | 基础配图 | `--theme-style 4` |
| 纯文字 | 纯文字 | `--theme-style 5` |
| 表格无/少量/丰富 | 同名中文值 | `--table-quantity 0/1/2` |
| 合并式响应 | 合并式响应 | `--reference-type 0` |
| 仅格式要求 | 仅格式要求 | `--reference-type 1` |
| 仅评分要求 | 仅评分要求 | `--reference-type 2` |
| 模板1｜章节目次（第一章→第一节→一、） | 模板1 | `--template 1` |
| 模板2｜中文层级（一、→（一）→1） | 模板2 | `--template 2` |
| 模板3｜全数字分级（1→1.1→1.1.1） | 模板3 | `--template 3` |
| 模板4｜章节+数字（第一章→1→1.1） | 模板4 | `--template 4` |
| 模板5｜自定义编号（请在喜鹊前端设置） | WorkBuddy 中禁用 | 喜鹊前端可视化设置；xq-cli 底层仅保留 `--template 5 --style-json <file>` 兼容能力 |
| 常规/全表/精排 | 同名中文值 | `--layout 0/1/2` |

## Optional mappings

- 表格颜色：黑色、蓝色、红色、绿色、紫色、青色、橙色。
- 表格样式：纯净版、表头强化、斑马条纹、全底色白框。
- WorkBuddy 计划模式固定为快速（`--plan-mode 0`），不向用户展示规划模式。
- 自动编号、修改标记和图片开关：开启、关闭。
- 图片开关：我的图库=`knowledgeImg`，但仅当 `xique_gallery_status` 返回
  `available=true` 时可开启；图库为空或查询失败时仍展示该项但固定为关闭。
  实拍风格图同时控制 `sceneImg` 和 `onlineImg`；PPT式插图=`infoImg`；
  流程图=`mermaidImg`。不要单独展示联网搜图。
- 流程图样式：灰色、紫色、蓝色、绿色、橙色、红色。
- 模板5在 WorkBuddy 中只展示能力说明，不允许提交，也不显示高级样式
  JSON 输入框；用户需要在喜鹊前端通过可视化编辑器设置。

## Explicit default profile

Use this profile only after the user explicitly authorizes defaults:

- 篇幅=短篇
- 写作=标准
- 风格=基础配图
- 表格=丰富
- 响应依据=合并式响应
- 表格颜色=蓝色
- 表格样式=纯净版
- 计划模式=快速
- 图片设置=基础配图默认（仅流程图开启）
- 导出=模板1+常规
- 自动编号=开启
- 修改标记=关闭
- 输出路径=默认

## Issue bypasses

These values default to `false` and require exact user authorization:

- `ignoreShortRequirement`: ignore a short requirement section.
- `ignoreMissingBill`: continue without a bill of quantities.
- `ignoreMissingScore`: continue without scoring criteria.
- `ignoreDirectoryBasis`: continue without directory basis.

Never turn on several bypasses because the user approved only one.
