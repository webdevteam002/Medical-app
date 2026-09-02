# Team 3 — Content workspace

Raw and polished content lives here **before** upload to the system via admin panel.

## Structure

```text
content/
├── qbanks/           # CSV files per year/subject
├── materials/        # PDFs organized by year/subject
├── images/           # Question diagrams (WebP/PNG)
└── content-map.csv   # Master index (copy from docs/templates/)
```

## Workflow

1. Polish content offline (see `docs/CONTENT_GUIDE.md`)
2. Set `status` to `READY` in content-map.csv
3. Upload via admin panel (Team 2) or batch script (Team 1)
4. Spot-check in app → set `PUBLISHED`

## Owner

**Team 3** — content + design polish

See [docs/TEAM_SPLIT.md](../docs/TEAM_SPLIT.md)
