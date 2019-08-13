const BUCKET_DEFAULT: &str = "habitat-on-prem-builder-bootstrap";
const S3_ROOT_URL_DEFAULT: &str = "https://s3-us-west-2.amazonaws.com";
const LATEST: &str = "LATEST.tar.gz";
const BLDR_DEFAULT: &str = "https://bldr.habitat.sh/v1/depot";
const BLDR_BASE: &str = "https://bldr.habitat.sh/v1";
const PRODUCT: &str = "hab";
const VERSION: &str = "1.0";

extern crate env_logger;
extern crate rusoto_core;
extern crate rusoto_s3;

use clap::App;
use std::process;

//use log::Level;

use habitat_api_client as hab_api_client;
use habitat_core as hab_core;

mod builder_api;
mod error;
mod fetch_expand_cmd;
mod package_spec;

fn main() {
    env_logger::init();

    let matches = App::new("builder_tool")
        .version("0.1")
        .author("Habitat habitat@habitat.sh")
        .about("Tool to sync on prem builder")
        .subcommand(fetch_expand_cmd::make_subcommand())
        .get_matches();

    let result = match matches.subcommand() {
        (fetch_expand_cmd::NAME, Some(m)) => fetch_expand_cmd::run(m),
        _ => 0,
    };
    process::exit(result)
}
