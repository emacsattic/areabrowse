;;; areabrowse.el --- browse diku mud .are area files

;; Copyright 2005, 2007 Kevin Ryde

;; Author: Kevin Ryde <user42@zip.com.au>
;; Version: 1
;; Keywords: games
;; URL: http://www.geocities.com/user42_kevin/areabrowse/index.html

;; tty-format.el is free software; you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by the
;; Free Software Foundation; either version 2, or (at your option) any later
;; version.
;;
;; tty-format.el is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
;; Public License for more details.
;;
;; You can get a copy of the GNU General Public License online at
;; http://www.gnu.org/licenses/gpl.txt, or you should have one in the file
;; COPYING which comes with GNU Emacs and other GNU programs.  Failing that,
;; write to the Free Software Foundation, Inc., 51 Franklin St, Fifth Floor,
;; Boston, MA 02110-1301 USA.


;;; Commentary:

;; This is a mode to browse Diku MUD .are dungeon area files.  It's pretty
;; minimal, just helping to let you walk the area north, south, etc.

;;; Install:

;; Put areabrowse.el somewhere in your load path, and in your .emacs add
;;
;;     (autoload 'areabrowse-mode "areabrowse" nil t)
;;     (add-to-list 'auto-mode-alist '("\\.are\\'" . areabrowse-mode))

;;; History:

;; version 1 - the first version


;;; Code:

(defconst areabrowse-font-lock-keywords
  '("^#.*")  ;; object IDs and section markers
  "`font-lock-keywords' for `areabrowse-mode'.")

(defvar areabrowse-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map [?d]  'areabrowse-go-down)
    (define-key map [?e]  'areabrowse-go-east)
    (define-key map [?l]  'areabrowse-go-last)
    (define-key map [?n]  'areabrowse-go-north)
    (define-key map [?s]  'areabrowse-go-south)
    (define-key map [?u]  'areabrowse-go-up)
    (define-key map [?w]  'areabrowse-go-west)
    (define-key map [? ]  'areabrowse-go-next)
    (define-key map [?\d] 'areabrowse-go-prev)
    map)
  "Keymap for `areabrowse-mode'.")

(defvar areabrowse-room-history nil
  "History of rooms visited by `areabrowse-mode'.
This is a list of integers.  It's buffer local because room
numbers are only applicable to a given file.")
(make-variable-buffer-local 'areabrowse-room-history)

(defun areabrowse-go-north ()
  "Go north."
  (interactive)
  (areabrowse-go-direction 0))
(defun areabrowse-go-east ()
  "Go east."
  (interactive)
  (areabrowse-go-direction 1))
(defun areabrowse-go-south ()
  "Go south."
  (interactive)
  (areabrowse-go-direction 2))
(defun areabrowse-go-west ()
  "Go west."
  (interactive)
  (areabrowse-go-direction 3))
(defun areabrowse-go-up ()
  "Go up."
  (interactive)
  (areabrowse-go-direction 4))
(defun areabrowse-go-down ()
  "Go down."
  (interactive)
  (areabrowse-go-direction 5))

(defun areabrowse-go-direction (direction)
  "Go in the given DIRECTION.
0=north, 1=east, 2=south, 3=west, 4=up, 5=down."
  (save-excursion
    (end-of-line)
    (re-search-forward (format "^\\(\\(D%d\\)\\|#\\)" direction))
    (if (not (match-string 2))
        (error "No exit that way"))
    (re-search-forward "^[0-9-]+ [0-9-]+ \\([0-9-]+\\)"))
  (areabrowse-go-room (string-to-number (match-string 1))))

(defun areabrowse-go-room (roomnum)
  "Go to ROOMNUM (an integer) in the buffer."
  (goto-char (point-min))
  (re-search-forward "^#ROOMS")
  (re-search-forward (format "#%d" roomnum))
  (beginning-of-line)
  (set-window-start (selected-window) (point))
  (setq areabrowse-room-history (cons roomnum areabrowse-room-history)))

(defun areabrowse-go-last ()
  "Go back to the previously visited room (from `areabrowse-room-history')."
  (interactive)
  (if (not areabrowse-room-history)
      (error "No last room"))
  (let ((new-history (cddr areabrowse-room-history)))
    (areabrowse-go-room (cadr areabrowse-room-history))
    (setq areabrowse-room-history new-history)))

(defun areabrowse-go-first-room ()
  "Go to the first room in the buffer."
  (interactive)
  (goto-char (point-min))
  (re-search-forward "^#ROOMS")
  (forward-line 1)
  (set-window-start (selected-window) (point)))

(defun areabrowse-go-next ()
  "Go forward to the next room (sequentially in the buffer)."
  (interactive)
  (end-of-line)
  (re-search-forward "^#")
  (beginning-of-line)
  (set-window-start (selected-window) (point)))

(defun areabrowse-go-prev ()
  "Go back to the previous room (sequentially in the buffer)."
  (interactive)
  (re-search-backward "^#")
  (beginning-of-line)
  (set-window-start (selected-window) (point)))

(defun areabrowse-count-rooms ()
  "Show a count of the number of rooms in the buffer."
  (interactive)
  (save-excursion
    (areabrowse-go-first-room)
    (let ((count 0))
      (while (and (re-search-forward "^#\\([0-9]+\\)" (point-max) t)
                  (not (equal "0" (match-string 1))))
        (setq count (1+ count)))
      (message "Total %d rooms" count))))


(defun areabrowse-mode ()
  "A major mode for viewing diku mud \".are\" dungeon area files.

\\{areabrowse-mode-map}

`areabrowse-mode-hook' is run after initializations are
complete."

  (interactive)
  (kill-all-local-variables)
  (setq major-mode       'areabrowse-mode
        mode-name        "areabrowse"
        buffer-read-only t)
  (use-local-map areabrowse-mode-map)
  
  (set (make-local-variable 'font-lock-defaults)
       '(areabrowse-font-lock-keywords
         t     ;; no syntactic fontification (of strings etc)
         nil   ;; no case-fold
         nil)) ;; no changes to syntax table

  (run-hooks 'areabrowse-mode-hook))


(provide 'areabrowse)

;;; areabrowse.el ends here
