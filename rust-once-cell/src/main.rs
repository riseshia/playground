use std::{cell::OnceCell, collections::HashMap};

#[derive(Debug)]
struct Client;

#[derive(Debug)]
struct Context {
    name: String,
    client: OnceCell<Client>,
}

impl Context {
    fn new(name: String) -> Self {
        Self {
            name,
            client: OnceCell::new(),
        }
    }

    fn client(&self) -> &Client {
        self.client.get_or_init(|| {
            println!("Creating a new client for {}", self.name);
            Client
        })
    }
}

#[derive(Debug)]
struct ContextWithoutOnceCell {
    name: String,
    client: Option<Client>,
}

impl ContextWithoutOnceCell {
    fn new(name: String) -> Self {
        Self { name, client: None }
    }

    fn client(&mut self) -> &Client {
        if self.client.is_some() {
            return self.client.as_ref().unwrap();
        }
        println!("Creating a new client for {}", self.name);
        self.client = Some(Client);
        self.client.as_ref().unwrap()
    }
}

#[derive(Debug)]
struct SecretClient;
impl SecretClient {
    fn new() -> Self {
        println!("Creating a new LambdaClient");
        Self
    }

    fn fetch_all(&self) -> HashMap<String, String> {
        let mut map = HashMap::new();
        map.insert("secret1".to_string(), "secret1".to_string());
        map.insert("secret2".to_string(), "secret2".to_string());
        map
    }
}

#[derive(Debug)]
struct ContextWithMultipleOnceCell {
    name: String,
    client: OnceCell<SecretClient>,
    secrets: OnceCell<HashMap<String, String>>,
}

impl ContextWithMultipleOnceCell {
    fn new(name: String) -> Self {
        Self {
            name,
            client: OnceCell::new(),
            secrets: OnceCell::new(),
        }
    }

    fn client(&self) -> &SecretClient {
        self.client.get_or_init(|| {
            println!("Creating a new client for {}", self.name);
            SecretClient::new()
        })
    }

    fn secrets(&self) -> &HashMap<String, String> {
        self.secrets.get_or_init(|| {
            println!("Fetching secrets");
            self.client().fetch_all()
        })
    }

    fn secret1(&self) -> &String {
        self.secrets().get("secret1").unwrap()
    }

    fn secret2(&self) -> &String {
        self.secrets().get("secret2").unwrap()
    }
}

fn main() {
    let context = Context::new("Alice".to_string());
    println!("Context: {:?}", context);
    println!("Client: {:?}", context.client());
    println!("Client: {:?}", context.client());

    let mut context2 = ContextWithoutOnceCell::new("Alice".to_string());
    println!("ContextWithoutOnceCell: {:?}", context2);
    println!("Client: {:?}", context2.client());
    println!("Client: {:?}", context.client());

    let context = ContextWithMultipleOnceCell::new("Alice".to_string());
    println!("Context: {:?}", context);
    println!("secret1: {:?}", context.secret1());
    println!("secret2: {:?}", context.secret2());
}
