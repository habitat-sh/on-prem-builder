use std::fs::File;
use std::io::prelude::*;
use std::io::BufReader;
use std::path::Path;
use std::str::FromStr;

//use log::{info, warn};
use clap::{App, Arg, ArgMatches, SubCommand};

use crate::builder_api;
use crate::error::{Error, Result};

// use crate::hab_core::{package::{self,
//                                 Identifiable,
//                                 PackageArchive,
//                                 PackageTarget,
//                                 PackageIdent},
//                       ChannelIdent};
use crate::hab_api_client::{self, BoxedClient, Client, Error::APIError};
use crate::hab_core::package::{PackageIdent, PackageTarget};

pub const NAME: &str = "fetch-from-file";
pub const FILE_ARG: &str = "file";

pub fn make_subcommand<'c>() -> App<'c, 'c> {
    // This blows up with lifetime issues; TODOge
    //    let target_help = format!("Target platform to fetch for (one of: {} all)",
    //                              supported_target_descriptor());
    let target_help = "Target platform to fetch for (one of:  x86_64-linux )";

    let c = SubCommand::with_name(NAME)
        .about("Takes a list of packages and expands their transitive deps, and fetches all packages needed to support them")
        .arg(Arg::with_name(FILE_ARG)
             .help("File containing the package list")
             .index(1)
             )
        .arg(Arg::with_name("target")
             .help(target_help));
    c
}

fn process_target_option(matches: &ArgMatches) -> Vec<PackageTarget> {
    let mut target_list = Vec::<(PackageTarget)>::new();
    if true {
        let build_target = "x86_64-windows";
        let target = PackageTarget::from_str(build_target).expect(&format!(
            "provided value of {} could not be parsed as a PackageTarget",
            build_target
        ));
        target_list.push(target)
    } else {
        for target in PackageTarget::supported_targets() {
            target_list.push(*target)
        }
    }
    return target_list;
}

pub fn run(matches: &ArgMatches) -> i32 {
    println!("s1 {:?}", matches);
    let filename = matches.value_of(FILE_ARG).unwrap();
    let target_list = process_target_option(matches);

    let packages = read_file(filename).unwrap();

    let mut fetch_list = Vec::<(PackageIdent, PackageTarget)>::new();

    for pkg in &packages {
        for target in &target_list {
            let expanded_package =
                builder_api::fetch_package_details(crate::BLDR_DEFAULT, pkg, &target);
            match expanded_package {
                Ok(mut p) => fetch_list.append(&mut p),
                Err(_e) => println!("Unable to resolve package {} for target {}", pkg, target),
            }
        }
    }

    fetch_packages(crate::BLDR_BASE, fetch_list, Path::new("hab-cache"));

    0
}

pub fn read_file(filename: &str) -> Result<Vec<PackageIdent>> {
    println!("Opening file {}", filename);

    let file = File::open(filename).unwrap(); // This is a likely user error; we should be more graceful
    let buf_reader = BufReader::new(file);
    let packages: Vec<PackageIdent> = buf_reader
        .lines()
        .map(|x| expand_line(x.unwrap()))
        .collect();

    println!("Read {} packages from {}", packages.len(), filename);

    Ok(packages)
}

// Error handling would be nice here; if nothing else dump the offending string
pub fn expand_line(line: String) -> PackageIdent {
    PackageIdent::from_str(line.trim()).unwrap()
}

pub fn fetch_packages(
    base_url: &str,
    fetch_list: Vec<(PackageIdent, PackageTarget)>,
    dst_path: &std::path::Path,
) -> Result<()> {
    let client = Client::new(
        base_url,
        crate::PRODUCT,
        crate::VERSION,
        Some(dst_path.clone()),
    )
    .unwrap();

    for i in &fetch_list {
        let (package, target) = i;
        println!("Fetching {} for {}", package, target);
        let archive = client
            .fetch_package((&package, *target), None, dst_path, None)
            .unwrap();
        println!("Archive {:?}", archive)
    }
    Ok(())
}

fn supported_target_descriptor() -> String {
    let strings: Vec<&str> = PackageTarget::supported_targets()
        .map(|t| t.as_ref())
        .collect();
    return strings.join(", ");
}
