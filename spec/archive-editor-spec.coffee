{Document} = require 'atom'
ArchiveEditor = require '../lib/archive-editor'

describe "ArchiveEditor", ->
  it "destroys itself upon creation if no file exists at the given path", ->
    doc = Document.create()
    doc.set('archiveEditor', new ArchiveEditor(path: "bogus"))
    expect(doc.has('imageEditor')).toBe false
