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
  - [AppImageLauncher 使用手册（AppImage 集成 / 桌面条目 / appimagelauncherd / ail-cli / 卸载清理）](os_desktop/20261019-appimagelauncher-usage-guide.md)
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

- **devops_ansible**
  - [Ansible 双模式软件运行环境安装基座（install_base + install_homebrew / install_ruby）](devops_ansible/20261018-ansible-dual-mode-install-base.md)（含 `scripts/ansible/`；online/offline 双模式、apt 国内镜像、包管理器等锁、快照回滚、状态标记、离线包制作分发）
  - [Node.js 工具链双模式安装（nvm + Node 22/24）](devops_ansible/20261019-ansible-nodejs-nvm-dual-mode-install.md)（含 `roles/install_nvm`、`roles/install_nodejs`；nvm 共享前缀 `/opt/nvm`、22/24 共存、wrapper 解决 ssh 非交互、离线包 nvm 85 KB + nodejs 91 MB 随包 libstdc++6）
- **devops_env_snapshot**
  - [Linux 开发环境整体离线快照（node/nvm + Homebrew 及 bottle 源 + Pi Agent 及插件技能 + oh-my-zsh）打包与复原手册](devops_env_snapshot/20261019-linux-devkit-offline-snapshot.md)（含 `scripts/devops/linux_devkit_pack.sh`；产物 `~/.work_linux_working/artifacts/linux-devkit-offline-20261019` 1.5 GB，bottle 57 个可直接当 HTTP 源，目标机 `install.sh --restore-cache` 一键复原 + `verify.sh` 自检）
