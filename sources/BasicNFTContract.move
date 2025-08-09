module sravani_addr::BasicNFT {
    use aptos_framework::signer;
    use std::string::{Self, String};
    use std::vector;

    const ENFT_NOT_FOUND: u64 = 1;
    const ENOT_OWNER: u64 = 2;

    struct NFT has store, key {
        id: u64,
        name: String,
        description: String,
        image_url: String,
        owner: address,
    }

    struct NFTCollection has store, key {
        nfts: vector<NFT>,
        next_id: u64,
    }

    public fun initialize_collection(account: &signer) {
        let collection = NFTCollection {
            nfts: vector::empty<NFT>(),
            next_id: 1,
        };
        move_to(account, collection);
    }

    public fun mint_nft(
        account: &signer, 
        name: String, 
        description: String, 
        image_url: String
    ) acquires NFTCollection {
        let account_addr = signer::address_of(account);
        
        if (!exists<NFTCollection>(account_addr)) {
            initialize_collection(account);
        };

        let collection = borrow_global_mut<NFTCollection>(account_addr);
        
        let nft = NFT {
            id: collection.next_id,
            name,
            description,
            image_url,
            owner: account_addr,
        };

        vector::push_back(&mut collection.nfts, nft);
        collection.next_id = collection.next_id + 1;
    }

    public fun transfer_nft(
        from: &signer,
        to: address,
        nft_id: u64
    ) acquires NFTCollection {
        let from_addr = signer::address_of(from);
        assert!(exists<NFTCollection>(from_addr), ENFT_NOT_FOUND);
        
        let from_collection = borrow_global_mut<NFTCollection>(from_addr);
        let nft_index = find_nft_index(&from_collection.nfts, nft_id);
        let nft = vector::remove(&mut from_collection.nfts, nft_index);
        
        if (!exists<NFTCollection>(to)) {
            // In practice, recipient should initialize collection first
            abort ENFT_NOT_FOUND
        };
        
        let to_collection = borrow_global_mut<NFTCollection>(to);
        vector::push_back(&mut to_collection.nfts, nft);
    }

    fun find_nft_index(nfts: &vector<NFT>, nft_id: u64): u64 {
        let len = vector::length(nfts);
        let i = 0;
        while (i < len) {
            let nft = vector::borrow(nfts, i);
            if (nft.id == nft_id) {
                return i
            };
            i = i + 1;
        };
        abort ENFT_NOT_FOUND
    }

}
