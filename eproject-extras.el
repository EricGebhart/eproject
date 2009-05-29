;;; eproject-extras.el --- various utilities that make eproject more enjoyable

;; Copyright (C) 2009  Jonathan Rockway

;; Author: Jonathan Rockway <jon@jrock.us>
;; Keywords: eproject

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Some of this stuff used to be in eproject "core", but it is a bit
;; bloated, and not strictly necessary.  So now it lives here, leaving
;; the eproject core pristine and minimal.

;;; Code:

(require 'eproject)
(require 'iswitchb)
(require 'ibuffer)
(require 'ibuf-ext)

;; support for visiting other project files
(defalias 'eproject-ifind-file 'eproject-find-file)  ;; ifind is deperecated
(defun eproject-find-file ()
  "Present the user with a list of files in the current project
to select from, open file when selected."
  (interactive)
  (find-file (eproject--icomplete-read-with-alist
              "Project file: "
              (mapcar #'eproject--shorten-filename (eproject-list-project-files)))))

(defun eproject--completing-read (prompt choices)
  "Use completing-read to do a completing read."
  (completing-read prompt choices nil t))

(defun eproject--icompleting-read (prompt choices)
  "Use iswitchb to do a completing read."
  (let ((iswitchb-make-buflist-hook
         (lambda ()
           (setq iswitchb-temp-buflist choices))))
    (unwind-protect
        (progn
          (when (not iswitchb-mode)
            (add-hook 'minibuffer-setup-hook 'iswitchb-minibuffer-setup))
          (iswitchb-read-buffer prompt nil t))
      (when (not iswitchb-mode)
        (remove-hook 'minibuffer-setup-hook 'iswitchb-minibuffer-setup)))))

(defun eproject--ido-completing-read (prompt choices)
  "Use ido to do a completing read."
  (ido-completing-read prompt choices nil t))

(defcustom eproject-completing-read-function
  #'eproject--icompleting-read
  "The function used to ask the user select a single file from a
list of files; used by `eproject-find-file'."
  :group 'eproject
  :type '(radio (function-item :doc "Use emacs' standard completing-read function."
                               eproject--completing-read)
                (function-item :doc "Use iswitchb's completing-read function."
                               eproject--icompleting-read)
                (function-item :doc "Use ido's completing-read function."
                               eproject--ido-completing-read)
                (function)))

(defun eproject--icomplete-read-with-alist (prompt alist)
  (let ((show (mapcar (lambda (x) (car x)) alist)))
    (cdr (assoc (funcall eproject-completing-read-function prompt show) alist))))

;; ibuffer support

(define-ibuffer-filter eproject-root
    "Filter buffers that have the provided eproject root"
  (:reader (read-directory-name "Project root: " (ignore-errors (eproject-root)))
           :description "project root")
  (with-current-buffer buf
    (equal (file-name-as-directory (expand-file-name qualifier))
           (ignore-errors (eproject-root)))))

(define-ibuffer-filter eproject
    "Filter buffers that have the provided eproject name"
  (:reader (funcall eproject-completing-read-function
                    "Project name: " eproject-project-names)
           :description "project name")
  (with-current-buffer buf
    (equal qualifier
           (ignore-errors (eproject-name)))))

(defun* eproject-ibuffer (&optional (project-root (eproject-root)))
  "Open an IBuffer window showing all buffers with the
project root PROJECT-ROOT."
  (interactive)
  (ibuffer nil "*Project Buffers*"
           (list (cons 'eproject-root project-root))))

;; extra macros
(defmacro* with-each-buffer-in-project
    ((binding &optional (project-root (eproject-root)))
     &body body)
  "Given a project root PROJECT-ROOT, finds each buffer visiting a file in that project, and executes BODY with each buffer bound to BINDING (and made current).

\(fn (BINDING &optional PROJECT-ROOT) &body BODY)"
  (declare (indent 2))
  `(loop for ,binding in (buffer-list)
         do
         (with-current-buffer ,binding
           (let ((detected-root (ignore-errors (eproject-root))))
             (when (and detected-root (equal ,project-root detected-root))
               ,@body)))))

;; bulk management utils

(defun eproject-kill-project-buffers ()
  "Kill every buffer in the current project, including the current buffer."
  (interactive)
  (with-each-buffer-in-project (buf)
      (kill-buffer buf)))

(defun eproject-open-all-project-files ()
  "Open every file in the same project as the file visited by the current buffer."
  (interactive)
  (let ((total 0))
    (message "Opening files...")
    (save-window-excursion
      (loop for file in (eproject-list-project-files)
            do (progn (find-file file) (incf total))))
    (message "Opened %d files" total)))

(provide 'eproject-extras)
;;; eproject-extras.el ends here