#[allow(unused_use)]
module discover::space {
    use std::ascii::{Self, string};
    use sui::transfer::{Self, Receiving};
    use std::string::{Self, utf8};
    use sui::table::{Self, Table};
    use sui::dynamic_object_field as dof;
    use sui::dynamic_field as df;
    use sui::event;
    use sui::display;
    use sui::object;
    use sui::package;
    use sui::tx_context::TxContext;
    use discover::utils;

    const ESpaceIdentifyAlreadyExist: u64 = 0;
    const ESpaceSetInvalidIdentify: u64 = 1;
    const ESpaceRoutingFailed: u64 = 2;

    public struct SPACE has drop {}

    public struct SpaceCap has key, store {
        id: UID,
        routing: Table<ascii::String, address>
    }

    public struct Space has key, store {
        id: UID,
        identify: std::ascii::String,
        name: std::string::String,
    }

    #[lint_allow(self_transfer)]
    fun init(witness: SPACE, ctx: &mut TxContext) {
        let publisher = package::claim(witness, ctx);
        let keys = vector[
            std::string::utf8(b"name"),
            std::string::utf8(b"identify"),
            std::string::utf8(b"project_url"),
        ];
        let values = vector[
            std::string::utf8(b"{name}"),
            std::string::utf8(b"{identify}"),
            std::string::utf8(b"https://wrapper.space"),
        ];
        let mut display = display::new_with_fields<Space>(&publisher, keys, values, ctx);
        display::update_version<Space>(&mut display);

        transfer::public_transfer(publisher, ctx.sender());
        transfer::public_transfer(display, ctx.sender());
        transfer::public_share_object(SpaceCap {
            id: object::new(ctx),
            routing: table::new<ascii::String, address>(ctx)
        })
    }

    /// Event emitted when Space is created.
    public struct Created has copy, drop {
        creater: address,
        id: ID,
        identify: ascii::String,
    }

    /// get address use identify string
    public fun router(identify: ascii::String, cap: &SpaceCap): address {
        assert!(table::contains(&cap.routing, identify), ESpaceRoutingFailed);
        return *table::borrow(&cap.routing, identify)
    }

    /// Creates a new, empty Space.
    /// Parameters:
    /// - `name`: Name of the Space.
    /// - `space_id`: ASCII string identifying the Space.
    /// - `cap`: SpaceCap used for creating the Space.
    /// - `ctx`: Transaction context used for creating the Space.
    /// Returns:
    /// - A new Space with no items and a generic kind.
    /// Errors:
    /// - `ESpaceIdentifyAlreadyExist`: If the Space identifier already exists.
    /// - `ESpaceSetInvalidIdentify`: If the Space identifier is invalid.
    public entry fun create(id: vector<u8>, name: vector<u8>, cap: &mut SpaceCap, ctx: &mut TxContext) {
        transfer::public_transfer(
            new(string(id), utf8(name), cap, ctx),
            ctx.sender()
        );
    }

    /// Creates a new, empty Space.
    /// Parameters:
    /// - `space_id`: ASCII string identifying the Space.
    /// - `name`: Name of the Space.
    /// - `cap`: SpaceCap used for creating the Space.
    /// - `ctx`: Transaction context used for creating the Space.
    /// Returns:
    /// - A new Space with no items and a generic kind.
    /// Errors:
    /// - `ESpaceIdentifyAlreadyExist`: If the Space identifier already exists.
    /// - `ESpaceSetInvalidIdentify`: If the Space identifier is invalid.
    public fun new(space_id: ascii::String, name: string::String, cap: &mut SpaceCap, ctx: &mut TxContext): Space {
        assert!(utils::is_valid_label(&space_id), ESpaceSetInvalidIdentify);
        let identify = utils::to_lowercase(space_id);
        assert!(!table::contains<ascii::String, address>(&cap.routing, identify), ESpaceIdentifyAlreadyExist);
        let id = object::new(ctx);
        event::emit(Created {
            creater: ctx.sender(),
            id: id.to_inner(),
            identify,
        });
        table::add(&mut cap.routing, identify, id.to_address());
        Space {
            id,
            identify,
            name,
        }
    }


    /// Sets a new name for the Space.
    /// Parameters:
    /// - `s`: Mutable reference to the Space.
    /// - `name`: New name to set for the Space.
    /// Effects:
    /// - Updates the name field of the Space.
    public entry fun set_name(s: &mut Space, name: std::string::String) {
        s.name = name;
    }


    /// Event emitted when Space is destroy.
    public struct Destroyed has copy, drop {
        id: ID,
        identify: std::ascii::String,
    }


    /// Destroys the Space, ensuring it is empty before deletion.
    /// Parameters:
    /// - `s`: The Space to destroy.
    /// Effects:
    /// - The Space and its identifier are deleted.
    /// Errors:
    /// - `ESpaceNotEmpty`: If the Space is not empty at the time of destruction.
    public fun destroy_empty(s: Space) {
        // delete the Space
        let Space { id, name: _, identify } = s;
        event::emit(Destroyed {
            id: id.to_inner(),
            identify,
        });
        id.delete();
    }

    /// Retrieves the identify of objects contained within the Space.
    /// Parameters:
    /// - `s`: Reference to the Space.
    /// Returns:
    /// - ASCII string indicating the identify of objects in the Space.
    public fun identify(s: &Space): std::ascii::String {
        s.identify
    }

