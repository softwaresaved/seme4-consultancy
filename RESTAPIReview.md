# sameAs Lite REST API review

Mike Jackson, The Software Sustainability Institute / EPCC, The University of Edinburgh

## Introduction

[sameAs.org](http://sameas.org) is a search engine for linked data that, if given a URI, returns URIs that are co-referent, should any be known to it. The engine searches information harvested from a number of sources. sameAs.org is maintained by [Seme4 Limited](http://www.seme4.com). [sameAs Lite](http://github.com/seme4/sameas-lite) is a refactored, free open source, version of the software that powers sameAs.org.

[REST API examples](./RESTAPIexamples.md) gives examples of invocations of sameAs Lite's REST API, using curl. The API can also be viewed, and invoked, via a web-based interface at http://127.0.0.1/sameas-lite/datasets/api.

This document summarises issues with the REST API were identified when documenting the examples.

---

## Clarify how to pass URIs as canons and symbols in URLs

It is unclear how to pass URIs as canons or symbols. None of these operations worked:

    $ curl -X GET http://127.0.0.1/sameas-lite/datasets/test/symbols/http%3A%2F%2Fdata.nytimes.com%2Fedinburgh_scotland_geo
    <h1>Error 404</h1>

    $ curl -X GET http://127.0.0.1/sameas-lite/datasets/test/symbols/http\:\/\/data.nytimes.com\/edinburgh_scotland_geo
    <h1>Error 404</h1>

    $ curl -X GET http://127.0.0.1/sameas-lite/datasets/test/symbols/http://data.nytimes.com/edinburgh_scotland_geo
    <h1>Error 404</h1>

This invocation:

    $ curl -X GET http://127.0.0.1/sameas-lite/datasets/test/symbols/http%253A%252F%252Fdata.nytimes.com%252Fedinburgh_scotland_geo

did not raise an error, but it returned no matches.

---

## Bugs

### Fix typos in web-based interface API descriptions

On http://127.0.0.1/sameas-lite/datasets/api:

* Search (GET http://127.0.0.1/sameas-lite/datasets/{store}/search/{symbol}), description has a typo: "Find symols".
* Delete symbol (DELETE http://127.0.0.1/sameas-lite/datasets/{store}/symbols/{symbol}) description is "TBC".

The typos are in src/WebApp.php line 310:

    $this->registerURL(
        'GET',
        '/datasets/:store/search/:string',
        'search',
        'Search',
        'Find symols which contain/match the search string/pattern'
    );

and src/WebApp.php line 326:

    $this->registerURL(
         'DELETE',
        '/datasets/:store/symbols/:symbol',
        'removeSymbol',
        'Delete symbol',
        'TBC',
        true,
        'text/html,text/plain'
    );

A fix is in the [typos](https://github.com/softwaresaved/sameas-lite/tree/typos) branch of https://github.com/softwaresaved/sameas-lite, commit [c4fa238d52a1320bbfeaea6e1a75169da7a644bb](https://github.com/softwaresaved/sameas-lite/commit/c4fa238d52a1320bbfeaea6e1a75169da7a644bb).

### Fix Delete symbol bug

Delete symbol raises an error:

    $ curl -H "Accept: text/html"  -X DELETE --user username:password http://127.0.0.1/sameas-lite/datasets/test/symbols/canonA
    <h2>Undefined variable: result</h2>

    <p><strong>/var/www/html/sameas-lite/src/WebApp.php</strong> &nbsp; +1033</p><p>Please try returning to <a href="http://127.0.0.1/sameas-lite">the homepage</a>.</p>

Inspecting the database shows that the deletion does occur.

The bug is at src/WebApp.php line 1033:

    public function removeSymbol($store, $symbol)
    {
        $this->stores[$store]->removeSymbol($symbol);
        $this->outputSuccess($result);
    }

The first line of the function should be:

        $result = $this->stores[$store]->removeSymbol($symbol);

A fix is in the [fixdelete](https://github.com/softwaresaved/sameas-lite/tree/fixdelete) branch of https://github.com/softwaresaved/sameas-lite, commit [5e4b14e4b8d02996ce1884bfc047179b4e0a2409](https://github.com/softwaresaved/sameas-lite/commit/5e4b14e4b8d02996ce1884bfc047179b4e0a2409).

    $ curl -H "Accept: text/html"  -X DELETE --user username:password http://127.0.0.1/sameas-lite/datasets/test/symbols/canonA
    <h2>Success!</h2><p></p>

    $ curl -H "Accept: text/plain"  -X DELETE --user username:password http://127.0.0.1/sameas-lite/datasets/test/symbols/canonB
    ...nothing....

### Fix Analyse contents of the store bug

If a store is non-empty, Analyse contents of the store raises an error:

    $ curl -H "Accept: text/html" -X GET http://127.0.0.1/sameas-lite/datasets/test/analyse
    <h2>Undefined index: http://www.wikidata.org/entity/Q220966</h2>
    /var/www/html/sameas-lite/src/Store.php +823

If store is empty, then the bug does not arise:

    $ curl -H "Accept: text/html" -X GET http://127.0.0.1/sameas-lite/datasets/test/analyse
    <pre><pre>

    Analysis of sameAs store 'table1' in Database 'testdb':
    Store is empty!</pre>

The bug is at src/Store.php line 823:

    $bundleSizes = array(); // An array of canon => bundle size

    foreach ($store as $row) {
        $s = $row['symbol'];
        $b = $row['canon'];
        $nSymbols++;
        $bundleSizes[$b]++;

$bundleSizes should be checked to see if it has a value for key $b before being incremented:

    foreach ($store as $row) {
        $s = $row['symbol'];
        $b = $row['canon'];
        $nSymbols++;
        if (array_key_exists($b, $bundleSizes)) {
            $bundleSizes[$b]++;
        } else {
           $bundleSizes[$b] = 0;
        }

A fix is in the [fixanalyse](https://github.com/softwaresaved/sameas-lite/tree/fixanalyse] branch of https://github.com/softwaresaved/sameas-lite, commit [8b8664417cbb24ba2f09dc5e71ebd28564d7d350](https://github.com/softwaresaved/sameas-lite/commit/8b8664417cbb24ba2f09dc5e71ebd28564d7d350).

    $ curl -H "Accept: text/html" -X GET http://127.0.0.1/sameas-lite/datasets/test/analyse
    <h1>[titleHeader]</h1>
    <pre><pre>

    Analysis of sameAs store 'table1' in Database 'testdb':
    =====================================================
    Basic numeric statistics:
    15 	symbols
    3 	bundles
    5.00	symbols per bundle
    4	bundle size median
    4	bundle size mode
    =====================================================
    Table of count of bundles for each bundle size
    Size	Bundle Count
    4	3
    =====================================================
    Symbols by type:
    15	HTTP symbols
    0	HTTPS symbols
    0	non-HTTP(S) symbols
    =====================================================
    URI(s) etc per domain - for http symbols, if any
    Count	Domain
    3	data.nytimes.com
    3	data.ordnancesurvey.co.uk
    3	dbpedia.org
    3	sws.geonames.org
    3	www.wikidata.org
    ------------------------
    Count	Base+TLD Domain
    3	nytimes.com
    3	co.uk
    3	dbpedia.org
    3	geonames.org
    3	wikidata.org
    ------------------------
    Count	TLD Domain
    3	com
    3	uk
    9	org
    =====================================================
    URI(s) etc per domain - for https symbols, if any
    =====================================================
    Things that might be considered errors:
    Singleton bundle symbols:
    =====================================================
    Errors:
    List of canons that are not also listed as symbols:
    http://www.wikidata.org/entity/Q220966
    http://www.wikidata.org/entity/Q23436
    http://www.wikidata.org/entity/Q6940372
    =====================================================
    </pre>
    </pre>

This seems to reveal a new bug. The above `List of canons that are not also listed as symbols` *are* listed as symbols:

    > select * from table1;
    +-----------------------------------------+---------------------------------------------------------+
    | canon                                   | symbol                                                  |
    +-----------------------------------------+---------------------------------------------------------+
    | http://www.wikidata.org/entity/Q23436   | http://www.wikidata.org/entity/Q23436                   |
    ...
    | http://www.wikidata.org/entity/Q220966  | http://www.wikidata.org/entity/Q220966                  |
    ...
    | http://www.wikidata.org/entity/Q6940372 | http://www.wikidata.org/entity/Q6940372                 |
    ...
    +-----------------------------------------+---------------------------------------------------------+
    15 rows in set (0.00 sec)

### Fix Get Canon so it does not return an ambiguous result

If Get Canon is called with a non-existent canon or symbol then that canon or symbol is returned:

    $ curl -H "Accept: text/html" -X GET http://127.0.0.1/sameas-lite/datasets/test/canons/nomatch
    <h1>Canon for &ldquo;nomatch&rdquo;</h1>
    <ul>
        <li>nomatch</li>
    </ul>

    $ curl -H "Accept: text/plain" -X GET http://127.0.0.1/sameas-lite/datasets/test/canons/nomatch
    nomatch

The caller cannot tell whether there is one matching canon or symbol, called nomatch, or none.

---

## Input/output formats

### Make Assert multiple pairs and Export list of pairs complementary

Assert multiple pairs takes a list of TAB-separated pairs:

    $ curl -X PUT --user username:password -T "pairs.txt" http://127.0.0.1/sameas-lite/datasets/test/pairs

However Export list of pairs returns JSON, HTML, or comma-separated values:

    $ curl -H "Accept: application/json" -X GET http://127.0.0.1/sameas-lite/datasets/test/pairs
    $ curl -H "Accept: text/html" -X GET http://127.0.0.1/sameas-lite/datasets/test/pairs
    $ curl -H "Accept: text/csv" -X GET http://127.0.0.1/sameas-lite/datasets/test/pairs

As these are complementary operations, make them behave as such:

* Export list of pairs also returns a TAB-separated list of pairs if content-type text/plain is specified.
* Assert multiple pairs also accepts JSON and CSV files that are output from Export list of pairs.

### Be consistent when returning lists of data

If Search finds matching canons or symbols, it returns an HTML list:

    $ curl -H "Accept: text/html" -X GET http://127.0.0.1/sameas-lite/datasets/test/search/dinb
    <ul>
        <li><a href="http://data.nytimes.com/edinburgh_scotland_geo">http://data.nytimes.com/edinburgh_scotland_geo</a></li>
        <li><a href="http://data.ordnancesurvey.co.uk/id/50kGazetteer/81482">http://data.ordnancesurvey.co.uk/id/50kGazetteer/81482</a></li>
        <li><a href="http://dbpedia.org/resource/Embra">http://dbpedia.org/resource/Embra</a></li>
        <li><a href="http://sws.geonames.org/2650225/">http://sws.geonames.org/2650225/</a></li>
        <li><a href="http://www.wikidata.org/entity/Q23436">http://www.wikidata.org/entity/Q23436</a></li>
      </ul>

If it finds none, it returns a paragraph:

    $ curl -H "Accept: text/html" -X GET http://127.0.0.1/sameas-lite/datasets/test/search/nomatch
    <p>No items found</p>

It would be more consistent to return an empty list:

    <ul></ul>

The count of items could be added also:

    <p>3 items found:</p>
    <ul>
      <li>....</li>
      <li>....</li>
      <li>....</li>
    </ul>

    <p>0 items found:</p>
    <ul>
    </ul>

Similarly, Retrieve symbol returns its lists within pre blocks:

    $ curl -H "Accept: text/html" -X GET http://127.0.0.1/sameas-lite/datasets/test/symbols/canonA
    <pre>canonA
    symbolA1
    symbolA2
    symbolA3</pre>

    $ curl -H "Accept: text/html" -X GET http://127.0.0.1/sameas-lite/datasets/test/symbols/nomatch
    <pre></pre>

For consistency, these should adopt the same list-based structured output as Search.

### Return status and analysis information as a table

Return status of the store returns its contents as a pre block:

    $ curl -X GET http://127.0.0.1/sameas-lite/datasets/test/status
    <pre>Statistics for sameAs store table1:
    15    symbols
    3    bundles</pre>

As does Analyse contents of the store:

    $ curl -H "Accept: text/html" -X GET http://127.0.0.1/sameas-lite/datasets/test/analyse
    <pre><pre>

    Analysis of sameAs store 'table1' in Database 'testdb':
    Store is empty!</pre>

These would be more readable, and consistent with other data returned as HTML, if represented as tables.

### Support additional content-types

Endpoints that return lists or tabular data could support all of text/html, application/json, text/plain, and text/csv. It should be ensured that the representation within each format is consistent (as described above).

---

## Implementation

### Implement Lists available datasets

    $ curl -X GET http://127.0.0.1/sameas-lite/datasets

returns:

    TODO

### Fill in titleheader

A number of endpoints return a template header when text/html is requested:

    <h1>[titleHeader]</h1>

These include:

    $ curl -H "Accept: text/html" -X GET http://127.0.0.1/sameas-lite/datasets
    $ curl -H "Accept: text/html" -X DELETE --user username:password http://127.0.0.1/sameas-lite/datasets/test
    $ curl -H "Accept: text/html" -X DELETE --user username:password http://127.0.0.1/sameas-lite/datasets/test/admin/empty
    $ curl -H "Accept: text/html" -X PUT --user username:password http://127.0.0.1/sameas-lite/datasets/test/canons/canonA
    $ curl -H "Accept: text/html" -X PUT --user username:password -T "pairs.txt" http://127.0.0.1/sameas-lite/datasets/test/pairs
    $ curl -H "Accept: text/html" -X GET http://127.0.0.1/sameas-lite/datasets/test/search/dinb
    $ curl -H "Accept: text/html" -X GET http://127.0.0.1/sameas-lite/datasets/test/symbols/canonA
    $ curl -H "Accept: text/html" -X GET http://127.0.0.1/sameas-lite/datasets/test/status
    $ curl -H "Accept: text/html" -X GET http://127.0.0.1/sameas-lite/datasets/test/analyse

### Implement authorisation

The username:password accepted by PUT and DELETE operations can be anything.

    $ curl -X PUT --user xxx:yyy http://127.0.0.1/sameas-lite/datasets/test/canons/canonA
    <h2>Success!</h2><p>Canon set to 'canonA'</p>

However, leaving it out results in an Access Denied error:

    $ curl -X PUT http://127.0.0.1/sameas-lite/datasets/test/canons/canonA
    <h1>Error 401</h1>
    <h2>Access Denied</h2>
    <p>You have failed to supply valid credentials, access to this resource is denied.</p><p>Please try returning to <a href="http://127.0.0.1/sameas-lite">the homepage</a>.</p>

Implement authorisation and/or describe how to configure it.

### Implement Restore a database backup

Restore a database backup currently raises an error:

    $ curl -H "Accept: text/html" -X PUT --user username:password http://127.0.0.1/sameas-lite/datasets/test/admin/restore
    <h1>Error 500</h1>
    <h2>Missing argument 2 for SameAsLite\WebApp::restoreStore()</h2>
    <p><strong>/var/www/html/sameas-lite/src/WebApp.php</strong> &nbsp; +882</p><p>Please try returning to <a href="http://127.0.0.1/sameas-lite">the homepage</a>.</p>

The API web page comments that "You can use this method to restore a previously downloaded database backup". 

src/Store.php has a function:

    public function dumpStore()

which implements /datasets/{store}/pairs. There is also a function:

    public function restoreStore($file)

which is commented as:

    * Takes the output of dumpStore and adds it into this store
    * Overwrites any existing values, leaving the others intact.
    * Assumes the source data is valid.
    * @param string $file The file name of the source data to be asserted

It seems to need a local file. This seems to be work-in-progress as src/WebApp.php has a complementary chunk of code commented-out:

    // $this->registerURL(
    // 'GET',
    // '/datasets/:store/admin/backup/',
    // 'backupStore',
    // 'Backup the database contents',
    // 'You can use this method to download a database backup file',
    // true,
    // 'text/html,text/plain'
    // );

When implementing this endpoint, it might be useful to return information about the restored back up e.g. the number of pairs inserted, the number of canons etc.

### Make Assert multiple pairs more robust

Assert multiple pairs works if no file is given:

    $ curl -H "Accept: text/plain" -X PUT --user username:password  http://127.0.0.1/sameas-lite/datasets/test/pairs
    Pairs asserted

Or if an invalid file is given:

    $ curl -H "Accept: text/plain" -X PUT --user username:password -T create_mysql_table.sql http://127.0.0.1/sameas-lite/datasets/test/pairs
    Pairs asserted

Return a count of the number of pairs asserted if the file format is valid. 

Raise an error if the file format is invalid.

---

## Update RESTAPIExamples.md

Once these issues are addressed, update the sample outputs in RESTAPIexamples.md.