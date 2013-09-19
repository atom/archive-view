{View} = require 'atom'
FileView = require './file-view'

module.exports =
class DirectoryView extends View
  @content: (archivePath, entry) ->
    @li class: 'list-nested-item entry', =>
      @span class: 'list-item', =>
        @span entry.getName(), class: 'directory icon icon-file-directory'
      @ol class: 'list-tree', outlet: 'entries'

  initialize: (archivePath, entry) ->
    for child in entry.children
      if child.isDirectory()
        @entries.append(new DirectoryView(archivePath, child))
      else
        @entries.append(new FileView(archivePath, child))
