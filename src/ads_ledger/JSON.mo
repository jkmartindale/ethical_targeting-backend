import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Nat16 "mo:base/Nat16";
import Text "mo:base/Text";
import Time "mo:base/Time";

import Ad "Ad";
import Target "Target";

/// Functions to convert types to strings of JSON
module {
    /// Wrap text in double quotes
    func quote(text : Text) : Text {
        "\"" # text # "\""
    };

    /**
     * Base JSON types
     */

    /// Convert an iterator of JSON objects to a JSON array
    public func array(jsonObj : Iter.Iter<Text>) : Text {
        "[" # 
            Text.join(",", jsonObj) #
        "]"
    };

    /// Convert key-value tuples to a JSON object
    ///
    /// The key must be unquoted (quotes will be escaped) and the value must be safe, valid JSON as-is. This is because keys can only be strings but values can be any type.
    public func obj(properties : [(Text, Text)]) : Text {
        "{" #
            Text.join(",",
                Iter.map(Iter.fromArray(properties), func ((key : Text, value : Text)) : Text {
                    text(key) # ":" # value
                })
            ) #
        "}"
    };

    /// Convert a nullable object to JSON
    ///
    /// Requires passing a function to convert the type to a string of JSON. Passing functions in this module should be sufficient, e.g. JSON.text or JSON.gender
    public func nullable<T>(jsonify : T -> Text, obj : ?T) : Text {
        switch obj {
            case null "null";
            case (?obj) jsonify(obj);
        }
    };

    /// Escape a text value and wrap it in double quotes
    public func text(text : Text) : Text {
        quote(
            Text.replace(
            Text.replace(
            Text.replace(
            Text.replace(
            Text.replace(text,
            #char '\"', "\\\""),
            #char '\\' , "\\\\"),
            #char '\n' , "\\n"),
            #char '\r' , "\\r"),
            #char '\t' , "\\t")
        )
    };

    /**
     * Ad ledger types
     */

    /// Convert an age variant to JSON
    public func age(age : Target.Age) : Text {
        quote(switch age {
            case (#age0_12) "0-12";
            case (#age13_17) "13-17";
            case (#age18_24) "18-24";
            case (#age25_34) "25-34";
            case (#age35_44) "35-44";
            case (#age45_54) "45-54";
            case (#age55_64) "55-64";
            case (#age65_74) "65-74";
            case (#age75_) "75+";
        })
    };

    /// Convert a dislike to JSON
    public let dislike = text;

    /// Convert a gender identity variant to JSON
    public func gender(gender : Target.Gender) : Text {
        quote(switch gender {
            case (#masculine) "masculine";
            case (#non_binary) "non_binary";
            case (#feminine) "feminine";
        })
    };

    /// Convert an ad image to JSON
    public func image(image : Ad.Image) : Text {
        obj([
            ("url", quote(image.url)),
            ("height", Nat16.toText(image.height)),
            ("width", Nat16.toText(image.width)),
        ])
    };

    /// Convert an industry to JSON
    public let industry = text;

    /// Convert an interest to JSON
    public let interest = text;

    /// Convert match rules to JSON
    ///
    /// Requires passing a function to convert the type to a JSON string. Passing functions in this module should be sufficient, e.g. JSON.text or JSON.gender
    public func matchRules<T>(rules : ?Target.MatchRules<T>, jsonify : T -> Text) : Text {
        // I would use nullable() here if Motoko supported currying
        switch rules {
            case null
                "null";
            case (?rules)
                obj([
                    ("all", array(Iter.map(Iter.fromArray(rules.all), jsonify))),
                    ("some", array(Iter.map(Iter.fromArray(rules.some), jsonify))),
                    ("none", array(Iter.map(Iter.fromArray(rules.none), jsonify))),
                ])
        }
    };

    /// Convert an occupation to JSON
    public let occupation = text;

    /// Convert an ad target to JSON
    public func target(target : Target.Target) : Text {
        obj([
            ("age", matchRules(target.age, age)),
            ("gender", matchRules(target.gender, gender)),
            ("occupation", matchRules(target.occupation, occupation)),
            ("industry", matchRules(target.industry, industry)),
            ("interests", matchRules(target.interests, interest)),
            ("dislikes", matchRules(target.dislikes, dislike)),
        ])
    };

    /// Convert a time option to JSON
    public func time(time : Time.Time) : Text {
        quote(Int.toText(time))
    };

    /// Convert a tuple of (AdID, Ad) to JSON
    public func ad((id : Ad.ID, ad : Ad.Ad)) : Text {
        obj([
            ("owner", text(ad.owner)),
            ("id", quote(Nat.toText(id))),
            ("image", image(ad.image)),
            ("link", quote(ad.link)),
            ("start", nullable(time, ad.start)),
            ("end", nullable(time, ad.end)),
            ("profile", nullable(target, ad.profile)),
        ])
    };

    public func ads(iter : Iter.Iter<(Ad.ID, Ad.Ad)>) : Text {
        array(Iter.map(iter, ad))
    }
}
