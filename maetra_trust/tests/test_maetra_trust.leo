// The 'test_maetra_trust' test program.
import maetra_trust.aleo;
program test_maetra_trust.aleo {
    @test
    script test_it() {
        let result: u32 = maetra_trust.aleo/main(1u32, 2u32);
        assert_eq(result, 3u32);
    }

    @test
    @should_fail
    transition do_nothing() {
        let result: u32 = maetra_trust.aleo/main(2u32, 3u32);
        assert_eq(result, 3u32);
    }

    @noupgrade
    async constructor() {}
}
