path = require 'path'
{Document} = require 'atom'
ArchiveEditor = require '../lib/archive-editor'

describe "ArchiveEditor", ->
  describe ".deserialize", ->
    it "returns undefined if no file exists at the given path", ->
      spyOn(console, 'warn') # Don't log during specs
      editor = new ArchiveEditor(path: path.join(__dirname, 'fixtures', 'nested.tar'))
      state = editor.serialize()
      expect(ArchiveEditor.deserialize(state)).toBeDefined()
      state.path = 'bogus'
      expect(ArchiveEditor.deserialize(state)).toBeUndefined()
