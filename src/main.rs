// Copyright 2024 Matthew P. Dargan. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

use chrono::{NaiveDateTime, Utc};
use reqwest::Url;
use scraper::{selectable::Selectable, Html, Selector};
use std::env;
use std::error::Error;
use std::process;

fn main() -> Result<(), Box<dyn Error>> {
    let manga = env::args().nth(1).unwrap_or_else(|| {
        eprintln!("usage: manga-alert manga");
        process::exit(1);
    });
    let url = Url::parse_with_params(
        "https://tcbscans-manga.com",
        &[("s", manga), ("post_type", "wp-manga".to_string())],
    )?;
    let body = reqwest::blocking::get(url)?.text()?;
    let doc = Html::parse_document(&body);
    let div_selector = Selector::parse("div.tab-meta")?;
    let a_selector = Selector::parse("a")?;
    let post_on_selector = Selector::parse("div.post-on > span")?;
    let div = doc.select(&div_selector).next().unwrap();
    let chapter = div
        .select(&a_selector)
        .next()
        .unwrap()
        .value()
        .attr("href")
        .unwrap();
    let date_posted = div.select(&post_on_selector).next().unwrap().inner_html();
    let date = NaiveDateTime::parse_from_str(&date_posted, "%Y-%m-%d %H:%M:%S")?;
    let today = Utc::now().date_naive().and_hms_opt(0, 0, 0).unwrap();
    if date > today {
        println!("New manga chapter: {chapter}")
    }
    Ok(())
}
