###############################################################################
# Title: Patent Search and Theme Extraction
# 
# Author: 
###############################################################################
#save(list = ls(all=TRUE), file = paste(workingDir, '/temp.RData', key, sep=''))
#load("temp.RData")

rm(list=ls())
require(httpRequest)
require(tm)
require(NMF)

setwd("/Users/oconste/Documents/Quid/R_code/")

##---------------------------------------------------------------------
##     GET THE LIST OF PATENTS THAT MEET SEARCH PATTERN
##       ** WILL ONLY SELECT THE FIRST 50 PATENTS **
##---------------------------------------------------------------------
searchURL <- c("http://patft.uspto.gov/netacgi/nph-Parser?Sect1=PTO2&Sect2=HITOFF&p=1&u=%2Fnetahtml%2FPTO%2Fsearch-adv.htm&r=0&f=S&l=50&d=PTXT&Query=")
patentURL <- c("http://patft.uspto.gov")


## READ THE SEARCH PATTERNS, AND THE TITLE OF THE SEARCH
## TITLE: <title>
## abst/(keyword or keyword) and (keyword or keyword)
##
SEARCH_INPUT <- "EXAMPLE_2_unrelated_search.txt"
###
searchList <- readLines(SEARCH_INPUT)
searchTitle <- strsplit(searchList[1], " ")[[1]][2]


## CREATE THE WORKING DIRECTORIES FROM THE SEARCH TITLE
workingDir <- paste(getwd(), '/', searchTitle, sep="")
dir.create(workingDir,  showWarnings = FALSE)
dir.create(paste(workingDir, '/html/', sep=''),  showWarnings = FALSE)
dir.create(paste(workingDir, '/abstract/', sep=''),  showWarnings = FALSE)


## INITIALIZE THE PATENT LIST
count <- 0
patentList <- list()

## SPIN THROUGH ALL THE SEARCH PATTERNS
for (i in 2:length(searchList)) {
	
	## PREPARE THE SEARCH FOR PASSING ON THE URL
	tline <- gsub("\\(", "%28", searchList[i])
	tline <- gsub("\\)", "%29", tline)
	tline <- gsub("\\/", "%2F", tline)
	tline <- gsub(" ", "+", tline)
	cat("LINE: ", tline, "\n")
	
	## ISSUE THE PATENT SEARCH
	page <- getURL(paste(searchURL, tline, sep=""))
	
	## SAVE THE RESULTING SEARCH RESULTS PAGE 
	sink(paste(workingDir, '/', "search_page_", i, sep=""))
	cat(page)
	cat("\n")
	sink()
	pageLines <- readLines(paste(workingDir, '/', "search_page_", i, sep=""))
	
	## INITIALIZE LOOP CONTROL VARIABLES
	refOne <- TRUE
	refTwo <- FALSE
	start <- grep("PAT. N", pageLines)
	end   <- grep("name=\"bottom\"", pageLines)
	
	## CHECK IF PATENTS ARE FOUND, 0=FOUND A PATENT, 1=NO PATENTS FOUND
	noPatentsFound <- length(grep("No patents have matched your query", pageLines))
	
	## EXTRACT THE PATENT #, URL, AND TITLE FROM THE SEARCH PAGE
	if (noPatentsFound == 0) {
		for (p in start:end) {
			
			## FIRST HREF HAS THE PATENT NUMBER AND THE PATENT SEARCH URL IS ALSO SAVED
			if (grepl("HREF", pageLines[p]) & refOne == TRUE) {
	
				## PLUCK THE PATENT NUMBER AND URL FOR FULL TEXT
				hrefLine <- substr(pageLines[p],25,nchar(pageLines[p]))
				ss <- strsplit(hrefLine, '>')
				href <- ss[[1]][1]
				patNum <- ss[[1]][2]
				patNum <- gsub(',','',strsplit(patNum, '<')[[1]][1])
				
				patentList[[patNum]]$URL <- href
				patentList[[patNum]]$SEARCH <- searchList[i]
				
				#cat("\nPATENT#=", patNum, "\n")
				#cat("HREF=", href, "\n")
				
				refOne <- FALSE
				refTwo <- TRUE
				next
			}
			
			## SECOND HREF HAS THE PATENT TITLE
			if (grepl("HREF", pageLines[p]) & refTwo == TRUE) {
				
				## PLUCK THE PATENT TITLE
				hrefLine <- substr(pageLines[p],25,nchar(pageLines[p]))
				ss <- strsplit(hrefLine, '>')
				href <- ss[[1]][1]
				patTitle <- ss[[1]][2]
				patTitle <- gsub(',','',strsplit(patTitle, '<')[[1]][1])
				
				patentList[[patNum]]$TITLE <- patTitle
				cat("FOUND PATENT NUMBER = ", patNum, " TITLE = ", patTitle, "\n")
	
				count <- count + 1
				refOne <- TRUE
				refTwo <- FALSE
				next
			} # end if
		} # end for
	} # end if
} # end for

##---------------------------------------------------------------------
## GET ALL THE PATENTS, FULL TEXT
##   *** THIS CAN TAKE A WHILE DEPENDING ON THE NUMBER OF PATENTS ***
##---------------------------------------------------------------------
for (key in names(patentList)) {
	
	## SKIP DEAD KEYS IN patentList
	if (key != "") {
		cat("DOWNLOADING PATENT = ", key,"\n")
		
		## GET THE PATENT
		page <- getURL(paste(patentURL, patentList[[key]], sep=""))
		
		## SAVE THE PATENT INTO A FILE FOR LOCAL PROCESSING
		sink(paste(workingDir, '/html/', key, ".html", sep=''))
		cat(page)
		cat("\n")
		sink()
		
	}
	
}

