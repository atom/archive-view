path = require 'path'

_ = require 'underscore'
archive = require 'ls-archive'
telepath = require 'telepath'

fsUtils = require 'fs-utils'
File = require 'file'

module.exports=
class ArchiveEditSession
  @acceptsDocuments: true
  registerDeserializer(this)
  @version: 1

  @activate: ->
    Project = require 'project'
    Project.registerOpener (filePath) ->
      new ArchiveEditSession(path: filePath) if archive.isPathSupported(filePath)

  @deserialize: (state) ->
    relativePath = state.get('relativePath')
    resolvedPath = project.resolve(relativePath) if relativePath
    if fsUtils.isFileSync(resolvedPath)
      new ArchiveEditSession(state)
    else
      console.warn "Could not build archive edit session for path '#{relativePath}' because that file no longer exists"

  constructor: (optionsOrState) ->
    if optionsOrState instanceof telepath.Document
      @state = optionsOrState
      resolvedPath = project.resolve(@getRelativePath())
    else
      resolvedPath = optionsOrState.path
      @state = site.createDocument
        deserializer: @constructor.name
        version: @constructor.version
        relativePath: project.relativize(resolvedPath)

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
