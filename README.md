# Ethical Targeting Backend

This code makes up the backend service for Ethical Targeting, running on the [DFINITY Internet Computer](https://dfinity.org/).

So far this is made up of three canisters:

* `ads_ledger`: Place where ads are stored and retrieved from
* `www`: Web interface to manage ads (currently unmodified [Candid UI](https://github.com/dfinity/candid/tree/master/tools/ui))

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
dfx start --background
dfx deploy
```
