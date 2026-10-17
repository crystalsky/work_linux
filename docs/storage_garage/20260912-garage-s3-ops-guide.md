---
title: "【运维手册】Garage S3 安装配置、多节点集群与数据备份恢复完整指南(含 S3 兼容切换)"
type: note
status: active
scope: storage_garage
created: 2026-09-12 14:00:00
updated: 2026-09-12 15:00:00
summary: "Garage 是 Rust 编写、极简轻量的 S3 兼容对象存储。本文给出单节点/多节点集群安装配置、Garage 数据与其它 S3(MinIO/Ceph/AWS S3)的兼容性边界、rclone 对象级备份恢复流程与切换到其它 S3 服务的迁移检查清单。"
keywords: [garage, s3, object-storage, rust, cluster, backup, restore, rclone, migration]
verification: "garage status 显示 nodes 与 all ok; rclone sync 后对随机对象执行 rclone check / aws s3 cp 校验返回 200"
ai_rules: "保持客观技术风格,代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> Garage 是纯 Rust 实现的 S3 兼容对象存储,特点:**单二进制、占用极低、多副本自动复制**、适合边缘/私有云/图床等轻量场景。
> 本文解决三个问题:①怎么安装与配置;②多节点集群怎么组建、数据安全靠什么机制;③数据如何备份恢复、**能否无缝切换到其它 S3 软件服务**。

## ⚙️ 核心结论:Garage 数据能否兼容切换到其它 S3?

**结论:API 层面可无缝迁移,磁盘层面不可直接搬。**

| 层面 | 结论 | 依据 |
|------|------|------|
| ✅ **S3 API / 对象数据** | **可直接迁移使用** | Garage 兼容 AWS S3 API,对象即二进制流;用 `rclone sync` / `aws s3 cp` 直接导到 MinIO / Ceph / R2 / AWS S3,**导入即用,无需特殊处理** |
| ❌ **服务器磁盘格式** | **不可移植** | 服务端数据 =`data_dir`(对象按 1MiB 分块) + `metadata_dir`(SQLite 元数据),两者格式私有,**仅 Garage 可读**,不能把目录拷给 MinIO/Ceph |
| ⚠️ **特性子集** | 需检查清单 | 不支持对象锁 / SSE 加密 / 事件通知 / 部分 ACL;生命周期与版本控制支持有限,迁移前确认应用未依赖 |

> 一句话:**迁移用 rclone 对象级全量同步(Garage → 任意 S3 均兼容);把数据目录直接拷过去不成立。**

## ⚙️ 核心内容

### 1. 安装(单二进制)

**方式 A:官方 .deb(Debian/Ubuntu)**
```bash
wget https://garagehq.deuxfleurs.fr/_releases/v1.0.1/garage-v1.0.1-x86_64-unknown-linux-musl.deb
sudo dpkg -i garage-v1.0.1-x86_64-unknown-linux-musl.deb
# 安装后自带 garage.service(systemd),数据目录 /var/lib/garage/{meta,data}
sudo systemctl enable --now garage
```

**方式 B:纯二进制(其他发行版)**
```bash
wget https://garagehq.deuxfleurs.fr/_releases/v1.0.1/garage-v1.0.1-x86_64-unknown-linux-musl
install -m 0755 garage-v1.0.1-x86_64-unknown-linux-musl /usr/local/bin/garage
garage --version
```

> garage 作为 systemd 服务时使用用户 `garage`,配置默认在 `/etc/garage.toml`。

### 2. 单节点配置

```toml
# /etc/garage.toml
metadata_dir = "/var/lib/garage/meta"     # 元数据目录(必须独立于 data)
data_dir     = "/var/lib/garage/data"     # 对象数据目录
db_engine    = "sqlite"                   # 1.x 默认元数据库引擎
block_size   = 1048576                    # 对象分块 1MiB
replication_mode = "1"                    # 单节点=1,3 节点集群用 "3"

[s3_api]
bind_addr   = "[::]:3900"                 # S3 API 端口
root_domain = ".s3.garage.local"          # 虚拟主机风格域名(可留空)

[s3_web]
bind_addr = "[::]:3901"                   # 静态网站端点(不用可注释)

[rpc]
bind_addr = "[::]:3902"                   # 节点间集群通信端口
```

```bash
sudo systemctl restart garage
garage status          # 看到 1 个节点、Healthy=true 即正常
```

### 3. 多节点集群配置(3 节点 × 3 副本)

**最小高可用:≥3 台机器,`replication_mode = "3"`(任意 1 节点故障数据不丢)。每个节点都装好 garage 并配以下内容:**

