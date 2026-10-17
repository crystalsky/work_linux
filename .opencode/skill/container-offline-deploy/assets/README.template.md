# <service> 离线部署包

本目录是 **<service>** 的离线部署 bundle：在联网机器上打包，在离线机器上一次导入并启动。

## 目录结构

```text
<service>/
├── docker-compose.yaml   # 编排文件（变量来自 .env）
├── .env                  # 实际生效的配置（含密码，注意保密）
├── .env.example          # 配置模板（不含真实密码）
├── images.txt            # 镜像清单（repo:tag，每行一个）
├── images/               # 离线镜像 tar 包 + manifest.txt
├── export.sh             # 联网机器：拉取并导出镜像
├── deploy.sh             # 离线机器：导入镜像并启动
└── README.md             # 本文件
```

## 一、联网机器：制作/更新离线镜像包

```bash
# 离线机为不同 CPU 架构时，用 -p 指定平台（如 linux/amd64、linux/arm64）
./export.sh . --platform linux/amd64
```

产物为 `images/*.tar` 与 `images/manifest.txt`。

## 二、传输到离线机器

把整个 `<service>/` 目录拷贝 / 刻盘 / 内网传输到离线机器（保持目录结构不变）。

## 三、离线机器：导入并启动

```bash
cd <service>
./deploy.sh              # 导入镜像并 docker compose up -d
./deploy.sh ps           # 查看状态
./deploy.sh logs         # 查看日志
./deploy.sh down         # 停止（数据卷保留）
```

## 四、访问服务

| 用途 | 地址 |
|------|------|
| <入口> | http://<离线机IP>:${HOST_PORT} |

## 五、环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `IMAGE` | `<repo:tag>` | 镜像名与标签 |
| `<VAR>` | `<value>` | <说明> |

## 六、常见问题

- **`docker load` 报架构不匹配**：联网打包时用 `export.sh . --platform <离线机架构>` 重新导出。
- **端口被占用**：修改 `.env` 中的 `HOST_PORT` 后 `./deploy.sh up`。
- **找不到 compose 命令**：离线机需安装 docker-compose（v1/v2 均可，`deploy.sh` 会自动探测）。