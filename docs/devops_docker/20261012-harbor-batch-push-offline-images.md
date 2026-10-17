---
title: "【安装配置】离线 Docker 镜像批量导入内网 Harbor（mailcow 离线包实测）"
type: note
status: active
scope: devops_docker
created: 2026-10-12 15:36:00
updated: 2026-10-12 15:36:00
summary: "在无外网的 KVM 主机上将离线镜像包（*.tar.gz + manifest.txt）批量 load/tag/push 到内网 Harbor（registry.cdvire.cn/library），覆盖无 docker 权限走 sudo、Harbor Bearer 认证探测、保留 mailcow 子前缀命名等要点，并沉淀可复用脚本。"
keywords: [linux, ubuntu, docker, harbor, registry, docker-load, docker-push, mailcow, offline, intranet]
verification: "docker images | grep registry.cdvire.cn ; curl -sk https://registry.cdvire.cn/v2/ | head"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。严禁写入 Harbor 登录口令与 sudo 密码。"
---

## 📌 背景与目的

> [!NOTE]
> mailcow 离线部署包（见同仓库 `docs/mail_mailcow/20261012-mailcow-docker-deploy-guide.md`）产出了 `images/*.tar.gz` + `images/manifest.txt`。
> 本次目标是将这批离线镜像**统一导入内网 Harbor**（`registry.cdvire.cn/library`），供内网其它主机 `docker pull` 复用，免去逐台 `docker load`。
> 实测环境：KVM 主机 `SERVER_KVM_90`（192.168.16.90，Ubuntu 20.04，Docker 20.10.24），离线包位于 `/data/mailcow/images/`，共 18 个镜像。

## ⚙️ 核心内容

### 1. 环境与前提

| 项 | 值 |
|----|----|
| 目标仓库 | `registry.cdvire.cn`（解析到 192.168.16.254，**Harbor** 服务） |
| 目标项目 | `library` |
| 运行主机 | SERVER_KVM_90 / Ubuntu 20.04.6 LTS / Docker 20.10.24 |
| 离线包 | `/data/mailcow/images/`：18 个 `*.tar.gz` + `manifest.txt` |
| 登录用户 | `vire`（**不在 docker 组**，docker 命令需 `sudo`） |

镜像清单（`manifest.txt`，每行 `文件名<TAB>镜像名:标签`）：

```text
ghcr.io_mailcow_acme_1.98.tar.gz            ghcr.io/mailcow/acme:1.98
ghcr.io_mailcow_clamd_1.4.6-1.tar.gz        ghcr.io/mailcow/clamd:1.4.6-1
ghcr.io_mailcow_dockerapi_2.12.tar.gz       ghcr.io/mailcow/dockerapi:2.12
ghcr.io_mailcow_dovecot_2.3.21.1-2.tar.gz   ghcr.io/mailcow/dovecot:2.3.21.1-2
ghcr.io_mailcow_netfilter_1.64.tar.gz       ghcr.io/mailcow/netfilter:1.64
ghcr.io_mailcow_nginx_1.30.4-1.tar.gz       ghcr.io/mailcow/nginx:1.30.4-1
ghcr.io_mailcow_olefy_1.15.tar.gz           ghcr.io/mailcow/olefy:1.15
ghcr.io_mailcow_phpfpm_8.2.29-3.tar.gz      ghcr.io/mailcow/phpfpm:8.2.29-3
ghcr.io_mailcow_postfix_3.10.12-1.tar.gz    ghcr.io/mailcow/postfix:3.10.12-1
ghcr.io_mailcow_postfix-tlspol_1.14.0.tar.gz ghcr.io/mailcow/postfix-tlspol:1.14.0
ghcr.io_mailcow_rspamd_4.2.1-1.tar.gz       ghcr.io/mailcow/rspamd:4.2.1-1
ghcr.io_mailcow_sogo_5.12.11-1.tar.gz       ghcr.io/mailcow/sogo:5.12.11-1
ghcr.io_mailcow_unbound_1.26.1-1.tar.gz     ghcr.io/mailcow/unbound:1.26.1-1
ghcr.io_mailcow_watchdog_2.11.tar.gz        ghcr.io/mailcow/watchdog:2.11
mariadb_10.11.tar.gz                        mariadb:10.11
mcuadros_ofelia_latest.tar.gz               mcuadros/ofelia:latest
memcached_alpine.tar.gz                     memcached:alpine
redis_7.4.11-alpine.tar.gz                  redis:7.4.11-alpine
```

### 2. 前置检查（只读，务必先做）

```bash
# 1) 确认 registry 服务类型与连通性：HTTP 会 308 跳 HTTPS，/v2/ 返回 401 表示需认证
curl -s -v http://registry.cdvire.cn/v2/ 2>&1 | grep -iE 'HTTP/|Location'
curl -sk -D - -o /dev/null https://registry.cdvire.cn/v2/ | grep -i 'Www-Authenticate'
#   Www-Authenticate: Bearer realm="https://registry.cdvire.cn/service/token",service="harbor-registry"
#   → 确认是 Harbor，push 前必须先 docker login

# 2) 确认 docker daemon 是否已信任仓库证书（Harbor 为自签 CA）
cat /etc/docker/daemon.json
ls -l /etc/docker/certs.d/registry.cdvire.cn/

# 3) 确认当前用户是否有 docker 权限
docker info >/dev/null 2>&1 && echo "docker OK" || echo "需 sudo 或加入 docker 组"
```

