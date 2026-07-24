/**
 * HTML Sanitizer for Rich Text Content
 * 
 * Handles HTML content from multiple sources:
 * - Qt TextArea (adds DOCTYPE, -qt-* styles, margin styles)
 * - Odoo Rich Text Editor (standard HTML with various inline styles)
 * - Squire.js Editor (clean semantic HTML)
 * 
 * This module provides functions to normalize HTML for consistent
 * rendering across Qt WebEngine and Qt TextArea components.
 */

.pragma library

/**
 * Main sanitization function - cleans HTML from any source
 * @param {string} html - Raw HTML content
 * @param {object} options - Sanitization options
 * @returns {string} Clean HTML suitable for both Qt TextArea and WebEngine
 */
function sanitize(html, options) {
    if (!html || typeof html !== 'string') return "";
    
    options = options || {};
    var result = html;
    
    // Step 1: Remove DOCTYPE and extract body content if present
    result = extractBodyContent(result);
    
    // Step 2: Clean Qt-specific styles
    result = cleanQtStyles(result);
    
    // Step 2b: Convert Odoo CSS class-based font sizes to inline styles
    // (enables Qt TextArea and Squire to render them correctly)
    result = normalizeOdooClasses(result);
    
    // Step 3: Normalize formatting tags for cross-platform compatibility
    result = normalizeFormattingTags(result);
    
    // Step 4: Clean up whitespace and empty elements
    result = cleanupWhitespace(result);
    
    // Step 5: Validate and fix common HTML issues
    result = fixCommonIssues(result);
    
    return result.trim();
}

/**
 * Extract body content from full HTML document
 * Handles Qt's DOCTYPE wrapper and Odoo's full HTML documents
 */
function extractBodyContent(html) {
    if (!html) return "";
    
    // Check if this looks like a full HTML document
    if (html.indexOf('<!DOCTYPE') !== -1 || 
        html.indexOf('<html') !== -1 ||
        html.indexOf('<HTML') !== -1) {
        
        // Try to extract body content
        var bodyMatch = html.match(/<body[^>]*>([\s\S]*)<\/body>/i);
        if (bodyMatch && bodyMatch[1]) {
            return bodyMatch[1].trim();
        }
        
        // Fallback: strip document-level tags
        var stripped = html
            .replace(/<!DOCTYPE[^>]*>/gi, '')
            .replace(/<\/?html[^>]*>/gi, '')
            .replace(/<head>[\s\S]*?<\/head>/gi, '')
            .replace(/<\/?head[^>]*>/gi, '')
            .replace(/<\/?body[^>]*>/gi, '')
            .trim();
        
        return stripped;
    }
    
    return html;
}

/**
 * Remove Qt-specific CSS properties and styles
 * Qt adds properties like -qt-block-indent, -qt-paragraph-type, etc.
 * IMPORTANT: Only removes Qt-specific properties, preserves all formatting styles
 * (font-weight, font-style, color, text-decoration, etc.)
 */
