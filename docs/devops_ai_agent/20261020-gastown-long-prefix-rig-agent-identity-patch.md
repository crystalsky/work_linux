---
title: "【故障变更】Gas Town 长前缀 rig 的 Agent 身份识别修复：polecat identity 落库重定向与 gt 源码补丁重编译"
type: note
status: active
scope: gt 1.2.1 + bd 1.0.0 用户级安装环境（Ubuntu 26.04 LTS，免 sudo）
created: 2026-10-20 17:45:00
updated: 2026-10-20 17:45:00
summary: "定位并修复「gt polecat identity add 成功但 gt polecat identity list 永远为空」这一故障：根因一是 bd 1.0.0 不执行 routes.jsonl 路由，导致 identity bead 误落 town 的 hq 库；根因二是 gt 解析 agent ID 时把 rig 前缀长度硬编码为 2~3 字符。对应三项修补（bd wrapper 落库重定向、gt 源码放宽前缀长度并重编译、离线包携带修补版二进制），含完整操作说明、验证记录与回滚方法。"
keywords: [linux, ubuntu, ai_agent, gastown, gt, beads, bd, dolt, patch, polecat, identity, prefix, routes, multi-agent, offline]
verification: "gt polecat identity list collab_rig 输出 3 identity bead(s)（dev1/dev2/qa）；collab_rig 库 bd list 可见 3 条 polecat bead 且 hq 库无残留；gt doctor 无 failed；离线包安装后 ~/.local/bin/gt 大小为 38199561 字节（修补版）"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的
> [!NOTE]
> 在 Gas Town 中编排「多 AI 角色协作」（产品经理 1 人 + 开发 2 人 + 测试 1 人）时，需要先用 `gt polecat identity add <rig> <name>` 为每个具名 polecat 建立**身份 bead**，再用 `gt sling <bead> <rig>/polecats/<name>` 精确派活。
> 实测发现：`identity add` 每次执行都报成功，但 `gt polecat identity list` **永远返回空**，导致无法向具名角色派活，协作编排第一步即被卡死。
> 本文记录该故障的完整定位过程、两处相互独立的上游设计缺陷、三项修补措施（其中一项需要重新编译 gt）、可复现的操作步骤与回滚方法。

---

## 🔍 问题现象

三条命令依次执行，全部「成功」，但结果自相矛盾：

```bash
$ cd ~/work_luli/gt_work/gt_ai
$ gt polecat identity add collab_rig dev1 --role polecat
✓ Created identity bead: collab-collab_rig-polecat-dev1

$ gt polecat identity list collab_rig
No polecat identities found in collab_rig.        # ← 刚刚创建的身份无法列出

$ gt sling task-001 collab_rig/polecats/dev1
Error: polecat "dev1" not found in rig collab_rig  # ← 派活失败
```

补充证据（用记录型探针替换 `~/.local/bin/bd`，抓取 gt 实际下发的调用）显示：`identity add` 与 `identity list` 使用的 **`BEADS_DIR` 不是同一个目录**。

| 操作 | gt 下发的 `BEADS_DIR` | 实际读写的库 |
|------|----------------------|--------------|
| `gt polecat identity add` | `<town>/.beads`（town 库） | `hq` |
| `gt polecat identity list` | `<town>/collab_rig/.beads`（rig 库） | `collab_rig` |

结论：**写入与读取分别落在两个不同的 Dolt 库**，因此列表恒为空。两者都「成功」，因为各自在自己的库里都是合法操作。

---

## 🧭 根因分析

### 1. 上游设计：agent bead 走 town 库，再由 routes 路由分发

阅读 gt 1.2.1 源码可见，其设计**有意**在 town 库创建 agent bead（`internal/beads/beads_agent.go:282` `CreateOrReopenAgentBead`），并有专门的上游测试用例为其背书：

```go
// internal/beads/beads_agent_test.go:466
func TestCreateOrReopenAgentBeadExistingUsesTownBeadsDir(t *testing.T) {
    ...
    // 路由表把 hq- 前缀留在 town，把 gt- 前缀指向具体 rig
    WriteRoutes(townBeadsDir, []Route{{Prefix: "hq-", Path: "."}, {Prefix: "gt-", Path: "gastown/mayor/rig"}})
```

