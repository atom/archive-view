const path = require('path')
const ArchiveEditor = require('../lib/archive-editor')

describe('ArchiveEditor', () => {
  const tarPath = path.join(__dirname, 'fixtures', 'nested.tar')

  // Don't log during specs
  beforeEach(() => spyOn(console, 'warn'))

  describe('.deserialize', () => {
    it('returns undefined if no file exists at the given path', () => {
      const editor1 = new ArchiveEditor({ path: tarPath })
      const state = editor1.serialize()
      editor1.destroy()

      const editor2 = ArchiveEditor.deserialize(state)
      expect(editor2).toBeDefined()
      editor2.destroy()

      state.path = 'bogus'
      expect(ArchiveEditor.deserialize(state)).toBeUndefined()
    })
  })

  describe('.copy()', () => {
    it('returns a new ArchiveEditor for the same file', () => {
      const oldEditor = new ArchiveEditor({ path: tarPath })
      const newEditor = oldEditor.copy()
      expect(newEditor.getPath()).toBe(oldEditor.getPath())
    })
  })
})
