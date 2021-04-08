import { fetchActor, render } from './candid';
import { Principal } from '@dfinity/agent';
import canisters from '../../canister_ids.json';

async function main() {
    if (!canisters.ads_ledger || !canisters.ads_ledger.ic) {
        throw new Error('Ensure canister_ids.json specifies an `ads_ledger` canister ID on the ic network');
    } else {
        const canisterId = Principal.fromText(canisters.ads_ledger.ic);
        const actor = await fetchActor(canisterId);
        render(canisterId, actor);
        const app = document.getElementById('app');
        const progress = document.getElementById('progress');
        progress!.remove();
        app!.style.display = 'block';
    }
}

main().catch(err => {
    const div = document.createElement('div');
    div.innerText = 'An error happened in Candid canister:';
    const pre = document.createElement('pre');
    pre.innerHTML = err.stack;
    div.appendChild(pre);
    const progress = document.getElementById('progress');
    progress!.remove();
    document.body.appendChild(div);
    throw err;
});
