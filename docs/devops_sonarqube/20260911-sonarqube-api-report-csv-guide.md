---
title: "【安装配置】SonarQube 静态代码问题 API 报告生成脚本（CSV 输出）使用指南"
type: note
status: active
scope: devops_sonarqube
created: 2026-09-11 10:00:00
updated: 2026-09-11 16:30:00
summary: "通过 SonarQube 官方 Web API 拉取项目代码质量问题，一键导出 CSV 报告，覆盖问题等级、类型、所在文件、行号、问题描述、源代码片段、规则与修复建议、状态、修复工时等关键信息，仅依赖 Python 标准库。"
keywords: [sonarqube, api, csv, report, static-analysis, python, devops]
verification: "python3 scripts/sonarqube/sonarqube_report.py --help"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> 部门 SonarQube 平台已按上述部署手册上线，扫描脚本可自动上报 Node.js/Java/C++ 等工程的质量问题。
> 但日常审计、里程碑复盘、质量门禁时需要把"存量问题清单"导出成可交付/可入库的 CSV 报告。
> 本文档总结 `scripts/sonarqube/sonarqube_report.py` 的用法：通过 SonarQube Web API
> 分页拉取问题并生成结构化 CSV（中文表头，10 列），提取关键字段：**问题ID、类型、
> 质量维度、影响等级、项目、所在代码文件、行号、规则名称、修复建议、解决状态** 等。

## ⚙️ 核心内容

### 1. 脚本概览

- **脚本位置**: `scripts/sonarqube/sonarqube_report.py`
- **运行要求**: Python 3.6+，**零第三方依赖**（仅标准库 `urllib`/`csv` 等）
- **API 端点**:
  - `/api/authentication/validate` — 连通性与认证校验
  - `/api/issues/search` — 分页拉取问题（支持筛选项）
  - `/api/rules/search` — 逐 key 拉取规则名称与描述（修复建议）

### 2. 基础用法

```bash
python3 scripts/sonarqube/sonarqube_report.py \
    -U http://<sonar-server>:9000 \
    -T <SONAR_TOKEN> \
    -P <项目key> \
    -o sonarqube_report.csv
```

> 令牌获取：SonarQube 登录后 `My Account → Security → Generate`。
> 亦支持环境变量 `SONAR_URL` / `SONAR_TOKEN`，或用户名/密码认证：
> `python3 ... -u admin -pwd <password> -P <项目key>`。

### 3. 高级用法示例

```bash
# 只看 BLOCKER/CRITICAL 的 Bug 与漏洞，指定分支，输出到指定路径
python3 scripts/sonarqube/sonarqube_report.py \
    -U http://sonar.example.com:9000 -T <token> -P my-project \
    -B release/1.2.0 \
    --severities BLOCKER,CRITICAL --types BUG,VULNERABILITY \
    -o blocker_critical.csv

# 从本地代码目录读取源码片段(比远端源码接口快)，加大上下文行数
python3 scripts/sonarqube/sonarqube_report.py \
    -U http://sonar.example.com:9000 -T <token> -P my-project \
    --local-src /data/code/my-project --snippet-lines 5

# 只拉问题清单，不要源码片段与规则描述(最快，适合 CI 定时审计)
python3 scripts/sonarqube/sonarqube_report.py \
    -U http://sonar.example.com:9000 -T <token> -P my-project \
    --no-snippet --no-rules -o quick_report.csv
```

### 4. 参数说明

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `-U/--url` | 环境变量 `SONAR_URL` | SonarQube 服务器地址 |
| `-T/--token` | 环境变量 `SONAR_TOKEN` | 访问令牌（与用户名二选一） |
| `-u/--username`、`-pwd/--password` | 空 | 用户名/密码认证（与令牌二选一） |
| `-P/--project` | 必填 | 项目 key |
| `-B/--branch` | 空 | 分支过滤，空为全部分支 |
| `--severities` | 空 | 严重级别：`BLOCKER,CRITICAL,MAJOR,MINOR,INFO` |
| `--types` | 空 | 类型：`BUG,VULNERABILITY,CODE_SMELL,SECURITY_HOTSPOT` |
| `--statuses` | 空 | 状态：`OPEN,CONFIRMED,REOPENED` |
| `--max-issues` | 10000 | 最多拉取条数上限 |
| `-o/--output` | `sonarqube_report.csv` | CSV 输出路径 |
| `--local-src` | 空 | 本地代码根目录（存在则优先读本地源码） |
| `--no-snippet` | 关 | 不输出源代码片段（加速） |
| `--no-rules` | 关 | 不拉取规则描述/修复建议（加速） |
| `--snippet-lines` | 3 | 源代码片段问题行上下各取多少行 |
| `--timeout` | 30 | HTTP 请求超时秒数 |

