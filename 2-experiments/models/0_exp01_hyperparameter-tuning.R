#################################################
## Training Hyperparameters for statewide XGBoost model
## to predict BFI for full state (AZ)
#################################################

training <- read.csv(here("2-experiments/exp_statewide-model/models/data/instrumented_all-predictors.csv"))

BFI.log <- logit(training$BFI)

tune_grid <- expand.grid(
  nrounds = seq(from = 500, to = 1000, by = 50),
  eta = c(0.025, 0.05, 0.075, 0.1),
  max_depth = c(3, 4, 5, 6, 7),
  gamma = c(0, 0.025, 0.05, 0.075, 0.1),
  colsample_bytree = c(0.6, 0.8, 1),
  min_child_weight = c(1, 3, 5, 10),
  subsample = c(0.5, 1)
)

start.time <- Sys.time()
xgb_caret <- train(x = training[,7:52],
                   y = BFI.log,
                   method = "xgbTree",
                   trControl = trainControl(
                     method = "cv",
                     number = 5,
                     verboseIter = TRUE),
                   tuneGrid = tune_grid,
                   verbosity = 0)

xgb_caret$bestTune
end.time <- Sys.time()
time.taken <- round(end.time - start.time, 2)
time.taken

#################################################
## 9497 samples
## 46 predictor
## Time Taken: 14.27 hours

## Hyperparameter Tuning
## nrounds = 650, max_depth = 7, eta = 0.05, gamma = 0.1,
## colsample_bytree = 0.6, min_child_weight = 10, subsample = 1
#################################################
