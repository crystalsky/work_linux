---
title: "[安装配置] PicList 自定义上传器 → Wiki.js /u 完整配置指南（含 nginx 与 MinIO 原理详解）"
type: note
status: active
scope: 
created: 2026-09-10 16:10:00
updated: 2026-09-10 18:30:00
summary: "通过 PicList 自定义上传器对接 Wiki.js 的 /u 附件路径，使用 nginx 统一收口、MinIO 作为图片存储底座，讲清请求链路原理、nginx 关键指令和 MinIO 桶策略"
keywords: [piclist, picgo, wikijs, uploader, custom, nginx, minio, s3]
verification: "PicList 上传后浏览器访问 https://<wiki-domain>/u/<filename> 返回 200"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> Wiki.js 默认把所有附件/图片存放在自己的存储引擎中，由 Wiki.js 服务统一托管。这么做的问题：**图片与 Wiki 服务强耦合**——Wiki 扛着全部图片带宽、扩容不省心、也没法享用 CDN/反代的缓存能力。
>
> 所以生产上把「上传/托管图片」这件事从 Wiki.js 里拆出来，形成独立图床。本文的落地方案是：
> **PicList（上传）→ nginx（统一入口）→ MinIO（图片存储）**，图片在 Wiki 侧统一使用 `https://img.example.com/u/<key>` 形式的公开 URL。

## ⚙️ 核心内容

### 1. 核心原理：一张图看懂整条链路

先分清图床里的**两个动作**：**上传（写）**和**访问（读）**。它们在同一台服务器上，但走了完全不同的 nginx 路径。

```text
【上传动作】（写，只有 PicList 会发起）
   PicList ─POST multipart─► nginx ──反代──► FastAPI ──S3──► MinIO
   (桌面端)     /u/upload    (精确匹配)      (校验+写桶)     落盘

【访问动作】（读，浏览器/读者会发起）
   浏览器 ─GET─► nginx ──反代──►  MinIO  ──► 返回图片
   (Wiki读者)    /u/xxx.png     (路径重写)  (从桶取对象)

Wiki.js 只负责把「https://img.example.com/u/...」当普通图片地址嵌进页面，
图片数据全程不经过 Wiki.js 进程。
```

**为什么中间必须有 nginx 这一层？**
1. **统一入口/证书**：浏览器只认 `https://img.example.com`，nginx 在这里终结 TLS，MinIO 不需要暴露公网端口。
2. **路径翻译**：浏览器看到的 `/u/uploads/2026/09/a.png` 和 MinIO 里的实际对象 `bucket: wiki-images, key: uploads/2026/09/a.png` 不是一回事，nginx 做前缀改写。
3. **加缓存与安全**：图片命中 `immutable` 缓存；MinIO 端口被防火墙挡死，外部只能走 nginx。
4. **反代上传接口**：`POST /u/upload` 需要动态落库/校验，nginx 精确匹配后转给 FastAPI。

**为什么存储用 MinIO 而不是本地磁盘？**
| 维度 | 本地目录 /srv/upload | MinIO |
|------|----------------------|-------|
| 扩容 | 单机，扩容=拷数据 | 加节点，纠删码自动 |
| 备份 | 靠自己 rsync | `mc mirror`/生命周期 |
| 权限 | 文件系统权限 | 桶策略/AK-SK |
| 生态 | 无法被其他程序用 | S3 协议，其他工具都能读 |

### 2. 生产架构图

```text
                          服务器（示例单机）
┌───────────┐          ┌──────────────────────────────────────────────┐
│  PicList  │─POST────►│ nginx :443 (img.example.com)                  │
│  (桌面端)  │          │  ├─ exact  = /u/upload  ──► FastAPI :8000      │
└───────────┘          │  └─ prefix ^~ /u/        ──► MinIO :9000       │
                       │        (路径改写 /u  → bucket/wiki-images)     │
        ▲              └──────────────────────────────────────────────┘
        │ GET /u/...                         │
┌───────┴────────┐                ┌──────────▼─────────┐
│ Wiki.js 页面    │ 里面嵌的图片    │ MinIO (仅在127.0.0.1)│
│ (wiki.example) │ 地址全部走      │ bucket: wiki-images │
└────────────────┘ img.example.com │ 对象: uploads/...    │
                                   └────────────────────┘
```

