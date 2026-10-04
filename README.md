# Chile Public Procurement Analytics

End-to-end analytics engineering project built with official Chilean public procurement data from Mercado Público / ChileCompra.

The project focuses on transforming large, messy public procurement files into a reproducible analytical model for SQL and Power BI, with explicit data-quality checks, dimensional modeling, and documented assumptions.

## Current Scope

- **Sector:** Health
- **Period:** 2025, first semester (H1)
- **Source domain:** Purchase orders
- **Current analytical focus:** Trato Directo
- **Grains modeled:**
  - one row per purchase order
  - one row per purchase-order item

The repository is designed so additional procurement mechanisms and periods can be incorporated later using the same pipeline.

## Tech Stack

- Python
- SQL Server
- Power BI
- Git / GitHub

## Data Pipeline

```text
ChileCompra open-data files
        ↓
Python normalization
        ↓
SQL Server staging layer
        ↓
Clean typed layer
        ↓
Analytics star schema
        ↓
Reporting views / Power BI
```

The project preserves raw source values, performs reproducible transformations, and separates staging, clean, and analytical layers.

## Data Source & Credits

The source data come from **Dirección ChileCompra / Mercado Público**, through the official Chilean public-procurement open-data platform:

- **ChileCompra Open Data — Downloads:**  
  https://datos-abiertos.chilecompra.cl/descargas
- **ChileCompra / Mercado Público:**  
  https://www.mercadopublico.cl/
- **ChileCompra terms and data-use information:**  
  https://www.chilecompra.cl/terminos-y-condiciones-de-uso/

For the current version of this project, the downloaded report corresponds to **Health-sector purchase orders, 2025 H1**. The source archive contains purchase-order files separated by procurement mechanism; the current analytical model is built from the **Trato Directo** file.

### Important data note

ChileCompra distinguishes between **integral/raw data** extracted from Mercado Público and processed figures used for official reporting. Raw downloadable records may contain missing values, inconsistent labels, unusual monetary values, or records that ChileCompra excludes from its own processed statistics.

Accordingly:

- this project performs and documents its own cleaning and normalization;
- analytical totals in this repository may differ from official processed ChileCompra statistics;
- purchase-order amounts are interpreted as **purchase-order values**, not as confirmed payments or executed expenditure.

No source records are silently overwritten; raw values are preserved and analytical normalizations are documented separately.

## Data Quality Work

Examples of data-quality controls implemented in the project include:

- order-level and item-level spend reconciliation;
- validation of purchase-order grain;
- supplier, buyer, and product natural-key profiling;
- region normalization from inconsistent source labels;
- preservation and flagging of zero-amount and zero-quantity items;
- typed monetary and quantity fields with sufficient decimal precision;
- dimensional modeling with foreign-key validation.

## AI Assistance Disclosure

This project was developed by **Dídac Forno** with assistance from generative AI, primarily **OpenAI ChatGPT**.

AI assistance was used for tasks such as:

- brainstorming and architecture discussion;
- debugging and code review;
- SQL and Python implementation support;
- data-quality reasoning and validation design;
- analytical interpretation;
- documentation drafting and refinement.

All source selection, code execution, transformations, validation checks, modeling decisions, and final interpretations were reviewed and executed by the author. **No AI-generated synthetic data are used as source data in this project.**

## Disclaimer

This is an independent educational and portfolio project. It is not affiliated with or endorsed by Dirección ChileCompra, Mercado Público, the Government of Chile, or any supplier or public institution appearing in the data.

Third-party data remain subject to the terms and conditions of their respective source.
