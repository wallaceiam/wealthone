import {createSelector} from 'reselect';
import {IsAsset} from '../../Models/Account';
import {toDate} from '../DateHelpers';
import {getAccounts, getRecords} from './AccountSelector';

const sameYear = (d1, d2) =>
  toDate(d1).getFullYear() === toDate(d2).getFullYear();

const sameTaxYear = (d1, d2) => {
  const da = toDate(d1);
  const db = toDate(d2);
  const fyA =
    da.getFullYear() +
    (da.getMonth() >= 3 /* apr */ || (da.getMonth() === 3 && da.getDate() > 5)
      ? 1
      : 0);
  const fyB =
    db.getFullYear() +
    (db.getMonth() >= 3 /* apr */ || (db.getMonth() === 3 && db.getDate() > 5)
      ? 1
      : 0);
  return fyA === fyB;
};

const reduceCalc = (p, c, i) => {
  const twrr =
    i > 0 && p[i - 1].total !== 0
      ? (c.total - c.netflows - p[i - 1].total) / p[i - 1].total
      : 0;
  const twrrPercent =
    p.reduce((tp, tc) => tp * (1 + tc.twrrRaw), 1) * (1 + twrr) - 1;

  const yearlyTwrrPercent =
    p
      .filter(x => sameYear(x.date, c.date))
      .reduce((tp, tc) => 1 + tp * tc.twrrRaw, 1) *
      (1 + twrr) -
    1;
  const beginningOfTheYear = p.find(x => sameYear(x.date, c.date)) || {
    total: 0,
    yearlyNetflows: 0,
    taxYearNetflows: 0,
  };
  const yearlyGrowth = c.total - beginningOfTheYear.total;
  const yearlyGrowthPercent =
    beginningOfTheYear.taxYearNetflows !== 0
      ? (c.total - beginningOfTheYear.total) /
        beginningOfTheYear.taxYearNetflows
      : 0;

  const totalNetflows = (i > 0 ? p[i - 1].totalNetflows : 0) + c.netflows;
  const yearlyNetflows =
    (i > 0 && sameYear(p[i - 1].date, c.date) ? p[i - 1].yearlyNetflows : 0) +
    c.netflows;
  const taxYearNetflows =
    (i > 0 && sameTaxYear(p[i - 1].date, c.date)
      ? p[i - 1].taxYearNetflows
      : 0) + c.netflows;

  const totalPL = i > 0 ? c.total - totalNetflows - p[0].total : 0;
  const totalPLPerc = i > 0 && p[0].total !== 0 ? totalPL / p[0].total : 0;

  const yearlyPL =
    i > 0
      ? c.total -
        yearlyNetflows -
        (beginningOfTheYear.total - beginningOfTheYear.yearlyNetflows)
      : 0;

  const yearlyPLPerc =
    i > 0 && beginningOfTheYear.total - beginningOfTheYear.yearlyNetflows !== 0
      ? (c.total -
          yearlyNetflows -
          (beginningOfTheYear.total - beginningOfTheYear.yearlyNetflows)) /
        (beginningOfTheYear.total - beginningOfTheYear.yearlyNetflows)
      : 0;
  p.push({
    ...c,
    changeAmount: i > 0 ? c.total - p[i - 1].total : 0,
    changePercent:
      i > 0 && p[i - 1].total !== 0
        ? (c.total - p[i - 1].total) / p[i - 1].total
        : 0,
    twrrRaw: twrr,
    twrrPercent: twrrPercent,
    yearlyTwrrPercent: yearlyTwrrPercent,
    yearlyGrowth: yearlyGrowth,
    yearlyGrowthPercent: yearlyGrowthPercent,
    totalNetflows: totalNetflows,
    yearlyNetflows: yearlyNetflows,
    taxYearNetflows: taxYearNetflows,
    totalPL: totalPL,
    totalPLPercent: totalPLPerc,
    yearlyPL: yearlyPL,
    yearlyPLPercent: yearlyPLPerc,
  });
  return p;
};

export const getNetWorth = createSelector(
  [getAccounts, getRecords],
  (accounts, records) =>
    records
      .map(c => {
        return {
          date: c.date,
          assets: c.totals.reduce((tp, tc) => {
            const account = accounts.find(x => x.id === tc.id);
            return (
              tp +
              (account !== null && account.isAsset === IsAsset.Asset
                ? tc.amount
                : 0)
            );
          }, 0),
          liabilities: c.totals.reduce((tp, tc) => {
            const account = accounts.find(x => x.id === tc.id);
            return (
              tp +
              (account !== null && account.isAsset === IsAsset.Liability
                ? tc.amount
                : 0)
            );
          }, 0),
          inflows: c.inflows.reduce((tp, tc) => {
            const account = accounts.find(x => x.id === tc.id);
            return tp + (account !== null && tc.amount != null ? tc.amount : 0);
          }, 0),
          outflows: c.outflows.reduce((tp, tc) => {
            const account = accounts.find(x => x.id === tc.id);
            return tp + (account !== null && tc.amount != null ? tc.amount : 0);
          }, 0),
        };
      })
      .map(c => {
        return {
          ...c,
          total: c.assets - c.liabilities,
          netflows: c.inflows - c.outflows,
        };
      })
      .reduce(reduceCalc, []),
);

export const getCurrentNetWorth = createSelector([getNetWorth], netWorth => {
  if (netWorth.length > 0) {
    return netWorth[netWorth.length - 1].total;
  }
  return 0;
});

export const getNetWorthByAccount = createSelector(
  [getAccounts, getRecords],
  (accounts, records) =>
    accounts.map(c => {
      return {
        id: c.id,
        isAsset: c.isAsset,
        records: records
          .map(oc => {
            const total = oc.totals.find(x => x.id === c.id);
            const inflow = oc.inflows.find(x => x.id === c.id);
            const outflow = oc.outflows.find(x => x.id === c.id);
            return {
              date: toDate(oc.date),
              total: total !== null && total !== undefined ? total.amount : 0,
              inflow:
                inflow !== null && inflow !== undefined ? inflow.amount : 0,
              outflow:
                outflow !== null && outflow !== undefined ? outflow.amount : 0,
            };
          })
          .map(oc => {
            return {
              ...oc,
              netflows: oc.inflow - oc.outflow,
            };
          })
          .reduce(reduceCalc, []),
      };
    }),
);

export const getAccountSummary = createSelector(
  [getAccounts, getRecords],
  (accounts, records) => {
    // const last = records.sort();

    return accounts.map(c => {
      return {
        id: c.id,
        isAsset: c.isAsset,
        records: records
          .map(oc => {
            const total = oc.totals.find(x => x.id === c.id);
            const inflow = oc.inflows.find(x => x.id === c.id);
            const outflow = oc.outflows.find(x => x.id === c.id);
            return {
              date: toDate(oc.date),
              total: total !== null && total !== undefined ? total.amount : 0,
              inflow:
                inflow !== null && inflow !== undefined ? inflow.amount : 0,
              outflow:
                outflow !== null && outflow !== undefined ? outflow.amount : 0,
            };
          })
          .map(oc => {
            return {
              ...oc,
              netflows: oc.inflow - oc.outflow,
            };
          })
          .reduce(reduceCalc, []),
      };
    });
  },
);
