# 📖 运维手册总索引

> 自动维护，每次新增/修改文档后需刷新。
>
> 归档规则：采用**扁平化的两级目录结构** `docs/<领域分类_组件名>/`，按“面向事务”的领域_组件方式命名，**不再区分操作系统与环境**。文件名统一 `YYYYMMDD-<英文-kebab-case-描述>.md`。

## 目录索引

### 🖥️ 操作系统与主机基础设施（os_*）

- **os_apt**
  - [Ubuntu20.04 内网 APT 镜像源不完整导致 apt update 404 的排查与修复](os_apt/20260912-ubuntu20-apt-mirror-incomplete-fix.md)
- **os_alternatives**
  - [update-alternatives 作用、原理与常用使用场景](os_alternatives/20260924-update-alternatives-guide.md)
- **os_chrony**
  - [Chrony 安装与 Aliyun NTP 时间同步配置（含内网 NTP Server）](os_chrony/20260701-chrony-install-aliyun-ntp.md)
- **os_ssh**
  - [SSH 公钥已安装却仍要密码：StrictModes 权限拒绝排查与修复](os_ssh/20260912-ssh-pubkey-strictmodes-permission-fix.md)
- **os_storage**
  - [LVM 释放 data 逻辑卷空间合并至根目录](os_storage/20260801-lvm-data-lv-merge-to-root.md)
  - [Linux Mint NTFS 分区转换为 ext4 并配置 fstab 自动挂载](os_storage/20260815-ntfs-to-ext4-fstab-automount.md)
  - [Linux bind mount 单盘挂载到多个目录（含 fstab 持久化）](os_storage/20260817-bind-mount-multiple-directories.md)
- **os_network**
  - [V2Ray 安装配置与代理管理指南](os_network/20260617-v2ray-install-config-guide.md)
  - [V2Ray 代理配置错误排查（outbound 协议 / HTTP 与 SOCKS 端口分离）](os_network/20260601-v2ray-config-troubleshooting.md)
  - [KVM 虚拟机桥接网卡部署指南（局域网直连 + 静态 IP）](os_network/20260904-kvm-bridge-network-guide.md)
  - [远程主机容器 GUI 显示到本机 X11（TCP 监听 + xhost 放行）](os_network/20260917-remote-container-x11-display-tcp-guide.md)
  - [代理订阅链接备份](os_network/20260930-proxy-subscription-backup.md)（⚠️ 含订阅令牌，勿外泄）
