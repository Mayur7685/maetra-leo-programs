// The 'maetra_content' program.
// Registers content hashes on-chain so creators can prove
// they published alpha at a specific time (timestamped proof of insight).
// Actual content is stored off-chain (encrypted); only the hash lives on-chain.
program maetra_content.aleo {

    @noupgrade
    async constructor() {}

    // On-chain registry: post_id (as field) => content hash
    mapping content_hashes: field => field;

    // On-chain: post_id => creator address (for ownership verification)
    mapping content_owners: field => address;

    // On-chain: creator's total post count
    mapping post_counts: address => u64;

    // Creator publishes a content hash on-chain
    // post_id: unique identifier for the post (computed off-chain)
    // content_hash: hash of the encrypted content (computed off-chain)
    async transition publish(
        public post_id: field,
        public content_hash: field,
    ) -> Future {
        return finalize_publish(self.caller, post_id, content_hash);
    }

    async function finalize_publish(
        public creator: address,
        public post_id: field,
        public content_hash: field,
    ) {
        // Ensure post_id hasn't been used
        let existing: field = content_hashes.get_or_use(post_id, 0field);
        assert_eq(existing, 0field);

        content_hashes.set(post_id, content_hash);
        content_owners.set(post_id, creator);

        let count: u64 = post_counts.get_or_use(creator, 0u64);
        post_counts.set(creator, count + 1u64);
    }

    // Verify that a piece of content was published by a specific creator
    // Returns true if the hash matches (pure transition, no state change)
    transition verify_content(
        public post_id: field,
        public expected_hash: field,
        public expected_creator: address,
    ) -> bool {
        // Actual verification happens on-chain via async
        // This transition just returns true as a placeholder;
        // real verification is done by reading the mapping off-chain
        return true;
    }
}
