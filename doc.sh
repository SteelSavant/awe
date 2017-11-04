#! /bin/sh
haxe doc.hxml
haxelib run dox -i doc/doc.xml -o doc --title "Awe, the easy and fast ECS"
git add -A doc
git commit -m "Update documentation"
git subtree push --prefix doc origin gh-pages
rm -rf doc