{ScrollView} = require 'atom-space-pen-views'
fs = require 'fs-plus'
humanize = require 'humanize-plus'
archive = require 'ls-archive'
{CompositeDisposable} = require 'atom'

FileView = require './file-view'
DirectoryView = require './directory-view'

module.exports =
class ArchiveEditorView extends ScrollView
  @content: ->
    @div class: 'archive-editor', tabindex: -1, =>
      @div class: 'archive-container', =>
        @div outlet: 'loadingMessage', class: 'padded icon icon-hourglass text-info', 'Loading archive\u2026'
        @div outlet: 'errorMessage', class: 'padded icon icon-alert text-error'
        @div class: 'inset-panel', =>
          @div outlet: 'summary', class: 'panel-heading'
          @ol outlet: 'tree', class: 'archive-tree padded list-tree has-collapsable-children'

  initialize: (editor) ->
    commandDisposable = super()
    commandDisposable.dispose()

    @setModel(editor)

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
    @errorMessage.hide()

    originalPath = @path
    archive.list @path, tree: true, (error, entries) =>
      return unless originalPath is @path

      @loadingMessage.hide()
      if error?
        message = 'Reading the archive file failed'
        message += ": #{error.message}" if error.message
        @errorMessage.show().text(message)
      else
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

  setModel: (editor) ->
    @editorSubscriptions?.dispose()
    @editorSubscriptions = null

    if editor?
      @editorSubscriptions = new CompositeDisposable()
      @editor = editor
      @setPath(editor.getPath())
      @editorSubscriptions.add editor.file.onDidChange =>
        @refresh()
      @editorSubscriptions.add editor.file.onDidDelete =>
        atom.workspace.paneForItem(@editor)?.destroyItem(@editor)
      @editorSubscriptions.add editor.onDidDestroy =>
        @editorSubscriptions?.dispose()
        @editorSubscriptions = null
