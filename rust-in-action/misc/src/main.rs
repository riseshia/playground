use serde_json::{Value, json};
use std::io;
// use std::fmt;
use std::net;
use std::fs::File;
use std::net::Ipv6Addr;

#[derive(Debug)]
enum CommandError {
    AError,
    BError,
    NotFound
}

impl From<io::Error> for CommandError {
    fn from(_error: io::Error) -> Self {
        CommandError::AError
    }
}

impl From<net::AddrParseError> for CommandError {
    fn from(_error: net::AddrParseError) -> Self {
        CommandError::BError
    }
}

fn command_a_handler() -> Result<Value, CommandError> {
    let _f = File::open("invisible.txt")?;
    Ok(json!({}))
}

fn command_b_handler() -> Result<Value, CommandError> {
    let _localhost: Ipv6Addr = "::1".parse()?;
    Ok(json!({}))
}

fn main() {
    let command = "command_a";

    let res = match command {
        "command_a" => command_a_handler(),
        "command_b" => command_b_handler(),
        _ => Err(CommandError::NotFound)
    };

    match res {
        Ok(_msg) => json!({ "text": "hogehoge" }),
        Err(err) => json!({ "text": format!("{:?}", err) }),
    };
}
