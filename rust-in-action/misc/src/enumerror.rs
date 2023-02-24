use std::io;
use std::fmt;
use std::net;
use std::fs::File;
use std::net::Ipv6Addr;


#[derive(Debug)]
enum UpstreamError {
    IO(io::Error),
    Parsing(net::AddrParseError),
}

impl fmt::Display for UpstreamError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{:?}", self)
    }
}

impl std::error::Error for UpstreamError {}

impl From<io::Error> for UpstreamError {
    fn from(error: io::Error) -> Self {
        UpstreamError::IO(error)
    }
}

impl From<net::AddrParseError> for UpstreamError {
    fn from(error: net::AddrParseError) -> Self {
        UpstreamError::Parsing(error)
    }
}

fn main() -> Result<(), UpstreamError> {
    let _f = File::open("invisible.txt")?;

    let _localhost: Ipv6Addr = "::1".parse()?;

    Ok(())
}
