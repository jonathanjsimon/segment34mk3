#!/usr/bin/env python3
"""
Font character audit for Segment34 Mk3 watchface.
Checks all watch-displayed strings (labels, weather conditions, day/month names, units)
against the character sets of the custom bitmap fonts (smol, led, storre, xsmol).

All these fonts share the same character set:
  - Uppercase A-Z
  - Digits 0-9
  - Punctuation subset (varies slightly per font)
  - Accented: À Ä Å Ç È É Ê Ó Ö Ù Ü î Ą Ć Ę Ł Ń Ś Ź Ż
  - Lowercase: a b c (smol/storre/xsmol only), a-h (led - used for wind bearing arrows)

Strings in settings.xml / settings/ are shown in Garmin Connect mobile app (system font)
and are NOT subject to these constraints. Only strings rendered on the watchface matter.

Settings-only string ID prefixes: settings_, format_desc, format_letter
"""

import re
import os
import sys

REPO = os.path.dirname(os.path.abspath(__file__))

# Settings-only prefixes - these are shown in Garmin Connect app, not on watchface
SETTINGS_PREFIXES = ("settings_", "format_desc", "format_letter")

# String IDs that appear only in settings UI (not rendered on-watch)
SETTINGS_IDS = {
    "AppName",  # shown in app store, not watchface
}


def parse_fnt_charset(fnt_path):
    """Parse an AngelCode BMFont .fnt file and return the set of supported char codepoints."""
    chars = set()
    with open(fnt_path, "r", encoding="utf-8") as f:
        for line in f:
            if line.startswith("char "):
                m = re.search(r'\bid=(\d+)', line)
                if m:
                    chars.add(int(m.group(1)))
    return chars


def parse_strings_xml(xml_path, exclude_settings=True):
    """Parse a strings.xml and return dict of {id: value} for watch-displayed strings."""
    with open(xml_path, "r", encoding="utf-8") as f:
        content = f.read()
    strings = {}
    for m in re.finditer(r'<string id="([^"]+)">([^<]+)</string>', content):
        sid, val = m.group(1), m.group(2)
        if exclude_settings:
            if any(sid.startswith(p) for p in SETTINGS_PREFIXES):
                continue
            if sid in SETTINGS_IDS:
                continue
        strings[sid] = val
    return strings


def audit_strings(strings, charset, font_name, lang):
    """Check all strings against charset. Return list of (lang, sid, val, bad_chars)."""
    issues = []
    for sid, val in strings.items():
        bad = [c for c in val if ord(c) not in charset]
        if bad:
            issues.append((lang, sid, val, bad))
    return issues


def main():
    fonts_dir = os.path.join(REPO, "resources", "fonts")

    # Parse all font charsets
    font_files = {
        "smol":   os.path.join(fonts_dir, "smol.fnt"),
        "storre": os.path.join(fonts_dir, "storre.fnt"),
        "led":    os.path.join(fonts_dir, "led.fnt"),
        "xsmol":  os.path.join(fonts_dir, "xsmol.fnt"),
        "led_small": os.path.join(fonts_dir, "led_small.fnt"),
        "led_big":   os.path.join(fonts_dir, "led_big.fnt"),
    }
    charsets = {}
    for name, path in font_files.items():
        if os.path.exists(path):
            charsets[name] = parse_fnt_charset(path)

    # Use intersection of all fonts as the "any font" charset
    # (since strings may be rendered by different fonts depending on field)
    # The real constraint is: smol/storre for labels, led variants for data values.
    # In practice all share the same accented chars, so use union to be permissive,
    # but flag chars missing from ALL fonts as definite errors.
    any_font_chars = set().union(*charsets.values())
    all_font_chars = set.intersection(*charsets.values())

    print(f"Character sets parsed: {list(charsets.keys())}")
    print(f"Chars in ALL fonts: {len(all_font_chars)}")
    print(f"Chars in ANY font: {len(any_font_chars)}")
    print()
    print(f"All-font accented: {''.join(chr(c) for c in sorted(all_font_chars) if c > 127)}")
    print()

    # Audit all language string files
    lang_dirs = {
        "en":  os.path.join(REPO, "resources", "strings", "strings.xml"),
        "deu": os.path.join(REPO, "resources-deu", "strings", "strings.xml"),
        "fre": os.path.join(REPO, "resources-fre", "strings", "strings.xml"),
        "ita": os.path.join(REPO, "resources-ita", "strings", "strings.xml"),
        "pol": os.path.join(REPO, "resources-pol", "strings", "strings.xml"),
        "spa": os.path.join(REPO, "resources-spa", "strings", "strings.xml"),
        "swe": os.path.join(REPO, "resources-swe", "strings", "strings.xml"),
    }

    all_issues = []
    for lang, xml_path in lang_dirs.items():
        if not os.path.exists(xml_path):
            print(f"WARNING: {xml_path} not found")
            continue
        strings = parse_strings_xml(xml_path)
        issues = audit_strings(strings, all_font_chars, "all", lang)
        all_issues.extend(issues)

    if not all_issues:
        print("✓ No character violations found in any language!")
    else:
        print(f"VIOLATIONS ({len(all_issues)} strings have unsupported characters):")
        print()
        for lang, sid, val, bad_chars in sorted(all_issues, key=lambda x: (x[0], x[1])):
            bad_str = ", ".join(f"U+{ord(c):04X} '{c}'" for c in bad_chars)
            print(f"  [{lang}] {sid}: \"{val}\"")
            print(f"         Bad chars: {bad_str}")
        print()
        print("Fix: either update the string to use only supported characters,")
        print("or add the missing glyphs to the bitmap fonts.")

    # Also show which chars are in some fonts but not all
    print()
    print("Chars in SOME but not ALL fonts:")
    for c in sorted(any_font_chars - all_font_chars):
        in_which = [n for n, cs in charsets.items() if c in cs]
        print(f"  U+{c:04X} '{chr(c)}' in: {in_which}")


if __name__ == "__main__":
    main()