```toml
# 每台节点的 /etc/garage.toml —— 参数与单节点一致,仅改下面两段
metadata_dir = "/var/lib/garage/meta"
data_dir     = "/var/lib/garage/data"
db_engine    = "sqlite"
block_size   = 1048576
replication_mode = "3"

[s3_api] bind_addr = "[::]:3900"
[s3_web] bind_addr = "[::]:3901"
[rpc]    bind_addr = "[::]:3902"
```

**集群组网与布局(layout):**
```bash
# 各节点获取自身 node id
garage node id    # 输出如 1c90e...5ff3,记到尾节点分别是 A/B/C

# 在任意一台上把 3 个节点加入布局并指定可用区(zone)
garage layout assign A_NodeId -z dc1 -c 100G --tag node-a
garage layout assign B_NodeId -z dc2 -c 100G --tag node-b
garage layout assign C_NodeId -z dc3 -c 100G --tag node-c
garage layout show                                # 检查 pending 布局
garage layout apply --version 1                   # 1.x:应用版本 1
garage status                                     # 三节点 Healthy=true,Repair=true 表示数据平衡中
```

> - **`-z` 可用区**:3 节点各放 1 个 zone 即无单点故障;也可同 zone 多节点(电报机架内冗余)。
> - 新增节点扩容时:装 garage → `node id` → `layout assign` → `apply`,Garage 自动再平衡。
> - 节点间 RPC 走 3902 端口,防火墙放行;**同网段 Garage 会自动发现(mDNS)**,跨网段生产建议用 Kubernetes/Consul 的服务发现或保证 3902 可达后 `status` 可见。

### 4. 桶与访问控制(首用必做)

```bash
# 建桶
garage bucket create photos
# 建访问密钥(输出 AK / SK,gateway: 记下)
garage key create app1
# 授权密钥读写桶
garage bucket allow --read --write --owner app1 photos
# 校验
garage bucket info photos
garage key info app1
```

**S3 端点**:`http://<node-ip>:3900`(path-style,必填)。

客户端三种连接方式:
```bash
# aws cli
export AWS_ACCESS_KEY_ID=<AK> AWS_SECRET_ACCESS_KEY=<SK>
aws --endpoint-url http://127.0.0.1:3900 s3 ls

# rclone(Garage 迁入迁出的主力,见第 5 节)
cat >> ~/.config/rclone/rclone.conf <<'EOF'
[garage]
type = s3
provider = Other
endpoint = http://127.0.0.1:3900
access_key_id = <AK>
secret_access_key = <SK>
region = us-east-1
force_path_style = true
EOF

# mc(与 MinIO 同一工具链)
mc alias set garage http://127.0.0.1:3900 <AK> <SK>
```

### 5. 数据备份与恢复

#### 5.1 推荐方案:rclone 对象级备份(跨 S3 通用)

```bash
# ── 备份:Garage → 本地/其它 S3 ─────────────────────────────
rclone sync garage:photos /backup/garage/photos \
    --transfers 8 --log-file /var/log/garage-backup.log
# 增量备份:重复执行同命令(已传对象跳过)

# ── 恢复:本地/其它 S3 → Garage(重建或换机后)─────────────
rclone sync /backup/garage/photos garage:photos \
    --transfers 8 --log-file /var/log/garage-restore.log

# ── 完整性校验 ─────────────────────────────────────────────
rclone check garage:photos /backup/garage/photos --one-way
```

> 全桶备份(含所有桶):先 `rclone lsd garage: --dirs-only` 拿桶清单,循环执行上述 sync,或直接
> `rclone sync garage: /backup/garage --transfers 8`(garage 根级含全部桶)。

> 已封装为脚本 `scripts/backup/garage_backup.sh`(子命令 `backup`/`restore`/`check`/`list`,已 `chmod +x`),可直接用,见第 8 节。

#### 5.2 补充方案:停机复制数据目录(单节点/临时容灾)

仅适合**短暂停机**的单节点无损拷贝,集群模式不要用(各节点 meta/data 分角色):

```bash
sudo systemctl stop garage
sudo tar -czf /backup/garage-$(date +%F).tar.gz -C /var/lib garage
# 恢复:停服解包回 /var/lib/garage/{meta,data} 保持路径一致
sudo systemctl start garage
```

> 多副本本身即冗余:3 副本下若某节点磁盘坏,Garage 会自动从剩余副本重建。rclone 备份承担「逻辑误删 + 灾难全损 + 跨软件迁移」兜底。

### 6. 切换到其它 S3(MinIO/Ceph/AWS S3)迁移手册

