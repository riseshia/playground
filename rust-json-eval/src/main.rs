use serde::{Deserialize, Serialize};
// use serde_json::Result;
use std::path::{Path, PathBuf};

use jrsonnet_evaluator::{error::LocError, EvaluationState, FileImportResolver};

pub fn evaluate_from_file(path: &Path) -> Result<String, String> {
    let state = EvaluationState::default();
    state.with_stdlib();
    state.set_import_resolver(Box::new(FileImportResolver::default()));

    match evaluate(path, &state) {
        Ok(val) => Ok(val),
        Err(err) => Err(state.stringify_err(&err)),
    }
}

#[derive(Serialize, Deserialize, Debug)]
struct Person {
    name: String,
    age: u8,
    phones: Vec<String>,
}

fn evaluate(path: &Path, state: &EvaluationState) -> Result<String, LocError> {
    let val = state.import(state.resolve_file(&PathBuf::new(), &opts.input.input)?)?
    let result = state.manifest(val)?;
    Ok(result.to_string())
}

fn main() -> Result<(), String> {
    let result = evaluate_from_file(&PathBuf::from("example.jsonnet"))?;

    let person = serde_json::from_str::<Person>(&result).map_err(|e| e.to_string())?;

    println!("{:?}", person);

    Ok(())
}
