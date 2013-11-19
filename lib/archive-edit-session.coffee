path = require 'path'
archive = require 'ls-archive'
{Document, File, fs} = require 'atom'

module.exports=
class ArchiveEditSession
  @acceptsDocuments: true
  atom.deserializers.add(this)
  @version: 1

  @activate: ->
    atom.project.registerOpener (filePath) ->
      new ArchiveEditSession(path: filePath) if archive.isPathSupported(filePath)

  @deserialize: (state) ->
    relativePath = state.get('relativePath')
    resolvedPath = atom.project.resolve(relativePath) if relativePath
    if fs.isFileSync(resolvedPath)
      new ArchiveEditSession(state)
    else
      console.warn "Could not build archive edit session for path '#{relativePath}' because that file no longer exists"

  constructor: (optionsOrState) ->
    if optionsOrState instanceof Document
      @state = optionsOrState
      resolvedPath = atom.project.resolve(@getRelativePath())
    else
      resolvedPath = optionsOrState.path
      @state = atom.site.createDocument
        deserializer: @constructor.name
        version: @constructor.version
        relativePath: atom.project.relativize(resolvedPath)

    @file = new File(resolvedPath)

  destroy: -> @file?.off()

  serialize: -> @state.clone()

  getState: -> @state

  getViewClass: -> require './archive-view'

  getTitle: ->
    if archivePath = @getPath()
      path.basename(archivePath)
    else
      'untitled'

  getUri: -> @getRelativePath()

  getRelativePath: -> @state.get('relativePath')

  getPath: -> @file.getPath()

  isEqual: (other) ->
    other instanceof ArchiveEditSession and @getUri() is other.getUri()
