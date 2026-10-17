---
title: "【安装配置】Pi Agent 接入自建 LiteLLM 网关配置手册（OpenAI 兼容端点 + 默认模型）"
type: note
status: active
scope: Ubuntu 26.04 LTS；Pi 1.3.0（用户级 npm 安装）+ LiteLLM 网关 192.168.16.142:4000
created: 2026-10-17 15:55:00
updated: 2026-10-17 15:55:00
summary: "把 Pi 编码 Agent 指向自建 LiteLLM 网关：通过 ~/.pi/agent/models.json 注册 openai-completions 兼容端点与模型，并设置默认模型；含 5 项实测验证与 tool calling 验证结果。"
keywords: [linux, ai_agent, pi, litellm, gateway, models.json, openai-completions, install]
verification: "pi --list-models deepseek 列出 litellm 提供方；pi -p 默认模型返回正常；pi auth check --provider litellm → status=ready"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的
> [!NOTE]
> 本机已按 [Pi 编码 Agent CLI 安装、配置与使用手册](20261017-pi-coding-agent-install-usage-guide.md) 装好 Pi v1.3.0，但默认走官方模型目录（`/login` 或各提供方环境变量）。本次要把 Pi 接到**内网自建的 LiteLLM 网关**（`http://192.168.16.142:4000/v1`），使模型调用不出内网，并把 `huangza-openai-deepseek-flash` 设为默认模型。

## ⚙️ 核心内容

### 1. 目标拓扑

```text
Pi CLI (本机)  ──OpenAI Chat Completions──▶  LiteLLM 网关 192.168.16.142:4000/v1
                                                    │
                                                    └──▶ 上游模型（由网关侧路由决定）
```

网关能力实测：

| 探测项 | 结果 |
|--------|------|
| `GET /v1/models`（带 `Authorization: Bearer <key>`） | HTTP 200，耗时 0.03s |
| `GET /v1/models`（不带鉴权头） | HTTP 401 → **强制鉴权** |
| 模型清单 | 共 12 个：`huangza-openai-{qwen,kimi,glm-5.2,glm-5,MiniMax,deepseek-flash}` 与 `huangza-cc-{同名 6 个}` |
| 目标模型是否在列 | `huangza-openai-deepseek-flash` ✓ |

### 2. 配置方式选型（为什么不用写扩展）

Pi 官方 `custom-provider.md` 给出的决策表明确：**「若服务已经说 Pi 支持的 API，就配置 `models.json`」**。LiteLLM 网关暴露的就是 OpenAI Chat Completions 协议，因此：

| 方案 | 是否采用 | 理由 |
|------|----------|------|
| `~/.pi/agent/models.json` 注册兼容端点 | ✅ 采用 | 零代码；`api: openai-completions` 直接复用 Pi 内置的请求转换、工具调用、用量统计 |
| 编写 provider 扩展（`pi.registerProvider`） | ❌ 不采用 | 仅在需要自定义认证流、动态模型发现或非标准协议时才需要 |

### 3. 配置文件一：注册网关与模型

**文件路径**：`~/.pi/agent/models.json`（Pi 的 agent 目录，用户级、与工程无关）

```json
{
  "$schema": "https://pi.dev/schemas/models.schema.json",
  "providers": {
    "litellm": {
      "name": "LiteLLM 网关 (192.168.16.142:4000)",
      "baseUrl": "http://192.168.16.142:4000/v1",
      "api": "openai-completions",
      "apiKey": "<网关 API Key>",
      "models": [
        {
          "id": "huangza-openai-deepseek-flash",
          "name": "huangza-openai-deepseek-flash",
          "input": ["text", "image"],
          "contextWindow": 128000,
          "maxTokens": 16384,
          "cost": { "input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0 }
        }
      ]
    }
  }
}
```

字段要点（依据官方 `models-configuration.md`）：

| 字段 | 说明 |
|------|------|
| `providers.<id>` | 非内置 provider ID 需同时给 `baseUrl` 与 `api`；本文用 `litellm`，与 OpenCode 侧配置保持一致 |
| `api` | `openai-completions` 表示走 OpenAI Chat Completions 协议 |
| `apiKey` | 支持字面值、`$NAME` / `${NAME}` 环境变量插值、`!command` 命令取值 |
| `input` | 声明的输入模态，Pi 会据此在 `/model` 与图片附件处理中展示 |
| `contextWindow` / `maxTokens` | 上下文窗口与最大输出；未声明时默认 128000 / 16384 |
| `cost` | 计费元数据，四项均为必填；内网网关按 0 记录（仅影响 Pi 的费用显示，不影响调用） |

> [!WARNING]
> 上述 `apiKey` 为**明文凭据**。本手册刻意使用占位符而不写真实值，原因是本仓库同时配置了 `gitee`、`github` 两个**公网远端**（`AGENTS.md` 亦明确要求不得把凭据类内容推送到公网）。真实值仅存在于本机 `~/.pi/agent/models.json`，该文件不在仓库内，权限已收紧为 `600`。
> 若希望连明文也不落地，可改为环境变量插值：
> ```json
> { "apiKey": "${LITELLM_GATEWAY_KEY}" }
> ```
> 注意环境变量必须存在于**启动 Pi 的那个进程**中（写进 `~/.bashrc`/`~/.profile` 后需新开终端），因此本机当前采用字面值方案。

### 4. 配置文件二：设为默认模型

**文件路径**：`~/.pi/agent/settings.json`（在保留原有键值的基础上合并写入）

```json
{
  "lastChangelogVersion": "1.3.0",
  "defaultProvider": "litellm",
  "defaultModel": "huangza-openai-deepseek-flash"
}
```

