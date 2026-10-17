---
title: "【故障变更】SonarScanner for Maven 3.11.0.3922 内网离线下载与 Nexus 上传手册"
type: note
status: active
scope: devops_sonarqube
created: 2026-09-14 10:30:00
updated: 2026-09-14 11:30:00
summary: "解决 mvn sonar 报 PluginResolutionException（nexus.maven-public 仅有旧版 sonar-maven-plugin 3.6.0.1398）的问题：列出缺失构件清单，指导在外网机器上批量下载插件及运行时依赖（附带 maven-dependency-plugin 辅助列与依赖用 pom），并手工上传内网 Nexus 后恢复扫描。经实测修正：配套 API 版本为 2.16.3.1081，central 无 sonar-scanner-engine-shaded 构件（引擎由扫描客户端运行时从 SonarQube 服务端获取）；另记录 Java 25 下 cacerts 软链失效的 TLS 修复方案。"
keywords: [sonarqube, sonar-maven-plugin, maven, nexus, offline, dependency, scan-java, tls, cacerts]
verification: "curl -s http://nexus.cdvire.cn/repository/maven-public/org/sonarsource/scanner/maven/sonar-maven-plugin/3.11.0.3922/sonar-maven-plugin-3.11.0.3922.pom 返回 XML；随后 mvn ...:sonar 插件解析成功"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> `scan-java.sh` 通过 `sonar-maven-plugin:3.11.0.3922` 上报 Java 工程。执行时报
> `Could not find artifact ... in nexus (http://nexus.cdvire.cn/repository/maven-public/)`，
> 说明内网 Nexus 仓库中缺少该版本的插件及其依赖。
> 本文档指导：① 在外网机器上一次性下载全部缺失构件；② 手工上传内网 Nexus；③ 验证恢复。

## 🔍 现状探测结论（内网 Nexus `maven-public`）

| GAV 坐标 | Nexus 现状 |
|---------|-----------|
| `org.sonarsource.scanner.maven:sonar-maven-plugin` | ⚠️ 仅旧版 `3.6.0.1398`，缺 `3.11.0.3922` |
| `org.sonarsource.scanner.api:sonar-scanner-api` | ⚠️ 仅旧版 `2.12.0.1661`，缺 `2.16.3.1081` |
| `org.sonarsource.scanner.engine:sonar-scanner-engine-shaded` | ⚠️ 无需上传：该构件在 Maven Central 不存在（2026-09-14 实测目录 404），扫描引擎由客户端运行期从 SonarQube 服务端下载 |
| `org.sonarsource.api:sonar-api` | ❌ 完全缺失（若解析时实际需要再补） |
| `org.codehaus.plexus:plexus-utils` / `org.sonatype.plexus:plexus-sec-dispatcher` / `commons-lang:commons-lang` | ✅ 已有，无需下载 |

## ⚙️ 核心内容

### 1. 需要上传的构件清单（pom + jar 各一份）

| # | GAV 坐标 | Nexus 路径（GAV 目录结构） |
|---|---------|---------------------------|
| 1 | `org.sonarsource.scanner.maven:sonar-maven-plugin:3.11.0.3922` | `org/sonarsource/scanner/maven/sonar-maven-plugin/3.11.0.3922/` |
| 2 | `org.sonarsource.scanner.api:sonar-scanner-api:2.16.3.1081` | `org/sonarsource/scanner/api/sonar-scanner-api/2.16.3.1081/` |

> [!IMPORTANT]
> 版本以 `sonar-maven-plugin:3.11.0.3922` 的 pom 依赖为准（实测为 Scanner API `2.16.3.1081`，非早期推测的 `2.16.1.1778`，后者在 Central 不存在）。
> `sonar-scanner-api` 为 shaded 包，内含 `sonar-scanner-api-batch` 接口；完整扫描引擎由运行期
> 从 SonarQube 服务端 `/api/scanner/engine` 获取，**中央仓库与内网 Nexus 均无需此构件**。

### 2. 方式 A：用 `dependency:get` 自动解析真实依赖树（推荐）

在外网机器（可访问 Maven Central）执行，自动下载插件及其全部传递依赖：

```bash
mvn org.apache.maven.plugins:maven-dependency-plugin:3.6.1:get \
  -Dartifact=org.sonarsource.scanner.maven:sonar-maven-plugin:3.11.0.3922
```

查看实际依赖树，确认上表第 2 项的真实版本：

```bash
mvn org.apache.maven.plugins:maven-dependency-plugin:3.6.1:tree \
  -Dincludes=org.sonarsource*:*
```

产物位于本地仓库 `~/.m2/repository/org/sonarsource/...`，按「1. 构件清单」挑出所需 `.jar` 与 `.pom` 上传即可。

### 3. 方式 B：使用旁附 pom 一键平铺下载

