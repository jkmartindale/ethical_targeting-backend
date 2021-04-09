/// Types and associated functions for ad target attributes
module {
    /// Standard age groups for targeting
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

    /// Primary gender expression to target
    ///
    /// This is obviously not an exhaustive list, but I have yet to see advertising catered to anything outside of these three categories. In most cases you shouldn't care about targeting gender anyway.
    public type Gender = {
        #masculine;
        #non_binary;
        #feminine;
    };

    /// Primary product/service of employee's organization (corresponding to sales, not job title)
    public type Industry = Text;

    /// Primary business function of an employee (corresponding to job title, not company)
    public type Occupation = Text;

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

    // Profile attributes an ad is relevant to
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
}
