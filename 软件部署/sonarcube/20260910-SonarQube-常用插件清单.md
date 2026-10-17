---
title: "【运维参考】SonarQube 生产环境常用开源插件清单与安装兼容性指南"
type: note
status: active
scope: ubuntu_prod
created: 2026-09-10 12:30:00
updated: 2026-09-10 12:30:00
summary: "梳理 SonarQube 生产环境可用的开源插件（官方 Marketplace 与第三方 GitHub 两类）、下载来源、安装方式及大版本兼容性注意事项，并说明社区版安全能力补充的正确姿势。"
keywords: [sonarqube, plugin, marketplace, community-branch-plugin, chinese-pack, dependency-check, opensource, prod]
verification: "登录 SonarQube UI，Administration -> Applications 查看插件已加载；或 curl http://<host>:9000/api/plugins/installed"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> SonarQube 7.9+ 起，语言分析器（Java、JS/TS、Python、Go、C#、C/C++ 等）已全部内置在服务端，无需像旧版那样单独下载分析器插件。生产环境中真正需要"额外安装"的是**界面汉化、分支分析能力补强、依赖漏洞扫描（SCA）、代码风格规则补充**等扩展型插件。本文档给出这些开源插件的选型、下载来源、安装方法与生产兼容性要点。

## ⚙️ 核心内容

### 1. 需要明确的前提（少走弯路）

- **语言分析器不需要插件**：Java / JavaScript / TypeScript / Python / Go / C# / C++ / C 等扫描能力已内置，只要在扫描机器装好对应运行时（JDK、Node.js 等）+ sonar-scanner 即可。
- **不要乱装网上伪"pj 版商业插件"**：商业功能（如 Developer Edition 的完整分支分析、高级安全）在法律和稳定性上都不适合生产，应通过插件/工具链补强，详见第 4 节。

### 2. 官方便利渠道：Marketplace（Web 端）
> 安装位置：登录后有权限的账号 → **Administration → Applications → Marketplace**，搜索后点 Install，需重启生效。

| 插件 | 用途 | 备注 |
|------|------|------|
| **Chinese Pack（中文语言包）** | 将管理界面/部分报告汉化 | 开源，SonarSource Community 维护；安装后重启 |

> [!TIP]
> 若离线环境无法访问 Marketplace，将对应 `sonar-l10n-zh-plugin-*.jar` 从 GitHub Releases 下载后手动放入扩展目录，见第 4 节。

### 3. 生产高频开源插件清单

按是否需要手动下载分为两类：

#### 3.1 需从 GitHub Releases 下载 jar 的插件

| 插件 | 仓库/作者 | 用途 | 适用版本 |
|------|----------|------|---------|
| **Community Branch Plugin（社区分支插件）** | `mc1arke/sonarqube-community-branch-plugin` | 让 **Community（社区版）** 支持 Branch / Pull Request 分析，MR 门禁可视化 | 需匹配 SonarQube 大版本（10.x 用 1.17+） |
| **Sonar Dependency Check（ODC）** | `stevespringett/dependency-track` 配套 `sonar-dependency-check` 插件 | 依赖组件 **CVE 漏洞扫描**，补社区版缺失的 SCA 能力 | 与 SonarQube 大版本对应 |
| **sonar-pmd** / **sonar-checkstyle** | `jensgerdes/sonar-pmd` 等社区仓库 | 将 PMD / Checkstyle 的 Java 风格规则并入 Quality Profile | 需匹配对应 SQ 版本 |
| **sonar-cxx** | `SonarOpenCommunity/sonar-cxx` | 社区版 C/C++ 规则增强（官方 C/C++ 为商业授权，社区版仅基本支持） | 与 SonarQube 大版本严格匹配 |

#### 3.2 其他可选的界面/多语言包
- `sonar-l10n` 派生各语言包（日文、德文等），生产通常只需中文包。

