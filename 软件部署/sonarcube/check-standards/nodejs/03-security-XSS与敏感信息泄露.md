---
title: "【修复指南】前端 Node.js/TS 安全类：XSS 与敏感信息泄露"
type: note
status: active
scope: 软件部署/sonarcube/check-standards/nodejs
created: 2026-09-10 16:30:00
updated: 2026-09-10 16:30:00
summary: "覆盖前端特有安全告警：DOM XSS（innerHTML/v-html/dangerouslySetInnerHTML）、硬编码凭据、日志/接口泄露敏感信息，给出产生原因与修复示例。"
keywords: [sonarqube, xss, security, secrets, frontend, v-html, dangerouslysetinnerhtml]
verification: "整改后重扫，XSS 与硬编码密钥告警清零并把密钥迁入环境变量"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> 前端 XSS 与敏感信息泄露直接威胁用户数据安全。SonarJS 对 `dangerouslySetInnerHTML`、`v-html`、`innerHTML` 及硬编码密钥等给出告警/热点，属发布红线。

## 🔍 检查要点说明

| 要点 | 说明 | 危害 |
|------|------|------|
| `innerHTML` / `outerHTML` | DOM 注入 HTML | XSS 窃取 cookie/会话 |
| Vue `v-html` | 渲染不可信 HTML | XSS |
| React `dangerouslySetInnerHTML` | 同上 | XSS |
| `a[href=javascript:]` | 协议注入 | 点击执行脚本 |
| 硬编码密钥/Token（S2068 类） | 代码里写死账号密码 | 凭据泄露 |
| 日志/接口回包含敏感字段 | console 打印、接口透传完整信息 | 信息泄露 |

## 🛠️ 修复方案

### 1. 使用 `innerHTML` / `v-html` 渲染用户内容

**产生原因**：把接口回传的字符串直接当 HTML 渲染。

```html
<!-- ❌ Vue 错误示例 -->
<div v-html="userComment">你是管理员</div>
```

```html
<!-- ✅ 修复示例：改用插值自动转义 -->
<div>{{ userComment }}</div>

<!-- 若要渲染富文本：先用 DOMPurify 消毒后再 v-html -->
```

```js
// ✅ DOMPurify 白名单消毒
import DOMPurify from 'dompurify';
const safe = DOMPurify.sanitize(serverHtml);   // 移除 script / event handler
```

```jsx
// ❌ React 错误示例
const html = `<img src=x onerror="alert(1)"/>` + data;
return <div dangerouslySetInnerHTML={{ __html: html }} />;

// ✅ React 修复示例（先用 DOMPurify 消毒）
const safe = DOMPurify.sanitize(data);
return <div dangerouslySetInnerHTML={{ __html: safe }} />;
```

### 2. `a` 标签 `javascript:` 链接

```js
// ❌ 错误示例
<a :href="`javascript:doXxx('${userInput}')`">点击</a>

// ✅ 修复示例：事件绑定而非 href 协议
<a href="#" @click.prevent="doXxx(userInput)">点击</a>
```

### 3. 硬编码凭据 / 密钥（S2068 类）

**产生原因**：把 `password=`、`token=`、AK/SK 直接写进源码并提交仓库。

```js
// ❌ 错误示例
const MYSQL_PWD = 'P@ssw0rd123';
axios.post('/api', { key: 'LTAIxxxxxxxxxxxxxxxx' });

// ✅ 修复示例（环境变量注入，源码不落盘）
const MYSQL_PWD = process.env.MYSQL_PWD;
axios.post('/api', { key: process.env.OSS_ACCESS_KEY });
```

配套动作：
- 已提交的密钥**必须在平台/代码托管平台做历史清理与吊销**；
- 新建 `.env`（已排除）、`.gitignore` 增加 `.env*`；
- 上线用部署系统的 Secret 管理注入环境变量。

### 4. 日志与接口敏感字段

```js
// ❌ 错误示例
console.log('login user:', user);            // 打印出密码/token
res.json({ user, password: user.pwdHash });  // 回包带出不应对外字段

// ✅ 修复示例
const { pwdHash, mobile, ...safeUser } = user;
console.log('login userId:', user.id);
res.json({ user: safeUser });
```

## ✅ 快速自查清单

- [ ] 全仓搜索 `v-html`、`innerHTML`、`dangerouslySetInnerHTML`，不可信数据一律先消毒
- [ ] 全仓搜索 `password`、`secret`、`token =`、`AK/SK` 字样，确有凭据迁入环境变量
- [ ] console/日志不打印敏感字段；接口响应做字段裁剪
- [ ] 密钥泄露后已吊销并清理历史

## 📎 关联

- XSS 规则族：React(S5247 类)、Web/vue 由 SonarJS 检测
- 扫描脚本：[../../../../scripts/sonarqube/nodejs_scanner/scan-nodejs.sh](../../../../scripts/sonarqube/nodejs_scanner/scan-nodejs.sh)