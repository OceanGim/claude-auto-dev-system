# Claude Auto-Dev System

[English](#claude-auto-dev-system) | [한국어](#claude-auto-dev-system-한국어)

**Turn Claude Code into an autonomous development partner with persistent memory, architecture enforcement, and team orchestration.**

> A production-tested framework extracted from a real Electron + TypeScript + DDD project.
> Drop it into any project — Claude Code becomes session-aware, architecture-enforcing, and team-ready.

## What This Does

Without this system, every Claude Code session starts from zero. With it:

| Problem | Solution |
|---------|----------|
| Claude forgets what you did last session | **Session Restore** hook auto-detects in-progress work |
| Claude doesn't know your project's architecture rules | **Architecture Guard** hooks block violations + inject context |
| External research gets lost between sessions | **Research Cache** forces all WebSearch/Context7 results into local docs |
| No progress tracking across sessions | **Hierarchical TODO** system with phase dashboard + work log |
| Manual "read this file first" every time | **Intent Router** auto-suggests relevant docs based on keywords |
| Claude marks things done without asking | **No Unilateral Completion** rule — only you decide when tasks are done |
| Claude moves on without committing | **Task Completion Guard** warns about uncommitted changes before new work |
| Doc cross-references break silently | **Document Link Guard** hook tracks backlinks + validates links |
| Scaling to parallel work is manual | **Agent Teams** with role-based agents + file conflict prevention |

## System Architecture

```
┌─────────────────────────────────────────────────────────┐
│                   Claude Code Session                    │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  CLAUDE.md ──> Auto Behaviors (6 protocols)             │
│       │        Planning | Coding | Review               │
│       │        Wrap | Research | Git                     │
│       │                                                 │
│       ▼                                                 │
│  .claude/                                               │
│  ├── settings.json ── Hook wiring + permissions         │
│  ├── hooks/ ───────── 11 shell scripts                  │
│  │   ├── SessionStart ──> session-restore.sh            │
│  │   ├── UserPromptSubmit ─┬> intent-router.sh          │
│  │   │                     └> task-completion-guard.sh   │
│  │   ├── PreToolUse ──┬──> research-cache-guard.sh      │
│  │   │                ├──> research-cache-check.sh      │
│  │   │                ├──> arch-guard.sh                │
│  │   │                ├──> arch-docs-guard.sh           │
│  │   │                └──> arch-commit-guard.sh         │
│  │   └── PostToolUse ─┬──> research-cache-remind.sh     │
│  │                    ├──> arch-post-check.sh           │
│  │                    └──> doc-link-guard.sh            │
│  ├── commands/ ────── 6 slash commands                  │
│  │   /begin /wrap /todo /commit /build /review          │
│  ├── skills/ ──────── Domain knowledge                  │
│  │   work-init (3-doc memory) + team (agent teams)      │
│  └── agents/ ──────── Teammate role definitions         │
│      backend + frontend + test-engineer + docs-writer   │
│                                                         │
│  Persistent State                                       │
│  ├── docs/PROJECT_TODO.md ─── Phase Dashboard           │
│  ├── docs/phases/*.md ─────── Task Checkboxes           │
│  ├── docs/work/*/ ─────────── Active Task Memory        │
│  ├── docs/research/ ───────── Cached External Knowledge │
│  └── LESSONS.md ───────────── Mistake Patterns          │
└─────────────────────────────────────────────────────────┘
```

## Quick Start

```bash
# 1. Clone this repo somewhere accessible
git clone https://github.com/oceangim/claude-auto-dev-system.git

# 2. Go to YOUR project
cd /path/to/your-project

# 3. Run setup (creates .claude/, docs/, CLAUDE.md, LESSONS.md)
bash /path/to/claude-auto-dev-system/setup.sh

# 4. Customize (replace {{PLACEHOLDER}} values)
#    - CLAUDE.md: project name, tech stack, coding standards
#    - .claude/hooks/arch-guard.sh: your architecture rules
#    - .claude/hooks/intent-router.sh: your keyword→doc mappings
#    - .claude/agents/*.md: your team role definitions

# 5. Start a session
#    Type /begin in Claude Code
```

## What Gets Created

```
your-project/
├── CLAUDE.md                          # Project config + auto behaviors
├── LESSONS.md                         # Mistake pattern tracker
├── .claude/
│   ├── settings.json                  # Hook wiring + permissions
│   ├── settings.local.json            # MCP + model settings
│   ├── hooks/
│   │   ├── session-restore.sh         # Detects in-progress work on session start
│   │   ├── intent-router.sh           # Suggests relevant docs by keyword
│   │   ├── task-completion-guard.sh   # Warns about uncommitted changes
│   │   ├── research-cache-guard.sh    # Blocks until research is cached
│   │   ├── research-cache-check.sh    # Checks cache before external calls
│   │   ├── research-cache-remind.sh   # Forces caching after external calls
│   │   ├── arch-guard.sh             # Blocks architecture violations
│   │   ├── arch-docs-guard.sh        # Warns on terminology misuse in docs
│   │   ├── arch-commit-guard.sh      # Warns on cross-module commits
│   │   ├── arch-post-check.sh        # Reminds verification after code writes
│   │   └── doc-link-guard.sh         # Enforces backlink + registry updates on doc edits
│   ├── commands/
│   │   ├── begin.md                   # /begin — start session, read state
│   │   ├── wrap.md                    # /wrap — end session, update TODO
│   │   ├── todo.md                    # /todo — manage tasks
│   │   ├── commit.md                  # /commit — conventional commits
│   │   ├── build.md                   # /build — orchestrate parallel builds
│   │   └── review.md                  # /review — quality gate reviews
│   ├── skills/
│   │   ├── work-init/SKILL.md         # 3-doc task memory system
│   │   └── team/SKILL.md             # Agent team management
│   └── agents/
│       ├── backend-developer.md
│       ├── frontend-developer.md
│       ├── test-engineer.md
│       └── docs-writer.md
└── docs/
    ├── PROJECT_TODO.md                # Phase dashboard + work log
    ├── phases/                        # Task checkboxes per phase
    ├── work/                          # Active task memory (3-doc folders)
    └── research/
        ├── 00_INDEX.md                # Research cache index
        ├── TEMPLATE.md                # Cache document template
        ├── searches/                  # WebSearch results
        ├── apis/                      # WebFetch results
        └── libraries/                 # Context7 library docs
```

## Components

### Hooks (11 scripts)

The core automation layer. Shell scripts that fire on Claude Code events.

| Hook | Event | What It Does |
|------|-------|-------------|
| **session-restore** | SessionStart | Scans `docs/work/` for IN PROGRESS tasks, injects context so Claude resumes where you left off |
| **intent-router** | UserPromptSubmit | Pattern-matches your prompt against keywords, suggests relevant project docs to read first |
| **task-completion-guard** | UserPromptSubmit | Checks for uncommitted code changes before new work starts, reminds to `/commit` + `/wrap` |
| **research-cache-check** | PreToolUse | Before any WebSearch/WebFetch/Context7 call, checks if the answer is already cached locally |
| **research-cache-guard** | PreToolUse | If a previous research result hasn't been cached yet, **blocks all other tool calls** until you cache or skip it |
| **research-cache-remind** | PostToolUse | After any external lookup completes, creates a pending state that triggers the guard |
| **arch-guard** | PreToolUse | **Blocks** architecture violations (e.g., infrastructure imports in domain layer) and injects layer-specific guidance |
| **arch-docs-guard** | PreToolUse | **Warns** (asks permission) when documentation uses wrong domain terminology |
| **arch-commit-guard** | PreToolUse | **Warns** when a git commit touches multiple modules/domains |
| **arch-post-check** | PostToolUse | After writing code, reminds a verification checklist specific to that layer |
| **doc-link-guard** | PostToolUse | After editing docs, detects cross-reference links and reminds to update backlinks + `LINK_REGISTRY.md` |

### Slash Commands (6 commands)

| Command | Purpose |
|---------|---------|
| `/begin` | Start session: reads TODO state, finds in-progress work, suggests next task |
| `/wrap` | End session: marks progress, writes work log, commits, updates LESSONS.md |
| `/todo [op]` | Manage tasks: `status`, `start`, `done`, `add`, `block`, `log`, `next`, `phase`, `history` |
| `/commit` | Git commit: analyzes diff, generates conventional commit message, updates work log |
| `/build` | Build orchestrator: loads task specs, spawns agent teams, runs quality gates |
| `/review` | Quality review: pre-build spec check, code review, integration test, phase validation |

### Skills (2 skills)

| Skill | Triggers On | What It Does |
|-------|------------|-------------|
| **work-init** | Tasks touching 3+ files or spanning multiple sessions | Creates `docs/work/{task}/` with plan.md + context.md + checklist.md |
| **team** | Parallel work needed across domains | Defines agent team patterns, spawn procedures, file conflict prevention |

### Agents (4 roles)

| Agent | Model | Domain |
|-------|-------|--------|
| **backend-developer** | opus | Domain logic, database, API, external integrations |
| **frontend-developer** | opus | UI components, pages, state management |
| **test-engineer** | opus | Unit, integration, E2E tests across all packages |
| **docs-writer** | sonnet | Documentation consistency, work logs, README |

### TODO System (3 levels)

```
Level 1: docs/PROJECT_TODO.md     — Phase Dashboard, Milestones, Work Log
Level 2: docs/phases/*.md          — Task checkboxes with status markers
Level 3: docs/work/{task}/         — Active task memory (plan + context + checklist)
```

### Research Cache

Forces Claude to save all external research locally. No more re-searching the same things.

```
Flow: External call → PostToolUse creates pending state → All tools blocked
      → Claude saves to docs/research/{category}/{slug}.md → Updates 00_INDEX.md
      → Block cleared → Normal operation resumes
```

## Customization

### Choose Your Hook Level

| Level | Hooks | Best For |
|-------|-------|----------|
| **Minimal** | session-restore + intent-router + task-completion-guard | Personal projects, quick iterations |
| **Standard** | + research-cache (3 scripts) + doc-link-guard | Medium projects, external API usage |
| **Full** | + arch-guard (4 scripts) | Large projects, team dev, architecture matters |

To disable hooks you don't need, remove their entries from `.claude/settings.json`.

### Customize Architecture Guard

Edit `.claude/hooks/arch-guard.sh` — the template includes examples for:

| Pattern | Guard Strategy |
|---------|---------------|
| **DDD** | Block infra imports in domain layer, inject bounded context info |
| **Clean Architecture** | Block framework imports in entities, inject layer responsibilities |
| **MVC** | Block view imports in models, inject MVC responsibilities |
| **Modular Monolith** | Block cross-module direct imports, inject module boundaries |

### Customize Intent Router

Edit `.claude/hooks/intent-router.sh` — add keyword→doc mappings:

```bash
# Example: when user mentions "auth", suggest auth docs
if echo "$PROMPT" | grep -qiE 'auth|login|OAuth|JWT'; then
  SUGGESTIONS="${SUGGESTIONS}
- Auth Architecture: docs/auth-design.md"
fi
```

### Customize Agents

Edit `.claude/agents/*.md` — define domains, responsibilities, and rules for each teammate role.

## Project Type Recommendations

| Project Type | Hooks | Commands | Agents |
|-------------|-------|----------|--------|
| **Full-stack Web App** | Full | All 6 | backend + frontend + test |
| **Backend API** | arch + research + session | begin/wrap/todo/commit | backend + test |
| **Frontend SPA** | research + session | begin/wrap/todo/commit | frontend + test |
| **Library/SDK** | arch + research | begin/wrap/todo/commit | backend + test + docs |
| **Data Pipeline** | research + session | begin/wrap/todo/commit | backend + test |
| **Mobile App** | Full | All 6 | mobile + frontend + test |

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI installed
- `jq` available in PATH (used by hook scripts)
- Bash 4+ (macOS and Linux compatible)

## FAQ

**Q: Does this work with any programming language?**
A: Yes. The hooks, commands, and TODO system are language-agnostic. Only the architecture guard needs customization for your specific patterns.

**Q: Will this conflict with my existing CLAUDE.md?**
A: The setup script skips existing files. You can merge the Auto Behaviors section manually.

**Q: How do I disable a specific hook?**
A: Remove its entry from `.claude/settings.json` under the relevant event.

**Q: Does this work without MCP servers?**
A: Yes. MCP-related features (Context7, Sequential Thinking) are optional. The research cache gracefully handles their absence.

## Origin

Extracted and generalized from [ZeroO2 v3](https://zeroo2.ai) — an Electron + TypeScript + DDD desktop application with 100+ tasks across 5 development phases. Every component was battle-tested over weeks of real development before being standardized into this template.

## License

MIT

---

# Claude Auto-Dev System (한국어)

[English](#claude-auto-dev-system) | [한국어](#claude-auto-dev-system-한국어)

**Claude Code를 자율 개발 파트너로 만들어주는 프레임워크. 세션 간 기억 유지, 아키텍처 규칙 강제, 팀 오케스트레이션까지.**

> 실제 Electron + TypeScript + DDD 프로젝트에서 실전 검증된 프레임워크입니다.
> 아무 프로젝트에나 적용하면 Claude Code가 세션을 기억하고, 아키텍처를 지키고, 팀으로 일합니다.

## 이 시스템이 해결하는 문제

시스템 없이는 Claude Code가 매 세션마다 처음부터 시작합니다. 이 시스템을 쓰면:

| 문제 | 해결책 |
|------|--------|
| Claude가 지난 세션 작업을 잊음 | **Session Restore** 훅이 진행 중인 작업을 자동 감지 |
| Claude가 프로젝트 아키텍처 규칙을 모름 | **Architecture Guard** 훅이 위반을 차단하고 레이어별 컨텍스트 주입 |
| 외부 조사 결과가 세션 간에 유실됨 | **Research Cache**가 모든 WebSearch/Context7 결과를 로컬에 강제 저장 |
| 세션 간 진행 상황 추적 불가 | **계층적 TODO** 시스템 (페이즈 대시보드 + 작업 로그) |
| 매번 수동으로 "이 파일 먼저 읽어" | **Intent Router**가 키워드 기반으로 관련 문서 자동 추천 |
| Claude가 마음대로 작업 완료 처리 | **No Unilateral Completion** 규칙 — 완료 결정은 사용자만 |
| Claude가 커밋 없이 다음 작업으로 넘어감 | **Task Completion Guard**가 커밋되지 않은 변경사항을 경고 |
| 문서 간 참조가 조용히 깨짐 | **Document Link Guard** 훅이 백링크 + 레지스트리 업데이트 강제 |
| 병렬 작업 확장이 수동 | **Agent Teams** — 역할 기반 에이전트 + 파일 충돌 방지 |

## 시스템 구조

```
┌─────────────────────────────────────────────────────────┐
│                   Claude Code 세션                       │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  CLAUDE.md ──> 자동 동작 (6가지 프로토콜)                  │
│       │        계획 | 코딩 | 리뷰                         │
│       │        마무리 | 리서치 | Git                       │
│       │                                                 │
│       ▼                                                 │
│  .claude/                                               │
│  ├── settings.json ── 훅 연결 + 권한 설정                  │
│  ├── hooks/ ───────── 11개 셸 스크립트                     │
│  │   ├── SessionStart ──> session-restore.sh            │
│  │   ├── UserPromptSubmit ─┬> intent-router.sh          │
│  │   │                     └> task-completion-guard.sh   │
│  │   ├── PreToolUse ──┬──> research-cache-guard.sh      │
│  │   │                ├──> research-cache-check.sh      │
│  │   │                ├──> arch-guard.sh                │
│  │   │                ├──> arch-docs-guard.sh           │
│  │   │                └──> arch-commit-guard.sh         │
│  │   └── PostToolUse ─┬──> research-cache-remind.sh     │
│  │                    ├──> arch-post-check.sh           │
│  │                    └──> doc-link-guard.sh            │
│  ├── commands/ ────── 6개 슬래시 커맨드                    │
│  │   /begin /wrap /todo /commit /build /review          │
│  ├── skills/ ──────── 도메인 지식                         │
│  │   work-init (3문서 메모리) + team (에이전트 팀)         │
│  └── agents/ ──────── 팀원 역할 정의                      │
│      backend + frontend + test-engineer + docs-writer   │
│                                                         │
│  영속 상태                                                │
│  ├── docs/PROJECT_TODO.md ─── 페이즈 대시보드              │
│  ├── docs/phases/*.md ─────── 태스크 체크박스              │
│  ├── docs/work/*/ ─────────── 활성 태스크 메모리           │
│  ├── docs/research/ ───────── 캐시된 외부 조사 결과        │
│  └── LESSONS.md ───────────── 실수 패턴 기록              │
└─────────────────────────────────────────────────────────┘
```

## 빠른 시작

```bash
# 1. 이 저장소를 클론
git clone https://github.com/oceangim/claude-auto-dev-system.git

# 2. 내 프로젝트로 이동
cd /path/to/your-project

# 3. 셋업 실행 (.claude/, docs/, CLAUDE.md, LESSONS.md 생성)
bash /path/to/claude-auto-dev-system/setup.sh

# 4. 커스터마이즈 ({{PLACEHOLDER}} 값을 내 프로젝트에 맞게 수정)
#    - CLAUDE.md: 프로젝트명, 기술 스택, 코딩 규칙
#    - .claude/hooks/arch-guard.sh: 아키텍처 규칙
#    - .claude/hooks/intent-router.sh: 키워드→문서 매핑
#    - .claude/agents/*.md: 팀원 역할 정의

# 5. 세션 시작
#    Claude Code에서 /begin 입력
```

## 생성되는 파일 구조

```
your-project/
├── CLAUDE.md                          # 프로젝트 설정 + 자동 동작 규칙
├── LESSONS.md                         # 실수 패턴 추적
├── .claude/
│   ├── settings.json                  # 훅 연결 + 권한
│   ├── settings.local.json            # MCP + 모델 설정
│   ├── hooks/
│   │   ├── session-restore.sh         # 세션 시작 시 진행 중 작업 감지
│   │   ├── intent-router.sh           # 키워드 기반 관련 문서 추천
│   │   ├── task-completion-guard.sh   # 커밋 안 된 변경사항 경고
│   │   ├── research-cache-guard.sh    # 리서치 캐시 완료까지 도구 차단
│   │   ├── research-cache-check.sh    # 외부 호출 전 캐시 확인
│   │   ├── research-cache-remind.sh   # 외부 호출 후 캐싱 강제
│   │   ├── arch-guard.sh             # 아키텍처 위반 차단
│   │   ├── arch-docs-guard.sh        # 문서 내 용어 오용 경고
│   │   ├── arch-commit-guard.sh      # 모듈 간 혼합 커밋 경고
│   │   ├── arch-post-check.sh        # 코드 작성 후 검증 체크리스트
│   │   └── doc-link-guard.sh         # 문서 편집 시 백링크 + 레지스트리 업데이트 강제
│   ├── commands/
│   │   ├── begin.md                   # /begin — 세션 시작, 상태 읽기
│   │   ├── wrap.md                    # /wrap — 세션 종료, TODO 업데이트
│   │   ├── todo.md                    # /todo — 태스크 관리
│   │   ├── commit.md                  # /commit — 컨벤셔널 커밋
│   │   ├── build.md                   # /build — 병렬 빌드 오케스트레이션
│   │   └── review.md                  # /review — 품질 게이트 리뷰
│   ├── skills/
│   │   ├── work-init/SKILL.md         # 3문서 태스크 메모리 시스템
│   │   └── team/SKILL.md             # 에이전트 팀 관리
│   └── agents/
│       ├── backend-developer.md
│       ├── frontend-developer.md
│       ├── test-engineer.md
│       └── docs-writer.md
└── docs/
    ├── PROJECT_TODO.md                # 페이즈 대시보드 + 작업 로그
    ├── phases/                        # 페이즈별 태스크 체크박스
    ├── work/                          # 활성 태스크 메모리 (3문서 폴더)
    └── research/
        ├── 00_INDEX.md                # 리서치 캐시 인덱스
        ├── TEMPLATE.md                # 캐시 문서 템플릿
        ├── searches/                  # WebSearch 결과
        ├── apis/                      # WebFetch 결과
        └── libraries/                 # Context7 라이브러리 문서
```

## 구성 요소

### 훅 (11개 스크립트)

핵심 자동화 레이어. Claude Code 이벤트에 반응하는 셸 스크립트입니다.

| 훅 | 이벤트 | 역할 |
|----|--------|------|
| **session-restore** | SessionStart | `docs/work/`에서 진행 중인 태스크를 스캔하여 컨텍스트 주입 → Claude가 이전 작업을 이어서 진행 |
| **intent-router** | UserPromptSubmit | 사용자 프롬프트를 키워드 매칭하여 관련 프로젝트 문서 추천 |
| **task-completion-guard** | UserPromptSubmit | 새 작업 시작 전 커밋되지 않은 코드 변경사항 감지, `/commit` + `/wrap` 실행 알림 |
| **research-cache-check** | PreToolUse | WebSearch/WebFetch/Context7 호출 전, 이미 캐시된 결과가 있는지 확인 |
| **research-cache-guard** | PreToolUse | 이전 리서치 결과가 아직 캐시되지 않았으면 다른 모든 도구 호출을 **차단** |
| **research-cache-remind** | PostToolUse | 외부 조사 완료 후 pending 상태를 생성하여 guard 트리거 |
| **arch-guard** | PreToolUse | 아키텍처 위반을 **차단** (예: 도메인 레이어에서 인프라 import) + 레이어별 가이드 주입 |
| **arch-docs-guard** | PreToolUse | 문서에서 잘못된 도메인 용어 사용 시 **경고** (허용 여부 질문) |
| **arch-commit-guard** | PreToolUse | git 커밋이 여러 모듈/도메인에 걸칠 때 **경고** |
| **arch-post-check** | PostToolUse | 코드 작성 후 해당 레이어에 맞는 검증 체크리스트 알림 |
| **doc-link-guard** | PostToolUse | 문서 편집 시 교차 참조 감지 → 백링크 + `LINK_REGISTRY.md` 업데이트 강제 |

### 슬래시 커맨드 (6개)

| 커맨드 | 용도 |
|--------|------|
| `/begin` | 세션 시작: TODO 상태 읽기, 진행 중 작업 찾기, 다음 태스크 제안 |
| `/wrap` | 세션 종료: 진행 상황 기록, 작업 로그 작성, 커밋, LESSONS.md 업데이트 |
| `/todo [op]` | 태스크 관리: `status`, `start`, `done`, `add`, `block`, `log`, `next`, `phase`, `history` |
| `/commit` | Git 커밋: diff 분석, 컨벤셔널 커밋 메시지 생성, 작업 로그 업데이트 |
| `/build` | 빌드 오케스트레이터: 태스크 스펙 로드, 에이전트 팀 생성, 품질 게이트 실행 |
| `/review` | 품질 리뷰: 빌드 전 스펙 점검, 코드 리뷰, 통합 테스트, 페이즈 검증 |

### 스킬 (2개)

| 스킬 | 트리거 조건 | 역할 |
|------|------------|------|
| **work-init** | 3개 이상 파일에 걸치거나 멀티 세션 태스크 | `docs/work/{task}/`에 plan.md + context.md + checklist.md 생성 |
| **team** | 여러 도메인에 걸친 병렬 작업 필요 시 | 에이전트 팀 패턴 정의, 생성 절차, 파일 충돌 방지 |

### 에이전트 (4개 역할)

| 에이전트 | 모델 | 담당 |
|----------|------|------|
| **backend-developer** | opus | 도메인 로직, 데이터베이스, API, 외부 연동 |
| **frontend-developer** | opus | UI 컴포넌트, 페이지, 상태 관리 |
| **test-engineer** | opus | 유닛, 통합, E2E 테스트 전 패키지 |
| **docs-writer** | sonnet | 문서 일관성, 작업 로그, README |

### TODO 시스템 (3단계)

```
레벨 1: docs/PROJECT_TODO.md     — 페이즈 대시보드, 마일스톤, 작업 로그
레벨 2: docs/phases/*.md          — 상태 마커 포함 태스크 체크박스
레벨 3: docs/work/{task}/         — 활성 태스크 메모리 (계획 + 컨텍스트 + 체크리스트)
```

### 리서치 캐시

Claude의 모든 외부 조사를 로컬에 강제 저장합니다. 같은 것을 다시 검색할 필요가 없습니다.

```
흐름: 외부 호출 → PostToolUse가 pending 상태 생성 → 모든 도구 차단
      → Claude가 docs/research/{category}/{slug}.md에 저장 → 00_INDEX.md 업데이트
      → 차단 해제 → 정상 작업 재개
```

## 커스터마이즈

### 훅 레벨 선택

| 레벨 | 훅 | 적합한 프로젝트 |
|------|-----|----------------|
| **최소** | session-restore + intent-router + task-completion-guard | 개인 프로젝트, 빠른 반복 개발 |
| **표준** | + research-cache (3개) + doc-link-guard | 중규모 프로젝트, 외부 API 활용 |
| **전체** | + arch-guard (4개) | 대규모 프로젝트, 팀 개발, 아키텍처 중요 |

불필요한 훅은 `.claude/settings.json`에서 해당 항목을 제거하면 됩니다.

### 아키텍처 가드 커스터마이즈

`.claude/hooks/arch-guard.sh`를 수정하세요. 템플릿에 포함된 예시:

| 패턴 | 가드 전략 |
|------|----------|
| **DDD** | 도메인 레이어에서 인프라 import 차단, 바운디드 컨텍스트 정보 주입 |
| **Clean Architecture** | 엔티티에서 프레임워크 import 차단, 레이어 책임 주입 |
| **MVC** | 모델에서 뷰 import 차단, MVC 책임 주입 |
| **Modular Monolith** | 모듈 간 직접 import 차단, 모듈 경계 주입 |

### 인텐트 라우터 커스터마이즈

`.claude/hooks/intent-router.sh`를 수정하세요 — 키워드→문서 매핑 추가:

```bash
# 예: 사용자가 "auth"를 언급하면 인증 문서 추천
if echo "$PROMPT" | grep -qiE 'auth|login|OAuth|JWT'; then
  SUGGESTIONS="${SUGGESTIONS}
- Auth Architecture: docs/auth-design.md"
fi
```

### 에이전트 커스터마이즈

`.claude/agents/*.md`를 수정하세요 — 각 팀원 역할의 도메인, 책임, 규칙을 정의합니다.

## 프로젝트 유형별 추천 설정

| 프로젝트 유형 | 훅 | 커맨드 | 에이전트 |
|-------------|-----|--------|---------|
| **풀스택 웹앱** | 전체 | 6개 전부 | backend + frontend + test |
| **백엔드 API** | arch + research + session | begin/wrap/todo/commit | backend + test |
| **프론트엔드 SPA** | research + session | begin/wrap/todo/commit | frontend + test |
| **라이브러리/SDK** | arch + research | begin/wrap/todo/commit | backend + test + docs |
| **데이터 파이프라인** | research + session | begin/wrap/todo/commit | backend + test |
| **모바일 앱** | 전체 | 6개 전부 | mobile + frontend + test |

## 요구사항

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI 설치
- `jq`가 PATH에 있어야 함 (훅 스크립트에서 사용)
- Bash 4+ (macOS, Linux 호환)

## FAQ

**Q: 어떤 프로그래밍 언어에서든 작동하나요?**
A: 네. 훅, 커맨드, TODO 시스템은 언어에 무관합니다. 아키텍처 가드만 프로젝트의 패턴에 맞게 수정하면 됩니다.

**Q: 기존 CLAUDE.md와 충돌하나요?**
A: 셋업 스크립트는 이미 존재하는 파일을 건너뜁니다. Auto Behaviors 섹션을 수동으로 병합할 수 있습니다.

**Q: 특정 훅을 비활성화하려면?**
A: `.claude/settings.json`에서 해당 이벤트의 항목을 제거하세요.

**Q: MCP 서버 없이도 작동하나요?**
A: 네. MCP 관련 기능(Context7, Sequential Thinking)은 선택 사항입니다. 리서치 캐시는 MCP 없이도 정상 동작합니다.

## 출처

[ZeroO2 v3](https://zeroo2.ai)에서 추출하여 범용화한 프레임워크입니다. Electron + TypeScript + DDD 데스크톱 앱에서 5개 개발 페이즈, 100개 이상의 태스크를 거치며 실전 검증된 후 템플릿으로 표준화했습니다.

## 라이선스

MIT
