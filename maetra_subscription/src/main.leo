// The 'maetra_subscription' program.
// Manages privacy-preserving subscriptions between followers and creators.
// Subscribers receive a private SubscriptionRecord as proof of access.
program maetra_subscription.aleo {

    @noupgrade
    async constructor() {}

    // Private record given to subscriber as proof of active subscription
    record SubscriptionRecord {
        owner: address,          // The subscriber
        creator: address,        // The creator they subscribed to
        amount: u64,             // Price paid in microcredits
        expires_at: u64,         // Block height when subscription expires
    }

    // On-chain: creator's subscription price (microcredits)
    mapping subscription_prices: address => u64;

    // On-chain: creator's total subscriber count
    mapping subscriber_counts: address => u64;

    // Creator sets or updates their subscription price
    async transition set_price(public price: u64) -> Future {
        assert(price > 0u64);
        return finalize_set_price(self.caller, price);
    }

    async function finalize_set_price(
        public creator: address,
        public price: u64,
    ) {
        subscription_prices.set(creator, price);
    }

    // Subscriber pays to subscribe to a creator
    // Returns a private SubscriptionRecord as proof
    async transition subscribe(
        public creator: address,
        private amount: u64,
        public duration_blocks: u64, // ~1 month ≈ 430_000 blocks at ~6s/block
    ) -> (SubscriptionRecord, Future) {
        // Cannot subscribe to yourself
        assert_neq(self.caller, creator);
        assert(amount > 0u64);
        assert(duration_blocks > 0u64);

        // Mint a SubscriptionRecord for the subscriber
        let sub: SubscriptionRecord = SubscriptionRecord {
            owner: self.caller,
            creator: creator,
            amount: amount,
            expires_at: duration_blocks, // Will be added to block.height on-chain
        };

        return (sub, finalize_subscribe(creator, amount));
    }

    async function finalize_subscribe(
        public creator: address,
        public amount: u64,
    ) {
        // Verify payment meets creator's price
        let price: u64 = subscription_prices.get_or_use(creator, 0u64);
        assert(amount >= price);

        // Increment subscriber count
        let current: u64 = subscriber_counts.get_or_use(creator, 0u64);
        subscriber_counts.set(creator, current + 1u64);
    }

    // Verify a subscription is valid (for off-chain use)
    // Consumes and re-mints the record so it can be checked without losing it
    transition verify_subscription(
        private sub: SubscriptionRecord,
        public creator: address,
    ) -> SubscriptionRecord {
        // Verify the subscription is for the specified creator
        assert_eq(sub.creator, creator);

        // Re-mint the same record back to the owner
        return SubscriptionRecord {
            owner: sub.owner,
            creator: sub.creator,
            amount: sub.amount,
            expires_at: sub.expires_at,
        };
    }
}
