# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

The project uses `makem.sh` (wrapped by `Makefile`) for building, linting, and testing.

```bash
# Run all lints and tests
./makem.sh all

# Byte-compile source files
./makem.sh compile

# Run all linters
./makem.sh lint
./makem.sh lint-checkdoc   # checkdoc
./makem.sh lint-compile    # byte-compile with warnings as errors
./makem.sh lint-package    # package-lint

# Run tests
./makem.sh test-ert        # run ERT tests in batch mode

# Run with sandbox (clean Emacs config, auto-installs deps)
./makem.sh --sandbox test-ert
./makem.sh --sandbox --install-deps test-ert  # first run

# Run a specific test interactively
./makem.sh test-ert-interactive
```

Tests live in `tests/ement-tests.el` and use ERT (`ert-deftest`).

To enable debug messages while developing, uncomment the `eval-and-compile` block near the top of the relevant file and byte-compile it:
```elisp
;; (eval-and-compile
;;   (setq-local warning-minimum-log-level nil)
;;   (setq-local warning-minimum-log-level :debug))
```

## Architecture

Ement.el is a Matrix client for Emacs. The codebase is structured as a collection of interdependent Emacs Lisp libraries:

### Dependency order (low → high level)

1. **`ement-macros.el`** — Core macros used across all files: `ement-debug`, `ement-propertize`, `ement-with-room-and-session`, progress reporter macros, and anaphoric helpers (`ement-afirst`, `ement-aprog1`).

2. **`ement-structs.el`** — Data structure definitions using `cl-defstruct`: `ement-user`, `ement-event`, `ement-server`, `ement-session`, `ement-room`. These are the fundamental data types passed throughout the codebase.

3. **`ement-api.el`** — Low-level HTTP API wrapper around `plz` (an HTTP library). The `ement-api` function makes authenticated requests to Matrix endpoints using a session's server/token.

4. **`ement-lib.el`** — Shared utility functions used by multiple higher-level files. Exists to avoid circular dependencies. Contains helpers for room operations, user display, formatting, etc.

5. **`ement-room.el`** — Room buffer implementation using EWOC. Displays events, handles sending messages, manages the timeline. This is the main UI for reading/writing in a room.

6. **`ement-notify.el`** — Event notification system for newly received events (via sync).

7. **`ement-notifications.el`** — Matrix notifications endpoint support, listing old notifications. Distinct from `ement-notify`: this fetches from the Matrix `/notifications` API, while `ement-notify` handles live sync events.

8. **`ement-room-list.el`** — Room list view using `taxy` and `taxy-magit-section` for dynamic, programmable grouping.

9. **`ement-tabulated-room-list.el`** — Alternative tabulated room list view.

10. **`ement-directory.el`** — Public room directory browser.

11. **`ement.el`** — Main entry point. Handles login, sync loop, session persistence, and wires together all other components via hooks (`ement-sync-callback-hook`, `ement-event-hook`).

### Key design patterns

- **Sessions**: A `ement-session` struct holds credentials, the server, and all rooms. Multiple sessions (accounts) are stored in `ement-sessions` alist keyed by MXID.
- **Sync loop**: `ement--sync` polls the Matrix `/sync` endpoint via `plz` (async HTTP). Responses are processed by `ement--sync-callback`, which fires `ement-sync-callback-hook`.
- **Events**: Raw Matrix events are parsed into `ement-event` structs. `ement-event-hook` is called for each event during sync processing.
- **Room buffers**: Each room has an EWOC-backed buffer. `ement-room` local variables `ement-room` and `ement-session` identify which room/session the buffer belongs to.
- **`ement-propertize` macro**: Used instead of `propertize` throughout to ensure both `face` and `font-lock-face` properties are set (workaround for magit-section compatibility).