**前提检查清单(migration checklist):**
| 依赖特性 | Garage | MinIO | Ceph | 说明 |
|----------|--------|-------|------|------|
| 对象读写/List/Multipart | ✅ | ✅ | ✅ | 核心场景无差异 |
| 版本控制(versioning) | 部分 | ✅ | ✅ | Garage 需显式开启且支持有限,多版本场景留意 |
| 生命周期(ILM) | 有限 | ✅ | ✅ | 自动过期规则差异大,迁移后重配 |
| 服务端加密 SSE | ❌ | ⚠️ 有限 | ✅ | 加密需求请改用应用侧加密 |
| 对象锁(Object Lock) | ❌ | ✅ | ✅ | 合规需求场景慎选 Garage |
| 事件通知 | ❌ | ✅ | ✅ | 依赖通知的应用不兼容 |
| ACL | 子集 | ✅ | ✅ | 公共桶用策略重配 |
| 磁盘目录直接搬 | ❌ | ❌ | ❌ | **均不可跨软件搬目录** |

**迁移操作(S3 → S3,以 Garage → MinIO 为例):**
```bash
# 0) 演练(推荐先用 dry-run 全桶预览)
scripts/backup/s3_migrate.sh --from garage --to minio --all-buckets --dry-run
# 1) 实施(脚本自动建桶?否——先手动建桶,再 sync+check)
rclone mkdir minio:photos
scripts/backup/s3_migrate.sh --from garage --to minio --bucket photos
# 2) 业务侧把 endpoint 从 3900 换成 MinIO,重跑应用回归(上传/下载/分片大文件)
```

> 若迁回 Garage(MinoIO → Garage)完全对称:`rclone sync minio:photos garage:photos`。

### 7. 备份验证与巡检
```bash
garage status                                  # 节点健康、恢复中修复进度
garage stats                                   # 总体用量/各节点占用
rclone check garage:photos /backup/garage/photos --one-way   # 备份一致性
# 每周恢复演练:把最近备份 sync 到临时桶,抽 3-5 个对象 aws s3 cp 回来做 md5 对比
```

### 8. 定时自动化(可选)

配套脚本 `scripts/backup/garage_backup.sh`(已 `chmod +x`),支持 `backup`/`restore`/`check`/`list` 子命令,与 systemd timer 结合即可每日自动增量备份:

```bash
install -m 755 scripts/backup/garage_backup.sh /usr/local/bin/garage_backup.sh

# timer unit
sudo tee /etc/systemd/system/garage-backup.timer >/dev/null <<'EOF'
[Unit]
Description=Garage 每日 S3 对象备份
[Timer]
OnCalendar=*-*-* 03:10:00
Persistent=true

[Install]
WantedBy=timers.target
EOF

# service unit
sudo tee /etc/systemd/system/garage-backup.service >/dev/null <<'EOF'
[Unit]
Description=Garage 每日 S3 对象备份
[Service]
Type=oneshot
ExecStart=/usr/local/bin/garage_backup.sh backup
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now garage-backup.timer
systemctl list-timers garage-backup.timer
```

> 跨 S3 迁移/演练使用 `scripts/backup/s3_migrate.sh`(见第 6 节),本脚本不处理迁移。

## ✅ 验证命令
```bash
garage status            # 全部 Healthy=true
rclone check garage:photos /backup/garage/photos --one-way   # 0 differences
aws --endpoint-url http://127.0.0.1:3900 s3 ls s3://photos   # 桶可见
```

## ⚠️ 常见问题
| 问题 | 原因与处理 |
|------|-----------|
| `layout apply` 后状态在 Moving/Repair | 数据重平衡中,`garage status` 观察 Repair 归零即可 |
| 客户端 403 SignatureDoesNotMatch | 时钟偏移(校准 NTP)或 AK/SK/region(固定 `us-east-1`)错误 |
| 多节点互相不可见 | 3902 RPC 端口未放行、跨网段无发现服务(配 Consul/K8s 或保证可达) |
| rclone link 403 | 必须 `force_path_style=true`,`provider=Other` |
| 想换回 MinIO 但对象不见了 | 生命周期/版本差异导致,见第 6 节检查清单逐项核验 |

## 📎 相关文档
- `scripts/backup/garage_backup.sh` — Garage 备份/恢复/校验脚本(rclone)
- `scripts/backup/s3_migrate.sh` — 任意 S3 之间互迁/演练脚本(Garage↔MinIO/Ceph/云 S3)
- `docs/storage_minio/20260912-minio-distributed-backup-restore-guide.md` — MinIO 集群备份恢复(同思路可对照)
- `soft_use/piclist/01-piclist-custom-uploader-wikijs.md` — Wiki.js 图床分离(MinIO 底座,可换 Garage)