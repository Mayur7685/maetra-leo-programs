program maetra_subscription.aleo;

record SubscriptionRecord:
    owner as address.private;
    creator as address.private;
    amount as u64.private;
    expires_at as u64.private;

mapping subscription_prices:
    key as address.public;
    value as u64.public;

mapping subscriber_counts:
    key as address.public;
    value as u64.public;

function set_price:
    input r0 as u64.public;
    gt r0 0u64 into r1;
    assert.eq r1 true;
    async set_price self.caller r0 into r2;
    output r2 as maetra_subscription.aleo/set_price.future;

finalize set_price:
    input r0 as address.public;
    input r1 as u64.public;
    set r1 into subscription_prices[r0];

function subscribe:
    input r0 as address.public;
    input r1 as u64.private;
    input r2 as u64.public;
    assert.neq self.caller r0;
    gt r1 0u64 into r3;
    assert.eq r3 true;
    gt r2 0u64 into r4;
    assert.eq r4 true;
    cast self.caller r0 r1 r2 into r5 as SubscriptionRecord.record;
    async subscribe r0 r1 into r6;
    output r5 as SubscriptionRecord.record;
    output r6 as maetra_subscription.aleo/subscribe.future;

finalize subscribe:
    input r0 as address.public;
    input r1 as u64.public;
    get.or_use subscription_prices[r0] 0u64 into r2;
    gte r1 r2 into r3;
    assert.eq r3 true;
    get.or_use subscriber_counts[r0] 0u64 into r4;
    add r4 1u64 into r5;
    set r5 into subscriber_counts[r0];

function verify_subscription:
    input r0 as SubscriptionRecord.record;
    input r1 as address.public;
    assert.eq r0.creator r1;
    cast r0.owner r0.creator r0.amount r0.expires_at into r2 as SubscriptionRecord.record;
    output r2 as SubscriptionRecord.record;

constructor:
    assert.eq edition 0u16;
