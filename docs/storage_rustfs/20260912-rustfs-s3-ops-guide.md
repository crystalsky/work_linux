---
title: "【运维手册】RustFS S3 安装配置、Web 控制台管理、平滑迁移/扩展升级指南(含与 MinIO/Garage 对比)"
type: note
status: active
scope: storage_rustfs
created: 2026-09-12 16:00:00
updated: 2026-09-12 16:00:00
summary: "RustFS 是 Rust 编写的 Apache2.0 开原高性能 S3 兼容对象存储(支持 MinIO 磁盘格式互通预览)。本文给出一键脚本/Docker 安装、单节点与池扩展、Web 控制台与 mc 管理、rclone 备份、与 MinIO/Garage 对比和平滑迁移兼容策略。"
keywords: [rustfs, s3, object-storage, rust, minio, garage, backup, rclone, migration, pool-expansion]
verification: "docker ps 查看 rustfs 容器 Running; 浏览器访问 http://<ip>:9001 控制台登录; mc ls rustfs: 返回桶列表"
ai_rules: "保持客观技术风格,代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> RustFS(`github.com/rustfs/rustfs`)是 Rust 编写的高性能分布式 S3 兼容对象存储,Apache 2.0 许可,**无 AGPL 传染**,特性覆盖面与 MinIO 对齐(对象锁/IAM/生命周期/桶复制/事件通知/S3 Select 等),并提供 **MinIO 磁盘格式兼容(预览)** 帮助从 MinIO 平滑迁移。本文解决:①如何安装与配置;②如何通过 Web 控制台/mc 管理;③多盘/多节点池如何扩展、如何备份恢复;④与 MinIO/Garage 在运维与迁移上的差异。

## ⚙️ 核心结论:与 MinIO/Garage 的迁移兼容性

| 层面 | RustFS 结论 | 依据 |
|------|-------------|------|
| ✅ **S3 API / 对象数据** | 与任意 S3 服务**对象级互通**,`rclone sync`/`mc mirror`/`aws s3 cp` 即迁即用 | 兼容 AWS S3 API,对象即二进制流 |
| 🧪 **磁盘级兼容** | 支持 **MinIO On-Disk Compatibility(预览,`rio-v2` 特性)**,可直接读取 MinIO 数据盘;MinIO 加密对象除外 | 迁移到 MinIO 大集群、或从 MinIO 切换时无需对象重灌 |
| ❌ **Garage 磁盘格式** | 与 Garage 磁盘格式不互通,需对象级同步 | Garage 私有 chunk+SQLite 元数据格式 |
| ⚠️ **注意** | 当前为 `1.0.0-rc` 预发布,生产大规模部署前充分压测 | Apache 2.0,特性标记见官方 compatibility matrix |

> 一句话:**S3 API 层三者都能对象级互通;RustFS 额外提供 MinIO 盘格式互通(预览),但不读 Garage 盘。**

## ⚙️ 核心内容

### 1. 安装(Docker 推荐)

镜像 `rustfs/rustfs`,端口 **9000**(S3 API)/ **9001**(Web 控制台)。容器内非 root 用户 **UID/GID 10001:10001**,挂载目录必须先 chown。

```bash
# 数据与日志目录授权
mkdir -p data logs
chown -R 10001:10001 data logs

# 指定版本启动(建议锁版本,不用 latest)
docker run -d --name rustfs \
  -p 9000:9000 -p 9001:9001 \
  -v $(pwd)/data:/data -v $(pwd)/logs:/logs \
  rustfs/rustfs:1.0.0-rc.6

# podman 方式(自动处理目录属主)
podman run -d -p 9000:9000 -p 9001:9001 \
  -v $(pwd)/data:/data:Z,U -v $(pwd)/logs:/logs:Z,U \
  rustfs/rustfs:latest
```

**未用 Docker 的一键安装**:
```bash
curl -O https://rustfs.com/install_rustfs.sh && bash install_rustfs.sh
```

**Compose 部署**(仓库自带 `docker-compose-simple.yml`,含可观测性服务 Grafana/Prometheus/Jaeger 可选用):
```bash
docker compose -f docker-compose-simple.yml up -d
```

> [!CAUTION]
> 挂载点属主不是 `10001:10001` 时启动会报 permission denied;也可在 compose 里把服务设为 `user: "<host-uid>:<host-gid>"`。

### 2. 初始配置与访问

1. 打开 `http://<服务器ip>:9001` 进入 Web 控制台。
2. 默认凭据:**`rustfsadmin` / `rustfsadmin`**(首次务必在控制台改密码)。
3. 控制台可完成:创建/管理桶、创建 AccessKey/SecretKey、IAM 策略、生命周期(ILM)、事件通知、桶复制、配额、审计日志查看等,覆盖多数管理需求(好管理的关键)。

