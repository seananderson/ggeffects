.runThisTest <- Sys.getenv("RunAllggeffectsTests") == "yes"

if (.runThisTest &&
    suppressPackageStartupMessages((requiet("testthat") &&
                                    requiet("ggeffects") &&
                                    requiet("AER")))) {
  data(CigarettesSW)
  CigarettesSW$rprice <- with(CigarettesSW, price / cpi)
  CigarettesSW$rincome <- with(CigarettesSW, income / population / cpi)
  CigarettesSW$tdiff <- with(CigarettesSW, (taxs - tax) / cpi)

  m1 <- ivreg(log(packs) ~ log(rprice) + log(rincome) | log(rincome) + tdiff + I(tax / cpi), data = CigarettesSW, subset = year == "1995")

  test_that("ggpredict", {
    p <- ggpredict(m1, "rprice")
    expect_equal(p$predicted[1], 125.4697, tolerance = 1e-1)
  })
}
