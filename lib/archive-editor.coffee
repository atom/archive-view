path = require 'path'
url = require 'url'

{allowUnsafeNewFunction} = require 'loophole'
archive = allowUnsafeNewFunction -> require 'ls-archive'
{File} = require 'pathwatcher'
fs = require 'fs-plus'
Serializable = require 'serializable'

module.exports=
class ArchiveEditor extends Serializable
  atom.deserializers.add(this)

  @activate: ->
    atom.workspace.registerOpener (filePath='') ->
      # Don't open URIs with a protocol such as http:
      if not url.parse(filePath).protocol and archive.isPathSupported(filePath)
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

  getUri: -> @getPath()

  isEqual: (other) ->
    other instanceof ArchiveEditor and @getUri() is other.getUri()
