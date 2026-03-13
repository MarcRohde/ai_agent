# Cost-Optimization Patterns for AI Agent Skills

**Date:** 2026-03-08
**Context:** Skill complexity routing, model selection strategy, and resource efficiency patterns

---

## Header

- Purpose: Document cost-efficiency patterns for skill execution and tool selection.
- Use when: Designing or revising skills where data transfer, call count, and model usage affect cost.
- Scope: `ai_agent` skill design and operational execution patterns.

---

## Content

## Purpose

This document establishes patterns for optimizing AI agent costs while maintaining quality. It provides guidance on when to use efficient methods, when to escalate to more powerful models, and how to structure skills to minimize token usage and API calls.

---

## Core Principles

### 1. Complexity-Based Routing
- **Simple tasks** → Use efficient, direct methods with minimal token overhead
- **Moderate tasks** → Standard agent with optimized tool selection
- **Complex tasks** → Escalate to specialized agents or more capable models only when necessary

### 2. Tool Efficiency First
- Prefer single API calls over multiple chained calls
- Use server-side filtering (search APIs) over client-side filtering (retrieve all, then filter)
- Leverage indexed search over sequential scans
- Cache reference data (lookup tables) to avoid repeated queries

### 3. Data Transfer Minimization
- Request only required fields, not full objects
- Use pagination smartly (retrieve what's needed, not maximum)
- Avoid "fetch everything then process" patterns
- Filter at the source, not in post-processing

---

## Lessons Learned

### Azure DevOps Work Item Queries

**Problem:** Initial approach retrieved 473+ items (56KB) then required multiple 200-item batch queries (82KB each) totaling 150KB+ data transfer.

**Solution:** Discovered `mcp_microsoft_azu_search_workitem` with `searchText:"assignedTo:email"` syntax provides:
- **3-5x faster** execution
- **60-80% less** data transfer (20-50KB single call)
- **Server-side filtering** by state, project, and assignee
- **Single API call** vs 3-5 chained calls

**Pattern Established:**
```
✅ Use: mcp_microsoft_azu_search_workitem with filters
❌ Avoid: list_backlog_work_items + batch queries
```

**Cost Impact:**
- Old method: ~150-200KB data, 3-5 API calls, higher token processing
- New method: ~20-50KB data, 1 API call, minimal token overhead
- **Estimated 70% cost reduction** for assignee queries

### Name-to-Email Resolution

**Problem:** Users provide partial names ("Kyle", "Matthew") requiring identity lookup before work item queries.

**Solution:** Created assignee reference table in skill documentation with 21+ staff members from past 6 months activity.

**Pattern Established:**
```
✅ Table lookup (instant, zero cost) → email → search query
❌ API search for identity → email → search query (2x API calls)
```

**Cost Impact:**
- Eliminates 1 API call per name-based query
- Zero token cost for name resolution
- **50% reduction** in identity-related queries

### Search Syntax Discovery

**Problem:** `assignedTo` parameter array returned 0 results despite correct email format.

**Solution:** Discovered `searchText` field supports special syntax: `"assignedTo:email@domain.com"` or `"assignedTo:FirstName"`.

**Lesson:** API parameter documentation may not reflect actual search capabilities. Test alternative syntaxes when standard parameters fail.

---

## Cost-Optimization Patterns

### Pattern 1: Reference Data Caching

**Use Case:** Frequently queried static or semi-static data (names, IDs, mappings)

**Implementation:**
- Store lookup tables in skill documentation
- Update quarterly or when new entries emerge
- Use markdown tables for easy parsing

**Example:**
```markdown
| Name | Email | Team |
|------|-------|------|
| Kyle Gilman | kgilman@andisco.com | CRM |
| Matthew Schmidt | mschmidt@andisco.com | IT |
```

**Cost Savings:** Eliminates identity/lookup API calls (100% reduction for cached entries)

---

### Pattern 2: Search Index > Backlog Queries

**Use Case:** Finding specific work items among large datasets

**Implementation:**
- Use dedicated search APIs with server-side filtering
- Apply state filters to exclude closed/resolved items
- Limit results to what's needed (top=50 vs unlimited)

**Example:**
```json
{
  "searchText": "assignedTo:user@domain.com",
  "state": ["New", "Active", "In Progress"],
  "top": 50
}
```

**Cost Savings:** 60-80% reduction in data transfer, 3-5x faster execution

---

### Pattern 3: Lazy Loading & Progressive Detail

**Use Case:** Displaying work item lists where user may want details on select items

**Implementation:**
1. Initial query returns IDs and minimal fields only
2. User selects specific items of interest
3. Fetch full details only for selected items

**Anti-Pattern:**
```
❌ Fetch all 200 items with full field details
❌ Process and format all 200 items
❌ User views only 5 items
```

**Optimized Pattern:**
```
✅ Fetch 200 items (IDs, title, state only)
✅ Display summary list
✅ Fetch full details for 5 user-selected items
```

**Cost Savings:** 70-90% reduction when user needs detail on <10% of results

---

### Pattern 4: Skill Complexity Metadata

**Use Case:** Guiding agent to use appropriate resources for different task complexities

**Implementation:** Add complexity section to skill frontmatter:

```markdown
## Complexity & Routing

### Task Complexity
- **Simple:** Query, retrieve, list operations
- **Moderate:** Create, update, link operations
- **Complex:** Bulk operations, migrations, custom workflows

### When to Use This Skill Directly
✅ Individual item operations
✅ Queries with known efficient methods
✅ Standard CRUD operations

### When to Escalate
❌ Bulk operations (>50 items)
❌ Complex multi-step workflows
❌ Custom field mappings
```

**Cost Savings:** Prevents over-provisioning of compute for simple tasks

---

### Pattern 5: Type-Based Filtering vs Content Search

**Use Case:** Analyzing specific work item types when content search returns mixed results

**Problem:**
- Content-based searches (e.g., "help desk") return all items mentioning the term
- Results include multiple work item types (User Story, Task, Feature, Help Desk)
- Analyzing wrong data set leads to incorrect metrics

**Implementation:**
```python
# Filter by work item type field, not content search
for item in search_results:
    if item['fields']['system.workitemtype'] != 'Help Desk':
        continue
    # Process only actual Help Desk work items
```

**Example:**
- Search for "help desk" returns 133 results
- Filter by `workitemtype = 'Help Desk'` reduces to 52 actual Help Desk items
- 61% reduction in data processing

**Best Practice:**
1. Use content search to find potentially relevant items
2. Apply type filter in post-processing for precise analysis
3. Document filter criteria in analysis scripts

**Cost Savings:**
- Eliminates processing of irrelevant items
- Produces accurate metrics without false data
- Reduces debugging time from analyzing wrong data set

---

## Skill Structure Best Practices

### 1. Document Efficient Methods First
Place performance-optimized approaches at the top of workflow sections. Mark deprecated/inefficient methods with warnings.

**Example:**
```markdown
## Querying Work Items by Assignee

**Recommended Method:** Use `mcp_microsoft_azu_search_workitem`
- 3-5x faster than backlog queries
- 60-80% less data transfer
- Single API call

⚠️ **Deprecated:** Using `list_backlog_work_items` for assignee queries
```

### 2. Include Performance Comparisons
Provide specific metrics so agents can make informed decisions.

**Example:**
```markdown
| Method | API Calls | Data Transfer | Execution Time |
|--------|-----------|---------------|----------------|
| Search API | 1 | 20-50KB | 1-2 seconds |
| Backlog + Batch | 3-5 | 150-200KB | 5-8 seconds |
```

### 3. Add Troubleshooting Sections
Document common pitfalls and their solutions to prevent trial-and-error cycles.

**Example:**
```markdown
## Troubleshooting

**Issue:** `assignedTo` parameter returns 0 results
**Solution:** Use `searchText:"assignedTo:email@domain.com"` instead
```

### 4. Maintain Reference Tables
Keep frequently-needed lookup data in the skill itself.

**Benefits:**
- Zero-cost lookups
- Consistent naming
- Historical audit trail

---

## Model Selection Strategy

### When Simple/Efficient Methods Suffice

**Characteristics:**
- Well-documented patterns in skill
- Single tool call required
- No complex reasoning needed
- Clear input → output mapping

**Examples:**
- Query work items by assignee name (table lookup + search)
- Retrieve specific work item details by ID
- List open items with state filter
- Search by keyword with known syntax

**Cost Impact:** Can use lighter models or efficient execution paths

---

### When to Consider Escalation

**Characteristics:**
- Multiple interdependent tool calls required
- Complex decision trees or error handling
- Novel patterns not documented in skill
- Requires cross-referencing multiple sources
- Bulk operations with >50 items

**Examples:**
- Work item migrations across projects
- Complex workflow customization
- Multi-step approval processes
- Custom field mappings requiring validation

**Cost Impact:** Justify higher-tier model usage with complexity

---

## Measurement & Continuous Improvement

### Tracking Efficiency Gains

**Metrics to Monitor:**
1. **API Calls per Task** — Target: ≤2 calls for standard operations
2. **Data Transfer Volume** — Target: <50KB for single-item queries, <200KB for lists
3. **Execution Time** — Target: <3 seconds for queries, <5 seconds for creates
4. **Token Usage** — Track context size and generation tokens per task type

### Feedback Loop

**When to Update Patterns:**
- New efficient APIs discovered → Document immediately
- Recurring inefficient patterns observed → Add to anti-patterns section
- Performance degradation noticed → Investigate tool changes
- User feedback on slow operations → Analyze and optimize

### Pattern Documentation Lifecycle

1. **Discovery** — Find more efficient method through testing
2. **Validation** — Confirm 2x+ improvement in key metric
3. **Documentation** — Add to skill with performance comparison
4. **Deprecation** — Mark old method with warnings
5. **Monitoring** — Track usage shift to new pattern

---

## Action Items & Recommendations

### Immediate Actions
1. ✅ **Completed:** Added complexity routing to Azure DevOps work item skill
2. ✅ **Completed:** Documented efficient search patterns with performance metrics
3. ✅ **Completed:** Established assignee reference table for zero-cost lookups

### Short-Term (Next 2 Weeks)
1. Review other skills for similar optimization opportunities (SQL changes, BI semantic views)
2. Add performance metrics to frequently-used skills
3. Document reference data patterns for other domains (warehouse codes, customer types)

### Medium-Term (Next Month)
1. Create skill performance dashboard (track improvements over time)
2. Establish baseline metrics for all skill operations
3. Add automated performance regression detection
4. Create skill template with complexity routing section

### Long-Term (Next Quarter)
1. Develop skill complexity scoring system
2. Create automated tool efficiency analyzer
3. Build recommendation engine for skill optimization opportunities
4. Establish skill certification process (performance benchmarks)

---

## Summary

**Key Takeaways:**
1. **Search APIs > Backlog Queries:** Use indexed search with server-side filtering for 3-5x performance gains
2. **Reference Tables > Repeated Lookups:** Cache static/semi-static data in skills for zero-cost access
3. **Complexity Metadata Matters:** Explicit routing guidance prevents over-provisioning
4. **Document Performance:** Specific metrics guide better tool selection
5. **Continuous Measurement:** Track efficiency gains and iterate

**Expected Cost Impact:**
- **Assignee queries:** 70% reduction (search optimization + name caching)
- **Identity lookups:** 100% elimination (reference table pattern)
- **Bulk operations:** 50-80% reduction (complexity routing prevents unnecessary processing)
- **Overall:** Estimated 40-60% cost reduction for Azure DevOps work item operations

**ROI Timeline:**
- Immediate: Search optimization benefits (within same session)
- 1 week: Reference table coverage reaches 80% of queries
- 1 month: Complexity routing patterns established across skills
- 1 quarter: Measurable cost reduction across all agent operations

---

## References

- Skill: [azure_devops_work_item/skill.md](../skills/azure_devops_work_item/skill.md)
- Azure DevOps Search API: `mcp_microsoft_azu_search_workitem`
- Performance Test Results: Mica (60 items), Karin (114 items), Matthew (25 items), Kyle (181 items)
- Date: 2026-03-08

---

## Learning Log

- 2026-03-08 | Indexed search with server-side filtering should be preferred over backlog-plus-batch patterns for lower cost and faster execution.
- 2026-03-08 | Reference table lookups in skill docs can eliminate repeated identity-resolution API calls.
- 2026-03-08 | Fetch-minimum-first and lazy detail loading significantly reduces unnecessary transfer and token usage.
- 2026-03-08 | Work item type filtering is required for accurate analysis when keyword search returns mixed item types.
- 2026-03-08 | Complexity routing guidance in skills helps prevent overuse of expensive execution paths for simple tasks.
