program maetra_content.aleo;

mapping content_hashes:
    key as field.public;
    value as field.public;

mapping content_owners:
    key as field.public;
    value as address.public;

mapping post_counts:
    key as address.public;
    value as u64.public;

function publish:
    input r0 as field.public;
    input r1 as field.public;
    async publish self.caller r0 r1 into r2;
    output r2 as maetra_content.aleo/publish.future;

finalize publish:
    input r0 as address.public;
    input r1 as field.public;
    input r2 as field.public;
    get.or_use content_hashes[r1] 0field into r3;
    assert.eq r3 0field;
    set r2 into content_hashes[r1];
    set r0 into content_owners[r1];
    get.or_use post_counts[r0] 0u64 into r4;
    add r4 1u64 into r5;
    set r5 into post_counts[r0];

function verify_content:
    input r0 as field.public;
    input r1 as field.public;
    input r2 as address.public;
    output true as boolean.private;

constructor:
    assert.eq edition 0u16;
