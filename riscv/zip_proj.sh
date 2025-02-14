#! /bin/bash

set -e

PROJ_NAME="cpre381-toolflow"

(cd docs/ && pdflatex main.tex)

mkdir -p $PROJ_NAME

cp 381_tf.sh $PROJ_NAME
chmod +755 $PROJ_NAME/381_tf.sh

cp -r internal $PROJ_NAME/
cp docs/main.pdf $PROJ_NAME/$PROJ_NAME.pdf

git describe > $PROJ_NAME/internal/version.txt

zip -rq $PROJ_NAME.zip $PROJ_NAME
echo "Done"
rm -rf $PROJ_NAME
