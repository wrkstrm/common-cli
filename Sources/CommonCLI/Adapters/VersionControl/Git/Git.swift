import CommonProcess
import CommonShell

/// Minimal async wrapper around the `git` tool with common operations.
public struct Git: CLI, Versioned {
  /// Executable identity for invoking `git` directly.
  public static let executable: Executable = .name("git")
  /// Base shell context.
  public var shell: CommonShell

  /// Initialize with a base shell and disable the shell wrapper.
  public init(shell: CommonShell) {
    // Preserve the caller's shell context (cwd/logging/backend). Bind to git spec.
    self.shell = shell
  }

  /// Run an arbitrary git subcommand and return stdout.
  public func run(_ args: [String]) async throws -> String {
    try await shell.runConfigured(executable: Self.executable, arguments: args)
  }

  /// Show the commit log.
  public func log(format: String = "%H %ci", reverse: Bool = true) async throws -> String {
    var args = ["log", "--format=\(format)"]
    if reverse { args.append("--reverse") }
    return try await run(args)
  }

  /// Reset the current HEAD. When hard is true, discards changes.
  public func reset(hard: Bool = true) async throws -> String {
    var args = ["reset"]
    if hard { args.append("--hard") }
    return try await run(args)
  }

  /// Clean untracked files. When fdX is true, passes -fdx.
  public func clean(fdX: Bool = true) async throws -> String {
    var args = ["clean"]
    if fdX { args.append(contentsOf: ["-fdx"]) }
    return try await run(args)
  }

  /// Initialize and update all submodules recursively.
  public func submoduleUpdateInitRecursive() async throws -> String {
    try await run(["submodule", "update", "--init", "--recursive"])
  }

  /// Clean untracked files in all submodules.
  public func cleanSubmodules() async throws -> String {
    try await run(["submodule", "foreach", "git", "clean", "-fdx"])
  }

  /// Checkout a ref (branch, tag, or commit).
  public func checkout(_ ref: String) async throws -> String {
    try await run(["checkout", ref])
  }

  /// Stash current changes.
  public func stash() async throws -> String { try await run(["stash"]) }

  /// Show working tree status; when porcelain is true, prints machine-parseable output.
  public func status(porcelain: Bool = true) async throws -> String {
    var args = ["status"]
    if porcelain { args.append("--porcelain") }
    return try await run(args)
  }

  /// Return the current branch name.
  public func currentBranch() async throws -> String {
    try await run(["rev-parse", "--abbrev-ref", "HEAD"]).trimmed()
  }

  /// Create a new branch; optionally check it out.
  public func createBranch(_ name: String, checkout: Bool = false) async throws -> String {
    if checkout { return try await run(["checkout", "-b", name]) }
    return try await run(["branch", name])
  }

  /// List branches; when all is true, includes remote branches.
  public func branches(all: Bool = false) async throws -> String {
    var args = ["branch", "--list"]
    if all { args.append("--all") }
    return try await run(args)
  }

  /// List tags; an optional glob pattern can filter results.
  public func tags(pattern: String? = nil) async throws -> String {
    var args = ["tag", "--list"]
    if let pattern { args.append(pattern) }
    return try await run(args)
  }

  /// Create a tag (lightweight by default); when annotated, pass a message.
  public func createTag(_ name: String, annotated: Bool = false, message: String? = nil)
    async throws -> String
  {
    var args = ["tag"]
    if annotated { args.append("-a") }
    if let message { args += ["-m", message] }
    args.append(name)
    return try await run(args)
  }

  // MARK: - Merge & history

  /// Merge a branch or commit into the current branch.
  public func merge(_ ref: String, noFF: Bool = false, message: String? = nil) async throws
    -> String
  {
    var args = ["merge"]
    if noFF { args.append("--no-ff") }
    if let message { args += ["-m", message] }
    args.append(ref)
    return try await run(args)
  }

  /// Cherry-pick a commit (or range) onto the current branch.
  public func cherryPick(_ ref: String, noCommit: Bool = false, signoff: Bool = false) async throws
    -> String
  {
    var args = ["cherry-pick"]
    if noCommit { args.append("--no-commit") }
    if signoff { args.append("--signoff") }
    args.append(ref)
    return try await run(args)
  }

