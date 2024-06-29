module discover::resources {
    use std::option;
    use std::option::Option;
    use std::string::String;
    use sui::dynamic_field as df;
    use sui::object;
    use discover::space;
    use discover::space::Space;

    /// Resource
    public struct Resource has store, drop {
        path: String,
        content_type: String,
        content_encoding: String,
        blob_id: u256,
    }

    /// Group
    public struct Group has store {
        id: UID,
        name: String,
        path: String,
    }

    /// Destroy an group
    public fun destroy_empty(group: Group) {
        let Group { id, name: _, path: _ } = group;
        object::delete(id);
    }

    /// Path
    public struct Path has copy, store, drop {
        path: String,
    }

    public fun resource(
        path: String,
        content_type: String,
        content_encoding: String,
        blob_id: u256,
    ): Resource {
        Resource {
            path,
            content_type,
            content_encoding,
            blob_id,
        }
    }

    public fun group(name: String, path: String, ctx: &mut TxContext): Group {
        Group {
            id: object::new(ctx),
            path,
            name,
        }
    }

    public fun add<T: store>(group: &mut Group, path: String, obj: T) {
        let path_obj = Path { path };
        df::add(&mut group.id, path_obj, obj);
    }

    public fun attach(s: &mut Space, group: Group) {
        let path_obj = Path { path: group.path };
        space::add_field(s, path_obj, group);
    }


    public fun remove<T: store>(group: &mut Group, path: String): T {
        let path_obj = Path { path };
        df::remove<Path, T>(&mut group.id, path_obj)
    }

    public fun detach(s: &mut Space, path: String): Group {
        let path_obj = Path { path };
        space::remove_field(s, path_obj)
    }

    public fun remove_if_exists<T: store>(group: &mut Group, path: String): Option<T> {
        let path_obj = Path { path };
        if (df::exists_with_type<Path, T>(&mut group.id, path_obj)) {
            option::some(remove(group, path))
        } else {
            option::none()
        }
    }

    public fun detach_if_exists(s: &mut Space, path: String): Option<Group> {
        let path_obj = Path { path };
        if (space::exists_field<Path, Group>(s, path_obj)) {
            option::some(detach(s, path))
        } else {
            option::none()
        }
    }
}
