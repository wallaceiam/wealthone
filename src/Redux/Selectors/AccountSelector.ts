import { createSelector } from 'reselect';
import { toDate } from '../DateHelpers';
import { IAccount } from '../IAccount';
import { IRecord } from '../IState';

export const getAccounts = state => state.portfolio.accounts as IAccount[];

const allRecords = state => (state.portfolio.records || []) as IRecord[];

const dateSort = (d1: string | number | Date, d2: string | number | Date) =>
  toDate(d1).getTime() - toDate(d2).getTime();

export const getRecords = createSelector([allRecords], records =>
  records.sort((a, b) => dateSort(a.date, b.date)),
);

export const getAssetAccounts = createSelector([getAccounts], accounts =>
  (accounts || []).filter(a => a.isAsset === true),
);

export const getLiabilityAccounts = createSelector([getAccounts], accounts =>
  (accounts || []).filter(a => a.isAsset === false),
);
