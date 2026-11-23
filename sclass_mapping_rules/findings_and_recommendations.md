---
output:
  word_document: default
  html_document: default
---
# Succession class mapping rules: findings and recommendations

Reviewed 23 November 2026. Nothing in this note was loaded into the database, and no rule values were changed.

Files reviewed:

- `LF_CONUS_SuccessionClassMappingRules_09262023_2.xls` — created 21 March 2019 by Kori Blankenship, last saved 26 September 2023 by Paul Bourget
- `Succession_Class_Mapping_Rules_Readme_2019.pdf` — October 2019

The workbook has six sheets: `NONREFERENCE_RULES`, `REFERENCE_RULES`, `BPS_Code_LUT`, `Leaf_form_LUT`, `VegComposition_LUT`, and `change log & notes`. No script in this project reads either file.

The link below uses `REFERENCE_RULES` only. `NONREFERENCE_RULES` is left out for now.

Compared with the current national database: `bps_models` (901 models), `scls_descriptions` (819 models), `sclass_species`, `ref_con_long`, and `deterministic`. Alaska was left out of the comparison on purpose. This workbook has no Alaska reference rules.

## What checks out

Reference rules cover 827 models. Every model has a full herb, shrub, and tree height grid, and no cover cell is blank.

Eight of those models are sparse systems: `10010`, `10020`, `10030`, `10040`, `10060`, `10070`, `13410`, and `14980`. Every cell is Sparse. They have no description document. That matches the readme.

The other 819 model ids are exactly the 819 models in `scls_descriptions`. For 817 of them, the class letters used in the rules are the same letters used in the descriptions.

`BPS_Code_LUT` contains the same 827 models. Its old-code to new-code changes match the remap notes in the change log, including the split of `10800` into `10803` and `10804`.

## The readme does not describe this workbook

The PDF is the October 2019 instructions. The change log runs through 26 September 2023. On the reference sheet, the readme treats Not Possible (NP) as a succession class in the grid. In the workbook, NP is only in the Additional Rules notes. The cover cells still hold a mappable class. There are 246 notes that say “height NP”. The readme also does not mention the 2022–2023 reference-rule edits below.

## Rules that are not mutually exclusive

`13653_41` has three tree rows for 25–50 m and three for >50 m. The Leaf Form column is blank on all six, so one lifeform and height matches all three rows. The cover cells say `D mix`, `D brdlf`, and `E con`. The >50 m rows are also marked “height NP” while still assigning D or E.

The Word document has the same stacked rows. The change log (4 May 2022) says class E was added to this model. It was added as a third overlapping row, not as a Leaf Form split. A unique key on model, lifeform, leaf form, composition, height, and cover cannot be enforced until that is resolved.

## Six models were updated in the workbook and not in the Word grids

These match the 2023 change log. The lifeform grids in the description documents still have the older rules. For the other models, the class pattern in the workbook matches the document grid column for column.

- `10290_2_3_4_5_6_7_12` (30 May 2023). Rules split broadleaf and mixed leaf form. Conifer above 5 m is Uncharacteristic Native. The document maps those heights to C, D, or E with no leaf-form split.
- `10390_1_2_3_7` and `10420_1_7` (30 May 2023). D and E now start at 25 m. The documents still put the older classes on the 25–50 m row. The log says trees taller than 50 m are rarely mapped, so the old threshold left the late classes unmapped. The log text says “E and E” where it means D and E.
- `11792_29_30` (30 May 2023) and `13620_41_50` (15 August 2023). Rules map class E. The document grids are still all D on those rows.
- `13820_55_58` (15 August 2023). D and E moved from shrubs onto trees. The document still puts D and E on the shrub rows.

## Two reference classes cannot be mapped

Here the workbook matches the Word lifeform grid, and both disagree with the written class and the reference percent.

- `14490_58_60` class E is late closed (`Late1:CLS`) and 3% of the reference condition. Neither the grid nor the rules ever assign E. Closed trees at 25 m and taller are Uncharacteristic Native.
- `14710_41_50` class D is late closed (`Late1:CLS`) and 17% of the reference condition. Neither the grid nor the rules ever assign D. Trees at 25 m and taller are Uncharacteristic Native. `ref_con_long` also has a class E row for this model with percent `NA`. The descriptions do not include E.

## Crosswalk zones disagree with five model ids

The zone list inside the model id is not the zone list in `BPS_Code_LUT`.

