---
name: container-offline-deploy
description: 当用户要求部署容器化服务（Docker / docker-compose）、把服务做成"离线/内网/无网"部署包、导出或导入 Docker 镜像（docker save / docker load）、生成 docker-compose.yaml 与 .env、或在没有外网的机器上跑起容器服务时使用本技能。技能默认遵循"先本地部署测试、用户确认后再打包"的秩序：先拉镜像在本机起服务、做端口可达测试、交用户手动试用，用户确认后才导出离线镜像并生成标准 bundle（docker-compose.yaml、.env / .env.example、images/*.tar、export.sh、deploy.sh、README.md），默认打包目录为家目录下的 _docker-packages/服务名（即 /home/登录用户/_docker-packages/服务名），并按 AGENTS.md 生成部署手册、刷新 docs/README.md 索引。只要用户提到"部署容器/服务""离线部署""内网部署""无网机器装服务""镜像离线包""docker save/load""打包容器""compose 部署"等，即使没明说"离线"，也应使用本技能。
---

# container-offline-deploy —— 容器化服务「本地部署测试 → 离线打包」技能

## 这个技能解决什么问题

把容器化服务落地为**可分发到无外网机器的离线包**，并把「先跑通、再打包」作为默认秩序：

| 阶段 | 在哪台机器 | 做什么 | 关键产物 |
|------|-----------|--------|----------|
| A. 本地部署测试 | 有网/本机 | 拉镜像、起服务、端口可达测试、交用户试用 | 运行中的容器、`docker-compose.yaml`、`.env` |
| B. 打包（用户确认后） | 同一台机器 | `docker save` 导出镜像、补齐离线脚本与文档 | `images/*.tar`、`export.sh`、`deploy.sh`、`README.md` |
| C. 离线部署 | 目标离线机 | 导入镜像、启动、验证 | 运行中的容器 |

三条核心原则：

1. **先测后包**：镜像必须先在本地成功部署、端口可达、并经**用户实际试用确认**后，才进行打包。不要在未验证的情况下直接产出离线包。
2. **离线自包含**：目标机不需要联网、不需要登录镜像仓库、不需要本技能目录——拷整个 `<package>/` 目录过去，`./deploy.sh` 就能起来。
3. **默认打包目录**：用户不指定时，输出到 `/home/<user>/_docker-packages/<package>`（`<user>` 取当前登录用户）。

## 触发时机

满足任一条件即使用本技能：

- 用户要求部署某个容器化服务（`nginx`、`redis`、`n8n`、`wordpress`、`minio`、`vaultwarden` 等）；
- 用户提到"离线部署""内网部署""没有外网的服务器上装""做成离线包""打包这个服务"；
- 用户要求导出/导入镜像（`docker save` / `docker load`）用于搬运；
- 用户要求生成 `docker-compose.yaml` 与 `.env` 并落地部署；
- 用户提到"镜像离线文件""离线安装包""compose 部署到内网"。

## 工作流程

### 阶段 0：识别环境

先做只读探测，不要凭空假设：

```bash
whoami; echo "$HOME"                       # 决定默认打包目录里的 <user>
cat /etc/os-release | grep -E '^PRETTY_NAME|^ID|^VERSION_ID'
uname -m                                   # 本机架构
docker version --format '{{.Server.Version}}' 2>/dev/null || echo "无 docker"
docker compose version 2>/dev/null || docker-compose version 2>/dev/null   # 用于选择命令
docker ps >/dev/null 2>&1 && echo "docker 可用(免sudo)" || echo "docker 需要 sudo"
df -h / | tail -1                          # 磁盘余量（镜像 tar 很占空间）
```

用结果决定：用 `docker compose` 还是 `docker-compose`、是否要 `--platform`、数据目录是否可写。

### 阶段 1：收集需求（缺项主动问，不要瞎猜）

用 `question` 工具或直接提问，逐项确认：

1. **服务名** `<package>`（小写、连字符，决定目录名与文档名）。
2. **镜像** `<repo:tag>`，一个或多个（多容器服务逐个数清）。尽量钉死版本，不要用 `latest`。
3. **离线机 CPU 架构**：与本机不同时打包要用 `--platform linux/arm64`（或 `linux/amd64`）。
4. **端口映射**：`HOST_PORT:CONTAINER_PORT`。
5. **数据持久化目录**：目标机上的绝对路径（本地测试若不可写，可临时用工作目录下的 `./data` 覆盖）。
6. **环境变量**：密码、时区、初始化参数等（密码只进 `.env`，不进 compose）。
7. **目标环境**：用于手册归档（`<domain>`，如 `security_vaultwarden`、`devops_docker`）。
8. **打包输出目录**：默认 `/home/<user>/_docker-packages/<package>`（`<user>` = `whoami`）；用户可指定。

> 对服务不熟时，先确认官方推荐的镜像、端口、必需环境变量与数据目录，再动手。

### 阶段 2：本地部署并测试（先跑通）

**工作目录就用打包输出目录**（默认 `/home/<user>/_docker-packages/<package>`），这样测试通过后原地打包，不搬来搬去。

1. 建目录并写编排文件；从技能拷贝脚本：

```bash
PKG=/home/$(whoami)/_docker-packages/<package>
mkdir -p "$PKG/images"
cp <skill>/scripts/deploy_offline.sh "$PKG/deploy.sh"
cp <skill>/scripts/export_images.sh "$PKG/export.sh"
chmod +x "$PKG/deploy.sh" "$PKG/export.sh"
# 按 assets/docker-compose.template.yaml 写 docker-compose.yaml + .env
```

2. 拉取镜像（若本地已有会跳过/回退）：

```bash
docker pull <repo:tag>
# 跨架构测试：docker pull --platform linux/arm64 <repo:tag>
```

3. 起服务（此时还没有 `images/manifest.txt`，`deploy.sh` 会跳过导入，直接用已拉取的镜像启动）：

```bash
cd "$PKG" && ./deploy.sh up
```

4. **端口可达测试**（必做，不是只看容器 `Up`）：

```bash
ss -lntp | grep ":<HOST_PORT>"                                   # 端口在监听
curl -sS -o /dev/null -w 'HTTP %{http_code}\n' http://localhost:<HOST_PORT>/   # 纯 HTTP 服务
curl -k -s -o /dev/null -w 'HTTPS %{http_code}\n' https://localhost/           # 走 HTTPS 反代的服务
./deploy.sh logs                                                  # 日志无报错
```

5. 若起不来：看日志定位（端口冲突改 `.env` 的 `HOST_PORT`；目录权限 `mkdir -p`；依赖缺失等），修好后重测。

> **人工检查点（关键）**：把访问地址、默认账号/初始口令（如有）、验证方式整理给用户，请其**手动登录/试用**。
> 在用户明确回复"测试通过 / 可以打包"之前，**不要进入阶段 3**。不要替用户判定通过。

### 阶段 3：确认后打包（用户提出打包时）

只有用户确认测试通过并提出打包时，才执行；打包即"导出镜像 + 补齐离线件"：

```bash
cd "$PKG"
./export.sh . --platform linux/amd64     # 或目标离线机架构；产物 images/*.tar + images/manifest.txt
```

- 补齐 `images.txt`（镜像清单）、`.env.example`（占位符）、`README.md`（离线部署说明）。
- 核对每个镜像都有 tar：

```bash
ls -lh images/ && cat images/manifest.txt
```

- 若目标机架构与本机不同，务必用 `--platform` 重新导出。

### 阶段 4：离线部署（目标机）

把整个 `<package>/` 目录原样拷到离线机器：

```bash
cd <package>
sudo mkdir -p <数据目录>          # 数据目录需可写
./deploy.sh                       # 导入镜像 + compose up -d + 显示状态
./deploy.sh logs
```

若 `docker load` 报架构不匹配，回到阶段 3 用正确 `--platform` 重新导出。

### 阶段 5：沉淀手册 + 刷新索引

按技能 `references/manual-template.md` 生成手册。**领域 `<domain>` 要贴合服务本身**（如
密码/安全类用 `security_<service>`，不要把一切都塞进 `devops_docker`），并优先复用仓库已有的同领域目录：

```
docs/<domain>/<YYYYMMDD>-<package>-docker-offline-deploy.md
```

必须逐项填写标准文件头（title/type/status/scope/created/updated/summary/keywords/verification/ai_rules），
正文代码块标注语言类型。然后**只做最小改动**地在 `docs/README.md` 的 `- **<domain>**` 分组下追加一行索引
（索引可能是分类式，见模板），不要重排既有条目。详细格式见 `references/manual-template.md`。

## 服务需要 HTTPS 时（反代前置）

有些服务（如 Vaultwarden/Bitwarden、部分平台）**官方客户端强制 HTTPS**，纯 HTTP 无法登录；
也有服务出于安全必须 TLS。遇到这类需求时，不要只跑单服务，而要在 bundle 里加一个 **TLS 终结反代**：

- 用 **Caddy + `tls internal`**（完全离线、自动生成本地 CA）：把 `assets/Caddyfile.template` 拷成
  bundle 的 `Caddyfile`，站点地址写 `{$DOMAIN}, localhost`，`reverse_proxy <应用服务名>:80`。
- **应用服务只 `expose: ["80"]`，不发布宿主机端口**；由 Caddy 发布 `${HTTP_PORT}:80` / `${HTTPS_PORT}:443`。
- `caddy-data/` 挂载到 Caddy 的 `/data`，持久化内部 CA（换机/重建后证书与客户端信任才稳定）。
- 应用的环境变量要写**带 scheme 的对外地址**（如 Vaultwarden 的 `DOMAIN: https://${DOMAIN}`）。
- 端口测试走 HTTPS：`curl -k -s -o /dev/null -w '%{http_code}' https://localhost/`。
- `images.txt` 加入反代镜像（如 `caddy:2-alpine`）。
- **手册与 README 必须写清客户端信任根证书**：
  `docker cp <caddy容器>:/data/caddy/pki/authorities/local/root.crt` 后导入各客户端系统/浏览器信任库。

> 原因：自签/内部 CA 的证书默认不被客户端信任，不导入根证书，浏览器和 App 仍会拒绝连接——
> 这一步不写清楚，离线部署会"起了但用不了"。

## 打包目录结构（交付物）

```text
/home/<user>/_docker-packages/<package>/     # 默认打包目录
├── docker-compose.yaml
├── .env
├── .env.example
├── images.txt
├── images/
│   ├── <safe_name>.tar
│   └── manifest.txt
├── export.sh
├── deploy.sh
├── README.md
├── Caddyfile              # 可选：需要 HTTPS 时的反代配置
└── caddy-data/            # 可选：Caddy 内部 CA（持久化）
```

## 脚本说明

- `scripts/deploy_offline.sh`（本机测试 / 离线机通用）：自动探测 `docker compose` / `docker-compose`，
  有 `images/manifest.txt` 时先导入镜像，再 `up -d`；支持 `down` / `ps` / `logs` / `load`。
  本地测试阶段没有 manifest，会跳过导入、直接用已拉取的镜像启动。
- `scripts/export_images.sh`（打包）：解析 `images.txt` / compose，`docker pull` 并 `docker save` 为
  `images/*.tar` + `manifest.txt`，支持 `--platform`、`--compress`、`--no-pull`、
  `--mirrors`、`--no-mirror`。拉取失败时先用镜像站前缀重试、再回退本地同镜像（见下节）。

## 拉取不到镜像时：镜像站前缀回退

国内/内网直连 Docker Hub 常失败。`export.sh` 内置了**镜像站回退**：官方地址拉取失败后，
依次用镜像站前缀重试，成功后 `docker tag` **改回官方名**，保证 compose 与离线机引用的仍是官方镜像名：

```bash
# 脚本自动做的事（等价于）:
docker pull docker.m.daocloud.io/vaultwarden/server:latest
docker tag  docker.m.daocloud.io/vaultwarden/server:latest vaultwarden/server:latest
docker rmi  docker.m.daocloud.io/vaultwarden/server:latest   # 去掉镜像站临时 tag
```

- 默认镜像站（可在测试中按可达性增删）：`docker.m.daocloud.io`、`docker.1ms.run`、
  `swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io`、`docker.mirrors.ustc.edu.cn`、
  `docker.nju.edu.cn`、`docker.1panel.live`。
- 镜像站列表可扩展：`./export.sh . --mirrors "docker.m.daocloud.io docker.1ms.run"`，
  或用环境变量 `DOCKER_MIRRORS="..."` 覆盖；以后新增镜像站只改这一处。
- 前缀可带路径：如华为云的 `swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io`，
  脚本会直接拼在镜像名前（`<前缀>/<镜像名>`）。各站路径风格不同时，用 `--mirrors` 按需传入。
- 仅在镜像名指向 Docker Hub 时回退；已带 registry host（如 `registry.cdvire.cn/...`、`nvcr.io/...`）的镜像不拼前缀。
- 若镜像站在本机 `/etc/docker/daemon.json` 里配了 `registry-mirrors`，那是另一层透明加速；本脚本的前缀回退与其互补。
- 全失败且本地无同名镜像时才报错。

## 安全边界（遵循 AGENTS.md）

- 拉镜像、起停容器、导出镜像均属**写入/变更操作**：执行前用一句话说明要做什么，让用户确认；
  纯探测（`docker version`、`df -h`、`ls`、`ss`）可直接执行。
- **密码只进 `.env`**；`.env.example` 只留占位符。严禁把真实密码写入仓库、手册或对话。
- **本地测试容器生命周期**：测试可能长期运行（供用户试用），不要擅自 `down`；卸载/清理前先问用户。
- 手册里展示配置用占位符代替真实密钥。
- 镜像 tag 固定版本，避免 `latest` 导致离线包与文档对不上。

## 常见坑

- **跳过测试直接打包**：最常见也最危险的错误。没跑通就打包，问题会推迟到离线机才暴露，返工成本更高。
- **只看容器 Up 不看端口**：容器 Up 不等于服务可用，必须做端口监听 + HTTP/HTTPS 探测。
- **忘了客户端强制 HTTPS**：把只支持 HTTP 的单服务直接交出去，客户端根本登录不了。需要 HTTPS 的服务必须反代前置并写清根证书信任（见上一节）。
- **离线机架构不一致**：`docker load` 失败的首要原因，打包前确认离线机 `uname -m`，必要时 `--platform`。
- **`docker compose` 与 `docker-compose` 混用**：老机器只有独立版，脚本已自动探测。
- **直连 Docker Hub 拉不动**：用镜像站前缀回退（见「拉取不到镜像时」一节）；镜像站清单可 `--mirrors` / `DOCKER_MIRRORS` 扩展。
- **只导出 compose 里被 `${VAR}` 引用的镜像**：用 `images.txt` 显式列出，避免变量解析歧义导致漏导。
- **本地数据目录不可写**：目标数据目录（如 `/srv/...`）本机可能无权限，测试时用工作目录下 `./data` 覆盖。
- **磁盘空间**：镜像 tar 可能很大，打包前用 `df -h` 确认余量。