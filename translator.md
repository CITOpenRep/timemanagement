#Scan all the texts
cd po
xgettext \
  --from-code=UTF-8 \
  --language=JavaScript \
  --keyword=i18n.tr:1 \
  --package-name="your-app" \
  --add-comments=TRANSLATORS: \
  --output=ubtms.pot\
  $(find ../qml -name "*.qml" -print)

cd ..

# First time for a lang:
msginit --locale=nl --input=ubtms.pot --output=nl.po

# On later updates (after you re-run xgettext):
msgmerge --update ubtms_nl.po ubtms.pot
