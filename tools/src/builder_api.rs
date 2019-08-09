//
//
//extern crate serde_derive;
use serde_json::{Value};

extern crate reqwest;

use crate::hab_core::package::{PackageIdent, PackageTarget};
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

// We can have 
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

    //println!("Response: {:?}", response);

    if let Err(err) = response.error_for_status_ref() {
        return Err(Error::HttpClient(err))
    }
    
    let json = response.json();
    //println!("Response json: {:?}", json);
    
    return json.map_err(|e| Error::HttpClient(e))
}

pub fn fetch_package_details(root: &str, package_to_fetch: &PackageIdent, target: &PackageTarget)
                             -> Result< Vec<(PackageIdent, PackageTarget)> >  {
    // E.g. 'https://bldr.habitat.sh/v1/depot/pkgs/core/7zip/latest?target=x86_64-linux'
    //       https://bldr.habitat.sh/v1/depot/channels/core/stable/pkgs/7zip/latest?target=x86_64-linux' | j
    let request_url = format!("{root}/channels/{origin}/stable/pkgs/{name}/latest?target={target}",
                              root = root,
                              origin = package_to_fetch.origin,
                              name = package_to_fetch.name,
                              target = target);
    
    let json_or_error = fetch_json(&request_url);

//    println!("Response j|e: {:?}", json_or_error);
 
    let json : Value = json_or_error?;

    let expanded_package : PackageIdent = serde_json::from_value(json["ident"].to_owned()).unwrap();
    // println!("DEP: {:?}", expanded_package);
    
    // TODO: Figure out if to_owned is right thing to do; without it I was getting 'cannot move out of borrowed content'
    // For more information about this error, try `rustc --explain E0507`.
    let tdeps : Vec<PackageIdent> = serde_json::from_value(json["tdeps"].to_owned()).unwrap();

    let mut full_deps : Vec<(PackageIdent,PackageTarget)> = tdeps.iter().map(|package| (package.to_owned(), target.to_owned())).collect();
    full_deps.push((expanded_package, target.to_owned()));
    
    // println!("full_deps: {:?}", full_deps);
    Ok(full_deps)
}

pub fn make_fully_qualified_ident(package: &PackageIdent, target: &PackageTarget) -> String {
    format!("{},{},{},{},{}",
            package.origin,
            package.name,
            package.version.as_ref().unwrap(),
            package.release.as_ref().unwrap(),
            target)
}

pub fn make_download_resource(package: &PackageIdent, target: &PackageTarget) -> String {
    format!("/pkgs/{origin}/{name}/{version}/{release}/download?target={target}",
            origin = package.origin,
            name = package.name,
            version = package.version.as_ref().unwrap(),
            release = package.release.as_ref().unwrap(),
            target = target)    
}
