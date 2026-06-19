# ClaudeDeepSeek

Tiny wrapper for running Claude Code with DeepSeek.

After setup, start Claude Code with DeepSeek using:

```sh
cld
```

or:

```sh
claude-deepseek
```

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

On Windows, `cld` works from PowerShell and Command Prompt after opening a new terminal.

If you cloned the repository and are installing from Command Prompt, run:

```bat
install.cmd
```

Open a new terminal after install, then run:

```sh
cld
```

## Usage

Start Claude Code with DeepSeek:

```sh
cld
```

The long command does the same thing:

```sh
claude-deepseek
```

Extra arguments are passed to `claude`:

```sh
cld --version
```

## Change API Key

Run:

```sh
cld-key
```

This prompts for a new DeepSeek API key.

## What It Sets

The wrapper sets these environment variables only while launching Claude Code:

```sh
ANTHROPIC_BASE_URL=https://api.deepseek.com/anthropic
ANTHROPIC_AUTH_TOKEN=<your DeepSeek API key>
ANTHROPIC_MODEL=deepseek-v4-pro[1m]
ANTHROPIC_DEFAULT_OPUS_MODEL=deepseek-v4-pro[1m]
ANTHROPIC_DEFAULT_SONNET_MODEL=deepseek-v4-pro[1m]
ANTHROPIC_DEFAULT_HAIKU_MODEL=deepseek-v4-flash
CLAUDE_CODE_SUBAGENT_MODEL=deepseek-v4-flash
CLAUDE_CODE_EFFORT_LEVEL=max
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

If `cld` is not recognized right after install:

macOS/Linux:

```sh
export PATH="$HOME/.local/bin:$PATH"
```

Windows PowerShell:

```powershell
Import-Module ClaudeDeepSeek
```
