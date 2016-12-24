{CompositeDisposable}  = require 'atom'
{$}                    = require 'atom-space-pen-views'
git                    = require './git'
configurations         = require './config'
contextMenu            = require './context-menu'
OutputViewManager      = require './output-view-manager'
GitPaletteView         = require './views/git-palette-view'
GitAddContext          = require './models/context/git-add-context'
GitDiffContext         = require './models/context/git-diff-context'
GitAddAndCommitContext = require './models/context/git-add-and-commit-context'
GitBranch              = require './models/git-branch'
GitDeleteLocalBranch   = require './models/git-delete-local-branch'
GitDeleteRemoteBranch  = require './models/git-delete-remote-branch'
GitCheckoutAllFiles    = require './models/git-checkout-all-files'
GitCheckoutFile        = require './models/git-checkout-file'
GitCheckoutFileContext = require './models/context/git-checkout-file-context'
GitCherryPick          = require './models/git-cherry-pick'
GitCommit              = require './models/git-commit'
GitCommitAmend         = require './models/git-commit-amend'
GitDiff                = require './models/git-diff'
GitDifftool            = require './models/git-difftool'
GitDifftoolContext     = require './models/context/git-difftool-context'
GitDiffAll             = require './models/git-diff-all'
GitFetch               = require './models/git-fetch'
GitFetchPrune          = require './models/git-fetch-prune'
GitInit                = require './models/git-init'
GitLog                 = require './models/git-log'
GitPull                = require './models/git-pull'
GitPullContext         = require './models/context/git-pull-context'
GitPush                = require './models/git-push'
GitPushContext         = require './models/context/git-push-context'
GitRemove              = require './models/git-remove'
GitShow                = require './models/git-show'
GitStageFiles          = require './models/git-stage-files'
GitStageHunk           = require './models/git-stage-hunk'
GitStashApply          = require './models/git-stash-apply'
GitStashDrop           = require './models/git-stash-drop'
GitStashPop            = require './models/git-stash-pop'
GitStashSave           = require './models/git-stash-save'
GitStashSaveMessage    = require './models/git-stash-save-message'
GitStatus              = require './models/git-status'
GitTags                = require './models/git-tags'
GitUnstageFiles        = require './models/git-unstage-files'
GitUnstageFileContext  = require './models/context/git-unstage-file-context'
GitRun                 = require './models/git-run'
GitMerge               = require './models/git-merge'
GitRebase              = require './models/git-rebase'
GitOpenChangedFiles    = require './models/git-open-changed-files'
diffGrammars           = require './grammars/diff.js'

baseWordGrammar = __dirname + '/grammars/word-diff.json'
baseLineGrammar = __dirname + '/grammars/line-diff.json'

currentFile = (repo) ->
  repo.relativize(atom.workspace.getActiveTextEditor()?.getPath())

setDiffGrammar = ->
  while atom.grammars.grammarForScopeName 'source.diff'
    atom.grammars.removeGrammarForScopeName 'source.diff'

  enableSyntaxHighlighting = atom.config.get('git-support-ide').syntaxHighlighting
  wordDiff = atom.config.get('git-support-ide').wordDiff
  diffGrammar = null
  baseGrammar = null

  if wordDiff
    diffGrammar = diffGrammars.wordGrammar
    baseGrammar = baseWordGrammar
  else
    diffGrammar = diffGrammars.lineGrammar
    baseGrammar = baseLineGrammar

  if enableSyntaxHighlighting
    atom.grammars.addGrammar diffGrammar
  else
    grammar = atom.grammars.readGrammarSync baseGrammar
    grammar.packageName = 'git-support-ide'
    atom.grammars.addGrammar grammar

