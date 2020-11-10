import { createSelector } from 'reselect';

const getAccounts = (state) => state.portfolio.accounts

export const assetAccountsSelector = createSelector(
  [getAccounts],
  (accounts) => (accounts || []).filter((a) => a.isAsset === true)
);

export const liabilityAccountsSelector = createSelector(
  [getAccounts],
  (accounts) => (accounts || []).filter((a) => a.isAsset === false)
);


