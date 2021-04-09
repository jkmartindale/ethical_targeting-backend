# Ethical Targeting Ad Ledger/Manager

This code makes up the backend service for Ethical Targeting, an ad network designed with privacy baked in. For the browser extension source, see [@larkinds/EthicalTargeting](https://github.com/larkinds/EthicalTargeting).

Most data collection of Internet user behavior ultimately comes from advertising's desire for **audience targeting and campaign analytics**. Constant exposés in the news and the gradual rollout of data privacy regulations are not enough to fight this **technological arms race**. Pandora's box has been opened and advertisers will not back down from having access to targeting and analytics.

Ethical Targeting recognizes this reality and compromises by **moving ad targeting to the browser**. Browsers pull from a public ledger of ads and match ads with locally stored user profiles that **never touch the Internet**. Users can update, remove, and switch between multiple profiles at any time **with immediate effect**, or disable ad personalization altogether. We can't convert the megacorps with massive ad budgets, but we can provide an ethical alternative to the big ad networks for **SMBs who rely on effective advertising to drive revenue**.

This service runs on the [DFINITY Internet Computer](https://dfinity.org/), a decentralized network of independent data centers enabling a public ad network that is:

* **Transparent:** anyone can see what ads are in the ledger (past/present/future) and who funded them  
* **Private:** nobody will know who clicked on an ad or what their interests/demographics are  
* **Targeted:** actually relevant, making ads more useful to the user and effective for the advertiser  
* **Truly open:** not stored in any one data center and controlled by community governance in the future

## Usage

The backend service is made up of two canisters:

* `ads_ledger`: open repository of ads (and the API endpoint for browsers)
* `www`: web interface to manage/browse ads (slightly modified version of [in-development Candid UI](https://github.com/dfinity/candid/tree/c54bb6c158/tools/ui))

To see the ad JSON payload that the browser receives from the backend service, visit <https://gf3q7-kyaaa-aaaab-aa6aq-cai.ic0.app>.

To create/edit/view ads, visit the ad manager at <https://glz5x-riaaa-aaaab-aa6bq-cai.ic0.app>.

### Ad Manager Functions

* `add`: add a new ad to the ledger and get its ID  
* `allAdsJson`: JSON payload of all ads in the ledger  
* `delete`: remove an ad from the ledger by ID  
* `get`: look up an ad by ID
* `http_request`: used by the `ic0.app` gateway to act as an API server  
* `replace`: update an ad by ID

### Ad Format
Ethical Targeting uses an ad format that is incredibly powerful and flexible, though it can be confusing at first. Here's the breakdown:

**Required attributes**
* `owner`: Sponsor of this advertisement  
* `link`: URL to visit when the user clicks on the ad  
* `image`: image to display for the ad  
    * `url`: URL of the image to display  
    * `height`: height of the image in pixels  
    * `width`: width of the image in pixels

**Optional attributes**  
In the ad manager, optional attributes are shown as a checkbox. Checking the box expands the fields that make up an optional attribute, and unchecking the box removes the attribute.  
* `start`: time this campaign starts (in nanoseconds since the Unix epoch)  
* `end`: time this campaign ends (in nanoseconds since the Unix epoch)  
* `profile`: describes the audience to target (if unspecified, anyone can be shown this ad)  
    * `age`: age range a person falls into  
    * `occupation`: primary business function of employment (not company)  
    * `industry`: primary business category of employer (not employee)  
    * `interests`: topics a user is interested in  
    * `gender`: primary gender expression masculine/feminine/non-binary (clearly not exhaustive, but we've yet to see ads targeting more specific identities)  
    * `dislikes`: topics a user has chosen to hide  

**Match rules**  
Each attribute in an ad profile is an (optional) set of rules made up of `all`, `some`, and `none`. Each of these three sub-attributes is a list. For a profile to match an ad, it must have everything in `all`, at least one thing in `some` (if not empty), and nothing in `none`.

To create a profile in the ad manager, first select the checkbox next to the profile attribute, type a length into all/some/none specifying how many values are in each list (or 0 for none), then enter the values.

For example, I might target an ad for a commercial Minecraft hosting service to `interests.all=minecraft`, `interests.some=servers,multiplayer games`, and `age.none=age0_12`.

This system is a little complex, but with a little practice it becomes straightforward. You can mix and match rules for each profile attribute to get as specific and relevant as you want, all without nonconsensual data harvesting.

## Development
The DFINITY Canister SDK only supports Unix-like systems (including Linux and macOS).

**For Windows environments**  
* Use the [Windows Subsystem for Linux](https://docs.microsoft.com/en-us/windows/wsl/install-win10)  
* Ensure your Linux distribution is running WSL 2
* Use a Linux partition as your development workspace (e.g. `/home/username`) instead of any Windows-mounted partitions (e.g. `/mnt/c`)  
* If you have npm installed in Windows, you will need to install Node.js through the [Node Version Manager](https://github.com/nvm-sh/nvm) (nvm) in your Linux distribution

**Prerequisites**

* [npm](https://nodejs.org/en/)
* [DFINITY Canister SDK](https://sdk.dfinity.org/docs/index.html)
* [Rust compiler](https://rustup.rs/) (with `cargo`)
* [Binaryen](https://github.com/WebAssembly/binaryen) (for `wasm-opt`)

**Setup**  
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

Currently the ad manager can only make calls against a canister on the `ic` network. Since it is basically equivalent to Candid UI, you can instead visit `http://127.0.0.1:8000/candid?canisterId=<www-canister_id>` for testing the `ads_ledger` canister locally.