### 4. 安装方法与离线部署（Docker 环境）

#### 4.1 在线安装（有外网）
```bash
# Web 端操作：Administration → Applications → Marketplace → 搜索 → Install
# 或 API 安装（需 POST 请求，先获得 CSRF token）：
curl -X POST -u admin:xxxx \
  "http://localhost:9000/api/plugins/install?key=l10nzh"
```
> API 自动安装后仍需**重启服务**生效。

#### 4.2 离线安装 / Docker 挂载扩展卷
```bash
# 1. 下载对应版本的 jar（务必匹配 SonarQube 大版本）
#    例如仓库中已有 Docker Compose 部署的 sonarqube_extensions 数据卷
docker volume inspect sonarqube_extensions
#    卷挂载点在容器内 /opt/sonarqube/extensions

# 2. 拷贝到宿主机对应扩展目录（以 Docker 卷为例，找到 mountpoint）
cp sonar-*.jar <mountpoint>/plugins/

# 3. 重启服务
docker compose restart sonarqube
# 或 (Docker 起容器)：docker restart sonarqube
```

#### 4.3 验证插件是否加载成功
```bash
# API 方式（无需 Web 端）
curl -s -u admin:xxxx http://localhost:9000/api/plugins/installed | grep -o 'key[^,]*'
# 或查看日志
docker logs sonarqube | grep -i 'plugin'
```

### 5. 生产环境使用注意（踩坑清单）

1. **版本必须严格匹配 SonarQube 大版本**：10.x 对插件 API 收紧，老 jar 会导致服务**启动失败**。安装前先确认 SonarQube 主版本号。
2. **先备份再升级**：升级插件前备份 `extensions/plugins`，并 stop 服务后替换，避免热替换损坏。
3. **不要贪多**：插件过多会拖慢启动（每个插件都有独立 scan 阶段），生产只保留必需项。
4. **分支插件与 Legal 顾虑**：Community Branch Plugin 商业授权需留意（仅源码开源、需自担使用风险），大版本升级前注意其上游是否停止维护——SonarSource 已将 Branch MTTP cap 放开有限范围，建议在 CI 上以主分支+PR 简化模式兜底。
5. **安全补强优先走工具链而非插件**：社区版没有 Developer Edition 高级安全能力，软件供应链扫描用 CI 侧 **Trivy / Dependency-Check / Grype** 更稳，方案见《SonarQube 生态协作工具链清单与使用场景》。

### 6. 一张图看清"需要/不需要"插件

| 场景需求 | 是否需要插件 | 推荐方案 |
|----------|-------------|---------|
| 分析 Java/JS/TS/Python/Go/C# | ❌ 不需要 | 内置分析器 + sonar-scanner |
| 中文界面 | ✅ 需要 | Chinese Pack |
| 社区版使用分支/MR 门禁 | ✅ 需要 | Community Branch Plugin |
| 依赖组件 CVE 扫描 | ✅ 建议 | Dependency-Check（CI 侧） |
| Java 代码风格规则补充 | ⏸ 可选 | sonar-pmd / sonar-checkstyle |
| C/C++ 高级规则 | ⚠️ 受限 | sonar-cxx 增强 / 商业版 |

## ✅ 验证命令
```bash
curl -s -u admin:xxxx http://localhost:9000/api/plugins/installed
# 预期：能看到 l10nzh（中文包）、community-branch 等已 installed
```

## 📎 参考
- SonarQube 官方插件文档：https://docs.sonarsource.com/sonarqube/latest/
- Community Branch Plugin：https://github.com/mc1arke/sonarqube-community-branch-plugin
- Dependency-Check(ODC)：https://github.com/stevespringett/sonar-dependency-check
- sonar-cxx：https://github.com/SonarOpenCommunity/sonar-cxx
- 相关沉淀：同目录《SonarQube 生态协作工具链清单与使用场景》、`scripts/sonarqube/*_scanner/README.md`