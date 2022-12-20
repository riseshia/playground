use lambda_runtime::{service_fn, LambdaEvent, Error};
use serde_json::{json, Value};
use serde::{Deserialize, Serialize};

#[tokio::main]
async fn main() -> Result<(), Error> {
    let func = service_fn(func);
    lambda_runtime::run(func).await?;
    Ok(())
}

async fn func(request: LambdaEvent<Request>) -> Result<Value, Error> {
    let (request, _context) = request.into_parts();

    Ok(json!({ "message": format!("Hello, {}!", request.raw_path) }))
}

#[derive(Deserialize, Serialize)]
struct QueryParams {
    user_id: String,
    channel_id: String,
    command: String,
    response_url: String,
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
struct Request {
    #[serde(alias = "rawPath")]
    raw_path: String,
    headers: RequestHeader,
    body: QueryParams,
    #[serde(default)]
    #[serde(alias = "isBase64Encoded")]
    is_base64_encoded: bool,
    #[serde(default)]
    #[serde(alias = "skipRequestVerify")]
    skip_request_verify: bool,
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
struct RequestHeader {
    #[serde(alias = "x-slack-signature")]
    x_slack_signature: String,
    #[serde(alias = "x-slack-request-timestamp")]
    x_slack_request_timestamp: i32,
}

impl Default for RequestHeader {
    fn default() -> Self {
        Self {
            x_slack_signature: "".to_owned(),
            x_slack_request_timestamp: 0,
        }
    }
}

#[tokio::test]
async fn test_handle_command() {
    let request_body = QueryParams {
        user_id: "U11111111".to_owned(),
        channel_id: "C11111111".to_owned(),
        command: "/some-command".to_owned(),
        response_url: "https://hooks.slack.com/commands/1234/5678".to_owned(),
    };

    let request = Request {
        raw_path: "/".to_owned(),
        body: request_body,
        headers: RequestHeader {
            x_slack_signature: "".to_owned(),
            x_slack_request_timestamp: 0
        },
        is_base64_encoded: false,
        skip_request_verify: true
    };

    let context = lambda_runtime::Context::default();
    let event = lambda_runtime::LambdaEvent::new(request, context);

    let result = func(event).await.expect("failed to handle event");
    assert_eq!(result, json!({
        "message": "Hello, /!"
    }));
}
