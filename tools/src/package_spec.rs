use std::{
    cmp::{Ord, Ordering, PartialOrd},
    fmt,
    ops::Deref,
    str::FromStr,
};

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
    pub target: PackageTarget,
}

impl PackageIdentTarget {
    pub fn new(ident: PackageIdent, target: PackageTarget) -> Self {
        PackageIdentTarget { ident, target }
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
            _ => ord,
        }
    }
}

impl PartialOrd for PackageIdentTarget {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some(self.cmp(other))
    }
}

impl fmt::Display for PackageIdentTarget {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}/{}", self.ident, self.target)
    }
}

impl FromStr for PackageIdentTarget {
    type Err = Error;
    fn from_str(value: &str) -> Result<Self> {
        let items: Vec<&str> = value.split('/').collect();
        let (ident, target) = match items.len() {
            5 => (
                PackageIdent::new(items[0], items[1], Some(items[2]), Some(items[3])),
                PackageTarget::from_str(items[4])
                    .or(Err(Error::InvalidPackageIdentTarget(value.to_string())))?,
            ),
            _ => return Err(Error::InvalidPackageIdentTarget(value.to_string())),
        };
        Ok(PackageIdentTarget::new(ident, target))
    }
}
