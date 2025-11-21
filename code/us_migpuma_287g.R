library(tigris)
library(dplyr)
library(sf)
library(ggplot2)

work_path <- "~/Desktop/287g/"
data <- paste0(work_path, "data/")
output <- paste0(work_path, "output/final/")


# get data
migpuma_geo <- read_sf(paste0(data, "raw/ipums_migpuma_pwpuma_2010/ipums_migpuma_pwpuma_2010.shp")) %>%
  mutate(MIGPUMA = as.numeric(MIGPUMA), 
         State = tolower(State))
migpuma_geo = st_make_valid(migpuma_geo)
migpuma_geo <- migpuma_geo %>%
  filter(!(State %in% c("alaska", "hawaii")))

states <- states(2021)
states <- states %>%
  filter(!STUSPS %in% c("AK", "HI", "PR", "VI", "GU", "MP", "AS"))


# get treatment
treatment <- read.csv(paste0(data, "int/list_migpumas_treatment.csv")) %>%
  mutate(current_migpuma = as.numeric(current_migpuma))

# connect migpuma to treatment
migpuma_treated <- left_join(
  migpuma_geo,
  treatment,
  by = c("MIGPUMA" = "current_migpuma",
        "State" = "statefip")
)

migpuma_treated$always_treated_migpuma[is.na(migpuma_treated$always_treated_migpuma)] <- 0
migpuma_treated$ever_gain_exp_migpuma[is.na(migpuma_treated$ever_gain_exp_migpuma)] <- 0
migpuma_treated$ever_lost_exp_migpuma[is.na(migpuma_treated$ever_lost_exp_migpuma)] <- 0

migpuma_treated <- migpuma_treated %>%
  filter(!(State %in% c("alaska", "hawaii", "puerto rico")))



# data ready to plot
migpuma_plot <- migpuma_treated %>%
  mutate(
    treatment_group = case_when(
      always_treated_migpuma == 1                      ~ "Always treated",
      ever_gain_exp_migpuma == 1 & ever_lost_exp_migpuma == 0 ~ "Gain",
      ever_lost_exp_migpuma == 1 & ever_gain_exp_migpuma == 0 ~ "Lost",
      ever_gain_exp_migpuma == 1 & ever_lost_exp_migpuma == 1 ~ "Gain & Lost",
      TRUE ~ "None"
    )
  )

# fix coordinates
migpuma_plot <- st_transform(migpuma_plot, crs=3857)
states <- st_transform(states, crs=3857)
migpuma_geo <- migpuma_geo %>%
  filter(!(State %in% c("alaska", "hawaii", "puerto rico")))



# Ensure all 5 categories exist as factor levels
migpuma_plot <- migpuma_plot %>%
  mutate(
    treatment_group = factor(
      treatment_group,
      levels = c("Always treated", "Gain only", "Lost only", "Gain & Lost", "None")
    )
  )

ggplot() +
  geom_sf(
    data = migpuma_geo,
    fill = NA,
    color = "black",
    size = 0.05
  ) +
  geom_sf(
    data = migpuma_plot,
    aes(fill = treatment_group),
    color = NA,
    size = 0.05
  ) +
  geom_sf(
    data = states,
    fill = NA,
    color = "black",
    size = 0.3
  ) +
  
  # FORCE all 5 categories to appear in legend
  scale_fill_manual(
    values = c(
      "Always treated" = "gray90",
      "Gain only"      = "gray75",
      "Lost only"      = "gray60",
      "Gain & Lost"    = "gray20",
      "None"           = "white"
    ),
    limits = c("Always treated", "Gain only", "Lost only", "Gain & Lost", "None"),  # <-- KEY FIX
    name = NULL  # <-- removes the legend title
  ) +
  
  theme_minimal() +
  theme(
    panel.grid        = element_blank(),
    panel.background  = element_rect(fill = "white", color = NA),
    plot.background   = element_rect(fill = "white", color = NA),
    axis.text         = element_blank(),
    axis.title        = element_blank(),
    axis.ticks        = element_blank(),
    legend.position   = "bottom"
  )
ggsave(paste0(output, "treatment_map.png" ))





