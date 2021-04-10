import Char "mo:base/Char";
import Iter "mo:base/Iter";
import Nat8 "mo:base/Nat8";
import Nat32 "mo:base/Nat32";

/// Objects used in the (currently undocumented) HTTP API exposed to canisters
///
/// In the future these types will probably use `Blob` instead of `[Nat8]`.
/// The two types are equivalent in Candid, but Motoko's `Blob` is more efficient.
/// Unfortuantely it's also more unfinished, and lacks an easy way to be created from arbitrary `Text`.
module {
    /// 2-tuple of HTTP header name and value
    public type HeaderField = (Text, Text);

    /// HTTP Request record
    public type Request = {
        method : Text;
        url : Text;
        headers : [HeaderField];
        body : [Nat8];
    };

    /// HTTP Request record
    public type Response = {
        status_code : Nat16;
        headers : [HeaderField];
        body : [Nat8];
    };

    /// Convert a `Text` string to `[Nat8]` (useful for `Response` body encoding)
    public func textToNat8s(text : Text) : [Nat8] {
        Iter.toArray(Iter.map(text.chars(), func (char : Char) : Nat8 {
            Nat8.fromNat(Nat32.toNat(Char.toNat32(char)))
        }))
    };
}