> 关键安全约束：**MinIO 端口（9000）只绑定在 `127.0.0.1`**，对外只有 nginx:443 一个口子。这样桶配成「公开读」也只是对 nginx 可见，公网谁都无法绕过 nginx 直接扫 MinIO。

### 3. 部署 MinIO 并准备桶（图片存储底座）

#### 3.1 docker-compose
```yaml
# /opt/minio/docker-compose.yml
services:
  minio:
    image: minio/minio:RELEASE.2024-10-13T13-34-11Z
    restart: unless-stopped
    command: server /data --console-address ":9001"
    environment:
      MINIO_ROOT_USER: minioadmin
      MINIO_ROOT_PASSWORD: ChangeThisRootP@ssw0rd
    ports:
      - "127.0.0.1:9000:9000"   # ⭐ 只绑本机回环，公网不可达
      - "9001:9001"             # 控制台：管理时就本机用，生产建议加访问控制
    volumes:
      - /data/minio:/data
```

```bash
cd /opt/minio && docker compose up -d
```

> `127.0.0.1:9000:9000` 是本文安全的核心：容器把 9000 暴露成「只有本机才能访问」，nginx（同机）代理得了，公网访问不了。

#### 3.2 建桶 + 专用账号
```bash
docker exec -it minio sh -c 'mc alias set local http://127.0.0.1:9000 minioadmin ChangeThisRootP@ssw0rd'
docker exec -it minio sh -c 'mc mb local/wiki-images --region us-east-1'

# 创建专用最小权限用户（供 FastAPI 写入使用），记住输出的 AK/SK
docker exec -it minio sh -c 'mc admin user add local picwrite PicW@riter0nly'
docker exec -it minio sh -c 'mc admin policy attach local consoleAdmin --user picwrite'
```
> 生产请按《04-minio-setup》第 3 节用策略文件收紧（只给 `s3:PutObject`），这里简明示范。

#### 3.3 桶公开读策略（只允许 GetObject，禁止列目录）
桶要能被浏览器 GET，但不能被遍历。用一条**只读策略**替代 `mc anonymous set download`（后者连 ListBucket 一起放开了）：

```bash
cat > /tmp/pub-read.json <<'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "AWS": ["*"] },
      "Action": ["s3:GetObject"],
      "Resource": ["arn:aws:s3:::wiki-images/*"]
    }
  ]
}
EOF
docker cp /tmp/pub-read.json minio:/tmp/pub-read.json
docker exec -it minio sh -c 'mc anonymous set-json /tmp/pub-read.json local/wiki-images'
```

> 为什么敢公开读？因为 MinIO 端口只在 127.0.0.1 上，`*` 只能通过 nginx 这个唯一入口命中。**「公开读」+「端口不暴露」缺一不可。**

### 4. 部署接收端 FastAPI（把上传写进 MinIO）

> 上传接口干三件事：鉴权、校验类型、用 S3 协议把文件 `put_object` 进 MinIO。

```bash
mkdir -p /opt/wikijs-uploader && cd /opt/wikijs-uploader
python3 -m venv .venv && source .venv/bin/activate
pip install "fastapi" "uvicorn" "boto3" "python-multipart"
```

```python
# /opt/wikijs-uploader/main.py
import uuid
import boto3
from pathlib import Path
from botocore.client import Config
from fastapi import FastAPI, File, Form, UploadFile, HTTPException, Header

app = FastAPI(title="wikijs-uploader")

MINIO = {
    "endpoint": "http://127.0.0.1:9000",
    "ak": "从3.2得到的AccessKey",
    "sk": "从3.2得到的SecretKey",
    "bucket": "wiki-images",
}
TOKEN = "change-me-please"                 # 与 PicList 请求头一致
ALIAS = "/u"                               # 对外 URL 前缀
TYPES = {".png", ".jpg", ".jpeg", ".gif", ".webp", ".svg", ".bmp", ".ico"}

s3 = boto3.client(
    "s3",
    endpoint_url=MINIO["endpoint"],
    aws_access_key_id=MINIO["ak"],
    aws_secret_access_key=MINIO["sk"],
    region_name="us-east-1",
    config=Config(signature_version="s3v4", s3={"addressing_style": "path"}),
)

@app.post("/u/upload")
async def upload(image: UploadFile = File(...),
                 dir: str = Form("misc"),
                 authorization: str | None = Header(None)):
    if TOKEN and authorization != f"Bearer {TOKEN}":
        raise HTTPException(401, "bad token")

    suffix = Path(image.filename or "img").suffix.lower()
    if suffix not in TYPES:
        raise HTTPException(415, f"type not allowed: {suffix}")

    key = f"{dir.strip().strip('/')}/{uuid.uuid4().hex}{suffix}"   # 对象key
    s3.put_object(Bucket=MINIO["bucket"], Key=key,
                  Body=await image.read(), ContentType=image.content_type or "application/octet-stream")

    return {"data": {"url": f"{ALIAS}/{key}"}}   # 返回 /u/uploads/2026/09/xxx.png
```