### 3. 登录 Harbor（在运行 docker 的用户下执行）

```bash
# vire 无 docker 权限，故用 sudo；凭据写入 /root/.docker/config.json
sudo docker login registry.cdvire.cn
# 输入 Harbor 账号口令，出现 Login Succeeded 即可
```

```bash
# 确认登录凭据已落盘（能看到 registry.cdvire.cn 即已登录）
sudo cat /root/.docker/config.json | grep -o registry.cdvire.cn
```

### 4. 批量导入并推送

命名规则：**去掉原 registry 域名前缀，保留后续路径**（即保留 `mailcow/` 子前缀）。

- `ghcr.io/mailcow/acme:1.98` → `registry.cdvire.cn/library/mailcow/acme:1.98`
- `mariadb:10.11` → `registry.cdvire.cn/library/mariadb:10.11`
- `mcuadros/ofelia:latest` → `registry.cdvire.cn/library/mcuadros/ofelia:latest`

推荐直接使用沉淀脚本 `scripts/harbor/push-images-to-harbor.sh`（支持 sudo、dry-run、命名模式切换）：

```bash
# 预演（不实际推送）
scripts/harbor/push-images-to-harbor.sh -d /data/mailcow/images -N
# 实际推送（vire 无 docker 权限，-s 强制 sudo；默认保留 mailcow 子前缀）
scripts/harbor/push-images-to-harbor.sh \
  -d /data/mailcow/images \
  -r registry.cdvire.cn -P library -s
```

等价的纯手工循环（与脚本逻辑一致）：

```bash
cd /data/mailcow/images
while IFS=$'\t' read -r file image; do
  first="${image%%/*}"
  case "$first" in
    *.*|*:*|localhost) tpath="${image#*/}" ;;   # 首段是 registry 域名 → 去掉
    *)                 tpath="$image" ;;
  esac
  dest="registry.cdvire.cn/library/${tpath}"
  sudo docker load -i "$file"          # tar.gz 可被 docker load 直接识别（自动解压）
  sudo docker tag "$image" "$dest"
  sudo docker push "$dest"
done < manifest.txt
```

### 5. 验证

```bash
# 本机查看已打标的镜像
docker images | grep registry.cdvire.cn/library

# 直接拉取验证（换一台内网机器，或清掉本地标签后重拉）
docker pull registry.cdvire.cn/library/mailcow/sogo:5.12.11-1

# Harbor API 侧核对镜像仓库是否入库（需账号）
curl -sk -u '<user>:<pass>' 'https://registry.cdvire.cn/api/v2.0/projects/library/repositories?page_size=100'
```

`docker push` 成功时会输出每层 `Pushed/Mounted` 与最终 `digest: sha256:... size: ...`，即为成功标志。

## 🛠️ 验证清单（本次实测结果）

- [x] 18 个镜像全部 `docker load` 成功
- [x] 全部 `docker tag` 到 `registry.cdvire.cn/library/...` 成功
- [x] 18 个镜像 `docker push` 全部成功（`fail=0`），含公共层 `Mounted from ...` 去重复用
- [x] 命名保留 mailcow 子前缀：`library/mailcow/{acme,clamd,...}`；`library/{mariadb,redis,memcached,mcuadros/ofelia}`

## ⚠️ 注意事项

- **权限**：`vire` 不在 docker 组，所有 docker 命令需 `sudo`；`sudo docker login` 的凭据存于 `/root/.docker/config.json`，因此 push 也必须用 `sudo docker`，否则会 `denied: requested access to the resource is denied`。
- **Harbor `library` 项目**：Harbor 的 `library` 项目**非默认自动创建**（新版 Harbor 不含），若 push 报 `project ... not found`，需先在 Harbor Web 或 API 建项目（可用 `scripts/harbor/harbor_project.py`）。
- **HTTPS 证书**：Harbor 为自签 CA，`curl` 需 `-k`；docker 侧已通过 `/etc/docker/certs.d/registry.cdvire.cn/` 信任，无需加入 `insecure-registries`。若目标机未信任，需放入对应 CA 或临时使用 `insecure-registries`（修改 `daemon.json` 后 `systemctl restart docker`）。
- **口令安全**：Harbor 登录口令、sudo 密码严禁写入本文档、脚本与仓库。
- **去重**：公共基础层（如 `5f70bf18a086`、`989e799e6349`）会显示 `Mounted from ...`，说明跨镜像层复用，属正常加速现象。
- **离线包命名**：`manifest.txt` 的 `文件名<TAB>镜像名:标签` 是 `export.sh`/`docker-export.sh` 的产物；若离线包无 manifest，可改用目录内 `*.tar.gz` 文件名反推镜像名。

## 📎 参考

- 脚本：`scripts/harbor/push-images-to-harbor.sh`、`scripts/harbor/harbor_project.py`
- 离线包来源：`docs/mail_mailcow/20261012-mailcow-docker-deploy-guide.md`（§7 离线打包）
- Harbor API：`https://registry.cdvire.cn/api/v2.0/projects/{project}/repositories`