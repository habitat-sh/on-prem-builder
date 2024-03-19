// This is a deno script. You can run this script using 'deno main.js'

import { parse } from "https://deno.land/std@0.205.0/flags/mod.ts";

const flags = parse(Deno.args, {
    boolean: ["help"],
    string: ["bldr-url", "origins", "output"],
    default: { help: false, "output": "packages.txt" },
});

if (flags["help"] || flags["bldr-url"] == null || flags["origins"] == null) {
    console.log("usage: pkg-tool --origins <ORIGINS> --bldr-url <BLDR_URL>");
    console.log("example: pkg-tool --origins chef,habitat --bldr-url https://bldr.habitat.sh");
} else {

    const OUTPUT = flags["output"];
    const ORIGINS = flags["origins"].split(",");
    const BASE_DEPOT_URL = flags["bldr-url"];
    const TARGETS = ['x86_64-linux', 'x86_64-linux-2', 'x86_64-windows'];
    console.log(`Checking origins "${ORIGINS.join('", "')}" at "${BASE_DEPOT_URL}"`)


    const packages = [];
    for (const origin of ORIGINS) {
        let range = 0;
        while (true) {
            const url = `${BASE_DEPOT_URL}/v1/depot/${origin}/pkgs?range=${range}`;
            console.log(`Fetching data from "${url}"`)
            let res = await fetch(url);
            let json = await res.json();
            if (json.data.length === 0) {
                break;
            }
            range += 50;
            for (const item of json.data) {
                packages.push({ origin: item.origin, name: item.name });
            }
        }
        console.log(`Discovered ${packages.length} packages`);
    }

    const used_packages_list = [];

    for (const pkg of packages) {
        for (const target of TARGETS) {
            try {
                const url = `${BASE_DEPOT_URL}/v1/depot/pkgs/${pkg.origin}/${pkg.name}/latest?target=${target}`;
                console.log(`Fetching data from "${url}"`)
                let res = await fetch(url);
                let json = await res.json();
                for (const tdep of json.tdeps) {
                    const package_name = `${tdep.origin}/${tdep.name}/${tdep.version}/${tdep.release}`;
                    if (used_packages_list.indexOf(package_name) < 0) {
                        used_packages_list.push(package_name);
                    }
                }
                for (const build_tdep of json.build_tdeps) {
                    const package_name = `${build_tdep.origin}/${build_tdep.name}/${build_tdep.version}/${build_tdep.release}`;
                    if (used_packages_list.indexOf(package_name) < 0) {
                        used_packages_list.push(package_name);
                    }
                }
                console.log(`Checking deps of ${pkg.origin}/${pkg.name} for ${target}`);
            } catch (err) {
                // console.log(`Error fetching ${pkg.origin}/${pkg.name} for ${target}`);
            }
        }
    }
    used_packages_list.sort();
    console.log(`Discovered ${used_packages_list.length} used packages`);
    await Deno.writeTextFile(OUTPUT, used_packages_list.join("\n"));
    console.log(`Packages written to "${OUTPUT}"`);
    console.log(`Please share this file with the Progress Customer Success team.`);
}
