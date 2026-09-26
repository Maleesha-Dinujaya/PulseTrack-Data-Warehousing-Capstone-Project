# pulsetrack.conversions — topic dump (Kafka-style)

One record per line, exactly as a consumer of all 4 partitions would see it:

    pulsetrack.conversions|partition=<0-3>|offset=<per-partition, increasing>|ts=<epoch millis>|key=<conversion_id>|<JSON payload>

Event types: conversion.created · conversion.status_changed · adjustment.applied
Semantics (all deliberate, all real Kafka phenomena):
  * At-least-once delivery — ~2.5% duplicate deliveries (same event_id at a later offset). De-duplicate by event_id.
  * Per-partition offsets are strictly increasing; ordering is only guaranteed WITHIN a partition.
  * ~0.1% malformed (truncated) lines — a partial write; the producer's RETRY (the intact
    record) follows on the same partition, so no event is permanently lost. Parse
    defensively, quarantine and count the bad lines.
  * Schema evolution: after ~70% of the stream, payloads carry "schema_version":"2.0" and the
    conversion.created field `revenue` is renamed `revenue_amount`.
  * Envelope ts = producer event-time in epoch millis (UTC). Duplicate deliveries carry a
    slightly later ts; ordering is authoritative ONLY via per-partition offsets.
  * Timezone convention: ALL wall-clock times across the dataset are UTC; epochs are true
    UTC epochs of those wall clocks.
  * is_test conversions also emit events — filter them, as in the batch source.
Reconciliation guarantee: replaying the stream (dedup by event_id, latest status per conversion)
reproduces the batch state: conversions_raw deduplicated by MAX(updated_at) + revenue_adjustments_raw.