S3 标准客户端接入:
```bash
# mc 兼容客户端
mc alias set rustfs http://127.0.0.1:9000 <ak> <sk>
mc ls rustfs

# aws cli
aws --endpoint-url http://127.0.0.1:9000 s3 ls

# rclone(S3 远程)
rclone config   # type=s3, provider=Other, endpoint=http://127.0.0.1:9000
```

### 3. 单节点/多盘与池扩展

- **单节点单盘(SNSD)**:仅作独立本地路径;**不能原地扩容、不能加入 Pool**;要上多盘需新建部署后经 S3 迁移。
- **多盘/Multi-drive**:以 Erasure Set 为单元。扩容量=**追加新 Pool**,保持既有 Pool 的端点和 EC 宽度不变;基于 `...` 通配的端点表达式必须至少展开成 2 个盘。
- **节点下线/退役**:支持 Decommission,可在线把数据迁出下线节点。
- 拓扑与池布局规则与 MinIO 对齐,但自动 parity 选择策略不同,扩展前参考官方 Pool layout 兼容性说明。

```bash
# 示例:4 盘单节点(环境变量/启动参数形态以官方文档为准)
rustfs server /data/disk{1...4}
# 扩容 -> 追加新 Pool,注意通配必须展开 >= 2 个端点:
rustfs server /data/disk{1...4} /data/disk{5...8}
```

### 4. 数据备份与恢复(rclone 对象级)

| 场景 | 命令 |
|------|------|
| 备份全部桶 | `rclone sync rustfs: /backup/rustfs --transfers 8` |
| 备份单桶 | `rclone sync rustfs:photos /backup/rustfs/photos --transfers 8` |
| 恢复 | `rclone sync /backup/rustfs/photos rustfs:photos --transfers 8` |
| 校验 | `rclone check rustfs:photos /backup/rustfs/photos --one-way` |
| 定时 | crontab: `0 2 * * * rclone sync rustfs: /backup/rustfs --log-file /var/log/rustfs-backup.log` |

> 对象级备份是通用兜底;桶复制/站点复制(同步异常可用)属在线容灾手段。

### 5. 与 MinIO 互相迁移

```bash
# 方式一(通用,对象级,适用任意 S3 双向):
rclone sync minio:project rustfs:project --transfers 8
# 或
mc mirror minio/project rustfs/project

# 方式二(仅在 RustFS 构建开启 rio-v2 特性且未被 MinIO 加密时):
# 直接把 MinIO 数据盘挂给 RustFS 读取(MINIO 磁盘格式互通,预览)
```

### 6. 常见运维注意事项

- **版本策略**:当前 `1.0.0-rc.*` 迭代快,生产建议锁定稳定 rc 并跟踪 changelog;正式 GA(1.0.0)发布前慎重承载核心业务。
- **TLS**:生产必须启用 HTTPS(`https://docs.rustfs.com/integration/tls-configured`),证书目录同样须 `10001:10001` 可读。
- **事件通知**:Webhook 通知默认禁止向私网/容器网络地址发请求,`RUSTFS_OUTBOUND_ALLOW_ORIGINS` 需显式放行内网 `scheme://host:port`。
- **KMS**:Object Lock 与 SSE 使用 KMS(Vault/AWS KMS 支持生产;Local/Static 仅开发)。
- **许可证**:Apache 2.0,无 AGPL 传染,可放心商用/二次封装。

### 7. 三方案选型速览(RustFS / MinIO / Garage)

| 维度 | MinIO | RustFS | Garage |
|------|-------|--------|--------|
| 语言/许可证 | Go / **AGPL v3** | Rust / **Apache 2.0** | Rust / **AGPL v3** |
| 成熟度 | 极成熟(2014~) | 新(2023~,1.0 rc) | 较成熟(自 v1 稳定) |
| 单机即可用 | ✅ | ✅ | 单节点可用,高可用须 3 节点 |
| Web 管理台 | ✅ 极佳 | ✅ 佳 | ❌ 以 CLI(`garage layout`)为主 |
| 高级特性(对象锁/SSE/复制/S3Select) | ✅ 齐 | ✅ 齐 | ⚠️ 子集(加密/通知受限) |
| 资源占用 | 中 | 低 | 极低 |
| 与 MinIO 盘互通 | - | ✅(预览) | ❌ |
| 生态/资料/招人 | 最广 | 增长快 | 中 |

## 🛠️ 验证方式

```bash
docker ps --filter name=rustfs                    # Up(healthy)
curl -I http://127.0.0.1:9000                    # S3 API 200
curl -I http://127.0.0.1:9001                    # Console 200
mc alias set rustfs http://127.0.0.1:9000 <ak> <sk> && mc ls rustfs
```

## 📎 参考

- 官方仓库:https://github.com/rustfs/rustfs
- 官方文档:https://docs.rustfs.com
- 安装指南:https://docs.rustfs.com/en/installation
- 本仓库对照文档:`docs/storage_minio/20260912-minio-distributed-backup-restore-guide.md`、`docs/storage_garage/20260912-garage-s3-ops-guide.md`