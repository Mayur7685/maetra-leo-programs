// The 'test_maetra_content' test program.
import maetra_content.aleo;
program test_maetra_content.aleo {
    @test
    script test_it() {
        let result: u32 = maetra_content.aleo/main(1u32, 2u32);
        assert_eq(result, 3u32);
    }

    @test
    @should_fail
    transition do_nothing() {
        let result: u32 = maetra_content.aleo/main(2u32, 3u32);
        assert_eq(result, 3u32);
    }

    @noupgrade
    async constructor() {}
}
