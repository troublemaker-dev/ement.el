;;; ement-tests.el --- Tests for Ement.el                  -*- lexical-binding: t; -*-

;; Copyright (C) 2023  Free Software Foundation, Inc.

;; Author: Adam Porter <adam@alphapapa.net>

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; 

;;; Code:

(require 'ert)
(require 'map)

(require 'ement-lib)
(require 'ement-room)

;;;; Tests

(ert-deftest ement--format-body-mentions ()
  (let ((room (make-ement-room
               :members (map-into
                         `(("@foo:matrix.org" . ,(make-ement-user :id "@foo:matrix.org"
                                                                  :displayname "foo"))
                           ("@bar:matrix.org" . ,(make-ement-user :id "@bar:matrix.org"
                                                                  :displayname "bar")))
                         '(hash-table :test equal)))))
    (should (equal (ement--format-body-mentions "@foo: hi" room)
                   "<a href=\"https://matrix.to/#/@foo:matrix.org\">foo</a>: hi"))
    (should (equal (ement--format-body-mentions "@foo:matrix.org: hi" room)
                   "<a href=\"https://matrix.to/#/@foo:matrix.org\">foo</a>: hi"))
    (should (equal (ement--format-body-mentions "foo: hi" room)
                   "<a href=\"https://matrix.to/#/@foo:matrix.org\">foo</a>: hi"))
    (should (equal (ement--format-body-mentions "@foo and @bar:matrix.org: hi" room)
                   "<a href=\"https://matrix.to/#/@foo:matrix.org\">foo</a> and <a href=\"https://matrix.to/#/@bar:matrix.org\">bar</a>: hi"))
    (should (equal (ement--format-body-mentions "foo: how about you and @bar ..." room)
                   "<a href=\"https://matrix.to/#/@foo:matrix.org\">foo</a>: how about you and <a href=\"https://matrix.to/#/@bar:matrix.org\">bar</a> ..."))
    (should (equal (ement--format-body-mentions "Hello, @foo:matrix.org." room)
                   "Hello, <a href=\"https://matrix.to/#/@foo:matrix.org\">foo</a>."))
    (should (equal (ement--format-body-mentions "Hello, @foo:matrix.org, how are you?" room)
                   "Hello, <a href=\"https://matrix.to/#/@foo:matrix.org\">foo</a>, how are you?"))))

(ert-deftest ement-room--format-message-body/edit-bogus-formatted-body ()
  "Plain-text edits shouldn't render as the outer fallback's bogus \"* \".
Regression test for <https://github.com/ruma/ruma/issues/2536>: some
clients send a spurious \"* \" `formatted_body' on the outer (fallback)
content of a plain-text edit even though `m.new_content' correctly has
none.  Ement should prefer `m.new_content''s (lack of) formatted body."
  (let* ((content '((body . "* This is an edited message.")
                    (msgtype . "m.text")
                    (format . "org.matrix.custom.html")
                    (formatted_body . "* ")
                    (m.relates_to (rel_type . "m.replace")
                                  (event_id . "$original_event_id"))
                    (m.new_content (body . "This is an edited message.")
                                   (msgtype . "m.text"))))
         (event (make-ement-event :content content)))
    (should (string= (ement-room--format-message-body event nil)
                     "This is an edited message. [edited]"))))

(provide 'ement-tests)

;;; ement-tests.el ends here
