//from http://article.gmane.org/gmane.comp.lang.lua.general/58453

I've just posted a first release of a C99 parser using LPEG.  This is
a full parser implementing all of the C99 grammar rules except for
some of the preprocessor directives. I based it off of
http://www.open-std.org/JTC1/SC22/wg14/www/docs/n1124.pdf
.  In
addition to defining nearly all of the rules of the C99 grammar, there
are some convenience data structures and functions.

C99 has tons of rules, so I've also grouped them into sections
according to Appendix A of the C99 spec.  For example, there are
listings of identifier_rules, constant_rules, string_literal_rules,
expression_rules, declaration_rules, statement_rules,
external_definition_rules, and all_rules as well as a special lpeg.P
for matching any token called token_patt.  These can be found in the
c99.ceg module.

The ceg module itself defines some useful functions such as apply
(apply a set of captures to a grammer (like in LEG)) and scan, which
will return a scanning function to match a pattern.  See the example
provided for details.

The example takes a chunk of C code (actually C++ code) and LuaDocs
the documented functions.  It can process C++ code since it simply
ignores tokens that don't match the pattern it's looking for through
the use of the scan function.  One thing of note, typedefs are handled
by a special table.  Usage is demonstrated in the example.

ceg can be downloaded at: http://www.mat.ucsb.edu/~whsmith/temp/ceg.zip

Feedback is welcome.