use serde::{Deserialize, Serialize};
use std::path::Path;

#[derive(Serialize, Deserialize, Debug)]
struct Person {
    name: String,
    age: u8,
    phones: Vec<String>,
}

use rsjsonnet_lang::program::Value;

fn main() -> Result<(), String> {
    let source_path = Path::new("example.jsonnet");

    let mut session = rsjsonnet_front::Session::new();
    let name = session.program().str_interner().intern("name");
    let name_value = Value::string("shia");
    let name_thunk = session.program_mut().value_to_thunk(&name_value);
    session.program_mut().add_ext_var(name, &name_thunk);

    let Some(thunk) = session.load_real_file(source_path) else {
        return Err("Failed to load file".to_string());
    };

    let Some(value) = session.eval_value(&thunk) else {
        return Err("Failed to evaluate file".to_string());
    };

    let Some(json) = session.manifest_json(&value, true) else {
        return Err("Failed to evaluate file".to_string());
    };

    let person = serde_json::from_str::<Person>(&json).unwrap();
    println!("{:?}", person);

    Ok(())
}
