path = require 'path'
ArchiveEditor = require '../lib/archive-editor'
ArchiveEditorView = require '../lib/archive-editor-view'

describe "ArchiveEditor", ->
  describe ".deserialize", ->
    it "returns undefined if no file exists at the given path", ->
      spyOn(console, 'warn') # Don't log during specs
      editor1 = new ArchiveEditorView(path.join(__dirname, 'fixtures', 'nested.tar'))
      state = editor1.serialize()
      editor1.destroy()

      editor2 = ArchiveEditor.deserialize(state)
      expect(editor2).toBeDefined()
      editor2.destroy()

      state.path = 'bogus'
      expect(ArchiveEditor.deserialize(state)).toBeUndefined()

  describe ".deactivate()", ->
    it "removes all ArchiveEditorViews from the workspace and does not open any new ones", ->
      waitsForPromise -> atom.packages.activatePackage('archive-view')
      waitsForPromise -> atom.workspace.open(path.join(__dirname, 'fixtures', 'nested.tar'))
      waitsForPromise -> atom.workspace.open(path.join(__dirname, 'fixtures', 'invalid.zip'))
      waitsForPromise -> atom.workspace.open()

      runs ->
        expect(atom.workspace.getPaneItems().filter((item) -> item instanceof ArchiveEditorView).length).toBe(2)

      waitsForPromise -> atom.packages.deactivatePackage('archive-view')

      runs ->
        expect(atom.workspace.getPaneItems().filter((item) -> item instanceof ArchiveEditorView).length).toBe(0)

      waitsForPromise -> atom.workspace.open(path.join(__dirname, 'fixtures', 'nested.tar'))

      runs ->
        expect(atom.workspace.getPaneItems().filter((item) -> item instanceof ArchiveEditorView).length).toBe(0)
