#pragma once
#ifndef _STATISTICS_TEST_FUNCTIONS_H_
#define _STATISTICS_TEST_FUNCTIONS_H_



struct statistics
{
	unsigned int   myNum;
	double mySum;
	double myMean;
	double myVar;          // Variance
	double mySumSqs;       // Sum of Squares
	int  myValidVar;       // Valid variance flag
	double myMax;
	double myMin;
	int firstTime;
};

void recalculate(struct statistics* ptr);


void resetStatistic(struct statistics* ptr);
void accumulateStatistic(struct statistics* ptr, double yourValue);
double getMeanStatistic(struct statistics* ptr);
double getVarianceStatistic(struct statistics* ptr);
double getStdDeviationStatistic(struct statistics* ptr);
unsigned int getNStatistic(struct statistics* ptr);
double getMaximumStatistic(struct statistics* ptr);
double getMinimumStatistic(struct statistics* ptr);
int isValidStatistic(struct statistics* ptr);   // returns 1 if valid / 0 if not valid
void showStatistics(struct statistics* ptr);
void simpleLogStatistics(struct statistics* ptr);


#endif