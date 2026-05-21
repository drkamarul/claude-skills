---
name: shinyskill
description: >
  Build modern R Shiny applications using bslib for UI layout, theming,
  and components. Use this skill whenever the user asks to create, design,
  build, or improve a Shiny app, Shiny dashboard, or any interactive R web
  application. Also trigger when the user mentions bslib, shinydashboard
  replacement, Shiny UI layout, cards, value boxes, sidebars, navbars,
  Shiny theming, Bootswatch themes, or page_sidebar and page_navbar. Even
  if the user just says make me an app or build a dashboard in an R context,
  use this skill. Covers project structure, UI layout with bslib, theming,
  components, server logic patterns, and deployment considerations.
---

# Shiny App Builder Skill

Build modern R Shiny applications using `bslib` as the primary UI framework. All new Shiny apps should use `bslib` instead of legacy `shinydashboard` or raw `fluidPage()` unless the user specifically requests otherwise.

## Why bslib

`bslib` is the modern UI toolkit for Shiny, built on Bootstrap 5. It replaces older approaches (`shinydashboard`, `shinythemes`, raw Bootstrap 3) with a cleaner API, better theming, responsive layouts, and reusable components like cards, value boxes, and sidebars. It works in both Shiny apps and R Markdown documents.

## Project Structure

For any Shiny app, use this structure:

```
my-app/
├── app.R              # Single-file app (small apps)
├── R/                 # Helper functions, modules
│   ├── mod_overview.R
│   └── utils.R
├── www/               # Static assets (CSS, images, logos)
│   └── custom.css
└── data/              # Data files if needed
```

For larger apps, split into `ui.R`, `server.R`, and `global.R`. Encourage Shiny modules (`moduleServer()`) for any non-trivial app.

## Page Layouts

Choose the right page function based on the app's purpose:

### page_sidebar() — Dashboard with a single sidebar
Best for: apps with one main content area and a filter/control panel.

```r
library(shiny)
library(bslib)

ui <- page_sidebar(
  title = "My Dashboard",
  theme = bs_theme(bootswatch = "flatly"),
  sidebar = sidebar(
    title = "Controls",
    selectInput("var", "Variable", choices = names(mtcars)),
    sliderInput("bins", "Bins", min = 5, max = 50, value = 30)
  ),
  card(
    card_header("Main Plot"),
    card_body(plotOutput("main_plot")),
    full_screen = TRUE
  )
)
```

### page_navbar() — Multi-page app with top navigation
Best for: apps with multiple sections/pages.

```r
ui <- page_navbar(
  title = "Multi-Page App",
  theme = bs_theme(bootswatch = "cosmo"),
  nav_panel(
    title = "Overview",
    layout_columns(
      value_box("Metric 1", textOutput("val1"), showcase = icon("chart-line")),
      value_box("Metric 2", textOutput("val2"), showcase = icon("users")),
      value_box("Metric 3", textOutput("val3"), showcase = icon("check")),
      col_widths = c(4, 4, 4)
    ),
    card(
      card_header("Summary"),
      card_body(plotOutput("overview_plot")),
      full_screen = TRUE
    )
  ),
  nav_panel(
    title = "Details",
    layout_sidebar(
      sidebar = sidebar(
        selectInput("detail_var", "Select", choices = NULL)
      ),
      card(card_body(DT::DTOutput("detail_table")))
    )
  ),
  nav_panel(title = "About", markdown("## About this app\n\nDescription here."))
)
```

### page_fillable() — Full-height, no scrolling
Best for: map apps, single visualizations that should fill the viewport.

```r
ui <- page_fillable(
  theme = bs_theme(bootswatch = "darkly"),
  card(
    card_body(leaflet::leafletOutput("map", height = "100%")),
    full_screen = TRUE
  )
)
```

## Theming

