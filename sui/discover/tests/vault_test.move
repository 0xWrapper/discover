#[test_only]
module discover::vault_test {
    use std::ascii::string;
    use std::string::utf8;
    use sui::coin;
    use sui::coin::Coin;
    use sui::object;
    use sui::object::UID;
    use sui::sui::SUI;
    use sui::test_scenario;
    use sui::transfer::{Self};
    use discover::space::Space;
    use discover::vault;
    use discover::test_space;

    const ADMIN: address = @0x12;
    const UserA: address = @0xa;
    const UserB: address = @0xb;

    // Mock struct for testing assets
    public struct MockAsset has key, store {
        id: UID,
    }


    public fun destory_mock_asset(asset: MockAsset) {
        let MockAsset { id } = asset;
        object::delete(id);
    }

    #[test]
    fun test_receive_asset() {
        let mut space_init = test_space::setup();
        space_init.next_tx_with_sender(UserA);
        assert!(space_init.sender() == UserA, 0);

        let space_id;
        let space_addr;
        {
            let mut s = space_init.new_space(utf8(b"name1"), string(b"id1"));
            space_id = object::id(&s);
            space_addr = space_id.to_address();
            transfer::public_transfer(s, copy UserA);
        };

        let sender = @0x0;
        let mut scenario = test_scenario::begin(sender);
        let uid1 = scenario.new_object();
        let id1 = uid1.uid_to_inner();
        {
            let asset1 = MockAsset { id: uid1 };
            transfer::public_transfer(asset1, space_addr);
        };
        test_scenario::next_tx(&mut scenario, UserA);
        {
            let mut parent = scenario.take_from_sender_by_id<Space>(space_id);
            assert!(object::id(&parent).to_address() == space_addr, 0);
            let a = test_scenario::most_recent_receiving_ticket<MockAsset>(&space_id);
            vault::receive<MockAsset>(&mut parent, a);
            assert!(vault::existence<MockAsset>(&parent, id1), 0);
            let mut assert = vault::take<MockAsset>(&mut parent, id1);
            assert!(object::id(&assert) == id1, 0);
            assert!(!vault::existence<MockAsset>(&parent, id1), 0);
            destory_mock_asset(assert);
            scenario.return_to_sender(parent);
        };
        scenario.end();
        space_init.end();
    }

    #[test]
    fun test_receipts_currency() {
        let mut space_init = test_space::setup();
        space_init.next_tx_with_sender(UserA);
        assert!(space_init.sender() == UserA, 0);

        let space_id;
        let space_addr;
        {
            let mut s = space_init.new_space(utf8(b"name1"), string(b"id1"));
            space_id = object::id(&s);
            space_addr = space_id.to_address();
            transfer::public_transfer(s, copy UserA);
        };

        let sender = @0x0;
        let mut scenario = test_scenario::begin(sender);
        {
            let mut coin = coin::mint_for_testing<SUI>(101, scenario.ctx());
            transfer::public_transfer(coin, space_addr);
        };

        test_scenario::next_tx(&mut scenario, UserA);
        {
            let mut parent = scenario.take_from_sender_by_id<Space>(space_id);
            assert!(object::id(&parent).to_address() == space_addr, 0);
            let a = test_scenario::most_recent_receiving_ticket<Coin<SUI>>(&space_id);
            vault::receipts<SUI>(&mut parent, a);
            let mut coin = vault::withdraw<SUI>(&mut parent, 50, scenario.ctx());
            assert!(coin::value(&coin) == 50, 0);
            assert!(vault::value<SUI>(&parent) == 51, 0);
            coin::burn_for_testing(coin);
            scenario.return_to_sender(parent);
        };
        scenario.end();
        space_init.end();
    }
}
