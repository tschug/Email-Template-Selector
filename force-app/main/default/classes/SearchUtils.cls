public class SearchUtils {

    /*
     * FROM: https://github.com/douglascayers/sfdc-escape-sosl
     *  
     * Designed to prepare text input for the FIND { phrase } part of SOSL query.
     *
     * Removes reserved logical operators: AND NOT, AND, OR
     * Escapes special characters: ? & | ! { } [ ] ( ) ^ ~ * : " ' + -
     *
     * Does not handle backslash (\) so do not include it in the text input.
     * Returns null if text is blank.
     *
     * https://developer.salesforce.com/docs/atlas.en-us.soql_sosl.meta/soql_sosl/sforce_api_calls_sosl_find.htm
     */
    public static String escapeSosl( String text ) {

        String escapedText;

        if ( String.isBlank( text ) ) {

            escapedText = null;

        } else {

            // Escaping characters is a bit annoying because
            // we are having to plan for multiple levels of evaluation of the escaped characters:
            //  1. Apex   -- this code requires double slahes (\\) to equate to a single slash (\) in the string literal
            //  2. Regex  -- when the replaceAll method parses the input sequence the apex \\ is read as a single \, so have to double up again in Apex to get \\ in regex land
            //  3. SOSL   -- when Search.query() method parses the query string it expects valid apex string literal, so any \ must be escaped as \\

            // In addition to my below logic, you can check out some other solutions here:
            // http://salesforce.stackexchange.com/questions/64757/function-to-properly-escape-dynamic-sosl-input

            // escape single quotes
            // we do not handle the single quote escaping in the matcher.replaceAll method along with the other escaping because we would end up with incorrect number of slashes
            escapedText = String.escapeSingleQuotes( text ) ;

            // remove special logical operators from the term (case insensitive)
            // these are keywords for SOSL, can't escape them so we exclude them from the search term
            escapedText = escapedText.replaceAll( '(?i)( AND NOT | AND | OR )', ' ' );

            // escape reserved characters
            // note, we handled single quotes above already
            // note, we do not handle \, it ends up being overly escaped
            // ? & | ! { } [ ] ( ) ^ ~ * : \ " ' + -
            Pattern myPattern = Pattern.compile( '(\\?|\\&|\\||\\!|\\{|\\}|\\[|\\]|\\(|\\)|\\^|\\~|\\*|\\:|\\"|\\+|\\-)' );
            Matcher myMatcher = myPattern.matcher( escapedText );

            // remember all the notes above about the 7 circles of hell of escaping text for apex, regex, sosl??
            // so all that comes into play here when we now perform the escaping of the matched special characters
            // we need 8 slashes (\\\\\\\\)
            //      ...in apex that translates into a string literal of just 4 (\\\\)
            //      ...once the replaceAll method runs it parses the input as regex, and regex like apex needs slashes escaped so the 4 (\\\\) it received is interpreted as regex literal of 2 (\\)
            //      ...we return the apex literal string with each special character now prefixed with 2 slashes (\\)
            //      ...when Search.query() method parses the escaped string literal we return from here those 2 slashes (\\) get interpreted as 1 slash (\)
            escapedText = myMatcher.replaceAll( '\\\\\\\\$1' );

            // collapse repeated whitespace
            escapedText = escapedText.replaceAll( '( )+', ' ' ).trim();

        }

        return escapedText;
    }

}