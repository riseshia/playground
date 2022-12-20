use lambda_runtime::{LambdaEvent, Error};
use serde::{Deserialize, Serialize};
use serde_json::{json, Value};

pub async fn func(request: LambdaEvent<Request>) -> Result<Value, Error> {
    let (request, _context) = request.into_parts();

    Ok(json!({ "message": format!("Hello, {}!", request.raw_path) }))
}

#[derive(Deserialize, Serialize)]
pub struct QueryParams {
    pub user_id: String,
    pub channel_id: String,
    pub command: String,
    pub response_url: String,
}

impl Default for QueryParams {
    fn default() -> Self {
        Self {
            user_id: "".to_owned(),
            channel_id: "".to_owned(),
            command: "".to_owned(),
            response_url: "".to_owned(),
        }
    }
}

#[derive(Deserialize, Serialize)]
pub struct Request {
    #[serde(alias = "rawPath")]
    pub raw_path: String,
    pub headers: RequestHeader,
    pub body: QueryParams,
    #[serde(default)]
    #[serde(alias = "isBase64Encoded")]
    pub is_base64_encoded: bool,
    #[serde(default)]
    #[serde(alias = "skipRequestVerify")]
    pub skip_request_verify: bool,
}

impl Default for Request {
    fn default() -> Self {
        Self {
            raw_path: "/".to_owned(),
            headers: RequestHeader::default(),
            body: QueryParams::default(),
            is_base64_encoded: false,
            skip_request_verify: false,
        }
    }
}

#[derive(Deserialize, Serialize)]
pub struct RequestHeader {
    #[serde(alias = "x-slack-signature")]
    pub x_slack_signature: String,
    #[serde(alias = "x-slack-request-timestamp")]
    pub x_slack_request_timestamp: i32,
}

impl Default for RequestHeader {
    fn default() -> Self {
        Self {
            x_slack_signature: "".to_owned(),
            x_slack_request_timestamp: 0,
        }
    }
}
