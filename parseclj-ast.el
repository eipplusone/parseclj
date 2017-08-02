;;; parseclj-ast.el --- Clojure parser/unparser              -*- lexical-binding: t; -*-

;; Copyright (C) 2017  Arne Brasseur

;; Author: Arne Brasseur <arne@arnebrasseur.net>

;; This file is not part of GNU Emacs.

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; Parse Clojure code to an AST, and unparse back to code.

;;; Code:

;; AST helper functions

(defun parseclj-ast-node (type position &rest attributes)
  "Create an AST node with given TYPE and POSITION.

Other ATTRIBUTES can be given as a flat list of key-value pairs. "
  (apply 'a-list :node-type type :position position attributes))

(defun parseclj-ast-node? (node)
  "Return `t' if the given NODE is a Clojure AST node."
  (and (consp node)
       (consp (car node))
       (eq :node-type (caar node))))

(defun parseclj-ast-node-type (node)
  "Return the type of the AST node NODE."
  (a-get node :node-type))

(defun parseclj-ast-leaf-node? (node)
  "Return `t' if the given ast NODE is a leaf node."
  (member (parseclj-ast-node-type node) parseclj--leaf-tokens))

;; Parse/reduce strategy functions

(defun parseclj-ast--reduce-leaf (stack token)
  (if (member (parseclj-lex-token-type token) '(:whitespace :comment))
      stack
    (cons
     (parseclj-ast-node (parseclj-lex-token-type token)
                        (a-get token :pos)
                        :form (a-get token :form)
                        :value (parseclj--leaf-token-value token))
     stack)))

(defun parseclj-ast--reduce-leaf-with-lexical-preservation (stack token)
  (let ((token-type (parseclj-lex-token-type token))
        (top (car stack)))
    (if (member token-type '(:whitespace :comment))
        ;; merge consecutive whitespace or comment tokens
        (if (eq token-type (a-get top :node-type))
            (cons (a-update top :form #'concat (a-get token :form))
                  (cdr stack))
          (cons (parseclj-ast-node (parseclj-lex-token-type token)
                                   (a-get token :pos)
                                   :form (a-get token :form))
                stack))
      (parseclj-ast--reduce-leaf stack token))))

(defun parseclj-ast--reduce-branch (stack opener-token children)
  (let* ((pos (a-get opener-token :pos))
         (type (parseclj-lex-token-type opener-token))
         (type (cl-case type
                 (:lparen :list)
                 (:lbracket :vector)
                 (:lbrace :map)
                 (t type))))
    (cl-case type
      (:root (parseclj-ast--node :root 0 :children children))
      (:discard stack)
      (:tag (list (parseclj-ast--node :tag
                                      pos
                                      :tag (intern (substring (a-get opener-token 'form) 1))
                                      :children children)))
      (t (cons
          (parseclj-ast--node type pos :children children)
          stack)))))

(defun parseclj-ast--reduce-branch-with-lexical-preservation (&rest args)
  (let ((node (apply #'parseclj-ast--reduce-branch args)))
    (cl-list*
     (car node) ;; make sure :node-type remains the first element in the list
     '(:lexical-preservation . t)
     (cdr node))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Unparser

(defun parseclj-ast-unparse-collection (nodes ld rd)
  (insert ld)
  (when-let (node (car nodes))
    (parseclj-ast-unparse node))
  (seq-doseq (node (cdr nodes))
    (insert " ")
    (parseclj-ast-unparse node))
  (insert rd))

(defun parseclj-ast-unparse-tag (node)
  (progn
    (insert "#")
    (insert (symbol-name (a-get node :tag)))
    (insert " ")
    (parseclj-ast-unparse (car (a-get node :children)))))

(defun parseclj-ast-unparse (node)
  (if (parseclj--leaf? node)
      (insert (alist-get ':form node))
    (let ((subnodes (alist-get ':children node)))
      (cl-case (a-get node ':node-type)
        (:root (parseclj-ast-unparse-collection subnodes "" ""))
        (:list (parseclj-ast-unparse-collection subnodes "(" ")"))
        (:vector (parseclj-ast-unparse-collection subnodes "[" "]"))
        (:set (parseclj-ast-unparse-collection subnodes "#{" "}"))
        (:map (parseclj-ast-unparse-collection subnodes "{" "}"))
        (:tag (parseclj-ast-unparse-tag node))))))

(defun parseclj-ast-unparse-str (data)
  (with-temp-buffer
    (parseclj-ast-unparse data)
    (buffer-substring-no-properties (point-min) (point-max))))

(provide 'parseclj-ast)

;;; parseclj-ast.el ends here
