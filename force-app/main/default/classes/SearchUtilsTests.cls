@isTest
private class SearchUtilsTests {

    @isTest
    static void test_escape_null() {

        Test.startTest();

        String text = null;

        String escapedText = SearchUtils.escapeSosl( text );

        Test.stopTest();

        System.assertEquals( null, escapedText );

    }

    @isTest
    static void test_escape_empty_string() {

        Test.startTest();

        String text = '';

        String escapedText = SearchUtils.escapeSosl( text );

        Test.stopTest();

        System.assertEquals( null, escapedText );

    }

    @isTest
    static void test_escape_plain_text() {

        Test.startTest();

        String text = 'search this';

        String escapedText = SearchUtils.escapeSosl( text );

        String query =
            ' FIND ' +
                '\'' + escapedText + '\'' +
            ' RETURNING ' +
                ' Account ( id, name ) ' +
            ' LIMIT 10 '
        ;

        System.debug( query );

        // sosl doesn't actually do a search in tests, you can only mock the results
        // we are just testing for syntax parsing issues at runtime
        Search.query( query );

        Test.stopTest();

        System.assertEquals( 'search this', escapedText );

    }

    @isTest
    static void test_escape_special_characters() {

        Test.startTest();

        String text = 'search this or that and ? & | ! { } [ ] ( ) ^ ~ * : " \' + -';

        String escapedText = SearchUtils.escapeSosl( text );

        String query =
            ' FIND ' +
                '\'' + escapedText + '\'' +
            ' RETURNING ' +
                ' Account ( id, name ) ' +
            ' LIMIT 10 '
        ;

        System.debug( query );

        // sosl doesn't actually do a search in tests, you can only mock the results
        // we are just testing for syntax parsing issues at runtime
        Search.query( query );

        Test.stopTest();

        System.assertEquals( 'search this that \\\\? \\\\& \\\\| \\\\! \\\\{ \\\\} \\\\[ \\\\] \\\\( \\\\) \\\\^ \\\\~ \\\\* \\\\: \\\\" \\\' \\\\+ \\\\-', escapedText );

    }

}