旁附文件 `20260914-sonar-maven-plugin-3.11.0.3922-deps.pom` 已显式声明插件及依赖（版本已按 Central 实测修正），直接拷贝后运行：

```bash
mvn -f 20260914-sonar-maven-plugin-3.11.0.3922-deps.pom \
  org.apache.maven.plugins:maven-dependency-plugin:3.6.1:copy-dependencies \
  -DoutputDirectory=./sonar-deps -DincludeScope=runtime

# 查看下载结果（平铺 jar，文件名 = <artifact>-<version>.jar）
ls -lh ./sonar-deps/
```

> [!WARNING]
> `copy-dependencies` 只输出 `.jar`。GAV 对应的 `.pom` 也已自动下载到
> `~/.m2/repository` 对应目录下，上传时一并取用；也可从 Maven Central 直接下载
> `https://repo1.maven.org/maven2/<GAV路径>/*.pom`。
> 若报 `Could not find artifact`，说明 pom 中声明的版本与 Central 实际不符，按报错修正版本即可。

### 3.1 常见坑：Java 25 下 https 下载报 `trustAnchors parameter must be non-empty`

> [!IMPORTANT]
> 现象：外网机器执行上述任意 mvn 下载命令时，`Downloading from central` 后立刻
> `BUILD FAILURE ... java.security.InvalidAlgorithmParameterException: the trustAnchors parameter must be non-empty`。
> 根因（Ubuntu + 外部安装的 OpenJDK 常见）：`$JAVA_HOME/lib/security/cacerts` 是指向 RHEL 路径的
> 失效软链（如 `-> /etc/pki/ca-trust/extracted/java/cacerts`，该路径在 Ubuntu 上不存在）。
> 解决：运行 mvn 前注入 Ubuntu 的 CA 库即可，无需 root：

```bash
export MAVEN_OPTS="-Djavax.net.ssl.trustStore=/etc/ssl/certs/java/cacerts"
```

> 验证修复：`/opt/openjdk-25/lib/security/cacerts` 为 broken symlink；
> `/etc/ssl/certs/java/cacerts` 由 `ca-certificates-java` 生成。
> 如需永久修复（可选，需 root `sudo ln -sf /etc/ssl/certs/java/cacerts $JAVA_HOME/lib/security/cacerts`）。

### 4. 上传到内网 Nexus

`maven-public` 是 group 仓库（只读），必须上传到其 **hosted 成员仓库**（如 `maven-releases`）：

```bash
BASE=http://nexus.cdvire.cn/repository/maven-releases
NEXUS_USER=<用户名>
NEXUS_PASS=<密码>

# 以插件本体为例（每个构件传 jar + pom 两个文件，其余构件类推）
G=org/sonarsource/scanner/maven
V=3.11.0.3922
curl -u "${NEXUS_USER}:${NEXUS_PASS}" --upload-file "sonar-maven-plugin-${V}.jar"  "${BASE}/${G}/sonar-maven-plugin/${V}/sonar-maven-plugin-${V}.jar"
curl -u "${NEXUS_USER}:${NEXUS_PASS}" --upload-file "sonar-maven-plugin-${V}.pom"  "${BASE}/${G}/sonar-maven-plugin/${V}/sonar-maven-plugin-${V}.pom"

# 剩余一个构件（g 用对应 GAV 目录）：
#   org/sonarsource/scanner/api/sonar-scanner-api/2.16.3.1081/...
```

### 5. 验证

```bash
# 1) 确认 maven-public（group）可读取到新版本
curl -s http://nexus.cdvire.cn/repository/maven-public/org/sonarsource/scanner/maven/sonar-maven-plugin/3.11.0.3922/sonar-maven-plugin-3.11.0.3922.pom | head -5

# 2) 在扫描机重新执行 Java 扫描
./scan-java.sh -k <项目key> /data/projects/<项目目录>
```

### 6. 异常补充

- 若扫描时仍报缺 `org.sonarsource.api:sonar-api`：按「方式 B」同样的流程补上传
  `org/sonarsource/api/sonar-api/<版本>/sonar-api-<版本>.{jar,pom}`。
- ⚠️ 若在中央仓库/内网仓库中找不到 `sonar-scanner-engine-shaded`，属正常现象——该构件不存在，
  引擎由扫描客户端在连接服务端后自动获取；请勿尝试按旧版本文档上传。
- 若不想上传新版本，可临时将 `scan-java.sh` 中 `MAVEN_PLUGIN_VERSION` 改为 nexus 已有的
  `3.6.0.1398`（需确认与 SonarQube 服务端版本兼容，且解码器与旧 API 不匹配时仍会失败）。

## 📎 参考

- 官方插件仓库（Maven Central）：`https://repo1.maven.org/maven2/org/sonarsource/scanner/maven/sonar-maven-plugin/`
- 旁附 pom：`docs/devops_sonarqube/20260914-sonar-maven-plugin-3.11.0.3922-deps.pom`