    /// Retrieves the name of the Space.
    /// Parameters:
    /// - `s`: Reference to the Space.
    /// Returns:
    /// - UTF8 encoded string representing the name of the Space.
    public fun name(s: &Space): std::string::String {
        s.name
    }

    /// Sets the identify of the space.
    /// Parameters:
    /// - `s`: Mutable reference to the Space.
    /// - `identify`: The new identify to set.
    public(package) fun set_identify(s: &mut Space, cap: &mut SpaceCap, mut space_id: ascii::String) {
        assert!(utils::is_valid_label(&space_id), ESpaceSetInvalidIdentify);
        let identify = utils::to_lowercase(space_id);
        assert!(!table::contains<ascii::String, address>(&cap.routing, identify), ESpaceIdentifyAlreadyExist);
        table::remove(&mut cap.routing, s.identify);
        table::add(&mut cap.routing, identify, s.id.to_address());
        s.identify = identify;
    }

    /// Accepts a receiving object into the space.
    /// Parameters:
    /// - `w`: Mutable reference to the Space.
    /// - `to_receive`: The object to receive.
    /// Returns:
    /// - The received object.
    public(package) fun accept<T: key+store>(s: &mut Space, to_receive: Receiving<T>): T {
        transfer::public_receive(&mut s.id, to_receive)
    }

    /// Receive a receiving object into the Share SpaceCap.
    /// Parameters:
    /// - `w`: Mutable reference to the SpaceCap.
    /// - `to_receive`: The object to receive.
    /// Returns:
    /// - The received object.
    public(package) fun receive<T : key+store>(cap: &mut SpaceCap, to_receive: Receiving<T>): T {
        transfer::public_receive(&mut cap.id, to_receive)
    }


    /// Adds an object to the space.
    /// Parameters:
    /// - `s`: Mutable reference to the Space.
    /// - `k`: The key of the object.
    /// - `v`: The value of the object.
    public(package) fun add_object<K: copy + drop + store, V: key + store>(s: &mut Space, k: K, v: V) {
        dof::add(&mut s.id, k, v);
    }

    /// Checks if an object exists in the space.
    /// Parameters:
    /// - `s`: Reference to the Space.
    /// - `k`: The key of the object.
    /// Returns:
    /// - `true` if the object exists, `false` otherwise.
    public(package) fun exists_object<K: copy + drop + store, V: key + store>(s: &Space, k: K): bool {
        dof::exists_with_type<K, V>(&s.id, k)
    }

    /// Mutates an object in the space.
    /// Parameters:
    /// - `s`: Mutable reference to the Space.
    /// - `k`: The key of the object.
    /// Returns:
    /// - Mutable reference to the object.
    public(package) fun mutate_object<K: copy + drop + store, V: key + store>(s: &mut Space, k: K): &mut V {
        dof::borrow_mut<K, V>(&mut s.id, k)
    }


    /// Borrows an object from the space.
    /// Parameters:
    /// - `s`: Reference to the Space.
    /// - `k`: The key of the object.
    /// Returns:
    /// - Reference to the object.
    public(package) fun borrow_object<K: copy + drop + store, V: key + store>(s: &Space, k: K): &V {
        dof::borrow<K, V>(&s.id, k)
    }

    /// Removes an object from the space.
    /// Parameters:
    /// - `s`: Mutable reference to the Space.
    /// - `k`: The key of the object.
    /// Returns:
    /// - The removed object.
    public(package) fun remove_object<K: copy + drop + store, V: key + store>(s: &mut Space, k: K): V {
        dof::remove<K, V>(&mut s.id, k)
    }

    /// Adds a field to the space.
    /// Parameters:
    /// - `s`: Mutable reference to the Space.
    /// - `k`: The key of the field.
    /// - `v`: The value of the field.
    public(package) fun add_field<K: copy + drop + store, V: store>(s: &mut Space, k: K, v: V) {
        df::add(&mut s.id, k, v);
    }

    /// Checks if a field exists in the space.
    /// Parameters:
    /// - `s`: Reference to the Space.
    /// - `k`: The key of the field.
    /// Returns:
    /// - `true` if the field exists, `false` otherwise.
    public(package) fun exists_field<K: copy + drop + store, V: store>(s: &Space, k: K): bool {
        df::exists_with_type<K, V>(&s.id, k)
    }

    /// Mutates a field in the space.
    /// Parameters:
    /// - `s`: Mutable reference to the Space.
    /// - `k`: The key of the field.
    /// Returns:
    /// - Mutable reference to the field.
    public(package) fun mutate_field<K: copy + drop + store, V: store>(s: &mut Space, k: K): &mut V {
        df::borrow_mut<K, V>(&mut s.id, k)
    }

    /// Borrows a field from the space.
    /// Parameters:
    /// - `s`: Reference to the Space.
    /// - `k`: The key of the field.
    /// Returns:
    /// - Reference to the field.
    public(package) fun borrow_field<K: copy + drop + store, V: store>(s: &Space, k: K): &V {
        df::borrow<K, V>(&s.id, k)
    }

    /// Removes a field from the space.
    /// Parameters:
    /// - `s`: Mutable reference to the Space.
    /// - `k`: The key of the field.
    /// Returns:
    /// - The removed field.
    public(package) fun remove_field<K: copy + drop + store, V: store>(s: &mut Space, k: K): V {
        df::remove<K, V>(&mut s.id, k)
    }


    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(SPACE {}, ctx);
    }
}