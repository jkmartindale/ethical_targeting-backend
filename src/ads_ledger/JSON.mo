import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Nat16 "mo:base/Nat16";
import Text "mo:base/Text";
import Time "mo:base/Time";

import Ad "Ad";
import Target "Target";

/// Functions to convert types to strings of JSON
///
/// Each Motoko type to be serialized is accompanied by a function named after that type, which converts an object of that type to a JSON string.
/// The beauty of this is functions can be composed together to "mirror" the type system, including generics.
/// Serializers for generics take a single argument of a function that converts its type into JSON and returns a function that converts the non-generic type to JSON.
/// This can be used as `generic(type)(object)`, which looks very similar to `generic<type> object`.
/// Example: nullable(matchRules(text))(object) resembles `Nullable<MatchRules<Text>> object`.
module {
    /// Represents strings of JSON
    ///
    /// Used to make function signatures more clear where they expect or promise valid JSON vs. regular text
    public type Json = Text;

    /// Wrap text in double quotes
    ///
    /// This is a helper function for other type converters but should never be used publicly.
    func quote(text : Text) : Text {
        "\"" # text # "\""
    };

    /**
     * Base JSON types
     */

    /// Convert a generic array to JSON
    ///
    /// Call this function curry-style, e.g. `array(ad)(adsToSerialize)`
    public func array<T>(jsonify : T -> Json) : [T] -> Json {
        func (obj : [T]) : Json {
            "[" # 
                Text.join(",", Iter.map(Iter.fromArray(obj), jsonify)) #
            "]"
        }
    };

    /// Convert key-value tuples to a JSON object
    ///
    /// The key must be unquoted (quotes will be escaped) and the value must be safe, valid JSON as-is.
    /// This is because keys can only be strings but values can be any type.
    public func obj(properties : [(Text, Json)]) : Json {
        "{" #
            Text.join(",",
                Iter.map(Iter.fromArray(properties), func ((key : Text, value : Json)) : Json {
                    text(key) # ":" # value
                })
            ) #
        "}"
    };

    /// Convert a generic nullable type to JSON
    ///
    /// Call this function curry-style, e.g. `nullable(text)(textToSerialize)`
    public func nullable<T>(jsonify : T -> Json) : ?T -> Json {
        func (obj : ?T) : Json {
            switch obj {
                case null "null";
                case (?obj) jsonify(obj);
            }
        }
    };

    /// Escape a text value and wrap it in double quotes
    public func text(text : Text) : Json {
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
    public func age(age : Target.Age) : Json {
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
    public func gender(gender : Target.Gender) : Json {
        quote(switch gender {
            case (#masculine) "masculine";
            case (#non_binary) "non_binary";
            case (#feminine) "feminine";
        })
    };

    /// Convert an ad image to JSON
    public func image(image : Ad.Image) : Json {
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

    /// Convert a generic MatchRules type to JSON
    ///
    /// Call this function curry-style, e.g. `matchRules(text)(textToSerialize)`
    public func matchRules<T>(jsonify : T -> Json) : Target.MatchRules<T> -> Json {
        func (rules : Target.MatchRules<T>) : Json {
            obj([
                ("all", array(jsonify)(rules.all)),
                ("some", array(jsonify)(rules.some)),
                ("none", array(jsonify)(rules.none)),
            ])
        }
    };

    /// Convert an occupation to JSON
    public let occupation = text;

    /// Convert an ad target to JSON
    public func target(target : Target.Target) : Json {
        obj([
            ("age", nullable(matchRules(age))(target.age)),
            ("gender", nullable(matchRules(gender))(target.gender)),
            ("occupation", nullable(matchRules(occupation))(target.occupation)),
            ("industry", nullable(matchRules(industry))(target.industry)),
            ("interests", nullable(matchRules(interest))(target.interests)),
            ("dislikes", nullable(matchRules(dislike))(target.dislikes)),
        ])
    };

    /// Convert a time option to JSON
    public func time(time : Time.Time) : Json {
        quote(Int.toText(time))
    };

    /// Convert a tuple of (AdID, Ad) to JSON
    public func ad((id : Ad.ID, ad : Ad.Ad)) : Json {
        obj([
            ("owner", text(ad.owner)),
            ("id", quote(Nat.toText(id))),
            ("image", image(ad.image)),
            ("link", quote(ad.link)),
            ("start", nullable(time)(ad.start)),
            ("end", nullable(time)(ad.end)),
            ("profile", nullable(target)(ad.profile)),
        ])
    };

    /// Convert an iterator of ads to JSON
    public func ads(iter : Iter.Iter<(Ad.ID, Ad.Ad)>) : Json {
        array(ad)(Iter.toArray(iter))
    };
}