### Bootswatch Themes
Apply any Bootswatch theme via `bs_theme(bootswatch = "theme_name")`. Popular choices for professional/academic dashboards: `flatly`, `cosmo`, `lux`, `minty`, `sandstone`, `journal`, `united`.

### Custom Colors and Fonts

```r
my_theme <- bs_theme(
  bg = "#FFFFFF",
  fg = "#333333",
  primary = "#0072B2",
  secondary = "#009E73",
  success = "#009E73",
  base_font = font_google("Source Sans Pro"),
  heading_font = font_google("Source Serif Pro"),
  code_font = font_google("Fira Code"),
  font_scale = 1.0
)
```

### Dark Mode

```r
dark_theme <- bs_theme(
  bg = "#1a1a2e",
  fg = "#EAEAEA",
  primary = "#E94560",
  base_font = font_google("Inter")
)
```

### Real-Time Theme Preview
During development, add `bs_themer()` inside the server function to interactively tweak the theme:

```r
server <- function(input, output, session) {
  bs_themer()
  # ... rest of server logic
}
```

Remove `bs_themer()` before deploying to production.

## Components

### Cards
Cards are the primary content containers. Use them for plots, tables, text, and any grouped content.

```r
card(
  card_header("Title"),
  card_body(
    plotOutput("my_plot")
  ),
  card_footer("Source: Dataset XYZ"),
  full_screen = TRUE,    # Allow expanding to full screen
  height = 400           # Optional fixed height
)
```

Card bodies scroll by default when content exceeds `max_height`. Combine `max_height` with `full_screen = TRUE` so users can expand if needed.

Multiple card bodies create separate scrollable sections:

```r
card(
  card_header("Two sections"),
  card_body(plotOutput("plot1")),
  card_body(DT::DTOutput("table1"))
)
```

### Value Boxes
Use value boxes for key metrics / KPIs at the top of dashboards.

```r
value_box(
  title = "Total Cases",
  value = textOutput("total_cases"),
  showcase = icon("virus"),
  theme = "primary"
)
```

Available themes: `"primary"`, `"secondary"`, `"success"`, `"danger"`, `"warning"`, `"info"`, or custom `value_box_theme()`.

### Sidebars
Sidebars hold controls and filters. They are collapsible by default.

```r
sidebar(
  title = "Filters",
  open = "desktop",     # Open on desktop, closed on mobile
  width = 300,
  selectInput("state", "State", choices = NULL),
  dateRangeInput("dates", "Date Range"),
  actionButton("go", "Apply", class = "btn-primary w-100")
)
```

### Accordions
Group related controls or content into collapsible panels:

```r
accordion(
  accordion_panel("Demographics", selectInput("age", "Age Group", choices = c("All", "0-17", "18-64", "65+"))),
  accordion_panel("Geography", selectInput("region", "Region", choices = NULL)),
  open = "Demographics"
)
```

## Multi-Column Layouts

### layout_columns() — Responsive column grid

```r
layout_columns(
  col_widths = c(4, 8),        # Bootstrap 12-column grid
  card(card_body("Narrow")),
  card(card_body("Wide"))
)
```

Responsive breakpoints:

```r
layout_columns(
  col_widths = breakpoints(
    sm = c(12, 12),   # Stack on small screens
    md = c(6, 6),     # Half-half on medium
    lg = c(4, 8)      # 1/3 + 2/3 on large
  ),
  card(...),
  card(...)
)
```

### layout_column_wrap() — Equal-width wrapping columns

```r
layout_column_wrap(
  width = 1/3,   # Each card takes 1/3 of the row
  value_box(...),
  value_box(...),
  value_box(...)
)
```

## Server Logic Patterns

### Reactive data flow

