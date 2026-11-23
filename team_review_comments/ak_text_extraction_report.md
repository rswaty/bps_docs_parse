# Alaska text extraction: changes and remaining recommendations

23 November 2026. Items 1–3 from the Alaska review are in the extractor and in `tables_AK/text_df.csv`. Items 4–7 are not implemented.

Source of the review: `AK_BPS_SHreview comments.docx` and `ak_parsed_doc_review_1Jun2026_kb.xlsx`. The text extract is the Python block in `parse_in_python_r_AK.qmd`. It reads `no_tables_AK/` and writes `tables_AK/text_df.csv`.

## What changed

### 1. Section boundaries

A field now ends at the next stored heading or at one of these headings:

- BpS Dominant and Indicator Species
- Fire Frequency
- Fire Frequency Results
- Succession Classes
- Model Parameters

Headings match after case-folding and stripping a trailing period or colon.

Checked against the previous table, 84 models:

| Field | Bleed before | Bleed after | Characters removed (min / median / max) |
|---|---:|---:|---|
| Vegetation Description | 84 included the indicator-species caption | 0 | 35 / 131 / 131 |
| Disturbance Description | 83 included the fire-interval caption | 0 | 23 / 365 / 365 |
| Comments | 84 included Succession Classes | 0 | 772 / 1,333 / 7,261 |

`16200` uses the heading “Fire Frequency Results.” That caption is gone, and the disturbance text still ends with the peatland sentence. On `16050`, the firebreak paragraph is still in Disturbance Description, and the fire-frequency caption is not.

Every other text field is unchanged, including Scale, Geographic Range, and the other narrative fields. Vegetation, disturbance, and comments text is the previous text with the trailing block removed. Nothing in front of those headings was cut.

### 2. Description reviewers

New column: `Description Reviewers`.

It is the `Reviewer:` or `Reviewers:` line above Vegetation Type. It is not the Reviewers column in `tables_AK/modelers.csv`.

Filled for 68 of 84 models. The other 16 documents do not have that header line. Their modeler-table reviewers, when present, are unchanged. `16760` is one of the 16: the modeler table lists Tom DeMeo and Tina Boucher, and there is no header line.

Examples of the two lists disagreeing, which is why they stay separate:

| Model | Header line (`Description Reviewers`) | Modeler-table reviewers |
|---|---|---|
| 16141 | Janet Fryer and Blaine T. Spellman | Tom Paragi |
| 16281 | Robin Innes, Blaine Spellman | Lisa Saperstein, Stuart Chapin |
| 16050 | Phillip Barber, Janet Fryer, and Beth Schulz | Will Putnam |

Sentences in the body that start with “Reviewer” and have no colon were left in Comments. `16160` and `16790` have that kind of sentence.

### 3. Bibliographies on 16281 and 16282

Both documents head the bibliography “References.” with a period. That now matches References.

References was empty for both and is now 5,326 characters, starting with the Comer et al. citation and including the FEIS tundra URL. That URL is no longer inside Comments. No other model’s References field changed.

## Still to decide

Stopping Comments at Succession Classes also dropped two blocks that were only stored because of the bleed: succession-class narratives, and the optional-disturbance labels on 18 models. Both are still in the Word documents. They are not in `text_df.csv`.

### 4. Succession-class prose

Class species are already in `tables_AK/sclass_indicators.csv`, and the sample review found those rows correct. The class name, description, and tree-size line are not in their own Alaska table. The CONUS `scls_descriptions` table has no Alaska models.

Leave the prose out of Comments. Add an Alaska class-description table only if this database should hold the same class narrative CONUS already has. If SyncroSim remains the source for that prose, do not parse it from Word.

### 5. Optional disturbances

Eighteen models have an “Optional Disturbances” block in the Word document (flooding, avalanche, thermokarst, storm surge, ice scour, sand deposition, soil disturbance, and similar). Those names were inside Comments and are not anymore. They were never in `fire_frequency.csv`, which only has Replacement, Mixed, Surface, and All Fires. That fire table matched the sample.

Parse the names from the Word documents into a small table if they need to be queryable. The rates are not in that block.

### 6. Fire minimum and maximum

All 336 Alaska fire rows still have empty `min_fi` and `max_fi`. About 570 of 3,604 CONUS rows have values in those columns, so the parser reads them when the cells are filled. Check two or three Alaska Word fire tables. If the cells are empty, keep the nulls.

### 7. Formatting and file metadata

Left as they are.

- Italics, bullet glyphs, and blank lines are presentation. Species names and list items are in the text.
- Curly quotes in the CSV are UTF-8. Odd characters in Excel come from opening the file as Windows-1252.
- Trailing spaces and non-breaking spaces are already normalized. Several “False” cells in the review sheet were that difference.
- Word core properties (creator, last modified, revision, created, modified) are still null on all 84 documents. They are file metadata, not BpS content.
- Empty sections such as Geographic Range and Scale on `16230` are empty in the document.
