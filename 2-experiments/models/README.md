# Models

## Hyper-parameter Tuning

1.  Statewide Model

    -   Model to predict BFI trained on full training dataset (all filtered USGS streamgages)
    -   optimal model chosen by minimizing RMSE

| nrounds | max_depth | eta  | gamma | colsample_bytree | min_child_weight | subsample |
|-----------|-----------|-----------|-----------|-----------|-----------|-----------|
| 650     | 7         | 0.05 | 0.1   | 0.6              | 10               | 1         |

: Hyper-parameters (Statewide Model)
