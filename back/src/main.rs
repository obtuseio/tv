use std::collections::BTreeMap;

fn read(path: &str) -> String {
    use std::fs::File;
    use std::io::Read;

    let mut file = File::open(path).unwrap();
    let mut string = String::new();
    file.read_to_string(&mut string).unwrap();
    string
}

#[derive(Debug)]
struct Rating {
    average: f32,
    count: u32,
}

type RatingsById<'a> = BTreeMap<&'a str, Rating>;

#[derive(Debug)]
struct PartialEpisode<'a> {
    series_id: &'a str,
    season_number: Option<u32>,
    episode_number: Option<u32>,
}

type PartialEpisodesById<'a> = BTreeMap<&'a str, PartialEpisode<'a>>;

fn main() {
    let string = read("data/title.ratings.tsv");
    let ratings_by_id: RatingsById = string
        .trim()
        .split('\n')
        .skip(1)
        .map(|line| {
            let mut parts = line.trim().split('\t');
            let mut n = || parts.next().unwrap();
            (
                n(),
                Rating {
                    average: n().parse().unwrap(),
                    count: n().parse().unwrap(),
                },
            )
        })
        .collect();

    let string = read("data/title.episode.tsv");
    let partial_episodes_by_id: PartialEpisodesById = string
        .trim()
        .split('\n')
        .skip(1)
        .map(|line| {
            let mut parts = line.trim().split('\t');
            let mut n = || parts.next().unwrap();
            (
                n(),
                PartialEpisode {
                    series_id: n(),
                    season_number: n().parse().ok(),
                    episode_number: n().parse().ok(),
                },
            )
        })
        .collect();
}
