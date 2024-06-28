module discover::vault {
    use sui::coin;
    use sui::coin::Coin;
    use sui::transfer::Receiving;
    use discover::space::{Space, exists_field, mutate_field, remove_field, exists_object, borrow_field};

    // ====== Vault Error Codes =====
    const EAssetNotFoundInVault: u64 = 0;
    const ECurrencyNotFoundInVault: u64 = 1;
    const ECurrencyNotEnoughAmountInVault: u64 = 2;

    public struct CurrencyVault<phantom T> has copy, drop, store {}

    public struct AssetVault<phantom T> has copy, drop, store { id: ID }

    /// Receive an asset and stores it in the Vault.
    /// Parameters:
    /// - `s`: Mutable reference to the Space.
    /// - `assert`: The asset to be acquired and stored.
    public entry fun receive<T: key + store>(s: &mut Space, assert: Receiving<T>) {
        let sent_assert = s.accept(assert);
        let assert_type = AssetVault<T> { id: object::id(&sent_assert) };
        s.add_object(assert_type, sent_assert);
    }

    /// Take an asset from the Vault and transfers it to the requester.
    /// Parameters:
    /// - `s`: Mutable reference to the Space.
    /// - `asset_id`: The ID of the asset to be extracted.
    public fun take<T: key + store>(s: &mut Space, asset_id: ID): T {
        let asset_type = AssetVault<T> { id: asset_id };
        assert!(exists_object<AssetVault<T>, T>(s, asset_type), EAssetNotFoundInVault);

        let asset = s.remove_object<AssetVault<T>, T>(asset_type);
        asset
    }


    /// Check the existence of an asset in the Vault.
    /// Parameters:
    /// - `s`: Reference to the Space.
    /// - `asset_id`: The ID of the asset to be checked.
    /// Returns:
    /// - `true` if the asset exists in the Vault, `false` otherwise.
    public fun existence<T: key + store>(s: &Space, asset_id: ID): bool {
        let asset_type = AssetVault<T> { id: asset_id };
        exists_object<AssetVault<T>, T>(s, asset_type)
    }

    /// Receipts a currency and updates the balance in the Vault.
    /// Parameters:
    /// - `s`: Mutable reference to the Space.
    /// - `currency`: The currency to be received and stored.
    public entry fun receipts<T>(s: &mut Space, currency: Receiving<Coin<T>>) {
        let coin = s.accept(currency);
        let balance_type = CurrencyVault<T> {};
        if (s.exists_field<CurrencyVault<T>, Coin<T>>(balance_type)) {
            let balance: &mut Coin<T> = s.mutate_field(balance_type);
            coin::join(balance, coin);
        } else {
            s.add_field(balance_type, coin);
        }
    }

    /// Returns the value of the currency in the Vault.
    /// Parameters:
    /// - `s`: Reference to the Space.
    /// Returns:
    /// - The value of the currency in the Vault.
    /// Errors:
    /// - `ECurrencyNotFoundInVault`: The currency is not found in the Vault.
    public fun value<T>(s: &Space): u64 {
        let balance_type = CurrencyVault<T> {};
        assert!(exists_field<CurrencyVault<T>, Coin<T>>(s, balance_type), ECurrencyNotFoundInVault);

        borrow_field<CurrencyVault<T>, Coin<T>>(s, balance_type).value()
    }

    /// Withdraw a specified amount of currency from the Vault and transfers it to the requester.
    /// Parameters:
    /// - `s`: Mutable reference to the Space.
    /// - `amount`: The amount of currency to be retrieved.
    /// - `ctx`: The transaction context.
    public fun withdraw<T>(s: &mut Space, amount: u64, ctx: &mut TxContext): Coin<T> {
        let balance_type = CurrencyVault<T> {};
        assert!(exists_field<CurrencyVault<T>, Coin<T>>(s, balance_type), ECurrencyNotFoundInVault);

        let balance: &mut Coin<T> = mutate_field<CurrencyVault<T>, Coin<T>>(s, balance_type);
        assert!(coin::value(balance) >= amount, ECurrencyNotEnoughAmountInVault);

        let coin_to_retrieve = coin::split(balance, amount, ctx);
        coin_to_retrieve
    }
}
