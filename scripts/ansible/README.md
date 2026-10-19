# Ansible 控制端（work_linux）

本目录是 **Ansible 控制端工程**，采用官方推荐的样板目录结构，用于远程接管
Debian 13 沙箱容器（及后续其它主机）批量装包与配置收敛。

控制端 Python 环境由 **uv + pyproject.toml** 管理，不污染系统 Python。

## 目录结构（对齐 Ansible 官方样板）

```text
scripts/ansible/
├── ansible.cfg              # 控制端配置（清单路径、roles_path、提权、SSH 参数）
├── pyproject.toml           # uv 依赖声明（ansible-core / yamllint / ansible-lint）
├── requirements.yml         # Galaxy collection 依赖
├── playbooks/               # 所有 playbook 统一收纳于此
│   ├── site.yml             # 总入口 playbook
│   ├── sandbox.yml          # 沙箱组专用 playbook
│   └── ping.yml             # 连通性 + 提权冒烟测试
├── test-playbooks.sh        # 批量执行多个 playbook 并汇总结果
├── .yamllint                # YAML 静态检查规则
├── inventory/               # 按环境分离的清单（官方样板做法）
│   ├── production/
│   │   ├── hosts.yml
│   │   └── group_vars/all.yml
│   └── staging/
│       ├── hosts.yml
│       └── group_vars/
│           ├── all.yml
│           └── sandbox.yml
├── group_vars/              # 全局组变量（跨环境共用）
├── host_vars/               # 全局主机变量
├── library/                 # 自定义模块（可选）
├── module_utils/            # 模块共用代码（可选）
├── filter_plugins/          # 自定义过滤器（可选）
└── roles/
    ├── common/              # 基线：时区、基础软件包
    │   ├── defaults/main.yml
    │   ├── handlers/main.yml
    │   ├── meta/main.yml
    │   ├── tasks/main.yml
    │   ├── vars/main.yml
    │   ├── files/
    │   └── templates/
    └── sshd_sandbox/        # sshd 配置管理（模板下发 + 语法校验）
        ├── defaults/main.yml
        ├── handlers/main.yml
        ├── meta/main.yml
        ├── tasks/main.yml
        ├── templates/99-sandbox.conf.j2
        ├── files/
        └── vars/
```

## 环境准备

```bash
cd scripts/ansible

# 1. 创建控制端虚拟环境并安装依赖（需要 Python 3.13）
uv sync

# 若本机无 3.13 且 GitHub 直连超时，可用镜像安装：
# UV_PYTHON_INSTALL_MIRROR="https://ghfast.top/https://github.com/astral-sh/python-build-standalone/releases/download" \
#   uv python install 3.13

# 2. 安装 Galaxy collection（必须在项目内路径，ansible.cfg 已声明）
.venv/bin/ansible-galaxy collection install -r requirements.yml -p ./collections
```

## 目标主机准备（Debian 13 沙箱容器）

```bash
# 在仓库根目录执行
./docker/debian13-sandbox/build.sh
./docker/debian13-sandbox/run.sh -p 22222
```

清单 `inventory/staging/hosts.yml` 默认指向 `127.0.0.1:22222`，账号 `test/test`。

## 验证与执行

```bash
# 连通性与免密提权验证（只读，不改目标机）
.venv/bin/ansible-playbook -i inventory/staging/hosts.yml playbooks/ping.yml

# 基线收敛（时区 + 基础软件包 + sshd 配置）
.venv/bin/ansible-playbook -i inventory/staging/hosts.yml playbooks/site.yml

# 临时远程装包（示例：htop）
.venv/bin/ansible sandbox -i inventory/staging/hosts.yml \
  -m ansible.builtin.apt -a 'name=htop state=present' -b

# YAML 静态检查
.venv/bin/yamllint .
```

## 批量测试多个 playbook

`test-playbooks.sh` 用于一次性跑完任意多个 playbook 并汇总结果，
**维护方式：直接编辑脚本内的 `PLAYBOOKS` 数组，追加任意多个路径即可（路径相对 `scripts/ansible/`）。**

```bash
./test-playbooks.sh                          # 跑数组内的全部 playbook
./test-playbooks.sh --start-sandbox          # 先自动启动沙箱容器再跑
./test-playbooks.sh -p playbooks/extra.yml -p playbooks/more.yml # 临时追加（可重复）
./test-playbooks.sh -d ./playbooks           # 扫描 playbooks 目录下所有 *.yml
./test-playbooks.sh --syntax-only            # 只做语法检查
./test-playbooks.sh --check -t common        # 干跑模式 + 指定标签
./test-playbooks.sh --stop-on-fail           # 遇错即停
./test-playbooks.sh -h                       # 完整帮助
```

输出包含每个 playbook 的结果、耗时、`PLAY RECAP` 摘要，以及最终
`PASS/FAIL/SKIP` 统计；任一 playbook 失败则脚本以非零码退出。
详细日志落盘到 `$WORK_DIR/logs/ansible/<时间戳>-<名称>.log`（默认
`~/.work_linux_working/logs/ansible/`）。

## 变量优先级说明

`roles/*/defaults/main.yml` 优先级最低，可被 `inventory/*/group_vars/` 覆盖。
例如 `common_timezone` 默认取 `sandbox_timezone`，改时区只需改
`inventory/staging/group_vars/sandbox.yml`。

## 安全提示

> [!WARNING]
> 清单中使用了明文密码（`ansible_password`），仅适用于本地沙箱。生产环境请改用
> SSH 公钥，并将敏感变量放入 `ansible-vault` 加密文件。
