**Understand-Anything** 是一个结合 **Tree-sitter 静态代码分析** 与 **多 Agent LLM 语义提取** 的开源辅助工具。它可以将复杂的代码库扫描并转化为**可交互的架构知识图谱（Knowledge Graph）**，并生成业务流程、引导教程和可视化 Dashboard。

---

## 一、 安装与环境准备

该工具支持主流的 AI 编码平台（Claude Code、Cursor、VS Code Copilot、Codex、Gemini CLI 等）。

### 1. 快速安装方式

* **Claude Code 用户（官方推荐原生插件）**：
```bash
/plugin marketplace add Egonex-AI/Understand-Anything
/plugin install understand-anything

```


* **一键脚本安装（支持 Codex, OpenCode, Gemini CLI, Cline, KIMI 等）**：
* **macOS / Linux**：
```bash
curl -fsSL https://raw.githubusercontent.com/Egonex-AI/Understand-Anything/main/install.sh | bash
# 或指定平台，例如 codex:
curl -fsSL https://raw.githubusercontent.com/Egonex-AI/Understand-Anything/main/install.sh | bash -s codex

```


* **Windows (PowerShell)**：
```powershell
iwr -useb https://raw.githubusercontent.com/Egonex-AI/Understand-Anything/main/install.ps1 | iex

```




* **Cursor / VS Code**：
* 直接打开项目根目录，通过 `.cursor-plugin/` 或 `.copilot-plugin/` 自动识别；也可在插件市场/扩展中搜索添加。



---

## 二、 核心命令与使用流程

在终端或 AI 对话框中，通常使用对应前缀（大部分平台为 `/`，Codex 为 `$`）：

| 命令 | 适用场景 | 详细说明 |
| --- | --- | --- |
| `/understand` | 项目全量/增量分析 | 启动多 Agent 扫描代码，建立图谱并存入 `.ua/knowledge-graph.json`。支持指定语言：`/understand --language zh`。对于超大仓库可限定子目录：`/understand src/backend`。 |
| `/understand-dashboard` | 启动可视化图形面板 | 在浏览器打开交互式知识图谱，按分层（API、Service、Data 等）着色。 |
| `/understand-domain` | 提取业务领域与流程 | 提炼出核心业务域（Domains）、业务流（Flows）与执行步骤（Steps）。 |
| `/understand-explain <path>` | 单点精读 | 深度解读指定的类、函数或文件（例如 `/understand-explain src/auth/jwt.ts`）。 |
| `/understand-diff` | 变更影响评估 | 在 Git 提交前分析当前修改会引发哪些上下游波动与连锁反应。 |
| `/understand-onboard` | 生成新人上手文档 | 自动生成依赖拓扑友好的新人漫游指南（Guided Tours）。 |
| `/understand-chat <问题>` | 针对图谱的语义问答 | 结合已构建的图谱结构解答宏观业务和架构疑问。 |

> **提示**：团队协作时可将生成的 `.ua/knowledge-graph.json` 提交到 Git。其他人无需消耗 LLM Token，仅需使用 Node.js 查看器即可离线浏览：
> ```bash
> npx https://github.com/Egonex-AI/Understand-Anything/releases/latest/download/understand-anything-viewer.tgz .
> 
> ```
> 
> 

---

## 三、 开源项目全流程理解手册（四大维度）

在实际阅读一个全新的开源项目时，配合 Understand-Anything 的**内置技能与定制提示词（Prompts）**，可以按照以下四个阶段展开：

### 1. 接口层（Interfaces / APIs）分析

**核心目标**：梳理对外暴露的 API（HTTP REST、RPC、CLI、SDK Export），弄清系统边界。

* **使用技能/命令**：
* 运行 `/understand` 后，在 Dashboard 中筛选 **API / Controller** 分层节点。
* 针对接口入口文件运行 `/understand-explain <controller_file>`。


* **推荐提示词**：
```markdown
请基于当前项目的知识图谱和路由配置，为我梳理系统的所有外部接口：
1. 列出核心 HTTP 路由 / RPC 服务的入口文件与对应处理函数。
2. 提取公共 Request 结构体、Query 参数校验逻辑与统一 Response 规范。
3. 识别出接口调用的通用切面（如 JWT 鉴权、Rate Limiting、中间件链路），并用时序图展示一个请求从进入系统到返回的全过程。

```



---

### 2. 业务逻辑（Business Logic）分析

**核心目标**：脱离单纯的文件结构，弄清“这个项目到底在解决什么具体业务问题，主流程是怎样流转的”。

* **使用技能/命令**：
* 执行 `/understand-domain`：提取 Domain 模型与 Flow。
* 执行 `/understand-chat` 进行宏观问答。


* **推荐提示词**：
```markdown
请结合 /understand-domain 的提取结果，帮我分析此项目的核心业务流程：
1. 梳理主要领域实体（Domain Entities）及其生命周期状态机变化。
2. 挑选出系统最核心的主干业务流（例如“下单-支付-发货”或“任务创建-调度-执行”），画出流程图并标注每个步骤对应的 Service 类和函数。
3. 指出业务逻辑中的异常边界处理方案（如幂等校验、补偿事务、失败重试机制）。

```



---

### 3. 数据处理与存储（Data Processing）分析

**核心目标**：掌握数据是如何被摄入、清洗、转换、落库与缓存的。

* **使用技能/命令**：
* 在 Dashboard 中过滤 **Data / Model / Repository / Pipeline** 节点。
* 执行 `/understand-explain` 针对 ORM 模型文件或 ETL 处理管道。


* **推荐提示词**：
```markdown
请深入分析本项目的数据流转与处理机制（Data Processing Pipeline）：
1. 数据流向拓扑：数据从外部输入到落入持久层，经历了哪些 DTO -> Domain Model -> PO 的映射与转换？
2. 存储与缓存层设计：项目使用了哪些数据库（Postgres, Mongo 等）与缓存（Redis）？其核心索引和表关联关系是怎样的？
3. 异步/批处理数据：项目中是否存在消息队列（Kafka/RabbitMQ）或后台定时任务？消息生产者和消费者的具体实现逻辑是什么？

```



---

### 4. 架构全貌与变更影响（Architecture & Impact）

**核心目标**：整体架构分层设计、设计模式应用，以及代码修改时的波及面。

* **使用技能/命令**：
* `/understand-onboard`：梳理渐进式学习路线。
* `/understand-diff`：在开发分支提交前做连带依赖影响检查。


* **推荐提示词**：
```markdown
我想作为核心贡献者参与此项目，请提供架构指南：
1. 项目采用了哪种架构风格（如 Clean Architecture, Hexagonal, 经典三层或微内核插件式）？各层之间的单向依赖规则是什么？
2. 代码中高频使用了哪些设计模式（如工厂、策略、观察者、装饰器）？请结合 2 个具体代码实例讲解其用法。
3. 如果我需要扩展一个新的功能插件/业务分支，推荐遵循哪个现有的模板文件开发？需要修改哪些注册表或工厂配置？

```



---

## 四、 最佳实操工作流建议

1. **第一天（宏观把控）**：克隆仓库 $\rightarrow$ 运行 `/understand --language zh` $\rightarrow$ 启动 `/understand-dashboard` $\rightarrow$ 执行 `/understand-onboard`，了解分层与模块边界。
2. **第二天（业务与数据）**：运行 `/understand-domain` $\rightarrow$ 结合提示词探索核心业务流与数据处理管道。
3. **日常开发（局部深入与校验）**：修改局部代码 $\rightarrow$ 执行 `/understand-diff` 检查上下游依赖受击面 $\rightarrow$ 确保改动不破坏核心流程。