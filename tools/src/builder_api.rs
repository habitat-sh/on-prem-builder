

use std::{ops::Deref,
          cmp::{Ordering,
                Ord,
                PartialOrd}
          };

use serde_json::Value;

extern crate reqwest;

use crate::error::{Error, Result};
use crate::hab_core::package::{PackageIdent, PackageTarget};


//
// This really belongs in hab_core::package; we really can't correctly specify a package with PackageIdent alone.
// The name is terrible, but haven't come up with a better one.
//
#[derive(Debug, Clone, Eq, Hash, PartialEq)] // Copy needs PackageIdent::Copy
pub struct PackageIdentTarget {
    // Ideally these would not be pub, but the accessors seem to hit issues with split borrows
    pub ident: PackageIdent,
    pub target: PackageTarget    
}

impl PackageIdentTarget {
    pub fn new(ident: PackageIdent, target: PackageTarget) -> Self {
        PackageIdentTarget {
            ident,
            target
        }
    }

    // These would be cool, except that they don't work
    //  println!("Fetching {} for {}", p.ident(), p.target()); hits
    //  E0308 or other borrow related errors, probably because they
    //  are opaque and the checker uses the lifetime of the whole
    //  struct and doesn't treat them as disjoint entities.

    //  https://doc.rust-lang.org/nomicon/borrow-splitting.html
    //
    //    pub fn ident(&self) -> PackageIdent { &self.ident }
    //    pub fn target(&self) -> PackageTarget { &self.target }

}

// It would be nice if Ident and Target implemented Ord, PartialOrd and PartialEq
impl Ord for PackageIdentTarget {
    fn cmp(&self, other: &Self) -> Ordering {
        let ord = self.ident.by_parts_cmp(&other.ident);
        match ord {
            Ordering::Equal => self.target.deref().cmp(&other.target.deref()),
            _ => ord
        }       
    }
}

impl PartialOrd for PackageIdentTarget {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some(self.cmp(other))
    }
}


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
pub fn fetch_json(url: &str) -> Result<serde_json::Value> {
    println!("Fetching from URL {}", url);
    let mut response = match reqwest::get(url) {
        Ok(r) => r,
        Err(e) => {
            println!("Requesting url {:?} got {:?}", url, e);
            return Err(Error::HttpClient(e));
        }
    };

    //println!("Response: {:?}", response);

    if let Err(err) = response.error_for_status_ref() {
        return Err(Error::HttpClient(err));
    }

    let json = response.json();
    //println!("Response json: {:?}", json);

    return json.map_err(|e| Error::HttpClient(e));
}

pub fn fetch_package_details(
    root: &str,
    package_to_fetch: &PackageIdent,
    target: &PackageTarget,
) -> Result<Vec<PackageIdentTarget>> {
    // E.g. 'https://bldr.habitat.sh/v1/depot/pkgs/core/7zip/latest?target=x86_64-linux'
    //       https://bldr.habitat.sh/v1/depot/channels/core/stable/pkgs/7zip/latest?target=x86_64-linux' | j
    let request_url = format!(
        "{root}/channels/{origin}/stable/pkgs/{name}/latest?target={target}",
        root = root,
        origin = package_to_fetch.origin,
        name = package_to_fetch.name,
        target = target
    );

    let json_or_error = fetch_json(&request_url);

    //    println!("Response j|e: {:?}", json_or_error);

    let json: Value = json_or_error?;

    let expanded_package: PackageIdent = serde_json::from_value(json["ident"].to_owned()).unwrap();
    // println!("DEP: {:?}", expanded_package);

    // TODO: Figure out if to_owned is right thing to do; without it I was getting 'cannot move out of borrowed content'
    // For more information about this error, try `rustc --explain E0507`.
    let tdeps: Vec<PackageIdent> = serde_json::from_value(json["tdeps"].to_owned()).unwrap();

    let mut full_deps: Vec<PackageIdentTarget> = tdeps
        .iter()
        .map(|package| PackageIdentTarget::new(package.to_owned(), target.to_owned()))
        .collect();
    full_deps.push(PackageIdentTarget::new(expanded_package, target.to_owned()));

    println!("full_deps: {:?}", full_deps);
    Ok(full_deps)
}

pub fn make_fully_qualified_ident(package: &PackageIdent, target: &PackageTarget) -> String {
    format!(
        "{},{},{},{},{}",
        package.origin,
        package.name,
        package.version.as_ref().unwrap(),
        package.release.as_ref().unwrap(),
        target
    )
}

pub fn make_download_resource(package: &PackageIdent, target: &PackageTarget) -> String {
    format!(
        "/pkgs/{origin}/{name}/{version}/{release}/download?target={target}",
        origin = package.origin,
        name = package.name,
        version = package.version.as_ref().unwrap(),
        release = package.release.as_ref().unwrap(),
        target = target
    )
}
