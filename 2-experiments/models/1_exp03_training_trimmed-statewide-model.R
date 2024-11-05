#################################################
## Training statewide XGBoost model to predict BFI
## for full state (AZ)
#################################################
statewide.model <- xgb.load(here("2-experiments/exp01_statewide-model/models/xgb.statewide"))
feats <- read.csv(here("2-experiments/exp01_statewide-model/models/xgb.feature-names.csv"))

importance <- xgb.importance(model = statewide.model, feature_names = feats[,1])
xgb.plot.importance(importance, rel_to_first = TRUE, top_n = 10)

# Feature selection
# Top 10 most important features
top10 <- importance$Feature[1:10]
top10 <- c("HUC8", "Site_Num","BFI", top10) #adding BFI so that it is kept in trainingData

full_training <- read.csv(here("2-experiments/exp01_statewide-model/models/data/instrumented_all-predictors.csv"))

top10.ind <- which(colnames(full_training) %in% top10)
trainingData <- full_training[,top10.ind]

# observed BFI (log transformed to keep values between 0-1)
trainingData$BFI.log <- logit(full_training$BFI)

# Tuned hyper-parameters
tune_grid <- list(
  eta = 0.05,
  max_depth = 7,
  gamma = 0.1,
  colsample_bytree = 0.8,
  min_child_weight = 10,
  subsample = 1)

# Create 10-fold cross-validation indices
num_folds <- 10
fold_indices <- createFolds(trainingData$BFI, k = num_folds)

# Initialize an empty dataframe to store results from all folds
results_df <- data.frame()

#################################################
## Train the model
## 10-fold cross validation
#################################################

for (fold in 1:num_folds) {
  # Get the indices for the current fold
  fold_index <- fold_indices[[fold]]

  # Split the data into training and testing sets
  training <- trainingData[-fold_index, ]
  testing <- trainingData[fold_index, ]

  # Train an xgboost model on the training set
  xgb.model <- xgboost(
    nrounds = 700,
    data = as.matrix(training[, 4:13]),
    label = training$BFI.log,
    params = tune_grid,
    verbose = 0
  )

  # Make predictions on the testing set
  predictions <- predict(xgb.model, newdata = as.matrix(testing[, 4:13]))
  predictions <- inv.logit(predictions)

  # Store the results with testing data and the predictions
  results_fold <- cbind(testing, Predicted_BFI = predictions)

  # Combine the results from each fold into one dataframe
  results_df <- bind_rows(results_df, results_fold)

  cat("Completed fold", fold, "/", num_folds, "\n")
}

# Save Model
xgb.save(xgb.model, here("2-experiments/exp03_trimmed-statewide-model/models/xgb.trimmed-statewide"))

# Save feature names
write.csv(xgb.model$feature_names, here("2-experiments/exp03_trimmed-statewide-model/models/xgb.trimmed_feature-names.csv"), row.names = F)

# Save Results dataframe
write.csv(results_df, here("2-experiments/exp03_trimmed-statewide-model/data/trimmed-statewide-model_results.csv"), row.names = FALSE)

xgb.plot.importance(xgb.importance(model = xgb.model), rel_to_first = TRUE, top_n = 10)

## Goodness of Fit Statistics #############################

source(here("2-experiments/exp01_statewide-model/code/0_exp01_fx.R"))
analysis.stats(results_df)


#################################################
## Plotting Actual vs. Observed
#################################################
ggplot(data = results_df, mapping = aes(y = BFI, x = Predicted_BFI))+
  geom_point(alpha = 0.3,
             color = '#414141') +
  geom_smooth(method = "lm",
              linetype = "dashed",
              color = 'black',
              linewidth = .75,
              se=FALSE,
              fullrange=TRUE) +
  geom_abline(slope = 1,
              intercept =  0,
              color = "black",
              linewidth = 0.75) +
  theme_few() +
  theme(text=element_text(size=16, family = "Helvetica"),
        axis.title.y = element_text(size = 16, face = "bold"),
        axis.title.x = element_text(size = 16, face = "bold"),
        axis.ticks.length = unit(.1,'cm'),
        axis.ticks = element_line(size = 0.5),
        plot.margin = margin(1, 1, 1, 1, "cm"),
        panel.border = element_rect(colour = "black", fill=NA, linewidth=1)) +
  scale_x_continuous(breaks = c(0,0.25,0.5,0.75,1),
                     labels = c("", "0.25", "0.5", "0.75", "1"),
                     expand = c(0, 0), limits = c(0, 1)) +
  scale_y_continuous(breaks = c(0,0.25,0.5,0.75,1),
                     labels = c("0", "0.25", "0.5", "0.75", "1"),
                     expand = c(0, 0), limits = c(0, 1)) +
  labs(y = "Observed BFI",
       x = "Predicted BFI")

## Plotting Feature Importance #############################

feats <- read.csv(here("2-experiments/exp01_statewide-model/models/xgb-trimmed.feature-names.csv"))

xgb.plot.importance(xgb.importance(model = y,feature_names = feats[,1]), rel_to_first = TRUE, top_n = 10)
