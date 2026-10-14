import QtQuick 2.7
import QtTest 1.0
import "../../../qml/components/richtext/js/html-sanitizer.js" as HtmlSanitizer

Item {
    width: 200
    height: 200

    TestCase {
        name: "HtmlSanitizerTests"
        when: windowShown

        function test_extractBodyContent() {
            var fullDoc = '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0//EN" "http://www.w3.org/TR/REC-html40/strict.dtd"><html><head><meta name="qrichtext" content="1" /></head><body><p>Clean paragraph</p></body></html>';
            compare(HtmlSanitizer.extractBodyContent(fullDoc), "<p>Clean paragraph</p>");

            var plainHtml = "<div>Normal content</div>";
            compare(HtmlSanitizer.extractBodyContent(plainHtml), "<div>Normal content</div>");

            compare(HtmlSanitizer.extractBodyContent(""), "");
            compare(HtmlSanitizer.extractBodyContent(null), "");
        }

        function test_cleanQtStyles() {
            var qtStyled = '<p style="-qt-block-indent:0; -qt-paragraph-type:empty; margin-top:12px; margin-bottom:12px; margin-left:0px; margin-right:0px; text-indent:0px; color:#ff0000;">Styled text</p>';
            var cleaned = HtmlSanitizer.cleanQtStyles(qtStyled);
            verify(cleaned.indexOf("-qt-") === -1);
            verify(cleaned.indexOf("margin-top:12px") === -1);
            verify(cleaned.indexOf("text-indent:0px") === -1);
            verify(cleaned.indexOf("color:#ff0000;") !== -1);
        }

        function test_normalizeColors() {
            var rgbHtml = '<span style="color: rgb(255, 0, 0);">Red</span>';
            compare(HtmlSanitizer.normalizeColors(rgbHtml), '<span style="color: #ff0000;">Red</span>');

            var rgbaHtml = '<div style="background-color: rgba(0, 128, 255, 0.5);">Blue</div>';
            compare(HtmlSanitizer.normalizeColors(rgbaHtml), '<div style="background-color: #0080ff;">Blue</div>');
        }

        function test_normalizeOdooClasses() {
            var odooHtml = '<h2 class="h1-fs text-primary">Heading</h2>';
            var normalized = HtmlSanitizer.normalizeOdooClasses(odooHtml);
            verify(normalized.indexOf("font-size: 28px;") !== -1);
            verify(normalized.indexOf("color: #714b67;") !== -1);
        }

        function test_convertFontTagsToSpans() {
            var legacyFont = '<font color="#00ff00" size="4">Green text</font>';
            var converted = HtmlSanitizer.convertFontTagsToSpans(legacyFont);
            verify(converted.startsWith('<span class="colour"'));
            verify(converted.indexOf("color:#00ff00") !== -1);
            verify(converted.indexOf("font-size:18px") !== -1);
            verify(converted.indexOf("Green text</span>") !== -1);
        }

        function test_validate() {
            var safeHtml = "<p>Safe text with <b>bold</b> element</p>";
            var validResult = HtmlSanitizer.validate(safeHtml);
            verify(validResult.isValid);
            compare(validResult.issues.length, 0);

            var unsafeScript = '<p>Test</p><script>alert("xss")</script>';
            var scriptResult = HtmlSanitizer.validate(unsafeScript);
            verify(!scriptResult.isValid);
            verify(scriptResult.issues.indexOf("Contains script tags") !== -1);

            var unsafeEditor = '<div>window.editor.getContent()</div>';
            var editorResult = HtmlSanitizer.validate(unsafeEditor);
            verify(!editorResult.isValid);
            verify(editorResult.issues.indexOf("Contains editor JavaScript code") !== -1);
        }

        function test_needsSanitization() {
            verify(HtmlSanitizer.needsSanitization('<!DOCTYPE html><html><body>Test</body></html>'));
            verify(HtmlSanitizer.needsSanitization('<p style="-qt-block-indent:0;">Qt paragraph</p>'));
            verify(HtmlSanitizer.needsSanitization('<span style="color: rgb(0,0,0);">Color</span>'));
            verify(HtmlSanitizer.needsSanitization('<font color="red">Font tag</font>'));
            verify(HtmlSanitizer.needsSanitization('<h1 class="h1-fs">Odoo Heading</h1>'));

            // Clean plain text or simple semantic HTML does not need sanitization
            verify(!HtmlSanitizer.needsSanitization("<p>Plain simple paragraph</p>"));
            verify(!HtmlSanitizer.needsSanitization(""));
            verify(!HtmlSanitizer.needsSanitization(null));
        }

        function test_toPlainText() {
            var html = '<p>Hello <b>World</b>!</p><br><p>Second &nbsp; line &amp; &lt;escaped&gt;</p>';
            var text = HtmlSanitizer.toPlainText(html);
            verify(text.indexOf("Hello World!") !== -1);
            verify(text.indexOf("Second   line & <escaped>") !== -1);
            verify(text.indexOf("<p>") === -1);
            verify(text.indexOf("<br>") === -1);
        }

        function test_sanitize_fullPipeline() {
            var rawInput = '<!DOCTYPE html><html><body><p style="-qt-block-indent:0; margin-top:12px; margin-bottom:12px; margin-left:0px; margin-right:0px;">Text with <del>deleted</del> and <font color="rgb(255, 0, 0)">red font</font></p></body></html>';
            var clean = HtmlSanitizer.sanitize(rawInput);
            verify(clean.indexOf("<!DOCTYPE") === -1);
            verify(clean.indexOf("-qt-") === -1);
            verify(clean.indexOf("<s>deleted</s>") !== -1);
            verify(clean.indexOf("#ff0000") !== -1);
            verify(clean.indexOf("<font") === -1);
        }
    }
}
