---
title: "【故障变更】GitLab 数据恢复报 pg_trgm/btree_gist 扩展 owner 权限错误修复"
type: note
status: active
scope: devops_gitlab
created: 2026-07-07 00:00:00
updated: 2026-07-07 00:00:00
summary: "GitLab 恢复 PostgreSQL 数据时因普通用户无扩展所有权报 must be owner of extension，通过临时将 gitlab 用户提升为超级用户完成导入后再降权解决。"
keywords: [linux, gitlab, postgresql, restore, pg_trgm, btree_gist, superuser]
verification: "gitlab-backup restore BACKUP=<备份文件名> 不再出现 must be owner 报错"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

# GitLab 数据恢复扩展 owner 权限错误处理

## 📌 问题现象

已处理 PostgreSQL 权限问题后，开始导入数据时仍报错：

```sh
ERROR: must be owner of extersion pg_trgm
ERROR: must be owner of extersion btree_gist
```

## 原因解释

这是 GitLab 恢复 PostgreSQL 数据库时最常见的权限越界错误。GitLab 数据库初始化时需加载高级扩展插件（`pg_trgm` 用于模糊搜索、`btree_gist` 用于索引优化）。在 PostgreSQL 中，只有超级用户（Superuser，通常是 `gitlab-psql`）才有资格创建或修改这些扩展。

GitLab 恢复脚本导入数据时使用的是普通数据库用户（`gitlab`），它在尝试获取扩展所有权（`OWNER TO`）时被数据库拒绝，因此导入失败。

## 解决步骤

### 1. 进入容器并连接数据库

```bash
docker exec -it gitlab /bin/bash
su - gitlab-psql -c "/opt/gitlab/embedded/bin/psql -h /var/opt/gitlab/postgresql -d gitlabhq_production"
```

此时提示符应变为 `gitlabhq_production=#`。

### 2. 临时提升 gitlab 用户为超级用户

```sql
ALTER USER gitlab WITH SUPERUSER;
```

看到 `ALTER ROLE` 即代表成功，输入 `\q` 退出。

### 3. 重新执行数据恢复

先确认 `puma` 与 `sidekiq` 已停止：

```bash
gitlab-ctl stop puma
gitlab-ctl stop sidekiq
gitlab-backup restore BACKUP=你的备份文件名
```

此时因 `gitlab` 已是超级用户，报错消失，恢复可顺利完成。

### 4. 恢复完成后安全降权（强烈建议）

```bash
su - gitlab-psql -c "/opt/gitlab/embedded/bin/psql -h /var/opt/gitlab/postgresql -d gitlabhq_production"
```

```sql
ALTER USER gitlab WITH NOSUPERUSER;
```

输入 `\q` 退出，随后按需执行 `gitlab-ctl restore`。

## 验证

恢复过程中不再出现 `must be owner of extension` 报错即为成功；完成后确认 `gitlab` 用户已恢复为普通权限。