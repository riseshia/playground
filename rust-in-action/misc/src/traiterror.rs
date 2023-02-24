use std::fs::File;
use std::error::Error;
use std::net::Ipv6Addr;

fn main() -> Result<(), Box<dyn Error>> {
    let _f = File::open("invisible.txt")?;

    let _localhost: Ipv6Addr = "::1".parse()?;

    Ok(())
}