- `defaultProvider`：启动时的默认 provider
- `defaultModel`：启动时的默认模型 ID（**只写模型 ID，不带 provider 前缀**）

### 5. 权限收紧

```bash
chmod 600 ~/.pi/agent/models.json ~/.pi/agent/settings.json
```

实测结果：两份文件均为 `-rw-------`，且 `~/.pi/agent` 目录本身为 `700`。

### 6. 验证清单（5 项，全部实测通过）

```bash
# ① JSON 语法
jq -e . ~/.pi/agent/models.json && jq -e . ~/.pi/agent/settings.json

# ② Pi 是否识别模型
pi --list-models deepseek
```

实测输出：

```text
provider  model                          context  max-out  thinking  images
litellm   huangza-openai-deepseek-flash  128K     16.4K    no        yes
```

```bash
# ③ 默认模型端到端推理（不传 --model，即验证 settings.json 生效）
pi -p "只回复这六个字：网关连接成功"
#   → 网关连接成功   （退出码 0）

# ④ 显式指定 provider/model
pi -p --model litellm/huangza-openai-deepseek-flash "…"
#   → 正常返回，退出码 0

# ⑤ 工具调用能力（bash + read，验证网关对 function calling 的支持）
pi -p "用 bash 工具统计当前目录文件数，并用 read 工具读出 sample.txt 的内容，最后一行回复 DONE"
#   → 正确统计文件数、正确读出文件内容、输出 DONE（退出码 0）

# ⑥ 凭据解析状态
pi auth check --provider litellm --json
#   → {"status":"ready","provider":"litellm","authType":"api_key"}
```

> [!NOTE]
> 凭据解析顺序（官方 models.md）：运行时 `--api-key` → `auth.json` → `models.json` 的 `apiKey` → provider 环境变量。因此**无需**执行 `/login`；`~/.pi/agent/auth.json` 当前仍为 `{}`，凭据来自 `models.json`。
> 另：网关模型清单里 `thinking` 列为 `no`（本模型未声明推理能力）；如需思考级别，可在模型条目中加 `"reasoning": true` 并按提供方要求配置 `thinkingLevelMap`。

### 7. 追加网关上的其它模型

网关共有 12 个可用模型。如需把 `huangza-openai-*` 整族都接进来，只需扩展 `models` 数组（同 provider 内多条目）：

```json
"models": [
  { "id": "huangza-openai-deepseek-flash", "name": "DeepSeek Flash", "input": ["text"] },
  { "id": "huangza-openai-qwen",           "name": "Qwen",           "input": ["text"] },
  { "id": "huangza-openai-kimi",           "name": "Kimi",           "input": ["text"] },
  { "id": "huangza-openai-glm-5.2",        "name": "GLM 5.2",        "input": ["text"] },
  { "id": "huangza-openai-glm-5",          "name": "GLM 5",          "input": ["text"] },
  { "id": "huangza-openai-MiniMax",        "name": "MiniMax",        "input": ["text"] }
]
```

配置本身的公共字段沿用 provider 级 `baseUrl` / `api` / `apiKey` / `cost`（模型级未声明的字段会取默认值）。追加后在 Pi 内用 `/model` 搜索切换，或用 `Ctrl+P` 循环（可用 `settings.json` 的 `enabledModels` 限定循环范围）。

### 8. 与 OpenCode 侧配置的对照

同一网关在两套工具里的写法映射：

| 概念 | OpenCode（`opencode.json`） | Pi（`~/.pi/agent/models.json`） |
|------|------------------------------|----------------------------------|
| 网关地址 | `provider.litellm.options.baseURL` | `providers.litellm.baseUrl` |
| 凭据 | `provider.litellm.options.apiKey` | `providers.litellm.apiKey` |
| 协议适配 | `"npm": "@ai-sdk/openai-compatible"` | `"api": "openai-completions"` |
| 模型声明 | `provider.litellm.models.<id>` | `providers.litellm.models[]` 数组 |
| 输入模态 | `modalities.input` | 模型级 `input` |
| 默认模型 | 顶层 `"model": "litellm/<id>"` | `settings.json` 的 `defaultProvider` + `defaultModel` |

## 🔍 常见排错

| 现象 | 原因与处理 |
|------|-----------|
| `pi --list-models` 看不到该模型 | 官方说明：模型即使写在 `models.json`，**凭据不可解析时也不会出现在 `/model`**。核对 `apiKey` 是否为字面值或环境变量确实存在（`pi auth check --provider litellm` 应为 `ready`） |
| 请求返回 401/403 | 网关强制 Bearer 鉴权（实测无鉴权头即 401）。确认 `apiKey` 正确；本机 `authHeader` 未显式设置亦可正常工作（Pi 对 `openai-completions` 会带上 `Authorization: Bearer`） |
| 模型自述与其名称不一致 | 本次实测中该模型自称另一家上游模型，属网关侧路由/别名行为，不代表配置错误；对内网网关而言，以网关侧配置为准 |
| 上下文被截断或报超长 | 按上游真实能力调整模型级 `contextWindow` 与 `maxTokens` |
| 换了终端后失效 | 若改用 `${VAR}` 插值，变量必须在启动 Pi 的进程中存在（新开终端或 `source ~/.profile`） |

**关联文档**
- [Pi 编码 Agent CLI 安装、配置与使用手册](20261017-pi-coding-agent-install-usage-guide.md)
- [AionUi Linux 部署与使用手册](20261017-aionui-linux-deploy-guide.md)（可把 Pi 作为外部 CLI Agent 接入）
- [direnv 目录级环境变量管理](../devops_shell/20261017-direnv-env-management.md)（如需按目录注入网关环境变量）