use edit_distance::edit_distance;

// Find the most closest app name with given s1
fn main() {
    let mut apps = vec![
        "someapp-prod",
        "someapp-stg",
        "someapp-dev",
        "someapp-qa",
    ];

    let s1 = "app";

    apps.sort_by_key(|app| edit_distance(s1, app));
    let closest_app = apps.first().unwrap();
    println!("The closest app to '{}' is '{}'", s1, closest_app);
}
