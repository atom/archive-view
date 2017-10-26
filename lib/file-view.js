/** @babel */

import {CompositeDisposable, Disposable} from 'atom'
import path from 'path'
import fs from 'fs-plus'
import temp from 'temp'
import archive from 'ls-archive'

import IconServices from './icon-services'

export default class FileView {
  constructor (parentView, indexInParentView, archivePath, entry) {
    this.disposables = new CompositeDisposable()
    this.parentView = parentView
    this.indexInParentView = indexInParentView
    this.archivePath = archivePath
    this.entry = entry

    this.element = document.createElement('li')
    this.element.classList.add('list-item', 'entry')
    this.element.tabIndex = -1

    this.name = document.createElement('span')
    IconServices.updateFileIcon(this)
    this.name.textContent = this.entry.getName()
    this.element.appendChild(this.name)

    const clickHandler = () => {
      this.select()
      this.openFile()
    }
    this.element.addEventListener('click', clickHandler)
    this.disposables.add(new Disposable(() => { this.element.removeEventListener('click', clickHandler) }))

    this.disposables.add(atom.commands.add(this.element, {
      'core:confirm': () => {
        if (this.isSelected()) {
          this.openFile()
        }
      },

      'core:move-down': () => {
        if (this.isSelected()) {
          this.parentView.selectFileAfterIndex(this.indexInParentView)
        }
      },

      'core:move-up': () => {
        if (this.isSelected()) {
          this.parentView.selectFileBeforeIndex(this.indexInParentView)
        }
      }
    }))
  }

  destroy () {
    this.disposables.dispose()
    this.element.remove()
  }

  isSelected () {
    return this.element.classList.contains('selected')
  }

  logError (message, error) {
    console.error(message, error.stack != null ? error.stack : error)
  }

  openFile () {
    archive.readFile(this.archivePath, this.entry.getPath(), (error, contents) => {
      if (error != null) {
        this.logError(`Error reading: ${this.entry.getPath()} from ${this.archivePath}`, error)
      } else {
        temp.mkdir('atom-', (error, tempDirPath) => {
          if (error != null) {
            this.logError(`Error creating temp directory: ${tempDirPath}`, error)
          } else {
            const tempFilePath = path.join(tempDirPath, path.basename(this.archivePath), this.entry.getName())
            fs.writeFile(tempFilePath, contents, error => {
              if (error != null) {
                return this.logError(`Error writing to ${tempFilePath}`, error)
              } else {
                return atom.workspace.open(tempFilePath)
              }
            })
          }
        })
      }
    })
  }

  select () {
    for (const selected of this.element.closest('.archive-editor').querySelectorAll('.selected')) {
      selected.classList.remove('selected')
    }
    this.element.classList.add('selected')
    this.element.focus()
  }
}