```r
server <- function(input, output, session) {
  # Reactive data filtered by inputs
  filtered_data <- reactive({
    df |>
      dplyr::filter(
        state %in% input$state,
        date >= input$dates[1],
        date <= input$dates[2]
      )
  })

  # Render outputs using filtered data
  output$main_plot <- renderPlot({
    filtered_data() |>
      ggplot2::ggplot(ggplot2::aes(x = date, y = cases)) +
      ggplot2::geom_line()
  })

  output$total_cases <- renderText({
    scales::comma(sum(filtered_data()$cases))
  })
}
```

### Dynamic UI updates

```r
server <- function(input, output, session) {
  observe({
    choices <- unique(data[[input$category]])
    updateSelectInput(session, "subcategory", choices = choices)
  })
}
```

### Shiny Modules Pattern
For reusable components:

```r
# R/mod_plot_card.R
plot_card_ui <- function(id, title = "Plot") {
  ns <- NS(id)
  card(
    card_header(title),
    card_body(plotOutput(ns("plot"))),
    full_screen = TRUE
  )
}

plot_card_server <- function(id, data, x_var, y_var) {
  moduleServer(id, function(input, output, session) {
    output$plot <- renderPlot({
      ggplot2::ggplot(data(), ggplot2::aes(.data[[x_var()]], .data[[y_var()]])) +
        ggplot2::geom_point()
    })
  })
}
```

## Common Packages to Pair with bslib Shiny Apps

- **DT** — Interactive tables (`DT::DTOutput`, `DT::renderDT`)
- **plotly** — Interactive plots (`plotly::plotlyOutput`, `plotly::renderPlotly`)
- **leaflet** — Interactive maps
- **echarts4r** — Rich charting library
- **reactable** — Another interactive table option
- **thematic** — Auto-theme ggplot2/lattice plots to match the bslib theme
- **shinyWidgets** — Extra input widgets
- **waiter** — Loading screens and spinners

## Auto-Theming ggplot2 with thematic

To make ggplot2 plots automatically match the bslib theme:

```r
library(thematic)
thematic_shiny()   # Call once, before runApp() or in global.R
```

## Deployment Checklist

Before deploying (to Posit Connect, shinyapps.io, or a server):

1. Remove `bs_themer()` from server function
2. Ensure all packages are listed or managed (e.g., `renv`)
3. Test on multiple screen sizes (bslib is responsive by default)
4. Set appropriate `options(shiny.maxRequestSize)` if file uploads are expected
5. Add error handling with `tryCatch()` or `validate(need(...))` for user-facing messages

## Quick-Start Template

When the user asks for a new Shiny app without specific requirements, start with this template and customize:

```r
library(shiny)
library(bslib)

ui <- page_sidebar(
  title = "App Title",
  theme = bs_theme(bootswatch = "flatly"),
  sidebar = sidebar(
    title = "Controls"
    # Add inputs here
  ),
  layout_columns(
    col_widths = c(4, 4, 4),
    value_box("Metric 1", "—", showcase = icon("chart-line")),
    value_box("Metric 2", "—", showcase = icon("users")),
    value_box("Metric 3", "—", showcase = icon("check"))
  ),
  card(
    card_header("Main Content"),
    card_body(
      "Replace with plotOutput(), DTOutput(), etc."
    ),
    full_screen = TRUE
  )
)

server <- function(input, output, session) {
  # Server logic here
}

shinyApp(ui, server)
```

## Key Principles

1. **Always use bslib** for new apps — not `shinydashboard` or raw `fluidPage()`.
2. **Cards everywhere** — wrap every output (plot, table, text block) in a `card()`.
3. **Value boxes for KPIs** — place them prominently at the top of dashboards.
4. **Responsive layouts** — use `layout_columns()` with `breakpoints()` for mobile-friendly designs.
5. **Theme early** — set `bs_theme()` at the start so the whole app is visually cohesive.
6. **Full-screen option** — add `full_screen = TRUE` to cards containing plots or tables.
7. **Sidebar for controls** — group all user inputs in a `sidebar()` for clean separation of controls and content.
8. **Modularize** — use Shiny modules for any component that repeats or any app with more than ~200 lines.
