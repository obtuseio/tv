extern crate serde;

#[macro_use]
extern crate serde_derive;

#[macro_use]
extern crate serde_json;

use std::collections::HashMap;
use std::io::{Read, Write};
use std::fs::File;

fn read(path: &str) -> String {
    let mut file = File::open(path).unwrap();
    let mut string = String::new();
    file.read_to_string(&mut string).unwrap();
    string
}

#[derive(Debug, Serialize)]
struct Rating {
    #[serde(rename = "a")] average: f64,
    #[serde(rename = "c")] count: u32,
}

type RatingsById<'a> = HashMap<&'a str, Rating>;

#[derive(Debug)]
struct PartialEpisode<'a> {
    show_id: &'a str,
    season_number: u32,
    episode_number: u32,
}

type PartialEpisodesById<'a> = HashMap<&'a str, PartialEpisode<'a>>;

#[derive(Debug, Serialize)]
struct Show<'a> {
    id: &'a str,
    #[serde(rename = "pt")] primary_title: &'a str,
    #[serde(rename = "ot")] original_title: &'a str,
    #[serde(rename = "sy")] start_year: u32,
    #[serde(rename = "ey")] end_year: Option<u32>,
    #[serde(rename = "g")] genres: Vec<&'a str>,
    #[serde(rename = "r")] rating: &'a Rating,
    #[serde(rename = "es")] episodes: Vec<Episode<'a>>,
}

type ShowsById<'a> = HashMap<&'a str, Show<'a>>;

#[derive(Debug, Serialize)]
struct Episode<'a> {
    id: &'a str,
    #[serde(rename = "pt")] primary_title: &'a str,
    #[serde(rename = "ot")] original_title: &'a str,
    #[serde(rename = "sy")] start_year: Option<u32>,
    #[serde(rename = "ey")] end_year: Option<u32>,
    #[serde(rename = "sn")] season_number: u32,
    #[serde(rename = "en")] episode_number: u32,
    #[serde(rename = "r")] rating: &'a Rating,
}

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
        .filter_map(|line| {
            let mut parts = line.trim().split('\t');
            let mut n = || parts.next().unwrap();
            Some((
                n(),
                PartialEpisode {
                    show_id: n(),
                    season_number: n().parse().ok()?,
                    episode_number: n().parse().ok()?,
                },
            ))
        })
        .collect();

    let string = read("data/title.basics.tsv");
    let mut shows_by_id: ShowsById = string
        .trim()
        .split('\n')
        .skip(1)
        .filter_map(|line| {
            let mut parts = line.trim().split('\t');
            let mut n = || parts.next().unwrap();
            let id = n();
            let type_ = n();
            match type_ {
                "tvSeries" => Some((
                    id,
                    Show {
                        id: id,
                        primary_title: n(),
                        original_title: n(),
                        start_year: {
                            n();
                            n().parse().ok()?
                        },
                        end_year: n().parse().ok(),
                        genres: {
                            n();
                            n().split(',').collect()
                        },
                        rating: ratings_by_id.get(&id)?,
                        episodes: Vec::new(),
                    },
                )),
                _ => None,
            }
        })
        .collect();

    string.trim().split('\n').skip(1).for_each(|line| {
        let mut parts = line.trim().split('\t');
        let mut n = || parts.next().unwrap();
        let id = n();
        let type_ = n();
        match type_ {
            "tvEpisode" => {
                if let &Some(partial_episode) = &partial_episodes_by_id.get(&id) {
                    if let Some(mut show) = shows_by_id.get_mut(&partial_episode.show_id) {
                        if let Some(rating) = ratings_by_id.get(&id) {
                            show.episodes.push(Episode {
                                id,
                                primary_title: n(),
                                original_title: n(),
                                start_year: {
                                    n();
                                    n().parse().ok()
                                },
                                end_year: n().parse().ok(),
                                rating,
                                season_number: partial_episode.season_number,
                                episode_number: partial_episode.episode_number,
                            });
                        }
                    }
                }
            }
            _ => {}
        }
    });

    let mut shows = shows_by_id
        .into_iter()
        .map(|(_, show)| show)
        .collect::<Vec<_>>();

    // We only care about the shows which have at least one episode.
    shows.retain(|show| !show.episodes.is_empty());

    shows.iter_mut().for_each(|show| {
        show.episodes
            .sort_by_key(|episode| (episode.season_number, episode.episode_number));
    });

    eprintln!("shows.len() = {:#?}", shows.len());

    let json = json!(
        shows
            .iter()
            .map(|s| json!({
                "id": s.id,
                "pt": s.primary_title,
                "sy": s.start_year,
                "ey": s.end_year,
                "r": {
                    "a": s.rating.average,
                    "c": s.rating.count,
                },
            }))
            .collect::<Vec<_>>()
    );

    let mut file = File::create("data/shows.json").unwrap();
    write!(&mut file, "{}", json).unwrap();

    std::fs::create_dir_all("data/shows").unwrap();
    for show in shows {
        let string = serde_json::to_string(&show).unwrap();
        let mut file = File::create(format!("data/shows/{}.json", show.id)).unwrap();
        file.write_all(string.as_bytes()).unwrap();
    }
}
