import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Hash "mo:base/Hash";
import List "mo:base/List";
import Nat "mo:base/Nat";
import TrieMap "mo:base/TrieMap";

import Ad "Ad";
import Http "Http";
import JSON "JSON";

actor AdsLedger {
    /**
     * Private implementation details
     */
    
    /// Returns true if two AdIDs are equal
    func equalID(a : Ad.ID, b: Ad.ID) : Bool {
        a == b
    };

    /// Hash function used in ads map
    /// XXX: Apparently getting moved someday?
    let hashID : Ad.ID -> Hash.Hash = Int.hash;

    /**
     * Application State
     */

    /// Next available `Ad` id
    ///
    /// TODO: Could this be subject to race conditions? Docs unclear on when race conditions are possible
    stable var nextID : Ad.ID = 0;

    /// Ad repository backup used during canister code upgrades
    stable var adsBackup : [(Ad.ID, Ad.Ad)] = [];
    /// Ad repository used during runtime
    var ads = TrieMap.fromEntries(adsBackup.vals(), equalID, hashID);

    /// Store ads map to stable array before canister upgrade
    system func preupgrade() {
        adsBackup := Iter.toArray(ads.entries());
    };

    /// Clear stable array backup after canister upgrade
    system func postupgrade() {
        adsBackup := [];
    };

    /**
     * "API" I guess
     */

    public query func allAdsJson() : async Text {
        JSON.ads(ads.entries())
    };
    
    /// Add an ad to the ledger
    ///
    /// @return ID of the added ad
    public func add(ad : Ad.Ad) : async Ad.ID {
        let id = nextID;
        nextID += 1;
        ads.put(id, ad);
        id
    };

    /// Delete an ad from the ledger
    ///
    /// @return The Ad that was just deleted, or null if it didn't exist
    public func delete(id : Ad.ID) : async ?Ad.Ad {
        ads.remove(id)
    };

    /// Get an ad from the ledger
    ///
    /// @return The Ad with the corresponding ID, or null if it doesn't exist
    public func get(id : Ad.ID) : async ?Ad.Ad {
        ads.get(id)
    };

    /// Replace (update) an ad in the ledger
    ///
    /// If an ad
    /// @return Previous Ad existing at that ID, or null if that ID isn't in use
    public func replace(id : Ad.ID, newAd : Ad.Ad) : async ?Ad.Ad {
        // Make sure ID is in use to avoid inserting ads at Ids the ID generator doesn't know about
        switch (ads.get(id)) {
            case (?oldAd) ads.replace(id, newAd);
            case null null;
        }
    };

    /// Return a list of all ads in the ledger
    ///
    /// @return List of (Ad.ID, Ad.Ad) tuples
    public query func getAds() : async List.List<(Ad.ID, Ad.Ad)> {
        Iter.toList(ads.entries())
    };

    /// Return JSON of all the ads in the ledger, or reject if not GET /
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
        // Also Motoko doesn't have capitalization functions in the standard library
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

        let body = Http.textToNat8s(JSON.ads(ads.entries()));
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
