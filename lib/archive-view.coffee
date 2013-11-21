{fs, ScrollView} = require 'atom'
humanize = require 'humanize-plus'
archive = require 'ls-archive'

FileView = require './file-view'
DirectoryView = require './directory-view'

module.exports =
class ArchiveView extends ScrollView
  @content: ->
    @div class: 'archive-view', tabindex: -1, =>
      @div class: 'archive-container', =>
        @div outlet: 'loadingMessage', class: 'loading-message text-info', 'Loading archive\u2026'
        @div class: 'inset-panel', =>
          @div outlet: 'summary', class: 'panel-heading'
          @ol outlet: 'tree', class: 'archive-tree padded list-tree has-collapsable-children'

  initialize: (editSession) ->
    super

    @setModel(editSession)

    @on 'focus', =>
      @focusSelectedFile()
      false

  setPath: (path) ->
    if path and @path isnt path
      @path = path
      @refresh()

  refresh: ->
    @summary.hide()
    @tree.hide()
    @loadingMessage.show()

    originalPath = @path
    archive.list @path, tree: true, (error, entries) =>
      return unless originalPath is @path

      if error?
        console.error("Error listing archive file: #{@path}", error.stack ? error)
      else
        @loadingMessage.hide()
        @createTreeEntries(entries)
        @updateSummary()

  createTreeEntries: (entries) ->
    @tree.empty()

    for entry in entries
      if entry.isDirectory()
        @tree.append(new DirectoryView(@path, entry))
      else
        @tree.append(new FileView(@path, entry))

    @tree.show()
    @tree.find('.file').view()?.select()

  updateSummary: ->
    fileCount = @tree.find('.file').length
    fileLabel = if fileCount is 1 then "1 file" else "#{humanize.intComma(fileCount)} files"

    directoryCount = @tree.find('.directory').length
    directoryLabel = if directoryCount is 1 then "1 folder" else "#{humanize.intComma(directoryCount)} folders"

    @summary.text("#{humanize.fileSize(fs.getSizeSync(@path))} with #{fileLabel} and #{directoryLabel}").show()

  focusSelectedFile: ->
    @tree.find('.selected').view()?.focus()

  focus: ->
    @focusSelectedFile()

  setModel: (editSession) ->
    @unsubscribe(@editSession) if @editSession
    if editSession
      @editSession = editSession
      @setPath(editSession.getPath())
      editSession.file.on 'contents-changed', =>
        @refresh()
      editSession.file.on 'removed', =>
        @parent('.item-views').parent('.pane').view()?.destroyItem(editSession)
