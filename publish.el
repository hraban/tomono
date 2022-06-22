(package-initialize)
(require 'org)

(find-file "Readme.org")
;; The tomono script
(org-babel-tangle)
(load-file "export-html.el")