### 5. 与批量扫描脚本集成（batch-release-scan.sh）

`scripts/sonarqube/batch-release-scan.sh` 已内置本报告脚本的批处理：

- 每个 release 分支**扫描成功后立即**调用本脚本导出该分支的 CSV 报告。
- 输出目录默认 `<脚本目录>/reports/<type>/`，文件名格式：
  `sas_report_<项目名>_<分支名>.csv`（项目名取 `SONAR_PROJECT_NAME`，分支名中的 `/` 转为 `_`）。
- 报告相关选项：
  - `--no-report`：关闭自动导出（默认开启）
  - `--report-dir DIR`：自定义输出目录
  - `--report-url URL`：报告用 SonarQube 地址（默认取 `.env` 的 `SONAR_HOST_URL`）
  - `--report-wait SECONDS`：扫描成功后等待 N 秒再导出（等后台分析完成）
  - `--report-args "ARGS"`：透传额外参数给本脚本

```bash
./batch-release-scan.sh -t nodejs --report-wait 10 /data/projects/web-portal
# 输出示例: scripts/sonarqube/reports/nodejs/sas_report_vrnet-cloud-web_release1.2.0.csv
```

### 5. CSV 字段说明

> CSV 表头为中文（英文列名仅用于脚本内部逻辑），按以下顺序固定 10 列：

| CSV 表头（中文） | 内部列名 | 说明 |
|------|------|------|
| 问题ID | `issue_key` | 问题唯一标识 |
| 问题类型 | `type` | BUG / VULNERABILITY / CODE_SMELL / SECURITY_HOTSPOT |
| 质量维度 | `impact_quality` | SonarQube 10.x+ 质量维度（如 MAINTAINABILITY / RELIABILITY / SECURITY） |
| 影响等级 | `impact_severity` | 影响程度：HIGH / MEDIUM / LOW（10.x 起替代旧 severity） |
| 项目 | `project` | 所属项目 key |
| 文件路径 | `file` | 问题所在代码文件相对路径 |
| 行号 | `line` | 问题所在行号 |
| 规则名称 | `rule_name` | 触发问题的规则名称 |
| 修复建议 | `rule_desc` | 取自规则描述（新版取 `how_to_fix` 小节） |
| 解决状态 | `resolution` | 解决情况：FIXED / WONTFIX / FALSE-POSITIVE 等，空为未解决 |

### 6. 输出示例

| 问题类型 | 质量维度 | 影响等级 | 文件路径 | 行号 | 规则名称 |
|----------|----------|----------|----------|------|----------|
| BUG | RELIABILITY | HIGH | src/main/java/Demo.java | 42 | "Null pointers should not be dereferenced" |

CSV 表头为中文，如：

```text
问题ID,问题类型,质量维度,影响等级,项目,文件路径,行号,规则名称,修复建议,解决状态
```

## 🛠️ 脚本（Scripts）需求说明

- 可执行权限已设置（`chmod +x`）；`-h/--help` 输出完整中文帮助。
- 仅标准库实现，任何机器无需 `pip install` 即可运行。
- 5xx/网络异常自动重试；参数/权限 4xx 明确报错并返回非零退出码（便于 CI 判断）。

## ⚠️ 注意事项与踩坑记录

1. **SonarQube 10.x 影响等级**：10.0 起官方逐步以 `impacts`（质量维度×影响程度）替代旧 `severity`，
   CSV 输出 `质量维度`/`影响等级` 两列；旧版服务器该两列可能为空，可放心兼容 7.x~10.x。
2. **规则接口版本差异**：新版 SonarQube 规则 `/api/rules/search` 的筛选参数改用单数 `rule_key`
   （复数 `rule_keys` 会被静默忽略返回全量），且规则描述由 `htmlDesc` 改为 `descriptionSections`
   （`root_cause`/`how_to_fix` 小节）。脚本已自动兼容：逐 key 查询 + 参数名自动兜底 + 描述分节提取。
3. **大量问题优化**：工程问题上万条时建议先用 `--severities/--types` 收紧范围，并配合
   `--no-rules` 提速（跳过规则拉取，`修复建议` 列留空）。
4. **分页上限**：`--max-issues` 为安全上限，默认 10000，超过时终止分页并给出告警。
5. **CSV 编码**：输出使用 `utf-8-sig`，Excel 直接打开中文表头不乱码；字段内换行已自动转义。

## 📎 参考

- SonarQube Web API 文档：https://docs.sonarsource.com/sonarqube/latest/extension-guide/web-api/
- 配套扫描手册：`../软件部署/sonarcube/README.md` 与 `scripts/sonarqube/batch-release-scan.sh`