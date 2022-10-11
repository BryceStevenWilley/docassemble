git checkout gh-pages
git pull upstream gh-pages
bundle exec jekyll build
(cd _site && ~/go/bin/dashing build --config ../dashing.json && tar --exclude='.DS_Store' -cvzf docassemble.tgz docassemble.docset)