| Model id | Zones in the id with no LUT row |
| --- | --- |
| `10220_2_3_6_7` | 6 |
| `10431_2_3_6_7` | 2 and 3. On 1 June 2020 the log renamed `10431_6_7` to this id. Zones 2 and 3 were never added to the crosswalk. The LUT rows that do exist are for zones 6 and 7 only. |
| `10802_21_22_28` | 28 |
| `13030_61_63_64_65_66` | 66 |
| `13622_41_50` | 50. The notes already say zone 50 was not in the pre-remap crosswalk. The LUT has zone 41 only. |

The new-model-plus-zone key is repeated where several old models collapsed into one new model:

- `10810_27_33`, zone 27 (old codes `10811` and `10812`)
- `11250_20_29_30_31_33`, zone 31 (old codes `10800` and `11250`)
- `13022_41_50_51`, zones 41, 50, and 51 (old codes `13021` and `13022`)

`10040` zone 13 is an exact duplicate row.

`BPS_MODEL_0` is not a stable key. Zones 1–9 are zero-padded text (331 cells). Zones 10 and above are numbers (1,451 cells).

## Cover breaks differ from the description documents

Workbook bins are `0-9`, `10-19`, … `90-100`. The BpS documents use `0-10`, `11-20`, … `91-100`. The class letters line up column by column for the models that were not edited in 2023. On 4,381 rule rows, across 721 models, two neighboring cover columns have different classes. Cover of 10, 20, 30, 40, 50, 60, 70, 80, or 90 falls in a different class under the two headings.

## Smaller lookup gaps

`VegComposition_LUT` lists both the 3000-series and the 7000-series vegetation types for lodgepole, sagebrush, oak, and maple-basswood. The Additional Rules notes cite only the 3000-series codes.

`Leaf_form_LUT` maps Sparsely Vegetated to `sparse`. No reference rule uses that value. The readme’s leaf forms are only broadleaf, conifer, and mixed. The reference rules use leaf form only on trees.

## Recommendation: how to link the rules to the database

Join on the model id and the class letter. Do not join on the 5-digit BpS code. One hundred fifty-four codes have more than one model, and the rules differ by model.

`REFERENCE_RULES.BpS Model Code` is already `bps_models.bps_model_id` for the 819 modeled rules. Each cover cell is a class. That letter is:

- `scls_descriptions.ref_label`
- `sclass_species.class`
- `ref_con_long.ref_label`

The structural stage (`Early1:ALL`, `Mid1:CLS`, and the rest) is not in the workbook. Reach it only through the description:

`rule cell → ref_label → scls_descriptions.state_class_id → deterministic.state_class_source / state_class_to`

### Store the reference rules in two tables

The sheet is wide: ten cover columns, and the class is the cell value. The database needs one class assignment per cover bin. Keep the spreadsheet row as the parent so the Additional Rules note is stored once and so the `13653_41` duplicates can be kept.

`sclass_rule`, one row per spreadsheet row:

- `source_row` — spreadsheet row number
- `bps_code` — the 5-digit code
- `bps_model_id`
- `lifeform`, `leaf_form`, `composition`, `height_class`
- `additional_rule`

`sclass_rule_cell`, one row per cover column:

- `source_row`
- `cover_class` — the header as stored (`0-9`, `10-19`, … `90-100`)
- `cover_min`, `cover_max`
- `sclass_raw` — the cell text, including `D mix` and `E brdlf`
- `ref_label` — letter only: `A`–`E`, `UN`, or `Sparse`
- `label_leaf_form` — leaf form parsed out of `sclass_raw` when the cell contains one

### Examples

These rows are from `REFERENCE_RULES`. `source_row` is the spreadsheet row number. Blank columns in the sheet stay blank here.

`sclass_rule` for three spreadsheet rows:

| source_row | bps_code | bps_model_id | lifeform | leaf_form | composition | height_class | additional_rule |
| ---: | ---: | --- | --- | --- | --- | --- | --- |
| 84 | 10080 | 10080_1_2_3_7 | Tree | | | 10-25 | |
| 617 | 10290 | 10290_2_3_4_5_6_7_12 | Tree | brdlf | | 10-25 | |
| 7431 | 13653 | 13653_41 | Tree | | | 25-50 | |
| 7432 | 13653 | 13653_41 | Tree | | | 25-50 | |

Row 84 unpivots to ten `sclass_rule_cell` rows. Cover 0–39% is class C. Cover 40–100% is class B. There is no leaf form in the cell, so `label_leaf_form` is blank.

