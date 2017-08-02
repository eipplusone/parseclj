;;; parseclj-lex-test.el --- Unit tests for the lexer

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

;;; Commentary

;; Unit tests for the lexer

;;; Code

(require 'ert)
(require 'parseclj-lex)

(ert-deftest parseclj-lex-test-next ()
  (with-temp-buffer
    (insert "()")
    (goto-char 1)
    (should (equal (parseclj-lex-next) '((:token-type . :lparen) (:form . "(") (:pos . 1))))
    (should (equal (parseclj-lex-next) '((:token-type . :rparen) (:form . ")") (:pos . 2))))
    (should (equal (parseclj-lex-next) '((:token-type . :eof) (:form . nil) (:pos . 3)))))

  (with-temp-buffer
    (insert "123")
    (goto-char 1)
    (should (equal (parseclj-lex-next) '((:token-type . :number)
                                         (:form . "123")
                                         (:pos . 1)))))

  (with-temp-buffer
    (insert "123e34M")
    (goto-char 1)
    (should (equal (parseclj-lex-next) '((:token-type . :number)
                                         (:form . "123e34M")
                                         (:pos . 1)))))

  (with-temp-buffer
    (insert "123x")
    (goto-char 1)
    (should (equal (parseclj-lex-next) (parseclj-lex-token :lex-error "123x" 1 :error-type :invalid-number-format))))

  (with-temp-buffer
    (insert " \t  \n")
    (goto-char 1)
    (should (equal (parseclj-lex-next) '((:token-type . :whitespace) (:form . " \t  \n") (:pos . 1)))))

  (with-temp-buffer
    (insert "nil")
    (goto-char 1)
    (should (equal (parseclj-lex-next) '((:token-type . :nil) (:form . "nil") (:pos . 1)))))

  (with-temp-buffer
    (insert "true")
    (goto-char 1)
    (should (equal (parseclj-lex-next) '((:token-type . :true) (:form . "true") (:pos . 1)))))

  (with-temp-buffer
    (insert "false")
    (goto-char 1)
    (should (equal (parseclj-lex-next) '((:token-type . :false) (:form . "false") (:pos . 1)))))

  (with-temp-buffer
    (insert "hello-world")
    (goto-char 1)
    (should (equal (parseclj-lex-next) '((:token-type . :symbol) (:form . "hello-world") (:pos . 1)))))

  (with-temp-buffer
    (insert "-hello-world")
    (goto-char 1)
    (should (equal (parseclj-lex-next) '((:token-type . :symbol) (:form . "-hello-world") (:pos . 1)))))

  (with-temp-buffer
    (insert "foo#")
    (goto-char 1)
    (should (equal (parseclj-lex-next) '((:token-type . :symbol) (:form . "foo#") (:pos . 1)))))

  (with-temp-buffer
    (insert "#inst")
    (goto-char 1)
    (should (equal (parseclj-lex-next) '((:token-type . :tag) (:form . "#inst") (:pos . 1)))))

  (with-temp-buffer
    (insert "#qualified/tag")
    (goto-char 1)
    (should (equal (parseclj-lex-next) '((:token-type . :tag) (:form . "#qualified/tag") (:pos . 1)))))

  (with-temp-buffer
    (insert "\\newline\\return\\space\\tab\\a\\b\\c")
    (goto-char 1)
    (should (equal (parseclj-lex-next) (parseclj-lex-token :character "\\newline" 1)))
    (should (equal (parseclj-lex-next) (parseclj-lex-token :character "\\return" 9)))
    (should (equal (parseclj-lex-next) (parseclj-lex-token :character "\\space" 16)))
    (should (equal (parseclj-lex-next) (parseclj-lex-token :character "\\tab" 22)))
    (should (equal (parseclj-lex-next) (parseclj-lex-token :character "\\a" 26)))
    (should (equal (parseclj-lex-next) (parseclj-lex-token :character "\\b" 28)))
    (should (equal (parseclj-lex-next) (parseclj-lex-token :character "\\c" 30))))

  (with-temp-buffer
    (insert "\\newline\\return\\space\\tab\\a\\b\\c")
    (goto-char 1)
    (should (equal (parseclj-lex-next) (parseclj-lex-token :character "\\newline" 1)))
    (should (equal (parseclj-lex-next) (parseclj-lex-token :character "\\return" 9)))
    (should (equal (parseclj-lex-next) (parseclj-lex-token :character "\\space" 16)))
    (should (equal (parseclj-lex-next) (parseclj-lex-token :character "\\tab" 22)))
    (should (equal (parseclj-lex-next) (parseclj-lex-token :character "\\a" 26)))
    (should (equal (parseclj-lex-next) (parseclj-lex-token :character "\\b" 28)))
    (should (equal (parseclj-lex-next) (parseclj-lex-token :character "\\c" 30))))

  (with-temp-buffer
    (insert "\\u0078\\o170")
    (goto-char 1)
    (should (equal (parseclj-lex-next) (parseclj-lex-token :character "\\u0078" 1)))
    (should (equal (parseclj-lex-next) (parseclj-lex-token :character "\\o170" 7))))

  (with-temp-buffer
    (insert "\"\\u0078\\o170\"")
    (goto-char 1)
    (should (equal (parseclj-lex-next) (parseclj-lex-token :string "\"\\u0078\\o170\"" 1))))

  (with-temp-buffer
    (insert ":hello-world")
    (goto-char 1)
    (should (equal (parseclj-lex-next) (parseclj-lex-token :keyword ":hello-world" 1))))

  (with-temp-buffer
    (insert ":hello/world")
    (goto-char 1)
    (should (equal (parseclj-lex-next) (parseclj-lex-token :keyword ":hello/world" 1))))

  (with-temp-buffer
    (insert "::hello-world")
    (goto-char 1)
    (should (equal (parseclj-lex-next) (parseclj-lex-token :keyword "::hello-world" 1))))

  (with-temp-buffer
    (insert ":::hello-world")
    (goto-char 1)
    (should (equal (parseclj-lex-next) (parseclj-lex-token :lex-error ":::" 1 :error-type :invalid-keyword))))

  (with-temp-buffer
    (insert "[123]")
    (goto-char 1)
    (should (equal (parseclj-lex-next) (parseclj-lex-token :lbracket "[" 1)))
    (should (equal (parseclj-lex-next) (parseclj-lex-token :number "123" 2)))
    (should (equal (parseclj-lex-next) (parseclj-lex-token :rbracket "]" 5))))

  (with-temp-buffer
    (insert "{:count 123}")
    (goto-char 1)
    (should (equal (parseclj-lex-next) (parseclj-lex-token :lbrace "{" 1)))
    (should (equal (parseclj-lex-next) (parseclj-lex-token :keyword ":count" 2)))
    (should (equal (parseclj-lex-next) (parseclj-lex-token :whitespace " " 8)))
    (should (equal (parseclj-lex-next) (parseclj-lex-token :number "123" 9)))
    (should (equal (parseclj-lex-next) (parseclj-lex-token :rbrace "}" 12))))

  (with-temp-buffer
    (insert "#{:x}")
    (goto-char 1)
    (should (equal (parseclj-lex-next) (parseclj-lex-token :set "#{" 1)))
    (should (equal (parseclj-lex-next) (parseclj-lex-token :keyword ":x" 3)))
    (should (equal (parseclj-lex-next) (parseclj-lex-token :rbrace "}" 5))))

  (with-temp-buffer
    (insert "(10 #_11 12 #_#_ 13 14)")
    (goto-char 1)
    (should (equal (parseclj-lex-next) (parseclj-lex-token :lparen "(" 1)))
    (should (equal (parseclj-lex-next) (parseclj-lex-token :number "10" 2)))
    (should (equal (parseclj-lex-next) (parseclj-lex-token :whitespace " " 4)))
    (should (equal (parseclj-lex-next) (parseclj-lex-token :discard "#_" 5)))
    (should (equal (parseclj-lex-next) (parseclj-lex-token :number "11" 7)))
    (should (equal (parseclj-lex-next) (parseclj-lex-token :whitespace " " 9)))
    (should (equal (parseclj-lex-next) (parseclj-lex-token :number "12" 10)))
    (should (equal (parseclj-lex-next) (parseclj-lex-token :whitespace " " 12)))
    (should (equal (parseclj-lex-next) (parseclj-lex-token :discard "#_" 13)))
    (should (equal (parseclj-lex-next) (parseclj-lex-token :discard "#_" 15)))
    (should (equal (parseclj-lex-next) (parseclj-lex-token :whitespace " " 17)))
    (should (equal (parseclj-lex-next) (parseclj-lex-token :number "13" 18)))
    (should (equal (parseclj-lex-next) (parseclj-lex-token :whitespace " " 20)))
    (should (equal (parseclj-lex-next) (parseclj-lex-token :number "14" 21)))
    (should (equal (parseclj-lex-next) (parseclj-lex-token :rparen ")" 23)))))

(ert-deftest parseclj-lex-test-at-number? ()
  (dolist (str '("123" ".9" "+1" "0" "-456"))
    (with-temp-buffer
      (insert str)
      (goto-char 1)
      (should (equal (parseclj-lex-at-number?) t))))

  (dolist (str '("a123" "$.9" "+/1" "++0" "-"))
    (with-temp-buffer
      (insert str)
      (goto-char 1)
      (should (equal (parseclj-lex-at-number?) nil)))))

(ert-deftest parseclj-lex-test-token ()
  (should (equal (parseclj-lex-token :whitespace ",,," 10)
                 '((:token-type . :whitespace)
                   (:form . ",,,")
                   (:pos . 10)))))

(ert-deftest parseclj-lex-test-digit? ()
  (should (equal (parseclj-lex-digit? ?0) t))
  (should (equal (parseclj-lex-digit? ?5) t))
  (should (equal (parseclj-lex-digit? ?9) t))
  (should (equal (parseclj-lex-digit? ?a) nil))
  (should (equal (parseclj-lex-digit? ?-) nil)))

(ert-deftest parseclj-lex-test-symbol-start? ()
  (should (equal (parseclj-lex-symbol-start? ?0) nil))
  (should (equal (parseclj-lex-symbol-start? ?a) t))
  (should (equal (parseclj-lex-symbol-start? ?A) t))
  (should (equal (parseclj-lex-symbol-start? ?.) t))
  (should (equal (parseclj-lex-symbol-start? ?. t) nil))
  (should (equal (parseclj-lex-symbol-start? ?~) nil))
  (should (equal (parseclj-lex-symbol-start? ? ) nil)))

(ert-deftest parseclj-lex-test-symbol-rest? ()
  (should (equal (parseclj-lex-symbol-rest? ?0) t))
  (should (equal (parseclj-lex-symbol-rest? ?a) t))
  (should (equal (parseclj-lex-symbol-rest? ?A) t))
  (should (equal (parseclj-lex-symbol-rest? ?.) t))
  (should (equal (parseclj-lex-symbol-rest? ?~) nil))
  (should (equal (parseclj-lex-symbol-rest? ? ) nil)))

(ert-deftest parseclj-lex-test-get-symbol-at-point ()
  (with-temp-buffer
    (insert "a-symbol")
    (goto-char 1)
    (should (equal (parseclj-lex-get-symbol-at-point 1) "a-symbol"))
    (should (equal (point) 9))))

(ert-deftest parseclj-lex-test-invalid-tag ()
  (with-temp-buffer
    (insert "#.not-a-tag")
    (goto-char 1)
    (should (equal (parseclj-lex-next)
                   (parseclj-lex-token :lex-error "#.not-a-tag" 1 :error-type :invalid-hashtag-dispatcher))))

  (with-temp-buffer
    (insert "#-not-a-tag")
    (goto-char 1)
    (should (equal (parseclj-lex-next)
                   (parseclj-lex-token :lex-error "#-not-a-tag" 1 :error-type :invalid-hashtag-dispatcher))))

  (with-temp-buffer
    (insert "#+not-a-tag")
    (goto-char 1)
    (should (equal (parseclj-lex-next)
                   (parseclj-lex-token :lex-error "#+not-a-tag" 1 :error-type :invalid-hashtag-dispatcher)))))

(ert-deftest parseclj-lex-test-string ()
  (with-temp-buffer
    (insert "\"abc\"")
    (goto-char 1)
    (should (equal (parseclj-lex-string) (parseclj-lex-token :string "\"abc\"" 1))))

  (with-temp-buffer
    (insert "\"abc")
    (goto-char 1)
    (should (equal (parseclj-lex-string) (parseclj-lex-token :lex-error "\"abc" 1))))

  (with-temp-buffer
    (insert "\"abc\\\"\"")"abc\""
    (goto-char 1)
    (should (equal (parseclj-lex-string) (parseclj-lex-token :string "\"abc\\\"\"" 1)))))

(ert-deftest parseclj-lex-test-tag ()
  (with-temp-buffer
    (insert "#inst")
    (goto-char 1)
    (should (equal (parseclj-lex-next) (parseclj-lex-token :tag "#inst" 1))))

  (with-temp-buffer
    (insert "#foo/bar")
    (goto-char 1)
    (should (equal (parseclj-lex-next) (parseclj-lex-token :tag "#foo/bar" 1)))))

(provide 'parseclj-lex-test)

;;; parseclj-lex-test.el ends here