  /// Revert a commit, creating a new commit that undoes it.
  public func revert(_ ref: String, noCommit: Bool = false) async throws -> String {
    var args = ["revert"]
    if noCommit { args.append("--no-commit") }
    args.append(ref)
    return try await run(args)
  }

  // MARK: - Network

  /// Fetch updates from a remote. Optionally pass a refspec; you can also prune or fetch all tags.
  public func fetch(
    remote: String? = nil, refspec: String? = nil, prune: Bool = false, tags: Bool = false,
  ) async throws -> String {
    var args = ["fetch"]
    if prune { args.append("--prune") }
    if tags { args.append("--tags") }
    if let remote { args.append(remote) }
    if let refspec { args.append(refspec) }
    return try await run(args)
  }

  /// Pull updates for the given remote/branch. When rebase is true, performs `--rebase`.
  public func pull(remote: String? = nil, branch: String? = nil, rebase: Bool = false) async throws
    -> String
  {
    var args = ["pull"]
    if rebase { args.append("--rebase") }
    if let remote { args.append(remote) }
    if let branch { args.append(branch) }
    return try await run(args)
  }

  /// Push a branch to the given remote. Supports --force, --tags and setting upstream.
  public func push(
    remote: String? = nil, branch: String? = nil, force: Bool = false, tags: Bool = false,
    setUpstream: Bool = false,
  ) async throws -> String {
    var args = ["push"]
    if force { args.append("--force") }
    if tags { args.append("--tags") }
    if setUpstream { args.append("--set-upstream") }
    if let remote { args.append(remote) }
    if let branch { args.append(branch) }
    return try await run(args)
  }

  // MARK: - Delete ops

  /// Delete a branch (local by default). When remote is true, issues `push <remote> --delete <branch>`.
  public func deleteBranch(_ name: String, remote: String? = nil) async throws -> String {
    if let remote {
      return try await run(["push", remote, "--delete", name])
    }
    return try await run(["branch", "-D", name])
  }

  /// Delete a tag (local) and optionally from a remote.
  public func deleteTag(_ name: String, remote: String? = nil) async throws -> String {
    _ = try await run(["tag", "-d", name])
    if let remote {
      return try await run(["push", remote, ":refs/tags/\(name)"])
    }
    return ""
  }

  // MARK: - Remote operations

  /// Add a remote with the given name and url.
  public func remoteAdd(name: String, url: String) async throws -> String {
    try await run(["remote", "add", name, url])
  }

  /// Remove a remote.
  public func remoteRemove(name: String) async throws -> String {
    try await run(["remote", "remove", name])
  }

  /// Set the URL for a remote; when push is true, sets the push URL, else fetch URL.
  public func remoteSetURL(name: String, url: String, push: Bool = false) async throws -> String {
    var args = ["remote", "set-url"]
    if push { args.append("--push") }
    args += [name, url]
    return try await run(args)
  }

  /// List remotes; when verbose is true, includes URLs.
  public func remotes(verbose: Bool = false) async throws -> String {
    var args = ["remote"]
    if verbose { args.append("-v") }
    return try await run(args)
  }

  /// Prune stale remote-tracking branches.
  public func remotePrune(name: String) async throws -> String {
    try await run(["remote", "prune", name])
  }

  /// Rename a remote.
  public func remoteRename(old: String, new: String) async throws -> String {
    try await run(["remote", "rename", old, new])
  }

  // MARK: - Stash helpers

  /// List stashes.
  public func stashList() async throws -> String { try await run(["stash", "list"]) }

  /// Apply a stash by reference (e.g., "stash@{0}"). When index is nil, applies the latest.
  public func stashApply(index: String? = nil) async throws -> String {
    var args = ["stash", "apply"]
    if let index { args.append(index) }
    return try await run(args)
  }

