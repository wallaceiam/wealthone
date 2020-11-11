// https://github.com/ebradyjobory/finance.js/blob/master/finance.js

// Compound Interest (CI)

// e.g., If rate is 4.3%, the compoundings per period is 4, the principal is $1,500, and the number of periods is 6, the compound interest is $1,938.84.

// finance.CI(4.3, 4, 1500, 6 );
// => 1938.84
export const CI = (rate, numOfCompoundings, principal, numOfPeriods) => {
  const ci =
    principal *
    Math.pow(
      1 + rate / 100 / numOfCompoundings,
      numOfCompoundings * numOfPeriods,
    );
  return Math.round(ci * 100) / 100;
};

// Compound Annual Growth Rate (CAGR)

// e.g., If the beginning value is $10,000, the ending value is $19,500, and the number of periods is 3, the CAGR is 24.93%.

// finance.CAGR(10000, 19500, 3);
// => 24.93
export const CAGR = (beginningValue, endingValue, numOfPeriods) => {
  const cagr = Math.pow(endingValue / beginningValue, 1 / numOfPeriods) - 1;
  return Math.round(cagr * 10000) / 100;
};
