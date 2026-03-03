# Daily Quantum News

**A dedicated repo for your daily quantum computing email digest:** top articles from RSS, prioritised for **partnerships and large announcements** (over pure R&D), **no repetition** (same article not sent again within 14 days), plus **LinkedIn post drafts** in your voice.

---

## What it does

- Fetches from **ScienceDaily Quantum**, **Quanta Magazine Physics**, and **Red Hat Blog** (configurable).
- Keeps only articles matching your **topic** (default: quantum).
- **Skips** any article already sent in the **last 14 days** (logged in `scripts/.quantum-digest-sent.log`).
- **Ranks** by: partnership/announcement score → IBM/Red Hat relevance → newest first.
- Sends **top 3** (or N) by email with **LinkedIn post proposals** (hook, takeaway, CTA, hashtags).

---

## Quick start (GitHub Actions — 8 AM CET every day)

1. **Create this repo on GitHub** (if you haven’t): [github.com/new](https://github.com/new) → name it **daily-quantum-news** (or similar).
2. **Push this folder** to that repo (see “Push to a new repo” below).
3. **Secrets** (Settings → Secrets and variables → Actions):
   - `QUANTUM_DIGEST_RECIPIENT` — your email
   - `GMAIL_APP_PASSWORD` — Gmail App Password (16 chars, no spaces). Create at [myaccount.google.com/apppasswords](https://myaccount.google.com/apppasswords) (2FA required).
4. **Test:** Actions → “Quantum Digest 8AM CET” → Run workflow. Check your inbox.
5. The workflow runs **every day at 07:00 UTC** (8 AM CET) on GitHub’s servers.

---

## Push to a new repo (e.g. daily-quantum-news)

```bash
cd /path/to/daily-quantum-news
git init
git add .
git commit -m "Initial commit: Daily Quantum News digest"
git branch -M main
git remote add origin git@github.com:marijaRH/daily-quantum-news.git
git push -u origin main
```

(Use your SSH key or a token; create the empty repo first at [github.com/new?name=daily-quantum-news](https://github.com/new?name=daily-quantum-news).)

---

## Run locally

```bash
pip install -r scripts/requirements-digest.txt
cp scripts/quantum-digest.env.example scripts/quantum-digest.env
# Edit scripts/quantum-digest.env: QUANTUM_DIGEST_RECIPIENT, GMAIL_APP_PASSWORD
./scripts/run-quantum-digest.sh
```

**Cron (8 AM CET):**  
`0 8 * * * TZ=Europe/Paris /path/to/daily-quantum-news/scripts/run-quantum-digest.sh`

---

## Repo structure

```
.github/workflows/quantum-digest.yml   # 8 AM CET schedule + persist sent log
scripts/
  quantum_daily_digest.py              # Main script
  run-quantum-digest.sh
  quantum-digest.env.example
  digest-topic2.env.example
  .quantum-digest-sent.log            # No repetition (committed for CI)
  requirements-digest.txt
.gitignore
README.md
```

---

## Prioritisation and no repetition

- **Partnership / large announcements** (partnerships, deals, acquisitions, launches, enterprise, funding) rank higher than pure R&D phrasing.
- **IBM / Red Hat** (IBM, Qiskit, Red Hat, RHEL, OpenShift) rank next.
- **No repetition:** every sent URL is logged with its date; URLs in the log from the last **14 days** are excluded from the next run. GitHub Actions commits the log so each run sees the same history.

---

## Licence

Use and modify as you like. Keep env files with secrets out of version control (see `.gitignore`).
