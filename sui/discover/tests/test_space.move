#[test_only]
module discover::test_space {
    use std::ascii;
    use std::string;
    use discover::space;
    use sui::test_scenario::{Self, Scenario};
    use sui::test_utils;
    use sui::transfer::transfer;
    use discover::space::{SpaceCap, Space};

    const ENotImplemented: u64 = 0;

    const ADMIN: address = @0x12;

    public struct TestInit {
        scenario: Scenario,
        cap: SpaceCap,
    }

    public fun setup(): TestInit {
        let mut scenario = test_scenario::begin(ADMIN);
        let scenario_mut = &mut scenario;

        space::init_for_testing(scenario_mut.ctx());

        scenario_mut.next_tx(ADMIN);

        let mut cap = scenario_mut.take_shared<SpaceCap>();
        TestInit {
            scenario,
            cap
        }
    }

    public fun new_space(self: &mut TestInit, name: string::String, id: ascii::String): Space {
        space::new(name, id, &mut self.cap, self.scenario.ctx())
    }

    public fun get_mut_cap(self: &mut TestInit): &mut SpaceCap {
        &mut self.cap
    }

    public fun get_cap(self: & TestInit): & SpaceCap {
        &self.cap
    }

    public fun next_tx(self: &mut TestInit): &mut TestInit {
        self.scenario.next_tx(ADMIN);
        self
    }

    public fun ctx(self: &mut TestInit): &mut TxContext {
        self.scenario.ctx()
    }


    public fun sender(self: &mut TestInit): address {
        self.scenario.sender()
    }

    public fun take_from_sender<T: key>(self: &mut TestInit): T {
        self.scenario.take_from_sender()
    }

    public fun return_to_sender<T: key>(self: &mut TestInit, t: T) {
        self.scenario.return_to_sender(t)
    }

    public fun send_to_sender<T: key+store>(self: &mut TestInit, t: T) {
        transfer::public_transfer(t, self.scenario.sender());
    }

    public fun next_tx_with_sender(self: &mut TestInit, sender: address): &mut TestInit {
        self.scenario.next_tx(sender);
        self
    }

    public fun end(self: TestInit) {
        test_utils::destroy(self);
    }
}
