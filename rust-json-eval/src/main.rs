use serde_json::{Result, Value};

fn parse_json() -> Value {
    let data = r#"
    {
        "name": "John Doe",
        "age": 43,
        "phones": [
            "+44 12345678",
            "+44 22222222"

        ]
    }"#;

    let v: Value = serde_json::from_str(data).expect("Invalid JSON str");

    println!("Please call {} at the number {}", v["name"], v["phones"][0]);

    match v["phones"].get(1) {
        Some(phone) => println!("The second phone number is: {}", phone),
        None => println!("There is no second phone number."),
    }

    v
}

fn main() -> Result<()> {
    let _json = parse_json();

    Ok(())
}
