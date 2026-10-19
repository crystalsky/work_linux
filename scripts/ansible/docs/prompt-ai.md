下面给你一份可以直接拿去写 README / role 注释 / issue 描述的提示词，我按“可落地”的方式组织好了（含 role 结构、变量设计、模式分支、职责流程）。你可以按需增删。

Ansible Role + Playbook 安装程序环境（在线 / 离线双模式）

一、整体目标

使用 Ansible Role + Playbook 统一管理程序运行环境的安装，要求：

• 每个 Role 只负责安装一种指定的软件 / 运行环境（单一职责）

• 同时支持：

  • 在线模式（online）：使用官方推荐的在线安装方式

  • 离线模式（offline）：使用预先准备好的 tar.gz 离线包进行安装

• 支持 离线包的制作、分发与复用

二、支持的两种安装模式

1️⃣ 在线模式（online）

• 使用软件官方指定的安装方式

• 可通过官方脚本、包管理器、仓库、在线二进制等方式进行安装

• 联网环境直接执行

• 支持指定：

  • 软件版本

  • 安装源（官方 / 镜像）

  • 安装参数

2️⃣ 离线模式（offline）

离线包可通过以下方式之一提供：

• 本地固定路径（如 /opt/offline_pkgs/xxx.tar.gz）

• HTTP / HTTPS URL（下载到本地后再安装）

离线包格式统一为：
xxx-<version>.tar.gz


离线包内至少包含：
• 软件安装文件

• 依赖包

• 必要的安装脚本（如 install.sh）

• （可选）校验文件（sha256 / md5）

三、Role 职责流程（核心）

每个 Role 必须实现以下 3 个职责流程，并通过变量控制执行路径。

✅ 流程 1：在线安装指定软件包

目标：
• 在在线模式下，安装指定版本的软件及其依赖

说明：
• 使用官方推荐方式

• 自动识别操作系统 / 架构

• 保证幂等

• 安装完成后：

  • 校验版本

  • 校验关键命令是否可用

✅ 流程 2：制作并分发离线安装包

触发条件：
• 通过变量控制，例如：
  make_offline_package: true
  

流程包括：

1. 在线安装指定软件
2. 将以下内容打包：
   • 软件本体

   • 依赖文件

   • 环境变量配置

   • 启动脚本（如有）

3. 打包为 tar.gz
4. 分发离线包到目标位置：
   • 上传到指定 SFTP 服务器

   • 或

   • 拷贝到指定 本地目录

可配置参数：
package_name: xxx
package_version: 1.2.3

offline_package_dir: /opt/offline_packages
offline_distribute_method: sftp | local

# SFTP
sftp_host: 10.0.0.10
sftp_user: uploader
sftp_path: /data/offline

# 本地目录
local_dist_dir: /mnt/share/offline


✅ 流程 3：使用离线包进行离线安装

触发条件：
install_mode: offline


离线包来源：
• 本地固定路径

• HTTP / HTTPS URL

流程：

1. 校验离线包是否存在
2. 如果是 URL，则先下载
3. 校验完整性（sha256）
4. 解压到临时目录
5. 执行离线安装脚本 / 拷贝文件
6. 配置环境变量
7. 校验安装结果

四、Role 结构建议

roles/
└── install_xxx/
    ├── tasks/
    │   ├── main.yml
    │   ├── online_install.yml
    │   ├── offline_install.yml
    │   └── make_offline_package.yml
    ├── files/
    ├── templates/
    ├── vars/
    │   └── main.yml
    └── defaults/
        └── main.yml


五、统一变量设计示例

# Role 默认变量
install_mode: online        # online | offline
package_version: latest

# 离线相关
offline_package_url: ""
offline_package_path: ""
offline_package_checksum: ""

make_offline_package: false
offline_distribute_method: local   # sftp | local


六、Playbook 示例

- hosts: app_servers
  roles:
    - role: install_xxx
      vars:
        install_mode: offline
        offline_package_path: /opt/pkg/xxx-1.2.3.tar.gz


七、设计原则

• 每个 Role 只安装一个程序 ✅

• 在线 / 离线逻辑彻底解耦 ✅

• 幂等、可重复执行 ✅

• 离线包可跨主机复用 ✅

• 不依赖目标节点外网 ✅

如果你愿意，我可以：
• 帮你把这个提示词 改成 AI 生成代码的 system prompt

• 直接帮你 生成一套完整 role + playbook 骨架

• 按 具体软件（如 Docker / Java / Python / Nginx） 细化变量和任务

只要告诉我你第一个要装的软件是什么。