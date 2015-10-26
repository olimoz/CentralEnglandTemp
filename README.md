# CentralEnglandTemp

##Trends Analysis Tool in Shiny

This a straightforward app to use. It will open by showing you a chart of the Central England Temperature record, 356yrs of annual temperature averages for central England, as recorded by instruments. This is NOT a proxy record, such a tree rings.

You then have the option to filter that data and view trends either as Loess or as Changepoints.

Changepoints illustrate 95% confidence that the mean of the series has changed.

###Summarise data
This changes the period over which the mean is calculated:
Year, Decade or Century.

Since the series starts in 1659 and ends in 2014, any analysis of Century is not really comparing like with like since the 17th and 21st centuries are incomplete.

###Filter By & Filter value
this allows you to filter the data, say by Month. Having chosen that filter the following dropdown will allow you to choose which month you want to filter by.

If you select 'Jan' then the chart will show trends in the mean temperatures for January. By analogy, the same applies to the other options: Season, Decade, Century.

Note, by filtering on a decade or century, the chart will 'zoom' in on that period, to the exclusion of other dates.

#How To Reset the Filters!
To reset, just select 'No Filter' from 'Filter By'.

##Warnings
It is possible to select combinations of data which do not lead to a changepoint analysis. For example, filtering by decade results in only 10 records, which is insufficent for changepoint analysis, although it is sufficient for Loess smooth.

The tool will issue an error explaining this, should the situation arise.
