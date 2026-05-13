use lib/common.nu [resolve-project-root load-config]
use lib/repos.nu [run-repo-stage]
use lib/packages.nu [run-package-stage]
use lib/system.nu [run-system-stage]

export def main [build_root?: string, --dry-run(-n)] {
  let root = if ($build_root | is-not-empty) {
    $build_root
  } else {
    resolve-project-root
  }

  let cfg = load-config $root

  print $"==> using build root: ($root)"
  if $dry_run {
    print "==> mode: dry-run"
  }

  run-repo-stage $dry_run $cfg.repos
  run-package-stage $dry_run $cfg.packages $cfg.extras
  run-system-stage $dry_run $cfg.system
}
