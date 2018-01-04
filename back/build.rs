use std::path::Path;
use std::process::Command;

fn main() {
    std::fs::create_dir_all("data").unwrap();
    for name in &["basics", "episode", "ratings"] {
        let tsv = format!("data/title.{}.tsv", name);
        if !Path::new(&tsv).exists() {
            let gz = format!("{}.gz", tsv);
            let url = format!("https://datasets.imdbws.com/title.{}.tsv.gz", name);
            assert!(
                Command::new("curl")
                    .args(&["-s", "-L", "-o", &gz, &url])
                    .status()
                    .unwrap()
                    .success()
            );
            assert!(Command::new("gunzip").arg(gz).status().unwrap().success());
        }
    }
}
