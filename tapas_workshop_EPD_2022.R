# -----------------------------------------------------------------------------
# EPD Workshop (Prague 2022): Charcoal Trend and Peaks analysis with the 'tapas' R package"
# author: Walter Finsinger
# date: 03-04 June 2022
# -----------------------------------------------------------------------------
#
# Hi,
# many thanks for your interest in this R package.
# The following R script is meant to illustrate a simple workflow to perform
# trend and peak-detection analysis of macroscopic charcoal records.
#
# The code builds on CharAnalysis (https://github.com/phiguera/CharAnalysis),
# a software for analyzing sediment-charcoal records written in and compiled
# with Matlab 7.0 by Phil Higuera (Higuera et al., 2009), with significant input
# by (amongst others) Patrick Bartlein (U of OR), Daniel Gavin (U of OR),
# Jennifer Marlon, and Ryan Kelly.
# The core of most functions that are included in the 'tapas' package was
# translated verbatim from CharAnalysis.


# In this tutorial, you'll be using the macroscopic charcoal record from
# Code Lake (Higuera et al., 2009). Please be aware that the tutorial shows
# how the tapas package performs the peak-detection analysis with this dataset
# using different options than those chosen by Higuera et al. (2009).
#
# Specifically, the tutorial uses the so-called 'global' threshold rather than
# the so-called 'local threshold'. However, the tapas package also allows
# performing the anlysis with the so-called 'local' threshold, as does
# CharAnalysis.



# 1. Download, install and load the R 'tapas' package -------------------------

## If you haven't installed the tapas package, yet, run these lines.
## Please, run these lines also to download the most recent version of
## the tapas package:
# install.packages("devtools")
# library(devtools)
devtools::install_github("wfinsinger/tapas")

## Load packages into the local R Environment
library(tapas)   # Load the 'tapas' package
library(ggplot2) # additionally load the ggplot package



# 2. Load the toy data that comes with the 'tapas' package ----------------
# i.e. the macroscopic charcoal record from Code Lake (Higuera et al., 2009)
co <- tapas::co_char_data
head(co)

# NB: if you want to run the analysis with your own data, you should load your
# data into the R Environment, for instance using 'read.csv()'. The format of
# the input data is described on https://github.com/wfinsinger/tapas.



# 3. Check the data (gaps? contiguous sampling? duplicates?) --------------
co <- tapas::check_pretreat(co)



# 4. Bin the data (resample to equal sampling intervals) ----------------------

#### 4.1. Bin the data using the default options ------------------------------
co_i <- tapas::pretreatment_data(series = co)
# Question: Are default options ok?
# Specifically: the argument 'yrInterp', which defines the resolution of the
#    binned series (by default, yrInterp = the median sampling resolution).


### 4.2. Explore the sampling resolution of the record ------------------------

# Plot the depth-age relationship:
par(mfrow = c(1,1), mar = c(5,5,2,2))
plot(co$AgeTop, co$cmTop, type = "l",
     xlab = "Age (cal BP)",
     ylab = "Depth (cmTop)")


# Set x-axis and y-axis limits, and the direction of the axes
# and replot the depth-age relationship:
x_lim <- c(max(co$AgeTop), min(co$AgeTop))
y_lim <- c(max(co$cmTop), min(co$cmTop))
plot(co$AgeTop, co$cmTop, type = "l",
     xlim = x_lim, ylim = y_lim,
     xlab = "Age (cal BP; AgeTop)",
     ylab = "Depth (cm; cmTop)")


# Plot the raw data: charcoal counts against age
plot(co$AgeTop, co$char, type = "h",
     xlim = x_lim,
     xlab = "Age (cal BP)",
     ylab = "Charcoal counts (pieces/sample)")


# Calculate and plot the sampling resolution (sample integration time)
# for the record (yr/sample), and the median sampling resolution (red dashed line)
yr_smpl <- co$AgeBot - co$AgeTop
plot(co$AgeTop, yr_smpl, type = "l",
     xlab = "Age (cal BP)",
     ylab = "Sample integration time\n(yr/sample)")
abline(h = median(yr_smpl), col = "red", lty = 2)

#### Check the distribution of sampling resolution values
boxplot(yr_smpl, ylab = "Sample integration time\n(yr/sample)")
summary(yr_smpl)


### 4.3. Bin the data ---------------------------------------------------------
# Given the results above, one may set, for instance, yrInterp = 16 years.
co_i <- tapas::pretreatment_data(series = co, out = "accI",
                                 first = -51, last = 7500,
                                 yrInterp = 16)


# 5. Detrend the data ---------------------------------------------------------
co_detr <- tapas::SeriesDetrend(co_i, detr.type = "mov.median",
                                smoothing.yr = 500)
# The SeriesDetrend() function sends plots (one for each variable included in
# the input data.frame) to the device. To save plots directly to the hard disk,
# one can use the pdf() and dev.off() R functions.



# 6. Decompose noise & potential peaks ----------------------------------------
co_glob <- tapas::global_thresh(co_detr, proxy = "charAR",
                                thresh.value = 0.95)

# The global_thresh() function produces two plots. The first one shows the
# results of the Gaussian Mixture Model analysis. The second, shows the
# detrended series with the thresholds, and the peaks (grey circles: peaks
# that did not pass the minimum-count test, red crosses: those that passed the
# test).


# 7. Evaluate results ---------------------------------------------------------
# - check SNI plot produced with previous function (the 2nd to last plot)


