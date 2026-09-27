# ADR-0003: Monthly FX snapshots and conversion

- Status: Accepted
- Date: 2026-09-27
- Related: [Architecture v0.7](../ARCHITECTURE.md), [implementation plan](../IMPLEMENTATION-PLAN.md), [workflow and overview](../WORKFLOW-AND-OVERVIEW.md)

## Context

Employee compensation is stored in one currency per employment contract. The dashboard and employee detail API expose totals in that native currency. A client needs optional currency conversion without making a page request depend on a live exchange-rate provider or changing the stored compensation.

## Decisions by implementation phase

| Phase | Decision | Implementation state |
| --- | --- | --- |
| Snapshot model | Store a rate for a base/quote currency pair and calendar month. Keep `period_month` as the month's first day and `rate_date` as the observation date within that month. Store source and provider attribution; enforce positive rates, distinct currencies, and one row per pair per month. | Implemented |
| Provider client | Use Frankfurter's public v2 rates endpoint behind a small HTTP client. Keep provider parsing and transport errors in the adapter; let the importer choose observations and write snapshots. | Implemented |
| Conversion service | Read only the current month's stored snapshots. Return the original amount for the same currency, return null conversion fields for a missing pair, and include the available target currencies for the source. Do not fetch rates in this service. | Implemented |
| Snapshot importer | At the monthly run, use currencies on contracts active on that run date as base currencies. Fetch month-to-date observations, choose the earliest available observation per pair, and preserve existing monthly rows on retries. | Implemented |
| Schedule | Run the importer in production at 02:00 on the last calendar day of each month. | Implemented |
| Conversion API | Expose conversion through a separate authenticated `POST /api/v1/exchange_rates/convert` endpoint, not an employee controller. Return a conversion result and available target currencies; do not contact the provider per request. | Implemented |
| Employee detail UI | Show the native total and an optional converted total on active employee details; default the target to the contract currency, offer only targets returned by the API, and explain unavailable conversions while retaining the native value. | Planned |

## Consequences

- `period_month` identifies the lookup bucket; `rate_date` identifies the provider observation that supplied the stored rate. The database rejects a date outside that month.
- Later job executions cannot replace a saved pair for the same month. A provider failure before persistence leaves the importer without a partial set of newly fetched bases.
- A missing current-month pair has no live or prior-month fallback. The API returns null conversion amount, rate, and rate date; clients keep the native amount visible.
- The active contract currency, rather than country reference data, determines the FX base currency. This includes contracts whose currency overrides the country's default.
- Conversion does not alter compensation rows, employee totals, or dashboard totals. It is a separate display operation; no payroll or reporting calculation is introduced.
- The frontend has not yet integrated the conversion endpoint. Its agreed behavior is a planned follow-up, not current application behavior.

## Alternatives considered

1. Fetch a live rate when the client requests conversion: rejected because provider availability would affect page requests and rates could vary within a month.
2. Fetch base currencies from every country in reference data: rejected because the contract currency can differ from a country's default and unused currencies need no snapshots. Use currencies on currently active contracts instead.
3. Put conversion on the employee controller: rejected because conversion is an independent operation and may be useful to other clients or screens.
4. Replace the monthly pair when the job retries: rejected because it would let later observations silently change the value used during that month. Keep the earliest available monthly observation.
5. Fall back to a live or previous-month rate when the pair is absent: rejected; an unavailable conversion is explicit.
