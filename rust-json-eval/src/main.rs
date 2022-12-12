use serde::{Deserialize, Serialize};
use serde_json::Result;

fn parse_json(data: String) -> Person {
    serde_json::from_str(&data).expect("Invalid JSON str")
}

#[derive(Serialize, Deserialize)]
struct Person {
    name: String,
    age: u8,
    phones: Vec<String>,
}

use jsonnet::JsonnetVm;

fn main() -> Result<()> {
    let data = r#"
    local obj = {
        name: "John Doe",
        age: 43,
        phones: [
            "+44 1234567",
            "+44 2345678"
        ]
    };

    obj"#;

    let mut vm = JsonnetVm::new();

    let output = vm.evaluate_snippet("example", data).unwrap();
    let person = parse_json(output.as_str().to_string());

    println!("Please call {} at the number {}", person.name, person.phones[0]);

    match person.phones.get(1) {
        Some(phone) => println!("The second phone number is: {}", phone),
        None => println!("There is no second phone number."),
    }

    Ok(())
}
