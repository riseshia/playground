use lambda_runtime::{service_fn, Error};

use sam_lambda_rust::func;

#[tokio::main]
async fn main() -> Result<(), Error> {
    let func = service_fn(func);
    lambda_runtime::run(func).await?;
    Ok(())
}

#[tokio::test]
async fn test_handle_command() {
    use serde_json::json;
    use sam_lambda_rust::{Request, QueryParams, RequestHeader};

    let request_body = QueryParams {
        user_id: "U11111111".to_owned(),
        channel_id: "C11111111".to_owned(),
        command: "/some-command".to_owned(),
        response_url: "https://hooks.slack.com/commands/1234/5678".to_owned(),
    };

    let request = Request {
        raw_path: "/".to_owned(),
        body: request_body,
        headers: RequestHeader::default(),
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
