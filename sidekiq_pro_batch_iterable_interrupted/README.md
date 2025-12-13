# Sidekiq Pro Batch + Sidekiq 7.3 Iterable Interrupted MRE

This folder contains a minimal reproduction for an issue when combining **Sidekiq Pro Batch middleware** with **Sidekiq 7.3 Iterable jobs**.

## Summary

When an Iterable job gets interrupted (via `Sidekiq::Job::Interrupted`), Sidekiq Pro’s Batch server middleware (`Sidekiq::Batch::Server`) can treat that interruption like a normal failure and call `add_failure`. If the batch has no other pending jobs at that moment, the `:complete` callback can fire **too early**, even though the job is expected to be re-enqueued and resume later.

## Requirements

- Ruby + Bundler
- Sidekiq `~> 7.3.0`
- Sidekiq Pro (Batch is required)
- Redis

## Versions used in the verified run

- Ruby 3.4.5
- Sidekiq 7.3.9
- Sidekiq Pro 7.3.6
- Redis 7 (via Docker image `redis:7-alpine`)

## How to run

### 1) Start Redis

```bash
docker compose up -d
```

### 2) Install gems

```bash
bundle install
```

You need access to the Sidekiq Pro gem source (`https://gems.contribsys.com/`).
Configure Bundler credentials as appropriate for your environment.

### 3) Reset reproduction state (optional)

```bash
bundle exec ruby reset.rb
```

This clears the MRE’s Redis keys and also clears `queue:default`, `retry`, and `schedule` to keep runs deterministic.

### 4) Start Sidekiq

Terminal 1:

```bash
bundle exec sidekiq -r ./boot.rb -c 1 -q default
```

### 5) Enqueue the batch

Terminal 2:

```bash
bundle exec ruby enqueue.rb
```

## Expected vs actual

- **Expected**: If an Iterable job raises `Sidekiq::Job::Interrupted`, the batch should not record a failure, and the `:complete` callback should only fire once, after the resumed job truly finishes.
- **Actual (bug)**: On the first interruption, the batch records a failure via `add_failure`. Because the batch can temporarily have `pending == 0`, the `:complete` callback may fire **before** the job finishes after being re-enqueued.

## What to look for in logs

If you see the following ordering in Sidekiq logs, you’ve reproduced the issue:

- `Interrupted, re-queueing...` (from `Sidekiq::Job::InterruptHandler`)
- `[MRE] BATCH COMPLETE callback fired ...`

…before any of the `[MRE] Processed item=...` lines from the resumed run.

### Example log excerpt (bug)

This is a real run after `reset.rb`, where the job interrupts once at `item=0`:

```
... class=MreIterableJob ... WARN: [MRE] Forcing early abort to trigger Interrupted (item=0)
... class=MreIterableJob ... DEBUG: Interrupted, re-queueing...
... class=Sidekiq::Batch::Callback ... WARN: [MRE] BATCH COMPLETE callback fired (bid=...)
... class=MreIterableJob ... INFO: [MRE] Processed item=0 / total=...
... class=MreIterableJob ... INFO: [MRE] Processed item=1 / total=...
...
```

…and then later the job continues processing iterations.

## Files

- `boot.rb`: Sidekiq/Redis configuration and requires
- `workers.rb`: Iterable job + Batch complete callback
- `enqueue.rb`: Creates a batch and enqueues the job
- `reset.rb`: Clears Redis keys used by this MRE
- `docker-compose.yml`: Redis container
