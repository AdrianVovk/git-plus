git = require '../git'

<<<<<<< HEAD
module.exports = (repo, {addAll}={}) ->
  if addAll
    git.add repo
=======
gitAdd = (repo, {addAll}={}) ->
  console.debug 'Repo for file is at', repo.getWorkingDirectory()
  if not addAll
    file = repo.relativize(atom.workspace.getActiveTextEditor()?.getPath())
>>>>>>> bf18bb2373b668e45674522b5ae23f87cbcb94fc
  else
    file = repo.relativize(atom.workspace.getActiveTextEditor()?.getPath())
    git.add(repo, file: file)
