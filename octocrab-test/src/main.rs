use octocrab::models::{InstallationToken, InstallationRepositories};
use octocrab::Octocrab;

#[tokio::main]
async fn main() -> octocrab::Result<()> {
    let app_id = read_env_var("GITHUB_APP_ID").parse::<u64>().unwrap().into();
    let app_private_key = read_env_var("GITHUB_APP_PRIVATE_KEY");

    let key = jsonwebtoken::EncodingKey::from_rsa_pem(app_private_key.as_bytes()).unwrap();

    let octocrab = Octocrab::builder().app(app_id, key).build()?;
    let installations = octocrab
        .apps()
        .installations()
        .send()
        .await
        .unwrap()
        .take_items();

    for ins in installations.iter() {
        let access: InstallationToken = octocrab
            .post(
                ins.access_tokens_url.as_ref().unwrap(),
                None::<&()>,
            )
            .await
            .unwrap();

        let octocrab = octocrab::OctocrabBuilder::new()
            .personal_token(access.token)
            .build()
            .unwrap();

        let repos: Result<InstallationRepositories, octocrab::Error> = octocrab
            .get("/installation/repositories", None::<&()>)
            .await;

        for repo in repos.unwrap().repositories.iter() {
            println!("{}", repo.name);
        }
    }
    Ok(())
}

fn read_env_var(var_name: &str) -> String {
    let err = format!("Missing env variable: {}", var_name);
    std::env::var(var_name).expect(&err)
}
