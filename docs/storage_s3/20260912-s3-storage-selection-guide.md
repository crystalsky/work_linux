---
title: "【运维手册】S3 对象存储选型指南：MinIO / RustFS / Garage 对比与 50 人团队分布式部署决策"
type: note
status: active
scope: storage_s3
created: 2026-09-12 16:30:00
updated: 2026-09-12 17:10:00
summary: "内部多个服务数据统一入 S3 桶、需分布式部署且要稳定的场景下,对比 MinIO / RustFS / Garage 在用户使用、运维维护与迁移扩展上的差异。含 2025-10 起 MinIO 开源版归档(EOL)的事实与影响,给出修正后的 50 人团队选型结论。"
keywords: [s3, minio, rustfs, garage, object-storage, selection, distributed, storage]
verification: "mc alias set 后可 mc admin info 查看集群;各作家服务 SDK 端点 http://s3:9000 连通后读写全部桶正常"
ai_rules: "保持客观技术风格,代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> 场景:团队内部多个服务(文档库、图床、备份、AI/大数据训练集、Wiki/Web 附件等)统一把数据写入 S3 存储桶;
> 要求:①桶读写要**稳定**;②可以**分布式部署**承载后续增长;③**用户使用**(各服务对接、日常上传下载)与
> **运维维护**(监控、升级、扩容、排障)都要省心;团队规模约 50 人。

## ⚙️ 核心内容

### 1. 需求清单(从场景推导)

| 需求 | 说明 |
|------|------|
| 稳定优先 | 桶必须是长期可依赖的基础设施,故障/坏盘有兜底(纠删码/副本),升级不中断 |
| S3 兼容要广 | 多个服务、多种 SDK/工具(aws-cli / mc / rclone / 各语言 SDK)必须即插即用 |
| 运维友好 | Web 管理台、清晰监控、社区资料、成熟升级/扩容路径 |
| 可扩展 | 从一台起步能在线扩容量/节点,不推倒重来 |

### 2. 三方案对比(分布式场景)

| 维度 | MinIO | RustFS | Garage |
|------|-------|--------|--------|
| 稳定性/成熟度 | **极成熟但在售→归档**:开源版 2025-10 起 EOL,不再有安全更新,继续维护须商业订阅 | **1.0.0-rc 预发布**,功能齐全但尚未 GA | 较稳定(v1 正式发布),仍活跃维护,但重点在边缘/自管 |
| 分布式形态 | 纠删码集群,单节点多盘即 EC,可滚蛋式加节点/Pool 在线扩容 | 池式扩展,规则与 MinIO 对齐 | 3 节点起步 layout 复制,二次平衡自动 |
| 用户使用(SDK/CLI) | **最标准**,所有 S3 客户端全兼容,console+mc UI 直观 | 对齐 MinIO,兼容面广 | S3 子集,**部分高级能力缺失**,个别客户端可能有缺口 |
| 运维维护 | **最省心**:Web 台全功能、mc 工具、文档/社区/解决方案最丰富、排障方案易搜到 | Web 台+mc 对齐 MinIO,但资料与坑经验积累少,新出问题可能要翻官方 issue | **无官方图形台**,管理靠 `garage layout` CLI,学习与使用门槛高 |
| 升级/扩容平滑度 | 成熟:在线 Pool 扩展、版本升级路径清晰 | 与 MinIO 同构,但成熟度待验证 | 加节点即扩,rebuild 自动,但功能升级路线偏自治社区 |
| 资源开销 | 中 | 低 | 极低 |

### 3. 结论与建议

**⚠️ 重大前提变化(2025-10 起):MinIO 开源版已归档(EOL)。**

MinIO Server / mc / KES 开源仓库已归档(`archived: true`),官方二进制下载通道返回 410,不再提供安全更新与社区支持;最后一个开源 release 为 **RELEASE.2025-10-15T17-29-55Z**(修复服务账号/STS 会话策略绕过提权 CVE)。"长期靠社区维护 MinIO"的场景已不存在,要继续获得修复与支持必须购买 MinIO 商业订阅。

