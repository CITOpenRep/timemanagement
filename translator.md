#Scan all the texts (Not needed, We have integrated with build system)
cd po
xgettext \
  --from-code=UTF-8 \
  --language=JavaScript \
  --keyword=i18n.tr:1 \
  --package-name="ubtms" \
  --add-comments=TRANSLATORS: \
  --output=ubtms.pot\
  $(find ../qml -name "*.qml" -print)

cd ..

# First time for a lang: Refer https://gitlab.com/dekkan/dekko/-/tree/master/i18n?ref_type=heads for the filename
msginit --locale=nl --input=ubtms.pot --output=nl.po

# On later updates (after you re-run xgettext):
msgmerge --update nl.po ubtms.pot
