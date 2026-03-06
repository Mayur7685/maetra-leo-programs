# Maetra Leo Programs — Architecture & Integration

## Overview

Maetra uses three Leo programs deployed on Aleo testnet to provide privacy-preserving trading reputation, subscriptions, and content verification. The programs leverage Aleo's zero-knowledge proof system so traders can prove their performance without revealing raw trade data.

## Deployed Programs

| Program | Transaction ID | Purpose |
|---|---|---|
| `maetra_trust.aleo` | `at1e42jduhvfxxen7e0pwmphpm8d2jklezq0glk2qgypzq6ktyz3gzqr4cxas` | ZK trust scores & leaderboard |
| `maetra_subscription.aleo` | `at1g2y9txst0d334kt5lcshsnvykgnwcfmd0jpvfwur7tt2qma94yqsxaev6k` | Private subscription records |
| `maetra_content.aleo` | `at1jp0lnxeynnp0zn7uqhdtgf257m3ghg87s5zqdnt23ey47wxshqpq0nfmww` | Content hash registry |

- Deployer address: `aleo14c2afj8u0mdgqe8drgx5h65qealr3wtl8n9c9vgt3c8zy20q8ggsvpvq8k`
- Network: **testnet** | Endpoint: `https://api.explorer.provable.com/v1`

---

## 1. maetra_trust.aleo — ZK Trust Score Engine

### What it does

Computes a verifiable trust score from a trader's performance metrics. All inputs are **private** — the ZK proof guarantees correctness without revealing actual trade data on-chain. Only computed scores are stored publicly.

### On-chain mappings (public)

| Mapping | Type | Description |
|---|---|---|
| `trust_scores` | `address => u64` | Trust score x100 (fixed point) |
| `win_rates` | `address => u64` | Win rate x10000 (e.g. 7850 = 78.50%) |
| `trade_counts` | `address => u64` | Total verified trades |
| `weight_classes` | `address => u8` | 0=Lightweight, 1=Middleweight, 2=Heavyweight |
| `win_streaks` | `address => u64` | Current win streak |

### Transition: `submit_performance`

```
async transition submit_performance(
    private profitable_days: u64,
    private total_days: u64,
    private trade_count: u64,
    private current_streak: u64,
    private avg_volume_usd: u64,   // in cents
) -> Future
```

**Private inputs** (never revealed):
- `profitable_days` — days with positive PnL
- `total_days` — total trading days in the period
- `trade_count` — number of trades
- `current_streak` — consecutive winning days
- `avg_volume_usd` — average monthly volume in cents

**On-chain computation**:
1. Win rate = `(profitable_days * 10000) / total_days`
2. Weight class based on volume: <$100K = Lightweight, $100K-$500K = Middleweight, >$500K = Heavyweight
3. Trust score = `win_rate * log_approx(trade_count + 1) / 10000`
4. All results written to public mappings under the caller's address

### How the app uses it

```
Exchange API → Backend Pipeline → Leo Inputs → Wallet executes submit_performance → Leaderboard updated
```

1. User connects exchange (Hyperliquid/Binance) on the frontend
2. Backend fetches trade history via exchange APIs
3. Pipeline computes metrics and formats them as Leo u64 inputs
4. Frontend calls `submit_performance` via the user's Aleo wallet (Shield/Leo)
5. ZK proof is generated client-side — the network verifies correctness
6. Public mappings update, feeding the leaderboard

---

## 2. maetra_subscription.aleo — Private Subscriptions

### What it does

Manages privacy-preserving subscriptions between followers and creators. Subscribers receive a **private SubscriptionRecord** as proof of access — no one else can see who subscribes to whom.

### Record type

```leo
record SubscriptionRecord {
    owner: address,      // The subscriber
    creator: address,    // The creator they subscribed to
    amount: u64,         // Price paid in microcredits
    expires_at: u64,     // Block height when subscription expires
}
```

### On-chain mappings

| Mapping | Type | Description |
|---|---|---|
| `subscription_prices` | `address => u64` | Creator's price in microcredits |
| `subscriber_counts` | `address => u64` | Total subscriber count per creator |

### Transitions

| Transition | Description |
|---|---|
| `set_price(public price: u64)` | Creator sets their subscription price |
| `subscribe(public creator, private amount, public duration_blocks)` | Pay to subscribe; returns a private `SubscriptionRecord` |
| `verify_subscription(private sub, public creator)` | Verify a subscription is valid; re-mints the record |

### How the app uses it

```
Creator sets price → Subscriber pays via wallet → Private record minted → Access granted
```

1. Creator sets subscription price on My Page (stored on-chain via `set_price`)
2. Subscriber clicks "Subscribe" on a creator's profile
3. Wallet executes `subscribe` — payment happens on-chain, subscriber gets a private record
4. Backend verifies subscription status for content access
5. `verify_subscription` can be called to prove access without consuming the record

---

## 3. maetra_content.aleo — Content Hash Registry

### What it does

Registers content hashes on-chain so creators can prove they published alpha at a specific time. The actual content is stored off-chain (encrypted in the database); only the hash lives on-chain as a tamper-proof timestamp.

### On-chain mappings