module.exports =
  config: configurations

  subscriptions: null

  activate: (state) ->
    setDiffGrammar()
    @subscriptions = new CompositeDisposable
    repos = atom.project.getRepositories().filter (r) -> r?
    if repos.length is 0
      @subscriptions.add atom.commands.add 'atom-workspace', 'git:init', => GitInit().then => @activate()
    else
      contextMenu()
      @subscriptions.add atom.commands.add 'atom-workspace', 'git:menu', -> new GitPaletteView()
      @subscriptions.add atom.commands.add 'atom-workspace', 'git:add', -> git.getRepo().then((repo) -> git.add(repo, file: currentFile(repo)))
      @subscriptions.add atom.commands.add 'atom-workspace', 'git:add-modified', -> git.getRepo().then((repo) -> git.add(repo, update: true))
      @subscriptions.add atom.commands.add 'atom-workspace', 'git:add-all', -> git.getRepo().then((repo) -> git.add(repo))
      @subscriptions.add atom.commands.add 'atom-workspace', 'git:commit', -> git.getRepo().then((repo) -> GitCommit(repo))
      @subscriptions.add atom.commands.add 'atom-workspace', 'git:commit-all', -> git.getRepo().then((repo) -> GitCommit(repo, stageChanges: true))
      @subscriptions.add atom.commands.add 'atom-workspace', 'git:commit-amend', -> git.getRepo().then((repo) -> new GitCommitAmend(repo))
      @subscriptions.add atom.commands.add 'atom-workspace', 'git:add-and-commit', -> git.getRepo().then((repo) -> git.add(repo, file: currentFile(repo)).then -> GitCommit(repo))
      @subscriptions.add atom.commands.add 'atom-workspace', 'git:add-and-commit-and-push', -> git.getRepo().then((repo) -> git.add(repo, file: currentFile(repo)).then -> GitCommit(repo, andPush: true))
      @subscriptions.add atom.commands.add 'atom-workspace', 'git:add-all-and-commit', -> git.getRepo().then((repo) -> git.add(repo).then -> GitCommit(repo))
      @subscriptions.add atom.commands.add 'atom-workspace', 'git:add-all-commit-and-push', -> git.getRepo().then((repo) -> git.add(repo).then -> GitCommit(repo, andPush: true))
      @subscriptions.add atom.commands.add 'atom-workspace', 'git:commit-all-and-push', -> git.getRepo().then((repo) -> GitCommit(repo, stageChanges: true, andPush: true))
      @subscriptions.add atom.commands.add 'atom-workspace', 'git:checkout', -> git.getRepo().then((repo) -> GitBranch.gitBranches(repo))
      @subscriptions.add atom.commands.add 'atom-workspace', 'git:checkout-remote', -> git.getRepo().then((repo) -> GitBranch.gitRemoteBranches(repo))
      @subscriptions.add atom.commands.add 'atom-workspace', 'git:checkout-current-file', -> git.getRepo().then((repo) -> GitCheckoutFile(repo, file: currentFile(repo)))
      @subscriptions.add atom.commands.add 'atom-workspace', 'git:checkout-all-files', -> git.getRepo().then((repo) -> GitCheckoutAllFiles(repo))
      @subscriptions.add atom.commands.add 'atom-workspace', 'git:new-branch', -> git.getRepo().then((repo) -> GitBranch.newBranch(repo))
      @subscriptions.add atom.commands.add 'atom-workspace', 'git:delete-local-branch', -> git.getRepo().then((repo) -> GitDeleteLocalBranch(repo))
      @subscriptions.add atom.commands.add 'atom-workspace', 'git:delete-remote-branch', -> git.getRepo().then((repo) -> GitDeleteRemoteBranch(repo))
      @subscriptions.add atom.commands.add 'atom-workspace', 'git:cherry-pick', -> git.getRepo().then((repo) -> GitCherryPick(repo))
      @subscriptions.add atom.commands.add 'atom-workspace', 'git:diff', -> git.getRepo().then((repo) -> GitDiff(repo, file: currentFile(repo)))
      @subscriptions.add atom.commands.add 'atom-workspace', 'git:difftool', -> git.getRepo().then((repo) -> GitDifftool(repo, file: currentFile(repo)))
      @subscriptions.add atom.commands.add 'atom-workspace', 'git:diff-all', -> git.getRepo().then((repo) -> GitDiffAll(repo))
      @subscriptions.add atom.commands.add 'atom-workspace', 'git:fetch', -> git.getRepo().then((repo) -> GitFetch(repo))
      @subscriptions.add atom.commands.add 'atom-workspace', 'git:fetch-prune', -> git.getRepo().then((repo) -> GitFetchPrune(repo))
      @subscriptions.add atom.commands.add 'atom-workspace', 'git:pull', -> git.getRepo().then((repo) -> GitPull(repo))
      @subscriptions.add atom.commands.add 'atom-workspace', 'git:push', -> git.getRepo().then((repo) -> GitPush(repo))
      @subscriptions.add atom.commands.add 'atom-workspace', 'git:push-set-upstream', -> git.getRepo().then((repo) -> GitPush(repo, setUpstream: true))
      @subscriptions.add atom.commands.add 'atom-workspace', 'git:remove', -> git.getRepo().then((repo) -> GitRemove(repo, showSelector: true))
      @subscriptions.add atom.commands.add 'atom-workspace', 'git:remove-current-file', -> git.getRepo().then((repo) -> GitRemove(repo))
      @subscriptions.add atom.commands.add 'atom-workspace', 'git:reset', -> git.getRepo().then((repo) -> git.reset(repo))
      @subscriptions.add atom.commands.add 'atom-workspace', 'git:show', -> git.getRepo().then((repo) -> GitShow(repo))
      @subscriptions.add atom.commands.add 'atom-workspace', 'git:log', -> git.getRepo().then((repo) -> GitLog(repo))
      @subscriptions.add atom.commands.add 'atom-workspace', 'git:log-current-file', -> git.getRepo().then((repo) -> GitLog(repo, onlyCurrentFile: true))
      @subscriptions.add atom.commands.add 'atom-workspace', 'git:stage-files', -> git.getRepo().then((repo) -> GitStageFiles(repo))
      @subscriptions.add atom.commands.add 'atom-workspace', 'git:unstage-files', -> git.getRepo().then((repo) -> GitUnstageFiles(repo))
      @subscriptions.add atom.commands.add 'atom-workspace', 'git:stage-hunk', -> git.getRepo().then((repo) -> GitStageHunk(repo))
      @subscriptions.add atom.commands.add 'atom-workspace', 'git:stash-save', -> git.getRepo().then((repo) -> GitStashSave(repo))
      @subscriptions.add atom.commands.add 'atom-workspace', 'git:stash-save-message', -> git.getRepo().then((repo) -> GitStashSaveMessage(repo))
      @subscriptions.add atom.commands.add 'atom-workspace', 'git:stash-pop', -> git.getRepo().then((repo) -> GitStashPop(repo))
      @subscriptions.add atom.commands.add 'atom-workspace', 'git:stash-apply', -> git.getRepo().then((repo) -> GitStashApply(repo))
      @subscriptions.add atom.commands.add 'atom-workspace', 'git:stash-delete', -> git.getRepo().then((repo) -> GitStashDrop(repo))
      @subscriptions.add atom.commands.add 'atom-workspace', 'git:status', -> git.getRepo().then((repo) -> GitStatus(repo))
      @subscriptions.add atom.commands.add 'atom-workspace', 'git:tags', -> git.getRepo().then((repo) -> GitTags(repo))
      @subscriptions.add atom.commands.add 'atom-workspace', 'git:run', -> git.getRepo().then((repo) -> new GitRun(repo))
      @subscriptions.add atom.commands.add 'atom-workspace', 'git:merge', -> git.getRepo().then((repo) -> GitMerge(repo))
      @subscriptions.add atom.commands.add 'atom-workspace', 'git:merge-remote', -> git.getRepo().then((repo) -> GitMerge(repo, remote: true))
      @subscriptions.add atom.commands.add 'atom-workspace', 'git:merge-no-fast-forward', -> git.getRepo().then((repo) -> GitMerge(repo, noFastForward: true))
      @subscriptions.add atom.commands.add 'atom-workspace', 'git:rebase', -> git.getRepo().then((repo) -> GitRebase(repo))
      @subscriptions.add atom.commands.add 'atom-workspace', 'git:git-open-changed-files', -> git.getRepo().then((repo) -> GitOpenChangedFiles(repo))
      @subscriptions.add atom.commands.add '.tree-view', 'git-context:add', -> GitAddContext()
      @subscriptions.add atom.commands.add '.tree-view', 'git-context:add-and-commit', -> GitAddAndCommitContext()
      @subscriptions.add atom.commands.add '.tree-view', 'git-context:checkout-file', -> GitCheckoutFileContext()
      @subscriptions.add atom.commands.add '.tree-view', 'git-context:diff', -> GitDiffContext()
      @subscriptions.add atom.commands.add '.tree-view', 'git-context:difftool', -> GitDifftoolContext()
      @subscriptions.add atom.commands.add '.tree-view', 'git-context:pull', -> GitPullContext()
      @subscriptions.add atom.commands.add '.tree-view', 'git-context:push', -> GitPushContext()
      @subscriptions.add atom.commands.add '.tree-view', 'git-context:push-set-upstream', -> GitPushContext(setUpstream: true)
      @subscriptions.add atom.commands.add '.tree-view', 'git-context:unstage-file', -> GitUnstageFileContext()
      @subscriptions.add atom.config.observe 'git-support-ide.syntaxHighlighting', setDiffGrammar
      @subscriptions.add atom.config.observe 'git-support-ide.wordDiff', setDiffGrammar

  deactivate: ->
    @subscriptions.dispose()

  consumeStatusBar: (statusBar) ->
    @setupBranchesMenuToggle statusBar
    if atom.config.get 'git-support-ide.enableStatusBarIcon'
      @setupOutputViewToggle statusBar

  consumeAutosave: ({dontSaveIf}) ->
    dontSaveIf (paneItem) -> paneItem.getPath().includes 'COMMIT_EDITMSG'

  setupOutputViewToggle: (statusBar) ->
    div = document.createElement 'div'
    div.classList.add 'inline-block'
    icon = document.createElement 'span'
    icon.classList.add 'icon', 'icon-pin'
    link = document.createElement 'a'
    link.appendChild icon
    link.onclick = (e) -> OutputViewManager.getView().toggle()
    atom.tooltips.add div, { title: "Toggle Git Output Console"}
    div.appendChild link
    @statusBarTile = statusBar.addRightTile item: div, priority: 0

  setupBranchesMenuToggle: (statusBar) ->
    statusBar.getRightTiles().some ({item}) =>
      if item?.classList?.contains? 'git-view'
        $(item).find('.git-branch').on 'click', ({altKey, shiftKey}) ->
          unless altKey or shiftKey
            atom.commands.dispatch(document.querySelector('atom-workspace'), 'git:checkout')
        return true
