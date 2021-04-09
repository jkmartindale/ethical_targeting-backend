import Target "Target";
import Time "mo:base/Time";

/// Types and associated functions for ads in the ledger
module {
    /// Unique identifier for an ad
    public type ID = Nat;

    /// Image that serves as ad content
    public type Image = {
        /// Publicly accessible URL of image
        url : Text;
        /// Height of image in pixels
        height : Nat16;
        /// Width of image in pixels
        width : Nat16;
    };

    /// Ad campaign containing `image` and `link` to be shown to users matching `profile` between `start` and `end`
    public type Ad = {
        /// User with control over this ad
        owner : Text;
        /// Image that serves as ad content
        image : Image;
        /// URL the user should visit after clicking on the ad
        link : Text;
        /// Profile attributes this ad is relevant to, or null for no targeting
        profile : ?Target.Target;
        /// Time this campaign starts
        start : ?Time.Time;
        /// Time this campaign ends
        end : ?Time.Time;
    };

}
