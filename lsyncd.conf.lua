settings {
    logfile    = "/tmp/lsyncd-darwin-config.log",
    statusFile = "/tmp/lsyncd-darwin-config.status",
    nodaemon   = false,
    insist     = true,
}

sync {
    default.rsyncssh,

    source    = "/home/luisnquin/Projects/github.com/luisnquin/darwin-config",
    host      = "rose",
    targetdir = "/Users/luisnquin/.dotfiles",

    delay     = 1,

    -- .git/ is mirrored on purpose: rose's flake build only evaluates files its
    -- own index tracks, so shipping the index is what makes uncommitted work
    -- buildable there. Add ".git/" below to leave rose's repo state alone.
    exclude   = {
        ".claude/",
        ".direnv/",
        "result",
        "result-*",
        "*.swp",
        "*.tmp",
    },

    rsync     = {
        archive  = true,
        compress = true,
        perms    = true,
        owner    = false,          -- do not map linux uid/gid onto macOS
        group    = false,
        _extra   = { "--delete" }, -- mirror deletions; excluded paths are safe
    },
}
