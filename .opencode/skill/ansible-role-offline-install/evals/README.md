# evals —— 判定技能是否被正确使用

每次改动 SKILL.md 或模板后，用下面这些用例回归一遍。

## A. 触发词识别（技能是否会加载）

| # | 用户输入 | 期望 | 说明 |
|---|---|---|---|
| A1 | 用 ansible role 创建安装 redis 环境 | ✅ 加载 | 标准触发 |
| A2 | 帮我做一个 ansible role 工具环境，装 nginx | ✅ 加载 | 变体措辞 |
| A3 | 这台内网机器装不了 ruby，要离线包 | ✅ 加载 | 从"离线"切入 |
| A4 | 把 postgres 做成双模式安装 | ✅ 加载 | 从"双模式"切入 |
| A5 | 在沙箱验证一下这个离线包能不能装 | ✅ 加载 | 从"沙箱验证"切入 |
| A6 | ansible role 怎么写 | ⚠️ 可加载 | 泛问，可加载但应聚焦 |
| A7 | 帮我重启一下 nginx | ❌ 不加载 | 无关运维任务 |
| A8 | 写个 Dockerfile | ❌ 不加载 | 无关 |

## B. 设计约束遵守（最容易犯的错）

| # | 场景 | 期望行为 | 常见错误 |
|---|---|---|---|
| B1 | 新建 role | 复制 `assets/role-skeleton/`，`main.yml` 保持 include_vars → resolve → import_role → orchestrate 四步 | 只写 `import_role: install_base` 就结束 |
| B2 | `meta/main.yml` | `dependencies: []` | 把 install_base 列为依赖 → 重复执行 |
| B3 | `_install_online_tasks` | 指向**本 role** 的 online_install.yml | 留空或指向基座 → 找不到任务 |
| B4 | 起容器 | 用 `-p 22222` 并**带上 `-w $OFFLINE_PKG_DIR`** | 用 2222；忘记 `-w` 导致产物丢失 |
| B5 | 打离线包 | tar.gz + `.sha256` 成对搬运 | 只搬 tar.gz → 离线安装校验失败 |
| B6 | 离线复装 | `docker rm -f` 销毁重建容器 | 只 `dpkg --purge`，残留文件让验证失真 |
| B7 | 幂等验收 | 第二次必须 `changed=0` 且 `本次动作 = skip` | 只看第一次 changed 多就当成功 |

## C. 排障能力

| # | 现象 | 期望定位 |
|---|---|---|
| C1 | SSH Permission denied，容器内 su root 正常 | 端口被宿主机 sshd 占用 → 比对 host key 指纹 → 换 22222 |
| C2 | `Unable to acquire the dpkg frontend lock` | 上次 playbook 被 kill 残留 apt 进程 → kill + `dpkg --configure -a` |
| C3 | 换源后 grep 仍见原源 | `replace backup:true` 生成的备份文件被 grep 到 → `backup:false` + 排除 |
| C4 | `is version()` 断言失败 | Debian 包版本带 epoch `1:` → 改跑 `<cmd> --version` |
| C5 | `.deb` 集合为空 | 元包 + 依赖已满足不展开闭包 + 落 /var/cache → 取已装包名 + apt-get download |
| C6 | `-e xxx=true` 报 str 类型错 | `-e` 传的是字符串 → 条件加 `\| bool` |
| C7 | 源码装完版本没变 | `creates:` 静默跳过 → 先探测前缀版本，不符则清空重编 |
| C8 | `tar: more than one '-Acdtrux'` | Jinja for 吃掉换行 → bash 数组 |

## D. 产物完整性

技能跑完后应存在：

```
$OFFLINE_PKG_DIR/<pkg>-<ver>.tar.gz
$OFFLINE_PKG_DIR/<pkg>-<ver>.tar.gz.sha256
```

目标机应存在：

```
/var/lib/ansible-install-state/<pkg>.json   # mode=offline, version=实测版本
```

## E. 脚本自检

```bash
# 沙箱自检（应全绿，含挂载双向验证）
./scripts/check-sandbox.sh -c 'ruby -v'

# 幂等验证（应输出「幂等验证通过」）
./scripts/verify-idempotent.sh playbooks/install_ruby.yml
```

两者都必须 `bash -n` 无语法错误，`-h` 能正常输出帮助。
