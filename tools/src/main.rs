
const BUCKET_DEFAULT: &str = "habitat-on-prem-builder-bootstrap";
const S3_ROOT_URL_DEFAULT: &str = "https://s3-us-west-2.amazonaws.com";
const LATEST: &str = "LATEST.tar.gz";
const BLDR_DEFAULT: &str = "https://bldr.habitat.sh/v1/depot";

mod package_util;
mod builder_api;
mod fetch_expand_cmd;

use std::process;
//use clap::{Arg, ArgMatches, App, SubCommand};
use clap::{App};

//#[macro_use] extern crate log;
extern crate env_logger;
//use log::Level;

use habitat_core as hab_core;

fn main() {
    env_logger::init();
        
    let matches = App::new("builder_tool")
        .version("0.1")
        .author("Habitat habitat@habitat.sh")
        .about("Tool to sync on prem builder")
        .subcommand(fetch_expand_cmd::make_subcommand()).get_matches();

    let result = match matches.subcommand() {
        (fetch_expand_cmd::NAME, Some(m)) => fetch_expand_cmd::run(m),
        _ => 0
    };
    process::exit(result)
}