# 8. Evaluate sensitivity to smoothing-window widths --------------------------
# using the peak_detection() wrapper function (which runs the functions used in
# steps 3.-6. in one go):
co_glob2 <- tapas::peak_detection(series = co, proxy = "char",
                                 first = -51, last = 7500,
                                 yrInterp = 16,
                                 thresh_type = "global",
                                 detr_type = "mov.median",
                                 smoothing_yr = 500,
                                 thresh_value = 0.95, min_CountP = 0.05,
                                 sens = F,
                                 smoothing_yr_seq = c(500, 600, 700,
                                                      800, 900, 1000))
# and check the 2nd to last plot...

# 9. ...and if you are happy with it, plot results & export data -------
par(mfrow = c(2,1))
tapas::Plot.Anomalies(co_glob, plot.neg = FALSE)
tapas::Plot_ReturnIntervals(co_glob, plot.x = TRUE)

# extract data from the package's output as a data.frame.
co_glob_exp <- tapas::tapas_export(co_glob)

# NB: This can then be saved as *.csv file to the local hard disk
# with write.csv()




# 10. Influence of the 'yrInterp' argument on the SNI? ------------------------

# Here the code will loop analyses with different yrInterp values, then gather
# data obtained in each of the loops, and finally plot diagnostic figures:

# First define which binning-year values you want to use
yrInterp_want <- c(5, 15, 30, 50, 100)

# prepare empty lists where data will be stored in the loop below
yrInterp_list <- list()
co_loc_list <- list()

# Run the peak_detection() analysis with different yrInterp values
for (i in 1:length(yrInterp_want)) {
        yr_interp <- yrInterp_want[i]
        co_loc_i <- tapas::peak_detection(series = co, proxy = "char",
                                          first = -51, last = 7500,
                                          yrInterp = yr_interp,
                                          thresh_type = "global",
                                          detr_type = "mov.median",
                                          smoothing_yr = 500,
                                          thresh_value = 0.95,
                                          sens = FALSE, plotit = FALSE)
        co_loc_list[[i]] <- co_loc_i  # stores output of analysis

        # Gather the summary data.frame generated by tapas_export() in the list
        co_loc_i_exp <- tapas::tapas_export(co_loc_i)
        co_loc_i_exp$yr_interp <- yr_interp
        yrInterp_list[[i]] <- co_loc_i_exp
}

# Clean environment
rm(co_loc_i, co_loc_i_exp)

# Gather the data from the list into one data.frame
yrInterp_sens <- dplyr::bind_rows(yrInterp_list)

# Plot results
ggplot(data = yrInterp_sens, aes(x = age_top_i, y = sni_smooth)) +
        geom_line(aes(group = yr_interp, colour = factor(yr_interp))) +
        scale_x_reverse() + #scale_y_continuous(limits = c(0, 20)) +
        geom_hline(yintercept = 3) +
        ggtitle(label = "Code Lake - SNI records for different yrInterp",
                subtitle = "local GMMs, mov.median 500yrs, thresh.value 0.95")

# Question: what emerges from this comparison ?



# We can also compare the results
par(mfrow = c(length(yrInterp_want), 1))
for (i in 1:length(yrInterp_want)) {
        tapas::Plot.Anomalies(co_loc_list[[i]], plot.neg = FALSE)
}


# 11. - n: Assignment:
# You may copy/paste the code under paragraph "10. Influence of the 'yrInterp'...",
# and modify it to explore the influence of other user-determined choices,
# such as:
# - the threshold value (thresh.value),
# - the minimum-count test (min_CountP),
# - the detrending method (detr_type),
# - ...




# 12. Model the 'background' trend with a Generalised Additive Model (GAM) ----
#
# NB:
# The functions that are illustrated here are still at a 'beta' stage.
# For more details on GAMs you can refer to the following paper:
# Simpson GL (2018) Modelling Palaeoecological Time Series Using Generalised
#  Additive Models. Frontiers in Ecology and Evolution 6: 149:
#  doi:10.3389/fevo.2018.00149.


#### 11.1. Reshape the binned data that is stored in a list such that ---------
# the 'mgcv' package can read it:
co_i_mgcv <- tapas::tapas2mgcv(series = co_i)

#### 11.2. Determine trend with a GAM -----------------------------------------
#### and let the gam() function choose the degree of the whiggliness of
#### the smoothed curve:
co_i_gam1 <- mgcv::gam(charAR ~ s(age_top),
                       data = co_i_mgcv,
                       family = gaussian(link = "identity"),
                       method = "REML")

#### 11.3. Check GAM model ----------------------------------------------------
par(mfrow = c(4,1), mar = c(2,5,2,2))
mgcv::gam.check(co_i_gam1)
summary(co_i_gam1)

par(mfrow = c(2,1), mar = c(2,5,2,2))
mgcv::plot.gam(co_i_gam1, shade = T)
plot(co_i_mgcv$age_top, co_i_mgcv$charAR, type = "l")
lines(co_i_mgcv$age_top, co_i_gam1$fitted.values, col = "red", lwd = 2)


#### 11.4. Reshape the GAM output for tapas:: and detrend data ----------------
co_i_gam1_detr <- tapas::mgcv2tapas(series = co_i_gam1,
                                    data_type = "accI")

#### 11.5. and finally move on to the 'threshold analysis' --------------------
co_gam_thresh <- global_thresh(co_i_gam1_detr, proxy = "charAR",
                               smoothing.yr = 500)
tapas::Plot.Anomalies(co_gam_thresh, plot.neg = F, plot.x = T)
