use std::fs;

use jsonwebtoken::jwk::JwkSet;
use jsonwebtoken::{encode, decode, Validation};
use jsonwebtoken::{Header, DecodingKey, EncodingKey};

use serde::{Deserialize, Serialize};
use serde_json::Value;

fn read_file(filepath: &str) -> String {
    fs::read_to_string(filepath)
        .unwrap_or_else(|_| panic!("Fail to read {}", &filepath))
}

fn read_jwks(filepath: &str) -> JwkSet {
    let file_body = fs::read_to_string(filepath)
        .unwrap_or_else(|_| panic!("Fail to read {}", &filepath));

    let v: JwkSet = serde_json::from_str(&file_body)
        .unwrap_or_else(|_| panic!("Fail to parse {}", &filepath));

    v
}

#[derive(Debug, Serialize, Deserialize)]
struct Claims {
   sub: String,
   company: String,
   exp: u32,
}

fn main() {
    let event = read_file("event.json");
    let public_key_jwks = read_jwks("ec-public.json");
    let private_key = include_bytes!("../ec-private.pem");

    dbg!(&event);
    dbg!(&public_key_jwks);
    dbg!(&private_key);

    let encoding_key = EncodingKey::from_ec_pem(private_key).unwrap();

    let my_claims = Claims {
        sub: "b@b.com".to_owned(),
        company: "ACME".to_owned(),
        exp: 1711007476,
    };

    let token = encode(
        &Header {
            kid: Some("sig-1710902060".to_owned()),
            alg: jsonwebtoken::Algorithm::ES256,
            ..Default::default()
        },
        &my_claims,
        &encoding_key,
    ).unwrap();

    dbg!(&token);

    let key = public_key_jwks.find("sig-1710902060").unwrap();
    dbg!(&key);

    let decoding_key = DecodingKey::from_jwk(key).unwrap();

    let token_message = decode::<Claims>(
        &token,
        &decoding_key,
        &Validation::new(jsonwebtoken::Algorithm::ES256)
    );

    dbg!(&token_message);
}
