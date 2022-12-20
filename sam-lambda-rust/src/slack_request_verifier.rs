use hmac::{Hmac, Mac};
use sha2::Sha256;

pub struct Request {
    body: String,
    signature: String,
    timestamp: i32,
}

type HmacSha256 = Hmac<Sha256>;

pub fn verify_request(request: Request, signing_secret: String) -> bool {
    let basestring = format!("v0:{}:{}", request.timestamp, request.body);

    let mut hmac = HmacSha256::new_from_slice(signing_secret.as_bytes()).unwrap();

    hmac.update(basestring.as_bytes());

    let result = hmac.finalize().into_bytes();
    let sig = format!("v0={}", hex::encode(result.as_slice()));

    sig == request.signature
}

#[cfg(test)]
mod tests {
    use crate::{Request, verify_request};

    #[test]
    fn test_verify_request() {
        let request = Request {
            body: "token=xyzz0WbapA4vBCDEFasx0q6G&team_id=T1DC2JH3J&team_domain=testteamnow&channel_id=G8PSS9T3V&channel_name=foobar&user_id=U2CERLKJA&user_name=roadrunner&command=%2Fwebhook-collect&text=&response_url=https%3A%2F%2Fhooks.slack.com%2Fcommands%2FT1DC2JH3J%2F397700885554%2F96rGlfmibIGlgcZRskXaIFfN&trigger_id=398738663015.47445629121.803a0bc887a14d10d2c447fce8b6703c".to_string(),
            signature: "v0=a2114d57b48eac39b9ad189dd8316235a7b4a8d21a10bd27519666489c69b503".to_string(),
            timestamp: 1531420618,
        };

        let slack_signing_secret = "8f742231b10e8888abcd99yyyzzz85a5";

        assert!(verify_request(request, slack_signing_secret.to_string()))
    }
}
