path = require 'path'
archive = require 'ls-archive'
{Model, File, fs} = require 'atom'

module.exports=
class ArchiveEditor extends Model
  atom.deserializers.add(this)

  @activate: ->
    atom.project.registerOpener (filePath) ->
      atom.create(new ArchiveEditor(path: filePath)) if archive.isPathSupported(filePath)

  @properties
    path: null

  @behavior 'relativePath', ->
    @$path.map (path) -> atom.project.relativize(path)

  created: ->
    unless fs.isFileSync(@path)
      console.warn "Could not build archive editor for path '#{@path}' because that file no longer exists"
      @destroy()
    @file = new File(@path)

  destroyed: ->
    @file?.off()

  # Deprecated: This can be removed once pane items are fully managed by telepath
  serialize: -> this

  getViewClass: -> require './archive-editor-view'

  getTitle: ->
    if @path?
      path.basename(@path)
    else
      'untitled'

  getUri: -> @relativePath

  isEqual: (other) ->
    other instanceof ArchiveEditor and @getUri() is other.getUri()
