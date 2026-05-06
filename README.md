# URL Parser — Excel Edition

A zero-dependency, browser-based tool that reads URLs from an Excel or CSV file
and instantly parses each one into its individual components.

## Features

- **Drag-and-drop** Excel (`.xlsx`, `.xls`) or CSV upload
- **Auto-detects** which column contains URLs — or let you specify it
- Parses every URL into: scheme, username, password, hostname, port, path, query string, individual query parameters, fragment
- **Sortable, filterable table** with pagination (50 rows/page)
- **Stats bar**: total, valid, invalid counts; unique schemes and hosts
- **Detail panel**: click any row for a full breakdown including a query-parameter table
- **Export**: copy to clipboard, download as CSV, or download as Excel
- Runs entirely in the browser — no data is uploaded anywhere

## Usage

1. Open `index.html` in any modern browser (Chrome, Firefox, Edge, Safari).
2. Drop your Excel file onto the upload area, or click **Browse file**.
3. Select the sheet and, optionally, specify the URL column header.
4. Click **Parse URLs**.

A sample file `sample_urls.xlsx` is included to try immediately.

## File format

Your Excel file needs at least one column of URLs. The column can have any header
name — the tool looks for a header containing "url" first, then scores each column
by how many cells look like URLs and picks the best match.

| ID | URL | Category | Notes |
|----|-----|----------|-------|
| 1  | https://example.com/path?q=1 | Web | … |
