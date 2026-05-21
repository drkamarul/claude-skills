# Quarto Figures – Extended Reference

Source: https://quarto.org/docs/authoring/figures.html

## Figure Basics

A figure is created when a captioned image appears alone in a paragraph:

```markdown
![Elephant](elephant.png)
```

For HTML: displays inline. For PDF: auto-numbered. For Word: captioned image.

## Sizing

```markdown
![](img.png){width=300}        # pixels
![](img.png){width=80%}        # percentage of container
![](img.png){width=4in}        # inches
![](img.png){height=2in}       # height (width auto-calculated)
```

## Alignment

```markdown
![Caption](img.png){fig-align="left"}
![Caption](img.png){fig-align="center"}   # default
![Caption](img.png){fig-align="right"}
```

Note: captions are always left-aligned regardless.

## Alt Text

```markdown
![](img.png){fig-alt="A bar chart showing prevalence by district."}
```

Title and alt text can differ:

```markdown
![Caption](img.png "Tooltip title"){fig-alt="Screen reader text."}
```

## Linked Figures

```markdown
[![Elephant](elephant.png)](https://en.wikipedia.org/wiki/Elephant)
```

Still treated as a captioned figure in output.

## Multiformat Images

Omit extension to auto-select by output format:

```markdown
![](figure)
```

- Default → looks for `figure.png`
- PDF → looks for `figure.pdf`

Customize:

```yaml
format:
  html:
    default-image-extension: svg
  pdf:
    default-image-extension: tex
```

## Lightbox (HTML only)

```markdown
![An elephant](elephant.png){.lightbox}
```

Clicking the image opens a larger version. Enable globally:

```yaml
lightbox: true
```

## Combining Multiple Options

```markdown
![](img.png){fig-alt="Chart." fig-align="left" width=20%}
```

## Cross References

Label must start with `fig-`:

```markdown
![An Elephant](elephant.png){#fig-elephant}

This is illustrated in @fig-elephant.
```

For code chunks:

````
```{r}
#| label: fig-line-plot
#| fig-cap: "A line plot"

plot(1:10)
```

For a line plot, see @fig-line-plot.
````

## Subfigures

````
```{r}
#| label: fig-two-plots
#| fig-cap: "Two plots"
#| fig-subcap:
#|   - "First plot"
#|   - "Second plot"
#| layout-ncol: 2

plot(1:10)
plot(10:1)
```

See @fig-two-plots-1 and @fig-two-plots-2.
````

## Multiple Rows Layout

```markdown
::: {layout-nrow=2}
![](img1.png)

![](img2.png)

![](img3.png)

![](img4.png)
:::
```

## Custom Layout Grid

```markdown
::: {layout="[[1,1], [1]]"}
![](img1.png)
![](img2.png)
![](img3.png)
:::
```

Numbers are relative widths per row.

## Figure Divs

Explicit figure block:

```markdown
::: {#fig-elephant}
![](elephant.png)

An elephant.
:::
```

## LaTeX / PDF Figure Options

```yaml
fig-pos: "H"          # position: H=here, t=top, b=bottom
fig-env: "figure*"    # LaTeX environment
```

Short captions for List of Figures:

```markdown
![Long full caption.](img.png){fig-scap="Short caption"}
```

## Vertical Alignment in Panels

```markdown
::: {layout="[1,1]" layout-valign="bottom"}
![](img1.png)
![](img2.png)
:::
```

## Caption Location

```yaml
fig-cap-location: bottom   # default
fig-cap-location: top
fig-cap-location: margin
```

## Computation Layout with Subcaptions

````
```{r}
#| label: fig-mpg
#| fig-cap: "City and highway mileage for 38 popular models"
#| fig-subcap:
#|   - "Coloured by cylinders"
#|   - "Coloured by engine displacement"
#| layout-ncol: 2
#| column: page

ggplot(mpg, aes(x = hwy, y = cty, color = cyl)) +
  geom_point(alpha = 0.5, size = 2) +
  scale_color_viridis_c() +
  theme_minimal()

ggplot(mpg, aes(x = hwy, y = cty, color = displ)) +
  geom_point(alpha = 0.5, size = 2) +
  scale_color_viridis_c(option = "E") +
  theme_minimal()
```

The plots in @fig-mpg show the relationship.
In @fig-mpg-1 points are colored by cylinders,
while @fig-mpg-2 uses engine displacement.
````
