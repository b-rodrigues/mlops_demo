library(targets)

scripts <- list.files("functions/",
                      pattern = "*.R",
                      full.names = T)

tar_option_set(packages = c(
                            "dials",
                            "dplyr",
                            "parsnip",
                            "readr",
                            "recipes",
                            "stringr",
                            "tune",
                            "workflows",
                            "yardstick"
                           )
              )


lapply(scripts, source)

list(

  tar_target(
    datasets,
    get_data(n=100)
  ),

  tar_target(
    training_set,
    datasets$data_train
  ),

  tar_target(
    testing_set,
    datasets$data_test
  ),

  tar_target(
    training_splits,
    rsample::vfold_cv(training_set, v = 3)
  ),

  tar_target(
    preprocessed,
    preprocess(training_set)
  ),
  
  tar_target(
    boosted_trees_model,
    define_model(boost_tree,
                 "xgboost",
                 "classification",
                 mtry = tune(),
                 tree = tune(),
                 tree_depth = tune())
  ),
  
  tar_target(
    boost_grid,
    define_grid(boosted_trees_model,
                predictor_data = select(training_set, -target),
                grid_max_entropy,
                size = 5)
  ),
  
  tar_target(
    boost_wflow,
    define_wflow(preprocessed,
                 boosted_trees_model)
  ),
  
  tar_target(
    tuned_boosted_trees,
    tune_grid(boost_wflow,
              training_splits,
              boost_grid)
  ),
  
  tar_target(
    best_boosted_trees_hyperparams,
    as.list(select_best(tuned_boosted_trees, "roc_auc"))
  ),
  
  tar_target(
    best_boosted_trees_model,
    define_model(boost_tree,
                 "xgboost",
                 "classification",
                 mtry = best_boosted_trees_hyperparams$mtry,
                 trees = best_boosted_trees_hyperparams$trees,
                 tree_depth = best_boosted_trees_hyperparams$tree_depth)
  ),
  
  tar_target(
    best_boost_wflow,
    define_wflow(preprocessed,
                 best_boosted_trees_model)
  ),
  
  tar_target(
    fit_boosted_trees,
    fit(best_boost_wflow, data = training_set),
  ),
  
  tar_target(
    boost_predictions_prob,
    predict(fit_boosted_trees,
            testing_set,
            "prob")
  ),
  
  tar_target(
    boost_predictions_class,
    predict(fit_boosted_trees,
            testing_set,
            "class"),
  ),
  
  tar_target(
    testing_set_and_preds,
    bind_cols(
      list(
        testing_set,
        boost_predictions_prob,
        boost_predictions_class
      )),
  ),
  
  tar_target(
    conf_mat_boost,
    conf_mat(testing_set_and_preds,
             truth = target,
             estimate = .pred_class),
  ),
  
  tar_target(
    roc_curve_boost,
    roc_curve(testing_set_and_preds,
              truth = target,
              `.pred_<=50K`),
  ),
  
  tar_target(
    roc_auc_boost,
    roc_auc(testing_set_and_preds,
            truth = target,
            `.pred_<=50K`),
  )

)


