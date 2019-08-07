// adapted from https://github.com/habitat-sh/builder/blob/master/components/builder-api/src/server/error.rs
// and https://github.com/habitat-sh/habitat/blob/master/components/core/src/error.rs

use std::{error,
          fmt,
          fs,
          io,
          result,
          string};

use reqwest;
use rusoto_core::RusotoError;
use rusoto_s3;
use serde_json;

use crate::{hab_core};

#[derive(Debug)]
pub enum Error {
    CreateBucketError(RusotoError<rusoto_s3::CreateBucketError>),
    HabitatCore(hab_core::Error),
    HttpClient(reqwest::Error),
    InnerError(io::IntoInnerError<io::BufWriter<fs::File>>),
    IO(io::Error),
    ListBuckets(RusotoError<rusoto_s3::ListBucketsError>),
    MultipartCompletion(RusotoError<rusoto_s3::CompleteMultipartUploadError>),
    MultipartUploadReq(RusotoError<rusoto_s3::CreateMultipartUploadError>),
    PackageDownload(RusotoError<rusoto_s3::GetObjectError>),
    PackageUpload(RusotoError<rusoto_s3::PutObjectError>),
    PartialUpload(RusotoError<rusoto_s3::UploadPartError>),
    SerdeJson(serde_json::Error),
    System,
    Utf8(string::FromUtf8Error),
}

pub type Result<T> = result::Result<T, Error>;

impl fmt::Display for Error {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        let msg = match *self {
            Error::CreateBucketError(ref e) => format!("{}", e),
            Error::HabitatCore(ref e) => format!("{}", e),
            Error::HttpClient(ref e) => format!("{}", e),
            Error::InnerError(ref e) => format!("{}", e.error()),
            Error::IO(ref e) => format!("{}", e),
            Error::ListBuckets(ref e) => format!("{}", e),
            Error::MultipartCompletion(ref e) => format!("{}", e),
            Error::MultipartUploadReq(ref e) => format!("{}", e),
            Error::PackageDownload(ref e) => format!("{}", e),
            Error::PackageUpload(ref e) => format!("{}", e),
            Error::PartialUpload(ref e) => format!("{}", e),
            Error::SerdeJson(ref e) => format!("{}", e),
            Error::System => "Internal error".to_string(),
            Error::Utf8(ref e) => format!("{}", e),
        };
        write!(f, "{}", msg)
    }
}

impl error::Error for Error {
    fn description(&self) -> &str {
        match *self {
            Error::CreateBucketError(ref err) => err.description(),
            Error::HabitatCore(ref err) => err.description(),
            Error::HttpClient(ref err) => err.description(),
            Error::InnerError(ref err) => err.error().description(),
            Error::IO(ref err) => err.description(),
            Error::ListBuckets(ref err) => err.description(),
            Error::MultipartCompletion(ref err) => err.description(),
            Error::MultipartUploadReq(ref err) => err.description(),
            Error::PackageDownload(ref err) => err.description(),
            Error::PackageUpload(ref err) => err.description(),
            Error::PartialUpload(ref err) => err.description(),
            Error::SerdeJson(ref err) => err.description(),
            Error::System => "Internal error",
            Error::Utf8(ref err) => err.description(),
        }
    }
}

// From handlers - these make application level error handling cleaner

impl From<hab_core::Error> for Error {
    fn from(err: hab_core::Error) -> Error { Error::HabitatCore(err) }
}

impl From<io::IntoInnerError<io::BufWriter<fs::File>>> for Error {
    fn from(err: io::IntoInnerError<io::BufWriter<fs::File>>) -> Error { Error::InnerError(err) }
}

impl From<io::Error> for Error {
    fn from(err: io::Error) -> Self { Error::IO(err) }
}

impl From<serde_json::Error> for Error {
    fn from(err: serde_json::Error) -> Error { Error::SerdeJson(err) }
}

impl From<string::FromUtf8Error> for Error {
    fn from(err: string::FromUtf8Error) -> Error { Error::Utf8(err) }
}
