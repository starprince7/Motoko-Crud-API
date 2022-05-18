import Trie "mo:base/Trie";
import Hash "mo:base/Hash";
import Nat "mo:base/Nat";

actor Avatar {
    // App data model
    type Bio = {
        name: ?Text;
        lastname: ?Text;
        age: ?Text;
        country: ?Text;
    };
    
    type Profile = {
        bio: Bio;
    };

    // Application state / Persisted state OR Database
    stable var profiles : Trie.Trie<Nat, Profile> = Trie.empty();

    // Increamented ID
    stable var next_id : Nat = 1;

    // Create Method
    public func create(profile : Profile) : async Bool {
        let profileId = next_id;
        next_id += 1;

        let (newProfile, existingProfile) = Trie.put(
            profiles,       /* Database Where to insert profile data */
            key(profileId), /* Key */
            Nat.equal,      /* Check Equality */
            profile         /* Data from argument */
        );

        // Update App state on Condition
        switch(existingProfile) {
            case null {
                profiles:= newProfile;
            };
            case (? v) {
                return false;
            };
        };

        return true;
    };

    // Read Method
    public func read(profileId : Nat) : async ?Profile {
        let result = Trie.find(
            profiles,
            key(profileId),
            Nat.equal,
        );
        return result;
    };

    // Update Method
    public func update(profileId : Nat, profile : Profile) : async Bool {
        let result = Trie.find(
            profiles,
            key(profileId),
            Nat.equal,  /* Equality Checker */
        );

        // Look for the exact profile to update
        // Do not update or allow update on profiles not yet created
        switch(result) {
            case null {
                return false;
            };
            case (? v) {
                profiles:= Trie.replace(
                    profiles,
                    key(profileId),
                    Nat.equal, 
                    ?profile
                ).0;
            };
        };
        return true;
    };

    // Delete Method
    public func delete(profileId : Nat) : async Bool {
        let result = Trie.find(
            profiles,
            key(profileId),
            Nat.equal
        );

        // Check if profile data exist using 'switch' statement
        switch(result) {
            case null {
                return false;
            };
            case (? v) {
                profiles:= Trie.replace(    /* Trie.replace returns a tuple (newUpdate & existingData) */
                    profiles,    /* Pointer to App state or DB */
                    key(profileId),
                    Nat.equal,
                    null    /* Data to update with */
                ).0;
            };
        };
        return true;
    };

    private func key(x : Nat) : Trie.Key<Nat> {
        return { key = x; hash = Hash.hash(x) }
    }

}