#######################################################################
#######################################################################
######                                                           ######
######                     Problem Set #06                       ######
######                        Yang Han                           ######
######                                                           ######
#######################################################################
#######################################################################



###Preparation


#  Install and load necessary packages.
library(nycflights13)
library(dplyr)
library(parallel)



###Question 1


## 1.Without any parallel processing.

#  Load the data.
airtime_flight <- flights %>%
  select(origin,
         dest,
         air_time) %>%
  filter(!is.na(air_time))

#  Define a bootstrap function by destination.
##' @title A bootstrap function
##' @param dat A set of data
##' @return A set of data representing sample mean by origin
boot <- function(dat) {
  sample_data <- dat %>%
    group_by(dest) %>%
    sample_n(size = n(), replace = TRUE) %>%
    ungroup()
  
  mean_dat <- sample_data %>% 
    group_by(origin) %>%
    summarize(mean_air_time = mean(air_time)) %>%
    ungroup()
  
  return(mean_dat)
}

#  Set the number of bootstrap samples.
reps <- 1000

#  Initialize an empty tibble to store bootstrap results.
bootstrap_results1 <- tibble()

#  Generate the bootstrapping samples.
system.time(res1 <- 
  for (i in 1:reps) {
    bootstrap_results1 <- bind_rows(bootstrap_results1, boot(airtime_flight))
  })

#  Calculate the standard error for each origin.
bootstrap_se1 <- bootstrap_results1 %>%
  group_by(origin) %>%
  summarize(sd_origin = sd(mean_air_time))

#  Calculate the confidence interval for each origin and display the result table.
avg1 <- airtime_flight %>%
  group_by(origin) %>%
  summarize(mean_air_time = mean(air_time))

results_table1 <- avg1 %>%
  left_join(bootstrap_se1) %>%
  mutate(lower_bound = mean_air_time - 1.96 * sd_origin) %>%
  mutate(upper_bound = mean_air_time + 1.96 * sd_origin) %>%
  select(-sd_origin)

print(results_table1)



## 2.With some form of parallel processing


#  Generate the bootstrapping sample.
system.time({
  numCores <- detectCores()
  cl <- makeCluster(numCores)
  clusterEvalQ(cl, library(dplyr))
  clusterExport(cl, c("airtime_flight", "boot"))
  res2 <- parLapply(cl, seq_len(reps), function(x) boot(airtime_flight))
  stopCluster(cl)
})


#  Reduce the result into a single tibble.
bootstrap_results2 <- bind_rows(res2)

#  Then carry out the calculations and display the result.
bootstrap_se2 <- bootstrap_results2 %>%
  group_by(origin) %>%
  summarize(sd_origin = sd(mean_air_time))

avg2 <- airtime_flight %>%
  group_by(origin) %>%
  summarize(mean_air_time = mean(air_time))

results_table2 <- avg2 %>%
  left_join(bootstrap_se2) %>%
  mutate(lower_bound = mean_air_time - 1.96 * sd_origin) %>%
  mutate(upper_bound = mean_air_time + 1.96 * sd_origin) %>%
  select(-sd_origin)

print(results_table2)

#  From the two sets of system processing time we can see the performance of the parallel processing is far better
#  than without using it.
