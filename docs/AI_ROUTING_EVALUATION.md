# AI Model Routing Evaluation

**Date:** January 2025
**Status:** Recommended - Pending Implementation

---

## Executive Summary

Evaluated simplifying our multi-model AI architecture from 4 models to 2 models while improving quality and reducing costs. **Recommendation: Grok 4.1 + Gemini 3 Pro with local heuristics routing (no routing model needed).**

---

## Current Architecture (4 Models)

| Model | Role | Traffic % | Cost/1M Input |
|-------|------|-----------|---------------|
| Gemini 2.0 Flash | Intent routing | 30%* | $0.075 |
| Grok 4 Fast | Roasting, general chat | 60% | $0.20 |
| Claude Sonnet | Financial advice, sensitive | 25% | $3.00 |
| Gemini 2.0 Flash | Categorization, receipts | 15% | $0.075 |

*Local heuristics handle ~70% of routing; Gemini called for remaining 30%

**Blended cost:** ~$0.00037/request
**Complexity:** High (4 API integrations, routing logic)

---

## Models Evaluated

### DeepSeek V3

| Aspect | Finding |
|--------|---------|
| **Pricing** | $0.14/1M input, $0.28/1M output |
| **For Routing** | ❌ More expensive than Gemini Flash ($0.14 vs $0.075) |
| **For Financial Advice** | ❌ Less proven than Claude for nuanced guidance |
| **For Roasting** | ❌ Neutral tone, can't match Grok's personality |
| **Multimodal** | ❌ Text-only (no receipt scanning) |

**Verdict:** Not recommended for our use cases.

### Gemini 3 Pro (Released Nov 2025)

