//
//
//extern crate serde_derive;
use serde_json::{Result, Value};

extern crate reqwest;
//use reqwest::Error;

use crate::hab_core::package::{PackageIdent};


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

pub fn fetch_package_details(root: &str, package_to_fetch: &PackageIdent) -> Result< serde_json::Value >  {
    // E.g. 'https://bldr.habitat.sh/v1/depot/pkgs/core/7zip/latest?target=x86_64-linux'
    //       https://bldr.habitat.sh/v1/depot/channels/core/stable/pkgs/7zip/latest?target=x86_64-linux' | j
    let request_url = format!("{root}/channels/{origin}/stable/pkgs/{name}/latest?target={target}",
                              root = root,
                              origin = package_to_fetch.origin,
                              name = package_to_fetch.name,
                              target = "x86_64-linux"); // "x86_64-linux"
    println!("Fetching from URL {}", request_url);
    let mut response = reqwest::get(&request_url).unwrap();

    // THIS CAN FAIL; (our list doesn't work all the way through for either windows or linux
    let json : Value = response.json().unwrap();
    
    println!("Response: {:?}", json);
    
    // TODO: Figure out if to_owned is right thing to do; without it I was getting 'cannot move out of borrowed content'
    // For more information about this error, try `rustc --explain E0507`.
    let tdeps : Vec<PackageIdent> = serde_json::from_value(json["tdeps"].to_owned()).unwrap();
   
    println!("TDEPS: {:?}", tdeps);
    Ok(serde_json::Value::Null)
}
