.runThisTest <- Sys.getenv("RunAllggeffectsTests") == "yes"

if (.runThisTest &&
    getRversion() >= "3.6.0" &&
    requiet("testthat") &&
    requiet("ggeffects") &&
    requiet("ordinal") &&
    requiet("MASS")) {
  data(wine, package = "ordinal")
  m1 <- clm(rating ~ temp * contact, data = wine)

  test_that("ggpredict", {
    p <- ggpredict(m1, "temp")
    expect_equal(p$predicted[1], 0.1960351, tolerance = 1e-3)
    expect_equal(p$conf.low[1], 0.0772626, tolerance = 1e-3)
    expect_equal(p$conf.high[1], 0.41522921, tolerance = 1e-3)
    ggpredict(m1, c("temp", "contact"))
  })

  test_that("ggeffect", {
    p <- ggeffect(m1, "temp")
    expect_equal(p$predicted[1], 0.110564082334497, tolerance = 1e-3)
    ggeffect(m1, c("temp", "contact"))
  })

  test_that("ggemmeans", {
    p <- ggemmeans(m1, "contact")
    expect_equal(p$predicted[1], 0.1097049, tolerance = 1e-3)
    ggemmeans(m1, c("temp", "contact"))
  })
}
