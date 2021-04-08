import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Hash "mo:base/Hash";
import Http "Http";
import List "mo:base/List";
import Nat "mo:base/Nat";
import Text "mo:base/Text";
import Time "mo:base/Time";
import TrieMap "mo:base/TrieMap";

actor AdsLedger {
    /**
     * Types
     */

    public type AdID = Nat;

    /// Standard age groups for targeting
    ///
    /// TODO: Find some alternative variant identifiers that start with a letter. Or yell at DFINITY to allow starting with an underscore.
    public type Age = {
        #age0_12;
        #age13_17;
        #age18_24;
        #age25_34;
        #age35_44;
        #age45_54;
        #age55_64;
        #age65_74;
        #age75_;
    };

    func ageToText(age : Age) : Text {
        switch age {
            case (#age0_12) "\"0-12\"";
            case (#age13_17) "\"13-17\"";
            case (#age18_24) "\"18-24\"";
            case (#age25_34) "\"25-34\"";
            case (#age35_44) "\"35-44\"";
            case (#age45_54) "\"45-54\"";
            case (#age55_64) "\"55-64\"";
            case (#age65_74) "\"65-74\"";
            case (#age75_) "\"75+\"";
        }
    };

    /// Primary gender expression to target
    ///
    /// This is obviously not an exhaustive list, but I have yet to see advertising catered to anything outside of these three categories. In most cases you shouldn't care about targeting gender anyway.
    public type Gender = {
        #masculine;
        #non_binary;
        #feminine;
    };

    func genderToText(gender : Gender) : Text {
        switch gender {
            case (#masculine) "\"masculine\"";
            case (#non_binary) "\"non_binary\"";
            case (#feminine) "\"feminine\"";
        }
    };

    /// Primary business function of an employee (corresponding to job title, not company)
    public type Occupation = Text;

    /// Primary product/service of employee's organization (corresponding to sales, not job title)
    public type Industry = Text;

    // TODO: Targeting province? region?
    public type Country = Text;

    /// Topic user is interested in
    ///
    /// In addition to standard interests, this should be used instead of Dislike to represent things the user actively seeks to fight, e.g. Interest(anti-racism) instead of Dislike(racism).
    public type Interest = Text;

    /// Topic user is not interested in
    ///
    /// This is usually used client-side to hide topics from the user but could still be useful for targeting, e.g. Occupation(Software) AND Dislike(Amazon Web Services) for marketing alternative cloud platforms.
    public type Dislike = Text;

    /// Rules specifying what values of a type must exist to be considered a "match", using AND (`all`), OR (`some`), and NOT (`none`)
    public type MatchRules<T> = {
        /// All of these values must exist to be considered a match
        all : [T];
        /// At least one of these values must exist to be considered a match
        some : [T];
        /// None of these values can exist to be considered a match
        none : [T];
    };

    /// Serialize a `MatchRules<Text>` to JSON
    ///
    /// TODO: Generic serialization?
    func textRulesToJson(rules : ?MatchRules<Text>) : Text {
        switch rules {
            case null
                "null";
            case (?rules)
                "{" #
                    "\"all\":[" # Text.join(",", Iter.map(Iter.fromArray(rules.all), func (text : Text) : Text {"\"" # text # "\""})) # "]," #
                    "\"some\":[" # Text.join(",", Iter.map(Iter.fromArray(rules.some), func (text : Text) : Text {"\"" # text # "\""})) # "]," #
                    "\"none\":[" # Text.join(",", Iter.map(Iter.fromArray(rules.none), func (text : Text) : Text {"\"" # text # "\""})) # "]" #
                "}";
        }
    };

    /// Serialize a `MatchRules<Gender>` to JSON
    func genderRulesToJson(rules : ?MatchRules<Gender>) : Text {
        switch rules {
            case null
                "null";
            case (?rules)
                "{" #
                    "\"all\":[" # Text.join(",", Iter.map(Iter.fromArray(rules.all), genderToText)) # "]," #
                    "\"some\":[" # Text.join(",", Iter.map(Iter.fromArray(rules.some), genderToText)) # "]," #
                    "\"none\":[" # Text.join(",", Iter.map(Iter.fromArray(rules.none), genderToText)) # "]" #
                "}";
        }
    };

    /// Serialize a `MatchRules<Age>` to JSON
    func ageRulesToJson(rules : ?MatchRules<Age>) : Text {
        switch rules {
            case null
                "null";
            case (?rules)
                "{" #
                    "\"all\":[" # Text.join(",", Iter.map(Iter.fromArray(rules.all), ageToText)) # "]," #
                    "\"some\":[" # Text.join(",", Iter.map(Iter.fromArray(rules.some), ageToText)) # "]," #
                    "\"none\":[" # Text.join(",", Iter.map(Iter.fromArray(rules.none), ageToText)) # "]" #
                "}";
        }
    };

    /// Profile attributes an ad is relevant to
    ///
    /// All attributes are optional, and non-null attributes are combined using AND, reducing the pool of candidate users to reach. For example, a Target with non-null `interests` and `dislikes` will match profiles matching the `interests` rules AND `dislikes` rules. For OR relationships, define multiple `Ad` objects.
    public type Target = {
        age : ?MatchRules<Age>;
        gender : ?MatchRules<Gender>;
        occupation : ?MatchRules<Occupation>;
        industry : ?MatchRules<Industry>;
        interests : ?MatchRules<Interest>;
        dislikes : ?MatchRules<Dislike>;
    };

    func targetToJson(target : Target) : Text {
        "{" #
            "\"age\":" # ageRulesToJson(target.age) # "," #
            "\"gender\":" # genderRulesToJson(target.gender) # "," #
            "\"occupation\":" # textRulesToJson(target.occupation) # "," #
            "\"industry\":" # textRulesToJson(target.industry) # "," #
            "\"interests\":" # textRulesToJson(target.interests) # "," #
            "\"dislikes\":" # textRulesToJson(target.dislikes) #
        "}"
    };

    /// Ad campaign containing `image` and `link` to be shown to users matching `profile` between `start` and `end`
    public type Ad = {
        /// User with control over this ad
        owner : Text;
        /// Link to ad content
        /// TODO: Host blob on-chain, once Candid UI supports blob uploads
        image : Text;
        /// URL the user should visit after clicking on the ad
        link : Text;
        /// Profile attributes this ad is relevant to, or null for no targeting
        profile : ?Target;
        /// Time this campaign starts
        start : ?Time.Time;
        /// Time this campaign ends
        end : ?Time.Time;
    };

    func adToJson((id : AdID, ad : Ad)) : Text {
        "{" #
            "\"owner\":\"" # ad.owner # "\"," #
            "\"id\":\"" # Nat.toText(id) # "\"," #
            "\"image\":\"" # ad.image # "\"," #
            "\"link\":\"" # ad.link # "\"," #
            "\"start\":" # (switch (ad.start) {
                case null "null";
                case (?start) "\"" # Int.toText(start) # "\"";
            }) # "," #
            "\"end\":" # (switch (ad.end) {
                case null "null";
                case (?end) "\"" # Int.toText(end) # "\"";
            }) # "," #
            "\"profile\":" # (switch (ad.profile) {
                case null "null";
                case (?profile) targetToJson(profile);
            }) #
        "}"
    };

    /**
     * Private implementation details
     */
    
    /// Returns if two AdIDs are equal
    func equalID(a : AdID, b: AdID) : Bool {
        a == b
    };

    /// Hash function used in ads map
    /// XXX: Apparently getting moved someday?
    let hashID : AdID -> Hash.Hash = Int.hash;

    /**
     * Application State
     * 
     * HashMap isn't stable so none of this is stable at the moment
     */

    /// Next available `Ad` id
    ///
    /// TODO: Could this be subject to race conditions? Docs unclear on when race conditions are possible
    stable var nextID : AdID = 0;

    /// Ad repository backup used during canister code upgrades
    stable var adsBackup : [(AdID, Ad)] = [];
    /// Ad repository used during runtime
    var ads = TrieMap.fromEntries(adsBackup.vals(), equalID, hashID);

    system func preupgrade() {
        adsBackup := Iter.toArray(ads.entries());
    };

    system func postupgrade() {
        adsBackup := [];
    };

    /**
     * "API" I guess
     */
 
    func allAdsJsonPrivate() : Text {
        "[" #
            Text.join(",", Iter.map(ads.entries(), adToJson)) #
        "]"
    };

    public query func addAdsJson() : async Text {
        allAdsJsonPrivate()
    };
    
    /// Add an ad to the ledger
    ///
    /// @return ID of the added ad
    public func add(ad : Ad) : async AdID {
        let id = nextID;
        nextID += 1;
        ads.put(id, ad);
        return id;
    };

    /// Delete an ad from the ledger
    ///
    /// @return The Ad that was just deleted, or null if it didn't exist
    public func delete(id : AdID) : async ?Ad {
        return ads.remove(id);
    };

    /// Get an ad from the ledger
    ///
    /// @return The Ad with the corresponding ID, or null if it doesn't exist
    public func get(id : AdID) : async ?Ad {
        return ads.get(id);
    };

    /// Replace (update) an ad in the ledger
    ///
    /// If an ad
    /// @return Previous Ad existing at that ID, or null if that ID isn't in use
    public func replace(id : AdID, newAd : Ad) : async ?Ad {
        // Make sure ID is in use to avoid inserting ads at Ids the ID generator doesn't know about
        return switch (ads.get(id)) {
            case (?oldAd) ads.replace(id, newAd);
            case null null;
        }
    };

    /// Return a map of all ads in the ledger
    public query func getAds() : async List.List<(AdID, Ad)> {
        Iter.toList(ads.entries())
    };

    public query func http_request(request : Http.Request) : async Http.Response {
        // Reject non-root paths
        if (request.url != "/") {
            let body = Http.textToNat8s("Not Found");
            return {
                status_code = 404;
                headers = [("Content-Length", Nat.toText(body.size()))];
                body = body;
            }
        };

        // Reject non-GET/HEAD requests
        // Case sensitive matching because the HTTP protocol is case-sensitive
        // Also Motko doesn't have capitalization functions in the standard library
        // TODO: Support HEAD?
        if (request.method != "GET") {
            let body = Http.textToNat8s("Method Not Allowed");
            return {
                status_code = 405;
                headers = [
                    ("Allow", "GET"),
                    ("Content-Length", Nat.toText(body.size())),
                ];
                body = body;
            }
        };

        let body = Http.textToNat8s(allAdsJsonPrivate());
        return {
            status_code = 200;
            headers = [
                ("Access-Control-Allow-Origin", "*"),
                ("Content-Length", Nat.toText(body.size())),
                ("Content-Type", "application/json"),
                ("X-Content-Type-Options", "nosniff"),
            ];
            body = body;
        }
    };
}
