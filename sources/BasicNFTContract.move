module sravani_addr::BasicNFT {
    use aptos_framework::signer;
    use std::string::{Self, String};
    use std::vector;

    /// Error codes
    const ENFT_NOT_FOUND: u64 = 1;
    const ENOT_OWNER: u64 = 2;

    /// Struct representing an NFT with metadata
    struct NFT has store, key {
        id: u64,
        name: String,
        description: String,
        image_url: String,
        owner: address,
    }

    /// Collection to store all NFTs for an account
    struct NFTCollection has store, key {
        nfts: vector<NFT>,
        next_id: u64,
    }

    /// Initialize NFT collection for an account
    public fun initialize_collection(account: &signer) {
        let collection = NFTCollection {
            nfts: vector::empty<NFT>(),
            next_id: 1,
        };
        move_to(account, collection);
    }

    /// Mint a new NFT with metadata
    public fun mint_nft(
        account: &signer, 
        name: String, 
        description: String, 
        image_url: String
    ) acquires NFTCollection {
        let account_addr = signer::address_of(account);
        
        // Initialize collection if it doesn't exist
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

    /// Transfer NFT to another address (simplified version)
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
        
        // Initialize collection for recipient if needed
        if (!exists<NFTCollection>(to)) {
            // In practice, recipient should initialize collection first
            abort ENFT_NOT_FOUND
        };
        
        let to_collection = borrow_global_mut<NFTCollection>(to);
        vector::push_back(&mut to_collection.nfts, nft);
    }

    /// Helper function to find NFT index by ID
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