module discover::utils {
    use std::ascii;
    use std::ascii::{String, string};

    const ALLOWED_LABEL_CHARS: vector<u8> = b"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-";


    public fun to_uppercase(input: String): String {
        let mut bytes = ascii::into_bytes(input);
        let length = vector::length(&bytes);
        let mut i = 0;
        while (i < length) {
            let letter = vector::borrow_mut(&mut bytes, i);
            if (is_lowercase(*letter)) {
                *letter = *letter - 32;
            };
            i = i + 1;
        };
        ascii::string(bytes)
    }

    public fun to_lowercase(input: String): String {
        let mut bytes = ascii::into_bytes(input);
        let length = vector::length(&bytes);
        let mut i = 0;
        while (i < length) {
            let letter = vector::borrow_mut(&mut bytes, i);
            if (is_uppercase(*letter)) {
                *letter = *letter + 32;
            };
            i = i + 1;
        };
        ascii::string(bytes)
    }

    public fun is_lowercase(letter: u8): bool {
        letter >= 97 && letter <= 122
    }

    public fun is_uppercase(letter: u8): bool {
        letter >= 65 && letter <= 90
    }

    public fun is_valid_label(label: &String): bool {
        let length = label.length();
        if (length == 0 || length > 63) {
            return false;
        };

        let chars = label.as_bytes();

        let first_char = chars[0];
        let last_char = chars[length - 1];
        if (first_char == 45 || last_char == 45) {
            return false;
        };
        let chars_length = vector::length(chars);
        let mut i = 0;
        while (i < chars_length) {
            if (!is_allowed_char(chars[i])) {
                return false;
            };
            i = i + 1;
        };
        true
    }

    public fun is_allowed_char(char: u8): bool {
        vector::contains(&ALLOWED_LABEL_CHARS, &char)
    }

    #[test]
    fun test_is_valid_label() {
        assert!(is_valid_label(&string(b"abc")), 1);
        assert!(is_valid_label(&string(b"123456789012345678901234567890123")), 1);
        assert!(!is_valid_label(&string(b"0123456789012345678901234567890123456789012345678901234567891234")), 1);
        assert!(is_valid_label(&string(b"012345678901234567890123456789012345678901234567890123456789123")), 1);
        assert!(is_valid_label(&string(b"abcd")), 2);
        assert!(is_valid_label(&string(b"ab-cd")), 2);
        assert!(!is_valid_label(&string(b"-abcd")), 2);
        assert!(!is_valid_label(&string(b"ab_d")), 2);
        assert!(!is_valid_label(&string(b"abc!")), 3);
        assert!(!is_valid_label(&string(b"abc ")), 4);
        assert!(!is_valid_label(&string(b"abc.")), 5);
        assert!(!is_valid_label(&string(b"abc@")), 6);
        assert!(!is_valid_label(&string(b"abc#")), 7);
        assert!(!is_valid_label(&string(b"abc$")), 8);
        assert!(!is_valid_label(&string(b"abc&")), 9);
        assert!(!is_valid_label(&string(b"abc=")), 10);
        assert!(!is_valid_label(&string(b"abc+")), 11);
        assert!(!is_valid_label(&string(b"abc-")), 12);
        assert!(!is_valid_label(&string(b"abc*")), 13);
        assert!(!is_valid_label(&string(b"abc/")), 14);
        assert!(!is_valid_label(&string(b"abc\\")), 15);
        assert!(!is_valid_label(&string(b"abc|")), 16);
        assert!(!is_valid_label(&string(b"abc<")), 17);
        assert!(!is_valid_label(&string(b"abc>")), 18);
        assert!(!is_valid_label(&string(b"abc,")), 19);
        assert!(!is_valid_label(&string(b"abc?")), 20);
        assert!(!is_valid_label(&string(b"abc;")), 21);
        assert!(!is_valid_label(&string(b"abc:")), 22);
        assert!(!is_valid_label(&string(b"abc[")), 23);
        assert!(!is_valid_label(&string(b"abc]")), 24);
        assert!(!is_valid_label(&string(b"abc{")), 25);
        assert!(!is_valid_label(&string(b"abc}")), 26);
        assert!(!is_valid_label(&string(b"abc(")), 27);
        assert!(!is_valid_label(&string(b"abc)")), 28);
        assert!(!is_valid_label(&string(b"abc'")), 29);
        assert!(!is_valid_label(&string(b"abc\"")), 30);
        assert!(!is_valid_label(&string(b"abc`")), 31);
        assert!(!is_valid_label(&string(b"abc~")), 32);
    }
}