| Aspect | Finding |
|--------|---------|
| **Pricing** | $2.00/1M input, $12.00/1M output |
| **Reasoning** | ✅ World-leading (1501 Elo, 91.9% GPQA) |
| **Math** | ✅ 23.4% MathArena vs Claude's 1.6% |
| **Context Window** | ✅ 1M tokens (vs Claude's 200K) |
| **Multimodal** | ✅ Best-in-class image understanding |
| **vs Claude** | ✅ 33% cheaper, better at math/reasoning |

**Verdict:** Excellent replacement for Claude on financial advice + receipts.

### GPT-4o Mini (for routing)

| Aspect | Finding |
|--------|---------|
| **Pricing** | $0.15/1M input, $0.60/1M output |
| **vs Gemini Flash** | ❌ 2x more expensive |

**Verdict:** Not recommended. Gemini Flash is cheaper, but local heuristics are best.

---

## Recommended Architecture (2 Models)

### Overview

| Component | Model | Cost/1M Input | Use Case |
|-----------|-------|---------------|----------|
| **Routing** | Local heuristics | **$0** | Intent classification |
| **Chat/Personality** | Grok 4.1 | $0.20 | Roasting, general chat, greetings |
| **Financial/Analysis** | Gemini 3 Pro | $2.00 | Advice, calculations, receipts, deep analysis |

### Traffic Split

- **Grok 4.1:** ~65% of requests (casual chat, roasting)
- **Gemini 3 Pro:** ~35% of requests (anything money-related)

### Cost Comparison

| Architecture | Blended Cost/Request | Models | Routing Cost |
|--------------|---------------------|--------|--------------|
| Current | ~$0.00037 | 4 | $0.00001 |
| **Proposed** | ~$0.00040 | 2 | **$0** |

Slightly higher per-request cost (+8%), but:
- Better quality on financial advice (Gemini 3 Pro > Claude for math)
- Better receipt parsing (Gemini 3 Pro multimodal)
- Simpler codebase (2 integrations vs 4)
- No routing API costs
- Fewer failure points

---

## Local Heuristics Routing Logic

```python
def route_to_model(message: str) -> str:
    """
    Route message to appropriate model using local heuristics.
    No API call needed - 100% local, $0 cost.
    """
    msg = message.lower()

    # Financial/number topics → Gemini 3 Pro
    finance_triggers = [
        # Direct money words
        "budget", "spend", "spent", "spending", "save", "saving",
        "afford", "cost", "price", "worth", "money", "cash",
        "invest", "investment", "bill", "bills", "receipt",
        "balance", "income", "salary", "debt", "loan", "credit",

        # Question patterns about purchases
        "should i buy", "can i afford", "how much", "is it worth",
        "good deal", "too expensive", "waste of money",

        # Analysis requests
        "analyze", "breakdown", "report", "summary", "trend",
        "category", "categorize", "transactions"
    ]

    if any(trigger in msg for trigger in finance_triggers):
        return "gemini-3-pro"

    # Everything else → Grok (personality, chat, roasting)
    return "grok-4.1"
```

---

## Implementation Plan

### Phase 1: Add Gemini 3 Pro Integration
- [ ] Create `services/gemini3_service.py`
- [ ] Add Gemini 3 Pro API credentials to `.env`
- [ ] Implement financial advice prompt template
- [ ] Implement receipt parsing with multimodal

### Phase 2: Simplify Router
- [ ] Update `model_router.py` to use local heuristics only
- [ ] Remove Gemini Flash routing calls
- [ ] Update intent-to-model mapping for 2-model architecture

### Phase 3: Remove Claude Dependency
- [ ] Remove Claude API calls from `model_router.py`
- [ ] Remove `ANTHROPIC_API_KEY` dependency (optional - keep for fallback)
- [ ] Update cost tracking for new models

### Phase 4: Testing
- [ ] A/B test Gemini 3 Pro vs Claude on financial advice quality
- [ ] Monitor user satisfaction scores
- [ ] Track cost per request

---

## New Capabilities Enabled

### 1. Deep Financial Analysis
Gemini 3 Pro's 1M token context enables:
- Full year transaction analysis in single request
- Comprehensive spending pattern detection
- Detailed financial health reports

### 2. Better Receipt Parsing
Best-in-class multimodal for:
- Handwritten receipts
- Faded/damaged receipts
- Complex multi-item receipts

### 3. Improved Math Accuracy
23.4% MathArena (vs Claude's 1.6%):
- More accurate budget projections
- Better compound interest calculations
- Precise savings goal tracking

---

## Risk Mitigation

| Risk | Mitigation |
|------|------------|
| Gemini 3 Pro quality regression | Keep Claude credentials as fallback |
| Grok personality too edgy | Maintain intensity levels in prompt |
| Local heuristics miss edge cases | Log unclassified messages, refine triggers |
| API outages | Implement fallback responses |

---

## References

- [Gemini 3 for Developers - Google Blog](https://blog.google/technology/developers/gemini-3-developers/)
- [Gemini 3 Pro vs Claude 4.5 Comparison](https://www.cometapi.com/gemini-3-pro-vs-claude-4-5-sonnet-for-coding/)
- [Google Gemini 3 Pricing](https://www.eesel.ai/blog/google-gemini-3-pricing)
- [2025 AI Model Comparison](https://www.getpassionfruit.com/blog/gpt-5-1-vs-claude-4-5-sonnet-vs-gemini-3-pro-vs-deepseek-v3-2-the-definitive-2025-ai-model-comparison)

---

## Decision Log

| Date | Decision | Rationale |
|------|----------|-----------|
| Jan 2025 | Reject DeepSeek V3 | More expensive than Gemini for routing, no multimodal |
| Jan 2025 | Reject GPT-4o mini for routing | 2x more expensive than Gemini Flash |
| Jan 2025 | Adopt Gemini 3 Pro | Better math/reasoning than Claude, 33% cheaper |
| Jan 2025 | Keep Grok 4.1 | Best personality for roasting, cost-effective |
| Jan 2025 | Use local heuristics only | Eliminates routing API cost entirely |
