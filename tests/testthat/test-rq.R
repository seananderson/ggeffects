if (suppressWarnings(
  requiet("testthat") &&
  requiet("ggeffects") &&
  requiet("quantreg") &&
  getRversion() >= "3.6.0"
)) {

  data(stackloss)
  m1 <- rq(stack.loss ~ Air.Flow + Water.Temp, data = stackloss, tau = 0.25)

  test_that("ggpredict, rq", {
    expect_warning({
      pr <- ggpredict(m1, "Air.Flow")
    })
    expect_equal(pr$predicted[1], 10.09524, tolerance = 1e-4)
  })

  test_that("ggeffect, rq", {
    expect_null(ggeffect(m1, "Air.Flow", verbose = FALSE))
  })

  test_that("ggemmeans, rq", {
    expect_null(ggemmeans(m1, "Air.Flow", verbose = FALSE))
  })
}
