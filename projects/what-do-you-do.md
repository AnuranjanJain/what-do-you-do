# What Do You Do

Architecture note: [architecture.md](architecture.md)

## One-line idea

A privacy-first digital wellbeing app for phone and PC that tells users what they actually did with their time, using on-device AI to classify activity into meaningful categories and deeper sub-activities.

## Core concept

Most screen-time tools say things like "You used Chrome for 3 hours" or "You played games for 90 minutes." This app should answer the more human question:

> What did I actually do?

Examples:

- Browsing
- Watching
- Gaming
- Coding
- Productivity
- Communication apps like Discord
- Learning
- Note-making
- Idle / AFK

Then it should go one level deeper.

Examples:

- Gaming:
  - Playing strategy game
  - Actively thinking / planning
  - AFK / waiting
  - Repeating/grinding
  - Watching cutscenes or menus

- Coding:
  - Problem solving
  - Debugging
  - Learning something
  - Writing notes
  - Reading docs
  - Building features
  - Idle / stuck

- Browsing:
  - Research
  - Entertainment
  - Shopping
  - Social media
  - News
  - Random distraction

- Discord / communication:
  - Text chatting
  - Voice call
  - Study or work call
  - Gaming coordination
  - Community browsing
  - Watching a stream
  - Idle in a call
  - Distracted scrolling

## Target platforms

- PC app
- Phone app
- Optional synced dashboard, but without uploading private raw activity data

## Privacy principle

Everything should run on-device by default.

No server should receive:

- Screenshots
- Browser history
- App contents
- Keystrokes
- Raw activity logs
- Personal files

The app should be designed as local-first and privacy-preserving from the beginning:

- No cloud account required.
- No server-side AI processing.
- No raw screenshots stored by default.
- No keystroke logging.
- No reading private message contents by default.
- No hidden background collection.
- No selling or sharing user data.
- No third-party analytics unless the user explicitly enables it.
- All sensitive processing happens on the user's own device.
- The user can see, pause, delete, export, and control all collected data.
- App-specific detection should use the least private signal that works.

If cloud sync is ever added, it should only sync processed summaries, and ideally use end-to-end encryption. Raw activity data should stay local.

## Privacy-safe detection model

The app should prefer privacy-safe signals before invasive ones.

Detection priority:

1. User-approved app integrations or local APIs.
2. App name, process name, and active window title.
3. Browser domain/category, not full page content where possible.
4. Input activity level for idle vs active detection.
5. User-corrected labels.
6. Optional local screenshot understanding only if the user explicitly enables it.

For Discord-like detection, the app should avoid reading private messages. It can detect higher-level activity such as:

- Discord is active
- User is in a voice call
- User is idle in a call
- User is switching channels
- User is typing
- User is watching a stream, if exposed by the app or OS

The app should summarize behavior without exposing private content.

## How it might work

The app can combine multiple local signals:

- Active app/window title
- Website domain or browser tab title, where permission allows
- Communication app state, such as Discord active window, call state, typing/activity indicators, and broad channel context where available without reading private message contents
- Keyboard/mouse activity level
- Idle detection
- Optional periodic screenshot analysis on-device
- Optional accessibility APIs on phone/desktop, only with clear consent
- Local embeddings or small AI models to classify activity context

The AI model could classify activity in layers:

1. Broad category: coding, gaming, watching, browsing, productivity, idle.
2. Sub-category: debugging, learning, note-making, strategy gaming, AFK, research, distraction.
3. Time quality: focused, fragmented, passive, blocked, idle, flow state.

## Possible AI approach

Start without heavy model training:

- Use rules for obvious signals like active app, domain, idle time, and window title.
- Use a small local model to classify unclear activity from text metadata.
- Add optional local screenshot understanding later for richer detection.

Later, train or fine-tune models using user-corrected labels:

- User reviews timeline labels.
- User corrects "watching" to "learning video" or "gaming" to "AFK."
- Corrections stay local.
- The app learns that user's personal patterns over time.

## MVP

The first version should focus on PC because desktop signals are easier to collect.

MVP features:

- Track active window/app.
- Detect idle vs active time.
- Group time into categories.
- Show a daily timeline.
- Let user correct labels.
- Keep all data local in SQLite.
- Basic dashboard:
  - total focus time
  - distraction time
  - coding time
  - browsing time
  - gaming time
  - idle time

## Product angle

This should feel less like parental control and more like self-awareness.

Tone:

- Calm
- Honest
- Useful
- Not guilt-driven

The app should help users answer:

