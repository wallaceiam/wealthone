import { createSelector } from 'reselect';
import { BALANCE_DATA, CONTRIBUTION_DATA, DISTRIBUTION_DATA } from '../Data';
import { IGoalInput } from '../IGoalInput';
import { getCurrentNetWorth } from './NetWorthSelector';

export const getGoalInput = state => {
  return (
    state.goal || {
      birthDate: new Date(1978, 11, 26),
      currentAge: 40,
      earnings: 55000,

      contributions: 0,
      pension: 0,
      investmentStyle: 3,
      lifeStyle: 40,
      retirementAge: 65,
    }
  );
};

export const getGoalResults = createSelector(
  [getGoalInput, getCurrentNetWorth],
  (input, netWorth, _date) => {
    const result = calculate(input, 'pound', netWorth);

    return result;
  },
);

const Config = {
  calculation: {
    lifeExpectancy: 96,
    // inflation: 0.02,
    inflation: 0,
    realSalaryGrowth: 0.01,
    statePension: 8500,
    useComputedAccumulationArrays: false,
  },
};

const calculate = (input: IGoalInput, currency: string, savings: number) => {
  const ageDifMs = Date.now() - new Date(input.birthDate).getTime();
  const ageDate = new Date(ageDifMs); // miliseconds from epoch
  const currentAge = Math.abs(ageDate.getUTCFullYear() - 1970);

  const accumData = computeAccumArrays(currency),
    balanceData = Config.calculation.useComputedAccumulationArrays
      ? accumData.balanceData
      : BALANCE_DATA;
  const contributionData = Config.calculation.useComputedAccumulationArrays
    ? accumData.contributionData
    : CONTRIBUTION_DATA;

  const yrsTill = input.retirementAge - currentAge;
  const retireYrs = Math.max(
    0,
    Config.calculation.lifeExpectancy - input.retirementAge,
  );
  const inflationFactor = Math.pow(1 + Config.calculation.inflation, -yrsTill);
  const e =
    Config.calculation.realSalaryGrowth +
    Config.calculation.inflation +
    Config.calculation.realSalaryGrowth * Config.calculation.inflation;
  const preRetIncomeProjected = input.earnings * Math.pow(1 + e, yrsTill);
  const incomeGoalProjected = (input.lifeStyle / 100) * preRetIncomeProjected;
  const incomeGoal = incomeGoalProjected * inflationFactor;
  let stateBenRet = Config.calculation.statePension / inflationFactor,
    savingsGoal,
    unitsOfAssets,
    unitsOfContrib,
    avgSavingsExpect,
    avgSavingsExpectReal,
    avgIncomeExpect,
    poorSavingsExpect,
    poorSavingsExpectReal,
    poorIncomeExpect,
    projectedIncomePoorPercentage,
    projectedSavingsPoorPercentage,
    projectedIncomeAveragePercentage,
    projectedSavingsAveragePercentage;

  if (
    input.retirementAge < 68 ||
    Config.calculation.useComputedAccumulationArrays
  ) {
    stateBenRet = 0;
  }

  savingsGoal = Math.max(
    0,
    (incomeGoalProjected -
      ((input.pension / 100) * preRetIncomeProjected) /
        (1 + Math.round(e * 100) / 100) -
      stateBenRet) /
      DISTRIBUTION_DATA[0][retireYrs - 1],
  );
  savingsGoal = 1000 * savingsGoal * inflationFactor;

  unitsOfAssets = savings / 1000;
  unitsOfContrib = input.contributions * 12;

  avgSavingsExpect =
    balanceData[Math.max(0, yrsTill - 1)][2 * input.investmentStyle] *
    unitsOfAssets;
  avgSavingsExpect +=
    contributionData[Math.max(0, yrsTill - 1)][2 * input.investmentStyle] *
    unitsOfContrib;
  avgSavingsExpectReal = avgSavingsExpect * inflationFactor;

  avgIncomeExpect =
    (DISTRIBUTION_DATA[0][retireYrs - 1] * avgSavingsExpect) / 1000;
  avgIncomeExpect += (preRetIncomeProjected * input.pension) / 100;
  avgIncomeExpect += stateBenRet;
  avgIncomeExpect = inflationFactor * avgIncomeExpect;

  poorSavingsExpect =
    balanceData[Math.max(0, yrsTill - 1)][2 * input.investmentStyle + 1] *
    unitsOfAssets;
  poorSavingsExpect +=
    contributionData[Math.max(0, yrsTill - 1)][2 * input.investmentStyle + 1] *
    unitsOfContrib;
  poorSavingsExpectReal = poorSavingsExpect; // * inflationFactor;

  poorIncomeExpect =
    (DISTRIBUTION_DATA[0][retireYrs - 1] * poorSavingsExpect) / 1000;
  poorIncomeExpect += (preRetIncomeProjected * input.pension) / 100;
  poorIncomeExpect += stateBenRet;
  poorIncomeExpect = inflationFactor * poorIncomeExpect;

  projectedIncomePoorPercentage =
    (poorIncomeExpect / incomeGoal) * input.lifeStyle;
  projectedIncomeAveragePercentage =
    (avgIncomeExpect / incomeGoal) * input.lifeStyle;

  if (savingsGoal > 0) {
    projectedSavingsPoorPercentage =
      (poorSavingsExpectReal / savingsGoal) * input.lifeStyle;
    projectedSavingsAveragePercentage =
      (avgSavingsExpectReal / savingsGoal) * input.lifeStyle;
  } else {
    projectedSavingsPoorPercentage = 100;
    projectedSavingsAveragePercentage = 100;
  }

  return {
    projectedIncomeGoal: Math.round(incomeGoal / 100) * 100,
    projectedIncomePoor: Math.round(poorIncomeExpect / 100) * 100,
    projectedIncomePoorPercentage: Math.round(projectedIncomePoorPercentage),
    projectedIncomeAverage: Math.round(avgIncomeExpect / 100) * 100,
    projectedIncomeAveragePercentage: Math.round(
      projectedIncomeAveragePercentage,
    ),

    projectedSavingsGoal: Math.round(savingsGoal / 1000) * 1000,
    projectedSavingsPoor: Math.round(poorSavingsExpectReal / 1000) * 1000,
    projectedSavingsPoorPercentage: Math.round(projectedSavingsPoorPercentage),
    projectedSavingsAverage: Math.round(avgSavingsExpectReal / 1000) * 1000,
    projectedSavingsAveragePercentage: Math.round(
      projectedSavingsAveragePercentage,
    ),
  };
};