##---------------------------------------------------------------------
##   EXTRACT THE ABSTRACT FROM EACH PATENT HTML FILE
##   *** ONLY THE ABSTRACT IS USED IN THE CORPUS ***
##---------------------------------------------------------------------
for (key in names(patentList)) {
	if (key != "") {
		cat("PROCESSING PATENT:: FIND ABSTRACT = ", key,"\n")
		
		patentHTML <- readLines(paste(workingDir, '/html/', key, '.html', sep=""))
		
		abstractLineNum <- grep("Abstract", patentHTML)[1]
		
		abstract <- ''
        indx <- 1
        for (l in abstractLineNum+1:10000) {
			if (grepl('</P>', patentHTML[l]) | grepl('BACKGROUND OF THE INVENTION', patentHTML[l])) {
				sink(paste(workingDir, '/abstract/', key, sep=''))
				cat(abstract)
				cat("\n")
				sink()
				break	
			} else {
				line <- gsub('</I></B>',' ', patentHTML[l])
				line <- gsub('<P>','', line)
				line <- gsub('</P>','', line)
				line <- gsub('<B><I>',' ', line) 
				abstract[indx] <- line
				indx <- indx + 1
			 }
		}
	}	
}


###-------------------------------------------------------------
###   CREATE DOCUMENT CORPUS FROM THE PATENT ABSTRACTS
###-------------------------------------------------------------
patent <- Corpus(DirSource(paste(workingDir, '/abstract/', key, sep='')), readControl=list(reader=readPlain))
						 
# CLEAN UP THE CORPUS
for (i in 1:length(patent)) {
	patent[[i]] <- removeWords(patent[[i]], stopwords("english"))
	patent[[i]] <- removePunctuation(patent[[i]])
	patent[[i]] <- removeNumbers(patent[[i]])
	patent[[i]] <- stripWhitespace(patent[[i]])
	patent[[i]] <- stemDocument(patent[[i]])
}	

dtm <- DocumentTermMatrix(patent,
		control = list(weighting = weightTf,
				stopwords = TRUE))

## TRIM THE DTM MATRIX DOWN REMOVING SPARSE TERMS AND CONVERT TO MATRIX
dtm.trim <- removeSparseTerms(dtm, 0.85)
dtm.trim.m <- as.matrix(inspect(dtm.trim))

#str(dtm.trim.m)


###-------------------------------------------------------------
###   NON-NEGATIVE MATRIX FACTORIZATION (NMF) USED TO ESTABLISH 
###      THEMES AND DOCUMENT RELATIONSHIPS
###-------------------------------------------------------------

## SELECT THE NUMBER OF THEMES TO EXTARCT
numThemes <- 3
res <- nmf(dtm.trim.m, numThemes)

## HEATMAP THAT SHOWS HOW TERMS RELATE TO THEMES
metaHeatmap(res)

## DISPLAY RESULTS
round(basis(res),3)
t(round(coef(res),3))


## CONSOLIDATE THE THEME DATA INTO A LIST, AND CREATE A THEME LABEL FROM TOP 5 TERMS
themes <- list()
themeLabels <- vector()
for (t in 1:numThemes) {
	tKey <- paste("Theme", t, sep='-')
	themes[[tKey]]$WORDS <- names((coef(res)[t,order((coef(res)[t,]), decreasing = TRUE)]))
	themes[[tKey]]$LABEL <- gsub(" ", "_", do.call("paste", as.list(themes[[tKey]]$WORDS[1:5])))
	themeLabels[t] <- themes[[tKey]]$LABEL
}

## PRINT THEMES
themes

## APPLY LABELS
colnames(basis(res)) <- names(themes)
round(basis(res),3)

###-------------------------------------------------------------
###  WRITE GML
###-------------------------------------------------------------
nodes <- themeLabels
nodes <- c(nodes, rownames(basis(res)))
edges <- as.matrix(basis(res))

nodeNum <- 1

sink(paste(workingDir,"/THEME.gml", sep=""))

## WRITE THE NODES
cat("graph \n [ \n  ")
for (n in 1:length(nodes)) {
	cat("  node\n  [ \n")
	cat("      id ", nodeNum, "\n")
	cat("      label ", nodes[n], "\n" )
	cat("  ]\n")
	nodeNum <- nodeNum + 1
}

## WRITE THE EDGES
for (t in 1:ncol(edges)) {
	for (e in 1:nrow(edges)) {
		if (edges[e,t] >= 1) {
			cat("  edge \n  [\n")
			cat("     source ", e+numThemes, "\n")
			cat("     target ", t, "\n")
			cat("     value  ", edges[e,t], "\n")
			cat("  ]\n")
	    }
	}
}
cat("]\n")
sink()


###-------------------------------------------------------------
###  WRITE DETAILED REPORT
###-------------------------------------------------------------
dtmTable <- as.data.frame(dtm.trim.m)
basisTable <- as.data.frame(round(basis(res),3))

sink(paste(workingDir,"/REPORT.txt", sep=""))
for (n in names(patentList)) {

	if (n != "") {
		cat("\n\n----------------------------- ", n, " --------------------------------\n")
		cat("  PATENT: ", n, "\n")
		cat("  TITLE:  ", patentList[[n]]$TITLE, "\n")
		cat("  SEARCH: ", patentList[[n]]$SEARCH, "\n")
		cat("    BASIS                THEMES \n")
		for (b in 1:numThemes) {
			cat("    ", basisTable[n, b], ":", themeLabels[b], "\n")
        }
		cat("  TERMS: \n") 
		print(dtmTable[n,])
	}
}
sink()