- **devops_docker**
  - [Docker 引擎与 Compose 插件安装记录（腾讯云源）](devops_docker/20260601-docker-engine-install-record.md)
  - [Podman 安装配置与离线部署指南](devops_docker/20260817-podman-install-config-guide.md)
  - [离线 Docker 镜像批量导入内网 Harbor（mailcow 离线包实测）](devops_docker/20261012-harbor-batch-push-offline-images.md)（含 `scripts/harbor/push-images-to-harbor.sh`）
  - [Debian 13 沙箱开发容器镜像构建（Python 3.13 + uv + SSH）及 Ansible 接管验证](devops_docker/20261018-debian13-sandbox-image-python-uv-ssh.md)（含 `docker/debian13-sandbox/`、`scripts/ansible/`、批量测试脚本 `test-playbooks.sh`）
  - [Ubuntu 20.04 LTS 沙箱镜像构建（Python 3.12 + uv + SSH）](devops_docker/20261019-ubuntu2004-sandbox-image-python312-uv.md)（`docker/ubuntu20.04-sandbox/`，含 sshd `SetEnv` 注入 PATH、glibc 2.31 旧发行版验证场景）
  - [Debian 11 (bullseye) 沙箱镜像构建：与 ubuntu20.04-sandbox 环境包对齐（glibc 2.31）](devops_docker/20261019-debian11-sandbox-image-glibc231.md)（`docker/debian11-sandbox/`，SSH 22228；bullseye 已 EOL，走 aliyun `debian-archive` 归档源 + `Check-Valid-Until false`）
  - [Fedora 32 沙箱镜像构建：补齐 glibc 2.31 的 RPM 系空白](devops_docker/20261019-fedora32-sandbox-image-glibc231.md)（`docker/fedora32-sandbox/`，SSH 22227；禁用 metalink 改指 `archives.fedoraproject.org`；含 Ubuntu↔Fedora 包名映射表与 OpenSSH 8.3 兼容坑）
  - [跨发行版沙箱一致性校验脚本](devops_docker/20261019-fedora32-sandbox-image-glibc231.md#-关联文档)（`scripts/devops/sandbox-parity-check.sh`：对比 glibc / 依赖命令集 / uv / venv，`-e 2.31` 可指定期望 glibc）
- **devops_shell**
  - [Bash-it 安装配置与使用手册](devops_shell/20260610-bashit-install-config-guide.md)
  - [ldd_install.sh 动态库依赖收集脚本与 CMake 集成指南](devops_shell/20260828-ldd-install-script-cmake-integration.md)
  - [fd + fzf 安装配置与常用查找命令使用手册](devops_shell/20260920-fd-fzf-install-usage-guide.md)
  - [direnv 目录级环境变量管理：work_linux 仓库 .envrc + .env.default 落地手册](devops_shell/20261017-direnv-env-management.md)（含仓库文件 `.envrc`、`.env.default`）
  - [Linux Mint 环境 Oh My Zsh 安装配置与插件使用手册](devops_shell/20261020-oh-my-zsh-install-config-guide.md)（含 nvm / PATH 环境迁移、`/etc/profile.d` 补齐）
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
- **devops_homebrew**
  - [Homebrew（Linux/WSL2）在线安装、国内镜像加速与离线安装包制作手册](devops_homebrew/20261018-homebrew-install-config-guide.md)（含 `scripts/devops/homebrew_install.sh`、`scripts/devops/homebrew_offline_bundle.sh`）
- **devops_nodejs**
  - [通用 Node.js 运行时离线包制作与多版本共存部署手册（第一步）](devops_nodejs/20261017-nodejs-offline-runtime-bundle-guide.md)（含 `scripts/devops/nodejs_offline_bundle.sh`；官方纯净、同 dest 多版本并存、默认零污染、支持 `--activate`/`--link-bin`/`--uninstall`）
  - [nvm 配置管理与 Node.js 多版本切换手册（含国内镜像加速）](devops_nodejs/20261018-nvm-nodejs-version-management-guide.md)（nvm 0.40.3；git 安装 + npmmirror 加速 + default 别名 + .nvmrc；含本机 v22.23.3 → v24.22.0 满足 pi-cowboy 要求 Node ≥ 24.20.0 的实操）
- **devops_ohmyzsh**
  - [Oh My Zsh 在线安装、国内镜像加速与离线安装包制作手册](devops_ohmyzsh/20261018-ohmyzsh-install-config-guide.md)（含 `scripts/devops/ohmyzsh_install.sh`、`scripts/devops/ohmyzsh_offline_bundle.sh`）
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
  - [Pi（earendil-works/pi）编码 Agent CLI 的安装、配置与使用手册](devops_ai_agent/20261017-pi-coding-agent-install-usage-guide.md)（v1.3.0，用户级 npm 安装，免 sudo）
  - [Pi 内置 find 工具依赖 fd：GitHub 不可达导致下载失败与内网离线补齐](devops_ai_agent/20261019-pi-builtin-find-fd-offline-fix.md)（内网 APT 安装 fd-find / 免 sudo 放置 ~/.pi/agent/bin/fd）
  - [Pi（earendil-works/pi）编码 Agent CLI 的安装、配置与使用手册](devops_ai_agent/20261017-pi-coding-agent-install-usage-guide.md)（v1.3.0，用户级 npm 安装，免 sudo；含内网 npm 源不可达时 `--registry` 覆盖源的排错）
  - [Pi Agent 接入自建 LiteLLM 网关配置手册（OpenAI 兼容端点 + 默认模型）](devops_ai_agent/20261017-pi-litellm-gateway-config-guide.md)（网关 192.168.16.142:4000，实测含 tool calling 验证）
  - [为 Pi Agent 安装 anthropics/skills 与 obra/superpowers 两套通用技能集（目录技能 + git 包）](devops_ai_agent/20261017-pi-install-anthropic-superpowers-skills.md)（含 `scripts/skills/install_agent_skills.sh`；anthropic 19 个技能落 `~/.agents/skills/`，superpowers 以 git 包安装并含启动引导扩展，规避 GitHub TLS 中断）
  - [Pi 编码 Agent 离线部署（两步法）：通用 Node 运行时包 + Pi 应用包](devops_ai_agent/20261017-pi-offline-bundle-build-deploy-guide.md)（含离线包 `~/.work_linux_working/artifacts/pi-app-offline-1.3.0.tar.gz` 25 MB；第一步 Node 包见 devops_nodejs 分类）
  - [Pi Agent 批量安装 7 个扩展包：npm ENOTEMPTY、镜像源慢速与 onnxruntime-node 安装脚本失败的排查与修复](devops_ai_agent/20261017-pi-extension-packages-install-troubleshooting.md)（om-memory-system / billion-context / pi-cowboy / pi-mcp-adapter / pi-btw / pi-web-access / pi-subagents；npmmirror 提速 29 倍 + 跳过 install 脚本）
  - [Rowboat（rowboatlabs/rowboat）Linux 便携式部署与使用手册（官方 zip，免 sudo）](devops_ai_agent/20261017-rowboat-linux-portable-deploy-guide.md)（v1.0.5；Linux 无 AppImage，可选 deb/rpm/zip）
  - [Rowboat 便携式离线部署包制作与目标机部署手册（官方 zip + 脱敏配置 + 桌面集成）](devops_ai_agent/20261017-rowboat-offline-bundle-build-deploy-guide.md)（含离线包 `~/.work_linux_working/artifacts/rowboat-offline-1.0.5.tar.gz`，144 MB，配置排除凭据并脱敏）
  - [AionUi（iOfficeAI/AionUi）Linux 部署与使用手册（官方 deb + 免 sudo 解包运行）](devops_ai_agent/20261017-aionui-linux-deploy-guide.md)（v2.2.2；GitHub Release 无二进制，Linux 仅官方 deb）
  - [OpenWork（different-ai/openwork）Linux AppImage 部署与使用手册（含产物归位规范）](devops_ai_agent/20261017-openwork-appimage-deploy-guide.md)（v0.18.58；含 `scripts/devops/electron-desktop-integrate.sh` 通用桌面集成脚本）
  - [anthropics/skills 全部技能依赖的本地化下载与离线包制备（Node.js 24 + Python 3.11/3.12）](devops_ai_agent/20261017-anthropic-skills-deps-offline-download.md)（含 `scripts/skills/download_anthropic_skills_deps.sh` 与 `scripts/skills/deps/` 清单；npm core 318 包 / full 517 包，py311+py312 各 69 个 wheel）
  - [pandoc / tesseract 文档处理 CLI 的「解压即用」离线包制备（内网无源场景）](devops_ai_agent/20261017-doc-tools-offline-bundle-guide.md)（含 `scripts/devops/download_doc_tools_offline.sh`；pandoc 3.12.1 静态二进制 + tesseract 5.5.3 AppImage 解包 + tessdata_fast 语言数据，归档 126 MB）
  - [Gas Town（gastownhall/gastown）多 Agent 工作区编排系统：离线包制备与用户级部署配置手册](devops_ai_agent/20261019-gastown-offline-install-config-guide.md)（gt 1.2.1 + bd 1.0.0 + dolt 2.5.0 + Go 1.26.2，运行时 pi 1.3.0，免 sudo；含 `scripts/devops/gastown_offline_bundle.sh`、`gastown_install_offline.sh`，离线包 167 MB；记录 bd 版本必须与 gt 内嵌 beads 同代、Ubuntu 26.04 缺 ICU74 的零侵入处置、bd 多 rig 路由补丁、pi 项目信任前置）
  - [Gas Town 多 Agent 工作区编排系统：概念、命令速查与典型工作流（使用手册）](devops_ai_agent/20261019-gastown-usage-manual.md)（Mayor/Rig/Crew/Polecat/Hook/Convoy/Bead/Molecule 概念，**最小可用用例（下发指令 + 收集各 agent 状态）**，**人工确认的上行/下行通道（escalate、nudge、mail 与 AGENT.md 写法）**，Mayor 与 minimal 两种工作流，feed/dashboard/doctor 监控，运行时 pi/opencode 等切换与 pi 项目信任配置）
  - [Gas Town 本地验证环境全流程 SOP：初始化、配置、使用与实测问题处置](devops_ai_agent/20261019-gastown-local-verification-sop.md)（运行时 pi 1.3.0；实测 rig/crew/sling/convoy/feed/dashboard 全链路；沉淀 7 项实测发现：pi 项目信任前置、bd 多 rig 路由补丁、新增 rig 需重启 daemon、跨 rig convoy 无法自动关闭、`--dry-run` 仍会派发、切换运行时的 doctor 告警等）
  - [Gas Town 长前缀 rig 的 Agent 身份识别修复：polecat identity 落库重定向与 gt 源码补丁重编译](devops_ai_agent/20261020-gastown-long-prefix-rig-agent-identity-patch.md)（修复「identity add 成功但 identity list 恒为空」：根因一为 bd 1.0.0 不执行 routes.jsonl 路由致 bead 误落 hq 库，根因二为 gt 把 rig 前缀长度硬编码为 2~3；对应补丁 A/B（bd wrapper）+ 补丁 C（gt 源码放宽前缀上限至 32 并重编译）；含 `scripts/devops/gastown_build_patched_gt.sh`、`scripts/devops/patches/gt-1.2.1-agent-id-prefix-length.patch`，离线包升级至 180 MB 并携带修补版 gt）
  - [Gas Town 多 Agent 协同开发完整事例手册（git 通知任务 + 分角色提示词约束）](devops_ai_agent/20261020-gastown-git-driven-multiagent-collab-handbook.md)（**git push 任务单 → 钩子 → bd create + gt sling 的自动派发链路**；三层提示词约束模型：gt 内置角色模板 / 工位级 `polecats/<角色>/AGENTS.md` / 任务单正文经 `--args` 注入；含 `scripts/devops/gastown_git_task_bridge.sh`（dispatch/scan/install-hook/list，幂等 + dry-run）、mayor/dev1/dev2/tester 四类工位的职责边界与提示词模板、端到端四角色协作事例与协作流程全景；含 2026-10-20 上游版本核查结论：gt v1.2.1 / dolt v2.5.0 / pi 1.3.0 均为最新，bd 锁定 1.0.0 系 gt go.mod 硬约束）
  - [基于 Git 总线的异地多 Agent 协作：需求下行、状态上行与人工确认闭环（方案设计）](devops_ai_agent/20261019-git-bus-remote-multiagent-design.md)（家端只需 git、不装 gt 不登录远程；远程 `gitbus-bridge` 轮询总线，用 `bd create` → `gt sling` 下发、用 `gt nudge` + `gt escalate ack/close` 回复，并把 escalate/mq/commits/blocked 投影为 `outbox/*.json`；含目录即队列契约、数据结构定义、systemd user unit、幂等与死信处置、安全边界，以及 20 项待确定细节 D1–D20）
  - [Pi 编码 Agent 扩展与技能（extensions/skills）离线打包与部署手册](devops_ai_agent/20261018-pi-extensions-skills-offline-bundle-deploy.md)（含 `scripts/skills/pack_pi_extensions_skills.sh` + `scripts/skills/deploy_pi_extensions_skills.sh`；实测打包 6 扩展 + 120 技能，归档 `~/.work_linux_working/artifacts/pi-extensions-skills-offline-20261018.tar.gz`）
- **devops_gastown**
  - [Gas Town 停机/重建与多 Polecat 协同派活全流程（stop → rebuild → 批量派活 + 定向派活三件套）](devops_gastown/20261020-gastown-stop-rebuild-multi-polecat-flow.md)（含版本核查（gt 1.2.1 最新 + 本地补丁判定）、`down` 与 `shutdown` 分级对照、自定义命名池固定员工名、`sling` 到 rig 的批量派活（附「必须先派下一条再等完工」的隐含前提）、**定向派活三件套 `pool-init → session start → sling 点名`**、单一 convoy 组成 swarm；沉淀 18 项实测坑：**派活静默复用空闲员工致单子被假完工关闭**、`pool-init` 溢出名的真实条件与例外用法、空闲会话会被回收、临时单会被压缩回收、`gt peek` 不支持镇级角色、`gt sling --dry-run` 并非纯预演、`gt mq list` 需带 rig 参数、具名 polecat 需先有会话、命名须 >3 字符、`shutdown` 需 `--nuclear` 才清未提交工作区、`gt bead move` 在 bd 1.0.0 不可用等）
  - [Gas Town 多员工协同干活：从停机到三名 AI 员工并行交付的通俗手册（不懂开发也能照着做）](devops_gastown/20261020-gastown-multi-polecat-beginner-guide.md)（上文的**通俗改写版 + 真机从零复现记录**：以「公司下班再上班、招聘 dev1/dev2/tester 分头干活」为比喻，覆盖停机清理→重建名册→开工→立项目拆任务→派活到 rig→共享 convoy 看板→观察收工七步；附「怎么判断真的成功」判据表与 10 项新手坑通俗解释；本次实测 190 项单测全过、三条提交入主干）
  - [Gas Town 四人协作实训：1 PM + 2 开发 + 1 测试交付 Celery 任务调度器（含独立验收与收口）](devops_gastown/20261020-gastown-four-role-team-celery-playbook.md)（**完整实战案例**：Mayor=PM、dev1=后端、dev2=worker+前端、tester=端到端；含角色分工表与架构数据流、开工前**冻结接口契约**与 PM 拍板的 3 条歧义（status 以 exit_code 为准 / PENDING 语义 / 未知 id 必须 404）、**可复制的十一轮流程**（清场备份→建镇锁运行时→裸仓库骨架→注册 rig+命名池→开工体检→PM 简报建板→批量派活→观察合并→补派测试单三件套→**独立验收**（另目录 + 独立 venv(3.11) + 另端口 `:8010`）→交回 PM 收口→缺陷单回流第二圈）、判据速查表与本次 7 项新增坑（假完工、wisp 回收、`identity add` 不建目录、会话回收、`gt peek` 镇级地址、`--dry-run` 语义、合并环境缺 pytest）)
