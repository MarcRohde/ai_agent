# Skill: API Resilience & Throttling

## Description
Implement robust API calls with retry logic, exponential backoff, rate limit handling, and throttling budget management. Parse server-provided backoff hints (e.g., `Retry-After`, `BackOffMilliseconds`) and adapt request rates dynamically to avoid 429/503 errors and service degradation.

## Inputs

| Input | Required | Description |
|-------|----------|-------------|
| `api_name` | Yes | API being integrated (e.g., Exchange EWS, Microsoft Graph, REST API) |
| `operations` | Yes | List of API operations to wrap with resilience patterns |
| `max_retries` | No | Maximum retry attempts (default: 6) |
| `initial_backoff_seconds` | No | Starting backoff delay (default: 2 seconds) |
| `max_backoff_seconds` | No | Maximum backoff cap (default: 180 seconds) |
| `batch_size` | No | Batch size for batch operations (research optimal size) |
| `inter_batch_delay` | No | Delay between batches to prevent budget exhaustion |

## Steps

1. **Research API Throttling Policies** — Use `fetch_webpage` to find official documentation on rate limits, throttling policies, and error codes. Key information:
   - Requests per minute/hour limits
   - Concurrent connection limits
   - Batch size recommendations
   - Error codes for throttling (HTTP 429, 503, or API-specific codes like `ErrorServerBusy`)
   - Server-provided backoff hint headers/fields

2. **Identify Transient vs Permanent Errors** — Classify error types:
   - **Retriable**: Throttling (429/503), timeouts, server errors (500-504), network errors
   - **Non-retriable**: Authentication (401), authorization (403), bad request (400), not found (404)

3. **Implement Exponential Backoff** — Start with `initial_backoff_seconds`, double after each retry, cap at `max_backoff_seconds`. Formula: `delay = min(initial * (2 ^ attempt), max_backoff_seconds)`.

4. **Parse Server Backoff Hints** — Honor server-provided delay hints:
   - HTTP `Retry-After` header (seconds or HTTP date)
   - Custom fields (e.g., `BackOffMilliseconds` in EWS XML responses)
   - Trailing numbers in error messages (e.g., "ErrorServerBusy...84603" = 84.6 seconds)
   - **Always prefer server hint over exponential calculation**

5. **Add Batch Processing with Delays** — For bulk operations:
   - Split work into batches (research optimal size per API)
   - Add `inter_batch_delay` to allow server budgets to recharge
   - Log batch progress for visibility

6. **Implement Circuit Breaker (Optional)** — For repeated failures, temporarily stop requests to allow service recovery. Track consecutive failures and open circuit after threshold.

7. **Add Comprehensive Logging** — Log:
   - Retry attempts with backoff duration
   - Throttling events with server hints
   - Final success/failure status
   - Cumulative API call statistics

## Output

A retry wrapper function that handles transient errors automatically. Include verbose logging for troubleshooting.

```powershell
# PowerShell Example
function Invoke-ApiWithRetry {
    param(
        [ScriptBlock]$Operation,
        [int]$MaxRetries = 6,
        [int]$InitialBackoff = 2,
        [int]$MaxBackoff = 180
    )
    
    for ($attempt = 1; $attempt -le $MaxRetries; $attempt++) {
        try {
            return & $Operation
        }
        catch {
            # Parse server backoff hints from exception
            $backoffSeconds = Get-ServerBackoffHint -Error $_
            
            if (-not $backoffSeconds) {
                $backoffSeconds = [Math]::Min($InitialBackoff * [Math]::Pow(2, $attempt - 1), $MaxBackoff)
            }
            
            if ($attempt -eq $MaxRetries) {
                throw
            }
            
            Write-Verbose "Retry $attempt/$MaxRetries after ${backoffSeconds}s"
            Start-Sleep -Seconds $backoffSeconds
        }
    }
}
```

```python
# Python Example
import time
from typing import Callable, Any

def api_retry(
    operation: Callable[[], Any],
    max_retries: int = 6,
    initial_backoff: float = 2.0,
    max_backoff: float = 180.0
) -> Any:
    """Execute operation with exponential backoff retry logic"""
    for attempt in range(1, max_retries + 1):
        try:
            return operation()
        except Exception as e:
            # Parse server backoff hint
            backoff = parse_backoff_hint(e) or min(
                initial_backoff * (2 ** (attempt - 1)),
                max_backoff
            )
            
            if attempt == max_retries:
                raise
            
            print(f"Retry {attempt}/{max_retries} after {backoff}s")
            time.sleep(backoff)
```

## Referenced Prompts
- `prompts/system/default_system.md`

## Referenced Tools
- `fetch_webpage` (research API throttling documentation)

## Tags
`api-integration`, `resilience`, `retry-logic`, `throttling`, `rate-limiting`, `error-handling`
