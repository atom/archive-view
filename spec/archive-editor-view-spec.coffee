{Disposable, File} = require 'atom'
{$} = require 'atom-space-pen-views'

describe "Archive viewer", ->
  [archiveView, onDidDeleteCallback, onDidChangeCallback] = []

  beforeEach ->
    spyOn(File::, 'onDidDelete').andCallFake (callback) ->
      onDidDeleteCallback = callback if @getPath().match /\.tar$/
      new Disposable

    spyOn(File::, 'onDidChange').andCallFake (callback) ->
      onDidChangeCallback = callback if @getPath().match /\.tar$/
      new Disposable

    waitsForPromise ->
      atom.packages.activatePackage('archive-view')

    waitsForPromise ->
      atom.workspace.open('nested.tar')

    runs ->
      archiveView = $(atom.views.getView(atom.workspace.getActivePaneItem())).view()

  describe ".initialize()", ->
    it "displays the files and folders in the archive file", ->
      expect(archiveView).toExist()

      waitsFor -> archiveView.find('.entry').length > 0

      runs ->
        expect(archiveView.find('.directory').length).toBe 6
        expect(archiveView.find('.directory:eq(0)').text()).toBe 'd1'
        expect(archiveView.find('.directory:eq(1)').text()).toBe 'd2'
        expect(archiveView.find('.directory:eq(2)').text()).toBe 'd3'
        expect(archiveView.find('.directory:eq(3)').text()).toBe 'd4'
        expect(archiveView.find('.directory:eq(4)').text()).toBe 'da'
        expect(archiveView.find('.directory:eq(5)').text()).toBe 'db'

        expect(archiveView.find('.file').length).toBe 3
        expect(archiveView.find('.file:eq(0)').text()).toBe 'f1.txt'
        expect(archiveView.find('.file:eq(1)').text()).toBe 'f2.txt'
        expect(archiveView.find('.file:eq(2)').text()).toBe 'fa.txt'

    it "selects the first file", ->
      waitsFor -> archiveView.find('.entry').length > 0
      runs -> expect(archiveView.find('.selected').text()).toBe 'f1.txt'

  describe "when core:move-up/core:move-down is triggered", ->
    it "selects the next/previous file", ->
      waitsFor -> archiveView.find('.entry').length > 0

      runs ->
        atom.commands.dispatch archiveView.find('.selected')[0], 'core:move-up'
        expect(archiveView.find('.selected').text()).toBe 'f1.txt'
        atom.commands.dispatch archiveView.find('.selected')[0], 'core:move-down'
        expect(archiveView.find('.selected').text()).toBe 'f2.txt'
        atom.commands.dispatch archiveView.find('.selected')[0], 'core:move-down'
        expect(archiveView.find('.selected').text()).toBe 'fa.txt'
        atom.commands.dispatch archiveView.find('.selected')[0], 'core:move-down'
        expect(archiveView.find('.selected').text()).toBe 'fa.txt'
        atom.commands.dispatch archiveView.find('.selected')[0], 'core:move-up'
        expect(archiveView.find('.selected').text()).toBe 'f2.txt'
        atom.commands.dispatch archiveView.find('.selected')[0], 'core:move-up'
        expect(archiveView.find('.selected').text()).toBe 'f1.txt'

  describe "when a file is clicked", ->
    it "copies the contents to a temp file and opens it in a new editor", ->
      waitsFor ->
        archiveView.find('.entry').length > 0

      runs ->
        archiveView.find('.file:eq(2)').trigger 'click'

      waitsFor ->
        atom.workspace.getActivePane().getItems().length > 1

      runs ->
        expect(atom.workspace.getActivePaneItem().getText()).toBe 'hey there\n'
        expect(atom.workspace.getActivePaneItem().getTitle()).toBe 'fa.txt'

  describe "when core:confirm is triggered", ->
    it "copies the contents to a temp file and opens it in a new editor", ->
      waitsFor ->
        archiveView.find('.entry').length > 0

      runs ->
        atom.commands.dispatch archiveView.find('.file:eq(0)')[0], 'core:confirm'

      waitsFor ->
        atom.workspace.getActivePane().getItems().length > 1

      runs ->
        expect(atom.workspace.getActivePaneItem().getText()).toBe ''
        expect(atom.workspace.getActivePaneItem().getTitle()).toBe 'f1.txt'

  describe "when the file is removed", ->
    it "destroys the view", ->
      waitsFor ->
        archiveView.find('.entry').length > 0

      runs ->
        expect(atom.workspace.getActivePane().getItems().length).toBe 1
        onDidDeleteCallback()
        expect(atom.workspace.getActivePaneItem()).toBeUndefined()

  describe "when the file is modified", ->
    it "refreshes the view", ->
      waitsFor ->
        archiveView.find('.entry').length > 0

      runs ->
        spyOn(archiveView, 'refresh')
        onDidChangeCallback()
        expect(archiveView.refresh).toHaveBeenCalled()

  describe "when the file is invalid", ->
    beforeEach ->
      waitsForPromise ->
        atom.workspace.open('invalid.zip')

      runs ->
        archiveView = $(atom.views.getView(atom.workspace.getActivePaneItem())).view()
        jasmine.attachToDOM(atom.views.getView(atom.workspace))

    it "shows the error", ->
      waitsFor ->
        archiveView.errorMessage.isVisible()

      runs ->
        expect(archiveView.errorMessage.text().length).toBeGreaterThan 0
