// Copyright 2024 Matthew P. Dargan. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

#![warn(clippy::pedantic)]
use chrono::{DateTime, Utc};
use scraper::{selectable::Selectable, Html, Selector};
use std::env;
use std::error::Error;
use std::process;

const URL: &str = "https://tcbscans.com";

fn main() -> Result<(), Box<dyn Error>> {
    let manga = env::args().nth(1).unwrap_or_else(|| {
        eprintln!("usage: manga-alert manga");
        process::exit(1);
    });
    let manga_chapter = format!("{}-chapter", manga.to_lowercase().replace(' ', "-"));
    let body = reqwest::blocking::get(URL)?.text()?;
    let doc = Html::parse_document(&body);
    let div_selector = Selector::parse("div.flex.flex-col.gap-3")?;
    let a_selector = Selector::parse("a")?;
    let time_ago_selector = Selector::parse("time-ago")?;
    let chapter = doc
        .select(&div_selector)
        .next()
        .unwrap()
        .child_elements()
        .map(|e| {
            let chapter = e
                .select(&a_selector)
                .next()
                .unwrap()
                .value()
                .attr("href")
                .unwrap();
            let date_time = e
                .select(&time_ago_selector)
                .next()
                .unwrap()
                .value()
                .attr("datetime")
                .unwrap();
            (chapter, date_time)
        })
        .filter(|(ch, _)| ch.contains(&manga_chapter))
        .filter_map(|(ch, dt)| {
            let date_time = DateTime::parse_from_rfc3339(dt).ok()?;
            let now = Utc::now()
                .date_naive()
                .and_hms_opt(0, 0, 0)
                .unwrap()
                .and_utc();
            if date_time > now {
                Some(format!("{URL}{ch}"))
            } else {
                None
            }
        })
        .collect::<Vec<String>>();
    if let Some(ch) = chapter.first() {
        println!("New manga chapter: {ch}");
    }
    Ok(())
}
