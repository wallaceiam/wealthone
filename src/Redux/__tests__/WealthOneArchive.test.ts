import {createWealthOneArchive} from '../WealthOneArchive';

test('exports sparse dated records and decimal values without changing state', () => {
  const state: any = {
    accounts: [{id: 'a', name: 'Savings', provider: 'Bank', isAsset: true,
      accountType: {id: 1, name: 'Savings', isAsset: true}}],
    records: [{date: new Date('2023-06-01T00:00:00Z'),
      totals: [{id: 'a', amount: 123.45}], inflows: [], outflows: []},
      {date: new Date('2023-06-02T00:00:00Z'), totals: [], inflows: [], outflows: []}],
    goal: {pension: 12, lifeStyle: 40},
  };
  const before = JSON.stringify(state);
  const result = JSON.parse(createWealthOneArchive(state));
  expect(result.schemaVersion).toBe(1);
  expect(result.accounts[0].accountType).toBe(1);
  expect(result.records[0].totals).toEqual([{accountID: 'a', amount: 123.45}]);
  expect(result.records[1].totals).toEqual([]);
  expect(result.goal.pension).toBe(12);
  expect(JSON.stringify(state)).toBe(before);
});

test('rejects non-finite values rather than exporting a lossy null', () => {
  expect(() => createWealthOneArchive({accounts: [], goal: {} as any,
    records: [{date: new Date(), totals: [{id: 'a', amount: Infinity}], inflows: [], outflows: []}]}))
    .toThrow();
});
