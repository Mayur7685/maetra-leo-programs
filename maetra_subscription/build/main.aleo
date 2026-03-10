import credits.aleo;
program maetra_subscription_v3.aleo;

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
    output r2 as maetra_subscription_v3.aleo/set_price.future;

finalize set_price:
    input r0 as address.public;
    input r1 as u64.public;
    set r1 into subscription_prices[r0];

function subscribe:
    input r0 as address.public;
    input r1 as u64.public;
    input r2 as u64.public;
    assert.neq self.caller r0;
    gt r1 0u64 into r3;
    assert.eq r3 true;
    gt r2 0u64 into r4;
    assert.eq r4 true;
    call credits.aleo/transfer_public_as_signer r0 r1 into r5;
    cast self.caller r0 r1 r2 into r6 as SubscriptionRecord.record;
    async subscribe r5 r0 r1 into r7;
    output r6 as SubscriptionRecord.record;
    output r7 as maetra_subscription_v3.aleo/subscribe.future;

finalize subscribe:
    input r0 as credits.aleo/transfer_public_as_signer.future;
    input r1 as address.public;
    input r2 as u64.public;
    await r0;
    get.or_use subscription_prices[r1] 0u64 into r3;
    gte r2 r3 into r4;
    assert.eq r4 true;
    get.or_use subscriber_counts[r1] 0u64 into r5;
    add r5 1u64 into r6;
    set r6 into subscriber_counts[r1];

function verify_subscription:
    input r0 as SubscriptionRecord.record;
    input r1 as address.public;
    assert.eq r0.creator r1;
    cast r0.owner r0.creator r0.amount r0.expires_at into r2 as SubscriptionRecord.record;
    output r2 as SubscriptionRecord.record;

constructor:
    assert.eq edition 0u16;
