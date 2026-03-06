program maetra_trust.aleo;

mapping trust_scores:
    key as address.public;
    value as u64.public;

mapping win_rates:
    key as address.public;
    value as u64.public;

mapping trade_counts:
    key as address.public;
    value as u64.public;

mapping weight_classes:
    key as address.public;
    value as u8.public;

mapping win_streaks:
    key as address.public;
    value as u64.public;

closure approximate_log:
    input r0 as u64;
    lte r0 1u64 into r1;
    lte r0 10u64 into r2;
    lte r0 100u64 into r3;
    lte r0 1000u64 into r4;
    lte r0 10000u64 into r5;
    ternary r5 400u64 500u64 into r6;
    ternary r4 300u64 r6 into r7;
    ternary r3 200u64 r7 into r8;
    ternary r2 100u64 r8 into r9;
    ternary r1 0u64 r9 into r10;
    output r10 as u64;

function submit_performance:
    input r0 as u64.private;
    input r1 as u64.private;
    input r2 as u64.private;
    input r3 as u64.private;
    input r4 as u64.private;
    gt r1 0u64 into r5;
    assert.eq r5 true;
    lte r0 r1 into r6;
    assert.eq r6 true;
    mul r0 10000u64 into r7;
    div r7 r1 into r8;
    gte r4 50000000u64 into r9;
    gte r4 10000000u64 into r10;
    ternary r10 1u8 0u8 into r11;
    ternary r9 2u8 r11 into r12;
    add r2 1u64 into r13;
    call approximate_log r13 into r14;
    mul r8 r14 into r15;
    div r15 10000u64 into r16;
    async submit_performance self.caller r8 r2 r16 r12 r3 into r17;
    output r17 as maetra_trust.aleo/submit_performance.future;

finalize submit_performance:
    input r0 as address.public;
    input r1 as u64.public;
    input r2 as u64.public;
    input r3 as u64.public;
    input r4 as u8.public;
    input r5 as u64.public;
    set r3 into trust_scores[r0];
    set r1 into win_rates[r0];
    set r2 into trade_counts[r0];
    set r4 into weight_classes[r0];
    set r5 into win_streaks[r0];

constructor:
    assert.eq edition 0u16;
