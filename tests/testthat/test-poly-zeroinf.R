if (suppressWarnings(
  requiet("testthat") &&
  requiet("ggeffects") &&
  requiet("glmmTMB") &&
  requiet("pscl") &&
  getRversion() >= "4.0.0"
)) {

  data(Salamanders)

  m1 <- suppressWarnings(glmmTMB(
    count ~ spp + poly(cover, 3) + mined + (1 | site),
    ziformula = ~DOY,
    dispformula = ~spp,
    data = Salamanders,
    family = nbinom2
  ))

  m2 <- suppressWarnings(glmmTMB(
    count ~ spp + poly(cover, 3) + mined + (1 | site),
    ziformula = ~poly(DOY, 3),
    dispformula = ~spp,
    data = Salamanders,
    family = nbinom2
  ))

  m3 <- zeroinfl(count ~ spp + poly(cover, 3) + mined | DOY, data = Salamanders)
  m4 <- zeroinfl(count ~ spp + poly(cover, 3) + mined | poly(DOY, 3), data = Salamanders)

  test_that("ggpredict, glmmTMB", {
    pr <- ggpredict(m1, c("cover", "mined", "spp"), type = "fe.zi", verbose = FALSE)
    expect_identical(ncol(pr), 7L)
    expect_identical(
      colnames(pr),
      c("x", "predicted", "std.error", "conf.low", "conf.high", "group", "facet")
    )

    pr <- ggpredict(m1, c("mined", "spp"), type = "fe.zi", verbose = FALSE)
    expect_identical(ncol(pr), 6L)

    pr <- ggpredict(m2, c("cover", "mined", "spp"), type = "fe.zi", verbose = FALSE)
    expect_identical(ncol(pr), 7L)

    pr <- ggpredict(m2, c("mined", "spp"), type = "fe.zi", verbose = FALSE)
    expect_identical(ncol(pr), 6L)

    pr <- ggpredict(m3, c("mined", "spp"), type = "fe.zi", verbose = FALSE)
    expect_identical(ncol(pr), 6L)

    pr <- ggpredict(m3, c("cover", "mined", "spp"), type = "fe.zi", verbose = FALSE)
    expect_identical(ncol(pr), 7L)

    pr <- ggpredict(m4, c("mined", "spp"), type = "fe.zi", verbose = FALSE)
    expect_identical(ncol(pr), 6L)

    pr <- ggpredict(m4, c("cover", "mined", "spp"), type = "fe.zi", verbose = FALSE)
    expect_identical(ncol(pr), 7L)
  })
}