- Where did my time go?
- Was I actually working or just sitting at the screen?
- What kind of work did I do?
- When did I get distracted?
- What activities put me into focus?

## Personal assistant features

The app can become a private personal operating layer, not only a tracker.

These assistant-layer features should depend on integration with the user's other app:

- Required companion app: Project AI Agent
- Current trusted Project AI Agent thread: `codex://threads/019e4a40-fd50-7f92-b46e-1a1548dfdd94`
- Current Project AI Agent workspace: `C:\Users\anura\Documents\Ai Agent`
- Expected local Project AI Agent app URL: `http://127.0.0.1:5000/`
- `What Do You Do` handles activity awareness, digital wellbeing, time context, and privacy-first tracking.
- `Project AI Agent` handles deeper assistant actions, automation, reminders, memory, email intelligence, and job-tracking workflows.
- The assistant-layer features should only become available after `Project AI Agent` is successfully installed and connected.
- If `Project AI Agent` is not installed, `What Do You Do` should still work as a standalone activity tracking and digital wellbeing app.

Integration idea:

- During setup, `What Do You Do` checks whether `Project AI Agent` is installed.
- If found, the user can explicitly connect it.
- After connection, `What Do You Do` can pass local activity context to `Project AI Agent`.
- `Project AI Agent` can return reminders, memories, job updates, and suggested actions.
- Both apps should keep the same privacy rules: local-first, permission-based, no hidden data collection.

Possible integration methods:

- Local API on the user's device.
- Localhost service with user approval.
- Shared encrypted local database.
- App-to-app deep links.
- Plugin system where `Project AI Agent` installs an integration module for `What Do You Do`.

### Reminders

- Save reminders manually.
- Create reminders from detected context.
- Remind the user at a chosen time.
- Remind the user when returning to a specific app, task, website, or project.
- Support recurring reminders.
- Keep reminder data local by default.

Examples:

- "Remind me to reply to this email tonight."
- "Remind me when I open VS Code again."
- "Remind me to apply to jobs every weekday at 7 PM."

### Important memory

The app should let users save important things they want the app to remember.

Examples:

- Deadlines
- Job application notes
- People to follow up with
- Personal goals
- Project ideas
- Things learned
- Links or resources
- Important emails or tasks

This memory should be user-controlled:

- User can add, edit, pin, archive, delete, and export memories.
- Sensitive memories stay local.
- The app should not silently memorize private content without permission.

### Desktop and mobile widgets

Widgets should make the app useful without opening the full dashboard.

Possible desktop widgets:

- Today timeline
- Current activity
- Focus timer
- Reminder list
- Important tasks
- Job application status
- Quick capture

Possible mobile widgets:

- Current day summary
- Next reminder
- Quick add reminder
- Focus status
- Job tracker progress
- Important notes

### Email reading

Email support should be opt-in and privacy-preserving.

Possible features:

- Read selected emails only after user permission.
- Detect deadlines, follow-ups, interview invites, bills, meetings, and important tasks.
- Let the user save an email as an important memory.
- Create reminders from emails.
- Summarize job-related emails locally.

Privacy rules:

- No full mailbox scanning unless the user explicitly enables it.
- Prefer reading only selected labels/folders such as Jobs, Interviews, or Important.
- Process email content locally where possible.
- Store only summaries and extracted tasks unless the user chooses to save the full email.

### Job tracking

The app can include a private job application tracker.

Features:

- Track companies, roles, links, dates, status, contacts, notes, and next steps.
- Detect job-related emails such as application confirmations, rejections, interviews, and follow-ups.
- Remind the user to follow up.
- Show pipeline status:
  - saved
  - applied
  - assessment
  - interview
  - offer
  - rejected
  - ghosted
- Connect job activity with time usage, such as time spent applying, preparing, coding, or researching.

This should be useful for students, interns, and job seekers who want one private place for applications, reminders, preparation, and follow-ups.

## Open questions

- Should the app use screenshots at all, even locally?
- What permissions are acceptable on phone?
- Should AI labeling be fully automatic or correction-driven?
- Should there be a focus coach, or only analytics?
- Should the first version be Windows-only?
- How much detail is useful before it becomes creepy?
- Should reminders and memory become core MVP features or phase 2?
- Should email reading start with manual email import before connecting Gmail/Outlook?
- Should job tracking be a dedicated module or a template inside the memory/reminder system?

## Possible name

What Do You Do

Alternative vibe:

- What Did I Do
- DayTrace
- Mindful Meter
- Actual Time
- TimeLens
