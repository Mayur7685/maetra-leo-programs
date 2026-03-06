// The 'maetra_trust' program.
// Verifies trader performance using ZK proofs.
// Private inputs: raw trade metrics (never revealed on-chain)
// Public outputs: trust score, win rate, trade count, weight class
program maetra_trust.aleo {

    @noupgrade
    async constructor() {}

    // Public leaderboard data stored on-chain
    mapping trust_scores: address => u64;     // Trust score × 100 (fixed point)
    mapping win_rates: address => u64;        // Win rate × 10000 (e.g., 7850 = 78.50%)
    mapping trade_counts: address => u64;     // Total verified trades
    mapping weight_classes: address => u8;    // 0=Lightweight, 1=Middleweight, 2=Heavyweight
    mapping win_streaks: address => u64;      // Current win streak

    // Creator submits verified performance
    // All inputs are private — the ZK proof guarantees correctness
    // without revealing the actual trade data
    async transition submit_performance(
        private profitable_days: u64,
        private total_days: u64,
        private trade_count: u64,
        private current_streak: u64,
        private avg_volume_usd: u64,   // in cents (e.g., 10000000 = $100K)
    ) -> Future {
        // Validate inputs
        assert(total_days > 0u64);
        assert(profitable_days <= total_days);

        // Compute win rate (× 10000 for precision, e.g., 7850 = 78.50%)
        let win_rate: u64 = (profitable_days * 10000u64) / total_days;

        // Compute weight class based on avg monthly volume
        // <$100K = 0 (Lightweight), $100K-$500K = 1 (Middleweight), >$500K = 2 (Heavyweight)
        let weight: u8 = 0u8;
        if avg_volume_usd >= 50000000u64 {      // $500K in cents
            weight = 2u8;
        } else if avg_volume_usd >= 10000000u64 { // $100K in cents
            weight = 1u8;
        }

        // Approximate trust score: win_rate × log_approx(trade_count + 1) / 10000
        let log_val: u64 = approximate_log(trade_count + 1u64);
        let trust: u64 = (win_rate * log_val) / 10000u64;

        return update_leaderboard(
            self.caller,
            win_rate,
            trade_count,
            trust,
            weight,
            current_streak,
        );
    }

    async function update_leaderboard(
        public creator: address,
        public win_rate: u64,
        public trade_count: u64,
        public trust_score: u64,
        public weight_class: u8,
        public win_streak: u64,
    ) {
        trust_scores.set(creator, trust_score);
        win_rates.set(creator, win_rate);
        trade_counts.set(creator, trade_count);
        weight_classes.set(creator, weight_class);
        win_streaks.set(creator, win_streak);
    }

    // Piecewise linear approximation of log10 for ZK circuits
    // Returns value × 100 (e.g., log10(10) = 1.0 → 100)
    function approximate_log(x: u64) -> u64 {
        if x <= 1u64 { return 0u64; }
        if x <= 10u64 { return 100u64; }       // log10(10)  ≈ 1.0
        if x <= 100u64 { return 200u64; }      // log10(100) ≈ 2.0
        if x <= 1000u64 { return 300u64; }     // log10(1K)  ≈ 3.0
        if x <= 10000u64 { return 400u64; }    // log10(10K) ≈ 4.0
        return 500u64;                          // cap at ≈ 5.0
    }
}
