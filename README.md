# Daily Quantum News

A dedicated repository for a **daily email digest** of quantum computing (and configurable topic) news: top articles from RSS feeds, prioritised for **partnerships and large announcements**, with **no repetition** of articles within 14 days, plus **LinkedIn post drafts** ready to paste.

---

## Prerequisites

Before running the script or the GitHub Action, ensure you have the following.

### Required

| Prerequisite | Description |
|--------------|-------------|
| **Python 3.8+** | The script is written in Python. Check with `python3 --version`. |
| **pip** | To install the single dependency (`feedparser`). Usually bundled with Python. |
| **Network access** | The script fetches RSS feeds over HTTP/HTTPS and sends email via SMTP. |
| **Gmail account with 2-Step Verification** | Needed to create an App Password for sending email. |
| **Gmail App Password** | A 16-character application-specific password (not your normal Gmail password). Create at [myaccount.google.com/apppasswords](https://myaccount.google.com/apppasswords) after enabling 2FA. |

### Optional (depending on how you run)

| Prerequisite | When needed |
|--------------|-------------|
| **GitHub account** | To run the digest on a schedule via GitHub Actions (no need for your own server or always-on machine). |
| **Repository secrets** | When using GitHub Actions: you must add `QUANTUM_DIGEST_RECIPIENT` and `GMAIL_APP_PASSWORD` in the repo’s Settings → Secrets and variables → Actions. |
| **Cron or similar scheduler** | When running locally on a schedule (e.g. 8 AM CET daily). Cron requires the machine to be on at the scheduled time. |
| **Bash** | The wrapper script `run-quantum-digest.sh` is Bash; on Windows you can run the Python script directly with env vars set. |

### Not required

- No database: the “no repetition” state is stored in a simple log file (`scripts/.quantum-digest-sent.log`).
- No API keys for news: articles are fetched from public RSS feeds only.

---

## What the script does (detailed)

The script `scripts/quantum_daily_digest.py` runs as a single pipeline each time you execute it. Below is a step-by-step description.

### 1. Load configuration

- Reads environment variables (from the shell or from an env file loaded by `run-quantum-digest.sh`).
- **Required:** `QUANTUM_DIGEST_RECIPIENT` (email address that receives the digest), and either `GMAIL_APP_PASSWORD` or SMTP credentials.
- **Optional:** `DIGEST_NAME`, `DIGEST_TOP_N`, `DIGEST_TOPIC_KEYWORDS`, `DIGEST_FEEDS`, `QUANTUM_DIGEST_SENDER`. See [Environment variables](#environment-variables) below.

### 2. Fetch RSS feeds

- Requests each feed URL (default: ScienceDaily Quantum Computing, Quanta Magazine Physics, Red Hat Blog) over HTTP/HTTPS.
- Parses RSS/Atom XML and extracts for each entry: **title**, **link**, **summary** (or description), and **publication date**.
- HTML tags in summaries are stripped to plain text.
- If a feed fails (e.g. timeout or invalid XML), that feed is skipped and the script continues with the others.

### 3. Topic filter

- Only entries whose **title or summary** contain at least one of the configured topic keywords are kept (e.g. default: `quantum`).
- This ensures the digest stays on-topic when feeds mix multiple subjects (e.g. general physics or Red Hat blog).

### 4. No-repetition filter (sent log)

- Reads the file `scripts/.quantum-digest-sent.log`, which stores one line per previously sent article: `YYYY-MM-DD<TAB>article_url`.
- Any article whose URL appears in the log with a date within the **last 14 days** is **excluded** from this run.
- So you never get the same article twice within two weeks; each run prefers new or older-but-unsent items.

### 5. Deduplication by URL and title

- Among the remaining entries, duplicates are dropped by normalised (link, title) so the same story from the same source is only considered once.

### 6. Prioritisation (scoring and sort)

Each remaining article is scored and then sorted so that “better” items appear first.

- **Partnership / large-announcement score (higher = better):**
  - Phrases like partnership, partners, collaboration, collaborates: **+4**
  - Acquisition, acquires, merger, deal, agreement, signed: **+4**
  - Launches, announces, unveiled: **+3**
  - Strategic, enterprise, commercial, deployment: **+2**
  - Funding, investment, billion, million, “$”: **+2**
  - Pure R&D phrasing (e.g. “scientists discover”, “study finds”, “paper published”): **-1** (so partnership/announcement news ranks above pure R&D when both exist).

- **IBM / Red Hat score (higher = better):**
  - IBM or Qiskit: **+3**
  - Red Hat, RHEL, OpenShift: **+3**
  - Open source: **+1**

- **Sort order:**  
  `(partnership_announcement_score, ibm_redhat_score, publication_date)` descending, so: best partnership/announcement first, then most IBM/Red Hat–relevant, then newest.

### 7. Pick top N

- Takes the first **N** articles from the sorted list (default **N = 3**; configurable via `DIGEST_TOP_N`, max 20).
- If there are fewer than N topic-matching, non-repeated articles, only that many are used.

### 8. Build email content

- **Subject line:** `{DIGEST_NAME} {YYYY-MM-DD} — Top {N} + LinkedIn ideas` (e.g. “Quantum Digest 2026-02-23 — Top 3 + LinkedIn ideas”).
- **Body (HTML and plain text):**
  - A short header with the digest name and date.
  - For each of the top N articles: **title**, **summary** (truncated), and **link**.
  - A **LinkedIn post proposals** section: for each article (up to 5), a ready-to-paste draft with a hook (“Did you see this?” / “This one’s worth a read”), a short takeaway, a CTA (“Worth reading the full piece — link below. What would you add?”), the link, and suggested hashtags (e.g. `#QuantumComputing`, `#IBMQuantum`, `#RedHat` when relevant).

### 9. Send email

- Connects to Gmail’s SMTP (or the configured SMTP host) with TLS.
- Authenticates using `GMAIL_APP_PASSWORD` (or `SMTP_USER` / `SMTP_PASSWORD`).
- Sends one email to `QUANTUM_DIGEST_RECIPIENT` with the HTML and plain versions (multipart/alternative).
- **Sender address:** `QUANTUM_DIGEST_SENDER` if set, otherwise the recipient address. The sending account is the one whose App Password or SMTP credentials you use.

### 10. Update sent log

- After a **successful** send, the script appends the **N** sent article URLs to `scripts/.quantum-digest-sent.log` with today’s date.
- Old log lines (older than 14 + 7 days) are trimmed so the file does not grow indefinitely.
- When the script is run from **GitHub Actions**, the workflow commits and pushes this file so the next run (e.g. next day) sees the same history and continues to avoid repetition.

---

## Environment variables

| Variable | Required | Description |
|----------|----------|-------------|
| `QUANTUM_DIGEST_RECIPIENT` | Yes | Email address that receives the digest. |
| `GMAIL_APP_PASSWORD` | Yes* | Gmail App Password (16 characters, no spaces). Create at [myaccount.google.com/apppasswords](https://myaccount.google.com/apppasswords) (2FA must be on). |
| `QUANTUM_DIGEST_SENDER` | No | Sender email (default: same as recipient). Use the Gmail address that owns the App Password when sending to a different recipient. |
| `DIGEST_NAME` | No | Title used in subject and body (default: `Quantum Digest`). |
| `DIGEST_TOP_N` | No | Number of articles to include (default: `3`, max 20). |
| `DIGEST_TOPIC_KEYWORDS` | No | Comma-separated keywords; only articles whose title/summary contain at least one are kept (default: `quantum`). |
| `DIGEST_FEEDS` | No | Comma-separated RSS feed URLs; overrides the default ScienceDaily / Quanta / Red Hat feeds. |
| `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASSWORD` | No | Use these instead of Gmail when you want to send via another SMTP server. |

\* Or SMTP_* variables if not using Gmail.

---

## How to run

### Option A: GitHub Actions (recommended for daily 8 AM CET)

1. Push this repository to GitHub (e.g. `marijaRH/daily-quantum-news`).
2. Add repository secrets: **Settings → Secrets and variables → Actions**
   - `QUANTUM_DIGEST_RECIPIENT` = your email
   - `GMAIL_APP_PASSWORD` = your 16-character Gmail App Password (no spaces)
3. The workflow **Quantum Digest 8AM CET** runs on schedule at **07:00 UTC** (8 AM CET) and on **workflow_dispatch** (Actions tab → Run workflow).
4. After each run, the workflow commits `scripts/.quantum-digest-sent.log` so the next run avoids repeating the same articles.

**Prerequisites:** GitHub account, repo pushed, secrets set. No need for your own server or machine to be on.

### Option B: Local (one-off or cron)

1. **Install dependency**
   ```bash
   pip install -r scripts/requirements-digest.txt
   ```
2. **Configure**
   ```bash
   cp scripts/quantum-digest.env.example scripts/quantum-digest.env
   ```
   Edit `scripts/quantum-digest.env`: set `QUANTUM_DIGEST_RECIPIENT` and `GMAIL_APP_PASSWORD` (and optionally `QUANTUM_DIGEST_SENDER` if sending to a different address).
3. **Run**
   ```bash
   ./scripts/run-quantum-digest.sh
   ```
   Or run the script directly with env vars set:
   ```bash
   export QUANTUM_DIGEST_RECIPIENT=you@example.com
   export GMAIL_APP_PASSWORD=your16charapppassword
   python3 scripts/quantum_daily_digest.py
   ```
4. **Schedule (e.g. 8 AM CET daily)**  
   Add to crontab (`crontab -e`):
   ```cron
   TZ=Europe/Paris
   0 8 * * * /absolute/path/to/daily-quantum-news/scripts/run-quantum-digest.sh
   ```
   **Prerequisites:** Python 3.8+, pip, network, Gmail App Password. Cron only runs when the machine is on at the scheduled time.

---

## Repository structure

```
.github/
  workflows/
    quantum-digest.yml     # Runs at 8 AM CET; runs script then commits sent log
scripts/
  quantum_daily_digest.py # Main script (fetch, filter, score, email, update log)
  run-quantum-digest.sh   # Loads env file and runs the script
  quantum-digest.env.example
  digest-topic2.env.example
  .quantum-digest-sent.log  # Log of sent URLs (used for no-repetition; committed in CI)
  requirements-digest.txt   # Python dependency: feedparser
.gitignore
README.md
```

Env files with secrets (`quantum-digest.env`, `digest-*.env`) are in `.gitignore` and must not be committed.

---

## Second digest (different topic or recipient)

You can run the same script with a different env file for another topic or recipient (e.g. AI, offshore, or a different email):

1. Copy `scripts/digest-topic2.env.example` to e.g. `scripts/digest-ai.env`.
2. Set in that file: `QUANTUM_DIGEST_RECIPIENT`, `DIGEST_TOPIC_KEYWORDS`, `DIGEST_NAME`, and `GMAIL_APP_PASSWORD` (and `QUANTUM_DIGEST_SENDER` if needed).
3. Run: `./scripts/run-quantum-digest.sh digest-ai.env`.
4. Schedule that command separately (cron or another workflow) if you want it daily or weekly.

---

## Default RSS feeds

- [ScienceDaily — Quantum Computing](https://www.sciencedaily.com/rss/matter_energy/quantum_computing.xml)
- [Quanta Magazine — Physics](https://www.quantamagazine.org/physics/feed/)
- [Red Hat Blog](https://www.redhat.com/en/rss/blog)

Override with `DIGEST_FEEDS` (comma-separated URLs).

---

## Licence and use

Use and modify as you like. No warranty. Keep env files with secrets out of version control (they are listed in `.gitignore`).
