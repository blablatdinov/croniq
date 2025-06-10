# Croniq - Open-Source Cron Scheduler

_A modern job scheduler built with Elixir and Phoenix_

## 🌟 Features

**HTTP Task Scheduling** - Trigger any API endpoint on a schedule

**Full Cron Syntax** - Supports standard cron expressions with seconds precision

**Real-time Monitoring** - Built-in dashboard with LiveView

**Retry Mechanism** - Automatic retries with exponential backoff

**Web UI & REST API** - Manage jobs through both interfaces

**Lightweight** - Runs with minimal resources

## 🚀 Quick Start

Requirements:

- Elixir 1.14+
- PostgreSQL 12+
- Node.js 16+ (for assets)

Installation

1. Clone the repo:

```bash
git clone https://github.com/yourusername/croniq.git
cd croniq
```

2. Set up dependencies:

```bash
mix deps.get
cd assets && npm install && cd ..
```

3. Configure database:

```bash
mix ecto.setup
```

4. Start the server:

```bash
mix phx.server
```

Visit http://localhost:4000 in your browser.

## 📚 Documentation

API Examples

Create a new job:

```bash
curl -X POST http://localhost:4000/api/jobs \
  -H "Content-Type: application/json" \
  -d '{
    "name": "daily-backup",
    "schedule": "0 3 * * *",
    "url": "https://api.example.com/backup",
    "method": "POST",
    "headers": {
      "Authorization": "Bearer your-token"
    },
    "body": {
      "database": "production"
    }
  }'
```

List all jobs:

```bash
curl http://localhost:4000/api/jobs
```
