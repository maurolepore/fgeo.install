#' Install __fgeo__ from GitHub.
#'
#' This function installs __fgeo__ dependencies from CRAN and fgeo packages from
#' GitHub. It installs only the packages that are not already installed.
#'
#' @param ref Desired git reference. Could be a commit, tag, a call to
#'   github_pull(), or most commonly a branch name such as "master" or "dev".
#'
#' @seealso [remotes::install_github], [follow_up].
#'
#' @export
#'
#' @examples
#' \dontrun{
#' install_fgeo()
#'
#' # Install the development (maybe failing) branch of each package.
#' install_fgeo("dev")
#' }
install_fgeo <- function(ref = "master") {
  inform_expected_r_environment()

  if (!all_installed(needed(fgeo.install::cran_packages))) {
    install_needed_cran_packages()
  }
  done(fgeo.install::cran_packages, "All CRAN dependencies are installed.")

  if (!all_installed(needed(fgeo.install::fgeo_packages))) {
    install_needed_fgeo_packages(ref = ref)
  }
  done(fgeo.install::fgeo_packages, "All fgeo packages are installed.")

  follow_up()
}

install_needed_cran_packages <- function() {
  cat_line(cry_note("Installing fgeo dependencies from CRAN:"))
  utils::install.packages(pkgs = needed(fgeo.install::cran_packages))
  invisible()
}

install_needed_fgeo_packages <- function(ref = "master") {
  cat_line(cry_note("Installing needed fgeo packages from GitHub:"))
  repos <- paste0("forestgeo/", needed(fgeo.install::fgeo_packages))
  withr::with_envvar(
    c(GITHUB_PAT = .guest_pat),
    lapply(repos, try_install, ref)
  )

  invisible()
}

try_install <- function(repo, ref) {
  if (identical(ref, "master")) {
    return(install_ref(repo, ref))
  }

  tryCatch(
    install_ref(repo, ref),
    error = function(e) {
      warning(
        repo, "@", ref, " failed to install. ", "Trying ", repo, "@master",
        call. = FALSE
      )

      install_ref(repo, ref = "master")
    }
  )
}

install_ref <- function(repo, ref) {
  remotes::install_github(
    repo = repo,
    ref = ref,
    updgrade = "never",
    auth_token = .guest_pat
  )
}

# Helpers -----------------------------------------------------------------

inform_expected_r_environment <- function() {
  cat_line(cry_note(crayon::bold("Expected R environment:")))
  cat_line(cry_note("* R version is recent"))
  cat_line(
    cry_note("* All packages are updated (run "),
    cry_code("`update.packages()`"),
    cry_note(")")
  )
  cat_line(cry_note("* No other R session is running"))
  cat_line(
    cry_note("* Current R session is clean (click "),
    cry_note(crayon::italic("Session > Restart R")), cry_note(")")
  )

  invisible()
}

all_installed <- function(pkgs) {
  identical(pkgs, character(0))
}

needed <- function(pkgs) {
  installed <- unname(rownames(utils::installed.packages()))
  setdiff(basename(pkgs), installed)
}

done <- function(x, msg) {
  if (all_installed(needed(x))) {
    cat_line(cry_done(msg))
  }

  invisible()
}

follow_up <- function() {
  cat_line(cry_note("Next you may run "), cry_code("`?fgeo.install::follow_up`"))
  invisible()
}
