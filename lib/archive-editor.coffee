path = require 'path'

{File} = require 'pathwatcher'
fs = require 'fs-plus'
Serializable = require 'serializable'

isPathSupported = (filePath) ->
  switch path.extname(filePath)
    when '.epub', '.jar', '.love', '.tar', '.tgz', '.war', '.zip'
      return true
    when '.gz'
      return path.extname(path.basename(filePath, '.gz')) is '.tar'
    else
      return false

module.exports=
class ArchiveEditor extends Serializable
  atom.deserializers.add(this)

  @activate: ->
    atom.workspace.addOpener (filePath='') ->
      # Check that the file path exists before opening in case something like
      # an http: URI is being opened.
      if isPathSupported(filePath) and fs.isFileSync(filePath)
        new ArchiveEditor(path: filePath)

  constructor: ({path}) ->
    @file = new File(path)

  serializeParams: ->
    path: @getPath()

  deserializeParams: (params={}) ->
    if fs.isFileSync(params.path)
      params
    else
      console.warn "Could not build archive editor for path '#{params.path}' because that file no longer exists"

  getPath: ->
    @file.getPath()

  destroy: ->
    @file?.off()

  getViewClass: -> require './archive-editor-view'

  getTitle: ->
    if @getPath()?
      path.basename(@getPath())
    else
      'untitled'

  getURI: -> @getPath()

  isEqual: (other) ->
    other instanceof ArchiveEditor and @getURI() is other.getURI()
