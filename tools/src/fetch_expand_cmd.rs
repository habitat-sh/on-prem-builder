use std::fs::File;
use std::io::BufReader;
use std::io::prelude::*;
use std::str::FromStr;

//use log::{info, warn};
use clap::{Arg, ArgMatches, App, SubCommand};

use crate::builder_api;

// use crate::hab_core::{package::{self,
//                                 Identifiable,
//                                 PackageArchive,
//                                 PackageTarget,
//                                 PackageIdent},
//                       ChannelIdent};
use crate::hab_core::package::{PackageIdent, PackageTarget};

pub const NAME: &str = "fetch-from-file";
pub const FILE_ARG: &str = "file";

// TODO add targets option
pub fn make_subcommand<'c>() -> App<'c,'c> {
    let c = SubCommand::with_name(NAME)
        .about("Takes a list of packages and expands their transitive deps, and fetches all packages needed to support them")
        .arg(Arg::with_name(FILE_ARG)
             .help("File containing the package list")
             .index(1)
             );
    c
}

pub fn run(matches: &ArgMatches) -> i32 {
    println!("s1 {:?}", matches);
    let filename = matches.value_of(FILE_ARG).unwrap();

    let packages = read_file(filename).unwrap();

    let mut fetch_list = Vec::<(PackageIdent,PackageTarget)>::new();
    
    for pkg in &packages {
        for target in PackageTarget::supported_targets() {
            let  expanded_package = builder_api::fetch_package_details(crate::BLDR_DEFAULT, pkg, target);
            match expanded_package {
                Ok(mut p) =>
                    fetch_list.append(&mut p),
                Err(_e) =>
                    println!("Unable to resolve package {} for target {}", pkg, target)
            }
        }
    }
    0
}

pub fn read_file(filename: &str) -> Result<Vec<PackageIdent>, ()> {
    println!("Opening file {}", filename);
    
    let file = File::open(filename).unwrap(); // This is a likely user error; we should be more graceful
    let buf_reader = BufReader::new(file);
    let packages: Vec<PackageIdent> = buf_reader.lines().map(|x| expand_line(x.unwrap())).collect();

    println!("Read {} packages from {}", packages.len(), filename);
  
    Ok(packages)    
}

// Error handling would be nice here; if nothing else dump the offending string
pub fn expand_line(line: String) -> PackageIdent {
    PackageIdent::from_str(line.trim()).unwrap()
}

