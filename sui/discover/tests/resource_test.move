#[test_only]
module discover::resource_test {
    use std::ascii::string;
    use std::option;
    use std::string::utf8;
    use discover::resources;
    use discover::resources::{Resource, destroy_empty};
    use discover::test_space;

    const ENotImplemented: u64 = 0;

    const ADMIN: address = @0x12;
    const UserA: address = @0xa;
    const UserB: address = @0xb;

    #[test]
    fun test_create_resource() {
        let mut resource_init = test_space::setup();
        resource_init.next_tx_with_sender(UserA);
        assert!(resource_init.sender() == UserA, 0);

        let mut group = resources::group(
            utf8(b"group1"), utf8(b"/posts"),
            resource_init.ctx());
        let res = resources::resource(
            utf8(b"/posts/a"),
            utf8(b"text/plain"),
            utf8(b"utf-8"),
            1234
        );
        resources::add(&mut group, utf8(b"/posts/a"), res);
        let mut space = resource_init.new_space(utf8(b"name1"), string(b"id1"));
        resources::attach(&mut space, group);
        resource_init.send_to_sender(space);

        resource_init.end();
    }

    #[test]
    fun test_add_and_remove_resource_from_group() {
        let mut resource_init = test_space::setup();
        resource_init.next_tx_with_sender(UserA);
        assert!(resource_init.sender() == UserA, 0);

        let mut group = resources::group(
            utf8(b"group1"), utf8(b"/posts"),
            resource_init.ctx());
        let res = resources::resource(
            utf8(b"/posts/a"),
            utf8(b"text/plain"),
            utf8(b"utf-8"),
            1234
        );
        resources::add(&mut group, utf8(b"/posts/a"), res);

        // 检查资源是否存在
        let mut exists = resources::remove_if_exists<Resource>(&mut group, utf8(b"/posts/a"));
        assert!(option::is_some(&exists), 0);

        // 检查资源是否已被移除
        let exists = resources::remove_if_exists<Resource>(&mut group, utf8(b"/posts/a"));
        assert!(option::is_none(&exists), 0);

        resources::destroy_empty(group);
        resource_init.end();
    }

    #[test]
    fun test_attach_and_detach_group() {
        let mut resource_init = test_space::setup();
        resource_init.next_tx_with_sender(UserA);
        assert!(resource_init.sender() == UserA, 0);

        let mut group = resources::group(
            utf8(b"group1"), utf8(b"/posts"),
            resource_init.ctx());
        let mut space = resource_init.new_space(utf8(b"name1"), string(b"id1"));
        resources::attach(&mut space, group);

        let mut exists = resources::detach_if_exists(&mut space, utf8(b"/posts"));
        assert!(option::is_some(&exists), 0);

        let detached_group = option::extract(&mut exists);

        destroy_empty(detached_group);
        option::destroy_none(exists);
        resource_init.send_to_sender(space);

        resource_init.end();
    }

    #[test]
    #[expected_failure(abort_code = 0x2::dynamic_field::EFieldAlreadyExists)]
    fun test_duplicate_group_attach() {
        let mut resource_init = test_space::setup();
        resource_init.next_tx_with_sender(UserA);
        assert!(resource_init.sender() == UserA, 0);

        let mut group1 = resources::group(
            utf8(b"group1"), utf8(b"/posts"),
            resource_init.ctx());
        let mut group2 = resources::group(
            utf8(b"group2"), utf8(b"/posts"),
            resource_init.ctx());

        let mut space = resource_init.new_space(utf8(b"name1"), string(b"id1"));
        resources::attach(&mut space, group1);
        resources::attach(&mut space, group2);

        resource_init.send_to_sender(space);
        resource_init.end();
    }

    #[test]
    fun test_remove_non_existent_resource() {
        let mut resource_init = test_space::setup();
        resource_init.next_tx_with_sender(UserA);
        assert!(resource_init.sender() == UserA, 0);

        let mut group = resources::group(
            utf8(b"group1"), utf8(b"/posts"),
            resource_init.ctx());
        let non_existent = resources::remove_if_exists<Resource>(&mut group, utf8(b"/posts/b"));

        assert!(option::is_none(&non_existent), 0);
        destroy_empty(group);
        resource_init.end();
    }
}
