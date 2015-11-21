Predicting Whether a Yelp Business is at Risk of Closing
========================================================
author: M W Hertneck
date: November 21, 2015

The Question
========================================================

Approximately 12% of companies available in the [Yelp Challenge](http://www.yelp.com/dataset_challenge) data are no longer in business.  Using the dataset, can a company's open or closed status be determined by variables, such as:  

- number of stars or frequency of a business review  
- business attributes, such as a company's noise level or that it is oriented toward children  
- business type, such as a juice bar or bike shop  


Importance
========================================================

Using the Yelp data to predict a company's current status may be helpful in predicting the company's future status:

- Could be the basis of creating an "early warning" signal for businesses that may be at risk of closing
- Could create a mechanism to prompt business owners to update their information if considered "at risk" and ensure more accurate data for Yelp users

Analysis 
========================================================
left: 55%

- 5,858 Phoenix businesses with 635 variables; reviews covered a 10-year period
- examined correlations with "open" businesses...weak (see table)
- examined correlations amongst potential predictor variables...many
- plotted potential predictors against "open" variable...selected for variance

***
<!-- html table generated in R 3.2.2 by xtable 1.8-0 package -->
<!-- Wed Nov 18 19:47:05 2015 -->
<table align="center" table border=1>
<tr> <th>VarID  </th> <th> Variable Name </th> <th> Freq </th>  </tr>
  <tr> <td align="right" td style="padding: 0px 1px 0px 1px" td style="padding: 0px 1px 0px 1px"> 18 </td> <td style="padding: 0px 1px 0px 1px"> attributes.Wheelchair.Accessible </td> <td align="right" td style="padding: 0px 1px 0px 1px"> -0.18 </td> </tr>
  <tr> <td align="right" td style="padding: 0px 1px 0px 1px"> 35 </td> <td style="padding: 0px 1px 0px 1px"> attributes.Good.For.dinner </td> <td align="right" td style="padding: 0px 1px 0px 1px"> -0.17 </td> </tr>
  <tr> <td align="right" td style="padding: 0px 1px 0px 1px"> 15 </td> <td style="padding: 0px 1px 0px 1px"> attributes.Waiter.Service </td> <td align="right" td style="padding: 0px 1px 0px 1px"> -0.15 </td> </tr>
  <tr> <td align="right" td style="padding: 0px 1px 0px 1px"> 72 </td> <td style="padding: 0px 1px 0px 1px"> cat.Restaurants </td> <td align="right" td style="padding: 0px 1px 0px 1px"> -0.15 </td> </tr>
  <tr> <td align="right" td style="padding: 0px 1px 0px 1px"> 591 </td> <td style="padding: 0px 1px 0px 1px"> attributes.Attire.casual </td> <td align="right" td style="padding: 0px 1px 0px 1px"> -0.14 </td> </tr>
  <tr> <td align="right" td style="padding: 0px 1px 0px 1px"> 8 </td> <td style="padding: 0px 1px 0px 1px"> attributes.Outdoor.Seating </td> <td align="right" td style="padding: 0px 1px 0px 1px"> -0.12 </td> </tr>
  <tr> <td align="right" td style="padding: 0px 1px 0px 1px"> 13 </td> <td style="padding: 0px 1px 0px 1px"> attributes.Take.out </td> <td align="right" td style="padding: 0px 1px 0px 1px"> -0.12 </td> </tr>
  <tr> <td align="right" td style="padding: 0px 1px 0px 1px"> 586 </td> <td style="padding: 0px 1px 0px 1px"> attributes.Alcohol.full_bar </td> <td align="right" td style="padding: 0px 1px 0px 1px"> -0.12 </td> </tr>
  <tr> <td align="right" td style="padding: 0px 1px 0px 1px"> 7 </td> <td style="padding: 0px 1px 0px 1px"> attributes.Good.For.Groups </td> <td align="right" td style="padding: 0px 1px 0px 1px"> -0.11 </td> </tr>
  <tr> <td align="right" td style="padding: 0px 1px 0px 1px"> 14 </td> <td style="padding: 0px 1px 0px 1px"> attributes.Takes.Reservations </td> <td align="right" td style="padding: 0px 1px 0px 1px"> -0.11 </td> </tr>
  <tr> <td align="right" td style="padding: 0px 1px 0px 1px"> 41 </td> <td style="padding: 0px 1px 0px 1px"> attributes.Parking.lot </td> <td align="right" td style="padding: 0px 1px 0px 1px"> -0.11 </td> </tr>
  <tr> <td align="right" td style="padding: 0px 1px 0px 1px"> 34 </td> <td style="padding: 0px 1px 0px 1px"> attributes.Good.For.lunch </td> <td align="right" td style="padding: 0px 1px 0px 1px"> -0.10 </td> </tr>

   </table>
   <br>


Results
========================================================

Using Logistic Regression, the final prediction model:

- included 21 variables and 41 interactions between these variables
- resulted in predictions with a balanced accuracy of 80%, verified by ROC Curve
- could potentially be improved using other review/hours variables or data for other cities

The full report and code can be found at:
https://github.com/margiehertneck/DSCapstone 


