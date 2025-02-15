.runThisTest <- Sys.getenv("RunAllggeffectsTests") == "yes"

# works interactive only - check every now and then
if (FALSE && .runThisTest &&
    suppressWarnings(
    requiet("testthat") &&
    requiet("brms") &&
    requiet("ggeffects") &&
    requiet("insight")
  )) {
    data(mtcars)
  m1 <- insight::download_model("brms_ordinal_1")
  m2 <- insight::download_model("brms_ordinal_1_wt")

  m3 <- insight::download_model("brms_categorical_1_num")
  m4 <- insight::download_model("brms_categorical_1_fct")
  m5 <- insight::download_model("brms_categorical_1_wt")

  test_that("ggpredict, brms-categ-cum", {
    p1 <- ggpredict(m1, "mpg")
    p2 <- ggpredict(m2, "mpg")

    p3 <- ggpredict(m3, "mpg")
    p4 <- ggpredict(m4, "mpg")
    p5 <- ggpredict(m5, "mpg")

    # m3/m4 are the same, except response is numeric/factor, so predictions should be the same
    p4$response.level <- as.numeric(p4$response.level)
    for (resp.level in 3:5) {
      expect_equal(
        p3[p3$response.level == resp.level, ],
        p4[p4$response.level == resp.level, ],
        ignore_attr = TRUE, tolerance = 0.05
      )
    }
  })
}
