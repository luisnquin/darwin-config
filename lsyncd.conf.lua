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

    -- untracked-on-rose files are invisible to the flake build; keep .git local
    -- to rose and it stays a real repo. To make rose an exact mirror instead,
    -- remove ".git/" from this list (see notes when handing off).
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
