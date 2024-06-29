module discover::message {

    use std::ascii;
    use std::type_name;
    use sui::bcs;
    use sui::event;
    use sui::hash::blake2b256;
    use sui::object;
    use sui::transfer;
    use sui::transfer::Receiving;
    use sui::tx_context::TxContext;
    use discover::space::SpaceCap;
    use discover::space;


    const SPACE_CAP: address = @0x07c8ff22e9a5e5c2490de682bb987eed9894f41d0a4d8404b70130341b0a1cb3;
    const EReferentCantForward: u64 = 0;


    public struct Message<T: store> has key, store {
        id: UID,
        to: address,
        payload: T
    }

    public struct SubscribeMessage has copy, drop, store {
        message: ID,
        payload: ID,
        payload_type: ascii::String,
        to: address,
    }

    public entry fun produce<T: store>(object: T, to: address, ctx: &mut TxContext) {
        transfer::public_transfer(
            Message<T> {
                id: object::new(ctx),
                to,
                payload: object
            },
            SPACE_CAP
        );
    }

    public struct Referent<phantom T> {
        to: address,
        payload: ID,
    }

    public fun recipient<T>(ref: &Referent<T>): address {
        return ref.to
    }

    public fun payload<T>(ref: &Referent<T>): ID {
        return ref.payload
    }

    public fun id<T>(payload: &T): ID {
        let mut p_bcs = bcs::to_bytes(payload);
        vector::append(&mut p_bcs, bcs::to_bytes(&type_name::get<T>()));
        object::id_from_bytes(blake2b256(&p_bcs))
    }

    public fun subscribe<T: store>(cap: &mut SpaceCap, message: Receiving<Message<T>>): (T, Referent<T>) {
        let Message { id, to, payload } = space::receive(cap, message);
        let payload_id = id(&payload);

        let ref = Referent<T> {
            to,
            payload: payload_id
        };
        event::emit(SubscribeMessage {
            message: id.to_inner(),
            payload: payload_id,
            payload_type: type_name::into_string(type_name::get<T>()),
            to,
        });
        object::delete(id);
        (payload, ref)
    }

    public struct Receipt<T> has key, store {
        id: UID,
        referent: ID,
        payload: T
    }

    public fun forward<T: store>(object: T, ref: Referent<T>, ctx: &mut TxContext) {
        let ref_id = id(&ref);
        let Referent<T> { to, payload } = ref;
        assert!(id(&object) == payload, EReferentCantForward);
        transfer::public_transfer(
            Receipt<T> {
                id: object::new(ctx),
                referent: ref_id,
                payload: object
            },
            to
        );
    }
}
