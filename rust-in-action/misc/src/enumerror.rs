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

fn main() -> Result<(), UpstreamError> {
    let _f = File::open("invisible.txt").map_err(UpstreamError::IO)?;

    let _localhost: Ipv6Addr = "::1".parse().map_err(UpstreamError::Parsing)?;

    Ok(())
}