const computeAccumArrays = currency => {
  let balance_accum_array = [],
    contribution_accum_array = [],
    B87 = 0,
    B88,
    B89,
    B26_D28 = [
      [1, -0.3025, 0.0087],
      [-0.3025, 1, 0.2697],
      [0.0087, 0.2697, 1],
    ],
    B48_D50 = [
      [0.14, 0.04, 0.005],
      [0.14, 0.04, 0.005],
      [0.14, 0.04, 0.005],
    ],
    share_bond_cash_euro = [
      [0, 0, 100],
      [10, 50, 40],
      [35, 65, 0],
      [50, 50, 0],
      [75, 25, 0],
      [85, 15, 0],
      [100, 0, 0],
    ],
    share_bond_cash_dollar = [
      [0, 0, 100],
      [15, 50, 35],
      [35, 65, 0],
      [50, 50, 0],
      [75, 25, 0],
      [85, 15, 0],
      [100, 0, 0],
    ],
    share_bond_cash_pound = [
      [0, 0, 100],
      [15, 30, 55],
      [40, 45, 15],
      [50, 45, 5],
      [75, 25, 0],
      [85, 15, 0],
      [100, 0, 0],
    ],
    b_accum_val,
    c_accum_val,
    share_bond_cash;

  if (currency === 'euro') {
    share_bond_cash = share_bond_cash_euro;
  } else if (currency === 'dollar') {
    share_bond_cash = share_bond_cash_dollar;
  } else {
    share_bond_cash = share_bond_cash_pound;
  }

  for (let yr = 1; yr <= 80; yr++) {
    balance_accum_array[yr - 1] = [];
    contribution_accum_array[yr - 1] = [];
    for (let k = 0; k < share_bond_cash.length; k++) {
      B88 =
        (0.0875 * share_bond_cash[k][0] +
          0.06 * share_bond_cash[k][1] +
          0.0475 * share_bond_cash[k][2]) /
        100;
      B89 = 0;
      for (let i = 0; i < 3; i++) {
        for (let j = 0; j < 3; j++) {
          B89 +=
            (B26_D28[i][j] *
              B48_D50[i][j] *
              B48_D50[j][i] *
              share_bond_cash[k][i] *
              share_bond_cash[k][j]) /
            10000;
        }
      }
      B89 = Math.sqrt(B89);
      B87 = 0;
      b_accum_val =
        1000 *
        Math.exp((B88 - (B89 * B89) / 2) * yr + B87 * B89 * Math.sqrt(yr));
      balance_accum_array[yr - 1].push(b_accum_val);
      c_accum_val = b_accum_val / 1000;
      contribution_accum_array[yr - 1].push(
        yr === 1
          ? c_accum_val
          : c_accum_val + contribution_accum_array[yr - 2][2 * k] * 1.035,
      );
      B87 = -1.282;
      b_accum_val =
        1000 *
        Math.exp((B88 - (B89 * B89) / 2) * yr + B87 * B89 * Math.sqrt(yr));
      balance_accum_array[yr - 1].push(b_accum_val);
      c_accum_val = b_accum_val / 1000;
      contribution_accum_array[yr - 1].push(
        yr === 1
          ? c_accum_val
          : c_accum_val + contribution_accum_array[yr - 2][2 * k + 1] * 1.035,
      );
    }
  }
  return {
    balanceData: balance_accum_array,
    contributionData: contribution_accum_array,
  };
};
