#################################################
## Feature selection for trimmed model
## to predict BFI for full state (AZ)
#################################################

statewide.model <- xgb.load(here("2-experiments/exp01_statewide-model/models/xgb.statewide"))
feats <- read.csv(here("2-experiments/exp01_statewide-model/models/xgb.feature-names.csv"))

importance <- xgb.importance(model = statewide.model, feature_names = feats[,1])
xgb.plot.importance(importance, rel_to_first = TRUE, top_n = 10)

# Feature selection
# Top 10 most important features
top10 <- importance$Feature[1:10]

#################################################
## Training Hyperparameters for trimmed statewide XGBoost model
## to predict BFI for full state (AZ)
#################################################

full_training <- read.csv(here("2-experiments/exp01_statewide-model/models/data/instrumented_all-predictors.csv"))

top10.ind <- which(colnames(full_training) %in% top10)
training <- full_training[,top10.ind]


BFI.log <- logit(full_training$BFI)

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
xgb_caret <- train(x = training,
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
## Time Taken: 8.93 hours

## Hyperparameter Tuning
## nrounds = 700, max_depth = 7, eta = 0.05, gamma = 0.1,
## colsample_bytree = 0.8, min_child_weight = 10, subsample = 1
#################################################
