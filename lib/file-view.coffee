path = require 'path'
{$, View} = require 'atom-space-pen-views'
fs = require 'fs-plus'
temp = require 'temp'
archive = require 'ls-archive'

FileIcons = require './file-icons'

module.exports =
class FileView extends View
  @content: (archivePath, entry) ->
    @li class: 'list-item entry', tabindex: -1, =>
      @span entry.getName(), class: 'file icon', outlet: 'name'

  initialize: (@archivePath, @entry) ->
    typeClass = FileIcons.getService().iconClassForPath(@entry.path, "archive-view") or []
    unless Array.isArray typeClass
      typeClass = typeClass?.toString().split(/\s+/g)
    
    @name.addClass(typeClass.join(" "))

    @on 'click', =>
      @select()
      @openFile()

    atom.commands.add @element,
      'core:confirm': =>
        @openFile() if @isSelected()

      'core:move-down': =>
        if @isSelected()
          files = @closest('.archive-editor').find('.file')
          $(files[files.index(@name) + 1]).view()?.select()

      'core:move-up': =>
        if @isSelected()
          files = @closest('.archive-editor').find('.file')
          $(files[files.index(@name) - 1]).view()?.select()

  isSelected: -> @hasClass('selected')

  logError: (message, error) ->
    console.error(message, error.stack ? error)

  openFile: ->
    archive.readFile @archivePath, @entry.getPath(), (error, contents) =>
      if error?
        @logError("Error reading: #{@entry.getPath()} from #{@archivePath}", error)
      else
        temp.mkdir 'atom-', (error, tempDirPath) =>
          if error?
            @logError("Error creating temp directory: #{tempDirPath}", error)
          else
            tempFilePath = path.join(tempDirPath, path.basename(@archivePath), @entry.getName())
            fs.writeFile tempFilePath, contents, (error) =>
              if error?
                @logError("Error writing to #{tempFilePath}", error)
              else
                atom.workspace.open(tempFilePath)

  select: ->
    @closest('.archive-editor').find('.selected').toggleClass('selected')
    @addClass('selected')
    @focus()
