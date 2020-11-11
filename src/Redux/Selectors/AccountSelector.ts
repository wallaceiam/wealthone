import { createSelector } from 'reselect';

export const getAccounts = (state) => state.portfolio.accounts;

const allRecords = (state) => (state.portfolio.records || []);

const dateSort = (d1, d2) => {
  const da = d1 instanceof Date ? d1 : new Date(Date.parse(d1));
  const db = d2 instanceof Date ? d2 : new Date(Date.parse(d2));
  return da.getTime() - db.getTime();
};

export const getRecords = createSelector(
  [allRecords],
  (records) => records.sort((a, b) => dateSort(a.date, b.date))
);

export const getAssetAccounts = createSelector(
  [getAccounts],
  (accounts) => (accounts || []).filter((a) => a.isAsset === true)
);

export const getLiabilityAccounts = createSelector(
  [getAccounts],
  (accounts) => (accounts || []).filter((a) => a.isAsset === false)
);

