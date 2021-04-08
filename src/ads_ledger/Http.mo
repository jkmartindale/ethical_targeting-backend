import Char "mo:base/Char";
import Iter "mo:base/Iter";
import Nat8 "mo:base/Nat8";
import Nat32 "mo:base/Nat32";
import Prim "mo:prim";

/// Web server for the ad ledger, based on the (currently undocumented) HTTP API exposed to canisters
///
/// Warning: this code was written while tired and angry!
module {
    /// 2-tuple of HTTP header name and value
    ///
    /// Based on unreleased didjs Rust crate.
    public type HeaderField = (Text, Text);

    /// HTTP Request record
    ///
    /// Based on unreleased didjs Rust crate. Motoko's `Blob` primitive hardly even exists, so it's been replaced with `[Nat8]` (equivalent as far as Candid is concerned).
    public type Request = {
        method : Text;
        url : Text;
        headers : [HeaderField];
        body : [Nat8];
    };

    /// HTTP Request record
    ///
    /// Based on unreleased didjs Rust crate. Motoko's `Blob` is unfinished garbage, so it's been replaced with `[Nat8]` (equivalent as far as Candid is concerned).
    public type Response = {
        status_code : Nat16;
        headers : [HeaderField];
        body : [Nat8];
    };

    /// Convert a Text string to `[Nat8]` (useful for `Response` body encoding)
    ///
    /// DFINITY, why did you make me do this? I hate you. "Your new favorite language" was a lie!
    public func textToNat8s(text : Text) : [Nat8] {
        Iter.toArray(Iter.map(text.chars(), func (char : Char) : Nat8 {
            Nat8.fromNat(Nat32.toNat(Char.toNat32(char)))
        }))
    };
}
