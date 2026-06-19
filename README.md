# ClaudeDeepSeek

Tiny wrapper for running Claude Code with DeepSeek.

## Commands

| Command     | Main Model          | Subagent Model      |
|-------------|---------------------|---------------------|
| `cld`       | deepseek-v4-pro     | deepseek-v4-flash   |
| `cld-pro`   | deepseek-v4-pro     | deepseek-v4-flash   |
| `cld-flash` | deepseek-v4-flash   | deepseek-v4-flash   |
| `cld-key`   | update API key      | —                   |

`cld` is the daily driver (Pro main + Flash subagents for efficiency).
`cld-flash` saves tokens by running everything on Flash.

## Prerequisite

Install Claude Code CLI first:

```sh
npm install -g @anthropic-ai/claude-code
```

Confirm it works:

```sh
claude --version
```

## Install

macOS/Linux:

```sh
curl -fsSL https://raw.githubusercontent.com/aldeniaalexandra/claude-deepseek/main/install.sh | bash
```

Windows PowerShell:

```powershell
irm https://raw.githubusercontent.com/aldeniaalexandra/claude-deepseek/main/install.ps1 | iex
```

The installer asks for your DeepSeek API key once.

On Windows, commands work from PowerShell and Command Prompt after opening a new terminal.

If you cloned the repository and are installing from Command Prompt, run:

```bat
install.cmd
```

Open a new terminal after install, then run:

```sh
cld --version
```

## Usage

```sh
cld                  # start Claude Code with DeepSeek Pro
cld-pro              # same, explicit
cld-flash            # Flash model (cheaper)
cld --version        # extra args passed to claude
```

## Change API Key

```sh
cld-key
```

This prompts for a new DeepSeek API key.

## What It Sets

The wrapper sets these environment variables only while launching Claude Code:

```sh
ANTHROPIC_BASE_URL=https://api.deepseek.com/anthropic
ANTHROPIC_AUTH_TOKEN=<your DeepSeek API key>
CLAUDE_CODE_SUBAGENT_MODEL=deepseek-v4-flash
ANTHROPIC_MODEL=deepseek-v4-pro[1m]   # or deepseek-v4-flash with cld-flash
```

## Troubleshooting

If Claude Code CLI is missing, install it:

```sh
npm install -g @anthropic-ai/claude-code
```

If your DeepSeek API key is missing or needs to change:

```sh
cld-key
```

If a command is not recognized right after install:

macOS/Linux:

```sh
export PATH="$HOME/.local/bin:$PATH"
```

Windows PowerShell:

```powershell
Import-Module ClaudeDeepSeek
```
