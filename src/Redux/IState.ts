import { IAccount } from './IAccount';

export interface IRecordValue {
  id: string;
  amount: number;
}

export interface IRecord {
  date: Date | number | string;
  totals: IRecordValue[];
  inflows: IRecordValue[];
  outflows: IRecordValue[];
}

export interface IState {
  accounts: IAccount[];
  records: IRecord[];
}
