export def print-step [message: string] {
  print $"\n==> ($message)"
}

export def print-bullets [items] {
  for item in $items {
    print $"  - ($item)"
  }
}

export def preview-command [cmd: string, args] {
  let rendered = ([ $cmd ] | append $args | flatten | str join " ")
  print $"DRY-RUN: ($rendered)"
}

export def run-cmd [dry_run: bool, cmd: string, args] {
  if $dry_run {
    preview-command $cmd $args
  } else {
    run-external $cmd ...$args
  }
}

export def resolve-project-root [] {
  let candidates = [
    "/tmp/build"
    "build"
    "./build"
  ]

  for candidate in $candidates {
    if ($candidate | path exists) {
      return $candidate
    }
  }

  print $"unable to locate build directory, tried: ($candidates | str join ', ')"
  exit 1
}

export def load-config [build_root: string] {
  {
    repos: (open $"($build_root)/config/repos.nuon")
    packages: (open $"($build_root)/config/packages.nuon")
    extras: (open $"($build_root)/config/extras.nuon")
    system: (open $"($build_root)/config/system.nuon")
  }
}

export def dnf-clean [dry_run: bool] {
  run-cmd $dry_run "dnf" ["clean" "all"]
}

export def dnf-install-lean [dry_run: bool, packages] {
  if (($packages | length) == 0) {
    return
  }

  print $"  package-count: ($packages | length)"
  print-bullets $packages
  run-cmd $dry_run "dnf" ["install" "-y" "--setopt=install_weak_deps=False" "--nodocs" ...$packages]
}

export def strip-version-prefix [tag: string, prefix: string] {
  if (($prefix | str length) == 0) {
    $tag
  } else if ($tag | str starts-with $prefix) {
    $tag | str replace $prefix ""
  } else {
    $tag
  }
}
