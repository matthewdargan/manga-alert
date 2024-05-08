// Copyright 2024 Matthew P. Dargan. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

use std::error::Error;

fn main() -> Result<(), Box<dyn Error>> {
    let body =
        reqwest::blocking::get("https://tcbscans-manga.com/?s=one+piece&post_type=wp-manga")?
            .text()?;
    println!("{:?}", body);
    Ok(())
}
