#pragma warning( disable : 4305)
#pragma warning( disable : 4244)
// This file contains test code .. .testing of capabilities implemented in other c++ files
// but reverse engineered into a C environment


#include <math.h>
#include <stdio.h>
#include "def_ZARF_9.h"

#include "StatisticsFunction_ZARF_9.h"

const char STATISTICS_VERSION_INFORMATION[] = "File StatisticsFunction Edit revision date is 15 August 2020 4:22 PM";

const char* statisticsVersionPtr = STATISTICS_VERSION_INFORMATION;





static struct statistics XStatistics;
static struct statistics YStatistics;
static struct statistics ZStatistics;

const static struct statistics* X_statistics_ptr = &XStatistics;
const static struct statistics* Y_statistics_ptr = &YStatistics;
const static struct statistics* Z_statistics_ptr = &ZStatistics;



void recalculate(struct statistics* ptr);


void resetStatistic(struct statistics* ptr)
{
	ptr->myNum = 0;
	ptr->mySum = 0;
	ptr->myMean = 0;         // Mean
	ptr->myVar = 0;          // Variance
	ptr->mySumSqs = 0;       // Sum of Squares
	ptr->myValidVar = 0;     // Valid variance flag
	ptr->myMax = 0;
	ptr->myMin = 0;
	ptr->firstTime = 1;
}

// Design decision ... for first release passing a double by value is acceptable
// even though passing a pointer only requires half the number of bytes

void accumulateStatistic(struct statistics* ptr, double yourValue)
{
	if (1 == ptr->firstTime)
	{
		ptr->firstTime = 0;
		ptr->myMax = yourValue;
		ptr->myMin = yourValue;
	}
	ptr->myValidVar = 0;
	ptr->myNum++;
	ptr->mySum += yourValue;
	ptr->mySumSqs += yourValue * yourValue;

	if (ptr->myMax < yourValue)
	{
		ptr->myMax = yourValue;
	}

	if (ptr->myMin > yourValue)
	{
		ptr->myMin = yourValue;
	}
}
double getMeanStatistic(struct statistics* ptr)
{
	recalculate(ptr);
	return ptr->myMean;
}
double getVarianceStatistic(struct statistics* ptr)
{
	recalculate(ptr);
	return ptr->myVar;
}
double getStdDeviationStatistic(struct statistics* ptr)
{
	recalculate(ptr);
	return sqrt(ptr->myVar);
}
unsigned int getNStatistic(struct statistics* ptr)
{
	return ptr->myNum;
}

double getMaximumStatistic(struct statistics* ptr)
{
	return ptr->myMax;
}
double getMinimumStatistic(struct statistics* ptr)
{
	return ptr->myMin;
}

int isValidStatistic(struct statistics* ptr)
{
	recalculate(ptr);
	if (ptr->myValidVar != 0)
	{
		return 1;
	}
	return 0; // not valid
}



void recalculate(struct statistics* ptr)
{
	if (ptr->myNum < 1)
	{
		ptr->myMean = 0;
		ptr->myVar = 0;
		ptr->myValidVar = 0;
		return;
	}

	ptr->myMean = ptr->mySum / (double)ptr->myNum;
	double  term = (ptr->mySumSqs * (double)ptr->myNum) - (ptr->mySum * ptr->mySum);

	if (term < 0)
	{
		ptr->myVar = 0;
		ptr->myValidVar = 0;
	}
	else
	{
		if (ptr->myNum > 1)
		{
			ptr->myVar = term / (double)((double)(ptr->myNum - 1) * (double)ptr->myNum);
			ptr->myValidVar = 1;
		}
		else
		{
			ptr->myVar = 0;
			ptr->myValidVar = 0;
		}
	}




}

void showStatistics(struct statistics* ptr)
{
	printf("is valid [%d]\n", isValidStatistic(ptr));
	printf("N        [%u]\n", getNStatistic(ptr));
	printf("Mean     <%10.6f>\n", getMeanStatistic(ptr));
	printf("Sum      <%10.6f>\n", ptr->mySum);
	printf("SumSqrs  <%10.6f>\n", ptr->mySumSqs);
	printf("Variance <%10.6f>\n", getVarianceStatistic(ptr));
	printf("Maximum  <%10.6f>\n", getMaximumStatistic(ptr));
	printf("Minimum  <%10.6f>\n", getMinimumStatistic(ptr));
	printf("\n");
}
void simpleLogStatistics(struct statistics* ptr)
{
	char buffer[128];
	buffer[127] = '\0';
	sprintf(buffer, "is valid [%d]", isValidStatistic(ptr)); simpleLog(buffer);
	sprintf(buffer, "N        [%u]", getNStatistic(ptr)); simpleLog(buffer);
	sprintf(buffer, "Mean     <%10.6f>", getMeanStatistic(ptr)); simpleLog(buffer);
	sprintf(buffer, "Sum      <%10.6f>", ptr->mySum); simpleLog(buffer);
	sprintf(buffer, "SumSqrs  <%10.6f>", ptr->mySumSqs); simpleLog(buffer);
	sprintf(buffer, "Variance <%10.6f>", getVarianceStatistic(ptr)); simpleLog(buffer);
	sprintf(buffer, "Maximum  <%10.6f>", getMaximumStatistic(ptr)); simpleLog(buffer);
	sprintf(buffer, "Minimum  <%10.6f>", getMinimumStatistic(ptr)); simpleLog(buffer);
	simpleLogBlankLine();
}