  /// Drop a stash by reference (e.g., "stash@{0}"). When index is nil, drops the latest.
  public func stashDrop(index: String? = nil) async throws -> String {
    var args = ["stash", "drop"]
    if let index { args.append(index) }
    return try await run(args)
  }
}

extension String {
  fileprivate func trimmed() -> String { trimmingCharacters(in: .whitespacesAndNewlines) }
}

extension CommonShell { public var git: Git { .init(shell: self) } }

// MARK: - Typed CommandSpec builders

extension Git {
  /// Build a CommandSpec for `git clone`.
  public static func clone(
    noLocal: Bool = true,
    noHardlinks: Bool = true,
    source: String,
    destination: String,
    workingDirectory: String
  ) -> CommandSpec {
    var args = ["clone"]
    if noLocal { args.append("--no-local") }
    if noHardlinks { args.append("--no-hardlinks") }
    args.append(contentsOf: [source, destination])
    return CommandSpec(
      executable: Self.executable,
      args: args,
      workingDirectory: workingDirectory
    )
  }

  /// Build a CommandSpec for `git filter-repo`.
  public static func filterRepo(
    path: String,
    pathRename: String? = nil,
    force: Bool = true,
    workingDirectory: String
  ) -> CommandSpec {
    var args = ["filter-repo", "--path", path]
    if let pathRename { args += ["--path-rename", pathRename] }
    if force { args.append("--force") }
    return CommandSpec(
      executable: Self.executable,
      args: args,
      workingDirectory: workingDirectory
    )
  }

  /// Build a CommandSpec for `git filter-repo --subdirectory-filter <subdir>`.
  /// This rewrites history so that the provided subdirectory becomes the repository root.
  public static func filterRepoSubdirectory(
    subdirectory: String,
    force: Bool = true,
    workingDirectory: String
  ) -> CommandSpec {
    var args = ["filter-repo", "--subdirectory-filter", subdirectory]
    if force { args.append("--force") }
    return CommandSpec(
      executable: Self.executable,
      args: args,
      workingDirectory: workingDirectory
    )
  }

  /// `git remote remove <name>`
  public static func remoteRemove(name: String, workingDirectory: String) -> CommandSpec {
    CommandSpec(
      executable: Self.executable,
      args: ["remote", "remove", name],
      workingDirectory: workingDirectory
    )
  }

  /// `git remote add <name> <url>`
  public static func remoteAdd(name: String, url: String, workingDirectory: String) -> CommandSpec {
    CommandSpec(
      executable: Self.executable,
      args: ["remote", "add", name, url],
      workingDirectory: workingDirectory
    )
  }

  /// `git push [-u] <remote> --all`
  public static func pushAll(
    setUpstream: Bool = true,
    remote: String,
    workingDirectory: String
  ) -> CommandSpec {
    var args = ["push"]
    if setUpstream { args.append("-u") }
    args += [remote, "--all"]
    return CommandSpec(
      executable: Self.executable,
      args: args,
      workingDirectory: workingDirectory
    )
  }

  /// `git push [-u] <remote> --tags`
  public static func pushTags(
    setUpstream: Bool = true,
    remote: String,
    workingDirectory: String
  ) -> CommandSpec {
    var args = ["push"]
    if setUpstream { args.append("-u") }
    args += [remote, "--tags"]
    return CommandSpec(
      executable: Self.executable,
      args: args,
      workingDirectory: workingDirectory
    )
  }

  /// `git rm [-r] <path>`
  public static func rm(
    recursive: Bool = true,
    path: String,
    workingDirectory: String
  ) -> CommandSpec {
    var args = ["rm"]
    if recursive { args.append("-r") }
    args.append(path)
    return CommandSpec(
      executable: Self.executable,
      args: args,
      workingDirectory: workingDirectory
    )
  }

  /// `git submodule add -b <branch> <url> <path>`
  public static func submoduleAdd(
    branch: String,
    url: String,
    path: String,
    workingDirectory: String
  )
    -> CommandSpec
  {
    CommandSpec(
      executable: Self.executable,
      args: ["submodule", "add", "-b", branch, url, path],
      workingDirectory: workingDirectory
    )
  }
}
