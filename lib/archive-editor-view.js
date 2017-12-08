/** @babel */
/** @jsx etch.dom */

import fs from 'fs-plus'
import humanize from 'humanize-plus'
import archive from 'ls-archive'
import {CompositeDisposable, Disposable} from 'atom'
import etch from 'etch'

import FileView from './file-view'
import DirectoryView from './directory-view'

export default class ArchiveEditorView {
  constructor (editor) {
    this.disposables = new CompositeDisposable()
    this.entries = []
    etch.initialize(this)
    this.setModel(editor)

    const focusHandler = () => {
      this.focusSelectedFile()
    }
    this.element.addEventListener('focus', focusHandler)
    this.disposables.add(new Disposable(() => { this.element.removeEventListener('focus', focusHandler) }))
  }

  update () {}

  destroy () {
    while (this.entries.length > 0) {
      this.entries.pop().destroy()
    }
    this.disposables.dispose()
    return etch.destroy(this)
  }

  render () {
    return (
      <div className='archive-editor' tabIndex='-1'>
        <div className='archive-container'>
          <div ref='loadingMessage' className='padded icon icon-hourglass text-info'>{`Loading archive\u2026`}</div>
          <div ref='errorMessage' className='padded icon icon-alert text-error' />
          <div className='inset-panel'>
            <div ref='summary' className='panel-heading' />
            <ol ref='tree' className='archive-tree padded list-tree has-collapsable-children' />
          </div>
        </div>
      </div>
    )
  }

  setPath (path) {
    if (path && this.path !== path) {
      this.path = path
      this.refresh()
    }
  }

  refresh () {
    this.refs.summary.style.display = 'none'
    this.refs.tree.style.display = 'none'
    this.refs.loadingMessage.style.display = ''
    this.refs.errorMessage.style.display = 'none'

    const originalPath = this.path
    archive.list(this.path, {tree: true}, (error, entries) => {
      if (originalPath !== this.path) {
        return
      }

      if (error != null) {
        let message = 'Reading the archive file failed'
        if (error.message) {
          message += `: ${error.message}`
        }
        this.refs.errorMessage.style.display = ''
        this.refs.errorMessage.textContent = message
      } else {
        this.createTreeEntries(entries)
        this.updateSummary()
      }

      // We hide the loading message _after_ creating the archive tree
      // to avoid forced reflows.
      this.refs.loadingMessage.style.display = 'none'
    })
  }

  createTreeEntries (entries) {
    while (this.entries.length > 0) {
      this.entries.pop().destroy()
    }

    let index = 0
    for (const entry of entries) {
      if (entry.isDirectory()) {
        const entryView = new DirectoryView(this, index, this.path, entry)
        this.entries.push(entryView)
      } else {
        const entryView = new FileView(this, index, this.path, entry)
        this.entries.push(entryView)
      }
      index++
    }

    this.selectFileAfterIndex(-1)

    // Wait until selecting (focusing) the first file before appending the entries
    // to avoid a double-forced reflow when focusing.
    for (const entry of this.entries) {
      this.refs.tree.appendChild(entry.element)
    }

    this.refs.tree.style.display = ''
  }

  updateSummary () {
    const fileCount = this.entries.filter((entry) => entry instanceof FileView).length
    const fileLabel = fileCount === 1 ? '1 file' : `${humanize.intComma(fileCount)} files`

    const directoryCount = this.entries.filter((entry) => entry instanceof DirectoryView).length
    const directoryLabel = directoryCount === 1 ? '1 folder' : `${humanize.intComma(directoryCount)} folders`

    this.refs.summary.style.display = ''
    this.refs.summary.textContent = `${humanize.fileSize(fs.getSizeSync(this.path))} with ${fileLabel} and ${directoryLabel}`
  }

  focusSelectedFile () {
    const selectedFile = this.refs.tree.querySelector('.selected')
    if (selectedFile) {
      selectedFile.focus()
    }
  }

  selectFileBeforeIndex (index) {
    for (let i = index - 1; i >= 0; i--) {
      const previousEntry = this.entries[i]
      if (previousEntry instanceof FileView) {
        previousEntry.select()
        break
      } else {
        if (previousEntry.selectLastFile()) {
          break
        }
      }
    }
  }

  selectFileAfterIndex (index) {
    for (let i = index + 1; i < this.entries.length; i++) {
      const nextEntry = this.entries[i]
      if (nextEntry instanceof FileView) {
        nextEntry.select()
        break
      } else {
        if (nextEntry.selectFirstFile()) {
          break
        }
      }
    }
  }

  focus () {
    this.focusSelectedFile()
  }

  setModel (editor) {
    if (!editor) {
      return
    }

    this.editor = editor
    this.setPath(this.editor.getPath())
    this.disposables.add(this.editor.file.onDidChange(() => {
      this.refresh()
    }))
    this.disposables.add(this.editor.file.onDidDelete(() => {
      const pane = atom.workspace.paneForItem(this.editor)
      if (pane) {
        pane.destroyItem(this.editor)
      }
    }))
  }
}
