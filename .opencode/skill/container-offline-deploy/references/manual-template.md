# 部署手册模板与索引刷新规范

本文件供 `container-offline-deploy` 技能在“阶段 4：沉淀运维手册”时参考。目标机器或部署环境不同时，
只需替换模板中的变量，不要改变结构。

## 一、落盘位置

先确定**领域** `<domain>`，再决定路径。`<domain>` 取"面向事务的领域_组件"命名，应贴合服务本身：

- 密码/安全类服务 → `security_<service>`（如 `security_vaultwarden`）
- 通用容器/中间件部署 → `devops_docker`
- 数据库、存储、Web、邮件等 → `db_<service>` / `storage_<service>` / `web_<service>` / `mail_<service>`

若仓库已有同领域的既有文档目录，**优先复用**（例如仓库已有 `docs/security_vaultwarden/`，新文档就放同目录）。
落盘路径以仓库当前实际约定为准，本仓库为扁平的两级结构：

```
docs/<domain>/<YYYYMMDD>-<service>-docker-offline-deploy.md
```

- `<domain>`：如 `security_vaultwarden`、`devops_docker`
- `<service>`：服务名（小写，连字符）
- 日期用当天日期，格式 `YYYYMMDD`

> 兼容旧结构：若目标仓库仍使用 `docs/<domain>/<os>_<env>/` 三级结构，则沿用三级结构，
> 文件头的 `scope` 相应写成 `<domain>/<os>_<env>`。

## 二、标准文件头（必须逐项填写）

```markdown
---
title: "【安装配置】<服务> 容器化离线部署指南（Docker Compose + 离线镜像）"
type: note
status: active
scope: <domain>
created: <YYYY-MM-DD HH:MM:SS>
updated: <YYYY-MM-DD HH:MM:SS>
summary: "<一句话：在联网机制作 <服务> 离线 bundle（docker-compose + .env + 镜像 tar + 部署脚本），离线机 docker load 后 compose 启动，端口 <port>，数据持久化到 <dir>"
keywords: [linux, docker, docker-compose, offline, <service>, <env>]
verification: "<验证命令，如：cd <bundle> && ./deploy.sh ps && curl -s -o /dev/null -w '%{http_code}' http://localhost:<port>/"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---
```

## 三、正文结构

```markdown
## 📌 背景与目的
> [!NOTE]
> <为什么需要离线部署，本次目标服务与约束>

## ⚙️ 核心内容
### 1. 环境准备
<表格：操作系统 / Docker / compose / 内存 / 端口 / 数据目录 / 离线机架构>

### 2. 离线 bundle 制作（联网机）
<export.sh 用法、平台参数、产物清单>

### 3. 离线部署（目标机）
<目录结构表格、deploy.sh 用法、compose 与 .env 关键内容>

### 4. 环境变量说明
<变量表格>

### 5. 验证
<命令 + 预期输出>

### 6. 访问与日常管理
<访问地址表格 + up/down/logs 等命令>

## 🔧 排障记录
<本次实际踩到的坑与解法；没有则写“暂无”>

## 📎 参考
<镜像来源、官方文档、bundle 路径>
```

所有代码块必须标注语言类型（```bash / ```yaml / ```ini / ```markdown）。

## 四、刷新总索引 `docs/README.md`

索引可能有两种形态，先读文件再决定怎么改：

- **扁平分组**：`- **<domain>**` 直接列表；
- **分类分组**：顶层有 `### <emoji> <分类>（<prefix>_*）` 小节，其下再列 `- **<domain>**`。

步骤：

1. 打开 `docs/README.md`，先定位已有的 `- **<domain>**` 分组（如 `- **security_vaultwarden**`）。
2. 在该分组下按现有格式追加一行（缩进两空格）：

```markdown
  - [<标题>](<domain>/<文件名>.md)（含离线 bundle `<bundle 路径>`）
```

3. 若该 `- **<domain>**` 分组不存在：
   - 分类式索引：找到匹配的分类小节（如 `### 🔐 安全（security_*）`）并在其下新增分组；分类小节也不存在时才新建小节；
   - 扁平式索引：直接新增 `- **<domain>**` 分组。
4. 保持其他分组、分类小节与行序不变，只做最小改动；不要重排、不要改动他人条目。
5. 若 bundle 落在仓库的“外部部署目录”（如本仓库的 `软件部署/<service>/`），可在索引底部的
   `## 软件部署手册（外部目录）` 小节同法追加一条指向该 bundle 的 `README.md`。