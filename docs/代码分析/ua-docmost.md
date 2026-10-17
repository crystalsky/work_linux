以开源协作文档/知识库项目 **[Docmost](https://github.com/docmost/docmost)**（一个基于 TypeScript Monorepo 架构、定位为 Notion / Confluence 开源替代品的实时协作系统）为例，带你完整实战一遍 **Understand-Anything 工具链 + 针对性提示词** 的逆向拆解全流程。

---

### 第一步：准备阶段与初始化图谱

Docmost 是一个典型的 **pnpm + Nx Monorepo**（包含 `apps/server`、`apps/client`、`packages` 等目录），全量分析可能文件量较大。建议先做聚焦分析：

```bash
# 1. 克隆代码
git clone https://github.com/docmost/docmost.git
cd docmost

# 2. 如果使用 Claude Code / Codex，建议先限定后端核心服务进行图谱构建（节省 Token 且更快）
/understand apps/server --language zh

# 3. 启动本地交互面板，直观查看依赖和架构分层
/understand-dashboard

```

---

### 第二步：四大维度专属技能与实战提示词

针对 Docmost 这类**实时协作、多租户/空间、富文本编辑**的系统，在四个核心维度上的具体拆解策略如下：

---

#### 维度 1：接口层拆解（REST API & WebSocket 实时信道）

> **业务背景**：Docmost 既有传统的 REST API（鉴权、空间管理、页面元数据），又有协同编辑（通常基于 Yjs / WebSocket）的长连接信道。

* **使用技能**：
* 先在 Dashboard 过滤器中勾选 `API / Controller / Gateway`。
* 针对具体的路由目录执行精读：
```bash
/understand-explain apps/server/src/

```




* **实战提示词（Prompt）**：
```markdown
请结合当前构建的代码图谱，帮我梳理 Docmost 的所有对外通信接口与边界：

1. 【HTTP 接口全景】：
   - 系统的路由（Routes/Controllers）是如何组织的？主要包含哪些模块（如 auth, spaces, pages, users）？
   - 请求的生命周期中间件链是怎样的（如 JWT 验证、Cookie 解析、RBAC 权限中间件）？请画出请求流转图。
   - 统一的 Response 返回结构和全局 Exception Filter 是如何设计的？

2. 【实时通信 / WebSocket 接口】：
   - 项目中处理文档协同编辑的 WebSocket Gateway / Handler 在哪里？
   - 客户端加入一个 Space 或打开一个特定 Page 时，发送的握手协议与鉴权流程是怎样的？
   - 协同消息是如何与持久层解耦的？

```



---

#### 维度 2：核心业务逻辑分析（协同编辑、空间与权限体系）

> **业务背景**：Docmost 的核心业务主要围绕 **Space（空间）**、**Page（页面层级树）**、**Permissions（组织/群组权限）** 和 **实时编辑冲突解决**。

* **使用技能**：
* 运行业务领域提取命令：
```bash
/understand-domain

```


* 配合针对图谱的语义问答：
```bash
/understand-chat "Docmost 的页面权限继承机制和父子页面树是如何计算的？"

```




* **实战提示词（Prompt）**：
```markdown
基于 /understand-domain 提取的领域流，请为我深入解析 Docmost 的三大核心业务模块：

1. 【页面层级与版本管理】：
   - 页面（Page/Document）的树状父子层级是如何存储和维护的（Nested Sets、Materialized Path 还是邻接表 parentId）？
   - 页面在发生移动、重命名、归档或删除（软删除/级联）时的业务校验流程是怎样的？
   - Page History（历史版本快照）的生成与回滚机制在 Service 层是如何实现的？

2. 【权限与空间隔离（RBAC）】：
   - 用户、群组（Groups）、空间（Spaces）和单个页面之间的权限判定优先级规则是什么？
   - 找到核心的 Permission Service 或 Policy 代码，分析权限校验函数的核心算法与鉴权拦截点。

```



---

#### 维度 3：数据流与数据处理（Data Pipeline & CRDT）

> **业务背景**：协同文档最硬核的部分在于富文本的数据处理——文档内容如何落库、如何做 CRDT（Yjs）更新、附件/图表（Draw.io/Excalidraw）数据如何存储。

* **使用技能**：
* 在 Dashboard 中过滤出 `Data / Repository / Entity / Model` 节点。
* 定位 ORM 配置（如 Prisma / TypeORM / Drizzle / Kysely）文件后执行：
```bash
/understand-explain apps/server/src/database

```




* **实战提示词（Prompt）**：
```markdown
请重点剖析 Docmost 的数据架构与实时协作数据处理机制：

1. 【协作数据（CRDT / Yjs）流转】：
   - 文档的正文内容是存为纯 JSON/HTML，还是作为 Yjs 二进制更新（yjs update / snapshot）持久化？
   - 协同编辑时，客户端产生的 Delta 增量数据从 WebSocket 接收后，是如何在内存（或 Redis）中暂存，并最终定期批量 Flush 刷入数据库的？

2. 【数据库模型与关联】：
   - 梳理 Postgres/MySQL 中的核心数据表及其关联关系（User, Workspace, Space, Page, PageVersion, Attachment 等）。
   - 哪些高频查询建立了特殊索引？是否存在全文检索（如 Postgres Full-Text Search 或 Algolia 集成）？

3. 【附件与媒体文件处理】：
   - 用户上传的图片、附件及内嵌图表数据（Excalidraw/Draw.io）的处理管线是怎样的？
   - 支持哪些存储后端（本地磁盘、S3/MinIO），其驱动抽象层是如何设计的？

```



---

#### 维度 4：架构全貌与二次开发（Extension & Contributing）

> **业务背景**：作为开发者，理解完后最常见的要求是“在此基础上新增功能”或“接入第三方 SSO”。

* **使用技能**：
* 运行新人漫游命令，获得系统级依赖顺序：
```bash
/understand-onboard

```


* 在开发测试时进行变更影响预警：
```bash
/understand-diff

```




* **实战提示词（Prompt）**：
```markdown
我计划基于 Docmost 进行二次开发和功能扩展，请结合系统全局架构给出指南：

1. 【分层规范与设计模式】：
   - 后端采用了什么样的分层设计（Controller -> Service -> Repository -> Entity）？各层之间依赖约束是什么？
   - 是否有依赖注入（DI）容器或事件总线（Event Emitter）用于模块解耦？列举出核心的事件广播机制。

2. 【二次开发实战范例】：
   - 场景：如果我想新增一个“飞书/Lark 第三方 OAuth 登录”并支持一键同步团队组织架构，我需要分别修改/新建哪些文件？
   - 请列出：路由注册点、Auth 适配器、数据表迁移文件（Migration）、前端入口的修改步骤。

```



---

### 总结：日常梳理项目的节奏清单

| 阶段 | 动作 | 预期产出 |
| --- | --- | --- |
| **0 ~ 15 分钟** | `/understand apps/server` + `/understand-dashboard` | 建立全局拓扑直觉，知晓系统由哪些模块构成。 |
| **15 ~ 30 分钟** | 发送**维度 1（接口）**与**维度 2（业务）**提示词 | 搞清楚系统的对外 HTTP/WS 协议以及空间/页面的业务主线。 |
| **30 ~ 60 分钟** | 结合 `/understand-domain` 与**维度 3（数据）**提示词 | 攻克最硬核的 CRDT/Yjs 协同机制与数据库表关系。 |
| **编写代码时** | 随时执行 `/understand-diff` | 验证当前改动是否破坏了上下游的依赖树。 |