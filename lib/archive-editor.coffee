path = require 'path'
archive = require 'ls-archive'
{File} = require 'pathwatcher'
fs = require 'fs-plus'
Serializable = require 'serializable'

module.exports=
class ArchiveEditor extends Serializable
  atom.deserializers.add(this)

  @activate: ->
    atom.project.registerOpener (filePath) ->
      new ArchiveEditor(path: filePath) if archive.isPathSupported(filePath)

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

  getUri: -> @getPath()

  isEqual: (other) ->
    other instanceof ArchiveEditor and @getUri() is other.getUri()
