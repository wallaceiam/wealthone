import {IAccount} from './IAccount';
import {IRecord} from './IState';
import {IGoalInput} from './IGoalInput';

/** Portable state baseline. The native app starts edit history at migration. */
export function createWealthOneArchive(state: {
  accounts: IAccount[];
  records: IRecord[];
  goal: IGoalInput;
}): string {
  const amounts = (values: {id: string; amount: number}[]) =>
    values.map(value => {
      if (!Number.isFinite(value.amount)) {
        throw new Error('An account amount is not a finite number.');
      }
      return {accountID: value.id, amount: value.amount};
    });
  return JSON.stringify({
    schemaVersion: 1,
    accounts: state.accounts.map(account => ({
      ...account,
      provider: account.provider || '',
      accountType: account.accountType?.id ?? (account.isAsset ? 0 : 7),
    })),
    records: state.records.map(record => ({
      date: new Date(record.date).toISOString(),
      totals: amounts(record.totals),
      inflows: amounts(record.inflows),
      outflows: amounts(record.outflows),
    })),
    goal: state.goal,
  });
}
