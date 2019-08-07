//
//
//extern crate serde_derive;
use serde_json::{Value};

extern crate reqwest;

use crate::hab_core::package::{PackageIdent};
use crate::error::{Error,Result};


// TODO: PackageTarget is default linux x64 I think; we should figure out how to do others
// see PackageTarget::ACTIVE_PACKAGE_TARGET

// What I want is an API that for a set of targets gives latest in
// channel.  Simplest approach is write a call that takes target list,
// and hits 'https://bldr.habitat.sh/v1/depot/pkgs/core/7zip' to
// produce list of fully qualifed packages
// (e.g. https://bldr.habitat.sh/v1/depot/pkgs/core/7zip/16.02/20190625085936),
// and fetches the tdeps for them.
// NOTE the https://bldr.habitat.sh/v1/depot/pkgs/core/7zip' resource is slow, and produces data I don't need.
// What I *want* is to be able to specify the channel and get latest for all architectures.

// components/builder-api/src/server/resources/channels.rs
// "/depot/channels/{origin}/{channel}/pkgs/{pkg}/latest?target=x86_64-windows",

pub fn fetch_json(url: &str) -> Result< serde_json::Value > {
    println!("Fetching from URL {}", url);
    let mut response = match reqwest::get(url) {
        Ok(r) =>
            r,
        Err(e) => {
            println!("Requesting url {:?} got {:?}", url, e);
            return Err(Error::HttpClient(e))
        }
    };

    println!("Response: {:?}", response);
    
    // THIS CAN FAIL; (our list doesn't work all the way through for either windows or linux
    let json : Value = response.json().unwrap();
    return Ok(json)
}

pub fn fetch_package_details(root: &str, package_to_fetch: &PackageIdent) -> Result< Vec<PackageIdent> >  {
    // E.g. 'https://bldr.habitat.sh/v1/depot/pkgs/core/7zip/latest?target=x86_64-linux'
    //       https://bldr.habitat.sh/v1/depot/channels/core/stable/pkgs/7zip/latest?target=x86_64-linux' | j
    let request_url = format!("{root}/channels/{origin}/stable/pkgs/{name}/latest?target={target}",
                              root = root,
                              origin = package_to_fetch.origin,
                              name = package_to_fetch.name,
                              target = "x86_64-windows"); // "x86_64-linux"
    let json : Value = fetch_json(&request_url).unwrap();
    
    println!("Response: {:?}", json);
    
    // TODO: Figure out if to_owned is right thing to do; without it I was getting 'cannot move out of borrowed content'
    // For more information about this error, try `rustc --explain E0507`.
    let tdeps : Vec<PackageIdent> = serde_json::from_value(json["tdeps"].to_owned()).unwrap();
   
    println!("TDEPS: {:?}", tdeps);
    Ok(tdeps)
}
