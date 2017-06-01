SELECT
*
FROM sys.columns
/* Das ist der interessante Part */
OPTION
(
    QUERYTRACEON 3604, /* 3604 – it redirects trace output to the client so it appears in the SSMS messages tab. */
    QUERYTRACEON 9292, /* 9292 - With this enabled, we get a report of statistics objects which are considered ‘interesting’ by the query optimizer when compiling, or recompiling the query in question.  For potentially useful statistics, just the header is loaded. */
    QUERYTRACEON 9204  /* 9204 - With this enabled, we see the ‘interesting’ statistics which end up being fully loaded and used to produce cardinality and distribution estimates for some plan alternative or other. Again, this only happens when a plan is compiled or recompiled – not when a plan is retrieved from cache. */
)