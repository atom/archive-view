path = require 'path'

fs = require 'fs-plus'
Serializable = require 'serializable'
{Emitter, File} = require 'atom'

isPathSupported = (filePath) ->
  switch path.extname(filePath)
    when '.egg', '.epub', '.jar', '.love', '.nupkg', '.tar', '.tgz', '.war', '.whl', '.xpi', '.zip'
      return true
    when '.gz'
      return path.extname(path.basename(filePath, '.gz')) is '.tar'
    else
      return false

module.exports=
class ArchiveEditor extends Serializable
  @activate: ->
    atom.workspace.addOpener (filePath='') ->
      # Check that the file path exists before opening in case something like
      # an http: URI is being opened.
      if isPathSupported(filePath) and fs.isFileSync(filePath)
        new ArchiveEditor(path: filePath)

  constructor: ({path}) ->
    @file = new File(path)
    @emitter = new Emitter()

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
    @emitter.emit 'did-destroy'

  onDidDestroy: (callback) ->
    @emitter.on 'did-destroy', callback

  getViewClass: -> require './archive-editor-view'

  getTitle: ->
    if @getPath()?
      path.basename(@getPath())
    else
      'untitled'

  getURI: -> @getPath()

  isEqual: (other) ->
    other instanceof ArchiveEditor and @getURI() is other.getURI()

if parseFloat(atom.getVersion()) < 1.7
  atom.deserializers.add(ArchiveEditor)