```bash
# 前台跑：uvicorn main:app --host 127.0.0.1 --port 8000
# 生产用 systemd 托管：
sudo tee /etc/systemd/system/wikijs-uploader.service >/dev/null <<'EOF'
[Unit]
Description=WikiJS image uploader (FastAPI -> MinIO)
After=network.target

[Service]
User=root
WorkingDirectory=/opt/wikijs-uploader
ExecStart=/opt/wikijs-uploader/.venv/bin/uvicorn main:app --host 127.0.0.1 --port 8000
Restart=always

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload && sudo systemctl enable --now wikijs-uploader
```

### 5. 完整 nginx 配置（逐指令详解）

```nginx
# /etc/nginx/conf.d/img.example.com.conf
server {
    listen 443 ssl http2;
    server_name img.example.com;

    ssl_certificate     /etc/nginx/ssl/img.example.com.crt;   # 证书，图中省略
    ssl_certificate_key /etc/nginx/ssl/img.example.com.key;

    # ═══ 块A：上传接口（精确匹配）════════════════════════════════
    location = /u/upload {
        client_max_body_size 50m;                 # 上传体不得超过 50MB（默认只有1MB）
        proxy_pass http://127.0.0.1:8000;        # POST /u/upload 原样转给 FastAPI
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header Authorization $http_authorization;
    }

    # ═══ 块B：图片读取（前缀匹配）════════════════════════════════
    location ^~ /u/ {
        expires 1y;                                # 返回 Expires=1年后 + Cache-Control: max-age=31536000
        add_header Cache-Control "public, immutable";  # 图片永远不变，浏览器/CDN放缓存
        proxy_pass http://127.0.0.1:9000/wiki-images/;  # ⭐ 前缀改写（见下面原理说明）
        proxy_set_header Host $host;
    }
}
```

**nginx 是如何决定走哪一行的？**
| 规则 | 优先级 |
|------|--------|
| `location = /u/upload`（等号=精确匹配） | 最高，命中即用，不再比较 |
| `location ^~ /u/`（^~前缀匹配） | 其次，命中后跳过正则，直接用 |
| 普通 `location /` | 兜底 |

所以 `POST /u/upload` 进块A；`GET /u/uploads/2026/09/a.png` 进块B。

**块B 的 `proxy_pass http://127.0.0.1:9000/wiki-images/;` 如何改写路径？（重点理解）**
这是 nginx 最易踩坑的点。规则是：
> 当 `proxy_pass` **自带 URI 部分**（`http://.../wiki-images/`）且 location 是前缀匹配时，nginx 把请求 URI 中**与 location 前缀匹配的那一段**（`/u/`）**替换成** `/wiki-images/`。

```text
浏览器请求:  GET /u/uploads/2026/09/a.png
location:    ^~ /u/          （被替换的前缀）
proxy_pass:  http://127.0.0.1:9000/wiki-images/   （替换成的内容）
────────────────────────────────────────────────────────
最终到 MinIO:GET /wiki-images/uploads/2026/09/a.png
             └─桶名──┘   └─────对象 key──────┘
```

> ⚠️ 若把 `proxy_pass` 写成不带 URI 的 `http://127.0.0.1:9000;`，MinIO 会收到 `/u/uploads/...`，MinIO 里根本没有 `u` 这个桶 → 404。**必须带 `/wiki-images/` 尾巴**。

**对照：如果你坚持用本地磁盘存（不推荐）**
替换块B即可，利用的是 `alias` 的「前缀替换成目录」语义：
```nginx
    location ^~ /u/ {
        alias /srv/upload/;          # /u/a.png → 文件 /srv/upload/a.png
        try_files $uri =404;         # 文件不存在就返回404
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
```

