;;; Author: Tung Dao <me@tungdao.com>
(require 'eproject)

;; Clojure Leiningen project
(define-project-type clojure-leiningen (generic)
  (look-for "project.clj")
  :irrelevant-files ("*.class" "*.jar")
  :tasks (("test" :shell "lein test")
          ("jar" :shell "lein jar")))


(provide 'eproject-clojure-leiningen)
