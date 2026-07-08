# WDYD + AiOS Real-Life Planner Prompt

Build WDYD as my private daily operating system, with AiOS as the local intelligence engine.

AiOS should ingest my Gmail, hackathons, goals, GitHub repos, learning videos, notes, reminders, and activity signals. It should turn them into one planning row per real-life event:

- event title
- source: Gmail, hackathon, repo, goal, video, manual note
- project or goal name
- idea and context
- deadline
- planned day/time
- estimated duration
- work already done
- work left or blockers
- linked repo and latest repo activity
- next question to ask me
- status

The planner should create daily, weekly, and monthly plans from these rows. If new mail arrives and contains an action, deadline, meeting, follow-up, or waiting-on item, AiOS should create or update an event row. If a row has a GitHub repo, AiOS should refresh latest repo activity and use it as progress context. If a row is a learning goal such as GenAI, AiOS should ask which video/resource I completed, what notes to remember, and what should happen next.

AiOS should keep an "Answer next" queue from active rows so I can quickly feed progress: what got done, what is left, what video/resource I completed, what notes to remember, and whether the plan should move. WDYD should let me answer those questions from the native Planner screen and send the answer back to AiOS over loopback.

AiOS should also produce a short daily briefing from the same rows: what to focus on, what is due soon, and which questions need my answer.

WDYD should not store Gmail tokens or raw email content. It should show approved local summaries from AiOS through loopback only, including planner rows, focus cards, urgent emails, deadlines, suggestions, and progress.

Both AiOS Settings and WDYD should show a "real-life readiness" checklist so I can immediately see whether Gmail, sync, local Ollama, GitHub repo tracking, planner rows, background workers, and local-only privacy are ready or still need setup.

All AI reasoning should run locally through Ollama when available, with a deterministic fallback when Ollama is off.