- **devops_code_analysis**
  - [C/C++ 代码分析工具链：快速部署、接口/业务链扫描与单元测试体系实施方案](devops_code_analysis/20261009-code-analysis-toolchain-deployment-guide.md)（含 `scripts/code_analysis/`：安装、离线打包、接口扫描、静态分析、单测脚手架、覆盖率、业务链追踪、code-review-graph 多语言接口手册、Understand-Anything 业务域图谱、Dockerfile）
  - [Node.js / Java / C++ 自动化测试工具链与离线包清单（Python 3.11 / JDK≥8 / glibc≤2.27）](devops_code_analysis/20261009-nodejs-java-cpp-testing-toolchain-package-list.md)
  - [C++ 第三方库与 GitHub 开源地址（测试/质量 + 常见引擎依赖）](devops_code_analysis/20261009-cpp-testing-libraries-and-repos.md)
  - [ast-grep：AST 结构化搜索/重写工具的安装、离线部署与使用手册](devops_code_analysis/20261012-ast-grep-install-usage-guide.md)（含 `scripts/code_analysis/install_ast_grep.sh`、`download_ast_grep_bundle.sh`）
  - [code-graph-rag（cgr）：多语言代码知识图谱/RAG 的部署、离线打包与使用手册](devops_code_analysis/20261012-code-graph-rag-install-usage-guide.md)（含 `scripts/code_analysis/install_code_graph_rag.sh`、`download_code_graph_rag_bundle.sh`）
  - [Understand-Anything：代码业务语义知识图谱/用例生成引擎的安装、离线部署与使用手册](devops_code_analysis/20261012-understand-anything-install-usage-guide.md)（含 `scripts/code_analysis/install_understand_anything.sh`）
