if (suppressWarnings(requiet("testthat") && requiet("ggeffects") && requiet("marginaleffects") && requiet("ggplot2"))) {
  set.seed(123)
  n <- 200
  d <- data.frame(
    outcome = rnorm(n),
    groups = as.factor(sample(c("treatment", "control"), n, TRUE)),
    episode = as.factor(sample(1:3, n, TRUE)),
    ID = as.factor(rep(1:10, n / 10)),
    sex = as.factor(sample(c("female", "male"), n, TRUE, prob = c(0.4, 0.6)))
  )
  model1 <- lm(outcome ~ groups * episode, data = d)
  test_that("hypothesis_test, categorical, pairwise", {
    out <- hypothesis_test(model1, c("groups", "episode"))
    expect_identical(colnames(out), c("groups", "episode", "Contrast", "conf.low", "conf.high", "p.value"))
    expect_equal(
      out$Contrast,
      c(
        0.4183, -0.2036, -0.1482, 0.0709, 0.1211, -0.6219, -0.5666,
        -0.3475, -0.2972, 0.0554, 0.2745, 0.3247, 0.2191, 0.2694, 0.0503
      ),
      tolerance = 1e-3,
      ignore_attr = FALSE
    )
    expect_identical(
      out$groups,
      c(
        "control-treatment", "control-control", "control-treatment",
        "control-control", "control-treatment", "treatment-control",
        "treatment-treatment", "treatment-control", "treatment-treatment",
        "control-treatment", "control-control", "control-treatment",
        "treatment-control", "treatment-treatment", "control-treatment"
      )
    )
    expect_equal(
      attributes(out)$standard_error,
      c(
        0.23286, 0.21745, 0.23533, 0.22247, 0.21449, 0.23558, 0.25218,
        0.24022, 0.23286, 0.23803, 0.22532, 0.21745, 0.24262, 0.23533,
        0.22247
      ),
      tolerance = 1e-3
    )
  })
  test_that("hypothesis_test, categorical, pairwise, p_adjust", {
    out1 <- hypothesis_test(model1, c("groups", "episode"))
    out2 <- hypothesis_test(model1, c("groups", "episode"), p_adjust = "tukey")
    expect_equal(
      out1$p.value,
      c(
        0.074, 0.3503, 0.5295, 0.7504, 0.5729, 0.009, 0.0258, 0.1497,
        0.2033, 0.8163, 0.2247, 0.137, 0.3676, 0.2538, 0.8215
      ),
      tolerance = 1e-3,
      ignore_attr = FALSE
    )
    expect_equal(
      out2$p.value,
      c(
        0.4704, 0.9366, 0.9887, 0.9996, 0.9931, 0.0927, 0.2215, 0.6985,
        0.7976, 0.9999, 0.8276, 0.6689, 0.9453, 0.862, 0.9999
      ),
      tolerance = 1e-3,
      ignore_attr = FALSE
    )
  })
  test_that("hypothesis_test, categorical, NULL", {
    out <- hypothesis_test(model1, c("groups", "episode"), test = NULL)
    expect_identical(colnames(out), c("groups", "episode", "Predicted", "conf.low", "conf.high", "p.value"))
    expect_equal(out$Predicted, c(0.028, -0.3903, 0.2316, 0.1763, -0.0428, -0.0931),
      tolerance = 1e-3,
      ignore_attr = FALSE
    )
    expect_identical(
      out$groups,
      structure(c(1L, 2L, 1L, 2L, 1L, 2L), levels = c("control", "treatment"), class = "factor")
    )
  })

  data(iris)
  model2 <- lm(Sepal.Width ~ Sepal.Length * Species, data = iris)
  test_that("hypothesis_test, interaction", {
    out <- hypothesis_test(model2, c("Sepal.Length", "Species"))
    expect_identical(colnames(out), c(
      "Sepal.Length", "Species", "Contrast", "conf.low", "conf.high",
      "p.value"
    ))
    expect_equal(out$Contrast, c(0.4788, 0.5666, 0.0878),
      tolerance = 1e-3,
      ignore_attr = FALSE
    )
    expect_identical(out$Sepal.Length, c("slope", "slope", "slope"))
  })

  test_that("hypothesis_test, by-argument", {
    skip_if_not_installed("datawizard")
    data(efc)
    efc$c161sex <- datawizard::to_factor(efc$c161sex)
    efc$c172code <- datawizard::to_factor(efc$c172code)

    mfilter <- lm(neg_c_7 ~ c161sex * c172code + e42dep + c12hour, data = efc)
    prfilter <- ggpredict(mfilter, "c172code")

    out <- hypothesis_test(prfilter, by = "c161sex")
    expect_identical(nrow(out), 6L)
    expect_identical(
      out$c172code,
      c(
        "low level of education-intermediate level of education",
        "low level of education-high level of education",
        "intermediate level of education-high level of education",
        "low level of education-intermediate level of education",
        "low level of education-high level of education",
        "intermediate level of education-high level of education"
      )
    )
    expect_equal(out$p.value, c(0.3962, 0.6512, 0.7424, 0.9491, 0.0721, 0.0288), tolerance = 1e-3)

    out <- hypothesis_test(prfilter, by = "c161sex", p_adjust = "tukey")
    expect_equal(out$p.value, c(0.6727, 0.8934, 0.9422, 0.9978, 0.1699, 0.0734), tolerance = 1e-3)

    prfilter <- ggpredict(mfilter, c("c172code", "c161sex"))
    out <- hypothesis_test(prfilter, p_adjust = "tukey")
    out <- out[out$c161sex %in% c("Male-Male", "Female-Female"), , drop = FALSE]
    expect_equal(out$p.value, c(0.9581, 0.9976, 0.9995, 1, 0.4657, 0.2432), tolerance = 1e-3)

    expect_error(hypothesis_test(mfilter, "c161sex", by = "c12hour"), regex = "categorical")
  })

  if (suppressWarnings(requiet("lme4"))) {
    model3 <- suppressMessages(lme4::lmer(outcome ~ groups * episode + sex + (1 | ID), data = d))
    test_that("hypothesis_test, categorical, pairwise", {
      out <- hypothesis_test(model3, c("groups", "episode"))
      expect_identical(colnames(out), c("groups", "episode", "Contrast", "conf.low", "conf.high", "p.value"))
      expect_equal(
        out$Contrast,
        c(
          0.4199, -0.2051, -0.1528, 0.0666, 0.1187, -0.6251, -0.5727,
          -0.3533, -0.3012, 0.0524, 0.2718, 0.3239, 0.2194, 0.2715, 0.0521
        ),
        tolerance = 1e-3,
        ignore_attr = FALSE
      )
      expect_identical(
        out$groups,
        c(
          "control-treatment", "control-control", "control-treatment",
          "control-control", "control-treatment", "treatment-control",
          "treatment-treatment", "treatment-control", "treatment-treatment",
          "control-treatment", "control-control", "control-treatment",
          "treatment-control", "treatment-treatment", "control-treatment"
        ),
      )
      expect_identical(
        out$episode,
        c(
          "1-1", "1-2", "1-2", "1-3", "1-3", "1-2", "1-2", "1-3", "1-3",
          "2-2", "2-3", "2-3", "2-3", "2-3", "3-3"
        )
      )
    })
    test_that("hypothesis_test, categorical, NULL", {
      out <- hypothesis_test(model3, c("groups", "episode"), test = NULL)
      out <- out[order(out$groups, out$episode), ]
      expect_identical(colnames(out), c("groups", "episode", "Predicted", "conf.low", "conf.high", "p.value"))
      expect_equal(out$Predicted, c(0.0559, 0.2611, -0.0107, -0.364, 0.2087, -0.0628),
        tolerance = 1e-3,
        ignore_attr = FALSE
      )
      expect_identical(
        out$groups,
        structure(c(1L, 1L, 1L, 2L, 2L, 2L), levels = c("control", "treatment"), class = "factor")
      )
      expect_identical(
        out$episode,
        structure(c(1L, 2L, 3L, 1L, 2L, 3L), levels = c("1", "2", "3"), class = "factor")
      )
    })

    if (suppressWarnings(requiet("nlme"))) {
      d <- nlme::Orthodont
      m <- lme4::lmer(distance ~ age * Sex + (1 | Subject), data = d)
      test_that("hypothesis_test, numeric, one focal, pairwise", {
        out <- hypothesis_test(m, "age")
        expect_identical(colnames(out), c("age", "Slope", "conf.low", "conf.high", "p.value"))
        expect_equal(out$Slope, 0.6602, tolerance = 1e-3, ignore_attr = FALSE)
      })
      test_that("hypothesis_test, numeric, one focal, NULL", {
        out <- hypothesis_test(m, "age", test = NULL)
        expect_identical(colnames(out), c("age", "Slope", "conf.low", "conf.high", "p.value"))
        expect_equal(out$Slope, 0.6602, tolerance = 1e-3, ignore_attr = FALSE)
      })
      test_that("hypothesis_test, categorical, one focal, pairwise", {
        out <- hypothesis_test(m, "Sex")
        expect_identical(colnames(out), c("Sex", "Contrast", "conf.low", "conf.high", "p.value"))
        expect_equal(out$Contrast, 2.321023, tolerance = 1e-3, ignore_attr = FALSE)
      })
      test_that("hypothesis_test, categorical, one focal, NULL", {
        out <- hypothesis_test(m, "Sex", test = NULL)
        expect_identical(colnames(out), c("Sex", "Predicted", "conf.low", "conf.high", "p.value"))
        expect_equal(out$Predicted, c(24.9688, 22.6477), tolerance = 1e-3, ignore_attr = FALSE)
      })
    }
  }

  if (suppressWarnings(requiet("lme4"))) {
    set.seed(123)
    n <- 200
    d <- data.frame(
      outcome = rnorm(n),
      groups = as.factor(sample(c("ta-ca", "tb-cb"), n, TRUE)),
      episode = as.factor(sample(1:3, n, TRUE)),
      ID = as.factor(rep(1:10, n / 10)),
      sex = as.factor(sample(c("1", "2"), n, TRUE, prob = c(0.4, 0.6)))
    )

    model <- suppressMessages(lme4::lmer(outcome ~ groups * sex + episode + (1 | ID), data = d))
    test_that("hypothesis_test, masked chars in levels", {
      out <- hypothesis_test(model, c("groups", "sex"))
      expect_identical(colnames(out), c("groups", "sex", "Contrast", "conf.low", "conf.high", "p.value"))
      expect_equal(
        out$Contrast,
        c(-0.1854, -0.4473, -0.2076, -0.2619, -0.0222, 0.2397),
        tolerance = 1e-3,
        ignore_attr = FALSE
      )
      expect_identical(
        out$groups,
        c(
          "ta-ca-ta-ca", "ta-ca-tb-cb", "ta-ca-tb-cb", "ta-ca-tb-cb",
          "ta-ca-tb-cb", "tb-cb-tb-cb"
        )
      )
    })
  }

  if (suppressWarnings(requiet("lme4"))) {
    test_that("hypothesis_test, don't drop single columns", {
      data(iris)
      iris$Sepal.Width.factor <- factor(as.numeric(iris$Sepal.Width >= 3))
      m <- lme4::lmer(Petal.Length ~ Petal.Width * Sepal.Width.factor + (1 | Species), data = iris)
      expect_s3_class(
        hypothesis_test(m, c("Sepal.Width.factor", "Petal.Width [0.5]")),
        "ggcomparisons"
      )
    })
  }

  if (suppressWarnings(requiet("lme4"))) {
    test_that("hypothesis_test, make sure random effects group is categorical", {
      data(sleepstudy)
      set.seed(123)
      sleepstudy$grp <- as.factor(sample(letters[1:3], nrow(sleepstudy), replace = TRUE))
      sleepstudy$ID <- as.numeric(sleepstudy$Subject)
      m <- lmer(Reaction ~ Days + (1 | ID), sleepstudy)
      out <- hypothesis_test(ggpredict(m, "Days"))
      expect_equal(out$Slope, 10.467285959584, tolerance = 1e-4)

      m <- lmer(Reaction ~ Days * grp + (1 | ID), sleepstudy)
      out <- hypothesis_test(ggpredict(m, c("Days", "grp")))
      expect_equal(out$Contrast, c(-0.0813, -1.26533, -1.18403), tolerance = 1e-4)
    })
  }
}