也就是说，上游期望的链路是：

```text
gt polecat identity add（在 town 库发起）
        ↓
bd create --id=collab-... --force
        ↓  ← 期望 bd 读取 <town>/.beads/routes.jsonl
        ↓    把 collab- 前缀的 bead 物理落到 collab_rig 库
collab_rig 库
        ↑
gt polecat identity list（在 rig 库读取）—— 两侧一致，列表正常
```

本机的路由表**确实是正确生成的**：

```bash
$ cat <town>/.beads/routes.jsonl
{"prefix":"hq-","path":"."}
{"prefix":"hq-cv-","path":"."}
{"prefix":"collab-","path":"collab_rig"}
```

### 2. 根因一：bd 1.0.0 不执行 routes 路由，identity bead 误落 town 库

决定性验证——在 town 库直接创建 `collab-` 前缀的 bead：

```bash
$ cd <town> && bd create "routing probe" --id=collab-routingprobe-1 --type=task
Error: prefix mismatch: database uses 'hq-' (allowed: hq,hq-cv) but ID 'collab-routingprobe-1'
doesn't match any allowed prefix (use --force to override)
```

关键点：

- 报错里给出的白名单 `allowed: hq,hq-cv` **来自 `<town>/.beads/metadata.json` 的 `prefix` 字段，而不是 `routes.jsonl`**；说明 bd 根本没有读取路由表；
- 正因为如此，gt 侧必须加 `--force` 才能把 bead 造出来（源码中确实传了 `--force`），而 `--force` 只是绕过了前缀校验，**并不会把 bead 搬到 rig 库**——
  于是 6 条 identity bead 全部留在 `hq` 库，rig 库空空如也。

> [!NOTE]
> 本机 bd 固定为 1.0.0（必须与 gt 1.2.1 内嵌 beads 版本同代，见部署手册）。更高版本 bd（1.3.1）虽可能支持 routes，但会触发 `schema migration: pending schema migrations alter pre-existing dirty tables`，与 gt 1.2.1 的库结构不兼容，因此**不能**用「升级 bd」来绕过本问题。

### 3. 根因二：gt 解析 agent ID 时把前缀长度硬编码为 2~3 字符

即使把 bead 放进了正确的库，身份**仍然列不出来**。阅读 `internal/beads/agent_ids.go`：

```go
// 打补丁前（gt 1.2.1 原始代码，约 373 行）
func ParseAgentBeadID(id string) (rig, role, name string, ok bool) {
    // Find the prefix (everything before the first hyphen)
    // Valid prefixes are 2-3 characters (e.g., "gt", "bd", "hq")
    hyphenIdx := strings.Index(id, "-")
    if hyphenIdx < 2 || hyphenIdx > 3 {
        return "", "", "", false
    }
    ...
```

而其「写」侧函数 `AgentBeadIDWithPrefix` **不限制前缀长度**：

```text
id = "<prefix>-<rig>-polecat-<name>"
      └── 6 字符 "collab" ──┘
```

- 写：`collab-collab_rig-polecat-dev1`（前缀 `collab` = 6 字符，正常写入）
- 读：`hyphenIdx = 6 > 3` → 直接 `ok=false` → 被 `identity list` 的过滤器全部丢弃

即 **add 与 list 对「前缀长度」的假设不一致**。上游同时存在两处约束矛盾：`gt rig add --prefix` 不限制前缀长度，`ParseAgentBeadID` 却假定前缀只有 2~3 个字符（`gt` / `bd` / `hq`）。

### 4. 两处根因的关系

| # | 缺陷位置 | 现象 | 后果 |
|---|---------|------|------|
| 一 | bd 1.0.0 不读 `routes.jsonl` | identity bead 落错库 | rig 库查无此人 |
| 二 | gt `ParseAgentBeadID` 前缀上限 3 | 长前缀 ID 解析失败 | 即便库对了也过滤掉 |

**两者互相独立**：实测表明只修其一时 `identity list` 仍为空，必须同时修补才能恢复功能。这正是本方案需要「wrapper 补丁 + 重新编译 gt」两件事一起做的原因。

---

## 🛠️ 修补方案

### 补丁 A：bd wrapper 剥离 `BEADS_DOLT_DATA_DIR`（既有，回顾）

