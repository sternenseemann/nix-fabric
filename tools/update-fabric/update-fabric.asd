(asdf:defsystem "update-fabric"
  :depends-on ("drakma" "cl-json" "alexandria")
  :description "Simple tool to update version info of the fabric mod loader"
  :components ((:file "update-fabric")))