| Mapping | Type | Description |
|---|---|---|
| `content_hashes` | `field => field` | post_id → content hash |
| `content_owners` | `field => address` | post_id → creator address |
| `post_counts` | `address => u64` | Creator's total published posts |

### Transitions

| Transition | Description |
|---|---|
| `publish(public post_id, public content_hash)` | Register content hash on-chain (one-time per post_id) |
| `verify_content(public post_id, public expected_hash, public expected_creator)` | Verify content authenticity |

### How the app uses it

```
Creator writes post → Backend encrypts & stores → Hash published on-chain → Subscribers decrypt with access
```

1. Creator writes a post on My Page
2. Backend stores encrypted content and generates a hash
3. `publish` is called to register the hash on-chain with the creator's address
4. Anyone can verify via `verify_content` that a specific post was published by a specific creator at a specific time
5. Subscribers with valid `SubscriptionRecord` can decrypt and read the full content

---

## Integration Architecture

### End-to-end data flow

```
┌─────────────────────────────────────────────────────────────────────┐
│  EXCHANGES (Hyperliquid / Binance)                                  │
│  Real trade data fetched via APIs                                   │
└──────────────────────────┬──────────────────────────────────────────┘
                           │ Trade history
                           ▼
┌─────────────────────────────────────────────────────────────────────┐
│  BACKEND PIPELINE (maetra-backend)                                  │
│                                                                     │
│  1. fetchTradeMetrics()  — Pull trades from connected exchanges     │
│  2. cachePerformance()   — Compute & cache in PostgreSQL            │
│  3. formatForLeo()       — Convert to Leo u64 input format          │
│                                                                     │
│  Output: { profitable_days: "23u64", total_days: "30u64", ... }     │
└──────────────────────────┬──────────────────────────────────────────┘
                           │ Leo-formatted inputs
                           ▼
┌─────────────────────────────────────────────────────────────────────┐
│  FRONTEND (maetra-app / Next.js)                                    │
│                                                                     │
│  User's Aleo wallet (Shield/Leo) executes the transition:           │
│  maetra_trust.aleo/submit_performance(private inputs...)            │
│                                                                     │
│  ZK proof generated CLIENT-SIDE — raw data never leaves the user    │
└──────────────────────────┬──────────────────────────────────────────┘
                           │ ZK transaction
                           ▼
┌─────────────────────────────────────────────────────────────────────┐
│  ALEO NETWORK (testnet)                                             │
│                                                                     │
│  - Verifies ZK proof                                                │
│  - Updates public mappings (trust_scores, win_rates, etc.)          │
│  - Leaderboard reads from these mappings                            │
└─────────────────────────────────────────────────────────────────────┘
```

### Key files

| File | Role |
|---|---|
| `programs/maetra_trust/src/main.leo` | Trust score ZK program |
| `programs/maetra_subscription/src/main.leo` | Subscription management program |
| `programs/maetra_content/src/main.leo` | Content hash registry program |
| `maetra-backend/src/lib/exchanges/pipeline.ts` | Proof pipeline (fetch → compute → format) |
| `maetra-backend/src/lib/exchanges/hyperliquid.ts` | Hyperliquid API client |
| `maetra-backend/src/lib/exchanges/binance.ts` | Binance API client |
| `maetra-backend/src/routes/exchanges.ts` | Exchange connection & sync endpoints |
| `maetra-app/src/context/WalletContext.tsx` | Aleo wallet adapter setup |
| `maetra-app/src/app/(dashboard)/my-page/page.tsx` | UI for sync & proof generation |

### Leo input format example

The backend pipeline outputs inputs formatted for the Leo program:

```json
{
  "profitable_days": "23u64",
  "total_days": "30u64",
  "trade_count": "150u64",
  "current_streak": "5u64",
  "avg_volume_usd": "15000000u64"
}
```

These are passed as private arguments to `submit_performance`. The ZK circuit proves the trust score computation is correct without revealing the raw values to anyone.

### Privacy guarantees

- **Trade data**: Never leaves the user's device. The backend computes Leo inputs, but the ZK proof is generated in the wallet.
- **Subscriptions**: Private records — only the subscriber knows they subscribed.
- **Content**: Encrypted off-chain; only the hash is public (proves timestamp, not content).
- **Leaderboard**: Shows computed scores (trust, win rate, weight class) but not underlying trade details.

---

## Development & Deployment

### Build

```bash
cd programs/maetra_trust && leo build --network testnet
cd programs/maetra_subscription && leo build --network testnet
cd programs/maetra_content && leo build --network testnet
```

### Deploy

```bash
leo deploy --network testnet \
  --private-key $PRIVATE_KEY \
  --endpoint "https://api.explorer.provable.com/v1" \
  --broadcast --yes
```

### Execute a transition (CLI example)

```bash
leo execute submit_performance \
  23u64 30u64 150u64 5u64 15000000u64 \
  --network testnet \
  --private-key $PRIVATE_KEY \
  --endpoint "https://api.explorer.provable.com/v1" \
  --broadcast --yes
```

### Requirements

- Leo 3.4+
- snarkOS (for local devnet testing)
- Aleo testnet credits for deployment and execution fees
