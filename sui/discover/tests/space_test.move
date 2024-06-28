#[test_only]
module discover::space_test {
    use std::ascii::string;
    use std::string::utf8;
    use sui::object;
    use discover::space;
    use discover::space::Space;
    use discover::test_space;

    const ENotImplemented: u64 = 0;

    const ADMIN: address = @0x12;
    const UserA: address = @0xa;
    const UserB: address = @0xb;

    #[test]
    fun test_new_space() {
        let mut space_init = test_space::setup();
        space_init.next_tx_with_sender(UserA);
        assert!(space_init.sender() == UserA, 0);
        let x = space_init.new_space(utf8(b"name1"), string(b"id1"));
        space_init.send_to_sender(x);


        space_init.next_tx_with_sender(UserB);
        assert!(space_init.sender() == UserB, 0);
        let x = space_init.new_space(utf8(b"name2"), string(b"id2"));
        space_init.send_to_sender(x);
        space_init.end();
    }

    #[test]
    #[expected_failure(abort_code = space::ESpaceIdentifyAlreadyExist)]
    fun test_same_id_space() {
        let mut space_init = test_space::setup();
        space_init.next_tx_with_sender(UserA);
        assert!(space_init.sender() == UserA, 0);
        let x = space_init.new_space(utf8(b"name1"), string(b"id1"));
        space_init.send_to_sender(x);

        space_init.next_tx_with_sender(UserB);
        assert!(space_init.sender() == UserB, 0);
        let x = space_init.new_space(utf8(b"name2"), string(b"id1"));
        space_init.send_to_sender(x);
        space_init.end();
    }


    #[test]
    fun test_set_name_space() {
        let mut space_init = test_space::setup();
        space_init.next_tx_with_sender(UserA);
        assert!(space_init.sender() == UserA, 0);
        let mut x = space_init.new_space(utf8(b"name1"), string(b"id1"));
        space::set_name(&mut x, utf8(b"❤️"));
        assert!(space::name(&x) == utf8(b"❤️"), 0);
        space_init.send_to_sender(x);
        space_init.end();
    }

    #[test]
    fun test_destroy_space() {
        let mut space_init = test_space::setup();
        space_init.next_tx_with_sender(UserA);
        assert!(space_init.sender() == UserA, 0);
        let mut x = space_init.new_space(utf8(b"name1"), string(b"id1"));
        space::set_name(&mut x, utf8(b"❤️"));
        assert!(space::name(&x) == utf8(b"❤️"), 0);
        space_init.send_to_sender(x);

        space_init.next_tx_with_sender(UserA);
        let obj: Space = space_init.take_from_sender<Space>();
        space::destroy_empty(obj);

        space_init.end();
    }


    #[test]
    #[expected_failure(abort_code = space::ESpaceIdentifyAlreadyExist)]
    fun test_set_id_exist_space() {
        let mut space_init = test_space::setup();

        space_init.next_tx_with_sender(UserB);
        assert!(space_init.sender() == UserB, 0);
        let x = space_init.new_space(utf8(b"name2"), string(b"ID-2"));
        space_init.send_to_sender(x);

        space_init.next_tx_with_sender(UserA);
        assert!(space_init.sender() == UserA, 0);
        let mut x = space_init.new_space(utf8(b"name1"), string(b"ID1"));


        let cap = test_space::get_mut_cap(&mut space_init);
        space::set_identify(&mut x, cap, string(b"ID-2"));
        space_init.send_to_sender(x);
        space_init.end();
    }

    #[test]
    fun test_set_id_space() {
        let mut space_init = test_space::setup();

        space_init.next_tx_with_sender(UserB);
        assert!(space_init.sender() == UserB, 0);
        let x = space_init.new_space(utf8(b"name2"), string(b"ID-2"));
        space_init.send_to_sender(x);

        space_init.next_tx_with_sender(UserA);
        assert!(space_init.sender() == UserA, 0);
        let mut x = space_init.new_space(utf8(b"name1"), string(b"ID1"));


        let cap = test_space::get_mut_cap(&mut space_init);
        space::set_identify(&mut x, cap, string(b"ID-3"));
        space_init.send_to_sender(x);
        space_init.end();
    }


    #[test]
    fun test_router_space() {
        let mut space_init = test_space::setup();
        space_init.next_tx_with_sender(UserA);
        assert!(space_init.sender() == UserA, 0);
        let x = space_init.new_space(utf8(b"name1"), string(b"id1"));
        space_init.send_to_sender(x);

        space_init.next_tx_with_sender(UserB);
        assert!(space_init.sender() == UserB, 0);
        let x = space_init.new_space(utf8(b"name2"), string(b"id2"));
        space_init.send_to_sender(x);


        space_init.next_tx_with_sender(UserA);
        let cap = test_space::get_cap(&mut space_init);
        let addr1 = space::router(string(b"id1"), cap);
        let obj1: Space = space_init.take_from_sender<Space>();

        assert!(addr1 == object::id(&obj1).id_to_address(), 0);
        space_init.return_to_sender(obj1);


        space_init.next_tx_with_sender(UserB);
        let cap = test_space::get_cap(&mut space_init);
        let addr2 = space::router(string(b"id2"), cap);
        let obj2: Space = space_init.take_from_sender<Space>();

        assert!(addr2 == object::id(&obj2).id_to_address(), 0);
        space_init.return_to_sender(obj2);

        space_init.end();
    }
}
