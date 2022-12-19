use lambda_runtime::{service_fn, LambdaEvent, Error};
use serde_json::{json, Value};

#[tokio::main]
async fn main() -> Result<(), Error> {
    let func = service_fn(func);
    lambda_runtime::run(func).await?;
    Ok(())
}

async fn func(event: LambdaEvent<Value>) -> Result<Value, Error> {
    let (event, _context) = event.into_parts();
    let first_name = event["firstName"].as_str().unwrap_or("world");

    Ok(json!({ "message": format!("Hello, {}!", first_name) }))
}

#[tokio::test]
async fn test_my_lambda_handler() {
  let input = serde_json::from_str("{\"command\": \"Say Hi!\"}").expect("failed to parse event");
  let context = lambda_runtime::Context::default();

  let event = lambda_runtime::LambdaEvent::new(input, context);

  func(event).await.expect("failed to handle event");
}