**修正后的选型结论(50 人团队、长期稳定、多服务入桶):**

| 路线 | 方案 | 说明 |
|------|------|------|
| 免费开源、长期自维护 | **Garage(立即可用) > RustFS(等 1.0 GA)** | Garage 稳定且仍活跃维护;RustFS 活跃开发 + Apache 2.0 + 可与 MinIO 盘互通,是最值得跟踪的候选;**MinIO 开源已停更,不再推荐作为新建长期方案** |
| 付费换取官方维护 | **MinIO 商业订阅** | 若预算允许,MinIO 仍是最省心运维的 S3(修复/扩容/支持官方负责),适合"稳定优先"的多服务场景 |
| 无论选哪条路 | 均为标准 S3 API | rclone/mc 对象级互迁,**不锁定**,可随时平滑换(见各方案手册) |

**短期落地建议:**
1. 存量 MinIO(手册版本 2024-10-13)若继续使用,最后应升到 **RELEASE.2025-10-15T17-29-55Z** 补齐已知安全修复——这是开源版的终止点,之后不再有补丁。
2. 新部署不建议再选开源 MinIO;把 **Garage(先跑通场景)** 与 **RustFS(AG 后切换)** 列入候选验证。
3. 所有 S3 客户端对接代码零改动即可在两方案间迁移,过渡期无锁定风险。

### 4. 落地路径(推荐)

```bash
# 阶段一:单节点 4 盘起跑(纠删码兜底,数据已分层保护)
mkdir -p /data/{disk1..4} && chown -R <user> /data
minio server --address ":9000" --console-address ":9001" \
  http://minio{1..4}/data --help   # 实际单节点写法见 MinIO 手册

# 阶段二:更高可用时扩到 2 节点(每个节点 4 盘)或 4 节点
# 做法:在线把单节点 pool 与新增节点 pool 组合到一个分布式命令行

# 阶段三:统一接入规范
# - 每个服务独立 AccessKey + 桶 + IAM 策略做最小权限
# - 服务端通过内网 DNS s3.<域名> 访问 9000
# - 统一用 rclone 做每日对象级备份
```

最佳实践:
- 各服务**独立密钥与桶**,控制台做最小权限管理,避免共用一个管理员 Key。
- 打开**版本控制 + 生命周期(ILM)**:bucket 多版本兜误删,ILM 自动转冷/清过期数据。
- 配置**监控告警**(Prometheus endpoint 9000/minio/v2/metrics/metadata 等),磁盘/容量阈值告警。
- 内网统一走 `http://s3:9000`,外部严格要求 HTTPS。

### 5. 参考对照手册

- `docs/storage_minio/20260912-minio-distributed-backup-restore-guide.md`
- `docs/storage_rustfs/20260912-rustfs-s3-ops-guide.md`
- `docs/storage_garage/20260912-garage-s3-ops-guide.md`

## 🛠️ 验证方式

```bash
mc admin info s3              # 集群节点/驱动全绿
python3 -c "import boto3; s3=boto3.client('s3',endpoint_url='http://s3:9000',aws_access_key_id='...',aws_secret_access_key='...'); print([b['Name'] for b in s3.list_buckets()['Buckets']])"
```

## 📎 参考

- MinIO:https://min.io 、https://github.com/minio/minio(**仓库已归档**,开源 EOL;CVE 修复止于 RELEASE.2025-10-15T17-29-55Z)
- RustFS:https://rustfs.com 、https://github.com/rustfs/rustfs
- Garage:https://garagehq.deuxfleurs.fr 、https://github.com/GarageHQ/garage
- 兼容性矩阵:RustFS https://github.com/rustfs/rustfs/blob/main/docs/architecture/s3-compatibility-matrix.md