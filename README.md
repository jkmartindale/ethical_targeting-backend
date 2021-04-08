# Ethical Targeting Backend

This code makes up the backend service for Ethical Targeting, running on the [DFINITY Internet Computer](https://dfinity.org/).

So far this is made up of three canisters:

* `ads_ledger`: Place where ads are stored and retrieved from
* `www`: Web interface to manage ads (slightly modified version of [in-development Candid UI](https://github.com/dfinity/candid/tree/c54bb6c158/tools/ui))

## Build

**Prerequisites:**

* [npm](https://nodejs.org/en/)
* [DFINITY Canister Software Development Kit](https://sdk.dfinity.org/docs/index.html)
* [Rust Compiler](https://rustup.rs/)
* [Binaryen](https://github.com/WebAssembly/binaryen) (for `wasm-opt`)

After installing rustup, add the `wasm32-unknown-unknown` target if you haven't already:

```bash
rustup target add wasm32-unknown-unknown
```

Then you can clone the repository and build:

```bash
git clone https://github.com/jkmartindale/ethical_targeting-backend.git
cd ethical_targeting-backend
npm install
# Required to generate canister_ids.json
dfx canister --network=ic create --all
# All that's necessary after the first run
dfx deploy --network=ic
```

The console output of `dfx` should list canister IDs for `ads_ledger` and `www`, which you can also find in `canister_ids.json`.

Access the all ads JSON endpoint at `<ads_ledger-canister_id>.ic0.app` and the ads manager at `<www-canister_id>.ic0.app`.

Currently the ad manager can only make calls against a canister on the `ic` network. Since it is basically equivalent to Candid UI, you can instead visit `http://127.0.0.1:8000/candid?canisterId=<www-canister_id>` for a very similar experience.