function cleanQtStyles(html) {
    if (!html) return "";
    
    var result = html;
    
    // Remove -qt-* CSS properties ONLY (e.g., -qt-block-indent, -qt-paragraph-type)
    // These are Qt-specific and not valid CSS
    result = result.replace(/-qt-[a-z-]+\s*:\s*[^;"]+;?\s*/gi, '');
    
    // Remove Qt's complete default margin pattern (all four together)
    // Only remove when it's the exact Qt default, not user-intended margins
    result = result.replace(/margin-top\s*:\s*12px\s*;\s*margin-bottom\s*:\s*12px\s*;\s*margin-left\s*:\s*0px\s*;\s*margin-right\s*:\s*0px\s*;?/gi, '');
    
    // Remove text-indent:0px when combined with Qt margins (Qt default)
    result = result.replace(/text-indent\s*:\s*0px\s*;?\s*/gi, '');
    
    // Clean up empty or whitespace-only style attributes
    result = result.replace(/\s*style\s*=\s*"\s*;?\s*"/gi, '');
    result = result.replace(/\s*style\s*=\s*'\s*;?\s*'/gi, '');
    
    return result;
}

/**
 * Normalize formatting tags for cross-platform compatibility
 * Ensures tags work well in both Qt TextArea and WebEngine
 */
function normalizeFormattingTags(html) {
    if (!html) return "";
    
    var result = html;
    
    // Normalize bold: <strong> -> <b> (Qt TextArea prefers <b>)
    // But keep both since WebEngine handles both
    // result = result.replace(/<strong>/gi, '<b>');
    // result = result.replace(/<\/strong>/gi, '</b>');
    
    // Normalize italic: <em> -> <i>
    // result = result.replace(/<em>/gi, '<i>');
    // result = result.replace(/<\/em>/gi, '</i>');
    
    // Normalize strike: <s>, <del> -> <strike> for Qt compatibility
    result = result.replace(/<del>/gi, '<s>');
    result = result.replace(/<\/del>/gi, '</s>');
    
    // Ensure line breaks are consistent
    result = result.replace(/<br\s*\/?>/gi, '<br>');
    
    // Clean up Squire's data attributes (they're for internal tracking)
    result = result.replace(/\s*data-[a-z-]+="[^"]*"/gi, '');
    
    return result;
}

/**
 * Clean up whitespace and empty elements
 * IMPORTANT: This is intentionally minimal to avoid losing formatting
 */
function cleanupWhitespace(html) {
    if (!html) return "";
    
    var result = html;
    
    // Normalize multiple spaces to single space (but not inside <pre>)
    result = result.replace(/  +/g, ' ');
    
    // Only remove truly empty paragraphs (no content at all)
    // Preserve <p>&nbsp;</p> as intentional spacers
    result = result.replace(/<p><\/p>/gi, '');
    
    // Remove empty spans that have no attributes (style-less)
    // Keep spans with style attributes as they contain formatting
    result = result.replace(/<span><\/span>/gi, '');
    
    // Only collapse runs of 2+ whitespace between tags
    // Preserve single spaces/newlines to maintain structure
    result = result.replace(/>\s{2,}</g, '> <');
    
    return result;
}

/**
 * Fix common HTML issues
 */
function fixCommonIssues(html) {
    if (!html) return "";
    
    var result = html;
    
    // Fix unclosed br tags
    result = result.replace(/<br>/gi, '<br>');
    
    // Ensure proper paragraph structure
    // If content doesn't start with a block element, wrap in <p>
    var trimmed = result.trim();
    if (trimmed && 
        !trimmed.match(/^<(p|div|h[1-6]|ul|ol|li|blockquote|pre|table)/i)) {
        // Check if it's just plain text or inline elements
        if (!trimmed.match(/^<[a-z]/i) || 
            trimmed.match(/^<(span|a|b|i|u|s|strong|em|font)/i)) {
            // Don't wrap if it's already formatted inline content
            // result = '<p>' + result + '</p>';
        }
    }
    
    return result;
}

/**
 * Convert HTML to Qt-compatible format
 * Use this when setting content to Qt TextArea
 */
function toQtFormat(html) {
    if (!html) return "";
    
    // First sanitize
    var result = sanitize(html);
    
    // Qt TextArea handles standard HTML tags well
    // Just ensure the content is clean
    return result;
}

/**
 * Convert HTML to Squire-compatible format
 * Use this when setting content to WebEngine/Squire editor
 */
function toSquireFormat(html) {
    if (!html) return "";
    
    // First sanitize
    var result = sanitize(html);
    
    // Squire prefers semantic tags and clean structure
    // The sanitize function already handles this
    return result;
}

/**
 * Check if HTML content appears to be corrupted or from wrong source
 * Returns an object with: { isValid: boolean, issues: string[] }
 */
function validate(html) {
    var issues = [];
    
    if (!html) {
        return { isValid: true, issues: [] };
    }
    
    // Check for script tags (security issue)
    if (html.indexOf('<script') !== -1) {
        issues.push('Contains script tags');
    }
    
    // Check for editor internals
    if (html.indexOf('window.editor') !== -1) {
        issues.push('Contains editor JavaScript code');
    }
    
    if (html.indexOf('oxide.sendMessage') !== -1) {
        issues.push('Contains bridge communication code');
    }
    
    if (html.indexOf('squire-raw.js') !== -1) {
        issues.push('Contains Squire library reference');
    }
    
    // NOTE: Qt DOCTYPE is NOT an issue - it just needs sanitization
    // We don't reject content that has DOCTYPE, we sanitize it instead
    
    return {
        isValid: issues.length === 0,
        issues: issues
    };
}

/**
 * Convert Odoo CSS class-based font sizes to inline styles
 * so both Qt TextArea (RichTextPreview) and Squire (RichTextEditor)
 * render them properly.
 */
function normalizeOdooClasses(html) {
    if (!html) return "";
    
    var odooClassToSize = {
        'display-1-fs': '96px',
        'display-2-fs': '80px',
        'display-3-fs': '64px',
        'display-4-fs': '56px',
        'h1-fs': '40px',
        'h2-fs': '32px',
        'h3-fs': '28px',
        'h4-fs': '24px',
        'h5-fs': '20px',
        'h6-fs': '16px'
    };

    // Replace tag class attributes if they contain Odoo font-size classes
    return html.replace(/<([a-z0-9]+)\b([^>]*)>/gi, function(match, tagName, attrs) {
        var classMatch = attrs.match(/class\s*=\s*["']([^"']+)["']/i);
        if (!classMatch) return match;
        
        var classNames = classMatch[1].split(/\s+/);
        var matchedSize = null;
        
        for (var i = 0; i < classNames.length; i++) {
            var className = classNames[i];
            if (odooClassToSize.hasOwnProperty(className)) {
                matchedSize = odooClassToSize[className];
                break;
            }
        }
        
        if (!matchedSize) return match;
        
        // Match existing style attribute
        var styleMatch = attrs.match(/style\s*=\s*["']([^"']*)["']/i);
        if (styleMatch) {
            var styleContent = styleMatch[1].trim();
            // Check if font-size is already specified in the style (e.g. style="font-size: 32px")
            if (!/font-size\s*:/i.test(styleContent)) {
                if (styleContent && !styleContent.endsWith(';')) {
                    styleContent += ';';
                }
                styleContent += ' font-size: ' + matchedSize + ';';
                attrs = attrs.replace(/style\s*=\s*["']([^"']*)["']/i, 'style="' + styleContent + '"');
            }
        } else {
            attrs += ' style="font-size: ' + matchedSize + ';"';
        }
        
        return '<' + tagName + attrs + '>';
    });
}

/**
 * Quick check if content needs sanitization
 * Returns true for Qt-specific wrappers/styles, and Odoo font-size classes
 */
function needsSanitization(html) {
    if (!html) return false;
    
    // Sanitize for Qt DOCTYPE wrapper, Qt-specific CSS properties, or Odoo font-size classes
    return html.indexOf('<!DOCTYPE') !== -1 ||
           html.indexOf('-qt-') !== -1 ||
           /(?:display-[1-6]-fs|h[1-6]-fs)\b/.test(html);
}

/**
 * Extract plain text from HTML (strip all tags)
 */
function toPlainText(html) {
    if (!html) return "";
    
    var result = html;
    
    // Replace br and block elements with newlines
    result = result.replace(/<br\s*\/?>/gi, '\n');
    result = result.replace(/<\/(p|div|h[1-6]|li)>/gi, '\n');
    result = result.replace(/<(p|div|h[1-6]|li)[^>]*>/gi, '');
    
    // Remove all remaining HTML tags
    result = result.replace(/<[^>]+>/g, '');
    
    // Decode HTML entities
    result = result.replace(/&nbsp;/gi, ' ');
    result = result.replace(/&amp;/gi, '&');
    result = result.replace(/&lt;/gi, '<');
    result = result.replace(/&gt;/gi, '>');
    result = result.replace(/&quot;/gi, '"');
    result = result.replace(/&#39;/gi, "'");
    
    // Clean up multiple newlines
    result = result.replace(/\n\s*\n/g, '\n\n');
    
    return result.trim();
}