| source_row | cover_class | cover_min | cover_max | sclass_raw | ref_label | label_leaf_form |
| ---: | --- | ---: | ---: | --- | --- | --- |
| 84 | 0-9 | 0 | 9 | C | C | |
| 84 | 10-19 | 10 | 19 | C | C | |
| 84 | 20-29 | 20 | 29 | C | C | |
| 84 | 30-39 | 30 | 39 | C | C | |
| 84 | 40-49 | 40 | 49 | B | B | |
| 84 | 50-59 | 50 | 59 | B | B | |
| 84 | 60-69 | 60 | 69 | B | B | |
| 84 | 70-79 | 70 | 79 | B | B | |
| 84 | 80-89 | 80 | 89 | B | B | |
| 84 | 90-100 | 90 | 100 | B | B | |

That letter joins to the description. For `10080_1_2_3_7`, `ref_label` C is `Mid1:OPN` and `ref_label` B is `Mid1:CLS`. The stage name is not stored on the rule cell.

Row 617 shows a compound cell. The sheet’s Leaf Form column is `brdlf`, and the same form is also written into the class. The first four cover bins are D and the last six are E. Two of the ten cells:

| source_row | cover_class | cover_min | cover_max | sclass_raw | ref_label | label_leaf_form |
| ---: | --- | ---: | ---: | --- | --- | --- |
| 617 | 0-9 | 0 | 9 | D brdlf | D | brdlf |
| 617 | 40-49 | 40 | 49 | E brdlf | E | brdlf |

Rows 7431 and 7432 are the overlapping `13653_41` case. Lifeform, leaf form, composition, and height are the same. Only `source_row` separates them. One cell from each row:

| source_row | cover_class | cover_min | cover_max | sclass_raw | ref_label | label_leaf_form |
| ---: | --- | ---: | ---: | --- | --- | --- |
| 7431 | 50-59 | 50 | 59 | D mix | D | mix |
| 7432 | 50-59 | 50 | 59 | D brdlf | D | brdlf |

Do not copy a leaf form parsed from the cell back into `leaf_form`. On most rows the Leaf Form column is already what makes the rule unique. On `13653_41` it is blank, and the leaf form exists only in the cell text. A unique constraint on model, lifeform, leaf form, composition, height, and cover will fail for that model. Keep `source_row` in the key, and report the overlap with a check query rather than dropping rows.

Store the workbook’s bins. Do not relabel them to the document breaks (`0-10`, `11-20`, …). That would change the rule wherever neighboring columns differ.

The eight sparse models cannot reference `bps_models`, because they have no row there. Keep them in `sclass_rule` with `bps_model_id` filled, and enforce the foreign key in a view of the 819 modeled rules rather than on the base table.

### Do not hang the other sheets off the model id

Leave `NONREFERENCE_RULES` out of this load.

`BPS_Code_LUT` is not the join between rules and descriptions. The model id already is. Store it as a zone table, one row per spreadsheet row, because several old models share one new model and zone. Use `BPS_MODEL_NEW` and `ZONE`. Do not use `BPS_MODEL` or `BPS_MODEL_0`. Do not invent the five missing zone rows listed above.

`Leaf_form_LUT` and `VegComposition_LUT` are inputs to the rules, not model attributes. Store them as vegetation-type lookups. Treat the composition lookup as the list of types. The Additional Rules notes are a partial copy and omit the 7000-series codes.

### Checks to keep after a load

- Class letters in the rules versus class letters in `scls_descriptions`. Expected exceptions: `14490_58_60` has description E and no rule cell; `14710_41_50` has description D and no rule cell.
- Reference percent greater than zero with no rule cell. Same two classes: E at 3%, D at 17%.
- Duplicate rule keys. Expected: `13653_41` tree 25–50 m and >50 m.
- Models in `bps_models` with no reference rules. Expected: the Alaska models, and no others.
- Rule models with no `bps_models` row. Expected: the eight sparse systems.

### What not to do

- Join on the 5-digit BpS code.
- Collapse `D mix` to `D` and discard the raw cell.
- Drop the overlapping `13653_41` rows to force a unique key.
- Load `NONREFERENCE_RULES` in this pass.
- Apply this CONUS workbook to Alaska models.
- Treat the missing rule cells for `14490_58_60` E and `14710_41_50` D as a failed load. Report them as reference classes that the rules cannot map.
