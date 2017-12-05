path = require 'path'
ArchiveEditor = require '../lib/archive-editor'

describe "ArchiveEditor", ->
  describe ".deserialize", ->
    it "returns undefined if no file exists at the given path", ->
      spyOn(console, 'warn') # Don't log during specs
      editor1 = new ArchiveEditor(path: path.join(__dirname, 'fixtures', 'nested.tar'))
      state = editor1.serialize()
      editor1.destroy()

      editor2 = ArchiveEditor.deserialize(state)
      expect(editor2).toBeDefined()
      editor2.destroy()

      state.path = 'bogus'
      expect(ArchiveEditor.deserialize(state)).toBeUndefined()

  describe ".copy()", ->
    it "returns a new ArchiveEditor for the same file", ->
      editor = new ArchiveEditor(path: path.join(__dirname, 'fixtures', 'nested.tar'))
      newEditor = editor.copy()
      expect(newEditor.getPath()).toBe(editor.getPath())
