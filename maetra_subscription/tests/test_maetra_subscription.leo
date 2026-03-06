// The 'test_maetra_subscription' test program.
import maetra_subscription.aleo;
program test_maetra_subscription.aleo {
    @test
    script test_it() {
        let result: u32 = maetra_subscription.aleo/main(1u32, 2u32);
        assert_eq(result, 3u32);
    }

    @test
    @should_fail
    transition do_nothing() {
        let result: u32 = maetra_subscription.aleo/main(2u32, 3u32);
        assert_eq(result, 3u32);
    }

    @noupgrade
    async constructor() {}
}
