themeExtraction
================

## Background

The following is a program I wrote for an interview with Quid (Quid.com) in 2011.
During the interview I was asked how I would relate information found in the US patent DB with 
trends occurring in the market place.  I gave a really terrible answer and knew the interview
was going down the tubes.  I spent that next couple days or so researching the US patent DB and techniques 
for doing text analytics.  I developed the following program as a "better" response to
the question.  

Quid was heavily into using Gephi as a graph visualization tool, so the output of the 
search and text analysis is a raw input file to Gephi.  In each example directory there is a pdf
with the Gephi generated graph visualization. The formatting of each visual was done by hand, to make them look nice.

I forwarded them the program and the analysis, and had another interview, however
I did not get the job.

## Files/Directories

File/Directories                | Description
------------------------------- | -----------------------------------------------
EXAMPLE1                        | Output from search EXAMPLE1
EXAMPLE2                        | Output from search EXAMPLE2
EXAMPLE3                        | Output from search EXAMPLE3
EXAMPLE_1_companies_search.txt  | Search criteria for EXAMPLE1, search includes top technology companies to see if there are any relationships between the technologies that being patented by these companies.
EXAMPLE_2_unrelated_search.txt  | Search criteria for EXAMPLE2, search for unrelated items, a negative case to see how the algorithm pulls themes from unrelated patents.
EXAMPLE_3_whatsHot_search.txt   | Search criteria for EXAMPLE3, keywords include the top technologies and trends at the time to see what was being invented that is addressing current trends.
README.md                       | This file.
themeExtraction.R               | Code to search and extract patents, create document to text matrix, non-negative matrix factorization, format data for Gephi, and create a detailed report of the results.  ** THE CODE NO LONGER WORKS AS THE PATENT DB SEARCH HAS CHANGED **



## ThemeExtraction.R:

The following application searches the patent full text database using a collection of keywords. 

The basic approach comes from Chapter 10, Finding Independent Features
in “Programming Collective Intelligence”, by Toby Segaram. 

I used R
to search and parse the full-text patent database with a collection
of user supplied queries, mined the text using the R package “tm” to
filter/refine/pre-process the text into a document-term matrix
suitable for use with the R package “NMF” to perform the non-negative
matrix factorization used to isolate the “themes” that tie the patents
together. The top-five features or words are used to “label” each
theme, highlighting what the theme encompasses. The data is then
formatted into GML for import into Gephi.

This process and code is not a result.  It is a tool/technique for
refining the analysis of the data as it relates to particular
keywords, not unlike other unsupervised learning techniques used to
“derive” intelligence from seemingly unrelated data.


## Description:

themeExtraction.R contains all the code to search, retrieve, and parse
patent data, and perform the data mining and NMF. Also generates the
GML and a detailed report.

To run the code create a file with any collection of valid patent
full-text searches or use one of the examples as a template. Then
replace the SEARCH_INPUT value, near the top of the code:

 SEARCH_INPUT <- "EXAMPLE_2_unrelated_search.txt"

Also, before you run NMF, you need to tell nmf how many themes you are
looking for:

 SELECT THE NUMBER OF THEMES TO EXTRACT

numThemes <- 3
res <- nmf(dtm.trim.m, numThemes)


## EXAMPLES:
I created a few examples to see how the process performs.

### EXAMPLE_1_companies.txt: search patterns
Looked up specific companies and technology in a specific area, and
added a social network and internet retailer to the mix.

```
 TITLE: EXAMPLE1
 an/IBM and abst/data
 an/Facebook
 an/Amazon and abst/data
 an/EMC and abst/virtual and abst/data
 an/NetApp and abst/virtual and abst/data
 an/Hewlett-Packard and abst/data and abst/virtual
```

### EXAMPLE_2_unrelated_search.txt
 Search on seemingly unrelated topics

```
 TITLE: EXAMPLE2
 abst/computer and telecommunications
 abst/process and metal
```

### EXAMPLE_3_whatsHot_search.txt
 A collection of “hot” topics/technology/trends

```
 TITLE: EXAMPLE3
 abst/payment and credit and card and mobile
 abst/social and network and transaction
 abst/loans and (payment or credit or schedule)
 abst/payment and systems
 abst/financial and service and (mobile or home or shopping)
 abst/(social and network) and (message or friend or search or
 associate or shopping)
 abst/(social and network) and (credit or card or photo or email)
 abst/iphone
 abst/andriod
 abst/tablet
```