- **os_desktop**
  - [AppImage 应用安装模式总结（直接运行 / 安装到 /opt + 桌面集成）](os_desktop/20260601-appimage-install-patterns.md)
  - [AppImage 版 Obsidian 点击 obsidian:// 链接报「无法理解该网址」：Electron 协议处理器只认 CHROME_DESKTOP 的根因与修复](os_desktop/20261017-obsidian-appimage-url-scheme-handler.md)（含 `scripts/devops/obsidian-appimage-integrate.sh`）
  - [fcitx5 五笔输入法安装记录（替代搜狗）](os_desktop/20260601-fcitx5-wubi-install.md)
  - [Firefox 浏览器卸载记录](os_desktop/20260601-firefox-uninstall-record.md)
- **os_display**
  - [换显示器后 Cinnamon 双屏只亮一个桌面：第二块显示器被布局配置禁用（含改配置后需重载会话方生效的复发处置）](os_display/20261009-cinnamon-dual-monitor-second-disabled-fix.md)
- **os_systemd**
  - [AppImage 报 dlopen(): error loading libfuse.so.2 的排查与修复（Ubuntu 24.04+ 缺 libfuse2）](os_systemd/20261017-appimage-libfuse2-missing.md)
- **os_wsl**
  - [WSL2 运行 Linux 桌面程序并在 Windows 显示（WSLg X11/Wayland 配置）](os_wsl/20260802-wslg-gui-display-config.md)

### 🧰 开发与运维工具链（devops_*）

- **devops_docker**
  - [Docker 引擎与 Compose 插件安装记录（腾讯云源）](devops_docker/20260601-docker-engine-install-record.md)
  - [Podman 安装配置与离线部署指南](devops_docker/20260817-podman-install-config-guide.md)
  - [离线 Docker 镜像批量导入内网 Harbor（mailcow 离线包实测）](devops_docker/20261012-harbor-batch-push-offline-images.md)（含 `scripts/harbor/push-images-to-harbor.sh`）
- **devops_shell**
  - [Bash-it 安装配置与使用手册](devops_shell/20260610-bashit-install-config-guide.md)
  - [ldd_install.sh 动态库依赖收集脚本与 CMake 集成指南](devops_shell/20260828-ldd-install-script-cmake-integration.md)
  - [fd + fzf 安装配置与常用查找命令使用手册](devops_shell/20260920-fd-fzf-install-usage-guide.md)
- **devops_editor**
  - [vim 安装与依赖修复记录](devops_editor/20260601-vim-install-record.md)
  - [micro 终端文本编辑器：功能说明、使用手册、配置与插件管理指南](devops_editor/20260930-micro-editor-install-config-guide.md)（含 `scripts/editor/micro_setup.sh`）
  - [micro 配置离线包制作与内网离线安装指南](devops_editor/20260930-micro-offline-config-install-guide.md)（含 `scripts/editor/micro_offline_install.sh`）
- **devops_terminal**
  - [Tabby 终端 AppImage 安装到 /opt 与桌面集成记录](devops_terminal/20260601-tabby-appimage-install.md)
- **devops_gitclient**
  - [标准 git CLI 命令行全流程操作指南](devops_gitclient/20260912-git-cli-operations-guide.md)
  - [gitui TUI 终端 Git 客户端安装与全流程操作指南](devops_gitclient/20260912-gitui-operations-guide.md)
  - [lazygit TUI 终端 Git 客户端安装与全流程操作指南](devops_gitclient/20260912-lazygit-operations-guide.md)
  - [git worktree 多工作目录使用手册（含子模块场景）](devops_gitclient/20260912-git-worktree-guide.md)
  - [git 子模块（submodule）操作手册：地址迁移/分支关联策略/常用命令与使用场景大全](devops_gitclient/20260914-git-submodule-guide.md)
  - [git status 中文文件名八进制转义（core.quotepath）排查与修复](devops_gitclient/20260928-git-quotepath-chinese-filename.md)
  - [Git LFS 安装、配置与常用二进制文件跟踪指南](devops_gitclient/20260930-git-lfs-install-config-guide.md)（含 `scripts/git/git_lfs_setup.sh`）
  - [工程目录二进制/大文件扫描与外置规范（默认落到 ~/.work_linux_working/）](devops_gitclient/20261017-repo-binary-artifacts-externalize.md)（含扫描/搬出脚本 `~/.work_linux_working/scan/`：`scan-binaries.sh`、`move-binaries-out.sh`）
  - [本地仓库历史压缩：142 条提交压为单一快照并压缩对象库](devops_gitclient/20261017-repo-history-squash-local-compaction.md)（.git 91 MB → 1.9 MB；含 bundle 备份与受保护分支推送受阻说明）
- **devops_gitea**
  - [Gitea 作为内网私有 Go Module 源（配置/上传/下载/工程集成）指南](devops_gitea/20260930-gitea-go-module-registry-guide.md)（含 `scripts/go/gitea_go_upload.sh`、`scripts/go/gitea_go_download.sh`）
- **devops_gitlab**
  - [GitLab 数据恢复报 pg_trgm/btree_gist 扩展 owner 权限错误修复](devops_gitlab/20260707-gitlab-pg-extension-owner-restore-fix.md)
- **devops_go**
  - [基于基础镜像与 QEMU 的多架构 Go 模块离线包构建指南（含指定包全量依赖收集）](devops_go/20260929-go-mod-offline-cross-arch-bundle-guide.md)
  - [gitea_go_upload.sh 使用指南：将 Go module zip 批量上传到 Gitea 私有 Go 源](devops_go/20260930-gitea-go-upload-script-usage-guide.md)
  - [Gitea 内网无法下载指定 Go 依赖的根因分析与离线包补全方案](devops_go/20260930-go-mod-bundle-incomplete-root-cause-and-offline-fix.md)
  - [go.sum 作用、可删除性及跨架构一致性辨析](devops_go/20260930-go-sum-explained-and-cross-arch-consistency.md)
- **devops_python**
  - [pip download 跨平台/版本依赖包下载指南](devops_python/20260717-pip-download-cross-platform.md)
  - [Python3.11 glibc2.27 跨架构 markdown 生态离线 wheel 下载指南](devops_python/20260911-pip-download-markdown-ecosystem-wheels.md)
- **devops_vscode**
  - [VS Code 桌面版 deb 安装指南](devops_vscode/20260601-vscode-desktop-deb-install.md)
  - [VS Code 命令行插件安装与离线部署指南](devops_vscode/20260817-vscode-cli-ext-install-guide.md)
- **devops_opencode**
  - [opencode 命令行工具二进制安装记录（代理下载 + ripgrep/fzf 依赖）](devops_opencode/20260601-opencode-binary-install-record.md)
  - [非 root 用户运行 opencode 阻塞问题修复](devops_opencode/20260815-opencode-nonroot-user-block-fix.md)
  - [opencode 启动缓慢根因分析与 npm 插件依赖离线化处置](devops_opencode/20260930-opencode-slow-startup-npm-install-offline.md)（含 `scripts/devops/opencode_npm_offline.sh`、`scripts/devops/opencode_offline/serve-registry.py`）
  - [skill-creator 技能创建器：离线安装、使用手册、常用案例与技能调校技巧](devops_opencode/20261008-skill-creator-offline-install-usage-guide.md)（含 `scripts/opencode/skill_offline_install.sh`）
  - [多子模块（git submodule）工程的 OpenCode 上下文切换与父子协作规范](devops_opencode/20261017-multi-submodule-context-switching.md)（含 `/ctx` 命令与 `sub-<模块>` 子代理模板、模块注册表与父子文档/技能关联契约）
- **devops_herdr**
  - [herdr 终端多路复用与 AI 编码 Agent 运行时：配置方式、常用操作、Workspace 拆分与 worktree 场景、效率提升与使用技巧](devops_herdr/20260930-herdr-install-config-usage-guide.md)
- **devops_ai_agent**
  - [工程内 AI 技能（Skills）的跨 Agent 管理与放置标准](devops_ai_agent/20260930-project-ai-skills-placement-standard.md)
  - [Agent-Reach 自建容器镜像与内网离线部署手册（零配置核心渠道 + 批量测试）](devops_ai_agent/20261013-agent-reach-container-offline-deploy.md)（含离线 bundle `/home/vire/_docker-packages/agent-reach/`：`deploy.sh`、`build.sh`、`export.sh`、`tests/run-tests.sh`）
  - [TencentDB Agent Memory 三件套 Docker 内网离线部署手册（官方镜像 + 官方脚本编排）](devops_ai_agent/20261013-tencentdb-agent-memory-docker-offline-deploy.md)（含离线 bundle `/home/vire/_docker-packages/tencentdb-agent-memory/`：`deploy.sh`、`export.sh`、`images/`、`global-images/`）
- **devops_code_analysis**
  - [C/C++ 代码分析工具链：快速部署、接口/业务链扫描与单元测试体系实施方案](devops_code_analysis/20261009-code-analysis-toolchain-deployment-guide.md)（含 `scripts/code_analysis/`：安装、离线打包、接口扫描、静态分析、单测脚手架、覆盖率、业务链追踪、code-review-graph 多语言接口手册、Understand-Anything 业务域图谱、Dockerfile）
  - [Node.js / Java / C++ 自动化测试工具链与离线包清单（Python 3.11 / JDK≥8 / glibc≤2.27）](devops_code_analysis/20261009-nodejs-java-cpp-testing-toolchain-package-list.md)
  - [C++ 第三方库与 GitHub 开源地址（测试/质量 + 常见引擎依赖）](devops_code_analysis/20261009-cpp-testing-libraries-and-repos.md)
  - [ast-grep：AST 结构化搜索/重写工具的安装、离线部署与使用手册](devops_code_analysis/20261012-ast-grep-install-usage-guide.md)（含 `scripts/code_analysis/install_ast_grep.sh`、`download_ast_grep_bundle.sh`）
  - [code-graph-rag（cgr）：多语言代码知识图谱/RAG 的部署、离线打包与使用手册](devops_code_analysis/20261012-code-graph-rag-install-usage-guide.md)（含 `scripts/code_analysis/install_code_graph_rag.sh`、`download_code_graph_rag_bundle.sh`）
  - [Understand-Anything：代码业务语义知识图谱/用例生成引擎的安装、离线部署与使用手册](devops_code_analysis/20261012-understand-anything-install-usage-guide.md)（含 `scripts/code_analysis/install_understand_anything.sh`）
- **devops_crawler_to_md**
  - [crawler-to-md 容器：把文档站点抓取并生成 Markdown/JSON 的使用指南](devops_crawler_to_md/20261013-crawler-to-md-doc-download-guide.md)
- **devops_sonarqube**
  - [SonarQube 静态代码问题 API 报告生成脚本（CSV 输出）使用指南](devops_sonarqube/20260911-sonarqube-api-report-csv-guide.md)
  - [SonarScanner for Maven 3.11.0.3922 内网离线下载与 Nexus 上传手册](devops_sonarqube/20260914-sonar-maven-plugin-offline-download-upload-guide.md)

### 🏗️ 构建与依赖（build_*）

- **build_cmake**
  - [通用 C++ 工程依赖库打包工具：package_cpp_deps.py（按依赖闭包打包 + 打包后自校验）](build_cmake/20261013-cpp-deps-python-package-tool.md)（含 `scripts/build/package_cpp_deps.py`：依赖闭包、无用库清理、跨平台 Linux/macOS/Windows、打包后自校验）
  - [Model_Service CMake 安装包缺失三方库 .so：install_linux_3rds 根目录变量回退缺失导致打包被跳过](build_cmake/20261013-model-service-install-3rds-so-missing-fix.md)（该 CMake 机制已被上述 Python 脚本取代）

### 📦 应用与平台部署（app_*）

- **app_dify**
  - [Dify 容器版本地部署手册](app_dify/20260613-dify-docker-compose-deploy.md)
- **app_n8n**
  - [使用 Docker 部署 n8n 工作流自动化工具（中文汉化版）](app_n8n/20260605-n8n-docker-deploy.md)
- **app_qanything**
  - [使用 Docker Compose 部署 QAnything v2.0.0 本地知识库问答系统](app_qanything/20260605-qanything-docker-deploy.md)
- **app_filestash**
  - [Filestash Web 文件管理器部署（SFTP 远程管理 + LDAP 认证）](app_filestash/20260605-filestash-docker-deploy.md)
- **app_ops_platform**
  - [OpenWebUI + Dify + n8n 容器化运维平台部署指南](app_ops_platform/20260609-openwebui-dify-n8n-deploy-guide.md)
- **app_outline**
  - [Outline 内网知识库 Docker Compose 部署手册（HTTPS + 邮件登录）](app_outline/20260930-outline-deployment-guide.md)
  - [Outline 内网知识库配置与使用手册（邮件登录/团队/存储/API/备份）](app_outline/20260930-outline-configuration-guide.md)
  - [Outline 内网知识库数据备份与迁移手册（全量备份脚本 + 异地迁移）](app_outline/20261015-outline-backup-migration-guide.md)（含 `scripts/backup/outline_backup.sh`）

### 📧 邮件（mail_*）

- **mail_mailu**
  - [MaILU 2024.06 内网邮箱服务 Docker Compose 部署手册（HTTPS）](mail_mailu/20260930-mailu-deployment-guide.md)
  - [MaILU 2024.06 内网邮箱服务配置与使用手册（客户端/域名/用户/API/DKIM）](mail_mailu/20260930-mailu-configuration-guide.md)
- **mail_mailcow**
  - [mailcow 私有邮件服务器 Docker Compose 内网部署手册（HTTPS 自签 + 离线打包，非 LDAP）](mail_mailcow/20261012-mailcow-docker-deploy-guide.md)（含 `_docker-packages/mailcow/`：compose、deploy/export 脚本、images 离线包、README-OFFLINE.md）
  - [mailcow LDAP 集成部署手册（Identity Provider / 属性映射 / 自动开通 / 自定义 CA）](mail_mailcow/20261012-mailcow-ldap-deploy-guide.md)（含 `_docker-packages/mailcow/ldap/`：conf.example、docker-compose.override.yml）
  - [mailcow 配置变更与 LDAP/SSO 故障排查 FAQ（域名/SSL/端口 + 用户同步/登录/收发邮件）](mail_mailcow/20261012-mailcow-config-change-and-troubleshooting-faq.md)
- **mail_stalwart**
  - [Stalwart v0.16.26 邮件/协作服务器 Docker 内网离线部署手册](mail_stalwart/20261012-stalwart-docker-offline-deploy.md)（含离线 bundle `/home/vire/_docker-packages/stalwart`）

### 🔐 安全（security_*）

- **security_vaultwarden**
  - [Vaultwarden 局域网自建部署与离线客户端同步说明](security_vaultwarden/20261009-vaultwarden-lan-deploy-notes.md)
  - [Vaultwarden 容器化离线部署指南（Docker Compose + Caddy HTTPS + 离线镜像）](security_vaultwarden/20261009-vaultwarden-docker-offline-deploy.md)（含离线 bundle `软件部署/vaultwarden/`）

### 🌐 Web 服务（web_*）

- **web_caddy**
  - [Caddy 服务详解与内网邮件服务（MaILU）HTTPS 适用性分析](web_caddy/20261009-caddy-guide-and-mailu-https-applicability.md)
- **web_nginx**
  - [Nginx 端口修改（80→45723）与 APT 本地镜像源配置](web_nginx/20260605-nginx-port-change-apt-mirror.md)
  - [Nginx 静态文件 403 Permission Denied 排查与修复](web_nginx/20260717-nginx-403-permission-denied-file-permission.md)

### 💾 存储（storage_*）

- **storage_s3**
  - [S3 对象存储选型指南：MinIO / RustFS / Garage 对比与分布式部署决策](storage_s3/20260912-s3-storage-selection-guide.md)
- **storage_minio**
  - [MinIO 多节点集群部署与数据备份恢复完整指南](storage_minio/20260912-minio-distributed-backup-restore-guide.md)
- **storage_rustfs**
  - [RustFS S3 安装配置、Web 控制台管理、平滑迁移/扩展升级指南](storage_rustfs/20260912-rustfs-s3-ops-guide.md)
- **storage_garage**
  - [Garage S3 安装配置、多节点集群与数据备份恢复指南（含 S3 兼容切换）](storage_garage/20260912-garage-s3-ops-guide.md)

### 🖧 虚拟化（virtualization_*）

- **virtualization_kvm**
  - [KVM 安装 Windows 10 虚拟机完整指南](virtualization_kvm/20260817-kvm-win10-vm-install-guide.md)
  - [KVM 安装 Rocky Linux 9.8 虚拟机完整指南](virtualization_kvm/20260904-rocky9-vm-install-guide.md)
  - [Rocky Linux 9.8 虚拟机磁盘在线扩容至 500G 实战指南](virtualization_kvm/20260904-rocky9-vm-disk-expand-guide.md)
  - [KVM 虚拟化常用操作命令与使用方法大全](virtualization_kvm/20260906-kvm-common-operations-guide.md)
  - [KVM 创建 Ubuntu 20.04 Desktop 虚拟机 ubuntu2004-dev（桥接+静态IP）](virtualization_kvm/20260912-ubuntu2004-dev-kvm-install-guide.md)
  - [KVM virsh 存储池路径修改与磁盘迁移指南](virtualization_kvm/20260817-kvm-virsh-storage-pool-path-config.md)
- **virtualization_qemu**
  - [QEMU 模拟 ARM64 系统与 multiarch user-static 使用指南](virtualization_qemu/20260902-qemu-arm64-emulation.md)

## 软件部署手册（外部目录）

- **sonarcube**
  - [SonarQube 静态代码检查工具 Docker Compose 部署手册](../软件部署/sonarcube/README.md)（含 `docker-compose.yml` 与 `.env.example`）
  - [SonarQube 生态协作工具链清单与使用场景](../软件部署/sonarcube/20260910-SonarQube-工具链协作清单.md)
  - [SonarQube 生产环境常用开源插件清单与安装兼容性指南](../软件部署/sonarcube/20260910-SonarQube-常用插件清单.md)
  - [多语言扫描脚本使用手册与默认检查标准配置（Node.js/Java/C++）](../scripts/sonarqube/nodejs_scanner/README.md)（含 `scan-*.sh` 脚本、`sonar-*.properties`、各 `<type>_scanner/.env` 与 `scripts/sonarqube/batch-release-scan.sh`）
  - [各语言检查要点与修复指南（总索引，按 nodejs/java/cpp 分子目录）](../软件部署/sonarcube/check-standards/README.md)
- **find_tools**
  - [Linux 快速文件查找工具选型与组合使用指南（Everything 平替方案）](../soft/find_tools/20260910-linux-file-search-tools-guide.md)
- **vaultwarden**
  - [Vaultwarden 离线部署包使用说明](../软件部署/vaultwarden/README.md)（含 `docker-compose.yaml`、`.env.example`、`export.sh`、`deploy.sh`）

## 已迁移（子模块）

- **app_wikijs**（已迁移 → 子模块 `submodule/wiki-js`，主仓库不再维护 wiki-js/AI 相关文档与脚本）
  - [Wiki.js 文档自动化运维套件（技能/脚本/手册总索引）](../submodule/wiki-js/docs/README.md)
  - [Wiki.js 双通道同步实施手册（唯一写通道 + MinIO 图床 + AI 线下 MR）](../submodule/wiki-js/docs/wikijs-ai-offline-git-sync-plan.md)
  - [Wiki.js GraphQL 批量上传与更新页面脚本使用指南](../submodule/wiki-js/docs/wikijs-graphql-batch-sync-guide.md)