**防火墙（很重要，别漏）**
```bash
ufw allow 443/tcp        # 只对世界开放 HTTPS
ufw deny 9000/tcp        # MinIO S3 端口公网一律拒绝（前面已在compose绑了127.0.0.1）
ufw deny 9001/tcp        # 控制台也只在内网
```

### 6. PicList 端配置（自定义上传器）

「设置 → 图床设置 → 自定义Web图床（Custom）」：

| 字段 | 值 | 说明 |
|------|-----|------|
| 请求方法 | `POST` | PicList 会把文件以 multipart/form-data 发出 |
| 请求URL | `https://img.example.com/u/upload` | 走 nginx 块A |
| 文件字段名 | `image` | 与 FastAPI `image: UploadFile` 一致 |
| 请求Headers | `Authorization: Bearer change-me-please` | 与 FastAPI TOKEN 一致 |
| 自定义请求参数 | `dir=uploads/2026/09` | 可选，告诉后端归档目录 |

**响应解析（PicList 需要知道「URL 从返回 JSON 的哪个位置取」）:**

```text
自定义真实URL   :  body.data.url
自定义URL前缀   :  https://img.example.com            ← 注意前缀到域名为止
```

**原理对照**：FastAPI 返回 `{"data":{"url":"/u/uploads/2026/09/xxx.png"}}` → PicList 解析出 `/u/uploads/2026/09/xxx.png` → 拼上前缀得到
`https://img.example.com/u/uploads/2026/09/xxx.png` → 这个地址既可贴进 Wiki，浏览器 GET 后也会走 nginx 块B 命中 MinIO。

### 7. Wiki.js 端对接

Wiki 不需要任何特殊插件，只需要认知这些图片地址「已存在」：

1. 写正文时直接粘贴图片：`![配图](https://img.example.com/u/uploads/2026/09/xxx.png)`。
2. 若希望 Wiki.js 编辑器自带的拖图上传也落到同一 MinIO，可在「管理 → 存储 → S3」指向 `http://127.0.0.1:9000` 桶 `wiki-images`（注意 Wiki.js 的 storage folder 与 `uploads/` 对齐），二选一即可，**不要混用两套存储**。

### 8. 端到端验证（一条龙自检）

```bash
# 1) 上传一张图（模拟 PicList）
curl -i -X POST https://img.example.com/u/upload \
     -H "Authorization: Bearer change-me-please" \
     -F "image=@./test.png"

#    预期返回: {"data":{"url":"/u/uploads/misc/abc123.png"}}
# 2) 把上面 url 拼上前缀浏览器/curl 访问
curl -I https://img.example.com/u/uploads/misc/abc123.png
#    预期: HTTP/1.1 200 OK / Content-Type: image/png / Cache-Control: public, immutable

# 3) 若想确认确实落在 MinIO
docker exec -it minio sh -c 'mc ls local/wiki-images/uploads/misc/'
```

**黄金链路小结**：`POST 200 → GET 200 → mc ls 见对象`，三个都过即成功。

## 🛠️ 常见问题

| 问题 | 原因与处理 |
|------|-----------|
| 上传 403 | FastAPI 的 TOKEN 与 PicList Header 不一致；或 nginx 没转发 `Authorization` 头 |
| 上传 413 | `client_max_body_size 50m` 改小，或前面还有网关（CDN/其他 l7）
| 图片 404 | ①`proxy_pass` 漏了 `/wiki-images/` 尾巴（见 5 节原理）②对象 key 与 URL 对不上 |
| 图片 403 | MinIO 桶策略没生效（`mc anonymous set-json` 未执行/对象 ACL），或 MinIO 端口没在 127.0.0.1 |
| SignatureDoesNotMatch | FastAPI 里 AK/SK/endpoint 抄错，或服务器时钟漂（`chronyc`/`ntpdate`） |
| 图片 URL 能访问但无缓存头 | `add_header` 在 `expires` 之后且同级别才生效，确认写在 location 内层 |

## 📂 相关文档

- `02-piclist-s3-r2-nginx-cdn.md` — 不走自建服务、直接用 S3/R2 + 云 CDN 的等价方案
- `04-piclist-minio-setup.md` — MinIO 桶/密钥/策略详细配置与备份
- `03-wikijs-upload-separation-arch.md` — Wiki.js 与图床分离的整体架构