**必要性**：bd 1.0.0 在环境变量存在 `BEADS_DOLT_DATA_DIR` 时会**忽略** `BEADS_DIR/metadata.json` 里的 `dolt_database`，从而连到错误的库（多 rig 场景下表现为 `gt show` / `gt sling` 报 bead not found）。gt 已通过 `BEADS_DOLT_SERVER_HOST/PORT` 提供连接信息，因此剥离该变量是安全的。

### 补丁 B：`polecat identity create` 的落库重定向（新增）

**必要性**：绕开根因一。既然 bd 1.0.0 不会依据 `routes.jsonl` 自动路由，就在 wrapper 层**手工补上这次路由**：当调用是 `bd create` 且 `--id` 形如 `<任意前缀>-<rig>-polecat-<名字>` 时，把 `BEADS_DIR` 从 town 库改写为该 rig 的库。

**设计约束**（保证低风险）：

- 仅在子命令为 `create` 时介入，其他子命令完全不碰；
- 仅当 ID 中确实命中 `-<rig>-polecat-` 且该 rig 目录下存在 `.beads` 时才改写；
- rig 名从 `<town>/rigs.json` 所在根目录下的一级子目录动态枚举，不写死任何 rig 名。

### 补丁 C：gt 源码放宽前缀长度上限并重新编译（新增）

**必要性**：修复根因二。上游写侧不限制前缀长度、读侧限制 2~3，属于明显的前后不一致；且无法通过配置规避（gt 无相关开关），只能改代码。

**改动内容**：把 `hyphenIdx > 3` 放宽为 `hyphenIdx > 32`，**保留 `hyphenIdx < 2` 的下界**。

**为什么上限取 32**：

| 取值思路 | 评价 |
|---------|------|
| 保持 3，要求用户改用短前缀 | 需重建已注册 rig 与全部 bead，破坏面大；且 `--prefix` 本身无此限制，属上游疏漏 |
| 放宽到 32 | 覆盖一切现实可行的 rig 前缀，同时仍能拒绝 `hyphenIdx` 异常的畸形 ID（如下界 2 依然在） |
| 完全取消长度校验 | 会退化 ID 校验强度，不利于后续排障 |

**风险与影响面评估**：

- 对既有的 2~3 字符前缀（`gt` / `hq` / `bd`），`hyphenIdx <= 3 <= 32` 恒成立，**行为与官方二进制完全一致**；
- 放宽的只是「上限」这一条拒绝路径，不改变任何匹配/解析逻辑；
- 补丁 B 只影响 `create` 且命中 polecat 命名约定的调用，正常业务 bead 不受影响。

---

## ⚙️ 操作说明

> [!IMPORTANT]
> 以下步骤中的「替换 `~/.local/bin/gt`」「重建离线包」属于对已安装环境的写操作，执行前请先确认已有备份（下面第 1、3 步均含备份动作）。

### 1. 应用 bd wrapper 补丁（补丁 A + B）

**先备份**：

```bash
cp -a ~/.local/bin/bd ~/.local/bin/bd.bak-$(date +%Y%m%d-%H%M%S)
```

**写入新的 wrapper**（完整内容如下，三处补丁均在其中）：

```bash
#!/usr/bin/env bash
# Gas Town / Beads launcher
#   1) 为 bd 注入私有 ICU 74 运行库路径（不改动系统库）
#   2) 兼容性补丁 A：bd 1.0.0 在存在 BEADS_DOLT_DATA_DIR 时会忽略
#      BEADS_DIR/metadata.json 中的 dolt_database，连到错误的库。
#   3) 兼容性补丁 B：gt 的 `gt polecat identity add` 会把 BEADS_DIR 固定为
#      <town>/.beads，使 identity bead 误落 town 库；而 `gt polecat identity
#      list` 读取 <town>/<rig>/.beads，导致列表永远为空。此处在 create
#      调用上按 --id 中的 rig 名把 BEADS_DIR 重定向回 rig 库。
set -euo pipefail

ICU_LIB_DIR="${HOME}/.local/icu74/usr/lib/x86_64-linux-gnu"
if [ -d "$ICU_LIB_DIR" ]; then
  export LD_LIBRARY_PATH="$ICU_LIB_DIR${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"
