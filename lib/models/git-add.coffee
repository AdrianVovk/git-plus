git = require '../git'

gitAdd = (repo, {addAll}={}) ->
  console.debug 'Repo for file is at', repo.getWorkingDirectory()
  if not addAll
    file = repo.relativize(atom.workspace.getActiveTextEditor()?.getPath())
  else
    file = repo.relativize(atom.workspace.getActiveTextEditor()?.getPath())
    git.add(repo, file: file)
