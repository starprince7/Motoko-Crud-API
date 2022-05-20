import Trie "mo:base/Trie";
import Hash "mo:base/Hash";
import Nat "mo:base/Nat";
import Result "mo:base/Result";
import Principal "mo:base/Principal";

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
        id: Principal;
    };

    type ProfileUpdate = {
        bio: Bio;
    };

    // Err Type
    type Error = {
        #NotFound;
        #AlreadyExists;
        #NOT_AUTHORIZED;
    };

    // Application state / Persisted state OR Database
    stable var profiles : Trie.Trie<Principal, Profile> = Trie.empty();

    // < Create Method >======================================================================>
    public shared(msg) func create (profile : ProfileUpdate) : async Result.Result<(), Error> {
        // get caller's Principal
        let callerId = msg.caller;

        // reject anonymous identity calls
        if(Principal.toText(callerId) == "2vxsx-fae") {
            return #err(#NOT_AUTHORIZED);
        };
        
        // Assign Principal to a new profile of type (': Profile') to each new user.
        let userProfile : Profile = {
            bio = profile.bio;
            id = callerId;
        };

        let (newProfile, existingProfile) = Trie.put(
            profiles,           /* Database Where to insert profile data */
            key(callerId),      /* Key */
            Principal.equal,    /* Check Equality */
            userProfile         /* Data from argument */
        );

        // Update App state on Condition
        switch(existingProfile) {
            case null {
                profiles:= newProfile;
                #ok(());
            };
            case (? v) {
                #err(#AlreadyExists);
            };
        };

    };

    // < Read Method >====================================================>
    public shared(msg) func read () : async Result.Result<Profile, Error> {
        // get caller's Principal
        let callerId = msg.caller;

        // reject anonymous identity calls
        if(Principal.toText(callerId) == "2vxsx-fae") {
            return #err(#NOT_AUTHORIZED);
        };
        
        let result = Trie.find(
            profiles,
            key(callerId),
            Principal.equal,
        );
        return Result.fromOption(result, #NotFound);
    };

    // < Update Method >================================================================<
    public shared(msg) func update (profile : Profile) : async Result.Result<(), Error> {
        // get caller's Principal
        let callerId = msg.caller;

        // reject anonymous identity calls
        if(Principal.toText(callerId) == "2vxsx-fae") {
            return #err(#NOT_AUTHORIZED);
        };
        
        // Associate a principal to each user / caller.
        let userProfile : Profile = {
            bio = profile.bio;
            id = callerId;
        };

        let result = Trie.find(
            profiles,
            key(callerId),
            Principal.equal,  /* Equality Checker */
        );

        // Look for the exact profile to update
        // Do not update or allow update on profiles not yet created
        switch(result) {
            case null {
                #err(#NotFound);
            };
            case (? v) {
                profiles:= Trie.replace(
                    profiles,
                    key(callerId),
                    Principal.equal, 
                    ?userProfile
                ).0;
                #ok(());
            };
        };

    };

    // < Delete Method >===============================================<
    public shared(msg) func delete () : async Result.Result<(), Error> {
        // get caller's Principal
        let callerId = msg.caller;

        // reject anonymous identity calls
        if(Principal.toText(callerId) == "2vxsx-fae") {
            return #err(#NOT_AUTHORIZED);
        };
        
        let result = Trie.find(
            profiles,
            key(callerId),
            Principal.equal
        );

        // Check if profile data to delete exists using 'switch' statement before a Delete operation
        switch(result) {
            case null {
                #err(#NotFound);
            };
            case (? v) {
                profiles:= Trie.replace(    /* Trie.replace returns a tuple (newUpdate & existingData) */
                    profiles,    /* Pointer to App state or DB */
                    key(callerId),
                    Principal.equal,
                    null    /* Data to update with */
                ).0;
                #ok(());
            };
        };

    };

    // < Key Function > ===============================>
    private func key(x : Principal) : Trie.Key<Principal> {
        return { key = x; hash = Principal.hash(x) }
    }

}