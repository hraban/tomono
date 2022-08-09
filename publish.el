;; Keep this file simple, just babel tangle and trampoline to that file.
(require 'org)

(setq vc-handled-backends nil
      make-backup-files nil)
(find-file "Readme.org")
;; The tomono script
(org-babel-tangle)
;; This file is tangled in the previous step
(load-file "literate-html.el")
(literate-html-export)
