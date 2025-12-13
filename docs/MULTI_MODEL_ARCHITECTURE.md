# Multi-Model AI Architecture

FURG uses an intelligent multi-model routing system that optimizes for both cost and quality by routing requests to the most appropriate AI model based on intent.

## Overview

Instead of using a single expensive model for all requests, FURG routes each message to the optimal model:

| Intent | Model | Cost/1M Tokens | Use Case |
|--------|-------|----------------|----------|
| Roasting & Casual | Grok 4 Fast | $0.20 / $0.50 | 60% of traffic |
| Financial Advice | Claude Sonnet | $3.00 / $15.00 | 25% of traffic |
| Categorization | Gemini Flash | $0.075 / $0.30 | 15% of traffic |

**Result: 94% cost reduction** compared to using Claude for everything.

## Architecture Diagram

```
                         ┌─────────────────────────────────────┐
                         │           User Message              │
                         └──────────────────┬──────────────────┘
                                            │
                                            ▼
                         ┌─────────────────────────────────────┐
                         │        Local Heuristics             │
                         │   (Handles 70% without API call)    │
                         └──────────────────┬──────────────────┘
                                            │ ambiguous
                                            ▼
                         ┌─────────────────────────────────────┐
                         │      Gemini Flash (Router)          │
                         │        ~$0.00001/request            │
                         └──────────────────┬──────────────────┘
                                            │
              ┌─────────────────────────────┼─────────────────────────────┐
              │                             │                             │
              ▼                             ▼                             ▼
┌─────────────────────────┐   ┌─────────────────────────┐   ┌─────────────────────────┐
│      Grok 4 Fast        │   │     Claude Sonnet       │   │     Gemini Flash        │
│                         │   │                         │   │                         │
│  - Roasting/banter      │   │  - Financial advice     │   │  - Categorization       │
│  - Casual chat          │   │  - Complex questions    │   │  - Receipt scanning     │
│  - Greetings            │   │  - Sensitive topics     │   │  - Transaction classify │
│                         │   │                         │   │                         │
│  Cost: $0.20/$0.50      │   │  Cost: $3.00/$15.00     │   │  Cost: $0.075/$0.30     │
│  ~$0.00007/request      │   │  ~$0.00127/request      │   │  ~$0.00005/request      │
└─────────────────────────┘   └─────────────────────────┘   └─────────────────────────┘
```

## Intent Classification

### Local Heuristics (Fast Path)

Before calling any API, the router checks for obvious patterns:

```python
# Roast intent (-> Grok)
"roast", "roasting", "mock", "burn"
"hey", "hi", "hello", "what's up"  # Greetings

# Advice intent (-> Claude)
"should i", "is it worth", "can i afford"
"advice", "recommend", "budget"

# Categorize intent (-> Gemini)
"category", "categorize"

# Sensitive intent (-> Claude)
"broken", "not working", "bug", "issue"
```

This handles ~70% of requests without any API call.

### Gemini Router (Ambiguous Cases)

For messages that don't match heuristics, Gemini Flash classifies intent:

```json
{
  "intent": "roast",
  "confidence": 0.85,
  "reasoning": "user asking about spending in casual tone"
}
```

## Model Specializations

### Grok 4 Fast - Roasting Engine

**Why Grok for roasting:**
- Naturally edgy, sarcastic personality
- 93% cheaper than Claude
- Faster response times (~400ms)
- Automatic prompt caching (75% off repeated prefixes)

**Prompt structure:**
```
[STABLE PREFIX - Cached]
You are FURG's roasting engine...
Rules, personality, examples...

[DYNAMIC CONTEXT - Fresh]
User: {name}
Balance: ${balance}
Last transaction: ${amount} at {merchant}
Stress level: {stress}

[USER MESSAGE]
```

### Claude Sonnet - Financial Advisor

**Why Claude for advice:**
- Superior reasoning for financial decisions
- More nuanced, careful with sensitive topics
- Better at weighing trade-offs
- Handles complex multi-step analysis

**Used for:**
- "Should I buy this?"
- Budget planning
- Investment questions
- Debt payoff strategies
- Any request involving real financial decisions

### Gemini Flash - Utility Engine

**Why Gemini for utilities:**
- Cheapest option ($0.075/1M input)
- Excellent for structured tasks
- Vision capabilities for receipts
- Fast batch processing

**Used for:**
- Intent routing
- Transaction categorization
- Receipt OCR/scanning
- Merchant classification

## Context Caching Strategy

### Three-Layer Cache

```
┌─────────────────────────────────────────────────────────────┐
│                    LAYER 1: STATIC                          │
│                 TTL: 24 hours                               │
│  • Personality prompt    • User name/preferences            │
│  • Roasting rules        • Intensity mode                   │
│  • Core instructions     • Savings goals                    │
├─────────────────────────────────────────────────────────────┤
│                    LAYER 2: SLOW-CHANGING                   │
│                 TTL: 1 hour                                 │
│  • Health context (sleep, stress, HRV)                      │
│  • Location context (home/work/travel)                      │
│  • Calendar events (upcoming expenses)                      │
│  • Spending patterns (weekly averages)                      │
├─────────────────────────────────────────────────────────────┤
│                    LAYER 3: DYNAMIC                         │
│                 TTL: None (always fresh)                    │
│  • Current balance                                          │
│  • Last 3 transactions                                      │
│  • Today's spending                                         │
│  • Active alerts                                            │
└─────────────────────────────────────────────────────────────┘
```

