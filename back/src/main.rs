use std::collections::HashMap;

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

type RatingsById<'a> = HashMap<&'a str, Rating>;

#[derive(Debug)]
struct PartialEpisode<'a> {
    series_id: &'a str,
    season_number: Option<u32>,
    episode_number: Option<u32>,
}

type PartialEpisodesById<'a> = HashMap<&'a str, PartialEpisode<'a>>;

#[derive(Debug)]
struct Series<'a> {
    id: &'a str,
    primary_title: &'a str,
    original_title: &'a str,
    start_year: Option<u32>,
    end_year: Option<u32>,
    genres: Vec<&'a str>,
    rating: Option<&'a Rating>,
    episodes: Vec<Episode<'a>>,
}

type SeriesById<'a> = HashMap<&'a str, Series<'a>>;

#[derive(Debug)]
struct Episode<'a> {
    id: &'a str,
    primary_title: &'a str,
    original_title: &'a str,
    start_year: Option<u32>,
    end_year: Option<u32>,
    season_number: Option<u32>,
    episode_number: Option<u32>,
    rating: Option<&'a Rating>,
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

    let string = read("data/title.basics.tsv");
    let mut series_by_id: SeriesById = string
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
                    Series {
                        id: id,
                        primary_title: n(),
                        original_title: n(),
                        start_year: {
                            n();
                            n().parse().ok()
                        },
                        end_year: n().parse().ok(),
                        genres: {
                            n();
                            n().split(',').collect()
                        },
                        rating: ratings_by_id.get(&id),
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
                    if let Some(mut series) = series_by_id.get_mut(&partial_episode.series_id) {
                        series.episodes.push(Episode {
                            id,
                            primary_title: n(),
                            original_title: n(),
                            start_year: {
                                n();
                                n().parse().ok()
                            },
                            end_year: n().parse().ok(),
                            rating: ratings_by_id.get(&id),
                            season_number: partial_episode.season_number,
                            episode_number: partial_episode.episode_number,
                        });
                    }
                }
            }
            _ => {}
        }
    });

    let mut series = series_by_id
        .into_iter()
        .map(|(_, series)| series)
        .collect::<Vec<_>>();

    // We only care about the series which have episodes and all of them have a rating,
    // season_number, and episode_number.
    series.retain(|series| {
        !series.episodes.is_empty() && series.episodes.iter().all(|episode| {
            episode.rating.is_some() && episode.season_number.is_some()
                && episode.episode_number.is_some()
        })
    });

    eprintln!("series.len() = {:#?}", series.len());
}
