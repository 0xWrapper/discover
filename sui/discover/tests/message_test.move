#[test_only]
module discover::message_test {
    use std::string::{String, utf8};
    use sui::object;
    use sui::test_scenario;
    use discover::message::{Self,Message};
    use discover::test_space;

    const UserA: address = @0xa;
    const UserB: address = @0xb;
    const UserC: address = @0xb;


    #[test]
    fun test_message_produce() {
        let mut space_init = test_space::setup();
        let mut cap = space_init.get_mut_cap();
        let cap_id = object::id(cap);

        let mut scenario = test_scenario::begin(UserA);
        {
            // Step 1: UserA produces a message
            message::produce<String>(
                utf8(b"TestPayload"),
                UserC,
                // cap_id.to_address(),
                test_scenario::ctx(&mut scenario)
            );
        };
        space_init.end();
        test_scenario::end(scenario);
    }

    #[test]
    fun test_message_produce_and_subscribe() {
        let mut space_init = test_space::setup();
        let mut cap = space_init.get_mut_cap();
        let cap_id = object::id(cap);


        let mut scenario = test_scenario::begin(UserA);
        {
            // Step 1: UserA produces a message
            message::produce<String>(
                utf8(b"TestPayload"),
                UserC,
                // cap_id.to_address(),
                test_scenario::ctx(&mut scenario)
            );
        };
        test_scenario::next_tx(&mut scenario, UserB);
        {
            // Step 2: UserB subscribes to the message
            let msg = test_scenario::most_recent_receiving_ticket<Message<String>>(&cap_id);
            let (received_payload, referent) = message::subscribe(cap, msg);
            assert!(received_payload == utf8(b"TestPayload"), 1);
            assert!(message::recipient(&referent) == UserC, 2);
            assert!(message::payload(&referent) == message::id(&utf8(b"TestPayload")), 3);
            message::forward(received_payload, referent, test_scenario::ctx(&mut scenario));
        };

        space_init.end();
        test_scenario::end(scenario);
    }
}