### Provider-Specific Caching

| Provider | Cache Method | Savings |
|----------|--------------|---------|
| Grok | Automatic (keep prefix stable) | 75% |
| Claude | Manual (`cache_control`) | 90% |
| Gemini | Explicit `CachedContent` API | 75% |

## Cost Analysis

### Per-Request Costs

| Route | Router | Model | Total |
|-------|--------|-------|-------|
| Roast | $0.00001 | $0.00007 | **$0.00008** |
| Advice | $0.00001 | $0.00127 | **$0.00128** |
| Categorize | $0.00001 | $0.00005 | **$0.00006** |

### Blended Cost (Based on Traffic Mix)

| Traffic Type | % | Cost | Weighted |
|--------------|---|------|----------|
| Roast/casual | 60% | $0.00008 | $0.000048 |
| Advice | 25% | $0.00128 | $0.000320 |
| Categorize | 15% | $0.00006 | $0.000009 |
| **Blended** | | | **$0.00037** |

### Monthly Cost Projection

| Users | Requests/Day | Pure Claude | Multi-Model | Savings |
|-------|--------------|-------------|-------------|---------|
| 1,000 | 50,000 | $9,000 | $555 | $8,445 |
| 10,000 | 500,000 | $90,000 | $5,550 | $84,450 |
| 100,000 | 5,000,000 | $900,000 | $55,500 | $844,500 |

## Configuration

### Environment Variables

```bash
# Required API Keys
ANTHROPIC_API_KEY=sk-ant-...      # Claude
XAI_API_KEY=xai-...               # Grok
GOOGLE_API_KEY=...                # Gemini

# Feature Flag
USE_MULTI_MODEL_CHAT=true         # Enable multi-model (default: true)

# Optional: Redis for distributed caching
REDIS_URL=redis://localhost:6379
```

### Disabling Multi-Model

To fall back to Claude-only mode:

```bash
USE_MULTI_MODEL_CHAT=false
```

## API Response

The chat endpoint now includes routing metadata:

```json
{
  "message": "Nice $47 Uber at 2am. Your wallet called - it's filing for divorce.",
  "model": "grok-4-fast",
  "intent": "roast",
  "tokens_used": {
    "input": 450,
    "output": 35,
    "cached": 380
  },
  "cost": 0.000079,
  "latency_ms": 423
}
```

### Routing Stats Endpoint

```
GET /api/v1/chat/routing-stats
```

Returns model usage statistics and costs.

## File Structure

```
backend/services/
├── chat.py              # Legacy single-model (Claude only)
├── chat_v2.py           # Multi-model chat service
├── model_router.py      # Orchestrates model routing
├── grok_service.py      # Grok API integration
├── gemini_service.py    # Gemini API integration
└── context_cache.py     # Layered caching system
```

## Adding New Models

To add a new model to the router:

1. Create service in `backend/services/{model}_service.py`
2. Add intent mapping in `model_router.py`:
   ```python
   INTENT_MODEL_MAP = {
       ModelIntent.NEW_INTENT: "new_model",
   }
   ```
3. Implement `_call_{model}()` method in `ModelRouter`
4. Add cost tracking in `COSTS` dict

## Monitoring

### Key Metrics to Track

- **Intent distribution**: % of requests per intent type
- **Cache hit rate**: % of tokens served from cache
- **Model latency**: p50/p95/p99 response times per model
- **Cost per user**: Daily/monthly spend per active user
- **Routing accuracy**: Manual review of edge cases

### Logging

All routing decisions are logged to `model_routing_logs` table:

```sql
SELECT
    model,
    COUNT(*) as requests,
    AVG(cost) as avg_cost,
    AVG(latency_ms) as avg_latency,
    SUM(cached_tokens)::float / SUM(input_tokens + cached_tokens) as cache_rate
FROM model_routing_logs
WHERE created_at > NOW() - INTERVAL '7 days'
GROUP BY model;
```

## Business Impact

### Unit Economics

| Scenario | Revenue/User | AI Cost/User | Margin |
|----------|--------------|--------------|--------|
| Pure Claude | $9.99/mo | $45-150/mo | -350% to -1400% |
| Multi-Model | $9.99/mo | $8-25/mo | +20% to +60% |

### Break-Even Analysis

- **Pure Claude**: Never profitable at $9.99/mo
- **Multi-Model**: Profitable immediately
- **Required price (Claude only)**: $50+/mo to break even

## Future Improvements

1. **On-device routing**: Move heuristics to iOS for zero-latency classification
2. **Learned routing**: Train classifier on actual usage patterns
3. **Dynamic model selection**: Adjust based on response quality feedback
4. **Cost alerts**: Notify when users approach budget limits
5. **A/B testing**: Compare model quality on same queries