- **devops_crawler_to_md**
  - [crawler-to-md 容器：把文档站点抓取并生成 Markdown/JSON 的使用指南](devops_crawler_to_md/20261013-crawler-to-md-doc-download-guide.md)
  - [pi.dev 官方文档整站抓取与逐句中英对照翻译（crawler-to-md + LiteLLM 网关）](devops_crawler_to_md/20261017-pi-dev-docs-crawl-bilingual-translate.md)（42 页 / 4428 处译文；含 `scripts/docs/crawl_docs_to_md.sh`、`split_pages.py`、`bilingual_translate.py`，产物在 `~/.work_linux_working/outputs/pi-dev-docs/`）
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
- **app_mattermost**
  - [Mattermost 配置 SMTP 邮件失败（unencrypted connection / authentication not enabled）排查与修复](app_mattermost/20261016-mattermost-smtp-auth-failure-fix.md)（mailcow 内部端口 10025 无 AUTH，改用 10587/STARTTLS）
  - [Mattermost 更换邮件服务器后 SMTP 测试再报 553 Sender address rejected（发件地址未归属认证账号）排查与修复](app_mattermost/20261019-mattermost-smtp-sender-address-mismatch-fix.md)（迁移至 mail.vire.cn:587/STARTTLS、账号 mattermost@vire.cn 后发件人未同步，改控制台即时生效）
- **app_outline**
  - [Outline 内网知识库 Docker Compose 部署手册（HTTPS + 邮件登录）](app_outline/20260930-outline-deployment-guide.md)（宿主 nginx 反代变体见迁移手册 §8）
  - [Outline 内网知识库配置与使用手册（邮件登录/团队/存储/API/备份）](app_outline/20260930-outline-configuration-guide.md)
  - [Outline 接入 Keycloak OIDC 单点登录配置手册（客户端/回调/email_verified 排障，含域名变更回调补充）](app_outline/20261014-outline-keycloak-oidc-sso-config.md)
  - [Outline 内网知识库数据备份与迁移手册（全量备份脚本 + 异地迁移）](app_outline/20261015-outline-backup-migration-guide.md)（含 `scripts/backup/outline_backup.sh`；§8 记录迁移至 SERVER_44 宿主 nginx 反代 + 数据恢复实测）

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