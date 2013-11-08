(require 'eproject)

;; xul project
(define-project-type xul (generic)
  (look-for "install.rdf")
  :tasks (("make" :shell "make")))

(provide 'eproject-xul)