fi

# ---- 补丁 B：polecat identity create 的库重定向 ----
if [ -n "${BEADS_DIR:-}" ] && [ "${1:-}" = "create" ]; then
  _bd_town_root="$(dirname "${BEADS_DIR%/}")"
  if [ -f "${_bd_town_root}/rigs.json" ]; then
    _bd_id=""
    for _bd_arg in "$@"; do
      case "$_bd_arg" in
        --id=*) _bd_id="${_bd_arg#--id=}" ;;
      esac
    done
    if [ -n "$_bd_id" ]; then
      for _bd_rig_dir in "${_bd_town_root}"/*/; do
        _bd_rig="$(basename "${_bd_rig_dir}")"
        case "$_bd_id" in
          *-"${_bd_rig}"-polecat-*)
            if [ -d "${_bd_rig_dir%/}/.beads" ]; then
              export BEADS_DIR="${_bd_rig_dir%/}/.beads"
            fi
            ;;
        esac
      done
    fi
  fi
fi

# ---- 补丁 A：BEADS_DIR 已确定时剥离 BEADS_DOLT_DATA_DIR ----
if [ -n "${BEADS_DIR:-}" ]; then
  unset BEADS_DOLT_DATA_DIR
fi

exec "${HOME}/.local/libexec/gastown/bd-1.0.0" "$@"
```

```bash
chmod +x ~/.local/bin/bd
```

> [!NOTE]
> 使用本仓库的离线安装脚本时**无需手工执行本步**：`scripts/devops/gastown_install_offline.sh` 生成的 wrapper 已内含补丁 A 与 B。

### 2. 构建修补版 gt（补丁 C，需要有外网 + Go 工具链）

仓库提供了一键构建脚本，它会自动应用补丁文件并编译：

```bash
cd ~/work_luli/work_linux
scripts/devops/gastown_build_patched_gt.sh --download-src
```

- 补丁文件：`scripts/devops/patches/gt-1.2.1-agent-id-prefix-length.patch`
- 产物：`~/.work_linux_working/artifacts/gt-1.2.1-patched`（约 37 MB）
- 源码缓存：`~/.work_linux_working/downloads/src/gtsrc/github.com/steveyegge/gastown@v1.2.1`
- 脚本可重复执行（幂等）：检测到源码已含补丁标记即跳过打补丁

补丁本体：

```diff
--- a/internal/beads/agent_ids.go
+++ b/internal/beads/agent_ids.go
@@ -373,7 +373,13 @@
 	// Find the prefix (everything before the first hyphen)
 	// Valid prefixes are 2-3 characters (e.g., "gt", "bd", "hq")
 	hyphenIdx := strings.Index(id, "-")
-	if hyphenIdx < 2 || hyphenIdx > 3 {
+	// LOCAL PATCH: upstream hardcodes the agent-ID prefix length to 2-3 chars
+	// (gt/bd/hq), but `gt rig add --prefix` does not enforce any length limit.
+	// The mismatch makes agent beads of long-prefix rigs unparseable, so a rig
+	// like `gt rig add collab_rig --prefix collab` can create polecat identity
+	// beads that `gt polecat identity list` can never display. Relax the upper
+	// bound while keeping the "prefix has at least 2 chars" lower bound.
+	if hyphenIdx < 2 || hyphenIdx > 32 {
 		return "", "", "", false
 	}
```

### 3. 安装修补版 gt

```bash
# 备份官方二进制
cp -a ~/.local/bin/gt ~/.local/bin/gt.bak-$(date +%Y%m%d-%H%M%S)

# 安装修补版
install -m 0755 ~/.work_linux_working/artifacts/gt-1.2.1-patched ~/.local/bin/gt

# 校验（修补版无 (dev) 后缀，大小约 38 MB）
~/.local/bin/gt --version
```

安装后需重启长驻服务，使 witness / refinery 等子进程使用新的二进制：

```bash
cd <town> && gt down && gt up && gt status
```

### 4. 重建离线包（使离线机器也拿到修补版）

```bash
cd ~/work_luli/work_linux
scripts/devops/gastown_offline_bundle.sh
```

打包脚本会自动把 `~/.work_linux_working/artifacts/gt-1.2.1-patched` 收进 `payload/gt-1.2.1-patched`；若该文件不存在，则打印警告并只打出官方 gt（离线机器将无法使用长前缀 rig 的 identity 功能）。

安装脚本 `gastown_install_offline.sh` 检测到 payload 中存在 `gt-*-patched` 时，会在安装官方 gt 之后就地覆盖为修补版。

### 5. 验证

```bash
cd <town>
gt polecat identity list collab_rig
gt polecat identity show collab_rig dev1
```

---

## ✅ 实测验证记录

**（1）修补前**（仅补丁 A 生效）：

```bash
$ gt polecat identity list collab_rig
No polecat identities found in collab_rig.
```

**（2）修补后——补丁 B + C 同时生效**：

```bash
$ gt polecat identity list collab_rig
3 identity bead(s)

$ gt polecat identity show collab_rig dev1
（正常输出 dev1 的身份字段：role_type/rig/agent_state 等）
```

**（3）落库正确性**：rig 库 `collab_rig` 中存在 3 条 identity bead，`hq` 库无残留（此前误写入 `hq` 的 6 条已清除）。

**（4）服务重启后全链路**：

```bash
$ gt status
Mayor          hq-mayor            pi / huangza-openai-deepseek-flash    running
Deacon         hq-deacon           pi / huangza-openai-deepseek-flash    running
Witness        collab-witness      pi / huangza-openai-deepseek-flash    running
Refinery       collab-refinery     pi / huangza-openai-deepseek-flash    running
Dolt                            :3308                                  running
```

**（5）离线包安装验证**（干净假 HOME，`--skip-go`）：

```text
payload 中已打入修补版 gt: gt-1.2.1-patched
~/.local/bin/gt  大小 38199561 字节（37 MB，修补版）
~/.local/bin/bd  wrapper 中补丁 B 命中 2 处
bd version 1.0.0 (72170267)
dolt version 2.5.0
```

离线包：`~/.work_linux_working/artifacts/gastown-offline-1.2.1.tar.gz`（180 MB，含修补版 gt）。

---

## 🔁 回滚

三项修补各自独立可回滚，且都不触碰系统级目录：

```bash
# 回滚 wrapper（补丁 A + B）
cp -a ~/.local/bin/bd.bak-<时间戳> ~/.local/bin/bd

# 回滚 gt（补丁 C）
cp -a ~/.local/bin/gt.bak-<时间戳> ~/.local/bin/gt

# 回滚后重启服务
cd <town> && gt down && gt up
```

回滚的后果：长前缀 rig 的 `gt polecat identity list` 恢复为「恒为空」，即回到修补前的状态；已落在 rig 库中的 bead 数据**不会**因回滚而丢失（旧二进制只是解析不出它们）。

---

## 📎 相关文件与产物

| 类别 | 路径 | 说明 |
|------|------|------|
| 脚本 | `scripts/devops/gastown_build_patched_gt.sh` | 打补丁 + 编译修补版 gt（幂等，支持 `--download-src` / `--no-build`） |
| 补丁 | `scripts/devops/patches/gt-1.2.1-agent-id-prefix-length.patch` | gt 源码补丁（unified diff） |
| 脚本 | `scripts/devops/gastown_install_offline.sh` | wrapper 已含补丁 A + B；自动安装 payload 中的修补版 gt |
| 脚本 | `scripts/devops/gastown_offline_bundle.sh` | 自动把修补版 gt 收进离线包 payload |
| 产物 | `~/.work_linux_working/artifacts/gt-1.2.1-patched` | 修补版 gt 二进制（约 37 MB） |
| 产物 | `~/.work_linux_working/artifacts/gastown-offline-1.2.1.tar.gz` | 离线包（180 MB，含修补版 gt） |
| 源码 | `~/.work_linux_working/downloads/src/gtsrc/github.com/steveyegge/gastown@v1.2.1` | 打了补丁的源码树 |
| 备份 | `~/.local/bin/{bd,gt}.bak-<时间戳>` | 修补前的原始二进制 |

---

## 📝 变更记录

| 日期 | 变更 |
|------|------|
| 2026-10-20 | 首次成文：确认双根因，落地补丁 A/B/C，重编译 gt，离线包升级至含修补版 |