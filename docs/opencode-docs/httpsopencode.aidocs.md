# https://opencode.ai/docs

<!--
URL: https://opencode.ai/docs
title: Intro | AI coding agent built for the terminal
-->

[Skip to content](#_top)

[![](/docs/_astro/logo-dark.DOStV66V.svg) ![](/docs/_astro/logo-light.B0yzR0O5.svg)  OpenCode](/docs/)

[app.header.home](/)[app.header.docs](/v2/docs)

Search  `CtrlK`

Cancel

  [New OpenCode v2 is now available →](https://opencode.ai/v2)

* [Intro](/docs/)
* [Config](/docs/config/)
* [Providers](/docs/providers/)
* [Network](/docs/network/)
* [Enterprise](/docs/enterprise/)
* [Troubleshooting](/docs/troubleshooting/)
* [Windows](/docs/windows-wsl)
* Usage

  + [Go](https://opencode.ai/v2/docs/console/go/)
  + [TUI](/docs/tui/)
  + [CLI](/docs/cli/)
  + [Web](/docs/web/)
  + [IDE](/docs/ide/)
  + [Console](https://opencode.ai/v2/docs/console/)
  + [Share](/docs/share/)
  + [GitHub](/docs/github/)
  + [GitLab](/docs/gitlab/)
* Configure

  + [Tools](/docs/tools/)
  + [Rules](/docs/rules/)
  + [Agents](/docs/agents/)
  + [Models](/docs/models/)
  + [Themes](/docs/themes/)
  + [Keybinds](/docs/keybinds/)
  + [Commands](/docs/commands/)
  + [Formatters](/docs/formatters/)
  + [Permissions](/docs/permissions/)
  + [Policies](/docs/policies/)
  + [LSP Servers](/docs/lsp/)
  + [MCP servers](/docs/mcp-servers/)
  + [ACP Support](/docs/acp/)
  + [Agent Skills](/docs/skills/)
  + [References](/docs/references/)
  + [Custom Tools](/docs/custom-tools/)
* Develop

  + [SDK](/docs/sdk/)
  + [Server](/docs/server/)
  + [Plugins](/docs/plugins/)
  + [Ecosystem](/docs/ecosystem/)

[GitHub](https://github.com/anomalyco/opencode)[Discord](https://opencode.ai/discord)

  Select theme   DarkLightAuto         Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

On this page

* [Overview](#_top)
* [Install](#install)
* [Configure](#configure)
* [Initialize](#initialize)
* [Usage](#usage)
  + [Ask questions](#ask-questions)
  + [Add features](#add-features)
  + [Make changes](#make-changes)
  + [Undo changes](#undo-changes)
* [Share](#share)
* [Customize](#customize)

### On this page

* [Overview](#_top)
* [Install](#install)
* [Configure](#configure)
* [Initialize](#initialize)
* [Usage](#usage)
  + [Ask questions](#ask-questions)
  + [Add features](#add-features)
  + [Make changes](#make-changes)
  + [Undo changes](#undo-changes)
* [Share](#share)
* [Customize](#customize)

## Intro

Get started with OpenCode.

Note

OpenCode 1 and OpenCode 2 both use the `opencode` command and cannot be installed side by side under their default command.
See the [OpenCode 2 docs](https://opencode.ai/v2/docs/) to migrate to V2.

[**OpenCode**](/) is an open source AI coding agent. Itâs available as a terminal-based interface, desktop app, or IDE extension.

![OpenCode TUI with the opencode theme](/docs/_astro/screenshot.CQjBbRyJ_1dLadc.webp)

Letâs get started.

---

##### [Prerequisites](#prerequisites)

To use OpenCode in your terminal, youâll need:

1. A modern terminal emulator like:

   * [WezTerm](https://wezterm.org), cross-platform
   * [Alacritty](https://alacritty.org), cross-platform
   * [Ghostty](https://ghostty.org), Linux and macOS
   * [Kitty](https://sw.kovidgoyal.net/kitty/), Linux and macOS
2. API keys for the LLM providers you want to use.

---

### [Install](#install)

The easiest way to install OpenCode 1 is through the install script. These installation methods provide the `opencode`
binary and can conflict with or replace an OpenCode 2 installation.

Terminal window

```
curl -fsSL https://opencode.ai/install | bash
```

You can also install it with the following commands:

* **Using Node.js**

  + [npm](#tab-panel-0)
  + [Bun](#tab-panel-1)
  + [pnpm](#tab-panel-2)
  + [Yarn](#tab-panel-3)

  Terminal window

  ```
  npm install -g opencode-ai
  ```

  Terminal window

  ```
  bun install -g opencode-ai
  ```

  Terminal window

  ```
  pnpm install -g opencode-ai
  ```

  Terminal window

  ```
  yarn global add opencode-ai
  ```
* **Using Homebrew on macOS and Linux**

  Terminal window

  ```
  brew install anomalyco/tap/opencode
  ```

  > We recommend using the OpenCode tap for the most up to date releases. The official `brew install opencode` formula is maintained by the Homebrew team and is updated less frequently.
* **Installing on Arch Linux**

  Terminal window

  ```
  sudo pacman -S opencode           # Arch Linux (Stable)

  paru -S opencode-bin              # Arch Linux (Latest from AUR)
  ```

##### [Windows](#windows)

Recommended: Use WSL

For the best experience on Windows, we recommend using [Windows Subsystem for Linux (WSL)](/docs/windows-wsl). It provides better performance and full compatibility with OpenCodeâs features.

* **Using Chocolatey**

  Terminal window

  ```
  choco install opencode
  ```
* **Using Scoop**

  Terminal window

  ```
  scoop install opencode
  ```
* **Using NPM**

  Terminal window

  ```
  npm install -g opencode-ai
  ```
* **Using Mise**

  Terminal window

  ```
  mise use -g github:anomalyco/opencode
  ```
* **Using Docker**

  Terminal window

  ```
  docker run -it --rm ghcr.io/anomalyco/opencode
  ```

Support for installing OpenCode on Windows using Bun is currently in progress.

You can also grab the binary from the [Releases](https://github.com/anomalyco/opencode/releases).

---

### [Configure](#configure)

With OpenCode you can use any LLM provider by configuring their API keys.

If you are new to using LLM providers, we recommend using [OpenCode Zen](https://opencode.ai/v2/docs/console/).
Itâs a curated list of models that have been tested and verified by the OpenCode
team.

1. Run the `/connect` command in the TUI, select opencode, and head to [opencode.ai/auth](https://opencode.ai/auth).

   ```
   /connect
   ```
2. Sign in, add your billing details, and copy your API key.
3. Paste your API key.

   ```
   â API key

   â

   â

   â enter
   ```

Alternatively, you can select one of the other providers. [Learn more](/docs/providers#directory).

---

### [Initialize](#initialize)

Now that youâve configured a provider, you can navigate to a project that
you want to work on.

Terminal window

```
cd /path/to/project
```

And run OpenCode.

Terminal window

```
opencode
```

Next, initialize OpenCode for the project by running the following command.

```
/init
```

This will get OpenCode to analyze your project and create an `AGENTS.md` file in
the project root.

Tip

You should commit your projectâs `AGENTS.md` file to Git.

This helps OpenCode understand the project structure and the coding patterns
used.

---

### [Usage](#usage)

You are now ready to use OpenCode to work on your project. Feel free to ask it
anything!

If you are new to using an AI coding agent, here are some examples that might
help.

---

#### [Ask questions](#ask-questions)

You can ask OpenCode to explain the codebase to you.

Tip

Use the `@` key to fuzzy search for files in the project.

```
How is authentication handled in @packages/functions/src/api/index.ts
```

This is helpful if thereâs a part of the codebase that you didnât work on.

---

#### [Add features](#add-features)

You can ask OpenCode to add new features to your project. Though we first recommend asking it to create a plan.

1. **Create a plan**

   OpenCode has a *Plan mode* that disables its ability to make changes and
   instead suggest *how* itâll implement the feature.

   Switch to it using the **Tab** key. Youâll see an indicator for this in the lower right corner.

   ```
   <TAB>
   ```

   Now letâs describe what we want it to do.

   ```
   When a user deletes a note, we'd like to flag it as deleted in the database.

   Then create a screen that shows all the recently deleted notes.

   From this screen, the user can undelete a note or permanently delete it.
   ```

   You want to give OpenCode enough details to understand what you want. It helps
   to talk to it like you are talking to a junior developer on your team.

   Tip

   Give OpenCode plenty of context and examples to help it understand what you
   want.
2. **Iterate on the plan**

   Once it gives you a plan, you can give it feedback or add more details.

   ```
   We'd like to design this new screen using a design I've used before.

   [Image #1] Take a look at this image and use it as a reference.
   ```

   Tip

   Drag and drop images into the terminal to add them to the prompt.

   OpenCode can scan any images you give it and add them to the prompt. You can
   do this by dragging and dropping an image into the terminal.
3. **Build the feature**

   Once you feel comfortable with the plan, switch back to *Build mode* by
   hitting the **Tab** key again.

   ```
   <TAB>
   ```

   And asking it to make the changes.

   ```
   Sounds good! Go ahead and make the changes.
   ```

---

#### [Make changes](#make-changes)

For more straightforward changes, you can ask OpenCode to directly build it
without having to review the plan first.

```
We need to add authentication to the /settings route. Take a look at how this is

handled in the /notes route in @packages/functions/src/notes.ts and implement

the same logic in @packages/functions/src/settings.ts
```

You want to make sure you provide a good amount of detail so OpenCode makes the right
changes.

---

#### [Undo changes](#undo-changes)

Letâs say you ask OpenCode to make some changes.

```
Can you refactor the function in @packages/functions/src/api/index.ts?
```

But you realize that it is not what you wanted. You **can undo** the changes
using the `/undo` command.

```
/undo
```

OpenCode will now revert the changes you made and show your original message
again.

```
Can you refactor the function in @packages/functions/src/api/index.ts?
```

From here you can tweak the prompt and ask OpenCode to try again.

Tip

You can run `/undo` multiple times to undo multiple changes.

Or you **can redo** the changes using the `/redo` command.

```
/redo
```

---

### [Share](#share)

The conversations that you have with OpenCode can be [shared with your
team](/docs/share).

```
/share
```

This will create a link to the current conversation and copy it to your clipboard.

Note

Conversations are not shared by default.

Hereâs an [example conversation](https://opencode.ai/s/4XP1fce5) with OpenCode.

---

### [Customize](#customize)

And thatâs it! You are now a pro at using OpenCode.

To make it your own, we recommend [picking a theme](/docs/themes), [customizing the keybinds](/docs/keybinds), [configuring code formatters](/docs/formatters), [creating custom commands](/docs/commands), or playing around with the [OpenCode config](/docs/config).

[Edit page](https://github.com/anomalyco/opencode/edit/dev/packages/web/src/content/docs/index.mdx)[Found a bug? Open an issue](https://github.com/anomalyco/opencode/issues/new)[Join our Discord community](https://opencode.ai/discord)  Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

© [Anomaly](https://anoma.ly)

Last updated: Oct 13, 2026

---
<!--
URL: https://opencode.ai/docs/server/
title: Server | OpenCode
-->

[Skip to content](#_top)

[![](/docs/_astro/logo-dark.DOStV66V.svg) ![](/docs/_astro/logo-light.B0yzR0O5.svg)  OpenCode](/docs/)

[app.header.home](/)[app.header.docs](/v2/docs)

Search  `CtrlK`

Cancel

  [New OpenCode v2 is now available →](https://opencode.ai/v2)

* [Intro](/docs/)
* [Config](/docs/config/)
* [Providers](/docs/providers/)
* [Network](/docs/network/)
* [Enterprise](/docs/enterprise/)
* [Troubleshooting](/docs/troubleshooting/)
* [Windows](/docs/windows-wsl)
* Usage

  + [Go](https://opencode.ai/v2/docs/console/go/)
  + [TUI](/docs/tui/)
  + [CLI](/docs/cli/)
  + [Web](/docs/web/)
  + [IDE](/docs/ide/)
  + [Console](https://opencode.ai/v2/docs/console/)
  + [Share](/docs/share/)
  + [GitHub](/docs/github/)
  + [GitLab](/docs/gitlab/)
* Configure

  + [Tools](/docs/tools/)
  + [Rules](/docs/rules/)
  + [Agents](/docs/agents/)
  + [Models](/docs/models/)
  + [Themes](/docs/themes/)
  + [Keybinds](/docs/keybinds/)
  + [Commands](/docs/commands/)
  + [Formatters](/docs/formatters/)
  + [Permissions](/docs/permissions/)
  + [Policies](/docs/policies/)
  + [LSP Servers](/docs/lsp/)
  + [MCP servers](/docs/mcp-servers/)
  + [ACP Support](/docs/acp/)
  + [Agent Skills](/docs/skills/)
  + [References](/docs/references/)
  + [Custom Tools](/docs/custom-tools/)
* Develop

  + [SDK](/docs/sdk/)
  + [Server](/docs/server/)
  + [Plugins](/docs/plugins/)
  + [Ecosystem](/docs/ecosystem/)

[GitHub](https://github.com/anomalyco/opencode)[Discord](https://opencode.ai/discord)

  Select theme   DarkLightAuto         Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

On this page

* [Overview](#_top)
  + [Usage](#usage)
  + [Authentication](#authentication)
  + [How it works](#how-it-works)
* [Spec](#spec)
* [APIs](#apis)
  + [Global](#global)
  + [Project](#project)
  + [Path & VCS](#path--vcs)
  + [Instance](#instance)
  + [Config](#config)
  + [Provider](#provider)
  + [Sessions](#sessions)
  + [Messages](#messages)
  + [Commands](#commands)
  + [Files](#files)
  + [Tools (Experimental)](#tools-experimental)
  + [LSP, Formatters & MCP](#lsp-formatters--mcp)
  + [Agents](#agents)
  + [Logging](#logging)
  + [TUI](#tui)
  + [Auth](#auth)
  + [Events](#events)
  + [Docs](#docs)

### On this page

* [Overview](#_top)
  + [Usage](#usage)
  + [Authentication](#authentication)
  + [How it works](#how-it-works)
* [Spec](#spec)
* [APIs](#apis)
  + [Global](#global)
  + [Project](#project)
  + [Path & VCS](#path--vcs)
  + [Instance](#instance)
  + [Config](#config)
  + [Provider](#provider)
  + [Sessions](#sessions)
  + [Messages](#messages)
  + [Commands](#commands)
  + [Files](#files)
  + [Tools (Experimental)](#tools-experimental)
  + [LSP, Formatters & MCP](#lsp-formatters--mcp)
  + [Agents](#agents)
  + [Logging](#logging)
  + [TUI](#tui)
  + [Auth](#auth)
  + [Events](#events)
  + [Docs](#docs)

## Server

Interact with opencode server over HTTP.

The `opencode serve` command runs a headless HTTP server that exposes an OpenAPI endpoint that an opencode client can use.

---

#### [Usage](#usage)

Terminal window

```
opencode serve [--port <number>] [--hostname <string>] [--cors <origin>]
```

##### [Options](#options)

| Flag | Description | Default |
| --- | --- | --- |
| `--port` | Port to listen on | `4096` |
| `--hostname` | Hostname to listen on | `127.0.0.1` |
| `--mdns` | Enable mDNS discovery | `false` |
| `--mdns-domain` | Custom domain name for mDNS service | `opencode.local` |
| `--cors` | Additional browser origins to allow | `[]` |

`--cors` can be passed multiple times:

Terminal window

```
opencode serve --cors http://localhost:5173 --cors https://app.example.com
```

---

#### [Authentication](#authentication)

Set `OPENCODE_SERVER_PASSWORD` to protect the server with HTTP basic auth. The username defaults to `opencode`, or set `OPENCODE_SERVER_USERNAME` to override it. This applies to both `opencode serve` and `opencode web`.

Terminal window

```
OPENCODE_SERVER_PASSWORD=your-password opencode serve
```

---

#### [How it works](#how-it-works)

When you run `opencode` it starts a TUI and a server. Where the TUI is the
client that talks to the server. The server exposes an OpenAPI 3.1 spec
endpoint. This endpoint is also used to generate an [SDK](/docs/sdk).

Tip

Use the opencode server to interact with opencode programmatically.

This architecture lets opencode support multiple clients and allows you to interact with opencode programmatically.

You can run `opencode serve` to start a standalone server. If you have the
opencode TUI running, `opencode serve` will start a new server.

---

##### [Connect to an existing server](#connect-to-an-existing-server)

When you start the TUI it randomly assigns a port and hostname. You can instead pass in the `--hostname` and `--port` [flags](/docs/cli). Then use this to connect to its server.

The [`/tui`](#tui) endpoint can be used to drive the TUI through the server. For example, you can prefill or run a prompt. This setup is used by the OpenCode [IDE](/docs/ide) plugins.

---

### [Spec](#spec)

The server publishes an OpenAPI 3.1 spec that can be viewed at:

```
http://<hostname>:<port>/doc
```

For example, `http://localhost:4096/doc`. Use the spec to generate clients or inspect request and response types. Or view it in a Swagger explorer.

---

### [APIs](#apis)

The opencode server exposes the following APIs.

---

#### [Global](#global)

| Method | Path | Description | Response |
| --- | --- | --- | --- |
| `GET` | `/global/health` | Get server health and version | `{ healthy: true, version: string }` |
| `GET` | `/global/event` | Get global events (SSE stream) | Event stream |

---

#### [Project](#project)

| Method | Path | Description | Response |
| --- | --- | --- | --- |
| `GET` | `/project` | List all projects | [`Project[]`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) |
| `GET` | `/project/current` | Get the current project | [`Project`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) |

---

#### [Path & VCS](#path--vcs)

| Method | Path | Description | Response |
| --- | --- | --- | --- |
| `GET` | `/path` | Get the current path | [`Path`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) |
| `GET` | `/vcs` | Get VCS info for the current project | [`VcsInfo`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) |

---

#### [Instance](#instance)

| Method | Path | Description | Response |
| --- | --- | --- | --- |
| `POST` | `/instance/dispose` | Dispose the current instance | `boolean` |

---

#### [Config](#config)

| Method | Path | Description | Response |
| --- | --- | --- | --- |
| `GET` | `/config` | Get config info | [`Config`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) |
| `PATCH` | `/config` | Update config | [`Config`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) |
| `GET` | `/config/providers` | List providers and default models | `{ providers:` [Provider[]](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts)`, default: { [key: string]: string } }` |

---

#### [Provider](#provider)

| Method | Path | Description | Response |
| --- | --- | --- | --- |
| `GET` | `/provider` | List all providers | `{ all:` [Provider[]](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts)`, default: {...}, connected: string[] }` |
| `GET` | `/provider/auth` | Get provider authentication methods | `{ [providerID: string]:` [ProviderAuthMethod[]](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) `}` |
| `POST` | `/provider/{id}/oauth/authorize` | Authorize a provider using OAuth | [`ProviderAuthAuthorization`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) |
| `POST` | `/provider/{id}/oauth/callback` | Handle OAuth callback for a provider | `boolean` |

---

#### [Sessions](#sessions)

| Method | Path | Description | Notes |
| --- | --- | --- | --- |
| `GET` | `/session` | List all sessions | Returns [`Session[]`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) |
| `POST` | `/session` | Create a new session | body: `{ parentID?, title? }`, returns [`Session`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) |
| `GET` | `/session/status` | Get session status for all sessions | Returns `{ [sessionID: string]:` [SessionStatus](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) `}` |
| `GET` | `/session/:id` | Get session details | Returns [`Session`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) |
| `DELETE` | `/session/:id` | Delete a session and all its data | Returns `boolean` |
| `PATCH` | `/session/:id` | Update session properties | body: `{ title? }`, returns [`Session`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) |
| `GET` | `/session/:id/children` | Get a sessionâs child sessions | Returns [`Session[]`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) |
| `POST` | `/session/:id/init` | Analyze app and create `AGENTS.md` | body: `{ messageID, providerID, modelID }`, returns `boolean` |
| `POST` | `/session/:id/fork` | Fork an existing session at a message | body: `{ messageID? }`, returns [`Session`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) |
| `POST` | `/session/:id/abort` | Abort a running session | Returns `boolean` |
| `POST` | `/session/:id/share` | Share a session | Returns [`Session`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) |
| `DELETE` | `/session/:id/share` | Unshare a session | Returns [`Session`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) |
| `GET` | `/session/:id/diff` | Get the diff for this session | query: `messageID?`, returns [`FileDiff[]`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) |
| `POST` | `/session/:id/summarize` | Summarize the session | body: `{ providerID, modelID }`, returns `boolean` |
| `POST` | `/session/:id/revert` | Revert a message | body: `{ messageID, partID? }`, returns `boolean` |
| `POST` | `/session/:id/unrevert` | Restore all reverted messages | Returns `boolean` |
| `POST` | `/session/:id/permissions/:permissionID` | Respond to a permission request | body: `{ response, remember? }`, returns `boolean` |

---

#### [Messages](#messages)

| Method | Path | Description | Notes |
| --- | --- | --- | --- |
| `GET` | `/session/:id/message` | List messages in a session | query: `limit?`, returns `{ info:` [Message](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts)`, parts:` [Part[]](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts)`}[]` |
| `POST` | `/session/:id/message` | Send a message and wait for response | body: `{ messageID?, model?, agent?, noReply?, system?, tools?, parts }`, returns `{ info:` [Message](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts)`, parts:` [Part[]](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts)`}` |
| `GET` | `/session/:id/message/:messageID` | Get message details | Returns `{ info:` [Message](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts)`, parts:` [Part[]](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts)`}` |
| `POST` | `/session/:id/prompt_async` | Send a message asynchronously (no wait) | body: same as `/session/:id/message`, returns `204 No Content` |
| `POST` | `/session/:id/command` | Execute a slash command | body: `{ messageID?, agent?, model?, command, arguments }`, returns `{ info:` [Message](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts)`, parts:` [Part[]](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts)`}` |
| `POST` | `/session/:id/shell` | Run a shell command | body: `{ agent, model?, command }`, returns `{ info:` [Message](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts)`, parts:` [Part[]](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts)`}` |

---

#### [Commands](#commands)

| Method | Path | Description | Response |
| --- | --- | --- | --- |
| `GET` | `/command` | List all commands | [`Command[]`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) |

---

#### [Files](#files)

| Method | Path | Description | Response |
| --- | --- | --- | --- |
| `GET` | `/find?pattern=<pat>` | Search for text in files | Array of match objects with `path`, `lines`, `line_number`, `absolute_offset`, `submatches` |
| `GET` | `/find/file?query=<q>` | Find files and directories by name | `string[]` (paths) |
| `GET` | `/find/symbol?query=<q>` | Find workspace symbols | [`Symbol[]`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) |
| `GET` | `/file?path=<path>` | List files and directories | [`FileNode[]`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) |
| `GET` | `/file/content?path=<p>` | Read a file | [`FileContent`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) |
| `GET` | `/file/status` | Get status for tracked files | [`File[]`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) |

##### [`/find/file` query parameters](#findfile-query-parameters)

* `query` (required) â search string (fuzzy match)
* `type` (optional) â limit results to `"file"` or `"directory"`
* `directory` (optional) â override the project root for the search
* `limit` (optional) â max results (1â200)
* `dirs` (optional) â legacy flag (`"false"` returns only files)

---

#### [Tools (Experimental)](#tools-experimental)

| Method | Path | Description | Response |
| --- | --- | --- | --- |
| `GET` | `/experimental/tool/ids` | List all tool IDs | [`ToolIDs`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) |
| `GET` | `/experimental/tool?provider=<p>&model=<m>` | List tools with JSON schemas for a model | [`ToolList`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) |

---

#### [LSP, Formatters & MCP](#lsp-formatters--mcp)

| Method | Path | Description | Response |
| --- | --- | --- | --- |
| `GET` | `/lsp` | Get LSP server status | [`LSPStatus[]`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) |
| `GET` | `/formatter` | Get formatter status | [`FormatterStatus[]`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) |
| `GET` | `/mcp` | Get MCP server status | `{ [name: string]:` [MCPStatus](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) `}` |
| `POST` | `/mcp` | Add MCP server dynamically | body: `{ name, config }`, returns MCP status object |

---

#### [Agents](#agents)

| Method | Path | Description | Response |
| --- | --- | --- | --- |
| `GET` | `/agent` | List all available agents | [`Agent[]`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) |

---

#### [Logging](#logging)

| Method | Path | Description | Response |
| --- | --- | --- | --- |
| `POST` | `/log` | Write log entry. Body: `{ service, level, message, extra? }` | `boolean` |

---

#### [TUI](#tui)

| Method | Path | Description | Response |
| --- | --- | --- | --- |
| `POST` | `/tui/append-prompt` | Append text to the prompt | `boolean` |
| `POST` | `/tui/open-help` | Open the help dialog | `boolean` |
| `POST` | `/tui/open-sessions` | Open the session selector | `boolean` |
| `POST` | `/tui/open-themes` | Open the theme selector | `boolean` |
| `POST` | `/tui/open-models` | Open the model selector | `boolean` |
| `POST` | `/tui/submit-prompt` | Submit the current prompt | `boolean` |
| `POST` | `/tui/clear-prompt` | Clear the prompt | `boolean` |
| `POST` | `/tui/execute-command` | Execute a command (`{ command }`) | `boolean` |
| `POST` | `/tui/show-toast` | Show toast (`{ title?, message, variant }`) | `boolean` |
| `GET` | `/tui/control/next` | Wait for the next control request | Control request object |
| `POST` | `/tui/control/response` | Respond to a control request (`{ body }`) | `boolean` |

---

#### [Auth](#auth)

| Method | Path | Description | Response |
| --- | --- | --- | --- |
| `PUT` | `/auth/:id` | Set authentication credentials. Body must match provider schema | `boolean` |

---

#### [Events](#events)

| Method | Path | Description | Response |
| --- | --- | --- | --- |
| `GET` | `/event` | Server-sent events stream. First event is `server.connected`, then bus events | Server-sent events stream |

---

#### [Docs](#docs)

| Method | Path | Description | Response |
| --- | --- | --- | --- |
| `GET` | `/doc` | OpenAPI 3.1 specification | HTML page with OpenAPI spec |

[Edit page](https://github.com/anomalyco/opencode/edit/dev/packages/web/src/content/docs/server.mdx)[Found a bug? Open an issue](https://github.com/anomalyco/opencode/issues/new)[Join our Discord community](https://opencode.ai/discord)  Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

© [Anomaly](https://anoma.ly)

Last updated: Oct 13, 2026

---
<!--
URL: https://opencode.ai/docs/tui/
title: TUI | OpenCode
-->

[Skip to content](#_top)

[![](/docs/_astro/logo-dark.DOStV66V.svg) ![](/docs/_astro/logo-light.B0yzR0O5.svg)  OpenCode](/docs/)

[app.header.home](/)[app.header.docs](/v2/docs)

Search  `CtrlK`

Cancel

  [New OpenCode v2 is now available →](https://opencode.ai/v2)

* [Intro](/docs/)
* [Config](/docs/config/)
* [Providers](/docs/providers/)
* [Network](/docs/network/)
* [Enterprise](/docs/enterprise/)
* [Troubleshooting](/docs/troubleshooting/)
* [Windows](/docs/windows-wsl)
* Usage

  + [Go](https://opencode.ai/v2/docs/console/go/)
  + [TUI](/docs/tui/)
  + [CLI](/docs/cli/)
  + [Web](/docs/web/)
  + [IDE](/docs/ide/)
  + [Console](https://opencode.ai/v2/docs/console/)
  + [Share](/docs/share/)
  + [GitHub](/docs/github/)
  + [GitLab](/docs/gitlab/)
* Configure

  + [Tools](/docs/tools/)
  + [Rules](/docs/rules/)
  + [Agents](/docs/agents/)
  + [Models](/docs/models/)
  + [Themes](/docs/themes/)
  + [Keybinds](/docs/keybinds/)
  + [Commands](/docs/commands/)
  + [Formatters](/docs/formatters/)
  + [Permissions](/docs/permissions/)
  + [Policies](/docs/policies/)
  + [LSP Servers](/docs/lsp/)
  + [MCP servers](/docs/mcp-servers/)
  + [ACP Support](/docs/acp/)
  + [Agent Skills](/docs/skills/)
  + [References](/docs/references/)
  + [Custom Tools](/docs/custom-tools/)
* Develop

  + [SDK](/docs/sdk/)
  + [Server](/docs/server/)
  + [Plugins](/docs/plugins/)
  + [Ecosystem](/docs/ecosystem/)

[GitHub](https://github.com/anomalyco/opencode)[Discord](https://opencode.ai/discord)

  Select theme   DarkLightAuto         Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

On this page

* [Overview](#_top)
* [File references](#file-references)
* [Bash commands](#bash-commands)
* [Commands](#commands)
  + [connect](#connect)
  + [compact](#compact)
  + [details](#details)
  + [editor](#editor)
  + [exit](#exit)
  + [export](#export)
  + [help](#help)
  + [init](#init)
  + [models](#models)
  + [new](#new)
  + [redo](#redo)
  + [sessions](#sessions)
  + [share](#share)
  + [themes](#themes)
  + [thinking](#thinking)
  + [undo](#undo)
  + [unshare](#unshare)
* [Editor setup](#editor-setup)
* [Configure](#configure)
  + [Options](#options)
  + [Attention](#attention)
* [Customization](#customization)

### On this page

* [Overview](#_top)
* [File references](#file-references)
* [Bash commands](#bash-commands)
* [Commands](#commands)
  + [connect](#connect)
  + [compact](#compact)
  + [details](#details)
  + [editor](#editor)
  + [exit](#exit)
  + [export](#export)
  + [help](#help)
  + [init](#init)
  + [models](#models)
  + [new](#new)
  + [redo](#redo)
  + [sessions](#sessions)
  + [share](#share)
  + [themes](#themes)
  + [thinking](#thinking)
  + [undo](#undo)
  + [unshare](#unshare)
* [Editor setup](#editor-setup)
* [Configure](#configure)
  + [Options](#options)
  + [Attention](#attention)
* [Customization](#customization)

## TUI

Using the OpenCode terminal user interface.

OpenCode provides an interactive terminal interface or TUI for working on your projects with an LLM.

Running OpenCode starts the TUI for the current directory.

Terminal window

```
opencode
```

Or you can start it for a specific working directory.

Terminal window

```
opencode /path/to/project
```

Once youâre in the TUI, you can prompt it with a message.

```
Give me a quick summary of the codebase.
```

---

### [File references](#file-references)

You can reference files in your messages using `@`. This does a fuzzy file search in the current working directory.

Tip

You can also use `@` to reference files in your messages.

```
How is auth handled in @packages/functions/src/api/index.ts?
```

The content of the file is added to the conversation automatically.

Configured [references](/docs/references) also appear in `@` autocomplete. Type `@alias` to add the reference root as context, or type `@alias/` to autocomplete files inside that reference.

```
Compare our setup with @docs/README.md
```

---

### [Bash commands](#bash-commands)

Start a message with `!` to run a shell command.

```
!ls -la
```

The output of the command is added to the conversation as a tool result.

---

### [Commands](#commands)

When using the OpenCode TUI, you can type `/` followed by a command name to quickly execute actions. For example:

```
/help
```

Most commands also have keyboard shortcuts using `ctrl+x` as the default leader key. [Learn more](/docs/keybinds).

Here are all available slash commands:

---

#### [connect](#connect)

Add a provider to OpenCode. Allows you to select from available providers and add their API keys.

```
/connect
```

---

#### [compact](#compact)

Compact the current session. *Alias*: `/summarize`

```
/compact
```

**Keybind:** `ctrl+x c`

---

#### [details](#details)

Toggle tool execution details.

```
/details
```

---

#### [editor](#editor)

Open external editor for composing messages. Uses the editor set in your `EDITOR` environment variable. [Learn more](#editor-setup).

```
/editor
```

**Keybind:** `ctrl+x e`

---

#### [exit](#exit)

Exit OpenCode. *Aliases*: `/quit`, `/q`

```
/exit
```

**Keybind:** `ctrl+x q`

---

#### [export](#export)

Export current conversation to Markdown and open in your default editor. Uses the editor set in your `EDITOR` environment variable. [Learn more](#editor-setup).

```
/export
```

**Keybind:** `ctrl+x x`

---

#### [help](#help)

Show the help dialog.

```
/help
```

---

#### [init](#init)

Guided setup for creating or updating `AGENTS.md`. [Learn more](/docs/rules).

```
/init
```

---

#### [models](#models)

List available models.

```
/models
```

**Keybind:** `ctrl+x m`

---

#### [new](#new)

Start a new session. *Alias*: `/clear`

```
/new
```

**Keybind:** `ctrl+x n`

---

#### [redo](#redo)

Redo a previously undone message. Only available after using `/undo`.

Tip

Any file changes will also be restored.

Internally, this uses Git to manage the file changes. So your project **needs to
be a Git repository**.

```
/redo
```

**Keybind:** `ctrl+x r`

---

#### [sessions](#sessions)

List and switch between sessions. *Aliases*: `/resume`, `/continue`

```
/sessions
```

**Keybind:** `ctrl+x l`

---

#### [share](#share)

Share current session. [Learn more](/docs/share).

```
/share
```

---

#### [themes](#themes)

List available themes.

```
/themes
```

**Keybind:** `ctrl+x t`

---

#### [thinking](#thinking)

Toggle the visibility of thinking/reasoning blocks in the conversation. When enabled, you can see the modelâs reasoning process for models that support extended thinking.

Note

This command only controls whether thinking blocks are **displayed** - it does not enable or disable the modelâs reasoning capabilities. To toggle actual reasoning capabilities, use `ctrl+t` to cycle through model variants.

```
/thinking
```

---

#### [undo](#undo)

Undo last message in the conversation. Removes the most recent user message, all subsequent responses, and any file changes.

Tip

Any file changes made will also be reverted.

Internally, this uses Git to manage the file changes. So your project **needs to
be a Git repository**.

```
/undo
```

**Keybind:** `ctrl+x u`

---

#### [unshare](#unshare)

Unshare current session. [Learn more](/docs/share#un-sharing).

```
/unshare
```

---

### [Editor setup](#editor-setup)

Both the `/editor` and `/export` commands use the editor specified in your `EDITOR` environment variable.

* [Linux/macOS](#tab-panel-4)
* [Windows (CMD)](#tab-panel-5)
* [Windows (PowerShell)](#tab-panel-6)

Terminal window

```

## Example for nano or vim

export EDITOR=nano

export EDITOR=vim

## For GUI editors, VS Code, Cursor, VSCodium, Windsurf, Zed, etc.

## include --wait

export EDITOR="code --wait"
```

To make it permanent, add this to your shell profile;
`~/.bashrc`, `~/.zshrc`, etc.

Terminal window

```
set EDITOR=notepad

## For GUI editors, VS Code, Cursor, VSCodium, Windsurf, Zed, etc.

## include --wait

set EDITOR=code --wait
```

To make it permanent, use **System Properties** > **Environment
Variables**.

Terminal window

```
$env:EDITOR = "notepad"

## For GUI editors, VS Code, Cursor, VSCodium, Windsurf, Zed, etc.

## include --wait

$env:EDITOR = "code --wait"
```

To make it permanent, add this to your PowerShell profile.

Popular editor options include:

* `code` - Visual Studio Code
* `cursor` - Cursor
* `windsurf` - Windsurf
* `nvim` - Neovim editor
* `vim` - Vim editor
* `nano` - Nano editor
* `notepad` - Windows Notepad
* `subl` - Sublime Text

Note

Some editors like VS Code need to be started with the `--wait` flag.

Some editors need command-line arguments to run in blocking mode. The `--wait` flag makes the editor process block until closed.

---

### [Configure](#configure)

You can customize TUI behavior through `tui.json` (or `tui.jsonc`).

tui.json

```
{

"$schema": "https://opencode.ai/tui.json",

"theme": "opencode",

"leader_timeout": 2000,

"keybinds": {

"leader": "ctrl+x",

"command_list": "ctrl+p"

},

"scroll_speed": 3,

"scroll_acceleration": {

"enabled": false

},

"diff_style": "auto",

"cursor": {

"style": "block",

"blinking": true

},

"mouse": true,

"attention": {

"enabled": true,

"notifications": true,

"sound": true,

"volume": 0.4,

"sound_pack": "opencode.default",

"sounds": {

"error": "./sounds/error.mp3"

}

}

}
```

This is separate from `opencode.json`, which configures server/runtime behavior.

`keybinds` is merged with built-in defaults, so you only need to configure the shortcuts you want to change.

#### [Options](#options)

* `theme` - Sets your UI theme. [Learn more](/docs/themes).
* `keybinds` - Customizes keyboard shortcuts. [Learn more](/docs/keybinds).
* `leader_timeout` - Controls how long OpenCode waits after the leader key. Defaults to `2000`.
* `scroll_acceleration.enabled` - Enable macOS-style scroll acceleration for smooth, natural scrolling. When enabled, scroll speed increases with rapid scrolling gestures and stays precise for slower movements. **This setting takes precedence over `scroll_speed` and overrides it when enabled.**
* `scroll_speed` - Controls how fast the TUI scrolls when using scroll commands (minimum: `0.001`, supports decimal values). Defaults to `3`. **Note: This is ignored if `scroll_acceleration.enabled` is set to `true`.**
* `diff_style` - Controls diff rendering. `"auto"` adapts to terminal width, `"stacked"` always shows a single-column layout.
* `cursor` - Controls the terminal cursor in TUI input fields. `style` defaults to `"block"`, can be `"underline"`, `"line"`, or `"default"`; `blinking` defaults to `true`. When `style` is `"default"`, the terminal default cursor is restored, so `blinking` has no effect.
* `mouse` - Enable or disable mouse capture in the TUI (default: `true`). When disabled, the terminalâs native mouse selection/scrolling behavior is preserved.
* `attention` - Configures TUI desktop notifications and sounds. Disabled by default.

Use `OPENCODE_TUI_CONFIG` to load a custom TUI config path.

#### [Attention](#attention)

The TUI can request attention for questions, permissions, session errors, and completed sessions. Enable it with `attention.enabled`; built-in events play sounds when triggered, and non-subagent events request desktop notifications only when the terminal is blurred.

* `enabled` - Enable all attention notifications and sounds. Defaults to `false`.
* `notifications` - Allow terminal-mediated desktop notifications when attention is enabled. Defaults to `true`.
* `sound` - Allow attention sounds when attention is enabled. Defaults to `true`.
* `volume` - Default sound volume from `0` to `1`. Defaults to `0.4`.
* `sound_pack` - Sound pack ID to use. Defaults to `opencode.default`.
* `sounds` - Override sound files for `default`, `question`, `permission`, `error`, `done`, or `subagent_done`. Paths can be absolute, `file://` URLs, or relative to `tui.json`.

---

### [Customization](#customization)

You can customize various aspects of the TUI view using the command palette (`ctrl+p`). These settings persist across restarts.

---

##### [Username display](#username-display)

Toggle whether your username appears in chat messages. Access this through:

* Command palette: Search for âusernameâ or âhide usernameâ
* The setting persists automatically and will be remembered across TUI sessions

[Edit page](https://github.com/anomalyco/opencode/edit/dev/packages/web/src/content/docs/tui.mdx)[Found a bug? Open an issue](https://github.com/anomalyco/opencode/issues/new)[Join our Discord community](https://opencode.ai/discord)  Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

© [Anomaly](https://anoma.ly)

Last updated: Oct 13, 2026

---
<!--
URL: https://opencode.ai/docs/keybinds
title: Keybinds | OpenCode
-->

[Skip to content](#_top)

[![](/docs/_astro/logo-dark.DOStV66V.svg) ![](/docs/_astro/logo-light.B0yzR0O5.svg)  OpenCode](/docs/)

[app.header.home](/)[app.header.docs](/v2/docs)

Search  `CtrlK`

Cancel

  [New OpenCode v2 is now available →](https://opencode.ai/v2)

* [Intro](/docs/)
* [Config](/docs/config/)
* [Providers](/docs/providers/)
* [Network](/docs/network/)
* [Enterprise](/docs/enterprise/)
* [Troubleshooting](/docs/troubleshooting/)
* [Windows](/docs/windows-wsl)
* Usage

  + [Go](https://opencode.ai/v2/docs/console/go/)
  + [TUI](/docs/tui/)
  + [CLI](/docs/cli/)
  + [Web](/docs/web/)
  + [IDE](/docs/ide/)
  + [Console](https://opencode.ai/v2/docs/console/)
  + [Share](/docs/share/)
  + [GitHub](/docs/github/)
  + [GitLab](/docs/gitlab/)
* Configure

  + [Tools](/docs/tools/)
  + [Rules](/docs/rules/)
  + [Agents](/docs/agents/)
  + [Models](/docs/models/)
  + [Themes](/docs/themes/)
  + [Keybinds](/docs/keybinds/)
  + [Commands](/docs/commands/)
  + [Formatters](/docs/formatters/)
  + [Permissions](/docs/permissions/)
  + [Policies](/docs/policies/)
  + [LSP Servers](/docs/lsp/)
  + [MCP servers](/docs/mcp-servers/)
  + [ACP Support](/docs/acp/)
  + [Agent Skills](/docs/skills/)
  + [References](/docs/references/)
  + [Custom Tools](/docs/custom-tools/)
* Develop

  + [SDK](/docs/sdk/)
  + [Server](/docs/server/)
  + [Plugins](/docs/plugins/)
  + [Ecosystem](/docs/ecosystem/)

[GitHub](https://github.com/anomalyco/opencode)[Discord](https://opencode.ai/discord)

  Select theme   DarkLightAuto         Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

On this page

* [Overview](#_top)
* [Leader Key](#leader-key)
* [Binding Values](#binding-values)
* [Disable Keybind](#disable-keybind)
* [Desktop Prompt Shortcuts](#desktop-prompt-shortcuts)
* [Shift+Enter](#shiftenter)
  + [Windows Terminal](#windows-terminal)

### On this page

* [Overview](#_top)
* [Leader Key](#leader-key)
* [Binding Values](#binding-values)
* [Disable Keybind](#disable-keybind)
* [Desktop Prompt Shortcuts](#desktop-prompt-shortcuts)
* [Shift+Enter](#shiftenter)
  + [Windows Terminal](#windows-terminal)

## Keybinds

Customize your keybinds.

OpenCode has a list of keybinds that you can customize through `tui.json`.

tui.json

```
{

"$schema": "https://opencode.ai/tui.json",

"leader_timeout": 2000,

"keybinds": {

"leader": "ctrl+x",

"app_exit": "ctrl+c,ctrl+d,<leader>q",

"app_debug": "none",

"app_console": "none",

"app_heap_snapshot": "none",

"app_toggle_animations": "none",

"app_toggle_file_context": "none",

"app_toggle_diffwrap": "none",

"app_toggle_paste_summary": "none",

"app_toggle_session_directory_filter": "none",

"command_list": "ctrl+p",

"help_show": "none",

"docs_open": "none",

"editor_open": "<leader>e",

"theme_list": "<leader>t",

"theme_switch_mode": "none",

"theme_mode_lock": "none",

"sidebar_toggle": "<leader>b",

"scrollbar_toggle": "none",

"status_view": "<leader>s",

"session_export": "<leader>x",

"session_copy": "none",

"session_move": "none",

"session_new": "<leader>n",

"session_list": "<leader>l",

"session_timeline": "<leader>g",

"session_fork": "none",

"session_rename": "ctrl+r",

"session_delete": "ctrl+d",

"session_share": "none",

"session_unshare": "none",

"session_interrupt": "escape",

"session_compact": "<leader>c",

"session_toggle_timestamps": "none",

"session_toggle_generic_tool_output": "none",

"session_child_first": "<leader>down",

"session_child_cycle": "right",

"session_child_cycle_reverse": "left",

"session_parent": "up",

"stash_delete": "ctrl+d",

"model_provider_list": "ctrl+a",

"model_favorite_toggle": "ctrl+f",

"model_list": "<leader>m",

"model_cycle_recent": "f2",

"model_cycle_recent_reverse": "shift+f2",

"model_cycle_favorite": "none",

"model_cycle_favorite_reverse": "none",

"mcp_list": "none",

"provider_connect": "none",

"console_org_switch": "none",

"agent_list": "<leader>a",

"agent_cycle": "tab",

"agent_cycle_reverse": "shift+tab",

"variant_cycle": "ctrl+t",

"variant_list": "none",

"messages_page_up": "pageup,ctrl+alt+b",

"messages_page_down": "pagedown,ctrl+alt+f",

"messages_line_up": "ctrl+alt+y",

"messages_line_down": "ctrl+alt+e",

"messages_half_page_up": "ctrl+alt+u",

"messages_half_page_down": "ctrl+alt+d",

"messages_first": "ctrl+g,home",

"messages_last": "ctrl+alt+g,end",

"messages_next": "none",

"messages_previous": "none",

"messages_last_user": "none",

"messages_copy": "<leader>y",

"messages_undo": "<leader>u",

"messages_redo": "<leader>r",

"messages_toggle_conceal": "<leader>h",

"tool_details": "none",

"display_thinking": "none",

"prompt_submit": "none",

"prompt_editor_context_clear": "none",

"prompt_skills": "none",

"prompt_stash": "none",

"prompt_stash_pop": "none",

"prompt_stash_list": "none",

"workspace_set": "none",

"input_clear": "ctrl+c",

"input_paste": {

"key": "ctrl+v",

"preventDefault": false

},

"input_submit": "return",

"input_newline": "shift+return,ctrl+return,alt+return,ctrl+j",

"input_move_left": "left,ctrl+b",

"input_move_right": "right,ctrl+f",

"input_move_up": "up",

"input_move_down": "down",

"input_select_left": "shift+left",

"input_select_right": "shift+right",

"input_select_up": "shift+up",

"input_select_down": "shift+down",

"input_line_home": "ctrl+a",

"input_line_end": "ctrl+e",

"input_select_line_home": "ctrl+shift+a",

"input_select_line_end": "ctrl+shift+e",

"input_visual_line_home": "alt+a",

"input_visual_line_end": "alt+e",

"input_select_visual_line_home": "alt+shift+a",

"input_select_visual_line_end": "alt+shift+e",

"input_buffer_home": "home",

"input_buffer_end": "end",

"input_select_buffer_home": "shift+home",

"input_select_buffer_end": "shift+end",

"input_delete_line": "ctrl+shift+d",

"input_delete_to_line_end": "ctrl+k",

"input_delete_to_line_start": "ctrl+u",

"input_backspace": "backspace,shift+backspace",

"input_delete": "ctrl+d,delete,shift+delete",

"input_undo": "ctrl+-,super+z",

"input_redo": "ctrl+.,super+shift+z",

"input_word_forward": "alt+f,alt+right,ctrl+right",

"input_word_backward": "alt+b,alt+left,ctrl+left",

"input_select_word_forward": "alt+shift+f,alt+shift+right",

"input_select_word_backward": "alt+shift+b,alt+shift+left",

"input_delete_word_forward": "alt+d,alt+delete,ctrl+delete",

"input_delete_word_backward": "ctrl+w,ctrl+backspace,alt+backspace",

"input_select_all": "super+a",

"history_previous": "up",

"history_next": "down",

"dialog.select.prev": "up,ctrl+p",

"dialog.select.next": "down,ctrl+n",

"dialog.select.page_up": "pageup",

"dialog.select.page_down": "pagedown",

"dialog.select.home": "home",

"dialog.select.end": "end",

"dialog.select.submit": "return",

"dialog.prompt.submit": "return",

"dialog.mcp.toggle": "space",

"prompt.autocomplete.prev": "up,ctrl+p",

"prompt.autocomplete.next": "down,ctrl+n",

"prompt.autocomplete.hide": "escape",

"prompt.autocomplete.select": "return",

"prompt.autocomplete.complete": "tab",

"permission.prompt.fullscreen": "ctrl+f",

"plugins.toggle": "space",

"dialog.plugins.install": "shift+i",

"terminal_suspend": "ctrl+z",

"terminal_title_toggle": "none",

"plugin_manager": "none",

"plugin_install": "none",

"which_key_toggle": "ctrl+alt+k",

"which_key_layout_toggle": "ctrl+alt+shift+k",

"which_key_pending_toggle": "ctrl+alt+shift+p",

"which_key_group_previous": "ctrl+alt+left,ctrl+alt+[",

"which_key_group_next": "ctrl+alt+right,ctrl+alt+]",

"which_key_scroll_up": "ctrl+alt+up,ctrl+alt+p",

"which_key_scroll_down": "ctrl+alt+down,ctrl+alt+n",

"which_key_page_up": "ctrl+alt+pageup",

"which_key_page_down": "ctrl+alt+pagedown",

"which_key_home": "ctrl+alt+home",

"which_key_end": "ctrl+alt+end"

}

}
```

Note

On Windows, the defaults for `input_undo` and `terminal_suspend` are different:

* `input_undo` defaults to `ctrl+z,ctrl+-,super+z` when it is not explicitly configured. The `ctrl+z` binding is added because Windows terminals do not support POSIX suspend.
* `terminal_suspend` is forced to `none` because native Windows terminals do not support POSIX suspend.

---

### [Leader Key](#leader-key)

OpenCode uses a `leader` key for many keybinds. This avoids conflicts in your terminal.

By default, `ctrl+x` is the leader key and many actions require you to first press the leader key and then the shortcut. For example, to start a new session you first press `ctrl+x` and then press `n`.

You donât need to use a leader key for your keybinds but we recommend doing so.

Some navigation keybinds intentionally do not use the leader key by default. For subagent sessions, the defaults are `session_child_first` = `<leader>down`, `session_child_cycle` = `right`, `session_child_cycle_reverse` = `left`, and `session_parent` = `up`.

`leader_timeout` controls how long OpenCode waits for the next key after the leader key. It defaults to `2000` milliseconds.

---

### [Binding Values](#binding-values)

A string can contain one shortcut or multiple comma-separated shortcuts. You can also use an array for multiple shortcuts.

For advanced cases, use an object with `key`, `event`, `preventDefault`, or `fallthrough`.

tui.json

```
{

"$schema": "https://opencode.ai/tui.json",

"keybinds": {

"messages_copy": ["<leader>y", "ctrl+shift+c"],

"input_paste": {

"key": "ctrl+v",

"preventDefault": false

}

}

}
```

---

### [Disable Keybind](#disable-keybind)

You can disable a keybind by adding the key to `tui.json` with a value of `"none"` or `false`.

tui.json

```
{

"$schema": "https://opencode.ai/tui.json",

"keybinds": {

"session_compact": "none"

}

}
```

---

### [Desktop Prompt Shortcuts](#desktop-prompt-shortcuts)

The OpenCode desktop app prompt input supports common Readline/Emacs-style shortcuts for editing text. These are built-in and currently not configurable via `opencode.json`.

| Shortcut | Action |
| --- | --- |
| `ctrl+a` | Move to start of current line |
| `ctrl+e` | Move to end of current line |
| `ctrl+b` | Move cursor back one character |
| `ctrl+f` | Move cursor forward one character |
| `alt+b` | Move cursor back one word |
| `alt+f` | Move cursor forward one word |
| `ctrl+d` | Delete character under cursor |
| `ctrl+k` | Kill to end of line |
| `ctrl+u` | Kill to start of line |
| `ctrl+w` | Kill previous word |
| `alt+d` | Kill next word |
| `ctrl+t` | Transpose characters |
| `ctrl+g` | Cancel popovers / abort running response |

---

### [Shift+Enter](#shiftenter)

Some terminals donât send modifier keys with Enter by default. You may need to configure your terminal to send `Shift+Enter` as an escape sequence.

#### [Windows Terminal](#windows-terminal)

Open your `settings.json` at:

```
%LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json
```

Add this to the root-level `actions` array:

```
"actions": [

{

"command": {

"action": "sendInput",

"input": "\u001b[13;2u"

},

"id": "User.sendInput.ShiftEnterCustom"

}

]
```

Add this to the root-level `keybindings` array:

```
"keybindings": [

{

"keys": "shift+enter",

"id": "User.sendInput.ShiftEnterCustom"

}

]
```

Save the file and restart Windows Terminal or open a new tab.

[Edit page](https://github.com/anomalyco/opencode/edit/dev/packages/web/src/content/docs/keybinds.mdx)[Found a bug? Open an issue](https://github.com/anomalyco/opencode/issues/new)[Join our Discord community](https://opencode.ai/discord)  Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

© [Anomaly](https://anoma.ly)

Last updated: Oct 13, 2026

---
<!--
URL: https://opencode.ai/docs/formatters
title: Formatters | OpenCode
-->

[Skip to content](#_top)

[![](/docs/_astro/logo-dark.DOStV66V.svg) ![](/docs/_astro/logo-light.B0yzR0O5.svg)  OpenCode](/docs/)

[app.header.home](/)[app.header.docs](/v2/docs)

Search  `CtrlK`

Cancel

  [New OpenCode v2 is now available →](https://opencode.ai/v2)

* [Intro](/docs/)
* [Config](/docs/config/)
* [Providers](/docs/providers/)
* [Network](/docs/network/)
* [Enterprise](/docs/enterprise/)
* [Troubleshooting](/docs/troubleshooting/)
* [Windows](/docs/windows-wsl)
* Usage

  + [Go](https://opencode.ai/v2/docs/console/go/)
  + [TUI](/docs/tui/)
  + [CLI](/docs/cli/)
  + [Web](/docs/web/)
  + [IDE](/docs/ide/)
  + [Console](https://opencode.ai/v2/docs/console/)
  + [Share](/docs/share/)
  + [GitHub](/docs/github/)
  + [GitLab](/docs/gitlab/)
* Configure

  + [Tools](/docs/tools/)
  + [Rules](/docs/rules/)
  + [Agents](/docs/agents/)
  + [Models](/docs/models/)
  + [Themes](/docs/themes/)
  + [Keybinds](/docs/keybinds/)
  + [Commands](/docs/commands/)
  + [Formatters](/docs/formatters/)
  + [Permissions](/docs/permissions/)
  + [Policies](/docs/policies/)
  + [LSP Servers](/docs/lsp/)
  + [MCP servers](/docs/mcp-servers/)
  + [ACP Support](/docs/acp/)
  + [Agent Skills](/docs/skills/)
  + [References](/docs/references/)
  + [Custom Tools](/docs/custom-tools/)
* Develop

  + [SDK](/docs/sdk/)
  + [Server](/docs/server/)
  + [Plugins](/docs/plugins/)
  + [Ecosystem](/docs/ecosystem/)

[GitHub](https://github.com/anomalyco/opencode)[Discord](https://opencode.ai/discord)

  Select theme   DarkLightAuto         Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

On this page

* [Overview](#_top)
* [Built-in](#built-in)
* [How it works](#how-it-works)
* [Configure](#configure)
  + [Disabling formatters](#disabling-formatters)
  + [Custom formatters](#custom-formatters)

### On this page

* [Overview](#_top)
* [Built-in](#built-in)
* [How it works](#how-it-works)
* [Configure](#configure)
  + [Disabling formatters](#disabling-formatters)
  + [Custom formatters](#custom-formatters)

## Formatters

OpenCode uses language specific formatters.

OpenCode can format files after they are written or edited using language-specific formatters. Formatters are disabled by default; enable them in your config before OpenCode will run them.

---

### [Built-in](#built-in)

OpenCode comes with several built-in formatters for popular languages and frameworks. Below is a list of the formatters, supported file extensions, and commands or config options it needs.

| Formatter | Extensions | Requirements |
| --- | --- | --- |
| air | .R | `air` command available |
| biome | .js, .jsx, .ts, .tsx, .html, .css, .md, .json, .yaml, and [more](https://biomejs.dev/) | `biome.json(c)` config file |
| cargofmt | .rs | `cargo fmt` command available |
| clang-format | .c, .cpp, .h, .hpp, .ino, and [more](https://clang.llvm.org/docs/ClangFormat.html) | `.clang-format` config file |
| cljfmt | .clj, .cljs, .cljc, .edn | `cljfmt` command available |
| dart | .dart | `dart` command available |
| dfmt | .d | `dfmt` command available |
| gleam | .gleam | `gleam` command available |
| gofmt | .go | `gofmt` command available |
| htmlbeautifier | .erb, .html.erb | `htmlbeautifier` command available |
| ktlint | .kt, .kts | `ktlint` command available |
| mix | .ex, .exs, .eex, .heex, .leex, .neex, .sface | `mix` command available |
| nixfmt | .nix | `nixfmt` command available |
| ocamlformat | .ml, .mli | `ocamlformat` command available and `.ocamlformat` config file |
| ormolu | .hs | `ormolu` command available |
| oxfmt (Experimental) | .js, .jsx, .ts, .tsx | `oxfmt` dependency in `package.json` and an [experimental env variable flag](/docs/cli/#experimental) |
| pint | .php | `laravel/pint` dependency in `composer.json` |
| prettier | .js, .jsx, .ts, .tsx, .html, .css, .md, .json, .yaml, and [more](https://prettier.io/docs/en/index.html) | `prettier` dependency in `package.json` |
| rubocop | .rb, .rake, .gemspec, .ru | `rubocop` command available |
| ruff | .py, .pyi | `ruff` command available with config |
| rustfmt | .rs | `rustfmt` command available |
| shfmt | .sh, .bash | `shfmt` command available |
| standardrb | .rb, .rake, .gemspec, .ru | `standardrb` command available |
| terraform | .tf, .tfvars | `terraform` command available |
| uv | .py, .pyi | `uv` command available |
| zig | .zig, .zon | `zig` command available |

When formatters are enabled, OpenCode will use `prettier` for matching files if your project has `prettier` in `package.json`.

---

### [How it works](#how-it-works)

When OpenCode writes or edits a file and formatters are enabled, it:

1. Checks the file extension against all enabled formatters.
2. Runs the appropriate formatter command on the file.
3. Applies the formatting changes.

This process happens in the background for enabled formatters.

---

### [Configure](#configure)

You can enable and customize formatters through the `formatter` section in your OpenCode config.

To enable all built-in formatters, set `formatter` to `true`.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"formatter": true

}
```

Use an object to keep built-ins enabled while configuring overrides or custom formatters.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"formatter": {}

}
```

Each formatter configuration supports the following:

| Property | Type | Description |
| --- | --- | --- |
| `disabled` | boolean | Set this to `true` to disable the formatter |
| `command` | string[] | The command to run for formatting. Required for custom formatters; optional for built-ins. |
| `environment` | object | Environment variables to set when running the formatter |
| `extensions` | string[] | File extensions this formatter should handle |

Letâs look at some examples.

---

#### [Disabling formatters](#disabling-formatters)

If `formatter` is omitted, all formatters are disabled. To disable all formatters after another config enabled them, set `formatter` to `false`:

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"formatter": false

}
```

To disable a **specific** formatter, set `disabled` to `true`:

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"formatter": {

"prettier": {

"disabled": true

}

}

}
```

---

#### [Custom formatters](#custom-formatters)

You can configure built-in formatters with options like `environment` or `extensions`. To add a custom formatter, specify a `command` and `extensions`:

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"formatter": {

"prettier": {

"command": ["npx", "prettier", "--write", "$FILE"],

"environment": {

"NODE_ENV": "development"

},

"extensions": [".js", ".ts", ".jsx", ".tsx"]

},

"custom-markdown-formatter": {

"command": ["deno", "fmt", "$FILE"],

"extensions": [".md"]

}

}

}
```

The **`$FILE` placeholder** in the command will be replaced with the path to the file being formatted.

[Edit page](https://github.com/anomalyco/opencode/edit/dev/packages/web/src/content/docs/formatters.mdx)[Found a bug? Open an issue](https://github.com/anomalyco/opencode/issues/new)[Join our Discord community](https://opencode.ai/discord)  Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

© [Anomaly](https://anoma.ly)

Last updated: Oct 13, 2026

---
<!--
URL: https://opencode.ai/docs/acp/
title: ACP Support | OpenCode
-->

[Skip to content](#_top)

[![](/docs/_astro/logo-dark.DOStV66V.svg) ![](/docs/_astro/logo-light.B0yzR0O5.svg)  OpenCode](/docs/)

[app.header.home](/)[app.header.docs](/v2/docs)

Search  `CtrlK`

Cancel

  [New OpenCode v2 is now available →](https://opencode.ai/v2)

* [Intro](/docs/)
* [Config](/docs/config/)
* [Providers](/docs/providers/)
* [Network](/docs/network/)
* [Enterprise](/docs/enterprise/)
* [Troubleshooting](/docs/troubleshooting/)
* [Windows](/docs/windows-wsl)
* Usage

  + [Go](https://opencode.ai/v2/docs/console/go/)
  + [TUI](/docs/tui/)
  + [CLI](/docs/cli/)
  + [Web](/docs/web/)
  + [IDE](/docs/ide/)
  + [Console](https://opencode.ai/v2/docs/console/)
  + [Share](/docs/share/)
  + [GitHub](/docs/github/)
  + [GitLab](/docs/gitlab/)
* Configure

  + [Tools](/docs/tools/)
  + [Rules](/docs/rules/)
  + [Agents](/docs/agents/)
  + [Models](/docs/models/)
  + [Themes](/docs/themes/)
  + [Keybinds](/docs/keybinds/)
  + [Commands](/docs/commands/)
  + [Formatters](/docs/formatters/)
  + [Permissions](/docs/permissions/)
  + [Policies](/docs/policies/)
  + [LSP Servers](/docs/lsp/)
  + [MCP servers](/docs/mcp-servers/)
  + [ACP Support](/docs/acp/)
  + [Agent Skills](/docs/skills/)
  + [References](/docs/references/)
  + [Custom Tools](/docs/custom-tools/)
* Develop

  + [SDK](/docs/sdk/)
  + [Server](/docs/server/)
  + [Plugins](/docs/plugins/)
  + [Ecosystem](/docs/ecosystem/)

[GitHub](https://github.com/anomalyco/opencode)[Discord](https://opencode.ai/discord)

  Select theme   DarkLightAuto         Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

On this page

* [Overview](#_top)
* [Configure](#configure)
  + [Zed](#zed)
  + [JetBrains IDEs](#jetbrains-ides)
  + [Avante.nvim](#avantenvim)
  + [CodeCompanion.nvim](#codecompanionnvim)
* [Support](#support)

### On this page

* [Overview](#_top)
* [Configure](#configure)
  + [Zed](#zed)
  + [JetBrains IDEs](#jetbrains-ides)
  + [Avante.nvim](#avantenvim)
  + [CodeCompanion.nvim](#codecompanionnvim)
* [Support](#support)

## ACP Support

Use OpenCode in any ACP-compatible editor.

OpenCode supports the [Agent Client Protocol](https://agentclientprotocol.com) or (ACP), allowing you to use it directly in compatible editors and IDEs.

Tip

For a list of editors and tools that support ACP, check out the [ACP progress report](https://zed.dev/blog/acp-progress-report#available-now).

ACP is an open protocol that standardizes communication between code editors and AI coding agents.

---

### [Configure](#configure)

To use OpenCode via ACP, configure your editor to run the `opencode acp` command.

The command starts OpenCode as an ACP-compatible subprocess that communicates with your editor over JSON-RPC via stdio.

Below are examples for popular editors that support ACP.

---

#### [Zed](#zed)

Install OpenCode from the [Zed ACP Registry](https://zed.dev/docs/ai/external-agents#registry) by running `zed: acp registry` in the Command Palette.

To use a custom OpenCode executable instead, add it to your [Zed](https://zed.dev) configuration (`~/.config/zed/settings.json`):

~/.config/zed/settings.json

```
{

"agent_servers": {

"OpenCode": {

"type": "custom",

"command": "opencode",

"args": ["acp"]

}

}

}
```

To open it, use the `agent: new thread` action in the **Command Palette**.

You can also bind a keyboard shortcut by editing your `keymap.json`:

keymap.json

```
[

{

"bindings": {

"cmd-alt-o": [

"agent::NewExternalAgentThread",

{

"agent": {

"custom": {

"name": "OpenCode",

"command": {

"command": "opencode",

"args": ["acp"]

}

}

}

}

]

}

}

]
```

---

#### [JetBrains IDEs](#jetbrains-ides)

Add to your [JetBrains IDE](https://www.jetbrains.com/) acp.json according to the [documentation](https://www.jetbrains.com/help/ai-assistant/acp.html):

acp.json

```
{

"agent_servers": {

"OpenCode": {

"command": "/absolute/path/bin/opencode",

"args": ["acp"]

}

}

}
```

To open it, use the new âOpenCodeâ agent in the AI Chat agent selector.

---

#### [Avante.nvim](#avantenvim)

Add to your [Avante.nvim](https://github.com/yetone/avante.nvim) configuration:

```
{

acp_providers = {

["opencode"] = {

command = "opencode",

args = { "acp" }

}

}

}
```

If you need to pass environment variables:

```
{

acp_providers = {

["opencode"] = {

command = "opencode",

args = { "acp" },

env = {

OPENCODE_API_KEY = os.getenv("OPENCODE_API_KEY")

}

}

}

}
```

---

#### [CodeCompanion.nvim](#codecompanionnvim)

To use OpenCode as an ACP agent in [CodeCompanion.nvim](https://github.com/olimorris/codecompanion.nvim), add the following to your Neovim config:

```
require("codecompanion").setup({

interactions = {

chat = {

adapter = {

name = "opencode",

model = "claude-sonnet-4",

},

},

},

})
```

This config sets up CodeCompanion to use OpenCode as the ACP agent for chat.

If you need to pass environment variables (like `OPENCODE_API_KEY`), refer to [Configuring Adapters: Environment Variables](https://codecompanion.olimorris.dev/getting-started#setting-an-api-key) in the CodeCompanion.nvim documentation for full details.

### [Support](#support)

OpenCode works the same via ACP as it does in the terminal. All features are supported:

Note

Some built-in slash commands like `/undo` and `/redo` are currently unsupported.

* Built-in tools (file operations, terminal commands, etc.)
* Custom tools and slash commands
* MCP servers configured in your OpenCode config
* Project-specific rules from `AGENTS.md`
* Custom formatters and linters
* Agents and permissions system

[Edit page](https://github.com/anomalyco/opencode/edit/dev/packages/web/src/content/docs/acp.mdx)[Found a bug? Open an issue](https://github.com/anomalyco/opencode/issues/new)[Join our Discord community](https://opencode.ai/discord)  Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

© [Anomaly](https://anoma.ly)

Last updated: Oct 13, 2026

---
<!--
URL: https://opencode.ai/docs/ecosystem/
title: Ecosystem | OpenCode
-->

[Skip to content](#_top)

[![](/docs/_astro/logo-dark.DOStV66V.svg) ![](/docs/_astro/logo-light.B0yzR0O5.svg)  OpenCode](/docs/)

[app.header.home](/)[app.header.docs](/v2/docs)

Search  `CtrlK`

Cancel

  [New OpenCode v2 is now available →](https://opencode.ai/v2)

* [Intro](/docs/)
* [Config](/docs/config/)
* [Providers](/docs/providers/)
* [Network](/docs/network/)
* [Enterprise](/docs/enterprise/)
* [Troubleshooting](/docs/troubleshooting/)
* [Windows](/docs/windows-wsl)
* Usage

  + [Go](https://opencode.ai/v2/docs/console/go/)
  + [TUI](/docs/tui/)
  + [CLI](/docs/cli/)
  + [Web](/docs/web/)
  + [IDE](/docs/ide/)
  + [Console](https://opencode.ai/v2/docs/console/)
  + [Share](/docs/share/)
  + [GitHub](/docs/github/)
  + [GitLab](/docs/gitlab/)
* Configure

  + [Tools](/docs/tools/)
  + [Rules](/docs/rules/)
  + [Agents](/docs/agents/)
  + [Models](/docs/models/)
  + [Themes](/docs/themes/)
  + [Keybinds](/docs/keybinds/)
  + [Commands](/docs/commands/)
  + [Formatters](/docs/formatters/)
  + [Permissions](/docs/permissions/)
  + [Policies](/docs/policies/)
  + [LSP Servers](/docs/lsp/)
  + [MCP servers](/docs/mcp-servers/)
  + [ACP Support](/docs/acp/)
  + [Agent Skills](/docs/skills/)
  + [References](/docs/references/)
  + [Custom Tools](/docs/custom-tools/)
* Develop

  + [SDK](/docs/sdk/)
  + [Server](/docs/server/)
  + [Plugins](/docs/plugins/)
  + [Ecosystem](/docs/ecosystem/)

[GitHub](https://github.com/anomalyco/opencode)[Discord](https://opencode.ai/discord)

  Select theme   DarkLightAuto         Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

On this page

* [Overview](#_top)
* [Plugins](#plugins)
* [Projects](#projects)
* [Agents](#agents)

### On this page

* [Overview](#_top)
* [Plugins](#plugins)
* [Projects](#projects)
* [Agents](#agents)

## Ecosystem

Projects and integrations built with OpenCode.

A collection of community projects built on OpenCode.

Note

Want to add your OpenCode related project to this list? Submit a PR.

You can also check out [awesome-opencode](https://github.com/awesome-opencode/awesome-opencode) and [opencode.cafe](https://opencode.cafe), a community that aggregates the ecosystem and community.

---

### [Plugins](#plugins)

| Name | Description |
| --- | --- |
| [opencode-daytona](https://github.com/daytona/integrations/tree/main/packages/opencode-plugin) | Automatically run OpenCode sessions in isolated Daytona sandboxes with git sync and live previews |
| [opencode-helicone-session](https://github.com/H2Shami/opencode-helicone-session) | Automatically inject Helicone session headers for request grouping |
| [opencode-type-inject](https://github.com/nick-vi/opencode-type-inject) | Auto-inject TypeScript/Svelte types into file reads with lookup tools |
| [opencode-openai-codex-auth](https://github.com/numman-ali/opencode-openai-codex-auth) | Use your ChatGPT Plus/Pro subscription instead of API credits |
| [opencode-gemini-auth](https://github.com/jenslys/opencode-gemini-auth) | Use your existing Gemini plan instead of API billing |
| [opencode-antigravity-auth](https://github.com/NoeFabris/opencode-antigravity-auth) | Use Antigravityâs free models instead of API billing |
| [opencode-devcontainers](https://github.com/athal7/opencode-devcontainers) | Multi-branch devcontainer isolation with shallow clones and auto-assigned ports |
| [opencode-google-antigravity-auth](https://github.com/shekohex/opencode-google-antigravity-auth) | Google Antigravity OAuth Plugin, with support for Google Search, and more robust API handling |
| [opencode-dynamic-context-pruning](https://github.com/Tarquinen/opencode-dynamic-context-pruning) | Optimize token usage by pruning obsolete tool outputs |
| [opencode-vibeguard](https://github.com/inkdust2021/opencode-vibeguard) | Redact secrets/PII into VibeGuard-style placeholders before LLM calls; restore locally |
| [opencode-websearch-cited](https://github.com/ghoulr/opencode-websearch-cited.git) | Add native websearch support for supported providers with Google grounded style |
| [opencode-pty](https://github.com/shekohex/opencode-pty.git) | Enables AI agents to run background processes in a PTY, send interactive input to them. |
| [opencode-shell-strategy](https://github.com/JRedeker/opencode-shell-strategy) | Instructions for non-interactive shell commands - prevents hangs from TTY-dependent operations |
| [opencode-wakatime](https://github.com/angristan/opencode-wakatime) | Track OpenCode usage with Wakatime |
| [opencode-md-table-formatter](https://github.com/franlol/opencode-md-table-formatter/tree/main) | Clean up markdown tables produced by LLMs |
| [opencode-morph-fast-apply](https://github.com/JRedeker/opencode-morph-fast-apply) | 10x faster code editing with Morph Fast Apply API and lazy edit markers |
| [opencode-morph-plugin](https://github.com/morphllm/opencode-morph-plugin) | Fast Apply editing, WarpGrep codebase search, and context compaction via Morph |
| [oh-my-opencode](https://github.com/code-yeongyu/oh-my-opencode) | Background agents, pre-built LSP/AST/MCP tools, curated agents, Claude Code compatible |
| [opencode-notificator](https://github.com/panta82/opencode-notificator) | Desktop notifications and sound alerts for OpenCode sessions |
| [opencode-notifier](https://github.com/mohak34/opencode-notifier) | Desktop notifications and sound alerts for permission, completion, and error events |
| [opencode-zellij-namer](https://github.com/24601/opencode-zellij-namer) | AI-powered automatic Zellij session naming based on OpenCode context |
| [opencode-skillful](https://github.com/zenobi-us/opencode-skillful) | Allow OpenCode agents to lazy load prompts on demand with skill discovery and injection |
| [opencode-supermemory](https://github.com/supermemoryai/opencode-supermemory) | Persistent memory across sessions using Supermemory |
| [@plannotator/opencode](https://github.com/backnotprop/plannotator/tree/main/apps/opencode-plugin) | Interactive plan review with visual annotation and private/offline sharing |
| [@openspoon/subtask2](https://github.com/spoons-and-mirrors/subtask2) | Extend opencode /commands into a powerful orchestration system with granular flow control |
| [opencode-scheduler](https://github.com/different-ai/opencode-scheduler) | Schedule recurring jobs using launchd (Mac) or systemd (Linux) with cron syntax |
| [opencode-conductor](https://github.com/derekbar90/opencode-conductor) | Protocol-Driven Workflow: Automation of the Context -> Spec -> Plan -> Implement lifecycle. |
| [micode](https://github.com/vtemian/micode) | Structured Brainstorm â Plan â Implement workflow with session continuity |
| [octto](https://github.com/vtemian/octto) | Interactive browser UI for AI brainstorming with multi-question forms |
| [opencode-background-agents](https://github.com/kdcokenny/opencode-background-agents) | Claude Code-style background agents with async delegation and context persistence |
| [opencode-notify](https://github.com/kdcokenny/opencode-notify) | Native OS notifications for OpenCode â know when tasks complete |
| [opencode-workspace](https://github.com/kdcokenny/opencode-workspace) | Bundled multi-agent orchestration harness â 16 components, one install |
| [opencode-worktree](https://github.com/kdcokenny/opencode-worktree) | Zero-friction git worktrees for OpenCode |
| [opencode-sentry-monitor](https://github.com/stolinski/opencode-sentry-monitor) | Trace and debug your AI agents with Sentry AI Monitoring |
| [opencode-firecrawl](https://github.com/firecrawl/opencode-firecrawl) | Web scraping, crawling, and search via the Firecrawl CLI |
| [opencode-jfrog-plugin](https://github.com/jfrog/opencode-jfrog-plugin) | JFrog Plugin for seamless integration of Opencode users to JFrog platform |
| [opencode-goal-plugin](https://github.com/willytop8/OpenCode-goal-plugin) | Session-scoped `/goal` workflow that keeps objectives in context and auto-continues until complete |
| [opencode-tavily](https://github.com/tavily-ai/opencode-tavily) | Web search, extraction, crawling, and deep research via the Tavily CLI |
| [opencode-supabase](https://github.com/supabase-community/opencode-supabase) | Supabase plugin for OpenCode: account login, Management API tools, bundled Supabase agent skills, and guided Supabase MCP setup. |

---

### [Projects](#projects)

| Name | Description |
| --- | --- |
| [kimaki](https://kimaki.dev) | Discord bot to control OpenCode sessions, built on the SDK |
| [opencode.nvim](https://github.com/NickvanDyke/opencode.nvim) | Neovim plugin for editor-aware prompts, built on the API |
| [portal](https://github.com/hosenur/portal) | Mobile-first web UI for OpenCode over Tailscale/VPN |
| [opencode plugin template](https://github.com/zenobi-us/opencode-plugin-template/) | Template for building OpenCode plugins |
| [opencode.nvim](https://github.com/sudo-tee/opencode.nvim) | Neovim frontend for opencode - a terminal-based AI coding agent |
| [ai-sdk-provider-opencode-sdk](https://github.com/ben-vargas/ai-sdk-provider-opencode-sdk) | Vercel AI SDK provider for using OpenCode via @opencode-ai/sdk |
| [OpenChamber](https://github.com/btriapitsyn/openchamber) | Web / Desktop App and VS Code Extension for OpenCode |
| [OpenCode-Obsidian](https://github.com/mtymek/opencode-obsidian) | Obsidian plugin that embeds OpenCode in Obsidianâs UI |
| [OpenWork](https://github.com/different-ai/openwork) | An open-source alternative to Claude Cowork, powered by OpenCode |
| [ocx](https://github.com/kdcokenny/ocx) | OpenCode extension manager with portable, isolated profiles. |
| [CodeNomad](https://github.com/NeuralNomadsAI/CodeNomad) | Desktop, Web, Mobile and Remote Client App for OpenCode |

---

### [Agents](#agents)

| Name | Description |
| --- | --- |
| [Agentic](https://github.com/Cluster444/agentic) | Modular AI agents and commands for structured development |
| [opencode-agents](https://github.com/darrenhinde/opencode-agents) | Configs, prompts, agents, and plugins for enhanced workflows |

[Edit page](https://github.com/anomalyco/opencode/edit/dev/packages/web/src/content/docs/ecosystem.mdx)[Found a bug? Open an issue](https://github.com/anomalyco/opencode/issues/new)[Join our Discord community](https://opencode.ai/discord)  Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

© [Anomaly](https://anoma.ly)

Last updated: Oct 13, 2026

---
<!--
URL: https://opencode.ai/docs/themes
title: Themes | OpenCode
-->

[Skip to content](#_top)

[![](/docs/_astro/logo-dark.DOStV66V.svg) ![](/docs/_astro/logo-light.B0yzR0O5.svg)  OpenCode](/docs/)

[app.header.home](/)[app.header.docs](/v2/docs)

Search  `CtrlK`

Cancel

  [New OpenCode v2 is now available →](https://opencode.ai/v2)

* [Intro](/docs/)
* [Config](/docs/config/)
* [Providers](/docs/providers/)
* [Network](/docs/network/)
* [Enterprise](/docs/enterprise/)
* [Troubleshooting](/docs/troubleshooting/)
* [Windows](/docs/windows-wsl)
* Usage

  + [Go](https://opencode.ai/v2/docs/console/go/)
  + [TUI](/docs/tui/)
  + [CLI](/docs/cli/)
  + [Web](/docs/web/)
  + [IDE](/docs/ide/)
  + [Console](https://opencode.ai/v2/docs/console/)
  + [Share](/docs/share/)
  + [GitHub](/docs/github/)
  + [GitLab](/docs/gitlab/)
* Configure

  + [Tools](/docs/tools/)
  + [Rules](/docs/rules/)
  + [Agents](/docs/agents/)
  + [Models](/docs/models/)
  + [Themes](/docs/themes/)
  + [Keybinds](/docs/keybinds/)
  + [Commands](/docs/commands/)
  + [Formatters](/docs/formatters/)
  + [Permissions](/docs/permissions/)
  + [Policies](/docs/policies/)
  + [LSP Servers](/docs/lsp/)
  + [MCP servers](/docs/mcp-servers/)
  + [ACP Support](/docs/acp/)
  + [Agent Skills](/docs/skills/)
  + [References](/docs/references/)
  + [Custom Tools](/docs/custom-tools/)
* Develop

  + [SDK](/docs/sdk/)
  + [Server](/docs/server/)
  + [Plugins](/docs/plugins/)
  + [Ecosystem](/docs/ecosystem/)

[GitHub](https://github.com/anomalyco/opencode)[Discord](https://opencode.ai/discord)

  Select theme   DarkLightAuto         Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

On this page

* [Overview](#_top)
* [Terminal requirements](#terminal-requirements)
* [Built-in themes](#built-in-themes)
* [System theme](#system-theme)
* [Using a theme](#using-a-theme)
* [Custom themes](#custom-themes)
  + [Hierarchy](#hierarchy)
  + [Creating a theme](#creating-a-theme)
  + [JSON format](#json-format)
  + [Color definitions](#color-definitions)
  + [Terminal defaults](#terminal-defaults)
  + [Example](#example)

### On this page

* [Overview](#_top)
* [Terminal requirements](#terminal-requirements)
* [Built-in themes](#built-in-themes)
* [System theme](#system-theme)
* [Using a theme](#using-a-theme)
* [Custom themes](#custom-themes)
  + [Hierarchy](#hierarchy)
  + [Creating a theme](#creating-a-theme)
  + [JSON format](#json-format)
  + [Color definitions](#color-definitions)
  + [Terminal defaults](#terminal-defaults)
  + [Example](#example)

## Themes

Select a built-in theme or define your own.

With OpenCode you can select from one of several built-in themes, use a theme that adapts to your terminal theme, or define your own custom theme.

By default, OpenCode uses our own `opencode` theme.

---

### [Terminal requirements](#terminal-requirements)

For themes to display correctly with their full color palette, your terminal must support **truecolor** (24-bit color). Most modern terminals support this by default, but you may need to enable it:

* **Check support**: Run `echo $COLORTERM` - it should output `truecolor` or `24bit`
* **Enable truecolor**: Set the environment variable `COLORTERM=truecolor` in your shell profile
* **Terminal compatibility**: Ensure your terminal emulator supports 24-bit color (most modern terminals like iTerm2, Alacritty, Kitty, Windows Terminal, and recent versions of GNOME Terminal do)

Without truecolor support, themes may appear with reduced color accuracy or fall back to the nearest 256-color approximation.

---

### [Built-in themes](#built-in-themes)

OpenCode comes with several built-in themes.

| Name | Description |
| --- | --- |
| `system` | Adapts to your terminalâs background color |
| `tokyonight` | Based on the [Tokyonight](https://github.com/folke/tokyonight.nvim) theme |
| `everforest` | Based on the [Everforest](https://github.com/sainnhe/everforest) theme |
| `ayu` | Based on the [Ayu](https://github.com/ayu-theme) dark theme |
| `catppuccin` | Based on the [Catppuccin](https://github.com/catppuccin) theme |
| `catppuccin-macchiato` | Based on the [Catppuccin](https://github.com/catppuccin) theme |
| `gruvbox` | Based on the [Gruvbox](https://github.com/morhetz/gruvbox) theme |
| `kanagawa` | Based on the [Kanagawa](https://github.com/rebelot/kanagawa.nvim) theme |
| `nord` | Based on the [Nord](https://github.com/nordtheme/nord) theme |
| `matrix` | Hacker-style green on black theme |
| `one-dark` | Based on the [Atom One](https://github.com/Th3Whit3Wolf/one-nvim) Dark theme |

And more, we are constantly adding new themes.

---

### [System theme](#system-theme)

The `system` theme is designed to automatically adapt to your terminalâs color scheme. Unlike traditional themes that use fixed colors, the *system* theme:

* **Generates gray scale**: Creates a custom gray scale based on your terminalâs background color, ensuring optimal contrast.
* **Uses ANSI colors**: Leverages standard ANSI colors (0-15) for syntax highlighting and UI elements, which respect your terminalâs color palette.
* **Preserves terminal defaults**: Uses `none` for text and background colors to maintain your terminalâs native appearance.

The system theme is for users who:

* Want OpenCode to match their terminalâs appearance
* Use custom terminal color schemes
* Prefer a consistent look across all terminal applications

---

### [Using a theme](#using-a-theme)

You can select a theme by bringing up the theme select with the `/theme` command. Or you can specify it in `tui.json`.

tui.json

```
{

"$schema": "https://opencode.ai/tui.json",

"theme": "tokyonight"

}
```

---

### [Custom themes](#custom-themes)

OpenCode supports a flexible JSON-based theme system that allows users to create and customize themes easily.

---

#### [Hierarchy](#hierarchy)

Themes are loaded from multiple directories in the following order where later directories override earlier ones:

1. **Built-in themes** - These are embedded in the binary
2. **User config directory** - Defined in `~/.config/opencode/themes/*.json` or `$XDG_CONFIG_HOME/opencode/themes/*.json`
3. **Project root directory** - Defined in the `<project-root>/.opencode/themes/*.json`
4. **Current working directory** - Defined in `./.opencode/themes/*.json`

If multiple directories contain a theme with the same name, the theme from the directory with higher priority will be used.

---

#### [Creating a theme](#creating-a-theme)

To create a custom theme, create a JSON file in one of the theme directories.

For user-wide themes:

Terminal window

```
mkdir -p ~/.config/opencode/themes

vim ~/.config/opencode/themes/my-theme.json
```

And for project-specific themes.

Terminal window

```
mkdir -p .opencode/themes

vim .opencode/themes/my-theme.json
```

---

#### [JSON format](#json-format)

Themes use a flexible JSON format with support for:

* **Hex colors**: `"#ffffff"`
* **ANSI colors**: `3` (0-255)
* **Color references**: `"primary"` or custom definitions
* **Dark/light variants**: `{"dark": "#000", "light": "#fff"}`
* **No color**: `"none"` - Uses the terminalâs default color or transparent

---

#### [Color definitions](#color-definitions)

The `defs` section is optional and it allows you to define reusable colors that can be referenced in the theme.

---

#### [Terminal defaults](#terminal-defaults)

The special value `"none"` can be used for any color to inherit the terminalâs default color. This is particularly useful for creating themes that blend seamlessly with your terminalâs color scheme:

* `"text": "none"` - Uses terminalâs default foreground color
* `"background": "none"` - Uses terminalâs default background color

---

#### [Example](#example)

Hereâs an example of a custom theme:

my-theme.json

```
{

"$schema": "https://opencode.ai/theme.json",

"defs": {

"nord0": "#2E3440",

"nord1": "#3B4252",

"nord2": "#434C5E",

"nord3": "#4C566A",

"nord4": "#D8DEE9",

"nord5": "#E5E9F0",

"nord6": "#ECEFF4",

"nord7": "#8FBCBB",

"nord8": "#88C0D0",

"nord9": "#81A1C1",

"nord10": "#5E81AC",

"nord11": "#BF616A",

"nord12": "#D08770",

"nord13": "#EBCB8B",

"nord14": "#A3BE8C",

"nord15": "#B48EAD"

},

"theme": {

"primary": {

"dark": "nord8",

"light": "nord10"

},

"secondary": {

"dark": "nord9",

"light": "nord9"

},

"accent": {

"dark": "nord7",

"light": "nord7"

},

"error": {

"dark": "nord11",

"light": "nord11"

},

"warning": {

"dark": "nord12",

"light": "nord12"

},

"success": {

"dark": "nord14",

"light": "nord14"

},

"info": {

"dark": "nord8",

"light": "nord10"

},

"text": {

"dark": "nord4",

"light": "nord0"

},

"textMuted": {

"dark": "nord3",

"light": "nord1"

},

"background": {

"dark": "nord0",

"light": "nord6"

},

"backgroundPanel": {

"dark": "nord1",

"light": "nord5"

},

"backgroundElement": {

"dark": "nord1",

"light": "nord4"

},

"border": {

"dark": "nord2",

"light": "nord3"

},

"borderActive": {

"dark": "nord3",

"light": "nord2"

},

"borderSubtle": {

"dark": "nord2",

"light": "nord3"

},

"diffAdded": {

"dark": "nord14",

"light": "nord14"

},

"diffRemoved": {

"dark": "nord11",

"light": "nord11"

},

"diffContext": {

"dark": "nord3",

"light": "nord3"

},

"diffHunkHeader": {

"dark": "nord3",

"light": "nord3"

},

"diffHighlightAdded": {

"dark": "nord14",

"light": "nord14"

},

"diffHighlightRemoved": {

"dark": "nord11",

"light": "nord11"

},

"diffAddedBg": {

"dark": "#3B4252",

"light": "#E5E9F0"

},

"diffRemovedBg": {

"dark": "#3B4252",

"light": "#E5E9F0"

},

"diffContextBg": {

"dark": "nord1",

"light": "nord5"

},

"diffLineNumber": {

"dark": "nord2",

"light": "nord4"

},

"diffAddedLineNumberBg": {

"dark": "#3B4252",

"light": "#E5E9F0"

},

"diffRemovedLineNumberBg": {

"dark": "#3B4252",

"light": "#E5E9F0"

},

"markdownText": {

"dark": "nord4",

"light": "nord0"

},

"markdownHeading": {

"dark": "nord8",

"light": "nord10"

},

"markdownLink": {

"dark": "nord9",

"light": "nord9"

},

"markdownLinkText": {

"dark": "nord7",

"light": "nord7"

},

"markdownCode": {

"dark": "nord14",

"light": "nord14"

},

"markdownBlockQuote": {

"dark": "nord3",

"light": "nord3"

},

"markdownEmph": {

"dark": "nord12",

"light": "nord12"

},

"markdownStrong": {

"dark": "nord13",

"light": "nord13"

},

"markdownHorizontalRule": {

"dark": "nord3",

"light": "nord3"

},

"markdownListItem": {

"dark": "nord8",

"light": "nord10"

},

"markdownListEnumeration": {

"dark": "nord7",

"light": "nord7"

},

"markdownImage": {

"dark": "nord9",

"light": "nord9"

},

"markdownImageText": {

"dark": "nord7",

"light": "nord7"

},

"markdownCodeBlock": {

"dark": "nord4",

"light": "nord0"

},

"syntaxComment": {

"dark": "nord3",

"light": "nord3"

},

"syntaxKeyword": {

"dark": "nord9",

"light": "nord9"

},

"syntaxFunction": {

"dark": "nord8",

"light": "nord8"

},

"syntaxVariable": {

"dark": "nord7",

"light": "nord7"

},

"syntaxString": {

"dark": "nord14",

"light": "nord14"

},

"syntaxNumber": {

"dark": "nord15",

"light": "nord15"

},

"syntaxType": {

"dark": "nord7",

"light": "nord7"

},

"syntaxOperator": {

"dark": "nord9",

"light": "nord9"

},

"syntaxPunctuation": {

"dark": "nord4",

"light": "nord0"

}

}

}
```

[Edit page](https://github.com/anomalyco/opencode/edit/dev/packages/web/src/content/docs/themes.mdx)[Found a bug? Open an issue](https://github.com/anomalyco/opencode/issues/new)[Join our Discord community](https://opencode.ai/discord)  Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

© [Anomaly](https://anoma.ly)

Last updated: Oct 13, 2026

---
<!--
URL: https://opencode.ai/docs/references/
title: References | OpenCode
-->

[Skip to content](#_top)

[![](/docs/_astro/logo-dark.DOStV66V.svg) ![](/docs/_astro/logo-light.B0yzR0O5.svg)  OpenCode](/docs/)

[app.header.home](/)[app.header.docs](/v2/docs)

Search  `CtrlK`

Cancel

  [New OpenCode v2 is now available →](https://opencode.ai/v2)

* [Intro](/docs/)
* [Config](/docs/config/)
* [Providers](/docs/providers/)
* [Network](/docs/network/)
* [Enterprise](/docs/enterprise/)
* [Troubleshooting](/docs/troubleshooting/)
* [Windows](/docs/windows-wsl)
* Usage

  + [Go](https://opencode.ai/v2/docs/console/go/)
  + [TUI](/docs/tui/)
  + [CLI](/docs/cli/)
  + [Web](/docs/web/)
  + [IDE](/docs/ide/)
  + [Console](https://opencode.ai/v2/docs/console/)
  + [Share](/docs/share/)
  + [GitHub](/docs/github/)
  + [GitLab](/docs/gitlab/)
* Configure

  + [Tools](/docs/tools/)
  + [Rules](/docs/rules/)
  + [Agents](/docs/agents/)
  + [Models](/docs/models/)
  + [Themes](/docs/themes/)
  + [Keybinds](/docs/keybinds/)
  + [Commands](/docs/commands/)
  + [Formatters](/docs/formatters/)
  + [Permissions](/docs/permissions/)
  + [Policies](/docs/policies/)
  + [LSP Servers](/docs/lsp/)
  + [MCP servers](/docs/mcp-servers/)
  + [ACP Support](/docs/acp/)
  + [Agent Skills](/docs/skills/)
  + [References](/docs/references/)
  + [Custom Tools](/docs/custom-tools/)
* Develop

  + [SDK](/docs/sdk/)
  + [Server](/docs/server/)
  + [Plugins](/docs/plugins/)
  + [Ecosystem](/docs/ecosystem/)

[GitHub](https://github.com/anomalyco/opencode)[Discord](https://opencode.ai/discord)

  Select theme   DarkLightAuto         Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

On this page

* [Overview](#_top)
* [Local directories](#local-directories)
* [Git repositories](#git-repositories)
* [Describe usage](#describe-usage)
* [Hide autocomplete entries](#hide-autocomplete-entries)
* [Use references](#use-references)
* [Configure fields](#configure-fields)

### On this page

* [Overview](#_top)
* [Local directories](#local-directories)
* [Git repositories](#git-repositories)
* [Describe usage](#describe-usage)
* [Hide autocomplete entries](#hide-autocomplete-entries)
* [Use references](#use-references)
* [Configure fields](#configure-fields)

## References

Add local directories and Git repositories as project references.

References give OpenCode access to directories outside the current project. Use them to make documentation, shared libraries, examples, or another repository available while you work.

References are configured by alias in `opencode.json` or `opencode.jsonc`.

opencode.jsonc

```
{

"$schema": "https://opencode.ai/config.json",

"references": {

"docs": {

"path": "../product-docs",

"description": "Use for product behavior and documentation conventions",

},

"sdk": {

"repository": "anomalyco/opencode-sdk-js",

"branch": "main",

"description": "Use for JavaScript SDK implementation details",

},

},

}
```

---

### [Local directories](#local-directories)

Use `path` to reference a local directory.

opencode.jsonc

```
{

"references": {

"docs": {

"path": "../docs",

},

},

}
```

Paths can be:

* Relative to the config file that defines the reference
* Absolute, such as `/home/user/docs`
* Relative to your home directory, such as `~/docs`

You can also use a string shorthand:

opencode.jsonc

```
{

"references": {

"docs": "../docs",

},

}
```

---

### [Git repositories](#git-repositories)

Use `repository` to reference a Git repository. OpenCode materializes the repository in its local repository cache and makes the checked-out source available as a reference directory.

opencode.jsonc

```
{

"references": {

"effect": {

"repository": "Effect-TS/effect",

"branch": "main",

},

},

}
```

`repository` accepts Git URLs, host/path references, and GitHub `owner/repo` shorthand. The optional `branch` field selects a branch or ref. Without `branch`, OpenCode uses the repositoryâs default branch.

You can use string shorthand when you do not need a branch, description, or other options:

opencode.jsonc

```
{

"references": {

"effect": "Effect-TS/effect",

},

}
```

Note

Git references are refreshed asynchronously. A newly configured repository may take a moment to finish cloning or updating.

---

### [Describe usage](#describe-usage)

Add `description` to explain when an agent should use a reference.

opencode.jsonc

```
{

"references": {

"design-system": {

"path": "../design-system",

"description": "Use when implementing UI components or design tokens",

},

},

}
```

OpenCode includes references with descriptions in agent context. Descriptions should be short and specific enough to distinguish references with similar content. References without descriptions remain available through autocomplete and direct use, but are not advertised to agents.

---

### [Hide autocomplete entries](#hide-autocomplete-entries)

Set `hidden` to `true` to omit a reference from `@` autocomplete in the TUI.

opencode.jsonc

```
{

"references": {

"internal": {

"path": "../internal",

"description": "Use for internal implementation details",

"hidden": true,

},

},

}
```

`hidden` only affects autocomplete. A hidden reference with a description remains included in agent context.

---

### [Use references](#use-references)

Configured references appear in TUI `@` autocomplete. Type `@alias` to attach the reference root, or `@alias/` to search for files inside it.

```
Compare this implementation with @sdk/src/client.ts
```

Agents also receive the resolved paths and descriptions of configured references that have descriptions in their system context, so they can inspect a reference when it is relevant without you attaching it manually.

OpenCode automatically allows reference directories through its external-directory permission boundary. Normal tool permissions still apply; for example, an agent that cannot edit files does not gain edit access because a directory is configured as a reference.

---

### [Configure fields](#configure-fields)

| Field | Local | Git | Description |
| --- | --- | --- | --- |
| `path` | Yes | No | Local reference directory |
| `repository` | No | Yes | Git URL, host/path, or GitHub `owner/repo` value |
| `branch` | No | Yes | Optional Git branch or ref |
| `description` | Yes | Yes | Guidance describing when to use the reference |
| `hidden` | Yes | Yes | Hide the reference from TUI `@` autocomplete |

Reference aliases cannot be empty or contain `/`, whitespace, backticks, or commas.

[Edit page](https://github.com/anomalyco/opencode/edit/dev/packages/web/src/content/docs/references.mdx)[Found a bug? Open an issue](https://github.com/anomalyco/opencode/issues/new)[Join our Discord community](https://opencode.ai/discord)  Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

© [Anomaly](https://anoma.ly)

Last updated: Oct 13, 2026

---
<!--
URL: https://opencode.ai/docs/commands/
title: Commands | OpenCode
-->

[Skip to content](#_top)

[![](/docs/_astro/logo-dark.DOStV66V.svg) ![](/docs/_astro/logo-light.B0yzR0O5.svg)  OpenCode](/docs/)

[app.header.home](/)[app.header.docs](/v2/docs)

Search  `CtrlK`

Cancel

  [New OpenCode v2 is now available →](https://opencode.ai/v2)

* [Intro](/docs/)
* [Config](/docs/config/)
* [Providers](/docs/providers/)
* [Network](/docs/network/)
* [Enterprise](/docs/enterprise/)
* [Troubleshooting](/docs/troubleshooting/)
* [Windows](/docs/windows-wsl)
* Usage

  + [Go](https://opencode.ai/v2/docs/console/go/)
  + [TUI](/docs/tui/)
  + [CLI](/docs/cli/)
  + [Web](/docs/web/)
  + [IDE](/docs/ide/)
  + [Console](https://opencode.ai/v2/docs/console/)
  + [Share](/docs/share/)
  + [GitHub](/docs/github/)
  + [GitLab](/docs/gitlab/)
* Configure

  + [Tools](/docs/tools/)
  + [Rules](/docs/rules/)
  + [Agents](/docs/agents/)
  + [Models](/docs/models/)
  + [Themes](/docs/themes/)
  + [Keybinds](/docs/keybinds/)
  + [Commands](/docs/commands/)
  + [Formatters](/docs/formatters/)
  + [Permissions](/docs/permissions/)
  + [Policies](/docs/policies/)
  + [LSP Servers](/docs/lsp/)
  + [MCP servers](/docs/mcp-servers/)
  + [ACP Support](/docs/acp/)
  + [Agent Skills](/docs/skills/)
  + [References](/docs/references/)
  + [Custom Tools](/docs/custom-tools/)
* Develop

  + [SDK](/docs/sdk/)
  + [Server](/docs/server/)
  + [Plugins](/docs/plugins/)
  + [Ecosystem](/docs/ecosystem/)

[GitHub](https://github.com/anomalyco/opencode)[Discord](https://opencode.ai/discord)

  Select theme   DarkLightAuto         Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

On this page

* [Overview](#_top)
* [Create command files](#create-command-files)
* [Configure](#configure)
  + [JSON](#json)
  + [Markdown](#markdown)
* [Prompt config](#prompt-config)
  + [Arguments](#arguments)
  + [Shell output](#shell-output)
  + [File references](#file-references)
* [Options](#options)
  + [Template](#template)
  + [Description](#description)
  + [Agent](#agent)
  + [Subtask](#subtask)
  + [Model](#model)
* [Built-in](#built-in)

### On this page

* [Overview](#_top)
* [Create command files](#create-command-files)
* [Configure](#configure)
  + [JSON](#json)
  + [Markdown](#markdown)
* [Prompt config](#prompt-config)
  + [Arguments](#arguments)
  + [Shell output](#shell-output)
  + [File references](#file-references)
* [Options](#options)
  + [Template](#template)
  + [Description](#description)
  + [Agent](#agent)
  + [Subtask](#subtask)
  + [Model](#model)
* [Built-in](#built-in)

## Commands

Create custom commands for repetitive tasks.

Custom commands let you specify a prompt you want to run when that command is executed in the TUI.

```
/my-command
```

Custom commands are in addition to the built-in commands like `/init`, `/undo`, `/redo`, `/share`, `/help`. [Learn more](/docs/tui#commands).

---

### [Create command files](#create-command-files)

Create markdown files in the `commands/` directory to define custom commands.

Create `.opencode/commands/test.md`:

.opencode/commands/test.md

```
---

description: Run tests with coverage

agent: build

model: anthropic/claude-3-5-sonnet-20241022

---

Run the full test suite with coverage report and show any failures.

Focus on the failing tests and suggest fixes.
```

The frontmatter defines command properties. The content becomes the template.

Use the command by typing `/` followed by the command name.

```
"/test"
```

---

### [Configure](#configure)

You can add custom commands through the OpenCode config or by creating markdown files in the `commands/` directory.

---

#### [JSON](#json)

Use the `command` option in your OpenCode [config](/docs/config):

opencode.jsonc

```
{

"$schema": "https://opencode.ai/config.json",

"command": {

// This becomes the name of the command

"test": {

// This is the prompt that will be sent to the LLM

"template": "Run the full test suite with coverage report and show any failures.\nFocus on the failing tests and suggest fixes.",

// This is shown as the description in the TUI

"description": "Run tests with coverage",

"agent": "build",

"model": "anthropic/claude-3-5-sonnet-20241022"

}

}

}
```

Now you can run this command in the TUI:

```
/test
```

---

#### [Markdown](#markdown)

You can also define commands using markdown files. Place them in:

* Global: `~/.config/opencode/commands/`
* Per-project: `.opencode/commands/`

~/.config/opencode/commands/test.md

```
---

description: Run tests with coverage

agent: build

model: anthropic/claude-3-5-sonnet-20241022

---

Run the full test suite with coverage report and show any failures.

Focus on the failing tests and suggest fixes.
```

The markdown file name becomes the command name. For example, `test.md` lets
you run:

```
/test
```

---

### [Prompt config](#prompt-config)

The prompts for the custom commands support several special placeholders and syntax.

---

#### [Arguments](#arguments)

Pass arguments to commands using the `$ARGUMENTS` placeholder.

.opencode/commands/component.md

```
---

description: Create a new component

---

Create a new React component named $ARGUMENTS with TypeScript support.

Include proper typing and basic structure.
```

Run the command with arguments:

```
/component Button
```

And `$ARGUMENTS` will be replaced with `Button`.

You can also access individual arguments using positional parameters:

* `$1` - First argument
* `$2` - Second argument
* `$3` - Third argument
* And so onâ¦

For example:

.opencode/commands/create-file.md

```
---

description: Create a new file with content

---

Create a file named $1 in the directory $2

with the following content: $3
```

Run the command:

```
/create-file config.json src "{ \"key\": \"value\" }"
```

This replaces:

* `$1` with `config.json`
* `$2` with `src`
* `$3` with `{ "key": "value" }`

---

#### [Shell output](#shell-output)

Use *!`command`* to inject [bash command](/docs/tui#bash-commands) output into your prompt.

For example, to create a custom command that analyzes test coverage:

.opencode/commands/analyze-coverage.md

```
---

description: Analyze test coverage

---

Here are the current test results:

!`npm test`

Based on these results, suggest improvements to increase coverage.
```

Or to review recent changes:

.opencode/commands/review-changes.md

```
---

description: Review recent changes

---

Recent git commits:

!`git log --oneline -10`

Review these changes and suggest any improvements.
```

Commands run in your projectâs root directory and their output becomes part of the prompt.

---

#### [File references](#file-references)

Include files in your command using `@` followed by the filename.

.opencode/commands/review-component.md

```
---

description: Review component

---

Review the component in @src/components/Button.tsx.

Check for performance issues and suggest improvements.
```

The file content gets included in the prompt automatically.

---

### [Options](#options)

Letâs look at the configuration options in detail.

---

#### [Template](#template)

The `template` option defines the prompt that will be sent to the LLM when the command is executed.

opencode.json

```
{

"command": {

"test": {

"template": "Run the full test suite with coverage report and show any failures.\nFocus on the failing tests and suggest fixes."

}

}

}
```

This is a **required** config option.

---

#### [Description](#description)

Use the `description` option to provide a brief description of what the command does.

opencode.json

```
{

"command": {

"test": {

"description": "Run tests with coverage"

}

}

}
```

This is shown as the description in the TUI when you type in the command.

---

#### [Agent](#agent)

Use the `agent` config to optionally specify which [agent](/docs/agents) should execute this command.
If this is a [subagent](/docs/agents/#subagents) the command will trigger a subagent invocation by default.
To disable this behavior, set `subtask` to `false`.

opencode.json

```
{

"command": {

"review": {

"agent": "plan"

}

}

}
```

This is an **optional** config option. If not specified, defaults to your current agent.

---

#### [Subtask](#subtask)

Use the `subtask` boolean to force the command to trigger a [subagent](/docs/agents/#subagents) invocation.
This is useful if you want the command to not pollute your primary context and will **force** the agent to act as a subagent,
even if `mode` is set to `primary` on the [agent](/docs/agents) configuration.

opencode.json

```
{

"command": {

"analyze": {

"subtask": true

}

}

}
```

This is an **optional** config option.

---

#### [Model](#model)

Use the `model` config to override the default model for this command.

opencode.json

```
{

"command": {

"analyze": {

"model": "anthropic/claude-3-5-sonnet-20241022"

}

}

}
```

This is an **optional** config option.

---

### [Built-in](#built-in)

opencode includes several built-in commands like `/init`, `/undo`, `/redo`, `/share`, `/help`; [learn more](/docs/tui#commands).

Note

Custom commands can override built-in commands.

If you define a custom command with the same name, it will override the built-in command.

[Edit page](https://github.com/anomalyco/opencode/edit/dev/packages/web/src/content/docs/commands.mdx)[Found a bug? Open an issue](https://github.com/anomalyco/opencode/issues/new)[Join our Discord community](https://opencode.ai/discord)  Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

© [Anomaly](https://anoma.ly)

Last updated: Oct 13, 2026

---
<!--
URL: https://opencode.ai/docs/mcp-servers/
title: MCP servers | OpenCode
-->

[Skip to content](#_top)

[![](/docs/_astro/logo-dark.DOStV66V.svg) ![](/docs/_astro/logo-light.B0yzR0O5.svg)  OpenCode](/docs/)

[app.header.home](/)[app.header.docs](/v2/docs)

Search  `CtrlK`

Cancel

  [New OpenCode v2 is now available →](https://opencode.ai/v2)

* [Intro](/docs/)
* [Config](/docs/config/)
* [Providers](/docs/providers/)
* [Network](/docs/network/)
* [Enterprise](/docs/enterprise/)
* [Troubleshooting](/docs/troubleshooting/)
* [Windows](/docs/windows-wsl)
* Usage

  + [Go](https://opencode.ai/v2/docs/console/go/)
  + [TUI](/docs/tui/)
  + [CLI](/docs/cli/)
  + [Web](/docs/web/)
  + [IDE](/docs/ide/)
  + [Console](https://opencode.ai/v2/docs/console/)
  + [Share](/docs/share/)
  + [GitHub](/docs/github/)
  + [GitLab](/docs/gitlab/)
* Configure

  + [Tools](/docs/tools/)
  + [Rules](/docs/rules/)
  + [Agents](/docs/agents/)
  + [Models](/docs/models/)
  + [Themes](/docs/themes/)
  + [Keybinds](/docs/keybinds/)
  + [Commands](/docs/commands/)
  + [Formatters](/docs/formatters/)
  + [Permissions](/docs/permissions/)
  + [Policies](/docs/policies/)
  + [LSP Servers](/docs/lsp/)
  + [MCP servers](/docs/mcp-servers/)
  + [ACP Support](/docs/acp/)
  + [Agent Skills](/docs/skills/)
  + [References](/docs/references/)
  + [Custom Tools](/docs/custom-tools/)
* Develop

  + [SDK](/docs/sdk/)
  + [Server](/docs/server/)
  + [Plugins](/docs/plugins/)
  + [Ecosystem](/docs/ecosystem/)

[GitHub](https://github.com/anomalyco/opencode)[Discord](https://opencode.ai/discord)

  Select theme   DarkLightAuto         Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

On this page

* [Overview](#_top)
* [Enable](#enable)
  + [Overriding remote defaults](#overriding-remote-defaults)
* [Local](#local)
* [Remote](#remote)
* [OAuth](#oauth)
  + [Automatic](#automatic)
  + [Pre-registered](#pre-registered)
  + [Authenticating](#authenticating)
* [Manage](#manage)
  + [Global](#global)
  + [Per agent](#per-agent)
* [Examples](#examples)
  + [Sentry](#sentry)
  + [Context7](#context7)
  + [Grep by Vercel](#grep-by-vercel)

### On this page

* [Overview](#_top)
* [Enable](#enable)
  + [Overriding remote defaults](#overriding-remote-defaults)
* [Local](#local)
* [Remote](#remote)
* [OAuth](#oauth)
  + [Automatic](#automatic)
  + [Pre-registered](#pre-registered)
  + [Authenticating](#authenticating)
* [Manage](#manage)
  + [Global](#global)
  + [Per agent](#per-agent)
* [Examples](#examples)
  + [Sentry](#sentry)
  + [Context7](#context7)
  + [Grep by Vercel](#grep-by-vercel)

## MCP servers

Add local and remote MCP tools.

You can add external tools to OpenCode using the *Model Context Protocol*, or MCP. OpenCode supports both local and remote servers.

Once added, MCP tools are automatically available to the LLM alongside built-in tools.

---

##### [Caveats](#caveats)

When you use an MCP server, it adds to the context. This can quickly add up if you have a lot of tools. So we recommend being careful with which MCP servers you use.

Tip

MCP servers add to your context, so you want to be careful with which ones you enable.

Certain MCP servers, like the GitHub MCP server, tend to add a lot of tokens and can easily exceed the context limit.

---

### [Enable](#enable)

You can define MCP servers in your [OpenCode Config](https://opencode.ai/docs/config/) under `mcp`. Add each MCP with a unique name. You can refer to that MCP by name when prompting the LLM.

opencode.jsonc

```
{

"$schema": "https://opencode.ai/config.json",

"mcp": {

"name-of-mcp-server": {

// ...

"enabled": true,

},

"name-of-other-mcp-server": {

// ...

},

},

}
```

You can also disable a server by setting `enabled` to `false`. This is useful if you want to temporarily disable a server without removing it from your config.

---

#### [Overriding remote defaults](#overriding-remote-defaults)

Organizations can provide default MCP servers via their `.well-known/opencode` endpoint. These servers may be disabled by default, allowing users to opt-in to the ones they need.

To enable a specific server from your organizationâs remote config, add it to your local config with `enabled: true`:

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"mcp": {

"jira": {

"type": "remote",

"url": "https://jira.example.com/mcp",

"enabled": true

}

}

}
```

Your local config values override the remote defaults. See [config precedence](/docs/config#precedence-order) for more details.

---

### [Local](#local)

Add local MCP servers using `type` to `"local"` within the MCP object.

opencode.jsonc

```
{

"$schema": "https://opencode.ai/config.json",

"mcp": {

"my-local-mcp-server": {

"type": "local",

// Or ["bun", "x", "my-mcp-command"]

"command": ["npx", "-y", "my-mcp-command"],

"enabled": true,

"environment": {

"MY_ENV_VAR": "my_env_var_value",

},

},

},

}
```

The command is how the local MCP server is started. You can also pass in a list of environment variables as well.

For example, hereâs how you can add the test [`@modelcontextprotocol/server-everything`](https://www.npmjs.com/package/%40modelcontextprotocol/server-everything) MCP server.

opencode.jsonc

```
{

"$schema": "https://opencode.ai/config.json",

"mcp": {

"mcp_everything": {

"type": "local",

"command": ["npx", "-y", "@modelcontextprotocol/server-everything"],

},

},

}
```

And to use it I can add `use the mcp_everything tool` to my prompts.

```
use the mcp_everything tool to add the number 3 and 4
```

---

##### [Options](#options)

Here are all the options for configuring a local MCP server.

| Option | Type | Required | Description |
| --- | --- | --- | --- |
| `type` | String | Y | Type of MCP server connection, must be `"local"`. |
| `command` | Array | Y | Command and arguments to run the MCP server. |
| `cwd` | String |  | Working directory for the MCP server process. Relative paths resolve from the workspace. |
| `environment` | Object |  | Environment variables to set when running the server. |
| `enabled` | Boolean |  | Enable or disable the MCP server on startup. |
| `timeout` | Number |  | Timeout in ms for fetching tools from the MCP server. Defaults to 5000 (5 seconds). |

---

### [Remote](#remote)

Add remote MCP servers by setting `type` to `"remote"`.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"mcp": {

"my-remote-mcp": {

"type": "remote",

"url": "https://my-mcp-server.com",

"enabled": true,

"headers": {

"Authorization": "Bearer MY_API_KEY"

}

}

}

}
```

The `url` is the URL of the remote MCP server and with the `headers` option you can pass in a list of headers.

---

##### [Options](#options-1)

| Option | Type | Required | Description |
| --- | --- | --- | --- |
| `type` | String | Y | Type of MCP server connection, must be `"remote"`. |
| `url` | String | Y | URL of the remote MCP server. |
| `enabled` | Boolean |  | Enable or disable the MCP server on startup. |
| `headers` | Object |  | Headers to send with the request. |
| `oauth` | Object |  | OAuth authentication configuration. See [OAuth](#oauth) section below. |
| `timeout` | Number |  | Timeout in ms for fetching tools from the MCP server. Defaults to 5000 (5 seconds). |

---

### [OAuth](#oauth)

OpenCode automatically handles OAuth authentication for remote MCP servers. When a server requires authentication, OpenCode will:

1. Detect the 401 response and initiate the OAuth flow
2. Use **Dynamic Client Registration (RFC 7591)** if supported by the server
3. Store tokens securely for future requests

---

#### [Automatic](#automatic)

For most OAuth-enabled MCP servers, no special configuration is needed. Just configure the remote server:

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"mcp": {

"my-oauth-server": {

"type": "remote",

"url": "https://mcp.example.com/mcp"

}

}

}
```

If the server requires authentication, OpenCode will prompt you to authenticate when you first try to use it. If not, you can [manually trigger the flow](#authenticating) with `opencode mcp auth <server-name>`.

---

#### [Pre-registered](#pre-registered)

If you have client credentials from the MCP server provider, you can configure them:

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"mcp": {

"my-oauth-server": {

"type": "remote",

"url": "https://mcp.example.com/mcp",

"oauth": {

"clientId": "{env:MY_MCP_CLIENT_ID}",

"clientSecret": "{env:MY_MCP_CLIENT_SECRET}",

"scope": "tools:read tools:execute"

}

}

}

}
```

---

#### [Authenticating](#authenticating)

You can manually trigger authentication or manage credentials.

Authenticate with a specific MCP server:

Terminal window

```
opencode mcp auth my-oauth-server
```

List all MCP servers and their auth status:

Terminal window

```
opencode mcp list
```

Remove stored credentials:

Terminal window

```
opencode mcp logout my-oauth-server
```

The `mcp auth` command will open your browser for authorization. After you authorize, OpenCode will store the tokens securely in `~/.local/share/opencode/mcp-auth.json`.

---

##### [Disabling OAuth](#disabling-oauth)

If you want to disable automatic OAuth for a server (e.g., for servers that use API keys instead), set `oauth` to `false`:

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"mcp": {

"my-api-key-server": {

"type": "remote",

"url": "https://mcp.example.com/mcp",

"oauth": false,

"headers": {

"Authorization": "Bearer {env:MY_API_KEY}"

}

}

}

}
```

---

##### [OAuth Options](#oauth-options)

| Option | Type | Description |
| --- | --- | --- |
| `oauth` | Object | false | OAuth config object, or `false` to disable OAuth auto-detection. |
| `clientId` | String | OAuth client ID. If not provided, dynamic client registration will be attempted. |
| `clientSecret` | String | OAuth client secret, if required by the authorization server. |
| `scope` | String | OAuth scopes to request during authorization. |

##### [Debugging](#debugging)

If a remote MCP server is failing to authenticate, you can diagnose issues with:

Terminal window

```

## View auth status for all OAuth-capable servers

opencode mcp auth list

## Debug connection and OAuth flow for a specific server

opencode mcp debug my-oauth-server
```

The `mcp debug` command shows the current auth status, tests HTTP connectivity, and attempts the OAuth discovery flow.

---

### [Manage](#manage)

Tools from your MCP servers are available in OpenCode alongside built-in tools. You can manage them through the OpenCode config like any other tool.

---

#### [Global](#global)

This means that you can enable or disable them globally.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"mcp": {

"my-mcp-foo": {

"type": "local",

"command": ["bun", "x", "my-mcp-command-foo"]

},

"my-mcp-bar": {

"type": "local",

"command": ["bun", "x", "my-mcp-command-bar"]

}

},

"tools": {

"my-mcp-foo": false

}

}
```

We can also use a glob pattern to disable all matching MCP tools.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"mcp": {

"my-mcp-foo": {

"type": "local",

"command": ["bun", "x", "my-mcp-command-foo"]

},

"my-mcp-bar": {

"type": "local",

"command": ["bun", "x", "my-mcp-command-bar"]

}

},

"tools": {

"my-mcp*": false

}

}
```

Here we are using the glob pattern `my-mcp*` to disable all matching MCP tools.

---

#### [Per agent](#per-agent)

If you have a large number of MCP servers you may want to only enable them per agent and disable them globally. To do this:

1. Disable it as a tool globally.
2. In your [agent config](/docs/agents#tools), enable the MCP server as a tool.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"mcp": {

"my-mcp": {

"type": "local",

"command": ["bun", "x", "my-mcp-command"],

"enabled": true

}

},

"tools": {

"my-mcp*": false

},

"agent": {

"my-agent": {

"tools": {

"my-mcp*": true

}

}

}

}
```

---

##### [Glob patterns](#glob-patterns)

The glob pattern uses simple regex globbing patterns:

* `*` matches zero or more of any character (e.g., `"my-mcp*"` matches `my-mcp_search`, `my-mcp_list`, etc.)
* `?` matches exactly one character
* All other characters match literally

Note

MCP server tools are registered with server name as prefix, so to disable all tools for a server simply use:

```
"mymcpservername_*": false
```

---

### [Examples](#examples)

Below are examples of some common MCP servers. You can submit a PR if you want to document other servers.

---

#### [Sentry](#sentry)

Add the [Sentry MCP server](https://mcp.sentry.dev) to interact with your Sentry projects and issues.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"mcp": {

"sentry": {

"type": "remote",

"url": "https://mcp.sentry.dev/mcp",

"oauth": {}

}

}

}
```

After adding the configuration, authenticate with Sentry:

Terminal window

```
opencode mcp auth sentry
```

This will open a browser window to complete the OAuth flow and connect OpenCode to your Sentry account.

Once authenticated, you can use Sentry tools in your prompts to query issues, projects, and error data.

```
Show me the latest unresolved issues in my project. use sentry
```

---

#### [Context7](#context7)

Add the [Context7 MCP server](https://github.com/upstash/context7) to search through docs.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"mcp": {

"context7": {

"type": "remote",

"url": "https://mcp.context7.com/mcp"

}

}

}
```

If you have signed up for a free account, you can use your API key and get higher rate-limits.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"mcp": {

"context7": {

"type": "remote",

"url": "https://mcp.context7.com/mcp",

"headers": {

"CONTEXT7_API_KEY": "{env:CONTEXT7_API_KEY}"

}

}

}

}
```

Here we are assuming that you have the `CONTEXT7_API_KEY` environment variable set.

Add `use context7` to your prompts to use Context7 MCP server.

```
Configure a Cloudflare Worker script to cache JSON API responses for five minutes. use context7
```

Alternatively, you can add something like this to your [AGENTS.md](/docs/rules/).

AGENTS.md

```
When you need to search docs, use `context7` tools.
```

---

#### [Grep by Vercel](#grep-by-vercel)

Add the [Grep by Vercel](https://grep.app) MCP server to search through code snippets on GitHub.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"mcp": {

"gh_grep": {

"type": "remote",

"url": "https://mcp.grep.app"

}

}

}
```

Since we named our MCP server `gh_grep`, you can add `use the gh_grep tool` to your prompts to get the agent to use it.

```
What's the right way to set a custom domain in an SST Astro component? use the gh_grep tool
```

Alternatively, you can add something like this to your [AGENTS.md](/docs/rules/).

AGENTS.md

```
If you are unsure how to do something, use `gh_grep` to search code examples from GitHub.
```

[Edit page](https://github.com/anomalyco/opencode/edit/dev/packages/web/src/content/docs/mcp-servers.mdx)[Found a bug? Open an issue](https://github.com/anomalyco/opencode/issues/new)[Join our Discord community](https://opencode.ai/discord)  Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

© [Anomaly](https://anoma.ly)

Last updated: Oct 13, 2026

---
<!--
URL: https://opencode.ai/docs/
title: Intro | AI coding agent built for the terminal
-->

[Skip to content](#_top)

[![](/docs/_astro/logo-dark.DOStV66V.svg) ![](/docs/_astro/logo-light.B0yzR0O5.svg)  OpenCode](/docs/)

[app.header.home](/)[app.header.docs](/v2/docs)

Search  `CtrlK`

Cancel

  [New OpenCode v2 is now available →](https://opencode.ai/v2)

* [Intro](/docs/)
* [Config](/docs/config/)
* [Providers](/docs/providers/)
* [Network](/docs/network/)
* [Enterprise](/docs/enterprise/)
* [Troubleshooting](/docs/troubleshooting/)
* [Windows](/docs/windows-wsl)
* Usage

  + [Go](https://opencode.ai/v2/docs/console/go/)
  + [TUI](/docs/tui/)
  + [CLI](/docs/cli/)
  + [Web](/docs/web/)
  + [IDE](/docs/ide/)
  + [Console](https://opencode.ai/v2/docs/console/)
  + [Share](/docs/share/)
  + [GitHub](/docs/github/)
  + [GitLab](/docs/gitlab/)
* Configure

  + [Tools](/docs/tools/)
  + [Rules](/docs/rules/)
  + [Agents](/docs/agents/)
  + [Models](/docs/models/)
  + [Themes](/docs/themes/)
  + [Keybinds](/docs/keybinds/)
  + [Commands](/docs/commands/)
  + [Formatters](/docs/formatters/)
  + [Permissions](/docs/permissions/)
  + [Policies](/docs/policies/)
  + [LSP Servers](/docs/lsp/)
  + [MCP servers](/docs/mcp-servers/)
  + [ACP Support](/docs/acp/)
  + [Agent Skills](/docs/skills/)
  + [References](/docs/references/)
  + [Custom Tools](/docs/custom-tools/)
* Develop

  + [SDK](/docs/sdk/)
  + [Server](/docs/server/)
  + [Plugins](/docs/plugins/)
  + [Ecosystem](/docs/ecosystem/)

[GitHub](https://github.com/anomalyco/opencode)[Discord](https://opencode.ai/discord)

  Select theme   DarkLightAuto         Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

On this page

* [Overview](#_top)
* [Install](#install)
* [Configure](#configure)
* [Initialize](#initialize)
* [Usage](#usage)
  + [Ask questions](#ask-questions)
  + [Add features](#add-features)
  + [Make changes](#make-changes)
  + [Undo changes](#undo-changes)
* [Share](#share)
* [Customize](#customize)

### On this page

* [Overview](#_top)
* [Install](#install)
* [Configure](#configure)
* [Initialize](#initialize)
* [Usage](#usage)
  + [Ask questions](#ask-questions)
  + [Add features](#add-features)
  + [Make changes](#make-changes)
  + [Undo changes](#undo-changes)
* [Share](#share)
* [Customize](#customize)

## Intro

Get started with OpenCode.

Note

OpenCode 1 and OpenCode 2 both use the `opencode` command and cannot be installed side by side under their default command.
See the [OpenCode 2 docs](https://opencode.ai/v2/docs/) to migrate to V2.

[**OpenCode**](/) is an open source AI coding agent. Itâs available as a terminal-based interface, desktop app, or IDE extension.

![OpenCode TUI with the opencode theme](/docs/_astro/screenshot.CQjBbRyJ_1dLadc.webp)

Letâs get started.

---

##### [Prerequisites](#prerequisites)

To use OpenCode in your terminal, youâll need:

1. A modern terminal emulator like:

   * [WezTerm](https://wezterm.org), cross-platform
   * [Alacritty](https://alacritty.org), cross-platform
   * [Ghostty](https://ghostty.org), Linux and macOS
   * [Kitty](https://sw.kovidgoyal.net/kitty/), Linux and macOS
2. API keys for the LLM providers you want to use.

---

### [Install](#install)

The easiest way to install OpenCode 1 is through the install script. These installation methods provide the `opencode`
binary and can conflict with or replace an OpenCode 2 installation.

Terminal window

```
curl -fsSL https://opencode.ai/install | bash
```

You can also install it with the following commands:

* **Using Node.js**

  + [npm](#tab-panel-0)
  + [Bun](#tab-panel-1)
  + [pnpm](#tab-panel-2)
  + [Yarn](#tab-panel-3)

  Terminal window

  ```
  npm install -g opencode-ai
  ```

  Terminal window

  ```
  bun install -g opencode-ai
  ```

  Terminal window

  ```
  pnpm install -g opencode-ai
  ```

  Terminal window

  ```
  yarn global add opencode-ai
  ```
* **Using Homebrew on macOS and Linux**

  Terminal window

  ```
  brew install anomalyco/tap/opencode
  ```

  > We recommend using the OpenCode tap for the most up to date releases. The official `brew install opencode` formula is maintained by the Homebrew team and is updated less frequently.
* **Installing on Arch Linux**

  Terminal window

  ```
  sudo pacman -S opencode           # Arch Linux (Stable)

  paru -S opencode-bin              # Arch Linux (Latest from AUR)
  ```

##### [Windows](#windows)

Recommended: Use WSL

For the best experience on Windows, we recommend using [Windows Subsystem for Linux (WSL)](/docs/windows-wsl). It provides better performance and full compatibility with OpenCodeâs features.

* **Using Chocolatey**

  Terminal window

  ```
  choco install opencode
  ```
* **Using Scoop**

  Terminal window

  ```
  scoop install opencode
  ```
* **Using NPM**

  Terminal window

  ```
  npm install -g opencode-ai
  ```
* **Using Mise**

  Terminal window

  ```
  mise use -g github:anomalyco/opencode
  ```
* **Using Docker**

  Terminal window

  ```
  docker run -it --rm ghcr.io/anomalyco/opencode
  ```

Support for installing OpenCode on Windows using Bun is currently in progress.

You can also grab the binary from the [Releases](https://github.com/anomalyco/opencode/releases).

---

### [Configure](#configure)

With OpenCode you can use any LLM provider by configuring their API keys.

If you are new to using LLM providers, we recommend using [OpenCode Zen](https://opencode.ai/v2/docs/console/).
Itâs a curated list of models that have been tested and verified by the OpenCode
team.

1. Run the `/connect` command in the TUI, select opencode, and head to [opencode.ai/auth](https://opencode.ai/auth).

   ```
   /connect
   ```
2. Sign in, add your billing details, and copy your API key.
3. Paste your API key.

   ```
   â API key

   â

   â

   â enter
   ```

Alternatively, you can select one of the other providers. [Learn more](/docs/providers#directory).

---

### [Initialize](#initialize)

Now that youâve configured a provider, you can navigate to a project that
you want to work on.

Terminal window

```
cd /path/to/project
```

And run OpenCode.

Terminal window

```
opencode
```

Next, initialize OpenCode for the project by running the following command.

```
/init
```

This will get OpenCode to analyze your project and create an `AGENTS.md` file in
the project root.

Tip

You should commit your projectâs `AGENTS.md` file to Git.

This helps OpenCode understand the project structure and the coding patterns
used.

---

### [Usage](#usage)

You are now ready to use OpenCode to work on your project. Feel free to ask it
anything!

If you are new to using an AI coding agent, here are some examples that might
help.

---

#### [Ask questions](#ask-questions)

You can ask OpenCode to explain the codebase to you.

Tip

Use the `@` key to fuzzy search for files in the project.

```
How is authentication handled in @packages/functions/src/api/index.ts
```

This is helpful if thereâs a part of the codebase that you didnât work on.

---

#### [Add features](#add-features)

You can ask OpenCode to add new features to your project. Though we first recommend asking it to create a plan.

1. **Create a plan**

   OpenCode has a *Plan mode* that disables its ability to make changes and
   instead suggest *how* itâll implement the feature.

   Switch to it using the **Tab** key. Youâll see an indicator for this in the lower right corner.

   ```
   <TAB>
   ```

   Now letâs describe what we want it to do.

   ```
   When a user deletes a note, we'd like to flag it as deleted in the database.

   Then create a screen that shows all the recently deleted notes.

   From this screen, the user can undelete a note or permanently delete it.
   ```

   You want to give OpenCode enough details to understand what you want. It helps
   to talk to it like you are talking to a junior developer on your team.

   Tip

   Give OpenCode plenty of context and examples to help it understand what you
   want.
2. **Iterate on the plan**

   Once it gives you a plan, you can give it feedback or add more details.

   ```
   We'd like to design this new screen using a design I've used before.

   [Image #1] Take a look at this image and use it as a reference.
   ```

   Tip

   Drag and drop images into the terminal to add them to the prompt.

   OpenCode can scan any images you give it and add them to the prompt. You can
   do this by dragging and dropping an image into the terminal.
3. **Build the feature**

   Once you feel comfortable with the plan, switch back to *Build mode* by
   hitting the **Tab** key again.

   ```
   <TAB>
   ```

   And asking it to make the changes.

   ```
   Sounds good! Go ahead and make the changes.
   ```

---

#### [Make changes](#make-changes)

For more straightforward changes, you can ask OpenCode to directly build it
without having to review the plan first.

```
We need to add authentication to the /settings route. Take a look at how this is

handled in the /notes route in @packages/functions/src/notes.ts and implement

the same logic in @packages/functions/src/settings.ts
```

You want to make sure you provide a good amount of detail so OpenCode makes the right
changes.

---

#### [Undo changes](#undo-changes)

Letâs say you ask OpenCode to make some changes.

```
Can you refactor the function in @packages/functions/src/api/index.ts?
```

But you realize that it is not what you wanted. You **can undo** the changes
using the `/undo` command.

```
/undo
```

OpenCode will now revert the changes you made and show your original message
again.

```
Can you refactor the function in @packages/functions/src/api/index.ts?
```

From here you can tweak the prompt and ask OpenCode to try again.

Tip

You can run `/undo` multiple times to undo multiple changes.

Or you **can redo** the changes using the `/redo` command.

```
/redo
```

---

### [Share](#share)

The conversations that you have with OpenCode can be [shared with your
team](/docs/share).

```
/share
```

This will create a link to the current conversation and copy it to your clipboard.

Note

Conversations are not shared by default.

Hereâs an [example conversation](https://opencode.ai/s/4XP1fce5) with OpenCode.

---

### [Customize](#customize)

And thatâs it! You are now a pro at using OpenCode.

To make it your own, we recommend [picking a theme](/docs/themes), [customizing the keybinds](/docs/keybinds), [configuring code formatters](/docs/formatters), [creating custom commands](/docs/commands), or playing around with the [OpenCode config](/docs/config).

[Edit page](https://github.com/anomalyco/opencode/edit/dev/packages/web/src/content/docs/index.mdx)[Found a bug? Open an issue](https://github.com/anomalyco/opencode/issues/new)[Join our Discord community](https://opencode.ai/discord)  Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

© [Anomaly](https://anoma.ly)

Last updated: Oct 13, 2026

---
<!--
URL: https://opencode.ai/docs/tools/
title: Tools | OpenCode
-->

[Skip to content](#_top)

[![](/docs/_astro/logo-dark.DOStV66V.svg) ![](/docs/_astro/logo-light.B0yzR0O5.svg)  OpenCode](/docs/)

[app.header.home](/)[app.header.docs](/v2/docs)

Search  `CtrlK`

Cancel

  [New OpenCode v2 is now available →](https://opencode.ai/v2)

* [Intro](/docs/)
* [Config](/docs/config/)
* [Providers](/docs/providers/)
* [Network](/docs/network/)
* [Enterprise](/docs/enterprise/)
* [Troubleshooting](/docs/troubleshooting/)
* [Windows](/docs/windows-wsl)
* Usage

  + [Go](https://opencode.ai/v2/docs/console/go/)
  + [TUI](/docs/tui/)
  + [CLI](/docs/cli/)
  + [Web](/docs/web/)
  + [IDE](/docs/ide/)
  + [Console](https://opencode.ai/v2/docs/console/)
  + [Share](/docs/share/)
  + [GitHub](/docs/github/)
  + [GitLab](/docs/gitlab/)
* Configure

  + [Tools](/docs/tools/)
  + [Rules](/docs/rules/)
  + [Agents](/docs/agents/)
  + [Models](/docs/models/)
  + [Themes](/docs/themes/)
  + [Keybinds](/docs/keybinds/)
  + [Commands](/docs/commands/)
  + [Formatters](/docs/formatters/)
  + [Permissions](/docs/permissions/)
  + [Policies](/docs/policies/)
  + [LSP Servers](/docs/lsp/)
  + [MCP servers](/docs/mcp-servers/)
  + [ACP Support](/docs/acp/)
  + [Agent Skills](/docs/skills/)
  + [References](/docs/references/)
  + [Custom Tools](/docs/custom-tools/)
* Develop

  + [SDK](/docs/sdk/)
  + [Server](/docs/server/)
  + [Plugins](/docs/plugins/)
  + [Ecosystem](/docs/ecosystem/)

[GitHub](https://github.com/anomalyco/opencode)[Discord](https://opencode.ai/discord)

  Select theme   DarkLightAuto         Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

On this page

* [Overview](#_top)
* [Configure](#configure)
* [Built-in](#built-in)
  + [bash](#bash)
  + [edit](#edit)
  + [write](#write)
  + [read](#read)
  + [grep](#grep)
  + [glob](#glob)
  + [lsp (experimental)](#lsp-experimental)
  + [apply\_patch](#apply_patch)
  + [skill](#skill)
  + [webfetch](#webfetch)
  + [websearch](#websearch)
  + [question](#question)
* [Custom tools](#custom-tools)
* [MCP servers](#mcp-servers)
* [Internals](#internals)
  + [Ignore patterns](#ignore-patterns)

### On this page

* [Overview](#_top)
* [Configure](#configure)
* [Built-in](#built-in)
  + [bash](#bash)
  + [edit](#edit)
  + [write](#write)
  + [read](#read)
  + [grep](#grep)
  + [glob](#glob)
  + [lsp (experimental)](#lsp-experimental)
  + [apply\_patch](#apply_patch)
  + [skill](#skill)
  + [webfetch](#webfetch)
  + [websearch](#websearch)
  + [question](#question)
* [Custom tools](#custom-tools)
* [MCP servers](#mcp-servers)
* [Internals](#internals)
  + [Ignore patterns](#ignore-patterns)

## Tools

Manage the tools an LLM can use.

Tools allow the LLM to perform actions in your codebase. OpenCode comes with a set of built-in tools, but you can extend it with [custom tools](/docs/custom-tools) or [MCP servers](/docs/mcp-servers).

By default, all tools are **enabled** and donât need permission to run. You can control tool behavior through [permissions](/docs/permissions).

---

### [Configure](#configure)

Use the `permission` field to control tool behavior. You can allow, deny, or require approval for each tool.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"permission": {

"edit": "deny",

"bash": "ask",

"webfetch": "allow"

}

}
```

You can also use wildcards to control multiple tools at once. For example, to require approval for all tools from an MCP server:

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"permission": {

"mymcp_*": "ask"

}

}
```

[Learn more](/docs/permissions) about configuring permissions.

---

### [Built-in](#built-in)

Here are all the built-in tools available in OpenCode.

---

#### [bash](#bash)

Execute shell commands in your project environment.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"permission": {

"bash": "allow"

}

}
```

This tool allows the LLM to run terminal commands like `npm install`, `git status`, or any other shell command.

---

#### [edit](#edit)

Modify existing files using exact string replacements.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"permission": {

"edit": "allow"

}

}
```

This tool performs precise edits to files by replacing exact text matches. Itâs the primary way the LLM modifies code.

---

#### [write](#write)

Create new files or overwrite existing ones.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"permission": {

"edit": "allow"

}

}
```

Use this to allow the LLM to create new files. It will overwrite existing files if they already exist.

Note

The `write` tool is controlled by the `edit` permission, which covers all file modifications (`edit`, `write`, `apply_patch`).

---

#### [read](#read)

Read file contents from your codebase.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"permission": {

"read": "allow"

}

}
```

This tool reads files and returns their contents. It supports reading specific line ranges for large files.

---

#### [grep](#grep)

Search file contents using regular expressions.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"permission": {

"grep": "allow"

}

}
```

Fast content search across your codebase. Supports full regex syntax and file pattern filtering.

---

#### [glob](#glob)

Find files by pattern matching.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"permission": {

"glob": "allow"

}

}
```

Search for files using glob patterns like `**/*.js` or `src/**/*.ts`. Returns matching file paths sorted by modification time.

---

#### [lsp (experimental)](#lsp-experimental)

Interact with your configured LSP servers to get code intelligence features like definitions, references, hover info, and call hierarchy.

Note

This tool is only available when `OPENCODE_EXPERIMENTAL_LSP_TOOL=true` (or `OPENCODE_EXPERIMENTAL=true`).

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"permission": {

"lsp": "allow"

}

}
```

Supported operations include `goToDefinition`, `findReferences`, `hover`, `documentSymbol`, `workspaceSymbol`, `goToImplementation`, `prepareCallHierarchy`, `incomingCalls`, and `outgoingCalls`.

To configure which LSP servers are available for your project, see [LSP Servers](/docs/lsp).

---

#### [apply\_patch](#apply_patch)

Apply patches to files.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"permission": {

"edit": "allow"

}

}
```

This tool applies patch files to your codebase. Useful for applying diffs and patches from various sources.

When handling `tool.execute.before` or `tool.execute.after` hooks, check `input.tool === "apply_patch"` (not `"patch"`).

`apply_patch` uses `output.args.patchText` instead of `output.args.filePath`. Paths are embedded in marker lines within `patchText` and are relative to the project root (for example: `*** Add File: src/new-file.ts`, `*** Update File: src/existing.ts`, `*** Move to: src/renamed.ts`, `*** Delete File: src/obsolete.ts`).

Note

The `apply_patch` tool is controlled by the `edit` permission, which covers all file modifications (`edit`, `write`, `apply_patch`).

---

#### [skill](#skill)

Load a [skill](/docs/skills) (a `SKILL.md` file) and return its content in the conversation.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"permission": {

"skill": "allow"

}

}
```

---

#### [webfetch](#webfetch)

Fetch web content.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"permission": {

"webfetch": "allow"

}

}
```

Allows the LLM to fetch and read web pages. Useful for looking up documentation or researching online resources.

---

#### [websearch](#websearch)

Search the web for information.

Note

This tool is only available when using the OpenCode or OpenCode Go provider, or when either the `OPENCODE_ENABLE_EXA` or `OPENCODE_ENABLE_PARALLEL` environment variable is set to any truthy value (e.g., `true` or `1`).

To enable when launching OpenCode:

Terminal window

```
OPENCODE_ENABLE_EXA=1 opencode

## or

OPENCODE_ENABLE_PARALLEL=1 opencode
```

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"permission": {

"websearch": "allow"

}

}
```

Performs web searches using Exa or Parallel to find relevant information online. Useful for researching topics, finding current events, or gathering information beyond the training data cutoff.

No API key is required â the tool connects directly to the backendâs hosted MCP service without authentication.

Tip

Use `websearch` when you need to find information (discovery), and `webfetch` when you need to retrieve content from a specific URL (retrieval).

---

#### [question](#question)

Ask the user questions during execution.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"permission": {

"question": "allow"

}

}
```

This tool allows the LLM to ask the user questions during a task. Itâs useful for:

* Gathering user preferences or requirements
* Clarifying ambiguous instructions
* Getting decisions on implementation choices
* Offering choices about what direction to take

Each question includes a header, the question text, and a list of options. Users can select from the provided options or type a custom answer. When there are multiple questions, users can navigate between them before submitting all answers.

---

### [Custom tools](#custom-tools)

Custom tools let you define your own functions that the LLM can call. These are defined in your config file and can execute arbitrary code.

[Learn more](/docs/custom-tools) about creating custom tools.

---

### [MCP servers](#mcp-servers)

MCP (Model Context Protocol) servers allow you to integrate external tools and services. This includes database access, API integrations, and third-party services.

[Learn more](/docs/mcp-servers) about configuring MCP servers.

---

### [Internals](#internals)

Internally, tools like `grep` and `glob` use [ripgrep](https://github.com/BurntSushi/ripgrep) under the hood. By default, ripgrep respects `.gitignore` patterns, which means files and directories listed in your `.gitignore` will be excluded from searches and listings.

---

#### [Ignore patterns](#ignore-patterns)

To include files that would normally be ignored, create a `.ignore` file in your project root. This file can explicitly allow certain paths.

.ignore

```
!node_modules/

!dist/

!build/
```

For example, this `.ignore` file allows ripgrep to search within `node_modules/`, `dist/`, and `build/` directories even if theyâre listed in `.gitignore`.

[Edit page](https://github.com/anomalyco/opencode/edit/dev/packages/web/src/content/docs/tools.mdx)[Found a bug? Open an issue](https://github.com/anomalyco/opencode/issues/new)[Join our Discord community](https://opencode.ai/discord)  Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

© [Anomaly](https://anoma.ly)

Last updated: Oct 13, 2026

---
<!--
URL: https://opencode.ai/docs/rules/
title: Rules | OpenCode
-->

[Skip to content](#_top)

[![](/docs/_astro/logo-dark.DOStV66V.svg) ![](/docs/_astro/logo-light.B0yzR0O5.svg)  OpenCode](/docs/)

[app.header.home](/)[app.header.docs](/v2/docs)

Search  `CtrlK`

Cancel

  [New OpenCode v2 is now available →](https://opencode.ai/v2)

* [Intro](/docs/)
* [Config](/docs/config/)
* [Providers](/docs/providers/)
* [Network](/docs/network/)
* [Enterprise](/docs/enterprise/)
* [Troubleshooting](/docs/troubleshooting/)
* [Windows](/docs/windows-wsl)
* Usage

  + [Go](https://opencode.ai/v2/docs/console/go/)
  + [TUI](/docs/tui/)
  + [CLI](/docs/cli/)
  + [Web](/docs/web/)
  + [IDE](/docs/ide/)
  + [Console](https://opencode.ai/v2/docs/console/)
  + [Share](/docs/share/)
  + [GitHub](/docs/github/)
  + [GitLab](/docs/gitlab/)
* Configure

  + [Tools](/docs/tools/)
  + [Rules](/docs/rules/)
  + [Agents](/docs/agents/)
  + [Models](/docs/models/)
  + [Themes](/docs/themes/)
  + [Keybinds](/docs/keybinds/)
  + [Commands](/docs/commands/)
  + [Formatters](/docs/formatters/)
  + [Permissions](/docs/permissions/)
  + [Policies](/docs/policies/)
  + [LSP Servers](/docs/lsp/)
  + [MCP servers](/docs/mcp-servers/)
  + [ACP Support](/docs/acp/)
  + [Agent Skills](/docs/skills/)
  + [References](/docs/references/)
  + [Custom Tools](/docs/custom-tools/)
* Develop

  + [SDK](/docs/sdk/)
  + [Server](/docs/server/)
  + [Plugins](/docs/plugins/)
  + [Ecosystem](/docs/ecosystem/)

[GitHub](https://github.com/anomalyco/opencode)[Discord](https://opencode.ai/discord)

  Select theme   DarkLightAuto         Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

On this page

* [Overview](#_top)
* [Initialize](#initialize)
* [Example](#example)
* [Types](#types)
  + [Project](#project)
  + [Global](#global)
  + [Claude Code Compatibility](#claude-code-compatibility)
* [Precedence](#precedence)
* [Custom Instructions](#custom-instructions)
* [Referencing External Files](#referencing-external-files)
  + [Using opencode.json](#using-opencodejson)
  + [Manual Instructions in AGENTS.md](#manual-instructions-in-agentsmd)

### On this page

* [Overview](#_top)
* [Initialize](#initialize)
* [Example](#example)
* [Types](#types)
  + [Project](#project)
  + [Global](#global)
  + [Claude Code Compatibility](#claude-code-compatibility)
* [Precedence](#precedence)
* [Custom Instructions](#custom-instructions)
* [Referencing External Files](#referencing-external-files)
  + [Using opencode.json](#using-opencodejson)
  + [Manual Instructions in AGENTS.md](#manual-instructions-in-agentsmd)

## Rules

Set custom instructions for opencode.

You can provide custom instructions to opencode by creating an `AGENTS.md` file. This is similar to Cursorâs rules. It contains instructions that will be included in the LLMâs context to customize its behavior for your specific project.

---

### [Initialize](#initialize)

To create a new `AGENTS.md` file, you can run the `/init` command in opencode.

Tip

You should commit your projectâs `AGENTS.md` file to Git.

`/init` scans the important files in your repo, may ask a couple of targeted questions when the codebase cannot answer them, and then creates or updates `AGENTS.md` with concise project-specific guidance.

It focuses on the things future agent sessions are most likely to need:

* build, lint, and test commands
* command order and focused verification steps when they matter
* architecture and repo structure that are not obvious from filenames alone
* project-specific conventions, setup quirks, and operational gotchas
* references to existing instruction sources like Cursor or Copilot rules

If you already have an `AGENTS.md`, `/init` will improve it in place instead of blindly replacing it.

---

### [Example](#example)

You can also just create this file manually. Hereâs an example of some things you can put into an `AGENTS.md` file.

AGENTS.md

```

## SST v3 Monorepo Project

This is an SST v3 monorepo with TypeScript. The project uses bun workspaces for package management.

### Project Structure

- `packages/` - Contains all workspace packages (functions, core, web, etc.)

- `infra/` - Infrastructure definitions split by service (storage.ts, api.ts, web.ts)

- `sst.config.ts` - Main SST configuration with dynamic imports

### Code Standards

- Use TypeScript with strict mode enabled

- Shared code goes in `packages/core/` with proper exports configuration

- Functions go in `packages/functions/`

- Infrastructure should be split into logical files in `infra/`

### Monorepo Conventions

- Import shared modules using workspace names: `@my-app/core/example`
```

We are adding project-specific instructions here and this will be shared across your team.

---

### [Types](#types)

opencode also supports reading the `AGENTS.md` file from multiple locations. And this serves different purposes.

#### [Project](#project)

Place an `AGENTS.md` in your project root for project-specific rules. These only apply when you are working in this directory or its sub-directories.

#### [Global](#global)

You can also have global rules in a `~/.config/opencode/AGENTS.md` file. This gets applied across all opencode sessions.

Since this isnât committed to Git or shared with your team, we recommend using this to specify any personal rules that the LLM should follow.

#### [Claude Code Compatibility](#claude-code-compatibility)

For users migrating from Claude Code, OpenCode supports Claude Codeâs file conventions as fallbacks:

* **Project rules**: `CLAUDE.md` in your project directory (used if no `AGENTS.md` exists)
* **Global rules**: `~/.claude/CLAUDE.md` (used if no `~/.config/opencode/AGENTS.md` exists)
* **Skills**: `~/.claude/skills/` â see [Agent Skills](/docs/skills/) for details

To disable Claude Code compatibility, set one of these environment variables:

Terminal window

```
export OPENCODE_DISABLE_CLAUDE_CODE=1        # Disable all .claude support

export OPENCODE_DISABLE_CLAUDE_CODE_PROMPT=1 # Disable only ~/.claude/CLAUDE.md

export OPENCODE_DISABLE_CLAUDE_CODE_SKILLS=1 # Disable only .claude/skills
```

---

### [Precedence](#precedence)

When opencode starts, it looks for rule files in this order:

1. **Local files** by traversing up from the current directory (`AGENTS.md`, `CLAUDE.md`)
2. **Global file** at `~/.config/opencode/AGENTS.md`
3. **Claude Code file** at `~/.claude/CLAUDE.md` (unless disabled)

The first matching file wins in each category. For example, if you have both `AGENTS.md` and `CLAUDE.md`, only `AGENTS.md` is used. Similarly, `~/.config/opencode/AGENTS.md` takes precedence over `~/.claude/CLAUDE.md`.

---

### [Custom Instructions](#custom-instructions)

You can specify custom instruction files in your `opencode.json` or the global `~/.config/opencode/opencode.json`. This allows you and your team to reuse existing rules rather than having to duplicate them to AGENTS.md.

Example:

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"instructions": ["CONTRIBUTING.md", "docs/guidelines.md", ".cursor/rules/*.md"]

}
```

You can also use remote URLs to load instructions from the web.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"instructions": ["https://raw.githubusercontent.com/my-org/shared-rules/main/style.md"]

}
```

Remote instructions are fetched with a 5 second timeout.

All instruction files are combined with your `AGENTS.md` files.

---

### [Referencing External Files](#referencing-external-files)

While opencode doesnât automatically parse file references in `AGENTS.md`, you can achieve similar functionality in two ways:

#### [Using opencode.json](#using-opencodejson)

The recommended approach is to use the `instructions` field in `opencode.json`:

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"instructions": ["docs/development-standards.md", "test/testing-guidelines.md", "packages/*/AGENTS.md"]

}
```

#### [Manual Instructions in AGENTS.md](#manual-instructions-in-agentsmd)

You can teach opencode to read external files by providing explicit instructions in your `AGENTS.md`. Hereâs a practical example:

AGENTS.md

```

## TypeScript Project Rules

### External File Loading

CRITICAL: When you encounter a file reference (e.g., @rules/general.md), use your Read tool to load it on a need-to-know basis. They're relevant to the SPECIFIC task at hand.

Instructions:

- Do NOT preemptively load all references - use lazy loading based on actual need

- When loaded, treat content as mandatory instructions that override defaults

- Follow references recursively when needed

### Development Guidelines

For TypeScript code style and best practices: @docs/typescript-guidelines.md

For React component architecture and hooks patterns: @docs/react-patterns.md

For REST API design and error handling: @docs/api-standards.md

For testing strategies and coverage requirements: @test/testing-guidelines.md

### General Guidelines

Read the following file immediately as it's relevant to all workflows: @rules/general-guidelines.md.
```

This approach allows you to:

* Create modular, reusable rule files
* Share rules across projects via symlinks or git submodules
* Keep AGENTS.md concise while referencing detailed guidelines
* Ensure opencode loads files only when needed for the specific task

Tip

For monorepos or projects with shared standards, using `opencode.json` with glob patterns (like `packages/*/AGENTS.md`) is more maintainable than manual instructions.

[Edit page](https://github.com/anomalyco/opencode/edit/dev/packages/web/src/content/docs/rules.mdx)[Found a bug? Open an issue](https://github.com/anomalyco/opencode/issues/new)[Join our Discord community](https://opencode.ai/discord)  Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

© [Anomaly](https://anoma.ly)

Last updated: Oct 13, 2026

---
<!--
URL: https://opencode.ai/docs/agents/
title: Agents | OpenCode
-->

[Skip to content](#_top)

[![](/docs/_astro/logo-dark.DOStV66V.svg) ![](/docs/_astro/logo-light.B0yzR0O5.svg)  OpenCode](/docs/)

[app.header.home](/)[app.header.docs](/v2/docs)

Search  `CtrlK`

Cancel

  [New OpenCode v2 is now available →](https://opencode.ai/v2)

* [Intro](/docs/)
* [Config](/docs/config/)
* [Providers](/docs/providers/)
* [Network](/docs/network/)
* [Enterprise](/docs/enterprise/)
* [Troubleshooting](/docs/troubleshooting/)
* [Windows](/docs/windows-wsl)
* Usage

  + [Go](https://opencode.ai/v2/docs/console/go/)
  + [TUI](/docs/tui/)
  + [CLI](/docs/cli/)
  + [Web](/docs/web/)
  + [IDE](/docs/ide/)
  + [Console](https://opencode.ai/v2/docs/console/)
  + [Share](/docs/share/)
  + [GitHub](/docs/github/)
  + [GitLab](/docs/gitlab/)
* Configure

  + [Tools](/docs/tools/)
  + [Rules](/docs/rules/)
  + [Agents](/docs/agents/)
  + [Models](/docs/models/)
  + [Themes](/docs/themes/)
  + [Keybinds](/docs/keybinds/)
  + [Commands](/docs/commands/)
  + [Formatters](/docs/formatters/)
  + [Permissions](/docs/permissions/)
  + [Policies](/docs/policies/)
  + [LSP Servers](/docs/lsp/)
  + [MCP servers](/docs/mcp-servers/)
  + [ACP Support](/docs/acp/)
  + [Agent Skills](/docs/skills/)
  + [References](/docs/references/)
  + [Custom Tools](/docs/custom-tools/)
* Develop

  + [SDK](/docs/sdk/)
  + [Server](/docs/server/)
  + [Plugins](/docs/plugins/)
  + [Ecosystem](/docs/ecosystem/)

[GitHub](https://github.com/anomalyco/opencode)[Discord](https://opencode.ai/discord)

  Select theme   DarkLightAuto         Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

On this page

* [Overview](#_top)
* [Types](#types)
  + [Primary agents](#primary-agents)
  + [Subagents](#subagents)
* [Built-in](#built-in)
  + [Use build](#use-build)
  + [Use plan](#use-plan)
  + [Use general](#use-general)
  + [Use explore](#use-explore)
  + [Use scout](#use-scout)
  + [Use compaction](#use-compaction)
  + [Use title](#use-title)
  + [Use summary](#use-summary)
* [Usage](#usage)
* [Configure](#configure)
  + [JSON](#json)
  + [Markdown](#markdown)
* [Options](#options)
  + [Description](#description)
  + [Temperature](#temperature)
  + [Max steps](#max-steps)
  + [Disable](#disable)
  + [Prompt](#prompt)
  + [Model](#model)
  + [Tools (deprecated)](#tools-deprecated)
  + [Permissions](#permissions)
  + [Mode](#mode)
  + [Hidden](#hidden)
  + [Task permissions](#task-permissions)
  + [Color](#color)
  + [Top P](#top-p)
  + [Additional](#additional)
* [Create agents](#create-agents)
* [Use cases](#use-cases)
* [Examples](#examples)
  + [Documentation agent](#documentation-agent)
  + [Security auditor](#security-auditor)

### On this page

* [Overview](#_top)
* [Types](#types)
  + [Primary agents](#primary-agents)
  + [Subagents](#subagents)
* [Built-in](#built-in)
  + [Use build](#use-build)
  + [Use plan](#use-plan)
  + [Use general](#use-general)
  + [Use explore](#use-explore)
  + [Use scout](#use-scout)
  + [Use compaction](#use-compaction)
  + [Use title](#use-title)
  + [Use summary](#use-summary)
* [Usage](#usage)
* [Configure](#configure)
  + [JSON](#json)
  + [Markdown](#markdown)
* [Options](#options)
  + [Description](#description)
  + [Temperature](#temperature)
  + [Max steps](#max-steps)
  + [Disable](#disable)
  + [Prompt](#prompt)
  + [Model](#model)
  + [Tools (deprecated)](#tools-deprecated)
  + [Permissions](#permissions)
  + [Mode](#mode)
  + [Hidden](#hidden)
  + [Task permissions](#task-permissions)
  + [Color](#color)
  + [Top P](#top-p)
  + [Additional](#additional)
* [Create agents](#create-agents)
* [Use cases](#use-cases)
* [Examples](#examples)
  + [Documentation agent](#documentation-agent)
  + [Security auditor](#security-auditor)

## Agents

Configure and use specialized agents.

Agents are specialized AI assistants that can be configured for specific tasks and workflows. They allow you to create focused tools with custom prompts, models, and tool access.

Tip

Use the plan agent to analyze code and review suggestions without making any code changes.

You can switch between agents during a session or invoke them with the `@` mention.

---

### [Types](#types)

There are two types of agents in OpenCode; primary agents and subagents.

---

#### [Primary agents](#primary-agents)

Primary agents are the main assistants you interact with directly. You can cycle through them using the **Tab** key, or your configured `switch_agent` keybind. These agents handle your main conversation. Tool access is configured via permissions â for example, Build has all tools enabled while Plan is restricted.

Tip

You can use the **Tab** key to switch between primary agents during a session.

OpenCode comes with two built-in primary agents, **Build** and **Plan**. Weâll
look at these below.

---

#### [Subagents](#subagents)

Subagents are specialized assistants that primary agents can invoke for specific tasks. You can also manually invoke them by **@ mentioning** them in your messages.

OpenCode comes with three built-in subagents, **General**, **Explore**, and **Scout**. Weâll look at this below.

---

### [Built-in](#built-in)

OpenCode comes with two built-in primary agents and three built-in subagents.

---

#### [Use build](#use-build)

*Mode*: `primary`

Build is the **default** primary agent with all tools enabled. This is the standard agent for development work where you need full access to file operations and system commands.

---

#### [Use plan](#use-plan)

*Mode*: `primary`

A restricted agent designed for planning and analysis. We use a permission system to give you more control and prevent unintended changes.
By default, all of the following are set to `ask`:

* `file edits`: All writes, patches, and edits
* `bash`: All bash commands

This agent is useful when you want the LLM to analyze code, suggest changes, or create plans without making any actual modifications to your codebase.

---

#### [Use general](#use-general)

*Mode*: `subagent`

A general-purpose agent for researching complex questions and executing multi-step tasks. Has full tool access, so it can make file changes when needed. Use this to run multiple units of work in parallel.

---

#### [Use explore](#use-explore)

*Mode*: `subagent`

A fast, read-only agent for exploring codebases. Cannot modify files. Use this when you need to quickly find files by patterns, search code for keywords, or answer questions about the codebase.

---

#### [Use scout](#use-scout)

*Mode*: `subagent`

A read-only agent for external docs and dependency research. Use this when you need to clone a dependency repository into OpenCodeâs managed cache, inspect library source, or cross-reference local code against upstream implementations without modifying your workspace.

---

#### [Use compaction](#use-compaction)

*Mode*: `primary`

Hidden system agent that compacts long context into a smaller summary. It runs automatically when needed and is not selectable in the UI.

---

#### [Use title](#use-title)

*Mode*: `primary`

Hidden system agent that generates short session titles. It runs automatically and is not selectable in the UI.

---

#### [Use summary](#use-summary)

*Mode*: `primary`

Hidden system agent that creates session summaries. It runs automatically and is not selectable in the UI.

---

### [Usage](#usage)

1. For primary agents, use the **Tab** key to cycle through them during a session. You can also use your configured `switch_agent` keybind.
2. Subagents can be invoked:

   * **Automatically** by primary agents for specialized tasks based on their descriptions.
   * Manually by **@ mentioning** a subagent in your message. For example.

     ```
     @general help me search for this function
     ```
3. **Navigation between sessions**: When subagents create child sessions, use `session_child_first` (default: **<Leader>+Down**) to enter the first child session from the parent.
4. Once you are in a child session, use:

   * `session_child_cycle` (default: **Right**) to cycle to the next child session
   * `session_child_cycle_reverse` (default: **Left**) to cycle to the previous child session
   * `session_parent` (default: **Up**) to return to the parent session

   This lets you switch between the main conversation and specialized subagent work.

---

### [Configure](#configure)

You can customize the built-in agents or create your own through configuration. Agents can be configured in two ways:

---

#### [JSON](#json)

Configure agents in your `opencode.json` config file:

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"agent": {

"build": {

"mode": "primary",

"model": "anthropic/claude-sonnet-4-20250514",

"prompt": "{file:./prompts/build.txt}",

"permission": {

"edit": "allow",

"bash": "allow"

}

},

"plan": {

"mode": "primary",

"model": "anthropic/claude-haiku-4-20250514",

"permission": {

"edit": "deny",

"bash": "deny"

}

},

"code-reviewer": {

"description": "Reviews code for best practices and potential issues",

"mode": "subagent",

"model": "anthropic/claude-sonnet-4-20250514",

"prompt": "You are a code reviewer. Focus on security, performance, and maintainability.",

"permission": {

"edit": "deny"

}

}

}

}
```

---

#### [Markdown](#markdown)

You can also define agents using markdown files. Place them in:

* Global: `~/.config/opencode/agents/`
* Per-project: `.opencode/agents/`

~/.config/opencode/agents/review.md

```
---

description: Reviews code for quality and best practices

mode: subagent

model: anthropic/claude-sonnet-4-20250514

temperature: 0.1

permission:

edit: deny

bash: deny

---

You are in code review mode. Focus on:

- Code quality and best practices

- Potential bugs and edge cases

- Performance implications

- Security considerations

Provide constructive feedback without making direct changes.
```

The markdown file name becomes the agent name. For example, `review.md` creates a `review` agent.

---

### [Options](#options)

Letâs look at these configuration options in detail.

---

#### [Description](#description)

Use the `description` option to provide a brief description of what the agent does and when to use it.

opencode.json

```
{

"agent": {

"review": {

"description": "Reviews code for best practices and potential issues"

}

}

}
```

This is a **required** config option.

---

#### [Temperature](#temperature)

Control the randomness and creativity of the LLMâs responses with the `temperature` config.

Lower values make responses more focused and deterministic, while higher values increase creativity and variability.

opencode.json

```
{

"agent": {

"plan": {

"temperature": 0.1

},

"creative": {

"temperature": 0.8

}

}

}
```

Temperature values typically range from 0.0 to 1.0:

* **0.0-0.2**: Very focused and deterministic responses, ideal for code analysis and planning
* **0.3-0.5**: Balanced responses with some creativity, good for general development tasks
* **0.6-1.0**: More creative and varied responses, useful for brainstorming and exploration

opencode.json

```
{

"agent": {

"analyze": {

"temperature": 0.1,

"prompt": "{file:./prompts/analysis.txt}"

},

"build": {

"temperature": 0.3

},

"brainstorm": {

"temperature": 0.7,

"prompt": "{file:./prompts/creative.txt}"

}

}

}
```

If no temperature is specified, OpenCode uses model-specific defaults; typically 0 for most models, 0.55 for Qwen models.

---

#### [Max steps](#max-steps)

Control the maximum number of agentic iterations an agent can perform before being forced to respond with text only. This allows users who wish to control costs to set a limit on agentic actions.

If this is not set, the agent will continue to iterate until the model chooses to stop or the user interrupts the session.

opencode.json

```
{

"agent": {

"quick-thinker": {

"description": "Fast reasoning with limited iterations",

"prompt": "You are a quick thinker. Solve problems with minimal steps.",

"steps": 5

}

}

}
```

When the limit is reached, the agent receives a special system prompt instructing it to respond with a summarization of its work and recommended remaining tasks.

Caution

The legacy `maxSteps` field is deprecated. Use `steps` instead.

---

#### [Disable](#disable)

Set to `true` to disable the agent.

opencode.json

```
{

"agent": {

"review": {

"disable": true

}

}

}
```

---

#### [Prompt](#prompt)

Specify a custom system prompt file for this agent with the `prompt` config. The prompt file should contain instructions specific to the agentâs purpose.

opencode.json

```
{

"agent": {

"review": {

"prompt": "{file:./prompts/code-review.txt}"

}

}

}
```

This path is relative to where the config file is located. So this works for both the global OpenCode config and the project specific config.

---

#### [Model](#model)

Use the `model` config to override the model for this agent. Useful for using different models optimized for different tasks. For example, a faster model for planning, a more capable model for implementation.

Tip

If you donât specify a model, primary agents use the [model globally configured](/docs/config#models) while subagents will use the model of the primary agent that invoked the subagent.

opencode.json

```
{

"agent": {

"plan": {

"model": "anthropic/claude-haiku-4-20250514"

}

}

}
```

The model ID in your OpenCode config uses the format `provider/model-id`. For example, if youâre using [OpenCode Zen](https://opencode.ai/v2/docs/console/), you would use `opencode/gpt-5.1-codex` for GPT 5.1 Codex.

---

#### [Tools (deprecated)](#tools-deprecated)

`tools` is **deprecated**. Prefer the agentâs [`permission`](#permissions) field for new configs, updates and more fine-grained control.

Allows you to control which tools are available in this agent. You can enable or disable specific tools by setting them to `true` or `false`. In an agentâs `tools` config, `true` is equivalent to `{"*": "allow"}` permission and `false` is equivalent to `{"*": "deny"}` permission.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"tools": {

"write": true,

"bash": true

},

"agent": {

"plan": {

"tools": {

"write": false,

"bash": false

}

}

}

}
```

Note

The agent-specific config overrides the global config.

You can also use wildcards in legacy `tools` entries to control multiple tools at once. For example, to disable all tools from an MCP server:

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"agent": {

"readonly": {

"tools": {

"mymcp_*": false,

"write": false,

"edit": false

}

}

}

}
```

[Learn more about tools](/docs/tools).

---

#### [Permissions](#permissions)

You can configure permissions to manage what actions an agent can take. Each permission key can be set to:

* `"ask"` â Prompt for approval before running the tool
* `"allow"` â Allow all operations without approval
* `"deny"` â Disable the tool

The available permission keys are:

| Key | Tools it gates |
| --- | --- |
| `read` | `read` |
| `edit` | `write`, `edit`, `apply_patch` |
| `glob` | `glob` |
| `grep` | `grep` |
| `list` | `list` |
| `bash` | `bash` |
| `task` | `task` |
| `external_directory` | Any tool that reads or writes files outside the project worktree |
| `webfetch` | `webfetch` |
| `websearch` | `websearch` |
| `lsp` | `lsp` |
| `skill` | `skill` |
| `question` | `question` |
| `doom_loop` | Recovery prompts when an agent appears stuck |

`read`, `edit`, `glob`, `grep`, `list`, `bash`, `task`, `external_directory`, `lsp`, and `skill` accept either a shorthand action (`"allow" | "ask" | "deny"`) or an object of glob/pattern â action for fine-grained control. The remaining keys accept the shorthand action only.

Note

Permission keys are matched as wildcard patterns against the underlying tool name, so the same syntax works for built-ins, custom tools, and MCP tools â for example `"mymcp_*": "deny"` denies every tool from an MCP server, and `"mymcp_search": "ask"` targets a single one.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"permission": {

"edit": "deny"

}

}
```

You can override these permissions per agent.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"permission": {

"edit": "deny"

},

"agent": {

"build": {

"permission": {

"edit": "ask"

}

}

}

}
```

You can also set permissions in Markdown agents.

~/.config/opencode/agents/review.md

```
---

description: Code review without edits

mode: subagent

permission:

edit: deny

bash:

"*": ask

"git diff": allow

"git log*": allow

"grep *": allow

webfetch: deny

---

Only analyze code and suggest changes.
```

You can set permissions for specific bash commands.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"agent": {

"build": {

"permission": {

"bash": {

"git push": "ask",

"grep *": "allow"

}

}

}

}

}
```

This can take a glob pattern.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"agent": {

"build": {

"permission": {

"bash": {

"git *": "ask"

}

}

}

}

}
```

And you can also use the `*` wildcard to manage permissions for all commands.
Since the last matching rule takes precedence, put the `*` wildcard first and specific rules after.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"agent": {

"build": {

"permission": {

"bash": {

"*": "ask",

"git status *": "allow"

}

}

}

}

}
```

[Learn more about permissions](/docs/permissions).

---

#### [Mode](#mode)

Control the agentâs mode with the `mode` config. The `mode` option is used to determine how the agent can be used.

opencode.json

```
{

"agent": {

"review": {

"mode": "subagent"

}

}

}
```

The `mode` option can be set to `primary`, `subagent`, or `all`. If no `mode` is specified, it defaults to `all`.

---

#### [Hidden](#hidden)

Hide a subagent from the `@` autocomplete menu with `hidden: true`. Useful for internal subagents that should only be invoked programmatically by other agents via the Task tool.

opencode.json

```
{

"agent": {

"internal-helper": {

"mode": "subagent",

"hidden": true

}

}

}
```

This only affects user visibility in the autocomplete menu. Hidden agents can still be invoked by the model via the Task tool if permissions allow.

Note

Only applies to `mode: subagent` agents.

---

#### [Task permissions](#task-permissions)

Control which subagents an agent can invoke via the Task tool with `permission.task`. Uses glob patterns for flexible matching.

opencode.json

```
{

"agent": {

"orchestrator": {

"mode": "primary",

"permission": {

"task": {

"*": "deny",

"orchestrator-*": "allow",

"code-reviewer": "ask"

}

}

}

}

}
```

When set to `deny`, the subagent is removed from the Task tool description entirely, so the model wonât attempt to invoke it.

Tip

Rules are evaluated in order, and the **last matching rule wins**. In the example above, `orchestrator-planner` matches both `*` (deny) and `orchestrator-*` (allow), but since `orchestrator-*` comes after `*`, the result is `allow`.

Tip

Users can always invoke any subagent directly via the `@` autocomplete menu, even if the agentâs task permissions would deny it.

---

#### [Color](#color)

Customize the agentâs visual appearance in the UI with the `color` option. This affects how the agent appears in the interface.

Use a valid hex color (e.g., `#FF5733`) or theme color: `primary`, `secondary`, `accent`, `success`, `warning`, `error`, `info`.

opencode.json

```
{

"agent": {

"creative": {

"color": "#ff6b6b"

},

"code-reviewer": {

"color": "accent"

}

}

}
```

---

#### [Top P](#top-p)

Control response diversity with the `top_p` option. Alternative to temperature for controlling randomness.

opencode.json

```
{

"agent": {

"brainstorm": {

"top_p": 0.9

}

}

}
```

Values range from 0.0 to 1.0. Lower values are more focused, higher values more diverse.

---

#### [Additional](#additional)

Any other options you specify in your agent configuration will be **passed through directly** to the provider as model options. This allows you to use provider-specific features and parameters.

For example, with OpenAIâs reasoning models, you can control the reasoning effort:

opencode.json

```
{

"agent": {

"deep-thinker": {

"description": "Agent that uses high reasoning effort for complex problems",

"model": "openai/gpt-5",

"reasoningEffort": "high",

"textVerbosity": "low"

}

}

}
```

These additional options are model and provider-specific. Check your providerâs documentation for available parameters.

Tip

Run `opencode models` to see a list of the available models.

---

### [Create agents](#create-agents)

You can create new agents using the following command:

Terminal window

```
opencode agent create
```

This interactive command will:

1. Ask where to save the agent; global or project-specific.
2. Description of what the agent should do.
3. Generate an appropriate system prompt and identifier.
4. Let you select which permissions the agent should be allowed (anything you donât select is denied).
5. Finally, create a markdown file with the agent configuration.

---

### [Use cases](#use-cases)

Here are some common use cases for different agents.

* **Build agent**: Full development work with all tools enabled
* **Plan agent**: Analysis and planning without making changes
* **Review agent**: Code review with read-only access plus documentation tools
* **Debug agent**: Focused on investigation with bash and read tools enabled
* **Docs agent**: Documentation writing with file operations but no system commands

---

### [Examples](#examples)

Here are some example agents you might find useful.

Tip

Do you have an agent youâd like to share? [Submit a PR](https://github.com/anomalyco/opencode).

---

#### [Documentation agent](#documentation-agent)

~/.config/opencode/agents/docs-writer.md

```
---

description: Writes and maintains project documentation

mode: subagent

permission:

bash: deny

---

You are a technical writer. Create clear, comprehensive documentation.

Focus on:

- Clear explanations

- Proper structure

- Code examples

- User-friendly language
```

---

#### [Security auditor](#security-auditor)

~/.config/opencode/agents/security-auditor.md

```
---

description: Performs security audits and identifies vulnerabilities

mode: subagent

permission:

edit: deny

---

You are a security expert. Focus on identifying potential security issues.

Look for:

- Input validation vulnerabilities

- Authentication and authorization flaws

- Data exposure risks

- Dependency vulnerabilities

- Configuration security issues
```

[Edit page](https://github.com/anomalyco/opencode/edit/dev/packages/web/src/content/docs/agents.mdx)[Found a bug? Open an issue](https://github.com/anomalyco/opencode/issues/new)[Join our Discord community](https://opencode.ai/discord)  Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

© [Anomaly](https://anoma.ly)

Last updated: Oct 13, 2026

---
<!--
URL: https://opencode.ai/docs/config/
title: Config | OpenCode
-->

[Skip to content](#_top)

[![](/docs/_astro/logo-dark.DOStV66V.svg) ![](/docs/_astro/logo-light.B0yzR0O5.svg)  OpenCode](/docs/)

[app.header.home](/)[app.header.docs](/v2/docs)

Search  `CtrlK`

Cancel

  [New OpenCode v2 is now available →](https://opencode.ai/v2)

* [Intro](/docs/)
* [Config](/docs/config/)
* [Providers](/docs/providers/)
* [Network](/docs/network/)
* [Enterprise](/docs/enterprise/)
* [Troubleshooting](/docs/troubleshooting/)
* [Windows](/docs/windows-wsl)
* Usage

  + [Go](https://opencode.ai/v2/docs/console/go/)
  + [TUI](/docs/tui/)
  + [CLI](/docs/cli/)
  + [Web](/docs/web/)
  + [IDE](/docs/ide/)
  + [Console](https://opencode.ai/v2/docs/console/)
  + [Share](/docs/share/)
  + [GitHub](/docs/github/)
  + [GitLab](/docs/gitlab/)
* Configure

  + [Tools](/docs/tools/)
  + [Rules](/docs/rules/)
  + [Agents](/docs/agents/)
  + [Models](/docs/models/)
  + [Themes](/docs/themes/)
  + [Keybinds](/docs/keybinds/)
  + [Commands](/docs/commands/)
  + [Formatters](/docs/formatters/)
  + [Permissions](/docs/permissions/)
  + [Policies](/docs/policies/)
  + [LSP Servers](/docs/lsp/)
  + [MCP servers](/docs/mcp-servers/)
  + [ACP Support](/docs/acp/)
  + [Agent Skills](/docs/skills/)
  + [References](/docs/references/)
  + [Custom Tools](/docs/custom-tools/)
* Develop

  + [SDK](/docs/sdk/)
  + [Server](/docs/server/)
  + [Plugins](/docs/plugins/)
  + [Ecosystem](/docs/ecosystem/)

[GitHub](https://github.com/anomalyco/opencode)[Discord](https://opencode.ai/discord)

  Select theme   DarkLightAuto         Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

On this page

* [Overview](#_top)
* [Format](#format)
* [Locations](#locations)
  + [Precedence order](#precedence-order)
  + [Remote](#remote)
  + [Global](#global)
  + [Per project](#per-project)
  + [Custom path](#custom-path)
  + [Custom directory](#custom-directory)
  + [Managed settings](#managed-settings)
* [Schema](#schema)
  + [TUI](#tui)
  + [Server](#server)
  + [Shell](#shell)
  + [Tools](#tools)
  + [Models](#models)
  + [Policies](#policies)
  + [Image attachments](#image-attachments)
  + [Themes](#themes)
  + [Agents](#agents)
  + [Default agent](#default-agent)
  + [Subagent depth](#subagent-depth)
  + [Sharing](#sharing)
  + [Commands](#commands)
  + [Keybinds](#keybinds)
  + [Snapshot](#snapshot)
  + [Autoupdate](#autoupdate)
  + [Formatters](#formatters)
  + [LSP Servers](#lsp-servers)
  + [Permissions](#permissions)
  + [Compaction](#compaction)
  + [Watcher](#watcher)
  + [MCP servers](#mcp-servers)
  + [Plugins](#plugins)
  + [Instructions](#instructions)
  + [Disabled providers](#disabled-providers)
  + [Enabled providers](#enabled-providers)
  + [Experimental](#experimental)
* [Variables](#variables)
  + [Env vars](#env-vars)
  + [Files](#files)

### On this page

* [Overview](#_top)
* [Format](#format)
* [Locations](#locations)
  + [Precedence order](#precedence-order)
  + [Remote](#remote)
  + [Global](#global)
  + [Per project](#per-project)
  + [Custom path](#custom-path)
  + [Custom directory](#custom-directory)
  + [Managed settings](#managed-settings)
* [Schema](#schema)
  + [TUI](#tui)
  + [Server](#server)
  + [Shell](#shell)
  + [Tools](#tools)
  + [Models](#models)
  + [Policies](#policies)
  + [Image attachments](#image-attachments)
  + [Themes](#themes)
  + [Agents](#agents)
  + [Default agent](#default-agent)
  + [Subagent depth](#subagent-depth)
  + [Sharing](#sharing)
  + [Commands](#commands)
  + [Keybinds](#keybinds)
  + [Snapshot](#snapshot)
  + [Autoupdate](#autoupdate)
  + [Formatters](#formatters)
  + [LSP Servers](#lsp-servers)
  + [Permissions](#permissions)
  + [Compaction](#compaction)
  + [Watcher](#watcher)
  + [MCP servers](#mcp-servers)
  + [Plugins](#plugins)
  + [Instructions](#instructions)
  + [Disabled providers](#disabled-providers)
  + [Enabled providers](#enabled-providers)
  + [Experimental](#experimental)
* [Variables](#variables)
  + [Env vars](#env-vars)
  + [Files](#files)

## Config

Using the OpenCode JSON config.

You can configure OpenCode using a JSON config file.

---

### [Format](#format)

OpenCode supports both **JSON** and **JSONC** (JSON with Comments) formats.

opencode.jsonc

```
{

"$schema": "https://opencode.ai/config.json",

"model": "anthropic/claude-sonnet-4-5",

"autoupdate": true,

"server": {

"port": 4096,

},

}
```

---

### [Locations](#locations)

You can place your config in a couple of different locations and they have a
different order of precedence.

Note

Configuration files are **merged together**, not replaced.

Configuration files are merged together, not replaced. Settings from the following config locations are combined. Later configs override earlier ones only for conflicting keys. Non-conflicting settings from all configs are preserved.

For example, if your global config sets `autoupdate: true` and your project config sets `model: "anthropic/claude-sonnet-4-5"`, the final configuration will include both settings.

---

#### [Precedence order](#precedence-order)

Config sources are loaded in this order (later sources override earlier ones):

1. **Remote config** (from `.well-known/opencode`) - organizational defaults
2. **Global config** (`~/.config/opencode/opencode.json`) - user preferences
3. **Custom config** (`OPENCODE_CONFIG` env var) - custom overrides
4. **Project config** (`opencode.json` in project) - project-specific settings
5. **`.opencode` directories** - agents, commands, plugins
6. **Inline config** (`OPENCODE_CONFIG_CONTENT` env var) - runtime overrides
7. **Managed config files** (`/Library/Application Support/opencode/` on macOS) - admin-controlled
8. **macOS managed preferences** (`.mobileconfig` via MDM) - highest priority, not user-overridable

This means project configs can override global defaults, and global configs can override remote organizational defaults. Managed settings override everything.

Note

The `.opencode` and `~/.config/opencode` directories use **plural names** for subdirectories: `agents/`, `commands/`, `modes/`, `plugins/`, `skills/`, `tools/`, and `themes/`. Singular names (e.g., `agent/`) are also supported for backwards compatibility.

---

#### [Remote](#remote)

Organizations can provide default configuration via the `.well-known/opencode` endpoint. This is fetched automatically when you authenticate with a provider that supports it.

Remote config is loaded first, serving as the base layer. All other config sources (global, project) can override these defaults.

For example, if your organization provides MCP servers that are disabled by default:

Remote config from .well-known/opencode

```
{

"mcp": {

"jira": {

"type": "remote",

"url": "https://jira.example.com/mcp",

"enabled": false

}

}

}
```

You can enable specific servers in your local config:

opencode.json

```
{

"mcp": {

"jira": {

"type": "remote",

"url": "https://jira.example.com/mcp",

"enabled": true

}

}

}
```

---

#### [Global](#global)

Place your global OpenCode config in `~/.config/opencode/opencode.json`. Use global config for user-wide server/runtime preferences like providers, models, and permissions.

For TUI-specific settings, use `~/.config/opencode/tui.json`.

Global config overrides remote organizational defaults.

---

#### [Per project](#per-project)

Add `opencode.json` in your project root. Project config has the highest precedence among standard config files - it overrides both global and remote configs.

For project-specific TUI settings, add `tui.json` alongside it.

Tip

Place project specific config in the root of your project.

When OpenCode starts up, it first looks for a config file in the current directory, then traverses up to the nearest Git directory.

This is also safe to be checked into Git and uses the same schema as the global one.

---

#### [Custom path](#custom-path)

Specify a custom config file path using the `OPENCODE_CONFIG` environment variable.

Terminal window

```
export OPENCODE_CONFIG=/path/to/my/custom-config.json

opencode run "Hello world"
```

Custom config is loaded between global and project configs in the precedence order.

---

#### [Custom directory](#custom-directory)

Specify a custom config directory using the `OPENCODE_CONFIG_DIR`
environment variable. This directory will be searched for agents, commands,
modes, and plugins just like the standard `.opencode` directory, and should
follow the same structure.

Terminal window

```
export OPENCODE_CONFIG_DIR=/path/to/my/config-directory

opencode run "Hello world"
```

The custom directory is loaded after the global config and `.opencode` directories, so it **can override** their settings.

---

#### [Managed settings](#managed-settings)

Organizations can enforce configuration that users cannot override. Managed settings are loaded at the highest priority tier.

##### [File-based](#file-based)

Drop an `opencode.json` or `opencode.jsonc` file in the system managed config directory:

| Platform | Path |
| --- | --- |
| macOS | `/Library/Application Support/opencode/` |
| Linux | `/etc/opencode/` |
| Windows | `%ProgramData%\opencode` |

These directories require admin/root access to write, so users cannot modify them.

##### [macOS managed preferences](#macos-managed-preferences)

On macOS, OpenCode reads managed preferences from the `ai.opencode.managed` preference domain. Deploy a `.mobileconfig` via MDM (Jamf, Kandji, FleetDM) and the settings are enforced automatically.

OpenCode checks these paths:

1. `/Library/Managed Preferences/<user>/ai.opencode.managed.plist`
2. `/Library/Managed Preferences/ai.opencode.managed.plist`

The plist keys map directly to `opencode.json` fields. MDM metadata keys (`PayloadUUID`, `PayloadType`, etc.) are stripped automatically.

**Creating a `.mobileconfig`**

Use the `ai.opencode.managed` PayloadType. The OpenCode config keys go directly in the payload dict:

```
<?xml version="1.0" encoding="UTF-8"?>

<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"

"http://www.apple.com/DTDs/PropertyList-1.0.dtd">

<plist version="1.0">

<dict>

<key>PayloadContent</key>

<array>

<dict>

<key>PayloadType</key>

<string>ai.opencode.managed</string>

<key>PayloadIdentifier</key>

<string>com.example.opencode.config</string>

<key>PayloadUUID</key>

<string>GENERATE-YOUR-OWN-UUID</string>

<key>PayloadVersion</key>

<integer>1</integer>

<key>share</key>

<string>disabled</string>

<key>server</key>

<dict>

<key>hostname</key>

<string>127.0.0.1</string>

</dict>

<key>permission</key>

<dict>

<key>*</key>

<string>ask</string>

<key>bash</key>

<dict>

<key>*</key>

<string>ask</string>

<key>rm -rf *</key>

<string>deny</string>

</dict>

</dict>

</dict>

</array>

<key>PayloadType</key>

<string>Configuration</string>

<key>PayloadIdentifier</key>

<string>com.example.opencode</string>

<key>PayloadUUID</key>

<string>GENERATE-YOUR-OWN-UUID</string>

<key>PayloadVersion</key>

<integer>1</integer>

</dict>

</plist>
```

Generate unique UUIDs with `uuidgen`. Customize the settings to match your organizationâs requirements.

**Deploying via MDM**

* **Jamf Pro:** Computers > Configuration Profiles > Upload > scope to target devices or smart groups
* **FleetDM:** Add the `.mobileconfig` to your gitops repo under `mdm.macos_settings.custom_settings` and run `fleetctl apply`

**Verifying on a device**

Double-click the `.mobileconfig` to install locally for testing (shows in System Settings > Privacy & Security > Profiles), then run:

Terminal window

```
opencode debug config
```

All managed preference keys appear in the resolved config and cannot be overridden by user or project configuration.

---

### [Schema](#schema)

The server/runtime config schema is defined in [**`opencode.ai/config.json`**](https://opencode.ai/config.json).

TUI config uses [**`opencode.ai/tui.json`**](https://opencode.ai/tui.json).

Your editor should be able to validate and autocomplete based on the schema.

---

#### [TUI](#tui)

Use a dedicated `tui.json` (or `tui.jsonc`) file for TUI-specific settings.

tui.json

```
{

"$schema": "https://opencode.ai/tui.json",

"scroll_speed": 3,

"scroll_acceleration": {

"enabled": true

},

"diff_style": "auto",

"cursor": {

"style": "block",

"blinking": true

},

"mouse": true,

"attention": {

"enabled": true,

"notifications": true,

"sound": true,

"volume": 0.4

}

}
```

Use `OPENCODE_TUI_CONFIG` to point to a custom TUI config file.

When `cursor.style` is `"default"`, the terminal default cursor is restored, so `cursor.blinking` has no effect.

Set `attention.enabled` to turn on TUI desktop notifications and sounds. See [TUI attention](/docs/tui#attention).

Legacy `theme`, `keybinds`, and `tui` keys in `opencode.json` are deprecated and automatically migrated when possible.

---

#### [Server](#server)

You can configure server settings for the `opencode serve` and `opencode web` commands through the `server` option.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"server": {

"port": 4096,

"hostname": "0.0.0.0",

"mdns": true,

"mdnsDomain": "myproject.local",

"cors": ["http://localhost:5173"]

}

}
```

Available options:

* `port` - Port to listen on.
* `hostname` - Hostname to listen on. When `mdns` is enabled and no hostname is set, defaults to `0.0.0.0`.
* `mdns` - Enable mDNS service discovery. This allows other devices on the network to discover your OpenCode server.
* `mdnsDomain` - Custom domain name for mDNS service. Defaults to `opencode.local`. Useful for running multiple instances on the same network.
* `cors` - Additional origins to allow for CORS when using the HTTP server from a browser-based client. Values must be full origins (scheme + host + optional port), eg `https://app.example.com`.

[Learn more about the server here](/docs/server).

---

#### [Shell](#shell)

You can configure the shell used for the interactive terminal using the `shell` option. Compatible shells are also used for agent tool calls.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"shell": "pwsh"

}
```

If not specified, OpenCode will automatically discover and use a sensible default based on your operating system (e.g. `pwsh` or `cmd.exe` on Windows, `/bin/zsh` or `/bin/bash` on macOS/Linux). You can provide an absolute path or a short name.

---

#### [Tools](#tools)

You can manage the tools an LLM can use through the `tools` option.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"tools": {

"write": false,

"bash": false

}

}
```

[Learn more about tools here](/docs/tools).

---

#### [Models](#models)

You can configure the providers and models you want to use in your OpenCode config through the `provider`, `model` and `small_model` options.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"provider": {},

"model": "anthropic/claude-sonnet-4-5",

"small_model": "anthropic/claude-haiku-4-5"

}
```

The `small_model` option configures a separate model for lightweight tasks like title generation. By default, OpenCode tries to use a cheaper model if one is available from your provider, otherwise it falls back to your main model.

Provider options can include `timeout`, `headerTimeout`, `chunkTimeout`, and `setCacheKey`:

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"provider": {

"anthropic": {

"options": {

"timeout": 600000,

"chunkTimeout": 30000,

"setCacheKey": true

}

}

}

}
```

* `timeout` - Request timeout in milliseconds (default: 300000). Set to `false` to disable.
* `headerTimeout` - Timeout in milliseconds to wait for response headers (default: 300000, or 5 minutes). This timer stops once headers arrive and does not limit the streamed response body. Set to `false` to disable.
* `chunkTimeout` - Timeout in milliseconds between streamed response chunks (default: 300000, or 5 minutes). If no chunk arrives in time, the request is aborted. Set to `false` to disable.
* `setCacheKey` - Ensure a cache key is always set for designated provider.

You can also configure [local models](/docs/models#local). [Learn more](/docs/models).

---

#### [Policies](#policies)

Use the `experimental.policies` option to allow or deny OpenCode actions on configured resources. Currently, policies can control which providers OpenCode may use.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"experimental": {

"policies": [

{

"effect": "deny",

"action": "provider.use",

"resource": "openai"

}

]

}

}
```

[Learn more about policies here](/docs/policies).

---

#### [Image attachments](#image-attachments)

OpenCode normalizes image attachments before sending them to the model. By default, images are resized when they exceed `2000x2000` pixels or `5242880` base64 bytes.

Configure image attachment limits with the `attachment.image` option:

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"attachment": {

"image": {

"auto_resize": true,

"max_width": 2000,

"max_height": 2000,

"max_base64_bytes": 5242880

}

}

}
```

* `auto_resize` - Resize images that exceed the configured limits before provider requests. Set to `false` to reject oversized images instead.
* `max_width` - Maximum image width in pixels before resizing or rejection.
* `max_height` - Maximum image height in pixels before resizing or rejection.
* `max_base64_bytes` - Maximum encoded image payload size. This is the base64 payload size, not the original file size.

If an image still cannot fit after resizing, OpenCode omits oversized tool-result images or fails oversized user-provided images with an image size error.

---

##### [Provider-Specific Options](#provider-specific-options)

Some providers support additional configuration options beyond the generic `timeout` and `apiKey` settings.

###### [Amazon Bedrock](#amazon-bedrock)

Amazon Bedrock supports AWS-specific configuration:

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"provider": {

"amazon-bedrock": {

"options": {

"region": "us-east-1",

"profile": "my-aws-profile",

"endpoint": "https://bedrock-runtime.us-east-1.vpce-xxxxx.amazonaws.com"

}

}

}

}
```

* `region` - AWS region for Bedrock (defaults to `AWS_REGION` env var or `us-east-1`)
* `profile` - AWS named profile from `~/.aws/credentials` (defaults to `AWS_PROFILE` env var)
* `endpoint` - Custom endpoint URL for VPC endpoints. This is an alias for the generic `baseURL` option using AWS-specific terminology. If both are specified, `endpoint` takes precedence.

Note

Bearer tokens (`AWS_BEARER_TOKEN_BEDROCK` or `/connect`) take precedence over profile-based authentication. See [authentication precedence](/docs/providers#authentication-precedence) for details.

[Learn more about Amazon Bedrock configuration](/docs/providers#amazon-bedrock).

---

#### [Themes](#themes)

Set your UI theme in `tui.json`.

tui.json

```
{

"$schema": "https://opencode.ai/tui.json",

"theme": "tokyonight"

}
```

[Learn more here](/docs/themes).

---

#### [Agents](#agents)

You can configure specialized agents for specific tasks through the `agent` option.

opencode.jsonc

```
{

"$schema": "https://opencode.ai/config.json",

"agent": {

"code-reviewer": {

"description": "Reviews code for best practices and potential issues",

"model": "anthropic/claude-sonnet-4-5",

"prompt": "You are a code reviewer. Focus on security, performance, and maintainability.",

"tools": {

// Disable file modification tools for review-only agent

"write": false,

"edit": false,

},

},

},

}
```

You can also define agents using markdown files in `~/.config/opencode/agents/` or `.opencode/agents/`. [Learn more here](/docs/agents).

---

#### [Default agent](#default-agent)

You can set the default agent using the `default_agent` option. This determines which agent is used when none is explicitly specified.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"default_agent": "plan"

}
```

The default agent must be a primary agent (not a subagent). This can be a built-in agent like `"build"` or `"plan"`, or a [custom agent](/docs/agents) youâve defined. If the specified agent doesnât exist or is a subagent, OpenCode will fall back to `"build"` with a warning.

This setting applies across all interfaces: TUI, CLI (`opencode run`), desktop app, and GitHub Action.

---

#### [Subagent depth](#subagent-depth)

You can control how deeply subagents can invoke other subagents using the `subagent_depth` option.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"subagent_depth": 2

}
```

The default is `1`, which allows primary agents to launch subagents but prevents those subagents from launching additional subagents. Set it to `2` to allow one additional level of nested subagents, or `0` to prevent all subagent launches.

---

#### [Sharing](#sharing)

You can configure the [share](/docs/share) feature through the `share` option.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"share": "manual"

}
```

This takes:

* `"manual"` - Allow manual sharing via commands (default)
* `"auto"` - Automatically share new conversations
* `"disabled"` - Disable sharing entirely

By default, sharing is set to manual mode where you need to explicitly share conversations using the `/share` command.

---

#### [Commands](#commands)

You can configure custom commands for repetitive tasks through the `command` option.

opencode.jsonc

```
{

"$schema": "https://opencode.ai/config.json",

"command": {

"test": {

"template": "Run the full test suite with coverage report and show any failures.\nFocus on the failing tests and suggest fixes.",

"description": "Run tests with coverage",

"agent": "build",

"model": "anthropic/claude-haiku-4-5",

},

"component": {

"template": "Create a new React component named $ARGUMENTS with TypeScript support.\nInclude proper typing and basic structure.",

"description": "Create a new component",

},

},

}
```

You can also define commands using markdown files in `~/.config/opencode/commands/` or `.opencode/commands/`. [Learn more here](/docs/commands).

---

#### [Keybinds](#keybinds)

Customize TUI keyboard shortcuts in `tui.json` with `keybinds`.

tui.json

```
{

"$schema": "https://opencode.ai/tui.json",

"keybinds": {

"command_list": "ctrl+p"

}

}
```

`keybinds` is merged with built-in defaults, so you only need to configure the shortcuts you want to change.

[Learn more here](/docs/keybinds).

---

#### [Snapshot](#snapshot)

OpenCode uses snapshots to track file changes during agent operations, enabling you to undo and revert changes within a session. Snapshots are enabled by default.

For large repositories or projects with many submodules, the snapshot system can cause slow indexing and significant disk usage as it tracks all changes using an internal git repository. You can disable snapshots using the `snapshot` option.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"snapshot": false

}
```

Note that disabling snapshots means changes made by the agent cannot be rolled back through the UI.

---

#### [Autoupdate](#autoupdate)

OpenCode will automatically download any new updates when it starts up. You can disable this with the `autoupdate` option.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"autoupdate": false

}
```

If you donât want updates but want to be notified when a new version is available, set `autoupdate` to `"notify"`.
Notice that this only works if it was not installed using a package manager such as Homebrew.

---

#### [Formatters](#formatters)

You can enable and configure code formatters through the `formatter` option. Omit it to keep formatters disabled.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"formatter": true

}
```

Use an object to keep built-ins enabled while configuring overrides or custom formatters.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"formatter": {

"prettier": {

"disabled": true

},

"custom-prettier": {

"command": ["npx", "prettier", "--write", "$FILE"],

"environment": {

"NODE_ENV": "development"

},

"extensions": [".js", ".ts", ".jsx", ".tsx"]

}

}

}
```

[Learn more about formatters here](/docs/formatters).

---

#### [LSP Servers](#lsp-servers)

You can enable and configure LSP servers through the `lsp` option. Omit it to keep LSP disabled.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"lsp": true

}
```

Use an object to keep built-ins enabled while configuring overrides or custom LSP servers.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"lsp": {

"typescript": {

"disabled": true

}

}

}
```

[Learn more about LSP servers here](/docs/lsp).

---

#### [Permissions](#permissions)

By default, opencode **allows all operations** without requiring explicit approval. You can change this using the `permission` option.

For example, to ensure that the `edit` and `bash` tools require user approval:

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"permission": {

"edit": "ask",

"bash": "ask"

}

}
```

[Learn more about permissions here](/docs/permissions).

---

#### [Compaction](#compaction)

You can control context compaction behavior through the `compaction` option.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"compaction": {

"auto": true,

"prune": false,

"reserved": 10000

}

}
```

* `auto` - Automatically compact the session when context is full (default: `true`).
* `prune` - Remove old tool outputs to save tokens (default: `false`). Set to `true` to enable pruning.
* `reserved` - Token buffer for compaction. Leaves enough window to avoid overflow during compaction.

---

#### [Watcher](#watcher)

You can configure file watcher ignore patterns through the `watcher` option.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"watcher": {

"ignore": ["**/generated/**"]

}

}
```

Patterns follow glob syntax. Common dependency, VCS, build, and cache directories are ignored automatically at any depth.

---

#### [MCP servers](#mcp-servers)

You can configure MCP servers you want to use through the `mcp` option.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"mcp": {}

}
```

[Learn more here](/docs/mcp-servers).

---

#### [Plugins](#plugins)

[Plugins](/docs/plugins) extend OpenCode with custom tools, hooks, and integrations.

Place plugin files in `.opencode/plugins/` or `~/.config/opencode/plugins/`. You can also load plugins from npm through the `plugin` option.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"plugin": ["opencode-helicone-session", "@my-org/custom-plugin"]

}
```

[Learn more here](/docs/plugins).

---

#### [Instructions](#instructions)

You can configure the instructions for the model youâre using through the `instructions` option.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"instructions": ["CONTRIBUTING.md", "docs/guidelines.md", ".cursor/rules/*.md"]

}
```

This takes an array of paths and glob patterns to instruction files. [Learn more
about rules here](/docs/rules).

---

#### [Disabled providers](#disabled-providers)

You can disable providers that are loaded automatically through the `disabled_providers` option. This is useful when you want to prevent certain providers from being loaded even if their credentials are available.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"disabled_providers": ["openai", "gemini"]

}
```

Note

The `disabled_providers` takes priority over `enabled_providers`.

The `disabled_providers` option accepts an array of provider IDs. When a provider is disabled:

* It wonât be loaded even if environment variables are set.
* It wonât be loaded even if API keys are configured through the `/connect` command.
* The providerâs models wonât appear in the model selection list.

---

#### [Enabled providers](#enabled-providers)

You can specify an allowlist of providers through the `enabled_providers` option. When set, only the specified providers will be enabled and all others will be ignored.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"enabled_providers": ["anthropic", "openai"]

}
```

This is useful when you want to restrict OpenCode to only use specific providers rather than disabling them one by one.

Note

The `disabled_providers` takes priority over `enabled_providers`.

If a provider appears in both `enabled_providers` and `disabled_providers`, the `disabled_providers` takes priority for backwards compatibility.

---

#### [Experimental](#experimental)

The `experimental` key contains options that are under active development.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"experimental": {}

}
```

Caution

Experimental options are not stable. They may change or be removed without notice.

---

### [Variables](#variables)

You can use variable substitution in your config files to reference environment variables and file contents.

---

#### [Env vars](#env-vars)

Use `{env:VARIABLE_NAME}` to substitute environment variables:

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"model": "{env:OPENCODE_MODEL}",

"provider": {

"anthropic": {

"models": {},

"options": {

"apiKey": "{env:ANTHROPIC_API_KEY}"

}

}

}

}
```

If the environment variable is not set, it will be replaced with an empty string.

---

#### [Files](#files)

Use `{file:path/to/file}` to substitute the contents of a file:

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"instructions": ["./custom-instructions.md"],

"provider": {

"openai": {

"options": {

"apiKey": "{file:~/.secrets/openai-key}"

}

}

}

}
```

File paths can be:

* Relative to the config file directory
* Or absolute paths starting with `/` or `~`

These are useful for:

* Keeping sensitive data like API keys in separate files.
* Including large instruction files without cluttering your config.
* Sharing common configuration snippets across multiple config files.

[Edit page](https://github.com/anomalyco/opencode/edit/dev/packages/web/src/content/docs/config.mdx)[Found a bug? Open an issue](https://github.com/anomalyco/opencode/issues/new)[Join our Discord community](https://opencode.ai/discord)  Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

© [Anomaly](https://anoma.ly)

Last updated: Oct 13, 2026

---
<!--
URL: https://opencode.ai/docs/policies/
title: Policies | OpenCode
-->

[Skip to content](#_top)

[![](/docs/_astro/logo-dark.DOStV66V.svg) ![](/docs/_astro/logo-light.B0yzR0O5.svg)  OpenCode](/docs/)

[app.header.home](/)[app.header.docs](/v2/docs)

Search  `CtrlK`

Cancel

  [New OpenCode v2 is now available →](https://opencode.ai/v2)

* [Intro](/docs/)
* [Config](/docs/config/)
* [Providers](/docs/providers/)
* [Network](/docs/network/)
* [Enterprise](/docs/enterprise/)
* [Troubleshooting](/docs/troubleshooting/)
* [Windows](/docs/windows-wsl)
* Usage

  + [Go](https://opencode.ai/v2/docs/console/go/)
  + [TUI](/docs/tui/)
  + [CLI](/docs/cli/)
  + [Web](/docs/web/)
  + [IDE](/docs/ide/)
  + [Console](https://opencode.ai/v2/docs/console/)
  + [Share](/docs/share/)
  + [GitHub](/docs/github/)
  + [GitLab](/docs/gitlab/)
* Configure

  + [Tools](/docs/tools/)
  + [Rules](/docs/rules/)
  + [Agents](/docs/agents/)
  + [Models](/docs/models/)
  + [Themes](/docs/themes/)
  + [Keybinds](/docs/keybinds/)
  + [Commands](/docs/commands/)
  + [Formatters](/docs/formatters/)
  + [Permissions](/docs/permissions/)
  + [Policies](/docs/policies/)
  + [LSP Servers](/docs/lsp/)
  + [MCP servers](/docs/mcp-servers/)
  + [ACP Support](/docs/acp/)
  + [Agent Skills](/docs/skills/)
  + [References](/docs/references/)
  + [Custom Tools](/docs/custom-tools/)
* Develop

  + [SDK](/docs/sdk/)
  + [Server](/docs/server/)
  + [Plugins](/docs/plugins/)
  + [Ecosystem](/docs/ecosystem/)

[GitHub](https://github.com/anomalyco/opencode)[Discord](https://opencode.ai/discord)

  Select theme   DarkLightAuto         Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

On this page

* [Overview](#_top)
* [Configuration](#configuration)
* [Available Policies](#available-policies)
* [Matching](#matching)
* [Rule Order](#rule-order)
* [Provider Lists](#provider-lists)

### On this page

* [Overview](#_top)
* [Configuration](#configuration)
* [Available Policies](#available-policies)
* [Matching](#matching)
* [Rule Order](#rule-order)
* [Provider Lists](#provider-lists)

## Policies

Control which configured resources OpenCode may use.

Policies control whether OpenCode may perform an action on a named resource. This feature is experimental and is configured with the `experimental.policies` array in `opencode.json`.

Policies are separate from [permissions](/docs/permissions). Permissions control what tools can do during a session, while policies control whether OpenCode may use a resource such as an LLM provider.

---

### [Configuration](#configuration)

Each policy statement has three fields:

* `effect` - Either `"allow"` or `"deny"`.
* `action` - The operation being controlled.
* `resource` - The resource ID or wildcard pattern the statement applies to.

For example, deny use of the `openai` provider:

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"experimental": {

"policies": [

{

"effect": "deny",

"action": "provider.use",

"resource": "openai"

}

]

}

}
```

A provider denied by policy is not available for model selection or model use, even if it has credentials or is otherwise configured correctly.

---

### [Available Policies](#available-policies)

OpenCode currently supports one policy action:

| Action | Resource | Description |
| --- | --- | --- |
| `provider.use` | Provider ID, such as `openai` | Allow or deny use of an LLM provider. |

More policy actions may be added in the future.

---

### [Matching](#matching)

The `resource` field supports wildcard matching. Use `*` to match zero or more characters and `?` to match one character.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"experimental": {

"policies": [

{

"effect": "deny",

"action": "provider.use",

"resource": "company-*"

}

]

}

}
```

This denies providers such as `company-us` and `company-eu`.

---

### [Rule Order](#rule-order)

When multiple statements match, the last matching statement wins. Put broad rules first, then more specific exceptions after them.

For example, allow only Anthropic:

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"experimental": {

"policies": [

{

"effect": "deny",

"action": "provider.use",

"resource": "*"

},

{

"effect": "allow",

"action": "provider.use",

"resource": "anthropic"

}

]

}

}
```

If no policy matches a provider, provider use is allowed by default.

Policies may be set in both your global config and project config. If policies from both locations match the same provider, your global policy takes priority over the project policy. This prevents a repository from re-enabling a provider that you deny globally.

---

### [Provider Lists](#provider-lists)

Use policies instead of the older `disabled_providers` and `enabled_providers` settings when controlling provider access.

To replace `disabled_providers`:

opencode.json

```
{

"experimental": {

"policies": [

{ "effect": "deny", "action": "provider.use", "resource": "openai" },

{ "effect": "deny", "action": "provider.use", "resource": "google" }

]

}

}
```

To replace `enabled_providers`, deny all providers first and allow the selected providers after it:

opencode.json

```
{

"experimental": {

"policies": [

{ "effect": "deny", "action": "provider.use", "resource": "*" },

{ "effect": "allow", "action": "provider.use", "resource": "anthropic" },

{ "effect": "allow", "action": "provider.use", "resource": "openai" }

]

}

}
```

[Edit page](https://github.com/anomalyco/opencode/edit/dev/packages/web/src/content/docs/policies.mdx)[Found a bug? Open an issue](https://github.com/anomalyco/opencode/issues/new)[Join our Discord community](https://opencode.ai/discord)  Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

© [Anomaly](https://anoma.ly)

Last updated: Oct 13, 2026

---
<!--
URL: https://opencode.ai/docs/web/
title: Web | OpenCode
-->

[Skip to content](#_top)

[![](/docs/_astro/logo-dark.DOStV66V.svg) ![](/docs/_astro/logo-light.B0yzR0O5.svg)  OpenCode](/docs/)

[app.header.home](/)[app.header.docs](/v2/docs)

Search  `CtrlK`

Cancel

  [New OpenCode v2 is now available →](https://opencode.ai/v2)

* [Intro](/docs/)
* [Config](/docs/config/)
* [Providers](/docs/providers/)
* [Network](/docs/network/)
* [Enterprise](/docs/enterprise/)
* [Troubleshooting](/docs/troubleshooting/)
* [Windows](/docs/windows-wsl)
* Usage

  + [Go](https://opencode.ai/v2/docs/console/go/)
  + [TUI](/docs/tui/)
  + [CLI](/docs/cli/)
  + [Web](/docs/web/)
  + [IDE](/docs/ide/)
  + [Console](https://opencode.ai/v2/docs/console/)
  + [Share](/docs/share/)
  + [GitHub](/docs/github/)
  + [GitLab](/docs/gitlab/)
* Configure

  + [Tools](/docs/tools/)
  + [Rules](/docs/rules/)
  + [Agents](/docs/agents/)
  + [Models](/docs/models/)
  + [Themes](/docs/themes/)
  + [Keybinds](/docs/keybinds/)
  + [Commands](/docs/commands/)
  + [Formatters](/docs/formatters/)
  + [Permissions](/docs/permissions/)
  + [Policies](/docs/policies/)
  + [LSP Servers](/docs/lsp/)
  + [MCP servers](/docs/mcp-servers/)
  + [ACP Support](/docs/acp/)
  + [Agent Skills](/docs/skills/)
  + [References](/docs/references/)
  + [Custom Tools](/docs/custom-tools/)
* Develop

  + [SDK](/docs/sdk/)
  + [Server](/docs/server/)
  + [Plugins](/docs/plugins/)
  + [Ecosystem](/docs/ecosystem/)

[GitHub](https://github.com/anomalyco/opencode)[Discord](https://opencode.ai/discord)

  Select theme   DarkLightAuto         Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

On this page

* [Overview](#_top)
* [Getting Started](#getting-started)
* [Configuration](#configuration)
  + [Port](#port)
  + [Hostname](#hostname)
  + [mDNS Discovery](#mdns-discovery)
  + [CORS](#cors)
  + [Authentication](#authentication)
* [Using the Web Interface](#using-the-web-interface)
  + [Sessions](#sessions)
  + [Server Status](#server-status)
* [Attaching a Terminal](#attaching-a-terminal)
* [Config File](#config-file)

### On this page

* [Overview](#_top)
* [Getting Started](#getting-started)
* [Configuration](#configuration)
  + [Port](#port)
  + [Hostname](#hostname)
  + [mDNS Discovery](#mdns-discovery)
  + [CORS](#cors)
  + [Authentication](#authentication)
* [Using the Web Interface](#using-the-web-interface)
  + [Sessions](#sessions)
  + [Server Status](#server-status)
* [Attaching a Terminal](#attaching-a-terminal)
* [Config File](#config-file)

## Web

Using OpenCode in your browser.

OpenCode can run as a web application in your browser, providing the same powerful AI coding experience without needing a terminal.

![OpenCode Web - New Session](/docs/_astro/web-homepage-new-session.BB1mEdgo_Z1AT1v3.webp)

### [Getting Started](#getting-started)

Start the web interface by running:

Terminal window

```
opencode web
```

This starts a local server on `127.0.0.1` with a random available port and automatically opens OpenCode in your default browser.

Caution

If `OPENCODE_SERVER_PASSWORD` is not set, the server will be unsecured. This is fine for local use but should be set for network access.

Windows Users

For the best experience, run `opencode web` from [WSL](/docs/windows-wsl) rather than PowerShell. This ensures proper file system access and terminal integration.

---

### [Configuration](#configuration)

You can configure the web server using command line flags or in your [config file](/docs/config).

#### [Port](#port)

By default, OpenCode picks an available port. You can specify a port:

Terminal window

```
opencode web --port 4096
```

#### [Hostname](#hostname)

By default, the server binds to `127.0.0.1` (localhost only). To make OpenCode accessible on your network:

Terminal window

```
opencode web --hostname 0.0.0.0
```

When using `0.0.0.0`, OpenCode will display both local and network addresses:

```
Local access:       http://localhost:4096

Network access:     http://192.168.1.100:4096
```

#### [mDNS Discovery](#mdns-discovery)

Enable mDNS to make your server discoverable on the local network:

Terminal window

```
opencode web --mdns
```

This automatically sets the hostname to `0.0.0.0` and advertises the server as `opencode.local`.

You can customize the mDNS domain name to run multiple instances on the same network:

Terminal window

```
opencode web --mdns --mdns-domain myproject.local
```

#### [CORS](#cors)

To allow additional domains for CORS (useful for custom frontends):

Terminal window

```
opencode web --cors https://example.com
```

#### [Authentication](#authentication)

To protect access, set a password using the `OPENCODE_SERVER_PASSWORD` environment variable:

Terminal window

```
OPENCODE_SERVER_PASSWORD=secret opencode web
```

The username defaults to `opencode` but can be changed with `OPENCODE_SERVER_USERNAME`.

---

### [Using the Web Interface](#using-the-web-interface)

Once started, the web interface provides access to your OpenCode sessions.

#### [Sessions](#sessions)

View and manage your sessions from the homepage. You can see active sessions and start new ones.

![OpenCode Web - Active Session](/docs/_astro/web-homepage-active-session.BbK4Ph6e_Z1O7nO1.webp)

#### [Server Status](#server-status)

Click âSee Serversâ to view connected servers and their status.

![OpenCode Web - See Servers](/docs/_astro/web-homepage-see-servers.BpCOef2l_ZB0rJd.webp)

---

### [Attaching a Terminal](#attaching-a-terminal)

You can attach a terminal TUI to a running web server:

Terminal window

```

## Start the web server

opencode web --port 4096

## In another terminal, attach the TUI

opencode attach http://localhost:4096
```

This allows you to use both the web interface and terminal simultaneously, sharing the same sessions and state.

---

### [Config File](#config-file)

You can also configure server settings in your `opencode.json` config file:

```
{

"server": {

"port": 4096,

"hostname": "0.0.0.0",

"mdns": true,

"cors": ["https://example.com"]

}

}
```

Command line flags take precedence over config file settings.

[Edit page](https://github.com/anomalyco/opencode/edit/dev/packages/web/src/content/docs/web.mdx)[Found a bug? Open an issue](https://github.com/anomalyco/opencode/issues/new)[Join our Discord community](https://opencode.ai/discord)  Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

© [Anomaly](https://anoma.ly)

Last updated: Oct 13, 2026

---
<!--
URL: https://opencode.ai/docs/keybinds/
title: Keybinds | OpenCode
-->

[Skip to content](#_top)

[![](/docs/_astro/logo-dark.DOStV66V.svg) ![](/docs/_astro/logo-light.B0yzR0O5.svg)  OpenCode](/docs/)

[app.header.home](/)[app.header.docs](/v2/docs)

Search  `CtrlK`

Cancel

  [New OpenCode v2 is now available →](https://opencode.ai/v2)

* [Intro](/docs/)
* [Config](/docs/config/)
* [Providers](/docs/providers/)
* [Network](/docs/network/)
* [Enterprise](/docs/enterprise/)
* [Troubleshooting](/docs/troubleshooting/)
* [Windows](/docs/windows-wsl)
* Usage

  + [Go](https://opencode.ai/v2/docs/console/go/)
  + [TUI](/docs/tui/)
  + [CLI](/docs/cli/)
  + [Web](/docs/web/)
  + [IDE](/docs/ide/)
  + [Console](https://opencode.ai/v2/docs/console/)
  + [Share](/docs/share/)
  + [GitHub](/docs/github/)
  + [GitLab](/docs/gitlab/)
* Configure

  + [Tools](/docs/tools/)
  + [Rules](/docs/rules/)
  + [Agents](/docs/agents/)
  + [Models](/docs/models/)
  + [Themes](/docs/themes/)
  + [Keybinds](/docs/keybinds/)
  + [Commands](/docs/commands/)
  + [Formatters](/docs/formatters/)
  + [Permissions](/docs/permissions/)
  + [Policies](/docs/policies/)
  + [LSP Servers](/docs/lsp/)
  + [MCP servers](/docs/mcp-servers/)
  + [ACP Support](/docs/acp/)
  + [Agent Skills](/docs/skills/)
  + [References](/docs/references/)
  + [Custom Tools](/docs/custom-tools/)
* Develop

  + [SDK](/docs/sdk/)
  + [Server](/docs/server/)
  + [Plugins](/docs/plugins/)
  + [Ecosystem](/docs/ecosystem/)

[GitHub](https://github.com/anomalyco/opencode)[Discord](https://opencode.ai/discord)

  Select theme   DarkLightAuto         Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

On this page

* [Overview](#_top)
* [Leader Key](#leader-key)
* [Binding Values](#binding-values)
* [Disable Keybind](#disable-keybind)
* [Desktop Prompt Shortcuts](#desktop-prompt-shortcuts)
* [Shift+Enter](#shiftenter)
  + [Windows Terminal](#windows-terminal)

### On this page

* [Overview](#_top)
* [Leader Key](#leader-key)
* [Binding Values](#binding-values)
* [Disable Keybind](#disable-keybind)
* [Desktop Prompt Shortcuts](#desktop-prompt-shortcuts)
* [Shift+Enter](#shiftenter)
  + [Windows Terminal](#windows-terminal)

## Keybinds

Customize your keybinds.

OpenCode has a list of keybinds that you can customize through `tui.json`.

tui.json

```
{

"$schema": "https://opencode.ai/tui.json",

"leader_timeout": 2000,

"keybinds": {

"leader": "ctrl+x",

"app_exit": "ctrl+c,ctrl+d,<leader>q",

"app_debug": "none",

"app_console": "none",

"app_heap_snapshot": "none",

"app_toggle_animations": "none",

"app_toggle_file_context": "none",

"app_toggle_diffwrap": "none",

"app_toggle_paste_summary": "none",

"app_toggle_session_directory_filter": "none",

"command_list": "ctrl+p",

"help_show": "none",

"docs_open": "none",

"editor_open": "<leader>e",

"theme_list": "<leader>t",

"theme_switch_mode": "none",

"theme_mode_lock": "none",

"sidebar_toggle": "<leader>b",

"scrollbar_toggle": "none",

"status_view": "<leader>s",

"session_export": "<leader>x",

"session_copy": "none",

"session_move": "none",

"session_new": "<leader>n",

"session_list": "<leader>l",

"session_timeline": "<leader>g",

"session_fork": "none",

"session_rename": "ctrl+r",

"session_delete": "ctrl+d",

"session_share": "none",

"session_unshare": "none",

"session_interrupt": "escape",

"session_compact": "<leader>c",

"session_toggle_timestamps": "none",

"session_toggle_generic_tool_output": "none",

"session_child_first": "<leader>down",

"session_child_cycle": "right",

"session_child_cycle_reverse": "left",

"session_parent": "up",

"stash_delete": "ctrl+d",

"model_provider_list": "ctrl+a",

"model_favorite_toggle": "ctrl+f",

"model_list": "<leader>m",

"model_cycle_recent": "f2",

"model_cycle_recent_reverse": "shift+f2",

"model_cycle_favorite": "none",

"model_cycle_favorite_reverse": "none",

"mcp_list": "none",

"provider_connect": "none",

"console_org_switch": "none",

"agent_list": "<leader>a",

"agent_cycle": "tab",

"agent_cycle_reverse": "shift+tab",

"variant_cycle": "ctrl+t",

"variant_list": "none",

"messages_page_up": "pageup,ctrl+alt+b",

"messages_page_down": "pagedown,ctrl+alt+f",

"messages_line_up": "ctrl+alt+y",

"messages_line_down": "ctrl+alt+e",

"messages_half_page_up": "ctrl+alt+u",

"messages_half_page_down": "ctrl+alt+d",

"messages_first": "ctrl+g,home",

"messages_last": "ctrl+alt+g,end",

"messages_next": "none",

"messages_previous": "none",

"messages_last_user": "none",

"messages_copy": "<leader>y",

"messages_undo": "<leader>u",

"messages_redo": "<leader>r",

"messages_toggle_conceal": "<leader>h",

"tool_details": "none",

"display_thinking": "none",

"prompt_submit": "none",

"prompt_editor_context_clear": "none",

"prompt_skills": "none",

"prompt_stash": "none",

"prompt_stash_pop": "none",

"prompt_stash_list": "none",

"workspace_set": "none",

"input_clear": "ctrl+c",

"input_paste": {

"key": "ctrl+v",

"preventDefault": false

},

"input_submit": "return",

"input_newline": "shift+return,ctrl+return,alt+return,ctrl+j",

"input_move_left": "left,ctrl+b",

"input_move_right": "right,ctrl+f",

"input_move_up": "up",

"input_move_down": "down",

"input_select_left": "shift+left",

"input_select_right": "shift+right",

"input_select_up": "shift+up",

"input_select_down": "shift+down",

"input_line_home": "ctrl+a",

"input_line_end": "ctrl+e",

"input_select_line_home": "ctrl+shift+a",

"input_select_line_end": "ctrl+shift+e",

"input_visual_line_home": "alt+a",

"input_visual_line_end": "alt+e",

"input_select_visual_line_home": "alt+shift+a",

"input_select_visual_line_end": "alt+shift+e",

"input_buffer_home": "home",

"input_buffer_end": "end",

"input_select_buffer_home": "shift+home",

"input_select_buffer_end": "shift+end",

"input_delete_line": "ctrl+shift+d",

"input_delete_to_line_end": "ctrl+k",

"input_delete_to_line_start": "ctrl+u",

"input_backspace": "backspace,shift+backspace",

"input_delete": "ctrl+d,delete,shift+delete",

"input_undo": "ctrl+-,super+z",

"input_redo": "ctrl+.,super+shift+z",

"input_word_forward": "alt+f,alt+right,ctrl+right",

"input_word_backward": "alt+b,alt+left,ctrl+left",

"input_select_word_forward": "alt+shift+f,alt+shift+right",

"input_select_word_backward": "alt+shift+b,alt+shift+left",

"input_delete_word_forward": "alt+d,alt+delete,ctrl+delete",

"input_delete_word_backward": "ctrl+w,ctrl+backspace,alt+backspace",

"input_select_all": "super+a",

"history_previous": "up",

"history_next": "down",

"dialog.select.prev": "up,ctrl+p",

"dialog.select.next": "down,ctrl+n",

"dialog.select.page_up": "pageup",

"dialog.select.page_down": "pagedown",

"dialog.select.home": "home",

"dialog.select.end": "end",

"dialog.select.submit": "return",

"dialog.prompt.submit": "return",

"dialog.mcp.toggle": "space",

"prompt.autocomplete.prev": "up,ctrl+p",

"prompt.autocomplete.next": "down,ctrl+n",

"prompt.autocomplete.hide": "escape",

"prompt.autocomplete.select": "return",

"prompt.autocomplete.complete": "tab",

"permission.prompt.fullscreen": "ctrl+f",

"plugins.toggle": "space",

"dialog.plugins.install": "shift+i",

"terminal_suspend": "ctrl+z",

"terminal_title_toggle": "none",

"plugin_manager": "none",

"plugin_install": "none",

"which_key_toggle": "ctrl+alt+k",

"which_key_layout_toggle": "ctrl+alt+shift+k",

"which_key_pending_toggle": "ctrl+alt+shift+p",

"which_key_group_previous": "ctrl+alt+left,ctrl+alt+[",

"which_key_group_next": "ctrl+alt+right,ctrl+alt+]",

"which_key_scroll_up": "ctrl+alt+up,ctrl+alt+p",

"which_key_scroll_down": "ctrl+alt+down,ctrl+alt+n",

"which_key_page_up": "ctrl+alt+pageup",

"which_key_page_down": "ctrl+alt+pagedown",

"which_key_home": "ctrl+alt+home",

"which_key_end": "ctrl+alt+end"

}

}
```

Note

On Windows, the defaults for `input_undo` and `terminal_suspend` are different:

* `input_undo` defaults to `ctrl+z,ctrl+-,super+z` when it is not explicitly configured. The `ctrl+z` binding is added because Windows terminals do not support POSIX suspend.
* `terminal_suspend` is forced to `none` because native Windows terminals do not support POSIX suspend.

---

### [Leader Key](#leader-key)

OpenCode uses a `leader` key for many keybinds. This avoids conflicts in your terminal.

By default, `ctrl+x` is the leader key and many actions require you to first press the leader key and then the shortcut. For example, to start a new session you first press `ctrl+x` and then press `n`.

You donât need to use a leader key for your keybinds but we recommend doing so.

Some navigation keybinds intentionally do not use the leader key by default. For subagent sessions, the defaults are `session_child_first` = `<leader>down`, `session_child_cycle` = `right`, `session_child_cycle_reverse` = `left`, and `session_parent` = `up`.

`leader_timeout` controls how long OpenCode waits for the next key after the leader key. It defaults to `2000` milliseconds.

---

### [Binding Values](#binding-values)

A string can contain one shortcut or multiple comma-separated shortcuts. You can also use an array for multiple shortcuts.

For advanced cases, use an object with `key`, `event`, `preventDefault`, or `fallthrough`.

tui.json

```
{

"$schema": "https://opencode.ai/tui.json",

"keybinds": {

"messages_copy": ["<leader>y", "ctrl+shift+c"],

"input_paste": {

"key": "ctrl+v",

"preventDefault": false

}

}

}
```

---

### [Disable Keybind](#disable-keybind)

You can disable a keybind by adding the key to `tui.json` with a value of `"none"` or `false`.

tui.json

```
{

"$schema": "https://opencode.ai/tui.json",

"keybinds": {

"session_compact": "none"

}

}
```

---

### [Desktop Prompt Shortcuts](#desktop-prompt-shortcuts)

The OpenCode desktop app prompt input supports common Readline/Emacs-style shortcuts for editing text. These are built-in and currently not configurable via `opencode.json`.

| Shortcut | Action |
| --- | --- |
| `ctrl+a` | Move to start of current line |
| `ctrl+e` | Move to end of current line |
| `ctrl+b` | Move cursor back one character |
| `ctrl+f` | Move cursor forward one character |
| `alt+b` | Move cursor back one word |
| `alt+f` | Move cursor forward one word |
| `ctrl+d` | Delete character under cursor |
| `ctrl+k` | Kill to end of line |
| `ctrl+u` | Kill to start of line |
| `ctrl+w` | Kill previous word |
| `alt+d` | Kill next word |
| `ctrl+t` | Transpose characters |
| `ctrl+g` | Cancel popovers / abort running response |

---

### [Shift+Enter](#shiftenter)

Some terminals donât send modifier keys with Enter by default. You may need to configure your terminal to send `Shift+Enter` as an escape sequence.

#### [Windows Terminal](#windows-terminal)

Open your `settings.json` at:

```
%LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json
```

Add this to the root-level `actions` array:

```
"actions": [

{

"command": {

"action": "sendInput",

"input": "\u001b[13;2u"

},

"id": "User.sendInput.ShiftEnterCustom"

}

]
```

Add this to the root-level `keybindings` array:

```
"keybindings": [

{

"keys": "shift+enter",

"id": "User.sendInput.ShiftEnterCustom"

}

]
```

Save the file and restart Windows Terminal or open a new tab.

[Edit page](https://github.com/anomalyco/opencode/edit/dev/packages/web/src/content/docs/keybinds.mdx)[Found a bug? Open an issue](https://github.com/anomalyco/opencode/issues/new)[Join our Discord community](https://opencode.ai/discord)  Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

© [Anomaly](https://anoma.ly)

Last updated: Oct 13, 2026

---
<!--
URL: https://opencode.ai/docs/enterprise/
title: Enterprise | OpenCode
-->

[Skip to content](#_top)

[![](/docs/_astro/logo-dark.DOStV66V.svg) ![](/docs/_astro/logo-light.B0yzR0O5.svg)  OpenCode](/docs/)

[app.header.home](/)[app.header.docs](/v2/docs)

Search  `CtrlK`

Cancel

  [New OpenCode v2 is now available →](https://opencode.ai/v2)

* [Intro](/docs/)
* [Config](/docs/config/)
* [Providers](/docs/providers/)
* [Network](/docs/network/)
* [Enterprise](/docs/enterprise/)
* [Troubleshooting](/docs/troubleshooting/)
* [Windows](/docs/windows-wsl)
* Usage

  + [Go](https://opencode.ai/v2/docs/console/go/)
  + [TUI](/docs/tui/)
  + [CLI](/docs/cli/)
  + [Web](/docs/web/)
  + [IDE](/docs/ide/)
  + [Console](https://opencode.ai/v2/docs/console/)
  + [Share](/docs/share/)
  + [GitHub](/docs/github/)
  + [GitLab](/docs/gitlab/)
* Configure

  + [Tools](/docs/tools/)
  + [Rules](/docs/rules/)
  + [Agents](/docs/agents/)
  + [Models](/docs/models/)
  + [Themes](/docs/themes/)
  + [Keybinds](/docs/keybinds/)
  + [Commands](/docs/commands/)
  + [Formatters](/docs/formatters/)
  + [Permissions](/docs/permissions/)
  + [Policies](/docs/policies/)
  + [LSP Servers](/docs/lsp/)
  + [MCP servers](/docs/mcp-servers/)
  + [ACP Support](/docs/acp/)
  + [Agent Skills](/docs/skills/)
  + [References](/docs/references/)
  + [Custom Tools](/docs/custom-tools/)
* Develop

  + [SDK](/docs/sdk/)
  + [Server](/docs/server/)
  + [Plugins](/docs/plugins/)
  + [Ecosystem](/docs/ecosystem/)

[GitHub](https://github.com/anomalyco/opencode)[Discord](https://opencode.ai/discord)

  Select theme   DarkLightAuto         Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

On this page

* [Overview](#_top)
* [Trial](#trial)
  + [Data handling](#data-handling)
  + [Code ownership](#code-ownership)
* [Pricing](#pricing)
* [Deployment](#deployment)
  + [Central Config](#central-config)
  + [SSO integration](#sso-integration)
  + [Internal AI gateway](#internal-ai-gateway)
  + [Self-hosting](#self-hosting)
* [FAQ](#faq)

### On this page

* [Overview](#_top)
* [Trial](#trial)
  + [Data handling](#data-handling)
  + [Code ownership](#code-ownership)
* [Pricing](#pricing)
* [Deployment](#deployment)
  + [Central Config](#central-config)
  + [SSO integration](#sso-integration)
  + [Internal AI gateway](#internal-ai-gateway)
  + [Self-hosting](#self-hosting)
* [FAQ](#faq)

## Enterprise

Using OpenCode securely in your organization.

OpenCode Enterprise is for organizations that want to ensure that their code and data never leaves their infrastructure. It can do this by using a centralized config that integrates with your SSO and internal AI gateway.

Note

OpenCode does not store any of your code or context data.

To get started with OpenCode Enterprise:

1. Do a trial internally with your team.
2. **[Contact us](https://opencode.ai/enterprise)** to discuss pricing and implementation options.

---

### [Trial](#trial)

OpenCode is open source and does not store any of your code or context data, so your developers can simply [get started](/docs/) and carry out a trial.

---

#### [Data handling](#data-handling)

**OpenCode does not store your code or context data.** All processing happens locally or through direct API calls to your AI provider.

This means that as long as you are using a provider you trust, or an internal
AI gateway, you can use OpenCode securely.

The only caveat here is the optional `/share` feature.

---

##### [Sharing conversations](#sharing-conversations)

If a user enables the `/share` feature, the conversation and the data associated with it are sent to the service we use to host these share pages at opencode.ai.

The data is currently served through our CDNâs edge network, and is cached on the edge near your users.

We recommend you disable this for your trial.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"share": "disabled"

}
```

[Learn more about sharing](/docs/share).

---

#### [Code ownership](#code-ownership)

**You own all code produced by OpenCode.** There are no licensing restrictions or ownership claims.

---

### [Pricing](#pricing)

We use a per-seat model for OpenCode Enterprise. If you have your own LLM gateway, we do not charge for tokens used. For further details about pricing and implementation options, **[contact us](https://opencode.ai/enterprise)**.

---

### [Deployment](#deployment)

Once you have completed your trial and you are ready to use OpenCode at
your organization, you can **[contact us](https://opencode.ai/enterprise)** to discuss
pricing and implementation options.

---

#### [Central Config](#central-config)

We can set up OpenCode to use a single central config for your entire organization.

This centralized config can integrate with your SSO provider and ensures all users access only your internal AI gateway.

---

#### [SSO integration](#sso-integration)

Through the central config, OpenCode can integrate with your organizationâs SSO provider for authentication.

This allows OpenCode to obtain credentials for your internal AI gateway through your existing identity management system.

---

#### [Internal AI gateway](#internal-ai-gateway)

With the central config, OpenCode can also be configured to use only your internal AI gateway.

You can also disable all other AI providers, ensuring all requests go through your organizationâs approved infrastructure.

---

#### [Self-hosting](#self-hosting)

While we recommend disabling the share pages to ensure your data never leaves
your organization, we can also help you self-host them on your infrastructure.

This is currently on our roadmap. If youâre interested, **[let us know](https://opencode.ai/enterprise)**.

---

### [FAQ](#faq)

What is OpenCode Enterprise?

OpenCode Enterprise is for organizations that want to ensure that their code and data never leaves their infrastructure. It can do this by using a centralized config that integrates with your SSO and internal AI gateway.

How do I get started with OpenCode Enterprise?

Simply start with an internal trial with your team. OpenCode by default does not store your code or context data, making it easy to get started.

Then **[contact us](https://opencode.ai/enterprise)** to discuss pricing and implementation options.

How does enterprise pricing work?

We offer per-seat enterprise pricing. If you have your own LLM gateway, we do not charge for tokens used. For further details, **[contact us](https://opencode.ai/enterprise)** for a custom quote based on your organizationâs needs.

Is my data secure with OpenCode Enterprise?

Yes. OpenCode does not store your code or context data. All processing happens locally or through direct API calls to your AI provider. With central config and SSO integration, your data remains secure within your organizationâs infrastructure.

Can we use our own private NPM registry?

OpenCode supports private npm registries through Bunâs native `.npmrc` file support. If your organization uses a private registry, such as JFrog Artifactory, Nexus, or similar, ensure developers are authenticated before running OpenCode.

To set up authentication with your private registry:

Terminal window

```
npm login --registry=https://your-company.jfrog.io/api/npm/npm-virtual/
```

This creates `~/.npmrc` with authentication details. OpenCode will automatically
pick this up.

Caution

You must be logged into the private registry before running OpenCode.

Alternatively, you can manually configure a `.npmrc` file:

~/.npmrc

```
registry=https://your-company.jfrog.io/api/npm/npm-virtual/

//your-company.jfrog.io/api/npm/npm-virtual/:_authToken=${NPM_AUTH_TOKEN}
```

Developers must be logged into the private registry before running OpenCode to ensure packages can be installed from your enterprise registry.

[Edit page](https://github.com/anomalyco/opencode/edit/dev/packages/web/src/content/docs/enterprise.mdx)[Found a bug? Open an issue](https://github.com/anomalyco/opencode/issues/new)[Join our Discord community](https://opencode.ai/discord)  Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

© [Anomaly](https://anoma.ly)

Last updated: Oct 13, 2026

---
<!--
URL: https://opencode.ai/docs/lsp/
title: LSP Servers | OpenCode
-->

[Skip to content](#_top)

[![](/docs/_astro/logo-dark.DOStV66V.svg) ![](/docs/_astro/logo-light.B0yzR0O5.svg)  OpenCode](/docs/)

[app.header.home](/)[app.header.docs](/v2/docs)

Search  `CtrlK`

Cancel

  [New OpenCode v2 is now available →](https://opencode.ai/v2)

* [Intro](/docs/)
* [Config](/docs/config/)
* [Providers](/docs/providers/)
* [Network](/docs/network/)
* [Enterprise](/docs/enterprise/)
* [Troubleshooting](/docs/troubleshooting/)
* [Windows](/docs/windows-wsl)
* Usage

  + [Go](https://opencode.ai/v2/docs/console/go/)
  + [TUI](/docs/tui/)
  + [CLI](/docs/cli/)
  + [Web](/docs/web/)
  + [IDE](/docs/ide/)
  + [Console](https://opencode.ai/v2/docs/console/)
  + [Share](/docs/share/)
  + [GitHub](/docs/github/)
  + [GitLab](/docs/gitlab/)
* Configure

  + [Tools](/docs/tools/)
  + [Rules](/docs/rules/)
  + [Agents](/docs/agents/)
  + [Models](/docs/models/)
  + [Themes](/docs/themes/)
  + [Keybinds](/docs/keybinds/)
  + [Commands](/docs/commands/)
  + [Formatters](/docs/formatters/)
  + [Permissions](/docs/permissions/)
  + [Policies](/docs/policies/)
  + [LSP Servers](/docs/lsp/)
  + [MCP servers](/docs/mcp-servers/)
  + [ACP Support](/docs/acp/)
  + [Agent Skills](/docs/skills/)
  + [References](/docs/references/)
  + [Custom Tools](/docs/custom-tools/)
* Develop

  + [SDK](/docs/sdk/)
  + [Server](/docs/server/)
  + [Plugins](/docs/plugins/)
  + [Ecosystem](/docs/ecosystem/)

[GitHub](https://github.com/anomalyco/opencode)[Discord](https://opencode.ai/discord)

  Select theme   DarkLightAuto         Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

On this page

* [Overview](#_top)
* [Built-in](#built-in)
* [How It Works](#how-it-works)
* [Best Practices](#best-practices)
* [Configure](#configure)
  + [Environment variables](#environment-variables)
  + [Initialization options](#initialization-options)
  + [Disabling LSP servers](#disabling-lsp-servers)
  + [Custom LSP servers](#custom-lsp-servers)
* [Additional Information](#additional-information)
  + [PHP Intelephense](#php-intelephense)

### On this page

* [Overview](#_top)
* [Built-in](#built-in)
* [How It Works](#how-it-works)
* [Best Practices](#best-practices)
* [Configure](#configure)
  + [Environment variables](#environment-variables)
  + [Initialization options](#initialization-options)
  + [Disabling LSP servers](#disabling-lsp-servers)
  + [Custom LSP servers](#custom-lsp-servers)
* [Additional Information](#additional-information)
  + [PHP Intelephense](#php-intelephense)

## LSP Servers

OpenCode integrates with your LSP servers.

OpenCode can integrate with Language Server Protocol (LSP) servers to use diagnostics as feedback for the agent.

---

### [Built-in](#built-in)

OpenCode comes with several built-in LSP servers for popular languages:

| LSP Server | Extensions | Requirements |
| --- | --- | --- |
| astro | .astro | Auto-installs for Astro projects |
| bash | .sh, .bash, .zsh, .ksh | Auto-installs bash-language-server |
| clangd | .c, .cpp, .cc, .cxx, .c++, .h, .hpp, .hh, .hxx, .h++ | Auto-installs for C/C++ projects |
| csharp | .cs, .csx | `.NET SDK` installed |
| clojure-lsp | .clj, .cljs, .cljc, .edn | `clojure-lsp` command available |
| dart | .dart | `dart` command available |
| deno | .ts, .tsx, .js, .jsx, .mjs | `deno` command available (auto-detects deno.json/deno.jsonc) |
| elixir-ls | .ex, .exs | `elixir` command available |
| eslint | .ts, .tsx, .js, .jsx, .mjs, .cjs, .mts, .cts, .vue | `eslint` dependency in project |
| fsharp | .fs, .fsi, .fsx, .fsscript | `.NET SDK` installed |
| gleam | .gleam | `gleam` command available |
| gopls | .go | `go` command available |
| hls | .hs, .lhs | `haskell-language-server-wrapper` command available |
| jdtls | .java | `Java SDK (version 21+)` installed |
| julials | .jl | `julia` and `LanguageServer.jl` installed |
| kotlin-ls | .kt, .kts | Auto-installs for Kotlin projects |
| lua-ls | .lua | Auto-installs for Lua projects |
| nixd | .nix | `nixd` command available |
| ocaml-lsp | .ml, .mli | `ocamllsp` command available |
| oxlint | .ts, .tsx, .js, .jsx, .mjs, .cjs, .mts, .cts, .vue, .astro, .svelte | `oxlint` dependency in project |
| php intelephense | .php | Auto-installs for PHP projects |
| prisma | .prisma | `prisma` command available |
| pyright | .py, .pyi | `pyright` dependency installed |
| razor | .razor, .cshtml | `.NET SDK` and VS Code C# extension installed |
| ruby-lsp (rubocop) | .rb, .rake, .gemspec, .ru | `ruby` and `gem` commands available |
| rust | .rs | `rust-analyzer` command available |
| sourcekit-lsp | .swift, .objc, .objcpp | `swift` installed (`xcode` on macOS) |
| svelte | .svelte | Auto-installs for Svelte projects |
| terraform | .tf, .tfvars | Auto-installs from GitHub releases |
| tinymist | .typ, .typc | Auto-installs from GitHub releases |
| typescript | .ts, .tsx, .js, .jsx, .mjs, .cjs, .mts, .cts | `typescript` dependency in project |
| vue | .vue | Auto-installs for Vue projects |
| yaml-ls | .yaml, .yml | Auto-installs Red Hat yaml-language-server |
| zls | .zig, .zon | `zig` command available |

LSP is disabled by default. When enabled, servers start when one of the above file extensions is detected and the requirements are met.

Note

You can disable automatic LSP server downloads by setting the `OPENCODE_DISABLE_LSP_DOWNLOAD` environment variable to `true`.

---

### [How It Works](#how-it-works)

When LSP is enabled and opencode opens a file, it:

1. Checks the file extension against all enabled LSP servers.
2. Starts the appropriate LSP server if not already running.

---

### [Best Practices](#best-practices)

LSP can help the agent find and fix issues by providing diagnostics from language servers. This is useful in some projects, but it is not always a net positive.

Language servers can get out of sync, use significant memory, vary by version or project, and slow down agent workflows. In many projects it is better to have the agent run lint, typecheck, or other diagnostic CLI tools directly, so errors are fed back into the agent loop without those tradeoffs. Document those commands in instruction files such as `AGENTS.md` or skills so the agent knows what to run. Enable LSP when your project benefits from additional language-server feedback.

---

### [Configure](#configure)

You can enable and customize LSP servers through the `lsp` section in your opencode config.

To enable all built-in LSP servers, set `lsp` to `true`.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"lsp": true

}
```

Use an object to keep built-ins enabled while configuring overrides or custom servers.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"lsp": {}

}
```

Each configured LSP server entry supports the following:

Server entries need `command` unless they only disable a server.

| Property | Type | Description |
| --- | --- | --- |
| `disabled` | boolean | Set this to `true` to disable the LSP server |
| `command` | string[] | The command to start the LSP server |
| `extensions` | string[] | File extensions this LSP server should handle |
| `env` | object | Environment variables to set when starting server |
| `initialization` | object | Initialization options to send to the LSP server |

Letâs look at some examples.

---

#### [Environment variables](#environment-variables)

Use the `env` property to set environment variables when starting the LSP server:

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"lsp": {

"rust": {

"command": ["rust-analyzer"],

"env": {

"RUST_LOG": "debug"

}

}

}

}
```

---

#### [Initialization options](#initialization-options)

Use the `initialization` property to pass initialization options to the LSP server. These are server-specific settings sent during the LSP `initialize` request:

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"lsp": {

"custom-lsp": {

"command": ["custom-lsp-server", "--stdio"],

"extensions": [".custom"],

"initialization": {

"preferences": {

"importModuleSpecifierPreference": "relative"

}

}

}

}

}
```

Note

Initialization options vary by LSP server. Check your LSP serverâs documentation for available options.

---

#### [Disabling LSP servers](#disabling-lsp-servers)

If `lsp` is omitted, all LSP servers are disabled. To disable all LSP servers after another config enabled them, set `lsp` to `false`:

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"lsp": false

}
```

To disable a **specific** LSP server, set `disabled` to `true`:

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"lsp": {

"typescript": {

"disabled": true

}

}

}
```

---

#### [Custom LSP servers](#custom-lsp-servers)

You can add custom LSP servers by specifying the command and file extensions:

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"lsp": {

"custom-lsp": {

"command": ["custom-lsp-server", "--stdio"],

"extensions": [".custom"]

}

}

}
```

---

### [Additional Information](#additional-information)

#### [PHP Intelephense](#php-intelephense)

PHP Intelephense offers premium features through a license key. You can provide a license key by placing (only) the key in a text file at:

* On macOS/Linux: `$HOME/intelephense/license.txt`
* On Windows: `%USERPROFILE%/intelephense/license.txt`

The file should contain only the license key with no additional content.

[Edit page](https://github.com/anomalyco/opencode/edit/dev/packages/web/src/content/docs/lsp.mdx)[Found a bug? Open an issue](https://github.com/anomalyco/opencode/issues/new)[Join our Discord community](https://opencode.ai/discord)  Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

© [Anomaly](https://anoma.ly)

Last updated: Oct 13, 2026

---
<!--
URL: https://opencode.ai/docs/windows-wsl
title: Windows (WSL) | OpenCode
-->

[Skip to content](#_top)

[![](/docs/_astro/logo-dark.DOStV66V.svg) ![](/docs/_astro/logo-light.B0yzR0O5.svg)  OpenCode](/docs/)

[app.header.home](/)[app.header.docs](/v2/docs)

Search  `CtrlK`

Cancel

  [New OpenCode v2 is now available →](https://opencode.ai/v2)

* [Intro](/docs/)
* [Config](/docs/config/)
* [Providers](/docs/providers/)
* [Network](/docs/network/)
* [Enterprise](/docs/enterprise/)
* [Troubleshooting](/docs/troubleshooting/)
* [Windows](/docs/windows-wsl)
* Usage

  + [Go](https://opencode.ai/v2/docs/console/go/)
  + [TUI](/docs/tui/)
  + [CLI](/docs/cli/)
  + [Web](/docs/web/)
  + [IDE](/docs/ide/)
  + [Console](https://opencode.ai/v2/docs/console/)
  + [Share](/docs/share/)
  + [GitHub](/docs/github/)
  + [GitLab](/docs/gitlab/)
* Configure

  + [Tools](/docs/tools/)
  + [Rules](/docs/rules/)
  + [Agents](/docs/agents/)
  + [Models](/docs/models/)
  + [Themes](/docs/themes/)
  + [Keybinds](/docs/keybinds/)
  + [Commands](/docs/commands/)
  + [Formatters](/docs/formatters/)
  + [Permissions](/docs/permissions/)
  + [Policies](/docs/policies/)
  + [LSP Servers](/docs/lsp/)
  + [MCP servers](/docs/mcp-servers/)
  + [ACP Support](/docs/acp/)
  + [Agent Skills](/docs/skills/)
  + [References](/docs/references/)
  + [Custom Tools](/docs/custom-tools/)
* Develop

  + [SDK](/docs/sdk/)
  + [Server](/docs/server/)
  + [Plugins](/docs/plugins/)
  + [Ecosystem](/docs/ecosystem/)

[GitHub](https://github.com/anomalyco/opencode)[Discord](https://opencode.ai/discord)

  Select theme   DarkLightAuto         Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

On this page

* [Overview](#_top)
* [Setup](#setup)
* [Desktop App + WSL Server](#desktop-app--wsl-server)
* [Web Client + WSL](#web-client--wsl)
* [Accessing Windows Files](#accessing-windows-files)
* [Tips](#tips)

### On this page

* [Overview](#_top)
* [Setup](#setup)
* [Desktop App + WSL Server](#desktop-app--wsl-server)
* [Web Client + WSL](#web-client--wsl)
* [Accessing Windows Files](#accessing-windows-files)
* [Tips](#tips)

## Windows (WSL)

Run OpenCode on Windows using WSL for the best experience.

While OpenCode can run directly on Windows, we recommend using [Windows Subsystem for Linux (WSL)](https://learn.microsoft.com/en-us/windows/wsl/install) for the best experience. WSL provides a Linux environment that works seamlessly with OpenCodeâs features.

Why WSL?

WSL offers better file system performance, full terminal support, and compatibility with development tools that OpenCode relies on.

---

### [Setup](#setup)

1. **Install WSL**

   If you havenât already, [install WSL](https://learn.microsoft.com/en-us/windows/wsl/install) using the official Microsoft guide.
2. **Install OpenCode in WSL**

   Once WSL is set up, open your WSL terminal and install OpenCode using one of the [installation methods](/docs/).

   Terminal window

   ```
   curl -fsSL https://opencode.ai/install | bash
   ```
3. **Use OpenCode from WSL**

   Navigate to your project directory (access Windows files via `/mnt/c/`, `/mnt/d/`, etc.) and run OpenCode.

   Terminal window

   ```
   cd /mnt/c/Users/YourName/project

   opencode
   ```

---

### [Desktop App + WSL Server](#desktop-app--wsl-server)

If you prefer using the OpenCode Desktop app but want to run the server in WSL:

1. **Start the server in WSL** with `--hostname 0.0.0.0` to allow external connections:

   Terminal window

   ```
   opencode serve --hostname 0.0.0.0 --port 4096
   ```
2. **Connect the Desktop app** to `http://localhost:4096`

Note

If `localhost` does not work in your setup, connect using the WSL IP address instead (from WSL: `hostname -I`) and use `http://<wsl-ip>:4096`.

Caution

When using `--hostname 0.0.0.0`, set `OPENCODE_SERVER_PASSWORD` to secure the server.

Terminal window

```
OPENCODE_SERVER_PASSWORD=your-password opencode serve --hostname 0.0.0.0
```

---

### [Web Client + WSL](#web-client--wsl)

For the best web experience on Windows:

1. **Run `opencode web` in the WSL terminal** rather than PowerShell:

   Terminal window

   ```
   opencode web --hostname 0.0.0.0
   ```
2. **Access from your Windows browser** at `http://localhost:<port>` (OpenCode prints the URL)

Running `opencode web` from WSL ensures proper file system access and terminal integration while still being accessible from your Windows browser.

---

### [Accessing Windows Files](#accessing-windows-files)

WSL can access all your Windows files through the `/mnt/` directory:

* `C:` drive â `/mnt/c/`
* `D:` drive â `/mnt/d/`
* And so onâ¦

Example:

Terminal window

```
cd /mnt/c/Users/YourName/Documents/project

opencode
```

Tip

For the smoothest experience, consider cloning/copying your repo into the WSL filesystem (for example under `~/code/`) and running OpenCode there.

---

### [Tips](#tips)

* Keep OpenCode running in WSL for projects stored on Windows drives - file access is seamless
* Use VS Codeâs [WSL extension](https://code.visualstudio.com/docs/remote/wsl) alongside OpenCode for an integrated development workflow
* Your OpenCode config and sessions are stored within the WSL environment at `~/.local/share/opencode/`

[Edit page](https://github.com/anomalyco/opencode/edit/dev/packages/web/src/content/docs/windows-wsl.mdx)[Found a bug? Open an issue](https://github.com/anomalyco/opencode/issues/new)[Join our Discord community](https://opencode.ai/discord)  Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

© [Anomaly](https://anoma.ly)

Last updated: Oct 13, 2026

---
<!--
URL: https://opencode.ai/docs/models/
title: Models | OpenCode
-->

[Skip to content](#_top)

[![](/docs/_astro/logo-dark.DOStV66V.svg) ![](/docs/_astro/logo-light.B0yzR0O5.svg)  OpenCode](/docs/)

[app.header.home](/)[app.header.docs](/v2/docs)

Search  `CtrlK`

Cancel

  [New OpenCode v2 is now available →](https://opencode.ai/v2)

* [Intro](/docs/)
* [Config](/docs/config/)
* [Providers](/docs/providers/)
* [Network](/docs/network/)
* [Enterprise](/docs/enterprise/)
* [Troubleshooting](/docs/troubleshooting/)
* [Windows](/docs/windows-wsl)
* Usage

  + [Go](https://opencode.ai/v2/docs/console/go/)
  + [TUI](/docs/tui/)
  + [CLI](/docs/cli/)
  + [Web](/docs/web/)
  + [IDE](/docs/ide/)
  + [Console](https://opencode.ai/v2/docs/console/)
  + [Share](/docs/share/)
  + [GitHub](/docs/github/)
  + [GitLab](/docs/gitlab/)
* Configure

  + [Tools](/docs/tools/)
  + [Rules](/docs/rules/)
  + [Agents](/docs/agents/)
  + [Models](/docs/models/)
  + [Themes](/docs/themes/)
  + [Keybinds](/docs/keybinds/)
  + [Commands](/docs/commands/)
  + [Formatters](/docs/formatters/)
  + [Permissions](/docs/permissions/)
  + [Policies](/docs/policies/)
  + [LSP Servers](/docs/lsp/)
  + [MCP servers](/docs/mcp-servers/)
  + [ACP Support](/docs/acp/)
  + [Agent Skills](/docs/skills/)
  + [References](/docs/references/)
  + [Custom Tools](/docs/custom-tools/)
* Develop

  + [SDK](/docs/sdk/)
  + [Server](/docs/server/)
  + [Plugins](/docs/plugins/)
  + [Ecosystem](/docs/ecosystem/)

[GitHub](https://github.com/anomalyco/opencode)[Discord](https://opencode.ai/discord)

  Select theme   DarkLightAuto         Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

On this page

* [Overview](#_top)
* [Providers](#providers)
* [Select a model](#select-a-model)
* [Recommended models](#recommended-models)
* [Set a default](#set-a-default)
* [Configure models](#configure-models)
* [Variants](#variants)
  + [Built-in variants](#built-in-variants)
  + [Custom variants](#custom-variants)
  + [Cycle variants](#cycle-variants)
* [Loading models](#loading-models)

### On this page

* [Overview](#_top)
* [Providers](#providers)
* [Select a model](#select-a-model)
* [Recommended models](#recommended-models)
* [Set a default](#set-a-default)
* [Configure models](#configure-models)
* [Variants](#variants)
  + [Built-in variants](#built-in-variants)
  + [Custom variants](#custom-variants)
  + [Cycle variants](#cycle-variants)
* [Loading models](#loading-models)

## Models

Configuring an LLM provider and model.

OpenCode uses the [AI SDK](https://ai-sdk.dev/) and [Models.dev](https://models.dev) to support **75+ LLM providers** and it supports running local models.

---

### [Providers](#providers)

Most popular providers are preloaded by default. If youâve added the credentials for a provider through the `/connect` command, theyâll be available when you start OpenCode.

Learn more about [providers](/docs/providers).

---

### [Select a model](#select-a-model)

Once youâve configured your provider you can select the model you want by typing in:

```
/models
```

---

### [Recommended models](#recommended-models)

There are a lot of models out there, with new models coming out every week.

Tip

Consider using one of the models we recommend.

However, there are only a few of them that are good at both generating code and tool calling.

Here are several models that work well with OpenCode, in no particular order. (This is not an exhaustive list nor is it necessarily up to date):

* GPT 5.2
* GPT 5.1 Codex
* Claude Opus 4.5
* Claude Sonnet 4.5
* Minimax M2.1
* Gemini 3 Pro

---

### [Set a default](#set-a-default)

To set one of these as the default model, you can set the `model` key in your
OpenCode config.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"model": "lmstudio/google/gemma-3n-e4b"

}
```

Here the full ID is `provider_id/model_id`. For example, if youâre using [OpenCode Zen](https://opencode.ai/v2/docs/console/), you would use `opencode/gpt-5.1-codex` for GPT 5.1 Codex.

If youâve configured a [custom provider](/docs/providers#custom), the `provider_id` is key from the `provider` part of your config, and the `model_id` is the key from `provider.models`.

---

### [Configure models](#configure-models)

You can globally configure a modelâs options through the config.

opencode.jsonc

```
{

"$schema": "https://opencode.ai/config.json",

"provider": {

"openai": {

"models": {

"gpt-5": {

"options": {

"reasoningEffort": "high",

"textVerbosity": "low",

"reasoningSummary": "auto",

"include": ["reasoning.encrypted_content"],

},

},

},

},

"anthropic": {

"models": {

"claude-sonnet-4-5-20250929": {

"options": {

"thinking": {

"type": "enabled",

"budgetTokens": 16000,

},

},

},

},

},

},

}
```

Here weâre configuring global settings for two built-in models: `gpt-5` when accessed via the `openai` provider, and `claude-sonnet-4-20250514` when accessed via the `anthropic` provider.
The built-in provider and model names can be found on [Models.dev](https://models.dev).

You can also configure these options for any agents that you are using. The agent config overrides any global options here. [Learn more](/docs/agents/#additional).

You can also define custom variants that extend built-in ones. Variants let you configure different settings for the same model without creating duplicate entries:

opencode.jsonc

```
{

"$schema": "https://opencode.ai/config.json",

"provider": {

"opencode": {

"models": {

"gpt-5": {

"variants": {

"high": {

"reasoningEffort": "high",

"textVerbosity": "low",

"reasoningSummary": "auto",

},

"low": {

"reasoningEffort": "low",

"textVerbosity": "low",

"reasoningSummary": "auto",

},

},

},

},

},

},

}
```

---

### [Variants](#variants)

Many models support multiple variants with different configurations. OpenCode ships with built-in default variants for popular providers.

#### [Built-in variants](#built-in-variants)

OpenCode ships with default variants for many providers:

**Anthropic**:

* `high` - High thinking budget (default)
* `max` - Maximum thinking budget

**OpenAI**:

Varies by model but roughly:

* `none` - No reasoning
* `minimal` - Minimal reasoning effort
* `low` - Low reasoning effort
* `medium` - Medium reasoning effort
* `high` - High reasoning effort
* `xhigh` - Extra high reasoning effort

**Google**:

* `low` - Lower effort/token budget
* `high` - Higher effort/token budget

Tip

This list is not comprehensive. Many other providers have built-in defaults too.

#### [Custom variants](#custom-variants)

You can override existing variants or add your own:

opencode.jsonc

```
{

"$schema": "https://opencode.ai/config.json",

"provider": {

"openai": {

"models": {

"gpt-5": {

"variants": {

"thinking": {

"reasoningEffort": "high",

"textVerbosity": "low",

},

"fast": {

"disabled": true,

},

},

},

},

},

},

}
```

#### [Cycle variants](#cycle-variants)

Use the keybind `variant_cycle` to quickly switch between variants. [Learn more](/docs/keybinds).

---

### [Loading models](#loading-models)

When OpenCode starts up, it checks for models in the following priority order:

1. The `--model` or `-m` command line flag. The format is the same as in the config file: `provider_id/model_id`.
2. The model list in the OpenCode config.

   opencode.json

   ```
   {

   "$schema": "https://opencode.ai/config.json",

   "model": "anthropic/claude-sonnet-4-20250514"

   }
   ```

   The format here is `provider/model`.
3. The last used model.
4. The first model using an internal priority.

[Edit page](https://github.com/anomalyco/opencode/edit/dev/packages/web/src/content/docs/models.mdx)[Found a bug? Open an issue](https://github.com/anomalyco/opencode/issues/new)[Join our Discord community](https://opencode.ai/discord)  Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

© [Anomaly](https://anoma.ly)

Last updated: Oct 13, 2026

---
<!--
URL: https://opencode.ai/docs/cli/
title: CLI | OpenCode
-->

[Skip to content](#_top)

[![](/docs/_astro/logo-dark.DOStV66V.svg) ![](/docs/_astro/logo-light.B0yzR0O5.svg)  OpenCode](/docs/)

[app.header.home](/)[app.header.docs](/v2/docs)

Search  `CtrlK`

Cancel

  [New OpenCode v2 is now available →](https://opencode.ai/v2)

* [Intro](/docs/)
* [Config](/docs/config/)
* [Providers](/docs/providers/)
* [Network](/docs/network/)
* [Enterprise](/docs/enterprise/)
* [Troubleshooting](/docs/troubleshooting/)
* [Windows](/docs/windows-wsl)
* Usage

  + [Go](https://opencode.ai/v2/docs/console/go/)
  + [TUI](/docs/tui/)
  + [CLI](/docs/cli/)
  + [Web](/docs/web/)
  + [IDE](/docs/ide/)
  + [Console](https://opencode.ai/v2/docs/console/)
  + [Share](/docs/share/)
  + [GitHub](/docs/github/)
  + [GitLab](/docs/gitlab/)
* Configure

  + [Tools](/docs/tools/)
  + [Rules](/docs/rules/)
  + [Agents](/docs/agents/)
  + [Models](/docs/models/)
  + [Themes](/docs/themes/)
  + [Keybinds](/docs/keybinds/)
  + [Commands](/docs/commands/)
  + [Formatters](/docs/formatters/)
  + [Permissions](/docs/permissions/)
  + [Policies](/docs/policies/)
  + [LSP Servers](/docs/lsp/)
  + [MCP servers](/docs/mcp-servers/)
  + [ACP Support](/docs/acp/)
  + [Agent Skills](/docs/skills/)
  + [References](/docs/references/)
  + [Custom Tools](/docs/custom-tools/)
* Develop

  + [SDK](/docs/sdk/)
  + [Server](/docs/server/)
  + [Plugins](/docs/plugins/)
  + [Ecosystem](/docs/ecosystem/)

[GitHub](https://github.com/anomalyco/opencode)[Discord](https://opencode.ai/discord)

  Select theme   DarkLightAuto         Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

On this page

* [Overview](#_top)
  + [tui](#tui)
* [Commands](#commands)
  + [agent](#agent)
  + [attach](#attach)
  + [auth](#auth)
  + [github](#github)
  + [mcp](#mcp)
  + [models](#models)
  + [run](#run-1)
  + [serve](#serve)
  + [session](#session)
  + [stats](#stats)
  + [export](#export)
  + [import](#import)
  + [web](#web)
  + [acp](#acp)
  + [plugin](#plugin)
  + [pr](#pr)
  + [db](#db)
  + [debug](#debug-1)
  + [uninstall](#uninstall)
  + [upgrade](#upgrade)
* [Global Flags](#global-flags)
* [Environment variables](#environment-variables)
  + [Experimental](#experimental)

### On this page

* [Overview](#_top)
  + [tui](#tui)
* [Commands](#commands)
  + [agent](#agent)
  + [attach](#attach)
  + [auth](#auth)
  + [github](#github)
  + [mcp](#mcp)
  + [models](#models)
  + [run](#run-1)
  + [serve](#serve)
  + [session](#session)
  + [stats](#stats)
  + [export](#export)
  + [import](#import)
  + [web](#web)
  + [acp](#acp)
  + [plugin](#plugin)
  + [pr](#pr)
  + [db](#db)
  + [debug](#debug-1)
  + [uninstall](#uninstall)
  + [upgrade](#upgrade)
* [Global Flags](#global-flags)
* [Environment variables](#environment-variables)
  + [Experimental](#experimental)

## CLI

OpenCode CLI options and commands.

The OpenCode CLI by default starts the [TUI](/docs/tui) when run without any arguments.

Terminal window

```
opencode
```

But it also accepts commands as documented on this page. This allows you to interact with OpenCode programmatically.

Terminal window

```
opencode run "Explain how closures work in JavaScript"
```

---

#### [tui](#tui)

Start the OpenCode terminal user interface.

Terminal window

```
opencode [project]
```

##### [Flags](#flags)

| Flag | Short | Description |
| --- | --- | --- |
| `--continue` | `-c` | Continue the last session |
| `--session` | `-s` | Session ID to continue |
| `--fork` |  | Fork the session when continuing (use with `--continue` or `--session`) |
| `--prompt` |  | Prompt to use |
| `--model` | `-m` | Model to use in the form of provider/model |
| `--agent` |  | Agent to use |
| `--auto` |  | Auto-approve permissions that are not explicitly denied |
| `--port` |  | Port to listen on |
| `--hostname` |  | Hostname to listen on |
| `--mdns` |  | Enable mDNS discovery |
| `--mdns-domain` |  | Custom mDNS domain name |
| `--cors` |  | Additional browser origin(s) to allow CORS |

---

### [Commands](#commands)

The OpenCode CLI also has the following commands.

---

#### [agent](#agent)

Manage agents for OpenCode.

Terminal window

```
opencode agent [command]
```

---

##### [create](#create)

Create a new agent with custom configuration.

Terminal window

```
opencode agent create
```

This command will guide you through creating a new agent with a custom system prompt and permission configuration. Anything you donât allow is denied in the generated agentâs frontmatter.

##### [Flags](#flags-1)

| Flag | Short | Description |
| --- | --- | --- |
| `--path` |  | Directory to write the agent file to (defaults to global or `.opencode/agent` based on the prompt) |
| `--description` |  | What the agent should do |
| `--mode` |  | Agent mode: `all`, `primary`, or `subagent` |
| `--permissions` |  | Comma-separated list of permissions to allow (default: all). Available: `bash`, `read`, `edit`, `glob`, `grep`, `webfetch`, `task`, `websearch`, `lsp`, `skill`. Anything omitted is denied. Alias: `--tools` |
| `--model` | `-m` | Model to use, in `provider/model` format |

Passing all of `--path`, `--description`, `--mode`, and `--permissions` runs the command non-interactively.

---

##### [list](#list)

List all available agents.

Terminal window

```
opencode agent list
```

---

#### [attach](#attach)

Attach a terminal to an already running OpenCode backend server started via `serve` or `web` commands.

Terminal window

```
opencode attach [url]
```

This allows using the TUI with a remote OpenCode backend. For example:

Terminal window

```

## Start the backend server for web/mobile access

opencode web --port 4096 --hostname 0.0.0.0

## In another terminal, attach the TUI to the running backend

opencode attach http://10.20.30.40:4096
```

##### [Flags](#flags-2)

| Flag | Short | Description |
| --- | --- | --- |
| `--dir` |  | Working directory to start TUI in |
| `--continue` | `-c` | Continue the last session |
| `--session` | `-s` | Session ID to continue |
| `--fork` |  | Fork the session when continuing (use with `--continue` or `--session`) |
| `--password` | `-p` | Basic auth password (defaults to `OPENCODE_SERVER_PASSWORD`) |
| `--username` | `-u` | Basic auth username (defaults to `OPENCODE_SERVER_USERNAME` or `opencode`) |

---

#### [auth](#auth)

Command to manage credentials and login for providers.

Terminal window

```
opencode auth [command]
```

---

##### [login](#login)

OpenCode is powered by the provider list at [Models.dev](https://models.dev), so you can use `opencode auth login` to configure API keys for any provider youâd like to use. This is stored in `~/.local/share/opencode/auth.json`.

Terminal window

```
opencode auth login
```

When OpenCode starts up it loads the providers from the credentials file. And if there are any keys defined in your environments or a `.env` file in your project.

###### [Flags](#flags-3)

| Flag | Short | Description |
| --- | --- | --- |
| `--provider` | `-p` | Provider ID or name to log in to |
| `--method` | `-m` | Login method label to use, skipping method selection |

---

##### [list](#list-1)

Lists all the authenticated providers as stored in the credentials file.

Terminal window

```
opencode auth list
```

Or the short version.

Terminal window

```
opencode auth ls
```

---

##### [logout](#logout)

Logs you out of a provider by clearing it from the credentials file.

Terminal window

```
opencode auth logout
```

---

#### [github](#github)

Manage the GitHub agent for repository automation.

Terminal window

```
opencode github [command]
```

---

##### [install](#install)

Install the GitHub agent in your repository.

Terminal window

```
opencode github install
```

This sets up the necessary GitHub Actions workflow and guides you through the configuration process. [Learn more](/docs/github).

---

##### [run](#run)

Run the GitHub agent. This is typically used in GitHub Actions.

Terminal window

```
opencode github run
```

###### [Flags](#flags-4)

| Flag | Description |
| --- | --- |
| `--event` | GitHub mock event to run the agent for |
| `--token` | GitHub personal access token |

---

#### [mcp](#mcp)

Manage Model Context Protocol servers.

Terminal window

```
opencode mcp [command]
```

---

##### [add](#add)

Add an MCP server to your configuration.

Terminal window

```
opencode mcp add
```

This command will guide you through adding either a local or remote MCP server.

---

##### [list](#list-2)

List all configured MCP servers and their connection status.

Terminal window

```
opencode mcp list
```

Or use the short version.

Terminal window

```
opencode mcp ls
```

---

##### [auth](#auth-1)

Authenticate with an OAuth-enabled MCP server.

Terminal window

```
opencode mcp auth [name]
```

If you donât provide a server name, youâll be prompted to select from available OAuth-capable servers.

You can also list OAuth-capable servers and their authentication status.

Terminal window

```
opencode mcp auth list
```

Or use the short version.

Terminal window

```
opencode mcp auth ls
```

---

##### [logout](#logout-1)

Remove OAuth credentials for an MCP server.

Terminal window

```
opencode mcp logout [name]
```

---

##### [debug](#debug)

Debug OAuth connection issues for an MCP server.

Terminal window

```
opencode mcp debug <name>
```

---

#### [models](#models)

List all available models from configured providers.

Terminal window

```
opencode models [provider]
```

This command displays all models available across your configured providers in the format `provider/model`.

This is useful for figuring out the exact model name to use in [your config](/docs/config/).

You can optionally pass a provider ID to filter models by that provider.

Terminal window

```
opencode models anthropic
```

##### [Flags](#flags-5)

| Flag | Description |
| --- | --- |
| `--refresh` | Refresh the models cache from models.dev |
| `--verbose` | Use more verbose model output (includes metadata like costs) |

Use the `--refresh` flag to update the cached model list. This is useful when new models have been added to a provider and you want to see them in OpenCode.

Terminal window

```
opencode models --refresh
```

---

#### [run](#run-1)

Run opencode in non-interactive mode by passing a prompt directly.

Terminal window

```
opencode run [message..]
```

This is useful for scripting, automation, or when you want a quick answer without launching the full TUI. For example.

Terminal window

```
opencode run Explain the use of context in Go
```

You can also attach to a running `opencode serve` instance to avoid MCP server cold boot times on every run:

Terminal window

```

## Start a headless server in one terminal

opencode serve

## In another terminal, run commands that attach to it

opencode run --attach http://localhost:4096 "Explain async/await in JavaScript"
```

##### [Flags](#flags-6)

| Flag | Short | Description |
| --- | --- | --- |
| `--command` |  | The command to run, use message for args |
| `--continue` | `-c` | Continue the last session |
| `--session` | `-s` | Session ID to continue |
| `--fork` |  | Fork the session when continuing (use with `--continue` or `--session`) |
| `--share` |  | Share the session |
| `--model` | `-m` | Model to use in the form of provider/model |
| `--agent` |  | Agent to use |
| `--file` | `-f` | File(s) to attach to message |
| `--format` |  | Format: default (formatted) or json (raw JSON events) |
| `--title` |  | Title for the session (uses truncated prompt if no value provided) |
| `--attach` |  | Attach to a running opencode server (e.g., <http://localhost:4096>) |
| `--password` | `-p` | Basic auth password (defaults to `OPENCODE_SERVER_PASSWORD`) |
| `--username` | `-u` | Basic auth username (defaults to `OPENCODE_SERVER_USERNAME` or `opencode`) |
| `--dir` |  | Directory to run in, or path on the remote server when attaching |
| `--port` |  | Port for the local server (defaults to random port) |
| `--variant` |  | Model variant (provider-specific reasoning effort) |
| `--thinking` |  | Show thinking blocks |
| `--auto` |  | Auto-approve permissions that are not explicitly denied |

---

#### [serve](#serve)

Start a headless OpenCode server for API access. Check out the [server docs](/docs/server) for the full HTTP interface.

Terminal window

```
opencode serve
```

This starts an HTTP server that provides API access to opencode functionality without the TUI interface. Set `OPENCODE_SERVER_PASSWORD` to enable HTTP basic auth (username defaults to `opencode`).

##### [Flags](#flags-7)

| Flag | Description |
| --- | --- |
| `--port` | Port to listen on |
| `--hostname` | Hostname to listen on |
| `--mdns` | Enable mDNS discovery |
| `--mdns-domain` | Custom mDNS domain name |
| `--cors` | Additional browser origin(s) to allow CORS |

---

#### [session](#session)

Manage OpenCode sessions.

Terminal window

```
opencode session [command]
```

---

##### [list](#list-3)

List all OpenCode sessions.

Terminal window

```
opencode session list
```

###### [Flags](#flags-8)

| Flag | Short | Description |
| --- | --- | --- |
| `--max-count` | `-n` | Limit to N most recent sessions |
| `--format` |  | Output format: table or json (table) |

---

##### [delete](#delete)

Delete an OpenCode session.

Terminal window

```
opencode session delete <sessionID>
```

---

#### [stats](#stats)

Show token usage and cost statistics for your OpenCode sessions.

Terminal window

```
opencode stats
```

##### [Flags](#flags-9)

| Flag | Description |
| --- | --- |
| `--days` | Show stats for the last N days (all time) |
| `--tools` | Number of tools to show (all) |
| `--models` | Show model usage breakdown (hidden by default). Pass a number to show top N |
| `--project` | Filter by project (all projects, empty string: current project) |

---

#### [export](#export)

Export session data as JSON.

Terminal window

```
opencode export [sessionID]
```

If you donât provide a session ID, youâll be prompted to select from available sessions.

##### [Flags](#flags-10)

| Flag | Description |
| --- | --- |
| `--sanitize` | Redact sensitive transcript/file data |

---

#### [import](#import)

Import session data from a JSON file or OpenCode share URL.

Terminal window

```
opencode import <file>
```

You can import from a local file or an OpenCode share URL.

Terminal window

```
opencode import session.json

opencode import https://opncd.ai/s/abc123
```

---

#### [web](#web)

Start a headless OpenCode server with a web interface.

Terminal window

```
opencode web
```

This starts an HTTP server and opens a web browser to access OpenCode through a web interface. Set `OPENCODE_SERVER_PASSWORD` to enable HTTP basic auth (username defaults to `opencode`).

##### [Flags](#flags-11)

| Flag | Description |
| --- | --- |
| `--port` | Port to listen on |
| `--hostname` | Hostname to listen on |
| `--mdns` | Enable mDNS discovery |
| `--mdns-domain` | Custom mDNS domain name |
| `--cors` | Additional browser origin(s) to allow CORS |

---

#### [acp](#acp)

Start an ACP (Agent Client Protocol) server.

Terminal window

```
opencode acp
```

This command starts an ACP server that communicates via stdin/stdout using nd-JSON.

##### [Flags](#flags-12)

| Flag | Description |
| --- | --- |
| `--cwd` | Working directory |
| `--port` | Port to listen on |
| `--hostname` | Hostname to listen on |
| `--mdns` | Enable mDNS discovery |
| `--mdns-domain` | Custom mDNS domain name |
| `--cors` | Additional browser origin(s) to allow CORS |

---

#### [plugin](#plugin)

Install a plugin and update your config.

Terminal window

```
opencode plugin <module>
```

Or use the alias.

Terminal window

```
opencode plug <module>
```

##### [Flags](#flags-13)

| Flag | Short | Description |
| --- | --- | --- |
| `--global` | `-g` | Install in global config |
| `--force` | `-f` | Replace existing plugin version |

---

#### [pr](#pr)

Fetch and checkout a GitHub PR branch, then run OpenCode.

Terminal window

```
opencode pr <number>
```

---

#### [db](#db)

Database tools.

Terminal window

```
opencode db [query]
```

##### [Flags](#flags-14)

| Flag | Description |
| --- | --- |
| `--format` | Output format: `json` or `tsv` |

---

##### [path](#path)

Print the database path.

Terminal window

```
opencode db path
```

---

#### [debug](#debug-1)

Debugging and troubleshooting tools.

Terminal window

```
opencode debug [command]
```

---

#### [uninstall](#uninstall)

Uninstall OpenCode and remove all related files.

Terminal window

```
opencode uninstall
```

##### [Flags](#flags-15)

| Flag | Short | Description |
| --- | --- | --- |
| `--keep-config` | `-c` | Keep configuration files |
| `--keep-data` | `-d` | Keep session data and snapshots |
| `--dry-run` |  | Show what would be removed without removing |
| `--force` | `-f` | Skip confirmation prompts |

---

#### [upgrade](#upgrade)

Updates opencode to the latest version or a specific version.

Terminal window

```
opencode upgrade [target]
```

To upgrade to the latest version.

Terminal window

```
opencode upgrade
```

To upgrade to a specific version.

Terminal window

```
opencode upgrade v0.1.48
```

##### [Flags](#flags-16)

| Flag | Short | Description |
| --- | --- | --- |
| `--method` | `-m` | The installation method that was used; curl, npm, pnpm, bun, brew |

---

### [Global Flags](#global-flags)

The opencode CLI takes the following global flags.

| Flag | Short | Description |
| --- | --- | --- |
| `--help` | `-h` | Display help |
| `--version` | `-v` | Print version number |
| `--print-logs` |  | Print logs to stderr |
| `--log-level` |  | Log level (DEBUG, INFO, WARN, ERROR) |
| `--pure` |  | Run without external plugins |

---

### [Environment variables](#environment-variables)

OpenCode can be configured using environment variables.

| Variable | Type | Description |
| --- | --- | --- |
| `OPENCODE_AUTO_SHARE` | boolean | Automatically share sessions |
| `OPENCODE_GIT_BASH_PATH` | string | Path to Git Bash executable on Windows |
| `OPENCODE_CONFIG` | string | Path to config file |
| `OPENCODE_TUI_CONFIG` | string | Path to TUI config file |
| `OPENCODE_CONFIG_DIR` | string | Path to config directory |
| `OPENCODE_CONFIG_CONTENT` | string | Inline json config content |
| `OPENCODE_DISABLE_AUTOUPDATE` | boolean | Disable automatic update checks |
| `OPENCODE_DISABLE_PRUNE` | boolean | Disable pruning of old data |
| `OPENCODE_DISABLE_TERMINAL_TITLE` | boolean | Disable automatic terminal title updates |
| `OPENCODE_PERMISSION` | string | Inlined json permissions config |
| `OPENCODE_DISABLE_DEFAULT_PLUGINS` | boolean | Disable default plugins |
| `OPENCODE_DISABLE_LSP_DOWNLOAD` | boolean | Disable automatic LSP server downloads |
| `OPENCODE_ENABLE_EXPERIMENTAL_MODELS` | boolean | Enable experimental models |
| `OPENCODE_DISABLE_AUTOCOMPACT` | boolean | Disable automatic context compaction |
| `OPENCODE_DISABLE_CLAUDE_CODE` | boolean | Disable reading from `.claude` (prompt + skills) |
| `OPENCODE_DISABLE_CLAUDE_CODE_PROMPT` | boolean | Disable reading `~/.claude/CLAUDE.md` |
| `OPENCODE_DISABLE_CLAUDE_CODE_SKILLS` | boolean | Disable loading `.claude/skills` |
| `OPENCODE_DISABLE_MODELS_FETCH` | boolean | Disable fetching models from remote sources |
| `OPENCODE_DISABLE_MOUSE` | boolean | Disable mouse capture in the TUI |
| `OPENCODE_FAKE_VCS` | string | Fake VCS provider for testing purposes |
| `OPENCODE_CLIENT` | string | Client identifier (defaults to `cli`) |
| `OPENCODE_ENABLE_EXA` | boolean | Enable Exa web search tools |
| `OPENCODE_ENABLE_PARALLEL` | boolean | Enable Parallel web search tools |
| `OPENCODE_SERVER_PASSWORD` | string | Enable basic auth for `serve`/`web` |
| `OPENCODE_SERVER_USERNAME` | string | Override basic auth username (default `opencode`) |
| `OPENCODE_MODELS_URL` | string | Custom URL for fetching models configuration |

---

#### [Experimental](#experimental)

These environment variables enable experimental features that may change or be removed.

| Variable | Type | Description |
| --- | --- | --- |
| `OPENCODE_EXPERIMENTAL` | boolean | Enable the experimental umbrella flag |
| `OPENCODE_EXPERIMENTAL_ICON_DISCOVERY` | boolean | Enable icon discovery |
| `OPENCODE_EXPERIMENTAL_DISABLE_COPY_ON_SELECT` | boolean | Disable copy on select in TUI |
| `OPENCODE_EXPERIMENTAL_BASH_DEFAULT_TIMEOUT_MS` | number | Default timeout for bash commands in ms |
| `OPENCODE_EXPERIMENTAL_OUTPUT_TOKEN_MAX` | number | Max output tokens for LLM responses |
| `OPENCODE_EXPERIMENTAL_FILEWATCHER` | boolean | Enable file watcher for entire dir |
| `OPENCODE_EXPERIMENTAL_OXFMT` | boolean | Enable oxfmt formatter |
| `OPENCODE_EXPERIMENTAL_LSP_TOOL` | boolean | Enable experimental LSP tool |
| `OPENCODE_EXPERIMENTAL_DISABLE_FILEWATCHER` | boolean | Disable file watcher |
| `OPENCODE_EXPERIMENTAL_EXA` | boolean | Enable experimental Exa features |
| `OPENCODE_EXPERIMENTAL_LSP_TY` | boolean | Enable TY LSP for python files |
| `OPENCODE_EXPERIMENTAL_PLAN_MODE` | boolean | Enable plan mode |
| `OPENCODE_EXPERIMENTAL_EVENT_SYSTEM` | boolean | Enable experimental event system |
| `OPENCODE_EXPERIMENTAL_NATIVE_LLM` | boolean | Enable native LLM request path |
| `OPENCODE_EXPERIMENTAL_PARALLEL` | boolean | Enable parallel web search execution |
| `OPENCODE_EXPERIMENTAL_SCOUT` | boolean | Enable Scout subagent |
| `OPENCODE_EXPERIMENTAL_WORKSPACES` | boolean | Enable workspace support |

[Edit page](https://github.com/anomalyco/opencode/edit/dev/packages/web/src/content/docs/cli.mdx)[Found a bug? Open an issue](https://github.com/anomalyco/opencode/issues/new)[Join our Discord community](https://opencode.ai/discord)  Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

© [Anomaly](https://anoma.ly)

Last updated: Oct 13, 2026

---
<!--
URL: https://opencode.ai/docs/share/
title: Share | OpenCode
-->

[Skip to content](#_top)

[![](/docs/_astro/logo-dark.DOStV66V.svg) ![](/docs/_astro/logo-light.B0yzR0O5.svg)  OpenCode](/docs/)

[app.header.home](/)[app.header.docs](/v2/docs)

Search  `CtrlK`

Cancel

  [New OpenCode v2 is now available →](https://opencode.ai/v2)

* [Intro](/docs/)
* [Config](/docs/config/)
* [Providers](/docs/providers/)
* [Network](/docs/network/)
* [Enterprise](/docs/enterprise/)
* [Troubleshooting](/docs/troubleshooting/)
* [Windows](/docs/windows-wsl)
* Usage

  + [Go](https://opencode.ai/v2/docs/console/go/)
  + [TUI](/docs/tui/)
  + [CLI](/docs/cli/)
  + [Web](/docs/web/)
  + [IDE](/docs/ide/)
  + [Console](https://opencode.ai/v2/docs/console/)
  + [Share](/docs/share/)
  + [GitHub](/docs/github/)
  + [GitLab](/docs/gitlab/)
* Configure

  + [Tools](/docs/tools/)
  + [Rules](/docs/rules/)
  + [Agents](/docs/agents/)
  + [Models](/docs/models/)
  + [Themes](/docs/themes/)
  + [Keybinds](/docs/keybinds/)
  + [Commands](/docs/commands/)
  + [Formatters](/docs/formatters/)
  + [Permissions](/docs/permissions/)
  + [Policies](/docs/policies/)
  + [LSP Servers](/docs/lsp/)
  + [MCP servers](/docs/mcp-servers/)
  + [ACP Support](/docs/acp/)
  + [Agent Skills](/docs/skills/)
  + [References](/docs/references/)
  + [Custom Tools](/docs/custom-tools/)
* Develop

  + [SDK](/docs/sdk/)
  + [Server](/docs/server/)
  + [Plugins](/docs/plugins/)
  + [Ecosystem](/docs/ecosystem/)

[GitHub](https://github.com/anomalyco/opencode)[Discord](https://opencode.ai/discord)

  Select theme   DarkLightAuto         Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

On this page

* [Overview](#_top)
* [How it works](#how-it-works)
* [Sharing](#sharing)
  + [Manual (default)](#manual-default)
  + [Auto-share](#auto-share)
  + [Disabled](#disabled)
* [Un-sharing](#un-sharing)
* [Privacy](#privacy)
  + [Data retention](#data-retention)
  + [Recommendations](#recommendations)
* [For enterprises](#for-enterprises)

### On this page

* [Overview](#_top)
* [How it works](#how-it-works)
* [Sharing](#sharing)
  + [Manual (default)](#manual-default)
  + [Auto-share](#auto-share)
  + [Disabled](#disabled)
* [Un-sharing](#un-sharing)
* [Privacy](#privacy)
  + [Data retention](#data-retention)
  + [Recommendations](#recommendations)
* [For enterprises](#for-enterprises)

## Share

Share your OpenCode conversations.

OpenCodeâs share feature allows you to create public links to your OpenCode conversations, so you can collaborate with teammates or get help from others.

Note

Shared conversations are publicly accessible to anyone with the link.

---

### [How it works](#how-it-works)

When you share a conversation, OpenCode:

1. Creates a unique public URL for your session
2. Syncs your conversation history to our servers
3. Makes the conversation accessible via the shareable link â `opncd.ai/s/<share-id>`

---

### [Sharing](#sharing)

OpenCode supports three sharing modes that control how conversations are shared:

---

#### [Manual (default)](#manual-default)

By default, OpenCode uses manual sharing mode. Sessions are not shared automatically, but you can manually share them using the `/share` command:

```
/share
```

This will generate a unique URL thatâll be copied to your clipboard.

To explicitly set manual mode in your [config file](/docs/config):

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"share": "manual"

}
```

---

#### [Auto-share](#auto-share)

You can enable automatic sharing for all new conversations by setting the `share` option to `"auto"` in your [config file](/docs/config):

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"share": "auto"

}
```

With auto-share enabled, every new conversation will automatically be shared and a link will be generated.

---

#### [Disabled](#disabled)

You can disable sharing entirely by setting the `share` option to `"disabled"` in your [config file](/docs/config):

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"share": "disabled"

}
```

To enforce this across your team for a given project, add it to the `opencode.json` in your project and check into Git.

---

### [Un-sharing](#un-sharing)

To stop sharing a conversation and remove it from public access:

```
/unshare
```

This will remove the share link and delete the data related to the conversation.

---

### [Privacy](#privacy)

There are a few things to keep in mind when sharing a conversation.

---

#### [Data retention](#data-retention)

Shared conversations remain accessible until you explicitly unshare them. This
includes:

* Full conversation history
* All messages and responses
* Session metadata

---

#### [Recommendations](#recommendations)

* Only share conversations that donât contain sensitive information.
* Review conversation content before sharing.
* Unshare conversations when collaboration is complete.
* Avoid sharing conversations with proprietary code or confidential data.
* For sensitive projects, disable sharing entirely.

---

### [For enterprises](#for-enterprises)

For enterprise deployments, the share feature can be:

* **Disabled** entirely for security compliance
* **Restricted** to users authenticated through SSO only
* **Self-hosted** on your own infrastructure

[Learn more](/docs/enterprise) about using opencode in your organization.

[Edit page](https://github.com/anomalyco/opencode/edit/dev/packages/web/src/content/docs/share.mdx)[Found a bug? Open an issue](https://github.com/anomalyco/opencode/issues/new)[Join our Discord community](https://opencode.ai/discord)  Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

© [Anomaly](https://anoma.ly)

Last updated: Oct 13, 2026

---
<!--
URL: https://opencode.ai/docs/ide/
title: IDE | OpenCode
-->

[Skip to content](#_top)

[![](/docs/_astro/logo-dark.DOStV66V.svg) ![](/docs/_astro/logo-light.B0yzR0O5.svg)  OpenCode](/docs/)

[app.header.home](/)[app.header.docs](/v2/docs)

Search  `CtrlK`

Cancel

  [New OpenCode v2 is now available →](https://opencode.ai/v2)

* [Intro](/docs/)
* [Config](/docs/config/)
* [Providers](/docs/providers/)
* [Network](/docs/network/)
* [Enterprise](/docs/enterprise/)
* [Troubleshooting](/docs/troubleshooting/)
* [Windows](/docs/windows-wsl)
* Usage

  + [Go](https://opencode.ai/v2/docs/console/go/)
  + [TUI](/docs/tui/)
  + [CLI](/docs/cli/)
  + [Web](/docs/web/)
  + [IDE](/docs/ide/)
  + [Console](https://opencode.ai/v2/docs/console/)
  + [Share](/docs/share/)
  + [GitHub](/docs/github/)
  + [GitLab](/docs/gitlab/)
* Configure

  + [Tools](/docs/tools/)
  + [Rules](/docs/rules/)
  + [Agents](/docs/agents/)
  + [Models](/docs/models/)
  + [Themes](/docs/themes/)
  + [Keybinds](/docs/keybinds/)
  + [Commands](/docs/commands/)
  + [Formatters](/docs/formatters/)
  + [Permissions](/docs/permissions/)
  + [Policies](/docs/policies/)
  + [LSP Servers](/docs/lsp/)
  + [MCP servers](/docs/mcp-servers/)
  + [ACP Support](/docs/acp/)
  + [Agent Skills](/docs/skills/)
  + [References](/docs/references/)
  + [Custom Tools](/docs/custom-tools/)
* Develop

  + [SDK](/docs/sdk/)
  + [Server](/docs/server/)
  + [Plugins](/docs/plugins/)
  + [Ecosystem](/docs/ecosystem/)

[GitHub](https://github.com/anomalyco/opencode)[Discord](https://opencode.ai/discord)

  Select theme   DarkLightAuto         Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

On this page

* [Overview](#_top)
* [Usage](#usage)
* [Installation](#installation)
  + [Manual Install](#manual-install)
  + [Troubleshooting](#troubleshooting)

### On this page

* [Overview](#_top)
* [Usage](#usage)
* [Installation](#installation)
  + [Manual Install](#manual-install)
  + [Troubleshooting](#troubleshooting)

## IDE

The OpenCode extension for VS Code, Cursor, and other IDEs

OpenCode integrates with VS Code, Cursor, or any IDE that supports a terminal. Just run `opencode` in the terminal to get started.

---

### [Usage](#usage)

* **Quick Launch**: Use `Cmd+Esc` (Mac) or `Ctrl+Esc` (Windows/Linux) to open OpenCode in a split terminal view, or focus an existing terminal session if one is already running.
* **New Session**: Use `Cmd+Shift+Esc` (Mac) or `Ctrl+Shift+Esc` (Windows/Linux) to start a new OpenCode terminal session, even if one is already open. You can also click the OpenCode button in the UI.
* **Context Awareness**: Automatically share your current selection or tab with OpenCode.
* **File Reference Shortcuts**: Use `Cmd+Option+K` (Mac) or `Alt+Ctrl+K` (Linux/Windows) to insert file references. For example, `@File#L37-42`.

---

### [Installation](#installation)

To install OpenCode on VS Code and popular forks like Cursor, Windsurf, VSCodium:

1. Open VS Code
2. Open the integrated terminal
3. Run `opencode` - the extension installs automatically

If on the other hand you want to use your own IDE when you run `/editor` or `/export` from the TUI, youâll need to set `export EDITOR="code --wait"`. [Learn more](/docs/tui/#editor-setup).

---

#### [Manual Install](#manual-install)

Search for **OpenCode** in the Extension Marketplace and click **Install**.

---

#### [Troubleshooting](#troubleshooting)

If the extension fails to install automatically:

* Ensure youâre running `opencode` in the integrated terminal.
* Confirm the CLI for your IDE is installed:
  + For VS Code: `code` command
  + For Cursor: `cursor` command
  + For Windsurf: `windsurf` command
  + For VSCodium: `codium` command
  + If not, run `Cmd+Shift+P` (Mac) or `Ctrl+Shift+P` (Windows/Linux) and search for âShell Command: Install âcodeâ command in PATHâ (or the equivalent for your IDE)
* Ensure VS Code has permission to install extensions

[Edit page](https://github.com/anomalyco/opencode/edit/dev/packages/web/src/content/docs/ide.mdx)[Found a bug? Open an issue](https://github.com/anomalyco/opencode/issues/new)[Join our Discord community](https://opencode.ai/discord)  Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

© [Anomaly](https://anoma.ly)

Last updated: Oct 13, 2026

---
<!--
URL: https://opencode.ai/docs/sdk/
title: SDK | OpenCode
-->

[Skip to content](#_top)

[![](/docs/_astro/logo-dark.DOStV66V.svg) ![](/docs/_astro/logo-light.B0yzR0O5.svg)  OpenCode](/docs/)

[app.header.home](/)[app.header.docs](/v2/docs)

Search  `CtrlK`

Cancel

  [New OpenCode v2 is now available →](https://opencode.ai/v2)

* [Intro](/docs/)
* [Config](/docs/config/)
* [Providers](/docs/providers/)
* [Network](/docs/network/)
* [Enterprise](/docs/enterprise/)
* [Troubleshooting](/docs/troubleshooting/)
* [Windows](/docs/windows-wsl)
* Usage

  + [Go](https://opencode.ai/v2/docs/console/go/)
  + [TUI](/docs/tui/)
  + [CLI](/docs/cli/)
  + [Web](/docs/web/)
  + [IDE](/docs/ide/)
  + [Console](https://opencode.ai/v2/docs/console/)
  + [Share](/docs/share/)
  + [GitHub](/docs/github/)
  + [GitLab](/docs/gitlab/)
* Configure

  + [Tools](/docs/tools/)
  + [Rules](/docs/rules/)
  + [Agents](/docs/agents/)
  + [Models](/docs/models/)
  + [Themes](/docs/themes/)
  + [Keybinds](/docs/keybinds/)
  + [Commands](/docs/commands/)
  + [Formatters](/docs/formatters/)
  + [Permissions](/docs/permissions/)
  + [Policies](/docs/policies/)
  + [LSP Servers](/docs/lsp/)
  + [MCP servers](/docs/mcp-servers/)
  + [ACP Support](/docs/acp/)
  + [Agent Skills](/docs/skills/)
  + [References](/docs/references/)
  + [Custom Tools](/docs/custom-tools/)
* Develop

  + [SDK](/docs/sdk/)
  + [Server](/docs/server/)
  + [Plugins](/docs/plugins/)
  + [Ecosystem](/docs/ecosystem/)

[GitHub](https://github.com/anomalyco/opencode)[Discord](https://opencode.ai/discord)

  Select theme   DarkLightAuto         Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

On this page

* [Overview](#_top)
* [Install](#install)
* [Create client](#create-client)
* [Config](#config)
* [Client only](#client-only)
* [Types](#types)
* [Errors](#errors)
* [Structured Output](#structured-output)
  + [Basic Usage](#basic-usage)
  + [Output Format Types](#output-format-types)
  + [JSON Schema Format](#json-schema-format)
  + [Error Handling](#error-handling)
  + [Best Practices](#best-practices)
* [APIs](#apis)
  + [Global](#global)
  + [App](#app)
  + [Project](#project)
  + [Path](#path)
  + [Config](#config-1)
  + [Sessions](#sessions)
  + [Files](#files)
  + [TUI](#tui)
  + [Auth](#auth)
  + [Events](#events)

### On this page

* [Overview](#_top)
* [Install](#install)
* [Create client](#create-client)
* [Config](#config)
* [Client only](#client-only)
* [Types](#types)
* [Errors](#errors)
* [Structured Output](#structured-output)
  + [Basic Usage](#basic-usage)
  + [Output Format Types](#output-format-types)
  + [JSON Schema Format](#json-schema-format)
  + [Error Handling](#error-handling)
  + [Best Practices](#best-practices)
* [APIs](#apis)
  + [Global](#global)
  + [App](#app)
  + [Project](#project)
  + [Path](#path)
  + [Config](#config-1)
  + [Sessions](#sessions)
  + [Files](#files)
  + [TUI](#tui)
  + [Auth](#auth)
  + [Events](#events)

## SDK

Type-safe JS client for opencode server.

The opencode JS/TS SDK provides a type-safe client for interacting with the server.
Use it to build integrations and control opencode programmatically.

[Learn more](/docs/server) about how the server works. For examples, check out the [projects](/docs/ecosystem#projects) built by the community.

---

### [Install](#install)

Install the SDK from npm:

Terminal window

```
npm install @opencode-ai/sdk
```

---

### [Create client](#create-client)

Create an instance of opencode:

```
import { createOpencode } from "@opencode-ai/sdk"

const { client } = await createOpencode()
```

This starts both a server and a client

##### [Options](#options)

| Option | Type | Description | Default |
| --- | --- | --- | --- |
| `hostname` | `string` | Server hostname | `127.0.0.1` |
| `port` | `number` | Server port | `4096` |
| `signal` | `AbortSignal` | Abort signal for cancellation | `undefined` |
| `timeout` | `number` | Timeout in ms for server start | `5000` |
| `config` | `Config` | Configuration object | `{}` |

---

### [Config](#config)

You can pass a configuration object to customize behavior. The instance still picks up your `opencode.json`, but you can override or add configuration inline:

```
import { createOpencode } from "@opencode-ai/sdk"

const opencode = await createOpencode({

hostname: "127.0.0.1",

port: 4096,

config: {

model: "anthropic/claude-3-5-sonnet-20241022",

},

})

console.log(`Server running at ${opencode.server.url}`)

opencode.server.close()
```

### [Client only](#client-only)

If you already have a running instance of opencode, you can create a client instance to connect to it:

```
import { createOpencodeClient } from "@opencode-ai/sdk"

const client = createOpencodeClient({

baseUrl: "http://localhost:4096",

})
```

##### [Options](#options-1)

| Option | Type | Description | Default |
| --- | --- | --- | --- |
| `baseUrl` | `string` | URL of the server | `http://localhost:4096` |
| `fetch` | `function` | Custom fetch implementation | `globalThis.fetch` |
| `parseAs` | `string` | Response parsing method | `auto` |
| `responseStyle` | `string` | Return style: `data` or `fields` | `fields` |
| `throwOnError` | `boolean` | Throw errors instead of return | `false` |

---

### [Types](#types)

The SDK includes TypeScript definitions for all API types. Import them directly:

```
import type { Session, Message, Part } from "@opencode-ai/sdk"
```

All types are generated from the serverâs OpenAPI specification and available in the [types file](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts).

---

### [Errors](#errors)

The SDK can throw errors that you can catch and handle:

```
try {

await client.session.get({ path: { id: "invalid-id" } })

} catch (error) {

console.error("Failed to get session:", (error as Error).message)

}
```

---

### [Structured Output](#structured-output)

You can request structured JSON output from the model by specifying an `format` with a JSON schema. The model will use a `StructuredOutput` tool to return validated JSON matching your schema.

#### [Basic Usage](#basic-usage)

```
const result = await client.session.prompt({

path: { id: sessionId },

body: {

parts: [{ type: "text", text: "Research Anthropic and provide company info" }],

format: {

type: "json_schema",

schema: {

type: "object",

properties: {

company: { type: "string", description: "Company name" },

founded: { type: "number", description: "Year founded" },

products: {

type: "array",

items: { type: "string" },

description: "Main products",

},

},

required: ["company", "founded"],

},

},

},

})

// Access the structured output

console.log(result.data.info.structured_output)

// { company: "Anthropic", founded: 2021, products: ["Claude", "Claude API"] }
```

#### [Output Format Types](#output-format-types)

| Type | Description |
| --- | --- |
| `text` | Default. Standard text response (no structured output) |
| `json_schema` | Returns validated JSON matching the provided schema |

#### [JSON Schema Format](#json-schema-format)

When using `type: 'json_schema'`, provide:

| Field | Type | Description |
| --- | --- | --- |
| `type` | `'json_schema'` | Required. Specifies JSON schema mode |
| `schema` | `object` | Required. JSON Schema object defining the output structure |
| `retryCount` | `number` | Optional. Number of validation retries (default: 2) |

#### [Error Handling](#error-handling)

If the model fails to produce valid structured output after all retries, the response will include a `StructuredOutputError`:

```
if (result.data.info.error?.name === "StructuredOutputError") {

console.error("Failed to produce structured output:", result.data.info.error.message)

console.error("Attempts:", result.data.info.error.retries)

}
```

#### [Best Practices](#best-practices)

1. **Provide clear descriptions** in your schema properties to help the model understand what data to extract
2. **Use `required`** to specify which fields must be present
3. **Keep schemas focused** - complex nested schemas may be harder for the model to fill correctly
4. **Set appropriate `retryCount`** - increase for complex schemas, decrease for simple ones

---

### [APIs](#apis)

The SDK exposes all server APIs through a type-safe client.

---

#### [Global](#global)

| Method | Description | Response |
| --- | --- | --- |
| `global.health()` | Check server health and version | `{ healthy: true, version: string }` |

---

##### [Examples](#examples)

```
const health = await client.global.health()

console.log(health.data.version)
```

---

#### [App](#app)

| Method | Description | Response |
| --- | --- | --- |
| `app.log()` | Write a log entry | `boolean` |
| `app.agents()` | List all available agents | [`Agent[]`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) |

---

##### [Examples](#examples-1)

```
// Write a log entry

await client.app.log({

body: {

service: "my-app",

level: "info",

message: "Operation completed",

},

})

// List available agents

const agents = await client.app.agents()
```

---

#### [Project](#project)

| Method | Description | Response |
| --- | --- | --- |
| `project.list()` | List all projects | [`Project[]`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) |

---

##### [Examples](#examples-2)

```
// List all projects

const projects = await client.project.list()
```

---

#### [Path](#path)

| Method | Description | Response |
| --- | --- | --- |
| `path.get()` | Get current path | [`Path`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) |

---

##### [Examples](#examples-3)

```
// Get current path information

const pathInfo = await client.path.get()
```

---

#### [Config](#config-1)

| Method | Description | Response |
| --- | --- | --- |
| `config.get()` | Get config info | [`Config`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) |
| `config.providers()` | List providers and default models | `{ providers:` [`Provider[]`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts)`, default: { [key: string]: string } }` |

---

##### [Examples](#examples-4)

```
const config = await client.config.get()

const { providers, default: defaults } = await client.config.providers()
```

---

#### [Sessions](#sessions)

| Method | Description | Notes |
| --- | --- | --- |
| `session.list()` | List sessions | Returns [`Session[]`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) |
| `session.get({ path })` | Get session | Returns [`Session`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) |
| `session.children({ path })` | List child sessions | Returns [`Session[]`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) |
| `session.create({ body })` | Create session | Returns [`Session`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) |
| `session.delete({ path })` | Delete session | Returns `boolean` |
| `session.update({ path, body })` | Update session properties | Returns [`Session`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) |
| `session.init({ path, body })` | Analyze app and create `AGENTS.md` | Returns `boolean` |
| `session.abort({ path })` | Abort a running session | Returns `boolean` |
| `session.share({ path })` | Share session | Returns [`Session`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) |
| `session.unshare({ path })` | Unshare session | Returns [`Session`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) |
| `session.summarize({ path, body })` | Summarize session | Returns `boolean` |
| `session.messages({ path })` | List messages in a session | Returns `{ info:` [`Message`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts)`, parts:` [`Part[]`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts)`}[]` |
| `session.message({ path })` | Get message details | Returns `{ info:` [`Message`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts)`, parts:` [`Part[]`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts)`}` |
| `session.prompt({ path, body })` | Send prompt message | `body.noReply: true` returns UserMessage (context only). Default returns [`AssistantMessage`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) with AI response. Supports `body.outputFormat` for [structured output](#structured-output) |
| `session.command({ path, body })` | Send command to session | Returns `{ info:` [`AssistantMessage`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts)`, parts:` [`Part[]`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts)`}` |
| `session.shell({ path, body })` | Run a shell command | Returns [`AssistantMessage`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) |
| `session.revert({ path, body })` | Revert a message | Returns [`Session`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) |
| `session.unrevert({ path })` | Restore reverted messages | Returns [`Session`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) |
| `postSessionByIdPermissionsByPermissionId({ path, body })` | Respond to a permission request | Returns `boolean` |

---

##### [Examples](#examples-5)

```
// Create and manage sessions

const session = await client.session.create({

body: { title: "My session" },

})

const sessions = await client.session.list()

// Send a prompt message

const result = await client.session.prompt({

path: { id: session.id },

body: {

model: { providerID: "anthropic", modelID: "claude-3-5-sonnet-20241022" },

parts: [{ type: "text", text: "Hello!" }],

},

})

// Inject context without triggering AI response (useful for plugins)

await client.session.prompt({

path: { id: session.id },

body: {

noReply: true,

parts: [{ type: "text", text: "You are a helpful assistant." }],

},

})
```

---

#### [Files](#files)

| Method | Description | Response |
| --- | --- | --- |
| `find.text({ query })` | Search for text in files | Array of match objects with `path`, `lines`, `line_number`, `absolute_offset`, `submatches` |
| `find.files({ query })` | Find files and directories by name | `string[]` (paths) |
| `find.symbols({ query })` | Find workspace symbols | [`Symbol[]`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) |
| `file.read({ query })` | Read a file | `{ type: "raw" | "patch", content: string }` |
| `file.status({ query? })` | Get status for tracked files | [`File[]`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) |

`find.files` supports a few optional query fields:

* `type`: `"file"` or `"directory"`
* `directory`: override the project root for the search
* `limit`: max results (1â200)

---

##### [Examples](#examples-6)

```
// Search and read files

const textResults = await client.find.text({

query: { pattern: "function.*opencode" },

})

const files = await client.find.files({

query: { query: "*.ts", type: "file" },

})

const directories = await client.find.files({

query: { query: "packages", type: "directory", limit: 20 },

})

const content = await client.file.read({

query: { path: "src/index.ts" },

})
```

---

#### [TUI](#tui)

| Method | Description | Response |
| --- | --- | --- |
| `tui.appendPrompt({ body })` | Append text to the prompt | `boolean` |
| `tui.openHelp()` | Open the help dialog | `boolean` |
| `tui.openSessions()` | Open the session selector | `boolean` |
| `tui.openThemes()` | Open the theme selector | `boolean` |
| `tui.openModels()` | Open the model selector | `boolean` |
| `tui.submitPrompt()` | Submit the current prompt | `boolean` |
| `tui.clearPrompt()` | Clear the prompt | `boolean` |
| `tui.executeCommand({ body })` | Execute a command | `boolean` |
| `tui.showToast({ body })` | Show toast notification | `boolean` |

---

##### [Examples](#examples-7)

```
// Control TUI interface

await client.tui.appendPrompt({

body: { text: "Add this to prompt" },

})

await client.tui.showToast({

body: { message: "Task completed", variant: "success" },

})
```

---

#### [Auth](#auth)

| Method | Description | Response |
| --- | --- | --- |
| `auth.set({ ... })` | Set authentication credentials | `boolean` |

---

##### [Examples](#examples-8)

```
await client.auth.set({

path: { id: "anthropic" },

body: { type: "api", key: "your-api-key" },

})
```

---

#### [Events](#events)

| Method | Description | Response |
| --- | --- | --- |
| `event.subscribe()` | Server-sent events stream | Server-sent events stream |

---

##### [Examples](#examples-9)

```
// Listen to real-time events

const events = await client.event.subscribe()

for await (const event of events.stream) {

console.log("Event:", event.type, event.properties)

}
```

[Edit page](https://github.com/anomalyco/opencode/edit/dev/packages/web/src/content/docs/sdk.mdx)[Found a bug? Open an issue](https://github.com/anomalyco/opencode/issues/new)[Join our Discord community](https://opencode.ai/discord)  Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

© [Anomaly](https://anoma.ly)

Last updated: Oct 13, 2026

---
<!--
URL: https://opencode.ai/docs/config
title: Config | OpenCode
-->

[Skip to content](#_top)

[![](/docs/_astro/logo-dark.DOStV66V.svg) ![](/docs/_astro/logo-light.B0yzR0O5.svg)  OpenCode](/docs/)

[app.header.home](/)[app.header.docs](/v2/docs)

Search  `CtrlK`

Cancel

  [New OpenCode v2 is now available →](https://opencode.ai/v2)

* [Intro](/docs/)
* [Config](/docs/config/)
* [Providers](/docs/providers/)
* [Network](/docs/network/)
* [Enterprise](/docs/enterprise/)
* [Troubleshooting](/docs/troubleshooting/)
* [Windows](/docs/windows-wsl)
* Usage

  + [Go](https://opencode.ai/v2/docs/console/go/)
  + [TUI](/docs/tui/)
  + [CLI](/docs/cli/)
  + [Web](/docs/web/)
  + [IDE](/docs/ide/)
  + [Console](https://opencode.ai/v2/docs/console/)
  + [Share](/docs/share/)
  + [GitHub](/docs/github/)
  + [GitLab](/docs/gitlab/)
* Configure

  + [Tools](/docs/tools/)
  + [Rules](/docs/rules/)
  + [Agents](/docs/agents/)
  + [Models](/docs/models/)
  + [Themes](/docs/themes/)
  + [Keybinds](/docs/keybinds/)
  + [Commands](/docs/commands/)
  + [Formatters](/docs/formatters/)
  + [Permissions](/docs/permissions/)
  + [Policies](/docs/policies/)
  + [LSP Servers](/docs/lsp/)
  + [MCP servers](/docs/mcp-servers/)
  + [ACP Support](/docs/acp/)
  + [Agent Skills](/docs/skills/)
  + [References](/docs/references/)
  + [Custom Tools](/docs/custom-tools/)
* Develop

  + [SDK](/docs/sdk/)
  + [Server](/docs/server/)
  + [Plugins](/docs/plugins/)
  + [Ecosystem](/docs/ecosystem/)

[GitHub](https://github.com/anomalyco/opencode)[Discord](https://opencode.ai/discord)

  Select theme   DarkLightAuto         Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

On this page

* [Overview](#_top)
* [Format](#format)
* [Locations](#locations)
  + [Precedence order](#precedence-order)
  + [Remote](#remote)
  + [Global](#global)
  + [Per project](#per-project)
  + [Custom path](#custom-path)
  + [Custom directory](#custom-directory)
  + [Managed settings](#managed-settings)
* [Schema](#schema)
  + [TUI](#tui)
  + [Server](#server)
  + [Shell](#shell)
  + [Tools](#tools)
  + [Models](#models)
  + [Policies](#policies)
  + [Image attachments](#image-attachments)
  + [Themes](#themes)
  + [Agents](#agents)
  + [Default agent](#default-agent)
  + [Subagent depth](#subagent-depth)
  + [Sharing](#sharing)
  + [Commands](#commands)
  + [Keybinds](#keybinds)
  + [Snapshot](#snapshot)
  + [Autoupdate](#autoupdate)
  + [Formatters](#formatters)
  + [LSP Servers](#lsp-servers)
  + [Permissions](#permissions)
  + [Compaction](#compaction)
  + [Watcher](#watcher)
  + [MCP servers](#mcp-servers)
  + [Plugins](#plugins)
  + [Instructions](#instructions)
  + [Disabled providers](#disabled-providers)
  + [Enabled providers](#enabled-providers)
  + [Experimental](#experimental)
* [Variables](#variables)
  + [Env vars](#env-vars)
  + [Files](#files)

### On this page

* [Overview](#_top)
* [Format](#format)
* [Locations](#locations)
  + [Precedence order](#precedence-order)
  + [Remote](#remote)
  + [Global](#global)
  + [Per project](#per-project)
  + [Custom path](#custom-path)
  + [Custom directory](#custom-directory)
  + [Managed settings](#managed-settings)
* [Schema](#schema)
  + [TUI](#tui)
  + [Server](#server)
  + [Shell](#shell)
  + [Tools](#tools)
  + [Models](#models)
  + [Policies](#policies)
  + [Image attachments](#image-attachments)
  + [Themes](#themes)
  + [Agents](#agents)
  + [Default agent](#default-agent)
  + [Subagent depth](#subagent-depth)
  + [Sharing](#sharing)
  + [Commands](#commands)
  + [Keybinds](#keybinds)
  + [Snapshot](#snapshot)
  + [Autoupdate](#autoupdate)
  + [Formatters](#formatters)
  + [LSP Servers](#lsp-servers)
  + [Permissions](#permissions)
  + [Compaction](#compaction)
  + [Watcher](#watcher)
  + [MCP servers](#mcp-servers)
  + [Plugins](#plugins)
  + [Instructions](#instructions)
  + [Disabled providers](#disabled-providers)
  + [Enabled providers](#enabled-providers)
  + [Experimental](#experimental)
* [Variables](#variables)
  + [Env vars](#env-vars)
  + [Files](#files)

## Config

Using the OpenCode JSON config.

You can configure OpenCode using a JSON config file.

---

### [Format](#format)

OpenCode supports both **JSON** and **JSONC** (JSON with Comments) formats.

opencode.jsonc

```
{

"$schema": "https://opencode.ai/config.json",

"model": "anthropic/claude-sonnet-4-5",

"autoupdate": true,

"server": {

"port": 4096,

},

}
```

---

### [Locations](#locations)

You can place your config in a couple of different locations and they have a
different order of precedence.

Note

Configuration files are **merged together**, not replaced.

Configuration files are merged together, not replaced. Settings from the following config locations are combined. Later configs override earlier ones only for conflicting keys. Non-conflicting settings from all configs are preserved.

For example, if your global config sets `autoupdate: true` and your project config sets `model: "anthropic/claude-sonnet-4-5"`, the final configuration will include both settings.

---

#### [Precedence order](#precedence-order)

Config sources are loaded in this order (later sources override earlier ones):

1. **Remote config** (from `.well-known/opencode`) - organizational defaults
2. **Global config** (`~/.config/opencode/opencode.json`) - user preferences
3. **Custom config** (`OPENCODE_CONFIG` env var) - custom overrides
4. **Project config** (`opencode.json` in project) - project-specific settings
5. **`.opencode` directories** - agents, commands, plugins
6. **Inline config** (`OPENCODE_CONFIG_CONTENT` env var) - runtime overrides
7. **Managed config files** (`/Library/Application Support/opencode/` on macOS) - admin-controlled
8. **macOS managed preferences** (`.mobileconfig` via MDM) - highest priority, not user-overridable

This means project configs can override global defaults, and global configs can override remote organizational defaults. Managed settings override everything.

Note

The `.opencode` and `~/.config/opencode` directories use **plural names** for subdirectories: `agents/`, `commands/`, `modes/`, `plugins/`, `skills/`, `tools/`, and `themes/`. Singular names (e.g., `agent/`) are also supported for backwards compatibility.

---

#### [Remote](#remote)

Organizations can provide default configuration via the `.well-known/opencode` endpoint. This is fetched automatically when you authenticate with a provider that supports it.

Remote config is loaded first, serving as the base layer. All other config sources (global, project) can override these defaults.

For example, if your organization provides MCP servers that are disabled by default:

Remote config from .well-known/opencode

```
{

"mcp": {

"jira": {

"type": "remote",

"url": "https://jira.example.com/mcp",

"enabled": false

}

}

}
```

You can enable specific servers in your local config:

opencode.json

```
{

"mcp": {

"jira": {

"type": "remote",

"url": "https://jira.example.com/mcp",

"enabled": true

}

}

}
```

---

#### [Global](#global)

Place your global OpenCode config in `~/.config/opencode/opencode.json`. Use global config for user-wide server/runtime preferences like providers, models, and permissions.

For TUI-specific settings, use `~/.config/opencode/tui.json`.

Global config overrides remote organizational defaults.

---

#### [Per project](#per-project)

Add `opencode.json` in your project root. Project config has the highest precedence among standard config files - it overrides both global and remote configs.

For project-specific TUI settings, add `tui.json` alongside it.

Tip

Place project specific config in the root of your project.

When OpenCode starts up, it first looks for a config file in the current directory, then traverses up to the nearest Git directory.

This is also safe to be checked into Git and uses the same schema as the global one.

---

#### [Custom path](#custom-path)

Specify a custom config file path using the `OPENCODE_CONFIG` environment variable.

Terminal window

```
export OPENCODE_CONFIG=/path/to/my/custom-config.json

opencode run "Hello world"
```

Custom config is loaded between global and project configs in the precedence order.

---

#### [Custom directory](#custom-directory)

Specify a custom config directory using the `OPENCODE_CONFIG_DIR`
environment variable. This directory will be searched for agents, commands,
modes, and plugins just like the standard `.opencode` directory, and should
follow the same structure.

Terminal window

```
export OPENCODE_CONFIG_DIR=/path/to/my/config-directory

opencode run "Hello world"
```

The custom directory is loaded after the global config and `.opencode` directories, so it **can override** their settings.

---

#### [Managed settings](#managed-settings)

Organizations can enforce configuration that users cannot override. Managed settings are loaded at the highest priority tier.

##### [File-based](#file-based)

Drop an `opencode.json` or `opencode.jsonc` file in the system managed config directory:

| Platform | Path |
| --- | --- |
| macOS | `/Library/Application Support/opencode/` |
| Linux | `/etc/opencode/` |
| Windows | `%ProgramData%\opencode` |

These directories require admin/root access to write, so users cannot modify them.

##### [macOS managed preferences](#macos-managed-preferences)

On macOS, OpenCode reads managed preferences from the `ai.opencode.managed` preference domain. Deploy a `.mobileconfig` via MDM (Jamf, Kandji, FleetDM) and the settings are enforced automatically.

OpenCode checks these paths:

1. `/Library/Managed Preferences/<user>/ai.opencode.managed.plist`
2. `/Library/Managed Preferences/ai.opencode.managed.plist`

The plist keys map directly to `opencode.json` fields. MDM metadata keys (`PayloadUUID`, `PayloadType`, etc.) are stripped automatically.

**Creating a `.mobileconfig`**

Use the `ai.opencode.managed` PayloadType. The OpenCode config keys go directly in the payload dict:

```
<?xml version="1.0" encoding="UTF-8"?>

<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"

"http://www.apple.com/DTDs/PropertyList-1.0.dtd">

<plist version="1.0">

<dict>

<key>PayloadContent</key>

<array>

<dict>

<key>PayloadType</key>

<string>ai.opencode.managed</string>

<key>PayloadIdentifier</key>

<string>com.example.opencode.config</string>

<key>PayloadUUID</key>

<string>GENERATE-YOUR-OWN-UUID</string>

<key>PayloadVersion</key>

<integer>1</integer>

<key>share</key>

<string>disabled</string>

<key>server</key>

<dict>

<key>hostname</key>

<string>127.0.0.1</string>

</dict>

<key>permission</key>

<dict>

<key>*</key>

<string>ask</string>

<key>bash</key>

<dict>

<key>*</key>

<string>ask</string>

<key>rm -rf *</key>

<string>deny</string>

</dict>

</dict>

</dict>

</array>

<key>PayloadType</key>

<string>Configuration</string>

<key>PayloadIdentifier</key>

<string>com.example.opencode</string>

<key>PayloadUUID</key>

<string>GENERATE-YOUR-OWN-UUID</string>

<key>PayloadVersion</key>

<integer>1</integer>

</dict>

</plist>
```

Generate unique UUIDs with `uuidgen`. Customize the settings to match your organizationâs requirements.

**Deploying via MDM**

* **Jamf Pro:** Computers > Configuration Profiles > Upload > scope to target devices or smart groups
* **FleetDM:** Add the `.mobileconfig` to your gitops repo under `mdm.macos_settings.custom_settings` and run `fleetctl apply`

**Verifying on a device**

Double-click the `.mobileconfig` to install locally for testing (shows in System Settings > Privacy & Security > Profiles), then run:

Terminal window

```
opencode debug config
```

All managed preference keys appear in the resolved config and cannot be overridden by user or project configuration.

---

### [Schema](#schema)

The server/runtime config schema is defined in [**`opencode.ai/config.json`**](https://opencode.ai/config.json).

TUI config uses [**`opencode.ai/tui.json`**](https://opencode.ai/tui.json).

Your editor should be able to validate and autocomplete based on the schema.

---

#### [TUI](#tui)

Use a dedicated `tui.json` (or `tui.jsonc`) file for TUI-specific settings.

tui.json

```
{

"$schema": "https://opencode.ai/tui.json",

"scroll_speed": 3,

"scroll_acceleration": {

"enabled": true

},

"diff_style": "auto",

"cursor": {

"style": "block",

"blinking": true

},

"mouse": true,

"attention": {

"enabled": true,

"notifications": true,

"sound": true,

"volume": 0.4

}

}
```

Use `OPENCODE_TUI_CONFIG` to point to a custom TUI config file.

When `cursor.style` is `"default"`, the terminal default cursor is restored, so `cursor.blinking` has no effect.

Set `attention.enabled` to turn on TUI desktop notifications and sounds. See [TUI attention](/docs/tui#attention).

Legacy `theme`, `keybinds`, and `tui` keys in `opencode.json` are deprecated and automatically migrated when possible.

---

#### [Server](#server)

You can configure server settings for the `opencode serve` and `opencode web` commands through the `server` option.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"server": {

"port": 4096,

"hostname": "0.0.0.0",

"mdns": true,

"mdnsDomain": "myproject.local",

"cors": ["http://localhost:5173"]

}

}
```

Available options:

* `port` - Port to listen on.
* `hostname` - Hostname to listen on. When `mdns` is enabled and no hostname is set, defaults to `0.0.0.0`.
* `mdns` - Enable mDNS service discovery. This allows other devices on the network to discover your OpenCode server.
* `mdnsDomain` - Custom domain name for mDNS service. Defaults to `opencode.local`. Useful for running multiple instances on the same network.
* `cors` - Additional origins to allow for CORS when using the HTTP server from a browser-based client. Values must be full origins (scheme + host + optional port), eg `https://app.example.com`.

[Learn more about the server here](/docs/server).

---

#### [Shell](#shell)

You can configure the shell used for the interactive terminal using the `shell` option. Compatible shells are also used for agent tool calls.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"shell": "pwsh"

}
```

If not specified, OpenCode will automatically discover and use a sensible default based on your operating system (e.g. `pwsh` or `cmd.exe` on Windows, `/bin/zsh` or `/bin/bash` on macOS/Linux). You can provide an absolute path or a short name.

---

#### [Tools](#tools)

You can manage the tools an LLM can use through the `tools` option.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"tools": {

"write": false,

"bash": false

}

}
```

[Learn more about tools here](/docs/tools).

---

#### [Models](#models)

You can configure the providers and models you want to use in your OpenCode config through the `provider`, `model` and `small_model` options.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"provider": {},

"model": "anthropic/claude-sonnet-4-5",

"small_model": "anthropic/claude-haiku-4-5"

}
```

The `small_model` option configures a separate model for lightweight tasks like title generation. By default, OpenCode tries to use a cheaper model if one is available from your provider, otherwise it falls back to your main model.

Provider options can include `timeout`, `headerTimeout`, `chunkTimeout`, and `setCacheKey`:

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"provider": {

"anthropic": {

"options": {

"timeout": 600000,

"chunkTimeout": 30000,

"setCacheKey": true

}

}

}

}
```

* `timeout` - Request timeout in milliseconds (default: 300000). Set to `false` to disable.
* `headerTimeout` - Timeout in milliseconds to wait for response headers (default: 300000, or 5 minutes). This timer stops once headers arrive and does not limit the streamed response body. Set to `false` to disable.
* `chunkTimeout` - Timeout in milliseconds between streamed response chunks (default: 300000, or 5 minutes). If no chunk arrives in time, the request is aborted. Set to `false` to disable.
* `setCacheKey` - Ensure a cache key is always set for designated provider.

You can also configure [local models](/docs/models#local). [Learn more](/docs/models).

---

#### [Policies](#policies)

Use the `experimental.policies` option to allow or deny OpenCode actions on configured resources. Currently, policies can control which providers OpenCode may use.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"experimental": {

"policies": [

{

"effect": "deny",

"action": "provider.use",

"resource": "openai"

}

]

}

}
```

[Learn more about policies here](/docs/policies).

---

#### [Image attachments](#image-attachments)

OpenCode normalizes image attachments before sending them to the model. By default, images are resized when they exceed `2000x2000` pixels or `5242880` base64 bytes.

Configure image attachment limits with the `attachment.image` option:

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"attachment": {

"image": {

"auto_resize": true,

"max_width": 2000,

"max_height": 2000,

"max_base64_bytes": 5242880

}

}

}
```

* `auto_resize` - Resize images that exceed the configured limits before provider requests. Set to `false` to reject oversized images instead.
* `max_width` - Maximum image width in pixels before resizing or rejection.
* `max_height` - Maximum image height in pixels before resizing or rejection.
* `max_base64_bytes` - Maximum encoded image payload size. This is the base64 payload size, not the original file size.

If an image still cannot fit after resizing, OpenCode omits oversized tool-result images or fails oversized user-provided images with an image size error.

---

##### [Provider-Specific Options](#provider-specific-options)

Some providers support additional configuration options beyond the generic `timeout` and `apiKey` settings.

###### [Amazon Bedrock](#amazon-bedrock)

Amazon Bedrock supports AWS-specific configuration:

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"provider": {

"amazon-bedrock": {

"options": {

"region": "us-east-1",

"profile": "my-aws-profile",

"endpoint": "https://bedrock-runtime.us-east-1.vpce-xxxxx.amazonaws.com"

}

}

}

}
```

* `region` - AWS region for Bedrock (defaults to `AWS_REGION` env var or `us-east-1`)
* `profile` - AWS named profile from `~/.aws/credentials` (defaults to `AWS_PROFILE` env var)
* `endpoint` - Custom endpoint URL for VPC endpoints. This is an alias for the generic `baseURL` option using AWS-specific terminology. If both are specified, `endpoint` takes precedence.

Note

Bearer tokens (`AWS_BEARER_TOKEN_BEDROCK` or `/connect`) take precedence over profile-based authentication. See [authentication precedence](/docs/providers#authentication-precedence) for details.

[Learn more about Amazon Bedrock configuration](/docs/providers#amazon-bedrock).

---

#### [Themes](#themes)

Set your UI theme in `tui.json`.

tui.json

```
{

"$schema": "https://opencode.ai/tui.json",

"theme": "tokyonight"

}
```

[Learn more here](/docs/themes).

---

#### [Agents](#agents)

You can configure specialized agents for specific tasks through the `agent` option.

opencode.jsonc

```
{

"$schema": "https://opencode.ai/config.json",

"agent": {

"code-reviewer": {

"description": "Reviews code for best practices and potential issues",

"model": "anthropic/claude-sonnet-4-5",

"prompt": "You are a code reviewer. Focus on security, performance, and maintainability.",

"tools": {

// Disable file modification tools for review-only agent

"write": false,

"edit": false,

},

},

},

}
```

You can also define agents using markdown files in `~/.config/opencode/agents/` or `.opencode/agents/`. [Learn more here](/docs/agents).

---

#### [Default agent](#default-agent)

You can set the default agent using the `default_agent` option. This determines which agent is used when none is explicitly specified.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"default_agent": "plan"

}
```

The default agent must be a primary agent (not a subagent). This can be a built-in agent like `"build"` or `"plan"`, or a [custom agent](/docs/agents) youâve defined. If the specified agent doesnât exist or is a subagent, OpenCode will fall back to `"build"` with a warning.

This setting applies across all interfaces: TUI, CLI (`opencode run`), desktop app, and GitHub Action.

---

#### [Subagent depth](#subagent-depth)

You can control how deeply subagents can invoke other subagents using the `subagent_depth` option.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"subagent_depth": 2

}
```

The default is `1`, which allows primary agents to launch subagents but prevents those subagents from launching additional subagents. Set it to `2` to allow one additional level of nested subagents, or `0` to prevent all subagent launches.

---

#### [Sharing](#sharing)

You can configure the [share](/docs/share) feature through the `share` option.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"share": "manual"

}
```

This takes:

* `"manual"` - Allow manual sharing via commands (default)
* `"auto"` - Automatically share new conversations
* `"disabled"` - Disable sharing entirely

By default, sharing is set to manual mode where you need to explicitly share conversations using the `/share` command.

---

#### [Commands](#commands)

You can configure custom commands for repetitive tasks through the `command` option.

opencode.jsonc

```
{

"$schema": "https://opencode.ai/config.json",

"command": {

"test": {

"template": "Run the full test suite with coverage report and show any failures.\nFocus on the failing tests and suggest fixes.",

"description": "Run tests with coverage",

"agent": "build",

"model": "anthropic/claude-haiku-4-5",

},

"component": {

"template": "Create a new React component named $ARGUMENTS with TypeScript support.\nInclude proper typing and basic structure.",

"description": "Create a new component",

},

},

}
```

You can also define commands using markdown files in `~/.config/opencode/commands/` or `.opencode/commands/`. [Learn more here](/docs/commands).

---

#### [Keybinds](#keybinds)

Customize TUI keyboard shortcuts in `tui.json` with `keybinds`.

tui.json

```
{

"$schema": "https://opencode.ai/tui.json",

"keybinds": {

"command_list": "ctrl+p"

}

}
```

`keybinds` is merged with built-in defaults, so you only need to configure the shortcuts you want to change.

[Learn more here](/docs/keybinds).

---

#### [Snapshot](#snapshot)

OpenCode uses snapshots to track file changes during agent operations, enabling you to undo and revert changes within a session. Snapshots are enabled by default.

For large repositories or projects with many submodules, the snapshot system can cause slow indexing and significant disk usage as it tracks all changes using an internal git repository. You can disable snapshots using the `snapshot` option.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"snapshot": false

}
```

Note that disabling snapshots means changes made by the agent cannot be rolled back through the UI.

---

#### [Autoupdate](#autoupdate)

OpenCode will automatically download any new updates when it starts up. You can disable this with the `autoupdate` option.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"autoupdate": false

}
```

If you donât want updates but want to be notified when a new version is available, set `autoupdate` to `"notify"`.
Notice that this only works if it was not installed using a package manager such as Homebrew.

---

#### [Formatters](#formatters)

You can enable and configure code formatters through the `formatter` option. Omit it to keep formatters disabled.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"formatter": true

}
```

Use an object to keep built-ins enabled while configuring overrides or custom formatters.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"formatter": {

"prettier": {

"disabled": true

},

"custom-prettier": {

"command": ["npx", "prettier", "--write", "$FILE"],

"environment": {

"NODE_ENV": "development"

},

"extensions": [".js", ".ts", ".jsx", ".tsx"]

}

}

}
```

[Learn more about formatters here](/docs/formatters).

---

#### [LSP Servers](#lsp-servers)

You can enable and configure LSP servers through the `lsp` option. Omit it to keep LSP disabled.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"lsp": true

}
```

Use an object to keep built-ins enabled while configuring overrides or custom LSP servers.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"lsp": {

"typescript": {

"disabled": true

}

}

}
```

[Learn more about LSP servers here](/docs/lsp).

---

#### [Permissions](#permissions)

By default, opencode **allows all operations** without requiring explicit approval. You can change this using the `permission` option.

For example, to ensure that the `edit` and `bash` tools require user approval:

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"permission": {

"edit": "ask",

"bash": "ask"

}

}
```

[Learn more about permissions here](/docs/permissions).

---

#### [Compaction](#compaction)

You can control context compaction behavior through the `compaction` option.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"compaction": {

"auto": true,

"prune": false,

"reserved": 10000

}

}
```

* `auto` - Automatically compact the session when context is full (default: `true`).
* `prune` - Remove old tool outputs to save tokens (default: `false`). Set to `true` to enable pruning.
* `reserved` - Token buffer for compaction. Leaves enough window to avoid overflow during compaction.

---

#### [Watcher](#watcher)

You can configure file watcher ignore patterns through the `watcher` option.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"watcher": {

"ignore": ["**/generated/**"]

}

}
```

Patterns follow glob syntax. Common dependency, VCS, build, and cache directories are ignored automatically at any depth.

---

#### [MCP servers](#mcp-servers)

You can configure MCP servers you want to use through the `mcp` option.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"mcp": {}

}
```

[Learn more here](/docs/mcp-servers).

---

#### [Plugins](#plugins)

[Plugins](/docs/plugins) extend OpenCode with custom tools, hooks, and integrations.

Place plugin files in `.opencode/plugins/` or `~/.config/opencode/plugins/`. You can also load plugins from npm through the `plugin` option.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"plugin": ["opencode-helicone-session", "@my-org/custom-plugin"]

}
```

[Learn more here](/docs/plugins).

---

#### [Instructions](#instructions)

You can configure the instructions for the model youâre using through the `instructions` option.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"instructions": ["CONTRIBUTING.md", "docs/guidelines.md", ".cursor/rules/*.md"]

}
```

This takes an array of paths and glob patterns to instruction files. [Learn more
about rules here](/docs/rules).

---

#### [Disabled providers](#disabled-providers)

You can disable providers that are loaded automatically through the `disabled_providers` option. This is useful when you want to prevent certain providers from being loaded even if their credentials are available.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"disabled_providers": ["openai", "gemini"]

}
```

Note

The `disabled_providers` takes priority over `enabled_providers`.

The `disabled_providers` option accepts an array of provider IDs. When a provider is disabled:

* It wonât be loaded even if environment variables are set.
* It wonât be loaded even if API keys are configured through the `/connect` command.
* The providerâs models wonât appear in the model selection list.

---

#### [Enabled providers](#enabled-providers)

You can specify an allowlist of providers through the `enabled_providers` option. When set, only the specified providers will be enabled and all others will be ignored.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"enabled_providers": ["anthropic", "openai"]

}
```

This is useful when you want to restrict OpenCode to only use specific providers rather than disabling them one by one.

Note

The `disabled_providers` takes priority over `enabled_providers`.

If a provider appears in both `enabled_providers` and `disabled_providers`, the `disabled_providers` takes priority for backwards compatibility.

---

#### [Experimental](#experimental)

The `experimental` key contains options that are under active development.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"experimental": {}

}
```

Caution

Experimental options are not stable. They may change or be removed without notice.

---

### [Variables](#variables)

You can use variable substitution in your config files to reference environment variables and file contents.

---

#### [Env vars](#env-vars)

Use `{env:VARIABLE_NAME}` to substitute environment variables:

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"model": "{env:OPENCODE_MODEL}",

"provider": {

"anthropic": {

"models": {},

"options": {

"apiKey": "{env:ANTHROPIC_API_KEY}"

}

}

}

}
```

If the environment variable is not set, it will be replaced with an empty string.

---

#### [Files](#files)

Use `{file:path/to/file}` to substitute the contents of a file:

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"instructions": ["./custom-instructions.md"],

"provider": {

"openai": {

"options": {

"apiKey": "{file:~/.secrets/openai-key}"

}

}

}

}
```

File paths can be:

* Relative to the config file directory
* Or absolute paths starting with `/` or `~`

These are useful for:

* Keeping sensitive data like API keys in separate files.
* Including large instruction files without cluttering your config.
* Sharing common configuration snippets across multiple config files.

[Edit page](https://github.com/anomalyco/opencode/edit/dev/packages/web/src/content/docs/config.mdx)[Found a bug? Open an issue](https://github.com/anomalyco/opencode/issues/new)[Join our Discord community](https://opencode.ai/discord)  Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

© [Anomaly](https://anoma.ly)

Last updated: Oct 13, 2026

---
<!--
URL: https://opencode.ai/docs/themes/
title: Themes | OpenCode
-->

[Skip to content](#_top)

[![](/docs/_astro/logo-dark.DOStV66V.svg) ![](/docs/_astro/logo-light.B0yzR0O5.svg)  OpenCode](/docs/)

[app.header.home](/)[app.header.docs](/v2/docs)

Search  `CtrlK`

Cancel

  [New OpenCode v2 is now available →](https://opencode.ai/v2)

* [Intro](/docs/)
* [Config](/docs/config/)
* [Providers](/docs/providers/)
* [Network](/docs/network/)
* [Enterprise](/docs/enterprise/)
* [Troubleshooting](/docs/troubleshooting/)
* [Windows](/docs/windows-wsl)
* Usage

  + [Go](https://opencode.ai/v2/docs/console/go/)
  + [TUI](/docs/tui/)
  + [CLI](/docs/cli/)
  + [Web](/docs/web/)
  + [IDE](/docs/ide/)
  + [Console](https://opencode.ai/v2/docs/console/)
  + [Share](/docs/share/)
  + [GitHub](/docs/github/)
  + [GitLab](/docs/gitlab/)
* Configure

  + [Tools](/docs/tools/)
  + [Rules](/docs/rules/)
  + [Agents](/docs/agents/)
  + [Models](/docs/models/)
  + [Themes](/docs/themes/)
  + [Keybinds](/docs/keybinds/)
  + [Commands](/docs/commands/)
  + [Formatters](/docs/formatters/)
  + [Permissions](/docs/permissions/)
  + [Policies](/docs/policies/)
  + [LSP Servers](/docs/lsp/)
  + [MCP servers](/docs/mcp-servers/)
  + [ACP Support](/docs/acp/)
  + [Agent Skills](/docs/skills/)
  + [References](/docs/references/)
  + [Custom Tools](/docs/custom-tools/)
* Develop

  + [SDK](/docs/sdk/)
  + [Server](/docs/server/)
  + [Plugins](/docs/plugins/)
  + [Ecosystem](/docs/ecosystem/)

[GitHub](https://github.com/anomalyco/opencode)[Discord](https://opencode.ai/discord)

  Select theme   DarkLightAuto         Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

On this page

* [Overview](#_top)
* [Terminal requirements](#terminal-requirements)
* [Built-in themes](#built-in-themes)
* [System theme](#system-theme)
* [Using a theme](#using-a-theme)
* [Custom themes](#custom-themes)
  + [Hierarchy](#hierarchy)
  + [Creating a theme](#creating-a-theme)
  + [JSON format](#json-format)
  + [Color definitions](#color-definitions)
  + [Terminal defaults](#terminal-defaults)
  + [Example](#example)

### On this page

* [Overview](#_top)
* [Terminal requirements](#terminal-requirements)
* [Built-in themes](#built-in-themes)
* [System theme](#system-theme)
* [Using a theme](#using-a-theme)
* [Custom themes](#custom-themes)
  + [Hierarchy](#hierarchy)
  + [Creating a theme](#creating-a-theme)
  + [JSON format](#json-format)
  + [Color definitions](#color-definitions)
  + [Terminal defaults](#terminal-defaults)
  + [Example](#example)

## Themes

Select a built-in theme or define your own.

With OpenCode you can select from one of several built-in themes, use a theme that adapts to your terminal theme, or define your own custom theme.

By default, OpenCode uses our own `opencode` theme.

---

### [Terminal requirements](#terminal-requirements)

For themes to display correctly with their full color palette, your terminal must support **truecolor** (24-bit color). Most modern terminals support this by default, but you may need to enable it:

* **Check support**: Run `echo $COLORTERM` - it should output `truecolor` or `24bit`
* **Enable truecolor**: Set the environment variable `COLORTERM=truecolor` in your shell profile
* **Terminal compatibility**: Ensure your terminal emulator supports 24-bit color (most modern terminals like iTerm2, Alacritty, Kitty, Windows Terminal, and recent versions of GNOME Terminal do)

Without truecolor support, themes may appear with reduced color accuracy or fall back to the nearest 256-color approximation.

---

### [Built-in themes](#built-in-themes)

OpenCode comes with several built-in themes.

| Name | Description |
| --- | --- |
| `system` | Adapts to your terminalâs background color |
| `tokyonight` | Based on the [Tokyonight](https://github.com/folke/tokyonight.nvim) theme |
| `everforest` | Based on the [Everforest](https://github.com/sainnhe/everforest) theme |
| `ayu` | Based on the [Ayu](https://github.com/ayu-theme) dark theme |
| `catppuccin` | Based on the [Catppuccin](https://github.com/catppuccin) theme |
| `catppuccin-macchiato` | Based on the [Catppuccin](https://github.com/catppuccin) theme |
| `gruvbox` | Based on the [Gruvbox](https://github.com/morhetz/gruvbox) theme |
| `kanagawa` | Based on the [Kanagawa](https://github.com/rebelot/kanagawa.nvim) theme |
| `nord` | Based on the [Nord](https://github.com/nordtheme/nord) theme |
| `matrix` | Hacker-style green on black theme |
| `one-dark` | Based on the [Atom One](https://github.com/Th3Whit3Wolf/one-nvim) Dark theme |

And more, we are constantly adding new themes.

---

### [System theme](#system-theme)

The `system` theme is designed to automatically adapt to your terminalâs color scheme. Unlike traditional themes that use fixed colors, the *system* theme:

* **Generates gray scale**: Creates a custom gray scale based on your terminalâs background color, ensuring optimal contrast.
* **Uses ANSI colors**: Leverages standard ANSI colors (0-15) for syntax highlighting and UI elements, which respect your terminalâs color palette.
* **Preserves terminal defaults**: Uses `none` for text and background colors to maintain your terminalâs native appearance.

The system theme is for users who:

* Want OpenCode to match their terminalâs appearance
* Use custom terminal color schemes
* Prefer a consistent look across all terminal applications

---

### [Using a theme](#using-a-theme)

You can select a theme by bringing up the theme select with the `/theme` command. Or you can specify it in `tui.json`.

tui.json

```
{

"$schema": "https://opencode.ai/tui.json",

"theme": "tokyonight"

}
```

---

### [Custom themes](#custom-themes)

OpenCode supports a flexible JSON-based theme system that allows users to create and customize themes easily.

---

#### [Hierarchy](#hierarchy)

Themes are loaded from multiple directories in the following order where later directories override earlier ones:

1. **Built-in themes** - These are embedded in the binary
2. **User config directory** - Defined in `~/.config/opencode/themes/*.json` or `$XDG_CONFIG_HOME/opencode/themes/*.json`
3. **Project root directory** - Defined in the `<project-root>/.opencode/themes/*.json`
4. **Current working directory** - Defined in `./.opencode/themes/*.json`

If multiple directories contain a theme with the same name, the theme from the directory with higher priority will be used.

---

#### [Creating a theme](#creating-a-theme)

To create a custom theme, create a JSON file in one of the theme directories.

For user-wide themes:

Terminal window

```
mkdir -p ~/.config/opencode/themes

vim ~/.config/opencode/themes/my-theme.json
```

And for project-specific themes.

Terminal window

```
mkdir -p .opencode/themes

vim .opencode/themes/my-theme.json
```

---

#### [JSON format](#json-format)

Themes use a flexible JSON format with support for:

* **Hex colors**: `"#ffffff"`
* **ANSI colors**: `3` (0-255)
* **Color references**: `"primary"` or custom definitions
* **Dark/light variants**: `{"dark": "#000", "light": "#fff"}`
* **No color**: `"none"` - Uses the terminalâs default color or transparent

---

#### [Color definitions](#color-definitions)

The `defs` section is optional and it allows you to define reusable colors that can be referenced in the theme.

---

#### [Terminal defaults](#terminal-defaults)

The special value `"none"` can be used for any color to inherit the terminalâs default color. This is particularly useful for creating themes that blend seamlessly with your terminalâs color scheme:

* `"text": "none"` - Uses terminalâs default foreground color
* `"background": "none"` - Uses terminalâs default background color

---

#### [Example](#example)

Hereâs an example of a custom theme:

my-theme.json

```
{

"$schema": "https://opencode.ai/theme.json",

"defs": {

"nord0": "#2E3440",

"nord1": "#3B4252",

"nord2": "#434C5E",

"nord3": "#4C566A",

"nord4": "#D8DEE9",

"nord5": "#E5E9F0",

"nord6": "#ECEFF4",

"nord7": "#8FBCBB",

"nord8": "#88C0D0",

"nord9": "#81A1C1",

"nord10": "#5E81AC",

"nord11": "#BF616A",

"nord12": "#D08770",

"nord13": "#EBCB8B",

"nord14": "#A3BE8C",

"nord15": "#B48EAD"

},

"theme": {

"primary": {

"dark": "nord8",

"light": "nord10"

},

"secondary": {

"dark": "nord9",

"light": "nord9"

},

"accent": {

"dark": "nord7",

"light": "nord7"

},

"error": {

"dark": "nord11",

"light": "nord11"

},

"warning": {

"dark": "nord12",

"light": "nord12"

},

"success": {

"dark": "nord14",

"light": "nord14"

},

"info": {

"dark": "nord8",

"light": "nord10"

},

"text": {

"dark": "nord4",

"light": "nord0"

},

"textMuted": {

"dark": "nord3",

"light": "nord1"

},

"background": {

"dark": "nord0",

"light": "nord6"

},

"backgroundPanel": {

"dark": "nord1",

"light": "nord5"

},

"backgroundElement": {

"dark": "nord1",

"light": "nord4"

},

"border": {

"dark": "nord2",

"light": "nord3"

},

"borderActive": {

"dark": "nord3",

"light": "nord2"

},

"borderSubtle": {

"dark": "nord2",

"light": "nord3"

},

"diffAdded": {

"dark": "nord14",

"light": "nord14"

},

"diffRemoved": {

"dark": "nord11",

"light": "nord11"

},

"diffContext": {

"dark": "nord3",

"light": "nord3"

},

"diffHunkHeader": {

"dark": "nord3",

"light": "nord3"

},

"diffHighlightAdded": {

"dark": "nord14",

"light": "nord14"

},

"diffHighlightRemoved": {

"dark": "nord11",

"light": "nord11"

},

"diffAddedBg": {

"dark": "#3B4252",

"light": "#E5E9F0"

},

"diffRemovedBg": {

"dark": "#3B4252",

"light": "#E5E9F0"

},

"diffContextBg": {

"dark": "nord1",

"light": "nord5"

},

"diffLineNumber": {

"dark": "nord2",

"light": "nord4"

},

"diffAddedLineNumberBg": {

"dark": "#3B4252",

"light": "#E5E9F0"

},

"diffRemovedLineNumberBg": {

"dark": "#3B4252",

"light": "#E5E9F0"

},

"markdownText": {

"dark": "nord4",

"light": "nord0"

},

"markdownHeading": {

"dark": "nord8",

"light": "nord10"

},

"markdownLink": {

"dark": "nord9",

"light": "nord9"

},

"markdownLinkText": {

"dark": "nord7",

"light": "nord7"

},

"markdownCode": {

"dark": "nord14",

"light": "nord14"

},

"markdownBlockQuote": {

"dark": "nord3",

"light": "nord3"

},

"markdownEmph": {

"dark": "nord12",

"light": "nord12"

},

"markdownStrong": {

"dark": "nord13",

"light": "nord13"

},

"markdownHorizontalRule": {

"dark": "nord3",

"light": "nord3"

},

"markdownListItem": {

"dark": "nord8",

"light": "nord10"

},

"markdownListEnumeration": {

"dark": "nord7",

"light": "nord7"

},

"markdownImage": {

"dark": "nord9",

"light": "nord9"

},

"markdownImageText": {

"dark": "nord7",

"light": "nord7"

},

"markdownCodeBlock": {

"dark": "nord4",

"light": "nord0"

},

"syntaxComment": {

"dark": "nord3",

"light": "nord3"

},

"syntaxKeyword": {

"dark": "nord9",

"light": "nord9"

},

"syntaxFunction": {

"dark": "nord8",

"light": "nord8"

},

"syntaxVariable": {

"dark": "nord7",

"light": "nord7"

},

"syntaxString": {

"dark": "nord14",

"light": "nord14"

},

"syntaxNumber": {

"dark": "nord15",

"light": "nord15"

},

"syntaxType": {

"dark": "nord7",

"light": "nord7"

},

"syntaxOperator": {

"dark": "nord9",

"light": "nord9"

},

"syntaxPunctuation": {

"dark": "nord4",

"light": "nord0"

}

}

}
```

[Edit page](https://github.com/anomalyco/opencode/edit/dev/packages/web/src/content/docs/themes.mdx)[Found a bug? Open an issue](https://github.com/anomalyco/opencode/issues/new)[Join our Discord community](https://opencode.ai/discord)  Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

© [Anomaly](https://anoma.ly)

Last updated: Oct 13, 2026

---
<!--
URL: https://opencode.ai/docs/gitlab/
title: GitLab | OpenCode
-->

[Skip to content](#_top)

[![](/docs/_astro/logo-dark.DOStV66V.svg) ![](/docs/_astro/logo-light.B0yzR0O5.svg)  OpenCode](/docs/)

[app.header.home](/)[app.header.docs](/v2/docs)

Search  `CtrlK`

Cancel

  [New OpenCode v2 is now available →](https://opencode.ai/v2)

* [Intro](/docs/)
* [Config](/docs/config/)
* [Providers](/docs/providers/)
* [Network](/docs/network/)
* [Enterprise](/docs/enterprise/)
* [Troubleshooting](/docs/troubleshooting/)
* [Windows](/docs/windows-wsl)
* Usage

  + [Go](https://opencode.ai/v2/docs/console/go/)
  + [TUI](/docs/tui/)
  + [CLI](/docs/cli/)
  + [Web](/docs/web/)
  + [IDE](/docs/ide/)
  + [Console](https://opencode.ai/v2/docs/console/)
  + [Share](/docs/share/)
  + [GitHub](/docs/github/)
  + [GitLab](/docs/gitlab/)
* Configure

  + [Tools](/docs/tools/)
  + [Rules](/docs/rules/)
  + [Agents](/docs/agents/)
  + [Models](/docs/models/)
  + [Themes](/docs/themes/)
  + [Keybinds](/docs/keybinds/)
  + [Commands](/docs/commands/)
  + [Formatters](/docs/formatters/)
  + [Permissions](/docs/permissions/)
  + [Policies](/docs/policies/)
  + [LSP Servers](/docs/lsp/)
  + [MCP servers](/docs/mcp-servers/)
  + [ACP Support](/docs/acp/)
  + [Agent Skills](/docs/skills/)
  + [References](/docs/references/)
  + [Custom Tools](/docs/custom-tools/)
* Develop

  + [SDK](/docs/sdk/)
  + [Server](/docs/server/)
  + [Plugins](/docs/plugins/)
  + [Ecosystem](/docs/ecosystem/)

[GitHub](https://github.com/anomalyco/opencode)[Discord](https://opencode.ai/discord)

  Select theme   DarkLightAuto         Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

On this page

* [Overview](#_top)
* [GitLab CI](#gitlab-ci)
  + [Features](#features)
  + [Setup](#setup)
* [GitLab Duo](#gitlab-duo)
  + [Features](#features-1)
  + [Setup](#setup-1)
  + [Examples](#examples)

### On this page

* [Overview](#_top)
* [GitLab CI](#gitlab-ci)
  + [Features](#features)
  + [Setup](#setup)
* [GitLab Duo](#gitlab-duo)
  + [Features](#features-1)
  + [Setup](#setup-1)
  + [Examples](#examples)

## GitLab

Use OpenCode in GitLab issues and merge requests.

OpenCode integrates with your GitLab workflow through your GitLab CI/CD pipeline or with GitLab Duo.

In both cases, OpenCode will run on your GitLab runners.

---

### [GitLab CI](#gitlab-ci)

OpenCode works in a regular GitLab pipeline. You can build it into a pipeline as a [CI component](https://docs.gitlab.com/ee/ci/components/)

Here we are using a community-created CI/CD component for OpenCode â [nagyv/gitlab-opencode](https://gitlab.com/nagyv/gitlab-opencode).

---

#### [Features](#features)

* **Use custom configuration per job**: Configure OpenCode with a custom configuration directory, for example `./config/#custom-directory` to enable or disable functionality per OpenCode invocation.
* **Minimal setup**: The CI component sets up OpenCode in the background, you only need to create the OpenCode configuration and the initial prompt.
* **Flexible**: The CI component supports several inputs for customizing its behavior

---

#### [Setup](#setup)

1. Store your OpenCode authentication JSON as a File type CI environment variables under **Settings** > **CI/CD** > **Variables**. Make sure to mark them as âMasked and hiddenâ.
2. Add the following to your `.gitlab-ci.yml` file.

   .gitlab-ci.yml

   ```
   include:

   - component: $CI_SERVER_FQDN/nagyv/gitlab-opencode/opencode@2

   inputs:

   config_dir: ${CI_PROJECT_DIR}/opencode-config

   auth_json: $OPENCODE_AUTH_JSON # The variable name for your OpenCode authentication JSON

   command: optional-custom-command

   message: "Your prompt here"
   ```

For more inputs and use cases [check out the docs](https://gitlab.com/explore/catalog/nagyv/gitlab-opencode) for this component.

---

### [GitLab Duo](#gitlab-duo)

OpenCode integrates with your GitLab workflow.
Mention `@opencode` in a comment, and OpenCode will execute tasks within your GitLab CI pipeline.

---

#### [Features](#features-1)

* **Triage issues**: Ask OpenCode to look into an issue and explain it to you.
* **Fix and implement**: Ask OpenCode to fix an issue or implement a feature.
  It will create a new branch and raise a merge request with the changes.
* **Secure**: OpenCode runs on your GitLab runners.

---

#### [Setup](#setup-1)

OpenCode runs in your GitLab CI/CD pipeline, hereâs what youâll need to set it up:

Tip

Check out the [**GitLab docs**](https://docs.gitlab.com/user/duo_agent_platform/agent_assistant/) for up to date instructions.

1. Configure your GitLab environment
2. Set up CI/CD
3. Get an AI model provider API key
4. Create a service account
5. Configure CI/CD variables
6. Create a flow config file, hereâs an example:

   Flow configuration

   ```
   image: node:22-slim

   commands:

   - echo "Installing opencode"

   - npm install --global opencode-ai

   - echo "Installing glab"

   - export GITLAB_TOKEN=$GITLAB_TOKEN_OPENCODE

   - apt-get update --quiet && apt-get install --yes curl wget gpg git && rm --recursive --force /var/lib/apt/lists/*

   - curl --silent --show-error --location "https://raw.githubusercontent.com/upciti/wakemeops/main/assets/install_repository" | bash

   - apt-get install --yes glab

   - echo "Configuring glab"

   - echo $GITLAB_HOST

   - echo "Creating OpenCode auth configuration"

   - mkdir --parents ~/.local/share/opencode

   - |

   cat > ~/.local/share/opencode/auth.json << EOF

   {

   "anthropic": {

   "type": "api",

   "key": "$ANTHROPIC_API_KEY"

   }

   }

   EOF

   - echo "Configuring git"

   - git config --global user.email "opencode@gitlab.com"

   - git config --global user.name "OpenCode"

   - echo "Testing glab"

   - glab issue list

   - echo "Running OpenCode"

   - |

   opencode run "

   You are an AI assistant helping with GitLab operations.

   Context: $AI_FLOW_CONTEXT

   Task: $AI_FLOW_INPUT

   Event: $AI_FLOW_EVENT

   Please execute the requested task using the available GitLab tools.

   Be thorough in your analysis and provide clear explanations.

   <important>

   Please use the glab CLI to access data from GitLab. The glab CLI has already been authenticated. You can run the corresponding commands.

   If you are asked to summarize an MR or issue or asked to provide more information then please post back a note to the MR/Issue so that the user can see it.

   You don't need to commit or push up changes, those will be done automatically based on the file changes you make.

   </important>

   "

   - git checkout --branch $CI_WORKLOAD_REF origin/$CI_WORKLOAD_REF

   - echo "Checking for git changes and pushing if any exist"

   - |

   if ! git diff --quiet || ! git diff --cached --quiet || [ --not --zero "$(git ls-files --others --exclude-standard)" ]; then

   echo "Git changes detected, adding and pushing..."

   git add .

   if git diff --cached --quiet; then

   echo "No staged changes to commit"

   else

   echo "Committing changes to branch: $CI_WORKLOAD_REF"

   git commit --message "Codex changes"

   echo "Pushing changes up to $CI_WORKLOAD_REF"

   git push https://gitlab-ci-token:$GITLAB_TOKEN@$GITLAB_HOST/gl-demo-ultimate-dev-ai-epic-17570/test-java-project.git $CI_WORKLOAD_REF

   echo "Changes successfully pushed"

   fi

   else

   echo "No git changes detected, skipping push"

   fi

   variables:

   - ANTHROPIC_API_KEY

   - GITLAB_TOKEN_OPENCODE

   - GITLAB_HOST
   ```

You can refer to the [GitLab CLI agents docs](https://docs.gitlab.com/user/duo_agent_platform/agent_assistant/) for detailed instructions.

---

#### [Examples](#examples)

Here are some examples of how you can use OpenCode in GitLab.

Tip

You can configure to use a different trigger phrase than `@opencode`.

* **Explain an issue**

  Add this comment in a GitLab issue.

  ```
  @opencode explain this issue
  ```

  OpenCode will read the issue and reply with a clear explanation.
* **Fix an issue**

  In a GitLab issue, say:

  ```
  @opencode fix this
  ```

  OpenCode will create a new branch, implement the changes, and open a merge request with the changes.
* **Review merge requests**

  Leave the following comment on a GitLab merge request.

  ```
  @opencode review this merge request
  ```

  OpenCode will review the merge request and provide feedback.

[Edit page](https://github.com/anomalyco/opencode/edit/dev/packages/web/src/content/docs/gitlab.mdx)[Found a bug? Open an issue](https://github.com/anomalyco/opencode/issues/new)[Join our Discord community](https://opencode.ai/discord)  Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

© [Anomaly](https://anoma.ly)

Last updated: Oct 13, 2026

---
<!--
URL: https://opencode.ai/docs/providers/
title: Providers | OpenCode
-->

[Skip to content](#_top)

[![](/docs/_astro/logo-dark.DOStV66V.svg) ![](/docs/_astro/logo-light.B0yzR0O5.svg)  OpenCode](/docs/)

[app.header.home](/)[app.header.docs](/v2/docs)

Search  `CtrlK`

Cancel

  [New OpenCode v2 is now available →](https://opencode.ai/v2)

* [Intro](/docs/)
* [Config](/docs/config/)
* [Providers](/docs/providers/)
* [Network](/docs/network/)
* [Enterprise](/docs/enterprise/)
* [Troubleshooting](/docs/troubleshooting/)
* [Windows](/docs/windows-wsl)
* Usage

  + [Go](https://opencode.ai/v2/docs/console/go/)
  + [TUI](/docs/tui/)
  + [CLI](/docs/cli/)
  + [Web](/docs/web/)
  + [IDE](/docs/ide/)
  + [Console](https://opencode.ai/v2/docs/console/)
  + [Share](/docs/share/)
  + [GitHub](/docs/github/)
  + [GitLab](/docs/gitlab/)
* Configure

  + [Tools](/docs/tools/)
  + [Rules](/docs/rules/)
  + [Agents](/docs/agents/)
  + [Models](/docs/models/)
  + [Themes](/docs/themes/)
  + [Keybinds](/docs/keybinds/)
  + [Commands](/docs/commands/)
  + [Formatters](/docs/formatters/)
  + [Permissions](/docs/permissions/)
  + [Policies](/docs/policies/)
  + [LSP Servers](/docs/lsp/)
  + [MCP servers](/docs/mcp-servers/)
  + [ACP Support](/docs/acp/)
  + [Agent Skills](/docs/skills/)
  + [References](/docs/references/)
  + [Custom Tools](/docs/custom-tools/)
* Develop

  + [SDK](/docs/sdk/)
  + [Server](/docs/server/)
  + [Plugins](/docs/plugins/)
  + [Ecosystem](/docs/ecosystem/)

[GitHub](https://github.com/anomalyco/opencode)[Discord](https://opencode.ai/discord)

  Select theme   DarkLightAuto         Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

On this page

* [Overview](#_top)
  + [Credentials](#credentials)
  + [Config](#config)
* [OpenCode Zen](#opencode-zen)
* [OpenCode Go](#opencode-go)
* [Directory](#directory)
  + [302.AI](#302ai)
  + [Amazon Bedrock](#amazon-bedrock)
  + [Anthropic](#anthropic)
  + [Atomic Chat](#atomic-chat)
  + [Azure OpenAI](#azure-openai)
  + [Azure Cognitive Services](#azure-cognitive-services)
  + [Baseten](#baseten)
  + [Cerebras](#cerebras)
  + [Cloudflare AI Gateway](#cloudflare-ai-gateway)
  + [Cloudflare Workers AI](#cloudflare-workers-ai)
  + [Cortecs](#cortecs)
  + [DeepSeek](#deepseek)
  + [Deep Infra](#deep-infra)
  + [DigitalOcean](#digitalocean)
  + [Eden AI](#eden-ai)
  + [FrogBot](#frogbot)
  + [Fireworks AI](#fireworks-ai)
  + [GitLab Duo](#gitlab-duo)
  + [GitHub Copilot](#github-copilot)
  + [GMI Cloud](#gmi-cloud)
  + [Google Vertex AI](#google-vertex-ai)
  + [Groq](#groq)
  + [Hugging Face](#hugging-face)
  + [Helicone](#helicone)
  + [llama.cpp](#llamacpp)
  + [IO.NET](#ionet)
  + [LM Studio](#lm-studio)
  + [Moonshot AI](#moonshot-ai)
  + [MiniMax](#minimax)
  + [Modal](#modal)
  + [NVIDIA](#nvidia)
  + [Nebius Token Factory](#nebius-token-factory)
  + [Ollama](#ollama)
  + [Ollama Cloud](#ollama-cloud)
  + [OpenAI](#openai)
  + [OpenCode Zen](#opencode-zen-1)
  + [OpenRouter](#openrouter)
  + [LLM Gateway](#llm-gateway)
  + [Poolside](#poolside)
  + [SAP AI Core](#sap-ai-core)
  + [STACKIT](#stackit)
  + [OVHcloud AI Endpoints](#ovhcloud-ai-endpoints)
  + [Scaleway](#scaleway)
  + [SCX.ai](#scxai)
  + [Snowflake Cortex](#snowflake-cortex)
  + [Together AI](#together-ai)
  + [Venice AI](#venice-ai)
  + [Vercel AI Gateway](#vercel-ai-gateway)
  + [xAI](#xai)
  + [Z.AI](#zai)
  + [ZenMux](#zenmux)
* [Custom provider](#custom-provider)
* [Troubleshooting](#troubleshooting)

### On this page

* [Overview](#_top)
  + [Credentials](#credentials)
  + [Config](#config)
* [OpenCode Zen](#opencode-zen)
* [OpenCode Go](#opencode-go)
* [Directory](#directory)
  + [302.AI](#302ai)
  + [Amazon Bedrock](#amazon-bedrock)
  + [Anthropic](#anthropic)
  + [Atomic Chat](#atomic-chat)
  + [Azure OpenAI](#azure-openai)
  + [Azure Cognitive Services](#azure-cognitive-services)
  + [Baseten](#baseten)
  + [Cerebras](#cerebras)
  + [Cloudflare AI Gateway](#cloudflare-ai-gateway)
  + [Cloudflare Workers AI](#cloudflare-workers-ai)
  + [Cortecs](#cortecs)
  + [DeepSeek](#deepseek)
  + [Deep Infra](#deep-infra)
  + [DigitalOcean](#digitalocean)
  + [Eden AI](#eden-ai)
  + [FrogBot](#frogbot)
  + [Fireworks AI](#fireworks-ai)
  + [GitLab Duo](#gitlab-duo)
  + [GitHub Copilot](#github-copilot)
  + [GMI Cloud](#gmi-cloud)
  + [Google Vertex AI](#google-vertex-ai)
  + [Groq](#groq)
  + [Hugging Face](#hugging-face)
  + [Helicone](#helicone)
  + [llama.cpp](#llamacpp)
  + [IO.NET](#ionet)
  + [LM Studio](#lm-studio)
  + [Moonshot AI](#moonshot-ai)
  + [MiniMax](#minimax)
  + [Modal](#modal)
  + [NVIDIA](#nvidia)
  + [Nebius Token Factory](#nebius-token-factory)
  + [Ollama](#ollama)
  + [Ollama Cloud](#ollama-cloud)
  + [OpenAI](#openai)
  + [OpenCode Zen](#opencode-zen-1)
  + [OpenRouter](#openrouter)
  + [LLM Gateway](#llm-gateway)
  + [Poolside](#poolside)
  + [SAP AI Core](#sap-ai-core)
  + [STACKIT](#stackit)
  + [OVHcloud AI Endpoints](#ovhcloud-ai-endpoints)
  + [Scaleway](#scaleway)
  + [SCX.ai](#scxai)
  + [Snowflake Cortex](#snowflake-cortex)
  + [Together AI](#together-ai)
  + [Venice AI](#venice-ai)
  + [Vercel AI Gateway](#vercel-ai-gateway)
  + [xAI](#xai)
  + [Z.AI](#zai)
  + [ZenMux](#zenmux)
* [Custom provider](#custom-provider)
* [Troubleshooting](#troubleshooting)

## Providers

Using any LLM provider in OpenCode.

OpenCode uses the [AI SDK](https://ai-sdk.dev/) and [Models.dev](https://models.dev) to support **75+ LLM providers** and it supports running local models.

To add a provider you need to:

1. Add the API keys for the provider using the `/connect` command.
2. Configure the provider in your OpenCode config.

---

#### [Credentials](#credentials)

When you add a providerâs API keys with the `/connect` command, they are stored
in `~/.local/share/opencode/auth.json`.

---

#### [Config](#config)

You can customize the providers through the `provider` section in your OpenCode
config.

---

##### [Base URL](#base-url)

You can customize the base URL for any provider by setting the `baseURL` option. This is useful when using proxy services or custom endpoints.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"provider": {

"anthropic": {

"options": {

"baseURL": "https://api.anthropic.com/v1"

}

}

}

}
```

---

##### [Hiding models](#hiding-models)

You can hide specific models from the `/models` picker for a provider using the `blacklist` option. This is useful when a provider exposes models you donât want to use or select.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"provider": {

"anthropic": {

"blacklist": ["claude-opus-4-20250514"]

}

}

}
```

The inverse `whitelist` option hides every model except the ones listed.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"provider": {

"anthropic": {

"whitelist": ["claude-sonnet-4-20250514"]

}

}

}
```

Both options take an array of model IDs â the same IDs shown in the `/models` picker.

* `blacklist` removes the listed models from the picker.
* `whitelist` keeps only the listed models and hides the rest.
* You can combine them: `whitelist` narrows the set, then `blacklist` removes entries from it.

---

### [OpenCode Zen](#opencode-zen)

OpenCode Zen is a list of models provided by the OpenCode team that have been
tested and verified to work well with OpenCode. [Learn more](https://opencode.ai/v2/docs/console/).

Tip

If you are new, we recommend starting with OpenCode Zen.

1. Run the `/connect` command in the TUI, select `OpenCode Zen`, and head to [opencode.ai/auth](https://opencode.ai/zen).

   ```
   /connect
   ```
2. Sign in, add your billing details, and copy your API key.
3. Paste your API key.

   ```
   â API key

   â

   â

   â enter
   ```
4. Run `/models` in the TUI to see the list of models we recommend.

   ```
   /models
   ```

It works like any other provider in OpenCode and is completely optional to use.

---

### [OpenCode Go](#opencode-go)

OpenCode Go is a low cost subscription plan that provides reliable access to popular open coding models provided by the OpenCode team that have been
tested and verified to work well with OpenCode.

1. Run the `/connect` command in the TUI, select `OpenCode Go`, and head to [opencode.ai/auth](https://opencode.ai/zen).

   ```
   /connect
   ```
2. Sign in, add your billing details, and copy your API key.
3. Paste your API key.

   ```
   â API key

   â

   â

   â enter
   ```
4. Run `/models` in the TUI to see the list of models we recommend.

   ```
   /models
   ```

It works like any other provider in OpenCode and is completely optional to use.

---

### [Directory](#directory)

Letâs look at some of the providers in detail. If youâd like to add a provider to the
list, feel free to open a PR.

Note

Donât see a provider here? Submit a PR.

---

#### [302.AI](#302ai)

1. Head over to the [302.AI console](https://302.ai/), create an account, and generate an API key.
2. Run the `/connect` command and search for **302.AI**.

   ```
   /connect
   ```
3. Enter your 302.AI API key.

   ```
   â API key

   â

   â

   â enter
   ```
4. Run the `/models` command to select a model.

   ```
   /models
   ```

---

#### [Amazon Bedrock](#amazon-bedrock)

To use Amazon Bedrock with OpenCode:

1. Head over to the **Model catalog** in the Amazon Bedrock console and request
   access to the models you want.

   Tip

   You need to have access to the model you want in Amazon Bedrock.
2. **Configure authentication** using one of the following methods:

   ---

   #### [Environment Variables (Quick Start)](#environment-variables-quick-start)

   Set one of these environment variables while running opencode:

   Terminal window

   ```
   # Option 1: Using AWS access keys

   AWS_ACCESS_KEY_ID=XXX AWS_SECRET_ACCESS_KEY=YYY opencode

   # Option 2: Using named AWS profile

   AWS_PROFILE=my-profile opencode

   # Option 3: Using Bedrock bearer token

   AWS_BEARER_TOKEN_BEDROCK=XXX opencode
   ```

   Or add them to your bash profile:

   ~/.bash\_profile

   ```
   export AWS_PROFILE=my-dev-profile

   export AWS_REGION=us-east-1
   ```

   ---

   #### [Configuration File (Recommended)](#configuration-file-recommended)

   For project-specific or persistent configuration, use `opencode.json`:

   opencode.json

   ```
   {

   "$schema": "https://opencode.ai/config.json",

   "provider": {

   "amazon-bedrock": {

   "options": {

   "region": "us-east-1",

   "profile": "my-aws-profile"

   }

   }

   }

   }
   ```

   **Available options:**

   * `region` - AWS region (e.g., `us-east-1`, `eu-west-1`)
   * `profile` - AWS named profile from `~/.aws/credentials`
   * `endpoint` - Custom endpoint URL for VPC endpoints (alias for generic `baseURL` option)

   Tip

   Configuration file options take precedence over environment variables.

   ---

   #### [Advanced: VPC Endpoints](#advanced-vpc-endpoints)

   If youâre using VPC endpoints for Bedrock:

   opencode.json

   ```
   {

   "$schema": "https://opencode.ai/config.json",

   "provider": {

   "amazon-bedrock": {

   "options": {

   "region": "us-east-1",

   "profile": "production",

   "endpoint": "https://bedrock-runtime.us-east-1.vpce-xxxxx.amazonaws.com"

   }

   }

   }

   }
   ```

   Note

   The `endpoint` option is an alias for the generic `baseURL` option, using AWS-specific terminology. If both `endpoint` and `baseURL` are specified, `endpoint` takes precedence.

   ---

   #### [Authentication Methods](#authentication-methods)

   * **`AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY`**: Create an IAM user and generate access keys in the AWS Console
   * **`AWS_PROFILE`**: Use named profiles from `~/.aws/credentials`. First configure with `aws configure --profile my-profile` or `aws sso login`
   * **`AWS_BEARER_TOKEN_BEDROCK`**: Generate long-term API keys from the Amazon Bedrock console
   * **`AWS_WEB_IDENTITY_TOKEN_FILE` / `AWS_ROLE_ARN`**: For EKS IRSA (IAM Roles for Service Accounts) or other Kubernetes environments with OIDC federation. These environment variables are automatically injected by Kubernetes when using service account annotations.

   ---

   #### [Authentication Precedence](#authentication-precedence)

   Amazon Bedrock uses the following authentication priority:

   1. **Bearer Token** - `AWS_BEARER_TOKEN_BEDROCK` environment variable or token from `/connect` command
   2. **AWS Credential Chain** - Profile, access keys, shared credentials, IAM roles, Web Identity Tokens (EKS IRSA), instance metadata

   Note

   When a bearer token is set (via `/connect` or `AWS_BEARER_TOKEN_BEDROCK`), it takes precedence over all AWS credential methods including configured profiles.
3. Run the `/models` command to select the model you want.

   ```
   /models
   ```

Note

For custom inference profiles, use the model and provider name in the key and set the `id` property to the arn. This ensures correct caching.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"provider": {

"amazon-bedrock": {

// ...

"models": {

"anthropic-claude-sonnet-4.5": {

"id": "arn:aws:bedrock:us-east-1:xxx:application-inference-profile/yyy"

}

}

}

}

}
```

---

#### [Anthropic](#anthropic)

1. Once youâve signed up, run the `/connect` command and select Anthropic.

   ```
   /connect
   ```
2. Here you can select the **Claude Pro/Max** option and itâll open your browser
   and ask you to authenticate.

   ```
   â Select auth method

   â

   â Manually enter API Key

   â
   ```
3. Now all the Anthropic models should be available when you use the `/models` command.

   ```
   /models
   ```

There are plugins that allow you to use your Claude Pro/Max models with
OpenCode. Anthropic explicitly prohibits this.

Previous versions of OpenCode came bundled with these plugins but that is no
longer the case as of 1.3.0

Other companies support freedom of choice with developer tooling - you can use
the following subscriptions in OpenCode with zero setup:

* ChatGPT Plus
* Github Copilot
* Gitlab Duo

---

#### [Atomic Chat](#atomic-chat)

You can configure opencode to use local models through [Atomic Chat](https://atomic.chat), a desktop application that runs local LLMs behind an OpenAI-compatible API server (default endpoint `http://127.0.0.1:1337/v1`).

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"provider": {

"atomic-chat": {

"npm": "@ai-sdk/openai-compatible",

"name": "Atomic Chat (local)",

"options": {

"baseURL": "http://127.0.0.1:1337/v1"

},

"models": {

"<your-model-id>": {

"name": "<your-model-name>"

}

}

}

}

}
```

In this example:

* `atomic-chat` is the custom provider ID. This can be any string you want.
* `npm` specifies the package to use for this provider. Here, `@ai-sdk/openai-compatible` is used for any OpenAI-compatible API.
* `name` is the display name for the provider in the UI.
* `options.baseURL` is the endpoint for the local server. Change the host and port to match your Atomic Chat setup.
* `models` is a map of model IDs to their display names. Each ID must match the `id` returned by `GET /v1/models` â run `curl http://127.0.0.1:1337/v1/models` to list the ids currently loaded in Atomic Chat.

Tip

If tool calls arenât working well, pick a loaded model with strong tool-calling support (for example, a Qwen-Coder or DeepSeek-Coder variant).

---

#### [Azure OpenAI](#azure-openai)

Note

If you encounter âIâm sorry, but I cannot assist with that requestâ errors, try changing the content filter from **DefaultV2** to **Default** in your Azure resource.

1. Head over to the [Azure portal](https://portal.azure.com/) and create an **Azure OpenAI** resource. Youâll need:

   * **Resource name**: This becomes part of your API endpoint (`https://RESOURCE_NAME.openai.azure.com/`)
   * **API key**: Either `KEY 1` or `KEY 2` from your resource
2. Go to [Azure AI Foundry](https://ai.azure.com/) and deploy a model.

   Note

   The deployment name must match the model name for opencode to work properly.
3. Run the `/connect` command and search for **Azure**.

   ```
   /connect
   ```
4. Enter your API key.

   ```
   â API key

   â

   â

   â enter
   ```
5. Set your resource name as an environment variable:

   Terminal window

   ```
   AZURE_RESOURCE_NAME=XXX opencode
   ```

   Or add it to your bash profile:

   ~/.bash\_profile

   ```
   export AZURE_RESOURCE_NAME=XXX
   ```
6. Run the `/models` command to select your deployed model.

   ```
   /models
   ```

##### [Microsoft Entra ID (Azure CLI)](#microsoft-entra-id-azure-cli)

You can use your Azure CLI session instead of an API key. [Install the Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli), run `az login`, then run `/connect`, select **Azure**, and choose **Microsoft Entra ID (Azure CLI)**. Enter the Azure Resource name when prompted. Use `az login --tenant TENANT_ID` if the Resource belongs to a different tenant.

Find the Resource name by opening your Azure OpenAI or Foundry Resource in the [Azure portal](https://portal.azure.com/) or [Microsoft Foundry](https://ai.azure.com/). It is also the first part of the endpoint: `my-models` in `https://my-models.openai.azure.com/` or `https://my-models.services.ai.azure.com/`. If your identity can list Resources, you can also find their names and Resource groups with:

Terminal window

```
az cognitiveservices account list \

--query "[].{name:name,resourceGroup:resourceGroup}" \

--output table
```

OpenCode does not query Azure management APIs or discover deployments. Select a model whose catalog name matches your deployment, or configure its deployment name explicitly:

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"provider": {

"azure": {

"models": {

"gpt-5-mini": {

"id": "gpt-production"

}

}

}

}

}
```

Assign your identity the inference role required by the deployment: **Cognitive Services OpenAI User** for Azure OpenAI models or **Cognitive Services User** for other Foundry models. OpenCode refreshes access tokens through the Azure CLI, including versions earlier than 2.54.0, so you only need to sign in again when the CLI session expires.

---

#### [Azure Cognitive Services](#azure-cognitive-services)

1. Head over to the [Azure portal](https://portal.azure.com/) and create an **Azure OpenAI** resource. Youâll need:

   * **Resource name**: This becomes part of your API endpoint (`https://AZURE_COGNITIVE_SERVICES_RESOURCE_NAME.cognitiveservices.azure.com/`)
   * **API key**: Either `KEY 1` or `KEY 2` from your resource
2. Go to [Azure AI Foundry](https://ai.azure.com/) and deploy a model.

   Note

   The deployment name must match the model name for opencode to work properly.
3. Run the `/connect` command and search for **Azure Cognitive Services**.

   ```
   /connect
   ```
4. Enter your API key.

   ```
   â API key

   â

   â

   â enter
   ```
5. Set your resource name as an environment variable:

   Terminal window

   ```
   AZURE_COGNITIVE_SERVICES_RESOURCE_NAME=XXX opencode
   ```

   Or add it to your bash profile:

   ~/.bash\_profile

   ```
   export AZURE_COGNITIVE_SERVICES_RESOURCE_NAME=XXX
   ```
6. Run the `/models` command to select your deployed model.

   ```
   /models
   ```

---

#### [Baseten](#baseten)

1. Head over to the [Baseten](https://app.baseten.co/), create an account, and generate an API key.
2. Run the `/connect` command and search for **Baseten**.

   ```
   /connect
   ```
3. Enter your Baseten API key.

   ```
   â API key

   â

   â

   â enter
   ```
4. Run the `/models` command to select a model.

   ```
   /models
   ```

---

#### [Cerebras](#cerebras)

1. Head over to the [Cerebras console](https://inference.cerebras.ai/), create an account, and generate an API key.
2. Run the `/connect` command and search for **Cerebras**.

   ```
   /connect
   ```
3. Enter your Cerebras API key.

   ```
   â API key

   â

   â

   â enter
   ```
4. Run the `/models` command to select a model like *Qwen 3 Coder 480B*.

   ```
   /models
   ```

---

#### [Cloudflare AI Gateway](#cloudflare-ai-gateway)

Cloudflare AI Gateway lets you access models from OpenAI, Anthropic, Workers AI, and more through a unified endpoint. With [Unified Billing](https://developers.cloudflare.com/ai-gateway/features/unified-billing/) you donât need separate API keys for each provider.

1. Head over to the [Cloudflare dashboard](https://dash.cloudflare.com/), navigate to **AI** > **AI Gateway**, and create a new gateway. Note your **Account ID** and **Gateway ID**.
2. Run the `/connect` command and search for **Cloudflare AI Gateway**.

   ```
   /connect
   ```
3. Enter your **Account ID** when prompted.

   ```
   â Enter your Cloudflare Account ID

   â

   â

   â enter
   ```
4. Enter your **Gateway ID** when prompted.

   ```
   â Enter your Cloudflare AI Gateway ID

   â

   â

   â enter
   ```
5. Enter your **Cloudflare API token**.

   ```
   â Gateway API token

   â

   â

   â enter
   ```
6. Run the `/models` command to select a model.

   ```
   /models
   ```

   You can also add models through your opencode config.

   opencode.json

   ```
   {

   "$schema": "https://opencode.ai/config.json",

   "provider": {

   "cloudflare-ai-gateway": {

   "models": {

   "openai/gpt-4o": {},

   "anthropic/claude-sonnet-4": {}

   }

   }

   }

   }
   ```

   Alternatively, you can set environment variables instead of using `/connect`.

   ~/.bash\_profile

   ```
   export CLOUDFLARE_ACCOUNT_ID=your-32-character-account-id

   export CLOUDFLARE_GATEWAY_ID=your-gateway-id

   export CLOUDFLARE_API_TOKEN=your-api-token
   ```

---

#### [Cloudflare Workers AI](#cloudflare-workers-ai)

Cloudflare Workers AI lets you run AI models on Cloudflareâs global network directly via REST API, with no separate provider accounts needed for supported models.

1. Head over to the [Cloudflare dashboard](https://dash.cloudflare.com/), navigate to **Workers AI**, and select **Use REST API** to get your **Account ID** and create an API token.
2. Run the `/connect` command and search for **Cloudflare Workers AI**.

   ```
   /connect
   ```
3. Enter your **Account ID** when prompted.

   ```
   â Enter your Cloudflare Account ID

   â

   â

   â enter
   ```
4. Enter your **Cloudflare API key**.

   ```
   â API key

   â

   â

   â enter
   ```
5. Run the `/models` command to select a model.

   ```
   /models
   ```

   Alternatively, you can set environment variables instead of using `/connect`.

   ~/.bash\_profile

   ```
   export CLOUDFLARE_ACCOUNT_ID=your-32-character-account-id

   export CLOUDFLARE_API_KEY=your-api-token
   ```

---

#### [Cortecs](#cortecs)

1. Head over to the [Cortecs console](https://cortecs.ai/), create an account, and generate an API key.
2. Run the `/connect` command and search for **Cortecs**.

   ```
   /connect
   ```
3. Enter your Cortecs API key.

   ```
   â API key

   â

   â

   â enter
   ```
4. Run the `/models` command to select a model like *Kimi K2 Instruct*.

   ```
   /models
   ```

---

#### [DeepSeek](#deepseek)

1. Head over to the [DeepSeek console](https://platform.deepseek.com/), create an account, and click **Create new API key**.
2. Run the `/connect` command and search for **DeepSeek**.

   ```
   /connect
   ```
3. Enter your DeepSeek API key.

   ```
   â API key

   â

   â

   â enter
   ```
4. Run the `/models` command to select a DeepSeek model like *DeepSeek V4 Pro*.

   ```
   /models
   ```

---

#### [Deep Infra](#deep-infra)

1. Head over to the [Deep Infra dashboard](https://deepinfra.com/dash), create an account, and generate an API key.
2. Run the `/connect` command and search for **Deep Infra**.

   ```
   /connect
   ```
3. Enter your Deep Infra API key.

   ```
   â API key

   â

   â

   â enter
   ```
4. Run the `/models` command to select a model.

   ```
   /models
   ```

---

#### [DigitalOcean](#digitalocean)

DigitalOceanâs [Inference Engine](https://docs.digitalocean.com/products/inference/) provides access to open models like GPT-OSS, Llama, Qwen, and DeepSeek, plus custom [Inference Routers](https://docs.digitalocean.com/products/inference/how-to/use-inference-router/) that route each request to the cheapest, fastest, or best-fit model for a task.

OpenCode supports two authentication methods:

* **OAuth (Recommended)** â Sign in to your DigitalOcean account; OpenCode uses your DigitalOcean API token directly for inference and discovers your Inference Routers.
* **Model Access Key** â Paste an existing key from the DigitalOcean console.

##### [OAuth (Recommended)](#oauth-recommended)

1. Run the `/connect` command and search for **DigitalOcean**.

   ```
   /connect
   ```
2. Select **Login with DigitalOcean**.

   ```
   â Select auth method

   â

   â Login with DigitalOcean

   â Paste Model Access Key

   â
   ```
3. Your browser opens to authorize OpenCode. Sign in and approve.

   Note

   OpenCode requests `genai:read` and `inference:query` OAuth scopes. Your DigitalOcean API token is used directly for inference â no separate Model Access Key is created.

   Note

   Inference Routers only appear in the model picker after OAuth. Pasting a Model Access Key manually does not discover routers.
4. Run the `/models` command. Your Inference Routers appear as the format `router:` in the model selection.

   ```
   /models
   ```
5. To pick up newly created Inference Routers, re-run `/connect` and select **DigitalOcean** again.

##### [Using a Model Access Key](#using-a-model-access-key)

If youâd rather paste a key directly:

1. Head over to the **Manage** page in the Inference section of the [DigitalOcean console](https://cloud.digitalocean.com/) and create a new key.
2. Run the `/connect` command and select **DigitalOcean**, then **Paste Model Access Key**.

   ```
   â Enter your DigitalOcean Model Access Key

   â

   â

   â enter
   ```

   Note

   Inference Routers are not auto-discovered with this method. To surface them in the model picker, sign in via OAuth instead.
3. Run the `/models` command to select a model.

   ```
   /models
   ```

##### [Environment Variable](#environment-variable)

Alternatively, set your Model Access Key as an environment variable.

```
export DIGITALOCEAN_ACCESS_TOKEN=your-model-access-key
```

##### [Inference Routers](#inference-routers)

Inference Routers let you define a routing policy across multiple models â picking the cheapest, fastest, or most appropriate model per request based on the task. After OAuth, OpenCode surfaces each router as `router:<router-name>` in the model picker.

Selecting a router model is a drop-in replacement for any other model â OpenCode forwards your request and DigitalOcean picks the underlying model based on your routerâs policy. Learn more about [Inference Routers](https://docs.digitalocean.com/products/inference/how-to/use-inference-router/)

---

#### [Eden AI](#eden-ai)

[Eden AI](https://www.edenai.co/) is an EU-based gateway that serves models from many vendors over a single OpenAI-compatible API, with a separate EU endpoint for teams that need inference to stay in the EU.

1. Head over to the [Eden AI platform](https://app.edenai.run/user/register) to create an account and generate an API key.
2. Run the `/connect` command and search for **Eden AI**.

   ```
   /connect
   ```
3. Enter your Eden AI API key.

   ```
   â API key

   â

   â

   â enter
   ```
4. Run the `/models` command to select a model like *Mistral Large 3* or *Claude Sonnet 5*.

   ```
   /models
   ```

   Eden AI model ids are themselves in `vendor/model` form, so a full reference has three segments, for example `edenai/anthropic/claude-sonnet-5`.
5. To keep requests on Eden AIâs EU gateway, set its base URL.

   opencode.json

   ```
   {

   "$schema": "https://opencode.ai/config.json",

   "provider": {

   "edenai": {

   "options": {

   "baseURL": "https://api.eu.edenai.run/v3"

   }

   }

   }

   }
   ```

   The default is `https://api.edenai.run/v3`, so this swaps the global endpoint for the EU one. The EU endpoint serves the subset of the catalog that is available in the EU, so a model chosen in step 4 may not be reachable through it.

---

#### [FrogBot](#frogbot)

1. Head over to the [FrogBot dashboard](https://app.frogbot.ai/signup), create an account, and generate an API key.
2. Run the `/connect` command and search for **FrogBot**.

   ```
   /connect
   ```
3. Enter your FrogBot API key.

   ```
   â API key

   â

   â

   â enter
   ```
4. Run the `/models` command to select a model.

   ```
   /models
   ```

---

#### [Fireworks AI](#fireworks-ai)

1. Head over to the [Fireworks AI console](https://app.fireworks.ai/), create an account, and click **Create API Key**.
2. Run the `/connect` command and search for **Fireworks AI**.

   ```
   /connect
   ```
3. Enter your Fireworks AI API key.

   ```
   â API key

   â

   â

   â enter
   ```
4. Run the `/models` command to select a model like *Kimi K2 Instruct*.

   ```
   /models
   ```

---

#### [GitLab Duo](#gitlab-duo)

Experimental

GitLab Duo support in OpenCode is experimental. Features, configuration, and
behavior may change in future releases.

OpenCode integrates with the [GitLab Duo Agent Platform](https://docs.gitlab.com/user/duo_agent_platform/),
providing AI-powered agentic chat with native tool calling capabilities.

License requirements

GitLab Duo Agent Platform requires a **Premium** or **Ultimate** GitLab
subscription. It is available on GitLab.com and GitLab Self-Managed.
See [GitLab Duo Agent Platform prerequisites](https://docs.gitlab.com/user/duo_agent_platform/#prerequisites)
for full requirements.

1. Run the `/connect` command and select GitLab.

   ```
   /connect
   ```
2. Choose your authentication method:

   ```
   â Select auth method

   â

   â OAuth (Recommended)

   â Personal Access Token

   â
   ```

   #### [Using OAuth (Recommended)](#using-oauth-recommended)

   Select **OAuth** and your browser will open for authorization.

   #### [Using Personal Access Token](#using-personal-access-token)

   1. Go to [GitLab User Settings > Access Tokens](https://gitlab.com/-/user_settings/personal_access_tokens)
   2. Click **Add new token**
   3. Name: `OpenCode`, Scopes: `api`
   4. Copy the token (starts with `glpat-`)
   5. Enter it in the terminal
3. Run the `/models` command to see available models.

   ```
   /models
   ```

   Three Claude-based models are available:

   * **duo-chat-haiku-4-5** (Default) - Fast responses for quick tasks
   * **duo-chat-sonnet-4-5** - Balanced performance for most workflows
   * **duo-chat-opus-4-5** - Most capable for complex analysis

Note

You can also specify âGITLAB\_TOKENâ environment variable if you donât want
to store token in opencode auth storage.

###### [Self-Hosted GitLab](#self-hosted-gitlab)

compliance note

OpenCode uses a small model for some AI tasks like generating the session title.
It is configured to use gpt-5-nano by default, hosted by Zen. To lock OpenCode
to only use your own GitLab-hosted instance, add the following to your
`opencode.json` file. It is also recommended to disable session sharing.

```
{

"$schema": "https://opencode.ai/config.json",

"small_model": "gitlab/duo-chat-haiku-4-5",

"share": "disabled"

}
```

For self-hosted GitLab instances:

Terminal window

```
export GITLAB_INSTANCE_URL=https://gitlab.company.com

export GITLAB_TOKEN=glpat-...
```

If your instance runs a custom AI Gateway:

Terminal window

```
GITLAB_AI_GATEWAY_URL=https://ai-gateway.company.com
```

Or add to your bash profile:

~/.bash\_profile

```
export GITLAB_INSTANCE_URL=https://gitlab.company.com

export GITLAB_AI_GATEWAY_URL=https://ai-gateway.company.com

export GITLAB_TOKEN=glpat-...
```

Note

Your GitLab administrator must:

1. [Turn on GitLab Duo](https://docs.gitlab.com/user/duo_agent_platform/turn_on_off/#turn-gitlab-duo-on-or-off)
   for the user, group, or instance
2. [Turn on the Agent Platform](https://docs.gitlab.com/user/duo_agent_platform/turn_on_off/#turn-gitlab-duo-agent-platform-on-or-off)
   (GitLab 18.8+) or [enable beta and experimental features](https://docs.gitlab.com/user/duo_agent_platform/turn_on_off/#turn-on-beta-and-experimental-features)
   (GitLab 18.7 and earlier)
3. For Self-Managed, [configure your instance](https://docs.gitlab.com/administration/gitlab_duo/configure/gitlab_self_managed/)

###### [OAuth for Self-Hosted instances](#oauth-for-self-hosted-instances)

OpenCodeâs bundled GitLab OAuth application only exists on gitlab.com. To use
OAuth with a self-hosted instance, create your own application (Settings â
Applications) with the callback URL `http://127.0.0.1:8080/callback`, the
`api` scope, and **Confidential** unchecked (PKCE requires a public client).

Then expose the application ID as an environment variable:

Terminal window

```
export GITLAB_OAUTH_CLIENT_ID=your_application_id_here
```

###### [Configuration](#configuration)

Customize through `opencode.json`:

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"provider": {

"gitlab": {

"options": {

"instanceUrl": "https://gitlab.com"

}

}

}

}
```

###### [GitLab Duo Agent Platform (DAP) Workflow Models](#gitlab-duo-agent-platform-dap-workflow-models)

DAP workflow models provide an alternative execution path that routes tool calls
through GitLabâs Duo Workflow Service (DWS) instead of the standard agentic chat.
When a `duo-workflow-*` model is selected, OpenCode will:

1. Discover available models from your GitLab namespace
2. Present a selection picker if multiple models are available
3. Cache the selected model to disk for fast subsequent startups
4. Route tool execution requests through OpenCodeâs permission-gated tool system

Available DAP workflow models follow the `duo-workflow-*` naming convention and
are dynamically discovered from your GitLab instance.

Note

Workflow model discovery only runs for a login stored with `/connect` (OAuth or
a personal access token). A `GITLAB_TOKEN` environment variable on its own does
not trigger discovery.

###### [GitLab API Tools (Optional, but highly recommended)](#gitlab-api-tools-optional-but-highly-recommended)

To access GitLab tools (merge requests, issues, pipelines, CI/CD, etc.):

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"plugin": ["opencode-gitlab-plugin"]

}
```

This plugin provides comprehensive GitLab repository management capabilities including MR reviews, issue tracking, pipeline monitoring, and more.

---

#### [GitHub Copilot](#github-copilot)

To use your GitHub Copilot subscription with opencode:

Note

Some models might need a [Pro+
subscription](https://github.com/features/copilot/plans) to use.

1. Run the `/connect` command and search for GitHub Copilot.

   ```
   /connect
   ```
2. Navigate to [github.com/login/device](https://github.com/login/device) and enter the code.

   ```
   â Login with GitHub Copilot

   â

   â https://github.com/login/device

   â

   â Enter code: 8F43-6FCF

   â

   â Waiting for authorization...
   ```
3. Now run the `/models` command to select the model you want.

   ```
   /models
   ```

---

#### [GMI Cloud](#gmi-cloud)

To use GMI Cloud with OpenCode:

1. Head over to the [GMI Cloud console](https://console.gmicloud.ai/) to create an API key. You can also review the [API reference](https://docs.gmicloud.ai/inference-engine/api-reference/llm-api-reference) for the endpoint details.
2. Run the `/connect` command and search for **GMI Cloud**.

   ```
   /connect
   ```
3. Enter your GMI Cloud API key.

   ```
   â API key

   â

   â

   â enter
   ```
4. Run the `/models` command to select the model you want.

   ```
   /models
   ```

---

#### [Google Vertex AI](#google-vertex-ai)

To use Google Vertex AI with OpenCode:

1. Head over to the **Model Garden** in the Google Cloud Console and check the
   models available in your region.

   Note

   You need to have a Google Cloud project with Vertex AI API enabled.
2. Set the required environment variables:

   * `GOOGLE_CLOUD_PROJECT`: Your Google Cloud project ID
   * `VERTEX_LOCATION` (optional): The region for Vertex AI (defaults to `global`)
   * Authentication (choose one):
     + `GOOGLE_APPLICATION_CREDENTIALS`: Path to your service account JSON key file
     + Authenticate using gcloud CLI: `gcloud auth application-default login`

   Set them while running opencode.

   Terminal window

   ```
   GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json GOOGLE_CLOUD_PROJECT=your-project-id opencode
   ```

   Or add them to your bash profile.

   ~/.bash\_profile

   ```
   export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json

   export GOOGLE_CLOUD_PROJECT=your-project-id

   export VERTEX_LOCATION=global
   ```

Tip

The `global` region improves availability and reduces errors at no extra cost. Use regional endpoints (e.g., `us-central1`) for data residency requirements. [Learn more](https://cloud.google.com/vertex-ai/generative-ai/docs/partner-models/use-partner-models#regional_and_global_endpoints)

3. Run the `/models` command to select the model you want.

   ```
   /models
   ```

---

#### [Groq](#groq)

1. Head over to the [Groq console](https://console.groq.com/), click **Create API Key**, and copy the key.
2. Run the `/connect` command and search for Groq.

   ```
   /connect
   ```
3. Enter the API key for the provider.

   ```
   â API key

   â

   â

   â enter
   ```
4. Run the `/models` command to select the one you want.

   ```
   /models
   ```

---

#### [Hugging Face](#hugging-face)

[Hugging Face Inference Providers](https://huggingface.co/docs/inference-providers) provides access to open models supported by 17+ providers.

1. Head over to [Hugging Face settings](https://huggingface.co/settings/tokens/new?ownUserPermissions=inference.serverless.write&tokenType=fineGrained) to create a token with permission to make calls to Inference Providers.
2. Run the `/connect` command and search for **Hugging Face**.

   ```
   /connect
   ```
3. Enter your Hugging Face token.

   ```
   â API key

   â

   â

   â enter
   ```
4. Run the `/models` command to select a model like *Kimi-K2-Instruct* or *GLM-4.6*.

   ```
   /models
   ```

---

#### [Helicone](#helicone)

[Helicone](https://helicone.ai) is an LLM observability platform that provides logging, monitoring, and analytics for your AI applications. The Helicone AI Gateway routes your requests to the appropriate provider automatically based on the model.

1. Head over to [Helicone](https://helicone.ai), create an account, and generate an API key from your dashboard.
2. Run the `/connect` command and search for **Helicone**.

   ```
   /connect
   ```
3. Enter your Helicone API key.

   ```
   â API key

   â

   â

   â enter
   ```
4. Run the `/models` command to select a model.

   ```
   /models
   ```

For more providers and advanced features like caching and rate limiting, check the [Helicone documentation](https://docs.helicone.ai).

##### [Optional Configs](#optional-configs)

In the event you see a feature or model from Helicone that isnât configured automatically through opencode, you can always configure it yourself.

Hereâs [Heliconeâs Model Directory](https://helicone.ai/models), youâll need this to grab the IDs of the models you want to add.

~/.config/opencode/opencode.jsonc

```
{

"$schema": "https://opencode.ai/config.json",

"provider": {

"helicone": {

"npm": "@ai-sdk/openai-compatible",

"name": "Helicone",

"options": {

"baseURL": "https://ai-gateway.helicone.ai",

},

"models": {

"gpt-4o": {

// Model ID (from Helicone's model directory page)

"name": "GPT-4o", // Your own custom name for the model

},

"claude-sonnet-4-20250514": {

"name": "Claude Sonnet 4",

},

},

},

},

}
```

##### [Custom Headers](#custom-headers)

Helicone supports custom headers for features like caching, user tracking, and session management. Add them to your provider config using `options.headers`:

~/.config/opencode/opencode.jsonc

```
{

"$schema": "https://opencode.ai/config.json",

"provider": {

"helicone": {

"npm": "@ai-sdk/openai-compatible",

"name": "Helicone",

"options": {

"baseURL": "https://ai-gateway.helicone.ai",

"headers": {

"Helicone-Cache-Enabled": "true",

"Helicone-User-Id": "opencode",

},

},

},

},

}
```

###### [Session tracking](#session-tracking)

Heliconeâs [Sessions](https://docs.helicone.ai/features/sessions) feature lets you group related LLM requests together. Use the [opencode-helicone-session](https://github.com/H2Shami/opencode-helicone-session) plugin to automatically log each OpenCode conversation as a session in Helicone.

Terminal window

```
npm install -g opencode-helicone-session
```

Add it to your config.

opencode.json

```
{

"plugin": ["opencode-helicone-session"]

}
```

The plugin injects `Helicone-Session-Id` and `Helicone-Session-Name` headers into your requests. In Heliconeâs Sessions page, youâll see each OpenCode conversation listed as a separate session.

###### [Common Helicone headers](#common-helicone-headers)

| Header | Description |
| --- | --- |
| `Helicone-Cache-Enabled` | Enable response caching (`true`/`false`) |
| `Helicone-User-Id` | Track metrics by user |
| `Helicone-Property-[Name]` | Add custom properties (e.g., `Helicone-Property-Environment`) |
| `Helicone-Prompt-Id` | Associate requests with prompt versions |

See the [Helicone Header Directory](https://docs.helicone.ai/helicone-headers/header-directory) for all available headers.

---

#### [llama.cpp](#llamacpp)

You can configure opencode to use local models through [llama.cppâs](https://github.com/ggml-org/llama.cpp) llama-server utility

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"provider": {

"llama.cpp": {

"npm": "@ai-sdk/openai-compatible",

"name": "llama-server (local)",

"options": {

"baseURL": "http://127.0.0.1:8080/v1"

},

"models": {

"qwen3-coder:a3b": {

"name": "Qwen3-Coder: a3b-30b (local)",

"limit": {

"context": 128000,

"output": 65536

}

}

}

}

}

}
```

In this example:

* `llama.cpp` is the custom provider ID. This can be any string you want.
* `npm` specifies the package to use for this provider. Here, `@ai-sdk/openai-compatible` is used for any OpenAI-compatible API.
* `name` is the display name for the provider in the UI.
* `options.baseURL` is the endpoint for the local server.
* `models` is a map of model IDs to their configurations. The model name will be displayed in the model selection list.

---

#### [IO.NET](#ionet)

IO.NET offers 17 models optimized for various use cases:

1. Head over to the [IO.NET console](https://ai.io.net/), create an account, and generate an API key.
2. Run the `/connect` command and search for **IO.NET**.

   ```
   /connect
   ```
3. Enter your IO.NET API key.

   ```
   â API key

   â

   â

   â enter
   ```
4. Run the `/models` command to select a model.

   ```
   /models
   ```

---

#### [LM Studio](#lm-studio)

You can configure opencode to use local models through LM Studio.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"provider": {

"lmstudio": {

"npm": "@ai-sdk/openai-compatible",

"name": "LM Studio (local)",

"options": {

"baseURL": "http://127.0.0.1:1234/v1"

},

"models": {

"google/gemma-3n-e4b": {

"name": "Gemma 3n-e4b (local)"

}

}

}

}

}
```

In this example:

* `lmstudio` is the custom provider ID. This can be any string you want.
* `npm` specifies the package to use for this provider. Here, `@ai-sdk/openai-compatible` is used for any OpenAI-compatible API.
* `name` is the display name for the provider in the UI.
* `options.baseURL` is the endpoint for the local server.
* `models` is a map of model IDs to their configurations. The model name will be displayed in the model selection list.

---

#### [Moonshot AI](#moonshot-ai)

To use Kimi K2 from Moonshot AI:

1. Head over to the [Moonshot AI console](https://platform.moonshot.ai/console), create an account, and click **Create API key**.
2. Run the `/connect` command and search for **Moonshot AI**.

   ```
   /connect
   ```
3. Enter your Moonshot API key.

   ```
   â API key

   â

   â

   â enter
   ```
4. Run the `/models` command to select *Kimi K2*.

   ```
   /models
   ```

---

#### [MiniMax](#minimax)

1. Head over to the [MiniMax API Console](https://platform.minimax.io/login), create an account, and generate an API key.
2. Run the `/connect` command and search for **MiniMax**.

   ```
   /connect
   ```
3. Enter your MiniMax API key.

   ```
   â API key

   â

   â

   â enter
   ```
4. Run the `/models` command to select a model like *M2.1*.

   ```
   /models
   ```

---

#### [Modal](#modal)

1. Create a [shared Endpoint](https://modal.com/endpoints) for the model you want to use.
2. Create a [proxy token](https://modal.com/docs/guide/endpoints#proxy-tokens), then join its ID and secret with a period:

   ```
   wk-<id>.ws-<secret>
   ```
3. Run the `/connect` command, search for **Modal**, and enter the combined proxy token.

   ```
   /connect
   ```
4. Run the `/models` command to select one of the endpoints in your Modal workspace.

   ```
   /models
   ```

---

#### [NVIDIA](#nvidia)

NVIDIA provides access to Nemotron models and many other open models through [build.nvidia.com](https://build.nvidia.com) for free.

1. Head over to [build.nvidia.com](https://build.nvidia.com), create an account, and generate an API key.
2. Run the `/connect` command and search for **NVIDIA**.

   ```
   /connect
   ```
3. Enter your NVIDIA API key.

   ```
   â API key

   â

   â

   â enter
   ```
4. Run the `/models` command to select a model like nemotron-3-super-120b-a12b.

   ```
   /models
   ```

##### [On-Prem / NIM](#on-prem--nim)

You can also use NVIDIA models locally via [NVIDIA NIM](https://docs.nvidia.com/nim/) by setting a custom base URL.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"provider": {

"nvidia": {

"options": {

"baseURL": "http://localhost:8000/v1"

}

}

}

}
```

##### [Environment Variable](#environment-variable-1)

Alternatively, set your API key as an environment variable.

```
export NVIDIA_API_KEY=nvapi-your-key-here
```

---

#### [Nebius Token Factory](#nebius-token-factory)

1. Head over to the [Nebius Token Factory console](https://tokenfactory.nebius.com/), create an account, and click **Add Key**.
2. Run the `/connect` command and search for **Nebius Token Factory**.

   ```
   /connect
   ```
3. Enter your Nebius Token Factory API key.

   ```
   â API key

   â

   â

   â enter
   ```
4. Run the `/models` command to select a model like *Kimi K2 Instruct*.

   ```
   /models
   ```

---

#### [Ollama](#ollama)

You can configure opencode to use local models through Ollama.

Tip

Ollama can automatically configure itself for OpenCode. See the [Ollama integration docs](https://docs.ollama.com/integrations/opencode) for details.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"provider": {

"ollama": {

"npm": "@ai-sdk/openai-compatible",

"name": "Ollama (local)",

"options": {

"baseURL": "http://localhost:11434/v1"

},

"models": {

"llama2": {

"name": "Llama 2"

}

}

}

}

}
```

In this example:

* `ollama` is the custom provider ID. This can be any string you want.
* `npm` specifies the package to use for this provider. Here, `@ai-sdk/openai-compatible` is used for any OpenAI-compatible API.
* `name` is the display name for the provider in the UI.
* `options.baseURL` is the endpoint for the local server.
* `models` is a map of model IDs to their configurations. The model name will be displayed in the model selection list.

Tip

If tool calls arenât working, try increasing `num_ctx` in Ollama. Start around 16k - 32k.

---

#### [Ollama Cloud](#ollama-cloud)

To use Ollama Cloud with OpenCode:

1. Head over to <https://ollama.com/> and sign in or create an account.
2. Navigate to **Settings** > **Keys** and click **Add API Key** to generate a new API key.
3. Copy the API key for use in OpenCode.
4. Run the `/connect` command and search for **Ollama Cloud**.

   ```
   /connect
   ```
5. Enter your Ollama Cloud API key.

   ```
   â API key

   â

   â

   â enter
   ```
6. **Important**: Before using cloud models in OpenCode, you must pull the model information locally:

   Terminal window

   ```
   ollama pull gpt-oss:20b-cloud
   ```
7. Run the `/models` command to select your Ollama Cloud model.

   ```
   /models
   ```

---

#### [OpenAI](#openai)

We recommend signing up for [ChatGPT Plus or Pro](https://chatgpt.com/pricing).

1. Once youâve signed up, run the `/connect` command and select OpenAI.

   ```
   /connect
   ```
2. Here you can select the **ChatGPT Plus/Pro** option and itâll open your browser
   and ask you to authenticate.

   ```
   â Select auth method

   â

   â ChatGPT Plus/Pro

   â Manually enter API Key

   â
   ```
3. Now all the OpenAI models should be available when you use the `/models` command.

   ```
   /models
   ```

###### [Compute residency](#compute-residency)

For ChatGPT OAuth, OpenCode automatically applies a regional inference residency requirement when one is advertised by your workspace credentials. It forwards the compute residency value from the credential instead of maintaining a fixed list of regions. Data residency at rest does not imply regional inference.

###### [Using API keys](#using-api-keys)

If you already have an API key, you can select **Manually enter API Key** and paste it in your terminal.

---

#### [OpenCode Zen](#opencode-zen-1)

OpenCode Zen is a list of tested and verified models provided by the OpenCode team. [Learn more](https://opencode.ai/v2/docs/console/).

1. Sign in to **[OpenCode Zen](https://opencode.ai/auth)** and click **Create API Key**.
2. Run the `/connect` command and search for **OpenCode Zen**.

   ```
   /connect
   ```
3. Enter your OpenCode API key.

   ```
   â API key

   â

   â

   â enter
   ```
4. Run the `/models` command to select a model like *Qwen 3 Coder 480B*.

   ```
   /models
   ```

---

#### [OpenRouter](#openrouter)

1. Head over to the [OpenRouter dashboard](https://openrouter.ai/settings/keys), click **Create API Key**, and copy the key.
2. Run the `/connect` command and search for OpenRouter.

   ```
   /connect
   ```
3. Enter the API key for the provider.

   ```
   â API key

   â

   â

   â enter
   ```
4. Many OpenRouter models are preloaded by default, run the `/models` command to select the one you want.

   ```
   /models
   ```

   You can also add additional models through your opencode config.

   opencode.json

   ```
   {

   "$schema": "https://opencode.ai/config.json",

   "provider": {

   "openrouter": {

   "models": {

   "somecoolnewmodel": {}

   }

   }

   }

   }
   ```
5. You can also customize them through your opencode config. Hereâs an example of specifying a provider

   opencode.json

   ```
   {

   "$schema": "https://opencode.ai/config.json",

   "provider": {

   "openrouter": {

   "models": {

   "moonshotai/kimi-k2": {

   "options": {

   "provider": {

   "order": ["baseten"],

   "allow_fallbacks": false

   }

   }

   }

   }

   }

   }

   }
   ```

---

#### [LLM Gateway](#llm-gateway)

1. Head over to the [LLM Gateway dashboard](https://llmgateway.io/dashboard), click **Create API Key**, and copy the key.
2. Run the `/connect` command and search for LLM Gateway.

   ```
   /connect
   ```
3. Enter the API key for the provider.

   ```
   â API key

   â

   â

   â enter
   ```
4. Many LLM Gateway models are preloaded by default, run the `/models` command to select the one you want.

   ```
   /models
   ```

   You can also add additional models through your opencode config.

   opencode.json

   ```
   {

   "$schema": "https://opencode.ai/config.json",

   "provider": {

   "llmgateway": {

   "models": {

   "somecoolnewmodel": {}

   }

   }

   }

   }
   ```
5. You can also customize them through your opencode config. Hereâs an example of specifying a provider

   opencode.json

   ```
   {

   "$schema": "https://opencode.ai/config.json",

   "provider": {

   "llmgateway": {

   "models": {

   "glm-4.7": {

   "name": "GLM 4.7"

   },

   "gpt-5.2": {

   "name": "GPT-5.2"

   },

   "gemini-2.5-pro": {

   "name": "Gemini 2.5 Pro"

   },

   "claude-3-5-sonnet-20241022": {

   "name": "Claude 3.5 Sonnet"

   }

   }

   }

   }

   }
   ```

---

#### [Poolside](#poolside)

[Poolside](https://poolside.ai) provides access to its models through an OpenAI-compatible API.

1. Head over to [platform.poolside.ai](https://platform.poolside.ai), sign in, open the **API Keys** tab, and click **New key** to generate an API key.
2. Run the `/connect` command and search for **Poolside**.

   ```
   /connect
   ```
3. Enter your Poolside API key.

   ```
   â API key

   â

   â

   â enter
   ```
4. Run the `/models` command to select a model.

   ```
   /models
   ```

##### [Poolside deployment](#poolside-deployment)

If your organization runs a Poolside deployment, configure it as a custom OpenAI-compatible provider. Store the API key or token from your Poolside administrator in `~/.secrets/poolside-key`. Use a unique provider ID and add the model IDs available from your deployment.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"provider": {

"poolside-deployment": {

"npm": "@ai-sdk/openai-compatible",

"name": "Poolside deployment",

"options": {

"baseURL": "https://poolside.example.com/openai/v1",

"apiKey": "{file:~/.secrets/poolside-key}"

},

"models": {

"<served-model-id>": {

"name": "Poolside deployment model",

"reasoning": true,

"interleaved": {

"field": "reasoning_content"

}

}

}

}

}

}
```

Replace `poolside.example.com` with your deploymentâs host and `<served-model-id>` with a model ID returned by its `/openai/v1/models` endpoint. Model availability and thinking behavior depend on the deploymentâs configuration.

Tip

You can also install [Poolside Agent CLI](https://github.com/poolsideai/pool) to use Poolside agents directly from your terminal.

---

#### [SAP AI Core](#sap-ai-core)

SAP AI Core provides access to 40+ models from OpenAI, Anthropic, Google, Amazon, Meta, Mistral, and AI21 through a unified platform.

1. Go to your [SAP BTP Cockpit](https://account.hana.ondemand.com/), navigate to your SAP AI Core service instance, and create a service key.

   Tip

   The service key is a JSON object containing `clientid`, `clientsecret`, `url`, and `serviceurls.AI_API_URL`. You can find your AI Core instance under **Services** > **Instances and Subscriptions** in the BTP Cockpit.
2. Run the `/connect` command and search for **SAP AI Core**.

   ```
   /connect
   ```
3. Enter your service key JSON.

   ```
   â Service key

   â

   â

   â enter
   ```

   Or set the `AICORE_SERVICE_KEY` environment variable:

   Terminal window

   ```
   AICORE_SERVICE_KEY='{"clientid":"...","clientsecret":"...","url":"...","serviceurls":{"AI_API_URL":"..."}}' opencode
   ```

   Or add it to your bash profile:

   ~/.bash\_profile

   ```
   export AICORE_SERVICE_KEY='{"clientid":"...","clientsecret":"...","url":"...","serviceurls":{"AI_API_URL":"..."}}'
   ```
4. Optionally set deployment ID and resource group:

   Terminal window

   ```
   AICORE_DEPLOYMENT_ID=your-deployment-id AICORE_RESOURCE_GROUP=your-resource-group opencode
   ```

   Note

   These settings are optional and should be configured according to your SAP AI Core setup.
5. Run the `/models` command to select from 40+ available models.

   ```
   /models
   ```

---

#### [STACKIT](#stackit)

STACKIT AI Model Serving provides fully managed sovereign hosting environment for AI models, focusing on LLMs like Llama, Mistral, and Qwen, with maximum data sovereignty on European infrastructure.

1. Head over to [STACKIT Portal](https://portal.stackit.cloud), navigate to **AI Model Serving**, and create an auth token for your project.

   Tip

   You need a STACKIT customer account, user account, and project before creating auth tokens.
2. Run the `/connect` command and search for **STACKIT**.

   ```
   /connect
   ```
3. Enter your STACKIT AI Model Serving auth token.

   ```
   â API key

   â

   â

   â enter
   ```
4. Run the `/models` command to select from available models like *Qwen3-VL 235B* or *Llama 3.3 70B*.

   ```
   /models
   ```

---

#### [OVHcloud AI Endpoints](#ovhcloud-ai-endpoints)

1. Head over to the [OVHcloud panel](https://ovh.com/manager). Navigate to the `Public Cloud` section, `AI & Machine Learning` > `AI Endpoints` and in `API Keys` tab, click **Create a new API key**.
2. Run the `/connect` command and search for **OVHcloud AI Endpoints**.

   ```
   /connect
   ```
3. Enter your OVHcloud AI Endpoints API key.

   ```
   â API key

   â

   â

   â enter
   ```
4. Run the `/models` command to select a model like *gpt-oss-120b*.

   ```
   /models
   ```

---

#### [Scaleway](#scaleway)

To use [Scaleway Generative APIs](https://www.scaleway.com/en/docs/generative-apis/) with Opencode:

1. Head over to the [Scaleway Console IAM settings](https://console.scaleway.com/iam/api-keys) to generate a new API key.
2. Run the `/connect` command and search for **Scaleway**.

   ```
   /connect
   ```
3. Enter your Scaleway API key.

   ```
   â API key

   â

   â

   â enter
   ```
4. Run the `/models` command to select a model like *devstral-2-123b-instruct-2512* or *gpt-oss-120b*.

   ```
   /models
   ```

---

#### [SCX.ai](#scxai)

[SCX.ai](https://scx.ai) is an Australian sovereign AI platform serving open models over an OpenAI-compatible API, hosted on renewable-powered infrastructure in Australia.

1. Head over to the [SCX.ai platform](https://platform.scx.ai) to create an account and generate an API key.
2. Run the `/connect` command and search for **SCX.ai**.

   ```
   /connect
   ```
3. Enter your SCX.ai API key.

   ```
   â API key

   â

   â

   â enter
   ```
4. Run the `/models` command to select a model like *MiniMax-M2.7* or *GLM-5.2*.

   ```
   /models
   ```

---

#### [Snowflake Cortex](#snowflake-cortex)

[Snowflake Cortex](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-rest-api) gives you access to frontier models (Claude, OpenAI GPT-5, and more) via an OpenAI-compatible API. All inference runs within the Snowflake perimeter and is billed in Snowflake credits. For per-model rates, see the [Snowflake Service Consumption Table](https://www.snowflake.com/legal-files/CreditConsumptionTable.pdf).

Donât have a Snowflake account? [Sign up for a free trial](https://signup.snowflake.com/?utm_source=opencode&utm_medium=docs&utm_campaign=cortex-provider).

opencodeâs core workflow for coding, editing files, and running commands relies on tool calling. Only the Claude and OpenAI families within Snowflake Cortex support this. The provider is limited to those families to support the core workflow.

OpenCode supports two authentication methods:

* **Browser OAuth (Recommended)** â sign in with your IdP/SSO; no secrets to manage, tokens refresh automatically.
* **Manual bearer token** â paste a PAT or JWT from the Snowflake console.

##### [Browser OAuth (Recommended)](#browser-oauth-recommended)

1. Run the `/connect` command and search for **Snowflake Cortex**.

   ```
   /connect
   ```
2. Select **Login with Snowflake (External Browser)**.

   ```
   â Select auth method

   â

   â Login with Snowflake (External Browser)

   â Paste PAT or bearer token manually

   â
   ```
3. Enter your [account identifier](https://docs.snowflake.com/en/user-guide/admin-account-identifier) when prompted, for example `myorg-myaccount` or `xy12345.us-east-1`.

   ```
   â Snowflake Account Identifier

   â

   â

   â enter
   ```
4. Optionally enter a Snowflake role to scope the session (e.g. `SYSADMIN`). Leave blank to use your default role.
5. Complete sign-in in the browser that opens. OpenCode captures the OAuth callback automatically and stores the token â no copy/paste needed.
6. Run the `/models` command to select a model.

   ```
   /models
   ```

Note

Browser OAuth uses Snowflakeâs built-in `SNOWFLAKE$LOCAL_APPLICATION` security integration ([docs](https://docs.snowflake.com/en/user-guide/oauth-local-applications)), which is rolling out to all accounts. To check availability in your account:

```
SHOW SECURITY INTEGRATIONS LIKE 'SNOWFLAKE$LOCAL_APPLICATION';
```

If the result is empty, use the **Manual bearer token** method below while the integration rolls out to your account.

##### [Manual bearer token](#manual-bearer-token)

If you prefer to paste a token directly, or if `SNOWFLAKE$LOCAL_APPLICATION` is not yet available in your account:

1. Generate a [Programmatic Access Token (PAT)](https://docs.snowflake.com/en/user-guide/programmatic-access-tokens) in your Snowflake account.
2. Run the `/connect` command, search for **Snowflake Cortex**, and select **Paste PAT or bearer token manually**.
3. Enter your [account identifier](https://docs.snowflake.com/en/user-guide/admin-account-identifier) when prompted.
4. Paste your PAT.
5. Run the `/models` command to select a model.

   ```
   /models
   ```

##### [Environment variable](#environment-variable-2)

For CI or headless environments, set a PAT or JWT before starting opencode:

Terminal window

```
export SNOWFLAKE_ACCOUNT=myorg-myaccount

export SNOWFLAKE_CORTEX_TOKEN=your-pat-or-jwt
```

Note

`SNOWFLAKE_CORTEX_TOKEN` accepts a PAT or JWT only â the browser OAuth flow is available via `/connect` only and cannot be configured through an environment variable. `SNOWFLAKE_CORTEX_PAT` is still supported for backward compatibility.

The model catalog is provided automatically. A minimal `opencode.json` is all thatâs needed:

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"model": "snowflake-cortex/claude-sonnet-4-6",

"small_model": "snowflake-cortex/claude-haiku-4-5"

}
```

---

#### [Together AI](#together-ai)

1. Head over to the [Together AI console](https://api.together.ai), create an account, and click **Add Key**.
2. Run the `/connect` command and search for **Together AI**.

   ```
   /connect
   ```
3. Enter your Together AI API key.

   ```
   â API key

   â

   â

   â enter
   ```
4. Run the `/models` command to select a model like *Kimi K2 Instruct*.

   ```
   /models
   ```

---

#### [Venice AI](#venice-ai)

1. Head over to the [Venice AI console](https://venice.ai), create an account, and generate an API key.
2. Run the `/connect` command and search for **Venice AI**.

   ```
   /connect
   ```
3. Enter your Venice AI API key.

   ```
   â API key

   â

   â

   â enter
   ```
4. Run the `/models` command to select a model like *Llama 3.3 70B*.

   ```
   /models
   ```

---

#### [Vercel AI Gateway](#vercel-ai-gateway)

Vercel AI Gateway lets you access models from OpenAI, Anthropic, Google, xAI, and more through a unified endpoint. Models are offered at list price with no markup.

1. Head over to the [Vercel dashboard](https://vercel.com/), navigate to the **AI Gateway** tab, and click **API keys** to create a new API key.
2. Run the `/connect` command and search for **Vercel AI Gateway**.

   ```
   /connect
   ```
3. Enter your Vercel AI Gateway API key.

   ```
   â API key

   â

   â

   â enter
   ```
4. Run the `/models` command to select a model.

   ```
   /models
   ```

You can also customize models through your opencode config. Hereâs an example of specifying provider routing order.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"provider": {

"vercel": {

"models": {

"anthropic/claude-sonnet-4": {

"options": {

"order": ["anthropic", "vertex"]

}

}

}

}

}

}
```

Some useful routing options:

| Option | Description |
| --- | --- |
| `order` | Provider sequence to try |
| `only` | Restrict to specific providers |
| `zeroDataRetention` | Only use providers with zero data retention policies |

---

#### [xAI](#xai)

Two ways to authenticate: a SuperGrok subscription via device-code OAuth or a pay-as-you-go API key from the xAI console.

##### [Option A â SuperGrok subscription](#option-a--supergrok-subscription)

1. Run the `/connect` command and search for **xAI**.

   ```
   /connect
   ```
2. Select **SuperGrok Subscription**. OpenCode opens xAIâs verification link with the user code pre-populated when supported.
3. Approve the consent screen. If xAI asks for a code, enter the user code displayed by OpenCode. OpenCode polls xAIâs token endpoint and stores the resulting OAuth tokens once you approve.
4. Run the `/models` command to select a Grok model.

   ```
   /models
   ```

OpenCode refreshes the OAuth access token automatically. Any Grok or X Premium plan that includes Grok API access works; you do not need a separate `XAI_API_KEY`.

##### [Option B â API key](#option-b--api-key)

1. Head over to the [xAI console](https://console.x.ai/), create an account, and generate an API key.
2. Run the `/connect` command and search for **xAI**.

   ```
   /connect
   ```
3. Select **Manually enter API Key** and paste your xAI API key.

   ```
   â API key

   â

   â

   â enter
   ```
4. Run the `/models` command to select a model like *Grok Beta*.

   ```
   /models
   ```

---

#### [Z.AI](#zai)

1. Head over to the [Z.AI API console](https://z.ai/manage-apikey/apikey-list), create an account, and click **Create a new API key**.
2. Run the `/connect` command and search for **Z.AI**.

   ```
   /connect
   ```

   If you are subscribed to the **GLM Coding Plan**, select **Z.AI Coding Plan**.
3. Enter your Z.AI API key.

   ```
   â API key

   â

   â

   â enter
   ```
4. Run the `/models` command to select a model like *GLM-4.7*.

   ```
   /models
   ```

---

#### [ZenMux](#zenmux)

1. Head over to the [ZenMux dashboard](https://zenmux.ai/settings/keys), click **Create API Key**, and copy the key.
2. Run the `/connect` command and search for ZenMux.

   ```
   /connect
   ```
3. Enter the API key for the provider.

   ```
   â API key

   â

   â

   â enter
   ```
4. Many ZenMux models are preloaded by default, run the `/models` command to select the one you want.

   ```
   /models
   ```

   You can also add additional models through your opencode config.

   opencode.json

   ```
   {

   "$schema": "https://opencode.ai/config.json",

   "provider": {

   "zenmux": {

   "models": {

   "somecoolnewmodel": {}

   }

   }

   }

   }
   ```

---

### [Custom provider](#custom-provider)

To add any **OpenAI-compatible** provider thatâs not listed in the `/connect` command:

Tip

You can use any OpenAI-compatible provider with opencode. Most modern AI providers offer OpenAI-compatible APIs.

1. Run the `/connect` command and scroll down to **Other**.

   Terminal window

   ```
   $ /connect

   â  Add credential

   â

   â  Select provider

   â  ...

   â  â Other

   â
   ```
2. Enter a unique ID for the provider.

   Terminal window

   ```
   $ /connect

   â  Add credential

   â

   â  Enter provider id

   â  myprovider

   â
   ```

   Note

   Choose a memorable ID, youâll use this in your config file.
3. Enter your API key for the provider.

   Terminal window

   ```
   $ /connect

   â  Add credential

   â

   â²  This only stores a credential for myprovider - you will need to configure it in opencode.json, check the docs for examples.

   â

   â  Enter your API key

   â  sk-...

   â
   ```
4. Create or update your `opencode.json` file in your project directory:

   opencode.json

   ```
   {

   "$schema": "https://opencode.ai/config.json",

   "provider": {

   "myprovider": {

   "npm": "@ai-sdk/openai-compatible",

   "name": "My AI Provider Display Name",

   "options": {

   "baseURL": "https://api.myprovider.com/v1"

   },

   "models": {

   "my-model-name": {

   "name": "My Model Display Name"

   }

   }

   }

   }

   }
   ```

   Here are the configuration options:

   * **npm**: AI SDK package to use, `@ai-sdk/openai-compatible` for OpenAI-compatible providers (for `/v1/chat/completions`). If your provider/model uses `/v1/responses`, use `@ai-sdk/openai`.
   * **name**: Display name in UI.
   * **models**: Available models.
   * **options.baseURL**: API endpoint URL.
   * **options.apiKey**: Optionally set the API key, if not using auth.
   * **options.headers**: Optionally set custom headers.

   More on the advanced options in the example below.
5. Run the `/models` command and your custom provider and models will appear in the selection list.

---

###### [Example](#example)

Hereâs an example setting the `apiKey`, `headers`, and model `limit` options.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"provider": {

"myprovider": {

"npm": "@ai-sdk/openai-compatible",

"name": "My AI Provider Display Name",

"options": {

"baseURL": "https://api.myprovider.com/v1",

"apiKey": "{env:ANTHROPIC_API_KEY}",

"headers": {

"Authorization": "Bearer custom-token"

}

},

"models": {

"my-model-name": {

"name": "My Model Display Name",

"limit": {

"context": 200000,

"output": 65536

}

}

}

}

}

}
```

Configuration details:

* **apiKey**: Set using `env` variable syntax, [learn more](/docs/config#env-vars).
* **headers**: Custom headers sent with each request.
* **limit.context**: Maximum input tokens the model accepts.
* **limit.output**: Maximum tokens the model can generate.

The `limit` fields allow OpenCode to understand how much context you have left. Standard providers pull these from models.dev automatically.

---

### [Troubleshooting](#troubleshooting)

If you are having trouble with configuring a provider, check the following:

1. **Check the auth setup**: Run `opencode auth list` to see if the credentials
   for the provider are added to your config.

   This doesnât apply to providers like Amazon Bedrock, that rely on environment variables for their auth.
2. For custom providers, check the opencode config and:

   * Make sure the provider ID used in the `/connect` command matches the ID in your opencode config.
   * The right npm package is used for the provider. For example, use `@ai-sdk/cerebras` for Cerebras. And for all other OpenAI-compatible providers, use `@ai-sdk/openai-compatible` (for `/v1/chat/completions`); if a model uses `/v1/responses`, use `@ai-sdk/openai`. For mixed setups under one provider, you can override per model via `provider.npm`.
   * Check correct API endpoint is used in the `options.baseURL` field.

[Edit page](https://github.com/anomalyco/opencode/edit/dev/packages/web/src/content/docs/providers.mdx)[Found a bug? Open an issue](https://github.com/anomalyco/opencode/issues/new)[Join our Discord community](https://opencode.ai/discord)  Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

© [Anomaly](https://anoma.ly)

Last updated: Oct 13, 2026

---
<!--
URL: https://opencode.ai/docs/troubleshooting/
title: Troubleshooting | OpenCode
-->

[Skip to content](#_top)

[![](/docs/_astro/logo-dark.DOStV66V.svg) ![](/docs/_astro/logo-light.B0yzR0O5.svg)  OpenCode](/docs/)

[app.header.home](/)[app.header.docs](/v2/docs)

Search  `CtrlK`

Cancel

  [New OpenCode v2 is now available →](https://opencode.ai/v2)

* [Intro](/docs/)
* [Config](/docs/config/)
* [Providers](/docs/providers/)
* [Network](/docs/network/)
* [Enterprise](/docs/enterprise/)
* [Troubleshooting](/docs/troubleshooting/)
* [Windows](/docs/windows-wsl)
* Usage

  + [Go](https://opencode.ai/v2/docs/console/go/)
  + [TUI](/docs/tui/)
  + [CLI](/docs/cli/)
  + [Web](/docs/web/)
  + [IDE](/docs/ide/)
  + [Console](https://opencode.ai/v2/docs/console/)
  + [Share](/docs/share/)
  + [GitHub](/docs/github/)
  + [GitLab](/docs/gitlab/)
* Configure

  + [Tools](/docs/tools/)
  + [Rules](/docs/rules/)
  + [Agents](/docs/agents/)
  + [Models](/docs/models/)
  + [Themes](/docs/themes/)
  + [Keybinds](/docs/keybinds/)
  + [Commands](/docs/commands/)
  + [Formatters](/docs/formatters/)
  + [Permissions](/docs/permissions/)
  + [Policies](/docs/policies/)
  + [LSP Servers](/docs/lsp/)
  + [MCP servers](/docs/mcp-servers/)
  + [ACP Support](/docs/acp/)
  + [Agent Skills](/docs/skills/)
  + [References](/docs/references/)
  + [Custom Tools](/docs/custom-tools/)
* Develop

  + [SDK](/docs/sdk/)
  + [Server](/docs/server/)
  + [Plugins](/docs/plugins/)
  + [Ecosystem](/docs/ecosystem/)

[GitHub](https://github.com/anomalyco/opencode)[Discord](https://opencode.ai/discord)

  Select theme   DarkLightAuto         Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

On this page

* [Overview](#_top)
* [Logs](#logs)
* [Storage](#storage)
* [Uninstall](#uninstall)
* [Desktop app](#desktop-app)
  + [Quick checks](#quick-checks)
  + [Disable plugins](#disable-plugins)
  + [Clear the cache](#clear-the-cache)
  + [Fix server connection issues](#fix-server-connection-issues)
  + [Linux: Wayland / X11 issues](#linux-wayland--x11-issues)
  + [Windows: WebView2 runtime](#windows-webview2-runtime)
  + [Windows: General performance issues](#windows-general-performance-issues)
  + [Notifications not showing](#notifications-not-showing)
  + [Reset desktop app storage (last resort)](#reset-desktop-app-storage-last-resort)
* [Getting help](#getting-help)
* [Common issues](#common-issues)
  + [OpenCode wonât start](#opencode-wont-start)
  + [Authentication issues](#authentication-issues)
  + [Model not available](#model-not-available)
  + [ProviderInitError](#provideriniterror)
  + [AI\_APICallError and provider package issues](#ai_apicallerror-and-provider-package-issues)
  + [Copy/paste not working on Linux](#copypaste-not-working-on-linux)

### On this page

* [Overview](#_top)
* [Logs](#logs)
* [Storage](#storage)
* [Uninstall](#uninstall)
* [Desktop app](#desktop-app)
  + [Quick checks](#quick-checks)
  + [Disable plugins](#disable-plugins)
  + [Clear the cache](#clear-the-cache)
  + [Fix server connection issues](#fix-server-connection-issues)
  + [Linux: Wayland / X11 issues](#linux-wayland--x11-issues)
  + [Windows: WebView2 runtime](#windows-webview2-runtime)
  + [Windows: General performance issues](#windows-general-performance-issues)
  + [Notifications not showing](#notifications-not-showing)
  + [Reset desktop app storage (last resort)](#reset-desktop-app-storage-last-resort)
* [Getting help](#getting-help)
* [Common issues](#common-issues)
  + [OpenCode wonât start](#opencode-wont-start)
  + [Authentication issues](#authentication-issues)
  + [Model not available](#model-not-available)
  + [ProviderInitError](#provideriniterror)
  + [AI\_APICallError and provider package issues](#ai_apicallerror-and-provider-package-issues)
  + [Copy/paste not working on Linux](#copypaste-not-working-on-linux)

## Troubleshooting

Common issues and how to resolve them.

To debug issues with OpenCode, start by checking the logs and local data it stores on disk.

---

### [Logs](#logs)

Log files are written to:

* **macOS/Linux**: `~/.local/share/opencode/log/`
* **Windows**: Press `WIN+R` and paste `%USERPROFILE%\.local\share\opencode\log`

Log files are named with timestamps (e.g., `2025-01-09T123456.log`) and the most recent 10 log files are kept.

You can set the log level with the `--log-level` command-line option to get more detailed debug information. For example, `opencode --log-level DEBUG`.

---

### [Storage](#storage)

opencode stores session data and other application data on disk at:

* **macOS/Linux**: `~/.local/share/opencode/`
* **Windows**: Press `WIN+R` and paste `%USERPROFILE%\.local\share\opencode`

This directory contains:

* `auth.json` - Authentication data like API keys, OAuth tokens
* `log/` - Application logs
* `project/` - Project-specific data like session and message data
  + If the project is within a Git repo, it is stored in `./<project-slug>/storage/`
  + If it is not a Git repo, it is stored in `./global/storage/`

---

### [Uninstall](#uninstall)

To uninstall the OpenCode CLI and remove its related files, run:

Terminal window

```
opencode uninstall
```

The command shows what will be removed and asks for confirmation. See the [CLI reference](/docs/cli#uninstall) for options to keep your configuration or application data.

To remove OpenCode Desktop, uninstall the application through your operating systemâs app management tools.

---

### [Desktop app](#desktop-app)

OpenCode Desktop runs a local OpenCode server (the `opencode-cli` sidecar) in the background. Most issues are caused by a misbehaving plugin, a corrupted cache, or a bad server setting.

#### [Quick checks](#quick-checks)

* Fully quit and relaunch the app.
* If the app shows an error screen, click **Restart** and copy the error details.
* macOS only: `OpenCode` menu -> **Reload Webview** (helps if the UI is blank/frozen).

---

#### [Disable plugins](#disable-plugins)

If the desktop app is crashing on launch, hanging, or behaving strangely, start by disabling plugins.

##### [Check the global config](#check-the-global-config)

Open your global config file and look for a `plugin` key.

* **macOS/Linux**: `~/.config/opencode/opencode.jsonc` (or `~/.config/opencode/opencode.json`)
* **macOS/Linux** (older installs): `~/.local/share/opencode/opencode.jsonc`
* **Windows**: Press `WIN+R` and paste `%USERPROFILE%\.config\opencode\opencode.jsonc`

If you have plugins configured, temporarily disable them by removing the key or setting it to an empty array:

```
{

"$schema": "https://opencode.ai/config.json",

"plugin": [],

}
```

##### [Check plugin directories](#check-plugin-directories)

OpenCode can also load local plugins from disk. Temporarily move these out of the way (or rename the folder) and restart the desktop app:

* **Global plugins**
  + **macOS/Linux**: `~/.config/opencode/plugins/`
  + **Windows**: Press `WIN+R` and paste `%USERPROFILE%\.config\opencode\plugins`
* **Project plugins** (only if you use per-project config)
  + `<your-project>/.opencode/plugins/`

If the app starts working again, re-enable plugins one at a time to find which one is causing the issue.

---

#### [Clear the cache](#clear-the-cache)

If disabling plugins doesnât help (or a plugin install is stuck), clear the cache so OpenCode can rebuild it.

1. Quit OpenCode Desktop completely.
2. Delete the cache directory:

* **macOS**: Finder -> `Cmd+Shift+G` -> paste `~/.cache/opencode`
* **Linux**: delete `~/.cache/opencode` (or run `rm -rf ~/.cache/opencode`)
* **Windows**: Press `WIN+R` and paste `%USERPROFILE%\.cache\opencode`

3. Restart OpenCode Desktop.

---

#### [Fix server connection issues](#fix-server-connection-issues)

OpenCode Desktop can either start its own local server (default) or connect to a server URL you configured.

If you see a **âConnection Failedâ** dialog (or the app never gets past the splash screen), check for a custom server URL.

##### [Clear the desktop default server URL](#clear-the-desktop-default-server-url)

From the Home screen, click the server name (with the status dot) to open the Server picker. In the **Default server** section, click **Clear**.

##### [Remove `server.port` / `server.hostname` from your config](#remove-serverport--serverhostname-from-your-config)

If your `opencode.json(c)` contains a `server` section, temporarily remove it and restart the desktop app.

##### [Check environment variables](#check-environment-variables)

If you have `OPENCODE_PORT` set in your environment, the desktop app will try to use that port for the local server.

* Unset `OPENCODE_PORT` (or pick a free port) and restart.

---

#### [Linux: Wayland / X11 issues](#linux-wayland--x11-issues)

On Linux, some Wayland setups can cause blank windows or compositor errors.

* If youâre on Wayland and the app is blank/crashing, try launching with `OC_ALLOW_WAYLAND=1`.
* If that makes things worse, remove it and try launching under an X11 session instead.

---

#### [Windows: WebView2 runtime](#windows-webview2-runtime)

On Windows, OpenCode Desktop requires the Microsoft Edge **WebView2 Runtime**. If the app opens to a blank window or wonât start, install/update WebView2 and try again.

---

#### [Windows: General performance issues](#windows-general-performance-issues)

If youâre experiencing slow performance, file access issues, or terminal problems on Windows, try using [WSL (Windows Subsystem for Linux)](/docs/windows-wsl). WSL provides a Linux environment that works more seamlessly with OpenCodeâs features.

---

#### [Notifications not showing](#notifications-not-showing)

OpenCode Desktop only shows system notifications when:

* notifications are enabled for OpenCode in your OS settings, and
* the app window is not focused.

---

#### [Reset desktop app storage (last resort)](#reset-desktop-app-storage-last-resort)

If the app wonât start and you canât clear settings from inside the UI, reset the desktop appâs saved state.

1. Quit OpenCode Desktop.
2. Find and delete these files (they live in the OpenCode Desktop app data directory):

* `opencode.settings.dat` (desktop default server URL)
* `opencode.global.dat` and `opencode.workspace.*.dat` (UI state like recent servers/projects)

To find the directory quickly:

* **macOS**: Finder -> `Cmd+Shift+G` -> `~/Library/Application Support` (then search for the filenames above)
* **Linux**: search under `~/.local/share` for the filenames above
* **Windows**: Press `WIN+R` -> `%APPDATA%` (then search for the filenames above)

---

### [Getting help](#getting-help)

If youâre experiencing issues with OpenCode:

1. **Report issues on GitHub**

   The best way to report bugs or request features is through our GitHub repository:

   [**github.com/anomalyco/opencode/issues**](https://github.com/anomalyco/opencode/issues)

   Before creating a new issue, search existing issues to see if your problem has already been reported.
2. **Join our Discord**

   For real-time help and community discussion, join our Discord server:

   [**opencode.ai/discord**](https://opencode.ai/discord)

---

### [Common issues](#common-issues)

Here are some common issues and how to resolve them.

---

#### [OpenCode wonât start](#opencode-wont-start)

1. Check the logs for error messages
2. Try running with `--print-logs` to see output in the terminal
3. Ensure you have the latest version with `opencode upgrade`

---

#### [Authentication issues](#authentication-issues)

1. Try re-authenticating with the `/connect` command in the TUI
2. Check that your API keys are valid
3. Ensure your network allows connections to the providerâs API

---

#### [Model not available](#model-not-available)

1. Check that youâve authenticated with the provider
2. Verify the model name in your config is correct
3. Some models may require specific access or subscriptions

If you encounter `ProviderModelNotFoundError` you are most likely incorrectly
referencing a model somewhere.
Models should be referenced like so: `<providerId>/<modelId>`

Examples:

* `openai/gpt-4.1`
* `openrouter/google/gemini-2.5-flash`
* `opencode/kimi-k2`

To figure out what models you have access to, run `opencode models`

---

#### [ProviderInitError](#provideriniterror)

If you encounter a ProviderInitError, you likely have an invalid or corrupted configuration.

To resolve this:

1. First, verify your provider is set up correctly by following the [providers guide](/docs/providers)
2. If the issue persists, try clearing your stored configuration:

   Terminal window

   ```
   rm -rf ~/.local/share/opencode
   ```

   On Windows, press `WIN+R` and delete: `%USERPROFILE%\.local\share\opencode`
3. Re-authenticate with your provider using the `/connect` command in the TUI.

---

#### [AI\_APICallError and provider package issues](#ai_apicallerror-and-provider-package-issues)

If you encounter API call errors, this may be due to outdated provider packages. opencode dynamically installs provider packages (OpenAI, Anthropic, Google, etc.) as needed and caches them locally.

To resolve provider package issues:

1. Clear the provider package cache:

   Terminal window

   ```
   rm -rf ~/.cache/opencode
   ```

   On Windows, press `WIN+R` and delete: `%USERPROFILE%\.cache\opencode`
2. Restart opencode to reinstall the latest provider packages

This will force opencode to download the most recent versions of provider packages, which often resolves compatibility issues with model parameters and API changes.

---

#### [Copy/paste not working on Linux](#copypaste-not-working-on-linux)

Linux users need to have one of the following clipboard utilities installed for copy/paste functionality to work:

**For X11 systems:**

Terminal window

```
apt install -y xclip

## or

apt install -y xsel
```

**For Wayland systems:**

Terminal window

```
apt install -y wl-clipboard
```

**For headless environments:**

Terminal window

```
apt install -y xvfb

## and run:

Xvfb :99 -screen 0 1024x768x24 > /dev/null 2>&1 &

export DISPLAY=:99.0
```

opencode will detect if youâre using Wayland and prefer `wl-clipboard`, otherwise it will try to find clipboard tools in order of: `xclip` and `xsel`.

[Edit page](https://github.com/anomalyco/opencode/edit/dev/packages/web/src/content/docs/troubleshooting.mdx)[Found a bug? Open an issue](https://github.com/anomalyco/opencode/issues/new)[Join our Discord community](https://opencode.ai/discord)  Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

© [Anomaly](https://anoma.ly)

Last updated: Oct 13, 2026

---
<!--
URL: https://opencode.ai/docs/plugins/
title: Plugins | OpenCode
-->

[Skip to content](#_top)

[![](/docs/_astro/logo-dark.DOStV66V.svg) ![](/docs/_astro/logo-light.B0yzR0O5.svg)  OpenCode](/docs/)

[app.header.home](/)[app.header.docs](/v2/docs)

Search  `CtrlK`

Cancel

  [New OpenCode v2 is now available →](https://opencode.ai/v2)

* [Intro](/docs/)
* [Config](/docs/config/)
* [Providers](/docs/providers/)
* [Network](/docs/network/)
* [Enterprise](/docs/enterprise/)
* [Troubleshooting](/docs/troubleshooting/)
* [Windows](/docs/windows-wsl)
* Usage

  + [Go](https://opencode.ai/v2/docs/console/go/)
  + [TUI](/docs/tui/)
  + [CLI](/docs/cli/)
  + [Web](/docs/web/)
  + [IDE](/docs/ide/)
  + [Console](https://opencode.ai/v2/docs/console/)
  + [Share](/docs/share/)
  + [GitHub](/docs/github/)
  + [GitLab](/docs/gitlab/)
* Configure

  + [Tools](/docs/tools/)
  + [Rules](/docs/rules/)
  + [Agents](/docs/agents/)
  + [Models](/docs/models/)
  + [Themes](/docs/themes/)
  + [Keybinds](/docs/keybinds/)
  + [Commands](/docs/commands/)
  + [Formatters](/docs/formatters/)
  + [Permissions](/docs/permissions/)
  + [Policies](/docs/policies/)
  + [LSP Servers](/docs/lsp/)
  + [MCP servers](/docs/mcp-servers/)
  + [ACP Support](/docs/acp/)
  + [Agent Skills](/docs/skills/)
  + [References](/docs/references/)
  + [Custom Tools](/docs/custom-tools/)
* Develop

  + [SDK](/docs/sdk/)
  + [Server](/docs/server/)
  + [Plugins](/docs/plugins/)
  + [Ecosystem](/docs/ecosystem/)

[GitHub](https://github.com/anomalyco/opencode)[Discord](https://opencode.ai/discord)

  Select theme   DarkLightAuto         Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

On this page

* [Overview](#_top)
* [Use a plugin](#use-a-plugin)
  + [From local files](#from-local-files)
  + [From npm](#from-npm)
  + [How plugins are installed](#how-plugins-are-installed)
  + [Load order](#load-order)
* [Create a plugin](#create-a-plugin)
  + [Dependencies](#dependencies)
  + [Basic structure](#basic-structure)
  + [TypeScript support](#typescript-support)
  + [Events](#events)
* [Examples](#examples)
  + [Send notifications](#send-notifications)
  + [.env protection](#env-protection)
  + [Inject environment variables](#inject-environment-variables)
  + [Custom tools](#custom-tools)
  + [Logging](#logging)
  + [Compaction hooks](#compaction-hooks)

### On this page

* [Overview](#_top)
* [Use a plugin](#use-a-plugin)
  + [From local files](#from-local-files)
  + [From npm](#from-npm)
  + [How plugins are installed](#how-plugins-are-installed)
  + [Load order](#load-order)
* [Create a plugin](#create-a-plugin)
  + [Dependencies](#dependencies)
  + [Basic structure](#basic-structure)
  + [TypeScript support](#typescript-support)
  + [Events](#events)
* [Examples](#examples)
  + [Send notifications](#send-notifications)
  + [.env protection](#env-protection)
  + [Inject environment variables](#inject-environment-variables)
  + [Custom tools](#custom-tools)
  + [Logging](#logging)
  + [Compaction hooks](#compaction-hooks)

## Plugins

Write your own plugins to extend OpenCode.

Plugins allow you to extend OpenCode by hooking into various events and customizing behavior. You can create plugins to add new features, integrate with external services, or modify OpenCodeâs default behavior.

For examples, check out the [plugins](/docs/ecosystem#plugins) created by the community.

---

### [Use a plugin](#use-a-plugin)

There are two ways to load plugins.

---

#### [From local files](#from-local-files)

Place JavaScript or TypeScript files in the plugin directory.

* `.opencode/plugins/` - Project-level plugins
* `~/.config/opencode/plugins/` - Global plugins

Files in these directories are automatically loaded at startup.

---

#### [From npm](#from-npm)

Specify npm packages in your config file.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"plugin": ["opencode-helicone-session", "opencode-wakatime", "@my-org/custom-plugin"]

}
```

Both regular and scoped npm packages are supported.

Browse available plugins in the [ecosystem](/docs/ecosystem#plugins).

---

#### [How plugins are installed](#how-plugins-are-installed)

**npm plugins** are installed automatically using Bun at startup. Packages and their dependencies are cached in `~/.cache/opencode/node_modules/`.

**Local plugins** are loaded directly from the plugin directory. To use external packages, you must create a `package.json` within your config directory (see [Dependencies](#dependencies)), or publish the plugin to npm and [add it to your config](/docs/config#plugins).

---

#### [Load order](#load-order)

Plugins are loaded from all sources and all hooks run in sequence. The load order is:

1. Global config (`~/.config/opencode/opencode.json`)
2. Project config (`opencode.json`)
3. Global plugin directory (`~/.config/opencode/plugins/`)
4. Project plugin directory (`.opencode/plugins/`)

Duplicate npm packages with the same name and version are loaded once. However, a local plugin and an npm plugin with similar names are both loaded separately.

---

### [Create a plugin](#create-a-plugin)

A plugin is a **JavaScript/TypeScript module** that exports one or more plugin
functions. Each function receives a context object and returns a hooks object.

---

#### [Dependencies](#dependencies)

Local plugins and custom tools can use external npm packages. Add a `package.json` to your config directory with the dependencies you need.

.opencode/package.json

```
{

"dependencies": {

"shescape": "^2.1.0"

}

}
```

OpenCode runs `bun install` at startup to install these. Your plugins and tools can then import them.

.opencode/plugins/my-plugin.ts

```
import { escape } from "shescape"

export const MyPlugin = async (ctx) => {

return {

"tool.execute.before": async (input, output) => {

if (input.tool === "bash") {

output.args.command = escape(output.args.command)

}

},

}

}
```

---

#### [Basic structure](#basic-structure)

.opencode/plugins/example.js

```
export const MyPlugin = async ({ project, client, $, directory, worktree }) => {

console.log("Plugin initialized!")

return {

// Hook implementations go here

}

}
```

The plugin function receives:

* `project`: The current project information.
* `directory`: The current working directory.
* `worktree`: The git worktree path.
* `client`: An opencode SDK client for interacting with the AI.
* `$`: Bunâs [shell API](https://bun.com/docs/runtime/shell) for executing commands.

---

#### [TypeScript support](#typescript-support)

For TypeScript plugins, you can import types from the plugin package:

my-plugin.ts

```
import type { Plugin } from "@opencode-ai/plugin"

export const MyPlugin: Plugin = async ({ project, client, $, directory, worktree }) => {

return {

// Type-safe hook implementations

}

}
```

---

#### [Events](#events)

Plugins can subscribe to events as seen below in the Examples section. Here is a list of the different events available.

##### [Command Events](#command-events)

* `command.executed`

##### [File Events](#file-events)

* `file.edited`
* `file.watcher.updated`

##### [Installation Events](#installation-events)

* `installation.updated`

##### [LSP Events](#lsp-events)

* `lsp.client.diagnostics`
* `lsp.updated`

##### [Message Events](#message-events)

* `message.part.removed`
* `message.part.updated`
* `message.removed`
* `message.updated`

##### [Permission Events](#permission-events)

* `permission.asked`
* `permission.replied`

##### [Server Events](#server-events)

* `server.connected`

##### [Session Events](#session-events)

* `session.created`
* `session.compacted`
* `session.deleted`
* `session.diff`
* `session.error`
* `session.idle`
* `session.status`
* `session.updated`

##### [Shell Events](#shell-events)

* `shell.env`

##### [Tool Events](#tool-events)

* `tool.execute.after`
* `tool.execute.before`

##### [TUI Events](#tui-events)

* `tui.prompt.append`
* `tui.command.execute`
* `tui.toast.show`

---

### [Examples](#examples)

Here are some examples of plugins you can use to extend opencode.

---

#### [Send notifications](#send-notifications)

Send notifications when certain events occur:

.opencode/plugins/notification.js

```
export const NotificationPlugin = async ({ project, client, $, directory, worktree }) => {

return {

event: async ({ event }) => {

// Send notification on session completion

if (event.type === "session.idle") {

await $`osascript -e 'display notification "Session completed!" with title "opencode"'`

}

},

}

}
```

We are using `osascript` to run AppleScript on macOS. Here we are using it to send notifications.

Note

If youâre using the OpenCode desktop app, it can send system notifications automatically when a response is ready or when a session errors.

---

#### [.env protection](#env-protection)

Prevent opencode from reading `.env` files:

.opencode/plugins/env-protection.js

```
export const EnvProtection = async ({ project, client, $, directory, worktree }) => {

return {

"tool.execute.before": async (input, output) => {

if (input.tool === "read" && output.args.filePath.includes(".env")) {

throw new Error("Do not read .env files")

}

},

}

}
```

---

#### [Inject environment variables](#inject-environment-variables)

Inject environment variables into all shell execution (AI tools and user terminals):

.opencode/plugins/inject-env.js

```
export const InjectEnvPlugin = async () => {

return {

"shell.env": async (input, output) => {

output.env.MY_API_KEY = "secret"

output.env.PROJECT_ROOT = input.cwd

},

}

}
```

---

#### [Custom tools](#custom-tools)

Plugins can also add custom tools to opencode:

.opencode/plugins/custom-tools.ts

```
import { type Plugin, tool } from "@opencode-ai/plugin"

export const CustomToolsPlugin: Plugin = async (ctx) => {

return {

tool: {

mytool: tool({

description: "This is a custom tool",

args: {

foo: tool.schema.string(),

},

async execute(args, context) {

const { directory, worktree } = context

return `Hello ${args.foo} from ${directory} (worktree: ${worktree})`

},

}),

},

}

}
```

The `tool` helper creates a custom tool that opencode can call. It takes a Zod schema function and returns a tool definition with:

* `description`: What the tool does
* `args`: Zod schema for the toolâs arguments
* `execute`: Function that runs when the tool is called

Your custom tools will be available to opencode alongside built-in tools.

Note

If a plugin tool uses the same name as a built-in tool, the plugin tool takes precedence.

---

#### [Logging](#logging)

Use `client.app.log()` instead of `console.log` for structured logging:

.opencode/plugins/my-plugin.ts

```
export const MyPlugin = async ({ client }) => {

await client.app.log({

body: {

service: "my-plugin",

level: "info",

message: "Plugin initialized",

extra: { foo: "bar" },

},

})

}
```

Levels: `debug`, `info`, `warn`, `error`. See [SDK documentation](https://opencode.ai/docs/sdk) for details.

---

#### [Compaction hooks](#compaction-hooks)

Customize the context included when a session is compacted:

.opencode/plugins/compaction.ts

```
import type { Plugin } from "@opencode-ai/plugin"

export const CompactionPlugin: Plugin = async (ctx) => {

return {

"experimental.session.compacting": async (input, output) => {

// Inject additional context into the compaction prompt

output.context.push(`

### Custom Context

Include any state that should persist across compaction:

- Current task status

- Important decisions made

- Files being actively worked on

`)

},

}

}
```

The `experimental.session.compacting` hook fires before the LLM generates a continuation summary. Use it to inject domain-specific context that the default compaction prompt would miss.

You can also replace the compaction prompt entirely by setting `output.prompt`:

.opencode/plugins/custom-compaction.ts

```
import type { Plugin } from "@opencode-ai/plugin"

export const CustomCompactionPlugin: Plugin = async (ctx) => {

return {

"experimental.session.compacting": async (input, output) => {

// Replace the entire compaction prompt

output.prompt = `

You are generating a continuation prompt for a multi-agent swarm session.

Summarize:

1. The current task and its status

2. Which files are being modified and by whom

3. Any blockers or dependencies between agents

4. The next steps to complete the work

Format as a structured prompt that a new agent can use to resume work.

`

},

}

}
```

When `output.prompt` is set, it completely replaces the default compaction prompt. The `output.context` array is ignored in this case.

[Edit page](https://github.com/anomalyco/opencode/edit/dev/packages/web/src/content/docs/plugins.mdx)[Found a bug? Open an issue](https://github.com/anomalyco/opencode/issues/new)[Join our Discord community](https://opencode.ai/discord)  Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

© [Anomaly](https://anoma.ly)

Last updated: Oct 13, 2026

---
<!--
URL: https://opencode.ai/docs/providers
title: Providers | OpenCode
-->

[Skip to content](#_top)

[![](/docs/_astro/logo-dark.DOStV66V.svg) ![](/docs/_astro/logo-light.B0yzR0O5.svg)  OpenCode](/docs/)

[app.header.home](/)[app.header.docs](/v2/docs)

Search  `CtrlK`

Cancel

  [New OpenCode v2 is now available →](https://opencode.ai/v2)

* [Intro](/docs/)
* [Config](/docs/config/)
* [Providers](/docs/providers/)
* [Network](/docs/network/)
* [Enterprise](/docs/enterprise/)
* [Troubleshooting](/docs/troubleshooting/)
* [Windows](/docs/windows-wsl)
* Usage

  + [Go](https://opencode.ai/v2/docs/console/go/)
  + [TUI](/docs/tui/)
  + [CLI](/docs/cli/)
  + [Web](/docs/web/)
  + [IDE](/docs/ide/)
  + [Console](https://opencode.ai/v2/docs/console/)
  + [Share](/docs/share/)
  + [GitHub](/docs/github/)
  + [GitLab](/docs/gitlab/)
* Configure

  + [Tools](/docs/tools/)
  + [Rules](/docs/rules/)
  + [Agents](/docs/agents/)
  + [Models](/docs/models/)
  + [Themes](/docs/themes/)
  + [Keybinds](/docs/keybinds/)
  + [Commands](/docs/commands/)
  + [Formatters](/docs/formatters/)
  + [Permissions](/docs/permissions/)
  + [Policies](/docs/policies/)
  + [LSP Servers](/docs/lsp/)
  + [MCP servers](/docs/mcp-servers/)
  + [ACP Support](/docs/acp/)
  + [Agent Skills](/docs/skills/)
  + [References](/docs/references/)
  + [Custom Tools](/docs/custom-tools/)
* Develop

  + [SDK](/docs/sdk/)
  + [Server](/docs/server/)
  + [Plugins](/docs/plugins/)
  + [Ecosystem](/docs/ecosystem/)

[GitHub](https://github.com/anomalyco/opencode)[Discord](https://opencode.ai/discord)

  Select theme   DarkLightAuto         Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

On this page

* [Overview](#_top)
  + [Credentials](#credentials)
  + [Config](#config)
* [OpenCode Zen](#opencode-zen)
* [OpenCode Go](#opencode-go)
* [Directory](#directory)
  + [302.AI](#302ai)
  + [Amazon Bedrock](#amazon-bedrock)
  + [Anthropic](#anthropic)
  + [Atomic Chat](#atomic-chat)
  + [Azure OpenAI](#azure-openai)
  + [Azure Cognitive Services](#azure-cognitive-services)
  + [Baseten](#baseten)
  + [Cerebras](#cerebras)
  + [Cloudflare AI Gateway](#cloudflare-ai-gateway)
  + [Cloudflare Workers AI](#cloudflare-workers-ai)
  + [Cortecs](#cortecs)
  + [DeepSeek](#deepseek)
  + [Deep Infra](#deep-infra)
  + [DigitalOcean](#digitalocean)
  + [Eden AI](#eden-ai)
  + [FrogBot](#frogbot)
  + [Fireworks AI](#fireworks-ai)
  + [GitLab Duo](#gitlab-duo)
  + [GitHub Copilot](#github-copilot)
  + [GMI Cloud](#gmi-cloud)
  + [Google Vertex AI](#google-vertex-ai)
  + [Groq](#groq)
  + [Hugging Face](#hugging-face)
  + [Helicone](#helicone)
  + [llama.cpp](#llamacpp)
  + [IO.NET](#ionet)
  + [LM Studio](#lm-studio)
  + [Moonshot AI](#moonshot-ai)
  + [MiniMax](#minimax)
  + [Modal](#modal)
  + [NVIDIA](#nvidia)
  + [Nebius Token Factory](#nebius-token-factory)
  + [Ollama](#ollama)
  + [Ollama Cloud](#ollama-cloud)
  + [OpenAI](#openai)
  + [OpenCode Zen](#opencode-zen-1)
  + [OpenRouter](#openrouter)
  + [LLM Gateway](#llm-gateway)
  + [Poolside](#poolside)
  + [SAP AI Core](#sap-ai-core)
  + [STACKIT](#stackit)
  + [OVHcloud AI Endpoints](#ovhcloud-ai-endpoints)
  + [Scaleway](#scaleway)
  + [SCX.ai](#scxai)
  + [Snowflake Cortex](#snowflake-cortex)
  + [Together AI](#together-ai)
  + [Venice AI](#venice-ai)
  + [Vercel AI Gateway](#vercel-ai-gateway)
  + [xAI](#xai)
  + [Z.AI](#zai)
  + [ZenMux](#zenmux)
* [Custom provider](#custom-provider)
* [Troubleshooting](#troubleshooting)

### On this page

* [Overview](#_top)
  + [Credentials](#credentials)
  + [Config](#config)
* [OpenCode Zen](#opencode-zen)
* [OpenCode Go](#opencode-go)
* [Directory](#directory)
  + [302.AI](#302ai)
  + [Amazon Bedrock](#amazon-bedrock)
  + [Anthropic](#anthropic)
  + [Atomic Chat](#atomic-chat)
  + [Azure OpenAI](#azure-openai)
  + [Azure Cognitive Services](#azure-cognitive-services)
  + [Baseten](#baseten)
  + [Cerebras](#cerebras)
  + [Cloudflare AI Gateway](#cloudflare-ai-gateway)
  + [Cloudflare Workers AI](#cloudflare-workers-ai)
  + [Cortecs](#cortecs)
  + [DeepSeek](#deepseek)
  + [Deep Infra](#deep-infra)
  + [DigitalOcean](#digitalocean)
  + [Eden AI](#eden-ai)
  + [FrogBot](#frogbot)
  + [Fireworks AI](#fireworks-ai)
  + [GitLab Duo](#gitlab-duo)
  + [GitHub Copilot](#github-copilot)
  + [GMI Cloud](#gmi-cloud)
  + [Google Vertex AI](#google-vertex-ai)
  + [Groq](#groq)
  + [Hugging Face](#hugging-face)
  + [Helicone](#helicone)
  + [llama.cpp](#llamacpp)
  + [IO.NET](#ionet)
  + [LM Studio](#lm-studio)
  + [Moonshot AI](#moonshot-ai)
  + [MiniMax](#minimax)
  + [Modal](#modal)
  + [NVIDIA](#nvidia)
  + [Nebius Token Factory](#nebius-token-factory)
  + [Ollama](#ollama)
  + [Ollama Cloud](#ollama-cloud)
  + [OpenAI](#openai)
  + [OpenCode Zen](#opencode-zen-1)
  + [OpenRouter](#openrouter)
  + [LLM Gateway](#llm-gateway)
  + [Poolside](#poolside)
  + [SAP AI Core](#sap-ai-core)
  + [STACKIT](#stackit)
  + [OVHcloud AI Endpoints](#ovhcloud-ai-endpoints)
  + [Scaleway](#scaleway)
  + [SCX.ai](#scxai)
  + [Snowflake Cortex](#snowflake-cortex)
  + [Together AI](#together-ai)
  + [Venice AI](#venice-ai)
  + [Vercel AI Gateway](#vercel-ai-gateway)
  + [xAI](#xai)
  + [Z.AI](#zai)
  + [ZenMux](#zenmux)
* [Custom provider](#custom-provider)
* [Troubleshooting](#troubleshooting)

## Providers

Using any LLM provider in OpenCode.

OpenCode uses the [AI SDK](https://ai-sdk.dev/) and [Models.dev](https://models.dev) to support **75+ LLM providers** and it supports running local models.

To add a provider you need to:

1. Add the API keys for the provider using the `/connect` command.
2. Configure the provider in your OpenCode config.

---

#### [Credentials](#credentials)

When you add a providerâs API keys with the `/connect` command, they are stored
in `~/.local/share/opencode/auth.json`.

---

#### [Config](#config)

You can customize the providers through the `provider` section in your OpenCode
config.

---

##### [Base URL](#base-url)

You can customize the base URL for any provider by setting the `baseURL` option. This is useful when using proxy services or custom endpoints.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"provider": {

"anthropic": {

"options": {

"baseURL": "https://api.anthropic.com/v1"

}

}

}

}
```

---

##### [Hiding models](#hiding-models)

You can hide specific models from the `/models` picker for a provider using the `blacklist` option. This is useful when a provider exposes models you donât want to use or select.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"provider": {

"anthropic": {

"blacklist": ["claude-opus-4-20250514"]

}

}

}
```

The inverse `whitelist` option hides every model except the ones listed.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"provider": {

"anthropic": {

"whitelist": ["claude-sonnet-4-20250514"]

}

}

}
```

Both options take an array of model IDs â the same IDs shown in the `/models` picker.

* `blacklist` removes the listed models from the picker.
* `whitelist` keeps only the listed models and hides the rest.
* You can combine them: `whitelist` narrows the set, then `blacklist` removes entries from it.

---

### [OpenCode Zen](#opencode-zen)

OpenCode Zen is a list of models provided by the OpenCode team that have been
tested and verified to work well with OpenCode. [Learn more](https://opencode.ai/v2/docs/console/).

Tip

If you are new, we recommend starting with OpenCode Zen.

1. Run the `/connect` command in the TUI, select `OpenCode Zen`, and head to [opencode.ai/auth](https://opencode.ai/zen).

   ```
   /connect
   ```
2. Sign in, add your billing details, and copy your API key.
3. Paste your API key.

   ```
   â API key

   â

   â

   â enter
   ```
4. Run `/models` in the TUI to see the list of models we recommend.

   ```
   /models
   ```

It works like any other provider in OpenCode and is completely optional to use.

---

### [OpenCode Go](#opencode-go)

OpenCode Go is a low cost subscription plan that provides reliable access to popular open coding models provided by the OpenCode team that have been
tested and verified to work well with OpenCode.

1. Run the `/connect` command in the TUI, select `OpenCode Go`, and head to [opencode.ai/auth](https://opencode.ai/zen).

   ```
   /connect
   ```
2. Sign in, add your billing details, and copy your API key.
3. Paste your API key.

   ```
   â API key

   â

   â

   â enter
   ```
4. Run `/models` in the TUI to see the list of models we recommend.

   ```
   /models
   ```

It works like any other provider in OpenCode and is completely optional to use.

---

### [Directory](#directory)

Letâs look at some of the providers in detail. If youâd like to add a provider to the
list, feel free to open a PR.

Note

Donât see a provider here? Submit a PR.

---

#### [302.AI](#302ai)

1. Head over to the [302.AI console](https://302.ai/), create an account, and generate an API key.
2. Run the `/connect` command and search for **302.AI**.

   ```
   /connect
   ```
3. Enter your 302.AI API key.

   ```
   â API key

   â

   â

   â enter
   ```
4. Run the `/models` command to select a model.

   ```
   /models
   ```

---

#### [Amazon Bedrock](#amazon-bedrock)

To use Amazon Bedrock with OpenCode:

1. Head over to the **Model catalog** in the Amazon Bedrock console and request
   access to the models you want.

   Tip

   You need to have access to the model you want in Amazon Bedrock.
2. **Configure authentication** using one of the following methods:

   ---

   #### [Environment Variables (Quick Start)](#environment-variables-quick-start)

   Set one of these environment variables while running opencode:

   Terminal window

   ```
   # Option 1: Using AWS access keys

   AWS_ACCESS_KEY_ID=XXX AWS_SECRET_ACCESS_KEY=YYY opencode

   # Option 2: Using named AWS profile

   AWS_PROFILE=my-profile opencode

   # Option 3: Using Bedrock bearer token

   AWS_BEARER_TOKEN_BEDROCK=XXX opencode
   ```

   Or add them to your bash profile:

   ~/.bash\_profile

   ```
   export AWS_PROFILE=my-dev-profile

   export AWS_REGION=us-east-1
   ```

   ---

   #### [Configuration File (Recommended)](#configuration-file-recommended)

   For project-specific or persistent configuration, use `opencode.json`:

   opencode.json

   ```
   {

   "$schema": "https://opencode.ai/config.json",

   "provider": {

   "amazon-bedrock": {

   "options": {

   "region": "us-east-1",

   "profile": "my-aws-profile"

   }

   }

   }

   }
   ```

   **Available options:**

   * `region` - AWS region (e.g., `us-east-1`, `eu-west-1`)
   * `profile` - AWS named profile from `~/.aws/credentials`
   * `endpoint` - Custom endpoint URL for VPC endpoints (alias for generic `baseURL` option)

   Tip

   Configuration file options take precedence over environment variables.

   ---

   #### [Advanced: VPC Endpoints](#advanced-vpc-endpoints)

   If youâre using VPC endpoints for Bedrock:

   opencode.json

   ```
   {

   "$schema": "https://opencode.ai/config.json",

   "provider": {

   "amazon-bedrock": {

   "options": {

   "region": "us-east-1",

   "profile": "production",

   "endpoint": "https://bedrock-runtime.us-east-1.vpce-xxxxx.amazonaws.com"

   }

   }

   }

   }
   ```

   Note

   The `endpoint` option is an alias for the generic `baseURL` option, using AWS-specific terminology. If both `endpoint` and `baseURL` are specified, `endpoint` takes precedence.

   ---

   #### [Authentication Methods](#authentication-methods)

   * **`AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY`**: Create an IAM user and generate access keys in the AWS Console
   * **`AWS_PROFILE`**: Use named profiles from `~/.aws/credentials`. First configure with `aws configure --profile my-profile` or `aws sso login`
   * **`AWS_BEARER_TOKEN_BEDROCK`**: Generate long-term API keys from the Amazon Bedrock console
   * **`AWS_WEB_IDENTITY_TOKEN_FILE` / `AWS_ROLE_ARN`**: For EKS IRSA (IAM Roles for Service Accounts) or other Kubernetes environments with OIDC federation. These environment variables are automatically injected by Kubernetes when using service account annotations.

   ---

   #### [Authentication Precedence](#authentication-precedence)

   Amazon Bedrock uses the following authentication priority:

   1. **Bearer Token** - `AWS_BEARER_TOKEN_BEDROCK` environment variable or token from `/connect` command
   2. **AWS Credential Chain** - Profile, access keys, shared credentials, IAM roles, Web Identity Tokens (EKS IRSA), instance metadata

   Note

   When a bearer token is set (via `/connect` or `AWS_BEARER_TOKEN_BEDROCK`), it takes precedence over all AWS credential methods including configured profiles.
3. Run the `/models` command to select the model you want.

   ```
   /models
   ```

Note

For custom inference profiles, use the model and provider name in the key and set the `id` property to the arn. This ensures correct caching.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"provider": {

"amazon-bedrock": {

// ...

"models": {

"anthropic-claude-sonnet-4.5": {

"id": "arn:aws:bedrock:us-east-1:xxx:application-inference-profile/yyy"

}

}

}

}

}
```

---

#### [Anthropic](#anthropic)

1. Once youâve signed up, run the `/connect` command and select Anthropic.

   ```
   /connect
   ```
2. Here you can select the **Claude Pro/Max** option and itâll open your browser
   and ask you to authenticate.

   ```
   â Select auth method

   â

   â Manually enter API Key

   â
   ```
3. Now all the Anthropic models should be available when you use the `/models` command.

   ```
   /models
   ```

There are plugins that allow you to use your Claude Pro/Max models with
OpenCode. Anthropic explicitly prohibits this.

Previous versions of OpenCode came bundled with these plugins but that is no
longer the case as of 1.3.0

Other companies support freedom of choice with developer tooling - you can use
the following subscriptions in OpenCode with zero setup:

* ChatGPT Plus
* Github Copilot
* Gitlab Duo

---

#### [Atomic Chat](#atomic-chat)

You can configure opencode to use local models through [Atomic Chat](https://atomic.chat), a desktop application that runs local LLMs behind an OpenAI-compatible API server (default endpoint `http://127.0.0.1:1337/v1`).

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"provider": {

"atomic-chat": {

"npm": "@ai-sdk/openai-compatible",

"name": "Atomic Chat (local)",

"options": {

"baseURL": "http://127.0.0.1:1337/v1"

},

"models": {

"<your-model-id>": {

"name": "<your-model-name>"

}

}

}

}

}
```

In this example:

* `atomic-chat` is the custom provider ID. This can be any string you want.
* `npm` specifies the package to use for this provider. Here, `@ai-sdk/openai-compatible` is used for any OpenAI-compatible API.
* `name` is the display name for the provider in the UI.
* `options.baseURL` is the endpoint for the local server. Change the host and port to match your Atomic Chat setup.
* `models` is a map of model IDs to their display names. Each ID must match the `id` returned by `GET /v1/models` â run `curl http://127.0.0.1:1337/v1/models` to list the ids currently loaded in Atomic Chat.

Tip

If tool calls arenât working well, pick a loaded model with strong tool-calling support (for example, a Qwen-Coder or DeepSeek-Coder variant).

---

#### [Azure OpenAI](#azure-openai)

Note

If you encounter âIâm sorry, but I cannot assist with that requestâ errors, try changing the content filter from **DefaultV2** to **Default** in your Azure resource.

1. Head over to the [Azure portal](https://portal.azure.com/) and create an **Azure OpenAI** resource. Youâll need:

   * **Resource name**: This becomes part of your API endpoint (`https://RESOURCE_NAME.openai.azure.com/`)
   * **API key**: Either `KEY 1` or `KEY 2` from your resource
2. Go to [Azure AI Foundry](https://ai.azure.com/) and deploy a model.

   Note

   The deployment name must match the model name for opencode to work properly.
3. Run the `/connect` command and search for **Azure**.

   ```
   /connect
   ```
4. Enter your API key.

   ```
   â API key

   â

   â

   â enter
   ```
5. Set your resource name as an environment variable:

   Terminal window

   ```
   AZURE_RESOURCE_NAME=XXX opencode
   ```

   Or add it to your bash profile:

   ~/.bash\_profile

   ```
   export AZURE_RESOURCE_NAME=XXX
   ```
6. Run the `/models` command to select your deployed model.

   ```
   /models
   ```

##### [Microsoft Entra ID (Azure CLI)](#microsoft-entra-id-azure-cli)

You can use your Azure CLI session instead of an API key. [Install the Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli), run `az login`, then run `/connect`, select **Azure**, and choose **Microsoft Entra ID (Azure CLI)**. Enter the Azure Resource name when prompted. Use `az login --tenant TENANT_ID` if the Resource belongs to a different tenant.

Find the Resource name by opening your Azure OpenAI or Foundry Resource in the [Azure portal](https://portal.azure.com/) or [Microsoft Foundry](https://ai.azure.com/). It is also the first part of the endpoint: `my-models` in `https://my-models.openai.azure.com/` or `https://my-models.services.ai.azure.com/`. If your identity can list Resources, you can also find their names and Resource groups with:

Terminal window

```
az cognitiveservices account list \

--query "[].{name:name,resourceGroup:resourceGroup}" \

--output table
```

OpenCode does not query Azure management APIs or discover deployments. Select a model whose catalog name matches your deployment, or configure its deployment name explicitly:

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"provider": {

"azure": {

"models": {

"gpt-5-mini": {

"id": "gpt-production"

}

}

}

}

}
```

Assign your identity the inference role required by the deployment: **Cognitive Services OpenAI User** for Azure OpenAI models or **Cognitive Services User** for other Foundry models. OpenCode refreshes access tokens through the Azure CLI, including versions earlier than 2.54.0, so you only need to sign in again when the CLI session expires.

---

#### [Azure Cognitive Services](#azure-cognitive-services)

1. Head over to the [Azure portal](https://portal.azure.com/) and create an **Azure OpenAI** resource. Youâll need:

   * **Resource name**: This becomes part of your API endpoint (`https://AZURE_COGNITIVE_SERVICES_RESOURCE_NAME.cognitiveservices.azure.com/`)
   * **API key**: Either `KEY 1` or `KEY 2` from your resource
2. Go to [Azure AI Foundry](https://ai.azure.com/) and deploy a model.

   Note

   The deployment name must match the model name for opencode to work properly.
3. Run the `/connect` command and search for **Azure Cognitive Services**.

   ```
   /connect
   ```
4. Enter your API key.

   ```
   â API key

   â

   â

   â enter
   ```
5. Set your resource name as an environment variable:

   Terminal window

   ```
   AZURE_COGNITIVE_SERVICES_RESOURCE_NAME=XXX opencode
   ```

   Or add it to your bash profile:

   ~/.bash\_profile

   ```
   export AZURE_COGNITIVE_SERVICES_RESOURCE_NAME=XXX
   ```
6. Run the `/models` command to select your deployed model.

   ```
   /models
   ```

---

#### [Baseten](#baseten)

1. Head over to the [Baseten](https://app.baseten.co/), create an account, and generate an API key.
2. Run the `/connect` command and search for **Baseten**.

   ```
   /connect
   ```
3. Enter your Baseten API key.

   ```
   â API key

   â

   â

   â enter
   ```
4. Run the `/models` command to select a model.

   ```
   /models
   ```

---

#### [Cerebras](#cerebras)

1. Head over to the [Cerebras console](https://inference.cerebras.ai/), create an account, and generate an API key.
2. Run the `/connect` command and search for **Cerebras**.

   ```
   /connect
   ```
3. Enter your Cerebras API key.

   ```
   â API key

   â

   â

   â enter
   ```
4. Run the `/models` command to select a model like *Qwen 3 Coder 480B*.

   ```
   /models
   ```

---

#### [Cloudflare AI Gateway](#cloudflare-ai-gateway)

Cloudflare AI Gateway lets you access models from OpenAI, Anthropic, Workers AI, and more through a unified endpoint. With [Unified Billing](https://developers.cloudflare.com/ai-gateway/features/unified-billing/) you donât need separate API keys for each provider.

1. Head over to the [Cloudflare dashboard](https://dash.cloudflare.com/), navigate to **AI** > **AI Gateway**, and create a new gateway. Note your **Account ID** and **Gateway ID**.
2. Run the `/connect` command and search for **Cloudflare AI Gateway**.

   ```
   /connect
   ```
3. Enter your **Account ID** when prompted.

   ```
   â Enter your Cloudflare Account ID

   â

   â

   â enter
   ```
4. Enter your **Gateway ID** when prompted.

   ```
   â Enter your Cloudflare AI Gateway ID

   â

   â

   â enter
   ```
5. Enter your **Cloudflare API token**.

   ```
   â Gateway API token

   â

   â

   â enter
   ```
6. Run the `/models` command to select a model.

   ```
   /models
   ```

   You can also add models through your opencode config.

   opencode.json

   ```
   {

   "$schema": "https://opencode.ai/config.json",

   "provider": {

   "cloudflare-ai-gateway": {

   "models": {

   "openai/gpt-4o": {},

   "anthropic/claude-sonnet-4": {}

   }

   }

   }

   }
   ```

   Alternatively, you can set environment variables instead of using `/connect`.

   ~/.bash\_profile

   ```
   export CLOUDFLARE_ACCOUNT_ID=your-32-character-account-id

   export CLOUDFLARE_GATEWAY_ID=your-gateway-id

   export CLOUDFLARE_API_TOKEN=your-api-token
   ```

---

#### [Cloudflare Workers AI](#cloudflare-workers-ai)

Cloudflare Workers AI lets you run AI models on Cloudflareâs global network directly via REST API, with no separate provider accounts needed for supported models.

1. Head over to the [Cloudflare dashboard](https://dash.cloudflare.com/), navigate to **Workers AI**, and select **Use REST API** to get your **Account ID** and create an API token.
2. Run the `/connect` command and search for **Cloudflare Workers AI**.

   ```
   /connect
   ```
3. Enter your **Account ID** when prompted.

   ```
   â Enter your Cloudflare Account ID

   â

   â

   â enter
   ```
4. Enter your **Cloudflare API key**.

   ```
   â API key

   â

   â

   â enter
   ```
5. Run the `/models` command to select a model.

   ```
   /models
   ```

   Alternatively, you can set environment variables instead of using `/connect`.

   ~/.bash\_profile

   ```
   export CLOUDFLARE_ACCOUNT_ID=your-32-character-account-id

   export CLOUDFLARE_API_KEY=your-api-token
   ```

---

#### [Cortecs](#cortecs)

1. Head over to the [Cortecs console](https://cortecs.ai/), create an account, and generate an API key.
2. Run the `/connect` command and search for **Cortecs**.

   ```
   /connect
   ```
3. Enter your Cortecs API key.

   ```
   â API key

   â

   â

   â enter
   ```
4. Run the `/models` command to select a model like *Kimi K2 Instruct*.

   ```
   /models
   ```

---

#### [DeepSeek](#deepseek)

1. Head over to the [DeepSeek console](https://platform.deepseek.com/), create an account, and click **Create new API key**.
2. Run the `/connect` command and search for **DeepSeek**.

   ```
   /connect
   ```
3. Enter your DeepSeek API key.

   ```
   â API key

   â

   â

   â enter
   ```
4. Run the `/models` command to select a DeepSeek model like *DeepSeek V4 Pro*.

   ```
   /models
   ```

---

#### [Deep Infra](#deep-infra)

1. Head over to the [Deep Infra dashboard](https://deepinfra.com/dash), create an account, and generate an API key.
2. Run the `/connect` command and search for **Deep Infra**.

   ```
   /connect
   ```
3. Enter your Deep Infra API key.

   ```
   â API key

   â

   â

   â enter
   ```
4. Run the `/models` command to select a model.

   ```
   /models
   ```

---

#### [DigitalOcean](#digitalocean)

DigitalOceanâs [Inference Engine](https://docs.digitalocean.com/products/inference/) provides access to open models like GPT-OSS, Llama, Qwen, and DeepSeek, plus custom [Inference Routers](https://docs.digitalocean.com/products/inference/how-to/use-inference-router/) that route each request to the cheapest, fastest, or best-fit model for a task.

OpenCode supports two authentication methods:

* **OAuth (Recommended)** â Sign in to your DigitalOcean account; OpenCode uses your DigitalOcean API token directly for inference and discovers your Inference Routers.
* **Model Access Key** â Paste an existing key from the DigitalOcean console.

##### [OAuth (Recommended)](#oauth-recommended)

1. Run the `/connect` command and search for **DigitalOcean**.

   ```
   /connect
   ```
2. Select **Login with DigitalOcean**.

   ```
   â Select auth method

   â

   â Login with DigitalOcean

   â Paste Model Access Key

   â
   ```
3. Your browser opens to authorize OpenCode. Sign in and approve.

   Note

   OpenCode requests `genai:read` and `inference:query` OAuth scopes. Your DigitalOcean API token is used directly for inference â no separate Model Access Key is created.

   Note

   Inference Routers only appear in the model picker after OAuth. Pasting a Model Access Key manually does not discover routers.
4. Run the `/models` command. Your Inference Routers appear as the format `router:` in the model selection.

   ```
   /models
   ```
5. To pick up newly created Inference Routers, re-run `/connect` and select **DigitalOcean** again.

##### [Using a Model Access Key](#using-a-model-access-key)

If youâd rather paste a key directly:

1. Head over to the **Manage** page in the Inference section of the [DigitalOcean console](https://cloud.digitalocean.com/) and create a new key.
2. Run the `/connect` command and select **DigitalOcean**, then **Paste Model Access Key**.

   ```
   â Enter your DigitalOcean Model Access Key

   â

   â

   â enter
   ```

   Note

   Inference Routers are not auto-discovered with this method. To surface them in the model picker, sign in via OAuth instead.
3. Run the `/models` command to select a model.

   ```
   /models
   ```

##### [Environment Variable](#environment-variable)

Alternatively, set your Model Access Key as an environment variable.

```
export DIGITALOCEAN_ACCESS_TOKEN=your-model-access-key
```

##### [Inference Routers](#inference-routers)

Inference Routers let you define a routing policy across multiple models â picking the cheapest, fastest, or most appropriate model per request based on the task. After OAuth, OpenCode surfaces each router as `router:<router-name>` in the model picker.

Selecting a router model is a drop-in replacement for any other model â OpenCode forwards your request and DigitalOcean picks the underlying model based on your routerâs policy. Learn more about [Inference Routers](https://docs.digitalocean.com/products/inference/how-to/use-inference-router/)

---

#### [Eden AI](#eden-ai)

[Eden AI](https://www.edenai.co/) is an EU-based gateway that serves models from many vendors over a single OpenAI-compatible API, with a separate EU endpoint for teams that need inference to stay in the EU.

1. Head over to the [Eden AI platform](https://app.edenai.run/user/register) to create an account and generate an API key.
2. Run the `/connect` command and search for **Eden AI**.

   ```
   /connect
   ```
3. Enter your Eden AI API key.

   ```
   â API key

   â

   â

   â enter
   ```
4. Run the `/models` command to select a model like *Mistral Large 3* or *Claude Sonnet 5*.

   ```
   /models
   ```

   Eden AI model ids are themselves in `vendor/model` form, so a full reference has three segments, for example `edenai/anthropic/claude-sonnet-5`.
5. To keep requests on Eden AIâs EU gateway, set its base URL.

   opencode.json

   ```
   {

   "$schema": "https://opencode.ai/config.json",

   "provider": {

   "edenai": {

   "options": {

   "baseURL": "https://api.eu.edenai.run/v3"

   }

   }

   }

   }
   ```

   The default is `https://api.edenai.run/v3`, so this swaps the global endpoint for the EU one. The EU endpoint serves the subset of the catalog that is available in the EU, so a model chosen in step 4 may not be reachable through it.

---

#### [FrogBot](#frogbot)

1. Head over to the [FrogBot dashboard](https://app.frogbot.ai/signup), create an account, and generate an API key.
2. Run the `/connect` command and search for **FrogBot**.

   ```
   /connect
   ```
3. Enter your FrogBot API key.

   ```
   â API key

   â

   â

   â enter
   ```
4. Run the `/models` command to select a model.

   ```
   /models
   ```

---

#### [Fireworks AI](#fireworks-ai)

1. Head over to the [Fireworks AI console](https://app.fireworks.ai/), create an account, and click **Create API Key**.
2. Run the `/connect` command and search for **Fireworks AI**.

   ```
   /connect
   ```
3. Enter your Fireworks AI API key.

   ```
   â API key

   â

   â

   â enter
   ```
4. Run the `/models` command to select a model like *Kimi K2 Instruct*.

   ```
   /models
   ```

---

#### [GitLab Duo](#gitlab-duo)

Experimental

GitLab Duo support in OpenCode is experimental. Features, configuration, and
behavior may change in future releases.

OpenCode integrates with the [GitLab Duo Agent Platform](https://docs.gitlab.com/user/duo_agent_platform/),
providing AI-powered agentic chat with native tool calling capabilities.

License requirements

GitLab Duo Agent Platform requires a **Premium** or **Ultimate** GitLab
subscription. It is available on GitLab.com and GitLab Self-Managed.
See [GitLab Duo Agent Platform prerequisites](https://docs.gitlab.com/user/duo_agent_platform/#prerequisites)
for full requirements.

1. Run the `/connect` command and select GitLab.

   ```
   /connect
   ```
2. Choose your authentication method:

   ```
   â Select auth method

   â

   â OAuth (Recommended)

   â Personal Access Token

   â
   ```

   #### [Using OAuth (Recommended)](#using-oauth-recommended)

   Select **OAuth** and your browser will open for authorization.

   #### [Using Personal Access Token](#using-personal-access-token)

   1. Go to [GitLab User Settings > Access Tokens](https://gitlab.com/-/user_settings/personal_access_tokens)
   2. Click **Add new token**
   3. Name: `OpenCode`, Scopes: `api`
   4. Copy the token (starts with `glpat-`)
   5. Enter it in the terminal
3. Run the `/models` command to see available models.

   ```
   /models
   ```

   Three Claude-based models are available:

   * **duo-chat-haiku-4-5** (Default) - Fast responses for quick tasks
   * **duo-chat-sonnet-4-5** - Balanced performance for most workflows
   * **duo-chat-opus-4-5** - Most capable for complex analysis

Note

You can also specify âGITLAB\_TOKENâ environment variable if you donât want
to store token in opencode auth storage.

###### [Self-Hosted GitLab](#self-hosted-gitlab)

compliance note

OpenCode uses a small model for some AI tasks like generating the session title.
It is configured to use gpt-5-nano by default, hosted by Zen. To lock OpenCode
to only use your own GitLab-hosted instance, add the following to your
`opencode.json` file. It is also recommended to disable session sharing.

```
{

"$schema": "https://opencode.ai/config.json",

"small_model": "gitlab/duo-chat-haiku-4-5",

"share": "disabled"

}
```

For self-hosted GitLab instances:

Terminal window

```
export GITLAB_INSTANCE_URL=https://gitlab.company.com

export GITLAB_TOKEN=glpat-...
```

If your instance runs a custom AI Gateway:

Terminal window

```
GITLAB_AI_GATEWAY_URL=https://ai-gateway.company.com
```

Or add to your bash profile:

~/.bash\_profile

```
export GITLAB_INSTANCE_URL=https://gitlab.company.com

export GITLAB_AI_GATEWAY_URL=https://ai-gateway.company.com

export GITLAB_TOKEN=glpat-...
```

Note

Your GitLab administrator must:

1. [Turn on GitLab Duo](https://docs.gitlab.com/user/duo_agent_platform/turn_on_off/#turn-gitlab-duo-on-or-off)
   for the user, group, or instance
2. [Turn on the Agent Platform](https://docs.gitlab.com/user/duo_agent_platform/turn_on_off/#turn-gitlab-duo-agent-platform-on-or-off)
   (GitLab 18.8+) or [enable beta and experimental features](https://docs.gitlab.com/user/duo_agent_platform/turn_on_off/#turn-on-beta-and-experimental-features)
   (GitLab 18.7 and earlier)
3. For Self-Managed, [configure your instance](https://docs.gitlab.com/administration/gitlab_duo/configure/gitlab_self_managed/)

###### [OAuth for Self-Hosted instances](#oauth-for-self-hosted-instances)

OpenCodeâs bundled GitLab OAuth application only exists on gitlab.com. To use
OAuth with a self-hosted instance, create your own application (Settings â
Applications) with the callback URL `http://127.0.0.1:8080/callback`, the
`api` scope, and **Confidential** unchecked (PKCE requires a public client).

Then expose the application ID as an environment variable:

Terminal window

```
export GITLAB_OAUTH_CLIENT_ID=your_application_id_here
```

###### [Configuration](#configuration)

Customize through `opencode.json`:

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"provider": {

"gitlab": {

"options": {

"instanceUrl": "https://gitlab.com"

}

}

}

}
```

###### [GitLab Duo Agent Platform (DAP) Workflow Models](#gitlab-duo-agent-platform-dap-workflow-models)

DAP workflow models provide an alternative execution path that routes tool calls
through GitLabâs Duo Workflow Service (DWS) instead of the standard agentic chat.
When a `duo-workflow-*` model is selected, OpenCode will:

1. Discover available models from your GitLab namespace
2. Present a selection picker if multiple models are available
3. Cache the selected model to disk for fast subsequent startups
4. Route tool execution requests through OpenCodeâs permission-gated tool system

Available DAP workflow models follow the `duo-workflow-*` naming convention and
are dynamically discovered from your GitLab instance.

Note

Workflow model discovery only runs for a login stored with `/connect` (OAuth or
a personal access token). A `GITLAB_TOKEN` environment variable on its own does
not trigger discovery.

###### [GitLab API Tools (Optional, but highly recommended)](#gitlab-api-tools-optional-but-highly-recommended)

To access GitLab tools (merge requests, issues, pipelines, CI/CD, etc.):

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"plugin": ["opencode-gitlab-plugin"]

}
```

This plugin provides comprehensive GitLab repository management capabilities including MR reviews, issue tracking, pipeline monitoring, and more.

---

#### [GitHub Copilot](#github-copilot)

To use your GitHub Copilot subscription with opencode:

Note

Some models might need a [Pro+
subscription](https://github.com/features/copilot/plans) to use.

1. Run the `/connect` command and search for GitHub Copilot.

   ```
   /connect
   ```
2. Navigate to [github.com/login/device](https://github.com/login/device) and enter the code.

   ```
   â Login with GitHub Copilot

   â

   â https://github.com/login/device

   â

   â Enter code: 8F43-6FCF

   â

   â Waiting for authorization...
   ```
3. Now run the `/models` command to select the model you want.

   ```
   /models
   ```

---

#### [GMI Cloud](#gmi-cloud)

To use GMI Cloud with OpenCode:

1. Head over to the [GMI Cloud console](https://console.gmicloud.ai/) to create an API key. You can also review the [API reference](https://docs.gmicloud.ai/inference-engine/api-reference/llm-api-reference) for the endpoint details.
2. Run the `/connect` command and search for **GMI Cloud**.

   ```
   /connect
   ```
3. Enter your GMI Cloud API key.

   ```
   â API key

   â

   â

   â enter
   ```
4. Run the `/models` command to select the model you want.

   ```
   /models
   ```

---

#### [Google Vertex AI](#google-vertex-ai)

To use Google Vertex AI with OpenCode:

1. Head over to the **Model Garden** in the Google Cloud Console and check the
   models available in your region.

   Note

   You need to have a Google Cloud project with Vertex AI API enabled.
2. Set the required environment variables:

   * `GOOGLE_CLOUD_PROJECT`: Your Google Cloud project ID
   * `VERTEX_LOCATION` (optional): The region for Vertex AI (defaults to `global`)
   * Authentication (choose one):
     + `GOOGLE_APPLICATION_CREDENTIALS`: Path to your service account JSON key file
     + Authenticate using gcloud CLI: `gcloud auth application-default login`

   Set them while running opencode.

   Terminal window

   ```
   GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json GOOGLE_CLOUD_PROJECT=your-project-id opencode
   ```

   Or add them to your bash profile.

   ~/.bash\_profile

   ```
   export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json

   export GOOGLE_CLOUD_PROJECT=your-project-id

   export VERTEX_LOCATION=global
   ```

Tip

The `global` region improves availability and reduces errors at no extra cost. Use regional endpoints (e.g., `us-central1`) for data residency requirements. [Learn more](https://cloud.google.com/vertex-ai/generative-ai/docs/partner-models/use-partner-models#regional_and_global_endpoints)

3. Run the `/models` command to select the model you want.

   ```
   /models
   ```

---

#### [Groq](#groq)

1. Head over to the [Groq console](https://console.groq.com/), click **Create API Key**, and copy the key.
2. Run the `/connect` command and search for Groq.

   ```
   /connect
   ```
3. Enter the API key for the provider.

   ```
   â API key

   â

   â

   â enter
   ```
4. Run the `/models` command to select the one you want.

   ```
   /models
   ```

---

#### [Hugging Face](#hugging-face)

[Hugging Face Inference Providers](https://huggingface.co/docs/inference-providers) provides access to open models supported by 17+ providers.

1. Head over to [Hugging Face settings](https://huggingface.co/settings/tokens/new?ownUserPermissions=inference.serverless.write&tokenType=fineGrained) to create a token with permission to make calls to Inference Providers.
2. Run the `/connect` command and search for **Hugging Face**.

   ```
   /connect
   ```
3. Enter your Hugging Face token.

   ```
   â API key

   â

   â

   â enter
   ```
4. Run the `/models` command to select a model like *Kimi-K2-Instruct* or *GLM-4.6*.

   ```
   /models
   ```

---

#### [Helicone](#helicone)

[Helicone](https://helicone.ai) is an LLM observability platform that provides logging, monitoring, and analytics for your AI applications. The Helicone AI Gateway routes your requests to the appropriate provider automatically based on the model.

1. Head over to [Helicone](https://helicone.ai), create an account, and generate an API key from your dashboard.
2. Run the `/connect` command and search for **Helicone**.

   ```
   /connect
   ```
3. Enter your Helicone API key.

   ```
   â API key

   â

   â

   â enter
   ```
4. Run the `/models` command to select a model.

   ```
   /models
   ```

For more providers and advanced features like caching and rate limiting, check the [Helicone documentation](https://docs.helicone.ai).

##### [Optional Configs](#optional-configs)

In the event you see a feature or model from Helicone that isnât configured automatically through opencode, you can always configure it yourself.

Hereâs [Heliconeâs Model Directory](https://helicone.ai/models), youâll need this to grab the IDs of the models you want to add.

~/.config/opencode/opencode.jsonc

```
{

"$schema": "https://opencode.ai/config.json",

"provider": {

"helicone": {

"npm": "@ai-sdk/openai-compatible",

"name": "Helicone",

"options": {

"baseURL": "https://ai-gateway.helicone.ai",

},

"models": {

"gpt-4o": {

// Model ID (from Helicone's model directory page)

"name": "GPT-4o", // Your own custom name for the model

},

"claude-sonnet-4-20250514": {

"name": "Claude Sonnet 4",

},

},

},

},

}
```

##### [Custom Headers](#custom-headers)

Helicone supports custom headers for features like caching, user tracking, and session management. Add them to your provider config using `options.headers`:

~/.config/opencode/opencode.jsonc

```
{

"$schema": "https://opencode.ai/config.json",

"provider": {

"helicone": {

"npm": "@ai-sdk/openai-compatible",

"name": "Helicone",

"options": {

"baseURL": "https://ai-gateway.helicone.ai",

"headers": {

"Helicone-Cache-Enabled": "true",

"Helicone-User-Id": "opencode",

},

},

},

},

}
```

###### [Session tracking](#session-tracking)

Heliconeâs [Sessions](https://docs.helicone.ai/features/sessions) feature lets you group related LLM requests together. Use the [opencode-helicone-session](https://github.com/H2Shami/opencode-helicone-session) plugin to automatically log each OpenCode conversation as a session in Helicone.

Terminal window

```
npm install -g opencode-helicone-session
```

Add it to your config.

opencode.json

```
{

"plugin": ["opencode-helicone-session"]

}
```

The plugin injects `Helicone-Session-Id` and `Helicone-Session-Name` headers into your requests. In Heliconeâs Sessions page, youâll see each OpenCode conversation listed as a separate session.

###### [Common Helicone headers](#common-helicone-headers)

| Header | Description |
| --- | --- |
| `Helicone-Cache-Enabled` | Enable response caching (`true`/`false`) |
| `Helicone-User-Id` | Track metrics by user |
| `Helicone-Property-[Name]` | Add custom properties (e.g., `Helicone-Property-Environment`) |
| `Helicone-Prompt-Id` | Associate requests with prompt versions |

See the [Helicone Header Directory](https://docs.helicone.ai/helicone-headers/header-directory) for all available headers.

---

#### [llama.cpp](#llamacpp)

You can configure opencode to use local models through [llama.cppâs](https://github.com/ggml-org/llama.cpp) llama-server utility

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"provider": {

"llama.cpp": {

"npm": "@ai-sdk/openai-compatible",

"name": "llama-server (local)",

"options": {

"baseURL": "http://127.0.0.1:8080/v1"

},

"models": {

"qwen3-coder:a3b": {

"name": "Qwen3-Coder: a3b-30b (local)",

"limit": {

"context": 128000,

"output": 65536

}

}

}

}

}

}
```

In this example:

* `llama.cpp` is the custom provider ID. This can be any string you want.
* `npm` specifies the package to use for this provider. Here, `@ai-sdk/openai-compatible` is used for any OpenAI-compatible API.
* `name` is the display name for the provider in the UI.
* `options.baseURL` is the endpoint for the local server.
* `models` is a map of model IDs to their configurations. The model name will be displayed in the model selection list.

---

#### [IO.NET](#ionet)

IO.NET offers 17 models optimized for various use cases:

1. Head over to the [IO.NET console](https://ai.io.net/), create an account, and generate an API key.
2. Run the `/connect` command and search for **IO.NET**.

   ```
   /connect
   ```
3. Enter your IO.NET API key.

   ```
   â API key

   â

   â

   â enter
   ```
4. Run the `/models` command to select a model.

   ```
   /models
   ```

---

#### [LM Studio](#lm-studio)

You can configure opencode to use local models through LM Studio.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"provider": {

"lmstudio": {

"npm": "@ai-sdk/openai-compatible",

"name": "LM Studio (local)",

"options": {

"baseURL": "http://127.0.0.1:1234/v1"

},

"models": {

"google/gemma-3n-e4b": {

"name": "Gemma 3n-e4b (local)"

}

}

}

}

}
```

In this example:

* `lmstudio` is the custom provider ID. This can be any string you want.
* `npm` specifies the package to use for this provider. Here, `@ai-sdk/openai-compatible` is used for any OpenAI-compatible API.
* `name` is the display name for the provider in the UI.
* `options.baseURL` is the endpoint for the local server.
* `models` is a map of model IDs to their configurations. The model name will be displayed in the model selection list.

---

#### [Moonshot AI](#moonshot-ai)

To use Kimi K2 from Moonshot AI:

1. Head over to the [Moonshot AI console](https://platform.moonshot.ai/console), create an account, and click **Create API key**.
2. Run the `/connect` command and search for **Moonshot AI**.

   ```
   /connect
   ```
3. Enter your Moonshot API key.

   ```
   â API key

   â

   â

   â enter
   ```
4. Run the `/models` command to select *Kimi K2*.

   ```
   /models
   ```

---

#### [MiniMax](#minimax)

1. Head over to the [MiniMax API Console](https://platform.minimax.io/login), create an account, and generate an API key.
2. Run the `/connect` command and search for **MiniMax**.

   ```
   /connect
   ```
3. Enter your MiniMax API key.

   ```
   â API key

   â

   â

   â enter
   ```
4. Run the `/models` command to select a model like *M2.1*.

   ```
   /models
   ```

---

#### [Modal](#modal)

1. Create a [shared Endpoint](https://modal.com/endpoints) for the model you want to use.
2. Create a [proxy token](https://modal.com/docs/guide/endpoints#proxy-tokens), then join its ID and secret with a period:

   ```
   wk-<id>.ws-<secret>
   ```
3. Run the `/connect` command, search for **Modal**, and enter the combined proxy token.

   ```
   /connect
   ```
4. Run the `/models` command to select one of the endpoints in your Modal workspace.

   ```
   /models
   ```

---

#### [NVIDIA](#nvidia)

NVIDIA provides access to Nemotron models and many other open models through [build.nvidia.com](https://build.nvidia.com) for free.

1. Head over to [build.nvidia.com](https://build.nvidia.com), create an account, and generate an API key.
2. Run the `/connect` command and search for **NVIDIA**.

   ```
   /connect
   ```
3. Enter your NVIDIA API key.

   ```
   â API key

   â

   â

   â enter
   ```
4. Run the `/models` command to select a model like nemotron-3-super-120b-a12b.

   ```
   /models
   ```

##### [On-Prem / NIM](#on-prem--nim)

You can also use NVIDIA models locally via [NVIDIA NIM](https://docs.nvidia.com/nim/) by setting a custom base URL.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"provider": {

"nvidia": {

"options": {

"baseURL": "http://localhost:8000/v1"

}

}

}

}
```

##### [Environment Variable](#environment-variable-1)

Alternatively, set your API key as an environment variable.

```
export NVIDIA_API_KEY=nvapi-your-key-here
```

---

#### [Nebius Token Factory](#nebius-token-factory)

1. Head over to the [Nebius Token Factory console](https://tokenfactory.nebius.com/), create an account, and click **Add Key**.
2. Run the `/connect` command and search for **Nebius Token Factory**.

   ```
   /connect
   ```
3. Enter your Nebius Token Factory API key.

   ```
   â API key

   â

   â

   â enter
   ```
4. Run the `/models` command to select a model like *Kimi K2 Instruct*.

   ```
   /models
   ```

---

#### [Ollama](#ollama)

You can configure opencode to use local models through Ollama.

Tip

Ollama can automatically configure itself for OpenCode. See the [Ollama integration docs](https://docs.ollama.com/integrations/opencode) for details.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"provider": {

"ollama": {

"npm": "@ai-sdk/openai-compatible",

"name": "Ollama (local)",

"options": {

"baseURL": "http://localhost:11434/v1"

},

"models": {

"llama2": {

"name": "Llama 2"

}

}

}

}

}
```

In this example:

* `ollama` is the custom provider ID. This can be any string you want.
* `npm` specifies the package to use for this provider. Here, `@ai-sdk/openai-compatible` is used for any OpenAI-compatible API.
* `name` is the display name for the provider in the UI.
* `options.baseURL` is the endpoint for the local server.
* `models` is a map of model IDs to their configurations. The model name will be displayed in the model selection list.

Tip

If tool calls arenât working, try increasing `num_ctx` in Ollama. Start around 16k - 32k.

---

#### [Ollama Cloud](#ollama-cloud)

To use Ollama Cloud with OpenCode:

1. Head over to <https://ollama.com/> and sign in or create an account.
2. Navigate to **Settings** > **Keys** and click **Add API Key** to generate a new API key.
3. Copy the API key for use in OpenCode.
4. Run the `/connect` command and search for **Ollama Cloud**.

   ```
   /connect
   ```
5. Enter your Ollama Cloud API key.

   ```
   â API key

   â

   â

   â enter
   ```
6. **Important**: Before using cloud models in OpenCode, you must pull the model information locally:

   Terminal window

   ```
   ollama pull gpt-oss:20b-cloud
   ```
7. Run the `/models` command to select your Ollama Cloud model.

   ```
   /models
   ```

---

#### [OpenAI](#openai)

We recommend signing up for [ChatGPT Plus or Pro](https://chatgpt.com/pricing).

1. Once youâve signed up, run the `/connect` command and select OpenAI.

   ```
   /connect
   ```
2. Here you can select the **ChatGPT Plus/Pro** option and itâll open your browser
   and ask you to authenticate.

   ```
   â Select auth method

   â

   â ChatGPT Plus/Pro

   â Manually enter API Key

   â
   ```
3. Now all the OpenAI models should be available when you use the `/models` command.

   ```
   /models
   ```

###### [Compute residency](#compute-residency)

For ChatGPT OAuth, OpenCode automatically applies a regional inference residency requirement when one is advertised by your workspace credentials. It forwards the compute residency value from the credential instead of maintaining a fixed list of regions. Data residency at rest does not imply regional inference.

###### [Using API keys](#using-api-keys)

If you already have an API key, you can select **Manually enter API Key** and paste it in your terminal.

---

#### [OpenCode Zen](#opencode-zen-1)

OpenCode Zen is a list of tested and verified models provided by the OpenCode team. [Learn more](https://opencode.ai/v2/docs/console/).

1. Sign in to **[OpenCode Zen](https://opencode.ai/auth)** and click **Create API Key**.
2. Run the `/connect` command and search for **OpenCode Zen**.

   ```
   /connect
   ```
3. Enter your OpenCode API key.

   ```
   â API key

   â

   â

   â enter
   ```
4. Run the `/models` command to select a model like *Qwen 3 Coder 480B*.

   ```
   /models
   ```

---

#### [OpenRouter](#openrouter)

1. Head over to the [OpenRouter dashboard](https://openrouter.ai/settings/keys), click **Create API Key**, and copy the key.
2. Run the `/connect` command and search for OpenRouter.

   ```
   /connect
   ```
3. Enter the API key for the provider.

   ```
   â API key

   â

   â

   â enter
   ```
4. Many OpenRouter models are preloaded by default, run the `/models` command to select the one you want.

   ```
   /models
   ```

   You can also add additional models through your opencode config.

   opencode.json

   ```
   {

   "$schema": "https://opencode.ai/config.json",

   "provider": {

   "openrouter": {

   "models": {

   "somecoolnewmodel": {}

   }

   }

   }

   }
   ```
5. You can also customize them through your opencode config. Hereâs an example of specifying a provider

   opencode.json

   ```
   {

   "$schema": "https://opencode.ai/config.json",

   "provider": {

   "openrouter": {

   "models": {

   "moonshotai/kimi-k2": {

   "options": {

   "provider": {

   "order": ["baseten"],

   "allow_fallbacks": false

   }

   }

   }

   }

   }

   }

   }
   ```

---

#### [LLM Gateway](#llm-gateway)

1. Head over to the [LLM Gateway dashboard](https://llmgateway.io/dashboard), click **Create API Key**, and copy the key.
2. Run the `/connect` command and search for LLM Gateway.

   ```
   /connect
   ```
3. Enter the API key for the provider.

   ```
   â API key

   â

   â

   â enter
   ```
4. Many LLM Gateway models are preloaded by default, run the `/models` command to select the one you want.

   ```
   /models
   ```

   You can also add additional models through your opencode config.

   opencode.json

   ```
   {

   "$schema": "https://opencode.ai/config.json",

   "provider": {

   "llmgateway": {

   "models": {

   "somecoolnewmodel": {}

   }

   }

   }

   }
   ```
5. You can also customize them through your opencode config. Hereâs an example of specifying a provider

   opencode.json

   ```
   {

   "$schema": "https://opencode.ai/config.json",

   "provider": {

   "llmgateway": {

   "models": {

   "glm-4.7": {

   "name": "GLM 4.7"

   },

   "gpt-5.2": {

   "name": "GPT-5.2"

   },

   "gemini-2.5-pro": {

   "name": "Gemini 2.5 Pro"

   },

   "claude-3-5-sonnet-20241022": {

   "name": "Claude 3.5 Sonnet"

   }

   }

   }

   }

   }
   ```

---

#### [Poolside](#poolside)

[Poolside](https://poolside.ai) provides access to its models through an OpenAI-compatible API.

1. Head over to [platform.poolside.ai](https://platform.poolside.ai), sign in, open the **API Keys** tab, and click **New key** to generate an API key.
2. Run the `/connect` command and search for **Poolside**.

   ```
   /connect
   ```
3. Enter your Poolside API key.

   ```
   â API key

   â

   â

   â enter
   ```
4. Run the `/models` command to select a model.

   ```
   /models
   ```

##### [Poolside deployment](#poolside-deployment)

If your organization runs a Poolside deployment, configure it as a custom OpenAI-compatible provider. Store the API key or token from your Poolside administrator in `~/.secrets/poolside-key`. Use a unique provider ID and add the model IDs available from your deployment.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"provider": {

"poolside-deployment": {

"npm": "@ai-sdk/openai-compatible",

"name": "Poolside deployment",

"options": {

"baseURL": "https://poolside.example.com/openai/v1",

"apiKey": "{file:~/.secrets/poolside-key}"

},

"models": {

"<served-model-id>": {

"name": "Poolside deployment model",

"reasoning": true,

"interleaved": {

"field": "reasoning_content"

}

}

}

}

}

}
```

Replace `poolside.example.com` with your deploymentâs host and `<served-model-id>` with a model ID returned by its `/openai/v1/models` endpoint. Model availability and thinking behavior depend on the deploymentâs configuration.

Tip

You can also install [Poolside Agent CLI](https://github.com/poolsideai/pool) to use Poolside agents directly from your terminal.

---

#### [SAP AI Core](#sap-ai-core)

SAP AI Core provides access to 40+ models from OpenAI, Anthropic, Google, Amazon, Meta, Mistral, and AI21 through a unified platform.

1. Go to your [SAP BTP Cockpit](https://account.hana.ondemand.com/), navigate to your SAP AI Core service instance, and create a service key.

   Tip

   The service key is a JSON object containing `clientid`, `clientsecret`, `url`, and `serviceurls.AI_API_URL`. You can find your AI Core instance under **Services** > **Instances and Subscriptions** in the BTP Cockpit.
2. Run the `/connect` command and search for **SAP AI Core**.

   ```
   /connect
   ```
3. Enter your service key JSON.

   ```
   â Service key

   â

   â

   â enter
   ```

   Or set the `AICORE_SERVICE_KEY` environment variable:

   Terminal window

   ```
   AICORE_SERVICE_KEY='{"clientid":"...","clientsecret":"...","url":"...","serviceurls":{"AI_API_URL":"..."}}' opencode
   ```

   Or add it to your bash profile:

   ~/.bash\_profile

   ```
   export AICORE_SERVICE_KEY='{"clientid":"...","clientsecret":"...","url":"...","serviceurls":{"AI_API_URL":"..."}}'
   ```
4. Optionally set deployment ID and resource group:

   Terminal window

   ```
   AICORE_DEPLOYMENT_ID=your-deployment-id AICORE_RESOURCE_GROUP=your-resource-group opencode
   ```

   Note

   These settings are optional and should be configured according to your SAP AI Core setup.
5. Run the `/models` command to select from 40+ available models.

   ```
   /models
   ```

---

#### [STACKIT](#stackit)

STACKIT AI Model Serving provides fully managed sovereign hosting environment for AI models, focusing on LLMs like Llama, Mistral, and Qwen, with maximum data sovereignty on European infrastructure.

1. Head over to [STACKIT Portal](https://portal.stackit.cloud), navigate to **AI Model Serving**, and create an auth token for your project.

   Tip

   You need a STACKIT customer account, user account, and project before creating auth tokens.
2. Run the `/connect` command and search for **STACKIT**.

   ```
   /connect
   ```
3. Enter your STACKIT AI Model Serving auth token.

   ```
   â API key

   â

   â

   â enter
   ```
4. Run the `/models` command to select from available models like *Qwen3-VL 235B* or *Llama 3.3 70B*.

   ```
   /models
   ```

---

#### [OVHcloud AI Endpoints](#ovhcloud-ai-endpoints)

1. Head over to the [OVHcloud panel](https://ovh.com/manager). Navigate to the `Public Cloud` section, `AI & Machine Learning` > `AI Endpoints` and in `API Keys` tab, click **Create a new API key**.
2. Run the `/connect` command and search for **OVHcloud AI Endpoints**.

   ```
   /connect
   ```
3. Enter your OVHcloud AI Endpoints API key.

   ```
   â API key

   â

   â

   â enter
   ```
4. Run the `/models` command to select a model like *gpt-oss-120b*.

   ```
   /models
   ```

---

#### [Scaleway](#scaleway)

To use [Scaleway Generative APIs](https://www.scaleway.com/en/docs/generative-apis/) with Opencode:

1. Head over to the [Scaleway Console IAM settings](https://console.scaleway.com/iam/api-keys) to generate a new API key.
2. Run the `/connect` command and search for **Scaleway**.

   ```
   /connect
   ```
3. Enter your Scaleway API key.

   ```
   â API key

   â

   â

   â enter
   ```
4. Run the `/models` command to select a model like *devstral-2-123b-instruct-2512* or *gpt-oss-120b*.

   ```
   /models
   ```

---

#### [SCX.ai](#scxai)

[SCX.ai](https://scx.ai) is an Australian sovereign AI platform serving open models over an OpenAI-compatible API, hosted on renewable-powered infrastructure in Australia.

1. Head over to the [SCX.ai platform](https://platform.scx.ai) to create an account and generate an API key.
2. Run the `/connect` command and search for **SCX.ai**.

   ```
   /connect
   ```
3. Enter your SCX.ai API key.

   ```
   â API key

   â

   â

   â enter
   ```
4. Run the `/models` command to select a model like *MiniMax-M2.7* or *GLM-5.2*.

   ```
   /models
   ```

---

#### [Snowflake Cortex](#snowflake-cortex)

[Snowflake Cortex](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-rest-api) gives you access to frontier models (Claude, OpenAI GPT-5, and more) via an OpenAI-compatible API. All inference runs within the Snowflake perimeter and is billed in Snowflake credits. For per-model rates, see the [Snowflake Service Consumption Table](https://www.snowflake.com/legal-files/CreditConsumptionTable.pdf).

Donât have a Snowflake account? [Sign up for a free trial](https://signup.snowflake.com/?utm_source=opencode&utm_medium=docs&utm_campaign=cortex-provider).

opencodeâs core workflow for coding, editing files, and running commands relies on tool calling. Only the Claude and OpenAI families within Snowflake Cortex support this. The provider is limited to those families to support the core workflow.

OpenCode supports two authentication methods:

* **Browser OAuth (Recommended)** â sign in with your IdP/SSO; no secrets to manage, tokens refresh automatically.
* **Manual bearer token** â paste a PAT or JWT from the Snowflake console.

##### [Browser OAuth (Recommended)](#browser-oauth-recommended)

1. Run the `/connect` command and search for **Snowflake Cortex**.

   ```
   /connect
   ```
2. Select **Login with Snowflake (External Browser)**.

   ```
   â Select auth method

   â

   â Login with Snowflake (External Browser)

   â Paste PAT or bearer token manually

   â
   ```
3. Enter your [account identifier](https://docs.snowflake.com/en/user-guide/admin-account-identifier) when prompted, for example `myorg-myaccount` or `xy12345.us-east-1`.

   ```
   â Snowflake Account Identifier

   â

   â

   â enter
   ```
4. Optionally enter a Snowflake role to scope the session (e.g. `SYSADMIN`). Leave blank to use your default role.
5. Complete sign-in in the browser that opens. OpenCode captures the OAuth callback automatically and stores the token â no copy/paste needed.
6. Run the `/models` command to select a model.

   ```
   /models
   ```

Note

Browser OAuth uses Snowflakeâs built-in `SNOWFLAKE$LOCAL_APPLICATION` security integration ([docs](https://docs.snowflake.com/en/user-guide/oauth-local-applications)), which is rolling out to all accounts. To check availability in your account:

```
SHOW SECURITY INTEGRATIONS LIKE 'SNOWFLAKE$LOCAL_APPLICATION';
```

If the result is empty, use the **Manual bearer token** method below while the integration rolls out to your account.

##### [Manual bearer token](#manual-bearer-token)

If you prefer to paste a token directly, or if `SNOWFLAKE$LOCAL_APPLICATION` is not yet available in your account:

1. Generate a [Programmatic Access Token (PAT)](https://docs.snowflake.com/en/user-guide/programmatic-access-tokens) in your Snowflake account.
2. Run the `/connect` command, search for **Snowflake Cortex**, and select **Paste PAT or bearer token manually**.
3. Enter your [account identifier](https://docs.snowflake.com/en/user-guide/admin-account-identifier) when prompted.
4. Paste your PAT.
5. Run the `/models` command to select a model.

   ```
   /models
   ```

##### [Environment variable](#environment-variable-2)

For CI or headless environments, set a PAT or JWT before starting opencode:

Terminal window

```
export SNOWFLAKE_ACCOUNT=myorg-myaccount

export SNOWFLAKE_CORTEX_TOKEN=your-pat-or-jwt
```

Note

`SNOWFLAKE_CORTEX_TOKEN` accepts a PAT or JWT only â the browser OAuth flow is available via `/connect` only and cannot be configured through an environment variable. `SNOWFLAKE_CORTEX_PAT` is still supported for backward compatibility.

The model catalog is provided automatically. A minimal `opencode.json` is all thatâs needed:

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"model": "snowflake-cortex/claude-sonnet-4-6",

"small_model": "snowflake-cortex/claude-haiku-4-5"

}
```

---

#### [Together AI](#together-ai)

1. Head over to the [Together AI console](https://api.together.ai), create an account, and click **Add Key**.
2. Run the `/connect` command and search for **Together AI**.

   ```
   /connect
   ```
3. Enter your Together AI API key.

   ```
   â API key

   â

   â

   â enter
   ```
4. Run the `/models` command to select a model like *Kimi K2 Instruct*.

   ```
   /models
   ```

---

#### [Venice AI](#venice-ai)

1. Head over to the [Venice AI console](https://venice.ai), create an account, and generate an API key.
2. Run the `/connect` command and search for **Venice AI**.

   ```
   /connect
   ```
3. Enter your Venice AI API key.

   ```
   â API key

   â

   â

   â enter
   ```
4. Run the `/models` command to select a model like *Llama 3.3 70B*.

   ```
   /models
   ```

---

#### [Vercel AI Gateway](#vercel-ai-gateway)

Vercel AI Gateway lets you access models from OpenAI, Anthropic, Google, xAI, and more through a unified endpoint. Models are offered at list price with no markup.

1. Head over to the [Vercel dashboard](https://vercel.com/), navigate to the **AI Gateway** tab, and click **API keys** to create a new API key.
2. Run the `/connect` command and search for **Vercel AI Gateway**.

   ```
   /connect
   ```
3. Enter your Vercel AI Gateway API key.

   ```
   â API key

   â

   â

   â enter
   ```
4. Run the `/models` command to select a model.

   ```
   /models
   ```

You can also customize models through your opencode config. Hereâs an example of specifying provider routing order.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"provider": {

"vercel": {

"models": {

"anthropic/claude-sonnet-4": {

"options": {

"order": ["anthropic", "vertex"]

}

}

}

}

}

}
```

Some useful routing options:

| Option | Description |
| --- | --- |
| `order` | Provider sequence to try |
| `only` | Restrict to specific providers |
| `zeroDataRetention` | Only use providers with zero data retention policies |

---

#### [xAI](#xai)

Two ways to authenticate: a SuperGrok subscription via device-code OAuth or a pay-as-you-go API key from the xAI console.

##### [Option A â SuperGrok subscription](#option-a--supergrok-subscription)

1. Run the `/connect` command and search for **xAI**.

   ```
   /connect
   ```
2. Select **SuperGrok Subscription**. OpenCode opens xAIâs verification link with the user code pre-populated when supported.
3. Approve the consent screen. If xAI asks for a code, enter the user code displayed by OpenCode. OpenCode polls xAIâs token endpoint and stores the resulting OAuth tokens once you approve.
4. Run the `/models` command to select a Grok model.

   ```
   /models
   ```

OpenCode refreshes the OAuth access token automatically. Any Grok or X Premium plan that includes Grok API access works; you do not need a separate `XAI_API_KEY`.

##### [Option B â API key](#option-b--api-key)

1. Head over to the [xAI console](https://console.x.ai/), create an account, and generate an API key.
2. Run the `/connect` command and search for **xAI**.

   ```
   /connect
   ```
3. Select **Manually enter API Key** and paste your xAI API key.

   ```
   â API key

   â

   â

   â enter
   ```
4. Run the `/models` command to select a model like *Grok Beta*.

   ```
   /models
   ```

---

#### [Z.AI](#zai)

1. Head over to the [Z.AI API console](https://z.ai/manage-apikey/apikey-list), create an account, and click **Create a new API key**.
2. Run the `/connect` command and search for **Z.AI**.

   ```
   /connect
   ```

   If you are subscribed to the **GLM Coding Plan**, select **Z.AI Coding Plan**.
3. Enter your Z.AI API key.

   ```
   â API key

   â

   â

   â enter
   ```
4. Run the `/models` command to select a model like *GLM-4.7*.

   ```
   /models
   ```

---

#### [ZenMux](#zenmux)

1. Head over to the [ZenMux dashboard](https://zenmux.ai/settings/keys), click **Create API Key**, and copy the key.
2. Run the `/connect` command and search for ZenMux.

   ```
   /connect
   ```
3. Enter the API key for the provider.

   ```
   â API key

   â

   â

   â enter
   ```
4. Many ZenMux models are preloaded by default, run the `/models` command to select the one you want.

   ```
   /models
   ```

   You can also add additional models through your opencode config.

   opencode.json

   ```
   {

   "$schema": "https://opencode.ai/config.json",

   "provider": {

   "zenmux": {

   "models": {

   "somecoolnewmodel": {}

   }

   }

   }

   }
   ```

---

### [Custom provider](#custom-provider)

To add any **OpenAI-compatible** provider thatâs not listed in the `/connect` command:

Tip

You can use any OpenAI-compatible provider with opencode. Most modern AI providers offer OpenAI-compatible APIs.

1. Run the `/connect` command and scroll down to **Other**.

   Terminal window

   ```
   $ /connect

   â  Add credential

   â

   â  Select provider

   â  ...

   â  â Other

   â
   ```
2. Enter a unique ID for the provider.

   Terminal window

   ```
   $ /connect

   â  Add credential

   â

   â  Enter provider id

   â  myprovider

   â
   ```

   Note

   Choose a memorable ID, youâll use this in your config file.
3. Enter your API key for the provider.

   Terminal window

   ```
   $ /connect

   â  Add credential

   â

   â²  This only stores a credential for myprovider - you will need to configure it in opencode.json, check the docs for examples.

   â

   â  Enter your API key

   â  sk-...

   â
   ```
4. Create or update your `opencode.json` file in your project directory:

   opencode.json

   ```
   {

   "$schema": "https://opencode.ai/config.json",

   "provider": {

   "myprovider": {

   "npm": "@ai-sdk/openai-compatible",

   "name": "My AI Provider Display Name",

   "options": {

   "baseURL": "https://api.myprovider.com/v1"

   },

   "models": {

   "my-model-name": {

   "name": "My Model Display Name"

   }

   }

   }

   }

   }
   ```

   Here are the configuration options:

   * **npm**: AI SDK package to use, `@ai-sdk/openai-compatible` for OpenAI-compatible providers (for `/v1/chat/completions`). If your provider/model uses `/v1/responses`, use `@ai-sdk/openai`.
   * **name**: Display name in UI.
   * **models**: Available models.
   * **options.baseURL**: API endpoint URL.
   * **options.apiKey**: Optionally set the API key, if not using auth.
   * **options.headers**: Optionally set custom headers.

   More on the advanced options in the example below.
5. Run the `/models` command and your custom provider and models will appear in the selection list.

---

###### [Example](#example)

Hereâs an example setting the `apiKey`, `headers`, and model `limit` options.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"provider": {

"myprovider": {

"npm": "@ai-sdk/openai-compatible",

"name": "My AI Provider Display Name",

"options": {

"baseURL": "https://api.myprovider.com/v1",

"apiKey": "{env:ANTHROPIC_API_KEY}",

"headers": {

"Authorization": "Bearer custom-token"

}

},

"models": {

"my-model-name": {

"name": "My Model Display Name",

"limit": {

"context": 200000,

"output": 65536

}

}

}

}

}

}
```

Configuration details:

* **apiKey**: Set using `env` variable syntax, [learn more](/docs/config#env-vars).
* **headers**: Custom headers sent with each request.
* **limit.context**: Maximum input tokens the model accepts.
* **limit.output**: Maximum tokens the model can generate.

The `limit` fields allow OpenCode to understand how much context you have left. Standard providers pull these from models.dev automatically.

---

### [Troubleshooting](#troubleshooting)

If you are having trouble with configuring a provider, check the following:

1. **Check the auth setup**: Run `opencode auth list` to see if the credentials
   for the provider are added to your config.

   This doesnât apply to providers like Amazon Bedrock, that rely on environment variables for their auth.
2. For custom providers, check the opencode config and:

   * Make sure the provider ID used in the `/connect` command matches the ID in your opencode config.
   * The right npm package is used for the provider. For example, use `@ai-sdk/cerebras` for Cerebras. And for all other OpenAI-compatible providers, use `@ai-sdk/openai-compatible` (for `/v1/chat/completions`); if a model uses `/v1/responses`, use `@ai-sdk/openai`. For mixed setups under one provider, you can override per model via `provider.npm`.
   * Check correct API endpoint is used in the `options.baseURL` field.

[Edit page](https://github.com/anomalyco/opencode/edit/dev/packages/web/src/content/docs/providers.mdx)[Found a bug? Open an issue](https://github.com/anomalyco/opencode/issues/new)[Join our Discord community](https://opencode.ai/discord)  Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

© [Anomaly](https://anoma.ly)

Last updated: Oct 13, 2026

---
<!--
URL: https://opencode.ai/docs/github/
title: GitHub | OpenCode
-->

[Skip to content](#_top)

[![](/docs/_astro/logo-dark.DOStV66V.svg) ![](/docs/_astro/logo-light.B0yzR0O5.svg)  OpenCode](/docs/)

[app.header.home](/)[app.header.docs](/v2/docs)

Search  `CtrlK`

Cancel

  [New OpenCode v2 is now available →](https://opencode.ai/v2)

* [Intro](/docs/)
* [Config](/docs/config/)
* [Providers](/docs/providers/)
* [Network](/docs/network/)
* [Enterprise](/docs/enterprise/)
* [Troubleshooting](/docs/troubleshooting/)
* [Windows](/docs/windows-wsl)
* Usage

  + [Go](https://opencode.ai/v2/docs/console/go/)
  + [TUI](/docs/tui/)
  + [CLI](/docs/cli/)
  + [Web](/docs/web/)
  + [IDE](/docs/ide/)
  + [Console](https://opencode.ai/v2/docs/console/)
  + [Share](/docs/share/)
  + [GitHub](/docs/github/)
  + [GitLab](/docs/gitlab/)
* Configure

  + [Tools](/docs/tools/)
  + [Rules](/docs/rules/)
  + [Agents](/docs/agents/)
  + [Models](/docs/models/)
  + [Themes](/docs/themes/)
  + [Keybinds](/docs/keybinds/)
  + [Commands](/docs/commands/)
  + [Formatters](/docs/formatters/)
  + [Permissions](/docs/permissions/)
  + [Policies](/docs/policies/)
  + [LSP Servers](/docs/lsp/)
  + [MCP servers](/docs/mcp-servers/)
  + [ACP Support](/docs/acp/)
  + [Agent Skills](/docs/skills/)
  + [References](/docs/references/)
  + [Custom Tools](/docs/custom-tools/)
* Develop

  + [SDK](/docs/sdk/)
  + [Server](/docs/server/)
  + [Plugins](/docs/plugins/)
  + [Ecosystem](/docs/ecosystem/)

[GitHub](https://github.com/anomalyco/opencode)[Discord](https://opencode.ai/discord)

  Select theme   DarkLightAuto         Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

On this page

* [Overview](#_top)
* [Features](#features)
* [Installation](#installation)
  + [Manual Setup](#manual-setup)
* [Configuration](#configuration)
* [Supported Events](#supported-events)
  + [Schedule Example](#schedule-example)
  + [Pull Request Example](#pull-request-example)
  + [Issues Triage Example](#issues-triage-example)
* [Custom prompts](#custom-prompts)
* [Examples](#examples)

### On this page

* [Overview](#_top)
* [Features](#features)
* [Installation](#installation)
  + [Manual Setup](#manual-setup)
* [Configuration](#configuration)
* [Supported Events](#supported-events)
  + [Schedule Example](#schedule-example)
  + [Pull Request Example](#pull-request-example)
  + [Issues Triage Example](#issues-triage-example)
* [Custom prompts](#custom-prompts)
* [Examples](#examples)

## GitHub

Use OpenCode in GitHub issues and pull-requests.

OpenCode integrates with your GitHub workflow. Mention `/opencode` or `/oc` in your comment, and OpenCode will execute tasks within your GitHub Actions runner.

---

### [Features](#features)

* **Triage issues**: Ask OpenCode to look into an issue and explain it to you.
* **Fix and implement**: Ask OpenCode to fix an issue or implement a feature. And it will work in a new branch and submits a PR with all the changes.
* **Secure**: OpenCode runs inside your GitHubâs runners.

---

### [Installation](#installation)

Run the following command in a project that is in a GitHub repo:

Terminal window

```
opencode github install
```

This will walk you through installing the GitHub app, creating the workflow, and setting up secrets.

---

#### [Manual Setup](#manual-setup)

Or you can set it up manually.

1. **Install the GitHub app**

   Head over to [**github.com/apps/opencode-agent**](https://github.com/apps/opencode-agent). Make sure itâs installed on the target repository.
2. **Add the workflow**

   Add the following workflow file to `.github/workflows/opencode.yml` in your repo. Make sure to set the appropriate `model` and required API keys in `env`.

   .github/workflows/opencode.yml

   ```
   name: opencode

   on:

   issue_comment:

   types: [created]

   pull_request_review_comment:

   types: [created]

   jobs:

   opencode:

   if: |

   contains(github.event.comment.body, '/oc') ||

   contains(github.event.comment.body, '/opencode')

   runs-on: ubuntu-latest

   permissions:

   id-token: write

   steps:

   - name: Checkout repository

   uses: actions/checkout@v6

   with:

   fetch-depth: 1

   persist-credentials: false

   - name: Run OpenCode

   uses: anomalyco/opencode/github@latest

   env:

   ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}

   with:

   model: anthropic/claude-sonnet-4-20250514

   # share: true
   ```
3. **Store the API keys in secrets**

   In your organization or project **settings**, expand **Secrets and variables** on the left and select **Actions**. And add the required API keys.

---

### [Configuration](#configuration)

* `model`: The model to use with OpenCode. Takes the format of `provider/model`. This is **required**.
* `agent`: The agent to use. Must be a primary agent. Falls back to `default_agent` from config or `"build"` if not found.
* `share`: Whether to share the OpenCode session. Defaults to **true** for public repositories.
* `prompt`: Optional custom prompt to override the default behavior. Use this to customize how OpenCode processes requests.
* `mentions`: Comma-separated list of trigger phrases, case-insensitive. Defaults to `/opencode,/oc`.
* `variant`: Model variant for provider-specific reasoning effort, for example `high`, `max`, or `minimal`.
* `oidc_base_url`: Base URL for the OIDC token exchange API. Only needed when running a custom GitHub App install. Defaults to `https://api.opencode.ai`.
* `use_github_token`: Set to `true` to use a caller-provided `GITHUB_TOKEN` instead of exchanging an OIDC token for an OpenCode App installation token. Defaults to `false`.

  Use this mode to run without installing the OpenCode GitHub App. Pass the token through `env` and grant the permissions required by your workflow:

  ```
  permissions:

  contents: write

  pull-requests: write

  issues: write

  steps:

  - uses: anomalyco/opencode/github@latest

  env:

  ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}

  GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

  with:

  model: anthropic/claude-sonnet-4-20250514

  use_github_token: true
  ```

  `id-token: write` is not required in this mode because OIDC exchange is skipped. To use a [personal access token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens) or another GitHub App token, store it as a secret and pass that secret as `GITHUB_TOKEN` instead.

---

### [Supported Events](#supported-events)

OpenCode can be triggered by the following GitHub events:

| Event Type | Triggered By | Details |
| --- | --- | --- |
| `issue_comment` | Comment on an issue or PR | Mention `/opencode` or `/oc` in your comment. OpenCode reads context and can create branches, open PRs, or reply. |
| `pull_request_review_comment` | Comment on specific code lines in a PR | Mention `/opencode` or `/oc` while reviewing code. OpenCode receives file path, line numbers, and diff context. |
| `issues` | Issue opened or edited | Automatically trigger OpenCode when issues are created or modified. Requires `prompt` input. |
| `pull_request` | PR opened or updated | Automatically trigger OpenCode when PRs are opened, synchronized, or reopened. Useful for automated reviews. |
| `schedule` | Cron-based schedule | Run OpenCode on a schedule. Requires `prompt` input. Output goes to logs and PRs (no issue to comment on). |
| `workflow_dispatch` | Manual trigger from GitHub UI | Trigger OpenCode on demand via Actions tab. Requires `prompt` input. Output goes to logs and PRs. |

#### [Schedule Example](#schedule-example)

Run OpenCode on a schedule to perform automated tasks:

.github/workflows/opencode-scheduled.yml

```
name: Scheduled OpenCode Task

on:

schedule:

- cron: "0 9 * * 1" # Every Monday at 9am UTC

jobs:

opencode:

runs-on: ubuntu-latest

permissions:

id-token: write

contents: write

pull-requests: write

issues: write

steps:

- name: Checkout repository

uses: actions/checkout@v6

with:

persist-credentials: false

- name: Run OpenCode

uses: anomalyco/opencode/github@latest

env:

ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}

with:

model: anthropic/claude-sonnet-4-20250514

prompt: |

Review the codebase for any TODO comments and create a summary.

If you find issues worth addressing, open an issue to track them.
```

For scheduled events, the `prompt` input is **required** since thereâs no comment to extract instructions from. Scheduled workflows run without a user context to permission-check, so the workflow must grant `contents: write` and `pull-requests: write` if you expect OpenCode to create branches or PRs.

---

#### [Pull Request Example](#pull-request-example)

Automatically review PRs when they are opened or updated:

.github/workflows/opencode-review.yml

```
name: opencode-review

on:

pull_request:

types: [opened, synchronize, reopened, ready_for_review]

jobs:

review:

runs-on: ubuntu-latest

permissions:

id-token: write

contents: read

pull-requests: read

issues: read

steps:

- uses: actions/checkout@v6

with:

persist-credentials: false

- uses: anomalyco/opencode/github@latest

env:

ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}

GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

with:

model: anthropic/claude-sonnet-4-20250514

use_github_token: true

prompt: |

Review this pull request:

- Check for code quality issues

- Look for potential bugs

- Suggest improvements
```

For `pull_request` events, if no `prompt` is provided, OpenCode defaults to reviewing the pull request.

---

#### [Issues Triage Example](#issues-triage-example)

Automatically triage new issues. This example filters to accounts older than 30 days to reduce spam:

.github/workflows/opencode-triage.yml

```
name: Issue Triage

on:

issues:

types: [opened]

jobs:

triage:

runs-on: ubuntu-latest

permissions:

id-token: write

contents: write

pull-requests: write

issues: write

steps:

- name: Check account age

id: check

uses: actions/github-script@v7

with:

script: |

const user = await github.rest.users.getByUsername({

username: context.payload.issue.user.login

});

const created = new Date(user.data.created_at);

const days = (Date.now() - created) / (1000 * 60 * 60 * 24);

return days >= 30;

result-encoding: string

- uses: actions/checkout@v6

if: steps.check.outputs.result == 'true'

with:

persist-credentials: false

- uses: anomalyco/opencode/github@latest

if: steps.check.outputs.result == 'true'

env:

ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}

with:

model: anthropic/claude-sonnet-4-20250514

prompt: |

Review this issue. If there's a clear fix or relevant docs:

- Provide documentation links

- Add error handling guidance for code examples

Otherwise, do not comment.
```

For `issues` events, the `prompt` input is **required** since thereâs no comment to extract instructions from.

---

### [Custom prompts](#custom-prompts)

Override the default prompt to customize OpenCodeâs behavior for your workflow.

.github/workflows/opencode.yml

```
- uses: anomalyco/opencode/github@latest

with:

model: anthropic/claude-sonnet-4-5

prompt: |

Review this pull request:

- Check for code quality issues

- Look for potential bugs

- Suggest improvements
```

This is useful for enforcing specific review criteria, coding standards, or focus areas relevant to your project.

---

### [Examples](#examples)

Here are some examples of how you can use OpenCode in GitHub.

* **Explain an issue**

  Add this comment in a GitHub issue.

  ```
  /opencode explain this issue
  ```

  OpenCode will read the entire thread, including all comments, and reply with a clear explanation.
* **Fix an issue**

  In a GitHub issue, say:

  ```
  /opencode fix this
  ```

  And OpenCode will create a new branch, implement the changes, and open a PR with the changes.
* **Review PRs and make changes**

  Leave the following comment on a GitHub PR.

  ```
  Delete the attachment from S3 when the note is removed /oc
  ```

  OpenCode will implement the requested change and commit it to the same PR.
* **Review specific code lines**

  Leave a comment directly on code lines in the PRâs âFilesâ tab. OpenCode automatically detects the file, line numbers, and diff context to provide precise responses.

  ```
  [Comment on specific lines in Files tab]

  /oc add error handling here
  ```

  When commenting on specific lines, OpenCode receives:

  + The exact file being reviewed
  + The specific lines of code
  + The surrounding diff context
  + Line number information

  This allows for more targeted requests without needing to specify file paths or line numbers manually.

[Edit page](https://github.com/anomalyco/opencode/edit/dev/packages/web/src/content/docs/github.mdx)[Found a bug? Open an issue](https://github.com/anomalyco/opencode/issues/new)[Join our Discord community](https://opencode.ai/discord)  Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

© [Anomaly](https://anoma.ly)

Last updated: Oct 13, 2026

---
<!--
URL: https://opencode.ai/docs/network/
title: Network | OpenCode
-->

[Skip to content](#_top)

[![](/docs/_astro/logo-dark.DOStV66V.svg) ![](/docs/_astro/logo-light.B0yzR0O5.svg)  OpenCode](/docs/)

[app.header.home](/)[app.header.docs](/v2/docs)

Search  `CtrlK`

Cancel

  [New OpenCode v2 is now available →](https://opencode.ai/v2)

* [Intro](/docs/)
* [Config](/docs/config/)
* [Providers](/docs/providers/)
* [Network](/docs/network/)
* [Enterprise](/docs/enterprise/)
* [Troubleshooting](/docs/troubleshooting/)
* [Windows](/docs/windows-wsl)
* Usage

  + [Go](https://opencode.ai/v2/docs/console/go/)
  + [TUI](/docs/tui/)
  + [CLI](/docs/cli/)
  + [Web](/docs/web/)
  + [IDE](/docs/ide/)
  + [Console](https://opencode.ai/v2/docs/console/)
  + [Share](/docs/share/)
  + [GitHub](/docs/github/)
  + [GitLab](/docs/gitlab/)
* Configure

  + [Tools](/docs/tools/)
  + [Rules](/docs/rules/)
  + [Agents](/docs/agents/)
  + [Models](/docs/models/)
  + [Themes](/docs/themes/)
  + [Keybinds](/docs/keybinds/)
  + [Commands](/docs/commands/)
  + [Formatters](/docs/formatters/)
  + [Permissions](/docs/permissions/)
  + [Policies](/docs/policies/)
  + [LSP Servers](/docs/lsp/)
  + [MCP servers](/docs/mcp-servers/)
  + [ACP Support](/docs/acp/)
  + [Agent Skills](/docs/skills/)
  + [References](/docs/references/)
  + [Custom Tools](/docs/custom-tools/)
* Develop

  + [SDK](/docs/sdk/)
  + [Server](/docs/server/)
  + [Plugins](/docs/plugins/)
  + [Ecosystem](/docs/ecosystem/)

[GitHub](https://github.com/anomalyco/opencode)[Discord](https://opencode.ai/discord)

  Select theme   DarkLightAuto         Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

On this page

* [Overview](#_top)
* [Proxy](#proxy)
  + [Authenticate](#authenticate)
* [Custom certificates](#custom-certificates)

### On this page

* [Overview](#_top)
* [Proxy](#proxy)
  + [Authenticate](#authenticate)
* [Custom certificates](#custom-certificates)

## Network

Configure proxies and custom certificates.

OpenCode supports standard proxy environment variables and custom certificates for enterprise network environments.

---

### [Proxy](#proxy)

OpenCode respects standard proxy environment variables.

Terminal window

```

## HTTPS proxy (recommended)

export HTTPS_PROXY=https://proxy.example.com:8080

## HTTP proxy (if HTTPS not available)

export HTTP_PROXY=http://proxy.example.com:8080

## Bypass proxy for local server (required)

export NO_PROXY=localhost,127.0.0.1
```

Caution

The TUI communicates with a local HTTP server. You must bypass the proxy for this connection to prevent routing loops.

You can configure the serverâs port and hostname using [CLI flags](/docs/cli#run).

---

#### [Authenticate](#authenticate)

If your proxy requires basic authentication, include credentials in the URL.

Terminal window

```
export HTTPS_PROXY=http://username:password@proxy.example.com:8080
```

Caution

Avoid hardcoding passwords. Use environment variables or secure credential storage.

For proxies requiring advanced authentication like NTLM or Kerberos, consider using an LLM Gateway that supports your authentication method.

---

### [Custom certificates](#custom-certificates)

If your enterprise uses custom CAs for HTTPS connections, configure OpenCode to trust them.

Terminal window

```
export NODE_EXTRA_CA_CERTS=/path/to/ca-cert.pem
```

This works for both proxy connections and direct API access.

[Edit page](https://github.com/anomalyco/opencode/edit/dev/packages/web/src/content/docs/network.mdx)[Found a bug? Open an issue](https://github.com/anomalyco/opencode/issues/new)[Join our Discord community](https://opencode.ai/discord)  Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

© [Anomaly](https://anoma.ly)

Last updated: Oct 13, 2026

---
<!--
URL: https://opencode.ai/docs/share
title: Share | OpenCode
-->

[Skip to content](#_top)

[![](/docs/_astro/logo-dark.DOStV66V.svg) ![](/docs/_astro/logo-light.B0yzR0O5.svg)  OpenCode](/docs/)

[app.header.home](/)[app.header.docs](/v2/docs)

Search  `CtrlK`

Cancel

  [New OpenCode v2 is now available →](https://opencode.ai/v2)

* [Intro](/docs/)
* [Config](/docs/config/)
* [Providers](/docs/providers/)
* [Network](/docs/network/)
* [Enterprise](/docs/enterprise/)
* [Troubleshooting](/docs/troubleshooting/)
* [Windows](/docs/windows-wsl)
* Usage

  + [Go](https://opencode.ai/v2/docs/console/go/)
  + [TUI](/docs/tui/)
  + [CLI](/docs/cli/)
  + [Web](/docs/web/)
  + [IDE](/docs/ide/)
  + [Console](https://opencode.ai/v2/docs/console/)
  + [Share](/docs/share/)
  + [GitHub](/docs/github/)
  + [GitLab](/docs/gitlab/)
* Configure

  + [Tools](/docs/tools/)
  + [Rules](/docs/rules/)
  + [Agents](/docs/agents/)
  + [Models](/docs/models/)
  + [Themes](/docs/themes/)
  + [Keybinds](/docs/keybinds/)
  + [Commands](/docs/commands/)
  + [Formatters](/docs/formatters/)
  + [Permissions](/docs/permissions/)
  + [Policies](/docs/policies/)
  + [LSP Servers](/docs/lsp/)
  + [MCP servers](/docs/mcp-servers/)
  + [ACP Support](/docs/acp/)
  + [Agent Skills](/docs/skills/)
  + [References](/docs/references/)
  + [Custom Tools](/docs/custom-tools/)
* Develop

  + [SDK](/docs/sdk/)
  + [Server](/docs/server/)
  + [Plugins](/docs/plugins/)
  + [Ecosystem](/docs/ecosystem/)

[GitHub](https://github.com/anomalyco/opencode)[Discord](https://opencode.ai/discord)

  Select theme   DarkLightAuto         Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

On this page

* [Overview](#_top)
* [How it works](#how-it-works)
* [Sharing](#sharing)
  + [Manual (default)](#manual-default)
  + [Auto-share](#auto-share)
  + [Disabled](#disabled)
* [Un-sharing](#un-sharing)
* [Privacy](#privacy)
  + [Data retention](#data-retention)
  + [Recommendations](#recommendations)
* [For enterprises](#for-enterprises)

### On this page

* [Overview](#_top)
* [How it works](#how-it-works)
* [Sharing](#sharing)
  + [Manual (default)](#manual-default)
  + [Auto-share](#auto-share)
  + [Disabled](#disabled)
* [Un-sharing](#un-sharing)
* [Privacy](#privacy)
  + [Data retention](#data-retention)
  + [Recommendations](#recommendations)
* [For enterprises](#for-enterprises)

## Share

Share your OpenCode conversations.

OpenCodeâs share feature allows you to create public links to your OpenCode conversations, so you can collaborate with teammates or get help from others.

Note

Shared conversations are publicly accessible to anyone with the link.

---

### [How it works](#how-it-works)

When you share a conversation, OpenCode:

1. Creates a unique public URL for your session
2. Syncs your conversation history to our servers
3. Makes the conversation accessible via the shareable link â `opncd.ai/s/<share-id>`

---

### [Sharing](#sharing)

OpenCode supports three sharing modes that control how conversations are shared:

---

#### [Manual (default)](#manual-default)

By default, OpenCode uses manual sharing mode. Sessions are not shared automatically, but you can manually share them using the `/share` command:

```
/share
```

This will generate a unique URL thatâll be copied to your clipboard.

To explicitly set manual mode in your [config file](/docs/config):

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"share": "manual"

}
```

---

#### [Auto-share](#auto-share)

You can enable automatic sharing for all new conversations by setting the `share` option to `"auto"` in your [config file](/docs/config):

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"share": "auto"

}
```

With auto-share enabled, every new conversation will automatically be shared and a link will be generated.

---

#### [Disabled](#disabled)

You can disable sharing entirely by setting the `share` option to `"disabled"` in your [config file](/docs/config):

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"share": "disabled"

}
```

To enforce this across your team for a given project, add it to the `opencode.json` in your project and check into Git.

---

### [Un-sharing](#un-sharing)

To stop sharing a conversation and remove it from public access:

```
/unshare
```

This will remove the share link and delete the data related to the conversation.

---

### [Privacy](#privacy)

There are a few things to keep in mind when sharing a conversation.

---

#### [Data retention](#data-retention)

Shared conversations remain accessible until you explicitly unshare them. This
includes:

* Full conversation history
* All messages and responses
* Session metadata

---

#### [Recommendations](#recommendations)

* Only share conversations that donât contain sensitive information.
* Review conversation content before sharing.
* Unshare conversations when collaboration is complete.
* Avoid sharing conversations with proprietary code or confidential data.
* For sensitive projects, disable sharing entirely.

---

### [For enterprises](#for-enterprises)

For enterprise deployments, the share feature can be:

* **Disabled** entirely for security compliance
* **Restricted** to users authenticated through SSO only
* **Self-hosted** on your own infrastructure

[Learn more](/docs/enterprise) about using opencode in your organization.

[Edit page](https://github.com/anomalyco/opencode/edit/dev/packages/web/src/content/docs/share.mdx)[Found a bug? Open an issue](https://github.com/anomalyco/opencode/issues/new)[Join our Discord community](https://opencode.ai/discord)  Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

© [Anomaly](https://anoma.ly)

Last updated: Oct 13, 2026

---
<!--
URL: https://opencode.ai/docs/permissions/
title: Permissions | OpenCode
-->

[Skip to content](#_top)

[![](/docs/_astro/logo-dark.DOStV66V.svg) ![](/docs/_astro/logo-light.B0yzR0O5.svg)  OpenCode](/docs/)

[app.header.home](/)[app.header.docs](/v2/docs)

Search  `CtrlK`

Cancel

  [New OpenCode v2 is now available →](https://opencode.ai/v2)

* [Intro](/docs/)
* [Config](/docs/config/)
* [Providers](/docs/providers/)
* [Network](/docs/network/)
* [Enterprise](/docs/enterprise/)
* [Troubleshooting](/docs/troubleshooting/)
* [Windows](/docs/windows-wsl)
* Usage

  + [Go](https://opencode.ai/v2/docs/console/go/)
  + [TUI](/docs/tui/)
  + [CLI](/docs/cli/)
  + [Web](/docs/web/)
  + [IDE](/docs/ide/)
  + [Console](https://opencode.ai/v2/docs/console/)
  + [Share](/docs/share/)
  + [GitHub](/docs/github/)
  + [GitLab](/docs/gitlab/)
* Configure

  + [Tools](/docs/tools/)
  + [Rules](/docs/rules/)
  + [Agents](/docs/agents/)
  + [Models](/docs/models/)
  + [Themes](/docs/themes/)
  + [Keybinds](/docs/keybinds/)
  + [Commands](/docs/commands/)
  + [Formatters](/docs/formatters/)
  + [Permissions](/docs/permissions/)
  + [Policies](/docs/policies/)
  + [LSP Servers](/docs/lsp/)
  + [MCP servers](/docs/mcp-servers/)
  + [ACP Support](/docs/acp/)
  + [Agent Skills](/docs/skills/)
  + [References](/docs/references/)
  + [Custom Tools](/docs/custom-tools/)
* Develop

  + [SDK](/docs/sdk/)
  + [Server](/docs/server/)
  + [Plugins](/docs/plugins/)
  + [Ecosystem](/docs/ecosystem/)

[GitHub](https://github.com/anomalyco/opencode)[Discord](https://opencode.ai/discord)

  Select theme   DarkLightAuto         Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

On this page

* [Overview](#_top)
* [Actions](#actions)
* [Auto mode](#auto-mode)
* [Configuration](#configuration)
* [Granular Rules (Object Syntax)](#granular-rules-object-syntax)
  + [Wildcards](#wildcards)
  + [Home Directory Expansion](#home-directory-expansion)
  + [External Directories](#external-directories)
* [Available Permissions](#available-permissions)
* [Defaults](#defaults)
* [What âAskâ Does](#what-ask-does)
* [Agents](#agents)

### On this page

* [Overview](#_top)
* [Actions](#actions)
* [Auto mode](#auto-mode)
* [Configuration](#configuration)
* [Granular Rules (Object Syntax)](#granular-rules-object-syntax)
  + [Wildcards](#wildcards)
  + [Home Directory Expansion](#home-directory-expansion)
  + [External Directories](#external-directories)
* [Available Permissions](#available-permissions)
* [Defaults](#defaults)
* [What âAskâ Does](#what-ask-does)
* [Agents](#agents)

## Permissions

Control which actions require approval to run.

OpenCode uses the `permission` config to decide whether a given action should run automatically, prompt you, or be blocked.

As of `v1.1.1`, the legacy `tools` boolean config is deprecated and has been merged into `permission`. The old `tools` config is still supported for backwards compatibility.

---

### [Actions](#actions)

Each permission rule resolves to one of:

* `"allow"` â run without approval
* `"ask"` â prompt for approval
* `"deny"` â block the action

---

### [Auto mode](#auto-mode)

Start OpenCode with `--auto` to automatically approve permission requests that are not explicitly denied.

Terminal window

```
opencode --auto
```

You can also use auto mode with [`opencode run`](/docs/cli#run).

Terminal window

```
opencode run --auto "Refactor this module"
```

Explicit `"deny"` rules are still enforced. Auto mode only changes requests that would otherwise ask for approval.

In the TUI, open the command palette and select **Enable auto-approve permissions** or **Disable auto-approve permissions** to change modes. When auto mode is active, the prompt displays a muted `auto` indicator next to the current agent.

---

### [Configuration](#configuration)

You can set permissions globally (with `*`), and override specific tools.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"permission": {

"*": "ask",

"bash": "allow",

"edit": "deny"

}

}
```

You can also set all permissions at once:

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"permission": "allow"

}
```

---

### [Granular Rules (Object Syntax)](#granular-rules-object-syntax)

For most permissions, you can use an object to apply different actions based on the tool input.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"permission": {

"bash": {

"*": "ask",

"git *": "allow",

"npm *": "allow",

"rm *": "deny",

"grep *": "allow"

},

"edit": {

"*": "deny",

"packages/web/src/content/docs/*.mdx": "allow"

},

"webfetch": {

"*": "ask",

"https://en.wikipedia.org/*": "allow"

}

}

}
```

Rules are evaluated by pattern match, with the **last matching rule winning**. A common pattern is to put the catch-all `"*"` rule first, and more specific rules after it.

#### [Wildcards](#wildcards)

Permission patterns use simple wildcard matching:

* `*` matches zero or more of any character
* `?` matches exactly one character
* All other characters match literally

#### [Home Directory Expansion](#home-directory-expansion)

You can use `~` or `$HOME` at the start of a pattern to reference your home directory. This is particularly useful for [`external_directory`](#external-directories) rules.

* `~/projects/*` -> `/Users/username/projects/*`
* `$HOME/projects/*` -> `/Users/username/projects/*`
* `~` -> `/Users/username`

#### [External Directories](#external-directories)

Use `external_directory` to allow tool calls that touch paths outside the working directory where OpenCode was started. This applies to any tool that takes a path as input (for example `read`, `edit`, `glob`, `grep`, and many `bash` commands).

Home expansion (like `~/...`) only affects how a pattern is written. It does not make an external path part of the current workspace, so paths outside the working directory must still be allowed via `external_directory`.

For example, this allows access to everything under `~/projects/personal/`:

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"permission": {

"external_directory": {

"~/projects/personal/**": "allow"

}

}

}
```

Any directory allowed here inherits the same defaults as the current workspace. Since [`read` defaults to `allow`](#defaults), reads are also allowed for entries under `external_directory` unless overridden. Add explicit rules when a tool should be restricted in these paths, such as blocking edits while keeping reads:

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"permission": {

"external_directory": {

"~/projects/personal/**": "allow"

},

"edit": {

"~/projects/personal/**": "deny"

}

}

}
```

Keep the list focused on trusted paths, and layer extra allow or deny rules as needed for other tools (for example `bash`).

---

### [Available Permissions](#available-permissions)

OpenCode permissions are keyed by tool name, plus a couple of safety guards:

* `read` â reading a file (matches the file path)
* `edit` â all file modifications (covers `edit`, `write`, `patch`)
* `glob` â file globbing (matches the glob pattern)
* `grep` â content search (matches the regex pattern)
* `bash` â running shell commands (matches parsed commands like `git status --porcelain`)
* `task` â launching subagents (matches the subagent type)
* `skill` â loading a skill (matches the skill name)
* `lsp` â running LSP queries (currently non-granular)
* `question` â asking the user questions during execution
* `webfetch` â fetching a URL (matches the URL)
* `websearch` â web search
* `external_directory` â triggered when a tool touches paths outside the project working directory
* `doom_loop` â triggered when the same tool call repeats 3 times with identical input

---

### [Defaults](#defaults)

If you donât specify anything, OpenCode starts from permissive defaults:

* Most permissions default to `"allow"`.
* `doom_loop` and `external_directory` default to `"ask"`.
* `read` is `"allow"`, but `.env` files are denied by default:

opencode.json

```
{

"permission": {

"read": {

"*": "allow",

"*.env": "deny",

"*.env.*": "deny",

"*.env.example": "allow"

}

}

}
```

---

### [What âAskâ Does](#what-ask-does)

When OpenCode prompts for approval, the UI offers three outcomes:

* `once` â approve just this request
* `always` â approve future requests matching the suggested patterns (for the rest of the current OpenCode session)
* `reject` â deny the request

The set of patterns that `always` would approve is provided by the tool (for example, bash approvals typically whitelist a safe command prefix like `git status*`).

---

### [Agents](#agents)

You can override permissions per agent. Agent permissions are merged with the global config, and agent rules take precedence. [Learn more](/docs/agents#permissions) about agent permissions.

Note

Refer to the [Granular Rules (Object Syntax)](#granular-rules-object-syntax) section above for more detailed pattern matching examples.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"permission": {

"bash": {

"*": "ask",

"git *": "allow",

"git commit *": "deny",

"git push *": "deny",

"grep *": "allow"

}

},

"agent": {

"build": {

"permission": {

"bash": {

"*": "ask",

"git *": "allow",

"git commit *": "ask",

"git push *": "deny",

"grep *": "allow"

}

}

}

}

}
```

You can also configure agent permissions in Markdown:

~/.config/opencode/agents/review.md

```
---

description: Code review without edits

mode: subagent

permission:

edit: deny

bash: ask

webfetch: deny

---

Only analyze code and suggest changes.
```

Tip

Use pattern matching for commands with arguments. `"grep *"` allows `grep pattern file.txt`, while `"grep"` alone would block it. Commands like `git status` work for default behavior but require explicit permission (like `"git status *"`) when arguments are passed.

[Edit page](https://github.com/anomalyco/opencode/edit/dev/packages/web/src/content/docs/permissions.mdx)[Found a bug? Open an issue](https://github.com/anomalyco/opencode/issues/new)[Join our Discord community](https://opencode.ai/discord)  Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

© [Anomaly](https://anoma.ly)

Last updated: Oct 13, 2026

---
<!--
URL: https://opencode.ai/docs/custom-tools/
title: Custom Tools | OpenCode
-->

[Skip to content](#_top)

[![](/docs/_astro/logo-dark.DOStV66V.svg) ![](/docs/_astro/logo-light.B0yzR0O5.svg)  OpenCode](/docs/)

[app.header.home](/)[app.header.docs](/v2/docs)

Search  `CtrlK`

Cancel

  [New OpenCode v2 is now available →](https://opencode.ai/v2)

* [Intro](/docs/)
* [Config](/docs/config/)
* [Providers](/docs/providers/)
* [Network](/docs/network/)
* [Enterprise](/docs/enterprise/)
* [Troubleshooting](/docs/troubleshooting/)
* [Windows](/docs/windows-wsl)
* Usage

  + [Go](https://opencode.ai/v2/docs/console/go/)
  + [TUI](/docs/tui/)
  + [CLI](/docs/cli/)
  + [Web](/docs/web/)
  + [IDE](/docs/ide/)
  + [Console](https://opencode.ai/v2/docs/console/)
  + [Share](/docs/share/)
  + [GitHub](/docs/github/)
  + [GitLab](/docs/gitlab/)
* Configure

  + [Tools](/docs/tools/)
  + [Rules](/docs/rules/)
  + [Agents](/docs/agents/)
  + [Models](/docs/models/)
  + [Themes](/docs/themes/)
  + [Keybinds](/docs/keybinds/)
  + [Commands](/docs/commands/)
  + [Formatters](/docs/formatters/)
  + [Permissions](/docs/permissions/)
  + [Policies](/docs/policies/)
  + [LSP Servers](/docs/lsp/)
  + [MCP servers](/docs/mcp-servers/)
  + [ACP Support](/docs/acp/)
  + [Agent Skills](/docs/skills/)
  + [References](/docs/references/)
  + [Custom Tools](/docs/custom-tools/)
* Develop

  + [SDK](/docs/sdk/)
  + [Server](/docs/server/)
  + [Plugins](/docs/plugins/)
  + [Ecosystem](/docs/ecosystem/)

[GitHub](https://github.com/anomalyco/opencode)[Discord](https://opencode.ai/discord)

  Select theme   DarkLightAuto         Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

On this page

* [Overview](#_top)
* [Creating a tool](#creating-a-tool)
  + [Location](#location)
  + [Structure](#structure)
  + [Arguments](#arguments)
  + [Context](#context)
* [Examples](#examples)
  + [Write a tool in Python](#write-a-tool-in-python)

### On this page

* [Overview](#_top)
* [Creating a tool](#creating-a-tool)
  + [Location](#location)
  + [Structure](#structure)
  + [Arguments](#arguments)
  + [Context](#context)
* [Examples](#examples)
  + [Write a tool in Python](#write-a-tool-in-python)

## Custom Tools

Create tools the LLM can call in opencode.

Custom tools are functions you create that the LLM can call during conversations. They work alongside opencodeâs [built-in tools](/docs/tools) like `read`, `write`, and `bash`.

---

### [Creating a tool](#creating-a-tool)

Tools are defined as **TypeScript** or **JavaScript** files. However, the tool definition can invoke scripts written in **any language** â TypeScript or JavaScript is only used for the tool definition itself.

---

#### [Location](#location)

They can be defined:

* Locally by placing them in the `.opencode/tools/` directory of your project.
* Or globally, by placing them in `~/.config/opencode/tools/`.

---

#### [Structure](#structure)

The easiest way to create tools is using the `tool()` helper which provides type-safety and validation.

.opencode/tools/database.ts

```
import { tool } from "@opencode-ai/plugin"

export default tool({

description: "Query the project database",

args: {

query: tool.schema.string().describe("SQL query to execute"),

},

async execute(args) {

// Your database logic here

return `Executed query: ${args.query}`

},

})
```

The **filename** becomes the **tool name**. The above creates a `database` tool.

---

##### [Multiple tools per file](#multiple-tools-per-file)

You can also export multiple tools from a single file. Each export becomes **a separate tool** with the name **`<filename>_<exportname>`**:

.opencode/tools/math.ts

```
import { tool } from "@opencode-ai/plugin"

export const add = tool({

description: "Add two numbers",

args: {

a: tool.schema.number().describe("First number"),

b: tool.schema.number().describe("Second number"),

},

async execute(args) {

return (args.a + args.b).toString()

},

})

export const multiply = tool({

description: "Multiply two numbers",

args: {

a: tool.schema.number().describe("First number"),

b: tool.schema.number().describe("Second number"),

},

async execute(args) {

return (args.a * args.b).toString()

},

})
```

This creates two tools: `math_add` and `math_multiply`.

---

##### [Name collisions with built-in tools](#name-collisions-with-built-in-tools)

Custom tools are keyed by tool name. If a custom tool uses the same name as a built-in tool, the custom tool takes precedence.

For example, this file replaces the built-in `bash` tool:

.opencode/tools/bash.ts

```
import { tool } from "@opencode-ai/plugin"

export default tool({

description: "Restricted bash wrapper",

args: {

command: tool.schema.string(),

},

async execute(args) {

return `blocked: ${args.command}`

},

})
```

Note

Prefer unique names unless you intentionally want to replace a built-in tool. If you want to disable a built in tool but not override it, use [permissions](/docs/permissions).

---

#### [Arguments](#arguments)

You can use `tool.schema`, which is just [Zod](https://zod.dev), to define argument types.

```
args: {

query: tool.schema.string().describe("SQL query to execute")

}
```

You can also import [Zod](https://zod.dev) directly and return a plain object:

```
import { z } from "zod"

export default {

description: "Tool description",

args: {

param: z.string().describe("Parameter description"),

},

async execute(args, context) {

// Tool implementation

return "result"

},

}
```

---

#### [Context](#context)

Tools receive context about the current session:

.opencode/tools/project.ts

```
import { tool } from "@opencode-ai/plugin"

export default tool({

description: "Get project information",

args: {},

async execute(args, context) {

// Access context information

const { agent, sessionID, messageID, directory, worktree } = context

return `Agent: ${agent}, Session: ${sessionID}, Message: ${messageID}, Directory: ${directory}, Worktree: ${worktree}`

},

})
```

Use `context.directory` for the session working directory.
Use `context.worktree` for the git worktree root.

---

### [Examples](#examples)

#### [Write a tool in Python](#write-a-tool-in-python)

You can write your tools in any language you want. Hereâs an example that adds two numbers using Python.

First, create the tool as a Python script:

.opencode/tools/add.py

```
import sys

a = int(sys.argv[1])

b = int(sys.argv[2])

print(a + b)
```

Then create the tool definition that invokes it:

.opencode/tools/python-add.ts

```
import { tool } from "@opencode-ai/plugin"

import path from "path"

export default tool({

description: "Add two numbers using Python",

args: {

a: tool.schema.number().describe("First number"),

b: tool.schema.number().describe("Second number"),

},

async execute(args, context) {

const script = path.join(context.worktree, ".opencode/tools/add.py")

const result = await Bun.$`python3 ${script} ${args.a} ${args.b}`.text()

return result.trim()

},

})
```

Here we are using the [`Bun.$`](https://bun.com/docs/runtime/shell) utility to run the Python script.

[Edit page](https://github.com/anomalyco/opencode/edit/dev/packages/web/src/content/docs/custom-tools.mdx)[Found a bug? Open an issue](https://github.com/anomalyco/opencode/issues/new)[Join our Discord community](https://opencode.ai/discord)  Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

© [Anomaly](https://anoma.ly)

Last updated: Oct 13, 2026

---
<!--
URL: https://opencode.ai/docs/skills/
title: Agent Skills | OpenCode
-->

[Skip to content](#_top)

[![](/docs/_astro/logo-dark.DOStV66V.svg) ![](/docs/_astro/logo-light.B0yzR0O5.svg)  OpenCode](/docs/)

[app.header.home](/)[app.header.docs](/v2/docs)

Search  `CtrlK`

Cancel

  [New OpenCode v2 is now available →](https://opencode.ai/v2)

* [Intro](/docs/)
* [Config](/docs/config/)
* [Providers](/docs/providers/)
* [Network](/docs/network/)
* [Enterprise](/docs/enterprise/)
* [Troubleshooting](/docs/troubleshooting/)
* [Windows](/docs/windows-wsl)
* Usage

  + [Go](https://opencode.ai/v2/docs/console/go/)
  + [TUI](/docs/tui/)
  + [CLI](/docs/cli/)
  + [Web](/docs/web/)
  + [IDE](/docs/ide/)
  + [Console](https://opencode.ai/v2/docs/console/)
  + [Share](/docs/share/)
  + [GitHub](/docs/github/)
  + [GitLab](/docs/gitlab/)
* Configure

  + [Tools](/docs/tools/)
  + [Rules](/docs/rules/)
  + [Agents](/docs/agents/)
  + [Models](/docs/models/)
  + [Themes](/docs/themes/)
  + [Keybinds](/docs/keybinds/)
  + [Commands](/docs/commands/)
  + [Formatters](/docs/formatters/)
  + [Permissions](/docs/permissions/)
  + [Policies](/docs/policies/)
  + [LSP Servers](/docs/lsp/)
  + [MCP servers](/docs/mcp-servers/)
  + [ACP Support](/docs/acp/)
  + [Agent Skills](/docs/skills/)
  + [References](/docs/references/)
  + [Custom Tools](/docs/custom-tools/)
* Develop

  + [SDK](/docs/sdk/)
  + [Server](/docs/server/)
  + [Plugins](/docs/plugins/)
  + [Ecosystem](/docs/ecosystem/)

[GitHub](https://github.com/anomalyco/opencode)[Discord](https://opencode.ai/discord)

  Select theme   DarkLightAuto         Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

On this page

* [Overview](#_top)
* [Place files](#place-files)
* [Understand discovery](#understand-discovery)
* [Write frontmatter](#write-frontmatter)
* [Validate names](#validate-names)
* [Follow length rules](#follow-length-rules)
* [Use an example](#use-an-example)
* [Recognize tool description](#recognize-tool-description)
* [Configure permissions](#configure-permissions)
* [Override per agent](#override-per-agent)
* [Disable the skill tool](#disable-the-skill-tool)
* [Troubleshoot loading](#troubleshoot-loading)

### On this page

* [Overview](#_top)
* [Place files](#place-files)
* [Understand discovery](#understand-discovery)
* [Write frontmatter](#write-frontmatter)
* [Validate names](#validate-names)
* [Follow length rules](#follow-length-rules)
* [Use an example](#use-an-example)
* [Recognize tool description](#recognize-tool-description)
* [Configure permissions](#configure-permissions)
* [Override per agent](#override-per-agent)
* [Disable the skill tool](#disable-the-skill-tool)
* [Troubleshoot loading](#troubleshoot-loading)

## Agent Skills

Define reusable behavior via SKILL.md definitions

Agent skills let OpenCode discover reusable instructions from your repo or home directory.
Skills are loaded on-demand via the native `skill` toolâagents see available skills and can load the full content when needed.

---

### [Place files](#place-files)

Create one folder per skill name and put a `SKILL.md` inside it.
OpenCode searches these locations:

* Project config: `.opencode/skills/<name>/SKILL.md`
* Global config: `~/.config/opencode/skills/<name>/SKILL.md`
* Project Claude-compatible: `.claude/skills/<name>/SKILL.md`
* Global Claude-compatible: `~/.claude/skills/<name>/SKILL.md`
* Project agent-compatible: `.agents/skills/<name>/SKILL.md`
* Global agent-compatible: `~/.agents/skills/<name>/SKILL.md`

---

### [Understand discovery](#understand-discovery)

For project-local paths, OpenCode walks up from your current working directory until it reaches the git worktree.
It loads any matching `skills/*/SKILL.md` in `.opencode/` and any matching `.claude/skills/*/SKILL.md` or `.agents/skills/*/SKILL.md` along the way.

Global definitions are also loaded from `~/.config/opencode/skills/*/SKILL.md`, `~/.claude/skills/*/SKILL.md`, and `~/.agents/skills/*/SKILL.md`.

---

### [Write frontmatter](#write-frontmatter)

Each `SKILL.md` must start with YAML frontmatter.
Use these Agent Skills fields:

* `name` (required)
* `description` (required)
* `license` (optional)
* `compatibility` (optional)
* `metadata` (optional, string-to-string map)

Put OpenCode-specific behavior in `metadata` instead of adding custom top-level fields.

OpenCode recognizes these optional `metadata` keys:

* `opencode/slash`: set to `"true"` to expose the skill as a `/name` command in the TUI
* `opencode/autoinvoke`: set to `"false"` to keep the skill out of model-facing auto-selection guidance

The Agent Skills spec defines `metadata` values as strings, so quoted values are the portable form.
OpenCode also accepts YAML booleans like `opencode/slash: true` and `opencode/autoinvoke: false`.

---

### [Validate names](#validate-names)

`name` must:

* Be 1â64 characters
* Be lowercase alphanumeric with single hyphen separators
* Not start or end with `-`
* Not contain consecutive `--`
* Match the directory name that contains `SKILL.md`

Equivalent regex:

```
^[a-z0-9]+(-[a-z0-9]+)*$
```

---

### [Follow length rules](#follow-length-rules)

`description` must be 1-1024 characters.
Keep it specific enough for the agent to choose correctly.

---

### [Use an example](#use-an-example)

Create `.opencode/skills/git-release/SKILL.md` like this:

```
---

name: git-release

description: Create consistent releases and changelogs

license: MIT

compatibility: opencode

metadata:

audience: maintainers

workflow: github

opencode/slash: "true"

opencode/autoinvoke: "false"

---

### What I do

- Draft release notes from merged PRs

- Propose a version bump

- Provide a copy-pasteable `gh release create` command

### When to use me

Use this when you are preparing a tagged release.

Ask clarifying questions if the target versioning scheme is unclear.
```

---

### [Recognize tool description](#recognize-tool-description)

OpenCode lists available skills in the `skill` tool description.
Each entry includes the skill name and description:

```
<available_skills>

<skill>

<name>git-release</name>

<description>Create consistent releases and changelogs</description>

</skill>

</available_skills>
```

The agent loads a skill by calling the tool:

```
skill({ name: "git-release" })
```

Skills with `metadata["opencode/autoinvoke"]` set to `"false"` are not included in `<available_skills>`.
They can still be selected manually and loaded by exact name.

---

### [Configure permissions](#configure-permissions)

Control which skills agents can access using pattern-based permissions in `opencode.json`:

```
{

"permission": {

"skill": {

"*": "allow",

"pr-review": "allow",

"internal-*": "deny",

"experimental-*": "ask"

}

}

}
```

| Permission | Behavior |
| --- | --- |
| `allow` | Skill loads immediately |
| `deny` | Skill hidden from agent, access rejected |
| `ask` | User prompted for approval before loading |

Patterns support wildcards: `internal-*` matches `internal-docs`, `internal-tools`, etc.

---

### [Override per agent](#override-per-agent)

Give specific agents different permissions than the global defaults.

**For custom agents** (in agent frontmatter):

```
---

permission:

skill:

"documents-*": "allow"

---
```

**For built-in agents** (in `opencode.json`):

```
{

"agent": {

"plan": {

"permission": {

"skill": {

"internal-*": "allow"

}

}

}

}

}
```

---

### [Disable the skill tool](#disable-the-skill-tool)

Completely disable skills for agents that shouldnât use them:

**For custom agents**:

```
---

tools:

skill: false

---
```

**For built-in agents**:

```
{

"agent": {

"plan": {

"tools": {

"skill": false

}

}

}

}
```

When disabled, the `<available_skills>` section is omitted entirely.

---

### [Troubleshoot loading](#troubleshoot-loading)

If a skill does not show up:

1. Verify `SKILL.md` is spelled in all caps
2. Check that frontmatter includes `name` and `description`
3. Ensure skill names are unique across all locations
4. Check permissionsâskills with `deny` are hidden from agents
5. Check `metadata["opencode/autoinvoke"]`âskills set to `"false"` are hidden from model-facing guidance

[Edit page](https://github.com/anomalyco/opencode/edit/dev/packages/web/src/content/docs/skills.mdx)[Found a bug? Open an issue](https://github.com/anomalyco/opencode/issues/new)[Join our Discord community](https://opencode.ai/discord)  Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

© [Anomaly](https://anoma.ly)

Last updated: Oct 13, 2026

---
<!--
URL: https://opencode.ai/docs/formatters/
title: Formatters | OpenCode
-->

[Skip to content](#_top)

[![](/docs/_astro/logo-dark.DOStV66V.svg) ![](/docs/_astro/logo-light.B0yzR0O5.svg)  OpenCode](/docs/)

[app.header.home](/)[app.header.docs](/v2/docs)

Search  `CtrlK`

Cancel

  [New OpenCode v2 is now available →](https://opencode.ai/v2)

* [Intro](/docs/)
* [Config](/docs/config/)
* [Providers](/docs/providers/)
* [Network](/docs/network/)
* [Enterprise](/docs/enterprise/)
* [Troubleshooting](/docs/troubleshooting/)
* [Windows](/docs/windows-wsl)
* Usage

  + [Go](https://opencode.ai/v2/docs/console/go/)
  + [TUI](/docs/tui/)
  + [CLI](/docs/cli/)
  + [Web](/docs/web/)
  + [IDE](/docs/ide/)
  + [Console](https://opencode.ai/v2/docs/console/)
  + [Share](/docs/share/)
  + [GitHub](/docs/github/)
  + [GitLab](/docs/gitlab/)
* Configure

  + [Tools](/docs/tools/)
  + [Rules](/docs/rules/)
  + [Agents](/docs/agents/)
  + [Models](/docs/models/)
  + [Themes](/docs/themes/)
  + [Keybinds](/docs/keybinds/)
  + [Commands](/docs/commands/)
  + [Formatters](/docs/formatters/)
  + [Permissions](/docs/permissions/)
  + [Policies](/docs/policies/)
  + [LSP Servers](/docs/lsp/)
  + [MCP servers](/docs/mcp-servers/)
  + [ACP Support](/docs/acp/)
  + [Agent Skills](/docs/skills/)
  + [References](/docs/references/)
  + [Custom Tools](/docs/custom-tools/)
* Develop

  + [SDK](/docs/sdk/)
  + [Server](/docs/server/)
  + [Plugins](/docs/plugins/)
  + [Ecosystem](/docs/ecosystem/)

[GitHub](https://github.com/anomalyco/opencode)[Discord](https://opencode.ai/discord)

  Select theme   DarkLightAuto         Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

On this page

* [Overview](#_top)
* [Built-in](#built-in)
* [How it works](#how-it-works)
* [Configure](#configure)
  + [Disabling formatters](#disabling-formatters)
  + [Custom formatters](#custom-formatters)

### On this page

* [Overview](#_top)
* [Built-in](#built-in)
* [How it works](#how-it-works)
* [Configure](#configure)
  + [Disabling formatters](#disabling-formatters)
  + [Custom formatters](#custom-formatters)

## Formatters

OpenCode uses language specific formatters.

OpenCode can format files after they are written or edited using language-specific formatters. Formatters are disabled by default; enable them in your config before OpenCode will run them.

---

### [Built-in](#built-in)

OpenCode comes with several built-in formatters for popular languages and frameworks. Below is a list of the formatters, supported file extensions, and commands or config options it needs.

| Formatter | Extensions | Requirements |
| --- | --- | --- |
| air | .R | `air` command available |
| biome | .js, .jsx, .ts, .tsx, .html, .css, .md, .json, .yaml, and [more](https://biomejs.dev/) | `biome.json(c)` config file |
| cargofmt | .rs | `cargo fmt` command available |
| clang-format | .c, .cpp, .h, .hpp, .ino, and [more](https://clang.llvm.org/docs/ClangFormat.html) | `.clang-format` config file |
| cljfmt | .clj, .cljs, .cljc, .edn | `cljfmt` command available |
| dart | .dart | `dart` command available |
| dfmt | .d | `dfmt` command available |
| gleam | .gleam | `gleam` command available |
| gofmt | .go | `gofmt` command available |
| htmlbeautifier | .erb, .html.erb | `htmlbeautifier` command available |
| ktlint | .kt, .kts | `ktlint` command available |
| mix | .ex, .exs, .eex, .heex, .leex, .neex, .sface | `mix` command available |
| nixfmt | .nix | `nixfmt` command available |
| ocamlformat | .ml, .mli | `ocamlformat` command available and `.ocamlformat` config file |
| ormolu | .hs | `ormolu` command available |
| oxfmt (Experimental) | .js, .jsx, .ts, .tsx | `oxfmt` dependency in `package.json` and an [experimental env variable flag](/docs/cli/#experimental) |
| pint | .php | `laravel/pint` dependency in `composer.json` |
| prettier | .js, .jsx, .ts, .tsx, .html, .css, .md, .json, .yaml, and [more](https://prettier.io/docs/en/index.html) | `prettier` dependency in `package.json` |
| rubocop | .rb, .rake, .gemspec, .ru | `rubocop` command available |
| ruff | .py, .pyi | `ruff` command available with config |
| rustfmt | .rs | `rustfmt` command available |
| shfmt | .sh, .bash | `shfmt` command available |
| standardrb | .rb, .rake, .gemspec, .ru | `standardrb` command available |
| terraform | .tf, .tfvars | `terraform` command available |
| uv | .py, .pyi | `uv` command available |
| zig | .zig, .zon | `zig` command available |

When formatters are enabled, OpenCode will use `prettier` for matching files if your project has `prettier` in `package.json`.

---

### [How it works](#how-it-works)

When OpenCode writes or edits a file and formatters are enabled, it:

1. Checks the file extension against all enabled formatters.
2. Runs the appropriate formatter command on the file.
3. Applies the formatting changes.

This process happens in the background for enabled formatters.

---

### [Configure](#configure)

You can enable and customize formatters through the `formatter` section in your OpenCode config.

To enable all built-in formatters, set `formatter` to `true`.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"formatter": true

}
```

Use an object to keep built-ins enabled while configuring overrides or custom formatters.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"formatter": {}

}
```

Each formatter configuration supports the following:

| Property | Type | Description |
| --- | --- | --- |
| `disabled` | boolean | Set this to `true` to disable the formatter |
| `command` | string[] | The command to run for formatting. Required for custom formatters; optional for built-ins. |
| `environment` | object | Environment variables to set when running the formatter |
| `extensions` | string[] | File extensions this formatter should handle |

Letâs look at some examples.

---

#### [Disabling formatters](#disabling-formatters)

If `formatter` is omitted, all formatters are disabled. To disable all formatters after another config enabled them, set `formatter` to `false`:

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"formatter": false

}
```

To disable a **specific** formatter, set `disabled` to `true`:

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"formatter": {

"prettier": {

"disabled": true

}

}

}
```

---

#### [Custom formatters](#custom-formatters)

You can configure built-in formatters with options like `environment` or `extensions`. To add a custom formatter, specify a `command` and `extensions`:

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"formatter": {

"prettier": {

"command": ["npx", "prettier", "--write", "$FILE"],

"environment": {

"NODE_ENV": "development"

},

"extensions": [".js", ".ts", ".jsx", ".tsx"]

},

"custom-markdown-formatter": {

"command": ["deno", "fmt", "$FILE"],

"extensions": [".md"]

}

}

}
```

The **`$FILE` placeholder** in the command will be replaced with the path to the file being formatted.

[Edit page](https://github.com/anomalyco/opencode/edit/dev/packages/web/src/content/docs/formatters.mdx)[Found a bug? Open an issue](https://github.com/anomalyco/opencode/issues/new)[Join our Discord community](https://opencode.ai/discord)  Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

© [Anomaly](https://anoma.ly)

Last updated: Oct 13, 2026

---
<!--
URL: https://opencode.ai/docs/commands
title: Commands | OpenCode
-->

[Skip to content](#_top)

[![](/docs/_astro/logo-dark.DOStV66V.svg) ![](/docs/_astro/logo-light.B0yzR0O5.svg)  OpenCode](/docs/)

[app.header.home](/)[app.header.docs](/v2/docs)

Search  `CtrlK`

Cancel

  [New OpenCode v2 is now available →](https://opencode.ai/v2)

* [Intro](/docs/)
* [Config](/docs/config/)
* [Providers](/docs/providers/)
* [Network](/docs/network/)
* [Enterprise](/docs/enterprise/)
* [Troubleshooting](/docs/troubleshooting/)
* [Windows](/docs/windows-wsl)
* Usage

  + [Go](https://opencode.ai/v2/docs/console/go/)
  + [TUI](/docs/tui/)
  + [CLI](/docs/cli/)
  + [Web](/docs/web/)
  + [IDE](/docs/ide/)
  + [Console](https://opencode.ai/v2/docs/console/)
  + [Share](/docs/share/)
  + [GitHub](/docs/github/)
  + [GitLab](/docs/gitlab/)
* Configure

  + [Tools](/docs/tools/)
  + [Rules](/docs/rules/)
  + [Agents](/docs/agents/)
  + [Models](/docs/models/)
  + [Themes](/docs/themes/)
  + [Keybinds](/docs/keybinds/)
  + [Commands](/docs/commands/)
  + [Formatters](/docs/formatters/)
  + [Permissions](/docs/permissions/)
  + [Policies](/docs/policies/)
  + [LSP Servers](/docs/lsp/)
  + [MCP servers](/docs/mcp-servers/)
  + [ACP Support](/docs/acp/)
  + [Agent Skills](/docs/skills/)
  + [References](/docs/references/)
  + [Custom Tools](/docs/custom-tools/)
* Develop

  + [SDK](/docs/sdk/)
  + [Server](/docs/server/)
  + [Plugins](/docs/plugins/)
  + [Ecosystem](/docs/ecosystem/)

[GitHub](https://github.com/anomalyco/opencode)[Discord](https://opencode.ai/discord)

  Select theme   DarkLightAuto         Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

On this page

* [Overview](#_top)
* [Create command files](#create-command-files)
* [Configure](#configure)
  + [JSON](#json)
  + [Markdown](#markdown)
* [Prompt config](#prompt-config)
  + [Arguments](#arguments)
  + [Shell output](#shell-output)
  + [File references](#file-references)
* [Options](#options)
  + [Template](#template)
  + [Description](#description)
  + [Agent](#agent)
  + [Subtask](#subtask)
  + [Model](#model)
* [Built-in](#built-in)

### On this page

* [Overview](#_top)
* [Create command files](#create-command-files)
* [Configure](#configure)
  + [JSON](#json)
  + [Markdown](#markdown)
* [Prompt config](#prompt-config)
  + [Arguments](#arguments)
  + [Shell output](#shell-output)
  + [File references](#file-references)
* [Options](#options)
  + [Template](#template)
  + [Description](#description)
  + [Agent](#agent)
  + [Subtask](#subtask)
  + [Model](#model)
* [Built-in](#built-in)

## Commands

Create custom commands for repetitive tasks.

Custom commands let you specify a prompt you want to run when that command is executed in the TUI.

```
/my-command
```

Custom commands are in addition to the built-in commands like `/init`, `/undo`, `/redo`, `/share`, `/help`. [Learn more](/docs/tui#commands).

---

### [Create command files](#create-command-files)

Create markdown files in the `commands/` directory to define custom commands.

Create `.opencode/commands/test.md`:

.opencode/commands/test.md

```
---

description: Run tests with coverage

agent: build

model: anthropic/claude-3-5-sonnet-20241022

---

Run the full test suite with coverage report and show any failures.

Focus on the failing tests and suggest fixes.
```

The frontmatter defines command properties. The content becomes the template.

Use the command by typing `/` followed by the command name.

```
"/test"
```

---

### [Configure](#configure)

You can add custom commands through the OpenCode config or by creating markdown files in the `commands/` directory.

---

#### [JSON](#json)

Use the `command` option in your OpenCode [config](/docs/config):

opencode.jsonc

```
{

"$schema": "https://opencode.ai/config.json",

"command": {

// This becomes the name of the command

"test": {

// This is the prompt that will be sent to the LLM

"template": "Run the full test suite with coverage report and show any failures.\nFocus on the failing tests and suggest fixes.",

// This is shown as the description in the TUI

"description": "Run tests with coverage",

"agent": "build",

"model": "anthropic/claude-3-5-sonnet-20241022"

}

}

}
```

Now you can run this command in the TUI:

```
/test
```

---

#### [Markdown](#markdown)

You can also define commands using markdown files. Place them in:

* Global: `~/.config/opencode/commands/`
* Per-project: `.opencode/commands/`

~/.config/opencode/commands/test.md

```
---

description: Run tests with coverage

agent: build

model: anthropic/claude-3-5-sonnet-20241022

---

Run the full test suite with coverage report and show any failures.

Focus on the failing tests and suggest fixes.
```

The markdown file name becomes the command name. For example, `test.md` lets
you run:

```
/test
```

---

### [Prompt config](#prompt-config)

The prompts for the custom commands support several special placeholders and syntax.

---

#### [Arguments](#arguments)

Pass arguments to commands using the `$ARGUMENTS` placeholder.

.opencode/commands/component.md

```
---

description: Create a new component

---

Create a new React component named $ARGUMENTS with TypeScript support.

Include proper typing and basic structure.
```

Run the command with arguments:

```
/component Button
```

And `$ARGUMENTS` will be replaced with `Button`.

You can also access individual arguments using positional parameters:

* `$1` - First argument
* `$2` - Second argument
* `$3` - Third argument
* And so onâ¦

For example:

.opencode/commands/create-file.md

```
---

description: Create a new file with content

---

Create a file named $1 in the directory $2

with the following content: $3
```

Run the command:

```
/create-file config.json src "{ \"key\": \"value\" }"
```

This replaces:

* `$1` with `config.json`
* `$2` with `src`
* `$3` with `{ "key": "value" }`

---

#### [Shell output](#shell-output)

Use *!`command`* to inject [bash command](/docs/tui#bash-commands) output into your prompt.

For example, to create a custom command that analyzes test coverage:

.opencode/commands/analyze-coverage.md

```
---

description: Analyze test coverage

---

Here are the current test results:

!`npm test`

Based on these results, suggest improvements to increase coverage.
```

Or to review recent changes:

.opencode/commands/review-changes.md

```
---

description: Review recent changes

---

Recent git commits:

!`git log --oneline -10`

Review these changes and suggest any improvements.
```

Commands run in your projectâs root directory and their output becomes part of the prompt.

---

#### [File references](#file-references)

Include files in your command using `@` followed by the filename.

.opencode/commands/review-component.md

```
---

description: Review component

---

Review the component in @src/components/Button.tsx.

Check for performance issues and suggest improvements.
```

The file content gets included in the prompt automatically.

---

### [Options](#options)

Letâs look at the configuration options in detail.

---

#### [Template](#template)

The `template` option defines the prompt that will be sent to the LLM when the command is executed.

opencode.json

```
{

"command": {

"test": {

"template": "Run the full test suite with coverage report and show any failures.\nFocus on the failing tests and suggest fixes."

}

}

}
```

This is a **required** config option.

---

#### [Description](#description)

Use the `description` option to provide a brief description of what the command does.

opencode.json

```
{

"command": {

"test": {

"description": "Run tests with coverage"

}

}

}
```

This is shown as the description in the TUI when you type in the command.

---

#### [Agent](#agent)

Use the `agent` config to optionally specify which [agent](/docs/agents) should execute this command.
If this is a [subagent](/docs/agents/#subagents) the command will trigger a subagent invocation by default.
To disable this behavior, set `subtask` to `false`.

opencode.json

```
{

"command": {

"review": {

"agent": "plan"

}

}

}
```

This is an **optional** config option. If not specified, defaults to your current agent.

---

#### [Subtask](#subtask)

Use the `subtask` boolean to force the command to trigger a [subagent](/docs/agents/#subagents) invocation.
This is useful if you want the command to not pollute your primary context and will **force** the agent to act as a subagent,
even if `mode` is set to `primary` on the [agent](/docs/agents) configuration.

opencode.json

```
{

"command": {

"analyze": {

"subtask": true

}

}

}
```

This is an **optional** config option.

---

#### [Model](#model)

Use the `model` config to override the default model for this command.

opencode.json

```
{

"command": {

"analyze": {

"model": "anthropic/claude-3-5-sonnet-20241022"

}

}

}
```

This is an **optional** config option.

---

### [Built-in](#built-in)

opencode includes several built-in commands like `/init`, `/undo`, `/redo`, `/share`, `/help`; [learn more](/docs/tui#commands).

Note

Custom commands can override built-in commands.

If you define a custom command with the same name, it will override the built-in command.

[Edit page](https://github.com/anomalyco/opencode/edit/dev/packages/web/src/content/docs/commands.mdx)[Found a bug? Open an issue](https://github.com/anomalyco/opencode/issues/new)[Join our Discord community](https://opencode.ai/discord)  Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

© [Anomaly](https://anoma.ly)

Last updated: Oct 13, 2026

---
<!--
URL: https://opencode.ai/docs/ide
title: IDE | OpenCode
-->

[Skip to content](#_top)

[![](/docs/_astro/logo-dark.DOStV66V.svg) ![](/docs/_astro/logo-light.B0yzR0O5.svg)  OpenCode](/docs/)

[app.header.home](/)[app.header.docs](/v2/docs)

Search  `CtrlK`

Cancel

  [New OpenCode v2 is now available →](https://opencode.ai/v2)

* [Intro](/docs/)
* [Config](/docs/config/)
* [Providers](/docs/providers/)
* [Network](/docs/network/)
* [Enterprise](/docs/enterprise/)
* [Troubleshooting](/docs/troubleshooting/)
* [Windows](/docs/windows-wsl)
* Usage

  + [Go](https://opencode.ai/v2/docs/console/go/)
  + [TUI](/docs/tui/)
  + [CLI](/docs/cli/)
  + [Web](/docs/web/)
  + [IDE](/docs/ide/)
  + [Console](https://opencode.ai/v2/docs/console/)
  + [Share](/docs/share/)
  + [GitHub](/docs/github/)
  + [GitLab](/docs/gitlab/)
* Configure

  + [Tools](/docs/tools/)
  + [Rules](/docs/rules/)
  + [Agents](/docs/agents/)
  + [Models](/docs/models/)
  + [Themes](/docs/themes/)
  + [Keybinds](/docs/keybinds/)
  + [Commands](/docs/commands/)
  + [Formatters](/docs/formatters/)
  + [Permissions](/docs/permissions/)
  + [Policies](/docs/policies/)
  + [LSP Servers](/docs/lsp/)
  + [MCP servers](/docs/mcp-servers/)
  + [ACP Support](/docs/acp/)
  + [Agent Skills](/docs/skills/)
  + [References](/docs/references/)
  + [Custom Tools](/docs/custom-tools/)
* Develop

  + [SDK](/docs/sdk/)
  + [Server](/docs/server/)
  + [Plugins](/docs/plugins/)
  + [Ecosystem](/docs/ecosystem/)

[GitHub](https://github.com/anomalyco/opencode)[Discord](https://opencode.ai/discord)

  Select theme   DarkLightAuto         Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

On this page

* [Overview](#_top)
* [Usage](#usage)
* [Installation](#installation)
  + [Manual Install](#manual-install)
  + [Troubleshooting](#troubleshooting)

### On this page

* [Overview](#_top)
* [Usage](#usage)
* [Installation](#installation)
  + [Manual Install](#manual-install)
  + [Troubleshooting](#troubleshooting)

## IDE

The OpenCode extension for VS Code, Cursor, and other IDEs

OpenCode integrates with VS Code, Cursor, or any IDE that supports a terminal. Just run `opencode` in the terminal to get started.

---

### [Usage](#usage)

* **Quick Launch**: Use `Cmd+Esc` (Mac) or `Ctrl+Esc` (Windows/Linux) to open OpenCode in a split terminal view, or focus an existing terminal session if one is already running.
* **New Session**: Use `Cmd+Shift+Esc` (Mac) or `Ctrl+Shift+Esc` (Windows/Linux) to start a new OpenCode terminal session, even if one is already open. You can also click the OpenCode button in the UI.
* **Context Awareness**: Automatically share your current selection or tab with OpenCode.
* **File Reference Shortcuts**: Use `Cmd+Option+K` (Mac) or `Alt+Ctrl+K` (Linux/Windows) to insert file references. For example, `@File#L37-42`.

---

### [Installation](#installation)

To install OpenCode on VS Code and popular forks like Cursor, Windsurf, VSCodium:

1. Open VS Code
2. Open the integrated terminal
3. Run `opencode` - the extension installs automatically

If on the other hand you want to use your own IDE when you run `/editor` or `/export` from the TUI, youâll need to set `export EDITOR="code --wait"`. [Learn more](/docs/tui/#editor-setup).

---

#### [Manual Install](#manual-install)

Search for **OpenCode** in the Extension Marketplace and click **Install**.

---

#### [Troubleshooting](#troubleshooting)

If the extension fails to install automatically:

* Ensure youâre running `opencode` in the integrated terminal.
* Confirm the CLI for your IDE is installed:
  + For VS Code: `code` command
  + For Cursor: `cursor` command
  + For Windsurf: `windsurf` command
  + For VSCodium: `codium` command
  + If not, run `Cmd+Shift+P` (Mac) or `Ctrl+Shift+P` (Windows/Linux) and search for âShell Command: Install âcodeâ command in PATHâ (or the equivalent for your IDE)
* Ensure VS Code has permission to install extensions

[Edit page](https://github.com/anomalyco/opencode/edit/dev/packages/web/src/content/docs/ide.mdx)[Found a bug? Open an issue](https://github.com/anomalyco/opencode/issues/new)[Join our Discord community](https://opencode.ai/discord)  Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

© [Anomaly](https://anoma.ly)

Last updated: Oct 13, 2026

---
<!--
URL: https://opencode.ai/docs/cli
title: CLI | OpenCode
-->

[Skip to content](#_top)

[![](/docs/_astro/logo-dark.DOStV66V.svg) ![](/docs/_astro/logo-light.B0yzR0O5.svg)  OpenCode](/docs/)

[app.header.home](/)[app.header.docs](/v2/docs)

Search  `CtrlK`

Cancel

  [New OpenCode v2 is now available →](https://opencode.ai/v2)

* [Intro](/docs/)
* [Config](/docs/config/)
* [Providers](/docs/providers/)
* [Network](/docs/network/)
* [Enterprise](/docs/enterprise/)
* [Troubleshooting](/docs/troubleshooting/)
* [Windows](/docs/windows-wsl)
* Usage

  + [Go](https://opencode.ai/v2/docs/console/go/)
  + [TUI](/docs/tui/)
  + [CLI](/docs/cli/)
  + [Web](/docs/web/)
  + [IDE](/docs/ide/)
  + [Console](https://opencode.ai/v2/docs/console/)
  + [Share](/docs/share/)
  + [GitHub](/docs/github/)
  + [GitLab](/docs/gitlab/)
* Configure

  + [Tools](/docs/tools/)
  + [Rules](/docs/rules/)
  + [Agents](/docs/agents/)
  + [Models](/docs/models/)
  + [Themes](/docs/themes/)
  + [Keybinds](/docs/keybinds/)
  + [Commands](/docs/commands/)
  + [Formatters](/docs/formatters/)
  + [Permissions](/docs/permissions/)
  + [Policies](/docs/policies/)
  + [LSP Servers](/docs/lsp/)
  + [MCP servers](/docs/mcp-servers/)
  + [ACP Support](/docs/acp/)
  + [Agent Skills](/docs/skills/)
  + [References](/docs/references/)
  + [Custom Tools](/docs/custom-tools/)
* Develop

  + [SDK](/docs/sdk/)
  + [Server](/docs/server/)
  + [Plugins](/docs/plugins/)
  + [Ecosystem](/docs/ecosystem/)

[GitHub](https://github.com/anomalyco/opencode)[Discord](https://opencode.ai/discord)

  Select theme   DarkLightAuto         Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

On this page

* [Overview](#_top)
  + [tui](#tui)
* [Commands](#commands)
  + [agent](#agent)
  + [attach](#attach)
  + [auth](#auth)
  + [github](#github)
  + [mcp](#mcp)
  + [models](#models)
  + [run](#run-1)
  + [serve](#serve)
  + [session](#session)
  + [stats](#stats)
  + [export](#export)
  + [import](#import)
  + [web](#web)
  + [acp](#acp)
  + [plugin](#plugin)
  + [pr](#pr)
  + [db](#db)
  + [debug](#debug-1)
  + [uninstall](#uninstall)
  + [upgrade](#upgrade)
* [Global Flags](#global-flags)
* [Environment variables](#environment-variables)
  + [Experimental](#experimental)

### On this page

* [Overview](#_top)
  + [tui](#tui)
* [Commands](#commands)
  + [agent](#agent)
  + [attach](#attach)
  + [auth](#auth)
  + [github](#github)
  + [mcp](#mcp)
  + [models](#models)
  + [run](#run-1)
  + [serve](#serve)
  + [session](#session)
  + [stats](#stats)
  + [export](#export)
  + [import](#import)
  + [web](#web)
  + [acp](#acp)
  + [plugin](#plugin)
  + [pr](#pr)
  + [db](#db)
  + [debug](#debug-1)
  + [uninstall](#uninstall)
  + [upgrade](#upgrade)
* [Global Flags](#global-flags)
* [Environment variables](#environment-variables)
  + [Experimental](#experimental)

## CLI

OpenCode CLI options and commands.

The OpenCode CLI by default starts the [TUI](/docs/tui) when run without any arguments.

Terminal window

```
opencode
```

But it also accepts commands as documented on this page. This allows you to interact with OpenCode programmatically.

Terminal window

```
opencode run "Explain how closures work in JavaScript"
```

---

#### [tui](#tui)

Start the OpenCode terminal user interface.

Terminal window

```
opencode [project]
```

##### [Flags](#flags)

| Flag | Short | Description |
| --- | --- | --- |
| `--continue` | `-c` | Continue the last session |
| `--session` | `-s` | Session ID to continue |
| `--fork` |  | Fork the session when continuing (use with `--continue` or `--session`) |
| `--prompt` |  | Prompt to use |
| `--model` | `-m` | Model to use in the form of provider/model |
| `--agent` |  | Agent to use |
| `--auto` |  | Auto-approve permissions that are not explicitly denied |
| `--port` |  | Port to listen on |
| `--hostname` |  | Hostname to listen on |
| `--mdns` |  | Enable mDNS discovery |
| `--mdns-domain` |  | Custom mDNS domain name |
| `--cors` |  | Additional browser origin(s) to allow CORS |

---

### [Commands](#commands)

The OpenCode CLI also has the following commands.

---

#### [agent](#agent)

Manage agents for OpenCode.

Terminal window

```
opencode agent [command]
```

---

##### [create](#create)

Create a new agent with custom configuration.

Terminal window

```
opencode agent create
```

This command will guide you through creating a new agent with a custom system prompt and permission configuration. Anything you donât allow is denied in the generated agentâs frontmatter.

##### [Flags](#flags-1)

| Flag | Short | Description |
| --- | --- | --- |
| `--path` |  | Directory to write the agent file to (defaults to global or `.opencode/agent` based on the prompt) |
| `--description` |  | What the agent should do |
| `--mode` |  | Agent mode: `all`, `primary`, or `subagent` |
| `--permissions` |  | Comma-separated list of permissions to allow (default: all). Available: `bash`, `read`, `edit`, `glob`, `grep`, `webfetch`, `task`, `websearch`, `lsp`, `skill`. Anything omitted is denied. Alias: `--tools` |
| `--model` | `-m` | Model to use, in `provider/model` format |

Passing all of `--path`, `--description`, `--mode`, and `--permissions` runs the command non-interactively.

---

##### [list](#list)

List all available agents.

Terminal window

```
opencode agent list
```

---

#### [attach](#attach)

Attach a terminal to an already running OpenCode backend server started via `serve` or `web` commands.

Terminal window

```
opencode attach [url]
```

This allows using the TUI with a remote OpenCode backend. For example:

Terminal window

```

## Start the backend server for web/mobile access

opencode web --port 4096 --hostname 0.0.0.0

## In another terminal, attach the TUI to the running backend

opencode attach http://10.20.30.40:4096
```

##### [Flags](#flags-2)

| Flag | Short | Description |
| --- | --- | --- |
| `--dir` |  | Working directory to start TUI in |
| `--continue` | `-c` | Continue the last session |
| `--session` | `-s` | Session ID to continue |
| `--fork` |  | Fork the session when continuing (use with `--continue` or `--session`) |
| `--password` | `-p` | Basic auth password (defaults to `OPENCODE_SERVER_PASSWORD`) |
| `--username` | `-u` | Basic auth username (defaults to `OPENCODE_SERVER_USERNAME` or `opencode`) |

---

#### [auth](#auth)

Command to manage credentials and login for providers.

Terminal window

```
opencode auth [command]
```

---

##### [login](#login)

OpenCode is powered by the provider list at [Models.dev](https://models.dev), so you can use `opencode auth login` to configure API keys for any provider youâd like to use. This is stored in `~/.local/share/opencode/auth.json`.

Terminal window

```
opencode auth login
```

When OpenCode starts up it loads the providers from the credentials file. And if there are any keys defined in your environments or a `.env` file in your project.

###### [Flags](#flags-3)

| Flag | Short | Description |
| --- | --- | --- |
| `--provider` | `-p` | Provider ID or name to log in to |
| `--method` | `-m` | Login method label to use, skipping method selection |

---

##### [list](#list-1)

Lists all the authenticated providers as stored in the credentials file.

Terminal window

```
opencode auth list
```

Or the short version.

Terminal window

```
opencode auth ls
```

---

##### [logout](#logout)

Logs you out of a provider by clearing it from the credentials file.

Terminal window

```
opencode auth logout
```

---

#### [github](#github)

Manage the GitHub agent for repository automation.

Terminal window

```
opencode github [command]
```

---

##### [install](#install)

Install the GitHub agent in your repository.

Terminal window

```
opencode github install
```

This sets up the necessary GitHub Actions workflow and guides you through the configuration process. [Learn more](/docs/github).

---

##### [run](#run)

Run the GitHub agent. This is typically used in GitHub Actions.

Terminal window

```
opencode github run
```

###### [Flags](#flags-4)

| Flag | Description |
| --- | --- |
| `--event` | GitHub mock event to run the agent for |
| `--token` | GitHub personal access token |

---

#### [mcp](#mcp)

Manage Model Context Protocol servers.

Terminal window

```
opencode mcp [command]
```

---

##### [add](#add)

Add an MCP server to your configuration.

Terminal window

```
opencode mcp add
```

This command will guide you through adding either a local or remote MCP server.

---

##### [list](#list-2)

List all configured MCP servers and their connection status.

Terminal window

```
opencode mcp list
```

Or use the short version.

Terminal window

```
opencode mcp ls
```

---

##### [auth](#auth-1)

Authenticate with an OAuth-enabled MCP server.

Terminal window

```
opencode mcp auth [name]
```

If you donât provide a server name, youâll be prompted to select from available OAuth-capable servers.

You can also list OAuth-capable servers and their authentication status.

Terminal window

```
opencode mcp auth list
```

Or use the short version.

Terminal window

```
opencode mcp auth ls
```

---

##### [logout](#logout-1)

Remove OAuth credentials for an MCP server.

Terminal window

```
opencode mcp logout [name]
```

---

##### [debug](#debug)

Debug OAuth connection issues for an MCP server.

Terminal window

```
opencode mcp debug <name>
```

---

#### [models](#models)

List all available models from configured providers.

Terminal window

```
opencode models [provider]
```

This command displays all models available across your configured providers in the format `provider/model`.

This is useful for figuring out the exact model name to use in [your config](/docs/config/).

You can optionally pass a provider ID to filter models by that provider.

Terminal window

```
opencode models anthropic
```

##### [Flags](#flags-5)

| Flag | Description |
| --- | --- |
| `--refresh` | Refresh the models cache from models.dev |
| `--verbose` | Use more verbose model output (includes metadata like costs) |

Use the `--refresh` flag to update the cached model list. This is useful when new models have been added to a provider and you want to see them in OpenCode.

Terminal window

```
opencode models --refresh
```

---

#### [run](#run-1)

Run opencode in non-interactive mode by passing a prompt directly.

Terminal window

```
opencode run [message..]
```

This is useful for scripting, automation, or when you want a quick answer without launching the full TUI. For example.

Terminal window

```
opencode run Explain the use of context in Go
```

You can also attach to a running `opencode serve` instance to avoid MCP server cold boot times on every run:

Terminal window

```

## Start a headless server in one terminal

opencode serve

## In another terminal, run commands that attach to it

opencode run --attach http://localhost:4096 "Explain async/await in JavaScript"
```

##### [Flags](#flags-6)

| Flag | Short | Description |
| --- | --- | --- |
| `--command` |  | The command to run, use message for args |
| `--continue` | `-c` | Continue the last session |
| `--session` | `-s` | Session ID to continue |
| `--fork` |  | Fork the session when continuing (use with `--continue` or `--session`) |
| `--share` |  | Share the session |
| `--model` | `-m` | Model to use in the form of provider/model |
| `--agent` |  | Agent to use |
| `--file` | `-f` | File(s) to attach to message |
| `--format` |  | Format: default (formatted) or json (raw JSON events) |
| `--title` |  | Title for the session (uses truncated prompt if no value provided) |
| `--attach` |  | Attach to a running opencode server (e.g., <http://localhost:4096>) |
| `--password` | `-p` | Basic auth password (defaults to `OPENCODE_SERVER_PASSWORD`) |
| `--username` | `-u` | Basic auth username (defaults to `OPENCODE_SERVER_USERNAME` or `opencode`) |
| `--dir` |  | Directory to run in, or path on the remote server when attaching |
| `--port` |  | Port for the local server (defaults to random port) |
| `--variant` |  | Model variant (provider-specific reasoning effort) |
| `--thinking` |  | Show thinking blocks |
| `--auto` |  | Auto-approve permissions that are not explicitly denied |

---

#### [serve](#serve)

Start a headless OpenCode server for API access. Check out the [server docs](/docs/server) for the full HTTP interface.

Terminal window

```
opencode serve
```

This starts an HTTP server that provides API access to opencode functionality without the TUI interface. Set `OPENCODE_SERVER_PASSWORD` to enable HTTP basic auth (username defaults to `opencode`).

##### [Flags](#flags-7)

| Flag | Description |
| --- | --- |
| `--port` | Port to listen on |
| `--hostname` | Hostname to listen on |
| `--mdns` | Enable mDNS discovery |
| `--mdns-domain` | Custom mDNS domain name |
| `--cors` | Additional browser origin(s) to allow CORS |

---

#### [session](#session)

Manage OpenCode sessions.

Terminal window

```
opencode session [command]
```

---

##### [list](#list-3)

List all OpenCode sessions.

Terminal window

```
opencode session list
```

###### [Flags](#flags-8)

| Flag | Short | Description |
| --- | --- | --- |
| `--max-count` | `-n` | Limit to N most recent sessions |
| `--format` |  | Output format: table or json (table) |

---

##### [delete](#delete)

Delete an OpenCode session.

Terminal window

```
opencode session delete <sessionID>
```

---

#### [stats](#stats)

Show token usage and cost statistics for your OpenCode sessions.

Terminal window

```
opencode stats
```

##### [Flags](#flags-9)

| Flag | Description |
| --- | --- |
| `--days` | Show stats for the last N days (all time) |
| `--tools` | Number of tools to show (all) |
| `--models` | Show model usage breakdown (hidden by default). Pass a number to show top N |
| `--project` | Filter by project (all projects, empty string: current project) |

---

#### [export](#export)

Export session data as JSON.

Terminal window

```
opencode export [sessionID]
```

If you donât provide a session ID, youâll be prompted to select from available sessions.

##### [Flags](#flags-10)

| Flag | Description |
| --- | --- |
| `--sanitize` | Redact sensitive transcript/file data |

---

#### [import](#import)

Import session data from a JSON file or OpenCode share URL.

Terminal window

```
opencode import <file>
```

You can import from a local file or an OpenCode share URL.

Terminal window

```
opencode import session.json

opencode import https://opncd.ai/s/abc123
```

---

#### [web](#web)

Start a headless OpenCode server with a web interface.

Terminal window

```
opencode web
```

This starts an HTTP server and opens a web browser to access OpenCode through a web interface. Set `OPENCODE_SERVER_PASSWORD` to enable HTTP basic auth (username defaults to `opencode`).

##### [Flags](#flags-11)

| Flag | Description |
| --- | --- |
| `--port` | Port to listen on |
| `--hostname` | Hostname to listen on |
| `--mdns` | Enable mDNS discovery |
| `--mdns-domain` | Custom mDNS domain name |
| `--cors` | Additional browser origin(s) to allow CORS |

---

#### [acp](#acp)

Start an ACP (Agent Client Protocol) server.

Terminal window

```
opencode acp
```

This command starts an ACP server that communicates via stdin/stdout using nd-JSON.

##### [Flags](#flags-12)

| Flag | Description |
| --- | --- |
| `--cwd` | Working directory |
| `--port` | Port to listen on |
| `--hostname` | Hostname to listen on |
| `--mdns` | Enable mDNS discovery |
| `--mdns-domain` | Custom mDNS domain name |
| `--cors` | Additional browser origin(s) to allow CORS |

---

#### [plugin](#plugin)

Install a plugin and update your config.

Terminal window

```
opencode plugin <module>
```

Or use the alias.

Terminal window

```
opencode plug <module>
```

##### [Flags](#flags-13)

| Flag | Short | Description |
| --- | --- | --- |
| `--global` | `-g` | Install in global config |
| `--force` | `-f` | Replace existing plugin version |

---

#### [pr](#pr)

Fetch and checkout a GitHub PR branch, then run OpenCode.

Terminal window

```
opencode pr <number>
```

---

#### [db](#db)

Database tools.

Terminal window

```
opencode db [query]
```

##### [Flags](#flags-14)

| Flag | Description |
| --- | --- |
| `--format` | Output format: `json` or `tsv` |

---

##### [path](#path)

Print the database path.

Terminal window

```
opencode db path
```

---

#### [debug](#debug-1)

Debugging and troubleshooting tools.

Terminal window

```
opencode debug [command]
```

---

#### [uninstall](#uninstall)

Uninstall OpenCode and remove all related files.

Terminal window

```
opencode uninstall
```

##### [Flags](#flags-15)

| Flag | Short | Description |
| --- | --- | --- |
| `--keep-config` | `-c` | Keep configuration files |
| `--keep-data` | `-d` | Keep session data and snapshots |
| `--dry-run` |  | Show what would be removed without removing |
| `--force` | `-f` | Skip confirmation prompts |

---

#### [upgrade](#upgrade)

Updates opencode to the latest version or a specific version.

Terminal window

```
opencode upgrade [target]
```

To upgrade to the latest version.

Terminal window

```
opencode upgrade
```

To upgrade to a specific version.

Terminal window

```
opencode upgrade v0.1.48
```

##### [Flags](#flags-16)

| Flag | Short | Description |
| --- | --- | --- |
| `--method` | `-m` | The installation method that was used; curl, npm, pnpm, bun, brew |

---

### [Global Flags](#global-flags)

The opencode CLI takes the following global flags.

| Flag | Short | Description |
| --- | --- | --- |
| `--help` | `-h` | Display help |
| `--version` | `-v` | Print version number |
| `--print-logs` |  | Print logs to stderr |
| `--log-level` |  | Log level (DEBUG, INFO, WARN, ERROR) |
| `--pure` |  | Run without external plugins |

---

### [Environment variables](#environment-variables)

OpenCode can be configured using environment variables.

| Variable | Type | Description |
| --- | --- | --- |
| `OPENCODE_AUTO_SHARE` | boolean | Automatically share sessions |
| `OPENCODE_GIT_BASH_PATH` | string | Path to Git Bash executable on Windows |
| `OPENCODE_CONFIG` | string | Path to config file |
| `OPENCODE_TUI_CONFIG` | string | Path to TUI config file |
| `OPENCODE_CONFIG_DIR` | string | Path to config directory |
| `OPENCODE_CONFIG_CONTENT` | string | Inline json config content |
| `OPENCODE_DISABLE_AUTOUPDATE` | boolean | Disable automatic update checks |
| `OPENCODE_DISABLE_PRUNE` | boolean | Disable pruning of old data |
| `OPENCODE_DISABLE_TERMINAL_TITLE` | boolean | Disable automatic terminal title updates |
| `OPENCODE_PERMISSION` | string | Inlined json permissions config |
| `OPENCODE_DISABLE_DEFAULT_PLUGINS` | boolean | Disable default plugins |
| `OPENCODE_DISABLE_LSP_DOWNLOAD` | boolean | Disable automatic LSP server downloads |
| `OPENCODE_ENABLE_EXPERIMENTAL_MODELS` | boolean | Enable experimental models |
| `OPENCODE_DISABLE_AUTOCOMPACT` | boolean | Disable automatic context compaction |
| `OPENCODE_DISABLE_CLAUDE_CODE` | boolean | Disable reading from `.claude` (prompt + skills) |
| `OPENCODE_DISABLE_CLAUDE_CODE_PROMPT` | boolean | Disable reading `~/.claude/CLAUDE.md` |
| `OPENCODE_DISABLE_CLAUDE_CODE_SKILLS` | boolean | Disable loading `.claude/skills` |
| `OPENCODE_DISABLE_MODELS_FETCH` | boolean | Disable fetching models from remote sources |
| `OPENCODE_DISABLE_MOUSE` | boolean | Disable mouse capture in the TUI |
| `OPENCODE_FAKE_VCS` | string | Fake VCS provider for testing purposes |
| `OPENCODE_CLIENT` | string | Client identifier (defaults to `cli`) |
| `OPENCODE_ENABLE_EXA` | boolean | Enable Exa web search tools |
| `OPENCODE_ENABLE_PARALLEL` | boolean | Enable Parallel web search tools |
| `OPENCODE_SERVER_PASSWORD` | string | Enable basic auth for `serve`/`web` |
| `OPENCODE_SERVER_USERNAME` | string | Override basic auth username (default `opencode`) |
| `OPENCODE_MODELS_URL` | string | Custom URL for fetching models configuration |

---

#### [Experimental](#experimental)

These environment variables enable experimental features that may change or be removed.

| Variable | Type | Description |
| --- | --- | --- |
| `OPENCODE_EXPERIMENTAL` | boolean | Enable the experimental umbrella flag |
| `OPENCODE_EXPERIMENTAL_ICON_DISCOVERY` | boolean | Enable icon discovery |
| `OPENCODE_EXPERIMENTAL_DISABLE_COPY_ON_SELECT` | boolean | Disable copy on select in TUI |
| `OPENCODE_EXPERIMENTAL_BASH_DEFAULT_TIMEOUT_MS` | number | Default timeout for bash commands in ms |
| `OPENCODE_EXPERIMENTAL_OUTPUT_TOKEN_MAX` | number | Max output tokens for LLM responses |
| `OPENCODE_EXPERIMENTAL_FILEWATCHER` | boolean | Enable file watcher for entire dir |
| `OPENCODE_EXPERIMENTAL_OXFMT` | boolean | Enable oxfmt formatter |
| `OPENCODE_EXPERIMENTAL_LSP_TOOL` | boolean | Enable experimental LSP tool |
| `OPENCODE_EXPERIMENTAL_DISABLE_FILEWATCHER` | boolean | Disable file watcher |
| `OPENCODE_EXPERIMENTAL_EXA` | boolean | Enable experimental Exa features |
| `OPENCODE_EXPERIMENTAL_LSP_TY` | boolean | Enable TY LSP for python files |
| `OPENCODE_EXPERIMENTAL_PLAN_MODE` | boolean | Enable plan mode |
| `OPENCODE_EXPERIMENTAL_EVENT_SYSTEM` | boolean | Enable experimental event system |
| `OPENCODE_EXPERIMENTAL_NATIVE_LLM` | boolean | Enable native LLM request path |
| `OPENCODE_EXPERIMENTAL_PARALLEL` | boolean | Enable parallel web search execution |
| `OPENCODE_EXPERIMENTAL_SCOUT` | boolean | Enable Scout subagent |
| `OPENCODE_EXPERIMENTAL_WORKSPACES` | boolean | Enable workspace support |

[Edit page](https://github.com/anomalyco/opencode/edit/dev/packages/web/src/content/docs/cli.mdx)[Found a bug? Open an issue](https://github.com/anomalyco/opencode/issues/new)[Join our Discord community](https://opencode.ai/discord)  Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

© [Anomaly](https://anoma.ly)

Last updated: Oct 13, 2026

---
<!--
URL: https://opencode.ai/docs/sdk
title: SDK | OpenCode
-->

[Skip to content](#_top)

[![](/docs/_astro/logo-dark.DOStV66V.svg) ![](/docs/_astro/logo-light.B0yzR0O5.svg)  OpenCode](/docs/)

[app.header.home](/)[app.header.docs](/v2/docs)

Search  `CtrlK`

Cancel

  [New OpenCode v2 is now available →](https://opencode.ai/v2)

* [Intro](/docs/)
* [Config](/docs/config/)
* [Providers](/docs/providers/)
* [Network](/docs/network/)
* [Enterprise](/docs/enterprise/)
* [Troubleshooting](/docs/troubleshooting/)
* [Windows](/docs/windows-wsl)
* Usage

  + [Go](https://opencode.ai/v2/docs/console/go/)
  + [TUI](/docs/tui/)
  + [CLI](/docs/cli/)
  + [Web](/docs/web/)
  + [IDE](/docs/ide/)
  + [Console](https://opencode.ai/v2/docs/console/)
  + [Share](/docs/share/)
  + [GitHub](/docs/github/)
  + [GitLab](/docs/gitlab/)
* Configure

  + [Tools](/docs/tools/)
  + [Rules](/docs/rules/)
  + [Agents](/docs/agents/)
  + [Models](/docs/models/)
  + [Themes](/docs/themes/)
  + [Keybinds](/docs/keybinds/)
  + [Commands](/docs/commands/)
  + [Formatters](/docs/formatters/)
  + [Permissions](/docs/permissions/)
  + [Policies](/docs/policies/)
  + [LSP Servers](/docs/lsp/)
  + [MCP servers](/docs/mcp-servers/)
  + [ACP Support](/docs/acp/)
  + [Agent Skills](/docs/skills/)
  + [References](/docs/references/)
  + [Custom Tools](/docs/custom-tools/)
* Develop

  + [SDK](/docs/sdk/)
  + [Server](/docs/server/)
  + [Plugins](/docs/plugins/)
  + [Ecosystem](/docs/ecosystem/)

[GitHub](https://github.com/anomalyco/opencode)[Discord](https://opencode.ai/discord)

  Select theme   DarkLightAuto         Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

On this page

* [Overview](#_top)
* [Install](#install)
* [Create client](#create-client)
* [Config](#config)
* [Client only](#client-only)
* [Types](#types)
* [Errors](#errors)
* [Structured Output](#structured-output)
  + [Basic Usage](#basic-usage)
  + [Output Format Types](#output-format-types)
  + [JSON Schema Format](#json-schema-format)
  + [Error Handling](#error-handling)
  + [Best Practices](#best-practices)
* [APIs](#apis)
  + [Global](#global)
  + [App](#app)
  + [Project](#project)
  + [Path](#path)
  + [Config](#config-1)
  + [Sessions](#sessions)
  + [Files](#files)
  + [TUI](#tui)
  + [Auth](#auth)
  + [Events](#events)

### On this page

* [Overview](#_top)
* [Install](#install)
* [Create client](#create-client)
* [Config](#config)
* [Client only](#client-only)
* [Types](#types)
* [Errors](#errors)
* [Structured Output](#structured-output)
  + [Basic Usage](#basic-usage)
  + [Output Format Types](#output-format-types)
  + [JSON Schema Format](#json-schema-format)
  + [Error Handling](#error-handling)
  + [Best Practices](#best-practices)
* [APIs](#apis)
  + [Global](#global)
  + [App](#app)
  + [Project](#project)
  + [Path](#path)
  + [Config](#config-1)
  + [Sessions](#sessions)
  + [Files](#files)
  + [TUI](#tui)
  + [Auth](#auth)
  + [Events](#events)

## SDK

Type-safe JS client for opencode server.

The opencode JS/TS SDK provides a type-safe client for interacting with the server.
Use it to build integrations and control opencode programmatically.

[Learn more](/docs/server) about how the server works. For examples, check out the [projects](/docs/ecosystem#projects) built by the community.

---

### [Install](#install)

Install the SDK from npm:

Terminal window

```
npm install @opencode-ai/sdk
```

---

### [Create client](#create-client)

Create an instance of opencode:

```
import { createOpencode } from "@opencode-ai/sdk"

const { client } = await createOpencode()
```

This starts both a server and a client

##### [Options](#options)

| Option | Type | Description | Default |
| --- | --- | --- | --- |
| `hostname` | `string` | Server hostname | `127.0.0.1` |
| `port` | `number` | Server port | `4096` |
| `signal` | `AbortSignal` | Abort signal for cancellation | `undefined` |
| `timeout` | `number` | Timeout in ms for server start | `5000` |
| `config` | `Config` | Configuration object | `{}` |

---

### [Config](#config)

You can pass a configuration object to customize behavior. The instance still picks up your `opencode.json`, but you can override or add configuration inline:

```
import { createOpencode } from "@opencode-ai/sdk"

const opencode = await createOpencode({

hostname: "127.0.0.1",

port: 4096,

config: {

model: "anthropic/claude-3-5-sonnet-20241022",

},

})

console.log(`Server running at ${opencode.server.url}`)

opencode.server.close()
```

### [Client only](#client-only)

If you already have a running instance of opencode, you can create a client instance to connect to it:

```
import { createOpencodeClient } from "@opencode-ai/sdk"

const client = createOpencodeClient({

baseUrl: "http://localhost:4096",

})
```

##### [Options](#options-1)

| Option | Type | Description | Default |
| --- | --- | --- | --- |
| `baseUrl` | `string` | URL of the server | `http://localhost:4096` |
| `fetch` | `function` | Custom fetch implementation | `globalThis.fetch` |
| `parseAs` | `string` | Response parsing method | `auto` |
| `responseStyle` | `string` | Return style: `data` or `fields` | `fields` |
| `throwOnError` | `boolean` | Throw errors instead of return | `false` |

---

### [Types](#types)

The SDK includes TypeScript definitions for all API types. Import them directly:

```
import type { Session, Message, Part } from "@opencode-ai/sdk"
```

All types are generated from the serverâs OpenAPI specification and available in the [types file](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts).

---

### [Errors](#errors)

The SDK can throw errors that you can catch and handle:

```
try {

await client.session.get({ path: { id: "invalid-id" } })

} catch (error) {

console.error("Failed to get session:", (error as Error).message)

}
```

---

### [Structured Output](#structured-output)

You can request structured JSON output from the model by specifying an `format` with a JSON schema. The model will use a `StructuredOutput` tool to return validated JSON matching your schema.

#### [Basic Usage](#basic-usage)

```
const result = await client.session.prompt({

path: { id: sessionId },

body: {

parts: [{ type: "text", text: "Research Anthropic and provide company info" }],

format: {

type: "json_schema",

schema: {

type: "object",

properties: {

company: { type: "string", description: "Company name" },

founded: { type: "number", description: "Year founded" },

products: {

type: "array",

items: { type: "string" },

description: "Main products",

},

},

required: ["company", "founded"],

},

},

},

})

// Access the structured output

console.log(result.data.info.structured_output)

// { company: "Anthropic", founded: 2021, products: ["Claude", "Claude API"] }
```

#### [Output Format Types](#output-format-types)

| Type | Description |
| --- | --- |
| `text` | Default. Standard text response (no structured output) |
| `json_schema` | Returns validated JSON matching the provided schema |

#### [JSON Schema Format](#json-schema-format)

When using `type: 'json_schema'`, provide:

| Field | Type | Description |
| --- | --- | --- |
| `type` | `'json_schema'` | Required. Specifies JSON schema mode |
| `schema` | `object` | Required. JSON Schema object defining the output structure |
| `retryCount` | `number` | Optional. Number of validation retries (default: 2) |

#### [Error Handling](#error-handling)

If the model fails to produce valid structured output after all retries, the response will include a `StructuredOutputError`:

```
if (result.data.info.error?.name === "StructuredOutputError") {

console.error("Failed to produce structured output:", result.data.info.error.message)

console.error("Attempts:", result.data.info.error.retries)

}
```

#### [Best Practices](#best-practices)

1. **Provide clear descriptions** in your schema properties to help the model understand what data to extract
2. **Use `required`** to specify which fields must be present
3. **Keep schemas focused** - complex nested schemas may be harder for the model to fill correctly
4. **Set appropriate `retryCount`** - increase for complex schemas, decrease for simple ones

---

### [APIs](#apis)

The SDK exposes all server APIs through a type-safe client.

---

#### [Global](#global)

| Method | Description | Response |
| --- | --- | --- |
| `global.health()` | Check server health and version | `{ healthy: true, version: string }` |

---

##### [Examples](#examples)

```
const health = await client.global.health()

console.log(health.data.version)
```

---

#### [App](#app)

| Method | Description | Response |
| --- | --- | --- |
| `app.log()` | Write a log entry | `boolean` |
| `app.agents()` | List all available agents | [`Agent[]`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) |

---

##### [Examples](#examples-1)

```
// Write a log entry

await client.app.log({

body: {

service: "my-app",

level: "info",

message: "Operation completed",

},

})

// List available agents

const agents = await client.app.agents()
```

---

#### [Project](#project)

| Method | Description | Response |
| --- | --- | --- |
| `project.list()` | List all projects | [`Project[]`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) |

---

##### [Examples](#examples-2)

```
// List all projects

const projects = await client.project.list()
```

---

#### [Path](#path)

| Method | Description | Response |
| --- | --- | --- |
| `path.get()` | Get current path | [`Path`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) |

---

##### [Examples](#examples-3)

```
// Get current path information

const pathInfo = await client.path.get()
```

---

#### [Config](#config-1)

| Method | Description | Response |
| --- | --- | --- |
| `config.get()` | Get config info | [`Config`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) |
| `config.providers()` | List providers and default models | `{ providers:` [`Provider[]`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts)`, default: { [key: string]: string } }` |

---

##### [Examples](#examples-4)

```
const config = await client.config.get()

const { providers, default: defaults } = await client.config.providers()
```

---

#### [Sessions](#sessions)

| Method | Description | Notes |
| --- | --- | --- |
| `session.list()` | List sessions | Returns [`Session[]`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) |
| `session.get({ path })` | Get session | Returns [`Session`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) |
| `session.children({ path })` | List child sessions | Returns [`Session[]`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) |
| `session.create({ body })` | Create session | Returns [`Session`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) |
| `session.delete({ path })` | Delete session | Returns `boolean` |
| `session.update({ path, body })` | Update session properties | Returns [`Session`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) |
| `session.init({ path, body })` | Analyze app and create `AGENTS.md` | Returns `boolean` |
| `session.abort({ path })` | Abort a running session | Returns `boolean` |
| `session.share({ path })` | Share session | Returns [`Session`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) |
| `session.unshare({ path })` | Unshare session | Returns [`Session`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) |
| `session.summarize({ path, body })` | Summarize session | Returns `boolean` |
| `session.messages({ path })` | List messages in a session | Returns `{ info:` [`Message`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts)`, parts:` [`Part[]`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts)`}[]` |
| `session.message({ path })` | Get message details | Returns `{ info:` [`Message`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts)`, parts:` [`Part[]`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts)`}` |
| `session.prompt({ path, body })` | Send prompt message | `body.noReply: true` returns UserMessage (context only). Default returns [`AssistantMessage`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) with AI response. Supports `body.outputFormat` for [structured output](#structured-output) |
| `session.command({ path, body })` | Send command to session | Returns `{ info:` [`AssistantMessage`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts)`, parts:` [`Part[]`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts)`}` |
| `session.shell({ path, body })` | Run a shell command | Returns [`AssistantMessage`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) |
| `session.revert({ path, body })` | Revert a message | Returns [`Session`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) |
| `session.unrevert({ path })` | Restore reverted messages | Returns [`Session`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) |
| `postSessionByIdPermissionsByPermissionId({ path, body })` | Respond to a permission request | Returns `boolean` |

---

##### [Examples](#examples-5)

```
// Create and manage sessions

const session = await client.session.create({

body: { title: "My session" },

})

const sessions = await client.session.list()

// Send a prompt message

const result = await client.session.prompt({

path: { id: session.id },

body: {

model: { providerID: "anthropic", modelID: "claude-3-5-sonnet-20241022" },

parts: [{ type: "text", text: "Hello!" }],

},

})

// Inject context without triggering AI response (useful for plugins)

await client.session.prompt({

path: { id: session.id },

body: {

noReply: true,

parts: [{ type: "text", text: "You are a helpful assistant." }],

},

})
```

---

#### [Files](#files)

| Method | Description | Response |
| --- | --- | --- |
| `find.text({ query })` | Search for text in files | Array of match objects with `path`, `lines`, `line_number`, `absolute_offset`, `submatches` |
| `find.files({ query })` | Find files and directories by name | `string[]` (paths) |
| `find.symbols({ query })` | Find workspace symbols | [`Symbol[]`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) |
| `file.read({ query })` | Read a file | `{ type: "raw" | "patch", content: string }` |
| `file.status({ query? })` | Get status for tracked files | [`File[]`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) |

`find.files` supports a few optional query fields:

* `type`: `"file"` or `"directory"`
* `directory`: override the project root for the search
* `limit`: max results (1â200)

---

##### [Examples](#examples-6)

```
// Search and read files

const textResults = await client.find.text({

query: { pattern: "function.*opencode" },

})

const files = await client.find.files({

query: { query: "*.ts", type: "file" },

})

const directories = await client.find.files({

query: { query: "packages", type: "directory", limit: 20 },

})

const content = await client.file.read({

query: { path: "src/index.ts" },

})
```

---

#### [TUI](#tui)

| Method | Description | Response |
| --- | --- | --- |
| `tui.appendPrompt({ body })` | Append text to the prompt | `boolean` |
| `tui.openHelp()` | Open the help dialog | `boolean` |
| `tui.openSessions()` | Open the session selector | `boolean` |
| `tui.openThemes()` | Open the theme selector | `boolean` |
| `tui.openModels()` | Open the model selector | `boolean` |
| `tui.submitPrompt()` | Submit the current prompt | `boolean` |
| `tui.clearPrompt()` | Clear the prompt | `boolean` |
| `tui.executeCommand({ body })` | Execute a command | `boolean` |
| `tui.showToast({ body })` | Show toast notification | `boolean` |

---

##### [Examples](#examples-7)

```
// Control TUI interface

await client.tui.appendPrompt({

body: { text: "Add this to prompt" },

})

await client.tui.showToast({

body: { message: "Task completed", variant: "success" },

})
```

---

#### [Auth](#auth)

| Method | Description | Response |
| --- | --- | --- |
| `auth.set({ ... })` | Set authentication credentials | `boolean` |

---

##### [Examples](#examples-8)

```
await client.auth.set({

path: { id: "anthropic" },

body: { type: "api", key: "your-api-key" },

})
```

---

#### [Events](#events)

| Method | Description | Response |
| --- | --- | --- |
| `event.subscribe()` | Server-sent events stream | Server-sent events stream |

---

##### [Examples](#examples-9)

```
// Listen to real-time events

const events = await client.event.subscribe()

for await (const event of events.stream) {

console.log("Event:", event.type, event.properties)

}
```

[Edit page](https://github.com/anomalyco/opencode/edit/dev/packages/web/src/content/docs/sdk.mdx)[Found a bug? Open an issue](https://github.com/anomalyco/opencode/issues/new)[Join our Discord community](https://opencode.ai/discord)  Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

© [Anomaly](https://anoma.ly)

Last updated: Oct 13, 2026

---
<!--
URL: https://opencode.ai/docs/rules
title: Rules | OpenCode
-->

[Skip to content](#_top)

[![](/docs/_astro/logo-dark.DOStV66V.svg) ![](/docs/_astro/logo-light.B0yzR0O5.svg)  OpenCode](/docs/)

[app.header.home](/)[app.header.docs](/v2/docs)

Search  `CtrlK`

Cancel

  [New OpenCode v2 is now available →](https://opencode.ai/v2)

* [Intro](/docs/)
* [Config](/docs/config/)
* [Providers](/docs/providers/)
* [Network](/docs/network/)
* [Enterprise](/docs/enterprise/)
* [Troubleshooting](/docs/troubleshooting/)
* [Windows](/docs/windows-wsl)
* Usage

  + [Go](https://opencode.ai/v2/docs/console/go/)
  + [TUI](/docs/tui/)
  + [CLI](/docs/cli/)
  + [Web](/docs/web/)
  + [IDE](/docs/ide/)
  + [Console](https://opencode.ai/v2/docs/console/)
  + [Share](/docs/share/)
  + [GitHub](/docs/github/)
  + [GitLab](/docs/gitlab/)
* Configure

  + [Tools](/docs/tools/)
  + [Rules](/docs/rules/)
  + [Agents](/docs/agents/)
  + [Models](/docs/models/)
  + [Themes](/docs/themes/)
  + [Keybinds](/docs/keybinds/)
  + [Commands](/docs/commands/)
  + [Formatters](/docs/formatters/)
  + [Permissions](/docs/permissions/)
  + [Policies](/docs/policies/)
  + [LSP Servers](/docs/lsp/)
  + [MCP servers](/docs/mcp-servers/)
  + [ACP Support](/docs/acp/)
  + [Agent Skills](/docs/skills/)
  + [References](/docs/references/)
  + [Custom Tools](/docs/custom-tools/)
* Develop

  + [SDK](/docs/sdk/)
  + [Server](/docs/server/)
  + [Plugins](/docs/plugins/)
  + [Ecosystem](/docs/ecosystem/)

[GitHub](https://github.com/anomalyco/opencode)[Discord](https://opencode.ai/discord)

  Select theme   DarkLightAuto         Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

On this page

* [Overview](#_top)
* [Initialize](#initialize)
* [Example](#example)
* [Types](#types)
  + [Project](#project)
  + [Global](#global)
  + [Claude Code Compatibility](#claude-code-compatibility)
* [Precedence](#precedence)
* [Custom Instructions](#custom-instructions)
* [Referencing External Files](#referencing-external-files)
  + [Using opencode.json](#using-opencodejson)
  + [Manual Instructions in AGENTS.md](#manual-instructions-in-agentsmd)

### On this page

* [Overview](#_top)
* [Initialize](#initialize)
* [Example](#example)
* [Types](#types)
  + [Project](#project)
  + [Global](#global)
  + [Claude Code Compatibility](#claude-code-compatibility)
* [Precedence](#precedence)
* [Custom Instructions](#custom-instructions)
* [Referencing External Files](#referencing-external-files)
  + [Using opencode.json](#using-opencodejson)
  + [Manual Instructions in AGENTS.md](#manual-instructions-in-agentsmd)

## Rules

Set custom instructions for opencode.

You can provide custom instructions to opencode by creating an `AGENTS.md` file. This is similar to Cursorâs rules. It contains instructions that will be included in the LLMâs context to customize its behavior for your specific project.

---

### [Initialize](#initialize)

To create a new `AGENTS.md` file, you can run the `/init` command in opencode.

Tip

You should commit your projectâs `AGENTS.md` file to Git.

`/init` scans the important files in your repo, may ask a couple of targeted questions when the codebase cannot answer them, and then creates or updates `AGENTS.md` with concise project-specific guidance.

It focuses on the things future agent sessions are most likely to need:

* build, lint, and test commands
* command order and focused verification steps when they matter
* architecture and repo structure that are not obvious from filenames alone
* project-specific conventions, setup quirks, and operational gotchas
* references to existing instruction sources like Cursor or Copilot rules

If you already have an `AGENTS.md`, `/init` will improve it in place instead of blindly replacing it.

---

### [Example](#example)

You can also just create this file manually. Hereâs an example of some things you can put into an `AGENTS.md` file.

AGENTS.md

```

## SST v3 Monorepo Project

This is an SST v3 monorepo with TypeScript. The project uses bun workspaces for package management.

### Project Structure

- `packages/` - Contains all workspace packages (functions, core, web, etc.)

- `infra/` - Infrastructure definitions split by service (storage.ts, api.ts, web.ts)

- `sst.config.ts` - Main SST configuration with dynamic imports

### Code Standards

- Use TypeScript with strict mode enabled

- Shared code goes in `packages/core/` with proper exports configuration

- Functions go in `packages/functions/`

- Infrastructure should be split into logical files in `infra/`

### Monorepo Conventions

- Import shared modules using workspace names: `@my-app/core/example`
```

We are adding project-specific instructions here and this will be shared across your team.

---

### [Types](#types)

opencode also supports reading the `AGENTS.md` file from multiple locations. And this serves different purposes.

#### [Project](#project)

Place an `AGENTS.md` in your project root for project-specific rules. These only apply when you are working in this directory or its sub-directories.

#### [Global](#global)

You can also have global rules in a `~/.config/opencode/AGENTS.md` file. This gets applied across all opencode sessions.

Since this isnât committed to Git or shared with your team, we recommend using this to specify any personal rules that the LLM should follow.

#### [Claude Code Compatibility](#claude-code-compatibility)

For users migrating from Claude Code, OpenCode supports Claude Codeâs file conventions as fallbacks:

* **Project rules**: `CLAUDE.md` in your project directory (used if no `AGENTS.md` exists)
* **Global rules**: `~/.claude/CLAUDE.md` (used if no `~/.config/opencode/AGENTS.md` exists)
* **Skills**: `~/.claude/skills/` â see [Agent Skills](/docs/skills/) for details

To disable Claude Code compatibility, set one of these environment variables:

Terminal window

```
export OPENCODE_DISABLE_CLAUDE_CODE=1        # Disable all .claude support

export OPENCODE_DISABLE_CLAUDE_CODE_PROMPT=1 # Disable only ~/.claude/CLAUDE.md

export OPENCODE_DISABLE_CLAUDE_CODE_SKILLS=1 # Disable only .claude/skills
```

---

### [Precedence](#precedence)

When opencode starts, it looks for rule files in this order:

1. **Local files** by traversing up from the current directory (`AGENTS.md`, `CLAUDE.md`)
2. **Global file** at `~/.config/opencode/AGENTS.md`
3. **Claude Code file** at `~/.claude/CLAUDE.md` (unless disabled)

The first matching file wins in each category. For example, if you have both `AGENTS.md` and `CLAUDE.md`, only `AGENTS.md` is used. Similarly, `~/.config/opencode/AGENTS.md` takes precedence over `~/.claude/CLAUDE.md`.

---

### [Custom Instructions](#custom-instructions)

You can specify custom instruction files in your `opencode.json` or the global `~/.config/opencode/opencode.json`. This allows you and your team to reuse existing rules rather than having to duplicate them to AGENTS.md.

Example:

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"instructions": ["CONTRIBUTING.md", "docs/guidelines.md", ".cursor/rules/*.md"]

}
```

You can also use remote URLs to load instructions from the web.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"instructions": ["https://raw.githubusercontent.com/my-org/shared-rules/main/style.md"]

}
```

Remote instructions are fetched with a 5 second timeout.

All instruction files are combined with your `AGENTS.md` files.

---

### [Referencing External Files](#referencing-external-files)

While opencode doesnât automatically parse file references in `AGENTS.md`, you can achieve similar functionality in two ways:

#### [Using opencode.json](#using-opencodejson)

The recommended approach is to use the `instructions` field in `opencode.json`:

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"instructions": ["docs/development-standards.md", "test/testing-guidelines.md", "packages/*/AGENTS.md"]

}
```

#### [Manual Instructions in AGENTS.md](#manual-instructions-in-agentsmd)

You can teach opencode to read external files by providing explicit instructions in your `AGENTS.md`. Hereâs a practical example:

AGENTS.md

```

## TypeScript Project Rules

### External File Loading

CRITICAL: When you encounter a file reference (e.g., @rules/general.md), use your Read tool to load it on a need-to-know basis. They're relevant to the SPECIFIC task at hand.

Instructions:

- Do NOT preemptively load all references - use lazy loading based on actual need

- When loaded, treat content as mandatory instructions that override defaults

- Follow references recursively when needed

### Development Guidelines

For TypeScript code style and best practices: @docs/typescript-guidelines.md

For React component architecture and hooks patterns: @docs/react-patterns.md

For REST API design and error handling: @docs/api-standards.md

For testing strategies and coverage requirements: @test/testing-guidelines.md

### General Guidelines

Read the following file immediately as it's relevant to all workflows: @rules/general-guidelines.md.
```

This approach allows you to:

* Create modular, reusable rule files
* Share rules across projects via symlinks or git submodules
* Keep AGENTS.md concise while referencing detailed guidelines
* Ensure opencode loads files only when needed for the specific task

Tip

For monorepos or projects with shared standards, using `opencode.json` with glob patterns (like `packages/*/AGENTS.md`) is more maintainable than manual instructions.

[Edit page](https://github.com/anomalyco/opencode/edit/dev/packages/web/src/content/docs/rules.mdx)[Found a bug? Open an issue](https://github.com/anomalyco/opencode/issues/new)[Join our Discord community](https://opencode.ai/discord)  Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

© [Anomaly](https://anoma.ly)

Last updated: Oct 13, 2026

---
<!--
URL: https://opencode.ai/docs/references
title: References | OpenCode
-->

[Skip to content](#_top)

[![](/docs/_astro/logo-dark.DOStV66V.svg) ![](/docs/_astro/logo-light.B0yzR0O5.svg)  OpenCode](/docs/)

[app.header.home](/)[app.header.docs](/v2/docs)

Search  `CtrlK`

Cancel

  [New OpenCode v2 is now available →](https://opencode.ai/v2)

* [Intro](/docs/)
* [Config](/docs/config/)
* [Providers](/docs/providers/)
* [Network](/docs/network/)
* [Enterprise](/docs/enterprise/)
* [Troubleshooting](/docs/troubleshooting/)
* [Windows](/docs/windows-wsl)
* Usage

  + [Go](https://opencode.ai/v2/docs/console/go/)
  + [TUI](/docs/tui/)
  + [CLI](/docs/cli/)
  + [Web](/docs/web/)
  + [IDE](/docs/ide/)
  + [Console](https://opencode.ai/v2/docs/console/)
  + [Share](/docs/share/)
  + [GitHub](/docs/github/)
  + [GitLab](/docs/gitlab/)
* Configure

  + [Tools](/docs/tools/)
  + [Rules](/docs/rules/)
  + [Agents](/docs/agents/)
  + [Models](/docs/models/)
  + [Themes](/docs/themes/)
  + [Keybinds](/docs/keybinds/)
  + [Commands](/docs/commands/)
  + [Formatters](/docs/formatters/)
  + [Permissions](/docs/permissions/)
  + [Policies](/docs/policies/)
  + [LSP Servers](/docs/lsp/)
  + [MCP servers](/docs/mcp-servers/)
  + [ACP Support](/docs/acp/)
  + [Agent Skills](/docs/skills/)
  + [References](/docs/references/)
  + [Custom Tools](/docs/custom-tools/)
* Develop

  + [SDK](/docs/sdk/)
  + [Server](/docs/server/)
  + [Plugins](/docs/plugins/)
  + [Ecosystem](/docs/ecosystem/)

[GitHub](https://github.com/anomalyco/opencode)[Discord](https://opencode.ai/discord)

  Select theme   DarkLightAuto         Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

On this page

* [Overview](#_top)
* [Local directories](#local-directories)
* [Git repositories](#git-repositories)
* [Describe usage](#describe-usage)
* [Hide autocomplete entries](#hide-autocomplete-entries)
* [Use references](#use-references)
* [Configure fields](#configure-fields)

### On this page

* [Overview](#_top)
* [Local directories](#local-directories)
* [Git repositories](#git-repositories)
* [Describe usage](#describe-usage)
* [Hide autocomplete entries](#hide-autocomplete-entries)
* [Use references](#use-references)
* [Configure fields](#configure-fields)

## References

Add local directories and Git repositories as project references.

References give OpenCode access to directories outside the current project. Use them to make documentation, shared libraries, examples, or another repository available while you work.

References are configured by alias in `opencode.json` or `opencode.jsonc`.

opencode.jsonc

```
{

"$schema": "https://opencode.ai/config.json",

"references": {

"docs": {

"path": "../product-docs",

"description": "Use for product behavior and documentation conventions",

},

"sdk": {

"repository": "anomalyco/opencode-sdk-js",

"branch": "main",

"description": "Use for JavaScript SDK implementation details",

},

},

}
```

---

### [Local directories](#local-directories)

Use `path` to reference a local directory.

opencode.jsonc

```
{

"references": {

"docs": {

"path": "../docs",

},

},

}
```

Paths can be:

* Relative to the config file that defines the reference
* Absolute, such as `/home/user/docs`
* Relative to your home directory, such as `~/docs`

You can also use a string shorthand:

opencode.jsonc

```
{

"references": {

"docs": "../docs",

},

}
```

---

### [Git repositories](#git-repositories)

Use `repository` to reference a Git repository. OpenCode materializes the repository in its local repository cache and makes the checked-out source available as a reference directory.

opencode.jsonc

```
{

"references": {

"effect": {

"repository": "Effect-TS/effect",

"branch": "main",

},

},

}
```

`repository` accepts Git URLs, host/path references, and GitHub `owner/repo` shorthand. The optional `branch` field selects a branch or ref. Without `branch`, OpenCode uses the repositoryâs default branch.

You can use string shorthand when you do not need a branch, description, or other options:

opencode.jsonc

```
{

"references": {

"effect": "Effect-TS/effect",

},

}
```

Note

Git references are refreshed asynchronously. A newly configured repository may take a moment to finish cloning or updating.

---

### [Describe usage](#describe-usage)

Add `description` to explain when an agent should use a reference.

opencode.jsonc

```
{

"references": {

"design-system": {

"path": "../design-system",

"description": "Use when implementing UI components or design tokens",

},

},

}
```

OpenCode includes references with descriptions in agent context. Descriptions should be short and specific enough to distinguish references with similar content. References without descriptions remain available through autocomplete and direct use, but are not advertised to agents.

---

### [Hide autocomplete entries](#hide-autocomplete-entries)

Set `hidden` to `true` to omit a reference from `@` autocomplete in the TUI.

opencode.jsonc

```
{

"references": {

"internal": {

"path": "../internal",

"description": "Use for internal implementation details",

"hidden": true,

},

},

}
```

`hidden` only affects autocomplete. A hidden reference with a description remains included in agent context.

---

### [Use references](#use-references)

Configured references appear in TUI `@` autocomplete. Type `@alias` to attach the reference root, or `@alias/` to search for files inside it.

```
Compare this implementation with @sdk/src/client.ts
```

Agents also receive the resolved paths and descriptions of configured references that have descriptions in their system context, so they can inspect a reference when it is relevant without you attaching it manually.

OpenCode automatically allows reference directories through its external-directory permission boundary. Normal tool permissions still apply; for example, an agent that cannot edit files does not gain edit access because a directory is configured as a reference.

---

### [Configure fields](#configure-fields)

| Field | Local | Git | Description |
| --- | --- | --- | --- |
| `path` | Yes | No | Local reference directory |
| `repository` | No | Yes | Git URL, host/path, or GitHub `owner/repo` value |
| `branch` | No | Yes | Optional Git branch or ref |
| `description` | Yes | Yes | Guidance describing when to use the reference |
| `hidden` | Yes | Yes | Hide the reference from TUI `@` autocomplete |

Reference aliases cannot be empty or contain `/`, whitespace, backticks, or commas.

[Edit page](https://github.com/anomalyco/opencode/edit/dev/packages/web/src/content/docs/references.mdx)[Found a bug? Open an issue](https://github.com/anomalyco/opencode/issues/new)[Join our Discord community](https://opencode.ai/discord)  Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

© [Anomaly](https://anoma.ly)

Last updated: Oct 13, 2026

---
<!--
URL: https://opencode.ai/docs/tui
title: TUI | OpenCode
-->

[Skip to content](#_top)

[![](/docs/_astro/logo-dark.DOStV66V.svg) ![](/docs/_astro/logo-light.B0yzR0O5.svg)  OpenCode](/docs/)

[app.header.home](/)[app.header.docs](/v2/docs)

Search  `CtrlK`

Cancel

  [New OpenCode v2 is now available →](https://opencode.ai/v2)

* [Intro](/docs/)
* [Config](/docs/config/)
* [Providers](/docs/providers/)
* [Network](/docs/network/)
* [Enterprise](/docs/enterprise/)
* [Troubleshooting](/docs/troubleshooting/)
* [Windows](/docs/windows-wsl)
* Usage

  + [Go](https://opencode.ai/v2/docs/console/go/)
  + [TUI](/docs/tui/)
  + [CLI](/docs/cli/)
  + [Web](/docs/web/)
  + [IDE](/docs/ide/)
  + [Console](https://opencode.ai/v2/docs/console/)
  + [Share](/docs/share/)
  + [GitHub](/docs/github/)
  + [GitLab](/docs/gitlab/)
* Configure

  + [Tools](/docs/tools/)
  + [Rules](/docs/rules/)
  + [Agents](/docs/agents/)
  + [Models](/docs/models/)
  + [Themes](/docs/themes/)
  + [Keybinds](/docs/keybinds/)
  + [Commands](/docs/commands/)
  + [Formatters](/docs/formatters/)
  + [Permissions](/docs/permissions/)
  + [Policies](/docs/policies/)
  + [LSP Servers](/docs/lsp/)
  + [MCP servers](/docs/mcp-servers/)
  + [ACP Support](/docs/acp/)
  + [Agent Skills](/docs/skills/)
  + [References](/docs/references/)
  + [Custom Tools](/docs/custom-tools/)
* Develop

  + [SDK](/docs/sdk/)
  + [Server](/docs/server/)
  + [Plugins](/docs/plugins/)
  + [Ecosystem](/docs/ecosystem/)

[GitHub](https://github.com/anomalyco/opencode)[Discord](https://opencode.ai/discord)

  Select theme   DarkLightAuto         Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

On this page

* [Overview](#_top)
* [File references](#file-references)
* [Bash commands](#bash-commands)
* [Commands](#commands)
  + [connect](#connect)
  + [compact](#compact)
  + [details](#details)
  + [editor](#editor)
  + [exit](#exit)
  + [export](#export)
  + [help](#help)
  + [init](#init)
  + [models](#models)
  + [new](#new)
  + [redo](#redo)
  + [sessions](#sessions)
  + [share](#share)
  + [themes](#themes)
  + [thinking](#thinking)
  + [undo](#undo)
  + [unshare](#unshare)
* [Editor setup](#editor-setup)
* [Configure](#configure)
  + [Options](#options)
  + [Attention](#attention)
* [Customization](#customization)

### On this page

* [Overview](#_top)
* [File references](#file-references)
* [Bash commands](#bash-commands)
* [Commands](#commands)
  + [connect](#connect)
  + [compact](#compact)
  + [details](#details)
  + [editor](#editor)
  + [exit](#exit)
  + [export](#export)
  + [help](#help)
  + [init](#init)
  + [models](#models)
  + [new](#new)
  + [redo](#redo)
  + [sessions](#sessions)
  + [share](#share)
  + [themes](#themes)
  + [thinking](#thinking)
  + [undo](#undo)
  + [unshare](#unshare)
* [Editor setup](#editor-setup)
* [Configure](#configure)
  + [Options](#options)
  + [Attention](#attention)
* [Customization](#customization)

## TUI

Using the OpenCode terminal user interface.

OpenCode provides an interactive terminal interface or TUI for working on your projects with an LLM.

Running OpenCode starts the TUI for the current directory.

Terminal window

```
opencode
```

Or you can start it for a specific working directory.

Terminal window

```
opencode /path/to/project
```

Once youâre in the TUI, you can prompt it with a message.

```
Give me a quick summary of the codebase.
```

---

### [File references](#file-references)

You can reference files in your messages using `@`. This does a fuzzy file search in the current working directory.

Tip

You can also use `@` to reference files in your messages.

```
How is auth handled in @packages/functions/src/api/index.ts?
```

The content of the file is added to the conversation automatically.

Configured [references](/docs/references) also appear in `@` autocomplete. Type `@alias` to add the reference root as context, or type `@alias/` to autocomplete files inside that reference.

```
Compare our setup with @docs/README.md
```

---

### [Bash commands](#bash-commands)

Start a message with `!` to run a shell command.

```
!ls -la
```

The output of the command is added to the conversation as a tool result.

---

### [Commands](#commands)

When using the OpenCode TUI, you can type `/` followed by a command name to quickly execute actions. For example:

```
/help
```

Most commands also have keyboard shortcuts using `ctrl+x` as the default leader key. [Learn more](/docs/keybinds).

Here are all available slash commands:

---

#### [connect](#connect)

Add a provider to OpenCode. Allows you to select from available providers and add their API keys.

```
/connect
```

---

#### [compact](#compact)

Compact the current session. *Alias*: `/summarize`

```
/compact
```

**Keybind:** `ctrl+x c`

---

#### [details](#details)

Toggle tool execution details.

```
/details
```

---

#### [editor](#editor)

Open external editor for composing messages. Uses the editor set in your `EDITOR` environment variable. [Learn more](#editor-setup).

```
/editor
```

**Keybind:** `ctrl+x e`

---

#### [exit](#exit)

Exit OpenCode. *Aliases*: `/quit`, `/q`

```
/exit
```

**Keybind:** `ctrl+x q`

---

#### [export](#export)

Export current conversation to Markdown and open in your default editor. Uses the editor set in your `EDITOR` environment variable. [Learn more](#editor-setup).

```
/export
```

**Keybind:** `ctrl+x x`

---

#### [help](#help)

Show the help dialog.

```
/help
```

---

#### [init](#init)

Guided setup for creating or updating `AGENTS.md`. [Learn more](/docs/rules).

```
/init
```

---

#### [models](#models)

List available models.

```
/models
```

**Keybind:** `ctrl+x m`

---

#### [new](#new)

Start a new session. *Alias*: `/clear`

```
/new
```

**Keybind:** `ctrl+x n`

---

#### [redo](#redo)

Redo a previously undone message. Only available after using `/undo`.

Tip

Any file changes will also be restored.

Internally, this uses Git to manage the file changes. So your project **needs to
be a Git repository**.

```
/redo
```

**Keybind:** `ctrl+x r`

---

#### [sessions](#sessions)

List and switch between sessions. *Aliases*: `/resume`, `/continue`

```
/sessions
```

**Keybind:** `ctrl+x l`

---

#### [share](#share)

Share current session. [Learn more](/docs/share).

```
/share
```

---

#### [themes](#themes)

List available themes.

```
/themes
```

**Keybind:** `ctrl+x t`

---

#### [thinking](#thinking)

Toggle the visibility of thinking/reasoning blocks in the conversation. When enabled, you can see the modelâs reasoning process for models that support extended thinking.

Note

This command only controls whether thinking blocks are **displayed** - it does not enable or disable the modelâs reasoning capabilities. To toggle actual reasoning capabilities, use `ctrl+t` to cycle through model variants.

```
/thinking
```

---

#### [undo](#undo)

Undo last message in the conversation. Removes the most recent user message, all subsequent responses, and any file changes.

Tip

Any file changes made will also be reverted.

Internally, this uses Git to manage the file changes. So your project **needs to
be a Git repository**.

```
/undo
```

**Keybind:** `ctrl+x u`

---

#### [unshare](#unshare)

Unshare current session. [Learn more](/docs/share#un-sharing).

```
/unshare
```

---

### [Editor setup](#editor-setup)

Both the `/editor` and `/export` commands use the editor specified in your `EDITOR` environment variable.

* [Linux/macOS](#tab-panel-4)
* [Windows (CMD)](#tab-panel-5)
* [Windows (PowerShell)](#tab-panel-6)

Terminal window

```

## Example for nano or vim

export EDITOR=nano

export EDITOR=vim

## For GUI editors, VS Code, Cursor, VSCodium, Windsurf, Zed, etc.

## include --wait

export EDITOR="code --wait"
```

To make it permanent, add this to your shell profile;
`~/.bashrc`, `~/.zshrc`, etc.

Terminal window

```
set EDITOR=notepad

## For GUI editors, VS Code, Cursor, VSCodium, Windsurf, Zed, etc.

## include --wait

set EDITOR=code --wait
```

To make it permanent, use **System Properties** > **Environment
Variables**.

Terminal window

```
$env:EDITOR = "notepad"

## For GUI editors, VS Code, Cursor, VSCodium, Windsurf, Zed, etc.

## include --wait

$env:EDITOR = "code --wait"
```

To make it permanent, add this to your PowerShell profile.

Popular editor options include:

* `code` - Visual Studio Code
* `cursor` - Cursor
* `windsurf` - Windsurf
* `nvim` - Neovim editor
* `vim` - Vim editor
* `nano` - Nano editor
* `notepad` - Windows Notepad
* `subl` - Sublime Text

Note

Some editors like VS Code need to be started with the `--wait` flag.

Some editors need command-line arguments to run in blocking mode. The `--wait` flag makes the editor process block until closed.

---

### [Configure](#configure)

You can customize TUI behavior through `tui.json` (or `tui.jsonc`).

tui.json

```
{

"$schema": "https://opencode.ai/tui.json",

"theme": "opencode",

"leader_timeout": 2000,

"keybinds": {

"leader": "ctrl+x",

"command_list": "ctrl+p"

},

"scroll_speed": 3,

"scroll_acceleration": {

"enabled": false

},

"diff_style": "auto",

"cursor": {

"style": "block",

"blinking": true

},

"mouse": true,

"attention": {

"enabled": true,

"notifications": true,

"sound": true,

"volume": 0.4,

"sound_pack": "opencode.default",

"sounds": {

"error": "./sounds/error.mp3"

}

}

}
```

This is separate from `opencode.json`, which configures server/runtime behavior.

`keybinds` is merged with built-in defaults, so you only need to configure the shortcuts you want to change.

#### [Options](#options)

* `theme` - Sets your UI theme. [Learn more](/docs/themes).
* `keybinds` - Customizes keyboard shortcuts. [Learn more](/docs/keybinds).
* `leader_timeout` - Controls how long OpenCode waits after the leader key. Defaults to `2000`.
* `scroll_acceleration.enabled` - Enable macOS-style scroll acceleration for smooth, natural scrolling. When enabled, scroll speed increases with rapid scrolling gestures and stays precise for slower movements. **This setting takes precedence over `scroll_speed` and overrides it when enabled.**
* `scroll_speed` - Controls how fast the TUI scrolls when using scroll commands (minimum: `0.001`, supports decimal values). Defaults to `3`. **Note: This is ignored if `scroll_acceleration.enabled` is set to `true`.**
* `diff_style` - Controls diff rendering. `"auto"` adapts to terminal width, `"stacked"` always shows a single-column layout.
* `cursor` - Controls the terminal cursor in TUI input fields. `style` defaults to `"block"`, can be `"underline"`, `"line"`, or `"default"`; `blinking` defaults to `true`. When `style` is `"default"`, the terminal default cursor is restored, so `blinking` has no effect.
* `mouse` - Enable or disable mouse capture in the TUI (default: `true`). When disabled, the terminalâs native mouse selection/scrolling behavior is preserved.
* `attention` - Configures TUI desktop notifications and sounds. Disabled by default.

Use `OPENCODE_TUI_CONFIG` to load a custom TUI config path.

#### [Attention](#attention)

The TUI can request attention for questions, permissions, session errors, and completed sessions. Enable it with `attention.enabled`; built-in events play sounds when triggered, and non-subagent events request desktop notifications only when the terminal is blurred.

* `enabled` - Enable all attention notifications and sounds. Defaults to `false`.
* `notifications` - Allow terminal-mediated desktop notifications when attention is enabled. Defaults to `true`.
* `sound` - Allow attention sounds when attention is enabled. Defaults to `true`.
* `volume` - Default sound volume from `0` to `1`. Defaults to `0.4`.
* `sound_pack` - Sound pack ID to use. Defaults to `opencode.default`.
* `sounds` - Override sound files for `default`, `question`, `permission`, `error`, `done`, or `subagent_done`. Paths can be absolute, `file://` URLs, or relative to `tui.json`.

---

### [Customization](#customization)

You can customize various aspects of the TUI view using the command palette (`ctrl+p`). These settings persist across restarts.

---

##### [Username display](#username-display)

Toggle whether your username appears in chat messages. Access this through:

* Command palette: Search for âusernameâ or âhide usernameâ
* The setting persists automatically and will be remembered across TUI sessions

[Edit page](https://github.com/anomalyco/opencode/edit/dev/packages/web/src/content/docs/tui.mdx)[Found a bug? Open an issue](https://github.com/anomalyco/opencode/issues/new)[Join our Discord community](https://opencode.ai/discord)  Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

© [Anomaly](https://anoma.ly)

Last updated: Oct 13, 2026

---
<!--
URL: https://opencode.ai/docs/agents
title: Agents | OpenCode
-->

[Skip to content](#_top)

[![](/docs/_astro/logo-dark.DOStV66V.svg) ![](/docs/_astro/logo-light.B0yzR0O5.svg)  OpenCode](/docs/)

[app.header.home](/)[app.header.docs](/v2/docs)

Search  `CtrlK`

Cancel

  [New OpenCode v2 is now available →](https://opencode.ai/v2)

* [Intro](/docs/)
* [Config](/docs/config/)
* [Providers](/docs/providers/)
* [Network](/docs/network/)
* [Enterprise](/docs/enterprise/)
* [Troubleshooting](/docs/troubleshooting/)
* [Windows](/docs/windows-wsl)
* Usage

  + [Go](https://opencode.ai/v2/docs/console/go/)
  + [TUI](/docs/tui/)
  + [CLI](/docs/cli/)
  + [Web](/docs/web/)
  + [IDE](/docs/ide/)
  + [Console](https://opencode.ai/v2/docs/console/)
  + [Share](/docs/share/)
  + [GitHub](/docs/github/)
  + [GitLab](/docs/gitlab/)
* Configure

  + [Tools](/docs/tools/)
  + [Rules](/docs/rules/)
  + [Agents](/docs/agents/)
  + [Models](/docs/models/)
  + [Themes](/docs/themes/)
  + [Keybinds](/docs/keybinds/)
  + [Commands](/docs/commands/)
  + [Formatters](/docs/formatters/)
  + [Permissions](/docs/permissions/)
  + [Policies](/docs/policies/)
  + [LSP Servers](/docs/lsp/)
  + [MCP servers](/docs/mcp-servers/)
  + [ACP Support](/docs/acp/)
  + [Agent Skills](/docs/skills/)
  + [References](/docs/references/)
  + [Custom Tools](/docs/custom-tools/)
* Develop

  + [SDK](/docs/sdk/)
  + [Server](/docs/server/)
  + [Plugins](/docs/plugins/)
  + [Ecosystem](/docs/ecosystem/)

[GitHub](https://github.com/anomalyco/opencode)[Discord](https://opencode.ai/discord)

  Select theme   DarkLightAuto         Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

On this page

* [Overview](#_top)
* [Types](#types)
  + [Primary agents](#primary-agents)
  + [Subagents](#subagents)
* [Built-in](#built-in)
  + [Use build](#use-build)
  + [Use plan](#use-plan)
  + [Use general](#use-general)
  + [Use explore](#use-explore)
  + [Use scout](#use-scout)
  + [Use compaction](#use-compaction)
  + [Use title](#use-title)
  + [Use summary](#use-summary)
* [Usage](#usage)
* [Configure](#configure)
  + [JSON](#json)
  + [Markdown](#markdown)
* [Options](#options)
  + [Description](#description)
  + [Temperature](#temperature)
  + [Max steps](#max-steps)
  + [Disable](#disable)
  + [Prompt](#prompt)
  + [Model](#model)
  + [Tools (deprecated)](#tools-deprecated)
  + [Permissions](#permissions)
  + [Mode](#mode)
  + [Hidden](#hidden)
  + [Task permissions](#task-permissions)
  + [Color](#color)
  + [Top P](#top-p)
  + [Additional](#additional)
* [Create agents](#create-agents)
* [Use cases](#use-cases)
* [Examples](#examples)
  + [Documentation agent](#documentation-agent)
  + [Security auditor](#security-auditor)

### On this page

* [Overview](#_top)
* [Types](#types)
  + [Primary agents](#primary-agents)
  + [Subagents](#subagents)
* [Built-in](#built-in)
  + [Use build](#use-build)
  + [Use plan](#use-plan)
  + [Use general](#use-general)
  + [Use explore](#use-explore)
  + [Use scout](#use-scout)
  + [Use compaction](#use-compaction)
  + [Use title](#use-title)
  + [Use summary](#use-summary)
* [Usage](#usage)
* [Configure](#configure)
  + [JSON](#json)
  + [Markdown](#markdown)
* [Options](#options)
  + [Description](#description)
  + [Temperature](#temperature)
  + [Max steps](#max-steps)
  + [Disable](#disable)
  + [Prompt](#prompt)
  + [Model](#model)
  + [Tools (deprecated)](#tools-deprecated)
  + [Permissions](#permissions)
  + [Mode](#mode)
  + [Hidden](#hidden)
  + [Task permissions](#task-permissions)
  + [Color](#color)
  + [Top P](#top-p)
  + [Additional](#additional)
* [Create agents](#create-agents)
* [Use cases](#use-cases)
* [Examples](#examples)
  + [Documentation agent](#documentation-agent)
  + [Security auditor](#security-auditor)

## Agents

Configure and use specialized agents.

Agents are specialized AI assistants that can be configured for specific tasks and workflows. They allow you to create focused tools with custom prompts, models, and tool access.

Tip

Use the plan agent to analyze code and review suggestions without making any code changes.

You can switch between agents during a session or invoke them with the `@` mention.

---

### [Types](#types)

There are two types of agents in OpenCode; primary agents and subagents.

---

#### [Primary agents](#primary-agents)

Primary agents are the main assistants you interact with directly. You can cycle through them using the **Tab** key, or your configured `switch_agent` keybind. These agents handle your main conversation. Tool access is configured via permissions â for example, Build has all tools enabled while Plan is restricted.

Tip

You can use the **Tab** key to switch between primary agents during a session.

OpenCode comes with two built-in primary agents, **Build** and **Plan**. Weâll
look at these below.

---

#### [Subagents](#subagents)

Subagents are specialized assistants that primary agents can invoke for specific tasks. You can also manually invoke them by **@ mentioning** them in your messages.

OpenCode comes with three built-in subagents, **General**, **Explore**, and **Scout**. Weâll look at this below.

---

### [Built-in](#built-in)

OpenCode comes with two built-in primary agents and three built-in subagents.

---

#### [Use build](#use-build)

*Mode*: `primary`

Build is the **default** primary agent with all tools enabled. This is the standard agent for development work where you need full access to file operations and system commands.

---

#### [Use plan](#use-plan)

*Mode*: `primary`

A restricted agent designed for planning and analysis. We use a permission system to give you more control and prevent unintended changes.
By default, all of the following are set to `ask`:

* `file edits`: All writes, patches, and edits
* `bash`: All bash commands

This agent is useful when you want the LLM to analyze code, suggest changes, or create plans without making any actual modifications to your codebase.

---

#### [Use general](#use-general)

*Mode*: `subagent`

A general-purpose agent for researching complex questions and executing multi-step tasks. Has full tool access, so it can make file changes when needed. Use this to run multiple units of work in parallel.

---

#### [Use explore](#use-explore)

*Mode*: `subagent`

A fast, read-only agent for exploring codebases. Cannot modify files. Use this when you need to quickly find files by patterns, search code for keywords, or answer questions about the codebase.

---

#### [Use scout](#use-scout)

*Mode*: `subagent`

A read-only agent for external docs and dependency research. Use this when you need to clone a dependency repository into OpenCodeâs managed cache, inspect library source, or cross-reference local code against upstream implementations without modifying your workspace.

---

#### [Use compaction](#use-compaction)

*Mode*: `primary`

Hidden system agent that compacts long context into a smaller summary. It runs automatically when needed and is not selectable in the UI.

---

#### [Use title](#use-title)

*Mode*: `primary`

Hidden system agent that generates short session titles. It runs automatically and is not selectable in the UI.

---

#### [Use summary](#use-summary)

*Mode*: `primary`

Hidden system agent that creates session summaries. It runs automatically and is not selectable in the UI.

---

### [Usage](#usage)

1. For primary agents, use the **Tab** key to cycle through them during a session. You can also use your configured `switch_agent` keybind.
2. Subagents can be invoked:

   * **Automatically** by primary agents for specialized tasks based on their descriptions.
   * Manually by **@ mentioning** a subagent in your message. For example.

     ```
     @general help me search for this function
     ```
3. **Navigation between sessions**: When subagents create child sessions, use `session_child_first` (default: **<Leader>+Down**) to enter the first child session from the parent.
4. Once you are in a child session, use:

   * `session_child_cycle` (default: **Right**) to cycle to the next child session
   * `session_child_cycle_reverse` (default: **Left**) to cycle to the previous child session
   * `session_parent` (default: **Up**) to return to the parent session

   This lets you switch between the main conversation and specialized subagent work.

---

### [Configure](#configure)

You can customize the built-in agents or create your own through configuration. Agents can be configured in two ways:

---

#### [JSON](#json)

Configure agents in your `opencode.json` config file:

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"agent": {

"build": {

"mode": "primary",

"model": "anthropic/claude-sonnet-4-20250514",

"prompt": "{file:./prompts/build.txt}",

"permission": {

"edit": "allow",

"bash": "allow"

}

},

"plan": {

"mode": "primary",

"model": "anthropic/claude-haiku-4-20250514",

"permission": {

"edit": "deny",

"bash": "deny"

}

},

"code-reviewer": {

"description": "Reviews code for best practices and potential issues",

"mode": "subagent",

"model": "anthropic/claude-sonnet-4-20250514",

"prompt": "You are a code reviewer. Focus on security, performance, and maintainability.",

"permission": {

"edit": "deny"

}

}

}

}
```

---

#### [Markdown](#markdown)

You can also define agents using markdown files. Place them in:

* Global: `~/.config/opencode/agents/`
* Per-project: `.opencode/agents/`

~/.config/opencode/agents/review.md

```
---

description: Reviews code for quality and best practices

mode: subagent

model: anthropic/claude-sonnet-4-20250514

temperature: 0.1

permission:

edit: deny

bash: deny

---

You are in code review mode. Focus on:

- Code quality and best practices

- Potential bugs and edge cases

- Performance implications

- Security considerations

Provide constructive feedback without making direct changes.
```

The markdown file name becomes the agent name. For example, `review.md` creates a `review` agent.

---

### [Options](#options)

Letâs look at these configuration options in detail.

---

#### [Description](#description)

Use the `description` option to provide a brief description of what the agent does and when to use it.

opencode.json

```
{

"agent": {

"review": {

"description": "Reviews code for best practices and potential issues"

}

}

}
```

This is a **required** config option.

---

#### [Temperature](#temperature)

Control the randomness and creativity of the LLMâs responses with the `temperature` config.

Lower values make responses more focused and deterministic, while higher values increase creativity and variability.

opencode.json

```
{

"agent": {

"plan": {

"temperature": 0.1

},

"creative": {

"temperature": 0.8

}

}

}
```

Temperature values typically range from 0.0 to 1.0:

* **0.0-0.2**: Very focused and deterministic responses, ideal for code analysis and planning
* **0.3-0.5**: Balanced responses with some creativity, good for general development tasks
* **0.6-1.0**: More creative and varied responses, useful for brainstorming and exploration

opencode.json

```
{

"agent": {

"analyze": {

"temperature": 0.1,

"prompt": "{file:./prompts/analysis.txt}"

},

"build": {

"temperature": 0.3

},

"brainstorm": {

"temperature": 0.7,

"prompt": "{file:./prompts/creative.txt}"

}

}

}
```

If no temperature is specified, OpenCode uses model-specific defaults; typically 0 for most models, 0.55 for Qwen models.

---

#### [Max steps](#max-steps)

Control the maximum number of agentic iterations an agent can perform before being forced to respond with text only. This allows users who wish to control costs to set a limit on agentic actions.

If this is not set, the agent will continue to iterate until the model chooses to stop or the user interrupts the session.

opencode.json

```
{

"agent": {

"quick-thinker": {

"description": "Fast reasoning with limited iterations",

"prompt": "You are a quick thinker. Solve problems with minimal steps.",

"steps": 5

}

}

}
```

When the limit is reached, the agent receives a special system prompt instructing it to respond with a summarization of its work and recommended remaining tasks.

Caution

The legacy `maxSteps` field is deprecated. Use `steps` instead.

---

#### [Disable](#disable)

Set to `true` to disable the agent.

opencode.json

```
{

"agent": {

"review": {

"disable": true

}

}

}
```

---

#### [Prompt](#prompt)

Specify a custom system prompt file for this agent with the `prompt` config. The prompt file should contain instructions specific to the agentâs purpose.

opencode.json

```
{

"agent": {

"review": {

"prompt": "{file:./prompts/code-review.txt}"

}

}

}
```

This path is relative to where the config file is located. So this works for both the global OpenCode config and the project specific config.

---

#### [Model](#model)

Use the `model` config to override the model for this agent. Useful for using different models optimized for different tasks. For example, a faster model for planning, a more capable model for implementation.

Tip

If you donât specify a model, primary agents use the [model globally configured](/docs/config#models) while subagents will use the model of the primary agent that invoked the subagent.

opencode.json

```
{

"agent": {

"plan": {

"model": "anthropic/claude-haiku-4-20250514"

}

}

}
```

The model ID in your OpenCode config uses the format `provider/model-id`. For example, if youâre using [OpenCode Zen](https://opencode.ai/v2/docs/console/), you would use `opencode/gpt-5.1-codex` for GPT 5.1 Codex.

---

#### [Tools (deprecated)](#tools-deprecated)

`tools` is **deprecated**. Prefer the agentâs [`permission`](#permissions) field for new configs, updates and more fine-grained control.

Allows you to control which tools are available in this agent. You can enable or disable specific tools by setting them to `true` or `false`. In an agentâs `tools` config, `true` is equivalent to `{"*": "allow"}` permission and `false` is equivalent to `{"*": "deny"}` permission.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"tools": {

"write": true,

"bash": true

},

"agent": {

"plan": {

"tools": {

"write": false,

"bash": false

}

}

}

}
```

Note

The agent-specific config overrides the global config.

You can also use wildcards in legacy `tools` entries to control multiple tools at once. For example, to disable all tools from an MCP server:

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"agent": {

"readonly": {

"tools": {

"mymcp_*": false,

"write": false,

"edit": false

}

}

}

}
```

[Learn more about tools](/docs/tools).

---

#### [Permissions](#permissions)

You can configure permissions to manage what actions an agent can take. Each permission key can be set to:

* `"ask"` â Prompt for approval before running the tool
* `"allow"` â Allow all operations without approval
* `"deny"` â Disable the tool

The available permission keys are:

| Key | Tools it gates |
| --- | --- |
| `read` | `read` |
| `edit` | `write`, `edit`, `apply_patch` |
| `glob` | `glob` |
| `grep` | `grep` |
| `list` | `list` |
| `bash` | `bash` |
| `task` | `task` |
| `external_directory` | Any tool that reads or writes files outside the project worktree |
| `webfetch` | `webfetch` |
| `websearch` | `websearch` |
| `lsp` | `lsp` |
| `skill` | `skill` |
| `question` | `question` |
| `doom_loop` | Recovery prompts when an agent appears stuck |

`read`, `edit`, `glob`, `grep`, `list`, `bash`, `task`, `external_directory`, `lsp`, and `skill` accept either a shorthand action (`"allow" | "ask" | "deny"`) or an object of glob/pattern â action for fine-grained control. The remaining keys accept the shorthand action only.

Note

Permission keys are matched as wildcard patterns against the underlying tool name, so the same syntax works for built-ins, custom tools, and MCP tools â for example `"mymcp_*": "deny"` denies every tool from an MCP server, and `"mymcp_search": "ask"` targets a single one.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"permission": {

"edit": "deny"

}

}
```

You can override these permissions per agent.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"permission": {

"edit": "deny"

},

"agent": {

"build": {

"permission": {

"edit": "ask"

}

}

}

}
```

You can also set permissions in Markdown agents.

~/.config/opencode/agents/review.md

```
---

description: Code review without edits

mode: subagent

permission:

edit: deny

bash:

"*": ask

"git diff": allow

"git log*": allow

"grep *": allow

webfetch: deny

---

Only analyze code and suggest changes.
```

You can set permissions for specific bash commands.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"agent": {

"build": {

"permission": {

"bash": {

"git push": "ask",

"grep *": "allow"

}

}

}

}

}
```

This can take a glob pattern.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"agent": {

"build": {

"permission": {

"bash": {

"git *": "ask"

}

}

}

}

}
```

And you can also use the `*` wildcard to manage permissions for all commands.
Since the last matching rule takes precedence, put the `*` wildcard first and specific rules after.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"agent": {

"build": {

"permission": {

"bash": {

"*": "ask",

"git status *": "allow"

}

}

}

}

}
```

[Learn more about permissions](/docs/permissions).

---

#### [Mode](#mode)

Control the agentâs mode with the `mode` config. The `mode` option is used to determine how the agent can be used.

opencode.json

```
{

"agent": {

"review": {

"mode": "subagent"

}

}

}
```

The `mode` option can be set to `primary`, `subagent`, or `all`. If no `mode` is specified, it defaults to `all`.

---

#### [Hidden](#hidden)

Hide a subagent from the `@` autocomplete menu with `hidden: true`. Useful for internal subagents that should only be invoked programmatically by other agents via the Task tool.

opencode.json

```
{

"agent": {

"internal-helper": {

"mode": "subagent",

"hidden": true

}

}

}
```

This only affects user visibility in the autocomplete menu. Hidden agents can still be invoked by the model via the Task tool if permissions allow.

Note

Only applies to `mode: subagent` agents.

---

#### [Task permissions](#task-permissions)

Control which subagents an agent can invoke via the Task tool with `permission.task`. Uses glob patterns for flexible matching.

opencode.json

```
{

"agent": {

"orchestrator": {

"mode": "primary",

"permission": {

"task": {

"*": "deny",

"orchestrator-*": "allow",

"code-reviewer": "ask"

}

}

}

}

}
```

When set to `deny`, the subagent is removed from the Task tool description entirely, so the model wonât attempt to invoke it.

Tip

Rules are evaluated in order, and the **last matching rule wins**. In the example above, `orchestrator-planner` matches both `*` (deny) and `orchestrator-*` (allow), but since `orchestrator-*` comes after `*`, the result is `allow`.

Tip

Users can always invoke any subagent directly via the `@` autocomplete menu, even if the agentâs task permissions would deny it.

---

#### [Color](#color)

Customize the agentâs visual appearance in the UI with the `color` option. This affects how the agent appears in the interface.

Use a valid hex color (e.g., `#FF5733`) or theme color: `primary`, `secondary`, `accent`, `success`, `warning`, `error`, `info`.

opencode.json

```
{

"agent": {

"creative": {

"color": "#ff6b6b"

},

"code-reviewer": {

"color": "accent"

}

}

}
```

---

#### [Top P](#top-p)

Control response diversity with the `top_p` option. Alternative to temperature for controlling randomness.

opencode.json

```
{

"agent": {

"brainstorm": {

"top_p": 0.9

}

}

}
```

Values range from 0.0 to 1.0. Lower values are more focused, higher values more diverse.

---

#### [Additional](#additional)

Any other options you specify in your agent configuration will be **passed through directly** to the provider as model options. This allows you to use provider-specific features and parameters.

For example, with OpenAIâs reasoning models, you can control the reasoning effort:

opencode.json

```
{

"agent": {

"deep-thinker": {

"description": "Agent that uses high reasoning effort for complex problems",

"model": "openai/gpt-5",

"reasoningEffort": "high",

"textVerbosity": "low"

}

}

}
```

These additional options are model and provider-specific. Check your providerâs documentation for available parameters.

Tip

Run `opencode models` to see a list of the available models.

---

### [Create agents](#create-agents)

You can create new agents using the following command:

Terminal window

```
opencode agent create
```

This interactive command will:

1. Ask where to save the agent; global or project-specific.
2. Description of what the agent should do.
3. Generate an appropriate system prompt and identifier.
4. Let you select which permissions the agent should be allowed (anything you donât select is denied).
5. Finally, create a markdown file with the agent configuration.

---

### [Use cases](#use-cases)

Here are some common use cases for different agents.

* **Build agent**: Full development work with all tools enabled
* **Plan agent**: Analysis and planning without making changes
* **Review agent**: Code review with read-only access plus documentation tools
* **Debug agent**: Focused on investigation with bash and read tools enabled
* **Docs agent**: Documentation writing with file operations but no system commands

---

### [Examples](#examples)

Here are some example agents you might find useful.

Tip

Do you have an agent youâd like to share? [Submit a PR](https://github.com/anomalyco/opencode).

---

#### [Documentation agent](#documentation-agent)

~/.config/opencode/agents/docs-writer.md

```
---

description: Writes and maintains project documentation

mode: subagent

permission:

bash: deny

---

You are a technical writer. Create clear, comprehensive documentation.

Focus on:

- Clear explanations

- Proper structure

- Code examples

- User-friendly language
```

---

#### [Security auditor](#security-auditor)

~/.config/opencode/agents/security-auditor.md

```
---

description: Performs security audits and identifies vulnerabilities

mode: subagent

permission:

edit: deny

---

You are a security expert. Focus on identifying potential security issues.

Look for:

- Input validation vulnerabilities

- Authentication and authorization flaws

- Data exposure risks

- Dependency vulnerabilities

- Configuration security issues
```

[Edit page](https://github.com/anomalyco/opencode/edit/dev/packages/web/src/content/docs/agents.mdx)[Found a bug? Open an issue](https://github.com/anomalyco/opencode/issues/new)[Join our Discord community](https://opencode.ai/discord)  Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

© [Anomaly](https://anoma.ly)

Last updated: Oct 13, 2026

---
<!--
URL: https://opencode.ai/docs/custom-tools
title: Custom Tools | OpenCode
-->

[Skip to content](#_top)

[![](/docs/_astro/logo-dark.DOStV66V.svg) ![](/docs/_astro/logo-light.B0yzR0O5.svg)  OpenCode](/docs/)

[app.header.home](/)[app.header.docs](/v2/docs)

Search  `CtrlK`

Cancel

  [New OpenCode v2 is now available →](https://opencode.ai/v2)

* [Intro](/docs/)
* [Config](/docs/config/)
* [Providers](/docs/providers/)
* [Network](/docs/network/)
* [Enterprise](/docs/enterprise/)
* [Troubleshooting](/docs/troubleshooting/)
* [Windows](/docs/windows-wsl)
* Usage

  + [Go](https://opencode.ai/v2/docs/console/go/)
  + [TUI](/docs/tui/)
  + [CLI](/docs/cli/)
  + [Web](/docs/web/)
  + [IDE](/docs/ide/)
  + [Console](https://opencode.ai/v2/docs/console/)
  + [Share](/docs/share/)
  + [GitHub](/docs/github/)
  + [GitLab](/docs/gitlab/)
* Configure

  + [Tools](/docs/tools/)
  + [Rules](/docs/rules/)
  + [Agents](/docs/agents/)
  + [Models](/docs/models/)
  + [Themes](/docs/themes/)
  + [Keybinds](/docs/keybinds/)
  + [Commands](/docs/commands/)
  + [Formatters](/docs/formatters/)
  + [Permissions](/docs/permissions/)
  + [Policies](/docs/policies/)
  + [LSP Servers](/docs/lsp/)
  + [MCP servers](/docs/mcp-servers/)
  + [ACP Support](/docs/acp/)
  + [Agent Skills](/docs/skills/)
  + [References](/docs/references/)
  + [Custom Tools](/docs/custom-tools/)
* Develop

  + [SDK](/docs/sdk/)
  + [Server](/docs/server/)
  + [Plugins](/docs/plugins/)
  + [Ecosystem](/docs/ecosystem/)

[GitHub](https://github.com/anomalyco/opencode)[Discord](https://opencode.ai/discord)

  Select theme   DarkLightAuto         Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

On this page

* [Overview](#_top)
* [Creating a tool](#creating-a-tool)
  + [Location](#location)
  + [Structure](#structure)
  + [Arguments](#arguments)
  + [Context](#context)
* [Examples](#examples)
  + [Write a tool in Python](#write-a-tool-in-python)

### On this page

* [Overview](#_top)
* [Creating a tool](#creating-a-tool)
  + [Location](#location)
  + [Structure](#structure)
  + [Arguments](#arguments)
  + [Context](#context)
* [Examples](#examples)
  + [Write a tool in Python](#write-a-tool-in-python)

## Custom Tools

Create tools the LLM can call in opencode.

Custom tools are functions you create that the LLM can call during conversations. They work alongside opencodeâs [built-in tools](/docs/tools) like `read`, `write`, and `bash`.

---

### [Creating a tool](#creating-a-tool)

Tools are defined as **TypeScript** or **JavaScript** files. However, the tool definition can invoke scripts written in **any language** â TypeScript or JavaScript is only used for the tool definition itself.

---

#### [Location](#location)

They can be defined:

* Locally by placing them in the `.opencode/tools/` directory of your project.
* Or globally, by placing them in `~/.config/opencode/tools/`.

---

#### [Structure](#structure)

The easiest way to create tools is using the `tool()` helper which provides type-safety and validation.

.opencode/tools/database.ts

```
import { tool } from "@opencode-ai/plugin"

export default tool({

description: "Query the project database",

args: {

query: tool.schema.string().describe("SQL query to execute"),

},

async execute(args) {

// Your database logic here

return `Executed query: ${args.query}`

},

})
```

The **filename** becomes the **tool name**. The above creates a `database` tool.

---

##### [Multiple tools per file](#multiple-tools-per-file)

You can also export multiple tools from a single file. Each export becomes **a separate tool** with the name **`<filename>_<exportname>`**:

.opencode/tools/math.ts

```
import { tool } from "@opencode-ai/plugin"

export const add = tool({

description: "Add two numbers",

args: {

a: tool.schema.number().describe("First number"),

b: tool.schema.number().describe("Second number"),

},

async execute(args) {

return (args.a + args.b).toString()

},

})

export const multiply = tool({

description: "Multiply two numbers",

args: {

a: tool.schema.number().describe("First number"),

b: tool.schema.number().describe("Second number"),

},

async execute(args) {

return (args.a * args.b).toString()

},

})
```

This creates two tools: `math_add` and `math_multiply`.

---

##### [Name collisions with built-in tools](#name-collisions-with-built-in-tools)

Custom tools are keyed by tool name. If a custom tool uses the same name as a built-in tool, the custom tool takes precedence.

For example, this file replaces the built-in `bash` tool:

.opencode/tools/bash.ts

```
import { tool } from "@opencode-ai/plugin"

export default tool({

description: "Restricted bash wrapper",

args: {

command: tool.schema.string(),

},

async execute(args) {

return `blocked: ${args.command}`

},

})
```

Note

Prefer unique names unless you intentionally want to replace a built-in tool. If you want to disable a built in tool but not override it, use [permissions](/docs/permissions).

---

#### [Arguments](#arguments)

You can use `tool.schema`, which is just [Zod](https://zod.dev), to define argument types.

```
args: {

query: tool.schema.string().describe("SQL query to execute")

}
```

You can also import [Zod](https://zod.dev) directly and return a plain object:

```
import { z } from "zod"

export default {

description: "Tool description",

args: {

param: z.string().describe("Parameter description"),

},

async execute(args, context) {

// Tool implementation

return "result"

},

}
```

---

#### [Context](#context)

Tools receive context about the current session:

.opencode/tools/project.ts

```
import { tool } from "@opencode-ai/plugin"

export default tool({

description: "Get project information",

args: {},

async execute(args, context) {

// Access context information

const { agent, sessionID, messageID, directory, worktree } = context

return `Agent: ${agent}, Session: ${sessionID}, Message: ${messageID}, Directory: ${directory}, Worktree: ${worktree}`

},

})
```

Use `context.directory` for the session working directory.
Use `context.worktree` for the git worktree root.

---

### [Examples](#examples)

#### [Write a tool in Python](#write-a-tool-in-python)

You can write your tools in any language you want. Hereâs an example that adds two numbers using Python.

First, create the tool as a Python script:

.opencode/tools/add.py

```
import sys

a = int(sys.argv[1])

b = int(sys.argv[2])

print(a + b)
```

Then create the tool definition that invokes it:

.opencode/tools/python-add.ts

```
import { tool } from "@opencode-ai/plugin"

import path from "path"

export default tool({

description: "Add two numbers using Python",

args: {

a: tool.schema.number().describe("First number"),

b: tool.schema.number().describe("Second number"),

},

async execute(args, context) {

const script = path.join(context.worktree, ".opencode/tools/add.py")

const result = await Bun.$`python3 ${script} ${args.a} ${args.b}`.text()

return result.trim()

},

})
```

Here we are using the [`Bun.$`](https://bun.com/docs/runtime/shell) utility to run the Python script.

[Edit page](https://github.com/anomalyco/opencode/edit/dev/packages/web/src/content/docs/custom-tools.mdx)[Found a bug? Open an issue](https://github.com/anomalyco/opencode/issues/new)[Join our Discord community](https://opencode.ai/discord)  Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

© [Anomaly](https://anoma.ly)

Last updated: Oct 13, 2026

---
<!--
URL: https://opencode.ai/docs/mcp-servers
title: MCP servers | OpenCode
-->

[Skip to content](#_top)

[![](/docs/_astro/logo-dark.DOStV66V.svg) ![](/docs/_astro/logo-light.B0yzR0O5.svg)  OpenCode](/docs/)

[app.header.home](/)[app.header.docs](/v2/docs)

Search  `CtrlK`

Cancel

  [New OpenCode v2 is now available →](https://opencode.ai/v2)

* [Intro](/docs/)
* [Config](/docs/config/)
* [Providers](/docs/providers/)
* [Network](/docs/network/)
* [Enterprise](/docs/enterprise/)
* [Troubleshooting](/docs/troubleshooting/)
* [Windows](/docs/windows-wsl)
* Usage

  + [Go](https://opencode.ai/v2/docs/console/go/)
  + [TUI](/docs/tui/)
  + [CLI](/docs/cli/)
  + [Web](/docs/web/)
  + [IDE](/docs/ide/)
  + [Console](https://opencode.ai/v2/docs/console/)
  + [Share](/docs/share/)
  + [GitHub](/docs/github/)
  + [GitLab](/docs/gitlab/)
* Configure

  + [Tools](/docs/tools/)
  + [Rules](/docs/rules/)
  + [Agents](/docs/agents/)
  + [Models](/docs/models/)
  + [Themes](/docs/themes/)
  + [Keybinds](/docs/keybinds/)
  + [Commands](/docs/commands/)
  + [Formatters](/docs/formatters/)
  + [Permissions](/docs/permissions/)
  + [Policies](/docs/policies/)
  + [LSP Servers](/docs/lsp/)
  + [MCP servers](/docs/mcp-servers/)
  + [ACP Support](/docs/acp/)
  + [Agent Skills](/docs/skills/)
  + [References](/docs/references/)
  + [Custom Tools](/docs/custom-tools/)
* Develop

  + [SDK](/docs/sdk/)
  + [Server](/docs/server/)
  + [Plugins](/docs/plugins/)
  + [Ecosystem](/docs/ecosystem/)

[GitHub](https://github.com/anomalyco/opencode)[Discord](https://opencode.ai/discord)

  Select theme   DarkLightAuto         Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

On this page

* [Overview](#_top)
* [Enable](#enable)
  + [Overriding remote defaults](#overriding-remote-defaults)
* [Local](#local)
* [Remote](#remote)
* [OAuth](#oauth)
  + [Automatic](#automatic)
  + [Pre-registered](#pre-registered)
  + [Authenticating](#authenticating)
* [Manage](#manage)
  + [Global](#global)
  + [Per agent](#per-agent)
* [Examples](#examples)
  + [Sentry](#sentry)
  + [Context7](#context7)
  + [Grep by Vercel](#grep-by-vercel)

### On this page

* [Overview](#_top)
* [Enable](#enable)
  + [Overriding remote defaults](#overriding-remote-defaults)
* [Local](#local)
* [Remote](#remote)
* [OAuth](#oauth)
  + [Automatic](#automatic)
  + [Pre-registered](#pre-registered)
  + [Authenticating](#authenticating)
* [Manage](#manage)
  + [Global](#global)
  + [Per agent](#per-agent)
* [Examples](#examples)
  + [Sentry](#sentry)
  + [Context7](#context7)
  + [Grep by Vercel](#grep-by-vercel)

## MCP servers

Add local and remote MCP tools.

You can add external tools to OpenCode using the *Model Context Protocol*, or MCP. OpenCode supports both local and remote servers.

Once added, MCP tools are automatically available to the LLM alongside built-in tools.

---

##### [Caveats](#caveats)

When you use an MCP server, it adds to the context. This can quickly add up if you have a lot of tools. So we recommend being careful with which MCP servers you use.

Tip

MCP servers add to your context, so you want to be careful with which ones you enable.

Certain MCP servers, like the GitHub MCP server, tend to add a lot of tokens and can easily exceed the context limit.

---

### [Enable](#enable)

You can define MCP servers in your [OpenCode Config](https://opencode.ai/docs/config/) under `mcp`. Add each MCP with a unique name. You can refer to that MCP by name when prompting the LLM.

opencode.jsonc

```
{

"$schema": "https://opencode.ai/config.json",

"mcp": {

"name-of-mcp-server": {

// ...

"enabled": true,

},

"name-of-other-mcp-server": {

// ...

},

},

}
```

You can also disable a server by setting `enabled` to `false`. This is useful if you want to temporarily disable a server without removing it from your config.

---

#### [Overriding remote defaults](#overriding-remote-defaults)

Organizations can provide default MCP servers via their `.well-known/opencode` endpoint. These servers may be disabled by default, allowing users to opt-in to the ones they need.

To enable a specific server from your organizationâs remote config, add it to your local config with `enabled: true`:

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"mcp": {

"jira": {

"type": "remote",

"url": "https://jira.example.com/mcp",

"enabled": true

}

}

}
```

Your local config values override the remote defaults. See [config precedence](/docs/config#precedence-order) for more details.

---

### [Local](#local)

Add local MCP servers using `type` to `"local"` within the MCP object.

opencode.jsonc

```
{

"$schema": "https://opencode.ai/config.json",

"mcp": {

"my-local-mcp-server": {

"type": "local",

// Or ["bun", "x", "my-mcp-command"]

"command": ["npx", "-y", "my-mcp-command"],

"enabled": true,

"environment": {

"MY_ENV_VAR": "my_env_var_value",

},

},

},

}
```

The command is how the local MCP server is started. You can also pass in a list of environment variables as well.

For example, hereâs how you can add the test [`@modelcontextprotocol/server-everything`](https://www.npmjs.com/package/%40modelcontextprotocol/server-everything) MCP server.

opencode.jsonc

```
{

"$schema": "https://opencode.ai/config.json",

"mcp": {

"mcp_everything": {

"type": "local",

"command": ["npx", "-y", "@modelcontextprotocol/server-everything"],

},

},

}
```

And to use it I can add `use the mcp_everything tool` to my prompts.

```
use the mcp_everything tool to add the number 3 and 4
```

---

##### [Options](#options)

Here are all the options for configuring a local MCP server.

| Option | Type | Required | Description |
| --- | --- | --- | --- |
| `type` | String | Y | Type of MCP server connection, must be `"local"`. |
| `command` | Array | Y | Command and arguments to run the MCP server. |
| `cwd` | String |  | Working directory for the MCP server process. Relative paths resolve from the workspace. |
| `environment` | Object |  | Environment variables to set when running the server. |
| `enabled` | Boolean |  | Enable or disable the MCP server on startup. |
| `timeout` | Number |  | Timeout in ms for fetching tools from the MCP server. Defaults to 5000 (5 seconds). |

---

### [Remote](#remote)

Add remote MCP servers by setting `type` to `"remote"`.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"mcp": {

"my-remote-mcp": {

"type": "remote",

"url": "https://my-mcp-server.com",

"enabled": true,

"headers": {

"Authorization": "Bearer MY_API_KEY"

}

}

}

}
```

The `url` is the URL of the remote MCP server and with the `headers` option you can pass in a list of headers.

---

##### [Options](#options-1)

| Option | Type | Required | Description |
| --- | --- | --- | --- |
| `type` | String | Y | Type of MCP server connection, must be `"remote"`. |
| `url` | String | Y | URL of the remote MCP server. |
| `enabled` | Boolean |  | Enable or disable the MCP server on startup. |
| `headers` | Object |  | Headers to send with the request. |
| `oauth` | Object |  | OAuth authentication configuration. See [OAuth](#oauth) section below. |
| `timeout` | Number |  | Timeout in ms for fetching tools from the MCP server. Defaults to 5000 (5 seconds). |

---

### [OAuth](#oauth)

OpenCode automatically handles OAuth authentication for remote MCP servers. When a server requires authentication, OpenCode will:

1. Detect the 401 response and initiate the OAuth flow
2. Use **Dynamic Client Registration (RFC 7591)** if supported by the server
3. Store tokens securely for future requests

---

#### [Automatic](#automatic)

For most OAuth-enabled MCP servers, no special configuration is needed. Just configure the remote server:

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"mcp": {

"my-oauth-server": {

"type": "remote",

"url": "https://mcp.example.com/mcp"

}

}

}
```

If the server requires authentication, OpenCode will prompt you to authenticate when you first try to use it. If not, you can [manually trigger the flow](#authenticating) with `opencode mcp auth <server-name>`.

---

#### [Pre-registered](#pre-registered)

If you have client credentials from the MCP server provider, you can configure them:

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"mcp": {

"my-oauth-server": {

"type": "remote",

"url": "https://mcp.example.com/mcp",

"oauth": {

"clientId": "{env:MY_MCP_CLIENT_ID}",

"clientSecret": "{env:MY_MCP_CLIENT_SECRET}",

"scope": "tools:read tools:execute"

}

}

}

}
```

---

#### [Authenticating](#authenticating)

You can manually trigger authentication or manage credentials.

Authenticate with a specific MCP server:

Terminal window

```
opencode mcp auth my-oauth-server
```

List all MCP servers and their auth status:

Terminal window

```
opencode mcp list
```

Remove stored credentials:

Terminal window

```
opencode mcp logout my-oauth-server
```

The `mcp auth` command will open your browser for authorization. After you authorize, OpenCode will store the tokens securely in `~/.local/share/opencode/mcp-auth.json`.

---

##### [Disabling OAuth](#disabling-oauth)

If you want to disable automatic OAuth for a server (e.g., for servers that use API keys instead), set `oauth` to `false`:

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"mcp": {

"my-api-key-server": {

"type": "remote",

"url": "https://mcp.example.com/mcp",

"oauth": false,

"headers": {

"Authorization": "Bearer {env:MY_API_KEY}"

}

}

}

}
```

---

##### [OAuth Options](#oauth-options)

| Option | Type | Description |
| --- | --- | --- |
| `oauth` | Object | false | OAuth config object, or `false` to disable OAuth auto-detection. |
| `clientId` | String | OAuth client ID. If not provided, dynamic client registration will be attempted. |
| `clientSecret` | String | OAuth client secret, if required by the authorization server. |
| `scope` | String | OAuth scopes to request during authorization. |

##### [Debugging](#debugging)

If a remote MCP server is failing to authenticate, you can diagnose issues with:

Terminal window

```

## View auth status for all OAuth-capable servers

opencode mcp auth list

## Debug connection and OAuth flow for a specific server

opencode mcp debug my-oauth-server
```

The `mcp debug` command shows the current auth status, tests HTTP connectivity, and attempts the OAuth discovery flow.

---

### [Manage](#manage)

Tools from your MCP servers are available in OpenCode alongside built-in tools. You can manage them through the OpenCode config like any other tool.

---

#### [Global](#global)

This means that you can enable or disable them globally.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"mcp": {

"my-mcp-foo": {

"type": "local",

"command": ["bun", "x", "my-mcp-command-foo"]

},

"my-mcp-bar": {

"type": "local",

"command": ["bun", "x", "my-mcp-command-bar"]

}

},

"tools": {

"my-mcp-foo": false

}

}
```

We can also use a glob pattern to disable all matching MCP tools.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"mcp": {

"my-mcp-foo": {

"type": "local",

"command": ["bun", "x", "my-mcp-command-foo"]

},

"my-mcp-bar": {

"type": "local",

"command": ["bun", "x", "my-mcp-command-bar"]

}

},

"tools": {

"my-mcp*": false

}

}
```

Here we are using the glob pattern `my-mcp*` to disable all matching MCP tools.

---

#### [Per agent](#per-agent)

If you have a large number of MCP servers you may want to only enable them per agent and disable them globally. To do this:

1. Disable it as a tool globally.
2. In your [agent config](/docs/agents#tools), enable the MCP server as a tool.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"mcp": {

"my-mcp": {

"type": "local",

"command": ["bun", "x", "my-mcp-command"],

"enabled": true

}

},

"tools": {

"my-mcp*": false

},

"agent": {

"my-agent": {

"tools": {

"my-mcp*": true

}

}

}

}
```

---

##### [Glob patterns](#glob-patterns)

The glob pattern uses simple regex globbing patterns:

* `*` matches zero or more of any character (e.g., `"my-mcp*"` matches `my-mcp_search`, `my-mcp_list`, etc.)
* `?` matches exactly one character
* All other characters match literally

Note

MCP server tools are registered with server name as prefix, so to disable all tools for a server simply use:

```
"mymcpservername_*": false
```

---

### [Examples](#examples)

Below are examples of some common MCP servers. You can submit a PR if you want to document other servers.

---

#### [Sentry](#sentry)

Add the [Sentry MCP server](https://mcp.sentry.dev) to interact with your Sentry projects and issues.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"mcp": {

"sentry": {

"type": "remote",

"url": "https://mcp.sentry.dev/mcp",

"oauth": {}

}

}

}
```

After adding the configuration, authenticate with Sentry:

Terminal window

```
opencode mcp auth sentry
```

This will open a browser window to complete the OAuth flow and connect OpenCode to your Sentry account.

Once authenticated, you can use Sentry tools in your prompts to query issues, projects, and error data.

```
Show me the latest unresolved issues in my project. use sentry
```

---

#### [Context7](#context7)

Add the [Context7 MCP server](https://github.com/upstash/context7) to search through docs.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"mcp": {

"context7": {

"type": "remote",

"url": "https://mcp.context7.com/mcp"

}

}

}
```

If you have signed up for a free account, you can use your API key and get higher rate-limits.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"mcp": {

"context7": {

"type": "remote",

"url": "https://mcp.context7.com/mcp",

"headers": {

"CONTEXT7_API_KEY": "{env:CONTEXT7_API_KEY}"

}

}

}

}
```

Here we are assuming that you have the `CONTEXT7_API_KEY` environment variable set.

Add `use context7` to your prompts to use Context7 MCP server.

```
Configure a Cloudflare Worker script to cache JSON API responses for five minutes. use context7
```

Alternatively, you can add something like this to your [AGENTS.md](/docs/rules/).

AGENTS.md

```
When you need to search docs, use `context7` tools.
```

---

#### [Grep by Vercel](#grep-by-vercel)

Add the [Grep by Vercel](https://grep.app) MCP server to search through code snippets on GitHub.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"mcp": {

"gh_grep": {

"type": "remote",

"url": "https://mcp.grep.app"

}

}

}
```

Since we named our MCP server `gh_grep`, you can add `use the gh_grep tool` to your prompts to get the agent to use it.

```
What's the right way to set a custom domain in an SST Astro component? use the gh_grep tool
```

Alternatively, you can add something like this to your [AGENTS.md](/docs/rules/).

AGENTS.md

```
If you are unsure how to do something, use `gh_grep` to search code examples from GitHub.
```

[Edit page](https://github.com/anomalyco/opencode/edit/dev/packages/web/src/content/docs/mcp-servers.mdx)[Found a bug? Open an issue](https://github.com/anomalyco/opencode/issues/new)[Join our Discord community](https://opencode.ai/discord)  Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

© [Anomaly](https://anoma.ly)

Last updated: Oct 13, 2026

---
<!--
URL: https://opencode.ai/docs/permissions
title: Permissions | OpenCode
-->

[Skip to content](#_top)

[![](/docs/_astro/logo-dark.DOStV66V.svg) ![](/docs/_astro/logo-light.B0yzR0O5.svg)  OpenCode](/docs/)

[app.header.home](/)[app.header.docs](/v2/docs)

Search  `CtrlK`

Cancel

  [New OpenCode v2 is now available →](https://opencode.ai/v2)

* [Intro](/docs/)
* [Config](/docs/config/)
* [Providers](/docs/providers/)
* [Network](/docs/network/)
* [Enterprise](/docs/enterprise/)
* [Troubleshooting](/docs/troubleshooting/)
* [Windows](/docs/windows-wsl)
* Usage

  + [Go](https://opencode.ai/v2/docs/console/go/)
  + [TUI](/docs/tui/)
  + [CLI](/docs/cli/)
  + [Web](/docs/web/)
  + [IDE](/docs/ide/)
  + [Console](https://opencode.ai/v2/docs/console/)
  + [Share](/docs/share/)
  + [GitHub](/docs/github/)
  + [GitLab](/docs/gitlab/)
* Configure

  + [Tools](/docs/tools/)
  + [Rules](/docs/rules/)
  + [Agents](/docs/agents/)
  + [Models](/docs/models/)
  + [Themes](/docs/themes/)
  + [Keybinds](/docs/keybinds/)
  + [Commands](/docs/commands/)
  + [Formatters](/docs/formatters/)
  + [Permissions](/docs/permissions/)
  + [Policies](/docs/policies/)
  + [LSP Servers](/docs/lsp/)
  + [MCP servers](/docs/mcp-servers/)
  + [ACP Support](/docs/acp/)
  + [Agent Skills](/docs/skills/)
  + [References](/docs/references/)
  + [Custom Tools](/docs/custom-tools/)
* Develop

  + [SDK](/docs/sdk/)
  + [Server](/docs/server/)
  + [Plugins](/docs/plugins/)
  + [Ecosystem](/docs/ecosystem/)

[GitHub](https://github.com/anomalyco/opencode)[Discord](https://opencode.ai/discord)

  Select theme   DarkLightAuto         Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

On this page

* [Overview](#_top)
* [Actions](#actions)
* [Auto mode](#auto-mode)
* [Configuration](#configuration)
* [Granular Rules (Object Syntax)](#granular-rules-object-syntax)
  + [Wildcards](#wildcards)
  + [Home Directory Expansion](#home-directory-expansion)
  + [External Directories](#external-directories)
* [Available Permissions](#available-permissions)
* [Defaults](#defaults)
* [What âAskâ Does](#what-ask-does)
* [Agents](#agents)

### On this page

* [Overview](#_top)
* [Actions](#actions)
* [Auto mode](#auto-mode)
* [Configuration](#configuration)
* [Granular Rules (Object Syntax)](#granular-rules-object-syntax)
  + [Wildcards](#wildcards)
  + [Home Directory Expansion](#home-directory-expansion)
  + [External Directories](#external-directories)
* [Available Permissions](#available-permissions)
* [Defaults](#defaults)
* [What âAskâ Does](#what-ask-does)
* [Agents](#agents)

## Permissions

Control which actions require approval to run.

OpenCode uses the `permission` config to decide whether a given action should run automatically, prompt you, or be blocked.

As of `v1.1.1`, the legacy `tools` boolean config is deprecated and has been merged into `permission`. The old `tools` config is still supported for backwards compatibility.

---

### [Actions](#actions)

Each permission rule resolves to one of:

* `"allow"` â run without approval
* `"ask"` â prompt for approval
* `"deny"` â block the action

---

### [Auto mode](#auto-mode)

Start OpenCode with `--auto` to automatically approve permission requests that are not explicitly denied.

Terminal window

```
opencode --auto
```

You can also use auto mode with [`opencode run`](/docs/cli#run).

Terminal window

```
opencode run --auto "Refactor this module"
```

Explicit `"deny"` rules are still enforced. Auto mode only changes requests that would otherwise ask for approval.

In the TUI, open the command palette and select **Enable auto-approve permissions** or **Disable auto-approve permissions** to change modes. When auto mode is active, the prompt displays a muted `auto` indicator next to the current agent.

---

### [Configuration](#configuration)

You can set permissions globally (with `*`), and override specific tools.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"permission": {

"*": "ask",

"bash": "allow",

"edit": "deny"

}

}
```

You can also set all permissions at once:

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"permission": "allow"

}
```

---

### [Granular Rules (Object Syntax)](#granular-rules-object-syntax)

For most permissions, you can use an object to apply different actions based on the tool input.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"permission": {

"bash": {

"*": "ask",

"git *": "allow",

"npm *": "allow",

"rm *": "deny",

"grep *": "allow"

},

"edit": {

"*": "deny",

"packages/web/src/content/docs/*.mdx": "allow"

},

"webfetch": {

"*": "ask",

"https://en.wikipedia.org/*": "allow"

}

}

}
```

Rules are evaluated by pattern match, with the **last matching rule winning**. A common pattern is to put the catch-all `"*"` rule first, and more specific rules after it.

#### [Wildcards](#wildcards)

Permission patterns use simple wildcard matching:

* `*` matches zero or more of any character
* `?` matches exactly one character
* All other characters match literally

#### [Home Directory Expansion](#home-directory-expansion)

You can use `~` or `$HOME` at the start of a pattern to reference your home directory. This is particularly useful for [`external_directory`](#external-directories) rules.

* `~/projects/*` -> `/Users/username/projects/*`
* `$HOME/projects/*` -> `/Users/username/projects/*`
* `~` -> `/Users/username`

#### [External Directories](#external-directories)

Use `external_directory` to allow tool calls that touch paths outside the working directory where OpenCode was started. This applies to any tool that takes a path as input (for example `read`, `edit`, `glob`, `grep`, and many `bash` commands).

Home expansion (like `~/...`) only affects how a pattern is written. It does not make an external path part of the current workspace, so paths outside the working directory must still be allowed via `external_directory`.

For example, this allows access to everything under `~/projects/personal/`:

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"permission": {

"external_directory": {

"~/projects/personal/**": "allow"

}

}

}
```

Any directory allowed here inherits the same defaults as the current workspace. Since [`read` defaults to `allow`](#defaults), reads are also allowed for entries under `external_directory` unless overridden. Add explicit rules when a tool should be restricted in these paths, such as blocking edits while keeping reads:

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"permission": {

"external_directory": {

"~/projects/personal/**": "allow"

},

"edit": {

"~/projects/personal/**": "deny"

}

}

}
```

Keep the list focused on trusted paths, and layer extra allow or deny rules as needed for other tools (for example `bash`).

---

### [Available Permissions](#available-permissions)

OpenCode permissions are keyed by tool name, plus a couple of safety guards:

* `read` â reading a file (matches the file path)
* `edit` â all file modifications (covers `edit`, `write`, `patch`)
* `glob` â file globbing (matches the glob pattern)
* `grep` â content search (matches the regex pattern)
* `bash` â running shell commands (matches parsed commands like `git status --porcelain`)
* `task` â launching subagents (matches the subagent type)
* `skill` â loading a skill (matches the skill name)
* `lsp` â running LSP queries (currently non-granular)
* `question` â asking the user questions during execution
* `webfetch` â fetching a URL (matches the URL)
* `websearch` â web search
* `external_directory` â triggered when a tool touches paths outside the project working directory
* `doom_loop` â triggered when the same tool call repeats 3 times with identical input

---

### [Defaults](#defaults)

If you donât specify anything, OpenCode starts from permissive defaults:

* Most permissions default to `"allow"`.
* `doom_loop` and `external_directory` default to `"ask"`.
* `read` is `"allow"`, but `.env` files are denied by default:

opencode.json

```
{

"permission": {

"read": {

"*": "allow",

"*.env": "deny",

"*.env.*": "deny",

"*.env.example": "allow"

}

}

}
```

---

### [What âAskâ Does](#what-ask-does)

When OpenCode prompts for approval, the UI offers three outcomes:

* `once` â approve just this request
* `always` â approve future requests matching the suggested patterns (for the rest of the current OpenCode session)
* `reject` â deny the request

The set of patterns that `always` would approve is provided by the tool (for example, bash approvals typically whitelist a safe command prefix like `git status*`).

---

### [Agents](#agents)

You can override permissions per agent. Agent permissions are merged with the global config, and agent rules take precedence. [Learn more](/docs/agents#permissions) about agent permissions.

Note

Refer to the [Granular Rules (Object Syntax)](#granular-rules-object-syntax) section above for more detailed pattern matching examples.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"permission": {

"bash": {

"*": "ask",

"git *": "allow",

"git commit *": "deny",

"git push *": "deny",

"grep *": "allow"

}

},

"agent": {

"build": {

"permission": {

"bash": {

"*": "ask",

"git *": "allow",

"git commit *": "ask",

"git push *": "deny",

"grep *": "allow"

}

}

}

}

}
```

You can also configure agent permissions in Markdown:

~/.config/opencode/agents/review.md

```
---

description: Code review without edits

mode: subagent

permission:

edit: deny

bash: ask

webfetch: deny

---

Only analyze code and suggest changes.
```

Tip

Use pattern matching for commands with arguments. `"grep *"` allows `grep pattern file.txt`, while `"grep"` alone would block it. Commands like `git status` work for default behavior but require explicit permission (like `"git status *"`) when arguments are passed.

[Edit page](https://github.com/anomalyco/opencode/edit/dev/packages/web/src/content/docs/permissions.mdx)[Found a bug? Open an issue](https://github.com/anomalyco/opencode/issues/new)[Join our Discord community](https://opencode.ai/discord)  Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

© [Anomaly](https://anoma.ly)

Last updated: Oct 13, 2026

---
<!--
URL: https://opencode.ai/docs/lsp
title: LSP Servers | OpenCode
-->

[Skip to content](#_top)

[![](/docs/_astro/logo-dark.DOStV66V.svg) ![](/docs/_astro/logo-light.B0yzR0O5.svg)  OpenCode](/docs/)

[app.header.home](/)[app.header.docs](/v2/docs)

Search  `CtrlK`

Cancel

  [New OpenCode v2 is now available →](https://opencode.ai/v2)

* [Intro](/docs/)
* [Config](/docs/config/)
* [Providers](/docs/providers/)
* [Network](/docs/network/)
* [Enterprise](/docs/enterprise/)
* [Troubleshooting](/docs/troubleshooting/)
* [Windows](/docs/windows-wsl)
* Usage

  + [Go](https://opencode.ai/v2/docs/console/go/)
  + [TUI](/docs/tui/)
  + [CLI](/docs/cli/)
  + [Web](/docs/web/)
  + [IDE](/docs/ide/)
  + [Console](https://opencode.ai/v2/docs/console/)
  + [Share](/docs/share/)
  + [GitHub](/docs/github/)
  + [GitLab](/docs/gitlab/)
* Configure

  + [Tools](/docs/tools/)
  + [Rules](/docs/rules/)
  + [Agents](/docs/agents/)
  + [Models](/docs/models/)
  + [Themes](/docs/themes/)
  + [Keybinds](/docs/keybinds/)
  + [Commands](/docs/commands/)
  + [Formatters](/docs/formatters/)
  + [Permissions](/docs/permissions/)
  + [Policies](/docs/policies/)
  + [LSP Servers](/docs/lsp/)
  + [MCP servers](/docs/mcp-servers/)
  + [ACP Support](/docs/acp/)
  + [Agent Skills](/docs/skills/)
  + [References](/docs/references/)
  + [Custom Tools](/docs/custom-tools/)
* Develop

  + [SDK](/docs/sdk/)
  + [Server](/docs/server/)
  + [Plugins](/docs/plugins/)
  + [Ecosystem](/docs/ecosystem/)

[GitHub](https://github.com/anomalyco/opencode)[Discord](https://opencode.ai/discord)

  Select theme   DarkLightAuto         Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

On this page

* [Overview](#_top)
* [Built-in](#built-in)
* [How It Works](#how-it-works)
* [Best Practices](#best-practices)
* [Configure](#configure)
  + [Environment variables](#environment-variables)
  + [Initialization options](#initialization-options)
  + [Disabling LSP servers](#disabling-lsp-servers)
  + [Custom LSP servers](#custom-lsp-servers)
* [Additional Information](#additional-information)
  + [PHP Intelephense](#php-intelephense)

### On this page

* [Overview](#_top)
* [Built-in](#built-in)
* [How It Works](#how-it-works)
* [Best Practices](#best-practices)
* [Configure](#configure)
  + [Environment variables](#environment-variables)
  + [Initialization options](#initialization-options)
  + [Disabling LSP servers](#disabling-lsp-servers)
  + [Custom LSP servers](#custom-lsp-servers)
* [Additional Information](#additional-information)
  + [PHP Intelephense](#php-intelephense)

## LSP Servers

OpenCode integrates with your LSP servers.

OpenCode can integrate with Language Server Protocol (LSP) servers to use diagnostics as feedback for the agent.

---

### [Built-in](#built-in)

OpenCode comes with several built-in LSP servers for popular languages:

| LSP Server | Extensions | Requirements |
| --- | --- | --- |
| astro | .astro | Auto-installs for Astro projects |
| bash | .sh, .bash, .zsh, .ksh | Auto-installs bash-language-server |
| clangd | .c, .cpp, .cc, .cxx, .c++, .h, .hpp, .hh, .hxx, .h++ | Auto-installs for C/C++ projects |
| csharp | .cs, .csx | `.NET SDK` installed |
| clojure-lsp | .clj, .cljs, .cljc, .edn | `clojure-lsp` command available |
| dart | .dart | `dart` command available |
| deno | .ts, .tsx, .js, .jsx, .mjs | `deno` command available (auto-detects deno.json/deno.jsonc) |
| elixir-ls | .ex, .exs | `elixir` command available |
| eslint | .ts, .tsx, .js, .jsx, .mjs, .cjs, .mts, .cts, .vue | `eslint` dependency in project |
| fsharp | .fs, .fsi, .fsx, .fsscript | `.NET SDK` installed |
| gleam | .gleam | `gleam` command available |
| gopls | .go | `go` command available |
| hls | .hs, .lhs | `haskell-language-server-wrapper` command available |
| jdtls | .java | `Java SDK (version 21+)` installed |
| julials | .jl | `julia` and `LanguageServer.jl` installed |
| kotlin-ls | .kt, .kts | Auto-installs for Kotlin projects |
| lua-ls | .lua | Auto-installs for Lua projects |
| nixd | .nix | `nixd` command available |
| ocaml-lsp | .ml, .mli | `ocamllsp` command available |
| oxlint | .ts, .tsx, .js, .jsx, .mjs, .cjs, .mts, .cts, .vue, .astro, .svelte | `oxlint` dependency in project |
| php intelephense | .php | Auto-installs for PHP projects |
| prisma | .prisma | `prisma` command available |
| pyright | .py, .pyi | `pyright` dependency installed |
| razor | .razor, .cshtml | `.NET SDK` and VS Code C# extension installed |
| ruby-lsp (rubocop) | .rb, .rake, .gemspec, .ru | `ruby` and `gem` commands available |
| rust | .rs | `rust-analyzer` command available |
| sourcekit-lsp | .swift, .objc, .objcpp | `swift` installed (`xcode` on macOS) |
| svelte | .svelte | Auto-installs for Svelte projects |
| terraform | .tf, .tfvars | Auto-installs from GitHub releases |
| tinymist | .typ, .typc | Auto-installs from GitHub releases |
| typescript | .ts, .tsx, .js, .jsx, .mjs, .cjs, .mts, .cts | `typescript` dependency in project |
| vue | .vue | Auto-installs for Vue projects |
| yaml-ls | .yaml, .yml | Auto-installs Red Hat yaml-language-server |
| zls | .zig, .zon | `zig` command available |

LSP is disabled by default. When enabled, servers start when one of the above file extensions is detected and the requirements are met.

Note

You can disable automatic LSP server downloads by setting the `OPENCODE_DISABLE_LSP_DOWNLOAD` environment variable to `true`.

---

### [How It Works](#how-it-works)

When LSP is enabled and opencode opens a file, it:

1. Checks the file extension against all enabled LSP servers.
2. Starts the appropriate LSP server if not already running.

---

### [Best Practices](#best-practices)

LSP can help the agent find and fix issues by providing diagnostics from language servers. This is useful in some projects, but it is not always a net positive.

Language servers can get out of sync, use significant memory, vary by version or project, and slow down agent workflows. In many projects it is better to have the agent run lint, typecheck, or other diagnostic CLI tools directly, so errors are fed back into the agent loop without those tradeoffs. Document those commands in instruction files such as `AGENTS.md` or skills so the agent knows what to run. Enable LSP when your project benefits from additional language-server feedback.

---

### [Configure](#configure)

You can enable and customize LSP servers through the `lsp` section in your opencode config.

To enable all built-in LSP servers, set `lsp` to `true`.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"lsp": true

}
```

Use an object to keep built-ins enabled while configuring overrides or custom servers.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"lsp": {}

}
```

Each configured LSP server entry supports the following:

Server entries need `command` unless they only disable a server.

| Property | Type | Description |
| --- | --- | --- |
| `disabled` | boolean | Set this to `true` to disable the LSP server |
| `command` | string[] | The command to start the LSP server |
| `extensions` | string[] | File extensions this LSP server should handle |
| `env` | object | Environment variables to set when starting server |
| `initialization` | object | Initialization options to send to the LSP server |

Letâs look at some examples.

---

#### [Environment variables](#environment-variables)

Use the `env` property to set environment variables when starting the LSP server:

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"lsp": {

"rust": {

"command": ["rust-analyzer"],

"env": {

"RUST_LOG": "debug"

}

}

}

}
```

---

#### [Initialization options](#initialization-options)

Use the `initialization` property to pass initialization options to the LSP server. These are server-specific settings sent during the LSP `initialize` request:

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"lsp": {

"custom-lsp": {

"command": ["custom-lsp-server", "--stdio"],

"extensions": [".custom"],

"initialization": {

"preferences": {

"importModuleSpecifierPreference": "relative"

}

}

}

}

}
```

Note

Initialization options vary by LSP server. Check your LSP serverâs documentation for available options.

---

#### [Disabling LSP servers](#disabling-lsp-servers)

If `lsp` is omitted, all LSP servers are disabled. To disable all LSP servers after another config enabled them, set `lsp` to `false`:

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"lsp": false

}
```

To disable a **specific** LSP server, set `disabled` to `true`:

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"lsp": {

"typescript": {

"disabled": true

}

}

}
```

---

#### [Custom LSP servers](#custom-lsp-servers)

You can add custom LSP servers by specifying the command and file extensions:

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"lsp": {

"custom-lsp": {

"command": ["custom-lsp-server", "--stdio"],

"extensions": [".custom"]

}

}

}
```

---

### [Additional Information](#additional-information)

#### [PHP Intelephense](#php-intelephense)

PHP Intelephense offers premium features through a license key. You can provide a license key by placing (only) the key in a text file at:

* On macOS/Linux: `$HOME/intelephense/license.txt`
* On Windows: `%USERPROFILE%/intelephense/license.txt`

The file should contain only the license key with no additional content.

[Edit page](https://github.com/anomalyco/opencode/edit/dev/packages/web/src/content/docs/lsp.mdx)[Found a bug? Open an issue](https://github.com/anomalyco/opencode/issues/new)[Join our Discord community](https://opencode.ai/discord)  Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

© [Anomaly](https://anoma.ly)

Last updated: Oct 13, 2026

---
<!--
URL: https://opencode.ai/docs/skills
title: Agent Skills | OpenCode
-->

[Skip to content](#_top)

[![](/docs/_astro/logo-dark.DOStV66V.svg) ![](/docs/_astro/logo-light.B0yzR0O5.svg)  OpenCode](/docs/)

[app.header.home](/)[app.header.docs](/v2/docs)

Search  `CtrlK`

Cancel

  [New OpenCode v2 is now available →](https://opencode.ai/v2)

* [Intro](/docs/)
* [Config](/docs/config/)
* [Providers](/docs/providers/)
* [Network](/docs/network/)
* [Enterprise](/docs/enterprise/)
* [Troubleshooting](/docs/troubleshooting/)
* [Windows](/docs/windows-wsl)
* Usage

  + [Go](https://opencode.ai/v2/docs/console/go/)
  + [TUI](/docs/tui/)
  + [CLI](/docs/cli/)
  + [Web](/docs/web/)
  + [IDE](/docs/ide/)
  + [Console](https://opencode.ai/v2/docs/console/)
  + [Share](/docs/share/)
  + [GitHub](/docs/github/)
  + [GitLab](/docs/gitlab/)
* Configure

  + [Tools](/docs/tools/)
  + [Rules](/docs/rules/)
  + [Agents](/docs/agents/)
  + [Models](/docs/models/)
  + [Themes](/docs/themes/)
  + [Keybinds](/docs/keybinds/)
  + [Commands](/docs/commands/)
  + [Formatters](/docs/formatters/)
  + [Permissions](/docs/permissions/)
  + [Policies](/docs/policies/)
  + [LSP Servers](/docs/lsp/)
  + [MCP servers](/docs/mcp-servers/)
  + [ACP Support](/docs/acp/)
  + [Agent Skills](/docs/skills/)
  + [References](/docs/references/)
  + [Custom Tools](/docs/custom-tools/)
* Develop

  + [SDK](/docs/sdk/)
  + [Server](/docs/server/)
  + [Plugins](/docs/plugins/)
  + [Ecosystem](/docs/ecosystem/)

[GitHub](https://github.com/anomalyco/opencode)[Discord](https://opencode.ai/discord)

  Select theme   DarkLightAuto         Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

On this page

* [Overview](#_top)
* [Place files](#place-files)
* [Understand discovery](#understand-discovery)
* [Write frontmatter](#write-frontmatter)
* [Validate names](#validate-names)
* [Follow length rules](#follow-length-rules)
* [Use an example](#use-an-example)
* [Recognize tool description](#recognize-tool-description)
* [Configure permissions](#configure-permissions)
* [Override per agent](#override-per-agent)
* [Disable the skill tool](#disable-the-skill-tool)
* [Troubleshoot loading](#troubleshoot-loading)

### On this page

* [Overview](#_top)
* [Place files](#place-files)
* [Understand discovery](#understand-discovery)
* [Write frontmatter](#write-frontmatter)
* [Validate names](#validate-names)
* [Follow length rules](#follow-length-rules)
* [Use an example](#use-an-example)
* [Recognize tool description](#recognize-tool-description)
* [Configure permissions](#configure-permissions)
* [Override per agent](#override-per-agent)
* [Disable the skill tool](#disable-the-skill-tool)
* [Troubleshoot loading](#troubleshoot-loading)

## Agent Skills

Define reusable behavior via SKILL.md definitions

Agent skills let OpenCode discover reusable instructions from your repo or home directory.
Skills are loaded on-demand via the native `skill` toolâagents see available skills and can load the full content when needed.

---

### [Place files](#place-files)

Create one folder per skill name and put a `SKILL.md` inside it.
OpenCode searches these locations:

* Project config: `.opencode/skills/<name>/SKILL.md`
* Global config: `~/.config/opencode/skills/<name>/SKILL.md`
* Project Claude-compatible: `.claude/skills/<name>/SKILL.md`
* Global Claude-compatible: `~/.claude/skills/<name>/SKILL.md`
* Project agent-compatible: `.agents/skills/<name>/SKILL.md`
* Global agent-compatible: `~/.agents/skills/<name>/SKILL.md`

---

### [Understand discovery](#understand-discovery)

For project-local paths, OpenCode walks up from your current working directory until it reaches the git worktree.
It loads any matching `skills/*/SKILL.md` in `.opencode/` and any matching `.claude/skills/*/SKILL.md` or `.agents/skills/*/SKILL.md` along the way.

Global definitions are also loaded from `~/.config/opencode/skills/*/SKILL.md`, `~/.claude/skills/*/SKILL.md`, and `~/.agents/skills/*/SKILL.md`.

---

### [Write frontmatter](#write-frontmatter)

Each `SKILL.md` must start with YAML frontmatter.
Use these Agent Skills fields:

* `name` (required)
* `description` (required)
* `license` (optional)
* `compatibility` (optional)
* `metadata` (optional, string-to-string map)

Put OpenCode-specific behavior in `metadata` instead of adding custom top-level fields.

OpenCode recognizes these optional `metadata` keys:

* `opencode/slash`: set to `"true"` to expose the skill as a `/name` command in the TUI
* `opencode/autoinvoke`: set to `"false"` to keep the skill out of model-facing auto-selection guidance

The Agent Skills spec defines `metadata` values as strings, so quoted values are the portable form.
OpenCode also accepts YAML booleans like `opencode/slash: true` and `opencode/autoinvoke: false`.

---

### [Validate names](#validate-names)

`name` must:

* Be 1â64 characters
* Be lowercase alphanumeric with single hyphen separators
* Not start or end with `-`
* Not contain consecutive `--`
* Match the directory name that contains `SKILL.md`

Equivalent regex:

```
^[a-z0-9]+(-[a-z0-9]+)*$
```

---

### [Follow length rules](#follow-length-rules)

`description` must be 1-1024 characters.
Keep it specific enough for the agent to choose correctly.

---

### [Use an example](#use-an-example)

Create `.opencode/skills/git-release/SKILL.md` like this:

```
---

name: git-release

description: Create consistent releases and changelogs

license: MIT

compatibility: opencode

metadata:

audience: maintainers

workflow: github

opencode/slash: "true"

opencode/autoinvoke: "false"

---

### What I do

- Draft release notes from merged PRs

- Propose a version bump

- Provide a copy-pasteable `gh release create` command

### When to use me

Use this when you are preparing a tagged release.

Ask clarifying questions if the target versioning scheme is unclear.
```

---

### [Recognize tool description](#recognize-tool-description)

OpenCode lists available skills in the `skill` tool description.
Each entry includes the skill name and description:

```
<available_skills>

<skill>

<name>git-release</name>

<description>Create consistent releases and changelogs</description>

</skill>

</available_skills>
```

The agent loads a skill by calling the tool:

```
skill({ name: "git-release" })
```

Skills with `metadata["opencode/autoinvoke"]` set to `"false"` are not included in `<available_skills>`.
They can still be selected manually and loaded by exact name.

---

### [Configure permissions](#configure-permissions)

Control which skills agents can access using pattern-based permissions in `opencode.json`:

```
{

"permission": {

"skill": {

"*": "allow",

"pr-review": "allow",

"internal-*": "deny",

"experimental-*": "ask"

}

}

}
```

| Permission | Behavior |
| --- | --- |
| `allow` | Skill loads immediately |
| `deny` | Skill hidden from agent, access rejected |
| `ask` | User prompted for approval before loading |

Patterns support wildcards: `internal-*` matches `internal-docs`, `internal-tools`, etc.

---

### [Override per agent](#override-per-agent)

Give specific agents different permissions than the global defaults.

**For custom agents** (in agent frontmatter):

```
---

permission:

skill:

"documents-*": "allow"

---
```

**For built-in agents** (in `opencode.json`):

```
{

"agent": {

"plan": {

"permission": {

"skill": {

"internal-*": "allow"

}

}

}

}

}
```

---

### [Disable the skill tool](#disable-the-skill-tool)

Completely disable skills for agents that shouldnât use them:

**For custom agents**:

```
---

tools:

skill: false

---
```

**For built-in agents**:

```
{

"agent": {

"plan": {

"tools": {

"skill": false

}

}

}

}
```

When disabled, the `<available_skills>` section is omitted entirely.

---

### [Troubleshoot loading](#troubleshoot-loading)

If a skill does not show up:

1. Verify `SKILL.md` is spelled in all caps
2. Check that frontmatter includes `name` and `description`
3. Ensure skill names are unique across all locations
4. Check permissionsâskills with `deny` are hidden from agents
5. Check `metadata["opencode/autoinvoke"]`âskills set to `"false"` are hidden from model-facing guidance

[Edit page](https://github.com/anomalyco/opencode/edit/dev/packages/web/src/content/docs/skills.mdx)[Found a bug? Open an issue](https://github.com/anomalyco/opencode/issues/new)[Join our Discord community](https://opencode.ai/discord)  Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

© [Anomaly](https://anoma.ly)

Last updated: Oct 13, 2026

---
<!--
URL: https://opencode.ai/docs/tools
title: Tools | OpenCode
-->

[Skip to content](#_top)

[![](/docs/_astro/logo-dark.DOStV66V.svg) ![](/docs/_astro/logo-light.B0yzR0O5.svg)  OpenCode](/docs/)

[app.header.home](/)[app.header.docs](/v2/docs)

Search  `CtrlK`

Cancel

  [New OpenCode v2 is now available →](https://opencode.ai/v2)

* [Intro](/docs/)
* [Config](/docs/config/)
* [Providers](/docs/providers/)
* [Network](/docs/network/)
* [Enterprise](/docs/enterprise/)
* [Troubleshooting](/docs/troubleshooting/)
* [Windows](/docs/windows-wsl)
* Usage

  + [Go](https://opencode.ai/v2/docs/console/go/)
  + [TUI](/docs/tui/)
  + [CLI](/docs/cli/)
  + [Web](/docs/web/)
  + [IDE](/docs/ide/)
  + [Console](https://opencode.ai/v2/docs/console/)
  + [Share](/docs/share/)
  + [GitHub](/docs/github/)
  + [GitLab](/docs/gitlab/)
* Configure

  + [Tools](/docs/tools/)
  + [Rules](/docs/rules/)
  + [Agents](/docs/agents/)
  + [Models](/docs/models/)
  + [Themes](/docs/themes/)
  + [Keybinds](/docs/keybinds/)
  + [Commands](/docs/commands/)
  + [Formatters](/docs/formatters/)
  + [Permissions](/docs/permissions/)
  + [Policies](/docs/policies/)
  + [LSP Servers](/docs/lsp/)
  + [MCP servers](/docs/mcp-servers/)
  + [ACP Support](/docs/acp/)
  + [Agent Skills](/docs/skills/)
  + [References](/docs/references/)
  + [Custom Tools](/docs/custom-tools/)
* Develop

  + [SDK](/docs/sdk/)
  + [Server](/docs/server/)
  + [Plugins](/docs/plugins/)
  + [Ecosystem](/docs/ecosystem/)

[GitHub](https://github.com/anomalyco/opencode)[Discord](https://opencode.ai/discord)

  Select theme   DarkLightAuto         Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

On this page

* [Overview](#_top)
* [Configure](#configure)
* [Built-in](#built-in)
  + [bash](#bash)
  + [edit](#edit)
  + [write](#write)
  + [read](#read)
  + [grep](#grep)
  + [glob](#glob)
  + [lsp (experimental)](#lsp-experimental)
  + [apply\_patch](#apply_patch)
  + [skill](#skill)
  + [webfetch](#webfetch)
  + [websearch](#websearch)
  + [question](#question)
* [Custom tools](#custom-tools)
* [MCP servers](#mcp-servers)
* [Internals](#internals)
  + [Ignore patterns](#ignore-patterns)

### On this page

* [Overview](#_top)
* [Configure](#configure)
* [Built-in](#built-in)
  + [bash](#bash)
  + [edit](#edit)
  + [write](#write)
  + [read](#read)
  + [grep](#grep)
  + [glob](#glob)
  + [lsp (experimental)](#lsp-experimental)
  + [apply\_patch](#apply_patch)
  + [skill](#skill)
  + [webfetch](#webfetch)
  + [websearch](#websearch)
  + [question](#question)
* [Custom tools](#custom-tools)
* [MCP servers](#mcp-servers)
* [Internals](#internals)
  + [Ignore patterns](#ignore-patterns)

## Tools

Manage the tools an LLM can use.

Tools allow the LLM to perform actions in your codebase. OpenCode comes with a set of built-in tools, but you can extend it with [custom tools](/docs/custom-tools) or [MCP servers](/docs/mcp-servers).

By default, all tools are **enabled** and donât need permission to run. You can control tool behavior through [permissions](/docs/permissions).

---

### [Configure](#configure)

Use the `permission` field to control tool behavior. You can allow, deny, or require approval for each tool.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"permission": {

"edit": "deny",

"bash": "ask",

"webfetch": "allow"

}

}
```

You can also use wildcards to control multiple tools at once. For example, to require approval for all tools from an MCP server:

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"permission": {

"mymcp_*": "ask"

}

}
```

[Learn more](/docs/permissions) about configuring permissions.

---

### [Built-in](#built-in)

Here are all the built-in tools available in OpenCode.

---

#### [bash](#bash)

Execute shell commands in your project environment.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"permission": {

"bash": "allow"

}

}
```

This tool allows the LLM to run terminal commands like `npm install`, `git status`, or any other shell command.

---

#### [edit](#edit)

Modify existing files using exact string replacements.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"permission": {

"edit": "allow"

}

}
```

This tool performs precise edits to files by replacing exact text matches. Itâs the primary way the LLM modifies code.

---

#### [write](#write)

Create new files or overwrite existing ones.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"permission": {

"edit": "allow"

}

}
```

Use this to allow the LLM to create new files. It will overwrite existing files if they already exist.

Note

The `write` tool is controlled by the `edit` permission, which covers all file modifications (`edit`, `write`, `apply_patch`).

---

#### [read](#read)

Read file contents from your codebase.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"permission": {

"read": "allow"

}

}
```

This tool reads files and returns their contents. It supports reading specific line ranges for large files.

---

#### [grep](#grep)

Search file contents using regular expressions.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"permission": {

"grep": "allow"

}

}
```

Fast content search across your codebase. Supports full regex syntax and file pattern filtering.

---

#### [glob](#glob)

Find files by pattern matching.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"permission": {

"glob": "allow"

}

}
```

Search for files using glob patterns like `**/*.js` or `src/**/*.ts`. Returns matching file paths sorted by modification time.

---

#### [lsp (experimental)](#lsp-experimental)

Interact with your configured LSP servers to get code intelligence features like definitions, references, hover info, and call hierarchy.

Note

This tool is only available when `OPENCODE_EXPERIMENTAL_LSP_TOOL=true` (or `OPENCODE_EXPERIMENTAL=true`).

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"permission": {

"lsp": "allow"

}

}
```

Supported operations include `goToDefinition`, `findReferences`, `hover`, `documentSymbol`, `workspaceSymbol`, `goToImplementation`, `prepareCallHierarchy`, `incomingCalls`, and `outgoingCalls`.

To configure which LSP servers are available for your project, see [LSP Servers](/docs/lsp).

---

#### [apply\_patch](#apply_patch)

Apply patches to files.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"permission": {

"edit": "allow"

}

}
```

This tool applies patch files to your codebase. Useful for applying diffs and patches from various sources.

When handling `tool.execute.before` or `tool.execute.after` hooks, check `input.tool === "apply_patch"` (not `"patch"`).

`apply_patch` uses `output.args.patchText` instead of `output.args.filePath`. Paths are embedded in marker lines within `patchText` and are relative to the project root (for example: `*** Add File: src/new-file.ts`, `*** Update File: src/existing.ts`, `*** Move to: src/renamed.ts`, `*** Delete File: src/obsolete.ts`).

Note

The `apply_patch` tool is controlled by the `edit` permission, which covers all file modifications (`edit`, `write`, `apply_patch`).

---

#### [skill](#skill)

Load a [skill](/docs/skills) (a `SKILL.md` file) and return its content in the conversation.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"permission": {

"skill": "allow"

}

}
```

---

#### [webfetch](#webfetch)

Fetch web content.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"permission": {

"webfetch": "allow"

}

}
```

Allows the LLM to fetch and read web pages. Useful for looking up documentation or researching online resources.

---

#### [websearch](#websearch)

Search the web for information.

Note

This tool is only available when using the OpenCode or OpenCode Go provider, or when either the `OPENCODE_ENABLE_EXA` or `OPENCODE_ENABLE_PARALLEL` environment variable is set to any truthy value (e.g., `true` or `1`).

To enable when launching OpenCode:

Terminal window

```
OPENCODE_ENABLE_EXA=1 opencode

## or

OPENCODE_ENABLE_PARALLEL=1 opencode
```

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"permission": {

"websearch": "allow"

}

}
```

Performs web searches using Exa or Parallel to find relevant information online. Useful for researching topics, finding current events, or gathering information beyond the training data cutoff.

No API key is required â the tool connects directly to the backendâs hosted MCP service without authentication.

Tip

Use `websearch` when you need to find information (discovery), and `webfetch` when you need to retrieve content from a specific URL (retrieval).

---

#### [question](#question)

Ask the user questions during execution.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"permission": {

"question": "allow"

}

}
```

This tool allows the LLM to ask the user questions during a task. Itâs useful for:

* Gathering user preferences or requirements
* Clarifying ambiguous instructions
* Getting decisions on implementation choices
* Offering choices about what direction to take

Each question includes a header, the question text, and a list of options. Users can select from the provided options or type a custom answer. When there are multiple questions, users can navigate between them before submitting all answers.

---

### [Custom tools](#custom-tools)

Custom tools let you define your own functions that the LLM can call. These are defined in your config file and can execute arbitrary code.

[Learn more](/docs/custom-tools) about creating custom tools.

---

### [MCP servers](#mcp-servers)

MCP (Model Context Protocol) servers allow you to integrate external tools and services. This includes database access, API integrations, and third-party services.

[Learn more](/docs/mcp-servers) about configuring MCP servers.

---

### [Internals](#internals)

Internally, tools like `grep` and `glob` use [ripgrep](https://github.com/BurntSushi/ripgrep) under the hood. By default, ripgrep respects `.gitignore` patterns, which means files and directories listed in your `.gitignore` will be excluded from searches and listings.

---

#### [Ignore patterns](#ignore-patterns)

To include files that would normally be ignored, create a `.ignore` file in your project root. This file can explicitly allow certain paths.

.ignore

```
!node_modules/

!dist/

!build/
```

For example, this `.ignore` file allows ripgrep to search within `node_modules/`, `dist/`, and `build/` directories even if theyâre listed in `.gitignore`.

[Edit page](https://github.com/anomalyco/opencode/edit/dev/packages/web/src/content/docs/tools.mdx)[Found a bug? Open an issue](https://github.com/anomalyco/opencode/issues/new)[Join our Discord community](https://opencode.ai/discord)  Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

© [Anomaly](https://anoma.ly)

Last updated: Oct 13, 2026

---
<!--
URL: https://opencode.ai/docs/models
title: Models | OpenCode
-->

[Skip to content](#_top)

[![](/docs/_astro/logo-dark.DOStV66V.svg) ![](/docs/_astro/logo-light.B0yzR0O5.svg)  OpenCode](/docs/)

[app.header.home](/)[app.header.docs](/v2/docs)

Search  `CtrlK`

Cancel

  [New OpenCode v2 is now available →](https://opencode.ai/v2)

* [Intro](/docs/)
* [Config](/docs/config/)
* [Providers](/docs/providers/)
* [Network](/docs/network/)
* [Enterprise](/docs/enterprise/)
* [Troubleshooting](/docs/troubleshooting/)
* [Windows](/docs/windows-wsl)
* Usage

  + [Go](https://opencode.ai/v2/docs/console/go/)
  + [TUI](/docs/tui/)
  + [CLI](/docs/cli/)
  + [Web](/docs/web/)
  + [IDE](/docs/ide/)
  + [Console](https://opencode.ai/v2/docs/console/)
  + [Share](/docs/share/)
  + [GitHub](/docs/github/)
  + [GitLab](/docs/gitlab/)
* Configure

  + [Tools](/docs/tools/)
  + [Rules](/docs/rules/)
  + [Agents](/docs/agents/)
  + [Models](/docs/models/)
  + [Themes](/docs/themes/)
  + [Keybinds](/docs/keybinds/)
  + [Commands](/docs/commands/)
  + [Formatters](/docs/formatters/)
  + [Permissions](/docs/permissions/)
  + [Policies](/docs/policies/)
  + [LSP Servers](/docs/lsp/)
  + [MCP servers](/docs/mcp-servers/)
  + [ACP Support](/docs/acp/)
  + [Agent Skills](/docs/skills/)
  + [References](/docs/references/)
  + [Custom Tools](/docs/custom-tools/)
* Develop

  + [SDK](/docs/sdk/)
  + [Server](/docs/server/)
  + [Plugins](/docs/plugins/)
  + [Ecosystem](/docs/ecosystem/)

[GitHub](https://github.com/anomalyco/opencode)[Discord](https://opencode.ai/discord)

  Select theme   DarkLightAuto         Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

On this page

* [Overview](#_top)
* [Providers](#providers)
* [Select a model](#select-a-model)
* [Recommended models](#recommended-models)
* [Set a default](#set-a-default)
* [Configure models](#configure-models)
* [Variants](#variants)
  + [Built-in variants](#built-in-variants)
  + [Custom variants](#custom-variants)
  + [Cycle variants](#cycle-variants)
* [Loading models](#loading-models)

### On this page

* [Overview](#_top)
* [Providers](#providers)
* [Select a model](#select-a-model)
* [Recommended models](#recommended-models)
* [Set a default](#set-a-default)
* [Configure models](#configure-models)
* [Variants](#variants)
  + [Built-in variants](#built-in-variants)
  + [Custom variants](#custom-variants)
  + [Cycle variants](#cycle-variants)
* [Loading models](#loading-models)

## Models

Configuring an LLM provider and model.

OpenCode uses the [AI SDK](https://ai-sdk.dev/) and [Models.dev](https://models.dev) to support **75+ LLM providers** and it supports running local models.

---

### [Providers](#providers)

Most popular providers are preloaded by default. If youâve added the credentials for a provider through the `/connect` command, theyâll be available when you start OpenCode.

Learn more about [providers](/docs/providers).

---

### [Select a model](#select-a-model)

Once youâve configured your provider you can select the model you want by typing in:

```
/models
```

---

### [Recommended models](#recommended-models)

There are a lot of models out there, with new models coming out every week.

Tip

Consider using one of the models we recommend.

However, there are only a few of them that are good at both generating code and tool calling.

Here are several models that work well with OpenCode, in no particular order. (This is not an exhaustive list nor is it necessarily up to date):

* GPT 5.2
* GPT 5.1 Codex
* Claude Opus 4.5
* Claude Sonnet 4.5
* Minimax M2.1
* Gemini 3 Pro

---

### [Set a default](#set-a-default)

To set one of these as the default model, you can set the `model` key in your
OpenCode config.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"model": "lmstudio/google/gemma-3n-e4b"

}
```

Here the full ID is `provider_id/model_id`. For example, if youâre using [OpenCode Zen](https://opencode.ai/v2/docs/console/), you would use `opencode/gpt-5.1-codex` for GPT 5.1 Codex.

If youâve configured a [custom provider](/docs/providers#custom), the `provider_id` is key from the `provider` part of your config, and the `model_id` is the key from `provider.models`.

---

### [Configure models](#configure-models)

You can globally configure a modelâs options through the config.

opencode.jsonc

```
{

"$schema": "https://opencode.ai/config.json",

"provider": {

"openai": {

"models": {

"gpt-5": {

"options": {

"reasoningEffort": "high",

"textVerbosity": "low",

"reasoningSummary": "auto",

"include": ["reasoning.encrypted_content"],

},

},

},

},

"anthropic": {

"models": {

"claude-sonnet-4-5-20250929": {

"options": {

"thinking": {

"type": "enabled",

"budgetTokens": 16000,

},

},

},

},

},

},

}
```

Here weâre configuring global settings for two built-in models: `gpt-5` when accessed via the `openai` provider, and `claude-sonnet-4-20250514` when accessed via the `anthropic` provider.
The built-in provider and model names can be found on [Models.dev](https://models.dev).

You can also configure these options for any agents that you are using. The agent config overrides any global options here. [Learn more](/docs/agents/#additional).

You can also define custom variants that extend built-in ones. Variants let you configure different settings for the same model without creating duplicate entries:

opencode.jsonc

```
{

"$schema": "https://opencode.ai/config.json",

"provider": {

"opencode": {

"models": {

"gpt-5": {

"variants": {

"high": {

"reasoningEffort": "high",

"textVerbosity": "low",

"reasoningSummary": "auto",

},

"low": {

"reasoningEffort": "low",

"textVerbosity": "low",

"reasoningSummary": "auto",

},

},

},

},

},

},

}
```

---

### [Variants](#variants)

Many models support multiple variants with different configurations. OpenCode ships with built-in default variants for popular providers.

#### [Built-in variants](#built-in-variants)

OpenCode ships with default variants for many providers:

**Anthropic**:

* `high` - High thinking budget (default)
* `max` - Maximum thinking budget

**OpenAI**:

Varies by model but roughly:

* `none` - No reasoning
* `minimal` - Minimal reasoning effort
* `low` - Low reasoning effort
* `medium` - Medium reasoning effort
* `high` - High reasoning effort
* `xhigh` - Extra high reasoning effort

**Google**:

* `low` - Lower effort/token budget
* `high` - Higher effort/token budget

Tip

This list is not comprehensive. Many other providers have built-in defaults too.

#### [Custom variants](#custom-variants)

You can override existing variants or add your own:

opencode.jsonc

```
{

"$schema": "https://opencode.ai/config.json",

"provider": {

"openai": {

"models": {

"gpt-5": {

"variants": {

"thinking": {

"reasoningEffort": "high",

"textVerbosity": "low",

},

"fast": {

"disabled": true,

},

},

},

},

},

},

}
```

#### [Cycle variants](#cycle-variants)

Use the keybind `variant_cycle` to quickly switch between variants. [Learn more](/docs/keybinds).

---

### [Loading models](#loading-models)

When OpenCode starts up, it checks for models in the following priority order:

1. The `--model` or `-m` command line flag. The format is the same as in the config file: `provider_id/model_id`.
2. The model list in the OpenCode config.

   opencode.json

   ```
   {

   "$schema": "https://opencode.ai/config.json",

   "model": "anthropic/claude-sonnet-4-20250514"

   }
   ```

   The format here is `provider/model`.
3. The last used model.
4. The first model using an internal priority.

[Edit page](https://github.com/anomalyco/opencode/edit/dev/packages/web/src/content/docs/models.mdx)[Found a bug? Open an issue](https://github.com/anomalyco/opencode/issues/new)[Join our Discord community](https://opencode.ai/discord)  Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

© [Anomaly](https://anoma.ly)

Last updated: Oct 13, 2026

---
<!--
URL: https://opencode.ai/docs/server
title: Server | OpenCode
-->

[Skip to content](#_top)

[![](/docs/_astro/logo-dark.DOStV66V.svg) ![](/docs/_astro/logo-light.B0yzR0O5.svg)  OpenCode](/docs/)

[app.header.home](/)[app.header.docs](/v2/docs)

Search  `CtrlK`

Cancel

  [New OpenCode v2 is now available →](https://opencode.ai/v2)

* [Intro](/docs/)
* [Config](/docs/config/)
* [Providers](/docs/providers/)
* [Network](/docs/network/)
* [Enterprise](/docs/enterprise/)
* [Troubleshooting](/docs/troubleshooting/)
* [Windows](/docs/windows-wsl)
* Usage

  + [Go](https://opencode.ai/v2/docs/console/go/)
  + [TUI](/docs/tui/)
  + [CLI](/docs/cli/)
  + [Web](/docs/web/)
  + [IDE](/docs/ide/)
  + [Console](https://opencode.ai/v2/docs/console/)
  + [Share](/docs/share/)
  + [GitHub](/docs/github/)
  + [GitLab](/docs/gitlab/)
* Configure

  + [Tools](/docs/tools/)
  + [Rules](/docs/rules/)
  + [Agents](/docs/agents/)
  + [Models](/docs/models/)
  + [Themes](/docs/themes/)
  + [Keybinds](/docs/keybinds/)
  + [Commands](/docs/commands/)
  + [Formatters](/docs/formatters/)
  + [Permissions](/docs/permissions/)
  + [Policies](/docs/policies/)
  + [LSP Servers](/docs/lsp/)
  + [MCP servers](/docs/mcp-servers/)
  + [ACP Support](/docs/acp/)
  + [Agent Skills](/docs/skills/)
  + [References](/docs/references/)
  + [Custom Tools](/docs/custom-tools/)
* Develop

  + [SDK](/docs/sdk/)
  + [Server](/docs/server/)
  + [Plugins](/docs/plugins/)
  + [Ecosystem](/docs/ecosystem/)

[GitHub](https://github.com/anomalyco/opencode)[Discord](https://opencode.ai/discord)

  Select theme   DarkLightAuto         Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

On this page

* [Overview](#_top)
  + [Usage](#usage)
  + [Authentication](#authentication)
  + [How it works](#how-it-works)
* [Spec](#spec)
* [APIs](#apis)
  + [Global](#global)
  + [Project](#project)
  + [Path & VCS](#path--vcs)
  + [Instance](#instance)
  + [Config](#config)
  + [Provider](#provider)
  + [Sessions](#sessions)
  + [Messages](#messages)
  + [Commands](#commands)
  + [Files](#files)
  + [Tools (Experimental)](#tools-experimental)
  + [LSP, Formatters & MCP](#lsp-formatters--mcp)
  + [Agents](#agents)
  + [Logging](#logging)
  + [TUI](#tui)
  + [Auth](#auth)
  + [Events](#events)
  + [Docs](#docs)

### On this page

* [Overview](#_top)
  + [Usage](#usage)
  + [Authentication](#authentication)
  + [How it works](#how-it-works)
* [Spec](#spec)
* [APIs](#apis)
  + [Global](#global)
  + [Project](#project)
  + [Path & VCS](#path--vcs)
  + [Instance](#instance)
  + [Config](#config)
  + [Provider](#provider)
  + [Sessions](#sessions)
  + [Messages](#messages)
  + [Commands](#commands)
  + [Files](#files)
  + [Tools (Experimental)](#tools-experimental)
  + [LSP, Formatters & MCP](#lsp-formatters--mcp)
  + [Agents](#agents)
  + [Logging](#logging)
  + [TUI](#tui)
  + [Auth](#auth)
  + [Events](#events)
  + [Docs](#docs)

## Server

Interact with opencode server over HTTP.

The `opencode serve` command runs a headless HTTP server that exposes an OpenAPI endpoint that an opencode client can use.

---

#### [Usage](#usage)

Terminal window

```
opencode serve [--port <number>] [--hostname <string>] [--cors <origin>]
```

##### [Options](#options)

| Flag | Description | Default |
| --- | --- | --- |
| `--port` | Port to listen on | `4096` |
| `--hostname` | Hostname to listen on | `127.0.0.1` |
| `--mdns` | Enable mDNS discovery | `false` |
| `--mdns-domain` | Custom domain name for mDNS service | `opencode.local` |
| `--cors` | Additional browser origins to allow | `[]` |

`--cors` can be passed multiple times:

Terminal window

```
opencode serve --cors http://localhost:5173 --cors https://app.example.com
```

---

#### [Authentication](#authentication)

Set `OPENCODE_SERVER_PASSWORD` to protect the server with HTTP basic auth. The username defaults to `opencode`, or set `OPENCODE_SERVER_USERNAME` to override it. This applies to both `opencode serve` and `opencode web`.

Terminal window

```
OPENCODE_SERVER_PASSWORD=your-password opencode serve
```

---

#### [How it works](#how-it-works)

When you run `opencode` it starts a TUI and a server. Where the TUI is the
client that talks to the server. The server exposes an OpenAPI 3.1 spec
endpoint. This endpoint is also used to generate an [SDK](/docs/sdk).

Tip

Use the opencode server to interact with opencode programmatically.

This architecture lets opencode support multiple clients and allows you to interact with opencode programmatically.

You can run `opencode serve` to start a standalone server. If you have the
opencode TUI running, `opencode serve` will start a new server.

---

##### [Connect to an existing server](#connect-to-an-existing-server)

When you start the TUI it randomly assigns a port and hostname. You can instead pass in the `--hostname` and `--port` [flags](/docs/cli). Then use this to connect to its server.

The [`/tui`](#tui) endpoint can be used to drive the TUI through the server. For example, you can prefill or run a prompt. This setup is used by the OpenCode [IDE](/docs/ide) plugins.

---

### [Spec](#spec)

The server publishes an OpenAPI 3.1 spec that can be viewed at:

```
http://<hostname>:<port>/doc
```

For example, `http://localhost:4096/doc`. Use the spec to generate clients or inspect request and response types. Or view it in a Swagger explorer.

---

### [APIs](#apis)

The opencode server exposes the following APIs.

---

#### [Global](#global)

| Method | Path | Description | Response |
| --- | --- | --- | --- |
| `GET` | `/global/health` | Get server health and version | `{ healthy: true, version: string }` |
| `GET` | `/global/event` | Get global events (SSE stream) | Event stream |

---

#### [Project](#project)

| Method | Path | Description | Response |
| --- | --- | --- | --- |
| `GET` | `/project` | List all projects | [`Project[]`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) |
| `GET` | `/project/current` | Get the current project | [`Project`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) |

---

#### [Path & VCS](#path--vcs)

| Method | Path | Description | Response |
| --- | --- | --- | --- |
| `GET` | `/path` | Get the current path | [`Path`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) |
| `GET` | `/vcs` | Get VCS info for the current project | [`VcsInfo`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) |

---

#### [Instance](#instance)

| Method | Path | Description | Response |
| --- | --- | --- | --- |
| `POST` | `/instance/dispose` | Dispose the current instance | `boolean` |

---

#### [Config](#config)

| Method | Path | Description | Response |
| --- | --- | --- | --- |
| `GET` | `/config` | Get config info | [`Config`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) |
| `PATCH` | `/config` | Update config | [`Config`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) |
| `GET` | `/config/providers` | List providers and default models | `{ providers:` [Provider[]](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts)`, default: { [key: string]: string } }` |

---

#### [Provider](#provider)

| Method | Path | Description | Response |
| --- | --- | --- | --- |
| `GET` | `/provider` | List all providers | `{ all:` [Provider[]](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts)`, default: {...}, connected: string[] }` |
| `GET` | `/provider/auth` | Get provider authentication methods | `{ [providerID: string]:` [ProviderAuthMethod[]](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) `}` |
| `POST` | `/provider/{id}/oauth/authorize` | Authorize a provider using OAuth | [`ProviderAuthAuthorization`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) |
| `POST` | `/provider/{id}/oauth/callback` | Handle OAuth callback for a provider | `boolean` |

---

#### [Sessions](#sessions)

| Method | Path | Description | Notes |
| --- | --- | --- | --- |
| `GET` | `/session` | List all sessions | Returns [`Session[]`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) |
| `POST` | `/session` | Create a new session | body: `{ parentID?, title? }`, returns [`Session`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) |
| `GET` | `/session/status` | Get session status for all sessions | Returns `{ [sessionID: string]:` [SessionStatus](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) `}` |
| `GET` | `/session/:id` | Get session details | Returns [`Session`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) |
| `DELETE` | `/session/:id` | Delete a session and all its data | Returns `boolean` |
| `PATCH` | `/session/:id` | Update session properties | body: `{ title? }`, returns [`Session`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) |
| `GET` | `/session/:id/children` | Get a sessionâs child sessions | Returns [`Session[]`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) |
| `POST` | `/session/:id/init` | Analyze app and create `AGENTS.md` | body: `{ messageID, providerID, modelID }`, returns `boolean` |
| `POST` | `/session/:id/fork` | Fork an existing session at a message | body: `{ messageID? }`, returns [`Session`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) |
| `POST` | `/session/:id/abort` | Abort a running session | Returns `boolean` |
| `POST` | `/session/:id/share` | Share a session | Returns [`Session`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) |
| `DELETE` | `/session/:id/share` | Unshare a session | Returns [`Session`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) |
| `GET` | `/session/:id/diff` | Get the diff for this session | query: `messageID?`, returns [`FileDiff[]`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) |
| `POST` | `/session/:id/summarize` | Summarize the session | body: `{ providerID, modelID }`, returns `boolean` |
| `POST` | `/session/:id/revert` | Revert a message | body: `{ messageID, partID? }`, returns `boolean` |
| `POST` | `/session/:id/unrevert` | Restore all reverted messages | Returns `boolean` |
| `POST` | `/session/:id/permissions/:permissionID` | Respond to a permission request | body: `{ response, remember? }`, returns `boolean` |

---

#### [Messages](#messages)

| Method | Path | Description | Notes |
| --- | --- | --- | --- |
| `GET` | `/session/:id/message` | List messages in a session | query: `limit?`, returns `{ info:` [Message](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts)`, parts:` [Part[]](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts)`}[]` |
| `POST` | `/session/:id/message` | Send a message and wait for response | body: `{ messageID?, model?, agent?, noReply?, system?, tools?, parts }`, returns `{ info:` [Message](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts)`, parts:` [Part[]](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts)`}` |
| `GET` | `/session/:id/message/:messageID` | Get message details | Returns `{ info:` [Message](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts)`, parts:` [Part[]](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts)`}` |
| `POST` | `/session/:id/prompt_async` | Send a message asynchronously (no wait) | body: same as `/session/:id/message`, returns `204 No Content` |
| `POST` | `/session/:id/command` | Execute a slash command | body: `{ messageID?, agent?, model?, command, arguments }`, returns `{ info:` [Message](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts)`, parts:` [Part[]](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts)`}` |
| `POST` | `/session/:id/shell` | Run a shell command | body: `{ agent, model?, command }`, returns `{ info:` [Message](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts)`, parts:` [Part[]](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts)`}` |

---

#### [Commands](#commands)

| Method | Path | Description | Response |
| --- | --- | --- | --- |
| `GET` | `/command` | List all commands | [`Command[]`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) |

---

#### [Files](#files)

| Method | Path | Description | Response |
| --- | --- | --- | --- |
| `GET` | `/find?pattern=<pat>` | Search for text in files | Array of match objects with `path`, `lines`, `line_number`, `absolute_offset`, `submatches` |
| `GET` | `/find/file?query=<q>` | Find files and directories by name | `string[]` (paths) |
| `GET` | `/find/symbol?query=<q>` | Find workspace symbols | [`Symbol[]`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) |
| `GET` | `/file?path=<path>` | List files and directories | [`FileNode[]`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) |
| `GET` | `/file/content?path=<p>` | Read a file | [`FileContent`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) |
| `GET` | `/file/status` | Get status for tracked files | [`File[]`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) |

##### [`/find/file` query parameters](#findfile-query-parameters)

* `query` (required) â search string (fuzzy match)
* `type` (optional) â limit results to `"file"` or `"directory"`
* `directory` (optional) â override the project root for the search
* `limit` (optional) â max results (1â200)
* `dirs` (optional) â legacy flag (`"false"` returns only files)

---

#### [Tools (Experimental)](#tools-experimental)

| Method | Path | Description | Response |
| --- | --- | --- | --- |
| `GET` | `/experimental/tool/ids` | List all tool IDs | [`ToolIDs`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) |
| `GET` | `/experimental/tool?provider=<p>&model=<m>` | List tools with JSON schemas for a model | [`ToolList`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) |

---

#### [LSP, Formatters & MCP](#lsp-formatters--mcp)

| Method | Path | Description | Response |
| --- | --- | --- | --- |
| `GET` | `/lsp` | Get LSP server status | [`LSPStatus[]`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) |
| `GET` | `/formatter` | Get formatter status | [`FormatterStatus[]`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) |
| `GET` | `/mcp` | Get MCP server status | `{ [name: string]:` [MCPStatus](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) `}` |
| `POST` | `/mcp` | Add MCP server dynamically | body: `{ name, config }`, returns MCP status object |

---

#### [Agents](#agents)

| Method | Path | Description | Response |
| --- | --- | --- | --- |
| `GET` | `/agent` | List all available agents | [`Agent[]`](https://github.com/anomalyco/opencode/blob/dev/packages/sdk/js/src/gen/types.gen.ts) |

---

#### [Logging](#logging)

| Method | Path | Description | Response |
| --- | --- | --- | --- |
| `POST` | `/log` | Write log entry. Body: `{ service, level, message, extra? }` | `boolean` |

---

#### [TUI](#tui)

| Method | Path | Description | Response |
| --- | --- | --- | --- |
| `POST` | `/tui/append-prompt` | Append text to the prompt | `boolean` |
| `POST` | `/tui/open-help` | Open the help dialog | `boolean` |
| `POST` | `/tui/open-sessions` | Open the session selector | `boolean` |
| `POST` | `/tui/open-themes` | Open the theme selector | `boolean` |
| `POST` | `/tui/open-models` | Open the model selector | `boolean` |
| `POST` | `/tui/submit-prompt` | Submit the current prompt | `boolean` |
| `POST` | `/tui/clear-prompt` | Clear the prompt | `boolean` |
| `POST` | `/tui/execute-command` | Execute a command (`{ command }`) | `boolean` |
| `POST` | `/tui/show-toast` | Show toast (`{ title?, message, variant }`) | `boolean` |
| `GET` | `/tui/control/next` | Wait for the next control request | Control request object |
| `POST` | `/tui/control/response` | Respond to a control request (`{ body }`) | `boolean` |

---

#### [Auth](#auth)

| Method | Path | Description | Response |
| --- | --- | --- | --- |
| `PUT` | `/auth/:id` | Set authentication credentials. Body must match provider schema | `boolean` |

---

#### [Events](#events)

| Method | Path | Description | Response |
| --- | --- | --- | --- |
| `GET` | `/event` | Server-sent events stream. First event is `server.connected`, then bus events | Server-sent events stream |

---

#### [Docs](#docs)

| Method | Path | Description | Response |
| --- | --- | --- | --- |
| `GET` | `/doc` | OpenAPI 3.1 specification | HTML page with OpenAPI spec |

[Edit page](https://github.com/anomalyco/opencode/edit/dev/packages/web/src/content/docs/server.mdx)[Found a bug? Open an issue](https://github.com/anomalyco/opencode/issues/new)[Join our Discord community](https://opencode.ai/discord)  Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

© [Anomaly](https://anoma.ly)

Last updated: Oct 13, 2026

---
<!--
URL: https://opencode.ai/docs/policies
title: Policies | OpenCode
-->

[Skip to content](#_top)

[![](/docs/_astro/logo-dark.DOStV66V.svg) ![](/docs/_astro/logo-light.B0yzR0O5.svg)  OpenCode](/docs/)

[app.header.home](/)[app.header.docs](/v2/docs)

Search  `CtrlK`

Cancel

  [New OpenCode v2 is now available →](https://opencode.ai/v2)

* [Intro](/docs/)
* [Config](/docs/config/)
* [Providers](/docs/providers/)
* [Network](/docs/network/)
* [Enterprise](/docs/enterprise/)
* [Troubleshooting](/docs/troubleshooting/)
* [Windows](/docs/windows-wsl)
* Usage

  + [Go](https://opencode.ai/v2/docs/console/go/)
  + [TUI](/docs/tui/)
  + [CLI](/docs/cli/)
  + [Web](/docs/web/)
  + [IDE](/docs/ide/)
  + [Console](https://opencode.ai/v2/docs/console/)
  + [Share](/docs/share/)
  + [GitHub](/docs/github/)
  + [GitLab](/docs/gitlab/)
* Configure

  + [Tools](/docs/tools/)
  + [Rules](/docs/rules/)
  + [Agents](/docs/agents/)
  + [Models](/docs/models/)
  + [Themes](/docs/themes/)
  + [Keybinds](/docs/keybinds/)
  + [Commands](/docs/commands/)
  + [Formatters](/docs/formatters/)
  + [Permissions](/docs/permissions/)
  + [Policies](/docs/policies/)
  + [LSP Servers](/docs/lsp/)
  + [MCP servers](/docs/mcp-servers/)
  + [ACP Support](/docs/acp/)
  + [Agent Skills](/docs/skills/)
  + [References](/docs/references/)
  + [Custom Tools](/docs/custom-tools/)
* Develop

  + [SDK](/docs/sdk/)
  + [Server](/docs/server/)
  + [Plugins](/docs/plugins/)
  + [Ecosystem](/docs/ecosystem/)

[GitHub](https://github.com/anomalyco/opencode)[Discord](https://opencode.ai/discord)

  Select theme   DarkLightAuto         Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

On this page

* [Overview](#_top)
* [Configuration](#configuration)
* [Available Policies](#available-policies)
* [Matching](#matching)
* [Rule Order](#rule-order)
* [Provider Lists](#provider-lists)

### On this page

* [Overview](#_top)
* [Configuration](#configuration)
* [Available Policies](#available-policies)
* [Matching](#matching)
* [Rule Order](#rule-order)
* [Provider Lists](#provider-lists)

## Policies

Control which configured resources OpenCode may use.

Policies control whether OpenCode may perform an action on a named resource. This feature is experimental and is configured with the `experimental.policies` array in `opencode.json`.

Policies are separate from [permissions](/docs/permissions). Permissions control what tools can do during a session, while policies control whether OpenCode may use a resource such as an LLM provider.

---

### [Configuration](#configuration)

Each policy statement has three fields:

* `effect` - Either `"allow"` or `"deny"`.
* `action` - The operation being controlled.
* `resource` - The resource ID or wildcard pattern the statement applies to.

For example, deny use of the `openai` provider:

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"experimental": {

"policies": [

{

"effect": "deny",

"action": "provider.use",

"resource": "openai"

}

]

}

}
```

A provider denied by policy is not available for model selection or model use, even if it has credentials or is otherwise configured correctly.

---

### [Available Policies](#available-policies)

OpenCode currently supports one policy action:

| Action | Resource | Description |
| --- | --- | --- |
| `provider.use` | Provider ID, such as `openai` | Allow or deny use of an LLM provider. |

More policy actions may be added in the future.

---

### [Matching](#matching)

The `resource` field supports wildcard matching. Use `*` to match zero or more characters and `?` to match one character.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"experimental": {

"policies": [

{

"effect": "deny",

"action": "provider.use",

"resource": "company-*"

}

]

}

}
```

This denies providers such as `company-us` and `company-eu`.

---

### [Rule Order](#rule-order)

When multiple statements match, the last matching statement wins. Put broad rules first, then more specific exceptions after them.

For example, allow only Anthropic:

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"experimental": {

"policies": [

{

"effect": "deny",

"action": "provider.use",

"resource": "*"

},

{

"effect": "allow",

"action": "provider.use",

"resource": "anthropic"

}

]

}

}
```

If no policy matches a provider, provider use is allowed by default.

Policies may be set in both your global config and project config. If policies from both locations match the same provider, your global policy takes priority over the project policy. This prevents a repository from re-enabling a provider that you deny globally.

---

### [Provider Lists](#provider-lists)

Use policies instead of the older `disabled_providers` and `enabled_providers` settings when controlling provider access.

To replace `disabled_providers`:

opencode.json

```
{

"experimental": {

"policies": [

{ "effect": "deny", "action": "provider.use", "resource": "openai" },

{ "effect": "deny", "action": "provider.use", "resource": "google" }

]

}

}
```

To replace `enabled_providers`, deny all providers first and allow the selected providers after it:

opencode.json

```
{

"experimental": {

"policies": [

{ "effect": "deny", "action": "provider.use", "resource": "*" },

{ "effect": "allow", "action": "provider.use", "resource": "anthropic" },

{ "effect": "allow", "action": "provider.use", "resource": "openai" }

]

}

}
```

[Edit page](https://github.com/anomalyco/opencode/edit/dev/packages/web/src/content/docs/policies.mdx)[Found a bug? Open an issue](https://github.com/anomalyco/opencode/issues/new)[Join our Discord community](https://opencode.ai/discord)  Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

© [Anomaly](https://anoma.ly)

Last updated: Oct 13, 2026

---
<!--
URL: https://opencode.ai/docs/plugins
title: Plugins | OpenCode
-->

[Skip to content](#_top)

[![](/docs/_astro/logo-dark.DOStV66V.svg) ![](/docs/_astro/logo-light.B0yzR0O5.svg)  OpenCode](/docs/)

[app.header.home](/)[app.header.docs](/v2/docs)

Search  `CtrlK`

Cancel

  [New OpenCode v2 is now available →](https://opencode.ai/v2)

* [Intro](/docs/)
* [Config](/docs/config/)
* [Providers](/docs/providers/)
* [Network](/docs/network/)
* [Enterprise](/docs/enterprise/)
* [Troubleshooting](/docs/troubleshooting/)
* [Windows](/docs/windows-wsl)
* Usage

  + [Go](https://opencode.ai/v2/docs/console/go/)
  + [TUI](/docs/tui/)
  + [CLI](/docs/cli/)
  + [Web](/docs/web/)
  + [IDE](/docs/ide/)
  + [Console](https://opencode.ai/v2/docs/console/)
  + [Share](/docs/share/)
  + [GitHub](/docs/github/)
  + [GitLab](/docs/gitlab/)
* Configure

  + [Tools](/docs/tools/)
  + [Rules](/docs/rules/)
  + [Agents](/docs/agents/)
  + [Models](/docs/models/)
  + [Themes](/docs/themes/)
  + [Keybinds](/docs/keybinds/)
  + [Commands](/docs/commands/)
  + [Formatters](/docs/formatters/)
  + [Permissions](/docs/permissions/)
  + [Policies](/docs/policies/)
  + [LSP Servers](/docs/lsp/)
  + [MCP servers](/docs/mcp-servers/)
  + [ACP Support](/docs/acp/)
  + [Agent Skills](/docs/skills/)
  + [References](/docs/references/)
  + [Custom Tools](/docs/custom-tools/)
* Develop

  + [SDK](/docs/sdk/)
  + [Server](/docs/server/)
  + [Plugins](/docs/plugins/)
  + [Ecosystem](/docs/ecosystem/)

[GitHub](https://github.com/anomalyco/opencode)[Discord](https://opencode.ai/discord)

  Select theme   DarkLightAuto         Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

On this page

* [Overview](#_top)
* [Use a plugin](#use-a-plugin)
  + [From local files](#from-local-files)
  + [From npm](#from-npm)
  + [How plugins are installed](#how-plugins-are-installed)
  + [Load order](#load-order)
* [Create a plugin](#create-a-plugin)
  + [Dependencies](#dependencies)
  + [Basic structure](#basic-structure)
  + [TypeScript support](#typescript-support)
  + [Events](#events)
* [Examples](#examples)
  + [Send notifications](#send-notifications)
  + [.env protection](#env-protection)
  + [Inject environment variables](#inject-environment-variables)
  + [Custom tools](#custom-tools)
  + [Logging](#logging)
  + [Compaction hooks](#compaction-hooks)

### On this page

* [Overview](#_top)
* [Use a plugin](#use-a-plugin)
  + [From local files](#from-local-files)
  + [From npm](#from-npm)
  + [How plugins are installed](#how-plugins-are-installed)
  + [Load order](#load-order)
* [Create a plugin](#create-a-plugin)
  + [Dependencies](#dependencies)
  + [Basic structure](#basic-structure)
  + [TypeScript support](#typescript-support)
  + [Events](#events)
* [Examples](#examples)
  + [Send notifications](#send-notifications)
  + [.env protection](#env-protection)
  + [Inject environment variables](#inject-environment-variables)
  + [Custom tools](#custom-tools)
  + [Logging](#logging)
  + [Compaction hooks](#compaction-hooks)

## Plugins

Write your own plugins to extend OpenCode.

Plugins allow you to extend OpenCode by hooking into various events and customizing behavior. You can create plugins to add new features, integrate with external services, or modify OpenCodeâs default behavior.

For examples, check out the [plugins](/docs/ecosystem#plugins) created by the community.

---

### [Use a plugin](#use-a-plugin)

There are two ways to load plugins.

---

#### [From local files](#from-local-files)

Place JavaScript or TypeScript files in the plugin directory.

* `.opencode/plugins/` - Project-level plugins
* `~/.config/opencode/plugins/` - Global plugins

Files in these directories are automatically loaded at startup.

---

#### [From npm](#from-npm)

Specify npm packages in your config file.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"plugin": ["opencode-helicone-session", "opencode-wakatime", "@my-org/custom-plugin"]

}
```

Both regular and scoped npm packages are supported.

Browse available plugins in the [ecosystem](/docs/ecosystem#plugins).

---

#### [How plugins are installed](#how-plugins-are-installed)

**npm plugins** are installed automatically using Bun at startup. Packages and their dependencies are cached in `~/.cache/opencode/node_modules/`.

**Local plugins** are loaded directly from the plugin directory. To use external packages, you must create a `package.json` within your config directory (see [Dependencies](#dependencies)), or publish the plugin to npm and [add it to your config](/docs/config#plugins).

---

#### [Load order](#load-order)

Plugins are loaded from all sources and all hooks run in sequence. The load order is:

1. Global config (`~/.config/opencode/opencode.json`)
2. Project config (`opencode.json`)
3. Global plugin directory (`~/.config/opencode/plugins/`)
4. Project plugin directory (`.opencode/plugins/`)

Duplicate npm packages with the same name and version are loaded once. However, a local plugin and an npm plugin with similar names are both loaded separately.

---

### [Create a plugin](#create-a-plugin)

A plugin is a **JavaScript/TypeScript module** that exports one or more plugin
functions. Each function receives a context object and returns a hooks object.

---

#### [Dependencies](#dependencies)

Local plugins and custom tools can use external npm packages. Add a `package.json` to your config directory with the dependencies you need.

.opencode/package.json

```
{

"dependencies": {

"shescape": "^2.1.0"

}

}
```

OpenCode runs `bun install` at startup to install these. Your plugins and tools can then import them.

.opencode/plugins/my-plugin.ts

```
import { escape } from "shescape"

export const MyPlugin = async (ctx) => {

return {

"tool.execute.before": async (input, output) => {

if (input.tool === "bash") {

output.args.command = escape(output.args.command)

}

},

}

}
```

---

#### [Basic structure](#basic-structure)

.opencode/plugins/example.js

```
export const MyPlugin = async ({ project, client, $, directory, worktree }) => {

console.log("Plugin initialized!")

return {

// Hook implementations go here

}

}
```

The plugin function receives:

* `project`: The current project information.
* `directory`: The current working directory.
* `worktree`: The git worktree path.
* `client`: An opencode SDK client for interacting with the AI.
* `$`: Bunâs [shell API](https://bun.com/docs/runtime/shell) for executing commands.

---

#### [TypeScript support](#typescript-support)

For TypeScript plugins, you can import types from the plugin package:

my-plugin.ts

```
import type { Plugin } from "@opencode-ai/plugin"

export const MyPlugin: Plugin = async ({ project, client, $, directory, worktree }) => {

return {

// Type-safe hook implementations

}

}
```

---

#### [Events](#events)

Plugins can subscribe to events as seen below in the Examples section. Here is a list of the different events available.

##### [Command Events](#command-events)

* `command.executed`

##### [File Events](#file-events)

* `file.edited`
* `file.watcher.updated`

##### [Installation Events](#installation-events)

* `installation.updated`

##### [LSP Events](#lsp-events)

* `lsp.client.diagnostics`
* `lsp.updated`

##### [Message Events](#message-events)

* `message.part.removed`
* `message.part.updated`
* `message.removed`
* `message.updated`

##### [Permission Events](#permission-events)

* `permission.asked`
* `permission.replied`

##### [Server Events](#server-events)

* `server.connected`

##### [Session Events](#session-events)

* `session.created`
* `session.compacted`
* `session.deleted`
* `session.diff`
* `session.error`
* `session.idle`
* `session.status`
* `session.updated`

##### [Shell Events](#shell-events)

* `shell.env`

##### [Tool Events](#tool-events)

* `tool.execute.after`
* `tool.execute.before`

##### [TUI Events](#tui-events)

* `tui.prompt.append`
* `tui.command.execute`
* `tui.toast.show`

---

### [Examples](#examples)

Here are some examples of plugins you can use to extend opencode.

---

#### [Send notifications](#send-notifications)

Send notifications when certain events occur:

.opencode/plugins/notification.js

```
export const NotificationPlugin = async ({ project, client, $, directory, worktree }) => {

return {

event: async ({ event }) => {

// Send notification on session completion

if (event.type === "session.idle") {

await $`osascript -e 'display notification "Session completed!" with title "opencode"'`

}

},

}

}
```

We are using `osascript` to run AppleScript on macOS. Here we are using it to send notifications.

Note

If youâre using the OpenCode desktop app, it can send system notifications automatically when a response is ready or when a session errors.

---

#### [.env protection](#env-protection)

Prevent opencode from reading `.env` files:

.opencode/plugins/env-protection.js

```
export const EnvProtection = async ({ project, client, $, directory, worktree }) => {

return {

"tool.execute.before": async (input, output) => {

if (input.tool === "read" && output.args.filePath.includes(".env")) {

throw new Error("Do not read .env files")

}

},

}

}
```

---

#### [Inject environment variables](#inject-environment-variables)

Inject environment variables into all shell execution (AI tools and user terminals):

.opencode/plugins/inject-env.js

```
export const InjectEnvPlugin = async () => {

return {

"shell.env": async (input, output) => {

output.env.MY_API_KEY = "secret"

output.env.PROJECT_ROOT = input.cwd

},

}

}
```

---

#### [Custom tools](#custom-tools)

Plugins can also add custom tools to opencode:

.opencode/plugins/custom-tools.ts

```
import { type Plugin, tool } from "@opencode-ai/plugin"

export const CustomToolsPlugin: Plugin = async (ctx) => {

return {

tool: {

mytool: tool({

description: "This is a custom tool",

args: {

foo: tool.schema.string(),

},

async execute(args, context) {

const { directory, worktree } = context

return `Hello ${args.foo} from ${directory} (worktree: ${worktree})`

},

}),

},

}

}
```

The `tool` helper creates a custom tool that opencode can call. It takes a Zod schema function and returns a tool definition with:

* `description`: What the tool does
* `args`: Zod schema for the toolâs arguments
* `execute`: Function that runs when the tool is called

Your custom tools will be available to opencode alongside built-in tools.

Note

If a plugin tool uses the same name as a built-in tool, the plugin tool takes precedence.

---

#### [Logging](#logging)

Use `client.app.log()` instead of `console.log` for structured logging:

.opencode/plugins/my-plugin.ts

```
export const MyPlugin = async ({ client }) => {

await client.app.log({

body: {

service: "my-plugin",

level: "info",

message: "Plugin initialized",

extra: { foo: "bar" },

},

})

}
```

Levels: `debug`, `info`, `warn`, `error`. See [SDK documentation](https://opencode.ai/docs/sdk) for details.

---

#### [Compaction hooks](#compaction-hooks)

Customize the context included when a session is compacted:

.opencode/plugins/compaction.ts

```
import type { Plugin } from "@opencode-ai/plugin"

export const CompactionPlugin: Plugin = async (ctx) => {

return {

"experimental.session.compacting": async (input, output) => {

// Inject additional context into the compaction prompt

output.context.push(`

### Custom Context

Include any state that should persist across compaction:

- Current task status

- Important decisions made

- Files being actively worked on

`)

},

}

}
```

The `experimental.session.compacting` hook fires before the LLM generates a continuation summary. Use it to inject domain-specific context that the default compaction prompt would miss.

You can also replace the compaction prompt entirely by setting `output.prompt`:

.opencode/plugins/custom-compaction.ts

```
import type { Plugin } from "@opencode-ai/plugin"

export const CustomCompactionPlugin: Plugin = async (ctx) => {

return {

"experimental.session.compacting": async (input, output) => {

// Replace the entire compaction prompt

output.prompt = `

You are generating a continuation prompt for a multi-agent swarm session.

Summarize:

1. The current task and its status

2. Which files are being modified and by whom

3. Any blockers or dependencies between agents

4. The next steps to complete the work

Format as a structured prompt that a new agent can use to resume work.

`

},

}

}
```

When `output.prompt` is set, it completely replaces the default compaction prompt. The `output.context` array is ignored in this case.

[Edit page](https://github.com/anomalyco/opencode/edit/dev/packages/web/src/content/docs/plugins.mdx)[Found a bug? Open an issue](https://github.com/anomalyco/opencode/issues/new)[Join our Discord community](https://opencode.ai/discord)  Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

© [Anomaly](https://anoma.ly)

Last updated: Oct 13, 2026

---
<!--
URL: https://opencode.ai/docs/github
title: GitHub | OpenCode
-->

[Skip to content](#_top)

[![](/docs/_astro/logo-dark.DOStV66V.svg) ![](/docs/_astro/logo-light.B0yzR0O5.svg)  OpenCode](/docs/)

[app.header.home](/)[app.header.docs](/v2/docs)

Search  `CtrlK`

Cancel

  [New OpenCode v2 is now available →](https://opencode.ai/v2)

* [Intro](/docs/)
* [Config](/docs/config/)
* [Providers](/docs/providers/)
* [Network](/docs/network/)
* [Enterprise](/docs/enterprise/)
* [Troubleshooting](/docs/troubleshooting/)
* [Windows](/docs/windows-wsl)
* Usage

  + [Go](https://opencode.ai/v2/docs/console/go/)
  + [TUI](/docs/tui/)
  + [CLI](/docs/cli/)
  + [Web](/docs/web/)
  + [IDE](/docs/ide/)
  + [Console](https://opencode.ai/v2/docs/console/)
  + [Share](/docs/share/)
  + [GitHub](/docs/github/)
  + [GitLab](/docs/gitlab/)
* Configure

  + [Tools](/docs/tools/)
  + [Rules](/docs/rules/)
  + [Agents](/docs/agents/)
  + [Models](/docs/models/)
  + [Themes](/docs/themes/)
  + [Keybinds](/docs/keybinds/)
  + [Commands](/docs/commands/)
  + [Formatters](/docs/formatters/)
  + [Permissions](/docs/permissions/)
  + [Policies](/docs/policies/)
  + [LSP Servers](/docs/lsp/)
  + [MCP servers](/docs/mcp-servers/)
  + [ACP Support](/docs/acp/)
  + [Agent Skills](/docs/skills/)
  + [References](/docs/references/)
  + [Custom Tools](/docs/custom-tools/)
* Develop

  + [SDK](/docs/sdk/)
  + [Server](/docs/server/)
  + [Plugins](/docs/plugins/)
  + [Ecosystem](/docs/ecosystem/)

[GitHub](https://github.com/anomalyco/opencode)[Discord](https://opencode.ai/discord)

  Select theme   DarkLightAuto         Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

On this page

* [Overview](#_top)
* [Features](#features)
* [Installation](#installation)
  + [Manual Setup](#manual-setup)
* [Configuration](#configuration)
* [Supported Events](#supported-events)
  + [Schedule Example](#schedule-example)
  + [Pull Request Example](#pull-request-example)
  + [Issues Triage Example](#issues-triage-example)
* [Custom prompts](#custom-prompts)
* [Examples](#examples)

### On this page

* [Overview](#_top)
* [Features](#features)
* [Installation](#installation)
  + [Manual Setup](#manual-setup)
* [Configuration](#configuration)
* [Supported Events](#supported-events)
  + [Schedule Example](#schedule-example)
  + [Pull Request Example](#pull-request-example)
  + [Issues Triage Example](#issues-triage-example)
* [Custom prompts](#custom-prompts)
* [Examples](#examples)

## GitHub

Use OpenCode in GitHub issues and pull-requests.

OpenCode integrates with your GitHub workflow. Mention `/opencode` or `/oc` in your comment, and OpenCode will execute tasks within your GitHub Actions runner.

---

### [Features](#features)

* **Triage issues**: Ask OpenCode to look into an issue and explain it to you.
* **Fix and implement**: Ask OpenCode to fix an issue or implement a feature. And it will work in a new branch and submits a PR with all the changes.
* **Secure**: OpenCode runs inside your GitHubâs runners.

---

### [Installation](#installation)

Run the following command in a project that is in a GitHub repo:

Terminal window

```
opencode github install
```

This will walk you through installing the GitHub app, creating the workflow, and setting up secrets.

---

#### [Manual Setup](#manual-setup)

Or you can set it up manually.

1. **Install the GitHub app**

   Head over to [**github.com/apps/opencode-agent**](https://github.com/apps/opencode-agent). Make sure itâs installed on the target repository.
2. **Add the workflow**

   Add the following workflow file to `.github/workflows/opencode.yml` in your repo. Make sure to set the appropriate `model` and required API keys in `env`.

   .github/workflows/opencode.yml

   ```
   name: opencode

   on:

   issue_comment:

   types: [created]

   pull_request_review_comment:

   types: [created]

   jobs:

   opencode:

   if: |

   contains(github.event.comment.body, '/oc') ||

   contains(github.event.comment.body, '/opencode')

   runs-on: ubuntu-latest

   permissions:

   id-token: write

   steps:

   - name: Checkout repository

   uses: actions/checkout@v6

   with:

   fetch-depth: 1

   persist-credentials: false

   - name: Run OpenCode

   uses: anomalyco/opencode/github@latest

   env:

   ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}

   with:

   model: anthropic/claude-sonnet-4-20250514

   # share: true
   ```
3. **Store the API keys in secrets**

   In your organization or project **settings**, expand **Secrets and variables** on the left and select **Actions**. And add the required API keys.

---

### [Configuration](#configuration)

* `model`: The model to use with OpenCode. Takes the format of `provider/model`. This is **required**.
* `agent`: The agent to use. Must be a primary agent. Falls back to `default_agent` from config or `"build"` if not found.
* `share`: Whether to share the OpenCode session. Defaults to **true** for public repositories.
* `prompt`: Optional custom prompt to override the default behavior. Use this to customize how OpenCode processes requests.
* `mentions`: Comma-separated list of trigger phrases, case-insensitive. Defaults to `/opencode,/oc`.
* `variant`: Model variant for provider-specific reasoning effort, for example `high`, `max`, or `minimal`.
* `oidc_base_url`: Base URL for the OIDC token exchange API. Only needed when running a custom GitHub App install. Defaults to `https://api.opencode.ai`.
* `use_github_token`: Set to `true` to use a caller-provided `GITHUB_TOKEN` instead of exchanging an OIDC token for an OpenCode App installation token. Defaults to `false`.

  Use this mode to run without installing the OpenCode GitHub App. Pass the token through `env` and grant the permissions required by your workflow:

  ```
  permissions:

  contents: write

  pull-requests: write

  issues: write

  steps:

  - uses: anomalyco/opencode/github@latest

  env:

  ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}

  GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

  with:

  model: anthropic/claude-sonnet-4-20250514

  use_github_token: true
  ```

  `id-token: write` is not required in this mode because OIDC exchange is skipped. To use a [personal access token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens) or another GitHub App token, store it as a secret and pass that secret as `GITHUB_TOKEN` instead.

---

### [Supported Events](#supported-events)

OpenCode can be triggered by the following GitHub events:

| Event Type | Triggered By | Details |
| --- | --- | --- |
| `issue_comment` | Comment on an issue or PR | Mention `/opencode` or `/oc` in your comment. OpenCode reads context and can create branches, open PRs, or reply. |
| `pull_request_review_comment` | Comment on specific code lines in a PR | Mention `/opencode` or `/oc` while reviewing code. OpenCode receives file path, line numbers, and diff context. |
| `issues` | Issue opened or edited | Automatically trigger OpenCode when issues are created or modified. Requires `prompt` input. |
| `pull_request` | PR opened or updated | Automatically trigger OpenCode when PRs are opened, synchronized, or reopened. Useful for automated reviews. |
| `schedule` | Cron-based schedule | Run OpenCode on a schedule. Requires `prompt` input. Output goes to logs and PRs (no issue to comment on). |
| `workflow_dispatch` | Manual trigger from GitHub UI | Trigger OpenCode on demand via Actions tab. Requires `prompt` input. Output goes to logs and PRs. |

#### [Schedule Example](#schedule-example)

Run OpenCode on a schedule to perform automated tasks:

.github/workflows/opencode-scheduled.yml

```
name: Scheduled OpenCode Task

on:

schedule:

- cron: "0 9 * * 1" # Every Monday at 9am UTC

jobs:

opencode:

runs-on: ubuntu-latest

permissions:

id-token: write

contents: write

pull-requests: write

issues: write

steps:

- name: Checkout repository

uses: actions/checkout@v6

with:

persist-credentials: false

- name: Run OpenCode

uses: anomalyco/opencode/github@latest

env:

ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}

with:

model: anthropic/claude-sonnet-4-20250514

prompt: |

Review the codebase for any TODO comments and create a summary.

If you find issues worth addressing, open an issue to track them.
```

For scheduled events, the `prompt` input is **required** since thereâs no comment to extract instructions from. Scheduled workflows run without a user context to permission-check, so the workflow must grant `contents: write` and `pull-requests: write` if you expect OpenCode to create branches or PRs.

---

#### [Pull Request Example](#pull-request-example)

Automatically review PRs when they are opened or updated:

.github/workflows/opencode-review.yml

```
name: opencode-review

on:

pull_request:

types: [opened, synchronize, reopened, ready_for_review]

jobs:

review:

runs-on: ubuntu-latest

permissions:

id-token: write

contents: read

pull-requests: read

issues: read

steps:

- uses: actions/checkout@v6

with:

persist-credentials: false

- uses: anomalyco/opencode/github@latest

env:

ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}

GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

with:

model: anthropic/claude-sonnet-4-20250514

use_github_token: true

prompt: |

Review this pull request:

- Check for code quality issues

- Look for potential bugs

- Suggest improvements
```

For `pull_request` events, if no `prompt` is provided, OpenCode defaults to reviewing the pull request.

---

#### [Issues Triage Example](#issues-triage-example)

Automatically triage new issues. This example filters to accounts older than 30 days to reduce spam:

.github/workflows/opencode-triage.yml

```
name: Issue Triage

on:

issues:

types: [opened]

jobs:

triage:

runs-on: ubuntu-latest

permissions:

id-token: write

contents: write

pull-requests: write

issues: write

steps:

- name: Check account age

id: check

uses: actions/github-script@v7

with:

script: |

const user = await github.rest.users.getByUsername({

username: context.payload.issue.user.login

});

const created = new Date(user.data.created_at);

const days = (Date.now() - created) / (1000 * 60 * 60 * 24);

return days >= 30;

result-encoding: string

- uses: actions/checkout@v6

if: steps.check.outputs.result == 'true'

with:

persist-credentials: false

- uses: anomalyco/opencode/github@latest

if: steps.check.outputs.result == 'true'

env:

ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}

with:

model: anthropic/claude-sonnet-4-20250514

prompt: |

Review this issue. If there's a clear fix or relevant docs:

- Provide documentation links

- Add error handling guidance for code examples

Otherwise, do not comment.
```

For `issues` events, the `prompt` input is **required** since thereâs no comment to extract instructions from.

---

### [Custom prompts](#custom-prompts)

Override the default prompt to customize OpenCodeâs behavior for your workflow.

.github/workflows/opencode.yml

```
- uses: anomalyco/opencode/github@latest

with:

model: anthropic/claude-sonnet-4-5

prompt: |

Review this pull request:

- Check for code quality issues

- Look for potential bugs

- Suggest improvements
```

This is useful for enforcing specific review criteria, coding standards, or focus areas relevant to your project.

---

### [Examples](#examples)

Here are some examples of how you can use OpenCode in GitHub.

* **Explain an issue**

  Add this comment in a GitHub issue.

  ```
  /opencode explain this issue
  ```

  OpenCode will read the entire thread, including all comments, and reply with a clear explanation.
* **Fix an issue**

  In a GitHub issue, say:

  ```
  /opencode fix this
  ```

  And OpenCode will create a new branch, implement the changes, and open a PR with the changes.
* **Review PRs and make changes**

  Leave the following comment on a GitHub PR.

  ```
  Delete the attachment from S3 when the note is removed /oc
  ```

  OpenCode will implement the requested change and commit it to the same PR.
* **Review specific code lines**

  Leave a comment directly on code lines in the PRâs âFilesâ tab. OpenCode automatically detects the file, line numbers, and diff context to provide precise responses.

  ```
  [Comment on specific lines in Files tab]

  /oc add error handling here
  ```

  When commenting on specific lines, OpenCode receives:

  + The exact file being reviewed
  + The specific lines of code
  + The surrounding diff context
  + Line number information

  This allows for more targeted requests without needing to specify file paths or line numbers manually.

[Edit page](https://github.com/anomalyco/opencode/edit/dev/packages/web/src/content/docs/github.mdx)[Found a bug? Open an issue](https://github.com/anomalyco/opencode/issues/new)[Join our Discord community](https://opencode.ai/discord)  Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

© [Anomaly](https://anoma.ly)

Last updated: Oct 13, 2026

---
<!--
URL: https://opencode.ai/docs/enterprise
title: Enterprise | OpenCode
-->

[Skip to content](#_top)

[![](/docs/_astro/logo-dark.DOStV66V.svg) ![](/docs/_astro/logo-light.B0yzR0O5.svg)  OpenCode](/docs/)

[app.header.home](/)[app.header.docs](/v2/docs)

Search  `CtrlK`

Cancel

  [New OpenCode v2 is now available →](https://opencode.ai/v2)

* [Intro](/docs/)
* [Config](/docs/config/)
* [Providers](/docs/providers/)
* [Network](/docs/network/)
* [Enterprise](/docs/enterprise/)
* [Troubleshooting](/docs/troubleshooting/)
* [Windows](/docs/windows-wsl)
* Usage

  + [Go](https://opencode.ai/v2/docs/console/go/)
  + [TUI](/docs/tui/)
  + [CLI](/docs/cli/)
  + [Web](/docs/web/)
  + [IDE](/docs/ide/)
  + [Console](https://opencode.ai/v2/docs/console/)
  + [Share](/docs/share/)
  + [GitHub](/docs/github/)
  + [GitLab](/docs/gitlab/)
* Configure

  + [Tools](/docs/tools/)
  + [Rules](/docs/rules/)
  + [Agents](/docs/agents/)
  + [Models](/docs/models/)
  + [Themes](/docs/themes/)
  + [Keybinds](/docs/keybinds/)
  + [Commands](/docs/commands/)
  + [Formatters](/docs/formatters/)
  + [Permissions](/docs/permissions/)
  + [Policies](/docs/policies/)
  + [LSP Servers](/docs/lsp/)
  + [MCP servers](/docs/mcp-servers/)
  + [ACP Support](/docs/acp/)
  + [Agent Skills](/docs/skills/)
  + [References](/docs/references/)
  + [Custom Tools](/docs/custom-tools/)
* Develop

  + [SDK](/docs/sdk/)
  + [Server](/docs/server/)
  + [Plugins](/docs/plugins/)
  + [Ecosystem](/docs/ecosystem/)

[GitHub](https://github.com/anomalyco/opencode)[Discord](https://opencode.ai/discord)

  Select theme   DarkLightAuto         Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

On this page

* [Overview](#_top)
* [Trial](#trial)
  + [Data handling](#data-handling)
  + [Code ownership](#code-ownership)
* [Pricing](#pricing)
* [Deployment](#deployment)
  + [Central Config](#central-config)
  + [SSO integration](#sso-integration)
  + [Internal AI gateway](#internal-ai-gateway)
  + [Self-hosting](#self-hosting)
* [FAQ](#faq)

### On this page

* [Overview](#_top)
* [Trial](#trial)
  + [Data handling](#data-handling)
  + [Code ownership](#code-ownership)
* [Pricing](#pricing)
* [Deployment](#deployment)
  + [Central Config](#central-config)
  + [SSO integration](#sso-integration)
  + [Internal AI gateway](#internal-ai-gateway)
  + [Self-hosting](#self-hosting)
* [FAQ](#faq)

## Enterprise

Using OpenCode securely in your organization.

OpenCode Enterprise is for organizations that want to ensure that their code and data never leaves their infrastructure. It can do this by using a centralized config that integrates with your SSO and internal AI gateway.

Note

OpenCode does not store any of your code or context data.

To get started with OpenCode Enterprise:

1. Do a trial internally with your team.
2. **[Contact us](https://opencode.ai/enterprise)** to discuss pricing and implementation options.

---

### [Trial](#trial)

OpenCode is open source and does not store any of your code or context data, so your developers can simply [get started](/docs/) and carry out a trial.

---

#### [Data handling](#data-handling)

**OpenCode does not store your code or context data.** All processing happens locally or through direct API calls to your AI provider.

This means that as long as you are using a provider you trust, or an internal
AI gateway, you can use OpenCode securely.

The only caveat here is the optional `/share` feature.

---

##### [Sharing conversations](#sharing-conversations)

If a user enables the `/share` feature, the conversation and the data associated with it are sent to the service we use to host these share pages at opencode.ai.

The data is currently served through our CDNâs edge network, and is cached on the edge near your users.

We recommend you disable this for your trial.

opencode.json

```
{

"$schema": "https://opencode.ai/config.json",

"share": "disabled"

}
```

[Learn more about sharing](/docs/share).

---

#### [Code ownership](#code-ownership)

**You own all code produced by OpenCode.** There are no licensing restrictions or ownership claims.

---

### [Pricing](#pricing)

We use a per-seat model for OpenCode Enterprise. If you have your own LLM gateway, we do not charge for tokens used. For further details about pricing and implementation options, **[contact us](https://opencode.ai/enterprise)**.

---

### [Deployment](#deployment)

Once you have completed your trial and you are ready to use OpenCode at
your organization, you can **[contact us](https://opencode.ai/enterprise)** to discuss
pricing and implementation options.

---

#### [Central Config](#central-config)

We can set up OpenCode to use a single central config for your entire organization.

This centralized config can integrate with your SSO provider and ensures all users access only your internal AI gateway.

---

#### [SSO integration](#sso-integration)

Through the central config, OpenCode can integrate with your organizationâs SSO provider for authentication.

This allows OpenCode to obtain credentials for your internal AI gateway through your existing identity management system.

---

#### [Internal AI gateway](#internal-ai-gateway)

With the central config, OpenCode can also be configured to use only your internal AI gateway.

You can also disable all other AI providers, ensuring all requests go through your organizationâs approved infrastructure.

---

#### [Self-hosting](#self-hosting)

While we recommend disabling the share pages to ensure your data never leaves
your organization, we can also help you self-host them on your infrastructure.

This is currently on our roadmap. If youâre interested, **[let us know](https://opencode.ai/enterprise)**.

---

### [FAQ](#faq)

What is OpenCode Enterprise?

OpenCode Enterprise is for organizations that want to ensure that their code and data never leaves their infrastructure. It can do this by using a centralized config that integrates with your SSO and internal AI gateway.

How do I get started with OpenCode Enterprise?

Simply start with an internal trial with your team. OpenCode by default does not store your code or context data, making it easy to get started.

Then **[contact us](https://opencode.ai/enterprise)** to discuss pricing and implementation options.

How does enterprise pricing work?

We offer per-seat enterprise pricing. If you have your own LLM gateway, we do not charge for tokens used. For further details, **[contact us](https://opencode.ai/enterprise)** for a custom quote based on your organizationâs needs.

Is my data secure with OpenCode Enterprise?

Yes. OpenCode does not store your code or context data. All processing happens locally or through direct API calls to your AI provider. With central config and SSO integration, your data remains secure within your organizationâs infrastructure.

Can we use our own private NPM registry?

OpenCode supports private npm registries through Bunâs native `.npmrc` file support. If your organization uses a private registry, such as JFrog Artifactory, Nexus, or similar, ensure developers are authenticated before running OpenCode.

To set up authentication with your private registry:

Terminal window

```
npm login --registry=https://your-company.jfrog.io/api/npm/npm-virtual/
```

This creates `~/.npmrc` with authentication details. OpenCode will automatically
pick this up.

Caution

You must be logged into the private registry before running OpenCode.

Alternatively, you can manually configure a `.npmrc` file:

~/.npmrc

```
registry=https://your-company.jfrog.io/api/npm/npm-virtual/

//your-company.jfrog.io/api/npm/npm-virtual/:_authToken=${NPM_AUTH_TOKEN}
```

Developers must be logged into the private registry before running OpenCode to ensure packages can be installed from your enterprise registry.

[Edit page](https://github.com/anomalyco/opencode/edit/dev/packages/web/src/content/docs/enterprise.mdx)[Found a bug? Open an issue](https://github.com/anomalyco/opencode/issues/new)[Join our Discord community](https://opencode.ai/discord)  Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

© [Anomaly](https://anoma.ly)

Last updated: Oct 13, 2026

---
<!--
URL: https://opencode.ai/docs/ecosystem
title: Ecosystem | OpenCode
-->

[Skip to content](#_top)

[![](/docs/_astro/logo-dark.DOStV66V.svg) ![](/docs/_astro/logo-light.B0yzR0O5.svg)  OpenCode](/docs/)

[app.header.home](/)[app.header.docs](/v2/docs)

Search  `CtrlK`

Cancel

  [New OpenCode v2 is now available →](https://opencode.ai/v2)

* [Intro](/docs/)
* [Config](/docs/config/)
* [Providers](/docs/providers/)
* [Network](/docs/network/)
* [Enterprise](/docs/enterprise/)
* [Troubleshooting](/docs/troubleshooting/)
* [Windows](/docs/windows-wsl)
* Usage

  + [Go](https://opencode.ai/v2/docs/console/go/)
  + [TUI](/docs/tui/)
  + [CLI](/docs/cli/)
  + [Web](/docs/web/)
  + [IDE](/docs/ide/)
  + [Console](https://opencode.ai/v2/docs/console/)
  + [Share](/docs/share/)
  + [GitHub](/docs/github/)
  + [GitLab](/docs/gitlab/)
* Configure

  + [Tools](/docs/tools/)
  + [Rules](/docs/rules/)
  + [Agents](/docs/agents/)
  + [Models](/docs/models/)
  + [Themes](/docs/themes/)
  + [Keybinds](/docs/keybinds/)
  + [Commands](/docs/commands/)
  + [Formatters](/docs/formatters/)
  + [Permissions](/docs/permissions/)
  + [Policies](/docs/policies/)
  + [LSP Servers](/docs/lsp/)
  + [MCP servers](/docs/mcp-servers/)
  + [ACP Support](/docs/acp/)
  + [Agent Skills](/docs/skills/)
  + [References](/docs/references/)
  + [Custom Tools](/docs/custom-tools/)
* Develop

  + [SDK](/docs/sdk/)
  + [Server](/docs/server/)
  + [Plugins](/docs/plugins/)
  + [Ecosystem](/docs/ecosystem/)

[GitHub](https://github.com/anomalyco/opencode)[Discord](https://opencode.ai/discord)

  Select theme   DarkLightAuto         Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

On this page

* [Overview](#_top)
* [Plugins](#plugins)
* [Projects](#projects)
* [Agents](#agents)

### On this page

* [Overview](#_top)
* [Plugins](#plugins)
* [Projects](#projects)
* [Agents](#agents)

## Ecosystem

Projects and integrations built with OpenCode.

A collection of community projects built on OpenCode.

Note

Want to add your OpenCode related project to this list? Submit a PR.

You can also check out [awesome-opencode](https://github.com/awesome-opencode/awesome-opencode) and [opencode.cafe](https://opencode.cafe), a community that aggregates the ecosystem and community.

---

### [Plugins](#plugins)

| Name | Description |
| --- | --- |
| [opencode-daytona](https://github.com/daytona/integrations/tree/main/packages/opencode-plugin) | Automatically run OpenCode sessions in isolated Daytona sandboxes with git sync and live previews |
| [opencode-helicone-session](https://github.com/H2Shami/opencode-helicone-session) | Automatically inject Helicone session headers for request grouping |
| [opencode-type-inject](https://github.com/nick-vi/opencode-type-inject) | Auto-inject TypeScript/Svelte types into file reads with lookup tools |
| [opencode-openai-codex-auth](https://github.com/numman-ali/opencode-openai-codex-auth) | Use your ChatGPT Plus/Pro subscription instead of API credits |
| [opencode-gemini-auth](https://github.com/jenslys/opencode-gemini-auth) | Use your existing Gemini plan instead of API billing |
| [opencode-antigravity-auth](https://github.com/NoeFabris/opencode-antigravity-auth) | Use Antigravityâs free models instead of API billing |
| [opencode-devcontainers](https://github.com/athal7/opencode-devcontainers) | Multi-branch devcontainer isolation with shallow clones and auto-assigned ports |
| [opencode-google-antigravity-auth](https://github.com/shekohex/opencode-google-antigravity-auth) | Google Antigravity OAuth Plugin, with support for Google Search, and more robust API handling |
| [opencode-dynamic-context-pruning](https://github.com/Tarquinen/opencode-dynamic-context-pruning) | Optimize token usage by pruning obsolete tool outputs |
| [opencode-vibeguard](https://github.com/inkdust2021/opencode-vibeguard) | Redact secrets/PII into VibeGuard-style placeholders before LLM calls; restore locally |
| [opencode-websearch-cited](https://github.com/ghoulr/opencode-websearch-cited.git) | Add native websearch support for supported providers with Google grounded style |
| [opencode-pty](https://github.com/shekohex/opencode-pty.git) | Enables AI agents to run background processes in a PTY, send interactive input to them. |
| [opencode-shell-strategy](https://github.com/JRedeker/opencode-shell-strategy) | Instructions for non-interactive shell commands - prevents hangs from TTY-dependent operations |
| [opencode-wakatime](https://github.com/angristan/opencode-wakatime) | Track OpenCode usage with Wakatime |
| [opencode-md-table-formatter](https://github.com/franlol/opencode-md-table-formatter/tree/main) | Clean up markdown tables produced by LLMs |
| [opencode-morph-fast-apply](https://github.com/JRedeker/opencode-morph-fast-apply) | 10x faster code editing with Morph Fast Apply API and lazy edit markers |
| [opencode-morph-plugin](https://github.com/morphllm/opencode-morph-plugin) | Fast Apply editing, WarpGrep codebase search, and context compaction via Morph |
| [oh-my-opencode](https://github.com/code-yeongyu/oh-my-opencode) | Background agents, pre-built LSP/AST/MCP tools, curated agents, Claude Code compatible |
| [opencode-notificator](https://github.com/panta82/opencode-notificator) | Desktop notifications and sound alerts for OpenCode sessions |
| [opencode-notifier](https://github.com/mohak34/opencode-notifier) | Desktop notifications and sound alerts for permission, completion, and error events |
| [opencode-zellij-namer](https://github.com/24601/opencode-zellij-namer) | AI-powered automatic Zellij session naming based on OpenCode context |
| [opencode-skillful](https://github.com/zenobi-us/opencode-skillful) | Allow OpenCode agents to lazy load prompts on demand with skill discovery and injection |
| [opencode-supermemory](https://github.com/supermemoryai/opencode-supermemory) | Persistent memory across sessions using Supermemory |
| [@plannotator/opencode](https://github.com/backnotprop/plannotator/tree/main/apps/opencode-plugin) | Interactive plan review with visual annotation and private/offline sharing |
| [@openspoon/subtask2](https://github.com/spoons-and-mirrors/subtask2) | Extend opencode /commands into a powerful orchestration system with granular flow control |
| [opencode-scheduler](https://github.com/different-ai/opencode-scheduler) | Schedule recurring jobs using launchd (Mac) or systemd (Linux) with cron syntax |
| [opencode-conductor](https://github.com/derekbar90/opencode-conductor) | Protocol-Driven Workflow: Automation of the Context -> Spec -> Plan -> Implement lifecycle. |
| [micode](https://github.com/vtemian/micode) | Structured Brainstorm â Plan â Implement workflow with session continuity |
| [octto](https://github.com/vtemian/octto) | Interactive browser UI for AI brainstorming with multi-question forms |
| [opencode-background-agents](https://github.com/kdcokenny/opencode-background-agents) | Claude Code-style background agents with async delegation and context persistence |
| [opencode-notify](https://github.com/kdcokenny/opencode-notify) | Native OS notifications for OpenCode â know when tasks complete |
| [opencode-workspace](https://github.com/kdcokenny/opencode-workspace) | Bundled multi-agent orchestration harness â 16 components, one install |
| [opencode-worktree](https://github.com/kdcokenny/opencode-worktree) | Zero-friction git worktrees for OpenCode |
| [opencode-sentry-monitor](https://github.com/stolinski/opencode-sentry-monitor) | Trace and debug your AI agents with Sentry AI Monitoring |
| [opencode-firecrawl](https://github.com/firecrawl/opencode-firecrawl) | Web scraping, crawling, and search via the Firecrawl CLI |
| [opencode-jfrog-plugin](https://github.com/jfrog/opencode-jfrog-plugin) | JFrog Plugin for seamless integration of Opencode users to JFrog platform |
| [opencode-goal-plugin](https://github.com/willytop8/OpenCode-goal-plugin) | Session-scoped `/goal` workflow that keeps objectives in context and auto-continues until complete |
| [opencode-tavily](https://github.com/tavily-ai/opencode-tavily) | Web search, extraction, crawling, and deep research via the Tavily CLI |
| [opencode-supabase](https://github.com/supabase-community/opencode-supabase) | Supabase plugin for OpenCode: account login, Management API tools, bundled Supabase agent skills, and guided Supabase MCP setup. |

---

### [Projects](#projects)

| Name | Description |
| --- | --- |
| [kimaki](https://kimaki.dev) | Discord bot to control OpenCode sessions, built on the SDK |
| [opencode.nvim](https://github.com/NickvanDyke/opencode.nvim) | Neovim plugin for editor-aware prompts, built on the API |
| [portal](https://github.com/hosenur/portal) | Mobile-first web UI for OpenCode over Tailscale/VPN |
| [opencode plugin template](https://github.com/zenobi-us/opencode-plugin-template/) | Template for building OpenCode plugins |
| [opencode.nvim](https://github.com/sudo-tee/opencode.nvim) | Neovim frontend for opencode - a terminal-based AI coding agent |
| [ai-sdk-provider-opencode-sdk](https://github.com/ben-vargas/ai-sdk-provider-opencode-sdk) | Vercel AI SDK provider for using OpenCode via @opencode-ai/sdk |
| [OpenChamber](https://github.com/btriapitsyn/openchamber) | Web / Desktop App and VS Code Extension for OpenCode |
| [OpenCode-Obsidian](https://github.com/mtymek/opencode-obsidian) | Obsidian plugin that embeds OpenCode in Obsidianâs UI |
| [OpenWork](https://github.com/different-ai/openwork) | An open-source alternative to Claude Cowork, powered by OpenCode |
| [ocx](https://github.com/kdcokenny/ocx) | OpenCode extension manager with portable, isolated profiles. |
| [CodeNomad](https://github.com/NeuralNomadsAI/CodeNomad) | Desktop, Web, Mobile and Remote Client App for OpenCode |

---

### [Agents](#agents)

| Name | Description |
| --- | --- |
| [Agentic](https://github.com/Cluster444/agentic) | Modular AI agents and commands for structured development |
| [opencode-agents](https://github.com/darrenhinde/opencode-agents) | Configs, prompts, agents, and plugins for enhanced workflows |

[Edit page](https://github.com/anomalyco/opencode/edit/dev/packages/web/src/content/docs/ecosystem.mdx)[Found a bug? Open an issue](https://github.com/anomalyco/opencode/issues/new)[Join our Discord community](https://opencode.ai/discord)  Select language   EnglishØ§ÙØ¹Ø±Ø¨ÙØ©BosanskiDanskDeutschEspaÃ±olFranÃ§aisItalianoæ¥æ¬èªíêµ­ì´Norsk BokmÃ¥lPolskiPortuguÃªs (Brasil)Ð ÑÑÑÐºÐ¸Ð¹à¹à¸à¸¢TÃ¼rkÃ§eç®ä½ä¸­æç¹é«ä¸­æ

© [Anomaly](https://anoma.ly)

Last updated: Oct 13, 2026

---